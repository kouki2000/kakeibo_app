import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 取引入力ページ
class AddTransactionPage extends StatelessWidget {
  /// コンストラクタ
  const AddTransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('取引を追加')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('閉じる'),
        ),
      ),
    );
  }
}
