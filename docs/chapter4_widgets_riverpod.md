# 第4章：Widgets と Riverpod 導入 — 収支サマリ画面を作る

## この章で触るロードマップの範囲

```
Flutter Roadmap
├── Basics of Dart              ✅（第2章）
├── go_router                   ✅（第3章）
└── この章
    ├── Widgets
    │   ├── Stateless Widgets   ← StatelessWidget の実装
    │   ├── Stateful Widgets    ← StatefulWidget との使い分けを理解する
    │   └── Material Widgets    ← Card / ListTile / CircleAvatar
    └── State Management
        └── Riverpod            ← ProviderScope / StateNotifier / ConsumerWidget
```

> ロードマップ画像の該当箇所をスクショで貼り付けてください

---

## この章で扱わないこと

本章では Riverpod の導入とサマリ UI の実装に集中します。データは実際の DB ではなくハードコードのサンプルデータを使います。DB（drift）との接続は第7章で行います。明細タブ・取引入力フォームの UI 実装は第5章以降で扱います。

---

## この章が終わるとこうなる

**ホームタブの画面構成**

```
┌─────────────────────────────────┐
│  ┌───────────────────────────┐  │
│  │  今月の収支               │  │  ← Card（SummaryCard）
│  │  ¥162,570                 │  │
│  │  ─────────────────────    │  │
│  │  収入          ¥250,000   │  │
│  │  支出           ¥87,430   │  │
│  └───────────────────────────┘  │
│                                 │
│  直近の取引                     │  ← RecentList
│  ┌───────────────────────────┐  │
│  │ [給] 給与   04/25  +¥250,000 │
│  │ [食] 食費   04/24    -¥3,200 │
│  │ [交] 交通費 04/23    -¥1,840 │
│  │ [娯] 娯楽費 04/22    -¥4,500 │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

> スクショ：ホームタブに収支サマリカードと直近取引リストが表示されている状態

- `flutter_riverpod` が追加されている
- `ProviderScope` でアプリ全体がラップされている
- `SummaryNotifier` がサンプルデータを保持している
- `HomeTab` が `ConsumerWidget` として実装されている
- `fvm flutter analyze` がクリーンな状態でコミットされている

---

## 1. featureブランチを作る

```bash
git checkout -b feature/ch04-widgets-riverpod
```

OK: `git branch` で `* feature/ch04-widgets-riverpod` が表示されれば次へ

---

## 2. パッケージを追加する

```bash
fvm flutter pub add flutter_riverpod
```

OK: `pubspec.yaml` の `dependencies:` に `flutter_riverpod` が追記されること

参考として執筆時点のバージョンを示します。

```yaml
# pubspec.yaml（抜粋）
dependencies:
  flutter_riverpod: ^2.6.1
```

```bash
fvm flutter pub get
```

OK: エラーなく完了すること

---

## 3. この章で追加・変更するファイルを確認する

```
lib/
├── main.dart                                          変更：ProviderScope を追加
└── features/dashboard/
    ├── model/
    │   └── summary_state.dart                        新規：SummaryState / RecentItem
    ├── view/
    │   ├── home_tab.dart                             変更：ConsumerWidget に置き換え
    │   ├── summary_card.dart                         新規：収支サマリカード
    │   └── recent_list.dart                          新規：直近取引リスト
    └── viewmodel/
        └── summary_notifier.dart                     新規：SummaryNotifier + Provider
```

---

## 4. ProviderScope でアプリをラップする

`lib/main.dart` を以下で丸ごと書き換える。`ProviderScope` は Riverpod の Provider をアプリ全体で有効にするルートウィジェット。`runApp()` の直下に置くことで、すべての子ウィジェットから Provider を参照できるようになる。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/app/router.dart';

void main() {
  runApp(
    // Riverpod を有効化するためアプリ全体を ProviderScope で包む
    const ProviderScope(
      child: KakeiboApp(),
    ),
  );
}

/// アプリのルートウィジェット
class KakeiboApp extends StatelessWidget {
  /// コンストラクタ
  const KakeiboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '家計簿アプリ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
```

OK: IDEのエラーが消えること

---

## 5. 収支サマリの状態クラスを作る

`lib/features/dashboard/model/summary_state.dart` を新規作成する。フィールドをすべて `final` にしたイミュータブルなデータクラスとして定義する。Riverpod は `state = 新インスタンス` で変化を検知するため、フィールドを直接書き換えると検知されない。

```dart
/// 収支サマリの状態を保持するイミュータブルなデータクラス
class SummaryState {
  const SummaryState({
    required this.income,
    required this.expense,
    required this.recentTransactions,
  });

  /// 今月の収入合計（円）
  final int income;

  /// 今月の支出合計（円、正値）
  final int expense;

  /// 直近の取引リスト（表示用）
  final List<RecentItem> recentTransactions;

  /// 収支（income - expense）
  int get balance => income - expense;
}

/// サマリ画面に表示する個々の取引データ
class RecentItem {
  const RecentItem({
    required this.label,
    required this.amount,
    required this.iconCode,
    required this.isIncome,
    required this.dateLabel,
  });

  final String label;
  final int amount;
  final String iconCode;
  final bool isIncome;
  final String dateLabel;
}
```

OK: ファイルが保存されること

---

## 6. SummaryNotifier を作る

`lib/features/dashboard/viewmodel/summary_notifier.dart` を新規作成する。`StateNotifier<T>` は状態 `T` を管理するクラス。状態を変更するときは必ず `state = 新インスタンス` を代入する。ファイル末尾の `summaryProvider` が Riverpod に公開する窓口になる。

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/features/dashboard/model/summary_state.dart';

/// 収支サマリの状態を管理する Notifier
///
/// 第4章ではハードコードのサンプルデータを使用する。
/// DB と接続する実装は第7章（drift）で行う。
class SummaryNotifier extends Notifier<SummaryState> {
  @override
  SummaryState build() => SummaryState(
        income: 250000,
        expense: 87430,
        recentTransactions: [
          const RecentItem(
            label: '給与',
            amount: 250000,
            iconCode: 'e227',
            isIncome: true,
            dateLabel: '04/25',
          ),
          const RecentItem(
            label: '食費',
            amount: 3200,
            iconCode: 'e56c',
            isIncome: false,
            dateLabel: '04/24',
          ),
          const RecentItem(
            label: '交通費',
            amount: 1840,
            iconCode: 'e530',
            isIncome: false,
            dateLabel: '04/23',
          ),
          const RecentItem(
            label: '娯楽費',
            amount: 4500,
            iconCode: 'e87c',
            isIncome: false,
            dateLabel: '04/22',
          ),
        ],
      );
}

/// アプリ全体で共有するサマリ Provider
final summaryProvider = NotifierProvider<SummaryNotifier, SummaryState>(
  SummaryNotifier.new,
);
```

OK: ファイルが保存されること

---

## 7. SummaryCard を作る

`lib/features/dashboard/view/summary_card.dart` を新規作成する。表示に必要な値をすべてコンストラクタで受け取り、自分では状態を持たないため `StatelessWidget` で実装する。`Card` は Material 3 の影付きコンテナで、情報のグループ化に適している。

```dart
import 'package:flutter/material.dart';
import 'package:kakeibo_app/core/utils/formatter.dart';

/// 収支サマリを表示する Card ウィジェット（Stateless）
///
/// 表示に必要なすべての値を外部から受け取る。
/// 自分では状態を持たないため StatelessWidget で十分。
class SummaryCard extends StatelessWidget {
  /// コンストラクタ
  const SummaryCard({
    required this.income,
    required this.expense,
    required this.balance,
    super.key,
  });

  /// 収入合計
  final int income;

  /// 支出合計（正値）
  final int expense;

  /// 収支
  final int balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceColor = balance >= 0
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今月の収支',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              Formatter.amount(balance.abs()),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: balanceColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _AmountRow(label: '収入', amount: income, isIncome: true),
            const SizedBox(height: 8),
            _AmountRow(label: '支出', amount: expense, isIncome: false),
          ],
        ),
      ),
    );
  }
}

/// 収入／支出の行コンポーネント（プライベート）
class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.isIncome,
  });

  final String label;
  final int amount;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final color = isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          Formatter.amount(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
```

OK: ファイルが保存されること

---

## 8. RecentList を作る

`lib/features/dashboard/view/recent_list.dart` を新規作成する。`ListTile` は Material Widgets のひとつで、leading / title / subtitle / trailing の4ゾーンを標準レイアウトで表示できる。データは外部（ConsumerWidget）から注入するため、こちらも `StatelessWidget` で実装する。

```dart
import 'package:flutter/material.dart';
import 'package:kakeibo_app/core/utils/formatter.dart';
import 'package:kakeibo_app/features/dashboard/model/summary_state.dart';

/// 直近の取引一覧を表示するリスト（Stateless）
///
/// データは外部（ConsumerWidget）から注入される。
class RecentList extends StatelessWidget {
  /// コンストラクタ
  const RecentList({required this.items, super.key});

  final List<RecentItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('直近の取引', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => _RecentTile(item: item)),
      ],
    );
  }
}

/// 個々の取引行（プライベート）
class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.item});

  final RecentItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    final sign = item.isIncome ? '+' : '-';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          IconData(
            int.parse(item.iconCode, radix: 16),
            fontFamily: 'MaterialIcons',
          ),
          color: color,
          size: 20,
        ),
      ),
      title: Text(item.label),
      subtitle: Text(item.dateLabel),
      trailing: Text(
        '$sign${Formatter.amount(item.amount)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

OK: ファイルが保存されること

---

## 9. HomeTab を ConsumerWidget に置き換える

`lib/features/dashboard/view/home_tab.dart` を以下で丸ごと書き換える。`ConsumerWidget` は `StatelessWidget` の Riverpod 版で、`build` メソッドの引数に `WidgetRef ref` が追加される。`ref.watch(provider)` で Provider の値を購読し、状態変化時に自動で再ビルドされる。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/features/dashboard/view/recent_list.dart';
import 'package:kakeibo_app/features/dashboard/view/summary_card.dart';
import 'package:kakeibo_app/features/dashboard/viewmodel/summary_notifier.dart';

/// ホームタブ：今月の収支サマリ
///
/// ConsumerWidget を使うことで summaryProvider を watch し、
/// 状態が変わると自動的に再ビルドされる。
class HomeTab extends ConsumerWidget {
  /// コンストラクタ
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // summaryProvider を監視：状態変化で自動再ビルド
    final summary = ref.watch(summaryProvider);

    return ListView(
      children: [
        SummaryCard(
          income: summary.income,
          expense: summary.expense,
          balance: summary.balance,
        ),
        RecentList(items: summary.recentTransactions),
      ],
    );
  }
}
```

OK: IDEのエラーが消えること

---

## 10. 動作確認する

```bash
fvm flutter run
```

以下の3点を確認します。

1. ホームタブに「今月の収支」カードが表示される
2. カード内の収支額が青系（黒字）で表示される
3. カードの下に4件の取引が ListTile で表示される

> スクショ：ホームタブ全体（SummaryCard + RecentList）が表示されている状態

OK: 上記3点が確認できること

---

## 11. コミットして push する

```bash
fvm dart analyze lib/
```

OK: `No issues found!` が表示されれば次へ

```bash
fvm dart format lib/
```

OK: `Formatted N files (0 changed) in 0.xx seconds.` が表示されれば次へ

```bash
git add lib/main.dart
git add lib/features/dashboard/model/summary_state.dart
git add lib/features/dashboard/viewmodel/summary_notifier.dart
git add lib/features/dashboard/view/summary_card.dart
git add lib/features/dashboard/view/recent_list.dart
git add lib/features/dashboard/view/home_tab.dart
git add pubspec.yaml pubspec.lock
git commit -m "feat: add Riverpod SummaryNotifier and HomeTab UI"
git push origin feature/ch04-widgets-riverpod
```

OK: コミットとpushが完了すること

---

## 補足A：基礎知識

### Stateless と Stateful の使い分け

Flutter のウィジェットは大きく2種類に分かれる。

| クラス | 状態 | 典型的な用途 |
|---|---|---|
| `StatelessWidget` | 持たない | 表示のみ。引数で値を受け取り描画する |
| `StatefulWidget` | 持つ（`State<T>`） | タップ・入力など内部で変化する UI |

ただし Riverpod を使う場合、`StatefulWidget` でやっていたデータ管理を Provider 側に移せる。その結果、ほとんどの画面ウィジェットは `ConsumerWidget`（= Stateless 相当）で書けるようになる。

```
StatefulWidget が必要な例：
  - アニメーションコントローラの lifetime 管理
  - TextEditingController / FocusNode の管理
  - initState でのリソース初期化

ConsumerWidget で十分な例：
  - Provider から値を受け取って表示するだけの画面
  - 状態変化を ref.read(provider.notifier).method() で起動するボタン
```

### Riverpod の基本3点セット

```
Notifier<T>
  └ 状態 T を管理するクラス。build() で初期値を返す。
    状態変更は state = 新インスタンス で行う。

NotifierProvider<Notifier, T>
  └ Notifier を外部に公開する Provider。
    アプリ起動時に1回インスタンス化され、ProviderScope の生存期間だけ保持される。

ConsumerWidget / ref.watch(provider)
  └ Provider の値を購読するウィジェット。
    状態が変わると build() が自動で再実行される。
```

### よく使う Material Widgets

| ウィジェット | 役割 |
|---|---|
| `Card` | 影付きのコンテナ。情報のグループ化に使う |
| `ListTile` | leading / title / subtitle / trailing の4ゾーンを持つ行レイアウト |
| `CircleAvatar` | 円形の画像またはアイコン表示エリア |
| `Divider` | 水平の区切り線 |
| `NavigationBar` | Material 3 のボトムナビバー（第3章で導入済み） |

### `ref.watch` と `ref.read` の違い

```dart
// watch：状態変化を監視し、変化があると build() を再実行する
// → build() の中で使う
final summary = ref.watch(summaryProvider);

// read：現在値を1回だけ取得する。再ビルドをトリガーしない
// → onPressed などのコールバック内で使う
ref.read(summaryProvider.notifier).someMethod();
```

### ProviderScope とウィジェットツリーの関係

`ProviderScope` を `runApp()` の直下に置くことで、アプリ全体のウィジェットツリーが Provider を参照できる状態になる。

```
ProviderScope                ← Provider のコンテナ
└── KakeiboApp（MaterialApp.router）
    └── DashboardPage
        └── HomeTab（ConsumerWidget）
            └── ref.watch(summaryProvider)  ← ここで参照できる
```

---

## 補足B：ベストプラクティス

### ウィジェットを小さく分割する理由

`HomeTab` は `SummaryCard` と `RecentList` に分割した。分割することで以下のメリットがある。

- `SummaryCard` 単体でテストできる（値を渡すだけで描画検証が可能）
- 「金額表示だけ変えたい」など部分変更の影響範囲が小さくなる
- ファイルを見ただけでウィジェットの責務が分かる

### プライベートクラス（`_` プレフィックス）を使う

`_AmountRow` と `_RecentTile` のように、同一ファイル内でしか使わないウィジェットは `_` を付けてプライベートにする。他のファイルから誤って参照されることを防ぎ、リファクタリング時の影響範囲を限定できる。

### 状態クラスはイミュータブルにする

`SummaryState` のフィールドをすべて `final` にし、`const` コンストラクタを使う。Riverpod は `state = 新インスタンス` で変化を検知するため、フィールドを直接書き換えると検知されない。

```dart
// NG：フィールドを直接書き換えても再ビルドされない
state.income = 300000;

// OK：新インスタンスを代入する
state = SummaryState(income: 300000, ...);
```

### `withValues` で透明度を指定する（Flutter 3.27 以降）

```dart
// 旧（非推奨警告が出る場合がある）
color.withOpacity(0.12)

// 新（Flutter 3.27 以降、本章のコードで採用）
color.withValues(alpha: 0.12)
```

---

## 補足C：よくあるエラー集

### `StateNotifier` / `StateNotifierProvider` でエラーになる

```
Classes can only extend other classes.
Too many positional arguments: 0 expected, but 1 found.
```

Riverpod 3.0 で `StateNotifier` と `StateNotifierProvider` が廃止された。代わりに `Notifier` と `NotifierProvider` を使う。

| Riverpod 2.x（廃止） | Riverpod 3.x（現行） |
|---|---|
| `extends StateNotifier<T>` | `extends Notifier<T>` |
| `StateNotifier() : super(初期値)` | `@override T build() => 初期値` |
| `StateNotifierProvider((ref) => MyNotifier())` | `NotifierProvider(MyNotifier.new)` |

### `ProviderScope` がないと例外が発生する

```
Error: No ProviderScope found. ...
```

`main.dart` の `runApp()` に渡すウィジェットを `ProviderScope(child: ...)` で包んでいないと発生する。手順4の変更が反映されているか確認する。

### `flutter_riverpod` の import を忘れる

```
The name 'ConsumerWidget' isn't a type.
The name 'StateNotifier' isn't a type.
```

`flutter_riverpod` の import が抜けている。各ファイルの先頭に以下を追加する。

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

### `ref.watch` を `build` 外で呼ぶと警告が出る

```
ref.watch was called outside of a widget's build method.
```

`ref.watch` は `build()` の中だけで使う。`onPressed` などのコールバック内では `ref.read` を使う。

### `IconData` のコードポイントが正しくない

`int.parse(item.iconCode, radix: 16)` の `radix: 16` を忘れると `NumberFormatException` が発生する。Material Icons のコードポイントは16進数（例: `'e56c'`）のため、変換時に基数の指定が必須。

```dart
// NG：radix を忘れると NumberFormatException
IconData(int.parse(item.iconCode), fontFamily: 'MaterialIcons')

// OK
IconData(int.parse(item.iconCode, radix: 16), fontFamily: 'MaterialIcons')
```

### `pubspec.yaml` 変更後に `fvm flutter pub get` を忘れる

```
Target of URI doesn't exist: 'package:flutter_riverpod/flutter_riverpod.dart'.
```

`pubspec.yaml` を編集しただけではパッケージは取得されない。必ず `fvm flutter pub get` を実行する。

---

## 次の章

第5章では**取引入力フォーム**を実装します。`TextFormField` / `DropdownButtonFormField` などの Form 系 Widgets を使って収支の登録 UI を作りながら、`StatefulWidget` と `TextEditingController` の使い方、入力バリデーションの実装を身につけます。