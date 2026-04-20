/// ダッシュボード（ホームタブ）の状態管理。
///
/// MVVM の ViewModel 層に位置する。
/// [SummaryNotifier] が [SummaryState] を保持・更新し、
/// [summaryProvider] 経由で View 層（`HomeTab`）に公開する。
///
/// 第5章では [SummaryNotifier.addTransaction] を追加し、
/// フォームからの入力をサマリに反映できるようにする。
/// DB（drift）との接続は第7章で実装する。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/features/dashboard/model/summary_state.dart';

/// 収支サマリの状態を管理する Notifier。
///
/// 状態を変更するときは `state = 新インスタンス` を代入する。
/// フィールドの直接書き換えは Riverpod に検知されないため行わない。
class SummaryNotifier extends Notifier<SummaryState> {
  /// 初期状態を生成して返す。
  ///
  /// Provider が初めて参照されたタイミングで1回だけ呼ばれる。
  /// 第7章以降は DB から取得した値を返すよう書き換える。
  @override
  SummaryState build() => const SummaryState(
    income: 250000,
    expense: 87430,
    recentTransactions: [
      RecentItem(
        label: '給与',
        amount: 250000,
        iconCode: 'e227',
        isIncome: true,
        dateLabel: '04/25',
      ),
      RecentItem(
        label: '食費',
        amount: 3200,
        iconCode: 'e56c',
        isIncome: false,
        dateLabel: '04/24',
      ),
      RecentItem(
        label: '交通費',
        amount: 1840,
        iconCode: 'e530',
        isIncome: false,
        dateLabel: '04/23',
      ),
      RecentItem(
        label: '娯楽費',
        amount: 4500,
        iconCode: 'e87c',
        isIncome: false,
        dateLabel: '04/22',
      ),
    ],
  );

  /// フォームから受け取った取引を追加してサマリを更新する。
  ///
  /// [item] を `recentTransactions` の先頭に挿入し、
  /// [isIncome] に応じて [SummaryState.income] または [SummaryState.expense] を加算する。
  /// Riverpod は `state = 新インスタンス` の代入で変化を検知する。
  void addTransaction(RecentItem item) {
    final updated = [item, ...state.recentTransactions];
    state = SummaryState(
      income: item.isIncome ? state.income + item.amount : state.income,
      expense: item.isIncome ? state.expense : state.expense + item.amount,
      recentTransactions: updated,
    );
  }
}

/// ホームタブ全体で共有するサマリ Provider。
///
/// 参照方法: `ref.watch(summaryProvider)` → [SummaryState] を返す。
/// 更新方法: `ref.read(summaryProvider.notifier).addTransaction(item)`
final summaryProvider = NotifierProvider<SummaryNotifier, SummaryState>(
  SummaryNotifier.new,
);
