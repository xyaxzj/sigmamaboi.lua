if not game:IsLoaded() then game.Loaded:Wait() end

local rs = game:GetService("ReplicatedStorage")
local vim = game:GetService("VirtualInputManager")
local vu = game:GetService("VirtualUser")
local players = game:GetService("Players")
local tpService = game:GetService("TeleportService")
local http = game:GetService("HttpService")
local lighting = game:GetService("Lighting")
local lp = players.LocalPlayer

-- ==========================================================
-- 🛡️ TRUE GOD MODE & ANTI-AFK ABSOLUTE
-- ==========================================================
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and method == "FireServer" and tostring(self.Name) == "DamageEvent" then
        return -- Kebal total dari damage map
    end
    return oldNamecall(self, ...)
end)
if setreadonly then setreadonly(mt, true) end

-- Anti-AFK
lp.Idled:Connect(function()
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ==========================================================
-- KONFIGURASI GLOBAL
-- ==========================================================
_G.autoFarm = true 
_G.stackLimit = 10 
_G.removeTsunami = true 
_G.potatoMode = false -- Default OFF (Diaktifkan manual via UI)

local LOBI_Z_LIMIT = -120 
local currentLoop = 1
_G.forceReset = false 
_G.isFinishing = false 
local isHopping = false

local webhookURL = "https://discord.com/api/webhooks/1414935491773468713/0_7onZYQPn4c7Anlv_9gZPNjF-xuZq5ESHjU1F0PujgvYSyZp38iopQ3QfJTSA9MO4ms"
local allowedMutations = {"lava", "galaxy", "rainbow"}

-- ==========================================================
-- 🖥️ OVERLAY HUD (DENGAN PING MONITOR)
-- ==========================================================
local existingHud = pcall(function() return game:GetService("CoreGui"):FindFirstChild("FishItHUD") end) and game:GetService("CoreGui"):FindFirstChild("FishItHUD")
if not existingHud then pcall(function() local hud = lp.PlayerGui:FindFirstChild("FishItHUD") if hud then hud:Destroy() end end) end
if existingHud then existingHud:Destroy() end

local hudGui = Instance.new("ScreenGui")
hudGui.Name = "FishItHUD"
hudGui.ResetOnSpawn = false 
hudGui.IgnoreGuiInset = true

local successParent, _ = pcall(function() hudGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not successParent then hudGui.Parent = lp:WaitForChild("PlayerGui") end

local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.new(0, 250, 0, 90) 
hudFrame.Position = UDim2.new(0.5, -125, 0, 20)
hudFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
hudFrame.BackgroundTransparency = 0.3
hudFrame.BorderSizePixel = 0
hudFrame.Parent = hudGui

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 8)
hudCorner.Parent = hudFrame

local hudStroke = Instance.new("UIStroke")
hudStroke.Color = Color3.fromRGB(0, 255, 200)
hudStroke.Thickness = 2
hudStroke.Parent = hudFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "💎 AUTO FARM V70 (FINAL) 💎"
titleLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.Parent = hudFrame

local loopLabel = Instance.new("TextLabel")
loopLabel.Size = UDim2.new(1, 0, 0, 20)
loopLabel.Position = UDim2.new(0, 0, 0, 28)
loopLabel.BackgroundTransparency = 1
loopLabel.Text = "Putaran: 1 / 10"
loopLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
loopLabel.Font = Enum.Font.GothamMedium
loopLabel.TextSize = 15
loopLabel.Parent = hudFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 48)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Standby..."
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = hudFrame

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(1, 0, 0, 20)
pingLabel.Position = UDim2.new(0, 0, 0, 68)
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "Ping: Menghitung..."
pingLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
pingLabel.Font = Enum.Font.Gotham
pingLabel.TextSize = 12
pingLabel.Parent = hudFrame

local function updateDisplay(statusMsg)
    if loopLabel and statusLabel then
        loopLabel.Text = string.format("Putaran: %d / %d", currentLoop, _G.stackLimit)
        statusLabel.Text = tostring(statusMsg)
    end
end

-- Ping Updater Loop
task.spawn(function()
    while task.wait(1) do
        if pingLabel then
            pcall(function()
                local pingValue = "0"
                local stats = game:GetService("Stats"):FindFirstChild("Network")
                if stats and stats:FindFirstChild("ServerStatsItem") then
                    local dataPing = stats.ServerStatsItem:FindFirstChild("Data Ping")
                    if dataPing then pingValue = string.match(dataPing:GetValueString(), "%d+") end
                end
                if pingValue == "0" and lp.GetNetworkPing then
                    pingValue = tostring(math.floor(lp:GetNetworkPing() * 1000))
                end
                pingLabel.Text = "Ping: " .. pingValue .. " ms"
            end)
        end
    end
end)

-- ==========================================================
-- 🥔 POTATO MODE ENGINE (ANTI-LAG)
-- ==========================================================
local function applyPotatoMode()
    pcall(function()
        -- Matikan efek cahaya & bayangan
        lighting.GlobalShadows = false
        lighting.FogEnd = 9e9
        lighting.ShadowSoftness = 0
        if sethiddenproperty then pcall(function() sethiddenproperty(lighting, "Technology", 2) end) end
        
        -- Matikan tekstur partikel & ubah material jadi polos
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
    end)
end

task.spawn(function()
    while task.wait(3) do
        if _G.potatoMode then applyPotatoMode() end
    end
end)

-- ==========================================================
-- MANUAL SERVER HOP
-- ==========================================================
local function manualServerHop()
    if isHopping then return end
    isHopping = true
    updateDisplay("Hopping Server...")
    task.spawn(function()
        pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local reqData = game:HttpGet(url)
            if reqData then
                local data = http:JSONDecode(reqData)
                if data and data.data then
                    local servers = {}
                    for _, v in ipairs(data.data) do
                        if type(v) == "table" and tonumber(v.playing) ~= nil and v.id ~= game.JobId then
                            table.insert(servers, v.id)
                        end
                    end
                    if #servers > 0 then
                        tpService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], lp)
                    end
                end
            end
        end)
        task.wait(5)
        isHopping = false
        updateDisplay("Hop Selesai / Gagal")
    end)
end

-- ==========================================================
-- UTILITAS (ANTI-TSUNAMI & GACHA FAILSAFE)
-- ==========================================================
task.spawn(function()
    while task.wait(1) do
        if not _G.removeTsunami then continue end
        pcall(function() for _, v in pairs(workspace:GetDescendants()) do if string.find(string.lower(v.Name), "tsunami") then v:Destroy() end end end)
    end
end)

task.spawn(function()
    pcall(function()
        for _, v in pairs(rs:GetDescendants()) do
            if v:IsA("RemoteEvent") and string.lower(v.Name) == "sequenceevent" then
                if getconnections then for _, conn in pairs(getconnections(v.OnClientEvent)) do conn:Disable() end end
                v.OnClientEvent:Connect(function(arg1, itemName, arg3)
                    if not _G.isFinishing then
                        updateDisplay("⚠️ Rem Darurat: Gacha Masuk!")
                        _G.forceReset = true
                    end
                    if itemName and type(itemName) == "string" then
                        local lowerName = string.lower(itemName)
                        for _, mutation in ipairs(allowedMutations) do
                            if string.find(lowerName, mutation) then 
                                pcall(function()
                                    local data = { ["username"] = "V70 Tracker", ["embeds"] = {{ ["title"] = "MUTASI DIDAPAT!", ["description"] = "**" .. lp.Name .. "** dapet: " .. itemName, ["color"] = 16711680 }} }
                                    local req = (syn and syn.request) or request or http_request
                                    if req then req({Url = webhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = http:JSONEncode(data)}) end
                                end)
                                break 
                            end
                        end
                    end
                end)
            end
        end
    end)
end)

local function getRemoteDoor()
    for _, v in pairs(rs:GetDescendants()) do
        if v:IsA("RemoteEvent") and string.lower(v.Name) == "doorevent" then return v end
    end return nil
end

-- ==========================================================
-- MENU UI RAYFIELD
-- ==========================================================
local library = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local win = library:CreateWindow({Name = "Auto Farm (V70 Optimized)", LoadingTitle = "Memuat Fitur Anti-Lag...", ConfigurationSaving = {Enabled = false}, KeySystem = false})
local tab = win:CreateTab("Main", 4483362458)

tab:CreateToggle({Name = "Auto Farm Aktif", CurrentValue = true, Callback = function(val) _G.autoFarm = val updateDisplay("Auto Farm: " .. tostring(val)) end})
tab:CreateSlider({ Name = "Target Stacking", Range = {1, 50}, Increment = 1, Suffix = "x", CurrentValue = 10, Flag = "StackSlider", Callback = function(Value) _G.stackLimit = Value updateDisplay("Target diubah ke " .. tostring(Value)) end })
tab:CreateToggle({Name = "Grafik Kentang (Potato Mode)", CurrentValue = false, Callback = function(val) _G.potatoMode = val end})
tab:CreateToggle({Name = "Hapus Tsunami (Anti-Lag)", CurrentValue = true, Callback = function(val) _G.removeTsunami = val end})
tab:CreateButton({ Name = "🔄 Manual Server Hop", Callback = function() manualServerHop() end })

-- ==========================================================
-- CORE ENGINE: FARM LOGIC
-- ==========================================================
local function executeFarmCycle()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChild("Humanoid")
    
    if not hrp or not humanoid or humanoid.Health <= 0 then 
        updateDisplay("Menunggu Karakter...")
        return 
    end
    
    local currentZ = hrp.Position.Z

    if _G.forceReset then
        updateDisplay("Memulihkan ke Lobi...")
        hrp.Anchored = true 
        hrp.CFrame = CFrame.new(-174, 12, -170)
        hrp.Velocity = Vector3.new(0, 0, 0)
        task.wait(0.5)
        hrp.Anchored = false
        _G.forceReset = false
        return
    end

    -- FASE 1: LOBI
    if currentZ < LOBI_Z_LIMIT then
        currentLoop = 1
        updateDisplay("Lobi: Klik Start Run")
        
        for _, obj in pairs(lp.PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local txt = string.lower(string.gsub(obj.Text or "", "%s+", ""))
                local name = string.lower(obj.Name)
                
                if string.find(txt, "start") or string.find(txt, "run") or string.find(name, "start") then
                    local btn = obj:IsA("TextButton") and obj or obj:FindFirstAncestorWhichIsA("TextButton") or obj:FindFirstAncestorWhichIsA("ImageButton")
                    if btn and btn.AbsolutePosition.X > 0 then
                        updateDisplay("Lobi: Menunggu Server Arena...")
                        if getconnections then
                            for _, c in pairs(getconnections(btn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                            for _, c in pairs(getconnections(btn.Activated)) do pcall(function() c:Fire() end) end
                        end
                        local ax, ay = btn.AbsolutePosition.X + btn.AbsoluteSize.X/2, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y/2 + 36
                        vim:SendMouseButtonEvent(ax, ay, 0, true, game, 1)
                        task.wait(0.05)
                        vim:SendMouseButtonEvent(ax, ay, 0, false, game, 1)
                        
                        local timeout = 0
                        repeat
                            task.wait(0.5)
                            timeout = timeout + 0.5
                            char = lp.Character
                            hrp = char and char:FindFirstChild("HumanoidRootPart")
                        until (hrp and hrp.Position.Z > (LOBI_Z_LIMIT + 10)) or timeout > 10 or _G.forceReset
                        return 
                    end
                end
            end
        end
        
    -- FASE 2: EKSKUSI ARENA (TERMINATOR)
    else
        updateDisplay("Arena: Scanning & Menghancurkan Pintu...")
        hrp.Anchored = true
        hrp.CFrame = CFrame.new(-128, 50, hrp.Position.Z) 
        task.wait(1.5) 
        
        local remote = getRemoteDoor()
        local goodDoors = {}
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local surfaceGui = obj:FindFirstChildOfClass("SurfaceGui") or obj:FindFirstChildOfClass("BillboardGui")
                if surfaceGui then
                    local textLabel = surfaceGui:FindFirstChildWhichIsA("TextLabel", true) or surfaceGui:FindFirstChildWhichIsA("TextButton", true)
                    if textLabel then
                        local txt = string.lower(string.gsub(textLabel.Text or "", "%s+", ""))
                        local numStr = string.match(txt, "%d+%.?%d*")
                        
                        if numStr then
                            local num = tonumber(numStr)
                            local isMult = string.find(txt, "x") or string.find(txt, "%*") or string.find(txt, "×")
                            local isAdd = string.find(txt, "%+")
                            local isMinus = string.find(txt, "%-")
                            local isDiv = string.find(txt, "÷") or string.find(txt, "/")

                            if isMinus or isDiv or (isMult and num < 1) then
                                pcall(function() obj:Destroy() end)
                            elseif isAdd or (isMult and num >= 1) then
                                local operation = isMult and "mul" or "add"
                                table.insert(goodDoors, {
                                    x = obj.Position.X, 
                                    y = obj.Position.Y, 
                                    z = obj.Position.Z, 
                                    num = num, 
                                    op = operation
                                })
                            end
                        end
                    end
                end
            end
        end

        if remote and #goodDoors > 0 then
            table.sort(goodDoors, function(a, b) return a.z < b.z end)
            updateDisplay("Arena: Menyedot Target...")
            
            hrp.Anchored = true
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end

            for _, door in ipairs(goodDoors) do
                if _G.forceReset then break end 
                if door.z < 5100 then 
                    hrp.CFrame = CFrame.new(door.x, door.y, door.z)
                    task.wait(0.08) 
                    remote:FireServer(door.num, door.op)
                end
            end
            
            if _G.forceReset then hrp.Anchored = false return end
            
            if currentLoop < _G.stackLimit then
                updateDisplay("Mati: Mereset Posisi Arena...")
                currentLoop = currentLoop + 1
                hrp.Anchored = false
                
                pcall(function() char.Humanoid.Health = 0 end)
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
                updateDisplay("Menembus Garis Finish!")
                _G.isFinishing = true 
                
                hrp.CFrame = CFrame.new(-122.8, hrp.Position.Y, 5200)
                hrp.Anchored = false
                hrp.Velocity = Vector3.new(0,0,0)
                task.wait(3.5) 
                
                updateDisplay("Selesai: Kembali ke Lobi")
                hrp.Anchored = true 
                hrp.CFrame = CFrame.new(-174, 12, -170)
                hrp.Velocity = Vector3.new(0, 0, 0)
                task.wait(0.5)
                hrp.Anchored = false
                
                _G.isFinishing = false 
            end
        else
            updateDisplay("Arena: Map belum siap / Pintu Kosong")
            task.wait(2)
        end
    end
end

-- ==========================================================
-- PEMANGGILAN ENGINE
-- ==========================================================
task.spawn(function()
    while task.wait(0.5) do
        if _G.autoFarm then
            local success, err = pcall(executeFarmCycle)
            if not success then
                updateDisplay("ERROR: Recovery Mode")
                task.wait(1.5) 
            end
        end
    end
end)
