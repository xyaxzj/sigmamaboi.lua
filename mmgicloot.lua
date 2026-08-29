-- ==============================================================================
-- 🚀 AUTO SETOR (FRIGOREX & PATAGOTITAN) -> USERNAME: szeshuro + AUTO SERVER HOP
-- ⚡ ULTRA ANTI-LAG & POTATO MODE (60+ FPS & ZERO FREEZE)
-- ⏱️ SYNCHRONIZED TIMING DENGAN AUTO TRADE.LUA (5.1s Countdown & Phase Handshake)
-- 🔒 ANTI-PREMATURE HOP: HANYA HOP JIKA SEMUA STOK FRIGOREX & PATAGOTITAN BENAR-BENAR 0!
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
-- ⚙️ KONFIGURASI PENGGUNA
-- ==============================================================================
local TARGET_USERNAME = "szeshuro"      -- Username tujuan setor

-- 🦖 Daftar Item Khusus yang Disetor (Hanya Frigorex & Patagotitan)
local TARGET_ITEMS = {
    ["frigorex"] = true,
    ["patagotitan"] = true,
    ["frigo"] = true,
    ["patago"] = true,
}

local INSERT_DELAY = 0.25               -- Jeda input item ke trade slot (detik)
local TRADE_TIMEOUT = 15                -- Batas waktu menunggu target merespon trade (detik)
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
        if settings and settings().Rendering then
            settings().Rendering.QualityLevel = 1
        end

        if DISABLE_SHADOWS then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
        end

        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("Atmosphere") then
                effect.Enabled = false
                effect:Destroy()
            end
        end

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
        if LocalPlayer.Character and (v == LocalPlayer.Character or v:IsDescendantOf(LocalPlayer.Character)) then return end
        local targetObj = Players:FindFirstChild(TARGET_USERNAME)
        if targetObj and targetObj.Character and (v == targetObj.Character or v:IsDescendantOf(targetObj.Character)) then return end

        pcall(function()
            local className = v.ClassName

            if REMOVE_PARTICLES and PURGE_CLASSES[className] then
                v:Destroy()
                return
            end

            if POTATO_WHITE_MAP then
                if className == "Decal" or className == "Texture" or v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = 1
                    return
                end

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
                end
            end
        end)
    end

    task.spawn(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            optimizeInstance(v)
        end
    end)

    workspace.DescendantAdded:Connect(function(v)
        task.defer(optimizeInstance, v)
    end)

    print("[⚡ Anti-Lag] Sistem Anti-Lag & Potato Mode Aktif!")
end

-- ==============================================================================
-- 🛡️ 2. ANTI-AFK SYSTEM
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
log("🦖 Target Item: Frigorex & Patagotitan")
log("⚡ Timing: Synchronized dengan Auto Trade Receiver (5.1s)")
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

if not ref_trade_r or not rev_trade_i then
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "ref_trade_r" and desc:IsA("RemoteFunction") then ref_trade_r = desc end
        if desc.Name == "rev_trade_i" and desc:IsA("RemoteEvent") then rev_trade_i = desc end
        if desc.Name == "rev_trade_start" and desc:IsA("RemoteEvent") then rev_trade_start = desc end
        if desc.Name == "rev_ToggleFav" and desc:IsA("RemoteEvent") then rev_ToggleFav = desc end
    end
end

-- ==============================================================================
-- 📚 5. ITEM SCANNER (KHUSUS FRIGOREX & PATAGOTITAN)
-- ==============================================================================
local function getToolGUID(tool)
    if not tool then return nil end
    local g = tool:GetAttribute("guid") or tool:GetAttribute("GUID") or tool:GetAttribute("uid") or tool:GetAttribute("UID") or tool:GetAttribute("id") or tool:GetAttribute("ID") or tool:GetAttribute("itemId")
    if g then return tostring(g) end
    
    local child = tool:FindFirstChild("guid") or tool:FindFirstChild("GUID") or tool:FindFirstChild("uid") or tool:FindFirstChild("UID") or tool:FindFirstChild("id")
    if child and (child:IsA("StringValue") or child:IsA("IntValue") or child:IsA("NumberValue")) then 
        return tostring(child.Value) 
    end
    
    return tool.Name
end

local function isToolFavorite(tool)
    if not tool then return false end
    local isFav = tool:GetAttribute("Favorite") or tool:GetAttribute("favorite") or tool:GetAttribute("Fav") or tool:GetAttribute("isFav")
    if isFav ~= nil then return isFav == true end
    local favObj = tool:FindFirstChild("Favorite") or tool:FindFirstChild("favorite") or tool:FindFirstChild("Fav")
    if favObj and favObj:IsA("BoolValue") then return favObj.Value end
    return false
end

local function isTargetSetorTool(tool)
    if not tool or not tool:IsA("Tool") then return false end

    local toolName = string.lower(tool.Name)
    local isMatch = false

    for targetKey, _ in pairs(TARGET_ITEMS) do
        if string.find(toolName, targetKey) then
            isMatch = true
            break
        end
    end

    if not isMatch then
        local attrName = tool:GetAttribute("ItemName") or tool:GetAttribute("Name") or tool:GetAttribute("name")
        if attrName then
            local lowerAttr = string.lower(tostring(attrName))
            for targetKey, _ in pairs(TARGET_ITEMS) do
                if string.find(lowerAttr, targetKey) then
                    isMatch = true
                    break
                end
            end
        end
    end

    return isMatch
end

local function getTargetToolsInInventory()
    local targetList = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character

    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if isTargetSetorTool(t) then
                table.insert(targetList, t)
            end
        end
    end

    if char then
        for _, t in ipairs(char:GetChildren()) do
            if isTargetSetorTool(t) then
                table.insert(targetList, t)
            end
        end
    end

    return targetList
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

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    log("⚠️ Teleport gagal: " .. tostring(errorMessage) .. ". Mengulang Server Hop...")
    task.wait(2)
    serverHop()
end)

-- ==============================================================================
-- 🤝 7. PROSES TRADE KE TARGET (szeshuro)
-- ==============================================================================
local function findTargetPlayer()
    local targetLower = string.lower(TARGET_USERNAME)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if string.lower(p.Name) == targetLower or string.lower(p.DisplayName) == targetLower then
                return p
            end
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
    pcall(function()
        task.spawn(function()
            pcall(function() ref_trade_r:InvokeServer(targetPlayer.UserId) end)
        end)
    end)

    -- Tunggu TradingFrame terbuka di PlayerGui
    local tradeFrame = nil
    local timer = 0
    while timer < TRADE_TIMEOUT do
        tradeFrame = LocalPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
        if tradeFrame and tradeFrame.Visible then
            break
        end
        task.wait(1)
        timer = timer + 1
    end

    if not (tradeFrame and tradeFrame.Visible) then
        log("⚠️ Target belum merespon trade request (" .. timer .. "s).")
        return false
    end

    log("✅ Trade window terbuka! Memasukkan item...")
    notify("📦 Input Item", "Memasukkan " .. #itemsToTrade .. " item ke slot trade...", 3)

    -- Masukkan item ke trade slot
    for idx, tool in ipairs(itemsToTrade) do
        local guid = getToolGUID(tool)
        if guid then
            if AUTO_UNFAVORITE and isToolFavorite(tool) and rev_ToggleFav then
                pcall(function() rev_ToggleFav:FireServer(guid) end)
                task.wait(0.05)
            end

            pcall(function()
                rev_trade_i:FireServer("AddItem", tostring(guid))
            end)
            log(string.format("   [%d/%d] Ditambahkan: %s", idx, #itemsToTrade, tool.Name))
            task.wait(INSERT_DELAY)
        end
    end

    -- Phase 1 Countdown 5.1s
    log("⏳ Menunggu countdown Phase 1 (5.1 detik)...")
    task.wait(5.1)
    pcall(function()
        rev_trade_i:FireServer("Confirm")
    end)
    log("🔒 Konfirmasi Phase 1 terkirim. Menunggu respon dari receiver...")
    task.wait(0.5)

    -- Tunggu konfirmasi receiver (Phase 1)
    local waitTimeout = 0
    while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do
        if not isLocalConfirmed(tradeFrame) then
            break
        end
        task.wait(0.2)
        waitTimeout = waitTimeout + 0.2
        if waitTimeout > 60 then
            log("❌ Timeout menunggu konfirmasi Phase 1 dari receiver (>60s).")
            return false
        end
    end

    -- Phase 2 Countdown 5.1s
    if tradeFrame and tradeFrame.Parent and tradeFrame.Visible then
        log("⏳ Menunggu countdown Phase 2 (5.1 detik)...")
        task.wait(5.1)
        pcall(function()
            rev_trade_i:FireServer("Confirm")
        end)
        log("🔒 Konfirmasi Phase 2 terkirim. Menunggu transaksi final...")

        while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do
            task.wait(0.5)
        end
    end

    log("🎉 Kloter trade berhasil diselesaikan secara sempurna!")
    notify("✅ Trade Berhasil", #itemsToTrade .. " item sukses terkirim!", 3)
    return true
end

-- ==============================================================================
-- 🚀 8. FUNGSI UTAMA AUTO SETOR & HOP (1X EXECUTE)
-- ==============================================================================
local function runAutoSetor()
    -- 1. Unequip semua tool agar tersimpan rapi di Backpack
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid:UnequipTools()
            task.wait(0.4)
        end
    end)

    log("🔍 Memeriksa stok Frigorex & Patagotitan di tas...")
    local initialItems = getTargetToolsInInventory()
    local totalInitial = #initialItems

    log(string.format("📊 Ditemukan %d item Frigorex & Patagotitan di inventory.", totalInitial))

    -- KASUS 1: Jika stok Frigorex & Patagotitan memang 0 dari awal
    if totalInitial == 0 then
        log("ℹ️ Tidak ada Frigorex atau Patagotitan di inventory. Segera melakukan Server Hop...")
        notify("📦 Stok Kosong", "Tidak ada Frigorex / Patagotitan di tas. Memulai Server Hop...", 4)
        task.wait(1.5)
        serverHop()
        return
    end

    -- KASUS 2: Cari target szeshuro (tunggu hingga 10 detik jika baru load)
    local targetPlayer = findTargetPlayer()
    local findTimer = 0
    while not targetPlayer and findTimer < 10 do
        task.wait(1)
        findTimer = findTimer + 1
        targetPlayer = findTargetPlayer()
    end

    if not targetPlayer then
        log(string.format("⚠️ Target '%s' TIDAK DITEMUKAN di server ini setelah 10 detik!", TARGET_USERNAME))
        log(string.format("ℹ️ Memiliki %d item Frigorex & Patagotitan, berpindah server untuk mencari target...", totalInitial))
        notify("⚠️ Target Tidak Ada", "Target " .. TARGET_USERNAME .. " tidak di server. Melakukan Server Hop...", 4)
        task.wait(2)
        serverHop()
        return
    end

    -- KASUS 3: Target DITEMUKAN & Ada Item!
    log(string.format("🎯 Target '%s' DITEMUKAN! Memulai proses setor %d item...", targetPlayer.Name, totalInitial))
    notify("🎯 Target Ditemukan", "Memulai setor " .. totalInitial .. " item ke " .. targetPlayer.Name .. "...", 4)

    local totalSent = 0

    -- 🔁 LOOP TERUS SAMPAI SEMUA FRIGOREX & PATAGOTITAN DI TAS BENAR-BENAR HABIS (0)!
    while true do
        -- Pastikan unequip tool setiap awal putaran
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character.Humanoid:UnequipTools()
            end
        end)
        task.wait(0.5)

        local currentStock = getTargetToolsInInventory()
        local remainingCount = #currentStock

        if remainingCount == 0 then
            log("🎉 SEMUA FRIGOREX & PATAGOTITAN TELAH HABIS DISETOR (Sisa: 0)!")
            notify("🏆 Selesai", "Semua Frigorex & Patagotitan berhasil disetor ke " .. TARGET_USERNAME .. "!", 5)
            break
        end

        log(string.format("📦 Sisa stok Frigorex & Patagotitan: %d item. Menyiapkan kloter trade...", remainingCount))

        -- Ambil maksimal 10 item per kloter
        local batch = {}
        for i = 1, math.min(10, remainingCount) do
            table.insert(batch, currentStock[i])
        end

        -- Pastikan target masih ada di server
        targetPlayer = findTargetPlayer()
        if not targetPlayer then
            log("⚠️ Target " .. TARGET_USERNAME .. " terputus dari server. Berpindah server...")
            notify("⚠️ Target Hilang", "Target keluar server. Melakukan Server Hop...", 4)
            task.wait(2)
            serverHop()
            return
        end

        local success = executeTradeBatch(targetPlayer, batch)
        if success then
            totalSent = totalSent + #batch
            log(string.format("✅ Kloter berhasil (%d item)! Total disetor: %d. Jeda 3.5 detik untuk kloter berikutnya...", #batch, totalSent))
            task.wait(3.5)
        else
            log("⚠️ Kloter trade belum berhasil / sedang sibuk. Mengulang kembali dalam 3 detik (TIDAK HOP, lanjut setor)...")
            task.wait(3.0)
        end
    end

    -- 🌐 HANYA SERVER HOP KETIKA SEMUA STOK DI TAS SUDAH HABIS (0)!
    log("==================================================")
    log(string.format("🚀 Total %d item Frigorex & Patagotitan berhasil disetor ke %s. Berpindah ke server publik lain...", totalSent, TARGET_USERNAME))
    log("==================================================")
    notify("🌐 Selesai Setor", "Berhasil setor " .. totalSent .. " item. Melakukan Server Hop...", 4)
    task.wait(2)
    serverHop()
end

-- Jalankan otomatis saat di-execute
runAutoSetor()
