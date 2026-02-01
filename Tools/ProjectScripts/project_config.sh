#!/bin/bash
# Project configuration for CodingReviewer (root project)

# shellcheck disable=SC2034
export ENABLE_AUTO_BUILD=true
# shellcheck disable=SC2034
export ENABLE_AI_ENHANCEMENT=true
# shellcheck disable=SC2034
export ENABLE_AUTO_TEST=true
# shellcheck disable=SC2034
export PROJECT_NAME="CodingReviewer"
SETUP_PATH="$(git rev-parse --show-toplevel 2>/dev/null)/scripts/setup_paths.sh"
if [[ -f "${SETUP_PATH}" ]]; then
	# shellcheck disable=SC1090
	source "${SETUP_PATH}"
fi

# shellcheck disable=SC2034
export PROJECT_DIR="${PROJECT_DIR:-${WORKSPACE_ROOT}/CodingReviewer}"
# shellcheck disable=SC2034
export PROJECT_DISPLAY_NAME="CodingReviewer"
# shellcheck disable=SC2034
export PROJECT_TYPE="macOS App"
# shellcheck disable=SC2034
export PROJECT_FEATURE_SUMMARY="Automated code review workflows"

echo "✅ CodingReviewer project configuration loaded (root)"
# End of configuration
