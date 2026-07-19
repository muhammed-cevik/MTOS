-- MT OS - Lua Test Scripti
print("Merhaba MT OS Lua Dünyası!")
print("Lua version: " .. _VERSION)

-- Temel döngü
for i = 1, 5 do
    print("Sayı: " .. i)
end

-- Fonksiyon tanımı
local function topla(a, b)
    return a + b
end
print("3 + 7 = " .. topla(3, 7))

-- Tablo
local renkler = {"kırmızı", "yeşil", "mavi"}
for i, renk in ipairs(renkler) do
    print(i .. ". " .. renk)
end
