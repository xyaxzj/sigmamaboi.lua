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
@@ -87,6 +91,22 @@ if rev_KickEventEnded then
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
        if string.find(tostring(msg), "Luck has been increased") or tostring(msgType) == "Reward" then
            luckBuffObtained = true
        end
    end)
end

-- =============================================
-- ⚙️ MAIN LOOP (STATE MACHINE - OPTIMIZED)
-- =============================================
@@ -136,6 +156,15 @@ task.spawn(function()
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
@@ -196,6 +225,75 @@ task.spawn(function()
elseif _G.stateTimer > 15 then
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
