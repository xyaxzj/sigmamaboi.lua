-- ==========================================================
-- MOCTA TRADE AUTOMATOR V7.2 (NEAT INVENTORY EDITION)
-- ==========================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- // Services & Remotes // --
local networkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")

local f_trade_r = networkFolder:WaitForChild("ref_trade_r") 
local r_trade_i = networkFolder:WaitForChild("rev_trade_i") 

-- // State Variables // --
local TargetPlayerName = ""
local TargetItemName = ""
local StopThreshold = 0
local CurrentQueue = {}
local ItemsProcessed = 0
local IsProcessing = false 
local InsertDelay = 0.15 
local InventoryConnections = {}

-- // Helper Functions // --
local function getAllTools()
    local tools = {}
    local bp = localPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then table.insert(tools, t) end
        end
    end
    return tools
end

local function getToolGUID(tool)
    if not tool then return nil end
    return tool:GetAttribute("guid") or tool:GetAttribute("GUID") or tool:GetAttribute("uid")
end

local function isTradeable(tool)
    return tool and tool:IsA("Tool") and getToolGUID(tool) ~= nil
end

local function getPlayerList()
    local tbl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then table.insert(tbl, p.Name) end
    end
    return tbl
end

local function getFullItemName(tool)
    local displayName = tool.Name
    local mutValue = tool:GetAttribute("Mutation") or tool:GetAttribute("Variant") or (tool:FindFirstChild("Mutation") and tool:FindFirstChild("Mutation").Value)
    if mutValue then displayName = displayName .. " [" .. tostring(mutValue) .. "]" end  
    return displayName
end

local function getInventoryList()
    local inventoryCounts = {}
    for _, tool in ipairs(getAllTools()) do  
        if isTradeable(tool) then
            local displayName = getFullItemName(tool)  
            inventoryCounts[displayName] = (inventoryCounts[displayName] or 0) + 1  
        end
    end  
    local itemsList = {"[ANY ASSET]"}  
    for name, count in pairs(inventoryCounts) do  
        table.insert(itemsList, name .. " | Qty: " .. count)  
    end  
    table.sort(itemsList, function(a, b)  
        if a == "[ANY ASSET]" then return true end
        if b == "[ANY ASSET]" then return false end
        return a < b  
    end)  
    return itemsList
end

local function getBaseName(dropdownString)
    if dropdownString == "[ANY ASSET]" then return "" end
    return string.split(dropdownString, " | Qty:")[1] or dropdownString
end

-- // UI Initialization // --
local Window = Rayfield:CreateWindow({
    Name = "Mocta Trade Automator V7.2",
    LoadingTitle = "Organizing Database...",
    LoadingSubtitle = "Loading Security Systems",
    ConfigurationSaving = { Enabled = false },
    Theme = "DarkBlue"
})

-- ==========================================
-- TAB 1: QUEUE SETUP
-- ==========================================
local TabQueue = Window:CreateTab("1. Queue Setup", 4483362458)

TabQueue:CreateSection("Target Definition")
local PlayerDropdown = TabQueue:CreateDropdown({
    Name = "Pilih Pembeli (Customer)", Options = getPlayerList(), CurrentOption = {""}, MultipleOptions = false,
    Callback = function(Option) TargetPlayerName = Option[1] end,
})

local ItemDropdown = TabQueue:CreateDropdown({
    Name = "Select Brainrot Type", Options = getInventoryList(), CurrentOption = {"[ANY ASSET]"}, MultipleOptions = false,
    Callback = function(Option) TargetItemName = getBaseName(Option[1]) end,
})

TabQueue:CreateInput({
    Name = "Total Quantity (Queue)", PlaceholderText = "Total item yg dijual...", RemoveTextAfterFocusLost = false,
    Callback = function(Text) StopThreshold = tonumber(Text) or 0 end,
})

local QueueStatus = TabQueue:CreateParagraph({Title = "📋 Queue Status", Content = "Queue is empty."})

TabQueue:CreateButton({
    Name = "GENERATE QUEUE",
    Callback = function()
        if TargetPlayerName == "" then return Rayfield:Notify({Title = "Error", Content = "Pilih pembeli dulu!", Duration = 2}) end
        if StopThreshold <= 0 then return Rayfield:Notify({Title = "Error", Content = "Jumlah harus lebih dari 0!", Duration = 2}) end

        CurrentQueue = {}
        ItemsProcessed = 0
        local allTools = getAllTools()  

        for _, tool in ipairs(allTools) do  
            if isTradeable(tool) then  
                local displayName = getFullItemName(tool)  
                if TargetItemName == "" or displayName == TargetItemName then table.insert(CurrentQueue, tool) end  
            end  
        end  

        local finalQueue = {}
        for i = 1, math.min(StopThreshold, #CurrentQueue) do table.insert(finalQueue, CurrentQueue[i]) end
        CurrentQueue = finalQueue

        if #CurrentQueue == 0 then
            return Rayfield:Notify({Title = "Stock Error", Content = "Stok item tidak ditemukan di tas.", Duration = 3})
        end

        QueueStatus:Set({
            Title = "📋 Queue Status", 
            Content = string.format("✅ Ready! %d items queued for %s.\nSilakan ke tab '2. Controller'.", #CurrentQueue, TargetPlayerName)
        })
        Rayfield:Notify({Title = "Queue Ready", Content = "Antrean berhasil dibuat!", Duration = 2})
    end,
})

TabQueue:CreateSection("Queue Reset / Abort")
TabQueue:CreateButton({
    Name = "❌ Batalkan / Reset Antrean",
    Callback = function()
        CurrentQueue = {}
        ItemsProcessed = 0
        IsProcessing = false
        QueueStatus:Set({Title = "📋 Queue Status", Content = "Antrean dibatalkan. Silakan generate ulang."})
    end,
})

-- ==========================================
-- TAB 2: TRADE CONTROLLER
-- ==========================================
local TabControl = Window:CreateTab("2. Controller", 4483362458)

local LiveProgress = TabControl:CreateParagraph({Title = "⚡ Trade Progress", Content = "Sisa Item: 0\nTerkirim: 0"})

local function updateProgressUI()
    LiveProgress:Set({
        Title = "⚡ Trade Progress", 
        Content = string.format("Sisa Item di Antrean: %d\nItem Terkirim: %d", #CurrentQueue, ItemsProcessed)
    })
end

TabControl:CreateSection("PHASE 1: INVITE")
TabControl:CreateButton({
    Name = "▶️ [1] Send Trade Request",
    Callback = function()
        if IsProcessing then return end
        local target = Players:FindFirstChild(TargetPlayerName)
        if target then
            IsProcessing = true
            task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)
            Rayfield:Notify({Title = "Phase 1", Content = "Invite sent!", Duration = 2})
            task.wait(1)
            IsProcessing = false
        else
            Rayfield:Notify({Title = "Target Hilang", Content = "Pembeli tidak ada di server!", Duration = 3})
        end
    end,
})

TabControl:CreateSection("PHASE 2: AUTO-INSERT")
TabControl:CreateSlider({
    Name = "Insert Delay", Range = {0.05, 0.5}, Increment = 0.05, CurrentValue = 0.15,
    Callback = function(Value) InsertDelay = Value end,
})

TabControl:CreateButton({
    Name = "📥 [2] Insert 10 Items from Queue",
    Callback = function()
        if IsProcessing then return end
        if #CurrentQueue == 0 then return Rayfield:Notify({Title = "Done", Content = "Antrean habis!", Duration = 3}) end

        IsProcessing = true
        local batchSize = math.min(10, #CurrentQueue)
        local batch = {}
        
        for i = 1, batchSize do table.insert(batch, table.remove(CurrentQueue, 1)) end

        for _, tool in ipairs(batch) do
            local guid = getToolGUID(tool)
            if guid then
                r_trade_i:FireServer("AddItem", tostring(guid))
                task.wait(InsertDelay) 
            end
        end

        ItemsProcessed = ItemsProcessed + batchSize
        updateProgressUI()
        Rayfield:Notify({Title = "Phase 2", Content = batchSize .. " item masuk!", Duration = 2})
        IsProcessing = false
    end,
})

TabControl:CreateSection("PHASE 3 & 4")
TabControl:CreateButton({
    Name = "✅ [3] Accept Trade (Kiri)",
    Callback = function()
        if IsProcessing then return end
        IsProcessing = true
        r_trade_i:FireServer("Confirm")
        task.wait(0.5)
        IsProcessing = false
    end,
})

TabControl:CreateButton({
    Name = "🚀 [4] Final Confirm (Kanan)",
    Callback = function()
        if IsProcessing then return end
        IsProcessing = true
        r_trade_i:FireServer("Confirm")
        task.wait(1)
        IsProcessing = false
    end,
})

-- ==========================================
-- TAB 3: FULL INVENTORY (REMASTERED)
-- ==========================================
local TabInventory = Window:CreateTab("3. Full Inventory", 4483362458)

local FullInventoryLabel = TabInventory:CreateParagraph({
    Title = "🎒 Database Inventory",
    Content = "Synchronizing data..."
})

function updateInventoryDisplay()
    local inventoryData = {}
    local totalCount = 0
    
    -- Mengumpulkan Data
    for _, tool in pairs(getAllTools()) do  
        if isTradeable(tool) then
            local displayName = getFullItemName(tool)  
            inventoryData[displayName] = (inventoryData[displayName] or 0) + 1  
            totalCount = totalCount + 1  
        end
    end  
    
    local displayString = "Total Tradeable Assets: " .. totalCount .. "\n\n"  
    
    if totalCount == 0 then 
        displayString = displayString .. "Inventory is empty or no tradeable items found." 
    else
        -- Logic Kategorisasi & Kerapian
        local categorizedItems = {}

        for itemName, amount in pairs(inventoryData) do
            local category = "📦 NORMAL / BASE"
            local cleanName = itemName

            -- Deteksi Mutasi untuk Kategori
            local mutStart = string.find(itemName, "%[")
            if mutStart then
                category = "✨ " .. string.upper(string.sub(itemName, mutStart + 1, -2))
                cleanName = string.sub(itemName, 1, mutStart - 2)
            end

            if not categorizedItems[category] then categorizedItems[category] = {} end
            table.insert(categorizedItems[category], {name = cleanName, qty = amount})
        end

        -- Sorting Kategori (Abjad)
        local sortedCategories = {}
        for cat, _ in pairs(categorizedItems) do table.insert(sortedCategories, cat) end
        table.sort(sortedCategories)

        -- Pembangunan UI Text
        for _, cat in ipairs(sortedCategories) do
            displayString = displayString .. "=== " .. cat .. " ===\n"
            
            -- Sorting Item per Kategori (Abjad)
            table.sort(categorizedItems[cat], function(a, b) return a.name < b.name end)
            
            for _, item in ipairs(categorizedItems[cat]) do
                displayString = displayString .. string.format(" • %s  |  Qty: %d\n", item.name, item.qty)
            end
            displayString = displayString .. "\n"
        end
    end
    
    FullInventoryLabel:Set({Title = "🎒 Database Inventory", Content = displayString})
end

TabInventory:CreateButton({
    Name = "🔄 Refresh Inventory Database",
    Callback = function()
        updateInventoryDisplay()
        Rayfield:Notify({Title = "Inventory", Content = "Database updated!", Duration = 2})
    end,
})

-- ==========================================
-- TAB 4: SETTINGS & UTILITIES
-- ==========================================
local TabSettings = Window:CreateTab("4. Settings", 4483362458)

TabSettings:CreateSection("Cinematic Mode")
TabSettings:CreateToggle({
    Name = "Enable Clean UI Mode", CurrentValue = false,
    Callback = function(Value)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not Value)
        local pGui = localPlayer:WaitForChild("PlayerGui")  
        for _, gui in ipairs(pGui:GetChildren()) do  
            if gui:IsA("ScreenGui") and gui.Name ~= "Rayfield" then  
                if Value then gui:SetAttribute("WasEnabled", gui.Enabled); gui.Enabled = false  
                else gui.Enabled = gui:GetAttribute("WasEnabled") or true end  
            end  
        end  
    end,
})

TabSettings:CreateSection("Synchronization")
TabSettings:CreateButton({
    Name = "Sync All Dropdowns",
    Callback = function()
        PlayerDropdown:Refresh(getPlayerList())
        ItemDropdown:Refresh(getInventoryList())
    end,
})

-- Initialize Inventory Auto-Sync
local function connect()
    local backpack = localPlayer:WaitForChild("Backpack")
    table.insert(InventoryConnections, backpack.ChildAdded:Connect(updateInventoryDisplay))
    table.insert(InventoryConnections, backpack.ChildRemoved:Connect(updateInventoryDisplay))
    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    table.insert(InventoryConnections, char.ChildAdded:Connect(updateInventoryDisplay))
    table.insert(InventoryConnections, char.ChildRemoved:Connect(updateInventoryDisplay))
    localPlayer.CharacterAdded:Connect(function(newChar)
        table.insert(InventoryConnections, newChar.ChildAdded:Connect(updateInventoryDisplay))
        table.insert(InventoryConnections, newChar.ChildRemoved:Connect(updateInventoryDisplay))
    end)
    task.wait(0.5)
    updateInventoryDisplay()
end
connect()
