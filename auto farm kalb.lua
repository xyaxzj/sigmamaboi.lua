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
-- 🚀 SYSTEM ANTI-LAG & OPTIMISASI (HAPUS SEMUA TEKSTUR MODEL)
-- =============================================
local function removeTextures(v)
    if not v then return end
    if lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character)) then return end

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

-- 3. Hapus Karakter Player Lain Secara Total & Bersih
local function purgeOtherCharacter(char)
    if not char or not char:IsA("Model") then return end
    if char == lp.Character or char.Name == lpName or (lpDisplayName and char.Name == lpDisplayName) then
        return
    end

    pcall(function()
        -- Buat transparan & nonaktifkan collision terlebih dahulu
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

-- Deteksi dan musnahkan model karakter yang memiliki Humanoid di Workspace
local function scanAndPurgeHumanoids()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child ~= lp.Character and child.Name ~= lpName and (not lpDisplayName or child.Name ~= lpDisplayName) then
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
        if child:IsA("Model") and child ~= lp.Character and child.Name ~= lpName and (not lpDisplayName or child.Name ~= lpDisplayName) then
            if child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("HumanoidRootPart") or Players:GetPlayerFromCharacter(child) then
                purgeOtherCharacter(child)
            end
        end
    end)
end)

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Humanoid") then
        local parentModel = descendant.Parent
        if parentModel and parentModel:IsA("Model") and parentModel ~= lp.Character and parentModel.Name ~= lpName then
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
