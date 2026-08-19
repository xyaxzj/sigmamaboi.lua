-- ==============================================================================
-- ☄️ KALB METEOR SHOP - LIVE STOCK MONITOR & PREDICTOR PRO
-- ==============================================================================
-- Fitur Utama:
-- 1. ⏱️ Live Restock Countdown: Hitungan mundur realtime (MM:SS) & waktu restock berikutnya (WIB).
-- 2. 🔮 Stock Probability Predictor: Perhitungan matematis akurat peluang stock muncul per restock.
-- 3. 📦 Real-Time Stock Tracker: Live stock monitor langsung dari sync server (Stock / Max).
-- 4. 🛒 Instant Buy & Auto-Buy: Beli manual 1-klik atau aktifkan auto-buy per item saat stock ada.
-- 5. 🔔 Smart Rare Stock Alert: Notifikasi otomatis saat item langka (Frigorex, Patagotitan, dll) ready!
-- 6. 🎨 Premium Glassmorphic UI: Modern dark theme, draggable, tab filter, search bar, & mini-mode.
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

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

-- Fallback scan jika belum ketemu
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
-- 📊 2. METEOR SHOP DATABASE & PREDICTION ENGINE
-- ==============================================================================
local RESTOCK_INTERVAL = 1800 -- 30 Menit

local SHOP_ITEMS = {
    ["Frigorex"] = {
        Category = "Brainrot",
        DisplayName = "Frigorex",
        Order = 1,
        Cost = 1250,
        StockMinimum = 0,
        StockChance = 2, -- 2%
        StockRolls = 1,
        RarityTag = "💎 ULTRA RARE",
        TagColor = Color3.fromRGB(255, 75, 130),
        Info = "250% CP/s Boost (Brainrot Terbaik)",
        Image = "rbxassetid://140510107418430",
        DefaultAutoBuy = true
    },
    ["Patagotitan"] = {
        Category = "Brainrot",
        DisplayName = "Patagotitan",
        Order = 2,
        Cost = 500,
        StockMinimum = 0,
        StockChance = 2,
        StockRolls = 3,
        RarityTag = "💎 ULTRA RARE",
        TagColor = Color3.fromRGB(255, 110, 80),
        Info = "150% CP/s Boost (Brainrot)",
        Image = "rbxassetid://95399484334874",
        DefaultAutoBuy = false
    },
    ["Meteor Kick"] = {
        Category = "Special",
        DisplayName = "Meteor Kick",
        Order = 3,
        Cost = 1500,
        StockMinimum = 0,
        StockChance = 4,
        StockRolls = 1,
        RarityTag = "🔥 EXCLUSIVE",
        TagColor = Color3.fromRGB(255, 160, 40),
        Info = "1.25x Kick Distance Animation",
        Image = "rbxassetid://133331609155814",
        DefaultAutoBuy = false
    },
    ["Farm Potion II"] = {
        Category = "Potion",
        DisplayName = "Farm Potion II",
        Order = 4,
        Cost = 80,
        StockMinimum = 0,
        StockChance = 5,
        StockRolls = 4,
        RarityTag = "⭐ RARE TIER II",
        TagColor = Color3.fromRGB(160, 100, 255),
        Info = "2.5x Kick & Run Speed (10 min)",
        Image = "rbxassetid://81556992722350",
        DefaultAutoBuy = true
    },
    ["Luck Potion II"] = {
        Category = "Potion",
        DisplayName = "Luck Potion II",
        Order = 5,
        Cost = 120,
        StockMinimum = 0,
        StockChance = 3,
        StockRolls = 4,
        RarityTag = "⭐ RARE TIER II",
        TagColor = Color3.fromRGB(180, 80, 255),
        Info = "4x Brainrot & Mutation Luck (10 min)",
        Image = "rbxassetid://90940157491160",
        DefaultAutoBuy = true
    },
    ["Cash Potion II"] = {
        Category = "Potion",
        DisplayName = "Cash Potion II",
        Order = 6,
        Cost = 60,
        StockMinimum = 0,
        StockChance = 5,
        StockRolls = 4,
        RarityTag = "⭐ RARE TIER II",
        TagColor = Color3.fromRGB(100, 220, 255),
        Info = "6x Cash Multiplier (10 min)",
        Image = "rbxassetid://85935283881899",
        DefaultAutoBuy = false
    },
    ["Weight Training Potion II"] = {
        Category = "Potion",
        DisplayName = "Weight Training Potion II",
        Order = 7,
        Cost = 100,
        StockMinimum = 0,
        StockChance = 4,
        StockRolls = 4,
        RarityTag = "⭐ RARE TIER II",
        TagColor = Color3.fromRGB(255, 140, 180),
        Info = "3x Lift Training Speed (10 min)",
        Image = "rbxassetid://128138101912438",
        DefaultAutoBuy = false
    },
    ["Farm Potion"] = {
        Category = "Potion",
        DisplayName = "Farm Potion (Tier 1)",
        Order = 8,
        Cost = 30,
        StockMinimum = 1,
        StockChance = 8,
        StockRolls = 6,
        RarityTag = "🟢 GUARANTEED (100%)",
        TagColor = Color3.fromRGB(80, 225, 120),
        Info = "1.75x Kick & Run Speed (10 min)",
        Image = "rbxassetid://137373210970097",
        DefaultAutoBuy = true
    },
    ["Luck Potion"] = {
        Category = "Potion",
        DisplayName = "Luck Potion (Tier 1)",
        Order = 9,
        Cost = 50,
        StockMinimum = 0,
        StockChance = 6,
        StockRolls = 6,
        RarityTag = "✨ UNCOMMON",
        TagColor = Color3.fromRGB(130, 200, 255),
        Info = "2x Luck & Brainrot Luck (10 min)",
        Image = "rbxassetid://133824459739024",
        DefaultAutoBuy = false
    },
    ["Cash Potion"] = {
        Category = "Potion",
        DisplayName = "Cash Potion (Tier 1)",
        Order = 10,
        Cost = 20,
        StockMinimum = 1,
        StockChance = 8,
        StockRolls = 6,
        RarityTag = "🟢 GUARANTEED (100%)",
        TagColor = Color3.fromRGB(80, 225, 120),
        Info = "3x Cash Multiplier (10 min)",
        Image = "rbxassetid://136230782614378",
        DefaultAutoBuy = false
    },
    ["Weight Training Potion"] = {
        Category = "Potion",
        DisplayName = "Weight Training Potion",
        Order = 11,
        Cost = 40,
        StockMinimum = 1,
        StockChance = 7,
        StockRolls = 6,
        RarityTag = "🟢 GUARANTEED (100%)",
        TagColor = Color3.fromRGB(80, 225, 120),
        Info = "2x Lift Training Speed (10 min)",
        Image = "rbxassetid://102337170718354",
        DefaultAutoBuy = false
    },
    ["Kick Mastery"] = {
        Category = "Upgrade",
        DisplayName = "Kick Mastery (+25)",
        Order = 12,
        Cost = 75,
        StockMinimum = 1,
        StockChance = 5,
        StockRolls = 5,
        RarityTag = "🟢 GUARANTEED (100%)",
        TagColor = Color3.fromRGB(80, 225, 120),
        Info = "Permanent +25 Kick Mastery Tokens",
        Image = "rbxassetid://109332270777080",
        DefaultAutoBuy = false
    },
    ["Speed"] = {
        Category = "Upgrade",
        DisplayName = "Speed (+1)",
        Order = 13,
        Cost = 75,
        StockMinimum = 0,
        StockChance = 2,
        StockRolls = 5,
        RarityTag = "⚡ UPGRADE",
        TagColor = Color3.fromRGB(255, 210, 60),
        Info = "Permanent +1 Movement Speed",
        Image = "rbxassetid://86964499984867",
        DefaultAutoBuy = false
    },
    ["Skip 1h Cash"] = {
        Category = "Upgrade",
        DisplayName = "Skip 1h Cash",
        Order = 14,
        Cost = 75,
        StockMinimum = 0,
        StockChance = 5,
        StockRolls = 5,
        RarityTag = "⏳ TIME SKIP",
        TagColor = Color3.fromRGB(200, 180, 255),
        Info = "Instantly skips 1 hour of cash generation",
        Image = "rbxassetid://138737171119064",
        DefaultAutoBuy = false
    }
}

-- Hitung Probabilitas Matematis P = 1 - (1 - p)^n
local function calculateStockProbability(itemData)
    if (itemData.StockMinimum or 0) > 0 then
        return 100.0
    end
    local p = (itemData.StockChance or 0) / 100
    local n = itemData.StockRolls or 1
    local probAtLeastOne = 1 - math.pow((1 - p), n)
    return math.clamp(probAtLeastOne * 100, 0, 100)
end

-- ==============================================================================
-- 🧠 3. STATE & REAL-TIME DATA STORE
-- ==============================================================================
local currentStockData = {}
local autoBuySettings = {}
local nextExpiryTimestamp = 0
local lastSyncTimestamp = 0
local activeTab = "All"
local searchQuery = ""

for itemName, itemInfo in pairs(SHOP_ITEMS) do
    currentStockData[itemName] = { Stock = 0, Max = 0 }
    autoBuySettings[itemName] = itemInfo.DefaultAutoBuy or false
end

-- ==============================================================================
-- 🎨 4. GUI CONTAINER & INITIALIZATION
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

-- Hapus instance lama jika ada
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
-- 🖼️ 5. DESAIN UI UTAMA (PREMIUM DARK GLASSMORPHISM)
-- ==============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 580)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -290)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 145, 30)
MainStroke.Thickness = 1.6
MainStroke.Transparency = 0.2
MainStroke.Parent = MainFrame

-- Top Bar (Draggable Area)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 46)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 12)
TopBarCorner.Parent = TopBar

local TopBarBottomCover = Instance.new("Frame")
TopBarBottomCover.Size = UDim2.new(1, 0, 0, 12)
TopBarBottomCover.Position = UDim2.new(0, 0, 1, -12)
TopBarBottomCover.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
TopBarBottomCover.BorderSizePixel = 0
TopBarBottomCover.Parent = TopBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 30, 0, 30)
TitleIcon.Position = UDim2.new(0, 12, 0, 8)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.Text = "☄️"
TitleIcon.TextSize = 20
TitleIcon.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 260, 0, 22)
TitleLabel.Position = UDim2.new(0, 46, 0, 6)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "METEOR STOCK PREDICTOR"
TitleLabel.TextColor3 = Color3.fromRGB(255, 170, 50)
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Size = UDim2.new(0, 260, 0, 14)
SubTitleLabel.Position = UDim2.new(0, 46, 0, 26)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Font = Enum.Font.GothamMedium
SubTitleLabel.Text = "Live Odds Calculator & Instant Auto-Buyer"
SubTitleLabel.TextColor3 = Color3.fromRGB(150, 165, 190)
SubTitleLabel.TextSize = 10
SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubTitleLabel.Parent = TopBar

-- Top Action Buttons (Sync, Minimize, Close)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0, 9)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 90, 100)
CloseBtn.TextSize = 13
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar
local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -72, 0, 9)
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(180, 200, 230)
MinBtn.TextSize = 13
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TopBar
local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 6)
MinBtnCorner.Parent = MinBtn

local SyncBtn = Instance.new("TextButton")
SyncBtn.Name = "SyncBtn"
SyncBtn.Size = UDim2.new(0, 78, 0, 28)
SyncBtn.Position = UDim2.new(1, -156, 0, 9)
SyncBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
SyncBtn.Font = Enum.Font.GothamBold
SyncBtn.Text = "🔄 Sync"
SyncBtn.TextColor3 = Color3.fromRGB(120, 210, 255)
SyncBtn.TextSize = 11
SyncBtn.BorderSizePixel = 0
SyncBtn.Parent = TopBar
local SyncBtnCorner = Instance.new("UICorner")
SyncBtnCorner.CornerRadius = UDim.new(0, 6)
SyncBtnCorner.Parent = SyncBtn

-- ==============================================================================
-- ⏱️ 6. COUNTDOWN & RESTOCK BANNER
-- ==============================================================================
local BannerFrame = Instance.new("Frame")
BannerFrame.Name = "BannerFrame"
BannerFrame.Size = UDim2.new(1, -24, 0, 64)
BannerFrame.Position = UDim2.new(0, 12, 0, 54)
BannerFrame.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
BannerFrame.BorderSizePixel = 0
BannerFrame.Parent = MainFrame

local BannerCorner = Instance.new("UICorner")
BannerCorner.CornerRadius = UDim.new(0, 8)
BannerCorner.Parent = BannerFrame

local BannerStroke = Instance.new("UIStroke")
BannerStroke.Color = Color3.fromRGB(60, 75, 105)
BannerStroke.Thickness = 1
BannerStroke.Parent = BannerFrame

local RestockTitle = Instance.new("TextLabel")
RestockTitle.Size = UDim2.new(0.5, 0, 0, 18)
RestockTitle.Position = UDim2.new(0, 12, 0, 10)
RestockTitle.BackgroundTransparency = 1
RestockTitle.Font = Enum.Font.GothamMedium
RestockTitle.Text = "⏳ NEXT RESTOCK IN:"
RestockTitle.TextColor3 = Color3.fromRGB(170, 185, 210)
RestockTitle.TextSize = 11
RestockTitle.TextXAlignment = Enum.TextXAlignment.Left
RestockTitle.Parent = BannerFrame

local CountdownLabel = Instance.new("TextLabel")
CountdownLabel.Name = "CountdownLabel"
CountdownLabel.Size = UDim2.new(0.5, 0, 0, 26)
CountdownLabel.Position = UDim2.new(0, 12, 0, 28)
CountdownLabel.BackgroundTransparency = 1
CountdownLabel.Font = Enum.Font.GothamBold
CountdownLabel.Text = "--:-- (Standby)"
CountdownLabel.TextColor3 = Color3.fromRGB(255, 205, 70)
CountdownLabel.TextSize = 18
CountdownLabel.TextXAlignment = Enum.TextXAlignment.Left
CountdownLabel.Parent = BannerFrame

local TargetTimeLabel = Instance.new("TextLabel")
TargetTimeLabel.Name = "TargetTimeLabel"
TargetTimeLabel.Size = UDim2.new(0.5, -12, 0, 18)
TargetTimeLabel.Position = UDim2.new(0.5, 0, 0, 10)
TargetTimeLabel.BackgroundTransparency = 1
TargetTimeLabel.Font = Enum.Font.GothamMedium
TargetTimeLabel.Text = "Jam Restock WIB: --:--"
TargetTimeLabel.TextColor3 = Color3.fromRGB(150, 165, 190)
TargetTimeLabel.TextSize = 11
TargetTimeLabel.TextXAlignment = Enum.TextXAlignment.Right
TargetTimeLabel.Parent = BannerFrame

local SyncStatusLabel = Instance.new("TextLabel")
SyncStatusLabel.Name = "SyncStatusLabel"
SyncStatusLabel.Size = UDim2.new(0.5, -12, 0, 20)
SyncStatusLabel.Position = UDim2.new(0.5, 0, 0, 32)
SyncStatusLabel.BackgroundTransparency = 1
SyncStatusLabel.Font = Enum.Font.GothamBold
SyncStatusLabel.Text = "🟢 Live Connected"
SyncStatusLabel.TextColor3 = Color3.fromRGB(90, 235, 130)
SyncStatusLabel.TextSize = 11
SyncStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
SyncStatusLabel.Parent = BannerFrame

-- ==============================================================================
-- 🔍 7. TAB NAVIGATION & SEARCH BAR
-- ==============================================================================
local ControlBar = Instance.new("Frame")
ControlBar.Name = "ControlBar"
ControlBar.Size = UDim2.new(1, -24, 0, 36)
ControlBar.Position = UDim2.new(0, 12, 0, 124)
ControlBar.BackgroundTransparency = 1
ControlBar.Parent = MainFrame

-- Tab Buttons
local tabList = { "All", "Brainrot", "Potion", "Upgrade" }
local tabButtons = {}

for i, tabName in ipairs(tabList) do
    local tBtn = Instance.new("TextButton")
    tBtn.Name = "Tab_" .. tabName
    tBtn.Size = UDim2.new(0, 72, 0, 32)
    tBtn.Position = UDim2.new(0, (i - 1) * 76, 0, 2)
    tBtn.BackgroundColor3 = (tabName == "All") and Color3.fromRGB(255, 145, 30) or Color3.fromRGB(24, 30, 42)
    tBtn.Font = Enum.Font.GothamBold
    tBtn.Text = tabName
    tBtn.TextColor3 = (tabName == "All") and Color3.fromRGB(15, 20, 30) or Color3.fromRGB(190, 205, 230)
    tBtn.TextSize = 11
    tBtn.BorderSizePixel = 0
    tBtn.Parent = ControlBar

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 6)
    tCorner.Parent = tBtn

    tabButtons[tabName] = tBtn
end

-- Search Box
local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -316, 0, 32)
SearchBox.Position = UDim2.new(0, 316, 0, 2)
SearchBox.BackgroundColor3 = Color3.fromRGB(22, 28, 40)
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.PlaceholderText = "🔍 Cari item..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 135, 160)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(240, 245, 255)
SearchBox.TextSize = 11
SearchBox.BorderSizePixel = 0
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = ControlBar

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 6)
SearchCorner.Parent = SearchBox

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = Color3.fromRGB(50, 65, 90)
SearchStroke.Thickness = 1
SearchStroke.Parent = SearchBox

-- ==============================================================================
-- 📜 8. SCROLLING LIST ITEM CARDS
-- ==============================================================================
local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Name = "ScrollList"
ScrollList.Size = UDim2.new(1, -24, 1, -172)
ScrollList.Position = UDim2.new(0, 12, 0, 164)
ScrollList.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
ScrollList.BorderSizePixel = 0
ScrollList.ScrollBarThickness = 5
ScrollList.ScrollBarImageColor3 = Color3.fromRGB(255, 145, 30)
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollList.Parent = MainFrame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 8)
ScrollCorner.Parent = ScrollList

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 8)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollList

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 8)
ListPadding.PaddingBottom = UDim.new(0, 12)
ListPadding.PaddingLeft = UDim.new(0, 8)
ListPadding.PaddingRight = UDim.new(0, 8)
ListPadding.Parent = ScrollList

-- ==============================================================================
-- 📦 9. ITEM CARD GENERATOR & REALTIME UPDATER
-- ==============================================================================
local itemCardElements = {}

local function createItemCard(itemName, itemData)
    local probPercent = calculateStockProbability(itemData)

    local Card = Instance.new("Frame")
    Card.Name = "Card_" .. itemName
    Card.Size = UDim2.new(1, 0, 0, 84)
    Card.BackgroundColor3 = Color3.fromRGB(24, 30, 42)
    Card.BorderSizePixel = 0
    Card.LayoutOrder = itemData.Order or 99
    Card.Parent = ScrollList

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 8)
    CardCorner.Parent = Card

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Color3.fromRGB(45, 55, 78)
    CardStroke.Thickness = 1
    CardStroke.Parent = Card

    -- Thumbnail Image
    local IconBg = Instance.new("Frame")
    IconBg.Size = UDim2.new(0, 64, 0, 64)
    IconBg.Position = UDim2.new(0, 10, 0, 10)
    IconBg.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    IconBg.BorderSizePixel = 0
    IconBg.Parent = Card
    local IconBgCorner = Instance.new("UICorner")
    IconBgCorner.CornerRadius = UDim.new(0, 6)
    IconBgCorner.Parent = IconBg

    local Thumbnail = Instance.new("ImageLabel")
    Thumbnail.Size = UDim2.new(1, -6, 1, -6)
    Thumbnail.Position = UDim2.new(0, 3, 0, 3)
    Thumbnail.BackgroundTransparency = 1
    Thumbnail.Image = itemData.Image or ""
    Thumbnail.ScaleType = Enum.ScaleType.Fit
    Thumbnail.Parent = IconBg

    -- Name & Cost
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0, 200, 0, 18)
    NameLabel.Position = UDim2.new(0, 82, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.Text = itemData.DisplayName
    NameLabel.TextColor3 = Color3.fromRGB(250, 250, 255)
    NameLabel.TextSize = 13
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Card

    local CostLabel = Instance.new("TextLabel")
    CostLabel.Size = UDim2.new(0, 120, 0, 14)
    CostLabel.Position = UDim2.new(0, 82, 0, 27)
    CostLabel.BackgroundTransparency = 1
    CostLabel.Font = Enum.Font.GothamBold
    CostLabel.Text = string.format("☄️ %d Meteors", itemData.Cost or 0)
    CostLabel.TextColor3 = Color3.fromRGB(255, 175, 45)
    CostLabel.TextSize = 11
    CostLabel.TextXAlignment = Enum.TextXAlignment.Left
    CostLabel.Parent = Card

    -- Info Text
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(0, 240, 0, 14)
    InfoLabel.Position = UDim2.new(0, 82, 0, 44)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.Text = itemData.Info or ""
    InfoLabel.TextColor3 = Color3.fromRGB(160, 175, 200)
    InfoLabel.TextSize = 10
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.Parent = Card

    -- Odds / Probability Badge
    local OddsBadge = Instance.new("Frame")
    OddsBadge.Size = UDim2.new(0, 130, 0, 18)
    OddsBadge.Position = UDim2.new(0, 82, 0, 60)
    OddsBadge.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    OddsBadge.BorderSizePixel = 0
    OddsBadge.Parent = Card
    local OddsCorner = Instance.new("UICorner")
    OddsCorner.CornerRadius = UDim.new(0, 4)
    OddsCorner.Parent = OddsBadge

    local OddsText = Instance.new("TextLabel")
    OddsText.Size = UDim2.new(1, 0, 1, 0)
    OddsText.BackgroundTransparency = 1
    OddsText.Font = Enum.Font.GothamBold
    if probPercent >= 100 then
        OddsText.Text = "🎲 Odds: 100% (Guaranteed)"
        OddsText.TextColor3 = Color3.fromRGB(80, 230, 120)
    else
        OddsText.Text = string.format("🎲 Odds: %.1f%% / Restock", probPercent)
        OddsText.TextColor3 = itemData.TagColor or Color3.fromRGB(255, 200, 70)
    end
    OddsText.TextSize = 9
    OddsText.Parent = OddsBadge

    -- Stock Badge (Right Side)
    local StockBadge = Instance.new("Frame")
    StockBadge.Size = UDim2.new(0, 100, 0, 22)
    StockBadge.Position = UDim2.new(1, -112, 0, 10)
    StockBadge.BackgroundColor3 = Color3.fromRGB(35, 22, 26)
    StockBadge.BorderSizePixel = 0
    StockBadge.Parent = Card
    local StockCorner = Instance.new("UICorner")
    StockCorner.CornerRadius = UDim.new(0, 5)
    StockCorner.Parent = StockBadge

    local StockLabel = Instance.new("TextLabel")
    StockLabel.Name = "StockLabel"
    StockLabel.Size = UDim2.new(1, 0, 1, 0)
    StockLabel.BackgroundTransparency = 1
    StockLabel.Font = Enum.Font.GothamBold
    StockLabel.Text = "Stock: 0"
    StockLabel.TextColor3 = Color3.fromRGB(255, 80, 95)
    StockLabel.TextSize = 11
    StockLabel.Parent = StockBadge

    -- Instant Buy Button
    local BuyBtn = Instance.new("TextButton")
    BuyBtn.Name = "BuyBtn"
    BuyBtn.Size = UDim2.new(0, 48, 0, 24)
    BuyBtn.Position = UDim2.new(1, -112, 0, 36)
    BuyBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
    BuyBtn.Font = Enum.Font.GothamBold
    BuyBtn.Text = "🛒 Buy"
    BuyBtn.TextColor3 = Color3.fromRGB(160, 210, 255)
    BuyBtn.TextSize = 10
    BuyBtn.BorderSizePixel = 0
    BuyBtn.Parent = Card
    local BuyBtnCorner = Instance.new("UICorner")
    BuyBtnCorner.CornerRadius = UDim.new(0, 5)
    BuyBtnCorner.Parent = BuyBtn

    -- Auto-Buy Toggle Button
    local AutoBuyBtn = Instance.new("TextButton")
    AutoBuyBtn.Name = "AutoBuyBtn"
    AutoBuyBtn.Size = UDim2.new(0, 48, 0, 24)
    AutoBuyBtn.Position = UDim2.new(1, -60, 0, 36)
    AutoBuyBtn.BackgroundColor3 = autoBuySettings[itemName] and Color3.fromRGB(30, 90, 55) or Color3.fromRGB(36, 40, 52)
    AutoBuyBtn.Font = Enum.Font.GothamBold
    AutoBuyBtn.Text = autoBuySettings[itemName] and "⚡ ON" or "⚡ OFF"
    AutoBuyBtn.TextColor3 = autoBuySettings[itemName] and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(160, 175, 195)
    AutoBuyBtn.TextSize = 10
    AutoBuyBtn.BorderSizePixel = 0
    AutoBuyBtn.Parent = Card
    local AutoBuyCorner = Instance.new("UICorner")
    AutoBuyCorner.CornerRadius = UDim.new(0, 5)
    AutoBuyCorner.Parent = AutoBuyBtn

    -- Actions & Events
    BuyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local buyRemote = rev_MeteorShop_Buy or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy"))
            if buyRemote then
                buyRemote:FireServer(itemName)
                print(string.format("🛒 [BUY CLICK] Mengirim permintaan beli item: %s", itemName))
            end
        end)
    end)

    AutoBuyBtn.MouseButton1Click:Connect(function()
        autoBuySettings[itemName] = not autoBuySettings[itemName]
        local isEnabled = autoBuySettings[itemName]
        AutoBuyBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(30, 90, 55) or Color3.fromRGB(36, 40, 52)
        AutoBuyBtn.Text = isEnabled and "⚡ ON" or "⚡ OFF"
        AutoBuyBtn.TextColor3 = isEnabled and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(160, 175, 195)
    end)

    itemCardElements[itemName] = {
        Card = Card,
        StockLabel = StockLabel,
        StockBadge = StockBadge,
        AutoBuyBtn = AutoBuyBtn,
        Category = itemData.Category,
        DisplayName = itemData.DisplayName
    }
end

-- Generate semua card sesuai urutan
local sortedItems = {}
for name, data in pairs(SHOP_ITEMS) do
    table.insert(sortedItems, { Name = name, Data = data })
end
table.sort(sortedItems, function(a, b) return (a.Data.Order or 0) < (b.Data.Order or 0) end)

for _, item in ipairs(sortedItems) do
    createItemCard(item.Name, item.Data)
end

-- ==============================================================================
-- 🔍 10. FILTER & SEARCH LOGIC
-- ==============================================================================
local function refreshListFilter()
    local query = string.lower(searchQuery)
    for itemName, elem in pairs(itemCardElements) do
        local matchesTab = (activeTab == "All") or (elem.Category == activeTab)
        local matchesSearch = (query == "") or string.find(string.lower(elem.DisplayName), query, 1, true)
        
        elem.Card.Visible = matchesTab and matchesSearch
    end
end

for tabName, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        activeTab = tabName
        for tName, tBtn in pairs(tabButtons) do
            local isSel = (tName == activeTab)
            tBtn.BackgroundColor3 = isSel and Color3.fromRGB(255, 145, 30) or Color3.fromRGB(24, 30, 42)
            tBtn.TextColor3 = isSel and Color3.fromRGB(15, 20, 30) or Color3.fromRGB(190, 205, 230)
        end
        refreshListFilter()
    end)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = SearchBox.Text
    refreshListFilter()
end)

-- ==============================================================================
-- 📡 11. STOCK SYNC & AUTO-BUY HANDLER
-- ==============================================================================
local function updateStockFromData(stockData, expiryTimestamp)
    if type(stockData) ~= "table" then return end
    lastSyncTimestamp = tick()

    if expiryTimestamp and tonumber(expiryTimestamp) then
        nextExpiryTimestamp = tonumber(expiryTimestamp)
    end

    SyncStatusLabel.Text = "🟢 Live Synced!"
    SyncStatusLabel.TextColor3 = Color3.fromRGB(90, 235, 130)

    for itemName, itemInfo in pairs(stockData) do
        if type(itemInfo) == "table" then
            local count = tonumber(itemInfo.Stock) or 0
            local maxC = tonumber(itemInfo.Max) or 0
            currentStockData[itemName] = { Stock = count, Max = maxC }

            local elem = itemCardElements[itemName]
            if elem then
                if count > 0 then
                    elem.StockLabel.Text = string.format("Stock: %d / %d", count, maxC)
                    elem.StockLabel.TextColor3 = Color3.fromRGB(90, 255, 140)
                    elem.StockBadge.BackgroundColor3 = Color3.fromRGB(20, 50, 35)
                else
                    elem.StockLabel.Text = "Stock: 0"
                    elem.StockLabel.TextColor3 = Color3.fromRGB(255, 80, 95)
                    elem.StockBadge.BackgroundColor3 = Color3.fromRGB(35, 22, 26)
                end
            end

            -- Eksekusi Auto-Buy jika aktif dan stock > 0
            if autoBuySettings[itemName] and count > 0 then
                task.spawn(function()
                    for i = 1, count do
                        pcall(function()
                            local buyRemote = rev_MeteorShop_Buy or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy"))
                            if buyRemote then
                                buyRemote:FireServer(itemName)
                                print(string.format("⚡ [AUTO BUY ENGINE] Membeli %s (#%d/%d)...", itemName, i, count))
                            end
                        end)
                        task.wait(0.2)
                    end
                end)
            end
        end
    end
end

if rev_MeteorShop_Stock then
    rev_MeteorShop_Stock.OnClientEvent:Connect(function(stockData, expiryTimestamp)
        updateStockFromData(stockData, expiryTimestamp)
    end)
end

-- Request Sync Function
local function sendSyncRequest()
    SyncStatusLabel.Text = "🟡 Syncing..."
    SyncStatusLabel.TextColor3 = Color3.fromRGB(255, 205, 80)
    pcall(function()
        local syncRemote = rev_MeteorShop_RequestSync or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_RequestSync"))
        if syncRemote then
            syncRemote:FireServer()
        end
    end)
end

SyncBtn.MouseButton1Click:Connect(function()
    sendSyncRequest()
end)

-- Initial Sync
task.defer(function()
    task.wait(0.5)
    sendSyncRequest()
end)

-- ==============================================================================
-- ⏱️ 12. COUNTDOWN & REALTIME LOOP
-- ==============================================================================
task.spawn(function()
    while task.wait(1) do
        local now = os.time()
        
        -- Hitung sisa waktu restock
        if nextExpiryTimestamp > 0 then
            local timeLeft = math.max(0, nextExpiryTimestamp - now)
            local mins = math.floor(timeLeft / 60)
            local secs = timeLeft % 60
            
            if timeLeft > 0 then
                CountdownLabel.Text = string.format("%02d:%02d", mins, secs)
                CountdownLabel.TextColor3 = (timeLeft <= 60) and Color3.fromRGB(255, 85, 95) or Color3.fromRGB(255, 205, 70)
            else
                CountdownLabel.Text = "00:00 (Restocking...)"
                CountdownLabel.TextColor3 = Color3.fromRGB(100, 255, 140)
                -- Auto sync saat waktu restock tiba
                sendSyncRequest()
            end

            -- Format jam target restock dalam WIB (UTC+7)
            local targetWib = os.date("!*t", nextExpiryTimestamp + (7 * 3600))
            TargetTimeLabel.Text = string.format("Jam Restock WIB: %02d:%02d:%02d", targetWib.hour, targetWib.min, targetWib.sec)
        else
            CountdownLabel.Text = "--:-- (Standby Sync)"
            TargetTimeLabel.Text = "Jam Restock WIB: Menunggu Sync..."
        end

        -- Sync berkala setiap 2 menit jika tidak ada update
        if tick() - lastSyncTimestamp > 120 then
            sendSyncRequest()
        end
    end
end)

-- ==============================================================================
-- 🖱️ 13. DRAGGABLE & MINIMIZE CONTROLLER
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

-- Minimize & Floating Bubble Mode
local isMinimized = false
local FloatingBubble = nil

local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Visible = false

        if not FloatingBubble then
            FloatingBubble = Instance.new("TextButton")
            FloatingBubble.Name = "MeteorStockBubble"
            FloatingBubble.Size = UDim2.new(0, 150, 0, 36)
            FloatingBubble.Position = UDim2.new(0, 20, 0.5, -18)
            FloatingBubble.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
            FloatingBubble.Font = Enum.Font.GothamBold
            FloatingBubble.Text = "☄️ Stock: --:--"
            FloatingBubble.TextColor3 = Color3.fromRGB(255, 175, 50)
            FloatingBubble.TextSize = 12
            FloatingBubble.BorderSizePixel = 0
            FloatingBubble.Active = true
            FloatingBubble.Draggable = true
            FloatingBubble.Parent = ScreenGui

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 8)
            bCorner.Parent = FloatingBubble

            local bStroke = Instance.new("UIStroke")
            bStroke.Color = Color3.fromRGB(255, 145, 30)
            bStroke.Thickness = 1.5
            bStroke.Parent = FloatingBubble

            FloatingBubble.MouseButton1Click:Connect(function()
                toggleMinimize()
            end)

            -- Bubble updater
            task.spawn(function()
                while FloatingBubble and FloatingBubble.Parent do
                    if nextExpiryTimestamp > 0 then
                        local timeLeft = math.max(0, nextExpiryTimestamp - os.time())
                        local mins = math.floor(timeLeft / 60)
                        local secs = timeLeft % 60
                        FloatingBubble.Text = string.format("☄️ Stock: %02d:%02d", mins, secs)
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

MinBtn.MouseButton1Click:Connect(toggleMinimize)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

print("--------------------------------------------------")
print("☄️ [SUKSES] KALB Meteor Stock Monitor & Predictor Pro Siap!")
print("--------------------------------------------------")
