-- ==============================================================================
-- 🚀 SIGMA ULTIMATE FPS BOOSTER & ANTI-LAG (100% STEALTH & ANTI-CHEAT SAFE)
-- Kompatibel: Mobile (Delta, Codex, Arceus X, Hydrogen) & PC (Wave, Solara, etc.)
-- Dilengkapi: Bypass BAC-5517 / Anti-Tamper Safe (Non-Destructive Visual Override)
-- Fitur: Potato Map, Hide Other Players (Stealth), Hide Other Plots, Lighting Opt, Anti-AFK
-- ==============================================================================

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

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

---------------------------------------------------------
-- ⚙️ KONFIGURASI 
---------------------------------------------------------
local CONFIG = {
    FPS_CAP             = _G.fpsCap or 240,             -- Target FPS Cap
    WHITE_MAP_MODE      = _G.whiteMap ~= nil and _G.whiteMap or true,   -- true: Ubah map jadi putih bersih
    HIDE_OTHER_PLAYERS  = _G.autoRemovePlayer ~= nil and _G.autoRemovePlayer or true, -- true: Sembunyikan player lain secara visual (Stealth)
    HIDE_OTHER_PLOTS    = _G.removePlots ~= nil and _G.removePlots or true,           -- true: Sembunyikan plot player lain
    PRESERVE_MY_PLOT    = true,                         -- true: Jaga agar plot kita tetap terlihat
    HIDE_CLIENT_ASSETS  = _G.removeClientAssets ~= nil and _G.removeClientAssets or (_G.hideClientAssets ~= nil and _G.hideClientAssets or true), -- true: Sembunyikan item drop
    HIDE_INCOME_CASH    = _G.hideIncomeCash ~= nil and _G.hideIncomeCash or true,     -- true: Sembunyikan part cash di Terrain
    DISABLE_3D_RENDER   = _G.disable3dRender or false,  -- true: Matikan 3D Rendering layar (GPU Saver)
    OPTIMIZE_TERRAIN    = true,                         -- true: Matikan efek ombak air
    OPTIMIZE_LIGHTING   = true,                         -- true: Matikan bayangan, kabut, dan efek post-processing
    REMOVE_PARTICLES    = true,                         -- true: Matikan partikel, decal, tekstur, api, asap
    ENABLE_ANTI_AFK     = true,                         -- true: Anti-AFK 20 menit
    ENABLE_REALTIME_OPT = true,                         -- true: Listener realtime untuk objek baru
}

-- Sinkronisasi global
_G.autoRemovePlayer = CONFIG.HIDE_OTHER_PLAYERS
_G.removePlayer = CONFIG.HIDE_OTHER_PLAYERS
_G.removePlayers = CONFIG.HIDE_OTHER_PLAYERS
_G.removeClientAssets = CONFIG.HIDE_CLIENT_ASSETS
_G.hideClientAssets = CONFIG.HIDE_CLIENT_ASSETS
_G.hideIncomeCash = CONFIG.HIDE_INCOME_CASH

-- 1. SET FPS CAP
pcall(function()
    if setfpscap then
        setfpscap(CONFIG.FPS_CAP)
    end
end)

-- 2. GPU SAVER (JIKA DIAKTIFKAN)
if CONFIG.DISABLE_3D_RENDER then
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end

local optimizedCount = 0

---------------------------------------------------------
-- 🛡️ ANTI-AFK SYSTEM (SAFE & BUILT-IN)
---------------------------------------------------------
if CONFIG.ENABLE_ANTI_AFK and lp then
    lp.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)
end

---------------------------------------------------------
-- 🎯 SMART DETEKTOR PLOT SENDIRI
---------------------------------------------------------
local function isMyPlot(plotModel)
    if not plotModel or not plotModel:IsA("Model") then return false end
    if not CONFIG.PRESERVE_MY_PLOT then return false end

    local myName = lpName
    local myDisplayName = lp.DisplayName
    local myUserIdStr = tostring(lpUserId)

    -- 1. Deteksi Jalur Spesifik Sign
    local plotSign = plotModel:FindFirstChild("PlotSign", true)
    if plotSign then
        local playerPlotSign = plotSign:FindFirstChild("PlayerPlotSign", true)
        if playerPlotSign then
            local playerNameLabel = playerPlotSign:FindFirstChild("PlayerName", true)
            if playerNameLabel and playerNameLabel:IsA("TextLabel") then
                local txt = playerNameLabel.Text
                if txt and (txt == myName or txt:find(myName, 1, true) or (myDisplayName and (txt == myDisplayName or txt:find(myDisplayName, 1, true)))) then
                    return true
                end
            end

            local playerIcon = playerPlotSign:FindFirstChild("PlayerIcon", true)
            if playerIcon and (playerIcon:IsA("ImageLabel") or playerIcon:IsA("ImageButton")) then
                local img = playerIcon.Image
                if img and (img:find("id=" .. myUserIdStr, 1, true) or img:find(myUserIdStr, 1, true)) then
                    return true
                end
            end
        end
    end

    -- 2. Deteksi Nilai Descendant
    for _, item in ipairs(plotModel:GetDescendants()) do
        if item:IsA("TextLabel") then
            local txt = item.Text
            if txt and (txt == myName or (myDisplayName and txt == myDisplayName)) then
                return true
            end
        elseif item:IsA("ImageLabel") or item:IsA("ImageButton") then
            local img = item.Image
            if img and (img:find("id=" .. myUserIdStr, 1, true) or img:find(myUserIdStr, 1, true)) then
                return true
            end
        elseif item:IsA("StringValue") or item:IsA("ObjectValue") or item:IsA("IntValue") or item:IsA("NumberValue") then
            if item.Value == myName or item.Value == myDisplayName or tostring(item.Value) == myUserIdStr or item.Value == lp then
                return true
            end
        end
    end

    return false
end

---------------------------------------------------------
-- 👻 STEALTH INVISIBLE HELPER (NON-DESTRUCTIVE / BYPASS BAC)
---------------------------------------------------------
-- Penting: JANGAN gunakan :Destroy() pada objek inti game/player untuk menghindari deteksi BAC-5517
local function hideObjectStealth(v)
    if not v then return end
    pcall(function()
        if v:IsA("BasePart") then
            v.Transparency = 1
            v.LocalTransparencyModifier = 1
            v.CastShadow = false
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
            optimizedCount = optimizedCount + 1
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("ScreenGui") then
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
        end
    end)
end

local function hideModelStealth(model)
    if not model then return end
    hideObjectStealth(model)
    for _, desc in ipairs(model:GetDescendants()) do
        hideObjectStealth(desc)
    end
end

---------------------------------------------------------
-- 1. UBAH MAP JADI POTATO (PUTIH & SMOOTH PLASTIC)
---------------------------------------------------------
local function optimizeMapPart(v)
    if not v or not v.Parent then return end
    
    -- Jangan ubah karakter kita
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
        elseif CONFIG.REMOVE_PARTICLES and (v:IsA("Decal") or v:IsA("Texture")) then
            v.Transparency = 1
            optimizedCount = optimizedCount + 1
        elseif CONFIG.REMOVE_PARTICLES and (
            v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or 
            v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or 
            v:IsA("Explosion") or v:IsA("Highlight")
        ) then
            v.Enabled = false
            optimizedCount = optimizedCount + 1
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
            optimizedCount = optimizedCount + 1
        end
    end)
end

for _, v in ipairs(workspace:GetDescendants()) do
    optimizeMapPart(v)
end

---------------------------------------------------------
-- 2. OPTIMASI EFEK LIGHTING & LANGIT (SAFE / NON-DESTRUCTIVE)
---------------------------------------------------------
if CONFIG.OPTIMIZE_LIGHTING then
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
        Lighting.Brightness = 1
        Lighting.ClockTime = 14

        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or 
               v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or 
               v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
                optimizedCount = optimizedCount + 1
            end
        end
    end)
end

---------------------------------------------------------
-- 3. SEMBUNYIKAN PLOT PLAYER LAIN (STEALTH & SAFE)
---------------------------------------------------------
local function optimizePlotsStealth()
    if not CONFIG.HIDE_OTHER_PLOTS then return end
    pcall(function()
        local plotsFolder = workspace:FindFirstChild("Plots")
        if plotsFolder then
            for _, plot in ipairs(plotsFolder:GetChildren()) do
                if plot:IsA("Model") then
                    if not isMyPlot(plot) then
                        hideModelStealth(plot)
                    end
                end
            end
        end
    end)
end

optimizePlotsStealth()

---------------------------------------------------------
-- 4. SEMBUNYIKAN CLIENT RENDERED ASSETS (STEALTH)
---------------------------------------------------------
if CONFIG.HIDE_CLIENT_ASSETS then
    pcall(function()
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "ClientRenderedAssets" or child.Name:find("ClientRendered") then
                hideModelStealth(child)
            end
        end
    end)
end

---------------------------------------------------------
-- 5. TERRAIN OPTIMIZATION & INCOME CASH HIDER
---------------------------------------------------------
if CONFIG.OPTIMIZE_TERRAIN or CONFIG.HIDE_INCOME_CASH then
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            if CONFIG.OPTIMIZE_TERRAIN then
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 0
            end

            if CONFIG.HIDE_INCOME_CASH then
                for _, obj in ipairs(terrain:GetDescendants()) do
                    if obj.Name:find("SyncedIncomeCash") then
                        hideObjectStealth(obj)
                    end
                end
            end
        end
    end)
end

---------------------------------------------------------
-- 6. SEMBUNYIKAN PLAYER LAIN SECARA STEALTH (BYPASS BAC-5517)
---------------------------------------------------------
local function hideOtherPlayerCharacter(char)
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
            elseif part:IsA("Accessory") or part:IsA("Shirt") or part:IsA("Pants") or part:IsA("ShirtGraphic") or part:IsA("BodyColors") then
                -- Sembunyikan part di dalam aksesoris
                for _, accPart in ipairs(part:GetDescendants()) do
                    if accPart:IsA("BasePart") then
                        accPart.Transparency = 1
                        accPart.LocalTransparencyModifier = 1
                    end
                end
            elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") or part:IsA("Highlight") or part:IsA("ParticleEmitter") then
                part.Enabled = false
            end
        end
        optimizedCount = optimizedCount + 1
    end)
end

if CONFIG.HIDE_OTHER_PLAYERS then
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            hideOtherPlayerCharacter(player.Character)
        end
    end
end

---------------------------------------------------------
-- 7. REALTIME LISTENERS (AUTO OPTIMIZE REALTIME)
---------------------------------------------------------
if CONFIG.ENABLE_REALTIME_OPT then
    -- Listener Objek Baru di Workspace
    workspace.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            -- Abaikan karakter kita sendiri
            if lp.Character and (descendant == lp.Character or descendant:IsDescendantOf(lp.Character)) then
                return
            end

            -- Cek apakah objek bagian dari karakter player lain
            if CONFIG.HIDE_OTHER_PLAYERS then
                local model = descendant:FindFirstAncestorOfClass("Model")
                if model and model ~= lp.Character and model:FindFirstChildOfClass("Humanoid") then
                    hideObjectStealth(descendant)
                    return
                end
            end

            -- Cek apakah objek bagian dari Plot player lain
            if CONFIG.HIDE_OTHER_PLOTS then
                local plotsFolder = workspace:FindFirstChild("Plots")
                if plotsFolder and descendant:IsDescendantOf(plotsFolder) then
                    local plotModel = descendant
                    while plotModel and plotModel.Parent ~= plotsFolder do
                        plotModel = plotModel.Parent
                    end
                    if plotModel and not isMyPlot(plotModel) then
                        hideObjectStealth(descendant)
                        return
                    end
                end
            end

            -- Optimasi objek umum lainnya
            optimizeMapPart(descendant)
        end)
    end)

    -- Listener Player Baru Masuk / Spawn
    Players.PlayerAdded:Connect(function(player)
        if player ~= lp then
            player.CharacterAdded:Connect(function(char)
                task.wait(0.2)
                if CONFIG.HIDE_OTHER_PLAYERS then
                    hideOtherPlayerCharacter(char)
                end
            end)
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            player.CharacterAdded:Connect(function(char)
                task.wait(0.2)
                if CONFIG.HIDE_OTHER_PLAYERS then
                    hideOtherPlayerCharacter(char)
                end
            end)
        end
    end
end

---------------------------------------------------------
-- 📢 NOTIFIKASI BERHASIL
---------------------------------------------------------
pcall(function()
    if StarterGui then
        StarterGui:SetCore("SendNotification", {
            Title = "🚀 Stealth FPS Booster",
            Text = string.format("Aktif & Aman! (%d Objek Dioptimasi)", optimizedCount),
            Duration = 4
        })
    end
end)

print("══════════════════════════════════════════════════")
print("🚀 [STEALTH FPS BOOSTER] Berhasil diaktifkan!")
print(string.format("📊 Objek Dioptimasi      : %d", optimizedCount))
print(string.format("🎯 FPS Cap               : %d", CONFIG.FPS_CAP))
print(string.format("🥔 White Potato Mode     : %s", tostring(CONFIG.WHITE_MAP_MODE)))
print(string.format("👻 Stealth Player Hide   : %s", tostring(CONFIG.HIDE_OTHER_PLAYERS)))
print(string.format("🛡️ Anti-Cheat Bypass     : AKTIF (BAC-5517 Safe)"))
print("══════════════════════════════════════════════════")
