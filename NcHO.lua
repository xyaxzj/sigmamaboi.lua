--[[
    Ultimate Hub UI Library
    Author: [Nama Anda]
    Repository: [Link Github Anda]
    Description: Lightweight, Draggable, Mobile-Friendly UI Library for Roblox.
]]

local ScriptUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Fungsi aman mencari tempat menaruh UI
local function getSafeParent()
    if gethui then return gethui() end
    local success, core = pcall(function() return game:GetService("CoreGui") end)
    if success and core then return core end
    return game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Sistem Drag Universal (Mouse & Touch)
local function MakeDraggable(dragPoint, objectToMove)
    local dragging = false
    local dragInput, mousePos, framePos

    dragPoint.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = objectToMove.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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
            objectToMove.Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X, 
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Tema Default
local Theme = {
    MainBg = Color3.fromRGB(15, 15, 20),
    TopBg = Color3.fromRGB(20, 20, 25),
    ElementBg = Color3.fromRGB(25, 25, 30),
    ElementHover = Color3.fromRGB(35, 35, 40),
    Accent = Color3.fromRGB(0, 170, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
}

function ScriptUI:CreateWindow(titleText)
    local targetParent = getSafeParent()

    if targetParent:FindFirstChild("UltimateHubUI") then
        targetParent.UltimateHubUI:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UltimateHubUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = targetParent

    -- ==========================================
    -- FLOATING LOGO (Minimize State)
    -- ==========================================
    local floatingBtn = Instance.new("TextButton")
    floatingBtn.Name = "FloatingLogo"
    floatingBtn.Size = UDim2.new(0, 45, 0, 45)
    floatingBtn.Position = UDim2.new(0, 50, 0, 50)
    floatingBtn.BackgroundColor3 = Theme.TopBg
    floatingBtn.Text = "🌀"
    floatingBtn.TextSize = 25
    floatingBtn.Visible = false
    floatingBtn.Parent = screenGui
    
    Instance.new("UICorner", floatingBtn).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", floatingBtn).Color = Theme.Accent

    MakeDraggable(floatingBtn, floatingBtn)

    -- ==========================================
    -- MAIN WINDOW
    -- ==========================================
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 320)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -160)
    mainFrame.BackgroundColor3 = Theme.MainBg
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Theme.ElementBg
    mainStroke.Thickness = 1
    mainStroke.Parent = mainFrame

    -- TOPBAR
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Theme.TopBg
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame

    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1, 0, 0, 10)
    topFix.Position = UDim2.new(0, 0, 1, -10)
    topFix.BackgroundColor3 = Theme.TopBg
    topFix.BorderSizePixel = 0
    topFix.Parent = topBar
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Theme.Accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 30, 0, 30)
    minBtn.Position = UDim2.new(1, -40, 0.5, -15)
    minBtn.BackgroundColor3 = Theme.ElementBg
    minBtn.Text = "—"
    minBtn.TextColor3 = Theme.Text
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.Parent = topBar
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

    -- CONTAINER TABS/CONTENT
    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, -20, 1, -55)
    container.Position = UDim2.new(0, 10, 0, 45)
    container.BackgroundTransparency = 1
    container.ScrollBarThickness = 2
    container.ScrollBarImageColor3 = Theme.Accent
    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    container.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = container

    MakeDraggable(topBar, mainFrame)

    -- TOGGLE LOGIC (Minimize/Maximize)
    minBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        floatingBtn.Visible = true
    end)

    floatingBtn.MouseButton1Click:Connect(function()
        floatingBtn.Visible = false
        mainFrame.Visible = true
    end)

    -- ==========================================
    -- COMPONENTS
    -- ==========================================
    local Window = {}

    -- 1. LABEL
    function Window:AddLabel(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -8, 0, 25)
        lbl.BackgroundTransparency = 1
        lbl.Text = " " .. text
        lbl.TextColor3 = Theme.TextDim
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = container
    end

    -- 2. BUTTON
    function Window:AddButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 35)
        btn.BackgroundColor3 = Theme.ElementBg
        btn.Text = "  " .. text
        btn.TextColor3 = Theme.Text
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        btn.Parent = container
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Theme.TopBg
        btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        btnStroke.Parent = btn

        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementHover}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBg}):Play() end)
        btn.MouseButton1Click:Connect(function()
            TweenService:Create(btnStroke, TweenInfo.new(0.1), {Color = Theme.Accent}):Play()
            task.wait(0.1)
            TweenService:Create(btnStroke, TweenInfo.new(0.3), {Color = Theme.TopBg}):Play()
            if callback then callback() end
        end)
    end

    -- 3. TOGGLE
    function Window:AddToggle(text, defaultState, callback)
        local state = defaultState or false
        local tglFrame = Instance.new("Frame")
        tglFrame.Size = UDim2.new(1, -8, 0, 35)
        tglFrame.BackgroundColor3 = Theme.ElementBg
        tglFrame.Parent = container
        Instance.new("UICorner", tglFrame).CornerRadius = UDim.new(0, 6)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.Text
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = tglFrame

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 36, 0, 20)
        indicator.Position = UDim2.new(1, -46, 0.5, -10)
        indicator.BackgroundColor3 = state and Theme.Accent or Theme.MainBg
        indicator.Parent = tglFrame
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(0, 16, 0, 16)
        circle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        circle.Parent = indicator
        Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

        local clickBtn = Instance.new("TextButton")
        clickBtn.Size = UDim2.new(1, 0, 1, 0)
        clickBtn.BackgroundTransparency = 1
        clickBtn.Text = ""
        clickBtn.Parent = tglFrame

        clickBtn.MouseButton1Click:Connect(function()
            state = not state
            local goalColor = state and Theme.Accent or Theme.MainBg
            local goalPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            
            TweenService:Create(indicator, TweenInfo.new(0.2), {BackgroundColor3 = goalColor}):Play()
            TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = goalPos}):Play()
            if callback then callback(state) end
        end)
    end

    -- 4. SLIDER
    function Window:AddSlider(text, min, max, default, callback)
        local sFrame = Instance.new("Frame")
        sFrame.Size = UDim2.new(1, -8, 0, 50)
        sFrame.BackgroundColor3 = Theme.ElementBg
        sFrame.Parent = container
        Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 6)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 25)
        label.Position = UDim2.new(0, 10, 0, 2)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.Text
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = sFrame

        local valLabel = Instance.new("TextLabel")
        valLabel.Size = UDim2.new(0, 50, 0, 25)
        valLabel.Position = UDim2.new(1, -60, 0, 2)
        valLabel.BackgroundTransparency = 1
        valLabel.Text = tostring(default)
        valLabel.TextColor3 = Theme.Accent
        valLabel.Font = Enum.Font.GothamBold
        valLabel.TextSize = 13
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.Parent = sFrame

        local bgBar = Instance.new("Frame")
        bgBar.Size = UDim2.new(1, -20, 0, 6)
        bgBar.Position = UDim2.new(0, 10, 0, 32)
        bgBar.BackgroundColor3 = Theme.MainBg
        bgBar.Parent = sFrame
        Instance.new("UICorner", bgBar).CornerRadius = UDim.new(1, 0)

        local fillBar = Instance.new("Frame")
        local initialScale = math.clamp((default - min) / (max - min), 0, 1)
        fillBar.Size = UDim2.new(initialScale, 0, 1, 0)
        fillBar.BackgroundColor3 = Theme.Accent
        fillBar.Parent = bgBar
        Instance.new("UICorner", fillBar).CornerRadius = UDim.new(1, 0)

        local clickBtn = Instance.new("TextButton")
        clickBtn.Size = UDim2.new(1, 0, 1, 10)
        clickBtn.Position = UDim2.new(0, 0, 0, -5)
        clickBtn.BackgroundTransparency = 1
        clickBtn.Text = ""
        clickBtn.Parent = bgBar

        local draggingSlider = false
        local function updateSlider(input)
            local pos = math.clamp((input.Position.X - bgBar.AbsolutePosition.X) / bgBar.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + ((max - min) * pos))
            fillBar.Size = UDim2.new(pos, 0, 1, 0)
            valLabel.Text = tostring(value)
            if callback then callback(value) end
        end

        clickBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSlider = true
                updateSlider(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input) end
        end)
    end

    -- 5. DROPDOWN (NEW)
    function Window:AddDropdown(text, list, callback)
        local dFrame = Instance.new("Frame")
        dFrame.Size = UDim2.new(1, -8, 0, 35)
        dFrame.BackgroundColor3 = Theme.ElementBg
        dFrame.ClipsDescendants = true
        dFrame.Parent = container
        Instance.new("UICorner", dFrame).CornerRadius = UDim.new(0, 6)

        local topBtn = Instance.new("TextButton")
        topBtn.Size = UDim2.new(1, 0, 0, 35)
        topBtn.BackgroundTransparency = 1
        topBtn.Text = "  " .. text .. " : [Select]"
        topBtn.TextColor3 = Theme.Text
        topBtn.Font = Enum.Font.GothamSemibold
        topBtn.TextSize = 13
        topBtn.TextXAlignment = Enum.TextXAlignment.Left
        topBtn.Parent = dFrame

        local dropLayout = Instance.new("UIListLayout")
        dropLayout.Padding = UDim.new(0, 2)
        dropLayout.Parent = dFrame

        local isOpen = false
        topBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            local targetHeight = isOpen and (35 + (#list * 28) + 5) or 35
            TweenService:Create(dFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, -8, 0, targetHeight)}):Play()
        end)

        for _, item in ipairs(list) do
            local itemBtn = Instance.new("TextButton")
            itemBtn.Size = UDim2.new(1, -16, 0, 26)
            itemBtn.Position = UDim2.new(0, 8, 0, 0)
            itemBtn.BackgroundColor3 = Theme.TopBg
            itemBtn.Text = tostring(item)
            itemBtn.TextColor3 = Theme.TextDim
            itemBtn.Font = Enum.Font.Gotham
            itemBtn.TextSize = 12
            itemBtn.Parent = dFrame
            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 4)

            itemBtn.MouseEnter:Connect(function() TweenService:Create(itemBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.MainBg}):Play() end)
            itemBtn.MouseLeave:Connect(function() TweenService:Create(itemBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.TopBg, TextColor3 = Theme.TextDim}):Play() end)
            
            itemBtn.MouseButton1Click:Connect(function()
                topBtn.Text = "  " .. text .. " : " .. tostring(item)
                isOpen = false
                TweenService:Create(dFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -8, 0, 35)}):Play()
                if callback then callback(item) end
            end)
        end
    end

    return Window
end

return ScriptUI
