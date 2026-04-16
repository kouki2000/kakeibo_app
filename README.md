# 家計簿アプリ

Flutter で作る家計簿アプリ（MoneyForward ME 風）。  
社内 Flutter 学習シリーズのサンプルリポジトリ。

---

## フォルダ構成

```
lib/
├── main.dart                        # エントリポイント。ProviderScope・appRouter を組み合わせる
├── app/
│   └── router.dart                  # 全画面のルーティング定義（go_router）
├── core/
│   └── utils/
│       └── formatter.dart           # 金額・日付のフォーマットユーティリティ
└── features/                        # 機能ごとのディレクトリ（MVVM 構成）
    ├── dashboard/                   # ホームタブ・明細タブ
    │   ├── model/
    │   │   └── summary_state.dart   # 収支サマリの状態モデル
    │   ├── view/
    │   │   ├── dashboard_page.dart  # ボトムナビ付き scaffold
    │   │   ├── home_tab.dart        # ホームタブ（ConsumerWidget）
    │   │   ├── list_tab.dart        # 明細タブ（第5章で実装）
    │   │   ├── summary_card.dart    # 収支サマリカード
    │   │   ├── recent_list.dart     # 直近取引リスト
    │   │   └── add_transaction_page.dart  # 取引入力ページ（第5章で実装）
    │   └── viewmodel/
    │       └── summary_notifier.dart  # SummaryNotifier + summaryProvider
    └── transaction/
        ├── model/
        │   ├── transaction.dart     # 取引モデル
        │   └── category.dart        # カテゴリマスタ
        └── view/                    # （第5章以降）
```

### MVVM レイヤーの対応表

| レイヤー | 場所 | 役割 |
|---|---|---|
| Model | `*/model/*.dart` | データ構造・DB 変換ロジック |
| ViewModel | `*/viewmodel/*.dart` | 状態管理（Riverpod Notifier） |
| View | `*/view/*.dart` | 画面描画のみ。状態は持たない |

---

## 開発環境のセットアップ

第1章を参照してください。FVM を使って Flutter バージョンを管理します。

```bash
fvm use         # .fvm/fvm_config.json に記載のバージョンを使用
fvm flutter pub get
fvm flutter run
```

---

## よく使うコマンド

```bash
make analyze    # 静的解析（fvm dart analyze lib/）
make format     # フォーマット（fvm dart format lib/）
make doc        # API ドキュメント生成（doc/api/index.html）
make doc-open   # 生成してブラウザで開く（macOS）
```

---

## API ドキュメント

各クラス・関数には `///` コメント（DartDoc）を記述しています。  
`fvm dart doc .` または `make doc` で HTML ドキュメントを生成できます。

```
doc/api/index.html  ← ブラウザで開く
```

main ブランチへのマージ時に GitHub Actions が自動生成し、GitHub Pages へ公開します。  
公開 URL: `https://kouki2000.github.io/kakeibo_app/`（GitHub Pages 有効化後）

### コメント漏れの検知

`analysis_options.yaml` に `public_member_api_docs: true` を設定しているため、  
public なクラス・メソッドに `///` がない場合は lint 警告が表示されます。

---

## 技術スタック

| 用途 | パッケージ |
|---|---|
| Flutter バージョン管理 | FVM |
| ルーティング | go_router |
| 状態管理 | flutter_riverpod |
| ローカル DB | drift（第7章で導入） |
| クラウド DB | Firebase Firestore（第8章で導入） |
| CI / CD | GitHub Actions |
| Lint | very_good_analysis |