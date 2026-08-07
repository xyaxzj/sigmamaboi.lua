if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- =============================================
-- ⚙️ KONFIGURASI 
-- =============================================
_G.autoFarm = true              
_G.animDelay = 5              
_G.blackScreen = false           

-- =============================================
-- 🧠 VARIABEL OTAK UTAMA (STATE MACHINE)
-- =============================================
_G.targetAction = "Idle"
_G.lastAction = "Idle"
_G.nextAction = "Idle"          
_G.stateTimer = 0               
_G.globalStuckTimer = 0         
_G.mutationCount = 0            
_G.targetItemPos = nil          
local safeZone = Vector3.new(698.030701, 3.298559, 233.707077)
local safeZoneCFrame = CFrame.new(698.030701, 3.298559, 233.707077, -0.061024, -0.000000, 0.998136, -0.000000, 1.000000, 0.000000, -0.998136, -0.000000, -0.061024)
local startTime = os.time()     

-- =============================================
-- ⬛ SETUP BLACKSCREEN UI
-- =============================================
local guiParent = pcall(function() return CoreGui end) and CoreGui or lp:WaitForChild("PlayerGui")
local oldGui = guiParent:FindFirstChild("AFK_Blackscreen")
if oldGui then oldGui:Destroy() end 

local countLabel = nil 

if _G.blackScreen then
    pcall(function() RunService:Set3dRenderingEnabled(false) end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AFK_Blackscreen"
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = guiParent

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.new(0, 0, 0) 
    bg.Parent = screenGui

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 40)
    infoLabel.Position = UDim2.new(0, 0, 0.5, -60)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.new(1, 1, 1)
    infoLabel.TextSize = 35
    infoLabel.Font = Enum.Font.Code
    infoLabel.Text = "SeNchO | Battlepass Farm Point"
    infoLabel.Parent = bg

    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, 0, 0, 30)
    timeLabel.Position = UDim2.new(0, 0, 0.5, -10)
    timeLabel.BackgroundTransparency = 1
    timeLabel.TextColor3 = Color3.new(1, 1, 0)
    timeLabel.TextSize = 25
    timeLabel.Font = Enum.Font.Code
    timeLabel.Text = "Time Counter = 00:00:00"
    timeLabel.Parent = bg

    countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, 0, 0, 30)
    countLabel.Position = UDim2.new(0, 0, 0.5, 30)
    countLabel.BackgroundTransparency = 1
    countLabel.TextColor3 = Color3.new(0, 1, 0)
    countLabel.TextSize = 25
    countLabel.Font = Enum.Font.Code
    countLabel.Text = "Mutation Counter = 0"
    countLabel.Parent = bg

    task.spawn(function()
        while task.wait(1) do
            if not timeLabel or not timeLabel.Parent then break end
            local elapsed = os.time() - startTime
            local hours = math.floor(elapsed / 3600)
            local mins = math.floor((elapsed % 3600) / 60)
            local secs = elapsed % 60
            timeLabel.Text = string.format("Time Counter = %02d:%02d:%02d", hours, mins, secs)
        end
    end)
end

-- =============================================
-- 🛡️ ANTI AFK
-- =============================================
lp.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- =============================================
-- 📡 CARI REMOTE
-- =============================================
local kickRemote = nil
local networkFolder = ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
if networkFolder then
    kickRemote = networkFolder:FindFirstChild("rev_KickEvent")
end

if not kickRemote then
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") and string.find(r.Name, "rev_KickEvent") and not string.find(r.Name, "Ended") then
            kickRemote = r; break
        end
    end
end

local rev_kickPhase2 = networkFolder and networkFolder:WaitForChild("rev_kickPhase2", 15)
local rev_Collected = networkFolder and networkFolder:WaitForChild("rev_Collected", 15)
local rev_KickEventEnded = networkFolder and networkFolder:WaitForChild("rev_KickEventEnded", 15)

-- =============================================
-- 📡 DAFTAR EVENT LISTENER
-- =============================================
local phase2Fired = false
local collectedFired = false
local kickEndedFired = false

if rev_kickPhase2 then
    rev_kickPhase2.OnClientEvent:Connect(function(...)
        phase2Fired = true
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

-- =============================================
-- ⚙️ MAIN LOOP (STATE MACHINE - OPTIMIZED)
-- =============================================
task.spawn(function()
    while task.wait(0.2) do
        if not _G.autoFarm then continue end

        local char = lp.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not hum or not hrp then 
            -- Coba wait jika character belum dimuat
            continue 
        end 

        -- [ PENDETEKSI MATI ]
        if hum.Health <= 0 then
            _G.targetAction = "WaitingRespawn"
            _G.lastAction = "WaitingRespawn"
            _G.globalStuckTimer = 0
            continue 
        end

        -- [ PENDETEKSI HIDUP KEMBALI ]
        if _G.targetAction == "WaitingRespawn" and hum.Health > 0 then
            _G.targetAction = "Idle"
            _G.lastAction = "Idle"
        end

        -- ==========================================
        -- 🚨 PENGATUR WAKTU OTOMATIS & FAILSAFE 25s
        -- ==========================================
        if _G.targetAction ~= _G.lastAction then
            _G.globalStuckTimer = 0
            _G.stateTimer = 0 
            _G.lastAction = _G.targetAction
        else
            _G.globalStuckTimer = _G.globalStuckTimer + 0.2
            _G.stateTimer = _G.stateTimer + 0.2 
            
            if _G.globalStuckTimer >= 25 then
                _G.globalStuckTimer = 0
                _G.targetAction = "WaitingRespawn"
                hum.Health = 0 
                continue
            end
        end

        local distToSafeZone = (hrp.Position - safeZone).Magnitude

        -- [ FASE 1: IDLE / NENDANG (JEDA HANYA DI SPAWN) ]
        if _G.targetAction == "Idle" then
            if distToSafeZone > 10 then
                -- Jeda 4 detik setelah hidup di spawn sebelum teleport
                if _G.stateTimer >= 4 then
                    hrp.CFrame = safeZoneCFrame
                    task.wait(0.1) 
                    _G.stateTimer = 0 
                end
            else
                -- Jika sudah di Safe Zone, langsung kick tanpa delay!
                phase2Fired = false
                collectedFired = false
                kickEndedFired = false
                if kickRemote then 
                    kickRemote:FireServer(1, 1) 
                end
                _G.targetAction = "WaitingForPhase2"
            end

        -- [ FASE 2: NUNGGU PHASE 2 ]
        elseif _G.targetAction == "WaitingForPhase2" then
            if phase2Fired then
                phase2Fired = false
                _G.targetAction = "PlayingAnim"
            elseif _G.stateTimer > 15 then
                _G.targetAction = "Idle"
            end

        -- [ FASE 3: NUNGGU ANIMASI GACHA (5 DETIK) ]
        elseif _G.targetAction == "PlayingAnim" then
            if _G.stateTimer >= _G.animDelay then
                _G.targetAction = "WalkToSafeZone"
            end

        -- [ FASE 4: JALAN BALIK KE SAFE ZONE ]
        elseif _G.targetAction == "WalkToSafeZone" then
            hum:MoveTo(safeZone)
            if distToSafeZone < 8 then
                collectedFired = false
                kickEndedFired = false
                _G.targetAction = "WaitingForCollected"
            end

        -- [ FASE 5: NUNGGU COLLECTED ATAU KICKENDED (LANGSUNG KICK KEMBALI) ]
        elseif _G.targetAction == "WaitingForCollected" then
            if collectedFired or kickEndedFired then
                collectedFired = false
                kickEndedFired = false
                _G.mutationCount = _G.mutationCount + 1
                if countLabel then countLabel.Text = "Mutation Counter = " .. tostring(_G.mutationCount) end
                
                -- Langsung lakukan kick kembali tanpa delay
                phase2Fired = false
                if kickRemote then 
                    kickRemote:FireServer(1, 1) 
                end
                _G.targetAction = "WaitingForPhase2"
            elseif _G.stateTimer > 15 then
                _G.targetAction = "Idle"
            end
        end
    end
end)
