-- =========================================================
-- CLEANUP THREAD & UI LAMA
-- =========================================================
if getgenv().CancelAutoFarm then getgenv().CancelAutoFarm() end
local scriptId = tick()
getgenv().CurrentAutoFarmID = scriptId

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("RGBAutoFarmUI") then
    PlayerGui.RGBAutoFarmUI:Destroy()
end

-- Built-in Anti-AFK System
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
        warn("⚡ Sigma Hub: Anti-AFK memicu stimulasi input virtual. Timer idle telah di-reset!")
    end)
end)

-- Configuration Variables
local isAutoFarmActive = false
local currentStageIndex = 1
local stopAtStage = 20
local heightOffset = 15
local lootDelay = 0.12
local autoEquipWeaponEnabled = false
local stageStartTime = 0

local autoRebirthActive = false
local rebirthInterval = 5
local autoSellActive = false
local sellInterval = 30
local broomSkipEnabled = false
local lootOnlyAtStopStage = true 
local MAX_STAGE_ITEMS = 9 
local stageLootCount = 0 
local currentLockTarget = nil

-- Remote Setup
local netRemoteEvent = nil
local netRemoteFunction = nil
pcall(function()
    netRemoteEvent = ReplicatedStorage.Msg.RemoteEvent.NetWorkRemoteEvent
    netRemoteFunction = ReplicatedStorage.Msg.RemoteFunction.NetWorkRemoteFunction
end)

-- =============================================
-- 🎨 LOAD SIGMA UI LIBRARY V4
-- =============================================
local Library = nil
local getSuccess, getErr = pcall(function()
    Library = loadstring(game:HttpGet("https://github.com/xyaxzj/sigmamaboi.lua/raw/main/NcHO.lua"))()
end)

if not getSuccess or not Library then
    pcall(function()
        if readfile and isfile and isfile("UI sigma.lua") then
            Library = loadstring(readfile("UI sigma.lua"))()
        end
    end)
end

if not Library then
    error("Gagal memuat Sigma UI Library! Pastikan executor Anda terhubung ke internet.")
end

local Window = Library:CreateWindow({
    Name       = 'Sigma Hub | Magic Loot',
    Footer     = 'discord.gg/sigma | v4.0',
    LogoText   = '⚡',
    ConfigName = 'SigmaHub_MagicLoot',
    ToggleKey  = Enum.KeyCode.RightShift,
    Watermark  = false,
})

-- TAB 1: MAIN FUNCTION
local MainTab = Window:MakeTab("⚡")
local FarmSec = MainTab:AddSection("Auto Farm Setup")

FarmSec:AddToggle({ Name = "ON / OFF Auto Farm", Default = isAutoFarmActive }, function(v)
    isAutoFarmActive = v
    if isAutoFarmActive then
        stageLootCount = 0
        logToScreen("⚡ Auto Farm AKTIF!")
    else
        currentLockTarget = nil
        logToScreen("🛑 Auto Farm MATI!")
    end
end)

FarmSec:AddToggle({ Name = "Loot Only at Stop Stage", Default = lootOnlyAtStopStage }, function(v)
    lootOnlyAtStopStage = v
end)

FarmSec:AddSlider({ Name = "Stop at Stage", Min = 1, Max = 50, Default = stopAtStage, Step = 1 }, function(v)
    stopAtStage = v
end)

FarmSec:AddToggle({ Name = "Broom Skip to Stage 13 (Beta)", Default = broomSkipEnabled }, function(v)
    broomSkipEnabled = v
end)

-- TAB 2: ADVANCED SETTINGS
local AdvTab = Window:MakeTab("⚙️")
local AdvSec = AdvTab:AddSection("Advanced Settings")

AdvSec:AddSlider({ Name = "Height Offset (Studs)", Min = 5, Max = 35, Default = heightOffset, Step = 1 }, function(v)
    heightOffset = v
end)

AdvSec:AddSlider({ Name = "Loot Delay (Seconds)", Min = 0.01, Max = 0.5, Default = lootDelay, Step = 0.01 }, function(v)
    lootDelay = v
end)

AdvSec:AddToggle({ Name = "Auto Equip Weapon", Default = autoEquipWeaponEnabled }, function(v)
    autoEquipWeaponEnabled = v
end)

local UtilSec = AdvTab:AddSection("Utility Loops")

UtilSec:AddToggle({ Name = "Auto Rebirth", Default = autoRebirthActive }, function(v)
    autoRebirthActive = v
    logToScreen(v and "✨ Auto Rebirth AKTIF!" or "💤 Auto Rebirth MATI!")
end)

local rebirthInput = UtilSec:AddInput({ Name = "Rebirth Interval (Seconds):", Placeholder = "Enter seconds..." }, function(v)
    local n = tonumber(v)
    if n and n > 0 then
        rebirthInterval = n
        logToScreen(string.format("⏱️ Jeda Rebirth diubah ke %d detik", n))
    end
end)
rebirthInput:Set("5")

UtilSec:AddToggle({ Name = "Auto Sell", Default = autoSellActive }, function(v)
    autoSellActive = v
    logToScreen(v and "💰 Auto Sell Materials AKTIF!" or "💤 Auto Sell Materials MATI!")
end)

local sellInput = UtilSec:AddInput({ Name = "Sell Interval (Seconds):", Placeholder = "Enter seconds..." }, function(v)
    local n = tonumber(v)
    if n and n > 0 then
        sellInterval = n
        logToScreen(string.format("⏱️ Jeda Auto Sell diubah ke %d detik", n))
    end
end)
sellInput:Set("30")

-- SECTION: MONITOR
local StatsSec = MainTab:AddSection("Stats Monitor")
local monitorPara = StatsSec:AddParagraph("📊 Status & Inventory", "Initializing...")

-- TAB 3: LIVE ACTIVITY LOGS
local LogTab = Window:MakeTab("📋")
local LogSec = LogTab:AddSection("Live Activity Logs")
local logPara = LogSec:AddParagraph("📜 Activity Log", "Ready...\nWaiting for activity...")

-- TAB 4: INVENTORY MANAGER
local InvTab = Window:MakeTab("🎒")
local InvSec = InvTab:AddSection("Backpack Inventory")
local InvStatus = InvSec:AddParagraph("Items in Backpack", "Loading inventory...")

-- TAB 5: CONFIG MANAGER
local CfgTab = Window:MakeTab("💾")
CfgTab:AddConfigManager()

-- Logging System
local liveLogs = {}
local MAX_LOG_LINES = 15

local function logToScreen(msg)
    local timestamp = os.date("%H:%M:%S")
    table.insert(liveLogs, 1, string.format("[%s] %s", timestamp, msg))
    if #liveLogs > MAX_LOG_LINES then
        table.remove(liveLogs)
    end
    if logPara then
        pcall(function()
            logPara:Set("📜 Activity Log", table.concat(liveLogs, "\n"))
        end)
    end
end

local function logSpawnedEnemies(stage, enemies)
    local counts = {}
    for _, e in ipairs(enemies) do
        local name = e.Model and e.Model.Name or "Monster"
        counts[name] = (counts[name] or 0) + 1
    end
    local names = {}
    for name, count in pairs(counts) do
        table.insert(names, string.format("%s (x%d)", name, count))
    end
    logToScreen(string.format("👾 Stage %d: Spawned %s", stage, table.concat(names, ", ")))
end

Library:Notify({ Title = 'Sigma UI Loaded', Content = 'Magic Loot Auto Farm ready!', Type = 'Success' })

-- =========================================================
-- STATUS MONITOR UPDATE SYSTEM
-- =========================================================
local currentStatus = "Idle | Ready"
local function updateStatusMonitor(newStatus)
    if newStatus then
        currentStatus = newStatus
    end
    
    local bagText = ""
    if stageLootCount >= MAX_STAGE_ITEMS then
        bagText = string.format("🎒 Tas Stage: %d / %d (PENUH!)", stageLootCount, MAX_STAGE_ITEMS)
    else
        bagText = string.format("🎒 Tas Stage: %d / %d Item", stageLootCount, MAX_STAGE_ITEMS)
    end
    
    monitorPara:Set(
        "📊 Status & Inventory",
        string.format("Status: %s\n%s\nCurrent Stage: %d / %d\nHeight Offset: %d studs", currentStatus, bagText, currentStageIndex, stopAtStage, heightOffset)
    )
end

-- =========================================================
-- BACKPACK INVENTORY SYSTEM
-- =========================================================
local function getBackpackTools()
    local tools = {}
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                table.insert(tools, t)
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then
                table.insert(tools, t)
            end
        end
    end
    return tools
end

local function getToolDisplayName(tool)
    local displayName = tool.Name
    local lvlValue = tool:GetAttribute("Level") or tool:GetAttribute("level") or tool:GetAttribute("Lvl")
    if not lvlValue then
        local lvlObj = tool:FindFirstChild("Level") or tool:FindFirstChild("level") or tool:FindFirstChild("Lvl")
        if lvlObj and (lvlObj:IsA("IntValue") or lvlObj:IsA("NumberValue") or lvlObj:IsA("StringValue")) then
            lvlValue = lvlObj.Value
        end
    end
    if lvlValue then displayName = displayName .. " (Lv." .. tostring(lvlValue) .. ")" end
    
    local rarity = tool:GetAttribute("Rarity") or tool:GetAttribute("rarity")
    if not rarity then
        local rarObj = tool:FindFirstChild("Rarity") or tool:FindFirstChild("rarity")
        if rarObj and rarObj:IsA("StringValue") then
            rarity = rarObj.Value
        end
    end
    if rarity then displayName = displayName .. " | " .. tostring(rarity) end
    
    return displayName
end

local function updateInventoryList()
    local tools = getBackpackTools()
    if #tools == 0 then
        InvStatus:Set("Items in Backpack", "Your backpack is empty.")
        return
    end
    
    local toolCounts = {}
    for _, t in ipairs(tools) do
        local dispName = getToolDisplayName(t)
        toolCounts[dispName] = (toolCounts[dispName] or 0) + 1
    end
    
    local lines = {}
    for name, count in pairs(toolCounts) do
        table.insert(lines, string.format("• %s (x%d)", name, count))
    end
    table.sort(lines)
    
    InvStatus:Set("Items in Backpack", table.concat(lines, "\n") .. "\n\nTotal Items: " .. #tools)
end

-- Task Pembaruan Status & Inventory Real-Time
local running = true
task.spawn(function()
    while running and getgenv().CurrentAutoFarmID == scriptId do
        pcall(updateStatusMonitor)
        task.wait(0.25)
    end
end)

task.spawn(function()
    while running and getgenv().CurrentAutoFarmID == scriptId do
        pcall(updateInventoryList)
        task.wait(1.5)
    end
end)

-- Fungsi Auto Sell Materials (1-1000 IDs)
local function performAutoSell()
    if not netRemoteFunction then return end
    pcall(function()
        local onlyIDList = {}
        for i = 1, 1000 do
            table.insert(onlyIDList, i)
        end
        netRemoteFunction:InvokeServer("出售材料", {
            ["onlyIDList"] = onlyIDList
        })
        logToScreen("💰 Auto Sell: Berhasil menjual material (ID 1-1000)!")
    end)
end

-- Auto Rebirth Loop
task.spawn(function()
    while running and getgenv().CurrentAutoFarmID == scriptId do
        if autoRebirthActive then
            if netRemoteFunction then
                local success = pcall(function()
                    netRemoteFunction:InvokeServer("玩家晋升")
                end)
                if success then
                    logToScreen("✨ Auto Rebirth: Karakter berhasil naik tingkatan!")
                end
            end
        end
        task.wait(rebirthInterval)
    end
end)

-- Auto Sell Loop
task.spawn(function()
    while running and getgenv().CurrentAutoFarmID == scriptId do
        if autoSellActive then
            performAutoSell()
        end
        task.wait(sellInterval)
    end
end)

-- =========================================================
-- FUNGSI PEMBANTU LAINNYA
-- =========================================================
local function checkPlayerAlive()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function autoEquipWeapon()
    if not autoEquipWeaponEnabled then return end
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if humanoid and backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                pcall(function()
                    humanoid:EquipTool(tool)
                end)
            end
        end
    end
end

local function returnToBaseAndReset()
    currentLockTarget = nil
    logToScreen("🎒 Tas Penuh! Mengirim request pulang ke Base...")
    updateStatusMonitor("🎒 Tas Penuh (8/8)! Pulang ke Base...")
    if netRemoteEvent then
        pcall(function()
            netRemoteEvent:FireServer("\xE5\x89\xAF\xE6\x9C\xAC\xE5\x9B\x9E\xE5\x9F\x8E")
        end)
    end
    task.wait(2.5) -- Waktu jeda agar teleport balik base & auto-claim selesai
    
    -- Jual material otomatis saat kembali ke base
    performAutoSell()
    
    stageLootCount = 0
    logToScreen("🔄 Memulai kembali Auto Farm dari Stage 1...")
    updateStatusMonitor("🔄 Re-starting dari Stage 1...")
    task.wait(1)
end

-- =========================================================
-- SMOOTH TELEPORT LOCK FRAME SYSTEM (HEARTBEAT BINDED)
-- =========================================================
RunService.Heartbeat:Connect(function()
    if isAutoFarmActive and running and getgenv().CurrentAutoFarmID == scriptId then
        if currentLockTarget and currentLockTarget.Parent and checkPlayerAlive() then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local destCFrame = CFrame.new(currentLockTarget.Position + Vector3.new(0, heightOffset, 0))
                    hrp.CFrame = destCFrame
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end)
        end
    end
end)

local function getActiveEnemies()
    local enemies = {}
    local foldersToSearch = {
        workspace:FindFirstChild("LocalMonster"),
        workspace:FindFirstChild("Monster")
    }

    for _, folder in ipairs(foldersToSearch) do
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Model") and not obj.Name:find("DeathFx") then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    local hpVal = obj:FindFirstChild("HP") or obj:FindFirstChild("Health")
                    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")

                    local currentHP = 0
                    local maxHP = 100
                    local isAlive = false

                    if hum then
                        currentHP = hum.Health
                        maxHP = hum.MaxHealth
                        isAlive = hum.Health > 0
                    elseif hpVal then
                        currentHP = hpVal.Value
                        isAlive = hpVal.Value > 0
                    end

                    if isAlive and hrp then
                        table.insert(enemies, {
                            Model = obj,
                            HRP = hrp,
                            HP = currentHP,
                            MaxHP = maxHP
                        })
                    end
                end
            end
        end
    end
    return enemies
end

-- =========================================================
-- AUTO LOOT PRESISI + INTERRUPT RESPRAWN MUSUH
-- =========================================================
local function sweepStageDrops(stage)
    if stageLootCount >= MAX_STAGE_ITEMS then
        return
    end

    local dropsFolder = workspace:FindFirstChild("DropsClient")
    if not dropsFolder then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local startPos = hrp.Position -- Catat posisi awal karakter di stage sebelum looting dimulai

    local prompts = {}
    for _, prompt in ipairs(dropsFolder:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Parent then
            table.insert(prompts, prompt)
        end
    end

    for _, prompt in ipairs(prompts) do
        -- Cek musuh: jika musuh respawn, hentikan looting
        local enemies = getActiveEnemies()
        if #enemies > 0 then
            currentLockTarget = enemies[1].HRP
            break
        end

        if stageLootCount >= MAX_STAGE_ITEMS then
            break
        end

        if prompt and prompt.Parent then
            local targetPart = prompt.Parent
            if not targetPart:IsA("BasePart") then
                targetPart = prompt:FindFirstAncestorOfClass("BasePart")
            end

            if targetPart then
                -- Cek apakah jarak dari drop ke posisi awal stage lebih dari 100 stud (artinya itu drop dari stage lain)
                local dist = (targetPart.Position - startPos).Magnitude
                if dist > 100 then
                    continue -- Lewati drop dari stage sebelumnya
                end

                currentLockTarget = nil -- Lepaskan lock sementara untuk mengambil loot
                if checkPlayerAlive() then
                    hrp.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 2, 0))
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.08)
                end
            end

            if not checkPlayerAlive() or #getActiveEnemies() > 0 then break end

            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = 99999

            local dropName = prompt.Parent and prompt.Parent.Name or "Unknown Item"
            local success = pcall(function()
                if fireproximityprompt then
                    fireproximityprompt(prompt, 0, true)
                else
                    prompt:InputHoldBegin()
                    prompt:InputHoldEnd()
                end
            end)

            if success then
                stageLootCount = stageLootCount + 1
                logToScreen(string.format("🎁 Looted: %s (Tas: %d/%d)", dropName, stageLootCount, MAX_STAGE_ITEMS))
            end

            task.wait(lootDelay)
        end
    end
end

-- =========================================================
-- MAIN AUTO FARM LOOP
-- =========================================================
getgenv().CancelAutoFarm = function()
    running = false
    currentLockTarget = nil
end

task.spawn(function()
    while running and getgenv().CurrentAutoFarmID == scriptId do
        if isAutoFarmActive then
            local startStage = 1
            if broomSkipEnabled and stopAtStage >= 13 then
                startStage = 13
                logToScreen("🧹 Broom Skip: Melompati dungeon langsung ke Stage 13!")
                updateStatusMonitor("⚡ Melompati Stage ke 13 (Broom)...")
                if netRemoteEvent then
                    pcall(function()
                        netRemoteEvent:FireServer("关卡跳关请求", 13)
                    end)
                end
                task.wait(1.5)
            end

            for stage = startStage, stopAtStage do
                if not isAutoFarmActive or not running then break end

                -- Cek kondisi hidup player
                while isAutoFarmActive and running and not checkPlayerAlive() do
                    currentLockTarget = nil
                    updateStatusMonitor("Waiting for Respawn...")
                    task.wait(1)
                end

                -- CEK SEBELUM START STAGE: Jika tas penuh, pulang base & restart dari Stage 1
                if stageLootCount >= MAX_STAGE_ITEMS then
                    returnToBaseAndReset()
                    break
                end
                
                currentStageIndex = stage
                updateStatusMonitor(string.format("Memicu Stage %d...", stage))

                if netRemoteEvent then
                    pcall(function()
                        netRemoteEvent:FireServer("\xE5\x89\xAF\xE6\x9C\xAC\xE5\x85\xB3\xE5\x8D\xA1\xE5\x88\xB7\xE6\x80\xAA", stage)
                        netRemoteEvent:FireServer("\xE8\xAE\xAD\xE7\xBB\x83\xE5\x9C\xBA\xE5\x8C\xBA\xE5\x9F\x9F\xE6\x9B\xB4\xE6\x96\xB0", {})
                    end)
                end

                local waitForSpawn = 0
                local loggedSpawn = false
                while isAutoFarmActive and running and waitForSpawn < 35 do
                    local enemies = getActiveEnemies()
                    if #enemies > 0 then 
                        if not loggedSpawn then
                            logSpawnedEnemies(stage, enemies)
                            loggedSpawn = true
                        end
                        break 
                    end
                    updateStatusMonitor(string.format("Menunggu Monster Stage %d (%ds)...", stage, 35 - waitForSpawn))
                    task.wait(1)
                    waitForSpawn = waitForSpawn + 1
                end

                local stageStartTime = tick()

                while isAutoFarmActive and running and checkPlayerAlive() do
                    autoEquipWeapon()
                    local enemies = getActiveEnemies()

                    if #enemies > 0 then
                        local target = enemies[1]
                        local hpText = target.MaxHP > 0 and math.floor((target.HP / target.MaxHP) * 100) .. "%" or tostring(target.HP)
                        updateStatusMonitor(string.format("Stage %d/%d | Musuh: %d | HP: %s", stage, stopAtStage, #enemies, hpText))

                        currentLockTarget = target.HRP
                    else
                        currentLockTarget = nil
                        updateStatusMonitor(string.format("Monster Habis! Melakukan Looting Stage %d...", stage))
                        
                        local canLoot = false
                        if lootOnlyAtStopStage then
                            if stage == stopAtStage then canLoot = true end
                        else
                            canLoot = true
                        end

                        if canLoot then 
                            sweepStageDrops(stage)
                        end

                        task.wait(0.3)
                        break
                    end

                    if tick() - stageStartTime > 600 then break end
                    task.wait(0.12)
                end

                -- CEK SETELAH LOOTING: Jika tas penuh, pulang base & restart dari Stage 1
                if stageLootCount >= MAX_STAGE_ITEMS then
                    returnToBaseAndReset()
                    break
                end

                -- STAGE TARGET: REPEAT LOOP MUSUH & LOOTING
                if stage == stopAtStage then
                    print(string.format("🔄 Mencapai Stage %d! Mode Infinite Loop Aktif...", stopAtStage))
                    logToScreen(string.format("🔄 Mencapai Stage %d! Mode Infinite Loop Aktif...", stopAtStage))
                    
                    local enemiesWereAlive = false
                    while isAutoFarmActive and running do
                        while isAutoFarmActive and running and not checkPlayerAlive() do
                            currentLockTarget = nil
                            updateStatusMonitor("Waiting for Respawn...")
                            task.wait(1)
                        end

                        autoEquipWeapon()
                        local enemies = getActiveEnemies()

                        if #enemies > 0 then
                            if not enemiesWereAlive then
                                logSpawnedEnemies(stopAtStage, enemies)
                                enemiesWereAlive = true
                            end
                            local target = enemies[1]
                            local hpText = target.MaxHP > 0 and math.floor((target.HP / target.MaxHP) * 100) .. "%" or tostring(target.HP)
                            updateStatusMonitor(string.format("Stage %d (Loop) | Musuh: %d | HP: %s", stopAtStage, #enemies, hpText))

                            currentLockTarget = target.HRP
                        else
                            enemiesWereAlive = false
                            currentLockTarget = nil
                            updateStatusMonitor(string.format("Stage %d: Menunggu Respawn / Looting...", stopAtStage))
                            sweepStageDrops(stopAtStage)

                            -- Jika tas penuh saat di stopAtStage loop
                            if stageLootCount >= MAX_STAGE_ITEMS then
                                returnToBaseAndReset()
                                break
                            end
                        end

                        task.wait(0.12)
                    end
                    break
                end
            end
        else
            currentLockTarget = nil
            task.wait(0.3)
        end
    end
end)
