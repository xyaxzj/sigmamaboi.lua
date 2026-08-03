-- ==========================================================
-- MOCTA ULTIMATE HUB V1.8 (THE COMPLETE ARSENAL)
-- Build: Trade, Sell, Base, Action Center (Unlimited Burst)
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
    -- ==========================================
    -- SYSTEM VARIABLES (CARTS & QUEUES)
    -- ==========================================
    local TargetPlayerName = ""
    local CurrentQueue = {}
    
    local ShoppingCart = {}  -- Trade
    local SellCart = {}      -- Sell
    local BaseCart = {}      -- Place Base
    
    local CachedInventoryData = {}
    local CachedTotalCount = 0
    local InvRarityDropdown = nil
    local InvMutationDropdown = nil
    
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
    local ConsoleStats
    _G.TradeLogsMode = "Detailed"
    local CumulativeSent = {}
    local CumulativeReceived = {}
    local function getCumulativeDetails(playerData)
        local parts = {}
        local order = {}
        for name in pairs(playerData) do table.insert(order, name) end
        table.sort(order)
        for _, name in ipairs(order) do
            table.insert(parts, name .. " x" .. playerData[name])
        end
        return table.concat(parts, ", ")
    end

    local function groupItems(namesTable)
        local counts = {}
        local order = {}
        for _, name in ipairs(namesTable) do
            if not counts[name] then
                counts[name] = 0
                table.insert(order, name)
            end
            counts[name] = counts[name] + 1
        end
        local parts = {}
        for _, name in ipairs(order) do
            table.insert(parts, name .. " x" .. counts[name])
        end
        return table.concat(parts, ", ")
    end

    local SelectedSellItems = {}
    local SelectedSellMixQty = 0
    local AutoSellEnabled = false

    local SelectedPlaceItems = {}
    local SelectedPlaceMixQty = 0
    local StartSlot = 1
    local MaxSlots = 30
    local CurrentPlaceSlot = 1

    -- Variabel Action Center
    local TargetToolNameAction = "Block Cup"

    -- ==========================================
    -- DATABASE & PARSER (STATICALLY EMBEDDED)
    -- ==========================================
    local RarityList = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Godly", "Exclusive", "Volcanic", "Celestial", "Abyssal", "Demon", "Secret", "Rainbow", "Eternal", "Hacked"}
    local database = {
        ["1x1x1x1"] = { Rarity = "" },
        ["67"] = { Rarity = "" },
        ["Agarrini La Palini"] = { Rarity = "Hacked" },
        ["Alessio"] = { Rarity = "" },
        ["Anpali Babel"] = { Rarity = "Eternal" },
        ["Astro Tim"] = { Rarity = "Eternal" },
        ["Baba Yaga"] = { Rarity = "Eternal" },
        ["Ballerina Cappuccina"] = { Rarity = "" },
        ["Bambini Crostini"] = { Rarity = "" },
        ["Bananita Dolphinita"] = { Rarity = "" },
        ["Bangello"] = { Rarity = "" },
        ["Barbelloni Gymrattoni"] = { Rarity = "Eternal" },
        ["Beluga Beluga"] = { Rarity = "Celestial" },
        ["Blackhole Goat"] = { Rarity = "" },
        ["Bobrito Bandito"] = { Rarity = "" },
        ["Bombardiro Crocodilo"] = { Rarity = "" },
        ["Bombini Gusini"] = { Rarity = "" },
        ["Boneca Ambalabu"] = { Rarity = "" },
        ["Brr Brr Patapim"] = { Rarity = "" },
        ["Burbaloni Luliloli"] = { Rarity = "" },
        ["Burguro"] = { Rarity = "" },
        ["Cacto Hipopotamo"] = { Rarity = "" },
        ["Cactus Pingu"] = { Rarity = "" },
        ["Capi Taco"] = { Rarity = "" },
        ["Cappuccino Assassino"] = { Rarity = "" },
        ["Cappuccino Clownino"] = { Rarity = "" },
        ["Capybara Eggplant"] = { Rarity = "" },
        ["Cavallo Virtuso"] = { Rarity = "" },
        ["Chef Crabracadabra"] = { Rarity = "" },
        ["Chicleteira Bicicleteira"] = { Rarity = "Celestial" },
        ["Chillin Chilli"] = { Rarity = "" },
        ["Chimpanzini Bananini"] = { Rarity = "" },
        ["Cocofanto Elefanto"] = { Rarity = "" },
        ["Coinator Baconator"] = { Rarity = "Abysall" },
        ["Compactoroni Diskaloni"] = { Rarity = "" },
        ["Cordraculo"] = { Rarity = "Abysall" },
        ["Corn Sahur"] = { Rarity = "" },
        ["Crazylone Pizaione"] = { Rarity = "OG" },
        ["Dipperi Chiperini"] = { Rarity = "" },
        ["Divinello Starblock"] = { Rarity = "" },
        ["Don Tiramisotto"] = { Rarity = "Eternal" },
        ["Dragonfrutina Dolphinita"] = { Rarity = "Celestial" },
        ["Dribbloni Spaghetti"] = { Rarity = "Eternal" },
        ["Dumbelloni"] = { Rarity = "Eternal" },
        ["Elefanto Frigo"] = { Rarity = "" },
        ["Elefantucci Bananucci"] = { Rarity = "" },
        ["Espresso Shockantoni"] = { Rarity = "Eternal" },
        ["Espresso Signora"] = { Rarity = "" },
        ["Frigo Camelo"] = { Rarity = "" },
        ["Fruli Frula"] = { Rarity = "" },
        ["Fryuro"] = { Rarity = "" },
        ["Gangster Footera"] = { Rarity = "" },
        ["Garamararam"] = { Rarity = "" },
        ["Gattatino Nyanino"] = { Rarity = "" },
        ["Girafa Celeste"] = { Rarity = "" },
        ["Glorbo Fruttodrillo"] = { Rarity = "" },
        ["Gorillo Watermelondrillo"] = { Rarity = "" },
        ["Guerriro Digitale"] = { Rarity = "Celestial" },
        ["Guest666"] = { Rarity = "" },
        ["Harpini Goosini"] = { Rarity = "" },
        ["John Pork"] = { Rarity = "" },
        ["Karkerkar Kurkur"] = { Rarity = "" },
        ["Ketupat Kepat"] = { Rarity = "" },
        ["Kicky"] = { Rarity = "Eternal" },
        ["Krupuk Pagi Pagi"] = { Rarity = "Celestial" },
        ["La Vacca Saturno Saturnita"] = { Rarity = "" },
        ["Lirili Larila"] = { Rarity = "" },
        ["Los Primos"] = { Rarity = "Celestial" },
        ["Los Primos Blue"] = { Rarity = "" },
        ["Lucky Fella"] = { Rarity = "Abysall" },
        ["Madung"] = { Rarity = "" },
        ["Mangolini Parrocini"] = { Rarity = "" },
        ["Mastodontico Telepiedone"] = { Rarity = "Celestial" },
        ["Matteo"] = { Rarity = "" },
        ["Meowl"] = { Rarity = "OG" },
        ["Noobini Pizzanini"] = { Rarity = "" },
        ["Nuclearo Dinossauro"] = { Rarity = "" },
        ["OctoDJ"] = { Rarity = "Abysall" },
        ["Octopusini Bluberini"] = { Rarity = "" },
        ["Orangutini Ananasini"] = { Rarity = "" },
        ["Orcalero"] = { Rarity = "" },
        ["Pandaccini Bananini"] = { Rarity = "" },
        ["Pannaburro"] = { Rarity = "" },
        ["Peant Jarro"] = { Rarity = "" },
        ["Penguino Cocosino"] = { Rarity = "" },
        ["Pesto Mortioni"] = { Rarity = "" },
        ["Pipi Kiwi"] = { Rarity = "" },
        ["Plan Blue"] = { Rarity = "" },
        ["Plan Red"] = { Rarity = "" },
        ["Pot Hotspot"] = { Rarity = "Celestial" },
        ["Professora 67"] = { Rarity = "Eternal" },
        ["Pulcino Pistoletti"] = { Rarity = "Abysall" },
        ["Rexosaurus"] = { Rarity = "" },
        ["Rhino Toasterino"] = { Rarity = "" },
        ["Rinooccio Verdini"] = { Rarity = "" },
        ["SWAG SODA"] = { Rarity = "" },
        ["Salamino Pinguino"] = { Rarity = "" },
        ["Sigma Boy"] = { Rarity = "" },
        ["Smelloni Papayoni"] = { Rarity = "Eternal" },
        ["Stoppo Luminino"] = { Rarity = "" },
        ["Strawberelli Flamingelli"] = { Rarity = "" },
        ["Strawberry Elephant"] = { Rarity = "OG" },
        ["Svinina Bombardino"] = { Rarity = "" },
        ["Ta Ta Ta Ta Sahur"] = { Rarity = "" },
        ["Talpa Di Fero"] = { Rarity = "" },
        ["Tictac Sahur"] = { Rarity = "" },
        ["Tim Cheese"] = { Rarity = "" },
        ["Torrtuginni Dragonfrutini"] = { Rarity = "" },
        ["Tralaledon"] = { Rarity = "Celestial" },
        ["Tralalerita Tralala"] = { Rarity = "" },
        ["Tralalero Tralala"] = { Rarity = "" },
        ["Tripi Tropi Tropa Tripa"] = { Rarity = "" },
        ["Trippi Troppi"] = { Rarity = "" },
        ["Trulimero Trulicina"] = { Rarity = "" },
        ["Tubafante"] = { Rarity = "" },
        ["Tuff Toucan"] = { Rarity = "" },
        ["Turtinella Melodica"] = { Rarity = "" },
        ["Udin Din Din Dun"] = { Rarity = "" },
        ["Waterdino"] = { Rarity = "" },
        ["Zibra Zubra Zibralini"] = { Rarity = "" },
    }

    -- ==========================================
    -- FUNGSI INTI & INVENTORY SCANNER
    -- ==========================================
    local function getBaseName(dropdownString) 
        return string.split(dropdownString, " | ")[1] or dropdownString 
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

    local function getToolCPS(tool)
        if not tool then return nil end
        local baseName = tool.Name
        
        local lvlValue = tool:GetAttribute("Level") or tool:GetAttribute("level") or tool:GetAttribute("Lvl")
        if not lvlValue then
            local lvlObj = tool:FindFirstChild("Level") or tool:FindFirstChild("level") or tool:FindFirstChild("Lvl")
            if lvlObj and (lvlObj:IsA("IntValue") or lvlObj:IsA("NumberValue") or lvlObj:IsA("StringValue")) then lvlValue = lvlObj.Value end
        end
        local level = tonumber(lvlValue) or 1
        local mutation = getToolMutation(tool)
        
        local EntitiesDataModule, MutationDataModule
        pcall(function()
            local Shared = ReplicatedStorage:FindFirstChild("Shared")
            local Data = Shared and Shared:FindFirstChild("Data")
            
            local EntitiesDataObj = Data and Data:FindFirstChild("EntitiesData")
            if EntitiesDataObj then EntitiesDataModule = require(EntitiesDataObj) end
            
            local MutationDataObj = Data and Data:FindFirstChild("MutationData")
            if MutationDataObj then MutationDataModule = require(MutationDataObj) end
        end)
        
        if EntitiesDataModule and EntitiesDataModule.Brainrots and EntitiesDataModule.Brainrots[baseName] then
            local info = EntitiesDataModule.Brainrots[baseName]
            local baseCPS = info.CPS
            if baseCPS then
                local levelMult = 1
                if EntitiesDataModule.GetMultiplierPerLevel then
                    pcall(function()
                        levelMult = EntitiesDataModule.GetMultiplierPerLevel(level)
                    end)
                end
                
                local mutMult = 1
                if mutation and MutationDataModule and MutationDataModule.Buffs and MutationDataModule.Buffs[mutation] then
                    mutMult = MutationDataModule.Buffs[mutation].Value or 1
                end
                
                return baseCPS * levelMult * mutMult
            end
        end
        return nil
    end

    local function isTradeable(tool) return tool and tool:IsA("Tool") and getToolGUID(tool) ~= nil end
    
    local function getPlayerList()
        local tbl = {}
        for _, p in ipairs(Players:GetPlayers()) do 
            if p ~= localPlayer then table.insert(tbl, p.Name) end 
        end
        return tbl
    end

    local function getItemInfo(tool)
        if not tool then return "Unknown" end
        local baseName = tool.Name
        local dbInfo = database[baseName]
        
        local rarity = "Unknown"
        
        -- Try to query game's actual EntitiesData module safely at runtime (non-blocking)
        local EntitiesDataModule
        pcall(function()
            local Shared = ReplicatedStorage:FindFirstChild("Shared")
            local Data = Shared and Shared:FindFirstChild("Data")
            local EntitiesDataObj = Data and Data:FindFirstChild("EntitiesData")
            if EntitiesDataObj then
                EntitiesDataModule = require(EntitiesDataObj)
            end
        end)
        
        if EntitiesDataModule and EntitiesDataModule.Brainrots and EntitiesDataModule.Brainrots[baseName] then
            local info = EntitiesDataModule.Brainrots[baseName]
            rarity = info.Rarity or rarity
        end
        
        -- Fallback to static database if the game module query was missing/unknown
        if (rarity == "Unknown" or rarity == "") and dbInfo then
            rarity = dbInfo.Rarity or "Unknown"
        end
        
        return rarity
    end

    local function addRaritiesToCart(TargetCart, SelectedRarities, QtyLimit, IsMax)
        if type(SelectedRarities) ~= "table" then SelectedRarities = {SelectedRarities} end
        local activeRarities = {}
        for _, r in pairs(SelectedRarities) do
            if r ~= "" then activeRarities[r] = true end
        end
        local matchingItems = {}
        for _, tool in ipairs(getAllTools()) do
            if isTradeable(tool) then
                local rarity = getItemInfo(tool)
                if activeRarities[rarity] then
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
        if not hasMut then return {"[NO MUTATION]"} end
        for k, v in pairs(mutCounts) do table.insert(list, k .. " | Stock: " .. v) end
        table.sort(list)
        return list
    end

    local function getInventoryMutationList()
        local mutCounts = {}
        for _, tool in ipairs(getAllTools()) do
            if isTradeable(tool) then
                local m = getToolMutation(tool) or "No Mutation"
                mutCounts[m] = (mutCounts[m] or 0) + 1
            end
        end
        local list = {}
        for k, v in pairs(mutCounts) do
            table.insert(list, k .. " | Stock: " .. v)
        end
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

    local function addMutationsToCart(TargetCart, SelectedOptions, QtyLimit, IsMax)
        if type(SelectedOptions) ~= "table" then SelectedOptions = {SelectedOptions} end
        local activeMutations = {}
        for _, opt in pairs(SelectedOptions) do
            local cleanMut = getBaseName(opt)
            if cleanMut ~= "" and cleanMut ~= "[NO MUTATION]" then activeMutations[cleanMut] = true end
        end
        local matchingItems = {}
        for _, tool in ipairs(getAllTools()) do
            if isTradeable(tool) then
                local mut = getToolMutation(tool)
                if mut and activeMutations[mut] then matchingItems[getFullItemName(tool)] = true end
            end
        end
        for itemName, _ in pairs(matchingItems) do
            local rs = getRealStock(itemName)
            local cur = TargetCart[itemName] or 0
            if IsMax then TargetCart[itemName] = rs elseif QtyLimit > 0 then TargetCart[itemName] = (cur + QtyLimit > rs) and rs or (cur + QtyLimit) end
        end
    end

    local updateInventoryDisplay
    local updateStatsDisplay 

    -- ==========================================
    -- RAYFIELD WINDOW INITIALIZATION -> SIGMA V4
    -- ==========================================
    local Library
    local successUI, err = pcall(function()
        if readfile and isfile and isfile("UI sigma.lua") then
            Library = loadstring(readfile("UI sigma.lua"))()
        else
            Library = loadstring(game:HttpGet('https://github.com/xyaxzj/sigmamaboi.lua/raw/main/NcHO.lua'))()
        end
    end)
    if not Library or type(Library) ~= "table" then return end

    local Window = Library:CreateWindow({
        Name = "Mocta Ultimate Hub V1.8",
        LogoText = "🛒",
        Footer = "v1.8",
        ConfigName = "MoctaTrade"
    })

    -- ==========================================
    -- UNIVERSAL HUD & STATUS WIDGET SYSTEM
    -- ==========================================
    local HUDToggle
    local TradeHUD = Window:CreateHUD({
        Title = "Auto-Trade Status", 
        Width = 180, 
        Height = 90,
        OnClose = function()
            if HUDToggle then HUDToggle:Set(false) end
        end
    })
    local hudQueueLine = TradeHUD:AddLine("Queue: Empty")
    local hudSenderLine = TradeHUD:AddLine("Sender (P1): 🔴 Inactive")
    local hudReceiverLine = TradeHUD:AddLine("Receiver (P2): 🔴 Inactive")

    local function updateTradeHUD()
        local queueCount = #CurrentQueue
        if queueCount > 0 then
            hudQueueLine:SetText("Queue: " .. queueCount .. " items remaining")
            hudQueueLine:SetColor(Color3.fromRGB(255, 200, 50))
        else
            hudQueueLine:SetText("Queue: Empty")
            hudQueueLine:SetColor(Color3.fromRGB(150, 150, 150))
        end
        
        if AutoLoopEnabled then
            hudSenderLine:SetText("Sender (P1): 🟢 Loop Active")
            hudSenderLine:SetColor(Color3.fromRGB(0, 255, 120))
        else
            hudSenderLine:SetText("Sender (P1): 🔴 Inactive")
            hudSenderLine:SetColor(Color3.fromRGB(150, 150, 150))
        end
        
        if AutoReceiverEnabled then
            hudReceiverLine:SetText("Receiver (P2): 🟢 Auto-Accept")
            hudReceiverLine:SetColor(Color3.fromRGB(0, 255, 120))
        else
            hudReceiverLine:SetText("Receiver (P2): 🔴 Inactive")
            hudReceiverLine:SetColor(Color3.fromRGB(150, 150, 150))
        end
        
        if AutoLoopEnabled or AutoReceiverEnabled then
            Window:SetMinimizedGlow("Success")
            if AutoLoopEnabled and AutoReceiverEnabled then
                Window:SetMinimizedText("P1 & P2 Active")
            elseif AutoLoopEnabled then
                Window:SetMinimizedText("P1: " .. queueCount .. " left")
            else
                Window:SetMinimizedText("P2: Active")
            end
        else
            Window:SetMinimizedGlow("TextDim")
            Window:SetMinimizedText("Trade Idle")
        end
    end

    -- Initialize Minimized state status
    Window:SetMinimizedText("Trade Idle")
    Window:SetMinimizedGlow("TextDim")

    -- ==========================================
    -- TAB 1: CART SETUP (TRADE)
    -- ==========================================
    local TabCart = Window:MakeTab("🛒")
    
    local SecCart1 = TabCart:AddSection("Receiver Target")
    local PlayerDropdown = SecCart1:AddDropdown({Name = "Receiver Target (P2)", Options = getPlayerList(), Default = ""}, function(Opt) TargetPlayerName = tostring(Opt) end)
    
    local SecCart2 = TabCart:AddSection("Send All (Bulk)")
    SecCart2:AddButton("Add All Items to Queue", function()
        if TargetPlayerName == "" then return Library:Notify("Attention", "Select target first.", 2) end
        CurrentQueue = {}; ItemsProcessed = 0; local itemsFound = 0
        for _, tool in ipairs(getAllTools()) do if isTradeable(tool) then table.insert(CurrentQueue, tool); itemsFound = itemsFound + 1 end end  
        Library:Notify("Success", itemsFound .. " items added to queue.", 2)
        updateTradeHUD()
    end)
    
    local SecCart3 = TabCart:AddSection("Specific Filter & Mutation")
    local TradeMutationDropdown = SecCart3:AddMultiDropdown({Name = "Select Mutation (Trade)", Options = getMutationList(), Default = {}}, function() end)
    local ItemDropdown = SecCart3:AddMultiDropdown({Name = "Select Custom Item", Options = {"[ANY ASSET]"}, Default = {}}, function() end)
    
    local qtyInputTrade = SecCart3:AddInput({Name = "Amount to send:", Placeholder = "Enter amount..."}, function() end)
    local TradeRarityDropdown = SecCart3:AddMultiDropdown({Name = "Select Rarity (Trade)", Options = RarityList, Default = {}}, function() end)
    
    local CartStatus = SecCart3:AddParagraph("Trade Cart Content", "Empty.")
    local function updateCartDisplay()
        local text = ""; local total = 0
        for name, qty in pairs(ShoppingCart) do if qty > 0 then text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end end
        CartStatus:Set("Trade Cart Content", total == 0 and "Empty." or text .. "\nTotal Items: " .. total)
    end
    
    SecCart3:AddButton("➕ Add Custom by Amount", function() 
        local TradeMixQty = tonumber(qtyInputTrade:Get()) or 0
        local liveSelectedItems = ItemDropdown:Get(); if type(liveSelectedItems) ~= "table" then liveSelectedItems = {liveSelectedItems} end
        for _, optionStr in pairs(liveSelectedItems) do local itemName = getBaseName(optionStr); if itemName ~= "" and itemName ~= "[ANY ASSET]" and TradeMixQty > 0 then local rs = getRealStock(itemName); local cur = ShoppingCart[itemName] or 0; ShoppingCart[itemName] = (cur + TradeMixQty > rs) and rs or (cur + TradeMixQty) end end
        updateCartDisplay() 
    end)
    SecCart3:AddButton("➕ Add Custom All Stock (Max)", function() 
        local liveSelectedItems = ItemDropdown:Get(); if type(liveSelectedItems) ~= "table" then liveSelectedItems = {liveSelectedItems} end
        for _, optionStr in pairs(liveSelectedItems) do local itemName = getBaseName(optionStr); if itemName ~= "" and itemName ~= "[ANY ASSET]" then ShoppingCart[itemName] = getRealStock(itemName) end end
        updateCartDisplay() 
    end)
    SecCart3:AddButton("✨ Add by Mutation (by Amount)", function() local TradeMixQty = tonumber(qtyInputTrade:Get()) or 0; addMutationsToCart(ShoppingCart, TradeMutationDropdown:Get(), TradeMixQty, false); updateCartDisplay() end)
    SecCart3:AddButton("✨ Add by Mutation (Max Stock)", function() local TradeMixQty = tonumber(qtyInputTrade:Get()) or 0; addMutationsToCart(ShoppingCart, TradeMutationDropdown:Get(), TradeMixQty, true); updateCartDisplay() end)
    SecCart3:AddButton("⭐ Add by Rarity (by Amount)", function() 
        local qty = tonumber(qtyInputTrade:Get()) or 0
        local selectedRarities = TradeRarityDropdown:Get()
        addRaritiesToCart(ShoppingCart, selectedRarities, qty, false)
        updateCartDisplay()
    end)
    SecCart3:AddButton("⭐ Add by Rarity (Max Stock)", function() 
        local selectedRarities = TradeRarityDropdown:Get()
        addRaritiesToCart(ShoppingCart, selectedRarities, 0, true)
        updateCartDisplay()
    end)
    SecCart3:AddButton("🗑️ Clear Cart", function() ShoppingCart = {}; updateCartDisplay() end)
    
    SecCart3:AddButton("🚀 Create Queue from Cart", function() 
        if TargetPlayerName == "" then return Library:Notify("Attention", "Select target first.", 2) end
        CurrentQueue = {}; ItemsProcessed = 0; local needed = {}; for k,v in pairs(ShoppingCart) do needed[k] = v end
        local itemsFound = 0
        for _, tool in ipairs(getAllTools()) do if isTradeable(tool) then local name = getFullItemName(tool); if needed[name] and needed[name] > 0 then table.insert(CurrentQueue, tool); needed[name] = needed[name] - 1; itemsFound = itemsFound + 1 end end end
        Library:Notify("Success", itemsFound .. " items prepared.", 2)
        updateTradeHUD()
    end)

    -- ==========================================
    -- TAB 2: SMART SELL (SELL CART)
    -- ==========================================
    local TabSell = Window:MakeTab("💰")
    local SecSell1 = TabSell:AddSection("1. Sell Cart Setup")
    if not ref_B_Sell then SecSell1:AddParagraph("⚠️ Warning", "Sell remote not found.") end
    
    local SellMutationDropdown = SecSell1:AddMultiDropdown({Name = "Select Mutation (Sell)", Options = getMutationList(), Default = {}}, function() end)
    local SellItemDropdown = SecSell1:AddMultiDropdown({Name = "Select Custom Sell Item", Options = {"[ANY ASSET]"}, Default = {}}, function(Options) SelectedSellItems = Options end)
    local qtyInputSell = SecSell1:AddInput({Name = "Amount to Sell:", Placeholder = "Enter amount..."}, function() end)
    local SellRarityDropdown = SecSell1:AddMultiDropdown({Name = "Select Rarity (Sell)", Options = RarityList, Default = {}}, function() end)
    
    local SellCartStatus = SecSell1:AddParagraph("🛒 Sell Cart", "Empty.")
    local function updateSellCartDisplay()
        local text = ""; local total = 0
        for name, qty in pairs(SellCart) do if qty > 0 then text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end end
        SellCartStatus:Set("🛒 Sell Cart", total == 0 and "Empty." or text .. "\nTotal Items: " .. total)
    end
    
    SecSell1:AddButton("➕ Add Custom by Amount", function() 
        local SelectedSellMixQty = tonumber(qtyInputSell:Get()) or 0
        local lst = type(SelectedSellItems) == "table" and SelectedSellItems or {SelectedSellItems}
        for _, optionStr in pairs(lst) do local itemName = getBaseName(optionStr); if itemName ~= "" and itemName ~= "[ANY ASSET]" and SelectedSellMixQty > 0 then local rs = getRealStock(itemName); local cur = SellCart[itemName] or 0; SellCart[itemName] = (cur + SelectedSellMixQty > rs) and rs or (cur + SelectedSellMixQty) end end
        updateSellCartDisplay() 
    end)
    SecSell1:AddButton("➕ Add Custom All Stock (Max)", function() 
        local lst = type(SelectedSellItems) == "table" and SelectedSellItems or {SelectedSellItems}
        for _, optionStr in pairs(lst) do local itemName = getBaseName(optionStr); if itemName ~= "" and itemName ~= "[ANY ASSET]" then SellCart[itemName] = getRealStock(itemName) end end
        updateSellCartDisplay() 
    end)
    SecSell1:AddButton("✨ Add Mutation (by Amount)", function() local SelectedSellMixQty = tonumber(qtyInputSell:Get()) or 0; addMutationsToCart(SellCart, SellMutationDropdown:Get(), SelectedSellMixQty, false); updateSellCartDisplay() end)
    SecSell1:AddButton("✨ Add Mutation (Max Stock)", function() local SelectedSellMixQty = tonumber(qtyInputSell:Get()) or 0; addMutationsToCart(SellCart, SellMutationDropdown:Get(), SelectedSellMixQty, true); updateSellCartDisplay() end)
    SecSell1:AddButton("⭐ Add by Rarity (by Amount)", function() 
        local qty = tonumber(qtyInputSell:Get()) or 0
        local selectedRarities = SellRarityDropdown:Get()
        addRaritiesToCart(SellCart, selectedRarities, qty, false)
        updateSellCartDisplay()
    end)
    SecSell1:AddButton("⭐ Add by Rarity (Max Stock)", function() 
        local selectedRarities = SellRarityDropdown:Get()
        addRaritiesToCart(SellCart, selectedRarities, 0, true)
        updateSellCartDisplay()
    end)
    SecSell1:AddButton("🗑️ Clear Sell Cart", function() SellCart = {}; updateSellCartDisplay() end)
    
    local SecSell2 = TabSell:AddSection("2. Sell Execution")
    local SellToggle = SecSell2:AddToggle({Name = "🧠 Start Selling", Default = false}, function(Value)
        AutoSellEnabled = Value
        if AutoSellEnabled then
            task.spawn(function()
                while AutoSellEnabled do
                    local character = localPlayer.Character; local humanoid = character and character:FindFirstChildOfClass("Humanoid"); local backpack = localPlayer:FindFirstChild("Backpack")
                    if not humanoid or not backpack or not ref_B_Sell then break end
                    local tempCart = {}; local totalLeft = 0
                    for k,v in pairs(SellCart) do tempCart[k] = v; totalLeft = totalLeft + v end
                    if totalLeft <= 0 then Library:Notify("Done", "All sold / Cart empty.", 3); SellToggle:Set(false); break end
                    local itemsToProcess = {}
                    for _, tool in ipairs(getAllTools()) do if isTradeable(tool) then local name = getFullItemName(tool); if tempCart[name] and tempCart[name] > 0 then table.insert(itemsToProcess, tool); tempCart[name] = tempCart[name] - 1 end end end
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
    end)

    -- ==========================================
    -- TAB 3: BASE MANAGER (PLACE & PICKUP CART)
    -- ==========================================
    local TabBase = Window:MakeTab("🏗️")
    local SecBase1 = TabBase:AddSection("1. Base Cart Setup")
    if not rev_S_Interact then SecBase1:AddParagraph("⚠️ Warning", "Interact remote not found.") end
    
    local BaseMutationDropdown = SecBase1:AddMultiDropdown({Name = "Select Mutation (Base)", Options = getMutationList(), Default = {}}, function() end)
    local PlaceItemDropdown = SecBase1:AddMultiDropdown({Name = "Select Custom Brainrot", Options = {"[ANY ASSET]"}, Default = {}}, function(Options) SelectedPlaceItems = Options end)
    local qtyInputBase = SecBase1:AddInput({Name = "Amount to place:", Placeholder = "Enter amount..."}, function() end)
    local BaseRarityDropdown = SecBase1:AddMultiDropdown({Name = "Select Rarity (Base)", Options = RarityList, Default = {}}, function() end)
    
    local BaseCartStatus = SecBase1:AddParagraph("🛒 Base Cart", "Empty.")
    local function updateBaseCartDisplay()
        local text = ""; local total = 0
        for name, qty in pairs(BaseCart) do if qty > 0 then text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end end
        BaseCartStatus:Set("🛒 Base Cart", total == 0 and "Empty." or text .. "\nTotal Items: " .. total)
    end
    
    SecBase1:AddButton("➕ Add Custom by Amount", function() 
        local SelectedPlaceMixQty = tonumber(qtyInputBase:Get()) or 0
        local lst = type(SelectedPlaceItems) == "table" and SelectedPlaceItems or {SelectedPlaceItems}
        for _, optionStr in pairs(lst) do local itemName = getBaseName(optionStr); if itemName ~= "" and itemName ~= "[ANY ASSET]" and SelectedPlaceMixQty > 0 then local rs = getRealStock(itemName); local cur = BaseCart[itemName] or 0; BaseCart[itemName] = (cur + SelectedPlaceMixQty > rs) and rs or (cur + SelectedPlaceMixQty) end end
        updateBaseCartDisplay() 
    end)
    SecBase1:AddButton("➕ Add Custom All Stock (Max)", function() 
        local lst = type(SelectedPlaceItems) == "table" and SelectedPlaceItems or {SelectedPlaceItems}
        for _, optionStr in pairs(lst) do local itemName = getBaseName(optionStr); if itemName ~= "" and itemName ~= "[ANY ASSET]" then BaseCart[itemName] = getRealStock(itemName) end end
        updateBaseCartDisplay() 
    end)
    SecBase1:AddButton("✨ Add Mutation (by Amount)", function() local SelectedPlaceMixQty = tonumber(qtyInputBase:Get()) or 0; addMutationsToCart(BaseCart, BaseMutationDropdown:Get(), SelectedPlaceMixQty, false); updateBaseCartDisplay() end)
    SecBase1:AddButton("✨ Add Mutation (Max Stock)", function() local SelectedPlaceMixQty = tonumber(qtyInputBase:Get()) or 0; addMutationsToCart(BaseCart, BaseMutationDropdown:Get(), SelectedPlaceMixQty, true); updateBaseCartDisplay() end)
    SecBase1:AddButton("⭐ Add by Rarity (by Amount)", function() 
        local qty = tonumber(qtyInputBase:Get()) or 0
        local selectedRarities = BaseRarityDropdown:Get()
        addRaritiesToCart(BaseCart, selectedRarities, qty, false)
        updateBaseCartDisplay()
    end)
    SecBase1:AddButton("⭐ Add by Rarity (Max Stock)", function() 
        local selectedRarities = BaseRarityDropdown:Get()
        addRaritiesToCart(BaseCart, selectedRarities, 0, true)
        updateBaseCartDisplay()
    end)
    SecBase1:AddButton("🗑️ Clear Base Cart", function() BaseCart = {}; updateBaseCartDisplay() end)
    
    local SecBase2 = TabBase:AddSection("2. Base Coordinate Settings")
    SecBase2:AddInput({Name = "Start from Slot-", Placeholder = "Default: 1"}, function(Text) local num = tonumber(Text); if num and num > 0 then StartSlot = num end end)
    SecBase2:AddInput({Name = "Max Slot Limit", Placeholder = "Default: 30"}, function(Text) local num = tonumber(Text); if num and num > 0 then MaxSlots = num end end)
    
    local SecBase3 = TabBase:AddSection("3. Base Execution")
    local PlaceToggle
    PlaceToggle = SecBase3:AddToggle({Name = "🏗️ Start Auto Place", Default = false}, function(Value)
        if Value then
            CurrentPlaceSlot = StartSlot
            task.spawn(function()
                while PlaceToggle:Get() do
                    local character = localPlayer.Character; local humanoid = character and character:FindFirstChildOfClass("Humanoid"); local backpack = localPlayer:FindFirstChild("Backpack")
                    if not humanoid or not backpack or not rev_S_Interact then break end
                    if CurrentPlaceSlot > MaxSlots then Library:Notify("Done", "Max Slot Limit Reached!", 3); PlaceToggle:Set(false); break end
                    local totalLeft = 0; for _, qty in pairs(BaseCart) do totalLeft = totalLeft + qty end
                    if totalLeft <= 0 then Library:Notify("Done", "Base Cart Empty!", 3); PlaceToggle:Set(false); break end
                    local placedThisLoop = false
                    for itemName, qtyNeeded in pairs(BaseCart) do
                        if qtyNeeded > 0 and CurrentPlaceSlot <= MaxSlots then
                            local itemToPlace = nil
                            for _, t in ipairs(getAllTools()) do if getFullItemName(t) == itemName then itemToPlace = t; break end end
                            if itemToPlace then
                                if itemToPlace.Parent ~= character then humanoid:EquipTool(itemToPlace); task.wait(0.15) end
                                pcall(function() rev_S_Interact:FireServer(CurrentPlaceSlot) end)
                                BaseCart[itemName] = BaseCart[itemName] - 1; CurrentPlaceSlot = CurrentPlaceSlot + 1; placedThisLoop = true; task.wait(0.15)
                            end
                        end
                    end
                    updateBaseCartDisplay()
                    if not placedThisLoop then task.wait(0.5) end
                end
            end)
        end
    end)
    
    local PickupToggle
    PickupToggle = SecBase3:AddToggle({Name = "🧲 Start Auto Pickup (Clean Sweep)", Default = false}, function(Value)
        if Value then
            task.spawn(function()
                local character = localPlayer.Character; local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid:UnequipTools() end; task.wait(0.2)
                for i = StartSlot, MaxSlots do if not PickupToggle:Get() then break end; pcall(function() rev_S_Interact:FireServer(i) end); task.wait(0.15) end
                Library:Notify("Done", "Clean sweep Pickup complete!", 3); PickupToggle:Set(false)
            end)
        end
    end)

    -- ==========================================
    -- TAB 4: ACTION CENTER (UNLIMITED BURST)
    -- ==========================================
    local TabAction = Window:MakeTab("💣")
    local SecAction = TabAction:AddSection("Burst Control")
    
    SecAction:AddParagraph("⚠️ UNLIMITED BURST WARNING", "Once pressed, the bot will search, equip, and click the item until INVENTORY STOCK IS COMPLETELY EMPTY (0).")

    SecAction:AddInput({Name = "Target Item Name:", Placeholder = "Example: Block Cup"}, function(Text)
        TargetToolNameAction = Text
        Library:Notify("Target Updated", "Locking target to: " .. TargetToolNameAction, 2)
    end)

    SecAction:AddButton("🚀 EXECUTE UNLIMITED BURST", function()
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local backpack = localPlayer:FindFirstChild("Backpack")
        
        if not char or not humanoid or not backpack then
            Library:Notify("Error", "Character or Backpack not found!", 3)
            return
        end

        local initialCheck = char:FindFirstChild(TargetToolNameAction) or backpack:FindFirstChild(TargetToolNameAction)
        if not initialCheck then
            Library:Notify("Failed", "Item '" .. TargetToolNameAction .. "' tidak ada di tas.", 3)
            return
        end

        Library:Notify("ACTION!", "Starting stock slaughter of " .. TargetToolNameAction .. "...", 3)

        task.spawn(function()
            local activeTool = char:FindFirstChild(TargetToolNameAction) or backpack:FindFirstChild(TargetToolNameAction)
            local clickCount = 0
            
            while activeTool do
                if activeTool.Parent ~= char then
                    humanoid:EquipTool(activeTool)
                    task.wait(0.1) 
                end
                
                activeTool:Activate()
                clickCount = clickCount + 1
                task.wait(0.1) 
                
                if not activeTool or not activeTool.Parent or activeTool.Parent == workspace then
                    activeTool = char:FindFirstChild(TargetToolNameAction) or backpack:FindFirstChild(TargetToolNameAction)
                end
            end
            
            Library:Notify("Completely Drained!", "Execution complete. Total clicks: " .. clickCount .. "x.", 5)
            print("[MOCTA] Execution finished. Total " .. TargetToolNameAction .. " executed: " .. clickCount)
        end)
    end)

    -- ==========================================
    -- TAB 5: STOCK & STORAGE (INVENTORY)
    -- ==========================================
    local TabInventory = Window:MakeTab("🎒")
    
    local SecInvFilter = TabInventory:AddSection("Filter Settings")
    
    InvRarityDropdown = SecInvFilter:AddMultiDropdown({
        Name = "Filter by Rarity",
        Options = RarityList,
        Default = {}
    }, function()
        if refreshInventoryText then
            refreshInventoryText()
        end
    end)
    
    InvMutationDropdown = SecInvFilter:AddMultiDropdown({
        Name = "Filter by Mutation",
        Options = {},
        Default = {}
    }, function()
        if refreshInventoryText then
            refreshInventoryText()
        end
    end)
    
    SecInvFilter:AddButton("🧹 Clear Filters", function()
        pcall(function() InvRarityDropdown:Set({}) end)
        pcall(function() InvMutationDropdown:Set({}) end)
        if refreshInventoryText then
            refreshInventoryText()
        end
    end)
    
    local SecInv = TabInventory:AddSection("Information")
    local FullInventoryLabel = SecInv:AddParagraph("Item List & Total", "Syncing...")
    SecInv:AddButton("🔄 Manual Update Inventory Data", function() updateInventoryDisplay() end)

    -- ==========================================
    -- TAB 6: DISPATCH SENDER (P1)
    -- ==========================================
    local TabDispatch = Window:MakeTab("📤")
    local SecDispatch = TabDispatch:AddSection("Dispatch Control")
    local LiveProgress = SecDispatch:AddParagraph("Dispatch Status", "Remaining Queue: 0\nSuccess: 0")
    local ActionLog = SecDispatch:AddParagraph("Process Log", "Waiting for command...")
    local function setLog(txt) ActionLog:Set("Process Log", txt) end
    SecDispatch:AddSlider({Name = "Input Delay", Min = 0.1, Max = 1.0, Step = 0.1, Default = 0.3}, function(v) InsertDelay = v end)

    local function executeSenderBatch()
        if IsProcessing or #CurrentQueue == 0 then return false end
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then setLog("❌ Target missing!"); return false end
        
        IsProcessing = true
        setLog("1️⃣ Sending trade...")
        task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)
        
        local tradeFrame = nil; local timer = 0
        while timer < 15 do
            tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
            if tradeFrame and tradeFrame.Visible then break end
            task.wait(1); timer = timer + 1
        end
        if not (tradeFrame and tradeFrame.Visible) then setLog("❌ Target timeout."); IsProcessing = false; return false end
        
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
        
        P1TradesCompleted = P1TradesCompleted + 1; ItemsProcessed = ItemsProcessed + batchSize; TotalItemsSent = TotalItemsSent + batchSize
        
        -- Always track cumulative sent in the background
        if not CumulativeSent[target.Name] then CumulativeSent[target.Name] = {} end
        local playerSent = CumulativeSent[target.Name]
        for _, name in ipairs(names) do
            playerSent[name] = (playerSent[name] or 0) + 1
        end

        if ConsoleStats then
            if _G.TradeLogsMode == "Documentation" then
                local details = getCumulativeDetails(playerSent)
                ConsoleStats:Log("Total Sent to " .. target.Name .. ": " .. details, "success")
            elseif _G.TradeLogsMode == "Both" then
                local detailed = groupItems(names)
                local cumulative = getCumulativeDetails(playerSent)
                ConsoleStats:Log("Send: " .. detailed .. " to " .. target.Name, "success")
                ConsoleStats:Log("Total Sent to " .. target.Name .. ": " .. cumulative, "info")
            else -- Detailed
                local details = groupItems(names)
                ConsoleStats:Log("Send: " .. details .. " to " .. target.Name, "success")
            end
        end
        
        LiveProgress:Set("Status", string.format("Remaining: %d\nSuccess: %d", #CurrentQueue, ItemsProcessed))
        updateStatsDisplay(); updateTradeHUD(); IsProcessing = false; return true
    end

    SecDispatch:AddButton("▶️ Send 1 Batch", function() task.spawn(executeSenderBatch) end)
    SecDispatch:AddToggle({Name = "🔁 Auto-Loop", Default = false}, function(V) 
        AutoLoopEnabled = V 
        updateTradeHUD()
        if V then task.spawn(function() while AutoLoopEnabled do if #CurrentQueue == 0 then AutoLoopEnabled = false; updateTradeHUD(); break end executeSenderBatch(); task.wait(2.5) end end) end 
    end)

    -- ==========================================
    -- TAB 7: INBOUND RECEIVER (P2)
    -- ==========================================
    local TabInbound = Window:MakeTab("📥")
    local SecInbound = TabInbound:AddSection("Inbound Control")
    local ReceiverLog = SecInbound:AddParagraph("Status", "Inactive.")
    SecInbound:AddToggle({Name = "🤖 Auto-Accept", Default = false}, function(Value)
        AutoReceiverEnabled = Value
        updateTradeHUD()
        if AutoReceiverEnabled then
            ReceiverLog:Set("Status", "🟢 Active...")
            task.spawn(function()
                while AutoReceiverEnabled do
                    local tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
                    if not (tradeFrame and tradeFrame.Visible) then
                        local pGui = localPlayer:FindFirstChild("PlayerGui")
                        if pGui then
                            for _, gui in ipairs(pGui:GetChildren()) do
                                if gui:IsA("ScreenGui") and gui.Name ~= "Sigma UI" and gui.Name ~= "Rayfield" then
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
                        local receivedNames = {}
                        pcall(function()
                            local p2Frame = tradeFrame:FindFirstChild("P2_Frame")
                            if p2Frame then
                                for _, slot in ipairs(p2Frame:GetDescendants()) do
                                    if slot:IsA("TextLabel") and slot.Visible and slot.Text ~= "" and slot.Text ~= "Confirmed" then
                                        local isPlayer = false
                                        for _, p in ipairs(Players:GetPlayers()) do
                                            if p.Name == slot.Text or p.DisplayName == slot.Text then isPlayer = true break end
                                        end
                                        if not isPlayer and not tonumber(slot.Text) and #slot.Text > 2 then
                                            table.insert(receivedNames, slot.Text)
                                        end
                                    end
                                end
                            end
                        end)
                        P2TradesCompleted = P2TradesCompleted + 1; updateStatsDisplay(); updateTradeHUD()
                        if ConsoleStats then
                            local partnerName = "Opponent"
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= localPlayer then
                                    if tradeFrame:FindFirstChild(p.Name, true) or tradeFrame:FindFirstChild(p.DisplayName, true) then
                                        partnerName = p.Name
                                        break
                                    end
                                end
                            end

                            if #receivedNames > 0 then
                                -- Always track cumulative received in the background
                                if not CumulativeReceived[partnerName] then CumulativeReceived[partnerName] = {} end
                                local playerRec = CumulativeReceived[partnerName]
                                for _, name in ipairs(receivedNames) do
                                    playerRec[name] = (playerRec[name] or 0) + 1
                                end

                                if _G.TradeLogsMode == "Documentation" then
                                    local details = getCumulativeDetails(playerRec)
                                    ConsoleStats:Log("Total Received from " .. partnerName .. ": " .. details, "info")
                                elseif _G.TradeLogsMode == "Both" then
                                    local detailed = groupItems(receivedNames)
                                    local cumulative = getCumulativeDetails(playerRec)
                                    ConsoleStats:Log("Receive: " .. detailed .. " from " .. partnerName, "info")
                                    ConsoleStats:Log("Total Received from " .. partnerName .. ": " .. cumulative, "info")
                                else -- Detailed
                                    ConsoleStats:Log("Receive: " .. groupItems(receivedNames) .. " from " .. partnerName, "info")
                                end
                            else
                                ConsoleStats:Log("Receive: Incoming trade completed successfully.", "info")
                            end
                        end
                    end
                end
            end)
        else 
            ReceiverLog:Set("Status", "❌ Disabled.") 
            updateTradeHUD()
        end
    end)

    -- ==========================================
    -- TAB 8: DASHBOARD
    -- ==========================================
    local TabStats = Window:MakeTab("📊")
    local SecStats = TabStats:AddSection("Statistics")
    local StatsDisplay = SecStats:AddParagraph("Current Session", "Calculating...")
    SecStats:AddDropdown({Name = "Console Log Mode", Options = {"Detailed", "Documentation", "Both"}, Default = "Detailed"}, function(val)
        _G.TradeLogsMode = val
    end)
    SecStats:AddButton("🧹 Clear Console Logs", function()
        if ConsoleStats then
            ConsoleStats:Clear()
        end
    end)
    ConsoleStats = SecStats:AddConsole("Trade History Logs")
    pcall(function()
        local dbCount = 0
        for _ in pairs(database) do dbCount = dbCount + 1 end
        ConsoleStats:Log("Static database embedded successfully.", "success")
        ConsoleStats:Log("Loaded " .. tostring(dbCount) .. " entity templates.", "info")
    end)
    
    updateStatsDisplay = function()
        local elapsedTime = tick() - SessionStartTime
        local str = "Uptime: " .. formatTime(elapsedTime) .. "\n"
        str = str .. "Total P1 Transactions (Send): " .. P1TradesCompleted .. " times\n"
        str = str .. "Total P2 Transactions (Receive): " .. P2TradesCompleted .. " times\n"
        str = str .. "Total Items Sent: " .. TotalItemsSent .. " items"
        
        StatsDisplay:Set("Real-Time Statistics", str)
    end

    task.spawn(function() while task.wait(1) do if updateStatsDisplay then updateStatsDisplay() end end end)

    -- ==========================================
    -- TAB 9: SETTINGS
    -- ==========================================
    local TabSettings = Window:MakeTab("⚙️")
    local SecSet = TabSettings:AddSection("System")
    HUDToggle = SecSet:AddToggle({Name = "📺 Show Status HUD", Default = true}, function(state)
        TradeHUD:SetVisible(state)
    end)
    SecSet:AddButton("🔄 Update Script", function() Library.Unloaded = true; task.wait(0.5); loadstring(game:HttpGet(SCRIPT_URL))() end)

    -- ==========================================
    -- INVENTORY SYNC ENGINE
    -- ==========================================
    local refreshInventoryText
    refreshInventoryText = function()
        if not CachedInventoryData then return end
        
        local selectedRarities = {}
        if InvRarityDropdown then
            selectedRarities = InvRarityDropdown:Get()
            if type(selectedRarities) ~= "table" then selectedRarities = {selectedRarities} end
        end
        
        local selectedMutations = {}
        if InvMutationDropdown then
            selectedMutations = InvMutationDropdown:Get()
            if type(selectedMutations) ~= "table" then selectedMutations = {selectedMutations} end
        end
        
        local hasRarityFilter = false
        for _, r in pairs(selectedRarities) do
            if r ~= "" then
                hasRarityFilter = true
                break
            end
        end
        
        local hasMutationFilter = false
        for _, m in pairs(selectedMutations) do
            local cleanM = getBaseName(m)
            if cleanM ~= "" then
                hasMutationFilter = true
                break
            end
        end
        
        local isFiltered = hasRarityFilter or hasMutationFilter
        
        local categorizedItems = {}
        local categoryTotals = {}
        local filteredTotalCount = 0
        
        local InfiniteMath
        pcall(function()
            local Shared = ReplicatedStorage:FindFirstChild("Shared")
            local Utility = Shared and Shared:FindFirstChild("Utility")
            local IMObj = Utility and Utility:FindFirstChild("InfiniteMath")
            if IMObj then InfiniteMath = require(IMObj) end
        end)
        
        local totalCPSVal = InfiniteMath and InfiniteMath.new(0) or 0
        local filteredCPSVal = InfiniteMath and InfiniteMath.new(0) or 0
        local itemFilterPassed = {}
        
        for itemName, amount in pairs(CachedInventoryData) do
            local itemRarity = "Unknown"
            local itemMutation = nil
            local itemCPS = nil
            for _, tool in ipairs(getAllTools()) do
                if isTradeable(tool) and getFullItemName(tool) == itemName then
                    itemRarity = getItemInfo(tool)
                    itemMutation = getToolMutation(tool)
                    itemCPS = getToolCPS(tool)
                    break
                end
            end
            local filterMut = itemMutation or "No Mutation"
            
            -- Rarity filter match check
            local rarityPass = true
            if hasRarityFilter then
                local found = false
                for _, r in pairs(selectedRarities) do
                    if r == itemRarity then
                        found = true
                        break
                    end
                end
                if not found then rarityPass = false end
            end
            
            -- Mutation filter match check
            local mutationPass = true
            if hasMutationFilter then
                local found = false
                for _, m in pairs(selectedMutations) do
                    local cleanM = getBaseName(m)
                    if cleanM == filterMut then
                        found = true
                        break
                    end
                end
                if not found then mutationPass = false end
            end
            
            if rarityPass and mutationPass then
                itemFilterPassed[itemName] = true
                local category = "🏆 " .. string.upper(itemRarity) .. " ITEMS"
                if not categorizedItems[category] then
                    categorizedItems[category] = {}
                    categoryTotals[category] = 0
                end
                table.insert(categorizedItems[category], {name = itemName, qty = amount, rarity = itemRarity, cps = itemCPS})
                categoryTotals[category] = categoryTotals[category] + amount
                filteredTotalCount = filteredTotalCount + amount
            end
        end
        
        -- Single-pass optimization to sum all tools' CPS
        for _, tool in ipairs(getAllTools()) do
            if isTradeable(tool) then
                local toolCPS = getToolCPS(tool)
                if toolCPS then
                    totalCPSVal = totalCPSVal + toolCPS
                    local fullName = getFullItemName(tool)
                    if itemFilterPassed[fullName] then
                        filteredCPSVal = filteredCPSVal + toolCPS
                    end
                end
            end
        end
        
        local totalCpsStr = tostring(totalCPSVal)
        local filteredCpsStr = tostring(filteredCPSVal)
        
        local displayString = ""
        if isFiltered then
            displayString = string.format("Showing %d / %d Items (Filtered)\n", filteredTotalCount, CachedTotalCount)
            displayString = displayString .. "Filtered CPS: " .. filteredCpsStr .. "  │  Total CPS: " .. totalCpsStr .. "\n\n"
            if filteredTotalCount == 0 then
                displayString = displayString .. "No items match the selected filters."
            end
        else
            displayString = "Total All Items: " .. CachedTotalCount .. "\n"
            displayString = displayString .. "Total CPS: " .. totalCpsStr .. "\n\n"
            if CachedTotalCount == 0 then
                displayString = displayString .. "Empty."
            end
        end
        
        if filteredTotalCount > 0 then
            local sortedCategories = {}
            for cat, _ in pairs(categorizedItems) do table.insert(sortedCategories, cat) end
            table.sort(sortedCategories)
            for _, cat in ipairs(sortedCategories) do
                displayString = displayString .. "=== " .. cat .. " (Total: " .. categoryTotals[cat] .. ") ===\n"
                table.sort(categorizedItems[cat], function(a, b) return a.name < b.name end)
                for _, item in ipairs(categorizedItems[cat]) do 
                    local cpsStr = item.cps and (" │ CPS: " .. tostring(item.cps)) or ""
                    displayString = displayString .. string.format(" • %s (Stock: %d%s)\n", item.name, item.qty, cpsStr) 
                end
                displayString = displayString .. "\n"
            end
        end
        
        if FullInventoryLabel then
            FullInventoryLabel:Set("Item List & Total", displayString)
        end
    end

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
            CachedInventoryData = inventoryData
            CachedTotalCount = totalCount
            
            local itemsList = {"[ANY ASSET]"}  
            for name, count in pairs(inventoryData) do 
                local rarity = "Unknown"
                for _, tool in ipairs(getAllTools()) do
                    if isTradeable(tool) and getFullItemName(tool) == name then
                        rarity = getItemInfo(tool)
                        break
                    end
                end
                
                table.insert(itemsList, string.format("%s | %s | Stock: %d", name, rarity, count))
            end  
            table.sort(itemsList, function(a, b) if a == "[ANY ASSET]" then return true end if b == "[ANY ASSET]" then return false end return a < b end)  
            
            local mutList = getMutationList()
            ItemDropdown:Refresh(itemsList)
            SellItemDropdown:Refresh(itemsList)
            PlaceItemDropdown:Refresh(itemsList)
            TradeMutationDropdown:Refresh(mutList) 
            SellMutationDropdown:Refresh(mutList)
            BaseMutationDropdown:Refresh(mutList)
            PlayerDropdown:Refresh(getPlayerList())
            
            local invMutList = getInventoryMutationList()
            if InvMutationDropdown then
                InvMutationDropdown:Refresh(invMutList)
            end
            
            refreshInventoryText()
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
    pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Error", Text = tostring(errorMessage), Duration = 20}) end)
end
