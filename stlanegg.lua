-- ==========================================================
-- STEAL AN EGG - AUTO TRADE & GIFTING SYSTEM (SIGMA UI V4)
-- Game: Steal an Egg (Roblox)
-- Framework: Sigma UI Library - V4 Ultimate Edition
-- Features: Auto Gifting, Backpack Scanner, Filtered Trade (Multi-Rarity, Weight, Mutation), Auto Accept, Server Tab (Job ID, Teleport & Low Player Server Hop)
-- ==========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- ==========================================================
-- 👤 [KONFIGURASI PER-PLAYER / PROFIL AKUN]
-- Pengaturan otomatis disesuaikan berdasarkan Username akun yang sedang login:
-- ==========================================================
local ACCOUNT_PROFILES = {
    -- [PROFIL 1] Khusus untuk akun "szeshuro" (Receiver / Penerima)
    -- Fitur yang aktif HANYA Auto Accept Gift saja
    ["szeshuro"] = {
        Role                = "Receiver (Hanya Auto Accept)",
        AutoAcceptGift      = true,             -- true = Otomatis aktifkan Auto Accept Gift
        OnlyAcceptTarget    = false,            -- false = Terima gift dari siapa saja
        AcceptDelay         = 0.1,              -- Jeda waktu sebelum respon accept (detik)
        AutoTradeLoop       = false,            -- false = Matikan trade sending
        AutoTradeFilterLoop = false,            -- false = Matikan filter trade sending
    },
    
    -- [PROFIL 2] Profil Default / Pengirim (Sender untuk akun lain / Alt)
    -- Otomatis hanya mengirim item dengan Rarity: Divine, Eternal, Secret
    ["DEFAULT"] = {
        Role                = "Sender (Pengirim ke szeshuro)",
        TargetUsername      = "szeshuro",       -- Otomatis kirim ke akun szeshuro
        TargetPlayerId      = nil,              -- Diisi otomatis lewat auto-resolve
        AutoTradeLoop       = false,            -- Trade semua tool
        AutoTradeFilterLoop = true,             -- true = Langsung jalankan Trade By Filter
        DelayBetweenGifts   = 0.5,              -- Jeda antar gift (detik)
        FilterItem          = "All Items",      -- Filter jenis item
        FilterMutation      = "All Mutations",  -- Filter mutasi (Cth: "Golden", "Normal", "All Mutations")
        FilterRarity        = "Divine, Eternal, Secret", -- 👈 Multi-Rarity Filter (Divine, Eternal, Secret) atau "All Rarities"
        MinWeightInMillions = 0,                -- Minimal berat (0 = Bebas / Kirim seluruh item Divine, Eternal, Secret)
        MaxWeightInMillions = 0,                -- Tanpa batas maksimal (0 = Bebas)
        IgnoreFavorites     = false,            -- Jangan abaikan barang favorit
        OnlyFavorites       = false,            -- Jangan batasi hanya favorit
        AutoAcceptGift      = false,            -- Matikan auto accept di akun pengirim
    }
}

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
getgenv().CurrentTradeScriptID = scriptId

-- Built-in Anti-AFK System
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
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
    local nameLower = nameStr:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == nameLower or p.DisplayName:lower() == nameLower then
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

local RarityTableToName = {}
local ItemRarityDatabase = {}
local isRarityLoaded = false

local function LoadGameDirectoryRarities()
    if isRarityLoaded then return end
    
    -- 1. Load Rarity Module (ReplicatedStorage.Directory.Rarity)
    pcall(function()
        local dir = ReplicatedStorage:FindFirstChild("Directory")
        local rarityMod = dir and (dir:FindFirstChild("Rarity") or dir:FindFirstChild("Rarities"))
        if not rarityMod then
            for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                if desc:IsA("ModuleScript") and (desc.Name == "Rarity" or desc.Name == "Rarities") then
                    rarityMod = desc
                    break
                end
            end
        end
        
        if rarityMod then
            local ok, rarityModuleData = pcall(require, rarityMod)
            if ok and type(rarityModuleData) == "table" then
                local raritiesTbl = rarityModuleData.Rarities or rarityModuleData
                if type(raritiesTbl) == "table" then
                    for rarityName, rarityObj in pairs(raritiesTbl) do
                        local rNameStr = tostring(rarityName)
                        if type(rarityObj) == "table" then
                            RarityTableToName[rarityObj] = rNameStr
                            if rarityObj.Name then RarityTableToName[rarityObj] = tostring(rarityObj.Name) end
                            if rarityObj.DisplayName then RarityTableToName[rarityObj] = tostring(rarityObj.DisplayName) end
                        end
                        
                        local exists = false
                        for _, existing in ipairs(KNOWN_RARITIES) do
                            if existing:lower() == rNameStr:lower() then exists = true; break end
                        end
                        if not exists then
                            table.insert(KNOWN_RARITIES, rNameStr)
                        end
                    end
                end
            end
        end
    end)

    -- 2. Scan seluruh Modul Item di ReplicatedStorage.Directory
    local itemCount = 0
    pcall(function()
        local dir = ReplicatedStorage:FindFirstChild("Directory") or ReplicatedStorage:FindFirstChild("Library")
        if dir then
            for _, desc in ipairs(dir:GetDescendants()) do
                if desc:IsA("ModuleScript") and desc.Name ~= "Rarity" and desc.Name ~= "Rarities" and desc.Name ~= "Pipeline" and desc.Name ~= "Interface" and desc.Name ~= "Constants" then
                    local ok, itemConfig = pcall(require, desc)
                    if ok and type(itemConfig) == "table" then
                        local rStr = nil
                        
                        if type(itemConfig.Rarity) == "string" then
                            rStr = itemConfig.Rarity
                        elseif type(itemConfig.Rarity) == "table" then
                            rStr = RarityTableToName[itemConfig.Rarity] 
                                or itemConfig.Rarity.Name 
                                or itemConfig.Rarity.DisplayName
                                or itemConfig.Rarity.Rarity
                            
                            if not rStr then
                                for obj, name in pairs(RarityTableToName) do
                                    if obj == itemConfig.Rarity then
                                        rStr = name
                                        break
                                    end
                                end
                            end
                        end
                        
                        if rStr then
                            local rStrClean = tostring(rStr)
                            local modName = desc.Name:lower()
                            ItemRarityDatabase[modName] = rStrClean
                            
                            if itemConfig.DisplayName then
                                ItemRarityDatabase[tostring(itemConfig.DisplayName):lower()] = rStrClean
                            end
                            if itemConfig.Name then
                                ItemRarityDatabase[tostring(itemConfig.Name):lower()] = rStrClean
                            end
                            if itemConfig.Category then
                                ItemRarityDatabase[tostring(itemConfig.Category):lower()] = rStrClean
                            end
                            itemCount = itemCount + 1
                        end
                    end
                end
            end
        end
    end)
    
    if itemCount > 0 then
        isRarityLoaded = true
        print(string.format("[StealAnEgg] Berhasil me-load %d Definisi Item Rarity dari ReplicatedStorage.Directory!", itemCount))
    end
end

LoadGameDirectoryRarities()


-- ==========================================================
-- [SECTION 1] STATE & BACKEND CONFIGURATION
-- ==========================================================

local Config = {
    TargetPlayerId      = SCRIPT_CONFIG.TargetPlayerId,
    TargetPlayerName    = SCRIPT_CONFIG.TargetUsername or "",
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
    SelectedInvTool     = nil,
    ProfileRole         = SCRIPT_CONFIG.ProfileRole
}

local TradeStats = {
    TotalSent = 0,
    SuccessCount = 0,
    FailCount = 0,
    AcceptedCount = 0,
    LastItemName = "-"
}

local LastGiftRequest = {
    SenderName = "-",
    SenderId = nil,
    ItemName = "-",
    RequestUID = nil,
    Time = 0
}

--- Resolves Target Player ID (Synchronous & Background)
local function ResolveTargetId()
    if Config.TargetPlayerId then return Config.TargetPlayerId end
    if not Config.TargetPlayerName or Config.TargetPlayerName == "" then return nil end
    
    local found = FindPlayerByName(Config.TargetPlayerName)
    if found then
        Config.TargetPlayerId = found.UserId
        print(string.format("[StealAnEgg] Target '%s' ditemukan di server -> UserID: %d", found.Name, found.UserId))
        return found.UserId
    end
    
    local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(Config.TargetPlayerName) end)
    if ok and id then
        Config.TargetPlayerId = id
        print(string.format("[StealAnEgg] Target '%s' di-resolve via API -> UserID: %d", Config.TargetPlayerName, id))
        return id
    end
    
    return nil
end

task.spawn(ResolveTargetId)

-- Cleanup handler
getgenv().CancelStealAnEggTrade = function()
    Config.AutoTradeLoop = false
    Config.AutoTradeFilterLoop = false
    Config.AutoAcceptGift = false
end


-- ==========================================================
-- [SECTION 2] PURE FUNCTIONS & PROGRAMMATIC API
-- ==========================================================

local StealAnEggTrade = {}

function StealAnEggTrade.GetGiftingRemote()
    local network = ReplicatedStorage:FindFirstChild("Network")
    if network then
        return network:FindFirstChild("Gifting: Send Request")
    end
    return nil
end

function StealAnEggTrade.GetGiftingResponseRemote()
    local network = ReplicatedStorage:FindFirstChild("Network")
    if network then
        return network:FindFirstChild("Gifting: Response")
    end
    return nil
end

function StealAnEggTrade.GetGiftingRequestRemote()
    local network = ReplicatedStorage:FindFirstChild("Network")
    if network then
        return network:FindFirstChild("Gifting: Request")
    end
    return nil
end

function StealAnEggTrade.GetToolRarity(tool)
    if not tool or not tool:IsA("Tool") then return "Normal" end
    
    if not isRarityLoaded then
        LoadGameDirectoryRarities()
    end
    
    local attrRarity = tool:GetAttribute("Rarity") or tool:GetAttribute("Tier") or tool:GetAttribute("ItemRarity") or tool:GetAttribute("RarityName")
    if attrRarity and tostring(attrRarity) ~= "" then
        return tostring(attrRarity)
    end
    
    local rVal = tool:FindFirstChild("Rarity") or tool:FindFirstChild("Tier")
    if rVal and rVal:IsA("ValueBase") and rVal.Value ~= "" then
        return tostring(rVal.Value)
    end
    
    local rawName = tool.Name
    local dispName = tostring(tool:GetAttribute("DisplayName") or ""):lower()
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
        return false, "Objek yang diberikan bukan Tool" 
    end
    
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if tool.Parent == character then
        return true, "Tool sudah aktif di tangan"
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
        return true, "Tool berhasil dipegang"
    else
        tool.Parent = character
        task.wait(0.2)
        return tool.Parent == character, "Tool force-parented"
    end
end

function StealAnEggTrade.GetToolInfo(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local name = tool.Name
    local dispName = tool:GetAttribute("DisplayName") or name
    local baseMutation = tool:GetAttribute("BaseMutation") or tool:GetAttribute("Mutations") or "Normal"
    local weight = tool:GetAttribute("Weight") or 0
    local category = tool:GetAttribute("Category") or dispName
    local uid = tool:GetAttribute("UID") or "-"
    local fav = tool:GetAttribute("Favorite") == true
    local itemType = tool:GetAttribute("ItemType") or "Asset"
    local rarity = StealAnEggTrade.GetToolRarity(tool)
    
    return {
        Instance = tool,
        Name = name,
        DisplayName = dispName,
        BaseMutation = tostring(baseMutation),
        Weight = tonumber(weight) or 0,
        Category = tostring(category),
        UID = tostring(uid),
        Favorite = fav,
        ItemType = tostring(itemType),
        Rarity = tostring(rarity)
    }
end

function StealAnEggTrade.GetAllTools()
    local tools = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    return tools
end

function StealAnEggTrade.ScanInventory()
    local tools = StealAnEggTrade.GetAllTools()
    local itemsByName = {}
    local uniqueNames = {"All Items"}
    local mutations = {"All Mutations"}
    local rarities = {"All Rarities", "Divine, Eternal, Secret"}
    local mutationSet = {}
    local raritySet = { ["Divine, Eternal, Secret"] = true }
    local totalWeight = 0
    local favoriteCount = 0
    local dropdownOptions = {}
    
    for _, tool in ipairs(tools) do
        local info = StealAnEggTrade.GetToolInfo(tool)
        if info then
            totalWeight = totalWeight + info.Weight
            if info.Favorite then
                favoriteCount = favoriteCount + 1
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
            
            local optStr = string.format("%s [%s] (%s) - %.1f kg%s", info.DisplayName, info.BaseMutation, info.Rarity, info.Weight, info.Favorite and " ⭐" or "")
            table.insert(dropdownOptions, optStr)
        end
    end
    
    for _, r in ipairs(KNOWN_RARITIES) do
        if not raritySet[r] and r ~= "All Rarities" then
            table.insert(rarities, r)
        end
    end
    
    if #dropdownOptions == 0 then
        table.insert(dropdownOptions, "Backpack Kosong")
    end
    
    return {
        Tools = tools,
        Count = #tools,
        ItemsByName = itemsByName,
        UniqueNames = uniqueNames,
        Mutations = mutations,
        Rarities = rarities,
        TotalWeight = totalWeight,
        FavoriteCount = favoriteCount,
        DropdownOptions = dropdownOptions
    }
end

local function CheckRarityMatch(itemRarity, filterRarity)
    if not filterRarity or filterRarity == "All Rarities" or filterRarity == "All" or filterRarity == "" then
        return true
    end
    
    local iRarityClean = tostring(itemRarity):lower():gsub("%s+", "")
    
    if type(filterRarity) == "table" then
        for _, r in ipairs(filterRarity) do
            if tostring(r):lower():gsub("%s+", "") == iRarityClean then
                return true
            end
        end
        return false
    end
    
    local filterStr = tostring(filterRarity):lower()
    if filterStr:find(",") then
        for part in string.gmatch(filterStr, "[^,]+") do
            local cleanPart = part:gsub("%s+", "")
            if cleanPart == iRarityClean then
                return true
            end
        end
        return false
    end
    
    return filterStr:gsub("%s+", "") == iRarityClean
end

function StealAnEggTrade.MatchesFilter(tool, filterConfig)
    filterConfig = filterConfig or Config
    if not tool or not tool:IsA("Tool") then return false end
    local info = StealAnEggTrade.GetToolInfo(tool)
    if not info then return false end
    
    if filterConfig.IgnoreFavorites and info.Favorite then
        return false
    end
    if filterConfig.OnlyFavorites and not info.Favorite then
        return false
    end
    
    if filterConfig.FilterItem and filterConfig.FilterItem ~= "All Items" and filterConfig.FilterItem ~= "" then
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
    
    return true, info
end

function StealAnEggTrade.SendGift(targetPlayerId, tool)
    local numericId = tonumber(targetPlayerId) or Config.TargetPlayerId or ResolveTargetId()
    if not numericId then
        return false, "Target Player belum ditentukan atau belum berada di server!"
    end
    
    if not tool then
        local character = LocalPlayer.Character
        if character then
            tool = character:FindFirstChildOfClass("Tool")
        end
    end
    
    if not tool or not tool:IsA("Tool") or not tool.Parent then
        return false, "Tidak ada Tool yang valid untuk dikirim!"
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
    if not targetPlayerObj and Config.TargetPlayerName and Config.TargetPlayerName ~= "" then
        targetPlayerObj = FindPlayerByName(Config.TargetPlayerName)
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
    
    print(string.format("[SendGift Hasil] Sukses: %s | Result: %s", tostring(success), tostring(result)))
    
    if success and result ~= false then
        return true, result
    else
        local errMsg = tostring(result or "Server menolak pengiriman gift")
        if not targetPlayerObj then
            errMsg = errMsg .. " (Pastikan target berada di server yang sama!)"
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

--- Pindah ke Server dengan jumlah pemain paling sedikit (Server Sepi)
function StealAnEggTrade.HopSmallServer()
    task.spawn(function()
        local placeId = game.PlaceId
        local foundServers = {}
        local cursor = ""
        local attempts = 0
        local maxAttempts = 3
        
        while attempts < maxAttempts do
            attempts = attempts + 1
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s", placeId, cursor ~= "" and ("&cursor=" .. cursor) or "")
            local success, raw = pcall(function() return game:HttpGet(url) end)
            
            if success and raw then
                local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
                if ok and data and data.data then
                    for _, s in ipairs(data.data) do
                        if s.id and s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.playing > 0 then
                            table.insert(foundServers, {
                                id = s.id,
                                playing = tonumber(s.playing) or 99,
                                maxPlayers = tonumber(s.maxPlayers) or 0,
                                ping = tonumber(s.ping) or 999
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
                if a.playing == b.playing then
                    return a.ping < b.ping
                end
                return a.playing < b.playing
            end)
            
            local bestServer = foundServers[1]
            print(string.format("[HopSmallServer] Menemukan Server Sepi! ID: %s | Pemain: %d/%d | Ping: %dms", 
                bestServer.id, bestServer.playing, bestServer.maxPlayers, bestServer.ping))
                
            pcall(function()
                Library:Notify({
                    Title   = "Server Sepi Ditemukan! 🍃",
                    Content = string.format("Pindah ke server dengan %d/%d pemain (Ping: %dms)", bestServer.playing, bestServer.maxPlayers, bestServer.ping),
                    Type    = "Success",
                    Duration = 4
                })
            end)
            
            task.wait(0.5)
            TeleportService:TeleportToPlaceInstance(placeId, bestServer.id, LocalPlayer)
        else
            pcall(function()
                Library:Notify({
                    Title   = "Server Sepi Tidak Ditemukan",
                    Content = "Mencoba teleport ke server publik umum...",
                    Type    = "Warning",
                    Duration = 3
                })
            end)
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    end)
end

--- Server Hop Acak (Random Server)
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

function StealAnEggTrade.SetTarget(targetUserIdOrUsername)
    local num = tonumber(targetUserIdOrUsername)
    if num then
        Config.TargetPlayerId = num
        print("[StealAnEgg API] Target UserId diset ke:", num)
        return true, num
    elseif type(targetUserIdOrUsername) == "string" and targetUserIdOrUsername ~= "" then
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
    if filterTbl.IgnoreFavorites ~= nil then Config.IgnoreFavorites = filterTbl.IgnoreFavorites end
    if filterTbl.OnlyFavorites ~= nil then Config.OnlyFavorites = filterTbl.OnlyFavorites end
    print(string.format("[StealAnEgg API] Filter Updated -> Item: %s | Mutasi: %s | Rarity: %s | Min: %.2f Juta kg", 
        tostring(Config.FilterItem), tostring(Config.FilterMutation), tostring(Config.FilterRarity), Config.MinWeight / 1000000))
    return true
end

function StealAnEggTrade.GiftFilteredBatch()
    local targetId = Config.TargetPlayerId or ResolveTargetId()
    if not targetId then
        warn("[StealAnEgg API] Target Player belum diset / belum berada di server!")
        return false, "Target Player belum diset / belum berada di server"
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

_G.StealAnEggTrade = StealAnEggTrade
getgenv().StealAnEggTrade = StealAnEggTrade


-- ==========================================================
-- [SECTION 3] AUTO ACCEPT LISTENER (EXACT EVENT HANDLER)
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
        if Config.OnlyAcceptTarget and Config.TargetPlayerId then
            if sId ~= tonumber(Config.TargetPlayerId) then
                if LastRequestPara then
                    pcall(function()
                        LastRequestPara:Set("Permintaan Masuk Terakhir", string.format("Item: %s\nDari: %s (ID: %s)\nStatus: Diabaikan (Bukan Target Whitelist) ❌", iName, sName, tostring(sId)))
                    end)
                end
                return
            end
        end
        
        if Config.AcceptDelay and Config.AcceptDelay > 0 then
            task.wait(Config.AcceptDelay)
        end
        
        local ok, result = StealAnEggTrade.AcceptGift(sId, reqUid)
        if ok then
            TradeStats.AcceptedCount = TradeStats.AcceptedCount + 1
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
            local targetId = Config.TargetPlayerId or ResolveTargetId()
            if targetId then
                local tools = StealAnEggTrade.GetAllTools()
                for _, tool in ipairs(tools) do
                    if not Config.AutoTradeLoop then break end
                    
                    if Config.IgnoreFavorites and tool:GetAttribute("Favorite") == true then
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
            local targetId = Config.TargetPlayerId or ResolveTargetId()
            if targetId then
                local tools = StealAnEggTrade.GetAllTools()
                local matchedCount = 0
                for _, tool in ipairs(tools) do
                    if not Config.AutoTradeFilterLoop then break end
                    
                    if StealAnEggTrade.MatchesFilter(tool, Config) then
                        matchedCount = matchedCount + 1
                        local tName = tool.Name
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
    LogoText   = '🥚',
    ConfigName = 'SigmaHub_StealAnEgg',
    ToggleKey  = Enum.KeyCode.RightShift,
    Watermark  = false,
})

-- ---------------------------------------------------------
-- TAB 1: ⚡ AUTO TRADE & RECEIVER (MAIN TAB)
-- ---------------------------------------------------------
local MainTab = Window:MakeTab("⚡")

-- Section 1: Target Player
local TargetSec = MainTab:AddSection("Target Player Setup")

local playerList = GetPlayerList()
local PlayerDropdown = TargetSec:AddDropdown({
    Name = "Pilih Player di Server",
    Options = playerList,
    Default = playerList[1] or "",
    Flag = "TargetPlayerDropdown",
    Tooltip = "Pilih target penerima gift dari daftar player aktif"
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
    Name = "🔄 Refresh Daftar Player",
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

TargetSec:AddInput({
    Name = "✏️ Input Manual UserID / Username",
    Placeholder = Config.TargetPlayerId and tostring(Config.TargetPlayerId) or (Config.TargetPlayerName ~= "" and Config.TargetPlayerName or "Masukkan UserID atau Username"),
    Tooltip = "Ketik UserID angka atau Username target langsung"
}, function(text)
    if text and text ~= "" then
        local ok, res = StealAnEggTrade.SetTarget(text)
        if ok then
            Library:Notify({
                Title   = "Target Diset",
                Content = "Target UserID: " .. tostring(res),
                Type    = "Success",
                Duration = 3
            })
        else
            Library:Notify({
                Title   = "Error",
                Content = "Player '" .. text .. "' tidak ditemukan!",
                Type    = "Error",
                Duration = 3
            })
        end
    end
end)


-- Section 2: Gifting Actions (Pengirim / Gifter)
local ActionSec = MainTab:AddSection("Aksi Quick Trade / Gift (Pengirim)")

ActionSec:AddButton({
    Name = "🎁 Gift Barang yang Sedang Dipegang (1x)",
    Tooltip = "Memegang dan mengirim tool yang saat ini aktif di tangan"
}, function()
    local targetId = Config.TargetPlayerId or ResolveTargetId()
    if not targetId then
        Library:Notify({
            Title   = "Peringatan",
            Content = "Pilih atau Masukkan Target Player terlebih dahulu!",
            Type    = "Warning",
            Duration = 3
        })
        return
    end
    
    local character = LocalPlayer.Character
    local heldTool = character and character:FindFirstChildOfClass("Tool")
    local itemName = heldTool and heldTool.Name or "Tool Aktif"
    
    local ok, err = StealAnEggTrade.SendGift(targetId, heldTool)
    if ok then
        TradeStats.TotalSent = TradeStats.TotalSent + 1
        TradeStats.SuccessCount = TradeStats.SuccessCount + 1
        TradeStats.LastItemName = itemName
        Library:Notify({
            Title   = "Gift Terkirim! 🎁",
            Content = "Berhasil mengirim: " .. itemName,
            Type    = "Success",
            Duration = 3
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
    Name = "📦 Gift Semua Tool di Backpack (1x Loop)",
    Tooltip = "Memegang satu per satu lalu mengirim seluruh Tool yang ada di Backpack"
}, function()
    local targetId = Config.TargetPlayerId or ResolveTargetId()
    if not targetId then
        Library:Notify({
            Title   = "Peringatan",
            Content = "Pilih Target Player terlebih dahulu!",
            Type    = "Warning",
            Duration = 3
        })
        return
    end
    
    local tools = StealAnEggTrade.GetAllTools()
    if #tools == 0 then
        Library:Notify({
            Title   = "Backpack Kosong",
            Content = "Tidak ada Tool yang ditemukan di Backpack!",
            Type    = "Warning",
            Duration = 3
        })
        return
    end
    
    Library:Notify({
        Title   = "Memulai Gifting",
        Content = "Mengirim " .. #tools .. " item ke target...",
        Type    = "Info",
        Duration = 3
    })
    
    task.spawn(function()
        for _, tool in ipairs(tools) do
            if Config.IgnoreFavorites and tool:GetAttribute("Favorite") == true then
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
        
        Library:Notify({
            Title   = "Selesai",
            Content = "Proses Gift semua Tool telah selesai!",
            Type    = "Success",
            Duration = 4
        })
    end)
end)

ActionSec:AddToggle({
    Name = "⚡ Auto Loop Trade Semua Item Terus Menerus",
    Default = Config.AutoTradeLoop,
    Flag = "AutoTradeLoopToggle",
    Tooltip = "Terus memindai backpack & mengirim seluruh item otomatis ke target"
}, function(Value)
    StealAnEggTrade.SetAutoTrade(Value)
    if Value then
        Library:Notify({
            Title   = "Auto Trade Aktif",
            Content = "Loop pengiriman aktif ke Target: " .. tostring(Config.TargetPlayerId or Config.TargetPlayerName or "Belum Diset"),
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
    Name = "🔒 Hanya Terima Dari Target Player (Whitelist)",
    Default = Config.OnlyAcceptTarget,
    Flag = "WhitelistTargetToggle",
    Tooltip = "Jika aktif, hanya menerima gift dari UserID Target Player yang dipilih"
}, function(Value)
    Config.OnlyAcceptTarget = Value
    if Value then
        Library:Notify({
            Title   = "Whitelist Aktif",
            Content = "Hanya menerima gift dari: " .. tostring(Config.TargetPlayerId or "Target Belum Diset"),
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
-- TAB 2: 🎒 BACKPACK & INVENTORY SCANNER (WITH RARITY)
-- ---------------------------------------------------------
local InvTab = Window:MakeTab("🎒")
local InvSec = InvTab:AddSection("Live Inventory / Backpack")

local initialScan = StealAnEggTrade.ScanInventory()

local InvDropdown = InvSec:AddDropdown({
    Name = "Pilih Tool dari Backpack",
    Options = initialScan.DropdownOptions,
    Default = initialScan.DropdownOptions[1] or "",
    Flag = "InvToolDropdown",
    Tooltip = "Pilih salah satu tool yang ada di backpack (menampilkan Nama, Mutasi, Rarity, Berat)"
}, function(selected)
    if not selected or selected == "Backpack Kosong" then 
        Config.SelectedInvTool = nil
        return 
    end
    local tools = StealAnEggTrade.GetAllTools()
    for _, t in ipairs(tools) do
        local info = StealAnEggTrade.GetToolInfo(t)
        local optStr = string.format("%s [%s] (%s) - %.1f kg%s", info.DisplayName, info.BaseMutation, info.Rarity, info.Weight, info.Favorite and " ⭐" or "")
        if optStr == selected then
            Config.SelectedInvTool = t
            break
        end
    end
end)

InvSec:AddButton({
    Name = "🔄 Refresh / Scan Ulang Backpack",
    Tooltip = "Memperbarui daftar item, mutasi, rarity, dan statistik inventaris"
}, function()
    local scan = StealAnEggTrade.ScanInventory()
    InvDropdown:Refresh(scan.DropdownOptions)
    Library:Notify({
        Title   = "Backpack Discan",
        Content = string.format("Ditemukan %d Tool (Total: %.1f kg)", scan.Count, scan.TotalWeight),
        Type    = "Info",
        Duration = 3
    })
end)

InvSec:AddButton({
    Name = "✋ Equip / Pegang Tool Terpilih",
    Tooltip = "Memegang tool yang dipilih dari dropdown ke tangan karakter"
}, function()
    if Config.SelectedInvTool and Config.SelectedInvTool.Parent then
        local ok, msg = StealAnEggTrade.EquipTool(Config.SelectedInvTool)
        if ok then
            Library:Notify({Title = "Equipped", Content = "Berhasil memegang: " .. Config.SelectedInvTool.Name, Type = "Success", Duration = 2.5})
        else
            Library:Notify({Title = "Gagal Equip", Content = tostring(msg), Type = "Error", Duration = 3})
        end
    else
        Library:Notify({Title = "Peringatan", Content = "Pilih Tool di dropdown terlebih dahulu!", Type = "Warning", Duration = 3})
    end
end)

InvSec:AddButton({
    Name = "🎁 Gift Tool Terpilih (1x)",
    Tooltip = "Kirim tool yang dipilih di dropdown langsung ke Target Player"
}, function()
    local targetId = Config.TargetPlayerId or ResolveTargetId()
    if not targetId then
        Library:Notify({Title = "Peringatan", Content = "Tentukan Target Player terlebih dahulu di Tab ⚡!", Type = "Warning", Duration = 3})
        return
    end
    if not Config.SelectedInvTool or not Config.SelectedInvTool.Parent then
        Library:Notify({Title = "Peringatan", Content = "Pilih Tool di dropdown terlebih dahulu!", Type = "Warning", Duration = 3})
        return
    end
    
    local toolName = Config.SelectedInvTool.Name
    local ok, err = StealAnEggTrade.SendGift(targetId, Config.SelectedInvTool)
    if ok then
        TradeStats.TotalSent = TradeStats.TotalSent + 1
        TradeStats.SuccessCount = TradeStats.SuccessCount + 1
        TradeStats.LastItemName = toolName
        Library:Notify({Title = "Terkirim!", Content = "Berhasil mengirim: " .. toolName, Type = "Success", Duration = 3})
        
        local scan = StealAnEggTrade.ScanInventory()
        InvDropdown:Refresh(scan.DropdownOptions)
    else
        TradeStats.FailCount = TradeStats.FailCount + 1
        Library:Notify({Title = "Gagal Gift", Content = "Error: " .. tostring(err), Type = "Error", Duration = 4})
    end
end)

local InvStatSec = InvTab:AddSection("📊 Ringkasan Inventaris")
local InvCountPara = InvStatSec:AddParagraph("Total Tool", tostring(initialScan.Count) .. " Items")
local InvWeightPara = InvStatSec:AddParagraph("Total Berat", string.format("%.2f kg", initialScan.TotalWeight))
local InvFavPara = InvStatSec:AddParagraph("Barang Favorit", tostring(initialScan.FavoriteCount) .. " Favorit ⭐")

task.spawn(function()
    while getgenv().CurrentTradeScriptID == scriptId do
        pcall(function()
            local scan = StealAnEggTrade.ScanInventory()
            InvCountPara:Set("Total Tool", tostring(scan.Count) .. " Items di Backpack")
            InvWeightPara:Set("Total Berat", string.format("%.2f kg", scan.TotalWeight))
            InvFavPara:Set("Barang Favorit", tostring(scan.FavoriteCount) .. " Favorit ⭐")
        end)
        task.wait(2.5)
    end
end)


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
    Name = "⚖️ Minimum Berat (Satuan: JUTA kg)",
    Placeholder = Config.MinWeight > 0 and string.format("%.2f", Config.MinWeight / 1000000) or "Cth: 1 (= 1.000.000 kg), 0 = Bebas",
    Tooltip = "Input angka dalam satuan Juta kg. 0 = Bebas / Kirim berapapun beratnya"
}, function(text)
    local num = tonumber(text)
    if num and num > 0 then
        Config.MinWeight = num * 1000000
        Library:Notify({
            Title   = "Min Berat Diset",
            Content = string.format("%.2f Juta kg (%s kg)", num, formatNumber(Config.MinWeight)),
            Type    = "Success",
            Duration = 3
        })
    else
        Config.MinWeight = 0
        Library:Notify({
            Title   = "Min Berat Diset",
            Content = "Bebas / Tanpa batas minimum",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)

FilterSec:AddInput({
    Name = "⚖️ Maximum Berat (Satuan: JUTA kg) [Opsional]",
    Placeholder = Config.MaxWeight > 0 and string.format("%.2f", Config.MaxWeight / 1000000) or "Cth: 5 (= 5.000.000 kg), 0 = Bebas",
    Tooltip = "Input angka dalam satuan Juta kg. 0 = Tanpa batas maksimum"
}, function(text)
    local num = tonumber(text)
    if num and num > 0 then
        Config.MaxWeight = num * 1000000
        Library:Notify({
            Title   = "Max Berat Diset",
            Content = string.format("%.2f Juta kg (%s kg)", num, formatNumber(Config.MaxWeight)),
            Type    = "Success",
            Duration = 3
        })
    else
        Config.MaxWeight = 0
        Library:Notify({
            Title   = "Max Berat Diset",
            Content = "Bebas / Tanpa batas maksimum",
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

task.spawn(function()
    while getgenv().CurrentTradeScriptID == scriptId do
        pcall(function()
            local tools = StealAnEggTrade.GetAllTools()
            local matchCount = 0
            for _, t in ipairs(tools) do
                if StealAnEggTrade.MatchesFilter(t, Config) then
                    matchCount = matchCount + 1
                end
            end
            
            local minWStr = Config.MinWeight > 0 and string.format("%.2f Juta (%s kg)", Config.MinWeight / 1000000, formatNumber(Config.MinWeight)) or "Bebas"
            local maxWStr = Config.MaxWeight > 0 and string.format("%.2f Juta (%s kg)", Config.MaxWeight / 1000000, formatNumber(Config.MaxWeight)) or "Bebas"
            local targetDisplay = tostring(Config.TargetPlayerId or Config.TargetPlayerName or "Belum Diset")
            
            local statusDesc = string.format("Item Cocok: %d dari %d Tool\nTarget: %s\nItem: %s | Mutasi: %s\nRarity: %s\nMin Berat: %s | Max: %s",
                matchCount,
                #tools,
                targetDisplay,
                tostring(Config.FilterItem),
                tostring(Config.FilterMutation),
                tostring(Config.FilterRarity),
                minWStr,
                maxWStr
            )
            FilterMatchPara:Set("Status Filter", statusDesc)
        end)
        task.wait(1.5)
    end
end)

FilterActionSec:AddButton({
    Name = "📦 Kirim Semua Item Sesuai Filter (1x Batch)",
    Tooltip = "Mengirim semua item di backpack yang cocok dengan kriteria filter"
}, function()
    local ok, count = StealAnEggTrade.GiftFilteredBatch()
    if ok then
        Library:Notify({Title = "Memulai Batch Filter", Content = "Mengirim " .. count .. " item sesuai filter...", Type = "Info", Duration = 3})
    else
        Library:Notify({Title = "Peringatan", Content = tostring(count), Type = "Warning", Duration = 3})
    end
end)

FilterActionSec:AddToggle({
    Name = "🔁 Auto Loop Trade Khusus Sesuai Filter",
    Default = Config.AutoTradeFilterLoop,
    Flag = "AutoTradeFilterLoopToggle",
    Tooltip = "Otomatis dan terus menerus mengirim hanya item yang lolos kriteria filter"
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
-- TAB 4: 📊 STATS & LOGS
-- ---------------------------------------------------------
local StatsTab = Window:MakeTab("📊")
local StatsSec = StatsTab:AddSection("Statistik Transaksi Gifting")

local TotalSentPara = StatsSec:AddParagraph("Total Terkirim", "0 Item")
local TotalAcceptedPara = StatsSec:AddParagraph("Total Diterima (Accept)", "0 Item Diterima 📥")
local SuccessPara   = StatsSec:AddParagraph("Status Sukses", "0 Sukses")
local FailPara      = StatsSec:AddParagraph("Status Gagal", "0 Gagal")
local LastItemPara  = StatsSec:AddParagraph("Item Terakhir", "-")

StatsSec:AddButton({
    Name = "🔄 Reset Statistik",
    Tooltip = "Mengatur ulang hitungan statistik ke 0"
}, function()
    TradeStats.TotalSent = 0
    TradeStats.SuccessCount = 0
    TradeStats.FailCount = 0
    TradeStats.AcceptedCount = 0
    TradeStats.LastItemName = "-"
    Library:Notify({
        Title   = "Stats Reset",
        Content = "Statistik transaksi berhasil di-reset!",
        Type    = "Info",
        Duration = 2
    })
end)

task.spawn(function()
    while getgenv().CurrentTradeScriptID == scriptId do
        pcall(function()
            TotalSentPara:Set("Total Terkirim", tostring(TradeStats.TotalSent) .. " Item Terkirim")
            TotalAcceptedPara:Set("Total Diterima (Accept)", tostring(TradeStats.AcceptedCount) .. " Gift Diterima 📥")
            SuccessPara:Set("Status Sukses", tostring(TradeStats.SuccessCount) .. " Transaksi Sukses")
            FailPara:Set("Status Gagal", tostring(TradeStats.FailCount) .. " Gagal")
            LastItemPara:Set("Item Terakhir", tostring(TradeStats.LastItemName))
        end)
        task.wait(1)
    end
end)


-- ---------------------------------------------------------
-- TAB 5: 🌐 SERVER UTILITIES (JOB ID & LOW-PLAYER HOP)
-- ---------------------------------------------------------
local ServerTab = Window:MakeTab("🌐")
local ServerInfoSec = ServerTab:AddSection("Informasi Server Saat Ini")

local ServerJobIdPara = ServerInfoSec:AddParagraph("Job ID Server", tostring(game.JobId))
local ServerPlayerPara = ServerInfoSec:AddParagraph("Jumlah Player", string.format("%d / %d Players", #Players:GetPlayers(), Players.MaxPlayers))

task.spawn(function()
    while getgenv().CurrentTradeScriptID == scriptId do
        pcall(function()
            ServerJobIdPara:Set("Job ID Server", tostring(game.JobId))
            ServerPlayerPara:Set("Jumlah Player", string.format("%d / %d Players di Server", #Players:GetPlayers(), Players.MaxPlayers))
        end)
        task.wait(3)
    end
end)

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

local TeleportSec = ServerTab:AddSection("🚀 Pindah Server / Server Hop")

-- Tombol Server Sepi (LOWEST PLAYER COUNT)
TeleportSec:AddButton({
    Name = "🍃 Hop ke Server Paling Sepi (Lowest Player)",
    Tooltip = "Mencari server publik dengan jumlah pemain paling sedikit (1-3 player) lalu teleport ke sana"
}, function()
    Library:Notify({
        Title   = "Mencari Server Sepi... 🍃",
        Content = "Sedang memindai server publik dengan jumlah pemain paling sedikit...",
        Type    = "Info",
        Duration = 3.5
    })
    StealAnEggTrade.HopSmallServer()
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


Library:Notify({
    Title   = "Sigma Hub Loaded!",
    Content = string.format("Akun: %s (%s)", currentUsername, Config.ProfileRole or "Active"),
    Type    = "Success",
    Duration = 3.5
})

return StealAnEggTrade
