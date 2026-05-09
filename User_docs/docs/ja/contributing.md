---
outline: deep
---

# コントリビューション

AppPorts にご関心をお寄せいただきありがとうございます！バグの修正、ドキュメントの改善、新機能の追加など、コミュニティメンバーのコントリビューションを歓迎します。

## 始める前に

1. 既存の[Issues](https://github.com/wzh4869/AppPorts/issues)を検索し、関連する重複がないことを確認
2. プロジェクトをフォークし、ローカルにクローン
3. `develop` ブランチをベースに機能ブランチ（`feat/your-feature`）または修正ブランチ（`fix/your-fix`）を作成

## 開発アプローチ

### Vibe Coding について

AppPorts プロジェクトは、AI アシスタントツール（例：Cursor、GitHub Copilot、Claude）を使用した Vibe Coding 開発を受け入れています。AI ツールが開発効率を大幅に向上できることを理解していますが、**提出されるコードの品質と正確性はコントリビューターの責任です**。

Vibe Coding を使用する場合：

- **AI アシスタントはプロジェクトルートの `CLAUDE.md` に従う必要があります**。これにはコーディングガイドライン、アーキテクチャ規約、ビルドコマンド、開発ワークフローが定義されています。AI アシスタントがこのファイルを自動的に読み取らない場合は、プロンプトで `CLAUDE.md` を最初に読み取るよう明示的に依頼してください
- 複数の AI モデルで生成されたコードの品質とセキュリティをクロスバリデーションし、単一モデルの盲点を回避することを検討してください
- AI が生成したコードはプロジェクトの既存スタイルと一致しない場合があります；提出前に手動でレビューしてください
- AI は macOS システム動作の理解を置き換えることはできません；ファイルシステム操作、コード署名、権限管理に関するロジックは手動で検証してください
- **コア機能**の変更（例：移行戦略、データディレクトリ移行、コード署名）は、開発前に Issue で議論する必要があります

### コード規約

- Swift コード規約とプロジェクトの既存スタイルに従う
- 複雑なロジックには明確な Swift ドキュメントコメントを記述する
- SwiftUI 文字列リテラルは `LocalizedStringKey` API を使用；AppKit/API 文字列は `.localized` を使用

## テスト要件

::: warning ⚠️ すべての PR はテストに合格する必要があります
開発方法に関係なく、PR を提出する前に以下のテストを完了する必要があります。CI は自動的にコンパイルスモークチェックを実行し、不合格の PR はマージがブロックされます。
:::

### 必須：コンパイルスモークチェック

すべての PR は Xcode Release コンパイルに合格する必要があります — これはマージのハード要件です：

```bash
xcodebuild clean build \
  -scheme "AppPorts" \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  CODE_SIGNING_ALLOWED=NO
```

### オンデマンド：専門テスト

PR が対応するモジュールに関わる場合、以下の専門テストを積極的に実行することを推奨します。CI は PR でも Advisory モードでこれらのテストを実行し、結果はマージをブロックしませんがフィードバックを提供します。

#### データディレクトリテスト

PR が `DataDirMover`、`DataDirScanner`、またはデータディレクトリ移行ロジックに関わる場合に実行：

```bash
xcodebuild test \
  -scheme "AppPorts" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  -only-testing:"AppPortsTests/DataDirMoverTests" \
  -only-testing:"AppPortsTests/DataDirScannerTests" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  CODE_SIGNING_ALLOWED=NO
```

#### アプリ移行テスト

PR が `AppMigrationService`、`AppScanner`、またはアプリ移行ロジックに関わる場合に実行：

```bash
xcodebuild test \
  -scheme "AppPorts" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  -only-testing:"AppPortsTests/AppMigrationServiceTests" \
  -only-testing:"AppPortsTests/AppScannerTests" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  CODE_SIGNING_ALLOWED=NO
```

#### ログテスト

PR が `AppLogger` または診断機能に関わる場合に実行：

```bash
xcodebuild test \
  -scheme "AppPorts" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  -only-testing:"AppPortsTests/AppLoggerTests" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  CODE_SIGNING_ALLOWED=NO
```

#### ローカライズ監査

PR がユーザーに見えるテキスト、メニュー、ポップアップ、設定、またはエラーメッセージに関わる場合に実行：

```bash
xcodebuild test \
  -scheme "AppPorts" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  -only-testing:"AppPortsTests/LocalizationAuditTests" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  CODE_SIGNING_ALLOWED=NO
```

### テスト概要

| テストスイート | モジュール | 実行タイミング |
|--------------|---------|--------------|
| コンパイルスモークチェック | プロジェクト全体 | **必須**（CI 強制） |
| `DataDirMoverTests` | データディレクトリ移行 | `DataDirMover` に関わる場合 |
| `DataDirScannerTests` | データディレクトリスキャン | `DataDirScanner` に関わる場合 |
| `AppMigrationServiceTests` | アプリ移行 | `AppMigrationService` に関わる場合 |
| `AppScannerTests` | アプリスキャン | `AppScanner` に関わる場合 |
| `AppLoggerTests` | ログと診断 | `AppLogger` に関わる場合 |
| `LocalizationAuditTests` | ローカライズ | ユーザーに見えるテキストに関わる場合 |

## ローカライズ

- ローカライズの適応は推奨されますが、外部コントリビューターの PR では必須ではありません
- PR がユーザーに見えるテキストの追加、変更、または削除を行う場合、同じ PR で `Localizable.xcstrings` を更新することが歓迎されます
- 今回の PR では対応しない場合、PR の説明に理由または今後の計画を簡単に記述してください
- SwiftUI 文字列リテラルは `LocalizedStringKey` API を使用；AppKit/API 文字列は `.localized` を使用
- 動的テキストはフォーマットキーを使用する必要があります。例：`String(format: "Sort: %@".localized, value)`
- 言語リストは `AppLanguageCatalog` で管理；複数のページで重複しないでください
- PR がメニュー、ポップアップ、設定、ログエクスポート、エラーメッセージ、ステータステキスト、またはオンボーディングテキストを変更する場合、少なくとも `zh-Hans` と `en` の表示結果を確認することが推奨されます

詳細なルールは：[LOCALIZATION.md](https://github.com/wzh4869/AppPorts/blob/main/LOCALIZATION.md)

## コミット規約

- **Issue ファースト**: 重要な機能変更はまず Issue で議論する必要があります
- **アトミックを保つ**: 各 PR は理想的に1つの問題のみを対応または1つの機能のみを追加する
- **コミットメッセージの提案**:
  - `feat: ...` — 新機能
  - `fix: ...` — バグ修正
  - `docs: ...` — ドキュメント更新
  - `refactor: ...` — リファクタリング
  - `test: ...` — テスト関連

## PR の提出

1. ブランチが最新の `develop` ブランチに基づいていることを確認
2. Fork リポジトリにプッシュ
3. AppPorts の `develop` ブランチに Pull Request を提出
4. PR テンプレートの必須項目を記入
5. CI チェックの合格と Code Review を待つ

::: tip 💡 マージ効率の向上
- 各 PR を単一の問題または機能に集中させる
- PR テンプレートのテスト状況を正直に記入する
- UI の変更にはスクリーンショットを含める
:::

## コントリビューション歓迎分野

- `AppScanner` などのコアロジックの安定性とパフォーマンス改善
- UI/UX 最適化、特に macOS にネイティブに感じられる改善
- 中国語と英語ドキュメントの同期と改善
