-- ==============================================================================
-- 🥔 KALB ULTRA LIGHTWEIGHT AUTO FARM & ANTI-LAG (ZERO MEMORY LEAK)
-- ==============================================================================
-- Fitur & Evaluasi:
-- 1. 🥔 Potato Mode Ekstrem: Hapus semua texture, PBR, bayangan, partikel, & efek Lighting
-- 2. 🚫 Total Player & Character Purger: Hapus karakter & instance player lain dari game.Players & workspace.Players
-- 3. 🛡️ Anti-AFK (VirtualUser) & Auto Garbage Collector (RAM tetap enteng berjam-jam)
-- 4. 💰 Auto Sell All (Setiap 5 detik via ref_B_SellAll)
-- 5. ☄️ Auto Meteor Event: Otomatis perbesar hitbox meteor di Debris (Bisa diatur di config)
-- 6. 🛒 Meteor Shop Auto Buy:
--    - 🦖 Patagotitan (⚡ON)
--    - ⚡ Speed (+1) (⚡ON)
--    - 👑 Frigorex (⚡ON)
--    - 🦏 Tricerabob (⚡ON)
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
_G.autoMeteor = true             -- ☄️ true: Otomatis perbesar hitbox meteor saat Meteor Shower, false: Nonaktif
_G.meteorHitboxSize = 200        -- 📏 Ukuran hitbox meteor dalam studs (Default: 200)
_G.autoBuyPatagotitan = true     -- 🦖 Patagotitan
_G.autoBuySpeed = true           -- ⚡ Speed (+1)
_G.autoBuyFrigorex = true        -- 👑 Frigorex
_G.autoBuyTricerabob = true      -- 🦏 Tricerabob
_G.autoBuyFarmPotion = true      -- 🧪 Farm Potion (I) (Khusus jam ganjil WIB max menit :10)
_G.autoSellAll = false            -- 💰 Auto Sell All tiap 5s
_G.autoRemovePlayer = false       -- 🚫 Hapus player lain dari game.Players & workspace.Players

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
-- 🥔 2. SYSTEM HAPUS TEKSTUR & VISUAL (SAFE ZERO-ERROR & ZERO-LAG)
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
    Clothing = true,
    ShirtGraphic = true,
    SelectionBox = true,
    SelectionSphere = true,
}

local function stripTexture(v)
    if not v then return end
    if lp and lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character)) then return end

    pcall(function()
        local className = v.ClassName
        if PURGE_CLASSES[className] then
            v:Destroy()
            return
        end

        if className == "Highlight" or v:IsA("Highlight") then
            v.Enabled = false
            v.FillTransparency = 1
            v.OutlineTransparency = 1
            return
        end

        if className == "Decal" or className == "Texture" or v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
            return
        end

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
    while task.wait(3) do
        if _G.autoRemovePlayer then
            pcall(scanAndPurgeAllOtherPlayers)
        end

        pcall(function()
            if collectgarbage then
                collectgarbage("step", 50)
            elseif gcinfo then
                gcinfo()
            end
        end)
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
-- 📢 DISCORD WEBHOOK NOTIFIER (PATAGOTITAN, FRIGOREX, TRICERABOB - ZERO LAG)
-- =============================================
local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1539697793973756084/1oLTQDKSmutWJlPX91He00IEEAg_lsos8MWbxuXki8LKqO8WnZUX8kwurULVjdB8lOqb"

local PATAGO_IMAGE_URL = "https://www.roblox.com/asset-thumbnail/image?assetId=95399484334874&width=420&height=420&format=png"
local FRIGOREX_IMAGE_URL = "https://www.roblox.com/asset-thumbnail/image?assetId=140510107418430&width=420&height=420&format=png"

local function sendDiscordWebhook(itemName, totalBought)
    totalBought = totalBought or 1
    task.defer(function()
        task.spawn(function()
            pcall(function()
                local httpReq = request or http_request or (delta and delta.request) or (syn and syn.request) or (Fluxus and Fluxus.request) or (http and http.request)
                if not httpReq then return end
                local HttpService = game:GetService("HttpService")

                local userDisplayName = lp and lp.DisplayName or (lp and lp.Name or "Unknown")
                local userId = lp and tostring(lp.UserId) or "0"
                local playerAvatarCdn = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=150&height=150&format=png", userId)

                local itemImageUrl = ""
                local embedColor = 0x3498db
                local itemIcon = "🛒"
                local unitCost = 0
                local itemBuff = ""

                if itemName == "Patagotitan" then
                    itemIcon = "🦖"
                    embedColor = 0x2ecc71 -- Hijau Emerald
                    itemImageUrl = PATAGO_IMAGE_URL
                    unitCost = 500
                    itemBuff = "150% CP/s"
                elseif itemName == "Frigorex" then
                    itemIcon = "👑"
                    embedColor = 0x9b59b6 -- Ungu Royal
                    itemImageUrl = FRIGOREX_IMAGE_URL
                    unitCost = 1250
                    itemBuff = "250% CP/s"
                elseif itemName == "Tricerabob" then
                    itemIcon = "🦏"
                    embedColor = 0xe67e22 -- Oranye Golden
                    itemImageUrl = playerAvatarCdn
                    unitCost = 750
                    itemBuff = "Exclusive Meteor Brainrot"
                end

                local totalCost = unitCost * totalBought
                local titleDesc = (totalBought > 1) and string.format("%s %dx %s", itemIcon, totalBought, itemName) or string.format("%s %s", itemIcon, itemName)

                local payload = {
                    ["username"] = "KALB Meteor Shop",
                    ["avatar_url"] = playerAvatarCdn,
                    ["embeds"] = {
                        {
                            ["author"] = {
                                ["name"] = userDisplayName,
                                ["icon_url"] = playerAvatarCdn
                            },
                            ["title"] = "Berhasil Membeli",
                            ["description"] = titleDesc,
                            ["color"] = embedColor,
                            ["thumbnail"] = {
                                ["url"] = itemImageUrl
                            },
                            ["fields"] = {
                                {
                                    ["name"] = "Exclusive",
                                    ["value"] = itemBuff,
                                    ["inline"] = false
                                },
                                {
                                    ["name"] = "Jumlah",
                                    ["value"] = string.format("%d Unit", totalBought),
                                    ["inline"] = true
                                },
                                {
                                    ["name"] = "Total Harga",
                                    ["value"] = string.format("%d Tokens", totalCost),
                                    ["inline"] = true
                                }
                            },
                            ["footer"] = {
                                ["text"] = "KALB - Meteor Shop"
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
    end)
end

-- =============================================
-- 🛒 8. AUTO BUY METEOR SHOP (PATAGOTITAN, SPEED, FRIGOREX, TRICERABOB)
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
                    elseif itemName == "Tricerabob" and _G.autoBuyTricerabob then
                        shouldBuy = true
                    end

                    if shouldBuy then
                        task.spawn(function()
                            local boughtCount = 0
                            for i = 1, stockCount do
                                pcall(function()
                                    buyRemote:FireServer(itemName)
                                    boughtCount = boughtCount + 1
                                    print(string.format("🛒 [METEOR AUTO BUY] Berhasil membeli %s (#%d/%d)!", itemName, i, stockCount))
                                end)
                                task.wait(0.15)
                            end
                            if boughtCount > 0 and (itemName == "Patagotitan" or itemName == "Frigorex" or itemName == "Tricerabob") then
                                sendDiscordWebhook(itemName, boughtCount)
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
        if _G.autoFarm and (_G.autoBuyPatagotitan or _G.autoBuySpeed or _G.autoBuyFrigorex or _G.autoBuyTricerabob) then
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

-- =============================================
-- ☄️ 11. AUTO METEOR EVENT ENGINE (HITBOX EXPANDER & PARTICLE PURGER)
-- =============================================
local activeMeteors = {}

local function getMeteorSize()
    local s = tonumber(_G.meteorHitboxSize) or 200
    return Vector3.new(s, s, s)
end

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
        local targetSize = getMeteorSize()
        if part.Size ~= targetSize then
            part.Size = targetSize
        end
    end)
end

local function handleNewMeteor(model)
    if not _G.autoMeteor then return end
    if not model or not isTargetMeteorModel(model) then return end
    if activeMeteors[model] then return end
    activeMeteors[model] = true

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant.ClassName == "Part" then
            expandMeteorHitbox(descendant)
        elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Fire") or descendant:IsA("Smoke") or 
               descendant:IsA("Trail") or descendant:IsA("PointLight") or descendant:IsA("SpotLight") then
            descendant:Destroy()
        end
    end
end

local function setupMeteorListeners(debris)
    if not debris then return end

    for _, item in ipairs(debris:GetChildren()) do
        if isTargetMeteorModel(item) then
            handleNewMeteor(item)
        end
    end

    debris.ChildAdded:Connect(function(child)
        task.defer(function()
            if isTargetMeteorModel(child) then
                handleNewMeteor(child)
            end
        end)
    end)

    debris.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            if not _G.autoMeteor then return end
            if descendant:IsA("BasePart") or descendant.ClassName == "Part" then
                local targetModel = getTargetMeteorParent(descendant)
                if targetModel then
                    expandMeteorHitbox(descendant)
                    handleNewMeteor(targetModel)
                end
            elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Fire") or descendant:IsA("Smoke") or 
                   descendant:IsA("Trail") or descendant:IsA("PointLight") or descendant:IsA("SpotLight") then
                descendant:Destroy()
            end
        end)
    end)

    debris.ChildRemoved:Connect(function(child)
        activeMeteors[child] = nil
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

print("🥔 [KALB] Auto Farm (Hitbox Meteor 200s, Anti-Lag, Total Purge, Auto Sell, Auto Buy) Siap!")
