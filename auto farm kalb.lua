-- ==============================================================================
-- 🥔 KALB ULTRA LIGHTWEIGHT AUTO FARM V3 (ULTRA ANTI-LAG & POTATO MAX EDITION)
-- ==============================================================================
-- Fitur & Alur:
-- 1. ⚙️ Full Config Mode: Semua pengaturan diatur via variabel _G di baris atas (Tanpa UI)
-- 2. 🚫 Total Player & Character Purger (100% Bersih):
--    - Menghapus & memusnahkan SEMUA player lain dari game.Players
--    - Menghapus SEMUA karakter player lain dari folder workspace.Players & workspace root
--    - Real-time listener + Background loop anti-bocor (tidak ada lagi yang lolos)
-- 3. 📚 Back To School Event 1: Math Event Auto Solver & Hitbox Expander:
--    - Mendeteksi rev_AddedWeather "MathEvent" & Model angka (1, 2, 3...) di Debris
--    - Membaca soal matematika di GuiPart.SurfaceGui.TextLabel (cth: 7+5) & menyelesaikannya otomatis
--    - Menghapus Part jawaban SALAH di folder Answers (cth: Part A = 10 dihapus)
--    - Memperbesar hitbox Part jawaban BENAR (cth: Part B = 12 diperbesar ke 200 studs, CanQuery=true)
-- 4. 🏃 Back To School Event 2: PEClass Auto Purger:
--    - Mendeteksi rev_AddedWeather "PEClass"
--    - Menghapus SEMUA Model angka (1, 2, 3...) dan Part "Ball" di Debris secara real-time
-- 5. ⚽ Auto Kick: Bot menendang bola (nonstop / saat event berlangsung)
-- 6. 💰 Auto Sell All: Menjual semua brainrot tiap 5 detik (ref_B_SellAll)
-- 7. 🥔 Potato Mode Ekstrem & 🛡️ Anti-AFK
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
-- ⚙️ KONFIGURASI PENGGUNA (UBAH SESUAI KEBUTUHAN DI SINI)
-- ==============================================================================
_G.autoFarm           = true        -- true: Auto Farm Aktif, false: Nonaktif
_G.onlyMathEvent       = false       -- true: HANYA Auto Kick saat MathEvent aktif, false: Auto kick nonstop
_G.autoMathEvent       = true        -- true: Otomatis selesaikan soal matematika, perbesar jawaban benar & hapus jawaban salah
_G.autoPEClass         = true        -- true: Otomatis hapus Model angka & Ball di Debris saat event PEClass
_G.autoSellAll         = false       -- true: Auto Sell All setiap 5 detik via ref_B_SellAll
_G.autoRemovePlayer    = true        -- true: Hapus player lain dari game.Players & workspace.Players (100% Bersih & No Lag), false: Biarkan
_G.debugConsoleLog     = true        -- true: Cetak log status/fase/soal math ke console (F9), false: Senyap
_G.failsafeTimeout     = 25          -- Waktu maksimal (detik) sebelum auto-reset ke Safe Zone jika macet

-- ⚡ ULTRA ANTI-LAG & POTATO MODE (PUSH MAX PERFORMANCE)
_G.antiLag             = true        -- true: Master switch Anti-Lag & Potato Mode Ekstrem
_G.mapVisual           = "Invisible" -- "Invisible": Visual map pure dihapus/transparan (0% beban render GPU, warna putih hilang), "Gray": Abu-abu semen polos netral, "White": Putih potato, "Default": Warna asli
_G.optimizePhysics     = true        -- true: Matikan CanTouch pada scenery map (Hemat kalkulasi CPU Physics, 100% aman untuk event)
_G.fpsCap              = 60          -- Batas target FPS (60 hemat baterai & CPU, 30 untuk multi-akun, 0 = default)
_G.disable3dRender     = false       -- true: Layar freeze / 0% GPU saat AFK farm (Pencet F10 untuk toggle), false: Tampilan visual normal
_G.muteAudio           = true        -- true: Mute semua audio & reverb game (0% beban CPU audio)
_G.cleanLighting       = true        -- true: Hapus semua efek visual di Lighting (Sky, Blur, Bloom, Atmosphere, SunRays)
_G.removeParticles     = true        -- true: Hapus ParticleEmitter, Trail, Beam, Fire, Smoke, Sparkles, Highlight, Lights
_G.optimizeTerrain     = true        -- true: Matikan gelombang air & dekorasi rumput pada terrain
_G.cleanClientAssets   = true        -- true: Sembunyikan ClientRenderedAssets & PlacedEggRenders

print("--------------------------------------------------")
print("🚀 [INIT] Memuat KALB Auto Farm V3 (Ultra Anti-Lag & Potato Max Edition)...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local UserSettingsService = (type(UserSettings) == "function" and pcall(UserSettings)) and UserSettings() or nil

local lp = Players.LocalPlayer
if not lp then
    local count = 0
    repeat
        task.wait(0.05)
        lp = Players.LocalPlayer
        count = count + 1
    until lp or count > 50
end

local lpName = lp and lp.Name or ""
local lpDisplayName = lp and lp.DisplayName or ""
local myUidStr = lp and tostring(lp.UserId) or ""

local function logConsole(...)
    if _G.debugConsoleLog ~= false then
        print(...)
    end
end

-- =============================================
-- 🛡️ FILTER & PROTEKSI ENTITAS LOKAL & MATH EVENT
-- =============================================
local function isLocalPlayerEntity(inst)
    if not inst then return false end
    if lp and inst == lp then return true end
    if lp and lp.Character and (inst == lp.Character or inst:IsDescendantOf(lp.Character)) then return true end
    local name = inst.Name
    if name == lpName or (lpDisplayName ~= "" and name == lpDisplayName) then return true end
    return false
end

local function isMathEventProtected(inst)
    if not inst then return false end
    local name = inst.Name
    if name == "GuiPart" or name == "Answers" or name == "PlotSign" or name == "KALB_SafeZoneMarker" then return true end

    local curr = inst
    while curr and curr ~= workspace and curr ~= game do
        local cName = curr.Name
        if cName == "GuiPart" or cName == "Answers" or cName == "PlotSign" or cName == "KALB_SafeZoneMarker" then
            return true
        end
        if curr:IsA("Model") and (curr:FindFirstChild("GuiPart") or curr:FindFirstChild("Answers")) then
            return true
        end
        curr = curr.Parent
    end
    return false
end

-- =============================================
-- ⚡ 1. ENGINE & HARDWARE OPTIMIZER
-- =============================================
-- Native Quality Level 1 (Engine Setting Terendah)
pcall(function()
    if settings and settings().Rendering then
        settings().Rendering.QualityLevel = 1
    end
    if UserSettingsService then
        local ugs = UserSettingsService:GetService("UserGameSettings")
        if ugs then ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end
    end
end)

-- Target FPS Cap
if _G.fpsCap and _G.fpsCap > 0 then
    pcall(function()
        if setfpscap and typeof(setfpscap) == "function" then
            setfpscap(_G.fpsCap)
        end
    end)
end

-- 3D Rendering (0% GPU AFK) & Hotkey F10 Toggle
if _G.disable3dRender then
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end

pcall(function()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F10 then
            _G.disable3dRender = not _G.disable3dRender
            pcall(function()
                RunService:Set3dRenderingEnabled(not _G.disable3dRender)
            end)
            logConsole("🎮 [3D RENDER] Toggled: " .. (_G.disable3dRender and "OFF (0% GPU AFK)" or "ON"))
        end
    end)
end)

-- Total Audio Mute (0% CPU Audio Processing)
if _G.muteAudio then
    pcall(function()
        if UserSettingsService then
            local ugs = UserSettingsService:GetService("UserGameSettings")
            if ugs then ugs.MasterVolume = 0 end
        end
        SoundService.AmbientReverb = Enum.ReverbType.NoReverb
    end)
end

-- =============================================
-- ☁️ 2. LIGHTING & ATMOSPHERE REAL-TIME PURGER
-- =============================================
local function purgeLighting()
    if not _G.cleanLighting then return end
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect")
               or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect")
               or v:IsA("DepthOfFieldEffect") or v:IsA("Sky")
               or v:IsA("Atmosphere") or v:IsA("Clouds") then
                v.Enabled = false
                v:Destroy()
            end
        end
    end)
end
purgeLighting()

Lighting.ChildAdded:Connect(function(child)
    if _G.cleanLighting then
        task.defer(function()
            if child:IsA("PostEffect") or child:IsA("BlurEffect") or child:IsA("SunRaysEffect")
               or child:IsA("ColorCorrectionEffect") or child:IsA("BloomEffect")
               or child:IsA("DepthOfFieldEffect") or child:IsA("Sky")
               or child:IsA("Atmosphere") or child:IsA("Clouds") then
                pcall(function()
                    child.Enabled = false
                    child:Destroy()
                end)
            end
        end)
    end
end)

-- =============================================
-- 🌊 3. TERRAIN & WATER OPTIMIZER
-- =============================================
if _G.optimizeTerrain then
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
            if sethiddenproperty then
                pcall(function() sethiddenproperty(terrain, "Decoration", false) end)
            end
        end
    end)
end

-- =============================================
-- 🥚 4. CLIENT ASSETS & PLACED EGGS PURGER
-- =============================================
local function cleanClientAssets()
    if not _G.cleanClientAssets then return end
    pcall(function()
        local eggFolder = workspace:FindFirstChild("PlacedEggRenders")
        if eggFolder then
            for _, d in ipairs(eggFolder:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Transparency = 1
                    d.CastShadow = false
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    d:Destroy()
                end
            end
        end
        local clientAssets = workspace:FindFirstChild("ClientRenderedAssets")
        if clientAssets then
            for _, d in ipairs(clientAssets:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Transparency = 1
                    d.CastShadow = false
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    d:Destroy()
                end
            end
        end
    end)
end
cleanClientAssets()

-- =============================================
-- 🥔 5. CORE INSTANCE OPTIMIZER (SMOOTHPLASTIC, WHITE MAP & PURGE FX)
-- =============================================
local PURGE_CLASSES = {
    PointLight = true,
    SpotLight = true,
    SurfaceLight = true,
    ParticleEmitter = true,
    Trail = true,
    Beam = true,
    Fire = true,
    Smoke = true,
    Sparkles = true,
    SurfaceAppearance = true,
    Highlight = true,
}

local function optimizeInstance(v)
    if not _G.antiLag or not v or not v.Parent then return end
    if isLocalPlayerEntity(v) then return end
    if isMathEventProtected(v) then return end

    pcall(function()
        local className = v.ClassName

        -- 1. Mute suara individual (Hemat CPU audio mixer)
        if _G.muteAudio and v:IsA("Sound") then
            v.Volume = 0
            if v.Looped and v.Playing then v:Stop() end
            return
        end

        -- 2. Purge partikel, cahaya, dan efek visual berat (Hemat GPU shader & draw calls)
        if _G.removeParticles and PURGE_CLASSES[className] then
            v:Destroy()
            return
        end

        -- 3. Hapus Decal, Texture, Clothing, ShirtGraphic
        if className == "Decal" or className == "Texture" or v:IsA("Clothing") or v:IsA("ShirtGraphic") then
            v:Destroy()
            return
        end

        -- 4. Matikan BillboardGui / SurfaceGui non-math & non-PlayerGui
        if (v:IsA("BillboardGui") or v:IsA("SurfaceGui")) and not v:IsDescendantOf(lp:WaitForChild("PlayerGui", 1)) then
            v.Enabled = false
            v:Destroy()
            return
        end

        -- 5. Potato Mesh & BasePart (Invisible / Gray / White Map)
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false

            local mode = _G.mapVisual or (_G.whiteMap and "White" or "Default")
            if mode == "Invisible" then
                v.Transparency = 1
            elseif mode == "Gray" then
                v.Color = Color3.fromRGB(140, 140, 140)
            elseif mode == "White" then
                v.Color = Color3.new(1, 1, 1)
            end

            if v:IsA("MeshPart") then
                v.TextureID = ""
            end

            -- Physics Optimizer: Matikan CanTouch pada objek scenery mati (Hemat CPU physics, CanCollide tetap aktif agar lantai tidak jebol)
            if _G.optimizePhysics then
                v.CanTouch = false
            end
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        end
    end)
end

-- Safe Zone Visual Marker (Penanda titik Safe Zone saat Map Invisible)
local function ensureSafeZoneMarker()
    if _G.mapVisual ~= "Invisible" then return end
    pcall(function()
        local existing = workspace:FindFirstChild("KALB_SafeZoneMarker")
        if not existing then
            local marker = Instance.new("Part")
            marker.Name = "KALB_SafeZoneMarker"
            marker.Size = Vector3.new(12, 0.2, 12)
            marker.Position = Vector3.new(698.030701, 3.2, 233.707077)
            marker.Anchored = true
            marker.CanCollide = false
            marker.CanTouch = false
            marker.CanQuery = false
            marker.Material = Enum.Material.Neon
            marker.Color = Color3.fromRGB(0, 255, 128)
            marker.Transparency = 0.6
            marker.Parent = workspace
        end
    end)
end
ensureSafeZoneMarker()

-- Eksekusi awal pembersihan aset ke seluruh workspace
task.spawn(function()
    if _G.antiLag then
        for _, v in ipairs(workspace:GetDescendants()) do
            optimizeInstance(v)
        end
        logConsole("🚀 [ANTI-LAG] Ultra Potato Mode & Hardware Engine Berhasil Diaktifkan!")
    end
end)

-- Listener Real-Time DescendantAdded untuk Workspace
workspace.DescendantAdded:Connect(function(descendant)
    if _G.antiLag then
        task.defer(optimizeInstance, descendant)
    end
end)

-- =============================================
-- 🚫 6. TOTAL PLAYER & CHARACTER PURGER (100% BERSIH)
-- =============================================
local function purgeOtherPlayer(player)
    if not _G.autoRemovePlayer or not player or player == lp or player.Name == lpName then return end
    
    pcall(function()
        if player.Character then
            player.Character:ClearAllChildren()
            player.Character:Destroy()
        end
    end)
    pcall(function()
        player:ClearAllChildren()
        player:Destroy()
    end)
end

local function purgeOtherCharacter(charModel)
    if not _G.autoRemovePlayer or not charModel then return end
    if isLocalPlayerEntity(charModel) then return end
    if charModel.Name == "Plots" or charModel.Name == "Debris" or charModel.Name == "NPCs" then return end

    pcall(function()
        for _, v in ipairs(charModel:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Transparency = 1
                v.CanCollide = false
                v.CanTouch = false
                v.CanQuery = false
            elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("Highlight") then
                v.Enabled = false
                v:Destroy()
            end
        end
        charModel:ClearAllChildren()
        charModel:Destroy()
    end)
end

local function scanAndPurgeAllOtherPlayers()
    if not _G.autoRemovePlayer then return end

    -- 1. Bersihkan dari game:GetService("Players")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            purgeOtherPlayer(p)
        end
    end
    for _, child in ipairs(Players:GetChildren()) do
        if child ~= lp and child:IsA("Player") then
            purgeOtherPlayer(child)
        end
    end

    -- 2. Bersihkan dari workspace.Players folder
    local wsPlayers = workspace:FindFirstChild("Players")
    if wsPlayers then
        for _, child in ipairs(wsPlayers:GetChildren()) do
            if child.Name ~= "Plots" and not isLocalPlayerEntity(child) then
                purgeOtherCharacter(child)
            end
        end
    end

    -- 3. Bersihkan dari workspace root (karakter liar)
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and not isLocalPlayerEntity(child) and child.Name ~= "Plots" and child.Name ~= "Debris" and child.Name ~= "NPCs" and child.Name ~= "Players" then
            if child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Head") then
                purgeOtherCharacter(child)
            end
        end
    end
end

-- Eksekusi awal pembersihan player & karakter
scanAndPurgeAllOtherPlayers()

-- Event Listener saat ada Player baru join
Players.PlayerAdded:Connect(function(player)
    if not _G.autoRemovePlayer then return end
    if player ~= lp then
        task.defer(function()
            purgeOtherPlayer(player)
        end)
        player.CharacterAdded:Connect(function(char)
            task.defer(function()
                purgeOtherCharacter(char)
            end)
        end)
    end
end)

Players.ChildAdded:Connect(function(child)
    if not _G.autoRemovePlayer then return end
    if child ~= lp and child:IsA("Player") then
        task.defer(function()
            purgeOtherPlayer(child)
        end)
    end
end)

-- Listener khusus untuk workspace.Players
local function setupWsPlayersListener(folder)
    if not folder then return end
    for _, child in ipairs(folder:GetChildren()) do
        if child.Name ~= "Plots" and not isLocalPlayerEntity(child) then
            purgeOtherCharacter(child)
        end
    end
    folder.ChildAdded:Connect(function(child)
        if not _G.autoRemovePlayer then return end
        task.defer(function()
            if child.Name ~= "Plots" and not isLocalPlayerEntity(child) then
                purgeOtherCharacter(child)
            end
        end)
    end)
end

local wsPlayers = workspace:FindFirstChild("Players")
if wsPlayers then
    setupWsPlayersListener(wsPlayers)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Players" then
        task.defer(function() setupWsPlayersListener(child) end)
    elseif child:IsA("Model") and not isLocalPlayerEntity(child) and child.Name ~= "Plots" and child.Name ~= "Debris" and child.Name ~= "NPCs" then
        task.defer(function()
            if child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Head") then
                purgeOtherCharacter(child)
            end
        end)
    end
end)

-- Background Sweeper Loop (Menjamin 0% Player Lolos & Bersihkan RAM)
task.spawn(function()
    local cleanCounter = 0
    while task.wait(0.25) do
        if _G.autoRemovePlayer then
            pcall(scanAndPurgeAllOtherPlayers)
        end

        cleanCounter = cleanCounter + 1
        -- Tiap 10 detik bersihkan client assets & refresh lighting
        if cleanCounter % 40 == 0 then
            pcall(cleanClientAssets)
            pcall(purgeLighting)
        end

        -- Tiap 30 detik jalankan garbage collector
        if cleanCounter >= 120 then
            cleanCounter = 0
            pcall(function()
                if gcinfo then gcinfo() end
                if collectgarbage then collectgarbage("collect") end
            end)
        end
    end
end)

-- =============================================
-- 🎯 DETEKTOR PLOT SENDIRI & REMOVER PLOT LAIN
-- =============================================
local function isMyPlot(plotModel)
    if not plotModel or not plotModel:IsA("Model") then return false end

    local sign = plotModel:FindFirstChild("PlotSign", true)
    if sign then
        local pps = sign:FindFirstChild("PlayerPlotSign", true)
        if pps then
            local nameLabel = pps:FindFirstChild("PlayerName", true)
            if nameLabel and nameLabel:IsA("TextLabel") then
                local t = nameLabel.Text
                if t and (t == lpName or t:find(lpName, 1, true) or (lpDisplayName ~= "" and (t == lpDisplayName or t:find(lpDisplayName, 1, true)))) then
                    return true
                end
            end
            local icon = pps:FindFirstChild("PlayerIcon", true)
            if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
                local img = icon.Image
                if img and img:find(myUidStr, 1, true) then
                    return true
                end
            end
        end
    end

    for _, item in ipairs(plotModel:GetDescendants()) do
        local ok, result = pcall(function()
            if item:IsA("TextLabel") then
                local t = item.Text
                if t and (t == lpName or (lpDisplayName ~= "" and t == lpDisplayName)) then
                    return true
                end
            elseif item:IsA("StringValue") or item:IsA("ObjectValue") or item:IsA("IntValue") or item:IsA("NumberValue") then
                local v = item.Value
                if v == lpName or v == lp or tostring(v) == myUidStr then
                    return true
                end
            end
            return false
        end)
        if ok and result then return true end
    end

    return false
end

local function cleanPlots(plotsFolder)
    if not plotsFolder then return end
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") and not isMyPlot(plot) then
            pcall(function() plot:Destroy() end)
        end
    end
    plotsFolder.ChildAdded:Connect(function(plot)
        task.wait(0.2)
        if plot:IsA("Model") and not isMyPlot(plot) then
            pcall(function() plot:Destroy() end)
        end
    end)
end

local plotsFolder = workspace:FindFirstChild("Plots") or (workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Plots"))
if plotsFolder then
    cleanPlots(plotsFolder)
end

-- =============================================
-- 📚 BACK TO SCHOOL EVENT 1 & 2: MATH EVENT & PECLASS ENGINE (UNBREAKABLE AFK V2)
-- =============================================
local OPTIMAL_ANSWER_SIZE = Vector3.new(200, 200, 200)
local isMathEventActive = true -- Default Aktif Langsung
local isPEClassActive = false
local modelLastSolvedQuestion = {} -- Melacak soal terakhir per model: [model] = "7+5"

-- Bersihkan cache model yang sudah dihancurkan
local function pruneProcessedCache()
    for model, _ in pairs(modelLastSolvedQuestion) do
        if not model or not model.Parent then
            modelLastSolvedQuestion[model] = nil
        end
    end
end

-- Evaluator Matematika Super Kuat (Mendukung +, -, *, /, x, X, ×, ÷, :, serta format teks RichText)
local function solveMathExpression(rawText)
    if not rawText or rawText == "" then return nil end
    local str = tostring(rawText)

    -- Bersihkan tag HTML / RichText (<font>...</font>, <stroke>...</stroke>)
    str = str:gsub("<[^>]+>", "")

    -- Bersihkan tanda sama dengan dan tanda tanya
    str = str:gsub("=%s*%?", ""):gsub("=", ""):gsub("%?", "")

    -- Coba ekstrak pola 2 angka dengan operator matematika (cth: "7 + 5", "14 + 16", "12 x 4", "20 ÷ 5")
    local num1Str, op, num2Str = str:match("(%-?%d+%.?%d*)%s*([%+%-%*%/xX×÷:])%s*(%-?%d+%.?%d*)")
    if num1Str and op and num2Str then
        local n1 = tonumber(num1Str)
        local n2 = tonumber(num2Str)
        if n1 and n2 then
            if op == "+" then return n1 + n2
            elseif op == "-" then return n1 - n2
            elseif op == "*" or op == "x" or op == "X" or op == "×" then return n1 * n2
            elseif (op == "/" or op == "÷" or op == ":") and n2 ~= 0 then return n1 / n2
            end
        end
    end

    -- Konversi simbol perkalian & pembagian global
    local cleanStr = str:gsub("×", "*"):gsub("x", "*"):gsub("X", "*"):gsub("÷", "/"):gsub(":", "/")
    cleanStr = cleanStr:gsub("%s+", "")
    cleanStr = cleanStr:gsub("[^%d%+%-%*%/%.%(%)]", "")

    if cleanStr ~= "" then
        local func = loadstring and loadstring("return " .. cleanStr)
        if func then
            local ok, val = pcall(func)
            if ok and type(val) == "number" then
                return val
            end
        end
    end

    return nil
end

local function parseAnswerValue(rawText)
    if not rawText or rawText == "" then return nil end
    local str = tostring(rawText)
    str = str:gsub("<[^>]+>", "")
    
    -- Ekstrak angka murni dari string (cth: "12", "A) 12", "Ans: 12")
    local numMatch = str:match("(%-?%d+%.?%d*)")
    if numMatch then
        local val = tonumber(numMatch)
        if val then return val end
    end

    return solveMathExpression(str)
end

-- Deteksi apakah sebuah Model adalah Model Soal Matematika
local function isTargetQuestionModel(model)
    if not model or not model:IsA("Model") then return false end
    local hasGui = model:FindFirstChild("GuiPart") or model:FindFirstChild("GuiPart", true)
    local hasAns = model:FindFirstChild("Answers") or model:FindFirstChild("Answers", true)
    if hasGui and hasAns then return true end
    if tonumber(model.Name) ~= nil and (hasGui or hasAns) then return true end
    return false
end

-- Cari Model Soal dari komponen apapun di dalamnya
local function getQuestionModelFromInstance(inst)
    if not inst or inst == workspace or inst == game then return nil end
    local curr = inst
    while curr and curr ~= workspace and curr ~= game do
        if curr:IsA("Model") and isTargetQuestionModel(curr) then
            return curr
        end
        curr = curr.Parent
    end
    return nil
end

-- =============================================
-- 🏃 DETEKTOR & PURGER PECLASS (MODEL ANGKA & BALL)
-- =============================================
local function isPEClassBall(inst)
    if not inst then return false end
    local lowerName = string.lower(inst.Name)
    if lowerName == "ball" or string.find(lowerName, "ball") then
        return true
    end
    return false
end

local function isPEClassModel(model)
    if not model or not model:IsA("Model") then return false end
    if tonumber(model.Name) == nil then return false end
    if isTargetQuestionModel(model) then return false end
    return true
end

local function scanAndPurgePEClass()
    if not _G.autoPEClass then return end
    local debris = workspace:FindFirstChild("Debris")
    local containers = {workspace}
    if debris then table.insert(containers, debris) end

    for _, container in ipairs(containers) do
        -- 1. Scan semua Ball di seluruh hierarki
        for _, desc in ipairs(container:GetDescendants()) do
            if isPEClassBall(desc) then
                pcall(function()
                    logConsole(string.format("🏃 [PECLASS PURGE] Menghapus Ball '%s' (%s)!", desc.Name, desc.ClassName))
                    desc:Destroy()
                end)
            end
        end

        -- 2. Scan Model Angka PEClass (Model angka murni tanpa GuiPart & tanpa Answers)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Model") and (tonumber(child.Name) ~= nil or child.Name:match("^%d+$")) then
                local hasGui = child:FindFirstChild("GuiPart") or child:FindFirstChild("GuiPart", true)
                local hasAns = child:FindFirstChild("Answers") or child:FindFirstChild("Answers", true)
                if not hasGui and not hasAns then
                    pcall(function()
                        logConsole(string.format("🏃 [PECLASS PURGE] Menghapus Model Angka PEClass '%s'!", child.Name))
                        child:Destroy()
                    end)
                end
            end
        end
    end
end

-- =============================================
-- 🧠 PROSES & SOLVE SOAL MATEMATIKA REAL-TIME
-- =============================================
local function processMathQuestionModel(model)
    if not _G.autoMathEvent then return end
    if not model or not model.Parent then return end

    local guiPart = model:FindFirstChild("GuiPart") or model:FindFirstChild("GuiPart", true)
    local answersFolder = model:FindFirstChild("Answers") or model:FindFirstChild("Answers", true)

    -- Tunggu hingga GuiPart dan Answers folder ada
    if not guiPart or not answersFolder then return end

    -- Cari TextLabel pada GuiPart
    local questionLabel = guiPart:FindFirstChildWhichIsA("TextLabel", true)
    if not questionLabel then return end

    local qText = questionLabel.ContentText ~= "" and questionLabel.ContentText or questionLabel.Text
    if not qText or qText == "" then return end

    -- Jika soal pada model ini sudah diselesaikan, lewati
    if modelLastSolvedQuestion[model] == qText then return end

    local correctAnswer = solveMathExpression(qText)
    if correctAnswer == nil then return end

    -- Ambil semua opsi jawaban dari folder Answers
    local answerItems = {}
    for _, child in ipairs(answersFolder:GetChildren()) do
        if child:IsA("BasePart") or child.ClassName == "Part" or child:IsA("Model") then
            local targetPart = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true)
            local ansLabel = child:FindFirstChildWhichIsA("TextLabel", true)
            if ansLabel and targetPart then
                local ansText = ansLabel.ContentText ~= "" and ansLabel.ContentText or ansLabel.Text
                if ansText and ansText ~= "" then
                    local ansVal = parseAnswerValue(ansText)
                    if ansVal ~= nil then
                        table.insert(answerItems, {part = targetPart, val = ansVal, text = ansText, obj = child})
                    end
                end
            end
        end
    end

    if #answerItems == 0 then
        return
    end

    modelLastSolvedQuestion[model] = qText
    isMathEventActive = true

    logConsole(string.format("📚 [MATH EVENT] Soal #%s: '%s' -> Kunci Jawaban: %s", tostring(model.Name), tostring(qText), tostring(correctAnswer)))

    -- Bersihkan partikel visual berat pada model soal
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("ParticleEmitter") or desc:IsA("Fire") or desc:IsA("Smoke") or 
           desc:IsA("Trail") or desc:IsA("PointLight") or desc:IsA("SpotLight") then
            pcall(function() desc:Destroy() end)
        end
    end

    -- Eksekusi pembesaran jawaban benar & penghapusan jawaban salah
    local foundCorrect = false
    for _, item in ipairs(answerItems) do
        local isCorrect = (math.abs(item.val - correctAnswer) < 0.0001)

        if isCorrect and not foundCorrect then
            foundCorrect = true
            -- JAWABAN BENAR: Perbesar Hitbox (200x200x200) & aktifkan CanTouch/CanQuery
            pcall(function()
                item.part.CanCollide = false
                item.part.CanTouch = true
                item.part.CanQuery = true
                item.part.CastShadow = false
                item.part.Transparency = 0.5
                if item.part.Size ~= OPTIMAL_ANSWER_SIZE then
                    item.part.Size = OPTIMAL_ANSWER_SIZE
                end
            end)
            logConsole(string.format("   ✅ [JAWABAN BENAR] Part %s ('%s') diperbesar ke 200 studs!", item.part.Name, tostring(item.text)))
        else
            -- JAWABAN SALAH: Hapus Part agar tidak tersentuh bola/karakter!
            pcall(function()
                item.obj:Destroy()
            end)
            logConsole(string.format("   ❌ [JAWABAN SALAH] Part %s ('%s') dihapus!", item.part.Name, tostring(item.text)))
        end
    end
end

-- =============================================
-- 📡 PEMINDAI UNIVERSAL WORKSPACE & DEBRIS
-- =============================================
local function scanAndProcessAllMath()
    pruneProcessedCache()
    if not _G.autoMathEvent and not _G.autoPEClass then return end

    local debris = workspace:FindFirstChild("Debris")
    local containers = {workspace}
    if debris then table.insert(containers, debris) end

    -- 1. Purge PEClass
    if _G.autoPEClass then
        scanAndPurgePEClass()
    end

    -- 2. Scan model soal matematika
    if _G.autoMathEvent then
        for _, container in ipairs(containers) do
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Model") then
                    if isTargetQuestionModel(child) then
                        task.defer(processMathQuestionModel, child)
                    end
                end
            end
        end
    end
end

-- Listener DescendantAdded pada Workspace (Menangkap model soal instan di mana pun berada)
workspace.DescendantAdded:Connect(function(descendant)
    task.defer(function()
        if not descendant or not descendant.Parent then return end

        -- 1. Deteksi Ball PEClass Instan (Hapus seketika)
        if _G.autoPEClass and isPEClassBall(descendant) then
            pcall(function()
                logConsole(string.format("🏃 [PECLASS PURGE] Menghapus Ball '%s'!", descendant.Name))
                descendant:Destroy()
            end)
            return
        end

        -- 2. Deteksi Model Angka PEClass Instan (Tunggu 0.08s untuk validasi bahwa ini bukan soal Math)
        if _G.autoPEClass and descendant:IsA("Model") and (tonumber(descendant.Name) ~= nil or descendant.Name:match("^%d+$")) then
            task.wait(0.08)
            if descendant and descendant.Parent then
                local hasGui = descendant:FindFirstChild("GuiPart") or descendant:FindFirstChild("GuiPart", true)
                local hasAns = descendant:FindFirstChild("Answers") or descendant:FindFirstChild("Answers", true)
                if not hasGui and not hasAns then
                    pcall(function()
                        logConsole(string.format("🏃 [PECLASS PURGE] Menghapus Model Angka PEClass '%s'!", descendant.Name))
                        descendant:Destroy()
                    end)
                    return
                end
            end
        end

        -- 3. Deteksi Math Event Instan
        if _G.autoMathEvent then
            if descendant.Name == "GuiPart" or descendant.Name == "Answers" or descendant:IsA("TextLabel") or descendant.Name == "A" or descendant.Name == "B" then
                local model = getQuestionModelFromInstance(descendant)
                if model then
                    processMathQuestionModel(model)
                end
            elseif descendant:IsA("Model") and isTargetQuestionModel(descendant) then
                processMathQuestionModel(descendant)
            end
        end
    end)
end)

-- Background Scanner Loop (tiap 0.1 detik)
task.spawn(function()
    while task.wait(0.1) do
        pcall(scanAndProcessAllMath)
    end
end)

-- Scan awal saat script pertama kali jalan
task.spawn(function()
    task.wait(0.1)
    pcall(scanAndProcessAllMath)
end)

-- =============================================
-- 🧠 VARIABEL STATE MACHINE & POSISI
-- =============================================
local targetAction = "Idle"
local lastAction = "Idle"
local stateTimer = 0               
local globalStuckTimer = 0         
local mutationCount = 0            
local lastRewardDesc = "None"
local kickRetryCount = 0
local MAX_KICK_RETRIES = 2
local kickAcceptedByServer = false
local safeZone = Vector3.new(698.030701, 3.298559, 233.707077)
local safeZoneCFrame = CFrame.new(698.030701, 3.298559, 233.707077, -0.061024, -0.000000, 0.998136, -0.000000, 1.000000, 0.000000, -0.998136, -0.000000, -0.061024)

local function logConsole(msg)
    if _G.debugConsoleLog then
        print(string.format("🤖 [KALB-FARM] [%s] %s", tostring(targetAction), tostring(msg)))
    end
end

local function checkMathEventActive()
    if isMathEventActive then return true end
    local debris = workspace:FindFirstChild("Debris")
    if debris then
        for _, child in ipairs(debris:GetChildren()) do
            if child:IsA("Model") and tonumber(child.Name) ~= nil then
                isMathEventActive = true
                return true
            end
        end
    end
    return false
end

local function shouldKick()
    if not _G.autoFarm then return false end
    if _G.onlyMathEvent then
        return checkMathEventActive()
    end
    return true
end

-- =============================================
-- 🛡️ ANTI AFK (MURNI TANPA KLIK APAPUN)
-- =============================================
pcall(function()
    if getconnections then
        for _, conn in ipairs(getconnections(lp.Idled)) do
            conn:Disable()
        end
    end
end)

lp.Idled:Connect(function()
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(lp.Idled)) do
                conn:Disable()
            end
        end
        if VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)

-- =============================================
-- 📡 DAFTAR REMOTE NETWORK RESMI & AUTO-RESOLVER
-- =============================================
local networkFolder = nil
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
    local packages = shared and (shared:FindFirstChild("Packages") or shared:WaitForChild("Packages", 3))
    networkFolder = packages and (packages:FindFirstChild("Network") or packages:WaitForChild("Network", 3))
end)

local function findRemote(name, className)
    if networkFolder then
        local r = networkFolder:FindFirstChild(name)
        if r and (not className or r:IsA(className)) then return r end
    end
    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
        if r.Name == name and (not className or r:IsA(className)) then
            return r
        end
    end
    return nil
end

local ref_KickEvent = findRemote("ref_KickEvent", "RemoteFunction")
local kickRemote = findRemote("rev_KickEvent", "RemoteEvent")
local rev_kickPhase2 = findRemote("rev_kickPhase2", "RemoteEvent")
local rev_Collected = findRemote("rev_Collected", "RemoteEvent")
local rev_KickEventEnded = findRemote("rev_KickEventEnded", "RemoteEvent")
local rev_AddedWeather = findRemote("rev_AddedWeather", "RemoteEvent")
local rev_RemovedWeather = findRemote("rev_RemovedWeather", "RemoteEvent")

local ref_B_SellAll = findRemote("ref_B_SellAll", "RemoteFunction")

-- =============================================
-- 💰 AUTO SELL ALL (SETIAP 5 DETIK)
-- =============================================
task.spawn(function()
    while task.wait(5) do
        if not _G.autoFarm or not _G.autoSellAll then continue end
        pcall(function()
            local sellRemote = ref_B_SellAll or (networkFolder and networkFolder:FindFirstChild("ref_B_SellAll"))
            if sellRemote then
                sellRemote:InvokeServer()
            end
        end)
    end
end)

-- =============================================
-- 🎮 LAPIS 1: ULTRA-LIGHTWEIGHT CONTROLLER HOOK (ZERO-FREEZE & NON-BLOCKING)
-- =============================================
local cachedGameController = nil

local function getGameController()
    if cachedGameController and type(cachedGameController.Kick) == "function" then
        return cachedGameController
    end

    if getgc then
        local ok, tables = pcall(function() return getgc(true) end)
        if ok and type(tables) == "table" then
            for _, item in ipairs(tables) do
                if type(item) == "table" then
                    if rawget(item, "CanKick") ~= nil and type(rawget(item, "Kick")) == "function" then
                        cachedGameController = item
                        return item
                    end
                end
            end
        end
    end

    return nil
end

-- Pre-fetch controller saat script pertama kali dimuat
task.spawn(function()
    task.wait(1)
    getGameController()
end)

-- =============================================
-- 📡 LISTENER EVENT SERVER (REAL-TIME RECEPTOR)
-- =============================================
local phase2Fired = false
local collectedFired = false
local kickEndedFired = false

local function setupServerEventListeners()
    local p2 = rev_kickPhase2 or findRemote("rev_kickPhase2", "RemoteEvent")
    if p2 then
        p2.OnClientEvent:Connect(function(rewardTable, ...)
            phase2Fired = true
            pcall(function()
                if type(rewardTable) == "table" and rewardTable[1] then
                    lastRewardDesc = string.format("%s [%s]", tostring(rewardTable[1].Name or "Brainrot"), tostring(rewardTable[1].Mutation or "Normal"))
                    logConsole(string.format("🎉 Gacha Reward Masuk: %s", lastRewardDesc))
                end
            end)
        end)
    end

    local col = rev_Collected or findRemote("rev_Collected", "RemoteEvent")
    if col then
        col.OnClientEvent:Connect(function(...)
            collectedFired = true
        end)
    end

    local ended = rev_KickEventEnded or findRemote("rev_KickEventEnded", "RemoteEvent")
    if ended then
        ended.OnClientEvent:Connect(function(...)
            kickEndedFired = true
        end)
    end

    local addW = rev_AddedWeather or findRemote("rev_AddedWeather", "RemoteEvent")
    if addW then
        addW.OnClientEvent:Connect(function(weatherType, ...)
            if weatherType == "MathEvent" then
                isMathEventActive = true
                logConsole("📚 Event Cuaca: MATH EVENT AKTIF! Memulai Auto Solver & Hitbox Expander...")
            elseif weatherType == "PEClass" then
                isPEClassActive = true
                logConsole("🏃 Event Cuaca: PECLASS AKTIF! Memulai Auto Purger (Model Angka & Ball)...")
                scanAndPurgePEClass()
            end
        end)
    end

    local remW = rev_RemovedWeather or findRemote("rev_RemovedWeather", "RemoteEvent")
    if remW then
        remW.OnClientEvent:Connect(function(weatherType, ...)
            if weatherType == "MathEvent" then
                isMathEventActive = false
                logConsole("☁️ Event Cuaca: Math Event Selesai. Standby di Safe Zone...")
            elseif weatherType == "PEClass" then
                isPEClassActive = false
                logConsole("☁️ Event Cuaca: PEClass Selesai. Standby di Safe Zone...")
            end
        end)
    end
end
setupServerEventListeners()

-- =============================================
-- 📚 DETEKSI MATH EVENT REAL-TIME (MULTI-SOURCE)
-- =============================================
local function checkMathEventActive()
    if isMathEventActive then return true end
    local debris = workspace:FindFirstChild("Debris")
    if debris then
        for _, child in ipairs(debris:GetChildren()) do
            if child:IsA("Model") and tonumber(child.Name) ~= nil then
                isMathEventActive = true
                return true
            end
        end
    end
    return false
end

local function shouldKick()
    if not _G.autoFarm then return false end
    if _G.onlyMathEvent then
        return checkMathEventActive()
    end
    return true
end

-- =============================================
-- 🚀 FUNGSI EKSEKUSI TENDANGAN REINFORCED (LAPIS 1 + LAPIS 3 NETWORK)
-- =============================================
local function executeKick()
    local timestamp = nil
    pcall(function() timestamp = workspace:GetServerTimeNow() end)
    if not timestamp or type(timestamp) ~= "number" or timestamp <= 0 then
        timestamp = tick()
    end

    logConsole("⚡ Mengeksekusi Kick (Lapis 1 Controller Hook + Lapis 3 Network)...")

    -- 🎮 LAPIS 1: Direct GameController Hook (Buka Kunci Cooldown & Panggil Kick Asli di Game)
    pcall(function()
        local controller = getGameController()
        if controller then
            if controller.UnblockKick then pcall(function() controller:UnblockKick() end) end
            if controller.ResetCooldown then pcall(function() controller:ResetCooldown() end) end
            controller.CanKick = true
            if controller.InGame ~= nil then controller.InGame = false end
            if controller.Status ~= nil and controller.Status == "InKick" then controller.Status = "Lobby" end
            pcall(function() controller:Kick(1, 1) end)
        end
    end)

    -- 📡 LAPIS 3: Network Remote Invocation (Jalur Resmi Server Non-Blocking & Konfirmasi Sukses)
    task.spawn(function()
        pcall(function()
            local targetRemote = ref_KickEvent or (networkFolder and networkFolder:FindFirstChild("ref_KickEvent"))
            if not targetRemote then
                for _, r in pairs(ReplicatedStorage:GetDescendants()) do
                    if r:IsA("RemoteFunction") and r.Name == "ref_KickEvent" then
                        targetRemote = r
                        ref_KickEvent = r
                        break
                    end
                end
            end

            if targetRemote and targetRemote:IsA("RemoteFunction") then
                local res = targetRemote:InvokeServer(1, 1, timestamp)
                if res == true or (type(res) == "table" and res[1] == true) then
                    kickAcceptedByServer = true
                    logConsole("✅ [SERVER CONFIRMED] Tendangan resmi terdaftar di server! Bola sedang terbang...")
                end
            end

            local fallbackEvent = kickRemote or (networkFolder and networkFolder:FindFirstChild("rev_KickEvent"))
            if fallbackEvent and fallbackEvent:IsA("RemoteEvent") then
                fallbackEvent:FireServer(1, 1, timestamp)
            end
        end)
    end)
end

-- =============================================
-- ⚙️ MAIN LOOP (STATE MACHINE AUTO FARM)
-- =============================================
task.spawn(function()
    while task.wait(0.05) do
        if not _G.autoFarm then continue end

        local char = lp.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not hum or not hrp then continue end 

        -- [ PENDETEKSI MATI & RESPAWN ]
        if hum.Health <= 0 then
            targetAction = "WaitingRespawn"
            lastAction = "WaitingRespawn"
            globalStuckTimer = 0
            kickRetryCount = 0
            kickAcceptedByServer = false
            continue 
        end

        if targetAction == "WaitingRespawn" and hum.Health > 0 then
            targetAction = "Idle"
            lastAction = "Idle"
            kickRetryCount = 0
            kickAcceptedByServer = false
            stateTimer = 0
            logConsole("Karakter Respawn -> Berjalan ke Safe Zone sebelum Kick...")
        end

        -- [ PENGATUR WAKTU & FAILSAFE RESET (MURNI JALAN TANPA TELEPORT) ]
        if targetAction ~= lastAction then
            globalStuckTimer = 0
            stateTimer = 0 
            lastAction = targetAction
            logConsole("Transisi Fase -> " .. tostring(targetAction))
        else
            globalStuckTimer = globalStuckTimer + 0.05
            stateTimer = stateTimer + 0.05 
            
            local maxTimeout = _G.failsafeTimeout or 45
            if globalStuckTimer >= maxTimeout and targetAction ~= "WalkToSafeZone" then
                globalStuckTimer = 0
                stateTimer = 0
                targetAction = "Idle"
                logConsole("🚨 Failsafe Triggered: Reset ke Idle")
                continue
            end
        end

        local distToSafeZone = (hrp.Position - safeZone).Magnitude

        -- [ FASE 1: IDLE / NENDANG DI SAFE ZONE (MURNI JALAN KAKI - TANPA TELEPORT) ]
        if targetAction == "Idle" then
            if distToSafeZone > 5 then
                hum:MoveTo(safeZone)
            else
                if shouldKick() then
                    if stateTimer >= 0.15 then
                        pcall(function()
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end)
                        kickRetryCount = 0
                        kickAcceptedByServer = false
                        phase2Fired = false
                        collectedFired = false
                        kickEndedFired = false
                        executeKick()
                        targetAction = "WaitingForPhase2"
                    end
                else
                    task.wait(0.1)
                end
            end

        -- [ FASE 2: NUNGGU PHASE 2 DARI SERVER -> LANGSUNG JALAN KE SAFEZONE ]
        elseif targetAction == "WaitingForPhase2" then
            if phase2Fired or collectedFired or kickEndedFired then
                phase2Fired = false
                kickRetryCount = 0
                kickAcceptedByServer = false
                targetAction = "WalkToSafeZone"
                logConsole("Phase 2 Selesai / Lucky Block Kena -> Langsung Jalan ke Safe Zone")

            -- Kondisi 1: Kick belum terdaftar sama sekali di server setelah 3 detik -> Retry
            elseif not kickAcceptedByServer and stateTimer >= 3.0 and not phase2Fired and not collectedFired and not kickEndedFired then
                if kickRetryCount < MAX_KICK_RETRIES then
                    kickRetryCount = kickRetryCount + 1
                    stateTimer = 0
                    logConsole(string.format("⚠️ [RETRY] Kick belum terdaftar di server, mencoba kick ulang #%d/%d...", kickRetryCount, MAX_KICK_RETRIES))
                    executeKick()
                else
                    logConsole(string.format("🚨 [FAILSAFE] Gagal respon setelah %d kali retry! Memaksa Respawn/Reset Karakter...", MAX_KICK_RETRIES))
                    kickRetryCount = 0
                    kickAcceptedByServer = false
                    stateTimer = 0
                    targetAction = "WaitingRespawn"
                    pcall(function()
                        if hum then hum.Health = 0 end
                        if char then char:BreakJoints() end
                    end)
                end

            -- Kondisi 2: Kick sudah diterima server (bola sedang terbang), tunggu hingga maksimal 20 detik
            elseif stateTimer >= 20.0 then
                kickAcceptedByServer = false
                targetAction = "WalkToSafeZone"
                logConsole("Phase 2 Timeout (20s) -> Lanjut Jalan ke Safe Zone")
            end

        -- [ FASE 3: JALAN MURNI SAMPAI KE SAFE ZONE (TANPA TELEPORT) ]
        elseif targetAction == "WalkToSafeZone" then
            pcall(function()
                if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
                if hrp.Anchored then hrp.Anchored = false end
            end)
            hum:MoveTo(safeZone)
            if distToSafeZone < 5 then
                targetAction = "WaitingForCollected"
                logConsole("Tiba di Safe Zone -> Menunggu Reward Collected")
            end

        -- [ FASE 4: NUNGGU COLLECTED & RE-KICK INSTAN / STOP JIKA METEOR BERAKHIR ]
        elseif targetAction == "WaitingForCollected" then
            if distToSafeZone >= 5 then
                hum:MoveTo(safeZone)
            end

            if collectedFired or kickEndedFired or stateTimer >= 2.5 then
                collectedFired = false
                kickEndedFired = false
                mutationCount = mutationCount + 1
                phase2Fired = false
                kickRetryCount = 0
                kickAcceptedByServer = false

                if shouldKick() then
                    executeKick()
                    targetAction = "WaitingForPhase2"
                    logConsole(string.format("🎉 Total Mutasi: %d | Re-Kick Langsung!", mutationCount))
                else
                    targetAction = "Idle"
                    logConsole(string.format("🎉 Total Mutasi: %d | Ronde Tuntas -> Standby di Safe Zone (Menunggu Event Meteor)", mutationCount))
                end
            end
        end
    end
end)

print("--------------------------------------------------")
print("🚀 [SUKSES] KALB Meteor Shower Auto Farm Siap Berjalan!")
print("--------------------------------------------------")
