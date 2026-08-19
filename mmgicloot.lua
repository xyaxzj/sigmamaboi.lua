-- ==============================================================================
-- 🥔 KALB ULTRA LIGHTWEIGHT AUTO FARM V2 (NO-CLICK KICK ENGINE & SMOOTH WALK)
-- ==============================================================================
-- Fitur & Alur:
-- 1. ⚙️ Full Config Mode: Semua pengaturan diatur via variabel _G di baris atas (Tanpa UI)
-- 2. ⚡ Zero-Click Pure Remote/Hook Kick Engine:
--    - Murni direct GameController:Kick(1, 1) + ref_KickEvent / rev_KickEvent
--    - 100% BEBAS dari VirtualInputManager & VirtualUser Click (TIDAK AKAN PERNAH mengeklik UI/Menu lain)
--    - Auto-Retry 3.5s jika kick belum terdaftar di server
-- 3. 🚶 Smooth Continuous Walk:
--    - Karakter DIJAMIN berjalan sampai tuntas ke Safe Zone (jarak <= 5 studs) tanpa berhenti di tengah jalan
--    - Throttle MoveTo agar pathfinding Humanoid berjalan mulus tanpa stutter/freeze
-- 4. ☄️ Meteor Shower Only Mode:
--    - Menendang bola saat event Meteor Shower aktif / ada meteor di Debris
--    - Saat event selesai di tengah jalan, karakter tetap berjalan sampai Safe Zone dan standby di titik Safe Zone
-- 5. ☄️ Auto Meteor Hitbox Expander: Ukuran 250x250x250 (CanQuery=true)
-- 6. 🛒 Auto Buy Frigorex (5 menit), 🧪 Farm Potion (WIB ganjil), 💰 Auto Sell All (5s)
-- 7. 🥔 Potato Mode Ekstrem & 🛡️ Anti-AFK Anti-Disconnect (getconnections disable)
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
-- ⚙️ KONFIGURASI PENGGUNA (UBAH SESUAI KEBUTUHAN DI SINI)
-- ==============================================================================
_G.autoFarm = true               -- true: Auto Farm Aktif, false: Nonaktif
_G.onlyMeteorEvent = false        -- true: HANYA Auto Kick saat Event Meteor Shower aktif, false: Auto kick nonstop
_G.autoMeteor = true             -- true: Otomatis perbesar hitbox meteor saat Meteor Shower, false: Nonaktif
_G.autoBuyFrigorex = true        -- true: Cek stock Meteor Shop tiap 5 menit & auto beli Frigorex jika stock > 0
_G.autoBuyFarmPotion = true      -- true: Auto beli 1x Farm Potion setiap jam ganjil (1, 3, 5... 23 WIB)
_G.autoSellAll = true            -- true: Auto Sell All setiap 5 detik via ref_B_SellAll
_G.autoRemovePlayer = false      -- true: Hapus player lain dari client (FPS Boost), false: Biarkan
_G.debugConsoleLog = false       -- true: Cetak log status/fase ke console (F9), false: Senyap
_G.failsafeTimeout = 25          -- Waktu maksimal (detik) sebelum auto-reset ke Safe Zone jika macet

print("--------------------------------------------------")
print("🚀 [INIT] Memuat KALB Auto Farm V2 (Zero-Click & Smooth Walk)...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local lp = Players.LocalPlayer
if not lp then
    local count = 0
    repeat
        task.wait(0.05)
        lp = Players.LocalPlayer
        count = count + 1
    until lp or count > 50
end

-- =============================================
-- 🚀 SYSTEM ANTI-LAG & POTATO MODE
-- =============================================
pcall(function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
            v.Color = Color3.new(1, 1, 1)
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("SpecialMesh") then
            v:Destroy()
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    for _, v in ipairs(Lighting:GetDescendants()) do
        if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Sky") then
            v:Destroy()
        end
    end

    local plotsFolder = workspace:FindFirstChild("Plots")
    if plotsFolder then
        for i = 1, 5 do
            local plot = plotsFolder:FindFirstChild("Plot" .. tostring(i))
            if plot then plot:Destroy() end
        end
    end
end)

-- Player Purger (Opsional jika diaktifkan di config)
if _G.autoRemovePlayer then
    local function musnahkanPlayer(player)
        if player ~= lp then
            if player.Character then pcall(function() player.Character:Destroy() end) end
            pcall(function() player:Destroy() end)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        musnahkanPlayer(player)
    end

    Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            if _G.autoRemovePlayer then
                musnahkanPlayer(player)
            end
        end)
    end)
end

-- =============================================
-- ☄️ AUTO METEOR EVENT ENGINE (HITBOX EXPANDER)
-- =============================================
local OPTIMAL_METEOR_SIZE = Vector3.new(250, 250, 250)
local activeMeteors = {}
local isMeteorShowerActive = false

local function isTargetMeteorModel(model)
    if not model or not model:IsA("Model") then return false end
    local debris = workspace:FindFirstChild("Debris")
    if not debris or not model:IsDescendantOf(debris) then return false end
    return tonumber(model.Name) ~= nil
end

local function isAnyMeteorInDebris()
    local debris = workspace:FindFirstChild("Debris")
    if not debris then return false end
    for _, child in ipairs(debris:GetChildren()) do
        if isTargetMeteorModel(child) then
            return true
        end
    end
    return false
end

local function getTargetMeteorParent(instance)
    if not instance then return nil end
    local debris = workspace:FindFirstChild("Debris")
    if not debris or not instance:IsDescendantOf(debris) then return nil end

    local curr = instance
    while curr and curr ~= debris and curr ~= workspace do
        if curr:IsA("Model") and tonumber(curr.Name) ~= nil then
            return curr
        end
        curr = curr.Parent
    end
    return nil
end

local function expandMeteorHitbox(part)
    if not part or not (part:IsA("BasePart") or part.ClassName == "Part") then return end
    pcall(function()
        part.CanCollide = false
        part.CanTouch = true
        part.CanQuery = true
        part.CastShadow = false
        if part.Size ~= OPTIMAL_METEOR_SIZE then
            part.Size = OPTIMAL_METEOR_SIZE
        end
    end)
end

local function handleNewMeteor(model)
    if not _G.autoMeteor then return end
    if not model or not isTargetMeteorModel(model) then return end
    if activeMeteors[model] then return end
    activeMeteors[model] = true
    isMeteorShowerActive = true

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant.ClassName == "Part" then
            expandMeteorHitbox(descendant)
        end
    end

    if _G.debugConsoleLog then
        print(string.format("☄️ [METEOR] Hitbox Model #%s diperbesar (250 studs, CanQuery=true)!", tostring(model.Name)))
    end
end

local function setupMeteorListeners(debris)
    if not debris then return end

    for _, item in ipairs(debris:GetDescendants()) do
        if isTargetMeteorModel(item) then
            handleNewMeteor(item)
        end
    end

    debris.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            if not _G.autoMeteor then return end
            if isTargetMeteorModel(descendant) then
                handleNewMeteor(descendant)
            elseif descendant:IsA("BasePart") or descendant.ClassName == "Part" then
                local targetModel = getTargetMeteorParent(descendant)
                if targetModel then
                    expandMeteorHitbox(descendant)
                    handleNewMeteor(targetModel)
                end
            end
        end)
    end)

    debris.DescendantRemoving:Connect(function(descendant)
        activeMeteors[descendant] = nil
    end)
end

task.spawn(function()
    local debris = workspace:FindFirstChild("Debris") or workspace:WaitForChild("Debris", 10)
    if debris then setupMeteorListeners(debris) end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Debris" then
        task.defer(function() setupMeteorListeners(child) end)
    end
end)

task.spawn(function()
    while task.wait(0.25) do
        if not _G.autoMeteor then continue end
        local debris = workspace:FindFirstChild("Debris")
        if debris then
            for _, item in ipairs(debris:GetDescendants()) do
                if isTargetMeteorModel(item) then
                    if not activeMeteors[item] then handleNewMeteor(item) end
                    for _, part in ipairs(item:GetDescendants()) do
                        if (part:IsA("BasePart") or part.ClassName == "Part") and (part.Size ~= OPTIMAL_METEOR_SIZE or not part.CanQuery) then
                            expandMeteorHitbox(part)
                        end
                    end
                end
            end
        end
    end
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
local safeZone = Vector3.new(698.030701, 3.298559, 233.707077)
local safeZoneCFrame = CFrame.new(698.030701, 3.298559, 233.707077, -0.061024, -0.000000, 0.998136, -0.000000, 1.000000, 0.000000, -0.998136, -0.000000, -0.061024)

local function logConsole(msg)
    if _G.debugConsoleLog then
        print(string.format("🤖 [KALB-FARM] [%s] %s", tostring(targetAction), tostring(msg)))
    end
end

local function shouldKick()
    if not _G.autoFarm then return false end
    if _G.onlyMeteorEvent then
        return isMeteorShowerActive or isAnyMeteorInDebris()
    end
    return true
end

-- =============================================
-- 🛡️ ANTI AFK (CLEAN SIGNAL DISABLE - NO CLICKS)
-- =============================================
pcall(function()
    if getconnections then
        for _, conn in ipairs(getconnections(lp.Idled)) do
            conn:Disable()
        end
    end
end)

-- =============================================
-- 📡 DAFTAR REMOTE NETWORK RESMI
-- =============================================
local networkFolder = nil
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
    local packages = shared and (shared:FindFirstChild("Packages") or shared:WaitForChild("Packages", 3))
    networkFolder = packages and (packages:FindFirstChild("Network") or packages:WaitForChild("Network", 3))
end)

local ref_KickEvent = networkFolder and networkFolder:FindFirstChild("ref_KickEvent")
local kickRemote = networkFolder and networkFolder:FindFirstChild("rev_KickEvent")
local rev_kickPhase2 = networkFolder and networkFolder:FindFirstChild("rev_kickPhase2")
local rev_Collected = networkFolder and networkFolder:FindFirstChild("rev_Collected")
local rev_KickEventEnded = networkFolder and networkFolder:FindFirstChild("rev_KickEventEnded")
local rev_AddedWeather = networkFolder and networkFolder:FindFirstChild("rev_AddedWeather")
local rev_RemovedWeather = networkFolder and networkFolder:FindFirstChild("rev_RemovedWeather")

local ref_B_SellAll = networkFolder and networkFolder:FindFirstChild("ref_B_SellAll")
local rev_MeteorShop_RequestSync = networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_RequestSync")
local rev_MeteorShop_Stock = networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Stock")
local rev_MeteorShop_Buy = networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy")

if not ref_KickEvent then
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteFunction") and r.Name == "ref_KickEvent" then
            ref_KickEvent = r
            break
        end
    end
end
if not kickRemote then
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") and string.find(r.Name, "rev_KickEvent") and not string.find(r.Name, "Ended") then
            kickRemote = r
            break
        end
    end
end

-- =============================================
-- 🛒 AUTO BUY METEOR SHOP (FRIGOREX VIA STOCK)
-- =============================================
if rev_MeteorShop_Stock then
    rev_MeteorShop_Stock.OnClientEvent:Connect(function(stockData, expiryTimestamp)
        if type(stockData) ~= "table" then return end
        
        for itemName, itemInfo in pairs(stockData) do
            if itemName == "Frigorex" and type(itemInfo) == "table" then
                local stockCount = tonumber(itemInfo.Stock) or 0
                local maxCount = tonumber(itemInfo.Max) or 0
                
                if _G.debugConsoleLog then
                    print(string.format("🛒 [METEOR SHOP] Frigorex Stock: %d / %d", stockCount, maxCount))
                end

                if _G.autoBuyFrigorex and stockCount > 0 then
                    for i = 1, stockCount do
                        pcall(function()
                            local buyRemote = rev_MeteorShop_Buy or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy"))
                            if buyRemote then
                                buyRemote:FireServer("Frigorex")
                                print(string.format("🔥 [AUTO BUY] Berhasil membeli Frigorex (#%d/%d)!", i, stockCount))
                            end
                        end)
                        task.wait(0.2)
                    end
                end
            end
        end
    end)
end

-- Loop Request Sync Stock setiap 5 Menit (300 Detik)
task.spawn(function()
    task.wait(3)
    while true do
        if _G.autoFarm and _G.autoBuyFrigorex then
            pcall(function()
                local syncRemote = rev_MeteorShop_RequestSync or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_RequestSync"))
                if syncRemote then
                    syncRemote:FireServer()
                    if _G.debugConsoleLog then
                        print("🛒 [METEOR SHOP] Mengirim RequestSync Stock ke server (Loop 5 Menit)...")
                    end
                end
            end)
        end
        task.wait(300)
    end
end)

-- =============================================
-- 🧪 AUTO BUY FARM POTION (JAM GANJIL WIB: 1, 3, 5... 23)
-- =============================================
local lastBoughtFarmPotionHour = -1

task.spawn(function()
    task.wait(2)
    while true do
        if _G.autoFarm and _G.autoBuyFarmPotion then
            pcall(function()
                local wibTime = os.date("!*t", os.time() + (7 * 3600))
                local hourWIB = wibTime.hour
                local minWIB = wibTime.min
                local secWIB = wibTime.sec

                if (hourWIB % 2 == 1) and (lastBoughtFarmPotionHour ~= hourWIB) then
                    lastBoughtFarmPotionHour = hourWIB
                    
                    local buyRemote = rev_MeteorShop_Buy or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy"))
                    if buyRemote then
                        buyRemote:FireServer("Farm Potion")
                        print(string.format("🧪 [AUTO BUY WIB] Berhasil membeli 1x Farm Potion pada jam %02d:%02d:%02d WIB!", hourWIB, minWIB, secWIB))
                    end
                end
            end)
        end
        task.wait(5)
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
-- 🎮 CLIENT CONTROLLER HOOK (GC MEMORY)
-- =============================================
local cachedGameController = nil
local function getGameController()
    if cachedGameController then return cachedGameController end
    if getgc then
        for _, item in ipairs(getgc(true)) do
            if type(item) == "table" then
                if rawget(item, "CanKick") ~= nil and type(rawget(item, "Kick")) == "function" and rawget(item, "Status") ~= nil then
                    cachedGameController = item
                    return item
                end
            end
        end
    end
    return nil
end

-- =============================================
-- 📡 LISTENER EVENT SERVER
-- =============================================
local phase2Fired = false
local collectedFired = false
local kickEndedFired = false

if rev_kickPhase2 then
    rev_kickPhase2.OnClientEvent:Connect(function(rewardTable, ...)
        phase2Fired = true
        pcall(function()
            if type(rewardTable) == "table" and rewardTable[1] then
                lastRewardDesc = string.format("%s [%s]", tostring(rewardTable[1].Name or "Brainrot"), tostring(rewardTable[1].Mutation or "Normal"))
                logConsole(string.format("🎉 Gacha Reward Masuk: %s", lastRewardDesc))
            end
        end)
    end)
end

if rev_Collected then
    rev_Collected.OnClientEvent:Connect(function(...)
        collectedFired = true
    end)
end

if rev_KickEventEnded then
    rev_KickEventEnded.OnClientEvent:Connect(function(...)
        kickEndedFired = true
    end)
end

if rev_AddedWeather then
    rev_AddedWeather.OnClientEvent:Connect(function(weatherType, ...)
        if weatherType == "MeteorShower" then
            isMeteorShowerActive = true
            logConsole("☄️ Event Cuaca: METEOR SHOWER AKTIF! Memulai Auto Kick & Farm...")
        end
    end)
end

if rev_RemovedWeather then
    rev_RemovedWeather.OnClientEvent:Connect(function(weatherType, ...)
        if weatherType == "MeteorShower" then
            isMeteorShowerActive = false
            logConsole("☁️ Event Cuaca: Meteor Shower Selesai. Menyelesaikan ronde ini lalu standby di Safe Zone...")
        end
    end)
end

-- =============================================
-- 🚀 FUNGSI EKSEKUSI TENDANGAN (100% BEBAS KLIK UI)
-- =============================================
local function executeKick()
    task.spawn(function()
        local timestamp = nil
        pcall(function() timestamp = workspace:GetServerTimeNow() end)
        if not timestamp or type(timestamp) ~= "number" or timestamp <= 0 then
            timestamp = tick()
        end

        logConsole("⚡ [PURE KICK] Menendang bola via Client Controller & Remote...")

        -- 1. Direct GameController Client Hook (Nyalakan animasi & projectile asli)
        pcall(function()
            local controller = getGameController()
            if controller then
                if controller.UnblockKick then
                    pcall(function() controller:UnblockKick() end)
                end
                controller.CanKick = true
                pcall(function() controller:Kick(1, 1) end)
            end
        end)

        -- 2. Jaringan Remote Resmi ke Server (InvokeServer / FireServer)
        pcall(function()
            if ref_KickEvent and ref_KickEvent:IsA("RemoteFunction") then
                ref_KickEvent:InvokeServer(1, 1, timestamp)
            elseif kickRemote and kickRemote:IsA("RemoteEvent") then
                kickRemote:FireServer(1, 1)
            end
        end)
    end)
end

-- =============================================
-- ⚙️ MAIN LOOP (STATE MACHINE AUTO FARM)
-- =============================================
local lastMoveToTick = 0

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
            continue 
        end

        if targetAction == "WaitingRespawn" and hum.Health > 0 then
            targetAction = "Idle"
            lastAction = "Idle"
            logConsole("Karakter Respawn -> Kembali ke Idle")
        end

        -- [ PENGATUR WAKTU & FAILSAFE RESET (TANPA MATI) ]
        if targetAction ~= lastAction then
            globalStuckTimer = 0
            stateTimer = 0 
            lastAction = targetAction
            logConsole("Transisi Fase -> " .. tostring(targetAction))
        else
            globalStuckTimer = globalStuckTimer + 0.05
            stateTimer = stateTimer + 0.05 
            
            local maxTimeout = _G.failsafeTimeout or 25
            if globalStuckTimer >= maxTimeout then
                globalStuckTimer = 0
                stateTimer = 0
                hrp.CFrame = safeZoneCFrame
                targetAction = "Idle"
                logConsole("🚨 Failsafe Triggered: Auto-TP Safe Zone (Reset Idle)")
                continue
            end
        end

        local distToSafeZone = (hrp.Position - safeZone).Magnitude

        -- Fungsi helper jalan kaki mulus (Throttle MoveTo setiap 0.25s agar tidak stutter)
        local function smoothWalkToSafeZone()
            local now = tick()
            if now - lastMoveToTick >= 0.25 then
                lastMoveToTick = now
                hum:MoveTo(safeZone)
            end
        end

        -- [ FASE 1: IDLE / NENDANG DI SAFE ZONE (HANYA KICK JIKA METEOR SHOWER AKTIF) ]
        if targetAction == "Idle" then
            if distToSafeZone > 5 then
                -- Jika belum persis di Safe Zone, jalan terus sampai masuk zona
                smoothWalkToSafeZone()
            else
                if shouldKick() then
                    if stateTimer >= 0.4 then
                        phase2Fired = false
                        collectedFired = false
                        kickEndedFired = false
                        executeKick()
                        targetAction = "WaitingForPhase2"
                    end
                else
                    -- Jika event Meteor Shower tidak aktif, standby di titik Safe Zone
                    task.wait(0.1)
                end
            end

        -- [ FASE 2: NUNGGU PHASE 2 DARI SERVER -> LANGSUNG JALAN KE SAFEZONE ]
        elseif targetAction == "WaitingForPhase2" then
            if phase2Fired or collectedFired or kickEndedFired then
                phase2Fired = false
                collectedFired = false
                kickEndedFired = false
                targetAction = "WalkToSafeZone"
                logConsole("Phase 2 Selesai -> Mulai Jalan Menuju Safe Zone")
            elseif stateTimer >= 3.5 and not phase2Fired and not collectedFired and not kickEndedFired then
                -- Auto-Retry jika kick belum terdaftar di server
                logConsole("⚠️ [RETRY] Belum ada respon kick dalam 3.5s, mencoba tendang ulang...")
                stateTimer = 0
                executeKick()
            elseif stateTimer > 18 then
                targetAction = "WalkToSafeZone"
                logConsole("Phase 2 Timeout (18s) -> Jalan ke Safe Zone")
            end

        -- [ FASE 3: JALAN MURNI SAMPAI TUNTAS DI SAFE ZONE (<= 5 STUDS) ]
        elseif targetAction == "WalkToSafeZone" then
            smoothWalkToSafeZone()
            
            -- DIJAMIN tidak berhenti di tengah jalan: hanya transisi saat jarak <= 5 studs
            if distToSafeZone <= 5 then
                targetAction = "WaitingForCollected"
                logConsole("Tiba Tuntas di Safe Zone -> Menunggu Reward Selesai")
            end

        -- [ FASE 4: NUNGGU COLLECTED & RE-KICK INSTAN / STANDBY DI SAFE ZONE ]
        elseif targetAction == "WaitingForCollected" then
            if distToSafeZone > 5 then
                smoothWalkToSafeZone()
            end

            -- Tunggu konfirmasi collected atau jeda 1 detik setelah tiba di safe zone
            if collectedFired or kickEndedFired or stateTimer >= 1.2 then
                collectedFired = false
                kickEndedFired = false
                mutationCount = mutationCount + 1
                phase2Fired = false

                if shouldKick() then
                    executeKick()
                    targetAction = "WaitingForPhase2"
                    logConsole(string.format("🎉 Total Mutasi: %d | Re-Kick Langsung!", mutationCount))
                else
                    targetAction = "Idle"
                    logConsole(string.format("🎉 Total Mutasi: %d | Ronde Tuntas -> Standby di Safe Zone (Menunggu Event)", mutationCount))
                end
            end
        end
    end
end)

print("--------------------------------------------------")
print("🚀 [SUKSES] KALB Zero-Click & Smooth Walk Siap Berjalan!")
print("--------------------------------------------------")
