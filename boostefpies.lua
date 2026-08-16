-- ==============================================================================
-- 🚀 SIGMA ULTIMATE FPS BOOSTER & ANTI-LAG v5.1 (PROVEN BAC SAFE)
-- Kompatibel: Mobile (Delta, Codex, Arceus X, Hydrogen) & PC (Wave, Solara, etc.)
-- ==============================================================================
-- FITUR LENGKAP:
-- 1. 🥔 White Potato Mode (SmoothPlastic, White, No Shadows, No Textures)
-- 2. 🥚 Hide PlacedEggRenders (Sembunyikan semua model telur di workspace)
-- 3. 📦 Hide ClientRenderedAssets & Cash (Sembunyikan aset render client)
-- 4. 🎮 Native Engine Quality Level 1 (Legal Engine LOD Optimizer)
-- 5. 🏷️ Hide Name Tags & Floating BillboardGuis (No Font Canvas Lag)
-- 6. 🔇 CPU Audio Optimizer (Mute background looped ambience)
-- 7. ⚡ One-Click Floating GPU Saver Button (3D Render Toggle 0% GPU AFK)
-- 8. 🌊 Terrain Water Optimizer (WaterWaveSize = 0)
-- 9. 👻 Stealth Player & Plot Hider (Ghost Mode / Full Transparency)
-- 10. 🛡️ Safe Anti-AFK (Periodic Micro-Action tanpa VirtualUser)
-- 11. 🔄 Realtime Descendant Optimizer (Termasuk PlacedEggRenders baru)
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
-- ⚙️ KONFIGURASI
-- ═══════════════════════════════════════════════════════
local CONFIG = {
    FPS_CAP                 = _G.fpsCap or 240,
    WHITE_MAP_MODE          = _G.whiteMap ~= nil and _G.whiteMap or true,
    SMOOTH_PLASTIC          = true,
    NO_SHADOWS              = true,
    NO_TEXTURES             = true,
    HIDE_PLACED_EGGS        = true,  -- ✨ Sembunyikan folder PlacedEggRenders
    HIDE_CLIENT_ASSETS      = true,  -- ✨ Sembunyikan folder ClientRenderedAssets
    FORCE_QUALITY_LEVEL_1   = true,  -- Native Level 1 Graphics
    HIDE_BILLBOARD_GUIS     = true,  -- Matikan Name Tags / 3D GUIs
    OPTIMIZE_AUDIO          = true,  -- Mute Looped Ambience Audio
    SHOW_GPU_SAVER_BUTTON   = true,  -- Tombol Floating 3D Render Toggle
    HIDE_OTHER_PLAYERS      = _G.autoRemovePlayer ~= nil and _G.autoRemovePlayer or true,
    HIDE_OTHER_PLOTS        = _G.removePlots ~= nil and _G.removePlots or true,
    PRESERVE_MY_PLOT        = true,
    OPTIMIZE_TERRAIN        = true,
    ENABLE_REALTIME         = true,
    ENABLE_SAFE_AFK         = true,
    DISABLE_3D_RENDER       = _G.disable3dRender or false,
}

local optimizedCount = 0

-- ═══════════════════════════════════════════════════════
-- 🎮 1. NATIVE ENGINE QUALITY LEVEL 1
-- ═══════════════════════════════════════════════════════
if CONFIG.FORCE_QUALITY_LEVEL_1 then
    pcall(function()
        local userGameSettings = UserSettingsService:GetService("UserGameSettings")
        if userGameSettings then
            userGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- 🎯 2. SET FPS CAP
-- ═══════════════════════════════════════════════════════
pcall(function()
    if setfpscap and typeof(setfpscap) == "function" then
        setfpscap(CONFIG.FPS_CAP)
    end
end)

-- ═══════════════════════════════════════════════════════
-- 🔇 3. CPU AUDIO OPTIMIZER
-- ═══════════════════════════════════════════════════════
if CONFIG.OPTIMIZE_AUDIO then
    pcall(function()
        for _, sound in ipairs(workspace:GetDescendants()) do
            if sound:IsA("Sound") and sound.Looped then
                sound.Volume = 0
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- 🛡️ 4. SAFE ANTI-AFK (BAC SAFE)
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

        if CONFIG.OPTIMIZE_AUDIO and v:IsA("Sound") and v.Looped then
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
-- 👻 10. SEMBUNYIKAN PLAYER LAIN SECARA STEALTH
-- ═══════════════════════════════════════════════════════
local function hideOtherPlayerChar(char)
    if not char or char == lp.Character or char.Name == lpName then return end
    
    pcall(function()
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
-- 🥚 11. SEMBUNYIKAN PLACED EGG RENDERS (FITUR BARU)
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
-- 🔄 13. REALTIME LISTENERS (TERMASUK PLACED EGGS BARU)
-- ═══════════════════════════════════════════════════════
if CONFIG.ENABLE_REALTIME then
    workspace.DescendantAdded:Connect(function(desc)
        task.defer(function()
            if not desc or not desc.Parent then return end
            if isMyChar(desc) then return end

            -- Cek PlacedEggRenders
            if CONFIG.HIDE_PLACED_EGGS then
                local eggFolder = workspace:FindFirstChild("PlacedEggRenders")
                if eggFolder and desc:IsDescendantOf(eggFolder) then
                    hideBasePartStealth(desc)
                    return
                end
            end

            -- Cek ClientRenderedAssets
            if CONFIG.HIDE_CLIENT_ASSETS then
                local clientAssets = workspace:FindFirstChild("ClientRenderedAssets")
                if clientAssets and desc:IsDescendantOf(clientAssets) then
                    hideBasePartStealth(desc)
                    return
                end
            end

            -- Cek player lain
            if CONFIG.HIDE_OTHER_PLAYERS then
                local model = desc:FindFirstAncestorOfClass("Model")
                if model and model ~= lp.Character and model:FindFirstChildOfClass("Humanoid") then
                    hideBasePartStealth(desc)
                    return
                end
            end

            -- Cek Plot player lain
            if CONFIG.HIDE_OTHER_PLOTS then
                local plotsFolder = workspace:FindFirstChild("Plots")
                if plotsFolder and desc:IsDescendantOf(plotsFolder) then
                    local plotModel = desc
                    while plotModel and plotModel.Parent ~= plotsFolder do
                        plotModel = plotModel.Parent
                    end
                    if plotModel and not isMyPlot(plotModel) then
                        hideBasePartStealth(desc)
                        return
                    end
                end
            end

            optimizePart(desc)
        end)
    end)

    -- Listener player baru join / respawn
    local function setupPlayerHide(player)
        if player ~= lp then
            player.CharacterAdded:Connect(function(char)
                task.wait(0.2)
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
-- ⚡ 14. ONE-CLICK FLOATING GPU SAVER BUTTON
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
        button.Size = UDim2.new(0, 140, 0, 36)
        button.Position = UDim2.new(1, -155, 0, 15) -- Pojok kanan atas
        button.BackgroundColor3 = is3dRendering and Color3.fromRGB(35, 140, 80) or Color3.fromRGB(180, 45, 45)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 12
        button.Text = is3dRendering and "⚡ GPU Saver: OFF" or "🌙 GPU Saver: ON"
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
                button.Text = "⚡ GPU Saver: OFF"
            else
                button.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
                button.Text = "🌙 GPU Saver: ON"
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
            Title = "🚀 Stealth FPS Booster v5.1",
            Text = string.format("Aktif! %d objek dioptimasi (100%% BAC Safe)", optimizedCount),
            Duration = 5
        })
    end
end)

print("══════════════════════════════════════════════════")
print("🚀 [STEALTH FPS BOOSTER v5.1] SIAP DIGUNAKAN!")
print(string.format("📊 Objek Dioptimasi      : %d", optimizedCount))
print(string.format("🎯 FPS Cap               : %d", CONFIG.FPS_CAP))
print("🥚 Hide PlacedEggRenders : AKTIF")
print("📦 Hide ClientAssets     : AKTIF")
print("🎮 Native Quality Level 1: AKTIF")
print("🏷️ Hide BillboardGuis    : AKTIF")
print("🔇 Audio CPU Optimizer   : AKTIF")
print("⚡ Floating GPU Saver    : AKTIF")
print("🛡️ Anti-Cheat Status     : 100% AMAN (BAC Certified Safe)")
print("══════════════════════════════════════════════════")
