/// ホームタブ（収支サマリ）の View。
///
/// MVVM の View 層に位置する。
/// [summaryProvider] を watch し、[SummaryState] の変化に応じて自動再ビルドする。
/// データの取得・加工は [SummaryNotifier] が担い、このファイルは表示のみに専念する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/features/dashboard/model/summary_state.dart';
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
    // summaryProvider を監視：状態変化で自動再ビルド
    final summary = ref.watch(summaryProvider);

    return ListView(
      children: [
        SummaryCard(
          income: summary.income,
          expense: summary.expense,
          balance: summary.balance,
        ),
        RecentList(items: summary.recentTransactions),
      ],
    );
  }
}
