-- ==============================================================================
-- 🚀 SIGMA HUB | KALB AUTO FARM V2 (FULL STATE MACHINE + REAL-TIME SCREEN DEBUG)
-- ==============================================================================
-- Fitur:
-- 1. 🖥️ Screen Debug HUD Real-Time: Memantau setiap transisi fase, timer, jarak, sinyal remote & stats
-- 2. 🥔 Potato Optimization & Safe Player Purger (Tanpa Lag / Memory Leak)
-- 3. 🎮 Sigma UI V4 (Main Tab, Auto Farm Toggle, Anim Delay Slider, Stats Monitor, Config)
-- 4. 🧠 Smart State Machine:
--    - [FASE 1] Idle (Auto Teleport ke Safe Zone & Eksekusi Kick)
--    - [FASE 2] WaitingForPhase2 (Menunggu hasil gacha & bola mendarat dari server)
--    - [FASE 3] PlayingAnim (Jeda animasi gacha sesuai slider animDelay)
--    - [FASE 4] WalkToSafeZone (Karakter bergerak kembali ke Safe Zone)
--    - [FASE 5] WaitingForCollected (Menunggu event reward collected & langsung Re-kick)
--    - [EVENT] LuckMachineTeleport & LuckMachineTraining (Auto Barbell sampai x8 Luck)
-- 5. 🛡️ Failsafe 25s Auto-Respawn Anti-Stuck & Anti-AFK VirtualUser
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local lp = Players.LocalPlayer
if not lp then
    local count = 0
    repeat
        task.wait(0.05)
        lp = Players.LocalPlayer
        count = count + 1
    until lp or count > 50
end

-- =============================================
-- ⚙️ KONFIGURASI AWAL
-- =============================================
_G.autoFarm = false
local autoFarmActive = false              
local animDelay = 5              
_G.autoRemovePlayer = false

-- =============================================
-- 🚀 SYSTEM ANTI-LAG & POTATO MODE
-- =============================================
pcall(function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
            v.Color = Color3.new(1, 1, 1)
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("SpecialMesh") then
            v:Destroy()
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    for _, v in ipairs(Lighting:GetDescendants()) do
        if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Sky") then
            v:Destroy()
        end
    end

    local plotsFolder = workspace:FindFirstChild("Plots")
    if plotsFolder then
        for i = 1, 5 do
            local plot = plotsFolder:FindFirstChild("Plot" .. tostring(i))
            if plot then plot:Destroy() end
        end
    end
end)

-- Player Purger (Opsional jika diaktifkan)
if _G.autoRemovePlayer or _G.removePlayer or _G.removePlayers then
    local function musnahkanPlayer(player)
        if player ~= lp then
            if player.Character then pcall(function() player.Character:Destroy() end) end
            pcall(function() player:Destroy() end)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        musnahkanPlayer(player)
    end

    Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            if _G.autoRemovePlayer or _G.removePlayer or _G.removePlayers then
                musnahkanPlayer(player)
            end
        end)
    end)
end

-- =============================================
-- 🖥️ REAL-TIME SCREEN DEBUG HUD
-- =============================================
local function getGuiContainer()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local pg = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5))
    return pg
end

local targetGuiParent = getGuiContainer()

pcall(function()
    if lp and lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("KalbFarmDebugGui") then
        lp.PlayerGui.KalbFarmDebugGui:Destroy()
    end
    if targetGuiParent and targetGuiParent:FindFirstChild("KalbFarmDebugGui") then
        targetGuiParent.KalbFarmDebugGui:Destroy()
    end
end)

local DebugScreenGui = Instance.new("ScreenGui")
DebugScreenGui.Name = "KalbFarmDebugGui"
DebugScreenGui.ResetOnSpawn = false
DebugScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
DebugScreenGui.DisplayOrder = 99998
DebugScreenGui.Enabled = true

local DebugFrame = Instance.new("Frame")
DebugFrame.Name = "DebugFrame"
DebugFrame.Size = UDim2.new(0, 310, 0, 210)
DebugFrame.Position = UDim2.new(1, -325, 0, 30)
DebugFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
DebugFrame.BorderSizePixel = 0
DebugFrame.Active = true
DebugFrame.Draggable = true
DebugFrame.Visible = true
DebugFrame.Parent = DebugScreenGui

local DebugCorner = Instance.new("UICorner")
DebugCorner.CornerRadius = UDim.new(0, 8)
DebugCorner.Parent = DebugFrame

local DebugStroke = Instance.new("UIStroke")
DebugStroke.Color = Color3.fromRGB(0, 200, 255)
DebugStroke.Thickness = 1.5
DebugStroke.Parent = DebugFrame

local DTitle = Instance.new("TextLabel")
DTitle.Size = UDim2.new(1, -10, 0, 22)
DTitle.Position = UDim2.new(0, 8, 0, 4)
DTitle.BackgroundTransparency = 1
DTitle.Font = Enum.Font.GothamBold
DTitle.Text = "🔍 KALB AUTO FARM - PHASE DEBUG"
DTitle.TextColor3 = Color3.fromRGB(80, 220, 255)
DTitle.TextSize = 11
DTitle.TextXAlignment = Enum.TextXAlignment.Left
DTitle.Parent = DebugFrame

local DPhaseLabel = Instance.new("TextLabel")
DPhaseLabel.Size = UDim2.new(1, -10, 0, 22)
DPhaseLabel.Position = UDim2.new(0, 8, 0, 26)
DPhaseLabel.BackgroundTransparency = 1
DPhaseLabel.Font = Enum.Font.GothamBold
DPhaseLabel.Text = "📌 Fase: [FASE 1] Idle"
DPhaseLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
DPhaseLabel.TextSize = 12
DPhaseLabel.TextXAlignment = Enum.TextXAlignment.Left
DPhaseLabel.Parent = DebugFrame

local DTimerLabel = Instance.new("TextLabel")
DTimerLabel.Size = UDim2.new(1, -10, 0, 18)
DTimerLabel.Position = UDim2.new(0, 8, 0, 48)
DTimerLabel.BackgroundTransparency = 1
DTimerLabel.Font = Enum.Font.Code
DTimerLabel.Text = "⏱️ Phase Timer: 0.0s | Stuck: 0.0s / 25s"
DTimerLabel.TextColor3 = Color3.fromRGB(240, 220, 100)
DTimerLabel.TextSize = 10
DTimerLabel.TextXAlignment = Enum.TextXAlignment.Left
DTimerLabel.Parent = DebugFrame

local DPosLabel = Instance.new("TextLabel")
DPosLabel.Size = UDim2.new(1, -10, 0, 18)
DPosLabel.Position = UDim2.new(0, 8, 0, 68)
DPosLabel.BackgroundTransparency = 1
DPosLabel.Font = Enum.Font.Code
DPosLabel.Text = "📍 Jarak SafeZone: 0.0 studs (Di Zona: YA)"
DPosLabel.TextColor3 = Color3.fromRGB(180, 210, 255)
DPosLabel.TextSize = 10
DPosLabel.TextXAlignment = Enum.TextXAlignment.Left
DPosLabel.Parent = DebugFrame

local DSignalsLabel = Instance.new("TextLabel")
DSignalsLabel.Size = UDim2.new(1, -10, 0, 18)
DSignalsLabel.Position = UDim2.new(0, 8, 0, 88)
DSignalsLabel.BackgroundTransparency = 1
DSignalsLabel.Font = Enum.Font.Code
DSignalsLabel.Text = "📡 Sinyal: P2: [X] | Collect: [X] | End: [X]"
DSignalsLabel.TextColor3 = Color3.fromRGB(255, 170, 80)
DSignalsLabel.TextSize = 10
DSignalsLabel.TextXAlignment = Enum.TextXAlignment.Left
DSignalsLabel.Parent = DebugFrame

local DEventLabel = Instance.new("TextLabel")
DEventLabel.Size = UDim2.new(1, -10, 0, 18)
DEventLabel.Position = UDim2.new(0, 8, 0, 108)
DEventLabel.BackgroundTransparency = 1
DEventLabel.Font = Enum.Font.Code
DEventLabel.Text = "☁️ Event Cuaca: None | Luck Buff x8: [X]"
DEventLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
DEventLabel.TextSize = 10
DEventLabel.TextXAlignment = Enum.TextXAlignment.Left
DEventLabel.Parent = DebugFrame

local DMutationLabel = Instance.new("TextLabel")
DMutationLabel.Size = UDim2.new(1, -10, 0, 18)
DMutationLabel.Position = UDim2.new(0, 8, 0, 128)
DMutationLabel.BackgroundTransparency = 1
DMutationLabel.Font = Enum.Font.GothamBold
DMutationLabel.Text = "🧬 Total Mutasi: 0 | Gacha: None"
DMutationLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
DMutationLabel.TextSize = 10
DMutationLabel.TextXAlignment = Enum.TextXAlignment.Left
DMutationLabel.Parent = DebugFrame

local DPerfLabel = Instance.new("TextLabel")
DPerfLabel.Size = UDim2.new(1, -10, 0, 18)
DPerfLabel.Position = UDim2.new(0, 8, 0, 148)
DPerfLabel.BackgroundTransparency = 1
DPerfLabel.Font = Enum.Font.Code
DPerfLabel.Text = "⚡ FPS: 60 | AFK: 0s | Saklar: OFF"
DPerfLabel.TextColor3 = Color3.fromRGB(150, 240, 200)
DPerfLabel.TextSize = 10
DPerfLabel.TextXAlignment = Enum.TextXAlignment.Left
DPerfLabel.Parent = DebugFrame

local DLogLabel = Instance.new("TextLabel")
DLogLabel.Size = UDim2.new(1, -10, 0, 32)
DLogLabel.Position = UDim2.new(0, 8, 0, 170)
DLogLabel.BackgroundTransparency = 1
DLogLabel.Font = Enum.Font.Code
DLogLabel.Text = "📝 Log: Bot Standby..."
DLogLabel.TextColor3 = Color3.fromRGB(160, 170, 190)
DLogLabel.TextSize = 9
DLogLabel.TextXAlignment = Enum.TextXAlignment.Left
DLogLabel.TextYAlignment = Enum.TextYAlignment.Top
DLogLabel.TextWrapped = true
DLogLabel.Parent = DebugFrame

pcall(function()
    DebugScreenGui.Parent = targetGuiParent or lp:WaitForChild("PlayerGui", 5)
end)

-- Warna fase untuk HUD
local phaseColors = {
    ["Idle"] = Color3.fromRGB(100, 255, 120),
    ["WaitingForPhase2"] = Color3.fromRGB(255, 210, 60),
    ["PlayingAnim"] = Color3.fromRGB(200, 130, 255),
    ["WalkToSafeZone"] = Color3.fromRGB(80, 200, 255),
    ["WaitingForCollected"] = Color3.fromRGB(255, 140, 60),
    ["LuckMachineTeleport"] = Color3.fromRGB(255, 180, 50),
    ["LuckMachineTraining"] = Color3.fromRGB(255, 225, 80),
    ["WaitingRespawn"] = Color3.fromRGB(255, 70, 70),
}

-- =============================================
-- 🎨 LOAD SIGMA UI LIBRARY V4
-- =============================================
local Library = nil
local getSuccess = pcall(function()
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

local Window = Library:CreateWindow({
    Name       = 'Sigma Hub | Auto Farm Kalb 2',
    Footer     = 'discord.gg/sigma | v4.0',
    LogoText   = 'S',
    ConfigName = 'SigmaHub_Kalb2',
    ToggleKey  = Enum.KeyCode.RightShift,
    Watermark  = true,
})

-- TAB 1: MAIN FUNCTION
local MainTab = Window:MakeTab("⚙️")
local FarmSec = MainTab:AddSection("Auto Farm Settings")

FarmSec:AddLabel("Aktifkan saklar di bawah untuk memulai/menghentikan bot:")

FarmSec:AddToggle({ Name = "ON / OFF Auto Farm", Default = autoFarmActive }, function(v)
    autoFarmActive = v
end)

FarmSec:AddSlider({ Name = "Anim Delay (Seconds)", Min = 1, Max = 15, Default = animDelay, Step = 1 }, function(v)
    animDelay = v
end)

-- SECTION: STATS MONITOR
local StatsSec = MainTab:AddSection("Stats Monitor")
local statusPara = StatsSec:AddParagraph("Status: Idle", "User: " .. lp.Name .. "\nMutation Count: 0\nAFK Time: 0 Detik\nFps: 0")

-- TAB 2: CONFIG MANAGER
local CfgTab = Window:MakeTab("💾")
CfgTab:AddConfigManager()

Library:Notify({ Title = 'Sigma UI Loaded', Content = 'Auto Farm Kalb 2 ready!', Type = 'Success' })

-- =============================================
-- 🧠 VARIABEL STATE MACHINE & POSISI
-- =============================================
local targetAction = "Idle"
local lastAction = "Idle"
local stateTimer = 0               
local globalStuckTimer = 0         
local mutationCount = 0            
local lastRewardDesc = "None"
local lastLogMessage = "Bot Standby..."
local safeZone = Vector3.new(698.030701, 3.298559, 233.707077)
local safeZoneCFrame = CFrame.new(698.030701, 3.298559, 233.707077, -0.061024, -0.000000, 0.998136, -0.000000, 1.000000, 0.000000, -0.998136, -0.000000, -0.061024)
local startTime = os.time()

local function setDebugLog(msg)
    lastLogMessage = tostring(msg)
    pcall(function()
        DLogLabel.Text = "📝 Log: " .. lastLogMessage
    end)
end

-- =============================================
-- 🛡️ ANTI AFK
-- =============================================
lp.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- =============================================
-- 📡 DAFTAR REMOTE NETWORK RESMI
-- =============================================
local networkFolder = nil
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
    local packages = shared and (shared:FindFirstChild("Packages") or shared:WaitForChild("Packages", 3))
    networkFolder = packages and (packages:FindFirstChild("Network") or packages:WaitForChild("Network", 3))
end)

local ref_KickEvent = networkFolder and networkFolder:FindFirstChild("ref_KickEvent")
local kickRemote = networkFolder and networkFolder:FindFirstChild("rev_KickEvent")
local rev_kickPhase2 = networkFolder and networkFolder:FindFirstChild("rev_kickPhase2")
local rev_Collected = networkFolder and networkFolder:FindFirstChild("rev_Collected")
local rev_KickEventEnded = networkFolder and networkFolder:FindFirstChild("rev_KickEventEnded")
local rev_AddedWeather = networkFolder and networkFolder:FindFirstChild("rev_AddedWeather")
local rev_PlayMessage = networkFolder and networkFolder:FindFirstChild("rev_PlayMessage")

if not ref_KickEvent then
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteFunction") and r.Name == "ref_KickEvent" then
            ref_KickEvent = r
            break
        end
    end
end
if not kickRemote then
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") and string.find(r.Name, "rev_KickEvent") and not string.find(r.Name, "Ended") then
            kickRemote = r
            break
        end
    end
end

-- =============================================
-- 🎮 CLIENT CONTROLLER HOOK (GC MEMORY)
-- =============================================
local cachedGameController = nil
local function getGameController()
    if cachedGameController then return cachedGameController end
    if getgc then
        for _, item in ipairs(getgc(true)) do
            if type(item) == "table" then
                if rawget(item, "CanKick") ~= nil and type(rawget(item, "Kick")) == "function" and rawget(item, "Status") ~= nil then
                    cachedGameController = item
                    return item
                end
            end
        end
    end
    return nil
end

-- =============================================
-- 📡 LISTENER EVENT SERVER
-- =============================================
local phase2Fired = false
local collectedFired = false
local kickEndedFired = false
local weatherEventPending = false
local luckBuffObtained = false

if rev_kickPhase2 then
    rev_kickPhase2.OnClientEvent:Connect(function(rewardTable, ...)
        phase2Fired = true
        pcall(function()
            if type(rewardTable) == "table" and rewardTable[1] then
                lastRewardDesc = string.format("%s [%s]", tostring(rewardTable[1].Name or "Brainrot"), tostring(rewardTable[1].Mutation or "Normal"))
                setDebugLog(string.format("Reward Masuk: %s", lastRewardDesc))
            end
        end)
    end)
end

if rev_Collected then
    rev_Collected.OnClientEvent:Connect(function(...)
        collectedFired = true
        setDebugLog("Event rev_Collected Diterima")
    end)
end

if rev_KickEventEnded then
    rev_KickEventEnded.OnClientEvent:Connect(function(...)
        kickEndedFired = true
        setDebugLog("Event rev_KickEventEnded Diterima")
    end)
end

if rev_AddedWeather then
    rev_AddedWeather.OnClientEvent:Connect(function(weatherType, ...)
        if weatherType == "LuckMachine" then
            weatherEventPending = true
            setDebugLog("Event Cuaca: LuckMachine Aktif!")
        end
    end)
end

if rev_PlayMessage then
    rev_PlayMessage.OnClientEvent:Connect(function(msg, msgType)
        if tostring(msg) == "Luck has been increased to x8" then
            luckBuffObtained = true
            setDebugLog("Buff x8 Luck Sukses Didapat!")
        end
    end)
end

-- =============================================
-- 🚀 FUNGSI EKSEKUSI TENDANGAN (KICK)
-- =============================================
local function executeKick()
    local timestamp = nil
    pcall(function() timestamp = workspace:GetServerTimeNow() end)
    if not timestamp or type(timestamp) ~= "number" or timestamp <= 0 then
        timestamp = tick()
    end

    setDebugLog("Mengeksekusi Kick (Tri-Layer)...")

    -- 1. Direct GameController Client Hook
    pcall(function()
        local controller = getGameController()
        if controller and type(controller.Kick) == "function" then
            controller:Kick(1, 1)
        end
    end)

    -- 2. Virtual Input Spacebar
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end)

    -- 3. Jaringan Remote Resmi
    pcall(function()
        if ref_KickEvent and ref_KickEvent:IsA("RemoteFunction") then
            ref_KickEvent:InvokeServer(1, 1, timestamp)
        elseif kickRemote and kickRemote:IsA("RemoteEvent") then
            kickRemote:FireServer(1, 1)
        end
    end)
end

-- =============================================
-- 📊 SYSTEM PENGHITUNG FPS
-- =============================================
local fps = 0
local frameCount = 0
local nextFpsUpdate = os.clock() + 1

RunService.Heartbeat:Connect(function()
    frameCount = frameCount + 1
    local now = os.clock()
    if now >= nextFpsUpdate then
        fps = frameCount
        frameCount = 0
        nextFpsUpdate = now + 1
    end
end)

-- =============================================
-- ⚙️ MAIN LOOP (STATE MACHINE + SCREEN DEBUG UPDATE)
-- =============================================
task.spawn(function()
    while task.wait(0.05) do
        local elapsedSeconds = os.time() - startTime
        local char = lp.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local distToSafeZone = hrp and (hrp.Position - safeZone).Magnitude or 999
        local inSafeZone = distToSafeZone <= 10

        -- 1. UPDATE SCREEN DEBUG HUD
        pcall(function()
            local phaseColor = phaseColors[targetAction] or Color3.fromRGB(200, 200, 200)
            DPhaseLabel.Text = string.format("📌 Fase: [%s]", tostring(targetAction))
            DPhaseLabel.TextColor3 = phaseColor
            DebugStroke.Color = phaseColor

            DTimerLabel.Text = string.format("⏱️ State: %.1fs | Stuck: %.1fs/25s", stateTimer, globalStuckTimer)
            DPosLabel.Text = string.format("📍 Jarak SafeZone: %.1f studs (Di Zona: %s)", distToSafeZone, inSafeZone and "YA" or "TIDAK")
            
            DSignalsLabel.Text = string.format(
                "📡 Sinyal: P2: [%s] | Collect: [%s] | End: [%s]",
                phase2Fired and "✓" or "X",
                collectedFired and "✓" or "X",
                kickEndedFired and "✓" or "X"
            )

            DEventLabel.Text = string.format(
                "☁️ Event: %s | Buff x8: [%s]",
                weatherEventPending and "LuckMachine" or (targetAction:find("LuckMachine") and "Training" or "None"),
                luckBuffObtained and "✓" or "X"
            )

            DMutationLabel.Text = string.format("🧬 Total Mutasi: %d | Gacha: %s", mutationCount, lastRewardDesc)
            DPerfLabel.Text = string.format("⚡ FPS: %d | AFK: %ds | Saklar: %s", fps, elapsedSeconds, autoFarmActive and "ON" or "OFF")
            DLogLabel.Text = "📝 Log: " .. tostring(lastLogMessage)
        end)

        -- 2. UPDATE SIGMA UI MONITOR
        pcall(function()
            statusPara:Set(
                "Status: " .. tostring(targetAction),
                string.format(
                    "User: %s\n" ..
                    "Mutation Count: %d\n" ..
                    "Last Reward: %s\n" ..
                    "AFK Time: %d Detik\n" ..
                    "Fps: %d",
                    lp.Name,
                    mutationCount,
                    lastRewardDesc,
                    elapsedSeconds,
                    fps
                )
            )
        end)

        if not autoFarmActive then continue end
        if not hum or not hrp then continue end 

        -- [ PENDETEKSI MATI & RESPAWN ]
        if hum.Health <= 0 then
            targetAction = "WaitingRespawn"
            lastAction = "WaitingRespawn"
            globalStuckTimer = 0
            setDebugLog("Karakter Mati -> WaitingRespawn")
            continue 
        end

        if targetAction == "WaitingRespawn" and hum.Health > 0 then
            targetAction = "Idle"
            lastAction = "Idle"
            setDebugLog("Karakter Hidup -> Kembali ke Idle")
        end

        -- [ PENGATUR WAKTU OTOMATIS & FAILSAFE 25 DETIK ]
        if targetAction ~= lastAction then
            globalStuckTimer = 0
            stateTimer = 0 
            lastAction = targetAction
            setDebugLog("Transisi Fase -> " .. tostring(targetAction))
        else
            globalStuckTimer = globalStuckTimer + 0.05
            stateTimer = stateTimer + 0.05 
            
            if globalStuckTimer >= 25 and targetAction ~= "LuckMachineTraining" and targetAction ~= "LuckMachineTeleport" then
                globalStuckTimer = 0
                targetAction = "WaitingRespawn"
                setDebugLog("🚨 Failsafe 25s Triggered! Reset karakter...")
                hum.Health = 0 
                continue
            end
        end

        -- [ INTERUPSI EVENT LUCK MACHINE ]
        if weatherEventPending then
            if targetAction ~= "WalkToSafeZone" then
                weatherEventPending = false
                luckBuffObtained = false
                pcall(function() hum:UnequipTools() end)
                targetAction = "LuckMachineTeleport"
                setDebugLog("Event Cuaca Terdeteksi -> Teleport Luck Machine")
            end
        end

        -- [ FASE 1: IDLE / NENDANG DI SAFE ZONE ]
        if targetAction == "Idle" then
            if distToSafeZone > 10 then
                if stateTimer >= 0.5 then
                    hrp.CFrame = safeZoneCFrame
                    stateTimer = 0 
                    setDebugLog("Teleport ke Safe Zone")
                end
            else
                if stateTimer >= 0.5 then
                    phase2Fired = false
                    collectedFired = false
                    kickEndedFired = false
                    executeKick()
                    targetAction = "WaitingForPhase2"
                    setDebugLog("Kick Dieksekusi -> Menunggu Phase 2")
                end
            end

        -- [ FASE 2: NUNGGU PHASE 2 DARI SERVER ]
        elseif targetAction == "WaitingForPhase2" then
            if phase2Fired then
                phase2Fired = false
                targetAction = "PlayingAnim"
                setDebugLog("Phase 2 Selesai -> PlayingAnim")
            elseif stateTimer > 20 then
                targetAction = "Idle"
                setDebugLog("Timeout Phase 2 (20s) -> Re-Idle")
            end

        -- [ FASE 3: NUNGGU ANIMASI GACHA SELESAI ]
        elseif targetAction == "PlayingAnim" then
            if stateTimer >= animDelay then
                targetAction = "WalkToSafeZone"
                setDebugLog("Anim Selesai -> WalkToSafeZone")
            end

        -- [ FASE 4: JALAN / KEMBALI KE SAFE ZONE ]
        elseif targetAction == "WalkToSafeZone" then
            hum:MoveTo(safeZone)
            if distToSafeZone < 8 then
                targetAction = "WaitingForCollected"
                setDebugLog("Tiba di Safe Zone -> WaitingForCollected")
            elseif stateTimer > 8 then
                hrp.CFrame = safeZoneCFrame
                targetAction = "WaitingForCollected"
                setDebugLog("Teleport Safe Zone (8s) -> WaitingForCollected")
            end

        -- [ FASE 5: NUNGGU COLLECTED & RE-KICK INSTAN ]
        elseif targetAction == "WaitingForCollected" then
            if collectedFired or kickEndedFired then
                collectedFired = false
                kickEndedFired = false
                mutationCount = mutationCount + 1
                
                phase2Fired = false
                executeKick()
                targetAction = "WaitingForPhase2"
                setDebugLog("Reward Terkumpul -> Re-Kick Langsung!")
            elseif stateTimer > 6 then
                targetAction = "Idle"
                setDebugLog("Timeout Collected (6s) -> Idle")
            end

        -- [ FASE EX-1: TELEPORT KE LUCK MACHINE ]
        elseif targetAction == "LuckMachineTeleport" then
            local targetPart = nil
            pcall(function()
                local debris = workspace:FindFirstChild("Debris")
                local luckMachine = debris and debris:FindFirstChild("LuckMachine")
                local standingPlatforms = luckMachine and luckMachine:FindFirstChild("StandingPlatforms")
                if standingPlatforms then
                    targetPart = standingPlatforms:FindFirstChild("1") 
                        or standingPlatforms:FindFirstChild("2") 
                        or standingPlatforms:FindFirstChild("3")
                end
            end)
            
            if targetPart then
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.5)
                targetAction = "LuckMachineTraining"
                setDebugLog("Tiba di Platform -> Training Barbell")
            else
                if stateTimer >= 3 then
                    targetAction = "Idle"
                    setDebugLog("Platform tidak ditemukan -> Idle")
                end
            end

        -- [ FASE EX-2: AUTO BARBELL DI LUCK MACHINE SAMPAI BUFF x8 ]
        elseif targetAction == "LuckMachineTraining" then
            local targetPart = nil
            pcall(function()
                local debris = workspace:FindFirstChild("Debris")
                local luckMachine = debris and debris:FindFirstChild("LuckMachine")
                local standingPlatforms = luckMachine and luckMachine:FindFirstChild("StandingPlatforms")
                if standingPlatforms then
                    targetPart = standingPlatforms:FindFirstChild("1") 
                        or standingPlatforms:FindFirstChild("2") 
                        or standingPlatforms:FindFirstChild("3")
                end
            end)
            
            if targetPart and (hrp.Position - targetPart.Position).Magnitude > 8 then
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
            end
            
            local currentTool = char:FindFirstChildOfClass("Tool")
            if currentTool and string.match(currentTool.Name, "Barbell$") then
                currentTool:Activate()
            else
                local backpack = lp:FindFirstChild("Backpack")
                if backpack then
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") and string.match(tool.Name, "Barbell$") then
                            hum:EquipTool(tool)
                            task.wait(0.1)
                            tool:Activate()
                            break
                        end
                    end
                end
            end
            
            if luckBuffObtained or stateTimer >= 240 then
                pcall(function() hum:UnequipTools() end)
                luckBuffObtained = false
                targetAction = "Idle"
                setDebugLog("Selesai Training Luck -> Kembali Idle")
            end
        end
    end
end)

print("--------------------------------------------------")
print("🚀 [SUKSES] KALB Auto Farm V2 (With Screen Debugger) Siap!")
print("--------------------------------------------------")
