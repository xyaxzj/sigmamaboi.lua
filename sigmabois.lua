-- =============================================
-- AUTO UPGRADE + AUTO BUY (Default ON)
-- =============================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "Auto Upgrade & Buy",
   LoadingTitle = "Weight Shop",
   LoadingSubtitle = "Default ON",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local Tab = Window:CreateTab("Auto Features", 4483362748)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage.Shared.Packages.Network

-- ===================== AUTO SPEED UPGRADE =====================
_G.AutoSpeedUpgrade = true   -- Default ON

Tab:CreateToggle({
   Name = "⚡ Auto Speed Upgrade (Level 5)",
   CurrentValue = true,      -- Langsung nyala
   Callback = function(Value)
      _G.AutoSpeedUpgrade = Value
   end
})

task.spawn(function()
   while task.wait(1.5) do
      if _G.AutoSpeedUpgrade then
         pcall(function()
            Network.rev_SPEED_UPGRADE:FireServer(5)
         end)
      end
   end
end)

-- ===================== AUTO BUY WOODEN STICK =====================
_G.AutoBuyStick = true       -- Default ON

Tab:CreateToggle({
   Name = "🪵 Auto Buy Wooden Stick",
   CurrentValue = true,      -- Langsung nyala
   Callback = function(Value)
      _G.AutoBuyStick = Value
   end
})

task.spawn(function()
   while task.wait(2) do
      if _G.AutoBuyStick then
         pcall(function()
            Network.rev_Shop_Buy:FireServer("WeightShop", "Wooden Stick")
         end)
      end
   end
end)

print("✅ Auto Upgrade & Buy aktif! (Default ON)")
Rayfield:Notify({
   Title = "Script Loaded",
   Content = "Kedua fitur langsung aktif",
   Duration = 4
})
