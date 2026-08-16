-- ==============================================================================
-- ☄️ KALB AUTO METEOR CLAIMER & ANTI-LAG (MANUAL AUTO KICK MODE)
-- ==============================================================================
-- Fitur:
-- 1. ☄️ Auto Meteor Claimer (Real-time firetouchinterest saat bola di udara)
-- 2. 🥔 Anti-Lag Ekstrem & Potato Map (Plastic, White, No Shadows, Plot & Player Removed)
-- 3. 🛡️ Anti-AFK
-- 4. ⚡ Auto Interupsi Event Cuaca Luck Machine (Barbell Training x8 Luck)
-- 5. 📊 Floating Status HUD Real-Time (Brainrot Counter, Meteor Counter, Jarak Bola)
-- 
-- * Catatan: Fitur Auto Kick dikendalikan manual oleh Anda langsung di tombol game!
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
local safeZoneCFrame = CFrame.new(698.030701, 3.298559, 233.707077, -0.061024, -0.000000, 0.998136, -0.000000, 1.000000, 0.000000, -0.998136, -0.000000, -0.061024)

-- =============================================
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
-- 🚀 INISIALISASI AWAL (TELEPORT + JEDA 5 DETIK + KLIK AUTOBUTTON 1X)
-- =============================================
task.spawn(function()
    -- 1. Teleport ke Safe Zone saat script dieksekusi
    updateStatus("📍 Teleport ke Safe Zone...", Color3.fromRGB(100, 200, 255))
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    if hrp then
        hrp.CFrame = safeZoneCFrame
    end

    -- 2. Jeda Waktu 5 Detik Sebelum Klik
    for i = 5, 1, -1 do
        updateStatus(string.format("⏳ Menunggu %d detik sebelum klik Auto Kick...", i), Color3.fromRGB(255, 200, 80))
        task.wait(1.0)
    end

    -- 3. Cari AutoButton di PlayerGui.HUD.AutoKickFrame
    pcall(function()
        local playerGui = lp:WaitForChild("PlayerGui", 10)
        local hud = playerGui and playerGui:WaitForChild("HUD", 10)
        local autoKickFrame = hud and (hud:FindFirstChild("AutoKickFrame", true) or hud:FindFirstChild("AutoKick", true))
        local autoBtn = autoKickFrame and (autoKickFrame:FindFirstChild("AutoButton", true) or autoKickFrame:FindFirstChildOfClass("ImageButton") or autoKickFrame:FindFirstChildOfClass("GuiButton"))
        
        -- Fallback pencarian berbasis Image Asset atau Text Label "AUTO KICK"
        if not autoBtn and hud then
            for _, v in ipairs(hud:GetDescendants()) do
                if v:IsA("ImageButton") and (v.Name == "AutoButton" or tostring(v.Image):find("136607941521284")) then
                    autoBtn = v
                    break
                elseif v:IsA("TextLabel") and v.Text:upper():find("AUTO KICK") then
                    local p = v.Parent
                    autoBtn = p and (p:FindFirstChildOfClass("ImageButton") or p:FindFirstChildOfClass("GuiButton"))
                    if autoBtn then break end
                end
            end
        end

        -- 4. Eksekusi Aktivasi Auto Kick (getconnections + firesignal + VirtualInput + Remote)
        if autoBtn and autoBtn:IsA("GuiButton") then
            local pos = autoBtn.AbsolutePosition + (autoBtn.AbsoluteSize / 2)
            
            -- 1. getconnections (Memicu langsung listener script game asli di executor)
            if getconnections then
                pcall(function()
                    for _, conn in ipairs(getconnections(autoBtn.Activated)) do
                        if conn.Function then conn.Function() elseif conn.Fire then conn:Fire() end
                    end
                    for _, conn in ipairs(getconnections(autoBtn.MouseButton1Click)) do
                        if conn.Function then conn.Function() elseif conn.Fire then conn:Fire() end
                    end
                    for _, conn in ipairs(getconnections(autoBtn.MouseButton1Down)) do
                        if conn.Function then conn.Function() elseif conn.Fire then conn:Fire() end
                    end
                end)
            end
            
            -- 2. firesignal (Fallback Event)
            if firesignal then
                pcall(function() firesignal(autoBtn.Activated) end)
                pcall(function() firesignal(autoBtn.MouseButton1Click) end)
                pcall(function() firesignal(autoBtn.MouseButton1Down) end)
                pcall(function() firesignal(autoBtn.MouseButton1Up) end)
            end
            
            -- 3. Virtual Input Manager (Simulasi Layar Sentuh & Mouse)
            local vim = nil
            pcall(function() vim = game:GetService("VirtualInputManager") end)
            if vim then
                pcall(function()
                    vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                    task.wait(0.05)
                    vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                    vim:SendTouchEvent(0, 0, pos.X, pos.Y)
                    task.wait(0.05)
                    vim:SendTouchEvent(0, 2, pos.X, pos.Y)
                end)
            else
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(pos)
                end)
            end

            -- 4. Remote Server Request (Memastikan Server Mengaktifkan Auto Kick)
            pcall(function()
                local ref_Auto = networkFolder and (networkFolder:FindFirstChild("ref_AutoRequest") or networkFolder:WaitForChild("ref_AutoRequest", 2))
                if ref_Auto then
                    ref_Auto:InvokeServer(true)
                end
            end)
            
            updateStatus("✅ Auto Kick Berhasil Diaktifkan!", Color3.fromRGB(100, 240, 120))
        else
            -- Backup langsung lewat remote jika objek GUI belum siap
            pcall(function()
                local ref_Auto = networkFolder and (networkFolder:FindFirstChild("ref_AutoRequest") or networkFolder:WaitForChild("ref_AutoRequest", 2))
                if ref_Auto then
                    ref_Auto:InvokeServer(true)
                end
            end)
            updateStatus("✅ Auto Kick Diaktifkan via Server!", Color3.fromRGB(100, 240, 120))
        end
    end)
end)

-- =============================================
-- 📡 DAFTAR EVENT LISTENER
-- =============================================
local isMeteorShowerActive = false

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
-- ☄️ AUTO METEOR EVENT CLAIMER (WORKSPACE.DEBRIS)
-- =============================================
local function claimMeteorModel(model)
    if not model or not model:IsA("Model") then return end
    
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Ambil semua part fisik di dalam model meteor
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            -- 1. Simulasi Sentuhan Fisik (Touch Interest)
            if firetouchinterest then
                pcall(function()
                    firetouchinterest(hrp, part, 0)
                    task.wait(0.01)
                    firetouchinterest(hrp, part, 1)
                end)
            end
            
            -- 2. Cek jika part memiliki ProximityPrompt
            pcall(function()
                local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                if prompt and fireproximityprompt then
                    fireproximityprompt(prompt)
                end
            end)
        end
    end
end

-- Listener Real-Time: Saat Meteor Baru Muncul di Debris (Hanya saat MeteorShower Aktif)
pcall(function()
    local debris = workspace:WaitForChild("Debris", 10)
    if debris then
        debris.ChildAdded:Connect(function(child)
            if not isMeteorShowerActive then return end
            task.defer(function()
                if child:IsA("Model") and (tonumber(child.Name) or child.Name:lower():find("meteor")) then
                    task.wait(0.05)
                    claimMeteorModel(child)
                    meteorClaimCount = meteorClaimCount + 1
                    MeteorLabel.Text = string.format("☄️ Meteor Diklaim: %d", meteorClaimCount)
                    updateStatus(string.format("☄️ Hit Meteor #%s!", tostring(child.Name)), Color3.fromRGB(255, 170, 50))
                end
            end)
        end)
    end
end)

-- Background Sweeper: Memastikan Tidak Ada Meteor yang Terlewat (Hanya saat MeteorShower Aktif)
task.spawn(function()
    while task.wait(0.2) do
        if not isMeteorShowerActive or not _G.autoFarm then continue end
        local debris = workspace:FindFirstChild("Debris")
        if debris then
            for _, child in ipairs(debris:GetChildren()) do
                if child:IsA("Model") and (tonumber(child.Name) or child.Name:lower():find("meteor")) then
                    claimMeteorModel(child)
                end
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
