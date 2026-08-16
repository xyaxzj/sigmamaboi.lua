-- ==============================================================================
-- ☄️ KALB AUTO METEOR CLAIMER, ANTI-LAG & ANTI-AFK
-- ==============================================================================
-- Fitur:
-- 1. ☄️ Auto Meteor Claimer (Aktif otomatis saat cuaca MeteorShower, klaim via firetouchinterest)
-- 2. 🥔 Anti-Lag Ekstrem & Potato Map (Plastic, White, No Shadows, Plot & Player Removed)
-- 3. 🛡️ Anti-AFK (Mencegah disconnect 20 menit)
-- 4. 💰 Auto Sell All (Setiap 5 detik via remote ref_B_SellAll)
-- 5. 📊 Floating Status HUD Real-Time (Brainrot Counter, Meteor Counter, Jarak Bola)
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
local meteorClaimCount = 0
local isMeteorShowerActive = false

-- =============================================
-- 🚀 SYSTEM ANTI-LAG & OPTIMISASI (BAC SAFE)
-- =============================================
-- 1. Ubah Map Jadi Potato (Putih & SmoothPlastic)
for _, v in ipairs(workspace:GetDescendants()) do
    if not (lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character))) then
        pcall(function()
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
                v.Color = Color3.new(1, 1, 1)
                if v:IsA("MeshPart") then v.TextureID = "" end
            elseif v:IsA("SpecialMesh") then
                v.TextureId = ""
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end)
    end
end

-- =============================================
-- 🎯 DETEKTOR PLOT SENDIRI & REMOVER PLOT LAIN
-- =============================================
local lpName = lp.Name
local lpDisplayName = lp.DisplayName
local myUidStr = tostring(lp.UserId)

local function isMyPlot(plotModel)
    if not plotModel or not plotModel:IsA("Model") then return false end

    -- 1. Cek via PlotSign
    local sign = plotModel:FindFirstChild("PlotSign", true)
    if sign then
        local pps = sign:FindFirstChild("PlayerPlotSign", true)
        if pps then
            local nameLabel = pps:FindFirstChild("PlayerName", true)
            if nameLabel and nameLabel:IsA("TextLabel") then
                local t = nameLabel.Text
                if t and (t == lpName or t:find(lpName, 1, true) or (lpDisplayName and (t == lpDisplayName or t:find(lpDisplayName, 1, true)))) then
                    return true
                end
            end
            local icon = pps:FindFirstChild("PlayerIcon", true)
            if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
                local img = icon.Image
                if img and img:find(myUidStr, 1, true) then
                    return true
                end
            end
        end
    end

    -- 2. Fallback scan value di descendant
    for _, item in ipairs(plotModel:GetDescendants()) do
        local ok, result = pcall(function()
            if item:IsA("TextLabel") then
                local t = item.Text
                if t and (t == lpName or (lpDisplayName and t == lpDisplayName)) then
                    return true
                end
            elseif item:IsA("StringValue") or item:IsA("ObjectValue") or item:IsA("IntValue") or item:IsA("NumberValue") then
                local v = item.Value
                if v == lpName or v == lp or tostring(v) == myUidStr then
                    return true
                end
            end
            return false
        end)
        if ok and result then return true end
    end

    return false
end

-- 2. Hapus Plot Player Lain
local plotsFolder = workspace:FindFirstChild("Plots")
if plotsFolder then
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") and not isMyPlot(plot) then
            pcall(function() plot:Destroy() end)
        end
    end
    plotsFolder.ChildAdded:Connect(function(plot)
        task.wait(0.2)
        if plot:IsA("Model") and not isMyPlot(plot) then
            pcall(function() plot:Destroy() end)
        end
    end)
end

-- 3. Hapus Total Player Lain & Data-Datanya (Character, Leaderstats, Instance)
local function purgePlayerTotal(player)
    if player and player ~= lp then
        pcall(function()
            if player.Character then
                player.Character:ClearAllChildren()
                player.Character:Destroy()
            end
        end)
        pcall(function()
            player:ClearAllChildren()
            player:Destroy()
        end)
    end
end

for _, player in ipairs(Players:GetPlayers()) do purgePlayerTotal(player) end
Players.PlayerAdded:Connect(function(player)
    if player ~= lp then
        task.defer(function()
            purgePlayerTotal(player)
        end)
        player.CharacterAdded:Connect(function(char)
            task.defer(function()
                pcall(function()
                    char:ClearAllChildren()
                    char:Destroy()
                end)
            end)
        end)
    end
end)

-- =============================================
-- 🛡️ ANTI AFK (KLASIK VIRTUALUSER)
-- =============================================
lp.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)
-- 📡 CARI REMOTE NETWORK
-- =============================================
local networkFolder = ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
local rev_kickPhase2 = networkFolder and networkFolder:WaitForChild("rev_kickPhase2", 15)
local rev_KickData = networkFolder and networkFolder:WaitForChild("rev_KickData", 15)
local rev_AddedWeather = networkFolder and networkFolder:WaitForChild("rev_AddedWeather", 15)
local rev_RemovedWeather = networkFolder and networkFolder:WaitForChild("rev_RemovedWeather", 15)
local ref_B_SellAll = networkFolder and (networkFolder:FindFirstChild("ref_B_SellAll") or networkFolder:WaitForChild("ref_B_SellAll", 5))

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
StatusFrame.Size = UDim2.new(0, 260, 0, 110)
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
Stroke.Color = Color3.fromRGB(255, 160, 40)
Stroke.Thickness = 1.2
Stroke.Parent = StatusFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 22)
Title.Position = UDim2.new(0, 8, 0, 4)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "☄️ KALB METEOR CLAIMER"
Title.TextColor3 = Color3.fromRGB(255, 180, 50)
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = StatusFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 20)
StatusLabel.Position = UDim2.new(0, 8, 0, 28)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Text = "Status: Menunggu Meteor Shower..."
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

local function updateStatus(text, color)
    StatusLabel.Text = "Status: " .. tostring(text)
    if color then StatusLabel.TextColor3 = color end
end

-- =============================================
-- 📡 DAFTAR EVENT LISTENER
-- =============================================
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
        
        RewardLabel.Text = string.format("Brainrot: %s (%s) | %d", rewardName, mutationType, _G.mutationCount)
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
-- ☄️ AUTO METEOR EVENT CLAIMER (KHUSUS WORKSPACE.DEBRIS)
-- =============================================
local MAX_SIZE = Vector3.new(2048, 2048, 2048) -- Ukuran part maksimal engine Roblox
local processedObjects = {}

local function enlargePart(part)
    if not part or not part:IsA("BasePart") then return end
    pcall(function()
        part.Size = MAX_SIZE
        part.CanCollide = false
    end)
end

local function processDebrisItem(obj)
    if not obj then return end
    if processedObjects[obj] then return end
    processedObjects[obj] = true

    if obj:IsA("Model") then
        -- Perbesar semua part di dalam model meteor di Debris (Main, RootPart, VFX, dll)
        for _, descendant in ipairs(obj:GetDescendants()) do
            if descendant:IsA("BasePart") then
                enlargePart(descendant)
            end
        end
        meteorClaimCount = meteorClaimCount + 1
        MeteorLabel.Text = string.format("☄️ Meteor Diklaim: %d", meteorClaimCount)
        updateStatus(string.format("☄️ Enlarge Debris Model #%s!", tostring(obj.Name)), Color3.fromRGB(255, 170, 50))
    elseif obj:IsA("BasePart") then
        -- Standalone Part di dalam Debris seperti HitMeteor
        enlargePart(obj)
        meteorClaimCount = meteorClaimCount + 1
        MeteorLabel.Text = string.format("☄️ Meteor Diklaim: %d", meteorClaimCount)
        updateStatus(string.format("☄️ Enlarge Debris Part: %s!", tostring(obj.Name)), Color3.fromRGB(255, 170, 50))
    end
end

-- 1. Scan & Listener Eksklusif di workspace.Debris
pcall(function()
    local debris = workspace:WaitForChild("Debris", 10)
    if debris then
        -- Proses item yang sudah ada di Debris
        for _, child in ipairs(debris:GetChildren()) do
            processDebrisItem(child)
        end

        -- Listener untuk objek baru yang masuk ke Debris
        debris.ChildAdded:Connect(function(child)
            task.defer(function()
                task.wait(0.02)
                processDebrisItem(child)
                -- Jika child adalah model, listen juga jika ada sub-part baru masuk
                if child:IsA("Model") then
                    for _, sub in ipairs(child:GetDescendants()) do
                        if sub:IsA("BasePart") then enlargePart(sub) end
                    end
                    child.DescendantAdded:Connect(function(sub)
                        if sub:IsA("BasePart") then enlargePart(sub) end
                    end)
                end
            end)
        end)

        debris.ChildRemoved:Connect(function(child)
            processedObjects[child] = nil
        end)
    end
end)

-- 2. Background Sweeper Rutin (Hanya memeriksa workspace.Debris)
task.spawn(function()
    while task.wait(0.2) do
        if not _G.autoFarm then continue end
        local debris = workspace:FindFirstChild("Debris")
        if debris then
            for _, child in ipairs(debris:GetChildren()) do
                processDebrisItem(child)
            end
        end
    end
end)

-- =============================================
-- 💰 AUTO SELL ALL (SETIAP 5 DETIK)
-- =============================================
task.spawn(function()
    while task.wait(5) do
        if not _G.autoFarm then continue end
        pcall(function()
            if ref_B_SellAll then
                ref_B_SellAll:InvokeServer()
            else
                local net = ReplicatedStorage:FindFirstChild("Shared")
                net = net and net:FindFirstChild("Packages")
                net = net and net:FindFirstChild("Network")
                local sellRemote = net and net:FindFirstChild("ref_B_SellAll")
                if sellRemote then
                    sellRemote:InvokeServer()
                end
            end
        end)
    end
end)
