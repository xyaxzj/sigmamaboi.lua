-- ==============================================================================
-- ☄️ KALB METEOR SHOP - LIVE STOCK MONITOR & 48-HOUR FUTURE PREDICTOR PRO
-- ==============================================================================
-- Fitur & Inovasi:
-- 1. 🔮 Tab "ALL": Prediksi lengkap semua item untuk 48 JAM KE DEPAN (96 Restock)!
--    - Dilengkapi Time Navigator (◀ Jam Sebelumnya | Jam Berikutnya ▶) & Full 48h Scroll List.
-- 2. 🎯 Tab "TARGET": Pilih item (Frigorex, Patagotitan, dll) & cari SEMUA jadwal kemunculannya dalam 48 jam!
-- 3. 📦 Tab "LIVE": Live stock realtime dari server + Instant Buy & Auto-Buy.
-- 4. 📜 Tab "LOG": Catatan riwayat restock server.
-- 5. 📱 Fix Mobile Scrolling: CanvasSize auto-update sehingga lancar di-scroll sampai bawah di HP!
-- 6. 👆 100% Touch Responsive: Menggunakan Button.Activated untuk Android & iOS.
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
if not lp then
    local count = 0
    repeat
        task.wait(0.05)
        lp = Players.LocalPlayer
        count = count + 1
    until lp or count > 50
end

-- ==============================================================================
-- 📡 1. NETWORK & REMOTE DISCOVERY
-- ==============================================================================
local networkFolder = nil
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
    local packages = shared and (shared:FindFirstChild("Packages") or shared:WaitForChild("Packages", 3))
    networkFolder = packages and (packages:FindFirstChild("Network") or packages:WaitForChild("Network", 3))
end)

local rev_MeteorShop_RequestSync = networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_RequestSync")
local rev_MeteorShop_Stock = networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Stock")
local rev_MeteorShop_Buy = networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy")

if not rev_MeteorShop_Stock or not rev_MeteorShop_Buy or not rev_MeteorShop_RequestSync then
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") then
            if r.Name == "rev_MeteorShop_Stock" then rev_MeteorShop_Stock = r
            elseif r.Name == "rev_MeteorShop_Buy" then rev_MeteorShop_Buy = r
            elseif r.Name == "rev_MeteorShop_RequestSync" then rev_MeteorShop_RequestSync = r
            end
        end
    end
end

-- ==============================================================================
-- 📊 2. METEOR SHOP DATABASE (DATA RESMI SESUAI ORDER SERVER)
-- ==============================================================================
local RESTOCK_INTERVAL = 1800 -- 30 Menit

local SHOP_ITEMS = {
    ["Cash Potion"] = {
        Category = "Potion",
        DisplayName = "Cash Potion (I)",
        Order = 0,
        Cost = 20,
        StockMinimum = 1,
        StockChance = 8,
        StockRolls = 6,
        RarityTag = "🟢 100%",
        TagColor = Color3.fromRGB(80, 225, 120),
        Info = "3x Cash (10m)",
        Image = "rbxassetid://136230782614378",
        DefaultAutoBuy = false
    },
    ["Farm Potion"] = {
        Category = "Potion",
        DisplayName = "Farm Potion (I)",
        Order = 1,
        Cost = 30,
        StockMinimum = 1,
        StockChance = 8,
        StockRolls = 6,
        RarityTag = "🟢 100%",
        TagColor = Color3.fromRGB(80, 225, 120),
        Info = "1.75x Speed (10m)",
        Image = "rbxassetid://137373210970097",
        DefaultAutoBuy = true
    },
    ["Weight Training Potion"] = {
        Category = "Potion",
        DisplayName = "Weight Potion (I)",
        Order = 2,
        Cost = 40,
        StockMinimum = 1,
        StockChance = 7,
        StockRolls = 6,
        RarityTag = "🟢 100%",
        TagColor = Color3.fromRGB(80, 225, 120),
        Info = "2x Lift (10m)",
        Image = "rbxassetid://102337170718354",
        DefaultAutoBuy = false
    },
    ["Luck Potion"] = {
        Category = "Potion",
        DisplayName = "Luck Potion (I)",
        Order = 3,
        Cost = 50,
        StockMinimum = 0,
        StockChance = 6,
        StockRolls = 6,
        RarityTag = "✨ 31%",
        TagColor = Color3.fromRGB(130, 200, 255),
        Info = "2x Luck (10m)",
        Image = "rbxassetid://133824459739024",
        DefaultAutoBuy = false
    },
    ["Cash Potion II"] = {
        Category = "Potion",
        DisplayName = "Cash Potion II",
        Order = 4,
        Cost = 60,
        StockMinimum = 0,
        StockChance = 5,
        StockRolls = 4,
        RarityTag = "⭐ 18.5%",
        TagColor = Color3.fromRGB(100, 220, 255),
        Info = "6x Cash (10m)",
        Image = "rbxassetid://85935283881899",
        DefaultAutoBuy = false
    },
    ["Farm Potion II"] = {
        Category = "Potion",
        DisplayName = "Farm Potion II",
        Order = 5,
        Cost = 80,
        StockMinimum = 0,
        StockChance = 5,
        StockRolls = 4,
        RarityTag = "⭐ 18.5%",
        TagColor = Color3.fromRGB(160, 100, 255),
        Info = "2.5x Speed (10m)",
        Image = "rbxassetid://81556992722350",
        DefaultAutoBuy = true
    },
    ["Weight Training Potion II"] = {
        Category = "Potion",
        DisplayName = "Weight Potion II",
        Order = 6,
        Cost = 100,
        StockMinimum = 0,
        StockChance = 4,
        StockRolls = 4,
        RarityTag = "⭐ 15.1%",
        TagColor = Color3.fromRGB(255, 140, 180),
        Info = "3x Lift (10m)",
        Image = "rbxassetid://128138101912438",
        DefaultAutoBuy = false
    },
    ["Luck Potion II"] = {
        Category = "Potion",
        DisplayName = "Luck Potion II",
        Order = 7,
        Cost = 120,
        StockMinimum = 0,
        StockChance = 3,
        StockRolls = 4,
        RarityTag = "⭐ 11.5%",
        TagColor = Color3.fromRGB(180, 80, 255),
        Info = "4x Luck (10m)",
        Image = "rbxassetid://90940157491160",
        DefaultAutoBuy = true
    },
    ["Speed"] = {
        Category = "Upgrade",
        DisplayName = "Speed (+1)",
        Order = 8,
        Cost = 75,
        StockMinimum = 0,
        StockChance = 2,
        StockRolls = 5,
        RarityTag = "⚡ 9.6%",
        TagColor = Color3.fromRGB(255, 210, 60),
        Info = "+1 Perm Speed",
        Image = "rbxassetid://86964499984867",
        DefaultAutoBuy = false
    },
    ["Kick Mastery"] = {
        Category = "Upgrade",
        DisplayName = "Kick Mastery (+25)",
        Order = 9,
        Cost = 75,
        StockMinimum = 1,
        StockChance = 5,
        StockRolls = 5,
        RarityTag = "🟢 100%",
        TagColor = Color3.fromRGB(80, 225, 120),
        Info = "+25 Tokens",
        Image = "rbxassetid://109332270777080",
        DefaultAutoBuy = false
    },
    ["Skip 1h Cash"] = {
        Category = "Upgrade",
        DisplayName = "Skip 1h Cash",
        Order = 10,
        Cost = 75,
        StockMinimum = 0,
        StockChance = 5,
        StockRolls = 5,
        RarityTag = "⏳ 22.6%",
        TagColor = Color3.fromRGB(200, 180, 255),
        Info = "Skips 1h Cash",
        Image = "rbxassetid://138737171119064",
        DefaultAutoBuy = false
    },
    ["Patagotitan"] = {
        Category = "Brainrot",
        DisplayName = "Patagotitan",
        Order = 11,
        Cost = 500,
        StockMinimum = 0,
        StockChance = 2,
        StockRolls = 3,
        RarityTag = "💎 5.9%",
        TagColor = Color3.fromRGB(255, 110, 80),
        Info = "+150% CP/s",
        Image = "rbxassetid://95399484334874",
        DefaultAutoBuy = false
    },
    ["Frigorex"] = {
        Category = "Brainrot",
        DisplayName = "Frigorex",
        Order = 12,
        Cost = 1250,
        StockMinimum = 0,
        StockChance = 2,
        StockRolls = 1,
        RarityTag = "💎 2.0%",
        TagColor = Color3.fromRGB(255, 75, 130),
        Info = "+250% CP/s (Best)",
        Image = "rbxassetid://140510107418430",
        DefaultAutoBuy = true
    },
    ["Meteor Kick"] = {
        Category = "Special",
        DisplayName = "Meteor Kick",
        Order = 13,
        Cost = 1500,
        StockMinimum = 0,
        StockChance = 4,
        StockRolls = 1,
        RarityTag = "🔥 4.0%",
        TagColor = Color3.fromRGB(255, 160, 40),
        Info = "1.25x Kick Dist",
        Image = "rbxassetid://133331609155814",
        DefaultAutoBuy = false
    }
}

local ORDERED_ITEMS = {}
for name, data in pairs(SHOP_ITEMS) do
    table.insert(ORDERED_ITEMS, { Name = name, Data = data })
end
table.sort(ORDERED_ITEMS, function(a, b) return (a.Data.Order or 0) < (b.Data.Order or 0) end)

-- ==============================================================================
-- 🔮 3. SIMULASI ENGINE PRNG PREDICTOR
-- ==============================================================================
local function simulateStockForTimestamp(targetTimestamp)
    local seed = math.floor(targetTimestamp / RESTOCK_INTERVAL)
    local rng = Random.new(seed)
    local simResults = {}

    for _, itemObj in ipairs(ORDERED_ITEMS) do
        local itemName = itemObj.Name
        local itemData = itemObj.Data
        local initialStock = itemData.StockMinimum or 0
        local stockWon = initialStock
        
        for roll = 1, (itemData.StockRolls or 1) do
            local rollVal = rng:NextInteger(1, 100)
            if rollVal <= (itemData.StockChance or 0) then
                stockWon = stockWon + 1
            end
        end
        
        simResults[itemName] = {
            Stock = stockWon,
            Max = math.max(1, stockWon)
        }
    end

    return simResults
end

-- ==============================================================================
-- 🧠 4. STATE DATA STORE
-- ==============================================================================
local currentStockData = {}
local autoBuySettings = {}
local nextExpiryTimestamp = os.time() + 1800
local lastSyncTimestamp = 0
local currentViewMode = "Live" -- "Live", "Future", "Target", "History"
local selectedTargetItem = "Frigorex"
local selectedFutureCycleIndex = 0 -- 0 = Restock 1 (+30m), 1 = Restock 2 (+1h), dst...
local restockHistoryLog = {}

for itemName, itemInfo in pairs(SHOP_ITEMS) do
    currentStockData[itemName] = { Stock = 0, Max = 0 }
    autoBuySettings[itemName] = itemInfo.DefaultAutoBuy or false
end

-- ==============================================================================
-- 🎨 5. GUI CONTAINER & INITIALIZATION
-- ==============================================================================
local function getGuiContainer()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    if game:GetService("CoreGui") then
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok and cg then return cg end
    end
    return lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5))
end

local targetParent = getGuiContainer()

pcall(function()
    if targetParent and targetParent:FindFirstChild("MeteorStockPredictGui") then
        targetParent.MeteorStockPredictGui:Destroy()
    end
    if lp and lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("MeteorStockPredictGui") then
        lp.PlayerGui.MeteorStockPredictGui:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeteorStockPredictGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 99999
ScreenGui.Enabled = true
ScreenGui.Parent = targetParent

-- ==============================================================================
-- 🖼️ 6. DESAIN UI UTAMA (COMPACT: 280 x 310 px)
-- ==============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 310)
MainFrame.Position = UDim2.new(0, 15, 0.5, -155)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 145, 30)
MainStroke.Thickness = 1.2
MainStroke.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 140, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "☄️ METEOR PREDICTOR"
TitleLabel.TextColor3 = Color3.fromRGB(255, 170, 50)
TitleLabel.TextSize = 11
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -26, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 30)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 90, 100)
CloseBtn.TextSize = 10
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar
local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 4)
CloseBtnCorner.Parent = CloseBtn

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 20, 0, 20)
MinBtn.Position = UDim2.new(1, -50, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(180, 200, 230)
MinBtn.TextSize = 10
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TopBar
local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 4)
MinBtnCorner.Parent = MinBtn

local SyncBtn = Instance.new("TextButton")
SyncBtn.Name = "SyncBtn"
SyncBtn.Size = UDim2.new(0, 48, 0, 20)
SyncBtn.Position = UDim2.new(1, -102, 0, 5)
SyncBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
SyncBtn.Font = Enum.Font.GothamBold
SyncBtn.Text = "🔄 Sync"
SyncBtn.TextColor3 = Color3.fromRGB(120, 210, 255)
SyncBtn.TextSize = 9
SyncBtn.BorderSizePixel = 0
SyncBtn.Parent = TopBar
local SyncBtnCorner = Instance.new("UICorner")
SyncBtnCorner.CornerRadius = UDim.new(0, 4)
SyncBtnCorner.Parent = SyncBtn

-- ==============================================================================
-- 🧭 7. 4 TAB NAVIGATION (LIVE | ALL PREDICT | TARGET ITEM | LOG)
-- ==============================================================================
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -12, 0, 26)
TabBar.Position = UDim2.new(0, 6, 0, 34)
TabBar.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame
local TabBarCorner = Instance.new("UICorner")
TabBarCorner.CornerRadius = UDim.new(0, 5)
TabBarCorner.Parent = TabBar

local tabButtons = {}
local tabList = {
    { Id = "Live", Name = "📦 Live" },
    { Id = "Future", Name = "🔮 All" },
    { Id = "Target", Name = "🎯 Target" },
    { Id = "History", Name = "📜 Log" }
}

for i, tData in ipairs(tabList) do
    local tBtn = Instance.new("TextButton")
    tBtn.Name = "Tab_" .. tData.Id
    tBtn.Size = UDim2.new(0.25, -2, 1, -2)
    tBtn.Position = UDim2.new((i - 1) * 0.25, 1, 0, 1)
    tBtn.BackgroundColor3 = (tData.Id == "Live") and Color3.fromRGB(255, 145, 30) or Color3.fromRGB(26, 32, 44)
    tBtn.Font = Enum.Font.GothamBold
    tBtn.Text = tData.Name
    tBtn.TextColor3 = (tData.Id == "Live") and Color3.fromRGB(15, 20, 30) or Color3.fromRGB(190, 205, 230)
    tBtn.TextSize = 9
    tBtn.BorderSizePixel = 0
    tBtn.Parent = TabBar

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 4)
    tCorner.Parent = tBtn

    tabButtons[tData.Id] = tBtn
end

-- ==============================================================================
-- ⏱️ 8. COUNTDOWN BANNER (SUPER COMPACT)
-- ==============================================================================
local BannerFrame = Instance.new("Frame")
BannerFrame.Name = "BannerFrame"
BannerFrame.Size = UDim2.new(1, -12, 0, 22)
BannerFrame.Position = UDim2.new(0, 6, 0, 64)
BannerFrame.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
BannerFrame.BorderSizePixel = 0
BannerFrame.Parent = MainFrame

local BannerCorner = Instance.new("UICorner")
BannerCorner.CornerRadius = UDim.new(0, 4)
BannerCorner.Parent = BannerFrame

local CountdownLabel = Instance.new("TextLabel")
CountdownLabel.Name = "CountdownLabel"
CountdownLabel.Size = UDim2.new(0.5, 0, 1, 0)
CountdownLabel.Position = UDim2.new(0, 6, 0, 0)
CountdownLabel.BackgroundTransparency = 1
CountdownLabel.Font = Enum.Font.GothamBold
CountdownLabel.Text = "⏳ --:--"
CountdownLabel.TextColor3 = Color3.fromRGB(255, 205, 70)
CountdownLabel.TextSize = 10
CountdownLabel.TextXAlignment = Enum.TextXAlignment.Left
CountdownLabel.Parent = BannerFrame

local TargetTimeLabel = Instance.new("TextLabel")
TargetTimeLabel.Name = "TargetTimeLabel"
TargetTimeLabel.Size = UDim2.new(0.5, -6, 1, 0)
TargetTimeLabel.Position = UDim2.new(0.5, 0, 0, 0)
TargetTimeLabel.BackgroundTransparency = 1
TargetTimeLabel.Font = Enum.Font.GothamBold
TargetTimeLabel.Text = "⏰ WIB: --:--"
TargetTimeLabel.TextColor3 = Color3.fromRGB(140, 225, 170)
TargetTimeLabel.TextSize = 9
TargetTimeLabel.TextXAlignment = Enum.TextXAlignment.Right
TargetTimeLabel.Parent = BannerFrame

-- ==============================================================================
-- 📜 9. SCROLLING VIEW CONTAINER (DENGAN AUTO CANVAS SIZE FIX)
-- ==============================================================================
local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Name = "ScrollList"
ScrollList.Size = UDim2.new(1, -12, 1, -94)
ScrollList.Position = UDim2.new(0, 6, 0, 88)
ScrollList.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
ScrollList.BorderSizePixel = 0
ScrollList.ScrollBarThickness = 4
ScrollList.ScrollBarImageColor3 = Color3.fromRGB(255, 145, 30)
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 500)
ScrollList.Parent = MainFrame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 5)
ScrollCorner.Parent = ScrollList

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollList

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 4)
ListPadding.PaddingBottom = UDim.new(0, 10)
ListPadding.PaddingLeft = UDim.new(0, 4)
ListPadding.PaddingRight = UDim.new(0, 4)
ListPadding.Parent = ScrollList

-- ==============================================================================
-- 📦 10. LIVE ITEMS GENERATOR
-- ==============================================================================
local liveCardElements = {}

local function createLiveCard(itemName, itemData)
    local Card = Instance.new("Frame")
    Card.Name = "LiveCard_" .. itemName
    Card.Size = UDim2.new(1, 0, 0, 44)
    Card.BackgroundColor3 = Color3.fromRGB(24, 30, 42)
    Card.BorderSizePixel = 0
    Card.LayoutOrder = itemData.Order or 99
    Card.Parent = ScrollList

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 5)
    CardCorner.Parent = Card

    local IconBg = Instance.new("Frame")
    IconBg.Size = UDim2.new(0, 32, 0, 32)
    IconBg.Position = UDim2.new(0, 5, 0, 6)
    IconBg.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    IconBg.BorderSizePixel = 0
    IconBg.Parent = Card
    local IconBgCorner = Instance.new("UICorner")
    IconBgCorner.CornerRadius = UDim.new(0, 4)
    IconBgCorner.Parent = IconBg

    local Thumbnail = Instance.new("ImageLabel")
    Thumbnail.Size = UDim2.new(1, -2, 1, -2)
    Thumbnail.Position = UDim2.new(0, 1, 0, 1)
    Thumbnail.BackgroundTransparency = 1
    Thumbnail.Image = itemData.Image or ""
    Thumbnail.ScaleType = Enum.ScaleType.Fit
    Thumbnail.Parent = IconBg

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0, 115, 0, 14)
    NameLabel.Position = UDim2.new(0, 42, 0, 5)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.Text = itemData.DisplayName
    NameLabel.TextColor3 = Color3.fromRGB(250, 250, 255)
    NameLabel.TextSize = 10
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Card

    local CostLabel = Instance.new("TextLabel")
    CostLabel.Size = UDim2.new(0, 115, 0, 12)
    CostLabel.Position = UDim2.new(0, 42, 0, 22)
    CostLabel.BackgroundTransparency = 1
    CostLabel.Font = Enum.Font.Gotham
    CostLabel.Text = string.format("☄️ %d | %s", itemData.Cost or 0, itemData.RarityTag)
    CostLabel.TextColor3 = itemData.TagColor or Color3.fromRGB(255, 175, 45)
    CostLabel.TextSize = 8
    CostLabel.TextXAlignment = Enum.TextXAlignment.Left
    CostLabel.Parent = Card

    -- Stock Badge
    local StockBadge = Instance.new("Frame")
    StockBadge.Size = UDim2.new(0, 48, 0, 15)
    StockBadge.Position = UDim2.new(1, -54, 0, 4)
    StockBadge.BackgroundColor3 = Color3.fromRGB(35, 22, 26)
    StockBadge.BorderSizePixel = 0
    StockBadge.Parent = Card
    local StockCorner = Instance.new("UICorner")
    StockCorner.CornerRadius = UDim.new(0, 3)
    StockCorner.Parent = StockBadge

    local StockLabel = Instance.new("TextLabel")
    StockLabel.Name = "StockLabel"
    StockLabel.Size = UDim2.new(1, 0, 1, 0)
    StockLabel.BackgroundTransparency = 1
    StockLabel.Font = Enum.Font.GothamBold
    StockLabel.Text = "Stok: 0"
    StockLabel.TextColor3 = Color3.fromRGB(255, 80, 95)
    StockLabel.TextSize = 8
    StockLabel.Parent = StockBadge

    local BuyBtn = Instance.new("TextButton")
    BuyBtn.Name = "BuyBtn"
    BuyBtn.Size = UDim2.new(0, 22, 0, 16)
    BuyBtn.Position = UDim2.new(1, -54, 0, 22)
    BuyBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
    BuyBtn.Font = Enum.Font.GothamBold
    BuyBtn.Text = "🛒"
    BuyBtn.TextColor3 = Color3.fromRGB(160, 210, 255)
    BuyBtn.TextSize = 9
    BuyBtn.BorderSizePixel = 0
    BuyBtn.Parent = Card
    local BuyBtnCorner = Instance.new("UICorner")
    BuyBtnCorner.CornerRadius = UDim.new(0, 3)
    BuyBtnCorner.Parent = BuyBtn

    local AutoBuyBtn = Instance.new("TextButton")
    AutoBuyBtn.Name = "AutoBuyBtn"
    AutoBuyBtn.Size = UDim2.new(0, 24, 0, 16)
    AutoBuyBtn.Position = UDim2.new(1, -30, 0, 22)
    AutoBuyBtn.BackgroundColor3 = autoBuySettings[itemName] and Color3.fromRGB(30, 90, 55) or Color3.fromRGB(36, 40, 52)
    AutoBuyBtn.Font = Enum.Font.GothamBold
    AutoBuyBtn.Text = autoBuySettings[itemName] and "⚡ON" or "⚡OFF"
    AutoBuyBtn.TextColor3 = autoBuySettings[itemName] and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(160, 175, 195)
    AutoBuyBtn.TextSize = 7
    AutoBuyBtn.BorderSizePixel = 0
    AutoBuyBtn.Parent = Card
    local AutoBuyCorner = Instance.new("UICorner")
    AutoBuyCorner.CornerRadius = UDim.new(0, 3)
    AutoBuyCorner.Parent = AutoBuyBtn

    BuyBtn.Activated:Connect(function()
        pcall(function()
            local buyRemote = rev_MeteorShop_Buy or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy"))
            if buyRemote then
                buyRemote:FireServer(itemName)
                print(string.format("🛒 [BUY] Membeli %s...", itemName))
            end
        end)
    end)

    AutoBuyBtn.Activated:Connect(function()
        autoBuySettings[itemName] = not autoBuySettings[itemName]
        local isEnabled = autoBuySettings[itemName]
        AutoBuyBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(30, 90, 55) or Color3.fromRGB(36, 40, 52)
        AutoBuyBtn.Text = isEnabled and "⚡ON" or "⚡OFF"
        AutoBuyBtn.TextColor3 = isEnabled and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(160, 175, 195)
    end)

    liveCardElements[itemName] = {
        Card = Card,
        StockLabel = StockLabel,
        StockBadge = StockBadge,
        AutoBuyBtn = AutoBuyBtn,
        DisplayName = itemData.DisplayName
    }
end

for _, itemObj in ipairs(ORDERED_ITEMS) do
    createLiveCard(itemObj.Name, itemObj.Data)
end

-- ==============================================================================
-- 🔮 11. ALL PREDICTIONS CONTAINER (NAVIGATOR 48 JAM + FULL LIST)
-- ==============================================================================
local futureContainer = Instance.new("Frame")
futureContainer.Name = "FutureContainer"
futureContainer.Size = UDim2.new(1, 0, 0, 0)
futureContainer.BackgroundTransparency = 1
futureContainer.Visible = false
futureContainer.Parent = ScrollList

local futureLayout = Instance.new("UIListLayout")
futureLayout.Padding = UDim.new(0, 4)
futureLayout.SortOrder = Enum.SortOrder.LayoutOrder
futureLayout.Parent = futureContainer

local function renderFuturePredictions()
    futureContainer:ClearAllChildren()

    local baseTs = (nextExpiryTimestamp > 0) and nextExpiryTimestamp or (os.time() + 1800)
    local now = os.time()

    -- 1. Time Navigator Bar (Pilih Jadwal 48 Jam)
    local NavFrame = Instance.new("Frame")
    NavFrame.Size = UDim2.new(1, 0, 0, 28)
    NavFrame.BackgroundColor3 = Color3.fromRGB(20, 26, 36)
    NavFrame.BorderSizePixel = 0
    NavFrame.LayoutOrder = 1
    NavFrame.Parent = futureContainer

    local NCorner = Instance.new("UICorner")
    NCorner.CornerRadius = UDim.new(0, 4)
    NCorner.Parent = NavFrame

    local PrevBtn = Instance.new("TextButton")
    PrevBtn.Size = UDim2.new(0, 24, 1, -4)
    PrevBtn.Position = UDim2.new(0, 2, 0, 2)
    PrevBtn.BackgroundColor3 = Color3.fromRGB(30, 38, 52)
    PrevBtn.Font = Enum.Font.GothamBold
    PrevBtn.Text = "◀"
    PrevBtn.TextColor3 = (selectedFutureCycleIndex > 0) and Color3.fromRGB(255, 170, 50) or Color3.fromRGB(100, 115, 135)
    PrevBtn.TextSize = 10
    PrevBtn.BorderSizePixel = 0
    PrevBtn.Parent = NavFrame
    local PBCorner = Instance.new("UICorner")
    PBCorner.CornerRadius = UDim.new(0, 3)
    PBCorner.Parent = PrevBtn

    local NextBtn = Instance.new("TextButton")
    NextBtn.Size = UDim2.new(0, 24, 1, -4)
    NextBtn.Position = UDim2.new(1, -26, 0, 2)
    NextBtn.BackgroundColor3 = Color3.fromRGB(30, 38, 52)
    NextBtn.Font = Enum.Font.GothamBold
    NextBtn.Text = "▶"
    NextBtn.TextColor3 = (selectedFutureCycleIndex < 95) and Color3.fromRGB(255, 170, 50) or Color3.fromRGB(100, 115, 135)
    NextBtn.TextSize = 10
    NextBtn.BorderSizePixel = 0
    NextBtn.Parent = NavFrame
    local NBCorner = Instance.new("UICorner")
    NBCorner.CornerRadius = UDim.new(0, 3)
    NBCorner.Parent = NextBtn

    local curTs = baseTs + (selectedFutureCycleIndex * RESTOCK_INTERVAL)
    local curWib = os.date("!*t", curTs + (7 * 3600))
    local nowWib = os.date("!*t", now + (7 * 3600))
    local diffSec = math.max(0, curTs - now)
    local diffHours = math.floor(diffSec / 3600)
    local diffMins = math.floor((diffSec % 3600) / 60)

    local dayTag = "Hari Ini"
    if curWib.yday > nowWib.yday or (curWib.year > nowWib.year) then
        if curWib.yday == nowWib.yday + 1 then
            dayTag = "Besok"
        else
            dayTag = string.format("%02d/%02d", curWib.day, curWib.month)
        end
    end

    local NavLabel = Instance.new("TextLabel")
    NavLabel.Size = UDim2.new(1, -56, 1, 0)
    NavLabel.Position = UDim2.new(0, 28, 0, 0)
    NavLabel.BackgroundTransparency = 1
    NavLabel.Font = Enum.Font.GothamBold
    NavLabel.Text = string.format("⏰ #%d: %02d:%02d WIB (%s, +%dj%dm)", selectedFutureCycleIndex + 1, curWib.hour, curWib.min, dayTag, diffHours, diffMins)
    NavLabel.TextColor3 = Color3.fromRGB(255, 205, 80)
    NavLabel.TextSize = 9
    NavLabel.Parent = NavFrame

    PrevBtn.Activated:Connect(function()
        if selectedFutureCycleIndex > 0 then
            selectedFutureCycleIndex = selectedFutureCycleIndex - 1
            renderFuturePredictions()
        end
    end)

    NextBtn.Activated:Connect(function()
        if selectedFutureCycleIndex < 95 then
            selectedFutureCycleIndex = selectedFutureCycleIndex + 1
            renderFuturePredictions()
        end
    end)

    -- 2. Render Prediksi untuk Jam Terpilih
    local simStock = simulateStockForTimestamp(curTs)
    local totalReadyCount = 0

    for idx, itemObj in ipairs(ORDERED_ITEMS) do
        local itemName = itemObj.Name
        local itemData = itemObj.Data
        local predData = simStock[itemName]
        local stockNum = predData and predData.Stock or 0
        if stockNum > 0 then totalReadyCount = totalReadyCount + 1 end

        local ItemRow = Instance.new("Frame")
        ItemRow.Size = UDim2.new(1, 0, 0, 20)
        ItemRow.BackgroundColor3 = (stockNum > 0) and Color3.fromRGB(26, 34, 46) or Color3.fromRGB(18, 22, 30)
        ItemRow.BorderSizePixel = 0
        ItemRow.LayoutOrder = 10 + itemData.Order
        ItemRow.Parent = futureContainer

        local IRowCorner = Instance.new("UICorner")
        IRowCorner.CornerRadius = UDim.new(0, 3)
        IRowCorner.Parent = ItemRow

        local RowName = Instance.new("TextLabel")
        RowName.Size = UDim2.new(0.65, 0, 1, 0)
        RowName.Position = UDim2.new(0, 6, 0, 0)
        RowName.BackgroundTransparency = 1
        RowName.Font = (stockNum > 0) and Enum.Font.GothamBold or Enum.Font.Gotham
        RowName.Text = itemData.DisplayName
        RowName.TextColor3 = (stockNum > 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 145, 170)
        RowName.TextSize = 9
        RowName.TextXAlignment = Enum.TextXAlignment.Left
        RowName.Parent = ItemRow

        local RowResult = Instance.new("TextLabel")
        RowResult.Size = UDim2.new(0.35, -6, 1, 0)
        RowResult.Position = UDim2.new(0.65, 0, 0, 0)
        RowResult.BackgroundTransparency = 1
        RowResult.Font = Enum.Font.GothamBold
        if stockNum > 0 then
            if itemName == "Frigorex" or itemName == "Patagotitan" or itemName == "Meteor Kick" then
                RowResult.Text = string.format("🔥 READY (%d)", stockNum)
                RowResult.TextColor3 = Color3.fromRGB(255, 80, 130)
            else
                RowResult.Text = string.format("✅ Ready (%d)", stockNum)
                RowResult.TextColor3 = Color3.fromRGB(90, 245, 140)
            end
        else
            RowResult.Text = "❌ 0"
            RowResult.TextColor3 = Color3.fromRGB(140, 75, 85)
        end
        RowResult.TextSize = 9
        RowResult.TextXAlignment = Enum.TextXAlignment.Right
        RowResult.Parent = ItemRow
    end

    -- Update Canvas Size
    task.defer(function()
        ScrollList.CanvasSize = UDim2.new(0, 0, 0, futureLayout.AbsoluteContentSize.Y + 20)
    end)
end

-- ==============================================================================
-- 🎯 12. TARGET ITEM PREDICTOR CONTAINER (PILIH ITEM & CARI JADWAL 48 JAM)
-- ==============================================================================
local targetContainer = Instance.new("Frame")
targetContainer.Name = "TargetContainer"
targetContainer.Size = UDim2.new(1, 0, 0, 0)
targetContainer.BackgroundTransparency = 1
targetContainer.Visible = false
targetContainer.Parent = ScrollList

local targetLayout = Instance.new("UIListLayout")
targetLayout.Padding = UDim.new(0, 4)
targetLayout.SortOrder = Enum.SortOrder.LayoutOrder
targetLayout.Parent = targetContainer

local function renderTargetItemPredictions()
    targetContainer:ClearAllChildren()

    -- 1. Selector Bar
    local SelectorFrame = Instance.new("Frame")
    SelectorFrame.Size = UDim2.new(1, 0, 0, 26)
    SelectorFrame.BackgroundColor3 = Color3.fromRGB(20, 26, 36)
    SelectorFrame.BorderSizePixel = 0
    SelectorFrame.LayoutOrder = 1
    SelectorFrame.Parent = targetContainer

    local SCorner = Instance.new("UICorner")
    SCorner.CornerRadius = UDim.new(0, 4)
    SCorner.Parent = SelectorFrame

    local SelectTitle = Instance.new("TextLabel")
    SelectTitle.Size = UDim2.new(0.35, 0, 1, 0)
    SelectTitle.Position = UDim2.new(0, 6, 0, 0)
    SelectTitle.BackgroundTransparency = 1
    SelectTitle.Font = Enum.Font.GothamBold
    SelectTitle.Text = "🎯 Item:"
    SelectTitle.TextColor3 = Color3.fromRGB(255, 185, 60)
    SelectTitle.TextSize = 9
    SelectTitle.TextXAlignment = Enum.TextXAlignment.Left
    SelectTitle.Parent = SelectorFrame

    local ItemPickerBtn = Instance.new("TextButton")
    ItemPickerBtn.Name = "ItemPickerBtn"
    ItemPickerBtn.Size = UDim2.new(0.65, -8, 1, -4)
    ItemPickerBtn.Position = UDim2.new(0.35, 2, 0, 2)
    ItemPickerBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
    ItemPickerBtn.Font = Enum.Font.GothamBold
    ItemPickerBtn.Text = selectedTargetItem .. " ▼"
    ItemPickerBtn.TextColor3 = Color3.fromRGB(130, 220, 255)
    ItemPickerBtn.TextSize = 9
    ItemPickerBtn.BorderSizePixel = 0
    ItemPickerBtn.Parent = SelectorFrame
    local IPCorner = Instance.new("UICorner")
    IPCorner.CornerRadius = UDim.new(0, 4)
    IPCorner.Parent = ItemPickerBtn

    local QuickGrid = Instance.new("Frame")
    QuickGrid.Name = "QuickGrid"
    QuickGrid.Size = UDim2.new(1, 0, 0, 0)
    QuickGrid.BackgroundTransparency = 1
    QuickGrid.Visible = false
    QuickGrid.LayoutOrder = 2
    QuickGrid.Parent = targetContainer

    local UIGrid = Instance.new("UIGridLayout")
    UIGrid.CellSize = UDim2.new(0.48, 0, 0, 20)
    UIGrid.CellPadding = UDim2.new(0.04, 0, 0, 3)
    UIGrid.Parent = QuickGrid

    for _, it in ipairs(ORDERED_ITEMS) do
        local itBtn = Instance.new("TextButton")
        itBtn.Size = UDim2.new(1, 0, 1, 0)
        itBtn.BackgroundColor3 = (it.Name == selectedTargetItem) and Color3.fromRGB(255, 145, 30) or Color3.fromRGB(24, 30, 42)
        itBtn.Font = Enum.Font.GothamBold
        itBtn.Text = it.Name
        itBtn.TextColor3 = (it.Name == selectedTargetItem) and Color3.fromRGB(15, 20, 30) or Color3.fromRGB(200, 215, 240)
        itBtn.TextSize = 8
        itBtn.BorderSizePixel = 0
        itBtn.Parent = QuickGrid
        local itCorner = Instance.new("UICorner")
        itCorner.CornerRadius = UDim.new(0, 3)
        itCorner.Parent = itBtn

        itBtn.Activated:Connect(function()
            selectedTargetItem = it.Name
            renderTargetItemPredictions()
        end)
    end

    ItemPickerBtn.Activated:Connect(function()
        QuickGrid.Visible = not QuickGrid.Visible
        ItemPickerBtn.Text = selectedTargetItem .. (QuickGrid.Visible and " ▲" or " ▼")
        task.defer(function()
            local qHeight = QuickGrid.Visible and (UIGrid.AbsoluteContentSize.Y + 10) or 0
            QuickGrid.Size = UDim2.new(1, 0, 0, qHeight)
            ScrollList.CanvasSize = UDim2.new(0, 0, 0, targetLayout.AbsoluteContentSize.Y + 30)
        end)
    end)

    -- 2. Scan 48 Jam (96 Interval)
    local baseTs = (nextExpiryTimestamp > 0) and nextExpiryTimestamp or (os.time() + 1800)
    local now = os.time()
    local foundSchedules = {}

    for cycle = 0, 95 do
        local simTs = baseTs + (cycle * RESTOCK_INTERVAL)
        local simStock = simulateStockForTimestamp(simTs)
        local stockWon = simStock[selectedTargetItem] and simStock[selectedTargetItem].Stock or 0

        if stockWon > 0 then
            local diffSec = math.max(0, simTs - now)
            local diffHours = math.floor(diffSec / 3600)
            local diffMins = math.floor((diffSec % 3600) / 60)
            local wibTime = os.date("!*t", simTs + (7 * 3600))
            local nowWib = os.date("!*t", now + (7 * 3600))

            local dayTag = "Hari Ini"
            if wibTime.yday > nowWib.yday or (wibTime.year > nowWib.year) then
                if wibTime.yday == nowWib.yday + 1 then
                    dayTag = "Besok"
                else
                    dayTag = string.format("%02d/%02d", wibTime.day, wibTime.month)
                end
            end

            table.insert(foundSchedules, {
                Cycle = cycle + 1,
                TimeStr = string.format("%02d:%02d WIB (%s)", wibTime.hour, wibTime.min, dayTag),
                RelStr = (diffHours > 0) and string.format("+%dj%dm", diffHours, diffMins) or string.format("+%dm", diffMins),
                Stock = stockWon
            })
        end
    end

    -- 3. Header Info Hasil
    local ResultHeader = Instance.new("Frame")
    ResultHeader.Size = UDim2.new(1, 0, 0, 22)
    ResultHeader.BackgroundColor3 = Color3.fromRGB(25, 32, 46)
    ResultHeader.BorderSizePixel = 0
    ResultHeader.LayoutOrder = 3
    ResultHeader.Parent = targetContainer
    local RCorner = Instance.new("UICorner")
    RCorner.CornerRadius = UDim.new(0, 4)
    RCorner.Parent = ResultHeader

    local RLabel = Instance.new("TextLabel")
    RLabel.Size = UDim2.new(1, -10, 1, 0)
    RLabel.Position = UDim2.new(0, 5, 0, 0)
    RLabel.BackgroundTransparency = 1
    RLabel.Font = Enum.Font.GothamBold
    RLabel.Text = string.format("⏰ Jadwal Stok %s (48 Jam):", selectedTargetItem)
    RLabel.TextColor3 = Color3.fromRGB(120, 220, 255)
    RLabel.TextSize = 9
    RLabel.TextXAlignment = Enum.TextXAlignment.Left
    RLabel.Parent = ResultHeader

    -- 4. Render List Jadwal
    if #foundSchedules == 0 then
        local EmptyBox = Instance.new("TextLabel")
        EmptyBox.Size = UDim2.new(1, 0, 0, 30)
        EmptyBox.BackgroundTransparency = 1
        EmptyBox.Font = Enum.Font.GothamMedium
        EmptyBox.Text = "Belum terprediksi dalam 48 jam."
        EmptyBox.TextColor3 = Color3.fromRGB(150, 165, 185)
        EmptyBox.TextSize = 9
        EmptyBox.LayoutOrder = 4
        EmptyBox.Parent = targetContainer
    else
        for idx, sched in ipairs(foundSchedules) do
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 24)
            Row.BackgroundColor3 = (idx == 1) and Color3.fromRGB(36, 50, 36) or Color3.fromRGB(22, 28, 38)
            Row.BorderSizePixel = 0
            Row.LayoutOrder = 10 + idx
            Row.Parent = targetContainer

            local RowCorner = Instance.new("UICorner")
            RowCorner.CornerRadius = UDim.new(0, 4)
            RowCorner.Parent = Row

            local RowStroke = Instance.new("UIStroke")
            RowStroke.Color = (idx == 1) and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(45, 55, 75)
            RowStroke.Thickness = (idx == 1) and 1 or 0.5
            RowStroke.Parent = Row

            local TimeTxt = Instance.new("TextLabel")
            TimeTxt.Size = UDim2.new(0.65, 0, 1, 0)
            TimeTxt.Position = UDim2.new(0, 6, 0, 0)
            TimeTxt.BackgroundTransparency = 1
            TimeTxt.Font = Enum.Font.GothamBold
            TimeTxt.Text = string.format("#%d. %s", idx, sched.TimeStr)
            TimeTxt.TextColor3 = (idx == 1) and Color3.fromRGB(100, 255, 140) or Color3.fromRGB(240, 245, 255)
            TimeTxt.TextSize = 8
            TimeTxt.TextXAlignment = Enum.TextXAlignment.Left
            TimeTxt.Parent = Row

            local StockTxt = Instance.new("TextLabel")
            StockTxt.Size = UDim2.new(0.35, -6, 1, 0)
            StockTxt.Position = UDim2.new(0.65, 0, 0, 0)
            StockTxt.BackgroundTransparency = 1
            StockTxt.Font = Enum.Font.GothamBold
            StockTxt.Text = string.format("🔥 %dx (%s)", sched.Stock, sched.RelStr)
            StockTxt.TextColor3 = (idx == 1) and Color3.fromRGB(255, 180, 50) or Color3.fromRGB(180, 200, 230)
            StockTxt.TextSize = 8
            StockTxt.TextXAlignment = Enum.TextXAlignment.Right
            StockTxt.Parent = Row
        end
    end

    -- Update Canvas Size
    task.defer(function()
        ScrollList.CanvasSize = UDim2.new(0, 0, 0, targetLayout.AbsoluteContentSize.Y + 30)
    end)
end

-- ==============================================================================
-- 📜 13. HISTORY LOG CONTAINER
-- ==============================================================================
local historyContainer = Instance.new("Frame")
historyContainer.Name = "HistoryContainer"
historyContainer.Size = UDim2.new(1, 0, 0, 0)
historyContainer.BackgroundTransparency = 1
historyContainer.Visible = false
historyContainer.Parent = ScrollList

local historyLayout = Instance.new("UIListLayout")
historyLayout.Padding = UDim.new(0, 4)
historyLayout.SortOrder = Enum.SortOrder.LayoutOrder
historyLayout.Parent = historyContainer

local function renderHistoryLog()
    historyContainer:ClearAllChildren()

    if #restockHistoryLog == 0 then
        local EmptyText = Instance.new("TextLabel")
        EmptyText.Size = UDim2.new(1, 0, 0, 24)
        EmptyText.BackgroundTransparency = 1
        EmptyText.Font = Enum.Font.GothamMedium
        EmptyText.Text = "Menunggu data restock server..."
        EmptyText.TextColor3 = Color3.fromRGB(140, 155, 180)
        EmptyText.TextSize = 9
        EmptyText.Parent = historyContainer
    else
        for idx, logEntry in ipairs(restockHistoryLog) do
            local LogRow = Instance.new("Frame")
            LogRow.Size = UDim2.new(1, 0, 0, 32)
            LogRow.BackgroundColor3 = Color3.fromRGB(20, 26, 36)
            LogRow.BorderSizePixel = 0
            LogRow.LayoutOrder = idx
            LogRow.Parent = historyContainer

            local LCorner = Instance.new("UICorner")
            LCorner.CornerRadius = UDim.new(0, 4)
            LCorner.Parent = LogRow

            local LTitle = Instance.new("TextLabel")
            LTitle.Size = UDim2.new(1, -10, 0, 14)
            LTitle.Position = UDim2.new(0, 5, 0, 2)
            LTitle.BackgroundTransparency = 1
            LTitle.Font = Enum.Font.GothamBold
            LTitle.Text = string.format("📌 %s WIB", logEntry.TimeStr)
            LTitle.TextColor3 = Color3.fromRGB(255, 170, 50)
            LTitle.TextSize = 9
            LTitle.TextXAlignment = Enum.TextXAlignment.Left
            LTitle.Parent = LogRow

            local LSub = Instance.new("TextLabel")
            LSub.Size = UDim2.new(1, -10, 0, 12)
            LSub.Position = UDim2.new(0, 5, 0, 16)
            LSub.BackgroundTransparency = 1
            LSub.Font = Enum.Font.Gotham
            LSub.Text = string.format("Ready: %s", logEntry.AvailableSummary)
            LSub.TextColor3 = Color3.fromRGB(150, 210, 170)
            LSub.TextSize = 8
            LSub.TextXAlignment = Enum.TextXAlignment.Left
            LSub.Parent = LogRow
        end
    end

    task.defer(function()
        ScrollList.CanvasSize = UDim2.new(0, 0, 0, historyLayout.AbsoluteContentSize.Y + 20)
    end)
end

-- ==============================================================================
-- 🔍 14. VIEW & TAB SWITCHING
-- ==============================================================================
local function switchView(targetMode)
    currentViewMode = targetMode

    for id, btn in pairs(tabButtons) do
        local isSel = (id == currentViewMode)
        btn.BackgroundColor3 = isSel and Color3.fromRGB(255, 145, 30) or Color3.fromRGB(26, 32, 44)
        btn.TextColor3 = isSel and Color3.fromRGB(15, 20, 30) or Color3.fromRGB(190, 205, 230)
    end

    if currentViewMode == "Live" then
        futureContainer.Visible = false
        targetContainer.Visible = false
        historyContainer.Visible = false
        for _, elem in pairs(liveCardElements) do
            elem.Card.Visible = true
        end
        task.defer(function()
            ScrollList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 20)
        end)
    elseif currentViewMode == "Future" then
        for _, elem in pairs(liveCardElements) do
            elem.Card.Visible = false
        end
        targetContainer.Visible = false
        historyContainer.Visible = false
        futureContainer.Visible = true
        renderFuturePredictions()
    elseif currentViewMode == "Target" then
        for _, elem in pairs(liveCardElements) do
            elem.Card.Visible = false
        end
        futureContainer.Visible = false
        historyContainer.Visible = false
        targetContainer.Visible = true
        renderTargetItemPredictions()
    elseif currentViewMode == "History" then
        for _, elem in pairs(liveCardElements) do
            elem.Card.Visible = false
        end
        futureContainer.Visible = false
        targetContainer.Visible = false
        historyContainer.Visible = true
        renderHistoryLog()
    end
end

for tId, tBtn in pairs(tabButtons) do
    tBtn.Activated:Connect(function()
        switchView(tId)
    end)
end

-- ==============================================================================
-- 📡 15. STOCK SYNC & AUTO-BUY
-- ==============================================================================
local function updateStockFromData(stockData, expiryTimestamp)
    if type(stockData) ~= "table" then return end
    lastSyncTimestamp = tick()

    if expiryTimestamp and tonumber(expiryTimestamp) then
        nextExpiryTimestamp = tonumber(expiryTimestamp)
    end

    local readyNames = {}
    for itemName, itemInfo in pairs(stockData) do
        if type(itemInfo) == "table" then
            local count = tonumber(itemInfo.Stock) or 0
            local maxC = tonumber(itemInfo.Max) or 0
            currentStockData[itemName] = { Stock = count, Max = maxC }

            if count > 0 then
                table.insert(readyNames, itemName)
            end

            local elem = liveCardElements[itemName]
            if elem then
                if count > 0 then
                    elem.StockLabel.Text = string.format("Stok: %d/%d", count, maxC)
                    elem.StockLabel.TextColor3 = Color3.fromRGB(90, 255, 140)
                    elem.StockBadge.BackgroundColor3 = Color3.fromRGB(20, 50, 35)
                else
                    elem.StockLabel.Text = "Stok: 0"
                    elem.StockLabel.TextColor3 = Color3.fromRGB(255, 80, 95)
                    elem.StockBadge.BackgroundColor3 = Color3.fromRGB(35, 22, 26)
                end
            end

            if autoBuySettings[itemName] and count > 0 then
                task.spawn(function()
                    for i = 1, count do
                        pcall(function()
                            local buyRemote = rev_MeteorShop_Buy or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy"))
                            if buyRemote then
                                buyRemote:FireServer(itemName)
                                print(string.format("⚡ [AUTO BUY] Beli %s (#%d/%d)...", itemName, i, count))
                            end
                        end)
                        task.wait(0.2)
                    end
                end)
            end
        end
    end

    local wibTime = os.date("!*t", os.time() + (7 * 3600))
    table.insert(restockHistoryLog, 1, {
        TimeStr = string.format("%02d:%02d:%02d", wibTime.hour, wibTime.min, wibTime.sec),
        AvailableSummary = (#readyNames > 0) and table.concat(readyNames, ", ") or "Kosong"
    })
    if #restockHistoryLog > 10 then table.remove(restockHistoryLog, 11) end

    if currentViewMode == "Future" then
        renderFuturePredictions()
    elseif currentViewMode == "Target" then
        renderTargetItemPredictions()
    elseif currentViewMode == "History" then
        renderHistoryLog()
    end
end

if rev_MeteorShop_Stock then
    rev_MeteorShop_Stock.OnClientEvent:Connect(function(stockData, expiryTimestamp)
        updateStockFromData(stockData, expiryTimestamp)
    end)
end

local function sendSyncRequest()
    pcall(function()
        local syncRemote = rev_MeteorShop_RequestSync or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_RequestSync"))
        if syncRemote then
            syncRemote:FireServer()
        end
    end)
end

SyncBtn.Activated:Connect(sendSyncRequest)

task.defer(function()
    task.wait(0.5)
    sendSyncRequest()
end)

-- ==============================================================================
-- ⏱️ 16. COUNTDOWN & REALTIME LOOP
-- ==============================================================================
task.spawn(function()
    while task.wait(1) do
        local now = os.time()
        
        if nextExpiryTimestamp > 0 then
            local timeLeft = math.max(0, nextExpiryTimestamp - now)
            local mins = math.floor(timeLeft / 60)
            local secs = timeLeft % 60
            
            if timeLeft > 0 then
                CountdownLabel.Text = string.format("⏳ %02d:%02d", mins, secs)
                CountdownLabel.TextColor3 = (timeLeft <= 60) and Color3.fromRGB(255, 85, 95) or Color3.fromRGB(255, 205, 70)
            else
                CountdownLabel.Text = "⏳ 00:00 (Restock!)"
                CountdownLabel.TextColor3 = Color3.fromRGB(100, 255, 140)
                sendSyncRequest()
            end

            local targetWib = os.date("!*t", nextExpiryTimestamp + (7 * 3600))
            TargetTimeLabel.Text = string.format("⏰ WIB: %02d:%02d:%02d", targetWib.hour, targetWib.min, targetWib.sec)
        else
            CountdownLabel.Text = "⏳ --:--"
            TargetTimeLabel.Text = "⏰ WIB: Menunggu Sync"
        end

        if tick() - lastSyncTimestamp > 120 then
            sendSyncRequest()
        end
    end
end)

-- ==============================================================================
-- 🖱️ 17. DRAGGABLE & MINI-BUBBLE (TOUCH COMPATIBLE)
-- ==============================================================================
local dragging = false
local dragInput, dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

local isMinimized = false
local FloatingBubble = nil

local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Visible = false

        if not FloatingBubble then
            FloatingBubble = Instance.new("TextButton")
            FloatingBubble.Name = "MeteorStockBubble"
            FloatingBubble.Size = UDim2.new(0, 95, 0, 26)
            FloatingBubble.Position = UDim2.new(0, 10, 0.5, -13)
            FloatingBubble.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
            FloatingBubble.Font = Enum.Font.GothamBold
            FloatingBubble.Text = "☄️ --:--"
            FloatingBubble.TextColor3 = Color3.fromRGB(255, 175, 50)
            FloatingBubble.TextSize = 10
            FloatingBubble.BorderSizePixel = 0
            FloatingBubble.Active = true
            FloatingBubble.Draggable = true
            FloatingBubble.Parent = ScreenGui

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 5)
            bCorner.Parent = FloatingBubble

            local bStroke = Instance.new("UIStroke")
            bStroke.Color = Color3.fromRGB(255, 145, 30)
            bStroke.Thickness = 1.2
            bStroke.Parent = FloatingBubble

            FloatingBubble.Activated:Connect(toggleMinimize)

            task.spawn(function()
                while FloatingBubble and FloatingBubble.Parent do
                    if nextExpiryTimestamp > 0 then
                        local timeLeft = math.max(0, nextExpiryTimestamp - os.time())
                        local mins = math.floor(timeLeft / 60)
                        local secs = timeLeft % 60
                        FloatingBubble.Text = string.format("☄️ %02d:%02d", mins, secs)
                    end
                    task.wait(1)
                end
            end)
        else
            FloatingBubble.Visible = true
        end
    else
        MainFrame.Visible = true
        if FloatingBubble then
            FloatingBubble.Visible = false
        end
    end
end

MinBtn.Activated:Connect(toggleMinimize)
CloseBtn.Activated:Connect(function()
    ScreenGui:Destroy()
end)

print("--------------------------------------------------")
print("☄️ [SUKSES] Meteor Predictor Pro + 48h Future Navigator Siap!")
print("--------------------------------------------------")
