import 'package:go_router/go_router.dart';
import 'package:kakeibo_app/features/dashboard/view/add_transaction_page.dart';
import 'package:kakeibo_app/features/dashboard/view/dashboard_page.dart';
import 'package:kakeibo_app/features/dashboard/view/home_tab.dart';
import 'package:kakeibo_app/features/dashboard/view/list_tab.dart';

/// アプリ全体のルーター
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  debugLogDiagnostics: true, // ルート遷移をコンソールに出力（デバッグ用）
  routes: [
    // ボトムナビを持つ shell：タブごとのスタックを独立管理する
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          DashboardPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/list',
              builder: (context, state) => const ListTab(),
            ),
          ],
        ),
      ],
    ),
    // ボトムナビの外に出るページ（モーダル相当）
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddTransactionPage(),
    ),
  ],
);
