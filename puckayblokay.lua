-- ==============================================================================
-- MIRAGE HUB VERCEL CLOUD BRIDGE (100% VERCEL NATIVE)
-- ==============================================================================
-- Deskripsi: Modul ini menghubungkan Roblox client langsung ke Web Vercel Anda.
-- Saat script ini dieksekusi, bot langsung terhubung secara otomatis ke Web.
-- ==============================================================================

local VERCEL_URL = "https://web-dashboard-five-navy.vercel.app"
local POLL_INTERVAL = 1.0 -- Frekuensi cek perintah (detik)
local TELEMETRY_INTERVAL = 3.0 -- Frekuensi kirim data inventory & status (detik)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

-- Deteksi fungsi HTTP executor
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
if not httpRequest then
    warn("[MiRaGe Bridge] Executor Anda tidak mendukung HTTP Request!")
    return
end

print("[MiRaGe Bridge] Menginisialisasi koneksi ke Vercel Cloud: " .. VERCEL_URL)

-- State global yang disinkronkan dengan auto trade.lua
_G.MiRaGeBridge = _G.MiRaGeBridge or {}
_G.MiRaGeBridge.Connected = true
_G.MiRaGeBridge.LastCommandId = ""
_G.MoctaBridge = _G.MiRaGeBridge -- Alias untuk kompatibilitas

-- Helper HTTP Request aman
local function safeRequest(options)
    local success, response = pcall(function()
        return httpRequest(options)
    end)
    if success and response and (response.StatusCode == 200 or response.Success) then
        return true, response.Body
    end
    return false, nil
end

-- 1. FUNGSI MENGAMBIL DAFTAR PLAYER DI SERVER
local function getServerPlayers()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

-- Helper CPS Formatter
local function formatCPSDisplay(num)
    if not num or type(num) ~= "number" then return nil end
    if num >= 1e9 then
        return string.format("%.2fB CPS", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.2fM CPS", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK CPS", num / 1e3)
    else
        return string.format("%.0f CPS", num)
    end
end

local function getToolLevel(tool)
    if not tool then return 1 end
    for _, attr in ipairs({"Level", "level", "Lvl", "lvl", "ItemLevel"}) do
        local v = tool:GetAttribute(attr)
        if v and tonumber(v) then return tonumber(v) end
    end
    for _, name in ipairs({"Level", "level", "Lvl", "lvl"}) do
        local obj = tool:FindFirstChild(name)
        if obj and tonumber(obj.Value) then return tonumber(obj.Value) end
    end
    local m = string.match(tool.Name, "%(Lv%.(%d+)%)") or string.match(tool.Name, "Lv%.(%d+)")
    if m and tonumber(m) then return tonumber(m) end
    return 1
end

local function getToolMutation(tool)
    if not tool then return "None" end
    local m = tool:GetAttribute("Mutation") or tool:GetAttribute("Variant") or (tool:FindFirstChild("Mutation") and tool:FindFirstChild("Mutation").Value)
    if m and tostring(m) ~= "" and tostring(m) ~= "None" and tostring(m) ~= "Standard" then
        return tostring(m)
    end
    local bracketMut = string.match(tool.Name, "%[(.-)%]")
    if bracketMut and bracketMut ~= "" then return bracketMut end
    return "None"
end

local function getExclusivePercent(tool)
    if not tool then return nil end
    for _, attr in ipairs({"KickPowerMultiplier", "Multiplier", "Percent", "Value", "Boost", "Power"}) do
        local v = tool:GetAttribute(attr)
        if v and tonumber(v) then
            local n = tonumber(v)
            return (n > 0 and n <= 50) and string.format("%.0f%%", n * 100) or string.format("%.0f%%", n)
        end
    end
    local pctMatch = string.match(tool.Name, "%((%d+%%)%)")
    if pctMatch then return pctMatch end
    return nil
end

local function getToolCPS(tool)
    if not tool then return nil end
    local baseName = tool.Name
    baseName = string.gsub(baseName, "%s*%(Lv%.%d+%)", "")
    baseName = string.gsub(baseName, "%s*%[.*%]", "")
    baseName = string.gsub(baseName, "%s*%(%d+%%%)", "")
    baseName = baseName:match("^%s*(.-)%s*$") or baseName

    local level = getToolLevel(tool) or 1
    local mutation = getToolMutation(tool)

    local EntitiesDataModule, MutationDataModule
    pcall(function()
        local Shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
        local Data = Shared and Shared:FindFirstChild("Data")
        local EntitiesDataObj = Data and Data:FindFirstChild("EntitiesData")
        if EntitiesDataObj then EntitiesDataModule = require(EntitiesDataObj) end
        local MutationDataObj = Data and Data:FindFirstChild("MutationData")
        if MutationDataObj then MutationDataModule = require(MutationDataObj) end
    end)

    if EntitiesDataModule and EntitiesDataModule.Brainrots and EntitiesDataModule.Brainrots[baseName] then
        local info = EntitiesDataModule.Brainrots[baseName]
        local baseCPS = info.CPS
        if baseCPS then
            local levelMult = 1
            if EntitiesDataModule.GetMultiplierPerLevel then
                pcall(function() levelMult = EntitiesDataModule.GetMultiplierPerLevel(level) end)
            end
            local mutMult = 1
            if mutation and mutation ~= "None" and MutationDataModule and MutationDataModule.Buffs and MutationDataModule.Buffs[mutation] then
                mutMult = MutationDataModule.Buffs[mutation].Value or 1
            end
            return baseCPS * levelMult * mutMult
        end
    end
    return nil
end

-- 2. FUNGSI MENGAMBIL SNAPSHOT INVENTORY
local function getInventorySnapshot()
    local items = {}
    local id = 1
    local allTools = {}
    if localPlayer then
        if localPlayer:FindFirstChild("Backpack") then
            for _, t in ipairs(localPlayer.Backpack:GetChildren()) do
                if t:IsA("Tool") then table.insert(allTools, t) end
            end
        end
        if localPlayer.Character then
            for _, t in ipairs(localPlayer.Character:GetChildren()) do
                if t:IsA("Tool") then table.insert(allTools, t) end
            end
        end
    end

    for _, tool in ipairs(allTools) do
        local rarityAttr = tool:GetAttribute("Rarity") or tool:GetAttribute("rarity") or "Common"
        local mutation = getToolMutation(tool)
        local isFav = (tool:GetAttribute("Favorite") == true) or (tool:GetAttribute("fav") == true) or (tool:FindFirstChild("Favorite") and tool:FindFirstChild("Favorite").Value == true)
        local level = getToolLevel(tool)
        local rawCps = getToolCPS(tool)
        local cpsStr = rawCps and formatCPSDisplay(rawCps) or nil
        local exclPct = getExclusivePercent(tool)

        table.insert(items, {
            id = id,
            name = tool.Name,
            rarity = tostring(rarityAttr),
            mutation = mutation,
            cps = cpsStr,
            level = level,
            exclusivePct = exclPct,
            qty = 1,
            fav = isFav
        })
        id = id + 1
    end
    return items
end

-- 3. FUNGSI KIRIM TELEMETRY DARI ROBLOX KE VERCEL
local function sendTelemetry()
    local payload = {
        source = "roblox",
        username = localPlayer and localPlayer.Name or "Unknown",
        jobId = game.JobId,
        status = _G.MiRaGeBridge.Status or "IDLE",
        tradesCompleted = _G.P1TradesCompleted or 0,
        itemsSent = _G.TotalItemsSent or 0,
        netCPS = _G.NetSentCPS or 0,
        sessionSeconds = math.floor(tick() - (_G.SessionStartTime or tick())),
        players = getServerPlayers(),
        inventory = getInventorySnapshot()
    }

    local jsonBody = HttpService:JSONEncode(payload)
    safeRequest({
        Url = VERCEL_URL .. "/api/bot",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = jsonBody
    })
end

-- 4. HANDLER EKSEKUSI PERINTAH DARI WEB
local function executeCommand(cmd)
    local action = cmd.action
    local payload = cmd.payload or {}
    print("[MiRaGe Bridge] Menerima perintah Web: " .. tostring(action))

    if action == "START_TRADE_ROUTINE" or action == "START_TRADE" then
        _G.AutoLoopEnabled = true
        _G.MiRaGeBridge.Status = "TRADING"
        if _G.StartTradeLoop then pcall(_G.StartTradeLoop) end

    elseif action == "PAUSE_TRADE_ROUTINE" or action == "PAUSE_TRADE" then
        _G.AutoLoopEnabled = false
        _G.MiRaGeBridge.Status = "IDLE"

    elseif action == "SET_AUTO_TRADE_LOOP" then
        _G.AutoLoopEnabled = (payload.enabled == true)
        _G.MiRaGeBridge.Status = _G.AutoLoopEnabled and "TRADING" or "IDLE"
        if _G.AutoLoopEnabled and _G.StartTradeLoop then pcall(_G.StartTradeLoop) end

    elseif action == "SET_TARGET_PLAYER" then
        if payload.player then
            _G.TargetPlayerName = payload.player
            print("[MiRaGe Bridge] Target Player diatur ke: " .. tostring(payload.player))
        end

    elseif action == "UPDATE_QUEUE" then
        if payload.queue then
            _G.ShoppingCart = payload.queue
            _G.CurrentQueue = payload.queue
            print("[MiRaGe Bridge] Antrean trade disinkronkan (" .. #payload.queue .. " items)")
        end

    elseif action == "CLEAR_QUEUE" then
        _G.ShoppingCart = {}
        _G.CurrentQueue = {}
        print("[MiRaGe Bridge] Antrean trade dikosongkan.")

    elseif action == "SET_INSERT_DELAY" then
        if payload.delay then
            _G.InsertDelay = tonumber(payload.delay) or 0.3
        end

    elseif action == "SET_AUTO_RECEIVER" then
        _G.AutoReceiverEnabled = (payload.enabled == true)

    elseif action == "SET_SKIP_FAVORITES" then
        _G.SkipFavorites = (payload.enabled == true)

    elseif action == "SET_AUTO_SELL" then
        _G.AutoSellEnabled = (payload.enabled == true)

    elseif action == "SET_SKIP_SELL_FAV" then
        _G.SkipSellFavorites = (payload.enabled == true)

    elseif action == "SET_AUTO_UPGRADE" then
        _G.AutoUpgradeEnabled = (payload.enabled == true)

    elseif action == "SET_AUTO_SWAP" then
        _G.AutoSwapMax = (payload.enabled == true)

    elseif action == "FORCE_SELL_BATCH" then
        if _G.SellBatchNow then
            pcall(_G.SellBatchNow)
        elseif _G.ForceSellBatch then
            pcall(_G.ForceSellBatch)
        end

    elseif action == "TOGGLE_FAVORITE" then
        if _G.ToggleFavorite then
            pcall(_G.ToggleFavorite, payload.itemId or payload.itemName, payload.fav)
        end

    elseif action == "TRIGGER_AUTO_FAVORITE_HIGH_TIERS" then
        if _G.AutoFavoriteHighTiers then
            pcall(_G.AutoFavoriteHighTiers)
        end

    elseif action == "EXECUTE_TOOL" then
        local toolName = payload.toolName
        if toolName and localPlayer and localPlayer.Character then
            local backpack = localPlayer:FindFirstChild("Backpack")
            local tool = (backpack and backpack:FindFirstChild(toolName)) or localPlayer.Character:FindFirstChild(toolName)
            if tool and tool:IsA("Tool") then
                tool.Parent = localPlayer.Character
                task.wait(0.1)
                pcall(function() tool:Activate() end)
            end
        end

    elseif action == "GET_SERVER_PLAYERS" or action == "SYNC_INVENTORY" or action == "QUERY_BASE_SLOTS" then
        task.spawn(sendTelemetry)

    elseif action == "RUN_COMMAND" then
        local cmdStr = payload.command
        if cmdStr and type(loadstring) == "function" then
            pcall(function()
                local fn, err = loadstring(cmdStr)
                if fn then fn() else warn("[MiRaGe Bridge] Command error: " .. tostring(err)) end
            end)
        end

    elseif action == "EMERGENCY_STOP" then
        _G.AutoLoopEnabled = false
        _G.AutoSellEnabled = false
        _G.AutoUpgradeEnabled = false
        _G.MiRaGeBridge.Status = "IDLE"
        print("[MiRaGe Bridge] !! EMERGENCY HALT DIAKTIFKAN OLEH WEB !!")

    elseif action == "REJOIN_SERVER" then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)

    elseif action == "SERVER_HOP" then
        pcall(function()
            local x = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            for _, s in pairs(x.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, localPlayer)
                    break
                end
            end
        end)
    end
end


-- 5. MAIN BACKGROUND THREAD (POLLING & SYNC LOOP)
task.spawn(function()
    print("[MiRaGe Bridge] Terhubung ke Vercel! Sinkronisasi otomatis berjalan.")
    sendTelemetry() -- Kirim data pertama kali saat execute

    local lastTelemetryTime = tick()

    while task.wait(POLL_INTERVAL) do
        -- A. Polling Perintah Baru dari Web Vercel
        local success, body = safeRequest({
            Url = VERCEL_URL .. "/api/bot?role=roblox",
            Method = "GET"
        })

        if success and body then
            local pcallSuccess, data = pcall(function()
                return HttpService:JSONDecode(body)
            end)

            if pcallSuccess and data and data.commands then
                for _, cmd in ipairs(data.commands) do
                    executeCommand(cmd)
                end
            end
        end

        -- B. Kirim Update Status & Inventory secara periodik
        if (tick() - lastTelemetryTime) >= TELEMETRY_INTERVAL then
            lastTelemetryTime = tick()
            task.spawn(sendTelemetry)
        end
    end
end)
