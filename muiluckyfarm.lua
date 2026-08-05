setfpscap(10)
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui", 10)

_G.autoUseBarbell = true
_G.autoClaimX2 = true

---------------------------------------------------------
-- 1. UBAH MAP JADI POTATO (LANTAI AMAN)
---------------------------------------------------------
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
            v.Color = Color3.new(0.5, 0.5, 0.5) 
            
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("SpecialMesh") then
            v:Destroy()
        end
    end)
end

---------------------------------------------------------
-- 2. HAPUS SEMUA GUI KECUALI TOMBOL X2
---------------------------------------------------------
if playerGui then
    for _, screenGui in ipairs(playerGui:GetChildren()) do
        if screenGui:IsA("ScreenGui") then
            local hasX2 = false
            for _, element in ipairs(screenGui:GetDescendants()) do
                if (element:IsA("ImageButton") or element:IsA("ImageLabel")) and string.find(element.Image or "", "138499790425912") then
                    hasX2 = true
                    break
                end
            end
            if not hasX2 then
                pcall(function() screenGui:Destroy() end)
            end
        end
    end
end

---------------------------------------------------------
-- 3. MUSNAHKAN EFEK LIGHTING & LANGIT
---------------------------------------------------------
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
for _, v in ipairs(Lighting:GetDescendants()) do
    if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Sky") then
        pcall(function() v:Destroy() end)
    end
end

---------------------------------------------------------
-- 4. HAPUS FOLDER PLOT 1 SAMPAI 5
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
-- 5. PEMBANTAIAN PLAYER (ABSOLUT & OTOMATIS)
---------------------------------------------------------
local function musnahkanKarakter(player)
    if player ~= lp then
        -- 1. Hapus jika wujudnya saat ini sudah ada di map
        if player.Character then
            pcall(function() player.Character:Destroy() end)
        end
        
        -- 2. PERANGKAP: Jika dia respawn atau wujudnya baru loading, langsung hapus!
        player.CharacterAdded:Connect(function(char)
            -- Menggunakan task.defer agar dihancurkan di akhir antrean frame saat ini sebelum sempat dirender (mencegah kedipan)
            task.defer(function()
                pcall(function() char:Destroy() end)
            end)
        end)
    end
end

-- Eksekusi ke player yang sudah ada di server sekarang
for _, player in ipairs(Players:GetPlayers()) do
    musnahkanKarakter(player)
end

-- Eksekusi ke player yang baru join ke server nanti
Players.PlayerAdded:Connect(function(player)
    musnahkanKarakter(player)
end)

---------------------------------------------------------
-- 6. NOTIFIKASI
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

---------------------------------------------------------
-- MEKANIK 1: AUTO USE BARBELL
---------------------------------------------------------
task.spawn(function()
    while task.wait(0.1) do
        if not _G.autoUseBarbell then continue end
        
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local backpack = lp:FindFirstChild("Backpack")
        
        if not char or not hum then continue end

        local currentTool = char:FindFirstChildOfClass("Tool")
        
        if currentTool and string.match(currentTool.Name, "Barbell$") then
            currentTool:Activate()
        else
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
            local char = lp.Character or lp.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart", 10)
            if hrp then
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0) -- Teleport di atas platform agar tidak stuck
            end
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
            local char = lp.Character or lp.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart", 10)
            if hrp then
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0) -- Teleport di atas part agar tidak stuck
            end
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
