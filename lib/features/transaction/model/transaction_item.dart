/// 明細タブの1行に対応する表示専用モデル。
///
/// MVVM の Model 層に位置する。
/// `TransactionListNotifier` が [TransactionItem] のリストを状態として保持し、
/// `ListTab` が `transactionListProvider` 経由で参照する。
/// 第7章では drift の `TransactionData` からこのクラスへの変換処理を追加する。
library;

import 'package:kakeibo_app/features/transaction/model/category.dart';

/// 明細タブに表示する取引1件のデータクラス。
///
/// フィールドはすべて `final` で、状態変更時は新インスタンスを生成する。
/// [id] は削除操作の識別子として使用する。
class TransactionItem {
  /// コンストラクタ。
  const TransactionItem({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.memo,
  });

  /// 取引を一意に識別する ID。削除操作で使用する。
  final String id;

  /// 取引のカテゴリ。
  final Category category;

  /// 金額（正値）。収支の区別は `category.isIncome` で判断する。
  final int amount;

  /// 取引日。月別フィルタリングに使用する。
  final DateTime date;

  /// メモ（任意）。`null` のときは表示しない。
  final String? memo;

  /// `true` のとき収入。[Category.isIncome] の委譲。
  bool get isIncome => category.isIncome;

  /// 指定フィールドだけ変更した新インスタンスを返す。
  TransactionItem copyWith({
    String? id,
    Category? category,
    int? amount,
    DateTime? date,
    String? memo,
  }) => TransactionItem(
    id: id ?? this.id,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    memo: memo ?? this.memo,
  );
}
