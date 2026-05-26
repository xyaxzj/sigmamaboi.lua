-- ==========================================================
-- MOCTA TRADE AUTOMATOR V18.13 (CHILL UI EDITION)
-- Build: Bahasa Santai, Ramah Pemula, Logika Anti-Bug
-- ==========================================================

local SCRIPT_URL = "https://raw.githubusercontent.com/xyaxzj/sigmamaboi.lua/refs/heads/main/sigmaboitradee.lua"

local success, errorMessage = pcall(function()
    
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local StarterGui = game:GetService("StarterGui")
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")

    local networkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
    local f_trade_r = networkFolder:WaitForChild("ref_trade_r", 5) 
    local r_trade_i = networkFolder:WaitForChild("rev_trade_i", 5) 
    local rev_trade_start = networkFolder:WaitForChild("rev_trade_start", 5) 

    local TargetPlayerName = ""
    local SelectedMutations = {}
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
    local TradeHistoryString = "Belum ada riwayat ngirim barang nih."

    local function parseMultiSelect(payload)
        local results = {}
        if type(payload) == "table" then
            for k, v in pairs(payload) do
                if type(k) == "number" and type(v) == "string" then
                    table.insert(results, v)
                elseif type(k) == "string" and v == true then
                    table.insert(results, k)
                end
            end
        elseif type(payload) == "string" then
            table.insert(results, payload)
        end
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
        for k, v in pairs(mutCounts) do 
            table.insert(list, k .. " | Stok: " .. v) 
        end
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
    -- RAYFIELD WINDOW INITIALIZATION
    -- ==========================================
    local Window = Rayfield:CreateWindow({
        Name = "Mocta Script Santai", 
        LoadingTitle = "Lagi muat sistem, tunggu bentar...", 
        ConfigurationSaving = { Enabled = false }, 
        Theme = "DarkBlue"
    })

    -- ==========================================
    -- TAB 1: CART SETUP & INVENTORY
    -- ==========================================
    local TabCart = Window:CreateTab("🛒 Siapin Barang", 4483362458)
    
    local PlayerDropdown = TabCart:CreateDropdown({
        Name = "Pilih Penerima Barang (P2)", Options = getPlayerList(), CurrentOption = {""}, MultipleOptions = false, 
        Callback = function() end 
    })

    TabCart:CreateSection("Jalur Cepat (Borongan)")
    TabCart:CreateButton({
        Name = "Masukin SEMUA Barang ke Antrean",
        Callback = function()
            local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Waduh", Content = "Pilih dulu orangnya, Bos!", Duration = 2}) end
            CurrentQueue = {}; ItemsProcessed = 0; local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do  
                if isTradeable(tool) then table.insert(CurrentQueue, tool); itemsFound = itemsFound + 1 end  
            end  
            Rayfield:Notify({Title = "Sip!", Content = itemsFound .. " barang udah masuk antrean.", Duration = 2})
        end
    })

    TabCart:CreateSection("Pilih Berdasarkan Mutasi")
    local MutationDropdown = TabCart:CreateDropdown({
        Name = "Filter Mutasi (Bisa klik banyak)", Options = getMutationList(), CurrentOption = {}, MultipleOptions = true, 
        Callback = function() end
    })
    
    TabCart:CreateButton({
        Name = "Masukin Mutasi Pilihan ke Antrean",
        Callback = function()
            local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Waduh", Content = "Pilih dulu orangnya, Bos!", Duration = 2}) end
            
            local liveSelectedMutations = MutationDropdown.CurrentOption
            if type(liveSelectedMutations) ~= "table" then liveSelectedMutations = {liveSelectedMutations} end
            
            local targetMuts = {}
            local hasValid = false
            for _, optionStr in pairs(liveSelectedMutations) do
                if type(optionStr) == "string" and optionStr ~= "[TIDAK ADA MUTASI]" and optionStr ~= "" then
                    local baseMut = string.split(optionStr, " | Stok:")[1]
                    if baseMut then targetMuts[baseMut] = true; hasValid = true end
                end
            end

            if not hasValid then 
                return Rayfield:Notify({Title = "Hei", Content = "Pilih minimal 1 mutasi dulu di atas.", Duration = 2}) 
            end
            
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
            Rayfield:Notify({Title = "Sip!", Content = itemsFound .. " barang mutasi udah siap dikirim.", Duration = 2})
        end
    })

    TabCart:CreateSection("Bikin Paket Custom")
    local SelectedMixQty = 0
    local function getBaseName(dropdownString) return string.split(dropdownString, " | Stok:")[1] or dropdownString end

    local ItemDropdown = TabCart:CreateDropdown({
        Name = "Pilih Nama Barang (Bisa klik banyak)", Options = {"[ANY ASSET]"}, CurrentOption = {}, MultipleOptions = true, 
        Callback = function() end
    })
    
    TabCart:CreateInput({
        Name = "Mau kirim berapa pcs per barang?", PlaceholderText = "Ketik angkanya di sini...", RemoveTextAfterFocusLost = false, 
        Callback = function(Text) SelectedMixQty = tonumber(Text) or 0 end
    })
    
    local CartStatus = TabCart:CreateParagraph({Title = "Isi Keranjangmu", Content = "Keranjang masih kosong nih."})

    local function updateCartDisplay()
        local text = ""; local total = 0
        for name, qty in pairs(ShoppingCart) do text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end
        if total == 0 then text = "Keranjang masih kosong nih." else text = text .. "\nTotal Item: " .. total end
        CartStatus:Set({Title = "Isi Keranjangmu", Content = text})
    end

    TabCart:CreateButton({
        Name = "➕ Tambah Sesuai Jumlah di Atas", 
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
                if addedItems > 0 then updateCartDisplay() else Rayfield:Notify({Title = "Gagal", Content = "Pilih dulu minimal 1 barang di atas.", Duration = 3}) end
            else
                Rayfield:Notify({Title = "Gagal", Content = "Masukin angka jumlahnya lebih dari 0 ya.", Duration = 3})
            end 
        end
    })
    
    TabCart:CreateButton({
        Name = "➕ Tambah Semua Stoknya (Max)", 
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
            
            if addedItems > 0 then updateCartDisplay() else Rayfield:Notify({Title = "Gagal", Content = "Pilih dulu minimal 1 barang di atas.", Duration = 3}) end 
        end
    })
    
    TabCart:CreateButton({Name = "🗑️ Kosongin Keranjang", Callback = function() ShoppingCart = {}; updateCartDisplay() end})

    TabCart:CreateButton({
        Name = "🚀 Bikin Antrean dari Keranjang", 
        Callback = function() 
            local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Waduh", Content = "Pilih dulu orangnya, Bos!", Duration = 2}) end
            
            CurrentQueue = {}; ItemsProcessed = 0; local needed = {}; for k,v in pairs(ShoppingCart) do needed[k] = v end
            local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do 
                if isTradeable(tool) then 
                    local name = getFullItemName(tool) 
                    if needed[name] and needed[name] > 0 then table.insert(CurrentQueue, tool); needed[name] = needed[name] - 1; itemsFound = itemsFound + 1 end 
                end 
            end
            Rayfield:Notify({Title = "Sip!", Content = itemsFound .. " barang dari keranjang udah siap dikirim.", Duration = 2})
        end
    })

    TabCart:CreateSection("Isi Tas Kamu Sekarang (Live)")
    local FullInventoryLabel = TabCart:CreateParagraph({Title = "Daftar Barang", Content = "Lagi ngecek tas..."})
    TabCart:CreateButton({Name = "🔄 Update Manual Isi Tas", Callback = function() updateInventoryDisplay() end})

    -- ==========================================
    -- TAB 2: AUTO DISPATCHER (P1)
    -- ==========================================
    local TabDispatch = Window:CreateTab("📤 Kirim Barang (P1)", 4483362458)
    local LiveProgress = TabDispatch:CreateParagraph({Title = "Progress Pengiriman", Content = "Sisa Antrean: 0\nSukses Terkirim: 0"})
    local ActionLog = TabDispatch:CreateParagraph({Title = "Catatan Bot", Content = "Tidur... Nunggu disuruh jalan."})

    local function updateProgressUI() LiveProgress:Set({Title = "Progress Pengiriman", Content = string.format("Sisa Antrean: %d\nSukses Terkirim: %d", #CurrentQueue, ItemsProcessed)}) end
    local function setLog(txt) ActionLog:Set({Title = "Catatan Bot", Content = txt}) end

    TabDispatch:CreateSlider({Name = "Jeda Masukin Barang (Detik)", Range = {0.1, 1.0}, Increment = 0.1, CurrentValue = 0.3, Callback = function(Value) InsertDelay = Value end})

    local function executeSenderBatch()
        if IsProcessing or #CurrentQueue == 0 then return false end
        
        local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then setLog("❌ Waduh, orangnya kabur dari server!"); return false end
        
        IsProcessing = true
        setLog("1️⃣ Ngirim invite trade ke " .. target.Name .. "...")
        task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)
        
        local tradeFrame = nil
        local timer = 0
        while timer < 15 do
            tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
            if tradeFrame and tradeFrame.Visible then break end
            task.wait(1); timer = timer + 1
        end
        if not (tradeFrame and tradeFrame.Visible) then setLog("❌ Gagal, dia nggak buka trade-nya (Timeout)."); IsProcessing = false; return false end
        
        setLog("2️⃣ Masukin barangnya...")
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
        
        setLog("3️⃣ Tunggu cooldown trade (5.5 detik)...")
        task.wait(5.5)
        
        setLog("4️⃣ Klik Accept pertama, nunggu layar pindah...")
        r_trade_i:FireServer("Confirm") 
        task.wait(0.5)

        local waitTimeout = 0
        while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do
            if not isLocalConfirmed(tradeFrame) then break end 
            task.wait(0.2); waitTimeout = waitTimeout + 0.2
            if waitTimeout > 60 then setLog("❌ Nyangkut di layar loading transisi!"); IsProcessing = false; return false end
        end

        if tradeFrame and tradeFrame.Parent and tradeFrame.Visible then
            setLog("5️⃣ Masuk ke layar final. Tunggu cooldown lagi (5.5 detik)...")
            task.wait(5.5)
            
            setLog("6️⃣ Klik Confirm Terakhir! Beresin transaksi...")
            r_trade_i:FireServer("Confirm") 
            
            while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do task.wait(0.5) end
        end
        
        P1TradesCompleted = P1TradesCompleted + 1
        ItemsProcessed = ItemsProcessed + batchSize
        TotalItemsSent = TotalItemsSent + batchSize
        
        for _, name in ipairs(itemNamesTbl) do
            SentAssetsRecord[name] = (SentAssetsRecord[name] or 0) + 1
        end
        
        local historyLines = {}
        for name, qty in pairs(SentAssetsRecord) do
            table.insert(historyLines, string.format(" • %s (x%d)", name, qty))
        end
        table.sort(historyLines)
        
        TradeHistoryString = string.format("Dikirim ke: %s\n\nTotal Barang Keluar (Sesi Ini):\n%s", 
            TargetPlayerName, 
            table.concat(historyLines, "\n")
        )
        
        HistoryLogLabel:Set({Title = "Riwayat Struk (P1)", Content = TradeHistoryString})
        updateProgressUI()
        setLog("✅ Sukses! " .. batchSize .. " barang berhasil dikirim.")
        IsProcessing = false
        return true
    end

    TabDispatch:CreateButton({Name = "▶️ Jalanin 1 Kloter Sekarang", Callback = function() task.spawn(executeSenderBatch) end})
    TabDispatch:CreateToggle({
        Name = "🔁 Mode Jalan Terus (Auto-Loop)", CurrentValue = false, 
        Callback = function(Value) 
            AutoLoopEnabled = Value 
            if AutoLoopEnabled then 
                task.spawn(function() 
                    while AutoLoopEnabled do 
                        if #CurrentQueue == 0 then setLog("🛑 Berhenti. Antreannya udah habis, Bos."); AutoLoopEnabled = false; break end 
                        executeSenderBatch() 
                        task.wait(2.5) 
                    end 
                end) 
            end 
        end
    })

    -- ==========================================
    -- TAB 3: INBOUND ENGINE (P2)
    -- ==========================================
    local TabInbound = Window:CreateTab("📥 Terima Barang (P2)", 4483362458)
    local ReceiverLog = TabInbound:CreateParagraph({Title = "Status Bot Penerima", Content = "Lagi mati. Belum dihidupin."})

    TabInbound:CreateToggle({
        Name = "🤖 Nyalain Auto-Accept Buat Nampung", CurrentValue = false,
        Callback = function(Value)
            AutoReceiverEnabled = Value
            if AutoReceiverEnabled then
                ReceiverLog:Set({Title = "Status Bot Penerima", Content = "🟢 Nyala! Siap nangkep semua request masuk..."})
                
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
                            ReceiverLog:Set({Title = "Status Bot Penerima", Content = "📥 UI Buka. Nunggu orangnya Accept duluan..."})
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            
                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                                ReceiverLog:Set({Title = "Status Bot Penerima", Content = "🔒 Dia udah Accept. Kita tunggu timer awal (5.5 detik)..."})
                                task.wait(5.5)
                                r_trade_i:FireServer("Confirm")
                                task.wait(1) 
                            end

                            ReceiverLog:Set({Title = "Status Bot Penerima", Content = "⏳ Nunggu layar loading pindah ke tahap 2..."})
                            while tradeFrame.Visible and isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end

                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                                ReceiverLog:Set({Title = "Status Bot Penerima", Content = "🔒 Masuk tahap 2. Tunggu timer lagi (5.5 detik)..."})
                                task.wait(5.5)
                                r_trade_i:FireServer("Confirm")
                            end

                            ReceiverLog:Set({Title = "Status Bot Penerima", Content = "✅ Nyelesaiin trade..."})
                            while tradeFrame.Visible do task.wait(0.5) end
                            
                            P2TradesCompleted = P2TradesCompleted + 1
                            ReceiverLog:Set({Title = "Status Bot Penerima", Content = "✅ Trade beres! Balik mode siaga lagi..."})
                        end
                    end
                end)
            else
                ReceiverLog:Set({Title = "Status Bot Penerima", Content = "❌ Dimatiin."})
            end
        end,
    })

    -- ==========================================
    -- TAB 4: ANALYTICS & LOGS
    -- ==========================================
    local TabAnalytics = Window:CreateTab("📊 Info & Riwayat", 4483362458)
    
    local AnalyticsLabel = TabAnalytics:CreateParagraph({Title = "Rangkuman Sesi Ini", Content = "Lagi ngitung data..."})
    task.spawn(function()
        while task.wait(1) do
            local currentUptime = tick() - SessionStartTime
            local statsText = string.format(
                "⏱️ Lama Main (Sesi Ini): %s\n" ..
                "📤 Total Kamu Ngirim (P1): %d kloter\n" ..
                "📥 Total Kamu Nampung (P2): %d kloter\n" ..
                "📦 Total Barang yang Jalan: %d item",
                formatTime(currentUptime), P1TradesCompleted, P2TradesCompleted, TotalItemsSent
            )
            AnalyticsLabel:Set({Title = "Rangkuman Sesi Ini", Content = statsText})
        end
    end)

    HistoryLogLabel = TabAnalytics:CreateParagraph({Title = "Riwayat Struk (P1)", Content = TradeHistoryString})

    -- ==========================================
    -- TAB 5: SYSTEM SETTINGS
    -- ==========================================
    local TabSettings = Window:CreateTab("⚙️ Pengaturan", 4483362458)

    TabSettings:CreateSection("Update Script Otomatis")
    TabSettings:CreateButton({
        Name = "🔄 Update Script ke Versi Terbaru (Kalo ada bug)", 
        Callback = function() 
            if SCRIPT_URL == "" then
                Rayfield:Notify({Title = "Error", Content = "Link GitHub kamu masih kosong tuh.", Duration = 4})
                return
            end
            Rayfield:Notify({Title = "Updating...", Content = "Lagi narik kode terbaru dari GitHub. Tunggu bentar...", Duration = 2})
            task.wait(1.5)
            Rayfield:Destroy() 
            task.wait(0.5)
            loadstring(game:HttpGet(SCRIPT_URL))()
        end
    })

    TabSettings:CreateSection("Biar Nggak Nge-Lag (HP Kentang Friendly)")
    TabSettings:CreateToggle({
        Name = "👁️ Mode Layar Bersih (Hapus Animasi/UI Game)", 
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
    -- INVENTORY SYNC ENGINE (Hidden Logic)
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
        
        ItemDropdown:Refresh(itemsList)
        MutationDropdown:Refresh(getMutationList()) 
        PlayerDropdown:Refresh(getPlayerList())
        
        local displayString = "Total Barang Bisa Di-Trade: " .. totalCount .. "\n\n"  
        if totalCount == 0 then displayString = displayString .. "Tas kamu masih kosong melompong nih." else
            local categorizedItems = {}
            for itemName, amount in pairs(inventoryData) do
                local category = "📦 BARANG BIASA"
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
                for _, item in ipairs(categorizedItems[cat]) do displayString = displayString .. string.format(" • %s  (Stok: %d)\n", item.name, item.qty) end
                displayString = displayString .. "\n"
            end
        end
        FullInventoryLabel:Set({Title = "Daftar Barang", Content = displayString})
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
    pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Waduh Ada Error", Text = tostring(errorMessage), Duration = 20}) end)
end
