-- ==============================================================================
-- 🚀 SIGMA ULTIMATE FPS BOOSTER & ANTI-LAG (NO UI / STANDALONE)
-- Kompatibel: Mobile (Delta, Codex, Arceus X, Hydrogen) & PC (Wave, Solara, etc.)
-- Menggabungkan seluruh metode optimasi dari Auto Train, Auto Farm Kalb, & Magic Loot
-- Dilengkapi Smart Plot Detector (Menghapus plot player lain & menjaga plot kita)
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
local lpUserId = lp.UserId

---------------------------------------------------------
-- ⚙️ PENGATURAN / KONFIGURASI (BISA DIUBAH SESUAI KEBUTUHAN)
---------------------------------------------------------
local CONFIG = {
    FPS_CAP             = _G.fpsCap or 240,             -- Target FPS (contoh: 5 untuk ultra AFK, 60, 120, 240)
    WHITE_MAP_MODE      = _G.whiteMap ~= nil and _G.whiteMap or true,   -- true: Ubah seluruh map jadi Putih Bersih (Potato Mode Auto Train)
    REMOVE_OTHER_PLAYER = _G.autoRemovePlayer ~= nil and _G.autoRemovePlayer or true, -- true: Hapus player lain dari client (FPS Boost Ekstrem)
    REMOVE_PLOTS_FOLDER = _G.removePlots ~= nil and _G.removePlots or true,           -- true: Hapus folder Plot player lain & folder Data
    PRESERVE_MY_PLOT    = true,                         -- true: JANGAN hapus plot kita (Smart Detection via BillboardGui/Name/Icon)
    HIDE_CLIENT_ASSETS  = _G.hideClientAssets ~= nil and _G.hideClientAssets or true, -- true: Sembunyikan model di ClientRenderedAssets (Invisible tanpa dihapus)
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
_G.hideClientAssets = CONFIG.HIDE_CLIENT_ASSETS

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
local invisibleAssetsCount = 0

---------------------------------------------------------
-- 👻 HELPER INVISIBLE MODEL (ANTI-LAG TANPA HAPUS OBJEK)
---------------------------------------------------------
local function makeModelInvisible(obj)
    if not obj then return end
    pcall(function()
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            pcall(function() obj.LocalTransparencyModifier = 1 end)
            obj.CastShadow = false
            invisibleAssetsCount = invisibleAssetsCount + 1
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or 
               obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or 
               obj:IsA("Highlight") or obj:IsA("SurfaceAppearance") then
            pcall(function() obj.Enabled = false end)
            pcall(function() obj.Transparency = 1 end)
        elseif obj:IsA("Light") then -- PointLight, SurfaceLight, SpotLight
            obj.Enabled = false
        elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            obj.Enabled = false
        end
    end)
end

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
-- 🎯 SMART DETEKTOR PLOT SENDIRI (JANGAN HAPUS PLOT KITA)
---------------------------------------------------------
local function isMyPlot(plotModel)
    if not plotModel or not plotModel:IsA("Model") then return false end
    if not CONFIG.PRESERVE_MY_PLOT then return false end

    local myName = lpName
    local myDisplayName = lp.DisplayName
    local myUserIdStr = tostring(lpUserId)

    -- 1. Deteksi Jalur Spesifik:
    -- Plots -> [Model] -> PlotSign (Part) -> PlayerPlotSign (BillboardGui) -> Frame -> PlayerName (TextLabel) & PlayerIcon (ImageLabel)
    local plotSign = plotModel:FindFirstChild("PlotSign", true)
    if plotSign then
        local playerPlotSign = plotSign:FindFirstChild("PlayerPlotSign", true)
        if playerPlotSign then
            -- Cek TextLabel (PlayerName)
            local playerNameLabel = playerPlotSign:FindFirstChild("PlayerName", true)
            if playerNameLabel and playerNameLabel:IsA("TextLabel") then
                local txt = playerNameLabel.Text
                if txt and (txt == myName or txt:find(myName, 1, true) or (myDisplayName and (txt == myDisplayName or txt:find(myDisplayName, 1, true)))) then
                    return true
                end
            end

            -- Cek ImageLabel (PlayerIcon -> rbxthumb dengan id kita)
            local playerIcon = playerPlotSign:FindFirstChild("PlayerIcon", true)
            if playerIcon and (playerIcon:IsA("ImageLabel") or playerIcon:IsA("ImageButton")) then
                local img = playerIcon.Image
                if img and (img:find("id=" .. myUserIdStr, 1, true) or img:find(myUserIdStr, 1, true)) then
                    return true
                end
            end
        end
    end

    -- 2. Deteksi Rekursif Descendant (Menangkap semua TextLabel/ImageLabel di dalam Plot)
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

    -- 3. Deteksi via Attribute (Owner, UserId, Player)
    local ok, attributes = pcall(function() return plotModel:GetAttributes() end)
    if ok and attributes then
        for _, attrVal in pairs(attributes) do
            if attrVal == myName or attrVal == myDisplayName or tostring(attrVal) == myUserIdStr or attrVal == lpUserId then
                return true
            end
        end
    end

    return false
end

---------------------------------------------------------
-- 1. UBAH MAP JADI POTATO (PUTIH & SMOOTH PLASTIC)
---------------------------------------------------------
local function optimizeObject(v)
    if not v or not v.Parent then return end
    
    -- Jika objek berada di dalam ClientRenderedAssets dan HIDE_CLIENT_ASSETS aktif, pastikan tetap invisible
    if CONFIG.HIDE_CLIENT_ASSETS and (v.Name == "ClientRenderedAssets" or (v.Parent and v.Parent.Name == "ClientRenderedAssets") or v:FindFirstAncestor("ClientRenderedAssets")) then
        makeModelInvisible(v)
        return
    end

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
            -- Jaga agar PlayerIcon/Texture pada PlayerPlotSign kita tidak terhapus jika di dalam BillboardGui
            if not v:FindFirstAncestorOfClass("BillboardGui") then
                v:Destroy()
                cleanedCount = cleanedCount + 1
            end
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
-- 3. HAPUS FOLDER PLOTS PLAYER LAIN (SMART DETECTION)
---------------------------------------------------------
local function hapusPlotsDanData()
    if not CONFIG.REMOVE_PLOTS_FOLDER then return end
    pcall(function()
        local plotsFolder = workspace:FindFirstChild("Plots")
        if plotsFolder then
            for _, plot in ipairs(plotsFolder:GetChildren()) do
                if plot:IsA("Model") then
                    if isMyPlot(plot) then
                        print("🛡️ [Smart Plot] Menjaga Plot Milik Kita: " .. plot.Name)
                    else
                        pcall(function() 
                            plot:Destroy() 
                            cleanedCount = cleanedCount + 1
                        end)
                    end
                end
            end
        end

        -- Hapus folder Plot / Bases / PlayerData milik orang lain di workspace jika ada
        local folderNames = { "PlotFolder", "PlayerPlots", "Bases", "PlayerData" }
        for _, fName in ipairs(folderNames) do
            local folder = workspace:FindFirstChild(fName)
            if folder and folder ~= workspace:FindFirstChild("Terrain") and not isMyPlot(folder) then
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
-- 4. INVISIBLE CLIENT RENDERED ASSETS (ITEM MODEL HIDER)
---------------------------------------------------------
local function sembunyikanClientAssets()
    if not CONFIG.HIDE_CLIENT_ASSETS then return end
    
    local function processFolder(folder)
        if not folder then return end
        for _, descendant in ipairs(folder:GetDescendants()) do
            makeModelInvisible(descendant)
        end
        folder.DescendantAdded:Connect(function(descendant)
            task.defer(function()
                makeModelInvisible(descendant)
            end)
        end)
    end

    -- 1. Scan folder ClientRenderedAssets di workspace
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "ClientRenderedAssets" or child.Name:find("ClientRendered") then
            processFolder(child)
            print("👻 [Anti-Lag] Menyembunyikan (Invisible) Model di: " .. child.Name)
        end
    end

    -- 2. Scan jika berada di sub-folder
    local deepFolder = workspace:FindFirstChild("ClientRenderedAssets", true)
    if deepFolder and deepFolder.Parent ~= workspace then
        processFolder(deepFolder)
        print("👻 [Anti-Lag] Menyembunyikan (Invisible) Model di: " .. deepFolder:GetFullName())
    end
end

sembunyikanClientAssets()

---------------------------------------------------------
-- 5. TERRAIN & WATER OPTIMIZATION
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
-- 6. ENGINE RENDERING QUALITY
---------------------------------------------------------
pcall(function()
    settings().Rendering.QualityLevel = 1
    settings().Rendering.EditQualityLevel = 1
end)
pcall(function()
    settings().Network.IncomingReplicationLag = 0
end)

---------------------------------------------------------
-- 7. PEMBANTAIAN PLAYER / REMOVE PLAYER LAIN (METODE LENGKAP & REKURSIF)
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
-- 8. REALTIME LISTENERS (AUTO CLEAN REALTIME & EVENT BARU)
---------------------------------------------------------
if CONFIG.ENABLE_REALTIME_OPT then
    -- Listener 1: Deteksi objek / model / humanoid / plot / client assets baru yang dimuat di workspace
    workspace.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            -- Deteksi dan buat Invisible item di ClientRenderedAssets
            if CONFIG.HIDE_CLIENT_ASSETS then
                if descendant.Name == "ClientRenderedAssets" or (descendant.Parent and descendant.Parent.Name == "ClientRenderedAssets") or descendant:FindFirstAncestor("ClientRenderedAssets") then
                    makeModelInvisible(descendant)
                    return
                end
            end

            -- Deteksi Plot baru
            if CONFIG.REMOVE_PLOTS_FOLDER and descendant:IsA("Model") and descendant.Parent and descendant.Parent.Name == "Plots" then
                task.wait(0.3) -- Beri waktu agar BillboardGui termuat
                if not isMyPlot(descendant) then
                    pcall(function() descendant:Destroy() end)
                else
                    print("🛡️ [Smart Plot] Menjaga Plot Milik Kita yang baru dimuat: " .. descendant.Name)
                end
                return
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
            Text = string.format("Aktif! (%d Objek, Plot & Player Dibersihkan)", cleanedCount),
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
print(string.format("🏡 Smart Plot Protection   : %s", tostring(CONFIG.PRESERVE_MY_PLOT)))
print(string.format("👻 Invisible Client Assets  : %s", tostring(CONFIG.HIDE_CLIENT_ASSETS)))
print("══════════════════════════════════════════════════")
