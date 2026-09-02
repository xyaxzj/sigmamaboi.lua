-- ==============================================================================
-- 🌦️ KALB WEATHER RADAR & UPCOMING EVENT PREDICTOR PRO
-- ==============================================================================
-- Fitur & Inovasi:
-- 1. 🔮 Upcoming Weather Predictor (Deep Upvalue & GC Engine):
--    - Membaca tabel 'Events' langsung dari upvalue WeatherService_Client / getgc()
--    - Menampilkan daftar event selanjutnya lengkap dengan countdown waktu mulai!
-- 2. ⚡ Live Active Weather Monitor:
--    - Menampilkan event yang sedang aktif detik ini, durasi sisa, icon & deskripsi
-- 3. 📡 Remote Interceptor (rev_AddedWeather & rev_RemovedWeather):
--    - Menangkap sinyal cuaca milidetik pertama dari server
-- 4. 📜 Live Weather Log & History Timeline:
--    - Riwayat event yang telah muncul lengkap dengan timestamp
-- 5. 🎨 UI Ultra-Modern Glassmorphism (100% Touch Responsive di Mobile & PC)
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
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
-- 📚 DATABASE & METADATA EVENT CUACA
-- ==============================================================================
local WEATHER_METADATA = {
    MathEvent = {
        Title = "Math Event",
        Color = Color3.fromRGB(80, 220, 120),
        Tag = "📚 Back To School",
        Image = "rbxassetid://107322383678822",
        Desc = "Selesaikan soal matematika untuk mendapatkan reward brainrot!"
    },
    PEClass = {
        Title = "P.E. Class",
        Color = Color3.fromRGB(255, 120, 60),
        Tag = "🏃 Dodgeball",
        Image = "rbxassetid://122131198867323",
        Desc = "Hindari bola dan bertahan di arena P.E. Class!"
    },
    LiftMachine = {
        Title = "Lift Machine",
        Color = Color3.fromRGB(255, 200, 50),
        Tag = "🏋️ Workout",
        Image = "rbxassetid://122131198867323",
        Desc = "Latihan angkat beban di gym untuk boost kekuatan kick!"
    },
    MutationPortal = {
        Title = "Mutation Portal",
        Color = Color3.fromRGB(198, 55, 255),
        Tag = "🌀 Mutation",
        Image = "rbxassetid://124425758292547",
        Desc = "Lewati portal mutasi untuk meroll ulang mutasi brainrot!"
    },
    Phantom = {
        Title = "Phantom Event",
        Color = Color3.fromRGB(199, 196, 187),
        Tag = "👻 3% Chance",
        Image = "rbxassetid://101689222190339",
        Desc = "3% chance lucky block berubah menjadi Phantom Lucky Block!"
    },
    MultiplierReactor = {
        Title = "Multiplier Reactor",
        Color = Color3.fromRGB(198, 55, 255),
        Tag = "⚡ Multiplier",
        Image = "rbxassetid://118706576986202",
        Desc = "Kick melewati reaktor untuk melipatgandakan lucky block!"
    },
    Pinata = {
        Title = "Giant Piñata",
        Color = Color3.fromRGB(255, 80, 180),
        Tag = "🪅 Piñata",
        Image = "rbxassetid://79129712986846",
        Desc = "Piñata raksasa muncul! Tendang block ke arahnya untuk memecahkannya!"
    },
    Gym = {
        Title = "Gym Workout",
        Color = Color3.fromRGB(255, 60, 60),
        Tag = "💪 Admin Abuse",
        Image = "rbxassetid://122131198867323",
        Desc = "Multiplier circle muncul di seluruh map untuk latihan!"
    },
    Bacon = {
        Title = "Bacon Event",
        Color = Color3.fromRGB(219, 133, 20),
        Tag = "🥓 5% Chance",
        Image = "rbxassetid://108280271882625",
        Desc = "5% chance lucky block berubah menjadi Bacon Lucky Block!"
    },
    Wet = {
        Title = "Wet Event",
        Color = Color3.fromRGB(30, 144, 255),
        Tag = "💧 10% Chance",
        Image = "rbxassetid://115218894315544",
        Desc = "10% chance lucky block berubah menjadi Wet Lucky Block!"
    },
    Disco = {
        Title = "Disco Party",
        Color = Color3.fromRGB(255, 50, 200),
        Tag = "🪩 Party Time",
        Image = "rbxassetid://120074370025048",
        Desc = "Musik Phonk & Rap berputar! Nikmati pesta Disco di server!"
    },
    LuckMachine = {
        Title = "Luck Machine",
        Color = Color3.fromRGB(198, 55, 255),
        Tag = "🍀 Server Luck",
        Image = "rbxassetid://107322383678822",
        Desc = "Squat di dalam Luck Machine untuk meningkatkan server luck!"
    },
    LightningEvent = {
        Title = "Lightning Strike",
        Color = Color3.fromRGB(255, 240, 60),
        Tag = "⚡ 2x Speed",
        Image = "rbxassetid://107052076487974",
        Desc = "Petir menyambar! 2x Kick Speed & Run Speed diaktifkan!"
    },
    Alien = {
        Title = "Alien Event",
        Color = Color3.fromRGB(175, 16, 255),
        Tag = "👽 5% Chance",
        Image = "rbxassetid://130233388559569",
        Desc = "5% chance lucky block berubah menjadi Alien Lucky Block!"
    },
    Concert = {
        Title = "Concert Event",
        Color = Color3.fromRGB(255, 100, 255),
        Tag = "🎤 Live Show",
        Image = "rbxassetid://120074370025048",
        Desc = "Konser musik spektakuler sedang berlangsung di arena!"
    },
    ["Block Cup Party"] = {
        Title = "Block Cup Party",
        Color = Color3.fromRGB(255, 180, 0),
        Tag = "🏆 Tournament",
        Image = "rbxassetid://118706576986202",
        Desc = "Pesta kejuaraan Block Cup sedang aktif di server!"
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
        Color = Color3.fromRGB(140, 160, 255),
        Tag = "🌦️ Weather",
        Image = "rbxassetid://107322383678822",
        Desc = "Event cuaca khusus aktif di server."
    }
end

-- ==============================================================================
-- 📡 1. NETWORK & REMOTE WEATHER FINDER
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
-- 🧠 2. DEEP UPVALUE & GC WEATHER EXTRACTOR (PREDICTOR ENGINE)
-- ==============================================================================
local liveActiveEvents = {}     -- [name] = { EndTime = timestamp, StartTime = timestamp }
local upcomingEventsList = {}   -- Array of { Name = name, Timestamp = timestamp }
local weatherHistoryLog = {}    -- Array of { Time = str, Event = name, Type = "START"|"END", Timestamp = ts }

local function addHistoryLog(wName, eventType, ts)
    local timeStr = os.date("%H:%M:%S")
    table.insert(weatherHistoryLog, 1, {
        Time = timeStr,
        Event = wName,
        Type = eventType,
        Timestamp = ts or os.time()
    })
    if #weatherHistoryLog > 50 then
        table.remove(weatherHistoryLog)
    end
end

-- Ekstraksi Upvalue dari WeatherService_Client
local cachedWeatherServiceModule = nil
local function getClientWeatherService()
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

-- Pemindai Upvalue Mendalam & GC
local function scanEventsFromMemory()
    local extractedUpcoming = {}
    local extractedActive = {}

    -- Cara 1: Scan via Module WeatherService_Client Upvalues
    local ws = getClientWeatherService()
    if ws and getupvalues then
        pcall(function()
            for k, fn in pairs(ws) do
                if type(fn) == "function" then
                    local uvs = getupvalues(fn)
                    for _, uv in pairs(uvs) do
                        if type(uv) == "table" and uv.Events and type(uv.Events) == "table" then
                            for eName, ts in pairs(uv.Events) do
                                if type(ts) == "number" then
                                    table.insert(extractedUpcoming, { Name = eName, Timestamp = ts })
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    -- Cara 2: Scan via getgc() (Universal jika didukung executor)
    if #extractedUpcoming == 0 and getgc then
        pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" and rawget(obj, "Events") and type(obj.Events) == "table" then
                    local evTable = obj.Events
                    local valid = false
                    for eName, ts in pairs(evTable) do
                        if type(ts) == "number" and ts > 1700000000 then
                            valid = true
                            table.insert(extractedUpcoming, { Name = eName, Timestamp = ts })
                        end
                    end
                    if valid then break end
                end
            end
        end)
    end

    -- Urutkan berdasarkan waktu mulai (Timestamp terkecil = paling dekat)
    table.sort(extractedUpcoming, function(a, b)
        return a.Timestamp < b.Timestamp
    end)

    upcomingEventsList = extractedUpcoming
    return upcomingEventsList
end

-- Listener Remote Resmi
if rev_AddedWeather then
    rev_AddedWeather.OnClientEvent:Connect(function(weatherType, timestamp)
        local wName = tostring(weatherType)
        local ts = tonumber(timestamp) or (os.time() + 300)
        liveActiveEvents[wName] = {
            EndTime = ts,
            StartTime = os.time(),
            Duration = math.max(1, ts - os.time())
        }
        addHistoryLog(wName, "START", ts)
        scanEventsFromMemory()
    end)
end

if rev_RemovedWeather then
    rev_RemovedWeather.OnClientEvent:Connect(function(weatherType, timestamp)
        local wName = tostring(weatherType)
        liveActiveEvents[wName] = nil
        addHistoryLog(wName, "END", timestamp)
        scanEventsFromMemory()
    end)
end

-- ==============================================================================
-- 🎨 3. USER INTERFACE (ULTRA PREMIUM GLASSMORPHISM RADAR)
-- ==============================================================================
local existingGui = CoreGui:FindFirstChild("KalbWeatherRadar") or (lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("KalbWeatherRadar"))
if existingGui then existingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KalbWeatherRadar"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = lp:WaitForChild("PlayerGui")
end

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 480)
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner_Main = Instance.new("UICorner")
UICorner_Main.CornerRadius = UDim.new(0, 16)
UICorner_Main.Parent = MainFrame

local UIStroke_Main = Instance.new("UIStroke")
UIStroke_Main.Color = Color3.fromRGB(70, 95, 160)
UIStroke_Main.Thickness = 1.5
UIStroke_Main.Transparency = 0.4
UIStroke_Main.Parent = MainFrame

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 52)
Topbar.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

local UICorner_Top = Instance.new("UICorner")
UICorner_Top.CornerRadius = UDim.new(0, 16)
UICorner_Top.Parent = Topbar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 36, 0, 36)
TitleIcon.Position = UDim2.new(0, 12, 0.5, -18)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "🌦️"
TitleIcon.TextSize = 24
TitleIcon.Parent = Topbar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -120, 0, 22)
TitleText.Position = UDim2.new(0, 50, 0, 8)
TitleText.BackgroundTransparency = 1
TitleText.Text = "WEATHER RADAR PRO"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 15
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = Topbar

local SubTitleText = Instance.new("TextLabel")
SubTitleText.Size = UDim2.new(1, -120, 0, 16)
SubTitleText.Position = UDim2.new(0, 50, 0, 28)
SubTitleText.BackgroundTransparency = 1
SubTitleText.Text = "Live Predictor & Schedule"
SubTitleText.TextColor3 = Color3.fromRGB(130, 165, 255)
SubTitleText.Font = Enum.Font.GothamMedium
SubTitleText.TextSize = 11
SubTitleText.TextXAlignment = Enum.TextXAlignment.Left
SubTitleText.Parent = Topbar

-- Close / Minimize Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 42, 65)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Topbar

local UICorner_Close = Instance.new("UICorner")
UICorner_Close.CornerRadius = UDim.new(0, 8)
UICorner_Close.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Dragging System (Support PC & Mobile)
local dragging, dragInput, dragStart, startPos
Topbar.InputBegan:Connect(function(input)
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

Topbar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Navigation Tabs (Upcoming | Live Active | History Log)
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -24, 0, 34)
TabBar.Position = UDim2.new(0, 12, 0, 58)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
TabBar.Parent = MainFrame

local UICorner_TabBar = Instance.new("UICorner")
UICorner_TabBar.CornerRadius = UDim.new(0, 8)
UICorner_TabBar.Parent = TabBar

local tabButtons = {}
local activeTab = "Upcoming"

local function createTabBtn(name, text, index)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.333, -4, 1, -4)
    btn.Position = UDim2.new((index - 1) * 0.333, 2, 0, 2)
    btn.BackgroundColor3 = (name == activeTab) and Color3.fromRGB(55, 90, 220) or Color3.fromRGB(24, 30, 48)
    btn.Text = text
    btn.TextColor3 = (name == activeTab) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 170, 210)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = TabBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    tabButtons[name] = btn
    return btn
end

local btnUpcoming = createTabBtn("Upcoming", "🔮 Jadwal (Next)", 1)
local btnLive = createTabBtn("Live", "⚡ Live Active", 2)
local btnHistory = createTabBtn("History", "📜 Riwayat", 3)

-- Scroll Container
local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Name = "ScrollContainer"
ScrollContainer.Size = UDim2.new(1, -24, 1, -145)
ScrollContainer.Position = UDim2.new(0, 12, 0, 98)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.ScrollBarThickness = 4
ScrollContainer.ScrollBarImageColor3 = Color3.fromRGB(70, 100, 200)
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ScrollContainer

-- Footer Info Bar
local Footer = Instance.new("Frame")
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, -24, 0, 36)
Footer.Position = UDim2.new(0, 12, 1, -44)
Footer.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
Footer.Parent = MainFrame

local UICorner_Foot = Instance.new("UICorner")
UICorner_Foot.CornerRadius = UDim.new(0, 8)
UICorner_Foot.Parent = Footer

local ServerTimeLabel = Instance.new("TextLabel")
ServerTimeLabel.Size = UDim2.new(1, -20, 1, 0)
ServerTimeLabel.Position = UDim2.new(0, 10, 0, 0)
ServerTimeLabel.BackgroundTransparency = 1
ServerTimeLabel.Text = "🕒 Waktu Server: ..."
ServerTimeLabel.TextColor3 = Color3.fromRGB(150, 180, 240)
ServerTimeLabel.Font = Enum.Font.GothamMedium
ServerTimeLabel.TextSize = 11
ServerTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
ServerTimeLabel.Parent = Footer

-- ==============================================================================
-- 🔄 4. RENDERER KARTU EVENT (UPCOMING, LIVE & HISTORY)
-- ==============================================================================
local function formatTimeRemaining(seconds)
    if seconds <= 0 then return "00:00" end
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

local function renderCard(title, subtitle, tagText, tagColor, descText, timeText, iconAsset, order)
    local card = Instance.new("Frame")
    card.Name = "EventCard"
    card.Size = UDim2.new(1, 0, 0, 78)
    card.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    card.Parent = ScrollContainer

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = tagColor or Color3.fromRGB(70, 95, 160)
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.6
    cardStroke.Parent = card

    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 48, 0, 48)
    icon.Position = UDim2.new(0, 10, 0.5, -24)
    icon.BackgroundColor3 = Color3.fromRGB(30, 38, 60)
    icon.Image = iconAsset or "rbxassetid://107322383678822"
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = card

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = icon

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -165, 0, 18)
    titleLbl.Position = UDim2.new(0, 66, 0, 10)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    -- Tag Badge
    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(0, 90, 0, 18)
    tag.Position = UDim2.new(1, -100, 0, 10)
    tag.BackgroundColor3 = Color3.fromRGB(32, 40, 65)
    tag.Text = tagText or "Event"
    tag.TextColor3 = tagColor or Color3.fromRGB(255, 255, 255)
    tag.Font = Enum.Font.GothamBold
    tag.TextSize = 9
    tag.Parent = card

    local tagCorner = Instance.new("UICorner")
    tagCorner.CornerRadius = UDim.new(0, 5)
    tagCorner.Parent = tag

    -- Description
    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -165, 0, 16)
    descLbl.Position = UDim2.new(0, 66, 0, 30)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = descText or subtitle
    descLbl.TextColor3 = Color3.fromRGB(150, 170, 210)
    descLbl.Font = Enum.Font.GothamMedium
    descLbl.TextSize = 10
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.TextTruncate = Enum.TextTruncate.AtEnd
    descLbl.Parent = card

    -- Countdown / Time Badge
    local timeLbl = Instance.new("TextLabel")
    timeLbl.Size = UDim2.new(1, -76, 0, 18)
    timeLbl.Position = UDim2.new(0, 66, 0, 50)
    timeLbl.BackgroundTransparency = 1
    timeLbl.Text = timeText or ""
    timeLbl.TextColor3 = Color3.fromRGB(100, 220, 255)
    timeLbl.Font = Enum.Font.GothamBold
    timeLbl.TextSize = 11
    timeLbl.TextXAlignment = Enum.TextXAlignment.Left
    timeLbl.Parent = card

    return card
end

-- Refresh Tampilan Tab
local function refreshView()
    -- Bersihkan kartu lama
    for _, child in ipairs(ScrollContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name == "EventCard" then
            child:Destroy()
        end
    end

    local now = os.time()

    if activeTab == "Upcoming" then
        scanEventsFromMemory()

        if #upcomingEventsList == 0 then
            local empty = Instance.new("TextLabel")
            empty.Name = "EventCard"
            empty.Size = UDim2.new(1, 0, 0, 100)
            empty.BackgroundTransparency = 1
            empty.Text = "🔍 Memindai jadwal cuaca dari memori...\n(Menunggu data event server)"
            empty.TextColor3 = Color3.fromRGB(140, 160, 210)
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 12
            empty.Parent = ScrollContainer
        else
            for idx, item in ipairs(upcomingEventsList) do
                local meta = getMetadata(item.Name)
                local diff = item.Timestamp - now
                local timeStr = ""

                if diff > 0 then
                    timeStr = string.format("⏳ Mulai dalam: %s (%s WIB)", formatTimeRemaining(diff), os.date("%H:%M:%S", item.Timestamp))
                else
                    timeStr = "⚡ Sedang berlangsung / Tiba giliran!"
                end

                renderCard(
                    meta.Title,
                    item.Name,
                    meta.Tag,
                    meta.Color,
                    meta.Desc,
                    timeStr,
                    meta.Image,
                    idx
                )
            end
        end

    elseif activeTab == "Live" then
        local count = 0
        for wName, info in pairs(liveActiveEvents) do
            count = count + 1
            local meta = getMetadata(wName)
            local remain = math.max(0, info.EndTime - now)
            local timeStr = string.format("🔴 AKTIF SEKARANG! Sisa: %s", formatTimeRemaining(remain))

            renderCard(
                meta.Title,
                wName,
                "🔥 LIVE NOW",
                Color3.fromRGB(255, 60, 60),
                meta.Desc,
                timeStr,
                meta.Image,
                count
            )
        end

        if count == 0 then
            local empty = Instance.new("TextLabel")
            empty.Name = "EventCard"
            empty.Size = UDim2.new(1, 0, 0, 100)
            empty.BackgroundTransparency = 1
            empty.Text = "☁️ Tidak ada event cuaca yang sedang aktif.\n(Menunggu event berikutnya)"
            empty.TextColor3 = Color3.fromRGB(140, 160, 210)
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 12
            empty.Parent = ScrollContainer
        end

    elseif activeTab == "History" then
        if #weatherHistoryLog == 0 then
            local empty = Instance.new("TextLabel")
            empty.Name = "EventCard"
            empty.Size = UDim2.new(1, 0, 0, 100)
            empty.BackgroundTransparency = 1
            empty.Text = "📜 Belum ada riwayat cuaca tercatat di sesi ini."
            empty.TextColor3 = Color3.fromRGB(140, 160, 210)
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 12
            empty.Parent = ScrollContainer
        else
            for idx, log in ipairs(weatherHistoryLog) do
                local meta = getMetadata(log.Event)
                local tagText = (log.Type == "START") and "🟢 MULAI" or "🔴 SELESAI"
                local tagCol = (log.Type == "START") and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(255, 80, 80)
                local timeStr = string.format("🕒 Waktu Catat: %s WIB", log.Time)

                renderCard(
                    meta.Title,
                    log.Event,
                    tagText,
                    tagCol,
                    meta.Desc,
                    timeStr,
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
            btn.BackgroundColor3 = Color3.fromRGB(55, 90, 220)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
            btn.TextColor3 = Color3.fromRGB(150, 170, 210)
        end
    end
    refreshView()
end

btnUpcoming.MouseButton1Click:Connect(function() switchTab("Upcoming") end)
btnLive.MouseButton1Click:Connect(function() switchTab("Live") end)
btnHistory.MouseButton1Click:Connect(function() switchTab("History") end)

-- Initial Scan & Render
scanEventsFromMemory()
refreshView()

-- ==============================================================================
-- 🔄 5. REAL-TIME TICK LOOP (SETIAP 1 DETIK)
-- ==============================================================================
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            ServerTimeLabel.Text = string.format("🕒 Waktu: %s WIB | Total Jadwal: %d", os.date("%H:%M:%S"), #upcomingEventsList)
            refreshView()
        end)
    end
end)

print("--------------------------------------------------")
print("✅ [KALB] Weather Radar & Upcoming Predictor Pro Siap Digunakan!")
