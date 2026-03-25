#!/bin/bash
set -euo pipefail
umask 077

# テスト用 age 鍵を chezmoi が期待するパスに配置する
# CI: AGE_TEST_SECRET_KEY 環境変数から注入
# ローカル: testdata/age-test-key.txt からコピー（gitignore 済み）

KEY_DST="${HOME}/.config/chezmoi/key-test.txt"

# CI: シークレットから注入
if [ -n "${AGE_TEST_SECRET_KEY:-}" ]; then
    mkdir -p "$(dirname "$KEY_DST")"
    printf '%s\n' "$AGE_TEST_SECRET_KEY" > "$KEY_DST"
    chmod 600 "$KEY_DST"
    echo "Test age key installed from secret: $KEY_DST"
    exit 0
fi

# ローカル: testdata/ からコピー（存在する場合のみ）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEY_SRC="$(dirname "$SCRIPT_DIR")/testdata/age-test-key.txt"
if [ -f "$KEY_SRC" ]; then
    mkdir -p "$(dirname "$KEY_DST")"
    cp "$KEY_SRC" "$KEY_DST"
    chmod 600 "$KEY_DST"
    echo "Test age key installed from file: $KEY_DST"
    exit 0
fi

if [ "${REQUIRE_KEY:-0}" = "1" ]; then
    echo "ERROR: No test key available (set AGE_TEST_SECRET_KEY or place testdata/age-test-key.txt)" >&2
    exit 1
fi
echo "SKIP: No test key available (set AGE_TEST_SECRET_KEY or place testdata/age-test-key.txt)"
exit 0
