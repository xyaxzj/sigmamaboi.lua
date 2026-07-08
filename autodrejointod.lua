if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local lp = Players.LocalPlayer

-- =============================================
-- ⚙️ KONFIGURASI (UBAH DI SINI SEBELUM EXECUTE)
-- =============================================
_G.autoFarm = true              -- Ubah ke false kalu mau mematikan auto farm
_G.hideOtherPlayers = true      -- Ubah ke false kalau mau melihat player lain
_G.animDelay = 7.3              -- Jeda nunggu animasi gacha (Detik)

-- Variabel Sistem (Jangan diubah)
_G.targetAction = "Idle"
_G.timeoutCounter = 0 
local safeZone = Vector3.new(689, 3, 236)

-- Fungsi Notifikasi Bawaan Roblox
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

notify("Engine V2.7 Aktif!", "Script berjalan di latar belakang tanpa UI.")

-- =============================================
-- ⚡ EKSEKUSI FPS BOOST OTOMATIS
-- =============================================
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
-- 👁️ SENSOR 3D MURNI
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
                            task.wait(_G.animDelay)
                            _G.targetAction = "Die"
                        end)
                    else
                        task.spawn(function()
                            task.wait(_G.animDelay)
                            _G.targetAction = "Walk"
                        end)
                    end
                end
            end)
        end
    end
end)

-- =============================================
-- 👻 MESIN GHOST MODE (PEMUTIH PEMAIN)
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
                
                -- TARGET 2: Kloning / Wujud Luckyblock Pemain Lain
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
-- ⚙️ MAIN LOOP (STATE MACHINE)
-- =============================================
task.spawn(function()
    while task.wait(0.2) do
        if not _G.autoFarm then continue end

        pcall(function()
            local char = lp.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not hum or not hrp then return end

            -- JIKA MATI -> KEMBALI KE IDLE
            if hum.Health <= 0 then
                _G.targetAction = "Idle"
                _G.timeoutCounter = 0
                task.wait(2) 
                return
            end

            local dist = (hrp.Position - safeZone).Magnitude

            -- [ PERSIAPAN NENDANG ]
            if _G.targetAction == "Idle" then
                if dist > 10 then
                    hrp.CFrame = CFrame.new(safeZone)
                    task.wait(0.3)
                else
                    if kickRemote then kickRemote:FireServer(1, 1) end
                    _G.targetAction = "WaitingForDrop"
                    _G.timeoutCounter = 0
                end

            -- [ NUNGGU SENSOR BACA DATA ]
            elseif _G.targetAction == "WaitingForDrop" then
                _G.timeoutCounter = _G.timeoutCounter + 0.2
                if _G.timeoutCounter > 15 then
                    _G.targetAction = "Idle"
                    _G.timeoutCounter = 0
                end
                hum:MoveTo(hrp.Position)

            -- [ NUNGGU ANIMASI KELAR (DIAM) ]
            elseif _G.targetAction == "PlayingAnim" then
                hum:MoveTo(hrp.Position)

            -- [ AMBIL MUTASI ]
            elseif _G.targetAction == "Walk" then
                hum:MoveTo(safeZone)
                if dist < 8 then
                    _G.targetAction = "Idle" 
                end

            -- [ BUNUH DIRI (AMPAS) ]
            elseif _G.targetAction == "Die" then
                hum.Health = 0
            end
        end)
    end
end)
