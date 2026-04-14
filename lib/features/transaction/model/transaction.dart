import 'package:kakeibo_app/core/utils/formatter.dart';
import 'package:kakeibo_app/features/transaction/model/category.dart';

class Transaction {
  const Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.memo,
  });

  // ---------- factory コンストラクタ ----------

  /// Map（DB行）からインスタンスを生成する
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String, // 明示的な型キャスト
      category: Category.findById(map['categoryId'] as String),
      amount: map['amount'] as int,
      date: DateTime.parse(map['date'] as String),
      memo: map['memo'] as String?, // null 許容型へのキャスト
    );
  }

  final String id;
  final Category category;
  final int amount;
  final DateTime date;
  final String? memo;

  // ---------- シリアライズ ----------

  Map<String, dynamic> toMap() => {
    // アロー関数
    'id': id,
    'categoryId': category.id,
    'amount': amount,
    'date': date.toIso8601String(),
    'memo': memo, // null のまま保存してよい
  };

  // ---------- getter（比較演算子） ----------

  bool get isIncome => amount > 0; // アロー関数
  bool get isExpense => amount < 0;

  /// 金額を「¥980」形式で返す
  String get formattedAmount => Formatter.amount(amount.abs());

  /// 日付を「2024/06/01」形式で返す
  String get formattedDate => Formatter.date(date);

  // ---------- copyWith（?? 演算子） ----------

  /// 指定フィールドだけ変更した新インスタンスを返す
  /// ?? 演算子：引数が null なら元の値を維持する
  Transaction copyWith({
    String? id,
    Category? category,
    int? amount,
    DateTime? date,
    String? memo,
  }) => Transaction(
    id: id ?? this.id,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    memo: memo ?? this.memo,
  );

  @override
  String toString() =>
      'Transaction(id: $id, category: ${category.name}, '
      'amount: $amount, date: $date)';
}
