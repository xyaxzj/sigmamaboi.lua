-- ==============================================================================
-- 💥 KALB AUTO METEOR CLAIMER (WITH DETAILED CONSOLE & ON-SCREEN DEBUG)
-- ==============================================================================
-- Fitur:
-- 1. 🎯 Khusus mendeteksi Model bernama Angka (1, 2, 3...) di dalam folder workspace.Debris
-- 2. 💥 Ultimate Combo Claim: Max Hitbox (2048) + CFrame Magnet + Multi-Limb Touch + Micro Flash Snap
-- 3. 🐞 Real-Time Console & On-Screen Debugger (Tekan F9 / Buka Console Executor)
-- ==============================================================================

print("--------------------------------------------------")
print("☄️ [DEBUG 1] Script auto meteor kalb.lua dieksekusi...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
if not lp then
    local count = 0
    repeat
        task.wait(0.05)
        lp = Players.LocalPlayer
        count = count + 1
    until lp or count > 50
end

print("☄️ [DEBUG 2] LocalPlayer:", lp and lp.Name or "TIDAK DITEMUKAN")

-- =============================================
-- ⚙️ KONFIGURASI 
-- =============================================
_G.autoMeteor = true
local meteorClaimCount = 0
local isMeteorShowerActive = false
local MAX_SIZE = Vector3.new(2048, 2048, 2048)

local activeMeteors = {}
local processedRoots = {}
local isSnapping = false

-- =============================================
-- 📊 FLOATING STATUS HUD ON-SCREEN
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
print("☄️ [DEBUG 3] Target GUI Container:", targetGuiParent and targetGuiParent:GetFullName() or "NIL (PlayerGui belum siap)")

-- Hapus GUI lama jika ada
pcall(function()
    if lp and lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("KalbMeteorStatusGui") then
        lp.PlayerGui.KalbMeteorStatusGui:Destroy()
    end
    if targetGuiParent and targetGuiParent:FindFirstChild("KalbMeteorStatusGui") then
        targetGuiParent.KalbMeteorStatusGui:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KalbMeteorStatusGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 99999
ScreenGui.Enabled = true

local StatusFrame = Instance.new("Frame")
StatusFrame.Name = "MainFrame"
StatusFrame.Size = UDim2.new(0, 280, 0, 135)
StatusFrame.Position = UDim2.new(0, 20, 0, 70)
StatusFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
StatusFrame.BorderSizePixel = 0
StatusFrame.Active = true
StatusFrame.Draggable = true
StatusFrame.Visible = true
StatusFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = StatusFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 160, 40)
Stroke.Thickness = 1.5
Stroke.Parent = StatusFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 22)
Title.Position = UDim2.new(0, 8, 0, 5)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "☄️ KALB METEOR CLAIMER"
Title.TextColor3 = Color3.fromRGB(255, 180, 50)
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = StatusFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 20)
StatusLabel.Position = UDim2.new(0, 8, 0, 28)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Text = "Status: Menunggu Meteor..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local MeteorLabel = Instance.new("TextLabel")
MeteorLabel.Size = UDim2.new(1, -10, 0, 20)
MeteorLabel.Position = UDim2.new(0, 8, 0, 50)
MeteorLabel.BackgroundTransparency = 1
MeteorLabel.Font = Enum.Font.GothamBold
MeteorLabel.Text = "☄️ Meteor Diklaim: 0"
MeteorLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
MeteorLabel.TextSize = 11
MeteorLabel.TextXAlignment = Enum.TextXAlignment.Left
MeteorLabel.Parent = StatusFrame

local RewardLabel = Instance.new("TextLabel")
RewardLabel.Size = UDim2.new(1, -10, 0, 20)
RewardLabel.Position = UDim2.new(0, 8, 0, 72)
RewardLabel.BackgroundTransparency = 1
RewardLabel.Font = Enum.Font.GothamBold
RewardLabel.Text = "Total Brainrots: 0"
RewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
RewardLabel.TextSize = 11
RewardLabel.TextXAlignment = Enum.TextXAlignment.Left
RewardLabel.Parent = StatusFrame

local DebugLabel = Instance.new("TextLabel")
DebugLabel.Size = UDim2.new(1, -10, 0, 20)
DebugLabel.Position = UDim2.new(0, 8, 0, 96)
DebugLabel.BackgroundTransparency = 1
DebugLabel.Font = Enum.Font.Code
DebugLabel.Text = "Debug: Initialized"
DebugLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
DebugLabel.TextSize = 10
DebugLabel.TextXAlignment = Enum.TextXAlignment.Left
DebugLabel.Parent = StatusFrame

-- Pasang ScreenGui
pcall(function()
    ScreenGui.Parent = targetGuiParent or lp:WaitForChild("PlayerGui", 5)
end)

print("☄️ [DEBUG 4] ScreenGui terpasang pada:", ScreenGui.Parent and ScreenGui.Parent:GetFullName() or "GAGAL TERPASANG")

local function updateStatus(text, color)
    pcall(function()
        StatusLabel.Text = "Status: " .. tostring(text)
        if color then StatusLabel.TextColor3 = color end
    end)
end

local function logDebug(text)
    print("☄️ [DEBUG]", text)
    pcall(function()
        DebugLabel.Text = "Debug: " .. tostring(text)
    end)
end

logDebug("HUD Siap! Mencari folder Debris...")

-- =============================================
-- 📡 CARI REMOTE NETWORK (SAFE DISCOVERY)
-- =============================================
local networkFolder = nil
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 2)
    local packages = shared and (shared:FindFirstChild("Packages") or shared:WaitForChild("Packages", 2))
    networkFolder = packages and (packages:FindFirstChild("Network") or packages:WaitForChild("Network", 2))
end)

local rev_kickPhase2 = networkFolder and networkFolder:FindFirstChild("rev_kickPhase2")
local rev_KickData = networkFolder and networkFolder:FindFirstChild("rev_KickData")
local rev_AddedWeather = networkFolder and networkFolder:FindFirstChild("rev_AddedWeather")
local rev_RemovedWeather = networkFolder and networkFolder:FindFirstChild("rev_RemovedWeather")

local mutationCount = 0
if rev_kickPhase2 then
    rev_kickPhase2.OnClientEvent:Connect(function(rewardTable, ...)
        mutationCount = mutationCount + 1
        local rewardName = "Brainrot"
        local mutationType = "Normal"
        pcall(function()
            if type(rewardTable) == "table" and rewardTable[1] then
                rewardName = tostring(rewardTable[1].Name or "Brainrot")
                mutationType = tostring(rewardTable[1].Mutation or "Normal")
            end
        end)
        pcall(function()
            RewardLabel.Text = string.format("Brainrot: %s (%s) | %d", rewardName, mutationType, mutationCount)
        end)
        updateStatus(string.format("🎉 Didapat: %s [%s]!", rewardName, mutationType), Color3.fromRGB(100, 240, 120))
    end)
end

if rev_KickData then
    rev_KickData.OnClientEvent:Connect(function(powerVal, distVal)
        updateStatus(string.format("🚀 Bola Melayang (%sm)", tostring(distVal)), Color3.fromRGB(255, 200, 80))
    end)
end

if rev_AddedWeather then
    rev_AddedWeather.OnClientEvent:Connect(function(weatherType, ...)
        if weatherType == "MeteorShower" then
            isMeteorShowerActive = true
            updateStatus("☄️ Meteor Shower Dimulai! Scanning Aktif...", Color3.fromRGB(255, 170, 50))
            logDebug("Weather: MeteorShower Aktif!")
        end
    end)
end

if rev_RemovedWeather then
    rev_RemovedWeather.OnClientEvent:Connect(function(weatherType, ...)
        if weatherType == "MeteorShower" then
            isMeteorShowerActive = false
            updateStatus("☁️ Meteor Shower Selesai. Standby...", Color3.fromRGB(180, 190, 210))
            logDebug("Weather: Selesai")
        end
    end)
end

-- =============================================
-- 💥 ULTIMATE COMBO METEOR ENGINE (KHUSUS DEBRIS + ANGKA)
-- =============================================

-- Mendeteksi HANYA model di dalam workspace.Debris yang namanya berupa angka (1, 2, 3, dst.)
local function isTargetModel(model)
    if not model or not model:IsA("Model") then return false end
    local debris = workspace:FindFirstChild("Debris")
    if not debris or not model:IsDescendantOf(debris) then return false end
    return tonumber(model.Name) ~= nil
end

local function getTargetModelParent(instance)
    if not instance then return nil end
    local debris = workspace:FindFirstChild("Debris")
    if not debris or not instance:IsDescendantOf(debris) then return nil end

    local curr = instance
    while curr and curr ~= debris and curr ~= workspace do
        if curr:IsA("Model") and tonumber(curr.Name) ~= nil then
            return curr
        end
        curr = curr.Parent
    end
    return nil
end

-- 1. Multi-Limb Touch Simulator
local function triggerMultiTouch(part)
    if not part or not firetouchinterest then return end
    local char = lp and lp.Character
    if not char then return end

    local limbs = {
        char:FindFirstChild("HumanoidRootPart"),
        char:FindFirstChild("Right Leg"),
        char:FindFirstChild("Left Leg"),
        char:FindFirstChild("RightFoot"),
        char:FindFirstChild("LeftFoot"),
        char:FindFirstChild("RightLowerLeg"),
        char:FindFirstChild("LeftLowerLeg"),
        char:FindFirstChild("Torso"),
        char:FindFirstChild("UpperTorso"),
        char:FindFirstChild("LowerTorso"),
    }

    for _, limb in ipairs(limbs) do
        if limb then
            pcall(function()
                firetouchinterest(limb, part, 0)
                firetouchinterest(limb, part, 1)
            end)
        end
    end
end

-- 2. Enlarge & Magnet Part
local function processMeteorPart(part, targetCFrame)
    if not part or not (part:IsA("BasePart") or part.ClassName == "Part") then return end
    
    pcall(function()
        part.CanCollide = false
        part.CastShadow = false
        if part.Size ~= MAX_SIZE then
            part.Size = MAX_SIZE
        end
        if targetCFrame then
            part.CFrame = targetCFrame
        end
    end)
    
    triggerMultiTouch(part)
end

-- 3. Flash-Touch Snap (Micro 0.08s touch di titik server asli)
local function performFlashTouch(targetPart)
    if isSnapping or not targetPart then return end
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    isSnapping = true
    local originalCFrame = hrp.CFrame
    local meteorPos = targetPart.CFrame

    pcall(function()
        hrp.CFrame = meteorPos + Vector3.new(0, 1, 0)
        triggerMultiTouch(targetPart)
    end)

    task.wait(0.08)

    pcall(function()
        if hrp and hum.Health > 0 then
            hrp.CFrame = originalCFrame
        end
    end)

    isSnapping = false
end

-- 4. Registrasi & Eksekusi Combo Meteor
local function handleNewMeteor(model)
    if not model or not isTargetModel(model) then return end
    if activeMeteors[model] then return end
    activeMeteors[model] = true

    logDebug(string.format("Ditemukan Meteor Model #%s!", tostring(model.Name)))

    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local targetPart = model:FindFirstChild("RootPart") 
        or model:FindFirstChild("Main") 
        or model:FindFirstChild("VFX")
        or model:FindFirstChildOfClass("BasePart")
        or model.PrimaryPart

    -- Combo A: Perbesar seluruh part + Magnet ke Karakter
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant.ClassName == "Part" then
            processMeteorPart(descendant, hrp and hrp.CFrame)
        end
    end

    -- Combo B: Flash micro-touch jika target part valid
    if targetPart then
        task.defer(function()
            performFlashTouch(targetPart)
        end)
    end

    if not processedRoots[model] then
        processedRoots[model] = true
        meteorClaimCount = meteorClaimCount + 1
        pcall(function()
            MeteorLabel.Text = string.format("☄️ Meteor Diklaim: %d", meteorClaimCount)
        end)
        updateStatus(string.format("💥 Combo Claim Meteor #%s!", tostring(model.Name)), Color3.fromRGB(100, 240, 120))
    end
end

-- 5. Real-Time Heartbeat Loop: Mempertahankan Magnet & Touch berkala
RunService.Heartbeat:Connect(function()
    if not _G.autoMeteor then return end
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local currentCFrame = hrp.CFrame
    local debris = workspace:FindFirstChild("Debris")
    if not debris then return end

    for model, _ in pairs(activeMeteors) do
        if model and model.Parent and model:IsDescendantOf(debris) then
            for _, descendant in ipairs(model:GetDescendants()) do
                if descendant:IsA("BasePart") or descendant.ClassName == "Part" then
                    processMeteorPart(descendant, currentCFrame)
                end
            end
        else
            activeMeteors[model] = nil
        end
    end
end)

-- 6. Setup Listener Eksklusif pada workspace.Debris
local function setupDebrisListeners(debris)
    if not debris then return end
    logDebug("Debris Listener AKTIF di: " .. debris:GetFullName())

    -- Scan semua objek yang sudah ada di Debris saat ini
    local count = 0
    for _, item in ipairs(debris:GetDescendants()) do
        if isTargetModel(item) then
            count = count + 1
            handleNewMeteor(item)
        end
    end
    if count > 0 then
        logDebug(string.format("Menemukan %d model meteor aktif di Debris", count))
    end

    -- Listener instan saat descendant baru masuk ke Debris
    debris.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            if isTargetModel(descendant) then
                handleNewMeteor(descendant)
            elseif descendant:IsA("BasePart") or descendant.ClassName == "Part" then
                local targetModel = getTargetModelParent(descendant)
                if targetModel then
                    local char = lp and lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    processMeteorPart(descendant, hrp and hrp.CFrame)
                    handleNewMeteor(targetModel)
                end
            end
        end)
    end)

    -- Cleanup table saat objek dihapus dari Debris
    debris.DescendantRemoving:Connect(function(descendant)
        activeMeteors[descendant] = nil
        processedRoots[descendant] = nil
    end)
end

-- Setup Debris Loop (Non-blocking)
task.spawn(function()
    local debris = workspace:FindFirstChild("Debris")
    if not debris then
        logDebug("Menunggu folder workspace.Debris...")
        debris = workspace:WaitForChild("Debris", 10)
    end
    if debris then
        setupDebrisListeners(debris)
    else
        logDebug("PERINGATAN: Folder Debris tidak ditemukan setelah 10s")
    end
end)

-- Listener jika folder Debris dibuat ulang di kemudian hari
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Debris" then
        logDebug("Folder Debris baru terdeteksi!")
        task.defer(function()
            setupDebrisListeners(child)
        end)
    end
end)

-- 7. Background Sweeper Rutin (Memeriksa workspace.Debris setiap 0.2 detik)
task.spawn(function()
    while task.wait(0.2) do
        if not _G.autoMeteor then continue end
        local debris = workspace:FindFirstChild("Debris")
        if debris then
            for _, item in ipairs(debris:GetDescendants()) do
                if isTargetModel(item) and not activeMeteors[item] then
                    handleNewMeteor(item)
                end
            end
        end
    end
end)

print("--------------------------------------------------")
print("☄️ [SUKSES] KALB Auto Meteor Claimer Siap Digunakan!")
print("--------------------------------------------------")
