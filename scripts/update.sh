#!/usr/bin/env bash
# Sync install repo, pull and offline-validate the new image, then swap live.
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

require_docker
require_env_file

root="$(run_root)"
cd "$root"

pull_install_repo

if [[ -f VERSION ]]; then
  echo "Updating to version $(cat VERSION)..."
fi

echo "Pulling image (live container keeps running)..."
compose_cmd pull

image="$(compose_service_image)"
if ! validate_image_offline "${image}"; then
  exit 1
fi

echo "Validation passed; swapping live container..."
compose_cmd up -d --remove-orphans

if ! compose_service_running; then
  echo "Swap finished but the the-network container is not running; skipping prune." >&2
  compose_cmd ps >&2 || true
  exit 1
fi

echo "Swap confirmed. Pruning unused Docker data host-wide (docker system prune -af)..."
docker system prune -af

echo "Update complete."
compose_cmd ps
