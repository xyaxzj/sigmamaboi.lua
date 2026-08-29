-- ==============================================================================
-- 🚀 AUTO SETOR EXCLUSIVE BRAINROT -> USERNAME: szeshuro + AUTO SERVER HOP
-- ⚡ ULTRA ANTI-LAG & POTATO MODE (60+ FPS & ZERO FREEZE)
-- ==============================================================================
-- Alur Kerja:
-- 1. 🥔 Aktifkan Ultra Anti-Lag (Matikan Shadow, Texture, Partikel, Efek Lighting & Potato Map).
-- 2. 🔍 Pindai seluruh inventory (Backpack & Karakter) untuk item bertipe "Exclusive".
-- 3. ❓ Cek ketersediaan item:
--    - Jika TIDAK ADA item Exclusive -> Langsung Server Hop ke server publik lain.
-- 4. 🎯 Cek keberadaan target (szeshuro) di server saat ini:
--    - Jika target TIDAK ADA di server -> Langsung Server Hop mencari server lain.
--    - Jika target ADA di server:
--      a. Kirim trade request ke szeshuro.
--      b. Masukkan semua item Exclusive (maksimal 10 item per kloter).
--      c. Tunggu countdown & auto confirm trade (Fase 1 & Fase 2).
--      d. Ulangi kloter berikutnya hingga SEMUA item Exclusive di inventory habis (0).
-- 5. 🌐 Setelah semua item Exclusive selesai disetor:
--    - Otomatis Server Hop ke server publik lain untuk mencari stok/server berikutnya!
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
-- ⚙️ KONFIGURASI PENGGUNA
-- ==============================================================================
local TARGET_USERNAME = "szeshuro"      -- Username tujuan setor
local TARGET_RARITY = "Exclusive"       -- Rarity yang disetor
local INSERT_DELAY = 0.25               -- Jeda input item ke trade slot (detik)
local TRADE_TIMEOUT = 20                -- Batas waktu menunggu target merespon trade (detik)
local AUTO_UNFAVORITE = true            -- Otomatis unfavorite item jika terkunci favorite
local AUTO_REQUEUE_ON_HOP = true        -- Otomatis jalankan script kembali setelah teleport ke server baru

-- 🥔 Pengaturan Anti-Lag
local ENABLE_ANTI_LAG = true            -- Aktifkan sistem anti-lag & FPS booster
local POTATO_WHITE_MAP = true           -- Ubah map menjadi putih & material plastic ringan
local DISABLE_SHADOWS = true            -- Matikan bayangan global
local REMOVE_PARTICLES = true           -- Hapus partikel, api, asap, dan efek berat

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

-- ==============================================================================
-- 🥔 1. ULTRA ANTI-LAG & POTATO MODE ENGINE (SUPER SMOOTH)
-- ==============================================================================
if ENABLE_ANTI_LAG then
    pcall(function()
        -- Setting Hardware / Rendering Level 1
        if settings and settings().Rendering then
            settings().Rendering.QualityLevel = 1
        end

        -- Lighting Optimization
        if DISABLE_SHADOWS then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
        end

        -- Hapus Efek Berat di Lighting
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("Atmosphere") then
                effect.Enabled = false
                effect:Destroy()
            end
        end

        -- Terrain Optimization
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
        if not v then return end
        -- Jangan ganggu karakter pemain sendiri atau target szeshuro
        if LocalPlayer.Character and (v == LocalPlayer.Character or v:IsDescendantOf(LocalPlayer.Character)) then return end
        local targetObj = Players:FindFirstChild(TARGET_USERNAME)
        if targetObj and targetObj.Character and (v == targetObj.Character or v:IsDescendantOf(targetObj.Character)) then return end

        pcall(function()
            local className = v.ClassName

            -- Hapus partikel dan efek cahaya berat
            if REMOVE_PARTICLES and PURGE_CLASSES[className] then
                v:Destroy()
                return
            end

            -- Hilangkan Decal & Tekstur jika Potato Mode aktif
            if POTATO_WHITE_MAP then
                if className == "Decal" or className == "Texture" or v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = 1
                    return
                end

                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                    v.CastShadow = false
                    v.Color = Color3.new(1, 1, 1) -- Potato White Map
                    if v:IsA("MeshPart") then
                        v.TextureID = ""
                    end
                elseif v:IsA("SpecialMesh") then
                    v.TextureId = ""
                end
            end
        end)
    end

    -- Sapu objek awal di workspace
    task.spawn(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            optimizeInstance(v)
        end
    end)

    -- Listener real-time untuk objek baru yang spawn
    workspace.DescendantAdded:Connect(function(v)
        task.defer(optimizeInstance, v)
    end)

    print("[⚡ Anti-Lag] Sistem Anti-Lag & Potato Mode Aktif!")
end

-- ==============================================================================
-- 🛡️ 2. ANTI-AFK SYSTEM (Mencegah Kick 20 Menit)
-- ==============================================================================
pcall(function()
    LocalPlayer.Idled:Connect(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end)

-- ==============================================================================
-- 📢 3. NOTIFIKASI & LOGGING
-- ==============================================================================
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Auto Setor",
            Text = text or "",
            Duration = duration or 4
        })
    end)
end

local function log(...)
    print("[📦 Auto Setor]", ...)
end

log("==================================================")
log("🚀 Script Auto Setor Dimulai! Target: " .. TARGET_USERNAME)
log("⚡ Anti-Lag & Booster: AKTIF")
log("==================================================")

-- ==============================================================================
-- 📡 4. INISIALISASI NETWORK REMOTES
-- ==============================================================================
local networkFolder = nil
pcall(function()
    local shared = ReplicatedStorage:WaitForChild("Shared", 5)
    local packages = shared and shared:WaitForChild("Packages", 5)
    networkFolder = packages and packages:WaitForChild("Network", 5)
end)

local ref_trade_r = networkFolder and networkFolder:FindFirstChild("ref_trade_r")
local rev_trade_i = networkFolder and networkFolder:FindFirstChild("rev_trade_i")
local rev_trade_start = networkFolder and networkFolder:FindFirstChild("rev_trade_start")
local rev_ToggleFav = networkFolder and networkFolder:FindFirstChild("rev_ToggleFav")

-- Fallback pencarian remote jika folder network berubah
if not ref_trade_r or not rev_trade_i then
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "ref_trade_r" and desc:IsA("RemoteFunction") then ref_trade_r = desc end
        if desc.Name == "rev_trade_i" and desc:IsA("RemoteEvent") then rev_trade_i = desc end
        if desc.Name == "rev_trade_start" and desc:IsA("RemoteEvent") then rev_trade_start = desc end
        if desc.Name == "rev_ToggleFav" and desc:IsA("RemoteEvent") then rev_ToggleFav = desc end
    end
end

-- ==============================================================================
-- 📚 5. DATABASE & ENTITIES DATA SCANNER
-- ==============================================================================
local EntitiesDataModule = nil
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local dataFolder = shared and shared:FindFirstChild("Data")
    local entitiesObj = dataFolder and dataFolder:FindFirstChild("EntitiesData")
    if entitiesObj then
        EntitiesDataModule = require(entitiesObj)
    end
end)

local function getToolGUID(tool)
    if not tool then return nil end
    return tool:GetAttribute("guid") or tool:GetAttribute("GUID") or tool:GetAttribute("uid")
end

local function isToolFavorite(tool)
    if not tool then return false end
    local isFav = tool:GetAttribute("Favorite") or tool:GetAttribute("favorite") or tool:GetAttribute("Fav") or tool:GetAttribute("isFav")
    if isFav ~= nil then return isFav == true end
    local favObj = tool:FindFirstChild("Favorite") or tool:FindFirstChild("favorite") or tool:FindFirstChild("Fav")
    if favObj and favObj:IsA("BoolValue") then return favObj.Value end
    return false
end

local function getToolRarity(tool)
    if not tool then return "Unknown" end
    local baseName = tool.Name

    -- 1. Cek EntitiesData runtime
    if EntitiesDataModule then
        if EntitiesDataModule.Brainrots and EntitiesDataModule.Brainrots[baseName] then
            local r = EntitiesDataModule.Brainrots[baseName].Rarity
            if r and r ~= "" then return r end
        end
        if EntitiesDataModule.LuckyBlocks and EntitiesDataModule.LuckyBlocks[baseName] then
            local r = EntitiesDataModule.LuckyBlocks[baseName].Rarity
            if r and r ~= "" then return r end
        end
    end

    -- 2. Cek Attribute pada Tool
    local attrRarity = tool:GetAttribute("Rarity") or tool:GetAttribute("rarity") or tool:GetAttribute("RarityName")
    if attrRarity and tostring(attrRarity) ~= "" then
        return tostring(attrRarity)
    end

    -- 3. Cek Child Value pada Tool
    local rarityObj = tool:FindFirstChild("Rarity") or tool:FindFirstChild("rarity")
    if rarityObj and rarityObj:IsA("StringValue") and rarityObj.Value ~= "" then
        return rarityObj.Value
    end

    return "Unknown"
end

local function isTargetExclusiveTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local guid = getToolGUID(tool)
    if not guid then return false end

    local rarity = getToolRarity(tool)
    if string.lower(rarity) == string.lower(TARGET_RARITY) then
        return true
    end

    -- Khusus item Lucky Block / Item Exclusive bawaan
    local lowerName = string.lower(tool.Name)
    if lowerName == "virus" or lowerName == "block cup" or lowerName == "volcanic" or lowerName == "weather" or lowerName == "rainbow" or lowerName == "eternal" then
        return true
    end

    return false
end

local function getExclusiveToolsInInventory()
    local exclusiveList = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character

    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if isTargetExclusiveTool(t) then
                table.insert(exclusiveList, t)
            end
        end
    end

    if char then
        for _, t in ipairs(char:GetChildren()) do
            if isTargetExclusiveTool(t) then
                table.insert(exclusiveList, t)
            end
        end
    end

    return exclusiveList
end

-- ==============================================================================
-- 🌐 6. PUBLIC SERVER HOPPING SYSTEM
-- ==============================================================================
local function queueScriptExecution()
    if not AUTO_REQUEUE_ON_HOP then return end
    pcall(function()
        local scriptSource = ""
        if readfile and isfile and isfile("auto setor.lua") then
            scriptSource = readfile("auto setor.lua")
        elseif readfile and isfile and isfile("Untuk Auto Trade/auto setor.lua") then
            scriptSource = readfile("Untuk Auto Trade/auto setor.lua")
        end

        if scriptSource ~= "" then
            if queue_on_teleport then
                queue_on_teleport(scriptSource)
            elseif syn and syn.queue_on_teleport then
                syn.queue_on_teleport(scriptSource)
            elseif fluxus and fluxus.queue_on_teleport then
                fluxus.queue_on_teleport(scriptSource)
            end
        end
    end)
end

local function serverHop()
    log("🌐 Memulai pencarian Server Publik lain...")
    notify("🌐 Server Hop", "Mencari server publik baru...", 4)
    queueScriptExecution()

    task.spawn(function()
        local placeId = game.PlaceId
        local currentJobId = game.JobId
        local candidateServers = {}

        -- Query server publik Roblox API
        local success, response = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
            return game:HttpGet(url)
        end)

        if success and response then
            local decoded = nil
            pcall(function() decoded = HttpService:JSONDecode(response) end)

            if decoded and decoded.data then
                for _, s in ipairs(decoded.data) do
                    if type(s) == "table" and s.id and s.playing and s.maxPlayers then
                        if s.id ~= currentJobId and s.playing < s.maxPlayers and s.playing > 0 then
                            table.insert(candidateServers, s)
                        end
                    end
                end
            end
        end

        if #candidateServers > 0 then
            -- Pilih server acak yang tersedia
            local chosen = candidateServers[math.random(1, #candidateServers)]
            log(string.format("🚀 Teleportasi ke Server ID: %s (%d/%d pemain)...", chosen.id, chosen.playing, chosen.maxPlayers))
            
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, chosen.id, LocalPlayer)
            end)
        else
            log("⚠️ Tidak ada daftar server spesifik, melakukan teleport acak...")
            pcall(function()
                TeleportService:Teleport(placeId, LocalPlayer)
            end)
        end
    end)
end

-- Listener jika teleport gagal
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    log("⚠️ Teleport gagal: " .. tostring(errorMessage) .. ". Mengulang Server Hop...")
    task.wait(2)
    serverHop()
end)

-- ==============================================================================
-- 🤝 7. PROSES TRADE KE TARGET (szeshuro)
-- ==============================================================================
local function findTargetPlayer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and string.lower(p.Name) == string.lower(TARGET_USERNAME) then
            return p
        end
    end
    return nil
end

local function isLocalConfirmed(tradeFrame)
    if not tradeFrame then return false end
    local p1 = tradeFrame:FindFirstChild("P1_Frame") and tradeFrame.P1_Frame:FindFirstChild("Confirmed")
    return p1 and p1.Visible or false
end

local function isOpponentConfirmed(tradeFrame)
    if not tradeFrame then return false end
    local p2 = tradeFrame:FindFirstChild("P2_Frame") and tradeFrame.P2_Frame:FindFirstChild("Confirmed")
    return p2 and p2.Visible or false
end

local function executeTradeBatch(targetPlayer, itemsToTrade)
    if not targetPlayer or #itemsToTrade == 0 then return false end
    if not ref_trade_r or not rev_trade_i then
        log("❌ Error: Remote Trade tidak siap!")
        return false
    end

    log(string.format("📤 Mengirim Trade Request ke %s (Kloter: %d item)...", targetPlayer.Name, #itemsToTrade))
    notify("🤝 Trade Request", "Mengajak trade " .. targetPlayer.Name .. " (" .. #itemsToTrade .. " item)...", 3)

    -- Kirim Trade Request
    local requestSent = false
    pcall(function()
        task.spawn(function()
            ref_trade_r:InvokeServer(targetPlayer.UserId)
        end)
        requestSent = true
    end)

    -- Tunggu TradingFrame terbuka di PlayerGui
    local tradeFrame = nil
    local waitTimer = 0
    while waitTimer < TRADE_TIMEOUT do
        tradeFrame = LocalPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
        if tradeFrame and tradeFrame.Visible then
            break
        end
        task.wait(0.5)
        waitTimer = waitTimer + 0.5
    end

    if not (tradeFrame and tradeFrame.Visible) then
        log("⚠️ Timeout: Target tidak menerima trade request dalam waktu " .. TRADE_TIMEOUT .. " detik.")
        return false
    end

    log("✅ Trade window terbuka! Mulai memasukkan item...")
    notify("📦 Input Item", "Memasukkan " .. #itemsToTrade .. " item ke slot trade...", 3)

    -- Masukkan item ke trade slot
    for idx, tool in ipairs(itemsToTrade) do
        local guid = getToolGUID(tool)
        if guid then
            -- Unfavorite jika terkunci
            if AUTO_UNFAVORITE and isToolFavorite(tool) and rev_ToggleFav then
                pcall(function() rev_ToggleFav:FireServer(guid) end)
                task.wait(0.1)
            end

            pcall(function()
                rev_trade_i:FireServer("AddItem", tostring(guid))
            end)
            log(string.format("   [%d/%d] Ditambahkan: %s", idx, #itemsToTrade, tool.Name))
            task.wait(INSERT_DELAY)
        end
    end

    -- Tunggu timer countdown game (5.5 detik)
    log("⏳ Menunggu countdown trade phase 1 (5.5 detik)...")
    task.wait(5.5)

    -- Confirm Phase 1
    pcall(function()
        rev_trade_i:FireServer("Confirm")
    end)
    log("🔒 Konfirmasi Phase 1 terkirim.")

    -- Tunggu konfirmasi lawan / countdown phase 2
    local phase2Timer = 0
    while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do
        if not isLocalConfirmed(tradeFrame) then break end
        task.wait(0.2)
        phase2Timer = phase2Timer + 0.2
        if phase2Timer > 60 then
            log("⚠️ Trade timeout menunggu konfirmasi lawan.")
            return false
        end
    end

    -- Confirm Phase 2 jika window masih terbuka
    if tradeFrame and tradeFrame.Parent and tradeFrame.Visible then
        log("⏳ Menunggu countdown trade phase 2 (5.5 detik)...")
        task.wait(5.5)
        pcall(function()
            rev_trade_i:FireServer("Confirm")
        end)
        log("🔒 Konfirmasi Phase 2 terkirim.")

        while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do
            task.wait(0.5)
        end
    end

    log("🎉 Kloter trade berhasil diselesaikan!")
    notify("✅ Trade Berhasil", #itemsToTrade .. " item Exclusive sukses terkirim!", 3)
    task.wait(1.5)
    return true
end

-- ==============================================================================
-- 🚀 8. FUNGSI UTAMA AUTO SETOR & HOP (1X EXECUTE)
-- ==============================================================================
local function runAutoSetor()
    log("🔍 Memeriksa stok item Exclusive di tas...")
    local exclusiveItems = getExclusiveToolsInInventory()
    local totalExclusive = #exclusiveItems

    log(string.format("📊 Ditemukan %d item Exclusive di inventory.", totalExclusive))

    -- KASUS 1: Tidak ada item Exclusive sama sekali di tas
    if totalExclusive == 0 then
        log("ℹ️ Tidak ada Brainrot Exclusive di inventory. Segera melakukan Server Hop...")
        notify("📦 Stok Kosong", "Tidak ada item Exclusive di tas. Memulai Server Hop...", 4)
        task.wait(1)
        serverHop()
        return
    end

    -- KASUS 2: Ada item Exclusive, cek target szeshuro
    local targetPlayer = findTargetPlayer()
    if not targetPlayer then
        log(string.format("⚠️ Target '%s' TIDAK DITEMUKAN di server ini!", TARGET_USERNAME))
        log(string.format("ℹ️ Memiliki %d item Exclusive, berpindah server untuk mencari target...", totalExclusive))
        notify("⚠️ Target Tidak Ada", "Target " .. TARGET_USERNAME .. " tidak di server. Melakukan Server Hop...", 4)
        task.wait(1)
        serverHop()
        return
    end

    -- KASUS 3: Ada item Exclusive DAN target ada di server!
    log(string.format("🎯 Target '%s' DITEMUKAN! Memulai setor %d item Exclusive...", targetPlayer.Name, totalExclusive))
    notify("🎯 Target Ditemukan", "Memulai setor " .. totalExclusive .. " item ke " .. targetPlayer.Name .. "...", 4)

    local totalSent = 0
    local retryCount = 0

    while true do
        local remainingItems = getExclusiveToolsInInventory()
        if #remainingItems == 0 then
            log("🎉 SEMUA ITEM EXCLUSIVE TELAH HABIS DISETOR!")
            notify("🏆 Selesai", "Semua item Exclusive berhasil disetor ke " .. TARGET_USERNAME .. "!", 5)
            break
        end

        -- Ambil maksimal 10 item per kloter
        local batch = {}
        for i = 1, math.min(10, #remainingItems) do
            table.insert(batch, remainingItems[i])
        end

        local success = executeTradeBatch(targetPlayer, batch)
        if success then
            totalSent = totalSent + #batch
            retryCount = 0
            task.wait(1.5)
        else
            retryCount = retryCount + 1
            log(string.format("⚠️ Trade gagal atau ditolak. Percobaan ulang #%d/3...", retryCount))
            if retryCount >= 3 then
                log("❌ Gagal trade 3x berturut-turut. Membatalkan dan melakukan Server Hop...")
                break
            end
            task.wait(2)
        end
    end

    -- Setelah semua selesai disetor, lakukan Server Hop ke server publik lain
    log("==================================================")
    log(string.format("🚀 Total %d item Exclusive disetor. Berpindah ke server publik lain...", totalSent))
    log("==================================================")
    notify("🌐 Selesai Setor", "Berhasil setor " .. totalSent .. " item. Melakukan Server Hop...", 4)
    task.wait(1.5)
    serverHop()
end

-- Jalankan otomatis saat di-execute
runAutoSetor()
