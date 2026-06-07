-- ==========================================================
-- MOCTA TRADE & SELL AUTOMATIC V18.16 (ANTI-LAG EDITION)
-- Build: Sell Cart System, No Sell-All, Debounce Sync Fixed
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
            if isTr
