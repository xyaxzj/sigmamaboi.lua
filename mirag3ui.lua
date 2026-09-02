--[[
    ========================================================================
                             MiRaGe HUB UI LIBRARY (v2.0)
                   The Next-Generation Modular Roblox Automation Suite
    ========================================================================
    Features:
      • Modern Void & Glassmorphism Aesthetic with Ambient Dynamic Gradients
      • Player Profile Headshot Card in Titlebar with Live Online Indicator
      • Minimize to Floating Circular Logo Bubble ("M") with Pulsing Glow Ring
      • Full Draggable Support (Main Window & Floating Bubble)
      • Multi-Theme Engine: Void Mirage, Cyberpunk Neon, Emerald Matrix, Crimson Red
      • Tab Navigation with Category Group Labels & Live Status Badges
      • Target Selector with Live Headshot Previews
      • Dual-Panel Console Logging (SENT & RECEIVED Streams with Timestamps)
      • Real-Time Session Net CPS Balance Tracker & Progress Bar
      • Rich Interactive Toast Notifications with Progress Timers
      • Fully Compatible with all major Roblox Executors
    ========================================================================
]]

local MiRaGe = {
    Version = "2.0.0",
    Flags = {},
    Themes = {},
    CurrentTheme = "VoidMirage",
    ActiveWindow = nil,
    FloatingBubble = nil,
    _themeCallbacks = {}
}

-- Core Services
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Safe Parent Resolver
local function getSafeGuiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, core = pcall(function() return CoreGui end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ══════════════════════════════════════════════════════════════════
-- THEME PALETTES
-- ══════════════════════════════════════════════════════════════════
MiRaGe.Themes = {
    VoidMirage = {
        Name        = "Void Mirage",
        Background  = Color3.fromRGB(8, 11, 18),
        Surface     = Color3.fromRGB(13, 17, 28),
        Card        = Color3.fromRGB(17, 24, 40),
        CardHover   = Color3.fromRGB(24, 34, 56),
        Input       = Color3.fromRGB(10, 14, 24),
        Border      = Color3.fromRGB(38, 55, 95),
        BorderGlow  = Color3.fromRGB(91, 138, 255),
        Accent      = Color3.fromRGB(91, 138, 255),
        Accent2     = Color3.fromRGB(168, 85, 247),
        Accent3     = Color3.fromRGB(6, 182, 212),
        Success     = Color3.fromRGB(34, 197, 94),
        Warning     = Color3.fromRGB(245, 158, 11),
        Danger      = Color3.fromRGB(239, 68, 68),
        Text        = Color3.fromRGB(248, 250, 252),
        TextSub     = Color3.fromRGB(148, 163, 184),
        TextDim     = Color3.fromRGB(71, 85, 105),
        Grad1       = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(91, 138, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212))
        })
    },
    Cyberpunk = {
        Name        = "Cyberpunk Neon",
        Background  = Color3.fromRGB(10, 8, 18),
        Surface     = Color3.fromRGB(18, 13, 30),
        Card        = Color3.fromRGB(28, 19, 48),
        CardHover   = Color3.fromRGB(42, 28, 70),
        Input       = Color3.fromRGB(14, 10, 24),
        Border      = Color3.fromRGB(70, 35, 110),
        BorderGlow  = Color3.fromRGB(236, 72, 153),
        Accent      = Color3.fromRGB(236, 72, 153),
        Accent2     = Color3.fromRGB(139, 92, 246),
        Accent3     = Color3.fromRGB(6, 182, 212),
        Success     = Color3.fromRGB(16, 185, 129),
        Warning     = Color3.fromRGB(251, 191, 36),
        Danger      = Color3.fromRGB(244, 63, 94),
        Text        = Color3.fromRGB(253, 244, 255),
        TextSub     = Color3.fromRGB(192, 132, 252),
        TextDim     = Color3.fromRGB(107, 70, 140),
        Grad1       = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(236, 72, 153)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(139, 92, 246)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212))
        })
    },
    EmeraldMatrix = {
        Name        = "Emerald Matrix",
        Background  = Color3.fromRGB(6, 14, 10),
        Surface     = Color3.fromRGB(10, 24, 18),
        Card        = Color3.fromRGB(16, 36, 26),
        CardHover   = Color3.fromRGB(24, 52, 38),
        Input       = Color3.fromRGB(8, 18, 13),
        Border      = Color3.fromRGB(25, 65, 45),
        BorderGlow  = Color3.fromRGB(16, 185, 129),
        Accent      = Color3.fromRGB(16, 185, 129),
        Accent2     = Color3.fromRGB(6, 182, 212),
        Accent3     = Color3.fromRGB(59, 130, 246),
        Success     = Color3.fromRGB(34, 197, 94),
        Warning     = Color3.fromRGB(245, 158, 11),
        Danger      = Color3.fromRGB(239, 68, 68),
        Text        = Color3.fromRGB(236, 253, 245),
        TextSub     = Color3.fromRGB(110, 231, 183),
        TextDim     = Color3.fromRGB(45, 110, 80),
        Grad1       = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 185, 129)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(6, 182, 212)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 130, 246))
        })
    },
    CrimsonRed = {
        Name        = "Crimson Red",
        Background  = Color3.fromRGB(16, 8, 10),
        Surface     = Color3.fromRGB(24, 11, 14),
        Card        = Color3.fromRGB(38, 17, 22),
        CardHover   = Color3.fromRGB(54, 24, 30),
        Input       = Color3.fromRGB(18, 9, 11),
        Border      = Color3.fromRGB(80, 28, 38),
        BorderGlow  = Color3.fromRGB(244, 63, 94),
        Accent      = Color3.fromRGB(244, 63, 94),
        Accent2     = Color3.fromRGB(225, 29, 72),
        Accent3     = Color3.fromRGB(251, 146, 60),
        Success     = Color3.fromRGB(34, 197, 94),
        Warning     = Color3.fromRGB(245, 158, 11),
        Danger      = Color3.fromRGB(239, 68, 68),
        Text        = Color3.fromRGB(255, 241, 242),
        TextSub     = Color3.fromRGB(253, 164, 175),
        TextDim     = Color3.fromRGB(140, 50, 65),
        Grad1       = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 29, 72)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(251, 146, 60))
        })
    }
}

local Theme = MiRaGe.Themes.VoidMirage

function MiRaGe:SetTheme(themeName)
    if MiRaGe.Themes[themeName] then
        MiRaGe.CurrentTheme = themeName
        Theme = MiRaGe.Themes[themeName]
        for _, cb in ipairs(MiRaGe._themeCallbacks) do
            pcall(cb, Theme)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- TWEEN & UTILITY HELPERS
-- ══════════════════════════════════════════════════════════════════
local function fastTween(instance, propTable, duration, style, dir)
    duration = duration or 0.22
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local tween = TweenService:Create(instance, TweenInfo.new(duration, style, dir), propTable)
    tween:Play()
    return tween
end

local function makeCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

local function makeStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.Parent = instance
    return stroke
end

local function makePadding(instance, top, bottom, left, right)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, top or 0)
    pad.PaddingBottom = UDim.new(0, bottom or 0)
    pad.PaddingLeft = UDim.new(0, left or 0)
    pad.PaddingRight = UDim.new(0, right or 0)
    pad.Parent = instance
    return pad
end

-- Enable full drag on any frame
local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
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
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- TOAST NOTIFICATION ENGINE
-- ══════════════════════════════════════════════════════════════════
local NotificationGui = nil
local ToastContainer = nil

local function getNotificationContainer()
    if ToastContainer and ToastContainer.Parent then return ToastContainer end

    NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "MiRaGe_Notifications"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.Parent = getSafeGuiParent()

    ToastContainer = Instance.new("Frame")
    ToastContainer.Name = "ToastContainer"
    ToastContainer.Size = UDim2.new(0, 320, 1, -40)
    ToastContainer.Position = UDim2.new(1, -340, 0, 20)
    ToastContainer.BackgroundTransparency = 1
    ToastContainer.Parent = NotificationGui

    local list = Instance.new("UIListLayout")
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.HorizontalAlignment = Enum.HorizontalAlignment.Right
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = ToastContainer

    return ToastContainer
end

function MiRaGe:Notify(options)
    local title = options.Title or "MiRaGe HUB"
    local content = options.Content or options.Text or ""
    local duration = options.Duration or 3.5
    local nType = options.Type or "Info" -- Info, Success, Warn, Danger

    local container = getNotificationContainer()

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 68)
    toast.BackgroundColor3 = Theme.Surface
    toast.BackgroundTransparency = 0.05
    toast.Position = UDim2.new(1, 100, 0, 0)
    toast.ClipsDescendants = true
    makeCorner(toast, 10)
    local stroke = makeStroke(toast, Theme.Border, 1)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 40, 65)),
        ColorSequenceKeypoint.new(1, Theme.Surface)
    })
    grad.Parent = toast

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 36, 0, 36)
    iconLabel.Position = UDim2.new(0, 12, 0, 12)
    iconLabel.BackgroundColor3 = Theme.Card
    iconLabel.Text = nType == "Success" and "✅" or (nType == "Warn" and "⚠️" or (nType == "Danger" and "❌" or "⚡"))
    iconLabel.TextSize = 16
    iconLabel.Parent = toast
    makeCorner(iconLabel, 8)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -62, 0, 18)
    titleLbl.Position = UDim2.new(0, 56, 0, 12)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.Text
    titleLbl.TextSize = 13
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = toast

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -62, 0, 28)
    descLbl.Position = UDim2.new(0, 56, 0, 30)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = content
    descLbl.TextColor3 = Theme.TextSub
    descLbl.TextSize = 11
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextWrapped = true
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.TextYAlignment = Enum.TextYAlignment.Top
    descLbl.Parent = toast

    local progressLine = Instance.new("Frame")
    progressLine.Size = UDim2.new(1, 0, 0, 2)
    progressLine.Position = UDim2.new(0, 0, 1, -2)
    progressLine.BackgroundColor3 = Theme.Accent
    progressLine.BorderSizePixel = 0
    progressLine.Parent = toast

    toast.Parent = container

    fastTween(toast, {Position = UDim2.new(0, 0, 0, 0)}, 0.35, Enum.EasingStyle.Back)
    fastTween(progressLine, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        fastTween(toast, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1}, 0.25)
        task.wait(0.26)
        toast:Destroy()
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- MASTER WINDOW CREATION
-- ══════════════════════════════════════════════════════════════════
function MiRaGe:CreateWindow(config)
    config = config or {}
    local hubTitle = config.Title or "MiRaGe HUB"
    local hubSubtitle = config.Subtitle or "Next-Gen Automation Suite"
    local keybind = config.Keybind or Enum.KeyCode.RightControl
    local defaultTheme = config.Theme or "VoidMirage"

    if MiRaGe.Themes[defaultTheme] then
        Theme = MiRaGe.Themes[defaultTheme]
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MiRaGe_Suite_v2"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = getSafeGuiParent()

    -- ──────────────────────────────────────────────────────────────
    -- 1. FLOATING CIRCULAR LOGO BUBBLE (SHOWN ON MINIMIZE)
    -- ──────────────────────────────────────────────────────────────
    local FloatingBubble = Instance.new("Frame")
    FloatingBubble.Name = "FloatingBubble"
    FloatingBubble.Size = UDim2.new(0, 58, 0, 58)
    FloatingBubble.Position = UDim2.new(1, -80, 1, -80)
    FloatingBubble.BackgroundColor3 = Theme.Surface
    FloatingBubble.Visible = false
    FloatingBubble.ZIndex = 500
    makeCorner(FloatingBubble, 29)
    local bubbleStroke = makeStroke(FloatingBubble, Theme.Accent, 2)

    local bubbleGrad = Instance.new("UIGradient")
    bubbleGrad.Color = Theme.Grad1
    bubbleGrad.Rotation = 45
    bubbleGrad.Parent = FloatingBubble

    -- Radar Pulsing Ring
    local pulseRing = Instance.new("Frame")
    pulseRing.Name = "PulseRing"
    pulseRing.Size = UDim2.new(1, 14, 1, 14)
    pulseRing.Position = UDim2.new(0, -7, 0, -7)
    pulseRing.BackgroundTransparency = 1
    makeCorner(pulseRing, 36)
    local pulseStroke = makeStroke(pulseRing, Theme.Accent, 2, 0.4)
    pulseRing.Parent = FloatingBubble

    -- Pulse Animation Loop
    task.spawn(function()
        while pulseRing.Parent do
            pulseRing.Size = UDim2.new(1, 0, 1, 0)
            pulseRing.Position = UDim2.new(0, 0, 0, 0)
            pulseStroke.Transparency = 0.2
            local tw = TweenService:Create(pulseRing, TweenInfo.new(1.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 24, 1, 24),
                Position = UDim2.new(0, -12, 0, -12)
            })
            local tw2 = TweenService:Create(pulseStroke, TweenInfo.new(1.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Transparency = 1
            })
            tw:Play()
            tw2:Play()
            task.wait(1.9)
        end
    end)

    local bubbleLetter = Instance.new("TextLabel")
    bubbleLetter.Size = UDim2.new(1, 0, 1, 0)
    bubbleLetter.BackgroundTransparency = 1
    bubbleLetter.Text = "M"
    bubbleLetter.TextColor3 = Color3.fromRGB(255, 255, 255)
    bubbleLetter.TextSize = 24
    bubbleLetter.Font = Enum.Font.GothamBlack
    bubbleLetter.ZIndex = 502
    bubbleLetter.Parent = FloatingBubble

    -- Queue Badge on Bubble
    local bubbleBadge = Instance.new("TextLabel")
    bubbleBadge.Name = "BubbleBadge"
    bubbleBadge.Size = UDim2.new(0, 22, 0, 18)
    bubbleBadge.Position = UDim2.new(1, -12, 0, -4)
    bubbleBadge.BackgroundColor3 = Theme.Success
    bubbleBadge.Text = "●"
    bubbleBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    bubbleBadge.TextSize = 10
    bubbleBadge.Font = Enum.Font.GothamBold
    bubbleBadge.ZIndex = 505
    makeCorner(bubbleBadge, 9)
    bubbleBadge.Parent = FloatingBubble

    FloatingBubble.Parent = ScreenGui
    makeDraggable(FloatingBubble)

    -- ──────────────────────────────────────────────────────────────
    -- 2. MAIN WINDOW CONTAINER
    -- ──────────────────────────────────────────────────────────────
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 820, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -410, 0.5, -260)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 10
    makeCorner(MainFrame, 14)
    local mainStroke = makeStroke(MainFrame, Theme.Border, 1.5)

    MainFrame.Parent = ScreenGui
    makeDraggable(MainFrame)

    -- Window Restore & Minimize Functions
    local isMinimized = false
    local function minimizeWindow()
        isMinimized = true
        fastTween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = FloatingBubble.Position}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(0.26)
        MainFrame.Visible = false
        FloatingBubble.Visible = true
        FloatingBubble.Size = UDim2.new(0, 0, 0, 0)
        fastTween(FloatingBubble, {Size = UDim2.new(0, 58, 0, 58)}, 0.35, Enum.EasingStyle.Back)
        MiRaGe:Notify({Title = "MiRaGe HUB", Content = "Minimized to floating bubble! Click it anytime to reopen.", Duration = 2.5})
    end

    local function restoreWindow()
        isMinimized = false
        FloatingBubble.Visible = false
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        fastTween(MainFrame, {
            Size = UDim2.new(0, 820, 0, 520),
            Position = UDim2.new(0.5, -410, 0.5, -260)
        }, 0.35, Enum.EasingStyle.Back)
    end

    -- Floating bubble click to restore
    local bubbleButton = Instance.new("TextButton")
    bubbleButton.Size = UDim2.new(1, 0, 1, 0)
    bubbleButton.BackgroundTransparency = 1
    bubbleButton.Text = ""
    bubbleButton.ZIndex = 510
    bubbleButton.Parent = FloatingBubble
    bubbleButton.MouseButton1Click:Connect(restoreWindow)

    -- Toggle with Keybind
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == keybind then
            if isMinimized then
                restoreWindow()
            else
                MainFrame.Visible = not MainFrame.Visible
            end
        end
    end)

    -- ──────────────────────────────────────────────────────────────
    -- 3. TITLEBAR & PROFILE CARD
    -- ──────────────────────────────────────────────────────────────
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 56)
    TitleBar.BackgroundColor3 = Theme.Surface
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    -- Titlebar Bottom Border Line
    local titleLine = Instance.new("Frame")
    titleLine.Size = UDim2.new(1, 0, 0, 1)
    titleLine.Position = UDim2.new(0, 0, 1, -1)
    titleLine.BackgroundColor3 = Theme.Border
    titleLine.BorderSizePixel = 0
    titleLine.Parent = TitleBar

    -- Top Accent Gradient Strip
    local topStrip = Instance.new("Frame")
    topStrip.Size = UDim2.new(1, 0, 0, 2)
    topStrip.BackgroundColor3 = Theme.Accent
    topStrip.BorderSizePixel = 0
    topStrip.Parent = TitleBar
    local stripGrad = Instance.new("UIGradient")
    stripGrad.Color = Theme.Grad1
    stripGrad.Parent = topStrip

    -- Left Brand Info
    local brandIcon = Instance.new("Frame")
    brandIcon.Size = UDim2.new(0, 34, 0, 34)
    brandIcon.Position = UDim2.new(0, 16, 0.5, -17)
    brandIcon.BackgroundColor3 = Theme.Accent
    makeCorner(brandIcon, 9)
    brandIcon.Parent = TitleBar
    local biGrad = Instance.new("UIGradient")
    biGrad.Color = Theme.Grad1
    biGrad.Parent = brandIcon

    local biText = Instance.new("TextLabel")
    biText.Size = UDim2.new(1, 0, 1, 0)
    biText.BackgroundTransparency = 1
    biText.Text = "M"
    biText.TextColor3 = Color3.fromRGB(255, 255, 255)
    biText.TextSize = 18
    biText.Font = Enum.Font.GothamBlack
    biText.Parent = brandIcon

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 160, 0, 20)
    titleLabel.Position = UDim2.new(0, 58, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = hubTitle
    titleLabel.TextColor3 = Theme.Text
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = TitleBar

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(0, 160, 0, 16)
    subLabel.Position = UDim2.new(0, 58, 0, 29)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = hubSubtitle
    subLabel.TextColor3 = Theme.TextSub
    subLabel.TextSize = 10
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.Parent = TitleBar

    -- Center Player Headshot Card
    local ProfileCard = Instance.new("Frame")
    ProfileCard.Name = "ProfileCard"
    ProfileCard.Size = UDim2.new(0, 210, 0, 36)
    ProfileCard.Position = UDim2.new(0.5, -105, 0.5, -18)
    ProfileCard.BackgroundColor3 = Theme.Card
    makeCorner(ProfileCard, 18)
    makeStroke(ProfileCard, Theme.Border, 1)
    ProfileCard.Parent = TitleBar

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(0, 28, 0, 28)
    avatarImg.Position = UDim2.new(0, 4, 0.5, -14)
    avatarImg.BackgroundColor3 = Theme.Surface
    avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=100&h=100"
    makeCorner(avatarImg, 14)
    avatarImg.Parent = ProfileCard

    -- Online Green Dot on Avatar
    local onlineDot = Instance.new("Frame")
    onlineDot.Size = UDim2.new(0, 8, 0, 8)
    onlineDot.Position = UDim2.new(1, -7, 1, -7)
    onlineDot.BackgroundColor3 = Theme.Success
    makeCorner(onlineDot, 4)
    makeStroke(onlineDot, Theme.Card, 1.5)
    onlineDot.Parent = avatarImg

    local pName = Instance.new("TextLabel")
    pName.Size = UDim2.new(1, -44, 0, 16)
    pName.Position = UDim2.new(0, 38, 0, 3)
    pName.BackgroundTransparency = 1
    pName.Text = LocalPlayer.DisplayName
    pName.TextColor3 = Theme.Text
    pName.TextSize = 11
    pName.Font = Enum.Font.GothamBold
    pName.TextXAlignment = Enum.TextXAlignment.Left
    pName.Parent = ProfileCard

    local pTag = Instance.new("TextLabel")
    pTag.Size = UDim2.new(1, -44, 0, 14)
    pTag.Position = UDim2.new(0, 38, 0, 18)
    pTag.BackgroundTransparency = 1
    pTag.Text = "@" .. LocalPlayer.Name
    pTag.TextColor3 = Theme.TextSub
    pTag.TextSize = 9.5
    pTag.Font = Enum.Font.Gotham
    pTag.TextXAlignment = Enum.TextXAlignment.Left
    pTag.Parent = ProfileCard

    -- Right Action Window Buttons (Minimize, Close, Theme)
    local winControls = Instance.new("Frame")
    winControls.Size = UDim2.new(0, 110, 0, 32)
    winControls.Position = UDim2.new(1, -120, 0.5, -16)
    winControls.BackgroundTransparency = 1
    winControls.Parent = TitleBar

    local function makeWinBtn(text, posX, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 28, 0, 28)
        btn.Position = UDim2.new(0, posX, 0, 2)
        btn.BackgroundColor3 = Theme.Card
        btn.Text = text
        btn.TextColor3 = Theme.TextSub
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        makeCorner(btn, 7)
        makeStroke(btn, Theme.Border, 1)
        btn.Parent = winControls

        btn.MouseEnter:Connect(function()
            fastTween(btn, {BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.Text}, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            fastTween(btn, {BackgroundColor3 = Theme.Card, TextColor3 = Theme.TextSub}, 0.15)
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Theme Switcher Button
    local themeNames = {"VoidMirage", "Cyberpunk", "EmeraldMatrix", "CrimsonRed"}
    local curThemeIdx = 1
    makeWinBtn("🎨", 0, function()
        curThemeIdx = (curThemeIdx % #themeNames) + 1
        MiRaGe:SetTheme(themeNames[curThemeIdx])
        MiRaGe:Notify({Title = "Theme Changed", Content = "Applied " .. themeNames[curThemeIdx] .. " aesthetic.", Duration = 2})
    end)

    -- Minimize Button
    makeWinBtn("—", 36, minimizeWindow)

    -- Close Button
    local closeBtn = makeWinBtn("✕", 72, function()
        MainFrame.Visible = false
        MiRaGe:Notify({Title = "MiRaGe HUB", Content = "Hidden. Press RightControl to toggle visibility.", Duration = 3})
    end)
    closeBtn.MouseEnter:Connect(function()
        fastTween(closeBtn, {BackgroundColor3 = Theme.Danger, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.15)
    end)

    -- ──────────────────────────────────────────────────────────────
    -- 4. SIDEBAR & PAGE SYSTEM
    -- ──────────────────────────────────────────────────────────────
    local BodyFrame = Instance.new("Frame")
    BodyFrame.Size = UDim2.new(1, 0, 1, -56)
    BodyFrame.Position = UDim2.new(0, 0, 0, 56)
    BodyFrame.BackgroundTransparency = 1
    BodyFrame.Parent = MainFrame

    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 200, 1, 0)
    Sidebar.BackgroundColor3 = Theme.Surface
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 2
    Sidebar.ScrollBarImageColor3 = Theme.Accent
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Sidebar.Parent = BodyFrame

    local sideStroke = Instance.new("Frame")
    sideStroke.Size = UDim2.new(0, 1, 1, 0)
    sideStroke.Position = UDim2.new(1, -1, 0, 0)
    sideStroke.BackgroundColor3 = Theme.Border
    sideStroke.BorderSizePixel = 0
    sideStroke.Parent = Sidebar

    local sideList = Instance.new("UIListLayout")
    sideList.SortOrder = Enum.SortOrder.LayoutOrder
    sideList.Padding = UDim.new(0, 3)
    sideList.Parent = Sidebar
    makePadding(Sidebar, 12, 12, 8, 8)

    local PageContainer = Instance.new("Frame")
    PageContainer.Name = "PageContainer"
    PageContainer.Size = UDim2.new(1, -200, 1, 0)
    PageContainer.Position = UDim2.new(0, 200, 0, 0)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = BodyFrame

    -- Window Object with Tab APIs
    local Window = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        FloatingBubble = FloatingBubble,
        Tabs = {},
        ActiveTab = nil
    }

    function Window:SetBubbleBadge(text)
        bubbleBadge.Text = tostring(text)
    end

    function Window:AddCategory(categoryName)
        local catLabel = Instance.new("TextLabel")
        catLabel.Size = UDim2.new(1, 0, 0, 24)
        catLabel.BackgroundTransparency = 1
        catLabel.Text = string.upper(categoryName)
        catLabel.TextColor3 = Theme.TextDim
        catLabel.TextSize = 9
        catLabel.Font = Enum.Font.GothamBold
        catLabel.TextXAlignment = Enum.TextXAlignment.Left
        catLabel.Parent = Sidebar
        makePadding(catLabel, 8, 2, 8, 0)
    end

    function Window:MakeTab(tabConfig)
        local tabName = type(tabConfig) == "table" and (tabConfig.Name or tabConfig[1]) or tostring(tabConfig)
        local tabIcon = type(tabConfig) == "table" and (tabConfig.Icon or "⚡") or "⚡"
        local initialBadge = type(tabConfig) == "table" and tabConfig.Badge or nil

        -- Tab Button in Sidebar
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "TabBtn_" .. tabName
        tabBtn.Size = UDim2.new(1, 0, 0, 34)
        tabBtn.BackgroundColor3 = Theme.Surface
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        makeCorner(tabBtn, 8)
        tabBtn.Parent = Sidebar

        -- Left Active Indicator Bar
        local activeBar = Instance.new("Frame")
        activeBar.Size = UDim2.new(0, 3, 0.5, 0)
        activeBar.Position = UDim2.new(0, 0, 0.25, 0)
        activeBar.BackgroundColor3 = Theme.Accent
        activeBar.Visible = false
        makeCorner(activeBar, 2)
        activeBar.Parent = tabBtn

        local iconLbl = Instance.new("TextLabel")
        iconLbl.Size = UDim2.new(0, 24, 1, 0)
        iconLbl.Position = UDim2.new(0, 8, 0, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text = tabIcon
        iconLbl.TextSize = 14
        iconLbl.Font = Enum.Font.Gotham
        iconLbl.Parent = tabBtn

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -64, 1, 0)
        nameLbl.Position = UDim2.new(0, 36, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = tabName
        nameLbl.TextColor3 = Theme.TextSub
        nameLbl.TextSize = 12
        nameLbl.Font = Enum.Font.GothamSemibold
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = tabBtn

        local badgeLbl = Instance.new("TextLabel")
        badgeLbl.Size = UDim2.new(0, 24, 0, 16)
        badgeLbl.Position = UDim2.new(1, -30, 0.5, -8)
        badgeLbl.BackgroundColor3 = Theme.Card
        badgeLbl.Text = initialBadge or ""
        badgeLbl.TextColor3 = Theme.Accent
        badgeLbl.TextSize = 9
        badgeLbl.Font = Enum.Font.GothamBold
        badgeLbl.Visible = (initialBadge ~= nil and initialBadge ~= "")
        makeCorner(badgeLbl, 8)
        badgeLbl.Parent = tabBtn

        -- Scrollable Page Viewport
        local Page = Instance.new("ScrollingFrame")
        Page.Name = "Page_" .. tabName
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.Visible = false
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Parent = PageContainer

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 12)
        pageLayout.Parent = Page
        makePadding(Page, 16, 16, 16, 16)

        local Tab = {
            Button = tabBtn,
            Page = Page,
            Name = tabName,
            Sections = {}
        }

        function Tab:SetBadge(text)
            if text and text ~= "" then
                badgeLbl.Text = tostring(text)
                badgeLbl.Visible = true
            else
                badgeLbl.Visible = false
            end
        end

        function Tab:Activate()
            for _, otherTab in pairs(Window.Tabs) do
                otherTab.Page.Visible = false
                otherTab.Button.BackgroundTransparency = 1
                local oBar = otherTab.Button:FindFirstChild("Frame")
                if oBar then oBar.Visible = false end
                local oName = otherTab.Button:FindFirstChild("TextLabel")
                if oName then oName.TextColor3 = Theme.TextSub end
            end
            Page.Visible = true
            tabBtn.BackgroundTransparency = 0.8
            tabBtn.BackgroundColor3 = Theme.Accent
            activeBar.Visible = true
            nameLbl.TextColor3 = Theme.Accent
            Window.ActiveTab = Tab
        end

        tabBtn.MouseButton1Click:Connect(function()
            Tab:Activate()
        end)

        -- Auto activate first tab
        if #Window.Tabs == 0 then
            task.spawn(function()
                Tab:Activate()
            end)
        end

        table.insert(Window.Tabs, Tab)

        -- ──────────────────────────────────────────────────────────
        -- SECTION & CONTROL ELEMENTS
        -- ──────────────────────────────────────────────────────────
        function Tab:AddSection(secTitle)
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = "Sec_" .. secTitle
            SectionFrame.Size = UDim2.new(1, 0, 0, 0)
            SectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            SectionFrame.BackgroundColor3 = Theme.Card
            makeCorner(SectionFrame, 10)
            makeStroke(SectionFrame, Theme.Border, 1)
            SectionFrame.Parent = Page

            local secHeader = Instance.new("Frame")
            secHeader.Size = UDim2.new(1, 0, 0, 32)
            secHeader.BackgroundTransparency = 1
            secHeader.Parent = SectionFrame

            local sTitle = Instance.new("TextLabel")
            sTitle.Size = UDim2.new(1, -20, 1, 0)
            sTitle.Position = UDim2.new(0, 12, 0, 0)
            sTitle.BackgroundTransparency = 1
            sTitle.Text = secTitle
            sTitle.TextColor3 = Theme.Text
            sTitle.TextSize = 12
            sTitle.Font = Enum.Font.GothamBold
            sTitle.TextXAlignment = Enum.TextXAlignment.Left
            sTitle.Parent = secHeader

            local contentHolder = Instance.new("Frame")
            contentHolder.Size = UDim2.new(1, 0, 0, 0)
            contentHolder.Position = UDim2.new(0, 0, 0, 32)
            contentHolder.AutomaticSize = Enum.AutomaticSize.Y
            contentHolder.BackgroundTransparency = 1
            contentHolder.Parent = SectionFrame

            local clayout = Instance.new("UIListLayout")
            clayout.SortOrder = Enum.SortOrder.LayoutOrder
            clayout.Padding = UDim.new(0, 8)
            clayout.Parent = contentHolder
            makePadding(contentHolder, 4, 12, 12, 12)

            local Section = {
                Frame = SectionFrame,
                Container = contentHolder
            }

            -- 1. BUTTON
            function Section:AddButton(btnText, callback)
                callback = callback or function() end
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 34)
                btn.BackgroundColor3 = Theme.Surface
                btn.Text = btnText
                btn.TextColor3 = Theme.Text
                btn.TextSize = 12
                btn.Font = Enum.Font.GothamBold
                makeCorner(btn, 8)
                local bstroke = makeStroke(btn, Theme.Border, 1)
                btn.Parent = contentHolder

                btn.MouseEnter:Connect(function()
                    fastTween(btn, {BackgroundColor3 = Theme.CardHover}, 0.15)
                    fastTween(bstroke, {Color = Theme.Accent}, 0.15)
                end)
                btn.MouseLeave:Connect(function()
                    fastTween(btn, {BackgroundColor3 = Theme.Surface}, 0.15)
                    fastTween(bstroke, {Color = Theme.Border}, 0.15)
                end)
                btn.MouseButton1Click:Connect(callback)
                return btn
            end

            -- 2. TOGGLE
            function Section:AddToggle(toggleConfig, callback)
                local tName = type(toggleConfig) == "table" and toggleConfig.Name or tostring(toggleConfig)
                local defaultVal = type(toggleConfig) == "table" and toggleConfig.Default or false
                callback = callback or (type(toggleConfig) == "table" and toggleConfig.Callback) or function() end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 34)
                row.BackgroundTransparency = 1
                row.Parent = contentHolder

                local tLbl = Instance.new("TextLabel")
                tLbl.Size = UDim2.new(1, -48, 1, 0)
                tLbl.BackgroundTransparency = 1
                tLbl.Text = tName
                tLbl.TextColor3 = Theme.Text
                tLbl.TextSize = 12
                tLbl.Font = Enum.Font.GothamSemibold
                tLbl.TextXAlignment = Enum.TextXAlignment.Left
                tLbl.Parent = row

                local switch = Instance.new("Frame")
                switch.Size = UDim2.new(0, 38, 0, 20)
                switch.Position = UDim2.new(1, -38, 0.5, -10)
                switch.BackgroundColor3 = defaultVal and Theme.Accent or Theme.Input
                makeCorner(switch, 10)
                makeStroke(switch, Theme.Border, 1)
                switch.Parent = row

                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 14, 0, 14)
                dot.Position = defaultVal and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                makeCorner(dot, 7)
                dot.Parent = switch

                local state = defaultVal
                local trigger = Instance.new("TextButton")
                trigger.Size = UDim2.new(1, 0, 1, 0)
                trigger.BackgroundTransparency = 1
                trigger.Text = ""
                trigger.Parent = row

                local ToggleObj = {}
                function ToggleObj:Set(newVal)
                    state = newVal
                    fastTween(switch, {BackgroundColor3 = state and Theme.Accent or Theme.Input}, 0.2)
                    fastTween(dot, {Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}, 0.2)
                    pcall(callback, state)
                end

                trigger.MouseButton1Click:Connect(function()
                    ToggleObj:Set(not state)
                end)

                return ToggleObj
            end

            -- 3. SLIDER
            function Section:AddSlider(sliderConfig, callback)
                local sName = sliderConfig.Name or "Slider"
                local minVal = sliderConfig.Min or 0
                local maxVal = sliderConfig.Max or 100
                local defVal = sliderConfig.Default or minVal
                local valSuffix = sliderConfig.Suffix or ""
                callback = callback or function() end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 44)
                row.BackgroundTransparency = 1
                row.Parent = contentHolder

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -50, 0, 16)
                title.BackgroundTransparency = 1
                title.Text = sName
                title.TextColor3 = Theme.Text
                title.TextSize = 11
                title.Font = Enum.Font.GothamSemibold
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = row

                local valLbl = Instance.new("TextLabel")
                valLbl.Size = UDim2.new(0, 50, 0, 16)
                valLbl.Position = UDim2.new(1, -50, 0, 0)
                valLbl.BackgroundTransparency = 1
                valLbl.Text = tostring(defVal) .. valSuffix
                valLbl.TextColor3 = Theme.Accent
                valLbl.TextSize = 11
                valLbl.Font = Enum.Font.GothamBold
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.Parent = row

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, 0, 0, 6)
                track.Position = UDim2.new(0, 0, 0, 26)
                track.BackgroundColor3 = Theme.Input
                makeCorner(track, 3)
                track.Parent = row

                local fill = Instance.new("Frame")
                local initPct = math.clamp((defVal - minVal) / (maxVal - minVal), 0, 1)
                fill.Size = UDim2.new(initPct, 0, 1, 0)
                fill.BackgroundColor3 = Theme.Accent
                makeCorner(fill, 3)
                fill.Parent = track

                local curVal = defVal
                local sliding = false

                local function updateSlider(inputX)
                    local absPos = track.AbsolutePosition.X
                    local absSize = track.AbsoluteSize.X
                    local pct = math.clamp((inputX - absPos) / absSize, 0, 1)
                    curVal = math.floor(minVal + (maxVal - minVal) * pct)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    valLbl.Text = tostring(curVal) .. valSuffix
                    pcall(callback, curVal)
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        updateSlider(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input.Position.X)
                    end
                end)

                local SliderObj = {}
                function SliderObj:Set(newVal)
                    curVal = math.clamp(newVal, minVal, maxVal)
                    local pct = (curVal - minVal) / (maxVal - minVal)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    valLbl.Text = tostring(curVal) .. valSuffix
                    pcall(callback, curVal)
                end
                return SliderObj
            end

            -- 4. DROPDOWN (SINGLE & MULTI)
            function Section:AddDropdown(dropdownConfig, callback)
                local dName = dropdownConfig.Name or "Dropdown"
                local options = dropdownConfig.Options or {}
                local isMulti = dropdownConfig.MultiSelect or false
                local defaultVal = dropdownConfig.Default or (isMulti and {} or options[1])
                callback = callback or function() end

                local dropFrame = Instance.new("Frame")
                dropFrame.Size = UDim2.new(1, 0, 0, 52)
                dropFrame.BackgroundTransparency = 1
                dropFrame.ClipsDescendants = true
                dropFrame.Parent = contentHolder

                local dLbl = Instance.new("TextLabel")
                dLbl.Size = UDim2.new(1, 0, 0, 16)
                dLbl.BackgroundTransparency = 1
                dLbl.Text = dName
                dLbl.TextColor3 = Theme.TextSub
                dLbl.TextSize = 10.5
                dLbl.Font = Enum.Font.GothamBold
                dLbl.TextXAlignment = Enum.TextXAlignment.Left
                dLbl.Parent = dropFrame

                local box = Instance.new("TextButton")
                box.Size = UDim2.new(1, 0, 0, 30)
                box.Position = UDim2.new(0, 0, 0, 20)
                box.BackgroundColor3 = Theme.Input
                box.Text = ""
                makeCorner(box, 7)
                local bstroke = makeStroke(box, Theme.Border, 1)
                box.Parent = dropFrame

                local selectedText = Instance.new("TextLabel")
                selectedText.Size = UDim2.new(1, -30, 1, 0)
                selectedText.Position = UDim2.new(0, 10, 0, 0)
                selectedText.BackgroundTransparency = 1
                selectedText.Text = isMulti and (type(defaultVal) == "table" and table.concat(defaultVal, ", ") or "None") or tostring(defaultVal)
                selectedText.TextColor3 = Theme.Text
                selectedText.TextSize = 11
                selectedText.Font = Enum.Font.GothamSemibold
                selectedText.TextXAlignment = Enum.TextXAlignment.Left
                selectedText.Parent = box

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 20, 1, 0)
                arrow.Position = UDim2.new(1, -24, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Text = "▼"
                arrow.TextColor3 = Theme.TextSub
                arrow.TextSize = 9
                arrow.Parent = box

                local optionList = Instance.new("ScrollingFrame")
                optionList.Size = UDim2.new(1, 0, 0, 100)
                optionList.Position = UDim2.new(0, 0, 0, 54)
                optionList.BackgroundColor3 = Theme.Surface
                optionList.ScrollBarThickness = 2
                optionList.CanvasSize = UDim2.new(0, 0, 0, #options * 26)
                makeCorner(optionList, 6)
                makeStroke(optionList, Theme.Border, 1)
                optionList.Parent = dropFrame

                local oLayout = Instance.new("UIListLayout")
                oLayout.SortOrder = Enum.SortOrder.LayoutOrder
                oLayout.Parent = optionList

                local isOpen = false
                local selected = isMulti and (type(defaultVal) == "table" and defaultVal or {}) or defaultVal

                local function refreshOptions()
                    for _, child in ipairs(optionList:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end

                    for _, opt in ipairs(options) do
                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1, 0, 0, 26)
                        optBtn.BackgroundColor3 = Theme.Surface
                        optBtn.BackgroundTransparency = 1
                        optBtn.Text = "  " .. tostring(opt)
                        optBtn.TextColor3 = Theme.TextSub
                        optBtn.TextSize = 11
                        optBtn.Font = Enum.Font.Gotham
                        optBtn.TextXAlignment = Enum.TextXAlignment.Left
                        optBtn.Parent = optionList

                        optBtn.MouseButton1Click:Connect(function()
                            if isMulti then
                                local idx = table.find(selected, opt)
                                if idx then
                                    table.remove(selected, idx)
                                else
                                    table.insert(selected, opt)
                                end
                                selectedText.Text = #selected > 0 and table.concat(selected, ", ") or "None"
                                pcall(callback, selected)
                            else
                                selected = opt
                                selectedText.Text = tostring(opt)
                                isOpen = false
                                fastTween(dropFrame, {Size = UDim2.new(1, 0, 0, 52)}, 0.2)
                                arrow.Text = "▼"
                                pcall(callback, selected)
                            end
                        end)
                    end
                end

                refreshOptions()

                box.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    arrow.Text = isOpen and "▲" or "▼"
                    fastTween(dropFrame, {Size = isOpen and UDim2.new(1, 0, 0, 160) or UDim2.new(1, 0, 0, 52)}, 0.2)
                end)

                local DropdownObj = {}
                function DropdownObj:Set(newVal)
                    selected = newVal
                    selectedText.Text = isMulti and (#selected > 0 and table.concat(selected, ", ") or "None") or tostring(selected)
                    pcall(callback, selected)
                end
                function DropdownObj:Refresh(newOptions)
                    options = newOptions or {}
                    refreshOptions()
                end
                return DropdownObj
            end

            -- 5. TARGET PLAYER SELECTOR WITH HEADSHOT
            function Section:AddTargetSelector(callback)
                callback = callback or function() end

                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, 0, 0, 52)
                card.BackgroundColor3 = Theme.Input
                makeCorner(card, 8)
                makeStroke(card, Theme.Border, 1)
                card.Parent = contentHolder

                local tAvatar = Instance.new("ImageLabel")
                tAvatar.Size = UDim2.new(0, 36, 0, 36)
                tAvatar.Position = UDim2.new(0, 8, 0.5, -18)
                tAvatar.BackgroundColor3 = Theme.Surface
                tAvatar.Image = "rbxassetid://0"
                makeCorner(tAvatar, 18)
                tAvatar.Parent = card

                local selectBtn = Instance.new("TextButton")
                selectBtn.Size = UDim2.new(1, -54, 1, 0)
                selectBtn.Position = UDim2.new(0, 50, 0, 0)
                selectBtn.BackgroundTransparency = 1
                selectBtn.Text = "Select Target Player..."
                selectBtn.TextColor3 = Theme.Text
                selectBtn.TextSize = 12
                selectBtn.Font = Enum.Font.GothamBold
                selectBtn.TextXAlignment = Enum.TextXAlignment.Left
                selectBtn.Parent = card

                local targetUser = nil
                local function updateTarget(p)
                    targetUser = p
                    selectBtn.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                    tAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(p.UserId) .. "&w=100&h=100"
                    pcall(callback, p)
                end

                selectBtn.MouseButton1Click:Connect(function()
                    local plist = {}
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer then table.insert(plist, p) end
                    end
                    if #plist > 0 then
                        local nextIdx = 1
                        if targetUser then
                            local curIdx = table.find(plist, targetUser)
                            if curIdx then nextIdx = (curIdx % #plist) + 1 end
                        end
                        updateTarget(plist[nextIdx])
                    else
                        MiRaGe:Notify({Title = "No Targets", Content = "No other players found in server!", Type = "Warn"})
                    end
                end)

                return {
                    GetTarget = function() return targetUser end,
                    SetTarget = updateTarget
                }
            end

            -- 6. PARAGRAPH / STAT CARD
            function Section:AddParagraph(title, desc)
                local box = Instance.new("Frame")
                box.Size = UDim2.new(1, 0, 0, 0)
                box.AutomaticSize = Enum.AutomaticSize.Y
                box.BackgroundColor3 = Theme.Input
                makeCorner(box, 8)
                makePadding(box, 8, 8, 10, 10)
                box.Parent = contentHolder

                local tLbl = Instance.new("TextLabel")
                tLbl.Size = UDim2.new(1, 0, 0, 16)
                tLbl.BackgroundTransparency = 1
                tLbl.Text = title
                tLbl.TextColor3 = Theme.Text
                tLbl.TextSize = 11
                tLbl.Font = Enum.Font.GothamBold
                tLbl.TextXAlignment = Enum.TextXAlignment.Left
                tLbl.Parent = box

                local dLbl = Instance.new("TextLabel")
                dLbl.Size = UDim2.new(1, 0, 0, 0)
                dLbl.AutomaticSize = Enum.AutomaticSize.Y
                dLbl.Position = UDim2.new(0, 0, 0, 18)
                dLbl.BackgroundTransparency = 1
                dLbl.Text = desc
                dLbl.TextColor3 = Theme.TextSub
                dLbl.TextSize = 10.5
                dLbl.Font = Enum.Font.Gotham
                dLbl.TextWrapped = true
                dLbl.TextXAlignment = Enum.TextXAlignment.Left
                dLbl.Parent = box

                return {
                    Set = function(_, newTitle, newDesc)
                        if newDesc then
                            tLbl.Text = newTitle
                            dLbl.Text = newDesc
                        else
                            dLbl.Text = newTitle
                        end
                    end
                }
            end

            -- 7. PROGRESS BAR
            function Section:AddProgressBar(title)
                local box = Instance.new("Frame")
                box.Size = UDim2.new(1, 0, 0, 46)
                box.BackgroundTransparency = 1
                box.Parent = contentHolder

                local tLbl = Instance.new("TextLabel")
                tLbl.Size = UDim2.new(1, -60, 0, 16)
                tLbl.BackgroundTransparency = 1
                tLbl.Text = title or "Progress"
                tLbl.TextColor3 = Theme.Text
                tLbl.TextSize = 11
                tLbl.Font = Enum.Font.GothamBold
                tLbl.TextXAlignment = Enum.TextXAlignment.Left
                tLbl.Parent = box

                local pctLbl = Instance.new("TextLabel")
                pctLbl.Size = UDim2.new(0, 60, 0, 16)
                pctLbl.Position = UDim2.new(1, -60, 0, 0)
                pctLbl.BackgroundTransparency = 1
                pctLbl.Text = "0%"
                pctLbl.TextColor3 = Theme.Accent
                pctLbl.TextSize = 11
                pctLbl.Font = Enum.Font.GothamBold
                pctLbl.TextXAlignment = Enum.TextXAlignment.Right
                pctLbl.Parent = box

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, 0, 0, 6)
                track.Position = UDim2.new(0, 0, 0, 24)
                track.BackgroundColor3 = Theme.Input
                makeCorner(track, 3)
                track.Parent = box

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = Theme.Accent
                makeCorner(fill, 3)
                fill.Parent = track
                local fgrad = Instance.new("UIGradient")
                fgrad.Color = Theme.Grad1
                fgrad.Parent = fill

                return {
                    Set = function(_, pct, customText)
                        local clamped = math.clamp(pct, 0, 1)
                        fastTween(fill, {Size = UDim2.new(clamped, 0, 1, 0)}, 0.3)
                        pctLbl.Text = customText or (math.floor(clamped * 100) .. "%")
                    end
                }
            end

            -- 8. TERMINAL CONSOLE LOG (WITH REALTIME AUTO SCROLL)
            function Section:AddConsole(consoleTitle)
                local cFrame = Instance.new("Frame")
                cFrame.Size = UDim2.new(1, 0, 0, 160)
                cFrame.BackgroundColor3 = Color3.fromRGB(4, 6, 10)
                makeCorner(cFrame, 8)
                makeStroke(cFrame, Theme.Border, 1)
                cFrame.Parent = contentHolder

                local cheader = Instance.new("Frame")
                cheader.Size = UDim2.new(1, 0, 0, 24)
                cheader.BackgroundTransparency = 1
                cheader.Parent = cFrame

                local ctitle = Instance.new("TextLabel")
                ctitle.Size = UDim2.new(1, -60, 1, 0)
                ctitle.Position = UDim2.new(0, 8, 0, 0)
                ctitle.BackgroundTransparency = 1
                ctitle.Text = consoleTitle or "Console Logs"
                ctitle.TextColor3 = Theme.TextSub
                ctitle.TextSize = 10
                ctitle.Font = Enum.Font.GothamBold
                ctitle.TextXAlignment = Enum.TextXAlignment.Left
                ctitle.Parent = cheader

                local clearBtn = Instance.new("TextButton")
                clearBtn.Size = UDim2.new(0, 44, 0, 18)
                clearBtn.Position = UDim2.new(1, -50, 0.5, -9)
                clearBtn.BackgroundColor3 = Theme.Card
                clearBtn.Text = "Clear"
                clearBtn.TextColor3 = Theme.TextSub
                clearBtn.TextSize = 9
                clearBtn.Font = Enum.Font.Gotham
                makeCorner(clearBtn, 4)
                clearBtn.Parent = cheader

                local logScroll = Instance.new("ScrollingFrame")
                logScroll.Size = UDim2.new(1, -12, 1, -30)
                logScroll.Position = UDim2.new(0, 6, 0, 24)
                logScroll.BackgroundTransparency = 1
                logScroll.ScrollBarThickness = 2
                logScroll.ScrollBarImageColor3 = Theme.Accent
                logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                logScroll.Parent = cFrame

                local logLayout = Instance.new("UIListLayout")
                logLayout.SortOrder = Enum.SortOrder.LayoutOrder
                logLayout.Padding = UDim.new(0, 3)
                logLayout.Parent = logScroll

                clearBtn.MouseButton1Click:Connect(function()
                    for _, child in ipairs(logScroll:GetChildren()) do
                        if child:IsA("TextLabel") then child:Destroy() end
                    end
                end)

                local ConsoleObj = {}
                function ConsoleObj:Log(msg, logType)
                    local timeStr = os.date("%H:%M:%S")
                    local color = Theme.TextSub
                    if logType == "success" then color = Theme.Success
                    elseif logType == "info" then color = Theme.Accent
                    elseif logType == "warn" then color = Theme.Warning
                    elseif logType == "error" then color = Theme.Danger
                    end

                    local line = Instance.new("TextLabel")
                    line.Size = UDim2.new(1, 0, 0, 16)
                    line.BackgroundTransparency = 1
                    line.Text = string.format("[%s] %s", timeStr, tostring(msg))
                    line.TextColor3 = color
                    line.TextSize = 10
                    line.Font = Enum.Font.Code
                    line.TextXAlignment = Enum.TextXAlignment.Left
                    line.TextWrapped = true
                    line.Parent = logScroll

                    -- Auto scroll down
                    logScroll.CanvasPosition = Vector2.new(0, 99999)
                end

                function ConsoleObj:Clear()
                    for _, child in ipairs(logScroll:GetChildren()) do
                        if child:IsA("TextLabel") then child:Destroy() end
                    end
                end

                return ConsoleObj
            end

            return Section
        end

        return Tab
    end

    MiRaGe.ActiveWindow = Window
    return Window
end

return MiRaGe
