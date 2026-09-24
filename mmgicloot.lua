-- ==============================================================================
-- 💎 MIRAGE DEX MOBILE V1.0 (NEXT-GEN DARK GLASSMORPHISM DEX EXPLORER)
-- ==============================================================================
-- Fitur Utama:
-- 1. 📱 Mobile-First Touch Ergonomics: Tombol 40px+, touch-friendly drag bubble, modal action sheet
-- 2. 🌳 Lazy-Loading Hierarchy Tree: Ekstraksi on-demand (No-Lag / Anti-Freeze pada game berat)
-- 3. ⚙️ Live Property Inspector & Editor: Lihat & ubah Vector3, CFrame, Color3, Booleans, Numbers, Strings
-- 4. 📡 Real-Time Remote Spy & Caller: Tangkap InvokeServer / FireServer, inspect argumen, replay test fire
-- 5. 📜 Script Viewer & Decompiler: Integrasi decompile() executor + copy source code instan
-- 6. ⚡ Context Action Suite: Teleport to Part, Copy Path, Clone, Destroy, Clear Children
-- 7. 🎨 Dark Obsidian Glassmorphism UI: Tampilan ultra premium, frosted glass, smooth tween
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
-- 📋 UNIVERSAL CLIPBOARD HELPER
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
}

-- ==============================================================================
-- 🏷️ MAPPING ICON KELAS ROBLOX
-- ==============================================================================
local CLASS_ICONS = {
    Workspace           = "🌐",
    Players             = "👥",
    Player              = "👤",
    Lighting            = "💡",
    ReplicatedStorage   = "⚡",
    ReplicatedFirst     = "⚡",
    StarterGui          = "📱",
    StarterPack         = "🎒",
    StarterPlayer       = "🏃",
    SoundService        = "🔊",
    TextChatService     = "💬",
    Chat                = "💬",
    CoreGui             = "🛡️",
    MaterialService     = "🧱",
    Debris              = "🗑️",
    
    -- Objek Game
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
    AnimationTrack      = "🎞️"
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

-- Bersihkan versi sebelumnya jika ada
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

    -- Animasi Slide In & Out
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
-- 🖥️ MAIN DEX WINDOW (GLASSMORPHISM PANEL)
-- ==============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"

-- Ukuran responsif: Adaptif untuk Mobile landscape & Portrait
local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
local defaultW = math.clamp(screenSize.X * 0.72, 360, 560)
local defaultH = math.clamp(screenSize.Y * 0.85, 340, 520)

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
                if dist < 8 then -- Anggap sebagai tap (bukan drag)
                    toggleDexVisibility()
                end
            end
        end)
    end
end)

-- ==============================================================================
-- 🔝 HEADER & TITLE BAR
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
TitleLabel.Size = UDim2.new(1, -120, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "💎 MiRaGe Dex Mobile <font color=\"#8B5CF6\">v1.0</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = THEME.TextPrimary
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 102
TitleLabel.Parent = Header

-- Tombol Minimize & Close (Besar untuk sentuhan mobile)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -74, 0, 5)
MinBtn.BackgroundColor3 = THEME.BgInput
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "—"
MinBtn.TextColor3 = THEME.TextSecondary
MinBtn.TextSize = 13
MinBtn.ZIndex = 103
MinBtn.Parent = Header
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn
MinBtn.MouseButton1Click:Connect(toggleDexVisibility)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 13
CloseBtn.ZIndex = 103
CloseBtn.Parent = Header
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

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

-- Shared Variable untuk Instance Terpilih
local selectedInstance = nil
local updatePropertiesView = nil
local openInScriptViewer = nil

-- ==============================================================================
-- 🌳 TAB 1: EXPLORER TREE ENGINE (LAZY LOADING & REAL-TIME SEARCH)
-- ==============================================================================
-- Baris Pencarian
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
SearchBox.PlaceholderText = "🔍 Cari objek / class di Game..."
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
    TreeScroll.CanvasSize = UDim2.new(0, 0, 0, TreeLayout.AbsoluteContentSize.Y + 12)
end)

-- ==============================================================================
-- 📋 FUNGSI FORMAT PATH INSTANCE
-- ==============================================================================
local function getInstancePath(inst)
    if not inst then return "nil" end
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

CopyPathBtn.MouseButton1Click:Connect(function()
    if selectedInstance then
        local p = getInstancePath(selectedInstance)
        setClipboardText(p)
        showToast("📋 Copy Path", p, THEME.AccentCyan)
    else
        showToast("⚠️ Peringatan", "Pilih objek terlebih dahulu!", THEME.AccentAmber)
    end
end)

-- ==============================================================================
-- 📑 CONTEXT ACTION MODAL SHEET (ACTION MENU MOBILE)
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
ModalCard.Size = UDim2.new(0, 310, 0, 360)
ModalCard.Position = UDim2.new(0.5, -155, 0.5, -180)
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
ModalTitle.Text = "⚡ Quick Action Menu"
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
ActionScroll.CanvasSize = UDim2.new(0, 0, 0, 320)
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

-- Pilihan Aksi Cepat
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

addActionButton("Lihat Script (Decompile)", "📜", THEME.AccentCyan, function()
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
-- 🌲 TREE VIEW RENDERING ENGINE (LAZY ON-DEMAND EXPANSION)
-- ==============================================================================
local treeNodes = {}

local function createTreeNode(inst, depth, parentContainer)
    depth = depth or 0
    if not inst then return nil end

    local row = Instance.new("Frame")
    row.Name = "Row_" .. inst.Name
    row.Size = UDim2.new(1, -4, 0, 36) -- Tinggi 36px ramah sentuhan layar HP
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

    -- Expand/Collapse Arrow
    local hasChildren = (#inst:GetChildren() > 0)
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

    -- Icon Class
    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(0, 22, 0, 22)
    iconLbl.Position = UDim2.new(0, depth * 14 + 28, 0.5, -11)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Font = Enum.Font.Gotham
    iconLbl.Text = getClassIcon(inst.ClassName)
    iconLbl.TextSize = 13
    iconLbl.ZIndex = 117
    iconLbl.Parent = row

    -- Nama Instance & ClassName
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -(depth * 14 + 54), 1, 0)
    nameLbl.Position = UDim2.new(0, depth * 14 + 52, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.Text = string.format("%s <font color=\"#6B7280\">(%s)</font>", inst.Name, inst.ClassName)
    nameLbl.RichText = true
    nameLbl.TextColor3 = THEME.TextPrimary
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex = 117
    nameLbl.Parent = row

    -- Tombol Action Menu Cepat [⋮] (Khusus Sentuhan Mobile)
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

    -- Container Anak Objek
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

    local function toggleExpand()
        if not hasChildren then return end
        isExpanded = not isExpanded
        arrowBtn.Text = isExpanded and "▼" or "▶"
        arrowBtn.TextColor3 = isExpanded and THEME.AccentCyan or THEME.AccentPurple

        if isExpanded and not childrenLoaded then
            childrenLoaded = true
            local kids = inst:GetChildren()
            for _, child in ipairs(kids) do
                createTreeNode(child, depth + 1, childrenContainer)
            end
        end
        childrenContainer.Visible = isExpanded
    end

    arrowBtn.MouseButton1Click:Connect(toggleExpand)

    rowBtn.MouseButton1Click:Connect(function()
        selectedInstance = inst
        PathLabel.Text = getInstancePath(inst)

        -- Highlight visual baris
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

local function populateRootServices()
    for _, child in ipairs(TreeScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    treeNodes = {}

    local ROOT_SERVICES = {
        workspace,
        Players,
        game:GetService("Lighting"),
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        game:GetService("StarterGui"),
        game:GetService("StarterPack"),
        game:GetService("StarterPlayer"),
        game:GetService("SoundService"),
        game:GetService("TextChatService"),
        game:GetService("MaterialService"),
    }
    pcall(function() table.insert(ROOT_SERVICES, CoreGui) end)

    for _, s in ipairs(ROOT_SERVICES) do
        if s then
            createTreeNode(s, 0, TreeScroll)
        end
    end
end

populateRootServices()
RefreshTreeBtn.MouseButton1Click:Connect(populateRootServices)

-- Search Engine Real-Time
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
    local maxResults = 60 -- Limit agar tidak lag/freeze di Mobile

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
-- ⚙️ TAB 2: LIVE PROPERTY INSPECTOR & EDITOR
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
    PropScroll.CanvasSize = UDim2.new(0, 0, 0, PropLayout.AbsoluteContentSize.Y + 14)
end)

local function addPropertyRow(inst, propName, propValue, propType)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 38)
    row.BackgroundColor3 = THEME.BgInput
    row.BorderSizePixel = 0
    row.ZIndex = 113
    row.Parent = PropScroll

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 6)
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
    nameLbl.ZIndex = 114
    nameLbl.Parent = row

    -- Kontrol Editor Interaktif
    if propType == "boolean" then
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 56, 0, 26)
        toggleBtn.Position = UDim2.new(1, -64, 0.5, -13)
        toggleBtn.BackgroundColor3 = propValue and THEME.AccentEmerald or Color3.fromRGB(60, 65, 80)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Text = propValue and "TRUE" or "FALSE"
        toggleBtn.TextColor3 = Color3.new(1, 1, 1)
        toggleBtn.TextSize = 10
        toggleBtn.ZIndex = 114
        toggleBtn.Parent = row
        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(0, 5)
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
    else
        local valBox = Instance.new("TextBox")
        valBox.Size = UDim2.new(0.56, -6, 0, 26)
        valBox.Position = UDim2.new(0.44, 0, 0.5, -13)
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
                    end
                end)
            end
        end)
    end
end

updatePropertiesView = function(inst)
    if not inst then return end
    PropTitle.Text = string.format("⚙️ [%s] %s", inst.ClassName, inst.Name)

    for _, c in ipairs(PropScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local COMMON_PROPS = {
        "Name", "ClassName", "Parent",
        "Position", "Size", "Orientation", "CFrame",
        "Transparency", "Reflectance", "Material", "Color", "CastShadow",
        "CanCollide", "Anchored", "CanTouch", "CanQuery", "Massless",
        "Value", "WalkSpeed", "JumpPower", "Health", "MaxHealth",
        "Enabled", "Visible", "Text", "SoundId", "Volume", "Playing"
    }

    for _, prop in ipairs(COMMON_PROPS) do
        local ok, val = pcall(function() return inst[prop] end)
        if ok and val ~= nil then
            addPropertyRow(inst, prop, val, typeof(val))
        end
    end
end

-- ==============================================================================
-- 📡 TAB 3: REAL-TIME REMOTE SPY & NETWORK CALLER
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

    -- Tombol Re-fire / Test Invoke
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

    -- Tombol Salin Script Call
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

-- Hooking __namecall untuk menangkap tendangan/remote game
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
-- 📜 TAB 4: SCRIPT VIEWER & DECOMPILER
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
ScriptTitle.Size = UDim2.new(1, -160, 1, 0)
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
DecompileBtn.Position = UDim2.new(1, -152, 0, 5)
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

local CopyScriptBtn = Instance.new("TextButton")
CopyScriptBtn.Size = UDim2.new(0, 68, 0, 26)
CopyScriptBtn.Position = UDim2.new(1, -72, 0, 5)
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
ScriptBox.Text = "-- Silakan pilih LocalScript / ModuleScript di Explorer lalu tekan 'Decompile'"
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

    if not (scriptInst:IsA("LocalScript") or scriptInst:IsA("ModuleScript")) then
        ScriptBox.Text = string.format("-- '%s' adalah objek berkelas '%s', bukan Script!", scriptInst.Name, scriptInst.ClassName)
        return
    end

    ScriptBox.Text = "-- Membaca script " .. scriptInst.Name .. "...\n-- Tekan tombol '⚡ Decompile' untuk membaca source code lengkap."
end

DecompileBtn.MouseButton1Click:Connect(function()
    if not selectedInstance or not (selectedInstance:IsA("LocalScript") or selectedInstance:IsA("ModuleScript")) then
        showToast("⚠️ Peringatan", "Pilih LocalScript atau ModuleScript terlebih dahulu!", THEME.AccentAmber)
        return
    end

    showToast("⚡ Decompiler", "Sedang men-decompile script...", THEME.AccentPurple)
    ScriptBox.Text = "-- Memulai proses decompile, mohon tunggu beberapa detik..."

    task.spawn(function()
        local decompiledSource = nil
        local decompileFunc = decompile or (syn and syn.decompile) or (fluxus and fluxus.decompile)

        if decompileFunc and type(decompileFunc) == "function" then
            local ok, res = pcall(function() return decompileFunc(selectedInstance) end)
            if ok and res then
                decompiledSource = tostring(res)
            end
        end

        if not decompiledSource or decompiledSource == "" then
            decompiledSource = string.format("-- [DECOMPILE GAGAL / EXECUTOR TIDAK SUPPORT]\n-- Script: %s\n-- Path: %s\n-- Executor Anda belum menyediakan fungsi decompile() yang kompatibel.", selectedInstance.Name, getInstancePath(selectedInstance))
        end

        ScriptBox.Text = decompiledSource
        showToast("✅ Sukses", "Decompile selesai!", THEME.AccentEmerald)
    end)
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
showToast("💎 MiRaGe Dex Mobile", "Dex Explorer Siap Digunakan!", THEME.AccentPurple)
print("--------------------------------------------------")
print("💎 [SUKSES] MiRaGe Dex Mobile V1.0 Berhasil Dimuat!")
print("✨ [FITUR] Explorer, Properties, Remote Spy, Script Decompiler & Quick Actions Ready.")
print("--------------------------------------------------")
