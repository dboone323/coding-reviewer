#!/usr/bin/env bash
set -euo pipefail
: "${OLLAMA_CLOUD_URL:=}"
if [[ -n "${OLLAMA_CLOUD_URL}" ]]; then
	echo "Using Ollama Cloud at $OLLAMA_CLOUD_URL"
	exit 0
fi
if ! command -v ollama >/dev/null 2>&1; then
	echo "ollama not found; skipping local AI bootstrap"
	exit 0
fi
PID_FILE="$(mktemp -u /tmp/ollama_ci_XXXXXX.pid)"
mkdir -p "$(dirname "$PID_FILE")"
trap '[[ -f "${PID_FILE}" ]] && kill "$(cat "${PID_FILE}" 2>/dev/null)" 2>/dev/null || true' EXIT
nohup ollama serve >/dev/null 2>&1 &
echo $! >"${PID_FILE}"
sleep 2
