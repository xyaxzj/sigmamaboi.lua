-- ==============================================================================
-- 🥔 KALB ANTI-LAG, AUTO PURGE & AUTO SELL ALL
-- ==============================================================================
-- Fitur:
-- 1. 🥔 Anti-Lag Ekstrem & Potato Map (Plastic, White, No Shadows, Plot & Player Removed)
-- 2. 🛡️ Anti-AFK (Mencegah disconnect 20 menit)
-- 3. 💰 Auto Sell All (Setiap 5 detik via remote ref_B_SellAll)
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local lp = Players.LocalPlayer

-- =============================================
-- ⚙️ KONFIGURASI 
-- =============================================
_G.autoFarm = true

-- =============================================
-- 🚀 SYSTEM ANTI-LAG & OPTIMISASI (BAC SAFE)
-- =============================================
-- 1. Ubah Map Jadi Potato (Putih & SmoothPlastic)
for _, v in ipairs(workspace:GetDescendants()) do
    if not (lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character))) then
        pcall(function()
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
                v.Color = Color3.new(1, 1, 1)
                if v:IsA("MeshPart") then v.TextureID = "" end
            elseif v:IsA("SpecialMesh") then
                v.TextureId = ""
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end)
    end
end

-- =============================================
-- 🎯 DETEKTOR PLOT SENDIRI & REMOVER PLOT LAIN
-- =============================================
local lpName = lp.Name
local lpDisplayName = lp.DisplayName
local myUidStr = tostring(lp.UserId)

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

-- 3. Hapus Total Player Lain & Data-Datanya (Character, Leaderstats, Instance)
local function purgePlayerTotal(player)
    if player and player ~= lp then
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
end

for _, player in ipairs(Players:GetPlayers()) do purgePlayerTotal(player) end
Players.PlayerAdded:Connect(function(player)
    if player ~= lp then
        task.defer(function()
            purgePlayerTotal(player)
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
-- 🛡️ ANTI AFK (KLASIK VIRTUALUSER)
-- =============================================
lp.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- =============================================
-- 📡 CARI REMOTE NETWORK UNTUK AUTO SELL
-- =============================================
local networkFolder = ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
local ref_B_SellAll = networkFolder and (networkFolder:FindFirstChild("ref_B_SellAll") or networkFolder:WaitForChild("ref_B_SellAll", 5))

-- =============================================
-- 💰 AUTO SELL ALL (SETIAP 5 DETIK)
-- =============================================
task.spawn(function()
    while task.wait(5) do
        if not _G.autoFarm then continue end
        pcall(function()
            if ref_B_SellAll then
                ref_B_SellAll:InvokeServer()
            else
                local net = ReplicatedStorage:FindFirstChild("Shared")
                net = net and net:FindFirstChild("Packages")
                net = net and net:FindFirstChild("Network")
                local sellRemote = net and net:FindFirstChild("ref_B_SellAll")
                if sellRemote then
                    sellRemote:InvokeServer()
                end
            end
        end)
    end
end)
