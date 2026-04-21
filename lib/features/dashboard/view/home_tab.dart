/// ホームタブ（収支サマリ）の View。
///
/// MVVM の View 層に位置する。
/// [summaryProvider] を watch し、[AsyncValue<SummaryState>] の変化に応じて自動再ビルドする。
/// データの取得・加工は [SummaryNotifier] が担い、このファイルは表示のみに専念する。
///
/// 第9章で `summaryProvider` が `AsyncNotifierProvider` に変わったため、
/// `.when()` を使って3状態（ローディング・エラー・データ）を網羅するよう変更した。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/features/dashboard/view/recent_list.dart';
import 'package:kakeibo_app/features/dashboard/view/summary_card.dart';
import 'package:kakeibo_app/features/dashboard/viewmodel/summary_notifier.dart';

/// ホームタブ：今月の収支サマリを表示する。
///
/// [ConsumerWidget] を継承することで [WidgetRef] を受け取り、
/// `ref.watch(summaryProvider)` で状態変化を購読する。
/// 状態が変わると [build] が自動で再実行される。
class HomeTab extends ConsumerWidget {
  /// コンストラクタ。
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // summaryProvider を監視：AsyncValue<SummaryState> を返す
    final summaryAsync = ref.watch(summaryProvider);

    return summaryAsync.when(
      // ローディング中：インジケータを表示する
      loading: () => const Center(child: CircularProgressIndicator()),
      // エラー：エラーメッセージを表示する
      error: (e, _) => Center(child: Text('エラーが発生しました: $e')),
      // データ取得済み：サマリカードと直近リストを表示する
      data: (summary) => ListView(
        children: [
          SummaryCard(
            income: summary.income,
            expense: summary.expense,
            balance: summary.balance,
          ),
          RecentList(items: summary.recentTransactions),
        ],
      ),
    );
  }
}
