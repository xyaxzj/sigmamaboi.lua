if not game:IsLoaded() then game.Loaded:Wait() end

local rs = game:GetService("ReplicatedStorage")
local vim = game:GetService("VirtualInputManager")
local vu = game:GetService("VirtualUser")
local players = game:GetService("Players")
local tpService = game:GetService("TeleportService")
local http = game:GetService("HttpService")
local tweenService = game:GetService("TweenService")
local lp = players.LocalPlayer

-- ==========================================================
-- ⚙️ KONFIGURASI UTAMA
-- ==========================================================
_G.autoFarm = true 
_G.serverHop = true
_G.useWebhook = true
_G.dashSpeed = 0.08 
local webhookURL = "https://discord.com/api/webhooks/1414935491773468713/0_7onZYQPn4c7Anlv_9gZPNjF-xuZq5ESHjU1F0PujgvYSyZp38iopQ3QfJTSA9MO4ms"

-- FILTER MUTASI (Bisa ditambah/dikurang, pastikan huruf kecil semua)
local allowedMutations = {"lava", "galaxy", "rainbow"}

-- ==========================================================
-- 🌐 WEBHOOK & HTTP REQUEST HANDLER
-- ==========================================================
local httprequest = nil
pcall(function()
    httprequest = (syn and syn.request) or (fluxus and fluxus.request) or request or http_request
end)

local function sendToDiscord(itemName)
    if not httprequest or not _G.useWebhook then return end
    pcall(function()
        local data = {
            ["username"] = "Auto Farm Tracker",
            ["avatar_url"] = "https://i.imgur.com/13YMBHT.png",
            ["embeds"] = {
                {
                    ["title"] = "✨ MUTASI DIDAPATKAN!",
                    ["description"] = "Pemain **" .. lp.Name .. "** berhasil mendapatkan Mutasi Tier Tinggi:",
                    ["color"] = 16711680, -- Warna Merah (Hex: FF0000) biar mencolok
                    ["fields"] = {
                        {
                            ["name"] = "📦 Nama Item",
                            ["value"] = "```" .. tostring(itemName) .. "```",
                            ["inline"] = false
                        }
                    },
                    ["footer"] = {
                        ["text"] = "Auto Farm Luck Block Game"
                    },
                    ["timestamp"] = DateTime.now():ToIsoDate()
                }
            }
        }
        
        httprequest({
            Url = webhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = http:JSONEncode(data)
        })
    end)
end

-- ==========================================================
-- 🚫 ANIMATION SILENCER & MUTATION FILTER TRACKER
-- ==========================================================
task.spawn(function()
    pcall(function()
        for _, v in pairs(rs:GetDescendants()) do
            if v:IsA("RemoteEvent") and string.lower(v.Name) == "sequenceevent" then
                -- 1. Matikan visual cutscene bawaan game
                if getconnections then
                    for _, conn in pairs(getconnections(v.OnClientEvent)) do
                        conn:Disable()
                    end
                end
                
                -- 2. Pasang penyadap dengan Sistem Filter Mutasi
                v.OnClientEvent:Connect(function(arg1, itemName, arg3)
                    if itemName and type(itemName) == "string" then
                        local lowerName = string.lower(itemName)
                        local isTargetMutation = false
                        
                        -- Cek apakah nama item mengandung kata Lava, Galaxy, atau Rainbow
                        for _, mutation in ipairs(allowedMutations) do
                            if string.find(lowerName, mutation) then
                                isTargetMutation = true
                                break
                            end
                        end
                        
                        -- Hanya tembak ke Webhook kalau item tersebut masuk daftar filter
                        if isTargetMutation then
                            sendToDiscord(itemName)
                        end
                    end
                end)
            end
        end
    end)
end)

-- ==========================================================
-- 🛠️ FUNGSI UTILITAS PENDUKUNG
-- ==========================================================
local function getRemote()
    for _, v in pairs(rs:GetDescendants()) do
        if v:IsA("RemoteEvent") and string.lower(v.Name) == "doorevent" then return v end
    end
    return nil
end

local function hopServer()
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local req = game:HttpGet(url)
        local data = http:JSONDecode(req)
        if data and data.data then
            for _, v in ipairs(data.data) do
                if type(v) == "table" and tonumber(v.playing) ~= nil and tonumber(v.playing) < 2 and v.id ~= game.JobId then
                    tpService:TeleportToPlaceInstance(game.PlaceId, v.id, lp)
                    task.wait(5)
                end
            end
        end
    end)
end

lp.Idled:Connect(function()
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
end)

-- ==========================================================
-- 🖥️ MENU UI RAYFIELD
-- ==========================================================
local library = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local win = library:CreateWindow({Name = "Auto Farm (V36 Filtered)", LoadingTitle = "Setting up filters...", ConfigurationSaving = {Enabled = false}, KeySystem = false})
local tab = win:CreateTab("Main", 4483362458)

tab:CreateToggle({Name = "Auto Farm (Smart Glide)", CurrentValue = true, Callback = function(val) _G.autoFarm = val end})
tab:CreateToggle({Name = "Kirim Mutasi Langka ke Discord", CurrentValue = true, Callback = function(val) _G.useWebhook = val end})
tab:CreateToggle({Name = "Auto Hop (Max 2 Player)", CurrentValue = true, Callback = function(val) _G.serverHop = val end})

-- ==========================================================
-- 🚀 LOOP UTAMA AUTO FARM
-- ==========================================================
task.spawn(function()
    while task.wait(0.5) do
        if _G.serverHop and #players:GetPlayers() > 2 then hopServer() continue end
        if not _G.autoFarm then continue end

        pcall(function()
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- [1] AUTO KLIK START RUN
            local clickedStart = false
            for _, obj in pairs(lp.PlayerGui:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    local txt = string.lower(string.gsub(obj.Text or "", "%s+", ""))
                    local name = string.lower(obj.Name)
                    
                    if string.find(txt, "start") or string.find(txt, "run") or string.find(name, "start") then
                        local btn = obj:IsA("TextButton") and obj or obj:FindFirstAncestorWhichIsA("TextButton") or obj:FindFirstAncestorWhichIsA("ImageButton")
                        if btn and btn.AbsolutePosition.X > 0 then
                            if getconnections then
                                for _, c in pairs(getconnections(btn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                                for _, c in pairs(getconnections(btn.Activated)) do pcall(function() c:Fire() end) end
                            end
                            local ax, ay = btn.AbsolutePosition.X + btn.AbsoluteSize.X/2, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y/2 + 36
                            vim:SendMouseButtonEvent(ax, ay, 0, true, game, 1)
                            task.wait(0.05)
                            vim:SendMouseButtonEvent(ax, ay, 0, false, game, 1)
                            clickedStart = true
                            break 
                        end
                    end
                end
            end

            -- [2] SMART TRANSITION & SAFE GOD MODE
            if clickedStart then
                local lobbyPos = hrp.Position
                local inArena = false
                local timeout = 0
                
                -- Tunggu hingga dilempar masuk ke arena
                repeat
                    task.wait(0.2)
                    timeout = timeout + 0.2
                    char = lp.Character
                    hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - lobbyPos).Magnitude > 50 then
                        inArena = true
                    end
                until inArena or timeout >= 10
                
                if inArena and hrp then
                    task.wait(1) 
                    
                    local remote = getRemote()
                    local goodDoors = {}
                    
                    -- Scan & sortir pintu
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
                                if hasMinus or hasDiv or isDecimal then
                                    -- Matikan pintu jahat
                                    pcall(function()
                                        part.CanTouch = false
                                        part.CanCollide = false
                                    end)
                                elseif (hasPlus or hasMult) then
                                    -- Amankan pintu baik
                                    local num = tonumber(string.match(str, "%d+%.?%d*"))
                                    if num then
                                        local op = hasMult and "mul" or "add"
                                        table.insert(goodDoors, {part = part, num = num, op = op, z = part.Position.Z})
                                    end
                                end
                            end
                        end
                    end

                    -- [3] EKSEKUSI GLIDE & TELEPORT FINISH
                    if remote and #goodDoors > 0 then
                        table.sort(goodDoors, function(a, b) return a.z < b.z end)

                        -- Mode hantu
                        hrp.Anchored = true
                        for _, p in ipairs(char:GetDescendants()) do
                            if p:IsA("BasePart") then p.CanCollide = false end
                        end

                        -- Sapu bersih poin
                        for _, door in ipairs(goodDoors) do
                            local targetPos = Vector3.new(door.part.Position.X, door.part.Position.Y + 3, door.part.Position.Z)
                            local tween = tweenService:Create(hrp, TweenInfo.new(_G.dashSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
                            tween:Play()
                            tween.Completed:Wait() 
                            remote:FireServer(door.num, door.op)
                        end
                        
                        -- Terbang ke Finish (5200)
                        local finishCF = CFrame.new(-122.8, hrp.Position.Y, 5200)
                        local tweenEnd = tweenService:Create(hrp, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {CFrame = finishCF})
                        tweenEnd:Play()
                        tweenEnd.Completed:Wait()

                        -- Normalisasi karakter
                        hrp.Anchored = false
                        hrp.Velocity = Vector3.new(0,0,0)
                        
                        -- Jeda menunggu game mencatat gacha (Webhook jalan di background jika mutasi)
                        task.wait(3.5)
                    end
                end
            end
        end)
    end
end)
