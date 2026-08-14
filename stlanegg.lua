-- ==========================================================
-- STEAL AN EGG - AUTO TRADE & GIFTING SYSTEM (SIGMA UI V4)
-- Game: Steal an Egg (Roblox)
-- Framework: Sigma UI Library - V4 Ultimate Edition
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
    return {
        Name = tool.Name,
        DisplayName = tool:GetAttribute("DisplayName") or tool.Name,
        BaseMutation = tool:GetAttribute("BaseMutation") or tool:GetAttribute("Mutations") or "Normal",
        Weight = tool:GetAttribute("Weight") or 0,
        UID = tool:GetAttribute("UID") or "-",
        ItemType = tool:GetAttribute("ItemType") or "Asset",
        Favorite = tool:GetAttribute("Favorite") == true
    }
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

-- State & Konfigurasi
local Config = {
    TargetPlayerId = nil,
    AutoTradeLoop = false,
    IgnoreFavorites = true,
    DelayBetweenGifts = 0.5,
    FilterName = "",
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
            
            -- Filter nama jika diisi
            if Config.FilterName ~= "" then
                local toolName = tool.Name:lower()
                local dispName = (tool:GetAttribute("DisplayName") or ""):lower()
                local filterStr = Config.FilterName:lower()
                if not toolName:find(filterStr) and not dispName:find(filterStr) then
                    continue
                end
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
    Name = "⚡ Auto Loop Trade Terus Menerus",
    Default = false,
    Flag = "AutoTradeLoopToggle",
    Tooltip = "Terus memindai backpack & mengirim item otomatis ke target"
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
                        
                        -- Abaikan Favorite
                        if Config.IgnoreFavorites and tool:GetAttribute("Favorite") == true then
                            continue
                        end
                        
                        -- Filter Nama
                        if Config.FilterName ~= "" then
                            local toolName = tool.Name:lower()
                            local dispName = (tool:GetAttribute("DisplayName") or ""):lower()
                            local filterStr = Config.FilterName:lower()
                            if not toolName:find(filterStr) and not dispName:find(filterStr) then
                                continue
                            end
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
-- TAB 2: ⚙️ FILTER & SETTINGS
-- ---------------------------------------------------------
local FilterTab = Window:MakeTab("⚙️")
local FilterSec = FilterTab:AddSection("Pengaturan & Proteksi Item")

FilterSec:AddToggle({
    Name = "⭐ Abaikan Barang Favorit (Favorite == true)",
    Default = true,
    Flag = "IgnoreFavToggle",
    Tooltip = "Mencegah barang berstatus Favorite ikut terkirim secara tidak sengaja"
}, function(Value)
    Config.IgnoreFavorites = Value
end)

FilterSec:AddSlider({
    Name = "⏱️ Jeda Antar Gift (Detik)",
    Min = 0.1,
    Max = 3.0,
    Default = 0.5,
    Step = 0.1,
    Flag = "DelaySlider",
    Tooltip = "Waktu tunggu jeda antara pemanggilan remote gift"
}, function(Value)
    Config.DelayBetweenGifts = Value
end)

FilterSec:AddInput({
    Name = "🔍 Filter Nama Item / DisplayName",
    Placeholder = "Cth: Mosasaurus, Golden, Egg...",
    Tooltip = "Hanya mengirim Tool yang namanya mengandung kata kunci ini"
}, function(Text)
    Config.FilterName = Text or ""
end)

local InspectSec = FilterTab:AddSection("🔍 Item Inspector (Held Tool)")
local InspectPara = InspectSec:AddParagraph("Item Info", "Pegang barang di tangan untuk melihat data attributes...")

InspectSec:AddButton({
    Name = "🔎 Periksa Tool di Tangan Sekarang",
    Tooltip = "Melihat UID, Mutation, Weight, dan Status Favorite dari item di tangan"
}, function()
    local character = LocalPlayer.Character
    local held = character and character:FindFirstChildOfClass("Tool")
    if held then
        local info = StealAnEggTrade.GetToolInfo(held)
        local desc = string.format("Nama: %s\nDisplayName: %s\nMutation: %s\nWeight: %s\nUID: %s\nFavorite: %s",
            tostring(info.Name),
            tostring(info.DisplayName),
            tostring(info.BaseMutation),
            tostring(info.Weight),
            tostring(info.UID),
            info.Favorite and "⭐ Ya" or "Tidak"
        )
        InspectPara:Set("Item: " .. held.Name, desc)
        Library:Notify({
            Title   = "Inspect Tool",
            Content = "Data item '" .. held.Name .. "' berhasil dibaca!",
            Type    = "Info",
            Duration = 2.5
        })
    else
        InspectPara:Set("Tidak Ada Tool", "Karakter Anda saat ini tidak memegang Tool apapun di tangan.")
        Library:Notify({
            Title   = "Inspect Tool",
            Content = "Tidak ada Tool yang sedang dipegang di tangan!",
            Type    = "Warning",
            Duration = 2.5
        })
    end
end)


-- ---------------------------------------------------------
-- TAB 3: 📊 STATS & LOGS
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
