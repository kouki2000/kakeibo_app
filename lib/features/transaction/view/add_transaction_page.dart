/// 取引入力ページの View。
///
/// MVVM の View 層に位置する。
/// [StatefulWidget] で実装し、[TextEditingController] / [FocusNode] /
/// [GlobalKey] でフォームの入力状態を管理する。
/// 保存時に `summaryProvider.notifier` の `addTransaction` を呼び出して
/// ホームタブのサマリを更新する。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakeibo_app/features/dashboard/model/summary_state.dart';
import 'package:kakeibo_app/features/dashboard/viewmodel/summary_notifier.dart';
import 'package:kakeibo_app/features/transaction/model/category.dart';

/// 取引入力ページ。
///
/// [ConsumerStatefulWidget] を継承することで [WidgetRef] と
/// [State] ライフサイクル（[initState] / [dispose]）の両方を利用できる。
class AddTransactionPage extends ConsumerStatefulWidget {
  /// コンストラクタ。
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  /// フォーム全体を識別するキー。バリデーション呼び出しに使用する。
  final _formKey = GlobalKey<FormState>();

  /// 金額フィールドのコントローラ。
  final _amountController = TextEditingController();

  /// メモフィールドのコントローラ。
  final _memoController = TextEditingController();

  /// 金額フィールドのフォーカス管理。
  final _amountFocusNode = FocusNode();

  /// 収入 / 支出の選択状態。`true` のとき収入。
  bool _isIncome = false;

  /// 選択中のカテゴリ。
  Category _selectedCategory = Category.defaults.first;

  /// 選択中の日付。
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    // コントローラと FocusNode はウィジェットが破棄されるときに必ず解放する
    _amountController.dispose();
    _memoController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  /// DatePicker を表示して選択日付を更新する。
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// フォームのバリデーションを実行して取引を保存する。
  void _save() {
    // validate() が false を返した場合は各フィールドのエラーメッセージが表示される
    if (!_formKey.currentState!.validate()) return;

    final amount = int.parse(_amountController.text);
    final mm = _selectedDate.month.toString().padLeft(2, '0');
    final dd = _selectedDate.day.toString().padLeft(2, '0');

    final item = RecentItem(
      label: _selectedCategory.name,
      amount: amount,
      iconCode: _selectedCategory.iconCode,
      isIncome: _isIncome,
      dateLabel: '$mm/$dd',
    );

    ref.read(summaryProvider.notifier).addTransaction(item);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // 選択中のカテゴリをセグメントの状態に合わせてフィルタリング
    final categories = Category.defaults
        .where((c) => c.isIncome == _isIncome)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('取引を追加'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // ---- 収入 / 支出 切り替え ----
            const _SectionLabel(label: '種別'),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('支出')),
                ButtonSegment(value: true, label: Text('収入')),
              ],
              selected: {_isIncome},
              onSelectionChanged: (selected) {
                setState(() {
                  _isIncome = selected.first;
                  // 種別が変わったらカテゴリを先頭に戻す
                  _selectedCategory = Category.defaults.firstWhere(
                    (c) => c.isIncome == _isIncome,
                  );
                });
              },
            ),
            const SizedBox(height: 24),

            // ---- 金額 ----
            const _SectionLabel(label: '金額（円）'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: TextInputType.number,
              // 数字以外の入力を弾く
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '例: 3200',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return '金額を入力してください';
                final n = int.tryParse(value);
                if (n == null || n <= 0) return '1以上の整数を入力してください';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ---- カテゴリ ----
            const _SectionLabel(label: 'カテゴリ'),
            const SizedBox(height: 8),
            DropdownButtonFormField<Category>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
              validator: (value) => value == null ? 'カテゴリを選択してください' : null,
            ),
            const SizedBox(height: 24),

            // ---- 日付 ----
            const _SectionLabel(label: '日付'),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              // タップで DatePicker を開く
              onTap: _pickDate,
              decoration: const InputDecoration(
                hintText: '日付を選択',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today_outlined),
                // controller を使わず直接 controller に値を表示させる代わりに
                // labelText で選択済み日付を表示する
              ),
              controller: TextEditingController(
                text:
                    '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 24),

            // ---- メモ ----
            const _SectionLabel(label: 'メモ（任意）'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                hintText: '例: コンビニ',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
          ],
        ),
      ),
    );
  }
}

/// フォームフィールドの上に表示するセクションラベル。
///
/// ファイル内でのみ使うプライベートウィジェット。
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelLarge);
  }
}
