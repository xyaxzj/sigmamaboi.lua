-- ==============================================================================
-- 💎 MIRAGE DEX MOBILE V2.2 (ULTIMATE RESIZABLE DARK GLASSMORPHISM DEX EXPLORER)
-- ==============================================================================
-- Changelog & Refinements (V2.0):
-- 1. 🗚 Resizable Window: Grip resize handle di pojok kanan bawah (drag untuk ubah ukuran bebas di HP & PC)
-- 2. ➖ Minimize Only (No Accident Close): Tombol [✕] diganti dengan [—] Minimize (aman dari kepencet tutup)
-- 3. 🌐 Full DataModel & Nil Instances: Menampilkan SELURUH game service, game:GetChildren(), serta 👻 Nil Instances (getnilinstances)
-- 4. ⚙️ Exhaustive Studio Property Grid: Inspeksi properti lengkap per kategori (Transform, Physics, Appearance, Identity, Values, Humanoid, Guis, Lights, dll.)
-- 5. 📜 Universal Multi-Tier Decompiler: Mendukung Delta, Codex, Fluxus, Wave, Synapse, Hydrogen, direct .Source, dan Constant Dumper Fallback
-- 6. 📡 Advanced Remote Spy & Replay: Intercept __namecall, inspect parameter, test Fire/Invoke, copy script call
-- 7. ⚡ Context Action Suite: Teleport, Copy Path, Clone, Destroy, Clear Children, Save Script to File
-- ==============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer
while not lp do
    task.wait(0.1)
    lp = Players.LocalPlayer
end

-- ==============================================================================
-- 📋 UNIVERSAL CLIPBOARD & FILE HELPER
-- ==============================================================================
local function setClipboardText(text)
    text = tostring(text or "")
    local success = false
    if setclipboard then
        pcall(function() setclipboard(text); success = true end)
    elseif toclipboard then
        pcall(function() toclipboard(text); success = true end)
    elseif syn and syn.write_clipboard then
        pcall(function() syn.write_clipboard(text); success = true end)
    elseif Clipboard and Clipboard.set then
        pcall(function() Clipboard.set(text); success = true end)
    end
    return success
end

local function saveScriptToFile(fileName, content)
    if writefile then
        pcall(function()
            writefile(fileName, content)
        end)
        return true
    end
    return false
end

-- ==============================================================================
-- 🎨 TEMA WARNA & DESIGN TOKENS (DARK GLASSMORPHISM)
-- ==============================================================================
local THEME = {
    BgMain          = Color3.fromRGB(15, 17, 26),
    BgCard          = Color3.fromRGB(22, 26, 40),
    BgCardHover     = Color3.fromRGB(30, 36, 56),
    BgInput         = Color3.fromRGB(18, 21, 32),
    BorderSubtle    = Color3.fromRGB(45, 53, 76),
    BorderFocus     = Color3.fromRGB(99, 102, 241),
    AccentPurple    = Color3.fromRGB(139, 92, 246),
    AccentCyan      = Color3.fromRGB(56, 189, 248),
    AccentEmerald   = Color3.fromRGB(52, 211, 153),
    AccentRose      = Color3.fromRGB(244, 63, 94),
    AccentAmber     = Color3.fromRGB(245, 158, 11),
    TextPrimary     = Color3.fromRGB(243, 244, 246),
    TextSecondary   = Color3.fromRGB(156, 163, 175),
    TextMuted       = Color3.fromRGB(100, 110, 130),
    SectionHeader   = Color3.fromRGB(35, 42, 65),
}

-- ==============================================================================
-- 🏷️ MAPPING ICON KELAS ROBLOX LENGKAP
-- ==============================================================================
local CLASS_ICONS = {
    DataModel           = "🌐",
    Workspace           = "🌍",
    Players             = "👥",
    Player              = "👤",
    Lighting            = "💡",
    ReplicatedStorage   = "⚡",
    ReplicatedFirst     = "⚡",
    ServerScriptService = "🛡️",
    ServerStorage       = "📦",
    StarterGui          = "📱",
    StarterPack         = "🎒",
    StarterPlayer       = "🏃",
    SoundService        = "🔊",
    TextChatService     = "💬",
    Chat                = "💬",
    CoreGui             = "🛡️",
    MaterialService     = "🧱",
    Debris              = "🗑️",
    Teams               = "🚩",
    Team                = "🏳️",
    TweenService        = "🎬",
    UserInputService    = "🎮",
    RunService          = "⚙️",
    TeleportService     = "🌀",
    CollectionService   = "🏷️",
    NilInstances        = "👻",
    
    -- Objek Game & Geometri
    Folder              = "📁",
    Model               = "📦",
    Part                = "🧱",
    MeshPart            = "💠",
    WedgePart           = "📐",
    TrussPart           = "🪜",
    SpawnLocation       = "🏁",
    Terrain             = "🏔️",
    Humanoid            = "❤️",
    HumanoidRootPart    = "⚓",
    Accessory           = "👒",
    Shirt               = "👕",
    Pants               = "👖",
    Tool                = "🗡️",
    Camera              = "📷",
    
    -- Script & Logic
    Script              = "📜",
    LocalScript         = "💻",
    ModuleScript        = "📦",
    RemoteEvent         = "📡",
    RemoteFunction      = "🔄",
    BindableEvent       = "🪢",
    BindableFunction    = "🔁",
    
    -- Visual & Lighting
    Decal               = "🖼️",
    Texture             = "🎨",
    ParticleEmitter     = "✨",
    PointLight          = "💡",
    SpotLight           = "🔦",
    SurfaceLight        = "💡",
    Beam                = "⚡",
    Trail               = "〰️",
    Highlight           = "🌟",
    Sky                 = "☁️",
    Atmosphere          = "🌫️",
    Clouds              = "☁️",
    
    -- UI
    ScreenGui           = "🖥️",
    Frame               = "⬜",
    TextLabel           = "🔤",
    TextButton          = "🔘",
    ImageLabel          = "🖼️",
    ImageButton         = "🔘",
    TextBox             = "⌨️",
    ScrollingFrame      = "📜",
    BillboardGui        = "🏷️",
    SurfaceGui          = "🪧",
    
    -- Values
    StringValue         = "🏷️",
    IntValue            = "🔢",
    NumberValue         = "🔢",
    BoolValue           = "🔘",
    ObjectValue         = "🔗",
    CFrameValue         = "🧭",
    Vector3Value        = "📐",
    Color3Value         = "🎨",
    
    -- Physics
    Weld                = "🔗",
    Motor6D             = "🦾",
    Attachment          = "📍",
    ClickDetector       = "👆",
    ProximityPrompt     = "⌨️",
    TouchTransmitter    = "⚡",
    Sound               = "🎵",
    Animation           = "🎬",
    AnimationTrack      = "🎞️",
    SpecialMesh         = "💠"
}

local function getClassIcon(className)
    return CLASS_ICONS[className] or "🔹"
end

-- ==============================================================================
-- 🛡️ GUI CONTAINER (CORE GUI / GET HUI / PLAYERGUID DEFENSIVE)
-- ==============================================================================
local guiParent = nil
pcall(function()
    if gethui then
        guiParent = gethui()
    elseif CoreGui then
        guiParent = CoreGui
    end
end)
if not guiParent then
    guiParent = lp:WaitForChild("PlayerGui")
end

local oldGui = guiParent:FindFirstChild("MiRaGeDexMobileGui")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MiRaGeDexMobileGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = guiParent

-- ==============================================================================
-- 🔔 SISTEM TOAST NOTIFIKASI
-- ==============================================================================
local ToastContainer = Instance.new("Frame")
ToastContainer.Name = "ToastContainer"
ToastContainer.Size = UDim2.new(0, 320, 0, 50)
ToastContainer.Position = UDim2.new(0.5, -160, 0, 15)
ToastContainer.BackgroundTransparency = 1
ToastContainer.ZIndex = 1000
ToastContainer.Parent = ScreenGui

local function showToast(title, message, color)
    color = color or THEME.AccentCyan
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 48)
    toast.Position = UDim2.new(0, 0, -1.2, 0)
    toast.BackgroundColor3 = THEME.BgCard
    toast.BorderSizePixel = 0
    toast.ZIndex = 1001
    toast.Parent = ToastContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.2
    stroke.Parent = toast

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -12)
    bar.Position = UDim2.new(0, 6, 0, 6)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.ZIndex = 1002
    bar.Parent = toast
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -24, 0, 18)
    titleLbl.Position = UDim2.new(0, 18, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = title
    titleLbl.TextColor3 = THEME.TextPrimary
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 1002
    titleLbl.Parent = toast

    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size = UDim2.new(1, -24, 0, 16)
    msgLbl.Position = UDim2.new(0, 18, 0, 24)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.Text = message
    msgLbl.TextColor3 = THEME.TextSecondary
    msgLbl.TextSize = 11
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextTruncate = Enum.TextTruncate.AtEnd
    msgLbl.ZIndex = 1002
    msgLbl.Parent = toast

    toast:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.35, true)
    task.delay(2.6, function()
        pcall(function()
            toast:TweenPosition(UDim2.new(0, 0, -1.5, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.3, true, function()
                toast:Destroy()
            end)
        end)
    end)
end

-- ==============================================================================
-- 📱 DRAG HELPER UNIVERSAL (TOUCH & MOUSE SUPPORT)
-- ==============================================================================
local function makeDraggable(dragHandle, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ==============================================================================
-- 🔮 FLOATING TOGGLE BUBBLE (MOBILE QUICK BUTTON)
-- ==============================================================================
local Bubble = Instance.new("Frame")
Bubble.Name = "FloatingBubble"
Bubble.Size = UDim2.new(0, 52, 0, 52)
Bubble.Position = UDim2.new(0, 20, 0.5, -26)
Bubble.BackgroundColor3 = THEME.BgCard
Bubble.BorderSizePixel = 0
Bubble.Active = true
Bubble.ZIndex = 500
Bubble.Parent = ScreenGui

local BubbleCorner = Instance.new("UICorner")
BubbleCorner.CornerRadius = UDim.new(1, 0)
BubbleCorner.Parent = Bubble

local BubbleStroke = Instance.new("UIStroke")
BubbleStroke.Color = THEME.AccentPurple
BubbleStroke.Thickness = 1.6
BubbleStroke.Parent = Bubble

local BubbleIcon = Instance.new("TextLabel")
BubbleIcon.Size = UDim2.new(1, 0, 1, 0)
BubbleIcon.BackgroundTransparency = 1
BubbleIcon.Font = Enum.Font.GothamBold
BubbleIcon.Text = "💎"
BubbleIcon.TextSize = 22
BubbleIcon.TextColor3 = THEME.TextPrimary
BubbleIcon.ZIndex = 501
BubbleIcon.Parent = Bubble

makeDraggable(Bubble, Bubble)

-- ==============================================================================
-- 🖥️ MAIN DEX WINDOW (GLASSMORPHISM RESIZABLE PANEL)
-- ==============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"

local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
local defaultW = math.clamp(screenSize.X * 0.75, 360, 620)
local defaultH = math.clamp(screenSize.Y * 0.82, 340, 540)

MainFrame.Size = UDim2.new(0, defaultW, 0, defaultH)
MainFrame.Position = UDim2.new(0.5, -defaultW / 2, 0.5, -defaultH / 2)
MainFrame.BackgroundColor3 = THEME.BgMain
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = false
MainFrame.ZIndex = 100
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = THEME.BorderSubtle
MainStroke.Thickness = 1.4
MainStroke.Parent = MainFrame

-- ==============================================================================
-- 🗚 RESIZABLE GRIP HANDLE (POJOK KANAN BAWAH)
-- ==============================================================================
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Name = "ResizeHandle"
ResizeHandle.Size = UDim2.new(0, 28, 0, 28)
ResizeHandle.Position = UDim2.new(1, -28, 1, -28)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.Font = Enum.Font.GothamBold
ResizeHandle.Text = "⋰"
ResizeHandle.TextColor3 = THEME.AccentCyan
ResizeHandle.TextSize = 16
ResizeHandle.ZIndex = 250
ResizeHandle.Parent = MainFrame

local isResizing = false
local resizeStartPos = Vector2.zero
local resizeStartSize = Vector2.zero

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        resizeStartPos = Vector2.new(input.Position.X, input.Position.Y)
        resizeStartSize = Vector2.new(MainFrame.AbsoluteSize.X, MainFrame.AbsoluteSize.Y)
        ResizeHandle.TextColor3 = THEME.AccentPurple

        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isResizing = false
                ResizeHandle.TextColor3 = THEME.AccentCyan
                conn:Disconnect()
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local deltaX = input.Position.X - resizeStartPos.X
        local deltaY = input.Position.Y - resizeStartPos.Y
        
        local camSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        local newW = math.clamp(resizeStartSize.X + deltaX, 320, camSize.X * 0.96)
        local newH = math.clamp(resizeStartSize.Y + deltaY, 260, camSize.Y * 0.95)

        MainFrame.Size = UDim2.new(0, newW, 0, newH)
    end
end)

-- Toggle Window via Bubble
local isDexOpen = true
local function toggleDexVisibility()
    isDexOpen = not isDexOpen
    MainFrame.Visible = isDexOpen
    if isDexOpen then
        BubbleStroke.Color = THEME.AccentPurple
        showToast("💎 MiRaGe Dex", "Dex Explorer Ditampilkan", THEME.AccentPurple)
    else
        BubbleStroke.Color = THEME.BorderSubtle
        showToast("💎 MiRaGe Dex", "Dex Diminimize (Tekan bubble untuk membuka)", THEME.TextSecondary)
    end
end

Bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local startPos = input.Position
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                conn:Disconnect()
                local dist = (input.Position - startPos).Magnitude
                if dist < 8 then
                    toggleDexVisibility()
                end
            end
        end)
    end
end)

-- ==============================================================================
-- 🔝 HEADER & TITLE BAR (HANYA TOMBOL MINIMIZE & MAXIMIZE - NO ACCIDENTAL CLOSE)
-- ==============================================================================
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = THEME.BgCard
Header.BorderSizePixel = 0
Header.ZIndex = 101
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

makeDraggable(Header, MainFrame)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "💎 MiRaGe Dex Mobile <font color=\"#8B5CF6\">v2.0</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = THEME.TextPrimary
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 102
TitleLabel.Parent = Header

-- Tombol Maximize/Compact & Minimize
local isMaximized = false
local savedPreMaxSize = MainFrame.Size
local savedPreMaxPos = MainFrame.Position

local MaxBtn = Instance.new("TextButton")
MaxBtn.Size = UDim2.new(0, 32, 0, 32)
MaxBtn.Position = UDim2.new(1, -74, 0, 5)
MaxBtn.BackgroundColor3 = THEME.BgInput
MaxBtn.Font = Enum.Font.GothamBold
MaxBtn.Text = "🗖"
MaxBtn.TextColor3 = THEME.AccentCyan
MaxBtn.TextSize = 13
MaxBtn.ZIndex = 103
MaxBtn.Parent = Header
local MaxCorner = Instance.new("UICorner")
MaxCorner.CornerRadius = UDim.new(0, 6)
MaxCorner.Parent = MaxBtn

MaxBtn.MouseButton1Click:Connect(function()
    isMaximized = not isMaximized
    if isMaximized then
        savedPreMaxSize = MainFrame.Size
        savedPreMaxPos = MainFrame.Position
        local camSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        MainFrame.Size = UDim2.new(0, camSize.X * 0.94, 0, camSize.Y * 0.92)
        MainFrame.Position = UDim2.new(0.5, -(camSize.X * 0.94) / 2, 0.5, -(camSize.Y * 0.92) / 2)
        MaxBtn.Text = "🗗"
    else
        MainFrame.Size = savedPreMaxSize
        MainFrame.Position = savedPreMaxPos
        MaxBtn.Text = "🗖"
    end
end)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -38, 0, 5)
MinBtn.BackgroundColor3 = THEME.AccentPurple
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.TextSize = 14
MinBtn.ZIndex = 103
MinBtn.Parent = Header
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn
MinBtn.MouseButton1Click:Connect(toggleDexVisibility)

-- ==============================================================================
-- 📑 TAB NAVIGATION BAR (4 TABS MOBILE ERGONOMIC)
-- ==============================================================================
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -16, 0, 36)
TabBar.Position = UDim2.new(0, 8, 0, 48)
TabBar.BackgroundColor3 = THEME.BgInput
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 105
TabBar.Parent = MainFrame

local TabBarCorner = Instance.new("UICorner")
TabBarCorner.CornerRadius = UDim.new(0, 8)
TabBarCorner.Parent = TabBar

local TabBarLayout = Instance.new("UIListLayout")
TabBarLayout.FillDirection = Enum.FillDirection.Horizontal
TabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabBarLayout.Padding = UDim.new(0, 4)
TabBarLayout.Parent = TabBar

local TabButtons = {}
local TabPanels = {}
local activeTab = "Explorer"

local function switchTab(tabName)
    activeTab = tabName
    for name, btn in pairs(TabButtons) do
        local isActive = (name == tabName)
        btn.BackgroundColor3 = isActive and THEME.AccentPurple or Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = isActive and 0 or 1
        btn.TextColor3 = isActive and Color3.new(1, 1, 1) or THEME.TextSecondary
    end
    for name, panel in pairs(TabPanels) do
        panel.Visible = (name == tabName)
    end
end

local TAB_DEFS = {
    { ID = "Explorer",   Name = "🌳 Explorer" },
    { ID = "Properties", Name = "⚙️ Properties" },
    { ID = "RemoteSpy",  Name = "📡 Remote Spy" },
    { ID = "ScriptView", Name = "📜 Script" },
}

for i, def in ipairs(TAB_DEFS) do
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_" .. def.ID
    btn.Size = UDim2.new(0.25, -3, 1, 0)
    btn.BackgroundTransparency = (def.ID == "Explorer") and 0 or 1
    btn.BackgroundColor3 = (def.ID == "Explorer") and THEME.AccentPurple or Color3.fromRGB(0, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.Text = def.Name
    btn.TextColor3 = (def.ID == "Explorer") and Color3.new(1, 1, 1) or THEME.TextSecondary
    btn.TextSize = 11
    btn.LayoutOrder = i
    btn.ZIndex = 106
    btn.Parent = TabBar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        switchTab(def.ID)
    end)
    TabButtons[def.ID] = btn
end

-- ==============================================================================
-- 📦 CONTAINER HALAMAN PANEL
-- ==============================================================================
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -16, 1, -92)
ContentContainer.Position = UDim2.new(0, 8, 0, 88)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 110
ContentContainer.Parent = MainFrame

local function createPanel(name)
    local f = Instance.new("Frame")
    f.Name = "Panel_" .. name
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Visible = (name == "Explorer")
    f.ZIndex = 111
    f.Parent = ContentContainer
    TabPanels[name] = f
    return f
end

local ExplorerPanel   = createPanel("Explorer")
local PropertiesPanel = createPanel("Properties")
local RemoteSpyPanel  = createPanel("RemoteSpy")
local ScriptPanel     = createPanel("ScriptView")

-- Shared Variables
local selectedInstance = nil
local updatePropertiesView = nil
local openInScriptViewer = nil

-- ==============================================================================
-- 📋 FUNGSI FORMAT PATH INSTANCE LENGKAP
-- ==============================================================================
local function getInstancePath(inst)
    if not inst then return "nil" end
    if inst == game then return "game" end
    local parts = {}
    local curr = inst
    while curr and curr ~= game do
        local name = curr.Name
        if string.find(name, "[^%w_]") then
            table.insert(parts, 1, string.format('["%s"]', name))
        else
            table.insert(parts, 1, (curr.Parent == game and "" or ".") .. name)
        end
        curr = curr.Parent
    end
    if inst.Parent == game then
        return string.format('game:GetService("%s")', inst.ClassName)
    end
    return "game" .. table.concat(parts, "")
end

-- ==============================================================================
-- 🌳 TAB 1: EXPLORER TREE ENGINE (FULL SERVICES, NIL INSTANCES & LAZY EXPANSION)
-- ==============================================================================
local SearchBarContainer = Instance.new("Frame")
SearchBarContainer.Size = UDim2.new(1, 0, 0, 36)
SearchBarContainer.Position = UDim2.new(0, 0, 0, 0)
SearchBarContainer.BackgroundColor3 = THEME.BgCard
SearchBarContainer.BorderSizePixel = 0
SearchBarContainer.ZIndex = 112
SearchBarContainer.Parent = ExplorerPanel

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchBarContainer

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = THEME.BorderSubtle
SearchStroke.Thickness = 1
SearchStroke.Parent = SearchBarContainer

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -70, 1, 0)
SearchBox.Position = UDim2.new(0, 10, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Font = Enum.Font.Gotham
SearchBox.PlaceholderText = "🔍 Cari objek / class di Game & Nil..."
SearchBox.PlaceholderColor3 = THEME.TextMuted
SearchBox.Text = ""
SearchBox.TextColor3 = THEME.TextPrimary
SearchBox.TextSize = 12
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 113
SearchBox.Parent = SearchBarContainer

local ClearSearchBtn = Instance.new("TextButton")
ClearSearchBtn.Size = UDim2.new(0, 26, 0, 26)
ClearSearchBtn.Position = UDim2.new(1, -62, 0, 5)
ClearSearchBtn.BackgroundColor3 = THEME.BgInput
ClearSearchBtn.Font = Enum.Font.GothamBold
ClearSearchBtn.Text = "✕"
ClearSearchBtn.TextColor3 = THEME.TextMuted
ClearSearchBtn.TextSize = 11
ClearSearchBtn.ZIndex = 114
ClearSearchBtn.Parent = SearchBarContainer
local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 4)
ClearCorner.Parent = ClearSearchBtn

local RefreshTreeBtn = Instance.new("TextButton")
RefreshTreeBtn.Size = UDim2.new(0, 26, 0, 26)
RefreshTreeBtn.Position = UDim2.new(1, -32, 0, 5)
RefreshTreeBtn.BackgroundColor3 = THEME.BgInput
RefreshTreeBtn.Font = Enum.Font.GothamBold
RefreshTreeBtn.Text = "🔄"
RefreshTreeBtn.TextColor3 = THEME.TextPrimary
RefreshTreeBtn.TextSize = 12
RefreshTreeBtn.ZIndex = 114
RefreshTreeBtn.Parent = SearchBarContainer
local RefCorner = Instance.new("UICorner")
RefCorner.CornerRadius = UDim.new(0, 4)
RefCorner.Parent = RefreshTreeBtn

-- Path Bar (Breadcrumb)
local PathBar = Instance.new("Frame")
PathBar.Size = UDim2.new(1, 0, 0, 26)
PathBar.Position = UDim2.new(0, 0, 0, 40)
PathBar.BackgroundColor3 = THEME.BgInput
PathBar.BorderSizePixel = 0
PathBar.ZIndex = 112
PathBar.Parent = ExplorerPanel

local PathCorner = Instance.new("UICorner")
PathCorner.CornerRadius = UDim.new(0, 6)
PathCorner.Parent = PathBar

local PathLabel = Instance.new("TextLabel")
PathLabel.Size = UDim2.new(1, -70, 1, 0)
PathLabel.Position = UDim2.new(0, 8, 0, 0)
PathLabel.BackgroundTransparency = 1
PathLabel.Font = Enum.Font.Code
PathLabel.Text = "📍 Belum ada objek terpilih"
PathLabel.TextColor3 = THEME.AccentCyan
PathLabel.TextSize = 10
PathLabel.TextXAlignment = Enum.TextXAlignment.Left
PathLabel.TextTruncate = Enum.TextTruncate.AtEnd
PathLabel.ZIndex = 113
PathLabel.Parent = PathBar

local CopyPathBtn = Instance.new("TextButton")
CopyPathBtn.Size = UDim2.new(0, 58, 0, 20)
CopyPathBtn.Position = UDim2.new(1, -62, 0, 3)
CopyPathBtn.BackgroundColor3 = THEME.BgCard
CopyPathBtn.Font = Enum.Font.GothamBold
CopyPathBtn.Text = "📋 Copy"
CopyPathBtn.TextColor3 = THEME.TextPrimary
CopyPathBtn.TextSize = 9
CopyPathBtn.ZIndex = 114
CopyPathBtn.Parent = PathBar
local CopyPathCorner = Instance.new("UICorner")
CopyPathCorner.CornerRadius = UDim.new(0, 4)
CopyPathCorner.Parent = CopyPathBtn

CopyPathBtn.MouseButton1Click:Connect(function()
    if selectedInstance then
        local p = getInstancePath(selectedInstance)
        setClipboardText(p)
        showToast("📋 Copy Path", p, THEME.AccentCyan)
    else
        showToast("⚠️ Peringatan", "Pilih objek terlebih dahulu!", THEME.AccentAmber)
    end
end)

-- Scrolling Container Tree View
local TreeScroll = Instance.new("ScrollingFrame")
TreeScroll.Size = UDim2.new(1, 0, 1, -72)
TreeScroll.Position = UDim2.new(0, 0, 0, 72)
TreeScroll.BackgroundColor3 = THEME.BgCard
TreeScroll.BorderSizePixel = 0
TreeScroll.ScrollBarThickness = 5
TreeScroll.ScrollBarImageColor3 = THEME.BorderSubtle
TreeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TreeScroll.ZIndex = 112
TreeScroll.Parent = ExplorerPanel

local TreeCorner = Instance.new("UICorner")
TreeCorner.CornerRadius = UDim.new(0, 8)
TreeCorner.Parent = TreeScroll

local TreeLayout = Instance.new("UIListLayout")
TreeLayout.SortOrder = Enum.SortOrder.LayoutOrder
TreeLayout.Padding = UDim.new(0, 2)
TreeLayout.Parent = TreeScroll

TreeLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TreeScroll.CanvasSize = UDim2.new(0, 0, 0, TreeLayout.AbsoluteContentSize.Y + 14)
end)

-- ==============================================================================
-- 📑 CONTEXT ACTION MODAL SHEET (BOTTOM SHEET MOBILE)
-- ==============================================================================
local ActionModal = Instance.new("Frame")
ActionModal.Name = "ActionModal"
ActionModal.Size = UDim2.new(1, 0, 1, 0)
ActionModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ActionModal.BackgroundTransparency = 0.45
ActionModal.Visible = false
ActionModal.ZIndex = 800
ActionModal.Parent = MainFrame

local ModalCard = Instance.new("Frame")
ModalCard.Size = UDim2.new(0, 310, 0, 380)
ModalCard.Position = UDim2.new(0.5, -155, 0.5, -190)
ModalCard.BackgroundColor3 = THEME.BgCard
ModalCard.BorderSizePixel = 0
ModalCard.ZIndex = 801
ModalCard.Parent = ActionModal

local ModalCorner = Instance.new("UICorner")
ModalCorner.CornerRadius = UDim.new(0, 12)
ModalCorner.Parent = ModalCard

local ModalStroke = Instance.new("UIStroke")
ModalStroke.Color = THEME.AccentPurple
ModalStroke.Thickness = 1.4
ModalStroke.Parent = ModalCard

local ModalTitle = Instance.new("TextLabel")
ModalTitle.Size = UDim2.new(1, -20, 0, 28)
ModalTitle.Position = UDim2.new(0, 12, 0, 8)
ModalTitle.BackgroundTransparency = 1
ModalTitle.Font = Enum.Font.GothamBold
ModalTitle.Text = "⚡ Context Action Menu"
ModalTitle.TextColor3 = THEME.TextPrimary
ModalTitle.TextSize = 13
ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
ModalTitle.ZIndex = 802
ModalTitle.Parent = ModalCard

local ModalSub = Instance.new("TextLabel")
ModalSub.Size = UDim2.new(1, -20, 0, 18)
ModalSub.Position = UDim2.new(0, 12, 0, 32)
ModalSub.BackgroundTransparency = 1
ModalSub.Font = Enum.Font.Code
ModalSub.Text = "Target: Part"
ModalSub.TextColor3 = THEME.AccentCyan
ModalSub.TextSize = 10
ModalSub.TextXAlignment = Enum.TextXAlignment.Left
ModalSub.TextTruncate = Enum.TextTruncate.AtEnd
ModalSub.ZIndex = 802
ModalSub.Parent = ModalCard

local ActionScroll = Instance.new("ScrollingFrame")
ActionScroll.Size = UDim2.new(1, -16, 1, -95)
ActionScroll.Position = UDim2.new(0, 8, 0, 56)
ActionScroll.BackgroundTransparency = 1
ActionScroll.ScrollBarThickness = 3
ActionScroll.ScrollBarImageColor3 = THEME.BorderSubtle
ActionScroll.CanvasSize = UDim2.new(0, 0, 0, 360)
ActionScroll.ZIndex = 802
ActionScroll.Parent = ModalCard

local ActionLayout = Instance.new("UIListLayout")
ActionLayout.SortOrder = Enum.SortOrder.LayoutOrder
ActionLayout.Padding = UDim.new(0, 4)
ActionLayout.Parent = ActionScroll

local ModalCloseBtn = Instance.new("TextButton")
ModalCloseBtn.Size = UDim2.new(1, -16, 0, 30)
ModalCloseBtn.Position = UDim2.new(0, 8, 1, -36)
ModalCloseBtn.BackgroundColor3 = THEME.BgInput
ModalCloseBtn.Font = Enum.Font.GothamBold
ModalCloseBtn.Text = "Tutup"
ModalCloseBtn.TextColor3 = THEME.TextSecondary
ModalCloseBtn.TextSize = 11
ModalCloseBtn.ZIndex = 803
ModalCloseBtn.Parent = ModalCard
local MCBCorner = Instance.new("UICorner")
MCBCorner.CornerRadius = UDim.new(0, 6)
MCBCorner.Parent = ModalCloseBtn
ModalCloseBtn.MouseButton1Click:Connect(function()
    ActionModal.Visible = false
end)

local function openActionModal(inst)
    if not inst then return end
    selectedInstance = inst
    PathLabel.Text = getInstancePath(inst)
    ModalSub.Text = string.format("[%s] %s", inst.ClassName, inst.Name)
    ActionModal.Visible = true
end

local function addActionButton(name, icon, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = THEME.BgInput
    btn.Font = Enum.Font.Gotham
    btn.Text = string.format("  %s  %s", icon, name)
    btn.TextColor3 = color or THEME.TextPrimary
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 803
    btn.Parent = ActionScroll

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        ActionModal.Visible = false
        pcall(callback)
    end)
end

addActionButton("Teleport Karakter ke Part", "🚀", THEME.AccentEmerald, function()
    if not selectedInstance then return end
    local pos = nil
    if selectedInstance:IsA("BasePart") then
        pos = selectedInstance.Position
    elseif selectedInstance:IsA("Model") then
        local cf = selectedInstance:GetPivot()
        pos = cf.Position
    end
    if pos then
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
            showToast("🚀 Teleport Sukses", "Karakter dipindahkan ke " .. selectedInstance.Name, THEME.AccentEmerald)
        end
    else
        showToast("⚠️ Gagal", "Objek tidak memiliki koordinat posisi fisik!", THEME.AccentRose)
    end
end)

addActionButton("Inspeksi Properties", "⚙️", THEME.AccentPurple, function()
    if selectedInstance and updatePropertiesView then
        switchTab("Properties")
        updatePropertiesView(selectedInstance)
    end
end)

addActionButton("Buka di Script Viewer", "📜", THEME.AccentCyan, function()
    if selectedInstance and openInScriptViewer then
        switchTab("ScriptView")
        openInScriptViewer(selectedInstance)
    end
end)

addActionButton("Salin Full Path", "📋", THEME.TextPrimary, function()
    if selectedInstance then
        local p = getInstancePath(selectedInstance)
        setClipboardText(p)
        showToast("📋 Copied", p, THEME.AccentCyan)
    end
end)

addActionButton("Salin Nama Objek", "🏷️", THEME.TextPrimary, function()
    if selectedInstance then
        setClipboardText(selectedInstance.Name)
        showToast("📋 Copied Name", selectedInstance.Name, THEME.TextPrimary)
    end
end)

addActionButton("Salin ClassName", "💠", THEME.TextPrimary, function()
    if selectedInstance then
        setClipboardText(selectedInstance.ClassName)
        showToast("📋 Copied Class", selectedInstance.ClassName, THEME.TextPrimary)
    end
end)

addActionButton("Duplikasi / Clone Objek", "📦", THEME.AccentAmber, function()
    if selectedInstance and selectedInstance.Archivable then
        pcall(function()
            local clone = selectedInstance:Clone()
            clone.Parent = selectedInstance.Parent
            showToast("📦 Berhasil Di-clone", clone.Name, THEME.AccentAmber)
        end)
    else
        showToast("⚠️ Gagal Clone", "Objek tidak dapat di-clone!", THEME.AccentRose)
    end
end)

addActionButton("Hapus Seluruh Anak (ClearChildren)", "🧹", THEME.AccentRose, function()
    if selectedInstance then
        pcall(function()
            selectedInstance:ClearAllChildren()
            showToast("🧹 Clear All Children", "Seluruh isi objek dihapus", THEME.AccentRose)
        end)
    end
end)

addActionButton("Musnahkan Objek (:Destroy())", "🗑️", Color3.fromRGB(239, 68, 68), function()
    if selectedInstance then
        local n = selectedInstance.Name
        pcall(function() selectedInstance:Destroy() end)
        showToast("🗑️ Objek Dimusnahkan", n .. " (:Destroy() berhasil)", THEME.AccentRose)
    end
end)

-- ==============================================================================
-- 🌲 TREE VIEW RENDERING ENGINE (LAZY ON-DEMAND EXPANSION & REAL-TIME UPDATES)
-- ==============================================================================
local treeNodes = {}

local function createTreeNode(inst, depth, parentContainer, customDisplayName, customIcon)
    depth = depth or 0
    if not inst then return nil end

    local row = Instance.new("Frame")
    row.Name = "Row_" .. (inst.Name or "Unnamed")
    row.Size = UDim2.new(1, -4, 0, 36)
    row.BackgroundColor3 = THEME.BgCard
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.ZIndex = 115
    row.Parent = parentContainer

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 5)
    rowCorner.Parent = row

    local rowBtn = Instance.new("TextButton")
    rowBtn.Size = UDim2.new(1, -38, 1, 0)
    rowBtn.Position = UDim2.new(0, 0, 0, 0)
    rowBtn.BackgroundTransparency = 1
    rowBtn.Text = ""
    rowBtn.ZIndex = 116
    rowBtn.Parent = row

    local hasChildren = false
    pcall(function()
        hasChildren = (#inst:GetChildren() > 0)
    end)

    local arrowBtn = Instance.new("TextButton")
    arrowBtn.Size = UDim2.new(0, 24, 0, 24)
    arrowBtn.Position = UDim2.new(0, depth * 14 + 4, 0.5, -12)
    arrowBtn.BackgroundTransparency = 1
    arrowBtn.Font = Enum.Font.GothamBold
    arrowBtn.Text = hasChildren and "▶" or "•"
    arrowBtn.TextColor3 = hasChildren and THEME.AccentPurple or THEME.TextMuted
    arrowBtn.TextSize = 11
    arrowBtn.ZIndex = 117
    arrowBtn.Parent = row

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(0, 22, 0, 22)
    iconLbl.Position = UDim2.new(0, depth * 14 + 28, 0.5, -11)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Font = Enum.Font.Gotham
    iconLbl.Text = customIcon or getClassIcon(inst.ClassName)
    iconLbl.TextSize = 13
    iconLbl.ZIndex = 117
    iconLbl.Parent = row

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -(depth * 14 + 54), 1, 0)
    nameLbl.Position = UDim2.new(0, depth * 14 + 52, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.Text = customDisplayName or string.format("%s <font color=\"#6B7280\">(%s)</font>", inst.Name, inst.ClassName)
    nameLbl.RichText = true
    nameLbl.TextColor3 = THEME.TextPrimary
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex = 117
    nameLbl.Parent = row

    local actBtn = Instance.new("TextButton")
    actBtn.Size = UDim2.new(0, 32, 0, 28)
    actBtn.Position = UDim2.new(1, -34, 0.5, -14)
    actBtn.BackgroundColor3 = THEME.BgInput
    actBtn.Font = Enum.Font.GothamBold
    actBtn.Text = "⋮"
    actBtn.TextColor3 = THEME.TextSecondary
    actBtn.TextSize = 14
    actBtn.ZIndex = 118
    actBtn.Parent = row
    local actCorner = Instance.new("UICorner")
    actCorner.CornerRadius = UDim.new(0, 4)
    actCorner.Parent = actBtn

    actBtn.MouseButton1Click:Connect(function()
        openActionModal(inst)
    end)

    local childrenContainer = Instance.new("Frame")
    childrenContainer.Name = "ChildrenOf_" .. inst.Name
    childrenContainer.Size = UDim2.new(1, 0, 0, 0)
    childrenContainer.BackgroundTransparency = 1
    childrenContainer.AutomaticSize = Enum.AutomaticSize.Y
    childrenContainer.Visible = false
    childrenContainer.ZIndex = 115
    childrenContainer.Parent = parentContainer

    local cLayout = Instance.new("UIListLayout")
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cLayout.Padding = UDim.new(0, 2)
    cLayout.Parent = childrenContainer

    local isExpanded = false
    local childrenLoaded = false

    local function loadChildNodes()
        for _, c in ipairs(childrenContainer:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local ok, kids = pcall(function() return inst:GetChildren() end)
        if ok and kids then
            for _, child in ipairs(kids) do
                createTreeNode(child, depth + 1, childrenContainer)
            end
        end
    end

    local function toggleExpand()
        isExpanded = not isExpanded
        arrowBtn.Text = isExpanded and "▼" or "▶"
        arrowBtn.TextColor3 = isExpanded and THEME.AccentCyan or THEME.AccentPurple

        if isExpanded then
            if not childrenLoaded then
                childrenLoaded = true
                loadChildNodes()
                
                -- Real-Time Child Listeners
                pcall(function()
                    inst.ChildAdded:Connect(function()
                        if isExpanded then loadChildNodes() end
                    end)
                    inst.ChildRemoved:Connect(function()
                        if isExpanded then loadChildNodes() end
                    end)
                end)
            end
        end
        childrenContainer.Visible = isExpanded
    end

    arrowBtn.MouseButton1Click:Connect(toggleExpand)

    rowBtn.MouseButton1Click:Connect(function()
        selectedInstance = inst
        PathLabel.Text = getInstancePath(inst)

        for _, otherRow in pairs(treeNodes) do
            if otherRow and otherRow.Parent then
                otherRow.BackgroundTransparency = 1
            end
        end
        row.BackgroundTransparency = 0.4
        row.BackgroundColor3 = THEME.AccentPurple

        if updatePropertiesView then
            updatePropertiesView(inst)
        end
    end)

    table.insert(treeNodes, row)
    return row
end

-- ==============================================================================
-- 🌐 POPULATE FULL ROBLOX SERVICES & NIL INSTANCES
-- ==============================================================================
local function populateRootServices()
    for _, child in ipairs(TreeScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    treeNodes = {}

    -- 1. Root DataModel (game)
    local rootRow = createTreeNode(game, 0, TreeScroll, "🌐 DataModel (game)", "🌐")

    -- 2. Daftar Service Lengkap (Termasuk yang hidden)
    local KNOWN_SERVICES = {
        "Workspace", "Players", "Lighting", "ReplicatedFirst", "ReplicatedStorage",
        "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack",
        "StarterPlayer", "Teams", "SoundService", "Chat", "TextChatService",
        "LocalizationService", "JointsService", "Debris", "TweenService",
        "MaterialService", "TestService", "CoreGui"
    }

    local renderedServices = {}

    -- Tambahkan yang sudah ada di game:GetChildren()
    for _, child in ipairs(game:GetChildren()) do
        renderedServices[child.ClassName] = true
        createTreeNode(child, 1, TreeScroll)
    end

    -- Tambahkan service resmi lainnya via game:GetService()
    for _, sName in ipairs(KNOWN_SERVICES) do
        if not renderedServices[sName] then
            pcall(function()
                local s = game:GetService(sName)
                if s then
                    renderedServices[sName] = true
                    createTreeNode(s, 1, TreeScroll)
                end
            end)
        end
    end

    -- 3. 👻 NIL INSTANCES (GETNILINSTANCES INTEGRATION)
    task.spawn(function()
        local getNilFunc = getnilinstances or (getgenv and getgenv().getnilinstances) or (syn and syn.get_nil_instances)
        if getNilFunc and type(getNilFunc) == "function" then
            local ok, nilList = pcall(getNilFunc)
            if ok and type(nilList) == "table" and #nilList > 0 then
                -- Buat virtual folder Nil Instances di Tree
                local nilRow = Instance.new("Frame")
                nilRow.Name = "Row_NilInstances"
                nilRow.Size = UDim2.new(1, -4, 0, 36)
                nilRow.BackgroundColor3 = THEME.BgCard
                nilRow.BackgroundTransparency = 1
                nilRow.ZIndex = 115
                nilRow.Parent = TreeScroll

                local nrCorner = Instance.new("UICorner")
                nrCorner.CornerRadius = UDim.new(0, 5)
                nrCorner.Parent = nilRow

                local nArrow = Instance.new("TextButton")
                nArrow.Size = UDim2.new(0, 24, 0, 24)
                nArrow.Position = UDim2.new(0, 18, 0.5, -12)
                nArrow.BackgroundTransparency = 1
                nArrow.Font = Enum.Font.GothamBold
                nArrow.Text = "▶"
                nArrow.TextColor3 = THEME.AccentEmerald
                nArrow.TextSize = 11
                nArrow.ZIndex = 117
                nArrow.Parent = nilRow

                local nIcon = Instance.new("TextLabel")
                nIcon.Size = UDim2.new(0, 22, 0, 22)
                nIcon.Position = UDim2.new(0, 42, 0.5, -11)
                nIcon.BackgroundTransparency = 1
                nIcon.Font = Enum.Font.Gotham
                nIcon.Text = "👻"
                nIcon.TextSize = 13
                nIcon.ZIndex = 117
                nIcon.Parent = nilRow

                local nName = Instance.new("TextLabel")
                nName.Size = UDim2.new(1, -70, 1, 0)
                nName.Position = UDim2.new(0, 68, 0, 0)
                nName.BackgroundTransparency = 1
                nName.Font = Enum.Font.GothamBold
                nName.Text = string.format("Nil Instances <font color=\"#10B981\">(%d Objek)</font>", #nilList)
                nName.RichText = true
                nName.TextColor3 = THEME.AccentEmerald
                nName.TextSize = 11
                nName.TextXAlignment = Enum.TextXAlignment.Left
                nName.ZIndex = 117
                nName.Parent = nilRow

                local nilContainer = Instance.new("Frame")
                nilContainer.Name = "NilChildrenContainer"
                nilContainer.Size = UDim2.new(1, 0, 0, 0)
                nilContainer.BackgroundTransparency = 1
                nilContainer.AutomaticSize = Enum.AutomaticSize.Y
                nilContainer.Visible = false
                nilContainer.ZIndex = 115
                nilContainer.Parent = TreeScroll

                local nilLayout = Instance.new("UIListLayout")
                nilLayout.SortOrder = Enum.SortOrder.LayoutOrder
                nilLayout.Padding = UDim.new(0, 2)
                nilLayout.Parent = nilContainer

                local nilExpanded = false
                nArrow.MouseButton1Click:Connect(function()
                    nilExpanded = not nilExpanded
                    nArrow.Text = nilExpanded and "▼" or "▶"
                    if nilExpanded and #nilContainer:GetChildren() <= 1 then
                        for _, nInst in ipairs(nilList) do
                            if typeof(nInst) == "Instance" then
                                createTreeNode(nInst, 2, nilContainer)
                            end
                        end
                    end
                    nilContainer.Visible = nilExpanded
                end)
            end
        end
    end)
end

populateRootServices()
RefreshTreeBtn.MouseButton1Click:Connect(populateRootServices)

-- Search Engine
local function executeSearch(query)
    query = string.lower(query or "")
    if query == "" then
        populateRootServices()
        return
    end

    for _, child in ipairs(TreeScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    treeNodes = {}

    local count = 0
    local maxResults = 80

    local function searchDescendants(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if count >= maxResults then return end
            local cName = string.lower(child.Name)
            local cClass = string.lower(child.ClassName)

            if string.find(cName, query, 1, true) or string.find(cClass, query, 1, true) then
                createTreeNode(child, 0, TreeScroll)
                count = count + 1
            end
            pcall(function() searchDescendants(child) end)
        end
    end

    searchDescendants(game)
    showToast("🔍 Hasil Pencarian", string.format("Ditemukan %d objek untuk '%s'", count, query), THEME.AccentCyan)
end

SearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed or SearchBox.Text ~= "" then
        executeSearch(SearchBox.Text)
    end
end)

ClearSearchBtn.MouseButton1Click:Connect(function()
    SearchBox.Text = ""
    populateRootServices()
end)

-- ==============================================================================
-- ⚙️ TAB 2: EXHAUSTIVE STUDIO PROPERTY INSPECTOR & LIVE EDITOR
-- ==============================================================================
local PropHeader = Instance.new("Frame")
PropHeader.Size = UDim2.new(1, 0, 0, 36)
PropHeader.BackgroundColor3 = THEME.BgCard
PropHeader.BorderSizePixel = 0
PropHeader.ZIndex = 112
PropHeader.Parent = PropertiesPanel

local PHCorner = Instance.new("UICorner")
PHCorner.CornerRadius = UDim.new(0, 8)
PHCorner.Parent = PropHeader

local PropTitle = Instance.new("TextLabel")
PropTitle.Size = UDim2.new(1, -16, 1, 0)
PropTitle.Position = UDim2.new(0, 10, 0, 0)
PropTitle.BackgroundTransparency = 1
PropTitle.Font = Enum.Font.GothamBold
PropTitle.Text = "⚙️ Properties: (Pilih objek di Explorer)"
PropTitle.TextColor3 = THEME.TextPrimary
PropTitle.TextSize = 12
PropTitle.TextXAlignment = Enum.TextXAlignment.Left
PropTitle.TextTruncate = Enum.TextTruncate.AtEnd
PropTitle.ZIndex = 113
PropTitle.Parent = PropHeader

local PropScroll = Instance.new("ScrollingFrame")
PropScroll.Size = UDim2.new(1, 0, 1, -44)
PropScroll.Position = UDim2.new(0, 0, 0, 44)
PropScroll.BackgroundColor3 = THEME.BgCard
PropScroll.BorderSizePixel = 0
PropScroll.ScrollBarThickness = 5
PropScroll.ScrollBarImageColor3 = THEME.BorderSubtle
PropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PropScroll.ZIndex = 112
PropScroll.Parent = PropertiesPanel

local PSCorner = Instance.new("UICorner")
PSCorner.CornerRadius = UDim.new(0, 8)
PSCorner.Parent = PropScroll

local PropLayout = Instance.new("UIListLayout")
PropLayout.SortOrder = Enum.SortOrder.LayoutOrder
PropLayout.Padding = UDim.new(0, 3)
PropLayout.Parent = PropScroll

PropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PropScroll.CanvasSize = UDim2.new(0, 0, 0, PropLayout.AbsoluteContentSize.Y + 16)
end)

local function addCategoryHeader(title)
    local cat = Instance.new("Frame")
    cat.Size = UDim2.new(1, -6, 0, 24)
    cat.BackgroundColor3 = THEME.SectionHeader
    cat.BorderSizePixel = 0
    cat.ZIndex = 113
    cat.Parent = PropScroll

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 4)
    cCorner.Parent = cat

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = title
    lbl.TextColor3 = THEME.AccentCyan
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 114
    lbl.Parent = cat
end

local function addPropertyRow(inst, propName, propValue, propType)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 36)
    row.BackgroundColor3 = THEME.BgInput
    row.BorderSizePixel = 0
    row.ZIndex = 113
    row.Parent = PropScroll

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 5)
    rCorner.Parent = row

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0.42, -6, 1, 0)
    nameLbl.Position = UDim2.new(0, 8, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.Text = propName
    nameLbl.TextColor3 = THEME.TextPrimary
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex = 114
    nameLbl.Parent = row

    -- Kontrol Editor Berdasarkan Tipe Data
    if propType == "boolean" then
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 56, 0, 24)
        toggleBtn.Position = UDim2.new(1, -62, 0.5, -12)
        toggleBtn.BackgroundColor3 = propValue and THEME.AccentEmerald or Color3.fromRGB(60, 65, 80)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Text = propValue and "TRUE" or "FALSE"
        toggleBtn.TextColor3 = Color3.new(1, 1, 1)
        toggleBtn.TextSize = 10
        toggleBtn.ZIndex = 114
        toggleBtn.Parent = row
        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(0, 4)
        tCorner.Parent = toggleBtn

        toggleBtn.MouseButton1Click:Connect(function()
            local newVal = not propValue
            local ok = pcall(function() inst[propName] = newVal end)
            if ok then
                propValue = newVal
                toggleBtn.BackgroundColor3 = propValue and THEME.AccentEmerald or Color3.fromRGB(60, 65, 80)
                toggleBtn.Text = propValue and "TRUE" or "FALSE"
                showToast("⚙️ Property", string.format("%s = %s", propName, tostring(newVal)), THEME.AccentEmerald)
            end
        end)
    elseif propType == "Color3" then
        local colorSwatch = Instance.new("Frame")
        colorSwatch.Size = UDim2.new(0, 24, 0, 24)
        colorSwatch.Position = UDim2.new(0.44, 0, 0.5, -12)
        colorSwatch.BackgroundColor3 = propValue
        colorSwatch.BorderSizePixel = 0
        colorSwatch.ZIndex = 114
        colorSwatch.Parent = row
        local csCorner = Instance.new("UICorner")
        csCorner.CornerRadius = UDim.new(0, 4)
        csCorner.Parent = colorSwatch

        local valBox = Instance.new("TextBox")
        valBox.Size = UDim2.new(0.56, -34, 0, 24)
        valBox.Position = UDim2.new(0.44, 30, 0.5, -12)
        valBox.BackgroundColor3 = THEME.BgCard
        valBox.Font = Enum.Font.Code
        valBox.Text = string.format("%d, %d, %d", math.floor(propValue.R*255), math.floor(propValue.G*255), math.floor(propValue.B*255))
        valBox.TextColor3 = THEME.AccentCyan
        valBox.TextSize = 10
        valBox.ClearTextOnFocus = false
        valBox.ZIndex = 114
        valBox.Parent = row
        local vbCorner = Instance.new("UICorner")
        vbCorner.CornerRadius = UDim.new(0, 4)
        vbCorner.Parent = valBox

        valBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local r, g, b = valBox.Text:match("(%d+)[,%s]+(%d+)[,%s]+(%d+)")
                if r and g and b then
                    local newCol = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
                    pcall(function() inst[propName] = newCol end)
                    colorSwatch.BackgroundColor3 = newCol
                end
            end
        end)
    else
        local valBox = Instance.new("TextBox")
        valBox.Size = UDim2.new(0.56, -6, 0, 24)
        valBox.Position = UDim2.new(0.44, 0, 0.5, -12)
        valBox.BackgroundColor3 = THEME.BgCard
        valBox.Font = Enum.Font.Code
        valBox.Text = tostring(propValue)
        valBox.TextColor3 = THEME.AccentCyan
        valBox.TextSize = 10
        valBox.ClearTextOnFocus = false
        valBox.ZIndex = 114
        valBox.Parent = row
        local vbCorner = Instance.new("UICorner")
        vbCorner.CornerRadius = UDim.new(0, 4)
        vbCorner.Parent = valBox

        valBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local txt = valBox.Text
                pcall(function()
                    if propType == "number" then
                        inst[propName] = tonumber(txt) or inst[propName]
                    elseif propType == "string" then
                        inst[propName] = txt
                    elseif propType == "Vector3" then
                        local x, y, z = txt:match("([%d%.%-]+)[,%s]+([%d%.%-]+)[,%s]+([%d%.%-]+)")
                        if x and y and z then
                            inst[propName] = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
                        end
                    end
                end)
            end
        end)
    end
end

-- Katalog Kategori Properti Komprehensif
local PROPERTY_CATEGORIES = {
    {
        Category = "▼ Identity",
        Props = { "Name", "ClassName", "Parent", "Archivable" }
    },
    {
        Category = "▼ Transform",
        Props = { "CFrame", "Position", "Orientation", "Size", "PivotOffset", "WorldPivot" }
    },
    {
        Category = "▼ Appearance",
        Props = { "Color", "BrickColor", "Material", "Transparency", "Reflectance", "CastShadow", "TextureID", "MeshId", "DoubleSided" }
    },
    {
        Category = "▼ Collision & Physics",
        Props = { "CanCollide", "Anchored", "CanTouch", "CanQuery", "Massless", "AssemblyLinearVelocity", "AssemblyAngularVelocity" }
    },
    {
        Category = "▼ Value & Variables",
        Props = { "Value", "Text", "TextColor3", "TextSize", "SoundId", "Volume", "PlaybackSpeed", "Playing", "Looped" }
    },
    {
        Category = "▼ Humanoid & Character",
        Props = { "Health", "MaxHealth", "WalkSpeed", "JumpPower", "JumpHeight", "HipHeight", "DisplayName", "AutoRotate", "Sit", "PlatformStand" }
    },
    {
        Category = "▼ GUI & Display",
        Props = { "Visible", "Active", "Enabled", "ZIndex", "DisplayOrder", "LayoutOrder", "BackgroundTransparency", "BackgroundColor3", "ClipsDescendants" }
    },
    {
        Category = "▼ Lights & Atmosphere",
        Props = { "Brightness", "Range", "Shadows", "ClockTime", "FogStart", "FogEnd", "Density", "Haze", "Glare" }
    },
    {
        Category = "▼ Interaction & Proximity",
        Props = { "ActionText", "ObjectText", "HoldDuration", "MaxActivationDistance", "RequiresLineOfSight", "ClickablePrompt" }
    }
}

updatePropertiesView = function(inst)
    if not inst then return end
    PropTitle.Text = string.format("⚙️ [%s] %s", inst.ClassName, inst.Name)

    for _, c in ipairs(PropScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local renderedProps = {}

    for _, cat in ipairs(PROPERTY_CATEGORIES) do
        local catItems = {}
        for _, prop in ipairs(cat.Props) do
            local ok, val = pcall(function() return inst[prop] end)
            if ok and val ~= nil and not renderedProps[prop] then
                renderedProps[prop] = true
                table.insert(catItems, { Name = prop, Value = val, Type = typeof(val) })
            end
        end

        if #catItems > 0 then
            addCategoryHeader(cat.Category)
            for _, item in ipairs(catItems) do
                addPropertyRow(inst, item.Name, item.Value, item.Type)
            end
        end
    end
end

-- ==============================================================================
-- 📡 TAB 3: REAL-TIME REMOTE SPY & REPLAY CALLER
-- ==============================================================================
local RemoteSpyLogs = {}
local isSpyPaused = false

local RSHeader = Instance.new("Frame")
RSHeader.Size = UDim2.new(1, 0, 0, 36)
RSHeader.BackgroundColor3 = THEME.BgCard
RSHeader.BorderSizePixel = 0
RSHeader.ZIndex = 112
RSHeader.Parent = RemoteSpyPanel

local RSHCorner = Instance.new("UICorner")
RSHCorner.CornerRadius = UDim.new(0, 8)
RSHCorner.Parent = RSHeader

local RSTitle = Instance.new("TextLabel")
RSTitle.Size = UDim2.new(1, -120, 1, 0)
RSTitle.Position = UDim2.new(0, 10, 0, 0)
RSTitle.BackgroundTransparency = 1
RSTitle.Font = Enum.Font.GothamBold
RSTitle.Text = "📡 Network Traffic Logger (Hooking Active)"
RSTitle.TextColor3 = THEME.TextPrimary
RSTitle.TextSize = 12
RSTitle.TextXAlignment = Enum.TextXAlignment.Left
RSTitle.ZIndex = 113
RSTitle.Parent = RSHeader

local ClearSpyBtn = Instance.new("TextButton")
ClearSpyBtn.Size = UDim2.new(0, 52, 0, 26)
ClearSpyBtn.Position = UDim2.new(1, -114, 0, 5)
ClearSpyBtn.BackgroundColor3 = THEME.BgInput
ClearSpyBtn.Font = Enum.Font.GothamBold
ClearSpyBtn.Text = "Clear"
ClearSpyBtn.TextColor3 = THEME.TextSecondary
ClearSpyBtn.TextSize = 10
ClearSpyBtn.ZIndex = 114
ClearSpyBtn.Parent = RSHeader
local CSBCorner = Instance.new("UICorner")
CSBCorner.CornerRadius = UDim.new(0, 5)
CSBCorner.Parent = ClearSpyBtn

local PauseSpyBtn = Instance.new("TextButton")
PauseSpyBtn.Size = UDim2.new(0, 52, 0, 26)
PauseSpyBtn.Position = UDim2.new(1, -58, 0, 5)
PauseSpyBtn.BackgroundColor3 = THEME.BgInput
PauseSpyBtn.Font = Enum.Font.GothamBold
PauseSpyBtn.Text = "Pause"
PauseSpyBtn.TextColor3 = THEME.AccentCyan
PauseSpyBtn.TextSize = 10
PauseSpyBtn.ZIndex = 114
PauseSpyBtn.Parent = RSHeader
local PSBCorner = Instance.new("UICorner")
PSBCorner.CornerRadius = UDim.new(0, 5)
PSBCorner.Parent = PauseSpyBtn

local SpyScroll = Instance.new("ScrollingFrame")
SpyScroll.Size = UDim2.new(1, 0, 1, -44)
SpyScroll.Position = UDim2.new(0, 0, 0, 44)
SpyScroll.BackgroundColor3 = THEME.BgCard
SpyScroll.BorderSizePixel = 0
SpyScroll.ScrollBarThickness = 5
SpyScroll.ScrollBarImageColor3 = THEME.BorderSubtle
SpyScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SpyScroll.ZIndex = 112
SpyScroll.Parent = RemoteSpyPanel

local SpyCorner = Instance.new("UICorner")
SpyCorner.CornerRadius = UDim.new(0, 8)
SpyCorner.Parent = SpyScroll

local SpyLayout = Instance.new("UIListLayout")
SpyLayout.SortOrder = Enum.SortOrder.LayoutOrder
SpyLayout.Padding = UDim.new(0, 3)
SpyLayout.Parent = SpyScroll

SpyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SpyScroll.CanvasSize = UDim2.new(0, 0, 0, SpyLayout.AbsoluteContentSize.Y + 12)
end)

local function serializeValue(val)
    local t = typeof(val)
    if t == "string" then
        return string.format("%q", val)
    elseif t == "Vector3" then
        return string.format("Vector3.new(%.2f, %.2f, %.2f)", val.X, val.Y, val.Z)
    elseif t == "CFrame" then
        return string.format("CFrame.new(%.2f, %.2f, %.2f)", val.Position.X, val.Position.Y, val.Position.Z)
    elseif t == "Instance" then
        return getInstancePath(val)
    elseif t == "table" then
        return "{...}"
    else
        return tostring(val)
    end
end

local function addRemoteLog(method, remoteInst, args)
    if isSpyPaused or not remoteInst then return end

    local timeStr = os.date("%X")
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 44)
    row.BackgroundColor3 = THEME.BgInput
    row.BorderSizePixel = 0
    row.ZIndex = 113
    row.Parent = SpyScroll

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 6)
    rCorner.Parent = row

    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(0, 64, 0, 18)
    tag.Position = UDim2.new(0, 6, 0, 5)
    tag.BackgroundColor3 = (method == "InvokeServer") and THEME.AccentPurple or THEME.AccentCyan
    tag.Font = Enum.Font.GothamBold
    tag.Text = (method == "InvokeServer") and "INVOKE" or "FIRE"
    tag.TextColor3 = Color3.new(1, 1, 1)
    tag.TextSize = 9
    tag.ZIndex = 114
    tag.Parent = row
    local tagCorner = Instance.new("UICorner")
    tagCorner.CornerRadius = UDim.new(0, 4)
    tagCorner.Parent = tag

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -170, 0, 18)
    titleLbl.Position = UDim2.new(0, 76, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = string.format("%s (%s)", remoteInst.Name, timeStr)
    titleLbl.TextColor3 = THEME.TextPrimary
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    titleLbl.ZIndex = 114
    titleLbl.Parent = row

    local argStrParts = {}
    for i, a in ipairs(args) do
        table.insert(argStrParts, string.format("#%d: %s", i, serializeValue(a)))
    end
    local argSummary = #argStrParts > 0 and table.concat(argStrParts, ", ") or "(No Arguments)"

    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(1, -90, 0, 16)
    subLbl.Position = UDim2.new(0, 6, 0, 24)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.Code
    subLbl.Text = argSummary
    subLbl.TextColor3 = THEME.TextMuted
    subLbl.TextSize = 9
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.TextTruncate = Enum.TextTruncate.AtEnd
    subLbl.ZIndex = 114
    subLbl.Parent = row

    local fireBtn = Instance.new("TextButton")
    fireBtn.Size = UDim2.new(0, 38, 0, 24)
    fireBtn.Position = UDim2.new(1, -84, 0.5, -12)
    fireBtn.BackgroundColor3 = THEME.AccentEmerald
    fireBtn.Font = Enum.Font.GothamBold
    fireBtn.Text = "⚡ Test"
    fireBtn.TextColor3 = Color3.new(1, 1, 1)
    fireBtn.TextSize = 9
    fireBtn.ZIndex = 115
    fireBtn.Parent = row
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 4)
    fCorner.Parent = fireBtn

    fireBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if remoteInst:IsA("RemoteFunction") then
                remoteInst:InvokeServer(unpack(args))
            elseif remoteInst:IsA("RemoteEvent") then
                remoteInst:FireServer(unpack(args))
            end
            showToast("⚡ Remote Fired", "Berhasil test eksekusi " .. remoteInst.Name, THEME.AccentEmerald)
        end)
    end)

    local copyCallBtn = Instance.new("TextButton")
    copyCallBtn.Size = UDim2.new(0, 38, 0, 24)
    copyCallBtn.Position = UDim2.new(1, -42, 0.5, -12)
    copyCallBtn.BackgroundColor3 = THEME.BgCard
    copyCallBtn.Font = Enum.Font.GothamBold
    copyCallBtn.Text = "📋 Code"
    copyCallBtn.TextColor3 = THEME.TextPrimary
    copyCallBtn.TextSize = 8
    copyCallBtn.ZIndex = 115
    copyCallBtn.Parent = row
    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 4)
    cCorner.Parent = copyCallBtn

    copyCallBtn.MouseButton1Click:Connect(function()
        local code = string.format("%s:%s(%s)", getInstancePath(remoteInst), method, table.concat(argStrParts, ", "))
        setClipboardText(code)
        showToast("📋 Code Copied", code, THEME.AccentCyan)
    end)

    table.insert(RemoteSpyLogs, row)
end

ClearSpyBtn.MouseButton1Click:Connect(function()
    for _, item in ipairs(RemoteSpyLogs) do
        if item and item.Parent then item:Destroy() end
    end
    RemoteSpyLogs = {}
end)

PauseSpyBtn.MouseButton1Click:Connect(function()
    isSpyPaused = not isSpyPaused
    PauseSpyBtn.Text = isSpyPaused and "Resume" or "Pause"
    PauseSpyBtn.TextColor3 = isSpyPaused and THEME.AccentRose or THEME.AccentCyan
end)

pcall(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if typeof(self) == "Instance" then
                if method == "FireServer" or method == "InvokeServer" then
                    local args = {...}
                    task.defer(function()
                        addRemoteLog(method, self, args)
                    end)
                end
            end
            return oldNamecall(self, ...)
        end))
    end
end)

-- ==============================================================================
-- 📜 TAB 4: UNIVERSAL SCRIPT VIEWER & MULTI-TIER DECOMPILER ENGINE
-- ==============================================================================
local ScriptHeader = Instance.new("Frame")
ScriptHeader.Size = UDim2.new(1, 0, 0, 36)
ScriptHeader.BackgroundColor3 = THEME.BgCard
ScriptHeader.BorderSizePixel = 0
ScriptHeader.ZIndex = 112
ScriptHeader.Parent = ScriptPanel

local SHCorner = Instance.new("UICorner")
SHCorner.CornerRadius = UDim.new(0, 8)
SHCorner.Parent = ScriptHeader

local ScriptTitle = Instance.new("TextLabel")
ScriptTitle.Size = UDim2.new(1, -220, 1, 0)
ScriptTitle.Position = UDim2.new(0, 10, 0, 0)
ScriptTitle.BackgroundTransparency = 1
ScriptTitle.Font = Enum.Font.GothamBold
ScriptTitle.Text = "📜 Script Viewer: (Pilih Script di Explorer)"
ScriptTitle.TextColor3 = THEME.TextPrimary
ScriptTitle.TextSize = 12
ScriptTitle.TextXAlignment = Enum.TextXAlignment.Left
ScriptTitle.TextTruncate = Enum.TextTruncate.AtEnd
ScriptTitle.ZIndex = 113
ScriptTitle.Parent = ScriptHeader

local DecompileBtn = Instance.new("TextButton")
DecompileBtn.Size = UDim2.new(0, 76, 0, 26)
DecompileBtn.Position = UDim2.new(1, -214, 0, 5)
DecompileBtn.BackgroundColor3 = THEME.AccentPurple
DecompileBtn.Font = Enum.Font.GothamBold
DecompileBtn.Text = "⚡ Decompile"
DecompileBtn.TextColor3 = Color3.new(1, 1, 1)
DecompileBtn.TextSize = 10
DecompileBtn.ZIndex = 114
DecompileBtn.Parent = ScriptHeader
local DBCorner = Instance.new("UICorner")
DBCorner.CornerRadius = UDim.new(0, 5)
DBCorner.Parent = DecompileBtn

local SaveFileBtn = Instance.new("TextButton")
SaveFileBtn.Size = UDim2.new(0, 64, 0, 26)
SaveFileBtn.Position = UDim2.new(1, -134, 0, 5)
SaveFileBtn.BackgroundColor3 = THEME.AccentEmerald
SaveFileBtn.Font = Enum.Font.GothamBold
SaveFileBtn.Text = "💾 Save"
SaveFileBtn.TextColor3 = Color3.new(1, 1, 1)
SaveFileBtn.TextSize = 10
SaveFileBtn.ZIndex = 114
SaveFileBtn.Parent = ScriptHeader
local SFBCorner = Instance.new("UICorner")
SFBCorner.CornerRadius = UDim.new(0, 5)
SFBCorner.Parent = SaveFileBtn

local CopyScriptBtn = Instance.new("TextButton")
CopyScriptBtn.Size = UDim2.new(0, 62, 0, 26)
CopyScriptBtn.Position = UDim2.new(1, -66, 0, 5)
CopyScriptBtn.BackgroundColor3 = THEME.BgInput
CopyScriptBtn.Font = Enum.Font.GothamBold
CopyScriptBtn.Text = "📋 Copy"
CopyScriptBtn.TextColor3 = THEME.TextPrimary
CopyScriptBtn.TextSize = 10
CopyScriptBtn.ZIndex = 114
CopyScriptBtn.Parent = ScriptHeader
local CSB2Corner = Instance.new("UICorner")
CSB2Corner.CornerRadius = UDim.new(0, 5)
CSB2Corner.Parent = CopyScriptBtn

local ScriptBox = Instance.new("TextBox")
ScriptBox.Size = UDim2.new(1, 0, 1, -44)
ScriptBox.Position = UDim2.new(0, 0, 0, 44)
ScriptBox.BackgroundColor3 = THEME.BgCard
ScriptBox.BorderSizePixel = 0
ScriptBox.Font = Enum.Font.Code
ScriptBox.Text = "-- Silakan pilih LocalScript / ModuleScript di Explorer lalu tekan '⚡ Decompile'"
ScriptBox.TextColor3 = THEME.TextPrimary
ScriptBox.TextSize = 11
ScriptBox.TextXAlignment = Enum.TextXAlignment.Left
ScriptBox.TextYAlignment = Enum.TextYAlignment.Top
ScriptBox.MultiLine = true
ScriptBox.ClearTextOnFocus = false
ScriptBox.ZIndex = 112
ScriptBox.Parent = ScriptPanel

local SBCorner = Instance.new("UICorner")
SBCorner.CornerRadius = UDim.new(0, 8)
SBCorner.Parent = ScriptBox

openInScriptViewer = function(scriptInst)
    if not scriptInst then return end
    selectedInstance = scriptInst
    ScriptTitle.Text = string.format("📜 [%s] %s", scriptInst.ClassName, scriptInst.Name)

    if not (scriptInst:IsA("LocalScript") or scriptInst:IsA("ModuleScript") or scriptInst:IsA("Script")) then
        ScriptBox.Text = string.format("-- '%s' adalah objek berkelas '%s', bukan Script!", scriptInst.Name, scriptInst.ClassName)
        return
    end

    -- Cek langsung apakah .Source bisa dibaca (100% Original Source Code)
    local okSource, rawSource = pcall(function() return scriptInst.Source end)
    if okSource and type(rawSource) == "string" and #rawSource > 0 then
        ScriptBox.Text = rawSource
        showToast("📜 Source Code", "Berhasil membaca source code asli!", THEME.AccentEmerald)
        return
    end

    ScriptBox.Text = "-- Membaca script " .. scriptInst.Name .. "...\n-- Tekan tombol '⚡ Decompile' untuk membaca source code lengkap."
end

-- ==============================================================================
-- 🔬 UNIVERSAL DECOMPILER ENGINE (DELTA, CODEX, LIME, FLUXUS, WAVE, SYNAPSE)
-- ==============================================================================
local function isActualErrorOutput(str)
    if not str or type(str) ~= "string" or #str == 0 then return true end
    local lower = string.lower(str)
    -- Hanya anggap error jika teks pendek dan diawali pesan kegagalan decompiler sistem
    if #str < 120 and (string.find(lower, "error") or string.find(lower, "failed") or string.find(lower, "disabled") or string.find(lower, "not implemented") or string.find(lower, "unsupported")) then
        return true
    end
    return false
end

local function executeUniversalDecompile(scriptInst)
    if not scriptInst then return nil, "No Script" end

    local diagReports = {}

    -- TIER 1: Direct .Source Property (Jika environment membuka akses source)
    local okSource, rawSource = pcall(function() return scriptInst.Source end)
    if okSource and type(rawSource) == "string" and #rawSource > 0 then
        return rawSource, "Direct Source Access"
    end
    table.insert(diagReports, string.format("• .Source Property: %s", okSource and (type(rawSource) == "string" and #rawSource > 0 and "Tersedia" or "Kosong") or "Terkunci / Restricted"))

    -- TIER 2: Deteksi Seluruh Global Decompiler Function
    local decompileAPIs = {
        { Name = "decompile", Func = decompile },
        { Name = "getgenv().decompile", Func = getgenv and getgenv().decompile },
        { Name = "syn.decompile", Func = syn and syn.decompile },
        { Name = "fluxus.decompile", Func = fluxus and fluxus.decompile },
        { Name = "getrenv().decompile", Func = getrenv and getrenv().decompile },
    }

    for _, api in ipairs(decompileAPIs) do
        if type(api.Func) == "function" then
            local ok, res = pcall(function() return api.Func(scriptInst) end)
            if ok and type(res) == "string" and #res > 0 and not isActualErrorOutput(res) then
                return res, api.Name
            else
                local errMsg = ok and (type(res) == "string" and res:sub(1, 100) or tostring(res)) or tostring(res)
                table.insert(diagReports, string.format("• %s: Fungsi Ada, namun gagal dipanggil (%s)", api.Name, errMsg))
            end

            -- Coba fallback parameter timeout / mode
            local ok2, res2 = pcall(function() return api.Func(scriptInst, 20) end)
            if ok2 and type(res2) == "string" and #res2 > 0 and not isActualErrorOutput(res2) then
                return res2, api.Name .. " (Timeout Mode)"
            end
        else
            table.insert(diagReports, string.format("• %s: Tidak Disediakan oleh Executor (nil)", api.Name))
        end
    end

    -- TIER 3: Disassembler Bytecode
    local bc = nil
    if getscriptbytecode then
        local okBc, bRes = pcall(function() return getscriptbytecode(scriptInst) end)
        if okBc and bRes then bc = bRes end
    end

    if disassemble and bc then
        local ok, disRes = pcall(function() return disassemble(bc) end)
        if ok and type(disRes) == "string" and #disRes > 0 then
            return disRes, "Bytecode Disassembler"
        end
    end

    -- TIER 4: Fallback Constant, String & Diagnostic Report
    local dumpParts = {
        string.format("-- ========================================================"),
        string.format("-- ⚠️ STATUS DECOMPILER PADA EXECUTOR SAAT INI"),
        string.format("-- Objek    : %s (%s)", scriptInst.Name, scriptInst.ClassName),
        string.format("-- Path     : %s", getInstancePath(scriptInst)),
        string.format("-- ========================================================"),
        string.format("-- ℹ️ PENTING TENTANG SKOR sUNC (100%% sUNC):"),
        string.format("-- Skor sUNC (senS' Unified Naming Convention) HANYA menguji"),
        string.format("-- fungsi dasar environment (hook, memory, files, crypt)."),
        string.format("-- Fitur 'decompile' BUKAN bagian dari tes sUNC! Banyak executor"),
        string.format("-- ber-skor 100%% sUNC namun server decompiler-nya belum aktif."),
        string.format(""),
        string.format("-- 🔍 HASIL DIAGNOSTIK API PADA EXECUTOR ANDA:"),
    }

    for _, d in ipairs(diagReports) do
        table.insert(dumpParts, "-- " .. d)
    end

    if bc then
        table.insert(dumpParts, "")
        table.insert(dumpParts, string.format("-- 📦 Bytecode Script Ditemukan: %d bytes (getscriptbytecode = OK)", #bc))
    end

    -- Ekstrak konstanta string via debug / getconstants jika tersedia
    local getConstantsFunc = debug and debug.getconstants or getconstants
    if getConstantsFunc and type(getConstantsFunc) == "function" then
        local okC, consts = pcall(function() return getConstantsFunc(scriptInst) end)
        if okC and type(consts) == "table" and #consts > 0 then
            table.insert(dumpParts, "")
            table.insert(dumpParts, "-- 🏷️ DAFTAR STRING & KONSTANTA YANG DITEMUKAN DI DALAM SCRIPT:")
            for idx, cVal in ipairs(consts) do
                table.insert(dumpParts, string.format("  [%d] = %s", idx, serializeValue(cVal)))
            end
        end
    end

    return table.concat(dumpParts, "\n"), "Diagnostic Metadata Dump"
end

DecompileBtn.MouseButton1Click:Connect(function()
    if not selectedInstance or not (selectedInstance:IsA("LocalScript") or selectedInstance:IsA("ModuleScript") or selectedInstance:IsA("Script")) then
        showToast("⚠️ Peringatan", "Pilih Script atau ModuleScript terlebih dahulu!", THEME.AccentAmber)
        return
    end

    showToast("⚡ Decompiler", "Sedang memproses decompile...", THEME.AccentPurple)
    ScriptBox.Text = "-- Memulai proses decompile, mohon tunggu beberapa detik..."

    task.spawn(function()
        local decompiledCode, methodUsed = executeUniversalDecompile(selectedInstance)
        if decompiledCode then
            ScriptBox.Text = string.format("-- [DECOMPILED VIA: %s]\n\n%s", methodUsed, decompiledCode)
            showToast("✅ Sukses", "Decompile selesai via " .. methodUsed, THEME.AccentEmerald)
        else
            ScriptBox.Text = "-- Gagal melakukan decompile pada script ini."
            showToast("❌ Gagal", "Script tidak dapat didecompile", THEME.AccentRose)
        end
    end)
end)

SaveFileBtn.MouseButton1Click:Connect(function()
    if ScriptBox.Text ~= "" and selectedInstance then
        local safeName = string.gsub(selectedInstance.Name, "[^%w_%-]", "_") .. ".lua"
        local ok = saveScriptToFile(safeName, ScriptBox.Text)
        if ok then
            showToast("💾 File Tersimpan", "Tersimpan sebagai " .. safeName, THEME.AccentEmerald)
        else
            showToast("⚠️ Gagal Simpan", "writefile() tidak tersedia di executor ini", THEME.AccentAmber)
        end
    end
end)

CopyScriptBtn.MouseButton1Click:Connect(function()
    if ScriptBox.Text ~= "" then
        setClipboardText(ScriptBox.Text)
        showToast("📋 Script Copied", "Source code disalin ke clipboard!", THEME.AccentCyan)
    end
end)

-- ==============================================================================
-- 🚀 READY INITIALIZATION
-- ==============================================================================
showToast("💎 MiRaGe Dex Mobile", "Dex v2.0 Siap Digunakan!", THEME.AccentPurple)
print("--------------------------------------------------")
print("💎 [SUKSES] MiRaGe Dex Mobile V2.0 Berhasil Dimuat!")
print("✨ [FITUR] Resizable Grip Handle, Minimize Only, Full Services, Nil Instances, Universal Decompiler Ready.")
print("--------------------------------------------------")
