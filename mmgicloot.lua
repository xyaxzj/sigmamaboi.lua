-- ==============================================================================
-- 🍬 KALB AUTO CANDY HITBOX EXPANDER & AUTO SELL (FLAWLESS & GUARANTEED 24/7 AFK)
-- ==============================================================================
-- 📋 Fitur Utama:
-- 1. 🚀 Anti-Lag & Extreme FPS Boost (Potato Mode):
--    - Menghapus shadow, partikel berat, tekstur, efek blur, bloom, post-processing
--    - Proteksi penuh untuk karakter pemain dan item permen event
--
-- 2. 🍬 Candy Weather Event Engine:
--    - Mendeteksi rev_AddedWeather "Candy" & rev_candySpawn
--    - ✅ Hitbox diperbesar ke 200x200x200 studs (CanTouch=true, CanQuery=true, CanCollide=false, Transparency=0.5)
--    - 🎯 Target: CarriedCandy, Candy, Chocolate, Cake, Pancakes, Gummy Bear, Ice Cream, Gummy Worm, dll.
--    - 📡 Dynamic Listener: Otomatis mendeteksi dan mendaftarkan nama permen baru dari server
--
-- 3. 💰 Auto Sell All:
--    - Menjual seluruh brainrot setiap 5 detik via RemoteFunction ref_B_SellAll
--
-- 4. 🛡️ Anti-AFK & 🧹 Memory Pruner (Anti Disconnect 24/7)
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
-- ⚙️ KONFIGURASI PENGGUNA
-- ==============================================================================
_G.antiLag = true                              -- true: Aktifkan Anti-Lag / FPS Boost Ekstrem (Potato Mode)
_G.autoCandyEvent = true                       -- true: Otomatis perbesar hitbox permen (Candy, Cokelat, dll.)
_G.candyHitboxSize = Vector3.new(200, 200, 200)-- Ukuran hitbox Candy yang dibesarkan (Default: 200 studs)
_G.autoSellAll = true                          -- true: Otomatis jual semua brainrot berkala
_G.sellInterval = 5                            -- Interval waktu (detik) Auto Sell All
_G.debugConsoleLog = true                      -- true: Tampilkan log di Developer Console (F9)

print("--------------------------------------------------")
print("🚀 [INIT] Memuat KALB Perfect Candy Event & Auto Sell...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local lp = Players.LocalPlayer
if not lp then
    local count = 0
    repeat
        task.wait(0.05)
        lp = Players.LocalPlayer
        count = count + 1
    until lp or count > 50
end

local function logConsole(...)
    if _G.debugConsoleLog ~= false then
        print(...)
    end
end

-- ==============================================================================
-- 🍬 DAFTAR TARGET CANDY & DYNAMIC DISCOVERY ENGINE
-- ==============================================================================
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

-- Mendaftarkan nama permen baru secara dinamis
local function registerCandyName(name)
    if not name or name == "" then return end
    local lower = string.lower(tostring(name))
    if not CANDY_NAMES[lower] then
        CANDY_NAMES[lower] = true
        logConsole(string.format("🍬 [CANDY DISCOVERY] Mendaftarkan jenis permen baru: '%s'", tostring(name)))
    end
end

-- Pengecekan apakah sebuah objek adalah item permen
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

-- Proteksi agar partikel/tekstur permen tidak terhapus oleh anti-lag
local function isProtectedEventItem(inst)
    if not inst then return false end
    local name = inst.Name
    if name == "PlotSign" or name == "KALB_SafeZoneMarker" then return true end
    if isCandyItem(inst) then return true end

    local curr = inst
    while curr and curr ~= workspace and curr ~= game do
        local cName = curr.Name
        if cName == "PlotSign" or cName == "KALB_SafeZoneMarker" or isCandyItem(curr) then
            return true
        end
        curr = curr.Parent
    end
    return false
end

-- ==============================================================================
-- 🚀 SISTEM ANTI-LAG & FPS BOOSTER (POTATO MODE EKSTREM)
-- ==============================================================================
local function stripTexture(v)
    if not v then return end
    if lp and lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character)) then return end
    if isProtectedEventItem(v) then return end

    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
            v.Color = Color3.new(1, 1, 1)
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("SurfaceAppearance") or v:IsA("Clothing") or v:IsA("ShirtGraphic") then
            v:Destroy()
        end
    end)
end

if _G.antiLag then
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            stripTexture(v)
        end

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Sky") then
                v:Destroy()
            end
        end

        if setfpscap then
            pcall(setfpscap, 60)
        end

        logConsole("🚀 [ANTI-LAG] Potato Mode & FPS Booster berhasil diaktifkan!")
    end)

    workspace.DescendantAdded:Connect(function(descendant)
        if _G.antiLag then
            task.defer(stripTexture, descendant)
        end
    end)
end

-- ==============================================================================
-- 🛡️ ANTI-AFK & MEMORY STABILIZER (ANTI DISCONNECT & ANTI MEMORY LEAK)
-- ==============================================================================
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

-- Pembersih Memori Tiap 60 Detik
task.spawn(function()
    while task.wait(60) do
        pcall(function()
            if gcinfo then gcinfo() end
            if collectgarbage then collectgarbage("collect") end
        end)
    end
end)

-- ==============================================================================
-- 📡 DAFTAR REMOTE NETWORK & AUTO-RESOLVER
-- ==============================================================================
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

local ref_B_SellAll = findRemote("ref_B_SellAll", "RemoteFunction")
local rev_AddedWeather = findRemote("rev_AddedWeather", "RemoteEvent")
local rev_RemovedWeather = findRemote("rev_RemovedWeather", "RemoteEvent")
local rev_candySpawn = findRemote("rev_candySpawn", "RemoteEvent")

-- ==============================================================================
-- 💰 FITUR 1: AUTO SELL ALL (SETIAP 5 DETIK NONSTOP)
-- ==============================================================================
task.spawn(function()
    while true do
        local delayTime = (_G.sellInterval and _G.sellInterval > 0) and _G.sellInterval or 5
        task.wait(delayTime)
        if _G.autoSellAll then
            pcall(function()
                local sellRemote = ref_B_SellAll
                if not sellRemote or not sellRemote.Parent then
                    sellRemote = findRemote("ref_B_SellAll", "RemoteFunction")
                    ref_B_SellAll = sellRemote
                end

                if sellRemote and sellRemote:IsA("RemoteFunction") then
                    sellRemote:InvokeServer()
                    logConsole("💰 [AUTO SELL] Berhasil menjual seluruh brainrot!")
                end
            end)
        end
    end
end)

-- ==============================================================================
-- 🍬 FITUR 2: CANDY HITBOX EXPANDER ENGINE (200x200x200 STUDS)
-- ==============================================================================
local CANDY_HITBOX_SIZE = _G.candyHitboxSize or Vector3.new(200, 200, 200)
local isCandyEventActive = false
local expandedCandyObjects = {}

local function expandCandyHitbox(inst)
    if not _G.autoCandyEvent or not inst or not inst.Parent then return end
    if not isCandyItem(inst) then return end
    if expandedCandyObjects[inst] then return end

    pcall(function()
        local targetPart = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            targetPart.CanCollide = false
            targetPart.CanTouch = true
            targetPart.CanQuery = true
            targetPart.CastShadow = false
            targetPart.Transparency = 0.5
            local targetSize = _G.candyHitboxSize or CANDY_HITBOX_SIZE
            if targetPart.Size ~= targetSize then
                targetPart.Size = targetSize
            end
            expandedCandyObjects[inst] = true
            logConsole(string.format("🍬 [CANDY HITBOX] '%s' (%s) berhasil diperbesar ke 200 studs!", inst.Name, targetPart.Name))
        end
    end)
end

-- Pemindai semua permen di workspace & Debris
local function scanAndExpandAllCandies()
    if not _G.autoCandyEvent then return end

    -- Bersihkan cache item yang sudah musnah dari ingatan
    for obj, _ in pairs(expandedCandyObjects) do
        if not obj or not obj.Parent then
            expandedCandyObjects[obj] = nil
        end
    end

    local debris = workspace:FindFirstChild("Debris")
    local containers = {workspace}
    if debris then table.insert(containers, debris) end

    for _, container in ipairs(containers) do
        for _, child in ipairs(container:GetChildren()) do
            if isCandyItem(child) then
                expandCandyHitbox(child)
            end
        end
    end
end

-- Hook Engine Cuaca Game (WeatherService_Client)
local function isWeatherServiceCandyActive()
    local ok, result = pcall(function()
        local svLoader = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("ServicesLoader")
        local ws = svLoader and svLoader:FindFirstChild("WeatherService_Client") and require(svLoader.WeatherService_Client)
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
    end)
    return (ok and result == true)
end

-- ==============================================================================
-- ⚡ LISTENER DESCENDANT ADDED (REAL-TIME INSTANT HITBOX EXPANSION)
-- ==============================================================================
workspace.DescendantAdded:Connect(function(descendant)
    task.defer(function()
        if not descendant or not descendant.Parent then return end
        if _G.autoCandyEvent and isCandyItem(descendant) then
            expandCandyHitbox(descendant)
        end
    end)
end)

-- Fast Background Watchdog Loop (tiap 0.2 detik)
task.spawn(function()
    while task.wait(0.2) do
        pcall(scanAndExpandAllCandies)
    end
end)

-- Scan awal saat script dieksekusi
task.spawn(function()
    task.wait(0.1)
    pcall(scanAndExpandAllCandies)
end)

-- ==============================================================================
-- 🌦️ SINKRONISASI REMOTE WEATHER & CANDY SPAWN LISTENER
-- ==============================================================================
local function setupWeatherListeners()
    local addW = rev_AddedWeather or findRemote("rev_AddedWeather", "RemoteEvent")
    if addW then
        addW.OnClientEvent:Connect(function(weatherType, ...)
            local wStr = string.lower(tostring(weatherType or ""))
            if string.find(wStr, "candy") then
                isCandyEventActive = true
                logConsole(string.format("📡 [WEATHER] Event Candy Dimulai: %s! Memperbesar seluruh hitbox permen...", tostring(weatherType)))
                pcall(scanAndExpandAllCandies)
            end
        end)
    end

    local remW = rev_RemovedWeather or findRemote("rev_RemovedWeather", "RemoteEvent")
    if remW then
        remW.OnClientEvent:Connect(function(weatherType, ...)
            local wStr = string.lower(tostring(weatherType or ""))
            if string.find(wStr, "candy") then
                isCandyEventActive = false
                logConsole(string.format("☁️ [WEATHER] Event %s Berakhir.", tostring(weatherType)))
            end
        end)
    end

    -- Listener rev_candySpawn: Otomatis mendeteksi nama permen baru
    local candyRemote = rev_candySpawn or findRemote("rev_candySpawn", "RemoteEvent")
    if candyRemote then
        candyRemote.OnClientEvent:Connect(function(spawnData, ...)
            pcall(function()
                if type(spawnData) == "table" then
                    for _, item in pairs(spawnData) do
                        if type(item) == "table" and item.Name then
                            registerCandyName(item.Name)
                        end
                    end
                end
                pcall(scanAndExpandAllCandies)
            end)
        end)
    end
end

setupWeatherListeners()

-- Periksa status cuaca saat script pertama kali aktif
task.spawn(function()
    if isWeatherServiceCandyActive() then
        isCandyEventActive = true
        logConsole("🍬 [WEATHER INIT] Terdeteksi Candy Event sedang aktif di server!")
        pcall(scanAndExpandAllCandies)
    end
end)

print("--------------------------------------------------")
print("✅ [CandyEvent] Perfect Candy Hitbox Engine & Auto Sell Siap Berjalan 24/7!")
print("--------------------------------------------------")
