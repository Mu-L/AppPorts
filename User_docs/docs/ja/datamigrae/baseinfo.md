---
outline: deep
---

# データ移行の基本実装

![](https://pic.cdn.shimoko.com/appports/%E6%88%AA%E5%B1%8F2026-05-08%2008.38.05.png)

AppPorts のデータ移行機能は、アプリに関連するデータディレクトリ（`~/Library/Application Support`、`~/Library/Caches` など）を外部ストレージに移行し、ローカルのディスク容量を解放します。

## コア戦略：シンボリックリンク

データディレクトリの移行には**Whole Symlink**戦略を使用します：

1. 元のローカルディレクトリ全体を外部ストレージにコピー
2. 管理リンクメタデータ（`.appports-link-metadata.plist`）を外部ディレクトリに書き込む
3. 元のローカルディレクトリを削除
4. 元のパスに外部コピーを指すシンボリックリンクを作成

```
~/Library/Application Support/SomeApp
    → /Volumes/External/AppPortsData/SomeApp  (symlink)
```

## 移行フロー

```mermaid
flowchart TD
    A[データディレクトリを選択] --> B{権限と保護チェック}
    B -->|失敗| Z[終了]
    B -->|成功| C{ターゲットパスの競合検出}
    C -->|管理メタデータあり| D[自動回復モード]
    C -->|競合なし| E[外部ストレージにコピー]
    D --> E
    E --> F[管理リンクメタデータを書き込み]
    F --> G[ローカルディレクトリを削除]
    G -->|失敗| H[ロールバック: 外部コピーを削除]
    G -->|成功| I[シンボリックリンクを作成]
    I -->|失敗| J[緊急ロールバック: ローカルにコピーし直す]
    I -->|成功| K[移行完了]
```

## 管理リンクメタデータ

AppPorts は、そのディレクトリが AppPorts によって管理されていることを識別するために、外部ディレクトリに `.appports-link-metadata.plist` ファイルを書き込みます。メタデータには以下の情報が含まれます：

| フィールド | 説明 |
|-----------|------|
| `schemaVersion` | メタデータバージョン番号（現在は1） |
| `managedBy` | 管理者識別子（`com.shimoko.AppPorts`） |
| `sourcePath` | 元のローカルパス |
| `destinationPath` | 外部ストレージのターゲットパス |
| `dataDirType` | データディレクトリタイプ |

このメタデータはスキャン時に使用され、AppPorts 管理のリンクとユーザーが作成したシンボリックリンクを区別し、移行中断時の自動回復をサポートします。

## サポートされるデータディレクトリタイプ

| タイプ | パスの例 |
|--------|---------|
| `applicationSupport` | `~/Library/Application Support/` |
| `preferences` | `~/Library/Preferences/` |
| `containers` | `~/Library/Containers/` |
| `groupContainers` | `~/Library/Group Containers/` |
| `caches` | `~/Library/Caches/` |
| `webKit` | `~/Library/WebKit/` |
| `httpStorages` | `~/Library/HTTPStorages/` |
| `applicationScripts` | `~/Library/Application Scripts/` |
| `logs` | `~/Library/Logs/` |
| `savedState` | `~/Library/Saved Application State/` |
| `dotFolder` | `~/.npm`、`~/.vscode` など |
| `custom` | ユーザー定義パス |

## 復元フロー

1. ローカルパスが有効な外部ディレクトリを指すシンボリックリンクであることを確認
2. ローカルのシンボリックリンクを削除
3. 外部ディレクトリをローカルにコピー
4. 外部ディレクトリを削除（ベストエフォート）

コピーに失敗した場合、一貫性を維持するためにシンボリックリンクを自動的に再構築します。

## エラーハンドリングとロールバック

移行プロセスの各重要なステップには、ロールバックメカニズムが含まれています：

- **コピー失敗**: それ以上のアクションは実行されない；コピーされた外部ファイルをクリーンアップ
- **ローカルディレクトリ削除失敗**: 外部コピーを削除し、元の状態を復元
- **シンボリックリンク作成失敗**: 外部からデータをローカルにコピーし直し、外部コピーを削除

この設計により、どの段階で失敗が発生してもデータの損失がなく、システム状態の一貫性が保証されます。
