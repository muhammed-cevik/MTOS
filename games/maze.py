#!/usr/bin/env python3
"""MT OS - Labirent Oyunu"""
import random, os, sys, tty, termios

W, H = 21, 11  # tek sayı olmalı

def generate_maze():
    maze = [["█"] * W for _ in range(H)]
    visited = [[False]*W for _ in range(H)]

    def carve(x, y):
        visited[y][x] = True
        maze[y][x] = " "
        dirs = [(0,-2),(0,2),(-2,0),(2,0)]
        random.shuffle(dirs)
        for dx, dy in dirs:
            nx, ny = x+dx, y+dy
            if 0 < nx < W and 0 < ny < H and not visited[ny][nx]:
                maze[y+dy//2][x+dx//2] = " "
                carve(nx, ny)

    carve(1, 1)
    maze[1][0] = " "           # Giriş
    maze[H-2][W-1] = " "      # Çıkış
    maze[H-2][W-2] = "★"      # Hedef
    return maze

def getch():
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == "\x1b":
            ch += sys.stdin.read(2)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
    return ch

def draw(maze, px, py, steps):
    os.system("clear")
    print("\033[93m  ╔══ MT OS LABIRENT ══╗\033[0m")
    print(f"\033[90m  Adım: {steps} | WASD/Ok tuşları | q: çıkış\033[0m\n")
    for y, row in enumerate(maze):
        line = "  "
        for x, cell in enumerate(row):
            if x == px and y == py:
                line += "\033[92m@\033[0m"
            elif cell == "█":
                line += "\033[94m█\033[0m"
            elif cell == "★":
                line += "\033[93m★\033[0m"
            else:
                line += " "
        print(line)
    print()

def main():
    maze  = generate_maze()
    px, py = 1, 1
    steps = 0

    draw(maze, px, py, steps)
    print("\033[96m  Labirenti tamamla! ★ işaretine ulaş!\033[0m")

    while True:
        ch = getch()
        nx, ny = px, py

        if ch in ("w", "W", "\x1b[A"): ny -= 1
        elif ch in ("s", "S", "\x1b[B"): ny += 1
        elif ch in ("a", "A", "\x1b[D"): nx -= 1
        elif ch in ("d", "D", "\x1b[C"): nx += 1
        elif ch in ("q", "Q", "\x03"):
            print("\033[90m\nLabirentten çıkıldı.\033[0m\n")
            return

        if 0 <= nx < W and 0 <= ny < H and maze[ny][nx] != "█":
            if maze[ny][nx] == "★":
                draw(maze, nx, ny, steps+1)
                print(f"\033[92m  ✓ TEBRİKLER! {steps+1} adımda tamamladın!\033[0m\n")
                input("  [Enter] devam et...")
                return
            px, py = nx, ny
            steps += 1
            draw(maze, px, py, steps)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\033[91mHata: {e}\033[0m")
