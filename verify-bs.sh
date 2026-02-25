#!/usr/bin/env bash
# Lightweight verification script — tolerant of missing CLIs

echo "==> mise"
if command -v mise >/dev/null 2>&1; then
	mise doctor || echo "mise doctor reported an issue"
else
	echo "⚠️  mise not found on PATH"
fi

for cmd in python node java cmake; do
	echo "==> $cmd"
	if command -v "$cmd" >/dev/null 2>&1; then
		"$cmd" --version 2>&1 | sed -n '1,5p'
	else
		echo "⚠️  $cmd not found"
	fi
done

# Check gemini CLI (try common package binary names)
GEMINI_CANDS=(gemini generative-ai-cli)
GEMINI_FOUND=0
for c in "${GEMINI_CANDS[@]}"; do
	if command -v "$c" >/dev/null 2>&1; then
		echo "==> $c"
		"$c" --help 2>&1 | sed -n '1,10p' || echo "(no --help available)"
		GEMINI_FOUND=1
		break
	fi
done
if [ "$GEMINI_FOUND" -eq 0 ]; then
	echo "⚠️  gemini CLI not found (tried: ${GEMINI_CANDS[*]})"
fi

# Check claude-code CLI (try common package binary names)
CLAUDE_CANDS=(claude-code claude anthropic)
CLAUDE_FOUND=0
for c in "${CLAUDE_CANDS[@]}"; do
	if command -v "$c" >/dev/null 2>&1; then
		echo "==> $c"
		"$c" --help 2>&1 | sed -n '1,10p' || echo "(no --help available)"
		CLAUDE_FOUND=1
		break
	fi
done
if [ "$CLAUDE_FOUND" -eq 0 ]; then
	echo "⚠️  claude-code CLI not found (tried: ${CLAUDE_CANDS[*]})"
fi

echo "Done."
