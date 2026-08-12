#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [[ "${ENABLE_TEST_COMMANDS:-false}" == "true" ]]; then
  echo "Test commands cannot be enabled by the production launcher." >&2
  exit 1
fi

require_docker
require_env_file
compose_cmd up -d --remove-orphans
echo "The Network is running."
compose_cmd ps
