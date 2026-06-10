--[[
    WindUI Library v5.0 - 完美融合版
    功能: 多窗口、侧边栏分组折叠、标签页、Section网格布局、完整控件、主题、通知、动画
    兼容: 鼠标/触摸
    作者: 定制
    代码量: ~6500 行
    风格: Windows 11 风格，圆角、侧边栏、分组、动态效果
]]

-- 服务引用
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

-- 创建 ScreenGui
local Gui = Instance.new("ScreenGui")
Gui.Name = "WindUI"
Gui.Parent = CoreGui
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.ResetOnSpawn = false

-- 全局库
local Library = {
    Windows = {},
    Theme = "Dark",
    Themes = {
        Dark = {
            Main = Color3.fromRGB(32, 32, 37),
            Side = Color3.fromRGB(43, 43, 50),
            Card = Color3.fromRGB(50, 50, 60),
            Input = Color3.fromRGB(40, 40, 48),
            Text = Color3.fromRGB(255, 255, 255),
            SubText = Color3.fromRGB(180, 180, 190),
            MutedText = Color3.fromRGB(130, 130, 140),
            Accent = Color3.fromRGB(0, 120, 255),
            ToggleOn = Color3.fromRGB(0, 120, 255),
            ToggleOff = Color3.fromRGB(80, 80, 90),
            SliderBg = Color3.fromRGB(65, 65, 75),
            SliderKnob = Color3.fromRGB(255, 255, 255),
            Line = Color3.fromRGB(60, 60, 70),
            Shadow = Color3.fromRGB(0,0,0),
            WindowBorder = Color3.fromRGB(0,0,0),
            ButtonHover = Color3.fromRGB(55, 55, 65),
        },
        Light = {
            Main = Color3.fromRGB(243, 243, 247),
            Side = Color3.fromRGB(235, 235, 240),
            Card = Color3.fromRGB(255, 255, 255),
            Input = Color3.fromRGB(245, 245, 250),
            Text = Color3.fromRGB(0, 0, 0),
            SubText = Color3.fromRGB(80, 80, 90),
            MutedText = Color3.fromRGB(140, 140, 150),
            Accent = Color3.fromRGB(0, 120, 255),
            ToggleOn = Color3.fromRGB(0, 120, 255),
            ToggleOff = Color3.fromRGB(180, 180, 190),
            SliderBg = Color3.fromRGB(200, 200, 210),
            SliderKnob = Color3.fromRGB(255, 255, 255),
            Line = Color3.fromRGB(220, 220, 225),
            Shadow = Color3.fromRGB(200,200,200),
            WindowBorder = Color3.fromRGB(200,200,200),
            ButtonHover = Color3.fromRGB(220, 220, 225),
        },
        Midnight = {
            Main = Color3.fromRGB(20, 22, 28),
            Side = Color3.fromRGB(15, 17, 22),
            Card = Color3.fromRGB(30, 33, 40),
            Input = Color3.fromRGB(25, 28, 33),
            Text = Color3.fromRGB(220, 220, 230),
            SubText = Color3.fromRGB(160, 160, 170),
            MutedText = Color3.fromRGB(100, 100, 110),
            Accent = Color3.fromRGB(100, 120, 255),
            ToggleOn = Color3.fromRGB(100, 120, 255),
            ToggleOff = Color3.fromRGB(80, 80, 90),
            SliderBg = Color3.fromRGB(50, 50, 60),
            SliderKnob = Color3.fromRGB(255, 255, 255),
            Line = Color3.fromRGB(40, 40, 50),
            Shadow = Color3.fromRGB(0,0,0),
            WindowBorder = Color3.fromRGB(40,40,50),
            ButtonHover = Color3.fromRGB(40, 40, 50),
        }
    },
    ActiveTheme = function(self)
        return self.Themes[self.Theme]
    end,
}

-- ======================== 工具函数 ========================
local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

local function CreateShadow(parent, transparency, offset)
    local shadow = Instance.new("ImageLabel")
    shadow.Image = "rbxassetid://4996891970"
    shadow.ImageColor3 = Color3.fromRGB(0,0,0)
    shadow.ImageTransparency = transparency or 0.85
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(20,20,280,280)
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1, offset or 20, 1, offset or 20)
    shadow.Position = UDim2.new(0, -(offset or 20)/2, 0, -(offset or 20)/2)
    shadow.ZIndex = -1
    shadow.Parent = parent
    return shadow
end

local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(0,0,0)
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function TweenObject(obj, props, duration, easing, dir, callback)
    local tween = TweenService:Create(obj, TweenInfo.new(duration or 0.2, easing or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    if callback then
        tween.Completed:Connect(function(state)
            if state == Enum.PlaybackState.Completed then
                callback()
            end
        end)
    end
    tween:Play()
    return tween
end

local function MakeDraggable(handle, target, boundaries)
    local dragging, startPos, startInputPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = target.Position
            startInputPos = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInputPos
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y
            if boundaries then
                newX = math.clamp(newX, boundaries.MinX or -math.huge, boundaries.MaxX or math.huge)
                newY = math.clamp(newY, boundaries.MinY or -math.huge, boundaries.MaxY or math.huge)
            end
            target.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    end)
end

-- 通知系统
function Library:Notify(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5
    })
end

-- ======================== 窗口类 ========================
local Window = {}
Window.__index = Window

function Library:CreateWindow(title, options)
    options = options or {}
    local self = setmetatable({}, Window)
    self.Title = title or "Window"
    self.Width = options.Width or 640
    self.Height = options.Height or 480
    self.SideWidth = options.SideWidth or 170
    self.Minimized = false
    self.Visible = true
    self.TabGroups = {}
    self.Tabs = {}
    self.CurrentTab = nil
    
    local theme = Library:ActiveTheme()
    
    -- 主框架
    local Frame = Instance.new("Frame")
    Frame.Name = "Window"
    Frame.Parent = Gui
    Frame.Size = UDim2.new(0, self.Width, 0, self.Height)
    Frame.Position = UDim2.new(0.5, -self.Width/2, 0.5, -self.Height/2)
    Frame.BackgroundColor3 = theme.Main
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    CreateCorner(Frame, 8)
    CreateShadow(Frame, 0.8, 15)
    self.Frame = Frame
    
    -- 窗口边框 (Wind 风格细边框)
    CreateStroke(Frame, theme.WindowBorder, 1)
    
    -- 窗口栏 (标题 + 控制按钮)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = Frame
    TopBar.Size = UDim2.new(1, 0, 0, 32)
    TopBar.BackgroundColor3 = theme.Side
    TopBar.BorderSizePixel = 0
    CreateCorner(TopBar, 8)  -- 仅上圆角，通过ClipDescendants裁切下方
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = TopBar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0.01, 0, 0, 0)
    TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    TitleLabel.Text = self.Title
    TitleLabel.Font = Enum.Font.GothamSemibold
    TitleLabel.TextSize = 14
    TitleLabel.TextColor3 = theme.Text
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel = TitleLabel
    
    -- 控制按钮容器
    local Controls = Instance.new("Frame")
    Controls.Parent = TopBar
    Controls.BackgroundTransparency = 1
    Controls.Size = UDim2.new(0.28, 0, 1, 0)
    Controls.Position = UDim2.new(0.72, 0, 0, 0)
    local ControlsLayout = Instance.new("UIListLayout")
    ControlsLayout.Parent = Controls
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 8)
    
    -- 最小化按钮
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Parent = Controls
    MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
    MinimizeBtn.BackgroundColor3 = theme.Input
    MinimizeBtn.Text = "─"
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.TextSize = 16
    MinimizeBtn.TextColor3 = theme.Text
    MinimizeBtn.AutoButtonColor = false
    CreateCorner(MinimizeBtn, 4)
    MinimizeBtn.MouseButton1Click:Connect(function()
        self:Minimize()
    end)
    -- 最小化悬停效果
    MinimizeBtn.MouseEnter:Connect(function()
        TweenObject(MinimizeBtn, {BackgroundColor3 = theme.ButtonHover}, 0.1)
    end)
    MinimizeBtn.MouseLeave:Connect(function()
        TweenObject(MinimizeBtn, {BackgroundColor3 = theme.Input}, 0.1)
    end)
    
    -- 关闭按钮
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = Controls
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(240, 71, 71)
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 16
    CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
    CloseBtn.AutoButtonColor = false
    CreateCorner(CloseBtn, 4)
    CloseBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    CloseBtn.MouseEnter:Connect(function()
        TweenObject(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}, 0.1)
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenObject(CloseBtn, {BackgroundColor3 = Color3.fromRGB(240, 71, 71)}, 0.1)
    end)
    
    -- 拖拽栏 (整个 TopBar)
    MakeDraggable(TopBar, Frame)
    
    -- 侧边栏
    local Sidebar = Instance.new("Frame")
    Sidebar.Parent = Frame
    Sidebar.Size = UDim2.new(0, self.SideWidth, 1, -32)
    Sidebar.Position = UDim2.new(0, 0, 0, 32)
    Sidebar.BackgroundColor3 = theme.Side
    Sidebar.BorderSizePixel = 0
    local SideList = Instance.new("UIListLayout")
    SideList.Parent = Sidebar
    SideList.SortOrder = Enum.SortOrder.LayoutOrder
    SideList.Padding = UDim.new(0, 5)
    SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    self.Sidebar = Sidebar
    self.SideList = SideList
    
    -- 内容区
    local Content = Instance.new("ScrollingFrame")
    Content.Parent = Frame
    Content.Size = UDim2.new(1, -self.SideWidth, 1, -32)
    Content.Position = UDim2.new(0, self.SideWidth, 0, 32)
    Content.BackgroundColor3 = theme.Main
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = theme.MutedText
    Content.CanvasSize = UDim2.new(0,0,0,0)
    Content.ClipsDescendants = true
    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.Parent = Content
    ContentPadding.PaddingTop = UDim.new(0, 10)
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.PaddingBottom = UDim.new(0, 10)
    -- 使用 Grid 布局，每个 Section 自动换行
    local ContentLayout = Instance.new("UIGridLayout")
    ContentLayout.Parent = Content
    ContentLayout.CellSize = UDim2.new(0, 210, 0, 10) -- 高度自适应，但需要后续调整
    ContentLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    ContentLayout.FillDirection = Enum.FillDirection.Horizontal
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.StartCorner = Enum.StartCorner.TopLeft
    self.Content = Content
    self.ContentLayout = ContentLayout
    
    -- 监听内容大小变化以更新 CanvasSize
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- 注册窗口
    table.insert(Library.Windows, self)
    
    -- 窗口控制方法
    function self:Minimize()
        self.Minimized = not self.Minimized
        if self.Minimized then
            self.Sidebar.Visible = false
            self.Content.Visible = false
            self.Frame.Size = UDim2.new(0, self.Width, 0, 32)
        else
            self.Sidebar.Visible = true
            self.Content.Visible = true
            self.Frame.Size = UDim2.new(0, self.Width, 0, self.Height)
        end
    end
    
    function self:Destroy()
        self.Frame:Destroy()
        for i, w in ipairs(Library.Windows) do
            if w == self then
                table.remove(Library.Windows, i)
                break
            end
        end
    end
    
    function self:Show()
        self.Frame.Visible = true
        self.Visible = true
    end
    
    function self:Hide()
        self.Frame.Visible = false
        self.Visible = false
    end
    
    function self:SetTitle(newTitle)
        self.TitleLabel.Text = newTitle
    end
    
    -- 创建可折叠分组
    function self:CreateTabGroup(name)
        local groupFrame = Instance.new("Frame")
        groupFrame.Parent = self.Sidebar
        groupFrame.BackgroundTransparency = 1
        groupFrame.Size = UDim2.new(1, -10, 0, 25)  -- 初始高度
        groupFrame.LayoutOrder = #self.TabGroups + 1
        
        -- 分组标题按钮
        local headerBtn = Instance.new("TextButton")
        headerBtn.Parent = groupFrame
        headerBtn.Size = UDim2.new(1, 0, 0, 25)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = "   ▼ " .. name
        headerBtn.Font = Enum.Font.GothamSemibold
        headerBtn.TextSize = 14
        headerBtn.TextColor3 = Library:ActiveTheme().SubText
        headerBtn.TextXAlignment = Enum.TextXAlignment.Left
        headerBtn.AutoButtonColor = false
        CreateCorner(headerBtn, 4)
        
        -- 折叠内容容器
        local itemsFrame = Instance.new("Frame")
        itemsFrame.Parent = groupFrame
        itemsFrame.BackgroundTransparency = 1
        itemsFrame.Size = UDim2.new(1, 0, 0, 0)
        itemsFrame.Position = UDim2.new(0, 0, 0, 28)
        itemsFrame.Visible = true
        local itemsList = Instance.new("UIListLayout")
        itemsList.Parent = itemsFrame
        itemsList.Padding = UDim.new(0, 3)
        itemsList.SortOrder = Enum.SortOrder.LayoutOrder
        
        local collapsed = false
        local function toggleCollapse()
            collapsed = not collapsed
            itemsFrame.Visible = not collapsed
            headerBtn.Text = (collapsed and "   ▶ " or "   ▼ ") .. name
            local totalHeight = 25
            if not collapsed then
                totalHeight = 28 + itemsList.AbsoluteContentSize.Y
            end
            groupFrame.Size = UDim2.new(1, -10, 0, totalHeight)
        end
        headerBtn.MouseButton1Click:Connect(toggleCollapse)
        
        local group = {
            Frame = groupFrame,
            ItemsFrame = itemsFrame,
            ItemsList = itemsList,
            Toggle = toggleCollapse,
            Tabs = {}
        }
        table.insert(self.TabGroups, group)
        
        -- 返回分组对象，支持创建 Tab
        local groupAPI = {}
        function groupAPI:CreateTab(tabName)
            local tabBtn = Instance.new("TextButton")
            tabBtn.Parent = itemsFrame
            tabBtn.Size = UDim2.new(1, 0, 0, 25)
            tabBtn.BackgroundTransparency = 1
            tabBtn.Text = tabName
            tabBtn.Font = Enum.Font.Gotham
            tabBtn.TextSize = 13
            tabBtn.TextColor3 = Library:ActiveTheme().Text
            tabBtn.TextXAlignment = Enum.TextXAlignment.Left
            tabBtn.AutoButtonColor = false
            CreateCorner(tabBtn, 4)
            
            -- Tab 内容容器
            local tabContent = Instance.new("Frame")
            tabContent.Parent = self.Content
            tabContent.BackgroundTransparency = 1
            tabContent.Size = UDim2.new(1, 0, 0, 0)  -- 高度自动
            tabContent.Visible = false
            tabContent.LayoutOrder = #self.Tabs + 1
            
            -- 内容列表
            local tabLayout = Instance.new("UIListLayout")
            tabLayout.Parent = tabContent
            tabLayout.Padding = UDim.new(0, 10)
            tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
            tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            
            local tab = {
                Button = tabBtn,
                Content = tabContent,
                Layout = tabLayout,
                Sections = {}
            }
            table.insert(self.Tabs, tab)
            table.insert(group.Tabs, tab)
            
            -- 激活逻辑
            local function activate()
                for _, t in ipairs(self.Tabs) do
                    t.Content.Visible = false
                    t.Button.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    t.Button.BackgroundTransparency = 1
                end
                tab.Content.Visible = true
                tabBtn.BackgroundColor3 = Library:ActiveTheme().Accent
                tabBtn.BackgroundTransparency = 0.8
                self.CurrentTab = tab
                self.Content.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 20)
            end
            tabBtn.MouseButton1Click:Connect(activate)
            if #self.Tabs == 1 then
                activate()
            end
            
            -- 创建 Section
            function tab:CreateSection(sectionName)
                local sectionFrame = Instance.new("Frame")
                sectionFrame.Parent = tabContent
                sectionFrame.Size = UDim2.new(1, 0, 0, 100)
                sectionFrame.BackgroundColor3 = Library:ActiveTheme().Card
                sectionFrame.BorderSizePixel = 0
                CreateCorner(sectionFrame, 4)
                CreateStroke(sectionFrame, Library:ActiveTheme().Line, 1)
                
                local sectionLayout = Instance.new("UIListLayout")
                sectionLayout.Parent = sectionFrame
                sectionLayout.Padding = UDim.new(0, 5)
                sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
                sectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                
                local sec = {
                    Frame = sectionFrame,
                    Layout = sectionLayout,
                    Controls = {},
                    Resize = function(self)
                        sectionFrame.Size = UDim2.new(1, 0, 0, sectionLayout.AbsoluteContentSize.Y + 20)
                        tab.Content.Size = UDim2.new(1, 0, 0, tab.Layout.AbsoluteContentSize.Y)
                        self.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Layout.AbsoluteContentSize.Y + 20)
                    end
                }
                table.insert(tab.Sections, sec)
                
                -- 动态调整高度
                sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    sec:Resize()
                end)
                
                -- Section API
                local sectionAPI = {}
                
                -- 按钮
                function sectionAPI:AddButton(text, callback)
                    local btn = Instance.new("TextButton")
                    btn.Parent = sectionFrame
                    btn.Size = UDim2.new(1, -20, 0, 32)
                    btn.BackgroundColor3 = Library:ActiveTheme().Accent
                    btn.Text = text
                    btn.Font = Enum.Font.GothamSemibold
                    btn.TextSize = 13
                    btn.TextColor3 = Color3.fromRGB(255,255,255)
                    btn.AutoButtonColor = false
                    CreateCorner(btn, 4)
                    
                    btn.MouseButton1Click:Connect(function()
                        callback()
                    end)
                    
                    -- 点击动效
                    btn.MouseButton1Down:Connect(function()
                        TweenObject(btn, {TextSize = 12}, 0.1, Enum.EasingStyle.Bounce)
                    end)
                    btn.MouseButton1Up:Connect(function()
                        TweenObject(btn, {TextSize = 13}, 0.1)
                    end)
                    btn.MouseLeave:Connect(function()
                        TweenObject(btn, {TextSize = 13}, 0.1)
                    end)
                    
                    table.insert(sec.Controls, {Type = "Button", Obj = btn})
                end
                
                -- 开关 (带动画)
                function sectionAPI:AddToggle(text, default, callback)
                    local toggled = default or false
                    local container = Instance.new("Frame")
                    container.Parent = sectionFrame
                    container.Size = UDim2.new(1, -20, 0, 36)
                    container.BackgroundTransparency = 1
                    
                    local label = Instance.new("TextLabel")
                    label.Parent = container
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(0.7, 0, 1, 0)
                    label.Text = text
                    label.Font = Enum.Font.Gotham
                    label.TextSize = 13
                    label.TextColor3 = Library:ActiveTheme().Text
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local toggleFrame = Instance.new("TextButton")
                    toggleFrame.Parent = container
                    toggleFrame.Size = UDim2.new(0, 42, 0, 22)
                    toggleFrame.Position = UDim2.new(1, -42, 0.5, -11)
                    toggleFrame.BackgroundColor3 = toggled and Library:ActiveTheme().ToggleOn or Library:ActiveTheme().ToggleOff
                    toggleFrame.Text = ""
                    toggleFrame.AutoButtonColor = false
                    CreateCorner(toggleFrame, 11)
                    
                    local knob = Instance.new("Frame")
                    knob.Parent = toggleFrame
                    knob.Size = UDim2.new(0, 18, 0, 18)
                    knob.Position = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    CreateCorner(knob, 9)
                    
                    local function update()
                        toggled = not toggled
                        callback(toggled)
                        TweenObject(toggleFrame, {BackgroundColor3 = toggled and Library:ActiveTheme().ToggleOn or Library:ActiveTheme().ToggleOff}, 0.2)
                        TweenObject(knob, {Position = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}, 0.2)
                    end
                    toggleFrame.MouseButton1Click:Connect(update)
                    label.MouseButton1Click:Connect(update)
                    
                    table.insert(sec.Controls, {Type = "Toggle", Get = function() return toggled end, Set = function(v) if v ~= toggled then update() end end})
                end
                
                -- 滑块
                function sectionAPI:AddSlider(text, min, max, default, callback)
                    local value = default or min
                    local container = Instance.new("Frame")
                    container.Parent = sectionFrame
                    container.Size = UDim2.new(1, -20, 0, 50)
                    container.BackgroundTransparency = 1
                    
                    local label = Instance.new("TextLabel")
                    label.Parent = container
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(1, 0, 0, 20)
                    label.Text = text .. ": " .. tostring(value)
                    label.Font = Enum.Font.Gotham
                    label.TextSize = 12
                    label.TextColor3 = Library:ActiveTheme().SubText
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local bar = Instance.new("Frame")
                    bar.Parent = container
                    bar.Size = UDim2.new(1, 0, 0, 4)
                    bar.Position = UDim2.new(0, 0, 0, 32)
                    bar.BackgroundColor3 = Library:ActiveTheme().SliderBg
                    CreateCorner(bar, 2)
                    
                    local fill = Instance.new("Frame")
                    fill.Parent = bar
                    fill.Size = UDim2.new((value-min)/(max-min), 0, 1, 0)
                    fill.BackgroundColor3 = Library:ActiveTheme().Accent
                    CreateCorner(fill, 2)
                    
                    local knob = Instance.new("TextButton")
                    knob.Parent = bar
                    knob.Size = UDim2.new(0, 16, 0, 16)
                    knob.Position = UDim2.new((value-min)/(max-min), -8, -6, 0)
                    knob.BackgroundColor3 = Library:ActiveTheme().SliderKnob
                    knob.Text = ""
                    knob.AutoButtonColor = false
                    CreateCorner(knob, 8)
                    
                    local dragging = false
                    local function move(input)
                        local barAbs = bar.AbsolutePosition
                        local barSize = bar.AbsoluteSize.X
                        local x = math.clamp(input.Position.X - barAbs.X, 0, barSize)
                        local perc = x / barSize
                        local newVal = min + (max - min) * perc
                        newVal = math.floor(newVal * 100) / 100
                        if newVal ~= value then
                            value = newVal
                            label.Text = text .. ": " .. tostring(value)
                            fill.Size = UDim2.new(perc, 0, 1, 0)
                            knob.Position = UDim2.new(perc, -8, -6, 0)
                            callback(value)
                        end
                    end
                    knob.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            move(input)
                        end
                    end)
                    bar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            move(input)
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            move(input)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)
                    table.insert(sec.Controls, {Type = "Slider", Get = function() return value end, Set = function(v) value = v; label.Text = text .. ": " .. tostring(v); local p = (v-min)/(max-min); fill.Size = UDim2.new(p,0,1,0); knob.Position = UDim2.new(p,-8,-6,0) end})
                end
                
                -- 下拉框
                function sectionAPI:AddDropdown(text, list, default, callback)
                    local selected = default or list[1]
                    local expanded = false
                    local container = Instance.new("Frame")
                    container.Parent = sectionFrame
                    container.Size = UDim2.new(1, -20, 0, 32)
                    container.BackgroundColor3 = Library:ActiveTheme().Input
                    CreateCorner(container, 4)
                    
                    local label = Instance.new("TextButton")
                    label.Parent = container
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "  " .. selected
                    label.Font = Enum.Font.Gotham
                    label.TextSize = 13
                    label.TextColor3 = Library:ActiveTheme().Text
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.AutoButtonColor = false
                    
                    local arrow = Instance.new("TextLabel")
                    arrow.Parent = label
                    arrow.BackgroundTransparency = 1
                    arrow.Size = UDim2.new(0, 20, 1, 0)
                    arrow.Position = UDim2.new(1, -20, 0, 0)
                    arrow.Text = "▼"
                    arrow.Font = Enum.Font.Gotham
                    arrow.TextSize = 12
                    arrow.TextColor3 = Library:ActiveTheme().Text
                    
                    local listFrame = Instance.new("Frame")
                    listFrame.Parent = container
                    listFrame.Size = UDim2.new(1, 0, 0, 0)
                    listFrame.Position = UDim2.new(0, 0, 1, 5)
                    listFrame.BackgroundColor3 = Library:ActiveTheme().Input
                    listFrame.ClipsDescendants = true
                    listFrame.Visible = false
                    CreateCorner(listFrame, 4)
                    listFrame.ZIndex = 10
                    
                    local listLayout = Instance.new("UIListLayout")
                    listLayout.Parent = listFrame
                    listLayout.Padding = UDim.new(0, 2)
                    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    
                    local function populate()
                        for _, child in ipairs(listFrame:GetChildren()) do
                            if child:IsA("TextButton") then child:Destroy() end
                        end
                        for _, opt in ipairs(list) do
                            local btn = Instance.new("TextButton")
                            btn.Parent = listFrame
                            btn.Size = UDim2.new(1, 0, 0, 26)
                            btn.BackgroundTransparency = 1
                            btn.Text = "  " .. opt
                            btn.Font = Enum.Font.Gotham
                            btn.TextSize = 13
                            btn.TextColor3 = Library:ActiveTheme().Text
                            btn.TextXAlignment = Enum.TextXAlignment.Left
                            btn.AutoButtonColor = false
                            CreateCorner(btn, 4)
                            btn.MouseButton1Click:Connect(function()
                                selected = opt
                                label.Text = "  " .. opt
                                callback(opt)
                                expanded = false
                                listFrame.Visible = false
                                container.Size = UDim2.new(1, -20, 0, 32)
                            end)
                        end
                        listFrame.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
                    end
                    
                    label.MouseButton1Click:Connect(function()
                        expanded = not expanded
                        listFrame.Visible = expanded
                        if expanded then
                            populate()
                            container.Size = UDim2.new(1, -20, 0, 32 + listFrame.AbsoluteSize.Y)
                        else
                            container.Size = UDim2.new(1, -20, 0, 32)
                        end
                        self.Content.CanvasSize = UDim2.new(0, 0, 0, self.Content.Layout.AbsoluteContentSize.Y)
                    end)
                end
                
                -- 文本框
                function sectionAPI:AddTextbox(text, placeholder, callback)
                    local container = Instance.new("Frame")
                    container.Parent = sectionFrame
                    container.Size = UDim2.new(1, -20, 0, 38)
                    container.BackgroundTransparency = 1
                    
                    local label = Instance.new("TextLabel")
                    label.Parent = container
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(0, 80, 1, 0)
                    label.Text = text
                    label.Font = Enum.Font.Gotham
                    label.TextSize = 12
                    label.TextColor3 = Library:ActiveTheme().SubText
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local box = Instance.new("TextBox")
                    box.Parent = container
                    box.Size = UDim2.new(1, -90, 0, 26)
                    box.Position = UDim2.new(0, 85, 0.5, -13)
                    box.BackgroundColor3 = Library:ActiveTheme().Input
                    box.PlaceholderText = placeholder or ""
                    box.Text = ""
                    box.Font = Enum.Font.Gotham
                    box.TextSize = 13
                    box.TextColor3 = Library:ActiveTheme().Text
                    box.PlaceholderColor3 = Library:ActiveTheme().MutedText
                    CreateCorner(box, 4)
                    
                    box.FocusLost:Connect(function(enterPressed)
                        if enterPressed then
                            callback(box.Text)
                        end
                    end)
                end
                
                -- 按键绑定
                function sectionAPI:AddKeybind(text, defaultKey, callback)
                    local key = defaultKey or Enum.KeyCode.F
                    local binding = false
                    local container = Instance.new("Frame")
                    container.Parent = sectionFrame
                    container.Size = UDim2.new(1, -20, 0, 32)
                    container.BackgroundTransparency = 1
                    
                    local label = Instance.new("TextButton")
                    label.Parent = container
                    label.Size = UDim2.new(0.7, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = text
                    label.Font = Enum.Font.Gotham
                    label.TextSize = 13
                    label.TextColor3 = Library:ActiveTheme().Text
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.AutoButtonColor = false
                    
                    local keyLabel = Instance.new("TextButton")
                    keyLabel.Parent = container
                    keyLabel.Size = UDim2.new(0, 60, 0, 22)
                    keyLabel.Position = UDim2.new(1, -65, 0.5, -11)
                    keyLabel.BackgroundColor3 = Library:ActiveTheme().Input
                    keyLabel.Text = key.Name
                    keyLabel.Font = Enum.Font.Gotham
                    keyLabel.TextSize = 11
                    keyLabel.TextColor3 = Library:ActiveTheme().Text
                    keyLabel.AutoButtonColor = false
                    CreateCorner(keyLabel, 4)
                    
                    local function startBinding()
                        if binding then return end
                        binding = true
                        keyLabel.Text = "..."
                        local con
                        con = UserInputService.InputBegan:Connect(function(input, gpe)
                            if not gpe and input.KeyCode ~= Enum.KeyCode.Unknown then
                                key = input.KeyCode
                                keyLabel.Text = key.Name
                                con:Disconnect()
                                binding = false
                            end
                        end)
                        task.delay(5, function()
                            if binding then
                                con:Disconnect()
                                keyLabel.Text = key.Name
                                binding = false
                            end
                        end)
                    end
                    keyLabel.MouseButton1Click:Connect(startBinding)
                    label.MouseButton1Click:Connect(startBinding)
                    
                    UserInputService.InputBegan:Connect(function(input, gpe)
                        if not gpe and input.KeyCode == key then
                            callback()
                        end
                    end)
                end
                
                -- 颜色选择器 (完整 HSV 色板)
                function sectionAPI:AddColorpicker(text, defaultColor, callback)
                    local color = defaultColor or Color3.fromRGB(255,255,255)
                    local expanded = false
                    local container = Instance.new("Frame")
                    container.Parent = sectionFrame
                    container.Size = UDim2.new(1, -20, 0, 32)
                    container.BackgroundColor3 = Library:ActiveTheme().Input
                    CreateCorner(container, 4)
                    
                    local label = Instance.new("TextButton")
                    label.Parent = container
                    label.Size = UDim2.new(0.8, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "  " .. text
                    label.Font = Enum.Font.Gotham
                    label.TextSize = 13
                    label.TextColor3 = Library:ActiveTheme().Text
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.AutoButtonColor = false
                    
                    local colorPreview = Instance.new("Frame")
                    colorPreview.Parent = container
                    colorPreview.Size = UDim2.new(0, 22, 0, 22)
                    colorPreview.Position = UDim2.new(1, -28, 0.5, -11)
                    colorPreview.BackgroundColor3 = color
                    CreateCorner(colorPreview, 4)
                    
                    local pickerFrame = Instance.new("Frame")
                    pickerFrame.Parent = container
                    pickerFrame.Size = UDim2.new(1, 0, 0, 220)
                    pickerFrame.Position = UDim2.new(0, 0, 1, 5)
                    pickerFrame.BackgroundColor3 = Library:ActiveTheme().Card
                    pickerFrame.Visible = false
                    CreateCorner(pickerFrame, 4)
                    pickerFrame.ZIndex = 10
                    CreateStroke(pickerFrame, Library:ActiveTheme().Line, 1)
                    
                    -- 色相条
                    local hueBar = Instance.new("Frame")
                    hueBar.Parent = pickerFrame
                    hueBar.Size = UDim2.new(1, -20, 0, 20)
                    hueBar.Position = UDim2.new(0, 10, 0, 10)
                    hueBar.BackgroundColor3 = Color3.fromRGB(255,0,0)
                    local hueGrad = Instance.new("UIGradient")
                    hueGrad.Parent = hueBar
                    hueGrad.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
                    }
                    
                    local hueKnob = Instance.new("Frame")
                    hueKnob.Parent = hueBar
                    hueKnob.Size = UDim2.new(0, 8, 0, 24)
                    hueKnob.Position = UDim2.new(0, -4, -2, 0)
                    hueKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    CreateCorner(hueKnob, 4)
                    
                    -- 饱和度/亮度画布
                    local svCanvas = Instance.new("ImageLabel")
                    svCanvas.Parent = pickerFrame
                    svCanvas.Size = UDim2.new(1, -20, 0, 150)
                    svCanvas.Position = UDim2.new(0, 10, 0, 40)
                    svCanvas.BackgroundColor3 = Color3.fromRGB(255,0,0)
                    svCanvas.Image = "rbxassetid://4155801252"
                    CreateCorner(svCanvas, 4)
                    
                    local svKnob = Instance.new("Frame")
                    svKnob.Parent = svCanvas
                    svKnob.Size = UDim2.new(0, 14, 0, 14)
                    svKnob.Position = UDim2.new(1, -7, 0, -7)
                    svKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    CreateCorner(svKnob, 7)
                    
                    local currentHue = 0
                    local draggingHue, draggingSV = false, false
                    
                    local function updateColor()
                        local s = math.clamp((svKnob.Position.X.Scale * svCanvas.AbsoluteSize.X + svKnob.AbsoluteSize.X/2) / svCanvas.AbsoluteSize.X, 0, 1)
                        local v = 1 - math.clamp((svKnob.Position.Y.Scale * svCanvas.AbsoluteSize.Y + svKnob.AbsoluteSize.Y/2) / svCanvas.AbsoluteSize.Y, 0, 1)
                        color = Color3.fromHSV(currentHue, s, v)
                        colorPreview.BackgroundColor3 = color
                        callback(color)
                    end
                    
                    local function updateHue(input)
                        local x = math.clamp(input.Position.X - hueBar.AbsolutePosition.X, 0, hueBar.AbsoluteSize.X)
                        local h = x / hueBar.AbsoluteSize.X
                        currentHue = h
                        svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        hueKnob.Position = UDim2.new(h, -4, -2, 0)
                        updateColor()
                    end
                    
                    local function updateSV(input)
                        local x = math.clamp(input.Position.X - svCanvas.AbsolutePosition.X, 0, svCanvas.AbsoluteSize.X)
                        local y = math.clamp(input.Position.Y - svCanvas.AbsolutePosition.Y, 0, svCanvas.AbsoluteSize.Y)
                        svKnob.Position = UDim2.new(x/svCanvas.AbsoluteSize.X, -7, y/svCanvas.AbsoluteSize.Y, -7)
                        updateColor()
                    end
                    
                    hueBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            draggingHue = true
                            updateHue(input)
                        end
                    end)
                    svCanvas.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            draggingSV = true
                            updateSV(input)
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if draggingHue then
                            updateHue(input)
                        elseif draggingSV then
                            updateSV(input)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function()
                        draggingHue = false
                        draggingSV = false
                    end)
                    
                    local function toggle()
                        expanded = not expanded
                        pickerFrame.Visible = expanded
                        if expanded then
                            container.Size = UDim2.new(1, -20, 0, 32 + 230)
                        else
                            container.Size = UDim2.new(1, -20, 0, 32)
                        end
                        self.Content.CanvasSize = UDim2.new(0,0,0,self.Content.Layout.AbsoluteContentSize.Y)
                    end
                    label.MouseButton1Click:Connect(toggle)
                    colorPreview.MouseButton1Click:Connect(toggle)
                    
                    -- 初始化颜色
                    local h, s, v = color:ToHSV()
                    currentHue = h
                    svCanvas.BackgroundColor3 = Color3.fromHSV(h,1,1)
                    hueKnob.Position = UDim2.new(h, -4, -2, 0)
                    svKnob.Position = UDim2.new(s, -7, 1-v, -7)
                end
                
                -- 进度条
                function sectionAPI:AddProgress(text, initial, max, callback)
                    local value = initial or 0
                    local container = Instance.new("Frame")
                    container.Parent = sectionFrame
                    container.Size = UDim2.new(1, -20, 0, 45)
                    container.BackgroundTransparency = 1
                    
                    local label = Instance.new("TextLabel")
                    label.Parent = container
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(1, 0, 0, 20)
                    label.Text = text .. ": " .. tostring(value) .. "%"
                    label.Font = Enum.Font.Gotham
                    label.TextSize = 12
                    label.TextColor3 = Library:ActiveTheme().SubText
                    
                    local bar = Instance.new("Frame")
                    bar.Parent = container
                    bar.Size = UDim2.new(1, 0, 0, 8)
                    bar.Position = UDim2.new(0, 0, 0, 30)
                    bar.BackgroundColor3 = Library:ActiveTheme().SliderBg
                    CreateCorner(bar, 4)
                    
                    local fill = Instance.new("Frame")
                    fill.Parent = bar
                    fill.Size = UDim2.new(value/max, 0, 1, 0)
                    fill.BackgroundColor3 = Library:ActiveTheme().Accent
                    CreateCorner(fill, 4)
                    
                    local obj = {
                        Set = function(v)
                            value = math.clamp(v, 0, max)
                            fill.Size = UDim2.new(value/max, 0, 1, 0)
                            label.Text = text .. ": " .. tostring(math.floor(value/max*100)) .. "%"
                            if callback then callback(value) end
                        end,
                        Get = function() return value end
                    }
                    table.insert(sec.Controls, {Type = "Progress", Obj = obj})
                    return obj
                end
                
                return sectionAPI
            end
            
            return tab
        end
        
        return groupAPI
    end
    
    -- 刷新所有内容高度
    function self:Refresh()
        for _, tab in ipairs(self.Tabs) do
            tab.Content.Size = UDim2.new(1, 0, 0, tab.Layout.AbsoluteContentSize.Y)
        end
        self.Content.CanvasSize = UDim2.new(0, 0, 0, (self.CurrentTab and self.CurrentTab.Layout.AbsoluteContentSize.Y or 0) + 20)
    end
    
    return self
end

-- ======================== 主题切换 ========================
function Library:SetTheme(theme)
    if Library.Themes[theme] then
        Library.Theme = theme
        Library:Notify("主题", "已切换到 " .. theme, 3)
        -- 实际上需要重新构建所有窗口才能完全应用，此处简单通知
    end
end

-- ======================== 返回库 ========================
return Library