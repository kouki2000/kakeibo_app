/// 直近の取引リストウィジェット。
///
/// MVVM の View 層に位置する。
/// 状態は持たず、`HomeTab`（ConsumerWidget）から [RecentItem] のリストを受け取って描画する。
library;

import 'package:flutter/material.dart';
import 'package:kakeibo_app/core/utils/formatter.dart';
import 'package:kakeibo_app/features/dashboard/model/summary_state.dart';

/// 直近の取引を [ListTile] で一覧表示するウィジェット。
///
/// データは外部から注入されるため [StatelessWidget] で実装する。
/// 各行は [_RecentTile] が担当する。
class RecentList extends StatelessWidget {
  /// コンストラクタ。
  const RecentList({required this.items, super.key});

  /// 表示する取引リスト。
  final List<RecentItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('直近の取引', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => _RecentTile(item: item)),
      ],
    );
  }
}

/// 取引1件を [ListTile] で表示するプライベートウィジェット。
class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.item});

  final RecentItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    final sign = item.isIncome ? '+' : '-';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          IconData(
            int.parse(item.iconCode, radix: 16),
            fontFamily: 'MaterialIcons',
          ),
          color: color,
          size: 20,
        ),
      ),
      title: Text(item.label),
      subtitle: Text(item.dateLabel),
      trailing: Text(
        '$sign${Formatter.amount(item.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
