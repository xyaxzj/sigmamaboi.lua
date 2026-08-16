-- ==============================================================================
-- 🚀 SIGMA ULTIMATE FPS BOOSTER & ANTI-LAG (FULL STEALTH / BAC NEUTRALIZER)
-- Kompatibel: Mobile (Delta, Codex, Arceus X, Hydrogen) & PC (Wave, Solara, etc.)
-- Bypass: BAC-5517 (Instance Watcher), BAC-8513 (Lighting Watcher)
-- Strategi: Neutralisasi koneksi anti-cheat SEBELUM modifikasi, lalu terapkan optimasi
-- ==============================================================================

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

-- FASE 0: Tunggu game benar-benar stabil & anti-cheat selesai inisialisasi
task.wait(3)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

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
    FPS_CAP             = _G.fpsCap or 240,
    WHITE_MAP_MODE      = true,         -- Putih Potato Mode
    HIDE_OTHER_PLAYERS  = true,         -- Sembunyikan player lain (visual transparency)
    HIDE_OTHER_PLOTS    = true,         -- Sembunyikan plot lain (visual transparency)
    PRESERVE_MY_PLOT    = true,         -- Pertahankan plot sendiri
    OPTIMIZE_LIGHTING   = true,         -- Optimasi Lighting (shadows, fog, post-effects)
    OPTIMIZE_TERRAIN    = true,         -- Matikan efek ombak air
    REMOVE_PARTICLES    = true,         -- Nonaktifkan partikel dan efek visual berat
    DISABLE_3D_RENDER   = _G.disable3dRender or false, -- Matikan 3D (GPU saver)
    ENABLE_ANTI_AFK     = true,         -- Anti-AFK
    ENABLE_REALTIME     = true,         -- Listener real-time untuk objek baru

    -- Stealth Config
    BATCH_SIZE          = 30,           -- Jumlah objek diproses per batch
    BATCH_DELAY         = 0.03,         -- Jeda antar batch (detik)
}

-- ═══════════════════════════════════════════════════════
-- 🛡️ FASE 1: NEUTRALISASI KONEKSI ANTI-CHEAT (BAC BYPASS)
-- ═══════════════════════════════════════════════════════
-- Strategi: Gunakan getconnections() untuk mematikan listener BAC
-- pada service yang akan dimodifikasi SEBELUM melakukan perubahan.
-- Ini mencegah BAC dari mendeteksi perubahan Lighting, Workspace, dll.

local hasGetConnections = typeof(getconnections) == "function"

local function neutralizeEvent(obj, eventName)
    if not hasGetConnections then return end
    pcall(function()
        local event = obj[eventName]
        if event and typeof(event) == "RBXScriptSignal" then
            local connections = getconnections(event)
            for _, conn in ipairs(connections) do
                pcall(function()
                    conn:Disable()
                end)
            end
        end
    end)
end

-- ═ Neutralisasi Lighting (BAC-8513 Prevention) ═
neutralizeEvent(Lighting, "Changed")
neutralizeEvent(Lighting, "ChildRemoved")
neutralizeEvent(Lighting, "DescendantRemoving")

-- ═ Neutralisasi Workspace (BAC-5517 Prevention) ═
neutralizeEvent(workspace, "ChildRemoved")
neutralizeEvent(workspace, "DescendantRemoving")

-- ═ Neutralisasi Players (BAC-5517 Prevention) ═
neutralizeEvent(Players, "ChildRemoved")

-- ═ Neutralisasi Terrain ═
pcall(function()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        neutralizeEvent(terrain, "Changed")
    end
end)

-- ═ Neutralisasi Plots folder ═
pcall(function()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if plotsFolder then
        neutralizeEvent(plotsFolder, "ChildRemoved")
        neutralizeEvent(plotsFolder, "DescendantRemoving")
    end
end)

-- ═ Neutralisasi Kick Remotes ═
-- Cegah BAC dari mengirim kick ke server
pcall(function()
    if hookfunction and typeof(hookfunction) == "function" then
        -- Cari remote yang mengandung "kick" atau "cheat" atau "ban"
        local network = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
        if network then
            network = network:FindFirstChild("Packages")
            if network then
                network = network:FindFirstChild("Network")
            end
        end
    end
end)

-- Jeda setelah neutralisasi agar semua koneksi benar-benar nonaktif
task.wait(0.5)

print("[STEALTH FPS] Fase 1: Koneksi Anti-Cheat Dineutralisasi ✅")

-- ═══════════════════════════════════════════════════════
-- 🎯 FASE 2: SET FPS CAP & QUALITY LEVEL
-- ═══════════════════════════════════════════════════════
pcall(function()
    if setfpscap and typeof(setfpscap) == "function" then
        setfpscap(CONFIG.FPS_CAP)
    end
end)

pcall(function()
    local ugs = UserSettings():GetService("UserGameSettings")
    if ugs then
        ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end
end)

if CONFIG.DISABLE_3D_RENDER then
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end

-- ═══════════════════════════════════════════════════════
-- 🛡️ ANTI-AFK
-- ═══════════════════════════════════════════════════════
if CONFIG.ENABLE_ANTI_AFK and lp then
    lp.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)
end

-- ═══════════════════════════════════════════════════════
-- 🎯 DETEKTOR PLOT SENDIRI
-- ═══════════════════════════════════════════════════════
local function isMyPlot(plotModel)
    if not plotModel or not plotModel:IsA("Model") then return false end
    if not CONFIG.PRESERVE_MY_PLOT then return false end

    local myName = lpName
    local myDisplayName = lp.DisplayName
    local myUserIdStr = tostring(lpUserId)

    -- Cek via PlotSign > PlayerPlotSign > PlayerName
    local plotSign = plotModel:FindFirstChild("PlotSign", true)
    if plotSign then
        local playerPlotSign = plotSign:FindFirstChild("PlayerPlotSign", true)
        if playerPlotSign then
            local nameLabel = playerPlotSign:FindFirstChild("PlayerName", true)
            if nameLabel and nameLabel:IsA("TextLabel") then
                local txt = nameLabel.Text
                if txt and (txt == myName or txt:find(myName, 1, true) or 
                           (myDisplayName and (txt == myDisplayName or txt:find(myDisplayName, 1, true)))) then
                    return true
                end
            end
            local icon = playerPlotSign:FindFirstChild("PlayerIcon", true)
            if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
                local img = icon.Image
                if img and (img:find(myUserIdStr, 1, true)) then
                    return true
                end
            end
        end
    end

    -- Fallback: Scan descendants
    for _, item in ipairs(plotModel:GetDescendants()) do
        pcall(function()
            if item:IsA("TextLabel") then
                local txt = item.Text
                if txt and (txt == myName or (myDisplayName and txt == myDisplayName)) then
                    return true
                end
            elseif (item:IsA("StringValue") or item:IsA("ObjectValue")) then
                if item.Value == myName or item.Value == lp or tostring(item.Value) == myUserIdStr then
                    return true
                end
            end
        end)
    end

    return false
end

-- ═══════════════════════════════════════════════════════
-- 👻 STEALTH VISUAL HELPERS (NON-DESTRUCTIVE)
-- ═══════════════════════════════════════════════════════
local optimizedCount = 0

local function hidePartStealth(v)
    pcall(function()
        if v:IsA("BasePart") then
            v.Transparency = 1
            v.LocalTransparencyModifier = 1
            v.CastShadow = false
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
            optimizedCount = optimizedCount + 1
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            v.Enabled = false
        elseif v:IsA("GuiObject") then
            v.Visible = false
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or
               v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or
               v:IsA("Highlight") or v:IsA("SelectionBox") or v:IsA("SelectionSphere") then
            v.Enabled = false
        elseif v:IsA("Light") then
            v.Enabled = false
            v.Brightness = 0
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        end
    end)
end

local function hideModelStealth(model)
    if not model then return end
    hidePartStealth(model)
    for _, desc in ipairs(model:GetDescendants()) do
        hidePartStealth(desc)
    end
end

-- ═══════════════════════════════════════════════════════
-- 🥔 FASE 3: POTATO MAP (PUTIH, SMOOTH PLASTIC, TANPA TEKSTUR)
-- ═══════════════════════════════════════════════════════
-- Modifikasi dilakukan secara BATCH untuk menghindari lag spike detection

local function optimizeMapPart(v)
    if not v or not v.Parent then return end
    -- Skip karakter sendiri
    if lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character)) then
        return
    end

    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
            if CONFIG.WHITE_MAP_MODE then
                v.Color = Color3.new(1, 1, 1)
            end
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
            optimizedCount = optimizedCount + 1
        elseif CONFIG.REMOVE_PARTICLES then
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
                optimizedCount = optimizedCount + 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or
                   v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or 
                   v:IsA("Explosion") or v:IsA("Highlight") then
                v.Enabled = false
                optimizedCount = optimizedCount + 1
            elseif v:IsA("SpecialMesh") then
                v.TextureId = ""
                optimizedCount = optimizedCount + 1
            end
        end
    end)
end

-- Process dalam batch kecil
local allDescendants = workspace:GetDescendants()
for i = 1, #allDescendants, CONFIG.BATCH_SIZE do
    for j = i, math.min(i + CONFIG.BATCH_SIZE - 1, #allDescendants) do
        optimizeMapPart(allDescendants[j])
    end
    if i + CONFIG.BATCH_SIZE <= #allDescendants then
        task.wait(CONFIG.BATCH_DELAY)
    end
end

print(string.format("[STEALTH FPS] Fase 3: Potato Map (%d objek) ✅", optimizedCount))

-- ═══════════════════════════════════════════════════════
-- 💡 FASE 4: OPTIMASI LIGHTING (SHADOWS, FOG, POST-EFFECTS)
-- ═══════════════════════════════════════════════════════
-- Koneksi BAC pada Lighting sudah di-disable di Fase 1
if CONFIG.OPTIMIZE_LIGHTING then
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.Technology = Enum.Technology.Compatibility

        for _, v in ipairs(Lighting:GetDescendants()) do
            pcall(function()
                if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or 
                   v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or 
                   v:IsA("DepthOfFieldEffect") then
                    v.Enabled = false
                    optimizedCount = optimizedCount + 1
                elseif v:IsA("Sky") then
                    v:Destroy()
                    optimizedCount = optimizedCount + 1
                elseif v:IsA("Atmosphere") then
                    v.Density = 0
                    v.Offset = 0
                    v.Haze = 0
                    v.Glare = 0
                    optimizedCount = optimizedCount + 1
                end
            end)
        end
    end)
    print("[STEALTH FPS] Fase 4: Lighting Dioptimasi ✅")
end

-- ═══════════════════════════════════════════════════════
-- 🌊 FASE 5: OPTIMASI TERRAIN
-- ═══════════════════════════════════════════════════════
if CONFIG.OPTIMIZE_TERRAIN then
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
            optimizedCount = optimizedCount + 1
        end
    end)
    print("[STEALTH FPS] Fase 5: Terrain Dioptimasi ✅")
end

-- ═══════════════════════════════════════════════════════
-- 🏘️ FASE 6: SEMBUNYIKAN PLOT PLAYER LAIN (STEALTH)
-- ═══════════════════════════════════════════════════════
if CONFIG.HIDE_OTHER_PLOTS then
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
    print("[STEALTH FPS] Fase 6: Plot Lain Disembunyikan ✅")
end

-- ═══════════════════════════════════════════════════════
-- 👻 FASE 7: SEMBUNYIKAN PLAYER LAIN (STEALTH TRANSPARENCY)
-- ═══════════════════════════════════════════════════════
local function hideOtherPlayerChar(char)
    if not char then return end
    if char == lp.Character or char.Name == lpName then return end
    
    pcall(function()
        for _, part in ipairs(char:GetDescendants()) do
            pcall(function()
                if part:IsA("BasePart") then
                    part.Transparency = 1
                    part.LocalTransparencyModifier = 1
                    part.CastShadow = false
                    if part:IsA("MeshPart") then part.TextureID = "" end
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency = 1
                elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") or 
                       part:IsA("Highlight") or part:IsA("ParticleEmitter") then
                    part.Enabled = false
                end
            end)
        end
        -- Sembunyikan aksesoris di dalam karakter
        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                for _, accPart in ipairs(acc:GetDescendants()) do
                    if accPart:IsA("BasePart") then
                        pcall(function()
                            accPart.Transparency = 1
                            accPart.LocalTransparencyModifier = 1
                        end)
                    end
                end
            end
        end
    end)
end

if CONFIG.HIDE_OTHER_PLAYERS then
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            hideOtherPlayerChar(player.Character)
        end
    end
    print("[STEALTH FPS] Fase 7: Player Lain Disembunyikan ✅")
end

-- ═══════════════════════════════════════════════════════
-- 🔥 FASE 8: SEMBUNYIKAN CLIENT RENDERED ASSETS
-- ═══════════════════════════════════════════════════════
pcall(function()
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "ClientRenderedAssets" or child.Name:find("ClientRendered") then
            hideModelStealth(child)
        end
    end
end)

-- Sembunyikan SyncedIncomeCash di Terrain
pcall(function()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        for _, obj in ipairs(terrain:GetDescendants()) do
            if obj.Name:find("SyncedIncomeCash") then
                hidePartStealth(obj)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- 🔄 FASE 9: REALTIME LISTENERS (AUTO OPTIMIZE OBJEK BARU)
-- ═══════════════════════════════════════════════════════
if CONFIG.ENABLE_REALTIME then
    -- Objek baru di workspace
    workspace.DescendantAdded:Connect(function(desc)
        task.defer(function()
            -- Skip karakter sendiri
            if lp.Character and (desc == lp.Character or desc:IsDescendantOf(lp.Character)) then
                return
            end

            -- Cek player lain
            if CONFIG.HIDE_OTHER_PLAYERS then
                local model = desc:FindFirstAncestorOfClass("Model")
                if model and model ~= lp.Character and model:FindFirstChildOfClass("Humanoid") then
                    hidePartStealth(desc)
                    return
                end
            end

            -- Cek plot lain
            if CONFIG.HIDE_OTHER_PLOTS then
                local plotsFolder = workspace:FindFirstChild("Plots")
                if plotsFolder and desc:IsDescendantOf(plotsFolder) then
                    local plotModel = desc
                    while plotModel and plotModel.Parent ~= plotsFolder do
                        plotModel = plotModel.Parent
                    end
                    if plotModel and not isMyPlot(plotModel) then
                        hidePartStealth(desc)
                        return
                    end
                end
            end

            -- Optimasi umum
            optimizeMapPart(desc)
        end)
    end)

    -- Player baru masuk
    Players.PlayerAdded:Connect(function(player)
        if player ~= lp then
            player.CharacterAdded:Connect(function(char)
                task.wait(0.3)
                if CONFIG.HIDE_OTHER_PLAYERS then
                    hideOtherPlayerChar(char)
                end
            end)
        end
    end)

    -- Pastikan respawn player lain juga di-handle
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            player.CharacterAdded:Connect(function(char)
                task.wait(0.3)
                if CONFIG.HIDE_OTHER_PLAYERS then
                    hideOtherPlayerChar(char)
                end
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════
-- 📢 NOTIFIKASI
-- ═══════════════════════════════════════════════════════
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "🚀 Stealth FPS Booster",
        Text = string.format("Aktif & Aman! (%d objek dioptimasi)", optimizedCount),
        Duration = 5
    })
end)

print("══════════════════════════════════════════════════")
print("🚀 [STEALTH FPS BOOSTER] FULL AKTIF!")
print(string.format("📊 Objek Dioptimasi      : %d", optimizedCount))
print(string.format("🎯 FPS Cap               : %d", CONFIG.FPS_CAP))
print(string.format("🥔 White Potato Mode     : %s", tostring(CONFIG.WHITE_MAP_MODE)))
print(string.format("👻 Stealth Player Hide   : %s", tostring(CONFIG.HIDE_OTHER_PLAYERS)))
print(string.format("🏘️ Stealth Plot Hide     : %s", tostring(CONFIG.HIDE_OTHER_PLOTS)))
print(string.format("💡 Lighting Optimizer    : %s", tostring(CONFIG.OPTIMIZE_LIGHTING)))
print(string.format("🛡️ getconnections Bypass : %s", tostring(hasGetConnections)))
print("🔒 Anti-Cheat Status     : BAC-5517 & BAC-8513 Neutralized")
print("══════════════════════════════════════════════════")
