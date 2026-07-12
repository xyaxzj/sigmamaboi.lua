--[[
    Blue Compact Hub UI Library
    Style: Dark/Blue, Sidebar Tabs, Grouped Sections
]]

local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

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
            objectToMove.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

-- TEMA WARNA BIRU NEON (Blue Style)
local Theme = {
    MainBg = Color3.fromRGB(20, 20, 22),       -- Hitam pekat kebiruan
    SidebarBg = Color3.fromRGB(15, 15, 17),    -- Lebih gelap untuk sidebar
    ElementBg = Color3.fromRGB(30, 30, 35),    -- Abu-abu gelap
    Accent = Color3.fromRGB(0, 170, 255),      -- BIRU NEON
    Text = Color3.fromRGB(240, 240, 240),      -- Putih Teks
    TextDim = Color3.fromRGB(150, 150, 150),   -- Abu-abu Teks
    Radius = UDim.new(0, 6)
}

-- Wadah untuk Notifikasi
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

-- FUNGSI NOTIFIKASI
function Library:Notify(title, content, duration)
    local dur = duration or 3
    
    local NFrame = Instance.new("Frame")
    NFrame.Size = UDim2.new(1, 0, 0, 60)
    NFrame.BackgroundColor3 = Theme.SidebarBg
    NFrame.Position = UDim2.new(1, 300, 0, 0) -- Mulai dari luar layar (kanan)
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

    -- Animasi Masuk
    TweenService:Create(NFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    
    -- Animasi Keluar
    task.delay(dur, function()
        local tweenOut = TweenService:Create(NFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1, 300, 0, 0)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function() NFrame:Destroy() end)
    end)
end

-- FUNGSI MEMBUAT UI UTAMA
function Library:CreateWindow(config)
    local titleText = config.Name or "Compact Hub"
    local footerText = config.Footer or "discord.gg/yourlink | v1.0"
    local logoIcon = config.LogoText or "S" -- Default Logo "S"

    local targetParent = getSafeParent()
    if targetParent:FindFirstChild("BlueCompactUI") then
        targetParent.BlueCompactUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BlueCompactUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = targetParent

    -- FLOATING LOGO (Muncul saat diminimize)
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

    -- MAIN WINDOW (Ukuran 480x320)
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 480, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
    MainFrame.BackgroundColor3 = Theme.MainBg
    MainFrame.BorderSizePixel = 0
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

    local SearchBox = Instance.new("TextLabel")
    SearchBox.Size = UDim2.new(1, -40, 0, 26)
    SearchBox.Position = UDim2.new(0, 10, 0.5, -13)
    SearchBox.BackgroundColor3 = Theme.SidebarBg
    SearchBox.Text = "   🔍 Search / " .. titleText
    SearchBox.TextColor3 = Theme.TextDim
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 12
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.Parent = Topbar
    Instance.new("UICorner", SearchBox).CornerRadius = Theme.Radius

    -- TOMBOL MINIMIZE
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 40)
    MinBtn.Position = UDim2.new(1, -30, 0, 0)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "✖"
    MinBtn.TextColor3 = Theme.Accent
    MinBtn.TextSize = 14
    MinBtn.Parent = Topbar

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

    -- KONTEN TABS
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -45, 1, -60)
    ContentContainer.Position = UDim2.new(0, 45, 0, 40)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ClipsDescendants = true
    ContentContainer.Parent = MainFrame

    -- ==========================================
    -- LOGIKA TAB & SECTION
    -- ==========================================
    local Window = { Tabs = {}, FirstTab = true }

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

        table.insert(self.Tabs, {Btn = TabBtn, Page = Page})

        TabBtn.MouseButton1Click:Connect(function()
            for _, tabInfo in ipairs(self.Tabs) do
                tabInfo.Page.Visible = (tabInfo.Page == Page)
                tabInfo.Btn.TextColor3 = (tabInfo.Btn == TabBtn) and Theme.Accent or Theme.TextDim
            end
        end)

        self.FirstTab = false
        local TabLogic = {}

        function TabLogic:AddSection(titleText)
            local SecFrame = Instance.new("Frame")
            SecFrame.Size = UDim2.new(1, -20, 0, 30)
            SecFrame.BackgroundColor3 = Theme.MainBg
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

            local SecLayout = Instance.new("UIListLayout")
            SecLayout.Padding = UDim.new(0, 6)
            SecLayout.Parent = SecFrame

            SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SecFrame.Size = UDim2.new(1, -20, 0, SecLayout.AbsoluteContentSize.Y + 10)
            end)
            
            local SecPadding = Instance.new("UIPadding")
            SecPadding.PaddingTop = UDim.new(0, 30)
            SecPadding.PaddingLeft = UDim.new(0, 10)
            SecPadding.PaddingRight = UDim.new(0, 10)
            SecPadding.PaddingBottom = UDim.new(0, 10)
            SecPadding.Parent = SecFrame

            local Section = {}

            -- ================= ELEMEN DI DALAM SECTION =================

            -- 1. TOMBOL (BUTTON)
            function Section:AddButton(text, callback)
                local BtnFrame = Instance.new("TextButton")
                BtnFrame.Size = UDim2.new(1, 0, 0, 26)
                BtnFrame.BackgroundColor3 = Theme.ElementBg
                BtnFrame.Text = "  " .. text
                BtnFrame.TextColor3 = Theme.Text
                BtnFrame.Font = Enum.Font.Gotham
                BtnFrame.TextSize = 12
                BtnFrame.TextXAlignment = Enum.TextXAlignment.Left
                BtnFrame.Parent = SecFrame
                Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 4)

                BtnFrame.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)
            end

            -- 2. TOGGLE
            function Section:AddToggle(text, default, callback)
                local state = default or false
                local Tgl = Instance.new("Frame")
                Tgl.Size = UDim2.new(1, 0, 0, 26)
                Tgl.BackgroundTransparency = 1
                Tgl.Parent = SecFrame

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

                Btn.MouseButton1Click:Connect(function()
                    state = not state
                    TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.Accent or Theme.ElementBg}):Play()
                    TweenService:Create(Dot, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
                    if callback then callback(state) end
                end)
            end

            -- 3. SLIDER
            function Section:AddSlider(text, min, max, default, callback)
                local SldFrame = Instance.new("Frame")
                SldFrame.Size = UDim2.new(1, 0, 0, 40)
                SldFrame.BackgroundTransparency = 1
                SldFrame.Parent = SecFrame

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
                ValLbl.Text = tostring(default)
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
                local initialScale = math.clamp((default - min) / (max - min), 0, 1)
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

                local dragging = false
                local function updateSlider(input)
                    local pos = math.clamp((input.Position.X - BgBar.AbsolutePosition.X) / BgBar.AbsoluteSize.X, 0, 1)
                    local value = math.floor(min + ((max - min) * pos))
                    FillBar.Size = UDim2.new(pos, 0, 1, 0)
                    ValLbl.Text = tostring(value)
                    if callback then callback(value) end
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
            end

            -- 4. KEYBIND (TOMBOL PINTASAN)
            function Section:AddBind(text, defaultKey, callback)
                local keyName = defaultKey.Name
                local BindFrame = Instance.new("Frame")
                BindFrame.Size = UDim2.new(1, 0, 0, 26)
                BindFrame.BackgroundTransparency = 1
                BindFrame.Parent = SecFrame

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
            end

            -- 5. DROPDOWN (PILIHAN)
            function Section:AddDropdown(text, list, callback)
                local DropFrame = Instance.new("Frame")
                DropFrame.Size = UDim2.new(1, 0, 0, 45)
                DropFrame.BackgroundTransparency = 1
                DropFrame.ClipsDescendants = true
                DropFrame.Parent = SecFrame

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
                MainBtn.Text = "  Select..."
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

                    ItemBtn.MouseButton1Click:Connect(function()
                        MainBtn.Text = "  " .. tostring(item)
                        isOpen = false
                        TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play()
                        if callback then callback(item) end
                    end)
                end
            end

            -- 6. TEXTBOX INPUT
            function Section:AddInput(text, placeholder, callback)
                local InpFrame = Instance.new("Frame")
                InpFrame.Size = UDim2.new(1, 0, 0, 45)
                InpFrame.BackgroundTransparency = 1
                InpFrame.Parent = SecFrame

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
            end

            return Section
        end

        return TabLogic
    end

    return Window
end

return Library
