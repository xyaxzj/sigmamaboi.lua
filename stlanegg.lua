-- ==========================================================
-- STEAL AN EGG - AUTO TRADE & GIFTING SYSTEM (SIGMA UI V4)
-- Game: Steal an Egg (Roblox)
-- Framework: Sigma UI Library - V4 Ultimate Edition
-- Features: Auto Gifting, Multi-Target Whitelist, Backpack Scanner, Filtered Trade (Multi-Rarity, Weight, Mutation), Auto Accept, Server Tab (Job ID, Uptime, Smart Deep Hop & Teleport)
-- ==========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================================
-- 👤 [KONFIGURASI PER-PLAYER / PROFIL AKUN]
-- Pengaturan otomatis disesuaikan berdasarkan Username akun yang sedang login:
-- ==========================================================
local ACCOUNT_PROFILES = {
    -- [PROFIL 1] Khusus untuk akun "szeshuro" (Receiver / Penerima)
    -- Fitur yang aktif HANYA Auto Accept Gift saja dari Whitelist
    ["szeshuro"] = {
        Role                = "Receiver (Hanya Auto Accept)",
        AutoAcceptGift      = true,             -- true = Otomatis aktifkan Auto Accept Gift
        OnlyAcceptTarget    = false,            -- false = Terima dari siapa saja | true = Hanya terima dari Whitelist
        WhitelistUsernames  = { "szeshuro" },   -- 👈 Daftar username pengirim yang diizinkan (Bisa lebih dari 1)
        AcceptDelay         = 0.1,              -- Jeda waktu sebelum respon accept (detik)
        AutoTradeLoop       = false,            -- false = Matikan trade sending
        AutoTradeFilterLoop = false,            -- false = Matikan filter trade sending
    },
    
    -- [PROFIL 2] Profil Default / Pengirim (Sender untuk akun lain / Alt)
    -- Otomatis mencari akun penerima yang ada di Whitelist dan mengirim Rarity: Divine, Eternal, Secret
    ["DEFAULT"] = {
        Role                = "Sender (Pengirim ke Whitelist)",
        TargetUsername      = "szeshuro",       -- Target default
        WhitelistUsernames  = { "szeshuro" },   -- 👈 Daftar akun target penerima (Bisa lebih dari 1, cth: { "szeshuro", "alt_receiver", "player3" })
        TargetPlayerId      = nil,              -- Diisi otomatis lewat auto-resolve
        AutoTradeLoop       = false,            -- Trade semua tool
        AutoTradeFilterLoop = true,             -- true = Langsung jalankan Trade By Filter
        DelayBetweenGifts   = 0.5,              -- Jeda antar gift (detik)
        FilterItem          = "All Items",      -- Filter jenis item
        FilterMutation      = "All Mutations",  -- Filter mutasi (Cth: "Golden", "Normal", "All Mutations")
        FilterRarity        = "Divine, Eternal, Secret", -- 👈 Multi-Rarity Filter (Divine, Eternal, Secret) atau "All Rarities"
        MinWeightInMillions = 0,                -- Minimal berat dalam JUTA kg (0 = Bebas)
        MaxWeightInMillions = 0,                -- Tanpa batas maksimal berat (0 = Bebas)
        MinIncomeInMillions = 100,              -- 👈 MINIMAL INCOME: 100 = 100 JUTA/DETIK (100M/s). Item di bawah 100M TIDAK AKAN DIKIRIM!
        MaxIncomeInMillions = 0,                -- Tanpa batas maksimal income (0 = Bebas)
        IgnoreFavorites     = false,            -- Jangan abaikan barang favorit
        OnlyFavorites       = false,            -- Jangan batasi hanya favorit
        AutoAcceptGift      = false,            -- Matikan auto accept di akun pengirim
    }
}

-- Helper Parsing Whitelist
local function ParseWhitelist(input)
    local list = {}
    if type(input) == "table" then
        for _, item in ipairs(input) do
            local s = tostring(item):gsub("%s+", "")
            if s ~= "" then
                table.insert(list, s)
            end
        end
    elseif type(input) == "string" then
        for part in string.gmatch(input, "[^,]+") do
            local s = part:gsub("%s+", "")
            if s ~= "" then
                table.insert(list, s)
            end
        end
    end
    return list
end

-- ==========================================================
-- 🔍 DETEKSI AKUN AKTIF & LOAD PROFILE
-- ==========================================================
local currentUsername = LocalPlayer and LocalPlayer.Name or ""
local activeProfile = nil

for nameKey, profileData in pairs(ACCOUNT_PROFILES) do
    if nameKey ~= "DEFAULT" and currentUsername:lower() == nameKey:lower() then
        activeProfile = profileData
        print(string.format("[StealAnEgg] Profil Khusus Terdeteksi: '%s' -> Role: %s", currentUsername, profileData.Role or "Custom"))
        break
    end
end

if not activeProfile then
    activeProfile = ACCOUNT_PROFILES["DEFAULT"] or {}
    print(string.format("[StealAnEgg] Profil Default Diterapkan untuk akun '%s' -> Role: %s", currentUsername, activeProfile.Role or "Default"))
end

local SCRIPT_CONFIG = {
    TargetPlayerId      = activeProfile.TargetPlayerId,
    TargetUsername      = activeProfile.TargetUsername or "",
    WhitelistUsernames  = ParseWhitelist(activeProfile.WhitelistUsernames or { activeProfile.TargetUsername or "szeshuro" }),
    AutoTradeLoop       = activeProfile.AutoTradeLoop or false,
    AutoTradeFilterLoop = activeProfile.AutoTradeFilterLoop or false,
    DelayBetweenGifts   = activeProfile.DelayBetweenGifts or 0.5,
    AutoAcceptGift      = activeProfile.AutoAcceptGift or false,
    OnlyAcceptTarget    = activeProfile.OnlyAcceptTarget or false,
    AcceptDelay         = activeProfile.AcceptDelay or 0.1,
    FilterItem          = activeProfile.FilterItem or "All Items",
    FilterMutation      = activeProfile.FilterMutation or "All Mutations",
    FilterRarity        = activeProfile.FilterRarity or "Divine, Eternal, Secret",
    MinWeightInMillions = activeProfile.MinWeightInMillions or 0,
    MaxWeightInMillions = activeProfile.MaxWeightInMillions or 0,
    MinIncomeInMillions = activeProfile.MinIncomeInMillions or 0,
    MaxIncomeInMillions = activeProfile.MaxIncomeInMillions or 0,
    IgnoreFavorites     = activeProfile.IgnoreFavorites == true,
    OnlyFavorites       = activeProfile.OnlyFavorites == true,
    ProfileRole         = activeProfile.Role or "Normal"
}


-- =========================================================
-- CLEANUP THREAD & UI LAMA
-- =========================================================
if getgenv().CancelStealAnEggTrade then 
    pcall(getgenv().CancelStealAnEggTrade)
end
local scriptId = tick()
-- Built-in Anti-AFK System (BAC Safe)
LocalPlayer.Idled:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end)

-- Helper Format Angka Ribuan
local function formatNumber(n)
    if not n then return "0" end
    local formatted = tostring(math.floor(n))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return formatted
end

-- Helper Format Waktu (Uptime)
local function formatUptime(seconds)
    if not seconds or seconds < 0 then return "0 Detik" end
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    if hours > 0 then
        return string.format("%d Jam %d Menit %d Detik", hours, mins, secs)
    elseif mins > 0 then
        return string.format("%d Menit %d Detik", mins, secs)
    else
        return string.format("%d Detik", secs)
    end
end

-- Helper Clipboard
local function CopyToClipboard(text)
    if setclipboard then
        setclipboard(text)
        return true
    elseif toclipboard then
        toclipboard(text)
        return true
    elseif syn and syn.write_clipboard then
        syn.write_clipboard(text)
        return true
    end
    return false
end

-- Helper Case-Insensitive Player Finder
local function FindPlayerByName(nameStr)
    if not nameStr or nameStr == "" then return nil end
    local nameLower = nameStr:lower():gsub("%s+", "")
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():gsub("%s+", "") == nameLower or p.DisplayName:lower():gsub("%s+", "") == nameLower then
            return p
        end
    end
    return nil
end


-- ==========================================================
-- 💎 [RARITY SYSTEM & GAME DIRECTORY DATABASE LOADER]
-- ==========================================================
local KNOWN_RARITIES = {
    "All Rarities",
    "Divine, Eternal, Secret",
    "Basic", "Common", "Uncommon", "Rare", "SuperRare", "Epic",
    "Legendary", "Mythic", "Mythical", "Cosmic", "Celestial",
    "Exotic", "Superior", "Transcendent", "Secret", "Eternal",
    "Divine", "BrainrotGod", "Rainbow", "Prismatic", "Exclusive",
    "Limited", "Admin"
}

local ItemRarityDatabase = {}
local isRarityLoaded = true


-- ==========================================================
-- [SECTION 1] STATE & BACKEND CONFIGURATION
-- ==========================================================

local Config = {
    TargetPlayerId      = SCRIPT_CONFIG.TargetPlayerId,
    TargetPlayerName    = SCRIPT_CONFIG.TargetUsername or "",
    WhitelistUsernames  = SCRIPT_CONFIG.WhitelistUsernames or { "szeshuro" },
    AutoTradeLoop       = SCRIPT_CONFIG.AutoTradeLoop or false,
    AutoTradeFilterLoop = SCRIPT_CONFIG.AutoTradeFilterLoop or false,
    AutoAcceptGift      = SCRIPT_CONFIG.AutoAcceptGift or false,
    OnlyAcceptTarget    = SCRIPT_CONFIG.OnlyAcceptTarget or false,
    AcceptDelay         = SCRIPT_CONFIG.AcceptDelay or 0.1,
    IgnoreFavorites     = SCRIPT_CONFIG.IgnoreFavorites,
    OnlyFavorites       = SCRIPT_CONFIG.OnlyFavorites,
    DelayBetweenGifts   = SCRIPT_CONFIG.DelayBetweenGifts or 0.5,
    FilterItem          = SCRIPT_CONFIG.FilterItem or "All Items",
    FilterMutation      = SCRIPT_CONFIG.FilterMutation or "All Mutations",
    FilterRarity        = SCRIPT_CONFIG.FilterRarity or "Divine, Eternal, Secret",
    MinWeight           = (tonumber(SCRIPT_CONFIG.MinWeightInMillions) or 0) * 1000000,
    MaxWeight           = (tonumber(SCRIPT_CONFIG.MaxWeightInMillions) or 0) * 1000000,
    MinIncome           = (tonumber(SCRIPT_CONFIG.MinIncomeInMillions) or 0) * 1000000,
    MaxIncome           = (tonumber(SCRIPT_CONFIG.MaxIncomeInMillions) or 0) * 1000000,
    SelectedInvTool     = nil,
    ProfileRole         = SCRIPT_CONFIG.ProfileRole,
    
    -- Price Rate Configuration (Harga Jual Estimasi per 100M/s)
    PriceRatePer100M        = 0,                -- 0 / Kosong = Sembunyikan harga (Hanya muncul jika diisi user)
    
    -- Manual Item Trade Configuration (Multi-Select Support)
    SelectedTradeItems      = {},               -- List opsi teks item yang dipilih
    SelectedTradeUIDs       = {},               -- Set UID item yang dipilih {[uid] = true}
    SelectedTradeItemTypes  = {},               -- Set jenis nama item yang dipilih {[name] = true}
    
    -- Auto Equip Active Asset Configuration
    AutoEquipAsset          = false,
    AutoEquipMode           = "💰 Highest Income (Best Value)",
    AutoEquipMaxAmount      = 5,                -- Jumlah asset teratas yang di-equip
    AutoEquipItem           = "All Items",      -- Filter jenis item
    AutoEquipRarities       = "All Rarities",   -- Filter rarity item
    AutoEquipMutation       = "All Mutations",  -- Filter mutasi item
    AutoEquipMinIncome      = 0,                -- Minimal pasif income
    AutoEquipMinWeight      = 0,                -- Minimal berat (kg)
    AutoEquipOnlyFavorites  = false,            -- Hanya equip item favorit
    AutoEquipDelay          = 0.35,             -- Jeda antar equip (detik)
    AutoEquipInterval       = 3.0,              -- Interval loop auto equip
    LastEquippedAssetUID    = nil,
    LastEquippedAssetName   = nil,
    
    -- Auto Sell Configuration
    AutoSellLoop            = false,
    AutoSellDelay           = 0.5,
    AutoSellRarities        = "Basic, Common, Uncommon, Rare",
    AutoSellItem            = "All Items",
    AutoSellMutation        = "All Mutations",
    AutoSellMaxIncome       = 0,
    AutoSellMaxWeight       = 0,
    AutoSellIgnoreFavorites = true,
    AutoSellProtectGodTier  = true,
    AutoSellProtectRainbow  = true
}

local TradeStats = {
    TotalSent = 0,
    SuccessCount = 0,
    FailCount = 0,
    AcceptedCount = 0,
    LastItemName = "-",
    SellCount = 0,
    LastSoldName = "-",
    EquipCount = 0,
    LastEquippedName = "-"
}

local LastGiftRequest = {
    SenderName = "-",
    SenderId = nil,
    ItemName = "-",
    RequestUID = nil,
    Time = 0
}

--- Mencari Target Player aktif dari Whitelist yang ada di server saat ini
local function GetActiveWhitelistTarget()
    -- 1. Cek semua username di Whitelist yang ada di server saat ini
    if Config.WhitelistUsernames and #Config.WhitelistUsernames > 0 then
        for _, usn in ipairs(Config.WhitelistUsernames) do
            local cleanUsn = tostring(usn):gsub("%s+", "")
            if cleanUsn ~= "" then
                local p = FindPlayerByName(cleanUsn)
                if p and p ~= LocalPlayer then
                    return p.UserId, p.Name
                end
            end
        end
    end
    
    -- 2. Cek TargetPlayerName jika ada di server
    if Config.TargetPlayerName and Config.TargetPlayerName ~= "" then
        local p = FindPlayerByName(Config.TargetPlayerName)
        if p and p ~= LocalPlayer then
            return p.UserId, p.Name
        end
    end
    
    -- 3. Fallback TargetPlayerId
    if Config.TargetPlayerId then
        return Config.TargetPlayerId, Config.TargetPlayerName
    end
    
    -- 4. Fallback resolve target pertama di Whitelist
    if Config.WhitelistUsernames and #Config.WhitelistUsernames > 0 then
        local firstUsn = tostring(Config.WhitelistUsernames[1]):gsub("%s+", "")
        if firstUsn ~= "" then
            local p = FindPlayerByName(firstUsn)
            if p then return p.UserId, p.Name end
            local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(firstUsn) end)
            if ok and id then return id, firstUsn end
        end
    end
    
    return nil, nil
end

--- Memeriksa apakah suatu player termasuk dalam Whitelist
local function IsPlayerInWhitelist(senderUsername, senderUserId)
    if not Config.OnlyAcceptTarget then return true end
    
    local sNameLower = tostring(senderUsername or ""):lower():gsub("%s+", "")
    local sId = tonumber(senderUserId)
    
    -- Cek TargetPlayerId jika diset
    if Config.TargetPlayerId and sId == tonumber(Config.TargetPlayerId) then
        return true
    end
    if Config.TargetPlayerName and Config.TargetPlayerName ~= "" and sNameLower == Config.TargetPlayerName:lower():gsub("%s+", "") then
        return true
    end
    
    -- Cek Whitelist Usernames
    if Config.WhitelistUsernames and #Config.WhitelistUsernames > 0 then
        for _, usn in ipairs(Config.WhitelistUsernames) do
            local cleanUsn = tostring(usn):lower():gsub("%s+", "")
            if cleanUsn ~= "" and (cleanUsn == sNameLower or cleanUsn == tostring(sId)) then
                return true
            end
        end
    end
    
    if (not Config.WhitelistUsernames or #Config.WhitelistUsernames == 0) and not Config.TargetPlayerId then
        return true
    end
    
    return false
end

getgenv().CancelStealAnEggTrade = function()
    Config.AutoTradeLoop = false
    Config.AutoTradeFilterLoop = false
    Config.AutoAcceptGift = false
end


-- ==========================================================
-- [SECTION 2] PURE FUNCTIONS & PROGRAMMATIC API
-- ==========================================================

local StealAnEggTrade = {}

-- ⚡ Caching Remotes untuk Eksekusi Cepat 0ms
local CachedRemotes = {
    Network = nil,
    GiftingSend = nil,
    GiftingResponse = nil,
    GiftingRequest = nil,
    SellAsset = nil,
    ActiveAssetsEquip = nil
}

local function GetNetworkFolder()
    if CachedRemotes.Network and CachedRemotes.Network.Parent then
        return CachedRemotes.Network
    end
    CachedRemotes.Network = ReplicatedStorage:FindFirstChild("Network") or ReplicatedStorage:WaitForChild("Network", 5)
    return CachedRemotes.Network
end

function StealAnEggTrade.GetGiftingRemote()
    if CachedRemotes.GiftingSend and CachedRemotes.GiftingSend.Parent then return CachedRemotes.GiftingSend end
    local net = GetNetworkFolder()
    CachedRemotes.GiftingSend = net and net:FindFirstChild("Gifting: Send Request")
    return CachedRemotes.GiftingSend
end

function StealAnEggTrade.GetGiftingResponseRemote()
    if CachedRemotes.GiftingResponse and CachedRemotes.GiftingResponse.Parent then return CachedRemotes.GiftingResponse end
    local net = GetNetworkFolder()
    CachedRemotes.GiftingResponse = net and net:FindFirstChild("Gifting: Response")
    return CachedRemotes.GiftingResponse
end

function StealAnEggTrade.GetGiftingRequestRemote()
    if CachedRemotes.GiftingRequest and CachedRemotes.GiftingRequest.Parent then return CachedRemotes.GiftingRequest end
    local net = GetNetworkFolder()
    CachedRemotes.GiftingRequest = net and net:FindFirstChild("Gifting: Request")
    return CachedRemotes.GiftingRequest
end

local function GetSellRemote()
    if CachedRemotes.SellAsset and CachedRemotes.SellAsset.Parent then return CachedRemotes.SellAsset end
    local net = GetNetworkFolder()
    CachedRemotes.SellAsset = net and (net:FindFirstChild("AssetInventory: SellAsset") or net:WaitForChild("AssetInventory: SellAsset", 3))
    return CachedRemotes.SellAsset
end

function StealAnEggTrade.GetActiveAssetsEquipRemote()
    if CachedRemotes.ActiveAssetsEquip and CachedRemotes.ActiveAssetsEquip.Parent then return CachedRemotes.ActiveAssetsEquip end
    local net = GetNetworkFolder()
    CachedRemotes.ActiveAssetsEquip = net and (net:FindFirstChild("ActiveAssets: RequestEquip") or net:WaitForChild("ActiveAssets: RequestEquip", 3))
    return CachedRemotes.ActiveAssetsEquip
end

-- Helper Ekstraksi & Parsing Berat (kg) dari Nama Item atau String Atribut
local function ExtractWeightFromName(toolName)
    if not toolName then return 0 end
    local str = tostring(toolName)
    
    -- 1. Pola pencocokan: (100k kg), [2.5M kg], 100k kg, (1,050 kg), [500k], (1.2M), dll.
    local wStr = str:match("%(([%d%.,%a]+)%s*[kK][gG]%)") 
        or str:match("%[([%d%.,%a]+)%s*[kK][gG]%]")
        or str:match("([%d%.,%a]+)%s*[kK][gG]")
        or str:match("%(([%d%.,%a]+)%)")
        or str:match("%[([%d%.,%a]+)%]")
        
    if not wStr then
        wStr = str
    end
    
    local raw = wStr:lower():gsub("%s+", ""):gsub("kg$", "")
    if raw == "" then return 0 end
    
    -- Cek suffix Triliun (T)
    if raw:find("t") then
        local num = tonumber((raw:gsub("triliun", ""):gsub("t", ""):gsub(",", ".")))
        return num and (num * 1e12) or 0
    end
    -- Cek suffix Miliar / Billion (B)
    if raw:find("b") or raw:find("miliar") or raw:find("billion") then
        local num = tonumber((raw:gsub("billion", ""):gsub("miliar", ""):gsub("b", ""):gsub(",", ".")))
        return num and (num * 1e9) or 0
    end
    -- Cek suffix Juta / Million (M / JT)
    if raw:find("m") or raw:find("juta") or raw:find("jt") or raw:find("million") then
        local num = tonumber((raw:gsub("million", ""):gsub("juta", ""):gsub("jt", ""):gsub("m", ""):gsub(",", ".")))
        return num and (num * 1e6) or 0
    end
    -- Cek suffix Ribu / Thousand (K / RB)
    if raw:find("k") or raw:find("ribu") or raw:find("rb") or raw:find("thousand") then
        local num = tonumber((raw:gsub("thousand", ""):gsub("ribu", ""):gsub("rb", ""):gsub("k", ""):gsub(",", ".")))
        return num and (num * 1e3) or 0
    end
    
    -- Angka murni dengan koma/titik ribuan (Cth: 1,070.25 atau 1.070,25 atau 250000)
    if raw:find(",") and raw:find("%.") then
        raw = raw:gsub(",", "")
    elseif raw:find(",") and not raw:find("%.") then
        if raw:match(",%d%d%d$") or raw:match(",%d%d%d,") then
            raw = raw:gsub(",", "")
        else
            raw = raw:gsub(",", ".")
        end
    end
    
    local finalNum = tonumber(raw)
    return finalNum or 0
end

local function ParseWeightValue(val, itemName)
    if type(val) == "number" and val > 0 then
        return val
    end
    if type(val) == "string" and val ~= "" then
        local extracted = ExtractWeightFromName(val)
        if extracted and extracted > 0 then
            return extracted
        end
    end
    return ExtractWeightFromName(itemName) or 0
end

-- Helper Ekstraksi & Parsing Income (PerSecond) dari String/Angka/Nama Item
local function ExtractIncomeFromString(str)
    if not str then return 0 end
    if type(str) == "number" then return str end
    local s = tostring(str):lower():gsub("%s+", "")
    -- Bersihkan simbol uang, tanda tambah, kurung, dan akhiran satuan waktu
    s = s:gsub("%$", ""):gsub("^%+", ""):gsub("/s$", ""):gsub("/detik$", ""):gsub("/sec$", "")
    
    if s == "" or s == "0" then return 0 end
    
    -- Format Triliun (T)
    if s:find("t") then
        local raw = s:gsub("triliun", ""):gsub("t", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e12) or 0
    end
    
    -- Format Miliar / Billion (B)
    if s:find("b") or s:find("miliar") or s:find("billion") then
        local raw = s:gsub("billion", ""):gsub("miliar", ""):gsub("b", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e9) or 0
    end
    
    -- Format Juta / Million (M / JT)
    if s:find("m") or s:find("juta") or s:find("jt") or s:find("million") then
        local raw = s:gsub("million", ""):gsub("juta", ""):gsub("jt", ""):gsub("m", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e6) or 0
    end
    
    -- Format Ribu / Thousand (K / RB)
    if s:find("k") or s:find("ribu") or s:find("rb") or s:find("thousand") then
        local raw = s:gsub("thousand", ""):gsub("ribu", ""):gsub("rb", ""):gsub("k", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e3) or 0
    end
    
    -- Pemisah ribuan dengan koma/titik: 1,000 atau 1.000 atau 1,000,000
    if s:find(",") and s:find("%.") then
        s = s:gsub(",", "")
    elseif s:find(",") and not s:find("%.") then
        if s:match(",%d%d%d$") or s:match(",%d%d%d,") then
            s = s:gsub(",", "")
        else
            s = s:gsub(",", ".")
        end
    elseif s:find("%.") and not s:find(",") then
        if s:match("%.%d%d%d$") or s:match("%.%d%d%d%.") then
            s = s:gsub("%.", "")
        end
    end
    
    local finalNum = tonumber(s)
    return finalNum or 0
end

local function ParseIncomeValue(val, itemName)
    if type(val) == "number" and val > 0 then
        return val
    end
    if type(val) == "string" and val ~= "" then
        local extracted = ExtractIncomeFromString(val)
        if extracted and extracted > 0 then
            return extracted
        end
    end
    if itemName then
        local incFromName = itemName:match("%+([%d%.,%a]+)/s") or itemName:match("%$([%d%.,%a]+)") or itemName:match("💰%s*([%d%.,%a]+)")
        if incFromName then
            local extracted = ExtractIncomeFromString(incFromName)
            if extracted and extracted > 0 then
                return extracted
            end
        end
    end
    return 0
end

-- Helper Format PerSecond / Income
local function formatIncome(n)
    n = tonumber(n)
    if not n or n <= 0 then return "" end
    if n >= 1e12 then
        return string.format("+%.2fT/s", n / 1e12)
    elseif n >= 1e9 then
        return string.format("+%.2fB/s", n / 1e9)
    elseif n >= 1e6 then
        return string.format("+%.2fM/s", n / 1e6)
    elseif n >= 1e3 then
        return string.format("+%.1fK/s", n / 1e3)
    else
        return string.format("+%d/s", math.floor(n))
    end
end

-- Helper Hitung & Format Estimasi Harga Jual (100M/s = 1k, pembulatan ke bawah per kelipatan 100M)
local function CalculateItemPrice(income, customRate)
    income = tonumber(income) or 0
    local rate = customRate ~= nil and tonumber(customRate) or (Config and tonumber(Config.PriceRatePer100M)) or 0
    if not rate or rate <= 0 or income < 100000000 then
        return 0, ""
    end
    
    -- Kelipatan 100 Juta (100M/s). Contoh: 290M -> 2 unit (bulatkan ke 2k)
    local units = math.floor(income / 100000000)
    local totalPrice = units * rate
    
    local priceStr = ""
    if totalPrice >= 1e6 then
        local mVal = totalPrice / 1e6
        if mVal == math.floor(mVal) then
            priceStr = string.format("%dM", math.floor(mVal))
        else
            priceStr = string.format("%.2fM", mVal)
        end
    elseif totalPrice >= 1e3 then
        local kVal = totalPrice / 1e3
        if kVal == math.floor(kVal) then
            priceStr = string.format("%dk", math.floor(kVal))
        else
            priceStr = string.format("%.1fk", kVal)
        end
    else
        priceStr = tostring(math.floor(totalPrice))
    end
    
    return totalPrice, priceStr
end

-- Helper Parsing String Input Berat (kg, k, M, B, T, titik ribuan)
local function ParseWeightInput(text)
    if not text then return 0 end
    local str = tostring(text):lower():gsub("%s+", ""):gsub("kg$", "")
    if str == "" or str == "0" or str == "bebas" or str == "none" or str == "all" or str == "semua" then
        return 0
    end
    
    -- Format Triliun (T)
    if str:find("t") then
        local raw = str:gsub("triliun", ""):gsub("t", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e12) or 0
    end
    -- Format Miliar / Billion (B)
    if str:find("b") or str:find("miliar") or str:find("billion") then
        local raw = str:gsub("billion", ""):gsub("miliar", ""):gsub("b", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e9) or 0
    end
    -- Format Juta / Million (M / JT)
    if str:find("m") or str:find("juta") or str:find("jt") or str:find("million") then
        local raw = str:gsub("million", ""):gsub("juta", ""):gsub("jt", ""):gsub("m", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e6) or 0
    end
    -- Format Ribu / Thousand (K / RB)
    if str:find("k") or str:find("ribu") or str:find("rb") or str:find("thousand") then
        local raw = str:gsub("thousand", ""):gsub("ribu", ""):gsub("rb", ""):gsub("k", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e3) or 0
    end
    
    -- Cek jika user mengetik angka lengkap dengan pemisah ribuan (Cth: 272.058 atau 272,058 atau 1,000)
    if str:find(",") and str:find("%.") then
        str = str:gsub(",", "")
    elseif str:find(",") and not str:find("%.") then
        if str:match(",%d%d%d$") or str:match(",%d%d%d,") then
            str = str:gsub(",", "")
        else
            str = str:gsub(",", ".")
        end
    elseif str:find("%.") and not str:find(",") then
        if str:match("%.%d%d%d$") or str:match("%.%d%d%d%.") then
            str = str:gsub("%.", "")
        end
    end
    
    local normalNum = tonumber(str)
    if normalNum and normalNum > 0 then
        return normalNum
    end
    
    return 0
end

-- Helper Parsing String Input Income (1B, 100M, 500k, 1000, 1,000, /s, titik ribuan)
local function ParseIncomeInput(text)
    if not text then return 0 end
    local str = tostring(text):lower():gsub("%s+", "")
    -- Bersihkan akhiran /s, /detik, /sec, simbol $ dan tanda +
    str = str:gsub("/s$", ""):gsub("/detik$", ""):gsub("/sec$", ""):gsub("%$", ""):gsub("^%+", "")
    
    if str == "" or str == "0" or str == "bebas" or str == "none" or str == "all" or str == "semua" then 
        return 0 
    end
    
    -- Format Triliun (T)
    if str:find("t") then
        local raw = str:gsub("triliun", ""):gsub("t", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e12) or 0
    end
    
    -- Format Miliar / Billion (B)
    if str:find("b") or str:find("miliar") or str:find("billion") then
        local raw = str:gsub("billion", ""):gsub("miliar", ""):gsub("b", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e9) or 0
    end
    
    -- Format Juta / Million (M / JT)
    if str:find("m") or str:find("juta") or str:find("jt") or str:find("million") then
        local raw = str:gsub("million", ""):gsub("juta", ""):gsub("jt", ""):gsub("m", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e6) or 0
    end
    
    -- Format Ribu / Thousand (K / RB)
    if str:find("k") or str:find("ribu") or str:find("rb") or str:find("thousand") then
        local raw = str:gsub("thousand", ""):gsub("ribu", ""):gsub("rb", ""):gsub("k", ""):gsub(",", ".")
        local num = tonumber(raw)
        return num and (num * 1e3) or 0
    end
    
    -- Cek jika user mengetik angka lengkap dengan pemisah ribuan (Cth: 100.000.000 atau 100,000,000 atau 1,000)
    if str:find(",") and str:find("%.") then
        str = str:gsub(",", "")
    elseif str:find(",") and not str:find("%.") then
        if str:match(",%d%d%d$") or str:match(",%d%d%d,") then
            str = str:gsub(",", "")
        else
            str = str:gsub(",", ".")
        end
    elseif str:find("%.") and not str:find(",") then
        if str:match("%.%d%d%d$") or str:match("%.%d%d%d%.") then
            str = str:gsub("%.", "")
        end
    end
    
    local normalNum = tonumber(str)
    if normalNum and normalNum > 0 then
        return normalNum
    end
    
    return 0
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 📜 LIVE SCREEN LOG & TRADE HISTORY DATA STRUCTURE
-- ═══════════════════════════════════════════════════════════════════════════
local TradeHistoryList = {}
local MAX_TRADE_LOG_ENTRIES = 100
local currentLogFilter = "Semua Log (All)"
local LOGS_PER_PAGE = 5
local currentLogPage = 1

local LiveLogStats = {
    TotalSent = 0,
    TotalSentIncome = 0,
    TotalSentWeight = 0,
    TotalSentPrice = 0,
    TotalReceived = 0,
    TotalSold = 0,
    TotalEquipped = 0,
    TotalFail = 0
}

function StealAnEggTrade.AddTradeLog(actionType, itemInfo, targetOrSenderName, extraDetail)
    local now = os.date and os.date("%X")
    if not now or now == "" then
        local t = os.time and os.time() or tick()
        local h = math.floor((t % 86400) / 3600)
        local m = math.floor((t % 3600) / 60)
        local s = math.floor(t % 60)
        now = string.format("%02d:%02d:%02d", h, m, s)
    end
    
    local entry = {
        Timestamp   = now,
        Action      = actionType or "SENT",
        Target      = targetOrSenderName or "Unknown",
        ItemName    = (type(itemInfo) == "table" and itemInfo.Name) or (type(itemInfo) == "string" and itemInfo) or "Unknown Item",
        DisplayName = (type(itemInfo) == "table" and itemInfo.DisplayName) or (type(itemInfo) == "string" and itemInfo) or "Unknown Item",
        Rarity      = (type(itemInfo) == "table" and itemInfo.Rarity) or "Normal",
        Mutation    = (type(itemInfo) == "table" and itemInfo.BaseMutation) or "Normal",
        Weight      = (type(itemInfo) == "table" and tonumber(itemInfo.Weight)) or 0,
        Income      = (type(itemInfo) == "table" and tonumber(itemInfo.PerSecond)) or 0,
        Price       = (type(itemInfo) == "table" and tonumber(itemInfo.Price)) or 0,
        UID         = (type(itemInfo) == "table" and itemInfo.UID) or "-",
        Detail      = extraDetail or ""
    }
    
    if entry.Price <= 0 and entry.Income > 0 and CalculateItemPrice then
        entry.Price = CalculateItemPrice(entry.Income, Config.PriceRatePer100M or 1000)
    end
    
    if actionType == "SENT" then
        LiveLogStats.TotalSent = LiveLogStats.TotalSent + 1
        LiveLogStats.TotalSentIncome = LiveLogStats.TotalSentIncome + entry.Income
        LiveLogStats.TotalSentWeight = LiveLogStats.TotalSentWeight + entry.Weight
        LiveLogStats.TotalSentPrice = LiveLogStats.TotalSentPrice + entry.Price
        TradeStats.TotalSent = LiveLogStats.TotalSent
        TradeStats.SuccessCount = TradeStats.SuccessCount + 1
        TradeStats.LastItemName = entry.DisplayName
    elseif actionType == "RECEIVED" then
        LiveLogStats.TotalReceived = LiveLogStats.TotalReceived + 1
        TradeStats.AcceptedCount = LiveLogStats.TotalReceived
        TradeStats.LastItemName = entry.DisplayName
    elseif actionType == "SOLD" then
        LiveLogStats.TotalSold = LiveLogStats.TotalSold + 1
        TradeStats.SellCount = LiveLogStats.TotalSold
        TradeStats.LastSoldName = entry.DisplayName
    elseif actionType == "EQUIPPED" then
        LiveLogStats.TotalEquipped = LiveLogStats.TotalEquipped + 1
        TradeStats.EquipCount = LiveLogStats.TotalEquipped
        TradeStats.LastEquippedName = entry.DisplayName
    elseif actionType == "FAIL" then
        LiveLogStats.TotalFail = LiveLogStats.TotalFail + 1
        TradeStats.FailCount = TradeStats.FailCount + 1
    end
    
    table.insert(TradeHistoryList, 1, entry)
    if #TradeHistoryList > MAX_TRADE_LOG_ENTRIES then
        table.remove(TradeHistoryList, #TradeHistoryList)
    end
    
    if StealAnEggTrade.RefreshLogScreen then
        task.defer(StealAnEggTrade.RefreshLogScreen)
    end
    
    return entry
end

local function FormatLogEntryRichText(entry)
    local actionBadge = ""
    if entry.Action == "SENT" then
        actionBadge = '<font color="#00FF88"><b>[📤 SENT]</b></font>'
    elseif entry.Action == "RECEIVED" then
        actionBadge = '<font color="#00E5FF"><b>[📥 RECEIVED]</b></font>'
    elseif entry.Action == "SOLD" then
        actionBadge = '<font color="#FFAA00"><b>[💰 SOLD]</b></font>'
    elseif entry.Action == "EQUIPPED" then
        actionBadge = '<font color="#BF55EC"><b>[⚔️ EQUIP]</b></font>'
    else
        actionBadge = '<font color="#FF4444"><b>[❌ FAIL]</b></font>'
    end
    
    local rBadge = GetRarityBadge(entry.Rarity)
    local mBadge = GetMutationBadge(entry.Mutation)
    local incStr = entry.Income > 0 and formatIncome(entry.Income) or "-"
    local wStr = entry.Weight > 0 and (formatNumber(entry.Weight) .. " kg") or "-"
    local priceStr = entry.Price > 0 and formatNumber(entry.Price) or "-"
    local targetLabel = (entry.Action == "RECEIVED" and "Dari: @" or "Ke: @") .. tostring(entry.Target)
    
    local lines = {}
    table.insert(lines, string.format("<b>[%s]</b> %s ➔ <b>%s</b>", entry.Timestamp, actionBadge, targetLabel))
    table.insert(lines, string.format("%s <b>%s</b> %s", rBadge, entry.DisplayName, mBadge))
    
    local metrics = {}
    if entry.Weight > 0 then
        table.insert(metrics, string.format("<font color=\"#00E5FF\">⚖️ %s</font>", wStr))
    end
    if entry.Income > 0 then
        table.insert(metrics, string.format("<font color=\"#00FF88\"><b>💰 %s</b></font>", incStr))
    end
    if entry.Price > 0 then
        table.insert(metrics, string.format("<font color=\"#FFD700\"><b>🏷️ %s</b></font>", priceStr))
    end
    
    if #metrics > 0 then
        table.insert(lines, "├ " .. table.concat(metrics, "  •  "))
    end
    
    if entry.UID and entry.UID ~= "-" and entry.UID ~= "" then
        local shortUid = entry.UID:sub(1, 8) .. "..."
        table.insert(lines, string.format("└ <font color=\"#888888\">🆔 %s</font>", shortUid))
    else
        table.insert(lines, "└ <font color=\"#00FF88\">Status: Sukses Diproses</font>")
    end
    
    return table.concat(lines, "\n")
end

-- Blacklist Tool yang dikecualikan dari scan / trade (Bat dan Trap)
local IGNORED_TOOL_PATTERNS = { "bat", "trap" }

local function IsIgnoredTool(tool)
    if not tool or not tool:IsA("Tool") then return true end
    local nameLower = tool.Name:lower()
    for _, pattern in ipairs(IGNORED_TOOL_PATTERNS) do
        if nameLower:find(pattern, 1, true) then
            return true
        end
    end
    
    local cfg = tool:FindFirstChild("Configuration") or tool:FindFirstChild("Config") or tool:FindFirstChild("Settings")
    if cfg then
        local disp = cfg:GetAttribute("displayName") or cfg:GetAttribute("DisplayName")
        if disp then
            local dispLower = tostring(disp):lower()
            for _, pattern in ipairs(IGNORED_TOOL_PATTERNS) do
                if dispLower:find(pattern, 1, true) then
                    return true
                end
            end
        end
        local cat = cfg:GetAttribute("category") or cfg:GetAttribute("Category")
        if cat then
            local catLower = tostring(cat):lower()
            for _, pattern in ipairs(IGNORED_TOOL_PATTERNS) do
                if catLower:find(pattern, 1, true) then
                    return true
                end
            end
        end
    end
    
    local toolDisp = tool:GetAttribute("DisplayName")
    if toolDisp then
        local toolDispLower = tostring(toolDisp):lower()
        for _, pattern in ipairs(IGNORED_TOOL_PATTERNS) do
            if toolDispLower:find(pattern, 1, true) then
                return true
            end
        end
    end
    
    return false
end

-- ==========================================================
-- 👑 RARITY & MUTATION HIERARCHY RANKINGS
-- ==========================================================
local RARITY_RANK = {
    ["admin"] = 100,
    ["exclusive"] = 95,
    ["limited"] = 90,
    ["brainrotgod"] = 85,
    ["prismatic"] = 80,
    ["divine"] = 75,
    ["eternal"] = 70,
    ["secret"] = 65,
    ["transcendent"] = 60,
    ["superior"] = 55,
    ["exotic"] = 50,
    ["celestial"] = 45,
    ["cosmic"] = 40,
    ["mythical"] = 35,
    ["mythic"] = 35,
    ["legendary"] = 30,
    ["epic"] = 25,
    ["superrare"] = 20,
    ["rare"] = 15,
    ["uncommon"] = 10,
    ["common"] = 5,
    ["basic"] = 2,
    ["normal"] = 1
}

local MUTATION_RANK = {
    ["rainbow"] = 10,
    ["void"] = 9,
    ["diamond"] = 8,
    ["dark"] = 7,
    ["golden"] = 6,
    ["shiny"] = 5,
    ["normal"] = 1
}

local function GetRarityRank(rStr)
    if not rStr then return 0 end
    local rClean = tostring(rStr):lower():gsub("%s+", "")
    return RARITY_RANK[rClean] or 1
end

local function GetMutationRank(mStr)
    if not mStr then return 0 end
    local mClean = tostring(mStr):lower():gsub("%s+", "")
    return MUTATION_RANK[mClean] or 1
end

local function GetRarityBadge(rStr)
    local r = tostring(rStr or ""):lower()
    if r:find("divine") or r:find("god") then
        return "👑 " .. tostring(rStr)
    elseif r:find("eternal") or r:find("transcendent") then
        return "🔥 " .. tostring(rStr)
    elseif r:find("secret") or r:find("cosmic") or r:find("celestial") then
        return "🌌 " .. tostring(rStr)
    elseif r:find("mythic") then
        return "🔮 " .. tostring(rStr)
    elseif r:find("legend") then
        return "⚡ " .. tostring(rStr)
    elseif r:find("epic") or r:find("super") then
        return "💎 " .. tostring(rStr)
    elseif r:find("rare") then
        return "🔷 " .. tostring(rStr)
    else
        return tostring(rStr)
    end
end

local function GetMutationBadge(mStr)
    local m = tostring(mStr or ""):lower()
    if m:find("rainbow") then
        return "🌈 " .. tostring(mStr)
    elseif m:find("golden") then
        return "✨ " .. tostring(mStr)
    elseif m:find("dark") or m:find("void") then
        return "🌑 " .. tostring(mStr)
    elseif m:find("diamond") then
        return "💎 " .. tostring(mStr)
    elseif m:find("shiny") then
        return "🌟 " .. tostring(mStr)
    else
        return tostring(mStr)
    end
end

function StealAnEggTrade.GetToolRarity(tool)
    if not tool or not tool:IsA("Tool") then return "Normal" end
    
    -- 1. Cek dari objek Configuration (game structure: Configuration.rarity)
    local cfg = tool:FindFirstChild("Configuration") or tool:FindFirstChild("Config") or tool:FindFirstChild("Settings")
    if cfg then
        local rAttr = cfg:GetAttribute("rarity") or cfg:GetAttribute("Rarity") or cfg:GetAttribute("Tier")
        if rAttr and tostring(rAttr) ~= "" and tostring(rAttr) ~= "nil" then
            return tostring(rAttr)
        end
        local rVal = cfg:FindFirstChild("Rarity") or cfg:FindFirstChild("rarity") or cfg:FindFirstChild("Tier")
        if rVal and rVal:IsA("ValueBase") and rVal.Value ~= "" then
            return tostring(rVal.Value)
        end
    end
    
    -- 2. Cek attribute langsung pada Tool
    local attrRarity = tool:GetAttribute("Rarity") or tool:GetAttribute("rarity") or tool:GetAttribute("Tier") or tool:GetAttribute("ItemRarity") or tool:GetAttribute("RarityName")
    if attrRarity and tostring(attrRarity) ~= "" and tostring(attrRarity) ~= "nil" then
        return tostring(attrRarity)
    end
    
    local rVal = tool:FindFirstChild("Rarity") or tool:FindFirstChild("Tier")
    if rVal and rVal:IsA("ValueBase") and rVal.Value ~= "" then
        return tostring(rVal.Value)
    end
    
    -- 3. Cek Database berdasarkan displayName / nama tool
    local rawName = tool.Name
    local dispName = cfg and (cfg:GetAttribute("displayName") or cfg:GetAttribute("DisplayName")) or tool:GetAttribute("DisplayName") or rawName
    dispName = tostring(dispName):lower()
    local category = tostring(tool:GetAttribute("Category") or ""):lower()
    
    local cleanName = rawName:gsub("%s*%b()", ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    local baseName = cleanName:gsub("golden%s+", ""):gsub("rainbow%s+", ""):gsub("shiny%s+", ""):gsub("dark%s+", ""):gsub("void%s+", ""):gsub("diamond%s+", "")
    
    if dispName ~= "" and ItemRarityDatabase[dispName] then
        return ItemRarityDatabase[dispName]
    end
    if category ~= "" and ItemRarityDatabase[category] then
        return ItemRarityDatabase[category]
    end
    if ItemRarityDatabase[cleanName] then
        return ItemRarityDatabase[cleanName]
    end
    if ItemRarityDatabase[baseName] then
        return ItemRarityDatabase[baseName]
    end
    if ItemRarityDatabase[rawName:lower()] then
        return ItemRarityDatabase[rawName:lower()]
    end
    
    -- 4. Fallback pencocokan string nama
    for _, r in ipairs(KNOWN_RARITIES) do
        if r ~= "All Rarities" and not r:find(",") then
            local rLow = r:lower()
            if rawName:lower():find(rLow, 1, true) or dispName:find(rLow, 1, true) then
                return r
            end
        end
    end
    
    return "Normal"
end

function StealAnEggTrade.EquipTool(tool)
    if not tool or not tool:IsA("Tool") then 
        return false, "Objek yang diberikan bukan Item yang valid" 
    end
    
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if tool.Parent == character then
        return true, "Item sudah aktif di tangan"
    end
    
    if humanoid then
        humanoid:UnequipTools()
        task.wait(0.08)
    end
    
    if humanoid and tool.Parent == LocalPlayer:FindFirstChild("Backpack") then
        humanoid:EquipTool(tool)
    else
        tool.Parent = character
    end
    
    local startT = tick()
    while tool.Parent ~= character and (tick() - startT) < 1.0 do
        task.wait(0.05)
    end
    
    if tool.Parent == character then
        task.wait(0.2)
        return true, "Item berhasil dipegang"
    else
        tool.Parent = character
        task.wait(0.2)
        return tool.Parent == character, "Item force-parented"
    end
end

-- ⚡ Cache Objek Tool Info (Weak Table untuk Mencegah Memory Leak & Re-evaluasi Berulang)
local ToolInfoCache = setmetatable({}, { __mode = "k" })

function StealAnEggTrade.GetToolInfo(tool)
    if not tool or not tool:IsA("Tool") or IsIgnoredTool(tool) then return nil end
    
    local cached = ToolInfoCache[tool]
    if cached and cached.Instance == tool and tool.Parent ~= nil then
        return cached
    end
    
    local name = tool.Name
    local cfg = tool:FindFirstChild("Configuration") or tool:FindFirstChild("Config") or tool:FindFirstChild("Settings")
    
    -- Display Name (Cth: "Unicorn", "El Maja")
    local dispName = cfg and (cfg:GetAttribute("displayName") or cfg:GetAttribute("DisplayName"))
        or tool:GetAttribute("DisplayName")
        or name:gsub("%s*%b()", ""):gsub("^%s+", ""):gsub("%s+$", "")
        
    -- Mutation (Cth: "Rainbow", "Golden", "Normal")
    local baseMutation = cfg and (cfg:GetAttribute("baseMutation") or cfg:GetAttribute("mutations") or cfg:GetAttribute("BaseMutation"))
        or tool:GetAttribute("BaseMutation") 
        or tool:GetAttribute("Mutations")
        
    if not baseMutation or tostring(baseMutation) == "" then
        local lowerName = name:lower()
        if lowerName:find("rainbow") then
            baseMutation = "Rainbow"
        elseif lowerName:find("golden") then
            baseMutation = "Golden"
        elseif lowerName:find("shiny") then
            baseMutation = "Shiny"
        elseif lowerName:find("dark") then
            baseMutation = "Dark"
        elseif lowerName:find("void") then
            baseMutation = "Void"
        elseif lowerName:find("diamond") then
            baseMutation = "Diamond"
        else
            baseMutation = "Normal"
        end
    end
    
    -- Weight (Cth: 1070.25 kg, 250481 kg, 100k kg, 2.5M kg)
    local rawWeight = tool:GetAttribute("Weight")
        or tool:GetAttribute("weight")
        or tool:GetAttribute("EggWeight")
        or tool:GetAttribute("PetWeight")
        or (cfg and (cfg:GetAttribute("weight") or cfg:GetAttribute("Weight") or cfg:GetAttribute("baseWeight") or cfg:GetAttribute("BaseWeight")))
        or (tool:FindFirstChild("Weight") and tool.Weight.Value)
        or (cfg and cfg:FindFirstChild("Weight") and cfg.Weight.Value)
        
    local weight = ParseWeightValue(rawWeight, name)
        
    -- PerSecond / Income (Deep Attribute & Value Check dengan Multi-Format Parser)
    local rawIncome = nil
    if cfg then
        rawIncome = cfg:GetAttribute("perSecondDisplay") 
            or cfg:GetAttribute("perSecond") 
            or cfg:GetAttribute("PerSecond") 
            or cfg:GetAttribute("Income") 
            or cfg:GetAttribute("income")
            or (cfg:FindFirstChild("perSecond") and cfg.perSecond.Value)
            or (cfg:FindFirstChild("PerSecond") and cfg.PerSecond.Value)
            or (cfg:FindFirstChild("Income") and cfg.Income.Value)
    end
    if not rawIncome or rawIncome == 0 or rawIncome == "" then
        rawIncome = tool:GetAttribute("perSecondDisplay") 
            or tool:GetAttribute("perSecond") 
            or tool:GetAttribute("PerSecond") 
            or tool:GetAttribute("Income") 
            or tool:GetAttribute("income") 
            or (tool:FindFirstChild("perSecond") and tool.perSecond.Value)
            or (tool:FindFirstChild("PerSecond") and tool.PerSecond.Value)
            or (tool:FindFirstChild("Income") and tool.Income.Value)
    end
    local perSecond = ParseIncomeValue(rawIncome, name)
    
    -- Rarity (Cth: "Divine", "Eternal", "Secret", "Mythical")
    local rarity = StealAnEggTrade.GetToolRarity(tool)
    local rarityRank = GetRarityRank(rarity)
    local mutationRank = GetMutationRank(baseMutation)
    
    -- Category, UID, Favorite, Scale
    local category = tool:GetAttribute("Category") or dispName
    local uid = tool:GetAttribute("UID") 
        or tool:GetAttribute("UUID")
        or tool:GetAttribute("uid")
        or tool:GetAttribute("uuid")
        or tool:GetAttribute("AssetId")
        or (cfg and (cfg:GetAttribute("UID") or cfg:GetAttribute("UUID") or cfg:GetAttribute("uid") or cfg:GetAttribute("uuid") or cfg:GetAttribute("AssetId") or cfg:GetAttribute("id")))
        or (tool:FindFirstChild("UID") and tool.UID.Value)
        or (cfg and cfg:FindFirstChild("UID") and cfg.UID.Value)
        or name:match("([a-f0-9]{32})")
        or name:match("([%a%d]+%-[%a%d]+%-[%a%d]+%-[%a%d]+%-[%a%d]+)")
        or "-"
    local fav = tool:GetAttribute("Favorite") == true or (cfg and cfg:GetAttribute("Favorite") == true)
    local itemType = tool:GetAttribute("ItemType") or "Asset"
    local scale = (cfg and (cfg:GetAttribute("scale") or cfg:GetAttribute("Scale"))) 
        or tool:GetAttribute("Scale") 
        or tool:GetAttribute("scale") 
        or 1
    scale = tonumber(scale) or 1
    local eyeColor = cfg and cfg:GetAttribute("eyeColor") or nil
    local colorSeed = cfg and cfg:GetAttribute("colorSeed") or nil
    
    -- ⚖️ Hitung Berat Nyata/Display Game (Rumus Game: Berat Tampil = Base Weight * Scale^2)
    local displayWeight = weight
    if scale > 0 and scale ~= 1 and weight > 0 then
        displayWeight = weight * (scale ^ 2)
    end
    
    local rBadge = GetRarityBadge(rarity)
    local mBadge = GetMutationBadge(baseMutation)
    local incomeText = formatIncome(perSecond)
    local weightText = formatNumber(displayWeight)
    
    local namePart = (baseMutation ~= "Normal" and baseMutation ~= "") 
        and string.format("[%s] %s [%s]", rBadge, tostring(dispName), mBadge)
        or string.format("[%s] %s", rBadge, tostring(dispName))
        
    local parts = {
        namePart,
        string.format("⚖️ %s kg", weightText)
    }
    if incomeText ~= "" then
        table.insert(parts, string.format("💰 %s", incomeText))
    end
    local optStr = table.concat(parts, " • ")
    if fav then
        optStr = optStr .. " ⭐"
    end
    
    local info = {
        Instance = tool,
        Name = name,
        DisplayName = tostring(dispName),
        BaseMutation = tostring(baseMutation),
        Weight = tonumber(displayWeight) or 0,
        BaseWeight = tonumber(weight) or 0,
        PerSecond = tonumber(perSecond) or 0,
        Category = tostring(category),
        UID = tostring(uid),
        Favorite = fav,
        ItemType = tostring(itemType),
        Rarity = tostring(rarity),
        RarityRank = rarityRank,
        MutationRank = mutationRank,
        Scale = tonumber(scale) or 1,
        EyeColor = eyeColor,
        ColorSeed = colorSeed,
        OptionString = optStr
    }
    
    ToolInfoCache[tool] = info
    return info
end

function StealAnEggTrade.GetAllTools()
    local tools = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and not IsIgnoredTool(item) then
                table.insert(tools, item)
            end
        end
    end
    
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") and not IsIgnoredTool(item) then
                table.insert(tools, item)
            end
        end
    end
    
    return tools
end

local INVENTORY_SORT_OPTIONS = {
    "👑 Rarity (Highest ➔ Lowest)",
    "📉 Rarity (Lowest ➔ Highest)",
    "💰 Income/s (Highest ➔ Lowest)",
    "📉 Income/s (Lowest ➔ Highest)",
    "⚖️ Weight (Heaviest ➔ Lightest)",
    "📉 Weight (Lightest ➔ Heaviest)",
    "🌈 Rarest Mutation",
    "⭐ Favorites First",
    "🔤 Name (A ➔ Z)",
    "🔤 Name (Z ➔ A)"
}

local currentInventorySort = INVENTORY_SORT_OPTIONS[1]
local currentInventorySearch = ""
local currentInventoryMinIncome = 0

function StealAnEggTrade.ScanInventory(sortMethod, searchKeyword, minIncome)
    sortMethod = sortMethod or currentInventorySort
    searchKeyword = (searchKeyword or currentInventorySearch or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    minIncome = minIncome ~= nil and tonumber(minIncome) or currentInventoryMinIncome or 0
    
    local tools = StealAnEggTrade.GetAllTools()
    local toolDataList = {}
    local itemsByName = {}
    local uniqueNames = {"All Items"}
    local mutations = {"All Mutations"}
    local rarities = {"All Rarities", "Divine, Eternal, Secret"}
    local mutationSet = {}
    local raritySet = { ["Divine, Eternal, Secret"] = true }
    local totalWeight = 0
    local totalIncome = 0
    local totalPrice = 0
    local favoriteCount = 0
    local bestPet = nil
    local heaviestPet = nil
    
    for _, tool in ipairs(tools) do
        local info = StealAnEggTrade.GetToolInfo(tool)
        if info then
            totalWeight = totalWeight + info.Weight
            totalIncome = totalIncome + info.PerSecond
            local itemPrice, _ = CalculateItemPrice(info.PerSecond, Config.PriceRatePer100M)
            totalPrice = totalPrice + (itemPrice or 0)
            if info.Favorite then
                favoriteCount = favoriteCount + 1
            end
            
            -- 1. Item Value Tertinggi (Income / PerSecond Paling Gede)
            if not bestValuePet or info.PerSecond > bestValuePet.PerSecond or (info.PerSecond == bestValuePet.PerSecond and info.RarityRank > bestValuePet.RarityRank) or (info.PerSecond == bestValuePet.PerSecond and info.RarityRank == bestValuePet.RarityRank and info.Weight > bestValuePet.Weight) then
                bestValuePet = info
            end
            
            -- 2. Item Tier Tertinggi (Berdasarkan Rarity Rank)
            if not bestPet or info.RarityRank > bestPet.RarityRank or (info.RarityRank == bestPet.RarityRank and info.PerSecond > bestPet.PerSecond) then
                bestPet = info
            end
            
            -- 3. Item Terberat
            if not heaviestPet or info.Weight > heaviestPet.Weight then
                heaviestPet = info
            end
            
            local groupKey = info.DisplayName
            if not itemsByName[groupKey] then
                itemsByName[groupKey] = {
                    Count = 0,
                    Items = {}
                }
                table.insert(uniqueNames, groupKey)
            end
            itemsByName[groupKey].Count = itemsByName[groupKey].Count + 1
            table.insert(itemsByName[groupKey].Items, tool)
            
            if info.BaseMutation and not mutationSet[info.BaseMutation] then
                mutationSet[info.BaseMutation] = true
                table.insert(mutations, info.BaseMutation)
            end
            
            if info.Rarity and not raritySet[info.Rarity] then
                raritySet[info.Rarity] = true
                table.insert(rarities, info.Rarity)
            end
            
            -- Filter Pencarian & Min Income
            local passesMinIncome = true
            if minIncome > 0 and info.PerSecond < minIncome then
                passesMinIncome = false
            end
            
            local matchesSearch = true
            if searchKeyword ~= "" then
                local matchName = info.DisplayName:lower():find(searchKeyword, 1, true) ~= nil
                local matchRarity = info.Rarity:lower():find(searchKeyword, 1, true) ~= nil
                local matchMut = info.BaseMutation:lower():find(searchKeyword, 1, true) ~= nil
                local matchRaw = info.Name:lower():find(searchKeyword, 1, true) ~= nil
                matchesSearch = matchName or matchRarity or matchMut or matchRaw
            end
            
            if passesMinIncome and matchesSearch then
                table.insert(toolDataList, info)
            end
        end
    end
    
    table.sort(toolDataList, function(a, b)
        if sortMethod == "👑 Rarity (Highest ➔ Lowest)" then
            if a.RarityRank ~= b.RarityRank then return a.RarityRank > b.RarityRank end
            if a.PerSecond ~= b.PerSecond then return a.PerSecond > b.PerSecond end
            return a.Weight > b.Weight
        elseif sortMethod == "📉 Rarity (Lowest ➔ Highest)" then
            if a.RarityRank ~= b.RarityRank then return a.RarityRank < b.RarityRank end
            return a.Weight < b.Weight
        elseif sortMethod == "💰 Income/s (Highest ➔ Lowest)" then
            if a.PerSecond ~= b.PerSecond then return a.PerSecond > b.PerSecond end
            return a.RarityRank > b.RarityRank
        elseif sortMethod == "📉 Income/s (Lowest ➔ Highest)" then
            if a.PerSecond ~= b.PerSecond then return a.PerSecond < b.PerSecond end
            return a.Weight < b.Weight
        elseif sortMethod == "⚖️ Weight (Heaviest ➔ Lightest)" then
            if a.Weight ~= b.Weight then return a.Weight > b.Weight end
            return a.RarityRank > b.RarityRank
        elseif sortMethod == "📉 Weight (Lightest ➔ Heaviest)" then
            if a.Weight ~= b.Weight then return a.Weight < b.Weight end
            return a.RarityRank < b.RarityRank
        elseif sortMethod == "🌈 Rarest Mutation" then
            if a.MutationRank ~= b.MutationRank then return a.MutationRank > b.MutationRank end
            return a.RarityRank > b.RarityRank
        elseif sortMethod == "⭐ Favorites First" then
            if a.Favorite ~= b.Favorite then return a.Favorite == true end
            return a.RarityRank > b.RarityRank
        elseif sortMethod == "🔤 Name (A ➔ Z)" then
            return a.DisplayName:lower() < b.DisplayName:lower()
        elseif sortMethod == "🔤 Name (Z ➔ A)" then
            return a.DisplayName:lower() > b.DisplayName:lower()
        else
            if a.RarityRank ~= b.RarityRank then return a.RarityRank > b.RarityRank end
            return a.Weight > b.Weight
        end
    end)
    
    local dropdownOptions = {}
    for _, info in ipairs(toolDataList) do
        table.insert(dropdownOptions, info.OptionString)
    end
    
    for _, r in ipairs(KNOWN_RARITIES) do
        if not raritySet[r] and r ~= "All Rarities" then
            table.insert(rarities, r)
        end
    end
    
    if #dropdownOptions == 0 then
        table.insert(dropdownOptions, searchKeyword ~= "" and "Tidak ada item yang cocok dengan pencarian" or "Backpack Kosong")
    end
    
    return {
        Tools = tools,
        FilteredTools = toolDataList,
        Count = #tools,
        FilteredCount = #toolDataList,
        ItemsByName = itemsByName,
        UniqueNames = uniqueNames,
        Mutations = mutations,
        Rarities = rarities,
        TotalWeight = totalWeight,
        TotalIncome = totalIncome,
        TotalPrice = totalPrice,
        FavoriteCount = favoriteCount,
        BestValuePet = bestValuePet or bestPet,
        BestPet = bestValuePet or bestPet,
        BestTierPet = bestPet,
        HeaviestPet = heaviestPet,
        DropdownOptions = dropdownOptions
    }
end

-- ⚡ Fast O(1) Set-Based Multi-Rarity Matching Cache
local RaritySetCache = {}
local function GetRaritySet(filterRarity)
    if not filterRarity or filterRarity == "All Rarities" or filterRarity == "All" or filterRarity == "" then
        return nil
    end
    
    local key = type(filterRarity) == "table" and table.concat(filterRarity, ",") or tostring(filterRarity)
    if RaritySetCache[key] then
        return RaritySetCache[key]
    end
    
    local set = {}
    if type(filterRarity) == "table" then
        for _, r in ipairs(filterRarity) do
            local clean = tostring(r):lower():gsub("%s+", "")
            if clean ~= "" then set[clean] = true end
        end
    else
        for part in string.gmatch(tostring(filterRarity):lower(), "[^,]+") do
            local clean = part:gsub("%s+", "")
            if clean ~= "" then set[clean] = true end
        end
    end
    RaritySetCache[key] = set
    return set
end

local function CheckRarityMatch(itemRarity, filterRarity)
    local set = GetRaritySet(filterRarity)
    if not set then return true end
    local iClean = tostring(itemRarity or ""):lower():gsub("%s+", "")
    return set[iClean] == true
end

function StealAnEggTrade.MatchesFilter(tool, filterConfig)
    filterConfig = filterConfig or Config
    if not tool or not tool:IsA("Tool") or IsIgnoredTool(tool) then return false end
    local info = StealAnEggTrade.GetToolInfo(tool)
    if not info then return false end
    
    if filterConfig.IgnoreFavorites and info.Favorite then
        return false
    end
    if filterConfig.OnlyFavorites and not info.Favorite then
        return false
    end
    
    -- 1. Filter Multi-Select Item Spesifik (Berdasarkan UID yang Dicentang di Dropdown)
    if filterConfig.SelectedTradeUIDs and next(filterConfig.SelectedTradeUIDs) ~= nil then
        if not filterConfig.SelectedTradeUIDs[info.UID] then
            return false
        end
    end
    
    -- 2. Filter Multi-Select Jenis/Nama Item
    if filterConfig.SelectedTradeItemTypes and next(filterConfig.SelectedTradeItemTypes) ~= nil then
        local dispLower = info.DisplayName:lower()
        local nameLower = info.Name:lower()
        local matchedType = false
        for tName, _ in pairs(filterConfig.SelectedTradeItemTypes) do
            if tName == "All Items" or dispLower:find(tName:lower(), 1, true) or nameLower:find(tName:lower(), 1, true) then
                matchedType = true
                break
            end
        end
        if not matchedType then
            return false
        end
    elseif filterConfig.FilterItem and filterConfig.FilterItem ~= "All Items" and filterConfig.FilterItem ~= "" then
        local targetName = filterConfig.FilterItem:lower()
        local matchesName = info.Name:lower():find(targetName, 1, true) ~= nil
        local matchesDisp = info.DisplayName:lower():find(targetName, 1, true) ~= nil
        local matchesCat = info.Category:lower():find(targetName, 1, true) ~= nil
        if not matchesName and not matchesDisp and not matchesCat then
            return false
        end
    end
    
    if filterConfig.FilterMutation and filterConfig.FilterMutation ~= "All Mutations" and filterConfig.FilterMutation ~= "All" then
        if info.BaseMutation:lower() ~= filterConfig.FilterMutation:lower() then
            return false
        end
    end
    
    if not CheckRarityMatch(info.Rarity, filterConfig.FilterRarity) then
        return false
    end
    
    if filterConfig.MinWeight and filterConfig.MinWeight > 0 then
        if info.Weight < filterConfig.MinWeight then
            return false
        end
    end
    
    if filterConfig.MaxWeight and filterConfig.MaxWeight > 0 then
        if info.Weight > filterConfig.MaxWeight then
            return false
        end
    end
    
    if filterConfig.MinIncome and filterConfig.MinIncome > 0 then
        if info.PerSecond < filterConfig.MinIncome then
            return false
        end
    end
    
    if filterConfig.MaxIncome and filterConfig.MaxIncome > 0 then
        if info.PerSecond > filterConfig.MaxIncome then
            return false
        end
    end
    
    return true, info
end

-- Helper Menunggu Tool Berpindah Tangan (Hilang dari Inventaris & Karakter)
local function WaitForToolTransferred(tool, maxWaitSeconds)
    maxWaitSeconds = maxWaitSeconds or 6.0
    local startTime = tick()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    
    while (tick() - startTime) < maxWaitSeconds do
        if not tool or not tool.Parent or tool.Parent == nil then
            return true
        end
        
        local inBackpack = backpack and tool:IsDescendantOf(backpack)
        local inCharacter = character and tool:IsDescendantOf(character)
        
        if not inBackpack and not inCharacter then
            return true
        end
        
        task.wait(0.1)
    end
    
    local inBackpack = backpack and tool:IsDescendantOf(backpack)
    local inCharacter = character and tool:IsDescendantOf(character)
    return not inBackpack and not inCharacter
end

function StealAnEggTrade.SendGift(targetPlayerId, tool)
    local numericId, targetName = targetPlayerId, nil
    if not numericId then
        numericId, targetName = GetActiveWhitelistTarget()
    end
    
    if not numericId then
        return false, "Target Player Whitelist belum ditentukan atau belum berada di server!"
    end
    
    if not tool then
        local character = LocalPlayer.Character
        if character then
            tool = character:FindFirstChildOfClass("Tool")
        end
    end
    
    if not tool or not tool:IsA("Tool") or not tool.Parent or IsIgnoredTool(tool) then
        return false, "Tidak ada Tool yang valid untuk dikirim (Item Bat/Trap diabaikan)!"
    end
    
    local toolName = tool.Name
    
    local equipped, equipMsg = StealAnEggTrade.EquipTool(tool)
    if not equipped then
        return false, "Gagal memegang Tool: " .. tostring(equipMsg)
    end
    
    local giftingRemote = StealAnEggTrade.GetGiftingRemote()
    if not giftingRemote then
        return false, "Remote 'Gifting: Send Request' tidak ditemukan di ReplicatedStorage.Network"
    end
    
    local targetPlayerObj = Players:GetPlayerByUserId(numericId)
    if not targetPlayerObj and targetName then
        targetPlayerObj = FindPlayerByName(targetName)
    end
    
    print(string.format("[SendGift] Mengirim '%s' ke Target ID: %s (Player In Server: %s)", 
        toolName, tostring(numericId), targetPlayerObj and targetPlayerObj.Name or "TIDAK ADA DI SERVER"))
    
    local success, result = pcall(function()
        return giftingRemote:InvokeServer(numericId)
    end)
    
    if (not success or result == false) and targetPlayerObj then
        local s2, r2 = pcall(function()
            return giftingRemote:InvokeServer(targetPlayerObj)
        end)
        if s2 and r2 ~= false then
            success = s2
            result = r2
        end
    end
    
    print(string.format("[SendGift Request Dikirim] Sukses: %s | Result: %s", tostring(success), tostring(result)))
    
    if success and result ~= false then
        -- ⏳ Tunggu sampai tool benar-benar hilang/berpindah dari inventaris kita ke penerima
        print(string.format("[SendGift] Menunggu item '%s' diterima target & hilang dari inventaris...", toolName))
        local transferred = WaitForToolTransferred(tool, 6.0)
        
        if transferred then
            print(string.format("[SendGift Sukses] '%s' BERHASIL HILANG & DITERIMA TARGET ✅", toolName))
            StealAnEggTrade.AddTradeLog("SENT", toolInfo, targetPlayerObj and targetPlayerObj.Name or targetName or tostring(numericId))
            return true, "Tool berhasil dipindahtangankan"
        else
            print(string.format("[SendGift Peringatan] Timeout 6s: '%s' masih ada di inventaris!", toolName))
            StealAnEggTrade.AddTradeLog("FAIL", toolInfo, targetPlayerObj and targetPlayerObj.Name or targetName or tostring(numericId), "Timeout 6s")
            return false, "Timeout: Tool belum diterima oleh penerima"
        end
    else
        local errMsg = tostring(result or "Server menolak pengiriman gift")
        if not targetPlayerObj then
            errMsg = errMsg .. " (Pastikan target whitelist berada di server yang sama!)"
        end
        return false, errMsg
    end
end

function StealAnEggTrade.AcceptGift(senderUserId, requestUid)
    local responseRemote = StealAnEggTrade.GetGiftingResponseRemote()
    if not responseRemote then
        return false, "Remote 'Gifting: Response' tidak ditemukan di ReplicatedStorage.Network"
    end
    
    local numericId = tonumber(senderUserId) or senderUserId
    local uidStr = tostring(requestUid)
    
    local success, result = pcall(function()
        return responseRemote:InvokeServer(numericId, uidStr, true)
    end)
    
    return success, result
end

function StealAnEggTrade.DeclineGift(senderUserId, requestUid)
    local responseRemote = StealAnEggTrade.GetGiftingResponseRemote()
    if not responseRemote then
        return false, "Remote 'Gifting: Response' tidak ditemukan"
    end
    
    local numericId = tonumber(senderUserId) or senderUserId
    local uidStr = tostring(requestUid)
    
    local success, result = pcall(function()
        return responseRemote:InvokeServer(numericId, uidStr, false)
    end)
    
    return success, result
end

function StealAnEggTrade.GetJobId()
    return tostring(game.JobId)
end

function StealAnEggTrade.GetServerUptime()
    return workspace.DistributedGameTime
end

function StealAnEggTrade.CopyJobId()
    return CopyToClipboard(game.JobId)
end

function StealAnEggTrade.TeleportToJobId(targetJobId)
    if not targetJobId or targetJobId == "" then
        return false, "Job ID tidak boleh kosong!"
    end
    local cleanJobId = tostring(targetJobId):gsub("%s+", "")
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, cleanJobId, LocalPlayer)
    end)
    return success, err
end

function StealAnEggTrade.Rejoin()
    local success, err = pcall(function()
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\n[Rejoining Server...]")
            task.wait(0.5)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
    return success, err
end

--- ❄️ SMART DEEP HOP: Mencari Server Sepi Dingin (Matchmaking Deprioritized / Sepi Lama)
function StealAnEggTrade.HopSmartSmallServer()
    task.spawn(function()
        local placeId = game.PlaceId
        local foundServers = {}
        local cursor = ""
        local attempts = 0
        local maxAttempts = 5
        
        print("[SmartDeepHop] Memulai Deep Scan server sepi dingin...")
        
        while attempts < maxAttempts do
            attempts = attempts + 1
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s", placeId, cursor ~= "" and ("&cursor=" .. cursor) or "")
            local success, raw = pcall(function() return game:HttpGet(url) end)
            
            if success and raw then
                local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
                if ok and data and data.data then
                    for index, s in ipairs(data.data) do
                        if s.id and s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.playing > 0 then
                            local playerCnt = tonumber(s.playing) or 99
                            local pingVal = tonumber(s.ping) or 999
                            
                            table.insert(foundServers, {
                                id = s.id,
                                playing = playerCnt,
                                maxPlayers = tonumber(s.maxPlayers) or 0,
                                ping = pingVal,
                                page = attempts
                            })
                        end
                    end
                    
                    if data.nextPageCursor and data.nextPageCursor ~= "" then
                        cursor = data.nextPageCursor
                    else
                        break
                    end
                else
                    break
                end
            else
                break
            end
        end
        
        if #foundServers > 0 then
            table.sort(foundServers, function(a, b)
                if a.playing ~= b.playing then
                    return a.playing < b.playing
                elseif a.page ~= b.page then
                    return a.page > b.page
                else
                    return a.ping < b.ping
                end
            end)
            
            local bestServer = foundServers[1]
            print(string.format("[SmartDeepHop] Server Sepi Dingin Ditemukan! ID: %s | Pemain: %d/%d (Page %d) | Ping: %dms", 
                bestServer.id, bestServer.playing, bestServer.maxPlayers, bestServer.page, bestServer.ping))
                
            pcall(function()
                Library:Notify({
                    Title   = "Server Sepi Dingin Ditemukan! ❄️",
                    Content = string.format("Server dengan %d/%d pemain (Halaman %d, Ping %dms)", bestServer.playing, bestServer.maxPlayers, bestServer.page, bestServer.ping),
                    Type    = "Success",
                    Duration = 4.5
                })
            end)
            
            task.wait(0.5)
            TeleportService:TeleportToPlaceInstance(placeId, bestServer.id, LocalPlayer)
        else
            pcall(function()
                Library:Notify({
                    Title   = "Server Sepi Tidak Ditemukan",
                    Content = "Mencoba server publik acak...",
                    Type    = "Warning",
                    Duration = 3
                })
            end)
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    end)
end

function StealAnEggTrade.HopSmallServer()
    StealAnEggTrade.HopSmartSmallServer()
end

function StealAnEggTrade.ServerHop()
    pcall(function()
        local placeId = game.PlaceId
        local serversUrl = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        local raw = game:HttpGet(serversUrl)
        local data = HttpService:JSONDecode(raw)
        if data and data.data then
            local possibleServers = {}
            for _, s in ipairs(data.data) do
                if s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.id ~= game.JobId then
                    table.insert(possibleServers, s.id)
                end
            end
            if #possibleServers > 0 then
                local chosenId = possibleServers[math.random(1, #possibleServers)]
                TeleportService:TeleportToPlaceInstance(placeId, chosenId, LocalPlayer)
            else
                TeleportService:Teleport(placeId, LocalPlayer)
            end
        end
    end)
end


-- ==========================================================
-- 🎮 PROGRAMMATIC SCRIPT CONTROLLERS (API)
-- ==========================================================

function StealAnEggTrade.SetWhitelist(whitelistTblOrString)
    Config.WhitelistUsernames = ParseWhitelist(whitelistTblOrString)
    print(string.format("[StealAnEgg API] Whitelist Updated (%d Akun): %s", #Config.WhitelistUsernames, table.concat(Config.WhitelistUsernames, ", ")))
    return true, Config.WhitelistUsernames
end

function StealAnEggTrade.SetTarget(targetUserIdOrUsername)
    local num = tonumber(targetUserIdOrUsername)
    if num then
        Config.TargetPlayerId = num
        print("[StealAnEgg API] Target UserId diset ke:", num)
        return true, num
    elseif type(targetUserIdOrUsername) == "string" and targetUserIdOrUsername ~= "" then
        Config.TargetPlayerName = targetUserIdOrUsername
        local foundPlayer = FindPlayerByName(targetUserIdOrUsername)
        if foundPlayer then
            Config.TargetPlayerId = foundPlayer.UserId
            print(string.format("[StealAnEgg API] Target Player '%s' -> UserID: %d", targetUserIdOrUsername, foundPlayer.UserId))
            return true, foundPlayer.UserId
        else
            local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(targetUserIdOrUsername) end)
            if ok and id then
                Config.TargetPlayerId = id
                print(string.format("[StealAnEgg API] Target Player '%s' -> UserID: %d", targetUserIdOrUsername, id))
                return true, id
            end
        end
    end
    return false, "Player tidak ditemukan"
end

function StealAnEggTrade.SetAutoTrade(state)
    Config.AutoTradeLoop = (state == true)
    print("[StealAnEgg API] AutoTradeLoop set to:", Config.AutoTradeLoop)
    if Config.AutoTradeLoop then
        StealAnEggTrade.StartAutoTradeLoop()
    end
end

function StealAnEggTrade.SetAutoTradeFilter(state)
    Config.AutoTradeFilterLoop = (state == true)
    print("[StealAnEgg API] AutoTradeFilterLoop set to:", Config.AutoTradeFilterLoop)
    if Config.AutoTradeFilterLoop then
        StealAnEggTrade.StartFilteredTradeLoop()
    end
end

function StealAnEggTrade.SetAutoAccept(state)
    Config.AutoAcceptGift = (state == true)
    print("[StealAnEgg API] AutoAcceptGift set to:", Config.AutoAcceptGift)
end

function StealAnEggTrade.SetFilter(filterTbl)
    if type(filterTbl) ~= "table" then return false end
    if filterTbl.Item then Config.FilterItem = filterTbl.Item end
    if filterTbl.Mutation then Config.FilterMutation = filterTbl.Mutation end
    if filterTbl.Rarity or filterTbl.FilterRarity then Config.FilterRarity = filterTbl.Rarity or filterTbl.FilterRarity end
    if filterTbl.MinWeightMillions then Config.MinWeight = filterTbl.MinWeightMillions * 1000000 end
    if filterTbl.MinWeight then Config.MinWeight = filterTbl.MinWeight end
    if filterTbl.MaxWeightMillions then Config.MaxWeight = filterTbl.MaxWeightMillions * 1000000 end
    if filterTbl.MaxWeight then Config.MaxWeight = filterTbl.MaxWeight end
    if filterTbl.MinIncomeMillions then Config.MinIncome = filterTbl.MinIncomeMillions * 1000000 end
    if filterTbl.MinIncome then Config.MinIncome = filterTbl.MinIncome end
    if filterTbl.MaxIncomeMillions then Config.MaxIncome = filterTbl.MaxIncomeMillions * 1000000 end
    if filterTbl.MaxIncome then Config.MaxIncome = filterTbl.MaxIncome end
    if filterTbl.IgnoreFavorites ~= nil then Config.IgnoreFavorites = filterTbl.IgnoreFavorites end
    if filterTbl.OnlyFavorites ~= nil then Config.OnlyFavorites = filterTbl.OnlyFavorites end
    if filterTbl.Whitelist then StealAnEggTrade.SetWhitelist(filterTbl.Whitelist) end
    print(string.format("[StealAnEgg API] Filter Updated -> Item: %s | Mutasi: %s | Rarity: %s | Min W: %.2fM | Min Inc: %.2fM/s", 
        tostring(Config.FilterItem), tostring(Config.FilterMutation), tostring(Config.FilterRarity), Config.MinWeight / 1000000, Config.MinIncome / 1000000))
    return true
end

function StealAnEggTrade.GiftFilteredBatch()
    local targetId, targetName = GetActiveWhitelistTarget()
    if not targetId then
        warn("[StealAnEgg API] Target Whitelist belum diset / belum berada di server!")
        return false, "Target Whitelist belum diset / belum berada di server"
    end
    local tools = StealAnEggTrade.GetAllTools()
    local matched = {}
    for _, t in ipairs(tools) do
        if StealAnEggTrade.MatchesFilter(t, Config) then
            table.insert(matched, t)
        end
    end
    
    if #matched == 0 then
        return false, "Tidak ada item di backpack yang cocok dengan filter saat ini!"
    end
    
    task.spawn(function()
        for _, tool in ipairs(matched) do
            if not tool.Parent then continue end
            local tName = tool.Name
            local ok, err = StealAnEggTrade.SendGift(targetId, tool)
            if ok then
                TradeStats.TotalSent = TradeStats.TotalSent + 1
                TradeStats.SuccessCount = TradeStats.SuccessCount + 1
                TradeStats.LastItemName = tName
            else
                TradeStats.FailCount = TradeStats.FailCount + 1
            end
            task.wait(Config.DelayBetweenGifts)
        end
    end)
    return true, #matched
end

function StealAnEggTrade.GetStats()
    return TradeStats
end

function StealAnEggTrade.GetConfig()
    return Config
end

-- ==========================================================
-- 💰 AUTO SELL SYSTEM & REMOTE INTEGRATION
-- ==========================================================
local function GetSellRemote()
    local network = ReplicatedStorage:FindFirstChild("Network")
    if not network then return nil end
    return network:FindFirstChild("AssetInventory: SellAsset") 
        or network:WaitForChild("AssetInventory: SellAsset", 3)
end

function StealAnEggTrade.MatchesSellFilter(tool, sellConfig)
    sellConfig = sellConfig or Config
    if not tool or not tool:IsA("Tool") or IsIgnoredTool(tool) then return false end
    local info = StealAnEggTrade.GetToolInfo(tool)
    if not info then return false end
    
    -- 1. Validasi UID
    if not info.UID or info.UID == "-" or info.UID == "" then
        return false
    end
    
    -- 2. Proteksi Favorit
    if sellConfig.AutoSellIgnoreFavorites and info.Favorite then
        return false
    end
    
    -- 3. Proteksi Mutasi Rainbow (Jangan pernah jual Rainbow)
    if sellConfig.AutoSellProtectRainbow ~= false then
        local mLower = tostring(info.BaseMutation or ""):lower()
        local nameLower = tostring(info.Name or ""):lower()
        local dispLower = tostring(info.DisplayName or ""):lower()
        if mLower:find("rainbow") or nameLower:find("rainbow") or dispLower:find("rainbow") then
            return false
        end
    end
    
    -- 4. Proteksi Tier Dewa (Divine, Eternal, Secret, BrainrotGod, Prismatic)
    if sellConfig.AutoSellProtectGodTier then
        local rRank = info.RarityRank or GetRarityRank(info.Rarity)
        if rRank >= 65 then -- Tier Secret (65), Eternal (70), Divine (75), BrainrotGod (85), dll.
            return false
        end
    end
    
    -- 4. Filter Nama Jenis Item
    if sellConfig.AutoSellItem and sellConfig.AutoSellItem ~= "All Items" and sellConfig.AutoSellItem ~= "" then
        local targetName = sellConfig.AutoSellItem:lower()
        local matchesName = info.Name:lower():find(targetName, 1, true) ~= nil
        local matchesDisp = info.DisplayName:lower():find(targetName, 1, true) ~= nil
        if not matchesName and not matchesDisp then
            return false
        end
    end
    
    -- 5. Filter Mutasi
    if sellConfig.AutoSellMutation and sellConfig.AutoSellMutation ~= "All Mutations" and sellConfig.AutoSellMutation ~= "All" then
        if info.BaseMutation:lower() ~= sellConfig.AutoSellMutation:lower() then
            return false
        end
    end
    
    -- 6. Filter Rarity untuk Dijual
    if sellConfig.AutoSellRarities and sellConfig.AutoSellRarities ~= "" and sellConfig.AutoSellRarities ~= "All Rarities" then
        if not CheckRarityMatch(info.Rarity, sellConfig.AutoSellRarities) then
            return false
        end
    end
    
    -- 7. Batas Maksimal Income (Jual jika Income <= AutoSellMaxIncome)
    if sellConfig.AutoSellMaxIncome and sellConfig.AutoSellMaxIncome > 0 then
        if info.PerSecond > sellConfig.AutoSellMaxIncome then
            return false
        end
    end
    
    -- 8. Batas Maksimal Berat (Jual jika Berat <= AutoSellMaxWeight)
    if sellConfig.AutoSellMaxWeight and sellConfig.AutoSellMaxWeight > 0 then
        if info.Weight > sellConfig.AutoSellMaxWeight then
            return false
        end
    end
    
    return true, info
end

function StealAnEggTrade.SellItem(toolOrUid)
    local tool = nil
    local uid = nil
    local toolName = "Item"
    
    if typeof(toolOrUid) == "Instance" and toolOrUid:IsA("Tool") then
        tool = toolOrUid
        local info = StealAnEggTrade.GetToolInfo(tool)
        uid = info and info.UID
        toolName = info and info.DisplayName or tool.Name
    elseif type(toolOrUid) == "string" then
        uid = toolOrUid
        toolName = "UID " .. uid
        -- Cari instance Tool yang memiliki UID ini
        local tools = StealAnEggTrade.GetAllTools()
        for _, t in ipairs(tools) do
            local info = StealAnEggTrade.GetToolInfo(t)
            if info and info.UID == uid then
                tool = t
                toolName = info.DisplayName or t.Name
                break
            end
        end
    end
    
    if not uid or uid == "-" or uid == "" then
        return false, "UID item tidak valid / tidak ditemukan"
    end
    
    local sellRemote = GetSellRemote()
    if not sellRemote then
        return false, "Remote 'AssetInventory: SellAsset' tidak ditemukan di ReplicatedStorage.Network"
    end
    
    -- 1. ✋ Pegang / Equip tool ke tangan karakter terlebih dahulu
    if tool and tool.Parent then
        local equipOk, equipMsg = StealAnEggTrade.EquipTool(tool)
        task.wait(0.12)
    end
    
    -- 2. 💰 Panggil Remote Sell saat sedang dipegang di tangan
    local ok, res = pcall(function()
        sellRemote:FireServer({
            [1] = tostring(uid)
        })
    end)
    
    if ok then
        -- 3. ⏳ Tunggu hingga tool terhapus / hilang dari karakter
        if tool then
            WaitForToolTransferred(tool, 3.5)
        end
        TradeStats.SellCount = (TradeStats.SellCount or 0) + 1
        TradeStats.LastSoldName = toolName
        local sInfo = tool and StealAnEggTrade.GetToolInfo(tool) or {DisplayName = toolName, Name = toolName, UID = tostring(uid)}
        StealAnEggTrade.AddTradeLog("SOLD", sInfo, "System Shop")
        print(string.format("[AutoSell] Berhasil memegang & menjual '%s' [UID: %s] 💰", toolName, tostring(uid)))
        return true, "Berhasil dijual"
    else
        return false, tostring(res)
    end
end

function StealAnEggTrade.SellFilteredBatch()
    local tools = StealAnEggTrade.GetAllTools()
    local toSell = {}
    for _, t in ipairs(tools) do
        local isMatch, info = StealAnEggTrade.MatchesSellFilter(t, Config)
        if isMatch and info and info.UID and info.UID ~= "-" then
            table.insert(toSell, t)
        end
    end
    
    if #toSell == 0 then
        return false, "Tidak ada item di tas yang cocok dengan kriteria Auto Sell saat ini!"
    end
    
    task.spawn(function()
        for _, tool in ipairs(toSell) do
            if tool and tool.Parent then
                StealAnEggTrade.SellItem(tool)
                task.wait(Config.AutoSellDelay or 0.2)
            end
        end
    end)
    
    return true, #toSell
end

function StealAnEggTrade.SetAutoSell(state)
    Config.AutoSellLoop = (state == true)
    print("[StealAnEgg API] AutoSellLoop set to:", Config.AutoSellLoop)
    if Config.AutoSellLoop then
        StealAnEggTrade.StartAutoSellLoop()
    end
end

local isSellLoopRunning = false
function StealAnEggTrade.StartAutoSellLoop()
    if isSellLoopRunning then return end
    isSellLoopRunning = true
    task.spawn(function()
        while Config.AutoSellLoop and getgenv().CurrentTradeScriptID == scriptId do
            local tools = StealAnEggTrade.GetAllTools()
            for _, t in ipairs(tools) do
                if not Config.AutoSellLoop then break end
                local isMatch, info = StealAnEggTrade.MatchesSellFilter(t, Config)
                if isMatch and info and info.UID and info.UID ~= "-" and t.Parent then
                    StealAnEggTrade.SellItem(t)
                    task.wait(Config.AutoSellDelay or 0.25)
                end
            end
            task.wait(1.2)
        end
        isSellLoopRunning = false
    end)
end

-- ==========================================================
-- ⚔️ AUTO EQUIP ACTIVE ASSET SYSTEM & REMOTE INTEGRATION
-- ==========================================================

function StealAnEggTrade.EquipActiveAsset(toolOrUid)
    local tool = nil
    local uid = nil
    local toolName = "Asset"
    
    if typeof(toolOrUid) == "Instance" and toolOrUid:IsA("Tool") then
        tool = toolOrUid
        local info = StealAnEggTrade.GetToolInfo(tool)
        uid = info and info.UID
        toolName = info and info.DisplayName or tool.Name
        if not uid or uid == "-" or uid == "" then
            uid = tool:GetAttribute("UID") or tool:GetAttribute("UUID") or tool:GetAttribute("uid") or tool:GetAttribute("AssetId")
            local cfg = tool:FindFirstChild("Configuration") or tool:FindFirstChild("Config")
            if not uid and cfg then
                uid = cfg:GetAttribute("UID") or cfg:GetAttribute("UUID") or cfg:GetAttribute("uid")
            end
        end
    elseif type(toolOrUid) == "string" then
        uid = toolOrUid
        toolName = "UID " .. uid
        local tools = StealAnEggTrade.GetAllTools()
        for _, t in ipairs(tools) do
            local info = StealAnEggTrade.GetToolInfo(t)
            if info and info.UID == uid then
                tool = t
                toolName = info.DisplayName or t.Name
                break
            end
        end
    end
    
    if not uid or uid == "-" or uid == "" then
        return false, "UID item tidak valid / tidak ditemukan"
    end
    
    local remote = StealAnEggTrade.GetActiveAssetsEquipRemote()
    if not remote then
        return false, "Remote 'ActiveAssets: RequestEquip' tidak ditemukan di ReplicatedStorage.Network"
    end
    
    -- 1. ✋ Pegang item ke tangan karakter terlebih dahulu (Equip Tool)
    if tool and tool.Parent then
        local equipOk, equipMsg = StealAnEggTrade.EquipTool(tool)
        if not equipOk then
            return false, "Gagal memegang item: " .. tostring(equipMsg)
        end
        task.wait(0.12)
    end
    
    -- 2. ⚡ Panggil RemoteFunction ActiveAssets: RequestEquip
    local ok, res = pcall(function()
        return remote:InvokeServer(tostring(uid))
    end)
    
    if ok then
        Config.LastEquippedAssetUID = tostring(uid)
        Config.LastEquippedAssetName = toolName
        TradeStats.EquipCount = (TradeStats.EquipCount or 0) + 1
        TradeStats.LastEquippedName = toolName
        print(string.format("[AutoEquipAsset] Berhasil memegang & meng-equip Active Asset: '%s' [UID: %s] ⚔️", toolName, tostring(uid)))
        return true, res
    else
        return false, tostring(res)
    end
end

function StealAnEggTrade.MatchesEquipFilter(tool, equipConfig)
    equipConfig = equipConfig or Config
    if not tool or not tool:IsA("Tool") or IsIgnoredTool(tool) then return false end
    local info = StealAnEggTrade.GetToolInfo(tool)
    if not info then return false end
    
    -- 1. Validasi UID
    if not info.UID or info.UID == "-" or info.UID == "" then
        return false
    end
    
    -- 2. Filter Favorit
    if equipConfig.AutoEquipOnlyFavorites and not info.Favorite then
        return false
    end
    
    -- 3. Filter Nama Jenis Item
    if equipConfig.AutoEquipItem and equipConfig.AutoEquipItem ~= "All Items" and equipConfig.AutoEquipItem ~= "" then
        local targetName = equipConfig.AutoEquipItem:lower()
        local matchesName = info.Name:lower():find(targetName, 1, true) ~= nil
        local matchesDisp = info.DisplayName:lower():find(targetName, 1, true) ~= nil
        if not matchesName and not matchesDisp then
            return false
        end
    end
    
    -- 4. Filter Mutasi
    if equipConfig.AutoEquipMutation and equipConfig.AutoEquipMutation ~= "All Mutations" and equipConfig.AutoEquipMutation ~= "All" and equipConfig.AutoEquipMutation ~= "" then
        if info.BaseMutation:lower() ~= equipConfig.AutoEquipMutation:lower() then
            return false
        end
    end
    
    -- 5. Filter Rarity
    if equipConfig.AutoEquipRarities and equipConfig.AutoEquipRarities ~= "All Rarities" and equipConfig.AutoEquipRarities ~= "All" and equipConfig.AutoEquipRarities ~= "" then
        if not CheckRarityMatch(info.Rarity, equipConfig.AutoEquipRarities) then
            return false
        end
    end
    
    -- 6. Filter Min Income
    if equipConfig.AutoEquipMinIncome and equipConfig.AutoEquipMinIncome > 0 then
        if info.PerSecond < equipConfig.AutoEquipMinIncome then
            return false
        end
    end
    
    -- 7. Filter Min Weight
    if equipConfig.AutoEquipMinWeight and equipConfig.AutoEquipMinWeight > 0 then
        if info.Weight < equipConfig.AutoEquipMinWeight then
            return false
        end
    end
    
    return true, info
end

function StealAnEggTrade.GetEquipCandidates()
    local tools = StealAnEggTrade.GetAllTools()
    local mode = Config.AutoEquipMode or "💰 Highest Income (Best Value)"
    local candidates = {}
    
    for _, t in ipairs(tools) do
        local isMatch, info = false, nil
        if mode == "🎯 Custom Filter (Rarity / Mutasi / Item)" then
            isMatch, info = StealAnEggTrade.MatchesEquipFilter(t, Config)
        else
            info = StealAnEggTrade.GetToolInfo(t)
            isMatch = (info and info.UID and info.UID ~= "-")
            if Config.AutoEquipOnlyFavorites and info and not info.Favorite then
                isMatch = false
            end
        end
        
        if isMatch and info then
            table.insert(candidates, { Tool = t, Info = info })
        end
    end
    
    -- Urutkan kandidat berdasarkan mode prioritas
    table.sort(candidates, function(a, b)
        if mode == "⚖️ Heaviest Weight" then
            if a.Info.Weight ~= b.Info.Weight then return a.Info.Weight > b.Info.Weight end
            return a.Info.PerSecond > b.Info.PerSecond
        elseif mode == "👑 Highest Rarity Tier" then
            if a.Info.RarityRank ~= b.Info.RarityRank then return a.Info.RarityRank > b.Info.RarityRank end
            return a.Info.PerSecond > b.Info.PerSecond
        else -- "💰 Highest Income (Best Value)" atau "🎯 Custom Filter"
            if a.Info.PerSecond ~= b.Info.PerSecond then return a.Info.PerSecond > b.Info.PerSecond end
            if a.Info.RarityRank ~= b.Info.RarityRank then return a.Info.RarityRank > b.Info.RarityRank end
            return a.Info.Weight > b.Info.Weight
        end
    end)
    
    return candidates
end

function StealAnEggTrade.EquipTopAssets(limit)
    limit = math.max(1, tonumber(limit) or tonumber(Config.AutoEquipMaxAmount) or 5)
    local candidates = StealAnEggTrade.GetEquipCandidates()
    local count = 0
    local toEquip = {}
    
    for i = 1, math.min(limit, #candidates) do
        table.insert(toEquip, candidates[i].Tool)
    end
    
    for _, tool in ipairs(toEquip) do
        if tool and tool.Parent then
            local ok, _ = StealAnEggTrade.EquipActiveAsset(tool)
            if ok then count = count + 1 end
            task.wait(Config.AutoEquipDelay or 0.35)
        end
    end
    
    return count, #candidates
end

function StealAnEggTrade.SetAutoEquip(state)
    Config.AutoEquipAsset = (state == true)
    print("[StealAnEgg API] AutoEquipAsset set to:", Config.AutoEquipAsset)
    if Config.AutoEquipAsset then
        StealAnEggTrade.StartAutoEquipLoop()
    end
end

local isEquipLoopRunning = false
function StealAnEggTrade.StartAutoEquipLoop()
    if isEquipLoopRunning then return end
    isEquipLoopRunning = true
    task.spawn(function()
        while Config.AutoEquipAsset and getgenv().CurrentTradeScriptID == scriptId do
            pcall(function()
                local maxAmount = math.max(1, tonumber(Config.AutoEquipMaxAmount) or 5)
                StealAnEggTrade.EquipTopAssets(maxAmount)
            end)
            task.wait(Config.AutoEquipInterval or 3.0)
        end
        isEquipLoopRunning = false
    end)
end

_G.StealAnEggTrade = StealAnEggTrade
getgenv().StealAnEggTrade = StealAnEggTrade


-- ==========================================================
-- [SECTION 3] AUTO ACCEPT LISTENER (EXACT EVENT HANDLER + WHITELIST)
-- ==========================================================

local LastRequestPara = nil

function StealAnEggTrade.OnGiftRequestReceived(senderUsername, senderUserId, itemName, requestUID)
    local sName = tostring(senderUsername or "Unknown")
    local sId = tonumber(senderUserId)
    local iName = tostring(itemName or "Unknown Item")
    local reqUid = tostring(requestUID or "")
    
    LastGiftRequest.SenderName = sName
    LastGiftRequest.SenderId = sId
    LastGiftRequest.ItemName = iName
    LastGiftRequest.RequestUID = reqUid
    LastGiftRequest.Time = tick()
    
    print(string.format("[AutoAccept] Event Masuk: %s (ID: %s) mengirim '%s' [UID: %s]", sName, tostring(sId), iName, reqUid))
    
    if LastRequestPara then
        pcall(function()
            LastRequestPara:Set("Permintaan Masuk Terakhir", string.format("Item: %s\nDari: %s (ID: %s)\nStatus: Menunggu Respon...", iName, sName, tostring(sId)))
        end)
    end
    
    if Config.AutoAcceptGift then
        -- Cek Whitelist jika filter target aktif
        if not IsPlayerInWhitelist(sName, sId) then
            if LastRequestPara then
                pcall(function()
                    LastRequestPara:Set("Permintaan Masuk Terakhir", string.format("Item: %s\nDari: %s (ID: %s)\nStatus: Diabaikan (Bukan Akun Whitelist) ❌", iName, sName, tostring(sId)))
                end)
            end
            print(string.format("[AutoAccept] Ditolak: Pengirim '%s' (ID: %s) tidak ada di Whitelist!", sName, tostring(sId)))
            return
        end
        
        if Config.AcceptDelay and Config.AcceptDelay > 0 then
            task.wait(Config.AcceptDelay)
        end
        
        local ok, result = StealAnEggTrade.AcceptGift(sId, reqUid)
        if ok then
            TradeStats.AcceptedCount = TradeStats.AcceptedCount + 1
            StealAnEggTrade.AddTradeLog("RECEIVED", {DisplayName = iName, Name = iName, Rarity = "Normal"}, sName)
            if LastRequestPara then
                pcall(function()
                    LastRequestPara:Set("Permintaan Masuk Terakhir", string.format("Item: %s\nDari: %s (ID: %s)\nStatus: BERHASIL DITERIMA ✅", iName, sName, tostring(sId)))
                end)
            end
            pcall(function()
                Library:Notify({
                    Title   = "Gift Diterima! 📥",
                    Content = string.format("Menerima '%s' dari %s", iName, sName),
                    Type    = "Success",
                    Duration = 3.5
                })
            end)
        else
            if LastRequestPara then
                pcall(function()
                    LastRequestPara:Set("Permintaan Masuk Terakhir", string.format("Item: %s\nDari: %s\nStatus: GAGAL DITERIMA ❌ (%s)", iName, sName, tostring(result)))
                end)
            end
            pcall(function()
                Library:Notify({
                    Title   = "Gagal Menerima Gift",
                    Content = "Error: " .. tostring(result),
                    Type    = "Error",
                    Duration = 3.5
                })
            end)
        end
    end
end

task.spawn(function()
    local network = ReplicatedStorage:WaitForChild("Network", 10)
    if not network then return end
    
    local giftingReq = network:FindFirstChild("Gifting: Request") or network:WaitForChild("Gifting: Request", 5)
    if giftingReq and giftingReq:IsA("RemoteEvent") then
        giftingReq.OnClientEvent:Connect(function(senderUsername, senderUserId, itemName, requestUID)
            task.spawn(StealAnEggTrade.OnGiftRequestReceived, senderUsername, senderUserId, itemName, requestUID)
        end)
    end
    
    network.ChildAdded:Connect(function(child)
        if child.Name == "Gifting: Request" and child:IsA("RemoteEvent") then
            child.OnClientEvent:Connect(function(senderUsername, senderUserId, itemName, requestUID)
                task.spawn(StealAnEggTrade.OnGiftRequestReceived, senderUsername, senderUserId, itemName, requestUID)
            end)
        end
    end)
end)


-- ==========================================================
-- [SECTION 4] BACKGROUND LOOPS MANAGER
-- ==========================================================

local isTradeLoopRunning = false
function StealAnEggTrade.StartAutoTradeLoop()
    if isTradeLoopRunning then return end
    isTradeLoopRunning = true
    task.spawn(function()
        while Config.AutoTradeLoop and getgenv().CurrentTradeScriptID == scriptId do
            local targetId, targetName = GetActiveWhitelistTarget()
            if targetId then
                local tools = StealAnEggTrade.GetAllTools()
                for _, tool in ipairs(tools) do
                    if not Config.AutoTradeLoop then break end
                    
                    -- Cek kesesuaian filter jika ada filter aktif
                    if not StealAnEggTrade.MatchesFilter(tool, Config) then
                        continue
                    end
                    
                    local tName = tool.Name
                    local ok, err = StealAnEggTrade.SendGift(targetId, tool)
                    if ok then
                        TradeStats.TotalSent = TradeStats.TotalSent + 1
                        TradeStats.SuccessCount = TradeStats.SuccessCount + 1
                        TradeStats.LastItemName = tName
                    else
                        TradeStats.FailCount = TradeStats.FailCount + 1
                    end
                    task.wait(Config.DelayBetweenGifts)
                end
            end
            task.wait(1.0)
        end
        isTradeLoopRunning = false
    end)
end

local isFilterLoopRunning = false
function StealAnEggTrade.StartFilteredTradeLoop()
    if isFilterLoopRunning then return end
    isFilterLoopRunning = true
    task.spawn(function()
        while Config.AutoTradeFilterLoop and getgenv().CurrentTradeScriptID == scriptId do
            local targetId, targetName = GetActiveWhitelistTarget()
            if targetId then
                local tools = StealAnEggTrade.GetAllTools()
                local matchedCount = 0
                for _, tool in ipairs(tools) do
                    if not Config.AutoTradeFilterLoop then break end
                    
                    local isMatch, info = StealAnEggTrade.MatchesFilter(tool, Config)
                    if isMatch then
                        matchedCount = matchedCount + 1
                        local tName = info and info.DisplayName or tool.Name
                        print(string.format("[AutoTradeFilter] Item LOLOS Filter: %s [Income: %s/s | Berat: %s kg] -> Mengirim ke target...", 
                            tName, formatNumber(info.PerSecond), formatNumber(info.Weight)))
                        local ok, err = StealAnEggTrade.SendGift(targetId, tool)
                        if ok then
                            TradeStats.TotalSent = TradeStats.TotalSent + 1
                            TradeStats.SuccessCount = TradeStats.SuccessCount + 1
                            TradeStats.LastItemName = tName
                        else
                            TradeStats.FailCount = TradeStats.FailCount + 1
                            print(string.format("[AutoTradeFilter Gagal] %s -> Error: %s", tName, tostring(err)))
                        end
                        task.wait(Config.DelayBetweenGifts)
                    end
                end
            end
            task.wait(1.0)
        end
        isFilterLoopRunning = false
    end)
end

if Config.AutoTradeLoop then
    StealAnEggTrade.StartAutoTradeLoop()
end
if Config.AutoTradeFilterLoop then
    StealAnEggTrade.StartFilteredTradeLoop()
end


-- ==========================================================
-- [SECTION 5] LOAD SIGMA UI LIBRARY V4
-- ==========================================================

local Library = nil
local getSuccess, getErr = pcall(function()
    Library = loadstring(game:HttpGet("https://github.com/xyaxzj/sigmamaboi.lua/raw/main/NcHO.lua"))()
end)

if not getSuccess or not Library then
    pcall(function()
        if readfile and isfile and isfile("UI sigma.lua") then
            Library = loadstring(readfile("UI sigma.lua"))()
        end
    end)
end

if not Library then
    error("Gagal memuat Sigma UI Library! Pastikan executor Anda terhubung ke internet.")
end

local function GetPlayerList()
    local playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(playerNames, p.Name .. " (" .. p.UserId .. ")")
        end
    end
    if #playerNames == 0 then
        table.insert(playerNames, "Tidak ada player lain")
    end
    return playerNames
end

local function GetUserIdFromSelection(selectionStr)
    if not selectionStr or selectionStr == "Tidak ada player lain" then return nil end
    local idStr = selectionStr:match("%((%d+)%)")
    if idStr then
        return tonumber(idStr)
    end
    local nameOnly = selectionStr:split(" ")[1]
    local foundPlayer = FindPlayerByName(nameOnly)
    if foundPlayer then
        return foundPlayer.UserId
    end
    return tonumber(selectionStr)
end


-- ==========================================================
-- [SECTION 6] MEMBUAT WINDOW & KOMPONEN SIGMA UI
-- ==========================================================

local Window = Library:CreateWindow({
    Name       = string.format("Sigma Hub | Steal An Egg (%s)", Config.ProfileRole or currentUsername),
    Footer     = 'discord.gg/sigma | v4.0',
    Icon       = 10734898124,
    ToggleKey  = Enum.KeyCode.RightControl,
    Theme      = "Dark"
})

-- ⚡ Pastikan RichText aktif di seluruh TextLabel Sigma UI agar warna & bold tag bekerja optimal
task.spawn(function()
    local function enableRichText(obj)
        if obj and (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
            pcall(function() obj.RichText = true end)
        end
    end
    
    local coreGui = (gethui and gethui()) or (game:GetService("CoreGui"):FindFirstChild("RobloxGui")) or game:GetService("CoreGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if coreGui then
        for _, desc in ipairs(coreGui:GetDescendants()) do
            enableRichText(desc)
        end
        coreGui.DescendantAdded:Connect(function(desc)
            task.defer(function() enableRichText(desc) end)
        end)
    end
end)

-- ⚡ Scan Inventaris Awal untuk Mengisi Seluruh Opsi Dropdown di Semua Tab
local initialScan = StealAnEggTrade.ScanInventory(currentInventorySort, currentInventorySearch)

-- ---------------------------------------------------------
-- TAB 1: ⚡ AUTO TRADE & RECEIVER (MAIN TAB)
-- ---------------------------------------------------------
local MainTab = Window:MakeTab("⚡")

-- Section 1: Target Player & Whitelist
local TargetSec = MainTab:AddSection("Target Player & Whitelist Setup")

local WhitelistPara = TargetSec:AddParagraph("Status Target Whitelist", "Memindai target whitelist...")

task.spawn(function()
    while getgenv().CurrentTradeScriptID == scriptId do
        pcall(function()
            local activeId, activeName = GetActiveWhitelistTarget()
            local onlineTargets = {}
            for _, usn in ipairs(Config.WhitelistUsernames) do
                local p = FindPlayerByName(usn)
                if p and p ~= LocalPlayer then
                    table.insert(onlineTargets, string.format("🟢 %s (Online)", p.Name))
                else
                    table.insert(onlineTargets, string.format("⚪ %s (Offline)", usn))
                end
            end
            
            local desc = string.format("Daftar Whitelist (%d Akun):\n%s\n\nTarget Aktif Terpilih: %s",
                #Config.WhitelistUsernames,
                #onlineTargets > 0 and table.concat(onlineTargets, "\n") or "Belum ada whitelist",
                activeName and (activeName .. " (ID: " .. tostring(activeId) .. ")") or "Tidak ada di server"
            )
            WhitelistPara:Set("Status Target Whitelist", desc)
        end)
        task.wait(2)
    end
end)

TargetSec:AddInput({
    Name = "✏️ Input Whitelist Usernames (Pisahkan Koma)",
    Placeholder = table.concat(Config.WhitelistUsernames, ", "),
    Tooltip = "Ketik satu atau beberapa username target/pengirim sekaligus (Cth: szeshuro, player2, player3)"
}, function(text)
    if text and text ~= "" then
        StealAnEggTrade.SetWhitelist(text)
        Library:Notify({
            Title   = "Whitelist Diperbarui",
            Content = string.format("%d Akun terdaftar di Whitelist", #Config.WhitelistUsernames),
            Type    = "Success",
            Duration = 3
        })
    end
end)

local playerList = GetPlayerList()
local PlayerDropdown = TargetSec:AddDropdown({
    Name = "Pilih Player Manual di Server",
    Options = playerList,
    Default = playerList[1] or "",
    Flag = "TargetPlayerDropdown",
    Tooltip = "Pilih target penerima gift langsung dari server saat ini"
}, function(selected)
    local userId = GetUserIdFromSelection(selected)
    if userId then
        Config.TargetPlayerId = userId
        Library:Notify({
            Title   = "Target Diset",
            Content = "Target UserId: " .. tostring(userId),
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

TargetSec:AddButton({
    Name = "🔄 Refresh Daftar Player Server",
    Tooltip = "Memindai ulang player yang ada di dalam server"
}, function()
    local newList = GetPlayerList()
    PlayerDropdown:Refresh(newList)
    Library:Notify({
        Title   = "Player List",
        Content = "Daftar player diperbarui (" .. #newList .. " player)",
        Type    = "Info",
        Duration = 2
    })
end)


-- Section 2: Gifting Actions (Pengirim / Gifter)
local ActionSec = MainTab:AddSection("Aksi Quick & Manual Trade / Gift (Pengirim)")

local manualTradeOptions = {}
for _, opt in ipairs(initialScan.DropdownOptions) do
    if opt ~= "Backpack Kosong" and not opt:find("Tidak ada item") then
        table.insert(manualTradeOptions, opt)
    end
end

local manualTypeOptions = {}
for _, name in ipairs(initialScan.UniqueNames) do
    if name ~= "All Items" then
        table.insert(manualTypeOptions, name)
    end
end

local ManualTradeDropdown = nil
local ManualTradeTypeDropdown = nil

ManualTradeDropdown = ActionSec:AddMultiDropdown({
    Name = "🎒 Pilih Item dari Tas untuk Di-Trade (Multi-Select ☑️)",
    Options = manualTradeOptions,
    Default = {},
    Flag = "ManualTradeMultiDropdown",
    Tooltip = "Centang satu atau beberapa item spesifik sekaligus di tas yang ingin di-trade"
}, function(selectedList)
    Config.SelectedTradeItems = selectedList or {}
    local selectedUIDs = {}
    local tools = StealAnEggTrade.GetAllTools()
    
    for _, selectedOpt in ipairs(Config.SelectedTradeItems) do
        for _, t in ipairs(tools) do
            local info = StealAnEggTrade.GetToolInfo(t)
            if info and (info.OptionString == selectedOpt or selectedOpt:find(info.DisplayName, 1, true)) then
                if info.UID and info.UID ~= "-" then
                    selectedUIDs[info.UID] = true
                end
            end
        end
    end
    
    Config.SelectedTradeUIDs = selectedUIDs
    
    if #selectedList > 0 then
        Library:Notify({
            Title   = "Item Dipilih 🎒",
            Content = string.format("%d Item dicentang untuk Trade", #selectedList),
            Type    = "Info",
            Duration = 2
        })
    end
end)

ManualTradeTypeDropdown = ActionSec:AddMultiDropdown({
    Name = "📦 Filter Jenis/Nama Item (Multi-Select ☑️)",
    Options = manualTypeOptions,
    Default = {},
    Flag = "MainFilterItemMultiDropdown",
    Tooltip = "Centang beberapa jenis nama item tertentu (cth: Unicorn, El Maja, Mosasaurus) yang ingin di-trade"
}, function(selectedTypes)
    local typeSet = {}
    for _, tName in ipairs(selectedTypes or {}) do
        typeSet[tName] = true
    end
    Config.SelectedTradeItemTypes = typeSet
end)

ActionSec:AddButton({
    Name = "🎁 Gift Semua Item Terpilih Ini ke Whitelist (1x Batch)",
    Tooltip = "Mengirim seluruh item yang dicentang di dropdown atas satu per satu ke target Whitelist"
}, function()
    local targetId, targetName = GetActiveWhitelistTarget()
    if not targetId then
        Library:Notify({
            Title   = "Peringatan",
            Content = "Target Whitelist belum ditemukan di dalam server!",
            Type    = "Warning",
            Duration = 3.5
        })
        return
    end
    
    local toSend = {}
    local tools = StealAnEggTrade.GetAllTools()
    
    -- 1. Kumpulkan tool yang cocok dengan multi-select UID
    if Config.SelectedTradeUIDs and next(Config.SelectedTradeUIDs) ~= nil then
        for _, t in ipairs(tools) do
            local info = StealAnEggTrade.GetToolInfo(t)
            if info and Config.SelectedTradeUIDs[info.UID] then
                table.insert(toSend, t)
            end
        end
    -- 2. Kumpulkan tool yang cocok dengan multi-select types
    elseif Config.SelectedTradeItemTypes and next(Config.SelectedTradeItemTypes) ~= nil then
        for _, t in ipairs(tools) do
            local info = StealAnEggTrade.GetToolInfo(t)
            if info and (Config.SelectedTradeItemTypes[info.DisplayName] or Config.SelectedTradeItemTypes[info.Category]) then
                table.insert(toSend, t)
            end
        end
    -- 3. Fallback: item di tangan
    else
        local character = LocalPlayer.Character
        local heldTool = character and character:FindFirstChildOfClass("Tool")
        if heldTool and not IsIgnoredTool(heldTool) then
            table.insert(toSend, heldTool)
        end
    end
    
    if #toSend == 0 then
        Library:Notify({
            Title   = "Peringatan",
            Content = "Centang item di dropdown terlebih dahulu atau pegang item di tangan!",
            Type    = "Warning",
            Duration = 3.5
        })
        return
    end
    
    Library:Notify({
        Title   = "Memulai Gifting 🎁",
        Content = string.format("Mengirim %d item terpilih ke %s...", #toSend, targetName or tostring(targetId)),
        Type    = "Info",
        Duration = 3
    })
    
    task.spawn(function()
        local count = 0
        for _, tool in ipairs(toSend) do
            if not tool.Parent then continue end
            local info = StealAnEggTrade.GetToolInfo(tool)
            local itemName = info and info.DisplayName or tool.Name
            local ok, err = StealAnEggTrade.SendGift(targetId, tool)
            if ok then
                count = count + 1
                TradeStats.TotalSent = TradeStats.TotalSent + 1
                TradeStats.SuccessCount = TradeStats.SuccessCount + 1
                TradeStats.LastItemName = itemName
            else
                TradeStats.FailCount = TradeStats.FailCount + 1
            end
            task.wait(Config.DelayBetweenGifts or 0.5)
        end
        
        Library:Notify({
            Title   = "Selesai! 🎁",
            Content = string.format("Berhasil mengirim %d dari %d item terpilih!", count, #toSend),
            Type    = "Success",
            Duration = 4
        })
        
        task.defer(function()
            local scan = StealAnEggTrade.ScanInventory()
            local opts = {}
            for _, o in ipairs(scan.DropdownOptions) do
                if o ~= "Backpack Kosong" and not o:find("Tidak ada item") then
                    table.insert(opts, o)
                end
            end
            local types = {}
            for _, n in ipairs(scan.UniqueNames) do
                if n ~= "All Items" then table.insert(types, n) end
            end
            if ManualTradeDropdown then ManualTradeDropdown:Refresh(opts) end
            if ManualTradeTypeDropdown then ManualTradeTypeDropdown:Refresh(types) end
        end)
    end)
end)

ActionSec:AddButton({
    Name = "🔄 Refresh Pilihan Item dari Tas",
    Tooltip = "Memperbarui daftar item di dropdown dari tas saat ini"
}, function()
    local scan = StealAnEggTrade.ScanInventory()
    local opts = {}
    for _, o in ipairs(scan.DropdownOptions) do
        if o ~= "Backpack Kosong" and not o:find("Tidak ada item") then
            table.insert(opts, o)
        end
    end
    local types = {}
    for _, n in ipairs(scan.UniqueNames) do
        if n ~= "All Items" then table.insert(types, n) end
    end
    if ManualTradeDropdown then ManualTradeDropdown:Refresh(opts) end
    if ManualTradeTypeDropdown then ManualTradeTypeDropdown:Refresh(types) end
    Library:Notify({
        Title   = "Daftar Item Diperbarui 🔄",
        Content = string.format("%d Item terdeteksi di tas", scan.Count),
        Type    = "Info",
        Duration = 2.5
    })
end)

ActionSec:AddButton({
    Name = "🎁 Gift Barang yang Sedang Dipegang di Tangan (1x)",
    Tooltip = "Memegang dan mengirim item yang saat ini aktif di tangan ke target Whitelist"
}, function()
    local targetId, targetName = GetActiveWhitelistTarget()
    if not targetId then
        Library:Notify({
            Title   = "Peringatan",
            Content = "Target Whitelist belum ditemukan di dalam server!",
            Type    = "Warning",
            Duration = 3.5
        })
        return
    end
    
    local character = LocalPlayer.Character
    local heldTool = character and character:FindFirstChildOfClass("Tool")
    local itemName = heldTool and heldTool.Name or "Item Aktif"
    
    local ok, err = StealAnEggTrade.SendGift(targetId, heldTool)
    if ok then
        TradeStats.TotalSent = TradeStats.TotalSent + 1
        TradeStats.SuccessCount = TradeStats.SuccessCount + 1
        TradeStats.LastItemName = itemName
        Library:Notify({
            Title   = "Gift Terkirim! 🎁",
            Content = string.format("Berhasil mengirim '%s' ke %s", itemName, targetName or tostring(targetId)),
            Type    = "Success",
            Duration = 3.5
        })
    else
        TradeStats.FailCount = TradeStats.FailCount + 1
        Library:Notify({
            Title   = "Gagal Gift",
            Content = "Error: " .. tostring(err),
            Type    = "Error",
            Duration = 4
        })
    end
end)

ActionSec:AddButton({
    Name = "📦 Gift Semua Item Sesuai Filter ke Whitelist (1x Loop)",
    Tooltip = "Memegang satu per satu lalu mengirim seluruh Item yang cocok dengan kriteria filter ke target Whitelist"
}, function()
    local targetId, targetName = GetActiveWhitelistTarget()
    if not targetId then
        Library:Notify({
            Title   = "Peringatan",
            Content = "Target Whitelist belum ditemukan di dalam server!",
            Type    = "Warning",
            Duration = 3.5
        })
        return
    end
    
    local tools = StealAnEggTrade.GetAllTools()
    local matched = {}
    for _, t in ipairs(tools) do
        if StealAnEggTrade.MatchesFilter(t, Config) then
            table.insert(matched, t)
        end
    end
    
    if #matched == 0 then
        Library:Notify({
            Title   = "Tidak Ada Item Cocok",
            Content = "Tidak ada Item yang cocok dengan filter saat ini!",
            Type    = "Warning",
            Duration = 3
        })
        return
    end
    
    Library:Notify({
        Title   = "Memulai Gifting",
        Content = string.format("Mengirim %d item sesuai filter ke %s...", #matched, targetName or tostring(targetId)),
        Type    = "Info",
        Duration = 3
    })
    
    task.spawn(function()
        for _, tool in ipairs(matched) do
            if not tool.Parent then continue end
            local tName = tool.Name
            local ok, err = StealAnEggTrade.SendGift(targetId, tool)
            if ok then
                TradeStats.TotalSent = TradeStats.TotalSent + 1
                TradeStats.SuccessCount = TradeStats.SuccessCount + 1
                TradeStats.LastItemName = tName
            else
                TradeStats.FailCount = TradeStats.FailCount + 1
            end
            task.wait(Config.DelayBetweenGifts)
        end
        
        Library:Notify({
            Title   = "Selesai",
            Content = "Proses Gift semua Item sesuai filter telah selesai!",
            Type    = "Success",
            Duration = 4
        })
    end)
end)

ActionSec:AddToggle({
    Name = "⚡ Auto Loop Trade Item Sesuai Filter ke Whitelist",
    Default = Config.AutoTradeFilterLoop,
    Flag = "AutoTradeFilterLoopToggle",
    Tooltip = "Terus memindai backpack & mengirim item otomatis yang cocok dengan filter/pilihan ke Whitelist"
}, function(Value)
    StealAnEggTrade.SetAutoTradeFilter(Value)
    if Value then
        Library:Notify({
            Title   = "Auto Trade Filter Aktif",
            Content = "Loop pengiriman aktif sesuai filter / pilihan item ke Target Whitelist",
            Type    = "Success",
            Duration = 3
        })
    else
        Library:Notify({
            Title   = "Auto Trade Filter Dimatikan",
            Content = "Loop pengiriman filter dinonaktifkan.",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

ActionSec:AddToggle({
    Name = "⚡ Auto Loop Trade Semua Item ke Whitelist (Tanpa Filter)",
    Default = Config.AutoTradeLoop,
    Flag = "AutoTradeLoopToggle",
    Tooltip = "Terus memindai backpack & mengirim seluruh item otomatis ke akun Whitelist"
}, function(Value)
    StealAnEggTrade.SetAutoTrade(Value)
    if Value then
        Library:Notify({
            Title   = "Auto Trade Semua Aktif",
            Content = "Loop pengiriman semua item aktif ke Target Whitelist",
            Type    = "Success",
            Duration = 3
        })
    else
        Library:Notify({
            Title   = "Auto Trade Dimatikan",
            Content = "Loop pengiriman dinonaktifkan.",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)


-- Section 3: 📥 AUTO ACCEPT GIFT (PENERIMA / RECEIVER)
local ReceiveSec = MainTab:AddSection("📥 Auto Accept Gift (Penerima)")

local ReceiveStatusPara = ReceiveSec:AddParagraph("Status Auto Accept", Config.AutoAcceptGift and "Status: AKTIF (Menunggu Event 'Gifting: Request'...) 🟢" or "Status: NONAKTIF (OFF) 🔴")
LastRequestPara = ReceiveSec:AddParagraph("Permintaan Masuk Terakhir", "Belum ada permintaan gift yang masuk.")

ReceiveSec:AddToggle({
    Name = "⚡ Auto Accept Semua Permintaan Gift Otomatis",
    Default = Config.AutoAcceptGift,
    Flag = "AutoAcceptToggle",
    Tooltip = "Menunggu event 'Gifting: Request' muncul lalu seketika mengirim 'Gifting: Response' (Accept)"
}, function(Value)
    StealAnEggTrade.SetAutoAccept(Value)
    if Value then
        ReceiveStatusPara:Set("Status Auto Accept", "Status: AKTIF (Menunggu Event 'Gifting: Request'...) 🟢")
        Library:Notify({
            Title   = "Auto Accept Aktif",
            Content = "Menunggu event gift masuk dan langsung di-accept otomatis!",
            Type    = "Success",
            Duration = 3
        })
    else
        ReceiveStatusPara:Set("Status Auto Accept", "Status: NONAKTIF (OFF) 🔴")
        Library:Notify({
            Title   = "Auto Accept Nonaktif",
            Content = "Auto accept gift telah dimatikan.",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

ReceiveSec:AddToggle({
    Name = "🔒 Hanya Terima Dari Akun Whitelist (Whitelist Only)",
    Default = Config.OnlyAcceptTarget,
    Flag = "WhitelistTargetToggle",
    Tooltip = "Jika aktif, hanya menerima gift dari username yang ada di daftar Whitelist"
}, function(Value)
    Config.OnlyAcceptTarget = Value
    if Value then
        Library:Notify({
            Title   = "Whitelist Only Aktif 🔒",
            Content = "Hanya menerima gift dari akun di daftar Whitelist (" .. #Config.WhitelistUsernames .. " akun)",
            Type    = "Info",
            Duration = 3
        })
    end
end)

ReceiveSec:AddSlider({
    Name = "⏱️ Jeda Sebelum Accept (Detik)",
    Min = 0,
    Max = 2.0,
    Default = Config.AcceptDelay,
    Step = 0.1,
    Flag = "AcceptDelaySlider",
    Tooltip = "Waktu tunggu setelah event gift muncul sebelum memanggil remote accept"
}, function(val)
    Config.AcceptDelay = val
end)

ReceiveSec:AddButton({
    Name = "📥 Terima (Accept) Permintaan Terakhir Secara Manual",
    Tooltip = "Menerima permintaan gift yang terakhir kali masuk"
}, function()
    if LastGiftRequest.SenderId and LastGiftRequest.RequestUID then
        local ok, result = StealAnEggTrade.AcceptGift(LastGiftRequest.SenderId, LastGiftRequest.RequestUID)
        if ok then
            TradeStats.AcceptedCount = TradeStats.AcceptedCount + 1
            if LastRequestPara then
                LastRequestPara:Set("Permintaan Masuk Terakhir", string.format("Item: %s\nDari: %s (ID: %s)\nStatus: MANUAL ACCEPT BERHASIL ✅", LastGiftRequest.ItemName, LastGiftRequest.SenderName, tostring(LastGiftRequest.SenderId)))
            end
            Library:Notify({
                Title   = "Gift Diterima! 📥",
                Content = "Manual accept berhasil: " .. tostring(LastGiftRequest.ItemName),
                Type    = "Success",
                Duration = 3
            })
        else
            Library:Notify({
                Title   = "Gagal Accept",
                Content = "Error: " .. tostring(result),
                Type    = "Error",
                Duration = 3.5
            })
        end
    else
        Library:Notify({
            Title   = "Tidak Ada Permintaan",
            Content = "Belum ada event gift yang terdeteksi!",
            Type    = "Warning",
            Duration = 3
        })
    end
end)


-- ---------------------------------------------------------
-- TAB 2: 🎒 BACKPACK EXPLORER (CLEAN ENGLISH EDITION)
-- ---------------------------------------------------------
local InvTab = Window:MakeTab("🎒")

initialScan = StealAnEggTrade.ScanInventory(currentInventorySort, currentInventorySearch)

-- Pagination state (10 items per page with compact single-line formatting)
local ITEMS_PER_PAGE = 10
local currentInvPage = 1
local lastFilteredTools = initialScan.FilteredTools or {}

-- Helper: Format a single item line (Ringkas dengan format K/M/B/T & Harga Jual Estimasi)
local function FormatItemLine(index, info)
    local rBadge = GetRarityBadge(info.Rarity)
    local mBadge = GetMutationBadge(info.BaseMutation)
    local incStr = formatIncome(info.PerSecond) -- Cth: "+3.17B/s"
    local wStr = formatNumber(info.Weight)
    local inChar = info.Instance and info.Instance.Parent == LocalPlayer.Character
    
    local mutPart = (info.BaseMutation ~= "Normal" and info.BaseMutation ~= "") and string.format(" [%s]", mBadge) or ""
    local favPart = info.Favorite and " ⭐" or ""
    local locPart = inChar and " ✋" or ""
    local incPart = (incStr and incStr ~= "") and (" • 💰 " .. incStr) or ""
    
    -- Hitung harga jual estimasi (Cth: 100M/s = 1k, 290M/s = 2k) dengan warna emas & BOLD
    local _, priceStr = CalculateItemPrice(info.PerSecond, Config.PriceRatePer100M)
    local pricePart = ""
    if priceStr and priceStr ~= "" then
        pricePart = string.format(' • <font color="#FFD700"><b>🏷️ %s</b></font>', priceStr)
    end
    
    return string.format("#%d. [%s] %s%s • ⚖️ %s kg%s%s%s%s",
        index,
        rBadge,
        tostring(info.DisplayName),
        mutPart,
        wStr,
        incPart,
        pricePart,
        favPart,
        locPart
    )
end

-- Helper: Build paginated item list text
local function BuildItemListText(scan, page)
    local filtered = scan and scan.FilteredTools or lastFilteredTools
    lastFilteredTools = filtered
    
    if not filtered or #filtered == 0 then
        if currentInventoryMinIncome > 0 then
            return string.format("No items match the current filter (Min Income: +%s/s).", formatNumber(currentInventoryMinIncome))
        end
        return "Your backpack is empty."
    end
    
    local totalItems = #filtered
    local totalPages = math.ceil(totalItems / ITEMS_PER_PAGE)
    page = math.clamp(page or currentInvPage, 1, totalPages)
    currentInvPage = page
    
    local startIdx = (page - 1) * ITEMS_PER_PAGE + 1
    local endIdx = math.min(page * ITEMS_PER_PAGE, totalItems)
    
    local lines = {}
    table.insert(lines, string.format("── Page %d / %d  (%d items total) ──", page, totalPages, totalItems))
    table.insert(lines, "")
    
    for i = startIdx, endIdx do
        local info = filtered[i]
        if info then
            table.insert(lines, FormatItemLine(i, info))
        end
    end
    
    if totalPages > 1 then
        table.insert(lines, "")
        table.insert(lines, string.format("Showing #%d–#%d of %d items", startIdx, endIdx, totalItems))
    end
    
    return table.concat(lines, "\n")
end

-- Helper: Update the item list paragraph
local function RefreshItemList(scan, page)
    if InvItemListPara then
        InvItemListPara:Set("📋 Item List", BuildItemListText(scan, page))
    end
end

-- ─── Section 1: Filters & Sorting ─────────────────────
local InvFilterSec = InvTab:AddSection("🔧 Filters & Sorting")

InvFilterSec:AddDropdown({
    Name = "🔀 Sort By",
    Options = INVENTORY_SORT_OPTIONS,
    Default = currentInventorySort,
    Flag = "InvSortDropdown",
    Tooltip = "Choose how to sort items in the backpack"
}, function(selectedSort)
    currentInventorySort = selectedSort or INVENTORY_SORT_OPTIONS[1]
    currentInvPage = 1
    local scan = StealAnEggTrade.ScanInventory(currentInventorySort, currentInventorySearch, currentInventoryMinIncome)
    RefreshItemList(scan, 1)
end)

InvFilterSec:AddInput({
    Name = "💰 Min Income Filter (Unit: Millions /s)",
    Placeholder = Config.MinIncome > 0 and string.format("%.2fM/s", Config.MinIncome / 1000000) or "e.g. 100 (= 100M/s) or 2.8B, 0 = Show All",
    Tooltip = "Filter items by minimum passive income per second. Also syncs with Auto Trade filter."
}, function(text)
    local incomeVal = ParseIncomeInput(text)
    Config.MinIncome = incomeVal
    currentInventoryMinIncome = incomeVal
    currentInvPage = 1
    local scan = StealAnEggTrade.ScanInventory(currentInventorySort, currentInventorySearch, currentInventoryMinIncome)
    RefreshItemList(scan, 1)
end)

InvFilterSec:AddInput({
    Name = "🏷️ Custom Price Rate (per 100M/s Income) [Opsional]",
    Placeholder = "Kosong = Tanpa Tampilan Harga (Cth isi: 1000, 1.5k, 2000)",
    Tooltip = "Atur harga jual estimasi per 100M/s income pasif. Jika kolom ini dikosongkan (empty), maka tampilan harga jual TIDAK AKAN MUNCUL sama sekali."
}, function(text)
    if not text or text == "" or text == "0" or text == "none" or text == "off" or text == "bebas" then
        Config.PriceRatePer100M = 0
        local scan = StealAnEggTrade.ScanInventory(currentInventorySort, currentInventorySearch, currentInventoryMinIncome)
        RefreshItemList(scan, currentInvPage)
        Library:Notify({
            Title   = "Tampilan Harga Nonaktif 🏷️",
            Content = "Kolom kosong: Tampilan harga disembunyikan.",
            Type    = "Info",
            Duration = 2.5
        })
        return
    end
    
    local rateVal = ParseIncomeInput(text)
    if rateVal <= 0 then
        rateVal = tonumber(text:gsub("[^%d]", "")) or 0
    end
    
    Config.PriceRatePer100M = rateVal
    local scan = StealAnEggTrade.ScanInventory(currentInventorySort, currentInventorySearch, currentInventoryMinIncome)
    RefreshItemList(scan, currentInvPage)
    
    if rateVal > 0 then
        Library:Notify({
            Title   = "Harga Jual Diperbarui 🏷️",
            Content = string.format("Rate diset: %s per 100M/s income", formatNumber(Config.PriceRatePer100M)),
            Type    = "Success",
            Duration = 2.5
        })
    else
        Library:Notify({
            Title   = "Tampilan Harga Nonaktif 🏷️",
            Content = "Kolom kosong: Tampilan harga disembunyikan.",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

-- ─── Section 2: Item List (Paginated) ──────────────────
local InvListSec = InvTab:AddSection("📋 Item List")

local InvItemListPara = InvListSec:AddParagraph("📋 Item List", BuildItemListText(initialScan, 1))

InvListSec:AddButton({
    Name = "⬅️ Previous Page",
    Tooltip = "Go to the previous page of items"
}, function()
    if currentInvPage > 1 then
        currentInvPage = currentInvPage - 1
        RefreshItemList(nil, currentInvPage)
    end
end)

InvListSec:AddButton({
    Name = "➡️ Next Page",
    Tooltip = "Go to the next page of items"
}, function()
    local totalPages = math.max(1, math.ceil(#lastFilteredTools / ITEMS_PER_PAGE))
    if currentInvPage < totalPages then
        currentInvPage = currentInvPage + 1
        RefreshItemList(nil, currentInvPage)
    end
end)

InvListSec:AddButton({
    Name = "🔄 Refresh Backpack",
    Tooltip = "Rescan inventory and update the item list"
}, function()
    local scan = StealAnEggTrade.ScanInventory(currentInventorySort, currentInventorySearch, currentInventoryMinIncome)
    RefreshItemList(scan, currentInvPage)
    Library:Notify({
        Title   = "Backpack Refreshed 🎒",
        Content = string.format("Found %d Items (%d match filter)", scan.Count, scan.FilteredCount),
        Type    = "Info",
        Duration = 2.5
    })
end)

-- ─── Section 3: Backpack Summary ───────────────────────
local InvStatSec = InvTab:AddSection("📊 Backpack Summary")

local function FormatPriceDisplay(totalPrice)
    if not Config.PriceRatePer100M or Config.PriceRatePer100M <= 0 then
        return "Nonaktif (Kolom Harga Kosong)"
    end
    if not totalPrice or totalPrice <= 0 then return "0" end
    if totalPrice >= 1e6 then
        return string.format('<font color="#FFD700"><b>%.2fM</b></font> (Rp %s)', totalPrice / 1e6, formatNumber(totalPrice))
    elseif totalPrice >= 1e3 then
        return string.format('<font color="#FFD700"><b>%dk</b></font> (Rp %s)', math.floor(totalPrice / 1e3), formatNumber(totalPrice))
    else
        return string.format('<font color="#FFD700"><b>%d</b></font> (Rp %s)', math.floor(totalPrice), formatNumber(totalPrice))
    end
end

local InvCountPara   = InvStatSec:AddParagraph("Total Items", string.format("%d Items", initialScan.Count))
local InvWeightPara  = InvStatSec:AddParagraph("Total Weight", string.format("%s kg", formatNumber(initialScan.TotalWeight)))
local InvIncomePara  = InvStatSec:AddParagraph("Total Passive Income", string.format("%s 💰", formatIncome(initialScan.TotalIncome)))
local InvPricePara   = InvStatSec:AddParagraph("Total Estimated Value", (Config.PriceRatePer100M and Config.PriceRatePer100M > 0) and string.format("🏷️ %s (Rate: %s / 100M)", FormatPriceDisplay(initialScan.TotalPrice or 0), formatNumber(Config.PriceRatePer100M)) or "Nonaktif (Kolom Harga Kosong)")
local InvBestPara    = InvStatSec:AddParagraph("👑 Highest Value Item", (initialScan.BestValuePet or initialScan.BestPet) and (initialScan.BestValuePet or initialScan.BestPet).OptionString or "-")
local InvHeavyPara   = InvStatSec:AddParagraph("⚖️ Heaviest Item", initialScan.HeaviestPet and string.format("%s (%s kg)", initialScan.HeaviestPet.DisplayName, formatNumber(initialScan.HeaviestPet.Weight)) or "-")

-- ─── Section 4: ⚔️ Auto Equip Active Asset ────────────────
local InvEquipSec = InvTab:AddSection("⚔️ Auto Equip Active Asset")

local EquipStatusPara = nil
local EquipItemDropdown = nil
local EquipRarityDropdown = nil
local EquipMutationDropdown = nil

local EQUIP_FILTER_MODES = {
    "💰 Highest Income (Best Value)",
    "⚖️ Heaviest Weight",
    "👑 Highest Rarity Tier",
    "🎯 Custom Filter (Rarity / Mutasi / Item)"
}

InvEquipSec:AddToggle({
    Name = "⚡ Enable Auto Equip Active Asset",
    Default = Config.AutoEquipAsset or false,
    Tooltip = "Automatically equip the best assets according to selected filtering mode & amount limit"
}, function(state)
    StealAnEggTrade.SetAutoEquip(state)
    Library:Notify({
        Title   = state and "Auto Equip Started ⚔️" or "Auto Equip Stopped ⏹️",
        Content = state and string.format("Mode: %s (Limit: %d assets)", tostring(Config.AutoEquipMode), Config.AutoEquipMaxAmount or 5) or "Auto equip loop is now disabled.",
        Type    = state and "Success" or "Info",
        Duration = 2.5
    })
end)

InvEquipSec:AddDropdown({
    Name = "🎯 Equip Filtering Mode",
    Options = EQUIP_FILTER_MODES,
    Default = Config.AutoEquipMode or EQUIP_FILTER_MODES[1],
    Flag = "AutoEquipModeDropdown",
    Tooltip = "Choose which asset filtering criteria / priority to use for equipping"
}, function(selectedMode)
    Config.AutoEquipMode = selectedMode or EQUIP_FILTER_MODES[1]
    Library:Notify({
        Title   = "Equip Mode Updated 🎯",
        Content = "Mode: " .. tostring(Config.AutoEquipMode),
        Type    = "Info",
        Duration = 2
    })
end)

InvEquipSec:AddSlider({
    Name = "🔢 Jumlah Asset yang Di-Equip (Limit)",
    Min = 1,
    Max = 25,
    Default = Config.AutoEquipMaxAmount or 5,
    Step = 1,
    Flag = "AutoEquipMaxAmountSlider",
    Tooltip = "Berapa banyak asset teratas yang ingin di-equip ke plot/karakter"
}, function(val)
    Config.AutoEquipMaxAmount = tonumber(val) or 5
end)

EquipItemDropdown = InvEquipSec:AddDropdown({
    Name = "📦 Filter Berdasarkan Jenis Item",
    Options = initialScan.UniqueNames,
    Default = Config.AutoEquipItem or "All Items",
    Flag = "AutoEquipItemDropdown",
    Tooltip = "Pilih jenis item tertentu yang ingin di-equip atau 'All Items'"
}, function(selected)
    Config.AutoEquipItem = selected or "All Items"
end)

EquipRarityDropdown = InvEquipSec:AddDropdown({
    Name = "👑 Filter Berdasarkan Rarity",
    Options = initialScan.Rarities,
    Default = Config.AutoEquipRarities or "All Rarities",
    Flag = "AutoEquipRarityDropdown",
    Tooltip = "Pilih rarity item yang ingin di-equip atau 'All Rarities'"
}, function(selected)
    Config.AutoEquipRarities = selected or "All Rarities"
end)

EquipMutationDropdown = InvEquipSec:AddDropdown({
    Name = "✨ Filter Berdasarkan Mutasi",
    Options = initialScan.Mutations,
    Default = Config.AutoEquipMutation or "All Mutations",
    Flag = "AutoEquipMutationDropdown",
    Tooltip = "Pilih mutasi item yang ingin di-equip atau 'All Mutations'"
}, function(selected)
    Config.AutoEquipMutation = selected or "All Mutations"
end)

InvEquipSec:AddInput({
    Name = "✏️ Custom Multi-Rarity Filter (Pisahkan Koma)",
    Placeholder = Config.AutoEquipRarities or "Cth: Divine, Eternal, Secret",
    Tooltip = "Ketik beberapa rarity yang diizinkan untuk di-equip (Cth: Divine, Eternal, Secret)"
}, function(text)
    if text and text ~= "" then
        Config.AutoEquipRarities = text
        Library:Notify({
            Title   = "Equip Rarity Diset 👑",
            Content = "Rarity Filter: " .. text,
            Type    = "Success",
            Duration = 2.5
        })
    end
end)

InvEquipSec:AddInput({
    Name = "💰 Minimum Income / Pasif (Satuan: JUTA/s)",
    Placeholder = Config.AutoEquipMinIncome > 0 and string.format("%.2fM/s", Config.AutoEquipMinIncome / 1000000) or "Cth: 100 (= 100M/s) atau 2.8B, 0 = Bebas",
    Tooltip = "Hanya equip item yang menghasilkan pasif income minimal tertentu"
}, function(text)
    local inc = ParseIncomeInput(text)
    Config.AutoEquipMinIncome = inc
    if inc > 0 then
        Library:Notify({
            Title   = "Min Income Equip Diset 💰",
            Content = string.format("Minimal: +%s/s%s", formatNumber(inc), formatIncome(inc)),
            Type    = "Success",
            Duration = 2.5
        })
    end
end)

InvEquipSec:AddInput({
    Name = "⚖️ Minimum Berat (Satuan: kg atau M/K)",
    Placeholder = Config.AutoEquipMinWeight > 0 and string.format("%s kg", formatNumber(Config.AutoEquipMinWeight)) or "Cth: 200k, 1M (= 1 Juta kg), 0 = Bebas",
    Tooltip = "Hanya equip item dengan berat minimal tertentu"
}, function(text)
    local w = ParseWeightInput(text)
    Config.AutoEquipMinWeight = w
    if w > 0 then
        Library:Notify({
            Title   = "Min Berat Equip Diset ⚖️",
            Content = string.format("Minimal: %s kg", formatNumber(w)),
            Type    = "Success",
            Duration = 2.5
        })
    end
end)

InvEquipSec:AddToggle({
    Name = "⭐ Hanya Equip Item Favorit (Only Favorites)",
    Default = Config.AutoEquipOnlyFavorites or false,
    Tooltip = "Hanya meng-equip item yang ditandai bintang (Favorite)"
}, function(state)
    Config.AutoEquipOnlyFavorites = state
end)

InvEquipSec:AddSlider({
    Name = "⏱️ Jeda Antar Equip (Detik)",
    Min = 0.1,
    Max = 2.0,
    Default = Config.AutoEquipDelay or 0.35,
    Step = 0.05,
    Flag = "AutoEquipDelaySlider",
    Tooltip = "Waktu jeda saat meng-equip banyak item secara berurutan"
}, function(val)
    Config.AutoEquipDelay = tonumber(val) or 0.35
end)

InvEquipSec:AddButton({
    Name = "⚡ Equip Top Filtered Assets Now (1x Batch)",
    Tooltip = "Instantly equip top matching assets right now based on active filters and amount limit"
}, function()
    local limit = math.max(1, tonumber(Config.AutoEquipMaxAmount) or 5)
    Library:Notify({
        Title   = "Memulai Equip Asset ⚔️",
        Content = string.format("Memindai dan meng-equip hingga %d asset teratas...", limit),
        Type    = "Info",
        Duration = 2.5
    })
    
    task.spawn(function()
        local equippedCount, totalCandidates = StealAnEggTrade.EquipTopAssets(limit)
        Library:Notify({
            Title   = "Equip Selesai! ⚔️",
            Content = string.format("Berhasil meng-equip %d dari %d asset yang cocok!", equippedCount, totalCandidates),
            Type    = "Success",
            Duration = 3.5
        })
    end)
end)

InvEquipSec:AddButton({
    Name = "🔄 Refresh Opsi Dropdown dari Backpack",
    Tooltip = "Memperbarui daftar nama item, mutasi, dan rarity di dropdown dari inventaris tas"
}, function()
    local scan = StealAnEggTrade.ScanInventory()
    if EquipItemDropdown then EquipItemDropdown:Refresh(scan.UniqueNames) end
    if EquipRarityDropdown then EquipRarityDropdown:Refresh(scan.Rarities) end
    if EquipMutationDropdown then EquipMutationDropdown:Refresh(scan.Mutations) end
    Library:Notify({
        Title   = "Dropdown Diperbarui 🔄",
        Content = string.format("%d Jenis Item, %d Mutasi, %d Rarity terdeteksi di tas", #scan.UniqueNames - 1, #scan.Mutations - 1, #scan.Rarities - 1),
        Type    = "Info",
        Duration = 2.5
    })
end)

EquipStatusPara = InvEquipSec:AddParagraph("Status Auto Equip", "Mode: " .. tostring(Config.AutoEquipMode) .. "\nLast Equipped: -")



-- ---------------------------------------------------------
-- TAB 3: 🎯 AUTO TRADE BY FILTER (MULTI-RARITY, WEIGHT, MUTATION)
-- ---------------------------------------------------------
local FilterTab = Window:MakeTab("🎯")
local FilterSec = FilterTab:AddSection("Kriteria Filter Auto Trade")

local ItemNameDropdown = FilterSec:AddDropdown({
    Name = "Filter Berdasarkan Jenis Item",
    Options = initialScan.UniqueNames,
    Default = Config.FilterItem or "All Items",
    Flag = "FilterItemDropdown",
    Tooltip = "Pilih nama jenis item tertentu atau 'All Items'"
}, function(selected)
    Config.FilterItem = selected or "All Items"
end)

local MutationDropdown = FilterSec:AddDropdown({
    Name = "Filter Berdasarkan Mutasi",
    Options = initialScan.Mutations,
    Default = Config.FilterMutation or "All Mutations",
    Flag = "FilterMutationDropdown",
    Tooltip = "Pilih mutasi item (cth: Golden, Normal, etc.)"
}, function(selected)
    Config.FilterMutation = selected or "All Mutations"
end)

local RarityDropdown = FilterSec:AddDropdown({
    Name = "Filter Berdasarkan Rarity",
    Options = initialScan.Rarities,
    Default = Config.FilterRarity or "Divine, Eternal, Secret",
    Flag = "FilterRarityDropdown",
    Tooltip = "Pilih tingkat rarity atau 'Divine, Eternal, Secret'"
}, function(selected)
    Config.FilterRarity = selected or "All Rarities"
end)

FilterSec:AddInput({
    Name = "✏️ Custom Multi-Rarity Filter (Pisahkan Koma)",
    Placeholder = Config.FilterRarity or "Cth: Divine, Eternal, Secret, Mythical",
    Tooltip = "Ketik beberapa rarity sekaligus yang dipisahkan koma (Cth: Divine, Eternal, Secret)"
}, function(text)
    if text and text ~= "" then
        Config.FilterRarity = text
        Library:Notify({
            Title   = "Rarity Filter Diset",
            Content = "Filter Rarity: " .. text,
            Type    = "Success",
            Duration = 3
        })
    end
end)

FilterSec:AddButton({
    Name = "🔄 Refresh Opsi Filter dari Backpack",
    Tooltip = "Memperbarui daftar item, mutasi, dan rarity yang terdeteksi di inventaris"
}, function()
    local scan = StealAnEggTrade.ScanInventory()
    ItemNameDropdown:Refresh(scan.UniqueNames)
    MutationDropdown:Refresh(scan.Mutations)
    RarityDropdown:Refresh(scan.Rarities)
    Library:Notify({
        Title   = "Filter Diperbarui",
        Content = string.format("%d Item, %d Mutasi, %d Rarity terdeteksi", #scan.UniqueNames - 1, #scan.Mutations - 1, #scan.Rarities - 1),
        Type    = "Info",
        Duration = 2.5
    })
end)

FilterSec:AddInput({
    Name = "⚖️ Minimum Berat (Satuan: kg atau M/K)",
    Placeholder = Config.MinWeight > 0 and string.format("%s kg", formatNumber(Config.MinWeight)) or "Cth: 200k, 272058, atau 1M (= 1.000.000 kg), 0 = Bebas",
    Tooltip = "Input angka berat minimal. Contoh: 200k, 272058, 1M, atau 0 = Bebas"
}, function(text)
    local weightVal = ParseWeightInput(text)
    Config.MinWeight = weightVal
    if weightVal > 0 then
        Library:Notify({
            Title   = "Min Berat Diset ⚖️",
            Content = string.format("Minimal Berat: %s kg", formatNumber(weightVal)),
            Type    = "Success",
            Duration = 3
        })
    else
        Library:Notify({
            Title   = "Min Berat Diset ⚖️",
            Content = "Bebas / Tanpa batas minimum berat",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

FilterSec:AddInput({
    Name = "⚖️ Maximum Berat (Satuan: kg atau M/K) [Opsional]",
    Placeholder = Config.MaxWeight > 0 and string.format("%s kg", formatNumber(Config.MaxWeight)) or "Cth: 500k, 5M, 0 = Bebas",
    Tooltip = "Input angka batas maksimal berat (0 = Tanpa batas maksimum)"
}, function(text)
    local weightVal = ParseWeightInput(text)
    Config.MaxWeight = weightVal
    if weightVal > 0 then
        Library:Notify({
            Title   = "Max Berat Diset ⚖️",
            Content = string.format("Maksimal Berat: %s kg", formatNumber(weightVal)),
            Type    = "Success",
            Duration = 3
        })
    else
        Library:Notify({
            Title   = "Max Berat Diset ⚖️",
            Content = "Bebas / Tanpa batas maksimum berat",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

FilterSec:AddInput({
    Name = "💰 Minimum Income / Pasif (Satuan: JUTA / detik)",
    Placeholder = Config.MinIncome > 0 and string.format("%.2f", Config.MinIncome / 1000000) or "Cth: 100 (= 100M/s) atau 2.8B, 0 = Bebas",
    Tooltip = "Input angka minimal pasif income per detik (Cth: 100 = 100 Juta/s, 2.5B = 2.5 Miliar/s, 0 = Bebas)"
}, function(text)
    local incomeVal = ParseIncomeInput(text)
    Config.MinIncome = incomeVal
    currentInventoryMinIncome = incomeVal
    local scan = StealAnEggTrade.ScanInventory(currentInventorySort, currentInventorySearch, currentInventoryMinIncome)
    currentInvPage = 1
    RefreshItemList(scan, 1)
    if incomeVal > 0 then
        Library:Notify({
            Title   = "Min Income Diset 💰",
            Content = string.format("Minimal: +%s / detik%s (Auto Trade & Backpack tersinkron)", formatNumber(incomeVal), formatIncome(incomeVal)),
            Type    = "Success",
            Duration = 3
        })
    else
        Library:Notify({
            Title   = "Min Income Diset 💰",
            Content = "Bebas / Tanpa batas minimum income",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

FilterSec:AddInput({
    Name = "💰 Maximum Income / Pasif (Satuan: JUTA / detik) [Opsional]",
    Placeholder = Config.MaxIncome > 0 and string.format("%.2f", Config.MaxIncome / 1000000) or "Cth: 500 (= 500M/s), 0 = Bebas",
    Tooltip = "Input batas maksimal pasif income per detik (0 = Tanpa batas maksimum)"
}, function(text)
    local incomeVal = ParseIncomeInput(text)
    Config.MaxIncome = incomeVal
    if incomeVal > 0 then
        Library:Notify({
            Title   = "Max Income Diset 💰",
            Content = string.format("Maksimal: +%s / detik%s", formatNumber(incomeVal), formatIncome(incomeVal)),
            Type    = "Success",
            Duration = 3
        })
    else
        Library:Notify({
            Title   = "Max Income Diset 💰",
            Content = "Bebas / Tanpa batas maksimum income",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

FilterSec:AddToggle({
    Name = "⭐ Abaikan Barang Favorit (Skip Favorite)",
    Default = Config.IgnoreFavorites,
    Flag = "FilterIgnoreFavToggle",
    Tooltip = "Jangan kirim item yang ditandai Favorite"
}, function(val)
    Config.IgnoreFavorites = val
end)

FilterSec:AddToggle({
    Name = "🌟 Hanya Kirim Barang Favorit (Only Favorite)",
    Default = Config.OnlyFavorites,
    Flag = "FilterOnlyFavToggle",
    Tooltip = "Hanya kirim item yang berstatus Favorite"
}, function(val)
    Config.OnlyFavorites = val
end)

FilterSec:AddSlider({
    Name = "⏱️ Jeda Antar Gift (Detik)",
    Min = 0.1,
    Max = 3.0,
    Default = Config.DelayBetweenGifts,
    Step = 0.1,
    Flag = "FilterDelaySlider",
    Tooltip = "Waktu jeda antar pengiriman remote gift"
}, function(val)
    Config.DelayBetweenGifts = val
end)

local FilterActionSec = FilterTab:AddSection("⚡ Eksekusi Auto Trade By Filter")

local FilterMatchPara = FilterActionSec:AddParagraph("Status Pencocokan", "Memindai kecocokan filter...")

FilterActionSec:AddButton({
    Name = "📦 Kirim Semua Item Sesuai Filter ke Whitelist (1x Batch)",
    Tooltip = "Mengirim semua item di backpack yang cocok dengan kriteria filter ke target Whitelist"
}, function()
    local ok, count = StealAnEggTrade.GiftFilteredBatch()
    if ok then
        Library:Notify({Title = "Memulai Batch Filter", Content = "Mengirim " .. count .. " item sesuai filter...", Type = "Info", Duration = 3})
    else
        Library:Notify({Title = "Peringatan", Content = tostring(count), Type = "Warning", Duration = 3})
    end
end)

FilterActionSec:AddToggle({
    Name = "🔁 Auto Loop Trade Khusus Sesuai Filter ke Whitelist",
    Default = Config.AutoTradeFilterLoop,
    Flag = "AutoTradeFilterLoopToggle",
    Tooltip = "Otomatis dan terus menerus mengirim hanya item yang lolos kriteria filter ke akun Whitelist"
}, function(Value)
    StealAnEggTrade.SetAutoTradeFilter(Value)
    if Value then
        Library:Notify({
            Title   = "Auto Trade Filter Aktif",
            Content = string.format("Loop filter aktif: %s [%s] (%s)", tostring(Config.FilterItem), tostring(Config.FilterMutation), tostring(Config.FilterRarity)),
            Type    = "Success",
            Duration = 3.5
        })
    else
        Library:Notify({
            Title   = "Auto Trade Filter Mati",
            Content = "Loop filter dinonaktifkan.",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)


-- ---------------------------------------------------------
-- TAB 4: 💰 AUTO SELL (FILTER & BULK SELL)
-- ---------------------------------------------------------
local SellTab = Window:MakeTab("💰")
local SellSec = SellTab:AddSection("⚙️ Kriteria Auto Sell Item")

local initialSellScan = StealAnEggTrade.ScanInventory()

local SellRarityDropdown = SellSec:AddDropdown({
    Name = "Pilih Rarity untuk Dijual",
    Options = {
        "Basic, Common, Uncommon, Rare",
        "Common, Basic",
        "Basic, Common, Uncommon, Rare, SuperRare",
        "Under Mythical (Basic to Epic)",
        "All Rarities",
        "Custom"
    },
    Default = Config.AutoSellRarities or "Basic, Common, Uncommon, Rare",
    Flag = "AutoSellRarityDropdown",
    Tooltip = "Pilih kelompok rarity yang ingin dijual otomatis"
}, function(selected)
    if selected == "Under Mythical (Basic to Epic)" then
        Config.AutoSellRarities = "Basic, Common, Uncommon, Rare, SuperRare, Epic"
    elseif selected == "All Rarities" then
        Config.AutoSellRarities = "All Rarities"
    else
        Config.AutoSellRarities = selected
    end
    Library:Notify({
        Title   = "Auto Sell Rarity Diset 💰",
        Content = "Rarity yang akan dijual: " .. tostring(Config.AutoSellRarities),
        Type    = "Info",
        Duration = 2.5
    })
end)

SellSec:AddInput({
    Name = "✏️ Custom Multi-Rarity Sell (Pisahkan Koma)",
    Placeholder = Config.AutoSellRarities or "Cth: Basic, Common, Uncommon, Rare",
    Tooltip = "Ketik tingkat rarity yang ingin dijual otomatis secara spesifik dipisahkan koma"
}, function(text)
    if text and text ~= "" then
        Config.AutoSellRarities = text
        Library:Notify({
            Title   = "Custom Sell Rarity Diset",
            Content = "Rarity: " .. text,
            Type    = "Success",
            Duration = 2.5
        })
    end
end)

SellSec:AddInput({
    Name = "💰 Jual Item dengan Income di Bawah (Max Income / detik)",
    Placeholder = Config.AutoSellMaxIncome > 0 and string.format("%.2fM/s", Config.AutoSellMaxIncome / 1e6) or "Cth: 100M (= < 100M/s dijual), 0 = Bebas",
    Tooltip = "Item dengan penghasilan di bawah angka ini akan otomatis dijual (Cth: 100M -> Semua item < 100M/s dijual)"
}, function(text)
    local val = ParseIncomeInput(text)
    Config.AutoSellMaxIncome = val
    if val > 0 then
        Library:Notify({
            Title   = "Max Income Auto Sell Diset 💰",
            Content = string.format("Jual item berpenghasilan <= +%s/s%s", formatNumber(val), formatIncome(val)),
            Type    = "Success",
            Duration = 3
        })
    else
        Library:Notify({
            Title   = "Max Income Auto Sell Diset 💰",
            Content = "Bebas / Tanpa batas income (Sesuai Rarity saja)",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

SellSec:AddInput({
    Name = "⚖️ Jual Item dengan Berat di Bawah (Max Berat)",
    Placeholder = Config.AutoSellMaxWeight > 0 and string.format("%s kg", formatNumber(Config.AutoSellMaxWeight)) or "Cth: 100k, 272058, 1M, 0 = Bebas",
    Tooltip = "Item dengan berat di bawah angka ini akan otomatis dijual"
}, function(text)
    local val = ParseWeightInput(text)
    Config.AutoSellMaxWeight = val
    if val > 0 then
        Library:Notify({
            Title   = "Max Berat Auto Sell Diset",
            Content = string.format("Jual item dengan berat <= %s kg", formatNumber(val)),
            Type    = "Success",
            Duration = 3
        })
    else
        Config.AutoSellMaxWeight = 0
        Library:Notify({
            Title   = "Max Berat Auto Sell Diset",
            Content = "Bebas / Tanpa batas berat",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

SellSec:AddToggle({
    Name = "⭐ Jangan Jual Item Favorit (Favorite Protection)",
    Default = Config.AutoSellIgnoreFavorites,
    Flag = "AutoSellProtectFavToggle",
    Tooltip = "Proteksi keamanan: Item yang ditandai bintang ⭐ Favorite TIDAK AKAN PERNAH DIJUAL"
}, function(val)
    Config.AutoSellIgnoreFavorites = val
end)

SellSec:AddToggle({
    Name = "🌈 Kunci Mutasi Rainbow (Jangan Jual Rainbow)",
    Default = Config.AutoSellProtectRainbow,
    Flag = "AutoSellProtectRainbowToggle",
    Tooltip = "Proteksi mutlak: Item dengan mutasi Rainbow TIDAK AKAN PERNAH DIJUAL"
}, function(val)
    Config.AutoSellProtectRainbow = val
end)

SellSec:AddToggle({
    Name = "👑 Kunci Rarity Tier Dewa (Divine, Eternal, Secret Lock)",
    Default = Config.AutoSellProtectGodTier,
    Flag = "AutoSellProtectGodTierToggle",
    Tooltip = "Proteksi mutlak: Item tier Divine, Eternal, Secret, BrainrotGod TIDAK AKAN PERNAH DIJUAL"
}, function(val)
    Config.AutoSellProtectGodTier = val
end)

SellSec:AddSlider({
    Name = "⏱️ Jeda Antar Penjualan (Detik)",
    Min = 0.1,
    Max = 3.0,
    Default = Config.AutoSellDelay,
    Step = 0.1,
    Flag = "AutoSellDelaySlider",
    Tooltip = "Waktu jeda antar remote sell dipanggil"
}, function(val)
    Config.AutoSellDelay = val
end)

local SellActionSec = SellTab:AddSection("⚡ Aksi & Background Loop Auto Sell")

local SellStatusPara = SellActionSec:AddParagraph("Status Auto Sell", "Memindai item yang cocok untuk dijual...")

SellActionSec:AddToggle({
    Name = "🔁 Aktifkan Auto Sell Otomatis (Background Loop)",
    Default = Config.AutoSellLoop,
    Flag = "AutoSellLoopToggle",
    Tooltip = "Terus memindai tas dan otomatis menjual seluruh item sampah / item yang lolos kriteria sell"
}, function(Value)
    StealAnEggTrade.SetAutoSell(Value)
    if Value then
        Library:Notify({
            Title   = "Auto Sell Aktif 💰",
            Content = "Loop Auto Sell berjalan di latar belakang!",
            Type    = "Success",
            Duration = 3
        })
    else
        Library:Notify({
            Title   = "Auto Sell Dinonaktifkan",
            Content = "Loop Auto Sell telah dimatikan.",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

SellActionSec:AddButton({
    Name = "🗑️ Jual Semua Item Sesuai Kriteria Sell (1x Batch)",
    Tooltip = "Menjual sekaligus semua item di tas yang saat ini cocok dengan kriteria Auto Sell"
}, function()
    local ok, countOrMsg = StealAnEggTrade.SellFilteredBatch()
    if ok then
        Library:Notify({
            Title   = "Menjual Item 💰",
            Content = string.format("Sedang memproses penjualan %d item...", countOrMsg),
            Type    = "Success",
            Duration = 3
        })
    else
        Library:Notify({
            Title   = "Peringatan",
            Content = tostring(countOrMsg),
            Type    = "Warning",
            Duration = 3
        })
    end
end)

SellActionSec:AddButton({
    Name = "✋ Jual Item yang Sedang Dipegang di Tangan (1x)",
    Tooltip = "Menjual item yang saat ini sedang aktif dipegang oleh karakter"
}, function()
    local character = LocalPlayer.Character
    local heldTool = character and character:FindFirstChildOfClass("Tool")
    if not heldTool then
        Library:Notify({
            Title   = "Peringatan",
            Content = "Pegang item di tangan terlebih dahulu!",
            Type    = "Warning",
            Duration = 3
        })
        return
    end
    
    local ok, msg = StealAnEggTrade.SellItem(heldTool)
    if ok then
        Library:Notify({
            Title   = "Item Terjual 💰",
            Content = "Berhasil menjual item yang sedang dipegang!",
            Type    = "Success",
            Duration = 3
        })
    else
        Library:Notify({
            Title   = "Gagal Menjual",
            Content = "Error: " .. tostring(msg),
            Type    = "Error",
            Duration = 3.5
        })
    end
end)


-- ---------------------------------------------------------
-- TAB 5: 📺 LIVE SCREEN LOG & TRADE HISTORY STREAM
-- ---------------------------------------------------------
local StatsTab = Window:MakeTab("📺")

-- Section 1: 📊 Real-Time Trade & Value Summary
local LiveSummarySec = StatsTab:AddSection("📊 Ringkasan Nilai & Transaksi Real-Time")
local LiveSummaryPara = LiveSummarySec:AddParagraph("📊 Ringkasan Nilai & Transaksi", "Memuat data aktivitas transaksi...")

-- Section 2: 📺 Live Transaction Feed & History Screen
local LiveLogSec = StatsTab:AddSection("📺 Live Screen Log & History Feed")

local function GetFilteredLogs()
    if currentLogFilter == "All" or currentLogFilter == "Semua Log (All)" or currentLogFilter == "All Logs" then
        return TradeHistoryList
    end
    local res = {}
    for _, item in ipairs(TradeHistoryList) do
        if currentLogFilter:find("Terkirim") or currentLogFilter:find("Sent") then
            if item.Action == "SENT" then table.insert(res, item) end
        elseif currentLogFilter:find("Diterima") or currentLogFilter:find("Received") then
            if item.Action == "RECEIVED" then table.insert(res, item) end
        elseif currentLogFilter:find("Terjual") or currentLogFilter:find("Sold") then
            if item.Action == "SOLD" then table.insert(res, item) end
        elseif currentLogFilter:find("Equip") then
            if item.Action == "EQUIPPED" then table.insert(res, item) end
        end
    end
    return res
end

local LogFilterDropdown = LiveLogSec:AddDropdown({
    Name = "Filter Kategori Log",
    Options = {"Semua Log (All)", "📤 Terkirim (Sent Only)", "📥 Diterima (Received Only)", "💰 Terjual (Sold Only)", "⚔️ Di-Equip (Equip Only)"},
    Default = "Semua Log (All)",
    Flag = "LogCategoryDropdown",
    Tooltip = "Pilih jenis event transaksi yang ingin ditampilkan pada layar log"
}, function(selected)
    currentLogFilter = selected or "Semua Log (All)"
    currentLogPage = 1
    if StealAnEggTrade.RefreshLogScreen then
        StealAnEggTrade.RefreshLogScreen()
    end
end)

local LogPageIndicatorPara = LiveLogSec:AddParagraph("Navigasi Log", "Halaman 1 dari 1 (Total 0 Riwayat)")

-- 5 Pre-allocated slot paragraphs for transaction cards
local LogSlotParagraphs = {}
for i = 1, LOGS_PER_PAGE do
    local slotPara = LiveLogSec:AddParagraph(string.format("Transaction Card #%d", i), "Belum ada riwayat transaksi.")
    table.insert(LogSlotParagraphs, slotPara)
end

LiveLogSec:AddButton({
    Name = "◀️ Halaman Sebelumnya (Prev Page)",
    Tooltip = "Melihat riwayat transaksi di halaman sebelumnya"
}, function()
    local filtered = GetFilteredLogs()
    local totalPages = math.max(1, math.ceil(#filtered / LOGS_PER_PAGE))
    if currentLogPage > 1 then
        currentLogPage = currentLogPage - 1
        if StealAnEggTrade.RefreshLogScreen then StealAnEggTrade.RefreshLogScreen() end
    else
        Library:Notify({
            Title   = "Navigasi Log",
            Content = "Sudah berada di halaman pertama.",
            Type    = "Info",
            Duration = 2
        })
    end
end)

LiveLogSec:AddButton({
    Name = "▶️ Halaman Selanjutnya (Next Page)",
    Tooltip = "Melihat riwayat transaksi di halaman berikutnya"
}, function()
    local filtered = GetFilteredLogs()
    local totalPages = math.max(1, math.ceil(#filtered / LOGS_PER_PAGE))
    if currentLogPage < totalPages then
        currentLogPage = currentLogPage + 1
        if StealAnEggTrade.RefreshLogScreen then StealAnEggTrade.RefreshLogScreen() end
    else
        Library:Notify({
            Title   = "Navigasi Log",
            Content = "Sudah berada di halaman terakhir.",
            Type    = "Info",
            Duration = 2
        })
    end
end)


-- Section 3: 🛠️ Log Utilities & Export
local LogUtilSec = StatsTab:AddSection("🛠️ Log Utilities & Export")

LogUtilSec:AddButton({
    Name = "📋 Salin Seluruh History Log ke Clipboard (Export Text)",
    Tooltip = "Menyalin seluruh catatan riwayat transaksi ke clipboard untuk dibagikan ke Discord / Notepad"
}, function()
    if #TradeHistoryList == 0 then
        Library:Notify({
            Title   = "Log Kosong",
            Content = "Belum ada riwayat transaksi yang tercatat.",
            Type    = "Warning",
            Duration = 2.5
        })
        return
    end
    
    local exportLines = {
        "================================================================",
        "SIGMA HUB | STEAL AN EGG - LIVE SCREEN TRADE HISTORY LOG",
        string.format("Waktu Export : %s", os.date and os.date("%Y-%m-%d %X") or "Live"),
        string.format("Total Sent   : %d Items (Income: +%s | Harga: 🏷️ %s | Berat: ⚖️ %s)",
            LiveLogStats.TotalSent,
            formatIncome(LiveLogStats.TotalSentIncome),
            formatNumber(LiveLogStats.TotalSentPrice),
            formatNumber(LiveLogStats.TotalSentWeight) .. " kg"
        ),
        string.format("Total Received: %d Items | Sold: %d Items | Equipped: %d Assets",
            LiveLogStats.TotalReceived,
            LiveLogStats.TotalSold,
            LiveLogStats.TotalEquipped
        ),
        "================================================================"
    }
    
    for idx, entry in ipairs(TradeHistoryList) do
        local line = string.format("[%s] [%s] Target: %s | %s [%s] (%s) | Berat: %s kg | Income: +%s | Harga: %s | UID: %s",
            entry.Timestamp,
            entry.Action,
            entry.Target,
            entry.DisplayName,
            entry.Rarity,
            entry.Mutation,
            formatNumber(entry.Weight),
            formatIncome(entry.Income),
            formatNumber(entry.Price),
            entry.UID
        )
        table.insert(exportLines, line)
    end
    table.insert(exportLines, "================================================================")
    
    local fullText = table.concat(exportLines, "\n")
    local ok = CopyToClipboard(fullText)
    if ok then
        Library:Notify({
            Title   = "Log Disalin! 📋",
            Content = string.format("Berhasil menyalin %d catatan transaksi ke clipboard!", #TradeHistoryList),
            Type    = "Success",
            Duration = 3.5
        })
    end
end)

LogUtilSec:AddButton({
    Name = "🔄 Refresh Layar Log",
    Tooltip = "Memperbarui tampilan layar log transaksi secara instan"
}, function()
    if StealAnEggTrade.RefreshLogScreen then StealAnEggTrade.RefreshLogScreen() end
    Library:Notify({
        Title   = "Layar Log Diperbarui 🔄",
        Content = string.format("%d Total Riwayat Transaksi", #TradeHistoryList),
        Type    = "Info",
        Duration = 2
    })
end)

LogUtilSec:AddButton({
    Name = "🗑️ Bersihkan / Reset Riwayat Log",
    Tooltip = "Menghapus seluruh riwayat transaksi dan mereset statistik ke 0"
}, function()
    table.clear(TradeHistoryList)
    LiveLogStats.TotalSent = 0
    LiveLogStats.TotalSentIncome = 0
    LiveLogStats.TotalSentWeight = 0
    LiveLogStats.TotalSentPrice = 0
    LiveLogStats.TotalReceived = 0
    LiveLogStats.TotalSold = 0
    LiveLogStats.TotalEquipped = 0
    LiveLogStats.TotalFail = 0
    TradeStats.TotalSent = 0
    TradeStats.SuccessCount = 0
    TradeStats.FailCount = 0
    TradeStats.AcceptedCount = 0
    TradeStats.SellCount = 0
    TradeStats.EquipCount = 0
    TradeStats.LastItemName = "-"
    TradeStats.LastSoldName = "-"
    TradeStats.LastEquippedName = "-"
    currentLogPage = 1
    if StealAnEggTrade.RefreshLogScreen then StealAnEggTrade.RefreshLogScreen() end
    Library:Notify({
        Title   = "Log Dibersihkan 🗑️",
        Content = "Seluruh riwayat transaksi & statistik berhasil di-reset!",
        Type    = "Success",
        Duration = 2.5
    })
end)

function StealAnEggTrade.RefreshLogScreen()
    pcall(function()
        local filtered = GetFilteredLogs()
        local totalItems = #filtered
        local totalPages = math.max(1, math.ceil(totalItems / LOGS_PER_PAGE))
        if currentLogPage > totalPages then currentLogPage = totalPages end
        if currentLogPage < 1 then currentLogPage = 1 end
        
        -- Update Summary paragraph
        if LiveSummaryPara then
            local sumText = string.format(
                "<font color=\"#00FF88\"><b>📤 %d Terkirim</b></font> (💰 %s | 🏷️ %s | ⚖️ %s)\n" ..
                "<font color=\"#00E5FF\"><b>📥 %d Diterima</b></font>  •  <font color=\"#FFAA00\"><b>💰 %d Terjual</b></font>  •  <font color=\"#BF55EC\"><b>⚔️ %d Di-Equip</b></font>\n" ..
                "Aktivitas Terakhir: <b>%s</b>",
                LiveLogStats.TotalSent,
                formatIncome(LiveLogStats.TotalSentIncome),
                formatNumber(LiveLogStats.TotalSentPrice),
                formatNumber(LiveLogStats.TotalSentWeight) .. " kg",
                LiveLogStats.TotalReceived,
                LiveLogStats.TotalSold,
                LiveLogStats.TotalEquipped,
                TradeStats.LastItemName ~= "-" and (TradeStats.LastItemName .. " (Sukses)") or "Belum ada transaksi"
            )
            LiveSummaryPara:Set("📊 Ringkasan Nilai & Transaksi", sumText)
        end
        
        -- Update Page Indicator
        if LogPageIndicatorPara then
            LogPageIndicatorPara:Set("Navigasi Log", string.format("Halaman %d dari %d (Total %d Riwayat)", currentLogPage, totalPages, totalItems))
        end
        
        -- Render 5 log cards
        local startIdx = (currentLogPage - 1) * LOGS_PER_PAGE + 1
        for slot = 1, LOGS_PER_PAGE do
            local itemIdx = startIdx + slot - 1
            local entry = filtered[itemIdx]
            local p = LogSlotParagraphs[slot]
            if p then
                if entry then
                    local title = string.format("#%d [%s] %s ➔ @%s", itemIdx, entry.Timestamp, entry.Action, entry.Target)
                    local desc = FormatLogEntryRichText(entry)
                    p:Set(title, desc)
                else
                    p:Set(string.format("Transaction Slot #%d", itemIdx), "<font color=\"#666666\">[Kosong - Menunggu Aktivitas Trade Selanjutnya]</font>")
                end
            end
        end
    end)
end

-- Inisialisasi awal layar log
task.defer(function()
    if StealAnEggTrade.RefreshLogScreen then
        StealAnEggTrade.RefreshLogScreen()
    end
end)


-- ---------------------------------------------------------
-- TAB 6: 🌐 SERVER UTILITIES (JOB ID, UPTIME & SMART DEEP HOP)
-- ---------------------------------------------------------
local ServerTab = Window:MakeTab("🌐")
local ServerInfoSec = ServerTab:AddSection("Informasi Server Saat Ini")

local ServerJobIdPara  = ServerInfoSec:AddParagraph("Job ID Server", tostring(game.JobId))
local ServerUptimePara = ServerInfoSec:AddParagraph("Uptime Server Ini", formatUptime(workspace.DistributedGameTime))
local ServerPlayerPara = ServerInfoSec:AddParagraph("Jumlah Player", string.format("%d / %d Players", #Players:GetPlayers(), Players.MaxPlayers))

ServerInfoSec:AddButton({
    Name = "📋 Salin Job ID Server (Copy Job ID)",
    Tooltip = "Menyalin Job ID server saat ini ke clipboard keyboard"
}, function()
    local ok = CopyToClipboard(game.JobId)
    if ok then
        Library:Notify({
            Title   = "Job ID Disalin! 📋",
            Content = "Job ID berhasil disalin ke clipboard: \n" .. tostring(game.JobId),
            Type    = "Success",
            Duration = 3.5
        })
    else
        Library:Notify({
            Title   = "Job ID",
            Content = "Job ID: " .. tostring(game.JobId),
            Type    = "Info",
            Duration = 4
        })
    end
end)

ServerInfoSec:AddButton({
    Name = "📜 Salin Script Auto Teleport ke Server Ini",
    Tooltip = "Menyalin satu baris script Luau untuk langsung join ke server ini dari akun lain"
}, function()
    local code = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)', game.PlaceId, game.JobId)
    local ok = CopyToClipboard(code)
    if ok then
        Library:Notify({
            Title   = "Script Disalin! 📜",
            Content = "Script teleport berhasil disalin ke clipboard!",
            Type    = "Success",
            Duration = 3.5
        })
    end
end)

local TeleportSec = ServerTab:AddSection("🚀 Pindah Server / Smart Server Hop")

TeleportSec:AddButton({
    Name = "❄️ Smart Hop (Cari Server Sepi Dingin / Deep Scan)",
    Tooltip = "Memindai hingga 500 server untuk mencari server 1-2 player di bagian ekor matchmaker (yang sepinya tahan lama)"
}, function()
    Library:Notify({
        Title   = "Deep Scan Server Sepi... ❄️",
        Content = "Sedang memindai hingga 500 server mencari server sepi yang matchmaking-nya dingin...",
        Type    = "Info",
        Duration = 4.0
    })
    StealAnEggTrade.HopSmartSmallServer()
end)

TeleportSec:AddButton({
    Name = "🔀 Server Hop Acak (Random Server)",
    Tooltip = "Pindah ke server publik lain secara acak"
}, function()
    Library:Notify({
        Title   = "Server Hop Acak",
        Content = "Mencari server publik lain...",
        Type    = "Info",
        Duration = 2.5
    })
    StealAnEggTrade.ServerHop()
end)

TeleportSec:AddButton({
    Name = "🔄 Rejoin Server Saat Ini",
    Tooltip = "Menghubungkan ulang ke server saat ini"
}, function()
    Library:Notify({
        Title   = "Rejoining",
        Content = "Sedang menghubungkan ulang ke server...",
        Type    = "Info",
        Duration = 2.5
    })
    StealAnEggTrade.Rejoin()
end)

local ManualTpSec = ServerTab:AddSection("🎯 Teleport ke Job ID Tertentu")

local targetJobInput = ""
ManualTpSec:AddInput({
    Name = "🎯 Masukkan Target Job ID",
    Placeholder = "Tempel / Ketik Job ID server tujuan di sini...",
    Tooltip = "Job ID server tujuan yang ingin Anda kunjungi"
}, function(text)
    targetJobInput = text or ""
end)

ManualTpSec:AddButton({
    Name = "🚀 Teleport ke Target Job ID",
    Tooltip = "Pindah ke server sesuai Job ID yang dimasukkan"
}, function()
    if targetJobInput == "" then
        Library:Notify({
            Title   = "Peringatan",
            Content = "Silakan masukkan Job ID target terlebih dahulu!",
            Type    = "Warning",
            Duration = 3
        })
        return
    end
    
    Library:Notify({
        Title   = "Memulai Teleport",
        Content = "Menghubungkan ke Server: " .. targetJobInput,
        Type    = "Info",
        Duration = 3
    })
    
    local ok, err = StealAnEggTrade.TeleportToJobId(targetJobInput)
    if not ok then
        Library:Notify({
            Title   = "Gagal Teleport",
            Content = "Error: " .. tostring(err),
            Type    = "Error",
            Duration = 4
        })
    end
end)


-- ==========================================================
-- ⚡ [OPTIMALISASI ULTRA] SINGLE UNIFIED BACKGROUND STATE TICKER
-- Menggabungkan seluruh pembaruan status UI (Tab 2, 3, 4, 5, 6)
-- ke dalam 1 thread efisien dengan interval 2.0 detik.
-- ==========================================================
task.spawn(function()
    while getgenv().CurrentTradeScriptID == scriptId do
        pcall(function()
            local scan = StealAnEggTrade.ScanInventory(currentInventorySort, currentInventorySearch, currentInventoryMinIncome)
            local tools = scan.Tools or StealAnEggTrade.GetAllTools()
            
            -- 1. Tab 🎒: Item List & Backpack Summary (English)
            if InvItemListPara then
                InvItemListPara:Set("📋 Item List", BuildItemListText(scan, currentInvPage))
            end
            if InvCountPara and InvWeightPara and InvIncomePara and InvPricePara and InvBestPara and InvHeavyPara then
                InvCountPara:Set("Total Items", string.format("%d Items • %d Favorites ⭐", scan.Count, scan.FavoriteCount))
                InvWeightPara:Set("Total Weight", string.format("%s kg (%.2fM kg)", formatNumber(scan.TotalWeight), scan.TotalWeight / 1000000))
                InvIncomePara:Set("Total Passive Income", string.format("%s 💰", formatIncome(scan.TotalIncome)))
                if Config.PriceRatePer100M and Config.PriceRatePer100M > 0 then
                    InvPricePara:Set("Total Estimated Value", string.format("🏷️ %s (Rate: %s / 100M)", FormatPriceDisplay(scan.TotalPrice or 0), formatNumber(Config.PriceRatePer100M)))
                else
                    InvPricePara:Set("Total Estimated Value", "Nonaktif (Kolom Harga Kosong)")
                end
                InvBestPara:Set("👑 Highest Value Item", (scan.BestValuePet or scan.BestPet) and (scan.BestValuePet or scan.BestPet).OptionString or "-")
                InvHeavyPara:Set("⚖️ Heaviest Item", scan.HeaviestPet and string.format("%s [%s] (%s kg)", scan.HeaviestPet.DisplayName, scan.HeaviestPet.BaseMutation, formatNumber(scan.HeaviestPet.Weight)) or "-")
            end
            if EquipStatusPara then
                local candidates = StealAnEggTrade.GetEquipCandidates()
                local limit = Config.AutoEquipMaxAmount or 5
                local statusDesc = string.format("Status: %s\nMode: %s\nLimit Equip: %d Asset Teratas (Cocok: %d di Tas)\nLast Equipped: %s\nTotal Equipped Sesi Ini: %d Asset ⚔️",
                    Config.AutoEquipAsset and "🟢 Active (Looping)" or "⚪ Disabled",
                    tostring(Config.AutoEquipMode),
                    limit,
                    #candidates,
                    Config.LastEquippedAssetName and string.format("%s [UID: %s]", Config.LastEquippedAssetName, tostring(Config.LastEquippedAssetUID or "-")) or "-",
                    TradeStats.EquipCount or 0
                )
                EquipStatusPara:Set("Status Auto Equip", statusDesc)
            end
            
            -- 2. Tab 🎯: Hitung Item Cocok Trade Filter
            if FilterMatchPara then
                local tradeMatchCount = 0
                for _, t in ipairs(tools) do
                    if StealAnEggTrade.MatchesFilter(t, Config) then
                        tradeMatchCount = tradeMatchCount + 1
                    end
                end
                
                local minWStr = Config.MinWeight > 0 and string.format("%.2f Juta (%s kg)", Config.MinWeight / 1000000, formatNumber(Config.MinWeight)) or "Bebas"
                local maxWStr = Config.MaxWeight > 0 and string.format("%.2f Juta (%s kg)", Config.MaxWeight / 1000000, formatNumber(Config.MaxWeight)) or "Bebas"
                local minIncStr = Config.MinIncome > 0 and string.format("+%s/s%s", formatNumber(Config.MinIncome), formatIncome(Config.MinIncome)) or "Bebas"
                local maxIncStr = Config.MaxIncome > 0 and string.format("+%s/s%s", formatNumber(Config.MaxIncome), formatIncome(Config.MaxIncome)) or "Bebas"
                local activeId, activeName = GetActiveWhitelistTarget()
                local targetDisplay = activeName and string.format("%s (ID: %s)", activeName, tostring(activeId)) or "Belum Ada Target Whitelist di Server"
                
                local statusDesc = string.format("Item Cocok: %d dari %d Item\nTarget Whitelist: %s\nItem: %s | Mutasi: %s\nRarity: %s\nMin Berat: %s | Max: %s\nMin Income: %s | Max: %s",
                    tradeMatchCount,
                    #tools,
                    targetDisplay,
                    tostring(Config.FilterItem),
                    tostring(Config.FilterMutation),
                    tostring(Config.FilterRarity),
                    minWStr,
                    maxWStr,
                    minIncStr,
                    maxIncStr
                )
                FilterMatchPara:Set("Status Filter", statusDesc)
            end
            
            -- 3. Tab 💰: Hitung Item Cocok Auto Sell
            if SellStatusPara then
                local sellMatchCount = 0
                for _, t in ipairs(tools) do
                    if StealAnEggTrade.MatchesSellFilter(t, Config) then
                        sellMatchCount = sellMatchCount + 1
                    end
                end
                
                local maxSellIncStr = Config.AutoSellMaxIncome > 0 and string.format("<= +%s/s%s", formatNumber(Config.AutoSellMaxIncome), formatIncome(Config.AutoSellMaxIncome)) or "Bebas"
                local maxSellWStr   = Config.AutoSellMaxWeight > 0 and string.format("<= %.2f Juta kg", Config.AutoSellMaxWeight / 1e6) or "Bebas"
                
                local sellDesc = string.format("Item Cocok Dijual: %d dari %d Item di Tas\nRarity Target: %s\nBatas Max Income: %s\nBatas Max Berat: %s\nProteksi: %s Favorit | %s Rainbow | %s Tier Dewa\nTotal Item Terjual Sesi Ini: %d Item 💰",
                    sellMatchCount,
                    #tools,
                    tostring(Config.AutoSellRarities),
                    maxSellIncStr,
                    maxSellWStr,
                    Config.AutoSellIgnoreFavorites and "⭐ Kunci" or "❌ Bebas",
                    Config.AutoSellProtectRainbow and "🌈 Kunci" or "❌ Bebas",
                    Config.AutoSellProtectGodTier and "👑 Kunci" or "❌ Bebas",
                    TradeStats.SellCount or 0
                )
                SellStatusPara:Set("Status Auto Sell", sellDesc)
            end
            
            -- 4. Tab 📺: Live Screen Log & Summary Refresh
            if StealAnEggTrade.RefreshLogScreen then
                StealAnEggTrade.RefreshLogScreen()
            end
            
            -- 5. Tab 🌐: Server Info & Uptime
            if ServerJobIdPara and ServerUptimePara and ServerPlayerPara then
                ServerJobIdPara:Set("Job ID Server", tostring(game.JobId))
                ServerUptimePara:Set("Uptime Server Ini", formatUptime(workspace.DistributedGameTime))
                ServerPlayerPara:Set("Jumlah Player", string.format("%d / %d Players di Server", #Players:GetPlayers(), Players.MaxPlayers))
            end
        end)
        task.wait(2.0)
    end
end)


Library:Notify({
    Title   = "Sigma Hub Loaded!",
    Content = string.format("Akun: %s (%s)", currentUsername, Config.ProfileRole or "Active"),
    Type    = "Success",
    Duration = 3.5
})

return StealAnEggTrade
