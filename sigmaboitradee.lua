-- ==========================================================
-- MOCTA TRADE & SELL AUTOMATIC V18.15 (SAFE CART EDITION)
-- Build: Sell Cart System, Real-Time Deduction, No Sell-All
-- ==========================================================

local SCRIPT_URL = "https://raw.githubusercontent.com/xyaxzj/sigmamaboi.lua/refs/heads/main/sigmaboitradee.lua"

local success, errorMessage = pcall(function()
    
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local StarterGui = game:GetService("StarterGui")
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    -- ==========================================
    -- LOKASI REMOTES
    -- ==========================================
    local networkFolder = ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
    local f_trade_r = networkFolder:WaitForChild("ref_trade_r", 5) 
    local r_trade_i = networkFolder:WaitForChild("rev_trade_i", 5) 
    local rev_trade_start = networkFolder:WaitForChild("rev_trade_start", 5) 

    local ref_B_Sell = nil
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "ref_B_Sell" and v:IsA("RemoteFunction") then
            ref_B_Sell = v
            break
        end
    end

    -- ==========================================
    -- VARIABEL SISTEM
    -- ==========================================
    local TargetPlayerName = ""
    local ShoppingCart = {} 
    local CurrentQueue = {}
    
    local ItemsProcessed = 0
    local IsProcessing = false 
    local AutoLoopEnabled = false
    local AutoReceiverEnabled = false
    local InsertDelay = 0.3 
    local InventoryConnections = {}

    local SessionStartTime = tick()
    local P1TradesCompleted = 0
    local P2TradesCompleted = 0
    local TotalItemsSent = 0
    
    local SentAssetsRecord = {} 
    local TradeHistoryString = "Belum ada riwayat transaksi."

    -- Variabel Smart Sell
    local SelectedSellItems = {}
    local SellCart = {}
    local SelectedSellMixQty = 0
    local AutoSellEnabled = false
    local SellToggle

    -- ==========================================
    -- FUNGSI INTI & INVENTORY SCANNER
    -- ==========================================
    local function parseMultiSelect(payload)
        local results = {}
        if type(payload) == "table" then
            for k, v in pairs(payload) do
                if type(k) == "number" and type(v) == "string" then table.insert(results, v)
                elseif type(k) == "string" and v == true then table.insert(results, k) end
            end
        elseif type(payload) == "string" then table.insert(results, payload) end
        return results
    end

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
    
    local function isTradeable(tool) return tool and tool:IsA("Tool") and getToolGUID(tool) ~= nil end
    
    local function getPlayerList()
        local tbl = {}
        for _, p in ipairs(Players:GetPlayers()) do 
            if p ~= localPlayer then table.insert(tbl, p.Name) end 
        end
        return tbl
    end

    local function getMutationList()
        local mutCounts = {}
        local hasMut = false
        for _, tool in ipairs(getAllTools()) do
            if isTradeable(tool) then
                local m = tool:GetAttribute("Mutation") or tool:GetAttribute("Variant") or (tool:FindFirstChild("Mutation") and tool:FindFirstChild("Mutation").Value)
                if m then 
                    m = tostring(m)
                    mutCounts[m] = (mutCounts[m] or 0) + 1
                    hasMut = true 
                end
            end
        end
        local list = {}
        if not hasMut then return {"[TIDAK ADA MUTASI]"} end
        for k, v in pairs(mutCounts) do table.insert(list, k .. " | Stok: " .. v) end
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

    local function getBaseName(dropdownString) return string.split(dropdownString, " | Stok:")[1] or dropdownString end

    local updateInventoryDisplay

    -- ==========================================
    -- RAYFIELD WINDOW INITIALIZATION
    -- ==========================================
    local Window = Rayfield:CreateWindow({
        Name = "Mocta Ultimate Hub", 
        LoadingTitle = "Memuat sistem, harap tunggu...", 
        ConfigurationSaving = { Enabled = false }, 
        Theme = "DarkBlue"
    })

    -- ==========================================
    -- TAB 1: CART SETUP (TRADE)
    -- ==========================================
    local TabCart = Window:CreateTab("🛒 Trade Cart", 4483362458)
    
    local PlayerDropdown = TabCart:CreateDropdown({
        Name = "Target Penerima (P2)", Options = getPlayerList(), CurrentOption = {""}, MultipleOptions = false, 
        Callback = function() end 
    })

    TabCart:CreateSection("Kirim Semua (Massal)")
    TabCart:CreateButton({
        Name = "Masukkan Semua Barang ke Antrean",
        Callback = function()
            local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Perhatian", Content = "Harap pilih target penerima terlebih dahulu.", Duration = 2}) end
            CurrentQueue = {}; ItemsProcessed = 0; local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do  
                if isTradeable(tool) then table.insert(CurrentQueue, tool); itemsFound = itemsFound + 1 end  
            end  
            Rayfield:Notify({Title = "Berhasil", Content = itemsFound .. " barang telah masuk ke antrean.", Duration = 2})
        end
    })

    TabCart:CreateSection("Filter Berdasarkan Mutasi")
    local MutationDropdown = TabCart:CreateDropdown({
        Name = "Pilih Mutasi (Bisa pilih lebih dari satu)", Options = getMutationList(), CurrentOption = {}, MultipleOptions = true, 
        Callback = function() end
    })
    
    TabCart:CreateButton({
        Name = "Masukkan Mutasi Terpilih ke Antrean",
        Callback = function()
            local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Perhatian", Content = "Harap pilih target penerima terlebih dahulu.", Duration = 2}) end
            
            local liveSelectedMutations = MutationDropdown.CurrentOption
            if type(liveSelectedMutations) ~= "table" then liveSelectedMutations = {liveSelectedMutations} end
            
            local targetMuts = {}
            local hasValid = false
            for _, optionStr in pairs(liveSelectedMutations) do
                if type(optionStr) == "string" and optionStr ~= "[TIDAK ADA MUTASI]" and optionStr ~= "" then
                    local baseMut = getBaseName(optionStr)
                    if baseMut then targetMuts[baseMut] = true; hasValid = true end
                end
            end

            if not hasValid then return Rayfield:Notify({Title = "Perhatian", Content = "Harap pilih minimal satu mutasi yang valid.", Duration = 2}) end
            
            CurrentQueue = {}; ItemsProcessed = 0; local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do  
                if isTradeable(tool) then  
                    local m = tool:GetAttribute("Mutation") or tool:GetAttribute("Variant") or (tool:FindFirstChild("Mutation") and tool:FindFirstChild("Mutation").Value)
                    if m and targetMuts[tostring(m)] then 
                        table.insert(CurrentQueue, tool)
                        itemsFound = itemsFound + 1 
                    end
                end  
            end  
            Rayfield:Notify({Title = "Berhasil", Content = itemsFound .. " barang mutasi siap dikirim.", Duration = 2})
        end
    })

    TabCart:CreateSection("Buat Paket Custom")
    local SelectedMixQty = 0
    local ItemDropdown = TabCart:CreateDropdown({
        Name = "Pilih Barang (Bisa pilih lebih dari satu)", Options = {"[ANY ASSET]"}, CurrentOption = {}, MultipleOptions = true, 
        Callback = function() end
    })
    
    TabCart:CreateInput({
        Name = "Jumlah barang yang ingin dikirim:", PlaceholderText = "Masukkan jumlah...", RemoveTextAfterFocusLost = false, 
        Callback = function(Text) SelectedMixQty = tonumber(Text) or 0 end
    })
    
    local CartStatus = TabCart:CreateParagraph({Title = "Isi Keranjang Trade", Content = "Keranjang masih kosong."})

    local function updateCartDisplay()
        local text = ""; local total = 0
        for name, qty in pairs(ShoppingCart) do text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end
        if total == 0 then text = "Keranjang masih kosong." else text = text .. "\nTotal Item: " .. total end
        CartStatus:Set({Title = "Isi Keranjang Trade", Content = text})
    end

    TabCart:CreateButton({
        Name = "➕ Tambah Sesuai Jumlah", 
        Callback = function() 
            local liveSelectedItems = ItemDropdown.CurrentOption
            if type(liveSelectedItems) ~= "table" then liveSelectedItems = {liveSelectedItems} end
            
            local addedItems = 0
            if SelectedMixQty > 0 then 
                for _, optionStr in pairs(liveSelectedItems) do
                    if type(optionStr) == "string" then
                        local itemName = getBaseName(optionStr)
                        if itemName ~= "" and itemName ~= "[ANY ASSET]" then
                            local rs = getRealStock(itemName) 
                            local cur = ShoppingCart[itemName] or 0 
                            ShoppingCart[itemName] = (cur + SelectedMixQty > rs) and rs or (cur + SelectedMixQty)
                            addedItems = addedItems + 1
                        end
                    end
                end
                if addedItems > 0 then updateCartDisplay() else Rayfield:Notify({Title = "Gagal", Content = "Harap centang minimal satu barang pada daftar.", Duration = 3}) end
            else
                Rayfield:Notify({Title = "Gagal", Content = "Jumlah barang harus lebih dari 0.", Duration = 3})
            end 
        end
    })
    
    TabCart:CreateButton({
        Name = "➕ Tambah Semua Stok (Maksimal)", 
        Callback = function() 
            local liveSelectedItems = ItemDropdown.CurrentOption
            if type(liveSelectedItems) ~= "table" then liveSelectedItems = {liveSelectedItems} end
            
            local addedItems = 0
            for _, optionStr in pairs(liveSelectedItems) do
                if type(optionStr) == "string" then
                    local itemName = getBaseName(optionStr)
                    if itemName ~= "" and itemName ~= "[ANY ASSET]" then
                        ShoppingCart[itemName] = getRealStock(itemName)
                        addedItems = addedItems + 1
                    end
                end
            end
            if addedItems > 0 then updateCartDisplay() else Rayfield:Notify({Title = "Gagal", Content = "Harap centang minimal satu barang.", Duration = 3}) end 
        end
    })
    
    TabCart:CreateButton({Name = "🗑️ Kosongkan Keranjang", Callback = function() ShoppingCart = {}; updateCartDisplay() end})

    TabCart:CreateButton({
        Name = "🚀 Buat Antrean dari Keranjang", 
        Callback = function() 
            local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Perhatian", Content = "Harap pilih target penerima terlebih dahulu.", Duration = 2}) end
            
            CurrentQueue = {}; ItemsProcessed = 0; local needed = {}; for k,v in pairs(ShoppingCart) do needed[k] = v end
            local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do 
                if isTradeable(tool) then 
                    local name = getFullItemName(tool) 
                    if needed[name] and needed[name] > 0 then table.insert(CurrentQueue, tool); needed[name] = needed[name] - 1; itemsFound = itemsFound + 1 end 
                end 
            end
            Rayfield:Notify({Title = "Berhasil", Content = itemsFound .. " barang dari keranjang masuk ke antrean.", Duration = 2})
        end
    })

    -- ==========================================
    -- TAB 2: INVENTORY MANAGER
    -- ==========================================
    local TabInventory = Window:CreateTab("🎒 Tas & Stok", 4483362458)
    TabInventory:CreateSection("Daftar Barang (Live)")
    local FullInventoryLabel = TabInventory:CreateParagraph({Title = "Daftar Barang & Total", Content = "Menyinkronkan data tas..."})
    TabInventory:CreateButton({Name = "🔄 Update Manual Data Tas", Callback = function() updateInventoryDisplay() end})

    -- ==========================================
    -- TAB 3: SMART SELL (KERANJANG JUAL)
    -- ==========================================
    local TabSell = Window:CreateTab("💰 Jual Cerdas", 4483362458)
    
    if not ref_B_Sell then
        TabSell:CreateParagraph({Title = "⚠️ Peringatan", Content = "Remote 'ref_B_Sell' tidak ditemukan. Pastikan game sudah memuat sepenuhnya."})
    end

    TabSell:CreateSection("1. Pilih Barang untuk Dijual")
    
    local SellItemDropdown = TabSell:CreateDropdown({
        Name = "Pilih Item (Bisa pilih lebih dari satu)", Options = {"[ANY ASSET]"}, CurrentOption = {}, MultipleOptions = true, 
        Flag = "SmartSellDrop",
        Callback = function(Options) SelectedSellItems = Options end,
    })

    TabSell:CreateInput({
        Name = "Jumlah barang yang ingin dijual:", PlaceholderText = "Masukkan jumlah...", RemoveTextAfterFocusLost = false,
        Callback = function(Text) SelectedSellMixQty = tonumber(Text) or 0 end
    })

    local SellCartStatus = TabSell:CreateParagraph({Title = "🛒 Keranjang Jual", Content = "Keranjang jual masih kosong."})

    local function updateSellCartDisplay()
        local text = ""; local total = 0
        for name, qty in pairs(SellCart) do 
            if qty > 0 then
                text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty 
            end
        end
        if total == 0 then text = "Keranjang jual masih kosong." else text = text .. "\nTotal Item: " .. total end
        SellCartStatus:Set({Title = "🛒 Keranjang Jual", Content = text})
    end

    TabSell:CreateButton({
        Name = "➕ Tambah Sesuai Jumlah", 
        Callback = function() 
            local liveSelectedItems = SelectedSellItems
            if type(liveSelectedItems) ~= "table" then liveSelectedItems = {liveSelectedItems} end
            
            local addedItems = 0
            if SelectedSellMixQty > 0 then 
                for _, optionStr in pairs(liveSelectedItems) do
                    if type(optionStr) == "string" then
                        local itemName = getBaseName(optionStr)
                        if itemName ~= "" and itemName ~= "[ANY ASSET]" then
                            local rs = getRealStock(itemName) 
                            local cur = SellCart[itemName] or 0 
                            SellCart[itemName] = (cur + SelectedSellMixQty > rs) and rs or (cur + SelectedSellMixQty)
                            addedItems = addedItems + 1
                        end
                    end
                end
                if addedItems > 0 then updateSellCartDisplay() else Rayfield:Notify({Title = "Gagal", Content = "Harap centang minimal satu barang.", Duration = 3}) end
            else
                Rayfield:Notify({Title = "Gagal", Content = "Jumlah barang harus lebih dari 0.", Duration = 3})
            end 
        end
    })

    TabSell:CreateButton({
        Name = "➕ Tambah Semua Stok (Maksimal)", 
        Callback = function() 
            local liveSelectedItems = SelectedSellItems
            if type(liveSelectedItems) ~= "table" then liveSelectedItems = {liveSelectedItems} end
            
            local addedItems = 0
            for _, optionStr in pairs(liveSelectedItems) do
                if type(optionStr) == "string" then
                    local itemName = getBaseName(optionStr)
                    if itemName ~= "" and itemName ~= "[ANY ASSET]" then
                        SellCart[itemName] = getRealStock(itemName)
                        addedItems = addedItems + 1
                    end
                end
            end
            if addedItems > 0 then updateSellCartDisplay() else Rayfield:Notify({Title = "Gagal", Content = "Harap centang minimal satu barang.", Duration = 3}) end 
        end
    })

    TabSell:CreateButton({Name = "🗑️ Kosongkan Keranjang Jual", Callback = function() SellCart = {}; updateSellCartDisplay() end})

    TabSell:CreateSection("2. Eksekusi Penjualan")

    local function processSmartSell()
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local backpack = localPlayer:FindFirstChild("Backpack")

        if not humanoid or not backpack or not ref_B_Sell then return false end

        local allTools = getAllTools() 
        local itemsToProcess = {}

        -- Menyalin keranjang agar bisa dilacak
        local tempCart = {}
        for k,v in pairs(SellCart) do tempCart[k] = v end

        for _, tool in ipairs(allTools) do
            if isTradeable(tool) then
                local name = getFullItemName(tool)
                if tempCart[name] and tempCart[name] > 0 then
                    table.insert(itemsToProcess, tool)
                    tempCart[name] = tempCart[name] - 1
                end
            end
        end

        for _, toolToSell in ipairs(itemsToProcess) do
            local toolName = getFullItemName(toolToSell)
            
            -- Pengecekan real-time sebelum menjual
            if not SellCart[toolName] or SellCart[toolName] <= 0 then continue end

            if toolToSell.Parent == backpack then
                humanoid:EquipTool(toolToSell)
                task.wait(0.15) 
            end

            local didSell = pcall(function() return ref_B_Sell:InvokeServer() end)
            if didSell then 
                -- Update keranjang UI secara live!
                if SellCart[toolName] then
                    SellCart[toolName] = SellCart[toolName] - 1
                end
            end
            task.wait(0.1) 
        end
        
        updateSellCartDisplay()
        local totalLeft = 0
        for _, qty in pairs(SellCart) do totalLeft = totalLeft + qty end
        if totalLeft <= 0 then return true end 

        return false
    end

    SellToggle = TabSell:CreateToggle({
        Name = "🧠 Nyalakan Bot Jual", CurrentValue = false,
        Callback = function(Value)
            AutoSellEnabled = Value
            if AutoSellEnabled then
                local totalLeft = 0
                for _, qty in pairs(SellCart) do totalLeft = totalLeft + qty end
                if totalLeft <= 0 then
                    Rayfield:Notify({Title = "⚠️ Gagal", Content = "Keranjang Jual kosong! Tambahkan barang terlebih dahulu.", Duration = 3})
                    if SellToggle then SellToggle:Set(false) end
                    return
                end

                task.spawn(function()
                    while AutoSellEnabled do
                        local limitReached = processSmartSell()
                        if limitReached then
                            Rayfield:Notify({Title = "✅ Selesai!", Content = "Semua target penjualan telah berhasil dilebur menjadi koin.", Duration = 4})
                            if SellToggle then SellToggle:Set(false) end
                            break
                        end
                        task.wait(0.5) 
                    end
                end)
            end
        end
    })

    -- ==========================================
    -- TAB 4: AUTO DISPATCHER (P1)
    -- ==========================================
    local TabDispatch = Window:CreateTab("📤 Pengirim (P1)", 4483362458)
    local LiveProgress = TabDispatch:CreateParagraph({Title = "Status Pengiriman", Content = "Sisa Antrean: 0\nSukses Terkirim: 0"})
    local ActionLog = TabDispatch:CreateParagraph({Title = "Log Proses", Content = "Menunggu perintah..."})

    local function updateProgressUI() LiveProgress:Set({Title = "Status Pengiriman", Content = string.format("Sisa Antrean: %d\nSukses Terkirim: %d", #CurrentQueue, ItemsProcessed)}) end
    local function setLog(txt) ActionLog:Set({Title = "Log Proses", Content = txt}) end

    TabDispatch:CreateSlider({Name = "Jeda Input Barang (Detik)", Range = {0.1, 1.0}, Increment = 0.1, CurrentValue = 0.3, Callback = function(Value) InsertDelay = Value end})

    local function executeSenderBatch()
        if IsProcessing or #CurrentQueue == 0 then return false end
        
        local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then setLog("❌ Target tidak ditemukan di server!"); return false end
        
        IsProcessing = true
        setLog("1️⃣ Mengirim permintaan trade ke " .. target.Name .. "...")
        task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)
        
        local tradeFrame = nil
        local timer = 0
        while timer < 15 do
            tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
            if tradeFrame and tradeFrame.Visible then break end
            task.wait(1); timer = timer + 1
        end
        if not (tradeFrame and tradeFrame.Visible) then setLog("❌ Timeout, target tidak merespons."); IsProcessing = false; return false end
        
        setLog("2️⃣ Memasukkan barang...")
        local batchSize = math.min(10, #CurrentQueue)
        local batch = {}
        local itemNamesTbl = {} 
        
        for i = 1, batchSize do 
            local tool = table.remove(CurrentQueue, 1)
            table.insert(batch, tool)
            table.insert(itemNamesTbl, getFullItemName(tool))
        end
        
        for _, tool in ipairs(batch) do
            local guid = getToolGUID(tool)
            if guid then r_trade_i:FireServer("AddItem", tostring(guid)); task.wait(InsertDelay) end
        end
        
        setLog("3️⃣ Menunggu cooldown tahap 1...")
        task.wait(5.5)
        
        setLog("4️⃣ Konfirmasi awal...")
        r_trade_i:FireServer("Confirm") 
        task.wait(0.5)

        local waitTimeout = 0
        while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do
            if not isLocalConfirmed(tradeFrame) then break end 
            task.wait(0.2); waitTimeout = waitTimeout + 0.2
            if waitTimeout > 60 then setLog("❌ Terjebak di transisi!"); IsProcessing = false; return false end
        end

        if tradeFrame and tradeFrame.Parent and tradeFrame.Visible then
            setLog("5️⃣ Menunggu cooldown akhir...")
            task.wait(5.5)
            setLog("6️⃣ Konfirmasi terakhir!")
            r_trade_i:FireServer("Confirm") 
            while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do task.wait(0.5) end
        end
        
        P1TradesCompleted = P1TradesCompleted + 1
        ItemsProcessed = ItemsProcessed + batchSize
        TotalItemsSent = TotalItemsSent + batchSize
        
        for _, name in ipairs(itemNamesTbl) do SentAssetsRecord[name] = (SentAssetsRecord[name] or 0) + 1 end
        
        local historyLines = {}
        for name, qty in pairs(SentAssetsRecord) do table.insert(historyLines, string.format(" • %s (x%d)", name, qty)) end
        table.sort(historyLines)
        
        TradeHistoryString = string.format("Dikirim ke: %s\n\nTotal Barang Terkirim:\n%s", TargetPlayerName, table.concat(historyLines, "\n"))
        HistoryLogLabel:Set({Title = "Riwayat Transaksi (P1)", Content = TradeHistoryString})
        updateProgressUI()
        setLog("✅ Transaksi selesai! " .. batchSize .. " barang terkirim.")
        IsProcessing = false
        return true
    end

    TabDispatch:CreateButton({Name = "▶️ Kirim 1 Kloter Sekarang", Callback = function() task.spawn(executeSenderBatch) end})
    TabDispatch:CreateToggle({
        Name = "🔁 Mode Otomatis (Auto-Loop)", CurrentValue = false, 
        Callback = function(Value) 
            AutoLoopEnabled = Value 
            if AutoLoopEnabled then 
                task.spawn(function() 
                    while AutoLoopEnabled do 
                        if #CurrentQueue == 0 then setLog("🛑 Selesai. Antrean kosong."); AutoLoopEnabled = false; break end 
                        executeSenderBatch() 
                        task.wait(2.5) 
                    end 
                end) 
            end 
        end
    })

    -- ==========================================
    -- TAB 5: INBOUND ENGINE (P2)
    -- ==========================================
    local TabInbound = Window:CreateTab("📥 Penerima (P2)", 4483362458)
    local ReceiverLog = TabInbound:CreateParagraph({Title = "Status Penerima", Content = "Sedang tidak aktif."})

    TabInbound:CreateToggle({
        Name = "🤖 Aktifkan Auto-Accept", CurrentValue = false,
        Callback = function(Value)
            AutoReceiverEnabled = Value
            if AutoReceiverEnabled then
                ReceiverLog:Set({Title = "Status Penerima", Content = "🟢 Aktif! Menunggu permintaan..."})
                task.spawn(function()
                    while AutoReceiverEnabled do
                        local tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
                        
                        if not (tradeFrame and tradeFrame.Visible) then
                            local pGui = localPlayer:FindFirstChild("PlayerGui")
                            if pGui then
                                for _, gui in ipairs(pGui:GetChildren()) do
                                    if gui:IsA("ScreenGui") and gui.Name ~= "Rayfield" then
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
                            ReceiverLog:Set({Title = "Status Penerima", Content = "📥 Menunggu konfirmasi pengirim..."})
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            
                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                                ReceiverLog:Set({Title = "Status Penerima", Content = "🔒 Konfirmasi diterima. Cooldown tahap 1..."})
                                task.wait(5.5)
                                r_trade_i:FireServer("Confirm")
                                task.wait(1) 
                            end

                            ReceiverLog:Set({Title = "Status Penerima", Content = "⏳ Menunggu layar transisi..."})
                            while tradeFrame.Visible and isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end

                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                                ReceiverLog:Set({Title = "Status Penerima", Content = "🔒 Cooldown tahap 2..."})
                                task.wait(5.5)
                                r_trade_i:FireServer("Confirm")
                            end

                            ReceiverLog:Set({Title = "Status Penerima", Content = "✅ Menyelesaikan transaksi..."})
                            while tradeFrame.Visible do task.wait(0.5) end
                            
                            P2TradesCompleted = P2TradesCompleted + 1
                            ReceiverLog:Set({Title = "Status Penerima", Content = "✅ Transaksi selesai! Kembali siaga..."})
                        end
                    end
                end)
            else
                ReceiverLog:Set({Title = "Status Penerima", Content = "❌ Dimatikan."})
            end
        end,
    })

    -- ==========================================
    -- TAB 6: ANALYTICS & LOGS
    -- ==========================================
    local TabAnalytics = Window:CreateTab("📊 Info & Riwayat", 4483362458)
    
    local AnalyticsLabel = TabAnalytics:CreateParagraph({Title = "Rangkuman Sesi", Content = "Sedang menghitung..."})
    task.spawn(function()
        while task.wait(1) do
            local currentUptime = tick() - SessionStartTime
            local statsText = string.format(
                "⏱️ Waktu Aktif Sesi: %s\n" ..
                "📤 Total Transaksi Pengirim (P1): %d kloter\n" ..
                "📥 Total Transaksi Penerima (P2): %d kloter\n" ..
                "📦 Total Barang Diproses: %d item",
                formatTime(currentUptime), P1TradesCompleted, P2TradesCompleted, TotalItemsSent
            )
            AnalyticsLabel:Set({Title = "Rangkuman Sesi", Content = statsText})
        end
    end)

    HistoryLogLabel = TabAnalytics:CreateParagraph({Title = "Riwayat Transaksi (P1)", Content = TradeHistoryString})

    -- ==========================================
    -- TAB 7: SYSTEM SETTINGS
    -- ==========================================
    local TabSettings = Window:CreateTab("⚙️ Pengaturan", 4483362458)

    TabSettings:CreateSection("Perbarui Sistem")
    TabSettings:CreateButton({
        Name = "🔄 Perbarui Script ke Versi Terbaru", 
        Callback = function() 
            if SCRIPT_URL == "" then
                Rayfield:Notify({Title = "Kesalahan", Content = "URL GitHub belum diatur.", Duration = 4})
                return
            end
            Rayfield:Notify({Title = "Memperbarui...", Content = "Sedang mengambil script terbaru dari GitHub...", Duration = 2})
            task.wait(1.5)
            Rayfield:Destroy() 
            task.wait(0.5)
            loadstring(game:HttpGet(SCRIPT_URL))()
        end
    })

    TabSettings:CreateSection("Optimasi Performa")
    TabSettings:CreateToggle({
        Name = "👁️ Mode Layar Bersih (Sembunyikan UI Game)", 
        CurrentValue = false,
        Callback = function(Value)
            local pGui = localPlayer:WaitForChild("PlayerGui")
            if Value then
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
                RunService:BindToRenderStep("MoctaAggressiveCleanUI", 1, function()
                    for _, gui in ipairs(pGui:GetChildren()) do
                        if gui:IsA("ScreenGui") and gui.Name ~= "Rayfield" and gui.Enabled then
                            gui:SetAttribute("WasEnabled", true)
                            gui.Enabled = false
                        end
                    end
                end)
            else
                RunService:UnbindFromRenderStep("MoctaAggressiveCleanUI")
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
                for _, gui in ipairs(pGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and gui.Name ~= "Rayfield" then
                        if gui:GetAttribute("WasEnabled") then
                            task.spawn(function()
                                task.wait(0.5) 
                                gui.Enabled = true
                                gui:SetAttribute("WasEnabled", nil)
                            end)
                        end
                    end
                end
            end
        end,
    })

    -- ==========================================
    -- INVENTORY SYNC ENGINE (Master Controller)
    -- ==========================================
    updateInventoryDisplay = function()
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
        for name, count in pairs(inventoryData) do table.insert(itemsList, name .. " | Stok: " .. count) end  
        table.sort(itemsList, function(a, b) if a == "[ANY ASSET]" then return true end if b == "[ANY ASSET]" then return false end return a < b end)  
        
        -- Sinkronisasi list ke semua dropdown (Trade & Sell)
        ItemDropdown:Refresh(itemsList)
        SellItemDropdown:Refresh(itemsList)
        MutationDropdown:Refresh(getMutationList()) 
        PlayerDropdown:Refresh(getPlayerList())
        
        local displayString = "Total Semua Barang: " .. totalCount .. "\n\n"  
        if totalCount == 0 then displayString = displayString .. "Tidak ada barang yang ditemukan." else
            local categorizedItems = {}
            local categoryTotals = {}
            
            for itemName, amount in pairs(inventoryData) do
                local category = "📦 BARANG STANDAR"
                local mutMatch = string.match(itemName, "%[(.-)%]")
                
                if mutMatch then category = "✨ " .. string.upper(mutMatch) end
                
                if not categorizedItems[category] then 
                    categorizedItems[category] = {} 
                    categoryTotals[category] = 0
                end
                table.insert(categorizedItems[category], {name = itemName, qty = amount})
                categoryTotals[category] = categoryTotals[category] + amount
            end
            
            local sortedCategories = {}
            for cat, _ in pairs(categorizedItems) do table.insert(sortedCategories, cat) end
            table.sort(sortedCategories)
            
            for _, cat in ipairs(sortedCategories) do
                displayString = displayString .. "=== " .. cat .. " (Total: " .. categoryTotals[cat] .. ") ===\n"
                table.sort(categorizedItems[cat], function(a, b) return a.name < b.name end)
                for _, item in ipairs(categorizedItems[cat]) do 
                    displayString = displayString .. string.format(" • %s  (Stok: %d)\n", item.name, item.qty) 
                end
                displayString = displayString .. "\n"
            end
        end
        FullInventoryLabel:Set({Title = "Daftar Barang & Total", Content = displayString})
    end

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
    pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Terjadi Kesalahan", Text = tostring(errorMessage), Duration = 20}) end)
end
