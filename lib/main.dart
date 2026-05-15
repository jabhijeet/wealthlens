import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'app/router.dart';
import 'services/logging/error_handler.dart';
import 'services/analytics/analytics_service.dart';
import 'features/auth/lock_screen.dart';
import 'providers/providers.dart';
import 'data/db/daos.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }

  // Initialize error handling
  ErrorHandler.initialize();

  runApp(const ProviderScope(child: WealthLensApp()));
}

class WealthLensApp extends ConsumerStatefulWidget {
  const WealthLensApp({super.key});

  @override
  ConsumerState<WealthLensApp> createState() => _WealthLensAppState();
}

class _WealthLensAppState extends ConsumerState<WealthLensApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await Future.wait([_initSetup()]).timeout(const Duration(seconds: 15));
    } catch (e, stackTrace) {
      errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'Service initialization',
      );
      // Re-throw to show error in UI via FutureBuilder
      rethrow;
    }
  }

  Future<void> _initSetup() async {
    final db = ref.read(appDatabaseProvider);
    // Warm up the database and check connection
    // On web, this triggers the wasm worker initialization
    await db.customSelect('SELECT 1').get();

    // Initialize analytics service
    final analyticsService = ref.read(analyticsServiceProvider);
    await analyticsService.initialize();

    // Log app launch event
    final analyticsHelper = ref.read(analyticsHelperProvider);
    await analyticsHelper.logAppLaunched();

    // Initialize notification service
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize();

    // Wait for another short delay to ensure everything is settled
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        return MaterialApp.router(
          title: 'WealthLens',
          themeMode: themeMode,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          scaffoldMessengerKey: scaffoldMessengerKey,
          routerConfig: router,
          scrollBehavior: WebScrollBehavior(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: WealthColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Initialization Failed',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: WealthColors.textMuted),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _initFuture = _initializeServices();
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: WealthColors.primary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Initializing WealthLens...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take a moment on the first run',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WealthColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SizedBox.expand(
              child: Material(child: LockScreen(child: child!)),
            );
          },
        );
      },
    );
  }
}
