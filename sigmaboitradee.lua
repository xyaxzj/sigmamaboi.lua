-- ==========================================================
-- MOCTA TRADE AUTOMATOR V15.8 (THE PERFECT METRONOME)
-- ==========================================================

local success, errorMessage = pcall(function()
    
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local StarterGui = game:GetService("StarterGui")
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer

    -- // Services & Remotes // --
    local networkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
    local f_trade_r = networkFolder:WaitForChild("ref_trade_r", 5) 
    local r_trade_i = networkFolder:WaitForChild("rev_trade_i", 5) 
    local rev_trade_start = networkFolder:WaitForChild("rev_trade_start", 5) 

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
        local mutValue = tool:GetAttribute("Mutation") or tool:GetAttribute("Variant")
        if not mutValue then
            local mutObj = tool:FindFirstChild("Mutation")
            if mutObj then mutValue = mutObj.Value end
        end
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

    local function isOpponentConfirmed(tradeFrame)
        if not tradeFrame then return false end
        local p2Frame = tradeFrame:FindFirstChild("P2_Frame")
        if not p2Frame then return false end
        local p2Confirm = p2Frame:FindFirstChild("Confirmed")
        return p2Confirm and p2Confirm.Visible or false
    end

    -- Scanner Universal Auto-Accept
    local function universalAutoAccept()
        local pGui = localPlayer:FindFirstChild("PlayerGui")
        if not pGui then return end
        for _, gui in ipairs(pGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "Rayfield" then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and desc.Visible then
                        local text = string.lower(desc:IsA("TextButton") and desc.Text or desc.Name)
                        if string.find(text, "accept") or string.find(text, "yes") or string.find(text, "trade") then
                            pcall(function()
                                if getconnections then
                                    local conns1 = getconnections(desc.MouseButton1Click)
                                    if conns1 then for _, conn in ipairs(conns1) do pcall(function() conn:Fire() end) end end
                                    local conns2 = getconnections(desc.Activated)
                                    if conns2 then for _, conn in ipairs(conns2) do pcall(function() conn:Fire() end) end end
                                end
                                if firesignal then
                                    firesignal(desc.MouseButton1Click)
                                    firesignal(desc.Activated)
                                end
                            end)
                        end
                    end
                end
            end
        end
        if rev_trade_start then
            for _, desc in ipairs(pGui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible then
                    local txt = string.lower(desc.Text)
                    if string.find(txt, "trade") or string.find(txt, "request") or string.find(txt, "wants") then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= localPlayer and (string.find(desc.Text, p.Name) or string.find(desc.Text, p.DisplayName)) then
                                pcall(function() rev_trade_start:InvokeServer(p.UserId) end)
                                pcall(function() rev_trade_start:FireServer(p.UserId) end)
                            end
                        end
                    end
                end
            end
        end
    end

    -- // UI Initialization // --
    local Window = Rayfield:CreateWindow({
        Name = "Mocta Trade V15.8", 
        LoadingTitle = "Perfect Ping-Pong Mode...", 
        ConfigurationSaving = { Enabled = false }, 
        Theme = "DarkBlue"
    })

    -- ==========================================
    -- TAB 1: PACK MIX & QUEUE
    -- ==========================================
    local TabQueue = Window:CreateTab("1. Queue", 4483362458)
    local PlayerDropdown = TabQueue:CreateDropdown({
        Name = "Pilih Pembeli (P2)", 
        Options = getPlayerList(), 
        CurrentOption = {""}, 
        MultipleOptions = false, 
        Callback = function(Option) TargetPlayerName = Option[1] end
    })

    TabQueue:CreateSection("Bacon Event Quick-Trade")
    TabQueue:CreateButton({
        Name = "🚀 GENERATE QUEUE: ALL BACON MATERIALS",
        Callback = function()
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Error", Content = "Pilih pembeli dulu di atas!", Duration = 2}) end
            CurrentQueue = {} ItemsProcessed = 0 local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do  
                if isTradeable(tool) then  
                    local displayName = getFullItemName(tool)
                    local baseNameOnly = string.split(displayName, " [")[1]
                    baseNameOnly = string.split(baseNameOnly, " (Lv")[1]
                    if BaconEventItems[baseNameOnly] or BaconEventItems[displayName] then
                        table.insert(CurrentQueue, tool) itemsFound = itemsFound + 1
                    end  
                end  
            end  
            if itemsFound == 0 then Rayfield:Notify({Title = "Kosong", Content = "Tidak ada Bacon Materials.", Duration = 3})
            else Rayfield:Notify({Title = "Ready", Content = itemsFound .. " Bacon Materials masuk antrean!", Duration = 2}) end
        end
    })

    TabQueue:CreateSection("Custom Pack Mix")
    local SelectedMixItem = ""
    local SelectedMixQty = 0
    local function getBaseName(dropdownString) return string.split(dropdownString, " | Qty:")[1] or dropdownString end

    local ItemDropdown = TabQueue:CreateDropdown({
        Name = "Pilih Item", Options = {"[ANY ASSET]"}, CurrentOption = {"[ANY ASSET]"}, MultipleOptions = false, 
        Callback = function(Option) SelectedMixItem = getBaseName(Option[1]) end
    })
    
    TabQueue:CreateInput({
        Name = "Jumlah (Qty)", PlaceholderText = "Berapa banyak?", RemoveTextAfterFocusLost = false, 
        Callback = function(Text) SelectedMixQty = tonumber(Text) or 0 end
    })
    
    local CartStatus = TabQueue:CreateParagraph({Title = "🛒 Isi Keranjang", Content = "Keranjang kosong."})

    local function updateCartDisplay()
        local text = "" local total = 0
        for name, qty in pairs(ShoppingCart) do text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end
        if total == 0 then text = "Keranjang kosong." else text = text .. "\nTotal Item: " .. total end
        CartStatus:Set({Title = "🛒 Isi Keranjang", Content = text})
    end

    TabQueue:CreateButton({
        Name = "➕ Tambah Sesuai Qty", 
        Callback = function() 
            if SelectedMixItem ~= "" and SelectedMixItem ~= "[ANY ASSET]" and SelectedMixQty > 0 then 
                local rs = getRealStock(SelectedMixItem) 
                local cur = ShoppingCart[SelectedMixItem] or 0 
                if cur + SelectedMixQty > rs then ShoppingCart[SelectedMixItem] = rs 
                else ShoppingCart[SelectedMixItem] = cur + SelectedMixQty end 
                updateCartDisplay() 
            end 
        end
    })
    
    TabQueue:CreateButton({
        Name = "➕ Tambah MAX", 
        Callback = function() 
            if SelectedMixItem ~= "" and SelectedMixItem ~= "[ANY ASSET]" then 
                ShoppingCart[SelectedMixItem] = getRealStock(SelectedMixItem) updateCartDisplay() 
            end 
        end
    })
    
    TabQueue:CreateButton({Name = "🗑️ Kosongkan Keranjang", Callback = function() ShoppingCart = {} updateCartDisplay() end})

    TabQueue:CreateButton({
        Name = "🚀 GENERATE QUEUE DARI KERANJANG", 
        Callback = function() 
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Error", Content = "Pilih pembeli dulu!", Duration = 2}) end
            CurrentQueue = {} ItemsProcessed = 0 local needed = {} for k,v in pairs(ShoppingCart) do needed[k] = v end
            local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do 
                if isTradeable(tool) then 
                    local name = getFullItemName(tool) 
                    if needed[name] and needed[name] > 0 then 
                        table.insert(CurrentQueue, tool) needed[name] = needed[name] - 1 itemsFound = itemsFound + 1 
                    end 
                end 
            end
            Rayfield:Notify({Title = "Ready", Content = itemsFound .. " custom items queued.", Duration = 2})
        end
    })

    -- ==========================================
    -- TAB 2: SENDER MODE (P1 - PENGIRIM)
    -- ==========================================
    local TabControl = Window:CreateTab("2. Sender (P1)", 4483362458)
    local LiveProgress = TabControl:CreateParagraph({Title = "⚡ Auto Sender Progress", Content = "Sisa Item: 0\nTerkirim: 0"})
    local ActionLog = TabControl:CreateParagraph({Title = "📜 Live Trade Log", Content = "Menunggu perintah..."})

    local function updateProgressUI() LiveProgress:Set({Title = "⚡ Auto Sender Progress", Content = string.format("Sisa Item di Antrean: %d\nItem Terkirim: %d", #CurrentQueue, ItemsProcessed)}) end
    local function setLog(txt) ActionLog:Set({Title = "📜 Live Trade Log", Content = txt}) end

    TabControl:CreateSlider({Name = "Insert Delay", Range = {0.1, 1.0}, Increment = 0.1, CurrentValue = 0.3, Callback = function(Value) InsertDelay = Value end})

    -- [DIPERBAIKI] P1 SEKARANG MENGGUNAKAN TIMER METRONOME (SAMA SEPERTI V15.3)
    local function executeSenderBatch()
        if IsProcessing or #CurrentQueue == 0 then return false end
        IsProcessing = true
        
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then 
            setLog("❌ ERROR: Target tidak ditemukan di server!") 
            IsProcessing = false return false 
        end
        
        setLog("Fase 1: Mengirim Invite ke " .. target.Name .. "...")
        task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)
        
        local tradeFrame = nil
        local timer = 0
        while timer < 15 do
            tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
            if tradeFrame and tradeFrame.Visible then break end
            task.wait(1) timer = timer + 1
        end
        
        if not (tradeFrame and tradeFrame.Visible) then 
            setLog("❌ ERROR: Timeout! Target tidak merespon invite.") 
            IsProcessing = false return false 
        end
        
        setLog("Fase 2: UI Terbuka. Memasukkan item...")
        local batchSize = math.min(10, #CurrentQueue)
        local batch = {}
        for i = 1, batchSize do table.insert(batch, table.remove(CurrentQueue, 1)) end
        
        for _, tool in ipairs(batch) do 
            local guid = getToolGUID(tool) 
            if guid then r_trade_i:FireServer("AddItem", tostring(guid)) task.wait(InsertDelay) end 
        end
        
        setLog("Fase 3: Item masuk. Lock Pertama (Tunggu 5.5s)...")
        task.wait(5.5)
        
        setLog("Fase 4: Accept 1 Dikirim! (Menunggu P2 merespon 6.5s)...")
        r_trade_i:FireServer("Confirm")
        
        -- STATIC TIMER: P1 Cukup diam dan biarkan P2 mengejar ketertinggalan
        task.wait(6.5)

        if tradeFrame and tradeFrame.Parent and tradeFrame.Visible then
            setLog("Fase 5: Menekan Final Confirm! Selesai.")
            r_trade_i:FireServer("Confirm") 
            while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do 
                task.wait(0.5) 
            end
        end
        
        ItemsProcessed = ItemsProcessed + batchSize
        updateProgressUI()
        setLog("✅ TRADE SUKSES: " .. batchSize .. " item terkirim!")
        IsProcessing = false
        return true
    end

    TabControl:CreateButton({Name = "▶️ RUN 1 BATCH SEBAGAI P1", Callback = function() task.spawn(executeSenderBatch) end})
    TabControl:CreateToggle({
        Name = "🔁 FULL AUTO LOOP (P1)", CurrentValue = false, 
        Callback = function(Value) 
            AutoLoopEnabled = Value 
            if AutoLoopEnabled then 
                task.spawn(function() 
                    while AutoLoopEnabled do 
                        if #CurrentQueue == 0 then setLog("🏁 Antrean kosong. Loop berhenti.") AutoLoopEnabled = false break end 
                        executeSenderBatch() 
                        task.wait(2.5) 
                    end 
                end) 
            end 
        end
    })

    -- ==========================================
    -- TAB 3: RECEIVER MODE (P2 - PENERIMA UNIVERSAL)
    -- ==========================================
    local TabReceiver = Window:CreateTab("3. Receiver (P2)", 4483362458)
    local ReceiverLog = TabReceiver:CreateParagraph({Title = "📡 Status P2", Content = "Menunggu dihidupkan..."})

    TabReceiver:CreateToggle({
        Name = "🤖 ENABLE UNIVERSAL AUTO-ACCEPT", CurrentValue = false,
        Callback = function(Value)
            AutoReceiverEnabled = Value
            if AutoReceiverEnabled then
                ReceiverLog:Set({Title = "📡 Status P2", Content = "✅ Aktif. Memantau request masuk..."})
                task.spawn(function()
                    while AutoReceiverEnabled do
                        local tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
                        
                        if not (tradeFrame and tradeFrame.Visible) then
                            universalAutoAccept()
                            task.wait(1)
                        else
                            ReceiverLog:Set({Title = "📡 Status P2", Content = "📥 UI Terbuka! Menunggu P1 Accept..."})
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            
                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                                ReceiverLog:Set({Title = "📡 Status P2", Content = "🔒 P1 Accept. Lock 1 (5.5 detik)..."})
                                task.wait(5.5)
                                r_trade_i:FireServer("Confirm")
                                task.wait(1)
                            end

                            ReceiverLog:Set({Title = "📡 Status P2", Content = "⏳ Menunggu transisi ke Final Confirm..."})
                            while tradeFrame.Visible and isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end

                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                                ReceiverLog:Set({Title = "📡 Status P2", Content = "🔒 Masuk Final. Lock 2 (5.5 detik)..."})
                                task.wait(5.5)
                                r_trade_i:FireServer("Confirm")
                            end

                            ReceiverLog:Set({Title = "📡 Status P2", Content = "✅ Menyelesaikan..."})
                            while tradeFrame.Visible do task.wait(0.5) end
                            ReceiverLog:Set({Title = "📡 Status P2", Content = "✅ Trade sukses! Kembali memantau..."})
                        end
                        task.wait(0.2)
                    end
                end)
            else
                ReceiverLog:Set({Title = "📡 Status P2", Content = "❌ Non-aktif."})
            end
        end,
    })

    -- ==========================================
    -- TAB 4: INVENTORY & SETTINGS
    -- ==========================================
    local TabInventory = Window:CreateTab("4. Inventory", 4483362458)

    TabInventory:CreateToggle({
        Name = "👁️ Enable Clean UI Mode (Anti-Lag)", CurrentValue = false,
        Callback = function(Value)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not Value)
            local pGui = localPlayer:WaitForChild("PlayerGui")  
            for _, gui in ipairs(pGui:GetChildren()) do  
                if gui:IsA("ScreenGui") and gui.Name ~= "Rayfield" then  
                    if Value then gui:SetAttribute("WasEnabled", gui.Enabled) gui.Enabled = false  
                    else gui.Enabled = gui:GetAttribute("WasEnabled") or true end  
                end  
            end  
        end,
    })

    local FullInventoryLabel = TabInventory:CreateParagraph({Title = "🎒 Inventory", Content = "Syncing..."})

    local function updateInventoryDisplay()
        local inventoryData = {}
        local totalCount = 0
        
        for _, tool in pairs(getAllTools()) do  
            if isTradeable(tool) then
                local displayName = getFullItemName(tool)  
                inventoryData[displayName] = (inventoryData[displayName] or 0) + 1  
                totalCount = totalCount + 1  
            end
        end  
        
        local itemsList = {"[ANY ASSET]"}  
        for name, count in pairs(inventoryData) do table.insert(itemsList, name .. " | Qty: " .. count) end  
        table.sort(itemsList, function(a, b) if a == "[ANY ASSET]" then return true end if b == "[ANY ASSET]" then return false end return a < b end)  
        ItemDropdown:Refresh(itemsList)
        
        local displayString = "Total Tradeable Assets: " .. totalCount .. "\n\n"  
        if totalCount == 0 then 
            displayString = displayString .. "Inventory is empty." 
        else
            local categorizedItems = {}
            for itemName, amount in pairs(inventoryData) do
                local category = "📦 NORMAL / BASE"
                local mutMatch = string.match(itemName, "%[(.-)%]")
                
                local baseNameOnly = string.split(itemName, " [")[1]
                baseNameOnly = string.split(baseNameOnly, " (Lv")[1]
                
                if BaconEventItems[baseNameOnly] or BaconEventItems[itemName] then category = "🥓 BACON EVENT MATERIALS"
                elseif mutMatch then category = "✨ " .. string.upper(mutMatch) end
                
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

    TabInventory:CreateButton({Name = "🔄 Refresh Inventory", Callback = function() updateInventoryDisplay() PlayerDropdown:Refresh(getPlayerList()) end})

    local function connectInventory()
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
    connectInventory()

end)

if not success then
    warn("MOCTA SCRIPT ERROR: " .. tostring(errorMessage))
    if not game:IsLoaded() then game.Loaded:Wait() end
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title = "🚨 Script Error", Text = tostring(errorMessage), Duration = 20})
    end)
end
