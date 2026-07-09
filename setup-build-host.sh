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
  squashfs-tools \
  xorriso \
  syslinux \
  isolinux \
  genisoimage \
  grub-pc-bin \
  grub-efi-amd64-bin \
  grub2-common \
  mtools \
  git \
  curl \
  wget

echo ""
echo "依赖已安装。下一步:"
echo "  cd ayuchan-distro"
echo "  sudo ./build.sh"
