#!/bin/bash
# Ayuchan Linux — live-build ISO 构建脚本
# 在 Debian 12 / Ubuntu 构建机上运行: ./build.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [[ $EUID -ne 0 ]]; then
  echo "请使用 root 权限运行: sudo ./build.sh"
  exit 1
fi

for cmd in lb debootstrap; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "缺少依赖，请先安装:"
    echo "  apt update && apt install -y live-build debootstrap squashfs-tools xorriso syslinux isolinux"
    exit 1
  fi
done

chmod +x auto/config
chmod +x config/hooks/normal/*.chroot 2>/dev/null || true

echo "==> 清理上次构建..."
lb clean --purge 2>/dev/null || true

echo "==> 开始构建 Ayuchan ISO（可能需要 30–90 分钟）..."
lb build 2>&1 | tee build.log

ISO=""
for candidate in "$ROOT"/*.hybrid.iso "$ROOT"/live-image-amd64.hybrid.iso "$ROOT"/binary.hybrid.iso; do
  if [[ -f "$candidate" ]]; then
    ISO="$candidate"
    break
  fi
done

if [[ -z "$ISO" ]]; then
  ISO="$(find "$ROOT" -maxdepth 2 -name '*.iso' -type f 2>/dev/null | head -n1 || true)"
fi

if [[ -n "$ISO" ]]; then
  echo ""
  echo "构建完成: $ISO"
  sha256sum "$ISO" | tee "${ISO}.sha256"
  if command -v xorriso >/dev/null 2>&1; then
    echo ""
    echo "==> 引导检查"
    xorriso -indev "$ISO" -report_el_torito as_mkisofs 2>/dev/null | sed -n '1,6p' || true
    if xorriso -indev "$ISO" -find /boot/grub/efi.img -name . 2>/dev/null | grep -q efi.img; then
      echo "[OK] UEFI 引导文件 boot/grub/efi.img 存在"
    else
      echo "[!!] 未找到 UEFI 引导文件，虚拟机 UEFI 模式可能 Boot failed"
    fi
  fi
else
  echo "构建可能失败，请查看 build.log"
  exit 1
fi
