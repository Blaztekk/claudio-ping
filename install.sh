#!/usr/bin/env bash
# claude-notif installer — macOS / Linux

set -e

SETTINGS="$HOME/.claude/settings.json"
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
    SNIPPET="$(dirname "$0")/snippets/macos.json"
else
    SNIPPET="$(dirname "$0")/snippets/linux.json"
fi

# Backup existing settings + retention (keep 5 most recent)
if [[ -f "$SETTINGS" ]]; then
    BACKUP="${SETTINGS}.bak-$(date +%Y%m%d-%H%M%S)"
    cp "$SETTINGS" "$BACKUP"
    echo "Backup: $BACKUP"
    ls -1t "${SETTINGS}".bak-* 2>/dev/null | tail -n +6 | xargs -r rm -f
fi

mkdir -p "$(dirname "$SETTINGS")"

# Prefer jq; fall back to python3
if command -v jq &>/dev/null; then
    TMP="$(mktemp)"
    if [[ -f "$SETTINGS" ]]; then
        SRC="$SETTINGS"
    else
        echo '{}' > "$TMP.empty"
        SRC="$TMP.empty"
    fi
    jq --slurpfile snip "$SNIPPET" '
        .hooks = (.hooks // {}) |
        reduce ($snip[0].hooks | to_entries[]) as $e (
            .;
            if .hooks[$e.key] then . else .hooks[$e.key] = $e.value end
        )
    ' "$SRC" > "$TMP"

    # Report which hooks were added vs skipped
    for evt in $(jq -r '.hooks | keys[]' "$SNIPPET"); do
        if [[ -f "$SETTINGS" ]] && jq -e ".hooks[\"$evt\"]" "$SETTINGS" &>/dev/null; then
            echo "Hook '$evt' already exists in settings.json — skipped."
            echo "  To merge or replace, edit manually using: $SNIPPET"
        else
            echo "Added hook: $evt"
        fi
    done

    mv "$TMP" "$SETTINGS"
    rm -f "$TMP.empty"
elif command -v python3 &>/dev/null; then
    python3 - <<EOF
import json, os

settings_path = os.path.expanduser("$SETTINGS")
snippet_path = "$SNIPPET"

settings = {}
if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)

with open(snippet_path) as f:
    snippet = json.load(f)

hooks = settings.setdefault("hooks", {})
for event, value in snippet["hooks"].items():
    if event not in hooks:
        hooks[event] = value
        print(f"Added hook: {event}")
    else:
        print(f"Hook '{event}' already exists in settings.json — skipped.")
        print(f"  To merge or replace, edit manually using: {snippet_path}")

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
EOF
else
    echo "Neither 'jq' nor 'python3' found."
    echo "Install one of them, or merge $SNIPPET into $SETTINGS manually."
    exit 1
fi

echo ""
echo "Done. Restart Claude Code to activate."
