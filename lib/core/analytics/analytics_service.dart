/// Firebase Analytics へのイベント送信をまとめたサービスクラス。
///
/// アプリ内で記録するカスタムイベントをすべてここに定義する。
/// ViewModel 層からは [AnalyticsService] 経由でのみ Analytics にアクセスする。
/// [analyticsServiceProvider] 経由で ViewModel 層に公開する。
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Analytics へのイベント送信を提供するサービス。
///
/// イベント名・パラメータ名はすべてこのクラスで一元管理する。
/// Firebase コンソールのイベント名と同期させるため、
/// スネークケース・40文字以内・英数字とアンダースコアのみを使うこと。
class AnalyticsService {
  /// コンストラクタ。
  ///
  /// [_analytics] は依存注入のために引数で受け取る。
  /// 省略時は `FirebaseAnalytics.instance`（本番用）を使う。
  AnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// Firebase Analytics のインスタンスを返す。
  ///
  /// [FirebaseAnalyticsObserver] を go_router に渡すために使う。
  FirebaseAnalytics get instance => _analytics;

  /// 取引が追加されたときに記録するイベント。
  ///
  /// パラメータ：
  /// - `category_name`：カテゴリ名（例: "食費"）
  /// - `amount`：金額（円）
  /// - `is_income`：収入なら true、支出なら false
  Future<void> logTransactionAdded({
    required String categoryName,
    required int amount,
    required bool isIncome,
  }) async {
    await _analytics.logEvent(
      name: 'transaction_added',
      parameters: {
        'category_name': categoryName,
        'amount': amount,
        'is_income': isIncome ? 1 : 0, // bool → int に変換
      },
    );
  }

  /// 取引が削除されたときに記録するイベント。
  ///
  /// パラメータ：
  /// - `transaction_id`：削除した取引のID（SQLite の採番ID の文字列）
  Future<void> logTransactionDeleted({required String transactionId}) async {
    await _analytics.logEvent(
      name: 'transaction_deleted',
      parameters: {'transaction_id': transactionId},
    );
  }
}

/// [AnalyticsService] インスタンスを提供する Provider。
///
/// `Provider` を使い、アプリ起動中は同一インスタンスを使い回す。
/// テスト時は `ProviderScope` の `overrides` でモックに差し替え可能。
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
