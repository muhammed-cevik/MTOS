#!/usr/bin/env bash
# MT OS - Limbo/QEMU Boot IMG Builder
# Bu script GitHub Actions'da çalışır
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
INITRD_DIR="$BUILD_DIR/initramfs"
IMG="$DIST_DIR/mtos-limbo.img"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MT OS Limbo/QEMU Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "$BUILD_DIR" "$DIST_DIR" "$INITRD_DIR"

# ─── 1. Kernel bul ────────────────────────────────────────────────────────────
echo "[1/6] Kernel aranıyor..."
KERNEL=$(ls /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)
if [ -z "$KERNEL" ]; then
    echo "✗ Kernel bulunamadı!"
    exit 1
fi
echo "  ✓ Kernel: $KERNEL"
cp "$KERNEL" "$DIST_DIR/bzImage"

# ─── 2. initramfs yapısı ──────────────────────────────────────────────────────
echo "[2/6] initramfs yapısı oluşturuluyor..."
mkdir -p "$INITRD_DIR"/{bin,sbin,etc,proc,sys,dev,tmp,root,usr/bin,usr/lib,home/mtos}

# BusyBox
BUSYBOX=$(which busybox)
cp "$BUSYBOX" "$INITRD_DIR/bin/busybox"
chmod +x "$INITRD_DIR/bin/busybox"

# BusyBox symlinks
cd "$INITRD_DIR/bin"
for cmd in sh ash ls mkdir rm cat echo pwd cd; do
    ln -sf busybox $cmd 2>/dev/null || true
done
cd "$INITRD_DIR/sbin"
for cmd in init reboot poweroff; do
    ln -sf ../bin/busybox $cmd 2>/dev/null || true
done
cd "$ROOT_DIR"

# ─── 3. Python kopyala ────────────────────────────────────────────────────────
echo "[3/6] Python + MT OS dosyaları kopyalanıyor..."

# Python binary
PYTHON=$(which python3)
cp "$PYTHON" "$INITRD_DIR/usr/bin/python3"

# Python shared libs
ldd "$PYTHON" 2>/dev/null | grep "=> /" | awk '{print $3}' | while read lib; do
    dir="$INITRD_DIR$(dirname $lib)"
    mkdir -p "$dir"
    cp -L "$lib" "$dir/" 2>/dev/null || true
done

# Python stdlib - minimal
PYVER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PYLIB="/usr/lib/python${PYVER}"
PYLIB_DEST="$INITRD_DIR/usr/lib/python${PYVER}"
mkdir -p "$PYLIB_DEST"
# Sadece gerekli modüller
for mod in os sys pathlib readline shutil subprocess platform datetime random string re; do
    find "$PYLIB" -name "${mod}.py" -exec cp {} "$PYLIB_DEST/" \; 2>/dev/null || true
    find "$PYLIB" -name "${mod}" -type d -exec cp -r {} "$PYLIB_DEST/" \; 2>/dev/null || true
done
# encodings
cp -r "$PYLIB/encodings" "$PYLIB_DEST/" 2>/dev/null || true
cp "$PYLIB/os.py" "$PYLIB_DEST/" 2>/dev/null || true

# Python dynlib
PYDYNLIB=$(find /usr/lib -name "libpython${PYVER}*.so*" 2>/dev/null | head -1)
if [ -n "$PYDYNLIB" ]; then
    mkdir -p "$INITRD_DIR/usr/lib"
    cp -L "$PYDYNLIB" "$INITRD_DIR/usr/lib/"
fi

# ─── 4. Lua kopyala ────────────────────────────────────────────────────────────
echo "[4/6] Lua kopyalanıyor..."
LUA=$(which lua5.4 || which lua || true)
if [ -n "$LUA" ]; then
    cp "$LUA" "$INITRD_DIR/usr/bin/lua"
    ldd "$LUA" 2>/dev/null | grep "=> /" | awk '{print $3}' | while read lib; do
        dir="$INITRD_DIR$(dirname $lib)"
        mkdir -p "$dir"
        cp -L "$lib" "$dir/" 2>/dev/null || true
    done
    echo "  ✓ Lua: $LUA"
fi

# MT OS dosyaları
cp -r "$ROOT_DIR/shell"  "$INITRD_DIR/root/"
cp -r "$ROOT_DIR/games"  "$INITRD_DIR/root/"
cp -r "$ROOT_DIR/lua"    "$INITRD_DIR/root/"

# ─── 5. Init script ───────────────────────────────────────────────────────────
echo "[5/6] Init scripti yazılıyor..."
cat > "$INITRD_DIR/init" << 'INITEOF'
#!/bin/sh
# MT OS init

# Temel mount
mount -t proc  none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true

# Konsol
exec < /dev/console
exec > /dev/console
exec 2> /dev/console

# Hostname
hostname mtos

clear
echo ""
echo "  ███╗   ███╗████████╗ ██████╗ ███████╗"
echo "  ████╗ ████║╚══██╔══╝██╔═══██╗██╔════╝"
echo "  ██╔████╔██║   ██║   ██║   ██║███████╗"
echo "  ██║╚██╔╝██║   ██║   ██║   ██║╚════██║"
echo "  ██║ ╚═╝ ██║   ██║   ╚██████╔╝███████║"
echo "  ╚═╝     ╚═╝   ╚═╝    ╚═════╝ ╚══════╝"
echo ""
echo "  MT OS v1.0.0 - Limbo/QEMU Edition"
echo "  Booting..."
echo ""

sleep 1

export MTOS_ROOT=/root
export HOME=/root
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

cd /root

# Python shell'i başlat
if [ -f /usr/bin/python3 ]; then
    while true; do
        python3 /root/shell/shell.py
        echo "Shell yeniden başlatılıyor..."
        sleep 1
    done
else
    echo "Python bulunamadı, BusyBox shell'e düşülüyor..."
    exec /bin/sh
fi
INITEOF
chmod +x "$INITRD_DIR/init"

# /etc/passwd minimal
echo "root:x:0:0:root:/root:/bin/sh" > "$INITRD_DIR/etc/passwd"
echo "root::0:0:::" > "$INITRD_DIR/etc/shadow" 2>/dev/null || true

# ─── 6. initramfs + IMG ───────────────────────────────────────────────────────
echo "[6/6] initramfs + IMG oluşturuluyor..."

# initramfs.cpio.gz
INITRD="$DIST_DIR/initrd.img"
cd "$INITRD_DIR"
find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$INITRD"
cd "$ROOT_DIR"

echo "  ✓ initrd: $(ls -lh $INITRD | awk '{print $5}')"
echo "  ✓ bzImage: $(ls -lh $DIST_DIR/bzImage | awk '{print $5}')"

# Disk IMG (FAT32, Limbo için)
IMG_SIZE=128  # MB
dd if=/dev/zero of="$IMG" bs=1M count=$IMG_SIZE status=none
mkfs.fat -F 32 -n "MTOS" "$IMG"

# Syslinux bootloader kur
if command -v syslinux >/dev/null 2>&1; then
    syslinux --install "$IMG"
    MBR=$(find /usr/lib/syslinux /usr/share/syslinux -name "mbr.bin" 2>/dev/null | head -1)
    [ -n "$MBR" ] && dd if="$MBR" of="$IMG" bs=440 count=1 conv=notrunc status=none
fi

# Dosyaları IMG'ye kopyala
MOUNT_TMP=$(mktemp -d)
if sudo mount -o loop "$IMG" "$MOUNT_TMP" 2>/dev/null; then
    sudo mkdir -p "$MOUNT_TMP/syslinux"
    sudo cp "$DIST_DIR/bzImage" "$MOUNT_TMP/"
    sudo cp "$INITRD"           "$MOUNT_TMP/"
    
    # Syslinux config
    sudo tee "$MOUNT_TMP/syslinux/syslinux.cfg" > /dev/null << 'SYSEOF'
DEFAULT mtos
PROMPT 0
TIMEOUT 30

LABEL mtos
  MENU LABEL MT OS v1.0.0
  KERNEL /bzImage
  APPEND initrd=/initrd.img console=ttyS0 quiet
SYSEOF

    # extlinux varsa
    if command -v extlinux >/dev/null 2>&1; then
        sudo extlinux --install "$MOUNT_TMP/syslinux/" 2>/dev/null || true
    fi
    
    sudo umount "$MOUNT_TMP"
    echo "  ✓ IMG: $IMG ($(ls -lh $IMG | awk '{print $5}'))"
else
    echo "  INFO: Mount yetkisi yok, mcopy deneniyor..."
    if command -v mcopy >/dev/null 2>&1; then
        mcopy -i "$IMG" "$DIST_DIR/bzImage" "::bzImage"
        mcopy -i "$IMG" "$INITRD" "::initrd.img"
        echo "  ✓ Dosyalar mcopy ile kopyalandı"
    fi
fi
rmdir "$MOUNT_TMP" 2>/dev/null || true

# ZIP
echo "  Zip paketleniyor..."
cd "$DIST_DIR"
zip -j "MTOS-Limbo.zip" "$IMG" "$DIST_DIR/bzImage" "$INITRD" 2>/dev/null
echo "  ✓ ZIP: MTOS-Limbo.zip"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  BUILD TAMAM!"
echo ""
echo "  Limbo Ayarları:"
echo "  ┌─────────────────────────────────┐"
echo "  │ Architecture : x86              │"
echo "  │ CPU          : qemu32           │"
echo "  │ RAM          : 256 MB           │"
echo "  │ HDD          : mtos-limbo.img   │"
echo "  │ Kernel       : bzImage          │"
echo "  │ Initrd       : initrd.img       │"
echo "  │ Kernel cmd   : console=ttyS0    │"
echo "  └─────────────────────────────────┘"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
