#!/usr/bin/env bash
# Comprehensive verification script for rbk-dotfiles bootstrap

set -u

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

log_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASS_COUNT++))
}

log_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAIL_COUNT++))
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if a command exists and optionally print its version
check_cmd() {
    local cmd="$1"
    local name="${2:-$cmd}"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        # Try to get version, handle different flags
        local version=""
        if "$cmd" --version >/dev/null 2>&1; then
            version=$("$cmd" --version 2>&1 | head -n 1)
        elif "$cmd" -v >/dev/null 2>&1; then
            version=$("$cmd" -v 2>&1 | head -n 1)
        elif "$cmd" version >/dev/null 2>&1; then
            version=$("$cmd" version 2>&1 | head -n 1)
        fi
        
        # Truncate long version strings
        version=$(echo "$version" | cut -c 1-50)
        if [ -n "$version" ]; then
            log_pass "Found $name: $version"
        else
            log_pass "Found $name"
        fi
    else
        log_fail "Missing $name"
    fi
}

echo "========================================"
echo "🔍 Verifying Bootstrap Installation"
echo "========================================"

# Ensure shims are in path for this script if not already
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# 1. Base System Tools
echo -e "\n[Base System Tools]"
check_cmd git
check_cmd curl
check_cmd wget
check_cmd tmux
check_cmd rg "ripgrep"
# Ubuntu installs fd as fdfind
if command -v fdfind >/dev/null 2>&1; then
    check_cmd fdfind "fd (fdfind)"
else
    check_cmd fd
fi

# 2. Mise & Runtimes
echo -e "\n[Mise & Runtimes]"
check_cmd mise
if command -v mise >/dev/null 2>&1; then
    mise doctor 2>&1 | grep "mise version" >/dev/null && log_pass "mise doctor check" || log_warn "mise doctor reported issues"
fi

check_cmd node "Node.js"
check_cmd python "Python"
check_cmd java "Java"
check_cmd cmake "CMake"

# 3. C++ Toolchain
echo -e "\n[C++ Toolchain]"
check_cmd clang
check_cmd clang++
check_cmd clang-format
check_cmd clang-tidy
check_cmd ninja
check_cmd ccache
check_cmd gdb

# 4. Language Specific Tools
echo -e "\n[Dev Tools]"
# Python
check_cmd pip
check_cmd black
check_cmd ruff
# Node
check_cmd tsc "TypeScript"
check_cmd eslint
check_cmd prettier
# Java
check_cmd mvn "Maven"
check_cmd gradle

# 5. Editors & Shell
echo -e "\n[Editors & Shell]"
check_cmd nvim "Neovim"
check_cmd starship

# 6. AI CLIs
echo -e "\n[AI CLIs]"
check_cmd gemini "Gemini CLI"
check_cmd claude "Claude Code CLI"

# 7. Configuration Files
echo -e "\n[Configuration]"
check_cmd chezmoi

FILES_TO_CHECK=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.bash_aliases"
    "$HOME/.config/shell/exports.sh"
    "$HOME/.local/bin/gemini"
)

for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ] || [ -L "$file" ]; then
        log_pass "File exists: $file"
    else
        log_fail "Missing file: $file"
    fi
done

# Check content of .bashrc for critical integrations
if [ -f "$HOME/.bashrc" ]; then
    if grep -q "mise activate bash" "$HOME/.bashrc"; then
        log_pass "mise activation found in .bashrc"
    else
        log_fail "mise activation MISSING in .bashrc"
    fi
    
    if grep -q "starship init bash" "$HOME/.bashrc"; then
        log_pass "starship init found in .bashrc"
    else
        log_fail "starship init MISSING in .bashrc"
    fi
fi

echo "========================================"
echo "Summary: $PASS_COUNT passed, $FAIL_COUNT failed."

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}🎉 System verification successful!${NC}"
    rm -f *.log
    exit 0
else
    echo -e "${RED}💥 Some checks failed. Please review the logs above.${NC}"
    exit 1
fi
