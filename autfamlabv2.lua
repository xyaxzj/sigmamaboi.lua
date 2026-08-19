-- ==============================================================================
-- ☄️ KALB AUTO METEOR CLAIMER (OPTIMAL RAYCAST HITBOX EXPANDER - 100% SAH)
-- ==============================================================================
-- Fitur:
-- 1. 🎯 Deteksi Meteor: Khusus Model Bernomor (1, 2, 3...) di folder workspace.Debris
-- 2. ⚡ Optimal Raycast Hitbox (80x80x80): Memperbesar hitbox meteor di lokasi aslinya
--    dengan CanQuery = true agar Raycast bawaan game (CheckForHit) 100% menabrak meteor saat bola melayang!
-- 3. 🛡️ Anti-Rollback & Zero Desync: Tidak memindahkan CFrame meteor sembarangan sehingga
--    game engine memproses urutan t (trajectory) secara natural dan valid di server.
-- 4. 📊 Floating HUD Real-Time: Memantau event cuaca, klaim meteor, & reward server mutasi.
-- ==============================================================================

print("--------------------------------------------------")
print("☄️ [INIT] Memuat KALB Auto Meteor Hitbox Expander...")

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

-- =============================================
-- ⚙️ KONFIGURASI 
-- =============================================
_G.autoMeteor = true
local meteorCount = 0
local isMeteorShowerActive = false

-- Ukuran hitbox optimal untuk Raycast (80x80x80 studs).
-- JANGAN 2048 karena raycast yang mulai di dalam part 2048 akan tembus/miss!
local OPTIMAL_HITBOX_SIZE = Vector3.new(200, 200, 200)

local activeMeteors = {}
local processedRoots = {}

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
StatusLabel.Text = "Status: Standby Menunggu Meteor..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local MeteorLabel = Instance.new("TextLabel")
MeteorLabel.Size = UDim2.new(1, -10, 0, 20)
MeteorLabel.Position = UDim2.new(0, 8, 0, 50)
MeteorLabel.BackgroundTransparency = 1
MeteorLabel.Font = Enum.Font.GothamBold
MeteorLabel.Text = "☄️ Meteor Siap Tabrak: 0"
MeteorLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
MeteorLabel.TextSize = 11
MeteorLabel.TextXAlignment = Enum.TextXAlignment.Left
MeteorLabel.Parent = StatusFrame

local RewardLabel = Instance.new("TextLabel")
RewardLabel.Size = UDim2.new(1, -10, 0, 20)
RewardLabel.Position = UDim2.new(0, 8, 0, 72)
RewardLabel.BackgroundTransparency = 1
RewardLabel.Font = Enum.Font.GothamBold
RewardLabel.Text = "Server Reward: None | Total: 0"
RewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
RewardLabel.TextSize = 11
RewardLabel.TextXAlignment = Enum.TextXAlignment.Left
RewardLabel.Parent = StatusFrame

local DebugLabel = Instance.new("TextLabel")
DebugLabel.Size = UDim2.new(1, -10, 0, 20)
DebugLabel.Position = UDim2.new(0, 8, 0, 96)
DebugLabel.BackgroundTransparency = 1
DebugLabel.Font = Enum.Font.Code
DebugLabel.Text = "Mode: Raycast Hitbox Expander (80 studs)"
DebugLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
DebugLabel.TextSize = 10
DebugLabel.TextXAlignment = Enum.TextXAlignment.Left
DebugLabel.Parent = StatusFrame

pcall(function()
    ScreenGui.Parent = targetGuiParent or lp:WaitForChild("PlayerGui", 5)
end)

local function updateStatus(text, color)
    pcall(function()
        StatusLabel.Text = "Status: " .. tostring(text)
        if color then StatusLabel.TextColor3 = color end
    end)
end

-- =============================================
-- 📡 DAFTAR REMOTE NETWORK RESMI
-- =============================================
local networkFolder = nil
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
    local packages = shared and (shared:FindFirstChild("Packages") or shared:WaitForChild("Packages", 3))
    networkFolder = packages and (packages:FindFirstChild("Network") or packages:WaitForChild("Network", 3))
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
            RewardLabel.Text = string.format("🎉 %s (%s) | Total: %d", rewardName, mutationType, mutationCount)
        end)
        updateStatus(string.format("✅ Server Klaim Sah: %s [%s]!", rewardName, mutationType), Color3.fromRGB(100, 255, 120))
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
            updateStatus("☄️ Meteor Shower Aktif! Ayo Tendang Bola...", Color3.fromRGB(255, 170, 50))
        end
    end)
end

if rev_RemovedWeather then
    rev_RemovedWeather.OnClientEvent:Connect(function(weatherType, ...)
        if weatherType == "MeteorShower" then
            isMeteorShowerActive = false
            updateStatus("☁️ Meteor Shower Selesai. Standby...", Color3.fromRGB(180, 190, 210))
        end
    end)
end

-- =============================================
-- 🎯 DETEKTOR MODEL METEOR (DEBRIS + ANGKA)
-- =============================================
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

-- =============================================
-- 💥 OPTIMAL RAYCAST HITBOX EXPANDER (DI POSISI ASLI)
-- =============================================
-- Memperbesar hitbox meteor di koordinat aslinya agar Raycast CheckForHit 100% menabrak meteor saat bola lewat
local function expandMeteorHitbox(part)
    if not part or not (part:IsA("BasePart") or part.ClassName == "Part") then return end
    
    pcall(function()
        part.CanCollide = false
        part.CanTouch = true
        part.CanQuery = true -- SANGAT PENTING: Wajib true agar workspace:Raycast() mengenai part ini!
        part.CastShadow = false
        
        -- Perbesar part ke ukuran optimal (80x80x80) tanpa mengubah CFrame posisinya
        if part.Size ~= OPTIMAL_HITBOX_SIZE then
            part.Size = OPTIMAL_HITBOX_SIZE
        end
    end)
end

local function handleNewMeteor(model)
    if not model or not isTargetModel(model) then return end
    if activeMeteors[model] then return end
    activeMeteors[model] = true

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant.ClassName == "Part" then
            expandMeteorHitbox(descendant)
        end
    end

    if not processedRoots[model] then
        processedRoots[model] = true
        meteorCount = meteorCount + 1
        pcall(function()
            MeteorLabel.Text = string.format("☄️ Meteor Siap Tabrak: %d", meteorCount)
        end)
        print(string.format("☄️ [METEOR EXPAND] Hitbox Meteor #%s diperbesar ke 80 studs (CanQuery = true)", tostring(model.Name)))
    end
end

-- =============================================
-- 🔍 LISTENER DEBRIS
-- =============================================
local function setupDebrisListeners(debris)
    if not debris then return end

    for _, item in ipairs(debris:GetDescendants()) do
        if isTargetModel(item) then
            handleNewMeteor(item)
        end
    end

    debris.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            if isTargetModel(descendant) then
                handleNewMeteor(descendant)
            elseif descendant:IsA("BasePart") or descendant.ClassName == "Part" then
                local targetModel = getTargetModelParent(descendant)
                if targetModel then
                    expandMeteorHitbox(descendant)
                    handleNewMeteor(targetModel)
                end
            end
        end)
    end)

    debris.DescendantRemoving:Connect(function(descendant)
        activeMeteors[descendant] = nil
        processedRoots[descendant] = nil
    end)
end

task.spawn(function()
    local debris = workspace:FindFirstChild("Debris") or workspace:WaitForChild("Debris", 10)
    if debris then
        setupDebrisListeners(debris)
    end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Debris" then
        task.defer(function()
            setupDebrisListeners(child)
        end)
    end
end)

-- Background Sweeper Loop (Memastikan semua part meteor tetap berukuran 80x80x80 dan CanQuery = true)
task.spawn(function()
    while task.wait(0.2) do
        if not _G.autoMeteor then continue end
        local debris = workspace:FindFirstChild("Debris")
        if debris then
            for _, item in ipairs(debris:GetDescendants()) do
                if isTargetModel(item) then
                    if not activeMeteors[item] then
                        handleNewMeteor(item)
                    end
                    for _, part in ipairs(item:GetDescendants()) do
                        if (part:IsA("BasePart") or part.ClassName == "Part") and (part.Size ~= OPTIMAL_HITBOX_SIZE or not part.CanQuery) then
                            expandMeteorHitbox(part)
                        end
                    end
                end
            end
        end
    end
end)

print("--------------------------------------------------")
print("☄️ [SUKSES] KALB Auto Meteor Hitbox Expander Siap Digunakan!")
print("--------------------------------------------------")
