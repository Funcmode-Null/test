local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local HapticService = game:GetService("HapticService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isMobile = UserInputService.TouchEnabled

-- Remove old GUI
local existing = playerGui:FindFirstChild("TCS_ScriptGUI")
if existing then existing:Destroy() end

-- Theme
local Theme = {
    Colors = {
        Background = Color3.fromRGB(28,30,34),
        Panel = Color3.fromRGB(30,32,36),
        PanelAlt = Color3.fromRGB(24,26,30),
        TitleBar = Color3.fromRGB(20,20,24),
        Button = Color3.fromRGB(36,36,36),
        ButtonActive = Color3.fromRGB(60,120,200),
        Text = Color3.fromRGB(235,235,235),
        Shadow = Color3.fromRGB(0,0,0)
    },
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    TextSize = 14,
    TitleSize = 18,
    Padding = 8,
    ColorVariants = {
        info = Color3.fromRGB(60,120,200),
        success = Color3.fromRGB(60,200,120),
        error = Color3.fromRGB(200,80,80),
    }
}

local tweenFast = TweenInfo.new(0.25, Enum.EasingStyle.Quad)
local tweenSlow = TweenInfo.new(0.3, Enum.EasingStyle.Quad)

-- Helpers
local function New(class, props)
    local obj = Instance.new(class)
    if props then
        if typeof(props)=="Instance" then obj.Parent=props
        elseif type(props)=="table" then
            for k,v in pairs(props) do obj[k]=v end
        else error(("New(): props must be table/Instance, got %s"):format(typeof(props))) end
    end
    return obj
end

local function PlayTween(obj, info, props)
    if not obj then return end
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-- Persistent Floating Button Position
local ToggleKey = "TCS_ToggleBtn_Pos"
local function SaveTogglePos(pos)
    if not pos then return end
    pcall(function()
        player:SetAttribute(ToggleKey, HttpService:JSONEncode(pos))
    end)
end

local function LoadTogglePos()
    local attr = player:GetAttribute(ToggleKey)
    if attr then
        local suc, data = pcall(function() return HttpService:JSONDecode(attr) end)
        if suc then return data end
    end
    return nil
end

-- Persistent State
local SaveKey = "TCS_GUI_State"
local function SaveState(state)
    if not state then return end
    pcall(function()
        player:SetAttribute(SaveKey, HttpService:JSONEncode(state))
    end)
end
local function LoadState()
    local attr = player:GetAttribute(SaveKey)
    if attr then
        local suc, data = pcall(function() return HttpService:JSONDecode(attr) end)
        if suc then return data end
    end
    return nil
end

-- UI Constructor
local function MakeUI()
    local screenGui = New("ScreenGui",{Name="TCS_ScriptGUI",ResetOnSpawn=false,Parent=playerGui})

    local mainWidth = isMobile and 0.75 or 0.55
    local mainHeight = isMobile and 0.55 or 0.6

    local state = LoadState()
    local savedPos = state and state.Position
    local savedSize = state and state.Size
    local savedMinimized = state and state.Minimized
    local savedCollapsed = state and state.Collapsed or false

    local main = New("Frame",{
        Parent = screenGui,
        Name = "Main",
        AnchorPoint = Vector2.new(0,0.5),
        Position = savedPos and UDim2.fromOffset(savedPos.X, savedPos.Y) or UDim2.new(0,10,0.5,0),
        Size = savedSize and UDim2.fromOffset(savedSize.X, savedSize.Y) or UDim2.new(mainWidth,0,mainHeight,0),
        BackgroundColor3 = Theme.Colors.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })

    -- Title
    local titleBar = New("Frame",{
        Parent = main,
        Size=UDim2.new(1,0,0,34),
        BackgroundColor3=Theme.Colors.TitleBar,
        BorderSizePixel=0
    })
    New("TextLabel",{
        Parent = titleBar,
        Text = "TCS SCRIPT",
        Font = Theme.FontBold,
        TextSize = Theme.TitleSize,
        TextColor3 = Theme.Colors.Text,
        BackgroundTransparency=1,
        Size=UDim2.new(0.5,0,1,0),
        Position=UDim2.new(0,12,0,0),
        TextXAlignment=Enum.TextXAlignment.Left
    })

    -- Collapse Button
    local btnCollapse = New("TextButton",{
        Parent=titleBar,
        Text="<<",
        Font=Theme.FontBold,
        TextSize=16,
        Size=UDim2.new(0,40,0,26),
        Position=UDim2.new(1,-138,0.5,-13),
        BackgroundColor3=Theme.Colors.Button,
        TextColor3=Theme.Colors.Text,
        BorderSizePixel=0
    })

    -- Close/Min
    local btnClose = New("TextButton",{
        Parent=titleBar,
        Text="❌",
        Font=Theme.FontBold,
        TextSize=16,
        Size=UDim2.new(0,40,0,26),
        Position=UDim2.new(1,-46,0.5,-13),
        BackgroundColor3=Theme.Colors.Button,
        TextColor3=Theme.Colors.Text,
        BorderSizePixel=0
    })
    local btnMin = New("TextButton",{
        Parent=titleBar,
        Text="➖",
        Font=Theme.FontBold,
        TextSize=16,
        Size=UDim2.new(0,40,0,26),
        Position=UDim2.new(1,-92,0.5,-13),
        BackgroundColor3=Theme.Colors.Button,
        TextColor3=Theme.Colors.Text,
        BorderSizePixel=0
    })

    -- Body
    local body = New("Frame",{
        Parent=main,
        Position=UDim2.new(0,0,0,34),
        Size=UDim2.new(1,0,1,-34),
        BackgroundTransparency=1,
        Name="Body"
    })

    local leftPanel = New("Frame",{Parent=body,Size=UDim2.new(0.25,0,1,0),BackgroundColor3=Theme.Colors.PanelAlt,BorderSizePixel=0})
    local rightPanel = New("Frame",{Parent=body,Position=UDim2.new(0.25,0,0,0),Size=UDim2.new(0.75,0,1,0),BackgroundColor3=Theme.Colors.Panel,BorderSizePixel=0})

    -- Scrolls
    local leftScroll = New("ScrollingFrame",{
        Parent=leftPanel,
        Size=UDim2.new(1,0,1,-16),
        Position=UDim2.new(0,0,0,8),
        ScrollBarThickness=isMobile and 16 or 6,
        ScrollBarImageTransparency=1,
        BackgroundTransparency=1
    })
    New("UIListLayout",{Parent=leftScroll,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,Theme.Padding)})

    local padding = Theme.Padding
    local contentScroll = New("ScrollingFrame",{
        Parent=rightPanel,
        Size=UDim2.new(1, -2*padding,1, -2*padding),
        Position=UDim2.new(0, padding,0, padding),
        ScrollBarThickness=isMobile and 16 or 8,
        ScrollBarImageTransparency=1,
        BackgroundTransparency=1
    })
    New("UIListLayout",{Parent=contentScroll,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)})

    -- Notifications - Top-right on mobile, bottom-right on desktop
    local notifHolder = New("Frame",{
        Parent=screenGui,
        AnchorPoint=isMobile and Vector2.new(1,0) or Vector2.new(1,1),
        Size=isMobile and UDim2.new(0,250,0,150) or UDim2.new(0,280,0,200),
        Position=isMobile and UDim2.new(1,-12,0,12) or UDim2.new(1,-12,1,-12),
        BackgroundTransparency=1,
        ClipsDescendants=true
    })
    local notifLayout = New("UIListLayout",{
        Parent=notifHolder,
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,Theme.Padding)
    })
    notifLayout.VerticalAlignment = isMobile and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom

    -- Apply collapsed state
    if savedCollapsed then
        leftPanel.Visible = false
        rightPanel.Position = UDim2.new(0,0,0,0)
        rightPanel.Size = UDim2.new(1,0,1,0)
        btnCollapse.Text = ">>"
    end

    return {
        screenGui=screenGui,main=main,btnClose=btnClose,btnMin=btnMin,btnCollapse=btnCollapse,leftScroll=leftScroll,contentScroll=contentScroll,
        notifHolder=notifHolder,titleBar=titleBar,body=body,leftPanel=leftPanel,rightPanel=rightPanel,state=state
    }
end

-- Make UI
local UI = MakeUI()
local main, btnClose, btnMin, btnCollapse, body, leftPanel, rightPanel = UI.main, UI.btnClose, UI.btnMin, UI.btnCollapse, UI.body, UI.leftPanel, UI.rightPanel
local leftScroll, contentScroll, notifHolder = UI.leftScroll, UI.contentScroll, UI.notifHolder
local titleBar = UI.titleBar

local state = UI.state
local isMinimized = state and state.Minimized or false
local isCollapsed = state and state.Collapsed or false

local normalSize = main.Size
local minimizeSize = UDim2.new(0.3, 0, 0, 34)

-- Apply saved minimized state
if isMinimized then
    body.BackgroundTransparency = 1
    main.Size = minimizeSize
    btnMin.Text = "[]"
end

-- Set initial visibility: On mobile, start with main hidden so toggle shows
if isMobile then
    main.Visible = false
end

-- TAB BUTTONS table
local tabs, tabFrames, tabButtons, currentTab = {}, {}, {}, nil

-- Scale calculation
local function GetScaleFactor()
    local screenSize = workspace.CurrentCamera.ViewportSize
    local scaleX = screenSize.X / 1920
    local scaleY = screenSize.Y / 1080
    return math.min(scaleX, scaleY)
end

local scaleFactor = GetScaleFactor()
Theme.TextSize = math.clamp(14 * scaleFactor, 12, 24)
Theme.TitleSize = math.clamp(18 * scaleFactor, 14, 30)
Theme.Padding = math.clamp(8 * scaleFactor, isMobile and 8 or 4, isMobile and 20 or 16)

local function UpdateButtonSize(btn)
    if btn and btn:IsA("TextButton") then
        local height = isMobile and 40 or 30
        local widthOffset = 0
        btn.Size = UDim2.new(1, widthOffset, 0, height * scaleFactor)
        btn.TextSize = Theme.TextSize
    end
end

-- Function to update scroll bar visibility and canvas size
local function UpdateScrollBar(scrollFrame)
    local listLayout = scrollFrame:FindFirstChildOfClass("UIListLayout")
    if not listLayout then return end

    local contentHeight = listLayout.AbsoluteContentSize.Y
    local frameHeight = scrollFrame.AbsoluteSize.Y

    -- Set CanvasSize to content height exactly
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)

    -- Hide scroll bar if content fits or is smaller than frame, show only if it exceeds
    scrollFrame.ScrollBarImageTransparency = contentHeight <= frameHeight and 1 or 0
end

-- Combined update function for viewport changes
local function OnViewportChanged()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    scaleFactor = GetScaleFactor()
    Theme.TextSize = math.clamp(14 * scaleFactor, 12, 24)
    Theme.TitleSize = math.clamp(18 * scaleFactor, 14, 30)
    Theme.Padding = math.clamp(8 * scaleFactor, isMobile and 8 or 4, isMobile and 20 or 16)

    -- Update title bar elements
    local titleLabel = titleBar:FindFirstChildOfClass("TextLabel")
    if titleLabel then titleLabel.TextSize = Theme.TitleSize end
    btnClose.TextSize = math.clamp(16 * scaleFactor, 14, 20)
    btnMin.TextSize = math.clamp(16 * scaleFactor, 14, 20)
    btnCollapse.TextSize = math.clamp(16 * scaleFactor, 14, 20)

    -- Update tab buttons
    for _, btn in pairs(tabButtons) do
        UpdateButtonSize(btn)
    end

    -- Update scroll contents
    for _, scroll in pairs({leftScroll, contentScroll}) do
        local listLayout = scroll:FindFirstChildOfClass("UIListLayout")
        if listLayout then
            if scroll == contentScroll then
                listLayout.Padding = UDim.new(0, 0)
            else
                listLayout.Padding = UDim.new(0, Theme.Padding)
            end
        end
        for _, child in pairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextSize = Theme.TextSize
                local h = isMobile and 40 or 30
                local widthOffset = 0
                child.Size = UDim2.new(1, widthOffset, 0, h * scaleFactor)
            elseif child:IsA("TextLabel") then
                child.TextSize = Theme.TextSize
                local labelHeight = math.clamp(30 * scaleFactor, 24, 40)
                child.Size = UDim2.new(1, 0, 0, labelHeight)
            end
        end
        UpdateScrollBar(scroll)
    end

    -- Update notif holder padding
    local notifLayout = notifHolder:FindFirstChildOfClass("UIListLayout")
    if notifLayout then notifLayout.Padding = UDim.new(0, Theme.Padding) end

    -- Clamp main position
    local mainPos = main.Position
    local mainAbsSize = main.AbsoluteSize
    local clampedX = math.clamp(mainPos.X.Offset, 0, viewportSize.X - mainAbsSize.X)
    local clampedY = math.clamp(mainPos.Y.Offset, 0, viewportSize.Y - mainAbsSize.Y)
    if clampedX ~= mainPos.X.Offset or clampedY ~= mainPos.Y.Offset then
        main.Position = UDim2.new(0, clampedX, 0.5, clampedY - mainAbsSize.Y / 2)
    end

    -- Clamp toggle position
    local toggleBtn = UI.screenGui:FindFirstChild("ToggleButton")
    if toggleBtn then
        local pos = toggleBtn.Position
        local absSize = toggleBtn.AbsoluteSize
        local clampedTX = math.clamp(pos.X.Offset, 0, viewportSize.X - absSize.X)
        local clampedTY = math.clamp(pos.Y.Offset, 0, viewportSize.Y - absSize.Y)
        if clampedTX ~= pos.X.Offset or clampedTY ~= pos.Y.Offset then
            PlayTween(toggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, clampedTX, 0, clampedTY)
            })
            SaveTogglePos({ X = clampedTX, Y = clampedTY })
        end
    end

    -- Update resize limits
    if resizeHandle then
        maxWidth = viewportSize.X * 0.9
        maxHeight = viewportSize.Y * 0.9
    end
end

-- Listen for viewport changes (combined)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(OnViewportChanged)

-- Initial update
OnViewportChanged()

-- Notify function for scaled notifications
local activeNotifs = {}
Notify = function(text, nType, duration)
    nType = nType or "info"
    duration = duration or 4

    if #activeNotifs >= 3 then
        activeNotifs[1]:Destroy()
        table.remove(activeNotifs, 1)
    end

    local notifWidth = math.clamp(notifHolder.AbsoluteSize.X - 20, isMobile and 150 or 200, isMobile and 250 or 400)
    local notif = New("Frame", {
        Parent = notifHolder,
        Size = UDim2.new(0, notifWidth, 0, 0),
        BackgroundColor3 = Theme.Colors.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    New("UICorner", { Parent = notif, CornerRadius = UDim.new(0, 8) })
    New("UIStroke", { Parent = notif, Color = Theme.Colors.Shadow, Thickness = 1, Transparency = 0.6 })
    local label = New("TextLabel", {
        Parent = notif,
        Size = UDim2.new(1, -16, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        Font = Theme.Font,
        TextSize = Theme.TextSize,
        TextColor3 = Theme.Colors.Text,
        BackgroundTransparency = 1,
        TextWrapped = true,
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center
    })
    local bar = New("Frame", {
        Parent = notif,
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = Theme.ColorVariants[nType],
        BorderSizePixel = 0
    })
    table.insert(activeNotifs, notif)

    label:GetPropertyChangedSignal("TextBounds"):Connect(function()
        notif.Size = UDim2.new(0, notifWidth, 0, math.max(40, label.TextBounds.Y + 20))
    end)

    notif.BackgroundTransparency = 1
    label.TextTransparency = 1
    PlayTween(notif, tweenFast, { BackgroundTransparency = 0 })
    PlayTween(label, tweenFast, { TextTransparency = 0 })
    PlayTween(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 3) })

    task.spawn(function()
        task.wait(duration)
        PlayTween(notif, tweenFast, { BackgroundTransparency = 1 })
        PlayTween(label, tweenFast, { TextTransparency = 1 })
        task.wait(0.25)
        notif:Destroy()
        for i, v in ipairs(activeNotifs) do
            if v == notif then
                table.remove(activeNotifs, i)
                break
            end
        end
    end)
end

-- Connections tracker
local connections = {}
local function Connect(sig, func) local c = sig:Connect(func) table.insert(connections, c) return c end
local function CleanupConnections() for _, c in ipairs(connections) do if c and c.Disconnect then c:Disconnect() end end connections = {} end

-- Dragging
do
    local dragging, dragStart, startPos, dragInput
    local dragChangedConn
    local function update(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    Connect(titleBar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            if dragChangedConn then dragChangedConn:Disconnect() end
            dragChangedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                    SaveState({ Position = { X = main.AbsolutePosition.X, Y = main.AbsolutePosition.Y }, Size = { X = main.AbsoluteSize.X, Y = main.AbsoluteSize.Y }, Minimized = isMinimized, Collapsed = isCollapsed })
                end
            end)
        end
    end)
    Connect(titleBar.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and input == dragInput then update(input) end
    end)
end

-- Haptic feedback for mobile button clicks
local supportsHaptic = HapticService:IsVibrationSupported(Enum.UserInputType.Touch) and HapticService:IsMotorSupported(Enum.UserInputType.Touch, Enum.VibrationMotor.Small)
local function HapticClick()
    if isMobile and supportsHaptic then
        HapticService:SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Small, 1)
        task.delay(0.05, function()
            HapticService:SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Small, 0)
        end)
    end
end

-- Collapse Tabs
Connect(btnCollapse.MouseButton1Click, function()
    HapticClick()
    isCollapsed = not isCollapsed
    if isCollapsed then
        PlayTween(leftPanel, tweenFast, { Size = UDim2.new(0,0,1,0) })
        PlayTween(rightPanel, tweenFast, { Position = UDim2.new(0,0,0,0), Size = UDim2.new(1,0,1,0) })
        leftPanel.Visible = false
        btnCollapse.Text = ">>"
    else
        leftPanel.Visible = true
        PlayTween(leftPanel, tweenFast, { Size = UDim2.new(0.25,0,1,0) })
        PlayTween(rightPanel, tweenFast, { Position = UDim2.new(0.25,0,0,0), Size = UDim2.new(0.75,0,1,0) })
        btnCollapse.Text = "<<"
    end
    UpdateScrollBar(leftScroll)
    UpdateScrollBar(contentScroll)
    SaveState({ Position = { X = main.AbsolutePosition.X, Y = main.AbsolutePosition.Y }, Size = { X = main.AbsoluteSize.X, Y = main.AbsoluteSize.Y }, Minimized = isMinimized, Collapsed = isCollapsed })
end)

-- Minimize / Close
Connect(btnMin.MouseButton1Click, function()
    HapticClick()
    isMinimized = not isMinimized
    if isMinimized then
        PlayTween(body, tweenFast, { BackgroundTransparency = 1 })
        PlayTween(main, tweenFast, { Size = minimizeSize })
        btnMin.Text = "[]"
    else
        PlayTween(body, tweenFast, { BackgroundTransparency = 0 })
        PlayTween(main, tweenFast, { Size = normalSize })
        btnMin.Text = "➖"
    end
    SaveState({ Position = { X = main.AbsolutePosition.X, Y = main.AbsolutePosition.Y }, Size = { X = main.AbsoluteSize.X, Y = main.AbsoluteSize.Y }, Minimized = isMinimized, Collapsed = isCollapsed })
end)
Connect(btnClose.MouseButton1Click, function()
    HapticClick()
    if not isMobile then
        CleanupConnections()
        UI.screenGui:Destroy()
    else
        main.Visible = false
    end
end)

-- Hotkey toggle
Connect(UserInputService.InputBegan, function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        UI.main.Visible = not UI.main.Visible
    end
end)

-- Resize handle
local resizeHandle
local minWidth = isMobile and 250 or 300
local minHeight = isMobile and 200 or 200
local maxWidth = workspace.CurrentCamera.ViewportSize.X * 0.9
local maxHeight = workspace.CurrentCamera.ViewportSize.Y * 0.9
do
    local resizing = false
    local startSize, startMouse
    resizeHandle = New("Frame", {
        Parent = main,
        Size = isMobile and UDim2.new(0, 28, 0, 28) or UDim2.new(0, 16, 0, 16),
        Position = isMobile and UDim2.new(1, -28, 1, -28) or UDim2.new(1, -16, 1, -16),
        BackgroundColor3 = Theme.Colors.Button,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0),
        ZIndex = 10
    })
    New("UICorner", { Parent = resizeHandle, CornerRadius = UDim.new(0, 4) })
    for i = 0, 2 do
        local line = New("Frame", {
            Parent = resizeHandle,
            Size = UDim2.new(0, 10, 0, 2),
            BackgroundColor3 = Theme.Colors.Text,
            Rotation = -45,
            Position = UDim2.new(0, 2 + i * 4, 0, 10 - i * 4),
            BorderSizePixel = 0,
            ZIndex = 11
        })
        New("UICorner", { Parent = line, CornerRadius = UDim.new(0, 1) })
    end
    local hoverTween = TweenService:Create(resizeHandle, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Colors.ButtonActive })
    local leaveTween = TweenService:Create(resizeHandle, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Colors.Button })

    Connect(resizeHandle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startMouse = input.Position
            startSize = main.Size
            hoverTween:Play()
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    leaveTween:Play()
                    SaveState({ Position = { X = main.AbsolutePosition.X, Y = main.AbsolutePosition.Y }, Size = { X = main.AbsoluteSize.X, Y = main.AbsoluteSize.Y }, Minimized = isMinimized, Collapsed = isCollapsed })
                    UpdateScrollBar(leftScroll)
                    UpdateScrollBar(contentScroll)
                end
            end)
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startMouse
            local newWidth = math.clamp(startSize.X.Offset + delta.X, minWidth, maxWidth)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, minHeight, maxHeight)
            main.Size = UDim2.new(0, newWidth, 0, newHeight)
            UpdateScrollBar(leftScroll)
            UpdateScrollBar(contentScroll)
        end
    end)
    resizeHandle.MouseEnter:Connect(function() if not resizing then hoverTween:Play() end end)
    resizeHandle.MouseLeave:Connect(function() if not resizing then leaveTween:Play() end end)
end

-- Tabs system
local function SwitchTab(name)
    if currentTab == name then return end
    for tName, frame in pairs(tabFrames) do if frame and frame.Parent then frame.Visible = false end end
    for tName, btn in pairs(tabButtons) do if btn and btn.Parent then btn.BackgroundColor3 = Theme.Colors.Button end end
    if tabFrames[name] then
        tabFrames[name].Visible = true
    end
    if tabButtons[name] then tabButtons[name].BackgroundColor3 = Theme.Colors.ButtonActive end
    currentTab = name
    Notify("Switched to " .. name, "info", 2)
end

local function AddTab(name, callback)
    tabs[name] = callback
    local height = isMobile and 40 or 30
    local btn = New("TextButton", {
        Parent = leftScroll,
        Text = name,
        Font = Theme.Font,
        TextSize = isMobile and 18 or Theme.TextSize,
        TextColor3 = Theme.Colors.Text,
        BackgroundColor3 = Theme.Colors.Button,
        Size = UDim2.new(1, 0, 0, height * scaleFactor),
        BorderSizePixel = 0
    })
    New("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 6) })
    tabButtons[name] = btn
    UpdateButtonSize(btn)

    Connect(btn.MouseButton1Click, function()
        HapticClick()
        if not tabFrames[name] then
            local frame = New("Frame", {
                Parent = contentScroll,
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = true
            })
            tabFrames[name] = frame
            callback(frame)
            UpdateScrollBar(contentScroll)
        end
        SwitchTab(name)
    end)

    UpdateScrollBar(leftScroll)

    if not currentTab then
        if not tabFrames[name] then
            local frame = New("Frame", {
                Parent = contentScroll,
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = true
            })
            tabFrames[name] = frame
            callback(frame)
            UpdateScrollBar(contentScroll)
        end
        SwitchTab(name)
    end
    return btn
end

-- Floating Toggle Button (Draggable + Auto-Clamp with Tween)
do
    local savedTogglePos = LoadTogglePos()
    local toggleSize = isMobile and 60 or 60
    local toggleBtn = New("TextButton", {
        Parent = UI.screenGui,
        Name = "ToggleButton",
        Text = "TCS",
        Size = UDim2.new(0, toggleSize, 0, toggleSize),
        BackgroundColor3 = Theme.Colors.Button,
        TextColor3 = Theme.Colors.Text,
        BorderSizePixel = 0,
        ZIndex = 50,
        Font = Theme.FontBold,
        TextSize = math.clamp(16 * scaleFactor, 12, 20)
    })
    New("UICorner", { Parent = toggleBtn, CornerRadius = UDim.new(0, 12) })

    toggleBtn.Position = savedTogglePos and UDim2.fromOffset(savedTogglePos.X, savedTogglePos.Y) or UDim2.new(1, - (toggleSize + 12), 0, 12)
    toggleBtn.AnchorPoint = Vector2.new(0, 0)

    Connect(toggleBtn.MouseButton1Click, function()
        HapticClick()
        main.Visible = not main.Visible
    end)

    -- Dragging
    local dragging = false
    local dragStart, startPos

    Connect(toggleBtn.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    SaveTogglePos({ X = toggleBtn.Position.X.Offset, Y = toggleBtn.Position.Y.Offset })
                end
            end)
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newX = math.clamp(startPos.X.Offset + delta.X, 0, workspace.CurrentCamera.ViewportSize.X - toggleBtn.AbsoluteSize.X)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, workspace.CurrentCamera.ViewportSize.Y - toggleBtn.AbsoluteSize.Y)
            toggleBtn.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    -- Always show toggle button, but hide when main is visible on mobile
    if isMobile then
        local function UpdateToggleVis()
            toggleBtn.Visible = not main.Visible
        end
        UpdateToggleVis()
        Connect(main:GetPropertyChangedSignal("Visible"), UpdateToggleVis)
    end
end

-- Initial Notification
Notify("Created By TCS_Dev [FuncMode]", "info")

AddTab("AutoBuy", function(parent)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local HttpService = game:GetService("HttpService")
    local HapticService = game:GetService("HapticService")
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local BuyItemRemote = remotes:WaitForChild("BuyItem")
    local BuyGearRemote = remotes:WaitForChild("BuyGear")

    local player = game.Players.LocalPlayer
    local isMobile = UserInputService.TouchEnabled

    -- Haptic feedback local to this tab
    local supportsHaptic = HapticService:IsVibrationSupported(Enum.UserInputType.Touch) and HapticService:IsMotorSupported(Enum.UserInputType.Touch, Enum.VibrationMotor.Small)
    local function HapticClick()
        if isMobile and supportsHaptic then
            HapticService:SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Small, 1)
            task.delay(0.05, function()
                HapticService:SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Small, 0)
            end)
        end
    end

    -- Save/Load Keys
    local SaveKey = "TCS_AutoBuy_State"
    local function SaveAutoBuyState(state)
        if not state then return end
        pcall(function()
            player:SetAttribute(SaveKey, HttpService:JSONEncode(state))
        end)
    end
    local function LoadAutoBuyState()
        local attr = player:GetAttribute(SaveKey)
        if attr then
            local suc, data = pcall(function() return HttpService:JSONDecode(attr) end)
            if suc then return data end
        end
        return nil
    end

    -- Options (pre-compute lowercase for faster filtering)
    local PlantOptions = {
        "Cactus Seed","Strawberry Seed","Pumpkin Seed","Sunflower Seed",
        "Dragon Fruit Seed","Eggplant Seed","Watermelon Seed","Grape Seed",
        "Cocotank Seed","Carnivorous Plant Seed","Mr Carrot Seed",
        "Tomatrio Seed","Shroombino Seed", "Mango Seed"
    }
    local GearOptions = {
        "Water Bucket","Frost Grenade","Banana Gun","Frost Blower","Carrot Launcher"
    }
    local PlantOptionsLower, GearOptionsLower = {}, {}
    for _, opt in ipairs(PlantOptions) do table.insert(PlantOptionsLower, opt:lower()) end
    for _, opt in ipairs(GearOptions) do table.insert(GearOptionsLower, opt:lower()) end

    -- State
    local selectedType = "Plant"
    local selectedPerType = { Plant = {}, Gear = {} }
    local autoStatePerType = { Plant = false, Gear = false }
    local runningLoops = { Plant = false, Gear = false }
    local autoDelay = { Plant = 0.3, Gear = 0.3 }

    -- Scaled text sizes (updated on resize)
    local regularTextSize = 14
    local boldTextSize = 16
    local smallTextSize = 12

    local function autoLoop(typ)
        while autoStatePerType[typ] do
            for _, item in ipairs(selectedPerType[typ]) do
                for i = 1, 10 do
                    local success, err = pcall(function()
                        if typ == "Plant" then
                            BuyItemRemote:FireServer(item)
                        else
                            BuyGearRemote:FireServer(item)
                        end
                    end)
                    if not success then
                        warn("AutoBuy error: " .. tostring(err))
                    end
                    task.wait(autoDelay[typ])
                end
            end
            task.wait(0.5)
        end
        runningLoops[typ] = false
    end

    -- Load saved state
    local savedState = LoadAutoBuyState()
    if savedState then
        selectedPerType = savedState.selectedPerType or selectedPerType
        autoStatePerType = savedState.autoStatePerType or autoStatePerType
        autoDelay = savedState.autoDelay or autoDelay
        -- Restart loops if saved as on
        for typ, on in pairs(autoStatePerType) do
            if on and not runningLoops[typ] then
                runningLoops[typ] = true
                task.spawn(function() autoLoop(typ) end)
            end
        end
    end

    -- Initial scale
    local currentScale = scaleFactor

    -- Frame container (auto-size for responsiveness)
    local frame = New("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Colors.PanelAlt,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    New("UICorner", {Parent = frame, CornerRadius = UDim.new(0,8)})

    local base_gap = 5
    local base_action_gap = 10

    local titleLabel = New("TextLabel", {
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 30 * currentScale),
        Position = UDim2.new(0, 0, 0, 0),
        Font = Theme.FontBold,
        TextSize = math.clamp(16 * currentScale, 12, 20),
        Text = "Select Items to Auto Buy",
        TextColor3 = Theme.Colors.Text,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Type selector
    local typeSelector = New("Frame", {
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 30 * currentScale),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    })
    local plantBtn = New("TextButton", {
        Parent = typeSelector, 
        Size = UDim2.new(0.5, 0, 1, 0),
        Text = "Plant", 
        Font = Theme.Font, 
        TextSize = Theme.TextSize,
        BackgroundColor3 = Theme.Colors.Button, 
        TextColor3 = Theme.Colors.Text,
        TextScaled = false,
    })
    local gearBtn = New("TextButton", {
        Parent = typeSelector, 
        Position = UDim2.new(0.5, base_gap, 0, 0), 
        Size = UDim2.new(0.5, 0, 1, 0),
        Text = "Gear", 
        Font = Theme.Font, 
        TextSize = Theme.TextSize,
        BackgroundColor3 = Theme.Colors.Button, 
        TextColor3 = Theme.Colors.Text,
        TextScaled = false,
    })
    New("UICorner", {Parent = plantBtn, CornerRadius = UDim.new(0,6)})
    New("UICorner", {Parent = gearBtn, CornerRadius = UDim.new(0,6)})

    -- Search
    local searchBox = New("TextBox", {
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 28 * currentScale),
        Position = UDim2.new(0, 0, 0, 0),
        PlaceholderText = "Search...",
        Font = Theme.Font,
        TextSize = Theme.TextSize,
        TextColor3 = Theme.Colors.Text,
        BackgroundColor3 = Theme.Colors.Button,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Text = "",
        TextScaled = false,
    })
    New("UICorner", {Parent = searchBox, CornerRadius = UDim.new(0,6)})

    -- Delay Box
    local delayBox = New("TextBox", {
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 28 * currentScale),
        Position = UDim2.new(0, 0, 0, 0),
        PlaceholderText = "Delay (s): 0.3",
        Font = Theme.Font, 
        TextSize = Theme.TextSize,
        TextColor3 = Theme.Colors.Text, 
        BackgroundColor3 = Theme.Colors.Button,
        BorderSizePixel = 0, 
        Text = tostring(autoDelay[selectedType]),
        TextScaled = false,
    })
    New("UICorner", {Parent = delayBox, CornerRadius = UDim.new(0,6)})

    -- Clear & Select All & Select Both & Clear All
    local btnContainer = New("Frame", {
        Parent = frame, 
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 28 * currentScale), 
        BackgroundTransparency = 1,
    })
    local clearBtn = New("TextButton", {
        Parent = btnContainer, 
        Size = UDim2.new(0.25, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Clear Selection", 
        Font = Theme.Font, 
        TextSize = Theme.TextSize,
        BackgroundColor3 = Theme.ColorVariants.error, 
        TextColor3 = Theme.Colors.Text,
        TextScaled = true,
    })
    local selectAllBtn = New("TextButton", {
        Parent = btnContainer, 
        Size = UDim2.new(0.25, 0, 1, 0),
        Position = UDim2.new(0.25, base_action_gap, 0, 0), 
        Text = "Select All", 
        Font = Theme.Font, 
        TextSize = Theme.TextSize,
        BackgroundColor3 = Theme.ColorVariants.success, 
        TextColor3 = Theme.Colors.Text,
        TextScaled = true,
    })
    local selectBothBtn = New("TextButton", {
        Parent = btnContainer, 
        Size = UDim2.new(0.25, 0, 1, 0),
        Position = UDim2.new(0.5, base_action_gap, 0, 0), 
        Text = "Select Both", 
        Font = Theme.Font, 
        TextSize = Theme.TextSize,
        BackgroundColor3 = Theme.Colors.Button, 
        TextColor3 = Theme.Colors.Text,
        TextScaled = true,
    })
    local clearAllBtn = New("TextButton", {
        Parent = btnContainer, 
        Size = UDim2.new(0.25, 0, 1, 0),
        Position = UDim2.new(0.75, base_action_gap, 0, 0),
        Text = "Clear All", 
        Font = Theme.Font, 
        TextSize = Theme.TextSize,
        BackgroundColor3 = Theme.ColorVariants.error, 
        TextColor3 = Theme.Colors.Text,
        TextScaled = true,
    })
    New("UICorner", {Parent = clearBtn, CornerRadius = UDim.new(0,6)})
    New("UICorner", {Parent = selectAllBtn, CornerRadius = UDim.new(0,6)})
    New("UICorner", {Parent = selectBothBtn, CornerRadius = UDim.new(0,6)})
    New("UICorner", {Parent = clearAllBtn, CornerRadius = UDim.new(0,6)})

    -- Dropdown list (scaled height)
    local dropdownList = New("ScrollingFrame", {
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 150 * currentScale),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.Colors.PanelAlt,
        ClipsDescendants = true, 
        ScrollBarThickness = isMobile and 16 or 6,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    local listLayout = New("UIListLayout", {Parent = dropdownList, Padding = UDim.new(0, 4 * currentScale), SortOrder = Enum.SortOrder.LayoutOrder})

    -- Auto Buy toggle button (scaled)
    local autoBtn = New("TextButton", {
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 36 * currentScale),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Auto Buy: OFF", 
        Font = Theme.FontBold, 
        TextSize = math.clamp(16 * currentScale, 14, 20),
        BackgroundColor3 = Theme.ColorVariants.error, 
        TextColor3 = Theme.Colors.Text,
        BorderSizePixel = 0,
        TextScaled = true,
    })
    New("UICorner", {Parent = autoBtn, CornerRadius = UDim.new(0,6)})

    -- Auto Buy Both button
    local bothAutoBtn = New("TextButton", {
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 36 * currentScale),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Auto Buy Both: OFF", 
        Font = Theme.FontBold, 
        TextSize = math.clamp(16 * currentScale, 14, 20),
        BackgroundColor3 = Theme.ColorVariants.error, 
        TextColor3 = Theme.Colors.Text,
        BorderSizePixel = 0,
        TextScaled = true,
    })
    New("UICorner", {Parent = bothAutoBtn, CornerRadius = UDim.new(0,6)})

    -- Status Label
    local statusLabel = New("TextLabel", {
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 24 * currentScale),
        Position = UDim2.new(0, 0, 0, 0),
        Font = Theme.Font,
        TextSize = math.clamp(12 * currentScale, 10, 14),
        Text = "",
        TextColor3 = Theme.Colors.Text,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    })

    -- Button pool + connection cleanup (optimized connection storage)
    local buttonPool = {}
    local buttonConnections = {}
    local hoverTween = TweenInfo.new(0.1, Enum.EasingStyle.Quad)
    local clickTween = TweenInfo.new(0.05, Enum.EasingStyle.Quad)
    local hoverInProps = {BackgroundColor3 = Color3.fromRGB(180,180,180), Size = UDim2.new(1, -4, 0, 30 * currentScale)}
    local hoverOutProps = {BackgroundColor3 = Theme.Colors.Button, Size = UDim2.new(1, -4, 0, 28 * currentScale)}
    local clickInProps = {Size = UDim2.new(1, -4, 0, 26 * currentScale)}
    local clickOutProps = {Size = UDim2.new(1, -4, 0, 28 * currentScale)}

    local function getDropdownButton()
        local btn = table.remove(buttonPool)
        if not btn then
            btn = New("TextButton", {
                Size = UDim2.new(1, -4 * currentScale, 0, 28 * currentScale),
                Font = Theme.Font, 
                TextColor3 = Theme.Colors.Text, 
                BorderSizePixel = 0,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            New("UICorner",{Parent=btn, CornerRadius=UDim.new(0,6)})
        else
            btn.Size = UDim2.new(1, -4 * currentScale, 0, 28 * currentScale)
            btn.TextXAlignment = Enum.TextXAlignment.Left
        end
        btn.Visible = true
        return btn
    end

    local function recycleButton(btn)
        if buttonConnections[btn] then
            for _,conn in ipairs(buttonConnections[btn]) do 
                if conn and conn.Disconnect then 
                    conn:Disconnect() 
                end
            end
            buttonConnections[btn] = nil
        end
        btn.Size = UDim2.new(1, -4 * currentScale, 0, 28 * currentScale)
        btn.BackgroundColor3 = Theme.Colors.Button
        btn.Visible, btn.Parent = false, nil
        table.insert(buttonPool, btn)
    end

    local function updateTitle()
        local count = #selectedPerType[selectedType]
        local total = selectedType == "Plant" and #PlantOptions or #GearOptions
        titleLabel.Text = string.format("Select Items to Auto Buy (%d/%d)", count, total)
    end

    local function updateStatusLabel()
        local plantSel = #selectedPerType.Plant
        local gearSel = #selectedPerType.Gear
        local plantStatus = autoStatePerType.Plant and "ON" or "OFF"
        local gearStatus = autoStatePerType.Gear and "ON" or "OFF"
        statusLabel.Text = string.format("Plants: %d selected (%s) | Gears: %d selected (%s)", plantSel, plantStatus, gearSel, gearStatus)
    end

    local function updateAutoBtn()
        if not autoBtn then return end
        local typ = selectedType
        if autoStatePerType[typ] then
            autoBtn.Text = "Auto Buy: ON"
            autoBtn.BackgroundColor3 = Theme.ColorVariants.success
        else
            autoBtn.Text = "Auto Buy: OFF"
            autoBtn.BackgroundColor3 = Theme.ColorVariants.error
        end
        updateStatusLabel()
    end

    local function updateBothAutoBtn()
        if not bothAutoBtn then return end
        local plantOn = autoStatePerType.Plant
        local gearOn = autoStatePerType.Gear
        if plantOn and gearOn then
            bothAutoBtn.Text = "Auto Buy Both: ON"
            bothAutoBtn.BackgroundColor3 = Theme.ColorVariants.success
        elseif not plantOn and not gearOn then
            bothAutoBtn.Text = "Auto Buy Both: OFF"
            bothAutoBtn.BackgroundColor3 = Theme.ColorVariants.error
        else
            bothAutoBtn.Text = "Auto Buy Both: Mixed"
            bothAutoBtn.BackgroundColor3 = Theme.Colors.Button
        end
        updateStatusLabel()
    end

    local searchDebounce
    local function updateDropdownItems()
        for _,child in ipairs(dropdownList:GetChildren()) do
            if child:IsA("TextButton") then recycleButton(child) end
        end
        local options = selectedType == "Plant" and PlantOptions or GearOptions
        local optionsLower = selectedType == "Plant" and PlantOptionsLower or GearOptionsLower
        local currentSelected = selectedPerType[selectedType]
        local filter = searchBox.Text:lower()

        local filteredIndices = {}
        for i, _ in ipairs(options) do
            if filter == "" or optionsLower[i]:find(filter) then
                table.insert(filteredIndices, i)
            end
        end

        local layoutOrder = 1
        for _, idx in ipairs(filteredIndices) do
            local item = options[idx]
            local isSelected = table.find(currentSelected, item) ~= nil
            local btn = getDropdownButton()
            btn.Text = (isSelected and "✓ " or "") .. item
            btn.BackgroundColor3 = isSelected and Theme.ColorVariants.success or Theme.Colors.Button
            btn.TextSize = regularTextSize
            btn.LayoutOrder = layoutOrder
            layoutOrder += 1
            btn.Parent = dropdownList

            buttonConnections[btn] = {}

            -- Mouse hover effect with tween (cached props)
            table.insert(buttonConnections[btn], Connect(btn.MouseEnter, function()
                if not isSelected then
                    TweenService:Create(btn, hoverTween, hoverInProps):Play()
                end
            end))
            table.insert(buttonConnections[btn], Connect(btn.MouseLeave, function()
                if not isSelected then
                    TweenService:Create(btn, hoverTween, hoverOutProps):Play()
                end
            end))

            -- Click selection with animation (non-blocking chain)
            table.insert(buttonConnections[btn], Connect(btn.MouseButton1Click, function()
                HapticClick()
                -- Brief click animation (spawn to avoid blocking)
                local clickIn = TweenService:Create(btn, clickTween, clickInProps)
                clickIn:Play()
                task.spawn(function()
                    clickIn.Completed:Wait()
                    TweenService:Create(btn, clickTween, clickOutProps):Play()
                end)

                local idxSel = table.find(currentSelected, item)
                if idxSel then
                    table.remove(currentSelected, idxSel)
                    btn.BackgroundColor3 = Theme.Colors.Button
                    btn.Text = item
                    Notify("Removed: "..item, "error", 1.5)
                else
                    table.insert(currentSelected, item)
                    btn.BackgroundColor3 = Theme.ColorVariants.success
                    btn.Text = "✓ " .. item
                    Notify("Selected: "..item, "success", 1.5)
                end
                updateTitle()
                updateStatusLabel()
                SaveAutoBuyState({selectedPerType = selectedPerType, autoStatePerType = autoStatePerType, autoDelay = autoDelay})
            end))
        end

        -- Manually set canvas size to exact content height to prevent overscroll
        dropdownList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
        updateTitle()
    end

    -- Hover effects for type buttons
    local typeHoverTween = TweenInfo.new(0.1, Enum.EasingStyle.Quad)
    local typeHoverIn = {BackgroundColor3 = Theme.Colors.ButtonActive}
    local typeHoverOut = {BackgroundColor3 = Theme.Colors.Button}
    local function addTypeHover(btn)
        Connect(btn.MouseEnter, function()
            TweenService:Create(btn, typeHoverTween, typeHoverIn):Play()
        end)
        Connect(btn.MouseLeave, function()
            TweenService:Create(btn, typeHoverTween, typeHoverOut):Play()
        end)
    end
    addTypeHover(plantBtn)
    addTypeHover(gearBtn)

    -- Hover effects for action buttons
    local actionHoverTween = TweenInfo.new(0.1, Enum.EasingStyle.Quad)
    local actionHoverIn = {BackgroundColor3 = Theme.Colors.ButtonActive}
    local function actionHoverOut(btn)
        if btn == clearBtn or btn == clearAllBtn then
            return {BackgroundColor3 = Theme.ColorVariants.error}
        elseif btn == selectAllBtn then
            return {BackgroundColor3 = Theme.ColorVariants.success}
        else
            return {BackgroundColor3 = Theme.Colors.Button}
        end
    end
    local function addActionHover(btn)
        if not btn then return end
        Connect(btn.MouseEnter, function()
            TweenService:Create(btn, actionHoverTween, actionHoverIn):Play()
        end)
        Connect(btn.MouseLeave, function()
            TweenService:Create(btn, actionHoverTween, actionHoverOut(btn)):Play()
        end)
    end
    addActionHover(clearBtn)
    addActionHover(selectAllBtn)
    addActionHover(selectBothBtn)
    addActionHover(clearAllBtn)
    addActionHover(autoBtn)
    addActionHover(bothAutoBtn)

    -- Search debounce
    Connect(searchBox:GetPropertyChangedSignal("Text"), function()
        if searchDebounce then task.cancel(searchDebounce) end
        searchDebounce = task.delay(0.2, updateDropdownItems)
    end)

    -- Delay validation on focus lost
    Connect(delayBox.FocusLost, function()
        local num = tonumber(delayBox.Text)
        if num and num >= 0.1 and num <= 2 then
            autoDelay[selectedType] = num
        else
            delayBox.Text = tostring(autoDelay[selectedType])
            Notify("Invalid delay, using " .. autoDelay[selectedType] .. "s", "error", 2)
        end
        SaveAutoBuyState({selectedPerType = selectedPerType, autoStatePerType = autoStatePerType, autoDelay = autoDelay})
    end)

    -- Keyboard shortcuts
    local keyConn = Connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then return end
        if searchBox:IsFocused() and input.KeyCode == Enum.KeyCode.Return then
            updateDropdownItems()
        elseif input.KeyCode == Enum.KeyCode.A and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            HapticClick()
            -- Trigger select all
            local options = selectedType == "Plant" and PlantOptions or GearOptions
            selectedPerType[selectedType] = {}
            for _, v in ipairs(options) do
                table.insert(selectedPerType[selectedType], v)
            end
            updateDropdownItems()
            Notify("All "..selectedType.." selected","success",1.5)
            updateStatusLabel()
            SaveAutoBuyState({selectedPerType = selectedPerType, autoStatePerType = autoStatePerType, autoDelay = autoDelay})
        end
    end)

    -- Clear & Select all
    Connect(clearBtn.MouseButton1Click, function()
        HapticClick()
        selectedPerType[selectedType] = {}
        updateDropdownItems()
        Notify("Selection cleared for "..selectedType,"info",1.5)
        updateStatusLabel()
        SaveAutoBuyState({selectedPerType = selectedPerType, autoStatePerType = autoStatePerType, autoDelay = autoDelay})
    end)
    Connect(selectAllBtn.MouseButton1Click, function()
        HapticClick()
        local options = selectedType == "Plant" and PlantOptions or GearOptions
        selectedPerType[selectedType] = {}
        for _, v in ipairs(options) do
            table.insert(selectedPerType[selectedType], v)
        end
        updateDropdownItems()
        Notify("All "..selectedType.." selected","success",1.5)
        updateStatusLabel()
        SaveAutoBuyState({selectedPerType = selectedPerType, autoStatePerType = autoStatePerType, autoDelay = autoDelay})
    end)
    Connect(selectBothBtn.MouseButton1Click, function()
        HapticClick()
        selectedPerType.Plant = {}
        selectedPerType.Gear = {}
        for _, v in ipairs(PlantOptions) do
            table.insert(selectedPerType.Plant, v)
        end
        for _, v in ipairs(GearOptions) do
            table.insert(selectedPerType.Gear, v)
        end
        updateDropdownItems()
        Notify("All Plants & Gears selected","success",1.5)
        updateStatusLabel()
        SaveAutoBuyState({selectedPerType = selectedPerType, autoStatePerType = autoStatePerType, autoDelay = autoDelay})
    end)
    Connect(clearAllBtn.MouseButton1Click, function()
        HapticClick()
        selectedPerType.Plant = {}
        selectedPerType.Gear = {}
        updateDropdownItems()
        Notify("All selections cleared","error",1.5)
        updateStatusLabel()
        SaveAutoBuyState({selectedPerType = selectedPerType, autoStatePerType = autoStatePerType, autoDelay = autoDelay})
    end)

    -- Optimized toggle with debounce for single
    local toggleDebounce
    Connect(autoBtn.MouseButton1Click, function()
        HapticClick()
        if toggleDebounce then return end
        toggleDebounce = task.delay(0.1, function() toggleDebounce = nil end)
        
        local typ = selectedType
        autoStatePerType[typ] = not autoStatePerType[typ]
        if autoStatePerType[typ] then
            if not runningLoops[typ] then
                runningLoops[typ] = true
                task.spawn(function() autoLoop(typ) end)
            end
            Notify("AutoBuy started for "..typ,"success",2)
        else
            Notify("AutoBuy stopped for "..typ,"error",2)
        end
        updateAutoBtn()
        updateBothAutoBtn()
        SaveAutoBuyState({selectedPerType = selectedPerType, autoStatePerType = autoStatePerType, autoDelay = autoDelay})
    end)

    -- Toggle for both with debounce
    local bothToggleDebounce
    Connect(bothAutoBtn.MouseButton1Click, function()
        HapticClick()
        if bothToggleDebounce then return end
        bothToggleDebounce = task.delay(0.1, function() bothToggleDebounce = nil end)
        
        local plantOn = autoStatePerType.Plant
        local gearOn = autoStatePerType.Gear
        local newState
        if plantOn == gearOn then
            newState = not plantOn
        else
            newState = true
        end
        
        autoStatePerType.Plant = newState
        autoStatePerType.Gear = newState
        
        if newState then
            for _, typ in ipairs({"Plant", "Gear"}) do
                if not runningLoops[typ] then
                    runningLoops[typ] = true
                    task.spawn(function() autoLoop(typ) end)
                end
            end
            Notify("AutoBuy started for both","success",2)
        else
            Notify("AutoBuy stopped for both","error",2)
        end
        updateAutoBtn()
        updateBothAutoBtn()
        SaveAutoBuyState({selectedPerType = selectedPerType, autoStatePerType = autoStatePerType, autoDelay = autoDelay})
    end)

    -- Type switching with debounce and clear search
    local switchDebounce
    Connect(plantBtn.MouseButton1Click, function()
        HapticClick()
        if switchDebounce then return end
        switchDebounce = task.delay(0.1, function() switchDebounce = nil end)
        if selectedType ~= "Plant" then
            selectedType = "Plant"
            searchBox.Text = ""
            delayBox.Text = tostring(autoDelay[selectedType])
            updateDropdownItems()
            updateAutoBtn()
            updateBothAutoBtn()
            Notify("Switched to Plants","info",1.5)
        end
    end)
    Connect(gearBtn.MouseButton1Click, function()
        HapticClick()
        if switchDebounce then return end
        switchDebounce = task.delay(0.1, function() switchDebounce = nil end)
        if selectedType ~= "Gear" then
            selectedType = "Gear"
            searchBox.Text = ""
            delayBox.Text = tostring(autoDelay[selectedType])
            updateDropdownItems()
            updateAutoBtn()
            updateBothAutoBtn()
            Notify("Switched to Gears","info",1.5)
        end
    end)

    -- Responsive update function
    local viewportConnection
    local function updateAutoBuySizes()
        local screenSize = workspace.CurrentCamera.ViewportSize
        local refWidth, refHeight
        if isMobile then
            if screenSize.X < screenSize.Y then
                refWidth = 375
                refHeight = 812
            else
                refWidth = 812
                refHeight = 375
            end
        else
            refWidth = 1920
            refHeight = 1080
        end
        local scaleX = screenSize.X / refWidth
        local scaleY = screenSize.Y / refHeight
        local newScale = math.min(scaleX, scaleY)
        currentScale = newScale

        local minText = isMobile and 16 or 12
        local textMultiplier = currentScale
        regularTextSize = math.clamp(14 * textMultiplier, minText, 18)
        boldTextSize = math.clamp(16 * textMultiplier, minText + 2, 20)
        smallTextSize = math.clamp(12 * textMultiplier, minText - 2, 16)

        local minPad = isMobile and 12 or 8
        local pad = math.max(10 * currentScale, minPad)
        local mpad = math.max(20 * currentScale, minPad * 2)
        local gap = math.max(8 * currentScale, isMobile and 12 or 6)
        local smallGap = gap / 2
        local typeGapScale = 0.01 * currentScale
        local actionGapScale = 0.02 * currentScale

        local yOffset = 0

        -- Title
        local titleH = math.max(30 * currentScale, isMobile and 40 or 30)
        titleLabel.Position = UDim2.new(0, pad, 0, yOffset + pad)
        titleLabel.Size = UDim2.new(1, -mpad, 0, titleH)
        titleLabel.TextSize = boldTextSize
        yOffset = yOffset + titleH + gap

        -- Type selector
        local typeH = math.max(30 * currentScale, isMobile and 44 or 30)
        local typeBtnScale = (1 - typeGapScale) / 2
        typeSelector.Position = UDim2.new(0, pad, 0, yOffset)
        typeSelector.Size = UDim2.new(1, -mpad, 0, typeH)
        plantBtn.Size = UDim2.new(typeBtnScale, 0, 1, 0)
        plantBtn.TextSize = regularTextSize
        gearBtn.Size = UDim2.new(typeBtnScale, 0, 1, 0)
        gearBtn.Position = UDim2.new(typeBtnScale + typeGapScale, 0, 0, 0)
        gearBtn.TextSize = regularTextSize
        yOffset = yOffset + typeH + gap

        -- Search
        local inputH = math.max(28 * currentScale, isMobile and 44 or 28)
        searchBox.Position = UDim2.new(0, pad, 0, yOffset)
        searchBox.Size = UDim2.new(1, -mpad, 0, inputH)
        searchBox.TextSize = regularTextSize
        yOffset = yOffset + inputH + smallGap

        -- Delay
        delayBox.Position = UDim2.new(0, pad, 0, yOffset)
        delayBox.Size = UDim2.new(1, -mpad, 0, inputH)
        delayBox.TextSize = regularTextSize
        yOffset = yOffset + inputH + gap

        -- Btn container
        local actionH = math.max(28 * currentScale, isMobile and 44 or 28)
        btnContainer.Position = UDim2.new(0, pad, 0, yOffset)
        if isMobile then
            local actionLayout = btnContainer:FindFirstChild("ActionLayout")
            if not actionLayout then
                actionLayout = New("UIListLayout", {
                    Name = "ActionLayout",
                    Parent = btnContainer,
                    Padding = UDim.new(0, smallGap),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    FillDirection = Enum.FillDirection.Vertical,
                })
            end
            actionLayout.Padding = UDim.new(0, smallGap)
            btnContainer.AutomaticSize = Enum.AutomaticSize.Y
            btnContainer.Size = UDim2.new(1, -mpad, 0, 0)
            clearBtn.Position = UDim2.new(0, 0, 0, 0)
            clearBtn.Size = UDim2.new(1, 0, 0, 0)
            clearBtn.AutomaticSize = Enum.AutomaticSize.Y
            clearBtn.TextSize = regularTextSize
            selectAllBtn.Position = UDim2.new(0, 0, 0, 0)
            selectAllBtn.Size = UDim2.new(1, 0, 0, 0)
            selectAllBtn.AutomaticSize = Enum.AutomaticSize.Y
            selectAllBtn.TextSize = regularTextSize
            selectBothBtn.Position = UDim2.new(0, 0, 0, 0)
            selectBothBtn.Size = UDim2.new(1, 0, 0, 0)
            selectBothBtn.AutomaticSize = Enum.AutomaticSize.Y
            selectBothBtn.TextSize = regularTextSize
            clearAllBtn.Position = UDim2.new(0, 0, 0, 0)
            clearAllBtn.Size = UDim2.new(1, 0, 0, 0)
            clearAllBtn.AutomaticSize = Enum.AutomaticSize.Y
            clearAllBtn.TextSize = regularTextSize
            local stackedActionH = actionH * 4 + smallGap * 3
            yOffset = yOffset + stackedActionH + gap
        else
            if btnContainer:FindFirstChild("ActionLayout") then
                btnContainer.ActionLayout:Destroy()
            end
            btnContainer.AutomaticSize = Enum.AutomaticSize.None
            btnContainer.Size = UDim2.new(1, -mpad, 0, actionH)
            local actionBtnScale = (1 - 3 * actionGapScale) / 4
            clearBtn.Position = UDim2.new(0, 0, 0, 0)
            clearBtn.Size = UDim2.new(actionBtnScale, 0, 1, 0)
            clearBtn.TextSize = regularTextSize
            selectAllBtn.Position = UDim2.new(actionBtnScale + actionGapScale, 0, 0, 0)
            selectAllBtn.Size = UDim2.new(actionBtnScale, 0, 1, 0)
            selectAllBtn.TextSize = regularTextSize
            selectBothBtn.Position = UDim2.new(2 * (actionBtnScale + actionGapScale), 0, 0, 0)
            selectBothBtn.Size = UDim2.new(actionBtnScale, 0, 1, 0)
            selectBothBtn.TextSize = regularTextSize
            clearAllBtn.Position = UDim2.new(3 * (actionBtnScale + actionGapScale), 0, 0, 0)
            clearAllBtn.Size = UDim2.new(actionBtnScale, 0, 1, 0)
            clearAllBtn.TextSize = regularTextSize
            yOffset = yOffset + actionH + gap
        end

        -- Dropdown
        local listH = math.max(150 * currentScale, isMobile and 250 or 150)
        dropdownList.Position = UDim2.new(0, pad, 0, yOffset)
        dropdownList.Size = UDim2.new(1, -mpad, 0, listH)
        listLayout.Padding = UDim.new(0, math.max(4 * currentScale, isMobile and 8 or 4))
        dropdownList.ScrollBarThickness = isMobile and math.max(20 * currentScale, 20) or math.max(6 * currentScale, 6)
        local listBtnH = math.max(32 * currentScale, isMobile and 48 or 32)
        hoverInProps.Size = UDim2.new(1, -4 * currentScale, 0, listBtnH + 2 * currentScale)
        hoverOutProps.Size = UDim2.new(1, -4 * currentScale, 0, listBtnH)
        clickInProps.Size = UDim2.new(1, -4 * currentScale, 0, listBtnH - 4 * currentScale)
        clickOutProps.Size = UDim2.new(1, -4 * currentScale, 0, listBtnH)
        for _, child in ipairs(dropdownList:GetChildren()) do
            if child:IsA("TextButton") then
                child.Size = UDim2.new(1, -4 * currentScale, 0, listBtnH)
                child.TextSize = regularTextSize
            end
        end
        yOffset = yOffset + listH + gap

        -- Auto btn
        local toggleH = math.max(36 * currentScale, isMobile and 50 or 36)
        autoBtn.Position = UDim2.new(0, pad, 0, yOffset)
        autoBtn.Size = UDim2.new(1, -mpad, 0, toggleH)
        autoBtn.TextSize = boldTextSize
        yOffset = yOffset + toggleH + smallGap

        -- Both btn
        bothAutoBtn.Position = UDim2.new(0, pad, 0, yOffset)
        bothAutoBtn.Size = UDim2.new(1, -mpad, 0, toggleH)
        bothAutoBtn.TextSize = boldTextSize
        yOffset = yOffset + toggleH + gap

        -- Status label
        local statusH = math.max(24 * currentScale, isMobile and 28 or 20)
        statusLabel.Position = UDim2.new(0, pad, 0, yOffset)
        statusLabel.Size = UDim2.new(1, -mpad, 0, statusH)
        statusLabel.TextSize = smallTextSize

        -- Recalculate dropdown canvas after resize
        updateDropdownItems()
    end

    viewportConnection = Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateAutoBuySizes)

    -- Initial update
    updateAutoBuySizes()
    updateDropdownItems()
    updateAutoBtn()
    updateBothAutoBtn()
    updateStatusLabel()

    -- Cleanup on destroy + save
    local cleanupConn
    cleanupConn = frame.AncestryChanged:Connect(function()
        if not frame.Parent then
            -- Stop all loops on destroy
            for typ, _ in pairs(autoStatePerType) do
                autoStatePerType[typ] = false
            end
            for btn, conns in pairs(buttonConnections) do
                for _, conn in ipairs(conns) do 
                    if conn and conn.Disconnect then 
                        conn:Disconnect() 
                    end
                end
            end
            buttonConnections = {}
            if keyConn then keyConn:Disconnect() end
            if viewportConnection then viewportConnection:Disconnect() end
            if cleanupConn then cleanupConn:Disconnect() end
            -- Final save
            SaveAutoBuyState({selectedPerType = selectedPerType, autoStatePerType = autoStatePerType, autoDelay = autoDelay})
        end
    end)
end)

-- Initial scroll updates
UpdateScrollBar(leftScroll)
UpdateScrollBar(contentScroll)
