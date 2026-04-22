/// 取引カテゴリのモデル。
///
/// MVVM の Model 層に位置する。
/// 第10章で `fromDb` ファクトリを追加し、drift 生成の Category から変換できるようにした。
library;

import 'package:kakeibo_app/core/database/app_database.dart' as db;

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconCode,
    this.isIncome = false,
  });

  /// drift の db.Category から Category を生成するファクトリ。
  ///
  /// `app_database.dart` を `as db` でエイリアスすることで
  /// 同名の drift 生成クラスとアプリモデルを区別する。
  factory Category.fromDb(db.Category row) {
    return Category(
      id: row.id,
      name: row.name,
      iconCode: row.iconCode,
      isIncome: row.isIncome,
    );
  }

  /// カテゴリID（例: 'food'）
  final String id;

  /// 表示名（例: '食費'）
  final String name;

  /// Material Icons のコードポイント（例: 'e56c'）
  final String iconCode;

  /// true: 収入カテゴリ / false: 支出カテゴリ
  final bool isIncome;

  /// アプリで使用するデフォルトカテゴリ一覧。
  ///
  /// DBが初期化される前のフォールバックや、テストでの使用を想定して残す。
  static const List<Category> defaults = [
    Category(id: 'food', name: '食費', iconCode: 'e56c'),
    Category(id: 'transport', name: '交通費', iconCode: 'e530'),
    Category(id: 'utility', name: '光熱費', iconCode: 'e1ff'),
    Category(id: 'entertainment', name: '娯楽費', iconCode: 'e87c'),
    Category(id: 'salary', name: '給与', iconCode: 'e227', isIncome: true),
  ];

  static Category findById(String id) =>
      defaults.firstWhere((c) => c.id == id, orElse: () => defaults.first);
}
