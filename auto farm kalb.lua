-- ==============================================================================
-- ⚡ AUTO FARM KALB (NATIVE IN-GAME AUTO KICK INTEGRATION)
-- ==============================================================================
-- Memanfaatkan fitur Auto Kick bawaan resmi game:
-- game:GetService("ReplicatedStorage").Shared.Packages.Network.ref_AutoRequest:InvokeServer(true)
-- 
-- Fitur:
-- 1. Anti-Lag & Potato Map Ekstrem (Plastic, White, No Shadows, Plot & Player Removed)
-- 2. Anti-AFK
-- 3. Teleport otomatis ke Safe Zone saat pertama kali run & saat respawn
-- 4. Mengaktifkan fitur resmi Auto Kick bawaan game
-- 5. Auto Interupsi Event Cuaca Luck Machine (Barbell Training x8 Luck)
-- 6. Floating Status HUD Real-Time
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer

-- =============================================
-- ⚙️ KONFIGURASI 
-- =============================================
_G.autoFarm = true
_G.mutationCount = 0

-- =============================================
-- 🚀 SYSTEM ANTI-LAG & OPTIMISASI EKSTREM
-- =============================================
-- 1. Ubah Map Jadi Potato (Putih & Plastic)
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
            v.Color = Color3.new(1, 1, 1)
            if v:IsA("MeshPart") then v.TextureID = "" end
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("SpecialMesh") then
            v:Destroy()
        end
    end)
end

-- 2. Musnahkan Efek Lighting
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
for _, v in ipairs(Lighting:GetDescendants()) do
    if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Sky") then
        pcall(function() v:Destroy() end)
    end
end

-- 3. Hapus Plot 1-5 & Musnahkan Player Lain (FPS Boost)
local plotsFolder = workspace:FindFirstChild("Plots")
if plotsFolder then
    for i = 1, 5 do
        local plot = plotsFolder:FindFirstChild("Plot" .. tostring(i))
        if plot then pcall(function() plot:Destroy() end) end
    end
end

local function musnahkanPlayer(player)
    if player ~= lp then
        if player.Character then pcall(function() player.Character:Destroy() end) end
        pcall(function() player:Destroy() end)
    end
end

for _, player in ipairs(Players:GetPlayers()) do musnahkanPlayer(player) end
Players.PlayerAdded:Connect(function(player)
    task.defer(function() musnahkanPlayer(player) end)
end)

-- =============================================
-- 🛡️ ANTI AFK
-- =============================================
lp.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- =============================================
-- 📍 KOORDINAT SAFE ZONE
-- =============================================
local safeZone = Vector3.new(698.030701, 3.298559, 233.707077)
local safeZoneCFrame = CFrame.new(698.030701, 3.298559, 233.707077, -0.061024, -0.000000, 0.998136, -0.000000, 1.000000, 0.000000, -0.998136, -0.000000, -0.061024)

-- =============================================
-- 📡 CARI REMOTE NETWORK
-- =============================================
local networkFolder = ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
local ref_AutoRequest = networkFolder and (networkFolder:FindFirstChild("ref_AutoRequest") or networkFolder:WaitForChild("ref_AutoRequest", 5))

if not ref_AutoRequest then
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r.Name == "ref_AutoRequest" and r:IsA("RemoteFunction") then
            ref_AutoRequest = r
            break
        end
    end
end

local rev_kickPhase2 = networkFolder and networkFolder:WaitForChild("rev_kickPhase2", 15)
local rev_KickData = networkFolder and networkFolder:WaitForChild("rev_KickData", 15)
local rev_AddedWeather = networkFolder and networkFolder:WaitForChild("rev_AddedWeather", 15)
local rev_PlayMessage = networkFolder and networkFolder:WaitForChild("rev_PlayMessage", 15)

-- =============================================
-- 📊 FLOATING STATUS HUD ON-SCREEN
-- =============================================
local guiParent = pcall(function() return CoreGui end) and CoreGui or lp:WaitForChild("PlayerGui")
local oldHud = guiParent:FindFirstChild("KalbFarmStatusGui")
if oldHud then oldHud:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KalbFarmStatusGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(0, 260, 0, 90)
StatusFrame.Position = UDim2.new(0, 15, 0, 15)
StatusFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
StatusFrame.BorderSizePixel = 0
StatusFrame.Active = true
StatusFrame.Draggable = true
StatusFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = StatusFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(70, 180, 120)
Stroke.Thickness = 1.2
Stroke.Parent = StatusFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 22)
Title.Position = UDim2.new(0, 8, 0, 4)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "⚡ KALB OFFICIAL AUTO KICK"
Title.TextColor3 = Color3.fromRGB(100, 240, 140)
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = StatusFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 20)
StatusLabel.Position = UDim2.new(0, 8, 0, 28)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Text = "Status: Memulai..."
StatusLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local RewardLabel = Instance.new("TextLabel")
RewardLabel.Size = UDim2.new(1, -10, 0, 20)
RewardLabel.Position = UDim2.new(0, 8, 0, 50)
RewardLabel.BackgroundTransparency = 1
RewardLabel.Font = Enum.Font.GothamBold
RewardLabel.Text = "Total Brainrots: 0"
RewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
RewardLabel.TextSize = 12
RewardLabel.TextXAlignment = Enum.TextXAlignment.Left
RewardLabel.Parent = StatusFrame

local function updateStatus(text, color)
    StatusLabel.Text = "Status: " .. tostring(text)
    if color then StatusLabel.TextColor3 = color end
end

-- =============================================
-- 📡 DAFTAR EVENT LISTENER
-- =============================================
local weatherEventPending = false
local luckBuffObtained = false

if rev_kickPhase2 then
    rev_kickPhase2.OnClientEvent:Connect(function(rewardTable, ...)
        _G.mutationCount = _G.mutationCount + 1
        
        local rewardName = "Brainrot"
        local mutationType = "Normal"
        pcall(function()
            if type(rewardTable) == "table" and rewardTable[1] then
                rewardName = tostring(rewardTable[1].Name or "Brainrot")
                mutationType = tostring(rewardTable[1].Mutation or "Normal")
            end
        end)
        
        RewardLabel.Text = string.format("Brainrot: %s (%s) | Total: %d", rewardName, mutationType, _G.mutationCount)
        updateStatus(string.format("🎉 Didapat: %s [%s]!", rewardName, mutationType), Color3.fromRGB(100, 240, 120))
    end)
end

if rev_KickData then
    rev_KickData.OnClientEvent:Connect(function(powerVal, distVal)
        updateStatus(string.format("🚀 Bola Melayang! Jarak: %sm", tostring(distVal)), Color3.fromRGB(255, 200, 80))
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

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

-- Helper Klik Tombol AutoButton di PlayerGui.HUD.AutoKickFrame (Tepat 1 Kali Saja)
local function clickAutoButton()
    pcall(function()
        local playerGui = lp:FindFirstChild("PlayerGui")
        local hud = playerGui and playerGui:FindFirstChild("HUD")
        local autoKickFrame = hud and (hud:FindFirstChild("AutoKickFrame", true) or hud:FindFirstChild("AutoKick", true))
        local autoBtn = autoKickFrame and (autoKickFrame:FindFirstChild("AutoButton", true) or autoKickFrame:FindFirstChildOfClass("ImageButton") or autoKickFrame:FindFirstChildOfClass("GuiButton"))
        
        if not autoBtn and hud then
            for _, v in ipairs(hud:GetDescendants()) do
                if v:IsA("ImageButton") and (v.Name == "AutoButton" or tostring(v.Image):find("136607941521284")) then
                    autoBtn = v
                    break
                end
            end
        end
        
        if autoBtn and autoBtn:IsA("GuiButton") and autoBtn.Visible then
            if firesignal then
                firesignal(autoBtn.Activated)
            else
                local pos = autoBtn.AbsolutePosition + (autoBtn.AbsoluteSize / 2)
                if VirtualInputManager then
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                else
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(pos)
                end
            end
        end
    end)
end

-- Helper Aktifkan Auto Kick Bawaan Game (Teleport -> AutoRequest -> Tunggu 3 Detik -> Klik AutoButton)
local isActivatingAutoKick = false
local function triggerAutoKickSequence()
    if isActivatingAutoKick then return end
    isActivatingAutoKick = true

    task.spawn(function()
        -- 1. Teleport ke Safe Zone
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if hrp then
            hrp.CFrame = safeZoneCFrame
            task.wait(0.5)
        end

        -- 2. Panggil AutoRequest
        updateStatus("📡 Memanggil ref_AutoRequest...", Color3.fromRGB(100, 200, 255))
        if ref_AutoRequest then
            pcall(function()
                ref_AutoRequest:InvokeServer(true)
            end)
        end

        -- 3. Tunggu 3 Detik
        updateStatus("⏳ Menunggu 3 detik...", Color3.fromRGB(255, 200, 80))
        task.wait(3)

        -- 4. Klik AutoButton di GUI
        updateStatus("🔘 Menekan AutoButton...", Color3.fromRGB(100, 200, 255))
        clickAutoButton()
        updateStatus("✅ Auto Kick Aktif!", Color3.fromRGB(100, 240, 120))

        isActivatingAutoKick = false
    end)
end

-- =============================================
-- ⚙️ MAIN LOOP (AUTO FARM WITH IN-GAME AUTO KICK)
-- =============================================
task.spawn(function()
    -- 1. Jalankan urutan Auto Kick saat pertama kali start
    triggerAutoKickSequence()

    while task.wait(1) do
        if not _G.autoFarm then continue end

        local currentChar = lp.Character
        local currentHum = currentChar and currentChar:FindFirstChild("Humanoid")
        local currentHrp = currentChar and currentChar:FindFirstChild("HumanoidRootPart")

        if not currentHum or not currentHrp then continue end

        -- [ PENDETEKSI MATI / RESPAWN ]
        if currentHum.Health <= 0 then
            updateStatus("Menunggu respawn...", Color3.fromRGB(255, 100, 100))
            task.wait(2.0)
            
            -- Begitu hidup kembali, jalankan sequence lagi
            triggerAutoKickSequence()
            continue
        end

        -- [ EVENT CUACA LUCK MACHINE ]
        if weatherEventPending then
            weatherEventPending = false
            updateStatus("⚡ Event Cuaca! Menuju Luck Machine...", Color3.fromRGB(220, 120, 240))
            
            local targetPart = nil
            pcall(function()
                local debris = workspace:FindFirstChild("Debris")
                local luckMachine = debris and debris:FindFirstChild("LuckMachine")
                local standingPlatforms = luckMachine and luckMachine:FindFirstChild("StandingPlatforms")
                if standingPlatforms then
                    targetPart = standingPlatforms:FindFirstChild("1") or standingPlatforms:FindFirstChild("2") or standingPlatforms:FindFirstChild("3")
                end
            end)
            
            if targetPart then
                currentHrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.5)
                
                local trainStart = os.clock()
                while os.clock() - trainStart < 240 and not luckBuffObtained do
                    if not _G.autoFarm then break end
                    local currentTool = currentChar:FindFirstChildOfClass("Tool")
                    if currentTool and string.match(currentTool.Name, "Barbell$") then
                        currentTool:Activate()
                    else
                        local backpack = lp:FindFirstChild("Backpack")
                        if backpack then
                            for _, tool in ipairs(backpack:GetChildren()) do
                                if tool:IsA("Tool") and string.match(tool.Name, "Barbell$") then
                                    currentHum:EquipTool(tool)
                                    task.wait(0.1)
                                    tool:Activate()
                                    break
                                end
                            end
                        end
                    end
                    task.wait(0.2)
                end
                
                pcall(function() currentHum:UnequipTools() end)
                luckBuffObtained = false
                
                -- Jalankan sequence Auto Kick kembali
                triggerAutoKickSequence()
            end
        end
    end
end)
