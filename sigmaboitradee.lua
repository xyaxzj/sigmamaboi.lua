-- ==========================================================
-- MOCTA ULTIMATE HUB V1.7 (MUTATION MASTERY)
-- Build: Full Mutation Filter for Trade, Sell, and Base
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
    -- MENCARI LOKASI REMOTES
    -- ==========================================
    local networkFolder = ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
    local f_trade_r = networkFolder:WaitForChild("ref_trade_r", 5) 
    local r_trade_i = networkFolder:WaitForChild("rev_trade_i", 5) 
    local rev_trade_start = networkFolder:WaitForChild("rev_trade_start", 5) 

    local ref_B_Sell = nil
    local rev_S_Interact = nil
    
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "ref_B_Sell" and v:IsA("RemoteFunction") then ref_B_Sell = v end
        if v.Name == "rev_S_Interact" and v:IsA("RemoteEvent") then rev_S_Interact = v end
    end

    -- ==========================================
    -- VARIABEL SISTEM (KERANJANG & ANTREAN)
    -- ==========================================
    local TargetPlayerName = ""
    local CurrentQueue = {}
    
    local ShoppingCart = {}  -- Trade
    local SellCart = {}      -- Jual
    local BaseCart = {}      -- Place Base
    
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
    local TradeHistoryString = "Belum ada riwayat transaksi."

    local SelectedSellItems = {}
    local SelectedSellMixQty = 0
    local AutoSellEnabled = false

    local SelectedPlaceItems = {}
    local SelectedPlaceMixQty = 0
    local StartSlot = 1
    local MaxSlots = 30
    local CurrentPlaceSlot = 1

    -- ==========================================
    -- FUNGSI INTI & INVENTORY SCANNER
    -- ==========================================
    local function getBaseName(dropdownString) 
        return string.split(dropdownString, " | Stok:")[1] or dropdownString 
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
    
    local function getToolMutation(tool)
        if not tool then return nil end
        local m = tool:GetAttribute("Mutation") or tool:GetAttribute("Variant") or (tool:FindFirstChild("Mutation") and tool:FindFirstChild("Mutation").Value)
        return m and tostring(m) or nil
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
                local m = getToolMutation(tool)
                if m then 
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
        local mutValue = getToolMutation(tool)
        if mutValue then displayName = displayName .. " [" .. mutValue .. "]" end  
        
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

    -- FUNGSI HELPER UNTUK MEMASUKKAN BARANG BERDASARKAN MUTASI KE KERANJANG
    local function addMutationsToCart(TargetCart, SelectedOptions, QtyLimit, IsMax)
        if type(SelectedOptions) ~= "table" then SelectedOptions = {SelectedOptions} end
        
        local activeMutations = {}
        for _, opt in pairs(SelectedOptions) do
            local cleanMut = getBaseName(opt)
            if cleanMut ~= "" and cleanMut ~= "[TIDAK ADA MUTASI]" then activeMutations[cleanMut] = true end
        end

        local matchingItems = {}
        for _, tool in ipairs(getAllTools()) do
            if isTradeable(tool) then
                local mut = getToolMutation(tool)
                if mut and activeMutations[mut] then
                    matchingItems[getFullItemName(tool)] = true
                end
            end
        end

        for itemName, _ in pairs(matchingItems) do
            local rs = getRealStock(itemName)
            local cur = TargetCart[itemName] or 0
            if IsMax then
                TargetCart[itemName] = rs
            elseif QtyLimit > 0 then
                TargetCart[itemName] = (cur + QtyLimit > rs) and rs or (cur + QtyLimit)
            end
        end
    end

    local updateInventoryDisplay
    local updateStatsDisplay 

    -- ==========================================
    -- RAYFIELD WINDOW INITIALIZATION
    -- ==========================================
    local Window = Rayfield:CreateWindow({
        Name = "Mocta Ultimate Hub", 
        LoadingTitle = "Memuat Sistem V1.7...", 
        ConfigurationSaving = { Enabled = false }, 
        Theme = "DarkBlue"
    })

    -- ==========================================
    -- TAB 1: CART SETUP (TRADE)
    -- ==========================================
    local TabCart = Window:CreateTab("🛒 Trade Cart", 4483362458)
    
    local PlayerDropdown = TabCart:CreateDropdown({
        Name = "Target Penerima (P2)", Options = getPlayerList(), CurrentOption = {""}, MultipleOptions = false, 
        Callback = function(Opt) TargetPlayerName = Opt[1] or "" end 
    })

    TabCart:CreateSection("Kirim Semua (Massal)")
    TabCart:CreateButton({
        Name = "Masukkan Semua Barang ke Antrean",
        Callback = function()
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Perhatian", Content = "Pilih target dulu.", Duration = 2}) end
            CurrentQueue = {}; ItemsProcessed = 0; local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do  
                if isTradeable(tool) then table.insert(CurrentQueue, tool); itemsFound = itemsFound + 1 end  
            end  
            Rayfield:Notify({Title = "Berhasil", Content = itemsFound .. " barang masuk antrean.", Duration = 2})
        end
    })

    TabCart:CreateSection("Filter Spesifik & Mutasi")
    local TradeMutationDropdown = TabCart:CreateDropdown({
        Name = "Pilih Mutasi (Trade)", Options = getMutationList(), CurrentOption = {}, MultipleOptions = true, Callback = function() end
    })
    
    local ItemDropdown = TabCart:CreateDropdown({
        Name = "Pilih Barang Custom", Options = {"[ANY ASSET]"}, CurrentOption = {}, MultipleOptions = true, Callback = function() end
    })
    
    local TradeMixQty = 0
    TabCart:CreateInput({
        Name = "Jumlah barang dikirim:", PlaceholderText = "Masukkan jumlah...", RemoveTextAfterFocusLost = false, 
        Callback = function(Text) TradeMixQty = tonumber(Text) or 0 end
    })
    
    local CartStatus = TabCart:CreateParagraph({Title = "Isi Keranjang Trade", Content = "Kosong."})

    local function updateCartDisplay()
        local text = ""; local total = 0
        for name, qty in pairs(ShoppingCart) do if qty > 0 then text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end end
        CartStatus:Set({Title = "Isi Keranjang Trade", Content = total == 0 and "Kosong." or text .. "\nTotal Item: " .. total})
    end

    TabCart:CreateButton({
        Name = "➕ Tambah Custom Sesuai Jumlah", 
        Callback = function() 
            local liveSelectedItems = ItemDropdown.CurrentOption
            if type(liveSelectedItems) ~= "table" then liveSelectedItems = {liveSelectedItems} end
            for _, optionStr in pairs(liveSelectedItems) do
                local itemName = getBaseName(optionStr)
                if itemName ~= "" and itemName ~= "[ANY ASSET]" and TradeMixQty > 0 then
                    local rs = getRealStock(itemName) 
                    local cur = ShoppingCart[itemName] or 0 
                    ShoppingCart[itemName] = (cur + TradeMixQty > rs) and rs or (cur + TradeMixQty)
                end
            end
            updateCartDisplay() 
        end
    })

    TabCart:CreateButton({
        Name = "➕ Tambah Custom Semua Stok (Max)", 
        Callback = function() 
            local liveSelectedItems = ItemDropdown.CurrentOption
            if type(liveSelectedItems) ~= "table" then liveSelectedItems = {liveSelectedItems} end
            for _, optionStr in pairs(liveSelectedItems) do
                local itemName = getBaseName(optionStr)
                if itemName ~= "" and itemName ~= "[ANY ASSET]" then
                    ShoppingCart[itemName] = getRealStock(itemName)
                end
            end
            updateCartDisplay() 
        end
    })

    -- TOMBOL BARU UNTUK MUTASI (TRADE)
    TabCart:CreateButton({
        Name = "✨ Tambah Berdasarkan Mutasi (Sesuai Jumlah)", 
        Callback = function() addMutationsToCart(ShoppingCart, TradeMutationDropdown.CurrentOption, TradeMixQty, false); updateCartDisplay() end
    })
    TabCart:CreateButton({
        Name = "✨ Tambah Berdasarkan Mutasi (Maksimal Stok)", 
        Callback = function() addMutationsToCart(ShoppingCart, TradeMutationDropdown.CurrentOption, TradeMixQty, true); updateCartDisplay() end
    })
    
    TabCart:CreateButton({Name = "🗑️ Kosongkan Keranjang", Callback = function() ShoppingCart = {}; updateCartDisplay() end})
    TabCart:CreateButton({
        Name = "🚀 Buat Antrean dari Keranjang", 
        Callback = function() 
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Perhatian", Content = "Pilih target dulu.", Duration = 2}) end
            CurrentQueue = {}; ItemsProcessed = 0; local needed = {}; for k,v in pairs(ShoppingCart) do needed[k] = v end
            local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do 
                if isTradeable(tool) then 
                    local name = getFullItemName(tool) 
                    if needed[name] and needed[name] > 0 then table.insert(CurrentQueue, tool); needed[name] = needed[name] - 1; itemsFound = itemsFound + 1 end 
                end 
            end
            Rayfield:Notify({Title = "Berhasil", Content = itemsFound .. " barang disiapkan.", Duration = 2})
        end
    })

    -- ==========================================
    -- TAB 2: SMART SELL (KERANJANG JUAL)
    -- ==========================================
    local TabSell = Window:CreateTab("💰 Sell Cerdas", 4483362458)
    
    if not ref_B_Sell then TabSell:CreateParagraph({Title = "⚠️ Peringatan", Content = "Remote Sell tidak ditemukan."}) end

    TabSell:CreateSection("1. Setup Keranjang Jual")
    
    local SellMutationDropdown = TabSell:CreateDropdown({
        Name = "Pilih Mutasi (Jual)", Options = getMutationList(), CurrentOption = {}, MultipleOptions = true, Callback = function() end
    })

    local SellItemDropdown = TabSell:CreateDropdown({
        Name = "Pilih Item Dijual Custom", Options = {"[ANY ASSET]"}, CurrentOption = {}, MultipleOptions = true, Callback = function(Options) SelectedSellItems = Options end,
    })

    TabSell:CreateInput({
        Name = "Jumlah Dijual:", PlaceholderText = "Masukkan jumlah...", RemoveTextAfterFocusLost = false,
        Callback = function(Text) SelectedSellMixQty = tonumber(Text) or 0 end
    })

    local SellCartStatus = TabSell:CreateParagraph({Title = "🛒 Keranjang Jual", Content = "Kosong."})

    local function updateSellCartDisplay()
        local text = ""; local total = 0
        for name, qty in pairs(SellCart) do if qty > 0 then text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end end
        SellCartStatus:Set({Title = "🛒 Keranjang Jual", Content = total == 0 and "Kosong." or text .. "\nTotal Item: " .. total})
    end

    TabSell:CreateButton({
        Name = "➕ Tambah Custom Sesuai Jumlah", 
        Callback = function() 
            local lst = type(SelectedSellItems) == "table" and SelectedSellItems or {SelectedSellItems}
            for _, optionStr in pairs(lst) do
                local itemName = getBaseName(optionStr)
                if itemName ~= "" and itemName ~= "[ANY ASSET]" and SelectedSellMixQty > 0 then
                    local rs = getRealStock(itemName) 
                    local cur = SellCart[itemName] or 0 
                    SellCart[itemName] = (cur + SelectedSellMixQty > rs) and rs or (cur + SelectedSellMixQty)
                end
            end
            updateSellCartDisplay() 
        end
    })

    TabSell:CreateButton({
        Name = "➕ Tambah Custom Semua Stok (Max)", 
        Callback = function() 
            local lst = type(SelectedSellItems) == "table" and SelectedSellItems or {SelectedSellItems}
            for _, optionStr in pairs(lst) do
                local itemName = getBaseName(optionStr)
                if itemName ~= "" and itemName ~= "[ANY ASSET]" then
                    SellCart[itemName] = getRealStock(itemName)
                end
            end
            updateSellCartDisplay() 
        end
    })

    -- TOMBOL BARU UNTUK MUTASI (SELL)
    TabSell:CreateButton({
        Name = "✨ Tambah Mutasi (Sesuai Jumlah)", 
        Callback = function() addMutationsToCart(SellCart, SellMutationDropdown.CurrentOption, SelectedSellMixQty, false); updateSellCartDisplay() end
    })
    TabSell:CreateButton({
        Name = "✨ Tambah Mutasi (Maksimal Stok)", 
        Callback = function() addMutationsToCart(SellCart, SellMutationDropdown.CurrentOption, SelectedSellMixQty, true); updateSellCartDisplay() end
    })

    TabSell:CreateButton({Name = "🗑️ Kosongkan Keranjang Jual", Callback = function() SellCart = {}; updateSellCartDisplay() end})

    TabSell:CreateSection("2. Eksekusi Jual")
    local SellToggle = TabSell:CreateToggle({
        Name = "🧠 Mulai Jual", CurrentValue = false,
        Callback = function(Value)
            AutoSellEnabled = Value
            if AutoSellEnabled then
                task.spawn(function()
                    while AutoSellEnabled do
                        local character = localPlayer.Character
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        local backpack = localPlayer:FindFirstChild("Backpack")
                        
                        if not humanoid or not backpack or not ref_B_Sell then break end
                        
                        local tempCart = {}; local totalLeft = 0
                        for k,v in pairs(SellCart) do tempCart[k] = v; totalLeft = totalLeft + v end
                        
                        if totalLeft <= 0 then
                            Rayfield:Notify({Title = "Selesai", Content = "Semua terjual / Keranjang kosong.", Duration = 3})
                            SellToggle:Set(false)
                            break
                        end

                        local itemsToProcess = {}
                        for _, tool in ipairs(getAllTools()) do
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
                            if not SellCart[toolName] or SellCart[toolName] <= 0 then continue end

                            if toolToSell.Parent == backpack then humanoid:EquipTool(toolToSell); task.wait(0.15) end
                            local didSell = pcall(function() return ref_B_Sell:InvokeServer() end)
                            if didSell and SellCart[toolName] then SellCart[toolName] = SellCart[toolName] - 1 end
                            task.wait(0.1) 
                        end
                        updateSellCartDisplay(); task.wait(0.5) 
                    end
                end)
            end
        end
    })

    -- ==========================================
    -- TAB 3: BASE MANAGER (PLACE & PICKUP CART)
    -- ==========================================
    local TabBase = Window:CreateTab("🏗️ Base Manager", 4483362458)
    
    if not rev_S_Interact then TabBase:CreateParagraph({Title = "⚠️ Peringatan", Content = "Remote Interact tidak ditemukan."}) end

    TabBase:CreateSection("1. Setup Keranjang Base")
    
    local BaseMutationDropdown = TabBase:CreateDropdown({
        Name = "Pilih Mutasi (Base)", Options = getMutationList(), CurrentOption = {}, MultipleOptions = true, Callback = function() end
    })

    local PlaceItemDropdown = TabBase:CreateDropdown({
        Name = "Pilih Brainrot Custom", Options = {"[ANY ASSET]"}, CurrentOption = {}, MultipleOptions = true, Callback = function(Options) SelectedPlaceItems = Options end,
    })

    TabBase:CreateInput({
        Name = "Jumlah diletakkan:", PlaceholderText = "Masukkan jumlah...", RemoveTextAfterFocusLost = false,
        Callback = function(Text) SelectedPlaceMixQty = tonumber(Text) or 0 end
    })

    local BaseCartStatus = TabBase:CreateParagraph({Title = "🛒 Keranjang Base", Content = "Kosong."})

    local function updateBaseCartDisplay()
        local text = ""; local total = 0
        for name, qty in pairs(BaseCart) do if qty > 0 then text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end end
        BaseCartStatus:Set({Title = "🛒 Keranjang Base", Content = total == 0 and "Kosong." or text .. "\nTotal Item: " .. total})
    end

    TabBase:CreateButton({
        Name = "➕ Tambah Custom Sesuai Jumlah", 
        Callback = function() 
            local lst = type(SelectedPlaceItems) == "table" and SelectedPlaceItems or {SelectedPlaceItems}
            for _, optionStr in pairs(lst) do
                local itemName = getBaseName(optionStr)
                if itemName ~= "" and itemName ~= "[ANY ASSET]" and SelectedPlaceMixQty > 0 then
                    local rs = getRealStock(itemName) 
                    local cur = BaseCart[itemName] or 0 
                    BaseCart[itemName] = (cur + SelectedPlaceMixQty > rs) and rs or (cur + SelectedPlaceMixQty)
                end
            end
            updateBaseCartDisplay() 
        end
    })

    TabBase:CreateButton({
        Name = "➕ Tambah Custom Semua Stok (Max)", 
        Callback = function() 
            local lst = type(SelectedPlaceItems) == "table" and SelectedPlaceItems or {SelectedPlaceItems}
            for _, optionStr in pairs(lst) do
                local itemName = getBaseName(optionStr)
                if itemName ~= "" and itemName ~= "[ANY ASSET]" then
                    BaseCart[itemName] = getRealStock(itemName)
                end
            end
            updateBaseCartDisplay() 
        end
    })

    -- TOMBOL BARU UNTUK MUTASI (BASE)
    TabBase:CreateButton({
        Name = "✨ Tambah Mutasi (Sesuai Jumlah)", 
        Callback = function() addMutationsToCart(BaseCart, BaseMutationDropdown.CurrentOption, SelectedPlaceMixQty, false); updateBaseCartDisplay() end
    })
    TabBase:CreateButton({
        Name = "✨ Tambah Mutasi (Maksimal Stok)", 
        Callback = function() addMutationsToCart(BaseCart, BaseMutationDropdown.CurrentOption, SelectedPlaceMixQty, true); updateBaseCartDisplay() end
    })

    TabBase:CreateButton({Name = "🗑️ Kosongkan Keranjang Base", Callback = function() BaseCart = {}; updateBaseCartDisplay() end})

    TabBase:CreateSection("2. Pengaturan Koordinat Base")
    TabBase:CreateInput({Name = "Mulai dari Slot Ke-", PlaceholderText = "Default: 1", RemoveTextAfterFocusLost = false, Callback = function(Text) local num = tonumber(Text); if num and num > 0 then StartSlot = num end end})
    TabBase:CreateInput({Name = "Batas Slot Maksimal", PlaceholderText = "Default: 30", RemoveTextAfterFocusLost = false, Callback = function(Text) local num = tonumber(Text); if num and num > 0 then MaxSlots = num end end})

    TabBase:CreateSection("3. Eksekusi Base")
    local PlaceToggle
    PlaceToggle = TabBase:CreateToggle({
        Name = "🏗️ Start Auto Place", CurrentValue = false,
        Callback = function(Value)
            if Value then
                CurrentPlaceSlot = StartSlot
                task.spawn(function()
                    while PlaceToggle.CurrentValue do
                        local character = localPlayer.Character
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        local backpack = localPlayer:FindFirstChild("Backpack")
                        
                        if not humanoid or not backpack or not rev_S_Interact then break end
                        if CurrentPlaceSlot > MaxSlots then
                            Rayfield:Notify({Title = "Selesai", Content = "Batas Max Slot Tercapai!", Duration = 3})
                            PlaceToggle:Set(false); break
                        end

                        local totalLeft = 0; for _, qty in pairs(BaseCart) do totalLeft = totalLeft + qty end
                        if totalLeft <= 0 then
                            Rayfield:Notify({Title = "Selesai", Content = "Keranjang Base Kosong!", Duration = 3})
                            PlaceToggle:Set(false); break
                        end

                        local placedThisLoop = false
                        for itemName, qtyNeeded in pairs(BaseCart) do
                            if qtyNeeded > 0 and CurrentPlaceSlot <= MaxSlots then
                                local itemToPlace = nil
                                for _, t in ipairs(getAllTools()) do
                                    if getFullItemName(t) == itemName then itemToPlace = t; break end
                                end
                                
                                if itemToPlace then
                                    if itemToPlace.Parent ~= character then humanoid:EquipTool(itemToPlace); task.wait(0.15) end
                                    pcall(function() rev_S_Interact:FireServer(CurrentPlaceSlot) end)
                                    BaseCart[itemName] = BaseCart[itemName] - 1
                                    CurrentPlaceSlot = CurrentPlaceSlot + 1
                                    placedThisLoop = true; task.wait(0.15)
                                end
                            end
                        end
                        updateBaseCartDisplay()
                        if not placedThisLoop then task.wait(0.5) end
                    end
                end)
            end
        end
    })

    local PickupToggle
    PickupToggle = TabBase:CreateToggle({
        Name = "🧲 Start Auto Pickup (Sapu Bersih)", CurrentValue = false,
        Callback = function(Value)
            if Value then
                task.spawn(function()
                    local character = localPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if humanoid then humanoid:UnequipTools() end
                    task.wait(0.2)
                    for i = StartSlot, MaxSlots do
                        if not PickupToggle.CurrentValue then break end
                        pcall(function() rev_S_Interact:FireServer(i) end); task.wait(0.15)
                    end
                    Rayfield:Notify({Title = "Selesai", Content = "Sapu bersih Pickup selesai!", Duration = 3})
                    PickupToggle:Set(false)
                end)
            end
        end
    })

    -- ==========================================
    -- TAB 4 - 8: STATS, P1, P2, INVENTORY
    -- (TETAP SAMA SEPERTI VERSI SEBELUMNYA)
    -- ==========================================
    local TabInventory = Window:CreateTab("🎒 Tas & Stok", 4483362458)
    local FullInventoryLabel = TabInventory:CreateParagraph({Title = "Daftar Barang & Total", Content = "Menyinkronkan..."})
    TabInventory:CreateButton({Name = "🔄 Update Manual Data Tas", Callback = function() updateInventoryDisplay() end})

    local TabDispatch = Window:CreateTab("📤 Pengirim (P1)", 4483362458)
    local LiveProgress = TabDispatch:CreateParagraph({Title = "Status Pengiriman", Content = "Sisa Antrean: 0\nSukses: 0"})
    local ActionLog = TabDispatch:CreateParagraph({Title = "Log Proses", Content = "Menunggu perintah..."})
    local function setLog(txt) ActionLog:Set({Title = "Log Proses", Content = txt}) end
    TabDispatch:CreateSlider({Name = "Jeda Input", Range = {0.1, 1.0}, Increment = 0.1, CurrentValue = 0.3, Callback = function(v) InsertDelay = v end})

    local function executeSenderBatch()
        if IsProcessing or #CurrentQueue == 0 then return false end
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then setLog("❌ Target hilang!"); return false end
        
        IsProcessing = true
        setLog("1️⃣ Mengirim trade...")
        task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)
        
        local tradeFrame = nil; local timer = 0
        while timer < 15 do
            tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
            if tradeFrame and tradeFrame.Visible then break end
            task.wait(1); timer = timer + 1
        end
        if not (tradeFrame and tradeFrame.Visible) then setLog("❌ Timeout target."); IsProcessing = false; return false end
        
        local batchSize = math.min(10, #CurrentQueue); local batch = {}; local names = {}
        for i = 1, batchSize do 
            local t = table.remove(CurrentQueue, 1); table.insert(batch, t); table.insert(names, getFullItemName(t)) 
        end
        
        for _, t in ipairs(batch) do
            local guid = getToolGUID(t)
            if guid then r_trade_i:FireServer("AddItem", tostring(guid)); task.wait(InsertDelay) end
        end
        
        task.wait(5.5); r_trade_i:FireServer("Confirm"); task.wait(0.5)

        local waitTimeout = 0
        while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do
            if not isLocalConfirmed(tradeFrame) then break end 
            task.wait(0.2); waitTimeout = waitTimeout + 0.2
            if waitTimeout > 60 then IsProcessing = false; return false end
        end

        if tradeFrame and tradeFrame.Parent and tradeFrame.Visible then
            task.wait(5.5); r_trade_i:FireServer("Confirm")
            while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do task.wait(0.5) end
        end
        
        P1TradesCompleted = P1TradesCompleted + 1
        ItemsProcessed = ItemsProcessed + batchSize
        TotalItemsSent = TotalItemsSent + batchSize
        TradeHistoryString = TradeHistoryString .. "\n[" .. os.date("%H:%M:%S") .. "] Mengirim " .. batchSize .. " item ke " .. target.Name
        
        LiveProgress:Set({Title = "Status", Content = string.format("Sisa: %d\nSukses: %d", #CurrentQueue, ItemsProcessed)})
        updateStatsDisplay(); IsProcessing = false; return true
    end

    TabDispatch:CreateButton({Name = "▶️ Kirim 1 Kloter", Callback = function() task.spawn(executeSenderBatch) end})
    TabDispatch:CreateToggle({Name = "🔁 Auto-Loop", CurrentValue = false, Callback = function(V) 
        AutoLoopEnabled = V 
        if V then task.spawn(function() while AutoLoopEnabled do if #CurrentQueue == 0 then AutoLoopEnabled = false; break end executeSenderBatch(); task.wait(2.5) end end) end 
    end})

    local TabInbound = Window:CreateTab("📥 Penerima (P2)", 4483362458)
    local ReceiverLog = TabInbound:CreateParagraph({Title = "Status", Content = "Nonaktif."})
    TabInbound:CreateToggle({
        Name = "🤖 Auto-Accept", CurrentValue = false,
        Callback = function(Value)
            AutoReceiverEnabled = Value
            if AutoReceiverEnabled then
                ReceiverLog:Set({Title = "Status", Content = "🟢 Aktif..."})
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
                                            if string.find(txt, "trade") or string.find(txt, "request") then
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
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then task.wait(5.5); r_trade_i:FireServer("Confirm"); task.wait(1) end
                            while tradeFrame.Visible and isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then task.wait(5.5); r_trade_i:FireServer("Confirm") end
                            while tradeFrame.Visible do task.wait(0.5) end
                            P2TradesCompleted = P2TradesCompleted + 1; updateStatsDisplay() 
                        end
                    end
                end)
            else ReceiverLog:Set({Title = "Status", Content = "❌ Dimatikan."}) end
        end
    })

    local TabStats = Window:CreateTab("📊 Dashboard", 4483362458)
    local StatsDisplay = TabStats:CreateParagraph({Title = "Sesi Saat Ini", Content = "Menghitung..."})
    local HistoryDisplay = TabStats:CreateParagraph({Title = "Log Pengiriman Terakhir", Content = TradeHistoryString})
    
    updateStatsDisplay = function()
        local elapsedTime = tick() - SessionStartTime
        local str = "Waktu Berjalan: " .. formatTime(elapsedTime) .. "\n"
        str = str .. "Total Transaksi P1 (Kirim): " .. P1TradesCompleted .. " kali\n"
        str = str .. "Total Transaksi P2 (Terima): " .. P2TradesCompleted .. " kali\n"
        str = str .. "Total Item Terkirim: " .. TotalItemsSent .. " barang"
        
        StatsDisplay:Set({Title = "Statistik Real-Time", Content = str})
        
        local lines = string.split(TradeHistoryString, "\n")
        if #lines > 15 then
            local newHistory = ""
            for i = #lines - 10, #lines do newHistory = newHistory .. lines[i] .. "\n" end
            TradeHistoryString = newHistory
        end
        HistoryDisplay:Set({Title = "Log Pengiriman Terakhir", Content = TradeHistoryString})
    end

    task.spawn(function() while task.wait(1) do if updateStatsDisplay then updateStatsDisplay() end end end)

    local TabSettings = Window:CreateTab("⚙️ Settings", 4483362458)
    TabSettings:CreateButton({Name = "🔄 Update Script", Callback = function() Rayfield:Destroy(); task.wait(0.5); loadstring(game:HttpGet(SCRIPT_URL))() end})

    local isSyncingUI = false 
    updateInventoryDisplay = function()
        if isSyncingUI then return end
        isSyncingUI = true
        task.spawn(function()
            task.wait(1.5) 
            local inventoryData = {}; local totalCount = 0
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
            
            local mutList = getMutationList()
            ItemDropdown:Refresh(itemsList)
            SellItemDropdown:Refresh(itemsList)
            PlaceItemDropdown:Refresh(itemsList)
            
            -- Update semua dropdown mutasi
            TradeMutationDropdown:Refresh(mutList) 
            SellMutationDropdown:Refresh(mutList)
            BaseMutationDropdown:Refresh(mutList)
            
            PlayerDropdown:Refresh(getPlayerList())
            
            local displayString = "Total Semua Barang: " .. totalCount .. "\n\n"  
            if totalCount == 0 then displayString = displayString .. "Kosong." else
                local categorizedItems = {}; local categoryTotals = {}
                for itemName, amount in pairs(inventoryData) do
                    local category = "📦 BARANG STANDAR"
                    local mutMatch = string.match(itemName, "%[(.-)%]")
                    if mutMatch then category = "✨ " .. string.upper(mutMatch) end
                    if not categorizedItems[category] then categorizedItems[category] = {}; categoryTotals[category] = 0 end
                    table.insert(categorizedItems[category], {name = itemName, qty = amount})
                    categoryTotals[category] = categoryTotals[category] + amount
                end
                local sortedCategories = {}
                for cat, _ in pairs(categorizedItems) do table.insert(sortedCategories, cat) end; table.sort(sortedCategories)
                for _, cat in ipairs(sortedCategories) do
                    displayString = displayString .. "=== " .. cat .. " (Total: " .. categoryTotals[cat] .. ") ===\n"
                    table.sort(categorizedItems[cat], function(a, b) return a.name < b.name end)
                    for _, item in ipairs(categorizedItems[cat]) do displayString = displayString .. string.format(" • %s  (Stok: %d)\n", item.name, item.qty) end
                    displayString = displayString .. "\n"
                end
            end
            FullInventoryLabel:Set({Title = "Daftar Barang & Total", Content = displayString})
            isSyncingUI = false 
        end)
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
        task.wait(0.5); updateInventoryDisplay()
    end
    connectInventory()

end)

if not success then
    warn("MOCTA SCRIPT ERROR: " .. tostring(errorMessage))
    pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Kesalahan", Text = tostring(errorMessage), Duration = 20}) end)
end
