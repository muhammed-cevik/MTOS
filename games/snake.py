#!/usr/bin/env python3
"""MT OS - Terminal Yılan Oyunu (curses)"""
import curses, random, time

def play(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(True)
    stdscr.timeout(120)

    sh, sw = stdscr.getmaxyx()
    H, W   = sh - 2, sw - 2

    # Renkler
    curses.start_color()
    curses.init_pair(1, curses.COLOR_GREEN,  curses.COLOR_BLACK)
    curses.init_pair(2, curses.COLOR_RED,    curses.COLOR_BLACK)
    curses.init_pair(3, curses.COLOR_YELLOW, curses.COLOR_BLACK)
    curses.init_pair(4, curses.COLOR_CYAN,   curses.COLOR_BLACK)

    def new_food(snake):
        while True:
            f = [random.randint(1, H), random.randint(1, W)]
            if f not in snake:
                return f

    snake  = [[H//2, W//2], [H//2, W//2-1], [H//2, W//2-2]]
    food   = new_food(snake)
    dy, dx = 0, 1
    score  = 0
    speed  = 120

    while True:
        stdscr.clear()
        # Çerçeve
        stdscr.attron(curses.color_pair(4))
        stdscr.border()
        stdscr.addstr(0, 2, f" MT OS SNAKE | Skor: {score} | WASD/Ok tuşu ")
        stdscr.attroff(curses.color_pair(4))

        # Yılan
        for i, seg in enumerate(snake):
            ch = "█" if i == 0 else "▓"
            color = curses.color_pair(1) if i > 0 else curses.color_pair(3)
            try:
                stdscr.addstr(seg[0], seg[1], ch, color)
            except curses.error:
                pass

        # Yiyecek
        try:
            stdscr.addstr(food[0], food[1], "●", curses.color_pair(2))
        except curses.error:
            pass

        stdscr.refresh()

        # Tuş
        key = stdscr.getch()
        if key in (curses.KEY_UP,    ord('w'), ord('W')) and dy != 1:  dy,dx = -1,0
        if key in (curses.KEY_DOWN,  ord('s'), ord('S')) and dy != -1: dy,dx =  1,0
        if key in (curses.KEY_LEFT,  ord('a'), ord('A')) and dx != 1:  dy,dx =  0,-1
        if key in (curses.KEY_RIGHT, ord('d'), ord('D')) and dx != -1: dy,dx =  0, 1
        if key == ord('q'): break

        head = [snake[0][0]+dy, snake[0][1]+dx]

        # Duvar çarpışma
        if head[0] <= 0 or head[0] >= sh-1 or head[1] <= 0 or head[1] >= sw-1:
            break
        # Kendine çarpma
        if head in snake:
            break

        snake.insert(0, head)
        if head == food:
            score += 10
            food = new_food(snake)
            speed = max(50, speed - 3)
            stdscr.timeout(speed)
        else:
            snake.pop()

    # Game Over
    stdscr.clear()
    msg = f"  GAME OVER! Skor: {score}  "
    stdscr.addstr(sh//2,   (sw-len(msg))//2, "┌" + "─"*len(msg) + "┐", curses.color_pair(2))
    stdscr.addstr(sh//2+1, (sw-len(msg))//2, "│" + msg           + "│", curses.color_pair(3))
    stdscr.addstr(sh//2+2, (sw-len(msg))//2, "└" + "─"*len(msg) + "┘", curses.color_pair(2))
    stdscr.addstr(sh//2+4, (sw-18)//2, "Devam için tuşa bas...", curses.color_pair(4))
    stdscr.nodelay(False)
    stdscr.getch()

def main():
    try:
        curses.wrapper(play)
    except Exception as e:
        print(f"\033[91mYılan oyunu başlatılamadı: {e}\033[0m")
        print("\033[90mTerminal boyutunu büyüt ve tekrar dene.\033[0m")

if __name__ == "__main__":
    main()
