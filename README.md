# yatate

[chezmoi](https://www.chezmoi.io/) + [tomei](https://github.com/terassyi/tomei) による yatate 管理。

## サポート環境

| OS | Arch |
|---|---|
| Linux | amd64, arm64 |
| macOS (Darwin) | arm64 |

## ディレクトリ構成

```
yatate/
├── .chezmoi.toml.tmpl          # chezmoi 設定テンプレート（プロファイル・age 暗号化含む）
├── .chezmoiignore              # chezmoi 除外パターン（プロファイル別暗号化ファイル制御）
├── .chezmoiscripts/            # chezmoi 実行スクリプト
│   ├── run_once_before_*.sh.tmpl   # 初回セットアップ（ディレクトリ作成、tomei インストール等）
│   ├── run_before_20-fetch-age-key.sh.tmpl  # age 秘密鍵の GCM 取得
│   ├── run_onchange_before_*.sh.tmpl        # パッケージインストール
│   └── run_onchange_after_*.sh.tmpl         # tomei apply 等
├── age-recipients.txt          # 全プロファイルの age 公開鍵（encrypt.sh が参照）
├── Dockerfile                  # テスト用 Ubuntu コンテナ
├── Makefile                    # ローカル開発・テスト用コマンド
├── .gitignore                  # 鍵ファイルの誤コミット防止
├── dot_config/
│   ├── fish/                   # fish shell 設定
│   ├── git/
│   │   └── encrypted_config.tmpl  # git 設定（暗号化テンプレート、メール等 PII 含む）
│   ├── nvim/                   # Neovim 設定
│   ├── tomei/                  # tomei CUE マニフェスト（ツール定義）
│   └── ...                     # ghostty, zellij, zed, starship 等
├── dot_ssh/
│   ├── encrypted_config.tmpl   # SSH config（暗号化テンプレート、ホスト設定含む）
│   └── encrypted_test_key.age  # テスト用暗号化ファイル
├── testdata/
│   └── age-test-key.pub        # テスト用 age 公開鍵（秘密鍵は GitHub Secrets で管理）
├── plaintext/                  # 暗号化前テンプレート（gitignore 済み、リポジトリに含まれない）
└── scripts/
    ├── encrypt.sh              # 平文テンプレート → age 暗号化変換
    ├── setup-test-key.sh       # テスト用 age 鍵セットアップ（CI・Makefile 共通）
    ├── test.sh                 # 統合テスト（暗号化テスト含む）
    └── test-tools.sh           # ツールインストール検証
```

## 暗号化（age）

SSH 鍵などの機密ファイルは [age](https://github.com/FiloSottile/age) で暗号化してリポジトリに保存する。
chezmoi のビルトイン age サポートを使用するため、外部 `age` バイナリは復号に不要。

暗号化ファイルには 2 種類ある:

- **プロファイル専用**: 1 つの recipient で暗号化。そのプロファイルの鍵でのみ復号可能（SSH 秘密鍵など）
- **共有**: 全 3 recipient で暗号化。全プロファイルで復号可能（git config、SSH config など PII を含む設定）

### プロファイル

ホスト名に基づいて 3 つのプロファイルに分かれ、それぞれ独立した age 鍵ペアを持つ。
プロファイル専用の暗号化ファイルは、他のプロファイルのホストでは復号できない。
`.chezmoiignore` のテンプレート条件により、他プロファイルのファイルは source state から除外される。

| プロファイル | ホスト | age 鍵ファイル | GCM シークレット名 |
|------------|--------|--------------|-------------------|
| personal | teracarbon, teradev, devvm | `~/.config/chezmoi/key-personal.txt` | `chezmoi-age-key` |
| work | fukdesk, darwin2 | `~/.config/chezmoi/key-work.txt` | `chezmoi-age-key` |
| test | dev (CI/testuser) | `~/.config/chezmoi/key-test.txt` | なし（GitHub Actions シークレット `AGE_TEST_SECRET_KEY` で管理） |

### 暗号化ファイルの追加

プロファイル専用ファイル（SSH 鍵など）は `chezmoi add --encrypt` で追加する。
現在のプロファイルの recipient が自動選択される。

```sh
chezmoi add --encrypt ~/.ssh/id_ed25519
```

共有ファイル（git config など全プロファイルで必要なもの）は `scripts/encrypt.sh` で全 recipient を指定して暗号化する。

```sh
scripts/encrypt.sh plaintext/git-config.tmpl dot_config/git/encrypted_config.tmpl
```

### 暗号化ファイルの編集

暗号化テンプレートの平文は `plaintext/` ディレクトリ（gitignore 済み）で管理する。

```sh
# 既存の暗号化ファイルを復号して編集
chezmoi decrypt dot_config/git/encrypted_config.tmpl > plaintext/git-config.tmpl
vim plaintext/git-config.tmpl

# 再暗号化してコミット
scripts/encrypt.sh plaintext/git-config.tmpl dot_config/git/encrypted_config.tmpl
```

### テスト鍵のローテーション

1. `age-keygen -o new-key.txt` で新しい鍵ペアを生成
2. `.chezmoi.toml.tmpl` の test recipient（`[age]` セクション）を新しい公開鍵に更新
3. `testdata/age-test-key.pub` を新しい公開鍵に更新
4. 全暗号化ファイルを `plaintext/` に復号 → `scripts/encrypt.sh` で再暗号化
5. GitHub Actions シークレット `AGE_TEST_SECRET_KEY` を新しい秘密鍵に更新
6. 鍵ファイルを安全に削除

## セットアップ（Bootstrap）

新規マシンでは 2 段階でセットアップする。
Phase 1 で age 鍵なしでも安全に動作する平文 dotfiles とツール群を配置し、
Phase 2 で age 秘密鍵を取得して暗号化ファイル（SSH 鍵など）を復号・展開する。

### Phase 1: ツールインストール＋平文 dotfiles 配置

```sh
chezmoi init --apply --source=./yatate --exclude=encrypted
# または
make install
```

この段階で tomei, gcloud 等のツールがインストールされる。
暗号化ファイルはスキップされるため age 鍵は不要。
git config や SSH config など暗号化テンプレートは Phase 2 で展開される。

### Phase 2: age 鍵取得＋暗号化ファイル展開

```sh
# GCP プロジェクト ID を環境変数に設定（シェルプロファイルに追加推奨）
export CHEZMOI_GCP_PROJECT="your-gcp-project-id"

# Google Cloud 認証
gcloud auth login

# 全ファイル適用（age 鍵を自動取得し、暗号化ファイルを復号）
chezmoi apply
# または
make install-full
```

`run_before_20-fetch-age-key` スクリプトが環境変数 `CHEZMOI_GCP_PROJECT` で指定された
Google Secret Manager プロジェクトからプロファイルに対応する age 秘密鍵を
`~/.config/chezmoi/key-<profile>.txt` に配置し、暗号化ファイルが復号・展開される。

gcloud が未インストール、未認証、または `CHEZMOI_GCP_PROJECT` が未設定の場合、
スクリプトは graceful skip し Phase 1 相当で完了する。

## テスト

Docker コンテナ内で chezmoi と tomei の動作を検証する。

```sh
make build          # テスト用イメージをビルド
make test           # 暗号化なしモード（鍵不要、ローカル開発向け）
make test-encrypt   # 暗号化 E2E テスト（ローカルに鍵ファイルが必要）
make shell          # デバッグ用にコンテナへ入る（bash）
make run            # fish シェルでコンテナ起動
make clean          # イメージ削除
```

`make test` は暗号化ファイルをスキップし、平文 dotfiles のテストのみ実行する。
`make test-encrypt` は `testdata/age-test-key.txt`（gitignore 済み）をコンテナ内に配置し、
暗号化ファイルの復号まで検証する。CI は GitHub Actions シークレット経由で同等のテストを実行する。

## CI

`.github/workflows/yatate.yml` で `yatate/` 配下の変更時に自動テストが走る。

- **validate**: chezmoi テンプレート検証、tomei マニフェスト検証、fish 構文チェック
- **test**: container モード + native モードのマトリックス（linux/amd64, linux/arm64, macOS/arm64）。GitHub Actions シークレット `AGE_TEST_SECRET_KEY` 経由で暗号化ファイルの復号 E2E テストを含む

## tomei マニフェスト

`dot_config/tomei/` 配下の `.cue` ファイルにツール定義を追加する。
CUE モジュールの初期化は `tomei cue init` で行う（手動で `cue.mod/` を作成しない）。

ツールのインストールパターンは 3 種類。`installerRef`, `runtimeRef`, `commands` のいずれか 1 つを指定する。

### aqua レジストリ経由（個別）

```cue
fd: {
    apiVersion: "tomei.terassyi.net/v1beta1"
    kind:       "Tool"
    metadata: name: "fd"
    spec: {
        installerRef: "aqua"
        version:      "v10.3.0"
        package:      "sharkdp/fd"
    }
}
```

### プリセット + ToolSet（複数ツールをまとめて定義）

```cue
import "tomei.terassyi.net/presets/aqua"

cliTools: aqua.#AquaToolSet & {
    metadata: name: "cli-tools"
    spec: tools: {
        rg:  {package: "BurntSushi/ripgrep", version: "15.1.0"}
        fd:  {package: "sharkdp/fd", version: "v10.3.0"}
        jq:  {package: "jqlang/jq", version: "1.8.1"}
        bat: {package: "sharkdp/bat", version: "v0.26.1"}
    }
}
```

### Runtime 経由（Go, Rust など）

```cue
import gopreset "tomei.terassyi.net/presets/go"

goRuntime: gopreset.#GoRuntime & {
    platform: {os: _os, arch: _arch}
    spec: version: "1.26.0"
}

gopls: {
    apiVersion: "tomei.terassyi.net/v1beta1"
    kind:       "Tool"
    metadata: name: "gopls"
    spec: {
        runtimeRef: "go"
        package:    "golang.org/x/tools/gopls"
        version:    "v0.21.0"
    }
}
```

### カスタムコマンド

```cue
myTool: {
    apiVersion: "tomei.terassyi.net/v1beta1"
    kind:       "Tool"
    metadata: name: "my-tool"
    spec: commands: {
        install: ["curl -fsSL https://example.com/install.sh | sh"]
        check:   ["my-tool --version"]
        remove:  ["rm -f ~/.local/bin/my-tool"]
    }
}
```
