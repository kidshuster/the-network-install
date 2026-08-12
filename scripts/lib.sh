#!/usr/bin/env bash
# Shared helpers for install lifecycle scripts.

set -euo pipefail

run_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

compose_cmd() {
  local root
  root="$(run_root)"
  cd "$root"
  if [[ -f docker-compose.local.yml ]]; then
    docker compose -f docker-compose.yml -f docker-compose.local.yml "$@"
  else
    docker compose -f docker-compose.yml "$@"
  fi
}

service_name() {
  echo "${THE_NETWORK_SERVICE:-the-network-docker}"
}

compose_project_service() {
  echo "${THE_NETWORK_COMPOSE_SERVICE:-the-network}"
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed. See README.md for setup." >&2
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "Cannot connect to Docker. Add your user to the docker group or use sudo." >&2
    exit 1
  fi
}

require_env_file() {
  local root
  root="$(run_root)"
  if [[ ! -f "${root}/.env" ]]; then
    echo "Missing ${root}/.env — copy .env.example and set DISCORD_TOKEN and GUILD_ID." >&2
    exit 1
  fi
  if ! grep -q '^DISCORD_TOKEN=.\+' "${root}/.env" 2>/dev/null; then
    echo "Set DISCORD_TOKEN in ${root}/.env before starting." >&2
    exit 1
  fi
  if ! grep -q '^GUILD_ID=.\+' "${root}/.env" 2>/dev/null; then
    echo "Set GUILD_ID in ${root}/.env before starting." >&2
    exit 1
  fi
}

compose_service_image() {
  local image
  # Prefer compose's image list (post-pull this is the tag we will swap to).
  image="$(compose_cmd config --images 2>/dev/null | head -n 1 | tr -d '\r' || true)"
  if [[ -z "${image}" ]]; then
    image="$(
      compose_cmd config 2>/dev/null \
        | awk '/^[[:space:]]*image:[[:space:]]*/ { print $2; exit }' \
        | tr -d '\r"'
    )"
  fi
  if [[ -z "${image}" ]]; then
    echo "Could not resolve compose service image." >&2
    exit 1
  fi
  printf '%s\n' "${image}"
}

validate_image_offline() {
  local image="$1"
  local out

  echo "Validating image offline (live container stays up): ${image}"

  # No data volume and no Discord gateway — imports only.
  if ! docker run --rm --network none --entrypoint python "${image}" \
    -c 'import bot.app, bot.core, bot.features, bot.main; print("imports-ok")'; then
    echo "Offline image validation failed; live container was not swapped." >&2
    return 1
  fi

  # Entrypoint must reject test mode before starting the bot.
  out="$(mktemp)"
  if docker run --rm --network none \
    -e ENABLE_TEST_COMMANDS=true \
    "${image}" >"${out}" 2>&1; then
    echo "Image entrypoint must reject ENABLE_TEST_COMMANDS=true; live container was not swapped." >&2
    cat "${out}" >&2 || true
    rm -f "${out}"
    return 1
  fi
  if ! grep -qi 'test commands cannot be enabled' "${out}"; then
    echo "Image entrypoint rejection message missing; live container was not swapped." >&2
    cat "${out}" >&2 || true
    rm -f "${out}"
    return 1
  fi
  rm -f "${out}"

  echo "Offline validation passed."
}

compose_service_running() {
  local service id
  service="$(compose_project_service)"
  id="$(compose_cmd ps -q "${service}" 2>/dev/null || true)"
  if [[ -z "${id}" ]]; then
    return 1
  fi
  [[ "$(docker inspect -f '{{.State.Running}}' "${id}")" == "true" ]]
}
