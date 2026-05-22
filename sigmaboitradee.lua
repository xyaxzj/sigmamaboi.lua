-- ==========================================================
-- MOCTA TRADE AUTOMATOR V18.0 (LINORIA STABLE EDITION)
-- Build: Clean UI Migration to LinoriaLib + Full Features Intact
-- ==========================================================

local success, errorMessage = pcall(function()
    
    -- // Memuat LinoriaLib & Addons // --
    local repo = 'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/'
    local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
    local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()

    local StarterGui = game:GetService("StarterGui")
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer

    -- Folder Network & Remotes (Murni God-Sync)
    local networkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
    local f_trade_r = networkFolder:WaitForChild("ref_trade_r", 5) 
    local r_trade_i = networkFolder:WaitForChild("rev_trade_i", 5) 
    local rev_trade_start = networkFolder:WaitForChild("rev_trade_start", 5) 

    -- // Variabel State & Analitik // --
    local TargetPlayerName = ""
    local SelectedMutation = ""
    local ShoppingCart = {} 
    local CurrentQueue = {}
    
    local ItemsProcessed = 0
    local IsProcessing = false 
    local AutoLoopEnabled = false
    local AutoReceiverEnabled = false
    local InsertDelay = 0.3 
    local InventoryConnections = {}

    -- Tracker Statistik Sesi
    local SessionStartTime = tick()
    local P1TradesCompleted = 0
    local P2TradesCompleted = 0
    local TotalItemsSent = 0

    local BaconEventItems = {
        ["Chicleteira Bicicleteira"] = true,
        ["Agarrini La Palini"] = true,
        ["Trippi Troppi"] = true,
        ["Strawberry Elephant"] = true
    }

    -- ==========================================
    -- FUNGSI HELPER (LOGIKA TAS & WAKTU)
    -- ==========================================
    local function formatTime(seconds)
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = math.floor(seconds % 60)
        return string.format("%02d:%02d:%02d", h, m, s)
    end

    local function getAllTools()
        local tools = {}
        local bp = localPlayer:FindFirstChild("Backpack")
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
        local char = localPlayer.Character
        if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
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
        if #tbl == 0 then return {"Tidak ada player lain"} end
        return tbl
    end

    local function getMutationList()
        local muts = {}
        local hasMut = false
        for _, tool in ipairs(getAllTools()) do
            if isTradeable(tool) then
                local m = tool:GetAttribute("Mutation") or tool:GetAttribute("Variant") or (tool:FindFirstChild("Mutation") and tool:FindFirstChild("Mutation").Value)
                if m then muts[tostring(m)] = true; hasMut = true end
            end
        end
        local list = {}
        if not hasMut then return {"[TIDAK ADA MUTASI]"} end
        for k, _ in pairs(muts) do table.insert(list, k) end
        table.sort(list)
        return list
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

    local function isOpponentConfirmed(tradeFrame)
        if not tradeFrame then return false end
        local p2Confirm = tradeFrame:FindFirstChild("P2_Frame") and tradeFrame.P2_Frame:FindFirstChild("Confirmed")
        return p2Confirm and p2Confirm.Visible or false
    end

    local function isLocalConfirmed(tradeFrame)
        if not tradeFrame then return false end
        local p1Confirm = tradeFrame:FindFirstChild("P1_Frame") and tradeFrame.P1_Frame:FindFirstChild("Confirmed")
        return p1Confirm and p1Confirm.Visible or false
    end

    -- ==========================================
    -- STRUKTUR WINDOW & TAB LINORIALIB
    -- ==========================================
    local Window = Library:CreateWindow({
        Title = 'Mocta Trade Automator V18.0',
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2
    })

    local Tabs = {
        Main = Window:AddTab('1. Queue Generator'),
        Sender = Window:AddTab('2. Sender Mode (P1)'),
        Receiver = Window:AddTab('3. Receiver Mode (P2)'),
        Analytics = Window:AddTab('4. Dash & Inventory')
    }

    -- ==========================================
    -- TAB 1: QUEUE GENERATOR (BANYAK SEKSI PANEL)
    -- ==========================================
    local LeftBox = Tabs.Main:AddLeftGroupbox('Target & Mass Operation')
    
    LeftBox:AddDropdown('PlayerDropdown', {
        Values = getPlayerList(), Default = 1, Multi = false, Text = 'Pilih Pembeli (P2)',
        Callback = function(Value) TargetPlayerName = Value end
    })

    LeftBox:AddButton({
        Text = '🚀 GENERATE QUEUE: ALL INVENTORY',
        Func = function()
            if TargetPlayerName == "" or TargetPlayerName == "Tidak ada player lain" then return Library:Notify("Pilih pembeli yang valid dulu!") end
            CurrentQueue = {}; ItemsProcessed = 0; local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do  
                if isTradeable(tool) then table.insert(CurrentQueue, tool); itemsFound = itemsFound + 1 end  
            end  
            Library:Notify("Ready! " .. itemsFound .. " item masuk antrean massal.")
        end
    })

    local MutationBox = Tabs.Main:AddLeftGroupbox('Mutation & Event Filters')
    
    MutationBox:AddDropdown('MutationDropdown', {
        Values = getMutationList(), Default = 1, Multi = false, Text = 'Pilih Kategori Mutasi',
        Callback = function(Value) SelectedMutation = Value end
    })

    MutationBox:AddButton({
        Text = '🚀 GENERATE BY MUTATION',
        Func = function()
            if TargetPlayerName == "" or TargetPlayerName == "Tidak ada player lain" then return Library:Notify("Pilih pembeli dulu!") end
            if SelectedMutation == "" or SelectedMutation == "[TIDAK ADA MUTASI]" then return Library:Notify("Tidak ada mutasi valid!") end
            
            CurrentQueue = {}; ItemsProcessed = 0; local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do  
                if isTradeable(tool) then  
                    local m = tool:GetAttribute("Mutation") or tool:GetAttribute("Variant") or (tool:FindFirstChild("Mutation") and tool:FindFirstChild("Mutation").Value)
                    if m and tostring(m) == SelectedMutation then table.insert(CurrentQueue, tool); itemsFound = itemsFound + 1 end
                end  
            end  
            Library:Notify("Sukses! " .. itemsFound .. " Item " .. SelectedMutation .. " masuk antrean.")
        end
    })

    MutationBox:AddButton({
        Text = '🚀 GENERATE ALL BACON MATERIALS',
        Func = function()
            if TargetPlayerName == "" or TargetPlayerName == "Tidak ada player lain" then return Library:Notify("Pilih pembeli dulu!") end
            CurrentQueue = {}; ItemsProcessed = 0; local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do  
                if isTradeable(tool) then  
                    local displayName = getFullItemName(tool)
                    local baseNameOnly = string.split(string.split(displayName, " [")[1], " (Lv")[1]
                    if BaconEventItems[baseNameOnly] or BaconEventItems[displayName] then table.insert(CurrentQueue, tool); itemsFound = itemsFound + 1 end  
                end  
            end  
            Library:Notify("Sukses! " .. itemsFound .. " Bacon Materials masuk antrean.")
        end
    })

    -- Sisi Kanan Tab 1: Custom Basket Mix
    local RightBox = Tabs.Main:AddRightGroupbox('Custom Pack Mix')
    
    local SelectedMixItem = ""
    local SelectedMixQty = 0
    local function getBaseName(dropdownString) return string.split(dropdownString, " | Qty:")[1] or dropdownString end

    RightBox:AddDropdown('ItemDropdown', {
        Values = {"[ANY ASSET]"}, Default = 1, Multi = false, Text = 'Pilih Item',
        Callback = function(Value) SelectedMixItem = getBaseName(Value) end
    })

    RightBox:AddInput('QtyInput', {
        Default = '', Numeric = true, Finished = true, Text = 'Jumlah (Qty)', Placeholder = 'Berapa banyak?',
        Callback = function(Value) SelectedMixQty = tonumber(Value) or 0 end
    })

    local CartStatusLabel = RightBox:AddLabel('🛒 Keranjang kosong.')

    local function updateCartDisplay()
        local text = "🛒 ISI KERANJANG:\n" local total = 0
        for name, qty in pairs(ShoppingCart) do text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end
        if total == 0 then text = "🛒 Keranjang kosong." else text = text .. "Total Item: " .. total end
        CartStatusLabel:SetText(text)
    end

    RightBox:AddButton({
        Text = '➕ Tambah Sesuai Qty',
        Func = function()
            if SelectedMixItem ~= "" and SelectedMixItem ~= "[ANY ASSET]" and SelectedMixQty > 0 then 
                local rs = getRealStock(SelectedMixItem) 
                local cur = ShoppingCart[SelectedMixItem] or 0 
                ShoppingCart[SelectedMixItem] = (cur + SelectedMixQty > rs) and rs or (cur + SelectedMixQty)
                updateCartDisplay() 
            end 
        end
    })

    RightBox:AddButton({Text = '➕ Tambah MAX', Func = function() if SelectedMixItem ~= "" and SelectedMixItem ~= "[ANY ASSET]" then ShoppingCart[SelectedMixItem] = getRealStock(SelectedMixItem); updateCartDisplay() end end})
    RightBox:AddButton({Text = '🗑️ Kosongkan Keranjang', Func = function() ShoppingCart = {}; updateCartDisplay() end})
    
    RightBox:AddButton({
        Text = '🚀 GENERATE QUEUE DARI KERANJANG',
        Func = function()
            if TargetPlayerName == "" or TargetPlayerName == "Tidak ada player lain" then return Library:Notify("Pilih pembeli dulu!") end
            CurrentQueue = {}; ItemsProcessed = 0; local needed = {}; for k,v in pairs(ShoppingCart) do needed[k] = v end
            local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do 
                if isTradeable(tool) then 
                    local name = getFullItemName(tool) 
                    if needed[name] and needed[name] > 0 then table.insert(CurrentQueue, tool); needed[name] = needed[name] - 1; itemsFound = itemsFound + 1 end 
                end 
            end
            Library:Notify("Basket Ready! " .. itemsFound .. " item custom diantrekan.")
        end
    })

    -- ==========================================
    -- TAB 2: SENDER CONTROL PANEL (P1)
    -- ==========================================
    local SenderBox = Tabs.Sender:AddLeftGroupbox('Execution Command')
    local ProgressLabel = SenderBox:AddLabel('⚡ Progress P1:\nSisa Antrean: 0\nTerkirim Sesi Ini: 0')
    local LogLabel = SenderBox:AddLabel('📜 Log Status:\nMenunggu perintah...')

    local function updateProgressUI() 
        ProgressLabel:SetText(string.format("⚡ Progress P1:\nSisa Item Antrean: %d\nTerkirim Sesi Ini: %d", #CurrentQueue, ItemsProcessed)) 
    end
    local function setLog(txt) LogLabel:SetText("📜 Log Status:\n" .. txt) end

    SenderBox:AddSlider('DelaySlider', {
        Text = 'Insert Delay (Detik)', Default = 0.3, Min = 0.1, Max = 1.0, Rounding = 1, Compact = false,
        Callback = function(Value) InsertDelay = Value end
    })

    local function executeSenderBatch()
        if IsProcessing or #CurrentQueue == 0 then return false end
        IsProcessing = true
        
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then setLog("❌ ERROR: Target hilang dari server!"); IsProcessing = false; return false end
        
        setLog("1️⃣ Mengirim Invite ke " .. target.Name .. "...")
        task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)
        
        local tradeFrame = nil
        local timer = 0
        while timer < 15 do
            tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
            if tradeFrame and tradeFrame.Visible then break end
            task.wait(1); timer = timer + 1
        end
        if not (tradeFrame and tradeFrame.Visible) then setLog("❌ ERROR: Timeout Invite!"); IsProcessing = false; return false end
        
        setLog("2️⃣ Memasukkan max 10 item...")
        local batchSize = math.min(10, #CurrentQueue)
        local batch = {}
        for i = 1, batchSize do table.insert(batch, table.remove(CurrentQueue, 1)) end
        for _, tool in ipairs(batch) do
            local guid = getToolGUID(tool)
            if guid then r_trade_i:FireServer("AddItem", tostring(guid)); task.wait(InsertDelay) end
        end
        
        setLog("3️⃣ Lock Fase 1 (Tunggu 5.5s)...")
        task.wait(5.5)
        
        setLog("4️⃣ Accept 1 Dikirim. Menunggu Transisi Layar...")
        r_trade_i:FireServer("Confirm") 
        task.wait(0.5)

        local waitTimeout = 0
        while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do
            if not isLocalConfirmed(tradeFrame) then break end 
            task.wait(0.2); waitTimeout = waitTimeout + 0.2
            if waitTimeout > 60 then setLog("❌ ERROR: Stuck di Transisi!"); IsProcessing = false; return false end
        end

        if tradeFrame and tradeFrame.Parent and tradeFrame.Visible then
            setLog("5️⃣ Transisi Berhasil! Lock Fase 2 (Tunggu 5.5s)...")
            task.wait(5.5)
            
            setLog("6️⃣ Final Confirm! Menyelesaikan Trade...")
            r_trade_i:FireServer("Confirm") 
            
            while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do task.wait(0.5) end
        end
        
        -- Sinkronisasi Tracker Analytics Sesi
        ItemsProcessed = ItemsProcessed + batchSize
        TotalItemsSent = TotalItemsSent + batchSize
        P1TradesCompleted = P1TradesCompleted + 1
        
        updateProgressUI()
        setLog("✅ BATCH SUKSES: " .. batchSize .. " item aman!")
        IsProcessing = false
        return true
    end

    SenderBox:AddButton({Text = '▶️ RUN 1 BATCH SEBAGAI P1', Func = function() task.spawn(executeSenderBatch) end})
    
    SenderBox:AddToggle('AutoLoopToggle', {
        Text = '🔁 ENABLE FULL AUTO LOOP (P1)', Default = false,
        Callback = function(Value)
            AutoLoopEnabled = Value 
            if AutoLoopEnabled then 
                task.spawn(function() 
                    while AutoLoopEnabled do 
                        if #CurrentQueue == 0 then setLog("🏁 Antrean kosong. Loop selesai."); Toggles.AutoLoopToggle:SetValue(false); break end 
                        executeSenderBatch() 
                        task.wait(2.5) 
                    end 
                end) 
            end 
        end
    })

    -- ==========================================
    -- TAB 3: RECEIVER MODE PANEL (P2)
    -- ==========================================
    local ReceiverBox = Tabs.Receiver:AddLeftGroupbox('Universal Receiver Engine')
    ReceiverBox:AddLabel('🤖 Mode Penerima Universal (Gaib):\nMenyadap semua ajakan trade secara otomatis tanpa memilih nama.')
    local ReceiverLogLabel = ReceiverBox:AddLabel('📡 Status P2:\nMenunggu mesin diaktifkan...')

    ReceiverBox:AddToggle('UniversalReceiverToggle', {
        Text = '🤖 ACTIVATE AUTO-ACCEPT ENGINE', Default = false,
        Callback = function(Value)
            AutoReceiverEnabled = Value
            if AutoReceiverEnabled then
                ReceiverLogLabel:SetText("📡 Status P2:\n✅ Engine Aktif! Memantau request...")
                
                task.spawn(function()
                    while AutoReceiverEnabled do
                        local tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
                        
                        -- Penyadap Sinyal Request Masuk
                        if not (tradeFrame and tradeFrame.Visible) then
                            local pGui = localPlayer:FindFirstChild("PlayerGui")
                            if pGui then
                                for _, gui in ipairs(pGui:GetChildren()) do
                                    if gui:IsA("ScreenGui") and gui.Name ~= "Library" then
                                        for _, desc in ipairs(gui:GetDescendants()) do
                                            if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and desc.Visible then
                                                local text = string.lower(desc:IsA("TextButton") and desc.Text or desc.Name)
                                                if string.find(text, "accept") or string.find(text, "yes") or string.find(text, "trade") then
                                                    pcall(function()
                                                        if getconnections then
                                                            local c = getconnections(desc.MouseButton1Click)
                                                            if c then for _, conn in ipairs(c) do pcall(function() conn:Fire() end) end end
                                                        end
                                                        if firesignal then firesignal(desc.MouseButton1Click) end
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
                            task.wait(1)
                        else
                            -- Alur Penguncian Otomatis God-Sync P2
                            ReceiverLogLabel:SetText("📡 Status P2:\n📥 UI Terbuka! Menunggu P1 Accept...")
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            
                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                                ReceiverLogLabel:SetText("📡 Status P2:\n🔒 P1 Accept. Lock Fase 1 (5.5 detik)...")
                                task.wait(5.5)
                                r_trade_i:FireServer("Confirm")
                                task.wait(1) 
                            end

                            ReceiverLogLabel:SetText("📡 Status P2:\n⏳ Menunggu transisi layar ke Final...")
                            while tradeFrame.Visible and isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end

                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                                ReceiverLogLabel:SetText("📡 Status P2:\n🔒 Masuk Final. Lock Fase 2 (5.5 detik)...")
                                task.wait(5.5)
                                r_trade_i:FireServer("Confirm")
                            end

                            ReceiverLogLabel:SetText("📡 Status P2:\n✅ Menyelesaikan transaksi...")
                            while tradeFrame.Visible do task.wait(0.5) end
                            
                            P2TradesCompleted = P2TradesCompleted + 1
                            ReceiverLogLabel:SetText("📡 Status P2:\n✅ Transaksi Sukses! Standby kembali...")
                        end
                    end
                end)
            else
                ReceiverLogLabel:SetText("📡 Status P2:\n❌ Engine Non-aktif.")
            end
        end
    })

    -- ==========================================
    -- TAB 4: LIVE DASHBOARD & DATABASE INVENTORY
    -- ==========================================
    local DashBox = Tabs.Analytics:AddLeftGroupbox('Live Statistics Command Center')
    local LiveStatsLabel = DashBox:AddLabel('Memuat data statistik...')
    
    -- Loop Refresh Indikator Analitik Real-Time
    task.spawn(function()
        while task.wait(1) do
            local currentUptime = tick() - SessionStartTime
            local statsText = string.format(
                "⏱️ SESSION UPTIME:  %s\n\n" ..
                "📈 SUCCESS P1 TRADES:  %d\n" ..
                "📥 SUCCESS P2 TRADES:  %d\n" ..
                "📦 TOTAL ITEMS MOVED:  %d",
                formatTime(currentUptime),
                P1TradesCompleted,
                P2TradesCompleted,
                TotalItemsSent
            )
            LiveStatsLabel:SetText(statsText)
        end
    end)

    local InvBox = Tabs.Analytics:AddRightGroupbox('Database Management')
    
    InvBox:AddToggle('CleanUIToggle', {
        Text = '👁️ Clean UI Mode (Anti-Lag)', Default = false,
        Callback = function(Value)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not Value)
            local pGui = localPlayer:WaitForChild("PlayerGui")  
            for _, gui in ipairs(pGui:GetChildren()) do  
                if gui:IsA("ScreenGui") and gui.Name ~= "Library" then  
                    if Value then gui:SetAttribute("WasEnabled", gui.Enabled); gui.Enabled = false  
                    else gui.Enabled = gui:GetAttribute("WasEnabled") or true end  
                end  
            end  
        end
    })

    local FullInventoryLabel = InvBox:AddLabel('Menyinkronkan data tas...')

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
        
        -- Pembaruan Elemen Dropdown Dinamis di LinoriaLib
        local itemsList = {"[ANY ASSET]"}  
        for name, count in pairs(inventoryData) do table.insert(itemsList, name .. " | Qty: " .. count) end  
        table.sort(itemsList, function(a, b) if a == "[ANY ASSET]" then return true end if b == "[ANY ASSET]" then return false end return a < b end)  
        
        Options.ItemDropdown:SetValues(itemsList)
        Options.MutationDropdown:SetValues(getMutationList())
        Options.PlayerDropdown:SetValues(getPlayerList())
        
        local displayString = "TOTAL TRADABLE: " .. totalCount .. "\n\n"  
        if totalCount == 0 then 
            displayString = displayString .. "Tas kosong melompong." 
        else
            local categorizedItems = {}
            for itemName, amount in pairs(inventoryData) do
                local category = "📦 NORMAL ASSETS"
                local mutMatch = string.match(itemName, "%[(.-)%]")
                local baseNameOnly = string.split(string.split(itemName, " [")[1], " (Lv")[1]
                
                if BaconEventItems[baseNameOnly] or BaconEventItems[itemName] then category = "🥓 BACON MATERIALS"
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
                for _, item in ipairs(categorizedItems[cat]) do displayString = displayString .. string.format(" • %s (x%d)\n", item.name, item.qty) end
                displayString = displayString .. "\n"
            end
        end
        FullInventoryLabel:SetText(displayString)
    end

    InvBox:AddButton({Text = '🔄 Refresh Database System', Func = function() updateInventoryDisplay() end})

    -- Sinkronisasi Otomatis saat Item Bertambah/Berkurang
    local function connectInventory()
        local backpack = localPlayer:WaitForChild("Backpack")
        table.insert(InventoryConnections, backpack.ChildAdded:Connect(updateInventoryDisplay))
        table.insert(InventoryConnections, backpack.ChildRemoved:Connect(updateInventoryDisplay))
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        table.insert(InventoryConnections, char.ChildAdded:Connect(updateInventoryDisplay))
        table.insert(InventoryConnections, char.ChildRemoved:Connect(updateInventoryDisplay))
        localPlayer.CharacterAdded:Connect(function(newChar)
            table.insert(InventoryConnections, newChar.ChildAdded:Connect(updateInventoryDisplay))
            table.insert(InventoryConnections, newChar.CharacterRemoved:Connect(updateInventoryDisplay))
        end)
        task.wait(0.5)
        updateInventoryDisplay()
    end
    
    -- Juru Kunci UI & Event Binding
    ThemeManager:SetLibrary(Library)
    ThemeManager:ApplyToTab(Tabs.Analytics)
    connectInventory()

end)

if not success then
    warn("MOCTA LINORIA EXTENSION ERROR: " .. tostring(errorMessage))
    if not game:IsLoaded() then game.Loaded:Wait() end
    pcall(function() StarterGui:SetCore("SendNotification", {Title = "🚨 Fatal Error", Text = tostring(errorMessage), Duration = 10}) end)
end
