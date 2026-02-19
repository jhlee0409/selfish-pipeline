#!/bin/bash
# Selfish — Claude Code Pipeline System Installer
# Usage: ./install.sh [--commands-only | --hooks-only | --config-only]
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/commands"
HOOKS_SRC="$SCRIPT_DIR/hooks"
TEMPLATES_SRC="$SCRIPT_DIR/templates"

# Destinations
USER_COMMANDS="$HOME/.claude/commands"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_HOOKS="$PROJECT_DIR/.claude/hooks"
PROJECT_SETTINGS="$PROJECT_DIR/.claude/settings.json"
PROJECT_CONFIG="$PROJECT_DIR/.claude/selfish.config.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

install_commands() {
    echo ""
    echo "📦 Installing selfish commands → $USER_COMMANDS"
    mkdir -p "$USER_COMMANDS"

    local count=0
    for cmd in "$COMMANDS_SRC"/selfish.*.md; do
        [ -f "$cmd" ] || continue
        local name=$(basename "$cmd")
        if [ -f "$USER_COMMANDS/$name" ]; then
            warn "$name exists, backing up → ${name}.bak"
            cp "$USER_COMMANDS/$name" "$USER_COMMANDS/${name}.bak"
        fi
        cp "$cmd" "$USER_COMMANDS/$name"
        count=$((count + 1))
    done
    info "Installed $count commands"
}

install_hooks() {
    echo ""
    echo "🪝 Installing selfish hooks → $PROJECT_HOOKS"
    mkdir -p "$PROJECT_HOOKS"

    local count=0
    for hook in "$HOOKS_SRC"/*.sh; do
        [ -f "$hook" ] || continue
        local name=$(basename "$hook")
        cp "$hook" "$PROJECT_HOOKS/$name"
        chmod +x "$PROJECT_HOOKS/$name"
        count=$((count + 1))
    done
    info "Installed $count hooks"

    # settings.json 병합
    if [ -f "$PROJECT_SETTINGS" ]; then
        warn "settings.json already exists. Merge selfish hooks manually:"
        echo "   See: $TEMPLATES_SRC/settings.json"
    else
        mkdir -p "$(dirname "$PROJECT_SETTINGS")"
        cp "$TEMPLATES_SRC/settings.json" "$PROJECT_SETTINGS"
        info "Created settings.json with hook configuration"
    fi
}

install_config() {
    echo ""
    echo "⚙️  Setting up project config → $PROJECT_CONFIG"

    if [ -f "$PROJECT_CONFIG" ]; then
        warn "selfish.config.md already exists. Skipping."
    else
        cp "$TEMPLATES_SRC/selfish.config.template.md" "$PROJECT_CONFIG"
        info "Created selfish.config.md (edit to match your project)"
        warn "TODO: Edit .claude/selfish.config.md with your project's CI commands, architecture, etc."
    fi
}

# Main
echo "═══════════════════════════════════════════"
echo " Selfish — Claude Code Pipeline System"
echo "═══════════════════════════════════════════"
echo ""
echo "  Commands  → ~/.claude/commands/ (user-level, all projects)"
echo "  Hooks     → .claude/hooks/ (project-level)"
echo "  Config    → .claude/selfish.config.md (project-level)"

case "${1:-}" in
    --commands-only)
        install_commands
        ;;
    --hooks-only)
        install_hooks
        ;;
    --config-only)
        install_config
        ;;
    *)
        install_commands
        install_hooks
        install_config
        ;;
esac

echo ""
echo "═══════════════════════════════════════════"
echo " Installation complete!"
echo ""
echo " Next steps:"
echo "   1. Edit .claude/selfish.config.md"
echo "   2. Run /selfish.spec \"your feature\""
echo "═══════════════════════════════════════════"
