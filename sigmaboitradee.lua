-- ==========================================================
-- MOCTA TRADE AUTOMATOR V18.12 (BULLETPROOF LOGIC EDITION)
-- Build: Direct-Read Dropdown Fix, Flawless Multi-Select
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
    local TradeHistoryString = "No transaction history available."

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
        if not hasMut then return {"[NO MUTATION]"} end
        for k, v in pairs(mutCounts) do 
            table.insert(list, k .. " | Stock: " .. v) 
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
        Name = "Mocta Trade Automator", 
        LoadingTitle = "Initializing Systems...", 
        ConfigurationSaving = { Enabled = false }, 
        Theme = "DarkBlue"
    })

    -- ==========================================
    -- TAB 1: CART SETUP & INVENTORY
    -- ==========================================
    local TabCart = Window:CreateTab("Cart Setup", 4483362458)
    
    local PlayerDropdown = TabCart:CreateDropdown({
        Name = "Target Player (P2)", Options = getPlayerList(), CurrentOption = {""}, MultipleOptions = false, 
        Callback = function() end -- Kosong agar kita mengambil data live dari Dropdown.CurrentOption
    })

    TabCart:CreateSection("Mass Operations")
    TabCart:CreateButton({
        Name = "Queue Full Inventory",
        Callback = function()
            local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Notice", Content = "Select a target player first.", Duration = 2}) end
            CurrentQueue = {}; ItemsProcessed = 0; local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do  
                if isTradeable(tool) then table.insert(CurrentQueue, tool); itemsFound = itemsFound + 1 end  
            end  
            Rayfield:Notify({Title = "Queued", Content = itemsFound .. " total items ready for dispatch.", Duration = 2})
        end
    })

    TabCart:CreateSection("Categorized Filters")
    local MutationDropdown = TabCart:CreateDropdown({
        Name = "Mutation Filter (Multi-Select)", Options = getMutationList(), CurrentOption = {}, MultipleOptions = true, 
        Callback = function() end
    })
    
    TabCart:CreateButton({
        Name = "Queue by Selected Mutations",
        Callback = function()
            local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Notice", Content = "Select a target player first.", Duration = 2}) end
            
            -- DIRECT READ FIX: Ambil langsung dari UI Dropdown yang berjalan
            local liveSelectedMutations = MutationDropdown.CurrentOption
            if type(liveSelectedMutations) ~= "table" then liveSelectedMutations = {liveSelectedMutations} end
            
            local targetMuts = {}
            local hasValid = false
            for _, optionStr in pairs(liveSelectedMutations) do
                if type(optionStr) == "string" and optionStr ~= "[NO MUTATION]" and optionStr ~= "" then
                    local baseMut = string.split(optionStr, " | Stock:")[1]
                    if baseMut then targetMuts[baseMut] = true; hasValid = true end
                end
            end

            if not hasValid then 
                return Rayfield:Notify({Title = "Notice", Content = "Select at least one valid mutation filter.", Duration = 2}) 
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
            Rayfield:Notify({Title = "Queued", Content = itemsFound .. " items matching selected filters ready.", Duration = 2})
        end
    })

    TabCart:CreateSection("Custom Basket Builder")
    local SelectedMixQty = 0
    local function getBaseName(dropdownString) return string.split(dropdownString, " | Stock:")[1] or dropdownString end

    local ItemDropdown = TabCart:CreateDropdown({
        Name = "Select Assets (Multi-Select)", Options = {"[ANY ASSET]"}, CurrentOption = {}, MultipleOptions = true, 
        Callback = function() end
    })
    
    TabCart:CreateInput({
        Name = "Input Quantity", PlaceholderText = "Amount to apply to selected...", RemoveTextAfterFocusLost = false, 
        Callback = function(Text) SelectedMixQty = tonumber(Text) or 0 end
    })
    
    local CartStatus = TabCart:CreateParagraph({Title = "Basket Status", Content = "Basket is empty."})

    local function updateCartDisplay()
        local text = ""; local total = 0
        for name, qty in pairs(ShoppingCart) do text = text .. "- " .. name .. " (x" .. qty .. ")\n"; total = total + qty end
        if total == 0 then text = "Basket is empty." else text = text .. "\nTotal Assets: " .. total end
        CartStatus:Set({Title = "Basket Status", Content = text})
    end

    TabCart:CreateButton({
        Name = "Add Specified Quantity to Selected", 
        Callback = function() 
            -- DIRECT READ FIX
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
                if addedItems > 0 then
                    updateCartDisplay()
                else
                    Rayfield:Notify({Title = "Action Failed", Content = "Please check items from the dropdown.", Duration = 3})
                end
            else
                Rayfield:Notify({Title = "Action Failed", Content = "Input quantity must be more than 0.", Duration = 3})
            end 
        end
    })
    
    TabCart:CreateButton({
        Name = "Add Maximum Stock for Selected", 
        Callback = function() 
            -- DIRECT READ FIX
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
            
            if addedItems > 0 then
                updateCartDisplay() 
            else
                Rayfield:Notify({Title = "Action Failed", Content = "Please select at least 1 item from the dropdown.", Duration = 3})
            end 
        end
    })
    
    TabCart:CreateButton({Name = "Clear Basket", Callback = function() ShoppingCart = {}; updateCartDisplay() end})

    TabCart:CreateButton({
        Name = "Generate Queue from Basket", 
        Callback = function() 
            local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
            if TargetPlayerName == "" then return Rayfield:Notify({Title = "Notice", Content = "Select a target player first.", Duration = 2}) end
            
            CurrentQueue = {}; ItemsProcessed = 0; local needed = {}; for k,v in pairs(ShoppingCart) do needed[k] = v end
            local itemsFound = 0
            for _, tool in ipairs(getAllTools()) do 
                if isTradeable(tool) then 
                    local name = getFullItemName(tool) 
                    if needed[name] and needed[name] > 0 then table.insert(CurrentQueue, tool); needed[name] = needed[name] - 1; itemsFound = itemsFound + 1 end 
                end 
            end
            Rayfield:Notify({Title = "Queued", Content = itemsFound .. " custom basket items ready.", Duration = 2})
        end
    })

    TabCart:CreateSection("Live Database Inventory")
    local FullInventoryLabel = TabCart:CreateParagraph({Title = "Local Asset Database", Content = "Synchronizing data..."})

    -- ==========================================
    -- TAB 2: AUTO DISPATCHER (P1)
    -- ==========================================
    local TabDispatch = Window:CreateTab("Auto Dispatcher", 4483362458)
    local LiveProgress = TabDispatch:CreateParagraph({Title = "Dispatcher Progress", Content = "Remaining: 0\nDispatched: 0"})
    local ActionLog = TabDispatch:CreateParagraph({Title = "Execution Log", Content = "Awaiting commands..."})

    local function updateProgressUI() LiveProgress:Set({Title = "Dispatcher Progress", Content = string.format("Remaining Items: %d\nItems Dispatched: %d", #CurrentQueue, ItemsProcessed)}) end
    local function setLog(txt) ActionLog:Set({Title = "Execution Log", Content = txt}) end

    TabDispatch:CreateSlider({Name = "Insert Delay (Seconds)", Range = {0.1, 1.0}, Increment = 0.1, CurrentValue = 0.3, Callback = function(Value) InsertDelay = Value end})

    local function executeSenderBatch()
        if IsProcessing or #CurrentQueue == 0 then return false end
        
        local TargetPlayerName = PlayerDropdown.CurrentOption[1] or ""
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then setLog("[ERROR] Target player left the server!"); return false end
        
        IsProcessing = true
        setLog("[1/6] Transmitting trade request to " .. target.Name .. "...")
        task.spawn(function() pcall(function() f_trade_r:InvokeServer(target.UserId) end) end)
        
        local tradeFrame = nil
        local timer = 0
        while timer < 15 do
            tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
            if tradeFrame and tradeFrame.Visible then break end
            task.wait(1); timer = timer + 1
        end
        if not (tradeFrame and tradeFrame.Visible) then setLog("[ERROR] Request timeout."); IsProcessing = false; return false end
        
        setLog("[2/6] Inserting assets...")
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
        
        setLog("[3/6] Phase 1 verification (5.5s lock)...")
        task.wait(5.5)
        
        setLog("[4/6] Initial confirmation sent. Awaiting transition...")
        r_trade_i:FireServer("Confirm") 
        task.wait(0.5)

        local waitTimeout = 0
        while tradeFrame and tradeFrame.Parent and tradeFrame.Visible do
            if not isLocalConfirmed(tradeFrame) then break end 
            task.wait(0.2); waitTimeout = waitTimeout + 0.2
            if waitTimeout > 60 then setLog("[ERROR] Stuck in UI transition."); IsProcessing = false; return false end
        end

        if tradeFrame and tradeFrame.Parent and tradeFrame.Visible then
            setLog("[5/6] Transition successful. Phase 2 verification (5.5s lock)...")
            task.wait(5.5)
            
            setLog("[6/6] Final confirmation. Concluding transaction...")
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
        
        TradeHistoryString = string.format("Latest Receiver: %s\n\nTotal Dispatched Assets (Session Wide):\n%s", 
            TargetPlayerName, 
            table.concat(historyLines, "\n")
        )
        
        HistoryLogLabel:Set({Title = "Trade History Ledger", Content = TradeHistoryString})
        updateProgressUI()
        setLog("[SUCCESS] Dispatch completed. " .. batchSize .. " items safely transferred.")
        IsProcessing = false
        return true
    end

    TabDispatch:CreateButton({Name = "Execute Single Batch", Callback = function() task.spawn(executeSenderBatch) end})
    TabDispatch:CreateToggle({
        Name = "Enable Continuous Auto-Loop", CurrentValue = false, 
        Callback = function(Value) 
            AutoLoopEnabled = Value 
            if AutoLoopEnabled then 
                task.spawn(function() 
                    while AutoLoopEnabled do 
                        if #CurrentQueue == 0 then setLog("[STOP] Queue empty. Auto-Loop terminated."); AutoLoopEnabled = false; break end 
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
    local TabInbound = Window:CreateTab("Inbound Engine", 4483362458)
    local ReceiverLog = TabInbound:CreateParagraph({Title = "Engine Status", Content = "Service inactive."})

    TabInbound:CreateToggle({
        Name = "Activate Universal Auto-Accept", CurrentValue = false,
        Callback = function(Value)
            AutoReceiverEnabled = Value
            if AutoReceiverEnabled then
                ReceiverLog:Set({Title = "Engine Status", Content = "🟢 Active. Intercepting incoming requests..."})
                
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
                            ReceiverLog:Set({Title = "Engine Status", Content = "📥 UI opened. Awaiting P1 verification..."})
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            
                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                                ReceiverLog:Set({Title = "Engine Status", Content = "🔒 P1 confirmed. Engaging Phase 1 lock (5.5s)..."})
                                task.wait(5.5)
                                r_trade_i:FireServer("Confirm")
                                task.wait(1) 
                            end

                            ReceiverLog:Set({Title = "Engine Status", Content = "⏳ Awaiting transition screen..."})
                            while tradeFrame.Visible and isOpponentConfirmed(tradeFrame) do task.wait(0.2) end
                            while tradeFrame.Visible and not isOpponentConfirmed(tradeFrame) do task.wait(0.2) end

                            if tradeFrame.Visible and isOpponentConfirmed(tradeFrame) then
                                ReceiverLog:Set({Title = "Engine Status", Content = "🔒 Phase 2 lock engaged (5.5s)..."})
                                task.wait(5.5)
                                r_trade_i:FireServer("Confirm")
                            end

                            ReceiverLog:Set({Title = "Engine Status", Content = "✅ Finalizing inbound transfer..."})
                            while tradeFrame.Visible do task.wait(0.5) end
                            
                            P2TradesCompleted = P2TradesCompleted + 1
                            ReceiverLog:Set({Title = "Engine Status", Content = "✅ Transfer complete. Returning to standby mode..."})
                        end
                    end
                end)
            else
                ReceiverLog:Set({Title = "Engine Status", Content = "❌ Service offline."})
            end
        end,
    })

    -- ==========================================
    -- TAB 4: ANALYTICS & LOGS
    -- ==========================================
    local TabAnalytics = Window:CreateTab("Analytics & Logs", 4483362458)
    
    local AnalyticsLabel = TabAnalytics:CreateParagraph({Title = "Session Overview", Content = "Loading data..."})
    task.spawn(function()
        while task.wait(1) do
            local currentUptime = tick() - SessionStartTime
            local statsText = string.format(
                "⏱️ Session Uptime: %s\n" ..
                "📤 Total Dispatches (P1): %d\n" ..
                "📥 Total Receipts (P2): %d\n" ..
                "📦 Gross Asset Volume Moved: %d",
                formatTime(currentUptime), P1TradesCompleted, P2TradesCompleted, TotalItemsSent
            )
            AnalyticsLabel:Set({Title = "Session Overview", Content = statsText})
        end
    end)

    HistoryLogLabel = TabAnalytics:CreateParagraph({Title = "Trade History Ledger", Content = TradeHistoryString})

    -- ==========================================
    -- TAB 5: SYSTEM SETTINGS
    -- ==========================================
    local TabSettings = Window:CreateTab("Settings", 4483362458)

    TabSettings:CreateSection("System Updates")
    TabSettings:CreateButton({
        Name = "Refresh Script (Hot-Reload)", 
        Callback = function() 
            if SCRIPT_URL == "" then
                Rayfield:Notify({Title = "Error", Content = "GitHub link is not configured.", Duration = 4})
                return
            end
            Rayfield:Notify({Title = "Updating", Content = "Fetching the latest script version...", Duration = 2})
            task.wait(1.5)
            Rayfield:Destroy() 
            task.wait(0.5)
            loadstring(game:HttpGet(SCRIPT_URL))()
        end
    })

    TabSettings:CreateSection("Performance Optimization")
    TabSettings:CreateToggle({
        Name = "Enable UI Suppressor (Anti-Lag)", 
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
        for name, count in pairs(inventoryData) do table.insert(itemsList, name .. " | Stock: " .. count) end  
        table.sort(itemsList, function(a, b) if a == "[ANY ASSET]" then return true end if b == "[ANY ASSET]" then return false end return a < b end)  
        
        ItemDropdown:Refresh(itemsList)
        MutationDropdown:Refresh(getMutationList()) 
        PlayerDropdown:Refresh(getPlayerList())
        
        local displayString = "Total Tradable Assets: " .. totalCount .. "\n\n"  
        if totalCount == 0 then displayString = displayString .. "No assets found in database." else
            local categorizedItems = {}
            for itemName, amount in pairs(inventoryData) do
                local category = "📦 STANDARD ASSETS"
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
                for _, item in ipairs(categorizedItems[cat]) do displayString = displayString .. string.format(" • %s  (Stock: %d)\n", item.name, item.qty) end
                displayString = displayString .. "\n"
            end
        end
        FullInventoryLabel:Set({Title = "Local Asset Database", Content = displayString})
    end

    TabCart:CreateButton({Name = "Refresh Database Sync", Callback = function() updateInventoryDisplay() end})

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
    pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Fatal Engine Error", Text = tostring(errorMessage), Duration = 20}) end)
end
