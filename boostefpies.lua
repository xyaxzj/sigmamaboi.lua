-- ==============================================================================
-- 🔬 BOOSTFPS DIAGNOSTIC v4 — ISOLASI KODE BAC-4514
-- Setiap fase diuji satu per satu dengan jeda 15 detik.
-- Laporkan: "Kick di FASE berapa"
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local lp = Players.LocalPlayer

local function notify(fase, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = fase, Text = text, Duration = 5
        })
    end)
    print(fase .. ": " .. text)
end

notify("START", "Diagnostic v4 (Mencari pemicu BAC-4514)...")

-- Helper: cek karakter sendiri
local function isMyChar(v)
    return lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character))
end

-- ═══════════════════════════════════════════════════════
-- FASE 1 (detik 10): CORE POTATO MAP (YANG SUDAH TERBUKTI AMAN)
-- ═══════════════════════════════════════════════════════
task.wait(10)
notify("FASE 1", "Core Potato Map (Material, Color, Shadow, Texture)...")
for _, v in ipairs(workspace:GetDescendants()) do
    if not isMyChar(v) then
        pcall(function()
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
                v.Color = Color3.new(1, 1, 1)
                if v:IsA("MeshPart") then v.TextureID = "" end
            elseif v:IsA("SpecialMesh") then
                v.TextureId = ""
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════
-- FASE 2 (detik 25): HIDE BILLBOARDGUI & SURFACETAGS
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 2", "Test Hide BillboardGui & SurfaceGui...")
for _, v in ipairs(workspace:GetDescendants()) do
    if not isMyChar(v) and (v:IsA("BillboardGui") or v:IsA("SurfaceGui")) then
        pcall(function() v.Enabled = false end)
    end
end

-- ═══════════════════════════════════════════════════════
-- FASE 3 (detik 40): SOUND / AUDIO MUTING
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 3", "Test Sound / Audio Mute...")
pcall(function()
    local ugs = UserSettings():GetService("UserGameSettings")
    if ugs then ugs.MasterVolume = 0 end
    game:GetService("SoundService").AmbientReverb = Enum.ReverbType.NoReverb
    for _, s in ipairs(workspace:GetDescendants()) do
        if s:IsA("Sound") then s.Volume = 0 end
    end
end)

-- ═══════════════════════════════════════════════════════
-- FASE 4 (detik 55): PLACED EGG RENDERS & CLIENT ASSETS HIDE
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 4", "Test Hide PlacedEggRenders & ClientAssets...")
pcall(function()
    local eggs = workspace:FindFirstChild("PlacedEggRenders")
    if eggs then
        for _, p in ipairs(eggs:GetDescendants()) do
            if p:IsA("BasePart") then p.Transparency = 1 end
        end
    end
    local assets = workspace:FindFirstChild("ClientRenderedAssets")
    if assets then
        for _, p in ipairs(assets:GetDescendants()) do
            if p:IsA("BasePart") then p.Transparency = 1 end
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- FASE 5 (detik 70): FREEZE ANIMASI PLAYER LAIN (AnimationTrack:Stop)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 5", "Test Freeze Animasi Player Lain...")
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= lp and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local anim = hum and hum:FindFirstChildOfClass("Animator")
        if anim then
            for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                pcall(function() track:Stop(0) end)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════
-- FASE 6 (detik 85): VIRTUALINPUTMANAGER (ANTI-AFK)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 6", "Test VirtualInputManager Click...")
pcall(function()
    local vim = game:GetService("VirtualInputManager")
    vim:SendMouseButtonEvent(10, 10, 0, true, game, 1)
    task.wait(0.05)
    vim:SendMouseButtonEvent(10, 10, 0, false, game, 1)
end)

notify("✅ SELESAI", "Semua fase selesai tanpa kick!")
