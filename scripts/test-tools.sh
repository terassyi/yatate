#!/bin/bash
set -euo pipefail

TOMEI_DIR="${HOME}/.config/tomei"
FAIL=0
WARN=0

# Tool-specific version command overrides (default: --version)
declare -A VERSION_CMD
# VERSION_CMD[example]="-V"
# VERSION_CMD[other]="version"

get_version_output() {
    local name="$1"
    local flag="${VERSION_CMD[$name]:---version}"
    "$name" $flag 2>&1
}

# --- Discover tools from tomei plan ---
echo "==> Discovering tools from tomei plan"

if ! command -v tomei &>/dev/null; then
    echo "FAIL: tomei not found"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "FAIL: jq not found (required for parsing tomei plan output)"
    exit 1
fi

plan_json=$(tomei plan -o json "$TOMEI_DIR")

# Source .bashrc to pick up PATH (tomei env, cargo, pnpm, etc.)
set +eu
source "$HOME/.bashrc"
set -eu

# Extract Tool resources: name and version
mapfile -t tool_names < <(echo "$plan_json" | jq -r '.resources[] | select(.kind == "Tool") | .name')
mapfile -t tool_versions < <(echo "$plan_json" | jq -r '.resources[] | select(.kind == "Tool") | .version')

echo "   Found ${#tool_names[@]} tools: ${tool_names[*]}"

# --- Check each tool ---
echo "==> Checking tool binaries"

for i in "${!tool_names[@]}"; do
    name="${tool_names[$i]}"
    version="${tool_versions[$i]}"

    if ! command -v "$name" &>/dev/null; then
        echo "FAIL: $name not found in PATH"
        FAIL=$((FAIL + 1))
        continue
    fi

    echo "  OK: $name found at $(command -v "$name")"

    # Version check (best-effort)
    if version_output=$(get_version_output "$name"); then
        version_bare="${version#v}"
        if echo "$version_output" | grep -qF "$version_bare"; then
            echo "  OK: $name version matches ($version_bare)"
        else
            echo "  WARN: $name version mismatch (expected $version_bare)"
            echo "        got: $(echo "$version_output" | head -1)"
            WARN=$((WARN + 1))
        fi
    fi
done

# --- Check runtimes ---
mapfile -t runtime_names < <(echo "$plan_json" | jq -r '.resources[] | select(.kind == "Runtime") | .name')

if [ ${#runtime_names[@]} -gt 0 ]; then
    echo "==> Checking runtimes"
    for rt in "${runtime_names[@]}"; do
        case "$rt" in
            go)
                if command -v go &>/dev/null; then
                    echo "  OK: go $(go version)"
                else
                    echo "  FAIL: go not found"
                    FAIL=$((FAIL + 1))
                fi
                ;;
            rust)
                if command -v rustc &>/dev/null; then
                    echo "  OK: rustc $(rustc --version)"
                else
                    echo "  FAIL: rustc not found"
                    FAIL=$((FAIL + 1))
                fi
                ;;
            pnpm)
                if command -v pnpm &>/dev/null; then
                    echo "  OK: pnpm $(pnpm --version)"
                else
                    echo "  FAIL: pnpm not found"
                    FAIL=$((FAIL + 1))
                fi
                ;;
            lua)
                if command -v lua &>/dev/null; then
                    echo "  OK: lua $(lua -v 2>&1)"
                else
                    echo "  FAIL: lua not found"
                    FAIL=$((FAIL + 1))
                fi
                ;;
            uv)
                if command -v uv &>/dev/null; then
                    echo "  OK: uv $(uv --version)"
                else
                    echo "  FAIL: uv not found"
                    FAIL=$((FAIL + 1))
                fi
                ;;
            *)
                echo "  WARN: unknown runtime '$rt', skipping"
                WARN=$((WARN + 1))
                ;;
        esac
    done
fi

# --- Summary ---
echo ""
echo "==> Tool check summary: ${#tool_names[@]} tools, $FAIL failures, $WARN warnings"

if [ "$FAIL" -gt 0 ]; then
    echo "FAILED"
    exit 1
fi

echo "All tool checks passed"
