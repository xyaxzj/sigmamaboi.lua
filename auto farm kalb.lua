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
_G.animDelay = 5              -- Jeda animasi gacha saat kick (5 detik)
_G.autoRemovePlayer = false   -- true: Hapus player lain (FPS boost ekstrem), false: Biarkan player lain tetap ada

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
if _G.autoRemovePlayer or _G.removePlayer or _G.removePlayers then
    local function musnahkanPlayer(player)
        if player ~= lp then
            if player.Character then
                pcall(function() player.Character:Destroy() end)
            end
            pcall(function() player:Destroy() end)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        musnahkanPlayer(player)
    end

    Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            if _G.autoRemovePlayer or _G.removePlayer or _G.removePlayers then
                musnahkanPlayer(player)
            end
        end)
    end)

    local function periksaDanHapus(descendant)
        if not (_G.autoRemovePlayer or _G.removePlayer or _G.removePlayers) then return end
        if descendant:IsA("Humanoid") then
            local charModel = descendant.Parent
            if charModel and charModel:IsA("Model") and charModel.Name ~= lp.Name then
                pcall(function() charModel:Destroy() end)
            end
        end
    end

    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child.Name ~= lp.Name and child:FindFirstChildOfClass("Humanoid") then
            pcall(function() child:Destroy() end)
        end
    end

    workspace.DescendantAdded:Connect(function(descendant)
        task.defer(periksaDanHapus, descendant)
    end)
end

-- =============================================
-- 🧠 VARIABEL OTAK UTAMA (STATE MACHINE)
-- =============================================
_G.targetAction = "Idle"
_G.lastAction = "Idle"
_G.nextAction = "Idle"          
_G.stateTimer = 0               
_G.globalStuckTimer = 0         
_G.mutationCount = 0            
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
-- 📜 DIAGNOSTIC LOGGER & NETWORK INSPECTOR
-- =============================================
local function LogDiag(category, msg)
    local now = os.date and os.date("%X") or tostring(math.floor(tick()))
    local formatted = string.format("[AutoFarm %s] [%s] %s", now, tostring(category), tostring(msg))
    print(formatted)
end

-- =============================================
-- 📡 CARI REMOTE
-- =============================================
local networkFolder = ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
local ref_KickEvent = networkFolder and (networkFolder:FindFirstChild("ref_KickEvent") or networkFolder:WaitForChild("ref_KickEvent", 5))
local rev_KickEvent = networkFolder and networkFolder:FindFirstChild("rev_KickEvent")

if not ref_KickEvent and not rev_KickEvent then
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r.Name == "ref_KickEvent" and r:IsA("RemoteFunction") then
            ref_KickEvent = r
            break
        elseif r.Name == "rev_KickEvent" and r:IsA("RemoteEvent") then
            rev_KickEvent = r
            break
        end
    end
end

-- =============================================
-- 🎯 UI KICK CONTROLLER & PERFECT TIMING TRACKER
-- =============================================
local playerGui = lp:WaitForChild("PlayerGui", 10) or lp:FindFirstChild("PlayerGui")

-- Helper mencari Tombol Kick di PlayerGui
local function FindKickButton()
    if not playerGui then return nil end
    local hud = playerGui:FindFirstChild("HUD")
    if hud then
        local btn = hud:FindFirstChild("KickButton", true)
        if btn and btn:IsA("GuiButton") then return btn end
    end
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local btn = gui:FindFirstChild("KickButton", true)
            if btn and btn:IsA("GuiButton") then return btn end
        end
    end
    return nil
end

-- Helper trigger klik tombol GUI
local function TriggerGuiClick(btn)
    if not btn then return end
    pcall(function()
        if firesignal then
            firesignal(btn.MouseButton1Down)
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
            firesignal(btn.MouseButton1Up)
        end
    end)
    pcall(function()
        local absPos = btn.AbsolutePosition
        local absSize = btn.AbsoluteSize
        local center = absPos + (absSize / 2)
        VirtualUser:Button1Down(Vector2.new(center.X, center.Y))
        task.wait(0.01)
        VirtualUser:Button1Up(Vector2.new(center.X, center.Y))
    end)
end

-- Helper Auto Perfect Timing Bar Minigame
local function HandleKickMinigame(timeoutSec)
    local deadline = os.clock() + (timeoutSec or 3.5)
    local minigameGui = nil
    
    -- 1. Tunggu KickMinigame aktif di PlayerGui
    while os.clock() < deadline do
        minigameGui = playerGui and playerGui:FindFirstChild("KickMinigame")
        if minigameGui and (minigameGui.Enabled or minigameGui:FindFirstChildWhichIsA("Frame", true)) then
            break
        end
        task.wait(0.05)
    end
    
    if not minigameGui then
        LogDiag("MINIGAME", "KickMinigame GUI tidak muncul, menggunakan invoke fallback.")
        return false
    end
    
    -- 2. Cari MovingBar dan Target/Green Zone
    local movingBar = minigameGui:FindFirstChild("MovingBar", true)
    if not movingBar then
        LogDiag("MINIGAME", "MovingBar tidak ditemukan di KickMinigame.")
        return false
    end
    
    local targetZone = nil
    local parentFrame = movingBar.Parent
    if parentFrame then
        for _, child in ipairs(parentFrame:GetChildren()) do
            if child:IsA("GuiObject") and child ~= movingBar then
                local n = child.Name:lower()
                if n:find("target") or n:find("perfect") or n:find("green") or n:find("zone") or n:find("area") or n:find("goal") then
                    targetZone = child
                    break
                end
            end
        end
    end
    
    LogDiag("MINIGAME", string.format("Tracking MovingBar aktif (Target: %s)...", targetZone and targetZone.Name or "Tengah Frame"))
    
    -- 3. RenderStepped Tracking untuk Perfect Hit
    local hitDone = false
    local connection = nil
    local kickBtn = FindKickButton()
    
    connection = RunService.RenderStepped:Connect(function()
        if hitDone or os.clock() >= deadline or not movingBar.Parent or not minigameGui.Enabled then
            if connection then connection:Disconnect() end
            return
        end
        
        local barCenter = movingBar.AbsolutePosition.X + (movingBar.AbsoluteSize.X / 2)
        local targetCenter = 0
        local tolerance = 15 -- pixel toleransi
        
        if targetZone then
            targetCenter = targetZone.AbsolutePosition.X + (targetZone.AbsoluteSize.X / 2)
            tolerance = math.max(15, targetZone.AbsoluteSize.X / 2)
        elseif parentFrame and parentFrame:IsA("GuiObject") then
            targetCenter = parentFrame.AbsolutePosition.X + (parentFrame.AbsoluteSize.X / 2)
            tolerance = math.max(15, parentFrame.AbsoluteSize.X * 0.1)
        end
        
        -- Cek apakah MovingBar sudah berada tepat di area Perfect
        if math.abs(barCenter - targetCenter) <= tolerance then
            hitDone = true
            if connection then connection:Disconnect() end
            
            LogDiag("MINIGAME", string.format("🎯 PERFECT HIT! (Delta: %.1f px)", math.abs(barCenter - targetCenter)))
            
            -- Klik KickButton atau tap area minigame untuk mengunci Perfect Kick
            if kickBtn then
                TriggerGuiClick(kickBtn)
            end
            
            pcall(function()
                local center = movingBar.AbsolutePosition + (movingBar.AbsoluteSize / 2)
                VirtualUser:Button1Down(Vector2.new(center.X, center.Y))
                task.wait(0.01)
                VirtualUser:Button1Up(Vector2.new(center.X, center.Y))
            end)
        end
    end)
    
    -- Tunggu sampai hit selesai atau minigame tertutup
    while not hitDone and os.clock() < deadline and minigameGui.Enabled do
        task.wait(0.02)
    end
    if connection then pcall(function() connection:Disconnect() end) end
    
    return hitDone
end

-- Helper Eksekusi Kick Lengkap (UI Trigger + Perfect Timing + Remote Fallback)
local function executeKick()
    task.spawn(function()
        local kickBtn = FindKickButton()
        if kickBtn then
            LogDiag("KICK", "Menekan KickButton di HUD...")
            TriggerGuiClick(kickBtn)
            
            -- Tunggu dan lock Perfect Timing di MovingBar
            local perfectOk = HandleKickMinigame(3.5)
            if perfectOk then
                LogDiag("KICK", "✅ Perfect Kick Minigame berhasil diselesaikan!")
                return
            end
        end
        
        -- Fallback jika UI tidak membuka minigame
        local timestamp = nil
        pcall(function()
            timestamp = workspace:GetServerTimeNow()
        end)
        if not timestamp or type(timestamp) ~= "number" or timestamp <= 0 then
            timestamp = tick()
        end
        
        if ref_KickEvent then
            pcall(function()
                ref_KickEvent:InvokeServer(1, 1, timestamp)
            end)
        elseif rev_KickEvent then
            pcall(function()
                if rev_KickEvent:IsA("RemoteFunction") then
                    rev_KickEvent:InvokeServer(1, 1, timestamp)
                else
                    rev_KickEvent:FireServer(1, 1, timestamp)
                end
            end)
        end
    end)
end

local rev_kickPhase2 = networkFolder and networkFolder:WaitForChild("rev_kickPhase2", 5)
local rev_KickData = networkFolder and networkFolder:WaitForChild("rev_KickData", 5)
local rev_Collected = networkFolder and networkFolder:WaitForChild("rev_Collected", 5)
local rev_KickEventEnded = networkFolder and networkFolder:WaitForChild("rev_KickEventEnded", 5)

-- =============================================
-- 📡 DAFTAR EVENT LISTENER
-- =============================================
local phase2Fired = false
local collectedFired = false
local kickEndedFired = false

if rev_kickPhase2 then
    rev_kickPhase2.OnClientEvent:Connect(function(...)
        phase2Fired = true
        LogDiag("NET IN", "rev_kickPhase2 terpanggil!")
    end)
end

if rev_KickData then
    rev_KickData.OnClientEvent:Connect(function(data1, data2)
        phase2Fired = true
        _G.mutationCount = _G.mutationCount + 1
        LogDiag("REWARD", string.format("🎉 rev_KickData Diterima! Data: [%s, %s]", tostring(data1), tostring(data2)))
    end)
end

if rev_Collected then
    rev_Collected.OnClientEvent:Connect(function(...)
        collectedFired = true
        LogDiag("NET IN", "rev_Collected terpanggil!")
    end)
end

if rev_KickEventEnded then
    rev_KickEventEnded.OnClientEvent:Connect(function(...)
        kickEndedFired = true
        LogDiag("NET IN", "rev_KickEventEnded terpanggil!")
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
        if _G.lastAction ~= _G.targetAction then
            LogDiag("STATE", string.format("%s ➔ %s", tostring(_G.lastAction), tostring(_G.targetAction)))
            _G.globalStuckTimer = 0 
            _G.stateTimer = 0 
            _G.lastAction = _G.targetAction
        else
            _G.globalStuckTimer = _G.globalStuckTimer + 0.05
            _G.stateTimer = _G.stateTimer + 0.05 
            
            -- Failsafe 25 detik agar tidak stuck selamanya
            if _G.globalStuckTimer >= 25 then
                _G.globalStuckTimer = 0
                _G.targetAction = "WaitingRespawn"
                hum.Health = 0 
                continue
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
                    executeKick()
                    _G.targetAction = "WaitingForPhase2"
                end
            end

        -- [ FASE 2: NUNGGU PHASE 2 / KICK DATA ]
        elseif _G.targetAction == "WaitingForPhase2" then
            if phase2Fired or _G.stateTimer >= 1.5 then
                phase2Fired = false
                _G.targetAction = "PlayingAnim"
            end

        -- [ FASE 3: NUNGGU ANIMASI GACHA (5 DETIK) ]
        elseif _G.targetAction == "PlayingAnim" then
            if _G.stateTimer >= (_G.animDelay or 5) then
                _G.targetAction = "WalkToSafeZone"
            end

        -- [ FASE 4: JALAN BALIK KE SAFE ZONE ]
        elseif _G.targetAction == "WalkToSafeZone" then
            hum:MoveTo(safeZone)
            if distToSafeZone < 8 then
                _G.targetAction = "WaitingForCollected"
            elseif _G.stateTimer >= 3.5 then
                -- Failsafe teleport jika jalan kaki terhalang
                hrp.CFrame = safeZoneCFrame
                _G.targetAction = "WaitingForCollected"
            end

        -- [ FASE 5: NUNGGU COLLECTED ATAU KICKENDED (LANGSUNG KICK KEMBALI) ]
        elseif _G.targetAction == "WaitingForCollected" then
            if collectedFired or kickEndedFired or _G.stateTimer >= 1.5 then
                collectedFired = false
                kickEndedFired = false
                
                -- Langsung lakukan kick kembali tanpa delay
                phase2Fired = false
                executeKick()
                _G.targetAction = "WaitingForPhase2"
            end
        end
    end
end)  
