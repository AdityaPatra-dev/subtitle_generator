import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/storage/database.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/library_screen.dart';
import 'presentation/screens/runs_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupSqliteOnLinux();
  runApp(
    const ProviderScope(
      child: SubtitleGeneratorApp(),
    ),
  );
}

class ModernAppScrollBehavior extends MaterialScrollBehavior {
  const ModernAppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    // Disable the Android 12 stretching overscroll effect that distorts the entire screen
    return child;
  }
}

class SubtitleGeneratorApp extends ConsumerWidget {
  const SubtitleGeneratorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'AI Subtitle Generator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      scrollBehavior: const ModernAppScrollBehavior(),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;
  JobEntry? _pendingResumeJob;

  @override
  Widget build(BuildContext context) {
    final incompleteJobsAsync = ref.watch(incompleteJobsStreamProvider);
    final incompleteCount = incompleteJobsAsync.valueOrNull?.length ?? 0;

    final screens = [
      HomeScreen(
        key: ValueKey(_pendingResumeJob?.id ?? 'home'),
        initialResumeJob: _pendingResumeJob,
      ),
      const LibraryScreen(),
      RunsScreen(
        onResumeJob: (job) {
          setState(() {
            _pendingResumeJob = job;
            _currentIndex = 0;
          });
        },
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Generate',
          ),
          const NavigationDestination(
            icon: Icon(Icons.subtitles_outlined),
            selectedIcon: Icon(Icons.subtitles),
            label: 'Library',
          ),
          NavigationDestination(
            icon: incompleteCount > 0
                ? Badge.count(
                    count: incompleteCount,
                    backgroundColor: Colors.amber,
                    child: const Icon(Icons.pending_actions_outlined),
                  )
                : const Icon(Icons.pending_actions_outlined),
            selectedIcon: const Icon(Icons.pending_actions),
            label: 'Runs',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
