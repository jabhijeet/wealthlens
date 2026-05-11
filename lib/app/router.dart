import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/db/database.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/holdings/holdings_screen.dart';
import '../features/holdings/add_holding_screen.dart';
import '../features/holdings/holding_detail_screen.dart';
import '../features/import/import_screen.dart';
import '../features/news/news_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/systematic/systematic_plans_screen.dart';
import '../features/systematic/add_systematic_plan_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/activity/activity_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/privacy_policy_screen.dart';
import '../features/settings/terms_of_service_screen.dart';
import '../features/settings/llm_providers_screen.dart';
import '../features/settings/fx_rates_screen.dart';
import '../features/insights/ai_chat_screen.dart';
import '../features/search/global_search_screen.dart';
import 'shell_scaffold.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final _shellNavigatorKeys = List.generate(
  5,
  (_) => GlobalKey<NavigatorState>(),
);

// ─── Custom Transitions ───────────────────────────────────────────────────────

Page<void> _buildPageTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

// ─── Router Configuration ─────────────────────────────────────────────────────

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0 — Dashboard
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeys[0],
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => _buildPageTransition(
                state: state,
                child: const DashboardScreen(),
              ),
            ),
          ],
        ),
        // Tab 1 — Holdings
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeys[1],
          routes: [
            GoRoute(
              path: '/holdings',
              pageBuilder: (context, state) => _buildPageTransition(
                state: state,
                child: const HoldingsScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final instrument = state.extra as Instrument?;
                    return _buildPageTransition(
                      state: state,
                      child: AddHoldingScreen(initialInstrument: instrument),
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return _buildPageTransition(
                      state: state,
                      child: HoldingDetailScreen(holdingId: id),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Tab 2 — News
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeys[2],
          routes: [
            GoRoute(
              path: '/news',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state: state, child: const NewsScreen()),
            ),
          ],
        ),
        // Tab 3 — Insights
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeys[3],
          routes: [
            GoRoute(
              path: '/insights',
              pageBuilder: (context, state) => _buildPageTransition(
                state: state,
                child: const InsightsScreen(),
              ),
            ),
          ],
        ),
        // Tab 4 — Settings (More)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeys[4],
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => _buildPageTransition(
                state: state,
                child: const SettingsScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'privacy-policy',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => _buildPageTransition(
                    state: state,
                    child: const PrivacyPolicyScreen(),
                  ),
                ),
                GoRoute(
                  path: 'terms-of-service',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => _buildPageTransition(
                    state: state,
                    child: const TermsOfServiceScreen(),
                  ),
                ),
                GoRoute(
                  path: 'llm-providers',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => _buildPageTransition(
                    state: state,
                    child: const LlmProvidersScreen(),
                  ),
                ),
                GoRoute(
                  path: 'fx-rates',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => _buildPageTransition(
                    state: state,
                    child: const FxRatesScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // Full-screen routes (no bottom nav)
    GoRoute(
      path: '/import',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageTransition(state: state, child: const ImportScreen()),
    ),
    GoRoute(
      path: '/systematic-plans',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => _buildPageTransition(
        state: state,
        child: const SystematicPlansScreen(),
      ),
      routes: [
        GoRoute(
          path: 'new',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) {
            final holdingId = state.uri.queryParameters['holdingId'];
            return _buildPageTransition(
              state: state,
              child: AddSystematicPlanScreen(holdingId: holdingId),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/activity',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageTransition(state: state, child: const ActivityScreen()),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => _buildPageTransition(
        state: state,
        child: const NotificationsScreen(),
      ),
    ),
    GoRoute(
      path: '/ai-chat',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageTransition(state: state, child: const AiChatScreen()),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageTransition(state: state, child: const GlobalSearchScreen()),
    ),
  ],
);
