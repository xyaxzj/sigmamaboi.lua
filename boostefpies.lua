-- ==============================================================================
-- 🚀 SIGMA ULTIMATE FPS BOOSTER & ANTI-LAG (NO UI / STANDALONE)
-- Kompatibel: Mobile (Delta, Codex, Arceus X, Hydrogen) & PC (Wave, Solara, etc.)
-- Menggabungkan seluruh metode optimasi dari Auto Train, Auto Farm Kalb, & Magic Loot
-- ==============================================================================

---------------------------------------------------------
-- ⚙️ PENGATURAN / KONFIGURASI (BISA DIUBAH SESUAI KEBUTUHAN)
---------------------------------------------------------
local CONFIG = {
    FPS_CAP             = 240,              -- Target FPS (contoh: 5 untuk ultra AFK, 60, 120, 240)
    WHITE_MAP_MODE      = true,   -- true: Ubah seluruh map jadi Putih Bersih (Potato Mode Auto Train)
    REMOVE_OTHER_PLAYER = true, -- true: Hapus player lain dari client (FPS Boost Ekstrem Auto Farm Kalb)
    STRIP_ACCESSORIES   = _G.stripAccessories ~= nil and _G.stripAccessories or true, -- true: Hapus rambut, topi, baju player lain (jika player tidak dihapus)
    DISABLE_3D_RENDER   = _G.disable3dRender or false,  -- true: Matikan 3D Rendering layar (GPU Saver Magic Loot)
    OPTIMIZE_TERRAIN    = true,                         -- true: Matikan efek ombak air & dekorasi rumput
    REMOVE_LIGHTING_FX  = true,                         -- true: Musnahkan efek bayangan, kabut, skybox, dan shader
    REMOVE_PARTICLES    = true,                         -- true: Hapus partikel, decal, tekstur, api, asap, sparkle
    ENABLE_ANTI_AFK     = true,                         -- true: Cegah disconnect idle 20 menit (Anti-AFK)
    ENABLE_REALTIME_OPT = true,                         -- true: Realtime cleaner untuk objek baru yang dimuat/di-spawn
}

-- 1. SET FPS CAP
pcall(function()
    if setfpscap then
        setfpscap(CONFIG.FPS_CAP)
    end
end)

-- 2. GPU SAVER (DISABLE 3D RENDERING JIKA DIAKTIFKAN)
if CONFIG.DISABLE_3D_RENDER then
    pcall(function()
        game:GetService("RunService"):Set3dRenderingEnabled(false)
    end)
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local lp = Players.LocalPlayer

local cleanedCount = 0

---------------------------------------------------------
-- 🛡️ ANTI-AFK SYSTEM
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
-- 3. TERRAIN & WATER OPTIMIZATION
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
-- 4. ENGINE RENDERING QUALITY
---------------------------------------------------------
pcall(function()
    settings().Rendering.QualityLevel = 1
    settings().Rendering.EditQualityLevel = 1
end)
pcall(function()
    settings().Network.IncomingReplicationLag = 0
end)

---------------------------------------------------------
-- 5. PEMBANTAIAN PLAYER / STRIP AKSESORIS PLAYER LAIN
---------------------------------------------------------
local function musnahkanPlayer(player)
    if player ~= lp then
        if player.Character then
            pcall(function() player.Character:Destroy() end)
        end
        pcall(function() player:Destroy() end)
        cleanedCount = cleanedCount + 1
    end
end

local function stripPlayerAccessories(char)
    if not char or char.Name == lp.Name then return end
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

if CONFIG.REMOVE_OTHER_PLAYER then
    for _, player in ipairs(Players:GetPlayers()) do
        musnahkanPlayer(player)
    end
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child.Name ~= lp.Name and child:FindFirstChildOfClass("Humanoid") then
            pcall(function() child:Destroy() end)
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
-- 6. REALTIME LISTENERS (AUTO CLEAN OBJEK BARU)
---------------------------------------------------------
if CONFIG.ENABLE_REALTIME_OPT then
    -- Bersihkan part / partikel baru yang dimuat
    workspace.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            if CONFIG.REMOVE_OTHER_PLAYER and descendant:IsA("Humanoid") then
                local charModel = descendant.Parent
                if charModel and charModel:IsA("Model") and charModel.Name ~= lp.Name then
                    pcall(function() charModel:Destroy() end)
                end
                return
            end
            optimizeObject(descendant)
        end)
    end)

    -- Bersihkan lighting / sky baru jika game mencoba mengubahnya
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

    -- Listener untuk player baru yang join
    Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            if CONFIG.REMOVE_OTHER_PLAYER then
                musnahkanPlayer(player)
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
            Title = "🚀 FPS Booster",
            Text = string.format("FPS Boost Aktif! (%d Objek Dioptimalkan)", cleanedCount),
            Duration = 5
        })
    end
end)

print(string.format("══════════════════════════════════════════════════"))
print(string.format("🚀 [FPS BOOSTER] Berhasil diaktifkan!"))
print(string.format("📊 Objek Dibersihkan : %d", cleanedCount))
print(string.format("🎯 FPS Cap           : %d", CONFIG.FPS_CAP))
print(string.format("🥔 White Potato Mode : %s", tostring(CONFIG.WHITE_MAP_MODE)))
print(string.format("💀 Hapus Player Lain : %s", tostring(CONFIG.REMOVE_OTHER_PLAYER)))
print(string.format("══════════════════════════════════════════════════"))
