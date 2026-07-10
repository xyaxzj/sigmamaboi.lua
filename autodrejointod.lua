if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

-- =============================================
-- ⚙️ KONFIGURASI 
-- =============================================
_G.autoFarm = true              
_G.animDelay = 7.3              

-- =============================================
-- 🧠 VARIABEL OTAK UTAMA (STATE MACHINE)
-- =============================================
_G.targetAction = "Idle"
_G.lastAction = "Idle"
_G.nextAction = "Idle"          
_G.stateTimer = 0               
_G.globalStuckTimer = 0         
_G.targetItemPos = nil          
local safeZone = Vector3.new(689, 3, 236)

-- =============================================
-- 📊 SETUP MINI HUD (HANYA BATTLEPASS TRACKER)
-- =============================================
local guiParent = pcall(function() return CoreGui end) and CoreGui or lp:WaitForChild("PlayerGui")
local oldGui = guiParent:FindFirstChild("BP_Tracker_HUD")
if oldGui then oldGui:Destroy() end 

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BP_Tracker_HUD"
screenGui.Parent = guiParent

-- Label Widget Mungil di Atas Layar
local bpLabel = Instance.new("TextLabel")
bpLabel.Size = UDim2.new(0, 350, 0, 40)
bpLabel.Position = UDim2.new(0.5, -175, 0, 20)
bpLabel.BackgroundTransparency = 0.4 -- Agak tembus pandang
bpLabel.BackgroundColor3 = Color3.new(0, 0, 0)
bpLabel.TextColor3 = Color3.new(0, 1, 1) -- Warna Cyan / Biru Muda
bpLabel.TextSize = 20
bpLabel.Font = Enum.Font.Code
bpLabel.Text = lp.Name .. " | BP EXP: Mencari data..."
bpLabel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = bpLabel

-- MESIN PENCARI GUI BATTLEPASS
local targetAmountLabel = nil
local function findBPLabel()
    if targetAmountLabel and targetAmountLabel.Parent then return targetAmountLabel end
    
    local pGui = lp:FindFirstChild("PlayerGui")
    if pGui then
        for _, v in pairs(pGui:GetDescendants()) do
            if v:IsA("Frame") and v.Name == "XPSection" then
                local amountText = v:FindFirstChild("Amount")
                if amountText and amountText:IsA("TextLabel") then
                    targetAmountLabel = amountText
                    return targetAmountLabel
                end
            end
        end
    end
    return nil
end

-- LOOP PEMBARUAN TEKS (Tiap 1 Detik)
task.spawn(function()
    while task.wait(1) do
        if not bpLabel or not bpLabel.Parent then break end
        
        local currentBPText = findBPLabel()
        if currentBPText then
            bpLabel.Text = lp.Name .. " | BP EXP: " .. tostring(currentBPText.Text)
        else
            bpLabel.Text = lp.Name .. " | BP EXP: Menunggu UI..."
        end
    end
end)

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
for _, r in pairs(ReplicatedStorage:GetDescendants()) do
    if r:IsA("RemoteEvent") and string.find(r.Name, "rev_KickEvent") and not string.find(r.Name, "Ended") then
        kickRemote = r; break
    end
end

-- =============================================
-- 👁️ SENSOR 3D
-- =============================================
workspace.DescendantAdded:Connect(function(obj)
    if not _G.autoFarm or _G.targetAction ~= "WaitingForDrop" then return end
    if not obj:IsA("Model") then return end 
    
    task.wait(0.05) 
    if _G.targetAction ~= "WaitingForDrop" then return end 

    local mutation = obj:GetAttribute("Mutation")
    if mutation ~= nil then 
        local itemPos = obj:GetPivot().Position
        if (itemPos - safeZone).Magnitude < 60 then
            
            _G.targetAction = "PlayingAnim"
            
            if mutation == "None" or mutation == "" then
                _G.nextAction = "Die"
            else
                _G.targetItemPos = itemPos
                _G.nextAction = "WalkToItem"
            end
            
        end
    end
end)

-- =============================================
-- ⚙️ MAIN LOOP (STATE MACHINE DENGAN JEDA 4s)
-- =============================================
task.spawn(function()
    while task.wait(0.2) do
        if not _G.autoFarm then continue end

        local char = lp.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not hum or not hrp then continue end 

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
            _G.globalStuckTimer = _G.globalStuckTimer + 0.2
            _G.stateTimer = _G.stateTimer + 0.2 
            
            if _G.globalStuckTimer >= 25 then
                _G.globalStuckTimer = 0
                _G.targetAction = "WaitingRespawn"
                hum.Health = 0 
                continue
            end
        end

        local distToSafeZone = (hrp.Position - safeZone).Magnitude

        -- [ FASE 1: IDLE / NENDANG (JEDA 4 DETIK GANDA) ]
        if _G.targetAction == "Idle" then
            if distToSafeZone > 10 then
                -- Jeda 4 detik setelah respawn sebelum teleport
                if _G.stateTimer >= 3 then
                    hrp.CFrame = CFrame.new(safeZone)
                    task.wait(0.1) 
                    _G.stateTimer = 0 
                end
            else
                -- Jeda 4 detik di safe zone sebelum nendang
                if _G.stateTimer >= 3 then
                    if kickRemote then kickRemote:FireServer(1, 1) end
                    _G.targetAction = "WaitingForDrop"
                end
            end

        -- [ FASE 2: NUNGGU DROP ]
        elseif _G.targetAction == "WaitingForDrop" then
            if _G.stateTimer > 15 then
                _G.targetAction = "Idle"
            end

        -- [ FASE 3: NUNGGU ANIMASI 7.3s ]
        elseif _G.targetAction == "PlayingAnim" then
            if _G.stateTimer >= _G.animDelay then
                _G.targetAction = _G.nextAction
            end

        -- [ FASE 4: JALAN MENGAMBIL ITEM MUTASI ]
        elseif _G.targetAction == "WalkToItem" then
            if _G.targetItemPos then
                hum:MoveTo(_G.targetItemPos)
                if (hrp.Position - _G.targetItemPos).Magnitude < 8 then 
                    _G.targetAction = "WalkToSafeZone"
                end
            else
                _G.targetAction = "Idle" 
            end

        -- [ FASE 5: JALAN BALIK KE SAFE ZONE ]
        elseif _G.targetAction == "WalkToSafeZone" then
            hum:MoveTo(safeZone)
            if distToSafeZone < 8 then
                _G.targetAction = "Idle" 
            end

        -- [ FASE 6: BUNUH DIRI (AMPAS) ]
        elseif _G.targetAction == "Die" then
            hum.Health = 0
            _G.targetAction = "WaitingRespawn" 
        end
    end
end)
