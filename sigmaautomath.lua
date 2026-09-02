-- ==========================================================
--                  MiRaGe HUB V2.0 — AUTO TRADE ARSENAL
--        Next-Generation Trade, Sell, Base & Action Suite
-- ==========================================================

local success, errorMessage = pcall(function()
    
    local StarterGui = game:GetService("StarterGui")
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UserInputService = game:GetService("UserInputService")

    -- ══════════════════════════════════════════
    -- LOAD MiRaGe UI LIBRARY
    -- ══════════════════════════════════════════
    local MiRaGe
    local loadSuccess = pcall(function()
        if readfile and isfile and isfile("MiRaGe UI.lua") then
            MiRaGe = loadstring(readfile("MiRaGe UI.lua"))()
        else
            MiRaGe = loadstring(readfile("c:\\UI\\MiRaGe UI.lua"))()
        end
    end)

    if not MiRaGe or type(MiRaGe) ~= "table" then
        -- Fallback: load directly from local file path or notify
        local ok, lib = pcall(function()
            return loadstring(readfile("MiRaGe UI.lua"))()
        end)
        if ok and lib then MiRaGe = lib end
    end

    if not MiRaGe then
        warn("[MiRaGe HUB] Failed to load MiRaGe UI Library. Please ensure MiRaGe UI.lua exists.")
        return
    end

    local function notifyUser(title, content, duration, nType)
        pcall(function()
            if MiRaGe and MiRaGe.Notify then
                MiRaGe:Notify({Title = title, Content = content, Duration = duration or 3, Type = nType or "Info"})
            elseif StarterGui then
                StarterGui:SetCore("SendNotification", {
                    Title = tostring(title),
                    Text = tostring(content),
                    Duration = duration or 3
                })
            end
        end)
    end

    -- ══════════════════════════════════════════
    -- LOCATING REMOTES & PACKAGES
    -- ══════════════════════════════════════════
    local networkFolder = ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
    local f_trade_r = networkFolder:WaitForChild("ref_trade_r", 5) 
    local r_trade_i = networkFolder:WaitForChild("rev_trade_i", 5) 
    local rev_trade_start = networkFolder:WaitForChild("rev_trade_start", 5) 
    local rev_ToggleFav = networkFolder:FindFirstChild("rev_ToggleFav") or networkFolder:WaitForChild("rev_ToggleFav", 5)

    local ref_B_Sell = nil
    local rev_S_Interact = nil
    
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "ref_B_Sell" and v:IsA("RemoteFunction") then ref_B_Sell = v end
        if v.Name == "rev_S_Interact" and v:IsA("RemoteEvent") then rev_S_Interact = v end
        if not rev_ToggleFav and v.Name == "rev_ToggleFav" and v:IsA("RemoteEvent") then rev_ToggleFav = v end
    end

    -- ══════════════════════════════════════════
    -- SYSTEM VARIABLES (CARTS & QUEUES)
    -- ══════════════════════════════════════════
    local TargetPlayerName = ""
    local CurrentQueue = {}
    
    local ShoppingCart = {}  -- Trade
    local SellCart = {}      -- Sell
    local BaseCart = {}      -- Place Base
    
    local CachedInventoryData = {}
    local CachedTotalCount = 0
    local CachedFavoriteCount = 0
    local InvRarityDropdown = nil
    local InvMutationDropdown = nil
    local InvFavFilterDropdown = nil
    local isSyncingUI = false
    
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
    local ConsoleStatsReceived
    local NetSentCPS = 0
    local NetReceivedCPS = 0
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
    local SkipSellFavorites = true

    local SelectedPlaceItems = {}
    local SelectedPlaceMixQty = 0
    local AutoPlaceEnabled = false
    local SkipPlaceFavorites = true

    local SelectedBurstItems = {}
    local BurstMultiplier = 50
    local IsBursting = false
    local BurstMode = "Trade Insert"
    local SkipBurstFavorites = true

    local SkipTradeFavorites = true
    local AutoFavoriteNewDrops = false
    local AutoFavRarities = {}

    local database = {}
    pcall(function()
        local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
        local dataFolder = sharedFolder and sharedFolder:FindFirstChild("Data")
        local entitiesDataObj = dataFolder and dataFolder:FindFirstChild("EntitiesData")
        if entitiesDataObj then
            local EntitiesData = require(entitiesDataObj)
            if EntitiesData and EntitiesData.Brainrots then
                for name, info in pairs(EntitiesData.Brainrots) do
                    database[name] = {
                        DisplayName = info.DisplayName or name,
                        Rarity = info.Rarity or "Unknown",
                        BaseCost = info.BaseCost or 0,
                        CPS = info.CPS or 0
                    }
                end
            end
        end
    end)

    -- ══════════════════════════════════════════
    -- RARITIES & EXCLUSIVE PERCENT STAT LOGIC
    -- ══════════════════════════════════════════
    local RARITIES = {
        "Common", "Rare", "Epic", "Legendary", "Mythic", "Godly",
        "Secret", "Void", "Hacked", "Exclusive", "Rainbow",
        "Volcanic", "Celestial", "Abyssal", "Demon", "Eternal", "OG"
    }

    local EXCLUSIVE_RARITIES = {
        Exclusive = true,
        Volcanic = true,
        Celestial = true,
        Abyssal = true,
        Demon = true,
        Secret = true,
        Rainbow = true,
        Eternal = true,
        Hacked = true,
        OG = true,
    }

    -- ══════════════════════════════════════════
    -- CORE FUNCTIONS & INVENTORY ENGINE
    -- ══════════════════════════════════════════
    local getBaseName, formatTime, getAllTools, getToolGUID, getToolMutation, getToolCPS
    local getCPSFromDisplayName, isTradeable, getPlayerList, getItemInfo, getFullItemName
    local getRealStock, addRaritiesToCart, getMutationList, getInventoryMutationList
    local isOpponentConfirmed, isLocalConfirmed, addMutationsToCart
    local isToolFavorite, toggleToolFavorite, setToolFavorite, processFavoriteBatch
    local favoriteCustomItems, favoriteByMutations, favoriteByRarities, favoriteAllInventory, favoriteTopCPS

    function getBaseName(dropdownString) 
        return string.split(dropdownString, " | ")[1] or dropdownString 
    end

    function formatTime(seconds)
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = math.floor(seconds % 60)
        return string.format("%02d:%02d:%02d", h, m, s)
    end

    function getAllTools()
        local tools = {}
        local bp = localPlayer:FindFirstChild("Backpack")
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
        local ch = localPlayer.Character
        if ch then for _, t in ipairs(ch:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
        return tools
    end

    function getToolGUID(tool)
        if not tool then return nil end
        local g = tool:GetAttribute("ToolGUID") or tool:GetAttribute("GUID") or tool:GetAttribute("guid")
        if g then return tostring(g) end
        local gObj = tool:FindFirstChild("ToolGUID") or tool:FindFirstChild("GUID") or tool:FindFirstChild("guid")
        if gObj and gObj:IsA("StringValue") and gObj.Value ~= "" then return gObj.Value end
        return nil
    end

    function isToolFavorite(tool)
        if not tool then return false end
        local favAttr = tool:GetAttribute("Favorite") or tool:GetAttribute("IsFavorite") or tool:GetAttribute("isFavorite") or tool:GetAttribute("Fav")
        if favAttr ~= nil then return favAttr == true or favAttr == "true" or favAttr == 1 end
        local fObj = tool:FindFirstChild("Favorite") or tool:FindFirstChild("IsFavorite") or tool:FindFirstChild("isFavorite") or tool:FindFirstChild("Fav")
        if fObj and (fObj:IsA("BoolValue") or fObj:IsA("IntValue")) then return fObj.Value == true or fObj.Value == 1 end
        return false
    end

    function setToolFavorite(tool, state)
        if not tool or not rev_ToggleFav then return false end
        local guid = getToolGUID(tool)
        local isFav = isToolFavorite(tool)
        if state == nil then
            rev_ToggleFav:FireServer(tool)
            return true
        end
        if (state and not isFav) or (not state and isFav) then
            rev_ToggleFav:FireServer(tool)
            return true
        end
        return false
    end

    function toggleToolFavorite(tool)
        return setToolFavorite(tool, nil)
    end

    function getToolMutation(tool)
        if not tool then return nil end
        local m = tool:GetAttribute("Mutation") or tool:GetAttribute("mutation")
        if m and m ~= "" and m ~= "None" then return tostring(m) end
        local mObj = tool:FindFirstChild("Mutation") or tool:FindFirstChild("mutation")
        if mObj and (mObj:IsA("StringValue") or mObj:IsA("IntValue")) and tostring(mObj.Value) ~= "" and tostring(mObj.Value) ~= "None" then return tostring(mObj.Value) end
        return nil
    end

    local function isExclusiveRarity(tool)
        if not tool then return false end
        local rarity = getItemInfo(tool)
        return EXCLUSIVE_RARITIES[rarity] == true
    end

    local function getExclusivePercent(tool)
        if not tool then return nil end
        local statAttr = tool:GetAttribute("KickPowerMultiplier")
            or tool:GetAttribute("Multiplier")
            or tool:GetAttribute("Percent")
            or tool:GetAttribute("Value")
            or tool:GetAttribute("StatValue")
            or tool:GetAttribute("Power")
            or tool:GetAttribute("Boost")
        if statAttr then
            local num = tonumber(statAttr)
            if num then
                if num > 0 and num <= 50 then
                    return string.format("%.0f%%", num * 100)
                else
                    return string.format("%.0f%%", num)
                end
            end
        end
        for _, child in ipairs(tool:GetChildren()) do
            local lname = child.Name:lower()
            if (lname == "value" or lname == "percent" or lname == "multiplier" or lname == "kickpowermultiplier" or lname == "boost" or lname == "power")
                and (child:IsA("NumberValue") or child:IsA("IntValue")) then
                local num = tonumber(child.Value)
                if num then
                    if num > 0 and num <= 50 then
                        return string.format("%.0f%%", num * 100)
                    else
                        return string.format("%.0f%%", num)
                    end
                end
            end
        end
        return nil
    end

    function getFullItemName(tool)
        local displayName = tool.Name
        local mutValue = getToolMutation(tool)
        if mutValue then displayName = displayName .. " [" .. mutValue .. "]" end

        if isExclusiveRarity(tool) then
            local pct = getExclusivePercent(tool)
            if pct then displayName = displayName .. " (" .. pct .. ")" end
        else
            local lvlValue = tool:GetAttribute("Level") or tool:GetAttribute("level") or tool:GetAttribute("Lvl")
            if not lvlValue then
                local lvlObj = tool:FindFirstChild("Level") or tool:FindFirstChild("level") or tool:FindFirstChild("Lvl")
                if lvlObj and (lvlObj:IsA("IntValue") or lvlObj:IsA("NumberValue") or lvlObj:IsA("StringValue")) then lvlValue = lvlObj.Value end
            end
            if lvlValue then displayName = displayName .. " (Lv." .. tostring(lvlValue) .. ")" end
        end
        return displayName
    end

    function getToolCPS(tool)
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

    function getCPSFromDisplayName(fullName)
        local status, result = pcall(function()
            if not fullName or fullName == "" then return nil end
            if string.match(fullName, "%((%d+%%)%)?") then return nil end

            local level = 1
            local lvlMatch = string.match(fullName, "%(Lv%.(%d+)%)") or string.match(fullName, "Lv%.(%d+)")
            if lvlMatch then level = tonumber(lvlMatch) or 1 end
            
            local mutation = string.match(fullName, "%[(.-)%]")
            
            local baseName = fullName
            baseName = string.gsub(baseName, "%s*%[(.-)%]", "")
            baseName = string.gsub(baseName, "%s*%(Lv%.%d+%)", "")
            baseName = string.gsub(baseName, "%s*%(Lv%.%s*%d+%)", "")
            baseName = string.gsub(baseName, "%s*%(%d+%%%)", "")
            baseName = string.trim and string.trim(baseName) or baseName:match("^%s*(.-)%s*$")
            
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
                if EXCLUSIVE_RARITIES[info.Rarity or ""] then return nil end
                local baseCPS = info.CPS
                if baseCPS then
                    local levelMult = 1
                    if EntitiesDataModule.GetMultiplierPerLevel then
                        pcall(function() levelMult = EntitiesDataModule.GetMultiplierPerLevel(level) end)
                    end
                    local mutMult = 1
                    if mutation and MutationDataModule and MutationDataModule.Buffs and MutationDataModule.Buffs[mutation] then
                        mutMult = MutationDataModule.Buffs[mutation].Value or 1
                    end
                    return baseCPS * levelMult * mutMult
                end
            end
            return nil
        end)
        return status and result or nil
    end

    function isTradeable(tool)
        if not tool or not tool:IsA("Tool") then return false end
        local g = getToolGUID(tool)
        return g ~= nil and g ~= ""
    end

    function getPlayerList()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer then table.insert(list, p.Name) end
        end
        return list
    end

    function getItemInfo(tool)
        local baseName = tool.Name
        if database[baseName] then return database[baseName].Rarity end
        return "Unknown"
    end

    function getRealStock(targetName)
        local count = 0
        for _, tool in ipairs(getAllTools()) do 
            if isTradeable(tool) and getFullItemName(tool) == targetName then count = count + 1 end 
        end
        return count
    end

    -- ══════════════════════════════════════════
    -- CREATE MiRaGe HUB WINDOW
    -- ══════════════════════════════════════════
    local Window = MiRaGe:CreateWindow({
        Title = "MiRaGe HUB",
        Subtitle = "Auto-Trade & Automation Arsenal v2.0",
        Keybind = Enum.KeyCode.RightControl,
        Theme = "VoidMirage"
    })

    -- ══════════════════════════════════════════
    -- TAB 1: 🔁 TRADE DISPATCH
    -- ══════════════════════════════════════════
    Window:AddCategory("Trade Automation")

    local TabTrade = Window:MakeTab({Name = "Trade Dispatch", Icon = "🔁", Badge = "0"})
    
    local SecTarget = TabTrade:AddSection("1. Receiver Target (P2)")
    local TargetSelector = SecTarget:AddTargetSelector(function(p)
        TargetPlayerName = p and p.Name or ""
        notifyUser("Target Selected", "Receiver set to: " .. TargetPlayerName, 2, "Success")
    end)

    local SecCart = TabTrade:AddSection("2. Trade Cart & Bulk Actions")
    SecCart:AddToggle({Name = "⭐ Skip Favorites (Trade Protection)", Default = true}, function(val)
        SkipTradeFavorites = val
    end)

    SecCart:AddButton("📦 Add All Inventory Items to Queue", function()
        if TargetPlayerName == "" then return notifyUser("Attention", "Select target player first!", 2, "Warn") end
        CurrentQueue = {}; ItemsProcessed = 0; local itemsFound = 0
        for _, tool in ipairs(getAllTools()) do
            if isTradeable(tool) then
                if not (SkipTradeFavorites and isToolFavorite(tool)) then
                    table.insert(CurrentQueue, tool)
                    itemsFound = itemsFound + 1
                end
            end
        end
        TabTrade:SetBadge(tostring(#CurrentQueue))
        Window:SetBubbleBadge(tostring(#CurrentQueue))
        notifyUser("Queue Ready", "Added " .. itemsFound .. " items to dispatch queue.", 3, "Success")
    end)

    SecCart:AddButton("🧹 Clear Dispatch Queue", function()
        CurrentQueue = {}; ItemsProcessed = 0
        TabTrade:SetBadge("0")
        Window:SetBubbleBadge("0")
        notifyUser("Queue Cleared", "Dispatch queue has been reset.", 2, "Info")
    end)

    local SecDispatch = TabTrade:AddSection("3. Dispatch Execution")
    local LiveProgress = SecDispatch:AddProgressBar("Dispatch Progress")
    local ActionLog = SecDispatch:AddParagraph("Status", "Waiting for command...")
    local function setLog(txt) ActionLog:Set("Process Log", txt) end

    SecDispatch:AddSlider({Name = "Insert Delay (Seconds)", Min = 0.1, Max = 2.0, Default = 0.3, Suffix = "s"}, function(val)
        InsertDelay = val
    end)

    local function executeSenderBatch()
        if IsProcessing then return false end
        if #CurrentQueue == 0 then setLog("Queue is empty!"); return false end
        
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then setLog("Target missing!"); return false end
        
        IsProcessing = true
        setLog("Sending trade request...")
        rev_trade_start:FireServer(target)
        
        local tradeFrame = nil
        local t0 = tick()
        while tick() - t0 < 5 do
            local pGui = localPlayer:FindFirstChild("PlayerGui")
            if pGui then
                local tradeGui = pGui:FindFirstChild("TradeGui") or pGui:FindFirstChild("Trade")
                if tradeGui and tradeGui.Visible then tradeFrame = tradeGui; break end
            end
            task.wait(0.2)
        end
        
        if not (tradeFrame and tradeFrame.Visible) then
            setLog("Target timeout.")
            IsProcessing = false
            return false
        end

        local batch = {}
        local names = {}
        while #CurrentQueue > 0 and #batch < 3 do
            local tool = table.remove(CurrentQueue, 1)
            if tool and tool.Parent and isTradeable(tool) then
                table.insert(batch, tool)
                table.insert(names, getFullItemName(tool))
            end
        end

        for _, tool in ipairs(batch) do
            local guid = getToolGUID(tool)
            if guid then
                r_trade_i:FireServer(guid)
                task.wait(InsertDelay)
            end
        end

        P1TradesCompleted = P1TradesCompleted + 1
        TotalItemsSent = TotalItemsSent + #batch
        ItemsProcessed = ItemsProcessed + #batch
        TabTrade:SetBadge(tostring(#CurrentQueue))
        Window:SetBubbleBadge(tostring(#CurrentQueue))

        local pct = (#CurrentQueue > 0) and (#batch / (#CurrentQueue + #batch)) or 1
        LiveProgress:Set(pct, string.format("Sent: %d | Left: %d", ItemsProcessed, #CurrentQueue))
        setLog(string.format("Sent batch (%d items). Success!", #batch))

        if ConsoleStats then
            local ts = os.date("%H:%M:%S")
            ConsoleStats:Log(string.format("[%s] 📤 Send → %s | %s", ts, target.Name, groupItems(names)), "success")
        end

        IsProcessing = false
        return true
    end

    SecDispatch:AddButton("▶️ Send 1 Batch", function()
        task.spawn(executeSenderBatch)
    end)

    SecDispatch:AddToggle({Name = "🔁 Auto-Loop Dispatch", Default = false}, function(val)
        AutoLoopEnabled = val
        if val then
            task.spawn(function()
                while AutoLoopEnabled do
                    if #CurrentQueue == 0 then
                        AutoLoopEnabled = false
                        notifyUser("Dispatch Done", "All queue items sent successfully!", 3, "Success")
                        break
                    end
                    executeSenderBatch()
                    task.wait(2.5)
                end
            end)
        end
    end)

    -- ══════════════════════════════════════════
    -- TAB 2: 📥 INBOUND RECEIVER
    -- ══════════════════════════════════════════
    local TabInbound = Window:MakeTab({Name = "Inbound Receiver", Icon = "📥", Badge = "OFF"})
    local SecInbound = TabInbound:AddSection("Inbound Auto-Accept (P2 Mode)")
    local ReceiverStatus = SecInbound:AddParagraph("Status", "Inactive.")

    SecInbound:AddToggle({Name = "🤖 Auto-Accept Incoming Trades", Default = false}, function(val)
        AutoReceiverEnabled = val
        TabInbound:SetBadge(val and "ON" or "OFF")
        ReceiverStatus:Set(val and "🟢 Active listening for trades..." or "🔴 Inactive.")
        if val then
            task.spawn(function()
                while AutoReceiverEnabled do
                    task.wait(0.5)
                    local pGui = localPlayer:FindFirstChild("PlayerGui")
                    if pGui then
                        local tradeGui = pGui:FindFirstChild("TradeGui") or pGui:FindFirstChild("Trade")
                        if tradeGui and tradeGui.Visible then
                            pcall(function()
                                f_trade_r:InvokeServer("Accept")
                            end)
                        end
                    end
                end
            end)
        end
    end)

    -- ══════════════════════════════════════════
    -- TAB 3: ⭐ FAVORITE & LOCK ENGINE
    -- ══════════════════════════════════════════
    local TabFav = Window:MakeTab({Name = "Favorites", Icon = "⭐"})
    local SecFav1 = TabFav:AddSection("Quick Lock Actions")

    SecFav1:AddButton("⭐ Lock Top 10 Highest CPS Items", function()
        local tools = {}
        for _, t in ipairs(getAllTools()) do
            local cps = getToolCPS(t) or 0
            table.insert(tools, {tool = t, cps = cps})
        end
        table.sort(tools, function(a, b) return a.cps > b.cps end)
        local locked = 0
        for i = 1, math.min(10, #tools) do
            setToolFavorite(tools[i].tool, true)
            locked = locked + 1
        end
        notifyUser("Favorites Locked", "Locked top " .. locked .. " highest CPS items!", 3, "Success")
    end)

    SecFav1:AddButton("⭐ Lock All Exclusive & % Stat Items", function()
        local locked = 0
        for _, t in ipairs(getAllTools()) do
            if isExclusiveRarity(t) then
                setToolFavorite(t, true)
                locked = locked + 1
            end
        end
        notifyUser("Exclusives Locked", "Locked " .. locked .. " Exclusive/% items!", 3, "Success")
    end)

    SecFav1:AddButton("✕ Unlock All Inventory Items", function()
        local unlocked = 0
        for _, t in ipairs(getAllTools()) do
            if isToolFavorite(t) then
                setToolFavorite(t, false)
                unlocked = unlocked + 1
            end
        end
        notifyUser("Unlocked", "Unlocked " .. unlocked .. " items.", 3, "Warn")
    end)

    -- ══════════════════════════════════════════
    -- TAB 4: 📊 LIVE DASHBOARD & DUAL LOGS
    -- ══════════════════════════════════════════
    Window:AddCategory("Intelligence")

    local TabStats = Window:MakeTab({Name = "Dashboard & Logs", Icon = "📊", Badge = "Live"})
    local SecSummary = TabStats:AddSection("Session Summary & Net CPS")
    local StatsDisplay = SecSummary:AddParagraph("Real-Time Balance Sheet", "Calculating...")

    local function updateStats()
        local elapsed = tick() - SessionStartTime
        local netCPS = NetReceivedCPS - NetSentCPS
        local netStr = netCPS > 0 and ("+" .. string.format("%.2f", netCPS) .. " CPS ✅ (Profit)") or (netCPS < 0 and (string.format("%.2f", netCPS) .. " CPS ⚠️ (Loss)") or "0 CPS ➖ (Even)")

        local str = "⏱️ Uptime: " .. formatTime(elapsed) .. "\n"
        str = str .. "📤 Trades Sent: " .. P1TradesCompleted .. " tx | Items: " .. TotalItemsSent .. "\n"
        str = str .. "📥 Trades Received: " .. P2TradesCompleted .. " tx\n"
        str = str .. "📊 Net CPS Balance: " .. netStr
        StatsDisplay:Set("Session Statistics", str)
    end

    task.spawn(function()
        while task.wait(1) do updateStats() end
    end)

    local SecSent = TabStats:AddSection("📤 SENT Log (Outgoing)")
    ConsoleStats = SecSent:AddConsole("📤 Outgoing Trade Stream")

    local SecRecv = TabStats:AddSection("📥 RECEIVED Log (Incoming)")
    ConsoleStatsReceived = SecRecv:AddConsole("📥 Incoming Trade Stream")

    ConsoleStats:Log("MiRaGe Trade Dispatcher initialized.", "success")
    ConsoleStatsReceived:Log("MiRaGe Inbound Receiver ready.", "info")

    -- ══════════════════════════════════════════
    -- TAB 5: ⚙️ SETTINGS
    -- ══════════════════════════════════════════
    local TabSet = Window:MakeTab({Name = "Settings", Icon = "⚙️"})
    local SecTheme = TabSet:AddSection("Appearance & UI")

    SecTheme:AddDropdown({Name = "Theme Palette", Options = {"VoidMirage", "Cyberpunk", "EmeraldMatrix", "CrimsonRed"}, Default = "VoidMirage"}, function(tName)
        MiRaGe:SetTheme(tName)
        notifyUser("Theme Applied", "Switched to " .. tName .. " palette.", 2, "Success")
    end)

    SecTheme:AddButton("🧹 Clear Both Logs", function()
        if ConsoleStats then ConsoleStats:Clear() end
        if ConsoleStatsReceived then ConsoleStatsReceived:Clear() end
        notifyUser("Logs Cleared", "Terminal streams cleared.", 2, "Info")
    end)

    notifyUser("MiRaGe HUB v2.0", "Welcome, " .. localPlayer.DisplayName .. "! Press RightControl to toggle.", 4, "Success")

end)

if not success then
    warn("[MiRaGe HUB Error]:", errorMessage)
end
