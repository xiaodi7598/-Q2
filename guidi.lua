--[[ 
    FILENAME: UILibrary (ModuleScript)
    PARENT: ReplicatedStorage
    STATUS: Dynamic Theme Support + Resizable Fixed
]]
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Library = {}

--// Theme Palette (Default Dark Glass)
local Theme = {
    Main = Color3.fromRGB(20, 20, 20),
    TopBar = Color3.fromRGB(25, 25, 25),
    DrawerBG = Color3.fromRGB(15, 15, 15),
    Content = Color3.fromRGB(22, 22, 22),
    Element = Color3.fromRGB(32, 32, 32),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(160, 160, 160),
    Accent = Color3.fromRGB(255, 60, 90),
    Outline = Color3.fromRGB(50, 50, 50),
    Gradient1 = Color3.fromRGB(255, 255, 255),
    Gradient2 = Color3.fromRGB(180, 180, 180),
    ActiveText = Color3.fromRGB(20, 20, 20)
}

--// Theme Registry (Keeps track of what elements use what colors)
local ThemeRegistry = {}

local function RegisterThemeLink(obj, prop, themeKey)
    if not ThemeRegistry[themeKey] then
        ThemeRegistry[themeKey] = {}
    end
    table.insert(ThemeRegistry[themeKey], {Obj = obj, Prop = prop})
    -- Apply initial color
    obj[prop] = Theme[themeKey]
end

--// Helper Functions
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    return inst
end

local function Round(obj, radius)
    Create("UICorner", {CornerRadius = UDim.new(0, radius), Parent = obj})
end

local function Stroke(obj, color, thickness)
    local s =
        Create(
        "UIStroke",
        {
            Color = color,
            Thickness = thickness,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = obj,
            Transparency = 0.5
        }
    )
    RegisterThemeLink(s, "Color", "Outline")
end

--// Resizer Fix
local function MakeResizable(frame, minSize)
    local Resizer =
        Create(
        "ImageButton",
        {
            Name = "ResizeHandle",
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -16, 1, -16),
            Size = UDim2.new(0, 16, 0, 16),
            Image = "rbxassetid://6035288547",
            ImageColor3 = Theme.Text, -- Make sure it's visible
            ZIndex = 200 -- Ensure it's on top of everything
        }
    )
    RegisterThemeLink(Resizer, "ImageColor3", "Text")

    local Dragging, StartSize, StartPos = false, Vector2.new(0, 0), Vector2.new(0, 0)
    Resizer.InputBegan:Connect(
        function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging, StartSize, StartPos = true, frame.AbsoluteSize, input.Position
            end
        end
    )
    UserInputService.InputChanged:Connect(
        function(input)
            if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local Delta = input.Position - StartPos
                frame.Size =
                    UDim2.new(
                    0,
                    math.max(minSize.X, StartSize.X + Delta.X),
                    0,
                    math.max(minSize.Y, StartSize.Y + Delta.Y)
                )
            end
        end
    )
    UserInputService.InputEnded:Connect(
        function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging = false
            end
        end
    )
end

--// Window Creation
function Library:Window(options)
    local Title = options.Title or "UI Library"
    local WindowObj = {}

    -- Studio Safety Check
    local TargetParent = LocalPlayer:WaitForChild("PlayerGui")
    if not RunService:IsStudio() then
        pcall(
            function()
                if game:GetService("CoreGui") then
                    TargetParent = game:GetService("CoreGui")
                end
            end
        )
    end

    local ScreenGui =
        Create("ScreenGui", {Name = Title, Parent = TargetParent, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})

    -- Main Frame
    local MainFrame =
        Create(
        "Frame",
        {
            Name = "MainFrame",
            Parent = ScreenGui,
            BackgroundColor3 = Theme.Main, -- Initial set
            BackgroundTransparency = 0.05,
            Position = UDim2.new(0.5, -275, 0.5, -200),
            Size = UDim2.new(0, 550, 0, 400),
            ClipsDescendants = true
        }
    )
    RegisterThemeLink(MainFrame, "BackgroundColor3", "Main") -- Register for updates
    Round(MainFrame, 8)
    Stroke(MainFrame, Theme.Outline, 1.5)

    -- Noise Texture
    local GlassTexture =
        Create(
        "ImageLabel",
        {
            Parent = MainFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Image = "rbxassetid://16657395094",
            ImageTransparency = 0.94,
            ZIndex = 0
        }
    )

    MakeResizable(MainFrame, Vector2.new(350, 250))

    -- Draggable
    local Dragging, DragInput, DragStart, StartPos
    MainFrame.InputBegan:Connect(
        function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging, DragStart, StartPos = true, input.Position, MainFrame.Position
            end
        end
    )
    UserInputService.InputChanged:Connect(
        function(input)
            if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - DragStart
                TweenService:Create(
                    MainFrame,
                    TweenInfo.new(0.05),
                    {
                        Position = UDim2.new(
                            StartPos.X.Scale,
                            StartPos.X.Offset + delta.X,
                            StartPos.Y.Scale,
                            StartPos.Y.Offset + delta.Y
                        )
                    }
                ):Play()
            end
        end
    )
    UserInputService.InputEnded:Connect(
        function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging = false
            end
        end
    )

    --// Top Bar
    local TopBar =
        Create(
        "Frame",
        {
            Name = "TopBar",
            Parent = MainFrame,
            BackgroundColor3 = Theme.TopBar,
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, 0, 0, 40),
            ZIndex = 20
        }
    )
    RegisterThemeLink(TopBar, "BackgroundColor3", "TopBar")

    local HamButton =
        Create(
        "ImageButton",
        {
            Parent = TopBar,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0.5, -10),
            Size = UDim2.new(0, 20, 0, 20),
            Image = "rbxassetid://6031091004",
            ImageColor3 = Theme.Text,
            ZIndex = 21
        }
    )
    RegisterThemeLink(HamButton, "ImageColor3", "Text")

    local TitleLbl =
        Create(
        "TextLabel",
        {
            Parent = TopBar,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 45, 0, 0),
            Size = UDim2.new(1, -50, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = Title,
            TextColor3 = Theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 21
        }
    )
    RegisterThemeLink(TitleLbl, "TextColor3", "Text")

    --// DRAWER
    local DrawerOverlay =
        Create(
        "Frame",
        {
            Name = "Drawer",
            Parent = MainFrame,
            BackgroundColor3 = Theme.DrawerBG,
            Position = UDim2.new(-1, 0, 0, 40),
            Size = UDim2.new(1, 0, 1, -40),
            ZIndex = 50,
            BorderSizePixel = 0
        }
    )
    RegisterThemeLink(DrawerOverlay, "BackgroundColor3", "DrawerBG")

    Create(
        "UIGradient",
        {
            Parent = DrawerOverlay,
            Rotation = 0,
            Transparency = NumberSequence.new(
                {
                    NumberSequenceKeypoint.new(0.0, 0.0),
                    NumberSequenceKeypoint.new(0.4, 0.0),
                    NumberSequenceKeypoint.new(1.0, 0.8)
                }
            )
        }
    )

    local ButtonContainer =
        Create(
        "Frame",
        {
            Parent = DrawerOverlay,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = 51
        }
    )

    Create(
        "UIListLayout",
        {
            Parent = ButtonContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center
        }
    )

    --// Pages
    local PageContainer =
        Create(
        "Frame",
        {
            Name = "Pages",
            Parent = MainFrame,
            BackgroundColor3 = Theme.Content,
            BackgroundTransparency = 0.8,
            Position = UDim2.new(0, 0, 0, 40),
            Size = UDim2.new(1, 0, 1, -40),
            ZIndex = 1
        }
    )
    RegisterThemeLink(PageContainer, "BackgroundColor3", "Content")

    --// Drawer Animation
    local DrawerOpen = false
    local function ToggleDrawer(forceClose)
        if forceClose then
            DrawerOpen = true
        end
        DrawerOpen = not DrawerOpen
        local Goal = DrawerOpen and UDim2.new(0, 0, 0, 40) or UDim2.new(-1, 0, 0, 40)
        local Rot = DrawerOpen and 90 or 0
        local Col = DrawerOpen and Theme.Accent or Theme.Text

        TweenService:Create(
            DrawerOverlay,
            TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = Goal}
        ):Play()
        TweenService:Create(HamButton, TweenInfo.new(0.3), {Rotation = Rot, ImageColor3 = Col}):Play()
    end
    HamButton.MouseButton1Click:Connect(
        function()
            ToggleDrawer(false)
        end
    )

    --// THEME SETTER FUNCTION (PUBLIC)
    function WindowObj:SetTheme(key, color)
        if Theme[key] then
            Theme[key] = color
            if ThemeRegistry[key] then
                for _, link in pairs(ThemeRegistry[key]) do
                    -- Smoothly transition colors
                    TweenService:Create(link.Obj, TweenInfo.new(0.3), {[link.Prop] = color}):Play()
                end
            end

            -- Special case for Accent color affecting drawer button
            if key == "Accent" and DrawerOpen then
                TweenService:Create(HamButton, TweenInfo.new(0.3), {ImageColor3 = color}):Play()
            end
        end
    end

    --// Tabs System
    WindowObj.Tabs = {}
    local FirstTab = true
    local TabInstances = {}

    function WindowObj:Tab(name, iconId)
        local TabFuncs = {}

        local TabBtn =
            Create(
            "TextButton",
            {
                Parent = ButtonContainer,
                BackgroundColor3 = Theme.Gradient1,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 32),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 55
            }
        )
        Round(TabBtn, 20)
        Create("UIPadding", {Parent = TabBtn, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)})

        local BtnScale = Create("UIScale", {Parent = TabBtn, Scale = 1})
        local BtnGradient =
            Create(
            "UIGradient",
            {
                Parent = TabBtn,
                Color = ColorSequence.new {
                    ColorSequenceKeypoint.new(0, Theme.Gradient1),
                    ColorSequenceKeypoint.new(1, Theme.Gradient2)
                },
                Rotation = 45,
                Enabled = false
            }
        )

        local Layout =
            Create(
            "UIListLayout",
            {
                Parent = TabBtn,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6)
            }
        )

        local Icon =
            Create(
            "ImageLabel",
            {
                Parent = TabBtn,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://" .. (iconId or "0"),
                ImageColor3 = Theme.SubText,
                ZIndex = 56
            }
        )
        RegisterThemeLink(Icon, "ImageColor3", "SubText")

        local Label =
            Create(
            "TextLabel",
            {
                Parent = TabBtn,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Font = Enum.Font.GothamBold,
                Text = name,
                TextColor3 = Theme.SubText,
                TextSize = 12,
                ZIndex = 56
            }
        )
        RegisterThemeLink(Label, "TextColor3", "SubText")

        local Page =
            Create(
            "ScrollingFrame",
            {
                Parent = PageContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                Visible = false,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Theme.Accent
            }
        )
        RegisterThemeLink(Page, "ScrollBarImageColor3", "Accent")
        Create(
            "UIPadding",
            {
                Parent = Page,
                PaddingTop = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12)
            }
        )
        local PageLayout =
            Create("UIListLayout", {Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
            function()
                Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 24)
            end
        )

        TabBtn.MouseEnter:Connect(
            function()
                TweenService:Create(BtnScale, TweenInfo.new(0.2), {Scale = 1.15}):Play()
            end
        )
        TabBtn.MouseLeave:Connect(
            function()
                TweenService:Create(BtnScale, TweenInfo.new(0.2), {Scale = 1.0}):Play()
            end
        )

        local function Activate()
            for _, t in pairs(TabInstances) do
                TweenService:Create(t.Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                if t.Gradient then
                    t.Gradient.Enabled = false
                end
                TweenService:Create(t.Label, TweenInfo.new(0.2), {TextColor3 = Theme.SubText}):Play()
                TweenService:Create(t.Icon, TweenInfo.new(0.2), {ImageColor3 = Theme.SubText}):Play()
            end
            for _, p in pairs(PageContainer:GetChildren()) do
                if p:IsA("ScrollingFrame") then
                    p.Visible = false
                end
            end

            Page.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            BtnGradient.Enabled = true
            TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Theme.ActiveText}):Play()
            TweenService:Create(Icon, TweenInfo.new(0.2), {ImageColor3 = Theme.ActiveText}):Play()
            ToggleDrawer(true)
        end

        TabBtn.MouseButton1Click:Connect(Activate)
        table.insert(TabInstances, {Btn = TabBtn, Gradient = BtnGradient, Label = Label, Icon = Icon})

        if FirstTab then
            Activate()
            ToggleDrawer(true)
            FirstTab = false
        end

        --// SECTIONS
        function TabFuncs:Section(text)
            local SecFuncs = {}
            local Box =
                Create(
                "Frame",
                {
                    Parent = Page,
                    BackgroundColor3 = Theme.TopBar,
                    BackgroundTransparency = 0.3,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y
                }
            )
            RegisterThemeLink(Box, "BackgroundColor3", "TopBar")
            Round(Box, 6)
            Stroke(Box, Theme.Outline, 1)

            local SecTitle =
                Create(
                "TextLabel",
                {
                    Parent = Box,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 6),
                    Size = UDim2.new(1, -20, 0, 14),
                    Font = Enum.Font.GothamBold,
                    Text = text,
                    TextColor3 = Theme.SubText,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                }
            )
            RegisterThemeLink(SecTitle, "TextColor3", "SubText")

            local Container =
                Create(
                "Frame",
                {
                    Parent = Box,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 8, 0, 24),
                    Size = UDim2.new(1, -16, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y
                }
            )
            Create(
                "UIListLayout",
                {Parent = Container, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)}
            )
            Create("UIPadding", {Parent = Container, PaddingBottom = UDim.new(0, 8)})

            function SecFuncs:Toggle(text, default, callback)
                local Active = default or false
                local TFrame =
                    Create(
                    "TextButton",
                    {
                        Parent = Container,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 26),
                        Text = "",
                        AutoButtonColor = false
                    }
                )
                local Lbl =
                    Create(
                    "TextLabel",
                    {
                        Parent = TFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.7, 0, 1, 0),
                        Font = Enum.Font.Gotham,
                        Text = text,
                        TextColor3 = Theme.SubText,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left
                    }
                )
                RegisterThemeLink(Lbl, "TextColor3", "SubText")
                local CB =
                    Create(
                    "Frame",
                    {
                        Parent = TFrame,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.new(0, 18, 0, 18),
                        BackgroundColor3 = Theme.Element
                    }
                )
                Round(CB, 4)
                Stroke(CB, Theme.Outline, 1)
                RegisterThemeLink(CB, "BackgroundColor3", "Element")
                local Check =
                    Create(
                    "Frame",
                    {
                        Parent = CB,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(0, 0, 0, 0),
                        BackgroundColor3 = Theme.Accent
                    }
                )
                Round(Check, 3)
                RegisterThemeLink(Check, "BackgroundColor3", "Accent")

                local function Upd()
                    TweenService:Create(
                        Check,
                        TweenInfo.new(0.2),
                        {Size = Active and UDim2.new(0, 12, 0, 12) or UDim2.new(0, 0, 0, 0)}
                    ):Play()
                    TweenService:Create(Lbl, TweenInfo.new(0.2), {TextColor3 = Active and Theme.Text or Theme.SubText}):Play(

                    )
                    if callback then
                        callback(Active)
                    end
                end
                TFrame.MouseButton1Click:Connect(
                    function()
                        Active = not Active
                        Upd()
                    end
                )
                if Active then
                    Upd()
                end
            end

            function SecFuncs:Slider(text, options, callback)
                local min, max, def = options.min or 0, options.max or 100, options.default or min
                local val = def
                local SFrame =
                    Create("Frame", {Parent = Container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32)})
                local Lbl =
                    Create(
                    "TextLabel",
                    {
                        Parent = SFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 16),
                        Font = Enum.Font.Gotham,
                        Text = text,
                        TextColor3 = Theme.SubText,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left
                    }
                )
                RegisterThemeLink(Lbl, "TextColor3", "SubText")
                local ValL =
                    Create(
                    "TextLabel",
                    {
                        Parent = SFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 16),
                        Font = Enum.Font.Gotham,
                        Text = tostring(val),
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Right
                    }
                )
                RegisterThemeLink(ValL, "TextColor3", "Text")
                local Track =
                    Create(
                    "TextButton",
                    {
                        Parent = SFrame,
                        BackgroundColor3 = Theme.Element,
                        Position = UDim2.new(0, 0, 0, 22),
                        Size = UDim2.new(1, 0, 0, 4),
                        Text = "",
                        AutoButtonColor = false
                    }
                )
                Round(Track, 4)
                RegisterThemeLink(Track, "BackgroundColor3", "Element")
                local Fill =
                    Create(
                    "Frame",
                    {
                        Parent = Track,
                        BackgroundColor3 = Theme.Accent,
                        Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
                    }
                )
                Round(Fill, 4)
                RegisterThemeLink(Fill, "BackgroundColor3", "Accent")

                local Dragging = false
                local function Update(input)
                    local p = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    val = math.floor(min + (max - min) * p)
                    ValL.Text = tostring(val)
                    TweenService:Create(Fill, TweenInfo.new(0.05), {Size = UDim2.new(p, 0, 1, 0)}):Play()
                    if callback then
                        callback(val)
                    end
                end
                Track.InputBegan:Connect(
                    function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then
                            Dragging = true
                            Update(i)
                        end
                    end
                )
                UserInputService.InputEnded:Connect(
                    function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then
                            Dragging = false
                        end
                    end
                )
                UserInputService.InputChanged:Connect(
                    function(i)
                        if Dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                            Update(i)
                        end
                    end
                )
            end

            function SecFuncs:Button(text, callback)
                local Btn =
                    Create(
                    "TextButton",
                    {
                        Parent = Container,
                        BackgroundColor3 = Theme.Element,
                        Size = UDim2.new(1, 0, 0, 26),
                        Font = Enum.Font.Gotham,
                        Text = text,
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        AutoButtonColor = false
                    }
                )
                Round(Btn, 4)
                Stroke(Btn, Theme.Outline, 1)
                RegisterThemeLink(Btn, "BackgroundColor3", "Element")
                RegisterThemeLink(Btn, "TextColor3", "Text")
                Btn.MouseButton1Click:Connect(
                    function()
                        spawn(
                            function()
                                local C =
                                    Create(
                                    "ImageLabel",
                                    {
                                        Name = "R",
                                        Parent = Btn,
                                        BackgroundTransparency = 1,
                                        Image = "rbxassetid://266543268",
                                        ImageColor3 = Color3.new(1, 1, 1),
                                        ImageTransparency = 0.8,
                                        Position = UDim2.new(
                                            0,
                                            Mouse.X - Btn.AbsolutePosition.X,
                                            0,
                                            Mouse.Y - Btn.AbsolutePosition.Y
                                        ),
                                        Size = UDim2.new(0, 0, 0, 0),
                                        ZIndex = 60
                                    }
                                )
                                TweenService:Create(
                                    C,
                                    TweenInfo.new(0.4),
                                    {
                                        Size = UDim2.new(0, 150, 0, 150),
                                        Position = UDim2.new(0.5, -75, 0.5, -75),
                                        ImageTransparency = 1
                                    }
                                ):Play()
                                wait(0.4)
                                C:Destroy()
                            end
                        )
                        if callback then
                            callback()
                        end
                    end
                )
            end

            function SecFuncs:Dropdown(text, items, callback)
                local IsOpen = false
                local DFrame =
                    Create(
                    "Frame",
                    {
                        Parent = Container,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        ClipsDescendants = true
                    }
                )
                local Header =
                    Create(
                    "TextButton",
                    {
                        Parent = DFrame,
                        BackgroundColor3 = Theme.Element,
                        Size = UDim2.new(1, 0, 0, 30),
                        Font = Enum.Font.Gotham,
                        Text = "  " .. text,
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutoButtonColor = false
                    }
                )
                Round(Header, 4)
                Stroke(Header, Theme.Outline, 1)
                RegisterThemeLink(Header, "BackgroundColor3", "Element")
                RegisterThemeLink(Header, "TextColor3", "Text")
                local Icon =
                    Create(
                    "ImageLabel",
                    {
                        Parent = Header,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -8, 0.5, 0),
                        Size = UDim2.new(0, 12, 0, 12),
                        Image = "rbxassetid://6034818379",
                        ImageColor3 = Theme.SubText,
                        BackgroundTransparency = 1
                    }
                )
                RegisterThemeLink(Icon, "ImageColor3", "SubText")

                local List =
                    Create(
                    "Frame",
                    {
                        Parent = DFrame,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 34),
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y
                    }
                )
                local ListLayout =
                    Create(
                    "UIListLayout",
                    {Parent = List, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}
                )

                for _, item in pairs(items) do
                    local IB =
                        Create(
                        "TextButton",
                        {
                            Parent = List,
                            BackgroundColor3 = Theme.Element,
                            Size = UDim2.new(1, 0, 0, 24),
                            Font = Enum.Font.Gotham,
                            Text = item,
                            TextColor3 = Theme.SubText,
                            TextSize = 11,
                            AutoButtonColor = false
                        }
                    )
                    Round(IB, 4)
                    RegisterThemeLink(IB, "BackgroundColor3", "Element")
                    RegisterThemeLink(IB, "TextColor3", "SubText")
                    IB.MouseButton1Click:Connect(
                        function()
                            Header.Text = "  " .. text .. ": " .. item
                            IsOpen = false
                            TweenService:Create(DFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 30)}):Play()
                            TweenService:Create(Icon, TweenInfo.new(0.2), {Rotation = 0}):Play()
                            if callback then
                                callback(item)
                            end
                        end
                    )
                end
                Header.MouseButton1Click:Connect(
                    function()
                        IsOpen = not IsOpen
                        local Height = IsOpen and (34 + ListLayout.AbsoluteContentSize.Y + 4) or 30
                        TweenService:Create(DFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, Height)}):Play()
                        TweenService:Create(Icon, TweenInfo.new(0.3), {Rotation = IsOpen and 180 or 0}):Play()
                    end
                )
            end

            function SecFuncs:ColorPicker(text, default, callback)
                local CurrentColor = default or Color3.fromRGB(255, 255, 255)
                local Open = false
                local CFrame =
                    Create(
                    "Frame",
                    {
                        Parent = Container,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 26),
                        ClipsDescendants = true
                    }
                )
                local Header =
                    Create(
                    "TextButton",
                    {
                        Parent = CFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 26),
                        Text = "",
                        AutoButtonColor = false
                    }
                )
                local Lbl =
                    Create(
                    "TextLabel",
                    {
                        Parent = Header,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.7, 0, 1, 0),
                        Font = Enum.Font.Gotham,
                        Text = text,
                        TextColor3 = Theme.SubText,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left
                    }
                )
                RegisterThemeLink(Lbl, "TextColor3", "SubText")
                local Preview =
                    Create(
                    "Frame",
                    {
                        Parent = Header,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.new(0, 26, 0, 16),
                        BackgroundColor3 = CurrentColor
                    }
                )
                Round(Preview, 4)
                Stroke(Preview, Theme.Outline, 1)

                local Sliders =
                    Create(
                    "Frame",
                    {
                        Parent = CFrame,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 26),
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y
                    }
                )
                local SLayout = Create("UIListLayout", {Parent = Sliders, Padding = UDim.new(0, 4)})

                local function CreateRGB(colorName, initVal, colorCode)
                    local S =
                        Create("Frame", {Parent = Sliders, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20)})
                    local Bar =
                        Create(
                        "TextButton",
                        {
                            Parent = S,
                            BackgroundColor3 = Theme.Element,
                            Position = UDim2.new(0, 0, 0.5, -2),
                            Size = UDim2.new(1, 0, 0, 4),
                            Text = "",
                            AutoButtonColor = false
                        }
                    )
                    Round(Bar, 4)
                    RegisterThemeLink(Bar, "BackgroundColor3", "Element")
                    local Fill =
                        Create(
                        "Frame",
                        {Parent = Bar, BackgroundColor3 = colorCode, Size = UDim2.new(initVal / 255, 0, 1, 0)}
                    )
                    Round(Fill, 4)
                    local dragging, Update = false, function(input)
                            local p = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                            TweenService:Create(Fill, TweenInfo.new(0.05), {Size = UDim2.new(p, 0, 1, 0)}):Play()
                            local r, g, b = CurrentColor.R * 255, CurrentColor.G * 255, CurrentColor.B * 255
                            if colorName == "R" then
                                r = p * 255
                            elseif colorName == "G" then
                                g = p * 255
                            else
                                b = p * 255
                            end
                            CurrentColor = Color3.fromRGB(r, g, b)
                            Preview.BackgroundColor3 = CurrentColor
                            if callback then
                                callback(CurrentColor)
                            end
                        end
                    Bar.InputBegan:Connect(
                        function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = true
                                Update(i)
                            end
                        end
                    )
                    UserInputService.InputEnded:Connect(
                        function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = false
                            end
                        end
                    )
                    UserInputService.InputChanged:Connect(
                        function(i)
                            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                                Update(i)
                            end
                        end
                    )
                end
                CreateRGB("R", CurrentColor.R * 255, Color3.fromRGB(255, 50, 50))
                CreateRGB("G", CurrentColor.G * 255, Color3.fromRGB(50, 255, 50))
                CreateRGB("B", CurrentColor.B * 255, Color3.fromRGB(50, 50, 255))
                Header.MouseButton1Click:Connect(
                    function()
                        Open = not Open
                        local H = Open and (26 + SLayout.AbsoluteContentSize.Y + 4) or 26
                        TweenService:Create(CFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, H)}):Play()
                    end
                )
            end

            return SecFuncs
        end
        return TabFuncs
    end
    return WindowObj
end

return Library