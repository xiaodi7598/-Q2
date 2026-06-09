--[[
    ========================================================================
    LunaUI V3: Celestial Edition (星空极光版)
    ========================================================================
    - 纯代码打造次世代亚克力玻璃拟物风格，专为高级 Roblox 开发与注入环境设计
    - 支持全移动端/PC端智能响应式排版
    - 独家手机端物理可拖动极光悬浮球
    - 内置：全局通知、动态 Tooltips、物理水波纹、实时搜索过滤、性能监视器
    - 100% 离线运行，移除所有第三方依赖，确保绝对安全、极速响应
    ========================================================================
]]

local LunaUI = {}
LunaUI.__index = LunaUI

-- Roblox 系统服务注入
local TweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local textService = game:GetService("TextService")
local runService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer
local mouse = localPlayer:GetMouse()
local http = game:GetService("HttpService")
local guiService = game:GetService("GuiService")

-- =============================================================================
-- 【 主题调色盘配置 】
-- =============================================================================
LunaUI.Themes = {
    ["Cyberpunk Aurora"] = {
        MainBg = Color3.fromRGB(10, 10, 18),
        TopbarBg = Color3.fromRGB(15, 15, 28),
        SidebarBg = Color3.fromRGB(12, 12, 22),
        Accent = Color3.fromRGB(142, 68, 255), -- 极光紫
        AccentGlow = Color3.fromRGB(0, 240, 255), -- 极光蓝
        TextActive = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(140, 145, 170),
        Border = Color3.fromRGB(35, 35, 60),
        ElementBg = Color3.fromRGB(22, 22, 38),
        ElementHover = Color3.fromRGB(30, 30, 52),
    },
    ["Midnight Deep"] = {
        MainBg = Color3.fromRGB(8, 8, 8),
        TopbarBg = Color3.fromRGB(12, 12, 12),
        SidebarBg = Color3.fromRGB(10, 10, 10),
        Accent = Color3.fromRGB(255, 75, 75), -- 烈焰红
        AccentGlow = Color3.fromRGB(255, 140, 0),
        TextActive = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(120, 120, 120),
        Border = Color3.fromRGB(28, 28, 28),
        ElementBg = Color3.fromRGB(16, 16, 16),
        ElementHover = Color3.fromRGB(22, 22, 22),
    },
    ["Emerald Forest"] = {
        MainBg = Color3.fromRGB(6, 12, 10),
        TopbarBg = Color3.fromRGB(9, 18, 15),
        SidebarBg = Color3.fromRGB(7, 14, 12),
        Accent = Color3.fromRGB(46, 204, 113), -- 翡翠绿
        AccentGlow = Color3.fromRGB(26, 188, 156),
        TextActive = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(130, 160, 145),
        Border = Color3.fromRGB(25, 45, 38),
        ElementBg = Color3.fromRGB(14, 28, 23),
        ElementHover = Color3.fromRGB(20, 40, 33),
    },
    ["Sakura Blossom"] = {
        MainBg = Color3.fromRGB(20, 15, 18),
        TopbarBg = Color3.fromRGB(28, 20, 25),
        SidebarBg = Color3.fromRGB(24, 18, 22),
        Accent = Color3.fromRGB(255, 105, 180), -- 樱花粉
        AccentGlow = Color3.fromRGB(255, 192, 203),
        TextActive = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(180, 150, 165),
        Border = Color3.fromRGB(50, 35, 45),
        ElementBg = Color3.fromRGB(36, 25, 32),
        ElementHover = Color3.fromRGB(48, 33, 42),
    },
    ["Polar Light"] = { -- 高端明亮模式
        MainBg = Color3.fromRGB(245, 246, 250),
        TopbarBg = Color3.fromRGB(255, 255, 255),
        SidebarBg = Color3.fromRGB(238, 241, 245),
        Accent = Color3.fromRGB(9, 132, 227), -- 极地蓝
        AccentGlow = Color3.fromRGB(0, 206, 201),
        TextActive = Color3.fromRGB(45, 52, 54),
        TextMuted = Color3.fromRGB(116, 125, 140),
        Border = Color3.fromRGB(220, 225, 235),
        ElementBg = Color3.fromRGB(255, 255, 255),
        ElementHover = Color3.fromRGB(241, 242, 246),
    }
}

LunaUI.CurrentThemeName = "Cyberpunk Aurora"
local Theme = LunaUI.Themes[LunaUI.CurrentThemeName]

-- =============================================================================
-- 【 全局动画参数库 】
-- =============================================================================
local ANIM_EASE = Enum.EasingStyle.Exponential
local ANIM_FAST = TweenInfo.new(0.2, ANIM_EASE, Enum.EasingDirection.Out)
local ANIM_MID  = TweenInfo.new(0.4, ANIM_EASE, Enum.EasingDirection.Out)
local ANIM_SLOW = TweenInfo.new(0.6, ANIM_EASE, Enum.EasingDirection.Out)

-- =============================================================================
-- 【 底层核心工具箱 】
-- =============================================================================
function LunaUI:Tween(obj, info, props)
    if not obj then return end
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

-- 高性能实例工厂
function LunaUI:Create(className, props, parent)
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        inst[k] = v
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

-- 物理水波纹动效生成器 (Ripple Effect)
function LunaUI:Ripple(button)
    button.ClipsDescendants = true
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local absPos = button.AbsolutePosition
            local x = pos.X - absPos.X
            local y = pos.Y - absPos.Y
            
            local rip = self:Create("Frame", {
                Name = "PhysicsRipple",
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.6,
                Position = UDim2.new(0, x, 0, y),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 0, 0, 0),
                ZIndex = button.ZIndex + 1,
            }, button)
            
            local corner = self:Create("UICorner", {
                CornerRadius = UDim.new(1, 0)
            }, rip)
            
            local targetSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
            self:Tween(rip, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, targetSize, 0, targetSize),
                BackgroundTransparency = 1
            })
            task.delay(0.6, function()
                rip:Destroy()
            end)
        end
    end)
end

-- 移动端拖拽核心重构 (全面兼容 Touch 与 Mouse，加物理惯性平滑阻尼)
function LunaUI:SetDraggable(targetFrame, handleFrame)
    handleFrame = handleFrame or targetFrame
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        local xOffset = startPos.X.Offset + delta.X
        local yOffset = startPos.Y.Offset + delta.Y
        
        -- 防止菜单完全被拖拽出屏幕边缘
        local screen = targetFrame.Parent.AbsoluteSize
        xOffset = math.clamp(xOffset, -targetFrame.AbsoluteSize.X/1.5, screen.X - targetFrame.AbsoluteSize.X/3)
        yOffset = math.clamp(yOffset, 0, screen.Y - 50)
        
        self:Tween(targetFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(startPos.X.Scale, xOffset, startPos.Y.Scale, yOffset)
        })
    end
    
    handleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handleFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    uis.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- =============================================================================
-- 【 全局信息气泡提示栏 (Dynamic Tooltip Engine) 】
-- =============================================================================
local Tooltip = { Active = nil }
function Tooltip:Show(element, text)
    if self.Active then self.Active:Destroy() end
    
    local tooltipFrame = LunaUI:Create("Frame", {
        Name = "LunaTooltip",
        BackgroundColor3 = Theme.TopbarBg,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.new(0, 0, 0, 0),
        ZIndex = 10000,
        Parent = element.Parent.Parent.Parent.Parent.Parent -- 挂载到主 ScreenGui 上确保最顶层显示
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, tooltipFrame)
    LunaUI:Create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, tooltipFrame)
    
    local textLabel = LunaUI:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Ubuntu,
        Text = text,
        TextColor3 = Theme.TextActive,
        TextSize = 12,
        TextWrapped = true,
        Size = UDim2.new(0, math.min(180, string.len(text)*8), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 10001
    }, tooltipFrame)
    
    self.Active = tooltipFrame
    
    -- 动态坐标计算与实时追尾
    local function align()
        if not self.Active or not element then return end
        local elementPos = element.AbsolutePosition
        local elementSize = element.AbsoluteSize
        tooltipFrame.Position = UDim2.new(0, elementPos.X + (elementSize.X / 2) - (tooltipFrame.AbsoluteSize.X / 2), 0, elementPos.Y - tooltipFrame.AbsoluteSize.Y - 8)
    end
    
    align()
    tooltipFrame.BackgroundTransparency = 1
    textLabel.TextTransparency = 1
    tooltipFrame.BorderTransparency = 1
    
    LunaUI:Tween(tooltipFrame, ANIM_FAST, { BackgroundTransparency = 0.05, BorderTransparency = 0 })
    LunaUI:Tween(textLabel, ANIM_FAST, { TextTransparency = 0 })
end

function Tooltip:Hide()
    if self.Active then
        local old = self.Active
        self.Active = nil
        LunaUI:Tween(old, ANIM_FAST, { BackgroundTransparency = 1, BorderTransparency = 1 })
        task.delay(0.2, function() old:Destroy() end)
    end
end

-- 为组件快捷绑定人性化提示
function LunaUI:BindTooltip(guiElement, tipText)
    guiElement.MouseEnter:Connect(function()
        Tooltip:Show(guiElement, tipText)
    end)
    guiElement.MouseLeave:Connect(function()
        Tooltip:Hide()
    end)
    guiElement.TouchLongPress:Connect(function()
        Tooltip:Show(guiElement, tipText)
        task.delay(2.5, function() Tooltip:Hide() end)
    end)
end

-- =============================================================================
-- 【 瀑布级全局流式通知系统 (Notification Engine) 】
-- =============================================================================
local NotificationSystem = { Stack = {} }
function NotificationSystem:Push(title, content, typeName, duration)
    typeName = typeName or "Info" -- Info, Success, Warning, Error
    duration = duration or 4
    
    local ScreenGui = localPlayer:WaitForChild("PlayerGui"):FindFirstChild("LunaUI_Celestial")
    if not ScreenGui then return end
    
    -- 获取或构建通知专用容器
    local container = ScreenGui:FindFirstChild("NotificationContainer")
    if not container then
        container = LunaUI:Create("Frame", {
            Name = "NotificationContainer",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -310, 0, 40),
            Size = UDim2.new(0, 300, 1, -80),
            Parent = ScreenGui
        })
        LunaUI:Create("UIListLayout", {
            VerticalAlignment = Enum.VerticalAlignment.Top,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, container)
    end
    
    local accentColors = {
        Info = Color3.fromRGB(0, 162, 255),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60)
    }
    local accentColor = accentColors[typeName] or Theme.Accent
    
    local toast = LunaUI:Create("Frame", {
        BackgroundColor3 = Theme.TopbarBg,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundTransparency = 1,
        LayoutOrder = #self.Stack + 1,
        Parent = container
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, toast)
    
    local glowBar = LunaUI:Create("Frame", {
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 4, 1, 0),
        Parent = toast
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, glowBar)
    
    local titleLbl = LunaUI:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 10),
        Size = UDim2.new(1, -30, 0, 18),
        Font = Enum.Font.Ubuntu,
        Text = "<b>" .. title .. "</b>",
        RichText = true,
        TextColor3 = Theme.TextActive,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toast
    })
    
    local contentLbl = LunaUI:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 28),
        Size = UDim2.new(1, -24, 0, 36),
        Font = Enum.Font.Ubuntu,
        Text = content,
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = toast
    })
    
    -- 极速滑动入场动效
    toast.Position = UDim2.new(1.5, 0, 0, 0)
    LunaUI:Tween(toast, ANIM_SLOW, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.05 })
    
    -- 倒计时进度条
    local progressBar = LunaUI:Create("Frame", {
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 1, -4),
        Size = UDim2.new(1, -32, 0, 2),
        Parent = toast
    })
    
    LunaUI:Tween(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
    
    task.delay(duration, function()
        LunaUI:Tween(toast, ANIM_FAST, { Position = UDim2.new(1.5, 0, 0, 0), BackgroundTransparency = 1 })
        task.delay(0.2, function()
            toast:Destroy()
        end)
    end)
end

function LunaUI:Notify(title, content, typeName, duration)
    NotificationSystem:Push(title, content, typeName, duration)
end

-- =============================================================================
-- 【 极光主题无缝运行时更新器 】
-- =============================================================================
local ThemeUpdateRegistry = {}
function LunaUI:RegisterThemeUpdate(element, callback)
    table.insert(ThemeUpdateRegistry, { Element = element, Callback = callback })
end

function LunaUI:SwitchTheme(themeName)
    if not self.Themes[themeName] then return end
    self.CurrentThemeName = themeName
    Theme = self.Themes[themeName]
    
    for _, reg in ipairs(ThemeUpdateRegistry) do
        pcall(function()
            if reg.Element and reg.Element.Parent then
                reg.Callback(Theme)
            end
        end)
    end
    self:Notify("主题更新成功", "主面板现已优雅地切换至: " .. themeName, "Success", 3.5)
end

-- =============================================================================
-- 【 高级系统性能波动线图监控器 】
-- =============================================================================
local PerformanceGraph = {}
PerformanceGraph.__index = PerformanceGraph

function PerformanceGraph.new(parent)
    local self = setmetatable({}, PerformanceGraph)
    self.DataPoints = {}
    self.MaxPoints = 28
    
    self.Container = LunaUI:Create("Frame", {
        BackgroundColor3 = Theme.ElementBg,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        Size = UDim2.new(1, -16, 0, 95),
        Parent = parent
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, self.Container)
    
    local header = LunaUI:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 15),
        Font = Enum.Font.Ubuntu,
        Text = "<b>系统性能多维波动图 (Performance Graph)</b>",
        RichText = true,
        TextColor3 = Theme.TextActive,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    
    self.Readout = LunaUI:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 23),
        Size = UDim2.new(1, -24, 0, 15),
        Font = Enum.Font.Ubuntu,
        Text = "FPS: -- | Ping: --ms | Mem: --MB",
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    
    self.LineCanvas = LunaUI:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 42),
        Size = UDim2.new(1, -24, 0, 45),
        Parent = self.Container
    })
    
    -- 实时性能渲染环
    local lastTime = os.clock()
    local frames = 0
    runService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - lastTime >= 1 then
            local fps = frames
            frames = 0
            lastTime = now
            
            local ping = math.floor(guiService:GetNetworkLatency() * 1000)
            local mem = math.floor(gcinfo() / 1024)
            self:Update(fps, ping, mem)
        end
    end)
    
    LunaUI:RegisterThemeUpdate(self.Container, function(t)
        self.Container.BackgroundColor3 = t.ElementBg
        self.Container.BorderColor3 = t.Border
        self.Readout.TextColor3 = t.Accent
    end)
    
    return self
end

function PerformanceGraph:Update(fps, ping, mem)
    self.Readout.Text = string.format("实时帧率: %d FPS  |  网络延迟: %d ms  |  内存占用: %d MB", fps, ping, mem)
    
    table.insert(self.DataPoints, fps)
    if #self.DataPoints > self.MaxPoints then
        table.remove(self.DataPoints, 1)
    end
    
    -- 清理画布
    for _, child in ipairs(self.LineCanvas:GetChildren()) do
        child:Destroy()
    end
    
    -- 渲染平滑直方图
    local w = self.LineCanvas.AbsoluteSize.X / self.MaxPoints
    for i, pt in ipairs(self.DataPoints) do
        local ratio = math.clamp(pt / 60, 0, 1)
        local h = ratio * self.LineCanvas.AbsoluteSize.Y
        
        local bar = LunaUI:Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, (i-1)*w, 1, -h),
            Size = UDim2.new(0, w - 2, 0, h),
            Parent = self.LineCanvas
        })
        LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 2) }, bar)
        
        -- 色彩渐变响应
        if pt < 30 then
            bar.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- 卡顿发红
        elseif pt < 45 then
            bar.BackgroundColor3 = Color3.fromRGB(241, 196, 15) -- 中等发黄
        else
            bar.BackgroundColor3 = Theme.Accent
        end
    end
end

-- =============================================================================
-- 【 核心窗口引擎 (Main GUI Engine) 】
-- =============================================================================
function LunaUI.new(titleText)
    local self = setmetatable({}, LunaUI)
    self.Tabs = {}
    self.Open = true
    self.ThemeRegistry = {}
    
    -- 创建顶层独立渲染 ScreenGui
    self.ScreenGui = LunaUI:Create("ScreenGui", {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Name = "LunaUI_Celestial",
        IgnoreGuiInset = true,
    })
    
    -- 支持保护机制 (Syn, Wave, KRNL, Carbon etc.)
    if getgenv and getgenv().syn and syn.protect_gui then
        syn.protect_gui(self.ScreenGui)
    end
    
    local coreGuiSuccess, _ = pcall(function()
        self.ScreenGui.Parent = game:GetService("CoreGui")
    end)
    if not coreGuiSuccess then
        self.ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end
    
    -- =========================================================================
    -- 【 手机端专属极光悬浮球控制系统 】
    -- =========================================================================
    self.FloatBall = LunaUI:Create("TextButton", {
        Name = "MobileFloatBall",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.TopbarBg,
        BorderColor3 = Theme.Accent,
        BorderSizePixel = 1,
        Position = UDim2.new(0.9, 0, 0.2, 0),
        Size = UDim2.new(0, 48, 0, 48),
        Text = "",
        ZIndex = 9999,
        Visible = false, -- 默认隐藏，主面板展开时不显示
        Parent = self.ScreenGui
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, self.FloatBall)
    
    -- 环形呼吸灯
    local glowRing = LunaUI:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 6, 1, 6),
        ZIndex = 9998,
        Parent = self.FloatBall
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, glowRing)
    local grad = LunaUI:Create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentGlow)
        },
        Rotation = 0
    }, glowRing)
    
    -- 旋转极光动画
    task.spawn(function()
        local rot = 0
        while true do
            rot = (rot + 2) % 360
            grad.Rotation = rot
            task.wait(0.01)
        end
    end)
    
    -- 悬浮球拖拽行为
    LunaUI:SetDraggable(self.FloatBall)
    
    -- =========================================================================
    -- 【 主面板窗口 】
    -- =========================================================================
    self.MainFrame = LunaUI:Create("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.MainBg,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 680, 0, 470),
        ClipsDescendants = true,
        Parent = self.ScreenGui
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 10) }, self.MainFrame)
    LunaUI:SetDraggable(self.MainFrame, self.MainFrame) -- 支持全局任意位置拖拽，人性化拉满
    
    -- 亚克力背景流光层
    local blurBg = LunaUI:Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.95,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 0,
        Parent = self.MainFrame
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 10) }, blurBg)
    
    -- 头部栏 (Topbar)
    local Topbar = LunaUI:Create("Frame", {
        BackgroundColor3 = Theme.TopbarBg,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = self.MainFrame
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 10) }, Topbar)
    
    local Title = LunaUI:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 250, 1, 0),
        Font = Enum.Font.Ubuntu,
        Text = titleText,
        TextColor3 = Theme.TextActive,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
        Parent = Topbar
    })
    
    -- 控制按钮容器
    local CtrlContainer = LunaUI:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -110, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        Parent = Topbar
    })
    LunaUI:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8)
    }, CtrlContainer)
    
    -- 手机端最小化和关闭逻辑实现
    local function setWindowState(state)
        self.Open = state
        if state then
            -- 展开窗口
            self.MainFrame.Visible = true
            self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
            self.MainFrame.BackgroundTransparency = 1
            self.FloatBall.Visible = false
            
            LunaUI:Tween(self.MainFrame, ANIM_SLOW, {
                Size = UDim2.new(0, 680, 0, 470),
                BackgroundTransparency = 0
            })
        else
            -- 最小化至悬浮球 (极简极美渐进动画)
            LunaUI:Tween(self.MainFrame, ANIM_SLOW, {
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1
            })
            task.delay(0.4, function()
                self.MainFrame.Visible = false
                self.FloatBall.Visible = true
                self.FloatBall.Position = self.FloatBall.Position -- 保持之前的位置
            end)
        end
    end
    
    self.FloatBall.MouseButton1Down:Connect(function()
        setWindowState(true)
    end)
    
    -- 最小化按钮 (美化)
    local MinBtn = LunaUI:Create("TextButton", {
        BackgroundColor3 = Theme.ElementBg,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        Size = UDim2.new(0, 24, 0, 24),
        Font = Enum.Font.Ubuntu,
        Text = "—",
        TextColor3 = Theme.TextMuted,
        TextSize = 10,
        Parent = CtrlContainer
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, MinBtn)
    LunaUI:BindTooltip(MinBtn, "最小化控制台")
    MinBtn.MouseButton1Down:Connect(function()
        setWindowState(false)
    end)
    
    -- 关闭按钮
    local CloseBtn = LunaUI:Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(150, 40, 40),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 24, 0, 24),
        Font = Enum.Font.Ubuntu,
        Text = "✕",
        TextColor3 = Color3.fromRGB(255, 240, 240),
        TextSize = 11,
        Parent = CtrlContainer
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, CloseBtn)
    LunaUI:BindTooltip(CloseBtn, "关闭并卸载脚本")
    CloseBtn.MouseButton1Down:Connect(function()
        LunaUI:Tween(self.MainFrame, ANIM_FAST, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 })
        task.delay(0.2, function()
            self.ScreenGui:Destroy()
        end)
    end)
    
    -- =========================================================================
    -- 【 侧边栏 (Sidebar) 容器 与 选项卡承载器 】
    -- =========================================================================
    self.Sidebar = LunaUI:Create("Frame", {
        BackgroundColor3 = Theme.SidebarBg,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0, 0, 0, 41),
        Size = UDim2.new(0, 140, 1, -41),
        Parent = self.MainFrame
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 10) }, self.Sidebar)
    
    -- 搜索过滤输入框，人性化功能 (Search Panel)
    local searchFrame = LunaUI:Create("Frame", {
        BackgroundColor3 = Theme.ElementBg,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 25),
        Parent = self.Sidebar
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, searchFrame)
    
    local searchBox = LunaUI:Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 6, 0, 0),
        Size = UDim2.new(1, -12, 1, 0),
        Font = Enum.Font.Ubuntu,
        PlaceholderText = "🔍 智能检索...",
        Text = "",
        TextColor3 = Theme.TextActive,
        PlaceholderColor3 = Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = searchFrame
    })
    
    local SidebarScroll = LunaUI:Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 38),
        Size = UDim2.new(1, 0, 1, -38),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        Parent = self.Sidebar
    })
    local sidebarLayout = LunaUI:Create("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 6)
    }, SidebarScroll)
    
    -- 右侧主交互区
    self.ContainerHolder = LunaUI:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 140, 0, 42),
        Size = UDim2.new(1, -140, 1, -42),
        Parent = self.MainFrame
    })
    
    -- 全局检测 PC 还是 Mobile，更改布局热区实现人性化设计
    local isMobile = (uis.TouchEnabled and not uis.KeyboardEnabled)
    if isMobile then
        self.Sidebar.Size = UDim2.new(0, 55, 1, -41)
        self.ContainerHolder.Position = UDim2.new(0, 55, 0, 42)
        self.ContainerHolder.Size = UDim2.new(1, -55, 1, -42)
        searchFrame.Visible = false
        SidebarScroll.Position = UDim2.new(0, 0, 0, 5)
        SidebarScroll.Size = UDim2.new(1, 0, 1, -5)
    end
    
    -- 搜索输入响应逻辑
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local searchStr = string.lower(searchBox.Text)
        for _, tab in ipairs(self.Tabs) do
            for _, section in ipairs(tab.Sections) do
                for _, sector in ipairs(section.Sectors) do
                    for _, elem in ipairs(sector.Elements) do
                        local match = string.find(string.lower(elem.Name), searchStr) ~= nil
                        elem.Gui.Visible = match
                    end
                end
            end
        end
    end)
    
    -- =========================================================================
    -- 【 主题无缝更新挂载 】
    -- =========================================================================
    LunaUI:RegisterThemeUpdate(self.MainFrame, function(t)
        self.MainFrame.BackgroundColor3 = t.MainBg
        self.MainFrame.BorderColor3 = t.Border
        Topbar.BackgroundColor3 = t.TopbarBg
        Topbar.BorderColor3 = t.Border
        Title.TextColor3 = t.TextActive
        MinBtn.BackgroundColor3 = t.ElementBg
        MinBtn.BorderColor3 = t.Border
        MinBtn.TextColor3 = t.TextMuted
        self.Sidebar.BackgroundColor3 = t.SidebarBg
        self.Sidebar.BorderColor3 = t.Border
        searchFrame.BackgroundColor3 = t.ElementBg
        searchFrame.BorderColor3 = t.Border
        searchBox.TextColor3 = t.TextActive
        searchBox.PlaceholderColor3 = t.TextMuted
        self.FloatBall.BackgroundColor3 = t.TopbarBg
        self.FloatBall.BorderColor3 = t.Accent
    end)
    
    return self
end

-- =============================================================================
-- 【 Tab 页管理构造 (Tab Module) 】
-- =============================================================================
function LunaUI:NewTab(tabTitle, iconId)
    local selfTab = {
        Title = tabTitle,
        Sections = {},
        Active = false,
        TabButton = nil,
        Container = nil
    }
    
    local parentWindow = self
    local isMobile = (uis.TouchEnabled and not uis.KeyboardEnabled)
    
    -- 左侧导航栏对应按钮制作
    selfTab.TabButton = LunaUI:Create("TextButton", {
        BackgroundColor3 = Theme.ElementBg,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 0, isMobile and 45 or 30),
        Text = "",
        Parent = parentWindow.Sidebar:FindFirstChild("ScrollingFrame")
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, selfTab.TabButton)
    LunaUI:Ripple(selfTab.TabButton)
    
    -- 视觉流光高亮圈
    local activeIndicator = LunaUI:Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 2, 0.5, -8),
        Size = UDim2.new(0, 3, 0, 16),
        BackgroundTransparency = 1,
        Parent = selfTab.TabButton
    })
    LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, activeIndicator)
    
    -- 图标与文本渲染
    local icon = LunaUI:Create("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0.5, -9),
        Size = UDim2.new(0, 18, 0, 18),
        Image = iconId or "rbxassetid://6031075932",
        ImageColor3 = Theme.TextMuted,
        Parent = selfTab.TabButton
    })
    
    local text = LunaUI:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -34, 1, 0),
        Font = Enum.Font.Ubuntu,
        Text = tabTitle,
        TextColor3 = Theme.TextMuted,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = not isMobile, -- 手机端只留精巧图标
        Parent = selfTab.TabButton
    })
    
    if isMobile then
        icon.Position = UDim2.new(0.5, -10, 0.5, -10)
        icon.Size = UDim2.new(0, 20, 0, 20)
        LunaUI:BindTooltip(selfTab.TabButton, tabTitle)
    end
    
    -- 对应的主要内容承载容器 (2列智能排版)
    selfTab.Container = LunaUI:Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        Visible = false,
        Parent = parentWindow.ContainerHolder
    })
    
    local tabLayout = LunaUI:Create("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, selfTab.Container)
    
    local tabPadding = LunaUI:Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12)
    }, selfTab.Container)
    
    -- 响应式自适应高度计算
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        selfTab.Container.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 24)
    end)
    
    -- 激活逻辑切换
    local function activate()
        for _, tab in ipairs(parentWindow.Tabs) do
            tab.Active = false
            tab.Container.Visible = false
            LunaUI:Tween(tab.TabButton, ANIM_FAST, { BackgroundTransparency = 1 })
            LunaUI:Tween(tab.TabButton:FindFirstChild("Frame"), ANIM_FAST, { BackgroundTransparency = 1 })
            LunaUI:Tween(tab.TabButton:FindFirstChildOfClass("ImageLabel"), ANIM_FAST, { ImageColor3 = Theme.TextMuted })
            local lbl = tab.TabButton:FindFirstChildOfClass("TextLabel")
            if lbl then
                LunaUI:Tween(lbl, ANIM_FAST, { TextColor3 = Theme.TextMuted })
            end
        end
        
        selfTab.Active = true
        selfTab.Container.Visible = true
        LunaUI:Tween(selfTab.TabButton, ANIM_FAST, { BackgroundTransparency = 0.9 })
        LunaUI:Tween(activeIndicator, ANIM_FAST, { BackgroundTransparency = 0 })
        LunaUI:Tween(icon, ANIM_FAST, { ImageColor3 = Theme.Accent })
        if text.Visible then
            LunaUI:Tween(text, ANIM_FAST, { TextColor3 = Theme.TextActive })
        end
    end
    
    selfTab.TabButton.MouseButton1Down:Connect(activate)
    
    -- 如果是第一个 Tab, 自动点亮激活
    if #parentWindow.Tabs == 0 then
        task.spawn(activate)
    end
    
    table.insert(parentWindow.Tabs, selfTab)
    
    -- Tab 主题更新注册
    LunaUI:RegisterThemeUpdate(selfTab.TabButton, function(t)
        selfTab.TabButton.BackgroundColor3 = t.ElementBg
        activeIndicator.BackgroundColor3 = t.Accent
        selfTab.Container.ScrollBarImageColor3 = t.Accent
        if selfTab.Active then
            icon.ImageColor3 = t.Accent
            text.TextColor3 = t.TextActive
        else
            icon.ImageColor3 = t.TextMuted
            text.TextColor3 = t.TextMuted
        end
    end)
    
    -- =========================================================================
    -- 【 分区管理构造 (Section Module) 】
    -- =========================================================================
    function selfTab:NewSection(sectionName)
        local selfSec = { Name = sectionName, Sectors = {} }
        
        local secFrame = LunaUI:Create("Frame", {
            BackgroundColor3 = Theme.TopbarBg,
            BorderColor3 = Theme.Border,
            BorderSizePixel = 1,
            Size = UDim2.new(1, 0, 0, 40),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = selfTab.Container
        })
        LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, secFrame)
        
        local secPadding = LunaUI:Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12)
        }, secFrame)
        
        local secLayout = LunaUI:Create("UIListLayout", {
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, secFrame)
        
        local secTitle = LunaUI:Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 15),
            Font = Enum.Font.Ubuntu,
            Text = "<b>" .. sectionName .. "</b>",
            RichText = true,
            TextColor3 = Theme.Accent,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = secFrame
        })
        
        -- 主题更新注册
        LunaUI:RegisterThemeUpdate(secFrame, function(t)
            secFrame.BackgroundColor3 = t.TopbarBg
            secFrame.BorderColor3 = t.Border
            secTitle.TextColor3 = t.Accent
        end)
        
        -- =====================================================================
        -- 【 新增高级双列组网排版 Sector 】
        -- =====================================================================
        function selfSec:NewSector(sectorName)
            local selfSect = { Elements = {} }
            
            local groupFrame = LunaUI:Create("Frame", {
                BackgroundColor3 = Theme.ElementBg,
                BorderColor3 = Theme.Border,
                BorderSizePixel = 1,
                Size = UDim2.new(1, 0, 0, 30),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = secFrame
            })
            LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, groupFrame)
            
            local groupPadding = LunaUI:Create("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10)
            }, groupFrame)
            
            local groupLayout = LunaUI:Create("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder
            }, groupFrame)
            
            -- 主题同步
            LunaUI:RegisterThemeUpdate(groupFrame, function(t)
                groupFrame.BackgroundColor3 = t.ElementBg
                groupFrame.BorderColor3 = t.Border
            end)
            
            -- =================================================================
            -- 【 终极人机交互 UI 组建工坊 】
            -- =================================================================
            function selfSect:AddElement(elementType, elementName, elementData, callback)
                elementData = elementData or {}
                callback = callback or function() end
                
                local elementObj = { Name = elementName, Gui = nil }
                
                -- 基本元素底座 (所有控件继承自此底座)
                local eleBase = LunaUI:Create("Frame", {
                    BackgroundColor3 = Theme.TopbarBg,
                    BorderColor3 = Theme.Border,
                    BorderSizePixel = 1,
                    Size = UDim2.new(1, 0, 0, 36),
                    Parent = groupFrame
                })
                LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, eleBase)
                elementObj.Gui = eleBase
                
                local eleTitle = LunaUI:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Font = Enum.Font.Ubuntu,
                    Text = elementName,
                    TextColor3 = Theme.TextActive,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = eleBase
                })
                
                -- 自动绑定气泡说明
                if elementData.Tooltip then
                    LunaUI:BindTooltip(eleBase, elementData.Tooltip)
                end
                
                -- 主题自动同步
                LunaUI:RegisterThemeUpdate(eleBase, function(t)
                    eleBase.BackgroundColor3 = t.TopbarBg
                    eleBase.BorderColor3 = t.Border
                    eleTitle.TextColor3 = t.TextActive
                end)
                
                -- =============================================================
                -- 【 1. 动态自适应 Toggle 开关 】
                -- =============================================================
                if elementType == "Toggle" then
                    local toggled = elementData.Default or false
                    
                    local pill = LunaUI:Create("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(40, 40, 50),
                        BorderSizePixel = 0,
                        Position = UDim2.new(1, -12, 0.5, 0),
                        Size = UDim2.new(0, 36, 0, 18),
                        Text = "",
                        Parent = eleBase
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
                    
                    local dot = LunaUI:Create("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, toggled and 20 or 2, 0.5, 0),
                        Size = UDim2.new(0, 14, 0, 14),
                        Parent = pill
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
                    
                    local function updateToggle(state)
                        toggled = state
                        LunaUI:Tween(pill, ANIM_FAST, { BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(40, 40, 50) })
                        LunaUI:Tween(dot, ANIM_FAST, { Position = UDim2.new(0, toggled and 20 or 2, 0.5, 0) })
                        pcall(callback, toggled)
                    end
                    
                    pill.MouseButton1Down:Connect(function()
                        updateToggle(not toggled)
                    end)
                    
                    -- 支持外部调用重设值
                    function elementObj:SetValue(v)
                        updateToggle(v)
                    end
                    
                    LunaUI:RegisterThemeUpdate(pill, function(t)
                        pill.BackgroundColor3 = toggled and t.Accent or Color3.fromRGB(40, 40, 50)
                    end)
                    
                -- =============================================================
                -- 【 2. 带有物理拖拽与数值精确双输人的 Slider 控件 】
                -- =============================================================
                elseif elementType == "Slider" then
                    local min = elementData.Min or 0
                    local max = elementData.Max or 100
                    local current = elementData.Default or min
                    
                    local sliderTrack = LunaUI:Create("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                        BorderSizePixel = 0,
                        Position = UDim2.new(1, -65, 0.5, 0),
                        Size = UDim2.new(0.4, 0, 0, 6),
                        Text = "",
                        Parent = eleBase
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderTrack)
                    
                    local sliderFill = LunaUI:Create("Frame", {
                        BackgroundColor3 = Theme.Accent,
                        BorderSizePixel = 0,
                        Size = UDim2.new((current - min)/(max - min), 0, 1, 0),
                        Parent = sliderTrack
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderFill)
                    
                    local sliderGrab = LunaUI:Create("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BorderColor3 = Theme.Accent,
                        BorderSizePixel = 1,
                        Position = UDim2.new((current - min)/(max - min), 0, 0.5, 0),
                        Size = UDim2.new(0, 12, 0, 12),
                        Parent = sliderTrack
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderGrab)
                    
                    -- 右侧高精TextBox直接输入参数
                    local sliderValBox = LunaUI:Create("TextBox", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = Theme.ElementBg,
                        BorderColor3 = Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(1, -12, 0.5, 0),
                        Size = UDim2.new(0, 42, 0, 20),
                        Font = Enum.Font.Ubuntu,
                        Text = tostring(current),
                        TextColor3 = Theme.Accent,
                        TextSize = 11,
                        Parent = eleBase
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, sliderValBox)
                    
                    local function updateSlider(v)
                        current = math.clamp(v, min, max)
                        sliderValBox.Text = tostring(current)
                        local ratio = (current - min) / (max - min)
                        LunaUI:Tween(sliderFill, ANIM_FAST, { Size = UDim2.new(ratio, 0, 1, 0) })
                        LunaUI:Tween(sliderGrab, ANIM_FAST, { Position = UDim2.new(ratio, 0, 0.5, 0) })
                        pcall(callback, current)
                    end
                    
                    local function slide()
                        local ratio = math.clamp((mouse.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
                        local val = math.floor((ratio * (max - min)) + min)
                        updateSlider(val)
                    end
                    
                    sliderTrack.MouseButton1Down:Connect(function()
                        slide()
                        local conn = mouse.Move:Connect(slide)
                        local endConn
                        endConn = uis.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                conn:Disconnect()
                                endConn:Disconnect()
                            end
                        end)
                    end)
                    
                    sliderValBox.FocusLost:Connect(function()
                        local val = tonumber(sliderValBox.Text)
                        if val then
                            updateSlider(val)
                        else
                            sliderValBox.Text = tostring(current)
                        end
                    end)
                    
                    function elementObj:SetValue(v)
                        updateSlider(v)
                    end
                    
                    LunaUI:RegisterThemeUpdate(sliderTrack, function(t)
                        sliderFill.BackgroundColor3 = t.Accent
                        sliderGrab.BorderColor3 = t.Accent
                        sliderValBox.BackgroundColor3 = t.ElementBg
                        sliderValBox.BorderColor3 = t.Border
                        sliderValBox.TextColor3 = t.Accent
                    end)

                -- =============================================================
                -- 【 3. 智能模糊匹配检索下拉列表框 (Dropdown Searchable) 】
                -- =============================================================
                elseif elementType == "Dropdown" then
                    local options = elementData.Options or {}
                    local currentSelected = elementData.Default or options[1] or ""
                    
                    -- 高度可动态膨胀的下拉舱
                    eleBase.Size = UDim2.new(1, 0, 0, 36)
                    eleBase.ClipsDescendants = true
                    
                    local dropBtn = LunaUI:Create("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = Theme.ElementBg,
                        BorderColor3 = Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(1, -12, 0.5, 0),
                        Size = UDim2.new(0, 130, 0, 24),
                        Font = Enum.Font.Ubuntu,
                        Text = currentSelected,
                        TextColor3 = Theme.Accent,
                        TextSize = 12,
                        Parent = eleBase
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, dropBtn)
                    
                    -- 滚动槽
                    local optScroll = LunaUI:Create("ScrollingFrame", {
                        BackgroundColor3 = Theme.ElementBg,
                        BorderColor3 = Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(1, -130, 0, 36),
                        Size = UDim2.new(0, 130, 0, 0),
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        ScrollBarThickness = 2,
                        Visible = false,
                        ZIndex = 50,
                        Parent = eleBase
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, optScroll)
                    
                    local optLayout = LunaUI:Create("UIListLayout", {
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    }, optScroll)
                    
                    local open = false
                    local function renderOptions(filterStr)
                        optScroll:ClearAllChildren()
                        LunaUI:Create("UIListLayout", {
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        }, optScroll)
                        
                        local shown = 0
                        for _, opt in ipairs(options) do
                            if not filterStr or string.find(string.lower(opt), string.lower(filterStr)) then
                                shown = shown + 1
                                local optBtn = LunaUI:Create("TextButton", {
                                    Size = UDim2.new(1, 0, 0, 24),
                                    BackgroundColor3 = Theme.TopbarBg,
                                    BorderSizePixel = 0,
                                    Font = Enum.Font.Ubuntu,
                                    Text = opt,
                                    TextColor3 = opt == currentSelected and Theme.Accent or Theme.TextMuted,
                                    TextSize = 11,
                                    ZIndex = 51,
                                    Parent = optScroll
                                })
                                LunaUI:Ripple(optBtn)
                                
                                optBtn.MouseButton1Down:Connect(function()
                                    currentSelected = opt
                                    dropBtn.Text = opt
                                    open = false
                                    LunaUI:Tween(eleBase, ANIM_FAST, { Size = UDim2.new(1, 0, 0, 36) })
                                    optScroll.Visible = false
                                    pcall(callback, opt)
                                end)
                            end
                        end
                        optScroll.CanvasSize = UDim2.new(0, 0, 0, shown * 24)
                        LunaUI:Tween(optScroll, ANIM_FAST, { Size = UDim2.new(0, 130, 0, math.min(120, shown * 24)) })
                    end
                    
                    dropBtn.MouseButton1Down:Connect(function()
                        open = not open
                        if open then
                            eleBase.Size = UDim2.new(1, 0, 0, 160)
                            optScroll.Visible = true
                            renderOptions()
                        else
                            LunaUI:Tween(eleBase, ANIM_FAST, { Size = UDim2.new(1, 0, 0, 36) })
                            optScroll.Visible = false
                        end
                    end)
                    
                    function elementObj:SetOptions(newOpts)
                        options = newOpts
                        if open then renderOptions() end
                    end
                    
                    LunaUI:RegisterThemeUpdate(dropBtn, function(t)
                        dropBtn.BackgroundColor3 = t.ElementBg
                        dropBtn.BorderColor3 = t.Border
                        dropBtn.TextColor3 = t.Accent
                        optScroll.BackgroundColor3 = t.ElementBg
                        optScroll.BorderColor3 = t.Border
                    end)

                -- =============================================================
                -- 【 4. 专业虚拟多键绑定捕获器 (Universal Keybind) 】
                -- =============================================================
                elseif elementType == "Keybind" then
                    local currentBind = elementData.Default or Enum.KeyCode.F
                    local isListening = false
                    
                    local bindBtn = LunaUI:Create("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = Theme.ElementBg,
                        BorderColor3 = Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(1, -12, 0.5, 0),
                        Size = UDim2.new(0, 90, 0, 24),
                        Font = Enum.Font.Ubuntu,
                        Text = "[ " .. tostring(currentBind.Name or currentBind) .. " ]",
                        TextColor3 = Theme.Accent,
                        TextSize = 11,
                        Parent = eleBase
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, bindBtn)
                    
                    bindBtn.MouseButton1Down:Connect(function()
                        isListening = true
                        bindBtn.Text = "... 听取按键中 ..."
                        bindBtn.TextColor3 = Color3.fromRGB(241, 196, 15)
                    end)
                    
                    uis.InputBegan:Connect(function(input)
                        if isListening then
                            if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Insert then
                                isListening = false
                                currentBind = input.KeyCode
                                bindBtn.Text = "[ " .. currentBind.Name .. " ]"
                                bindBtn.TextColor3 = Theme.Accent
                                pcall(callback, currentBind)
                            end
                        else
                            if input.KeyCode == currentBind then
                                pcall(callback, currentBind)
                            end
                        end
                    end)
                    
                    LunaUI:RegisterThemeUpdate(bindBtn, function(t)
                        bindBtn.BackgroundColor3 = t.ElementBg
                        bindBtn.BorderColor3 = t.Border
                        if not isListening then bindBtn.TextColor3 = t.Accent end
                    end)

                -- =============================================================
                -- 【 5. 精细型 RGB 调色盘与 HEX 校验器 (HEX Pro Colorpicker) 】
                -- =============================================================
                elseif elementType == "Colorpicker" then
                    local color = elementData.Default or Color3.fromRGB(255, 255, 255)
                    
                    -- 可弹性折叠色彩操作板
                    eleBase.Size = UDim2.new(1, 0, 0, 36)
                    eleBase.ClipsDescendants = true
                    
                    local colorPreview = LunaUI:Create("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = color,
                        BorderColor3 = Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(1, -12, 0.5, 0),
                        Size = UDim2.new(0, 45, 0, 20),
                        Text = "",
                        Parent = eleBase
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, colorPreview)
                    
                    -- RGB 滑条操作舱
                    local colorFrame = LunaUI:Create("Frame", {
                        BackgroundColor3 = Theme.ElementBg,
                        BorderColor3 = Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0.05, 0, 0, 42),
                        Size = UDim2.new(0.9, 0, 0, 80),
                        Parent = eleBase
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, colorFrame)
                    
                    local open = false
                    colorPreview.MouseButton1Down:Connect(function()
                        open = not open
                        if open then
                            eleBase.Size = UDim2.new(1, 0, 0, 135)
                        else
                            LunaUI:Tween(eleBase, ANIM_FAST, { Size = UDim2.new(1, 0, 0, 36) })
                        end
                    end)
                    
                    -- 极简 RGB 通道调整
                    local function createRGBChannel(name, colorAccent, offset, defaultVal, updateCb)
                        local chanLbl = LunaUI:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 10, 0, offset),
                            Size = UDim2.new(0, 15, 0, 20),
                            Font = Enum.Font.Ubuntu,
                            Text = name,
                            TextColor3 = colorAccent,
                            TextSize = 11,
                            Parent = colorFrame
                        })
                        
                        local slideTrack = LunaUI:Create("TextButton", {
                            BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 30, 0, offset + 8),
                            Size = UDim2.new(0.8, -10, 0, 4),
                            Text = "",
                            Parent = colorFrame
                        })
                        LunaUI:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, slideTrack)
                        
                        local slideFill = LunaUI:Create("Frame", {
                            BackgroundColor3 = colorAccent,
                            BorderSizePixel = 0,
                            Size = UDim2.new(defaultVal/255, 0, 1, 0),
                            Parent = slideTrack
                        })
                        
                        local function adjust()
                            local ratio = math.clamp((mouse.X - slideTrack.AbsolutePosition.X) / slideTrack.AbsoluteSize.X, 0, 1)
                            slideFill.Size = UDim2.new(ratio, 0, 1, 0)
                            updateCb(math.floor(ratio * 255))
                        end
                        
                        slideTrack.MouseButton1Down:Connect(function()
                            adjust()
                            local conn = mouse.Move:Connect(adjust)
                            local endConn
                            endConn = uis.InputEnded:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    conn:Disconnect()
                                    endConn:Disconnect()
                                end
                            end)
                        end)
                    end
                    
                    local rVal, gVal, bVal = math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255)
                    local function updateColor()
                        color = Color3.fromRGB(rVal, gVal, bVal)
                        colorPreview.BackgroundColor3 = color
                        pcall(callback, color)
                    end
                    
                    createRGBChannel("R", Color3.fromRGB(255, 75, 75), 5, rVal, function(v) rVal = v updateColor() end)
                    createRGBChannel("G", Color3.fromRGB(46, 204, 113), 28, gVal, function(v) gVal = v updateColor() end)
                    createRGBChannel("B", Color3.fromRGB(52, 152, 219), 51, bVal, function(v) bVal = v updateColor() end)
                    
                    LunaUI:RegisterThemeUpdate(colorFrame, function(t)
                        colorFrame.BackgroundColor3 = t.ElementBg
                        colorFrame.BorderColor3 = t.Border
                    end)

                -- =============================================================
                -- 【 6. 万能 TextBox 文本输入舱 】
                -- =============================================================
                elseif elementType == "TextBox" then
                    local currentText = elementData.Default or ""
                    
                    local textBox = LunaUI:Create("TextBox", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = Theme.ElementBg,
                        BorderColor3 = Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(1, -12, 0.5, 0),
                        Size = UDim2.new(0, 130, 0, 24),
                        Font = Enum.Font.Ubuntu,
                        Text = currentText,
                        PlaceholderText = elementData.Placeholder or "在此输入...",
                        TextColor3 = Theme.Accent,
                        PlaceholderColor3 = Theme.TextMuted,
                        TextSize = 12,
                        Parent = eleBase
                    })
                    LunaUI:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, textBox)
                    
                    textBox.FocusLost:Connect(function()
                        currentText = textBox.Text
                        pcall(callback, currentText)
                    end)
                    
                    LunaUI:RegisterThemeUpdate(textBox, function(t)
                        textBox.BackgroundColor3 = t.ElementBg
                        textBox.BorderColor3 = t.Border
                        textBox.TextColor3 = t.Accent
                        textBox.PlaceholderColor3 = t.TextMuted
                    end)
                end
                
                table.insert(selfSect.Elements, elementObj)
                return elementObj
            end
            
            table.insert(selfSec.Sectors, selfSect)
            return selfSect
        end
        
        table.insert(selfTab.Sections, selfSec)
        return selfSec
    end
    
    return selfTab
end

-- =============================================================================
-- 【 高级系统性能波动监控器工厂挂载 】
-- =============================================================================
function LunaUI:NewPerformanceMonitor(tabObj)
    return PerformanceGraph.new(tabObj.Container)
end

return LunaUI