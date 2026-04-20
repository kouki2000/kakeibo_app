/// 収支サマリカードウィジェット。
///
/// MVVM の View 層に位置する。
/// 状態は持たず、`HomeTab`（ConsumerWidget）から値を受け取って描画する。
library;

import 'package:flutter/material.dart';
import 'package:kakeibo_app/core/utils/formatter.dart';

/// 今月の収支・収入・支出を表示する [Card] ウィジェット。
///
/// すべての表示値をコンストラクタで受け取る純粋な表示コンポーネント。
/// 自分では状態を持たないため [StatelessWidget] で実装する。
class SummaryCard extends StatelessWidget {
  /// コンストラクタ。
  const SummaryCard({
    required this.income,
    required this.expense,
    required this.balance,
    super.key,
  });

  /// 今月の収入合計（円）。
  final int income;

  /// 今月の支出合計（円、正値）。
  final int expense;

  /// 収支（収入 − 支出）。負値のとき赤色で表示する。
  final int balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceColor = balance >= 0
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今月の収支', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              Formatter.amount(balance.abs()),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: balanceColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _AmountRow(label: '収入', amount: income, isIncome: true),
            const SizedBox(height: 8),
            _AmountRow(label: '支出', amount: expense, isIncome: false),
          ],
        ),
      ),
    );
  }
}

/// 収入または支出を1行で表示するプライベートウィジェット。
class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.isIncome,
  });

  final String label;
  final int amount;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final color = isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          Formatter.amount(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
