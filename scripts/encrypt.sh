#!/bin/bash
set -euo pipefail

# 平文テンプレートを全 3 recipient で age 暗号化する
# Usage: scripts/encrypt.sh <plaintext-file> <encrypted-output>
# Example: scripts/encrypt.sh plaintext/git-config.tmpl dot_config/git/encrypted_config.tmpl

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RECIPIENTS_FILE="$(dirname "$SCRIPT_DIR")/age-recipients.txt"

usage() {
    echo "Usage: $0 <plaintext-file> <encrypted-output>"
    echo ""
    echo "Encrypt a plaintext template with all profile recipients."
    echo "Recipients are read from: age-recipients.txt"
    echo ""
    echo "Examples:"
    echo "  $0 plaintext/git-config.tmpl dot_config/git/encrypted_config.tmpl"
    echo "  $0 plaintext/ssh-config.tmpl dot_ssh/encrypted_config.tmpl"
    exit 1
}

[ $# -eq 2 ] || usage

PLAINTEXT="$1"
OUTPUT="$2"

[ -f "$PLAINTEXT" ] || { echo "ERROR: $PLAINTEXT not found" >&2; exit 1; }
[ -f "$RECIPIENTS_FILE" ] || { echo "ERROR: $RECIPIENTS_FILE not found" >&2; exit 1; }

if ! command -v age &>/dev/null; then
    echo "ERROR: age command not found. Install with: tomei apply" >&2
    exit 1
fi

age -R "$RECIPIENTS_FILE" -o "$OUTPUT" "$PLAINTEXT"
echo "Encrypted: $PLAINTEXT -> $OUTPUT"
