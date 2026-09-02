-- ==============================================================================
-- 🔬 KALB SUPER DEEP ALGORITHM & WEATHER REVERSE-ENGINEER (INSPECTOR V2)
-- ==============================================================================
-- Jalankan script ini di Executor, lalu buka Developer Console (F9)
-- Script ini akan otomatis membedah:
-- 1. 📜 String Constants & Logika Rotasi di Module Weather
-- 2. 🏷️ Attributes di Workspace, Admin Machine, Machine & ReplicatedStorage
-- 3. 🧠 Decompiler / Bytecode Constants pada WeatherData & WeatherController
-- 4. ⏰ Pola Waktu & Rotasi Jam (Back to School 1 Jam)
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
log("🔬 [REVERSE-ENGINEER] MEMULAI ANALISIS ALGORITMA WEATHER...")
log("==================================================")

-- 1. CEK SEMUA ATTRIBUTES DI SELURUH GAME
log("\n--- [1. ATTRIBUTES DI WORKSPACE & REPLICATEDSTORAGE] ---")
local checkedRoots = {
    workspace,
    workspace:FindFirstChild("Admin Machine"),
    workspace:FindFirstChild("Machine"),
    ReplicatedStorage,
    ReplicatedStorage:FindFirstChild("Shared"),
    ReplicatedStorage:FindFirstChild("Modules"),
    game:GetService("Lighting")
}

for _, root in ipairs(checkedRoots) do
    if root then
        local attrs = root:GetAttributes()
        local count = 0
        for k, v in pairs(attrs) do
            count = count + 1
            log(string.format("🏷️ Attr [%s]: '%s' = %s (%s)", root.Name, tostring(k), tostring(v), type(v)))
        end
        if count == 0 then
            log(string.format("   [%s] Tidak memiliki attributes.", root.Name))
        end
    end
end

-- 2. DUMP ISI LENGKAP WEATHERDATA & CONSTANTS
log("\n--- [2. BEDAH MODULE DATA: WEATHERDATA] ---")
pcall(function()
    local wd = require(ReplicatedStorage.Shared.Data.WeatherData)
    if type(wd) == "table" then
        for k, v in pairs(wd) do
            if type(v) == "table" then
                log(string.format("📦 WeatherData.%s = {", tostring(k)))
                for subK, subV in pairs(v) do
                    log(string.format("   🔹 [%s] = %s", tostring(subK), tostring(subV)))
                end
                log("}")
            else
                log(string.format("🔹 WeatherData.%s = %s (%s)", tostring(k), tostring(v), type(v)))
            end
        end
    end
end)

-- 3. SCAN SEMUA CONSTANTS & UPVALUES DARI FUNCTION WEATHERCONTROLLER & WEATHERSERVICE
log("\n--- [3. BEDAH FUNCTIONS & UPVALUES WEATHERCONTROLLER] ---")
pcall(function()
    local wc = require(ReplicatedStorage.Modules.ControllerLoader.WeatherController)
    if type(wc) == "table" then
        for k, fn in pairs(wc) do
            log(string.format("🔑 WeatherController.%s (%s)", tostring(k), type(fn)))
            if type(fn) == "function" and getconstants then
                local consts = getconstants(fn)
                local constStr = {}
                for idx, c in ipairs(consts) do
                    if type(c) == "string" or type(c) == "number" then
                        table.insert(constStr, string.format("[%d]=%s", idx, tostring(c)))
                    end
                end
                log(string.format("   📜 Constants: %s", table.concat(constStr, ", ")))
            end
            if type(fn) == "function" and getupvalues then
                local uvs = getupvalues(fn)
                for uIdx, uVal in pairs(uvs) do
                    log(string.format("   📦 Upvalue [%s] = %s (%s)", tostring(uIdx), tostring(uVal), type(uVal)))
                end
            end
        end
    end
end)

-- 4. BEDAH CMDR COMMAND ADDWEATHER / SERWEATHER (MELIHAT LOGIKA SERVER/ADMIN)
log("\n--- [4. BEDAH CMDR WEATHER COMMANDS] ---")
local cmdFolder = ReplicatedStorage:FindFirstChild("CmdrClient") and ReplicatedStorage.CmdrClient:FindFirstChild("Commands")
if cmdFolder then
    for _, cmd in ipairs(cmdFolder:GetChildren()) do
        if string.find(string.lower(cmd.Name), "weather") and cmd:IsA("ModuleScript") then
            pcall(function()
                local cData = require(cmd)
                log(string.format("⚡ Command '%s':", cmd.Name))
                for k, v in pairs(cData) do
                    if type(v) == "table" then
                        log(string.format("   🔑 %s = (table)", tostring(k)))
                        for subK, subV in pairs(v) do
                            log(string.format("      🔹 %s = %s", tostring(subK), tostring(subV)))
                        end
                    else
                        log(string.format("   🔑 %s = %s", tostring(k), tostring(v)))
                    end
                end
            end)
        end
    end
end

-- 5. ANALISIS ROTASI WAKTU BACK TO SCHOOL (JAM & MENIT)
log("\n--- [5. ANALISIS POLA WAKTU SERVER] ---")
local now = os.time()
local date = os.date("*t", now)
log(string.format("🕒 Waktu Saat Ini: %02d:%02d:%02d (Menit ke-%d dari jam %02d)", date.hour, date.min, date.sec, date.min, date.hour))
log(string.format("📊 Menit dalam 1 Jam: %d / 60 Menit", date.min))
log(string.format("💡 Interval 20 Menit: Menit 0-20 (Fase 1), Menit 20-40 (Fase 2), Menit 40-60 (Fase 3)"))

log("\n==================================================")
log("✅ [INSPECTOR V2] ANALISIS SELESAI!")
log("==================================================")

pcall(function()
    if setclipboard then
        setclipboard(table.concat(dumpResult, "\n"))
        log("📋 [CLIPBOARD] Hasil analisis telah disalin ke Clipboard!")
    end
end)
