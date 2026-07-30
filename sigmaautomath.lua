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
local StartVoting = MathEvents:WaitForChild("StartVoting")
local PlayerVote = MathEvents:WaitForChild("PlayerVote")
local ShowRoundResult = MathEvents:WaitForChild("ShowRoundResult")

_G.AutoMathNormal = false
_G.AutoMathSpeed = false
_G.DelayNormal = 1.0
_G.DelaySpeed = 0.3
_G.AutoObby = false
_G.ObbyDelay = 10.0
_G.GamepassSpoofed = false
_G.AntiAFK = true
local hookInitialized = false
local UIConsole
local lastQuestionText = ""

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
    if readfile and isfile and isfile("UI sigma.lua") then
        return loadstring(readfile("UI sigma.lua"))()
    end
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/xyaxzj/sigmamaboi.lua/refs/heads/main/NcHO.lua"))()
end)

if not successUI or type(Library) ~= "table" then return end

local Window = Library:CreateWindow({
    Name = "Math AI V23 (Full Coverage)",
    LogoText = "🧠",
    Footer = "v26",
    ConfigName = "MathV23"
})

-- ==========================================================
-- UNIVERSAL HUD & STATUS WIDGET SYSTEM
-- ==========================================================
local HUDToggle
local MathHUD = Window:CreateHUD({
    Title = "Math AI Status", 
    Width = 180, 
    Height = 90,
    OnClose = function()
        if HUDToggle then HUDToggle:Set(false) end
    end
})
local hudStatusLine = MathHUD:AddLine("🔴 Mode: Inactive")
local hudQuestionLine = MathHUD:AddLine("Question: None")
local hudAnswerLine = MathHUD:AddLine("Answer: --")

local function updateStatusHUD()
    if _G.AutoMathNormal and _G.AutoMathSpeed then
        hudStatusLine:SetText("🟢 Mode: Both Active")
        hudStatusLine:SetColor(Color3.fromRGB(0, 255, 120))
        Window:SetMinimizedText("Both Auto")
        Window:SetMinimizedGlow("Success")
    elseif _G.AutoMathNormal then
        hudStatusLine:SetText("🟢 Mode: Normal Active")
        hudStatusLine:SetColor(Color3.fromRGB(0, 255, 120))
        Window:SetMinimizedText("Normal Auto")
        Window:SetMinimizedGlow("Success")
    elseif _G.AutoMathSpeed then
        hudStatusLine:SetText("⚡ Mode: Speedrun Active")
        hudStatusLine:SetColor(Color3.fromRGB(255, 200, 50))
        Window:SetMinimizedText("Speed Auto")
        Window:SetMinimizedGlow("Warning")
    else
        hudStatusLine:SetText("🔴 Mode: Inactive")
        hudStatusLine:SetColor(Color3.fromRGB(150, 150, 150))
        Window:SetMinimizedText("Math Idle")
        Window:SetMinimizedGlow("TextDim")
    end
end

-- Initialize Minimized state status
Window:SetMinimizedText("Math Idle")
Window:SetMinimizedGlow("TextDim")

local MathTab = Window:MakeTab("📝")
local NormalSec = MathTab:AddSection("🧠 Mode Normal", true)
local SpeedSec = MathTab:AddSection("⚡ Mode Speed Run", true)
HUDToggle = NormalSec:AddToggle({Name = "📺 Show Status HUD", Default = true, Flag = "Tgl_MathHUD"}, function(state)
    MathHUD:SetVisible(state)
end)

NormalSec:AddToggle({Name = "✅ Auto Answer (Normal)", Default = false, Flag = "Tgl_Normal"}, function(state) 
    _G.AutoMathNormal = state 
    updateStatusHUD()
end)
NormalSec:AddInput({Name = "Jeda Jawab (Detik)", Placeholder = "1.0"}, function(txt) if tonumber(txt) then _G.DelayNormal = tonumber(txt) end end)

SpeedSec:AddToggle({Name = "⚡ Auto Answer (Speed)", Default = false, Flag = "Tgl_Speed"}, function(state) 
    _G.AutoMathSpeed = state 
    updateStatusHUD()
end)
SpeedSec:AddInput({Name = "Jeda Jawab (Detik)", Placeholder = "0.3"}, function(txt) if tonumber(txt) then _G.DelaySpeed = tonumber(txt) end end)

local voteConnection
SpeedSec:AddToggle({Name = "🗳️ Auto Vote Speedrun", Default = false, Flag = "Tgl_VoteSpeed"}, function(state)
    _G.AutoVoteSpeedrun = state
    if voteConnection then voteConnection:Disconnect() voteConnection = nil end
    if state then
        voteConnection = StartVoting.OnClientEvent:Connect(function(...)
            if not _G.AutoVoteSpeedrun then return end
            pcall(function()
                task.wait(0.5)
                PlayerVote:FireServer("Speedrun")
                task.wait(0.2)
                PlayerVote:FireServer("_submit")
            end)
        end)
    end
end)

local ExtraTab = Window:MakeTab("🛠️")
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
    
    if state then
        -- 1. Set atribut lokal pada Player & Character (Bypass client-side GetAttribute checks)
        local function applyAttributes(target)
            if not target then return end
            pcall(function()
                target:SetAttribute("VIP", true)
                target:SetAttribute("vip", true)
                target:SetAttribute("x2cash", true)
                target:SetAttribute("x2wins", true)
                target:SetAttribute("x2winstreak", true)
                target:SetAttribute("starterpack", true)
                target:SetAttribute("Pack1", true)
                target:SetAttribute("Pack2", true)
            end)
        end
        applyAttributes(LocalPlayer)
        applyAttributes(LocalPlayer.Character)
        
        local charConn = LocalPlayer.CharacterAdded:Connect(applyAttributes)
        
        -- 2. Modifikasi GameConfig jika ada di ReplicatedStorage
        pcall(function()
            local gc = ReplicatedStorage:FindFirstChild("GameConfig") or ReplicatedStorage:FindFirstChild("Gameconfig")
            if gc and gc:IsA("ModuleScript") then
                local config = require(gc)
                if type(config) == "table" then
                    -- Spoof getGamepassByKey / getGamepassById di modul
                    if type(config.getGamepassByKey) == "function" then
                        local oldByKey = config.getGamepassByKey
                        config.getGamepassByKey = function(self, key)
                            return {key = key, id = 1234567, effects = {}}
                        end
                    end
                    if type(config.getGamepassById) == "function" then
                        config.getGamepassById = function(self, id)
                            return {id = id, key = "spoofed", effects = {}}
                        end
                    end
                end
            end
        end)

        -- 3. Hook namecall & hookfunction
        if not hookInitialized then
            local successHook, err = pcall(function()
                -- Hook via hookfunction jika executor canggih
                if hookfunction then
                    local oldUserOwns = MarketplaceService.UserOwnsGamePassAsync
                    hookfunction(MarketplaceService.UserOwnsGamePassAsync, function(self, ...)
                        if _G.GamepassSpoofed then return true end
                        return oldUserOwns(self, ...)
                    end)
                    local oldPlayerOwns = MarketplaceService.PlayerOwnsAsset
                    hookfunction(MarketplaceService.PlayerOwnsAsset, function(self, ...)
                        if _G.GamepassSpoofed then return true end
                        return oldPlayerOwns(self, ...)
                    end)
                end
                
                -- Metamethod hook sebagai cadangan / untuk Remote
                local oldNamecall
                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
                    if _G.GamepassSpoofed and not checkcaller() then
                        if self == MarketplaceService and (method == "UserOwnsGamePassAsync" or method == "PlayerOwnsAsset") then
                            return true
                        end
                        if self == LocalPlayer and method == "GetAttribute" then
                            local attr = ...
                            if attr == "VIP" or attr == "vip" or attr == "x2cash" or attr == "x2wins" or attr == "x2winstreak" or attr == "starterpack" or attr == "Pack1" or attr == "Pack2" then
                                return true
                            end
                        end
                        if method == "InvokeServer" and (self.Name == "GamepassOwned" or self.Name == "GamepassSync") then
                            return true
                        end
                    end
                    return oldNamecall(self, ...)
                end)
            end)
            
            if successHook then
                hookInitialized = true
                Library:Notify({Title = "Hook Aktif", Content = "Bypass Gamepass & Atribut Aktif!", Type = "Success", Duration = 3})
            else
                -- Jika hookmetamethod & hookfunction gagal/tidak didukung, tetap beri notif bahwa atribut lokal dipasang
                Library:Notify({Title = "Atribut Diaktifkan", Content = "Bypass Atribut Aktif (Metamethod Hook tidak didukung).", Type = "Info", Duration = 3})
            end
        end
    end
end)
local LogTab = Window:MakeTab("📋")
local LogSec = LogTab:AddSection("Log Pertanyaan", true)
UIConsole = LogSec:AddConsole("Math AI Logs")

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

-- Menghitung jumlah faktor pembagi angka
local function countFactors(n)
    if not n or n < 1 then return 0 end
    local count = 0
    for i = 1, math.floor(math.sqrt(n)) do
        if n % i == 0 then
            if i * i == n then
                count = count + 1
            else
                count = count + 2
            end
        end
    end
    return count
end

-- Panjang huruf untuk representasi angka bahasa Inggris (1-10)
local NUMBER_WORD_LENGTHS = {
    [1] = 3, -- one
    [2] = 3, -- two
    [3] = 5, -- three
    [4] = 4, -- four
    [5] = 4, -- five
    [6] = 3, -- six
    [7] = 5, -- seven
    [8] = 5, -- eight
    [9] = 4, -- nine
    [10] = 3, -- ten
}


-- Trivia / Pengetahuan Umum (jawaban statis)
local TRIVIA_DB = {
    ["how many months in a year"]       = 12,
    ["months in a year"]                = 12,
    ["how many days in a week"]         = 7,
    ["days in a week"]                  = 7,
    ["how many days in a year"]         = 365,
    ["how many weeks in a year"]        = 52,
    ["how many seconds in a minute"]    = 60,
    ["how many minutes in an hour"]     = 60,
    ["how many hours in a day"]         = 24,
    ["how many hours in a week"]        = 168,
    ["how many sides does a triangle have"] = 3,
    ["sides does a triangle have"]      = 3,
    ["how many sides does a square have"]   = 4,
    ["sides does a square have"]        = 4,
    ["how many sides does a pentagon have"] = 5,
    ["sides does a pentagon have"]      = 5,
    ["how many sides does a hexagon have"]  = 6,
    ["sides does a hexagon have"]       = 6,
    ["how many sides does an octagon have"] = 8,
    ["sides does an octagon have"]      = 8,
    ["how many sides does a heptagon have"] = 7,
    ["how many sides does a decagon have"]  = 10,
    ["how many faces does a cube have"] = 6,
    ["faces does a cube have"]          = 6,
    ["how many edges does a cube have"] = 12,
    ["edges does a cube have"]          = 12,
    ["how many corners does a cube have"]   = 8,
    ["how many vertices does a cube have"]  = 8,
    ["how many degrees in a circle"]    = 360,
    ["degrees in a circle"]             = 360,
    ["how many degrees in a right angle"]   = 90,
    ["degrees in a right angle"]        = 90,
    ["how many degrees in a straight line"] = 180,
    ["degrees in a straight line"]      = 180,
    ["how many degrees in a triangle"]  = 180,
    ["sum of angles in a triangle"]     = 180,
    -- Shapes & Angles difficulty extras
    ["how many corners does a rectangle have"] = 4,
    ["how many corners does a square have"]    = 4,
    ["how many corners does a triangle have"]  = 3,
    ["how many corners does a pentagon have"]  = 5,
    ["how many corners does a hexagon have"]   = 6,
    ["how many right angles in a square"]      = 4,
    ["how many right angles in a rectangle"]   = 4,
    ["how many right angles in a triangle"]    = 1,
    ["how many lines of symmetry does a square have"]    = 4,
    ["how many lines of symmetry does a rectangle have"] = 2,
    ["how many lines of symmetry does a circle have"]    = 0,  -- infinite, but game likely says 0 or some fixed
    ["how many faces does a sphere have"]      = 1,
    ["how many faces does a cylinder have"]    = 3,
    ["how many faces does a cone have"]        = 2,
}

-- Peta nama bentuk → jumlah sisi/sudut
local SHAPE_SIDES = {
    triangle=3, square=4, rectangle=4, pentagon=5,
    hexagon=6, heptagon=7, octagon=8, nonagon=9, decagon=10,
    rhombus=4, parallelogram=4, trapezoid=4, trapezium=4,
    kite=4, diamond=4,
}

local DICE_ASSETS = {
    ["rbxassetid://135387362632078"] = 1,
    ["rbxassetid://131493678775999"] = 2,
    ["rbxassetid://110341390233609"] = 3,
    ["rbxassetid://80284591457100"]  = 4,
    ["rbxassetid://105892312794371"] = 5,
    ["rbxassetid://131239646519401"] = 6,
    ["dice_1"] = 1,
    ["dice_2"] = 2,
    ["dice_3"] = 3,
    ["dice_4"] = 4,
    ["dice_5"] = 5,
    ["dice_6"] = 6,
}

-- ==========================================================
-- [5] PERFECT AI ENGINE V26 (FULL PATTERN COVERAGE)
-- ==========================================================
local function ProcessAI(data)
    if type(data) ~= "table" then return nil end

    local render = data.render or {}
    local tempId = tostring(data.templateId or ""):lower()

    if data.answer ~= nil and type(data.answer) == "number" then
        return data.answer
    end

    local qType = tostring(data.type or ""):lower()
    local questionText = tostring(data.questionText or ""):lower()
    local prompt      = tostring(data.prompt or ""):lower()
    local mainText    = (questionText ~= "" and questionText) or prompt
    mainText = mainText:gsub("[\n\r]", " ")
    local normText  = NormalizeOp(mainText)
    local compactMath = normText:gsub("%s+", "")

    -- TRIVIA DB lookup (general knowledge questions)
    local cleanedMain = mainText:gsub("[%?%.%!]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if TRIVIA_DB[cleanedMain] then return TRIVIA_DB[cleanedMain] end

    local nums = ExtractNumbers(mainText)

    if mainText:find("approximately") then
        local normExpr = NormalizeOp(mainText)
        local expr = normExpr:match("approximately what is%s*(.-)%s*%(%s*1%s*%)")
        local actualVal = nil
        if expr then
            local a, op, b = expr:match("(%d+)%s*([%+%-%*/])%s*(%d+)")
            if a and b and op then
                actualVal = doOp(tonumber(a), tonumber(b), op)
            end
            if not actualVal then
                local n = expr:match("^%s*(%d+)%s*$")
                if n then actualVal = tonumber(n) end
            end
        end
        if actualVal then
            local options = {}
            for idx, val in mainText:gmatch("%((%d+)%)%s*(%d+)") do
                options[tonumber(idx)] = tonumber(val)
            end
            if next(options) then
                local bestIdx, bestDiff = nil, math.huge
                for idx, val in pairs(options) do
                    local diff = math.abs(val - actualVal)
                    if diff < bestDiff then
                        bestDiff = diff
                        bestIdx  = idx
                    end
                end
                if bestIdx then return bestIdx end
            end
        end
    end

    if mainText:find("what number") then
        local romanMatch = mainText:match("what number is this%?%s*([ivxlcdm]+)")
            or mainText:match("what number is%s*([ivxlcdm]+)")
            or mainText:match("([ivxlcdm]+)[%p%s]*$")
        if romanMatch then return RomanToInt(romanMatch) end
    end

    if mainText:find("is what percent of") then
        if #nums >= 2 then
            return math.floor(nums[1] / nums[2] * 100 + 0.5)
        end
    end
    if mainText:find("what is %d+%% of %d+") or mainText:find("%% of") then
        if #nums >= 2 then
            return math.floor(nums[1] * nums[2] / 100 + 0.5)
        end
    end

    if mainText:find("start at") then
        local startNum = tonumber(mainText:match("start at (%d+)"))
        if startNum then
            local current = startNum
            local stepsText = mainText:match("then%s*(.+)")
            if stepsText then
                for op, numStr in stepsText:gmatch("([%+%-%*/x÷×])%s*(%d+)") do
                    current = doOp(current, tonumber(numStr), op)
                end
                return current
            end
        end
    end

    if mainText:find("from %d+:%d+ to %d+:%d+") or (mainText:find("how many minutes") and mainText:find(":")) then
        local h1, m1, h2, m2 = mainText:match("(%d+):(%d+) to (%d+):(%d+)")
        if h1 and m1 and h2 and m2 then
            local t1 = tonumber(h1) * 60 + tonumber(m1)
            local t2 = tonumber(h2) * 60 + tonumber(m2)
            if t2 < t1 then t2 = t2 + 12 * 60 end
            if t2 < t1 then t2 = t2 + 12 * 60 end
            return t2 - t1
        end
    end

    if mainText:find("which is biggest") and mainText:find("%(1%)") then
        local e1 = mainText:match("%(1%)%s*([%d%+%-*x/÷×%s]+)")
        local e2 = mainText:match("%(2%)%s*([%d%+%-*x/÷×%s]+)")
        local e3 = mainText:match("%(3%)%s*([%d%+%-*x/÷×%s]+)")
        local function evalExpr(str)
            if not str then return -math.huge end
            str = str:gsub("%s+", "")
            local a, op, b = str:match("(%d+)([%+%-%*/x÷×])(%d+)")
            if a and b and op then
                return doOp(tonumber(a), tonumber(b), op) or -math.huge
            end
            return tonumber(str) or -math.huge
        end
        local v1 = evalExpr(e1)
        local v2 = evalExpr(e2)
        local v3 = evalExpr(e3)
        if v1 > v2 and v1 > v3 then return 1
        elseif v2 > v1 and v2 > v3 then return 2
        else return 3 end
    end

    if mainText:find("sort ascending") or mainText:find("sort descending") then
        local nthStr = mainText:match("what is the (%d+)") or mainText:match("what is the (%a+)")
        local nth = 1
        if nthStr then
            if nthStr:find("1") or nthStr == "first" or nthStr == "1st" then nth = 1
            elseif nthStr:find("2") or nthStr == "second" or nthStr == "2nd" then nth = 2
            elseif nthStr:find("3") or nthStr == "third" or nthStr == "3rd" then nth = 3
            elseif nthStr:find("4") or nthStr == "fourth" or nthStr == "4th" then nth = 4
            end
        end
        local list = {nums[1], nums[2], nums[3], nums[4]}
        if mainText:find("ascending") then
            table.sort(list)
        else
            table.sort(list, function(a,b) return a > b end)
        end
        return list[nth]
    end

    if mainText:find("temperature went from") or (mainText:find("went from") and mainText:find("rise")) then
        if #nums >= 2 then
            return math.abs(nums[2] - nums[1])
        end
    end

    if mainText:find("smallest multiple of %d+ above %d+") or (mainText:find("smallest multiple") and mainText:find("above")) then
        if #nums >= 2 then
            local mult = nums[1]
            local above = nums[2]
            return math.ceil((above + 1) / mult) * mult
        end
    end

    if mainText:find("how many factors does") then
        if nums[1] then return countFactors(nums[1]) end
    end

    if mainText:find("letters are in the word for") then
        if nums[1] and NUMBER_WORD_LENGTHS[nums[1]] then
            return NUMBER_WORD_LENGTHS[nums[1]]
        end
    end

    if tempId == "t3_fruit_equation" or render.kind == "fruits_substitution" then
        local tot = tonumber(render.total)
        local val = tonumber(render.knownValue)
        if tot and val then return tot - val end
    end

    if tempId == "t4_rectangle_area" and render.width and render.height then
        return tonumber(render.width) * tonumber(render.height)
    end
    if tempId == "t6_rectangle_perimeter" and render.width and render.height then
        return 2 * (tonumber(render.width) + tonumber(render.height))
    end

    if tempId == "t4_coin_total" or render.kind == "coins" then
        if render.coins then
            local sum = 0
            for _, coin in pairs(render.coins) do
                sum = sum + (tonumber(coin.value) or 0)
            end
            return sum
        end
    end

    if tempId == "t6_count_corners" and render.shape then
        return SHAPE_SIDES[render.shape] or 0
    end

    if qType == "numeric" then
        local a = tonumber(data.a)
        local b = tonumber(data.b)
        local op = tostring(data.operation or "")
        if a and b and op ~= "" then return doOp(a, b, op) end
    end

    if qType == "word" then
        local qt = tostring(data.questionText or mainText):lower()
        if #nums >= 2 then
            if qt:find("shared into groups of") or qt:find("shared into") or qt:find("groups of") or
               qt:find("split") or qt:find("shared") or qt:find("share") or qt:find("divided") or qt:find("how many each") then
                if nums[1] % nums[2] == 0 then
                    return nums[1] / nums[2]
                else
                    return nums[2] / nums[1]
                end
            end
            if (qt:find("start with") or qt:find("started with")) and (qt:find("sold") or qt:find("lost") or qt:find("gave")) then
                return nums[1] + nums[2]
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
            if (qt:find("eats") or qt:find("ate") or qt:find("lost") or qt:find("gave") or qt:find("sold")) and 
               (qt:find("buy") or qt:find("more") or qt:find("found") or qt:find("got")) then
                return nums[1] - nums[2] + nums[3]
            end
            if (qt:find("gave away") or qt:find("eats") or qt:find("ate") or qt:find("lost")) and 
               (qt:find("ate") or qt:find("eat") or qt:find("lost") or qt:find("gave")) then
                return nums[1] - nums[2] - nums[3]
            end
            if qt:find("sold") and qt:find("got") and qt:find("more") then return nums[1] - nums[2] + nums[3] end
        end
    end

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
    end

    if qType == "compare" then
        local opts = data.explicitOptions
        if opts and type(opts) == "table" and #opts >= 2 then
            if mainText:find("bigger") or mainText:find("larger") then return math.max(opts[1], opts[2]) end
            if mainText:find("smaller") then return math.min(opts[1], opts[2]) end
        end
        if #nums >= 2 then
            if mainText:find("bigger") or mainText:find("larger") or mainText:find("biggest") or mainText:find("largest") then return math.max(table.unpack(nums)) end
            if mainText:find("smaller") or mainText:find("smallest") then return math.min(table.unpack(nums)) end
        end
    end

    if qType == "parity" then
        local opts = data.explicitOptions
        if opts and type(opts) == "table" then
            if mainText:find("which is even") then
                for _, v in ipairs(opts) do if v % 2 == 0 then return v end end
            elseif mainText:find("which is odd") then
                for _, v in ipairs(opts) do if v % 2 ~= 0 then return v end end
            end
        end
        if mainText:find("which is even") then
            for _, n in ipairs(nums) do if n % 2 == 0 then return n end end
        elseif mainText:find("which is odd") then
            for _, n in ipairs(nums) do if n % 2 ~= 0 then return n end end
        end
    end

    if qType == "sequence" or mainText:find("what comes next") then
        if #nums >= 2 then
            if #nums >= 3 then
                local isFib = true
                for i=3, #nums do
                    if nums[i] ~= nums[i-1] + nums[i-2] then
                        isFib = false
                        break
                    end
                end
                if isFib then return nums[#nums] + nums[#nums-1] end
            end
            local diff = nums[#nums] - nums[#nums - 1]
            return nums[#nums] + diff
        end
    end

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

    if render.kind == "numerical_binary" then
        local a = tonumber(render.a)
        if a and render.aExp then a = a ^ tonumber(render.aExp) end
        if render.unary or not render.op or tostring(render.op) == "" or tostring(render.op) == "nil" then
            return a
        end
        local b = tonumber(render.b)
        if b and render.bExp then b = b ^ tonumber(render.bExp) end
        return doOp(a, b, tostring(render.op))
    end
    if render.sqrt or tempId == "t8_square_root" then
        local val = render.sqrt or render.a
        if not val then
            for _, v in pairs(render) do
                local nv = tonumber(v)
                if nv and nv > 0 then val = nv break end
            end
        end
        if val then return math.sqrt(tonumber(val)) end
    end
    if tempId == "t3_squares" or tempId:find("square") then
        local n = tonumber(render.n) or tonumber(render.a) or tonumber(render.base)
        if not n then
            for _, v in pairs(render) do
                local nv = tonumber(v)
                if nv and nv > 0 then n = nv break end
            end
        end
        if not n then
            local base = mainText:match("(%d+)%s*%^%s*2") or mainText:match("(%d+)%C2%B2") or mainText:match("(%d+)²")
            if base then n = tonumber(base) end
        end
        if n then return n * n end
    end
    if tempId == "t6_cubes" or tempId:find("cube") then
        local n = tonumber(render.n) or tonumber(render.a) or tonumber(render.base)
        if not n then
            for _, v in pairs(render) do
                local nv = tonumber(v)
                if nv and nv > 0 then n = nv break end
            end
        end
        if not n then
            local base = mainText:match("(%d+)%s*%^%s*3") or mainText:match("(%d+)%C2%B3") or mainText:match("(%d+)³")
            if base then n = tonumber(base) end
        end
        if n then return n * n * n end
    end
    if tempId:find("triangle") or render.kind == "triangle" then
        return 180 - ((type(render.x) == "number" and render.x or 0) + (type(render.y) == "number" and render.y or 0) + (type(render.z) == "number" and render.z or 0))
    end

    if tempId == "t5_roman_add_subtract" or tempId:find("roman") then
        if render.a and render.b and render.op then
            local n1, n2 = RomanToInt(tostring(render.a)), RomanToInt(tostring(render.b))
            if n1 and n2 then return doOp(n1, n2, tostring(render.op)) end
        end
    end
    local r1, opR, r2 = compactMath:match("([ivxlcdm]+)([%+%-%*/])([ivxlcdm]+)")
    if r1 and r2 then
        local n1, n2 = RomanToInt(r1), RomanToInt(r2)
        if n1 and n2 then return doOp(n1, n2, opR) end
    end

    local baseSq = compactMath:match("(%d+)%²") or compactMath:match("(%d+)%^2")
    if baseSq then return tonumber(baseSq) * tonumber(baseSq) end
    local baseCb = compactMath:match("(%d+)%³") or compactMath:match("(%d+)%^3")
    if baseCb then return tonumber(baseCb) * tonumber(baseCb) * tonumber(baseCb) end

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

    local a2, op3, b2, op4, c2 = compactMath:match("%((%d+)([%+%-%*/])(%d+)%)([%+%-%*/])(%d+)")
    if a2 and b2 and c2 then return doOp(doOp(tonumber(a2), tonumber(b2), op3), tonumber(c2), op4) end

    local a3, op5, b3 = compactMath:match("^(%d+)([%+%-%*/])(%d+)$")
    if a3 and b3 then return doOp(tonumber(a3), tonumber(b3), op5) end

    if normText:find("bigger") or normText:find("largest") or normText:find("biggest") then
        if #nums >= 2 then return math.max(table.unpack(nums)) end
    elseif normText:find("smaller") or normText:find("smallest") then
        if #nums >= 2 then return math.min(table.unpack(nums)) end
    end

    if normText:find("even:") or normText:find("which is even") then
        for _, n in ipairs(nums) do if n % 2 == 0 then return n end end
    elseif normText:find("odd:") or normText:find("which is odd") then
        for _, n in ipairs(nums) do if n % 2 ~= 0 then return n end end
    end

    if #nums == 2 then
        if normText:find("split") or normText:find("shared") or normText:find("share") or normText:find("divided") or normText:find("how many each") or normText:find("groups") then
            if nums[1] % nums[2] == 0 then
                return nums[1] / nums[2]
            else
                return nums[2] / nums[1]
            end
        end
        if normText:find("windows") or normText:find("crayons each") or normText:find("per row")
            or normText:find("per hive") or normText:find("total seats") then return nums[1] * nums[2] end
        if normText:find("eats") or normText:find("left") or (normText:find("remain") and not normText:find("remainder")) or normText:find("stay")
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

    if normText:find("reverse") and nums[1] then return tonumber(string.reverse(tostring(nums[1]))) end
    if normText:find("remainder") and #nums >= 2 then return nums[1] % nums[2] end
    if normText:find("sum of digits") and nums[1] then
        local sum = 0
        for i = 1, #tostring(nums[1]) do sum = sum + tonumber(string.sub(tostring(nums[1]), i, i)) end
        return sum
    end

    if tempId == "t2_how_many_digits" or (normText:find("how many digits") and normText:find("in")) then
        if nums[1] then return #tostring(nums[1]) end
    end

    if normText:find("round") then
        local dec = mainText:match("(%d+%.%d+)")
        if dec then
            return math.floor(tonumber(dec) + 0.5)
        end
        if #nums >= 2 then
            return math.floor(nums[1] / nums[2] + 0.5) * nums[2]
        end
    end

    if mainText:find("how many seconds in") and mainText:find("minute") then
        if nums[1] then return nums[1] * 60 end
    end
    if mainText:find("how many minutes in") and mainText:find("hour") then
        if nums[1] then return nums[1] * 60 end
    end
    if mainText:find("how many hours in") and mainText:find("day") then
        if nums[1] then return nums[1] * 24 end
    end
    if mainText:find("how many days in") and mainText:find("week") then
        if nums[1] then return nums[1] * 7 end
    end
    if mainText:find("how many months in") and mainText:find("year") then
        if nums[1] then return nums[1] * 12 end
    end
    if mainText:find("how many weeks in") and mainText:find("year") then
        if nums[1] then return nums[1] * 52 end
    end

    if mainText:find("how many corners") or mainText:find("how many sides") or
       mainText:find("how many vertices") or mainText:find("how many angles") then
        local sides = tonumber(render.sides) or tonumber(render.corners) or tonumber(render.vertices) or tonumber(render.n)
        if sides then return sides end
        local function checkShapeName(s)
            if not s then return nil end
            s = tostring(s):lower()
            for name, count in pairs(SHAPE_SIDES) do
                if s:find(name) then return count end
            end
            return nil
        end
        local found = checkShapeName(render.shape) or checkShapeName(render.type) or checkShapeName(render.kind) or checkShapeName(render.name) or checkShapeName(tempId)
        if found then return found end
        for name, count in pairs(SHAPE_SIDES) do
            if mainText:find(name) then return count end
        end
    end

    if tempId == "t6_pattern_completion" or render.kind == "pattern" then
        if render.items then
            local freq = {}
            for _, item in ipairs(render.items) do
                freq[item] = (freq[item] or 0) + 1
            end
            local outlier = nil
            for item, cnt in pairs(freq) do
                if cnt == 1 then
                    outlier = item
                    break
                end
            end
            if outlier then
                for idx, item in ipairs(render.items) do
                    if item == outlier then
                        return idx
                    end
                end
            end
        end
    end

    if mainText:find("breaks the pattern") or mainText:find("break the pattern") then
        local function collectNums(t, out)
            for _, v in pairs(t) do
                local nv = tonumber(v)
                if nv then table.insert(out, nv)
                elseif type(v) == "table" then collectNums(v, out) end
            end
        end
        local renderNums = {}
        collectNums(render, renderNums)
        if #renderNums >= 3 then
            local freq = {}
            for _, v in ipairs(renderNums) do freq[v] = (freq[v] or 0) + 1 end
            for val, cnt in pairs(freq) do
                if cnt == 1 then return val end
            end
        end
        if render.images then
            local freq = {}
            for _, img in pairs(render.images) do
                for name, _ in pairs(SHAPE_SIDES) do
                    if tostring(img):lower():find(name) then
                        freq[name] = (freq[name] or 0) + 1
                    end
                end
            end
            for shapeName, cnt in pairs(freq) do
                if cnt == 1 then return SHAPE_SIDES[shapeName] end
            end
        end
    end

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

    if render.kind == "dice" or tempId:find("dice") or tempId:find("dots") then
        if render.pips then
            local total = 0
            for _, pipsValue in pairs(render.pips) do
                local val = tonumber(pipsValue) or DICE_ASSETS[tostring(pipsValue)] or DICE_ASSETS[tostring(pipsValue):lower()]
                if val then total = total + val end
            end
            if total > 0 then return total end
        end
        if render.images then
            local total = 0
            for _, img in pairs(render.images) do
                local assetStr = tostring(img)
                local val = DICE_ASSETS[assetStr] or DICE_ASSETS[assetStr:lower()]
                if not val then
                    if not assetStr:find("rbxassetid://") then
                        local n = assetStr:match("%d+")
                        if n then val = tonumber(n) end
                    end
                end
                if val then total = total + val end
            end
            if total > 0 then return total end
        end
    end
    if render.images and (tempId:find("domino") or tempId:find("dice")) then
        local total = 0
        for _, img in pairs(render.images) do
            local assetStr = tostring(img)
            local val = DICE_ASSETS[assetStr] or DICE_ASSETS[assetStr:lower()]
            if not val then
                if not assetStr:find("rbxassetid://") then
                    local n = assetStr:match("%d+")
                    if n then val = tonumber(n) end
                end
            end
            if val then total = total + val end
        end
        if total > 0 then return total end
    end

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

    lastQuestionText = deskripsiSoal
    if hudQuestionLine then
        hudQuestionLine:SetText("Question: " .. deskripsiSoal)
    end

    if success then
        if answer ~= nil then
            local finalAns = math.floor(tonumber(answer) + 0.5)
            Library:Notify({
                Title = "✅ [" .. (qType ~= "" and qType or "AI") .. "] " .. modeName,
                Content = "Soal: " .. deskripsiSoal .. "\n➔ Jawab: " .. tostring(finalAns),
                Type = "Success",
                Duration = 2
            })
            if UIConsole then
                UIConsole:Log("[" .. modeName .. "] Soal: " .. deskripsiSoal .. " ➔ Jawab: " .. tostring(finalAns), "success")
            end
            if hudAnswerLine then
                hudAnswerLine:SetText("Answer: " .. tostring(finalAns) .. " (" .. modeName .. ")")
                hudAnswerLine:SetColor(Color3.fromRGB(0, 255, 120))
            end
            task.spawn(function()
                task.wait(delayTime)
                remote:FireServer(finalAns)
            end)
        else
            Library:Notify({
                Title = "⚠️ NIL ANSWER! [" .. (qType ~= "" and qType or "?") .. "]",
                Content = "ProcessAI mengembalikan nil untuk:\n" .. deskripsiSoal,
                Type = "Error",
                Duration = 5
            })
            if UIConsole then
                UIConsole:Log("[" .. modeName .. "] NIL ANSWER untuk: " .. deskripsiSoal, "warn")
            end
            if hudAnswerLine then
                hudAnswerLine:SetText("Answer: NIL ⚠️")
                hudAnswerLine:SetColor(Color3.fromRGB(255, 80, 80))
            end
        end
    else
        Library:Notify({
            Title = "❌ CRASH ERROR! [" .. (qType ~= "" and qType or "?") .. "]",
            Content = "Runtime Error: " .. tostring(answer) .. "\nSoal: " .. deskripsiSoal,
            Type = "Error",
            Duration = 7
        })
        if UIConsole then
            UIConsole:Log("[" .. modeName .. "] CRASH: " .. tostring(answer) .. " | Soal: " .. deskripsiSoal, "error")
        end
        if hudAnswerLine then
            hudAnswerLine:SetText("Answer: CRASH ❌")
            hudAnswerLine:SetColor(Color3.fromRGB(255, 80, 80))
        end
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

ShowRoundResult.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    if UIConsole then
        local myAns = data.myAnswer or "none"
        local oppAns = data.opponentAnswer or "none"
        local corrAns = data.correctAnswer or "none"
        local infoText = tostring(data.infoText or "")
        local outcome = "Round Result"
        local logType = "info"
        if data.myCorrect == true then
            outcome = "WON / CORRECT ✅"
            logType = "success"
        elseif data.myCorrect == false then
            outcome = "LOST / INCORRECT ❌"
            logType = "error"
        elseif data.isTie then
            outcome = "TIE ⚖️"
            logType = "warn"
        end
        local qText = lastQuestionText ~= "" and lastQuestionText or "Unknown"
        UIConsole:Log("📢 [" .. outcome .. "] Soal: " .. qText .. " | Jawab Saya: " .. tostring(myAns) .. " (Kunci: " .. tostring(corrAns) .. ") | Lawan: " .. tostring(oppAns) .. " | " .. infoText, logType)
    end
end)

Library:Notify({Title = "V26 Loaded ✅", Content = "Full Tiers 1-8 Coverage (V26 Perfect Engine) aktif.", Type = "Info", Duration = 5})
