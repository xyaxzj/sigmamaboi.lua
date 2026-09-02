-- ==============================================================================
-- 🌦️ KALB WEATHER RADAR & ROTATION PREDICTOR PRO (FINAL MASTER V5)
-- ==============================================================================
-- 📋 Sistem Prediksi & Analisis Lengkap:
-- 1. 🎓 Jadwal Pasti 3 Mini-Event Back to School (Rotasi 1 Jam):
--    - Fase 1 (Menit 00:00 - 20:00): 📚 Math Event
--    - Fase 2 (Menit 20:00 - 40:00): 🏃 P.E. Class (Dodgeball)
--    - Fase 3 (Menit 40:00 - 60:00): 🏋️ Lift Machine / 📝 Steal Homework
-- 2. ⚡ Live Active Weather & Milisecond Interceptor:
--    - Menangkap sinyal cuaca detik pertama dari server (rev_AddedWeather & rev_WeatherUpdate)
--    - Menampilkan sisa waktu hitung mundur live (mm:ss)
-- 3. 🎯 Hitung Mundur Roll Cuaca Server:
--    - Menghitung waktu pasti kapan server akan mengocok (roll) cuaca baru berikutnya
--    - Terhubung ke Workspace["Admin Machine"] ("NEXT EVENT: mm:ss")
-- 4. 🎰 Stok Weather Machine (ReplicatedStorage.Modules.ServicesLoader.WeatherMachineService)
-- 5. 📚 Database 31 Event Resmi (ReplicatedStorage.Shared.Data.WeatherData.ValidEvents)
-- 6. 📱 UI Super Compact (280x300px) & Floating Pill (Bisa di-minimize)
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
-- 📚 DATABASE 31 EVENT RESMI (SESUAI WEATHERDATA.VALIDEVENTS)
-- ==============================================================================
local WEATHER_METADATA = {
    -- 🎓 Back To School Events (Rotasi 1 Jam)
    MathEvent = {
        Title = "Math Event",
        Category = "🎓 Back To School (Fase 1)",
        Color = Color3.fromRGB(80, 220, 120),
        Tag = "📚 Math",
        Image = "rbxassetid://107322383678822",
        Desc = "Soal matematika berhadiah brainrot!"
    },
    PEClass = {
        Title = "P.E. Class",
        Category = "🎓 Back To School (Fase 2)",
        Color = Color3.fromRGB(255, 120, 60),
        Tag = "🏃 Dodgeball",
        Image = "rbxassetid://122131198867323",
        Desc = "Dodgeball rintangan & bertahan di arena!"
    },
    LiftMachine = {
        Title = "Lift Machine",
        Category = "🎓 Back To School (Fase 3)",
        Color = Color3.fromRGB(255, 200, 50),
        Tag = "🏋️ Workout",
        Image = "rbxassetid://122131198867323",
        Desc = "Angkat beban untuk boost kick power!"
    },
    StealHomework = {
        Title = "Steal Homework",
        Category = "🎓 Back To School (Fase 3)",
        Color = Color3.fromRGB(255, 170, 40),
        Tag = "📝 Homework",
        Image = "rbxassetid://107322383678822",
        Desc = "Event curi PR untuk reward ekstra!"
    },

    -- 🍀 Luck & Server Boost
    LuckMachine = {
        Title = "Luck Machine",
        Category = "🍀 Server Boost",
        Color = Color3.fromRGB(198, 55, 255),
        Tag = "🍀 Luck",
        Image = "rbxassetid://107322383678822",
        Desc = "Squat untuk melipatgandakan server luck!"
    },
    LuckCircles = {
        Title = "Luck Circles",
        Category = "🍀 Server Boost",
        Color = Color3.fromRGB(100, 235, 120),
        Tag = "🟢 Luck Circles",
        Image = "rbxassetid://107322383678822",
        Desc = "Lingkaran keberuntungan pelipatganda drop!"
    },
    MultiplierReactor = {
        Title = "Multiplier Reactor",
        Category = "⚡ Multiplier",
        Color = Color3.fromRGB(198, 55, 255),
        Tag = "⚡ Multiplier",
        Image = "rbxassetid://118706576986202",
        Desc = "Tendang block melewati reaktor pengali!"
    },
    Pinata = {
        Title = "Giant Piñata",
        Category = "🪅 Event",
        Color = Color3.fromRGB(255, 80, 180),
        Tag = "🪅 Piñata",
        Image = "rbxassetid://79129712986846",
        Desc = "Pecahkan piñata raksasa bersama pemain!"
    },

    -- 🌟 Special Weather
    MutationPortal = {
        Title = "Mutation Portal",
        Category = "🌟 Special Event",
        Color = Color3.fromRGB(198, 55, 255),
        Tag = "🌀 Mutation",
        Image = "rbxassetid://124425758292547",
        Desc = "Reroll mutasi brainrot saat melewati portal!"
    },
    Disco = {
        Title = "Disco Party",
        Category = "🌟 Special Event",
        Color = Color3.fromRGB(255, 50, 200),
        Tag = "🪩 Disco",
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
    Volcano = {
        Title = "Volcano Event",
        Category = "🌋 Special Event",
        Color = Color3.fromRGB(255, 75, 40),
        Tag = "🌋 Volcano",
        Image = "rbxassetid://122131198867323",
        Desc = "Gunung berapi aktif menyemburkan lava!"
    },
    Virus = {
        Title = "Virus Outbreak",
        Category = "🦠 Special Event",
        Color = Color3.fromRGB(60, 230, 90),
        Tag = "🦠 Virus",
        Image = "rbxassetid://107322383678822",
        Desc = "Wabah virus menyebar di seluruh server!"
    },
    Enchanted = {
        Title = "Enchanted Event",
        Category = "✨ Magic Event",
        Color = Color3.fromRGB(200, 100, 255),
        Tag = "✨ Enchanted",
        Image = "rbxassetid://124425758292547",
        Desc = "Kekuatan sihir memperkuat lucky block!"
    },
    Heavenly = {
        Title = "Heavenly Event",
        Category = "✨ Divine Event",
        Color = Color3.fromRGB(255, 240, 150),
        Tag = "⭐ Heavenly",
        Image = "rbxassetid://107322383678822",
        Desc = "Cahaya surga meningkatkan keberuntungan!"
    },
    Void = {
        Title = "Void Event",
        Category = "🌌 Dark Event",
        Color = Color3.fromRGB(120, 60, 200),
        Tag = "🌌 Void",
        Image = "rbxassetid://101689222190339",
        Desc = "Kekuatan kegelapan void melingkupi server!"
    },
    Carnival = {
        Title = "Carnival Event",
        Category = "🎪 Party Event",
        Color = Color3.fromRGB(255, 120, 180),
        Tag = "🎪 Carnival",
        Image = "rbxassetid://120074370025048",
        Desc = "Pesta karnaval meriah di arena utama!"
    },
    ["Zombie Apocalypse"] = {
        Title = "Zombie Apocalypse",
        Category = "🧟 Survival",
        Color = Color3.fromRGB(80, 180, 70),
        Tag = "🧟 Zombie",
        Image = "rbxassetid://122131198867323",
        Desc = "Bertahan hidup dari serangan zombie!"
    },
    Jungle = {
        Title = "Jungle Event",
        Category = "🌴 Nature Event",
        Color = Color3.fromRGB(50, 200, 100),
        Tag = "🌴 Jungle",
        Image = "rbxassetid://107322383678822",
        Desc = "Hutan tropis menyelimuti arena permainan!"
    },
    Frozen = {
        Title = "Frozen Event",
        Category = "❄️ Ice Event",
        Color = Color3.fromRGB(100, 220, 255),
        Tag = "❄️ Frozen",
        Image = "rbxassetid://115218894315544",
        Desc = "Es membekukan seluruh area pertandingan!"
    },

    -- 📦 Lucky Block Transforms
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
    ["Super Gym"] = {
        Title = "Super Gym",
        Category = "💪 Admin Abuse",
        Color = Color3.fromRGB(255, 40, 40),
        Tag = "💥 Super Gym",
        Image = "rbxassetid://122131198867323",
        Desc = "Latihan ekstrem dengan multiplier super tinggi!"
    },
    Concert = {
        Title = "Concert Event",
        Category = "🎤 Live Event",
        Color = Color3.fromRGB(255, 100, 255),
        Tag = "🎤 Concert",
        Image = "rbxassetid://120074370025048",
        Desc = "Konser musik spektakuler di panggung utama!"
    },
    ["Wandering Trader"] = {
        Title = "Wandering Trader",
        Category = "🛒 Trader Event",
        Color = Color3.fromRGB(60, 180, 255),
        Tag = "🛒 Trader",
        Image = "rbxassetid://107322383678822",
        Desc = "Pedagang keliling misterius membawa item langka!"
    },
    ["Big Red Button"] = {
        Title = "Big Red Button",
        Category = "🔴 Mystery Event",
        Color = Color3.fromRGB(255, 40, 40),
        Tag = "🔴 Red Button",
        Image = "rbxassetid://122131198867323",
        Desc = "Tekan tombol merah raksasa untuk kejutan acak!"
    },
    MightyChest = {
        Title = "Mighty Chest",
        Category = "🎁 Reward Event",
        Color = Color3.fromRGB(255, 215, 0),
        Tag = "🎁 Mighty Chest",
        Image = "rbxassetid://118706576986202",
        Desc = "Peti harta karun raksasa muncul dengan reward melimpah!"
    },
    Fire = {
        Title = "Fire Event",
        Category = "🔥 Hazard Event",
        Color = Color3.fromRGB(255, 100, 20),
        Tag = "🔥 Fire",
        Image = "rbxassetid://122131198867323",
        Desc = "Api menyala di sekitar arena lapangan!"
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
        Desc = "Event cuaca khusus aktif di server."
    }
end

-- ==============================================================================
-- 📡 1. NETWORK & SERVICES CONNECTIONS
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
local rev_WeatherUpdate = findRemote("rev_WeatherUpdate", "RemoteEvent")

local WeatherService_Client = nil
local WeatherMachineService = nil
pcall(function()
    local svLoader = ReplicatedStorage.Modules.ServicesLoader
    WeatherService_Client = require(svLoader.WeatherService_Client)
    WeatherMachineService = require(svLoader.WeatherMachineService)
end)

-- ==============================================================================
-- 🧠 2. STATE & ROTATION SCHEDULE ENGINE
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

-- Pembaca Text Admin Machine di Workspace ("NEXT EVENT: 10:27")
local function getAdminMachineNextEventText()
    local adminMachine = workspace:FindFirstChild("Admin Machine")
    if adminMachine then
        for _, desc in ipairs(adminMachine:GetDescendants()) do
            if desc:IsA("TextLabel") and string.find(desc.Text, "NEXT EVENT") then
                return desc.Text
            end
        end
    end
    return nil
end

-- Menghitung Jadwal Fase Back To School (Rotasi 1 Jam)
local function getBackToSchoolPhaseSchedule()
    local now = os.time()
    local date = os.date("*t", now)
    local minute = date.min
    local second = date.sec

    local currentPhase = ""
    local nextPhase = ""
    local remainingInPhase = 0

    if minute < 20 then
        currentPhase = "📚 Math Event (Fase 1)"
        nextPhase = "🏃 P.E. Class (Fase 2)"
        remainingInPhase = ((20 - minute) * 60) - second
    elseif minute < 40 then
        currentPhase = "🏃 P.E. Class (Fase 2)"
        nextPhase = "🏋️ Lift Machine / Steal Homework (Fase 3)"
        remainingInPhase = ((40 - minute) * 60) - second
    else
        currentPhase = "🏋️ Lift Machine / Steal Homework (Fase 3)"
        nextPhase = "📚 Math Event (Fase 1 Jam Baru)"
        remainingInPhase = ((60 - minute) * 60) - second
    end

    return currentPhase, nextPhase, remainingInPhase
end

-- Pembaca Data Terpadu
local function getUnifiedWeatherData()
    local liveList = {}
    local machineStock = {}
    local adminNextEventStr = getAdminMachineNextEventText()
    local now = os.time()

    if WeatherService_Client and type(WeatherService_Client.Events) == "table" then
        for eName, endTs in pairs(WeatherService_Client.Events) do
            if type(endTs) == "number" then
                local diff = endTs - now
                if diff > 0 then
                    table.insert(liveList, {
                        Name = eName,
                        EndTime = endTs,
                        Remaining = diff
                    })
                end
            end
        end
    end

    if #liveList == 0 and getgc then
        pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" and rawget(obj, "Events") and type(obj.Events) == "table" then
                    for eName, endTs in pairs(obj.Events) do
                        if type(endTs) == "number" and endTs > now then
                            table.insert(liveList, {
                                Name = eName,
                                EndTime = endTs,
                                Remaining = endTs - now
                            })
                        end
                    end
                end
            end
        end)
    end

    if WeatherMachineService and type(WeatherMachineService.Stock) == "table" then
        for sName, isAvailable in pairs(WeatherMachineService.Stock) do
            if isAvailable == true then
                table.insert(machineStock, sName)
            end
        end
    end

    return liveList, adminNextEventStr, machineStock
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
-- 🎨 3. USER INTERFACE (COMPACT 280x300px & FLOATING PILL)
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
FloatingPill.Size = UDim2.new(0, 175, 0, 32)
FloatingPill.Position = UDim2.new(0.5, -87, 0, 12)
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

-- Main Compact Window (280x300px)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 300)
MainFrame.Position = UDim2.new(0.5, -140, 0.45, -150)
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
TitleText.Size = UDim2.new(1, -120, 1, 0)
TitleText.Position = UDim2.new(0, 36, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "WEATHER RADAR"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = Topbar

-- Refresh Button
local RefBtn = Instance.new("TextButton")
RefBtn.Size = UDim2.new(0, 24, 0, 24)
RefBtn.Position = UDim2.new(1, -84, 0.5, -12)
RefBtn.BackgroundColor3 = Color3.fromRGB(32, 38, 58)
RefBtn.Text = "🔄"
RefBtn.TextColor3 = Color3.fromRGB(150, 220, 255)
RefBtn.Font = Enum.Font.GothamBold
RefBtn.TextSize = 11
RefBtn.Parent = Topbar

local UICorner_Ref = Instance.new("UICorner")
UICorner_Ref.CornerRadius = UDim.new(0, 6)
UICorner_Ref.Parent = RefBtn

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

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; FloatingPill.Visible = true end)
FloatingPill.MouseButton1Click:Connect(function() FloatingPill.Visible = false; MainFrame.Visible = true end)

-- Dragging System
local function enableDrag(frameToDrag, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frameToDrag.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
local activeTab = "Upcoming" -- Default buka tab Upcoming / Jadwal

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

    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(0, 72, 0, 16)
    tag.Position = UDim2.new(1, -78, 0, 8)
    tag.BackgroundColor3 = Color3.fromRGB(28, 36, 58)
    tag.Text = tagText or "Event"
    tag.TextColor3 = tagColor or Color3.fromRGB(255, 255, 255)
    tag.Font = Enum.Font.GothamBold
    tag.TextSize = 8
    tag.Parent = card

    local tagCorner = Instance.new("UICorner")
    tagCorner.CornerRadius = UDim.new(0, 4)
    tagCorner.Parent = tag

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, -54, 0, 16)
    statusLbl.Position = UDim2.new(0, 48, 0, 26)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = statusText or ""
    statusLbl.TextColor3 = statusColor or Color3.fromRGB(100, 220, 255)
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextSize = 9.5
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Parent = card

    return card
end

local function renderBannerCard(titleText, subText, order)
    local banner = Instance.new("Frame")
    banner.Name = "BannerCard"
    banner.Size = UDim2.new(1, 0, 0, 54)
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
    tLbl.Position = UDim2.new(0, 8, 0, 6)
    tLbl.BackgroundTransparency = 1
    tLbl.Text = titleText
    tLbl.TextColor3 = Color3.fromRGB(100, 220, 255)
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 11
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = banner

    local sLbl = Instance.new("TextLabel")
    sLbl.Size = UDim2.new(1, -16, 0, 24)
    sLbl.Position = UDim2.new(0, 8, 0, 24)
    sLbl.BackgroundTransparency = 1
    sLbl.Text = subText
    sLbl.TextColor3 = Color3.fromRGB(180, 200, 240)
    sLbl.Font = Enum.Font.GothamMedium
    sLbl.TextSize = 9
    sLbl.TextXAlignment = Enum.TextXAlignment.Left
    sLbl.TextWrapped = true
    sLbl.Parent = banner

    return banner
end

local function renderHeaderSection(headerText, order)
    local hdr = Instance.new("TextLabel")
    hdr.Name = "HeaderCard"
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

-- Refresh Tampilan
local function refreshView()
    for _, child in ipairs(ScrollContainer:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    local liveList, adminNextEventStr, machineStock = getUnifiedWeatherData()
    local currentPhase, nextPhase, remainingInPhase = getBackToSchoolPhaseSchedule()

    -- Update Floating Pill Text
    if #liveList > 0 then
        local first = liveList[1]
        local meta = getMetadata(first.Name)
        FloatingPill.Text = string.format("🔴 %s (%s)", meta.Title, formatTime(first.Remaining))
        FloatingPill.TextColor3 = Color3.fromRGB(255, 120, 120)
    elseif adminNextEventStr then
        FloatingPill.Text = string.format("⏳ %s", adminNextEventStr)
        FloatingPill.TextColor3 = Color3.fromRGB(100, 220, 255)
    else
        FloatingPill.Text = string.format("⏳ Next: %s", formatTime(remainingInPhase))
        FloatingPill.TextColor3 = Color3.fromRGB(130, 180, 255)
    end

    -- ==================== TAB 1: LIVE AKTIF ====================
    if activeTab == "Live" then
        if #liveList == 0 then
            local bannerSub = string.format("Fase Saat Ini: %s\n%s", currentPhase, adminNextEventStr or "Menunggu spawn event berikutnya.")
            renderBannerCard("☁️ STATUS CUACA: STANDBY", bannerSub, 1)
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

    -- ==================== TAB 2: JADWAL & PREDIKSI (NEXT) ====================
    elseif activeTab == "Upcoming" then
        local orderIndex = 1

        -- 1. Prediksi Berdasarkan Jadwal Fase Back To School (Rotasi 1 Jam)
        renderHeaderSection("🎓 JADWAL 3 MINI-EVENT BACK TO SCHOOL:", orderIndex)
        orderIndex = orderIndex + 1

        local phaseBannerTitle = string.format("⏳ FASE BERIKUTNYA: %s", formatTime(remainingInPhase))
        local phaseBannerSub = string.format("Sekarang: %s\nBerikutnya: %s (%s lagi)", currentPhase, nextPhase, formatTime(remainingInPhase))
        renderBannerCard(phaseBannerTitle, phaseBannerSub, orderIndex)
        orderIndex = orderIndex + 1

        -- 2. Countdown dari Admin Machine
        if adminNextEventStr then
            renderHeaderSection("📡 TIMER ADMIN MACHINE SERVER:", orderIndex)
            orderIndex = orderIndex + 1
            renderBannerCard("⏳ " .. adminNextEventStr, "Hitung mundur resmi event dari Admin Machine di Workspace.", orderIndex)
            orderIndex = orderIndex + 1
        end

        -- 3. Stok Weather Machine
        if #machineStock > 0 then
            renderHeaderSection("🎰 STOK WEATHER MACHINE:", orderIndex)
            orderIndex = orderIndex + 1
            for _, sName in ipairs(machineStock) do
                local meta = getMetadata(sName)
                renderCompactCard(
                    meta.Title,
                    "🎰 READY",
                    Color3.fromRGB(198, 55, 255),
                    "Tersedia untuk dipanggil di Weather Machine",
                    Color3.fromRGB(210, 150, 255),
                    meta.Image,
                    orderIndex
                )
                orderIndex = orderIndex + 1
            end
        end

        -- 4. Daftar Pool 31 Event Resmi Game
        renderHeaderSection("🌟 POOL 31 EVENT RESMI (WEATHERDATA):", orderIndex)
        orderIndex = orderIndex + 1

        local schoolList = {"MathEvent", "PEClass", "LiftMachine", "StealHomework"}
        for _, pName in ipairs(schoolList) do
            local meta = getMetadata(pName)
            renderCompactCard(
                meta.Title,
                meta.Tag,
                Color3.fromRGB(255, 200, 50),
                string.format("🎓 %s • %s", meta.Category, meta.Desc),
                Color3.fromRGB(255, 220, 100),
                meta.Image,
                orderIndex
            )
            orderIndex = orderIndex + 1
        end

        local otherList = {
            "LuckMachine", "LuckCircles", "MultiplierReactor", "Pinata",
            "MutationPortal", "Disco", "LightningEvent", "Volcano", "Virus",
            "Enchanted", "Heavenly", "Phantom", "Bacon", "Wet", "Alien"
        }
        for _, pName in ipairs(otherList) do
            local meta = getMetadata(pName)
            renderCompactCard(
                meta.Title,
                meta.Tag,
                meta.Color,
                string.format("🎲 %s • %s", meta.Category, meta.Desc),
                Color3.fromRGB(160, 180, 220),
                meta.Image,
                orderIndex
            )
            orderIndex = orderIndex + 1
        end

    -- ==================== TAB 3: RIWAYAT ====================
    elseif activeTab == "History" then
        if #weatherHistoryLog == 0 then
            renderBannerCard("📜 RIWAYAT KOSONG", "Belum ada riwayat cuaca tercatat di sesi saat ini.", 1)
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
RefBtn.MouseButton1Click:Connect(function() refreshView() end)

-- Initial Render
refreshView()

-- ==============================================================================
-- 🔄 5. REAL-TIME TICK LOOP (SETIAP 1 DETIK)
-- ==============================================================================
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local liveList, adminNextEventStr = getUnifiedWeatherData()
            local topStr = adminNextEventStr and string.format(" | %s", adminNextEventStr) or ""
            ServerTimeLabel.Text = string.format("🕒 %s WIB%s", os.date("%H:%M:%S"), topStr)
            refreshView()
        end)
    end
end)

print("--------------------------------------------------")
print("✅ [KALB] Weather Radar Pro V5 (Final Master) Siap Digunakan!")
