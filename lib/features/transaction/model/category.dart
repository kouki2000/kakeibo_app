class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconCode,
    this.isIncome = false,
  });

  /// カテゴリID（例: 'food'）
  final String id;

  /// 表示名（例: '食費'）
  final String name;

  /// Material Icons のコードポイント（例: 'e56c'）
  final String iconCode;

  /// true: 収入カテゴリ / false: 支出カテゴリ
  final bool isIncome;

  /// アプリで使用するデフォルトカテゴリ一覧
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
