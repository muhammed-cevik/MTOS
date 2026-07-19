#!/usr/bin/env python3
"""MT OS - Sayı Tahmin Oyunu"""
import random, os

def clear(): os.system("clear" if os.name != "nt" else "cls")

def play():
    clear()
    print("\033[93m")
    print("  ╔══════════════════════════════╗")
    print("  ║   MT OS - SAYI TAHMİN       ║")
    print("  ╚══════════════════════════════╝")
    print("\033[0m")

    toplam_skor = 0
    tur = 1

    while True:
        sayi    = random.randint(1, 100)
        deneme  = 0
        max_den = 7
        print(f"\n\033[96mTur {tur} - 1 ile 100 arasında bir sayı tuttum!\033[0m")
        print(f"\033[90m{max_den} hakkın var.\033[0m\n")

        while deneme < max_den:
            kalan = max_den - deneme
            try:
                tahmin = int(input(f"  \033[93m[{kalan} hak] Tahminin: \033[0m"))
            except ValueError:
                print("  \033[91mSayı gir!\033[0m")
                continue
            except KeyboardInterrupt:
                print("\n\033[90mOyun sona erdi.\033[0m")
                return

            deneme += 1
            if tahmin == sayi:
                puan = (max_den - deneme + 1) * 10
                toplam_skor += puan
                print(f"\n  \033[92m✓ DOĞRU! {deneme} denemede buldun! +{puan} puan\033[0m")
                print(f"  \033[96mToplam Skor: {toplam_skor}\033[0m\n")
                break
            elif tahmin < sayi:
                print(f"  \033[94m↑ Daha BÜYÜK bir sayı dene!\033[0m")
            else:
                print(f"  \033[94m↓ Daha KÜÇÜK bir sayı dene!\033[0m")
        else:
            print(f"\n  \033[91m✗ Kaybettin! Sayı: {sayi}\033[0m")

        tur += 1
        again = input("\n  Tekrar oyna? [e/H] ").strip().lower()
        if again != "e":
            print(f"\n\033[93m  Toplam Skor: {toplam_skor} | {tur-1} tur\033[0m")
            print("\033[90m  MT OS'a geri dönüyorsun...\033[0m\n")
            break

if __name__ == "__main__":
    play()
