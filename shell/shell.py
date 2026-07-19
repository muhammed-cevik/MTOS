#!/usr/bin/env python3
"""
MT OS Shell - Ana Kabuk
Komutlar: ls, cd, rm, mkdir, writef, edfile, lua, games, help, clear, exit
"""

import os
import sys
import shutil
import subprocess
import platform
import datetime
import readline  # ok tuşları için

MTOS_VERSION = "1.0.0"
MTOS_ROOT    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ─── Renkler ──────────────────────────────────────────────────────────────────
class C:
    RESET  = "\033[0m"
    BOLD   = "\033[1m"
    RED    = "\033[91m"
    GREEN  = "\033[92m"
    YELLOW = "\033[93m"
    BLUE   = "\033[94m"
    CYAN   = "\033[96m"
    GRAY   = "\033[90m"
    WHITE  = "\033[97m"

def ok(msg):   print(f"{C.GREEN}✓ {msg}{C.RESET}")
def err(msg):  print(f"{C.RED}✗ {msg}{C.RESET}")
def info(msg): print(f"{C.CYAN}→ {msg}{C.RESET}")
def warn(msg): print(f"{C.YELLOW}⚠ {msg}{C.RESET}")

# ─── Prompt ───────────────────────────────────────────────────────────────────
def get_prompt():
    cwd = os.getcwd()
    home = os.path.expanduser("~")
    cwd = cwd.replace(home, "~")
    return (f"{C.GREEN}{C.BOLD}mtos{C.RESET}"
            f"{C.GRAY}@{C.RESET}"
            f"{C.CYAN}kernel{C.RESET}"
            f"{C.GRAY}:{C.RESET}"
            f"{C.BLUE}{cwd}{C.RESET}"
            f"{C.YELLOW} ❯ {C.RESET}")

# ─── Komutlar ─────────────────────────────────────────────────────────────────

def cmd_ls(args):
    """Dizin içeriğini renkli listele"""
    path = args[0] if args else "."
    if not os.path.exists(path):
        err(f"ls: '{path}' bulunamadı")
        return
    entries = sorted(os.listdir(path))
    if not entries:
        warn("Dizin boş.")
        return
    for entry in entries:
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            print(f"  {C.BLUE}{C.BOLD}{entry}/{C.RESET}")
        elif os.access(full, os.X_OK):
            print(f"  {C.GREEN}{entry}*{C.RESET}")
        elif entry.endswith(('.py','.c','.h','.lua')):
            print(f"  {C.CYAN}{entry}{C.RESET}")
        else:
            print(f"  {C.WHITE}{entry}{C.RESET}")

def cmd_cd(args):
    """Dizin değiştir"""
    if not args:
        os.chdir(os.path.expanduser("~"))
        return
    target = args[0]
    try:
        os.chdir(target)
        info(f"Dizin: {os.getcwd()}")
    except FileNotFoundError:
        err(f"cd: '{target}' bulunamadı")
    except PermissionError:
        err(f"cd: '{target}' erişim reddedildi")

def cmd_mkdir(args):
    """Dizin oluştur"""
    if not args:
        err("mkdir: dizin adı gerekli")
        return
    for name in args:
        try:
            os.makedirs(name, exist_ok=True)
            ok(f"Dizin oluşturuldu: {name}")
        except PermissionError:
            err(f"mkdir: '{name}' oluşturulamadı - erişim reddedildi")

def cmd_rm(args):
    """Dosya veya dizin sil"""
    if not args:
        err("rm: dosya/dizin adı gerekli")
        return
    force = "-f" in args
    args = [a for a in args if not a.startswith("-")]
    for name in args:
        if not os.path.exists(name):
            if not force:
                err(f"rm: '{name}' bulunamadı")
            continue
        try:
            if os.path.isdir(name):
                confirm = input(f"{C.YELLOW}'{name}' dizini silinecek. Emin misin? [e/H] {C.RESET}")
                if confirm.lower() == "e":
                    shutil.rmtree(name)
                    ok(f"Dizin silindi: {name}")
                else:
                    warn("İptal edildi.")
            else:
                os.remove(name)
                ok(f"Dosya silindi: {name}")
        except PermissionError:
            err(f"rm: '{name}' silinemedi - erişim reddedildi")

def cmd_writef(args):
    """Dosyaya içerik yaz: writef <dosya> <içerik...>"""
    if len(args) < 2:
        err("writef: kullanım: writef <dosya> <içerik>")
        info("  Örnek: writef merhaba.txt Merhaba dünya!")
        return
    filename = args[0]
    content  = " ".join(args[1:])
    try:
        mode = "a" if os.path.exists(filename) else "w"
        with open(filename, mode, encoding="utf-8") as f:
            f.write(content + "\n")
        action = "eklendi" if mode == "a" else "oluşturuldu"
        ok(f"'{filename}' {action} ({len(content)} karakter)")
    except PermissionError:
        err(f"writef: '{filename}' yazılamadı - erişim reddedildi")

def cmd_edfile(args):
    """Dosyayı düzenle: edfile <dosya>"""
    if not args:
        err("edfile: dosya adı gerekli")
        return
    filename = args[0]

    # Mevcut içeriği yükle
    lines = []
    if os.path.exists(filename):
        with open(filename, "r", encoding="utf-8") as f:
            lines = f.readlines()
        info(f"'{filename}' yüklendi ({len(lines)} satır)")
    else:
        info(f"Yeni dosya: '{filename}'")

    print(f"{C.GRAY}─── MT OS Editor ── Ctrl+D veya 'SAVE' ile kaydet ───{C.RESET}")
    print(f"{C.GRAY}Komutlar: :list  :del <n>  :ins <n> <metin>  :save  :quit{C.RESET}\n")

    # Mevcut satırları göster
    if lines:
        for i, line in enumerate(lines, 1):
            print(f"{C.GRAY}{i:3}│{C.RESET} {line}", end="")
        print()

    try:
        while True:
            try:
                raw = input(f"{C.CYAN}ed❯ {C.RESET}")
            except EOFError:
                break

            if raw.strip() in (":quit", ":q"):
                warn("Kaydedilmeden çıkıldı.")
                return
            elif raw.strip() in (":save", ":s", "SAVE"):
                break
            elif raw.strip() == ":list":
                for i, line in enumerate(lines, 1):
                    print(f"{C.GRAY}{i:3}│{C.RESET} {line}", end="")
                if not lines:
                    warn("(boş)")
            elif raw.startswith(":del "):
                try:
                    n = int(raw.split()[1]) - 1
                    removed = lines.pop(n).rstrip()
                    ok(f"Satır {n+1} silindi: {removed}")
                except (IndexError, ValueError):
                    err("Geçersiz satır numarası")
            elif raw.startswith(":ins "):
                parts = raw.split(None, 2)
                if len(parts) < 3:
                    err("Kullanım: :ins <satır_no> <metin>")
                else:
                    try:
                        n = int(parts[1]) - 1
                        lines.insert(n, parts[2] + "\n")
                        ok(f"Satır {n+1}'e eklendi")
                    except ValueError:
                        err("Geçersiz satır numarası")
            else:
                lines.append(raw + "\n")
    except KeyboardInterrupt:
        warn("\nKaydedilmeden çıkıldı.")
        return

    with open(filename, "w", encoding="utf-8") as f:
        f.writelines(lines)
    ok(f"'{filename}' kaydedildi ({len(lines)} satır)")

def cmd_cat(args):
    """Dosya içeriğini göster"""
    if not args:
        err("cat: dosya adı gerekli")
        return
    for filename in args:
        if not os.path.exists(filename):
            err(f"cat: '{filename}' bulunamadı")
            continue
        print(f"{C.GRAY}─── {filename} ───{C.RESET}")
        with open(filename, "r", encoding="utf-8") as f:
            print(f.read())

def cmd_pwd(args):
    print(f"{C.CYAN}{os.getcwd()}{C.RESET}")

def cmd_echo(args):
    print(" ".join(args))

def cmd_clear(args):
    os.system("clear" if os.name != "nt" else "cls")

def cmd_whoami(args):
    print(f"{C.GREEN}{os.getenv('USER', 'mtos-user')}{C.RESET}")

def cmd_date(args):
    now = datetime.datetime.now()
    print(f"{C.CYAN}{now.strftime('%A, %d %B %Y  %H:%M:%S')}{C.RESET}")

def cmd_uname(args):
    s = platform.uname()
    print(f"{C.CYAN}{s.system} {s.node} {s.release} {s.machine}{C.RESET}")

def cmd_lua(args):
    """Lua interpreter - gerçek lua çalıştır"""
    lua_bin = shutil.which("lua") or shutil.which("lua5.4") or shutil.which("lua5.3")

    if not lua_bin:
        err("Lua bulunamadı!")
        info("Kur: sudo apt install lua5.4")
        return

    if args:
        # Dosya çalıştır
        filename = args[0]
        if not os.path.exists(filename):
            # MTOS lua dizininde ara
            lua_path = os.path.join(MTOS_ROOT, "lua", filename)
            if os.path.exists(lua_path):
                filename = lua_path
            else:
                err(f"lua: '{filename}' bulunamadı")
                return
        info(f"Lua dosyası çalıştırılıyor: {filename}")
        subprocess.run([lua_bin, filename])
    else:
        # İnteraktif Lua REPL
        info(f"Lua REPL ({lua_bin}) - Çıkmak için Ctrl+C veya os.exit()")
        print(f"{C.GRAY}MT OS Lua 5.x interpreter{C.RESET}\n")
        try:
            subprocess.run([lua_bin, "-i"])
        except KeyboardInterrupt:
            print()

def cmd_games(args):
    """Oyun menüsü"""
    games_dir = os.path.join(MTOS_ROOT, "games")
    games = {
        "1": ("Sayı Tahmin",     "guess.py"),
        "2": ("Yılan Oyunu",     "snake.py"),
        "3": ("Labirent",        "maze.py"),
        "4": ("Lua Oyunu",       "../lua/game.lua"),
    }

    if args:
        # Direkt oyun adı verilmişse
        name = args[0]
        if name.endswith(".lua"):
            cmd_lua([os.path.join(MTOS_ROOT, "lua", name)])
        else:
            path = os.path.join(games_dir, name)
            if os.path.exists(path):
                subprocess.run(["python3", path])
            else:
                err(f"Oyun bulunamadı: {name}")
        return

    print(f"\n{C.BOLD}{C.YELLOW}━━━ MT OS Oyun Merkezi ━━━{C.RESET}")
    for key, (name, _) in games.items():
        print(f"  {C.CYAN}[{key}]{C.RESET} {name}")
    print(f"  {C.CYAN}[q]{C.RESET} Çıkış\n")

    choice = input(f"{C.YELLOW}Seçim: {C.RESET}").strip()
    if choice == "q":
        return
    if choice not in games:
        err("Geçersiz seçim")
        return

    name, filename = games[choice]
    info(f"{name} başlatılıyor...")
    if filename.endswith(".lua"):
        cmd_lua([os.path.join(MTOS_ROOT, filename)])
    else:
        path = os.path.join(games_dir, filename)
        if os.path.exists(path):
            subprocess.run(["python3", path])
        else:
            err(f"Oyun dosyası bulunamadı: {path}")

def cmd_help(args):
    """Yardım menüsü"""
    print(f"\n{C.BOLD}{C.CYAN}━━━ MT OS Komutları ━━━{C.RESET}\n")
    cmds = [
        ("ls [dizin]",            "Dizin içeriğini listele"),
        ("cd <dizin>",            "Dizin değiştir"),
        ("mkdir <ad>",            "Yeni dizin oluştur"),
        ("rm [-f] <ad>",          "Dosya/dizin sil"),
        ("writef <dosya> <metin>","Dosyaya metin yaz/ekle"),
        ("edfile <dosya>",        "Dosya düzenleyici"),
        ("cat <dosya>",           "Dosya içeriğini göster"),
        ("pwd",                   "Mevcut dizini göster"),
        ("echo <metin>",          "Metin yazdır"),
        ("whoami",                "Kullanıcı adını göster"),
        ("date",                  "Tarih ve saat"),
        ("uname",                 "Sistem bilgisi"),
        ("lua [dosya.lua]",       "Lua interpreter / REPL"),
        ("games",                 "Oyun merkezi"),
        ("clear",                 "Ekranı temizle"),
        ("exit / quit",           "MT OS'dan çık"),
    ]
    for cmd, desc in cmds:
        print(f"  {C.GREEN}{cmd:<28}{C.RESET} {C.GRAY}{desc}{C.RESET}")
    print()

# ─── Komut Tablosu ────────────────────────────────────────────────────────────
COMMANDS = {
    "ls":      cmd_ls,
    "cd":      cmd_cd,
    "mkdir":   cmd_mkdir,
    "rm":      cmd_rm,
    "writef":  cmd_writef,
    "edfile":  cmd_edfile,
    "cat":     cmd_cat,
    "pwd":     cmd_pwd,
    "echo":    cmd_echo,
    "whoami":  cmd_whoami,
    "date":    cmd_date,
    "uname":   cmd_uname,
    "lua":     cmd_lua,
    "games":   cmd_games,
    "clear":   cmd_clear,
    "help":    cmd_help,
    "?":       cmd_help,
}

# ─── Ana Döngü ────────────────────────────────────────────────────────────────
def main():
    # Readline geçmişi
    history_file = os.path.join(os.path.expanduser("~"), ".mtos_history")
    try:
        readline.read_history_file(history_file)
    except FileNotFoundError:
        pass
    readline.set_history_length(500)

    while True:
        try:
            line = input(get_prompt()).strip()
        except EOFError:
            print()
            break
        except KeyboardInterrupt:
            print(f"\n{C.YELLOW}(Ctrl+C - çıkmak için 'exit' yazın){C.RESET}")
            continue

        if not line:
            continue

        parts = line.split()
        cmd   = parts[0].lower()
        args  = parts[1:]

        if cmd in ("exit", "quit", "shutdown"):
            print(f"\n{C.YELLOW}MT OS kapatılıyor...{C.RESET}")
            break
        elif cmd in COMMANDS:
            try:
                COMMANDS[cmd](args)
            except Exception as e:
                err(f"Hata: {e}")
        else:
            # Sistem komutuna dene
            try:
                result = subprocess.run(line, shell=True)
            except Exception:
                err(f"'{cmd}': komut bulunamadı. 'help' yazın.")

    readline.write_history_file(history_file)

if __name__ == "__main__":
    main()
