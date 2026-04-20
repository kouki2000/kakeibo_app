# 家計簿アプリ 開発用コマンド集
# 使い方: make <ターゲット名>

.PHONY: help doc doc-open analyze format

## ヘルプを表示する
help:
	@grep -E '^##' Makefile | sed 's/## //'

## API ドキュメントを生成する（doc/api/index.html）
doc:
	fvm dart doc .

## API ドキュメントを生成してブラウザで開く
doc-open: doc
	open doc/api/index.html

## 静的解析を実行する
analyze:
	fvm dart analyze lib/

## コードフォーマットを実行する
format:
	fvm dart format lib/