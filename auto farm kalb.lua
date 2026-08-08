setfpscap(20)
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer

-- =============================================
-- ⚙️ KONFIGURASI 
-- =============================================
_G.autoFarm = true              
_G.animDelay = 5              

-- =============================================
-- 🚀 SYSTEM ANTI-LAG & OPTIMISASI EKSTREM
-- =============================================
-- 1. UBAH MAP JADI POTATO (PUTIH & PLASTIC)
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
            v.Color = Color3.new(1, 1, 1) -- Mengubah warna map jadi putih bersih
            
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("SpecialMesh") then
            v:Destroy()
        end
    end)
end

-- 2. MUSNAHKAN EFEK LIGHTING & LANGIT
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
for _, v in ipairs(Lighting:GetDescendants()) do
    if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Sky") then
        pcall(function() v:Destroy() end)
    end
end

-- 3. HAPUS FOLDER PLOT 1 SAMPAI 5
local plotsFolder = workspace:FindFirstChild("Plots")
if plotsFolder then
    for i = 1, 5 do
        local plot = plotsFolder:FindFirstChild("Plot" .. tostring(i))
        if plot then
            pcall(function() plot:Destroy() end)
        end
    end
end

-- 4. PEMBANTAIAN PLAYER (REMOVE PLAYER LAIN)
local function musnahkanPlayer(player)
    if player ~= lp then
        -- 1. Hapus jika wujud karakternya saat ini sudah ada di map
        if player.Character then
            pcall(function() player.Character:Destroy() end)
        end
        
        -- 2. Hapus objek Player fisik beserta datanya dari game.Players di sisi client
        pcall(function() player:Destroy() end)
    end
end

-- Eksekusi ke player yang sudah ada di server sekarang
for _, player in ipairs(Players:GetPlayers()) do
    musnahkanPlayer(player)
end

-- Eksekusi ke player yang baru join ke server nanti
Players.PlayerAdded:Connect(function(player)
    task.defer(function()
        musnahkanPlayer(player)
    end)
end)

-- Perangkap Ekstrem & Pembersihan Karakter (Mendeteksi Humanoid secara rekursif)
local function periksaDanHapus(descendant)
    if descendant:IsA("Humanoid") then
        local charModel = descendant.Parent
        if charModel and charModel:IsA("Model") and charModel.Name ~= lp.Name then
            pcall(function() charModel:Destroy() end)
        end
    end
end

-- Bersihkan karakter player lain yang sudah terlanjur ada di workspace
for _, descendant in ipairs(workspace:GetDescendants()) do
    if descendant:IsA("Model") and descendant:FindFirstChildOfClass("Humanoid") and descendant.Name ~= lp.Name then
        pcall(function() descendant:Destroy() end)
    end
end

-- Pasang listener real-time untuk mendeteksi humanoid baru yang di-load
workspace.DescendantAdded:Connect(function(descendant)
    task.defer(periksaDanHapus, descendant)
end)

-- =============================================
-- 🧠 VARIABEL OTAK UTAMA (STATE MACHINE)
-- =============================================
_G.targetAction = "Idle"
_G.lastAction = "Idle"
_G.nextAction = "Idle"          
_G.stateTimer = 0               
_G.globalStuckTimer = 0         
_G.mutationCount = 0            
_G.targetItemPos = nil          
local safeZone = Vector3.new(698.030701, 3.298559, 233.707077)
local safeZoneCFrame = CFrame.new(698.030701, 3.298559, 233.707077, -0.061024, -0.000000, 0.998136, -0.000000, 1.000000, 0.000000, -0.998136, -0.000000, -0.061024)

-- =============================================
-- ⬛ HAPUS BLACKSCREEN UI JIKA ADA
-- =============================================
local guiParent = pcall(function() return CoreGui end) and CoreGui or lp:WaitForChild("PlayerGui")
local oldGui = guiParent:FindFirstChild("AFK_Blackscreen")
if oldGui then oldGui:Destroy() end 

-- =============================================
-- 🛡️ ANTI AFK
-- =============================================
lp.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- =============================================
-- 📡 CARI REMOTE
-- =============================================
local kickRemote = nil
local networkFolder = ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
if networkFolder then
    kickRemote = networkFolder:FindFirstChild("rev_KickEvent")
end

if not kickRemote then
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") and string.find(r.Name, "rev_KickEvent") and not string.find(r.Name, "Ended") then
            kickRemote = r; break
        end
    end
end

local rev_kickPhase2 = networkFolder and networkFolder:WaitForChild("rev_kickPhase2", 15)
local rev_Collected = networkFolder and networkFolder:WaitForChild("rev_Collected", 15)
local rev_KickEventEnded = networkFolder and networkFolder:WaitForChild("rev_KickEventEnded", 15)
local rev_AddedWeather = networkFolder and networkFolder:WaitForChild("rev_AddedWeather", 15)
local rev_PlayMessage = networkFolder and networkFolder:WaitForChild("rev_PlayMessage", 15)

-- =============================================
-- 📡 DAFTAR EVENT LISTENER
-- =============================================
local phase2Fired = false
local collectedFired = false
local kickEndedFired = false
local weatherEventPending = false
local luckBuffObtained = false

if rev_kickPhase2 then
    rev_kickPhase2.OnClientEvent:Connect(function(...)
        phase2Fired = true
    end)
end

if rev_Collected then
    rev_Collected.OnClientEvent:Connect(function(...)
        collectedFired = true
    end)
end

if rev_KickEventEnded then
    rev_KickEventEnded.OnClientEvent:Connect(function(...)
        kickEndedFired = true
    end)
end

if rev_AddedWeather then
    rev_AddedWeather.OnClientEvent:Connect(function(weatherType, ...)
        if weatherType == "LuckMachine" then
            weatherEventPending = true
        end
    end)
end

if rev_PlayMessage then
    rev_PlayMessage.OnClientEvent:Connect(function(msg, msgType)
        if tostring(msg) == "Luck has been increased to x8" then
            luckBuffObtained = true
        end
    end)
end

-- =============================================
-- ⚙️ MAIN LOOP (STATE MACHINE - OPTIMIZED)
-- =============================================
task.spawn(function()
    while task.wait(0.05) do
        if not _G.autoFarm then continue end

        local char = lp.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not hum or not hrp then 
            -- Coba wait jika character belum dimuat
            continue 
        end 

        -- [ PENDETEKSI MATI ]
        if hum.Health <= 0 then
            _G.targetAction = "WaitingRespawn"
            _G.lastAction = "WaitingRespawn"
            _G.globalStuckTimer = 0
            continue 
        end

        -- [ PENDETEKSI HIDUP KEMBALI ]
        if _G.targetAction == "WaitingRespawn" and hum.Health > 0 then
            _G.targetAction = "Idle"
            _G.lastAction = "Idle"
        end

        -- ==========================================
        -- 🚨 PENGATUR WAKTU OTOMATIS & FAILSAFE 25s
        -- ==========================================
        if _G.targetAction ~= _G.lastAction then
            _G.globalStuckTimer = 0
            _G.stateTimer = 0 
            _G.lastAction = _G.targetAction
        else
            _G.globalStuckTimer = _G.globalStuckTimer + 0.05
            _G.stateTimer = _G.stateTimer + 0.05 
            
            -- Failsafe 25 detik dinonaktifkan saat sedang berada di Luck Machine agar tidak mati prematur
            if _G.globalStuckTimer >= 25 and _G.targetAction ~= "LuckMachineTraining" and _G.targetAction ~= "LuckMachineTeleport" then
                _G.globalStuckTimer = 0
                _G.targetAction = "WaitingRespawn"
                hum.Health = 0 
                continue
            end
        end

        -- [ INTERUPSI EVENT CUACA (PAUSE AUTO FARM KECUALI SEDANG PULANG KE SAFE ZONE) ]
        if weatherEventPending then
            if _G.targetAction ~= "WalkToSafeZone" then
                weatherEventPending = false
                luckBuffObtained = false
                _G.targetAction = "LuckMachineTeleport"
            end
        end

        local distToSafeZone = (hrp.Position - safeZone).Magnitude

        -- [ FASE 1: IDLE / NENDANG (JEDA HANYA DI SPAWN) ]
        if _G.targetAction == "Idle" then
            if distToSafeZone > 10 then
                -- Jeda 1 detik setelah hidup di spawn sebelum teleport agar cepat aktif
                if _G.stateTimer >= 1 then
                    hrp.CFrame = safeZoneCFrame
                    _G.stateTimer = 0 
                end
            else
                -- Jeda 0.5 detik setelah teleport agar server mereplikasi posisi baru sebelum kick
                if _G.stateTimer >= 0.5 then
                    phase2Fired = false
                    collectedFired = false
                    kickEndedFired = false
                    if kickRemote then 
                        kickRemote:FireServer(1, 1) 
                    end
                    _G.targetAction = "WaitingForPhase2"
                end
            end

        -- [ FASE 2: NUNGGU PHASE 2 ]
        elseif _G.targetAction == "WaitingForPhase2" then
            if phase2Fired then
                phase2Fired = false
                _G.targetAction = "PlayingAnim"
            elseif _G.stateTimer > 5 then
                _G.targetAction = "Idle"
            end

        -- [ FASE 3: NUNGGU ANIMASI GACHA (5 DETIK) ]
        elseif _G.targetAction == "PlayingAnim" then
            if _G.stateTimer >= _G.animDelay then
                _G.targetAction = "WalkToSafeZone"
            end

        -- [ FASE 4: JALAN BALIK KE SAFE ZONE ]
        elseif _G.targetAction == "WalkToSafeZone" then
            hum:MoveTo(safeZone)
            if distToSafeZone < 8 then
                _G.targetAction = "WaitingForCollected"
            end

        -- [ FASE 5: NUNGGU COLLECTED ATAU KICKENDED (LANGSUNG KICK KEMBALI) ]
        elseif _G.targetAction == "WaitingForCollected" then
            if collectedFired or kickEndedFired then
                collectedFired = false
                kickEndedFired = false
                _G.mutationCount = _G.mutationCount + 1
                
                -- Langsung lakukan kick kembali tanpa delay
                phase2Fired = false
                if kickRemote then 
                    kickRemote:FireServer(1, 1) 
                end
                _G.targetAction = "WaitingForPhase2"
            elseif _G.stateTimer > 5 then
                _G.targetAction = "Idle"
            end

        -- [ FASE EX-1: TELEPORT KE LUCK MACHINE ]
        elseif _G.targetAction == "LuckMachineTeleport" then
            local targetPart = nil
            pcall(function()
                local debris = workspace:FindFirstChild("Debris")
                local luckMachine = debris and debris:FindFirstChild("LuckMachine")
                local standingPlatforms = luckMachine and luckMachine:FindFirstChild("StandingPlatforms")
                if standingPlatforms then
                    targetPart = standingPlatforms:FindFirstChild("1") 
                        or standingPlatforms:FindFirstChild("2") 
                        or standingPlatforms:FindFirstChild("3")
                end
            end)
            
            if targetPart then
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.5)
                _G.targetAction = "LuckMachineTraining"
            else
                if _G.stateTimer >= 3 then
                    _G.targetAction = "Idle"
                end
            end

        -- [ FASE EX-2: AUTO USE BARBELL DI LUCK MACHINE SAMPAI DAPAT LUCK BUFF ]
        elseif _G.targetAction == "LuckMachineTraining" then
            local targetPart = nil
            pcall(function()
                local debris = workspace:FindFirstChild("Debris")
                local luckMachine = debris and debris:FindFirstChild("LuckMachine")
                local standingPlatforms = luckMachine and luckMachine:FindFirstChild("StandingPlatforms")
                if standingPlatforms then
                    targetPart = standingPlatforms:FindFirstChild("1") 
                        or standingPlatforms:FindFirstChild("2") 
                        or standingPlatforms:FindFirstChild("3")
                end
            end)
            
            if targetPart and (hrp.Position - targetPart.Position).Magnitude > 8 then
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
            end
            
            -- Mekanik memegang & memakai Barbell
            local currentTool = char:FindFirstChildOfClass("Tool")
            if currentTool and string.match(currentTool.Name, "Barbell$") then
                currentTool:Activate()
            else
                local backpack = lp:FindFirstChild("Backpack")
                if backpack then
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") and string.match(tool.Name, "Barbell$") then
                            hum:EquipTool(tool)
                            task.wait(0.1)
                            tool:Activate()
                            break
                        end
                    end
                end
            end
            
            -- Jika buff keberuntungan sudah tercapai atau failsafe 240 detik terpenuhi
            if luckBuffObtained or _G.stateTimer >= 240 then
                pcall(function()
                    hum:UnequipTools()
                end)
                luckBuffObtained = false
                _G.targetAction = "Idle" -- Restart auto farm (Idle akan teleport balik ke safe zone)
            end
        end
    end
end)  
