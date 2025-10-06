local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local HapticService = game:GetService("HapticService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isMobile = UserInputService.TouchEnabled
local lowEndMode = isMobile  -- Proxy for low-end devices (mobile often lower perf)

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
        if typeof(props)=="Instance" then 
            pcall(function() obj.Parent=props end)
        elseif type(props)=="table" then
            for k,v in pairs(props) do
                pcall(function() obj[k]=v end)
            end
        else 
            warn(("New(): props must be table/Instance, got %s"):format(typeof(props)))
        end
    end
    return obj
end

local function PlayTween(obj, info, props)
    if not obj or lowEndMode then  -- Instant change on low-end
        for k,v in pairs(props) do 
            pcall(function() obj[k] = v end)
        end
        return { Play = function() end }  -- Dummy
    end
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

    local mainWidth = math.clamp(isMobile and 0.75 or 0.55, 0.4, 0.8)  -- Clamp para small screens
    local mainHeight = math.clamp(isMobile and 0.55 or 0.6, 0.3, 0.7)

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
        Size = savedSize and UDim2.fromOffset(savedSize.X, savedSize.Y) or UDim2.new(mainWidth,0,mainHeight,0),  -- Scale-based
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
        Name="Body",
        ClipsDescendants = true  -- Add clipping
    })

    local leftPanel = New("Frame",{Parent=body,Size=UDim2.new(0.25,0,1,0),BackgroundColor3=Theme.Colors.PanelAlt,BorderSizePixel=0, ClipsDescendants = true})
    local rightPanel = New("Frame",{Parent=body,Position=UDim2.new(0.25,0,0,0),Size=UDim2.new(0.75,0,1,0),BackgroundColor3=Theme.Colors.Panel,BorderSizePixel=0, ClipsDescendants = true})

    -- Scrolls
    local leftScroll = New("ScrollingFrame",{
        Parent=leftPanel,
        Size=UDim2.new(1,0,1,-16),
        Position=UDim2.new(0,0,0,8),
        ScrollBarThickness=isMobile and 16 or 6,
        ScrollBarImageTransparency=1,  -- Hide scroll bar by default
        BackgroundTransparency=1
    })
    New("UIListLayout",{Parent=leftScroll,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,Theme.Padding)})

    local padding = Theme.Padding
    local contentScroll = New("ScrollingFrame",{
        Parent=rightPanel,
        Size=UDim2.new(1, -2*padding,1, -2*padding),
        Position=UDim2.new(0, padding,0, padding),
        ScrollBarThickness=isMobile and 16 or 8,
        ScrollBarImageTransparency=1,  -- Hide scroll bar by default
        BackgroundTransparency=1,
        ClipsDescendants = true  -- Add clipping
    })
    New("UIListLayout",{Parent=contentScroll,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)})  -- Removed padding to avoid extra space

    -- Swipe for tabs setup
    local lastTouchPos
    contentScroll.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            lastTouchPos = input.Position
        end
    end)
    contentScroll.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and lastTouchPos then
            local deltaX = input.Position.X - lastTouchPos.X
            if math.abs(deltaX) > 50 then  -- Swipe threshold
                -- Find next/prev tab
                local tabOrder = {}  -- Will be populated in AddTab
                -- Assuming tabOrder is global now, logic here
                local currentIndex = 0
                for i, tabName in ipairs(tabOrder) do
                    if tabName == currentTab then currentIndex = i break end
                end
                local direction = deltaX > 0 and -1 or 1  -- Right swipe prev, left next
                local nextIndex = ((currentIndex + direction - 1) % #tabOrder) + 1
                local nextTab = tabOrder[nextIndex]
                if nextTab then SwitchTab(nextTab) end
            end
            lastTouchPos = nil
        end
    end)

    -- Notifications - Top-right on mobile, bottom-right on desktop
    local notifHolder = New("Frame",{
        Parent=screenGui,
        AnchorPoint=isMobile and Vector2.new(1,0) or Vector2.new(1,1),
        Size=isMobile and UDim2.new(0,250,0,150) or UDim2.new(0,280,0,200),
        Position=isMobile and UDim2.new(1,0,0,0) or UDim2.new(1,-12,1,-12),
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
local tabOrder = {}  -- For swipe ordering

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
        local height = isMobile and 44 or 32  -- Min 44px for touch targets
        local widthOffset = 0
        btn.Size = UDim2.new(1, widthOffset, 0, height * scaleFactor)
        btn.TextSize = Theme.TextSize
    end
end

-- Apply to existing tab buttons
for _,btn in pairs(tabButtons) do
    UpdateButtonSize(btn)
end

-- Throttled scroll update
local scrollDebounce = {}
local function UpdateScrollBar(scrollFrame)
    local id = tostring(scrollFrame)
    local now = tick()
    if scrollDebounce[id] and now - scrollDebounce[id] < 0.1 then return end  -- 10Hz max
    scrollDebounce[id] = now

    local listLayout = scrollFrame:FindFirstChildOfClass("UIListLayout")
    if not listLayout then return end

    local contentHeight = listLayout.AbsoluteContentSize.Y
    local frameHeight = scrollFrame.AbsoluteSize.Y

    -- Set CanvasSize to match content height exactly, avoiding extra space
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(contentHeight, frameHeight))  -- Ensure canvas doesn't shrink below frame height

    -- Hide scroll bar if content fits or is smaller than frame, show only if it exceeds
    scrollFrame.ScrollBarImageTransparency = contentHeight <= frameHeight and 1 or 0
end

-- Function to update all elements dynamically on scale change
local function UpdateScale()
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
                listLayout.Padding = UDim.new(0, 0)  -- No padding for content to avoid extra space
            else
                listLayout.Padding = UDim.new(0, Theme.Padding)  -- Keep padding for leftScroll
            end
        end
        for _, child in pairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextSize = Theme.TextSize
                local h = isMobile and 44 or 32
                local widthOffset = 0
                child.Size = UDim2.new(1, widthOffset, 0, h * scaleFactor)
            elseif child:IsA("TextLabel") then
                child.TextSize = Theme.TextSize
                local labelHeight = math.clamp(30 * scaleFactor, 24, 40)
                child.Size = UDim2.new(1, 0, 0, labelHeight)
            end
        end
        UpdateScrollBar(scroll)  -- Update scroll bar visibility
    end

    -- Update notif holder padding
    local notifLayout = notifHolder:FindFirstChildOfClass("UIListLayout")
    if notifLayout then notifLayout.Padding = UDim.new(0, Theme.Padding) end
end

-- Listen for viewport changes
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)

-- Orientation proxy (additional listener)
UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(UpdateScale)

-- Notify function for scaled notifications with rate-limit
local activeNotifs = {}
local lastNotifyTime = 0
local notifyCooldown = 0.5  -- 500ms min between notifies
Notify = function(text, nType, duration)
    local now = tick()
    if now - lastNotifyTime < notifyCooldown then return end  -- Rate limit
    lastNotifyTime = now

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
    New("UIStroke", { Parent = notif, Color = Theme.Colors.Shadow, Thickness = lowEndMode and 0.5 or 1, Transparency = 0.6 })
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

-- Apply scale to left/right scroll content
for _, scroll in pairs({leftScroll, contentScroll}) do
    for _, child in pairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then
            local h = isMobile and 44 or 32
            local widthOffset = 0
            child.Size = UDim2.new(1, widthOffset, 0, h * scaleFactor)
            child.TextSize = Theme.TextSize
        elseif child:IsA("TextLabel") then
            local labelHeight = math.clamp(30 * scaleFactor, 24, 40)
            child.Size = UDim2.new(1, 0, 0, labelHeight)
            child.TextSize = Theme.TextSize
        end
    end
    UpdateScrollBar(scroll)  -- Initial scroll bar update
end

-- Connections tracker
local connections = {}
local function Connect(sig, func) local c = sig:Connect(func) table.insert(connections, c) return c end
local function CleanupConnections() for _, c in ipairs(connections) do if c and c.Disconnect then c:Disconnect() end end connections = {} end

local needsSave = false  -- Batch save flag

-- Dragging with debounce and batch save
do
    local dragging, dragStart, startPos, dragInput
    local dragChangedConn
    local lastUpdate = 0
    local debounceTime = 1/60  -- 60FPS cap
    local function update(input)
        local now = tick()
        if now - lastUpdate < debounceTime then return end
        lastUpdate = now
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        needsSave = true  -- Flag for batch save
    end
    Connect(titleBar.InputBegan, function(input)  -- Note: UI.titleBar -> titleBar
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            if dragChangedConn then dragChangedConn:Disconnect() end
            dragChangedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                    if needsSave then
                        SaveState({ Position = { X = main.AbsolutePosition.X, Y = main.AbsolutePosition.Y }, Size = { X = main.AbsoluteSize.X, Y = main.AbsoluteSize.Y }, Minimized = isMinimized, Collapsed = isCollapsed })
                        needsSave = false
                    end
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

-- Haptic feedback for mobile button clicks (checked once globally)
local supportsHaptic = HapticService:IsVibrationSupported(Enum.UserInputType.Touch) and HapticService:IsMotorSupported(Enum.UserInputType.Touch, Enum.VibrationMotor.Small)
local function HapticClick()
    if isMobile and supportsHaptic and not lowEndMode then  -- Skip on low-end
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
    CleanupConnections()  -- Disconnect all
    UI.screenGui:Destroy()  -- Full cleanup
end)

-- Hotkey toggle
Connect(UserInputService.InputBegan, function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        UI.main.Visible = not UI.main.Visible
    end
end)

-- Resize handle with debounce and batch save
local resizeHandle
do
    local resizing = false
    local startSize, startMouse
    local lastResizeUpdate = 0
    local resizeDebounceTime = 1/60
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
    resizeHandle.MouseEnter:Connect(function() hoverTween:Play() end)
    resizeHandle.MouseLeave:Connect(function() if not resizing then leaveTween:Play() end end)

    local screenSize = workspace.CurrentCamera.ViewportSize
    local minWidth = math.max(200, screenSize.X * 0.3)  -- Scale-based min
    local minHeight = math.max(150, screenSize.Y * 0.2)
    local maxWidth = screenSize.X * 0.9
    local maxHeight = screenSize.Y * 0.9

    Connect(resizeHandle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startMouse = input.Position
            startSize = main.Size
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    leaveTween:Play()
                    if needsSave then
                        SaveState({ Position = { X = main.AbsolutePosition.X, Y = main.AbsolutePosition.Y }, Size = { X = main.AbsoluteSize.X, Y = main.AbsoluteSize.Y }, Minimized = isMinimized, Collapsed = isCollapsed })
                        needsSave = false
                    end
                    UpdateScrollBar(leftScroll)  -- Update scroll bars on resize
                    UpdateScrollBar(contentScroll)
                end
            end)
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local now = tick()
            if now - lastResizeUpdate < resizeDebounceTime then return end
            lastResizeUpdate = now
            local delta = input.Position - startMouse
            local newWidth = math.clamp(startSize.X.Offset + delta.X, minWidth, maxWidth)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, minHeight, maxHeight)
            main.Size = UDim2.new(0, newWidth, 0, newHeight)
            needsSave = true
            UpdateScrollBar(leftScroll)  -- Update scroll bars during resize
            UpdateScrollBar(contentScroll)
        end
    end)
end

-- Tabs system
local function SwitchTab(name)
    if currentTab == name then return end
    for tName, frame in pairs(tabFrames) do if frame and frame.Parent then frame.Visible = false end end
    for tName, btn in pairs(tabButtons) do if btn and btn.Parent then btn.BackgroundColor3 = Theme.Colors.Button end end
    if tabFrames[name] then
        tabFrames[name].Visible = true
        tabFrames[name].Position = UDim2.new(1, 0, 0, 0)
        PlayTween(tabFrames[name], tweenFast, { Position = UDim2.new(0, 0, 0, 0) })
    end
    if tabButtons[name] then tabButtons[name].BackgroundColor3 = Theme.Colors.ButtonActive end
    currentTab = name
    Notify("Switched to " .. name, "info", 2)
end

local function AddTab(name, callback)
    tabs[name] = callback
    table.insert(tabOrder, name)  -- For swipe order
    local height = isMobile and 44 or 32  -- Larger touch target
    local btn = New("TextButton", {
        Parent = leftScroll,
        Text = name,
        Font = Theme.Font,
        TextSize = isMobile and 18 or Theme.TextSize,
        TextColor3 = Theme.Colors.Text,
        BackgroundColor3 = Theme.Colors.Button,
        Size = UDim2.new(1, 0, 0, height),
        BorderSizePixel = 0
    })
    New("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 6) })
    tabButtons[name] = btn

    Connect(btn.MouseButton1Click, function()
        HapticClick()
        if not tabFrames[name] then
            local frame = New("Frame", {
                Parent = contentScroll,
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = true,
                ClipsDescendants = true
            })
            tabFrames[name] = frame
            callback(frame)
            -- Throttle update via AbsoluteContentSize
            local listLayout = contentScroll:FindFirstChildOfClass("UIListLayout")
            if listLayout then
                listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    UpdateScrollBar(contentScroll)
                end)
            end
        end
        SwitchTab(name)
    end)

    UpdateScrollBar(leftScroll)  -- Update left scroll bar after adding tab button

    if not currentTab then
        if not tabFrames[name] then
            local frame = New("Frame", {
                Parent = contentScroll,
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = true,
                ClipsDescendants = true
            })
            tabFrames[name] = frame
            callback(frame)
            local listLayout = contentScroll:FindFirstChildOfClass("UIListLayout")
            if listLayout then
                listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    UpdateScrollBar(contentScroll)
                end)
            end
        end
        SwitchTab(name)
    end
    return btn
end

-- Floating Toggle Button (Draggable + Auto-Clamp with Tween)
do
    local savedTogglePos = LoadTogglePos()
    -- On mobile, make toggle button slightly smaller for tiny screens
    local toggleSize = isMobile and 60 or 60  -- Reduced from 80 to 60 on mobile
    local toggleBtn = New("TextButton", {
        Parent = UI.screenGui,
        Text = "TCS",
        Size = UDim2.new(0, toggleSize, 0, toggleSize),
        BackgroundColor3 = Theme.Colors.Button,
        TextColor3 = Theme.Colors.Text,
        BorderSizePixel = 0,
        ZIndex = 50
    })
    New("UICorner", { Parent = toggleBtn, CornerRadius = UDim.new(0, 12) })

    toggleBtn.Position = savedTogglePos and UDim2.fromOffset(savedTogglePos.X, savedTogglePos.Y) or UDim2.new(1, - (toggleSize + 12), 0, 12)
    toggleBtn.AnchorPoint = Vector2.new(0, 0)

    Connect(toggleBtn.MouseButton1Click, function()
        HapticClick()
        main.Visible = not main.Visible
    end)

    -- Dragging with debounce
    local dragging = false
    local dragStart, startPos
    local toggleLastUpdate = 0
    local toggleDebounceTime = 1/60

    toggleBtn.InputBegan:Connect(function(input)
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

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local now = tick()
            if now - toggleLastUpdate < toggleDebounceTime then return end
            toggleLastUpdate = now
            local delta = input.Position - dragStart
            local newX = math.clamp(startPos.X.Offset + delta.X, 0, workspace.CurrentCamera.ViewportSize.X - toggleBtn.AbsoluteSize.X)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, workspace.CurrentCamera.ViewportSize.Y - toggleBtn.AbsoluteSize.Y)
            toggleBtn.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    -- Auto-clamp on screen resize with smooth tween
    local function ClampPosition()
        local pos = toggleBtn.Position
        local absSize = toggleBtn.AbsoluteSize
        local clampedX = math.clamp(pos.X.Offset, 0, workspace.CurrentCamera.ViewportSize.X - absSize.X)
        local clampedY = math.clamp(pos.Y.Offset, 0, workspace.CurrentCamera.ViewportSize.Y - absSize.Y)

        if clampedX ~= pos.X.Offset or clampedY ~= pos.Y.Offset then
            local tween = TweenService:Create(toggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, clampedX, 0, clampedY)
            })
            tween:Play()
        end

        SaveTogglePos({ X = clampedX, Y = clampedY })
    end

    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ClampPosition)

    -- Always show toggle button, but hide when main is visible on mobile
    if isMobile then
        local function UpdateToggleVis()
            toggleBtn.Visible = not main.Visible
        end
        UpdateToggleVis()
        main:GetPropertyChangedSignal("Visible"):Connect(UpdateToggleVis)
    end
end

-- Initial Notification
Notify("Created By TCS_Dev [FuncMode]", "info")

-- Example usage to test tab content and buttons
AddTab("Tab 1", function(frame)
    for i = 1, 3 do  -- Adjust number to test fitting
        New("TextLabel", {
            Parent = frame,
            Text = "Item " .. i,
            Size = UDim2.new(1, 0, 0, 30 * scaleFactor),
            BackgroundTransparency = 1,
            TextColor3 = Theme.Colors.Text,
            TextSize = Theme.TextSize,
            Font = Theme.Font
        })
    end
end)
AddTab("Tab 2", function(frame)
    for i = 1, 3 do  -- Adjust number to test fitting
        New("TextLabel", {
            Parent = frame,
            Text = "Item " .. i,
            Size = UDim2.new(1, 0, 0, 30 * scaleFactor),
            BackgroundTransparency = 1,
            TextColor3 = Theme.Colors.Text,
            TextSize = Theme.TextSize,
            Font = Theme.Font
        })
    end
end)
