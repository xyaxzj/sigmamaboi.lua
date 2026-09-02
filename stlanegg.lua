-- ==============================================================================
-- 🔬 KALB NEXT EVENT PREDICTOR - DEEP HUNT (INSPECTOR V3)
-- ==============================================================================
-- Target Pencarian:
-- 1. Queue/Schedule tabel di WeatherService_Client (NextEvent, Queue, Schedule, dll)
-- 2. String Value atau Attribute yang berisi nama event berikutnya
-- 3. Payload dari rev_WeatherUpdate (apakah termasuk next event?)
-- 4. Semua upvalue & constants di fungsi WeatherService
-- ==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dumpResult = {}
local function log(msg)
    print(msg)
    table.insert(dumpResult, tostring(msg))
end

log("==================================================")
log("🔬 [HUNT V3] MENCARI DATA NEXT EVENT PREDICTION...")
log("==================================================")

-- 1. BEDAH SEMUA FIELD DI WeatherService_Client
log("\n--- [1. SEMUA FIELD DI WeatherService_Client] ---")
pcall(function()
    local ws = require(ReplicatedStorage.Modules.ServicesLoader.WeatherService_Client)
    if type(ws) == "table" then
        for k, v in pairs(ws) do
            local vType = type(v)
            if vType == "table" then
                log(string.format("📦 WeatherService_Client.%s = {", tostring(k)))
                for subK, subV in pairs(v) do
                    log(string.format("   🔹 [%s] = %s (%s)", tostring(subK), tostring(subV), type(subV)))
                end
                log("}")
            else
                log(string.format("🔑 WeatherService_Client.%s = %s (%s)", tostring(k), tostring(v), vType))
            end
        end
    end
end)

-- 2. INTERCEPT rev_WeatherUpdate (cek payload-nya)
log("\n--- [2. INTERCEPT rev_WeatherUpdate PAYLOAD] ---")
log("🎧 Mendengarkan rev_WeatherUpdate selama 10 detik...")
pcall(function()
    local networkFolder
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local packages = shared and shared:FindFirstChild("Packages")
    networkFolder = packages and packages:FindFirstChild("Network")

    local rev_WeatherUpdate = networkFolder and networkFolder:FindFirstChild("rev_WeatherUpdate")
    if rev_WeatherUpdate then
        rev_WeatherUpdate.OnClientEvent:Connect(function(...)
            local args = {...}
            log(string.format("⚡ rev_WeatherUpdate PAYLOAD (%d args):", #args))
            for i, arg in ipairs(args) do
                if type(arg) == "table" then
                    log(string.format("   Arg[%d] = TABLE {", i))
                    for k, v in pairs(arg) do
                        log(string.format("      [%s] = %s (%s)", tostring(k), tostring(v), type(v)))
                    end
                    log("   }")
                else
                    log(string.format("   Arg[%d] = %s (%s)", i, tostring(arg), type(arg)))
                end
            end
        end)
    else
        log("❌ rev_WeatherUpdate tidak ditemukan!")
    end
end)

-- 3. INTERCEPT rev_AddedWeather (cek apakah berisi next event info)
log("\n--- [3. INTERCEPT rev_AddedWeather PAYLOAD] ---")
pcall(function()
    local networkFolder
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local packages = shared and shared:FindFirstChild("Packages")
    networkFolder = packages and packages:FindFirstChild("Network")

    local rev_Added = networkFolder and networkFolder:FindFirstChild("rev_AddedWeather")
    if rev_Added then
        rev_Added.OnClientEvent:Connect(function(...)
            local args = {...}
            log(string.format("⚡ rev_AddedWeather PAYLOAD (%d args):", #args))
            for i, arg in ipairs(args) do
                if type(arg) == "table" then
                    log(string.format("   Arg[%d] = TABLE {", i))
                    for k, v in pairs(arg) do
                        log(string.format("      [%s] = %s (%s)", tostring(k), tostring(v), type(v)))
                    end
                    log("   }")
                else
                    log(string.format("   Arg[%d] = %s (%s)", i, tostring(arg), type(arg)))
                end
            end
        end)
        log("✅ Listener rev_AddedWeather aktif - tunggu sampai event berikutnya spawn!")
    end
end)

-- 4. SCAN SEMUA UPVALUE WeatherService_Client FUNCTIONS
log("\n--- [4. SCAN UPVALUE FUNCTIONS WeatherService_Client] ---")
pcall(function()
    local ws = require(ReplicatedStorage.Modules.ServicesLoader.WeatherService_Client)
    if type(ws) == "table" then
        for k, fn in pairs(ws) do
            if type(fn) == "function" then
                log(string.format("\n🔑 Function: WeatherService_Client.%s", tostring(k)))

                if getupvalues then
                    local uvs = getupvalues(fn)
                    for uIdx, uVal in pairs(uvs) do
                        if type(uVal) == "table" then
                            log(string.format("   📦 Upvalue[%s] = TABLE {", tostring(uIdx)))
                            for subK, subV in pairs(uVal) do
                                log(string.format("      [%s] = %s (%s)", tostring(subK), tostring(subV), type(subV)))
                            end
                            log("   }")
                        else
                            log(string.format("   📦 Upvalue[%s] = %s (%s)", tostring(uIdx), tostring(uVal), type(uVal)))
                        end
                    end
                end

                if getconstants then
                    local consts = getconstants(fn)
                    local important = {}
                    for _, c in ipairs(consts) do
                        if type(c) == "string" and #c > 2 then
                            table.insert(important, c)
                        end
                    end
                    if #important > 0 then
                        log(string.format("   📜 String Constants: %s", table.concat(important, " | ")))
                    end
                end
            end
        end
    end
end)

-- 5. SCAN GC UNTUK TABEL DENGAN FIELD "NextEvent", "Queue", "Schedule", "nextWeather"
log("\n--- [5. SCAN GC: NextEvent / Queue / Schedule / nextWeather] ---")
pcall(function()
    if not getgc then log("❌ getgc tidak tersedia di executor ini."); return end
    local keywords = {"NextEvent", "Queue", "Schedule", "nextWeather", "upcomingEvent", "nextEvent", "weatherQueue"}
    local found = 0
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "table" then
            for _, keyword in ipairs(keywords) do
                if rawget(obj, keyword) ~= nil then
                    log(string.format("✅ DITEMUKAN! Tabel dengan field '%s':", keyword))
                    for k, v in pairs(obj) do
                        if type(v) ~= "function" and type(v) ~= "userdata" then
                            log(string.format("   [%s] = %s (%s)", tostring(k), tostring(v), type(v)))
                        end
                    end
                    found = found + 1
                    if found > 5 then break end
                end
            end
        end
        if found > 5 then break end
    end
    if found == 0 then
        log("❌ Tidak ditemukan tabel Queue/NextEvent di GC.")
        log("   Kemungkinan besar: event dipilih random di SERVER, bukan client.")
    end
end)

-- 6. SCAN WORKSPACE UNTUK OBJECT BERNAMA "NEXT"
log("\n--- [6. SCAN WORKSPACE: Object bertuliskan nama event berikutnya] ---")
pcall(function()
    local adminMachine = workspace:FindFirstChild("Admin Machine")
    if adminMachine then
        log("✅ Admin Machine ditemukan! Semua descendants:")
        for _, desc in ipairs(adminMachine:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("StringValue") or desc:IsA("TextBox") then
                log(string.format("   🔹 [%s] '%s' = '%s'", desc.ClassName, desc.Name, tostring(desc:IsA("StringValue") and desc.Value or desc.Text)))
            elseif desc:IsA("NumberValue") or desc:IsA("IntValue") then
                log(string.format("   🔢 [%s] '%s' = %s", desc.ClassName, desc.Name, tostring(desc.Value)))
            end
        end

        -- Cek Attributes
        for attrName, attrVal in pairs(adminMachine:GetAttributes()) do
            log(string.format("   🏷️ Attribute: '%s' = %s", attrName, tostring(attrVal)))
        end
    end
end)

log("\n==================================================")
log("🏁 [HUNT V3] SELESAI!")
log("📝 KESIMPULAN:")
log("   Jika tidak ada NextEvent/Queue ditemukan di GC atau Workspace,")
log("   maka event 100% dipilih random DI SERVER saat timer habis.")
log("   Satu-satunya cara predict adalah: intercept rev_AddedWeather saat spawn!")
log("==================================================")

pcall(function()
    if setclipboard then
        setclipboard(table.concat(dumpResult, "\n"))
        log("📋 Hasil disalin ke clipboard!")
    end
end)
