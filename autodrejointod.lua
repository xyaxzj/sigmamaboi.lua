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
local safeZone = Vector3.new(689, 3, 236)
local startTime = os.time()     

-- =============================================
-- ⬛ CLEANUP & SETUP BLACKSCREEN UI
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
    infoLabel.Position = UDim2.new(0, 0, 0.5, -90)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.new(1, 1, 1)
    infoLabel.TextSize = 35
    infoLabel.Font = Enum.Font.Code
    infoLabel.Text = "SeNchO | Battlepass Farm Point"
    infoLabel.Parent = bg

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, 0, 0, 30)
    fpsLabel.Position = UDim2.new(0, 0, 0.5, -30)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Color3.new(0, 1, 1)
    fpsLabel.TextSize = 25
    fpsLabel.Font = Enum.Font.Code
    fpsLabel.Text = "FPS = Menghitung..."
    fpsLabel.Parent = bg

    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, 0, 0, 30)
    timeLabel.Position = UDim2.new(0, 0, 0.5, 10)
    timeLabel.BackgroundTransparency = 1
    timeLabel.TextColor3 = Color3.new(1, 1, 0)
    timeLabel.TextSize = 25
    timeLabel.Font = Enum.Font.Code
    timeLabel.Text = "Time Counter = 00:00:00"
    timeLabel.Parent = bg

    countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, 0, 0, 30)
    countLabel.Position = UDim2.new(0, 0, 0.5, 50)
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

    local frames = 0
    local lastUpdate = os.clock()
    local fpsConnection
    fpsConnection = RunService.RenderStepped:Connect(function()
        if not fpsLabel or not fpsLabel.Parent then 
            fpsConnection:Disconnect() 
            return 
        end
        frames = frames + 1
        local now = os.clock()
        if now - lastUpdate >= 1 then
            fpsLabel.Text = "FPS = " .. frames
            frames = 0
            lastUpdate = now
        end
    end)
end

-- =============================================
-- ⚡ FPS BOOST OTOMATIS
-- =============================================
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if Terrain then Terrain.WaterWaveSize = 0; Terrain.WaterReflectance = 0 end
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic
        elseif v:IsA("PostEffect") or v:IsA("ParticleEmitter") then v.Enabled = false end
    end
end)

-- =============================================
-- 🛡️ ANTI AFK
-- =============================================
lp.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local kickRemote = nil
for _, r in pairs(ReplicatedStorage:GetDescendants()) do
    if r:IsA("RemoteEvent") and string.find(r.Name, "rev_KickEvent") and not string.find(r.Name, "Ended") then
        kickRemote = r; break
    end
end

-- =============================================
-- 👁️ SENSOR 3D
-- =============================================
workspace.DescendantAdded:Connect(function(obj)
    if not _G.autoFarm or _G.targetAction ~= "WaitingForDrop" then return end
    if not obj:IsA("Model") then return end 
    
    task.wait(0.1) 
    if _G.targetAction ~= "WaitingForDrop" then return end 

    local mutation = obj:GetAttribute("Mutation")
    if mutation ~= nil then 
        pcall(function()
            local itemPos = obj:GetPivot().Position
            if (itemPos - safeZone).Magnitude < 60 then
                
                _G.targetAction = "PlayingAnim"
                
                if mutation == "None" or mutation == "" then
                    _G.nextAction = "Die"
                else
                    _G.targetItemPos = itemPos
                    _G.nextAction = "WalkToItem"
                end
                
            end
        end)
    end
end)

-- =============================================
-- 👻 GHOST MODE CERDAS
-- =============================================
task.spawn(function()
    while task.wait(1) do 
        if _G.hideOtherPlayers then
            pcall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= lp and player.Character and not player.Character:GetAttribute("Ghosted") then
                        player.Character:SetAttribute("Ghosted", true) 
                        for _, v in pairs(player.Character:GetDescendants()) do
                            if v:IsA("BasePart") or v:IsA("Decal") then v.Transparency = 1; v.CanCollide = false
                            elseif v:IsA("Accessory") or v:IsA("ParticleEmitter") then v:Destroy() end
                        end
                    end
                end
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Model") and obj ~= lp.Character and obj:FindFirstChild("Humanoid") and not obj:GetAttribute("Ghosted") then
                        obj:SetAttribute("Ghosted", true) 
                        for _, v in pairs(obj:GetDescendants()) do
                            if v:IsA("BasePart") or v:IsA("Decal") then v.Transparency = 1; v.CanCollide = false
                            elseif v:IsA("Accessory") or v:IsA("ParticleEmitter") then v:Destroy() end
                        end
                    end
                end
            end)
        end
    end
end)

-- =============================================
-- ⚙️ MAIN LOOP (PERFECT STATE MACHINE)
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
                _G.targetAction = "WaitingRespawn"
                _G.lastAction = "WaitingRespawn"
                _G.globalStuckTimer = 0
                return 
            end

            if _G.targetAction == "WaitingRespawn" and hum.Health > 0 then
                _G.targetAction = "Idle"
                _G.lastAction = "Idle"
            end

            -- ==========================================
            -- 🚨 PENGATUR WAKTU OTOMATIS & FAILSAFE
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
                    return
                end
            end

            local distToSafeZone = (hrp.Position - safeZone).Magnitude

            -- [ FASE 1: IDLE / NENDANG (DENGAN JEDA GANDA) ]
            if _G.targetAction == "Idle" then
                if distToSafeZone > 10 then
                    -- TUNGGU 2 DETIK DI SPAWN SEBELUM TELEPORT
                    if _G.stateTimer >= 2 then
                        hrp.CFrame = CFrame.new(safeZone)
                        task.wait(0.1) -- Jeda kecil agar physics stabil
                        _G.stateTimer = 0 -- Reset timer untuk persiapan nendang
                    end
                else
                    -- TUNGGU 2 DETIK DI SAFE ZONE SEBELUM NENDANG
                    if _G.stateTimer >= 2 then
                        if kickRemote then kickRemote:FireServer(1, 1) end
                        _G.targetAction = "WaitingForDrop"
                    end
                end

            -- [ FASE 2: NUNGGU DROP ]
            elseif _G.targetAction == "WaitingForDrop" then
                if _G.stateTimer > 15 then
                    _G.targetAction = "Idle"
                end

            -- [ FASE 3: NUNGGU ANIMASI 7.3s ]
            elseif _G.targetAction == "PlayingAnim" then
                if _G.stateTimer >= _G.animDelay then
                    _G.targetAction = _G.nextAction
                end

            -- [ FASE 4: JALAN MENGAMBIL ITEM MUTASI ]
            elseif _G.targetAction == "WalkToItem" then
                if _G.targetItemPos then
                    hum:MoveTo(_G.targetItemPos)
                    local distToItem = (hrp.Position - _G.targetItemPos).Magnitude
                    if distToItem < 8 then 
                        _G.targetAction = "WalkToSafeZone"
                    end
                else
                    _G.targetAction = "Idle" 
                end

            -- [ FASE 5: JALAN BALIK KE SAFE ZONE (+1) ]
            elseif _G.targetAction == "WalkToSafeZone" then
                hum:MoveTo(safeZone)
                if distToSafeZone < 8 then
                    _G.mutationCount = _G.mutationCount + 1
                    if countLabel then countLabel.Text = "Mutation Counter = " .. tostring(_G.mutationCount) end
                    _G.targetAction = "Idle" 
                end

            -- [ FASE 6: BUNUH DIRI (AMPAS) ]
            elseif _G.targetAction == "Die" then
                hum.Health = 0
                _G.targetAction = "WaitingRespawn" 
            end
        end)
    end
end)
