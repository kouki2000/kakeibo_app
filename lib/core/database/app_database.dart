/// SQLiteデータベースの定義。
///
/// MVVM の Model 層（データソース）に位置する。
/// [AppDatabase] がテーブル定義とクエリを保持し、
/// `appDatabaseProvider` 経由で ViewModel 層に公開する。
/// `app_database.g.dart` は build_runner が自動生成するため手動編集禁止。
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 取引テーブルの定義。
///
/// drift では [Table] を継承したクラスでテーブルスキーマを定義する。
/// クラス名 `Transactions` がテーブル名 `transactions` に変換される。
/// 各フィールドは対応するSQLite型にマッピングされる。
class Transactions extends Table {
  /// 自動採番の主キー。`autoIncrement()` を付けると `INTEGER PRIMARY KEY AUTOINCREMENT` になる。
  IntColumn get id => integer().autoIncrement()();

  /// カテゴリID（例: 'food'）。`Category.id` と対応する。
  TextColumn get categoryId => text()();

  /// 金額（正値）。収支の区別は `categoryId` の isIncome フラグで判断する。
  IntColumn get amount => integer()();

  /// 取引日。SQLiteにはネイティブの日付型がないため Unix エポック秒（整数）で保存する。
  IntColumn get date => integer()();

  /// メモ（任意）。`nullable()` でNULL許容にする。
  TextColumn get memo => text().nullable()();
}

/// アプリ全体で使用するSQLiteデータベース。
///
/// `@DriftDatabase` アノテーションで使用するテーブルを宣言する。
/// `_$AppDatabase` は build_runner が生成する基底クラス。
/// [schemaVersion] はマイグレーション管理に使用する。
@DriftDatabase(tables: [Transactions])
class AppDatabase extends _$AppDatabase {
  /// コンストラクタ。[_openConnection] でプラットフォームに適したDBファイルを開く。
  AppDatabase() : super(_openConnection());

  /// テスト用のコンストラクタ。インメモリDBで動作確認できる。
  AppDatabase.forTesting(super.executor);

  /// スキーマバージョン。テーブル定義を変更したら値を上げてマイグレーションを書く。
  @override
  int get schemaVersion => 1;

  /// すべての取引を日付の降順で取得する。
  ///
  /// `select` → `orderBy` で型安全なクエリを組み立てる。
  /// 戻り値は `Future<List<Transaction>>` で、行1件が `Transaction` オブジェクトに対応する。
  Future<List<Transaction>> getAllTransactions() {
    return (select(transactions)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .get();
  }

  /// 取引を1件挿入する。
  ///
  /// [companion] は build_runner が生成する `TransactionsCompanion` を使う。
  /// `InsertMode.insertOrReplace` で同一主キーの重複を防ぐ。
  Future<int> insertTransaction(TransactionsCompanion companion) {
    return into(transactions).insert(companion);
  }

  /// 指定IDの取引を削除する。
  ///
  /// 削除された行数を返す。0 のときは該当レコードなし。
  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}

/// DBファイルを開く接続を返す。
///
/// [LazyDatabase] を使うことで、実際にDBが必要になるまでファイルのオープンを遅延できる。
/// `path_provider` でプラットフォームごとのドキュメントディレクトリを取得し、
/// その中に `kakeibo.sqlite` ファイルを作成する。
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'kakeibo.sqlite'));
    return NativeDatabase(file);
  });
}

/// DBインスタンスを提供する Provider。
///
/// `Provider` を使い、アプリ起動中は同一インスタンスを使い回す。
/// テスト時は `ProviderScope` の `overrides` でインメモリDBに差し替え可能。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Provider が破棄されるときにDBを閉じる
  ref.onDispose(db.close);
  return db;
});
