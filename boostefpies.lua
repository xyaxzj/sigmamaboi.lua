-- ==============================================================================
-- 🔬 BOOSTFPS DIAGNOSTIC MODE — Cari fitur mana yang trigger BAC
-- Setiap fase diaktifkan 1-per-1 dengan jeda 15 detik.
-- CATAT berapa detik setelah eksekusi kamu kena kick!
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local lp = Players.LocalPlayer

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = 5
        })
    end)
    print(title .. ": " .. text)
end

notify("🔬 DIAGNOSTIC", "Mulai! Perhatikan fase mana yang bikin kick...")

-- ═══════════════════════════════════════════════════════
-- FASE 1 (detik ke-0): ANTI-AFK SAJA
-- ═══════════════════════════════════════════════════════
notify("FASE 1", "Anti-AFK diaktifkan...")
pcall(function()
    local vu = game:GetService("VirtualUser")
    lp.Idled:Connect(function()
        pcall(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new(0, 0))
        end)
    end)
end)

-- ═══════════════════════════════════════════════════════
-- FASE 2 (detik ke-15): DISABLE PARTIKEL SAJA
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 2", "Disable partikel...")
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or
           v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- FASE 3 (detik ke-30): TERRAIN WATER OPTIMIZATION
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 3", "Terrain water optimization...")
pcall(function()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
    end
end)

-- ═══════════════════════════════════════════════════════
-- FASE 4 (detik ke-45): CASTSHADOW = FALSE (SEMUA BASEPART)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 4", "CastShadow = false pada semua BasePart...")
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("BasePart") then
            v.CastShadow = false
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- FASE 5 (detik ke-60): MATERIAL = SMOOTHPLASTIC (SEMUA BASEPART)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 5", "Material = SmoothPlastic...")
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- FASE 6 (detik ke-75): COLOR = PUTIH (SEMUA BASEPART)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 6", "Color = Putih (White Map)...")
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("BasePart") then
            v.Color = Color3.new(1, 1, 1)
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- FASE 7 (detik ke-90): HIDE PLAYER LAIN (TRANSPARENCY)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 7", "Sembunyikan player lain (transparency)...")
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= lp and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
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
-- FASE 8 (detik ke-105): HIDE PLOT LAIN (TRANSPARENCY)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 8", "Sembunyikan plot lain (transparency)...")
pcall(function()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if plotsFolder then
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            if plot:IsA("Model") then
                for _, part in ipairs(plot:GetDescendants()) do
                    pcall(function()
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                        end
                    end)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- FASE 9 (detik ke-120): TEXTURE REMOVAL (MESHPART + SPECIALMESH)
-- ═══════════════════════════════════════════════════════
task.wait(15)
notify("FASE 9", "Hapus tekstur MeshPart/SpecialMesh...")
for _, v in ipairs(workspace:GetDescendants()) do
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

-- ═══════════════════════════════════════════════════════
notify("✅ SELESAI", "Semua 9 fase selesai tanpa kick! Semua fitur AMAN.")
print("══════════════════════════════════════════════════")
print("✅ Semua fase selesai! Jika kamu sampai sini = semua fitur aman.")
print("══════════════════════════════════════════════════")
