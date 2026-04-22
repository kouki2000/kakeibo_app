/// 明細タブ（取引一覧）の View。
///
/// MVVM の View 層に位置する。
/// [transactionListProvider] と [selectedMonthProvider] を watch し、
/// 選択中の年月でフィルタリングした取引リストを [ListView.builder] で描画する。
/// スワイプ削除は [Dismissible] で実装する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/core/utils/formatter.dart';
import 'package:kakeibo_app/features/transaction/model/transaction_item.dart';
import 'package:kakeibo_app/features/transaction/viewmodel/transaction_list_notifier.dart';

/// 明細タブ：取引一覧を月別に表示する。
///
/// [ConsumerWidget] を継承して [transactionListProvider] と
/// [selectedMonthProvider] の変化を購読する。
class ListTab extends ConsumerWidget {
  /// コンストラクタ。
  const ListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(transactionListProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('明細')),
      body: Column(
        children: [
          // ---- 月ナビゲーション ----
          _MonthNavigator(selectedMonth: selectedMonth),
          const Divider(height: 1),
          // ---- 取引リスト ----
          Expanded(
            child: asyncItems.when(
              // ローディング中はインジケータを表示する
              loading: () => const Center(child: CircularProgressIndicator()),
              // エラー時はメッセージを表示する
              error: (e, _) => Center(child: Text('エラー: $e')),
              // データが取得できたら月でフィルタして表示する
              data: (items) {
                final filtered = items
                    .where(
                      (t) =>
                          t.date.year == selectedMonth.year &&
                          t.date.month == selectedMonth.month,
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('この月の取引はありません'));
                }

                return ListView.builder(
                  // アイテム数だけ ListTile を生成する
                  // builder コールバックは画面内に表示されるアイテムだけを生成するため、
                  // 数千件のリストでも効率的に描画できる
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _TransactionTile(item: item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 月ナビゲーションウィジェット。
///
/// 左右の矢印ボタンで [selectedMonthProvider] を1ヶ月単位で更新する。
class _MonthNavigator extends ConsumerWidget {
  const _MonthNavigator({required this.selectedMonth});

  /// 現在選択中の年月。
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '前の月',
          onPressed: () {
            // DateTime のコンストラクタは月に 0 や 13 を渡しても自動で繰り上がる
            // 変更後
            ref
                .read(selectedMonthProvider.notifier)
                .update(DateTime(selectedMonth.year, selectedMonth.month - 1));
          },
        ),
        Text(
          Formatter.yearMonth(selectedMonth),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '次の月',
          onPressed: () {
            ref
                .read(selectedMonthProvider.notifier)
                .update(DateTime(selectedMonth.year, selectedMonth.month + 1));
          },
        ),
      ],
    );
  }
}

/// 取引1件を [ListTile] と [Dismissible] で表示するプライベートウィジェット。
///
/// 左スワイプで削除操作を起動し、[transactionListProvider] の `removeItem` を呼ぶ。
class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.item});

  /// 表示する取引データ。
  final TransactionItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = item.isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    final sign = item.isIncome ? '+' : '-';

    return Dismissible(
      // key はリスト内で一意でなければならない。ここでは取引 ID を使う
      key: ValueKey(item.id),
      // 右から左へのスワイプだけ有効にする
      direction: DismissDirection.endToStart,
      // スワイプ中に背景として表示する赤いバー
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      // スワイプ完了時に削除を実行する
      onDismissed: (_) {
        ref.read(transactionListProvider.notifier).removeItem(item.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            IconData(
              int.parse(item.category.iconCode, radix: 16),
              fontFamily: 'MaterialIcons',
            ),
            color: color,
            size: 20,
          ),
        ),
        title: Text(item.category.name),
        subtitle: item.memo != null
            ? Text(
                '${Formatter.date(item.date)}  ${item.memo}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text(Formatter.date(item.date)),
        trailing: Text(
          '$sign${Formatter.amount(item.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
