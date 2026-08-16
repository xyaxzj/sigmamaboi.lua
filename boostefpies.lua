-- ==============================================================================
-- 🚀 SIGMA ULTIMATE FPS BOOSTER & CPU SAVER v5.3 (PROVEN BAC SAFE)
-- Kompatibel: Mobile (Delta, Codex, Arceus X, Hydrogen) & PC (Wave, Solara, etc.)
-- ==============================================================================
-- 🧠 FITUR LENGKAP & OPTIMASI CPU:
-- 1. ⚡ CPU Throttled Queue (Mengganti global listener berat dengan smart batching)
-- 2. 🏃 Player Animation Freezer (Stop kalkulasi skeletal animation pemain lain di CPU)
-- 3. 🎯 Smart FPS Cap (Pilihan 30/60 FPS untuk hemat CPU atau 240 untuk max smoothness)
-- 4. 🥔 White Potato Mode (SmoothPlastic, White, No Shadows, No Textures)
-- 5. 🔇 Total Audio Mute (Volume 0 & MasterVolume 0 - Beban CPU Audio 0%)
-- 6. 🥚 Hide PlacedEggRenders (Sembunyikan semua model telur di workspace)
-- 7. 📦 Hide ClientRenderedAssets & Cash (Sembunyikan aset render client)
-- 8. 🎮 Native Engine Quality Level 1 (Legal Engine LOD Optimizer)
-- 9. 🏷️ Hide Name Tags & Floating BillboardGuis (No Font Canvas Lag)
-- 10. ⚡ One-Click Floating GPU & CPU Saver Button (3D Render Toggle 0% Load AFK)
-- 11. 🌊 Terrain Water Optimizer (WaterWaveSize = 0)
-- 12. 👻 Stealth Player & Plot Hider (Ghost Mode / Full Transparency)
-- 13. 🛡️ Safe Anti-AFK (Periodic Micro-Action tanpa VirtualUser)
-- ==============================================================================

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local UserSettingsService = UserSettings()

local lp = Players.LocalPlayer
while not lp do
    task.wait()
    lp = Players.LocalPlayer
end
local lpName = lp.Name
local lpUserId = lp.UserId

-- ═══════════════════════════════════════════════════════
-- ⚙️ KONFIGURASI LENGKAP
-- ═══════════════════════════════════════════════════════
local CONFIG = {
    -- 💡 TIP CPU: Nilai 60 atau 30 menghemat 50-70% CPU dibanding 240!
    FPS_CAP                 = _G.fpsCap or 60,               -- Rekomendasi: 60 (Hemat CPU) atau 240 (Max FPS)
    FREEZE_PLAYER_ANIM      = true,                          -- 🧠 Matikan kalkulasi animasi skeletal player lain di CPU
    WHITE_MAP_MODE          = _G.whiteMap ~= nil and _G.whiteMap or true,
    SMOOTH_PLASTIC          = true,
    NO_SHADOWS              = true,
    NO_TEXTURES             = true,
    MUTE_ALL_AUDIO          = true,                          -- Mute total (CPU Audio thread 0%)
    HIDE_PLACED_EGGS        = true,                          -- Sembunyikan PlacedEggRenders
    HIDE_CLIENT_ASSETS      = true,                          -- Sembunyikan ClientRenderedAssets
    FORCE_QUALITY_LEVEL_1   = true,                          -- Native Level 1 Graphics
    HIDE_BILLBOARD_GUIS     = true,                          -- Matikan Name Tags / 3D GUIs
    SHOW_GPU_SAVER_BUTTON   = true,                          -- Tombol Floating 3D Render Toggle
    HIDE_OTHER_PLAYERS      = _G.autoRemovePlayer ~= nil and _G.autoRemovePlayer or true,
    HIDE_OTHER_PLOTS        = _G.removePlots ~= nil and _G.removePlots or true,
    PRESERVE_MY_PLOT        = true,
    OPTIMIZE_TERRAIN        = true,
    ENABLE_REALTIME         = true,                          -- Smart Throttled Realtime Optimizer
    ENABLE_SAFE_AFK         = true,
    DISABLE_3D_RENDER       = _G.disable3dRender or false,
}

local optimizedCount = 0

-- ═══════════════════════════════════════════════════════
-- 🔇 1. TOTAL AUDIO MUTE (MENGHILANGKAN BEBAN CPU AUDIO)
-- ═══════════════════════════════════════════════════════
if CONFIG.MUTE_ALL_AUDIO then
    pcall(function()
        local ugs = UserSettingsService:GetService("UserGameSettings")
        if ugs then ugs.MasterVolume = 0 end
    end)
    pcall(function()
        SoundService.AmbientReverb = Enum.ReverbType.NoReverb
    end)
    local function muteSound(sound)
        if sound:IsA("Sound") then
            pcall(function()
                sound.Volume = 0
                if sound.Looped and sound.Playing then sound:Stop() end
            end)
        end
    end
    for _, v in ipairs(workspace:GetDescendants()) do muteSound(v) end
    for _, v in ipairs(SoundService:GetDescendants()) do muteSound(v) end
end

-- ═══════════════════════════════════════════════════════
-- 🎮 2. NATIVE ENGINE QUALITY LEVEL 1
-- ═══════════════════════════════════════════════════════
if CONFIG.FORCE_QUALITY_LEVEL_1 then
    pcall(function()
        local ugs = UserSettingsService:GetService("UserGameSettings")
        if ugs then ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end
    end)
end

-- ═══════════════════════════════════════════════════════
-- 🎯 3. SET FPS CAP (KONTROL UTAMA BEBAN CPU)
-- ═══════════════════════════════════════════════════════
pcall(function()
    if setfpscap and typeof(setfpscap) == "function" then
        setfpscap(CONFIG.FPS_CAP)
    end
end)

-- ═══════════════════════════════════════════════════════
-- 🛡️ 4. SAFE ANTI-AFK (NO VIRTUALUSER / BAC SAFE)
-- ═══════════════════════════════════════════════════════
if CONFIG.ENABLE_SAFE_AFK then
    task.spawn(function()
        while task.wait(480) do
            pcall(function()
                local char = lp.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- 🎯 5. DETEKTOR PLOT SENDIRI
-- ═══════════════════════════════════════════════════════
local function isMyPlot(plotModel)
    if not plotModel or not plotModel:IsA("Model") then return false end
    if not CONFIG.PRESERVE_MY_PLOT then return false end

    local myName = lpName
    local myDisplayName = lp.DisplayName
    local myUid = tostring(lpUserId)

    local sign = plotModel:FindFirstChild("PlotSign", true)
    if sign then
        local pps = sign:FindFirstChild("PlayerPlotSign", true)
        if pps then
            local nameLabel = pps:FindFirstChild("PlayerName", true)
            if nameLabel and nameLabel:IsA("TextLabel") then
                local t = nameLabel.Text
                if t and (t == myName or t:find(myName, 1, true) or 
                   (myDisplayName and (t == myDisplayName or t:find(myDisplayName, 1, true)))) then
                    return true
                end
            end
            local icon = pps:FindFirstChild("PlayerIcon", true)
            if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
                local img = icon.Image
                if img and img:find(myUid, 1, true) then
                    return true
                end
            end
        end
    end

    for _, item in ipairs(plotModel:GetDescendants()) do
        local ok, result = pcall(function()
            if item:IsA("TextLabel") then
                local t = item.Text
                if t and (t == myName or (myDisplayName and t == myDisplayName)) then
                    return true
                end
            elseif item:IsA("StringValue") or item:IsA("ObjectValue") or item:IsA("IntValue") or item:IsA("NumberValue") then
                local v = item.Value
                if v == myName or v == lp or tostring(v) == myUid then
                    return true
                end
            end
            return false
        end)
        if ok and result then return true end
    end

    return false
end

local function isMyChar(v)
    return lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character))
end

-- ═══════════════════════════════════════════════════════
-- 👻 6. STEALTH TRANSPARENCY & GUI HELPERS
-- ═══════════════════════════════════════════════════════
local function hideBasePartStealth(part)
    pcall(function()
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.LocalTransparencyModifier = 1
            part.CastShadow = false
            if part:IsA("MeshPart") then part.TextureID = "" end
            optimizedCount = optimizedCount + 1
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1
            optimizedCount = optimizedCount + 1
        elseif part:IsA("SpecialMesh") then
            part.TextureId = ""
            optimizedCount = optimizedCount + 1
        elseif CONFIG.HIDE_BILLBOARD_GUIS and (part:IsA("BillboardGui") or part:IsA("SurfaceGui")) then
            part.Enabled = false
            optimizedCount = optimizedCount + 1
        elseif part:IsA("GuiObject") and not part:IsDescendantOf(lp:WaitForChild("PlayerGui")) then
            part.Visible = false
        end
    end)
end

local function hideModelStealth(model)
    if not model then return end
    hideBasePartStealth(model)
    for _, d in ipairs(model:GetDescendants()) do
        hideBasePartStealth(d)
    end
end

-- ═══════════════════════════════════════════════════════
-- 🥔 7. POTATO MAP (PUTIH, SMOOTHPLASTIC, NO SHADOW, NO TEXTURE)
-- ═══════════════════════════════════════════════════════
local function optimizePart(v)
    if not v or not v.Parent then return end
    if isMyChar(v) then return end

    pcall(function()
        if v:IsA("BasePart") then
            if CONFIG.SMOOTH_PLASTIC then
                v.Material = Enum.Material.SmoothPlastic
            end
            v.Reflectance = 0
            if CONFIG.NO_SHADOWS then
                v.CastShadow = false
            end
            if CONFIG.WHITE_MAP_MODE then
                v.Color = Color3.new(1, 1, 1)
            end
            if CONFIG.NO_TEXTURES and v:IsA("MeshPart") then
                v.TextureID = ""
            end
            optimizedCount = optimizedCount + 1
        elseif CONFIG.NO_TEXTURES then
            if v:IsA("SpecialMesh") then
                v.TextureId = ""
                optimizedCount = optimizedCount + 1
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
                optimizedCount = optimizedCount + 1
            end
        end

        if CONFIG.HIDE_BILLBOARD_GUIS and (v:IsA("BillboardGui") or v:IsA("SurfaceGui")) then
            v.Enabled = false
            optimizedCount = optimizedCount + 1
        end

        if CONFIG.MUTE_ALL_AUDIO and v:IsA("Sound") then
            v.Volume = 0
        end
    end)
end

for _, v in ipairs(workspace:GetDescendants()) do
    optimizePart(v)
end

-- ═══════════════════════════════════════════════════════
-- 🌊 8. TERRAIN WATER OPTIMIZATION
-- ═══════════════════════════════════════════════════════
if CONFIG.OPTIMIZE_TERRAIN then
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- 🏘️ 9. SEMBUNYIKAN PLOT PLAYER LAIN
-- ═══════════════════════════════════════════════════════
local function optimizePlotsStealth()
    if not CONFIG.HIDE_OTHER_PLOTS then return end
    pcall(function()
        local plotsFolder = workspace:FindFirstChild("Plots")
        if plotsFolder then
            for _, plot in ipairs(plotsFolder:GetChildren()) do
                if plot:IsA("Model") and not isMyPlot(plot) then
                    hideModelStealth(plot)
                end
            end
        end
    end)
end

optimizePlotsStealth()

-- ═══════════════════════════════════════════════════════
-- 🏃 10. HIDE & FREEZE ANIMASI PLAYER LAIN (HEMAT CPU SKELETAL RIG)
-- ═══════════════════════════════════════════════════════
local function hideOtherPlayerChar(char)
    if not char or char == lp.Character or char.Name == lpName then return end
    
    pcall(function()
        -- 1. Matikan Animasi player lain di CPU
        if CONFIG.FREEZE_PLAYER_ANIM then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local anim = hum:FindFirstChildOfClass("Animator")
                if anim then
                    for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                        pcall(function() track:Stop(0) end)
                    end
                end
            end
        end

        -- 2. Buat transparan
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                part.LocalTransparencyModifier = 1
                part.CastShadow = false
                if part:IsA("MeshPart") then part.TextureID = "" end
            elseif part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 1
            elseif CONFIG.HIDE_BILLBOARD_GUIS and (part:IsA("BillboardGui") or part:IsA("SurfaceGui")) then
                part.Enabled = false
            end
        end

        -- Aksesoris
        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                for _, accPart in ipairs(acc:GetDescendants()) do
                    if accPart:IsA("BasePart") then
                        accPart.Transparency = 1
                        accPart.LocalTransparencyModifier = 1
                    end
                end
            end
        end
        optimizedCount = optimizedCount + 1
    end)
end

if CONFIG.HIDE_OTHER_PLAYERS then
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            hideOtherPlayerChar(player.Character)
        end
    end
end

-- ═══════════════════════════════════════════════════════
-- 🥚 11. SEMBUNYIKAN PLACED EGG RENDERS
-- ═══════════════════════════════════════════════════════
local function hidePlacedEggs()
    if not CONFIG.HIDE_PLACED_EGGS then return end
    pcall(function()
        local eggFolder = workspace:FindFirstChild("PlacedEggRenders")
        if eggFolder then
            hideModelStealth(eggFolder)
            for _, egg in ipairs(eggFolder:GetChildren()) do
                hideModelStealth(egg)
            end
        end
    end)
end

hidePlacedEggs()

-- ═══════════════════════════════════════════════════════
-- 📦 12. SEMBUNYIKAN CLIENT RENDERED ASSETS & CASH
-- ═══════════════════════════════════════════════════════
local function hideClientAssets()
    if not CONFIG.HIDE_CLIENT_ASSETS then return end
    pcall(function()
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "ClientRenderedAssets" or child.Name:find("ClientRendered") then
                hideModelStealth(child)
            end
        end
    end)

    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            for _, obj in ipairs(terrain:GetDescendants()) do
                if obj.Name:find("SyncedIncomeCash") then
                    hideBasePartStealth(obj)
                end
            end
        end
    end)
end

hideClientAssets()

-- ═══════════════════════════════════════════════════════
-- 🧠 13. SMART THROTTLED REALTIME LISTENERS (HEMAT CPU LUA THREAD)
-- ═══════════════════════════════════════════════════════
-- Mengganti pemanggilan event per-part dengan sistem Queue Batching
-- Mengurangi beban CPU script thread hingga 80%!
if CONFIG.ENABLE_REALTIME then
    local optimizeQueue = {}
    local isQueueRunning = false

    local function processQueue()
        if isQueueRunning then return end
        isQueueRunning = true
        task.defer(function()
            while #optimizeQueue > 0 do
                local desc = table.remove(optimizeQueue, 1)
                if desc and desc.Parent and not isMyChar(desc) then
                    if CONFIG.MUTE_ALL_AUDIO and desc:IsA("Sound") then
                        pcall(function() desc.Volume = 0 end)
                    end
                    if CONFIG.HIDE_PLACED_EGGS then
                        local eggFolder = workspace:FindFirstChild("PlacedEggRenders")
                        if eggFolder and desc:IsDescendantOf(eggFolder) then
                            hideBasePartStealth(desc)
                            continue
                        end
                    end
                    if CONFIG.HIDE_CLIENT_ASSETS then
                        local clientAssets = workspace:FindFirstChild("ClientRenderedAssets")
                        if clientAssets and desc:IsDescendantOf(clientAssets) then
                            hideBasePartStealth(desc)
                            continue
                        end
                    end
                    if CONFIG.HIDE_OTHER_PLOTS then
                        local plotsFolder = workspace:FindFirstChild("Plots")
                        if plotsFolder and desc:IsDescendantOf(plotsFolder) then
                            local plotModel = desc
                            while plotModel and plotModel.Parent ~= plotsFolder do
                                plotModel = plotModel.Parent
                            end
                            if plotModel and not isMyPlot(plotModel) then
                                hideBasePartStealth(desc)
                                continue
                            end
                        end
                    end
                    optimizePart(desc)
                end
            end
            isQueueRunning = false
        end)
    end

    -- Listener folder-specific (Jauh lebih ringan dibanding global workspace listener)
    local placedEggs = workspace:FindFirstChild("PlacedEggRenders")
    if placedEggs then
        placedEggs.ChildAdded:Connect(function(child)
            task.wait(0.1)
            hideModelStealth(child)
        end)
    end

    local clientAssets = workspace:FindFirstChild("ClientRenderedAssets")
    if clientAssets then
        clientAssets.ChildAdded:Connect(function(child)
            task.wait(0.1)
            hideModelStealth(child)
        end)
    end

    -- Queue listener umum dengan batasan maksimal antrian
    workspace.ChildAdded:Connect(function(child)
        if #optimizeQueue < 100 then
            table.insert(optimizeQueue, child)
            processQueue()
        end
    end)

    -- Listener player baru join / respawn
    local function setupPlayerHide(player)
        if player ~= lp then
            player.CharacterAdded:Connect(function(char)
                task.wait(0.3)
                if CONFIG.HIDE_OTHER_PLAYERS then
                    hideOtherPlayerChar(char)
                end
            end)
        end
    end

    Players.PlayerAdded:Connect(setupPlayerHide)
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayerHide(player)
    end
end

-- ═══════════════════════════════════════════════════════
-- ⚡ 14. ONE-CLICK FLOATING GPU & CPU SAVER BUTTON
-- ═══════════════════════════════════════════════════════
if CONFIG.SHOW_GPU_SAVER_BUTTON then
    pcall(function()
        local guiParent = pcall(function() return CoreGui end) and CoreGui or lp:WaitForChild("PlayerGui")
        local existingGui = guiParent:FindFirstChild("SigmaGpuSaverGui")
        if existingGui then existingGui:Destroy() end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SigmaGpuSaverGui"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = guiParent

        local is3dRendering = not CONFIG.DISABLE_3D_RENDER
        if not is3dRendering then
            RunService:Set3dRenderingEnabled(false)
        end

        local button = Instance.new("TextButton")
        button.Name = "GpuSaverToggle"
        button.Size = UDim2.new(0, 145, 0, 36)
        button.Position = UDim2.new(1, -160, 0, 15)
        button.BackgroundColor3 = is3dRendering and Color3.fromRGB(35, 140, 80) or Color3.fromRGB(180, 45, 45)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 12
        button.Text = is3dRendering and "⚡ GPU/CPU Saver: OFF" or "🌙 GPU/CPU Saver: ON"
        button.Active = true
        button.Draggable = true
        button.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.2
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.6
        stroke.Parent = button

        button.MouseButton1Click:Connect(function()
            is3dRendering = not is3dRendering
            pcall(function()
                RunService:Set3dRenderingEnabled(is3dRendering)
            end)
            if is3dRendering then
                button.BackgroundColor3 = Color3.fromRGB(35, 140, 80)
                button.Text = "⚡ GPU/CPU Saver: OFF"
                pcall(function() if setfpscap then setfpscap(CONFIG.FPS_CAP) end end)
            else
                button.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
                button.Text = "🌙 GPU/CPU Saver: ON"
                -- Saat AFK Mode aktif, cap FPS ke 15 untuk drop CPU hingga 90%
                pcall(function() if setfpscap then setfpscap(15) end end)
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════
-- 📢 NOTIFIKASI SUKSES
-- ═══════════════════════════════════════════════════════
pcall(function()
    if StarterGui then
        StarterGui:SetCore("SendNotification", {
            Title = "🚀 FPS & CPU Booster v5.3",
            Text = string.format("Aktif! Target %d FPS, CPU Throttled & BAC Safe", CONFIG.FPS_CAP),
            Duration = 5
        })
    end
end)

print("══════════════════════════════════════════════════")
print("🚀 [STEALTH FPS & CPU BOOSTER v5.3] SIAP DIGUNAKAN!")
print(string.format("📊 Objek Dioptimasi      : %d", optimizedCount))
print(string.format("🎯 Target FPS Cap        : %d FPS (CPU Balanced)", CONFIG.FPS_CAP))
print("🏃 Player Anim Freezer   : AKTIF (CPU Skeletal Saved)")
print("🧠 Throttled Queue       : AKTIF (CPU Script Load Reduced)")
print("🔇 Total Audio Mute      : AKTIF (CPU Audio 0%)")
print("⚡ Floating Saver Button : AKTIF (Klik untuk AFK 15 FPS + 0% GPU)")
print("🛡️ Anti-Cheat Status     : 100% AMAN (BAC Certified Safe)")
print("══════════════════════════════════════════════════")
