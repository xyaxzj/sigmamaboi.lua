local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- // TARGET REMOTE GAME BARU //
local giftEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteGUI"):WaitForChild("UGiftEvent")

-- // State Variables // --
local GiftingActive = false
local StopThreshold = 0
local TargetPlayerName = ""
local TargetItemName = ""
local CurrentBundle = {}

-- // UI Helper //
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
-- Membaca semua item di tas dan di tangan
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

local function getPlayerList()
    local tbl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then table.insert(tbl, p.Name) end
    end
    return tbl
end

local function getInventoryList()
    local inventoryCounts = {}
    local allTools = getAllTools()

    for _, tool in ipairs(allTools) do  
        local name = tool.Name
        inventoryCounts[name] = (inventoryCounts[name] or 0) + 1  
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
    Name = "Universal Gifter System",
    LoadingTitle = "Hooking UGiftEvent...",
    LoadingSubtitle = "Clean Protocol Active",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
    Theme = "DarkBlue"
})

-- ==========================================
-- TAB 1: DIRECT TRANSFER
-- ==========================================
local TabTransfer = Window:CreateTab("Direct Transfer", 4483362458)

local LiveStatusLabel = TabTransfer:CreateParagraph({
    Title = "⚡ Operation Status",
    Content = "System Standby.\nWaiting for execution..."
})

TabTransfer:CreateSection("Target Definition")

local PlayerDropdown = TabTransfer:CreateDropdown({
    Name = "Pilih Penerima",
    Options = getPlayerList(),
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Option) TargetPlayerName = Option[1] end,
})

local ItemDropdown = TabTransfer:CreateDropdown({
    Name = "Select Item to Send",
    Options = getInventoryList(),
    CurrentOption = {"[ANY ASSET]"},
    MultipleOptions = false,
    Callback = function(Option) TargetItemName = getBaseName(Option[1]) end,
})

TabTransfer:CreateInput({
    Name = "Transfer Quantity",
    PlaceholderText = "Ketik jumlah yang dikirim...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) StopThreshold = tonumber(Text) or 0 end,
})

TabTransfer:CreateSection("Execution")

TabTransfer:CreateButton({
    Name = "INITIATE TRANSFER",
    Callback = function()
        if GiftingActive then return end
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target or StopThreshold <= 0 then
            return Rayfield:Notify({Title = "Error", Content = "Target atau Jumlah tidak valid.", Duration = 3})
        end

        GiftingActive = true  
        local itemsSent = 0  
        local allTools = getAllTools()  
        local itemsToProcess = {}  

        -- Filter item yang akan dikirim
        for _, tool in ipairs(allTools) do  
            if TargetItemName == "" or tool.Name == TargetItemName then  
                table.insert(itemsToProcess, tool)  
            end  
        end  

        local displayTargetName = TargetItemName == "" and "Randomized Items" or TargetItemName  

        for _, tool in ipairs(itemsToProcess) do  
            if itemsSent >= StopThreshold or not GiftingActive then break end  
            
            LiveStatusLabel:Set({  
                Title = "⚡ Transferring to: " .. TargetPlayerName,  
                Content = string.format("Item: %s\nProgress: %d / %d\n%s\nStatus: Equipping...", displayTargetName, itemsSent, StopThreshold, getProgressBar(itemsSent, StopThreshold))  
            })

            local character = localPlayer.Character  
            if character and character:FindFirstChild("Humanoid") then  
                character.Humanoid:EquipTool(tool)  
                task.wait(0.2) -- Jeda pegang item
                
                LiveStatusLabel:Set({  
                    Title = "⚡ Transferring to: " .. TargetPlayerName,  
                    Content = string.format("Item: %s\nProgress: %d / %d\n%s\nStatus: Firing UGiftEvent...", displayTargetName, itemsSent, StopThreshold, getProgressBar(itemsSent, StopThreshold))  
                })

                -- Eksekusi Remote (Coba dengan UserId dulu, ini paling standar)
                pcall(function()
                    giftEvent:FireServer(target.UserId) 
                end)
                
                task.wait(0.5) -- Jeda aman antar item
                itemsSent = itemsSent + 1  
            end  
        end  

        GiftingActive = false  
        LiveStatusLabel:Set({
            Title = "✅ Operation Concluded", 
            Content = string.format("Successfully sent %d unit(s) to %s.\n%s", itemsSent, TargetPlayerName, getProgressBar(itemsSent, StopThreshold))
        })  
        ItemDropdown:Refresh(getInventoryList())
    end,
})

TabTransfer:CreateButton({
    Name = "STOP / TERMINATE TRANSFER",
    Callback = function()
        GiftingActive = false
        Rayfield:Notify({Title = "Alert", Content = "Pengiriman dihentikan.", Duration = 3})
    end,
})

-- ==========================================
-- TAB 2: DATA SYNC
-- ==========================================
local TabSync = Window:CreateTab("Refresh Data", 4483362458)
TabSync:CreateButton({
    Name = "🔄 Sync Player & Inventory",
    Callback = function()
        PlayerDropdown:Refresh(getPlayerList())
        ItemDropdown:Refresh(getInventoryList())
        Rayfield:Notify({Title = "Sync Complete", Content = "Data terbaru berhasil ditarik.", Duration = 2})
    end,
})
