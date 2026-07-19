# 🖥️ MT OS — Mini Terminal İşletim Sistemi

> Python + C + Lua ile yazılmış gerçek bir terminal shell OS

[![Build Status](https://github.com/muhammed-cevik/MTOS/actions/workflows/build.yml/badge.svg)](https://github.com/muhammed-cevik/MTOS/actions)

---

## 📁 Proje Yapısı

```
MTOS/
├── kernel/
│   └── kernel.c          ← C ile yazılmış çekirdek başlatıcı
├── shell/
│   └── shell.py          ← Ana Python shell (15 komut)
├── games/
│   ├── guess.py          ← Sayı tahmin oyunu
│   ├── snake.py          ← Terminal yılan oyunu (curses)
│   └── maze.py           ← Labirent oyunu
├── lua/
│   ├── game.lua          ← Lua RPG oyunu (gerçek Lua interpreter)
│   └── hello.lua         ← Lua örnek scripti
├── scripts/
│   └── build.sh          ← IMG + ZIP build scripti
└── .github/workflows/
    └── build.yml         ← GitHub Actions CI/CD
```

---

## 🚀 Kurulum & Çalıştırma

### Gereksinimler
```bash
sudo apt install python3 lua5.4 gcc
```

### Çalıştır
```bash
# Python shell direkt
python3 shell/shell.py

# Veya C kernel üzerinden
gcc -o mtos_kernel kernel/kernel.c && ./mtos_kernel

# Build (IMG + ZIP üretir)
bash scripts/build.sh
```

---

## 💻 Komutlar

| Komut | Açıklama |
|-------|----------|
| `ls [dizin]` | Dizin içeriğini renkli listele |
| `cd <dizin>` | Dizin değiştir |
| `mkdir <ad>` | Yeni dizin oluştur |
| `rm [-f] <ad>` | Dosya/dizin sil |
| `writef <dosya> <metin>` | Dosyaya metin yaz/ekle |
| `edfile <dosya>` | Satır bazlı dosya düzenleyici |
| `cat <dosya>` | Dosya içeriğini göster |
| `pwd` | Mevcut dizini göster |
| `echo <metin>` | Metin yazdır |
| `whoami` | Kullanıcı adını göster |
| `date` | Tarih ve saat |
| `uname` | Sistem bilgisi |
| `lua [dosya.lua]` | Gerçek Lua interpreter / REPL |
| `games` | Oyun merkezi |
| `clear` | Ekranı temizle |

---

## 🎮 Oyunlar

- **Sayı Tahmin** — 1-100 arası sayıyı 7 hakkında bul
- **Snake** — Terminal yılan oyunu (WASD)
- **Labirent** — Prosedürel labirent oluşturma
- **Lua RPG** — Gerçek Lua 5.x interpreter ile çalışan zindan RPG

```bash
# Shell içinde
games          # menü
lua lua/game.lua   # Lua RPG direkt
```

---

## 🏗️ GitHub Actions

Her `push` ve `tag`'da otomatik olarak:
1. Python syntax kontrolü
2. Lua syntax kontrolü  
3. C kernel derleme
4. 32MB FAT32 `.img` oluşturma
5. `MTOS-release.zip` paketleme
6. Tag push'ta → GitHub Release oluşturma

### Release yap
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## 📄 Lisans
MIT — Muhammed Çevik
