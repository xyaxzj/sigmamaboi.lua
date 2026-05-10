local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- // TARGET REMOTE //
local giftEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteGUI"):WaitForChild("UGiftEvent")

-- // Core Functions //
local function getPlayerList()
    local tbl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then table.insert(tbl, p.Name) end
    end
    return tbl
end

-- // UI Initialization //
local Window = Rayfield:CreateWindow({
    Name = "Mocta Dupe Tester",
    LoadingTitle = "Analyzing Server Logic...",
    LoadingSubtitle = "Race Condition Protocol",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
    Theme = "DarkBlue"
})

local TabDupe = Window:CreateTab("Dupe Exploiter", 4483362458)

local TargetPlayerName = ""
local SpamCount = 20 -- Default tembakan

TabDupe:CreateSection("1. Target Setup")

TabDupe:CreateDropdown({
    Name = "Pilih Akun Tumbal (Penerima)",
    Options = getPlayerList(),
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Option) TargetPlayerName = Option[1] end,
})

TabDupe:CreateSlider({
    Name = "Spam Multiplier (Kecepatan Serangan)",
    Range = {5, 100},
    Increment = 1,
    Suffix = " Requests",
    CurrentValue = 20,
    Flag = "SpamSlider",
    Callback = function(Value) SpamCount = Value end,
})

TabDupe:CreateSection("2. Execution")
TabDupe:CreateParagraph({
    Title = "⚠️ CARA PAKAI:",
    Content = "1. Pegang (Equip) 1 item sampah di tangan karaktermu SEKARANG.\n2. Pilih target pemain.\n3. Tekan tombol merah di bawah."
})

TabDupe:CreateButton({
    Name = "☢️ EXECUTE DUPE GLITCH",
    Callback = function()
        local target = Players:FindFirstChild(TargetPlayerName)
        if not target then
            return Rayfield:Notify({Title = "Error", Content = "Pilih target penerima dulu!", Duration = 3})
        end

        local equippedTool = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Tool")
        if not equippedTool then
            return Rayfield:Notify({Title = "Error", Content = "Kamu tidak sedang memegang item apapun di tangan!", Duration = 3})
        end

        local uniqueID = equippedTool:GetAttribute("uniqueID") or equippedTool:GetAttribute("UniqueID") or equippedTool:GetAttribute("UUID")
        if not uniqueID then
            return Rayfield:Notify({Title = "Error", Content = "Item ini tidak punya Unique ID. Coba item lain.", Duration = 3})
        end

        local itemLvl = equippedTool:GetAttribute("Level") or equippedTool:GetAttribute("level") or equippedTool:GetAttribute("Lvl") or 1
        
        -- Rakit Payload
        local payload = {
            image = "rbxassetid://82142218961817",
            uniqueID = tostring(uniqueID),
            playerName = target.Name,
            level = tonumber(itemLvl),
            brainrotName = equippedTool.Name,
            uid = target.UserId
        }

        Rayfield:Notify({Title = "ATTACK LAUNCHED", Content = "Menembakkan " .. SpamCount .. " request secara bersamaan!", Duration = 2})

        -- EKSPLOITASI KONDISI BALAPAN (RACE CONDITION)
        -- task.spawn membuat semua tembakan dieksekusi di millidetik yang sama
        for i = 1, SpamCount do
            task.spawn(function()
                pcall(function()
                    giftEvent:FireServer(payload)
                end)
            end)
        end
        
        Rayfield:Notify({Title = "Selesai", Content = "Cek tas akun tumbal. Apakah itemnya berlipat ganda?", Duration = 5})
    end,
})
