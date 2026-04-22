/// 明細タブの1行に対応する表示専用モデル。
///
/// MVVM の Model 層に位置する。
/// `TransactionListNotifier` が [TransactionItem] のリストを状態として保持し、
/// `ListTab` が `transactionListProvider` 経由で参照する。
/// 第10章で [fromDrift] の引数を JOIN 結果対応に変更した。
library;

import 'package:kakeibo_app/core/database/app_database.dart' as db;
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

  /// drift の JOIN 結果 [db.TransactionWithCategory] から [TransactionItem] を生成するファクトリ。
  ///
  /// 第10章で引数を `Transaction`（単体行）から [db.TransactionWithCategory]（JOIN結果）に変更した。
  /// カテゴリ情報を JOIN 結果から直接取得するため、`Category.findById` のコード内検索が不要になる。
  /// `app_database.dart` を `as db` でエイリアスすることで同名の drift 生成 `Category` と区別する。
  factory TransactionItem.fromDrift(db.TransactionWithCategory row) {
    return TransactionItem(
      id: row.transaction.id.toString(),
      category: Category.fromDb(row.category),
      amount: row.transaction.amount,
      date: DateTime.fromMillisecondsSinceEpoch(row.transaction.date),
      memo: row.transaction.memo,
    );
  }

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
