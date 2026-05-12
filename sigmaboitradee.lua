local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer

local networkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")
local giftRequestRemote = networkFolder:WaitForChild("rev_GiftRequest")

local GiftingActive = false
local SafetyLock = true
local DiscordWebhookURL = ""
local StopThreshold = 0
local TargetPlayerName = ""
local TargetItemName = ""
local CurrentBundle = {}
local InventoryConnections = {}
local SearchQueryTransfer = ""
local SearchQueryBundle = ""

local function getProgressBar(current, total, length)
    length = length or 20
    if total <= 0 then return "[" .. string.rep("░", length) .. "] 0%" end
    local filled = math.floor((current / total) * length)
    if filled > length then filled = length end
    local empty = length - filled
    local percentage = math.floor((current / total) * 100)
    return "[" .. string.rep("█", filled) .. string.rep("░", empty) .. "] " .. percentage .. "%"
end

local function getAllTools()
    local tools = {}
    local bp = localPlayer:FindFirstChild("Backpack")
    if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
    local char = localPlayer.Character
    if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
    return tools
end

local function isTradeable(tool)
    return tool and tool:IsA("Tool") and (tool:GetAttribute("guid") or tool:GetAttribute("GUID"))
end

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

local function getPlayerList()
    local tbl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then table.insert(tbl, p.Name) end
    end
    return tbl
end

local function shuffleTable(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

local function getAvailableStock(itemName)
    local allTools = getAllTools()
    local count = 0
    for _, tool in ipairs(allTools) do
        if isTradeable(tool) then
            if itemName == "" or itemName == "[ANY ASSET]" then
                count = count + 1
            elseif getFullItemName(tool) == itemName then
                count = count + 1
            end
        end
    end
    return count
end

local function getInventoryList(searchFilter)
    local inventoryCounts = {}
    local allTools = getAllTools()

    for _, tool in ipairs(allTools) do  
        if isTradeable(tool) then
            local displayName = getFullItemName(tool)  
            if not searchFilter or searchFilter == "" or string.find(displayName:lower(), searchFilter:lower()) then
                inventoryCounts[displayName] = (inventoryCounts[displayName] or 0) + 1  
            end
        end
    end  

    local itemsList = {"[ANY ASSET]"}  
    for name, count in pairs(inventoryCounts) do table.insert(itemsList, name .. " | Qty: " .. count) end  
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

local function savePreset(name)
    pcall(function()
        if not isfolder("MoctaPresets") then makefolder("MoctaPresets") end
        local data = HttpService:JSONEncode(CurrentBundle)
        writefile("MoctaPresets/"..name..".json", data)
    end)
end

local function loadPreset(name)
    local success = false
    pcall(function()
        local path = "MoctaPresets/"..name..".json"
        if isfile(path) then
            local data = readfile(path)
            CurrentBundle = HttpService:JSONDecode(data)
            success = true
        end
    end)
    return success
end

local function getPresetList()
    local names = {}
    pcall(function()
        if isfolder("MoctaPresets") then
            local files = listfiles("MoctaPresets")
            for _, f in ipairs(files) do table.insert(names, f:gsub("MoctaPresets\\", ""):gsub("MoctaPresets/", ""):gsub(".json", "")) end
        end
    end)
    return names
end

local function sendDiscordWebhook(target, totalQty, itemListStr)
    if DiscordWebhookURL == "" then return end
    local data = {
        ["embeds"] = {{
            ["title"] = "✅ Transaction Completed",
            ["description"] = "**Sender:** " .. localPlayer.Name .. "\n**Receiver:** " .. target .. "\n**Total Assets:** " .. totalQty,
            ["color"] = tonumber(0x2B2D31),
            ["fields"] = { {["name"] = "Items Transferred", ["value"] = "```\n" .. itemListStr .. "\n```", ["inline"] = false} },
            ["footer"] = {["text"] = "Mocta System V2.4 | " .. os.date("%Y-%m-%d %H:%M:%S")}
        }}
    }
    pcall(function()
        local headers = {["Content-Type"] = "application/json"}
        local request = http_request or request or HttpPost
        if request then request({Url = DiscordWebhookURL, Method = "POST", Headers = headers, Body = HttpService:JSONEncode(data)}) end
    end)
end

local function showReceiptOverlay(targetName, totalQty, itemsDict)
    local itemListStr = ""
    for name, qty in pairs(itemsDict) do itemListStr = itemListStr .. "- " .. name .. " (x" .. qty .. ")\n" end

    local sg = Instance.new("ScreenGui")
    sg.Name = "MoctaEvidenceReceipt"
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
    sg.Parent = CoreGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.Parent = sg

    local receipt = Instance.new("Frame")
    receipt.Size = UDim2.new(0, 400, 0, 500)
    receipt.Position = UDim2.new(0.5, -200, 0.5, -250)
    receipt.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    receipt.BorderSizePixel = 0
    receipt.ClipsDescendants = true
    receipt.Parent = bg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = receipt

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    header.Text = "TRANSACTION RECEIPT"
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 20
    header.Parent = receipt

    local details = Instance.new("TextLabel")
    details.Size = UDim2.new(1, -40, 0, 100)
    details.Position = UDim2.new(0, 20, 0, 70)
    details.BackgroundTransparency = 1
    details.TextXAlignment = Enum.TextXAlignment.Left
    details.TextYAlignment = Enum.TextYAlignment.Top
    details.Text = string.format("Status: SUCCESS\nDate: %s\nSender: %s\nReceiver: %s\nTotal Assets: %d", os.date("%Y-%m-%d %H:%M:%S"), localPlayer.Name, targetName, totalQty)
    details.TextColor3 = Color3.fromRGB(200, 200, 200)
    details.Font = Enum.Font.Gotham
    details.TextSize = 14
    details.Parent = receipt

    local listHeader = Instance.new("TextLabel")
    listHeader.Size = UDim2.new(1, -40, 0, 20)
    listHeader.Position = UDim2.new(0, 20, 0, 180)
    listHeader.BackgroundTransparency = 1
    listHeader.TextXAlignment = Enum.TextXAlignment.Left
    listHeader.Text = "ASSETS TRANSFERRED:"
    listHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    listHeader.Font = Enum.Font.GothamBold
    listHeader.TextSize = 14
    listHeader.Parent = receipt

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -40, 1, -280)
    scroll.Position = UDim2.new(0, 20, 0, 210)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.Parent = receipt

    local list = Instance.new("TextLabel")
    list.Size = UDim2.new(1, -10, 1, 0)
    list.BackgroundTransparency = 1
    list.TextXAlignment = Enum.TextXAlignment.Left
    list.TextYAlignment = Enum.TextYAlignment.Top
    list.Text = itemListStr
    list.TextColor3 = Color3.fromRGB(150, 255, 150)
    list.Font = Enum.Font.Code
    list.TextSize = 13
    list.Parent = scroll
    
    list.Size = UDim2.new(1, -10, 0, list.TextBounds.Y + 20)
    scroll.CanvasSize = UDim2.new(0, 0, 0, list.Size.Y.Offset)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, -40, 0, 40)
    closeBtn.Position = UDim2.new(0, 20, 1, -50)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "CLOSE & DISMISS"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = receipt
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
    task.spawn(function() sendDiscordWebhook(targetName, totalQty, itemListStr) end)
end

local Window = Rayfield:CreateWindow({
    Name = "Mocta System V2.4",
    LoadingTitle = "Authenticating Protocol...",
    ConfigurationSaving = { Enabled = false },
    Theme = "DarkBlue"
})

local TabDashboard = Window:CreateTab("Dashboard", 4483362458)
TabDashboard:CreateSection("Security & Tracking")
TabDashboard:CreateToggle({
    Name = "Safety Confirmation Pop-up",
    CurrentValue = true,
    Callback = function(Value) SafetyLock = Value end,
})
local InventoryStatusLabel = TabDashboard:CreateParagraph({
    Title = "Real-time Inventory Assessment",
    Content = "Synchronizing data..."
})
TabDashboard:CreateButton({
    Name = "Refresh Database",
    Callback = function() updateInventoryDisplay(); Rayfield:Notify({Title = "System", Content = "Database synchronized.", Duration = 2}) end,
})
TabDashboard:CreateButton({
    Name = "TERMINATE ALL OPERATIONS",
    Callback = function() GiftingActive = false; Rayfield:Notify({Title = "Alert", Content = "All active transfers halted.", Duration = 3}) end,
})

local TabTransfer = Window:CreateTab("Direct Transfer", 4483362458)
local PlayerDropdown = TabTransfer:CreateDropdown({
    Name = "Pilih Penerima",
    Options = getPlayerList(),
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Option) TargetPlayerName = Option[1] end,
})
local ItemDropdown 
TabTransfer:CreateInput({
    Name = "Cari Item...",
    PlaceholderText = "Ketik nama/mutasi...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) SearchQueryTransfer = Text; ItemDropdown:Refresh(getInventoryList(SearchQueryTransfer), true) end,
})
ItemDropdown = TabTransfer:CreateDropdown({
    Name = "Select Asset",
    Options = getInventoryList(""),
    CurrentOption = {"[ANY ASSET]"},
    MultipleOptions = false,
    Callback = function(Option) TargetItemName = getBaseName(Option[1]) end,
})
TabTransfer:CreateInput({
    Name = "Transfer Quantity",
    PlaceholderText = "Qty",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) StopThreshold = tonumber(Text) or 0 end,
})
local LiveStatusLabel = TabTransfer:CreateParagraph({Title = "⚡ Operation Status", Content = "System Standby."})

local function executeDirectTransfer()
    GiftingActive = true  
    local itemsSent = 0  
    local allTools = getAllTools()  
    local itemsToProcess = {}  
    local target = Players:FindFirstChild(TargetPlayerName)
    local sentHistory = {} 

    for _, tool in ipairs(allTools) do  
        if isTradeable(tool) then  
            local displayName = getFullItemName(tool)  
            if TargetItemName == "" or displayName == TargetItemName then table.insert(itemsToProcess, tool) end  
        end  
    end  

    if TargetItemName == "" then shuffleTable(itemsToProcess) end  
    local displayTargetName = TargetItemName == "" and "Randomized Assets" or TargetItemName  

    for _, tool in ipairs(itemsToProcess) do  
        if itemsSent >= StopThreshold or not GiftingActive then break end  
        
        LiveStatusLabel:Set({Title = "⚡ Transferring...", Content = string.format("Asset: %s\nProgress: %d / %d", displayTargetName, itemsSent, StopThreshold)})
        local character = localPlayer.Character  
        if character and character:FindFirstChild("Humanoid") then  
            character.Humanoid:EquipTool(tool)  
            task.wait(1.5)  
            giftRequestRemote:FireServer(target.UserId)  
            task.wait(4.5)  
            
            local tName = getFullItemName(tool)
            sentHistory[tName] = (sentHistory[tName] or 0) + 1
            itemsSent = itemsSent + 1  
        end  
    end  

    GiftingActive = false  
    LiveStatusLabel:Set({Title = "✅ Operation Concluded", Content = "Transfer finished."})  
    updateInventoryDisplay()
    if itemsSent > 0 then showReceiptOverlay(TargetPlayerName, itemsSent, sentHistory) end
end

TabTransfer:CreateButton({
    Name = "INITIATE TRANSFER",
    Callback = function()
        if GiftingActive then return end
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target or StopThreshold <= 0 then return end
        if StopThreshold > getAvailableStock(TargetItemName) then return end

        if SafetyLock then
            Window:CreateDialog({
                Title = "⚠️ SECURITY CONFIRMATION",
                Content = "Kirim " .. StopThreshold .. " item ke " .. TargetPlayerName .. "?",
                Buttons = {{ Name = "Proceed (Gas)", Callback = executeDirectTransfer }, { Name = "Cancel", Callback = function() end }}
            })
        else executeDirectTransfer() end
    end,
})

local TabBundle = Window:CreateTab("Package & Presets", 4483362458)
local BundleContentLabel = TabBundle:CreateParagraph({Title = "Current Package", Content = "Package is empty."})

local function updateBundleDisplay()
    local text, totalItems = "", 0
    for name, qty in pairs(CurrentBundle) do text = text .. string.format("- %s: %d Unit(s)\n", name, qty); totalItems = totalItems + qty end
    if text == "" then text = "Package is empty." else text = text .. "\nTotal: " .. totalItems end
    BundleContentLabel:Set({Title = "Current Package", Content = text})
end

TabBundle:CreateSection("1. Load / Save Preset")
local PresetNameInput = ""
TabBundle:CreateInput({Name = "Nama Preset Baru", Callback = function(Text) PresetNameInput = Text end})
TabBundle:CreateButton({Name = "💾 Save Preset", Callback = function() if PresetNameInput ~= "" then savePreset(PresetNameInput) end end})
local PresetDropdown = TabBundle:CreateDropdown({
    Name = "Load Preset", Options = getPresetList(), CurrentOption = {""}, MultipleOptions = false,
    Callback = function(Option) if Option[1] ~= "" and loadPreset(Option[1]) then updateBundleDisplay() end end,
})
TabBundle:CreateButton({Name = "🔄 Refresh List", Callback = function() PresetDropdown:Refresh(getPresetList(), true) end})

TabBundle:CreateSection("2. Manual Editor")
local BundleItemName, BundleItemQty = "", 0
local BundleItemDropdown
TabBundle:CreateInput({Name = "Cari Item...", Callback = function(Text) SearchQueryBundle = Text; BundleItemDropdown:Refresh(getInventoryList(SearchQueryBundle), true) end})
BundleItemDropdown = TabBundle:CreateDropdown({Name = "Select Asset", Options = getInventoryList(""), CurrentOption = {""}, MultipleOptions = false, Callback = function(Option) BundleItemName = getBaseName(Option[1]) end})
TabBundle:CreateInput({Name = "Qty", Callback = function(Text) BundleItemQty = tonumber(Text) or 0 end})

TabBundle:CreateButton({
    Name = "Add to Package",
    Callback = function()
        if BundleItemName ~= "" and BundleItemQty > 0 then
            local current = CurrentBundle[BundleItemName] or 0
            if current + BundleItemQty <= getAvailableStock(BundleItemName) then
                CurrentBundle[BundleItemName] = current + BundleItemQty
                updateBundleDisplay()
            end
        end
    end,
})
TabBundle:CreateButton({
    Name = "Add ALL Available Stock",
    Callback = function()
        if BundleItemName ~= "" then
            local maxAvailable = getAvailableStock(BundleItemName)
            if maxAvailable > 0 then CurrentBundle[BundleItemName] = maxAvailable; updateBundleDisplay() end
        end
    end,
})
TabBundle:CreateButton({Name = "Clear Package", Callback = function() CurrentBundle = {}; updateBundleDisplay() end})

TabBundle:CreateSection("3. Package Execution")
local BundleReceiverDropdown = TabBundle:CreateDropdown({
    Name = "Select Receiver", Options = getPlayerList(), CurrentOption = {""}, MultipleOptions = false,
    Callback = function(Option) TargetPlayerName = Option[1] end,
})
local PackageStatusLabel = TabBundle:CreateParagraph({Title = "📦 Status", Content = "Ready."})

local function executePackageTransfer()
    GiftingActive = true  
    local target = Players:FindFirstChild(TargetPlayerName)
    local allTools = getAllTools()
    local queue, totalReqAssets, sentHistory = {}, 0, {}
    
    for reqItemName, reqQty in pairs(CurrentBundle) do  
        local found = 0  
        for _, tool in ipairs(allTools) do  
            if isTradeable(tool) then  
                if getFullItemName(tool) == reqItemName and found < reqQty then table.insert(queue, tool); found = found + 1 end  
            end  
        end  
        if found < reqQty then GiftingActive = false; return end  
        totalReqAssets = totalReqAssets + reqQty
    end  

    if totalReqAssets == 0 then GiftingActive = false return end

    local sentCount = 0  
    for _, tool in ipairs(queue) do  
        if not GiftingActive then break end  
        local currentToolName = getFullItemName(tool)
        PackageStatusLabel:Set({Title = "📦 Delivering...", Content = string.format("Progress: %d / %d", sentCount, totalReqAssets)})

        local character = localPlayer.Character  
        if character and character:FindFirstChild("Humanoid") then  
            character.Humanoid:EquipTool(tool)  
            task.wait(1.5)  
            giftRequestRemote:FireServer(target.UserId)  
            task.wait(4.5)  
            sentHistory[currentToolName] = (sentHistory[currentToolName] or 0) + 1
            sentCount = sentCount + 1  
        end  
    end  
    
    GiftingActive = false  
    PackageStatusLabel:Set({Title = "✅ Delivered", Content = "Transfer finished."})
    updateInventoryDisplay()
    if sentCount > 0 then showReceiptOverlay(TargetPlayerName, sentCount, sentHistory) end
end

TabBundle:CreateBut
