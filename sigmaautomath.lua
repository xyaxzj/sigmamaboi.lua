if not game:IsLoaded() then game.Loaded:Wait() end

-- ==========================================================
-- [1] INISIALISASI SERVICES & REMOTES
-- ==========================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local MarketplaceService = game:GetService("MarketplaceService") 
local LocalPlayer = Players.LocalPlayer

local MathEvents = ReplicatedStorage:WaitForChild("MathMatchEvents")
local StartRound = MathEvents:WaitForChild("StartRound")
local PlayerAnswer = MathEvents:WaitForChild("PlayerAnswer")
local SpeedRoundStart = MathEvents:WaitForChild("SpeedRoundStart")
local SpeedPlayerAnswer = MathEvents:WaitForChild("SpeedPlayerAnswer")

_G.AutoMathNormal = false
_G.AutoMathSpeed = false
_G.DelayNormal = 1.0
_G.DelaySpeed = 0.3
_G.AutoObby = false
_G.ObbyDelay = 10.0
_G.GamepassSpoofed = false
_G.AntiAFK = true
local hookInitialized = false

-- ==========================================================
-- [2] ANTI-AFK SYSTEM (BUILT-IN)
-- ==========================================================
LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ==========================================================
-- [3] UI SIGMA V4 LITE
-- ==========================================================
local successUI, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/xyaxzj/sigmamaboi.lua/refs/heads/main/NcHO.lua"))()
end)

if not successUI or type(Library) ~= "table" then return end

local Window = Library:CreateWindow({
    Name = "Math AI V23 (Full Coverage)",
    LogoText = "🧠",
    Footer = "SeNchO | Source Code Read",
    ConfigName = "MathV23"
})

local MathTab = Window:MakeTab("📝 Utama")
local NormalSec = MathTab:AddSection("🧠 Mode Normal", true)
local SpeedSec = MathTab:AddSection("⚡ Mode Speed Run", true)

NormalSec:AddToggle({Name = "✅ Auto Answer (Normal)", Default = false, Flag = "Tgl_Normal"}, function(state) _G.AutoMathNormal = state end)
NormalSec:AddInput({Name = "Jeda Jawab (Detik)", Placeholder = "1.0"}, function(txt) if tonumber(txt) then _G.DelayNormal = tonumber(txt) end end)

SpeedSec:AddToggle({Name = "⚡ Auto Answer (Speed)", Default = false, Flag = "Tgl_Speed"}, function(state) _G.AutoMathSpeed = state end)
SpeedSec:AddInput({Name = "Jeda Jawab (Detik)", Placeholder = "0.3"}, function(txt) if tonumber(txt) then _G.DelaySpeed = tonumber(txt) end end)

local ExtraTab = Window:MakeTab("🛠️ Utilitas Ekstra")
local ExploitSec = ExtraTab:AddSection("🔥 Client Exploits", true)

ExploitSec:AddToggle({Name = "🛡️ Anti-AFK (Bypass Idle Kick)", Default = true}, function(state) _G.AntiAFK = state end)
ExploitSec:AddInput({Name = "Jeda Teleport Obby (Detik)", Placeholder = "10"}, function(txt) if tonumber(txt) then _G.ObbyDelay = tonumber(txt) end end)

ExploitSec:AddToggle({Name = "🏃 Auto Teleport Obby (Anti-Pause)", Default = false}, function(state)
    _G.AutoObby = state
    if state then
        task.spawn(function()
            while _G.AutoObby do
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local targetPos = Vector3.new(189.9, 57.2, -134.3)
                    pcall(function() LocalPlayer:RequestStreamAroundAsync(targetPos) end)
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos)
                end
                task.wait(_G.ObbyDelay)
            end
        end)
    end
end)

ExploitSec:AddToggle({Name = "💎 Unlock All Gamepass (Advanced)", Default = false}, function(state)
    _G.GamepassSpoofed = state
    if state and not hookInitialized then
        local success, err = pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if _G.GamepassSpoofed and not checkcaller() then
                    if self == MarketplaceService and (method == "UserOwnsGamePassAsync" or method == "PlayerOwnsAsset") then return true end
                    if method == "InvokeServer" and (self.Name == "GamepassOwned" or self.Name == "GamepassSync") then return true end
                end
                return oldNamecall(self, ...)
            end)
        end)
        if success then hookInitialized = true Library:Notify({Title = "Hook Aktif", Content = "Bypass Gamepass Aktif!", Type = "Success", Duration = 3}) end
    end
end)

-- ==========================================================
-- [4] FUNGSI HELPER
-- ==========================================================
local function ExtractNumbers(str)
    local nums = {}
    for n in string.gmatch(str, "-?%d+") do
        local num = tonumber(n)
        if num then table.insert(nums, num) end
    end
    return nums
end

local function RomanToInt(s)
    local roman_values = {I=1, V=5, X=10, L=50, C=100, D=500, M=1000}
    local sum, prev = 0, 0
    for i = #s, 1, -1 do
        local val = roman_values[string.upper(string.sub(s, i, i))]
        if val then if val < prev then sum = sum - val else sum = sum + val end prev = val end
    end
    return sum > 0 and sum or nil
end

local function doOp(a, b, op)
    if not a or not b then return nil end
    local opC = tostring(op)
    opC = opC:gsub("\195\151", "*"):gsub("\195\183", "/"):gsub("×", "*"):gsub("÷", "/"):gsub("x", "*")
    if opC == "+" then return a + b
    elseif opC == "-" then return a - b
    elseif opC == "*" then return a * b
    elseif opC == "/" then return b ~= 0 and a / b or nil
    end
    return nil
end

-- Normalisasi semua bentuk operator Unicode ke ASCII
local function NormalizeOp(str)
    local s = tostring(str)
    s = s:gsub("\195\151", "*")  -- × (U+00D7) multi-byte
    s = s:gsub("\195\183", "/")  -- ÷ (U+00F7) multi-byte
    s = s:gsub("×", "*")
    s = s:gsub("÷", "/")
    return s
end

-- ==========================================================
-- [5] PERFECT AI ENGINE V23 (BERDASARKAN BANK SOAL ASLI)
-- ==========================================================
local function ProcessAI(data)
    if type(data) ~= "table" then return nil end

    local render = data.render or {}
    local tempId = tostring(data.templateId or ""):lower()

    -- =========================================================
    -- PRIORITAS 1: Server mengirim jawaban langsung (Classic Mode)
    -- Semua soal Classic punya field 'answer' yang berisi jawaban benar
    -- =========================================================
    if data.answer ~= nil and type(data.answer) == "number" then
        return data.answer
    end

    -- =========================================================
    -- PRIORITAS 2: Dispatch berdasarkan type soal (Classic Mode)
    -- =========================================================
    local qType = tostring(data.type or ""):lower()

    local questionText = tostring(data.questionText or ""):lower()
    local prompt      = tostring(data.prompt or ""):lower()
    local mainText    = (questionText ~= "" and questionText) or prompt
    mainText = mainText:gsub("[\n\r]", " ")
    local normText  = NormalizeOp(mainText)
    local compactMath = normText:gsub("%s+", "")

    -- NUMERIC: a op b
    if qType == "numeric" then
        local a = tonumber(data.a)
        local b = tonumber(data.b)
        local op = tostring(data.operation or "")
        if a and b and op ~= "" then return doOp(a, b, op) end
    end

    -- WORD: soal cerita
    if qType == "word" then
        local qt = tostring(data.questionText or mainText):lower()
        local nums = ExtractNumbers(qt)
        if #nums >= 2 then
            if qt:find("split equally") or qt:find("shared among") or qt:find("how many each") then
                return nums[1] / nums[2]
            end
            if qt:find("windows") or qt:find("crayons each") or qt:find("per row") or qt:find("per hive")
                or qt:find("total seats") or (qt:find("hives") and not qt:find("how many left"))
                or (qt:find("total%?") and not qt:find("how many")) then
                return nums[1] * nums[2]
            end
            if qt:find("eats") or qt:find("how many left") or qt:find("how many remain")
                or qt:find("how many stay") or qt:find("borrowed") or qt:find("get off")
                or qt:find("sold") or qt:find("swim away") or qt:find("digs up")
                or qt:find("checked out") or qt:find("go home") then
                return nums[1] - nums[2]
            end
            if qt:find("more") or qt:find("hop on") or qt:find("picks") or qt:find("grow")
                or qt:find("finds") or qt:find("arrive") or qt:find("move in")
                or qt:find("gives her") or qt:find("how many now") or qt:find("how many frogs")
                or qt:find("how many apples") or qt:find("how many marbles")
                or qt:find("total fans") or qt:find("how many people") then
                return nums[1] + nums[2]
            end
        end
        if #nums == 3 then
            if qt:find("sold") and qt:find("got") and qt:find("more") then return nums[1] - nums[2] + nums[3] end
        end
    end

    -- FINDX: cari angka hilang
    if qType == "findx" or (mainText:find("%?") and mainText:find("=")) then
        local pL, op, pR, res = compactMath:match("^(.-)([%+%-%*/])(.-)=(%d+)$")
        if pL and pR and res then
            local rN = tonumber(res)
            if pL == "?" and tonumber(pR) then
                local b = tonumber(pR)
                if op == "+" then return rN - b
                elseif op == "-" then return rN + b
                elseif op == "*" then return b ~= 0 and rN / b or nil
                elseif op == "/" then return rN * b end
            elseif pR == "?" and tonumber(pL) then
                local a = tonumber(pL)
                if op == "+" then return rN - a
                elseif op == "-" then return a - rN
                elseif op == "*" then return a ~= 0 and rN / a or nil
                elseif op == "/" then return a ~= 0 and a / rN or nil end
            end
        end
        local pL2, op2, pR2, res2 = normText:match("(%S+)%s*([%+%-%*/])%s*(%S+)%s*=%s*(%d+)")
        if pL2 and op2 and pR2 and res2 then
            local rN = tonumber(res2)
            if pL2 == "?" and tonumber(pR2) then
                local b = tonumber(pR2)
                if op2 == "+" then return rN - b
                elseif op2 == "-" then return rN + b
                elseif op2 == "*" then return b ~= 0 and rN / b or nil
                elseif op2 == "/" then return rN * b end
            elseif pR2 == "?" and tonumber(pL2) then
                local a = tonumber(pL2)
                if op2 == "+" then return rN - a
                elseif op2 == "-" then return a - rN
                elseif op2 == "*" then return a ~= 0 and rN / a or nil
                elseif op2 == "/" then return a ~= 0 and a / rN or nil end
            end
        end
    end

    -- COMPARE: mana lebih besar/kecil
    if qType == "compare" then
        local opts = data.explicitOptions
        if opts and type(opts) == "table" and #opts >= 2 then
            if mainText:find("bigger") or mainText:find("larger") then return math.max(opts[1], opts[2]) end
            if mainText:find("smaller") then return math.min(opts[1], opts[2]) end
        end
        local nums = ExtractNumbers(mainText)
        if #nums >= 2 then
            if mainText:find("bigger") or mainText:find("larger") then return math.max(nums[1], nums[2]) end
            if mainText:find("smaller") then return math.min(nums[1], nums[2]) end
        end
    end

    -- PARITY: mana yang genap/ganjil
    if qType == "parity" then
        local opts = data.explicitOptions
        if opts and type(opts) == "table" then
            if mainText:find("which is even") then
                for _, v in ipairs(opts) do if v % 2 == 0 then return v end end
            elseif mainText:find("which is odd") then
                for _, v in ipairs(opts) do if v % 2 ~= 0 then return v end end
            end
        end
        local nums = ExtractNumbers(mainText)
        if mainText:find("which is even") then
            for _, n in ipairs(nums) do if n % 2 == 0 then return n end end
        elseif mainText:find("which is odd") then
            for _, n in ipairs(nums) do if n % 2 ~= 0 then return n end end
        end
    end

    -- SEQUENCE: deret bilangan
    if qType == "sequence" or mainText:find("what comes next") then
        local nums = ExtractNumbers(tostring(data.questionText or mainText):lower())
        if #nums >= 2 then
            local diff = nums[#nums] - nums[#nums - 1]
            return nums[#nums] + diff
        end
    end

    -- DOUBLEHALF: ganda atau setengah
    if qType == "doublehalf" or mainText:find("double of") or mainText:find("half of") then
        local qt = tostring(data.questionText or mainText):lower()
        if qt:find("double of") then
            local n = qt:match("double of (%d+)")
            if n then return tonumber(n) * 2 end
        elseif qt:find("half of") then
            local n = qt:match("half of (%d+)")
            if n then return math.floor(tonumber(n) / 2) end
        end
    end

    -- SUBSTITUTION: substitusi variabel
    if qType == "substitution" or mainText:find("if .*what is") then
        local qt = NormalizeOp(tostring(data.questionText or mainText):lower())
        local map = {}
        for k, v in qt:gmatch("(%d+)%s*=%s*(%d+)") do map[tonumber(k)] = tonumber(v) end
        local expr = qt:match("what is%s*(.-)%s*%?")
        if expr and next(map) then
            expr = expr:gsub("and", ""):gsub("%s+", "")
            local a, op1, b, op2, c = expr:match("^(%d+)([%+%-%*/])(%d+)([%+%-%*/])(%d+)$")
            if a and b and c then
                local va = map[tonumber(a)] or tonumber(a)
                local vb = map[tonumber(b)] or tonumber(b)
                local vc = map[tonumber(c)] or tonumber(c)
                if (op1 == "*" or op1 == "/") and (op2 == "+" or op2 == "-") then
                    return doOp(doOp(va, vb, op1), vc, op2)
                elseif (op2 == "*" or op2 == "/") and (op1 == "+" or op1 == "-") then
                    return doOp(va, doOp(vb, vc, op2), op1)
                else
                    return doOp(doOp(va, vb, op1), vc, op2)
                end
            end
            local a2, op3, b2 = expr:match("^(%d+)([%+%-%*/])(%d+)$")
            if a2 and b2 then
                return doOp(map[tonumber(a2)] or tonumber(a2), map[tonumber(b2)] or tonumber(b2), op3)
            end
        end
    end

    -- =========================================================
    -- PRIORITAS 3: Render Server Eksplisit (Speed Mode / Visual)
    -- =========================================================
    if render.kind == "numerical_binary" then
        return doOp(tonumber(render.a), tonumber(render.b), tostring(render.op))
    end
    if tempId == "t3_squares" or tempId:find("square") then
        local n = render.n or render.a or render.base
        if not n then for _, v in pairs(render) do if type(v) == "number" then n = v break end end end
        if n then return n * n end
    end
    if tempId == "t6_cubes" or tempId:find("cube") then
        local n = render.n or render.a or render.base
        if not n then for _, v in pairs(render) do if type(v) == "number" then n = v break end end end
        if n then return n * n * n end
    end
    if tempId:find("triangle") or render.kind == "triangle" then
        return 180 - ((type(render.x) == "number" and render.x or 0)
                    + (type(render.y) == "number" and render.y or 0)
                    + (type(render.z) == "number" and render.z or 0))
    end

    -- =========================================================
    -- PRIORITAS 4: Fallback Text Parsing (Speed Mode)
    -- =========================================================

    -- Angka Romawi
    if tempId == "t5_roman_add_subtract" or tempId:find("roman") then
        if render.a and render.b and render.op then
            local n1, n2 = RomanToInt(tostring(render.a)), RomanToInt(tostring(render.b))
            if n1 and n2 then return doOp(n1, n2, tostring(render.op)) end
        end
    end
    if mainText:find("what number") then
        local romanMatch = mainText:match("what number is this%?%s*([ivxlcdm]+)")
            or mainText:match("what number is%s*([ivxlcdm]+)")
            or mainText:match("([ivxlcdm]+)[%p%s]*$")
        if romanMatch then return RomanToInt(romanMatch) end
    end
    local r1, opR, r2 = compactMath:match("([ivxlcdm]+)([%+%-%*/])([ivxlcdm]+)")
    if r1 and r2 then
        local n1, n2 = RomanToInt(r1), RomanToInt(r2)
        if n1 and n2 then return doOp(n1, n2, opR) end
    end

    -- Kuadrat ²
    local baseSq = compactMath:match("(%d+)%²")
    if baseSq then return tonumber(baseSq) * tonumber(baseSq) end

    -- Tiga angka (urutan operasi benar)
    local a1, op1a, b1, op2a, c1 = compactMath:match("(%d+)([%+%-%*/])(%d+)([%+%-%*/])(%d+)")
    if a1 and b1 and c1 then
        if (op1a == "*" or op1a == "/") and (op2a == "+" or op2a == "-") then
            return doOp(doOp(tonumber(a1), tonumber(b1), op1a), tonumber(c1), op2a)
        elseif (op2a == "*" or op2a == "/") and (op1a == "+" or op1a == "-") then
            return doOp(tonumber(a1), doOp(tonumber(b1), tonumber(c1), op2a), op1a)
        else
            return doOp(doOp(tonumber(a1), tonumber(b1), op1a), tonumber(c1), op2a)
        end
    end

    -- Kurung: (a op b) op c
    local a2, op3, b2, op4, c2 = compactMath:match("%((%d+)([%+%-%*/])(%d+)%)([%+%-%*/])(%d+)")
    if a2 and b2 and c2 then return doOp(doOp(tonumber(a2), tonumber(b2), op3), tonumber(c2), op4) end

    -- Dua angka murni
    local a3, op5, b3 = compactMath:match("^(%d+)([%+%-%*/])(%d+)$")
    if a3 and b3 then return doOp(tonumber(a3), tonumber(b3), op5) end

    -- Compare (speed prompt style)
    if normText:find("bigger:") or normText:find("larger:") then
        local nums = ExtractNumbers(mainText); if #nums >= 2 then return math.max(nums[1], nums[2]) end
    elseif normText:find("smaller:") then
        local nums = ExtractNumbers(mainText); if #nums >= 2 then return math.min(nums[1], nums[2]) end
    end

    -- Parity (speed prompt style)
    if normText:find("even:") or normText:find("which is even") then
        for _, n in ipairs(ExtractNumbers(mainText)) do if n % 2 == 0 then return n end end
    elseif normText:find("odd:") or normText:find("which is odd") then
        for _, n in ipairs(ExtractNumbers(mainText)) do if n % 2 ~= 0 then return n end end
    end

    -- Soal cerita fallback (speed mode, 2 angka)
    local nums = ExtractNumbers(mainText)
    if #nums == 2 then
        if normText:find("split") or normText:find("shared") or normText:find("how many each") then return nums[1] / nums[2] end
        if normText:find("windows") or normText:find("crayons each") or normText:find("per row")
            or normText:find("per hive") or normText:find("total seats") then return nums[1] * nums[2] end
        if normText:find("eats") or normText:find("left") or normText:find("remain") or normText:find("stay")
            or normText:find("borrowed") or normText:find("get off") or normText:find("sold")
            or normText:find("swim away") or normText:find("digs up") or normText:find("checked out")
            or normText:find("go home") then return nums[1] - nums[2] end
        if normText:find("more") or normText:find("hop on") or normText:find("picks") or normText:find("grow")
            or normText:find("finds") or normText:find("arrive") or normText:find("move in")
            or normText:find("gives her") or normText:find("how many now") then return nums[1] + nums[2] end
    elseif #nums == 3 then
        if normText:find("sold") and normText:find("got") and normText:find("more") then
            return nums[1] - nums[2] + nums[3]
        end
    end

    -- Utilitas
    if normText:find("reverse") and nums[1] then return tonumber(string.reverse(tostring(nums[1]))) end
    if normText:find("remainder") and #nums >= 2 then return nums[1] % nums[2] end
    if normText:find("sum of digits") and nums[1] then
        local sum = 0
        for i = 1, #tostring(nums[1]) do sum = sum + tonumber(string.sub(tostring(nums[1]), i, i)) end
        return sum
    end
    if normText:find("round") and #nums >= 2 then return math.floor(nums[1] / nums[2] + 0.5) * nums[2] end

    -- Area / Perimeter (visual)
    if normText:find("area") or normText:find("perimeter") then
        local geoNums = {}
        local function findNums(t)
            for _, v in pairs(t) do
                if type(v) == "number" then table.insert(geoNums, v)
                elseif type(v) == "string" and tonumber(v) then table.insert(geoNums, tonumber(v))
                elseif type(v) == "table" then findNums(v) end
            end
        end
        findNums(render)
        if #geoNums >= 2 then
            table.sort(geoNums, function(a, b) return a > b end)
            if normText:find("area") then return geoNums[1] * geoNums[2]
            else return 2 * (geoNums[1] + geoNums[2]) end
        end
    end

    -- Dadu
    if render.kind == "dice" and render.pips then
        local total = 0
        for _, pipsValue in pairs(render.pips) do total = total + tonumber(pipsValue) end
        return total
    end
    if render.images and (tempId:find("domino") or tempId:find("dice")) then
        local total = 0
        for _, img in pairs(render.images) do
            local n = img:match("%d+")
            if n then total = total + tonumber(n) end
        end
        return total
    end

    -- Object count
    if render.kind == "object_count" and render.images then
        local searchWords = {}
        for word in mainText:gmatch("%a+") do
            if word ~= "how" and word ~= "many" and word ~= "are" and word ~= "the" then
                if word:sub(-1) == "s" then word = word:sub(1, -2) end
                table.insert(searchWords, word)
            end
        end
        local count = 0
        for _, img in pairs(render.images) do
            local matchAll = true
            for _, w in pairs(searchWords) do if not string.lower(img):find(w) then matchAll = false break end end
            if matchAll then count = count + 1 end
        end
        return count
    end

    -- Total (fruit equation, dll)
    if normText:find("total") or tempId == "t3_fruit_equation" or normText:find("fruit") then
        local numsFruit = {}
        local total = 0
        local function extractVals(t)
            for _, v in pairs(t) do
                if type(v) == "number" then table.insert(numsFruit, v); total = total + v
                elseif type(v) == "string" and tonumber(v) then table.insert(numsFruit, tonumber(v)); total = total + tonumber(v)
                elseif type(v) == "table" then extractVals(v) end
            end
        end
        extractVals(render)
        if normText:find("fruit") and #numsFruit >= 2 then
            table.sort(numsFruit)
            return numsFruit[#numsFruit] - numsFruit[#numsFruit-1]
        elseif total > 0 then return total end
    end

    return nil
end

-- ==========================================================
-- [6] INTERCEPTOR & NOTIFIKASI
-- ==========================================================
local function FireAnswer(remote, rawData, delayTime, modeName)
    if type(rawData) ~= "table" then return end

    local success, answer = pcall(function() return ProcessAI(rawData) end)

    local qType = tostring(rawData.type or "")
    local deskripsiSoal = tostring(rawData.questionText or rawData.prompt or "")
    if deskripsiSoal == "" or deskripsiSoal == "nil" then
        deskripsiSoal = "Visual (" .. tostring(rawData.templateId or (rawData.render and rawData.render.kind) or qType or "Unknown") .. ")"
    end
    if #deskripsiSoal > 80 then deskripsiSoal = deskripsiSoal:sub(1, 77) .. "..." end

    if success and answer ~= nil then
        local finalAns = math.floor(tonumber(answer) + 0.5)
        Library:Notify({
            Title = "✅ [" .. (qType ~= "" and qType or "AI") .. "] " .. modeName,
            Content = "Soal: " .. deskripsiSoal .. "\n➔ Jawab: " .. tostring(finalAns),
            Type = "Success",
            Duration = 2
        })
        task.spawn(function()
            task.wait(delayTime)
            remote:FireServer(finalAns)
        end)
    else
        Library:Notify({
            Title = "⚠️ POLA BARU/GAGAL! [" .. (qType ~= "" and qType or "?") .. "]",
            Content = "AI Bingung: " .. deskripsiSoal .. "\nSilakan Screenshot & Report!",
            Type = "Error",
            Duration = 5
        })
    end
end

StartRound.OnClientEvent:Connect(function(...)
    if not _G.AutoMathNormal then return end
    FireAnswer(PlayerAnswer, ({...})[1], _G.DelayNormal, "Normal")
end)

SpeedRoundStart.OnClientEvent:Connect(function(...)
    if not _G.AutoMathSpeed then return end
    FireAnswer(SpeedPlayerAnswer, ({...})[1], _G.DelaySpeed, "Speed")
end)

Library:Notify({Title = "V23 Loaded ✅", Content = "Full Coverage: numeric/word/findX/compare/parity/sequence/doubleHalf/substitution aktif.", Type = "Info", Duration = 5})

