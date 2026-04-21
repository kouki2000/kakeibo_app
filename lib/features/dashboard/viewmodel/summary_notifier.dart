/// ダッシュボード（ホームタブ）の状態管理。
///
/// MVVM の ViewModel 層に位置する。
/// [SummaryNotifier] が [SummaryState] を保持・更新し、
/// [summaryProvider] 経由で View 層（`HomeTab`）に公開する。
///
/// 第9章で DB 連携に切り替えた。
/// `Notifier` から `AsyncNotifier` に変更し、
/// `ref.watch(transactionListProvider)` で取引リストを監視することで
/// 取引の追加・削除時にサマリが自動再計算される。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/features/dashboard/model/summary_state.dart';
import 'package:kakeibo_app/features/transaction/model/transaction_item.dart';
import 'package:kakeibo_app/features/transaction/viewmodel/transaction_list_notifier.dart';

/// 収支サマリの状態を非同期で管理する Notifier。
///
/// `AsyncNotifier<SummaryState>` を継承することで、状態が `AsyncValue` でラップされる。
/// `build` 内で `ref.watch(transactionListProvider)` を呼ぶことで、
/// 取引リストの変化（追加・削除）を検知して自動的に再計算する。
class SummaryNotifier extends AsyncNotifier<SummaryState> {
  /// 取引リストからサマリを計算して返す。
  ///
  /// `ref.watch(transactionListProvider)` が `AsyncData` でない場合（ローディング中・エラー）は
  /// 空のサマリを返す。データが取得できたら今月の取引だけを集計する。
  ///
  /// このメソッドは `transactionListProvider` の状態が変わるたびに自動で再実行される。
  /// `addTransactionPage` から `summaryProvider.notifier.addTransaction` を
  /// 呼ぶ必要がなくなる。
  @override
  Future<SummaryState> build() async {
    // transactionListProvider を watch することで、
    // 取引リストが変わったときに build が自動で再実行される
    final transactionsValue = ref.watch(transactionListProvider);

    // ローディング中またはエラーのときは空のサマリを返す
    final transactions = switch (transactionsValue) {
      AsyncData(:final value) => value,
      _ => <TransactionItem>[],
    };

    return _calcSummary(transactions);
  }

  /// 取引リストから今月の収支サマリを計算する。
  ///
  /// 今月の取引だけを抽出し、[isIncome] で収入・支出を分けて合計する。
  /// 直近5件を [SummaryState.recentTransactions] に格納する。
  SummaryState _calcSummary(List<TransactionItem> transactions) {
    final now = DateTime.now();
    // 今月の取引だけを抽出する
    final thisMonth = transactions.where(
      (t) => t.date.year == now.year && t.date.month == now.month,
    );

    var income = 0;
    var expense = 0;
    for (final t in thisMonth) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    // 今月の取引を日付降順で最大5件、RecentItem に変換する
    final recent = thisMonth
        .take(5)
        .map(
          (t) => RecentItem(
            label: t.category.name,
            amount: t.amount,
            iconCode: t.category.iconCode,
            isIncome: t.isIncome,
            dateLabel:
                '${t.date.month.toString().padLeft(2, '0')}/${t.date.day.toString().padLeft(2, '0')}',
          ),
        )
        .toList();

    return SummaryState(
      income: income,
      expense: expense,
      recentTransactions: recent,
    );
  }
}

/// ホームタブ全体で共有するサマリ Provider。
///
/// 第9章で `NotifierProvider` から `AsyncNotifierProvider` に変更した。
/// 参照方法: `ref.watch(summaryProvider)` → `AsyncValue<SummaryState>` を返す。
final summaryProvider = AsyncNotifierProvider<SummaryNotifier, SummaryState>(
  SummaryNotifier.new,
);
