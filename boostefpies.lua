-- ==============================================================================
-- 🔬 BOOSTFPS DIAGNOSTIC v3 — TEST PROPERTI BASEPART SAJA (TANPA PARTIKEL)
-- ==============================================================================
-- Kita sudah tahu:
-- ❌ VirtualUser   -> Trigger BAC-7518
-- ❌ Partikel      -> Trigger BAC-10512
-- ❌ Lighting      -> Trigger BAC-8513
-- ❌ :Destroy()    -> Trigger BAC-5517
-- ❌ getconnections -> Trigger BAC-5513
--
-- Sekarang kita test properti BasePart (Material, Shadow, Color, Texture, Hide Player, Hide Plot)
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

notify("START", "Diagnostic v3: Test BasePart Properties...")

-- Helper: cek apakah part milik karakter kita sendiri
local function isMyChar(v)
    return lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character))
end

-- ═══════════════════════════════════════════════════════
-- FASE 1 (detik 15): CASTSHADOW = FALSE
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 1", "CastShadow = false pada BasePart...")
for _, v in ipairs(workspace:GetDescendants()) do
    if not isMyChar(v) and v:IsA("BasePart") then
        pcall(function() v.CastShadow = false end)
    end
end

-- ═══════════════════════════════════════════════════════
-- FASE 2 (detik 30): MATERIAL = SMOOTHPLASTIC
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 2", "Material = SmoothPlastic...")
for _, v in ipairs(workspace:GetDescendants()) do
    if not isMyChar(v) and v:IsA("BasePart") then
        pcall(function() 
            v.Material = Enum.Material.SmoothPlastic 
            v.Reflectance = 0
        end)
    end
end

-- ═══════════════════════════════════════════════════════
-- FASE 3 (detik 45): COLOR = PUTIH (WHITE MAP)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 3", "Color = Putih (White Map)...")
for _, v in ipairs(workspace:GetDescendants()) do
    if not isMyChar(v) and v:IsA("BasePart") then
        pcall(function() v.Color = Color3.new(1, 1, 1) end)
    end
end

-- ═══════════════════════════════════════════════════════
-- FASE 4 (detik 60): HAPUS TEKSTUR MESHPART / DECAL
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 4", "Hapus tekstur MeshPart/Decal...")
for _, v in ipairs(workspace:GetDescendants()) do
    if not isMyChar(v) then
        pcall(function()
            if v:IsA("MeshPart") then
                v.TextureID = ""
            elseif v:IsA("SpecialMesh") then
                v.TextureId = ""
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════
-- FASE 5 (detik 75): TERRAIN WATER
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 5", "Terrain water optimization...")
pcall(function()
    local t = workspace:FindFirstChildOfClass("Terrain")
    if t then
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 0
    end
end)

-- ═══════════════════════════════════════════════════════
-- FASE 6 (detik 90): HIDE PLAYER LAIN (TRANSPARENCY)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 6", "Hide player lain (transparency)...")
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= lp and p.Character then
        for _, part in ipairs(p.Character:GetDescendants()) do
            pcall(function()
                if part:IsA("BasePart") then
                    part.Transparency = 1
                    part.LocalTransparencyModifier = 1
                end
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════
-- FASE 7 (detik 105): HIDE PLOT LAIN (TRANSPARENCY)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 7", "Hide plot lain (transparency)...")
pcall(function()
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            if plot:IsA("Model") then
                for _, part in ipairs(plot:GetDescendants()) do
                    pcall(function()
                        if part:IsA("BasePart") then part.Transparency = 1 end
                    end)
                end
            end
        end
    end
end)

notify("✅ SELESAI", "Semua 7 fase BasePart selesai tanpa kick!")
