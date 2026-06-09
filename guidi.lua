--[[
    Kavo UI 库 - 手机端中文版
    支持触摸拖动、大按钮、屏幕适配
]]

local Kavo = {}

local tween = game:GetService("TweenService")
local tweeninfo = TweenInfo.new
local input = game:GetService("UserInputService")
local run = game:GetService("RunService")

local Utility = {}
local Objects = {}

-- 🔵 手机端拖动功能（支持触摸）
function Kavo:DraggingEnabled(frame, parent)
    parent = parent or frame
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local touchInput = nil
    
    -- 鼠标拖动（电脑）
    frame.InputBegan:Connect(function(inputObj)
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inputObj.Position
            startPos = parent.Position
            
            inputObj.Changed:Connect(function()
                if inputObj.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    -- 触摸拖动（手机）
    frame.TouchTap:Connect(function() end) -- 避免触摸穿透
    frame.TouchLongPress:Connect(function() end)
    
    frame.InputBegan:Connect(function(inputObj)
        if inputObj.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inputObj.Position
            startPos = parent.Position
            touchInput = inputObj
        end
    end)
    
    frame.InputEnded:Connect(function(inputObj)
        if inputObj.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            touchInput = nil
        end
    end)
    
    -- 触摸移动
    input.TouchMoved:Connect(function(touch)
        if dragging and touchInput then
            local delta = touch.Position - dragStart
            parent.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- 鼠标移动
    frame.InputChanged:Connect(function(inputObj)
        if inputObj.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = inputObj.Position - dragStart
            parent.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Utility:TweenObject(obj, properties, duration, ...)
    tween:Create(obj, tweeninfo(duration, ...), properties):Play()
end

-- 🎨 主题配置
local themes = {
    SchemeColor = Color3.fromRGB(35,35,35),
    Background = Color3.fromRGB(25, 25, 25),
    Header = Color3.fromRGB(34, 34, 34),
    TextColor = Color3.fromRGB(240,240,240),
    ElementColor = Color3.fromRGB(35, 35, 35)
}

local themeStyles = {
    Ocean = {
        SchemeColor = Color3.fromRGB(35,35,35),
        Background = Color3.fromRGB(25, 25, 25),
        Header = Color3.fromRGB(34, 34, 34),
        TextColor = Color3.fromRGB(240,240,240),
        ElementColor = Color3.fromRGB(35, 35, 35)
    },
}

-- 📱 获取屏幕尺寸（用于适配）
local function getScreenSize()
    local viewport = game:GetService("Workspace").CurrentCamera.ViewportSize
    return viewport.X, viewport.Y
end

local LibName = tostring(math.random(1, 100))..tostring(math.random(1,50))..tostring(math.random(1, 100))

function Kavo:ToggleUI()
    if game.CoreGui[LibName].Enabled then
        game.CoreGui[LibName].Enabled = false
    else
        game.CoreGui[LibName].Enabled = true
    end
end

function Kavo.CreateLib(kavName, themeList)
    themeList = themeStyles.Ocean
    themeList = themeList or {}
    local selectedTab 
    kavName = kavName or "脚本菜单"
    
    for i,v in pairs(game.CoreGui:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name == kavName then
            v:Destroy()
        end
    end
    
    -- 📱 获取屏幕尺寸并设置窗口大小
    local screenX, screenY = getScreenSize()
    local windowWidth = math.min(400, screenX - 40)  -- 手机适配宽度
    local windowHeight = math.min(500, screenY - 100) -- 手机适配高度
    local windowX = (screenX - windowWidth) / 2
    local windowY = (screenY - windowHeight) / 2
    
    local ScreenGui = Instance.new("ScreenGui")
    local Main = Instance.new("Frame")
    local MainCorner = Instance.new("UICorner")
    local MainHeader = Instance.new("Frame")
    local headerCover = Instance.new("UICorner")
    local coverup = Instance.new("Frame")
    local title = Instance.new("TextLabel")
    local close = Instance.new("ImageButton")
    local MainSide = Instance.new("Frame")
    local sideCorner = Instance.new("UICorner")
    local coverup_2 = Instance.new("Frame")
    local tabFrames = Instance.new("Frame")
    local tabListing = Instance.new("UIListLayout")
    local pages = Instance.new("Frame")
    local Pages = Instance.new("Folder")
    local infoContainer = Instance.new("Frame")
    local blurFrame = Instance.new("Frame")

    Kavo:DraggingEnabled(MainHeader, Main)

    blurFrame.Name = "blurFrame"
    blurFrame.Parent = pages
    blurFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blurFrame.BackgroundTransparency = 1
    blurFrame.BorderSizePixel = 0
    blurFrame.Size = UDim2.new(1, 0, 1, 0)
    blurFrame.ZIndex = 999

    ScreenGui.Parent = game.CoreGui
    ScreenGui.Name = LibName
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = themeList.Background
    Main.ClipsDescendants = true
    Main.Position = UDim2.new(0, windowX, 0, windowY)
    Main.Size = UDim2.new(0, windowWidth, 0, windowHeight)

    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Name = "MainCorner"
    MainCorner.Parent = Main

    -- 顶部栏
    MainHeader.Name = "MainHeader"
    MainHeader.Parent = Main
    MainHeader.BackgroundColor3 = themeList.Header
    Objects[MainHeader] = "BackgroundColor3"
    MainHeader.Size = UDim2.new(1, 0, 0, 45)  -- 手机端更高
    headerCover.CornerRadius = UDim.new(0, 8)
    headerCover.Name = "headerCover"
    headerCover.Parent = MainHeader

    coverup.Name = "coverup"
    coverup.Parent = MainHeader
    coverup.BackgroundColor3 = themeList.Header
    Objects[coverup] = "BackgroundColor3"
    coverup.BorderSizePixel = 0
    coverup.Position = UDim2.new(0, 0, 0.758620679, 0)
    coverup.Size = UDim2.new(1, 0, 0, 7)

    -- 标题
    title.Name = "title"
    title.Parent = MainHeader
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0.02, 0, 0, 0)
    title.Size = UDim2.new(0.8, 0, 1, 0)
    title.Font = Enum.Font.Gotham
    title.Text = kavName
    title.TextColor3 = Color3.fromRGB(245, 245, 245)
    title.TextSize = 20  -- 手机端更大
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center

    -- 关闭按钮
    close.Name = "close"
    close.Parent = MainHeader
    close.BackgroundTransparency = 1
    close.AnchorPoint = Vector2.new(1, 0.5)
    close.Position = UDim2.new(0.98, 0, 0.5, 0)
    close.Size = UDim2.new(0, 32, 0, 32)  -- 手机端更大
    close.Image = "rbxassetid://3926305904"
    close.ImageRectOffset = Vector2.new(284, 4)
    close.ImageRectSize = Vector2.new(24, 24)
    close.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    -- 手机触摸关闭
    close.TouchTap:Connect(function()
        ScreenGui:Destroy()
    end)

    -- 侧边栏（标签页列表）
    MainSide.Name = "MainSide"
    MainSide.Parent = Main
    MainSide.BackgroundColor3 = themeList.Header
    Objects[MainSide] = "Header"
    MainSide.Position = UDim2.new(0, 0, 0, 45)
    MainSide.Size = UDim2.new(0, 100, 1, -45)  -- 侧边栏更宽

    sideCorner.CornerRadius = UDim.new(0, 0)
    sideCorner.Name = "sideCorner"
    sideCorner.Parent = MainSide

    coverup_2.Name = "coverup"
    coverup_2.Parent = MainSide
    coverup_2.BackgroundColor3 = themeList.Header
    Objects[coverup_2] = "Header"
    coverup_2.BorderSizePixel = 0
    coverup_2.Position = UDim2.new(0.95, 0, 0, 0)
    coverup_2.Size = UDim2.new(0, 7, 1, 0)

    tabFrames.Name = "tabFrames"
    tabFrames.Parent = MainSide
    tabFrames.BackgroundTransparency = 1
    tabFrames.Position = UDim2.new(0, 5, 0, 5)
    tabFrames.Size = UDim2.new(1, -10, 1, -10)

    tabListing.Name = "tabListing"
    tabListing.Parent = tabFrames
    tabListing.SortOrder = Enum.SortOrder.LayoutOrder
    tabListing.Padding = UDim.new(0, 8)  -- 手机端间距更大

    -- 页面区域
    pages.Name = "pages"
    pages.Parent = Main
    pages.BackgroundTransparency = 1
    pages.Position = UDim2.new(0, 105, 0, 50)
    pages.Size = UDim2.new(1, -110, 1, -55)

    Pages.Name = "Pages"
    Pages.Parent = pages

    infoContainer.Name = "infoContainer"
    infoContainer.Parent = Main
    infoContainer.BackgroundTransparency = 1
    infoContainer.Position = UDim2.new(0.3, 0, 0.85, 0)
    infoContainer.Size = UDim2.new(0.7, 0, 0, 40)
    infoContainer.Visible = false

    -- 颜色更新循环
    coroutine.wrap(function()
        while wait() do
            Main.BackgroundColor3 = themeList.Background
            MainHeader.BackgroundColor3 = themeList.Header
            MainSide.BackgroundColor3 = themeList.Header
            coverup_2.BackgroundColor3 = themeList.Header
            coverup.BackgroundColor3 = themeList.Header
        end
    end)()

    function Kavo:ChangeColor(prope,color)
        if prope == "背景" then
            themeList.Background = color
        elseif prope == "主题色" then
            themeList.SchemeColor = color
        elseif prope == "顶部栏" then
            themeList.Header = color
        elseif prope == "文字颜色" then
            themeList.TextColor = color
        elseif prope == "元素颜色" then
            themeList.ElementColor = color
        end
    end
    
    local Tabs = {}
    local first = true

    function Tabs:新建标签页(tabName)
        tabName = tabName or "标签"
        local tabButton = Instance.new("TextButton")
        local UICorner = Instance.new("UICorner")
        local page = Instance.new("ScrollingFrame")
        local pageListing = Instance.new("UIListLayout")

        local function UpdateSize()
            local cS = pageListing.AbsoluteContentSize
            tween:Create(page, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                CanvasSize = UDim2.new(0, cS.X, 0, cS.Y)
            }):Play()
        end

        page.Name = "Page"
        page.Parent = Pages
        page.Active = true
        page.BackgroundColor3 = themeList.Background
        page.BorderSizePixel = 0
        page.Size = UDim2.new(1, 0, 1, 0)
        page.ScrollBarThickness = 5
        page.Visible = false
        page.ScrollBarImageColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 16, themeList.SchemeColor.g * 255 - 15, themeList.SchemeColor.b * 255 - 28)

        pageListing.Name = "pageListing"
        pageListing.Parent = page
        pageListing.SortOrder = Enum.SortOrder.LayoutOrder
        pageListing.Padding = UDim.new(0, 8)  -- 手机端间距更大

        tabButton.Name = tabName.."TabButton"
        tabButton.Parent = tabFrames
        tabButton.BackgroundColor3 = themeList.SchemeColor
        Objects[tabButton] = "SchemeColor"
        tabButton.Size = UDim2.new(1, 0, 0, 40)  -- 手机端更大
        tabButton.AutoButtonColor = false
        tabButton.Font = Enum.Font.Gotham
        tabButton.Text = tabName
        tabButton.TextColor3 = themeList.TextColor
        Objects[tabButton] = "TextColor3"
        tabButton.TextSize = 15  -- 手机端更大
        tabButton.BackgroundTransparency = 1

        if first then
            first = false
            page.Visible = true
            tabButton.BackgroundTransparency = 0
            UpdateSize()
        else
            page.Visible = false
            tabButton.BackgroundTransparency = 1
        end

        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = tabButton
        table.insert(Tabs, tabName)

        UpdateSize()
        page.ChildAdded:Connect(UpdateSize)
        page.ChildRemoved:Connect(UpdateSize)

        tabButton.MouseButton1Click:Connect(function()
            UpdateSize()
            for i,v in next, Pages:GetChildren() do
                v.Visible = false
            end
            page.Visible = true
            for i,v in next, tabFrames:GetChildren() do
                if v:IsA("TextButton") then
                    Utility:TweenObject(v, {BackgroundTransparency = 1}, 0.2)
                end
            end
            Utility:TweenObject(tabButton, {BackgroundTransparency = 0}, 0.2)
        end)
        
        -- 手机触摸点击
        tabButton.TouchTap:Connect(function()
            UpdateSize()
            for i,v in next, Pages:GetChildren() do
                v.Visible = false
            end
            page.Visible = true
            for i,v in next, tabFrames:GetChildren() do
                if v:IsA("TextButton") then
                    Utility:TweenObject(v, {BackgroundTransparency = 1}, 0.2)
                end
            end
            Utility:TweenObject(tabButton, {BackgroundTransparency = 0}, 0.2)
        end)
        
        local Sections = {}
        local focusing = false
        local viewDe = false

        coroutine.wrap(function()
            while wait() do
                page.BackgroundColor3 = themeList.Background
                page.ScrollBarImageColor3 = Color3.fromRGB(themeList.SchemeColor.r * 255 - 16, themeList.SchemeColor.g * 255 - 15, themeList.SchemeColor.b * 255 - 28)
                tabButton.TextColor3 = themeList.TextColor
                tabButton.BackgroundColor3 = themeList.SchemeColor
            end
        end)()

        function Sections:新建分区(secName, hidden)
            secName = secName or "分区"
            local sectionFunctions = {}
            local modules = {}
            hidden = hidden or false
            
            local sectionFrame = Instance.new("Frame")
            local sectionlistoknvm = Instance.new("UIListLayout")
            local sectionHead = Instance.new("Frame")
            local sHeadCorner = Instance.new("UICorner")
            local sectionName = Instance.new("TextLabel")
            local sectionInners = Instance.new("Frame")
            local sectionElListing = Instance.new("UIListLayout")
            
            if hidden then
                sectionHead.Visible = false
            else
                sectionHead.Visible = true
            end

            sectionFrame.Name = "sectionFrame"
            sectionFrame.Parent = page
            sectionFrame.BackgroundColor3 = themeList.Background
            sectionFrame.BorderSizePixel = 0
            
            sectionlistoknvm.Name = "sectionlistoknvm"
            sectionlistoknvm.Parent = sectionFrame
            sectionlistoknvm.SortOrder = Enum.SortOrder.LayoutOrder
            sectionlistoknvm.Padding = UDim.new(0, 5)

            sectionHead.Name = "sectionHead"
            sectionHead.Parent = sectionFrame
            sectionHead.BackgroundColor3 = themeList.SchemeColor
            Objects[sectionHead] = "BackgroundColor3"
            sectionHead.Size = UDim2.new(1, 0, 0, 40)  -- 手机端更高
            sectionHead.ClipsDescendants = true

            sHeadCorner.CornerRadius = UDim.new(0, 8)
            sHeadCorner.Name = "sHeadCorner"
            sHeadCorner.Parent = sectionHead

            sectionName.Name = "sectionName"
            sectionName.Parent = sectionHead
            sectionName.BackgroundTransparency = 1
            sectionName.Position = UDim2.new(0.02, 0, 0, 0)
            sectionName.Size = UDim2.new(0.98, 0, 1, 0)
            sectionName.Font = Enum.Font.Gotham
            sectionName.Text = secName
            sectionName.RichText = true
            sectionName.TextColor3 = themeList.TextColor
            Objects[sectionName] = "TextColor3"
            sectionName.TextSize = 16
            sectionName.TextXAlignment = Enum.TextXAlignment.Left
            sectionName.TextYAlignment = Enum.TextYAlignment.Center

            sectionInners.Name = "sectionInners"
            sectionInners.Parent = sectionFrame
            sectionInners.BackgroundTransparency = 1
            sectionInners.Position = UDim2.new(0, 0, 0, 40)

            sectionElListing.Name = "sectionElListing"
            sectionElListing.Parent = sectionInners
            sectionElListing.SortOrder = Enum.SortOrder.LayoutOrder
            sectionElListing.Padding = UDim.new(0, 8)  -- 手机端间距更大
            sectionElListing.HorizontalAlignment = Enum.HorizontalAlignment.Center

            coroutine.wrap(function()
                while wait() do
                    sectionFrame.BackgroundColor3 = themeList.Background
                    sectionHead.BackgroundColor3 = themeList.SchemeColor
                    sectionName.TextColor3 = themeList.TextColor
                end
            end)()

            local function updateSectionFrame()
                local innerSc = sectionElListing.AbsoluteContentSize
                sectionInners.Size = UDim2.new(1, -20, 0, innerSc.Y + 10)
                local frameSc = sectionlistoknvm.AbsoluteContentSize
                sectionFrame.Size = UDim2.new(1, -10, 0, frameSc.Y + 5)
            end
            
            updateSectionFrame()
            UpdateSize()
            
            local Elements = {}
            
            -- 🔘 按钮
            function Elements:新建按钮(bname, tip, callback)
                bname = bname or "按钮"
                tip = tip or "点击执行操作"
                callback = callback or function() end

                local buttonElement = Instance.new("TextButton")
                local UICorner = Instance.new("UICorner")
                local btnInfo = Instance.new("TextLabel")
                local touchIcon = Instance.new("ImageLabel")

                buttonElement.Name = bname
                buttonElement.Parent = sectionInners
                buttonElement.BackgroundColor3 = themeList.ElementColor
                buttonElement.ClipsDescendants = true
                buttonElement.Size = UDim2.new(1, -20, 0, 45)  -- 手机端更高
                buttonElement.AutoButtonColor = false
                buttonElement.Font = Enum.Font.SourceSans
                buttonElement.Text = ""

                UICorner.CornerRadius = UDim.new(0, 8)
                UICorner.Parent = buttonElement

                touchIcon.Name = "touchIcon"
                touchIcon.Parent = buttonElement
                touchIcon.BackgroundTransparency = 1
                touchIcon.Position = UDim2.new(0.02, 0, 0.5, -12)
                touchIcon.Size = UDim2.new(0, 24, 0, 24)
                touchIcon.Image = "rbxassetid://3926305904"
                touchIcon.ImageColor3 = themeList.SchemeColor
                touchIcon.ImageRectOffset = Vector2.new(84, 204)
                touchIcon.ImageRectSize = Vector2.new(36, 36)

                btnInfo.Name = "btnInfo"
                btnInfo.Parent = buttonElement
                btnInfo.BackgroundTransparency = 1
                btnInfo.Position = UDim2.new(0.12, 0, 0, 0)
                btnInfo.Size = UDim2.new(0.85, 0, 1, 0)
                btnInfo.Font = Enum.Font.GothamSemibold
                btnInfo.Text = bname
                btnInfo.RichText = true
                btnInfo.TextColor3 = themeList.TextColor
                btnInfo.TextSize = 15
                btnInfo.TextXAlignment = Enum.TextXAlignment.Left
                btnInfo.TextYAlignment = Enum.TextYAlignment.Center

                updateSectionFrame()
                UpdateSize()

                local ms = game.Players.LocalPlayer:GetMouse()
                local btn = buttonElement

                -- 点击动画
                local function animateClick()
                    local oldColor = btn.BackgroundColor3
                    btn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                    task.wait(0.05)
                    btn.BackgroundColor3 = oldColor
                end

                btn.MouseButton1Click:Connect(function()
                    if not focusing then
                        animateClick()
                        callback()
                    end
                end)
                
                btn.TouchTap:Connect(function()
                    if not focusing then
                        animateClick()
                        callback()
                    end
                end)

                local hovering = false
                btn.MouseEnter:Connect(function()
                    if not focusing then
                        btn.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 20, themeList.ElementColor.g * 255 + 20, themeList.ElementColor.b * 255 + 20)
                        hovering = true
                    end
                end)
                
                btn.MouseLeave:Connect(function()
                    if not focusing then 
                        btn.BackgroundColor3 = themeList.ElementColor
                        hovering = false
                    end
                end)

                coroutine.wrap(function()
                    while wait() do
                        if not hovering then
                            buttonElement.BackgroundColor3 = themeList.ElementColor
                        end
                        touchIcon.ImageColor3 = themeList.SchemeColor
                        btnInfo.TextColor3 = themeList.TextColor
                    end
                end)()

                return buttonElement
            end

            -- 🔘 开关
            function Elements:新建开关(tname, tip, callback)
                tname = tname or "开关"
                tip = tip or "开启或关闭功能"
                callback = callback or function() end
                local toggled = false

                local toggleElement = Instance.new("TextButton")
                local UICorner = Instance.new("UICorner")
                local toggleDisabled = Instance.new("ImageLabel")
                local toggleEnabled = Instance.new("ImageLabel")
                local togName = Instance.new("TextLabel")
                local touchIcon = Instance.new("ImageLabel")

                toggleElement.Name = "toggleElement"
                toggleElement.Parent = sectionInners
                toggleElement.BackgroundColor3 = themeList.ElementColor
                toggleElement.ClipsDescendants = true
                toggleElement.Size = UDim2.new(1, -20, 0, 45)
                toggleElement.AutoButtonColor = false
                toggleElement.Text = ""

                UICorner.CornerRadius = UDim.new(0, 8)
                UICorner.Parent = toggleElement

                toggleDisabled.Name = "toggleDisabled"
                toggleDisabled.Parent = toggleElement
                toggleDisabled.BackgroundTransparency = 1
                toggleDisabled.Position = UDim2.new(0.02, 0, 0.5, -12)
                toggleDisabled.Size = UDim2.new(0, 24, 0, 24)
                toggleDisabled.Image = "rbxassetid://3926309567"
                toggleDisabled.ImageColor3 = themeList.SchemeColor
                toggleDisabled.ImageRectOffset = Vector2.new(628, 420)
                toggleDisabled.ImageRectSize = Vector2.new(48, 48)

                toggleEnabled.Name = "toggleEnabled"
                toggleEnabled.Parent = toggleElement
                toggleEnabled.BackgroundTransparency = 1
                toggleEnabled.Position = UDim2.new(0.02, 0, 0.5, -12)
                toggleEnabled.Size = UDim2.new(0, 24, 0, 24)
                toggleEnabled.Image = "rbxassetid://3926309567"
                toggleEnabled.ImageColor3 = themeList.SchemeColor
                toggleEnabled.ImageRectOffset = Vector2.new(784, 420)
                toggleEnabled.ImageRectSize = Vector2.new(48, 48)
                toggleEnabled.ImageTransparency = 1

                togName.Name = "togName"
                togName.Parent = toggleElement
                togName.BackgroundTransparency = 1
                togName.Position = UDim2.new(0.12, 0, 0, 0)
                togName.Size = UDim2.new(0.7, 0, 1, 0)
                togName.Font = Enum.Font.GothamSemibold
                togName.Text = tname
                togName.RichText = true
                togName.TextColor3 = themeList.TextColor
                togName.TextSize = 15
                togName.TextXAlignment = Enum.TextXAlignment.Left
                togName.TextYAlignment = Enum.TextYAlignment.Center

                local btn = toggleElement
                local img = toggleEnabled

                updateSectionFrame()
                UpdateSize()

                local function updateToggle()
                    if toggled then
                        img.ImageTransparency = 0
                    else
                        img.ImageTransparency = 1
                    end
                    pcall(callback, toggled)
                end

                btn.MouseButton1Click:Connect(function()
                    if not focusing then
                        toggled = not toggled
                        updateToggle()
                    end
                end)
                
                btn.TouchTap:Connect(function()
                    if not focusing then
                        toggled = not toggled
                        updateToggle()
                    end
                end)

                local hovering = false
                btn.MouseEnter:Connect(function()
                    if not focusing then
                        btn.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 20, themeList.ElementColor.g * 255 + 20, themeList.ElementColor.b * 255 + 20)
                        hovering = true
                    end 
                end)

                btn.MouseLeave:Connect(function()
                    if not focusing then
                        btn.BackgroundColor3 = themeList.ElementColor
                        hovering = false
                    end
                end)

                coroutine.wrap(function()
                    while wait() do
                        if not hovering then
                            toggleElement.BackgroundColor3 = themeList.ElementColor
                        end
                        toggleDisabled.ImageColor3 = themeList.SchemeColor
                        toggleEnabled.ImageColor3 = themeList.SchemeColor
                        togName.TextColor3 = themeList.TextColor
                    end
                end)()

                updateToggle()
                
                return {
                    设置状态 = function(self, state)
                        toggled = state
                        updateToggle()
                    end,
                    获取状态 = function() return toggled end
                }
            end

            -- 📊 滑块
            function Elements:新建滑块(slidInf, tip, maxvalue, minvalue, callback)
                slidInf = slidInf or "滑块"
                tip = tip or "拖动调节数值"
                maxvalue = maxvalue or 100
                minvalue = minvalue or 0
                callback = callback or function() end

                local sliderElement = Instance.new("TextButton")
                local UICorner = Instance.new("UICorner")
                local togName = Instance.new("TextLabel")
                local sliderBtn = Instance.new("TextButton")
                local sliderDrag = Instance.new("Frame")
                local UICorner_2 = Instance.new("UICorner")
                local val = Instance.new("TextLabel")

                sliderElement.Name = "sliderElement"
                sliderElement.Parent = sectionInners
                sliderElement.BackgroundColor3 = themeList.ElementColor
                sliderElement.ClipsDescendants = true
                sliderElement.Size = UDim2.new(1, -20, 0, 60)  -- 手机端更高
                sliderElement.AutoButtonColor = false
                sliderElement.Text = ""

                UICorner.CornerRadius = UDim.new(0, 8)
                UICorner.Parent = sliderElement

                togName.Name = "togName"
                togName.Parent = sliderElement
                togName.BackgroundTransparency = 1
                togName.Position = UDim2.new(0.02, 0, 0.15, 0)
                togName.Size = UDim2.new(0.8, 0, 0, 25)
                togName.Font = Enum.Font.GothamSemibold
                togName.Text = slidInf
                togName.RichText = true
                togName.TextColor3 = themeList.TextColor
                togName.TextSize = 15
                togName.TextXAlignment = Enum.TextXAlignment.Left

                sliderBtn.Name = "sliderBtn"
                sliderBtn.Parent = sliderElement
                sliderBtn.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 10, themeList.ElementColor.g * 255 + 10, themeList.ElementColor.b * 255 + 10)
                sliderBtn.BorderSizePixel = 0
                sliderBtn.Position = UDim2.new(0.02, 0, 0.6, 0)
                sliderBtn.Size = UDim2.new(0.7, 0, 0, 8)
                sliderBtn.AutoButtonColor = false
                sliderBtn.Text = ""

                UICorner_2.CornerRadius = UDim.new(0, 4)
                UICorner_2.Parent = sliderBtn

                sliderDrag.Name = "sliderDrag"
                sliderDrag.Parent = sliderBtn
                sliderDrag.BackgroundColor3 = themeList.SchemeColor
                sliderDrag.BorderSizePixel = 0
                sliderDrag.Size = UDim2.new(0.5, 0, 1, 0)

                val.Name = "val"
                val.Parent = sliderElement
                val.BackgroundTransparency = 1
                val.Position = UDim2.new(0.75, 0, 0.15, 0)
                val.Size = UDim2.new(0.23, 0, 0, 25)
                val.Font = Enum.Font.GothamSemibold
                val.Text = tostring(minvalue)
                val.TextColor3 = themeList.TextColor
                val.TextSize = 15
                val.TextXAlignment = Enum.TextXAlignment.Right

                updateSectionFrame()
                UpdateSize()

                local mouse = game:GetService("Players").LocalPlayer:GetMouse()
                local uis = game:GetService("UserInputService")
                local btn = sliderElement
                local currentValue = minvalue
                local dragging = false

                local function updateValue(rawValue)
                    local percent = math.clamp(rawValue, 0, 1)
                    local newValue = minvalue + (maxvalue - minvalue) * percent
                    if maxvalue - minvalue <= 100 then
                        newValue = math.floor(newValue)
                    else
                        newValue = math.floor(newValue * 10) / 10
                    end
                    currentValue = newValue
                    val.Text = tostring(currentValue)
                    sliderDrag.Size = UDim2.new(percent, 0, 1, 0)
                    pcall(callback, currentValue)
                end

                -- 鼠标拖动
                sliderBtn.InputBegan:Connect(function(io)
                    if io.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local percent = math.clamp((mouse.X - sliderBtn.AbsolutePosition.X) / sliderBtn.AbsoluteSize.X, 0, 1)
                        updateValue(percent)
                    end
                end)
                
                sliderBtn.InputEnded:Connect(function(io)
                    if io.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                -- 触摸拖动（手机）
                sliderBtn.TouchTap:Connect(function() end)
                sliderBtn.TouchLongPress:Connect(function() end)
                
                sliderBtn.InputBegan:Connect(function(io)
                    if io.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        local touchPos = io.Position
                        local percent = math.clamp((touchPos.X - sliderBtn.AbsolutePosition.X) / sliderBtn.AbsoluteSize.X, 0, 1)
                        updateValue(percent)
                    end
                end)
                
                sliderBtn.InputEnded:Connect(function(io)
                    if io.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                uis.InputChanged:Connect(function(io)
                    if dragging then
                        if io.UserInputType == Enum.UserInputType.MouseMovement then
                            local percent = math.clamp((mouse.X - sliderBtn.AbsolutePosition.X) / sliderBtn.AbsoluteSize.X, 0, 1)
                            updateValue(percent)
                        elseif io.UserInputType == Enum.UserInputType.Touch then
                            local percent = math.clamp((io.Position.X - sliderBtn.AbsolutePosition.X) / sliderBtn.AbsoluteSize.X, 0, 1)
                            updateValue(percent)
                        end
                    end
                end)

                coroutine.wrap(function()
                    while wait() do
                        sliderElement.BackgroundColor3 = themeList.ElementColor
                        val.TextColor3 = themeList.TextColor
                        togName.TextColor3 = themeList.TextColor
                        sliderBtn.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 10, themeList.ElementColor.g * 255 + 10, themeList.ElementColor.b * 255 + 10)
                        sliderDrag.BackgroundColor3 = themeList.SchemeColor
                    end
                end)()

                updateValue((minvalue) / (maxvalue - minvalue))
                
                return {
                    设置数值 = function(self, value)
                        local percent = math.clamp((value - minvalue) / (maxvalue - minvalue), 0, 1)
                        updateValue(percent)
                    end,
                    获取数值 = function() return currentValue end
                }
            end

            -- 📝 文本框
            function Elements:新建文本框(tname, tip, callback)
                tname = tname or "文本框"
                tip = tip or "输入文字"
                callback = callback or function() end

                local textboxElement = Instance.new("TextButton")
                local UICorner = Instance.new("UICorner")
                local write = Instance.new("ImageLabel")
                local TextBox = Instance.new("TextBox")
                local togName = Instance.new("TextLabel")

                textboxElement.Name = "textboxElement"
                textboxElement.Parent = sectionInners
                textboxElement.BackgroundColor3 = themeList.ElementColor
                textboxElement.ClipsDescendants = true
                textboxElement.Size = UDim2.new(1, -20, 0, 45)
                textboxElement.AutoButtonColor = false
                textboxElement.Text = ""

                UICorner.CornerRadius = UDim.new(0, 8)
                UICorner.Parent = textboxElement

                write.Name = "write"
                write.Parent = textboxElement
                write.BackgroundTransparency = 1
                write.Position = UDim2.new(0.02, 0, 0.5, -12)
                write.Size = UDim2.new(0, 24, 0, 24)
                write.Image = "rbxassetid://3926305904"
                write.ImageColor3 = themeList.SchemeColor
                write.ImageRectOffset = Vector2.new(324, 604)
                write.ImageRectSize = Vector2.new(36, 36)

                TextBox.Parent = textboxElement
                TextBox.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 - 10, themeList.ElementColor.g * 255 - 10, themeList.ElementColor.b * 255 - 10)
                TextBox.BorderSizePixel = 0
                TextBox.Position = UDim2.new(0.45, 0, 0.5, -14)
                TextBox.Size = UDim2.new(0.5, -10, 0, 28)
                TextBox.ClearTextOnFocus = true
                TextBox.Font = Enum.Font.Gotham
                TextBox.PlaceholderText = "输入..."
                TextBox.Text = ""
                TextBox.TextColor3 = themeList.TextColor
                TextBox.TextSize = 14

                local textCorner = Instance.new("UICorner")
                textCorner.CornerRadius = UDim.new(0, 6)
                textCorner.Parent = TextBox

                togName.Name = "togName"
                togName.Parent = textboxElement
                togName.BackgroundTransparency = 1
                togName.Position = UDim2.new(0.12, 0, 0, 0)
                togName.Size = UDim2.new(0.3, 0, 1, 0)
                togName.Font = Enum.Font.GothamSemibold
                togName.Text = tname
                togName.RichText = true
                togName.TextColor3 = themeList.TextColor
                togName.TextSize = 14
                togName.TextXAlignment = Enum.TextXAlignment.Left
                togName.TextYAlignment = Enum.TextYAlignment.Center

                updateSectionFrame()
                UpdateSize()

                TextBox.FocusLost:Connect(function(enterPressed)
                    if enterPressed and TextBox.Text ~= "" then
                        callback(TextBox.Text)
                        TextBox.Text = ""
                    end
                end)

                coroutine.wrap(function()
                    while wait() do
                        textboxElement.BackgroundColor3 = themeList.ElementColor
                        TextBox.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 - 10, themeList.ElementColor.g * 255 - 10, themeList.ElementColor.b * 255 - 10)
                        write.ImageColor3 = themeList.SchemeColor
                        togName.TextColor3 = themeList.TextColor
                        TextBox.TextColor3 = themeList.TextColor
                        TextBox.PlaceholderColor3 = themeList.TextDim or Color3.fromRGB(150,150,150)
                    end
                end)()
            end

            -- 📋 下拉框
            function Elements:新建下拉框(dropname, tip, list, callback)
                dropname = dropname or "下拉框"
                list = list or {}
                tip = tip or "选择一个选项"
                callback = callback or function() end

                local opened = false
                local dropFrame = Instance.new("Frame")
                local dropOpen = Instance.new("TextButton")
                local listImg = Instance.new("ImageLabel")
                local itemTextbox = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local UIListLayout = Instance.new("UIListLayout")
                local selectedItem = nil

                dropFrame.Name = "dropFrame"
                dropFrame.Parent = sectionInners
                dropFrame.BackgroundColor3 = themeList.Background
                dropFrame.BorderSizePixel = 0
                dropFrame.Size = UDim2.new(1, -20, 0, 45)
                dropFrame.ClipsDescendants = true

                dropOpen.Name = "dropOpen"
                dropOpen.Parent = dropFrame
                dropOpen.BackgroundColor3 = themeList.ElementColor
                dropOpen.Size = UDim2.new(1, 0, 0, 45)
                dropOpen.AutoButtonColor = false
                dropOpen.Text = ""

                listImg.Name = "listImg"
                listImg.Parent = dropOpen
                listImg.BackgroundTransparency = 1
                listImg.Position = UDim2.new(0.02, 0, 0.5, -12)
                listImg.Size = UDim2.new(0, 24, 0, 24)
                listImg.Image = "rbxassetid://3926305904"
                listImg.ImageColor3 = themeList.SchemeColor
                listImg.ImageRectOffset = Vector2.new(644, 364)
                listImg.ImageRectSize = Vector2.new(36, 36)

                itemTextbox.Name = "itemTextbox"
                itemTextbox.Parent = dropOpen
                itemTextbox.BackgroundTransparency = 1
                itemTextbox.Position = UDim2.new(0.12, 0, 0, 0)
                itemTextbox.Size = UDim2.new(0.8, 0, 1, 0)
                itemTextbox.Font = Enum.Font.GothamSemibold
                itemTextbox.Text = dropname
                itemTextbox.RichText = true
                itemTextbox.TextColor3 = themeList.TextColor
                itemTextbox.TextSize = 14
                itemTextbox.TextXAlignment = Enum.TextXAlignment.Left
                itemTextbox.TextYAlignment = Enum.TextYAlignment.Center

                UICorner.CornerRadius = UDim.new(0, 8)
                UICorner.Parent = dropOpen

                UIListLayout.Parent = dropFrame
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Padding = UDim.new(0, 5)

                updateSectionFrame()
                UpdateSize()

                local function toggleDropdown()
                    if opened then
                        opened = false
                        dropFrame:TweenSize(UDim2.new(1, -20, 0, 45), "Out", "Quad", 0.15)
                    else
                        opened = true
                        local totalHeight = 45 + math.min(#list, 5) * 45
                        dropFrame:TweenSize(UDim2.new(1, -20, 0, totalHeight), "Out", "Quad", 0.15)
                    end
                end

                dropOpen.MouseButton1Click:Connect(toggleDropdown)
                dropOpen.TouchTap:Connect(toggleDropdown)

                -- 创建选项
                local function refreshOptions()
                    -- 清除旧选项
                    for _, child in ipairs(dropFrame:GetChildren()) do
                        if child:IsA("TextButton") and child ~= dropOpen then
                            child:Destroy()
                        end
                    end
                    
                    for i, option in ipairs(list) do
                        local optionSelect = Instance.new("TextButton")
                        local optCorner = Instance.new("UICorner")
                        
                        optionSelect.Name = "optionSelect"
                        optionSelect.Parent = dropFrame
                        optionSelect.BackgroundColor3 = themeList.ElementColor
                        optionSelect.Position = UDim2.new(0, 0, 0, 45)
                        optionSelect.Size = UDim2.new(1, 0, 0, 45)
                        optionSelect.AutoButtonColor = false
                        optionSelect.Font = Enum.Font.GothamSemibold
                        optionSelect.Text = "  " .. option
                        optionSelect.TextColor3 = themeList.TextColor
                        optionSelect.TextSize = 14
                        optionSelect.TextXAlignment = Enum.TextXAlignment.Left
                        optionSelect.ClipsDescendants = true
                        optionSelect.LayoutOrder = i
                        
                        optCorner.CornerRadius = UDim.new(0, 8)
                        optCorner.Parent = optionSelect
                        
                        optionSelect.MouseButton1Click:Connect(function()
                            selectedItem = option
                            itemTextbox.Text = option
                            callback(option)
                            toggleDropdown()
                        end)
                        
                        optionSelect.TouchTap:Connect(function()
                            selectedItem = option
                            itemTextbox.Text = option
                            callback(option)
                            toggleDropdown()
                        end)
                        
                        local hover = false
                        optionSelect.MouseEnter:Connect(function()
                            optionSelect.BackgroundColor3 = Color3.fromRGB(themeList.ElementColor.r * 255 + 20, themeList.ElementColor.g * 255 + 20, themeList.ElementColor.b * 255 + 20)
                        end)
                        optionSelect.MouseLeave:Connect(function()
                            optionSelect.BackgroundColor3 = themeList.ElementColor
                        end)
                    end
                end

                refreshOptions()

                coroutine.wrap(function()
                    while wait() do
                        dropOpen.BackgroundColor3 = themeList.ElementColor
                        dropFrame.BackgroundColor3 = themeList.Background
                        listImg.ImageColor3 = themeList.SchemeColor
                        itemTextbox.TextColor3 = themeList.TextColor
                    end
                end)()

                return {
                    刷新 = function(self, newList)
                        list = newList
                        refreshOptions()
                    end,
                    选中 = function(self, option)
                        selectedItem = option
                        itemTextbox.Text = option
                        callback(option)
                    end
                }
            end

            -- 🏷️ 标签
            function Elements:新建标签(title)
                local label = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                
                label.Name = "label"
                label.Parent = sectionInners
                label.BackgroundColor3 = themeList.SchemeColor
                label.BorderSizePixel = 0
                label.ClipsDescendants = true
                label.Size = UDim2.new(1, -20, 0, 50)
                label.Font = Enum.Font.Gotham
                label.Text = title
                label.RichText = true
                label.TextColor3 = themeList.TextColor
                label.TextSize = 14
                label.TextXAlignment = Enum.TextXAlignment.Center
                label.TextYAlignment = Enum.TextYAlignment.Center
                
                UICorner.CornerRadius = UDim.new(0, 8)
                UICorner.Parent = label

                coroutine.wrap(function()
                    while wait() do
                        label.BackgroundColor3 = themeList.SchemeColor
                        label.TextColor3 = themeList.TextColor
                    end
                end)()
                
                updateSectionFrame()
                UpdateSize()
                
                return {
                    更新文本 = function(self, newText)
                        label.Text = newText
                    end
                }
            end

            return Elements
        end
        return Sections
    end  
    return Tabs
end

return Kavo