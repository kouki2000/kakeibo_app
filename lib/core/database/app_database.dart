/// SQLiteデータベースの定義。
///
/// MVVM の Model 層（データソース）に位置する。
/// [AppDatabase] がテーブル定義とクエリを保持し、
/// `appDatabaseProvider` 経由で ViewModel 層に公開する。
/// `app_database.g.dart` は build_runner が自動生成するため手動編集禁止。
///
/// 第10章で [Categories] テーブルを追加し、[schemaVersion] を 2 に上げた。
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// カテゴリテーブルの定義。
///
/// カテゴリIDは文字列（例: 'food'）で主キーとする。
/// 自動採番ではなく、アプリ側で意味のある ID を付与する。
class Categories extends Table {
  /// カテゴリID（例: 'food'）。文字列の主キー。
  TextColumn get id => text()();

  /// 表示名（例: '食費'）。
  TextColumn get name => text()();

  /// Material Icons のコードポイント（例: 'e56c'）。
  TextColumn get iconCode => text()();

  /// true: 収入カテゴリ / false: 支出カテゴリ。
  /// drift では bool を `boolean()` で定義し、SQLite 上は 0/1 の整数で保存される。
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();

  /// 主キーを `id`（文字列）に設定する。
  ///
  /// drift のデフォルト主キーは `autoIncrement()` を付けた整数カラムだが、
  /// `primaryKey` をオーバーライドすることで任意のカラムを主キーにできる。
  @override
  Set<Column> get primaryKey => {id};
}

/// 取引テーブルの定義。
///
/// drift では [Table] を継承したクラスでテーブルスキーマを定義する。
/// クラス名 `Transactions` がテーブル名 `transactions` に変換される。
class Transactions extends Table {
  /// 自動採番の主キー。
  IntColumn get id => integer().autoIncrement()();

  /// カテゴリID。[Categories.id] を参照する外部キー。
  TextColumn get categoryId => text().references(Categories, #id)();

  /// 金額（正値）。収支の区別は JOIN したカテゴリの isIncome フラグで判断する。
  IntColumn get amount => integer()();

  /// 取引日。Unix エポック秒（ミリ秒）で保存する。
  IntColumn get date => integer()();

  /// メモ（任意）。
  TextColumn get memo => text().nullable()();
}

/// JOIN クエリの結果を保持するデータクラス。
///
/// drift の `TypedResult` を使って取引とカテゴリを結合した結果を
/// Dart のデータクラスとして扱えるようにする。
/// build_runner はこのクラスを生成しないため手動で定義する。
class TransactionWithCategory {
  /// コンストラクタ。
  const TransactionWithCategory({
    required this.transaction,
    required this.category,
  });

  /// 取引行データ。build_runner が生成する `Transaction` データクラス。
  final Transaction transaction;

  /// カテゴリ行データ。build_runner が生成する `Category` データクラス。
  final Category category;
}

/// アプリ全体で使用するSQLiteデータベース。
///
/// `@DriftDatabase` アノテーションで使用するテーブルを宣言する。
/// 第10章で [Categories] テーブルを追加した。
@DriftDatabase(tables: [Transactions, Categories])
class AppDatabase extends _$AppDatabase {
  /// コンストラクタ。
  AppDatabase() : super(_openConnection());

  /// テスト用のコンストラクタ。インメモリDBで動作確認できる。
  AppDatabase.forTesting(super.executor);

  /// スキーマバージョン。
  ///
  /// 第10章で 1 → 2 に上げた。[migration] で移行処理を定義する。
  @override
  int get schemaVersion => 2;

  /// マイグレーション戦略。
  ///
  /// [schemaVersion] が上がったとき、古いバージョンから新しいバージョンへの
  /// 移行処理をここに書く。`from` は移行前のバージョン、`to` は移行後のバージョン。
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        // 初回インストール時：全テーブルを作成してシードデータを挿入する
        await m.createAll();
        await _seedCategories();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // バージョン1 → 2：categories テーブルを追加してシードデータを挿入する
          await m.createTable(categories);
          await _seedCategories();
        }
      },
    );
  }

  /// デフォルトカテゴリをDBに挿入する。
  ///
  /// `insertOnConflictUpdate` を使うことで、すでに同じIDのカテゴリが存在する場合は
  /// 上書きする（アプリ更新でカテゴリ名・アイコンを変更したい場合に対応できる）。
  Future<void> _seedCategories() async {
    const seeds = [
      CategoriesCompanion(
        id: Value('food'),
        name: Value('食費'),
        iconCode: Value('e56c'),
        isIncome: Value(false),
      ),
      CategoriesCompanion(
        id: Value('transport'),
        name: Value('交通費'),
        iconCode: Value('e530'),
        isIncome: Value(false),
      ),
      CategoriesCompanion(
        id: Value('utility'),
        name: Value('光熱費'),
        iconCode: Value('e1ff'),
        isIncome: Value(false),
      ),
      CategoriesCompanion(
        id: Value('entertainment'),
        name: Value('娯楽費'),
        iconCode: Value('e87c'),
        isIncome: Value(false),
      ),
      CategoriesCompanion(
        id: Value('salary'),
        name: Value('給与'),
        iconCode: Value('e227'),
        isIncome: Value(true),
      ),
    ];

    for (final seed in seeds) {
      await into(categories).insertOnConflictUpdate(seed);
    }
  }

  /// すべてのカテゴリを取得する。
  ///
  /// `add_transaction_page.dart` のドロップダウンで使用する。
  Future<List<Category>> getAllCategories() {
    return select(categories).get();
  }

  /// すべての取引をカテゴリと JOIN して日付の降順で取得する。
  ///
  /// `join` で `transactions` と `categories` を結合する。
  /// 戻り値の `TypedResult` から各テーブルの行データを取り出す。
  Future<List<TransactionWithCategory>> getAllTransactions() {
    final query =
        select(transactions).join([
          innerJoin(
            categories,
            categories.id.equalsExp(transactions.categoryId),
          ),
        ])..orderBy([
          OrderingTerm(expression: transactions.date, mode: OrderingMode.desc),
        ]);

    return query.map((row) {
      return TransactionWithCategory(
        transaction: row.readTable(transactions),
        category: row.readTable(categories),
      );
    }).get();
  }

  /// 取引を1件挿入する。
  Future<int> insertTransaction(TransactionsCompanion companion) {
    return into(transactions).insert(companion);
  }

  /// 指定IDの取引を削除する。
  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}

/// DBファイルを開く接続を返す。
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'kakeibo.sqlite'));
    return NativeDatabase(file);
  });
}

/// DBインスタンスを提供する Provider。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
