-- ==============================================================================
-- 🥔 KALB ULTRA LIGHTWEIGHT AUTO FARM V5.0 (SAFE ANTI-LAG & CANDY EVENT EDITION)
-- ==============================================================================
-- Fitur & Alur:
-- 1. ⚙️ Full Config Mode: Semua pengaturan diatur via variabel _G di baris atas (Tanpa UI)
-- 2. 🚫 Total Player & Character Purger (100% Bersih & No Lag)
-- 3. 🍬 Candy Weather Event Engine:
--    - Mendeteksi rev_AddedWeather "Candy" & rev_candySpawn
--    - Hitbox, Navigasi Waypoint & Debris Checker
--    - Mendukung CarriedCandy, Candy, Chocolate, Cake, Pancakes, Gummy Bear, Ice Cream, dll.
-- 4. 🧭 Candy Waypoint Navigation: Sembari membawa brainrot berjalan ke safe zone, melewati titik permen
-- 5. 💀 Empty Spawn Handler: Jika rev_candySpawn mengirim {}, diam di tempat sampai mati & respawn
-- 6. ⚡ Teleportation for Kick: Teleportasi instan ke safe zone saat Idle, Respawn, atau timeout kick
-- 7. 🥔 Safe Potato & Anti-Lag V5.0:
--    - Container Emptying (Decor, Walls, Shops, Leaderboards, NPCs, Machines, Portal, Sell)
--    - PlayerGui Optimizer (Enabled = false & Proteksi TouchGui HP)
--    - Map Gray Semen, Purge Partikel/Lampu/Decal & Purge Lighting
--    - Disarm error loop DecorationsHandler 60 FPS
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
-- ⚙️ KONFIGURASI PENGGUNA (UBAH SESUAI KEBUTUHAN DI SINI)
-- ==============================================================================
_G.autoFarm             = true        -- true: Auto Farm Aktif, false: Nonaktif
_G.onlyCandyEvent       = false       -- true: HANYA Auto Kick saat Candy Event aktif, false: Auto kick nonstop

-- 🍬 PENGATURAN FITUR CANDY EVENT (DAPAT DIAKTIFKAN / DINONAKTIFKAN SECARA TERPISAH)
_G.enableCandyEvent     = true        -- [1] Master Switch: Aktifkan penanganan Candy Event (cuaca & spawn permen)
_G.expandCandyHitbox    = false        -- [2] Hitbox Switch: Memperbesar hitbox Candy/Cokelat/dll ke ukuran yang ditentukan
_G.candyHitboxSize      = Vector3.new(100, 100, 100) -- Ukuran hitbox Candy yang dibesarkan
_G.candyWaypointNav     = true        -- [3] Navigation Switch: Pandu rute jalan kaki melintasi waypoint permen ke Safe Zone
_G.candyReachDist       = 1           -- Jarak dasar (studs) horizontal untuk menganggap permen sudah terlewati/terambil (Auto-scaled saat speed kencang)
_G.candyAntiOvershoot   = true        -- [4] Anti-Overshoot & Drift: Redam momentum saat lari kencang agar tidak muter-muter / miss
_G.verifyDebrisPickup   = true        -- [5] Debris Checker: Pastikan barang di Debris hilang saat dibawa; jika belum hilang, kembali ke waypoint
_G.enableFireTouch      = false       -- [6] FireTouch Switch: true: picu firetouchinterest instan, false: nonaktif (murni fisik/hitbox)

_G.useBrainrotWhitelist = true        -- true: Hanya bawa brainrot di whitelist ke safe zone, false: Bawa semua
_G.brainrotWhitelist    = {           -- Daftar nama brainrot yang diizinkan (Case-insensitive & Partial match)
    "Chocolate Gangster",
    "Tricerabob",
    "Teacherrina",
}
_G.kickDelay            = 0.5         -- Jeda waktu (detik) di Safe Zone sebelum menendang/kick (Default: 0.5 detik, jangan terlalu instant)
_G.autoSellAll          = true       -- true: Auto Sell All setiap 5 detik via ref_B_SellAll
_G.autoWorldTeleport    = true        -- true: Teleport otomatis 1x saat baru dieksekusi via rev_WORLD_TP, false: Nonaktif
_G.targetWorld          = 2           -- Target ID World untuk teleportasi otomatis (Default: 2)
_G.autoRemovePlayer     = true        -- true: Hapus player lain dari game.Players & workspace.Players (100% Bersih & No Lag), false: Biarkan
_G.debugConsoleLog      = true        -- true: Cetak log status/fase/candy ke console (F9), false: Senyap
_G.failsafeTimeout      = 25          -- Waktu maksimal (detik) sebelum auto-reset ke Safe Zone jika macet

-- ⚡ ANTI-LAG & POTATO MODE
_G.antiLag             = true        -- true: Master switch Anti-Lag (Hapus Folder/Model target, PlayerGui, Partikel, Lighting, Map Gray)
_G.fpsCap              = 60          -- Batas target FPS (60 hemat baterai & CPU, 30 untuk multi-akun, 0 = default)
_G.disable3dRender     = false       -- true: Layar freeze / 0% GPU saat AFK farm (Pencet F10 untuk toggle), false: Tampilan visual normal
_G.muteAudio           = true        -- true: Mute semua audio & reverb game (0% beban CPU audio)

print("--------------------------------------------------")
print("🚀 [INIT] Memuat KALB Auto Farm V5.0 (Safe Potato & Anti-Lag Edition)...")
print("✨ [VERSION] Build: V5.0 | Feature: Container Emptying & TouchGui Safe")
print("--------------------------------------------------")

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

local targetAction = "Idle"
local lastAction = "Idle"

local function logConsole(...)
    if _G.debugConsoleLog == false then return end
    local count = select("#", ...)
    if count == 1 then
        local msg = select(1, ...)
        print(string.format("🤖 [KALB-FARM] [%s] %s", tostring(targetAction), tostring(msg)))
    else
        print(...)
    end
end

-- =============================================
-- 🛡️ FILTER & PROTEKSI ENTITAS LOKAL & CANDY EVENT
-- =============================================
local CANDY_NAMES = {
    ["carriedcandy"] = true,
    ["candy"] = true,
    ["chocolate"] = true,
    ["cake"] = true,
    ["pancakes"] = true,
    ["gummy bear"] = true,
    ["ice cream"] = true,
    ["gummy worm"] = true,
}

local function registerCandyName(name)
    if not name or name == "" then return end
    CANDY_NAMES[string.lower(name)] = true
end

local function isCandyItem(inst)
    if not inst then return false end
    local lowerName = string.lower(inst.Name)
    if CANDY_NAMES[lowerName] then return true end
    for candyName, _ in pairs(CANDY_NAMES) do
        if string.find(lowerName, candyName, 1, true) then
            return true
        end
    end
    return false
end

local function isLocalPlayerEntity(inst)
    if not inst then return false end
    if lp and inst == lp then return true end
    if lp and lp.Character and (inst == lp.Character or inst:IsDescendantOf(lp.Character)) then return true end
    local name = inst.Name
    if name == lpName or (lpDisplayName ~= "" and name == lpDisplayName) then return true end
    return false
end

local function isProtectedEventItem(inst)
    if not inst then return false end
    local name = inst.Name
    if name == "PlotSign" or name == "KALB_SafeZoneMarker" then return true end
    if isCandyItem(inst) then return true end

    local p = inst.Parent
    if not p or p == workspace or p == game then return false end

    local curr = p
    while curr and curr ~= workspace and curr ~= game do
        local cName = curr.Name
        if cName == "PlotSign" or cName == "KALB_SafeZoneMarker" or isCandyItem(curr) then
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
        for _, sg in ipairs(SoundService:GetDescendants()) do
            if sg:IsA("SoundGroup") then
                sg.Volume = 0
            end
        end
    end)
end

-- =============================================
-- 🗑️ 1. WORKSPACE TARGETS PURGER (FOLDERS & MODELS)
-- =============================================
local WORKSPACE_REMOVE_NAMES = {
    -- Folders:
    ["decor"] = true,
    ["walls"] = true,
    ["shops"] = true,
    ["exclusiveproducts"] = true,
    ["leaderboards"] = true,
    ["npcs"] = true,
    -- Models:
    ["admin machine"] = true,
    ["barriers"] = true,
    ["freegift"] = true,
    ["fusemachine"] = true,
    ["machine"] = true,
    ["poolbillboard"] = true,
    ["kickupgrades"] = true,
    ["portal"] = true,
    ["sell"] = true,
}

-- Matikan listener OnPreRender dari script game DecorationsHandler agar tidak memicu error spam 60 FPS
local function disableDecorationsHandler()
    pcall(function()
        if getconnections then
            local signals = { RunService.PreRender, RunService.RenderStepped, RunService.Heartbeat, RunService.Stepped }
            for _, sig in ipairs(signals) do
                for _, conn in ipairs(getconnections(sig)) do
                    pcall(function()
                        local func = conn.Function
                        if func then
                            local info = debug.getinfo and debug.getinfo(func)
                            local src = info and info.source or tostring(func)
                            if string.find(string.lower(src), "decorationshandler") then
                                if conn.Disable then
                                    conn:Disable()
                                elseif conn.Disconnect then
                                    conn:Disconnect()
                                end
                            end
                        end
                    end)
                end
            end
        end
    end)
end
disableDecorationsHandler()

local function shouldRemoveWorkspaceTarget(inst)
    if not inst or not inst.Parent then return false end
    if isLocalPlayerEntity(inst) or isProtectedEventItem(inst) then return false end
    local lower = string.lower(inst.Name)
    return WORKSPACE_REMOVE_NAMES[lower] == true
end

local function isInsideTargetContainer(inst)
    if not inst or not inst.Parent then return false end
    local curr = inst.Parent
    while curr and curr ~= workspace and curr ~= game do
        local lower = string.lower(curr.Name)
        if WORKSPACE_REMOVE_NAMES[lower] then
            return true
        end
        curr = curr.Parent
    end
    return false
end

local function handleWorkspaceTarget(inst)
    if not inst or not inst.Parent then return false end
    if isLocalPlayerEntity(inst) or isProtectedEventItem(inst) then return false end

    -- Kasus 1: Instansiasi adalah wadah target itu sendiri (Folder / Model)
    if shouldRemoveWorkspaceTarget(inst) then
        pcall(function()
            if inst:IsA("Folder") or inst:IsA("Model") then
                -- Kosongkan seluruh isinya (0% beban render GPU, bebas error "Parent is locked")
                inst:ClearAllChildren()
            else
                inst:Destroy()
            end
        end)
        return true
    end

    -- Kasus 2: Instansiasi adalah objek baru yang dimasukkan ke dalam wadah target yang sudah dikosongkan
    if isInsideTargetContainer(inst) then
        pcall(function()
            inst:Destroy()
        end)
        return true
    end

    return false
end

local function purgeWorkspaceTargets()
    if not _G.antiLag then return end
    for _, child in ipairs(workspace:GetChildren()) do
        handleWorkspaceTarget(child)
    end
    for _, desc in ipairs(workspace:GetDescendants()) do
        handleWorkspaceTarget(desc)
    end
end

-- =============================================
-- 📱 2. PLAYERGUI OPTIMIZER (HIDE ALL SCREENGUI - 0% GPU DRAW CALLS)
-- =============================================
local function disableGuiElement(child)
    if not child then return end
    pcall(function()
        -- Jangan matikan kontrol layar sentuh HP (analog & tombol lompat)
        if child.Name == "TouchGui" then return end

        if child:IsA("ScreenGui") or child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
            child.Enabled = false
        end
    end)
end

local function purgePlayerGui()
    if not _G.antiLag then return end
    pcall(function()
        local playerGui = lp and (lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 5))
        if not playerGui then return end
        for _, child in ipairs(playerGui:GetChildren()) do
            disableGuiElement(child)
        end
        if not playerGui:GetAttribute("Kalb_CleanHooked") then
            playerGui:SetAttribute("Kalb_CleanHooked", true)
            playerGui.ChildAdded:Connect(function(child)
                if not _G.antiLag then return end
                task.defer(disableGuiElement, child)
            end)
        end
    end)
end

if lp then
    purgePlayerGui()
    lp.CharacterAdded:Connect(function()
        task.wait(0.2)
        purgePlayerGui()
    end)
end

-- =============================================
-- ☁️ 3. LIGHTING & ATMOSPHERE PURGER
-- =============================================
local function purgeLighting()
    if not _G.antiLag then return end
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
    if not _G.antiLag then return end
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
end)

-- Terrain & Water Optimization
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

-- =============================================
-- 🌫️ 4. MAP GRAY & PARTIKEL EFEK PURGER
-- =============================================
local PURGE_PARTICLE_CLASSES = {
    ParticleEmitter = true,
    Trail = true,
    Beam = true,
    Fire = true,
    Smoke = true,
    Sparkles = true,
    PointLight = true,
    SpotLight = true,
    SurfaceLight = true,
    SurfaceAppearance = true,
}

local GRAY_COLOR = Color3.fromRGB(140, 140, 140)

local function optimizeInstance(v)
    if not _G.antiLag or not v or not v.Parent then return end
    if isLocalPlayerEntity(v) then return end
    if isProtectedEventItem(v) then return end

    pcall(function()
        local className = v.ClassName

        -- 1. Hapus partikel efek & sumber cahaya
        if PURGE_PARTICLE_CLASSES[className] then
            v:Destroy()
            return
        end

        -- 2. Highlight: matikan agar tidak memberatkan rendering / crash AnimateBrainrots
        if v:IsA("Highlight") then
            v.Enabled = false
            return
        end

        -- 3. Mute audio individual jika _G.muteAudio
        if _G.muteAudio and v:IsA("Sound") then
            v.Volume = 0
            return
        end

        -- 4. Hapus Decal, Texture, pakaian visual
        if className == "Decal" or className == "Texture" or v:IsA("Clothing") or v:IsA("ShirtGraphic") then
            v:Destroy()
            return
        end

        -- 5. Ubah seluruh map menjadi Gray polos (SmoothPlastic)
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
            v.Color = GRAY_COLOR

            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        end
    end)
end

-- Eksekusi awal pembersihan aset target, PlayerGui, dan map Gray
task.spawn(function()
    if _G.antiLag then
        purgeWorkspaceTargets()
        purgePlayerGui()

        local all = workspace:GetDescendants()
        local count = 0
        for _, v in ipairs(all) do
            if not handleWorkspaceTarget(v) then
                optimizeInstance(v)
            end
            count = count + 1
            if count % 500 == 0 then
                task.wait()
            end
        end
        logConsole("🚀 [ANTI-LAG] Workspace Targets Purged, PlayerGui Hidden & Map Gray Applied!")
    end
end)

-- Listener Real-Time DescendantAdded untuk Workspace
workspace.DescendantAdded:Connect(function(descendant)
    if not _G.antiLag then return end
    if handleWorkspaceTarget(descendant) then
        return
    end
    task.defer(optimizeInstance, descendant)
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

-- Background Sweeper Loop (Backup sweeper dengan interval santai agar hemat CPU)
task.spawn(function()
    local cleanCounter = 0
    while task.wait(3.0) do
        if _G.autoRemovePlayer then
            pcall(scanAndPurgeAllOtherPlayers)
        end

        cleanCounter = cleanCounter + 1
        -- Tiap ~30 detik pastikan target terhapus & refresh lighting & playergui
        if cleanCounter % 10 == 0 then
            pcall(disableDecorationsHandler)
            pcall(purgeLighting)
            pcall(purgePlayerGui)
            pcall(purgeWorkspaceTargets)
        end

        -- Tiap ~60 detik jalankan garbage collector bertahap (non-blocking step)
        if cleanCounter >= 20 then
            cleanCounter = 0
            pcall(function()
                if collectgarbage then collectgarbage("step", 100) end
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
    task.spawn(function()
        task.wait(1.5) -- Beri waktu agar plot lokal selesai dimuat server sebelum membersihkan plot lain
        cleanPlots(plotsFolder)
    end)
end

-- =============================================
-- 🍬 CANDY WEATHER EVENT ENGINE (HITBOX EXPANDER & WAYPOINT SYSTEM)
-- =============================================
local function isCandyEventEnabled()
    if _G.enableCandyEvent ~= nil then
        return _G.enableCandyEvent == true
    end
    if _G.autoCandyEvent ~= nil then
        return _G.autoCandyEvent == true
    end
    return true
end

local function isHitboxExpanderEnabled()
    if _G.expandCandyHitbox ~= nil then
        return _G.expandCandyHitbox == true
    end
    if _G.autoCandyEvent ~= nil then
        return _G.autoCandyEvent == true
    end
    return true
end

local function isWaypointNavEnabled()
    if _G.candyWaypointNav ~= nil then
        return _G.candyWaypointNav == true
    end
    return true
end

local CANDY_HITBOX_SIZE = _G.candyHitboxSize or Vector3.new(200, 200, 200)
local isCandyEventActive = false
local expandedCandyObjects = setmetatable({}, { __mode = "k" })

local function expandCandyHitbox(inst)
    if not isHitboxExpanderEnabled() or not inst or not inst.Parent then return end
    if not isCandyItem(inst) then return end
    if expandedCandyObjects[inst] then return end

    pcall(function()
        local targetSize = _G.candyHitboxSize or CANDY_HITBOX_SIZE
        local partsExpanded = 0
        if inst:IsA("BasePart") then
            inst.CanCollide = false
            inst.CanTouch = true
            inst.CanQuery = true
            inst.CastShadow = false
            inst.Transparency = 0.5
            if inst.Size ~= targetSize then
                inst.Size = targetSize
            end
            partsExpanded = partsExpanded + 1
        elseif inst:IsA("Model") then
            for _, p in ipairs(inst:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                    p.CanTouch = true
                    p.CanQuery = true
                    p.CastShadow = false
                    p.Transparency = 0.5
                    if p.Size ~= targetSize then
                        p.Size = targetSize
                    end
                    partsExpanded = partsExpanded + 1
                end
            end
        end
        if partsExpanded > 0 then
            expandedCandyObjects[inst] = true
            logConsole(string.format("🍬 [CANDY HITBOX] '%s' (%d part) berhasil diperbesar ke 200 studs!", inst.Name, partsExpanded))
        end
    end)
end

-- Pemindai semua permen di Debris
local function scanAndExpandAllCandies()
    if not isHitboxExpanderEnabled() then return end

    -- Bersihkan cache item yang sudah musnah
    for obj, _ in pairs(expandedCandyObjects) do
        if not obj or not obj.Parent then
            expandedCandyObjects[obj] = nil
        end
    end

    local debris = workspace:FindFirstChild("Debris")
    if debris then
        for _, child in ipairs(debris:GetChildren()) do
            if isCandyItem(child) then
                expandCandyHitbox(child)
            end
        end
    end
end

-- Listener Debris (Menangkap permen baru instan di folder Debris)
local function hookDebrisListener(debrisFolder)
    if not debrisFolder then return end
    debrisFolder.ChildAdded:Connect(function(child)
        task.defer(function()
            if not child or not child.Parent then return end
            if isHitboxExpanderEnabled() and isCandyItem(child) then
                expandCandyHitbox(child)
            end
        end)
    end)
end

local initialDebris = workspace:FindFirstChild("Debris")
if initialDebris then
    hookDebrisListener(initialDebris)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Debris" then
        task.defer(function() hookDebrisListener(child) end)
    end
end)

-- Background Scanner Loop Candy (tiap 0.8 detik sebagai backup listener)
task.spawn(function()
    while task.wait(0.8) do
        pcall(scanAndExpandAllCandies)
    end
end)

-- Scan awal saat script pertama kali jalan
task.spawn(function()
    task.wait(0.1)
    pcall(scanAndExpandAllCandies)
end)

-- =============================================
-- 🔍 PEMERIKSA STATUS BARANG DI DEBRIS
-- =============================================
local function getDebrisItemPosition(inst)
    if not inst or not inst.Parent then return nil end
    local ok, pos = pcall(function()
        if inst:IsA("BasePart") then
            return inst.Position
        elseif inst:IsA("Model") then
            if inst.PrimaryPart then
                return inst.PrimaryPart.Position
            end
            local bp = inst:FindFirstChildWhichIsA("BasePart", true)
            if bp then return bp.Position end
            return inst:GetPivot().Position
        end
        return nil
    end)
    return (ok and pos) or nil
end

-- 🍬 EKSEKUTOR SENTUHAN INSTAN (FIRETOUCHINTEREST SUPPORT)
local function touchCandyItem(inst, charHrp)
    if not _G.enableFireTouch then return end
    if not inst or not charHrp then return end
    pcall(function()
        if firetouchinterest then
            if inst:IsA("BasePart") then
                firetouchinterest(charHrp, inst, 0)
                task.wait()
                firetouchinterest(charHrp, inst, 1)
            elseif inst:IsA("Model") then
                if inst.PrimaryPart then
                    firetouchinterest(charHrp, inst.PrimaryPart, 0)
                    task.wait()
                    firetouchinterest(charHrp, inst.PrimaryPart, 1)
                end
                for _, p in ipairs(inst:GetChildren()) do
                    if p:IsA("BasePart") then
                        firetouchinterest(charHrp, p, 0)
                        task.wait()
                        firetouchinterest(charHrp, p, 1)
                    end
                end
            end
        end
    end)
end

-- Mencari apakah barang/permen di dekat koordinat waypoint masih ada di folder Debris
-- Mengembalikan: itemInstance (jika masih ada), jarakHorizontal, posisiItem
local function findItemInDebrisNear(pos, maxDist)
    local debris = workspace:FindFirstChild("Debris")
    if not debris or not pos then return nil, math.huge, nil end
    local searchDist = maxDist or 80
    local closestItem = nil
    local closestDist = math.huge
    local closestPos = nil

    for _, child in ipairs(debris:GetChildren()) do
        if isCandyItem(child) then
            local p = getDebrisItemPosition(child)
            if p then
                local d = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(p.X, 0, p.Z)).Magnitude
                if d <= searchDist and d < closestDist then
                    closestDist = d
                    closestItem = child
                    closestPos = p
                end
            end
        end
    end

    return closestItem, closestDist, closestPos
end

-- =============================================
-- 🧠 VARIABEL STATE MACHINE & POSISI
-- =============================================
local stateTimer = 0               
local globalStuckTimer = 0         
local mutationCount = 0            
local lastRewardDesc = "None"
local kickRetryCount = 0
local MAX_KICK_RETRIES = 2
local kickAcceptedByServer = false
local safeZone = Vector3.new(698.030701, 3.298559, 233.707077)
local safeZoneCFrame = CFrame.new(698.030701, 3.298559, 233.707077, -0.061024, -0.000000, 0.998136, -0.000000, 1.000000, 0.000000, -0.998136, -0.000000, -0.061024)

-- Variabel Navigasi Permen & Anti-Stuck Watchdog
local activeCandyWaypoints = {}
local currentWaypointTarget = nil
local waypointStuckTimer = 0
local emptyCandySpawnReceived = false
local lastRewardBrainrotName = ""

-- Teleportasi Instan ke Safe Zone (Dipakai saat Kick / Idle / Respawn / Timeout)
local function teleportToSafeZone(hrp)
    if not hrp then return end
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = safeZoneCFrame
    end)
end

local cachedWeatherService = nil
local function getWeatherService()
    if cachedWeatherService ~= nil then return cachedWeatherService end
    local ok, res = pcall(function()
        local svLoader = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("ServicesLoader")
        if svLoader and svLoader:FindFirstChild("WeatherService_Client") then
            return require(svLoader.WeatherService_Client)
        end
        return nil
    end)
    if ok and res then
        cachedWeatherService = res
        return res
    end
    return nil
end

local function isWeatherServiceCandyActive()
    local ws = getWeatherService()
    if ws and type(ws.Events) == "table" then
        local now = os.time()
        for eName, endTs in pairs(ws.Events) do
            if string.find(string.lower(tostring(eName)), "candy") then
                if type(endTs) ~= "number" or endTs > now then
                    return true
                end
            end
        end
    end
    return false
end

local function checkCandyEventActive()
    if isCandyEventActive then return true end
    if isWeatherServiceCandyActive() then
        isCandyEventActive = true
        return true
    end
    -- HANYA cek folder Debris (JANGAN cek workspace karena ada objek dekorasi map statis)
    local debris = workspace:FindFirstChild("Debris")
    if debris then
        for _, child in ipairs(debris:GetChildren()) do
            if isCandyItem(child) then
                isCandyEventActive = true
                return true
            end
        end
    end
    return false
end

local function isCandyEventOngoing()
    if not isCandyEventEnabled() then return false end
    if isCandyEventActive then return true end
    if #activeCandyWaypoints > 0 then return true end
    if isWeatherServiceCandyActive() then
        isCandyEventActive = true
        return true
    end
    if checkCandyEventActive() then
        isCandyEventActive = true
        return true
    end
    return false
end

-- Pengecekan apakah ada Permen Nyata di Map (Waypoints aktif dari rev_candySpawn atau item di Debris)
local function hasCandyOnMap()
    if #activeCandyWaypoints > 0 then return true end

    -- Cek Debris folder (HANYA objek di Debris, JANGAN cek workspace karena ada objek map statis)
    local debris = workspace:FindFirstChild("Debris")
    if debris then
        for _, child in ipairs(debris:GetChildren()) do
            if isCandyItem(child) then
                return true
            end
        end
    end

    return false
end

-- Pengecekan Event Override: HANYA bypass whitelist jika:
-- 1. Candy Event aktif
-- 2. rev_candySpawn TIDAK mengirim {} (empty)
-- 3. Ada permen nyata (waypoint aktif atau item di Debris)
local function shouldBypassWhitelist()
    if not isCandyEventEnabled() then return false end
    if not isCandyEventOngoing() then return false end
    if emptyCandySpawnReceived then return false end
    if #activeCandyWaypoints > 0 then return true end
    if hasCandyOnMap() then return true end
    return false
end

-- Validasi Brainrot Whitelist
local function isBrainrotWhitelisted(name)
    if not _G.useBrainrotWhitelist then return true end
    if not _G.brainrotWhitelist or #_G.brainrotWhitelist == 0 then return true end
    if not name or name == "" then return false end

    local lowerName = string.lower(tostring(name))
    for _, wlName in ipairs(_G.brainrotWhitelist) do
        local cleanWl = string.lower(tostring(wlName))
        if cleanWl ~= "" and (lowerName == cleanWl or string.find(lowerName, cleanWl, 1, true)) then
            return true
        end
    end
    return false
end

local function shouldKick()
    if not _G.autoFarm then return false end
    if _G.onlyCandyEvent then
        return isCandyEventOngoing()
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
local rev_candySpawn = findRemote("rev_candySpawn", "RemoteEvent")

local ref_B_SellAll = findRemote("ref_B_SellAll", "RemoteFunction")
local rev_WORLD_TP = findRemote("rev_WORLD_TP", "RemoteEvent")

-- =============================================
-- 🌍 AUTO WORLD TELEPORT (1X SAAT BARU EXECUTE)
-- =============================================
task.spawn(function()
    if _G.autoWorldTeleport ~= false then
        pcall(function()
            local targetWorld = (type(_G.targetWorld) == "number") and _G.targetWorld or 2
            local tpRemote = rev_WORLD_TP or findRemote("rev_WORLD_TP", "RemoteEvent")
            if not tpRemote then
                local shared = ReplicatedStorage:FindFirstChild("Shared")
                local packages = shared and shared:FindFirstChild("Packages")
                local net = packages and packages:FindFirstChild("Network")
                tpRemote = net and net:FindFirstChild("rev_WORLD_TP")
            end

            if tpRemote then
                tpRemote:FireServer(targetWorld)
                logConsole(string.format("🌍 [WORLD TP] rev_WORLD_TP:FireServer(%s) berhasil dieksekusi 1x!", tostring(targetWorld)))
            else
                game:GetService("ReplicatedStorage").Shared.Packages.Network.rev_WORLD_TP:FireServer(targetWorld)
                logConsole(string.format("🌍 [WORLD TP] rev_WORLD_TP:FireServer(%s) dipanggil langsung!", tostring(targetWorld)))
            end
        end)
    end
end)

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
                    lastRewardBrainrotName = tostring(rewardTable[1].Name or "")
                    local mutation = tostring(rewardTable[1].Mutation or "Normal")
                    lastRewardDesc = string.format("%s [%s]", lastRewardBrainrotName ~= "" and lastRewardBrainrotName or "Brainrot", mutation)
                    logConsole(string.format("🎉 Gacha Reward Masuk: %s", lastRewardDesc))
                elseif type(rewardTable) == "table" and rewardTable.Name then
                    lastRewardBrainrotName = tostring(rewardTable.Name or "")
                    lastRewardDesc = lastRewardBrainrotName
                    logConsole(string.format("🎉 Gacha Reward Masuk: %s", lastRewardDesc))
                end
            end)
        end)
    end

    local col = rev_Collected or findRemote("rev_Collected", "RemoteEvent")
    if col then
        col.OnClientEvent:Connect(function(...)
            collectedFired = true
            logConsole("📥 [SERVER EVENT] rev_Collected diterima!")
            -- 🛡️ SECURITY TELEPORT: Jika reward sudah collected, segera teleport ke Safe Zone
            pcall(function()
                local char = lp.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and (targetAction == "WalkToSafeZone" or targetAction == "StayStillUntilDead" or targetAction == "WaitingForCollected") then
                    teleportToSafeZone(hrp)
                end
            end)
        end)
    end

    -- 🛡️ SECURITY LISTENER: Deteksi Teks / Pop-up "Collected" di PlayerGui
    pcall(function()
        local pGui = lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 2)
        if pGui then
            pGui.DescendantAdded:Connect(function(desc)
                if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                    local txt = string.lower(tostring(desc.Text or ""))
                    if string.find(txt, "collected") then
                        collectedFired = true
                        logConsole("📥 [UI SECURITY] Teks 'Collected' terdeteksi di PlayerGui! Memicu security teleport...")
                        pcall(function()
                            local char = lp.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp and (targetAction == "WalkToSafeZone" or targetAction == "StayStillUntilDead" or targetAction == "WaitingForCollected") then
                                teleportToSafeZone(hrp)
                            end
                        end)
                    end
                end
            end)
        end
    end)

    local ended = rev_KickEventEnded or findRemote("rev_KickEventEnded", "RemoteEvent")
    if ended then
        ended.OnClientEvent:Connect(function(...)
            kickEndedFired = true
        end)
    end

    local addW = rev_AddedWeather or findRemote("rev_AddedWeather", "RemoteEvent")
    if addW then
        addW.OnClientEvent:Connect(function(weatherType, ...)
            local wStr = string.lower(tostring(weatherType or ""))
            if string.find(wStr, "candy") then
                if isCandyEventEnabled() then
                    isCandyEventActive = true
                    logConsole("🍬 Event Cuaca: CANDY EVENT AKTIF! Memulai Candy Hitbox Expander & Auto Navigator...")
                end
            end
        end)
    end

    local remW = rev_RemovedWeather or findRemote("rev_RemovedWeather", "RemoteEvent")
    if remW then
        remW.OnClientEvent:Connect(function(weatherType, ...)
            local wStr = string.lower(tostring(weatherType or ""))
            if string.find(wStr, "candy") then
                isCandyEventActive = false
                activeCandyWaypoints = {}
                emptyCandySpawnReceived = false
                logConsole("☁️ Event Cuaca: Candy Event Selesai. Standby di Safe Zone...")
            end
        end)
    end

    -- Listener rev_candySpawn (Koordinat Permen & Empty Spawn Detector)
    local candyRemote = rev_candySpawn or findRemote("rev_candySpawn", "RemoteEvent")
    if candyRemote then
        candyRemote.OnClientEvent:Connect(function(spawnData, ...)
            pcall(function()
                kickAcceptedByServer = true
                if not isCandyEventEnabled() then return end
                logConsole("🍬 [EVENT REMOTE] rev_candySpawn diterima!")
                if type(spawnData) == "table" then
                    local count = 0
                    local newWaypoints = {}
                    for _, item in pairs(spawnData) do
                        count = count + 1
                        if type(item) == "table" then
                            if item.Name then
                                registerCandyName(item.Name)
                            end
                            if item.Position and typeof(item.Position) == "Vector3" then
                                table.insert(newWaypoints, item.Position)
                            elseif item.CFrame and typeof(item.CFrame) == "CFrame" then
                                table.insert(newWaypoints, item.CFrame.Position)
                            end
                        elseif typeof(item) == "Vector3" then
                            table.insert(newWaypoints, item)
                        end
                    end

                    if count == 0 or #newWaypoints == 0 then
                        emptyCandySpawnReceived = true
                        activeCandyWaypoints = {}
                        logConsole("⚠️ [CANDY SPAWN] Data kosong ({}) diterima! Tidak ada permen yang spawn.")
                    else
                        emptyCandySpawnReceived = false
                        activeCandyWaypoints = newWaypoints
                        logConsole(string.format("🍬 [CANDY SPAWN] Berhasil mendeteksi %d titik permen untuk waypoint navigasi!", #activeCandyWaypoints))
                    end
                elseif spawnData == nil then
                    emptyCandySpawnReceived = true
                    activeCandyWaypoints = {}
                    logConsole("⚠️ [CANDY SPAWN] Data nil diterima! Tidak ada permen yang spawn.")
                end
            end)
        end)
    end
end
setupServerEventListeners()

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
            activeCandyWaypoints = {}
            emptyCandySpawnReceived = false
            continue 
        end

        if targetAction == "WaitingRespawn" and hum.Health > 0 then
            -- RESPAWN SELESAI: LANGSUNG TELEPORTASI KE SAFE ZONE UNTUK KICK!
            teleportToSafeZone(hrp)
            targetAction = "Idle"
            lastAction = "Idle"
            kickRetryCount = 0
            kickAcceptedByServer = false
            stateTimer = 0
            activeCandyWaypoints = {}
            emptyCandySpawnReceived = false
            lastRewardBrainrotName = ""
            logConsole("Karakter Respawn -> Teleportasi instan ke Safe Zone untuk Kick...")
        end

        -- [ PENGATUR WAKTU & FAILSAFE RESET ]
        if targetAction ~= lastAction then
            globalStuckTimer = 0
            stateTimer = 0 
            lastAction = targetAction
            logConsole("Transisi Fase -> " .. tostring(targetAction))
        else
            globalStuckTimer = globalStuckTimer + 0.05
            stateTimer = stateTimer + 0.05 
            
            local maxTimeout = _G.failsafeTimeout or 25
            if globalStuckTimer >= maxTimeout and targetAction ~= "WalkToSafeZone" then
                globalStuckTimer = 0
                stateTimer = 0
                lastRewardBrainrotName = ""
                emptyCandySpawnReceived = false
                teleportToSafeZone(hrp)
                targetAction = "Idle"
                logConsole("🚨 Failsafe Triggered: Teleportasi reset ke Idle Safe Zone")
                continue
            end
        end

        local distToSafeZone = (hrp.Position - safeZone).Magnitude

        -- [ FASE 1: IDLE / NENDANG DI SAFE ZONE (TELEPORTASI INSTAN JIKA JAUH) ]
        if targetAction == "Idle" then
            if distToSafeZone > 5 then
                teleportToSafeZone(hrp)
            else
                if shouldKick() then
                    local delayKick = (_G.kickDelay and _G.kickDelay > 0) and _G.kickDelay or 0.5
                    if stateTimer >= delayKick then
                        pcall(function()
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end)
                        kickRetryCount = 0
                        kickAcceptedByServer = false
                        phase2Fired = false
                        collectedFired = false
                        kickEndedFired = false
                        emptyCandySpawnReceived = false
                        lastRewardBrainrotName = ""
                        executeKick()
                        targetAction = "WaitingForPhase2"
                    end
                else
                    task.wait(0.1)
                end
            end

        -- [ FASE 2: NUNGGU PHASE 2 DARI SERVER / DETEKSI EMPTY SPAWN / WHITELIST CHECK ]
        elseif targetAction == "WaitingForPhase2" then
            if phase2Fired or collectedFired or kickEndedFired then
                phase2Fired = false
                kickRetryCount = 0
                kickAcceptedByServer = false

                -- Pengecekan Whitelist & Candy Override
                local isWhitelisted = _G.useBrainrotWhitelist and isBrainrotWhitelisted(lastRewardBrainrotName)
                local bypassWl = shouldBypassWhitelist()

                local isAllowed = false
                if bypassWl then
                    isAllowed = true
                elseif isWhitelisted then
                    isAllowed = true
                elseif not _G.useBrainrotWhitelist and not emptyCandySpawnReceived and (not _G.onlyCandyEvent or hasCandyOnMap()) then
                    isAllowed = true
                end

                if isAllowed then
                    targetAction = "WalkToSafeZone"
                    if bypassWl and _G.useBrainrotWhitelist and not isWhitelisted then
                        logConsole(string.format("🍬 [EVENT OVERRIDE] Ada permen di map! Brainrot '%s' tetap dibawa ke Safe Zone sembari ambil permen...", tostring(lastRewardBrainrotName)))
                    else
                        logConsole(string.format("✅ [PASSED] Membawa Brainrot '%s' Menuju Safe Zone", tostring(lastRewardBrainrotName)))
                    end
                else
                    targetAction = "StayStillUntilDead"
                    if emptyCandySpawnReceived then
                        logConsole(string.format("🛑 [EMPTY CANDY SPAWN] Koordinat permen kosong ({}) & Brainrot '%s' bukan whitelist! Bot diam di tempat...", tostring(lastRewardBrainrotName)))
                    elseif not hasCandyOnMap() and isCandyEventOngoing() then
                        logConsole(string.format("🛑 [NO CANDY ON MAP] Gada permen yang spawn di map & Brainrot '%s' bukan whitelist! Bot diam di tempat...", tostring(lastRewardBrainrotName)))
                    else
                        logConsole(string.format("🛑 [WHITELIST REJECTED] Brainrot '%s' TIDAK ada di whitelist! Bot diam di tempat (tidak dibawa ke safe zone)...", tostring(lastRewardBrainrotName)))
                    end
                end

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
                targetAction = "Idle"
                teleportToSafeZone(hrp)
                logConsole("🚨 Phase 2 Timeout (20s) -> Teleportasi reset ke Safe Zone")
            end

        -- [ FASE KHUSUS: DIAM DI TEMPAT SAMPAI MATI (JIKA CANDY SPAWN KOSONG {} ATAU TIDAK LOLOS WHITELIST) ]
        elseif targetAction == "StayStillUntilDead" then
            -- 🛡️ SECURITY CHECK: Jika reward ternyata ter-collect saat sedang diam, langsung teleport ke Safe Zone untuk kick!
            if collectedFired then
                collectedFired = false
                teleportToSafeZone(hrp)
                mutationCount = mutationCount + 1
                phase2Fired = false
                kickRetryCount = 0
                kickAcceptedByServer = false
                activeCandyWaypoints = {}
                emptyCandySpawnReceived = false
                lastRewardBrainrotName = ""

                if shouldKick() then
                    local delayKick = (_G.kickDelay and _G.kickDelay > 0) and _G.kickDelay or 0.5
                    task.wait(delayKick)
                    executeKick()
                    targetAction = "WaitingForPhase2"
                    logConsole(string.format("⚡ [COLLECTED SECURITY] Reward Collected saat diam! Teleport ke Safe Zone & Re-Kick (Jeda %.1fs)! Total: %d", delayKick, mutationCount))
                else
                    targetAction = "Idle"
                    logConsole(string.format("⚡ [COLLECTED SECURITY] Reward Collected saat diam! Standby di Safe Zone. Total: %d", mutationCount))
                end
                continue
            end

            -- BOT MURNI DIAM DI TEMPAT SAMPAI MATI / AUTO-RESET (DILARANG JALAN KE SAFE ZONE!)
            pcall(function()
                hum:MoveTo(hrp.Position)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)

            -- Failsafe Auto-Reset: Jika dalam 1.5 detik karakter tidak mati sendiri, paksa respawn agar bisa teleport ke safe zone untuk kick berikutnya!
            if stateTimer >= 3 then
                logConsole("💀 [AUTO-RESET] Bot diam 3s -> Memaksa respawn agar bisa kembali ke Safe Zone untuk kick berikutnya...")
                pcall(function()
                    hum.Health = 0
                    char:BreakJoints()
                end)
            end
            -- Menunggu karakter mati sendiri jika tidak ada event (hum.Health <= 0 akan ditangkap oleh pendeteksi mati di atas)

        -- [ FASE 3: JALAN KAKI MEMBAWA BRAINROT MENUJU SAFE ZONE (JANGAN TELEPORTASI!) ]
        elseif targetAction == "WalkToSafeZone" then
            -- 🛡️ FAILSAFE TIMEOUT KHUSUS JALAN KAKI: Jika jalan kaki melebihi 45 detik, paksa teleport ke Safe Zone
            if stateTimer >= 45.0 then
                logConsole("🚨 [WALK TIMEOUT] Terlalu lama berjalan (45s) -> Memaksa teleport ke Safe Zone!")
                teleportToSafeZone(hrp)
                targetAction = "WaitingForCollected"
                activeCandyWaypoints = {}
                currentWaypointTarget = nil
                waypointStuckTimer = 0
                continue
            end

            -- 🛡️ SECURITY CHECK: Jika reward sudah ter-collect oleh server / UI di tengah jalan, langsung teleport & kick lagi!
            if collectedFired then
                collectedFired = false
                teleportToSafeZone(hrp)
                mutationCount = mutationCount + 1
                phase2Fired = false
                kickRetryCount = 0
                kickAcceptedByServer = false
                activeCandyWaypoints = {}
                currentWaypointTarget = nil
                waypointStuckTimer = 0
                emptyCandySpawnReceived = false
                lastRewardBrainrotName = ""

                if shouldKick() then
                    local delayKick = (_G.kickDelay and _G.kickDelay > 0) and _G.kickDelay or 0.5
                    task.wait(delayKick)
                    executeKick()
                    targetAction = "WaitingForPhase2"
                    logConsole(string.format("⚡ [COLLECTED SECURITY] Barang sudah Collected di tengah jalan! Langsung teleport ke Safe Zone & Re-Kick (Jeda %.1fs)! Total: %d", delayKick, mutationCount))
                else
                    targetAction = "Idle"
                    logConsole(string.format("⚡ [COLLECTED SECURITY] Barang sudah Collected! Standby di Safe Zone. Total: %d", mutationCount))
                end
                continue
            end

            pcall(function()
                if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
                if hrp.Anchored then hrp.Anchored = false end
            end)

            -- Navigasi sembari melewati koordinat permen
            local targetPos = safeZone
            if isWaypointNavEnabled() and #activeCandyWaypoints > 0 then
                -- 1. Pertahankan target aktif atau pilih waypoint terdekat baru
                local bestIdx = nil
                local bestDist = math.huge

                if currentWaypointTarget then
                    for i, pos in ipairs(activeCandyWaypoints) do
                        if (pos - currentWaypointTarget).Magnitude < 0.5 then
                            bestIdx = i
                            bestDist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
                            break
                        end
                    end
                end

                if not bestIdx then
                    for i, pos in ipairs(activeCandyWaypoints) do
                        local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
                        if d < bestDist then
                            bestDist = d
                            bestIdx = i
                        end
                    end
                end

                if bestIdx then
                    local wp = activeCandyWaypoints[bestIdx]
                    currentWaypointTarget = wp

                    -- 🚀 DYNAMIC REACH THRESHOLD: Skala dinamis mengikuti kecepatan lari karakter (Buff In-Game)
                    local currentSpeed = (hum and hum.WalkSpeed and hum.WalkSpeed > 0) and hum.WalkSpeed or 16
                    local baseReach = _G.candyReachDist or 8
                    local speedReachBonus = (currentSpeed > 16) and (currentSpeed * 0.3) or 0
                    local reachThreshold = math.max(baseReach, speedReachBonus)

                    -- 🔍 CEK DEBRIS: Cek apakah barang permen masih ada di Debris di sekitar waypoint
                    local itemInDebris, itemDist, itemPos = findItemInDebrisNear(wp, 80)
                    local shouldVerifyDebris = (_G.verifyDebrisPickup ~= false)

                    -- Target pergerakan: utamakan posisi aktual item di Debris jika ada, Y rata tanah agar karakter tidak loncat/stutter
                    local wpTargetPos = itemPos or wp
                    targetPos = Vector3.new(wpTargetPos.X, hrp.Position.Y, wpTargetPos.Z)

                    local distToTarget = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(wpTargetPos.X, 0, wpTargetPos.Z)).Magnitude

                    -- 🍬 SENTUHAN AKTIF (PROACTIVE TOUCH): Picu touch saat sudah dekat (< 80 studs) jika firetouch aktif
                    if _G.enableFireTouch and itemInDebris and distToTarget <= 80 then
                        touchCandyItem(itemInDebris, hrp)
                    end

                    -- 🛡️ WAYPOINT STUCK WATCHDOG: Jika mencoba waypoint yang sama > 6 detik tanpa perubahan, lewati
                    waypointStuckTimer = waypointStuckTimer + 0.05
                    if waypointStuckTimer >= 6.0 then
                        table.remove(activeCandyWaypoints, bestIdx)
                        logConsole(string.format("⚠️ [WAYPOINT TIMEOUT] Waypoint (%s) tidak terambil setelah 6s! Melewati ke titik berikutnya... Sisa: %d", itemInDebris and itemInDebris.Name or "Candy", #activeCandyWaypoints))
                        waypointStuckTimer = 0
                        currentWaypointTarget = nil
                        wp = nil
                    else
                        -- 🛑 KONDISI SUDAH MENCAPAI AREA PERMEN:
                        if distToTarget <= reachThreshold then
                            -- ⚡ ANTI-OVERSHOOT BRAKING: Redam inersia saat lari kencang agar tidak muter-muter / bablas
                            if _G.candyAntiOvershoot ~= false and currentSpeed > 20 then
                                pcall(function()
                                    hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                                end)
                            end

                            -- 📦 KONDISI KELOLOSAN WAYPOINT:
                            if shouldVerifyDebris then
                                if not itemInDebris then
                                    -- Barang SUDAH HILANG dari Debris (berhasil dibawa)
                                    table.remove(activeCandyWaypoints, bestIdx)
                                    currentWaypointTarget = nil
                                    waypointStuckTimer = 0
                                    logConsole(string.format("🍬 [COLLECTED] Barang berhasil dibawa (hilang dari Debris)! Sisa waypoint: %d", #activeCandyWaypoints))
                                else
                                    -- Barang MASIH ADA di Debris -> Picu touch ulang & tahan posisi sejenak
                                    touchCandyItem(itemInDebris, hrp)
                                    targetPos = Vector3.new(wpTargetPos.X, hrp.Position.Y, wpTargetPos.Z)
                                    if math.floor(waypointStuckTimer * 10) % 20 == 0 then
                                        logConsole(string.format("⏳ [CEK DEBRIS] Menyentuh '%s' (jarak: %.1fm, speed: %.0f). Menunggu server...", itemInDebris.Name, distToTarget, currentSpeed))
                                    end
                                end
                            else
                                -- Mode fallback tanpa verifikasi Debris
                                table.remove(activeCandyWaypoints, bestIdx)
                                currentWaypointTarget = nil
                                waypointStuckTimer = 0
                                logConsole(string.format("🍬 Waypoint permen terlewati! Sisa waypoint: %d", #activeCandyWaypoints))
                            end
                        else
                            -- Karakter masih dalam perjalanan menuju waypoint (distToTarget > reachThreshold)
                            -- ⚡ ANTI-DRIFT: Jika speed kencang & mulai mendekati (< 25 studs), luruskan vektor kecepatan agar tidak orbiting
                            if currentSpeed > 24 and distToTarget < 25 then
                                pcall(function()
                                    local toTarget = (Vector3.new(wpTargetPos.X, 0, wpTargetPos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Unit
                                    local currentVel = hrp.AssemblyLinearVelocity
                                    local horizSpeed = Vector2.new(currentVel.X, currentVel.Z).Magnitude
                                    if horizSpeed > 8 then
                                        hrp.AssemblyLinearVelocity = Vector3.new(toTarget.X * math.min(horizSpeed, currentSpeed), currentVel.Y, toTarget.Z * math.min(horizSpeed, currentSpeed))
                                    end
                                end)
                            end
                        end
                    end
                end
            else
                currentWaypointTarget = nil
                waypointStuckTimer = 0
            end

            -- Bot TETAP MURNI JALAN KAKI via MoveTo
            hum:MoveTo(targetPos)

            -- 🛡️ HANYA masuk Safe Zone jika SEMUA waypoint permen sudah tuntas diambil (atau tidak aktif)
            local waypointsPending = isWaypointNavEnabled() and (#activeCandyWaypoints > 0)
            if distToSafeZone < 5 and not waypointsPending then
                currentWaypointTarget = nil
                waypointStuckTimer = 0
                targetAction = "WaitingForCollected"
                logConsole("Tiba di Safe Zone -> Menunggu Reward Collected")
            end

        -- [ FASE 4: NUNGGU COLLECTED & RE-KICK INSTAN (TELEPORTASI KE SAFEZONE UNTUK KICK) ]
        elseif targetAction == "WaitingForCollected" then
            if distToSafeZone >= 5 then
                teleportToSafeZone(hrp)
            end

            if collectedFired or kickEndedFired or stateTimer >= 2.5 then
                collectedFired = false
                kickEndedFired = false
                mutationCount = mutationCount + 1
                phase2Fired = false
                kickRetryCount = 0
                kickAcceptedByServer = false
                activeCandyWaypoints = {}
                emptyCandySpawnReceived = false
                lastRewardBrainrotName = ""

                -- Pastikan posisi presisi di SafeZone via teleportasi
                teleportToSafeZone(hrp)

                if shouldKick() then
                    local delayKick = (_G.kickDelay and _G.kickDelay > 0) and _G.kickDelay or 0.5
                    task.wait(delayKick)
                    executeKick()
                    targetAction = "WaitingForPhase2"
                    logConsole(string.format("🎉 Total Mutasi: %d | Re-Kick (Jeda %.1fs)!", mutationCount, delayKick))
                else
                    targetAction = "Idle"
                    logConsole(string.format("🎉 Total Mutasi: %d | Ronde Tuntas -> Standby di Safe Zone (Menunggu Event Candy)", mutationCount))
                end
            end
        end
    end
end)

print("--------------------------------------------------")
print("🚀 [SUKSES] KALB Candy Event & Teleport Kick Auto Farm Siap Berjalan!")
print("--------------------------------------------------")
