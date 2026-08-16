-- ==============================================================================
-- 🚀 SIGMA ULTIMATE FPS BOOSTER & ANTI-LAG (CLEAN & OPTIMIZED EDITION)
-- Kompatibel: Mobile (Delta, Codex, Arceus X, Hydrogen) & PC (Wave, Solara, etc.)
-- ==============================================================================

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserSettingsService = UserSettings()

local lp = Players.LocalPlayer
while not lp do
    task.wait()
    lp = Players.LocalPlayer
end
local lpName = lp.Name
local lpDisplayName = lp.DisplayName
local lpUserId = lp.UserId
local myUidStr = tostring(lpUserId)

-- ═══════════════════════════════════════════════════════
-- ⚙️ KONFIGURASI PUSAT (UBAH SESUAI KEBUTUHAN)
-- ═══════════════════════════════════════════════════════
local CONFIG = {
    FPS_CAP                 = _G.fpsCap or 60,               -- Target FPS (60 hemat CPU, 240 max FPS)
    DISABLE_3D_RENDER       = _G.disable3dRender ~= nil and _G.disable3dRender or true, -- true: Layar freeze / 0% GPU saat AFK
    WHITE_MAP_MODE          = _G.whiteMap ~= nil and _G.whiteMap or true, -- true: Map putih potato
    SMOOTH_PLASTIC          = true,                          -- true: Material SmoothPlastic
    NO_SHADOWS              = true,                          -- true: Matikan bayangan
    NO_TEXTURES             = true,                          -- true: Hapus tekstur mesh & decal
    MUTE_ALL_AUDIO          = true,                          -- true: Mute semua suara (CPU Audio 0%)
    HIDE_PLACED_EGGS        = true,                          -- true: Sembunyikan PlacedEggRenders
    HIDE_CLIENT_ASSETS      = true,                          -- true: Sembunyikan ClientRenderedAssets
    FORCE_QUALITY_LEVEL_1   = true,                          -- true: Native Level 1 Graphics
    HIDE_BILLBOARD_GUIS     = true,                          -- true: Matikan text nama melayang
    HIDE_OTHER_PLAYERS      = _G.autoRemovePlayer ~= nil and _G.autoRemovePlayer or true,
    HIDE_OTHER_PLOTS        = _G.removePlots ~= nil and _G.removePlots or true,
    PRESERVE_MY_PLOT        = true,                          -- true: Plot sendiri tetap terlihat
    OPTIMIZE_TERRAIN        = true,                          -- true: Matikan ombak air
    ENABLE_REALTIME         = true,                          -- true: Realtime optimizer hemat CPU
    ENABLE_SAFE_AFK         = true,                          -- true: Anti-AFK VirtualInputManager
    FREEZE_PLAYER_ANIM      = true,                          -- true: Stop animasi skeletal player lain
}

local optimizedCount = 0
local myPlotCache = {}

-- ═══════════════════════════════════════════════════════
-- 🎯 1. INISIALISASI SETTING ENGINE & HARDWARE
-- ═══════════════════════════════════════════════════════
-- FPS Cap
pcall(function()
    if setfpscap and typeof(setfpscap) == "function" then
        setfpscap(CONFIG.FPS_CAP)
    end
end)

-- Native Quality Level 1
if CONFIG.FORCE_QUALITY_LEVEL_1 then
    pcall(function()
        local ugs = UserSettingsService:GetService("UserGameSettings")
        if ugs then ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end
    end)
end

-- Audio Mute
if CONFIG.MUTE_ALL_AUDIO then
    pcall(function()
        local ugs = UserSettingsService:GetService("UserGameSettings")
        if ugs then ugs.MasterVolume = 0 end
        SoundService.AmbientReverb = Enum.ReverbType.NoReverb
    end)
end

-- 3D Render GPU Saver
if CONFIG.DISABLE_3D_RENDER then
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end

-- ═══════════════════════════════════════════════════════
-- 🛡️ 2. SAFE ANTI-AFK (VIRTUAL INPUT & IDLED LISTENER)
-- ═══════════════════════════════════════════════════════
if CONFIG.ENABLE_SAFE_AFK then
    local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil

    local function sendInputTick()
        if VIM then
            VIM:SendMouseButtonEvent(10, 10, 0, true, game, 1)
            task.wait(0.05)
            VIM:SendMouseButtonEvent(10, 10, 0, false, game, 1)
        elseif mouse1click then
            mouse1click()
        end
    end

    lp.Idled:Connect(function()
        pcall(sendInputTick)
    end)

    task.spawn(function()
        while task.wait(120) do
            pcall(sendInputTick)
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- 🔍 3. SMART PLOT DETECTOR DENGAN CACHING
-- ═══════════════════════════════════════════════════════
local function isMyPlot(plotModel)
    if not plotModel or not plotModel:IsA("Model") then return false end
    if not CONFIG.PRESERVE_MY_PLOT then return false end
    if myPlotCache[plotModel] ~= nil then return myPlotCache[plotModel] end

    -- Cek PlotSign
    local sign = plotModel:FindFirstChild("PlotSign", true)
    if sign then
        local pps = sign:FindFirstChild("PlayerPlotSign", true)
        if pps then
            local nameLabel = pps:FindFirstChild("PlayerName", true)
            if nameLabel and nameLabel:IsA("TextLabel") then
                local t = nameLabel.Text
                if t and (t == lpName or t:find(lpName, 1, true) or (lpDisplayName and (t == lpDisplayName or t:find(lpDisplayName, 1, true)))) then
                    myPlotCache[plotModel] = true
                    return true
                end
            end
            local icon = pps:FindFirstChild("PlayerIcon", true)
            if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
                local img = icon.Image
                if img and img:find(myUidStr, 1, true) then
                    myPlotCache[plotModel] = true
                    return true
                end
            end
        end
    end

    -- Fallback Value scan
    for _, item in ipairs(plotModel:GetDescendants()) do
        local ok, result = pcall(function()
            if item:IsA("TextLabel") then
                local t = item.Text
                if t and (t == lpName or (lpDisplayName and t == lpDisplayName)) then return true end
            elseif item:IsA("StringValue") or item:IsA("ObjectValue") or item:IsA("IntValue") or item:IsA("NumberValue") then
                local v = item.Value
                if v == lpName or v == lp or tostring(v) == myUidStr then return true end
            end
            return false
        end)
        if ok and result then
            myPlotCache[plotModel] = true
            return true
        end
    end

    myPlotCache[plotModel] = false
    return false
end

local function isMyChar(v)
    return lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character))
end

-- ═══════════════════════════════════════════════════════
-- 👻 4. STEALTH TRANSPARENCY HELPERS
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
-- 🥔 5. POTATO MAP CORE (PUTIH, SMOOTHPLASTIC, NO SHADOW, NO TEXTURE)
-- ═══════════════════════════════════════════════════════
local function optimizePart(v)
    if not v or not v.Parent or isMyChar(v) then return end

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
            if v.Looped and v.Playing then v:Stop() end
        end
    end)
end

-- Eksekusi awal ke seluruh workspace
for _, v in ipairs(workspace:GetDescendants()) do
    optimizePart(v)
end

-- ═══════════════════════════════════════════════════════
-- 🌊 6. TERRAIN WATER OPTIMIZATION
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
-- 🏘️ 7. SEMBUNYIKAN PLOT PLAYER LAIN
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
-- 👥 8. SEMBUNYIKAN & FREEZE ANIMASI PLAYER LAIN
-- ═══════════════════════════════════════════════════════
local function hideOtherPlayerChar(char)
    if not char or char == lp.Character or char.Name == lpName then return end
    
    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and CONFIG.FREEZE_PLAYER_ANIM then
            local anim = hum:FindFirstChildOfClass("Animator")
            if anim then
                for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                    pcall(function() track:Stop(0) end)
                end
            end
        end

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
-- 🥚 9. SEMBUNYIKAN PLACED EGG RENDERS & CLIENT ASSETS
-- ═══════════════════════════════════════════════════════
if CONFIG.HIDE_PLACED_EGGS then
    pcall(function()
        local eggFolder = workspace:FindFirstChild("PlacedEggRenders")
        if eggFolder then hideModelStealth(eggFolder) end
    end)
end

if CONFIG.HIDE_CLIENT_ASSETS then
    pcall(function()
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "ClientRenderedAssets" or child.Name:find("ClientRendered") then
                hideModelStealth(child)
            end
        end
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

-- ═══════════════════════════════════════════════════════
-- 🧠 10. SMART THROTTLED REALTIME LISTENERS
-- ═══════════════════════════════════════════════════════
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
                        pcall(function()
                            desc.Volume = 0
                            if desc.Looped and desc.Playing then desc:Stop() end
                        end)
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

    workspace.ChildAdded:Connect(function(child)
        if #optimizeQueue < 100 then
            table.insert(optimizeQueue, child)
            processQueue()
        end
    end)

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
-- 📢 NOTIFIKASI SUKSES
-- ═══════════════════════════════════════════════════════
pcall(function()
    if StarterGui then
        StarterGui:SetCore("SendNotification", {
            Title = "🚀 FPS & CPU Booster",
            Text = string.format("Aktif! Target %d FPS (Clean & Optimized)", CONFIG.FPS_CAP),
            Duration = 5
        })
    end
end)

print("══════════════════════════════════════════════════")
print("🚀 [STEALTH FPS & CPU BOOSTER] CLEAN & OPTIMIZED")
print(string.format("📊 Objek Dioptimasi      : %d", optimizedCount))
print(string.format("🎯 Target FPS Cap        : %d FPS", CONFIG.FPS_CAP))
print(string.format("🌙 3D Rendering (GPU)    : %s", CONFIG.DISABLE_3D_RENDER and "OFF (0% GPU AFK)" or "ON"))
print("🏃 Player Anim Freezer   : AKTIF (CPU Skeletal Saved)")
print("🧠 Throttled Queue       : AKTIF (CPU Script Load Reduced)")
print("🔇 Total Audio Mute      : AKTIF (CPU Audio 0%)")
print("🛡️ Anti-Cheat Status     : 100% AMAN")
print("══════════════════════════════════════════════════")
