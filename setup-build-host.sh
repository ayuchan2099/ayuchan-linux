#!/bin/bash
# 在 Debian 12 / Ubuntu 构建机上安装 live-build 依赖

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "请使用: sudo ./setup-build-host.sh"
  exit 1
fi

apt-get update
apt-get install -y \
  live-build \
  debootstrap \
  debian-archive-keyring \
  gnupg \
  squashfs-tools \
  xorriso \
  syslinux \
  isolinux \
  genisoimage \
  git \
  curl \
  wget

# Ubuntu 自带的 debian-archive-keyring 可能过旧，无法验证 bookworm 新签名
install_latest_debian_keyring() {
  local ver
  for ver in 2025.1 2024.1 2023.4 2023.3; do
    if wget -q "http://deb.debian.org/debian/pool/main/d/debian-archive-keyring/debian-archive-keyring_${ver}_all.deb" -O /tmp/debian-archive-keyring.deb; then
      if dpkg -i /tmp/debian-archive-keyring.deb; then
        rm -f /tmp/debian-archive-keyring.deb
        return 0
      fi
    fi
  done
  return 1
}

if ! install_latest_debian_keyring; then
  echo "Warning: using distro debian-archive-keyring package"
fi

echo ""
echo "依赖已安装。下一步:"
echo "  cd ayuchan-distro"
echo "  sudo ./build.sh"
