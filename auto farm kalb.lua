_G.autoFarmKalb = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")

local lp = Players.LocalPlayer

-- CFrame & Posisi Safe Zone
local safeZoneCFrame = CFrame.new(698.030701, 3.298559, 233.707077, -0.061024, -0.000000, 0.998136, -0.000000, 1.000000, 0.000000, -0.998136, -0.000000, -0.061024)
local safeZonePosition = Vector3.new(698.030701, 3.298559, 233.707077)

-- Mencegah Kick AFK
lp.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- Tunggu Folder Network Remotes
local networkFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")
local rev_KickEvent = networkFolder:WaitForChild("rev_KickEvent")
local rev_kickPhase2 = networkFolder:WaitForChild("rev_kickPhase2")
local rev_Collected = networkFolder:WaitForChild("rev_Collected")

-- Flags untuk State Machine
local phase2Fired = false
local collectedFired = false

-- Daftarkan koneksi event agar tidak terlewat saat jeda/berjalan
rev_kickPhase2.OnClientEvent:Connect(function(...)
    phase2Fired = true
end)

rev_Collected.OnClientEvent:Connect(function(...)
    collectedFired = true
end)

-- Loop Utama Auto Farm
-- Fungsi untuk mendapatkan Character aktif yang masih hidup
local function getActiveCharacter()
    local char = lp.Character
    if not char or not char:Parent or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
        char = lp.CharacterAdded:Wait()
        char:WaitForChild("HumanoidRootPart", 10)
        char:WaitForChild("Humanoid", 10)
    end
    return char
end

-- Loop Utama Auto Farm
task.spawn(function()
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Farm Kalb",
            Text = "Script berhasil dimuat! Memulai loop...",
            Duration = 5
        })
    end)

    while true do
        task.wait(0.1)
        if not _G.autoFarmKalb then continue end
        
        -- Reset flag di setiap awal loop
        phase2Fired = false
        collectedFired = false
        
        -- Dapatkan karakter aktif
        local char = getActiveCharacter()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if not hrp or not hum then
            task.wait(1)
            continue
        end
        
        -- 1. Teleport ke Safe Zone (dengan tambahan offset Y agar kaki tidak tertanam di tanah)
        hrp.CFrame = safeZoneCFrame + Vector3.new(0, 2.5, 0)
        task.wait(0.3) -- Jeda singkat agar fisika stabil setelah teleport
        
        -- 2. Lakukan Kick ke Server
        rev_KickEvent:FireServer(1, 1)
        
        -- 3. Tunggu sampai event rev_kickPhase2 terpicu (Timeout 10 detik agar tidak stuck)
        local startPhase2Wait = os.clock()
        while _G.autoFarmKalb and not phase2Fired and (os.clock() - startPhase2Wait < 10) do
            task.wait(0.05)
        end
        
        if not _G.autoFarmKalb then continue end
        
        -- 4. Jeda 5 detik untuk animasi gacha selesai
        task.wait(5)
        
        -- 5. Jalan kaki balik ke Safe Zone (bukan teleport, loop deteksi pergerakan terhenti)
        if _G.autoFarmKalb then
            local startWalkTime = os.clock()
            while _G.autoFarmKalb and (os.clock() - startWalkTime < 15) do
                local curChar = getActiveCharacter()
                local curHum = curChar:FindFirstChild("Humanoid")
                local curHrp = curChar:FindFirstChild("HumanoidRootPart")
                
                if not curHum or curHum.Health <= 0 or not curHrp then
                    break
                end
                
                local distance = (curHrp.Position - safeZonePosition).Magnitude
                if distance <= 4 then
                    break
                end
                
                -- Hanya panggil MoveTo jika karakter tidak sedang melangkah/berhenti
                if curHum.MoveDirection.Magnitude == 0 then
                    curHum:MoveTo(safeZonePosition)
                end
                
                task.wait(0.2) -- Pengecekan status berjalan secara responsif
            end
        end
        
        if not _G.autoFarmKalb then continue end
        
        -- 6. Tunggu sampai event rev_Collected terpicu (Timeout 10 detik agar tidak stuck)
        local startCollectedWait = os.clock()
        while _G.autoFarmKalb and not collectedFired and (os.clock() - startCollectedWait < 10) do
            task.wait(0.05)
        end
    end
end)
