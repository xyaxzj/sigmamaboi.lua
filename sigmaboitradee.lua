-- ==========================================================
-- MOCTA TRADE: GHOST EXPRESS EDITION (MANUAL CONFIRM)
-- Target: sixqx1
-- ==========================================================

local targetName = "sometincRR1" -- Nama akun penerima

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local networkFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10):WaitForChild("Packages", 10):WaitForChild("Network", 10)
local f_trade_r = networkFolder:WaitForChild("ref_trade_r", 5) 
local r_trade_i = networkFolder:WaitForChild("rev_trade_i", 5) 

-- Fungsi Notifikasi Bawaan Roblox (Tanpa UI Rayfield biar ringan)
local function notify(title, text)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title, 
            Text = text, 
            Duration = 5
        })
    end)
end

local function executeExpressTrade()
    -- 1. Cari Target di Server
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if string.lower(p.Name) == string.lower(targetName) or string.lower(p.DisplayName) == string.lower(targetName) then
            target = p
            break
        end
    end

    if not target then
        notify("❌ Gagal", "Target '" .. targetName .. "' tidak ada di server!")
        return
    end

    -- 2. Kirim Invite
    notify("⏳ Memproses", "Mengirim Trade Request ke " .. target.Name .. "...")
    task.spawn(function() 
        pcall(function() f_trade_r:InvokeServer(target.UserId) end) 
    end)

    -- 3. Tunggu UI Trade Terbuka (Max 15 Detik)
    local tradeFrame = nil
    local timer = 0
    while timer < 15 do
        tradeFrame = localPlayer.PlayerGui:FindFirstChild("TradingFrame", true)
        if tradeFrame and tradeFrame.Visible then break end
        task.wait(1) 
        timer = timer + 1
    end

    if not (tradeFrame and tradeFrame.Visible) then
        notify("❌ Timeout", target.Name .. " tidak menerima invite dalam 15 detik.")
        return
    end

    -- 4. Kumpulkan Semua Item
    notify("📦 UI Terbuka", "Memasukkan semua item dari tas...")
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

    -- 5. Masukkan ke Trade (Maksimal 10 item per trade)
    local count = 0
    for _, tool in ipairs(tools) do
        local guid = tool:GetAttribute("guid") or tool:GetAttribute("GUID") or tool:GetAttribute("uid")
        if guid then
            r_trade_i:FireServer("AddItem", tostring(guid))
            count = count + 1
            task.wait(0.2) -- Jeda anti-lag server
            if count >= 10 then break end -- Batas slot trade Roblox
        end
    end

    -- 6. Stop dan Serahkan ke Player
    if count == 0 then
        notify("⚠️ Kosong", "Tidak ada item yang bisa di-trade di tasmu!")
    else
        notify("✅ Selesai!", count .. " item berhasil masuk. Silakan ACCEPT MANUAL!")
    end
end

-- Eksekusi langsung saat script dijalankan
executeExpressTrade()
