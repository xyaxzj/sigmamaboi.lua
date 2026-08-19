-- ==============================================================================
-- 🥔 KALB ULTRA LIGHTWEIGHT AUTO FARM & ANTI-LAG (ZERO MEMORY LEAK)
-- ==============================================================================
-- Fitur & Evaluasi:
-- 1. 🥔 Potato Mode Ekstrem: Hapus semua texture, PBR, bayangan, partikel, & efek Lighting
-- 2. 🚫 Total Player & Character Purger: Hapus karakter & instance player lain dari game.Players & workspace.Players
-- 3. 🛡️ Anti-AFK (VirtualUser) & Auto Garbage Collector (RAM tetap enteng berjam-jam)
-- 4. 💰 Auto Sell All (Setiap 5 detik via ref_B_SellAll)
-- 5. 🛒 Meteor Shop Auto Buy:
--    - 🦖 Patagotitan (⚡ON)
--    - ⚡ Speed (+1) (⚡ON)
--    - 👑 Frigorex (⚡ON)
--    - 🧪 Farm Potion (I) (Khusus Jam Ganjil WIB & Max Menit :10)
-- ==============================================================================

pcall(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
end)

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

local lpName = lp and lp.Name or ""
local lpDisplayName = lp and lp.DisplayName or ""
local myUidStr = lp and tostring(lp.UserId) or ""

-- =============================================
-- ⚙️ KONFIGURASI 
-- =============================================
_G.autoFarm = true
_G.autoBuyPatagotitan = true  -- 🦖 Patagotitan
_G.autoBuySpeed = true        -- ⚡ Speed (+1)
_G.autoBuyFrigorex = true     -- 👑 Frigorex
_G.autoBuyFarmPotion = true   -- 🧪 Farm Potion (I) (Khusus jam ganjil WIB max menit :10)
_G.autoSellAll = true         -- 💰 Auto Sell All tiap 5s
_G.autoRemovePlayer = true    -- 🚫 Hapus player lain dari game.Players & workspace.Players
_G.testWebhook = true        -- 📢 Ubah jadi true untuk langsung test kirim pesan Patagotitan & Frigorex ke Discord Webhook!

-- =============================================
-- 🚀 1. OPTIMISASI LIGHTING & SETTINGS GLOBAL (SUPER ENTENG)
-- =============================================
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 1
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") then
            effect.Enabled = false
            effect:Destroy()
        end
    end
end)

pcall(function()
    if settings and settings().Rendering then
        settings().Rendering.QualityLevel = 1
    end
end)

-- =============================================
-- 🥔 2. SYSTEM HAPUS TEKSTUR & MATERIAL (POTATO MAP)
-- =============================================
local function stripTexture(v)
    if not v then return end
    if lp and lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character)) then return end

    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
            v.Color = Color3.new(1, 1, 1)
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        elseif v:IsA("SurfaceAppearance") or v:IsA("Clothing") or v:IsA("ShirtGraphic") then
            v:Destroy()
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        end
    end)
end

for _, v in ipairs(workspace:GetDescendants()) do
    stripTexture(v)
end

workspace.DescendantAdded:Connect(function(v)
    task.defer(stripTexture, v)
end)

-- =============================================
-- 🚫 3. TOTAL PURGER (HAPUS OTHER PLAYER & DATA DI WORKSPACE + PLAYERS)
-- =============================================
local function isLocalPlayerEntity(entity)
    if not entity then return false end
    if entity == lp then return true end
    if lp and lp.Character and entity == lp.Character then return true end
    if entity.Name == lpName or (lpDisplayName ~= "" and entity.Name == lpDisplayName) then return true end
    return false
end

local function purgeOtherCharacter(char)
    if not char or not char:IsA("Model") or isLocalPlayerEntity(char) then return end
    pcall(function()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                part.CanCollide = false
            elseif part:IsA("Decal") or part:IsA("Texture") or part:IsA("Clothing") then
                part:Destroy()
            end
        end
        char:ClearAllChildren()
        char:Destroy()
    end)
end

local function purgeOtherPlayer(player)
    if not player or player == lp then return end
    pcall(function()
        if player.Character then
            purgeOtherCharacter(player.Character)
        end
    end)
    pcall(function()
        player:ClearAllChildren()
        player:Destroy()
    end)
end

local function scanAndPurgeAllOtherPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            purgeOtherPlayer(player)
        end
    end
    for _, child in ipairs(Players:GetChildren()) do
        if child ~= lp and child:IsA("Player") then
            purgeOtherPlayer(child)
        end
    end

    local wsPlayers = workspace:FindFirstChild("Players")
    if wsPlayers then
        for _, child in ipairs(wsPlayers:GetChildren()) do
            if child.Name ~= "Plots" and not isLocalPlayerEntity(child) then
                purgeOtherCharacter(child)
            end
        end
    end

    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and not isLocalPlayerEntity(child) and child.Name ~= "Plots" and child.Name ~= "Debris" and child.Name ~= "NPCs" and child.Name ~= "Players" then
            if child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Head") then
                purgeOtherCharacter(child)
            end
        end
    end
end

scanAndPurgeAllOtherPlayers()

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

-- =============================================
-- 🎯 4. DETEKTOR PLOT SENDIRI & REMOVER PLOT LAIN
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
-- 🧹 5. PERIODIC SWEEPER & GARBAGE COLLECTOR
-- =============================================
task.spawn(function()
    local cleanCounter = 0
    while task.wait(0.25) do
        if _G.autoRemovePlayer then
            pcall(scanAndPurgeAllOtherPlayers)
        end

        cleanCounter = cleanCounter + 1
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
-- 🛡️ 6. ANTI AFK (VIRTUALUSER)
-- =============================================
if lp then
    lp.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

-- =============================================
-- 📡 7. REMOTE NETWORK DISCOVERY
-- =============================================
local networkFolder = nil
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
    local packages = shared and (shared:FindFirstChild("Packages") or shared:WaitForChild("Packages", 3))
    networkFolder = packages and (packages:FindFirstChild("Network") or packages:WaitForChild("Network", 3))
end)

local ref_B_SellAll = networkFolder and networkFolder:FindFirstChild("ref_B_SellAll")
local rev_MeteorShop_RequestSync = networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_RequestSync")
local rev_MeteorShop_Stock = networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Stock")
local rev_MeteorShop_Buy = networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy")

if not rev_MeteorShop_Stock or not rev_MeteorShop_Buy or not rev_MeteorShop_RequestSync or not ref_B_SellAll then
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") then
            if r.Name == "rev_MeteorShop_Stock" then rev_MeteorShop_Stock = r
            elseif r.Name == "rev_MeteorShop_Buy" then rev_MeteorShop_Buy = r
            elseif r.Name == "rev_MeteorShop_RequestSync" then rev_MeteorShop_RequestSync = r
            end
        elseif r:IsA("RemoteFunction") then
            if r.Name == "ref_B_SellAll" then ref_B_SellAll = r
            end
        end
    end
end

-- =============================================
-- 📢 DISCORD WEBHOOK NOTIFIER (PATAGOTITAN & FRIGOREX - COMPACT & CLEAN)
-- =============================================
local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1539697793973756084/1oLTQDKSmutWJlPX91He00IEEAg_lsos8MWbxuXki8LKqO8WnZUX8kwurULVjdB8lOqb"

local function getDirectRobloxImageUrl(assetId, productId)
    local fallback = string.format("https://www.roblox.com/asset-thumbnail/image?assetId=%s&width=420&height=420&format=png", tostring(assetId))
    local ok, res = pcall(function()
        local httpReq = request or http_request or (delta and delta.request) or (syn and syn.request) or (Fluxus and Fluxus.request) or (http and http.request)
        if not httpReq then return nil end
        local HttpService = game:GetService("HttpService")

        -- 1. Coba Developer Product Icon API jika ada productId
        if productId then
            local pRes = httpReq({
                Url = string.format("https://thumbnails.roblox.com/v1/developer-products/icons?developerProductIds=%s&size=420x420&format=Png", tostring(productId)),
                Method = "GET"
            })
            if pRes and pRes.Body then
                local data = HttpService:JSONDecode(pRes.Body)
                if data and data.data and data.data[1] and data.data[1].imageUrl and data.data[1].imageUrl ~= "" then
                    return data.data[1].imageUrl
                end
            end
        end

        -- 2. Coba Asset Thumbnail API
        if assetId then
            local aRes = httpReq({
                Url = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=420x420&format=Png", tostring(assetId)),
                Method = "GET"
            })
            if aRes and aRes.Body then
                local data = HttpService:JSONDecode(aRes.Body)
                if data and data.data and data.data[1] and data.data[1].imageUrl and data.data[1].imageUrl ~= "" then
                    return data.data[1].imageUrl
                end
            end
        end
    end)
    if ok and res and type(res) == "string" and string.find(res, "http") then
        return res
    end
    return fallback
end

local function getDirectRobloxAvatarUrl(userId)
    local fallback = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=150&height=150&format=png", tostring(userId))
    local ok, res = pcall(function()
        local httpReq = request or http_request or (delta and delta.request) or (syn and syn.request) or (Fluxus and Fluxus.request) or (http and http.request)
        if httpReq then
            local apiRes = httpReq({
                Url = string.format("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=150x150&format=Png", tostring(userId)),
                Method = "GET"
            })
            if apiRes and apiRes.Body then
                local HttpService = game:GetService("HttpService")
                local data = HttpService:JSONDecode(apiRes.Body)
                if data and data.data and data.data[1] and data.data[1].imageUrl then
                    return data.data[1].imageUrl
                end
            end
        end
    end)
    if ok and res and type(res) == "string" and string.find(res, "http") then
        return res
    end
    return fallback
end

local function sendDiscordWebhook(itemName, currentCount, maxStock)
    task.spawn(function()
        pcall(function()
            local httpReq = request or http_request or (delta and delta.request) or (syn and syn.request) or (Fluxus and Fluxus.request) or (http and http.request)
            if not httpReq then return end
            local HttpService = game:GetService("HttpService")

            local wibTimeStr = os.date("!%d/%m/%Y - %H:%M:%S WIB", os.time() + (7 * 3600))
            local userName = lp and lp.Name or "Unknown"
            local userDisplayName = lp and lp.DisplayName or userName
            local userId = lp and tostring(lp.UserId) or "0"

            local playerAvatarCdn = getDirectRobloxAvatarUrl(userId)
            local itemImageUrl = ""
            local embedColor = 0x3498db
            local itemIcon = "🛒"
            local itemCost = 0
            local itemBuff = ""

            if itemName == "Patagotitan" then
                itemIcon = "🦖"
                embedColor = 0x2ecc71 -- Hijau Emerald
                itemImageUrl = getDirectRobloxImageUrl("95399484334874", "3708138558")
                itemCost = 500
                itemBuff = "+150% CP/s (Brainrot)"
            elseif itemName == "Frigorex" then
                itemIcon = "👑"
                embedColor = 0x9b59b6 -- Ungu Royal
                itemImageUrl = getDirectRobloxImageUrl("140510107418430", "3708174931")
                itemCost = 1250
                itemBuff = "+250% CP/s (Brainrot)"
            end

            local payload = {
                ["username"] = "KALB Meteor Shop",
                ["avatar_url"] = playerAvatarCdn,
                ["embeds"] = {
                    {
                        ["title"] = string.format("%s %s", itemIcon, itemName),
                        ["color"] = embedColor,
                        ["thumbnail"] = {
                            ["url"] = itemImageUrl
                        },
                        ["author"] = {
                            ["name"] = userDisplayName,
                            ["icon_url"] = playerAvatarCdn
                        },
                        ["fields"] = {
                            {
                                ["name"] = "Rarity / Buff",
                                ["value"] = string.format("`%s`", itemBuff),
                                ["inline"] = false
                            },
                            {
                                ["name"] = "Stock Dibeli",
                                ["value"] = string.format("`#%d / %d` (%d Tokens)", currentCount, maxStock, itemCost),
                                ["inline"] = true
                            },
                            {
                                ["name"] = "Akun Pembeli",
                                ["value"] = string.format("%s (`%s`)", userName, userId),
                                ["inline"] = true
                            }
                        },
                        ["footer"] = {
                            ["text"] = string.format("KALB - Meteor Shop | %s", wibTimeStr)
                        },
                        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }
                }
            }

            httpReq({
                Url = DISCORD_WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

-- Eksekusi Test Webhook jika diaktifkan di konfigurasi atas (_G.testWebhook = true)
if _G.testWebhook then
    task.spawn(function()
        task.wait(1.5)
        print("📢 [TEST WEBHOOK] Mengirim pesan simulasi pembelian Patagotitan & Frigorex ke Discord...")
        sendDiscordWebhook("Patagotitan", 1, 3)
        task.wait(1.5)
        sendDiscordWebhook("Frigorex", 1, 1)
        print("✅ [TEST WEBHOOK] Pesan test berhasil dikirim! Silakan periksa channel Discord Anda.")
    end)
end

-- =============================================
-- 🛒 8. AUTO BUY METEOR SHOP (PATAGOTITAN, SPEED, FRIGOREX)
-- =============================================
if rev_MeteorShop_Stock then
    rev_MeteorShop_Stock.OnClientEvent:Connect(function(stockData, expiryTimestamp)
        if type(stockData) ~= "table" then return end
        
        local buyRemote = rev_MeteorShop_Buy or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy"))
        if not buyRemote then return end

        for itemName, itemInfo in pairs(stockData) do
            if type(itemInfo) == "table" then
                local stockCount = tonumber(itemInfo.Stock) or 0
                
                if stockCount > 0 then
                    local shouldBuy = false

                    if itemName == "Patagotitan" and _G.autoBuyPatagotitan then
                        shouldBuy = true
                    elseif itemName == "Speed" and _G.autoBuySpeed then
                        shouldBuy = true
                    elseif itemName == "Frigorex" and _G.autoBuyFrigorex then
                        shouldBuy = true
                    end

                    if shouldBuy then
                        task.spawn(function()
                            for i = 1, stockCount do
                                pcall(function()
                                    buyRemote:FireServer(itemName)
                                    print(string.format("🛒 [METEOR AUTO BUY] Berhasil membeli %s (#%d/%d)!", itemName, i, stockCount))
                                    if itemName == "Patagotitan" or itemName == "Frigorex" then
                                        sendDiscordWebhook(itemName, i, stockCount)
                                    end
                                end)
                                task.wait(0.2)
                            end
                        end)
                    end
                end
            end
        end
    end)
end

-- Loop Request Sync Stock setiap 60 Detik
task.spawn(function()
    task.wait(3)
    while true do
        if _G.autoFarm and (_G.autoBuyPatagotitan or _G.autoBuySpeed or _G.autoBuyFrigorex) then
            pcall(function()
                local syncRemote = rev_MeteorShop_RequestSync or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_RequestSync"))
                if syncRemote then
                    syncRemote:FireServer()
                end
            end)
        end
        task.wait(60)
    end
end)

-- =============================================
-- 🧪 9. AUTO BUY FARM POTION (KHUSUS JAM GANJIL WIB: 1, 3, 5... 23 & MAX MENIT :10)
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

                -- Hanya beli jika jam ganjil (1, 3, 5... 23) DAN menit masih <= 10
                if (hourWIB % 2 == 1) and (minWIB <= 10) and (lastBoughtFarmPotionHour ~= hourWIB) then
                    lastBoughtFarmPotionHour = hourWIB
                    
                    local buyRemote = rev_MeteorShop_Buy or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy"))
                    if buyRemote then
                        buyRemote:FireServer("Farm Potion")
                        print(string.format("🧪 [AUTO BUY WIB] Berhasil membeli 1x Farm Potion pada jam %02d:%02d:%02d WIB (Di bawah menit :10)!", hourWIB, minWIB, secWIB))
                    end
                end
            end)
        end
        task.wait(5)
    end
end)

-- =============================================
-- 💰 10. AUTO SELL ALL (SETIAP 5 DETIK)
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

print("🥔 [KALB] Auto Farm (Anti-Lag, Total Purge, Auto Sell, Patago, Speed, Frigorex & Farm Potion WIB) Siap!")
