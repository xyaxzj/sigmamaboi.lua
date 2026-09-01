-- ==============================================================================
-- 🎓 KALB AUTO MATH, PECLASS & AUTO SELL (KHUSUS EVENT & SELL - TANPA KICK)
-- ==============================================================================
-- Fitur Khusus:
-- 1. 📚 Math Event Solver:
--    - Membaca soal dari GuiPart.SurfaceGui.TextLabel (Mendukung 1-3 digit, +, -, *, /, x, ÷, :)
--    - ✅ Jawaban BENAR: Hitbox diperbesar ke 200x200x200 studs (CanTouch=true, CanQuery=true)
--    - ❌ Jawaban SALAH: Part langsung dimusnahkan/dihapus (Destroy)
--    - Pemindai universal Workspace & Debris (aktif 24/7 seketika)
-- 2. 🏃 PEClass Purger:
--    - Menghapus Model angka & Part "Ball" saat event PEClass aktif
-- 3. 💰 Auto Sell All:
--    - Menjual seluruh brainrot secara berkala via RemoteFunction ref_B_SellAll
-- 4. 🛡️ Anti-AFK & 🥔 Anti-Lag Ringan
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
-- ⚙️ KONFIGURASI PENGGUNA
-- ==============================================================================
_G.autoMathEvent = true      -- true: Otomatis selesaikan soal math & perbesar jawaban benar
_G.autoPEClass = true        -- true: Otomatis hapus Model angka & Ball saat PEClass
_G.autoSellAll = true        -- true: Otomatis jual semua brainrot berkala
_G.sellInterval = 5          -- Interval waktu (detik) Auto Sell All
_G.debugConsoleLog = true    -- true: Tampilkan log di Developer Console (F9)

print("--------------------------------------------------")
print("🚀 [INIT] Memuat KALB Auto Math, PEClass & Auto Sell...")

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
-- 🛡️ ANTI-AFK (BUILT-IN)
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

-- ==============================================================================
-- 📡 DAFTAR REMOTE NETWORK & RESOLVER
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
-- 💰 FITUR 1: AUTO SELL ALL (SETIAP BEBERAPA DETIK)
-- ==============================================================================
task.spawn(function()
    while true do
        local delayTime = (_G.sellInterval and _G.sellInterval > 0) and _G.sellInterval or 5
        task.wait(delayTime)
        if _G.autoSellAll then
            pcall(function()
                local sellRemote = ref_B_SellAll or (networkFolder and networkFolder:FindFirstChild("ref_B_SellAll"))
                if not sellRemote then
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
-- 📚 FITUR 2: BACK TO SCHOOL MATH EVENT ENGINE (UNIVERSAL & BULLETPROOF)
-- ==============================================================================
local OPTIMAL_ANSWER_SIZE = Vector3.new(200, 200, 200)
local isMathEventActive = true -- Default Aktif Langsung 24/7
local isPEClassActive = false
local processedQuestionModels = {}

-- Evaluator Matematika Tangguh (Mendukung +, -, *, /, x, X, ×, ÷, :, kurung, & RichText)
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

-- Deteksi apakah sebuah Model adalah Model Soal Matematika
local function isTargetQuestionModel(model)
    if not model or not model:IsA("Model") then return false end
    local hasGui = model:FindFirstChild("GuiPart") or model:FindFirstChild("GuiPart", true)
    local hasAns = model:FindFirstChild("Answers") or model:FindFirstChild("Answers", true)
    if hasGui and hasAns then return true end
    if tonumber(model.Name) ~= nil and (hasGui or hasAns) then return true end
    return false
end

-- Cari Model Soal dari komponen apapun di dalamnya
local function getQuestionModelFromInstance(inst)
    if not inst or inst == workspace or inst == game then return nil end
    local curr = inst
    while curr and curr ~= workspace and curr ~= game do
        if curr:IsA("Model") and isTargetQuestionModel(curr) then
            return curr
        end
        curr = curr.Parent
    end
    return nil
end

-- ==============================================================================
-- 🏃 FITUR 3: PECLASS AUTO PURGER (MODEL ANGKA NON-MATH & BALL)
-- ==============================================================================
local function isTargetPEClassEntity(instance)
    if not instance then return false end

    -- Jika ini adalah soal matematika (ada GuiPart/Answers), JANGAN anggap sebagai PEClass
    if instance:IsA("Model") and (instance:FindFirstChild("GuiPart") or instance:FindFirstChild("Answers")) then
        return false
    end

    -- Part / Model dengan nama "Ball"
    local lowerName = string.lower(instance.Name)
    if lowerName == "ball" then
        return true
    end

    -- Model dengan nama angka murni saat PEClass aktif (tanpa GuiPart)
    if isPEClassActive and instance:IsA("Model") and tonumber(instance.Name) ~= nil then
        return true
    end

    return false
end

local function scanAndPurgePEClass()
    if not _G.autoPEClass or not isPEClassActive then return end
    local debris = workspace:FindFirstChild("Debris")
    local container = debris or workspace

    for _, child in ipairs(container:GetChildren()) do
        if isTargetPEClassEntity(child) then
            pcall(function()
                logConsole(string.format("🏃 [PECLASS PURGE] Menghapus %s '%s'!", child.ClassName, child.Name))
                child:Destroy()
            end)
        end
    end
end

-- ==============================================================================
-- 🧠 PROSES & SOLVE SOAL MATEMATIKA REAL-TIME
-- ==============================================================================
local function processMathQuestionModel(model)
    if not _G.autoMathEvent then return end
    if not model or not model.Parent or processedQuestionModels[model] then return end

    local guiPart = model:FindFirstChild("GuiPart") or model:FindFirstChild("GuiPart", true)
    local answersFolder = model:FindFirstChild("Answers") or model:FindFirstChild("Answers", true)

    -- Tunggu hingga GuiPart dan Answers folder ada
    if not guiPart or not answersFolder then return end

    -- Cari TextLabel pada GuiPart
    local questionLabel = guiPart:FindFirstChildWhichIsA("TextLabel", true)
    if not questionLabel then return end

    local qText = questionLabel.ContentText ~= "" and questionLabel.ContentText or questionLabel.Text
    if not qText or qText == "" then return end

    local correctAnswer = solveMathExpression(qText)
    if correctAnswer == nil then return end

    -- Ambil semua opsi jawaban dari folder Answers
    local answerItems = {}
    local totalParts = 0

    for _, child in ipairs(answersFolder:GetChildren()) do
        if child:IsA("BasePart") or child.ClassName == "Part" or child:IsA("Model") then
            totalParts = totalParts + 1
            local targetPart = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true)
            local ansLabel = child:FindFirstChildWhichIsA("TextLabel", true)
            if ansLabel and targetPart then
                local ansText = ansLabel.ContentText ~= "" and ansLabel.ContentText or ansLabel.Text
                local ansVal = parseAnswerValue(ansText)
                if ansVal ~= nil then
                    table.insert(answerItems, {part = targetPart, val = ansVal, text = ansText, obj = child})
                end
            end
        end
    end

    -- Pastikan semua pilihan jawaban sudah ter-load teksnya sebelum eksekusi
    if totalParts == 0 or #answerItems < totalParts then
        return -- Tunggu tick berikutnya agar semua label ter-load
    end

    -- Tandai bahwa model soal ini sudah berhasil diproses
    processedQuestionModels[model] = true
    isMathEventActive = true

    logConsole(string.format("📚 [MATH EVENT] Soal #%s: '%s' -> Kunci Jawaban: %s", tostring(model.Name), tostring(qText), tostring(correctAnswer)))

    -- Bersihkan partikel visual berat pada model soal
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
                item.part.Size = OPTIMAL_ANSWER_SIZE
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

    -- 1. Scan di Debris (jika ada)
    local debris = workspace:FindFirstChild("Debris")
    if debris then
        if isPEClassActive and _G.autoPEClass then
            scanAndPurgePEClass()
        end

        for _, child in ipairs(debris:GetChildren()) do
            if child:IsA("Model") and not processedQuestionModels[child] then
                if isTargetQuestionModel(child) then
                    task.defer(processMathQuestionModel, child)
                end
            end
        end
    end

    -- 2. Scan langsung di Workspace
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and not processedQuestionModels[child] then
            if isTargetQuestionModel(child) then
                task.defer(processMathQuestionModel, child)
            end
        end
    end
end

-- Listener DescendantAdded pada Workspace (Menangkap model soal instan di mana pun berada)
workspace.DescendantAdded:Connect(function(descendant)
    task.defer(function()
        if isPEClassActive and _G.autoPEClass and isTargetPEClassEntity(descendant) then
            pcall(function()
                logConsole(string.format("🏃 [PECLASS PURGE] Menghapus %s '%s'!", descendant.ClassName, descendant.Name))
                descendant:Destroy()
            end)
            return
        end

        if not _G.autoMathEvent then return end
        if descendant.Name == "GuiPart" or descendant.Name == "Answers" or descendant:IsA("TextLabel") or descendant.Name == "A" or descendant.Name == "B" then
            local model = getQuestionModelFromInstance(descendant)
            if model and not processedQuestionModels[model] then
                processMathQuestionModel(model)
            end
        elseif descendant:IsA("Model") and isTargetQuestionModel(descendant) then
            if not processedQuestionModels[descendant] then
                processMathQuestionModel(descendant)
            end
        end
    end)
end)

-- Background Scanner Loop (tiap 0.15 detik)
task.spawn(function()
    while task.wait(0.15) do
        scanAndProcessAllMath()
    end
end)

-- Scan awal saat script pertama kali jalan
task.spawn(function()
    task.wait(0.1)
    scanAndProcessAllMath()
end)

-- Listener Remote Weather
pcall(function()
    if rev_AddedWeather then
        rev_AddedWeather.OnClientEvent:Connect(function(weatherType, ...)
            if weatherType == "MathEvent" then
                isMathEventActive = true
                isPEClassActive = false
                logConsole("📡 [WEATHER] MathEvent Aktif!")
            elseif weatherType == "PEClass" then
                isPEClassActive = true
                isMathEventActive = false
                logConsole("🏃 [WEATHER] PEClass Aktif! Membersihkan Model Angka & Ball...")
                scanAndPurgePEClass()
            end
        end)
    end

    if rev_RemovedWeather then
        rev_RemovedWeather.OnClientEvent:Connect(function(weatherType, ...)
            if weatherType == "MathEvent" then
                isMathEventActive = true -- Tetap aktif agar tidak ada soal terlewat
                logConsole("☁️ [WEATHER] MathEvent Selesai!")
            elseif weatherType == "PEClass" then
                isPEClassActive = false
                logConsole("☁️ [WEATHER] PEClass Selesai!")
            end
        end)
    end
end)

print("--------------------------------------------------")
print("✅ [BackToSchool] Script Auto Math, PEClass & Auto Sell Siap Berjalan!")
