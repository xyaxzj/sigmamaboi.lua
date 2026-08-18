-- ==============================================================================
-- 🥔 KALB ANTI-LAG, AUTO PURGE, AUTO SELL & METEOR SHOP AUTO BUY
-- ==============================================================================
-- Fitur:
-- 1. 🥔 Anti-Lag Ekstrem & Potato Map (Plastic, White, No Shadows, Plot & Player Removed)
-- 2. 🛡️ Anti-AFK (Mencegah disconnect 20 menit)
-- 3. 💰 Auto Sell All (Setiap 5 detik via remote ref_B_SellAll)
-- 4. 🛒 Meteor Shop Auto Buy Frigorex (Pantau stock setiap 5 menit via rev_MeteorShop_RequestSync)
-- 5. 🧪 Meteor Shop Auto Buy Farm Potion (Beli 1x setiap pergantian jam ganjil WIB: 1, 3, 5... 23)
-- ==============================================================================

pcall(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- =============================================
-- ⚙️ KONFIGURASI 
-- =============================================
_G.autoFarm = true
_G.autoBuyFrigorex = true
_G.autoBuyFarmPotion = true

local autoBuyItems = {
    ["Frigorex"] = true, -- Otomatis beli Frigorex jika stock > 0
}

-- =============================================
-- 🚀 SYSTEM ANTI-LAG & OPTIMISASI (HAPUS SEMUA TEKSTUR MODEL)
-- =============================================
local function removeTextures(v)
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
        elseif v:IsA("SurfaceAppearance") then
            v:Destroy() -- Hapus tekstur modern PBR/HD
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("Clothing") or v:IsA("ShirtGraphic") then
            v:Destroy() -- Hapus tekstur baju/celana pada model
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false -- Matikan partikel efek visual
        end
    end)
end

-- 1. Bersihkan semua objek & model yang sudah ada di map
for _, v in ipairs(workspace:GetDescendants()) do
    removeTextures(v)
end

-- 2. Bersihkan otomatis jika ada model / part baru yang spawn
workspace.DescendantAdded:Connect(function(v)
    task.defer(removeTextures, v)
end)

-- =============================================
-- 🎯 DETEKTOR PLOT SENDIRI & REMOVER PLOT LAIN
-- =============================================
local lpName = lp and lp.Name or ""
local lpDisplayName = lp and lp.DisplayName or ""
local myUidStr = lp and tostring(lp.UserId) or ""

local function isMyPlot(plotModel)
    if not plotModel or not plotModel:IsA("Model") then return false end

    -- 1. Cek via PlotSign
    local sign = plotModel:FindFirstChild("PlotSign", true)
    if sign then
        local pps = sign:FindFirstChild("PlayerPlotSign", true)
        if pps then
            local nameLabel = pps:FindFirstChild("PlayerName", true)
            if nameLabel and nameLabel:IsA("TextLabel") then
                local t = nameLabel.Text
                if t and (t == lpName or t:find(lpName, 1, true) or (lpDisplayName and (t == lpDisplayName or t:find(lpDisplayName, 1, true)))) then
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

    -- 2. Fallback scan value di descendant
    for _, item in ipairs(plotModel:GetDescendants()) do
        local ok, result = pcall(function()
            if item:IsA("TextLabel") then
                local t = item.Text
                if t and (t == lpName or (lpDisplayName and t == lpDisplayName)) then
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

-- 2. Hapus Plot Player Lain
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
-- 🚫 PENGHAPUS KARAKTER PLAYER LAIN (HEMAT CPU & ANTI-LAG)
-- =============================================
local function purgeOtherCharacter(char)
    if not char or not char:IsA("Model") then return end
    if char == (lp and lp.Character) or char.Name == lpName or (lpDisplayName ~= "" and char.Name == lpDisplayName) then
        return
    end

    pcall(function()
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Transparency = 1
                v.CanCollide = false
            elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("Clothing") then
                v:Destroy()
            end
        end
        char:ClearAllChildren()
        char:Destroy()
    end)
end

local function scanAndPurgeHumanoids()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child ~= (lp and lp.Character) and child.Name ~= lpName and (lpDisplayName == "" or child.Name ~= lpDisplayName) then
            if child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("HumanoidRootPart") or Players:GetPlayerFromCharacter(child) then
                purgeOtherCharacter(child)
            end
        end
    end
end

-- 1. Eksekusi ke karakter pemain lain yang sudah ada saat ini
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= lp then
        if player.Character then
            purgeOtherCharacter(player.Character)
        end
        player.CharacterAdded:Connect(function(char)
            task.defer(function()
                task.wait(0.02)
                purgeOtherCharacter(char)
            end)
        end)
    end
end

-- 2. Pasang listener untuk pemain baru yang bergabung
Players.PlayerAdded:Connect(function(player)
    if player ~= lp then
        player.CharacterAdded:Connect(function(char)
            task.defer(function()
                task.wait(0.02)
                purgeOtherCharacter(char)
            end)
        end)
    end
end)

-- 3. Listener langsung di Workspace saat model/humanoid baru muncul
workspace.ChildAdded:Connect(function(child)
    task.defer(function()
        if child:IsA("Model") and child ~= (lp and lp.Character) and child.Name ~= lpName and (lpDisplayName == "" or child.Name ~= lpDisplayName) then
            if child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("HumanoidRootPart") or Players:GetPlayerFromCharacter(child) then
                purgeOtherCharacter(child)
            end
        end
    end)
end)

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Humanoid") then
        local parentModel = descendant.Parent
        if parentModel and parentModel:IsA("Model") and parentModel ~= (lp and lp.Character) and parentModel.Name ~= lpName then
            task.defer(function()
                purgeOtherCharacter(parentModel)
            end)
        end
    end
end)

-- 4. Background Sweeper Rutin (Memastikan Workspace Bersih dari Player Lain Setiap 0.2s)
task.spawn(function()
    while task.wait(0.2) do
        if not _G.autoFarm then continue end
        pcall(scanAndPurgeHumanoids)
    end
end)

-- =============================================
-- 🛡️ ANTI AFK (KLASIK VIRTUALUSER)
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
-- 📡 CARI REMOTE NETWORK (SAFE DISCOVERY)
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
-- 🛒 AUTO PANTAU STOCK & AUTO BUY FRIGOREX
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
                
                -- Jika item ini ada dalam target Auto Buy (misal: Frigorex)
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
    task.wait(2) -- Jeda awal saat baru load
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
        task.wait(300) -- Jeda 5 menit (300 detik) agar tidak membebani server
    end
end)

-- =============================================
-- 🧪 AUTO BUY FARM POTION (SETIAP JAM GANJIL WIB: 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23)
-- =============================================
local lastBoughtFarmPotionHour = -1

task.spawn(function()
    task.wait(1)
    while true do
        if _G.autoFarm and _G.autoBuyFarmPotion then
            pcall(function()
                -- Hitung waktu Indonesia Barat (WIB = UTC+7)
                local wibTime = os.date("!*t", os.time() + (7 * 3600))
                local hourWIB = wibTime.hour
                local minWIB = wibTime.min
                local secWIB = wibTime.sec

                -- Cek apakah jam ganjil (1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23)
                if (hourWIB % 2 == 1) and (lastBoughtFarmPotionHour ~= hourWIB) then
                    lastBoughtFarmPotionHour = hourWIB
                    
                    local buyRemote = rev_MeteorShop_Buy
                    if not buyRemote then
                        local net = networkFolder or (ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Packages") and ReplicatedStorage.Shared.Packages:FindFirstChild("Network"))
                        buyRemote = net and net:FindFirstChild("rev_MeteorShop_Buy")
                    end

                    if buyRemote then
                        buyRemote:FireServer("Farm Potion")
                        print(string.format("🧪 [AUTO BUY WIB] Berhasil membeli 1x Farm Potion pada jam %02d:%02d:%02d WIB!", hourWIB, minWIB, secWIB))
                    end
                end
            end)
        end
        task.wait(5) -- Cek setiap 5 detik
    end
end)

-- =============================================
-- 💰 AUTO SELL ALL (SETIAP 5 DETIK)
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

print("🥔 [KALB] Auto Farm (Anti-Lag, Auto Sell, Frigorex & Farm Potion WIB Auto-Buy) Siap!")
