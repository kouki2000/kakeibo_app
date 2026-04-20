/// 明細タブの取引リスト状態管理。
///
/// MVVM の ViewModel 層に位置する。
/// [TransactionListNotifier] が `AsyncNotifier<List<TransactionItem>>` を継承し、
/// [transactionListProvider] 経由で View 層（`ListTab`）に公開する。
///
/// 第6章では初期データをメモリ上で管理する。
/// 第7章で drift（SQLite）との接続に切り替える。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/features/transaction/model/category.dart';
import 'package:kakeibo_app/features/transaction/model/transaction_item.dart';

/// 取引リストを非同期で管理する Notifier。
///
/// `AsyncNotifier<T>` を継承することで、状態が [AsyncValue] でラップされる。
/// View 層では `.when()` を使ってローディング・エラー・データの3状態を網羅する。
class TransactionListNotifier extends AsyncNotifier<List<TransactionItem>> {
  /// 初期データをロードして返す。
  ///
  /// Provider が初めて参照されたタイミングで1回だけ呼ばれる。
  /// `await Future.delayed` で DB アクセスを想定した非同期処理をシミュレートする。
  /// 第7章では drift のクエリ結果を返すよう書き換える。
  @override
  Future<List<TransactionItem>> build() async {
    // DB アクセスのシミュレーション（第7章で drift のクエリに差し替える）
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _initialItems;
  }

  /// 取引を先頭に追加してリストを更新する。
  ///
  /// [item] を現在のリストの先頭に挿入した新しいリストを `state` に代入する。
  /// `state.requireValue` は状態が `AsyncData` のときだけ使用できる。
  Future<void> addItem(TransactionItem item) async {
    final current = state.requireValue;
    state = AsyncData([item, ...current]);
  }

  /// 指定 ID の取引を削除してリストを更新する。
  ///
  /// [id] に一致する要素を除いた新しいリストを `state` に代入する。
  Future<void> removeItem(String id) async {
    final current = state.requireValue;
    state = AsyncData(current.where((t) => t.id != id).toList());
  }

  /// 開発用の初期データ。
  ///
  /// 第7章で drift への移行後は不要になる。
  static final List<TransactionItem> _initialItems = [
    TransactionItem(
      id: '1',
      category: Category.findById('salary'),
      amount: 250000,
      date: DateTime(2025, 4, 25),
    ),
    TransactionItem(
      id: '2',
      category: Category.findById('food'),
      amount: 3200,
      date: DateTime(2025, 4, 24),
      memo: 'スーパー',
    ),
    TransactionItem(
      id: '3',
      category: Category.findById('transport'),
      amount: 1840,
      date: DateTime(2025, 4, 23),
    ),
    TransactionItem(
      id: '4',
      category: Category.findById('entertainment'),
      amount: 4500,
      date: DateTime(2025, 4, 22),
      memo: '映画',
    ),
    TransactionItem(
      id: '5',
      category: Category.findById('food'),
      amount: 2100,
      date: DateTime(2025, 3, 28),
    ),
    TransactionItem(
      id: '6',
      category: Category.findById('transport'),
      amount: 990,
      date: DateTime(2025, 3, 15),
    ),
  ];
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
