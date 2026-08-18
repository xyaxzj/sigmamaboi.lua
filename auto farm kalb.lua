-- ==============================================================================
-- 🥔 KALB ULTRA LIGHTWEIGHT AUTO FARM & ANTI-LAG (ZERO MEMORY LEAK)
-- ==============================================================================
-- Fitur & Evaluasi:
-- 1. 🥔 Potato Mode Ekstrem: Hapus semua texture, PBR, bayangan, partikel, & efek Lighting
-- 2. 🚫 Total Player & Data Purger: Hapus karakter, data, & instance player lain dari workspace & game.Players
-- 3. 🛡️ Anti-AFK (VirtualUser) & Auto Garbage Collector (RAM tetap enteng berjam-jam)
-- 4. 💰 Auto Sell All (Setiap 5 detik via ref_B_SellAll)
-- 5. 🛒 Meteor Shop Auto Buy Frigorex (Cek stock setiap 5 menit)
-- 6. 🧪 Meteor Shop Auto Buy Farm Potion (Beli 1x setiap pergantian jam ganjil WIB)
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
_G.autoBuyFrigorex = true
_G.autoBuyFarmPotion = true

local autoBuyItems = {
    ["Frigorex"] = true,
}

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
    if setfpscap then setfpscap(30) end -- Batasi FPS saat AFK agar hemat daya & dingin
    if settings and settings().Rendering then
        settings().Rendering.QualityLevel = 1
    end
end)

-- =============================================
-- 🥔 2. SYSTEM HAPUS TEKSTUR & MATERIAL (CLEAN & NO MEMORY LEAK)
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

-- Bersihkan objek yang ada di workspace saat awal
for _, v in ipairs(workspace:GetDescendants()) do
    stripTexture(v)
end

-- =============================================
-- 🚫 3. TOTAL PURGER (HAPUS OTHER PLAYER & DATA DI WORKSPACE + PLAYERS)
-- =============================================
local function purgePlayerCompletely(player)
    if not player or player == lp then return end

    -- 1. Hapus Karakter di Workspace
    pcall(function()
        if player.Character then
            player.Character:ClearAllChildren()
            player.Character:Destroy()
        end
    end)

    -- 2. Hapus Data & Instance Player dari game.Players
    pcall(function()
        player:ClearAllChildren()
        player:Destroy()
    end)
end

local function scanAndPurgeAllOtherPlayers()
    -- Hapus dari game.Players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            purgePlayerCompletely(player)
        end
    end

    -- Hapus sisa model karakter yang tercecer di Workspace
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child ~= (lp and lp.Character) and child.Name ~= lpName and (lpDisplayName == "" or child.Name ~= lpDisplayName) then
            if child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    child:ClearAllChildren()
                    child:Destroy()
                end)
            end
        end
    end
end

-- Eksekusi awal pembersihan player
scanAndPurgeAllOtherPlayers()

-- Event saat pemain baru join
Players.PlayerAdded:Connect(function(player)
    if player ~= lp then
        task.defer(function()
            task.wait(0.05)
            purgePlayerCompletely(player)
        end)
        player.CharacterAdded:Connect(function(char)
            task.defer(function()
                pcall(function()
                    char:ClearAllChildren()
                    char:Destroy()
                end)
            end)
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

-- Bersihkan Plot Orang Lain
local plotsFolder = workspace:FindFirstChild("Plots")
if plotsFolder then
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

-- =============================================
-- 🧹 5. PERIODIC SWEEPER & GARBAGE COLLECTOR (ANTI-LAG AFK LAMA)
-- =============================================
-- Sweeper berjalan setiap 1 detik (tidak membebani CPU, RAM selalu bersih)
task.spawn(function()
    local cleanCounter = 0
    while task.wait(1) do
        if not _G.autoFarm then continue end
        
        -- Hapus pemain lain & karakter liar
        pcall(scanAndPurgeAllOtherPlayers)

        cleanCounter = cleanCounter + 1
        -- Setiap 30 detik: Bersihkan RAM & jalankan Garbage Collector
        if cleanCounter >= 30 then
            cleanCounter = 0
            pcall(function()
                if gcinfo then gcinfo() end
                if collectgarbage then collectgarbage("collect") end
            end)
        end
    end
end)

-- Listener hemat CPU untuk part baru yang masuk ke workspace
workspace.ChildAdded:Connect(function(child)
    if not child then return end
    task.defer(function()
        if child:IsA("Model") and child ~= (lp and lp.Character) and child.Name ~= lpName and (lpDisplayName == "" or child.Name ~= lpDisplayName) then
            if child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    child:ClearAllChildren()
                    child:Destroy()
                end)
                return
            end
        end
        stripTexture(child)
    end)
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

-- =============================================
-- 🛒 8. AUTO BUY METEOR SHOP (FRIGOREX VIA STOCK)
-- =============================================
if rev_MeteorShop_Stock then
    rev_MeteorShop_Stock.OnClientEvent:Connect(function(stockData, expiryTimestamp)
        if type(stockData) ~= "table" then return end
        
        print("--------------------------------------------------")
        print("🛒 [METEOR SHOP] Data Stock Diterima dari Server:")
        
        for itemName, itemInfo in pairs(stockData) do
            if type(itemInfo) == "table" then
                local stockCount = tonumber(itemInfo.Stock) or 0
                local maxCount = tonumber(itemInfo.Max) or 0
                
                if autoBuyItems[itemName] then
                    print(string.format("⭐ [TARGET] %s | Stock: %d / %d", tostring(itemName), stockCount, maxCount))
                    
                    if _G.autoBuyFrigorex and stockCount > 0 then
                        for i = 1, stockCount do
                            pcall(function()
                                local buyRemote = rev_MeteorShop_Buy or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_Buy"))
                                if buyRemote then
                                    buyRemote:FireServer(itemName)
                                    print(string.format("🔥 [AUTO BUY] Membeli %s (#%d/%d)...", tostring(itemName), i, stockCount))
                                end
                            end)
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
        print("--------------------------------------------------")
    end)
end

-- Loop Request Stock setiap 5 Menit (300 Detik)
task.spawn(function()
    task.wait(2)
    while true do
        if _G.autoFarm and _G.autoBuyFrigorex then
            pcall(function()
                local syncRemote = rev_MeteorShop_RequestSync or (networkFolder and networkFolder:FindFirstChild("rev_MeteorShop_RequestSync"))
                if syncRemote then
                    syncRemote:FireServer()
                    print("🛒 [METEOR SHOP] Mengirim RequestSync ke server (Loop 5 Menit)...")
                end
            end)
        end
        task.wait(300)
    end
end)

-- =============================================
-- 🧪 9. AUTO BUY FARM POTION (SETIAP JAM GANJIL WIB: 1, 3, 5... 23)
-- =============================================
local lastBoughtFarmPotionHour = -1

task.spawn(function()
    task.wait(1)
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
-- 💰 10. AUTO SELL ALL (SETIAP 5 DETIK)
-- =============================================
task.spawn(function()
    while task.wait(5) do
        if not _G.autoFarm then continue end
        pcall(function()
            local sellRemote = ref_B_SellAll or (networkFolder and networkFolder:FindFirstChild("ref_B_SellAll"))
            if sellRemote then
                sellRemote:InvokeServer()
            end
        end)
    end
end)

print("🥔 [KALB] Auto Farm (Ultra Lightweight, Total Purge, Frigorex & Farm Potion WIB) Siap!")
