import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ダッシュボード：ボトムナビ付き scaffold
class DashboardPage extends StatelessWidget {
  /// コンストラクタ
  const DashboardPage({required this.navigationShell, super.key});

  /// go_router が提供するナビゲーション shell
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            // 同じタブを再タップしたとき初期位置に戻る
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: '明細',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
