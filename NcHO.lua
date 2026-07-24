--[[
    Blue Compact Hub UI Library (V3 - Ultimate Edition)
    Base: V2 Overlap Fixed
    New Features: Config Saver, Dynamic Updates, Ripple, Glassmorphism, Tooltips, Active Search, Watermark, Console
]]

local Library = { Flags = {}, ConfigName = "BlueHub_Config" }
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local function getSafeParent()
    if gethui then return gethui() end
    local success, core = pcall(function() return CoreGui end)
    if success and core then return core end
    return game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function MakeDraggable(dragPoint, objectToMove)
    local dragging = false
    local dragInput, mousePos, framePos

    dragPoint.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; mousePos = input.Position; framePos = objectToMove.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragPoint.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            TweenService:Create(objectToMove, TweenInfo.new(0.08), {Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)}):Play()
        end
    end)
end

-- EFEK RIPPLE (GELOMBANG KLIK)
local function CreateRipple(parent, input)
    local ripple = Instance.new("Frame")
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.8
    ripple.BorderSizePixel = 0
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
    
    local x, y = input.Position.X - parent.AbsolutePosition.X, input.Position.Y - parent.AbsolutePosition.Y
    ripple.Position = UDim2.new(0, x, 0, y)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Parent = parent
    
    local endSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 1.5
    local tween = TweenService:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, endSize, 0, endSize), 
        Position = UDim2.new(0, x - endSize/2, 0, y - endSize/2), 
        BackgroundTransparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function() ripple:Destroy() end)
end

-- TEMA WARNA BIRU NEON (Update Glassmorphism)
local Theme = {
    MainBg = Color3.fromRGB(20, 20, 22),
    SidebarBg = Color3.fromRGB(15, 15, 17),
    ElementBg = Color3.fromRGB(30, 30, 35),
    ElementHover = Color3.fromRGB(38, 38, 43),
    Accent = Color3.fromRGB(0, 170, 255),
    Warning = Color3.fromRGB(255, 100, 100),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 150),
    Transparency = 0.05, -- Glassmorphism
    Radius = UDim.new(0, 6)
}

-- SISTEM NOTIFIKASI
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "BlueUI_Notifications"
NotifGui.Parent = getSafeParent()
local NotifLayout = Instance.new("Frame")
NotifLayout.Size = UDim2.new(0, 250, 1, -20)
NotifLayout.Position = UDim2.new(1, -270, 0, 10)
NotifLayout.BackgroundTransparency = 1
NotifLayout.Parent = NotifGui
local UIListNotif = Instance.new("UIListLayout")
UIListNotif.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListNotif.Padding = UDim.new(0, 10)
UIListNotif.Parent = NotifLayout

function Library:Notify(title, content, duration)
    local dur = duration or 3
    local NFrame = Instance.new("Frame")
    NFrame.Size = UDim2.new(1, 0, 0, 60)
    NFrame.BackgroundColor3 = Theme.SidebarBg
    NFrame.Position = UDim2.new(1, 300, 0, 0)
    NFrame.Parent = NotifLayout
    Instance.new("UICorner", NFrame).CornerRadius = Theme.Radius
    local NStroke = Instance.new("UIStroke")
    NStroke.Color = Theme.Accent
    NStroke.Thickness = 1.5
    NStroke.Parent = NFrame

    local NTitle = Instance.new("TextLabel")
    NTitle.Size = UDim2.new(1, -20, 0, 20)
    NTitle.Position = UDim2.new(0, 10, 0, 5)
    NTitle.BackgroundTransparency = 1
    NTitle.Text = title
    NTitle.TextColor3 = Theme.Accent
    NTitle.Font = Enum.Font.GothamBold
    NTitle.TextSize = 13
    NTitle.TextXAlignment = Enum.TextXAlignment.Left
    NTitle.Parent = NFrame

    local NText = Instance.new("TextLabel")
    NText.Size = UDim2.new(1, -20, 0, 30)
    NText.Position = UDim2.new(0, 10, 0, 25)
    NText.BackgroundTransparency = 1
    NText.Text = content
    NText.TextColor3 = Theme.Text
    NText.Font = Enum.Font.Gotham
    NText.TextSize = 12
    NText.TextXAlignment = Enum.TextXAlignment.Left
    NText.TextWrapped = true
    NText.Parent = NFrame

    TweenService:Create(NFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    task.delay(dur, function()
        local tweenOut = TweenService:Create(NFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1, 300, 0, 0)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function() NFrame:Destroy() end)
    end)
end

function Library:CreateWindow(config)
    local titleText = config.Name or "Compact Hub"
    local footerText = config.Footer or "discord.gg/yourlink | v1.0"
    local logoIcon = config.LogoText or "S"
    self.ConfigName = config.ConfigName or "BlueHub_Config"

    local targetParent = getSafeParent()
    if targetParent:FindFirstChild("BlueCompactUI") then
        targetParent.BlueCompactUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BlueCompactUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = targetParent

    -- SISTEM TOOLTIP (INFO MENGAMBANG)
    local TooltipGui = Instance.new("Frame")
    TooltipGui.Size = UDim2.new(0, 200, 0, 30)
    TooltipGui.BackgroundColor3 = Theme.ElementBg
    TooltipGui.Visible = false
    TooltipGui.ZIndex = 100
    TooltipGui.Parent = ScreenGui
    Instance.new("UICorner", TooltipGui).CornerRadius = Theme.Radius
    local TtStroke = Instance.new("UIStroke")
    TtStroke.Color = Theme.Accent
    TtStroke.Parent = TooltipGui
    local TooltipText = Instance.new("TextLabel")
    TooltipText.Size = UDim2.new(1, -10, 1, 0)
    TooltipText.Position = UDim2.new(0, 5, 0, 0)
    TooltipText.BackgroundTransparency = 1
    TooltipText.TextColor3 = Theme.Text
    TooltipText.Font = Enum.Font.Gotham
    TooltipText.TextSize = 11
    TooltipText.TextWrapped = true
    TooltipText.Parent = TooltipGui

    local function AddTooltip(element, text)
        if not text or text == "" then return end
        local isHovering = false
        element.MouseEnter:Connect(function()
            isHovering = true
            task.wait(0.4)
            if isHovering then
                TooltipText.Text = text
                TooltipGui.Size = UDim2.new(0, TooltipText.TextBounds.X + 20, 0, TooltipText.TextBounds.Y + 15)
                TooltipGui.Visible = true
                TooltipGui.Position = UDim2.new(0, UserInputService:GetMouseLocation().X + 15, 0, UserInputService:GetMouseLocation().Y - 35)
            end
        end)
        element.MouseLeave:Connect(function()
            isHovering = false; TooltipGui.Visible = false
        end)
    end

    -- SISTEM WATERMARK (OPSIONAL)
    if config.Watermark then
        local WMFrame = Instance.new("Frame")
        WMFrame.Size = UDim2.new(0, 250, 0, 25)
        WMFrame.Position = UDim2.new(0, 20, 0, 20)
        WMFrame.BackgroundColor3 = Theme.SidebarBg
        WMFrame.BackgroundTransparency = Theme.Transparency
        WMFrame.Parent = ScreenGui
        Instance.new("UICorner", WMFrame).CornerRadius = Theme.Radius
        local WMStroke = Instance.new("UIStroke")
        WMStroke.Color = Theme.Accent
        WMStroke.Thickness = 1
        WMStroke.Parent = WMFrame
        local WMLabel = Instance.new("TextLabel")
        WMLabel.Size = UDim2.new(1, -10, 1, 0)
        WMLabel.Position = UDim2.new(0, 10, 0, 0)
        WMLabel.BackgroundTransparency = 1
        WMLabel.TextColor3 = Theme.Accent
        WMLabel.Font = Enum.Font.GothamBold
        WMLabel.TextSize = 12
        WMLabel.TextXAlignment = Enum.TextXAlignment.Left
        WMLabel.Parent = WMFrame
        MakeDraggable(WMFrame, WMFrame)
        
        RunService.RenderStepped:Connect(function()
            local fps = math.floor(1 / RunService.RenderStepped:Wait())
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            WMLabel.Text = titleText .. " | FPS: " .. fps .. " | Ping: " .. math.floor(ping) .. "ms"
        end)
    end

    -- FLOATING LOGO
    local FloatingBtn = Instance.new("TextButton")
    FloatingBtn.Size = UDim2.new(0, 50, 0, 50)
    FloatingBtn.Position = UDim2.new(0, 20, 0.5, -25)
    FloatingBtn.BackgroundColor3 = Theme.SidebarBg
    FloatingBtn.Text = logoIcon
    FloatingBtn.TextColor3 = Theme.Accent
    FloatingBtn.Font = Enum.Font.GothamBlack
    FloatingBtn.TextSize = 24
    FloatingBtn.Visible = false
    FloatingBtn.Parent = ScreenGui
    
    Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
    local FloatStroke = Instance.new("UIStroke")
    FloatStroke.Color = Theme.Accent
    FloatStroke.Thickness = 2
    FloatStroke.Parent = FloatingBtn
    MakeDraggable(FloatingBtn, FloatingBtn)

    -- MAIN WINDOW (Update Glassmorphism)
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 480, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
    MainFrame.BackgroundColor3 = Theme.MainBg
    MainFrame.BackgroundTransparency = Theme.Transparency
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = Theme.Radius
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Accent
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame

    -- SIDEBAR KIRI
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 45, 1, 0)
    Sidebar.BackgroundColor3 = Theme.SidebarBg
    Sidebar.BackgroundTransparency = Theme.Transparency
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    Instance.new("UICorner", Sidebar).CornerRadius = Theme.Radius
    local SidebarFix = Instance.new("Frame")
    SidebarFix.Size = UDim2.new(0, 10, 1, 0)
    SidebarFix.Position = UDim2.new(1, -10, 0, 0)
    SidebarFix.BackgroundColor3 = Theme.SidebarBg
    SidebarFix.BorderSizePixel = 0
    SidebarFix.Parent = Sidebar

    local LogoLabel = Instance.new("TextLabel")
    LogoLabel.Size = UDim2.new(1, 0, 0, 45)
    LogoLabel.BackgroundTransparency = 1
    LogoLabel.Text = logoIcon
    LogoLabel.TextColor3 = Theme.Accent
    LogoLabel.Font = Enum.Font.GothamBlack
    LogoLabel.TextSize = 20
    LogoLabel.Parent = Sidebar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, 0, 1, -45)
    TabContainer.Position = UDim2.new(0, 0, 0, 45)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = Sidebar
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.Padding = UDim.new(0, 8)
    TabListLayout.Parent = TabContainer

    -- TOPBAR
    local Topbar = Instance.new("Frame")
    Topbar.Size = UDim2.new(1, -45, 0, 40)
    Topbar.Position = UDim2.new(0, 45, 0, 0)
    Topbar.BackgroundTransparency = 1
    Topbar.Parent = MainFrame
    MakeDraggable(Topbar, MainFrame)

    -- SEARCH BOX AKTIF
    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(1, -50, 0, 26) 
    SearchBox.Position = UDim2.new(0, 10, 0.5, -13)
    SearchBox.BackgroundColor3 = Theme.SidebarBg
    SearchBox.Text = ""
    SearchBox.PlaceholderText = "🔍 Search / " .. titleText
    SearchBox.TextColor3 = Theme.Text
    SearchBox.PlaceholderColor3 = Theme.TextDim
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 12
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.Parent = Topbar
    Instance.new("UICorner", SearchBox).CornerRadius = Theme.Radius
    local SearchPadding = Instance.new("UIPadding")
    SearchPadding.PaddingLeft = UDim.new(0, 10)
    SearchPadding.Parent = SearchBox

    -- TOMBOL MINIMIZE
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 40)
    MinBtn.Position = UDim2.new(1, -30, 0, 0)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "✖"
    MinBtn.TextColor3 = Theme.TextDim
    MinBtn.TextSize = 14
    MinBtn.Parent = Topbar
    
    MinBtn.MouseEnter:Connect(function() MinBtn.TextColor3 = Theme.Accent end)
    MinBtn.MouseLeave:Connect(function() MinBtn.TextColor3 = Theme.TextDim end)

    MinBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        FloatingBtn.Visible = true
    end)
    FloatingBtn.MouseButton1Click:Connect(function()
        FloatingBtn.Visible = false
        MainFrame.Visible = true
    end)

    -- FOOTER
    local Footer = Instance.new("TextLabel")
    Footer.Size = UDim2.new(1, -45, 0, 20)
    Footer.Position = UDim2.new(0, 45, 1, -20)
    Footer.BackgroundColor3 = Theme.SidebarBg
    Footer.BorderSizePixel = 0
    Footer.Text = footerText
    Footer.TextColor3 = Theme.TextDim
    Footer.Font = Enum.Font.Gotham
    Footer.TextSize = 11
    Footer.Parent = MainFrame

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -45, 1, -60)
    ContentContainer.Position = UDim2.new(0, 45, 0, 40)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ClipsDescendants = true
    ContentContainer.Parent = MainFrame

    -- ==========================================
    -- LOGIKA WINDOW & SEARCH
    -- ==========================================
    local Window = { Tabs = {}, FirstTab = true, SearchableItems = {} }

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = string.lower(SearchBox.Text)
        for _, item in ipairs(Window.SearchableItems) do
            if searchText == "" or string.find(string.lower(item.Name), searchText) then
                item.Frame.Visible = true
            else
                item.Frame.Visible = false
            end
        end
    end)

    function Window:MakeTab(iconId)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(0, 30, 0, 30)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = iconId
        TabBtn.TextColor3 = self.FirstTab and Theme.Accent or Theme.TextDim
        TabBtn.TextSize = 16
        TabBtn.Parent = TabContainer

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Visible = self.FirstTab
        Page.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        PageLayout.Parent = Page
        Instance.new("UIPadding", Page).PaddingTop = UDim.new(0, 5)
        Instance.new("UIPadding", Page).PaddingBottom = UDim.new(0, 5)

        table.insert(self.Tabs, {Btn = TabBtn, Page = Page})

        TabBtn.MouseButton1Click:Connect(function()
            for _, tabInfo in ipairs(self.Tabs) do
                tabInfo.Page.Visible = (tabInfo.Page == Page)
                TweenService:Create(tabInfo.Btn, TweenInfo.new(0.2), {TextColor3 = (tabInfo.Btn == TabBtn) and Theme.Accent or Theme.TextDim}):Play()
            end
        end)

        self.FirstTab = false
        local TabLogic = {}

        -- STRUKTUR SECTION (TETAP MENGGUNAKAN FIX OVERLAP)
        function TabLogic:AddSection(titleText)
            local SecFrame = Instance.new("Frame")
            SecFrame.Size = UDim2.new(1, -20, 0, 40) 
            SecFrame.BackgroundColor3 = Theme.MainBg
            SecFrame.BackgroundTransparency = Theme.Transparency
            SecFrame.Parent = Page
            
            local SecStroke = Instance.new("UIStroke")
            SecStroke.Color = Theme.ElementBg
            SecStroke.Parent = SecFrame
            Instance.new("UICorner", SecFrame).CornerRadius = Theme.Radius

            local SecTitle = Instance.new("TextLabel")
            SecTitle.Size = UDim2.new(1, -10, 0, 30)
            SecTitle.Position = UDim2.new(0, 10, 0, 0)
            SecTitle.BackgroundTransparency = 1
            SecTitle.Text = "◎ " .. titleText
            SecTitle.TextColor3 = Theme.Accent
            SecTitle.Font = Enum.Font.GothamSemibold
            SecTitle.TextSize = 13
            SecTitle.TextXAlignment = Enum.TextXAlignment.Left
            SecTitle.Parent = SecFrame

            local InnerContainer = Instance.new("Frame")
            InnerContainer.Size = UDim2.new(1, 0, 1, -30)
            InnerContainer.Position = UDim2.new(0, 0, 0, 30)
            InnerContainer.BackgroundTransparency = 1
            InnerContainer.Parent = SecFrame

            local SecLayout = Instance.new("UIListLayout")
            SecLayout.Padding = UDim.new(0, 6)
            SecLayout.Parent = InnerContainer

            local SecPadding = Instance.new("UIPadding")
            SecPadding.PaddingTop = UDim.new(0, 5)
            SecPadding.PaddingBottom = UDim.new(0, 10)
            SecPadding.PaddingLeft = UDim.new(0, 10)
            SecPadding.PaddingRight = UDim.new(0, 10)
            SecPadding.Parent = InnerContainer

            SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SecFrame.Size = UDim2.new(1, -20, 0, SecLayout.AbsoluteContentSize.Y + 45)
            end)

            local Section = {}

            -- ================= ELEMEN ULTIMATE =================

            -- 1. WARNING BOX
            function Section:AddWarning(text)
                local WarnFrame = Instance.new("Frame")
                WarnFrame.Size = UDim2.new(1, 0, 0, 0)
                WarnFrame.BackgroundColor3 = Theme.Warning
                WarnFrame.BackgroundTransparency = 0.8
                WarnFrame.Parent = InnerContainer
                Instance.new("UICorner", WarnFrame).CornerRadius = Theme.Radius
                local WarnStroke = Instance.new("UIStroke")
                WarnStroke.Color = Theme.Warning
                WarnStroke.Thickness = 1
                WarnStroke.Parent = WarnFrame
                
                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, -20, 1, -10)
                Lbl.Position = UDim2.new(0, 10, 0, 5)
                Lbl.BackgroundTransparency = 1
                Lbl.Text = "⚠️ " .. text
                Lbl.TextColor3 = Theme.Warning
                Lbl.Font = Enum.Font.GothamBold
                Lbl.TextSize = 12
                Lbl.TextWrapped = true
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = WarnFrame
                
                WarnFrame.Size = UDim2.new(1, 0, 0, Lbl.TextBounds.Y + 20)
                table.insert(Window.SearchableItems, {Name = text, Frame = WarnFrame})
            end

            -- 2. BUTTON (With Hover & Ripple)
            function Section:AddButton(info, callback)
                local text = type(info) == "table" and info.Name or info
                local tooltip = type(info) == "table" and info.Tooltip or ""

                local BtnFrame = Instance.new("TextButton")
                BtnFrame.Size = UDim2.new(1, 0, 0, 30)
                BtnFrame.BackgroundColor3 = Theme.ElementBg
                BtnFrame.Text = "  " .. text
                BtnFrame.TextColor3 = Theme.Text
                BtnFrame.Font = Enum.Font.Gotham
                BtnFrame.TextSize = 12
                BtnFrame.TextXAlignment = Enum.TextXAlignment.Left
                BtnFrame.ClipsDescendants = true
                BtnFrame.Parent = InnerContainer
                Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 4)
                
                AddTooltip(BtnFrame, tooltip)

                BtnFrame.MouseEnter:Connect(function() TweenService:Create(BtnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementHover}):Play() end)
                BtnFrame.MouseLeave:Connect(function() TweenService:Create(BtnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBg}):Play() end)
                BtnFrame.MouseButton1Click:Connect(function() 
                    CreateRipple(BtnFrame, UserInputService:GetMouseLocation())
                    if callback then callback() end 
                end)
                table.insert(Window.SearchableItems, {Name = text, Frame = BtnFrame})
            end

            -- 3. TOGGLE (Dynamic & Config Ready)
            function Section:AddToggle(info, defaultOrCb, cbArg)
                local text, default, callback, flag, tooltip
                if type(info) == "table" then
                    text = info.Name; default = info.Default or false; callback = defaultOrCb; flag = info.Flag; tooltip = info.Tooltip
                else
                    text = info; default = defaultOrCb or false; callback = cbArg
                end
                
                local state = default
                if flag and Library.Flags[flag] ~= nil then state = Library.Flags[flag] end
                Library.Flags[flag] = state

                local Tgl = Instance.new("Frame")
                Tgl.Size = UDim2.new(1, 0, 0, 26)
                Tgl.BackgroundTransparency = 1
                Tgl.Parent = InnerContainer
                AddTooltip(Tgl, tooltip)

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, -40, 1, 0)
                Lbl.BackgroundTransparency = 1
                Lbl.Text = text
                Lbl.TextColor3 = Theme.TextDim
                Lbl.Font = Enum.Font.Gotham
                Lbl.TextSize = 12
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = Tgl

                local Bg = Instance.new("Frame")
                Bg.Size = UDim2.new(0, 32, 0, 16)
                Bg.Position = UDim2.new(1, -32, 0.5, -8)
                Bg.BackgroundColor3 = state and Theme.Accent or Theme.ElementBg
                Bg.Parent = Tgl
                Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)

                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.new(0, 12, 0, 12)
                Dot.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
                Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Dot.Parent = Bg
                Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(1, 0, 1, 0)
                Btn.BackgroundTransparency = 1
                Btn.Text = ""
                Btn.Parent = Tgl

                local function SetState(newState)
                    state = newState
                    if flag then Library.Flags[flag] = state end
                    TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.Accent or Theme.ElementBg}):Play()
                    TweenService:Create(Dot, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
                    if callback then callback(state) end
                end

                Btn.MouseButton1Click:Connect(function() SetState(not state) end)
                table.insert(Window.SearchableItems, {Name = text, Frame = Tgl})

                return { Set = function(self, val) SetState(val) end, Get = function() return state end }
            end

            -- 4. SLIDER (Dynamic & Config Ready)
            function Section:AddSlider(info, minVal, maxVal, defVal, cbArg)
                local text, min, max, default, callback, flag, tooltip
                if type(info) == "table" then
                    text = info.Name; min = info.Min or 0; max = info.Max or 100; default = info.Default or min; callback = minVal; flag = info.Flag; tooltip = info.Tooltip
                else
                    text = info; min = minVal; max = maxVal; default = defVal; callback = cbArg
                end

                local value = default
                if flag and Library.Flags[flag] ~= nil then value = Library.Flags[flag] end
                Library.Flags[flag] = value

                local SldFrame = Instance.new("Frame")
                SldFrame.Size = UDim2.new(1, 0, 0, 40)
                SldFrame.BackgroundTransparency = 1
                SldFrame.Parent = InnerContainer
                AddTooltip(SldFrame, tooltip)

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, -30, 0, 16)
                Lbl.BackgroundTransparency = 1
                Lbl.Text = text
                Lbl.TextColor3 = Theme.TextDim
                Lbl.Font = Enum.Font.Gotham
                Lbl.TextSize = 12
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = SldFrame

                local ValLbl = Instance.new("TextLabel")
                ValLbl.Size = UDim2.new(0, 30, 0, 16)
                ValLbl.Position = UDim2.new(1, -30, 0, 0)
                ValLbl.BackgroundTransparency = 1
                ValLbl.Text = tostring(value)
                ValLbl.TextColor3 = Theme.Accent
                ValLbl.Font = Enum.Font.GothamBold
                ValLbl.TextSize = 12
                ValLbl.TextXAlignment = Enum.TextXAlignment.Right
                ValLbl.Parent = SldFrame

                local BgBar = Instance.new("Frame")
                BgBar.Size = UDim2.new(1, 0, 0, 6)
                BgBar.Position = UDim2.new(0, 0, 0, 24)
                BgBar.BackgroundColor3 = Theme.ElementBg
                BgBar.Parent = SldFrame
                Instance.new("UICorner", BgBar).CornerRadius = UDim.new(1, 0)

                local FillBar = Instance.new("Frame")
                local initialScale = math.clamp((value - min) / (max - min), 0, 1)
                FillBar.Size = UDim2.new(initialScale, 0, 1, 0)
                FillBar.BackgroundColor3 = Theme.Accent
                FillBar.Parent = BgBar
                Instance.new("UICorner", FillBar).CornerRadius = UDim.new(1, 0)

                local SldBtn = Instance.new("TextButton")
                SldBtn.Size = UDim2.new(1, 0, 1, 10)
                SldBtn.Position = UDim2.new(0, 0, 0, -5)
                SldBtn.BackgroundTransparency = 1
                SldBtn.Text = ""
                SldBtn.Parent = BgBar

                local function SetValue(v)
                    value = math.clamp(v, min, max)
                    if flag then Library.Flags[flag] = value end
                    TweenService:Create(FillBar, TweenInfo.new(0.1), {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}):Play()
                    ValLbl.Text = tostring(value)
                    if callback then callback(value) end
                end

                local dragging = false
                local function updateSlider(input)
                    local pos = math.clamp((input.Position.X - BgBar.AbsolutePosition.X) / BgBar.AbsoluteSize.X, 0, 1)
                    SetValue(math.floor(min + ((max - min) * pos)))
                end

                SldBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true; updateSlider(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input) end
                end)
                table.insert(Window.SearchableItems, {Name = text, Frame = SldFrame})

                return { Set = function(self, val) SetValue(val) end, Get = function() return value end }
            end

            -- 5. KEYBIND
            function Section:AddBind(info, defaultKey, cbArg)
                local text, keyName, callback, tooltip
                if type(info) == "table" then
                    text = info.Name; keyName = info.Default.Name; callback = defaultKey; tooltip = info.Tooltip
                else
                    text = info; keyName = defaultKey.Name; callback = cbArg
                end

                local BindFrame = Instance.new("Frame")
                BindFrame.Size = UDim2.new(1, 0, 0, 26)
                BindFrame.BackgroundTransparency = 1
                BindFrame.Parent = InnerContainer
                AddTooltip(BindFrame, tooltip)

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, -60, 1, 0)
                Lbl.BackgroundTransparency = 1
                Lbl.Text = text
                Lbl.TextColor3 = Theme.TextDim
                Lbl.Font = Enum.Font.Gotham
                Lbl.TextSize = 12
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = BindFrame

                local BindBtn = Instance.new("TextButton")
                BindBtn.Size = UDim2.new(0, 50, 0, 20)
                BindBtn.Position = UDim2.new(1, -50, 0.5, -10)
                BindBtn.BackgroundColor3 = Theme.ElementBg
                BindBtn.Text = keyName
                BindBtn.TextColor3 = Theme.Accent
                BindBtn.Font = Enum.Font.GothamBold
                BindBtn.TextSize = 11
                BindBtn.Parent = BindFrame
                Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 4)

                local isListening = false
                BindBtn.MouseButton1Click:Connect(function()
                    isListening = true
                    BindBtn.Text = "..."
                end)

                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed then
                        if isListening and input.UserInputType == Enum.UserInputType.Keyboard then
                            isListening = false
                            keyName = input.KeyCode.Name
                            BindBtn.Text = keyName
                        elseif input.KeyCode.Name == keyName and not isListening then
                            if callback then callback() end
                        end
                    end
                end)
                table.insert(Window.SearchableItems, {Name = text, Frame = BindFrame})
            end

            -- 6. DROPDOWN (Dynamic & Config Ready)
            function Section:AddDropdown(info, listOpt, cbArg)
                local text, list, default, callback, flag, tooltip
                if type(info) == "table" then
                    text = info.Name; list = info.Options; default = info.Default; callback = listOpt; flag = info.Flag; tooltip = info.Tooltip
                else
                    text = info; list = listOpt; default = listOpt[1]; callback = cbArg
                end

                local selected = default
                if flag and Library.Flags[flag] ~= nil then selected = Library.Flags[flag] end
                Library.Flags[flag] = selected

                local DropFrame = Instance.new("Frame")
                DropFrame.Size = UDim2.new(1, 0, 0, 45)
                DropFrame.BackgroundTransparency = 1
                DropFrame.ClipsDescendants = true
                DropFrame.Parent = InnerContainer
                AddTooltip(DropFrame, tooltip)

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, 0, 0, 16)
                Lbl.BackgroundTransparency = 1
                Lbl.Text = text
                Lbl.TextColor3 = Theme.TextDim
                Lbl.Font = Enum.Font.Gotham
                Lbl.TextSize = 12
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = DropFrame

                local MainBtn = Instance.new("TextButton")
                MainBtn.Size = UDim2.new(1, 0, 0, 26)
                MainBtn.Position = UDim2.new(0, 0, 0, 18)
                MainBtn.BackgroundColor3 = Theme.ElementBg
                MainBtn.Text = "  " .. (selected or "Select...")
                MainBtn.TextColor3 = Theme.Text
                MainBtn.Font = Enum.Font.Gotham
                MainBtn.TextSize = 12
                MainBtn.TextXAlignment = Enum.TextXAlignment.Left
                MainBtn.Parent = DropFrame
                Instance.new("UICorner", MainBtn).CornerRadius = UDim.new(0, 4)

                local Layout = Instance.new("UIListLayout")
                Layout.Padding = UDim.new(0, 2)
                Layout.Parent = DropFrame

                local isOpen = false
                MainBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, isOpen and (45 + (#list * 24)) or 45)}):Play()
                end)

                local function SetOption(val)
                    selected = val
                    if flag then Library.Flags[flag] = selected end
                    MainBtn.Text = "  " .. tostring(val)
                    isOpen = false
                    TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play()
                    if callback then callback(val) end
                end

                for _, item in ipairs(list) do
                    local ItemBtn = Instance.new("TextButton")
                    ItemBtn.Size = UDim2.new(1, 0, 0, 22)
                    ItemBtn.BackgroundColor3 = Theme.SidebarBg
                    ItemBtn.Text = "  " .. tostring(item)
                    ItemBtn.TextColor3 = Theme.TextDim
                    ItemBtn.Font = Enum.Font.Gotham
                    ItemBtn.TextSize = 11
                    ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
                    ItemBtn.Parent = DropFrame
                    Instance.new("UICorner", ItemBtn).CornerRadius = UDim.new(0, 4)

                    ItemBtn.MouseButton1Click:Connect(function() SetOption(item) end)
                end
                table.insert(Window.SearchableItems, {Name = text, Frame = DropFrame})

                return { Set = function(self, val) SetOption(val) end, Get = function() return selected end }
            end

            -- 7. TEXT INPUT
            function Section:AddInput(text, placeholder, callback)
                local InpFrame = Instance.new("Frame")
                InpFrame.Size = UDim2.new(1, 0, 0, 45)
                InpFrame.BackgroundTransparency = 1
                InpFrame.Parent = InnerContainer

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, 0, 0, 16)
                Lbl.BackgroundTransparency = 1
                Lbl.Text = text
                Lbl.TextColor3 = Theme.TextDim
                Lbl.Font = Enum.Font.Gotham
                Lbl.TextSize = 12
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = InpFrame

                local Box = Instance.new("TextBox")
                Box.Size = UDim2.new(1, 0, 0, 26)
                Box.Position = UDim2.new(0, 0, 0, 18)
                Box.BackgroundColor3 = Theme.ElementBg
                Box.BorderSizePixel = 0
                Box.Text = ""
                Box.PlaceholderText = " " .. placeholder
                Box.TextColor3 = Theme.Text
                Box.Font = Enum.Font.Gotham
                Box.TextSize = 12
                Box.TextXAlignment = Enum.TextXAlignment.Left
                Box.Parent = InpFrame
                Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)

                Box.FocusLost:Connect(function(ep)
                    if ep and callback then callback(Box.Text) end
                end)
                table.insert(Window.SearchableItems, {Name = text, Frame = InpFrame})
            end

            -- 8. CONSOLE / TEXT LOG
            function Section:AddConsole(text)
                local CFrame = Instance.new("Frame")
                CFrame.Size = UDim2.new(1, 0, 0, 120)
                CFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
                CFrame.Parent = InnerContainer
                Instance.new("UICorner", CFrame).CornerRadius = Theme.Radius
                local CStroke = Instance.new("UIStroke")
                CStroke.Color = Theme.ElementBg
                CStroke.Parent = CFrame
                
                local CScroll = Instance.new("ScrollingFrame")
                CScroll.Size = UDim2.new(1, -10, 1, -10)
                CScroll.Position = UDim2.new(0, 5, 0, 5)
                CScroll.BackgroundTransparency = 1
                CScroll.ScrollBarThickness = 2
                CScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                CScroll.CanvasSize = UDim2.new(0,0,0,0)
                CScroll.Parent = CFrame
                local CLayout = Instance.new("UIListLayout")
                CLayout.Padding = UDim.new(0, 2)
                CLayout.Parent = CScroll
                
                table.insert(Window.SearchableItems, {Name = text, Frame = CFrame})
                
                return {
                    Log = function(self, msg)
                        local msgLbl = Instance.new("TextLabel")
                        msgLbl.Size = UDim2.new(1, 0, 0, 14)
                        msgLbl.BackgroundTransparency = 1
                        msgLbl.Text = "> " .. msg
                        msgLbl.TextColor3 = Theme.TextDim
                        msgLbl.Font = Enum.Font.Code
                        msgLbl.TextSize = 11
                        msgLbl.TextXAlignment = Enum.TextXAlignment.Left
                        msgLbl.Parent = CScroll
                        CScroll.CanvasPosition = Vector2.new(0, CLayout.AbsoluteContentSize.Y)
                    end,
                    Clear = function(self) 
                        for _, v in pairs(CScroll:GetChildren()) do 
                            if v:IsA("TextLabel") then v:Destroy() end 
                        end 
                    end
                }
            end

            return Section
        end

        return TabLogic
    end

    return Window
end

-- ==========================================
-- SISTEM SAVE & LOAD CONFIGURATION
-- ==========================================
function Library:SaveConfig()
    if not writefile then return end
    local success, encoded = pcall(function() return HttpService:JSONEncode(self.Flags) end)
    if success then writefile(self.ConfigName .. ".json", encoded) end
end

function Library:LoadConfig()
    if not readfile or not isfile or not isfile(self.ConfigName .. ".json") then return end
    local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(self.ConfigName .. ".json")) end)
    if success and type(decoded) == "table" then
        for k, v in pairs(decoded) do self.Flags[k] = v end
    end
end

return Library
