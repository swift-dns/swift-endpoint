#!/bin/bash

set -Eeuo pipefail

script_dir="$(dirname "${BASH_SOURCE[0]}")"

workflow_file="${WORKFLOW_FILE:?the repo-relative path of the calling workflow file, e.g. '.github/workflows/unit-tests.yml'}"

force_run_paths=(
  "${workflow_file}"
  ".github/scripts/check-tests-relevance.sh"
)

export TARGET_KIND="test"
export TARGET_FILTER='select(.type == "test")'
export PACKAGE_PATH="."
FORCE_RUN_PATHS="$(printf '%s\n' "${force_run_paths[@]}")"
export FORCE_RUN_PATHS

exec "${script_dir}/check-relevance.sh"
