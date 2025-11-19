#!/bin/bash
# Project configuration for CodingReviewer (root project)

export ENABLE_AUTO_BUILD=true
export ENABLE_AI_ENHANCEMENT=true
export ENABLE_AUTO_TEST=true
export PROJECT_NAME="CodingReviewer"
SETUP_PATH="$(git rev-parse --show-toplevel 2>/dev/null)/scripts/setup_paths.sh"
if [[ -f "${SETUP_PATH}" ]]; then
	# shellcheck disable=SC1090
	source "${SETUP_PATH}"
fi

export PROJECT_DIR="${PROJECT_DIR:-${WORKSPACE_ROOT}/CodingReviewer}"
export PROJECT_DISPLAY_NAME="CodingReviewer"
export PROJECT_TYPE="macOS App"
export PROJECT_FEATURE_SUMMARY="Automated code review workflows"

echo "✅ CodingReviewer project configuration loaded (root)"
# End of configuration
