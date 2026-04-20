/// 明細タブの取引リスト状態管理。
///
/// MVVM の ViewModel 層に位置する。
/// [TransactionListNotifier] が `AsyncNotifier<List<TransactionItem>>` を継承し、
/// [transactionListProvider] 経由で View 層（`ListTab`）に公開する。
///
/// 第7章で drift（SQLite）との接続に切り替えた。
/// `build` / `addItem` / `removeItem` の実装が変わったが、
/// View 層（`ListTab`）のコードは変更不要。
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/core/database/app_database.dart';
import 'package:kakeibo_app/features/transaction/model/transaction_item.dart';

/// 取引リストを非同期で管理する Notifier。
///
/// `AsyncNotifier<T>` を継承することで、状態が `AsyncValue` でラップされる。
/// View 層では `.when()` を使ってローディング・エラー・データの3状態を網羅する。
class TransactionListNotifier extends AsyncNotifier<List<TransactionItem>> {
  /// DBから全取引を読み込んで返す。
  ///
  /// Provider が初めて参照されたタイミングで1回だけ呼ばれる。
  /// `appDatabaseProvider` 経由で [AppDatabase] を取得し、
  /// `getAllTransactions()` の結果を [TransactionItem] に変換して返す。
  @override
  Future<List<TransactionItem>> build() async {
    final db = ref.read(appDatabaseProvider);
    final rows = await db.getAllTransactions();
    return rows.map(TransactionItem.fromDrift).toList();
  }

  /// 取引を先頭に追加してDBとリストを更新する。
  ///
  /// [item] を `transactions` テーブルに挿入し、採番された ID で
  /// [TransactionItem] を再生成してリストの先頭に追加する。
  Future<void> addItem(TransactionItem item) async {
    final db = ref.read(appDatabaseProvider);

    final insertedId = await db.insertTransaction(
      TransactionsCompanion.insert(
        categoryId: item.category.id,
        amount: item.amount,
        // DateTime を Unix エポック秒に変換して保存する
        date: item.date.millisecondsSinceEpoch,
        memo: Value(item.memo),
      ),
    );

    // DBが採番したIDで TransactionItem を再生成する
    final saved = item.copyWith(id: insertedId.toString());
    final current = state.requireValue;
    state = AsyncData([saved, ...current]);
  }

  /// 指定IDの取引をDBから削除してリストを更新する。
  ///
  /// [id] は `TransactionItem.id`（文字列）で渡される。
  /// DBの主キーは整数のため `int.parse` で変換する。
  Future<void> removeItem(String id) async {
    final db = ref.read(appDatabaseProvider);
    await db.deleteTransaction(int.parse(id));

    final current = state.requireValue;
    state = AsyncData(current.where((t) => t.id != id).toList());
  }
}

/// 取引リスト Provider。
///
/// 参照方法: `ref.watch(transactionListProvider)` → `AsyncValue<List<TransactionItem>>` を返す。
/// 追加: `ref.read(transactionListProvider.notifier).addItem(item)`
/// 削除: `ref.read(transactionListProvider.notifier).removeItem(id)`
final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<TransactionItem>>(
      TransactionListNotifier.new,
    );

/// 明細タブで選択中の年月を管理する Notifier。
///
/// 状態は現在の年月で初期化する。
/// [set] を呼ぶと状態が更新され、[selectedMonthProvider] を watch している
/// ウィジェットが自動で再ビルドされる。
class SelectedMonthNotifier extends Notifier<DateTime> {
  /// 初期値として現在の年月を返す。
  @override
  DateTime build() => DateTime(DateTime.now().year, DateTime.now().month);

  /// 選択中の年月を [month] に更新する。
  void set(DateTime month) => state = month;
}

/// 明細タブで選択中の年月を管理する Provider。
///
/// 参照方法: `ref.watch(selectedMonthProvider)` → [DateTime] を返す。
/// 更新方法: `ref.read(selectedMonthProvider.notifier).set(新しいDateTime)`
final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);
