if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer

-- =============================================
-- KONFIGURASI DEFAULT ON
-- =============================================
_G.autoFarm = true              -- Langsung ON
_G.hideOtherPlayers = true      -- Ghost Mode langsung ON
_G.animDelay = 7.3              -- Jeda default 7.3 detik
_G.statusTxt = "Menyiapkan Auto Farm..."
_G.targetAction = "Idle"
_G.timeoutCounter = 0 

local safeZone = Vector3.new(689, 3, 236)

-- =============================================
-- EKSEKUSI FPS BOOST OTOMATIS SAAT LOAD
-- =============================================
local function applyFPSBoost()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end

        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled = false
            elseif v:IsA("PostEffect") then 
                v.Enabled = false
            end
        end
    end)
end
applyFPSBoost() -- Langsung eksekusi di awal!

-- =============================================
-- 🛡️ BUILT-IN ANTI AFK
-- =============================================
lp.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

task.spawn(function()
    while task.wait(300) do 
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- =============================================
-- CARI KICK REMOTE
-- =============================================
local kickRemote = nil
for _, r in pairs(ReplicatedStorage:GetDescendants()) do
    if r:IsA("RemoteEvent") and string.find(r.Name, "rev_KickEvent") and not string.find(r.Name, "Ended") then
        kickRemote = r
        break
    end
end

-- =============================================
-- SENSOR 3D MURNI
-- =============================================
workspace.DescendantAdded:Connect(function(obj)
    if not _G.autoFarm or _G.targetAction ~= "WaitingForDrop" then return end
    
    if obj:IsA("Model") then
        task.wait(0.05) 
        
        local mutation = obj:GetAttribute("Mutation")
        
        if mutation ~= nil then 
            pcall(function()
                local dist = (obj:GetPivot().Position - safeZone).Magnitude
                if dist < 60 then
                    
                    _G.targetAction = "PlayingAnim"
                    _G.timeoutCounter = 0 
                    
                    if mutation == "None" or mutation == "" then
                        task.spawn(function()
                            _G.statusTxt = "⏳ Ampas Dideteksi! Nunggu ".._G.animDelay.."s..."
                            task.wait(_G.animDelay)
                            _G.statusTxt = "❌ Animasi Kelar, Reset Karakter!"
                            _G.targetAction = "Die"
                        end)
                    else
                        task.spawn(function()
                            _G.statusTxt = "⏳ MUTASI DIDETEKSI! Nunggu ".._G.animDelay.."s..."
                            task.wait(_G.animDelay)
                            _G.statusTxt = "🏃 Ambil Mutasi: " .. obj.Name
                            _G.targetAction = "Walk"
                        end)
                    end
                end
            end)
        end
    end
end)

-- =============================================
-- MESIN GHOST MODE (BACKGROUND LOOP)
-- =============================================
task.spawn(function()
    while task.wait(0.5) do 
        if _G.hideOtherPlayers then
            pcall(function()
                -- TARGET 1: Pemain Asli
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= lp and player.Character then
                        for _, v in pairs(player.Character:GetDescendants()) do
                            if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
                                v.Transparency = 1
                                v.CanCollide = false
                            elseif v:IsA("Accessory") or v:IsA("Tool") or v:IsA("ParticleEmitter") or v:IsA("Trail") then
                                v:Destroy() 
                            end
                        end
                        if player.Character:FindFirstChild("Humanoid") then
                            player.Character.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        end
                    end
                end
                
                -- TARGET 2: Kloning / Wujud Luckyblock
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Model") and obj ~= lp.Character and obj:FindFirstChild("Humanoid") then
                        for _, v in pairs(obj:GetDescendants()) do
                            if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
                                v.Transparency = 1
                                v.CanCollide = false
                            elseif v:IsA("Accessory") or v:IsA("ParticleEmitter") then
                                v:Destroy()
                            end
                        end
                        if obj:FindFirstChild("Humanoid") then
                            obj.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        end
                    end
                end
            end)
        end
    end
end)

-- =============================================
-- MAIN LOOP (STATE MACHINE)
-- =============================================
task.spawn(function()
    while task.wait(0.2) do
        if not _G.autoFarm then continue end

        pcall(function()
            local char = lp.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not hum or not hrp then return end

            if hum.Health <= 0 then
                _G.statusTxt = "💀 Menunggu Respawn..."
                _G.targetAction = "Idle"
                _G.timeoutCounter = 0
                task.wait(2) 
                return
            end

            local dist = (hrp.Position - safeZone).Magnitude

            if _G.targetAction == "Idle" then
                if dist > 10 then
                    hrp.CFrame = CFrame.new(safeZone)
                    task.wait(0.3)
                else
                    _G.statusTxt = "⚡ Menendang!"
                    if kickRemote then kickRemote:FireServer(1, 1) end
                    _G.targetAction = "WaitingForDrop"
                    _G.timeoutCounter = 0
                end

            elseif _G.targetAction == "WaitingForDrop" then
                _G.statusTxt = "⏳ Menunggu Data 3D..."
                _G.timeoutCounter = _G.timeoutCounter + 0.2
                if _G.timeoutCounter > 15 then
                    _G.statusTxt = "⚠️ Data ngelag. Reset..."
                    _G.targetAction = "Idle"
                    _G.timeoutCounter = 0
                end
                hum:MoveTo(hrp.Position)

            elseif _G.targetAction == "PlayingAnim" then
                hum:MoveTo(hrp.Position)

            elseif _G.targetAction == "Walk" then
                hum:MoveTo(safeZone)
                if dist < 8 then
                    _G.targetAction = "Idle" 
                end

            elseif _G.targetAction == "Die" then
                hum.Health = 0
            end
        end)
    end
end)

-- =============================================
-- UI RAYFIELD
-- =============================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local win = Rayfield:CreateWindow({
    Name = "Mutation Farmer",
    LoadingTitle = "Engine V2.6 (Auto Start)",
    LoadingSubtitle = "Semua Fitur Otomatis Aktif",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
    Theme = "DarkBlue"
})

-- TAB 1: AUTO FARM
local tabFarm = win:CreateTab("🎯 Auto Farm", 4483362748)
local statusLabel = tabFarm:CreateLabel("Status: " .. _G.statusTxt)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            statusLabel:Set("Status: " .. tostring(_G.statusTxt))
        end)
    end
end)

tabFarm:CreateToggle({
    Name = "🔥 Mulai Auto Farm",
    CurrentValue = true, -- Default ON
    Callback = function(val)
        _G.autoFarm = val
    end
})

tabFarm:CreateSlider({
    Name = "Jeda Menunggu Animasi (Detik)",
    Range = {1, 15},
    Increment = 0.1,
    CurrentValue = 7.3, -- Default diatur 7.3 Detik
    Callback = function(val)
        _G.animDelay = val
    end
})

-- TAB 2: BOOST FPS
local tabFPS = win:CreateTab("⚡ Boost FPS", 4483362748)

tabFPS:CreateButton({
    Name = "🚀 Re-Apply Low Graphics",
    Callback = function()
        applyFPSBoost()
        Rayfield:Notify({Title = "Diaplikasikan Ulang", Content = "Grafik kentang diterapkan ulang.", Duration = 3})
    end
})

tabFPS:CreateSection("Ghost Mode Wiper")

tabFPS:CreateToggle({
    Name = "👻 Sembunyikan Semua Pemain (Ghost Mode)",
    CurrentValue = true, -- Default ON
    Callback = function(state)
        _G.hideOtherPlayers = state
    end
})

Rayfield:Notify({
    Title = "Auto Start Aktif!",
    Content = "Semua fitur, FPS Boost, dan Ghost Mode langsung berjalan! (Jeda 7.3s)",
    Duration = 5
})
