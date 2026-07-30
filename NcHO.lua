--[[
    ========================================================
             Sigma UI Library - V4 ULTIMATE EDITION            
      Bug Fixes + 22 New Features + Visual Overhaul            
      Features: MultiTheme, ColorPicker, KeySystem,            
      Collapsible, ConfigManager, DependencySystem,            
      ProgressBar, Stepper, MultiDropdown, Changelog,          
      AutoSave, BadgeTab, Notification Types, Animations       
    ========================================================
]]
-- =
--  CORE SERVICES
-- =
local Library = {
    Flags       = {},
    ConfigName  = "SigmaHub_Config",
    Theme       = nil,
    _elements   = {},   -- untuk dependency system
    _autoSave   = false,
    _autoSaveConn = nil,
}

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")

local function getSafeParent()
    if gethui then return gethui() end
    local ok, core = pcall(function() return CoreGui end)
    if ok and core then return core end
    return game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- ══════════════════════════════════════════
--  TEMA SISTEM (5 PRESET)
-- ══════════════════════════════════════════
local Themes = {
    Blue = {
        MainBg      = Color3.fromRGB(13, 14, 20),
        SidebarBg   = Color3.fromRGB(9,  10, 15),
        ElementBg   = Color3.fromRGB(25, 27, 38),
        ElementHover= Color3.fromRGB(35, 38, 52),
        Accent      = Color3.fromRGB(0,  170, 255),
        AccentDark  = Color3.fromRGB(0,  100, 180),
        Success     = Color3.fromRGB(60, 210, 130),
        Warning     = Color3.fromRGB(255, 190, 50),
        Error       = Color3.fromRGB(255, 80,  80),
        Info        = Color3.fromRGB(80,  170, 255),
        Text        = Color3.fromRGB(230, 235, 245),
        TextDim     = Color3.fromRGB(130, 140, 165),
        Border      = Color3.fromRGB(35,  40,  60),
        Transparency= 0.04,
        Radius      = UDim.new(0, 7),
    },
    Red = {
        MainBg      = Color3.fromRGB(18, 12, 12),
        SidebarBg   = Color3.fromRGB(12, 8,  8),
        ElementBg   = Color3.fromRGB(35, 22, 22),
        ElementHover= Color3.fromRGB(48, 30, 30),
        Accent      = Color3.fromRGB(255, 70, 70),
        AccentDark  = Color3.fromRGB(180, 30, 30),
        Success     = Color3.fromRGB(60,  210, 130),
        Warning     = Color3.fromRGB(255, 190, 50),
        Error       = Color3.fromRGB(255, 80,  80),
        Info        = Color3.fromRGB(80,  170, 255),
        Text        = Color3.fromRGB(240, 230, 230),
        TextDim     = Color3.fromRGB(160, 130, 130),
        Border      = Color3.fromRGB(60,  30,  30),
        Transparency= 0.04,
        Radius      = UDim.new(0, 7),
    },
    Purple = {
        MainBg      = Color3.fromRGB(14, 12, 22),
        SidebarBg   = Color3.fromRGB(9,  8,  16),
        ElementBg   = Color3.fromRGB(28, 24, 45),
        ElementHover= Color3.fromRGB(40, 34, 62),
        Accent      = Color3.fromRGB(160, 90, 255),
        AccentDark  = Color3.fromRGB(100, 50, 200),
        Success     = Color3.fromRGB(60,  210, 130),
        Warning     = Color3.fromRGB(255, 190, 50),
        Error       = Color3.fromRGB(255, 80,  80),
        Info        = Color3.fromRGB(80,  170, 255),
        Text        = Color3.fromRGB(235, 230, 248),
        TextDim     = Color3.fromRGB(140, 130, 170),
        Border      = Color3.fromRGB(50,  35,  80),
        Transparency= 0.04,
        Radius      = UDim.new(0, 7),
    },
    Green = {
        MainBg      = Color3.fromRGB(10, 17, 13),
        SidebarBg   = Color3.fromRGB(6,  12, 9),
        ElementBg   = Color3.fromRGB(18, 32, 24),
        ElementHover= Color3.fromRGB(26, 44, 34),
        Accent      = Color3.fromRGB(50,  210, 120),
        AccentDark  = Color3.fromRGB(20,  140, 70),
        Success     = Color3.fromRGB(60,  210, 130),
        Warning     = Color3.fromRGB(255, 190, 50),
        Error       = Color3.fromRGB(255, 80,  80),
        Info        = Color3.fromRGB(80,  170, 255),
        Text        = Color3.fromRGB(225, 240, 228),
        TextDim     = Color3.fromRGB(130, 155, 135),
        Border      = Color3.fromRGB(25,  60,  35),
        Transparency= 0.04,
        Radius      = UDim.new(0, 7),
    },
    Orange = {
        MainBg      = Color3.fromRGB(18, 14, 9),
        SidebarBg   = Color3.fromRGB(12, 9,  5),
        ElementBg   = Color3.fromRGB(35, 26, 15),
        ElementHover= Color3.fromRGB(50, 36, 20),
        Accent      = Color3.fromRGB(255, 150, 30),
        AccentDark  = Color3.fromRGB(200, 100, 10),
        Success     = Color3.fromRGB(60,  210, 130),
        Warning     = Color3.fromRGB(255, 190, 50),
        Error       = Color3.fromRGB(255, 80,  80),
        Info        = Color3.fromRGB(80,  170, 255),
        Text        = Color3.fromRGB(245, 238, 225),
        TextDim     = Color3.fromRGB(165, 148, 120),
        Border      = Color3.fromRGB(60,  40,  15),
        Transparency= 0.04,
        Radius      = UDim.new(0, 7),
    },
}

local Theme = Themes.Blue  -- Default tema

-- ══════════════════════════════════════════
--  THEME API
-- ══════════════════════════════════════════
function Library:SetTheme(name)
    if not Themes[name] then return end
    Theme = Themes[name]
    Library.Theme = Theme
    -- Trigger semua callback theme change
    if Library._themeCallbacks then
        for _, cb in ipairs(Library._themeCallbacks) do pcall(cb, Theme) end
    end
end

Library._themeCallbacks = {}
function Library:OnThemeChange(cb)
    table.insert(Library._themeCallbacks, cb)
end

Library.Theme = Theme

-- ══════════════════════════════════════════
--  POLYFILLS (for Lua 5.1 executor compat)
-- ══════════════════════════════════════════
if not table.find then
    table.find = function(t, val)
        for i, v in ipairs(t) do
            if v == val then return i end
        end
        return nil
    end
end

if not task then
    task = {
        wait  = wait,
        spawn = spawn,
        defer = function(f, ...) 
            local args = {...}
            spawn(function() f(unpack(args)) end) 
        end,
        delay = function(t, f) delay(t, f) end,
    }
end

-- ══════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ══════════════════════════════════════════

local function Tween(obj, t, props, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir   = dir   or Enum.EasingDirection.Out
    return TweenService:Create(obj, TweenInfo.new(t, style, dir), props)
end

local function MakeDraggable(dragPoint, objectToMove)
    local dragging = false
    local dragInput, mousePos, framePos

    dragPoint.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            mousePos  = input.Position
            framePos  = objectToMove.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragPoint.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            Tween(objectToMove, 0.07, {
                Position = UDim2.new(
                    framePos.X.Scale, framePos.X.Offset + delta.X,
                    framePos.Y.Scale, framePos.Y.Offset + delta.Y
                )
            }):Play()
        end
    end)
end

local function CreateRipple(parent, inputPos)
    local ripple = Instance.new("Frame")
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.75
    ripple.BorderSizePixel = 0
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

    local x = inputPos.X - parent.AbsolutePosition.X
    local y = inputPos.Y - parent.AbsolutePosition.Y
    ripple.Position = UDim2.new(0, x, 0, y)
    ripple.Size     = UDim2.new(0, 0, 0, 0)
    ripple.ZIndex   = parent.ZIndex + 5
    ripple.Parent   = parent

    local endSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    local tw = Tween(ripple, 0.45, {
        Size                 = UDim2.new(0, endSize, 0, endSize),
        Position             = UDim2.new(0, x - endSize/2, 0, y - endSize/2),
        BackgroundTransparency = 1
    }, Enum.EasingStyle.Quad)
    tw:Play()
    tw.Completed:Connect(function() ripple:Destroy() end)
end

local function HsvToRgb(h, s, v)
    if s == 0 then return Color3.new(v, v, v) end
    local i  = math.floor(h * 6)
    local f  = h * 6 - i
    local p, q, t_ = v*(1-s), v*(1-f*s), v*(1-(1-f)*s)
    i = i % 6
    if i == 0 then return Color3.new(v, t_, p)
    elseif i == 1 then return Color3.new(q, v, p)
    elseif i == 2 then return Color3.new(p, v, t_)
    elseif i == 3 then return Color3.new(p, q, v)
    elseif i == 4 then return Color3.new(t_, p, v)
    else return Color3.new(v, p, q) end
end

local function RgbToHsv(c)
    local r, g, b = c.R, c.G, c.B
    local max_, min_ = math.max(r,g,b), math.min(r,g,b)
    local d = max_ - min_
    local h, s = 0, max_ == 0 and 0 or d/max_
    if d ~= 0 then
        if max_ == r then h = (g-b)/d % 6
        elseif max_ == g then h = (b-r)/d + 2
        else h = (r-g)/d + 4 end
        h = h / 6
    end
    return h, s, max_
end

-- ══════════════════════════════════════════
--  NOTIFICATION SYSTEM (V2 — Typed)
-- ══════════════════════════════════════════
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "SigmaUI_Notifs"
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotifGui.Parent = getSafeParent()

local NotifHolder = Instance.new("Frame")
NotifHolder.Size     = UDim2.new(0, 280, 1, -20)
NotifHolder.Position = UDim2.new(1, -300, 0, 10)
NotifHolder.BackgroundTransparency = 1
NotifHolder.Parent = NotifGui

local NotifList = Instance.new("UIListLayout")
NotifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifList.Padding           = UDim.new(0, 8)
NotifList.Parent            = NotifHolder

--[[
    Library:Notify({
        Title    = "Title",
        Content  = "Message",
        Type     = "Info" | "Success" | "Warning" | "Error",
        Duration = 3,
    })
    OR old syntax:
    Library:Notify(title, content, duration)
]]
function Library:Notify(titleOrConfig, content, duration)
    local cfg = {}
    if type(titleOrConfig) == "table" then
        cfg = titleOrConfig
    else
        cfg.Title    = titleOrConfig
        cfg.Content  = content
        cfg.Duration = duration
        cfg.Type     = "Info"
    end

    local typeColors = {
        Info    = Theme.Info    or Color3.fromRGB(80, 170, 255),
        Success = Theme.Success or Color3.fromRGB(60, 210, 130),
        Warning = Theme.Warning or Color3.fromRGB(255, 190, 50),
        Error   = Theme.Error   or Color3.fromRGB(255, 80,  80),
    }
    local typeIcons = { Info="ℹ", Success="✔", Warning="⚠", Error="✖" }
    local nType  = cfg.Type or "Info"
    local dur    = cfg.Duration or 4
    local color  = typeColors[nType] or typeColors.Info
    local icon   = typeIcons[nType]  or "ℹ"

    local NF = Instance.new("Frame")
    NF.Size                  = UDim2.new(1, 0, 0, 72)
    NF.BackgroundColor3      = Theme.SidebarBg
    NF.BackgroundTransparency= Theme.Transparency
    NF.Position              = UDim2.new(1, 310, 0, 0)
    NF.Parent                = NotifHolder
    NF.ClipsDescendants      = true
    Instance.new("UICorner", NF).CornerRadius = Theme.Radius
    local NFStroke = Instance.new("UIStroke", NF)
    NFStroke.Color     = color
    NFStroke.Thickness = 1.5

    -- Accent bar kiri
    local Bar = Instance.new("Frame", NF)
    Bar.Size             = UDim2.new(0, 3, 1, 0)
    Bar.BackgroundColor3 = color
    Bar.BorderSizePixel  = 0
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(0, 3)

    -- Icon
    local IcoLbl = Instance.new("TextLabel", NF)
    IcoLbl.Size     = UDim2.new(0, 28, 0, 28)
    IcoLbl.Position = UDim2.new(0, 12, 0, 8)
    IcoLbl.BackgroundColor3 = color
    IcoLbl.BackgroundTransparency = 0.8
    IcoLbl.Text      = icon
    IcoLbl.TextColor3= color
    IcoLbl.Font      = Enum.Font.GothamBold
    IcoLbl.TextSize  = 14
    Instance.new("UICorner", IcoLbl).CornerRadius = UDim.new(0, 6)

    -- Title
    local NTitle = Instance.new("TextLabel", NF)
    NTitle.Size     = UDim2.new(1, -60, 0, 18)
    NTitle.Position = UDim2.new(0, 48, 0, 8)
    NTitle.BackgroundTransparency = 1
    NTitle.Text      = cfg.Title or nType
    NTitle.TextColor3= color
    NTitle.Font      = Enum.Font.GothamBold
    NTitle.TextSize  = 13
    NTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Content
    local NContent = Instance.new("TextLabel", NF)
    NContent.Size     = UDim2.new(1, -55, 0, 28)
    NContent.Position = UDim2.new(0, 48, 0, 28)
    NContent.BackgroundTransparency = 1
    NContent.Text      = cfg.Content or ""
    NContent.TextColor3= Theme.Text
    NContent.Font      = Enum.Font.Gotham
    NContent.TextSize  = 11
    NContent.TextXAlignment  = Enum.TextXAlignment.Left
    NContent.TextWrapped     = true

    -- Close Button
    local CloseBtn = Instance.new("TextButton", NF)
    CloseBtn.Size   = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position= UDim2.new(1, -24, 0, 4)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text   = "✕"
    CloseBtn.TextColor3 = Theme.TextDim
    CloseBtn.TextSize   = 12

    -- Progress bar countdown
    local ProgBg = Instance.new("Frame", NF)
    ProgBg.Size  = UDim2.new(1, 0, 0, 3)
    ProgBg.Position = UDim2.new(0, 0, 1, -3)
    ProgBg.BackgroundColor3 = Theme.ElementBg
    ProgBg.BorderSizePixel  = 0
    local ProgFill = Instance.new("Frame", ProgBg)
    ProgFill.Size  = UDim2.new(1, 0, 1, 0)
    ProgFill.BackgroundColor3 = color
    ProgFill.BorderSizePixel  = 0

    -- Slide in
    Tween(NF, 0.4, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back):Play()

    local closed = false
    local function closeNotif()
        if closed then return end
        closed = true
        local tw = Tween(NF, 0.35, {Position = UDim2.new(1, 310, 0, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tw:Play()
        tw.Completed:Connect(function() NF:Destroy() end)
    end

    CloseBtn.MouseButton1Click:Connect(closeNotif)

    -- Countdown progress bar
    Tween(ProgFill, dur, {Size = UDim2.new(0, 0, 1, 0)}, Enum.EasingStyle.Linear):Play()
    task.delay(dur, closeNotif)
end

-- ══════════════════════════════════════════
--  KEY SYSTEM
-- ══════════════════════════════════════════
function Library:KeySystem(config)
    -- config = { Key = "abc123", Title = "...", Subtitle = "..." }
    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name   = "SigmaUI_KeySystem"
    KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeyGui.Parent = getSafeParent()

    -- Overlay backdrop
    local Backdrop = Instance.new("Frame", KeyGui)
    Backdrop.Size  = UDim2.new(1, 0, 1, 0)
    Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Backdrop.BackgroundTransparency = 0.4
    Backdrop.BorderSizePixel = 0

    local Box = Instance.new("Frame", KeyGui)
    Box.Size     = UDim2.new(0, 340, 0, 200)
    Box.Position = UDim2.new(0.5, -170, 0.5, -100)
    Box.BackgroundColor3 = Theme.MainBg
    Box.BackgroundTransparency = Theme.Transparency
    Box.BorderSizePixel = 0
    Box.AnchorPoint = Vector2.new(0.5, 0.5)
    Instance.new("UICorner", Box).CornerRadius = Theme.Radius
    local BoxStroke = Instance.new("UIStroke", Box)
    BoxStroke.Color     = Theme.Accent
    BoxStroke.Thickness = 1.5

    -- Entrance animation
    Box.Size = UDim2.new(0, 0, 0, 0)
    Box.Position = UDim2.new(0.5, 0, 0.5, 0)
    Tween(Box, 0.4, {
        Size     = UDim2.new(0, 340, 0, 200),
        Position = UDim2.new(0.5, -170, 0.5, -100)
    }, Enum.EasingStyle.Back):Play()

    local Logo = Instance.new("TextLabel", Box)
    Logo.Size  = UDim2.new(1, 0, 0, 40)
    Logo.Position = UDim2.new(0, 0, 0, 15)
    Logo.BackgroundTransparency = 1
    Logo.Text  = config.Title or "🔐 Key Required"
    Logo.TextColor3 = Theme.Accent
    Logo.Font  = Enum.Font.GothamBlack
    Logo.TextSize   = 18

    local Sub = Instance.new("TextLabel", Box)
    Sub.Size   = UDim2.new(1, -30, 0, 20)
    Sub.Position = UDim2.new(0, 15, 0, 55)
    Sub.BackgroundTransparency = 1
    Sub.Text   = config.Subtitle or "Enter your key to continue"
    Sub.TextColor3 = Theme.TextDim
    Sub.Font   = Enum.Font.Gotham
    Sub.TextSize    = 12
    Sub.TextXAlignment = Enum.TextXAlignment.Center

    local InputBox = Instance.new("TextBox", Box)
    InputBox.Size   = UDim2.new(1, -30, 0, 36)
    InputBox.Position = UDim2.new(0, 15, 0, 85)
    InputBox.BackgroundColor3 = Theme.ElementBg
    InputBox.BorderSizePixel  = 0
    InputBox.Text  = ""
    InputBox.PlaceholderText  = "Enter key here..."
    InputBox.TextColor3       = Theme.Text
    InputBox.PlaceholderColor3= Theme.TextDim
    InputBox.Font      = Enum.Font.Gotham
    InputBox.TextSize  = 13
    Instance.new("UICorner", InputBox).CornerRadius = Theme.Radius
    local InputPad = Instance.new("UIPadding", InputBox)
    InputPad.PaddingLeft = UDim.new(0, 12)
    local InputStroke = Instance.new("UIStroke", InputBox)
    InputStroke.Color     = Theme.Border
    InputStroke.Thickness = 1
    InputBox.Focused:Connect(function()
        Tween(InputStroke, 0.2, {Color = Theme.Accent, Thickness = 1.5}):Play()
    end)
    InputBox.FocusLost:Connect(function()
        Tween(InputStroke, 0.2, {Color = Theme.Border, Thickness = 1}):Play()
    end)

    local ErrLbl = Instance.new("TextLabel", Box)
    ErrLbl.Size   = UDim2.new(1, -30, 0, 16)
    ErrLbl.Position = UDim2.new(0, 15, 0, 128)
    ErrLbl.BackgroundTransparency = 1
    ErrLbl.Text   = ""
    ErrLbl.TextColor3 = Theme.Error
    ErrLbl.Font   = Enum.Font.GothamBold
    ErrLbl.TextSize    = 11
    ErrLbl.TextXAlignment = Enum.TextXAlignment.Center

    local ConfirmBtn = Instance.new("TextButton", Box)
    ConfirmBtn.Size   = UDim2.new(1, -30, 0, 34)
    ConfirmBtn.Position = UDim2.new(0, 15, 0, 150)
    ConfirmBtn.BackgroundColor3 = Theme.Accent
    ConfirmBtn.Text   = "Confirm"
    ConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ConfirmBtn.Font   = Enum.Font.GothamBold
    ConfirmBtn.TextSize    = 13
    Instance.new("UICorner", ConfirmBtn).CornerRadius = Theme.Radius
    ConfirmBtn.MouseEnter:Connect(function()
        Tween(ConfirmBtn, 0.15, {BackgroundColor3 = Theme.AccentDark}):Play()
    end)
    ConfirmBtn.MouseLeave:Connect(function()
        Tween(ConfirmBtn, 0.15, {BackgroundColor3 = Theme.Accent}):Play()
    end)

    local success = false
    ConfirmBtn.MouseButton1Click:Connect(function()
        if InputBox.Text == config.Key then
            success = true
            Tween(Box, 0.3, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
            task.delay(0.35, function()
                KeyGui:Destroy()
                Library:Notify({Title="Key Accepted", Content="Access granted!", Type="Success", Duration=3})
            end)
        else
            ErrLbl.Text = "❌ Incorrect key — try again"
            Tween(InputStroke, 0, {Color = Theme.Error, Thickness = 1.5}):Play()
            task.delay(2, function()
                ErrLbl.Text = ""
                Tween(InputStroke, 0.2, {Color = Theme.Border, Thickness = 1}):Play()
            end)
        end
    end)

    -- Wait for key confirmation
    repeat task.wait(0.1) until success or not KeyGui.Parent
    return success
end

-- ══════════════════════════════════════════
--  MAIN WINDOW
-- ══════════════════════════════════════════
function Library:CreateWindow(config)
    local titleText  = config.Name       or "Sigma Hub"
    local footerText = config.Footer     or "discord.gg/sigma | v4.0"
    local logoIcon   = config.LogoText   or "Σ"
    local toggleKey  = config.ToggleKey  or Enum.KeyCode.RightShift
    self.ConfigName  = config.ConfigName or "SigmaHub_Config"

    -- Cleanup existing
    local parent = getSafeParent()
    if parent:FindFirstChild("SigmaUI") then
        parent.SigmaUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name             = "SigmaUI"
    ScreenGui.ResetOnSpawn     = false
    ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent           = parent

    -- ── TOOLTIP SYSTEM ──────────────────────────
    local TooltipFrame = Instance.new("Frame", ScreenGui)
    TooltipFrame.Size             = UDim2.new(0, 200, 0, 30)
    TooltipFrame.BackgroundColor3 = Theme.ElementBg
    TooltipFrame.BackgroundTransparency = 0
    TooltipFrame.Visible          = false
    TooltipFrame.ZIndex           = 200
    TooltipFrame.BorderSizePixel  = 0
    Instance.new("UICorner", TooltipFrame).CornerRadius = Theme.Radius
    local TtStroke = Instance.new("UIStroke", TooltipFrame)
    TtStroke.Color     = Theme.Accent
    TtStroke.Thickness = 1
    local TooltipLabel = Instance.new("TextLabel", TooltipFrame)
    TooltipLabel.Size             = UDim2.new(1, -14, 1, 0)
    TooltipLabel.Position         = UDim2.new(0, 7, 0, 0)
    TooltipLabel.BackgroundTransparency = 1
    TooltipLabel.TextColor3       = Theme.Text
    TooltipLabel.Font             = Enum.Font.Gotham
    TooltipLabel.TextSize         = 11
    TooltipLabel.TextWrapped      = true
    TooltipLabel.ZIndex           = 201

    RunService.RenderStepped:Connect(function()
        if TooltipFrame.Visible then
            local mp = UserInputService:GetMouseLocation()
            TooltipFrame.Position = UDim2.new(0, mp.X + 14, 0, mp.Y - 38)
        end
    end)

    local function AddTooltip(el, text)
        if not text or text == "" then return end
        local hovering = false
        el.MouseEnter:Connect(function()
            hovering = true
            task.wait(0.5)
            if hovering then
                TooltipLabel.Text = text
                local tw = TooltipLabel.TextBounds
                TooltipFrame.Size    = UDim2.new(0, tw.X + 18, 0, math.max(26, tw.Y + 12))
                TooltipFrame.Visible = true
            end
        end)
        el.MouseLeave:Connect(function()
            hovering = false
            TooltipFrame.Visible = false
        end)
    end

    -- ── WATERMARK ───────────────────────────────
    if config.Watermark then
        local WM = Instance.new("Frame", ScreenGui)
        WM.Size             = UDim2.new(0, 280, 0, 28)
        WM.Position         = UDim2.new(0, 20, 0, 20)
        WM.BackgroundColor3 = Theme.SidebarBg
        WM.BackgroundTransparency = Theme.Transparency
        WM.BorderSizePixel  = 0
        Instance.new("UICorner", WM).CornerRadius = Theme.Radius
        local WMStroke = Instance.new("UIStroke", WM)
        WMStroke.Color     = Theme.Accent
        WMStroke.Thickness = 1
        local WMLabel = Instance.new("TextLabel", WM)
        WMLabel.Size              = UDim2.new(1, -12, 1, 0)
        WMLabel.Position          = UDim2.new(0, 12, 0, 0)
        WMLabel.BackgroundTransparency = 1
        WMLabel.TextColor3        = Theme.Accent
        WMLabel.Font              = Enum.Font.GothamBold
        WMLabel.TextSize          = 11
        WMLabel.TextXAlignment    = Enum.TextXAlignment.Left
        MakeDraggable(WM, WM)

        -- FPS counter (FIXED — tidak pakai RenderStepped:Wait di dalam Connect)
        local lastTime = tick()
        local frameCount = 0
        local fps = 60
        RunService.RenderStepped:Connect(function()
            frameCount = frameCount + 1
            local now = tick()
            if now - lastTime >= 0.5 then
                fps = math.floor(frameCount / (now - lastTime))
                frameCount = 0
                lastTime = now
                local ok, ping = pcall(function()
                    return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                end)
                WMLabel.Text = titleText .. "  │  FPS: " .. fps .. "  │  Ping: " .. (ok and math.floor(ping) or "--") .. "ms"
            end
        end)
    end

    -- ── FLOATING BUTTON (minimized state) ───────
    local FloatBtn = Instance.new("TextButton", ScreenGui)
    FloatBtn.Size             = UDim2.new(0, 48, 0, 48)
    FloatBtn.Position         = UDim2.new(0, 22, 0.5, -24)
    FloatBtn.BackgroundColor3 = Theme.SidebarBg
    FloatBtn.Text             = logoIcon
    FloatBtn.TextColor3       = Theme.Accent
    FloatBtn.Font             = Enum.Font.GothamBlack
    FloatBtn.TextSize         = 22
    FloatBtn.Visible          = false
    FloatBtn.BorderSizePixel  = 0
    Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
    local FBStroke = Instance.new("UIStroke", FloatBtn)
    FBStroke.Color     = Theme.Accent
    FBStroke.Thickness = 2
    MakeDraggable(FloatBtn, FloatBtn)

    -- Status indicator LED inside Floating Button
    local FloatLED = Instance.new("Frame", FloatBtn)
    FloatLED.Name = "FloatLED"
    FloatLED.Size = UDim2.new(0, 10, 0, 10)
    FloatLED.Position = UDim2.new(1, -10, 0, 0)
    FloatLED.BackgroundColor3 = Theme.Accent
    FloatLED.BorderSizePixel = 0
    Instance.new("UICorner", FloatLED).CornerRadius = UDim.new(1, 0)
    local LEDStroke = Instance.new("UIStroke", FloatLED)
    LEDStroke.Color = Theme.SidebarBg
    LEDStroke.Thickness = 1.5

    -- Status text label under Floating Button
    local FloatLabel = Instance.new("TextLabel", FloatBtn)
    FloatLabel.Name = "FloatLabel"
    FloatLabel.Size = UDim2.new(0, 100, 0, 14)
    FloatLabel.Position = UDim2.new(0.5, -50, 1, 4)
    FloatLabel.BackgroundTransparency = 1
    FloatLabel.Text = ""
    FloatLabel.TextColor3 = Theme.Text
    FloatLabel.Font = Enum.Font.GothamSemibold
    FloatLabel.TextSize = 9
    FloatLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- ── MAIN FRAME ──────────────────────────────
    local MainFrame = Instance.new("Frame", ScreenGui)
    local vpSize = workspace.CurrentCamera.ViewportSize
    local width = math.min(520, vpSize.X - 20)
    local height = math.min(340, vpSize.Y - 20)
    local currentWidth = width
    local currentHeight = height
    local currentPos = UDim2.new(0.5, -width/2, 0.5, -height/2)
    MainFrame.Size             = UDim2.new(0, width, 0, height)
    MainFrame.Position         = currentPos
    MainFrame.BackgroundColor3 = Theme.MainBg
    MainFrame.BackgroundTransparency = Theme.Transparency
    MainFrame.BorderSizePixel  = 0
    MainFrame.ClipsDescendants = true
    Instance.new("UICorner", MainFrame).CornerRadius = Theme.Radius
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color     = Theme.Accent
    MainStroke.Thickness = 1.5

    -- Window open animation
    MainFrame.Size     = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    task.defer(function()
        Tween(MainFrame, 0.45, {
            Size     = UDim2.new(0, width, 0, height),
            Position = currentPos
        }, Enum.EasingStyle.Back):Play()
    end)

    -- ── SIDEBAR ─────────────────────────────────
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Size             = UDim2.new(0, 48, 1, 0)
    Sidebar.BackgroundColor3 = Theme.SidebarBg
    Sidebar.BackgroundTransparency = Theme.Transparency
    Sidebar.BorderSizePixel  = 0
    Instance.new("UICorner", Sidebar).CornerRadius = Theme.Radius

    -- Fix rounded corners on right side of sidebar
    local SbFix = Instance.new("Frame", Sidebar)
    SbFix.Size             = UDim2.new(0, 12, 1, 0)
    SbFix.Position         = UDim2.new(1, -12, 0, 0)
    SbFix.BackgroundColor3 = Theme.SidebarBg
    SbFix.BorderSizePixel  = 0

    local LogoLabel = Instance.new("TextLabel", Sidebar)
    LogoLabel.Size             = UDim2.new(1, 0, 0, 48)
    LogoLabel.BackgroundTransparency = 1
    LogoLabel.Text             = logoIcon
    LogoLabel.TextColor3       = Theme.Accent
    LogoLabel.Font             = Enum.Font.GothamBlack
    LogoLabel.TextSize         = 22

    local TabContainer = Instance.new("ScrollingFrame", Sidebar)
    TabContainer.Size             = UDim2.new(1, 0, 1, -48)
    TabContainer.Position         = UDim2.new(0, 0, 0, 48)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness     = 0
    TabContainer.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    TabContainer.CanvasSize             = UDim2.new(0, 0, 0, 0)
    local TabList = Instance.new("UIListLayout", TabContainer)
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabList.Padding             = UDim.new(0, 6)
    local TabPad = Instance.new("UIPadding", TabContainer)
    TabPad.PaddingTop = UDim.new(0, 4)

    -- ── TOPBAR ──────────────────────────────────
    local Topbar = Instance.new("Frame", MainFrame)
    Topbar.Size             = UDim2.new(1, -48, 0, 42)
    Topbar.Position         = UDim2.new(0, 48, 0, 0)
    Topbar.BackgroundTransparency = 1
    Topbar.BorderSizePixel  = 0
    MakeDraggable(Topbar, MainFrame)

    local TopbarGlow = Instance.new("Frame", Topbar)
    TopbarGlow.Name = "TopbarGlow"
    TopbarGlow.Size = UDim2.new(1, 0, 0, 1)
    TopbarGlow.Position = UDim2.new(0, 0, 1, 0)
    TopbarGlow.BackgroundColor3 = Theme.Accent
    TopbarGlow.BorderSizePixel = 0

    -- Title in topbar
    local TitleLabel = Instance.new("TextLabel", Topbar)
    TitleLabel.Size             = UDim2.new(0, 120, 1, 0)
    TitleLabel.Position         = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text             = titleText
    TitleLabel.TextColor3       = Theme.Accent
    TitleLabel.Font             = Enum.Font.GothamBold
    TitleLabel.TextSize         = 13
    TitleLabel.TextXAlignment   = Enum.TextXAlignment.Left

    -- Search Box
    local SearchBox = Instance.new("TextBox", Topbar)
    SearchBox.Size             = UDim2.new(1, -170, 0, 27)
    SearchBox.Position         = UDim2.new(0, 130, 0.5, -13)
    SearchBox.BackgroundColor3 = Theme.SidebarBg
    SearchBox.Text             = ""
    SearchBox.PlaceholderText  = "🔍  Search features..."
    SearchBox.TextColor3       = Theme.Text
    SearchBox.PlaceholderColor3= Theme.TextDim
    SearchBox.Font             = Enum.Font.Gotham
    SearchBox.TextSize         = 12
    SearchBox.TextXAlignment   = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.BorderSizePixel  = 0
    Instance.new("UICorner", SearchBox).CornerRadius = Theme.Radius
    local SBPad = Instance.new("UIPadding", SearchBox)
    SBPad.PaddingLeft = UDim.new(0, 10)
    local SBStroke = Instance.new("UIStroke", SearchBox)
    SBStroke.Color     = Theme.Border
    SBStroke.Thickness = 1
    SearchBox.Focused:Connect(function()
        Tween(SBStroke, 0.2, {Color = Theme.Accent, Thickness = 1.5}):Play()
    end)
    SearchBox.FocusLost:Connect(function()
        Tween(SBStroke, 0.2, {Color = Theme.Border, Thickness = 1}):Play()
    end)

    -- Minimize Button
    local MinBtn = Instance.new("TextButton", Topbar)
    MinBtn.Size             = UDim2.new(0, 32, 0, 42)
    MinBtn.Position         = UDim2.new(1, -32, 0, 0)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text             = "—"
    MinBtn.TextColor3       = Theme.TextDim
    MinBtn.TextSize         = 17
    MinBtn.MouseEnter:Connect(function() Tween(MinBtn, 0.15, {TextColor3 = Theme.Accent}):Play() end)
    MinBtn.MouseLeave:Connect(function() Tween(MinBtn, 0.15, {TextColor3 = Theme.TextDim}):Play() end)

    -- ── FOOTER ──────────────────────────────────
    local Footer = Instance.new("TextLabel", MainFrame)
    Footer.Size             = UDim2.new(1, -48, 0, 22)
    Footer.Position         = UDim2.new(0, 48, 1, -22)
    Footer.BackgroundColor3 = Theme.SidebarBg
    Footer.BackgroundTransparency = Theme.Transparency
    Footer.Text             = footerText
    Footer.TextColor3       = Theme.TextDim
    Footer.Font             = Enum.Font.Gotham
    Footer.TextSize         = 11
    Footer.BorderSizePixel  = 0

    -- ── CONTENT AREA ────────────────────────────
    local ContentArea = Instance.new("Frame", MainFrame)
    ContentArea.Size             = UDim2.new(1, -48, 1, -64)
    ContentArea.Position         = UDim2.new(0, 48, 0, 42)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = true

    -- ── MINIMIZE / SHOW LOGIC ────────────────────
    local windowVisible = true
    local function setVisible(v)
        windowVisible = v
        if v then
            MainFrame.Visible = true
            FloatBtn.Visible  = false
            Tween(MainFrame, 0.3, {
                Size     = UDim2.new(0, currentWidth, 0, currentHeight),
                Position = currentPos
            }, Enum.EasingStyle.Back):Play()
        else
            currentPos = MainFrame.Position
            local tw = Tween(MainFrame, 0.25, {
                Size     = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset + currentWidth/2, currentPos.Y.Scale, currentPos.Y.Offset + currentHeight/2)
            }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            tw:Play()
            tw.Completed:Connect(function()
                MainFrame.Visible = false
                FloatBtn.Visible  = true
            end)
        end
    end

    MinBtn.MouseButton1Click:Connect(function() setVisible(false) end)
    FloatBtn.MouseButton1Click:Connect(function() setVisible(true) end)

    -- Global toggle key
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == toggleKey then
            setVisible(not windowVisible)
        end
    end)

    -- ══════════════════════════════════════════
    --  WINDOW OBJECT
    -- ══════════════════════════════════════════
    local Window = {
        Tabs           = {},
        FirstTab       = true,
        SearchableItems= {},
        Sections       = {},
        _activeTab     = nil,
    }

    -- Search logic
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(SearchBox.Text)
        for _, sec in ipairs(Window.Sections) do
            local sectionTitleMatches = string.find(string.lower(sec.Title), q, 1, true) ~= nil
            local anyItemMatches = false
            
            for _, item in ipairs(sec.Items) do
                local matches = (q == "") or sectionTitleMatches or (string.find(string.lower(item.Name), q, 1, true) ~= nil)
                item.Frame.Visible = matches
                if matches then
                    anyItemMatches = true
                end
            end
            
            if q == "" then
                sec.Frame.Visible = true
            else
                sec.Frame.Visible = sectionTitleMatches or anyItemMatches
            end
        end
    end)

    -- ── MINIMIZED WIDGET CONTROLS ────────────────
    function Window:SetMinimizedText(text)
        FloatLabel.Text = text
    end
    
    function Window:SetMinimizedGlow(color)
        if typeof(color) == "Color3" then
            FloatLED.BackgroundColor3 = color
            FloatLED.Visible = true
        elseif type(color) == "string" then
            local matched = Theme[color] or Themes.Blue[color] or (color:sub(1,1) == "#" and Color3.fromHex(color))
            if matched then
                FloatLED.BackgroundColor3 = matched
                FloatLED.Visible = true
            else
                FloatLED.Visible = false
            end
        else
            FloatLED.Visible = false
        end
    end

    -- ── UNIVERSAL HUD OVERLAY ───────────────────
    function Window:CreateHUD(config)
        config = config or {}
        local hudTitle = config.Title or "Status HUD"
        local hudWidth = config.Width or 160
        local hudHeight = config.Height or 100
        
        local HUDFrame = Instance.new("Frame", ScreenGui)
        HUDFrame.Name = "HUDFrame"
        HUDFrame.Size = UDim2.new(0, hudWidth, 0, hudHeight)
        HUDFrame.Position = UDim2.new(1, -hudWidth - 20, 0, 100)
        HUDFrame.BackgroundColor3 = Theme.SidebarBg
        HUDFrame.BackgroundTransparency = 0.4
        HUDFrame.BorderSizePixel = 0
        Instance.new("UICorner", HUDFrame).CornerRadius = Theme.Radius
        
        local HUDStroke = Instance.new("UIStroke", HUDFrame)
        HUDStroke.Color = Theme.Accent
        HUDStroke.Thickness = 1
        
        local HUDHeader = Instance.new("Frame", HUDFrame)
        HUDHeader.Name = "HUDHeader"
        HUDHeader.Size = UDim2.new(1, 0, 0, 24)
        HUDHeader.BackgroundTransparency = 1
        
        local HUDTitle = Instance.new("TextLabel", HUDHeader)
        HUDTitle.Size = UDim2.new(1, -30, 1, 0)
        HUDTitle.Position = UDim2.new(0, 10, 0, 0)
        HUDTitle.BackgroundTransparency = 1
        HUDTitle.Text = hudTitle
        HUDTitle.TextColor3 = Theme.Accent
        HUDTitle.Font = Enum.Font.GothamBold
        HUDTitle.TextSize = 11
        HUDTitle.TextXAlignment = Enum.TextXAlignment.Left
        
        local HUDClose = Instance.new("TextButton", HUDHeader)
        HUDClose.Size = UDim2.new(0, 20, 0, 20)
        HUDClose.Position = UDim2.new(1, -22, 0.5, -10)
        HUDClose.BackgroundTransparency = 1
        HUDClose.Text = "×"
        HUDClose.TextColor3 = Theme.TextDim
        HUDClose.TextSize = 16
        HUDClose.Font = Enum.Font.GothamBold
        HUDClose.MouseButton1Click:Connect(function()
            HUDFrame.Visible = false
        end)
        HUDClose.MouseEnter:Connect(function() HUDClose.TextColor3 = Theme.Error end)
        HUDClose.MouseLeave:Connect(function() HUDClose.TextColor3 = Theme.TextDim end)
        
        MakeDraggable(HUDHeader, HUDFrame)
        
        local HUDScroll = Instance.new("ScrollingFrame", HUDFrame)
        HUDScroll.Size = UDim2.new(1, -8, 1, -32)
        HUDScroll.Position = UDim2.new(0, 4, 0, 28)
        HUDScroll.BackgroundTransparency = 1
        HUDScroll.BorderSizePixel = 0
        HUDScroll.ScrollBarThickness = 2
        HUDScroll.ScrollBarImageColor3 = Theme.Accent
        HUDScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        HUDScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        
        local HUDList = Instance.new("UIListLayout", HUDScroll)
        HUDList.Padding = UDim.new(0, 4)
        
        local HUDPad = Instance.new("UIPadding", HUDScroll)
        HUDPad.PaddingLeft = UDim.new(0, 6)
        HUDPad.PaddingRight = UDim.new(0, 6)
        HUDPad.PaddingTop = UDim.new(0, 2)
        
        local hudCurrentW = hudWidth
        local hudCurrentH = hudHeight
        
        local function SetupHUDResizing(hudFrame, minW, minH)
            minW = minW or 100
            minH = minH or 60
            
            local Right = Instance.new("Frame", hudFrame)
            Right.Size = UDim2.new(0, 6, 1, -10)
            Right.Position = UDim2.new(1, -3, 0, 5)
            Right.BackgroundTransparency = 1
            Right.ZIndex = 101
            
            local Bottom = Instance.new("Frame", hudFrame)
            Bottom.Size = UDim2.new(1, -10, 0, 6)
            Bottom.Position = UDim2.new(0, 5, 1, -3)
            Bottom.BackgroundTransparency = 1
            Bottom.ZIndex = 101
            
            local Corner = Instance.new("ImageButton", hudFrame)
            Corner.Size = UDim2.new(0, 10, 0, 10)
            Corner.Position = UDim2.new(1, -10, 1, -10)
            Corner.BackgroundTransparency = 1
            Corner.Image = "rbxassetid://6032731804"
            Corner.ImageColor3 = Theme.TextDim
            Corner.ImageTransparency = 0.6
            Corner.ZIndex = 102
            
            Corner.MouseEnter:Connect(function() Corner.ImageTransparency = 0; Corner.ImageColor3 = Theme.Accent end)
            Corner.MouseLeave:Connect(function() Corner.ImageTransparency = 0.6; Corner.ImageColor3 = Theme.TextDim end)
            
            local function MakeHUDResizable(dragPt, resX, resY)
                local resizing = false
                local dragInput, mousePos, startSize
                dragPt.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        resizing = true
                        mousePos = input.Position
                        startSize = hudFrame.Size
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then resizing = false end
                        end)
                    end
                end)
                dragPt.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if input == dragInput and resizing then
                        local delta = input.Position - mousePos
                        local newW = startSize.X.Offset
                        local newH = startSize.Y.Offset
                        if resX then
                            newW = math.max(minW, startSize.X.Offset + delta.X)
                            hudCurrentW = newW
                        end
                        if resY then
                            newH = math.max(minH, startSize.Y.Offset + delta.Y)
                            hudCurrentH = newH
                        end
                        Tween(hudFrame, 0.05, {Size = UDim2.new(0, newW, 0, newH)}):Play()
                    end
                end)
            end
            
            MakeHUDResizable(Right, true, false)
            MakeHUDResizable(Bottom, false, true)
            MakeHUDResizable(Corner, true, true)
        end
        
        SetupHUDResizing(HUDFrame, 120, 60)
        
        local HUDObj = {}
        
        function HUDObj:SetVisible(state)
            HUDFrame.Visible = state
        end
        
        function HUDObj:SetTitle(title)
            HUDTitle.Text = title
        end
        
        function HUDObj:AddLine(labelText)
            local LineLabel = Instance.new("TextLabel", HUDScroll)
            LineLabel.Size = UDim2.new(1, 0, 0, 16)
            LineLabel.BackgroundTransparency = 1
            LineLabel.Text = labelText
            LineLabel.TextColor3 = Theme.Text
            LineLabel.Font = Enum.Font.Gotham
            LineLabel.TextSize = 10
            LineLabel.TextXAlignment = Enum.TextXAlignment.Left
            LineLabel.TextWrapped = true
            
            local LineObj = {}
            function LineObj:SetText(newTxt)
                LineLabel.Text = newTxt
            end
            function LineObj:SetColor(color)
                LineLabel.TextColor3 = color
            end
            function LineObj:Destroy()
                LineLabel:Destroy()
            end
            return LineObj
        end
        
        function HUDObj:Clear()
            for _, ch in ipairs(HUDScroll:GetChildren()) do
                if ch:IsA("TextLabel") then ch:Destroy() end
            end
        end
        
        function HUDObj:Destroy()
            HUDFrame:Destroy()
        end
        
        return HUDObj
    end

    -- ══════════════════════════════════════════
    --  TAB FACTORY
    -- ══════════════════════════════════════════
    --[[
        Window:MakeTab({
            Icon  = "⚙",
            Name  = "Settings",   -- opsional, label di bawah ikon
        })
        -- atau singkat: Window:MakeTab("⚙")
    ]]
    function Window:MakeTab(iconOrConfig)
        local icon, tabName
        if type(iconOrConfig) == "table" then
            icon    = iconOrConfig.Icon or "●"
            tabName = iconOrConfig.Name
        else
            icon    = iconOrConfig or "●"
        end

        -- Tab button container
        local TabBtn = Instance.new("Frame", TabContainer)
        TabBtn.Size             = UDim2.new(0, 34, 0, tabName and 48 or 34)
        TabBtn.BackgroundTransparency = 1

        local TabIco = Instance.new("TextButton", TabBtn)
        TabIco.Size             = UDim2.new(1, 0, 0, 32)
        TabIco.BackgroundColor3 = Theme.ElementBg
        TabIco.BackgroundTransparency = self.FirstTab and 0.5 or 1
        TabIco.Text             = icon
        TabIco.TextColor3       = self.FirstTab and Theme.Accent or Theme.TextDim
        TabIco.TextSize         = 16
        TabIco.BorderSizePixel  = 0
        Instance.new("UICorner", TabIco).CornerRadius = UDim.new(0, 6)

        if tabName then
            local TabLbl = Instance.new("TextLabel", TabBtn)
            TabLbl.Size             = UDim2.new(1, 0, 0, 13)
            TabLbl.Position         = UDim2.new(0, 0, 0, 34)
            TabLbl.BackgroundTransparency = 1
            TabLbl.Text             = tabName
            TabLbl.TextColor3       = self.FirstTab and Theme.Accent or Theme.TextDim
            TabLbl.Font             = Enum.Font.Gotham
            TabLbl.TextSize         = 9
            TabLbl.TextTruncate     = Enum.TextTruncate.AtEnd
            TabIco.Tag = TabLbl  -- store ref
        end

        -- Badge
        local BadgeFrame = Instance.new("Frame", TabBtn)
        BadgeFrame.Size             = UDim2.new(0, 16, 0, 16)
        BadgeFrame.Position         = UDim2.new(1, -4, 0, -4)
        BadgeFrame.BackgroundColor3 = Theme.Error
        BadgeFrame.Visible          = false
        BadgeFrame.ZIndex           = 10
        BadgeFrame.BorderSizePixel  = 0
        Instance.new("UICorner", BadgeFrame).CornerRadius = UDim.new(1, 0)
        local BadgeLbl = Instance.new("TextLabel", BadgeFrame)
        BadgeLbl.Size               = UDim2.new(1, 0, 1, 0)
        BadgeLbl.BackgroundTransparency = 1
        BadgeLbl.Text               = ""
        BadgeLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
        BadgeLbl.Font               = Enum.Font.GothamBold
        BadgeLbl.TextSize           = 9
        BadgeLbl.ZIndex             = 11

        -- Page
        local Page = Instance.new("ScrollingFrame", ContentArea)
        Page.Size             = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness     = 3
        Page.ScrollBarImageColor3   = Theme.Accent
        Page.AutomaticCanvasSize    = Enum.AutomaticSize.Y
        Page.CanvasSize             = UDim2.new(0, 0, 0, 0)
        Page.Visible                = self.FirstTab
        Page.BorderSizePixel        = 0

        local PageLayout = Instance.new("UIListLayout", Page)
        PageLayout.Padding          = UDim.new(0, 8)
        PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

        -- Single UIPadding (FIXED duplicate)
        local PagePad = Instance.new("UIPadding", Page)
        PagePad.PaddingTop    = UDim.new(0, 6)
        PagePad.PaddingBottom = UDim.new(0, 8)

        local tabInfo = {
            Btn     = TabBtn,
            Ico     = TabIco,
            Page    = Page,
            Badge   = {Frame = BadgeFrame, Label = BadgeLbl},
        }
        table.insert(self.Tabs, tabInfo)

        if self.FirstTab then
            self._activeTab = tabInfo
        end

        TabIco.MouseButton1Click:Connect(function()
            for _, ti in ipairs(self.Tabs) do
                local isActive = (ti == tabInfo)
                -- Fade transition
                if ti.Page.Visible and not isActive then
                    Tween(ti.Page, 0.1, {BackgroundTransparency = 1}):Play()
                end
                ti.Page.Visible = isActive
                Tween(ti.Ico, 0.2, {
                    TextColor3          = isActive and Theme.Accent or Theme.TextDim,
                    BackgroundTransparency = isActive and 0.5 or 1,
                }):Play()
                if tabName then
                    local lbl = ti.Btn:FindFirstChildWhichIsA("TextLabel")
                    if lbl then
                        Tween(lbl, 0.2, {TextColor3 = isActive and Theme.Accent or Theme.TextDim}):Play()
                    end
                end
            end
            self._activeTab = tabInfo
        end)

        self.FirstTab = false

        -- Tab API
        local TabObj = {}

        function TabObj:SetBadge(val)
            if val == false or val == 0 or val == nil then
                BadgeFrame.Visible = false
            else
                BadgeFrame.Visible = true
                BadgeLbl.Text = (type(val) == "number" and val > 0) and tostring(val) or ""
            end
        end

        -- ══════════════════════════════════════
        --  SECTION FACTORY
        -- ══════════════════════════════════════
        function TabObj:AddSection(sectionTitle, collapsible)
            collapsible = (collapsible == nil) and true or collapsible

            local SecFrame = Instance.new("Frame", Page)
            local secRecord = {
                Frame = SecFrame,
                Title = sectionTitle,
                Items = {}
            }
            table.insert(Window.Sections, secRecord)

            local function registerItem(name, frame)
                table.insert(secRecord.Items, {Name = name, Frame = frame})
                table.insert(Window.SearchableItems, {Name = name, Frame = frame})
            end

            SecFrame.Size             = UDim2.new(1, -18, 0, 36)
            SecFrame.BackgroundColor3 = Theme.MainBg
            SecFrame.BackgroundTransparency = Theme.Transparency
            SecFrame.BorderSizePixel  = 0
            Instance.new("UICorner", SecFrame).CornerRadius = Theme.Radius
            local SecStroke = Instance.new("UIStroke", SecFrame)
            SecStroke.Color     = Theme.Border
            SecStroke.Thickness = 1

            -- Header bar
            local Header = Instance.new("TextButton", SecFrame)
            Header.Size             = UDim2.new(1, 0, 0, 30)
            Header.BackgroundTransparency = 1
            Header.Text             = ""
            Header.BorderSizePixel  = 0

            local HeaderTitle = Instance.new("TextLabel", Header)
            HeaderTitle.Size             = UDim2.new(1, -40, 1, 0)
            HeaderTitle.Position         = UDim2.new(0, 10, 0, 0)
            HeaderTitle.BackgroundTransparency = 1
            HeaderTitle.Text             = "◈  " .. sectionTitle
            HeaderTitle.TextColor3       = Theme.Accent
            HeaderTitle.Font             = Enum.Font.GothamSemibold
            HeaderTitle.TextSize         = 12
            HeaderTitle.TextXAlignment   = Enum.TextXAlignment.Left

            local CollapseIco = Instance.new("TextLabel", Header)
            CollapseIco.Size             = UDim2.new(0, 20, 1, 0)
            CollapseIco.Position         = UDim2.new(1, -24, 0, 0)
            CollapseIco.BackgroundTransparency = 1
            CollapseIco.Text             = collapsible and "▾" or ""
            CollapseIco.TextColor3       = Theme.TextDim
            CollapseIco.Font             = Enum.Font.GothamBold
            CollapseIco.TextSize         = 13

            -- Inner content container
            local Inner = Instance.new("Frame", SecFrame)
            Inner.Size             = UDim2.new(1, 0, 1, -30)
            Inner.Position         = UDim2.new(0, 0, 0, 30)
            Inner.BackgroundTransparency = 1
            Inner.ClipsDescendants = true

            local InnerLayout = Instance.new("UIListLayout", Inner)
            InnerLayout.Padding          = UDim.new(0, 5)
            InnerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

            local InnerPad = Instance.new("UIPadding", Inner)
            InnerPad.PaddingTop    = UDim.new(0, 4)
            InnerPad.PaddingBottom = UDim.new(0, 8)
            InnerPad.PaddingLeft   = UDim.new(0, 8)
            InnerPad.PaddingRight  = UDim.new(0, 8)

            local isCollapsed = false

            local function updateHeight()
                if isCollapsed then
                    SecFrame.Size = UDim2.new(1, -18, 0, 30)
                else
                    local contentH = InnerLayout.AbsoluteContentSize.Y + 30 + 16
                    Tween(SecFrame, 0.2, {Size = UDim2.new(1, -18, 0, contentH)}):Play()
                end
            end

            InnerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight)

            if collapsible then
                Header.MouseButton1Click:Connect(function()
                    isCollapsed = not isCollapsed
                    Tween(CollapseIco, 0.2, {Rotation = isCollapsed and -90 or 0}):Play()
                    if isCollapsed then
                        Tween(SecFrame, 0.2, {Size = UDim2.new(1, -18, 0, 30)}):Play()
                    else
                        local contentH = InnerLayout.AbsoluteContentSize.Y + 30 + 16
                        Tween(SecFrame, 0.2, {Size = UDim2.new(1, -18, 0, contentH)}):Play()
                    end
                end)
            end

            -- ══════════════════════════════════
            --  SECTION ELEMENTS
            -- ══════════════════════════════════
            local Section = {}
            local disabledByDep = {}

            local function registerFlag(flag, defaultVal)
                if not flag then return end  -- guard against nil flag
                if Library.Flags[flag] == nil then
                    Library.Flags[flag] = defaultVal
                end
                Library._elements[flag] = Library._elements[flag] or {}
            end

            local function applyDependency(flag, elemFrame, depFlag)
                if not depFlag then return end
                Library._elements[depFlag] = Library._elements[depFlag] or {}
                table.insert(Library._elements[depFlag], function(val)
                    elemFrame.BackgroundTransparency = val and 1 or 0.6
                    for _, child in ipairs(elemFrame:GetDescendants()) do
                        if child:IsA("TextLabel") then
                            child.TextTransparency = val and 0 or 0.5
                        end
                    end
                    -- disable interaction
                    local btn = elemFrame:FindFirstChildWhichIsA("TextButton")
                    if btn then btn.Active = val end
                end)
                -- Apply immediately based on current flag value
                local curVal = Library.Flags[depFlag]
                if curVal ~= nil then
                    elemFrame.BackgroundTransparency = curVal and 1 or 0.6
                end
            end

            -- 1. LABEL
            function Section:AddLabel(text)
                local Lbl = Instance.new("TextLabel", Inner)
                Lbl.Size             = UDim2.new(1, 0, 0, 18)
                Lbl.BackgroundTransparency = 1
                Lbl.Text             = text
                Lbl.TextColor3       = Theme.TextDim
                Lbl.Font             = Enum.Font.Gotham
                Lbl.TextSize         = 12
                Lbl.TextXAlignment   = Enum.TextXAlignment.Left
                Lbl.TextWrapped      = true
                registerItem(text, Lbl)
                return Lbl
            end

            -- 2. PARAGRAPH
            function Section:AddParagraph(title, desc)
                local PFrame = Instance.new("Frame", Inner)
                PFrame.Size             = UDim2.new(1, 0, 0, 0)
                PFrame.BackgroundColor3 = Theme.ElementBg
                PFrame.BorderSizePixel  = 0
                Instance.new("UICorner", PFrame).CornerRadius = UDim.new(0, 5)

                local PTitle = Instance.new("TextLabel", PFrame)
                PTitle.Size             = UDim2.new(1, -16, 0, 18)
                PTitle.Position         = UDim2.new(0, 8, 0, 5)
                PTitle.BackgroundTransparency = 1
                PTitle.Text             = title
                PTitle.TextColor3       = Theme.Text
                PTitle.Font             = Enum.Font.GothamBold
                PTitle.TextSize         = 12
                PTitle.TextXAlignment   = Enum.TextXAlignment.Left

                local PDesc = Instance.new("TextLabel", PFrame)
                PDesc.Size              = UDim2.new(1, -16, 0, 0)
                PDesc.Position          = UDim2.new(0, 8, 0, 25)
                PDesc.BackgroundTransparency = 1
                PDesc.Text              = desc
                PDesc.TextColor3        = Theme.TextDim
                PDesc.Font              = Enum.Font.Gotham
                PDesc.TextSize          = 11
                PDesc.TextXAlignment    = Enum.TextXAlignment.Left
                PDesc.TextWrapped       = true
                PDesc.AutomaticSize     = Enum.AutomaticSize.Y

                PFrame.AutomaticSize = Enum.AutomaticSize.Y

                registerItem(title .. " " .. desc, PFrame)

                -- Return updateable object so callers can do para:Set(newTitle, newContent)
                return {
                    Set = function(_, newTitle, newDesc)
                        -- Support both Set(title, desc) and Set({Title=..., Content=...})
                        if type(newTitle) == "table" then
                            local t = newTitle.Title or newTitle[1]
                            local d = newTitle.Content or newTitle[2]
                            if t then PTitle.Text = t end
                            if d then PDesc.Text = d end
                        else
                            if newTitle then PTitle.Text = newTitle end
                            if newDesc  then PDesc.Text  = newDesc  end
                        end
                    end,
                    SetTitle   = function(_, t) PTitle.Text = t end,
                    SetContent = function(_, d) PDesc.Text  = d end,
                }
            end

            -- 3. WARNING BOX
            function Section:AddWarning(text, wType)
                local wColor = wType == "Error" and Theme.Error
                    or wType == "Success" and Theme.Success
                    or Theme.Warning

                local WF = Instance.new("Frame", Inner)
                WF.Size             = UDim2.new(1, 0, 0, 0)
                WF.BackgroundColor3 = wColor
                WF.BackgroundTransparency = 0.82
                WF.BorderSizePixel  = 0
                Instance.new("UICorner", WF).CornerRadius = UDim.new(0, 5)
                local WFS = Instance.new("UIStroke", WF)
                WFS.Color     = wColor
                WFS.Thickness = 1

                local WLbl = Instance.new("TextLabel", WF)
                WLbl.Size             = UDim2.new(1, -20, 1, -12)
                WLbl.Position         = UDim2.new(0, 10, 0, 6)
                WLbl.BackgroundTransparency = 1
                WLbl.Text             = "⚠  " .. text
                WLbl.TextColor3       = wColor
                WLbl.Font             = Enum.Font.GothamBold
                WLbl.TextSize         = 11
                WLbl.TextWrapped      = true
                WLbl.TextXAlignment   = Enum.TextXAlignment.Left
                WLbl.AutomaticSize    = Enum.AutomaticSize.Y

                WLbl:GetPropertyChangedSignal("TextBounds"):Connect(function()
                    WF.Size = UDim2.new(1, 0, 0, WLbl.TextBounds.Y + 14)
                end)
                registerItem(text, WF)
            end

            -- 4. BUTTON
            function Section:AddButton(info, callback)
                local text    = type(info) == "table" and info.Name    or info
                local tooltip = type(info) == "table" and info.Tooltip or ""
                local depFlag = type(info) == "table" and info.DependsOn or nil

                local Btn = Instance.new("TextButton", Inner)
                Btn.Size             = UDim2.new(1, 0, 0, 32)
                Btn.BackgroundColor3 = Theme.ElementBg
                Btn.Text             = "   " .. text
                Btn.TextColor3       = Theme.Text
                Btn.Font             = Enum.Font.Gotham
                Btn.TextSize         = 12
                Btn.TextXAlignment   = Enum.TextXAlignment.Left
                Btn.ClipsDescendants = true
                Btn.BorderSizePixel  = 0
                Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)
                AddTooltip(Btn, tooltip)
                applyDependency(nil, Btn, depFlag)

                Btn.MouseEnter:Connect(function()
                    Tween(Btn, 0.15, {BackgroundColor3 = Theme.ElementHover}):Play()
                end)
                Btn.MouseLeave:Connect(function()
                    Tween(Btn, 0.15, {BackgroundColor3 = Theme.ElementBg}):Play()
                end)
                Btn.MouseButton1Click:Connect(function()
                    CreateRipple(Btn, UserInputService:GetMouseLocation())
                    if callback then callback() end
                end)
                registerItem(text, Btn)
            end

            -- 5. TOGGLE
            function Section:AddToggle(info, defaultOrCb, cbArg)
                local text, default, callback, flag, tooltip, depFlag
                if type(info) == "table" then
                    text     = info.Name
                    default  = info.Default or false
                    callback = defaultOrCb
                    flag     = info.Flag
                    tooltip  = info.Tooltip
                    depFlag  = info.DependsOn
                else
                    text = info; default = (type(defaultOrCb) == "boolean" and defaultOrCb) or false
                    callback = cbArg
                end

                registerFlag(flag, default)
                local state = flag and Library.Flags[flag] or default

                local TglRow = Instance.new("Frame", Inner)
                TglRow.Size             = UDim2.new(1, 0, 0, 28)
                TglRow.BackgroundTransparency = 1
                AddTooltip(TglRow, tooltip)
                applyDependency(nil, TglRow, depFlag)

                local TLbl = Instance.new("TextLabel", TglRow)
                TLbl.Size             = UDim2.new(1, -50, 1, 0)
                TLbl.BackgroundTransparency = 1
                TLbl.Text             = text
                TLbl.TextColor3       = Theme.Text
                TLbl.Font             = Enum.Font.Gotham
                TLbl.TextSize         = 12
                TLbl.TextXAlignment   = Enum.TextXAlignment.Left

                local TBg = Instance.new("Frame", TglRow)
                TBg.Size             = UDim2.new(0, 36, 0, 18)
                TBg.Position         = UDim2.new(1, -36, 0.5, -9)
                TBg.BackgroundColor3 = state and Theme.Accent or Theme.ElementBg
                TBg.BorderSizePixel  = 0
                Instance.new("UICorner", TBg).CornerRadius = UDim.new(1, 0)

                local TDot = Instance.new("Frame", TBg)
                TDot.Size             = UDim2.new(0, 14, 0, 14)
                TDot.Position         = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                TDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TDot.BorderSizePixel  = 0
                Instance.new("UICorner", TDot).CornerRadius = UDim.new(1, 0)

                local TBtn = Instance.new("TextButton", TglRow)
                TBtn.Size             = UDim2.new(1, 0, 1, 0)
                TBtn.BackgroundTransparency = 1
                TBtn.Text             = ""

                local function SetState(newState)
                    state = newState
                    if flag then
                        Library.Flags[flag] = state
                        -- Notify dependents
                        if Library._elements[flag] then
                            for _, cb in ipairs(Library._elements[flag]) do pcall(cb, state) end
                        end
                    end
                    Tween(TBg, 0.2, {BackgroundColor3 = state and Theme.Accent or Theme.ElementBg}):Play()
                    Tween(TDot, 0.2, {Position = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
                    if callback then callback(state) end
                    if Library._autoSave then Library:SaveConfig() end
                end

                TBtn.MouseButton1Click:Connect(function() SetState(not state) end)
                registerItem(text, TglRow)

                return {
                    Set = function(_, v) SetState(v) end,
                    Get = function() return state end,
                }
            end

            -- 6. SLIDER (with Step/Decimal support)
            function Section:AddSlider(info, minArg, maxArg, defArg, cbArg)
                local text, min_, max_, default, callback, flag, tooltip, step, depFlag
                if type(info) == "table" then
                    text     = info.Name
                    min_     = info.Min     or 0
                    max_     = info.Max     or 100
                    default  = info.Default or min_
                    step     = info.Step    or 1
                    callback = minArg
                    flag     = info.Flag
                    tooltip  = info.Tooltip
                    depFlag  = info.DependsOn
                else
                    text = info; min_ = minArg; max_ = maxArg; default = defArg; callback = cbArg; step = 1
                end

                registerFlag(flag, default)
                local value = flag and Library.Flags[flag] or default
                local decimals = tostring(step):find("%.") and #tostring(step):match("%.(.*)") or 0

                local SldFrame = Instance.new("Frame", Inner)
                SldFrame.Size             = UDim2.new(1, 0, 0, 44)
                SldFrame.BackgroundTransparency = 1
                AddTooltip(SldFrame, tooltip)
                applyDependency(nil, SldFrame, depFlag)

                local SLbl = Instance.new("TextLabel", SldFrame)
                SLbl.Size             = UDim2.new(1, -45, 0, 18)
                SLbl.BackgroundTransparency = 1
                SLbl.Text             = text
                SLbl.TextColor3       = Theme.Text
                SLbl.Font             = Enum.Font.Gotham
                SLbl.TextSize         = 12
                SLbl.TextXAlignment   = Enum.TextXAlignment.Left

                local SVLbl = Instance.new("TextBox", SldFrame)
                SVLbl.Size             = UDim2.new(0, 50, 0, 18)
                SVLbl.Position         = UDim2.new(1, -50, 0, 0)
                SVLbl.BackgroundTransparency = 1
                SVLbl.TextColor3       = Theme.Accent
                SVLbl.Font             = Enum.Font.GothamBold
                SVLbl.TextSize         = 12
                SVLbl.TextXAlignment   = Enum.TextXAlignment.Right
                SVLbl.ClearTextOnFocus = false
                SVLbl.Text             = ""

                local BgBar = Instance.new("Frame", SldFrame)
                BgBar.Size             = UDim2.new(1, 0, 0, 6)
                BgBar.Position         = UDim2.new(0, 0, 0, 28)
                BgBar.BackgroundColor3 = Theme.ElementBg
                BgBar.BorderSizePixel  = 0
                Instance.new("UICorner", BgBar).CornerRadius = UDim.new(1, 0)

                local FillBar = Instance.new("Frame", BgBar)
                local initScale = math.clamp((value - min_) / (max_ - min_), 0, 1)
                FillBar.Size             = UDim2.new(initScale, 0, 1, 0)
                FillBar.BackgroundColor3 = Theme.Accent
                FillBar.BorderSizePixel  = 0
                Instance.new("UICorner", FillBar).CornerRadius = UDim.new(1, 0)

                -- Thumb knob
                local Thumb = Instance.new("Frame", BgBar)
                Thumb.Size             = UDim2.new(0, 12, 0, 12)
                Thumb.Position         = UDim2.new(initScale, -6, 0.5, -6)
                Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Thumb.BorderSizePixel  = 0
                Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)
                local ThumbStroke = Instance.new("UIStroke", Thumb)
                ThumbStroke.Color     = Theme.Accent
                ThumbStroke.Thickness = 2

                local SldBtn = Instance.new("TextButton", BgBar)
                SldBtn.Size             = UDim2.new(1, 0, 1, 14)
                SldBtn.Position         = UDim2.new(0, 0, 0, -7)
                SldBtn.BackgroundTransparency = 1
                SldBtn.Text             = ""

                local isFocused = false
                SVLbl.Focused:Connect(function()
                    isFocused = true
                end)
                SVLbl.FocusLost:Connect(function(enterPressed)
                    isFocused = false
                    local num = tonumber(SVLbl.Text)
                    if num then
                        SetValue(num)
                    else
                        local decimals = tostring(step):find("%.") and #tostring(step):match("%.(.*)") or 0
                        SVLbl.Text = decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value))
                    end
                end)

                local function SetValue(v)
                    -- Snap to step
                    if step and step ~= 0 then
                        v = math.floor(v / step + 0.5) * step
                    end
                    value = math.clamp(v, min_, max_)
                    if flag then
                        Library.Flags[flag] = value
                        if Library._elements[flag] then
                            for _, cb in ipairs(Library._elements[flag]) do pcall(cb, value) end
                        end
                    end
                    local scale = (value - min_) / (max_ - min_)
                    Tween(FillBar, 0.05, {Size = UDim2.new(scale, 0, 1, 0)}):Play()
                    Tween(Thumb, 0.05, {Position = UDim2.new(scale, -6, 0.5, -6)}):Play()
                    if not isFocused then
                        SVLbl.Text = decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(math.floor(value))
                    end
                    if callback then callback(value) end
                    if Library._autoSave then Library:SaveConfig() end
                end

                SetValue(value)

                local dragging = false
                SldBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        local pos = math.clamp((input.Position.X - BgBar.AbsolutePosition.X) / BgBar.AbsoluteSize.X, 0, 1)
                        SetValue(min_ + (max_ - min_) * pos)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        local pos = math.clamp((input.Position.X - BgBar.AbsolutePosition.X) / BgBar.AbsoluteSize.X, 0, 1)
                        SetValue(min_ + (max_ - min_) * pos)
                    end
                end)
                registerItem(text, SldFrame)

                return {
                    Set = function(_, v) SetValue(v) end,
                    Get = function() return value end,
                }
            end

            -- 7. NUMBER STEPPER
            function Section:AddStepper(info, cbArg)
                local text, min_, max_, default, step, callback, flag, tooltip
                if type(info) == "table" then
                    text     = info.Name
                    min_     = info.Min     or 0
                    max_     = info.Max     or 100
                    default  = info.Default or min_
                    step     = info.Step    or 1
                    callback = cbArg
                    flag     = info.Flag
                    tooltip  = info.Tooltip
                else
                    text = info; min_ = 0; max_ = 100; default = 0; step = 1; callback = cbArg
                end

                registerFlag(flag, default)
                local value = flag and Library.Flags[flag] or default

                local StRow = Instance.new("Frame", Inner)
                StRow.Size             = UDim2.new(1, 0, 0, 30)
                StRow.BackgroundTransparency = 1
                AddTooltip(StRow, tooltip)

                local StLbl = Instance.new("TextLabel", StRow)
                StLbl.Size             = UDim2.new(1, -110, 1, 0)
                StLbl.BackgroundTransparency = 1
                StLbl.Text             = text
                StLbl.TextColor3       = Theme.Text
                StLbl.Font             = Enum.Font.Gotham
                StLbl.TextSize         = 12
                StLbl.TextXAlignment   = Enum.TextXAlignment.Left

                local MinusBtn = Instance.new("TextButton", StRow)
                MinusBtn.Size            = UDim2.new(0, 28, 0, 24)
                MinusBtn.Position        = UDim2.new(1, -110, 0.5, -12)
                MinusBtn.BackgroundColor3= Theme.ElementBg
                MinusBtn.Text            = "−"
                MinusBtn.TextColor3      = Theme.Text
                MinusBtn.Font            = Enum.Font.GothamBold
                MinusBtn.TextSize        = 16
                MinusBtn.BorderSizePixel = 0
                Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 5)

                local ValDisp = Instance.new("TextLabel", StRow)
                ValDisp.Size             = UDim2.new(0, 48, 0, 24)
                ValDisp.Position         = UDim2.new(1, -80, 0.5, -12)
                ValDisp.BackgroundColor3 = Theme.ElementBg
                ValDisp.Text             = tostring(value)
                ValDisp.TextColor3       = Theme.Accent
                ValDisp.Font             = Enum.Font.GothamBold
                ValDisp.TextSize         = 12
                ValDisp.BorderSizePixel  = 0
                Instance.new("UICorner", ValDisp).CornerRadius = UDim.new(0, 5)

                local PlusBtn = Instance.new("TextButton", StRow)
                PlusBtn.Size             = UDim2.new(0, 28, 0, 24)
                PlusBtn.Position         = UDim2.new(1, -30, 0.5, -12)
                PlusBtn.BackgroundColor3 = Theme.ElementBg
                PlusBtn.Text             = "+"
                PlusBtn.TextColor3       = Theme.Text
                PlusBtn.Font             = Enum.Font.GothamBold
                PlusBtn.TextSize         = 14
                PlusBtn.BorderSizePixel  = 0
                Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 5)

                local function SetVal(v)
                    value = math.clamp(v, min_, max_)
                    if flag then Library.Flags[flag] = value end
                    ValDisp.Text = tostring(value)
                    if callback then callback(value) end
                    if Library._autoSave then Library:SaveConfig() end
                end

                for _, btn in ipairs({MinusBtn, PlusBtn}) do
                    btn.MouseEnter:Connect(function() Tween(btn, 0.1, {BackgroundColor3 = Theme.ElementHover}):Play() end)
                    btn.MouseLeave:Connect(function() Tween(btn, 0.1, {BackgroundColor3 = Theme.ElementBg}):Play() end)
                end
                MinusBtn.MouseButton1Click:Connect(function() SetVal(value - step) end)
                PlusBtn.MouseButton1Click:Connect(function() SetVal(value + step) end)

                registerItem(text, StRow)
                return {Set = function(_, v) SetVal(v) end, Get = function() return value end}
            end

            -- 8. KEYBIND (with Flag support)
            function Section:AddBind(info, defaultKey, cbArg)
                local text, keyName, callback, flag, tooltip
                if type(info) == "table" then
                    text     = info.Name
                    keyName  = (type(info.Default) == "table" and info.Default.Name) or tostring(info.Default) or "None"
                    callback = defaultKey
                    flag     = info.Flag
                    tooltip  = info.Tooltip
                else
                    text    = info
                    keyName = (type(defaultKey) == "table" and defaultKey.Name) or tostring(defaultKey) or "None"
                    callback = cbArg
                end

                if flag and Library.Flags[flag] then
                    keyName = Library.Flags[flag]
                end
                if flag then Library.Flags[flag] = keyName end

                local BRow = Instance.new("Frame", Inner)
                BRow.Size             = UDim2.new(1, 0, 0, 28)
                BRow.BackgroundTransparency = 1
                AddTooltip(BRow, tooltip)

                local BLbl = Instance.new("TextLabel", BRow)
                BLbl.Size             = UDim2.new(1, -70, 1, 0)
                BLbl.BackgroundTransparency = 1
                BLbl.Text             = text
                BLbl.TextColor3       = Theme.Text
                BLbl.Font             = Enum.Font.Gotham
                BLbl.TextSize         = 12
                BLbl.TextXAlignment   = Enum.TextXAlignment.Left

                local BBtn = Instance.new("TextButton", BRow)
                BBtn.Size             = UDim2.new(0, 60, 0, 22)
                BBtn.Position         = UDim2.new(1, -62, 0.5, -11)
                BBtn.BackgroundColor3 = Theme.ElementBg
                BBtn.Text             = keyName
                BBtn.TextColor3       = Theme.Accent
                BBtn.Font             = Enum.Font.GothamBold
                BBtn.TextSize         = 11
                BBtn.BorderSizePixel  = 0
                Instance.new("UICorner", BBtn).CornerRadius = UDim.new(0, 5)

                local isListening = false
                BBtn.MouseButton1Click:Connect(function()
                    isListening = true
                    BBtn.Text       = "..."
                    BBtn.TextColor3 = Theme.Warning
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if isListening and input.UserInputType == Enum.UserInputType.Keyboard then
                        isListening     = false
                        keyName         = input.KeyCode.Name
                        BBtn.Text       = keyName
                        BBtn.TextColor3 = Theme.Accent
                        if flag then Library.Flags[flag] = keyName end
                    elseif not isListening and input.KeyCode.Name == keyName then
                        if callback then callback() end
                    end
                end)
                registerItem(text, BRow)
            end

            -- 9. DROPDOWN (with Scrollable list)
            function Section:AddDropdown(info, listArg, cbArg)
                local text, list, default, callback, flag, tooltip
                if type(info) == "table" then
                    text     = info.Name
                    list     = info.Options
                    default  = info.Default
                    callback = listArg
                    flag     = info.Flag
                    tooltip  = info.Tooltip
                else
                    text = info; list = listArg; default = listArg[1]; callback = cbArg
                end

                registerFlag(flag, default)
                local selected = flag and Library.Flags[flag] or default

                local DROP_HEIGHT = math.min(#list * 26, 120)

                local DFrame = Instance.new("Frame", Inner)
                DFrame.Size             = UDim2.new(1, 0, 0, 46)
                DFrame.BackgroundTransparency = 1
                DFrame.ClipsDescendants = true
                AddTooltip(DFrame, tooltip)

                local DLbl = Instance.new("TextLabel", DFrame)
                DLbl.Size             = UDim2.new(1, 0, 0, 16)
                DLbl.BackgroundTransparency = 1
                DLbl.Text             = text
                DLbl.TextColor3       = Theme.TextDim
                DLbl.Font             = Enum.Font.Gotham
                DLbl.TextSize         = 11
                DLbl.TextXAlignment   = Enum.TextXAlignment.Left

                local DBtn = Instance.new("TextButton", DFrame)
                DBtn.Size             = UDim2.new(1, 0, 0, 28)
                DBtn.Position         = UDim2.new(0, 0, 0, 18)
                DBtn.BackgroundColor3 = Theme.ElementBg
                DBtn.Text             = ""
                DBtn.BorderSizePixel  = 0
                Instance.new("UICorner", DBtn).CornerRadius = UDim.new(0, 5)

                local DBtnTxt = Instance.new("TextLabel", DBtn)
                DBtnTxt.Size             = UDim2.new(1, -30, 1, 0)
                DBtnTxt.Position         = UDim2.new(0, 10, 0, 0)
                DBtnTxt.BackgroundTransparency = 1
                DBtnTxt.Text             = selected or "Select..."
                DBtnTxt.TextColor3       = Theme.Text
                DBtnTxt.Font             = Enum.Font.Gotham
                DBtnTxt.TextSize         = 12
                DBtnTxt.TextXAlignment   = Enum.TextXAlignment.Left

                local DArrow = Instance.new("TextLabel", DBtn)
                DArrow.Size             = UDim2.new(0, 22, 1, 0)
                DArrow.Position         = UDim2.new(1, -22, 0, 0)
                DArrow.BackgroundTransparency = 1
                DArrow.Text             = "▾"
                DArrow.TextColor3       = Theme.TextDim
                DArrow.Font             = Enum.Font.GothamBold
                DArrow.TextSize         = 12

                -- Scrollable options list
                local DScroll = Instance.new("ScrollingFrame", DFrame)
                DScroll.Size             = UDim2.new(1, 0, 0, DROP_HEIGHT)
                DScroll.Position         = UDim2.new(0, 0, 0, 48)
                DScroll.BackgroundColor3 = Theme.ElementBg
                DScroll.ScrollBarThickness = 3
                DScroll.ScrollBarImageColor3 = Theme.Accent
                DScroll.CanvasSize       = UDim2.new(0, 0, 0, 0)
                DScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                DScroll.BorderSizePixel  = 0
                Instance.new("UICorner", DScroll).CornerRadius = UDim.new(0, 5)
                local DListLayout = Instance.new("UIListLayout", DScroll)
                DListLayout.Padding = UDim.new(0, 1)

                local isOpen = false  -- declared before loop so item callbacks can reference it

                for _, item in ipairs(list) do
                    local IBtn = Instance.new("TextButton", DScroll)
                    IBtn.Size             = UDim2.new(1, 0, 0, 26)
                    IBtn.BackgroundColor3 = (item == selected) and Theme.ElementHover or Theme.SidebarBg
                    IBtn.Text             = "  " .. tostring(item)
                    IBtn.TextColor3       = (item == selected) and Theme.Accent or Theme.TextDim
                    IBtn.Font             = Enum.Font.Gotham
                    IBtn.TextSize         = 12
                    IBtn.TextXAlignment   = Enum.TextXAlignment.Left
                    IBtn.BorderSizePixel  = 0
                    IBtn.MouseEnter:Connect(function()
                        Tween(IBtn, 0.1, {BackgroundColor3 = Theme.ElementHover, TextColor3 = Theme.Text}):Play()
                    end)
                    IBtn.MouseLeave:Connect(function()
                        local isSel = IBtn.Text:gsub("^  ", "") == (selected or "")
                        Tween(IBtn, 0.1, {
                            BackgroundColor3 = isSel and Theme.ElementHover or Theme.SidebarBg,
                            TextColor3 = isSel and Theme.Accent or Theme.TextDim
                        }):Play()
                    end)
                    IBtn.MouseButton1Click:Connect(function()
                        selected = item
                        DBtnTxt.Text = tostring(selected)
                        if flag then Library.Flags[flag] = selected end
                        -- Refresh highlight
                        for _, ch in ipairs(DScroll:GetChildren()) do
                            if ch:IsA("TextButton") then
                                local isSel2 = ch.Text:gsub("^  ", "") == tostring(selected)
                                ch.BackgroundColor3 = isSel2 and Theme.ElementHover or Theme.SidebarBg
                                ch.TextColor3       = isSel2 and Theme.Accent or Theme.TextDim
                            end
                        end
                        isOpen = false
                        Tween(DFrame, 0.2, {Size = UDim2.new(1, 0, 0, 46)}):Play()
                        Tween(DArrow, 0.2, {Rotation = 0}):Play()
                        if callback then callback(selected) end
                        if Library._autoSave then Library:SaveConfig() end
                    end)
                end


                DBtn.MouseButton1Click:Connect(function()

                    isOpen = not isOpen
                    Tween(DFrame, 0.2, {Size = UDim2.new(1, 0, 0, isOpen and (46 + DROP_HEIGHT + 2) or 46)}):Play()
                    Tween(DArrow, 0.2, {Rotation = isOpen and 180 or 0}):Play()
                end)

                registerItem(text, DFrame)
                return {
                    Set = function(_, v)
                        -- Find and programmatically select the matching option
                        local found = false
                        for _, ch in ipairs(DScroll:GetChildren()) do
                            if ch:IsA("TextButton") then
                                local itemText = ch.Text:gsub("^  ", "")
                                if itemText == tostring(v) then
                                    found = true
                                    selected = v
                                    DBtnTxt.Text = tostring(v)
                                    if flag then Library.Flags[flag] = selected end
                                    -- Refresh highlight
                                    for _, ch2 in ipairs(DScroll:GetChildren()) do
                                        if ch2:IsA("TextButton") then
                                            local isSel = ch2.Text:gsub("^  ","") == tostring(v)
                                            ch2.BackgroundColor3 = isSel and Theme.ElementHover or Theme.SidebarBg
                                            ch2.TextColor3 = isSel and Theme.Accent or Theme.TextDim
                                        end
                                    end
                                    if callback then callback(selected) end
                                end
                            end
                        end
                    end,
                    Get = function() return selected end,
                    Refresh = function(_, newList)
                        for _, ch in ipairs(DScroll:GetChildren()) do
                            if ch:IsA("TextButton") then ch:Destroy() end
                        end
                        list = newList
                        DROP_HEIGHT = math.min(#list * 26, 120)
                        for _, item in ipairs(list) do
                            local IBtn2 = Instance.new("TextButton", DScroll)
                            IBtn2.Size = UDim2.new(1,0,0,26)
                            IBtn2.BackgroundColor3 = Theme.SidebarBg
                            IBtn2.Text = "  " .. tostring(item)
                            IBtn2.TextColor3 = Theme.TextDim
                            IBtn2.Font = Enum.Font.Gotham
                            IBtn2.TextSize = 12
                            IBtn2.TextXAlignment = Enum.TextXAlignment.Left
                            IBtn2.BorderSizePixel = 0
                            IBtn2.MouseButton1Click:Connect(function()
                                selected = item; DBtnTxt.Text = tostring(selected)
                                if flag then Library.Flags[flag] = selected end
                                isOpen = false
                                Tween(DFrame, 0.2, {Size = UDim2.new(1,0,0,46)}):Play()
                                Tween(DArrow, 0.2, {Rotation = 0}):Play()
                                if callback then callback(selected) end
                                if Library._autoSave then Library:SaveConfig() end
                            end)
                            Instance.new("UICorner", IBtn2).CornerRadius = UDim.new(0, 4)
                        end
                        -- Also update DScroll size
                        DScroll.Size = UDim2.new(1, 0, 0, math.min(#newList * 26, 120))
                    end,
                }
            end

            -- 10. MULTI-SELECT DROPDOWN
            function Section:AddMultiDropdown(info, listArg, cbArg)
                local text, list, defaults, callback, flag, tooltip
                if type(info) == "table" then
                    text     = info.Name
                    list     = info.Options
                    defaults = info.Default or {}
                    callback = listArg
                    flag     = info.Flag
                    tooltip  = info.Tooltip
                else
                    text = info; list = listArg; defaults = {}; callback = cbArg
                end

                registerFlag(flag, defaults)
                local selected = (flag and Library.Flags[flag]) or {}
                if type(selected) ~= "table" then selected = {} end

                local DROP_HEIGHT = math.min(#list * 26, 130)

                local MDFrame = Instance.new("Frame", Inner)
                MDFrame.Size             = UDim2.new(1, 0, 0, 46)
                MDFrame.BackgroundTransparency = 1
                MDFrame.ClipsDescendants = true
                AddTooltip(MDFrame, tooltip)

                local MDLbl = Instance.new("TextLabel", MDFrame)
                MDLbl.Size             = UDim2.new(1, 0, 0, 16)
                MDLbl.BackgroundTransparency = 1
                MDLbl.Text             = text
                MDLbl.TextColor3       = Theme.TextDim
                MDLbl.Font             = Enum.Font.Gotham
                MDLbl.TextSize         = 11
                MDLbl.TextXAlignment   = Enum.TextXAlignment.Left

                local MDBtn = Instance.new("TextButton", MDFrame)
                MDBtn.Size             = UDim2.new(1, 0, 0, 28)
                MDBtn.Position         = UDim2.new(0, 0, 0, 18)
                MDBtn.BackgroundColor3 = Theme.ElementBg
                MDBtn.Text             = ""
                MDBtn.BorderSizePixel  = 0
                Instance.new("UICorner", MDBtn).CornerRadius = UDim.new(0, 5)

                local MDBtnTxt = Instance.new("TextLabel", MDBtn)
                MDBtnTxt.Size             = UDim2.new(1, -30, 1, 0)
                MDBtnTxt.Position         = UDim2.new(0, 10, 0, 0)
                MDBtnTxt.BackgroundTransparency = 1
                MDBtnTxt.TextColor3       = Theme.TextDim
                MDBtnTxt.Font             = Enum.Font.Gotham
                MDBtnTxt.TextSize         = 11
                MDBtnTxt.TextXAlignment   = Enum.TextXAlignment.Left
                MDBtnTxt.TextTruncate     = Enum.TextTruncate.AtEnd

                local MDArrow = Instance.new("TextLabel", MDBtn)
                MDArrow.Size             = UDim2.new(0, 22, 1, 0)
                MDArrow.Position         = UDim2.new(1, -22, 0, 0)
                MDArrow.BackgroundTransparency = 1
                MDArrow.Text             = "▾"
                MDArrow.TextColor3       = Theme.TextDim
                MDArrow.Font             = Enum.Font.GothamBold
                MDArrow.TextSize         = 12

                local MDScroll = Instance.new("ScrollingFrame", MDFrame)
                MDScroll.Size             = UDim2.new(1, 0, 0, DROP_HEIGHT)
                MDScroll.Position         = UDim2.new(0, 0, 0, 48)
                MDScroll.BackgroundColor3 = Theme.ElementBg
                MDScroll.ScrollBarThickness = 3
                MDScroll.ScrollBarImageColor3 = Theme.Accent
                MDScroll.CanvasSize       = UDim2.new(0, 0, 0, 0)
                MDScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                MDScroll.BorderSizePixel  = 0
                Instance.new("UICorner", MDScroll).CornerRadius = UDim.new(0, 5)
                Instance.new("UIListLayout", MDScroll).Padding = UDim.new(0, 1)

                local function updateDisplay()
                    if #selected == 0 then
                        MDBtnTxt.Text       = "None selected"
                        MDBtnTxt.TextColor3 = Theme.TextDim
                    else
                        MDBtnTxt.Text       = table.concat(selected, ", ")
                        MDBtnTxt.TextColor3 = Theme.Text
                    end
                    if flag then Library.Flags[flag] = selected end
                    if callback then callback(selected) end
                end

                for _, item in ipairs(list) do
                    local checked = table.find(selected, item) ~= nil
                    local IRow = Instance.new("TextButton", MDScroll)
                    IRow.Size             = UDim2.new(1, 0, 0, 28)
                    IRow.BackgroundColor3 = checked and Theme.ElementHover or Theme.SidebarBg
                    IRow.Text             = ""
                    IRow.BorderSizePixel  = 0

                    local ICheck = Instance.new("TextLabel", IRow)
                    ICheck.Size            = UDim2.new(0, 22, 1, 0)
                    ICheck.Position        = UDim2.new(0, 5, 0, 0)
                    ICheck.BackgroundTransparency = 1
                    ICheck.Text            = checked and "☑" or "☐"
                    ICheck.TextColor3      = checked and Theme.Accent or Theme.TextDim
                    ICheck.Font            = Enum.Font.GothamBold
                    ICheck.TextSize        = 14

                    local IName = Instance.new("TextLabel", IRow)
                    IName.Size             = UDim2.new(1, -30, 1, 0)
                    IName.Position         = UDim2.new(0, 28, 0, 0)
                    IName.BackgroundTransparency = 1
                    IName.Text             = tostring(item)
                    IName.TextColor3       = checked and Theme.Text or Theme.TextDim
                    IName.Font             = Enum.Font.Gotham
                    IName.TextSize         = 12
                    IName.TextXAlignment   = Enum.TextXAlignment.Left

                    IRow.MouseButton1Click:Connect(function()
                        local idx = table.find(selected, item)
                        if idx then
                            table.remove(selected, idx)
                            ICheck.Text       = "☐"
                            ICheck.TextColor3 = Theme.TextDim
                            IName.TextColor3  = Theme.TextDim
                            Tween(IRow, 0.1, {BackgroundColor3 = Theme.SidebarBg}):Play()
                        else
                            table.insert(selected, item)
                            ICheck.Text       = "☑"
                            ICheck.TextColor3 = Theme.Accent
                            IName.TextColor3  = Theme.Text
                            Tween(IRow, 0.1, {BackgroundColor3 = Theme.ElementHover}):Play()
                        end
                        updateDisplay()
                    end)
                end

                updateDisplay()

                local mdOpen = false
                MDBtn.MouseButton1Click:Connect(function()
                    mdOpen = not mdOpen
                    Tween(MDFrame, 0.2, {Size = UDim2.new(1, 0, 0, mdOpen and (46 + DROP_HEIGHT + 2) or 46)}):Play()
                    Tween(MDArrow, 0.2, {Rotation = mdOpen and 180 or 0}):Play()
                end)

                registerItem(text, MDFrame)
                return {
                    Get = function() return selected end,
                    Set = function(_, newSel)
                        selected = newSel
                        updateDisplay()
                    end,
                    -- Rebuild the dropdown with a fresh list
                    Refresh = function(_, newList)
                        list = newList
                        DROP_HEIGHT = math.min(#list * 28, 130)
                        MDScroll.Size = UDim2.new(1, 0, 0, DROP_HEIGHT)
                        -- Clear old rows
                        for _, ch in ipairs(MDScroll:GetChildren()) do
                            if ch:IsA("TextButton") then ch:Destroy() end
                        end
                        -- Rebuild rows
                        for _, item in ipairs(list) do
                            local checked = table.find(selected, item) ~= nil
                            local IRow2 = Instance.new("TextButton", MDScroll)
                            IRow2.Size            = UDim2.new(1, 0, 0, 28)
                            IRow2.BackgroundColor3 = checked and Theme.ElementHover or Theme.SidebarBg
                            IRow2.Text            = ""
                            IRow2.BorderSizePixel  = 0
                            local IC2 = Instance.new("TextLabel", IRow2)
                            IC2.Size = UDim2.new(0, 22, 1, 0)
                            IC2.Position = UDim2.new(0, 5, 0, 0)
                            IC2.BackgroundTransparency = 1
                            IC2.Text = checked and "☑" or "☐"
                            IC2.TextColor3 = checked and Theme.Accent or Theme.TextDim
                            IC2.Font = Enum.Font.GothamBold
                            IC2.TextSize = 14
                            local IN2 = Instance.new("TextLabel", IRow2)
                            IN2.Size = UDim2.new(1, -30, 1, 0)
                            IN2.Position = UDim2.new(0, 28, 0, 0)
                            IN2.BackgroundTransparency = 1
                            IN2.Text = tostring(item)
                            IN2.TextColor3 = checked and Theme.Text or Theme.TextDim
                            IN2.Font = Enum.Font.Gotham
                            IN2.TextSize = 12
                            IN2.TextXAlignment = Enum.TextXAlignment.Left
                            IRow2.MouseButton1Click:Connect(function()
                                local idx = table.find(selected, item)
                                if idx then
                                    table.remove(selected, idx)
                                    IC2.Text = "☐"; IC2.TextColor3 = Theme.TextDim
                                    IN2.TextColor3 = Theme.TextDim
                                    Tween(IRow2, 0.1, {BackgroundColor3 = Theme.SidebarBg}):Play()
                                else
                                    table.insert(selected, item)
                                    IC2.Text = "☑"; IC2.TextColor3 = Theme.Accent
                                    IN2.TextColor3 = Theme.Text
                                    Tween(IRow2, 0.1, {BackgroundColor3 = Theme.ElementHover}):Play()
                                end
                                updateDisplay()
                                if flag then Library.Flags[flag] = selected end
                                if callback then callback(selected) end
                            end)
                        end
                        updateDisplay()
                    end,
                }
            end

            -- 11. TEXT INPUT
            function Section:AddInput(info, placeholderArg, cbArg)
                local text, placeholder, callback, tooltip
                if type(info) == "table" then
                    text        = info.Name
                    placeholder = info.Placeholder or ""
                    callback    = placeholderArg
                    tooltip     = info.Tooltip
                else
                    text = info; placeholder = placeholderArg; callback = cbArg
                end

                local InpFrame = Instance.new("Frame", Inner)
                InpFrame.Size             = UDim2.new(1, 0, 0, 46)
                InpFrame.BackgroundTransparency = 1
                AddTooltip(InpFrame, tooltip)

                local ILbl = Instance.new("TextLabel", InpFrame)
                ILbl.Size             = UDim2.new(1, 0, 0, 16)
                ILbl.BackgroundTransparency = 1
                ILbl.Text             = text
                ILbl.TextColor3       = Theme.TextDim
                ILbl.Font             = Enum.Font.Gotham
                ILbl.TextSize         = 11
                ILbl.TextXAlignment   = Enum.TextXAlignment.Left

                local Box = Instance.new("TextBox", InpFrame)
                Box.Size             = UDim2.new(1, 0, 0, 28)
                Box.Position         = UDim2.new(0, 0, 0, 18)
                Box.BackgroundColor3 = Theme.ElementBg
                Box.BorderSizePixel  = 0
                Box.Text             = ""
                Box.PlaceholderText  = placeholder
                Box.TextColor3       = Theme.Text
                Box.PlaceholderColor3= Theme.TextDim
                Box.Font             = Enum.Font.Gotham
                Box.TextSize         = 12
                Box.TextXAlignment   = Enum.TextXAlignment.Left
                Box.ClearTextOnFocus = false
                Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 5)
                local IBPad = Instance.new("UIPadding", Box)
                IBPad.PaddingLeft = UDim.new(0, 10)
                -- Focus glow (FIXED)
                local IBStroke = Instance.new("UIStroke", Box)
                IBStroke.Color     = Theme.Border
                IBStroke.Thickness = 1
                Box.Focused:Connect(function()
                    Tween(IBStroke, 0.2, {Color = Theme.Accent, Thickness = 1.5}):Play()
                end)
                Box.FocusLost:Connect(function(ep)
                    Tween(IBStroke, 0.2, {Color = Theme.Border, Thickness = 1}):Play()
                    if ep and callback then callback(Box.Text) end
                end)
                registerItem(text, InpFrame)
                return {
                    Get = function() return Box.Text end,
                    Set = function(_, v) Box.Text = v end,
                }
            end

            -- 12. PROGRESS BAR
            function Section:AddProgressBar(info)
                local text    = type(info) == "table" and info.Name    or info
                local max_    = type(info) == "table" and info.Max     or 100
                local initial = type(info) == "table" and info.Default or 0
                local tooltip = type(info) == "table" and info.Tooltip or ""

                local PBFrame = Instance.new("Frame", Inner)
                PBFrame.Size             = UDim2.new(1, 0, 0, 40)
                PBFrame.BackgroundTransparency = 1
                AddTooltip(PBFrame, tooltip)

                local PBLbl = Instance.new("TextLabel", PBFrame)
                PBLbl.Size             = UDim2.new(1, -40, 0, 16)
                PBLbl.BackgroundTransparency = 1
                PBLbl.Text             = text
                PBLbl.TextColor3       = Theme.Text
                PBLbl.Font             = Enum.Font.Gotham
                PBLbl.TextSize         = 12
                PBLbl.TextXAlignment   = Enum.TextXAlignment.Left

                local PBPct = Instance.new("TextLabel", PBFrame)
                PBPct.Size             = UDim2.new(0, 40, 0, 16)
                PBPct.Position         = UDim2.new(1, -40, 0, 0)
                PBPct.BackgroundTransparency = 1
                PBPct.Text             = "0%"
                PBPct.TextColor3       = Theme.Accent
                PBPct.Font             = Enum.Font.GothamBold
                PBPct.TextSize         = 12
                PBPct.TextXAlignment   = Enum.TextXAlignment.Right

                local PBBg = Instance.new("Frame", PBFrame)
                PBBg.Size             = UDim2.new(1, 0, 0, 8)
                PBBg.Position         = UDim2.new(0, 0, 0, 26)
                PBBg.BackgroundColor3 = Theme.ElementBg
                PBBg.BorderSizePixel  = 0
                Instance.new("UICorner", PBBg).CornerRadius = UDim.new(1, 0)

                local PBFill = Instance.new("Frame", PBBg)
                PBFill.Size             = UDim2.new(0, 0, 1, 0)
                PBFill.BackgroundColor3 = Theme.Accent
                PBFill.BorderSizePixel  = 0
                Instance.new("UICorner", PBFill).CornerRadius = UDim.new(1, 0)

                local curVal = 0
                local curMax = max_

                local function SetPB(v, newMax)
                    if newMax then curMax = newMax end
                    curVal = math.clamp(v, 0, curMax)
                    local pct = curMax > 0 and curVal / curMax or 0
                    Tween(PBFill, 0.3, {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                    PBPct.Text = math.floor(pct * 100) .. "%"
                end

                SetPB(initial)
                registerItem(text, PBFrame)
                return {
                    Set    = function(_, v, m) SetPB(v, m) end,
                    SetMax = function(_, m) curMax = m end,
                    Get    = function() return curVal end,
                }
            end

            -- 13. COLOR PICKER
            function Section:AddColorPicker(info, defaultColor, cbArg)
                local text, default, callback, flag, tooltip
                if type(info) == "table" then
                    text     = info.Name
                    default  = info.Default or Color3.fromRGB(0, 170, 255)
                    callback = defaultColor
                    flag     = info.Flag
                    tooltip  = info.Tooltip
                else
                    text = info; default = defaultColor or Color3.fromRGB(0, 170, 255); callback = cbArg
                end

                registerFlag(flag, {default.R, default.G, default.B})
                local currentColor = default

                local CPRow = Instance.new("Frame", Inner)
                CPRow.Size             = UDim2.new(1, 0, 0, 30)
                CPRow.BackgroundTransparency = 1
                CPRow.ClipsDescendants = false
                AddTooltip(CPRow, tooltip)

                local CPLbl = Instance.new("TextLabel", CPRow)
                CPLbl.Size             = UDim2.new(1, -80, 1, 0)
                CPLbl.BackgroundTransparency = 1
                CPLbl.Text             = text
                CPLbl.TextColor3       = Theme.Text
                CPLbl.Font             = Enum.Font.Gotham
                CPLbl.TextSize         = 12
                CPLbl.TextXAlignment   = Enum.TextXAlignment.Left

                -- Color preview swatch
                local Swatch = Instance.new("TextButton", CPRow)
                Swatch.Size             = UDim2.new(0, 32, 0, 22)
                Swatch.Position         = UDim2.new(1, -72, 0.5, -11)
                Swatch.BackgroundColor3 = currentColor
                Swatch.Text             = ""
                Swatch.BorderSizePixel  = 0
                Instance.new("UICorner", Swatch).CornerRadius = UDim.new(0, 5)
                local SwatchStroke = Instance.new("UIStroke", Swatch)
                SwatchStroke.Color     = Theme.Border
                SwatchStroke.Thickness = 1

                -- Hex label
                local HexLbl = Instance.new("TextLabel", CPRow)
                HexLbl.Size             = UDim2.new(0, 36, 1, 0)
                HexLbl.Position         = UDim2.new(1, -38, 0, 0)
                HexLbl.BackgroundTransparency = 1
                HexLbl.Font             = Enum.Font.Code
                HexLbl.TextSize         = 10
                HexLbl.TextColor3       = Theme.TextDim
                HexLbl.TextXAlignment   = Enum.TextXAlignment.Left

                local function ToHex(c)
                    return string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
                end

                local function SetColor(c)
                    currentColor = c
                    Swatch.BackgroundColor3 = c
                    HexLbl.Text = ToHex(c)
                    if flag then Library.Flags[flag] = {c.R, c.G, c.B} end
                    if callback then callback(c) end
                end

                SetColor(currentColor)

                -- ── Picker Panel (inline, appears below CPRow in Inner layout) ──
                local isOpen = false
                local PickerPanel = Instance.new("Frame", Inner)  -- same parent as CPRow so layout accounts for it
                PickerPanel.Size             = UDim2.new(1, 0, 0, 0)   -- starts collapsed
                PickerPanel.BackgroundColor3 = Theme.ElementBg
                PickerPanel.BorderSizePixel  = 0
                PickerPanel.ClipsDescendants = true
                Instance.new("UICorner", PickerPanel).CornerRadius = UDim.new(0, 6)
                local PPPad = Instance.new("UIPadding", PickerPanel)
                PPPad.PaddingLeft = UDim.new(0, 8)
                PPPad.PaddingRight= UDim.new(0, 8)
                PPPad.PaddingTop  = UDim.new(0, 8)

                -- SV (Saturation/Value) square
                local SVBox = Instance.new("Frame", PickerPanel)
                SVBox.Size             = UDim2.new(1, -55, 0, 90)
                SVBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                SVBox.BorderSizePixel  = 0
                Instance.new("UICorner", SVBox).CornerRadius = UDim.new(0, 4)
                -- White gradient (saturation)
                local SVImg = Instance.new("ImageLabel", SVBox)
                SVImg.Size             = UDim2.new(1, 0, 1, 0)
                SVImg.BackgroundTransparency = 1
                SVImg.Image            = "rbxassetid://4155801252"  -- white-to-transparent gradient
                SVImg.ScaleType        = Enum.ScaleType.Stretch
                -- Dark gradient (value)
                local SVImg2 = Instance.new("ImageLabel", SVBox)
                SVImg2.Size            = UDim2.new(1, 0, 1, 0)
                SVImg2.BackgroundTransparency = 1
                SVImg2.Image           = "rbxassetid://4155801252"
                SVImg2.ImageColor3     = Color3.fromRGB(0, 0, 0)
                SVImg2.ScaleType       = Enum.ScaleType.Stretch
                SVImg2.Rotation        = 90
                -- Cursor
                local SVCursor = Instance.new("Frame", SVBox)
                SVCursor.Size          = UDim2.new(0, 10, 0, 10)
                SVCursor.AnchorPoint   = Vector2.new(0.5, 0.5)
                SVCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SVCursor.BorderSizePixel = 0
                Instance.new("UICorner", SVCursor).CornerRadius = UDim.new(1, 0)
                Instance.new("UIStroke", SVCursor).Thickness = 1.5

                -- Hue bar (vertical)
                local HueBar = Instance.new("Frame", PickerPanel)
                HueBar.Size             = UDim2.new(0, 14, 0, 90)
                HueBar.Position         = UDim2.new(1, -45, 0, 8)
                HueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HueBar.BorderSizePixel  = 0
                Instance.new("UICorner", HueBar).CornerRadius = UDim.new(0, 4)
                local HueImg = Instance.new("ImageLabel", HueBar)
                HueImg.Size            = UDim2.new(1, 0, 1, 0)
                HueImg.BackgroundTransparency = 1
                HueImg.Image           = "rbxassetid://698846550"  -- hue spectrum
                HueImg.ScaleType       = Enum.ScaleType.Stretch
                -- Hue cursor
                local HueCursor = Instance.new("Frame", HueBar)
                HueCursor.Size         = UDim2.new(1, 4, 0, 4)
                HueCursor.Position     = UDim2.new(0, -2, 0, 0)
                HueCursor.AnchorPoint  = Vector2.new(0, 0.5)
                HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HueCursor.BorderSizePixel = 0
                Instance.new("UICorner", HueCursor).CornerRadius = UDim.new(0, 2)
                Instance.new("UIStroke", HueCursor).Thickness = 1

                local h, s, v = RgbToHsv(currentColor)
                SVBox.BackgroundColor3 = HsvToRgb(h, 1, 1)
                SVCursor.Position      = UDim2.new(s, 0, 1-v, 0)
                HueCursor.Position     = UDim2.new(0, -2, h, 0)

                local function updateFromHSV()
                    SetColor(HsvToRgb(h, s, v))
                    SVBox.BackgroundColor3 = HsvToRgb(h, 1, 1)
                    SVCursor.Position = UDim2.new(s, -5, 1-v, -5)
                    HueCursor.Position = UDim2.new(0, -2, h, 0)
                end

                -- SV interaction
                local svDragging = false
                local SVBtn = Instance.new("TextButton", SVBox)
                SVBtn.Size = UDim2.new(1,0,1,0); SVBtn.BackgroundTransparency=1; SVBtn.Text=""
                SVBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        svDragging = true
                        s = math.clamp((inp.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((inp.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                        updateFromHSV()
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if svDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        s = math.clamp((inp.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((inp.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                        updateFromHSV()
                    end
                end)

                -- Hue interaction
                local hueDragging = false
                local HueBtn = Instance.new("TextButton", HueBar)
                HueBtn.Size=UDim2.new(1,0,1,0); HueBtn.BackgroundTransparency=1; HueBtn.Text=""
                HueBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDragging = true
                        h = math.clamp((inp.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                        updateFromHSV()
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if hueDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        h = math.clamp((inp.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                        updateFromHSV()
                    end
                end)

                -- Toggle picker — animate height in Inner layout
                Swatch.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        PickerPanel.Visible = true
                        Tween(PickerPanel, 0.2, {Size = UDim2.new(1, 0, 0, 130)}, Enum.EasingStyle.Quad):Play()
                        Tween(SwatchStroke, 0.15, {Color = Theme.Accent}):Play()
                    else
                        local tw = Tween(PickerPanel, 0.2, {Size = UDim2.new(1, 0, 0, 0)}, Enum.EasingStyle.Quad)
                        tw:Play()
                        tw.Completed:Connect(function() PickerPanel.Visible = false end)
                        Tween(SwatchStroke, 0.15, {Color = Theme.Border}):Play()
                    end
                end)

                registerItem(text, CPRow)
                return {
                    Set = function(_, c) SetColor(c); h,s,v = RgbToHsv(c); updateFromHSV() end,
                    Get = function() return currentColor end,
                }
            end

            -- 14. CONSOLE / LOG
            function Section:AddConsole(name)
                local CF = Instance.new("Frame", Inner)
                CF.Size             = UDim2.new(1, 0, 0, 120)
                CF.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
                CF.BorderSizePixel  = 0
                Instance.new("UICorner", CF).CornerRadius = Theme.Radius
                local CStroke = Instance.new("UIStroke", CF)
                CStroke.Color     = Theme.Border
                CStroke.Thickness = 1

                local CScroll = Instance.new("ScrollingFrame", CF)
                CScroll.Size             = UDim2.new(1, -8, 1, -8)
                CScroll.Position         = UDim2.new(0, 4, 0, 4)
                CScroll.BackgroundTransparency = 1
                CScroll.ScrollBarThickness = 3
                CScroll.ScrollBarImageColor3 = Theme.Accent
                CScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                CScroll.CanvasSize       = UDim2.new(0, 0, 0, 0)
                CScroll.BorderSizePixel  = 0
                local CLayout = Instance.new("UIListLayout", CScroll)
                CLayout.Padding = UDim.new(0, 1)

                local typeColorMap = {
                    info    = Theme.TextDim,
                    success = Theme.Success or Color3.fromRGB(60, 210, 130),
                    warn    = Theme.Warning or Color3.fromRGB(255, 190, 50),
                    error   = Theme.Error   or Color3.fromRGB(255, 80, 80),
                }

                registerItem(name or "Console", CF)
                return {
                    Log = function(_, msg, logType)
                        local color = typeColorMap[logType or "info"] or Theme.TextDim
                        local prefix = logType == "success" and "✔  "
                            or logType == "warn" and "⚠  "
                            or logType == "error" and "✖  "
                            or "›  "
                        local line = Instance.new("TextLabel", CScroll)
                        line.Size             = UDim2.new(1, 0, 0, 14)
                        line.BackgroundTransparency = 1
                        line.Text             = prefix .. msg
                        line.TextColor3       = color
                        line.Font             = Enum.Font.Code
                        line.TextSize         = 11
                        line.TextXAlignment   = Enum.TextXAlignment.Left
                        line.TextWrapped      = true
                        line.AutomaticSize    = Enum.AutomaticSize.Y
                        task.defer(function()
                            CScroll.CanvasPosition = Vector2.new(0, CLayout.AbsoluteContentSize.Y)
                        end)
                    end,
                    Clear = function()
                        for _, ch in ipairs(CScroll:GetChildren()) do
                            if ch:IsA("TextLabel") then ch:Destroy() end
                        end
                    end,
                }
            end

            return Section
        end -- AddSection

        -- CONFIG MANAGER UI (as a special section)
        function TabObj:AddConfigManager()
            local Sec = self:AddSection("⚙  Config Manager", false)

            Sec:AddButton({Name = "💾  Save Config", Tooltip = "Save current settings"}, function()
                Library:SaveConfig()
                Library:Notify({Title="Config Saved", Content="Settings saved to " .. Library.ConfigName .. ".json", Type="Success", Duration=3})
            end)

            Sec:AddButton({Name = "📂  Load Config", Tooltip = "Load saved settings"}, function()
                Library:LoadConfig()
                Library:Notify({Title="Config Loaded", Content="Settings loaded from " .. Library.ConfigName .. ".json", Type="Info", Duration=3})
            end)

            -- Auto-save toggle
            Sec:AddToggle({Name = "Auto-Save", Default = false, Tooltip = "Save automatically on change"}, function(v)
                Library._autoSave = v
                if v then
                    Library:Notify({Title="Auto-Save ON", Content="Config will save on every change", Type="Success", Duration=2})
                end
            end)

            -- Theme selector
            Sec:AddDropdown({Name = "Theme", Options = {"Blue","Red","Purple","Green","Orange"}, Default = "Blue"}, function(val)
                Library:SetTheme(val)
                Library:Notify({Title="Theme Changed", Content="Theme set to " .. val, Type="Info", Duration=2})
            end)

            return Sec
        end

        -- CHANGELOG (as special section)
        function TabObj:AddChangelog(entries)
            -- entries = {{"v1.1", "Added aimbot"}, {"v1.0", "Initial release"}}
            local Sec = self:AddSection("📋  Changelog", true)
            for i = 1, math.min(#entries, 10) do
                local entry = entries[i]
                Sec:AddParagraph(entry[1] or "v?", entry[2] or "")
            end
            return Sec
        end

        return TabObj
    end -- MakeTab

    -- Config Manager (window-level)
    function Window:AddConfigManager()
        local tab = self:MakeTab({Icon="⚙", Name="Config"})
        return tab:AddConfigManager()
    end

    -- ── RESIZING ENGINE ──────────────────────────
    local function SetupResizing(mainFrame, minW, minH)
        minW = minW or 350
        minH = minH or 250
        
        -- Right resize edge strip
        local RightResize = Instance.new("Frame", mainFrame)
        RightResize.Name = "RightResize"
        RightResize.Size = UDim2.new(0, 8, 1, -20)
        RightResize.Position = UDim2.new(1, -4, 0, 10)
        RightResize.BackgroundTransparency = 1
        RightResize.ZIndex = 101
        
        -- Bottom resize edge strip
        local BottomResize = Instance.new("Frame", mainFrame)
        BottomResize.Name = "BottomResize"
        BottomResize.Size = UDim2.new(1, -20, 0, 8)
        BottomResize.Position = UDim2.new(0, 10, 1, -4)
        BottomResize.BackgroundTransparency = 1
        BottomResize.ZIndex = 101

        -- Bottom-Right corner resize grip button
        local CornerResize = Instance.new("ImageButton", mainFrame)
        CornerResize.Name = "CornerResize"
        CornerResize.Size = UDim2.new(0, 12, 0, 12)
        CornerResize.Position = UDim2.new(1, -12, 1, -12)
        CornerResize.BackgroundTransparency = 1
        CornerResize.Image = "rbxassetid://6032731804" -- standard diagonal resize grip icon
        CornerResize.ImageColor3 = Theme.TextDim
        CornerResize.ImageTransparency = 0.5
        CornerResize.ZIndex = 102
        
        CornerResize.MouseEnter:Connect(function()
            CornerResize.ImageTransparency = 0
            CornerResize.ImageColor3 = Theme.Accent
        end)
        CornerResize.MouseLeave:Connect(function()
            CornerResize.ImageTransparency = 0.5
            CornerResize.ImageColor3 = Theme.TextDim
        end)

        local function MakeEdgeResizable(dragPoint, resizeX, resizeY)
            local resizing = false
            local dragInput, mousePos, startSize

            dragPoint.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    resizing = true
                    mousePos = input.Position
                    startSize = mainFrame.Size
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            resizing = false
                        end
                    end)
                end
            end)

            dragPoint.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragInput = input
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and resizing then
                    local delta = input.Position - mousePos
                    local newW = startSize.X.Offset
                    local newH = startSize.Y.Offset
                    
                    if resizeX then
                        newW = math.max(minW, startSize.X.Offset + delta.X)
                        currentWidth = newW
                    end
                    if resizeY then
                        newH = math.max(minH, startSize.Y.Offset + delta.Y)
                        currentHeight = newH
                    end
                    
                    Tween(mainFrame, 0.05, {Size = UDim2.new(0, newW, 0, newH)}):Play()
                end
            end)
        end

        MakeEdgeResizable(RightResize, true, false)
        MakeEdgeResizable(BottomResize, false, true)
        MakeEdgeResizable(CornerResize, true, true)
    end

    SetupResizing(MainFrame, 400, 250)

    return Window
end -- CreateWindow

-- ══════════════════════════════════════════
--  SAVE / LOAD CONFIG (IMPROVED)
-- ══════════════════════════════════════════
function Library:SaveConfig()
    if not writefile then return end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(self.Flags) end)
    if ok then
        pcall(function() writefile(self.ConfigName .. ".json", encoded) end)
    end
end

function Library:LoadConfig()
    if not readfile or not isfile then return end
    local ok1, exists = pcall(function() return isfile(self.ConfigName .. ".json") end)
    if not ok1 or not exists then return end
    local ok2, decoded = pcall(function() return HttpService:JSONDecode(readfile(self.ConfigName .. ".json")) end)
    if ok2 and type(decoded) == "table" then
        for k, v in pairs(decoded) do
            self.Flags[k] = v
        end
    end
end

function Library:AutoSave(interval)
    self._autoSave = true
    -- Interval-based auto-save (separate from per-change auto-save)
    if interval and interval > 0 then
        -- Cancel previous auto-save loop if any
        if self._autoSaveThread then
            task.cancel(self._autoSaveThread)
        end
        self._autoSaveThread = task.spawn(function()
            while self._autoSave do
                task.wait(interval)
                if self._autoSave then
                    self:SaveConfig()
                end
            end
        end)
    end
end

function Library:StopAutoSave()
    self._autoSave = false
    if self._autoSaveThread then
        task.cancel(self._autoSaveThread)
        self._autoSaveThread = nil
    end
end

-- ===========================================================================
--  THEME SHORTCUT
-- ===========================================================================
Library.Themes = Themes

return Library
