---
outline: deep
---

# ツールディレクトリ検出

![](https://pic.cdn.shimoko.com/tools.png)

AppPorts は、ユーザーのホームディレクトリにある一般的な開発ツール、AI ツール、エディタが作成したデータディレクトリ（ドットフォルダ）を自動検出し、外部ストレージへの移行をサポートします。その他のツール移行の要望は、プロジェクトの[Issues](https://github.com/wzh4869/AppPorts/issues)までご提出ください。

## 優先度レベル

| 優先度 | 意味 |
|--------|------|
| `critical`（重要） | 移行後も動作が必須；コアアプリケーション機能に影響 |
| `recommended`（推奨） | 大きな容量削減効果；移行のメリットが高い |
| `optional`（任意） | サイズが小さいか再構築可能 |

## 開発ツール / パッケージマネージャー

| ツール | パス | 優先度 | 説明 |
|--------|------|--------|------|
| npm | `~/.npm` | 推奨 | Node.js パッケージマネージャーのローカルキャッシュ |
| Maven | `~/.m2` | 推奨 | Java Maven 依存リポジトリ |
| Bun | `~/.bun` | 推奨 | Bun JavaScript ランタイムとキャッシュ |
| Conda | `~/.conda` | 推奨 | Anaconda/Miniconda 環境データ |
| Composer | `~/.composer` | 任意 | PHP Composer グローバルパッケージ |
| Nexus | `~/.nexus` | 任意 | Nexus プロキシキャッシュ |

## AI / 機械学習ツール

| ツール | パス | 優先度 | 説明 |
|--------|------|--------|------|
| Ollama | `~/.ollama` | 推奨 | ローカル大規模言語モデルストレージ |
| PyTorch | `~/.cache/torch` | 推奨 | 事前学習済みモデル重みキャッシュ |
| Whisper | `~/.cache/whisper` | 推奨 | OpenAI 音声認識モデル |
| Keras | `~/.keras` | 任意 | Keras モデルとデータセット |
| NLTK | `~/nltk_data` | 任意 | 自然言語処理コーパス |

## AI コーディングアシスタント

| ツール | パス | 優先度 | 説明 |
|--------|------|--------|------|
| Lingma | `~/.lingma` | 任意 | 阿里巴巴クラウド AI コーディングアシスタント |
| Trae IDE | `~/.trae` | 任意 | ByteDance Trae IDE |
| Trae CN | `~/.trae-cn` | 任意 | Trae IDE 国内版 |
| Trae AICC | `~/.trae-aicc` | 任意 | Trae AICC |
| MarsCode | `~/.marscode` | 任意 | ByteDance MarsCode IDE |
| CodeBuddy | `~/.codebuddy` | 任意 | テンセント AI アシスタント |
| CodeBuddy CN | `~/.codebuddycn` | 任意 | テンセント CodeBuddy 国内版 |
| Qwen | `~/.qwen` | 任意 | 阿里巴巴通義千問 |
| ClawBOT | `~/.clawdbot` | 任意 | ClawdBOT AI ツール |

## エディタ / IDE

| ツール | パス | 優先度 | 説明 |
|--------|------|--------|------|
| VS Code | `~/.vscode` | 任意 | 拡張機能と設定 |
| Cursor | `~/.cursor` | 任意 | Cursor AI エディタ |
| Spring Tool Suite 4 | `~/.sts4` | 任意 | STS4 データ |

## ブラウザ / テスト自動化

| ツール | パス | 優先度 | 説明 |
|--------|------|--------|------|
| Selenium | `~/.cache/selenium` | 任意 | 自動ダウンロードされたブラウザドライバ |
| Chromium | `~/.chromium-browser-snapshots` | 任意 | Playwright/Selenium が使用するブラウザスナップショット |
| WDM | `~/.wdm` | 任意 | WebDriver Manager ドライバプログラム |

## ランタイム環境

| ツール | パス | 優先度 | 説明 |
|--------|------|--------|------|
| Docker | `~/.docker` | 任意 | Docker Desktop CLI 設定とコンテキスト |
| OpenClaw | `~/.openclaw` | 任意 | OpenClaw ツールデータ |

## 移行不可のシステムディレクトリ

以下のディレクトリには絶対パス参照または実行可能ファイルが含まれており、移行するとツールの故障を引き起こす可能性があります。**移行はサポートされていません**：

| パス | 理由 |
|------|------|
| `~/.local` | 実行可能パス参照が含まれており、移行後にコマンドラインツールが失敗する可能性がある |
| `~/.config` | 絶対パス設定が含まれており、移行後にツール設定が失敗する可能性がある |

## Conda ディストリビューションの特別処理

アプリの Bundle ID または名前に `anaconda`、`conda`、`miniconda` が含まれる場合、AppPorts は Conda インストールルートを特定するために以下のパスを追加スキャンします：

- `/opt/anaconda3`
- `/opt/miniconda3`
- `/usr/local/anaconda3`
- `/usr/local/miniconda3`
- `~/anaconda3`
- `~/miniconda3`
