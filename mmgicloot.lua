-- ==============================================================================
-- 🎓 KALB AUTO MATH, PECLASS & AUTO SELL (FLAWLESS & GUARANTEED 24/7 AFK)
-- ==============================================================================
-- 📋 Fitur Utama:
-- 1. 🚀 Anti-Lag & Extreme FPS Boost (Potato Mode):
--    - Menghapus shadow, partikel berat, tekstur, efek blur, bloom, post-processing
--
-- 2. 📚 MathEvent Auto Solver:
--    - Membaca soal dari GuiPart.SurfaceGui.TextLabel (1-3 digit, RichText, +, -, *, /, x, ÷, :)
--    - ✅ Jawaban BENAR: Hitbox diperbesar ke 200x200x200 studs (CanTouch=true, CanQuery=true, Transparency=0.5)
--    - ❌ Jawaban SALAH: Part langsung dimusnahkan/dihapus (:Destroy())
--
-- 3. 🏃 PEClass Purger (100% GARANSI HAPUS):
--    - Menghapus SEMUA Part/MeshPart/Model bernama "Ball" (di seluruh Workspace & Debris)
--    - Menghapus SEMUA Model angka PEClass (Model angka tanpa GuiPart/Answers)
--    - Menggunakan delay aman 0.08s agar tidak salah menghapus soal Math
--
-- 4. 💰 Auto Sell All:
--    - Menjual seluruh brainrot setiap 5 detik via RemoteFunction ref_B_SellAll
--
-- 5. 🛡️ Anti-AFK & 🧹 Memory Pruner (Anti Disconnect 24/7)
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
-- ⚙️ KONFIGURASI PENGGUNA
-- ==============================================================================
_G.antiLag = true            -- true: Aktifkan Anti-Lag / FPS Boost Ekstrem (Potato Mode)
_G.autoMathEvent = true      -- true: Otomatis selesaikan soal math & perbesar jawaban benar
_G.autoPEClass = true        -- true: Otomatis hapus Model angka PEClass & Ball
_G.autoSellAll = true        -- true: Otomatis jual semua brainrot berkala
_G.sellInterval = 5          -- Interval waktu (detik) Auto Sell All
_G.debugConsoleLog = true    -- true: Tampilkan log di Developer Console (F9)

print("--------------------------------------------------")
print("🚀 [INIT] Memuat KALB Perfect Math, PEClass & Auto Sell...")

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
-- 🚀 SISTEM ANTI-LAG & FPS BOOSTER (POTATO MODE EKSTREM)
-- ==============================================================================
local function stripTexture(v)
    if not v then return end
    if lp and lp.Character and (v == lp.Character or v:IsDescendantOf(lp.Character)) then return end

    pcall(function()
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
            v.Color = Color3.new(1, 1, 1)
            if v:IsA("MeshPart") then
                v.TextureID = ""
            end
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("SurfaceAppearance") or v:IsA("Clothing") or v:IsA("ShirtGraphic") then
            v:Destroy()
        end
    end)
end

if _G.antiLag then
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            stripTexture(v)
        end

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Sky") then
                v:Destroy()
            end
        end

        if setfpscap then
            pcall(setfpscap, 60)
        end

        logConsole("🚀 [ANTI-LAG] Potato Mode & FPS Booster berhasil diaktifkan!")
    end)

    workspace.DescendantAdded:Connect(function(descendant)
        if _G.antiLag then
            task.defer(stripTexture, descendant)
        end
    end)
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

-- Deteksi apakah model adalah Model Soal Matematika
local function isMathQuestionModel(model)
    if not model or not model:IsA("Model") then return false end
    local hasGui = model:FindFirstChild("GuiPart") or model:FindFirstChild("GuiPart", true)
    local hasAns = model:FindFirstChild("Answers") or model:FindFirstChild("Answers", true)
    if hasGui or hasAns then
        return true
    end
    return false
end

-- Deteksi apakah objek adalah Bola PEClass
local function isPEClassBall(inst)
    if not inst then return false end
    local lowerName = string.lower(inst.Name)
    if lowerName == "ball" or string.find(lowerName, "ball") then
        return true
    end
    return false
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

-- Bersihkan cache model yang sudah musnah
local function pruneProcessedCache()
    for model, _ in pairs(modelLastSolvedQuestion) do
        if not model or not model.Parent then
            modelLastSolvedQuestion[model] = nil
        end
    end
end

-- ==============================================================================
-- 🏃 MEKANIK PECLASS: PURGER BALL & MODEL ANGKA PECLASS (100% RELIABLE)
-- ==============================================================================
local function purgePEClassEntities()
    if not _G.autoPEClass then return end

    local debris = workspace:FindFirstChild("Debris")
    local containers = {workspace}
    if debris then table.insert(containers, debris) end

    for _, container in ipairs(containers) do
        -- 1. Hapus SEMUA Ball di mana pun berada (direct child & descendant)
        for _, desc in ipairs(container:GetDescendants()) do
            if isPEClassBall(desc) then
                pcall(function()
                    logConsole(string.format("🏃 [PECLASS PURGE] Menghapus Ball '%s' (%s)!", desc.Name, desc.ClassName))
                    desc:Destroy()
                end)
            end
        end

        -- 2. Hapus Model Angka PEClass (Model angka tanpa GuiPart & tanpa Answers)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Model") and (tonumber(child.Name) ~= nil or child.Name:match("^%d+$")) then
                local hasGui = child:FindFirstChild("GuiPart") or child:FindFirstChild("GuiPart", true)
                local hasAns = child:FindFirstChild("Answers") or child:FindFirstChild("Answers", true)
                
                -- Jika tidak punya GuiPart dan tidak punya Answers, ini 100% model angka PEClass!
                if not hasGui and not hasAns then
                    pcall(function()
                        logConsole(string.format("🏃 [PECLASS PURGE] Menghapus Model Angka PEClass '%s'!", child.Name))
                        child:Destroy()
                    end)
                end
            end
        end
    end
end

-- ==============================================================================
-- 🧠 EVALUATOR & SOLVER MATEMATIKA
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

    -- 2. Eksekusi Solver MathEvent
    if _G.autoMathEvent then
        scanAndProcessAllMath()
    end
end

-- ==============================================================================
-- ⚡ LISTENER DESCENDANT ADDED (REAL-TIME INSTANT)
-- ==============================================================================
workspace.DescendantAdded:Connect(function(descendant)
    task.defer(function()
        if not descendant or not descendant.Parent then return end

        -- 1. Deteksi Ball PEClass Instan (Hapus seketika)
        if _G.autoPEClass and isPEClassBall(descendant) then
            pcall(function()
                logConsole(string.format("🏃 [PECLASS PURGE] Menghapus Ball '%s'!", descendant.Name))
                descendant:Destroy()
            end)
            return
        end

        -- 2. Deteksi Model Angka PEClass Instan (Tunggu 0.08s untuk validasi bahwa ini bukan soal Math)
        if _G.autoPEClass and descendant:IsA("Model") and (tonumber(descendant.Name) ~= nil or descendant.Name:match("^%d+$")) then
            task.wait(0.08)
            if descendant and descendant.Parent then
                local hasGui = descendant:FindFirstChild("GuiPart") or descendant:FindFirstChild("GuiPart", true)
                local hasAns = descendant:FindFirstChild("Answers") or descendant:FindFirstChild("Answers", true)
                if not hasGui and not hasAns then
                    pcall(function()
                        logConsole(string.format("🏃 [PECLASS PURGE] Menghapus Model Angka PEClass '%s'!", descendant.Name))
                        descendant:Destroy()
                    end)
                    return
                end
            end
        end

        -- 3. Deteksi Komponen Math Event Instan
        if _G.autoMathEvent then
            if descendant.Name == "GuiPart" or descendant.Name == "Answers" or descendant:IsA("TextLabel") or descendant.Name == "A" or descendant.Name == "B" then
                local model = getQuestionModelFromInstance(descendant)
                if model then
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
print("✅ [BackToSchool] Perfect Math & PEClass Engine + Anti-Lag Siap Berjalan 24/7!")
