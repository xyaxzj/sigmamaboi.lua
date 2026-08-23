local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui", 10)

_G.autoUseBarbell = true
_G.autoClaimX2 = true

---------------------------------------------------------
-- 1. UBAH MAP JADI POTATO (PUTIH & PLASTIC)
---------------------------------------------------------
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

---------------------------------------------------------
-- 2. MUSNAHKAN EFEK LIGHTING & LANGIT
---------------------------------------------------------
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
for _, v in ipairs(Lighting:GetDescendants()) do
    if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Sky") then
        pcall(function() v:Destroy() end)
    end
end

---------------------------------------------------------
-- 3. HAPUS FOLDER PLOT 1 SAMPAI 5
---------------------------------------------------------
local plotsFolder = workspace:FindFirstChild("Plots")
if plotsFolder then
    for i = 1, 5 do
        local plot = plotsFolder:FindFirstChild("Plot" .. tostring(i))
        if plot then
            pcall(function() plot:Destroy() end)
        end
    end
end

---------------------------------------------------------
-- 4. PEMBANTAIAN PLAYER (REMOVE PLAYER LAIN)
---------------------------------------------------------
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

-- Perangkap Ekstrem: Pantau jika ada karakter player lain yang muncul di Workspace
workspace.ChildAdded:Connect(function(child)
    task.defer(function()
        if child:IsA("Model") and child.Name ~= lp.Name and child:FindFirstChild("Humanoid") then
            pcall(function() child:Destroy() end)
        end
    end)
end)

---------------------------------------------------------
-- 5. NOTIFIKASI
---------------------------------------------------------
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Ultimate Boost Aktif!",
        Text = "Map potato, Plot hilang, dan Player lain gaib total!",
        Duration = 5
    })
end)

---------------------------------------------------------
-- FUNGSI KLIK GAIB (BACKGROUND)
---------------------------------------------------------
local function klikGaib(guiObj)
    -- Daftar event yang biasa dipakai developer untuk tombol
    local targetEvents = {
        "Activated",
        "MouseButton1Click",
        "MouseButton1Down",
        "MouseButton1Up",
        "TouchTap"
    }
    
    for _, eventName in ipairs(targetEvents) do
        -- 1. Metode getconnections (Paling Ampuh & Gaib)
        if getconnections then
            pcall(function()
                if guiObj[eventName] then
                    for _, conn in ipairs(getconnections(guiObj[eventName])) do
                        conn:Fire() -- Eksekusi normal
                        
                        -- Jika Fire() gagal, kita paksa eksekusi langsung script di dalam tombolnya
                        if conn.Function then
                            task.spawn(conn.Function)
                        end
                    end
                end
            end)
        end
        
        -- 2. Metode firesignal (Alternatif executor lain)
        if firesignal then
            pcall(function()
                firesignal(guiObj[eventName])
            end)
        end
    end
end

local tempPauseBarbell = false

---------------------------------------------------------
-- MEKANIK 1: AUTO USE BARBELL
---------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.2) -- Frekuensi cek diubah ke 0.2 detik agar lebih ringan
        if not _G.autoUseBarbell or tempPauseBarbell then continue end
        
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local backpack = lp:FindFirstChild("Backpack")
        
        if not char or not hum then continue end

        local currentTool = char:FindFirstChildOfClass("Tool")
        
        if currentTool and string.match(currentTool.Name, "Barbell$") then
            currentTool:Activate()
            task.wait(0.3) -- Jeda ekstra setelah aktivasi agar tidak terjadi spam paket data ke server
        else
            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") and string.match(tool.Name, "Barbell$") then
                        hum:EquipTool(tool)
                        task.wait(0.2) 
                        tool:Activate()
                        break
                    end
                end
            end
        end
    end
end)

---------------------------------------------------------
-- MEKANIK 2: AUTO CLAIM X2 (REAL-TIME & SUPER CEPAT)
---------------------------------------------------------
local x2Buttons = {}

local function registerX2Button(obj)
    if (obj:IsA("ImageButton") or obj:IsA("ImageLabel")) and string.find(tostring(obj.Image), "138499790425912") then
        if not table.find(x2Buttons, obj) then
            table.insert(x2Buttons, obj)
        end
    end
end

-- Fungsi pembantu untuk cek apakah tombol dan semua parent-nya benar-benar terlihat (visible)
local function isReallyVisible(obj)
    local current = obj
    while current and current:IsA("GuiObject") do
        if not current.Visible then
            return false
        end
        current = current.Parent
    end
    return true
end

-- Lakukan scan awal & pasang event listener untuk UI baru yang di-spawn
task.spawn(function()
    if playerGui then
        -- Scan UI yang sudah terlanjur dimuat
        for _, obj in ipairs(playerGui:GetDescendants()) do
            registerX2Button(obj)
        end
        -- Dengar jika ada UI baru yang ditambahkan secara dinamis
        playerGui.DescendantAdded:Connect(registerX2Button)
    end
end)

-- Loop pemeriksaan super cepat (tiap 0.05 detik) khusus untuk list tombol yang cocok
local lastClaim = 0
task.spawn(function()
    while task.wait(0.05) do
        if not _G.autoClaimX2 then continue end
        
        local now = os.clock()
        if now - lastClaim < 1.0 then continue end -- Cooldown agar tidak klik berulang-ulang dalam 1 detik
        
        for i = #x2Buttons, 1, -1 do
            local obj = x2Buttons[i]
            if not obj:IsDescendantOf(game) then
                table.remove(x2Buttons, i) -- Hapus dari list jika objek sudah hancur
            elseif isReallyVisible(obj) then
                klikGaib(obj)
                lastClaim = now
                break -- Keluar dari iterasi untuk memproses klik
            end
        end
    end
end)

---------------------------------------------------------
-- MEKANIK 3: AUTO TELEPORT WEATHER EVENTS
---------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function teleportWithBarbellPause(targetPart)
    task.spawn(function()
        tempPauseBarbell = true
        
        -- Lepas semua tools yang sedang dipegang
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            hum:UnequipTools()
        end
        
        -- Teleportasi
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if hrp and targetPart and targetPart:IsA("BasePart") then
            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
        end
        
        -- Jeda 1.5 detik sebelum memakai kembali
        task.wait(1.5)
        tempPauseBarbell = false
    end)
end

local function teleportToLuckMachine()
    task.spawn(function()
        local debris = workspace:WaitForChild("Debris", 10)
        if not debris then return end
        
        local luckMachine = debris:WaitForChild("LuckMachine", 15)
        if not luckMachine then return end
        
        local standingPlatforms = luckMachine:WaitForChild("StandingPlatforms", 15)
        if not standingPlatforms then return end
        
        -- Cari platform 1, 2, atau 3 secara berurutan
        local targetPart = standingPlatforms:WaitForChild("1", 5) 
            or standingPlatforms:WaitForChild("2", 5) 
            or standingPlatforms:WaitForChild("3", 5)
            
        if targetPart and targetPart:IsA("BasePart") then
            teleportWithBarbellPause(targetPart)
        end
    end)
end

local function teleportToGymMachine()
    task.spawn(function()
        local debris = workspace:WaitForChild("Debris", 10)
        if not debris then return end
        
        local gymMachine = debris:WaitForChild("GymMachine", 15)
        if not gymMachine then return end
        
        -- Cari part target untuk teleportasi (PrimaryPart atau BasePart pertama)
        local targetPart = gymMachine.PrimaryPart
        if not targetPart then
            for _, child in ipairs(gymMachine:GetDescendants()) do
                if child:IsA("BasePart") then
                    targetPart = child
                    break
                end
            end
        end
        
        if targetPart then
            teleportWithBarbellPause(targetPart)
        end
    end)
end

-- Hubungkan ke Remote Event rev_AddedWeather secara dinamis dengan proteksi pcall
local success, weatherRemote = pcall(function()
    return ReplicatedStorage:WaitForChild("Shared", 10)
        :WaitForChild("Packages", 10)
        :WaitForChild("Network", 10)
        :WaitForChild("rev_AddedWeather", 10)
end)

if success and weatherRemote then
    weatherRemote.OnClientEvent:Connect(function(weatherType, ...)
        if weatherType == "LuckMachine" then
            teleportToLuckMachine()
        elseif weatherType == "LiftMachine" then
            teleportToGymMachine()
        end
    end)
end

---------------------------------------------------------
-- MEKANIK 4: ANTI AFK
---------------------------------------------------------
local VirtualUser = game:GetService("VirtualUser")
lp.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

---------------------------------------------------------
-- MEKANIK 5: AFK BLACKSCREEN (STATS MONITOR)
---------------------------------------------------------
local RunService = game:GetService("RunService")

-- 1. Buat ScreenGui Hitam Fullscreen
local blackScreenGui = Instance.new("ScreenGui")
blackScreenGui.Name = "AFKBlackscreen"
blackScreenGui.IgnoreGuiInset = true
blackScreenGui.Parent = playerGui

local blackFrame = Instance.new("Frame")
blackFrame.Size = UDim2.new(1, 0, 1, 0)
blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
blackFrame.BorderSizePixel = 0
blackFrame.Parent = blackScreenGui

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0.8, 0, 0.4, 0)
infoLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.new(1, 1, 1)
infoLabel.Font = Enum.Font.Code
infoLabel.TextSize = 22
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.TextYAlignment = Enum.TextYAlignment.Center
infoLabel.Text = "Menghitung Statistik AFK..."
infoLabel.Parent = blackFrame

-- 2. Sistem Penghitung FPS
local fps = 0
local frameCount = 0
local nextFpsUpdate = os.clock() + 1

RunService.Heartbeat:Connect(function()
    frameCount = frameCount + 1
    local now = os.clock()
    if now >= nextFpsUpdate then
        fps = frameCount
        frameCount = 0
        nextFpsUpdate = now + 1
    end
end)

-- 3. Fungsi Deteksi Statistik Dinamis (Attributes / Leaderstats / GUI)
local function getStatValue(statName)
    local val = nil
    
    -- A. Coba cari di attributes LocalPlayer
    pcall(function()
        val = lp:GetAttribute(statName) 
            or lp:GetAttribute(statName .. "Level") 
            or lp:GetAttribute(statName .. "Value")
            or lp:GetAttribute(statName .. "Speed")
    end)
    if val then return tostring(val) end
    
    -- B. Coba cari di leaderstats / Stats folder
    pcall(function()
        for _, folder in ipairs(lp:GetChildren()) do
            if folder:IsA("Folder") or folder:IsA("Configuration") then
                local obj = folder:FindFirstChild(statName) 
                    or folder:FindFirstChild(statName .. "Level")
                    or folder:FindFirstChild(statName .. "Speed")
                if obj then
                    val = obj.Value
                    break
                end
            end
        end
    end)
    if val then return tostring(val) end
    
    -- C. Coba cari di GUI di seluruh PlayerGui (rekursif)
    pcall(function()
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "AFKBlackscreen" then
                for _, obj in ipairs(gui:GetDescendants()) do
                    if obj:IsA("TextLabel") then
                        local objName = string.lower(obj.Name)
                        local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""
                        local searchPattern = string.lower(statName)
                        
                        -- Cek apakah nama objek atau nama parent-nya mengandung nama stat yang dicari
                        if string.find(objName, searchPattern) or string.find(parentName, searchPattern) then
                            local text = obj.Text
                            -- Filter out teks belanja/upgrade
                            if text and text ~= "" 
                               and not string.find(string.lower(text), "upgrade") 
                               and not string.find(string.lower(text), "cost") 
                               and not string.find(string.lower(text), "beli") then
                               
                               val = text
                               break
                            end
                        end
                    end
                end
            end
            if val then break end
        end
    end)
    
    return val and tostring(val) or nil
end

local function getKickPower()
    local power = nil
    pcall(function()
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "AFKBlackscreen" then
                local bottomLeft = gui:FindFirstChild("BottomLeft", true)
                if bottomLeft and bottomLeft:IsA("Frame") then
                    local kickLevel = bottomLeft:FindFirstChild("KickLevel")
                    if kickLevel and kickLevel:IsA("Frame") then
                        local textLabel = kickLevel:FindFirstChildOfClass("TextLabel")
                        if textLabel and textLabel.Text ~= "" then
                            power = textLabel.Text
                            break
                        end
                    end
                end
            end
        end
    end)
    return power or "Tidak Terdeteksi"
end

local function getSpeedStat()
    local val = "Tidak Terdeteksi"
    pcall(function()
        local frames = playerGui:WaitForChild("Frames", 10)
        if frames then
            -- 1. Cari exact match "+1 Speed"
            for _, obj in ipairs(frames:GetDescendants()) do
                if obj.Name == "+1 Speed" then
                    local nameLabel = obj:FindFirstChild("NameLabel")
                    if nameLabel then
                        val = nameLabel.Text
                        return val
                    end
                end
            end
            -- 2. Fallback: Cari yang mengandung "1 Speed" atau "1Speed"
            for _, obj in ipairs(frames:GetDescendants()) do
                if string.find(obj.Name, "1 Speed") or string.find(obj.Name, "1Speed") then
                    local nameLabel = obj:FindFirstChild("NameLabel")
                    if nameLabel then
                        val = nameLabel.Text
                        return val
                    end
                end
            end
            -- 3. Fallback Ekstrem: Cari yang mengandung "Speed" dan bertipe ImageLabel
            for _, obj in ipairs(frames:GetDescendants()) do
                if obj:IsA("ImageLabel") and string.find(obj.Name, "Speed") then
                    local nameLabel = obj:FindFirstChild("NameLabel")
                    if nameLabel then
                        val = nameLabel.Text
                        return val
                    end
                end
            end
        end
    end)
    return val
end

local function getRebirthStat()
    local val = "Tidak Terdeteksi"
    pcall(function()
        local frames = playerGui:WaitForChild("Frames", 10)
        if frames then
            -- 1. Cari exact name "Rebirth" -> "RebirthLevel"
            local rebirthFrame = frames:FindFirstChild("Rebirth")
            local rebirthLevel = rebirthFrame and rebirthFrame:FindFirstChild("RebirthLevel")
            if rebirthLevel then
                val = rebirthLevel.Text
                return val
            end
            
            -- 2. Fallback: Cari secara rekursif objek bernama "RebirthLevel"
            for _, obj in ipairs(frames:GetDescendants()) do
                if obj.Name == "RebirthLevel" and obj:IsA("TextLabel") then
                    val = obj.Text
                    return val
                end
            end
            
            -- 3. Fallback Ekstrem: Cari objek mengandung nama "Rebirth" bertipe TextLabel
            for _, obj in ipairs(frames:GetDescendants()) do
                if obj:IsA("TextLabel") and string.find(obj.Name, "Rebirth") then
                    val = obj.Text
                    return val
                end
            end
        end
    end)
    return val
end

-- 4. Loop Update Statistik (FPS & Waktu tiap 1 detik, Kick Power tiap 60 detik)
local startTime = os.time()
local cachedKickPower = "Menghitung..."
local cachedSpeedStat = "Menghitung..."
local cachedRebirthStat = "Menghitung..."
local kickPowerUpdateCounter = 0

local function updateMonitorText()
    local elapsedSeconds = os.time() - startTime
    
    infoLabel.Text = string.format(
        "=== ACCOUNT STATS MONITOR ===\n\n" ..
        "User : %s\n" ..
        "Fps : %d\n" ..
        "Waktu Afk : %d Detik\n" ..
        "%s\n" ..
        "%s\n" ..
        "%s\n\n" ..
        "=============================",
        lp.Name,
        fps,
        elapsedSeconds,
        cachedSpeedStat,
        cachedRebirthStat,
        cachedKickPower
    )
end

task.spawn(function()
    task.wait(2) -- Jeda awal agar UI game selesai dimuat sepenuhnya
    cachedKickPower = getKickPower()
    cachedSpeedStat = getSpeedStat() -- Hanya dibaca sekali di awal eksekusi
    cachedRebirthStat = getRebirthStat() -- Hanya dibaca sekali di awal eksekusi
    updateMonitorText()
    
    while task.wait(1) do
        kickPowerUpdateCounter = kickPowerUpdateCounter + 1
        
        -- Perbarui Kick Power hanya setelah 60 detik (1 menit)
        if kickPowerUpdateCounter >= 60 then
            kickPowerUpdateCounter = 0
            cachedKickPower = getKickPower()
        end
        
        updateMonitorText()
    end
end)
