-- ==============================================================================
-- 🥔 KALB ULTRA LIGHTWEIGHT AUTO FARM V2 (METEOR SHOWER AUTO KICK & AUTO BUY)
-- ==============================================================================
-- Fitur & Alur:
-- 1. ⚙️ Full Config Mode: Semua pengaturan diatur via variabel _G di baris atas (Tanpa UI)
-- 2. 🚫 Total Player & Character Purger (100% Bersih):
--    - Menghapus & memusnahkan SEMUA player lain dari game.Players
--    - Menghapus SEMUA karakter player lain dari folder workspace.Players & workspace root
--    - Real-time listener + Background loop anti-bocor (tidak ada lagi yang lolos)
-- 3. ☄️ Meteor Shower Auto Kick: Bot menendang bola (nonstop / saat event)
-- 4. ☄️ Auto Meteor Event: Memperbesar hitbox meteor di Debris (200x200x200, CanQuery=true)
-- 5. 🛒 Auto Buy Frigorex: Request stock tiap 5 menit & auto beli jika stock > 0
-- 6. 🧪 Auto Buy Farm Potion: Auto beli 1x setiap pergantian jam ganjil (1, 3, 5... 23 WIB)
-- 7. 💰 Auto Sell All: Menjual semua brainrot tiap 5 detik (ref_B_SellAll)
-- 8. 🥔 Potato Mode Ekstrem & 🛡️ Anti-AFK
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
-- ⚙️ KONFIGURASI PENGGUNA (UBAH SESUAI KEBUTUHAN DI SINI)
-- ==============================================================================
_G.autoFarm = true               -- true: Auto Farm Aktif, false: Nonaktif
_G.onlyMeteorEvent = true        -- true: HANYA Auto Kick saat Event Meteor Shower aktif, false: Auto kick nonstop
_G.autoMeteor = true             -- true: Otomatis perbesar hitbox meteor saat Meteor Shower, false: Nonaktif
_G.autoBuyFrigorex = true        -- true: Cek stock Meteor Shop tiap 5 menit & auto beli Frigorex jika stock > 0
_G.autoBuyFarmPotion = true      -- true: Auto beli 1x Farm Potion setiap jam ganjil (1, 3, 5... 23 WIB)
_G.autoSellAll = true            -- true: Auto Sell All setiap 5 detik via ref_B_SellAll
_G.autoRemovePlayer = true       -- true: Hapus player lain dari game.Players & workspace.Players (100% Bersih & No Lag), false: Biarkan
_G.debugConsoleLog = false        -- true: Cetak log status/fase ke console (F9), false: Senyap
_G.failsafeTimeout = 25          -- Waktu maksimal (detik) sebelum auto-reset ke Safe Zone jika macet

print("--------------------------------------------------")
print("🚀 [INIT] Memuat KALB Auto Farm V2 (Ultra Lightweight & Total Player Purger)...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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

local lpName = lp and lp.Name or ""
local lpDisplayName = lp and lp.DisplayName or ""
local myUidStr = lp and tostring(lp.UserId) or ""

-- =============================================
-- 🚀 SYSTEM ANTI-LAG & POTATO MODE
-- =============================================
local function stripTexture(v)
    if not v then return end
    if lp and lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character)) then return end

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
end)

-- =============================================
-- 🚫 TOTAL PLAYER & CHARACTER PURGER (100% BERSIH)
-- =============================================
local function isLocalPlayerEntity(inst)
    if not inst then return false end
    if lp and inst == lp then return true end
    if lp and lp.Character and (inst == lp.Character or inst:IsDescendantOf(lp.Character)) then return true end
    local name = inst.Name
    if name == lpName or (lpDisplayName ~= "" and name == lpDisplayName) then return true end
    return false
end

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
-- ☄️ AUTO METEOR EVENT ENGINE (HITBOX EXPANDER)
-- =============================================
local OPTIMAL_METEOR_SIZE = Vector3.new(200, 200, 200)
local activeMeteors = {}
local isMeteorShowerActive = false

local function isTargetMeteorModel(model)
    if not model or not model:IsA("Model") then return false end
    local debris = workspace:FindFirstChild("Debris")
    if not debris or not model:IsDescendantOf(debris) then return false end
    return tonumber(model.Name) ~= nil
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
        print(string.format("☄️ [METEOR] Hitbox Model #%s diperbesar (200 studs, CanQuery=true)!", tostring(model.Name)))
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
        return isMeteorShowerActive
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
-- 🚀 FUNGSI EKSEKUSI TENDANGAN (100% ZERO-CLICK & REINFORCED)
-- =============================================
local function executeKick()
    local timestamp = nil
    pcall(function() timestamp = workspace:GetServerTimeNow() end)
    if not timestamp or type(timestamp) ~= "number" or timestamp <= 0 then
        timestamp = tick()
    end

    logConsole("⚡ Menendang Bola...")

    -- 1. Direct GameController Client Hook (Animasi, Visual Asli & Unlock Cooldown)
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

    -- 2. Jaringan Remote Resmi ke Server (Async Non-Blocking)
    task.spawn(function()
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
                -- Jika belum persis di Safe Zone, jalan kaki terus sampai masuk zona (Tanpa Teleport)
                hum:MoveTo(safeZone)
            else
                if shouldKick() then
                    if stateTimer >= 0.5 then
                        phase2Fired = false
                        collectedFired = false
                        kickEndedFired = false
                        executeKick()
                        targetAction = "WaitingForPhase2"
                    end
                else
                    -- Jika event Meteor Shower tidak aktif, standby di Safe Zone
                    task.wait(0.2)
                end
            end

        -- [ FASE 2: NUNGGU PHASE 2 DARI SERVER -> LANGSUNG JALAN KE SAFEZONE ]
        elseif targetAction == "WaitingForPhase2" then
            if phase2Fired or collectedFired or kickEndedFired then
                phase2Fired = false
                targetAction = "WalkToSafeZone"
                logConsole("Phase 2 Selesai -> Langsung Jalan ke Safe Zone")
            elseif stateTimer >= 5 and not phase2Fired and not collectedFired and not kickEndedFired then
                -- Auto-Retry Failsafe: Jika respon server belum terdeteksi dalam 3.5s, coba kick ulang
                logConsole("⚠️ [RETRY] Auto-Retry Kick (3.5s timeout)...")
                stateTimer = 0
                executeKick()
            elseif stateTimer > 18 then
                targetAction = "WalkToSafeZone"
                logConsole("Phase 2 Timeout (18s) -> Lanjut Jalan ke Safe Zone")
            end

        -- [ FASE 3: JALAN MURNI SAMPAI KE SAFE ZONE (TANPA TELEPORT) ]
        elseif targetAction == "WalkToSafeZone" then
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
