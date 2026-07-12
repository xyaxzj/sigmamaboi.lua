--[[
    Pink Glow Compact Hub UI
    Reference: Screenshot_2712-152719.jpg
    Style: Dark/Pink, Sidebar Tabs, Grouped Sections
]]

local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Fungsi aman mendapatkan Parent UI
local function getSafeParent()
    if gethui then return gethui() end
    local success, core = pcall(function() return game:GetService("CoreGui") end)
    if success and core then return core end
    return game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Sistem Drag Universal
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

-- Tema Persis Seperti Gambar
local Theme = {
    MainBg = Color3.fromRGB(22, 22, 22),       -- Hitam pekat
    SidebarBg = Color3.fromRGB(15, 15, 15),    -- Hitam lebih gelap untuk sidebar
    ElementBg = Color3.fromRGB(30, 30, 30),    -- Abu-abu gelap untuk input/dropdown
    Accent = Color3.fromRGB(255, 105, 145),    -- Pink Neon
    Text = Color3.fromRGB(240, 240, 240),      -- Putih
    TextDim = Color3.fromRGB(150, 150, 150),   -- Abu-abu teks
    Radius = UDim.new(0, 6)
}

function Library:CreateWindow(config)
    local titleText = config.Name or "Compact Hub"
    local footerText = config.Footer or "discord.gg/yourlink | v1.0"
    local logoIcon = config.LogoText or "C" -- Teks untuk logo (seperti 'C' di gambar)

    local targetParent = getSafeParent()
    if targetParent:FindFirstChild("PinkCompactUI") then
        targetParent.PinkCompactUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PinkCompactUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = targetParent

    -- ==========================================
    -- 1. FLOATING LOGO (Seperti di gambar kiri luar)
    -- ==========================================
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

    -- ==========================================
    -- 2. MAIN WINDOW (Ukuran Compact 480x320)
    -- ==========================================
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 480, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
    MainFrame.BackgroundColor3 = Theme.MainBg
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = Theme.Radius
    
    -- Outline Pink Glow
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
    -- Fix corner kanan sidebar
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

    -- TOPBAR (Search Bar Fake & Drag icon)
    local Topbar = Instance.new("Frame")
    Topbar.Size = UDim2.new(1, -45, 0, 40)
    Topbar.Position = UDim2.new(0, 45, 0, 0)
    Topbar.BackgroundTransparency = 1
    Topbar.Parent = MainFrame
    MakeDraggable(Topbar, MainFrame) -- Buat Topbar jadi tempat drag

    local SearchBox = Instance.new("TextLabel")
    SearchBox.Size = UDim2.new(1, -40, 0, 26)
    SearchBox.Position = UDim2.new(0, 10, 0.5, -13)
    SearchBox.BackgroundColor3 = Theme.SidebarBg
    SearchBox.Text = "   🔍 Search..."
    SearchBox.TextColor3 = Theme.TextDim
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 12
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.Parent = Topbar
    Instance.new("UICorner", SearchBox).CornerRadius = Theme.Radius

    -- TOMBOL MINIMIZE (Di kanan atas Topbar, menggantikan icon drag di gambar)
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

    -- AREA KONTEN TABS
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -45, 1, -60)
    ContentContainer.Position = UDim2.new(0, 45, 0, 40)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ClipsDescendants = true
    ContentContainer.Parent = MainFrame

    -- ==========================================
    -- LOGIKA TAB & ELEMEN
    -- ==========================================
    local Window = { Tabs = {}, FirstTab = true }

    function Window:MakeTab(iconId)
        -- Tombol di Sidebar
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(0, 30, 0, 30)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = iconId -- Pakai emoji/teks icon sementara
        TabBtn.TextColor3 = self.FirstTab and Theme.Accent or Theme.TextDim
        TabBtn.TextSize = 16
        TabBtn.Parent = TabContainer

        -- Halaman Scroll
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

        -- BIKIN SECTION (Seperti kotak "Catch", "Grow")
        function TabLogic:AddSection(titleText)
            local SecFrame = Instance.new("Frame")
            SecFrame.Size = UDim2.new(1, -20, 0, 30) -- Default tinggi
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

            -- Auto resize section frame based on contents
            SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SecFrame.Size = UDim2.new(1, -20, 0, SecLayout.AbsoluteContentSize.Y + 10)
            end)
            
            -- Padding dalam section agar konten agak ke dalam
            local SecPadding = Instance.new("UIPadding")
            SecPadding.PaddingTop = UDim.new(0, 30) -- Sisakan ruang buat header
            SecPadding.PaddingLeft = UDim.new(0, 10)
            SecPadding.PaddingRight = UDim.new(0, 10)
            SecPadding.PaddingBottom = UDim.new(0, 10)
            SecPadding.Parent = SecFrame

            local Section = {}

            -- TOGGLE DI DALAM SECTION (Persis di gambar)
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

            -- INPUT / TEXTBOX DI DALAM SECTION (Seperti 'Max Catch Level')
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

            -- DROPDOWN DI DALAM SECTION
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

            return Section
        end

        return TabLogic
    end

    return Window
end

return Library
