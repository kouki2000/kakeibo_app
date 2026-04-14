// tool/model_check.dart
// ignore_for_file: avoid_print
import 'package:kakeibo_app/features/transaction/model/category.dart';
import 'package:kakeibo_app/core/utils/formatter.dart';
import 'package:kakeibo_app/features/transaction/model/transaction.dart';

void main() {
  // --- Category ---
  print('=== Category ===');
  for (final c in Category.defaults) {
    print('  ${c.name} (isIncome: ${c.isIncome})');
  }

  // --- Transaction ---
  print('\n=== Transaction ===');
  final tx = Transaction(
    id: 'test-001',
    category: Category.defaults[0],
    amount: -980,
    date: DateTime(2024, 6, 1),
    memo: 'コンビニ',
  );
  print('  $tx');
  print('  formattedAmount : ${tx.formattedAmount}');
  print('  formattedDate   : ${tx.formattedDate}');
  print('  isExpense       : ${tx.isExpense}');

  // --- copyWith ---
  print('\n=== copyWith ===');
  final updated = tx.copyWith(amount: -1200);
  print('  original : ${tx.amount}');
  print('  updated  : ${updated.amount}');
  assert(tx.amount == -980, 'original は変更されていないこと');

  // --- fromMap / toMap ---
  print('\n=== fromMap / toMap ===');
  final restored = Transaction.fromMap(tx.toMap());
  assert(restored.id == tx.id, 'id が一致すること');
  print('  restored : $restored');

  // --- Formatter ---
  print('\n=== Formatter ===');
  print('  ${Formatter.amount(1500)}');
  print('  ${Formatter.amount(1234567)}');
  print('  ${Formatter.date(DateTime(2024, 6, 1))}');
  print('  ${Formatter.yearMonth(DateTime(2024, 6, 1))}');

  print('\n全テスト OK');
}
