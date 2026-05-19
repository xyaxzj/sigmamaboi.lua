-- ==========================================================
-- MOCTA TRADE AUTOMATOR V8.3 (LEVEL & STOCK MASTERY)
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
local ShoppingCart = {} 
local CurrentQueue = {}
local ItemsProcessed = 0
local IsProcessing = false 
local AutoLoopEnabled = false
local InsertDelay = 0.5 
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

-- [UPDATE V8.3] Deteksi Mutasi & Level
local function getFullItemName(tool)
    local displayName = tool.Name
    
    -- Deteksi Mutasi
    local mutValue = tool:GetAttribute("Mutation") or tool:GetAttribute("Variant") or (tool:FindFirstChild("Mutation") and tool:FindFirstChild("Mutation").Value)
    if mutValue then displayName = displayName .. " [" .. tostring(mutValue) .. "]" end  
    
    -- Deteksi Level
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
    for _, tool in ipairs(getAllTools()) do
        if isTradeable(tool) and getFullItemName(tool) == targetName then
            count = count + 1
        end
    end
    return count
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
    Name = "Mocta Trade Automator V8.3",
    LoadingTitle = "Level & Stock Protocol...",
    LoadingSubtitle = "Loading UI Engine",
    ConfigurationSaving = { Enabled = false },
    Theme = "DarkBlue"
})

-- ==========================================
-- TAB 1: PACK MIX & QUEUE
-- ==========================================
local TabQueue = Window:CreateTab("1. Pack Mix", 4483362458)

local PlayerDropdown = TabQueue:CreateDropdown({
    Name = "Pilih Pembeli (Customer)", Options = getPlayerList(), CurrentOption = {""}, MultipleOptions = false,
    Callback = function(Option) TargetPlayerName = Option[1] end,
})

TabQueue:CreateSection("Keranjang Belanja (Pack Mix)")

local SelectedMixItem = ""
local SelectedMixQty = 0

local ItemDropdown = TabQueue:CreateDropdown({
    Name = "Pilih Item", Options = getInventoryList(), CurrentOption = {"[ANY ASSET]"}, MultipleOptions = false,
    Callback = function(Option) SelectedMixItem = getBaseName(Option[1]) end,
})

TabQueue:CreateInput({
    Name = "Jumlah (Qty)", PlaceholderText = "Berapa banyak?", RemoveTextAfterFocusLost = false,
    Callback = function(Text) SelectedMixQty = tonumber(Text) or 0 end,
})

local CartStatus = TabQueue:CreateParagraph({Title = "🛒 Isi Keranjang", Content = "Keranjang kosong."})

local function updateCartDisplay()
    local text = ""
    local total = 0
    for name, qty in pairs(ShoppingCart) do
        text = text .. "- " .. name .. " (x" .. qty .. ")\n"
        total = total + qty
    end
    if total == 0 then text = "Keranjang kosong." else text = text .. "\nTotal Item: " .. total end
    CartStatus:Set({Title = "🛒 Isi Keranjang", Content = text})
end

TabQueue:CreateButton({
    Name = "➕ Tambah Sesuai Qty",
    Callback = function()
        if SelectedMixItem ~= "" and SelectedMixItem ~= "[ANY ASSET]" and SelectedMixQty > 0 then
            local realStock = getRealStock(SelectedMixItem)
            local currentInCart = ShoppingCart[SelectedMixItem] or 0
            local desiredTotal = currentInCart + SelectedMixQty

            if desiredTotal > realStock then
                local maxAddable = realStock - currentInCart
                if maxAddable > 0 then
                    ShoppingCart[SelectedMixItem] = realStock
                    Rayfield:Notify({Title = "Limit Tercapai", Content = "Stok hanya sisa " .. maxAddable .. ". Semuanya dimasukkan ke keranjang.", Duration = 3})
                else
                    Rayfield:Notify({Title = "Out of Stock", Content = "Semua stok item ini sudah masuk ke keranjang!", Duration = 3})
                end
            else
                ShoppingCart[SelectedMixItem] = desiredTotal
                Rayfield:Notify({Title = "Ditambahkan", Content = SelectedMixQty .. " " .. SelectedMixItem .. " ditambahkan.", Duration = 2})
            end
            updateCartDisplay()
        else
            Rayfield:Notify({Title = "Error", Content = "Pilih item dan masukkan jumlah yang valid!", Duration = 2})
        end
    end,
})

TabQueue:CreateButton({
    Name = "➕ Tambah MAX (Semua Sisa Stok)",
    Callback = function()
        if SelectedMixItem ~= "" and SelectedMixItem ~= "[ANY ASSET]" then
            local realStock = getRealStock(SelectedMixItem)
            local currentInCart = ShoppingCart[SelectedMixItem] or 0
            local maxAddable = realStock - currentInCart

            if maxAddable > 0 then
                ShoppingCart[SelectedMixItem] = realStock
                Rayfield:Notify({Title = "Ditambahkan", Content = "Semua sisa stok (" .. maxAddable .. ") ditambahkan ke keranjang.", Duration = 3})
                updateCartDisplay()
            else
                Rayfield:Notify({Title = "Out of Stock", Content = "Semua stok item ini sudah masuk ke keranjang!", Duration = 3})
            end
        else
            Rayfield:Notify({Title = "Error", Content = "Pilih item terlebih dahulu!", Duration = 2})
        end
    end,
})

TabQueue:CreateButton({Name = "🗑️ Kosongkan Keranjang", Callback = function() ShoppingCart = {}; updateCartDisplay() end})

TabQueue:CreateSection("Eksekusi Antrean")
local QueueStatus = TabQueue:CreateParagraph({Title = "📋 Queue Status", Content = "Queue is empty."})

TabQueue:CreateButton({
    Name = "🚀 GENERATE QUEUE DARI KERANJANG",
    Callback = function()
        if TargetPlayerName == "" then return Rayfield:Notify({Title = "Error", Content = "Pilih pembeli dulu!", Duration = 2}) end
        
        CurrentQueue = {}
        ItemsProcessed = 0
        local allTools = getAllTools()  
        
        local neededItems = {}
        local totalNeeded = 0
        for k, v in pairs(ShoppingCart) do neededItems[k] = v; totalNeeded = totalNeeded + v end

        if totalNeeded == 0 then return Rayfield:Notify({Title = "Error", Content = "Keranjang masih kosong!", Duration = 2}) end

        for _, tool in ipairs(allTools) do  
            if isTradeable(tool) then  
                local displayName = getFullItemName(tool)  
                if neededItems[displayName] and neededItems[displayName] > 0 then 
                    table.insert(CurrentQueue, tool) 
                    neededItems[displayName] = neededItems[displayName] - 1
                end  
            end  
        end  

        QueueStatus:Set({
            Title = "📋 Queue Status", 
            Content = string.format("✅ Ready! %d items queued for %s.\nSilakan ke tab '2. Full Auto'.", #CurrentQueue, TargetPlayerName)
        })
        Rayfield:Notify({Title = "Queue Ready", Content = "Antrean Pack Mix berhasil dibuat!", Duration = 2})
    end,
})

-- ==========================================
-- TAB 2: FULL AUTO ENGINE (ANTI-DEBOUNCE)
-- ==========================================
local TabControl = Window:CreateTab("2. Full Auto", 4483362458)

local LiveProgress = TabControl:CreateParagraph({Title = "⚡ Auto Engine Progress", Content = "Sisa Item: 0\nTerkirim: 0"})

local function updateProgressUI()
    LiveProgress:Set({Title = "⚡ Auto Engine Progress", Content = string.format("Sisa Item di Antrean: %d\nItem Terkirim: %d", #CurrentQueue, ItemsProcessed)})
end

TabControl:CreateSlider({
    Name = "Insert Delay (Minimal 0.4s agar aman)", Range = {0.2, 1.5}, Increment = 0.1, CurrentValue = 0.5,
    Callback = function(Value) InsertDelay = Value end,
})

local function executeOneBatch()
    if IsProcessing or #CurrentQueue == 0 then return false end
    IsProcessing = true

    local target = Players:FindFirstChild(TargetPlayerName)
    if not target then IsProcessing = false return false end

    -- 1. Invite
    Rayfield:Notify({Title = "Auto Engine", Content = "Mengirim Invite...", Duration = 2})
    task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)

    -- 2. Tunggu TradingFrame Muncul
    local tradeFrame = nil
    local timer = 0
    while timer < 15 do
        tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
        if tradeFrame and tradeFrame.Visible then break end
        task.wait(1)
        timer = timer + 1
    end

    if not (tradeFrame and tradeFrame.Visible) then
        Rayfield:Notify({Title = "Timeout", Content = "Target tidak menerima trade (15s).", Duration = 3})
        IsProcessing = false
        return false
    end

    -- 3. Insert Items
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

    -- 4. Accept Pertama
    task.wait(1.5) 
    r_trade_i:FireServer("Confirm")

    -- 5. Auto-Confirm Final
    Rayfield:Notify({Title = "Auto Engine", Content = "Menunggu Lock Timer & Target Accept...", Duration = 2})
    
    while tradeFrame and tradeFrame.Parent do
        if not tradeFrame.Visible then break end
        task.wait(3.5) 
        if tradeFrame.Visible then
            r_trade_i:FireServer("Confirm")
        end
    end

    ItemsProcessed = ItemsProcessed + batchSize
    updateProgressUI()
    IsProcessing = false
    return true
end

TabControl:CreateButton({
    Name = "▶️ RUN 1 BATCH (Kirim 10 Item Otomatis)",
    Callback = function()
        task.spawn(function()
            local success = executeOneBatch()
            if success then Rayfield:Notify({Title = "Sukses", Content = "1 Batch berhasil diselesaikan!", Duration = 2}) end
        end)
    end,
})

TabControl:CreateToggle({
    Name = "🔁 ENABLE FULL AUTO-LOOP TILL EMPTY",
    CurrentValue = false,
    Callback = function(Value)
        AutoLoopEnabled = Value
        if AutoLoopEnabled then
            task.spawn(function()
                while AutoLoopEnabled do
                    if #CurrentQueue == 0 then
                        Rayfield:Notify({Title = "Selesai", Content = "Semua item di antrean telah terkirim!", Duration = 4})
                        AutoLoopEnabled = false
                        break
                    end
                    local success = executeOneBatch()
                    if not success then task.wait(3) else task.wait(2.5) end 
                end
            end)
        end
    end,
})

-- ==========================================
-- TAB 3: FULL INVENTORY & SETTINGS
-- ==========================================
local TabInventory = Window:CreateTab("3. Database", 4483362458)

local FullInventoryLabel = TabInventory:CreateParagraph({Title = "🎒 Database Inventory", Content = "Synchronizing data..."})

function updateInventoryDisplay()
    local inventoryData = {}
    local totalCount = 0
    for _, tool in pairs(getAllTools()) do  
        if isTradeable(tool) then
            local displayName = getFullItemName(tool)  
            inventoryData[displayName] = (inventoryData[displayName] or 0) + 1  
            totalCount = totalCount + 1  
        end
    end  
    
    local displayString = "Total Tradeable Assets: " .. totalCount .. "\n\n"  
    
    if totalCount == 0 then 
        displayString = displayString .. "Inventory is empty." 
    else
        local categorizedItems = {}
        for itemName, amount in pairs(inventoryData) do
            local category = "📦 NORMAL / BASE"
            
            -- Regex pintar untuk menangkap Mutasi (meski ada Level di belakangnya)
            local mutMatch = string.match(itemName, "%[(.-)%]")
            if mutMatch then
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
            
            for _, item in ipairs(categorizedItems[cat]) do 
                displayString = displayString .. string.format(" • %s  |  Qty: %d\n", item.name, item.qty) 
            end
            displayString = displayString .. "\n"
        end
    end
    FullInventoryLabel:Set({Title = "🎒 Database Inventory", Content = displayString})
end

TabInventory:CreateButton({
    Name = "🔄 Refresh Database",
    Callback = function() updateInventoryDisplay(); PlayerDropdown:Refresh(getPlayerList()); ItemDropdown:Refresh(getInventoryList()) end,
})

TabInventory:CreateToggle({
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
