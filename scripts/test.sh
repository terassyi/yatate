#!/bin/bash
set -euo pipefail

YATATE_SOURCE="${1:-/home/testuser/yatate}"

echo "==> chezmoi init"
chezmoi init --source="$YATATE_SOURCE" --no-tty

KEY_FILE="${HOME}/.config/chezmoi/key-test.txt"
if [ -f "$KEY_FILE" ]; then
    echo "==> chezmoi apply (with encryption)"
    chezmoi apply --source="$YATATE_SOURCE" --no-tty
else
    echo "==> chezmoi apply (exclude encrypted)"
    chezmoi apply --source="$YATATE_SOURCE" --no-tty --exclude=encrypted
fi

echo "==> Checking deployed files"
files=(
    ~/.config/fish/config.fish
    ~/.config/fish/conf.d/starship.fish
    ~/.config/fish/conf.d/zoxide.fish
    ~/.config/fish/functions/clone.fish
    ~/.config/fish/functions/sk_history.fish
    ~/.config/zellij/config.kdl
    ~/.config/ghostty/config
    ~/.config/nvim/init.lua
    ~/.config/nvim/lua/options.lua
    ~/.config/nvim/lua/keymaps.lua
    ~/.config/nvim/lua/plugins.lua
    ~/.config/nvim/lua/lsp.lua
    ~/.config/Code/User/settings.json
    ~/.config/Code/User/keybindings.json
    ~/.config/zed/settings.json
    ~/.config/zed/keymap.json
    ~/.config/dconf/gnome.ini
)
for f in "${files[@]}"; do
    test -f "$f" || { echo "FAIL: $f not found"; exit 1; }
done

echo "==> Fish syntax check"
fish -n ~/.config/fish/config.fish

echo "==> Fish function autoload check"
functions=(clone sk_history sk_bat sk_zoxide sk_zoxide_gh sk_code_repo gh_release)
for fn in "${functions[@]}"; do
    fish -c "functions -q $fn" || { echo "FAIL: function $fn not found"; exit 1; }
done

# skim_key_bindings is downloaded by chezmoi script only when sk is installed
if command -v sk &>/dev/null; then
    fish -c "functions -q skim_key_bindings" || { echo "FAIL: function skim_key_bindings not found"; exit 1; }
fi

echo "==> Zellij config check"
grep -q 'theme "tokyo-night"' ~/.config/zellij/config.kdl || { echo "FAIL: zellij config - theme"; exit 1; }
grep -q 'default_shell "fish"' ~/.config/zellij/config.kdl || { echo "FAIL: zellij config - default_shell"; exit 1; }
grep -q 'pane_frames false' ~/.config/zellij/config.kdl || { echo "FAIL: zellij config - pane_frames"; exit 1; }

echo "==> Ghostty config check"
grep -q 'initial-command = zellij' ~/.config/ghostty/config || { echo "FAIL: ghostty config - initial-command"; exit 1; }

echo "==> Neovim config check"
grep -q 'lazy.nvim' ~/.config/nvim/init.lua || { echo "FAIL: nvim init.lua - lazy.nvim bootstrap"; exit 1; }
grep -q 'colorscheme tokyonight' ~/.config/nvim/init.lua || { echo "FAIL: nvim init.lua - colorscheme"; exit 1; }
grep -q 'mapleader' ~/.config/nvim/lua/keymaps.lua || { echo "FAIL: nvim keymaps - mapleader"; exit 1; }

echo "==> Dconf settings check"
dconf_ini=~/.config/dconf/gnome.ini
grep -q "color-scheme='prefer-dark'" "$dconf_ini" || { echo "FAIL: dconf - color-scheme"; exit 1; }
grep -q "dock-position='BOTTOM'" "$dconf_ini" || { echo "FAIL: dconf - dock-position"; exit 1; }
# テンプレート変数の展開確認 (username がテンプレート展開されているか)
grep -q "/home/$(whoami)/" "$dconf_ini" || { echo "FAIL: dconf - username template"; exit 1; }

echo "==> Zed settings check"
grep -q '"vim_mode": true' ~/.config/zed/settings.json || { echo "FAIL: zed settings - vim_mode"; exit 1; }
grep -q '"Tokyo Night"' ~/.config/zed/settings.json || { echo "FAIL: zed settings - theme"; exit 1; }

if [ -f "$KEY_FILE" ]; then
    echo "==> Encryption test"
    test -f ~/.ssh/test_key || { echo "FAIL: decrypted test_key not found"; exit 1; }
    grep -q "test SSH key" ~/.ssh/test_key || { echo "FAIL: test_key content mismatch"; exit 1; }

    echo "==> Git config check (encrypted)"
    git_config=~/.config/git/config
    test -f "$git_config" || { echo "FAIL: git config not found"; exit 1; }
    assert_git() {
        local label="$1" pattern="$2"
        grep -Fq "$pattern" "$git_config" || { echo "FAIL: git config - $label"; exit 1; }
    }
    assert_git "user.email" "email = dev@terassyi.net"
    assert_git "user.signingkey" "signingkey = ~/.ssh/id_ed25519.pub"
    assert_git "commit.gpgsign" "gpgsign = true"
    assert_git "gpg.format" "format = ssh"
    assert_git "pull.rebase" "rebase = true"
    assert_git "pager.diff" "diff = delta"
    assert_git "delta.navigate" "navigate = true"
    assert_git "init.defaultBranch" "defaultBranch = main"

    echo "==> SSH config check (encrypted)"
    test -f ~/.ssh/config || { echo "FAIL: SSH config not found"; exit 1; }

    echo "Encryption tests passed"
fi

echo "All checks passed"
