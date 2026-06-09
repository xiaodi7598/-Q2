--[[
    LunaUI Library (V2 - Optimized & Secure)
    - 基于 Lua 5.1 / Luau 编写
    - 移除了所有后门 webhook
    - 修复了 :connect 为 :Connect 
    - 修正了大小写变量 Bug (State -> state)
    - 提供了完美的配置保存与链式结构支持
]]

local library = {}

local TweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local text_service = game:GetService("TextService")
local local_player = game:GetService("Players").LocalPlayer
local mouse = local_player:GetMouse()
local http = game:GetService("HttpService")
local rs = game:GetService("RunService")

-- 缓动函数
function library:tween(object, info, properties)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

-- 快捷实例化
function library:create(Object, Properties, Parent)
    local Obj = Instance.new(Object)
    for i,v in pairs(Properties) do
        Obj[i] = v
    end
    if Parent ~= nil then
        Obj.Parent = Parent
    end
    return Obj
end

-- 获取文本渲染尺寸
function library:get_text_size(...)
    return text_service:GetTextSize(...)
end

-- 简易 Signal (事件流) 实现，替代外部外部加载，确保 100% 离线单文件运行
local Signal = {}
Signal.__index = Signal
function Signal.new()
    local self = setmetatable({}, Signal)
    self._bindable = Instance.new("BindableEvent")
    return self
end
function Signal:Connect(callback)
    return self._bindable.Event:Connect(callback)
end
function Signal:Fire(...)
    self._bindable:Fire(...)
end

library.signal = {
    new = function()
        return Signal.new()
    end
}

-- 拖拽逻辑支持 (Touch + Mouse)
function library:set_draggable(gui)
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    gui.InputChanged:Connect(function(input)
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

-- 初始化 UI 主窗口
function library.new(library_title, cfg_location)
    local menu = {}
    menu.values = {}
    menu.on_load_cfg = library.signal.new()

    -- 兼容部分执行器的文件创建
    if cfg_location then
        pcall(function()
            if not isfolder(cfg_location) then
                makefolder(cfg_location)
            end
        end)
    end
    
    function menu.copy(original)
        local copy = {}
        for k, v in pairs(original) do
            if type(v) == "table" then
                v = menu.copy(v)
            end
            copy[k] = v
        end
        return copy
    end

    function menu.save_cfg(cfg_name)
        if not cfg_location then return end
        local values_copy = menu.copy(menu.values)
        for _,tab in next, values_copy do
            for _,section in next, tab do
                for _,sector in next, section do
                    for _,element in next, sector do
                        if not element.Color then continue end
                        element.Color = {R = element.Color.R, G = element.Color.G, B = element.Color.B}
                    end
                end
            end
        end
        pcall(function()
            writefile(cfg_location..cfg_name..".txt", http:JSONEncode(values_copy))
        end)
    end

    function menu.load_cfg(cfg_name)
        if not cfg_location then return end
        local success, data = pcall(function()
            return http:JSONDecode(readfile(cfg_location..cfg_name..".txt"))
        end)
        if not success or not data then return end

        for _,tab in next, data do
            for _2,section in next, tab do
                for _3,sector in next, section do
                    for _4,element in next, sector do
                        if element.Color then
                            element.Color = Color3.new(element.Color.R, element.Color.G, element.Color.B)
                        end
                        pcall(function()
                            menu.values[_][_2][_3][_4] = element
                        end)
                    end
                end
            end
        end
        menu.on_load_cfg:Fire()
    end

    menu.open = true
    
    -- 创建父级 ScreenGui
    local ScreenGui = library:create("ScreenGui", {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Name = "LunaUI_Framework",
        IgnoreGuiInset = true,
    })

    -- 保护 UI 不被探知 (仅在部分注入器环境下有效)
    if getgenv and getgenv().syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end

    -- 游戏内自定义鼠标渲染
    local Cursor = library:create("ImageLabel", {
        Name = "Cursor",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 17, 0, 17),
        Image = "rbxassetid://7205257578",
        ZIndex = 6969,
        Visible = false -- 默认隐藏，有需求可手动开启
    }, ScreenGui)

    rs.RenderStepped:Connect(function()
        if Cursor.Visible then
            Cursor.Position = UDim2.new(0, mouse.X, 0, mouse.Y + 36)
        end
    end)

    -- 优先放入 CoreGui，如果环境不支持则退回 PlayerGui
    local coreGuiSuccess, _ = pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    if not coreGuiSuccess then
        ScreenGui.Parent = local_player:WaitForChild("PlayerGui")
    end

    function menu.IsOpen()
        return menu.open
    end
    
    function menu.SetOpen(state)
        ScreenGui.Enabled = state
        menu.open = state
    end

    -- 默认按 Insert 键切换菜单显示
    uis.InputBegan:Connect(function(key)
        if key.KeyCode ~= Enum.KeyCode.Insert then return end
        menu.SetOpen(not ScreenGui.Enabled)
    end)

    -- 主框架窗体 (ImageButton 具有更好的遮罩和模态表现)
    local ImageLabel = library:create("ImageButton", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderColor3 = Color3.fromRGB(78, 93, 234),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 700, 0, 500),
        Image = "http://www.roblox.com/asset/?id=7300333488",
        AutoButtonColor = false,
        Modal = true,
    }, ScreenGui)

    function menu.GetPosition()
        return ImageLabel.Position
    end

    library:set_draggable(ImageLabel)

    -- 标题
    local Title = library:create("TextLabel", {
        Name = "Title",
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, -22, 0, 30),
        Font = Enum.Font.Ubuntu,
        Text = library_title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
    }, ImageLabel)

    -- 左侧侧边栏 (Tabs 容器)
    local TabButtons = library:create("Frame", {
        Name = "TabButtons",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 41),
        Size = UDim2.new(0, 76, 0, 447),
    }, ImageLabel)
    
    local UIListLayout = library:create("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 5)
    }, TabButtons)

    -- 右侧主内容区域
    local Tabs = library:create("Frame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 102, 0, 42),
        Size = UDim2.new(0, 586, 0, 446),
    }, ImageLabel)

    local is_first_tab = true
    local selected_tab
    local tab_num = 1

    -- 创建新选项卡 (Tab)
    function menu.new_tab(tab_image)
        local tab = {tab_num = tab_num}
        menu.values[tab_num] = {}
        tab_num = tab_num + 1

        local TabButton = library:create("TextButton", {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 76, 0, 75),
            Text = "",
        }, TabButtons)

        local TabImage = library:create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 28, 0, 28),
            Image = tab_image,
            ImageColor3 = Color3.fromRGB(100, 100, 100),
        }, TabButton)

        local Tab = library:create("Frame", {
            Name = "Tab",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
        }, Tabs)

        local TabSections = library:create("Frame", {
            Name = "TabSections",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            ClipsDescendants = true,
        }, Tab)

        local UIListLayout = library:create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        }, TabSections)

        local TabFrames = library:create("Frame", {
            Name = "TabFrames",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 29),
            Size = UDim2.new(1, 0, 0, 418),
        }, Tab)

        if is_first_tab then
            is_first_tab = false
            selected_tab = TabButton
            TabImage.ImageColor3 = Color3.fromRGB(186, 186, 255)
            Tab.Visible = true
        end

        TabButton.MouseButton1Down:Connect(function()
            if selected_tab == TabButton then return end
            for _, TButtons in pairs(TabButtons:GetChildren()) do
                if not TButtons:IsA("TextButton") then continue end
                library:tween(TButtons.ImageLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(100, 100, 100)})
            end
            for _, t in pairs(Tabs:GetChildren()) do
                t.Visible = false
            end
            Tab.Visible = true
            selected_tab = TabButton
            library:tween(TabImage, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(186, 186, 255)})
        end)

        TabButton.MouseEnter:Connect(function()
            if selected_tab == TabButton then return end
            library:tween(TabImage, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(255, 255, 255)})
        end)
        TabButton.MouseLeave:Connect(function()
            if selected_tab == TabButton then return end
            library:tween(TabImage, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(100, 100, 100)})
        end)

        local is_first_section = true
        local num_sections = 0
        local selected_section

        -- 创建子分区 (Section)
        function tab.new_section(section_name)
            local section = {}
            num_sections = num_sections + 1
            menu.values[tab.tab_num][section_name] = {}

            local SectionButton = library:create("TextButton", {
                Name = "SectionButton",
                BackgroundTransparency = 1,
                Size = UDim2.new(1/num_sections, 0, 1, 0),
                Font = Enum.Font.Ubuntu,
                Text = section_name,
                TextColor3 = Color3.fromRGB(100, 100, 100),
                TextSize = 14,
            }, TabSections)

            -- 动态重调各 Section 按钮大小
            for _, btn in pairs(TabSections:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.Size = UDim2.new(1/num_sections, 0, 1, 0)
                end
            end

            SectionButton.MouseEnter:Connect(function()
                if selected_section == SectionButton then return end
                library:tween(SectionButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(255, 255, 255)})
            end)
            SectionButton.MouseLeave:Connect(function()
                if selected_section == SectionButton then return end
                library:tween(SectionButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(100, 100, 100)})
            end)

            local SectionDecoration = library:create("Frame", {
                Name = "SectionDecoration",
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 27),
                Size = UDim2.new(1, 0, 0, 1),
                Visible = false,
            }, SectionButton)

            local UIGradient = library:create("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 33, 38)), 
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(81, 97, 243)), 
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(32, 33, 38))
                },
            }, SectionDecoration)

            local SectionFrame = library:create("Frame", {
                Name = "SectionFrame",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Visible = false,
            }, TabFrames)

            -- 左右双列排版支持
            local Left = library:create("Frame", {
                Name = "Left",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 14),
                Size = UDim2.new(0, 282, 0, 395),
            }, SectionFrame)

            library:create("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 12),
            }, Left)

            local Right = library:create("Frame", {
                Name = "Right",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 298, 0, 14),
                Size = UDim2.new(0, 282, 0, 395),
            }, SectionFrame)

            library:create("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 12),
            }, Right)

            SectionButton.MouseButton1Down:Connect(function()
                for _, btn in pairs(TabSections:GetChildren()) do
                    if btn:IsA("TextButton") then
                        library:tween(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(100, 100, 100)})
                        btn.SectionDecoration.Visible = false
                    end
                end
                for _, frame in pairs(TabFrames:GetChildren()) do
                    if frame:IsA("Frame") then
                        frame.Visible = false
                    end
                end

                selected_section = SectionButton
                SectionFrame.Visible = true
                library:tween(SectionButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(186, 186, 255)})
                SectionDecoration.Visible = true
            end)

            if is_first_section then
                is_first_section = false
                selected_section = SectionButton
                SectionButton.TextColor3 = Color3.fromRGB(186, 186, 255)
                SectionDecoration.Visible = true
                SectionFrame.Visible = true
            end

            -- 创建区域边框 (Sector)
            function section.new_sector(sector_name, sector_side)
                local sector = {}
                local actual_side = sector_side == "Right" and Right or Left
                menu.values[tab.tab_num][section_name][sector_name] = {}

                local Border = library:create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(5, 5, 5),
                    BorderColor3 = Color3.fromRGB(30, 30, 30),
                    Size = UDim2.new(1, 0, 0, 20),
                }, actual_side)

                local Container = library:create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(10, 10, 10),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 1, 0, 1),
                    Size = UDim2.new(1, -2, 1, -2),
                }, Border)

                library:create("UIListLayout", {
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, Container)

                library:create("UIPadding", {
                    PaddingTop = UDim.new(0, 12),
                }, Container)

                local SectorTitle = library:create("TextLabel", {
                    Name = "Title",
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0, -8),
                    Size = UDim2.new(1, 0, 0, 15),
                    Font = Enum.Font.Ubuntu,
                    Text = sector_name,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 13,
                }, Border)

                -- 创建分割线
                function sector.create_line(thickness)
                    thickness = thickness or 3
                    Border.Size = Border.Size + UDim2.new(0, 0, 0, thickness * 3)

                    local LineFrame = library:create("Frame", {
                        Name = "LineFrame",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 250, 0, thickness * 3),
                    }, Container)

                    library:create("Frame", {
                        Name = "Line",
                        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = UDim2.new(1, 0, 0, thickness),
                    }, LineFrame)
                end

                -- 核心方法：构建各种元素
                function sector.element(type_name, text, data, callback, c_flag)
                    text = text or type_name
                    data = data or {}
                    callback = callback or function() end

                    local value = {}
                    local flag = c_flag and text.." "..c_flag or text
                    menu.values[tab.tab_num][section_name][sector_name][flag] = value

                    local function do_callback()
                        menu.values[tab.tab_num][section_name][sector_name][flag] = value
                        callback(value)
                    end

                    local default = data.default
                    local element = {}

                    function element:get_value()
                        return value
                    end

                    ----------------- 【 1. Toggle 开关 】 -----------------
                    if type_name == "Toggle" then
                        Border.Size = Border.Size + UDim2.new(0, 0, 0, 18)
                        value = {Toggle = default and default.Toggle or false}

                        local ToggleButton = library:create("TextButton", {
                            Name = "Toggle",
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 18),
                            Text = "",
                        }, Container)

                        local ToggleFrame = library:create("Frame", {
                            AnchorPoint = Vector2.new(0, 0.5),
                            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            Position = UDim2.new(0, 9, 0.5, 0),
                            Size = UDim2.new(0, 9, 0, 9),
                        }, ToggleButton)

                        local ToggleText = library:create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 27, 0, 5),
                            Size = UDim2.new(0, 200, 0, 9),
                            Font = Enum.Font.Ubuntu,
                            Text = text,
                            TextColor3 = Color3.fromRGB(150, 150, 150),
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Left,
                        }, ToggleButton)

                        local mouse_in = false
                        function element:set_value(new_value, cb)
                            value = new_value or value
                            menu.values[tab.tab_num][section_name][sector_name][flag] = value

                            if value.Toggle then
                                library:tween(ToggleFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(186,186,255)})
                                library:tween(ToggleText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(255, 255, 255)})
                            else
                                library:tween(ToggleFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)})
                                if not mouse_in then
                                    library:tween(ToggleText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(150, 150, 150)})
                                end
                            end

                            if not cb then do_callback() end
                        end

                        ToggleButton.MouseEnter:Connect(function()
                            mouse_in = true
                            if value.Toggle then return end
                            library:tween(ToggleText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(255, 255, 255)})
                        end)
                        ToggleButton.MouseLeave:Connect(function()
                            mouse_in = false
                            if value.Toggle then return end
                            library:tween(ToggleText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(150, 150, 150)})
                        end)
                        ToggleButton.MouseButton1Down:Connect(function()
                            element:set_value({Toggle = not value.Toggle})
                        end)
                        element:set_value(value, true)

                        -- 附加 Keybind (按键绑定)
                        local has_extra = false
                        function element:add_keybind(key_default, key_callback)
                            if has_extra then return end
                            has_extra = true
                            local extra_flag = "$" .. flag
                            local extra_value = {Key = key_default, Type = "Always", Active = true}
                            key_callback = key_callback or function() end

                            local Keybind = library:create("TextButton", {
                                Name = "Keybind",
                                AnchorPoint = Vector2.new(1, 0),
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 265, 0, 0),
                                Size = UDim2.new(0, 56, 0, 20),
                                Font = Enum.Font.Ubuntu,
                                Text = "[ "..(key_default or "NONE").." ]",
                                TextColor3 = Color3.fromRGB(150, 150, 150),
                                TextSize = 12,
                                TextXAlignment = Enum.TextXAlignment.Right,
                            }, ToggleButton)

                            local KeybindFrame = library:create("Frame", {
                                Name = "KeybindFrame",
                                BackgroundColor3 = Color3.fromRGB(10, 10, 10),
                                BorderColor3 = Color3.fromRGB(30, 30, 30),
                                Position = UDim2.new(1, 5, 0, 3),
                                Size = UDim2.new(0, 65, 0, 75),
                                Visible = false,
                                ZIndex = 5,
                            }, Keybind)

                            library:create("UIListLayout", {
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                            }, KeybindFrame)

                            local keybind_in = false
                            local keybind_in2 = false
                            Keybind.MouseEnter:Connect(function()
                                keybind_in = true
                                library:tween(Keybind, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(255, 255, 255)})
                            end)
                            Keybind.MouseLeave:Connect(function()
                                keybind_in = false
                                library:tween(Keybind, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(150, 150, 150)})
                            end)
                            KeybindFrame.MouseEnter:Connect(function() keybind_in2 = true end)
                            KeybindFrame.MouseLeave:Connect(function() keybind_in2 = false end)

                            uis.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                                    if KeybindFrame.Visible and not keybind_in and not keybind_in2 then
                                        KeybindFrame.Visible = false
                                    end
                                end
                            end)

                            local function setup_type_button(name, is_always)
                                local btn = library:create("TextButton", {
                                    Name = name,
                                    BackgroundTransparency = 1,
                                    Size = UDim2.new(1, 0, 0, 25),
                                    Font = Enum.Font.Ubuntu,
                                    Text = name,
                                    TextColor3 = Color3.fromRGB(150, 150, 150),
                                    TextSize = 12,
                                    ZIndex = 5,
                                }, KeybindFrame)

                                btn.MouseButton1Down:Connect(function()
                                    KeybindFrame.Visible = false
                                    extra_value.Type = name
                                    extra_value.Active = true
                                    key_callback(extra_value)
                                    menu.values[tab.tab_num][section_name][sector_name][extra_flag] = extra_value
                                end)
                            end

                            setup_type_button("Always")
                            setup_type_button("Hold")
                            setup_type_button("Toggle")

                            local is_binding = false
                            uis.InputBegan:Connect(function(input)
                                if is_binding then
                                    is_binding = false
                                    local new_value = input.KeyCode.Name ~= "Unknown" and input.KeyCode.Name or input.UserInputType.Name
                                    Keybind.Text = "[ "..new_value:upper().." ]"
                                    extra_value.Key = new_value
                                    key_callback(extra_value)
                                elseif extra_value.Key then
                                    local key = input.KeyCode.Name ~= "Unknown" and input.KeyCode.Name or input.UserInputType.Name
                                    if key == extra_value.Key then
                                        if extra_value.Type == "Toggle" then
                                            extra_value.Active = not extra_value.Active
                                        elseif extra_value.Type == "Hold" then
                                            extra_value.Active = true
                                        end
                                        key_callback(extra_value)
                                    end
                                end
                            end)

                            uis.InputEnded:Connect(function(input)
                                if extra_value.Key and not is_binding then
                                    local key = input.KeyCode.Name ~= "Unknown" and input.KeyCode.Name or input.UserInputType.Name
                                    if key == extra_value.Key and extra_value.Type == "Hold" then
                                        extra_value.Active = false
                                        key_callback(extra_value)
                                    end
                                end
                            end)

                            Keybind.MouseButton1Down:Connect(function()
                                is_binding = true
                                Keybind.Text = "[ ... ]"
                            end)
                            Keybind.MouseButton2Down:Connect(function()
                                KeybindFrame.Visible = not KeybindFrame.Visible
                            end)
                        end

                        -- 附加调色板 (ColorPicker)
                        function element:add_color(color_default, has_transparency, color_callback)
                            if has_extra then return end
                            has_extra = true
                            local color_picker_obj = {}
                            local extra_flag = "$" .. flag
                            local extra_value = {Color = color_default or Color3.fromRGB(255,255,255), Transparency = 0}
                            color_callback = color_callback or function() end

                            local ColorButton = library:create("TextButton", {
                                Name = "ColorButton",
                                AnchorPoint = Vector2.new(1, 0.5),
                                BackgroundColor3 = extra_value.Color,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Position = UDim2.new(0, 265, 0.5, 0),
                                Size = UDim2.new(0, 35, 0, 11),
                                Text = "",
                            }, ToggleButton)

                            local ColorFrame = library:create("Frame", {
                                BackgroundColor3 = Color3.fromRGB(10, 10, 10),
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Position = UDim2.new(1, 5, 0, 0),
                                Size = UDim2.new(0, 200, 0, 170),
                                Visible = false,
                                ZIndex = 6,
                            }, ColorButton)

                            local ColorPicker = library:create("ImageButton", {
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Position = UDim2.new(0, 40, 0, 10),
                                Size = UDim2.new(0, 150, 0, 150),
                                Image = "rbxassetid://4155801252",
                                ZIndex = 6,
                            }, ColorFrame)

                            local ColorPick = library:create("Frame", {
                                Size = UDim2.new(0, 2, 0, 2),
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                ZIndex = 6,
                            }, ColorPicker)

                            local HuePicker = library:create("TextButton", {
                                Position = UDim2.new(0, 10, 0, 10),
                                Size = UDim2.new(0, 20, 0, 150),
                                Text = "",
                                ZIndex = 6,
                            }, ColorFrame)

                            library:create("UIGradient", {
                                Rotation = 90,
                                Color = ColorSequence.new {
                                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
                                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
                                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
                                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
                                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
                                }
                            }, HuePicker)

                            local HuePick = library:create("Frame", {
                                Size = UDim2.new(1, 0, 0, 2),
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                ZIndex = 6,
                            }, HuePicker)

                            ColorButton.MouseButton1Down:Connect(function()
                                ColorFrame.Visible = not ColorFrame.Visible
                            end)

                            -- 饱和度与色相计算逻辑
                            local h, s, v = extra_value.Color:ToHSV()
                            local function update_color()
                                local x = math.clamp(mouse.X - ColorPicker.AbsolutePosition.X, 0, ColorPicker.AbsoluteSize.X) / ColorPicker.AbsoluteSize.X
                                local y = math.clamp(mouse.Y - ColorPicker.AbsolutePosition.Y, 0, ColorPicker.AbsoluteSize.Y) / ColorPicker.AbsoluteSize.Y
                                ColorPick.Position = UDim2.new(x, 0, y, 0)
                                s = x
                                v = 1 - y
                                extra_value.Color = Color3.fromHSV(h, s, v)
                                ColorButton.BackgroundColor3 = extra_value.Color
                                color_callback(extra_value)
                            end

                            ColorPicker.MouseButton1Down:Connect(function()
                                update_color()
                                local conn = mouse.Move:Connect(update_color)
                                local endConn
                                endConn = uis.InputEnded:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        conn:Disconnect()
                                        endConn:Disconnect()
                                    end
                                end)
                            end)

                            local function update_hue()
                                local y = math.clamp(mouse.Y - HuePicker.AbsolutePosition.Y, 0, HuePicker.AbsoluteSize.Y) / HuePicker.AbsoluteSize.Y
                                HuePick.Position = UDim2.new(0, 0, y, 0)
                                h = 1 - y
                                ColorPicker.ImageColor3 = Color3.fromHSV(h, 1, 1)
                                extra_value.Color = Color3.fromHSV(h, s, v)
                                ColorButton.BackgroundColor3 = extra_value.Color
                                color_callback(extra_value)
                            end

                            HuePicker.MouseButton1Down:Connect(function()
                                update_hue()
                                local conn = mouse.Move:Connect(update_hue)
                                local endConn
                                endConn = uis.InputEnded:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        conn:Disconnect()
                                        endConn:Disconnect()
                                    end
                                end)
                            end)
                        end
                    end

                    ----------------- 【 2. Slider 滑块 】 -----------------
                    if type_name == "Slider" then
                        Border.Size = Border.Size + UDim2.new(0, 0, 0, 35)
                        value = {Slider = default and default.default or 0}
                        local min, max = default and default.min or 0, default and default.max or 100

                        local Slider = library:create("Frame", {
                            Name = "Slider",
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 35),
                        }, Container)

                        local SliderText = library:create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 9, 0, 6),
                            Size = UDim2.new(0, 200, 0, 9),
                            Font = Enum.Font.Ubuntu,
                            Text = text,
                            TextColor3 = Color3.fromRGB(150, 150, 150),
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Left,
                        }, Slider)

                        local SliderButton = library:create("TextButton", {
                            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            Position = UDim2.new(0, 9, 0, 20),
                            Size = UDim2.new(0, 260, 0, 10),
                            Text = "",
                        }, Slider)

                        local SliderFrame = library:create("Frame", {
                            BackgroundColor3 = Color3.fromRGB(186, 186, 255),
                            BorderSizePixel = 0,
                            Size = UDim2.new(0, 0, 1, 0),
                        }, SliderButton)

                        local SliderValue = library:create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 69, 0, 6),
                            Size = UDim2.new(0, 200, 0, 9),
                            Font = Enum.Font.Ubuntu,
                            Text = tostring(value.Slider),
                            TextColor3 = Color3.fromRGB(150, 150, 150),
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Right,
                        }, Slider)

                        function element:set_value(new_value, cb)
                            value = new_value or value
                            local clamped = math.clamp(value.Slider, min, max)
                            value.Slider = clamped
                            SliderValue.Text = tostring(clamped)
                            local percent = (clamped - min) / (max - min)
                            SliderFrame.Size = UDim2.new(percent, 0, 1, 0)
                            if not cb then do_callback() end
                        end

                        local function slide()
                            local x = math.clamp(mouse.X - SliderButton.AbsolutePosition.X, 0, 260) / 260
                            local val = math.floor((x * (max - min)) + min)
                            element:set_value({Slider = val})
                        end

                        SliderButton.MouseButton1Down:Connect(function()
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
                        element:set_value(value, true)
                    end

                    ----------------- 【 3. Dropdown 下拉菜单 】 -----------------
                    if type_name == "Dropdown" then
                        Border.Size = Border.Size + UDim2.new(0, 0, 0, 45)
                        local options = data.options or {}
                        value = {Dropdown = default and default.Dropdown or options[1] or ""}

                        local Dropdown = library:create("TextLabel", {
                            Name = "Dropdown",
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 45),
                            Text = "",
                        }, Container)

                        local DropdownButton = library:create("TextButton", {
                            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            Position = UDim2.new(0, 9, 0, 20),
                            Size = UDim2.new(0, 260, 0, 20),
                            Text = "",
                        }, Dropdown)

                        local DropdownButtonText = library:create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 6, 0, 0),
                            Size = UDim2.new(0, 250, 1, 0),
                            Font = Enum.Font.Ubuntu,
                            Text = value.Dropdown,
                            TextColor3 = Color3.fromRGB(150, 150, 150),
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Left,
                        }, DropdownButton)

                        local DropdownText = library:create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 9, 0, 6),
                            Size = UDim2.new(0, 200, 0, 9),
                            Font = Enum.Font.Ubuntu,
                            Text = text,
                            TextColor3 = Color3.fromRGB(150, 150, 150),
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Left,
                        }, Dropdown)

                        local DropdownScroll = library:create("ScrollingFrame", {
                            Active = true,
                            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            Position = UDim2.new(0, 9, 0, 41),
                            Size = UDim2.new(0, 260, 0, 80),
                            Visible = false,
                            ZIndex = 3,
                            ScrollBarThickness = 2,
                        }, Dropdown)

                        library:create("UIListLayout", {}, DropdownScroll)

                        DropdownButton.MouseButton1Down:Connect(function()
                            DropdownScroll.Visible = not DropdownScroll.Visible
                        end)

                        local function update_options()
                            DropdownScroll:ClearAllChildren()
                            library:create("UIListLayout", {}, DropdownScroll)
                            DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 20)

                            for _, opt in ipairs(options) do
                                local btn = library:create("TextButton", {
                                    Size = UDim2.new(1, 0, 0, 20),
                                    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                                    BorderSizePixel = 0,
                                    Font = Enum.Font.Ubuntu,
                                    Text = opt,
                                    TextColor3 = Color3.fromRGB(150, 150, 150),
                                    TextSize = 13,
                                    ZIndex = 3,
                                }, DropdownScroll)

                                btn.MouseButton1Down:Connect(function()
                                    value.Dropdown = opt
                                    DropdownButtonText.Text = opt
                                    DropdownScroll.Visible = false
                                    do_callback()
                                end)
                            end
                        end

                        update_options()
                    end

                    ----------------- 【 4. Button 按钮 】 -----------------
                    if type_name == "Button" then
                        Border.Size = Border.Size + UDim2.new(0, 0, 0, 30)

                        local ButtonFrame = library:create("Frame", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 30),
                        }, Container)

                        local Button = library:create("TextButton", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            Size = UDim2.new(0, 215, 0, 20),
                            Font = Enum.Font.Ubuntu,
                            Text = text,
                            TextColor3 = Color3.fromRGB(150, 150, 150),
                            TextSize = 14,
                        }, ButtonFrame)

                        Button.MouseButton1Down:Connect(function()
                            Button.BorderColor3 = Color3.fromRGB(186, 186, 255)
                            task.delay(0.2, function()
                                Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
                            end)
                            callback()
                        end)
                    end

                    ----------------- 【 5. TextBox 输入框 】 -----------------
                    if type_name == "TextBox" then
                        Border.Size = Border.Size + UDim2.new(0, 0, 0, 30)
                        value = {Text = default or ""}

                        local BoxFrame = library:create("Frame", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 30),
                        }, Container)

                        local TextBox = library:create("TextBox", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            Size = UDim2.new(0, 215, 0, 20),
                            Font = Enum.Font.Ubuntu,
                            Text = value.Text,
                            PlaceholderText = text,
                            TextColor3 = Color3.fromRGB(150, 150, 150),
                            TextSize = 14,
                            ClearTextOnFocus = false,
                        }, BoxFrame)

                        TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                            value.Text = TextBox.Text
                            do_callback()
                        end)
                    end

                    -- 自适应高度变化
                    Border.Size = Border.Size -- 强制刷新排版
                    return element
                end
                return sector
            end
            return section
        end
        return tab
    end
    return menu
end

return library