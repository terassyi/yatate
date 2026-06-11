# dotfiles 刷新: nix/home-manager → tomei + chezmoi 移行計画

## Context

terakoya リポジトリの開発環境管理を nix/home-manager 一本から、以下の構成に移行する:

- **tomei**: ユーザーレベルの CLI ツール・ランタイムのインストール（CUE マニフェスト）
- **chezmoi**: dotfiles（設定ファイル）のデプロイとテンプレート化
- **nix**: NixOS システム設定のみ（最小スコープ）。GUI アプリは手動管理

リポジトリ名: `yatate` (旧 dotfiles)。chezmoi ソースはリポジトリルートに配置。

---

## 1. 責務の分離

### 1.1 tomei が管理するもの（ツールバイナリ）

| カテゴリ | ツール | インストールパターン |
|---|---|---|
| 共通 CLI ツール | rg, fd, jq, bat, delta, zellij, just, yq, gh, zoxide, gitui, sk, starship, hugo | aqua ToolSet (common-tools.cue) |
| Protobuf/gRPC ツール | protoc, protoc-gen-go, protoc-gen-go-grpc, grpcurl | aqua ToolSet (lang-tools.cue) |
| Rust ツール | stylua, eza, btm (bottom), tokei | BinstallToolSet (lang-tools.cue) |
| Go | Go 1.26.0 runtime + gopls | GoRuntime + GoToolSet (lang-tools.cue) |
| Rust | rustup + stable toolchain + cargo-binstall | RustRuntime (runtimes.cue) |
| Node.js | pnpm 10.29.3 | PnpmRuntime (runtimes.cue) |
| Python | uv 0.10.6 | UvRuntime (runtimes.cue) |
| Lua | Lua 5.5.0 | delegation Runtime (runtimes.cue) |
| Darwin2 専用 | ffmpeg | aqua (darwin2-extras.cue.tmpl) |

### 1.2 chezmoi が管理するもの（設定ファイル）

| カテゴリ | ファイル |
|---|---|
| Fish shell | config.fish, functions/\*, conf.d/ (starship, zoxide init) |
| Git | ~/.config/git/config (テンプレート: name, email) |
| Starship | ~/.config/starship.toml |
| Zellij | ~/.config/zellij/config.kdl |
| Neovim | ~/.config/nvim/init.lua, lua/\*.lua (lazy.nvim ベース) |
| VSCode | settings.json, keybindings.json |
| Zed | settings.json (modify_ スクリプト), keymap.json |
| Ghostty | ~/.config/ghostty/config (Linux GUI のみ) |
| GNOME | ~/.config/dconf/gnome.ini (dconf 設定テンプレート) |
| 壁紙 | ~/.local/share/backgrounds/\*.jpg |

### 1.3 nix に残すもの（最小スコープ）

NixOS のシステム設定のみ。home-manager は廃止。

| カテゴリ | 理由 |
|---|---|
| NixOS システム設定 | ブートローダー、ネットワーク、ユーザー、サービス、ロケール |
| NixOS デスクトップ基盤 | GNOME セッション、Pipewire、seatd、IME (ibus) |
| NixOS システムパッケージ | linuxHeaders, libbpf (overlay), youki |
| Fish ログインシェル登録 | `programs.fish.enable = true` (NixOS レベル) |

### 1.4 手動管理に移行するもの

- GUI アプリ全般: VSCode, Google Chrome, Slack, Discord, Zoom, Wireshark
- VSCode 拡張機能 → VSCode Marketplace / Settings Sync
- フォント → OS のフォント管理 or chezmoi スクリプト
- GNOME 拡張機能 → GNOME Extensions サイト
- Ghostty → 公式インストーラー or tomei

---

## 2. ディレクトリ構成

```
yatate/                              # chezmoi ソースルート
├── .chezmoi.toml.tmpl               # chezmoi 設定 + [data] (ホスト別データ)
├── .chezmoiignore                   # OS/GUI 条件で不要ファイルを除外
├── Dockerfile                       # テスト用 Ubuntu コンテナ
├── Makefile                         # build, test, shell, run, clean
│
├── .chezmoiscripts/
│   ├── run_once_before_00-bootstrap-dirs.sh.tmpl
│   ├── run_onchange_before_01-install-packages.sh.tmpl
│   ├── run_once_before_02-install-tomei.sh.tmpl
│   ├── run_onchange_after_01-apply-tomei.sh.tmpl
│   ├── run_onchange_after_02-download-skim-keybindings.sh.tmpl
│   ├── run_onchange_after_03-vscode-settings-darwin.sh.tmpl
│   ├── run_once_after_90-set-fish-default-shell.sh.tmpl
│   └── run_once_after_91-gnome-dconf.sh.tmpl
│
├── scripts/
│   ├── test.sh                      # chezmoi apply + 設定ファイル検証
│   └── test-tools.sh                # tomei ツール・ランタイム検証
│
├── dot_config/
│   ├── fish/                        # config.fish.tmpl, conf.d/, functions/
│   ├── git/config.tmpl
│   ├── gh/config.yml
│   ├── starship.toml
│   ├── zellij/config.kdl
│   ├── nvim/                        # init.lua + lua/ (lazy.nvim ベース)
│   ├── Code/User/                   # settings.json, keybindings.json
│   ├── zed/                         # modify_settings.json.tmpl, keymap.json
│   ├── ghostty/config
│   ├── dconf/gnome.ini.tmpl
│   ├── packages/                    # OS パッケージリスト
│   └── tomei/                       # tomei CUE マニフェスト
│       ├── cue.mod/module.cue
│       ├── tomei_platform.cue       # @tag(os), @tag(arch), @tag(headless)
│       ├── runtimes.cue             # Go, Rust, pnpm, uv, Lua
│       ├── common-tools.cue         # aqua ToolSet (全プラットフォーム共通)
│       ├── lang-tools.cue           # gopls, cargo-binstall + Rust ツール
│       ├── (darwin-tools.cue 削除済み)
│       └── darwin2-extras.cue.tmpl  # ffmpeg (chezmoi テンプレート)
│
├── .github/workflows/yatate.yml    # CI: validate + test (container/native)
└── docs/
    └── dotfiles-migration.md        # 本ドキュメント
```

### nix/src/ (大幅縮小予定)

- `home/` → **全削除**（home-manager 廃止）
- `hosts/nixos/` → 維持（NixOS システム設定）
  - GUI アプリは `environment.systemPackages` から削除
- `overlays/libbpf.nix` → 維持（NixOS hosts が依存）
- `flake.nix` → home-manager, fenix, nix-vscode-extensions, darwin の input を削除

---

## 3. chezmoi テンプレート戦略

### 3.1 .chezmoi.toml.tmpl

ホスト名から GUI タイプ、git identity を自動判定。`.chezmoidata.toml.tmpl` は chezmoi の仕様上テンプレート不可のため、`.chezmoi.toml.tmpl` の `[data]` セクションに統合。

CI/テスト環境 (`runner`, `testuser`) は `hostname = "dev"` にオーバーライド。

### 3.2 .chezmoiignore

OS・GUI 条件で不要ファイルを除外:
- darwin: dconf, ghostty, packages
- headless: Code, ghostty, dconf
- hostname テンプレート: darwin2-extras.cue.tmpl

---

## 4. スクリプト実行順序

| 順序 | スクリプト | 内容 |
|---|---|---|
| before 00 | bootstrap-dirs | ~/workspace ディレクトリ作成 |
| before 01 | install-packages | 最低限の OS パッケージ (curl, git, fish) |
| before 02 | install-tomei | tomei バイナリを ~/.local/bin にダウンロード |
| (ファイル適用) | chezmoi がドットファイルを配置 | |
| after 01 | apply-tomei | tomei init + apply (マニフェスト hash 変更時のみ再実行) |
| after 02 | download-skim-keybindings | skim キーバインド設定ダウンロード |
| after 03 | vscode-settings-darwin | macOS の VSCode 設定コピー |
| after 90 | set-fish-default-shell | chsh -s fish |
| after 91 | gnome-dconf | dconf load (GNOME のみ) |

---

## 5. CI テスト戦略

### GitHub Actions ワークフロー (`yatate.yml`)

2 つのテストマトリクス:
- **container** (`ubuntu-latest`): Docker コンテナ内で full apply テスト
- **native** (`macos-latest`, `arm64`): macOS ネイティブで chezmoi + tomei テスト

テストスクリプト:
- `scripts/test.sh`: chezmoi init/apply → 設定ファイル検証 (fish, git, nvim, zellij, ghostty, dconf, zed)
- `scripts/test-tools.sh`: tomei plan から全ツール・ランタイムの存在・バージョン確認 (bash 3 互換)

---

## 6. Neovim プラグイン管理

home-manager 廃止に伴い、neovim プラグインを nixpkgs.vimPlugins から **lazy.nvim** に移行済み。

- Neovim バイナリ: chezmoi スクリプトでインストール (brew/apt)
- プラグイン: lazy.nvim がランタイムで管理（init.lua + plugins.lua で宣言）
- treesitter パーサー: nvim-treesitter が自動ビルド
- LSP サーバー: tomei がインストール (gopls)

---

## 7. 実装タスク

### Phase 1: chezmoi 基盤 ✅

- [x] `.chezmoi.toml.tmpl` 作成
- [x] `.chezmoiignore` 作成
- [x] `Makefile` 作成

### Phase 2: chezmoi スクリプト ✅

- [x] `run_once_before_00-bootstrap-dirs.sh.tmpl`
- [x] `run_onchange_before_01-install-packages.sh.tmpl`
- [x] `run_once_before_02-install-tomei.sh.tmpl`
- [x] `run_onchange_after_01-apply-tomei.sh.tmpl`
- [x] `run_onchange_after_02-download-skim-keybindings.sh.tmpl`
- [x] `run_onchange_after_03-vscode-settings-darwin.sh.tmpl`
- [x] `run_once_after_90-set-fish-default-shell.sh.tmpl`
- [x] `run_once_after_91-gnome-dconf.sh.tmpl`

### Phase 3: Shell 設定 (Fish) ✅

- [x] `dot_config/fish/config.fish.tmpl`
- [x] `dot_config/fish/conf.d/starship.fish`
- [x] `dot_config/fish/conf.d/zoxide.fish`
- [x] `dot_config/fish/functions/` (clone, gh_release, sk_bat, sk_code_repo, sk_history, sk_zoxide, sk_zoxide_gh)

### Phase 4: Git・ツール設定 ✅

- [x] `dot_config/git/config.tmpl`
- [x] `dot_config/gh/config.yml`
- [x] `dot_config/starship.toml`
- [x] `dot_config/zellij/config.kdl`

### Phase 5: エディタ設定 ✅

- [x] Neovim: lazy.nvim ベースの `init.lua` + `lua/*.lua`
- [x] VSCode: `settings.json`, `keybindings.json`
- [x] Zed: `modify_settings.json.tmpl` + `keymap.json`

### Phase 6: デスクトップ設定 (Linux) ✅

- [x] `dot_config/ghostty/config`
- [x] `dot_config/dconf/gnome.ini.tmpl`
- [x] 壁紙ファイル (`dot_local/share/backgrounds/`)

### Phase 7: tomei CUE マニフェスト ✅

- [x] `dot_config/tomei/cue.mod/module.cue`
- [x] `dot_config/tomei/tomei_platform.cue`
- [x] `dot_config/tomei/runtimes.cue` — Go 1.26.0, Rust stable, pnpm 10.29.3, uv 0.10.6, Lua 5.5.0
- [x] `dot_config/tomei/common-tools.cue` — rg, fd, jq, bat, delta, zellij, just, yq, gh, zoxide, gitui, sk, starship, hugo
- [x] `dot_config/tomei/lang-tools.cue` — gopls, protoc-gen-go, protoc-gen-go-grpc, cargo-binstall, stylua, eza, btm, tokei, protoc, grpcurl
- [x] ~~`dot_config/tomei/darwin-tools.cue`~~ — 削除 (docker, gcloud は手動管理)
- [x] `dot_config/tomei/darwin2-extras.cue.tmpl` — ffmpeg

**既知の tomei バグ** (→ `../tomei/docs/known-issues.md`):
- ~~tgz アーカイブ形式が未サポート (docker, skim)~~ → tomei v0.1.2 で修正済み
- ~~hash のみ checksum ファイル形式が未サポート (starship)~~ → tomei v0.1.2 で修正済み
- ~~アーカイブ内の相対シンボリンク展開失敗 (gcloud)~~ → tomei v0.1.2 で修正済み
- ~~delegation パターンで createSymlinks が呼ばれない (lua)~~ → tomei v0.1.2 で修正済み
- ~~delegation パターンの resolveVersion / check Vars~~ → tomei v0.1.8 で修正済み
- ~~アーカイブ内の "./" エントリで展開失敗 (aqua 経由の一部パッケージ)~~ → tomei v0.1.8 で修正済み

### Phase 8: darwin2 の home-manager 撤去（chezmoi + tomei への完全移行）

darwin2（仕事用 Mac、`DOTFILES_HOSTNAME=darwin2`）は HM generation 11 (2026-03-12) が現役。
chezmoi は部分適用済み（`~/.config/{nvim,fish,zellij,ghostty,zed}` は実ファイル）、ただし
`~/.config/git/config` は HM → `/nix/store/...` のシンボリックリンク。Homebrew は未インストール。

以下のランブックで段階的に切り替える。各ステップ末尾に **Verify** と **Rollback** を記載。
`tomei apply`, `chezmoi apply`, `home-manager switch` はユーザーが手動で実行する。

#### 決定事項

- **Python**: uv のみで管理。必要時に `uv python install 3.13`。brew へは追加しない
- **rust-analyzer**: yatate `lang-tools.cue` の `rustTools` (cargo-binstall) で管理
- **Docker**: Docker Desktop を手動インストール。tomei 管理しない

#### Step A: Preflight（状態変更なし）

- [ ] darwin2 で次を実行して想定外の差分がないことを確認:

```sh
tomei plan --system ~/.config/tomei/
chezmoi diff
home-manager generations | head -5
which fish nvim gcloud ffmpeg ttyd python3 docker
readlink ~/.config/git/config
```

#### Step B: yatate CUE にギャップ追加（yatate リポジトリ）

- [x] `dot_config/tomei/lang-tools.cue` の `rustTools` に `rust-analyzer: {package: "rust-analyzer"}` を追加
- [ ] `tomei validate ~/.config/tomei/` で検証
- [ ] コミット

#### Step C: Homebrew + brew 管理バイナリ導入（darwin2）

- [ ] `tomei apply --system ~/.config/tomei/` を実行（初回は Homebrew 本体を入れる、sudo プロンプト発生）

**Verify**:
```sh
which brew
/opt/homebrew/bin/fish --version
/opt/homebrew/bin/nvim --version
gcloud --version
ttyd --version
which rust-analyzer   # ~/.cargo/bin/rust-analyzer
```

**Rollback**: `brew uninstall <pkg>`。HM 版が `~/.nix-profile/bin/` に残るため復旧可能。

#### Step D: login shell を brew fish に切り替え（darwin2）

```sh
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish
```

**Verify**（新ターミナルで）: `echo $SHELL` = `/opt/homebrew/bin/fish`、`command -v fish` = `/opt/homebrew/bin/fish`

**Rollback**: `chsh -s ~/.nix-profile/bin/fish` または `chsh -s /bin/zsh`

#### Step E: git config を chezmoi 管理に移譲（darwin2）

```sh
rm ~/.config/git/config
chezmoi apply ~/.config/git/config
```

**Verify**: `readlink ~/.config/git/config` が空（実ファイル）、`git config --global user.email` が期待値、`git commit -S` が通る

**Rollback**: `home-manager switch` で HM シンボリックリンクが復元

#### Step F: terakoya HM の `programs.*` / `xdg.configFile` を無効化（terakoya リポジトリ）

- [ ] `nix/src/home/common/{shell,editor,tools}/**` を編集し、fish / neovim / git / starship / zellij / zoxide / tmux / vscode の `programs.*` と `xdg.configFile.*` を削除（import 外しでも可）
- [ ] `home.packages` はまだ残す（バイナリ喪失を避ける）
- [ ] darwin2 で `home-manager switch --flake ~/workspace/github.com/terassyi/terakoya/nix/src#terashima@darwin2`

**Verify**: `~/.config/` 配下に HM の `/nix/store` リンクが再発生しない。chezmoi 実ファイルが残っている

**Rollback**: `home-manager rollback`

#### Step G: HM `home.packages` を空にする（terakoya リポジトリ）

- [ ] `nix/src/home/common/{tools,lang}/**` と `nix/src/home/darwin/darwin2/**` の `home.packages` を `[]` に（モジュール丸ごと削除も可）
- [ ] `home-manager switch --flake ~/workspace/github.com/terassyi/terakoya/nix/src#terashima@darwin2`

**Verify**:
```sh
which fish nvim gcloud ttyd        # /opt/homebrew/bin/...
which ffmpeg rg fd jq bat starship # ~/.local/share/aquaproj-aqua/... など
which cargo rustc rust-analyzer    # ~/.cargo/bin
which go gopls                     # tomei go runtime
which docker                       # 未 or /usr/local/bin/docker（Step H 後）
which python3                      # 未（必要なら `uv python install 3.13`）
nvim +checkhealth                  # 動作確認
fish -c "functions"                # 関数 autoload
```

**Rollback**: `home-manager rollback`

#### Step H: Docker Desktop 手動インストール（必要な場合）

- [ ] Docker Desktop.app を導入し `docker ps` を確認

#### Step I: Neovim 状態ディレクトリクリーンアップ

HM 版プラグインが `/nix/store/...` 参照を持つため。

```sh
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
nvim +Lazy +qall
```

**Verify**: `:checkhealth` エラー無し、LSP (`gopls`, `rust-analyzer`) が動作

#### Step J: home-manager 本体を削除

```sh
nix profile remove home-manager-path
nix profile remove home-manager
rm -rf ~/.local/state/home-manager/
nix store gc
```

**Verify**: `command -v home-manager` が空、シェル・エディタが通常稼働

**Rollback**: `nix profile install nixpkgs#home-manager` + 旧 flake を再適用

#### Step K: terakoya flake クリーンアップ（terakoya リポジトリ）

- [ ] `nix/src/home/` ツリー全削除
- [ ] `nix/src/flake.nix` から `terashima@darwin2` ほか `homeConfigurations` エントリ削除
- [ ] flake inputs から `home-manager`, `fenix`, `nix-vscode-extensions`, `darwin` を削除
- [ ] `mkDarwinConfiguration`, `mkHomeConfiguration` 関数 / `homeConfigurations` output を削除
- [ ] `nix flake update && nix flake check`
- [ ] commit

#### Step L: yatate ドキュメント更新

- [ ] 本 Phase 8 の完了項目を `[x]` でマークしてコミット

#### リスク

- **login shell 順序**: Step D（chsh）を Step G（HM 削除）より先に。順序を逆にすると fish バイナリ喪失と同時にターミナルが起動できなくなる
- **nvim プラグイン**: Step I を忘れると `/nix/store` を指す古い参照で lazy.nvim が失敗
- **gcloud components**: brew 版はユーザー側で `gcloud components install kubectl` 等の再インストールが必要になるケースあり
- **Docker daemon**: HM の `docker` は CLI のみ。daemon は Docker Desktop が同梱するため Step H 以降を使う
- **SSH 署名**: Step E で git config 置換直後、`git commit -S` が通ることを確認

#### 検証マトリクス（移行完了後）

```
which fish            → /opt/homebrew/bin/fish
which nvim            → /opt/homebrew/bin/nvim
which gcloud ttyd     → /opt/homebrew/bin/...
which ffmpeg rg fd jq bat starship → ~/.local/... (tomei aqua)
which cargo rustc rust-analyzer    → ~/.cargo/bin
which go gopls        → ~/.local/... (tomei)
which docker          → /usr/local/bin/docker (Docker Desktop) or 未
readlink ~/.config/git/config       → (空: 実ファイル)
readlink ~/.config/fish/config.fish → (空: 実ファイル)
home-manager --version → command not found
echo $SHELL           → /opt/homebrew/bin/fish
```

### Phase 9: CI ✅

- [x] `.github/workflows/yatate.yml` 作成 (validate + test matrix)
- [x] `Dockerfile` 作成（コンテナテスト用）
- [x] `scripts/test.sh` + `scripts/test-tools.sh` (bash 3 互換)

### Phase 10: 検証

- [ ] ローカルで `chezmoi diff` 確認
- [ ] `tomei validate` + `tomei plan` 確認
- [x] CI パス確認 (container + native)
