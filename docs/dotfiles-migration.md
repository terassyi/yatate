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
- delegation パターンの resolveVersion / check Vars
- アーカイブ内の "./" エントリで展開失敗 (aqua 経由の一部パッケージ)

### Phase 8: nix 縮小 (home-manager → chezmoi + tomei グレースフル移行)

現在 darwin2 は home-manager (generation 10) がアクティブで、`~/.config/` 以下の主要設定ファイルは
全て nix store へのシンボリックリンク。`fish`, `nvim` 等のバイナリも `~/.nix-profile/bin/` 経由。

chezmoi apply を先に実行すると HM のシンボリックリンクと衝突する。
HM を先に削除するとバイナリも設定も消えて環境が壊れる。
以下の手順で段階的に切り替える。

#### Step 1: tomei apply でバイナリを並行インストール

- [x] `tomei apply ~/.config/tomei/` で全バイナリを `~/.local/bin/` や `~/.cargo/bin/` にインストール
- HM と並行して動作する。PATH の優先順位で `~/.local/bin` > `~/.nix-profile/bin` なら tomei 版が使われる
- docker, gcloud は tomei バグで失敗 → 手動インストール or tomei 修正後に再実行

#### Step 2: home-manager の設定ファイル管理を無効化

- [ ] terakoya `nix/src/home/common/default.nix` で `programs.*` と `xdg.configFile` を無効化
- [ ] `home-manager switch` で HM のシンボリックリンクが解除される（backup があればリストア）

#### Step 3: chezmoi init + apply

- [ ] `chezmoi init --source=/path/to/yatate --apply` で設定ファイルをデプロイ
- `~/.config/` 以下が chezmoi 管理の実ファイルになる

#### Step 4: home-manager のパッケージ管理を停止

- [ ] terakoya `nix/src/home/` で `home.packages = [];` にして `home-manager switch`
- `~/.nix-profile` からバイナリが削除され、tomei 版に完全切り替え

#### Step 5: home-manager を完全削除

- [ ] `nix profile remove home-manager-path && nix profile remove home-manager`
- [ ] `rm -rf ~/.local/state/home-manager/`
- [ ] `nix store gc`

#### Step 6: terakoya nix/src/ クリーンアップ

- [ ] `nix/src/home/` 全削除
- [ ] `nix/src/flake.nix` から不要 input 削除 (`home-manager`, `fenix`, `nix-vscode-extensions`, `darwin`)
- [ ] `mkDarwinConfiguration`, `mkHomeConfiguration` 関数・`homeConfigurations` output 削除
- [ ] `nix flake update` で flake.lock 更新

#### Step 7: NixOS hosts から GUI アプリ削除 (optional)

- [ ] `nix/src/hosts/nixos/common/desktop/` から Chrome, Slack, Discord, Zoom, Wireshark を削除

#### 注意事項

- **fish ログインシェル**: `/etc/shells` に nix store パスが登録されている可能性。tomei の fish パスに `chsh` し直す
- **nvim プラグイン**: HM 版は nixpkgs.vimPlugins、yatate 版は lazy.nvim。切り替え時に `~/.local/share/nvim/` をクリーンアップ
- **nix-darwin**: darwin-rebuild の設定も確認

#### 各 Step の検証

```sh
which fish && fish --version          # fish が使えるか
which nvim && nvim --version          # nvim が使えるか
readlink ~/.config/fish/config.fish   # nix store リンクでなく実ファイルか
tomei plan ~/.config/tomei/           # tomei の状態確認
```

### Phase 9: CI ✅

- [x] `.github/workflows/yatate.yml` 作成 (validate + test matrix)
- [x] `Dockerfile` 作成（コンテナテスト用）
- [x] `scripts/test.sh` + `scripts/test-tools.sh` (bash 3 互換)

### Phase 10: 検証

- [ ] ローカルで `chezmoi diff` 確認
- [ ] `tomei validate` + `tomei plan` 確認
- [x] CI パス確認 (container + native)
