-- ==============================================================================
-- 🚀 SIGMA HUB | KALB AUTO FARM V2 (FULL COMPLETE STATE MACHINE FLOW)
-- ==============================================================================
-- Flow Lengkap:
-- 1. 🥔 Potato Optimization & Safe Player Purger (Tanpa Lag / Memory Leak)
-- 2. 🎮 Sigma UI V4 (Main Tab, Auto Farm Toggle, Anim Delay Slider, Stats Monitor, Config)
-- 3. 🧠 Smart State Machine:
--    - Fase 1: Idle (Auto Teleport ke Safe Zone & Eksekusi Kick)
--    - Fase 2: WaitingForPhase2 (Menunggu hasil gacha & bola mendarat dari server)
--    - Fase 3: PlayingAnim (Jeda animasi gacha sesuai slider animDelay)
--    - Fase 4: WalkToSafeZone (Karakter bergerak kembali ke Safe Zone)
--    - Fase 5: WaitingForCollected (Menunggu event reward collected & langsung Re-kick)
--    - Fase Event: LuckMachineTeleport & LuckMachineTraining (Auto Barbell sampai x8 Luck)
-- 4. 🛡️ Failsafe 25s Auto-Respawn Anti-Stuck & Anti-AFK VirtualUser
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
local safeZone = Vector3.new(698.030701, 3.298559, 233.707077)
local safeZoneCFrame = CFrame.new(698.030701, 3.298559, 233.707077, -0.061024, -0.000000, 0.998136, -0.000000, 1.000000, 0.000000, -0.998136, -0.000000, -0.061024)
local startTime = os.time()

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

-- Fallback pencarian remote
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
            end
        end)
    end)
end

if rev_Collected then
    rev_Collected.OnClientEvent:Connect(function(...)
        collectedFired = true
    end)
end

if rev_KickEventEnded then
    rev_KickEventEnded.OnClientEvent:Connect(function(...)
        kickEndedFired = true
    end)
end

if rev_AddedWeather then
    rev_AddedWeather.OnClientEvent:Connect(function(weatherType, ...)
        if weatherType == "LuckMachine" then
            weatherEventPending = true
        end
    end)
end

if rev_PlayMessage then
    rev_PlayMessage.OnClientEvent:Connect(function(msg, msgType)
        if tostring(msg) == "Luck has been increased to x8" then
            luckBuffObtained = true
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
-- ⚙️ MAIN LOOP (STATE MACHINE - AUTO FARM FLOW)
-- =============================================
task.spawn(function()
    while task.wait(0.05) do
        -- Update UI Sigma Monitor
        pcall(function()
            local elapsedSeconds = os.time() - startTime
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

        local char = lp.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not hum or not hrp then continue end 

        -- [ PENDETEKSI MATI & RESPAWN ]
        if hum.Health <= 0 then
            targetAction = "WaitingRespawn"
            lastAction = "WaitingRespawn"
            globalStuckTimer = 0
            continue 
        end

        if targetAction == "WaitingRespawn" and hum.Health > 0 then
            targetAction = "Idle"
            lastAction = "Idle"
        end

        -- [ PENGATUR WAKTU OTOMATIS & FAILSAFE 25 DETIK ]
        if targetAction ~= lastAction then
            globalStuckTimer = 0
            stateTimer = 0 
            lastAction = targetAction
        else
            globalStuckTimer = globalStuckTimer + 0.05
            stateTimer = stateTimer + 0.05 
            
            if globalStuckTimer >= 25 and targetAction ~= "LuckMachineTraining" and targetAction ~= "LuckMachineTeleport" then
                globalStuckTimer = 0
                targetAction = "WaitingRespawn"
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
            end
        end

        local distToSafeZone = (hrp.Position - safeZone).Magnitude

        -- [ FASE 1: IDLE / NENDANG DI SAFE ZONE ]
        if targetAction == "Idle" then
            if distToSafeZone > 10 then
                if stateTimer >= 0.5 then
                    hrp.CFrame = safeZoneCFrame
                    stateTimer = 0 
                end
            else
                if stateTimer >= 0.5 then
                    phase2Fired = false
                    collectedFired = false
                    kickEndedFired = false
                    executeKick()
                    targetAction = "WaitingForPhase2"
                end
            end

        -- [ FASE 2: NUNGGU PHASE 2 DARI SERVER ]
        elseif targetAction == "WaitingForPhase2" then
            if phase2Fired then
                phase2Fired = false
                targetAction = "PlayingAnim"
            elseif stateTimer > 20 then
                targetAction = "Idle"
            end

        -- [ FASE 3: NUNGGU ANIMASI GACHA SELESAI ]
        elseif targetAction == "PlayingAnim" then
            if stateTimer >= animDelay then
                targetAction = "WalkToSafeZone"
            end

        -- [ FASE 4: JALAN / KEMBALI KE SAFE ZONE ]
        elseif targetAction == "WalkToSafeZone" then
            hum:MoveTo(safeZone)
            if distToSafeZone < 8 then
                targetAction = "WaitingForCollected"
            elseif stateTimer > 8 then
                hrp.CFrame = safeZoneCFrame
                targetAction = "WaitingForCollected"
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
            elseif stateTimer > 6 then
                targetAction = "Idle"
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
            else
                if stateTimer >= 3 then
                    targetAction = "Idle"
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
            end
        end
    end
end)

print("--------------------------------------------------")
print("🚀 [SUKSES] KALB Auto Farm V2 State Machine Siap Digunakan!")
print("--------------------------------------------------")
