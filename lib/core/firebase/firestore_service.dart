/// Firestore への読み書きをまとめたサービスクラス。
///
/// MVVM の Model 層（データソース）に位置する。
/// `cloud_firestore` の [FirebaseFirestore] を直接扱うコードをここに集約し、
/// ViewModel 層（`TransactionListNotifier`）からは [FirestoreService] 経由でのみ
/// Firestore にアクセスする。
/// [firestoreServiceProvider] 経由で ViewModel 層に公開する。
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/features/transaction/model/transaction_item.dart';

/// Firestore の取引コレクション名。
const _kCollection = 'transactions';

/// Firestore の取引コレクションへの読み書きを提供するサービス。
///
/// コレクション名は [_kCollection] で管理し、ドキュメントIDとして
/// SQLite の採番ID（文字列変換）を使うことで、ローカルとクラウドの
/// レコードを対応付けられるようにする。
class FirestoreService {
  /// コンストラクタ。
  ///
  /// [_firestore] は依存注入のために引数で受け取る。
  /// 省略時は `FirebaseFirestore.instance`（本番用）を使う。
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// [item] を Firestore の `transactions` コレクションに書き込む。
  ///
  /// ドキュメントIDに [TransactionItem.id] を使うことで
  /// SQLite のレコードと1対1で対応付ける。
  /// `set` を使うため、同じIDのドキュメントが存在する場合は上書きされる。
  Future<void> saveTransaction(TransactionItem item) async {
    await _firestore.collection(_kCollection).doc(item.id).set({
      'categoryId': item.category.id,
      'amount': item.amount,
      // DateTime を Unix エポック秒（ミリ秒）で保存する
      'date': item.date.millisecondsSinceEpoch,
      'memo': item.memo,
    });
  }

  /// 指定IDのドキュメントを Firestore から削除する。
  ///
  /// [id] は `TransactionItem.id`（SQLite の採番ID の文字列）。
  /// ドキュメントが存在しない場合もエラーにならない。
  Future<void> deleteTransaction(String id) async {
    await _firestore.collection(_kCollection).doc(id).delete();
  }
}

/// [FirestoreService] インスタンスを提供する Provider。
///
/// `Provider` を使い、アプリ起動中は同一インスタンスを使い回す。
/// テスト時は `ProviderScope` の `overrides` でモックに差し替え可能。
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
