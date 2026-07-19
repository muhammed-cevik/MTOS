-- MT OS - Lua RPG Oyunu
-- Gerçek Lua interpreter ile çalışır

-- ─── Yardımcı Fonksiyonlar ────────────────────────────────────────────────────
local function clear()
    os.execute("clear 2>/dev/null || cls 2>/dev/null")
end

local function sleep(s)
    local t = os.clock() + s
    while os.clock() < t do end
end

local function input(prompt)
    io.write(prompt)
    io.flush()
    return io.read("*l")
end

local function rnd(min, max)
    return math.random(min, max)
end

local function center(text, width)
    width = width or 40
    local pad = math.floor((width - #text) / 2)
    return string.rep(" ", pad) .. text
end

-- ─── Oyun Verisi ──────────────────────────────────────────────────────────────
math.randomseed(os.time())

local player = {
    name   = "Kahraman",
    hp     = 100,
    max_hp = 100,
    attack = 15,
    defense= 5,
    gold   = 0,
    level  = 1,
    xp     = 0,
    xp_next= 50,
    potions= 2,
}

local enemies = {
    { name="Goblin",     hp=30,  atk=8,  def=2,  xp=15, gold=rnd(3,8)   },
    { name="İskelet",    hp=45,  atk=12, def=4,  xp=25, gold=rnd(5,12)  },
    { name="Troll",      hp=70,  atk=18, def=7,  xp=40, gold=rnd(10,20) },
    { name="Ejderha",    hp=120, atk=28, def=12, xp=80, gold=rnd(25,50) },
    { name="Lich Kral",  hp=200, atk=35, def=15, xp=150,gold=rnd(50,100)},
}

-- ─── Görsel ───────────────────────────────────────────────────────────────────
local function banner()
    clear()
    print("")
    print("  ╔══════════════════════════════════════╗")
    print("  ║         MT OS  LUA  RPG              ║")
    print("  ║     Karanlık Zindan Macerası         ║")
    print("  ╚══════════════════════════════════════╝")
    print("")
end

local function show_status()
    print(string.format("  [ %s | HP:%d/%d | ATK:%d | DEF:%d | LVL:%d | XP:%d/%d | 💰%dg | 🧪%d ]",
        player.name, player.hp, player.max_hp,
        player.attack, player.defense,
        player.level, player.xp, player.xp_next,
        player.gold, player.potions))
    print("  " .. string.rep("─", 55))
end

local function hp_bar(current, max, width)
    width = width or 20
    local filled = math.floor(current / max * width)
    local bar = "[" .. string.rep("█", filled) .. string.rep("░", width-filled) .. "]"
    return bar .. string.format(" %d/%d", current, max)
end

-- ─── Seviye Atlama ────────────────────────────────────────────────────────────
local function check_level_up()
    if player.xp >= player.xp_next then
        player.level   = player.level + 1
        player.xp      = player.xp - player.xp_next
        player.xp_next = math.floor(player.xp_next * 1.6)
        player.max_hp  = player.max_hp + 20
        player.hp      = player.max_hp
        player.attack  = player.attack + 5
        player.defense = player.defense + 2
        print("")
        print("  ✨ SEVİYE ATLANDI! → Seviye " .. player.level)
        print("  HP Max +" .. 20 .. " | ATK +" .. 5 .. " | DEF +" .. 2)
        sleep(1.5)
    end
end

-- ─── Savaş ────────────────────────────────────────────────────────────────────
local function battle(enemy_template)
    -- Düşman kopyası (her savaş taze)
    local e = {
        name   = enemy_template.name,
        hp     = enemy_template.hp,
        max_hp = enemy_template.hp,
        atk    = enemy_template.atk,
        def    = enemy_template.def,
        xp     = enemy_template.xp,
        gold   = rnd(enemy_template.gold - 2, enemy_template.gold + 3),
    }
    if e.gold < 0 then e.gold = 0 end

    clear()
    print("\n  ⚔  SAVAŞ BAŞLIYOR: " .. e.name .. "  ⚔\n")
    sleep(0.8)

    while player.hp > 0 and e.hp > 0 do
        clear()
        show_status()
        print("\n  Düşman: " .. e.name)
        print("  HP " .. hp_bar(e.hp, e.max_hp))
        print("")
        print("  [1] Saldır    [2] Güçlü Saldırı (-%25 isabet)")
        print("  [3] Savun     [4] İksir kullan (" .. player.potions .. " adet)")
        print("  [5] Kaç\n")

        local choice = input("  Seçim: ")
        local log = ""

        if choice == "1" then
            -- Normal saldırı
            local dmg = math.max(1, player.attack - rnd(0, e.def))
            e.hp = e.hp - dmg
            log = "  ➤ " .. e.name .. "'a " .. dmg .. " hasar verdin!"

        elseif choice == "2" then
            -- Güçlü saldırı (%75 isabet)
            if rnd(1,4) ~= 1 then
                local dmg = math.max(1, math.floor(player.attack * 1.8) - rnd(0, e.def))
                e.hp = e.hp - dmg
                log = "  💥 GÜÇLÜ VURUŞ! " .. dmg .. " hasar!"
            else
                log = "  ✗ Iskaladın!"
            end

        elseif choice == "3" then
            -- Savunma turu (düşman hasarı yarıya iner)
            local block = math.floor(player.defense * 1.5)
            log = "  🛡  Savunma duruşu aldın! +" .. block .. " geçici zırh."
            -- Düşman hasarı bu tur azaltılır
            local edm = math.max(1, e.atk - block - rnd(0, player.defense))
            player.hp = player.hp - edm
            print(log)
            print("  " .. e.name .. " sana " .. edm .. " hasar verdi.")
            if player.hp <= 0 then break end
            input("  [Enter] devam...")
            goto continue

        elseif choice == "4" then
            if player.potions > 0 then
                local heal = rnd(30, 50)
                player.hp = math.min(player.max_hp, player.hp + heal)
                player.potions = player.potions - 1
                log = "  🧪 İksir içtin! +" .. heal .. " HP"
            else
                log = "  ✗ İksirin yok!"
            end

        elseif choice == "5" then
            if rnd(1,3) ~= 1 then
                print("\n  🏃 Kaçmayı başardın!")
                sleep(1)
                return "escaped"
            else
                log = "  ✗ Kaçamadın!"
            end
        else
            log = "  ? Geçersiz seçim."
        end

        -- Düşman saldırısı (savaş hareketlerinde)
        if e.hp > 0 and choice ~= "3" then
            local edm = math.max(1, e.atk - rnd(0, player.defense))
            player.hp = player.hp - edm
            print(log)
            print("  " .. e.name .. " sana " .. edm .. " hasar verdi.")
        else
            print(log)
        end

        if player.hp > 0 and e.hp > 0 then
            input("  [Enter] devam...")
        end

        ::continue::
    end

    if player.hp <= 0 then
        return "dead"
    end

    -- Zafer
    clear()
    print("\n  🏆 " .. e.name .. " yenildi!")
    print("  +" .. e.xp .. " XP | +" .. e.gold .. " Altın")
    player.xp   = player.xp + e.xp
    player.gold = player.gold + e.gold
    check_level_up()
    sleep(1.2)
    return "won"
end

-- ─── Dükkan ───────────────────────────────────────────────────────────────────
local function shop()
    while true do
        clear()
        show_status()
        print("\n  🏪 KASABA DÜKKANI\n")
        print("  [1] İksir (25 altın) - HP 40 iyileştirir")
        print("  [2] Silah yükselt   (60 altın) - ATK +8")
        print("  [3] Zırh yükselt    (50 altın) - DEF +5")
        print("  [4] Çıkış\n")
        local c = input("  Seçim: ")
        if c == "1" then
            if player.gold >= 25 then
                player.gold = player.gold - 25
                player.potions = player.potions + 1
                print("  ✓ İksir alındı!")
            else print("  ✗ Yeterli altın yok!") end
        elseif c == "2" then
            if player.gold >= 60 then
                player.gold = player.gold - 60
                player.attack = player.attack + 8
                print("  ✓ Silah yükseltildi! ATK +" .. 8)
            else print("  ✗ Yeterli altın yok!") end
        elseif c == "3" then
            if player.gold >= 50 then
                player.gold = player.gold - 50
                player.defense = player.defense + 5
                print("  ✓ Zırh yükseltildi! DEF +" .. 5)
            else print("  ✗ Yeterli altın yok!") end
        elseif c == "4" then break end
        sleep(0.8)
    end
end

-- ─── Ana Oyun ─────────────────────────────────────────────────────────────────
local function main()
    banner()
    print("  Karanlık zindana adım atıyorsun...\n")
    local pname = input("  Kahraman adın: ")
    if pname and #pname > 0 then player.name = pname end

    local floor = 1
    local enemy_idx = 1

    while floor <= #enemies do
        clear()
        show_status()
        print("\n  📍 KAT " .. floor .. " - " .. enemies[floor].name .. " seni bekliyor!\n")
        print("  [1] İlerle   [2] Dükkan   [3] Dinlen (20 HP)   [4] Çıkış\n")
        local c = input("  Seçim: ")

        if c == "1" then
            local result = battle(enemies[floor])
            if result == "dead" then
                clear()
                print("\n  💀 ÖLDÜN!")
                print("  " .. floor .. ". katta, " .. enemies[floor].name .. " tarafından yenildin.")
                print("  Skor: " .. player.gold .. " altın | Seviye " .. player.level)
                break
            elseif result == "won" then
                floor = floor + 1
                if floor > #enemies then
                    clear()
                    print("\n  👑 TEBRİKLER, " .. player.name .. "!")
                    print("  Tüm zindanı temizledin!")
                    print("  Final skoru: " .. player.gold .. " altın | Seviye " .. player.level)
                    break
                end
            end

        elseif c == "2" then
            shop()
        elseif c == "3" then
            if player.gold >= 10 then
                player.hp = math.min(player.max_hp, player.hp + 20)
                player.gold = player.gold - 10
                print("  💤 Dinlendin. HP +20")
                sleep(0.8)
            else
                print("  ✗ Dinlenmek için 10 altın gerekli!")
                sleep(0.8)
            end
        elseif c == "4" then
            print("\n  Zindandan ayrılıyorsun...")
            break
        end
    end

    print("\n  MT OS Lua RPG sona erdi. MT OS shell'e dönüyorsun.\n")
end

main()
