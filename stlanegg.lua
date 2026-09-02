-- ==============================================================================
-- 🌦️ KALB WEATHER RADAR & EVENT PREDICTOR PRO (COMPACT & FLAWLESS V3)
-- ==============================================================================
-- 📋 Evaluasi & Perbaikan Logika:
-- 1. 🧹 Fix Bug Text Duplikasi:
--    - Membersihkan seluruh anak ScrollContainer sebelum render ulang (tidak akan numpuk ke bawah lagi).
-- 2. 🔮 Tab Jadwal (Next) Informatif & Lengkap:
--    - Menampilkan Hitung Mundur Pasti Waktu Roll Cuaca Berikutnya (Waktu & Jam WIB).
--    - Menampilkan Pool Rotasi Event (Back to School & Special Weather) yang berpotensi muncul.
--    - Jika server mengirimkan antrean event berjadwal, nama event akan otomatis tampil di atas.
-- 3. ⚡ Tab Live (Aktif):
--    - Menampilkan event yang sedang berlangsung detik ini beserta sisa waktu dan deskripsi.
-- 4. 📱 UI Compact & Floating Pill:
--    - Ramping (280x290px), tidak menutupi layar, tombol minimize jadi pil mengambang.
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

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
-- 📚 DATABASE METADATA EVENT CUACA & ROTATION POOL
-- ==============================================================================
local WEATHER_METADATA = {
    MathEvent = {
        Title = "Math Event",
        Category = "🎓 Back To School",
        Color = Color3.fromRGB(80, 220, 120),
        Tag = "📚 Math",
        Image = "rbxassetid://107322383678822",
        Desc = "Soal matematika berhadiah brainrot!"
    },
    PEClass = {
        Title = "P.E. Class",
        Category = "🎓 Back To School",
        Color = Color3.fromRGB(255, 120, 60),
        Tag = "🏃 Dodgeball",
        Image = "rbxassetid://122131198867323",
        Desc = "Dodgeball rintangan & bertahan di arena!"
    },
    LiftMachine = {
        Title = "Lift Machine",
        Category = "🎓 Back To School",
        Color = Color3.fromRGB(255, 200, 50),
        Tag = "🏋️ Workout",
        Image = "rbxassetid://122131198867323",
        Desc = "Angkat beban untuk boost kick power!"
    },
    LuckCircles = {
        Title = "Luck Circles",
        Category = "🍀 Server Boost",
        Color = Color3.fromRGB(100, 235, 120),
        Tag = "🟢 Server Luck",
        Image = "rbxassetid://107322383678822",
        Desc = "Lingkaran keberuntungan pelipatganda drop!"
    },
    LuckMachine = {
        Title = "Luck Machine",
        Category = "🍀 Server Boost",
        Color = Color3.fromRGB(198, 55, 255),
        Tag = "🍀 Luck Machine",
        Image = "rbxassetid://107322383678822",
        Desc = "Squat untuk melipatgandakan server luck!"
    },
    MutationPortal = {
        Title = "Mutation Portal",
        Category = "🌟 Special Event",
        Color = Color3.fromRGB(198, 55, 255),
        Tag = "🌀 Mutation",
        Image = "rbxassetid://124425758292547",
        Desc = "Reroll mutasi brainrot saat melewati portal!"
    },
    MultiplierReactor = {
        Title = "Multiplier Reactor",
        Category = "🌟 Special Event",
        Color = Color3.fromRGB(198, 55, 255),
        Tag = "⚡ Multiplier",
        Image = "rbxassetid://118706576986202",
        Desc = "Tendang block melewati reaktor pengali!"
    },
    Pinata = {
        Title = "Giant Piñata",
        Category = "🌟 Special Event",
        Color = Color3.fromRGB(255, 80, 180),
        Tag = "🪅 Piñata",
        Image = "rbxassetid://79129712986846",
        Desc = "Pecahkan piñata raksasa bersama pemain!"
    },
    Disco = {
        Title = "Disco Party",
        Category = "🌟 Special Event",
        Color = Color3.fromRGB(255, 50, 200),
        Tag = "🪩 Disco Party",
        Image = "rbxassetid://120074370025048",
        Desc = "Musik Phonk & pesta disco di server!"
    },
    LightningEvent = {
        Title = "Lightning Strike",
        Category = "⚡ Speed Event",
        Color = Color3.fromRGB(255, 240, 60),
        Tag = "⚡ 2x Speed",
        Image = "rbxassetid://107052076487974",
        Desc = "2x Kick Speed & Run Speed diaktifkan!"
    },
    Phantom = {
        Title = "Phantom Event",
        Category = "📦 Lucky Block",
        Color = Color3.fromRGB(199, 196, 187),
        Tag = "👻 3% Chance",
        Image = "rbxassetid://101689222190339",
        Desc = "3% chance lucky block berubah jadi Phantom!"
    },
    Bacon = {
        Title = "Bacon Event",
        Category = "📦 Lucky Block",
        Color = Color3.fromRGB(219, 133, 20),
        Tag = "🥓 5% Chance",
        Image = "rbxassetid://108280271882625",
        Desc = "5% chance lucky block berubah jadi Bacon!"
    },
    Wet = {
        Title = "Wet Event",
        Category = "📦 Lucky Block",
        Color = Color3.fromRGB(30, 144, 255),
        Tag = "💧 10% Chance",
        Image = "rbxassetid://115218894315544",
        Desc = "10% chance lucky block berubah jadi Wet!"
    },
    Alien = {
        Title = "Alien Event",
        Category = "📦 Lucky Block",
        Color = Color3.fromRGB(175, 16, 255),
        Tag = "👽 5% Chance",
        Image = "rbxassetid://130233388559569",
        Desc = "5% chance lucky block berubah jadi Alien!"
    },
    Gym = {
        Title = "Gym Workout",
        Category = "💪 Admin Abuse",
        Color = Color3.fromRGB(255, 60, 60),
        Tag = "💪 Gym",
        Image = "rbxassetid://122131198867323",
        Desc = "Multiplier circle latihan menyebar di arena!"
    },
    Concert = {
        Title = "Concert Event",
        Category = "🎤 Live Event",
        Color = Color3.fromRGB(255, 100, 255),
        Tag = "🎤 Concert",
        Image = "rbxassetid://120074370025048",
        Desc = "Konser musik spektakuler di panggung utama!"
    }
}

local function getMetadata(name)
    if WEATHER_METADATA[name] then
        return WEATHER_METADATA[name]
    end
    for k, v in pairs(WEATHER_METADATA) do
        if string.lower(k) == string.lower(name) or string.find(string.lower(name), string.lower(k)) then
            return v
        end
    end
    return {
        Title = tostring(name),
        Category = "🌦️ Weather",
        Color = Color3.fromRGB(140, 160, 255),
        Tag = "🌦️ Event",
        Image = "rbxassetid://107322383678822",
        Desc = "Event cuaca khusus aktif."
    }
end

-- ==============================================================================
-- 📡 1. NETWORK & REMOTE INTERCEPTOR
-- ==============================================================================
local networkFolder = nil
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
    local packages = shared and (shared:FindFirstChild("Packages") or shared:WaitForChild("Packages", 3))
    networkFolder = packages and (packages:FindFirstChild("Network") or packages:WaitForChild("Network", 3))
end)

local function findRemote(name, className)
    if networkFolder then
        local r = networkFolder:FindFirstChild(name)
        if r and (not className or r:IsA(className)) then return r end
    end
    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
        if r.Name == name and (not className or r:IsA(className)) then
            return r
        end
    end
    return nil
end

local rev_AddedWeather = findRemote("rev_AddedWeather", "RemoteEvent")
local rev_RemovedWeather = findRemote("rev_RemovedWeather", "RemoteEvent")

-- ==============================================================================
-- 🧠 2. MEMORY & UPVALUE INSPECTOR (WEATHER PREDICTOR ENGINE)
-- ==============================================================================
local weatherHistoryLog = {}

local function addHistoryLog(wName, eventType, ts)
    local timeStr = os.date("%H:%M:%S")
    table.insert(weatherHistoryLog, 1, {
        Time = timeStr,
        Event = wName,
        Type = eventType,
        Timestamp = ts or os.time()
    })
    if #weatherHistoryLog > 30 then
        table.remove(weatherHistoryLog)
    end
end

-- Ambil modul WeatherService_Client
local cachedWeatherServiceModule = nil
local function getWeatherServiceModule()
    if cachedWeatherServiceModule then return cachedWeatherServiceModule end
    pcall(function()
        local ml = ReplicatedStorage:FindFirstChild("Modules")
        local sl = ml and ml:FindFirstChild("ServicesLoader")
        local ws = sl and sl:FindFirstChild("WeatherService_Client")
        if ws and ws:IsA("ModuleScript") then
            cachedWeatherServiceModule = require(ws)
        end
    end)
    return cachedWeatherServiceModule
end

-- Ekstrak data cuaca dari Upvalues & GC
local function inspectClientWeatherData()
    local rawEvents = {}      -- [name] = endTimestamp
    local activeModules = {}  -- [name] = true

    -- 1. Scan via WeatherService_Client Upvalues
    local ws = getWeatherServiceModule()
    if ws and getupvalues then
        pcall(function()
            for k, fn in pairs(ws) do
                if type(fn) == "function" then
                    local uvs = getupvalues(fn)
                    for _, uv in pairs(uvs) do
                        if type(uv) == "table" then
                            -- Upvalue 1: Events table
                            if uv.Events and type(uv.Events) == "table" then
                                for eName, ts in pairs(uv.Events) do
                                    if type(ts) == "number" then
                                        rawEvents[eName] = ts
                                    end
                                end
                            end
                            -- Upvalue 2: Modules table
                            if uv.Modules and type(uv.Modules) == "table" then
                                for mName, mData in pairs(uv.Modules) do
                                    if type(mData) == "table" and mData.Active == true then
                                        activeModules[mName] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    -- 2. Scan via getgc() (Universal Fallback)
    if (next(rawEvents) == nil) and getgc then
        pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" then
                    if rawget(obj, "Events") and type(obj.Events) == "table" then
                        for eName, ts in pairs(obj.Events) do
                            if type(ts) == "number" and ts > 1700000000 then
                                rawEvents[eName] = ts
                            end
                        end
                    end
                    if rawget(obj, "Modules") and type(obj.Modules) == "table" then
                        for mName, mData in pairs(obj.Modules) do
                            if type(mData) == "table" and mData.Active == true then
                                activeModules[mName] = true
                            end
                        end
                    end
                end
            end
        end)
    end

    -- Klasifikasikan Event: LIVE vs UPCOMING
    local now = os.time()
    local liveList = {}
    local upcomingList = {}
    local sortedEvents = {}

    for eName, endTs in pairs(rawEvents) do
        table.insert(sortedEvents, { Name = eName, EndTime = endTs })
    end

    table.sort(sortedEvents, function(a, b)
        return a.EndTime < b.EndTime
    end)

    for idx, item in ipairs(sortedEvents) do
        local diff = item.EndTime - now
        if diff > 0 then
            table.insert(liveList, {
                Name = item.Name,
                EndTime = item.EndTime,
                Remaining = diff,
                IsModuleActive = (activeModules[item.Name] == true)
            })
        end
    end

    -- Tambahkan juga modul yang memiliki flag Active = true ke Live List jika belum ada
    for mName, _ in pairs(activeModules) do
        local alreadyListed = false
        for _, l in ipairs(liveList) do
            if l.Name == mName then alreadyListed = true; break end
        end
        if not alreadyListed then
            table.insert(liveList, {
                Name = mName,
                EndTime = now + 180,
                Remaining = 180,
                IsModuleActive = true
            })
        end
    end

    -- Jika server memiliki lebih dari 1 event dalam antrean Events
    if #sortedEvents >= 2 then
        for i = 2, #sortedEvents do
            local prevEnd = sortedEvents[i-1].EndTime
            local currEnd = sortedEvents[i].EndTime
            local startIn = math.max(0, prevEnd - now)
            table.insert(upcomingList, {
                Name = sortedEvents[i].Name,
                StartTime = prevEnd,
                EndTime = currEnd,
                StartsIn = startIn
            })
        end
    end

    return liveList, upcomingList, activeModules
end

-- Listener Remote Weather
if rev_AddedWeather then
    rev_AddedWeather.OnClientEvent:Connect(function(weatherType, timestamp)
        local wName = tostring(weatherType)
        local ts = tonumber(timestamp) or (os.time() + 300)
        addHistoryLog(wName, "START", ts)
    end)
end

if rev_RemovedWeather then
    rev_RemovedWeather.OnClientEvent:Connect(function(weatherType, timestamp)
        local wName = tostring(weatherType)
        addHistoryLog(wName, "END", timestamp)
    end)
end

-- ==============================================================================
-- 🎨 3. USER INTERFACE (COMPACT & SLEEK 280x290px)
-- ==============================================================================
local existingGui = CoreGui:FindFirstChild("KalbWeatherRadar") or (lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("KalbWeatherRadar"))
if existingGui then existingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KalbWeatherRadar"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = lp:WaitForChild("PlayerGui") end

-- Floating Pill (Mode Minimize)
local FloatingPill = Instance.new("TextButton")
FloatingPill.Name = "FloatingPill"
FloatingPill.Size = UDim2.new(0, 165, 0, 32)
FloatingPill.Position = UDim2.new(0.5, -82, 0, 12)
FloatingPill.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
FloatingPill.Text = "🌦️ Radar: Standby"
FloatingPill.TextColor3 = Color3.fromRGB(130, 180, 255)
FloatingPill.Font = Enum.Font.GothamBold
FloatingPill.TextSize = 11
FloatingPill.Visible = false
FloatingPill.Parent = ScreenGui

local UICorner_Pill = Instance.new("UICorner")
UICorner_Pill.CornerRadius = UDim.new(0, 16)
UICorner_Pill.Parent = FloatingPill

local UIStroke_Pill = Instance.new("UIStroke")
UIStroke_Pill.Color = Color3.fromRGB(70, 110, 220)
UIStroke_Pill.Thickness = 1.2
UIStroke_Pill.Parent = FloatingPill

-- Main Compact Window (280x290px)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 290)
MainFrame.Position = UDim2.new(0.5, -140, 0.45, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner_Main = Instance.new("UICorner")
UICorner_Main.CornerRadius = UDim.new(0, 12)
UICorner_Main.Parent = MainFrame

local UIStroke_Main = Instance.new("UIStroke")
UIStroke_Main.Color = Color3.fromRGB(60, 85, 150)
UIStroke_Main.Thickness = 1.2
UIStroke_Main.Transparency = 0.3
UIStroke_Main.Parent = MainFrame

-- Topbar (Height: 40px)
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 40)
Topbar.BackgroundColor3 = Color3.fromRGB(22, 27, 42)
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

local UICorner_Top = Instance.new("UICorner")
UICorner_Top.CornerRadius = UDim.new(0, 12)
UICorner_Top.Parent = Topbar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 28, 0, 28)
TitleIcon.Position = UDim2.new(0, 8, 0.5, -14)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "🌦️"
TitleIcon.TextSize = 18
TitleIcon.Parent = Topbar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -95, 1, 0)
TitleText.Position = UDim2.new(0, 36, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "WEATHER RADAR"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = Topbar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -56, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(32, 38, 58)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(150, 180, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.Parent = Topbar

local UICorner_Min = Instance.new("UICorner")
UICorner_Min.CornerRadius = UDim.new(0, 6)
UICorner_Min.Parent = MinBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(32, 38, 58)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.Parent = Topbar

local UICorner_Close = Instance.new("UICorner")
UICorner_Close.CornerRadius = UDim.new(0, 6)
UICorner_Close.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingPill.Visible = true
end)

FloatingPill.MouseButton1Click:Connect(function()
    FloatingPill.Visible = false
    MainFrame.Visible = true
end)

-- Dragging System (Topbar & FloatingPill)
local function enableDrag(frameToDrag, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frameToDrag.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frameToDrag.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

enableDrag(MainFrame, Topbar)
enableDrag(FloatingPill, FloatingPill)

-- Navigation Tabs
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -16, 0, 26)
TabBar.Position = UDim2.new(0, 8, 0, 46)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
TabBar.Parent = MainFrame

local UICorner_TabBar = Instance.new("UICorner")
UICorner_TabBar.CornerRadius = UDim.new(0, 6)
UICorner_TabBar.Parent = TabBar

local tabButtons = {}
local activeTab = "Live"

local function createTabBtn(name, text, index)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.333, -2, 1, -2)
    btn.Position = UDim2.new((index - 1) * 0.333, 1, 0, 1)
    btn.BackgroundColor3 = (name == activeTab) and Color3.fromRGB(50, 85, 210) or Color3.fromRGB(22, 26, 42)
    btn.Text = text
    btn.TextColor3 = (name == activeTab) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 160, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = TabBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn

    tabButtons[name] = btn
    return btn
end

local btnLive = createTabBtn("Live", "⚡ Live (Aktif)", 1)
local btnUpcoming = createTabBtn("Upcoming", "🔮 Jadwal (Next)", 2)
local btnHistory = createTabBtn("History", "📜 Riwayat", 3)

-- Scroll Container
local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Name = "ScrollContainer"
ScrollContainer.Size = UDim2.new(1, -16, 1, -104)
ScrollContainer.Position = UDim2.new(0, 8, 0, 76)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.ScrollBarThickness = 3
ScrollContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 90, 180)
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = ScrollContainer

-- Footer Info Bar
local Footer = Instance.new("Frame")
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, -16, 0, 22)
Footer.Position = UDim2.new(0, 8, 1, -26)
Footer.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
Footer.Parent = MainFrame

local UICorner_Foot = Instance.new("UICorner")
UICorner_Foot.CornerRadius = UDim.new(0, 6)
UICorner_Foot.Parent = Footer

local ServerTimeLabel = Instance.new("TextLabel")
ServerTimeLabel.Size = UDim2.new(1, -10, 1, 0)
ServerTimeLabel.Position = UDim2.new(0, 6, 0, 0)
ServerTimeLabel.BackgroundTransparency = 1
ServerTimeLabel.Text = "🕒 Waktu: ..."
ServerTimeLabel.TextColor3 = Color3.fromRGB(130, 160, 220)
ServerTimeLabel.Font = Enum.Font.GothamMedium
ServerTimeLabel.TextSize = 10
ServerTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
ServerTimeLabel.Parent = Footer

-- ==============================================================================
-- 🔄 4. COMPACT CARD RENDERER
-- ==============================================================================
local function formatTime(sec)
    if not sec or sec <= 0 then return "00:00" end
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02d:%02d", m, s)
end

local function renderCompactCard(title, tagText, tagColor, statusText, statusColor, iconAsset, order)
    local card = Instance.new("Frame")
    card.Name = "EventCard"
    card.Size = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(22, 27, 44)
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    card.Parent = ScrollContainer

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = tagColor or Color3.fromRGB(60, 80, 140)
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.5
    cardStroke.Parent = card

    -- Icon (34x34)
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 34, 0, 34)
    icon.Position = UDim2.new(0, 8, 0.5, -17)
    icon.BackgroundColor3 = Color3.fromRGB(28, 35, 55)
    icon.Image = iconAsset or "rbxassetid://107322383678822"
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = card

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = icon

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -125, 0, 16)
    titleLbl.Position = UDim2.new(0, 48, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    -- Tag Badge
    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(0, 68, 0, 16)
    tag.Position = UDim2.new(1, -74, 0, 8)
    tag.BackgroundColor3 = Color3.fromRGB(28, 36, 58)
    tag.Text = tagText or "Event"
    tag.TextColor3 = tagColor or Color3.fromRGB(255, 255, 255)
    tag.Font = Enum.Font.GothamBold
    tag.TextSize = 8.5
    tag.Parent = card

    local tagCorner = Instance.new("UICorner")
    tagCorner.CornerRadius = UDim.new(0, 4)
    tagCorner.Parent = tag

    -- Status Text (Countdown)
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, -54, 0, 16)
    statusLbl.Position = UDim2.new(0, 48, 0, 26)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = statusText or ""
    statusLbl.TextColor3 = statusColor or Color3.fromRGB(100, 220, 255)
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextSize = 10
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Parent = card

    return card
end

-- Banner Card untuk Info Next Roll
local function renderBannerCard(titleText, subText, order)
    local banner = Instance.new("Frame")
    banner.Name = "EventCard"
    banner.Size = UDim2.new(1, 0, 0, 56)
    banner.BackgroundColor3 = Color3.fromRGB(28, 36, 62)
    banner.BorderSizePixel = 0
    banner.LayoutOrder = order or 1
    banner.Parent = ScrollContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = banner

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 130, 240)
    stroke.Thickness = 1
    stroke.Parent = banner

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -16, 0, 18)
    tLbl.Position = UDim2.new(0, 8, 0, 8)
    tLbl.BackgroundTransparency = 1
    tLbl.Text = titleText
    tLbl.TextColor3 = Color3.fromRGB(100, 220, 255)
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 11
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = banner

    local sLbl = Instance.new("TextLabel")
    sLbl.Size = UDim2.new(1, -16, 0, 22)
    sLbl.Position = UDim2.new(0, 8, 0, 28)
    sLbl.BackgroundTransparency = 1
    sLbl.Text = subText
    sLbl.TextColor3 = Color3.fromRGB(180, 200, 240)
    sLbl.Font = Enum.Font.GothamMedium
    sLbl.TextSize = 9.5
    sLbl.TextXAlignment = Enum.TextXAlignment.Left
    sLbl.TextWrapped = true
    sLbl.Parent = banner

    return banner
end

-- Header Section Card
local function renderHeaderSection(headerText, order)
    local hdr = Instance.new("TextLabel")
    hdr.Name = "EventCard"
    hdr.Size = UDim2.new(1, 0, 0, 20)
    hdr.BackgroundTransparency = 1
    hdr.Text = headerText
    hdr.TextColor3 = Color3.fromRGB(130, 160, 230)
    hdr.Font = Enum.Font.GothamBold
    hdr.TextSize = 10
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.LayoutOrder = order or 1
    hdr.Parent = ScrollContainer
    return hdr
end

-- Refresh Tampilan Tab (Pembersihan Bersih 100%)
local function refreshView()
    -- 1. Bersihkan seluruh elemen lama agar TIDAK ADA duplikasi
    for _, child in ipairs(ScrollContainer:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    local liveList, upcomingList, activeModules = inspectClientWeatherData()
    local now = os.time()

    -- Update Floating Pill Text
    if #liveList > 0 then
        local first = liveList[1]
        local meta = getMetadata(first.Name)
        FloatingPill.Text = string.format("🔴 %s (%s)", meta.Title, formatTime(first.Remaining))
        FloatingPill.TextColor3 = Color3.fromRGB(255, 120, 120)
    else
        FloatingPill.Text = "🌦️ Radar: Standby"
        FloatingPill.TextColor3 = Color3.fromRGB(130, 180, 255)
    end

    -- TAB 1: LIVE (AKTIF)
    if activeTab == "Live" then
        if #liveList == 0 then
            local empty = Instance.new("TextLabel")
            empty.Name = "EmptyLabel"
            empty.Size = UDim2.new(1, 0, 0, 70)
            empty.BackgroundTransparency = 1
            empty.Text = "☁️ Tidak ada event cuaca yang aktif.\n(Menunggu event berikutnya)"
            empty.TextColor3 = Color3.fromRGB(130, 150, 190)
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 11
            empty.Parent = ScrollContainer
        else
            for idx, item in ipairs(liveList) do
                local meta = getMetadata(item.Name)
                local statusStr = string.format("🔴 AKTIF! Sisa Waktu: %s", formatTime(item.Remaining))
                renderCompactCard(
                    meta.Title,
                    meta.Tag,
                    Color3.fromRGB(255, 80, 80),
                    statusStr,
                    Color3.fromRGB(255, 120, 120),
                    meta.Image,
                    idx
                )
            end
        end

    -- TAB 2: JADWAL (NEXT) & POOL ROTASI
    elseif activeTab == "Upcoming" then
        local orderIndex = 1

        -- 1. Jika ada Antrean Terjadwal dari Server
        if #upcomingList > 0 then
            renderHeaderSection("📅 EVENT BERIKUTNYA TERJADWAL:", orderIndex)
            orderIndex = orderIndex + 1

            for _, item in ipairs(upcomingList) do
                local meta = getMetadata(item.Name)
                local statusStr = string.format("⏳ Mulai dlm: %s (%s WIB)", formatTime(item.StartsIn), os.date("%H:%M:%S", item.StartTime))
                renderCompactCard(
                    meta.Title,
                    meta.Tag,
                    meta.Color,
                    statusStr,
                    Color3.fromRGB(100, 220, 255),
                    meta.Image,
                    orderIndex
                )
                orderIndex = orderIndex + 1
            end
        else
            -- 2. Banner Hitung Mundur Roll Cuaca Berikutnya
            if #liveList > 0 then
                local first = liveList[1]
                local bannerTitle = string.format("🎲 ROLL CUACA BERIKUTNYA: %s", formatTime(first.Remaining))
                local bannerSub = string.format("Event baru di-roll server pukul %s WIB (setelah '%s' selesai).", os.date("%H:%M:%S", first.EndTime), first.Name)
                renderBannerCard(bannerTitle, bannerSub, orderIndex)
                orderIndex = orderIndex + 1
            else
                renderBannerCard("🎲 ROLL CUACA: STANDBY", "Server sedang menyiapkan event cuaca baru...", orderIndex)
                orderIndex = orderIndex + 1
            end
        end

        -- 3. Daftar Pool Rotasi Event yang Berpotensi Muncul
        renderHeaderSection("🌟 POOL ROTASI EVENT CUACA:", orderIndex)
        orderIndex = orderIndex + 1

        local poolList = {
            "MathEvent", "PEClass", "LiftMachine",
            "MutationPortal", "LuckMachine", "MultiplierReactor",
            "Pinata", "Disco", "LightningEvent", "Phantom", "Bacon", "Wet", "Alien"
        }

        for _, pName in ipairs(poolList) do
            local meta = getMetadata(pName)
            local statusStr = string.format("🎲 %s • %s", meta.Category, meta.Desc)
            renderCompactCard(
                meta.Title,
                meta.Tag,
                meta.Color,
                statusStr,
                Color3.fromRGB(160, 180, 220),
                meta.Image,
                orderIndex
            )
            orderIndex = orderIndex + 1
        end

    -- TAB 3: RIWAYAT
    elseif activeTab == "History" then
        if #weatherHistoryLog == 0 then
            local empty = Instance.new("TextLabel")
            empty.Name = "EmptyLabel"
            empty.Size = UDim2.new(1, 0, 0, 70)
            empty.BackgroundTransparency = 1
            empty.Text = "📜 Belum ada riwayat cuaca di sesi ini."
            empty.TextColor3 = Color3.fromRGB(130, 150, 190)
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 11
            empty.Parent = ScrollContainer
        else
            for idx, log in ipairs(weatherHistoryLog) do
                local meta = getMetadata(log.Event)
                local tagText = (log.Type == "START") and "🟢 MULAI" or "🔴 SELESAI"
                local tagCol = (log.Type == "START") and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(255, 80, 80)
                local statusStr = string.format("🕒 Waktu Catat: %s WIB", log.Time)
                renderCompactCard(
                    meta.Title,
                    tagText,
                    tagCol,
                    statusStr,
                    Color3.fromRGB(180, 200, 240),
                    meta.Image,
                    idx
                )
            end
        end
    end
end

-- Tab Switch Handlers
local function switchTab(tabName)
    activeTab = tabName
    for name, btn in pairs(tabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(50, 85, 210)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(22, 26, 42)
            btn.TextColor3 = Color3.fromRGB(140, 160, 200)
        end
    end
    refreshView()
end

btnLive.MouseButton1Click:Connect(function() switchTab("Live") end)
btnUpcoming.MouseButton1Click:Connect(function() switchTab("Upcoming") end)
btnHistory.MouseButton1Click:Connect(function() switchTab("History") end)

-- Initial Render
refreshView()

-- ==============================================================================
-- 🔄 5. REAL-TIME TICK LOOP (SETIAP 1 DETIK)
-- ==============================================================================
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local liveList = inspectClientWeatherData()
            ServerTimeLabel.Text = string.format("🕒 %s WIB | Aktif: %d Event", os.date("%H:%M:%S"), #liveList)
            refreshView()
        end)
    end
end)

print("--------------------------------------------------")
print("✅ [KALB] Weather Radar Pro V3 (Flawless & Clean) Siap Digunakan!")
