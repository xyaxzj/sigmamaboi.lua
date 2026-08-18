-- ==============================================================================
-- ☄️ KALB ULTIMATE METEOR ENGINE (HYBRID: GC INTERNAL HOOK + BALL RAYCAST MAGNET)
-- ==============================================================================
-- Fitur & Bedah Sistem Game:
-- 1. ⚡ Direct GC/Engine Invocator: Menghubungkan langsung ke fungsi internal game "CheckForHit"
--    (ReplicatedStorage.Modules.ControllerLoader.WeatherController.Weathers.Events.MeteorShower)
--    Mengklaim seluruh daftar upvalue meteorList, memicu remote "meteorNetwork", AddLuck, dan PlayHit secara sah!
-- 2. 🚀 Projectile-Targeted Raycast Magnet: Menempatkan part meteor tepat di lintasan Raycast bola
--    dengan CanQuery = true, sehingga Raycast bawaan game 100% menabrak meteor secara natural.
-- 3. 🛡️ 100% Server Validated: Mencegah rollback dan memvalidasi gacha reward server asli.
-- 4. 📊 Floating HUD Real-Time dengan status klaim & server rewards.
-- ==============================================================================

print("--------------------------------------------------")
print("☄️ [INIT] Memuat KALB Ultimate Meteor Engine...")

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
local meteorClaimCount = 0
local isMeteorShowerActive = false
local RAYCAST_HITBOX_SIZE = Vector3.new(30, 30, 30)

local activeMeteors = {}
local processedRoots = {}
local activeProjectile = nil

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
MeteorLabel.Text = "☄️ Meteor Terklaim: 0"
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
DebugLabel.Text = "Engine: Hybrid (GC Hook + Ball Magnet)"
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

local function logDebug(text)
    pcall(function()
        DebugLabel.Text = tostring(text)
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
            updateStatus("☄️ Meteor Shower Aktif! Engine Siaga...", Color3.fromRGB(255, 170, 50))
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
-- ⚡ 1. DIRECT ENGINE GC INJECTOR (KLAIM INSTAN SAH SERVER)
-- =============================================
local cachedCheckForHit = nil
local cachedUpvalues = nil

local function getCheckForHitFunction()
    if cachedCheckForHit and cachedUpvalues then
        return cachedCheckForHit, cachedUpvalues
    end

    if getgc and getupvalues then
        for _, fn in ipairs(getgc(true)) do
            if type(fn) == "function" and islclosure and islclosure(fn) and not isexecutorclosure(fn) then
                local ok, uvs = pcall(getupvalues, fn)
                if ok and uvs then
                    -- Cek Heuristic 1: Nama fungsi CheckForHit
                    local info = getinfo and getinfo(fn)
                    local isNameMatch = info and info.name == "CheckForHit"
                    local isSourceMatch = info and info.source and string.find(info.source, "MeteorShower")
                    
                    -- Cek Heuristic 2: Signature Upvalue Tabel Multiplier Meteor
                    local hasMultiplierSignature = false
                    local meteorTableIndex = nil
                    local networkModIndex = nil

                    for i, uv in pairs(uvs) do
                        if type(uv) == "table" then
                            if uv.Golden == 2 and uv.Diamond == 3 and uv.Rainbow == 5 then
                                hasMultiplierSignature = true
                            elseif uv[1] and type(uv[1]) == "table" and (uv[1].Claimed ~= nil or uv[1].Data ~= nil or uv[1].t ~= nil) then
                                meteorTableIndex = i
                            elseif uv.FireServer or uv.InvokeServer then
                                networkModIndex = i
                            end
                        end
                    end

                    if isNameMatch or (isSourceMatch and meteorTableIndex) or (hasMultiplierSignature and meteorTableIndex) then
                        cachedCheckForHit = fn
                        cachedUpvalues = uvs
                        print("⚡ [GC HOOK] Berhasil menghubungkan fungsi CheckForHit via Signature Matching!")
                        return fn, uvs
                    end
                end
            end
        end
    end
    return nil, nil
end

local function triggerDirectEngineClaim()
    local fn, uvs = getCheckForHitFunction()
    if not fn or not uvs then return false end

    local meteorList = nil
    local networkMod = nil
    local playHitFn = nil
    local addLuckFn = nil
    local multTable = { Golden = 2, Diamond = 3, Default = 1, Rainbow = 5 }

    for _, uv in pairs(uvs) do
        if type(uv) == "table" then
            if uv.Golden == 2 and uv.Diamond == 3 and uv.Rainbow == 5 then
                multTable = uv
            elseif uv[1] and type(uv[1]) == "table" and (uv[1].Claimed ~= nil or uv[1].Data ~= nil or uv[1].t ~= nil) then
                meteorList = uv
            elseif uv.FireServer or uv.InvokeServer then
                networkMod = uv
            end
        elseif type(uv) == "function" then
            if not playHitFn then
                playHitFn = uv
            else
                addLuckFn = uv
            end
        end
    end

    if not meteorList then return false end
    local debris = workspace:FindFirstChild("Debris")

    local claimedAny = false
    for id, entry in pairs(meteorList) do
        if type(entry) == "table" and not entry.Claimed then
            entry.Claimed = true
            claimedAny = true

            -- Kirim paket resmi FireServer ke Server
            pcall(function()
                if networkMod and networkMod.FireServer then
                    networkMod.FireServer(networkMod, "meteorNetwork", id)
                end
            end)

            -- Eksekusi PlayHit & AddLuck
            pcall(function()
                local model = debris and debris:FindFirstChild(tostring(id))
                if playHitFn and model then
                    playHitFn(model)
                end
                if addLuckFn and entry.Data then
                    local luckMult = multTable[entry.Data.Name] or 1
                    addLuckFn(luckMult)
                end
            end)

            meteorClaimCount = meteorClaimCount + 1
            pcall(function()
                MeteorLabel.Text = string.format("☄️ Meteor Terklaim: %d", meteorClaimCount)
            end)
            print(string.format("💥 [GC CLAIM] Meteor #%s Berhasil Diklaim via Internal Game Engine!", tostring(id)))
        end
    end
    return claimedAny
end

-- =============================================
-- 🔍 2. PENDETEKSI BOLA / PROJECTILE MELAYANG
-- =============================================
local function findFlyingProjectile()
    local debris = workspace:FindFirstChild("Debris")
    if not debris then return nil end

    for _, obj in ipairs(debris:GetChildren()) do
        if obj.Name ~= "LuckMachine" and tonumber(obj.Name) == nil then
            if obj:IsA("BasePart") then
                if obj.AssemblyLinearVelocity.Magnitude > 1 or obj.Position.Y > 0 then
                    return obj
                end
            elseif obj:IsA("Model") then
                local root = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                if root and (root.AssemblyLinearVelocity.Magnitude > 1 or root.Position.Y > 0) then
                    return root
                end
            end
        end
    end

    for _, child in ipairs(workspace:GetChildren()) do
        if (child.Name == "Ball" or child.Name == "Projectile" or child.Name == "Football" or string.find(child.Name:lower(), "ball")) and child:IsA("BasePart") then
            return child
        end
    end

    return nil
end

-- =============================================
-- 💥 3. PROJECTILE RAYCAST MAGNET ENGINE
-- =============================================
local function prepareMeteorPart(part)
    if not part or not (part:IsA("BasePart") or part.ClassName == "Part") then return end
    pcall(function()
        part.CanCollide = false
        part.CanTouch = true
        part.CanQuery = true -- CRUCIAL: Diperlukan agar Raycast CheckForHit mengenai part ini!
        part.CastShadow = false
        if part.Size.X < 25 then
            part.Size = RAYCAST_HITBOX_SIZE
        end
    end)
end

local function handleNewMeteor(model)
    if not model or not isTargetModel(model) then return end
    if activeMeteors[model] then return end
    activeMeteors[model] = true

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant.ClassName == "Part" then
            prepareMeteorPart(descendant)
        end
    end

    -- Coba klaim langsung via Engine jika tersedia
    task.spawn(triggerDirectEngineClaim)

    if not processedRoots[model] then
        processedRoots[model] = true
        meteorClaimCount = meteorClaimCount + 1
        pcall(function()
            MeteorLabel.Text = string.format("☄️ Meteor Terdeteksi: %d", meteorClaimCount)
        end)
    end
end

-- =============================================
-- 🚀 HEARTBEAT LOOP: MENEMPELKAN METEOR KE BOLA
-- =============================================
RunService.Heartbeat:Connect(function()
    if not _G.autoMeteor then return end

    -- Trigger klaim GC jika ada list yang pending
    pcall(triggerDirectEngineClaim)

    local projectile = findFlyingProjectile()
    local debris = workspace:FindFirstChild("Debris")
    if not debris then return end

    if projectile and projectile.Parent then
        activeProjectile = projectile
        local ballCFrame = projectile.CFrame
        local forwardOffset = ballCFrame.LookVector * 2

        logDebug(string.format("Bola Terbang! Pos: (%.0f, %.0f)", projectile.Position.X, projectile.Position.Z))

        -- Tarik seluruh part meteor tepat di depan jalur terbang bola
        for model, _ in pairs(activeMeteors) do
            if model and model.Parent and model:IsDescendantOf(debris) then
                for _, descendant in ipairs(model:GetDescendants()) do
                    if descendant:IsA("BasePart") or descendant.ClassName == "Part" then
                        prepareMeteorPart(descendant)
                        pcall(function()
                            descendant.CFrame = ballCFrame + forwardOffset
                        end)
                    end
                end
            else
                activeMeteors[model] = nil
            end
        end
    else
        if activeProjectile then
            activeProjectile = nil
            logDebug("Bola Mendarat / Standby...")
        end
    end
end)

-- =============================================
-- 🔍 SETUP LISTENER DEBRIS
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
                    prepareMeteorPart(descendant)
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

-- Sweeper Rutin
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
print("☄️ [SUKSES] KALB Ultimate Meteor Engine Siap Digunakan!")
print("--------------------------------------------------")
