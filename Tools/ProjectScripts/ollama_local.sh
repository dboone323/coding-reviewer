#!/usr/bin/env bash
set -euo pipefail

# Simple launcher to run CodingReviewer workflows via local Ollama.
# Prefers submodule Tools/Automation if present.

command -v ollama >/dev/null 2>&1 || {
	echo "ollama not found. Install from https://ollama.com and ensure it's on PATH."
	exit 1
}

WORKDIR="$(cd "$(dirname "$0")"/../.. && pwd)"
AUTOMATION_DIR="$WORKDIR/Tools/Automation"

if [[ -d "$AUTOMATION_DIR" && -f "$AUTOMATION_DIR/mcp_workflow.sh" ]]; then
	echo "Using submodule workflow: $AUTOMATION_DIR/mcp_workflow.sh"
	exec "$AUTOMATION_DIR/mcp_workflow.sh" "$@"
fi

MODEL="${OLLAMA_MODEL:-llama3.1}"
PROMPT="${1:-'Summarize this repository'}"

if ! pgrep -f "ollama serve" >/dev/null 2>&1; then
	echo "Starting ollama server in background..."
	nohup ollama serve >/dev/null 2>&1 &
	sleep 2
fi

echo "Running ollama run $MODEL"
ollama run "$MODEL" "$PROMPT"
