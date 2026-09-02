--[[
    ========================================================================
                             MiRaGe HUB UI LIBRARY (v2.2)
                Mobile-Optimized Responsive Roblox Automation Suite
    ========================================================================
]]

local MiRaGe = {
    Version = "2.2.0",
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
    duration = duration or 0.2
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local tween = TweenService:Create(instance, TweenInfo.new(duration, style, dir), propTable)
    tween:Play()
    return tween
end

local function makeCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
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
    ToastContainer.Size = UDim2.new(0, 260, 1, -20)
    ToastContainer.Position = UDim2.new(1, -270, 0, 10)
    ToastContainer.BackgroundTransparency = 1
    ToastContainer.Parent = NotificationGui

    local list = Instance.new("UIListLayout")
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.HorizontalAlignment = Enum.HorizontalAlignment.Right
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)
    list.Parent = ToastContainer

    return ToastContainer
end

function MiRaGe:Notify(options)
    local title = options.Title or "MiRaGe HUB"
    local content = options.Content or options.Text or ""
    local duration = options.Duration or 3.0
    local nType = options.Type or "Info"

    local container = getNotificationContainer()

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 52)
    toast.BackgroundColor3 = Theme.Surface
    toast.BackgroundTransparency = 0.05
    toast.Position = UDim2.new(1, 80, 0, 0)
    toast.ClipsDescendants = true
    makeCorner(toast, 8)
    makeStroke(toast, Theme.Border, 1)

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 26, 0, 26)
    iconLabel.Position = UDim2.new(0, 8, 0.5, -13)
    iconLabel.BackgroundColor3 = Theme.Card
    iconLabel.Text = nType == "Success" and "✅" or (nType == "Warn" and "⚠️" or (nType == "Danger" and "❌" or "⚡"))
    iconLabel.TextSize = 12
    iconLabel.Parent = toast
    makeCorner(iconLabel, 6)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -42, 0, 15)
    titleLbl.Position = UDim2.new(0, 38, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.Text
    titleLbl.TextSize = 10.5
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = toast

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -42, 0, 24)
    descLbl.Position = UDim2.new(0, 38, 0, 22)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = content
    descLbl.TextColor3 = Theme.TextSub
    descLbl.TextSize = 9
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

    fastTween(toast, {Position = UDim2.new(0, 0, 0, 0)}, 0.25, Enum.EasingStyle.Back)
    fastTween(progressLine, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        fastTween(toast, {Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1}, 0.2)
        task.wait(0.22)
        toast:Destroy()
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- MASTER WINDOW CREATION (MOBILE RESPONSIVE)
-- ══════════════════════════════════════════════════════════════════
function MiRaGe:CreateWindow(config)
    config = config or {}
    local hubTitle = config.Title or "MiRaGe HUB"
    local hubSubtitle = config.Subtitle or "Automation Suite"
    local keybind = config.Keybind or Enum.KeyCode.RightControl
    local defaultTheme = config.Theme or "VoidMirage"

    if MiRaGe.Themes[defaultTheme] then
        Theme = MiRaGe.Themes[defaultTheme]
    end

    local Camera = workspace.CurrentCamera
    local viewport = Camera and Camera.ViewportSize or Vector2.new(800, 600)
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    -- Mobile Responsive Dimensions
    local winW = math.clamp(viewport.X - 30, 360, isMobile and 540 or 650)
    local winH = math.clamp(viewport.Y - 45, 260, isMobile and 310 or 390)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MiRaGe_Suite_v2"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = getSafeGuiParent()

    -- ──────────────────────────────────────────────────────────────
    -- 1. DRAGGABLE FLOATING CIRCULAR LOGO BUBBLE
    -- ──────────────────────────────────────────────────────────────
    local FloatingBubble = Instance.new("Frame")
    FloatingBubble.Name = "FloatingBubble"
    FloatingBubble.Size = UDim2.new(0, 48, 0, 48)
    FloatingBubble.Position = UDim2.new(0, 20, 0.5, -24)
    FloatingBubble.BackgroundColor3 = Theme.Surface
    FloatingBubble.Visible = false
    FloatingBubble.ZIndex = 500
    makeCorner(FloatingBubble, 24)
    makeStroke(FloatingBubble, Theme.Accent, 2)

    local bubbleGrad = Instance.new("UIGradient")
    bubbleGrad.Color = Theme.Grad1
    bubbleGrad.Rotation = 45
    bubbleGrad.Parent = FloatingBubble

    local pulseRing = Instance.new("Frame")
    pulseRing.Name = "PulseRing"
    pulseRing.Size = UDim2.new(1, 10, 1, 10)
    pulseRing.Position = UDim2.new(0, -5, 0, -5)
    pulseRing.BackgroundTransparency = 1
    makeCorner(pulseRing, 30)
    local pulseStroke = makeStroke(pulseRing, Theme.Accent, 1.5, 0.4)
    pulseRing.Parent = FloatingBubble

    task.spawn(function()
        while pulseRing.Parent do
            pulseRing.Size = UDim2.new(1, 0, 1, 0)
            pulseRing.Position = UDim2.new(0, 0, 0, 0)
            pulseStroke.Transparency = 0.2
            local tw = TweenService:Create(pulseRing, TweenInfo.new(1.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 20, 1, 20),
                Position = UDim2.new(0, -10, 0, -10)
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
    bubbleLetter.TextSize = 20
    bubbleLetter.Font = Enum.Font.GothamBlack
    bubbleLetter.ZIndex = 502
    bubbleLetter.Parent = FloatingBubble

    local bubbleBadge = Instance.new("TextLabel")
    bubbleBadge.Name = "BubbleBadge"
    bubbleBadge.Size = UDim2.new(0, 20, 0, 15)
    bubbleBadge.Position = UDim2.new(1, -10, 0, -3)
    bubbleBadge.BackgroundColor3 = Theme.Success
    bubbleBadge.Text = "●"
    bubbleBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    bubbleBadge.TextSize = 9
    bubbleBadge.Font = Enum.Font.GothamBold
    bubbleBadge.ZIndex = 505
    makeCorner(bubbleBadge, 7)
    bubbleBadge.Parent = FloatingBubble

    FloatingBubble.Parent = ScreenGui

    -- ──────────────────────────────────────────────────────────────
    -- 2. MAIN WINDOW CONTAINER
    -- ──────────────────────────────────────────────────────────────
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, winW, 0, winH)
    MainFrame.Position = UDim2.new(0.5, -winW/2, 0.5, -winH/2)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 10
    makeCorner(MainFrame, 10)
    makeStroke(MainFrame, Theme.Border, 1.2)

    MainFrame.Parent = ScreenGui

    -- Restore & Minimize Handlers
    local isMinimized = false
    local function minimizeWindow()
        isMinimized = true
        fastTween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = FloatingBubble.Position}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(0.22)
        MainFrame.Visible = false
        FloatingBubble.Visible = true
        FloatingBubble.Size = UDim2.new(0, 0, 0, 0)
        fastTween(FloatingBubble, {Size = UDim2.new(0, 48, 0, 48)}, 0.25, Enum.EasingStyle.Back)
        MiRaGe:Notify({Title = "MiRaGe HUB", Content = "Minimized! Tap floating logo to reopen.", Duration = 2.0})
    end

    local function restoreWindow()
        isMinimized = false
        FloatingBubble.Visible = false
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        fastTween(MainFrame, {
            Size = UDim2.new(0, winW, 0, winH),
            Position = UDim2.new(0.5, -winW/2, 0.5, -winH/2)
        }, 0.25, Enum.EasingStyle.Back)
    end

    -- Touch & Mouse Draggable for Floating Bubble
    do
        local dragging = false
        local dragStart, startPos
        local hasMoved = false
        local endConn

        FloatingBubble.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                hasMoved = false
                dragStart = input.Position
                startPos = FloatingBubble.Position

                if endConn then endConn:Disconnect() end
                endConn = UserInputService.InputEnded:Connect(function(endInput)
                    if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                        if dragging then
                            dragging = false
                            if endConn then endConn:Disconnect() end
                            if not hasMoved then
                                restoreWindow()
                            end
                        end
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                if delta.Magnitude > 6 then
                    hasMoved = true
                end
                FloatingBubble.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

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
    -- 3. COMPACT TITLEBAR
    -- ──────────────────────────────────────────────────────────────
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 36)
    TitleBar.BackgroundColor3 = Theme.Surface
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    -- Window Dragging
    do
        local dragging = false
        local dragStart, startPos
        TitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    local titleLine = Instance.new("Frame")
    titleLine.Size = UDim2.new(1, 0, 0, 1)
    titleLine.Position = UDim2.new(0, 0, 1, -1)
    titleLine.BackgroundColor3 = Theme.Border
    titleLine.BorderSizePixel = 0
    titleLine.Parent = TitleBar

    local topStrip = Instance.new("Frame")
    topStrip.Size = UDim2.new(1, 0, 0, 2)
    topStrip.BackgroundColor3 = Theme.Accent
    topStrip.BorderSizePixel = 0
    topStrip.Parent = TitleBar
    local stripGrad = Instance.new("UIGradient")
    stripGrad.Color = Theme.Grad1
    stripGrad.Parent = topStrip

    local brandIcon = Instance.new("Frame")
    brandIcon.Size = UDim2.new(0, 22, 0, 22)
    brandIcon.Position = UDim2.new(0, 8, 0.5, -11)
    brandIcon.BackgroundColor3 = Theme.Accent
    makeCorner(brandIcon, 5)
    brandIcon.Parent = TitleBar
    local biGrad = Instance.new("UIGradient")
    biGrad.Color = Theme.Grad1
    biGrad.Parent = brandIcon

    local biText = Instance.new("TextLabel")
    biText.Size = UDim2.new(1, 0, 1, 0)
    biText.BackgroundTransparency = 1
    biText.Text = "M"
    biText.TextColor3 = Color3.fromRGB(255, 255, 255)
    biText.TextSize = 12
    biText.Font = Enum.Font.GothamBlack
    biText.Parent = brandIcon

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 120, 0, 14)
    titleLabel.Position = UDim2.new(0, 36, 0, 4)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = hubTitle
    titleLabel.TextColor3 = Theme.Text
    titleLabel.TextSize = 11
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = TitleBar

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(0, 120, 0, 11)
    subLabel.Position = UDim2.new(0, 36, 0, 18)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = hubSubtitle
    subLabel.TextColor3 = Theme.TextSub
    subLabel.TextSize = 8
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.Parent = TitleBar

    -- Center Player Headshot Card
    local ProfileCard = Instance.new("Frame")
    ProfileCard.Name = "ProfileCard"
    ProfileCard.Size = UDim2.new(0, 120, 0, 22)
    ProfileCard.Position = UDim2.new(0.5, -60, 0.5, -11)
    ProfileCard.BackgroundColor3 = Theme.Card
    makeCorner(ProfileCard, 11)
    makeStroke(ProfileCard, Theme.Border, 1)
    ProfileCard.Parent = TitleBar

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(0, 16, 0, 16)
    avatarImg.Position = UDim2.new(0, 3, 0.5, -8)
    avatarImg.BackgroundColor3 = Theme.Surface
    avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=100&h=100"
    makeCorner(avatarImg, 8)
    avatarImg.Parent = ProfileCard

    local onlineDot = Instance.new("Frame")
    onlineDot.Size = UDim2.new(0, 5, 0, 5)
    onlineDot.Position = UDim2.new(1, -4, 1, -4)
    onlineDot.BackgroundColor3 = Theme.Success
    makeCorner(onlineDot, 2.5)
    makeStroke(onlineDot, Theme.Card, 1)
    onlineDot.Parent = avatarImg

    local pName = Instance.new("TextLabel")
    pName.Size = UDim2.new(1, -24, 1, 0)
    pName.Position = UDim2.new(0, 22, 0, 0)
    pName.BackgroundTransparency = 1
    pName.Text = LocalPlayer.DisplayName
    pName.TextColor3 = Theme.Text
    pName.TextSize = 8.5
    pName.Font = Enum.Font.GothamBold
    pName.TextXAlignment = Enum.TextXAlignment.Left
    pName.Parent = ProfileCard

    -- Right Action Buttons
    local winControls = Instance.new("Frame")
    winControls.Size = UDim2.new(0, 75, 0, 22)
    winControls.Position = UDim2.new(1, -82, 0.5, -11)
    winControls.BackgroundTransparency = 1
    winControls.Parent = TitleBar

    local function makeWinBtn(text, posX, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 22, 0, 22)
        btn.Position = UDim2.new(0, posX, 0, 0)
        btn.BackgroundColor3 = Theme.Card
        btn.Text = text
        btn.TextColor3 = Theme.TextSub
        btn.TextSize = 9.5
        btn.Font = Enum.Font.GothamBold
        makeCorner(btn, 4)
        makeStroke(btn, Theme.Border, 1)
        btn.Parent = winControls

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local themeNames = {"VoidMirage", "Cyberpunk", "EmeraldMatrix", "CrimsonRed"}
    local curThemeIdx = 1
    makeWinBtn("🎨", 0, function()
        curThemeIdx = (curThemeIdx % #themeNames) + 1
        MiRaGe:SetTheme(themeNames[curThemeIdx])
        MiRaGe:Notify({Title = "Theme Changed", Content = "Switched to " .. themeNames[curThemeIdx], Duration = 1.5})
    end)

    makeWinBtn("—", 26, minimizeWindow)

    local closeBtn = makeWinBtn("✕", 52, function()
        MainFrame.Visible = false
        MiRaGe:Notify({Title = "MiRaGe HUB", Content = "Hidden. Press RightControl to reopen.", Duration = 2})
    end)

    -- ──────────────────────────────────────────────────────────────
    -- 4. SIDEBAR & PAGE SYSTEM
    -- ──────────────────────────────────────────────────────────────
    local BodyFrame = Instance.new("Frame")
    BodyFrame.Size = UDim2.new(1, 0, 1, -36)
    BodyFrame.Position = UDim2.new(0, 0, 0, 36)
    BodyFrame.BackgroundTransparency = 1
    BodyFrame.Parent = MainFrame

    local sideW = 135
    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, sideW, 1, 0)
    Sidebar.BackgroundColor3 = Theme.Surface
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 2
    Sidebar.ScrollBarImageColor3 = Theme.Accent
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Sidebar.CanvasPosition = Vector2.new(0, 0)
    Sidebar.Parent = BodyFrame

    local sideStroke = Instance.new("Frame")
    sideStroke.Size = UDim2.new(0, 1, 1, 0)
    sideStroke.Position = UDim2.new(1, -1, 0, 0)
    sideStroke.BackgroundColor3 = Theme.Border
    sideStroke.BorderSizePixel = 0
    sideStroke.Parent = Sidebar

    local sideList = Instance.new("UIListLayout")
    sideList.SortOrder = Enum.SortOrder.LayoutOrder
    sideList.VerticalAlignment = Enum.VerticalAlignment.Top
    sideList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    sideList.Padding = UDim.new(0, 2)
    sideList.Parent = Sidebar
    makePadding(Sidebar, 4, 4, 4, 4)

    local PageContainer = Instance.new("Frame")
    PageContainer.Name = "PageContainer"
    PageContainer.Size = UDim2.new(1, -sideW, 1, 0)
    PageContainer.Position = UDim2.new(0, sideW, 0, 0)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = BodyFrame

    local sidebarOrder = 0

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
        sidebarOrder = sidebarOrder + 1
        local catLabel = Instance.new("TextLabel")
        catLabel.LayoutOrder = sidebarOrder
        catLabel.Size = UDim2.new(1, 0, 0, 16)
        catLabel.BackgroundTransparency = 1
        catLabel.Text = string.upper(categoryName)
        catLabel.TextColor3 = Theme.TextDim
        catLabel.TextSize = 7.5
        catLabel.Font = Enum.Font.GothamBold
        catLabel.TextXAlignment = Enum.TextXAlignment.Left
        catLabel.Parent = Sidebar
        makePadding(catLabel, 4, 1, 4, 0)
    end

    function Window:MakeTab(tabConfig)
        sidebarOrder = sidebarOrder + 1
        local tabName = type(tabConfig) == "table" and (tabConfig.Name or tabConfig[1]) or tostring(tabConfig)
        local tabIcon = type(tabConfig) == "table" and (tabConfig.Icon or "⚡") or "⚡"
        local initialBadge = type(tabConfig) == "table" and tabConfig.Badge or nil

        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "TabBtn_" .. tabName
        tabBtn.LayoutOrder = sidebarOrder
        tabBtn.Size = UDim2.new(1, 0, 0, 24)
        tabBtn.BackgroundColor3 = Theme.Surface
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        makeCorner(tabBtn, 4)
        tabBtn.Parent = Sidebar

        local activeBar = Instance.new("Frame")
        activeBar.Size = UDim2.new(0, 2, 0.6, 0)
        activeBar.Position = UDim2.new(0, 0, 0.2, 0)
        activeBar.BackgroundColor3 = Theme.Accent
        activeBar.Visible = false
        makeCorner(activeBar, 1)
        activeBar.Parent = tabBtn

        local iconLbl = Instance.new("TextLabel")
        iconLbl.Size = UDim2.new(0, 16, 1, 0)
        iconLbl.Position = UDim2.new(0, 4, 0, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text = tabIcon
        iconLbl.TextSize = 11
        iconLbl.Font = Enum.Font.Gotham
        iconLbl.Parent = tabBtn

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -44, 1, 0)
        nameLbl.Position = UDim2.new(0, 22, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = tabName
        nameLbl.TextColor3 = Theme.TextSub
        nameLbl.TextSize = 9.5
        nameLbl.Font = Enum.Font.GothamSemibold
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = tabBtn

        local badgeLbl = Instance.new("TextLabel")
        badgeLbl.Size = UDim2.new(0, 18, 0, 13)
        badgeLbl.Position = UDim2.new(1, -20, 0.5, -6.5)
        badgeLbl.BackgroundColor3 = Theme.Card
        badgeLbl.Text = initialBadge or ""
        badgeLbl.TextColor3 = Theme.Accent
        badgeLbl.TextSize = 7.5
        badgeLbl.Font = Enum.Font.GothamBold
        badgeLbl.Visible = (initialBadge ~= nil and initialBadge ~= "")
        makeCorner(badgeLbl, 5)
        badgeLbl.Parent = tabBtn

        local Page = Instance.new("ScrollingFrame")
        Page.Name = "Page_" .. tabName
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.Visible = false
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Parent = PageContainer

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 6)
        pageLayout.Parent = Page
        makePadding(Page, 8, 8, 8, 8)

        local Tab = {
            Button = tabBtn,
            Page = Page,
            Name = tabName
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

        if #Window.Tabs == 0 then
            task.spawn(function() Tab:Activate() end)
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
            makeCorner(SectionFrame, 6)
            makeStroke(SectionFrame, Theme.Border, 1)
            SectionFrame.Parent = Page

            local secHeader = Instance.new("Frame")
            secHeader.Size = UDim2.new(1, 0, 0, 22)
            secHeader.BackgroundTransparency = 1
            secHeader.Parent = SectionFrame

            local sTitle = Instance.new("TextLabel")
            sTitle.Size = UDim2.new(1, -16, 1, 0)
            sTitle.Position = UDim2.new(0, 8, 0, 0)
            sTitle.BackgroundTransparency = 1
            sTitle.Text = secTitle
            sTitle.TextColor3 = Theme.Text
            sTitle.TextSize = 9.5
            sTitle.Font = Enum.Font.GothamBold
            sTitle.TextXAlignment = Enum.TextXAlignment.Left
            sTitle.Parent = secHeader

            local contentHolder = Instance.new("Frame")
            contentHolder.Size = UDim2.new(1, 0, 0, 0)
            contentHolder.Position = UDim2.new(0, 0, 0, 22)
            contentHolder.AutomaticSize = Enum.AutomaticSize.Y
            contentHolder.BackgroundTransparency = 1
            contentHolder.Parent = SectionFrame

            local clayout = Instance.new("UIListLayout")
            clayout.SortOrder = Enum.SortOrder.LayoutOrder
            clayout.Padding = UDim.new(0, 5)
            clayout.Parent = contentHolder
            makePadding(contentHolder, 2, 6, 6, 6)

            local Section = {
                Frame = SectionFrame,
                Container = contentHolder
            }

            -- BUTTON
            function Section:AddButton(btnText, callback)
                callback = callback or function() end
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 25)
                btn.BackgroundColor3 = Theme.Surface
                btn.Text = btnText
                btn.TextColor3 = Theme.Text
                btn.TextSize = 9.5
                btn.Font = Enum.Font.GothamBold
                makeCorner(btn, 5)
                makeStroke(btn, Theme.Border, 1)
                btn.Parent = contentHolder

                btn.MouseButton1Click:Connect(callback)
                return btn
            end

            -- TOGGLE
            function Section:AddToggle(toggleConfig, callback)
                local tName = type(toggleConfig) == "table" and toggleConfig.Name or tostring(toggleConfig)
                local defaultVal = type(toggleConfig) == "table" and toggleConfig.Default or false
                callback = callback or (type(toggleConfig) == "table" and toggleConfig.Callback) or function() end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 24)
                row.BackgroundTransparency = 1
                row.Parent = contentHolder

                local tLbl = Instance.new("TextLabel")
                tLbl.Size = UDim2.new(1, -36, 1, 0)
                tLbl.BackgroundTransparency = 1
                tLbl.Text = tName
                tLbl.TextColor3 = Theme.Text
                tLbl.TextSize = 9.5
                tLbl.Font = Enum.Font.GothamSemibold
                tLbl.TextXAlignment = Enum.TextXAlignment.Left
                tLbl.Parent = row

                local switch = Instance.new("Frame")
                switch.Size = UDim2.new(0, 28, 0, 16)
                switch.Position = UDim2.new(1, -28, 0.5, -8)
                switch.BackgroundColor3 = defaultVal and Theme.Accent or Theme.Input
                makeCorner(switch, 8)
                makeStroke(switch, Theme.Border, 1)
                switch.Parent = row

                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 10, 0, 10)
                dot.Position = defaultVal and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
                dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                makeCorner(dot, 5)
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
                    fastTween(dot, {Position = state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)}, 0.2)
                    pcall(callback, state)
                end

                trigger.MouseButton1Click:Connect(function()
                    ToggleObj:Set(not state)
                end)

                return ToggleObj
            end

            -- SLIDER
            function Section:AddSlider(sliderConfig, callback)
                local sName = sliderConfig.Name or "Slider"
                local minVal = sliderConfig.Min or 0
                local maxVal = sliderConfig.Max or 100
                local defVal = sliderConfig.Default or minVal
                local valSuffix = sliderConfig.Suffix or ""
                callback = callback or function() end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 32)
                row.BackgroundTransparency = 1
                row.Parent = contentHolder

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -40, 0, 12)
                title.BackgroundTransparency = 1
                title.Text = sName
                title.TextColor3 = Theme.Text
                title.TextSize = 9
                title.Font = Enum.Font.GothamSemibold
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = row

                local valLbl = Instance.new("TextLabel")
                valLbl.Size = UDim2.new(0, 40, 0, 12)
                valLbl.Position = UDim2.new(1, -40, 0, 0)
                valLbl.BackgroundTransparency = 1
                valLbl.Text = tostring(defVal) .. valSuffix
                valLbl.TextColor3 = Theme.Accent
                valLbl.TextSize = 9
                valLbl.Font = Enum.Font.GothamBold
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.Parent = row

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, 0, 0, 4)
                track.Position = UDim2.new(0, 0, 0, 18)
                track.BackgroundColor3 = Theme.Input
                makeCorner(track, 2)
                track.Parent = row

                local fill = Instance.new("Frame")
                local initPct = math.clamp((defVal - minVal) / (maxVal - minVal), 0, 1)
                fill.Size = UDim2.new(initPct, 0, 1, 0)
                fill.BackgroundColor3 = Theme.Accent
                makeCorner(fill, 2)
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

            -- TEXT INPUT
            function Section:AddInput(inputConfig, callback)
                local iName = inputConfig.Name or "Input"
                local placeholder = inputConfig.Placeholder or "Enter text..."
                local defaultVal = inputConfig.Default or ""
                callback = callback or function() end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 38)
                row.BackgroundTransparency = 1
                row.Parent = contentHolder

                local iLbl = Instance.new("TextLabel")
                iLbl.Size = UDim2.new(1, 0, 0, 12)
                iLbl.BackgroundTransparency = 1
                iLbl.Text = iName
                iLbl.TextColor3 = Theme.TextSub
                iLbl.TextSize = 8.5
                iLbl.Font = Enum.Font.GothamBold
                iLbl.TextXAlignment = Enum.TextXAlignment.Left
                iLbl.Parent = row

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(1, 0, 0, 22)
                box.Position = UDim2.new(0, 0, 0, 14)
                box.BackgroundColor3 = Theme.Input
                box.Text = tostring(defaultVal)
                box.PlaceholderText = placeholder
                box.TextColor3 = Theme.Text
                box.PlaceholderColor3 = Theme.TextDim
                box.TextSize = 9.5
                box.Font = Enum.Font.Gotham
                box.ClearTextOnFocus = false
                makeCorner(box, 5)
                makeStroke(box, Theme.Border, 1)
                box.Parent = row

                box.FocusLost:Connect(function(enterPressed)
                    pcall(callback, box.Text, enterPressed)
                end)

                return {
                    Get = function() return box.Text end,
                    Set = function(_, text) box.Text = tostring(text) end
                }
            end

            -- DROPDOWN (SINGLE & MULTI)
            function Section:AddDropdown(dropdownConfig, callback)
                local dName = dropdownConfig.Name or "Dropdown"
                local options = dropdownConfig.Options or {}
                local isMulti = dropdownConfig.MultiSelect or false
                local defaultVal = dropdownConfig.Default or (isMulti and {} or options[1])
                callback = callback or function() end

                local dropFrame = Instance.new("Frame")
                dropFrame.Size = UDim2.new(1, 0, 0, 38)
                dropFrame.BackgroundTransparency = 1
                dropFrame.ClipsDescendants = true
                dropFrame.Parent = contentHolder

                local dLbl = Instance.new("TextLabel")
                dLbl.Size = UDim2.new(1, 0, 0, 12)
                dLbl.BackgroundTransparency = 1
                dLbl.Text = dName
                dLbl.TextColor3 = Theme.TextSub
                dLbl.TextSize = 8.5
                dLbl.Font = Enum.Font.GothamBold
                dLbl.TextXAlignment = Enum.TextXAlignment.Left
                dLbl.Parent = dropFrame

                local box = Instance.new("TextButton")
                box.Size = UDim2.new(1, 0, 0, 22)
                box.Position = UDim2.new(0, 0, 0, 14)
                box.BackgroundColor3 = Theme.Input
                box.Text = ""
                makeCorner(box, 5)
                makeStroke(box, Theme.Border, 1)
                box.Parent = dropFrame

                local selectedText = Instance.new("TextLabel")
                selectedText.Size = UDim2.new(1, -22, 1, 0)
                selectedText.Position = UDim2.new(0, 6, 0, 0)
                selectedText.BackgroundTransparency = 1
                selectedText.Text = isMulti and (type(defaultVal) == "table" and table.concat(defaultVal, ", ") or "None") or tostring(defaultVal or "")
                selectedText.TextColor3 = Theme.Text
                selectedText.TextSize = 9
                selectedText.Font = Enum.Font.GothamSemibold
                selectedText.TextXAlignment = Enum.TextXAlignment.Left
                selectedText.Parent = box

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 16, 1, 0)
                arrow.Position = UDim2.new(1, -16, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Text = "▼"
                arrow.TextColor3 = Theme.TextSub
                arrow.TextSize = 8
                arrow.Parent = box

                local optionList = Instance.new("ScrollingFrame")
                optionList.Size = UDim2.new(1, 0, 0, 80)
                optionList.Position = UDim2.new(0, 0, 0, 40)
                optionList.BackgroundColor3 = Theme.Surface
                optionList.ScrollBarThickness = 2
                optionList.CanvasSize = UDim2.new(0, 0, 0, #options * 22)
                makeCorner(optionList, 5)
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
                        optBtn.Size = UDim2.new(1, 0, 0, 22)
                        optBtn.BackgroundColor3 = Theme.Surface
                        optBtn.BackgroundTransparency = 1
                        optBtn.Text = "  " .. tostring(opt)
                        optBtn.TextColor3 = Theme.TextSub
                        optBtn.TextSize = 9
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
                                fastTween(dropFrame, {Size = UDim2.new(1, 0, 0, 38)}, 0.18)
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
                    fastTween(dropFrame, {Size = isOpen and UDim2.new(1, 0, 0, 126) or UDim2.new(1, 0, 0, 38)}, 0.18)
                end)

                local DropdownObj = {}
                function DropdownObj:Get()
                    return selected
                end
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

            -- TARGET PLAYER SELECTOR WITH HEADSHOT
            function Section:AddTargetSelector(callback)
                callback = callback or function() end

                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, 0, 0, 38)
                card.BackgroundColor3 = Theme.Input
                makeCorner(card, 5)
                makeStroke(card, Theme.Border, 1)
                card.Parent = contentHolder

                local tAvatar = Instance.new("ImageLabel")
                tAvatar.Size = UDim2.new(0, 26, 0, 26)
                tAvatar.Position = UDim2.new(0, 5, 0.5, -13)
                tAvatar.BackgroundColor3 = Theme.Surface
                tAvatar.Image = "rbxassetid://0"
                makeCorner(tAvatar, 13)
                tAvatar.Parent = card

                local selectBtn = Instance.new("TextButton")
                selectBtn.Size = UDim2.new(1, -38, 1, 0)
                selectBtn.Position = UDim2.new(0, 36, 0, 0)
                selectBtn.BackgroundTransparency = 1
                selectBtn.Text = "Select Target Player..."
                selectBtn.TextColor3 = Theme.Text
                selectBtn.TextSize = 9.5
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
                        MiRaGe:Notify({Title = "No Targets", Content = "No other players in server!", Type = "Warn"})
                    end
                end)

                return {
                    GetTarget = function() return targetUser end,
                    SetTarget = updateTarget
                }
            end

            -- PARAGRAPH / STAT CARD
            function Section:AddParagraph(title, desc)
                local box = Instance.new("Frame")
                box.Size = UDim2.new(1, 0, 0, 0)
                box.AutomaticSize = Enum.AutomaticSize.Y
                box.BackgroundColor3 = Theme.Input
                makeCorner(box, 5)
                makePadding(box, 5, 5, 6, 6)
                box.Parent = contentHolder

                local tLbl = Instance.new("TextLabel")
                tLbl.Size = UDim2.new(1, 0, 0, 12)
                tLbl.BackgroundTransparency = 1
                tLbl.Text = title
                tLbl.TextColor3 = Theme.Text
                tLbl.TextSize = 9
                tLbl.Font = Enum.Font.GothamBold
                tLbl.TextXAlignment = Enum.TextXAlignment.Left
                tLbl.Parent = box

                local dLbl = Instance.new("TextLabel")
                dLbl.Size = UDim2.new(1, 0, 0, 0)
                dLbl.AutomaticSize = Enum.AutomaticSize.Y
                dLbl.Position = UDim2.new(0, 0, 0, 13)
                dLbl.BackgroundTransparency = 1
                dLbl.Text = desc
                dLbl.TextColor3 = Theme.TextSub
                dLbl.TextSize = 8.5
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

            -- PROGRESS BAR
            function Section:AddProgressBar(title)
                local box = Instance.new("Frame")
                box.Size = UDim2.new(1, 0, 0, 32)
                box.BackgroundTransparency = 1
                box.Parent = contentHolder

                local tLbl = Instance.new("TextLabel")
                tLbl.Size = UDim2.new(1, -40, 0, 12)
                tLbl.BackgroundTransparency = 1
                tLbl.Text = title or "Progress"
                tLbl.TextColor3 = Theme.Text
                tLbl.TextSize = 9
                tLbl.Font = Enum.Font.GothamBold
                tLbl.TextXAlignment = Enum.TextXAlignment.Left
                tLbl.Parent = box

                local pctLbl = Instance.new("TextLabel")
                pctLbl.Size = UDim2.new(0, 40, 0, 12)
                pctLbl.Position = UDim2.new(1, -40, 0, 0)
                pctLbl.BackgroundTransparency = 1
                pctLbl.Text = "0%"
                pctLbl.TextColor3 = Theme.Accent
                pctLbl.TextSize = 9
                pctLbl.Font = Enum.Font.GothamBold
                pctLbl.TextXAlignment = Enum.TextXAlignment.Right
                pctLbl.Parent = box

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, 0, 0, 4)
                track.Position = UDim2.new(0, 0, 0, 16)
                track.BackgroundColor3 = Theme.Input
                makeCorner(track, 2)
                track.Parent = box

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = Theme.Accent
                makeCorner(fill, 2)
                fill.Parent = track
                local fgrad = Instance.new("UIGradient")
                fgrad.Color = Theme.Grad1
                fgrad.Parent = fill

                return {
                    Set = function(_, pct, customText)
                        local clamped = math.clamp(pct, 0, 1)
                        fastTween(fill, {Size = UDim2.new(clamped, 0, 1, 0)}, 0.2)
                        pctLbl.Text = customText or (math.floor(clamped * 100) .. "%")
                    end
                }
            end

            -- CONSOLE LOG TERMINAL
            function Section:AddConsole(consoleTitle)
                local cFrame = Instance.new("Frame")
                cFrame.Size = UDim2.new(1, 0, 0, 110)
                cFrame.BackgroundColor3 = Color3.fromRGB(4, 6, 10)
                makeCorner(cFrame, 5)
                makeStroke(cFrame, Theme.Border, 1)
                cFrame.Parent = contentHolder

                local cheader = Instance.new("Frame")
                cheader.Size = UDim2.new(1, 0, 0, 18)
                cheader.BackgroundTransparency = 1
                cheader.Parent = cFrame

                local ctitle = Instance.new("TextLabel")
                ctitle.Size = UDim2.new(1, -45, 1, 0)
                ctitle.Position = UDim2.new(0, 5, 0, 0)
                ctitle.BackgroundTransparency = 1
                ctitle.Text = consoleTitle or "Console Logs"
                ctitle.TextColor3 = Theme.TextSub
                ctitle.TextSize = 8.5
                ctitle.Font = Enum.Font.GothamBold
                ctitle.TextXAlignment = Enum.TextXAlignment.Left
                ctitle.Parent = cheader

                local clearBtn = Instance.new("TextButton")
                clearBtn.Size = UDim2.new(0, 32, 0, 14)
                clearBtn.Position = UDim2.new(1, -36, 0.5, -7)
                clearBtn.BackgroundColor3 = Theme.Card
                clearBtn.Text = "Clear"
                clearBtn.TextColor3 = Theme.TextSub
                clearBtn.TextSize = 7.5
                clearBtn.Font = Enum.Font.Gotham
                makeCorner(clearBtn, 3)
                clearBtn.Parent = cheader

                local logScroll = Instance.new("ScrollingFrame")
                logScroll.Size = UDim2.new(1, -6, 1, -20)
                logScroll.Position = UDim2.new(0, 3, 0, 18)
                logScroll.BackgroundTransparency = 1
                logScroll.ScrollBarThickness = 2
                logScroll.ScrollBarImageColor3 = Theme.Accent
                logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                logScroll.Parent = cFrame

                local logLayout = Instance.new("UIListLayout")
                logLayout.SortOrder = Enum.SortOrder.LayoutOrder
                logLayout.Padding = UDim.new(0, 2)
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
                    line.Size = UDim2.new(1, 0, 0, 13)
                    line.BackgroundTransparency = 1
                    line.Text = string.format("[%s] %s", timeStr, tostring(msg))
                    line.TextColor3 = color
                    line.TextSize = 8.5
                    line.Font = Enum.Font.Code
                    line.TextXAlignment = Enum.TextXAlignment.Left
                    line.TextWrapped = true
                    line.Parent = logScroll

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
