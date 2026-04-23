/// 明細タブの取引リスト状態管理。
///
/// MVVM の ViewModel 層に位置する。
/// TransactionListNotifier が AsyncNotifier を継承し、
/// transactionListProvider 経由で View 層（ListTab）に公開する。
///
/// 第7章で drift（SQLite）との接続に切り替えた。
/// 第8章で Firestore への書き込みを追加した。
/// 第10章で `app_database.dart` の import に `as db` エイリアスを追加し、
/// Category の名前衝突を解消した。
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/core/analytics/analytics_service.dart'; // ← 追加かつ順序をここに
import 'package:kakeibo_app/core/database/app_database.dart' as db;
import 'package:kakeibo_app/core/firebase/firestore_service.dart';
import 'package:kakeibo_app/features/transaction/model/transaction_item.dart';

/// 取引リストを非同期で管理する Notifier。
///
/// `AsyncNotifier<T>` を継承することで、状態が `AsyncValue` でラップされる。
/// View 層では `.when()` を使ってローディング・エラー・データの3状態を網羅する。
class TransactionListNotifier extends AsyncNotifier<List<TransactionItem>> {
  /// DBから全取引を読み込んで返す。
  ///
  /// Provider が初めて参照されたタイミングで1回だけ呼ばれる。
  /// appDatabaseProvider 経由で AppDatabase を取得し、
  /// getAllTransactions() の結果を TransactionItem に変換して返す。
  /// 起動時は常に SQLite から読み込む（Firestore への問い合わせは行わない）。
  @override
  Future<List<TransactionItem>> build() async {
    final database = ref.read(db.appDatabaseProvider);
    final rows = await database.getAllTransactions();
    return rows.map(TransactionItem.fromDrift).toList();
  }

  /// 取引を先頭に追加してSQLite・Firestore・リストを更新する。
  ///
  /// 処理順序は次の通り。
  /// 1. SQLite に挿入して採番IDを取得する。
  /// 2. 採番IDで TransactionItem を再生成して状態を更新する。
  /// 3. Analytics にイベントを送信する。
  /// 4. Firestore に書き込む（オフライン時はキューに積まれ、復帰後に自動送信される）。
  Future<void> addItem(TransactionItem item) async {
    final database = ref.read(db.appDatabaseProvider);
    final firestore = ref.read(firestoreServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    final insertedId = await database.insertTransaction(
      db.TransactionsCompanion.insert(
        categoryId: item.category.id,
        amount: item.amount,
        date: item.date.millisecondsSinceEpoch,
        memo: Value(item.memo),
      ),
    );

    final saved = item.copyWith(id: insertedId.toString());
    final current = state.requireValue;
    state = AsyncData([saved, ...current]);

    unawaited(
      analytics
          .logTransactionAdded(
            categoryName: saved.category.name,
            amount: saved.amount,
            isIncome: saved.category.isIncome,
          )
          .catchError((Object e) {
            debugPrint('[AnalyticsService] logTransactionAdded failed: $e');
          }),
    );

    unawaited(
      firestore.saveTransaction(saved).catchError((Object e) {
        debugPrint('[FirestoreService] saveTransaction failed: $e');
      }),
    );
  }

  /// 指定IDの取引をSQLite・Firestore・リストから削除する。
  ///
  /// id は TransactionItem.id（SQLite の採番ID の文字列）。
  /// SQLite の削除を先に行い、UIを即座に更新してから Firestore を削除する。
  Future<void> removeItem(String id) async {
    final database = ref.read(db.appDatabaseProvider);
    final firestore = ref.read(firestoreServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    // SQLite から削除する
    await database.deleteTransaction(int.parse(id));

    // リストから除外して状態を更新する
    final current = state.requireValue;
    state = AsyncData(current.where((t) => t.id != id).toList());

    // Analytics にイベントを送信する（unawaited で UI をブロックしない）
    unawaited(
      analytics.logTransactionDeleted(transactionId: id).catchError((Object e) {
        debugPrint('[AnalyticsService] logTransactionDeleted failed: $e');
      }),
    );

    // Firestore から削除する（unawaited で UI をブロックしない）
    unawaited(
      firestore.deleteTransaction(id).catchError((Object e) {
        debugPrint('[FirestoreService] deleteTransaction failed: $e');
      }),
    );
  }
}

/// 取引リスト Provider。
///
/// 参照方法: `ref.watch(transactionListProvider)` → AsyncValue<List<TransactionItem>> を返す。
/// 追加: `ref.read(transactionListProvider.notifier).addItem(item)`
/// 削除: `ref.read(transactionListProvider.notifier).removeItem(id)`
final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<TransactionItem>>(
      TransactionListNotifier.new,
    );

/// 明細タブで選択中の年月を管理する Notifier。
///
/// 状態は現在の年月で初期化する。
/// update を呼ぶと状態が更新され、
/// selectedMonthProvider を watch しているウィジェットが自動で再ビルドされる。
class SelectedMonthNotifier extends Notifier<DateTime> {
  /// 初期値として現在の年月を返す。
  @override
  DateTime build() => DateTime(DateTime.now().year, DateTime.now().month);

  /// 選択中の年月を更新する。
  void update(DateTime month) => state = month;
}

/// 明細タブで選択中の年月を管理する Provider。
///
/// 参照方法: `ref.watch(selectedMonthProvider)` → DateTime を返す。
/// 更新方法: `ref.read(selectedMonthProvider.notifier).update(新しいDateTime)`
final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);
