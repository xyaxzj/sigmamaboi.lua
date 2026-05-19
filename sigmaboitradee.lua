-- ==========================================================
-- MOCTA TRADE AUTOMATOR V14.1 (FULL HANDS-FREE EDITION)
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
local AutoReceiverEnabled = false
local InsertDelay = 0.3 
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
        if isTradeable(tool) and getFullItemName(tool) == targetName then count = count + 1 end
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
    for name, count in pairs(inventoryCounts) do table.insert(itemsList, name .. " | Qty: " .. count) end  
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

local function isOpponentConfirmed(tradeFrame)
    if not tradeFrame then return false end
    local p2Frame = tradeFrame:FindFirstChild("P2_Frame")
    local p2Confirm = p2Frame and p2Frame:FindFirstChild("Confirmed")
    return p2Confirm and p2Confirm.Visible or false
end

-- [FITUR BARU V14.1] Fungsi Auto-Accept Undangan Trade Masuk via UI
local function scanAndAcceptTradeRequest()
    local pGui = localPlayer:FindFirstChild("PlayerGui")
    if not pGui then return end
    
    -- Memeriksa seluruh ScreenGui untuk mencari pop-up invite
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "Rayfield" then
            -- Cari frame undangan trade (mencari nama yang umum dipakai developer)
            local inviteFrame = gui:FindFirstChild("TradeInvite", true) or gui:FindFirstChild("InviteFrame", true) or gui:FindFirstChild("RequestFrame", true) or gui:FindFirstChild("TradeRequest", true)
            
            if inviteFrame and inviteFrame.Visible then
                -- Cari tombol terima di dalam frame tersebut
                local acceptBtn = inviteFrame:FindFirstChild("Accept", true) or inviteFrame:FindFirstChild("Yes", true) or inviteFrame:FindFirstChild("Confirm", true) or inviteFrame:FindFirstChild("Button", true)
                if acceptBtn then
                    pcall(function()
                        -- Gunakan firesignal bawaan executor untuk klik instan tanpa lag
                        if firesignal then
                            firesignal(acceptBtn.MouseButton1Click)
                            firesignal(acceptBtn.Activated)
                        end
                    end)
                end
            end
        end
    end
end

-- // UI Initialization // --
local Window = Rayfield:CreateWindow({
    Name = "Mocta Trade V14.1 (Hands-Free)",
    LoadingTitle = "Connecting Ecosystem...",
    LoadingSubtitle = "Loading Hands-Free Logic",
    ConfigurationSaving = { Enabled = false },
    Theme = "DarkBlue"
})

-- ==========================================
-- TAB 1: PACK MIX & QUEUE
-- ==========================================
local TabQueue = Window:CreateTab("1. Pack Mix", 4483362458)
local PlayerDropdown = TabQueue:CreateDropdown({Name = "Pilih Pembeli", Options = getPlayerList(), CurrentOption = {""}, MultipleOptions = false, Callback = function(Option) TargetPlayerName = Option[1] end})
TabQueue:CreateSection("Keranjang Belanja (Pack Mix)")
local SelectedMixItem = ""
local SelectedMixQty = 0
local ItemDropdown = TabQueue:CreateDropdown({Name = "Pilih Item", Options = getInventoryList(), CurrentOption = {"[ANY ASSET]"}, MultipleOptions = false, Callback = function(Option) SelectedMixItem = getBaseName(Option[1]) end})
TabQueue:CreateInput({Name = "Jumlah (Qty)", PlaceholderText = "Berapa banyak?", RemoveTextAfterFocusLost = false, Callback = function(Text) SelectedMixQty = tonumber(Text) or 0 end})
local CartStatus = TabQueue:CreateParagraph({Title = "🛒 Isi Keranjang", Content = "Keranjang kosong."})

local function updateCartDisplay()
    local text = ""
    local total = 0
    for name, qty in pairs(ShoppingCart) do text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end
    if total == 0 then text = "Keranjang kosong." else text = text .. "\nTotal Item: " .. total end
    CartStatus:Set({Title = "🛒 Isi Keranjang", Content = text})
end

TabQueue:CreateButton({
    Name = "➕ Tambah Sesuai Qty",
    Callback = function()
        if SelectedMixItem ~= "" and SelectedMixItem ~= "[ANY ASSET]" and SelectedMixQty > 0 then
            local realStock = getRealStock(SelectedMixItem)
            local currentInCart = ShoppingCart[SelectedMixItem] or 0
            if currentInCart + SelectedMixQty > realStock then
                ShoppingCart[SelectedMixItem] = realStock
                Rayfield:Notify({Title = "Limit", Content = "Mentok di sisa stok.", Duration = 2})
            else ShoppingCart[SelectedMixItem] = currentInCart + SelectedMixQty end
            updateCartDisplay()
        end
    end,
})
TabQueue:CreateButton({Name = "➕ Tambah MAX", Callback = function() if SelectedMixItem ~= "" and SelectedMixItem ~= "[ANY ASSET]" then ShoppingCart[SelectedMixItem] = getRealStock(SelectedMixItem) updateCartDisplay() end end})
TabQueue:CreateButton({Name = "🗑️ Kosongkan Keranjang", Callback = function() ShoppingCart = {}; updateCartDisplay() end})

TabQueue:CreateSection("Eksekusi Antrean")
local QueueStatus = TabQueue:CreateParagraph({Title = "📋 Queue Status", Content = "Queue is empty."})
TabQueue:CreateButton({
    Name = "🚀 GENERATE QUEUE DARI KERANJANG",
    Callback = function()
        if TargetPlayerName == "" then return Rayfield:Notify({Title = "Error", Content = "Pilih pembeli dulu!", Duration = 2}) end
        CurrentQueue = {}
        ItemsProcessed = 0
        local neededItems = {}
        for k, v in pairs(ShoppingCart) do neededItems[k] = v end
        for _, tool in ipairs(getAllTools()) do  
            if isTradeable(tool) then  
                local displayName = getFullItemName(tool)  
                if neededItems[displayName] and neededItems[displayName] > 0 then 
                    table.insert(CurrentQueue, tool) 
                    neededItems[displayName] = neededItems[displayName] - 1
                end  
            end  
        end  
        QueueStatus:Set({Title = "📋 Queue Status", Content = string.format("✅ Ready! %d items queued.", #CurrentQueue)})
    end,
})

-- ==========================================
-- TAB 2: SENDER MODE (P1 - PENGIRIM)
-- ==========================================
local TabControl = Window:CreateTab("2. Sender (P1)", 4483362458)
local LiveProgress = TabControl:CreateParagraph({Title = "⚡ Auto Sender Progress", Content = "Sisa Item: 0\nTerkirim: 0"})
local function updateProgressUI() LiveProgress:Set({Title = "⚡ Auto Sender Progress", Content = string.format("Sisa Item di Antrean: %d\nItem Terkirim: %d", #CurrentQueue, ItemsProcessed)}) end

TabControl:CreateSlider({Name = "Insert Delay", Range = {0.1, 1.0}, Increment = 0.1, CurrentValue = 0.3, Callback = function(Value) InsertDelay = Value end})

local function executeSenderBatch()
    if IsProcessing or #CurrentQueue == 0 then return false end
    IsProcessing = true
    local target = Players:FindFirstChild(TargetPlayerName)
    if not target then IsProcessing = false return false end

    -- 1. Invite Target
    task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)

    -- 2. Wait UI Open
    local tradeFrame = nil
    local timer = 0
    while timer < 15 do
        tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
        if tradeFrame and tradeFrame.Visible then break end
        task.wait(1) timer = timer + 1
    end
    if not (tradeFrame and tradeFrame.Visible) then IsProcessing = false return false end

    -- 3. Insert Items
    local batchSize = math.min(10, #CurrentQueue)
    local batch = {}
    for i = 1, batchSize do table.insert(batch, table.remove(CurrentQueue, 1)) end
    for _, tool in ipairs(batch) do
        local guid = getToolGUID(tool)
        if guid then r_trade_i:FireServer("AddItem", tostring(guid)) task.wait(InsertDelay) end
    end

    -- 4. P1 LOCK 1
    Rayfield:Notify({Title = "P1 Lock", Content = "Menunggu 5.5s...", Duration = 5})
    task.wait(5.5)
    r_trade_i:FireServer("Confirm") -- P1 Accept
    task.wait(0.5)

    -- 5. WAIT TRANSITION TO FINAL
    local waitTimeout = 0
    while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do
        local p1Frame = tradeFrame:FindFirstChild("P1_Frame")
        local p1Confirm = p1Frame and p1Frame:FindFirstChild("Confirmed")
        if p1Confirm and not p1Confirm.Visible then break end 
        task.wait(0.2)
        waitTimeout = waitTimeout + 0.2
        if waitTimeout > 60 then IsProcessing = false return false end
    end

    -- 6. P1 LOCK 2 (FINAL)
    if tradeFrame and tradeFrame.Parent and tradeFrame.Visible then
        Rayfield:Notify({Title = "P1 Lock Final", Content = "Menunggu 5.5s...", Duration = 5})
        task.wait(5.5)
        r_trade_i:FireServer("Confirm") 
        
        while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do task.wait(0.5) end
    end

    ItemsProcessed = ItemsProcessed + batchSize
    updateProgressUI()
    IsProcessing = false
    return true
end

TabControl:CreateButton({Name = "▶️ RUN 1 BATCH SEBAGAI P1", Callback = function() task.spawn(function() executeSenderBatch() end) end})
TabControl:CreateToggle({
    Name = "🔁 FULL AUTO LOOP (P1)", CurrentValue = false,
    Callback = function(Value)
        AutoLoopEnabled = Value
        if AutoLoopEnabled then
            task.spawn(function()
                while AutoLoopEnabled do
                    if #CurrentQueue == 0 then AutoLoopEnabled = false break end
                    local success = executeSenderBatch()
                    if not success then task.wait(3) else task.wait(2.5) end 
                end
            end)
        end
    end,
})

-- ==========================================
-- TAB 3: RECEIVER MODE (P2 - PENERIMA BOT)
-- ==========================================
local TabReceiver = Window:CreateTab("3. Receiver (P2)", 4483362458)
TabReceiver:CreateParagraph({Title = "🤖 Mode Penerima Otomatis", Content = "Nyalakan ini di akun pembeli. Akun ini akan otomatis menerima request invite masuk dan menekan klik Confirm mengikuti ritme P1."})

TabReceiver:CreateToggle({
    Name = "🤖 ENABLE AUTO RECEIVER (P2 MODE)",
    CurrentValue = false,
    Callback = function(Value)
        AutoReceiverEnabled = Value
        if AutoReceiverEnabled then
            Rayfield:Notify({Title = "Receiver Aktif", Content = "Mulai memantau Layar & Request...", Duration = 3})
            task.spawn(function()
                while AutoReceiverEnabled do
                    -- [DI-UPDATE] Selalu scan undangan trade yang masuk jika UI trade utama belum terbuka
                    local tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
                    
                    if not (tradeFrame and tradeFrame.Visible) then
                        scanAndAcceptTradeRequest()
                    else
                        -- JIKA UI TRADE SUDAH TERBUKA (PROSES TRANSAKSI JALAN)
                        
                        -- TAHAP 1: Tunggu P1 Accept
                        while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                        
                        if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                            Rayfield:Notify({Title = "P2 Lock 1", Content = "Sender siap! Menunggu 5.5s...", Duration = 5})
                            task.wait(5.5)
                            r_trade_i:FireServer("Confirm") -- P2 Accept
                            task.wait(1)
                        end

                        -- TAHAP 2: Tunggu Layar Reset (Transisi)
                        while tradeFrame.Visible and isOpponentConfirmed(tradeFrame) do task.wait(0.2) end

                        -- TAHAP 3: Tunggu P1 Final Confirm
                        while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end

                        if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                            Rayfield:Notify({Title = "P2 Lock 2", Content = "Final step! Menunggu 5.5s...", Duration = 5--[[Sec]]})
                            task.wait(5.5)
                            r_trade_i:FireServer("Confirm") -- P2 Final Confirm
                        end

                        -- Tunggu sampai layar tertutup murni
                        while tradeFrame.Visible do task.wait(0.5) end
                        Rayfield:Notify({Title = "Selesai", Content = "Trade sukses diterima!", Duration = 2})
                    end
                    task.wait(0.5) -- Standby Loop Scanner
                end
            end)
        end
    end,
})

-- ==========================================
-- TAB 4: DATABASE INVENTORY
-- ==========================================
local TabInventory = Window:CreateTab("4. Database", 4483362458)
local FullInventoryLabel = TabInventory:CreateParagraph({Title = "🎒 Database", Content = "Syncing..."})

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
    if totalCount == 0 then displayString = displayString .. "Inventory is empty." else
        local categorizedItems = {}
        for itemName, amount in pairs(inventoryData) do
            local category = "📦 NORMAL / BASE"
            local mutMatch = string.match(itemName, "%[(.-)%]")
            if mutMatch then category = "✨ " .. string.upper(mutMatch) end
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
    FullInventoryLabel:Set({Title = "🎒 Database", Content = displayString})
end
TabInventory:CreateButton({Name = "🔄 Refresh Database", Callback = function() updateInventoryDisplay(); PlayerDropdown:Refresh(getPlayerList()); ItemDropdown:Refresh(getInventoryList()) end})

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
