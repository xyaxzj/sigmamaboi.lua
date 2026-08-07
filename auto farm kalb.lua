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
        
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        local hum = char:WaitForChild("Humanoid", 10)
        
        if not hrp or not hum then
            task.wait(1)
            continue
        end
        
        -- 1. Teleport ke Safe Zone
        hrp.CFrame = safeZoneCFrame
        task.wait(0.3) -- Jeda singkat agar fisika stabil setelah teleport
        
        -- 2. Lakukan Kick ke Server
        rev_KickEvent:FireServer(1, 1)
        
        -- 3. Tunggu sampai event rev_kickPhase2 terpicu
        while _G.autoFarmKalb and not phase2Fired do
            task.wait(0.05)
        end
        
        if not _G.autoFarmKalb then continue end
        
        -- 4. Jeda 5 detik untuk animasi gacha selesai
        task.wait(5)
        
        -- 5. Jalan kaki balik ke Safe Zone (bukan teleport)
        if _G.autoFarmKalb and hum and hrp then
            hum:MoveTo(safeZonePosition)
            pcall(function()
                hum.MoveToFinished:Wait()
            end)
        end
        
        if not _G.autoFarmKalb then continue end
        
        -- 6. Tunggu sampai event rev_Collected terpicu
        while _G.autoFarmKalb and not collectedFired do
            task.wait(0.05)
        end
    end
end)
