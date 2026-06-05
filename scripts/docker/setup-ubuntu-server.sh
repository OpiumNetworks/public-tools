#!/usr/bin/env bash
#
# Install Docker Engine on Ubuntu Server using Docker's official apt repository.
# Tested on Ubuntu 22.04 and 24.04 LTS.
#
set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly DOCKER_APT_KEYRING="/etc/apt/keyrings/docker.asc"
readonly DOCKER_APT_LIST="/etc/apt/sources.list.d/docker.list"

log() {
  printf '[%s] %s\n' "$SCRIPT_NAME" "$*"
}

die() {
  printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$*" >&2
  exit 1
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "Run as root or with sudo: sudo bash $SCRIPT_NAME"
  fi
}

require_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    die "Cannot detect OS. This script is for Ubuntu Server only."
  fi

  # shellcheck source=/dev/null
  source /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    die "This script is for Ubuntu Server. Detected: ${PRETTY_NAME:-unknown}"
  fi

  log "Detected ${PRETTY_NAME:-Ubuntu}"
}

apt_install() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq "$@"
}

remove_legacy_docker_packages() {
  log "Removing legacy Docker packages if present (safe to skip if none installed)"
  apt-get remove -y -qq docker docker-engine docker.io containerd runc 2>/dev/null || true
}

install_prerequisites() {
  log "Installing prerequisites"
  apt_install ca-certificates curl gnupg
}

add_docker_apt_repo() {
  log "Adding Docker apt repository"

  install -m 0755 -d /etc/apt/keyrings

  if [[ ! -f "$DOCKER_APT_KEYRING" ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$DOCKER_APT_KEYRING"
    chmod a+r "$DOCKER_APT_KEYRING"
  else
    log "Docker GPG key already present at $DOCKER_APT_KEYRING"
  fi

  # shellcheck source=/dev/null
  source /etc/os-release

  local arch
  arch="$(dpkg --print-architecture)"

  if [[ ! -f "$DOCKER_APT_LIST" ]]; then
    echo "deb [arch=${arch} signed-by=${DOCKER_APT_KEYRING}] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
      > "$DOCKER_APT_LIST"
  else
    log "Docker apt source already present at $DOCKER_APT_LIST"
  fi
}

install_docker_packages() {
  log "Installing Docker Engine and plugins"
  apt-get update -qq
  apt_install \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
}

enable_docker_service() {
  log "Enabling and starting docker service"
  systemctl enable docker
  systemctl start docker
}

add_user_to_docker_group() {
  local target_user="${SUDO_USER:-}"

  if [[ -z "$target_user" || "$target_user" == "root" ]]; then
    log "No non-root sudo user detected; skipping docker group membership"
    log "To run docker without sudo later: sudo usermod -aG docker <username>"
    return 0
  fi

  if id -nG "$target_user" | grep -qw docker; then
    log "User '$target_user' is already in the docker group"
    return 0
  fi

  log "Adding '$target_user' to the docker group"
  usermod -aG docker "$target_user"
  log "User '$target_user' must log out and back in for group changes to apply"
}

verify_installation() {
  log "Verifying Docker installation"
  docker --version
  docker compose version
  docker run --rm hello-world >/dev/null
  log "Docker is installed and responding"
}

main() {
  require_root
  require_ubuntu

  remove_legacy_docker_packages
  install_prerequisites
  add_docker_apt_repo
  install_docker_packages
  enable_docker_service
  add_user_to_docker_group
  verify_installation

  log "Done"
}

main "$@"
