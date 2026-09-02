-- ==============================================================================
-- 🔍 KALB DEEP WEATHER & FORECAST INSPECTOR (UNIVERSAL DUMPER)
-- ==============================================================================
-- Jalankan script ini di Executor, lalu buka Developer Console (F9)
-- Script ini akan otomatis memindai seluruh:
-- 1. 📡 RemoteEvent & RemoteFunction terkait Cuaca & Forecast
-- 2. 🏗️ Model "Weather Machine" & Objek Cuaca di Workspace (Text, GUI, Values)
-- 3. 🖥️ PlayerGui (TextLabel, HUD, Countdown Cuaca)
-- 4. 🧠 ModuleScript & Upvalues WeatherService
-- ==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local dumpResult = {}
local function log(msg)
    print(msg)
    table.insert(dumpResult, tostring(msg))
end

log("==================================================")
log("🚀 [KALB INSPECTOR] MEMULAI PEMINDAIAN DATA WEATHER...")
log("==================================================")

-- 1. SCAN REMOTE NETWORK
log("\n--- [1. REMOTE EVENTS & FUNCTIONS TERKAIT WEATHER] ---")
local foundRemotes = 0
for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
    if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
        local lower = string.lower(r.Name)
        if string.find(lower, "weather") or string.find(lower, "event") or string.find(lower, "forecast") or string.find(lower, "machine") or string.find(lower, "timer") then
            foundRemotes = foundRemotes + 1
            log(string.format("📡 [%s] %s (Path: %s)", r.ClassName, r.Name, r:GetFullName()))
        end
    end
end
if foundRemotes == 0 then log("Tidak ditemukan remote khusus dengan nama weather/forecast.") end

-- 2. SCAN WORKSPACE "WEATHER MACHINE" & PROXIMITY PROMPT
log("\n--- [2. OBJEK WEATHER MACHINE DI WORKSPACE] ---")
local foundMachine = 0
for _, obj in ipairs(workspace:GetDescendants()) do
    local lower = string.lower(obj.Name)
    if string.find(lower, "weather") or string.find(lower, "machine") or string.find(lower, "forecast") then
        foundMachine = foundMachine + 1
        log(string.format("🏗️ [%s] %s (Path: %s)", obj.ClassName, obj.Name, obj:GetFullName()))
        
        -- Cek TextLabel / SurfaceGui di dalam mesin
        for _, desc in ipairs(obj:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                log(string.format("   📝 Text: '%s' (Object: %s)", desc.Text, desc.Name))
            elseif desc:IsA("ValueBase") then
                log(string.format("   🏷️ Value [%s]: '%s' = %s", desc.ClassName, desc.Name, tostring(desc.Value)))
            elseif desc:IsA("ProximityPrompt") then
                log(string.format("   🔘 ProximityPrompt: ActionText='%s', ObjectText='%s'", desc.ActionText, desc.ObjectText))
            end
        end
    end
end
if foundMachine == 0 then log("Tidak ditemukan objek Weather Machine di Workspace.") end

-- 3. SCAN PLAYERGUI (TEXT & COUNTDOWN CUACA)
log("\n--- [3. GUI CUACA DI PLAYERGUI] ---")
local pGui = lp:FindFirstChild("PlayerGui")
if pGui then
    for _, g in ipairs(pGui:GetDescendants()) do
        if g:IsA("TextLabel") or g:IsA("TextButton") then
            local text = g.Text
            local lower = string.lower(text)
            if string.find(lower, "weather") or string.find(lower, "event") or string.find(lower, "next") or string.find(lower, "ends in") or string.find(lower, "starts in") or string.find(lower, ":") then
                if #text < 80 and text ~= "" then
                    log(string.format("🖥️ [GUI Text] '%s' (Path: %s)", text, g:GetFullName()))
                end
            end
        end
    end
end

-- 4. SCAN MODULE WEATHER SERVICE
log("\n--- [4. MODULESCRIPT WEATHER & UPVALUES] ---")
local wsModule = nil
for _, m in ipairs(ReplicatedStorage:GetDescendants()) do
    if m:IsA("ModuleScript") and string.find(string.lower(m.Name), "weather") then
        log(string.format("📦 [ModuleScript] %s (Path: %s)", m.Name, m:GetFullName()))
        pcall(function()
            local req = require(m)
            if type(req) == "table" then
                for k, v in pairs(req) do
                    log(string.format("   🔑 Key: %s (%s)", tostring(k), type(v)))
                    if type(v) == "table" then
                        for subK, subV in pairs(v) do
                            log(string.format("      🔹 %s = %s (%s)", tostring(subK), tostring(subV), type(subV)))
                        end
                    elseif type(v) == "function" and getupvalues then
                        local uvs = getupvalues(v)
                        for uIdx, uVal in pairs(uvs) do
                            if type(uVal) == "table" then
                                log(string.format("      📦 Upvalue [%s]: (Table with %d keys)", tostring(uIdx), #uVal))
                                for uk, uv in pairs(uVal) do
                                    log(string.format("         🔸 %s = %s (%s)", tostring(uk), tostring(uv), type(uv)))
                                end
                            else
                                log(string.format("      📦 Upvalue [%s] = %s (%s)", tostring(uIdx), tostring(uVal), type(uVal)))
                            end
                        end
                    end
                end
            end
        end)
    end
end

log("\n==================================================")
log("✅ [KALB INSPECTOR] PEMINDAIAN SELESAI!")
log("==================================================")

-- Salin hasil ke Clipboard jika didukung
pcall(function()
    if setclipboard then
        setclipboard(table.concat(dumpResult, "\n"))
        log("📋 [CLIPBOARD] Seluruh hasil log telah otomatis disalin ke Clipboard HP/PC!")
    end
end)
