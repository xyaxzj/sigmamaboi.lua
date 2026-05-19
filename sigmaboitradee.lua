-- ==========================================================
-- MOCTA TRADE AUTOMATOR V15.3 (BACON EVENT EDITION)
-- ==========================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- // Services & Remotes // --
local networkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")
local f_trade_r = networkFolder:WaitForChild("ref_trade_r") 
local r_trade_i = networkFolder:WaitForChild("rev_trade_i") 

-- // State Variables // --
local TargetPlayerName = ""
local ShoppingCart = {} 
local CurrentQueue = {}
local ItemsProcessed = 0
local IsProcessing = false 
local AutoLoopEnabled = false
local AutoReceiverEnabled = false
local InsertDelay = 0.3 
local InventoryConnections = {}

-- Daftar Bacon Event Materials
local BaconEventItems = {
    ["Chicleteira Bicicleteira"] = true,
    ["Agarrini La Palini"] = true,
    ["Trippi Troppi"] = true,
    ["Strawberry Elephant"] = true
}

-- // Helper Functions // --
local function getAllTools()
    local tools = {}
    local bp = localPlayer:FindFirstChild("Backpack")
    if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
    local char = localPlayer.Character
    if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
    return tools
end

local function getToolGUID(tool) return tool and (tool:GetAttribute("guid") or tool:GetAttribute("GUID") or tool:GetAttribute("uid")) end
local function isTradeable(tool) return tool and tool:IsA("Tool") and getToolGUID(tool) ~= nil end
local function getPlayerList()
    local tbl = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= localPlayer then table.insert(tbl, p.Name) end end
    return tbl
end

local function getFullItemName(tool)
    local displayName = tool.Name
    local mutValue = tool:GetAttribute("Mutation") or tool:GetAttribute("Variant") or (tool:FindFirstChild("Mutation") and tool:FindFirstChild("Mutation").Value)
    if mutValue then displayName = displayName .. " [" .. tostring(mutValue) .. "]" end  
    local lvlValue = tool:GetAttribute("Level") or tool:GetAttribute("level") or tool:GetAttribute("Lvl")
    if not lvlValue then
        local lvlObj = tool:FindFirstChild("Level") or tool:FindFirstChild("level") or tool:FindFirstChild("Lvl")
        if lvlObj and (lvlObj:IsA("IntValue") or lvlObj:IsA("NumberValue") or lvlObj:IsA("StringValue")) then lvlValue = lvlObj.Value end
    end
    if lvlValue then displayName = displayName .. " (Lv." .. tostring(lvlValue) .. ")" end
    return displayName
end

local function getRealStock(targetName)
    local count = 0
    for _, tool in ipairs(getAllTools()) do if isTradeable(tool) and getFullItemName(tool) == targetName then count = count + 1 end end
    return count
end

local function isOpponentConfirmed(tradeFrame)
    if not tradeFrame then return false end
    local p2Frame = tradeFrame:FindFirstChild("P2_Frame")
    local p2Confirm = p2Frame and p2Frame:FindFirstChild("Confirmed")
    return p2Confirm and p2Confirm.Visible or false
end

-- // UI // --
local Window = Rayfield:CreateWindow({Name = "Mocta Trade V15.3", LoadingTitle = "Loading Event Data...", ConfigurationSaving = { Enabled = false }, Theme = "DarkBlue"})

-- Tab 1: Queue & Pack Mix
local TabQueue = Window:CreateTab("1. Queue", 4483362458)
local PlayerDropdown = TabQueue:CreateDropdown({Name = "Pilih Pembeli (P2)", Options = getPlayerList(), CurrentOption = {""}, MultipleOptions = false, Callback = function(Option) TargetPlayerName = Option[1] end})

TabQueue:CreateSection("Bacon Event Quick-Trade")
TabQueue:CreateButton({
    Name = "🚀 GENERATE QUEUE: ALL BACON MATERIALS",
    Callback = function()
        if TargetPlayerName == "" then return Rayfield:Notify({Title = "Error", Content = "Pilih pembeli dulu di atas!", Duration = 2}) end
        CurrentQueue = {}
        ItemsProcessed = 0
        local itemsFound = 0
        
        for _, tool in ipairs(getAllTools()) do  
            if isTradeable(tool) then  
                local displayName = getFullItemName(tool)
                local baseNameOnly = string.split(displayName, " [")[1]
                baseNameOnly = string.split(baseNameOnly, " (Lv")[1]
                
                if BaconEventItems[baseNameOnly] or BaconEventItems[displayName] then
                    table.insert(CurrentQueue, tool) 
                    itemsFound = itemsFound + 1
                end  
            end  
        end  
        
        if itemsFound == 0 then
            Rayfield:Notify({Title = "Kosong", Content = "Tidak ada Bacon Materials di tas kamu.", Duration = 3})
        else
            Rayfield:Notify({Title = "Ready", Content = itemsFound .. " Bacon Materials masuk antrean!", Duration = 2})
        end
    end
})

TabQueue:CreateSection("Custom Pack Mix")
local ShoppingCart = {} 
local SelectedMixItem = ""
local SelectedMixQty = 0
local function getBaseName(dropdownString) return string.split(dropdownString, " | Qty:")[1] or dropdownString end

local ItemDropdown = TabQueue:CreateDropdown({Name = "Pilih Item", Options = {"[ANY ASSET]"}, CurrentOption = {"[ANY ASSET]"}, MultipleOptions = false, Callback = function(Option) SelectedMixItem = getBaseName(Option[1]) end})
TabQueue:CreateInput({Name = "Jumlah (Qty)", PlaceholderText = "Berapa banyak?", RemoveTextAfterFocusLost = false, Callback = function(Text) SelectedMixQty = tonumber(Text) or 0 end})
local CartStatus = TabQueue:CreateParagraph({Title = "🛒 Isi Keranjang", Content = "Keranjang kosong."})

local function updateCartDisplay()
    local text = "" local total = 0
    for name, qty in pairs(ShoppingCart) do text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end
    if total == 0 then text = "Keranjang kosong." else text = text .. "\nTotal Item: " .. total end
    CartStatus:Set({Title = "🛒 Isi Keranjang", Content = text})
end

TabQueue:CreateButton({Name = "➕ Tambah Sesuai Qty", Callback = function() if SelectedMixItem ~= "" and SelectedMixItem ~= "[ANY ASSET]" and SelectedMixQty > 0 then local rs = getRealStock(SelectedMixItem) local cur = ShoppingCart[SelectedMixItem] or 0 if cur + SelectedMixQty > rs then ShoppingCart[SelectedMixItem] = rs else ShoppingCart[SelectedMixItem] = cur + SelectedMixQty end updateCartDisplay() end end})
TabQueue:CreateButton({Name = "➕ Tambah MAX", Callback = function() if SelectedMixItem ~= "" and SelectedMixItem ~= "[ANY ASSET]" then ShoppingCart[SelectedMixItem] = getRealStock(SelectedMixItem) updateCartDisplay() end end})
TabQueue:CreateButton({Name = "🗑️ Kosongkan Keranjang", Callback = function() ShoppingCart = {}; updateCartDisplay() end})

TabQueue:CreateButton({Name = "🚀 GENERATE QUEUE DARI KERANJANG", Callback = function() 
    if TargetPlayerName == "" then return Rayfield:Notify({Title = "Error", Content = "Pilih pembeli dulu!", Duration = 2}) end
    CurrentQueue = {} ItemsProcessed = 0 local needed = {} for k,v in pairs(ShoppingCart) do needed[k]=v end
    local itemsFound = 0
    for _, tool in ipairs(getAllTools()) do 
        if isTradeable(tool) then 
            local name = getFullItemName(tool) 
            if needed[name] and needed[name] > 0 then table.insert(CurrentQueue, tool) needed[name] = needed[name] - 1 itemsFound = itemsFound + 1 end 
        end 
    end
    Rayfield:Notify({Title = "Ready", Content = itemsFound .. " custom items queued.", Duration = 2})
end})

-- Tab 2: Sender (P1)
local TabControl = Window:CreateTab("2. Sender (P1)", 4483362458)
local function executeSenderBatch()
    if IsProcessing or #CurrentQueue == 0 then return false end
    IsProcessing = true
    local target = Players:FindFirstChild(TargetPlayerName)
    if not target then IsProcessing = false return false end
    task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)
    local tradeFrame = nil
    repeat task.wait(1) tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true) until tradeFrame and tradeFrame.Visible
    local batch = {}
    for i = 1, math.min(10, #CurrentQueue) do table.insert(batch, table.remove(CurrentQueue, 1)) end
    for _, tool in ipairs(batch) do local guid = getToolGUID(tool) if guid then r_trade_i:FireServer("AddItem", tostring(guid)) task.wait(0.3) end end
    task.wait(5.5)
    r_trade_i:FireServer("Confirm")
    task.wait(6.0)
    r_trade_i:FireServer("Confirm")
    IsProcessing = false
end
TabControl:CreateButton({Name = "▶️ RUN 1 BATCH", Callback = function() task.spawn(executeSenderBatch) end})
TabControl:CreateToggle({Name = "🔁 FULL AUTO LOOP (P1)", CurrentValue = false, Callback = function(Value) AutoLoopEnabled = Value if AutoLoopEnabled then task.spawn(function() while AutoLoopEnabled do if #CurrentQueue == 0 then AutoLoopEnabled = false break end executeSenderBatch() task.wait(2.5) end end) end end})

-- Tab 3: Receiver (P2)
local TabReceiver = Window:CreateTab("3. Receiver (P2)", 4483362458)
TabReceiver:CreateToggle({
    Name = "🤖 ENABLE UNIVERSAL AUTO-ACCEPT",
    CurrentValue = false,
    Callback = function(Value)
        AutoReceiverEnabled = Value
        if AutoReceiverEnabled then
            task.spawn(function()
                while AutoReceiverEnabled do
                    local tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
                    if tradeFrame and tradeFrame.Visible then
                        while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                        if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then task.wait(5.5) r_trade_i:FireServer("Confirm") task.wait(1) end
                        while tradeFrame.Visible and isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                        while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                        if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then task.wait(5.5) r_trade_i:FireServer("Confirm") end
                        while tradeFrame.Visible do task.wait(0.5) end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})

-- Tab 4: Inventory
local TabInventory = Window:CreateTab("4. Inventory", 4483362458)
local FullInventoryLabel = TabInventory:CreateParagraph({Title = "🎒 Inventory", Content = "Syncing..."})

function updateInventoryDisplay()
    local inventoryData = {}
    local totalCount = 0
    local rawInventoryList = {}
    
    for _, tool in pairs(getAllTools()) do  
        if isTradeable(tool) then
            local displayName = getFullItemName(tool)  
            inventoryData[displayName] = (inventoryData[displayName] or 0) + 1  
            totalCount = totalCount + 1  
        end
    end  
    
    -- Update Item Dropdown in Tab 1
    local itemsList = {"[ANY ASSET]"}  
    for name, count in pairs(inventoryData) do table.insert(itemsList, name .. " | Qty: " .. count) end  
    table.sort(itemsList, function(a, b) if a == "[ANY ASSET]" then return true end if b == "[ANY ASSET]" then return false end return a < b end)  
    ItemDropdown:Refresh(itemsList)
    
    -- Display
    local displayString = "Total Tradeable Assets: " .. totalCount .. "\n\n"  
    if totalCount == 0 then 
        displayString = displayString .. "Inventory is empty." 
    else
        local categorizedItems = {}
        for itemName, amount in pairs(inventoryData) do
            local category = "📦 NORMAL / BASE"
            local mutMatch = string.match(itemName, "%[(.-)%]")
            
            -- Filter untuk Bacon Event
            local baseNameOnly = string.split(itemName, " [")[1]
            baseNameOnly = string.split(baseNameOnly, " (Lv")[1]
            
            if BaconEventItems[baseNameOnly] or BaconEventItems[itemName] then
                category = "🥓 BACON EVENT MATERIALS"
            elseif mutMatch then 
                category = "✨ " .. string.upper(mutMatch) 
            end
            
            if not categorizedItems[category] then categorizedItems[category] = {} end
            table.insert(categorizedItems[category], {name = itemName, qty = amount})
        end
        
        local sortedCategories = {}
        for cat, _ in pairs(categorizedItems) do table.insert(sortedCategories, cat) end
        table.sort(sortedCategories)
        
        for _, cat in ipairs(sortedCategories) do
            displayString = displayString .. "=== " .. cat .. " ===\n"
            table.sort(categorizedItems[cat], function(a, b) return a.name < b.name end)
            for _, item in ipairs(categorizedItems[cat]) do displayString = displayString .. string.format(" • %s  |  Qty: %d\n", item.name, item.qty) end
            displayString = displayString .. "\n"
        end
    end
    FullInventoryLabel:Set({Title = "🎒 Inventory", Content = displayString})
end

TabInventory:CreateButton({Name = "🔄 Refresh Inventory", Callback = function() updateInventoryDisplay(); PlayerDropdown:Refresh(getPlayerList()) end})

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
