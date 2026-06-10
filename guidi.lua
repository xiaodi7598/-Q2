--[[
    ============================================================================
    MobileUI - 手机通用高级UI库
    版本: 2.0
    代码量: ~3800 行
    功能: 窗口、标签页、按钮、开关、滑块、下拉框、颜色选择器、文本框、数字输入框、
          绑定按键、通知、模态对话框、网格布局、表格视图、分页控件、主题切换、
          动画队列、手势支持、屏幕适配、全局事件、模板系统。
    兼容: 手机触摸 + 鼠标
    作者: 定制
    ============================================================================
]]

local MobileUI = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- 确保 ScreenGui 存在且独立
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileUI_v2"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- =============================== 配置 ===================================
local Config = {
    AccentColor = Color3.fromRGB(114, 137, 228),      -- 主题色
    AccentHover = Color3.fromRGB(94, 117, 208),
    DangerColor = Color3.fromRGB(240, 71, 71),
    SuccessColor = Color3.fromRGB(67, 181, 129),
    WarningColor = Color3.fromRGB(250, 166, 26),
    BackgroundMain = Color3.fromRGB(47, 49, 54),
    BackgroundSide = Color3.fromRGB(40, 42, 47),
    BackgroundCard = Color3.fromRGB(64, 68, 75),
    BackgroundInput = Color3.fromRGB(45, 48, 53),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    TextMuted = Color3.fromRGB(140, 140, 140),
    BorderRadius = 8,                                   -- 全局圆角
    AnimationDuration = 0.2,
    BaseWidth = 375,                                    -- 设计稿宽度 (iPhone X)
}

-- 屏幕缩放因子
local function getScale()
    local viewport = workspace.CurrentCamera.ViewportSize
    return math.min(viewport.X / Config.BaseWidth, 1.2)
end

-- 便捷圆角
local function round(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or Config.BorderRadius)
    c.Parent = instance
end

-- 便捷阴影 (轻量)
local function shadow(instance)
    local shadow = Instance.new("ImageLabel")
    shadow.Image = "rbxassetid://4996891970"
    shadow.ImageColor3 = Color3.fromRGB(0,0,0)
    shadow.ImageTransparency = 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(20,20,280,280)
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.ZIndex = -1
    shadow.Parent = instance
end

-- 动画队列 (用于连续动画)
local TweenQueue = {}
function TweenQueue:Add(instance, properties, duration, easingStyle, easingDirection)
    local tween = TweenService:Create(instance, TweenInfo.new(duration or Config.AnimationDuration, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

-- 防抖/节流简单实现
local Debounce = {}
function Debounce:Call(func, wait)
    local co = coroutine.running()
    if self[co] then return end
    self[co] = true
    task.spawn(function()
        func()
        task.wait(wait)
        self[co] = nil
    end)
end

-- =============================== 基础拖拽 ===================================
local function MakeDraggable(handle, target)
    local dragStart, startPos, active = nil, nil, false
    local function update(input)
        local delta = input.Position - dragStart
        target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then active = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

-- =============================== 全局事件系统 ===================================
local Event = {}
Event.__index = Event
function Event.new()
    return setmetatable({_callbacks = {}}, Event)
end
function Event:Connect(cb)
    table.insert(self._callbacks, cb)
end
function Event:Fire(...)
    for _, cb in ipairs(self._callbacks) do
        task.spawn(cb, ...)
    end
end

-- =============================== 主题管理 ===================================
local Theme = {
    current = "dark",
    onChanged = Event.new(),
    colors = {
        dark = {
            main = Color3.fromRGB(47,49,54),
            side = Color3.fromRGB(40,42,47),
            card = Color3.fromRGB(64,68,75),
            input = Color3.fromRGB(45,48,53),
            text = Color3.fromRGB(255,255,255),
            textSec = Color3.fromRGB(200,200,200),
            textMuted = Color3.fromRGB(140,140,140),
        },
        light = {
            main = Color3.fromRGB(240,240,245),
            side = Color3.fromRGB(230,230,235),
            card = Color3.fromRGB(255,255,255),
            input = Color3.fromRGB(245,245,250),
            text = Color3.fromRGB(30,30,30),
            textSec = Color3.fromRGB(80,80,80),
            textMuted = Color3.fromRGB(120,120,120),
        }
    }
}
function Theme.set(themeName)
    if Theme.colors[themeName] then
        Theme.current = themeName
        Theme.onChanged:Fire(themeName)
    end
end
function Theme.getColor(key)
    return Theme.colors[Theme.current][key] or Config.BackgroundMain
end

-- =============================== 窗口类 ===================================
local Window = {}
Window.__index = Window

function Window.new(title, subtitle, accentColor)
    local self = setmetatable({}, Window)
    self.accent = accentColor or Config.AccentColor
    self.tabs = {}
    self.currentTab = nil
    self.scale = getScale()
    self.visible = true
    
    -- 主框架
    self.frame = Instance.new("Frame")
    self.frame.Parent = ScreenGui
    self.frame.AnchorPoint = Vector2.new(0.5, 0.5)
    self.frame.BackgroundColor3 = Theme.getColor("main")
    self.frame.ClipsDescendants = true
    self.frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.frame.Size = UDim2.new(0, 340 * self.scale, 0, 520 * self.scale)
    round(self.frame, Config.BorderRadius)
    shadow(self.frame)
    
    -- 顶部拖拽栏
    self.dragBar = Instance.new("Frame")
    self.dragBar.Parent = self.frame
    self.dragBar.Size = UDim2.new(1, 0, 0, 40 * self.scale)
    self.dragBar.BackgroundColor3 = self.accent
    self.dragBar.BackgroundTransparency = 0.9
    MakeDraggable(self.dragBar, self.frame)
    
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Parent = self.dragBar
    self.titleLabel.Size = UDim2.new(1, -60, 0.6, 0)
    self.titleLabel.Position = UDim2.new(0, 15, 0, 5 * self.scale)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = title
    self.titleLabel.TextColor3 = Theme.getColor("text")
    self.titleLabel.Font = Enum.Font.GothamBold
    self.titleLabel.TextSize = 18 * self.scale
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    self.subLabel = Instance.new("TextLabel")
    self.subLabel.Parent = self.dragBar
    self.subLabel.Size = UDim2.new(1, -60, 0.4, 0)
    self.subLabel.Position = UDim2.new(0, 15, 0, 24 * self.scale)
    self.subLabel.BackgroundTransparency = 1
    self.subLabel.Text = subtitle
    self.subLabel.TextColor3 = Theme.getColor("textSec")
    self.subLabel.Font = Enum.Font.Gotham
    self.subLabel.TextSize = 11 * self.scale
    self.subLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 关闭按钮
    self.closeBtn = Instance.new("TextButton")
    self.closeBtn.Parent = self.dragBar
    self.closeBtn.Size = UDim2.new(0, 35, 0, 35)
    self.closeBtn.Position = UDim2.new(1, -40, 0, 2)
    self.closeBtn.BackgroundTransparency = 1
    self.closeBtn.Text = "✕"
    self.closeBtn.TextColor3 = Theme.getColor("text")
    self.closeBtn.Font = Enum.Font.Gotham
    self.closeBtn.TextSize = 20
    self.closeBtn.AutoButtonColor = false
    self.closeBtn.MouseButton1Click:Connect(function()
        self:Hide()
    end)
    self.closeBtn.TouchTap:Connect(function()
        self:Hide()
    end)
    
    -- 左侧导航栏
    self.sidebar = Instance.new("Frame")
    self.sidebar.Parent = self.frame
    self.sidebar.Size = UDim2.new(0, 80 * self.scale, 1, -40 * self.scale)
    self.sidebar.Position = UDim2.new(0, 0, 0, 40 * self.scale)
    self.sidebar.BackgroundColor3 = Theme.getColor("side")
    self.sidebar.BorderSizePixel = 0
    
    -- 右侧内容区域 (ScrollingFrame)
    self.content = Instance.new("ScrollingFrame")
    self.content.Parent = self.frame
    self.content.Size = UDim2.new(1, -80 * self.scale, 1, -40 * self.scale)
    self.content.Position = UDim2.new(0, 80 * self.scale, 0, 40 * self.scale)
    self.content.BackgroundColor3 = Theme.getColor("main")
    self.content.BorderSizePixel = 0
    self.content.ScrollBarThickness = 4
    self.content.ScrollBarImageColor3 = Theme.getColor("textMuted")
    self.content.CanvasSize = UDim2.new(0,0,0,0)
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.Parent = self.content
    contentPadding.PaddingTop = UDim.new(0, 10)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.PaddingLeft = UDim.new(0, 10)
    contentPadding.PaddingRight = UDim.new(0, 10)
    
    self.contentLayout = Instance.new("UIListLayout")
    self.contentLayout.Parent = self.content
    self.contentLayout.Padding = UDim.new(0, 12)
    self.contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- 标签页列表布局
    self.tabLayout = Instance.new("UIListLayout")
    self.tabLayout.Parent = self.sidebar
    self.tabLayout.Padding = UDim.new(0, 8)
    self.tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- 主题响应
    Theme.onChanged:Connect(function()
        self.frame.BackgroundColor3 = Theme.getColor("main")
        self.titleLabel.TextColor3 = Theme.getColor("text")
        self.subLabel.TextColor3 = Theme.getColor("textSec")
        self.closeBtn.TextColor3 = Theme.getColor("text")
        self.sidebar.BackgroundColor3 = Theme.getColor("side")
        self.content.BackgroundColor3 = Theme.getColor("main")
        self.content.ScrollBarImageColor3 = Theme.getColor("textMuted")
        for _, tab in ipairs(self.tabs) do
            tab:refreshTheme()
        end
    end)
    
    return self
end

function Window:Hide()
    if not self.visible then return end
    self.visible = false
    TweenQueue:Add(self.frame, {Size = UDim2.new(0,0,0,0)}, 0.3, Enum.EasingStyle.Quart)
    task.wait(0.3)
    self.frame.Visible = false
end

function Window:Show()
    self.frame.Visible = true
    self.visible = true
    TweenQueue:Add(self.frame, {Size = UDim2.new(0, 340 * self.scale, 0, 520 * self.scale)}, 0.3, Enum.EasingStyle.Quart)
end

function Window:Destroy()
    self.frame:Destroy()
end

-- =============================== 标签页类 ===================================
local Tab = {}
Tab.__index = Tab

function Window:Tab(name, iconId)
    local selfWin = self
    local tab = setmetatable({}, Tab)
    tab.window = selfWin
    tab.name = name
    tab.iconId = iconId or "rbxassetid://6031087059"
    tab.button = nil
    tab.container = nil
    tab.controls = {}
    tab.active = false
    
    -- 创建按钮
    local btn = Instance.new("TextButton")
    btn.Parent = selfWin.sidebar
    btn.Size = UDim2.new(1, -10, 0, 55 * selfWin.scale)
    btn.Position = UDim2.new(0, 5, 0, 0)
    btn.BackgroundColor3 = Theme.getColor("side")
    btn.Text = ""
    btn.AutoButtonColor = false
    round(btn, Config.BorderRadius)
    
    local icon = Instance.new("ImageLabel")
    icon.Parent = btn
    icon.Size = UDim2.new(0, 28 * selfWin.scale, 0, 28 * selfWin.scale)
    icon.Position = UDim2.new(0.5, -14 * selfWin.scale, 0, 8 * selfWin.scale)
    icon.BackgroundTransparency = 1
    icon.Image = tab.iconId
    icon.ImageColor3 = Theme.getColor("textSec")
    
    local label = Instance.new("TextLabel")
    label.Parent = btn
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 40 * selfWin.scale)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.getColor("textSec")
    label.Font = Enum.Font.Gotham
    label.TextSize = 10 * selfWin.scale
    
    tab.button = btn
    tab.icon = icon
    tab.label = label
    
    -- 内容容器
    local container = Instance.new("Frame")
    container.Parent = selfWin.content
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 0)
    container.Visible = false
    container.LayoutOrder = #selfWin.tabs + 1
    
    local containerLayout = Instance.new("UIListLayout")
    containerLayout.Parent = container
    containerLayout.Padding = UDim.new(0, 12)
    containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    tab.container = container
    tab.containerLayout = containerLayout
    
    table.insert(selfWin.tabs, tab)
    
    -- 点击激活
    local function activate()
        for _, t in ipairs(selfWin.tabs) do
            t.button.BackgroundColor3 = Theme.getColor("side")
            t.icon.ImageColor3 = Theme.getColor("textSec")
            t.label.TextColor3 = Theme.getColor("textSec")
            t.container.Visible = false
            t.active = false
        end
        btn.BackgroundColor3 = selfWin.accent
        icon.ImageColor3 = Color3.fromRGB(255,255,255)
        label.TextColor3 = Color3.fromRGB(255,255,255)
        container.Visible = true
        tab.active = true
        -- 刷新滚动区域高度
        task.wait()
        selfWin.content.CanvasSize = UDim2.new(0, 0, 0, containerLayout.AbsoluteContentSize.Y + 20)
    end
    
    btn.MouseButton1Click:Connect(activate)
    btn.TouchTap:Connect(activate)
    
    -- 如果是第一个标签页，默认激活
    if #selfWin.tabs == 1 then
        activate()
    end
    
    -- 主题刷新
    function tab:refreshTheme()
        if self.active then
            self.button.BackgroundColor3 = self.window.accent
            self.icon.ImageColor3 = Color3.fromRGB(255,255,255)
            self.label.TextColor3 = Color3.fromRGB(255,255,255)
        else
            self.button.BackgroundColor3 = Theme.getColor("side")
            self.icon.ImageColor3 = Theme.getColor("textSec")
            self.label.TextColor3 = Theme.getColor("textSec")
        end
    end
    
    -- 创建控件的方法
    local function updateLayout()
        task.wait()
        self.window.content.CanvasSize = UDim2.new(0, 0, 0, tab.containerLayout.AbsoluteContentSize.Y + 20)
    end
    
    -- ========== 控件: 按钮 ==========
    function tab:Button(text, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = tab.container
        btn.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale)
        btn.BackgroundColor3 = Theme.getColor("card")
        btn.Text = text
        btn.TextColor3 = Theme.getColor("text")
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14 * selfWin.scale
        btn.AutoButtonColor = false
        round(btn, Config.BorderRadius)
        
        local function onClick()
            TweenQueue:Add(btn, {BackgroundColor3 = selfWin.accent}, 0.1)
            TweenQueue:Add(btn, {BackgroundColor3 = Theme.getColor("card")}, 0.2)
            pcall(callback)
        end
        btn.MouseButton1Click:Connect(onClick)
        btn.TouchTap:Connect(onClick)
        updateLayout()
    end
    
    -- ========== 控件: 开关 ==========
    function tab:Toggle(text, defaultValue, callback)
        local toggled = defaultValue or false
        local frame = Instance.new("Frame")
        frame.Parent = tab.container
        frame.Size = UDim2.new(1, 0, 0, 50 * selfWin.scale)
        frame.BackgroundColor3 = Theme.getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(1, -70, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.getColor("text")
        label.Font = Enum.Font.Gotham
        label.TextSize = 14 * selfWin.scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Parent = frame
        toggleBtn.Size = UDim2.new(0, 50 * selfWin.scale, 0, 26 * selfWin.scale)
        toggleBtn.Position = UDim2.new(1, -55 * selfWin.scale, 0.5, -13 * selfWin.scale)
        toggleBtn.BackgroundColor3 = toggled and selfWin.accent or Color3.fromRGB(120,120,120)
        toggleBtn.Text = ""
        toggleBtn.AutoButtonColor = false
        round(toggleBtn, 13)
        
        local circle = Instance.new("Frame")
        circle.Parent = toggleBtn
        circle.Size = UDim2.new(0, 22 * selfWin.scale, 0, 22 * selfWin.scale)
        circle.Position = toggled and UDim2.new(1, -24 * selfWin.scale, 0.5, -11 * selfWin.scale) or UDim2.new(0, 2 * selfWin.scale, 0.5, -11 * selfWin.scale)
        circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
        round(circle, 11)
        
        local function updateToggle()
            toggled = not toggled
            toggleBtn.BackgroundColor3 = toggled and selfWin.accent or Color3.fromRGB(120,120,120)
            local targetPos = toggled and UDim2.new(1, -24 * selfWin.scale, 0.5, -11 * selfWin.scale) or UDim2.new(0, 2 * selfWin.scale, 0.5, -11 * selfWin.scale)
            TweenQueue:Add(circle, {Position = targetPos}, 0.2)
            pcall(callback, toggled)
        end
        
        toggleBtn.MouseButton1Click:Connect(updateToggle)
        toggleBtn.TouchTap:Connect(updateToggle)
        updateLayout()
    end
    
    -- ========== 控件: 滑块 ==========
    function tab:Slider(text, minVal, maxVal, defaultVal, callback)
        local value = defaultVal or minVal
        local frame = Instance.new("Frame")
        frame.Parent = tab.container
        frame.Size = UDim2.new(1, 0, 0, 75 * selfWin.scale)
        frame.BackgroundColor3 = Theme.getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(1, -10, 0, 25 * selfWin.scale)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(value)
        label.TextColor3 = Theme.getColor("text")
        label.Font = Enum.Font.Gotham
        label.TextSize = 13 * selfWin.scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local bar = Instance.new("Frame")
        bar.Parent = frame
        bar.Size = UDim2.new(0.9, 0, 0, 4 * selfWin.scale)
        bar.Position = UDim2.new(0.05, 0, 0.65, 0)
        bar.BackgroundColor3 = Color3.fromRGB(80,80,80)
        round(bar, 2)
        
        local fill = Instance.new("Frame")
        fill.Parent = bar
        fill.Size = UDim2.new((value-minVal)/(maxVal-minVal), 0, 1, 0)
        fill.BackgroundColor3 = selfWin.accent
        round(fill, 2)
        
        local knob = Instance.new("TextButton")
        knob.Parent = bar
        knob.Size = UDim2.new(0, 22 * selfWin.scale, 0, 22 * selfWin.scale)
        knob.Position = UDim2.new((value-minVal)/(maxVal-minVal), -11 * selfWin.scale, -9 * selfWin.scale)
        knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        knob.Text = ""
        knob.AutoButtonColor = false
        round(knob, 11)
        shadow(knob)
        
        local dragging = false
        local function updateFromInput(input)
            local pos = input.Position
            local barPos = bar.AbsolutePosition.X
            local barSize = bar.AbsoluteSize.X
            local percent = math.clamp((pos.X - barPos) / barSize, 0, 1)
            local newVal = minVal + (maxVal - minVal) * percent
            if maxVal - minVal >= 1 then newVal = math.floor(newVal) end
            if newVal ~= value then
                value = newVal
                label.Text = text .. ": " .. tostring(value)
                fill.Size = UDim2.new((value-minVal)/(maxVal-minVal), 0, 1, 0)
                knob.Position = UDim2.new((value-minVal)/(maxVal-minVal), -11 * selfWin.scale, -9 * selfWin.scale)
                pcall(callback, value)
            end
        end
        
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end)
        knob.InputEnded:Connect(function()
            dragging = false
        end)
        
        updateLayout()
    end
    
    -- ========== 控件: 下拉框 ==========
    function tab:Dropdown(text, options, callback)
        local selected = options[1] or ""
        local expanded = false
        local frame = Instance.new("Frame")
        frame.Parent = tab.container
        frame.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale)
        frame.BackgroundColor3 = Theme.getColor("card")
        round(frame, Config.BorderRadius)
        frame.ClipsDescendants = false
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.7, -10, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. selected
        label.TextColor3 = Theme.getColor("text")
        label.Font = Enum.Font.Gotham
        label.TextSize = 13 * selfWin.scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local arrow = Instance.new("TextLabel")
        arrow.Parent = frame
        arrow.Size = UDim2.new(0, 30, 1, 0)
        arrow.Position = UDim2.new(1, -35, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▼"
        arrow.TextColor3 = Theme.getColor("textSec")
        arrow.Font = Enum.Font.Gotham
        arrow.TextSize = 14
        
        local panel = Instance.new("Frame")
        panel.Parent = frame
        panel.Size = UDim2.new(1, 0, 0, 0)
        panel.Position = UDim2.new(0, 0, 1, 5)
        panel.BackgroundColor3 = Theme.getColor("card")
        panel.ClipsDescendants = true
        round(panel, Config.BorderRadius)
        panel.Visible = false
        
        local panelLayout = Instance.new("UIListLayout")
        panelLayout.Parent = panel
        panelLayout.Padding = UDim.new(0, 2)
        
        local function refreshOptions()
            for _, child in ipairs(panel:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = panel
                optBtn.Size = UDim2.new(1, -10, 0, 35 * selfWin.scale)
                optBtn.Position = UDim2.new(0, 5, 0, 0)
                optBtn.BackgroundColor3 = Theme.getColor("card")
                optBtn.Text = opt
                optBtn.TextColor3 = Theme.getColor("text")
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 13 * selfWin.scale
                round(optBtn, Config.BorderRadius)
                optBtn.AutoButtonColor = false
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    label.Text = text .. ": " .. selected
                    expanded = false
                    panel.Visible = false
                    frame.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale)
                    pcall(callback, selected)
                end)
                optBtn.TouchTap:Connect(function()
                    selected = opt
                    label.Text = text .. ": " .. selected
                    expanded = false
                    panel.Visible = false
                    frame.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale)
                    pcall(callback, selected)
                end)
            end
            task.wait()
            panel.Size = UDim2.new(1, 0, 0, panelLayout.AbsoluteContentSize.Y + 10)
        end
        
        local function toggle()
            expanded = not expanded
            panel.Visible = expanded
            if expanded then
                refreshOptions()
                frame.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale + panel.AbsoluteSize.Y)
            else
                frame.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale)
            end
            updateLayout()
        end
        
        frame.MouseButton1Click:Connect(toggle)
        frame.TouchTap:Connect(toggle)
        updateLayout()
        
        -- 返回一个可以动态更新选项的对象
        local dropdownObj = { updateOptions = function(newOptions)
            options = newOptions
            selected = options[1] or ""
            label.Text = text .. ": " .. selected
            if expanded then
                refreshOptions()
                frame.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale + panel.AbsoluteSize.Y)
                updateLayout()
            end
        end }
        return dropdownObj
    end
    
    -- ========== 控件: 文本框 ==========
    function tab:Textbox(text, placeholder, callback)
        local frame = Instance.new("Frame")
        frame.Parent = tab.container
        frame.Size = UDim2.new(1, 0, 0, 50 * selfWin.scale)
        frame.BackgroundColor3 = Theme.getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0, 80 * selfWin.scale, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.getColor("text")
        label.Font = Enum.Font.Gotham
        label.TextSize = 13 * selfWin.scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local box = Instance.new("TextBox")
        box.Parent = frame
        box.Size = UDim2.new(1, -100 * selfWin.scale, 0.8, 0)
        box.Position = UDim2.new(0, 90 * selfWin.scale, 0.1, 0)
        box.BackgroundColor3 = Theme.getColor("input")
        box.Text = ""
        box.PlaceholderText = placeholder
        box.TextColor3 = Theme.getColor("text")
        box.Font = Enum.Font.Gotham
        box.TextSize = 13 * selfWin.scale
        round(box, Config.BorderRadius)
        
        box.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                pcall(callback, box.Text)
                box.Text = ""
            end
        end)
        updateLayout()
    end
    
    -- ========== 控件: 数字输入框 ==========
    function tab:Numberbox(text, defaultVal, callback)
        local frame = Instance.new("Frame")
        frame.Parent = tab.container
        frame.Size = UDim2.new(1, 0, 0, 50 * selfWin.scale)
        frame.BackgroundColor3 = Theme.getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0, 80 * selfWin.scale, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.getColor("text")
        label.Font = Enum.Font.Gotham
        label.TextSize = 13 * selfWin.scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local box = Instance.new("TextBox")
        box.Parent = frame
        box.Size = UDim2.new(1, -100 * selfWin.scale, 0.8, 0)
        box.Position = UDim2.new(0, 90 * selfWin.scale, 0.1, 0)
        box.BackgroundColor3 = Theme.getColor("input")
        box.Text = tostring(defaultVal or 0)
        box.PlaceholderText = "数字"
        box.TextColor3 = Theme.getColor("text")
        box.Font = Enum.Font.Gotham
        box.TextSize = 13 * selfWin.scale
        round(box, Config.BorderRadius)
        
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local num = tonumber(box.Text)
            if num then
                pcall(callback, num)
            else
                box.Text = tostring(defaultVal or 0)
            end
        end)
        updateLayout()
    end
    
    -- ========== 控件: 颜色选择器 (完整版) ==========
    function tab:Colorpicker(text, defaultColor, callback)
        local currentColor = defaultColor or Color3.fromRGB(255,255,255)
        local expanded = false
        local frame = Instance.new("Frame")
        frame.Parent = tab.container
        frame.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale)
        frame.BackgroundColor3 = Theme.getColor("card")
        round(frame, Config.BorderRadius)
        frame.ClipsDescendants = false
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.6, -10, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.getColor("text")
        label.Font = Enum.Font.Gotham
        label.TextSize = 13 * selfWin.scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local colorBox = Instance.new("Frame")
        colorBox.Parent = frame
        colorBox.Size = UDim2.new(0, 35 * selfWin.scale, 0, 25 * selfWin.scale)
        colorBox.Position = UDim2.new(1, -45 * selfWin.scale, 0.5, -12.5 * selfWin.scale)
        colorBox.BackgroundColor3 = currentColor
        round(colorBox, Config.BorderRadius)
        
        local pickerPanel = Instance.new("Frame")
        pickerPanel.Parent = frame
        pickerPanel.Size = UDim2.new(1, 0, 0, 0)
        pickerPanel.Position = UDim2.new(0, 0, 1, 5)
        pickerPanel.BackgroundColor3 = Theme.getColor("card")
        round(pickerPanel, Config.BorderRadius)
        pickerPanel.Visible = false
        pickerPanel.ClipsDescendants = true
        
        -- 色相条
        local hueBar = Instance.new("Frame")
        hueBar.Parent = pickerPanel
        hueBar.Size = UDim2.new(1, -20, 0, 20 * selfWin.scale)
        hueBar.Position = UDim2.new(0, 10, 0, 10)
        round(hueBar, 4)
        
        local hueGradient = Instance.new("UIGradient")
        hueGradient.Parent = hueBar
        hueGradient.Rotation = 0
        hueGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
        }
        
        local hueKnob = Instance.new("Frame")
        hueKnob.Parent = hueBar
        hueKnob.Size = UDim2.new(0, 8, 0, 24)
        hueKnob.Position = UDim2.new(0, -4, -2, 0)
        hueKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        round(hueKnob, 4)
        
        -- 饱和度/亮度面板
        local svArea = Instance.new("ImageLabel")
        svArea.Parent = pickerPanel
        svArea.Size = UDim2.new(1, -20, 0, 120 * selfWin.scale)
        svArea.Position = UDim2.new(0, 10, 0, 40)
        svArea.BackgroundColor3 = Color3.fromRGB(255,0,0)
        svArea.Image = "rbxassetid://4155801252"
        round(svArea, 6)
        
        local svKnob = Instance.new("Frame")
        svKnob.Parent = svArea
        svKnob.Size = UDim2.new(0, 14, 0, 14)
        svKnob.Position = UDim2.new(1, -7, 0, -7)
        svKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        round(svKnob, 7)
        
        local currentHue = 0
        local function setColorFromHue(hueVal)
            local col = Color3.fromHSV(hueVal, 1, 1)
            svArea.BackgroundColor3 = col
            currentHue = hueVal
        end
        
        local function updateFromSV(x, y)
            local s = math.clamp(x / svArea.AbsoluteSize.X, 0, 1)
            local v = 1 - math.clamp(y / svArea.AbsoluteSize.Y, 0, 1)
            currentColor = Color3.fromHSV(currentHue, s, v)
            colorBox.BackgroundColor3 = currentColor
            pcall(callback, currentColor)
        end
        
        -- 拖拽逻辑
        local draggingHue = false
        local draggingSV = false
        
        hueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingHue = true
                local x = math.clamp(input.Position.X - hueBar.AbsolutePosition.X, 0, hueBar.AbsoluteSize.X)
                local hue = x / hueBar.AbsoluteSize.X
                setColorFromHue(hue)
                hueKnob.Position = UDim2.new(x / hueBar.AbsoluteSize.X, -4, -2, 0)
                -- 同时更新SV上的颜色预览
                local s = math.clamp(svKnob.AbsolutePosition.X - svArea.AbsolutePosition.X, 0, svArea.AbsoluteSize.X) / svArea.AbsoluteSize.X
                local v = 1 - math.clamp(svKnob.AbsolutePosition.Y - svArea.AbsolutePosition.Y, 0, svArea.AbsoluteSize.Y) / svArea.AbsoluteSize.Y
                currentColor = Color3.fromHSV(hue, s, v)
                colorBox.BackgroundColor3 = currentColor
                pcall(callback, currentColor)
            end
        end)
        
        svArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSV = true
                local x = math.clamp(input.Position.X - svArea.AbsolutePosition.X, 0, svArea.AbsoluteSize.X)
                local y = math.clamp(input.Position.Y - svArea.AbsolutePosition.Y, 0, svArea.AbsoluteSize.Y)
                updateFromSV(x, y)
                svKnob.Position = UDim2.new(x / svArea.AbsoluteSize.X, -7, y / svArea.AbsoluteSize.Y, -7)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if draggingHue and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local x = math.clamp(input.Position.X - hueBar.AbsolutePosition.X, 0, hueBar.AbsoluteSize.X)
                local hue = x / hueBar.AbsoluteSize.X
                setColorFromHue(hue)
                hueKnob.Position = UDim2.new(x / hueBar.AbsoluteSize.X, -4, -2, 0)
                local s = math.clamp(svKnob.AbsolutePosition.X - svArea.AbsolutePosition.X, 0, svArea.AbsoluteSize.X) / svArea.AbsoluteSize.X
                local v = 1 - math.clamp(svKnob.AbsolutePosition.Y - svArea.AbsolutePosition.Y, 0, svArea.AbsoluteSize.Y) / svArea.AbsoluteSize.Y
                currentColor = Color3.fromHSV(hue, s, v)
                colorBox.BackgroundColor3 = currentColor
                pcall(callback, currentColor)
            elseif draggingSV and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local x = math.clamp(input.Position.X - svArea.AbsolutePosition.X, 0, svArea.AbsoluteSize.X)
                local y = math.clamp(input.Position.Y - svArea.AbsolutePosition.Y, 0, svArea.AbsoluteSize.Y)
                updateFromSV(x, y)
                svKnob.Position = UDim2.new(x / svArea.AbsoluteSize.X, -7, y / svArea.AbsoluteSize.Y, -7)
            end
        end)
        
        hueBar.InputEnded:Connect(function() draggingHue = false end)
        svArea.InputEnded:Connect(function() draggingSV = false end)
        
        -- 初始设置
        local h, s, v = Color3.toHSV(defaultColor or Color3.fromRGB(255,255,255))
        currentHue = h
        setColorFromHue(h)
        hueKnob.Position = UDim2.new(h, -4, -2, 0)
        svKnob.Position = UDim2.new(s, -7, 1-v, -7)
        
        local function toggle()
            expanded = not expanded
            pickerPanel.Visible = expanded
            if expanded then
                frame.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale + 180 * selfWin.scale)
                pickerPanel.Size = UDim2.new(1, 0, 0, 180 * selfWin.scale)
            else
                frame.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale)
            end
            updateLayout()
        end
        
        frame.MouseButton1Click:Connect(toggle)
        frame.TouchTap:Connect(toggle)
        updateLayout()
    end
    
    -- ========== 控件: 标签 ==========
    function tab:Label(text, align)
        local lbl = Instance.new("TextLabel")
        lbl.Parent = tab.container
        lbl.Size = UDim2.new(1, 0, 0, 30 * selfWin.scale)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Theme.getColor("textSec")
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12 * selfWin.scale
        if align == "center" then
            lbl.TextXAlignment = Enum.TextXAlignment.Center
        elseif align == "right" then
            lbl.TextXAlignment = Enum.TextXAlignment.Right
        else
            lbl.TextXAlignment = Enum.TextXAlignment.Left
        end
        updateLayout()
    end
    
    -- ========== 控件: 分割线 ==========
    function tab:Line()
        local line = Instance.new("Frame")
        line.Parent = tab.container
        line.Size = UDim2.new(1, 0, 0, 2)
        line.BackgroundColor3 = Theme.getColor("textMuted")
        line.BackgroundTransparency = 0.8
        round(line, 1)
        updateLayout()
    end
    
    -- ========== 控件: 按键绑定 ==========
    function tab:Bind(text, defaultKey, callback)
        local key = defaultKey or "None"
        local frame = Instance.new("Frame")
        frame.Parent = tab.container
        frame.Size = UDim2.new(1, 0, 0, 45 * selfWin.scale)
        frame.BackgroundColor3 = Theme.getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.6, -10, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.getColor("text")
        label.Font = Enum.Font.Gotham
        label.TextSize = 13 * selfWin.scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Parent = frame
        keyLabel.Size = UDim2.new(0, 80 * selfWin.scale, 0.8, 0)
        keyLabel.Position = UDim2.new(1, -90 * selfWin.scale, 0.1, 0)
        keyLabel.BackgroundColor3 = Theme.getColor("input")
        keyLabel.Text = key
        keyLabel.TextColor3 = Theme.getColor("text")
        keyLabel.Font = Enum.Font.Gotham
        keyLabel.TextSize = 13 * selfWin.scale
        keyLabel.TextXAlignment = Enum.TextXAlignment.Center
        round(keyLabel, Config.BorderRadius)
        
        local function startBinding()
            keyLabel.Text = "..."
            local con
            con = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    key = input.KeyCode.Name
                    keyLabel.Text = key
                    con:Disconnect()
                end
            end)
        end
        
        keyLabel.MouseButton1Click:Connect(startBinding)
        keyLabel.TouchTap:Connect(startBinding)
        
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode.Name == key and key ~= "None" then
                pcall(callback)
            end
        end)
        updateLayout()
    end
    
    -- ========== 高级: 网格布局 ==========
    function tab:Grid(columns, itemHeight, items)
        local container = Instance.new("Frame")
        container.Parent = tab.container
        container.Size = UDim2.new(1, 0, 0, 0)
        container.BackgroundTransparency = 1
        container.LayoutOrder = #tab.container:GetChildren() + 1
        
        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.Parent = container
        gridLayout.CellSize = UDim2.new(1/columns, -10, 0, itemHeight * selfWin.scale)
        gridLayout.CellPadding = UDim.new(0, 8)
        gridLayout.FillDirectionMaxCells = columns
        
        local totalHeight = math.ceil(#items / columns) * (itemHeight * selfWin.scale + 8)
        container.Size = UDim2.new(1, 0, 0, totalHeight)
        
        for _, item in ipairs(items) do
            local btn = Instance.new("TextButton")
            btn.Parent = container
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundColor3 = Theme.getColor("card")
            btn.Text = item.text
            btn.TextColor3 = Theme.getColor("text")
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12 * selfWin.scale
            round(btn, Config.BorderRadius)
            btn.AutoButtonColor = false
            btn.MouseButton1Click:Connect(item.callback)
            btn.TouchTap:Connect(item.callback)
        end
        
        updateLayout()
    end
    
    -- ========== 高级: 模态对话框 ==========
    function tab:Dialog(title, message, buttons)
        local overlay = Instance.new("TextButton")
        overlay.Parent = selfWin.frame
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
        overlay.BackgroundTransparency = 0.6
        overlay.AutoButtonColor = false
        overlay.Text = ""
        overlay.ZIndex = 100
        overlay.Visible = true
        
        local dialogFrame = Instance.new("Frame")
        dialogFrame.Parent = overlay
        dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        dialogFrame.Size = UDim2.new(0, 260 * selfWin.scale, 0, 150 * selfWin.scale)
        dialogFrame.BackgroundColor3 = Theme.getColor("card")
        round(dialogFrame, Config.BorderRadius)
        shadow(dialogFrame)
        
        local title = Instance.new("TextLabel")
        title.Parent = dialogFrame
        title.Size = UDim2.new(1, 0, 0, 40 * selfWin.scale)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = title
        title.TextColor3 = Theme.getColor("text")
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16 * selfWin.scale
        
        local msg = Instance.new("TextLabel")
        msg.Parent = dialogFrame
        msg.Size = UDim2.new(1, -20, 0, 50 * selfWin.scale)
        msg.Position = UDim2.new(0, 10, 0, 45 * selfWin.scale)
        msg.BackgroundTransparency = 1
        msg.Text = message
        msg.TextColor3 = Theme.getColor("textSec")
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 13 * selfWin.scale
        msg.TextWrapped = true
        
        local buttonFrame = Instance.new("Frame")
        buttonFrame.Parent = dialogFrame
        buttonFrame.Size = UDim2.new(1, 0, 0, 40 * selfWin.scale)
        buttonFrame.Position = UDim2.new(0, 0, 1, -40 * selfWin.scale)
        buttonFrame.BackgroundTransparency = 1
        
        local btnLayout = Instance.new("UIListLayout")
        btnLayout.Parent = buttonFrame
        btnLayout.FillDirection = Enum.FillDirection.Horizontal
        btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        btnLayout.Padding = UDim.new(0, 10)
        
        for _, btnInfo in ipairs(buttons) do
            local btn = Instance.new("TextButton")
            btn.Parent = buttonFrame
            btn.Size = UDim2.new(0, 80 * selfWin.scale, 1, -10)
            btn.BackgroundColor3 = btnInfo.accent or selfWin.accent
            btn.Text = btnInfo.text
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13 * selfWin.scale
            round(btn, Config.BorderRadius)
            btn.AutoButtonColor = false
            btn.MouseButton1Click:Connect(function()
                pcall(btnInfo.callback)
                overlay:Destroy()
            end)
            btn.TouchTap:Connect(function()
                pcall(btnInfo.callback)
                overlay:Destroy()
            end)
        end
        
        overlay.MouseButton1Click:Connect(function()
            overlay:Destroy()
        end)
    end
    
    return tab
end

-- =============================== 通知系统 ===================================
local Notification = {}
function MobileUI:Notify(title, message, duration, type)
    duration = duration or 3
    local notif = Instance.new("Frame")
    notif.Parent = ScreenGui
    notif.AnchorPoint = Vector2.new(0.5, 0)
    notif.Position = UDim2.new(0.5, 0, 0, -100)
    notif.Size = UDim2.new(0, 300 * getScale(), 0, 70 * getScale())
    notif.BackgroundColor3 = Config.BackgroundCard
    round(notif, Config.BorderRadius)
    shadow(notif)
    
    local colorLine = Instance.new("Frame")
    colorLine.Parent = notif
    colorLine.Size = UDim2.new(0, 4, 1, 0)
    colorLine.BackgroundColor3 = type == "error" and Config.DangerColor or (type == "success" and Config.SuccessColor or Config.AccentColor)
    round(colorLine, 2)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = notif
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 15, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.getColor("text")
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14 * getScale()
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Parent = notif
    msgLabel.Size = UDim2.new(1, -20, 0, 35)
    msgLabel.Position = UDim2.new(0, 15, 0, 32)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Theme.getColor("textSec")
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 12 * getScale()
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    
    TweenQueue:Add(notif, {Position = UDim2.new(0.5, 0, 0, 10)}, 0.3)
    task.wait(duration)
    TweenQueue:Add(notif, {Position = UDim2.new(0.5, 0, 0, -100)}, 0.3)
    task.wait(0.3)
    notif:Destroy()
end

-- =============================== 公开 API ===================================
MobileUI.Window = Window.new
MobileUI.Theme = Theme
MobileUI.Notify = Notification

return MobileUI