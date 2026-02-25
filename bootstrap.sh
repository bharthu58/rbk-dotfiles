#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting Full Polyglot Dev Bootstrap (mise + shims fixed)..."

# Container/CI compatibility: Ensure sudo exists or we are root
if ! command -v sudo &> /dev/null; then
  if [ "$(id -u)" -eq 0 ]; then
    echo "⚠️  Running as root without sudo. Installing sudo for compatibility..."
    apt-get update && apt-get install -y sudo
  else
    echo "❌ Error: This script requires 'sudo' or root privileges."
    exit 1
  fi
fi

# Prevent interactive prompts during apt installation
export DEBIAN_FRONTEND=noninteractive

############################################
# 1️⃣ Base System Packages
############################################
echo "📦 Installing base system dependencies..."
sudo apt update
sudo apt install -y \
  git curl wget build-essential \
  software-properties-common \
  ca-certificates gnupg lsb-release \
  unzip zip \
  tmux zsh bash \
  ninja-build ccache \
  gdb lldb \
  ripgrep fd-find \
  pkg-config \
  libssl-dev \
  python3-pip \
  xz-utils

############################################
# 2️⃣ Ensure ~/.local/bin in PATH
############################################
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# Ensure ~/.local/bin in profile exactly once
if ! grep -qxF 'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"' ~/.profile 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"' >> ~/.profile
fi

# Quick network check (curl is installed above); fail early if no network
if ! curl -sSf https://www.google.com/ >/dev/null 2>&1; then
  echo "❌ Network connectivity appears unavailable. Please check your connection and re-run the script."
  exit 1
fi

############################################
# 3️⃣ Install mise
############################################
if ! command -v mise &> /dev/null; then
  echo "📦 Installing mise..."
  curl https://mise.run | sh
fi

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

if ! command -v mise &> /dev/null; then
  echo "❌ mise installation failed"
  exit 1
fi

############################################
# 4️⃣ Activate mise in current session
############################################
echo "🔧 Activating mise for this shell..."
eval "$(mise activate bash)"

############################################
# 5️⃣ Install Tool Versions
############################################
echo "📦 Installing language runtimes..."
# Ensure LTS node is installed (required for tool installation steps below)
mise install node@lts
mise install

############################################
# 6️⃣ Modern C++ Toolchain
############################################
sudo apt install -y \
  clang clang-format clang-tidy clangd cmake

# Enable ccache
mkdir -p ~/.config/shell
grep -qxF 'export CC="ccache gcc"' ~/.config/shell/exports.sh 2>/dev/null || \
  echo 'export CC="ccache gcc"' >> ~/.config/shell/exports.sh
grep -qxF 'export CXX="ccache g++"' ~/.config/shell/exports.sh 2>/dev/null || \
  echo 'export CXX="ccache g++"' >> ~/.config/shell/exports.sh

############################################
# 7️⃣ Python Dev Tools
############################################
mise exec python -- pip install --upgrade pip --root-user-action=ignore
mise exec python -- pip install black ruff debugpy --root-user-action=ignore

############################################
# 8️⃣ Node Dev Tools
############################################
mise exec node -- corepack enable || true
mise exec node -- npm install -g typescript eslint prettier --unsafe-perm --loglevel error

############################################
# 9️⃣ Java Build Tools
############################################
sudo apt install -y maven gradle

############################################
# 🔟 Starship Prompt
############################################
if ! command -v starship &> /dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

############################################
# 11️⃣ Neovim
############################################
if ! command -v nvim &> /dev/null; then
  sudo add-apt-repository ppa:neovim-ppa/unstable -y
  sudo apt update
  sudo apt install -y neovim
fi

############################################
# 12️⃣ Gemini CLI
############################################
if ! command -v gemini &> /dev/null; then
  echo "📦 Installing Gemini CLI..."
  # Installing gemini cli package using LTS node to satisfy engine requirements
  mise exec node@lts -- npm install -g gemini-cli --unsafe-perm --loglevel error || true
  mise reshim

  # Ensure local bin exists for a shim
  mkdir -p "$HOME/.local/bin"

  # Discover the global npm bin dir for mise's node and create a shim named 'gemini'
  BIN_DIR="$(mise exec node@lts -- npm prefix -g 2>/dev/null)/bin"
  GEMINI_LINK_CREATED=0
  if [ -n "$BIN_DIR" ] && [ -d "$BIN_DIR" ]; then
    CANDS=(gemini gemini-cli gemini-chat generative-ai-cli generative-ai google-generative-ai)
    for b in "${CANDS[@]}"; do
      if [ -x "$BIN_DIR/$b" ]; then
        ln -sf "$BIN_DIR/$b" "$HOME/.local/bin/gemini"
        GEMINI_LINK_CREATED=1
        break
      fi
    done

    # Fallback: look for any bin with 'generat' or 'gemini' in the name
    if [ "$GEMINI_LINK_CREATED" -eq 0 ]; then
      for f in "$BIN_DIR"/*; do
        fname="$(basename "$f")"
        case "$fname" in
          *generat*|*gemini*|*google*|*gai*)
            if [ -x "$f" ]; then
              ln -sf "$f" "$HOME/.local/bin/gemini"
              GEMINI_LINK_CREATED=1
              break
            fi
            ;;
        esac
      done
    fi
  fi

  if [ "$GEMINI_LINK_CREATED" -eq 1 ]; then
    echo "✅ Created gemini shim at ~/.local/bin/gemini"
  else
    echo "⚠️  Could not detect gemini binary after install; please check the package's bin names."
  fi
fi

############################################
# 13️⃣ Claude Code CLI
############################################
if ! command -v claude &> /dev/null; then
  mise exec node -- npm install -g @anthropic-ai/claude-code --unsafe-perm --loglevel error || true
  mise reshim
  if ! command -v claude &> /dev/null; then
    echo "⚠️  'claude' binary not found after installing @anthropic-ai/claude-code."
  fi
fi

############################################
# 14️⃣ Install chezmoi + Apply Dotfiles
############################################
if ! command -v chezmoi &> /dev/null; then
  # Install specifically to ~/.local/bin so it is in PATH
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

# Fix "dubious ownership" error when running in containers/mounts
git config --global --add safe.directory "*"

# Initialize chezmoi from the current working directory explicitly
chezmoi init --apply "${PWD}" || echo "⚠️  chezmoi init failed; you may want to run 'chezmoi init --apply <repo>' manually."

############################################
# 15️⃣ Permanent Mise Activation (bash + zsh)
############################################
# Add mise activation to .bashrc
if ! grep -q "mise activate bash" ~/.bashrc 2>/dev/null; then
  echo 'eval "$(mise activate bash)"' >> ~/.bashrc
  echo 'eval "$(starship init bash)"' >> ~/.bashrc
fi

# Add mise activation to .zshrc
if ! grep -q "mise activate zsh" ~/.zshrc 2>/dev/null; then
  echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
  echo 'eval "$(starship init zsh)"' >> ~/.zshrc
fi

# Also add shims path to exports.sh if missing
mkdir -p ~/.config/shell
touch ~/.config/shell/exports.sh
SHIM_LINE='export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"'
grep -qxF "$SHIM_LINE" ~/.config/shell/exports.sh 2>/dev/null || \
  echo "$SHIM_LINE" >> ~/.config/shell/exports.sh

# Set global Node.js default to LTS (ensures modern runtime for new shells)
mise use --global node@lts

############################################
# 16️⃣ Set Default Shell
############################################
if command -v chsh &> /dev/null; then
  if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)" || echo "⚠️  chsh failed; you may need to change your login shell manually."
  fi
else
  echo "⚠️  'chsh' not available; skipping default shell change."
fi

############################################
# ✅ Done
############################################
echo ""
echo "✅ Full Polyglot Dev Environment Installed!"
echo ""
echo "Installed:"
echo " - Modern C++ (clang, gcc, cmake, ninja, ccache)"
echo " - Python + dev tools"
echo " - Node.js + dev tools"
echo " - Java + Maven/Gradle"
echo " - Gemini CLI"
echo " - Claude Code CLI"
echo " - Neovim"
echo " - Starship prompt"
echo " - Dual shell support (bash + zsh)"
echo ""

echo "🔄 Reloading shell environment..."
# Replace current shell with zsh (if installed) or bash to apply changes immediately
if command -v zsh >/dev/null; then
  exec zsh -l
else
  exec bash -l
fi