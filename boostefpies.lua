-- ==============================================================================
-- 🔬 BOOSTFPS DIAGNOSTIC v2 — TANPA VIRTUALUSER
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

notify("START", "Diagnostic v2 tanpa VirtualUser. Mulai...")

-- FASE 1 (0 detik): DISABLE PARTIKEL
task.wait(15)
notify("FASE 1", "Disable partikel...")
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or
           v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        end
    end)
end

-- FASE 2 (15 detik): CASTSHADOW = FALSE
task.wait(15)
notify("FASE 2", "CastShadow = false...")
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("BasePart") then v.CastShadow = false end
    end)
end

-- FASE 3 (30 detik): MATERIAL = SMOOTHPLASTIC
task.wait(15)
notify("FASE 3", "Material = SmoothPlastic...")
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic end
    end)
end

-- FASE 4 (45 detik): COLOR = PUTIH
task.wait(15)
notify("FASE 4", "Color = Putih...")
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("BasePart") then v.Color = Color3.new(1, 1, 1) end
    end)
end

-- FASE 5 (60 detik): HAPUS TEKSTUR
task.wait(15)
notify("FASE 5", "Hapus tekstur MeshPart/Decal...")
for _, v in ipairs(workspace:GetDescendants()) do
    pcall(function()
        if v:IsA("MeshPart") then v.TextureID = ""
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
        elseif v:IsA("SpecialMesh") then v.TextureId = ""
        end
    end)
end

-- FASE 6 (75 detik): TERRAIN WATER
task.wait(15)
notify("FASE 6", "Terrain water optimization...")
pcall(function()
    local t = workspace:FindFirstChildOfClass("Terrain")
    if t then
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 0
    end
end)

-- FASE 7 (90 detik): HIDE PLAYER LAIN
task.wait(15)
notify("FASE 7", "Hide player lain...")
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

-- FASE 8 (105 detik): HIDE PLOT LAIN
task.wait(15)
notify("FASE 8", "Hide plot lain...")
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

notify("✅ SELESAI", "Semua 8 fase selesai tanpa kick!")
