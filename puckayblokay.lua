if not game:IsLoaded() then game.Loaded:Wait() end

local rs = game:GetService("ReplicatedStorage")
local vim = game:GetService("VirtualInputManager")
local vu = game:GetService("VirtualUser")
local players = game:GetService("Players")
local tpService = game:GetService("TeleportService")
local http = game:GetService("HttpService")
local lp = players.LocalPlayer

-- ==========================================================
-- SISTEM LOGGING (CCTV)
-- ==========================================================
_G.FarmLogs = "=== MEMULAI SESI LOG V53 (IMMUNITY EDITION) ===\n"
local function addLog(msg)
    local t = os.date("%H:%M:%S")
    local posStr = "[Pos: MATI]"
    pcall(function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then posStr = string.format("[Pos: %.1f, %.1f, %.1f]", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) end
    end)
    local logMsg = "[" .. t .. "] " .. posStr .. " " .. tostring(msg)
    _G.FarmLogs = _G.FarmLogs .. logMsg .. "\n"
    print(logMsg) 
end

-- ==========================================================
-- KONFIGURASI GLOBAL
-- ==========================================================
_G.autoFarm = true 
_G.stackLimit = 10 
_G.removeTsunami = true 

local currentLoop = 1
_G.forceReset = false 
local LOBI_Z_LIMIT = -120 

local webhookURL = "https://discord.com/api/webhooks/1414935491773468713/0_7onZYQPn4c7Anlv_9gZPNjF-xuZq5ESHjU1F0PujgvYSyZp38iopQ3QfJTSA9MO4ms"
local allowedMutations = {"lava", "galaxy", "rainbow"}

-- ==========================================================
-- ANTI-LAG TSUNAMI
-- ==========================================================
task.spawn(function()
    while task.wait(1) do
        if _G.removeTsunami then
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if string.find(string.lower(v.Name), "tsunami") then v:Destroy() end
                end
            end)
        end
    end
end)

-- ==========================================================
-- WEBHOOK HANDLER
-- ==========================================================
local httprequest = nil
pcall(function() httprequest = (syn and syn.request) or (fluxus and fluxus.request) or request or http_request end)
local function sendToDiscord(itemName)
    if not httprequest then return end
    pcall(function()
        local data = {
            ["username"] = "God Farm Tracker",
            ["embeds"] = {{ ["title"] = "MUTASI LANGKA!", ["description"] = "Pemain **" .. lp.Name .. "** dapet: " .. tostring(itemName), ["color"] = 16711680 }}
        }
        httprequest({Url = webhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = http:JSONEncode(data)})
    end)
end

-- ==========================================================
-- PENGINTAI GACHA (EMERGENCY BRAKE)
-- ==========================================================
task.spawn(function()
    pcall(function()
        for _, v in pairs(rs:GetDescendants()) do
            if v:IsA("RemoteEvent") and string.lower(v.Name) == "sequenceevent" then
                if getconnections then for _, conn in pairs(getconnections(v.OnClientEvent)) do conn:Disable() end end
                v.OnClientEvent:Connect(function(arg1, itemName, arg3)
                    addLog("GACHA MASUK! Memicu Rem Darurat...")
                    _G.forceReset = true
                    currentLoop = 1
                    
                    if itemName and type(itemName) == "string" then
                        local lowerName = string.lower(itemName)
                        for _, mutation in ipairs(allowedMutations) do
                            if string.find(lowerName, mutation) then sendToDiscord(itemName) break end
                        end
                    end
                end)
            end
        end
    end)
end)

local function getRemote()
    for _, v in pairs(rs:GetDescendants()) do
        if v:IsA("RemoteEvent") and string.lower(v.Name) == "doorevent" then return v end
    end return nil
end

lp.Idled:Connect(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end)

-- ==========================================================
-- MENU UI RAYFIELD
-- ==========================================================
local library = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local win = library:CreateWindow({Name = "Auto Farm (V53 Immune)", LoadingTitle = "Z-Axis + Immunity...", ConfigurationSaving = {Enabled = false}, KeySystem = false})
local tab = win:CreateTab("Main", 4483362458)

tab:CreateButton({
    Name = "Salin Log ke Clipboard",
    Callback = function()
        if setclipboard then setclipboard(_G.FarmLogs) library:Notify({Title = "Log Tersalin!", Content = "Paste ke obrolan AI sekarang.", Duration = 3}) end
    end,
})
tab:CreateToggle({Name = "Auto Farm", CurrentValue = true, Callback = function(val) _G.autoFarm = val end})
tab:CreateSlider({Name = "Target Stacking", Range = {1, 50}, Increment = 1, Suffix = "x", CurrentValue = 10, Flag = "StackSlider", Callback = function(Value) _G.stackLimit = Value end})
tab:CreateToggle({Name = "Hapus Tsunami", CurrentValue = true, Callback = function(val) _G.removeTsunami = val end})

-- ==========================================================
-- LOOP UTAMA AUTO FARM (Z-AXIS ABSOLUTE + TRUE IMMUNITY)
-- ==========================================================
task.spawn(function()
    while task.wait(0.5) do
        if not _G.autoFarm then continue end

        pcall(function()
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChild("Humanoid")
            if not hrp or not humanoid or humanoid.Health <= 0 then return end

            local currentZ = hrp.Position.Z

            -- [PENANGANAN REM DARURAT]
            if _G.forceReset then
                addLog("Mereset posisi ke Lobi akibat Rem Darurat.")
                hrp.Anchored = false
                hrp.CFrame = CFrame.new(-174, 12, -170)
                task.wait(1)
                _G.forceReset = false
                currentLoop = 1
                return
            end

            -- [FASE 1: ZONA LOBI]
            if currentZ < LOBI_Z_LIMIT then
                for _, obj in pairs(lp.PlayerGui:GetDescendants()) do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                        local txt = string.lower(string.gsub(obj.Text or "", "%s+", ""))
                        local name = string.lower(obj.Name)
                        if string.find(txt, "start") or string.find(txt, "run") or string.find(name, "start") then
                            local btn = obj:IsA("TextButton") and obj or obj:FindFirstAncestorWhichIsA("TextButton") or obj:FindFirstAncestorWhichIsA("ImageButton")
                            if btn and btn.AbsolutePosition.X > 0 then
                                addLog("Mengklik Start Run dari Lobi.")
                                if getconnections then
                                    for _, c in pairs(getconnections(btn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                                    for _, c in pairs(getconnections(btn.Activated)) do pcall(function() c:Fire() end) end
                                end
                                local ax, ay = btn.AbsolutePosition.X + btn.AbsoluteSize.X/2, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y/2 + 36
                                vim:SendMouseButtonEvent(ax, ay, 0, true, game, 1)
                                task.wait(0.05)
                                vim:SendMouseButtonEvent(ax, ay, 0, false, game, 1)
                                
                                local waitTimeout = 0
                                repeat
                                    task.wait(0.5)
                                    waitTimeout = waitTimeout + 0.5
                                    char = lp.Character
                                    hrp = char and char:FindFirstChild("HumanoidRootPart")
                                until (hrp and hrp.Position.Z > (LOBI_Z_LIMIT + 10)) or waitTimeout > 10 or _G.forceReset
                                break 
                            end
                        end
                    end
                end
            
            -- [FASE 2: ZONA ARENA]
            else
                addLog("Loop ke: " .. tostring(currentLoop) .. "/" .. tostring(_G.stackLimit))
                task.wait(1.5) 
                
                local remote = getRemote()
                local goodDoors = {}
                
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                        local str = string.lower(string.gsub(obj.Text or "", "%s+", ""))
                        local hasPlus = string.find(str, "%+")
                        local hasMult = string.find(str, "x") or string.find(str, "%*")
                        local hasMinus = string.find(str, "%-")
                        local hasDiv = string.find(str, "÷") or string.find(str, "/")
                        local isDecimal = string.find(str, "0%.")
                        
                        local part = obj:FindFirstAncestorWhichIsA("BasePart")
                        if part then
                            -- LOGIKA TRUE IMMUNITY (KEBAL TOTAL)
                            if hasMinus or hasDiv or isDecimal then
                                pcall(function()
                                    part:Destroy() -- Pintu Sialan Dihapus Secara Fisik dari Map
                                end)
                            -- LOGIKA PINTU BAGUS
                            elseif (hasPlus or hasMult) then
                                local num = tonumber(string.match(str, "%d+%.?%d*"))
                                if num then
                                    local op = hasMult and "mul" or "add"
                                    table.insert(goodDoors, {part = part, num = num, op = op, z = part.Position.Z})
                                end
                            end
                        end
                    end
                end

                if remote and #goodDoors > 0 then
                    table.sort(goodDoors, function(a, b) return a.z < b.z end)
                    hrp.Anchored = true
                    for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end

                    -- PENYEDOTAN PINTU BAGUS
                    for _, door in ipairs(goodDoors) do
                        if _G.forceReset then break end 
                        if door.z < 5100 then 
                            hrp.CFrame = CFrame.new(door.part.Position.X, hrp.Position.Y, door.z)
                            task.wait(0.05)
                            remote:FireServer(door.num, door.op)
                        end
                    end
                    
                    if _G.forceReset then hrp.Anchored = false return end
                    
                    -- LOGIKA STACKING (MATI & RESPAWN)
                    if currentLoop < _G.stackLimit then
                        addLog("Bunuh diri untuk stacking.")
                        currentLoop = currentLoop + 1
                        hrp.Anchored = false
                        char:BreakJoints()
                        
                        local deathTimeout = 0
                        repeat task.wait(0.1) deathTimeout = deathTimeout + 0.1 char = lp.Character until (not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0) or deathTimeout > 5
                        
                        local timeoutRespawn = 0
                        repeat
                            task.wait(0.5)
                            timeoutRespawn = timeoutRespawn + 0.5
                            char = lp.Character
                            hrp = char and char:FindFirstChild("HumanoidRootPart")
                        until (hrp and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and hrp.Position.Z > (LOBI_Z_LIMIT + 10)) or timeoutRespawn >= 15
                        
                        task.wait(1.5) 
                    else
                        addLog("Garis Finish Ditembus!")
                        currentLoop = 1
                        hrp.CFrame = CFrame.new(-122.8, hrp.Position.Y, 5200)
                        hrp.Anchored = false
                        hrp.Velocity = Vector3.new(0,0,0)
                        task.wait(3.5)
                        hrp.CFrame = CFrame.new(-174, 12, -170)
                        task.wait(1)
                    end
                else
                    addLog("Pintu gagal dimuat. Menunggu render map...")
                    task.wait(2)
                end
            end
        end)
    end
end)
