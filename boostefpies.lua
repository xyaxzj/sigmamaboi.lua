-- ==============================================================================
-- 🚀 SIGMA ULTIMATE FPS BOOSTER & ANTI-LAG (NO UI / STANDALONE)
-- Kompatibel: Mobile (Delta, Codex, Arceus X, Hydrogen) & PC (Wave, Solara, etc.)
-- Menggabungkan seluruh metode optimasi dari Auto Train, Auto Farm Kalb, & Magic Loot
-- ==============================================================================

-- ⏳ TUNGGU GAME SELESAI LOADING
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

---------------------------------------------------------
-- ⚙️ PENGATURAN / KONFIGURASI (BISA DIUBAH SESUAI KEBUTUHAN)
---------------------------------------------------------
local CONFIG = {
    FPS_CAP             = _G.fpsCap or 240,             -- Target FPS (contoh: 5 untuk ultra AFK, 60, 120, 240)
    WHITE_MAP_MODE      = _G.whiteMap ~= nil and _G.whiteMap or true,   -- true: Ubah seluruh map jadi Putih Bersih (Potato Mode Auto Train)
    REMOVE_OTHER_PLAYER = _G.autoRemovePlayer ~= nil and _G.autoRemovePlayer or true, -- true: Hapus player lain dari client (FPS Boost Ekstrem)
    REMOVE_PLOTS_FOLDER = _G.removePlots ~= nil and _G.removePlots or true,           -- true: Hapus folder Plot 1-5 & folder Data (Auto Train & Kalb)
    STRIP_ACCESSORIES   = _G.stripAccessories ~= nil and _G.stripAccessories or true, -- true: Hapus rambut, topi, baju player lain (jika player tidak dihapus)
    DISABLE_3D_RENDER   = _G.disable3dRender or false,  -- true: Matikan 3D Rendering layar (GPU Saver Magic Loot)
    OPTIMIZE_TERRAIN    = true,                         -- true: Matikan efek ombak air & dekorasi rumput
    REMOVE_LIGHTING_FX  = true,                         -- true: Musnahkan efek bayangan, kabut, skybox, dan shader
    REMOVE_PARTICLES    = true,                         -- true: Hapus partikel, decal, tekstur, api, asap, sparkle
    ENABLE_ANTI_AFK     = true,                         -- true: Cegah disconnect idle 20 menit (Anti-AFK)
    ENABLE_REALTIME_OPT = true,                         -- true: Realtime cleaner untuk objek baru yang dimuat/di-spawn
}

-- Simpan ke _G agar sinkron dengan script lain jika diperlukan
_G.autoRemovePlayer = CONFIG.REMOVE_OTHER_PLAYER
_G.removePlayer = CONFIG.REMOVE_OTHER_PLAYER
_G.removePlayers = CONFIG.REMOVE_OTHER_PLAYER

-- 1. SET FPS CAP
pcall(function()
    if setfpscap then
        setfpscap(CONFIG.FPS_CAP)
    end
end)

-- 2. GPU SAVER (DISABLE 3D RENDERING JIKA DIAKTIFKAN)
if CONFIG.DISABLE_3D_RENDER then
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end

local cleanedCount = 0

---------------------------------------------------------
-- 🛡️ ANTI-AFK SYSTEM (BUILT-IN)
---------------------------------------------------------
if CONFIG.ENABLE_ANTI_AFK and lp then
    lp.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
            warn("⚡ [FPS Boost] Anti-AFK memicu stimulasi input virtual. Timer idle di-reset!")
        end)
    end)
end

---------------------------------------------------------
-- 1. UBAH MAP JADI POTATO (PUTIH & SMOOTH PLASTIC)
---------------------------------------------------------
local function optimizeObject(v)
    if not v or not v.Parent then return end
    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
            
            if CONFIG.WHITE_MAP_MODE then
                v.Color = Color3.new(1, 1, 1) -- Mengubah warna map jadi putih bersih
            end
            
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
            cleanedCount = cleanedCount + 1
        elseif CONFIG.REMOVE_PARTICLES and (v:IsA("Decal") or v:IsA("Texture")) then
            v:Destroy()
            cleanedCount = cleanedCount + 1
        elseif CONFIG.REMOVE_PARTICLES and (
            v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or 
            v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or 
            v:IsA("Explosion") or v:IsA("Highlight") or v:IsA("SurfaceAppearance")
        ) then
            v:Destroy()
            cleanedCount = cleanedCount + 1
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
            cleanedCount = cleanedCount + 1
        end
    end)
end

for _, v in ipairs(workspace:GetDescendants()) do
    optimizeObject(v)
end

---------------------------------------------------------
-- 2. MUSNAHKAN EFEK LIGHTING & LANGIT
---------------------------------------------------------
if CONFIG.REMOVE_LIGHTING_FX then
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        
        pcall(function()
            Lighting.ShadowMapEnabled = false
        end)

        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or 
               v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or 
               v:IsA("DepthOfFieldEffect") or v:IsA("Sky") or v:IsA("Atmosphere") or 
               v:IsA("Clouds") or v:IsA("ColorGradingEffect") then
                pcall(function() v:Destroy() end)
                cleanedCount = cleanedCount + 1
            end
        end
    end)
end

---------------------------------------------------------
-- 3. HAPUS FOLDER PLOT 1 SAMPAI 5 & FOLDER DATA (AUTO TRAIN & KALB)
---------------------------------------------------------
local function hapusPlotsDanData()
    if not CONFIG.REMOVE_PLOTS_FOLDER then return end
    pcall(function()
        -- Hapus Plots di workspace
        local plotsFolder = workspace:FindFirstChild("Plots")
        if plotsFolder then
            for i = 1, 10 do
                local plot = plotsFolder:FindFirstChild("Plot" .. tostring(i))
                if plot then
                    pcall(function() 
                        plot:Destroy() 
                        cleanedCount = cleanedCount + 1
                    end)
                end
            end
            -- Bersihkan isi plotsFolder lainnya
            for _, child in ipairs(plotsFolder:GetChildren()) do
                pcall(function() 
                    child:Destroy() 
                    cleanedCount = cleanedCount + 1
                end)
            end
        end

        -- Hapus folder Plot / Bases / PlayerData di workspace jika ada
        local folderNames = { "Plots", "PlotFolder", "PlayerPlots", "Bases", "PlayerData" }
        for _, fName in ipairs(folderNames) do
            local folder = workspace:FindFirstChild(fName)
            if folder and folder ~= workspace:FindFirstChild("Terrain") then
                pcall(function() 
                    folder:Destroy() 
                    cleanedCount = cleanedCount + 1
                end)
            end
        end
    end)
end

hapusPlotsDanData()

---------------------------------------------------------
-- 4. TERRAIN & WATER OPTIMIZATION
---------------------------------------------------------
if CONFIG.OPTIMIZE_TERRAIN then
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
            pcall(function()
                sethiddenproperty(terrain, "Decoration", false)
            end)
        end
    end)
end

---------------------------------------------------------
-- 5. ENGINE RENDERING QUALITY
---------------------------------------------------------
pcall(function()
    settings().Rendering.QualityLevel = 1
    settings().Rendering.EditQualityLevel = 1
end)
pcall(function()
    settings().Network.IncomingReplicationLag = 0
end)

---------------------------------------------------------
-- 6. PEMBANTAIAN PLAYER / REMOVE PLAYER LAIN (METODE LENGKAP & REKURSIF)
---------------------------------------------------------
local function musnahkanPlayer(player)
    if player ~= lp and player.Name ~= lpName then
        -- 1. Hapus jika wujud karakternya saat ini sudah ada di map
        if player.Character then
            pcall(function() 
                player.Character:Destroy() 
                cleanedCount = cleanedCount + 1
            end)
        end
        
        -- 2. Hapus folder data player (leaderstats, Data, PlayerData) dari client
        for _, subData in ipairs({ "leaderstats", "Data", "PlayerData", "Stats" }) do
            local d = player:FindFirstChild(subData)
            if d then
                pcall(function() d:Destroy() end)
            end
        end
        
        -- 3. Hapus objek Player fisik dari game.Players di sisi client
        pcall(function() 
            player:Destroy() 
            cleanedCount = cleanedCount + 1
        end)
    end
end

-- Strip aksesoris & baju player lain (jika player tidak dihapus total)
local function stripPlayerAccessories(char)
    if not char or char.Name == lpName then return end
    pcall(function()
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or 
               item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
                item:Destroy()
                cleanedCount = cleanedCount + 1
            elseif item:IsA("BasePart") then
                item.Material = Enum.Material.SmoothPlastic
                item.Reflectance = 0
                item.CastShadow = false
                local face = item:FindFirstChild("face") or item:FindFirstChild("Face")
                if face and face:IsA("Decal") then
                    face:Destroy()
                end
            end
        end
    end)
end

-- Fungsi periksa dan hapus Humanoid karakter player lain secara menyeluruh
local function periksaDanHapusHumanoid(descendant)
    if not CONFIG.REMOVE_OTHER_PLAYER then return end
    pcall(function()
        if descendant:IsA("Humanoid") then
            local charModel = descendant.Parent
            if charModel and charModel:IsA("Model") and charModel.Name ~= lpName and charModel ~= lp.Character then
                charModel:Destroy()
                cleanedCount = cleanedCount + 1
            end
        end
    end)
end

-- EKSEKUSI PEMBANTAIAN PLAYER AWAL
if CONFIG.REMOVE_OTHER_PLAYER then
    -- 1. Musnahkan dari list Players
    for _, player in ipairs(Players:GetPlayers()) do
        musnahkanPlayer(player)
    end

    -- 2. Musnahkan model karakter player lain di workspace secara langsung
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child.Name ~= lpName and child ~= lp.Character and child:FindFirstChildOfClass("Humanoid") then
            pcall(function() 
                child:Destroy() 
                cleanedCount = cleanedCount + 1
            end)
        end
    end

    -- 3. Musnahkan karakter player lain yang bersarang di dalam sub-folder (Characters, Entities, Players, dll)
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            local charModel = descendant.Parent
            if charModel and charModel:IsA("Model") and charModel.Name ~= lpName and charModel ~= lp.Character then
                pcall(function() 
                    charModel:Destroy() 
                    cleanedCount = cleanedCount + 1
                end)
            end
        end
    end
elseif CONFIG.STRIP_ACCESSORIES then
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            stripPlayerAccessories(player.Character)
        end
    end
end

---------------------------------------------------------
-- 7. REALTIME LISTENERS (AUTO CLEAN REALTIME & EVENT BARU)
---------------------------------------------------------
if CONFIG.ENABLE_REALTIME_OPT then
    -- Listener 1: Deteksi objek / model / humanoid baru yang dimuat di workspace
    workspace.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            -- Deteksi dan hapus Plots jika baru dimuat
            if CONFIG.REMOVE_PLOTS_FOLDER then
                if descendant.Name == "Plots" or descendant.Name:match("^Plot%d+") then
                    pcall(function() descendant:Destroy() end)
                    return
                end
            end

            -- Deteksi dan hapus Humanoid player lain
            if CONFIG.REMOVE_OTHER_PLAYER then
                if descendant:IsA("Humanoid") then
                    local charModel = descendant.Parent
                    if charModel and charModel:IsA("Model") and charModel.Name ~= lpName and charModel ~= lp.Character then
                        pcall(function() charModel:Destroy() end)
                        return
                    end
                elseif descendant:IsA("Model") and descendant.Name ~= lpName and descendant ~= lp.Character and descendant:FindFirstChildOfClass("Humanoid") then
                    pcall(function() descendant:Destroy() end)
                    return
                end
            end

            -- Optimasi material & tekstur
            optimizeObject(descendant)
        end)
    end)

    -- Listener 2: Deteksi lighting / sky baru yang dibuat game
    if CONFIG.REMOVE_LIGHTING_FX then
        Lighting.DescendantAdded:Connect(function(v)
            task.defer(function()
                if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or 
                   v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or 
                   v:IsA("DepthOfFieldEffect") or v:IsA("Sky") or v:IsA("Atmosphere") or 
                   v:IsA("Clouds") then
                    pcall(function() v:Destroy() end)
                end
            end)
        end)
    end

    -- Listener 3: Deteksi player baru yang join ke server
    Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            if CONFIG.REMOVE_OTHER_PLAYER then
                musnahkanPlayer(player)
                player.CharacterAdded:Connect(function(char)
                    task.defer(function()
                        if char and char.Name ~= lpName then
                            pcall(function() char:Destroy() end)
                        end
                    end)
                end)
            elseif CONFIG.STRIP_ACCESSORIES then
                player.CharacterAdded:Connect(function(char)
                    task.wait(0.5)
                    stripPlayerAccessories(char)
                end)
            end
        end)
    end)
end

---------------------------------------------------------
-- 📢 NOTIFIKASI BERHASIL
---------------------------------------------------------
pcall(function()
    if StarterGui then
        StarterGui:SetCore("SendNotification", {
            Title = "🚀 Ultimate FPS Boost",
            Text = string.format("Aktif! (%d Objek, Plot & Player Dimusnahkan)", cleanedCount),
            Duration = 5
        })
    end
end)

print("══════════════════════════════════════════════════")
print("🚀 [FPS BOOSTER] Berhasil diaktifkan!")
print(string.format("📊 Total Objek Dibersihkan : %d", cleanedCount))
print(string.format("🎯 FPS Cap                 : %d", CONFIG.FPS_CAP))
print(string.format("🥔 White Potato Mode       : %s", tostring(CONFIG.WHITE_MAP_MODE)))
print(string.format("💀 Hapus Player Lain       : %s", tostring(CONFIG.REMOVE_OTHER_PLAYER)))
print(string.format("🏡 Hapus Folder Plots/Data : %s", tostring(CONFIG.REMOVE_PLOTS_FOLDER)))
print("══════════════════════════════════════════════════")
