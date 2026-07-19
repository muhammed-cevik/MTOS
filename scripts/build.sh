#!/usr/bin/env bash
# MT OS Build Script
# IMG dosyası oluşturur, ZIP'ler

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
IMG_NAME="mtos.img"
IMG_SIZE_MB=32

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MT OS Build System v1.0"
echo "  Root: $ROOT_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "$BUILD_DIR" "$DIST_DIR"

# ─── 1. C Kernel Derle ────────────────────────────────────────────────────────
echo "[1/5] C kernel derleniyor..."
gcc -o "$BUILD_DIR/mtos_kernel" "$ROOT_DIR/kernel/kernel.c" -Wall -O2 2>&1 || {
    echo "  WARN: kernel.c derlenemedi, devam ediliyor..."
}

# ─── 2. Python dosyaları kopyala ──────────────────────────────────────────────
echo "[2/5] Dosyalar kopyalanıyor..."
cp -r "$ROOT_DIR/shell"  "$BUILD_DIR/"
cp -r "$ROOT_DIR/games"  "$BUILD_DIR/"
cp -r "$ROOT_DIR/lua"    "$BUILD_DIR/"
[ -f "$ROOT_DIR/README.md" ] && cp "$ROOT_DIR/README.md" "$BUILD_DIR/"

# run.sh oluştur
cat > "$BUILD_DIR/run.sh" << 'RUNEOF'
#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MTOS_ROOT="$DIR"
if [ -f "$DIR/mtos_kernel" ]; then
    "$DIR/mtos_kernel"
else
    python3 "$DIR/shell/shell.py"
fi
RUNEOF
chmod +x "$BUILD_DIR/run.sh"

# ─── 3. IMG Dosyası Oluştur ───────────────────────────────────────────────────
echo "[3/5] IMG dosyası oluşturuluyor (${IMG_SIZE_MB}MB)..."
IMG_PATH="$DIST_DIR/$IMG_NAME"

# FAT32 IMG oluştur (mkfs.fat varsa)
dd if=/dev/zero of="$IMG_PATH" bs=1M count=$IMG_SIZE_MB status=none

if command -v mkfs.fat >/dev/null 2>&1; then
    mkfs.fat -F 32 -n "MTOS" "$IMG_PATH" >/dev/null 2>&1

    # Dosyaları IMG'ye kopyala (mtools varsa)
    if command -v mcopy >/dev/null 2>&1; then
        mcopy -i "$IMG_PATH" -s "$BUILD_DIR/"* "::"
        echo "  ✓ Dosyalar IMG'ye kopyalandı (mtools)"
    else
        # Loop mount yöntemi
        MOUNT_DIR=$(mktemp -d)
        if sudo mount -o loop,uid=$(id -u),gid=$(id -g) "$IMG_PATH" "$MOUNT_DIR" 2>/dev/null; then
            cp -r "$BUILD_DIR/"* "$MOUNT_DIR/"
            sudo umount "$MOUNT_DIR"
            echo "  ✓ Dosyalar IMG'ye mount ile kopyalandı"
        else
            echo "  INFO: Dosyalar build/ klasöründe hazır (mount yetkisi yok)"
        fi
        rmdir "$MOUNT_DIR"
    fi
else
    echo "  INFO: mkfs.fat bulunamadı, raw IMG oluşturuldu"
    # Ham IMG'nin başına build içeriğini tar olarak göm
    tar -C "$BUILD_DIR" -czf "$DIST_DIR/mtos_files.tar.gz" .
    # IMG'ye header yaz
    printf "MTOS_IMG_v1\n" | dd of="$IMG_PATH" bs=512 count=1 conv=notrunc status=none
fi

echo "  ✓ IMG: $IMG_PATH"

# ─── 4. ZIP Paketi ────────────────────────────────────────────────────────────
echo "[4/5] ZIP paketi hazırlanıyor..."
ZIP_PATH="$DIST_DIR/MTOS-release.zip"
cd "$ROOT_DIR"
zip -r "$ZIP_PATH" \
    kernel/ shell/ games/ lua/ scripts/ \
    README.md .github/ \
    -x "*.pyc" -x "__pycache__/*" -x "*.o" \
    2>/dev/null || true
# IMG'yi de ekle
cd "$DIST_DIR"
zip "$ZIP_PATH" "$IMG_NAME" 2>/dev/null || true
echo "  ✓ ZIP: $ZIP_PATH"

# ─── 5. Özet ──────────────────────────────────────────────────────────────────
echo "[5/5] Build tamamlandı!"
echo ""
echo "  📦 Çıktılar:"
ls -lh "$DIST_DIR/"
echo ""
echo "  🚀 Çalıştırmak için:"
echo "     bash $BUILD_DIR/run.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
