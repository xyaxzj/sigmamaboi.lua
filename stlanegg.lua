-- ==========================================================
-- STEAL AN EGG - AUTO TRADE & GIFTING SYSTEM (SIGMA UI V4)
-- Game: Steal an Egg (Roblox)
-- Framework: Sigma UI Library - V4 Ultimate Edition
-- Features: Auto Gifting, Backpack Scanner, Filtered Auto Trade
-- ==========================================================

-- =========================================================
-- CLEANUP THREAD & UI LAMA
-- =========================================================
if getgenv().CancelStealAnEggTrade then 
    pcall(getgenv().CancelStealAnEggTrade)
end
local scriptId = tick()
getgenv().CurrentTradeScriptID = scriptId

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

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

-- ==========================================================
-- [SECTION 1] PURE FUNCTIONS (Fungsi Modular & Backend)
-- ==========================================================

local StealAnEggTrade = {}

--- Mencari RemoteFunction Gifting di ReplicatedStorage.Network
function StealAnEggTrade.GetGiftingRemote()
    local network = ReplicatedStorage:FindFirstChild("Network")
    if network then
        return network:FindFirstChild("Gifting: Send Request")
    end
    return nil
end

--- Memegang / Equip Tool ke Character Player
-- @param tool Instance Tool yang ingin dipegang
-- @return boolean (success), string (message)
function StealAnEggTrade.EquipTool(tool)
    if not tool or not tool:IsA("Tool") then 
        return false, "Objek yang diberikan bukan Tool" 
    end
    
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    -- Sudah dipegang di Character
    if tool.Parent == character then
        return true, "Tool sudah dipegang"
    end
    
    -- Equip dari Backpack ke Character
    if humanoid and tool.Parent == LocalPlayer:FindFirstChild("Backpack") then
        humanoid:EquipTool(tool)
        task.wait(0.25)
        return tool.Parent == character, "Equipped via Humanoid"
    else
        tool.Parent = character
        task.wait(0.25)
        return tool.Parent == character, "Equipped via Parent"
    end
end

--- Mengambil informasi Attributes dan Properties dari Tool
-- @param tool Instance Tool
-- @return table Info data tool
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
    
    return {
        Instance = tool,
        Name = name,
        DisplayName = dispName,
        BaseMutation = tostring(baseMutation),
        Weight = tonumber(weight) or 0,
        Category = tostring(category),
        UID = tostring(uid),
        Favorite = fav,
        ItemType = tostring(itemType)
    }
end

--- Mengambil semua Tool di Backpack & Character
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

--- Memindai seluruh inventaris untuk statistik & pengelompokan
function StealAnEggTrade.ScanInventory()
    local tools = StealAnEggTrade.GetAllTools()
    local itemsByName = {}
    local uniqueNames = {"All Items"}
    local mutations = {"All Mutations"}
    local mutationSet = {}
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
            
            -- Group by DisplayName
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
            
            -- Track Mutations
            if info.BaseMutation and not mutationSet[info.BaseMutation] then
                mutationSet[info.BaseMutation] = true
                table.insert(mutations, info.BaseMutation)
            end
            
            local optStr = string.format("%s [%s] (%.1f kg)%s", info.DisplayName, info.BaseMutation, info.Weight, info.Favorite and " ⭐" or "")
            table.insert(dropdownOptions, optStr)
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
        TotalWeight = totalWeight,
        FavoriteCount = favoriteCount,
        DropdownOptions = dropdownOptions
    }
end

--- Memeriksa apakah suatu Tool cocok dengan kriteria filter
function StealAnEggTrade.MatchesFilter(tool, filterConfig)
    if not tool or not tool:IsA("Tool") then return false end
    local info = StealAnEggTrade.GetToolInfo(tool)
    if not info then return false end
    
    -- Filter Favorite
    if filterConfig.IgnoreFavorites and info.Favorite then
        return false
    end
    if filterConfig.OnlyFavorites and not info.Favorite then
        return false
    end
    
    -- Filter Nama / DisplayName / Category
    if filterConfig.FilterItem and filterConfig.FilterItem ~= "All Items" and filterConfig.FilterItem ~= "" then
        local targetName = filterConfig.FilterItem:lower()
        local matchesName = info.Name:lower():find(targetName, 1, true) ~= nil
        local matchesDisp = info.DisplayName:lower():find(targetName, 1, true) ~= nil
        local matchesCat = info.Category:lower():find(targetName, 1, true) ~= nil
        if not matchesName and not matchesDisp and not matchesCat then
            return false
        end
    end
    
    -- Filter Mutation
    if filterConfig.FilterMutation and filterConfig.FilterMutation ~= "All Mutations" and filterConfig.FilterMutation ~= "All" then
        if info.BaseMutation:lower() ~= filterConfig.FilterMutation:lower() then
            return false
        end
    end
    
    -- Filter Minimum Weight (dalam kg sebenarnya)
    if filterConfig.MinWeight and filterConfig.MinWeight > 0 then
        if info.Weight < filterConfig.MinWeight then
            return false
        end
    end
    
    -- Filter Maximum Weight (dalam kg sebenarnya)
    if filterConfig.MaxWeight and filterConfig.MaxWeight > 0 then
        if info.Weight > filterConfig.MaxWeight then
            return false
        end
    end
    
    return true, info
end

--- Mengirim Gift Tool ke Player Target
-- @param targetPlayerId UserID player penerima
-- @param tool (Optional) Tool yang akan di-gift. Jika nil, mengambil yang sedang dipegang
-- @return boolean (success), any (result/error)
function StealAnEggTrade.SendGift(targetPlayerId, tool)
    if not targetPlayerId then
        return false, "Target Player ID (UserId) belum ditentukan!"
    end
    
    -- Jika tool nil, cari Tool yang sedang dipegang di Character
    if not tool then
        local character = LocalPlayer.Character
        if character then
            tool = character:FindFirstChildOfClass("Tool")
        end
    end
    
    if not tool or not tool:IsA("Tool") then
        return false, "Tidak ada Tool yang dipegang / ditemukan!"
    end
    
    -- 1. Pegang barangnya terlebih dahulu
    local equipped, equipMsg = StealAnEggTrade.EquipTool(tool)
    if not equipped then
        return false, "Gagal memegang Tool: " .. tostring(equipMsg)
    end
    
    -- Jeda singkat agar server menyinkronkan Tool yang sedang dipegang
    task.wait(0.15)
    
    -- 2. Dapatkan RemoteFunction Gifting
    local giftingRemote = StealAnEggTrade.GetGiftingRemote()
    if not giftingRemote then
        return false, "Remote 'Gifting: Send Request' tidak ditemukan di ReplicatedStorage.Network"
    end
    
    -- 3. InvokeServer ke remote game
    local numericId = tonumber(targetPlayerId) or targetPlayerId
    local success, result = pcall(function()
        return giftingRemote:InvokeServer(numericId)
    end)
    
    if success then
        return true, result
    else
        return false, tostring(result)
    end
end

-- Export global
_G.StealAnEggTrade = StealAnEggTrade
getgenv().StealAnEggTrade = StealAnEggTrade


-- ==========================================================
-- [SECTION 2] LOAD SIGMA UI LIBRARY V4
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

-- State & Konfigurasi Global
local Config = {
    TargetPlayerId = nil,
    AutoTradeLoop = false,
    AutoTradeFilterLoop = false,
    IgnoreFavorites = true,
    OnlyFavorites = false,
    DelayBetweenGifts = 0.5,
    FilterItem = "All Items",
    FilterMutation = "All Mutations",
    MinWeight = 0,
    MaxWeight = 0,
    QuantityLimit = 0,
    SelectedInvTool = nil
}

local TradeStats = {
    TotalSent = 0,
    SuccessCount = 0,
    FailCount = 0,
    LastItemName = "-"
}

-- Cleanup handler
getgenv().CancelStealAnEggTrade = function()
    Config.AutoTradeLoop = false
    Config.AutoTradeFilterLoop = false
end

-- Helper Player List
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
    local foundPlayer = Players:FindFirstChild(nameOnly)
    if foundPlayer then
        return foundPlayer.UserId
    end
    return tonumber(selectionStr)
end


-- ==========================================================
-- [SECTION 3] MEMBUAT WINDOW & KOMPONEN SIGMA UI
-- ==========================================================

local Window = Library:CreateWindow({
    Name       = 'Sigma Hub | Steal An Egg Auto Trade',
    Footer     = 'discord.gg/sigma | v4.0',
    LogoText   = '🥚',
    ConfigName = 'SigmaHub_StealAnEgg',
    ToggleKey  = Enum.KeyCode.RightShift,
    Watermark  = false,
})

-- ---------------------------------------------------------
-- TAB 1: ⚡ AUTO TRADE (MAIN TAB)
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
    Placeholder = "Masukkan UserID (cth: 12345678) atau Username",
    Tooltip = "Ketik UserID angka atau Username target langsung"
}, function(text)
    if text and text ~= "" then
        local num = tonumber(text)
        if num then
            Config.TargetPlayerId = num
            Library:Notify({
                Title   = "Target UserID",
                Content = "UserID diset ke: " .. num,
                Type    = "Success",
                Duration = 3
            })
        else
            task.spawn(function()
                local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(text) end)
                if ok and id then
                    Config.TargetPlayerId = id
                    Library:Notify({
                        Title   = "Target Username",
                        Content = text .. " -> UserID: " .. id,
                        Type    = "Success",
                        Duration = 3
                    })
                else
                    Library:Notify({
                        Title   = "Error",
                        Content = "Username '" .. text .. "' tidak ditemukan!",
                        Type    = "Error",
                        Duration = 3
                    })
                end
            end)
        end
    end
end)


-- Section 2: Gifting Actions
local ActionSec = MainTab:AddSection("Aksi Quick Trade / Gift")

ActionSec:AddButton({
    Name = "🎁 Gift Barang yang Sedang Dipegang (1x)",
    Tooltip = "Memegang dan mengirim tool yang saat ini aktif di tangan"
}, function()
    if not Config.TargetPlayerId then
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
    local itemName = heldTool and heldTool.Name or "Unknown Tool"
    
    local ok, err = StealAnEggTrade.SendGift(Config.TargetPlayerId, heldTool)
    if ok then
        TradeStats.TotalSent = TradeStats.TotalSent + 1
        TradeStats.SuccessCount = TradeStats.SuccessCount + 1
        TradeStats.LastItemName = itemName
        Library:Notify({
            Title   = "Gift Terkirim!",
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
    if not Config.TargetPlayerId then
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
            -- Abaikan favorit jika toggle aktif
            if Config.IgnoreFavorites and tool:GetAttribute("Favorite") == true then
                continue
            end
            
            local tName = tool.Name
            local ok, err = StealAnEggTrade.SendGift(Config.TargetPlayerId, tool)
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
    Default = false,
    Flag = "AutoTradeLoopToggle",
    Tooltip = "Terus memindai backpack & mengirim seluruh item otomatis ke target"
}, function(Value)
    Config.AutoTradeLoop = Value
    if Value then
        Library:Notify({
            Title   = "Auto Trade Aktif",
            Content = "Loop pengiriman aktif ke Target: " .. tostring(Config.TargetPlayerId or "Belum Diset"),
            Type    = "Success",
            Duration = 3
        })
        
        task.spawn(function()
            while Config.AutoTradeLoop and getgenv().CurrentTradeScriptID == scriptId do
                if Config.TargetPlayerId then
                    local tools = StealAnEggTrade.GetAllTools()
                    for _, tool in ipairs(tools) do
                        if not Config.AutoTradeLoop then break end
                        
                        if Config.IgnoreFavorites and tool:GetAttribute("Favorite") == true then
                            continue
                        end
                        
                        local tName = tool.Name
                        local ok, err = StealAnEggTrade.SendGift(Config.TargetPlayerId, tool)
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
                task.wait(0.5)
            end
        end)
    else
        Library:Notify({
            Title   = "Auto Trade Dimatikan",
            Content = "Loop pengiriman dinonaktifkan.",
            Type    = "Info",
            Duration = 2.5
        })
    end
end)


-- ---------------------------------------------------------
-- TAB 2: 🎒 BACKPACK & INVENTORY SCANNER (NEW TAB)
-- ---------------------------------------------------------
local InvTab = Window:MakeTab("🎒")
local InvSec = InvTab:AddSection("Live Inventory / Backpack")

local initialScan = StealAnEggTrade.ScanInventory()

local InvDropdown = InvSec:AddDropdown({
    Name = "Pilih Tool dari Backpack",
    Options = initialScan.DropdownOptions,
    Default = initialScan.DropdownOptions[1] or "",
    Flag = "InvToolDropdown",
    Tooltip = "Pilih salah satu tool yang ada di backpack"
}, function(selected)
    if not selected or selected == "Backpack Kosong" then 
        Config.SelectedInvTool = nil
        return 
    end
    -- Cari tool yang cocok dengan nama pilihan
    local tools = StealAnEggTrade.GetAllTools()
    for _, t in ipairs(tools) do
        local info = StealAnEggTrade.GetToolInfo(t)
        local optStr = string.format("%s [%s] (%.1f kg)%s", info.DisplayName, info.BaseMutation, info.Weight, info.Favorite and " ⭐" or "")
        if optStr == selected then
            Config.SelectedInvTool = t
            break
        end
    end
end)

InvSec:AddButton({
    Name = "🔄 Refresh / Scan Ulang Backpack",
    Tooltip = "Memperbarui daftar item dan statistik inventaris"
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
    if not Config.TargetPlayerId then
        Library:Notify({Title = "Peringatan", Content = "Tentukan Target Player terlebih dahulu di Tab ⚡!", Type = "Warning", Duration = 3})
        return
    end
    if not Config.SelectedInvTool or not Config.SelectedInvTool.Parent then
        Library:Notify({Title = "Peringatan", Content = "Pilih Tool di dropdown terlebih dahulu!", Type = "Warning", Duration = 3})
        return
    end
    
    local toolName = Config.SelectedInvTool.Name
    local ok, err = StealAnEggTrade.SendGift(Config.TargetPlayerId, Config.SelectedInvTool)
    if ok then
        TradeStats.TotalSent = TradeStats.TotalSent + 1
        TradeStats.SuccessCount = TradeStats.SuccessCount + 1
        TradeStats.LastItemName = toolName
        Library:Notify({Title = "Terkirim!", Content = "Berhasil mengirim: " .. toolName, Type = "Success", Duration = 3})
        
        -- Refresh dropdown setelah dikirim
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

-- Update Ringkasan Inventaris secara berkala
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
-- TAB 3: 🎯 AUTO TRADE BY FILTER (NEW TAB)
-- ---------------------------------------------------------
local FilterTab = Window:MakeTab("🎯")
local FilterSec = FilterTab:AddSection("Kriteria Filter Auto Trade")

-- Dropdown Item Name Filter
local ItemNameDropdown = FilterSec:AddDropdown({
    Name = "Filter Berdasarkan Jenis Item",
    Options = initialScan.UniqueNames,
    Default = "All Items",
    Flag = "FilterItemDropdown",
    Tooltip = "Pilih nama jenis item tertentu atau 'All Items'"
}, function(selected)
    Config.FilterItem = selected or "All Items"
end)

-- Dropdown Mutation Filter
local MutationDropdown = FilterSec:AddDropdown({
    Name = "Filter Berdasarkan Mutasi",
    Options = initialScan.Mutations,
    Default = "All Mutations",
    Flag = "FilterMutationDropdown",
    Tooltip = "Pilih mutasi item (cth: Golden, Normal, etc.)"
}, function(selected)
    Config.FilterMutation = selected or "All Mutations"
end)

FilterSec:AddButton({
    Name = "🔄 Refresh Opsi Filter dari Backpack",
    Tooltip = "Memperbarui daftar item dan mutasi yang terdeteksi di inventaris"
}, function()
    local scan = StealAnEggTrade.ScanInventory()
    ItemNameDropdown:Refresh(scan.UniqueNames)
    MutationDropdown:Refresh(scan.Mutations)
    Library:Notify({
        Title   = "Filter Diperbarui",
        Content = string.format("%d Jenis Item & %d Mutasi terdeteksi", #scan.UniqueNames - 1, #scan.Mutations - 1),
        Type    = "Info",
        Duration = 2.5
    })
end)

-- Kolom Input Minimum Berat (Dalam Satuan Juta kg)
FilterSec:AddInput({
    Name = "⚖️ Minimum Berat (Satuan: JUTA kg)",
    Placeholder = "Cth: 1 (= 1.000.000 kg), 0.5 (= 500.000 kg), 0 = Bebas",
    Tooltip = "Input angka dalam satuan Juta kg. Contoh: 1 = 1.000.000 kg"
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

-- Kolom Input Maximum Berat (Dalam Satuan JUTA kg) [Opsional]
FilterSec:AddInput({
    Name = "⚖️ Maximum Berat (Satuan: JUTA kg) [Opsional]",
    Placeholder = "Cth: 5 (= 5.000.000 kg), 0 = Bebas",
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
    Default = true,
    Flag = "FilterIgnoreFavToggle",
    Tooltip = "Jangan kirim item yang ditandai Favorite"
}, function(val)
    Config.IgnoreFavorites = val
end)

FilterSec:AddToggle({
    Name = "🌟 Hanya Kirim Barang Favorit (Only Favorite)",
    Default = false,
    Flag = "FilterOnlyFavToggle",
    Tooltip = "Hanya kirim item yang berstatus Favorite"
}, function(val)
    Config.OnlyFavorites = val
end)

FilterSec:AddSlider({
    Name = "⏱️ Jeda Antar Gift (Detik)",
    Min = 0.1,
    Max = 3.0,
    Default = 0.5,
    Step = 0.1,
    Flag = "FilterDelaySlider",
    Tooltip = "Waktu jeda antar pengiriman remote gift"
}, function(val)
    Config.DelayBetweenGifts = val
end)

local FilterActionSec = FilterTab:AddSection("⚡ Eksekusi Auto Trade By Filter")

local FilterMatchPara = FilterActionSec:AddParagraph("Status Pencocokan", "Memindai kecocokan filter...")

-- Updater status kecocokan filter
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
            
            local statusDesc = string.format("Item Cocok: %d dari %d Tool\nTarget: %s\nItem: %s | Mutasi: %s\nMin Berat: %s\nMax Berat: %s",
                matchCount,
                #tools,
                tostring(Config.TargetPlayerId or "Belum Diset"),
                tostring(Config.FilterItem),
                tostring(Config.FilterMutation),
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
    if not Config.TargetPlayerId then
        Library:Notify({Title = "Peringatan", Content = "Pilih Target Player terlebih dahulu di Tab ⚡!", Type = "Warning", Duration = 3})
        return
    end
    
    local tools = StealAnEggTrade.GetAllTools()
    local matchedTools = {}
    for _, t in ipairs(tools) do
        if StealAnEggTrade.MatchesFilter(t, Config) then
            table.insert(matchedTools, t)
        end
    end
    
    if #matchedTools == 0 then
        Library:Notify({Title = "Tidak Ada Item Cocok", Content = "Tidak ada item di backpack yang cocok dengan filter!", Type = "Warning", Duration = 3})
        return
    end
    
    Library:Notify({Title = "Memulai Batch Filter", Content = "Mengirim " .. #matchedTools .. " item sesuai filter...", Type = "Info", Duration = 3})
    
    task.spawn(function()
        for _, tool in ipairs(matchedTools) do
            if not tool.Parent then continue end
            local tName = tool.Name
            local ok, err = StealAnEggTrade.SendGift(Config.TargetPlayerId, tool)
            if ok then
                TradeStats.TotalSent = TradeStats.TotalSent + 1
                TradeStats.SuccessCount = TradeStats.SuccessCount + 1
                TradeStats.LastItemName = tName
            else
                TradeStats.FailCount = TradeStats.FailCount + 1
            end
            task.wait(Config.DelayBetweenGifts)
        end
        Library:Notify({Title = "Batch Selesai", Content = "Pengiriman item sesuai filter telah selesai!", Type = "Success", Duration = 3.5})
    end)
end)

FilterActionSec:AddToggle({
    Name = "🔁 Auto Loop Trade Khusus Sesuai Filter",
    Default = false,
    Flag = "AutoTradeFilterLoopToggle",
    Tooltip = "Otomatis dan terus menerus mengirim hanya item yang lolos kriteria filter"
}, function(Value)
    Config.AutoTradeFilterLoop = Value
    if Value then
        Library:Notify({
            Title   = "Auto Trade Filter Aktif",
            Content = "Loop filter aktif untuk: " .. tostring(Config.FilterItem) .. " [" .. tostring(Config.FilterMutation) .. "]",
            Type    = "Success",
            Duration = 3.5
        })
        
        task.spawn(function()
            while Config.AutoTradeFilterLoop and getgenv().CurrentTradeScriptID == scriptId do
                if Config.TargetPlayerId then
                    local tools = StealAnEggTrade.GetAllTools()
                    for _, tool in ipairs(tools) do
                        if not Config.AutoTradeFilterLoop then break end
                        
                        -- Cek filter
                        if StealAnEggTrade.MatchesFilter(tool, Config) then
                            local tName = tool.Name
                            local ok, err = StealAnEggTrade.SendGift(Config.TargetPlayerId, tool)
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
                end
                task.wait(0.5)
            end
        end)
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
    TradeStats.LastItemName = "-"
    Library:Notify({
        Title   = "Stats Reset",
        Content = "Statistik transaksi berhasil di-reset!",
        Type    = "Info",
        Duration = 2
    })
end)

-- Background thread updater untuk Tab Stats
task.spawn(function()
    while getgenv().CurrentTradeScriptID == scriptId do
        pcall(function()
            TotalSentPara:Set("Total Terkirim", tostring(TradeStats.TotalSent) .. " Item")
            SuccessPara:Set("Status Sukses", tostring(TradeStats.SuccessCount) .. " Transaksi Sukses")
            FailPara:Set("Status Gagal", tostring(TradeStats.FailCount) .. " Gagal")
            LastItemPara:Set("Item Terakhir", tostring(TradeStats.LastItemName))
        end)
        task.wait(1)
    end
end)

Library:Notify({
    Title   = "Sigma Hub Loaded!",
    Content = "Steal An Egg Auto Trade siap digunakan.",
    Type    = "Success",
    Duration = 3.5
})

return StealAnEggTrade
