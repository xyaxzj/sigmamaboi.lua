local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- // TARGET REMOTE //
local giftEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteGUI"):WaitForChild("UGiftEvent")

-- // State Variables // --
local GiftingActive = false
local StopThreshold = 0
local TargetPlayerName = ""
local TargetItemName = ""

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

-- // NEW CORE FUNCTIONS: CUSTOM BACKPACK READER // --
-- Membaca tombol UI di dalam Custom Backpack game
local function getAllItemButtons()
    local buttons = {}
    local pGui = localPlayer:FindFirstChild("PlayerGui")
    if pGui and pGui:FindFirstChild("BackpackGui") then
        local bp = pGui.BackpackGui:FindFirstChild("Backpack")
        if bp then
            -- 1. Cek di dalam Inventory Grid
            local grid = bp:FindFirstChild("Inventory") and bp.Inventory:FindFirstChild("ScrollingFrame") and bp.Inventory.ScrollingFrame:FindFirstChild("UIGridFrame")
            if grid then
                for _, btn in ipairs(grid:GetChildren()) do
                    if (btn:IsA("GuiButton") or btn:IsA("TextButton")) and btn:FindFirstChild("ToolName") then
                        table.insert(buttons, btn)
                    end
                end
            end
            -- 2. Cek di dalam Hotbar bawah
            local hotbar = bp:FindFirstChild("Hotbar")
            if hotbar then
                for _, btn in ipairs(hotbar:GetDescendants()) do
                    if (btn:IsA("GuiButton") or btn:IsA("TextButton")) and btn:FindFirstChild("ToolName") then
                        table.insert(buttons, btn)
                    end
                end
            end
        end
    end
    return buttons
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
    local allBtns = getAllItemButtons()

    for _, btn in ipairs(allBtns) do  
        local name = btn.ToolName.Text
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

-- // Helper Klik UI //
local function clickButton(btn)
    if firesignal then
        firesignal(btn.MouseButton1Click)
    else
        -- Fallback kalau executor nggak support firesignal
        for _, connection in pairs(getconnections(btn.MouseButton1Click)) do
            connection:Function()
        end
    end
end

-- // UI Initialization // --
local Window = Rayfield:CreateWindow({
    Name = "Mocta Gifter V3",
    LoadingTitle = "Bypassing Custom Backpack...",
    LoadingSubtitle = "UI Clicker & Payload Ready",
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
    Name = "🚀 INITIATE TRANSFER (SUPER FAST)",
    Callback = function()
        if GiftingActive then return end
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target or StopThreshold <= 0 then
            return Rayfield:Notify({Title = "Error", Content = "Target atau Jumlah tidak valid.", Duration = 3})
        end

        GiftingActive = true  
        local itemsSent = 0  
        local allBtns = getAllItemButtons()  
        local displayTargetName = TargetItemName == "" and "Randomized Items" or TargetItemName  
        local sentTracker = {} -- Mencegah item dikirim 2 kali

        for _, btn in ipairs(allBtns) do  
            if itemsSent >= StopThreshold or not GiftingActive then break end  
            
            local toolName = btn.ToolName.Text
            if TargetItemName == "" or toolName == TargetItemName then  
                
                LiveStatusLabel:Set({  
                    Title = "⚡ Transferring to: " .. TargetPlayerName,  
                    Content = string.format("Item: %s\nProgress: %d / %d\n%s\nStatus: Clicking Custom UI...", displayTargetName, itemsSent, StopThreshold, getProgressBar(itemsSent, StopThreshold))  
                })

                -- 1. KLIK TOMBOL UI DI LAYAR (SEPERTI SCRIPT REFERENSI)
                clickButton(btn)
                task.wait(0.05) -- Jeda super singkat agar tool muncul di tangan
                
                -- 2. AMBIL TOOL DARI TANGAN
                local equippedTool = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Tool")
                
                if equippedTool then
                    local uniqueID = equippedTool:GetAttribute("uniqueID") or equippedTool:GetAttribute("UniqueID") or equippedTool:GetAttribute("UUID")
                    
                    if uniqueID and not sentTracker[uniqueID] then
                        sentTracker[uniqueID] = true -- Tandai sudah dikirim
                        
                        LiveStatusLabel:Set({  
                            Title = "⚡ Transferring to: " .. TargetPlayerName,  
                            Content = string.format("Item: %s\nProgress: %d / %d\n%s\nStatus: Firing Payload...", displayTargetName, itemsSent, StopThreshold, getProgressBar(itemsSent, StopThreshold))  
                        })

                        -- 3. RAKIT PAYLOAD & KIRIM
                        local itemLvl = equippedTool:GetAttribute("Level") or equippedTool:GetAttribute("level") or equippedTool:GetAttribute("Lvl") or 1
                        local payload = {
                            image = "rbxassetid://82142218961817",
                            uniqueID = tostring(uniqueID),
                            playerName = target.Name,
                            level = tonumber(itemLvl),
                            brainrotName = toolName,
                            uid = target.UserId
                        }

                        pcall(function() giftEvent:FireServer(payload) end)
                        
                        itemsSent = itemsSent + 1  
                        task.wait(0.05) -- KECEPATAN DEWA
                    end
                end
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
    Name = "🛑 STOP / TERMINATE TRANSFER",
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
