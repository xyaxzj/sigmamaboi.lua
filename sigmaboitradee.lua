local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- // Services & Remotes // --
local networkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")
local giftRequestRemote = networkFolder:WaitForChild("rev_GiftRequest")

-- // State Variables // --
local GiftingActive = false
local StopThreshold = 0
local TargetPlayerName = ""
local TargetItemName = ""
local CurrentBundle = {}
local InventoryConnections = {}

-- // UI Helper: Progress Bar Generator // --
local function getProgressBar(current, total, length)
    length = length or 20
    if total <= 0 then return "[" .. string.rep("░", length) .. "] 0%" end
    local filled = math.floor((current / total) * length)
    if filled > length then filled = length end
    local empty = length - filled
    local percentage = math.floor((current / total) * 100)
    return "[" .. string.rep("█", filled) .. string.rep("░", empty) .. "] " .. percentage .. "%"
end

-- // Core Functions // --
-- Fungsi membaca tas DAN tangan (Hold-Detection Patch)
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

local function isTradeable(tool)
    if tool and tool:IsA("Tool") then
        return tool:GetAttribute("guid") or tool:GetAttribute("GUID")
    end
    return false
end

local function shuffleTable(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

local function getPlayerList()
    local tbl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then table.insert(tbl, p.Name) end
    end
    return tbl
end

-- Deteksi Mutasi & Level
local function getItemMutation(tool)
    local mut = tool:GetAttribute("Mutation") or tool:GetAttribute("mutation") or tool:GetAttribute("Variant")
    if not mut then
        local mutValue = tool:FindFirstChild("Mutation") or tool:FindFirstChild("Variant")
        if mutValue and mutValue:IsA("StringValue") then mut = mutValue.Value end
    end
    return mut and tostring(mut) or nil
end

local function getItemLevel(tool)
    local lvl = tool:GetAttribute("Level") or tool:GetAttribute("level") or tool:GetAttribute("Lvl")
    if not lvl then
        local lvlValue = tool:FindFirstChild("Level") or tool:FindFirstChild("level") or tool:FindFirstChild("Lvl")
        if lvlValue and (lvlValue:IsA("IntValue") or lvlValue:IsA("NumberValue") or lvlValue:IsA("StringValue")) then lvl = lvlValue.Value end
    end
    return lvl and tonumber(lvl) or nil
end

local function getFullItemName(tool)
    local displayName = tool.Name
    local mut = getItemMutation(tool)
    local lvl = getItemLevel(tool)

    if mut then displayName = displayName .. " [" .. mut .. "]" end  
    if lvl then displayName = displayName .. " (Lv." .. tostring(lvl) .. ")" end  
    return displayName
end

local function getInventoryList()
    local inventoryCounts = {}
    local allTools = getAllTools()

    for _, tool in ipairs(allTools) do  
        if isTradeable(tool) then
            local displayName = getFullItemName(tool)  
            inventoryCounts[displayName] = (inventoryCounts[displayName] or 0) + 1  
        end
    end  

    local itemsList = {"[ANY ASSET]"}  
    for name, count in pairs(inventoryCounts) do  
        table.insert(itemsList, name .. " | Qty: " .. count)  
    end  
      
    table.sort(itemsList, function(a, b)  
        if a == "[ANY ASSET]" then return true end  
        if b == "[ANY ASSET]" then return false end  
        return a < b  
    end)  
      
    return itemsList
end

local function getBaseName(dropdownString)
    if dropdownString == "[ANY ASSET]" then return "" end
    local base = string.split(dropdownString, " | Qty:")[1]
    return base or dropdownString
end

-- // UI Initialization // --
local Window = Rayfield:CreateWindow({
    Name = "Mocta Gifter System",
    LoadingTitle = "Authenticating Protocol...",
    LoadingSubtitle = "Loading Asset Management",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
    Theme = "DarkBlue"
})

-- ==========================================
-- TAB 1: SYSTEM DASHBOARD
-- ==========================================
local TabDashboard = Window:CreateTab("Dashboard", 4483362458)
TabDashboard:CreateSection("Asset Overview")

local InventoryStatusLabel = TabDashboard:CreateParagraph({
    Title = "Real-time Inventory Assessment",
    Content = "Synchronizing data..."
})

TabDashboard:CreateButton({
    Name = "Refresh Database",
    Callback = function()
        updateInventoryDisplay()
        Rayfield:Notify({Title = "System", Content = "Database synchronized.", Duration = 2})
    end,
})

TabDashboard:CreateSection("Emergency Controls")
TabDashboard:CreateButton({
    Name = "TERMINATE ALL OPERATIONS",
    Callback = function()
        GiftingActive = false
        Rayfield:Notify({Title = "Alert", Content = "All active transfers halted.", Duration = 3})
    end,
})

-- ==========================================
-- TAB 2: DIRECT TRANSFER
-- ==========================================
local TabTransfer = Window:CreateTab("Direct Transfer", 4483362458)
TabTransfer:CreateSection("Target Definition")

local PlayerDropdown = TabTransfer:CreateDropdown({
    Name = "Pilih Penerima",
    Options = getPlayerList(),
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Option) TargetPlayerName = Option[1] end,
})

local ItemDropdown = TabTransfer:CreateDropdown({
    Name = "Select Brainrot Type",
    Options = getInventoryList(),
    CurrentOption = {"[ANY ASSET]"},
    MultipleOptions = false,
    Callback = function(Option)
        TargetItemName = getBaseName(Option[1])
    end,
})

TabTransfer:CreateInput({
    Name = "Transfer Quantity",
    PlaceholderText = "Qty",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) StopThreshold = tonumber(Text) or 0 end,
})

TabTransfer:CreateSection("Execution")

-- [ROMBAKAN STATUS DIRECT TRANSFER]
local LiveStatusLabel = TabTransfer:CreateParagraph({
    Title = "⚡ Operation Status",
    Content = "System Standby.\nWaiting for execution..."
})

TabTransfer:CreateButton({
    Name = "INITIATE TRANSFER",
    Callback = function()
        if GiftingActive then return end
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target or StopThreshold <= 0 then
            Rayfield:Notify({Title = "Validation Failed", Content = "Invalid target or quantity.", Duration = 3})
            return
        end

        GiftingActive = true  
        local itemsSent = 0  
        local allTools = getAllTools()  
        local itemsToProcess = {}  

        for _, tool in ipairs(allTools) do  
            if isTradeable(tool) then  
                local displayName = getFullItemName(tool)  
                if TargetItemName == "" or displayName == TargetItemName then  
                    table.insert(itemsToProcess, tool)  
                end  
            end  
        end  

        if TargetItemName == "" then shuffleTable(itemsToProcess) end  
        local displayTargetName = TargetItemName == "" and "Randomized Assets" or TargetItemName  

        for _, tool in ipairs(itemsToProcess) do  
            if itemsSent >= StopThreshold or not GiftingActive then break end  
            
            -- Update Status (Preparing)
            LiveStatusLabel:Set({  
                Title = "⚡ Transferring to: " .. TargetPlayerName,  
                Content = string.format("Asset: %s\nProgress: %d / %d\n%s\nStatus: Equipping...", displayTargetName, itemsSent, StopThreshold, getProgressBar(itemsSent, StopThreshold))  
            })

            local character = localPlayer.Character  
            if character and character:FindFirstChild("Humanoid") then  
                character.Humanoid:EquipTool(tool)  
                task.wait(1.5)  
                
                -- Update Status (Sending)
                LiveStatusLabel:Set({  
                    Title = "⚡ Transferring to: " .. TargetPlayerName,  
                    Content = string.format("Asset: %s\nProgress: %d / %d\n%s\nStatus: Sending Packet...", displayTargetName, itemsSent, StopThreshold, getProgressBar(itemsSent, StopThreshold))  
                })

                giftRequestRemote:FireServer(target.UserId)  
                task.wait(6) -- DELAY 5 DETIK  
                itemsSent = itemsSent + 1  
            end  
        end  

        GiftingActive = false  
        LiveStatusLabel:Set({
            Title = "✅ Operation Concluded", 
            Content = string.format("Successfully sent %d unit(s) to %s.\n%s", itemsSent, TargetPlayerName, getProgressBar(itemsSent, StopThreshold))
        })  
        updateInventoryDisplay()
    end,
})

-- ==========================================
-- TAB 3: PACKAGE AUTO-MIX
-- ==========================================
local TabBundle = Window:CreateTab("Package Auto-Mix", 4483362458)
TabBundle:CreateSection("Package Configuration")

local BundleItemName = ""
local BundleItemQty = 0

local BundleItemDropdown = TabBundle:CreateDropdown({
    Name = "Select Asset to Add",
    Options = getInventoryList(),
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Option)
        BundleItemName = getBaseName(Option[1])
    end,
})

TabBundle:CreateInput({
    Name = "Quantity for this Asset",
    PlaceholderText = "Qty (Leave empty if adding ALL)",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) BundleItemQty = tonumber(Text) or 0 end,
})

local BundleContentLabel = TabBundle:CreateParagraph({
    Title = "Current Package Specifications",
    Content = "Package is empty."
})

local function updateBundleDisplay()
    local text = ""
    local totalItems = 0
    for name, qty in pairs(CurrentBundle) do
        text = text .. string.format("- %s: %d Unit(s)\n", name, qty)
        totalItems = totalItems + qty
    end
    if text == "" then text = "Package is empty." else text = text .. "\nTotal Brainrots in Package: " .. totalItems end
    BundleContentLabel:Set({Title = "Current Package Specifications", Content = text})
end

TabBundle:CreateButton({
    Name = "Add to Package (Specific Qty)",
    Callback = function()
        if BundleItemName ~= "" and BundleItemName ~= "[ANY ASSET]" and BundleItemQty > 0 then
            CurrentBundle[BundleItemName] = (CurrentBundle[BundleItemName] or 0) + BundleItemQty
            updateBundleDisplay()
            Rayfield:Notify({Title = "Package Updated", Content = "Asset added to bundle.", Duration = 2})
        end
    end,
})

TabBundle:CreateButton({
    Name = "Add ALL Available Stock",
    Callback = function()
        if BundleItemName ~= "" and BundleItemName ~= "[ANY ASSET]" then
            local totalAvailable = 0
            local allTools = getAllTools()
            
            for _, tool in ipairs(allTools) do
                if isTradeable(tool) and getFullItemName(tool) == BundleItemName then
                    totalAvailable = totalAvailable + 1
                end
            end

            if totalAvailable > 0 then
                CurrentBundle[BundleItemName] = totalAvailable
                updateBundleDisplay()
                Rayfield:Notify({Title = "Package Updated", Content = "Added ALL (" .. totalAvailable .. ") units of " .. BundleItemName, Duration = 3})
            else
                Rayfield:Notify({Title = "Stock Error", Content = "No stock found for this asset.", Duration = 3})
            end
        else
            Rayfield:Notify({Title = "Selection Error", Content = "Please select a valid asset first.", Duration = 3})
        end
    end,
})

TabBundle:CreateButton({
    Name = "Clear Package",
    Callback = function()
        CurrentBundle = {}
        updateBundleDisplay()
    end,
})

TabBundle:CreateSection("Package Execution")
local BundleReceiverDropdown = TabBundle:CreateDropdown({
    Name = "Select Receiver Identity",
    Options = getPlayerList(),
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Option) TargetPlayerName = Option[1] end,
})

-- [FITUR BARU: STATUS PACKAGE AUTO-MIX]
local PackageStatusLabel = TabBundle:CreateParagraph({
    Title = "📦 Delivery Status",
    Content = "System Standby.\nPackage ready to be dispatched."
})

TabBundle:CreateButton({
    Name = "EXECUTE PACKAGE TRANSFER",
    Callback = function()
        if GiftingActive then return end
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then return Rayfield:Notify({Title = "Error", Content = "Invalid target.", Duration = 3}) end

        local allTools = getAllTools()
        local queue = {}  
        local totalReqAssets = 0
        
        for reqItemName, reqQty in pairs(CurrentBundle) do  
            local found = 0  
            for _, tool in ipairs(allTools) do  
                if isTradeable(tool) then  
                    local displayName = getFullItemName(tool)  
                    if displayName == reqItemName and found < reqQty then  
                        table.insert(queue, tool)  
                        found = found + 1  
                    end  
                end  
            end  
            
            if found < reqQty then  
                Rayfield:Notify({Title = "Stock Deficit", Content = "Insufficient: " .. reqItemName, Duration = 5})  
                return   
            end  
            totalReqAssets = totalReqAssets + reqQty
        end  

        if totalReqAssets == 0 then return end

        GiftingActive = true  
        local sentCount = 0  
        
        for _, tool in ipairs(queue) do  
            if not GiftingActive then break end  
            
            local currentToolName = getFullItemName(tool)

            -- Update Package Status (Preparing)
            PackageStatusLabel:Set({  
                Title = "📦 Delivering to: " .. TargetPlayerName,  
                Content = string.format("Current Asset: %s\nOverall Progress: %d / %d\n%s\nStatus: Equipping...", currentToolName, sentCount, totalReqAssets, getProgressBar(sentCount, totalReqAssets))  
            })

            local character = localPlayer.Character  
            if character and character:FindFirstChild("Humanoid") then  
                character.Humanoid:EquipTool(tool)  
                task.wait(1.5)  
                
                -- Update Package Status (Sending)
                PackageStatusLabel:Set({  
                    Title = "📦 Delivering to: " .. TargetPlayerName,  
                    Content = string.format("Current Asset: %s\nOverall Progress: %d / %d\n%s\nStatus: Sending Packet...", currentToolName, sentCount, totalReqAssets, getProgressBar(sentCount, totalReqAssets))  
                })

                giftRequestRemote:FireServer(target.UserId)  
                task.wait(6) -- DELAY 5 DETIK  
                sentCount = sentCount + 1  
            end  
        end  
        
        GiftingActive = false  
        PackageStatusLabel:Set({
            Title = "✅ Package Delivered", 
            Content = string.format("Successfully delivered %d assets to %s.\n%s", sentCount, TargetPlayerName, getProgressBar(sentCount, totalReqAssets))
        })
        Rayfield:Notify({Title = "Package Delivered", Content = "Sent " .. sentCount .. " assets successfully.", Duration = 5})  
        updateInventoryDisplay()
    end,
})

-- ==========================================
-- TAB 4: ENVIRONMENT
-- ==========================================
local TabEnv = Window:CreateTab("Environment", 4483362458)
TabEnv:CreateSection("Cinematic / Evidence Mode")

TabEnv:CreateToggle({
    Name = "Enable Clean UI Mode",
    CurrentValue = false,
    Flag = "CleanUI",
    Callback = function(Value)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not Value)

        local pGui = localPlayer:WaitForChild("PlayerGui")  
        for _, gui in ipairs(pGui:GetChildren()) do  
            if gui:IsA("ScreenGui") and gui.Name ~= "Rayfield" then  
                if Value then  
                    gui:SetAttribute("WasEnabled", gui.Enabled)  
                    gui.Enabled = false  
                else  
                    if gui:GetAttribute("WasEnabled") ~= nil then  
                        gui.Enabled = gui:GetAttribute("WasEnabled")  
                    else  
                        gui.Enabled = true  
                    end  
                end  
            end  
        end  
         
        if Value then  
            Rayfield:Notify({Title = "Environment", Content = "Clean UI Active.", Duration = 3})  
        end
    end,
})

TabEnv:CreateSection("Data Synchronization")
TabEnv:CreateButton({
    Name = "Sync Dropdowns",
    Callback = function()
        PlayerDropdown:Refresh(getPlayerList())
        ItemDropdown:Refresh(getInventoryList())
        BundleItemDropdown:Refresh(getInventoryList())
        BundleReceiverDropdown:Refresh(getPlayerList())
    end,
})

-- // GLOBAL FUNCTIONS // --
function updateInventoryDisplay()
    local inventoryData = {}
    local totalCount = 0
    local allTools = getAllTools()

    for _, tool in pairs(allTools) do  
        if isTradeable(tool) then
            local displayName = getFullItemName(tool)  
            inventoryData[displayName] = (inventoryData[displayName] or 0) + 1  
            totalCount = totalCount + 1  
        end
    end  

    local displayString = "Total Authorized Assets: " .. totalCount .. "\n"  
    for itemName, amount in pairs(inventoryData) do  
        displayString = displayString .. string.format("\n• %s: %d Unit(s)", itemName, amount)  
    end  
    InventoryStatusLabel:Set({Title = "Real-time Inventory Assessment", Content = displayString})
end

-- Initialize & Hold-Detection Sync
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
