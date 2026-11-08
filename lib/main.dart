import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const Color maroonDeep = Color(0xFF23040B);

const Color maroon = Color(0xFF7A1030);

const Color ember = Color(0xFFFF7A1A);

const Color gold = Color(0xFFF6C453);

const Color cream = Color(0xFFFBE9D8);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const IN7GuideApp());
}

class GuidePreferences {
  static const _themeKey = 'in7_dark_mode';

  static const _savedKey = 'in7_saved_articles';

  static Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_themeKey) ?? true;
  }

  static Future<void> saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_themeKey, value);
  }

  static Future<Set<String>> loadSavedArticles() async {
    final prefs = await SharedPreferences.getInstance();

    return (prefs.getStringList(_savedKey) ?? <String>[]).toSet();
  }

  static Future<void> saveArticles(Set<String> values) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_savedKey, values.toList());
  }
}

class IN7GuideApp extends StatefulWidget {
  const IN7GuideApp({super.key});

  @override
  State<IN7GuideApp> createState() => _IN7GuideAppState();
}

class _IN7GuideAppState extends State<IN7GuideApp> {
  bool _darkMode = true;

  bool _ready = false;

  Set<String> _savedArticles = {};

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      GuidePreferences.loadDarkMode(),
      GuidePreferences.loadSavedArticles(),
    ]);

    if (!mounted) return;

    setState(() {
      _darkMode = results[0] as bool;

      _savedArticles = results[1] as Set<String>;

      _ready = true;
    });
  }

  Future<void> _setTheme(bool value) async {
    setState(() => _darkMode = value);

    await GuidePreferences.saveDarkMode(value);
  }

  Future<void> _toggleSaved(String id) async {
    final updated = Set<String>.from(_savedArticles);

    if (!updated.add(id)) updated.remove(id);

    setState(() => _savedArticles = updated);

    await GuidePreferences.saveArticles(updated);
  }

  ThemeData _buildTheme(bool dark) {
    final scheme = dark
        ? const ColorScheme.dark(
            primary: gold,
            secondary: ember,
            surface: Color(0xFF32121D),
            onPrimary: maroonDeep,
            onSurface: cream,
          )
        : const ColorScheme.light(
            primary: maroon,
            secondary: ember,
            surface: Color(0xFFFFF8F2),
            onPrimary: Colors.white,
            onSurface: Color(0xFF28151A),
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: dark ? maroonDeep : const Color(0xFFFFF8F2),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? maroonDeep : const Color(0xFFFFF8F2),
        foregroundColor: dark ? cream : maroonDeep,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF32121D) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: dark ? const Color(0xFF542333) : const Color(0xFFEAD9D0),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF32121D) : Colors.white,
        indicatorColor:
            dark ? const Color(0xFF70402A) : const Color(0xFFF6DFC7),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF32121D) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF542333) : const Color(0xFFEAD9D0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF542333) : const Color(0xFFEAD9D0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(true),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator(color: gold)),
        ),
      );
    }

    return MaterialApp(
      title: 'IN7 Guide',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(_darkMode),
      home: MainNavigation(
        darkMode: _darkMode,
        onThemeChanged: _setTheme,
        savedArticles: _savedArticles,
        onToggleSaved: _toggleSaved,
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final bool darkMode;

  final ValueChanged<bool> onThemeChanged;

  final Set<String> savedArticles;

  final ValueChanged<String> onToggleSaved;

  const MainNavigation({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
    required this.savedArticles,
    required this.onToggleSaved,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onNavigate: (index) => setState(() => _index = index),
        savedArticles: widget.savedArticles,
        onToggleSaved: widget.onToggleSaved,
      ),
      ExploreScreen(
        savedArticles: widget.savedArticles,
        onToggleSaved: widget.onToggleSaved,
      ),
      SafetyScreen(
        darkMode: widget.darkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Safety',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  final Set<String> savedArticles;

  final ValueChanged<String> onToggleSaved;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.savedArticles,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [maroon, ember],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text(
                  '7',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 27,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IN7 GUIDE',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    )),
                Text('Information and help center',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Explore saved information',
              onPressed: () => onNavigate(1),
              icon: Badge(
                isLabelVisible: savedArticles.isNotEmpty,
                label: Text('${savedArticles.length}'),
                child: const Icon(Icons.bookmark_outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF7A1030), Color(0xFF35101C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('WELCOME TO IN7 GUIDE',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  )),
              const SizedBox(height: 10),
              const Text(
                'Find helpful information in one simple place.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Browse the guide, read frequently asked questions, and review safety information.',
                style: TextStyle(
                  color: Color(0xFFF5DDE2),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: maroonDeep,
                ),
                onPressed: () => onNavigate(1),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Explore guide'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Explore sections',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HomeTile(
                icon: Icons.menu_book_rounded,
                title: 'FAQs',
                subtitle: 'Answers and help',
                onTap: () => onNavigate(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HomeTile(
                icon: Icons.verified_user_outlined,
                title: 'Safety',
                subtitle: 'Stay informed',
                onTap: () => onNavigate(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text('Featured information',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ArticleCard(
          article: guideArticles.first,
          isSaved: savedArticles.contains(guideArticles.first.id),
          onToggleSaved: () => onToggleSaved(guideArticles.first.id),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'IN7 Guide • Information resource',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 27),
              const SizedBox(height: 15),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class GuideArticle {
  final String id;

  final String category;

  final String title;

  final String summary;

  final String body;

  const GuideArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.body,
  });
}

// Replace these sample entries with accurate information about your own service.

const List<GuideArticle> guideArticles = [
  GuideArticle(
    id: 'getting-started',
    category: 'Getting started',
    title: 'Getting started with this guide',
    summary: 'Learn how to navigate the IN7 Guide information screens.',
    body:
        'IN7 Guide is an information resource. Use the Home tab for an overview, Explore to search the available help topics, and Safety to review general safety and privacy guidance. You can save useful articles with the bookmark icon. Saved items remain on this device.',
  ),
  GuideArticle(
    id: 'using-guide',
    category: 'Getting started',
    title: 'How do I use IN7 Guide?',
    summary: 'A quick overview of the app navigation.',
    body:
        'Use the bottom navigation bar to move between Home, Explore, and Safety. On Explore, enter a keyword in the search field or select a category. Open an article to read its full information.',
  ),
  GuideArticle(
    id: 'bookmarks',
    category: 'App features',
    title: 'How do saved articles work?',
    summary: 'Keep useful guide topics close at hand.',
    body:
        'Tap the bookmark icon on an article to save it. Tap it again to remove it. Your saved article list is stored locally on this device using app preferences. It is not uploaded to a server.',
  ),
  GuideArticle(
    id: 'privacy',
    category: 'Privacy',
    title: 'Privacy and device data',
    summary: 'Understand what this sample guide stores.',
    body:
        'This starter app stores only your selected theme and saved article IDs on your device. It does not include analytics, account registration, or a remote database. Update this notice if you add services that collect or transmit information.',
  ),
  GuideArticle(
    id: 'safe-links',
    category: 'Safety',
    title: 'Using links safely',
    summary: 'A few checks before opening an external link.',
    body:
        'Check that a link belongs to the expected organization before opening it. Do not enter passwords, payment details, or verification codes on pages you do not trust. This is general guidance and does not verify any third-party website.',
  ),
  GuideArticle(
    id: 'support',
    category: 'Support',
    title: 'How can I send feedback?',
    summary: 'Tell the app team about an issue or suggestion.',
    body:
        'Use the feedback option on the Safety screen to prepare a message. Add a clear description of the issue, the screen where it happened, and your device model. Do not include passwords or one-time verification codes.',
  ),
];

class ExploreScreen extends StatefulWidget {
  final Set<String> savedArticles;

  final ValueChanged<String> onToggleSaved;

  const ExploreScreen({
    super.key,
    required this.savedArticles,
    required this.onToggleSaved,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  String _category = 'All';

  bool _showSavedOnly = false;

  List<String> get _categories => [
        'All',
        ...guideArticles.map((a) => a.category).toSet().toList()..sort(),
      ];

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = guideArticles.where((article) {
      final matchesText =
          ('${article.title} ${article.summary} ${article.body}')
              .toLowerCase()
              .contains(_query.toLowerCase());

      final matchesCategory =
          _category == 'All' || article.category == _category;

      final matchesSaved =
          !_showSavedOnly || widget.savedArticles.contains(article.id);

      return matchesText && matchesCategory && matchesSaved;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Text('Explore',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Search topics and browse helpful information.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Search guide...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();

                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            return ChoiceChip(
              label: Text(category),
              selected: _category == category,
              onSelected: (_) => setState(() => _category = category),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show saved articles only'),
          secondary: const Icon(Icons.bookmark_outline),
          value: _showSavedOnly,
          onChanged: (value) => setState(() => _showSavedOnly = value),
        ),
        const SizedBox(height: 8),
        Text('${filtered.length} article(s)',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No information found',
            message: 'Try another search term or category.',
          )
        else
          ...filtered.map(
            (article) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ArticleCard(
                article: article,
                isSaved: widget.savedArticles.contains(article.id),
                onToggleSaved: () => widget.onToggleSaved(article.id),
              ),
            ),
          ),
      ],
    );
  }
}

class ArticleCard extends StatelessWidget {
  final GuideArticle article;

  final bool isSaved;

  final VoidCallback onToggleSaved;

  const ArticleCard({
    super.key,
    required this.article,
    required this.isSaved,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(
              article: article,
              initiallySaved: isSaved,
              onToggleSaved: onToggleSaved,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 8, 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.category.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        )),
                    const SizedBox(height: 6),
                    Text(article.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(article.summary,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                tooltip: isSaved ? 'Remove bookmark' : 'Save article',
                onPressed: onToggleSaved,
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Icon(Icons.chevron_right),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticleDetailScreen extends StatefulWidget {
  final GuideArticle article;

  final bool initiallySaved;

  final VoidCallback onToggleSaved;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.initiallySaved,
    required this.onToggleSaved,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late bool _saved = widget.initiallySaved;
  Future<void> _showLicenses(BuildContext context) async {
    showLicensePage(
      context: context,
      applicationName: 'IN7 Guide',
      applicationVersion: '1.0.0',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide article'),
        actions: [
          IconButton(
            tooltip: _saved ? 'Remove bookmark' : 'Save article',
            onPressed: () {
              widget.onToggleSaved();

              setState(() => _saved = !_saved);
            },
            icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
          ),
          IconButton(
            tooltip: 'Copy article',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                text: '${widget.article.title}\n\n${widget.article.body}',
              ));

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Article copied')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(widget.article.category.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              )),
          const SizedBox(height: 12),
          Text(
            widget.article.title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          Text(
            widget.article.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}

class SafetyScreen extends StatelessWidget {
  final bool darkMode;

  final ValueChanged<bool> onThemeChanged;

  const SafetyScreen({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  Future<void> _openFeedback(BuildContext context) async {
    final controller = TextEditingController();

    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send feedback'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Describe your suggestion or issue...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (message == null || message.isEmpty || !context.mounted) return;

    final uri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
      queryParameters: {
        'subject': 'IN7 Guide feedback',
        'body': message,
      },
    );

    try {
      final launched = await launchUrl(uri);

      if (!launched && context.mounted) {
        await Clipboard.setData(ClipboardData(text: message));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app found. Feedback copied instead.'),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      await Clipboard.setData(ClipboardData(text: message));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback copied to clipboard.')),
      );
    }
  }

  Future<void> _showPrivacy(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy information'),
        content: const SingleChildScrollView(
          child: Text(
            'This starter version stores the selected theme and saved article IDs locally on your device. It does not include account creation, analytics, or a remote database. If you add advertising, analytics, accounts, external services, or data collection, update this policy to accurately explain what data is collected, why it is used, and how users can contact you.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Text('Safety & Settings',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Helpful information and app preferences.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety checklist',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const _SafetyItem(
                    text: 'Check a website address before opening it.'),
                const _SafetyItem(
                    text: 'Never share passwords or one-time codes.'),
                const _SafetyItem(
                    text: 'Avoid installing files from unknown sources.'),
                const _SafetyItem(
                    text: 'Review app permissions before granting access.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark mode'),
                subtitle: const Text('Change the app appearance'),
                value: darkMode,
                onChanged: onThemeChanged,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy information'),
                subtitle: const Text('What this app stores on your device'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacy(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text('Send feedback'),
                subtitle: const Text('Share a suggestion or report an issue'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openFeedback(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Licenses'),
                subtitle: const Text('Open-source licenses used by this app'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const IN7LicenseScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Important: Replace the sample support email and sample guide content with accurate information before publishing.',
          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class IN7LicenseScreen extends StatelessWidget {
  const IN7LicenseScreen({super.key});

  static const String _websiteUrl =
      'https://sites.google.com/view/in7-game-downloads---/home';

  Future<void> _openWebsite() async {
    final uri = Uri.parse(_websiteUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<List<LicenseEntry>> _loadLicenses() async {
    return await LicenseRegistry.licenses.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: InkWell(
            onTap: _openWebsite,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('IN7 Guide'),
            ),
          ),
        ),
        body: FutureBuilder<List<LicenseEntry>>(
          future: _loadLicenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Unable to load licenses'),
              );
            }

            final entries = snapshot.data ?? [];

            return ListView(
              children: entries.map((entry) {
                return ExpansionTile(
                  title: Text(entry.packages.join(', ')),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        entry.paragraphs.map((p) => p.text).join('\n\n'),
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ));
  }
}

class _SafetyItem extends StatelessWidget {
  final String text;

  const _SafetyItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: ember, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;

  final String title;

  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
