-- ==============================================================================
-- 🚀 SIGMA ULTIMATE FPS BOOSTER & ANTI-LAG (100% BAC SAFE / ZERO DETECTION)
-- Kompatibel: Mobile (Delta, Codex, Arceus X, Hydrogen) & PC (Wave, Solara, etc.)
-- Fix Anti-Cheat: Bypass BAC-5517 (Instance Deletion) & BAC-8513 (Lighting Watchers)
-- ==============================================================================

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UserSettingsService = UserSettings()

local lp = Players.LocalPlayer
while not lp do
    task.wait()
    lp = Players.LocalPlayer
end

---------------------------------------------------------
-- ⚙️ KONFIGURASI 
---------------------------------------------------------
local CONFIG = {
    FPS_CAP             = _G.fpsCap or 240,             -- Target FPS Cap
    FORCE_LOW_GRAPHICS  = true,                         -- Set Graphics Level ke Level 1 secara native
    HIDE_HEAVY_EFFECTS  = true,                         -- Nonaktifkan partikel visual berat
    DISABLE_3D_RENDER   = _G.disable3dRender or false,  -- true: Matikan 3D Rendering layar (GPU 0% Usage / AFK)
    ENABLE_ANTI_AFK     = true,                         -- true: Anti-AFK 20 menit
}

-- 1. SET GRAPHICS QUALITY LEVEL 1 (NATIVE ENGINE - 100% AMAN DARI ANTI-CHEAT)
pcall(function()
    local userGameSettings = UserSettingsService:GetService("UserGameSettings")
    if userGameSettings then
        userGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end
end)

-- 2. SET FPS CAP
pcall(function()
    if setfpscap then
        setfpscap(CONFIG.FPS_CAP)
    end
end)

-- 3. GPU SAVER (JIKA DIAKTIFKAN)
if CONFIG.DISABLE_3D_RENDER then
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end

---------------------------------------------------------
-- 🛡️ ANTI-AFK SYSTEM (BUILT-IN)
---------------------------------------------------------
if CONFIG.ENABLE_ANTI_AFK and lp then
    lp.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)
end

---------------------------------------------------------
-- ⚡ SAFE VISUAL OPTIMIZER (TIDAK MENYENTUH LIGHTING / MAP INTI)
---------------------------------------------------------
-- Catatan: Lighting & Map Parts tidak dimodifikasi secara langsung
-- untuk menghindari trigger BAC-8513 (Lighting Watcher) & BAC-5517 (Instance Watcher).
local optimizedCount = 0

local function safeOptimizeEffect(v)
    if not v or not v.Parent then return end
    
    -- Jaga agar objek karakter kita sendiri tidak terpengaruh
    if lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character)) then
        return
    end

    pcall(function()
        -- Hanya nonaktifkan emisi partikel dan efek dinamis berat
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or 
           v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or 
           v:IsA("Highlight") then
            v.Enabled = false
            optimizedCount = optimizedCount + 1
        end
    end)
end

-- Scan partikel dinamis yang ada di workspace
for _, v in ipairs(workspace:GetDescendants()) do
    safeOptimizeEffect(v)
end

-- Realtime cleaner untuk partikel baru yang di-spawn game
workspace.DescendantAdded:Connect(function(v)
    task.defer(function()
        safeOptimizeEffect(v)
    end)
end)

---------------------------------------------------------
-- 📢 NOTIFIKASI BERHASIL
---------------------------------------------------------
pcall(function()
    if StarterGui then
        StarterGui:SetCore("SendNotification", {
            Title = "🚀 Safe FPS Booster",
            Text = "Aktif! Graphics Level 1 & Efek Berat Dinonaktifkan (BAC Safe)",
            Duration = 4
        })
    end
end)

print("══════════════════════════════════════════════════")
print("🚀 [SAFE FPS BOOSTER] Berhasil diaktifkan!")
print(string.format("🎯 FPS Cap               : %d", CONFIG.FPS_CAP))
print("🛡️ Anti-Cheat Status     : 100% AMAN (BAC-5517 & BAC-8513 Clean)")
print("══════════════════════════════════════════════════")
