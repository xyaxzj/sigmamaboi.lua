-- ==============================================================================
-- 🎓 KALB AUTO MATH, PECLASS & AUTO SELL (FLAWLESS DUAL-EVENT AFK ENGINE)
-- ==============================================================================
-- 📋 Evaluasi & Logika Sempurna:
-- 1. 📚 MathEvent (Model Soal Matematika):
--    - Ciri Pasti: Model bernama angka YANG MEMILIKI "GuiPart" dan/atau "Answers".
--    - Aksi:
--      * Baca soal dari GuiPart.SurfaceGui.TextLabel (1-3 digit, RichText, +, -, *, /, x, ÷, :).
--      * ✅ Jawaban BENAR: Hitbox diperbesar ke 200x200x200 studs (CanTouch=true, CanQuery=true, Transparency=0.5).
--      * ❌ Jawaban SALAH: Part langsung dimusnahkan/dihapus (:Destroy()).
--
-- 2. 🏃 PEClass (Model Angka & Bola Rintangan):
--    - Ciri Pasti:
--      * Part / Model bernama "Ball" (atau mengandung kata "ball").
--      * Model bernama angka murni (1, 2, 3...) YANG TIDAK MEMILIKI "GuiPart" dan "Answers".
--    - Aksi:
--      * Seketika DIHAPUS / DIMUSNAHKAN (:Destroy()) tanpa syarat dan tanpa tertahan mode.
--
-- 3. 💰 Auto Sell All:
--    - Menjual seluruh brainrot setiap 5 detik via RemoteFunction ref_B_SellAll.
--
-- 4. 🛡️ Anti-AFK & 🧹 Memory Pruner (Stabil untuk AFK Berhari-hari).
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
-- ⚙️ KONFIGURASI PENGGUNA
-- ==============================================================================
_G.autoMathEvent = true      -- true: Otomatis selesaikan soal math & perbesar jawaban benar
_G.autoPEClass = true        -- true: Otomatis hapus Model angka PEClass & Ball
_G.autoSellAll = true        -- true: Otomatis jual semua brainrot berkala
_G.sellInterval = 5          -- Interval waktu (detik) Auto Sell All
_G.debugConsoleLog = false    -- true: Tampilkan log di Developer Console (F9)

print("--------------------------------------------------")
print("🚀 [INIT] Memuat KALB Flawless Math, PEClass & Auto Sell...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local lp = Players.LocalPlayer
if not lp then
    local count = 0
    repeat
        task.wait(0.05)
        lp = Players.LocalPlayer
        count = count + 1
    until lp or count > 50
end

local function logConsole(...)
    if _G.debugConsoleLog ~= false then
        print(...)
    end
end

-- ==============================================================================
-- 🛡️ ANTI-AFK & MEMORY STABILIZER (ANTI DISCONNECT & ANTI MEMORY LEAK)
-- ==============================================================================
pcall(function()
    if getconnections then
        for _, conn in ipairs(getconnections(lp.Idled)) do
            conn:Disable()
        end
    end
end)

lp.Idled:Connect(function()
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(lp.Idled)) do
                conn:Disable()
            end
        end
        if VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)

-- Pembersih Memori Tiap 60 Detik
task.spawn(function()
    while task.wait(60) do
        pcall(function()
            if gcinfo then gcinfo() end
            if collectgarbage then collectgarbage("collect") end
        end)
    end
end)

-- ==============================================================================
-- 📡 DAFTAR REMOTE NETWORK & AUTO-RESOLVER
-- ==============================================================================
local networkFolder = nil
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
    local packages = shared and (shared:FindFirstChild("Packages") or shared:WaitForChild("Packages", 3))
    networkFolder = packages and (packages:FindFirstChild("Network") or packages:WaitForChild("Network", 3))
end)

local function findRemote(name, className)
    if networkFolder then
        local r = networkFolder:FindFirstChild(name)
        if r and (not className or r:IsA(className)) then return r end
    end
    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
        if r.Name == name and (not className or r:IsA(className)) then
            return r
        end
    end
    return nil
end

local ref_B_SellAll = findRemote("ref_B_SellAll", "RemoteFunction")
local rev_AddedWeather = findRemote("rev_AddedWeather", "RemoteEvent")
local rev_RemovedWeather = findRemote("rev_RemovedWeather", "RemoteEvent")

-- ==============================================================================
-- 💰 FITUR 1: AUTO SELL ALL (SETIAP 5 DETIK NONSTOP)
-- ==============================================================================
task.spawn(function()
    while true do
        local delayTime = (_G.sellInterval and _G.sellInterval > 0) and _G.sellInterval or 5
        task.wait(delayTime)
        if _G.autoSellAll then
            pcall(function()
                local sellRemote = ref_B_SellAll
                if not sellRemote or not sellRemote.Parent then
                    sellRemote = findRemote("ref_B_SellAll", "RemoteFunction")
                    ref_B_SellAll = sellRemote
                end

                if sellRemote and sellRemote:IsA("RemoteFunction") then
                    sellRemote:InvokeServer()
                    logConsole("💰 [AUTO SELL] Berhasil menjual seluruh brainrot!")
                end
            end)
        end
    end
end)

-- ==============================================================================
-- 🔍 KLASIFIKASI OBJEK & STRUKTUR (MATH vs PECLASS)
-- ==============================================================================
local OPTIMAL_ANSWER_SIZE = Vector3.new(200, 200, 200)
local modelLastSolvedQuestion = {} -- Melacak soal terakhir: [model] = "7+5"

-- Deteksi apakah model adalah Model Soal Matematika (Memiliki GuiPart atau Answers)
local function isMathQuestionModel(model)
    if not model or not model:IsA("Model") then return false end
    local hasGui = model:FindFirstChild("GuiPart") or model:FindFirstChild("GuiPart", true)
    local hasAns = model:FindFirstChild("Answers") or model:FindFirstChild("Answers", true)
    if hasGui or hasAns then
        return true
    end
    return false
end

-- Deteksi apakah objek adalah Bola PEClass (Part/Model bernama Ball)
local function isPEClassBall(inst)
    if not inst then return false end
    local lowerName = string.lower(inst.Name)
    if lowerName == "ball" or string.find(lowerName, "ball") then
        return true
    end
    return false
end

-- Deteksi apakah model adalah Model Angka PEClass (Model angka murni TANPA GuiPart & TANPA Answers)
local function isPEClassModel(model)
    if not model or not model:IsA("Model") then return false end
    -- Harus bernama angka (cth: "1", "2", "3"...)
    if tonumber(model.Name) == nil then return false end
    -- Jika memiliki GuiPart atau Answers, ini MathEvent, BUKAN PEClass!
    if isMathQuestionModel(model) then return false end
    return true
end

-- Cari Model Soal dari komponen apapun di dalamnya
local function getQuestionModelFromInstance(inst)
    if not inst or inst == workspace or inst == game then return nil end
    local curr = inst
    while curr and curr ~= workspace and curr ~= game do
        if curr:IsA("Model") and isMathQuestionModel(curr) then
            return curr
        end
        curr = curr.Parent
    end
    return nil
end

-- Bersihkan cache model yang sudah dihancurkan
local function pruneProcessedCache()
    for model, _ in pairs(modelLastSolvedQuestion) do
        if not model or not model.Parent then
            modelLastSolvedQuestion[model] = nil
        end
    end
end

-- ==============================================================================
-- 🏃 MEKANIK 1: PURGER PECLASS (BALL & MODEL ANGKA NON-MATH)
-- ==============================================================================
local function purgePEClassEntities()
    if not _G.autoPEClass then return end

    local containers = {workspace}
    local debris = workspace:FindFirstChild("Debris")
    if debris then table.insert(containers, debris) end

    for _, container in ipairs(containers) do
        for _, child in ipairs(container:GetChildren()) do
            -- 1. Hapus Bola PEClass
            if isPEClassBall(child) then
                pcall(function()
                    logConsole(string.format("🏃 [PECLASS] Menghapus Ball '%s' (%s)!", child.Name, child.ClassName))
                    child:Destroy()
                end)
            -- 2. Hapus Model Angka PEClass
            elseif isPEClassModel(child) then
                pcall(function()
                    logConsole(string.format("🏃 [PECLASS] Menghapus Model Angka '%s'!", child.Name))
                    child:Destroy()
                end)
            end
        end
    end
end

-- ==============================================================================
-- 🧠 MEKANIK 2: EVALUATOR & SOLVER MATEMATIKA
-- ==============================================================================
local function solveMathExpression(rawText)
    if not rawText or rawText == "" then return nil end
    local str = tostring(rawText)

    -- Bersihkan tag HTML / RichText (<font>...</font>, <stroke>...</stroke>)
    str = str:gsub("<[^>]+>", "")

    -- Bersihkan tanda sama dengan dan tanda tanya
    str = str:gsub("=%s*%?", ""):gsub("=", ""):gsub("%?", "")

    -- Coba ekstrak pola 2 angka dengan operator matematika (cth: "7 + 5", "14 + 16", "12 x 4", "20 ÷ 5")
    local num1Str, op, num2Str = str:match("(%-?%d+%.?%d*)%s*([%+%-%*%/xX×÷:])%s*(%-?%d+%.?%d*)")
    if num1Str and op and num2Str then
        local n1 = tonumber(num1Str)
        local n2 = tonumber(num2Str)
        if n1 and n2 then
            if op == "+" then return n1 + n2
            elseif op == "-" then return n1 - n2
            elseif op == "*" or op == "x" or op == "X" or op == "×" then return n1 * n2
            elseif (op == "/" or op == "÷" or op == ":") and n2 ~= 0 then return n1 / n2
            end
        end
    end

    -- Konversi simbol perkalian & pembagian global
    local cleanStr = str:gsub("×", "*"):gsub("x", "*"):gsub("X", "*"):gsub("÷", "/"):gsub(":", "/")
    cleanStr = cleanStr:gsub("%s+", "")
    cleanStr = cleanStr:gsub("[^%d%+%-%*%/%.%(%)]", "")

    if cleanStr ~= "" then
        local func = loadstring and loadstring("return " .. cleanStr)
        if func then
            local ok, val = pcall(func)
            if ok and type(val) == "number" then
                return val
            end
        end
    end

    return nil
end

local function parseAnswerValue(rawText)
    if not rawText or rawText == "" then return nil end
    local str = tostring(rawText)
    str = str:gsub("<[^>]+>", "")
    
    -- Ekstrak angka murni dari string pilihan jawaban (cth: "12", "A) 12", "Ans: 12")
    local numMatch = str:match("(%-?%d+%.?%d*)")
    if numMatch then
        local val = tonumber(numMatch)
        if val then return val end
    end

    return solveMathExpression(str)
end

local function processMathQuestionModel(model)
    if not _G.autoMathEvent then return end
    if not model or not model.Parent then return end

    local guiPart = model:FindFirstChild("GuiPart") or model:FindFirstChild("GuiPart", true)
    local answersFolder = model:FindFirstChild("Answers") or model:FindFirstChild("Answers", true)

    if not guiPart or not answersFolder then return end

    local questionLabel = guiPart:FindFirstChildWhichIsA("TextLabel", true)
    if not questionLabel then return end

    local qText = questionLabel.ContentText ~= "" and questionLabel.ContentText or questionLabel.Text
    if not qText or qText == "" then return end

    -- Jika soal ini sudah pernah diselesaikan dan part jawaban benar sudah berukuran 200, lewati
    if modelLastSolvedQuestion[model] == qText then
        return
    end

    local correctAnswer = solveMathExpression(qText)
    if correctAnswer == nil then return end

    -- Ambil semua opsi jawaban dari folder Answers
    local answerItems = {}
    for _, child in ipairs(answersFolder:GetChildren()) do
        if child:IsA("BasePart") or child.ClassName == "Part" or child:IsA("Model") then
            local targetPart = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true)
            local ansLabel = child:FindFirstChildWhichIsA("TextLabel", true)
            if ansLabel and targetPart then
                local ansText = ansLabel.ContentText ~= "" and ansLabel.ContentText or ansLabel.Text
                if ansText and ansText ~= "" then
                    local ansVal = parseAnswerValue(ansText)
                    if ansVal ~= nil then
                        table.insert(answerItems, {part = targetPart, val = ansVal, text = ansText, obj = child})
                    end
                end
            end
        end
    end

    -- Butuh setidaknya 1 opsi jawaban ter-load sebelum eksekusi
    if #answerItems == 0 then
        return
    end

    modelLastSolvedQuestion[model] = qText

    logConsole(string.format("📚 [MATH EVENT] Soal #%s: '%s' -> Kunci Jawaban: %s", tostring(model.Name), tostring(qText), tostring(correctAnswer)))

    -- Bersihkan partikel visual berat
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("ParticleEmitter") or desc:IsA("Fire") or desc:IsA("Smoke") or 
           desc:IsA("Trail") or desc:IsA("PointLight") or desc:IsA("SpotLight") then
            pcall(function() desc:Destroy() end)
        end
    end

    -- Eksekusi pembesaran jawaban benar & penghapusan jawaban salah
    local foundCorrect = false
    for _, item in ipairs(answerItems) do
        local isCorrect = (math.abs(item.val - correctAnswer) < 0.0001)

        if isCorrect and not foundCorrect then
            foundCorrect = true
            -- JAWABAN BENAR: Perbesar Hitbox (200x200x200) & aktifkan CanTouch/CanQuery
            pcall(function()
                item.part.CanCollide = false
                item.part.CanTouch = true
                item.part.CanQuery = true
                item.part.CastShadow = false
                item.part.Transparency = 0.5
                if item.part.Size ~= OPTIMAL_ANSWER_SIZE then
                    item.part.Size = OPTIMAL_ANSWER_SIZE
                end
            end)
            logConsole(string.format("   ✅ [JAWABAN BENAR] Part %s ('%s') diperbesar ke 200 studs!", item.part.Name, tostring(item.text)))
        else
            -- JAWABAN SALAH: Hapus Part agar tidak tersentuh bola/karakter!
            pcall(function()
                item.obj:Destroy()
            end)
            logConsole(string.format("   ❌ [JAWABAN SALAH] Part %s ('%s') dihapus!", item.part.Name, tostring(item.text)))
        end
    end
end

-- ==============================================================================
-- 📡 PEMINDAI UNIVERSAL WORKSPACE & DEBRIS
-- ==============================================================================
local function scanAndProcessAllMath()
    if not _G.autoMathEvent then return end

    local containers = {workspace}
    local debris = workspace:FindFirstChild("Debris")
    if debris then table.insert(containers, debris) end

    for _, container in ipairs(containers) do
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Model") and isMathQuestionModel(child) then
                task.defer(processMathQuestionModel, child)
            end
        end
    end
end

local function runFullCycle()
    pruneProcessedCache()

    -- 1. Eksekusi Purger PEClass (Hapus Ball & Model Angka PEClass)
    if _G.autoPEClass then
        purgePEClassEntities()
    end

    -- 2. Eksekusi Solver MathEvent (Hitung & Perbesar Jawaban Benar)
    if _G.autoMathEvent then
        scanAndProcessAllMath()
    end
end

-- ==============================================================================
-- ⚡ LISTENER DESCENDANT ADDED (INSTAN REAL-TIME)
-- ==============================================================================
workspace.DescendantAdded:Connect(function(descendant)
    task.defer(function()
        if not descendant or not descendant.Parent then return end

        -- 1. Deteksi Ball PEClass Instan
        if _G.autoPEClass and isPEClassBall(descendant) then
            pcall(function()
                logConsole(string.format("🏃 [PECLASS] Menghapus Ball '%s'!", descendant.Name))
                descendant:Destroy()
            end)
            return
        end

        -- 2. Deteksi Model Angka PEClass Instan (Model angka tanpa GuiPart/Answers)
        if _G.autoPEClass and descendant:IsA("Model") and isPEClassModel(descendant) then
            pcall(function()
                logConsole(string.format("🏃 [PECLASS] Menghapus Model Angka '%s'!", descendant.Name))
                descendant:Destroy()
            end)
            return
        end

        -- 3. Deteksi Komponen Math Event Instan
        if _G.autoMathEvent then
            if descendant.Name == "GuiPart" or descendant.Name == "Answers" or descendant:IsA("TextLabel") or descendant.Name == "A" or descendant.Name == "B" then
                local model = getQuestionModelFromInstance(descendant)
                if model and isMathQuestionModel(model) then
                    processMathQuestionModel(model)
                end
            elseif descendant:IsA("Model") and isMathQuestionModel(descendant) then
                processMathQuestionModel(descendant)
            end
        end
    end)
end)

-- Fast Background Watchdog Loop (tiap 0.1 detik)
task.spawn(function()
    while task.wait(0.1) do
        pcall(runFullCycle)
    end
end)

-- Scan awal saat script dieksekusi
task.spawn(function()
    task.wait(0.1)
    pcall(runFullCycle)
end)

-- ==============================================================================
-- 🌦️ SINKRONISASI REMOTE WEATHER (EVENT NOTIFIER)
-- ==============================================================================
local function setupWeatherListeners()
    local addW = rev_AddedWeather or findRemote("rev_AddedWeather", "RemoteEvent")
    if addW then
        addW.OnClientEvent:Connect(function(weatherType, ...)
            logConsole(string.format("📡 [WEATHER] Event Baru: %s", tostring(weatherType)))
            modelLastSolvedQuestion = {} -- Reset cache setiap ada event baru
            pcall(runFullCycle)
        end)
    end

    local remW = rev_RemovedWeather or findRemote("rev_RemovedWeather", "RemoteEvent")
    if remW then
        remW.OnClientEvent:Connect(function(weatherType, ...)
            logConsole(string.format("☁️ [WEATHER] Event %s Berakhir.", tostring(weatherType)))
            modelLastSolvedQuestion = {}
        end)
    end
end

setupWeatherListeners()

print("--------------------------------------------------")
print("✅ [BackToSchool] Flawless Dual-Event Engine (Math & PEClass) Aktif & Siap AFK 24/7!")
