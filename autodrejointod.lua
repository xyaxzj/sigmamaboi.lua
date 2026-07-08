if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- =============================================
-- ⚙️ KONFIGURASI 
-- =============================================
_G.autoFarm = true              
_G.hideOtherPlayers = true      
_G.animDelay = 7.3              
_G.blackScreen = true           

-- Variabel Sistem
_G.targetAction = "Idle"
_G.lastAction = "Idle"          
_G.globalStuckTimer = 0         
_G.timeoutCounter = 0 
_G.mutationCount = 0            
local safeZone = Vector3.new(689, 3, 236)
local startTime = os.time()     

-- =============================================
-- ⬛ SETUP BLACKSCREEN & TRACKER UI (FIXED)
-- =============================================
local countLabel = nil 

if _G.blackScreen then
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)

    local guiParent = pcall(function() return CoreGui end) and CoreGui or lp:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AFK_Blackscreen"
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = guiParent

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.new(0, 0, 0) 
    bg.Parent = screenGui

    -- Label Title (SeNchO)
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 40)
    infoLabel.Position = UDim2.new(0, 0, 0.5, -90)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.new(1, 1, 1) -- Putih
    infoLabel.TextSize = 35 -- Ukuran Fix
    infoLabel.Font = Enum.Font.Code
    infoLabel.Text = "SeNchO | Battlepass Farm Point"
    infoLabel.Parent = bg

    -- Label FPS
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, 0, 0, 30)
    fpsLabel.Position = UDim2.new(0, 0, 0.5, -30)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Color3.new(0, 1, 1) -- Cyan
    fpsLabel.TextSize = 25
    fpsLabel.Font = Enum.Font.Code
    fpsLabel.Text = "FPS = Menghitung..."
    fpsLabel.Parent = bg

    -- Label Stopwatch
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, 0, 0, 30)
    timeLabel.Position = UDim2.new(0, 0, 0.5, 10)
    timeLabel.BackgroundTransparency = 1
    timeLabel.TextColor3 = Color3.new(1, 1, 0) -- Kuning
    timeLabel.TextSize = 25
    timeLabel.Font = Enum.Font.Code
    timeLabel.Text = "Time Counter = 00:00:00"
    timeLabel.Parent = bg

    -- Label Counter Mutasi
    countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, 0, 0, 30)
    countLabel.Position = UDim2.new(0, 0, 0.5, 50)
    countLabel.BackgroundTransparency = 1
    countLabel.TextColor3 = Color3.new(0, 1, 0) -- Hijau
    countLabel.TextSize = 25
    countLabel.Font = Enum.Font.Code
    countLabel.Text = "Mutation Counter = 0"
    countLabel.Parent = bg

    -- Mesin Penghitung Waktu (Stopwatch)
    task.spawn(function()
        while task.wait(1) do
            if timeLabel and timeLabel.Parent then
                local elapsed = os.time() - startTime
                local hours = math.floor(elapsed / 3600)
                local mins = math.floor((elapsed % 3600) / 60)
                local secs = elapsed % 60
                timeLabel.Text = string.format("Time Counter = %02d:%02d:%02d", hours, mins, secs)
            end
        end
    end)

    -- Mesin Penghitung FPS
    local frames = 0
    local lastUpdate = os.clock()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - lastUpdate >= 1 then
            if fpsLabel and fpsLabel.Parent then
                fpsLabel.Text = "FPS = " .. frames
            end
            frames = 0
            lastUpdate = now
        end
    end)
end

-- =============================================
-- ⚡ EKSEKUSI FPS BOOST OTOMATIS
-- =============================================
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.ShadowSoftness = 0
    
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterWaveSize = 0; Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0; Terrain.WaterTransparency = 0
    end

    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("PostEffect") then
            v.Transparency = (v:IsA("Decal") or v:IsA("Texture")) and 1 or v.Transparency
            if not v:IsA("Decal") and not v:IsA("Texture") then v.Enabled = false end
        end
    end
end)

-- =============================================
-- 🛡️ BUILT-IN ANTI AFK
-- =============================================
lp.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

task.spawn(function()
    while task.wait(300) do 
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- =============================================
-- CARI KICK REMOTE
-- =============================================
local kickRemote = nil
for _, r in pairs(ReplicatedStorage:GetDescendants()) do
    if r:IsA("RemoteEvent") and string.find(r.Name, "rev_KickEvent") and not string.find(r.Name, "Ended") then
        kickRemote = r; break
    end
end

-- =============================================
-- 👁️ SENSOR 3D MURNI
-- =============================================
workspace.DescendantAdded:Connect(function(obj)
    if not _G.autoFarm or _G.targetAction ~= "WaitingForDrop" then return end
    
    if obj:IsA("Model") then
        task.wait(0.05) 
        local mutation = obj:GetAttribute("Mutation")
        if mutation ~= nil then 
            pcall(function()
                local dist = (obj:GetPivot().Position - safeZone).Magnitude
                if dist < 60 then
                    _G.targetAction = "PlayingAnim"
                    
                    if mutation == "None" or mutation == "" then
                        task.spawn(function()
                            task.wait(_G.animDelay)
                            _G.targetAction = "Die"
                        end)
                    else
                        task.spawn(function()
                            task.wait(_G.animDelay)
                            _G.targetAction = "Walk"
                        end)
                    end
                end
            end)
        end
    end
end)

-- =============================================
-- 👻 GHOST MODE (PEMUTIH PEMAIN)
-- =============================================
task.spawn(function()
    while task.wait(0.5) do 
        if _G.hideOtherPlayers then
            pcall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= lp and player.Character then
                        for _, v in pairs(player.Character:GetDescendants()) do
                            if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1; v.CanCollide = false
                            elseif v:IsA("Accessory") or v:IsA("Tool") or v:IsA("ParticleEmitter") or v:IsA("Trail") then v:Destroy() end
                        end
                    end
                end
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Model") and obj ~= lp.Character and obj:FindFirstChild("Humanoid") then
                        for _, v in pairs(obj:GetDescendants()) do
                            if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1; v.CanCollide = false
                            elseif v:IsA("Accessory") or v:IsA("ParticleEmitter") then v:Destroy() end
                        end
                    end
                end
            end)
        end
    end
end)

-- =============================================
-- ⚙️ MAIN LOOP (STATE MACHINE + 25s FAILSAFE)
-- =============================================
task.spawn(function()
    while task.wait(0.2) do
        if not _G.autoFarm then continue end

        pcall(function()
            local char = lp.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not hum or not hrp then return end

            if hum.Health <= 0 then
                _G.targetAction = "Idle"
                _G.lastAction = "Idle"
                _G.globalStuckTimer = 0
                _G.timeoutCounter = 0
                task.wait(2) 
                return
            end

            -- ==========================================
            -- 🚨 SISTEM FAILSAFE 25 DETIK (ANTI-NYANGKUT)
            -- ==========================================
            if _G.targetAction ~= _G.lastAction then
                _G.globalStuckTimer = 0
                _G.lastAction = _G.targetAction
            else
                _G.globalStuckTimer = _G.globalStuckTimer + 0.2
                if _G.globalStuckTimer >= 25 then
                    _G.globalStuckTimer = 0
                    _G.targetAction = "Idle"
                    hum.Health = 0 
                    return
                end
            end
            -- ==========================================

            local dist = (hrp.Position - safeZone).Magnitude

            if _G.targetAction == "Idle" then
                if dist > 10 then
                    hrp.CFrame = CFrame.new(safeZone)
                    task.wait(0.3)
                else
                    if kickRemote then kickRemote:FireServer(1, 1) end
                    _G.targetAction = "WaitingForDrop"
                    _G.timeoutCounter = 0
                end

            elseif _G.targetAction == "WaitingForDrop" then
                _G.timeoutCounter = _G.timeoutCounter + 0.2
                if _G.timeoutCounter > 15 then
                    _G.targetAction = "Idle"
                    _G.timeoutCounter = 0
                end
                hum:MoveTo(hrp.Position)

            elseif _G.targetAction == "PlayingAnim" then
                hum:MoveTo(hrp.Position)

            elseif _G.targetAction == "Walk" then
                hum:MoveTo(safeZone)
                if dist < 8 then
                    _G.mutationCount = _G.mutationCount + 1
                    if countLabel then
                        countLabel.Text = "Mutation Counter = " .. tostring(_G.mutationCount)
                    end
                    _G.targetAction = "Idle" 
                end

            elseif _G.targetAction == "Die" then
                hum.Health = 0
            end
        end)
    end
end)
