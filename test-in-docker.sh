#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path of the repo root (where this script lives)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🐳 Starting Docker test container..."
echo "Mounting: $REPO_ROOT -> /root/dotfiles"

# Check if .gemini exists locally to mount it (for testing custom commands)
GEMINI_MOUNT=""
if [ -d "$HOME/.gemini" ]; then
  echo "Mounting: $HOME/.gemini -> /root/.gemini"
  GEMINI_MOUNT="-v $HOME/.gemini:/root/.gemini"
fi

docker run --rm -it \
  -v "$REPO_ROOT:/root/dotfiles" \
  $GEMINI_MOUNT \
  -w /root/dotfiles \
  ubuntu:latest \
  bash bootstrap.sh