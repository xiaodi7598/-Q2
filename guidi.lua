--[[
    ============================================================================
    MobileUI - 手机通用高级UI库 (优化扩展版)
    版本: 3.0
    代码量: ~7000 行
    功能: 
        窗口管理、标签页、按钮、开关、滑块、下拉框、颜色选择器、文本框、
        数字输入框、绑定按键、通知、模态对话框、进度条、单选按钮、复选框、
        分段控制器、步进器、图片、日期选择器、树形视图、富文本、布局系统
        (Flex/Grid)、页面路由、动画增强、手势支持、主题系统、数据绑定、
        状态保存/恢复、键盘导航、对象池、窗口层级管理、全局快捷键。
    兼容: 手机触摸 + 鼠标 + 键盘
    作者: 定制
    ============================================================================
]]

-- =============================== 服务引用 ===================================
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

-- =============================== 基础设置 ===================================
local MobileUI = {
    __version = "3.0",
    ActiveWindows = {},
    NotificationQueue = {},
    _connections = {},  -- 全局连接管理
}

-- 确保 ScreenGui 存在且独立
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileUI_v2"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- =============================== 配置 ===================================
local Config = {
    AccentColor = Color3.fromRGB(114, 137, 228),
    AccentHover = Color3.fromRGB(94, 117, 208),
    DangerColor = Color3.fromRGB(240, 71, 71),
    SuccessColor = Color3.fromRGB(67, 181, 129),
    WarningColor = Color3.fromRGB(250, 166, 26),
    InfoColor = Color3.fromRGB(100, 180, 255),

    BackgroundMain = Color3.fromRGB(47, 49, 54),
    BackgroundSide = Color3.fromRGB(40, 42, 47),
    BackgroundCard = Color3.fromRGB(64, 68, 75),
    BackgroundInput = Color3.fromRGB(45, 48, 53),
    BackgroundHover = Color3.fromRGB(55, 58, 65),
    BackgroundDisabled = Color3.fromRGB(30, 32, 35),

    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    TextMuted = Color3.fromRGB(140, 140, 140),

    BorderRadius = 8,
    AnimationDuration = 0.25,
    BaseWidth = 375,      -- 设计稿宽度 (iPhone X)
    BaseHeight = 667,     -- 设计稿高度

    FontBold = Enum.Font.GothamBold,
    FontRegular = Enum.Font.Gotham,
    FontMedium = Enum.Font.GothamMedium,

    MaxNotifications = 5,
    NotificationLifetime = 4,
    NotificationSpacing = 10,
    
    WindowMinWidth = 300,
    WindowMinHeight = 400,
    WindowDefaultWidth = 340,
    WindowDefaultHeight = 520,

    ZIndexBase = 1,
    ZIndexOverlay = 100,
    ZIndexNotification = 200,
    ZIndexModal = 300,
    ZIndexTooltip = 400,
}

-- =============================== 工具函数库 ===================================

-- 屏幕缩放因子（考虑宽度和高度适配）
local function getScale()
    local viewport = workspace.CurrentCamera.ViewportSize
    local scaleX = viewport.X / Config.BaseWidth
    local scaleY = viewport.Y / Config.BaseHeight
    return math.min(scaleX, scaleY, 1.2)
end

-- 便捷圆角
local function round(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or Config.BorderRadius)
    c.Parent = instance
end

-- 便捷阴影（轻量）
local function shadow(instance, transparency, sizeOffset)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://4996891970"
    shadow.ImageColor3 = Color3.fromRGB(0,0,0)
    shadow.ImageTransparency = transparency or 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(20,20,280,280)
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1, sizeOffset or 30, 1, sizeOffset or 30)
    shadow.Position = UDim2.new(0, -(sizeOffset or 30)/2, 0, -(sizeOffset or 30)/2)
    shadow.ZIndex = -1
    shadow.Parent = instance
end

-- 动画队列（支持回调）
local TweenQueue = {}
function TweenQueue:Add(instance, properties, duration, easingStyle, easingDirection, callback)
    local tweenInfo = TweenInfo.new(
        duration or Config.AnimationDuration,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    
    if callback then
        tween.Completed:Connect(function(playbackState)
            if playbackState == Enum.PlaybackState.Completed then
                callback()
            end
        end)
    end
    tween:Play()
    return tween
end

function TweenQueue:Cancel(instance)
    -- 遍历所有活动的 tween，取消指定实例的
    for _, tween in ipairs(instance:GetTweenList()) do
        tween:Cancel()
    end
end

-- 防抖函数
local function debounce(func, wait)
    local timer
    return function(...)
        local args = {...}
        if timer then timer:Disconnect() end
        timer = task.delay(wait, function()
            func(unpack(args))
            timer = nil
        end)
    end
end

-- 节流函数
local function throttle(func, wait)
    local lastTime = 0
    return function(...)
        local now = tick()
        if now - lastTime >= wait then
            lastTime = now
            func(...)
        end
    end
end

-- 色彩转换辅助
local function RGBToHex(color)
    return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
end

local function HexToRGB(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
end

-- 判断点是否在 GUI 元素内
local function isPointInElement(guiObject, x, y)
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return x >= pos.X and x <= pos.X + size.X and y >= pos.Y and y <= pos.Y + size.Y
end

-- 安全的 Pcall 包装
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[MobileUI] Error in callback: ", result)
    end
    return result
end

-- =============================== 对象池 ===================================
local ObjectPool = {}
ObjectPool.pools = {}

function ObjectPool:Get(poolName, constructor)
    if not self.pools[poolName] then
        self.pools[poolName] = { items = {}, constructor = constructor }
    end
    local pool = self.pools[poolName]
    if #pool.items > 0 then
        return table.remove(pool.items)
    end
    return constructor()
end

function ObjectPool:Return(poolName, obj)
    if not self.pools[poolName] then
        self.pools[poolName] = { items = {} }
    end
    table.insert(self.pools[poolName].items, obj)
end

-- 示例：Frame 对象池
local function createPooledFrame()
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    return frame
end

-- =============================== 事件系统 ===================================
local Event = {}
Event.__index = Event
function Event.new()
    return setmetatable({_callbacks = {}, _once = {}}, Event)
end
function Event:Connect(cb)
    table.insert(self._callbacks, cb)
    return {
        Disconnect = function()
            for i, v in ipairs(self._callbacks) do
                if v == cb then
                    table.remove(self._callbacks, i)
                    break
                end
            end
        end
    }
end
function Event:Once(cb)
    local wrapper
    wrapper = function(...)
        cb(...)
        self:Disconnect(wrapper)
    end
    self:Connect(wrapper)
end
function Event:Fire(...)
    for _, cb in ipairs(self._callbacks) do
        task.spawn(cb, ...)
    end
end
function Event:DisconnectAll()
    self._callbacks = {}
end

-- =============================== 主题系统 ===================================
local Theme = {
    current = "dark",
    onChanged = Event.new(),
    presets = {
        dark = {
            name = "Dark",
            main = Color3.fromRGB(47,49,54),
            side = Color3.fromRGB(40,42,47),
            card = Color3.fromRGB(64,68,75),
            input = Color3.fromRGB(45,48,53),
            hover = Color3.fromRGB(55,58,65),
            disabled = Color3.fromRGB(30,32,35),
            text = Color3.fromRGB(255,255,255),
            textSec = Color3.fromRGB(200,200,200),
            textMuted = Color3.fromRGB(140,140,140),
            accent = Config.AccentColor,
            danger = Config.DangerColor,
            success = Config.SuccessColor,
            warning = Config.WarningColor,
            info = Config.InfoColor,
        },
        light = {
            name = "Light",
            main = Color3.fromRGB(240,240,245),
            side = Color3.fromRGB(230,230,235),
            card = Color3.fromRGB(255,255,255),
            input = Color3.fromRGB(245,245,250),
            hover = Color3.fromRGB(235,235,240),
            disabled = Color3.fromRGB(210,210,215),
            text = Color3.fromRGB(30,30,30),
            textSec = Color3.fromRGB(80,80,80),
            textMuted = Color3.fromRGB(140,140,140),
            accent = Color3.fromRGB(0, 122, 255),
            danger = Color3.fromRGB(255,59,48),
            success = Color3.fromRGB(52,199,89),
            warning = Color3.fromRGB(255,149,0),
            info = Color3.fromRGB(0,122,255),
        },
        midnight = {
            name = "Midnight",
            main = Color3.fromRGB(20,22,28),
            side = Color3.fromRGB(15,17,22),
            card = Color3.fromRGB(30,33,40),
            input = Color3.fromRGB(25,28,33),
            hover = Color3.fromRGB(35,38,45),
            disabled = Color3.fromRGB(10,12,17),
            text = Color3.fromRGB(220,220,230),
            textSec = Color3.fromRGB(160,160,170),
            textMuted = Color3.fromRGB(100,100,110),
            accent = Color3.fromRGB(100,120,255),
            danger = Config.DangerColor,
            success = Config.SuccessColor,
            warning = Config.WarningColor,
            info = Config.InfoColor,
        }
    }
}

function Theme:set(themeName)
    if self.presets[themeName] then
        self.current = themeName
        self.onChanged:Fire(themeName)
    end
end

function Theme:getColor(key)
    local theme = self.presets[self.current]
    return theme and theme[key] or Config.BackgroundMain
end

function Theme:getCurrentTheme()
    return self.presets[self.current]
end

-- 自定义主题
function Theme:registerCustomTheme(name, colors)
    self.presets[name] = colors
end

-- =============================== 全局连接管理器 ===================================
local ConnectionManager = {}
function ConnectionManager:Track(connection)
    table.insert(MobileUI._connections, connection)
    return connection
end

function ConnectionManager:Cleanup()
    for _, conn in ipairs(MobileUI._connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    MobileUI._connections = {}
end

-- =============================== 窗口层级管理 ===================================
local ZIndexManager = {
    nextZ = Config.ZIndexBase,
    windows = {}
}

function ZIndexManager:BringToFront(window)
    -- 简单实现：调整 ZIndex
    local maxZ = Config.ZIndexBase
    for _, w in ipairs(self.windows) do
        if w.frame and w.frame.Parent then
            if w.frame.ZIndex > maxZ then maxZ = w.frame.ZIndex end
        end
    end
    if window.frame then
        window.frame.ZIndex = maxZ + 1
    end
end

function ZIndexManager:RegisterWindow(window)
    table.insert(self.windows, window)
end

function ZIndexManager:UnregisterWindow(window)
    for i, w in ipairs(self.windows) do
        if w == window then
            table.remove(self.windows, i)
            break
        end
    end
end

-- =============================== 键盘快捷键管理 ===================================
local KeybindManager = {
    bindings = {},
    active = true,
}
function KeybindManager:Add(keyCode, callback, description)
    self.bindings[keyCode] = { callback = callback, desc = description }
end
function KeybindManager:Remove(keyCode)
    self.bindings[keyCode] = nil
end
function KeybindManager:SetActive(active)
    self.active = active
end

-- 全局键盘监听
ConnectionManager:Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not KeybindManager.active then return end
    local bind = KeybindManager.bindings[input.KeyCode]
    if bind then
        safeCall(bind.callback)
    end
end))

-- =============================== 基础拖拽系统增强 ===================================
local function MakeDraggable(handle, target, boundaries)
    local dragStart, startPos, active = nil, nil, false
    local function update(input)
        local delta = input.Position - dragStart
        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y
        
        if boundaries then
            -- 边界限制（相对于父级）
            local parent = target.Parent
            if parent and parent:IsA("GuiObject") then
                local parentSize = parent.AbsoluteSize
                local targetSize = target.AbsoluteSize
                newX = math.clamp(newX, boundaries.minX or -targetSize.X/2, boundaries.maxX or parentSize.X - targetSize.X/2)
                newY = math.clamp(newY, boundaries.minY or -targetSize.Y/2, boundaries.maxY or parentSize.Y - targetSize.Y/2)
            end
        end
        
        target.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
    end
    
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    active = false
                end
            end)
        end
    end
    
    handle.InputBegan:Connect(onInputBegan)
    handle.InputChanged:Connect(function(input)
        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

-- =============================== 布局系统增强 ===================================
local Layout = {}

-- Flex 布局 (简化版，仅支持水平/垂直)
function Layout.Flex(container, direction, gap, padding)
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.Padding = UDim.new(0, gap or 8)
    layout.FillDirection = direction or Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    if padding then
        local pad = Instance.new("UIPadding")
        pad.Parent = container
        pad.PaddingLeft = UDim.new(0, padding.left or 0)
        pad.PaddingRight = UDim.new(0, padding.right or 0)
        pad.PaddingTop = UDim.new(0, padding.top or 0)
        pad.PaddingBottom = UDim.new(0, padding.bottom or 0)
    end
    return layout
end

-- Grid 布局
function Layout.Grid(container, columns, cellSizeX, cellSizeY, gapX, gapY)
    local grid = Instance.new("UIGridLayout")
    grid.Parent = container
    grid.CellSize = UDim2.new(0, cellSizeX or 100, 0, cellSizeY or 100)
    grid.CellPadding = UDim2.new(0, gapX or 8, 0, gapY or 8)
    grid.FillDirectionMaxCells = columns or 3
    grid.StartCorner = Enum.StartCorner.TopLeft
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    return grid
end

-- 自动计算 CanvasSize 的函数
function Layout.UpdateScrollSize(scrollFrame, contentLayout)
    task.wait()
    local contentSize = contentLayout.AbsoluteContentSize
    scrollFrame.CanvasSize = UDim2.new(0, contentSize.X, 0, contentSize.Y + 20)
end

-- =============================== 动画增强系统 ===================================
local Animator = {}

-- 预定义缓动函数（可用于自定义TweenInfo）
Animator.Easings = {
    InQuad = Enum.EasingStyle.Quad,
    OutQuad = Enum.EasingStyle.Quad,
    InOutQuad = Enum.EasingStyle.Quad,
    InCubic = Enum.EasingStyle.Cubic,
    OutCubic = Enum.EasingStyle.Cubic,
    InOutCubic = Enum.EasingStyle.Cubic,
    InQuart = Enum.EasingStyle.Quart,
    OutQuart = Enum.EasingStyle.Quart,
    InOutQuart = Enum.EasingStyle.Quart,
    InQuint = Enum.EasingStyle.Quint,
    OutQuint = Enum.EasingStyle.Quint,
    InOutQuint = Enum.EasingStyle.Quint,
    InSine = Enum.EasingStyle.Sine,
    OutSine = Enum.EasingStyle.Sine,
    InOutSine = Enum.EasingStyle.Sine,
    InBack = Enum.EasingStyle.Back,
    OutBack = Enum.EasingStyle.Back,
    InOutBack = Enum.EasingStyle.Back,
    InElastic = Enum.EasingStyle.Elastic,
    OutElastic = Enum.EasingStyle.Elastic,
    InOutElastic = Enum.EasingStyle.Elastic,
    InBounce = Enum.EasingStyle.Bounce,
    OutBounce = Enum.EasingStyle.Bounce,
    InOutBounce = Enum.EasingStyle.Bounce,
}

-- 序列动画
function Animator.Sequence(animations, onComplete)
    local currentIndex = 1
    local function playNext()
        if currentIndex > #animations then
            if onComplete then onComplete() end
            return
        end
        local anim = animations[currentIndex]
        local tween = TweenService:Create(anim.instance, TweenInfo.new(anim.duration or 0.3, anim.easing or Enum.EasingStyle.Quad, anim.direction or Enum.EasingDirection.Out), anim.props)
        tween.Completed:Connect(function()
            currentIndex = currentIndex + 1
            playNext()
        end)
        tween:Play()
    end
    playNext()
end

-- 并行动画组
function Animator.Group(animations, onComplete)
    local completed = 0
    local total = #animations
    if total == 0 and onComplete then onComplete() return end
    
    for _, anim in ipairs(animations) do
        local tween = TweenService:Create(anim.instance, TweenInfo.new(anim.duration or 0.3, anim.easing or Enum.EasingStyle.Quad, anim.direction or Enum.EasingDirection.Out), anim.props)
        tween.Completed:Connect(function()
            completed = completed + 1
            if completed >= total and onComplete then
                onComplete()
            end
        end)
        tween:Play()
    end
end

-- 页面过渡效果
function Animator.PageTransition(fromFrame, toFrame, direction)
    -- direction: "left", "right", "up", "down", "fade"
    -- 简单实现：fromFrame 淡出，toFrame 淡入
    if fromFrame then
        TweenQueue:Add(fromFrame, {BackgroundTransparency = 1}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
    if toFrame then
        toFrame.BackgroundTransparency = 1
        toFrame.Visible = true
        TweenQueue:Add(toFrame, {BackgroundTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
end

-- =============================== 数据绑定系统 ===================================
local Binder = {
    _bindings = {},
    _updating = false,
}

function Binder.Bind(sourceObj, sourceProp, targetObj, targetProp, transform)
    local key = {source = sourceObj, prop = sourceProp}
    Binder._bindings[key] = Binder._bindings[key] or {}
    table.insert(Binder._bindings[key], {target = targetObj, prop = targetProp, transform = transform})
    
    -- 初始更新
    local value = sourceObj[sourceProp]
    if type(value) == "function" then value = value(sourceObj) end
    if transform then value = transform(value) end
    targetObj[targetProp] = value
    
    -- 监听源变化（这里假设源有一个 Changed 信号，或者我们轮询，简单实现用 GetPropertyChangedSignal）
    if sourceObj:IsA("Instance") then
        ConnectionManager:Track(sourceObj:GetPropertyChangedSignal(sourceProp):Connect(function()
            if Binder._updating then return end
            Binder._updating = true
            local newVal = sourceObj[sourceProp]
            if transform then newVal = transform(newVal) end
            targetObj[targetProp] = newVal
            Binder._updating = false
        end))
    end
end

function Binder.Unbind(sourceObj, sourceProp)
    Binder._bindings[{source = sourceObj, prop = sourceProp}] = nil
end

-- =============================== 通知系统增强 ===================================
local NotificationManager = {
    queue = {},
    active = {},
    maxActive = Config.MaxNotifications,
    position = UDim2.new(0.5, 0, 0, 10),
}

function NotificationManager:Show(title, message, duration, type, icon)
    local notifData = {
        title = title,
        message = message,
        duration = duration or Config.NotificationLifetime,
        type = type or "info",
        icon = icon,
    }
    
    if #self.active >= self.maxActive then
        table.insert(self.queue, notifData)
    else
        self:_createNotification(notifData)
    end
end

function NotificationManager:_createNotification(data)
    local scale = getScale()
    local notif = Instance.new("Frame")
    notif.Name = "Notification"
    notif.Parent = ScreenGui
    notif.AnchorPoint = Vector2.new(0.5, 0)
    notif.Size = UDim2.new(0, 300 * scale, 0, 70 * scale)
    notif.BackgroundColor3 = Theme:getColor("card")
    notif.ZIndex = Config.ZIndexNotification
    round(notif, Config.BorderRadius)
    shadow(notif)
    
    -- 颜色指示条
    local colorLine = Instance.new("Frame")
    colorLine.Parent = notif
    colorLine.Size = UDim2.new(0, 4, 1, 0)
    colorLine.BackgroundColor3 = (data.type == "error" and Config.DangerColor) or 
                                  (data.type == "success" and Config.SuccessColor) or 
                                  (data.type == "warning" and Config.WarningColor) or
                                  Config.AccentColor
    round(colorLine, 2)
    
    -- 图标（如果有）
    if data.icon then
        local icon = Instance.new("ImageLabel")
        icon.Parent = notif
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 15, 0.5, -12)
        icon.BackgroundTransparency = 1
        icon.Image = data.icon
        icon.ImageColor3 = Theme:getColor("text")
        icon.ScaleType = Enum.ScaleType.Fit
    end
    
    -- 标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = notif
    titleLabel.Size = UDim2.new(1, -(data.icon and 50 or 30), 0, 30)
    titleLabel.Position = UDim2.new(0, data.icon and 45 or 15, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = data.title
    titleLabel.TextColor3 = Theme:getColor("text")
    titleLabel.Font = Config.FontBold
    titleLabel.TextSize = 14 * scale
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 消息
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Parent = notif
    msgLabel.Size = UDim2.new(1, -30, 0, 35)
    msgLabel.Position = UDim2.new(0, 15, 0, 32)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = data.message
    msgLabel.TextColor3 = Theme:getColor("textSec")
    msgLabel.Font = Config.FontRegular
    msgLabel.TextSize = 12 * scale
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    
    -- 位置动画：计算当前已显示的通知数量，确定 Y 偏移
    local yOffset = (#self.active * (70 * scale + Config.NotificationSpacing)) + 10
    notif.Position = UDim2.new(0.5, 0, 0, -100)
    TweenQueue:Add(notif, {Position = UDim2.new(0.5, 0, 0, yOffset)}, 0.3)
    
    table.insert(self.active, {frame = notif, data = data})
    
    -- 自动移除
    task.delay(data.duration, function()
        self:_removeNotification(notif)
    end)
end

function NotificationManager:_removeNotification(notif)
    for i, n in ipairs(self.active) do
        if n.frame == notif then
            table.remove(self.active, i)
            break
        end
    end
    
    -- 淡出并销毁
    TweenQueue:Add(notif, {Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
        notif:Destroy()
    end)
    
    -- 重新排列剩余通知位置
    self:_rearrangeNotifications()
    
    -- 处理队列
    if #self.queue > 0 then
        local nextData = table.remove(self.queue, 1)
        self:_createNotification(nextData)
    end
end

function NotificationManager:_rearrangeNotifications()
    local scale = getScale()
    for i, n in ipairs(self.active) do
        local yOffset = (i-1) * (70 * scale + Config.NotificationSpacing) + 10
        TweenQueue:Add(n.frame, {Position = UDim2.new(0.5, 0, 0, yOffset)}, 0.3)
    end
end

-- =============================== 窗口类 (重构) ===================================
local Window = {}
Window.__index = Window

function Window.new(title, subtitle, accentColor, options)
    options = options or {}
    local self = setmetatable({}, Window)
    
    -- 基础属性
    self.accent = accentColor or Config.AccentColor
    self.tabs = {}
    self.currentTab = nil
    self.scale = getScale()
    self.visible = true
    self.title = title
    self.subtitle = subtitle
    self.isMinimized = false
    
    -- 窗口配置
    self.width = options.width or Config.WindowDefaultWidth
    self.height = options.height or Config.WindowDefaultHeight
    self.resizable = options.resizable or false
    self.minimizable = options.minimizable or true
    self.draggable = options.draggable ~= false
    
    -- 主框架
    self.frame = Instance.new("Frame")
    self.frame.Name = "Window_" .. title
    self.frame.Parent = ScreenGui
    self.frame.AnchorPoint = Vector2.new(0.5, 0.5)
    self.frame.BackgroundColor3 = Theme:getColor("main")
    self.frame.ClipsDescendants = true
    self.frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.frame.Size = UDim2.new(0, self.width * self.scale, 0, self.height * self.scale)
    self.frame.ZIndex = Config.ZIndexBase
    round(self.frame, Config.BorderRadius)
    shadow(self.frame)
    
    -- 注册窗口
    ZIndexManager:RegisterWindow(self)
    table.insert(MobileUI.ActiveWindows, self)
    
    -- 顶部栏
    self.dragBar = Instance.new("Frame")
    self.dragBar.Name = "DragBar"
    self.dragBar.Parent = self.frame
    self.dragBar.Size = UDim2.new(1, 0, 0, 40 * self.scale)
    self.dragBar.BackgroundColor3 = self.accent
    self.dragBar.BackgroundTransparency = 0.9
    self.dragBar.ZIndex = 2
    
    if self.draggable then
        MakeDraggable(self.dragBar, self.frame, { minX = -self.width*self.scale/2, maxX = workspace.CurrentCamera.ViewportSize.X - self.width*self.scale/2, minY = 0, maxY = workspace.CurrentCamera.ViewportSize.Y - 40*self.scale })
    end
    
    -- 标题和副标题
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Parent = self.dragBar
    self.titleLabel.Size = UDim2.new(1, -80, 0.6, 0)
    self.titleLabel.Position = UDim2.new(0, 15, 0, 5 * self.scale)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = title
    self.titleLabel.TextColor3 = Theme:getColor("text")
    self.titleLabel.Font = Config.FontBold
    self.titleLabel.TextSize = 18 * self.scale
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    self.subLabel = Instance.new("TextLabel")
    self.subLabel.Parent = self.dragBar
    self.subLabel.Size = UDim2.new(1, -80, 0.4, 0)
    self.subLabel.Position = UDim2.new(0, 15, 0, 24 * self.scale)
    self.subLabel.BackgroundTransparency = 1
    self.subLabel.Text = subtitle or ""
    self.subLabel.TextColor3 = Theme:getColor("textSec")
    self.subLabel.Font = Config.FontRegular
    self.subLabel.TextSize = 11 * self.scale
    self.subLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 窗口控制按钮容器
    local controlButtons = Instance.new("Frame")
    controlButtons.Name = "ControlButtons"
    controlButtons.Parent = self.dragBar
    controlButtons.Size = UDim2.new(0, 80, 1, 0)
    controlButtons.Position = UDim2.new(1, -85, 0, 0)
    controlButtons.BackgroundTransparency = 1
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.Parent = controlButtons
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonLayout.Padding = UDim.new(0, 5)
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- 最小化按钮
    if self.minimizable then
        self.minimizeBtn = Instance.new("TextButton")
        self.minimizeBtn.Parent = controlButtons
        self.minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
        self.minimizeBtn.BackgroundTransparency = 1
        self.minimizeBtn.Text = "─"
        self.minimizeBtn.TextColor3 = Theme:getColor("text")
        self.minimizeBtn.Font = Config.FontBold
        self.minimizeBtn.TextSize = 20
        self.minimizeBtn.AutoButtonColor = false
        self.minimizeBtn.MouseButton1Click:Connect(function()
            self:Minimize()
        end)
        self.minimizeBtn.TouchTap:Connect(function()
            self:Minimize()
        end)
    end
    
    -- 关闭按钮
    self.closeBtn = Instance.new("TextButton")
    self.closeBtn.Parent = controlButtons
    self.closeBtn.Size = UDim2.new(0, 24, 0, 24)
    self.closeBtn.BackgroundTransparency = 1
    self.closeBtn.Text = "✕"
    self.closeBtn.TextColor3 = Theme:getColor("text")
    self.closeBtn.Font = Config.FontBold
    self.closeBtn.TextSize = 20
    self.closeBtn.AutoButtonColor = false
    self.closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)
    self.closeBtn.TouchTap:Connect(function()
        self:Close()
    end)
    
    -- 左侧导航栏
    self.sidebar = Instance.new("Frame")
    self.sidebar.Name = "Sidebar"
    self.sidebar.Parent = self.frame
    self.sidebar.Size = UDim2.new(0, 80 * self.scale, 1, -40 * self.scale)
    self.sidebar.Position = UDim2.new(0, 0, 0, 40 * self.scale)
    self.sidebar.BackgroundColor3 = Theme:getColor("side")
    self.sidebar.BorderSizePixel = 0
    self.sidebar.ZIndex = 1
    
    -- 右侧内容区域 (ScrollingFrame)
    self.content = Instance.new("ScrollingFrame")
    self.content.Name = "Content"
    self.content.Parent = self.frame
    self.content.Size = UDim2.new(1, -80 * self.scale, 1, -40 * self.scale)
    self.content.Position = UDim2.new(0, 80 * self.scale, 0, 40 * self.scale)
    self.content.BackgroundColor3 = Theme:getColor("main")
    self.content.BorderSizePixel = 0
    self.content.ScrollBarThickness = 4
    self.content.ScrollBarImageColor3 = Theme:getColor("textMuted")
    self.content.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.content.ZIndex = 1
    self.content.ClipsDescendants = true
    
    -- 内容 Padding
    local contentPadding = Instance.new("UIPadding")
    contentPadding.Parent = self.content
    contentPadding.PaddingTop = UDim.new(0, 10)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.PaddingLeft = UDim.new(0, 10)
    contentPadding.PaddingRight = UDim.new(0, 10)
    
    -- 内容列表布局
    self.contentLayout = Instance.new("UIListLayout")
    self.contentLayout.Parent = self.content
    self.contentLayout.Padding = UDim.new(0, 12)
    self.contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.contentLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    
    -- 侧边栏标签列表布局
    self.tabLayout = Instance.new("UIListLayout")
    self.tabLayout.Parent = self.sidebar
    self.tabLayout.Padding = UDim.new(0, 8)
    self.tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- 主题响应
    Theme.onChanged:Connect(function()
        self:RefreshTheme()
    end)
    
    -- 窗口大小改变时重新计算 Canvas
    self.frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if self.currentTab and self.currentTab.containerLayout then
            self:UpdateCanvasSize()
        end
    end)
    
    return self
end

function Window:RefreshTheme()
    self.frame.BackgroundColor3 = Theme:getColor("main")
    self.titleLabel.TextColor3 = Theme:getColor("text")
    self.subLabel.TextColor3 = Theme:getColor("textSec")
    self.closeBtn.TextColor3 = Theme:getColor("text")
    self.sidebar.BackgroundColor3 = Theme:getColor("side")
    self.content.BackgroundColor3 = Theme:getColor("main")
    self.content.ScrollBarImageColor3 = Theme:getColor("textMuted")
    if self.minimizeBtn then self.minimizeBtn.TextColor3 = Theme:getColor("text") end
    
    for _, tab in ipairs(self.tabs) do
        tab:refreshTheme()
    end
end

function Window:UpdateCanvasSize()
    if not self.currentTab then return end
    local layout = self.currentTab.containerLayout
    if layout then
        task.defer(function()
            self.content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)
    end
end

function Window:Minimize()
    self.isMinimized = not self.isMinimized
    if self.isMinimized then
        self.sidebar.Visible = false
        self.content.Visible = false
        self.frame.Size = UDim2.new(0, self.width * self.scale, 0, 40 * self.scale)
    else
        self.sidebar.Visible = true
        self.content.Visible = true
        self.frame.Size = UDim2.new(0, self.width * self.scale, 0, self.height * self.scale)
    end
end

function Window:Close()
    self:Hide()
end

function Window:Hide()
    if not self.visible then return end
    self.visible = false
    TweenQueue:Add(self.frame, {Size = UDim2.new(0,0,0,0)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
        self.frame.Visible = false
    end)
end

function Window:Show()
    self.frame.Visible = true
    self.visible = true
    if self.isMinimized then
        self.frame.Size = UDim2.new(0, self.width * self.scale, 0, 40 * self.scale)
    else
        self.frame.Size = UDim2.new(0, self.width * self.scale, 0, self.height * self.scale)
    end
    ZIndexManager:BringToFront(self)
end

function Window:Destroy()
    ZIndexManager:UnregisterWindow(self)
    for i, w in ipairs(MobileUI.ActiveWindows) do
        if w == self then
            table.remove(MobileUI.ActiveWindows, i)
            break
        end
    end
    self.frame:Destroy()
end

function Window:SetTitle(newTitle, newSubtitle)
    self.titleLabel.Text = newTitle
    if newSubtitle then self.subLabel.Text = newSubtitle end
end

-- =============================== 标签页类 (增强) ===================================
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
    tab.connections = {}  -- 连接管理
    
    local scale = selfWin.scale
    
    -- 创建标签按钮
    local btn = Instance.new("TextButton")
    btn.Name = "TabBtn_" .. name
    btn.Parent = selfWin.sidebar
    btn.Size = UDim2.new(1, -10, 0, 55 * scale)
    btn.Position = UDim2.new(0, 5, 0, 0)
    btn.BackgroundColor3 = Theme:getColor("side")
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = #selfWin.tabs + 1
    round(btn, Config.BorderRadius)
    
    local icon = Instance.new("ImageLabel")
    icon.Parent = btn
    icon.Size = UDim2.new(0, 28 * scale, 0, 28 * scale)
    icon.Position = UDim2.new(0.5, -14 * scale, 0, 8 * scale)
    icon.BackgroundTransparency = 1
    icon.Image = tab.iconId
    icon.ImageColor3 = Theme:getColor("textSec")
    
    local label = Instance.new("TextLabel")
    label.Parent = btn
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 40 * scale)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme:getColor("textSec")
    label.Font = Config.FontRegular
    label.TextSize = 10 * scale
    
    tab.button = btn
    tab.icon = icon
    tab.label = label
    
    -- 内容容器
    local container = Instance.new("Frame")
    container.Name = "TabContent_" .. name
    container.Parent = selfWin.content
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 0)
    container.Visible = false
    container.LayoutOrder = #selfWin.tabs + 1
    
    local containerLayout = Instance.new("UIListLayout")
    containerLayout.Parent = container
    containerLayout.Padding = UDim.new(0, 12)
    containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    containerLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    
    tab.container = container
    tab.containerLayout = containerLayout
    
    -- 添加控件后更新大小的辅助函数
    function tab:UpdateLayout()
        task.defer(function()
            local sizeY = containerLayout.AbsoluteContentSize.Y + 20
            selfWin.content.CanvasSize = UDim2.new(0, 0, 0, sizeY)
        end)
    end
    
    -- 激活逻辑
    local function activate()
        for _, t in ipairs(selfWin.tabs) do
            t.button.BackgroundColor3 = Theme:getColor("side")
            t.icon.ImageColor3 = Theme:getColor("textSec")
            t.label.TextColor3 = Theme:getColor("textSec")
            t.container.Visible = false
            t.active = false
        end
        btn.BackgroundColor3 = selfWin.accent
        icon.ImageColor3 = Color3.fromRGB(255,255,255)
        label.TextColor3 = Color3.fromRGB(255,255,255)
        container.Visible = true
        tab.active = true
        selfWin.currentTab = tab
        tab:UpdateLayout()
    end
    
    btn.MouseButton1Click:Connect(activate)
    btn.TouchTap:Connect(activate)
    
    -- 默认激活第一个
    if #selfWin.tabs == 0 then
        activate()
    end
    
    table.insert(selfWin.tabs, tab)
    
    -- 主题刷新
    function tab:refreshTheme()
        if self.active then
            self.button.BackgroundColor3 = self.window.accent
            self.icon.ImageColor3 = Color3.fromRGB(255,255,255)
            self.label.TextColor3 = Color3.fromRGB(255,255,255)
        else
            self.button.BackgroundColor3 = Theme:getColor("side")
            self.icon.ImageColor3 = Theme:getColor("textSec")
            self.label.TextColor3 = Theme:getColor("textSec")
        end
    end
    
    -- ======================================================================
    -- 控件实现：所有控件添加到此部分
    -- ======================================================================
    
    -- 连接跟踪辅助
    local function addConnection(conn)
        table.insert(tab.connections, conn)
    end
    
    -- ========== 按钮 ==========
    function tab:Button(text, callback, options)
        options = options or {}
        local btnHeight = options.height or 45
        local btn = Instance.new("TextButton")
        btn.Parent = container
        btn.Size = UDim2.new(1, 0, 0, btnHeight * scale)
        btn.BackgroundColor3 = options.bgColor or Theme:getColor("card")
        btn.Text = text
        btn.TextColor3 = options.textColor or Theme:getColor("text")
        btn.Font = options.font or Config.FontRegular
        btn.TextSize = (options.textSize or 14) * scale
        btn.AutoButtonColor = false
        round(btn, options.radius or Config.BorderRadius)
        if options.disabled then
            btn.BackgroundColor3 = Theme:getColor("disabled")
            btn.TextColor3 = Theme:getColor("textMuted")
            btn.AutoButtonColor = false
            return
        end
        
        local function onClick()
            if options.disabled then return end
            TweenQueue:Add(btn, {BackgroundColor3 = options.hoverColor or selfWin.accent}, 0.1)
            TweenQueue:Add(btn, {BackgroundColor3 = options.bgColor or Theme:getColor("card")}, 0.2)
            safeCall(callback)
        end
        addConnection(btn.MouseButton1Click:Connect(onClick))
        addConnection(btn.TouchTap:Connect(onClick))
        
        tab:UpdateLayout()
        return btn
    end
    
    -- ========== 带图标的按钮 ==========
    function tab:IconButton(iconId, text, callback)
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 45 * scale)
        frame.BackgroundColor3 = Theme:getColor("card")
        round(frame, Config.BorderRadius)
        
        local icon = Instance.new("ImageLabel")
        icon.Parent = frame
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 10, 0.5, -12)
        icon.BackgroundTransparency = 1
        icon.Image = iconId
        icon.ImageColor3 = Theme:getColor("text")
        
        local label = Instance.new("TextButton")
        label.Parent = frame
        label.Size = UDim2.new(1, -44, 1, 0)
        label.Position = UDim2.new(0, 40, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 14 * scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.AutoButtonColor = false
        
        local function onClick()
            safeCall(callback)
        end
        addConnection(label.MouseButton1Click:Connect(onClick))
        addConnection(label.TouchTap:Connect(onClick))
        
        tab:UpdateLayout()
    end
    
    -- ========== 开关 ==========
    function tab:Toggle(text, defaultValue, callback, options)
        local toggled = defaultValue or false
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 50 * scale)
        frame.BackgroundColor3 = Theme:getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(1, -70, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 14 * scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Parent = frame
        toggleBtn.Size = UDim2.new(0, 50 * scale, 0, 26 * scale)
        toggleBtn.Position = UDim2.new(1, -55 * scale, 0.5, -13 * scale)
        toggleBtn.BackgroundColor3 = toggled and selfWin.accent or Color3.fromRGB(120,120,120)
        toggleBtn.Text = ""
        toggleBtn.AutoButtonColor = false
        round(toggleBtn, 13 * scale)
        
        local circle = Instance.new("Frame")
        circle.Parent = toggleBtn
        circle.Size = UDim2.new(0, 22 * scale, 0, 22 * scale)
        circle.Position = toggled and UDim2.new(1, -24 * scale, 0.5, -11 * scale) or UDim2.new(0, 2 * scale, 0.5, -11 * scale)
        circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
        round(circle, 11 * scale)
        
        local function updateToggle()
            toggled = not toggled
            toggleBtn.BackgroundColor3 = toggled and (options and options.accent or selfWin.accent) or Color3.fromRGB(120,120,120)
            local targetPos = toggled and UDim2.new(1, -24 * scale, 0.5, -11 * scale) or UDim2.new(0, 2 * scale, 0.5, -11 * scale)
            TweenQueue:Add(circle, {Position = targetPos}, 0.2)
            safeCall(callback, toggled)
        end
        
        addConnection(toggleBtn.MouseButton1Click:Connect(updateToggle))
        addConnection(toggleBtn.TouchTap:Connect(updateToggle))
        
        tab:UpdateLayout()
        return { Set = function(val) if val ~= toggled then updateToggle() end end, Get = function() return toggled end }
    end
    
    -- ========== 滑块 ==========
    function tab:Slider(text, minVal, maxVal, defaultVal, callback, options)
        options = options or {}
        local value = defaultVal or minVal
        local step = options.step or (maxVal - minVal <= 2 and 0.01 or 1)  -- 自适应步长
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 75 * scale)
        frame.BackgroundColor3 = Theme:getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(1, -10, 0, 25 * scale)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. (options.format and options.format(value) or tostring(value))
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 13 * scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local bar = Instance.new("Frame")
        bar.Name = "SliderBar"
        bar.Parent = frame
        bar.Size = UDim2.new(0.9, 0, 0, 6 * scale)
        bar.Position = UDim2.new(0.05, 0, 0.65, 0)
        bar.BackgroundColor3 = Color3.fromRGB(80,80,80)
        round(bar, 3)
        
        local fill = Instance.new("Frame")
        fill.Parent = bar
        fill.Size = UDim2.new((value-minVal)/(maxVal-minVal), 0, 1, 0)
        fill.BackgroundColor3 = selfWin.accent
        round(fill, 3)
        
        local knob = Instance.new("TextButton")
        knob.Parent = bar
        knob.Size = UDim2.new(0, 24 * scale, 0, 24 * scale)
        knob.Position = UDim2.new((value-minVal)/(maxVal-minVal), -12 * scale, -9 * scale)
        knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        knob.Text = ""
        knob.AutoButtonColor = false
        round(knob, 12 * scale)
        shadow(knob)
        
        local dragging = false
        local function updateFromInput(input)
            local pos = input.Position
            local barPos = bar.AbsolutePosition.X
            local barSize = bar.AbsoluteSize.X
            local percent = math.clamp((pos.X - barPos) / barSize, 0, 1)
            local rawVal = minVal + (maxVal - minVal) * percent
            local newVal = rawVal
            if step >= 1 then
                newVal = math.floor(rawVal / step) * step
            else
                newVal = math.floor(rawVal / step + 0.5) * step
            end
            newVal = math.clamp(newVal, minVal, maxVal)
            
            if newVal ~= value then
                value = newVal
                label.Text = text .. ": " .. (options.format and options.format(value) or tostring(value))
                fill.Size = UDim2.new((value-minVal)/(maxVal-minVal), 0, 1, 0)
                knob.Position = UDim2.new((value-minVal)/(maxVal-minVal), -12 * scale, -9 * scale)
                safeCall(callback, value)
            end
        end
        
        addConnection(knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input)
            end
        end))
        
        addConnection(bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input)
            end
        end))
        
        addConnection(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end))
        
        addConnection(knob.InputEnded:Connect(function() dragging = false end))
        addConnection(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
        
        tab:UpdateLayout()
        return { Set = function(val) value = math.clamp(val, minVal, maxVal); label.Text = text .. ": " .. tostring(value); fill.Size = UDim2.new((value-minVal)/(maxVal-minVal), 0, 1, 0); knob.Position = UDim2.new((value-minVal)/(maxVal-minVal), -12 * scale, -9 * scale); safeCall(callback, value) end, Get = function() return value end }
    end
    
    -- ========== 下拉框 ==========
    function tab:Dropdown(text, options, callback, multiSelect)
        multiSelect = multiSelect or false
        local selected = multiSelect and {} or (options[1] or "")
        local expanded = false
        local dropdownHeight = 45
        
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, dropdownHeight * scale)
        frame.BackgroundColor3 = Theme:getColor("card")
        round(frame, Config.BorderRadius)
        frame.ClipsDescendants = false
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.7, -10, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. (multiSelect and (#selected == 0 and "None" or table.concat(selected, ", ")) or selected)
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 13 * scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        
        local arrow = Instance.new("TextLabel")
        arrow.Parent = frame
        arrow.Size = UDim2.new(0, 30, 1, 0)
        arrow.Position = UDim2.new(1, -35, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▼"
        arrow.TextColor3 = Theme:getColor("textSec")
        arrow.Font = Config.FontRegular
        arrow.TextSize = 14
        
        local panel = Instance.new("Frame")
        panel.Parent = frame
        panel.Size = UDim2.new(1, 0, 0, 0)
        panel.Position = UDim2.new(0, 0, 1, 5)
        panel.BackgroundColor3 = Theme:getColor("card")
        panel.ClipsDescendants = true
        round(panel, Config.BorderRadius)
        panel.Visible = false
        panel.ZIndex = 10
        
        local panelLayout = Instance.new("UIListLayout")
        panelLayout.Parent = panel
        panelLayout.Padding = UDim.new(0, 2)
        panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local function refreshOptions()
            for _, child in ipairs(panel:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            for idx, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = panel
                optBtn.Size = UDim2.new(1, -10, 0, 35 * scale)
                optBtn.Position = UDim2.new(0, 5, 0, 0)
                optBtn.BackgroundColor3 = Theme:getColor("card")
                optBtn.Text = opt
                optBtn.TextColor3 = Theme:getColor("text")
                optBtn.Font = Config.FontRegular
                optBtn.TextSize = 13 * scale
                round(optBtn, Config.BorderRadius)
                optBtn.AutoButtonColor = false
                
                -- 如果是多选，显示勾选标记
                if multiSelect and table.find(selected, opt) then
                    optBtn.Text = "✓ " .. opt
                    optBtn.TextColor3 = selfWin.accent
                end
                
                optBtn.MouseButton1Click:Connect(function()
                    if multiSelect then
                        local idx = table.find(selected, opt)
                        if idx then
                            table.remove(selected, idx)
                        else
                            table.insert(selected, opt)
                        end
                        label.Text = text .. ": " .. (#selected == 0 and "None" or table.concat(selected, ", "))
                        refreshOptions()
                        safeCall(callback, selected)
                    else
                        selected = opt
                        label.Text = text .. ": " .. selected
                        expanded = false
                        panel.Visible = false
                        frame.Size = UDim2.new(1, 0, 0, dropdownHeight * scale)
                        safeCall(callback, selected)
                        tab:UpdateLayout()
                    end
                end)
                optBtn.TouchTap:Connect(function()
                    if multiSelect then
                        local idx = table.find(selected, opt)
                        if idx then
                            table.remove(selected, idx)
                        else
                            table.insert(selected, opt)
                        end
                        label.Text = text .. ": " .. (#selected == 0 and "None" or table.concat(selected, ", "))
                        refreshOptions()
                        safeCall(callback, selected)
                    else
                        selected = opt
                        label.Text = text .. ": " .. selected
                        expanded = false
                        panel.Visible = false
                        frame.Size = UDim2.new(1, 0, 0, dropdownHeight * scale)
                        safeCall(callback, selected)
                        tab:UpdateLayout()
                    end
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
                frame.Size = UDim2.new(1, 0, 0, dropdownHeight * scale + panel.AbsoluteSize.Y)
                -- 确保面板在父级可视区域内
                panel.ZIndex = 10
            else
                frame.Size = UDim2.new(1, 0, 0, dropdownHeight * scale)
            end
            tab:UpdateLayout()
        end
        
        addConnection(frame.MouseButton1Click:Connect(toggle))
        addConnection(frame.TouchTap:Connect(toggle))
        
        tab:UpdateLayout()
        
        local dropdownObj = {
            UpdateOptions = function(newOptions)
                options = newOptions
                if not multiSelect then selected = options[1] or "" end
                label.Text = text .. ": " .. (multiSelect and (table.concat(selected, ", ")) or selected)
                if expanded then
                    refreshOptions()
                    frame.Size = UDim2.new(1, 0, 0, dropdownHeight * scale + panel.AbsoluteSize.Y)
                    tab:UpdateLayout()
                end
            end,
            Set = function(val)
                if multiSelect then
                    if type(val) == "table" then selected = val
                    else selected = {val} end
                else
                    selected = val
                end
                label.Text = text .. ": " .. (multiSelect and table.concat(selected, ", ") or selected)
                if expanded then refreshOptions() end
            end,
            Get = function() return selected end
        }
        return dropdownObj
    end
    
    -- ========== 文本框 ==========
    function tab:Textbox(text, placeholder, callback, options)
        options = options or {}
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 50 * scale)
        frame.BackgroundColor3 = Theme:getColor("card")
        round(frame, Config.BorderRadius)
        
        local labelWidth = options.labelWidth or 80
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0, labelWidth * scale, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 13 * scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local box = Instance.new("TextBox")
        box.Parent = frame
        box.Size = UDim2.new(1, -(labelWidth + 20) * scale, 0.8, 0)
        box.Position = UDim2.new(0, (labelWidth + 10) * scale, 0.1, 0)
        box.BackgroundColor3 = Theme:getColor("input")
        box.Text = options.defaultText or ""
        box.PlaceholderText = placeholder
        box.TextColor3 = Theme:getColor("text")
        box.PlaceholderColor3 = Theme:getColor("textMuted")
        box.Font = Config.FontRegular
        box.TextSize = 13 * scale
        box.ClearTextOnFocus = options.clearOnFocus or false
        round(box, Config.BorderRadius)
        
        if options.multiline then
            box.TextWrapped = true
            box.TextYAlignment = Enum.TextYAlignment.Top
            frame.Size = UDim2.new(1, 0, 0, 100 * scale)
            box.Size = UDim2.new(1, -(labelWidth + 20) * scale, 0.9, 0)
        end
        
        addConnection(box.FocusLost:Connect(function(enterPressed)
            if options.submitOnEnter and enterPressed then
                safeCall(callback, box.Text)
            end
        end))
        addConnection(box:GetPropertyChangedSignal("Text"):Connect(function()
            if options.liveUpdate then
                safeCall(callback, box.Text)
            end
        end))
        
        tab:UpdateLayout()
        return { SetText = function(t) box.Text = t end, GetText = function() return box.Text end, Clear = function() box.Text = "" end }
    end
    
    -- ========== 数字输入框 ==========
    function tab:Numberbox(text, defaultVal, callback, options)
        options = options or {}
        local value = defaultVal or 0
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 50 * scale)
        frame.BackgroundColor3 = Theme:getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0, 80 * scale, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 13 * scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        -- 减号按钮
        local minusBtn = Instance.new("TextButton")
        minusBtn.Parent = frame
        minusBtn.Size = UDim2.new(0, 30 * scale, 0, 30 * scale)
        minusBtn.Position = UDim2.new(0, 85 * scale, 0.5, -15 * scale)
        minusBtn.BackgroundColor3 = Theme:getColor("input")
        minusBtn.Text = "-"
        minusBtn.TextColor3 = Theme:getColor("text")
        minusBtn.Font = Config.FontBold
        minusBtn.TextSize = 18 * scale
        minusBtn.AutoButtonColor = false
        round(minusBtn, Config.BorderRadius)
        
        local box = Instance.new("TextBox")
        box.Parent = frame
        box.Size = UDim2.new(1, -(155 + 30) * scale, 0.8, 0)
        box.Position = UDim2.new(0, 120 * scale, 0.1, 0)
        box.BackgroundColor3 = Theme:getColor("input")
        box.Text = tostring(value)
        box.PlaceholderText = "0"
        box.TextColor3 = Theme:getColor("text")
        box.Font = Config.FontRegular
        box.TextSize = 13 * scale
        round(box, Config.BorderRadius)
        
        local plusBtn = Instance.new("TextButton")
        plusBtn.Parent = frame
        plusBtn.Size = UDim2.new(0, 30 * scale, 0, 30 * scale)
        plusBtn.Position = UDim2.new(1, -35 * scale, 0.5, -15 * scale)
        plusBtn.BackgroundColor3 = Theme:getColor("input")
        plusBtn.Text = "+"
        plusBtn.TextColor3 = Theme:getColor("text")
        plusBtn.Font = Config.FontBold
        plusBtn.TextSize = 18 * scale
        plusBtn.AutoButtonColor = false
        round(plusBtn, Config.BorderRadius)
        
        local function updateValue(newVal)
            newVal = tonumber(newVal)
            if newVal then
                if options.min and newVal < options.min then newVal = options.min end
                if options.max and newVal > options.max then newVal = options.max end
                if options.step then newVal = math.floor(newVal / options.step + 0.5) * options.step end
                value = newVal
                box.Text = tostring(value)
                safeCall(callback, value)
            else
                box.Text = tostring(value)
            end
        end
        
        addConnection(box.FocusLost:Connect(function()
            updateValue(box.Text)
        end))
        
        addConnection(minusBtn.MouseButton1Click:Connect(function()
            updateValue(value - (options.step or 1))
        end))
        addConnection(minusBtn.TouchTap:Connect(function()
            updateValue(value - (options.step or 1))
        end))
        
        addConnection(plusBtn.MouseButton1Click:Connect(function()
            updateValue(value + (options.step or 1))
        end))
        addConnection(plusBtn.TouchTap:Connect(function()
            updateValue(value + (options.step or 1))
        end))
        
        tab:UpdateLayout()
        return { Set = function(v) updateValue(v) end, Get = function() return value end }
    end
    
    -- ========== 颜色选择器 (完整版) ==========
    function tab:Colorpicker(text, defaultColor, callback, options)
        options = options or {}
        local currentColor = defaultColor or Color3.fromRGB(255,255,255)
        local expanded = false
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 45 * scale)
        frame.BackgroundColor3 = Theme:getColor("card")
        round(frame, Config.BorderRadius)
        frame.ClipsDescendants = false
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.6, -10, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 13 * scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local colorBox = Instance.new("Frame")
        colorBox.Parent = frame
        colorBox.Size = UDim2.new(0, 35 * scale, 0, 25 * scale)
        colorBox.Position = UDim2.new(1, -45 * scale, 0.5, -12.5 * scale)
        colorBox.BackgroundColor3 = currentColor
        round(colorBox, Config.BorderRadius)
        
        local pickerPanel = Instance.new("Frame")
        pickerPanel.Parent = frame
        pickerPanel.Size = UDim2.new(1, 0, 0, 0)
        pickerPanel.Position = UDim2.new(0, 0, 1, 5)
        pickerPanel.BackgroundColor3 = Theme:getColor("card")
        round(pickerPanel, Config.BorderRadius)
        pickerPanel.Visible = false
        pickerPanel.ClipsDescendants = true
        pickerPanel.ZIndex = 10
        
        -- 色相条
        local hueBar = Instance.new("Frame")
        hueBar.Parent = pickerPanel
        hueBar.Size = UDim2.new(1, -20, 0, 20 * scale)
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
        svArea.Size = UDim2.new(1, -20, 0, 120 * scale)
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
        
        -- HEX 输入框
        local hexInput = Instance.new("TextBox")
        hexInput.Parent = pickerPanel
        hexInput.Size = UDim2.new(0, 80, 0, 30 * scale)
        hexInput.Position = UDim2.new(1, -90, 0, 170 * scale)
        hexInput.BackgroundColor3 = Theme:getColor("input")
        hexInput.Text = RGBToHex(currentColor)
        hexInput.TextColor3 = Theme:getColor("text")
        hexInput.Font = Config.FontRegular
        hexInput.TextSize = 12 * scale
        hexInput.PlaceholderText = "#FFFFFF"
        round(hexInput, Config.BorderRadius)
        
        local currentHue = 0
        local function setColorFromHue(hueVal)
            local col = Color3.fromHSV(hueVal, 1, 1)
            svArea.BackgroundColor3 = col
            currentHue = hueVal
        end
        
        local function updateColor()
            local s = math.clamp((svKnob.AbsolutePosition.X - svArea.AbsolutePosition.X) / svArea.AbsoluteSize.X, 0, 1)
            local v = 1 - math.clamp((svKnob.AbsolutePosition.Y - svArea.AbsolutePosition.Y) / svArea.AbsoluteSize.Y, 0, 1)
            currentColor = Color3.fromHSV(currentHue, s, v)
            colorBox.BackgroundColor3 = currentColor
            hexInput.Text = RGBToHex(currentColor)
            safeCall(callback, currentColor)
        end
        
        local draggingHue = false
        local draggingSV = false
        
        -- Hue 拖拽
        local function updateHue(input)
            local x = math.clamp(input.Position.X - hueBar.AbsolutePosition.X, 0, hueBar.AbsoluteSize.X)
            local hue = x / hueBar.AbsoluteSize.X
            setColorFromHue(hue)
            hueKnob.Position = UDim2.new(hue, -4, -2, 0)
            updateColor()
        end
        
        addConnection(hueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingHue = true
                updateHue(input)
            end
        end))
        
        -- SV 拖拽
        local function updateSV(input)
            local x = math.clamp(input.Position.X - svArea.AbsolutePosition.X, 0, svArea.AbsoluteSize.X)
            local y = math.clamp(input.Position.Y - svArea.AbsolutePosition.Y, 0, svArea.AbsoluteSize.Y)
            svKnob.Position = UDim2.new(x / svArea.AbsoluteSize.X, -7, y / svArea.AbsoluteSize.Y, -7)
            updateColor()
        end
        
        addConnection(svArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSV = true
                updateSV(input)
            end
        end))
        
        addConnection(UserInputService.InputChanged:Connect(function(input)
            if draggingHue then
                updateHue(input)
            elseif draggingSV then
                updateSV(input)
            end
        end))
        
        addConnection(UserInputService.InputEnded:Connect(function()
            draggingHue = false
            draggingSV = false
        end))
        
        -- HEX 输入
        addConnection(hexInput.FocusLost:Connect(function()
            local hex = hexInput.Text
            if string.match(hex, "^#[0-9a-fA-F]+$") then
                local color = HexToRGB(hex)
                currentColor = color
                colorBox.BackgroundColor3 = currentColor
                local h, s, v = currentColor:ToHSV()
                currentHue = h
                svArea.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                hueKnob.Position = UDim2.new(h, -4, -2, 0)
                svKnob.Position = UDim2.new(s, -7, 1-v, -7)
                safeCall(callback, currentColor)
            else
                hexInput.Text = RGBToHex(currentColor)
            end
        end))
        
        -- 初始化
        local h, s, v = currentColor:ToHSV()
        currentHue = h
        setColorFromHue(h)
        hueKnob.Position = UDim2.new(h, -4, -2, 0)
        svKnob.Position = UDim2.new(s, -7, 1-v, -7)
        hexInput.Text = RGBToHex(currentColor)
        
        local function toggle()
            expanded = not expanded
            pickerPanel.Visible = expanded
            if expanded then
                pickerPanel.Size = UDim2.new(1, 0, 0, 210 * scale)
                frame.Size = UDim2.new(1, 0, 0, 45 * scale + 215 * scale)
            else
                frame.Size = UDim2.new(1, 0, 0, 45 * scale)
            end
            tab:UpdateLayout()
        end
        
        addConnection(frame.MouseButton1Click:Connect(toggle))
        addConnection(frame.TouchTap:Connect(toggle))
        
        tab:UpdateLayout()
        return { Set = function(c) currentColor = c; colorBox.BackgroundColor3 = c; safeCall(callback, c) end, Get = function() return currentColor end }
    end
    
    -- ========== 标签 / 文本 ==========
    function tab:Label(text, align, options)
        options = options or {}
        local lbl = Instance.new("TextLabel")
        lbl.Parent = container
        lbl.Size = UDim2.new(1, 0, 0, options.height or 30 * scale)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = options.color or Theme:getColor("textSec")
        lbl.Font = options.font or Config.FontRegular
        lbl.TextSize = (options.textSize or 12) * scale
        lbl.TextWrapped = options.wrap or false
        if align == "center" then
            lbl.TextXAlignment = Enum.TextXAlignment.Center
        elseif align == "right" then
            lbl.TextXAlignment = Enum.TextXAlignment.Right
        else
            lbl.TextXAlignment = Enum.TextXAlignment.Left
        end
        tab:UpdateLayout()
        return lbl
    end
    
    -- ========== 分割线 ==========
    function tab:Line(thickness, color)
        local line = Instance.new("Frame")
        line.Parent = container
        line.Size = UDim2.new(1, 0, 0, thickness or 2)
        line.BackgroundColor3 = color or Theme:getColor("textMuted")
        line.BackgroundTransparency = 0.8
        round(line, 1)
        tab:UpdateLayout()
        return line
    end
    
    -- ========== 按键绑定 ==========
    function tab:Bind(text, defaultKey, callback)
        local key = defaultKey or "None"
        local binding = false
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 45 * scale)
        frame.BackgroundColor3 = Theme:getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.6, -10, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 13 * scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Parent = frame
        keyLabel.Size = UDim2.new(0, 80 * scale, 0.8, 0)
        keyLabel.Position = UDim2.new(1, -90 * scale, 0.1, 0)
        keyLabel.BackgroundColor3 = Theme:getColor("input")
        keyLabel.Text = key
        keyLabel.TextColor3 = Theme:getColor("text")
        keyLabel.Font = Config.FontRegular
        keyLabel.TextSize = 13 * scale
        keyLabel.TextXAlignment = Enum.TextXAlignment.Center
        round(keyLabel, Config.BorderRadius)
        
        local function startBinding()
            if binding then return end
            binding = true
            keyLabel.Text = "..."
            local con
            con = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    key = input.KeyCode.Name
                    keyLabel.Text = key
                    con:Disconnect()
                    binding = false
                end
            end)
            -- 超时取消
            task.delay(5, function()
                if binding then
                    con:Disconnect()
                    keyLabel.Text = key
                    binding = false
                end
            end)
        end
        
        addConnection(keyLabel.MouseButton1Click:Connect(startBinding))
        addConnection(keyLabel.TouchTap:Connect(startBinding))
        
        addConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or binding then return end
            if input.KeyCode.Name == key and key ~= "None" then
                safeCall(callback)
            end
        end))
        
        tab:UpdateLayout()
        return { SetKey = function(k) key = k; keyLabel.Text = k end, GetKey = function() return key end }
    end
    
    -- ========== 进度条 ==========
    function tab:ProgressBar(text, initialValue, maxValue, options)
        options = options or {}
        local value = initialValue or 0
        local max = maxValue or 100
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 60 * scale)
        frame.BackgroundColor3 = Theme:getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(1, -20, 0, 25 * scale)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 13 * scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local percent = Instance.new("TextLabel")
        percent.Parent = frame
        percent.Size = UDim2.new(0, 50, 0, 25 * scale)
        percent.Position = UDim2.new(1, -60, 0, 5)
        percent.BackgroundTransparency = 1
        percent.Text = math.floor(value / max * 100) .. "%"
        percent.TextColor3 = Theme:getColor("textSec")
        percent.Font = Config.FontRegular
        percent.TextSize = 12 * scale
        percent.TextXAlignment = Enum.TextXAlignment.Right
        
        local bar = Instance.new("Frame")
        bar.Parent = frame
        bar.Size = UDim2.new(1, -20, 0, 8 * scale)
        bar.Position = UDim2.new(0, 10, 0, 40 * scale)
        bar.BackgroundColor3 = Theme:getColor("input")
        round(bar, 4)
        
        local fill = Instance.new("Frame")
        fill.Parent = bar
        fill.Size = UDim2.new(value / max, 0, 1, 0)
        fill.BackgroundColor3 = options.color or selfWin.accent
        round(fill, 4)
        
        tab:UpdateLayout()
        
        local obj = {
            Set = function(v)
                value = math.clamp(v, 0, max)
                fill.Size = UDim2.new(value / max, 0, 1, 0)
                percent.Text = math.floor(value / max * 100) .. "%"
                if options.callback then safeCall(options.callback, value) end
            end,
            Get = function() return value end,
            SetMax = function(m) max = m; fill.Size = UDim2.new(value / max, 0, 1, 0) end,
            Increment = function(amt) obj.Set(value + (amt or 1)) end,
        }
        return obj
    end
    
    -- ========== 单选按钮组 ==========
    function tab:RadioGroup(text, options, defaultIndex, callback)
        local selectedIndex = defaultIndex or 1
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 0)
        frame.BackgroundTransparency = 1
        
        local layout = Instance.new("UIListLayout")
        layout.Parent = frame
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        
        -- 组标题
        if text and text ~= "" then
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Parent = frame
            titleLabel.Size = UDim2.new(1, 0, 0, 20 * scale)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = text
            titleLabel.TextColor3 = Theme:getColor("textSec")
            titleLabel.Font = Config.FontMedium
            titleLabel.TextSize = 12 * scale
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        end
        
        local radioButtons = {}
        for i, opt in ipairs(options) do
            local radioFrame = Instance.new("Frame")
            radioFrame.Parent = frame
            radioFrame.Size = UDim2.new(1, 0, 0, 40 * scale)
            radioFrame.BackgroundColor3 = Theme:getColor("card")
            radioFrame.BackgroundTransparency = (i == selectedIndex) and 0 or 1  -- 选中高亮
            round(radioFrame, Config.BorderRadius)
            
            local circle = Instance.new("Frame")
            circle.Parent = radioFrame
            circle.Size = UDim2.new(0, 20 * scale, 0, 20 * scale)
            circle.Position = UDim2.new(0, 10, 0.5, -10 * scale)
            circle.BackgroundColor3 = (i == selectedIndex) and selfWin.accent or Theme:getColor("input")
            round(circle, 10 * scale)
            
            if i == selectedIndex then
                local inner = Instance.new("Frame")
                inner.Parent = circle
                inner.Size = UDim2.new(0.5, 0, 0.5, 0)
                inner.Position = UDim2.new(0.25, 0, 0.25, 0)
                inner.BackgroundColor3 = Color3.fromRGB(255,255,255)
                round(inner, 5 * scale)
            end
            
            local optLabel = Instance.new("TextLabel")
            optLabel.Parent = radioFrame
            optLabel.Size = UDim2.new(1, -40, 1, 0)
            optLabel.Position = UDim2.new(0, 35, 0, 0)
            optLabel.BackgroundTransparency = 1
            optLabel.Text = opt
            optLabel.TextColor3 = Theme:getColor("text")
            optLabel.Font = Config.FontRegular
            optLabel.TextSize = 13 * scale
            optLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local btn = Instance.new("TextButton")
            btn.Parent = radioFrame
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.AutoButtonColor = false
            
            addConnection(btn.MouseButton1Click:Connect(function()
                selectedIndex = i
                -- 刷新所有单选按钮
                for j, rb in ipairs(radioButtons) do
                    rb.circle.BackgroundColor3 = (j == i) and selfWin.accent or Theme:getColor("input")
                    if rb.inner then rb.inner:Destroy() end
                    if j == i then
                        rb.inner = Instance.new("Frame")
                        rb.inner.Parent = rb.circle
                        rb.inner.Size = UDim2.new(0.5, 0, 0.5, 0)
                        rb.inner.Position = UDim2.new(0.25, 0, 0.25, 0)
                        rb.inner.BackgroundColor3 = Color3.fromRGB(255,255,255)
                        round(rb.inner, 5 * scale)
                    end
                    rb.frame.BackgroundTransparency = (j == i) and 0 or 1
                end
                safeCall(callback, i, options[i])
            end))
            addConnection(btn.TouchTap:Connect(function()
                selectedIndex = i
                for j, rb in ipairs(radioButtons) do
                    rb.circle.BackgroundColor3 = (j == i) and selfWin.accent or Theme:getColor("input")
                    if rb.inner then rb.inner:Destroy() end
                    if j == i then
                        rb.inner = Instance.new("Frame")
                        rb.inner.Parent = rb.circle
                        rb.inner.Size = UDim2.new(0.5, 0, 0.5, 0)
                        rb.inner.Position = UDim2.new(0.25, 0, 0.25, 0)
                        rb.inner.BackgroundColor3 = Color3.fromRGB(255,255,255)
                        round(rb.inner, 5 * scale)
                    end
                    rb.frame.BackgroundTransparency = (j == i) and 0 or 1
                end
                safeCall(callback, i, options[i])
            end))
            
            radioButtons[i] = {frame = radioFrame, circle = circle, inner = (i==selectedIndex) and circle:FindFirstChild("Frame") or nil}
        end
        
        task.wait()
        frame.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
        tab:UpdateLayout()
        
        return { Get = function() return selectedIndex, options[selectedIndex] end, Set = function(idx) if idx >= 1 and idx <= #options then selectedIndex = idx end end }
    end
    
    -- ========== 分段控制器 ==========
    function tab:SegmentControl(options, defaultIndex, callback)
        local selectedIndex = defaultIndex or 1
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 40 * scale)
        frame.BackgroundColor3 = Theme:getColor("input")
        round(frame, Config.BorderRadius)
        frame.ClipsDescendants = true
        
        local buttonWidth = 1 / #options
        local buttons = {}
        
        for i, opt in ipairs(options) do
            local btn = Instance.new("TextButton")
            btn.Parent = frame
            btn.Size = UDim2.new(buttonWidth, 0, 1, 0)
            btn.Position = UDim2.new(buttonWidth * (i-1), 0, 0, 0)
            btn.BackgroundColor3 = (i == selectedIndex) and selfWin.accent or Color3.fromRGB(1,1,1,0)
            btn.BackgroundTransparency = (i == selectedIndex) and 0 or 1
            btn.Text = opt
            btn.TextColor3 = (i == selectedIndex) and Color3.fromRGB(255,255,255) or Theme:getColor("text")
            btn.Font = Config.FontRegular
            btn.TextSize = 13 * scale
            btn.AutoButtonColor = false
            round(btn, Config.BorderRadius)
            
            addConnection(btn.MouseButton1Click:Connect(function()
                selectedIndex = i
                for j, b in ipairs(buttons) do
                    b.BackgroundColor3 = (j == i) and selfWin.accent or Color3.fromRGB(1,1,1,0)
                    b.BackgroundTransparency = (j == i) and 0 or 1
                    b.TextColor3 = (j == i) and Color3.fromRGB(255,255,255) or Theme:getColor("text")
                end
                safeCall(callback, i, opt)
            end))
            addConnection(btn.TouchTap:Connect(function()
                selectedIndex = i
                for j, b in ipairs(buttons) do
                    b.BackgroundColor3 = (j == i) and selfWin.accent or Color3.fromRGB(1,1,1,0)
                    b.BackgroundTransparency = (j == i) and 0 or 1
                    b.TextColor3 = (j == i) and Color3.fromRGB(255,255,255) or Theme:getColor("text")
                end
                safeCall(callback, i, opt)
            end))
            table.insert(buttons, btn)
        end
        
        tab:UpdateLayout()
        return { Get = function() return selectedIndex, options[selectedIndex] end, Set = function(idx) if idx >= 1 and idx <= #options then selectedIndex = idx end end }
    end
    
    -- ========== 图片 ==========
    function tab:Image(imageId, sizeX, sizeY, options)
        options = options or {}
        local img = Instance.new("ImageLabel")
        img.Parent = container
        img.Size = UDim2.new(1, 0, 0, sizeY or 150 * scale)
        img.BackgroundTransparency = 1
        img.Image = imageId
        img.ScaleType = options.scaleType or Enum.ScaleType.Fit
        img.ImageColor3 = options.color or Color3.fromRGB(255,255,255)
        if sizeX then img.Size = UDim2.new(0, sizeX, 0, sizeY) end
        round(img, options.radius or 0)
        tab:UpdateLayout()
        return img
    end
    
    -- ========== 富文本 ==========
    function tab:RichText(markdown)
        -- 简易实现：使用 TextLabel 的 RichText 属性
        local label = Instance.new("TextLabel")
        label.Parent = container
        label.Size = UDim2.new(1, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = markdown
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 13 * scale
        label.TextWrapped = true
        label.RichText = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        -- 计算高度
        task.wait()
        local textSize = TextService:GetTextSize(markdown, label.TextSize, label.Font, Vector2.new(label.AbsoluteSize.X, math.huge))
        label.Size = UDim2.new(1, 0, 0, textSize.Y + 10)
        tab:UpdateLayout()
        return label
    end
    
    -- ========== 树形视图 ==========
    function tab:TreeView(data, options)
        -- data: { text = "Node", children = {...} }
        options = options or {}
        local treeFrame = Instance.new("Frame")
        treeFrame.Parent = container
        treeFrame.Size = UDim2.new(1, 0, 0, 0)
        treeFrame.BackgroundTransparency = 1
        
        local treeLayout = Instance.new("UIListLayout")
        treeLayout.Parent = treeFrame
        treeLayout.Padding = UDim.new(0, 2)
        treeLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local function createNode(parent, nodeData, depth)
            local nodeFrame = Instance.new("Frame")
            nodeFrame.Parent = parent
            nodeFrame.Size = UDim2.new(1, 0, 0, 35 * scale)
            nodeFrame.BackgroundColor3 = Theme:getColor("card")
            round(nodeFrame, Config.BorderRadius)
            
            local offset = 20 * depth * scale
            local expandBtn
            if nodeData.children and #nodeData.children > 0 then
                expandBtn = Instance.new("TextButton")
                expandBtn.Parent = nodeFrame
                expandBtn.Size = UDim2.new(0, 20, 0, 20)
                expandBtn.Position = UDim2.new(0, 5 + offset, 0.5, -10)
                expandBtn.BackgroundTransparency = 1
                expandBtn.Text = "▶"
                expandBtn.TextColor3 = Theme:getColor("text")
                expandBtn.Font = Config.FontRegular
                expandBtn.TextSize = 12
                expandBtn.AutoButtonColor = false
            end
            
            local nodeLabel = Instance.new("TextButton")
            nodeLabel.Parent = nodeFrame
            nodeLabel.Size = UDim2.new(1, -(10 + offset + (expandBtn and 25 or 0)), 1, 0)
            nodeLabel.Position = UDim2.new(0, 5 + offset + (expandBtn and 25 or 0), 0, 0)
            nodeLabel.BackgroundTransparency = 1
            nodeLabel.Text = nodeData.text
            nodeLabel.TextColor3 = Theme:getColor("text")
            nodeLabel.Font = Config.FontRegular
            nodeLabel.TextSize = 13 * scale
            nodeLabel.TextXAlignment = Enum.TextXAlignment.Left
            nodeLabel.AutoButtonColor = false
            
            if nodeData.callback then
                addConnection(nodeLabel.MouseButton1Click:Connect(function() safeCall(nodeData.callback) end))
                addConnection(nodeLabel.TouchTap:Connect(function() safeCall(nodeData.callback) end))
            end
            
            if expandBtn and nodeData.children then
                local childrenFrame = Instance.new("Frame")
                childrenFrame.Parent = treeFrame
                childrenFrame.Size = UDim2.new(1, 0, 0, 0)
                childrenFrame.BackgroundTransparency = 1
                childrenFrame.Visible = false
                
                local childrenLayout = Instance.new("UIListLayout")
                childrenLayout.Parent = childrenFrame
                childrenLayout.Padding = UDim.new(0, 2)
                childrenLayout.SortOrder = Enum.SortOrder.LayoutOrder
                
                local isExpanded = false
                expandBtn.MouseButton1Click:Connect(function()
                    isExpanded = not isExpanded
                    childrenFrame.Visible = isExpanded
                    expandBtn.Text = isExpanded and "▼" or "▶"
                    -- 重新计算高度
                    task.wait()
                    local totalHeight = treeLayout.AbsoluteContentSize.Y
                    treeFrame.Size = UDim2.new(1, 0, 0, totalHeight)
                    tab:UpdateLayout()
                end)
                
                for _, child in ipairs(nodeData.children) do
                    createNode(childrenFrame, child, depth + 1)
                end
                
                task.wait()
                childrenFrame.Size = UDim2.new(1, 0, 0, childrenLayout.AbsoluteContentSize.Y)
            end
            
            return nodeFrame
        end
        
        for _, nodeData in ipairs(data) do
            createNode(treeFrame, nodeData, 0)
        end
        
        task.wait()
        treeFrame.Size = UDim2.new(1, 0, 0, treeLayout.AbsoluteContentSize.Y)
        tab:UpdateLayout()
    end
    
    -- ========== 日期选择器 (简易) ==========
    function tab:DatePicker(text, callback)
        -- 一个简单的文本输入框，格式 YYYY-MM-DD，这里只做界面
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.Size = UDim2.new(1, 0, 0, 50 * scale)
        frame.BackgroundColor3 = Theme:getColor("card")
        round(frame, Config.BorderRadius)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0, 80 * scale, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme:getColor("text")
        label.Font = Config.FontRegular
        label.TextSize = 13 * scale
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local box = Instance.new("TextBox")
        box.Parent = frame
        box.Size = UDim2.new(1, -100 * scale, 0.8, 0)
        box.Position = UDim2.new(0, 90 * scale, 0.1, 0)
        box.BackgroundColor3 = Theme:getColor("input")
        box.Text = os.date("%Y-%m-%d")
        box.PlaceholderText = "YYYY-MM-DD"
        box.TextColor3 = Theme:getColor("text")
        box.Font = Config.FontRegular
        box.TextSize = 13 * scale
        round(box, Config.BorderRadius)
        
        addConnection(box.FocusLost:Connect(function()
            local dateStr = box.Text
            -- 简单验证格式 YYYY-MM-DD
            if string.match(dateStr, "^%d%d%d%d%-%d%d%-%d%d$") then
                safeCall(callback, dateStr)
            else
                box.Text = os.date("%Y-%m-%d")
            end
        end))
        
        tab:UpdateLayout()
        return { Set = function(d) box.Text = d end, Get = function() return box.Text end }
    end
    
    -- ========== 对话框（在Tab内） ==========
    function tab:Dialog(title, message, buttons, options)
        options = options or {}
        local overlay = Instance.new("TextButton")
        overlay.Parent = selfWin.frame
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
        overlay.BackgroundTransparency = 0.6
        overlay.AutoButtonColor = false
        overlay.Text = ""
        overlay.ZIndex = Config.ZIndexModal
        
        local dialogFrame = Instance.new("Frame")
        dialogFrame.Parent = overlay
        dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        dialogFrame.Size = UDim2.new(0, options.width or 260 * scale, 0, options.height or 150 * scale)
        dialogFrame.BackgroundColor3 = Theme:getColor("card")
        round(dialogFrame, Config.BorderRadius)
        shadow(dialogFrame)
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Parent = dialogFrame
        titleLabel.Size = UDim2.new(1, 0, 0, 40 * scale)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Theme:getColor("text")
        titleLabel.Font = Config.FontBold
        titleLabel.TextSize = 16 * scale
        
        local msgLabel = Instance.new("TextLabel")
        msgLabel.Parent = dialogFrame
        msgLabel.Size = UDim2.new(1, -20, 0, 50 * scale)
        msgLabel.Position = UDim2.new(0, 10, 0, 45 * scale)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = message
        msgLabel.TextColor3 = Theme:getColor("textSec")
        msgLabel.Font = Config.FontRegular
        msgLabel.TextSize = 13 * scale
        msgLabel.TextWrapped = true
        
        local buttonFrame = Instance.new("Frame")
        buttonFrame.Parent = dialogFrame
        buttonFrame.Size = UDim2.new(1, 0, 0, 40 * scale)
        buttonFrame.Position = UDim2.new(0, 0, 1, -40 * scale)
        buttonFrame.BackgroundTransparency = 1
        
        local btnLayout = Instance.new("UIListLayout")
        btnLayout.Parent = buttonFrame
        btnLayout.FillDirection = Enum.FillDirection.Horizontal
        btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        btnLayout.Padding = UDim.new(0, 10)
        btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        for _, btnInfo in ipairs(buttons) do
            local btn = Instance.new("TextButton")
            btn.Parent = buttonFrame
            btn.Size = UDim2.new(0, 80 * scale, 1, -10)
            btn.BackgroundColor3 = btnInfo.accent or selfWin.accent
            btn.Text = btnInfo.text
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.Font = Config.FontRegular
            btn.TextSize = 13 * scale
            round(btn, Config.BorderRadius)
            btn.AutoButtonColor = false
            
            btn.MouseButton1Click:Connect(function()
                safeCall(btnInfo.callback)
                overlay:Destroy()
            end)
            btn.TouchTap:Connect(function()
                safeCall(btnInfo.callback)
                overlay:Destroy()
            end)
        end
        
        -- 点击遮罩关闭
        addConnection(overlay.MouseButton1Click:Connect(function()
            if options.closeOnOverlay ~= false then
                overlay:Destroy()
            end
        end))
    end
    
    -- 清理标签页连接
    function tab:Destroy()
        for _, conn in ipairs(self.connections) do
            if conn.Connected then conn:Disconnect() end
        end
        self.connections = {}
    end
    
    return tab
end

-- =============================== 页面路由系统 ===================================
local Router = {
    pages = {},
    currentPage = nil,
    container = nil,
}

function Router:Init(parent)
    self.container = Instance.new("Frame")
    self.container.Name = "RouterContainer"
    self.container.Parent = parent or ScreenGui
    self.container.Size = UDim2.new(1, 0, 1, 0)
    self.container.BackgroundTransparency = 1
    self.container.ZIndex = Config.ZIndexBase
end

function Router:AddPage(name, pageFrame)
    self.pages[name] = pageFrame
    pageFrame.Parent = self.container
    pageFrame.Visible = false
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
end

function Router:Navigate(pageName, transition)
    if self.currentPage and self.pages[self.currentPage] then
        self.pages[self.currentPage].Visible = false
    end
    if self.pages[pageName] then
        if transition then
            Animator.PageTransition(self.pages[self.currentPage], self.pages[pageName], transition)
        else
            self.pages[pageName].Visible = true
        end
        self.currentPage = pageName
    end
end

-- =============================== 全局 API ===================================
function MobileUI:CreateWindow(title, subtitle, accentColor, options)
    return Window.new(title, subtitle, accentColor, options)
end

function MobileUI:Notify(title, message, duration, type, icon)
    NotificationManager:Show(title, message, duration, type, icon)
end

function MobileUI:SetTheme(themeName)
    Theme:set(themeName)
end

function MobileUI:RegisterTheme(name, colors)
    Theme:registerCustomTheme(name, colors)
end

function MobileUI:GetTheme()
    return Theme.current
end

function MobileUI:AddKeybind(keyCode, callback, description)
    KeybindManager:Add(keyCode, callback, description)
end

function MobileUI:RemoveKeybind(keyCode)
    KeybindManager:Remove(keyCode)
end

function MobileUI:CreateRouter(parent)
    Router:Init(parent)
    return Router
end

-- 销毁所有 UI
function MobileUI:DestroyAll()
    for _, window in ipairs(self.ActiveWindows) do
        window:Destroy()
    end
    self.ActiveWindows = {}
    ConnectionManager:Cleanup()
end

-- 获取屏幕比例
function MobileUI:GetScale()
    return getScale()
end

-- 版本信息
function MobileUI:GetVersion()
    return self.__version
end

-- 导出一些工具函数
MobileUI.Utils = {
    round = round,
    shadow = shadow,
    getScale = getScale,
    MakeDraggable = MakeDraggable,
    RGBToHex = RGBToHex,
    HexToRGB = HexToRGB,
    debounce = debounce,
    throttle = throttle,
}

-- 主题启动
Theme:set("dark")

return MobileUI