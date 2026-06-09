-- by 小迪
local AYXDiscordUILibrary = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")

-- 配置
local Config = {
    Theme = "Dark",
    AccentColor = Color3.fromRGB(114, 137, 228),
    BackgroundColor = Color3.fromRGB(32, 34, 37),
    TextColor = Color3.fromRGB(255, 255, 255),
    SecondaryColor = Color3.fromRGB(47, 49, 54),
    AnimationSpeed = 0.2,
    EnableSounds = true,
    EnableAnimations = true,
    EnableGlow = true,
    EnableBlur = false,
    SaveSettings = true,
    AutoSave = true,
    Notifications = true,
    EnableRainbowMode = false,
    EnableSmoothScrolling = true,
    SoundErrorCount = 0,
    MaxSoundErrors = 5,
    UIScale = 0.85,
    MinScale = 0.5,
    MaxScale = 1.3
}

-- 悬停颜色
local HoverColors = {
    ButtonHover = Color3.fromRGB(103, 123, 196),
    ButtonNormal = Color3.fromRGB(114, 137, 228),
    ServerHover = Color3.fromRGB(114, 137, 228),
    ServerNormal = Color3.fromRGB(47, 49, 54),
    ChannelHover = Color3.fromRGB(52, 55, 60),
    ChannelNormal = Color3.fromRGB(47, 49, 54)
}

local currentScale = Config.UIScale
local scaleStep = 0.05

local function UpdateHoverColors()
    local accentColor = Config.AccentColor
    local darkerAccent = Color3.fromRGB(
        math.floor(accentColor.R * 0.9 * 255),
        math.floor(accentColor.G * 0.9 * 255),
        math.floor(accentColor.B * 0.9 * 255)
    )
    HoverColors.ButtonHover = darkerAccent
    HoverColors.ButtonNormal = accentColor
    HoverColors.ServerHover = accentColor
    HoverColors.ServerNormal = Config.SecondaryColor
    HoverColors.ChannelHover = Color3.fromRGB(
        math.floor(Config.SecondaryColor.R * 1.1 * 255),
        math.floor(Config.SecondaryColor.G * 1.1 * 255),
        math.floor(Config.SecondaryColor.B * 1.1 * 255)
    )
    HoverColors.ChannelNormal = Config.SecondaryColor
end

local function PlaySound(soundName)
    if Config.EnableSounds then
        pcall(function()
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://604236371"
            sound.Volume = 0.3
            sound.Parent = SoundService
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 1)
        end)
    end
end

local function CreateGlow(parent, color)
    if Config.EnableGlow then
        local existing = parent:FindFirstChild("Glow")
        if existing then existing:Destroy() end
        local glow = Instance.new("ImageLabel")
        glow.Name = "Glow"
        glow.BackgroundTransparency = 1
        glow.Position = UDim2.new(-0.1, 0, -0.1, 0)
        glow.Size = UDim2.new(1.2, 0, 1.2, 0)
        glow.ZIndex = parent.ZIndex - 1
        glow.Image = "rbxassetid://4996891970"
        glow.ImageColor3 = color or Config.AccentColor
        glow.ScaleType = Enum.ScaleType.Slice
        glow.SliceCenter = Rect.new(20, 20, 280, 280)
        glow.Parent = parent
        return glow
    end
end

local function SetBlur(enabled)
    local lighting = game:GetService("Lighting")
    for _, v in ipairs(lighting:GetChildren()) do
        if v:IsA("BlurEffect") and v.Name == "AYXDiscordUIBlur" then
            v:Destroy()
        end
    end
    if enabled then
        local blur = Instance.new("BlurEffect")
        blur.Name = "AYXDiscordUIBlur"
        blur.Size = 10
        blur.Parent = lighting
    end
end

function AYXDiscordUILibrary:ToggleBlur(enabled)
    Config.EnableBlur = enabled
    SetBlur(enabled)
end

-- 手机端友好的滑块（保留但未直接使用，下面有完整实现）
local function CreateMobileFriendlySlider(sliderFrame, currentValueFrame, zip, valueLabel, min, max, start, callback)
    local dragging = false
    local sliderFunc = {}
    local touchId = nil
    
    local function updateValue(inputPos)
        local relativeX = math.clamp((inputPos.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        local value = math.floor(relativeX * (max - min) + min)
        currentValueFrame.Size = UDim2.new(relativeX, 0, 0, 8)
        zip.Position = UDim2.new(relativeX, -6, -0.644999981, 0)
        valueLabel.Text = tostring(value)
        pcall(callback, value)
    end
    
    local function onInputBegan(input, isTouch)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            if isTouch then touchId = input end
            valueLabel.Parent.Visible = true
            updateValue(input.Position)
        end
    end
    
    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            touchId = nil
            valueLabel.Parent.Visible = false
        end
    end
    
    local function onInputChanged(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or 
               (input.UserInputType == Enum.UserInputType.Touch and input == touchId) then
                updateValue(input.Position)
            end
        end
    end
    
    zip.InputBegan:Connect(onInputBegan)
    zip.InputEnded:Connect(onInputEnded)
    sliderFrame.InputBegan:Connect(onInputBegan)
    
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)
    
    function sliderFunc:Change(tochange)
        local relativeX = math.clamp((tochange - min) / (max - min), 0, 1)
        currentValueFrame.Size = UDim2.new(relativeX, 0, 0, 8)
        zip.Position = UDim2.new(relativeX, -6, -0.644999981, 0)
        valueLabel.Text = tostring(tochange)
        pcall(callback, tochange)
    end
    
    return sliderFunc
end

-- 手机端友好的颜色选择器（保留但未直接使用）
local function CreateMobileFriendlyColorPicker(colorFrame, hueFrame, colorSelection, hueSelection, presetColorFrame, callback)
    local ColorH, ColorS, ColorV = 1, 1, 1
    local ColorInput = nil
    local HueInput = nil
    local touchingColor = false
    local touchingHue = false
    
    local function updateColor()
        local color = Color3.fromHSV(ColorH, ColorS, ColorV)
        presetColorFrame.BackgroundColor3 = color
        colorFrame.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
        pcall(callback, color)
    end
    
    local function onColorInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            touchingColor = true
            if ColorInput then ColorInput:Disconnect() end
            ColorInput = RunService.RenderStepped:Connect(function()
                local colorX = math.clamp((input.UserInputType == Enum.UserInputType.Touch and input.Position.X or Mouse.X) - colorFrame.AbsolutePosition.X, 0, colorFrame.AbsoluteSize.X) / colorFrame.AbsoluteSize.X
                local colorY = math.clamp((input.UserInputType == Enum.UserInputType.Touch and input.Position.Y or Mouse.Y) - colorFrame.AbsolutePosition.Y, 0, colorFrame.AbsoluteSize.Y) / colorFrame.AbsoluteSize.Y
                colorX = math.clamp(colorX, 0, 1)
                colorY = math.clamp(colorY, 0, 1)
                colorSelection.Position = UDim2.new(colorX, 0, colorY, 0)
                ColorS = colorX
                ColorV = 1 - colorY
                updateColor()
            end)
        end
    end
    
    local function onColorEnd(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            touchingColor = false
            if ColorInput then ColorInput:Disconnect() end
        end
    end
    
    local function onHueInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            touchingHue = true
            if HueInput then HueInput:Disconnect() end
            HueInput = RunService.RenderStepped:Connect(function()
                local hueY = math.clamp((input.UserInputType == Enum.UserInputType.Touch and input.Position.Y or Mouse.Y) - hueFrame.AbsolutePosition.Y, 0, hueFrame.AbsoluteSize.Y) / hueFrame.AbsoluteSize.Y
                hueY = math.clamp(hueY, 0, 1)
                hueSelection.Position = UDim2.new(0.48, 0, hueY, 0)
                ColorH = 1 - hueY
                updateColor()
            end)
        end
    end
    
    local function onHueEnd(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            touchingHue = false
            if HueInput then HueInput:Disconnect() end
        end
    end
    
    colorFrame.InputBegan:Connect(onColorInput)
    colorFrame.InputEnded:Connect(onColorEnd)
    hueFrame.InputBegan:Connect(onHueInput)
    hueFrame.InputEnded:Connect(onHueEnd)
end

-- 用户信息
local pfp, user, tag, userinfo = {}, "", "", {}
pcall(function() userinfo = HttpService:JSONDecode(readfile("discordlibinfo.txt")) end)

local function GetSafeProfilePicture()
    local success, result = pcall(function()
        return "https://www.roblox.com/headshot-thumbnail/image?userId=".. game.Players.LocalPlayer.UserId .."&width=420&height=420&format=png"
    end)
    return success and result or "rbxassetid://0"
end

local function GetSafeUserInfo()
    local success, result = pcall(function() return game.Players.LocalPlayer.Name end)
    return success and result or "User"
end

pfp = userinfo["pfp"] or GetSafeProfilePicture()
user = userinfo["user"] or GetSafeUserInfo()
tag = userinfo["tag"] or tostring(math.random(1000,9999))

local function SaveInfo()
    userinfo["pfp"] = pfp; userinfo["user"] = user; userinfo["tag"] = tag
    writefile("discordlibinfo.txt", HttpService:JSONEncode(userinfo))
end

-- 拖动功能，支持手机触摸
local function MakeDraggable(topbarobject, object)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local currentTouch = nil

    local function update(inputPos)
        local delta = inputPos - dragStart
        object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position
            if input.UserInputType == Enum.UserInputType.Touch then currentTouch = input end
        end
    end)

    topbarobject.InputEnded:Connect(function(input)
        if input == currentTouch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            currentTouch = nil
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input == currentTouch then
                update(input.Position)
            end
        end
    end)
end

-- 安全初始化
local Discord = (function()
    local success, result = pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "Discord"
        gui.Parent = game.CoreGui
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        return gui
    end)
    return success and result or Instance.new("ScreenGui")
end)()

local uiScaleObj = Instance.new("UIScale")
uiScaleObj.Name = "UIScale"
uiScaleObj.Scale = Config.UIScale
uiScaleObj.Parent = Discord

-- 缩放功能
local function setUIScale(scale)
    currentScale = math.clamp(scale, Config.MinScale, Config.MaxScale)
    Config.UIScale = currentScale
    uiScaleObj.Scale = currentScale
    return currentScale
end

function AYXDiscordUILibrary:ZoomIn() return setUIScale(currentScale + scaleStep) end
function AYXDiscordUILibrary:ZoomOut() return setUIScale(currentScale - scaleStep) end
function AYXDiscordUILibrary:SetUIScale(scale) return setUIScale(scale) end

function AYXDiscordUILibrary:Window(text)
    local currentservertoggled = ""
    local minimized = false
    local fs = false
    local settingsopened = false
    
    -- 统一尺寸变量
    local windowWidth = 720
    local windowHeight = 420
    local sidebarWidth = 75
    local topBarHeight = 28
    local userpadHeight = 48
    
    local scaledW = math.floor(windowWidth * Config.UIScale)
    local scaledH = math.floor(windowHeight * Config.UIScale)
    local scaledSidebar = math.floor(sidebarWidth * Config.UIScale)
    local scaledTopBar = math.floor(topBarHeight * Config.UIScale)
    
    local MainFrame = Instance.new("Frame")
    local TopFrame = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local CloseBtn = Instance.new("TextButton")
    local CloseIcon = Instance.new("ImageLabel")
    local MinimizeBtn = Instance.new("TextButton")
    local MinimizeIcon = Instance.new("ImageLabel")
    local ServersHolder = Instance.new("Folder")
    local Userpad = Instance.new("Frame")
    local UserIcon = Instance.new("Frame")
    local UserIconCorner = Instance.new("UICorner")
    local UserImage = Instance.new("ImageLabel")
    local UserCircleImage = Instance.new("ImageLabel")
    local UserName = Instance.new("TextLabel")
    local UserTag = Instance.new("TextLabel")
    local ServersHoldFrame = Instance.new("Frame")
    local ServersHold = Instance.new("ScrollingFrame")
    local ServersHoldLayout = Instance.new("UIListLayout")
    local ServersHoldPadding = Instance.new("UIPadding")
    local TopFrameHolder = Instance.new("Frame")

    MainFrame.Name = "MainFrame"
    MainFrame.Parent = Discord
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Config.BackgroundColor
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(0, scaledW, 0, scaledH)

    TopFrame.Name = "TopFrame"
    TopFrame.Parent = MainFrame
    TopFrame.BackgroundColor3 = Config.BackgroundColor
    TopFrame.BackgroundTransparency = 1
    TopFrame.Size = UDim2.new(0, scaledW, 0, scaledTopBar)
    
    TopFrameHolder.Name = "TopFrameHolder"
    TopFrameHolder.Parent = TopFrame
    TopFrameHolder.BackgroundColor3 = Config.BackgroundColor
    TopFrameHolder.BackgroundTransparency = 1
    TopFrameHolder.Size = UDim2.new(0, scaledW, 0, scaledTopBar)

    Title.Name = "Title"
    Title.Parent = TopFrame
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0.01, 0, 0, 0)
    Title.Size = UDim2.new(0, math.floor(200 * Config.UIScale), 0, scaledTopBar)
    Title.Font = Enum.Font.Gotham
    Title.Text = text
    Title.TextColor3 = Color3.fromRGB(220, 220, 220)
    Title.TextSize = math.floor(14 * Config.UIScale)
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- 按钮尺寸
    local btnSize = math.floor(32 * Config.UIScale)
    local btnIconSize = math.floor(18 * Config.UIScale)
    
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Parent = TopFrame
    CloseBtn.BackgroundColor3 = Config.BackgroundColor
    CloseBtn.BackgroundTransparency = 0
    CloseBtn.Position = UDim2.new(1, -btnSize - 5, 0, 0)
    CloseBtn.Size = UDim2.new(0, btnSize, 0, scaledTopBar)
    CloseBtn.Text = ""
    CloseBtn.BorderSizePixel = 0
    CloseBtn.AutoButtonColor = false

    CloseIcon.Name = "CloseIcon"
    CloseIcon.Parent = CloseBtn
    CloseIcon.BackgroundTransparency = 1
    CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    CloseIcon.Size = UDim2.new(0, btnIconSize, 0, btnIconSize)
    CloseIcon.Image = "http://www.roblox.com/asset/?id=6035047409"
    CloseIcon.ImageColor3 = Color3.fromRGB(220, 221, 222)

    MinimizeBtn.Name = "MinimizeButton"
    MinimizeBtn.Parent = TopFrame
    MinimizeBtn.BackgroundColor3 = Config.BackgroundColor
    MinimizeBtn.BackgroundTransparency = 0
    MinimizeBtn.Position = UDim2.new(1, -btnSize * 2 - 8, 0, 0)
    MinimizeBtn.Size = UDim2.new(0, btnSize, 0, scaledTopBar)
    MinimizeBtn.Text = ""
    MinimizeBtn.BorderSizePixel = 0
    MinimizeBtn.AutoButtonColor = false

    MinimizeIcon.Name = "MinimizeLabel"
    MinimizeIcon.Parent = MinimizeBtn
    MinimizeIcon.BackgroundTransparency = 1
    MinimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    MinimizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    MinimizeIcon.Size = UDim2.new(0, btnIconSize, 0, btnIconSize)
    MinimizeIcon.Image = "http://www.roblox.com/asset/?id=6035067836"
    MinimizeIcon.ImageColor3 = Color3.fromRGB(220, 221, 222)

    -- 缩放按钮组
    local ZoomOutBtn = Instance.new("TextButton")
    local ZoomOutIcon = Instance.new("ImageLabel")
    local ZoomInBtn = Instance.new("TextButton")
    local ZoomInIcon = Instance.new("ImageLabel")
    local ResetSizeBtn = Instance.new("TextButton")
    local ResetSizeIcon = Instance.new("ImageLabel")
    
    ZoomOutBtn.Name = "ZoomOutBtn"
    ZoomOutBtn.Parent = TopFrame
    ZoomOutBtn.BackgroundColor3 = Config.BackgroundColor
    ZoomOutBtn.BackgroundTransparency = 0
    ZoomOutBtn.Position = UDim2.new(1, -btnSize * 3 - 11, 0, 0)
    ZoomOutBtn.Size = UDim2.new(0, btnSize, 0, scaledTopBar)
    ZoomOutBtn.Text = ""
    ZoomOutBtn.BorderSizePixel = 0
    ZoomOutBtn.AutoButtonColor = false
    
    ZoomOutIcon.Parent = ZoomOutBtn
    ZoomOutIcon.BackgroundTransparency = 1
    ZoomOutIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ZoomOutIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    ZoomOutIcon.Size = UDim2.new(0, btnIconSize, 0, btnIconSize)
    ZoomOutIcon.Image = "http://www.roblox.com/asset/?id=6035067836"
    ZoomOutIcon.ImageColor3 = Color3.fromRGB(220, 221, 222)
    
    ZoomInBtn.Name = "ZoomInBtn"
    ZoomInBtn.Parent = TopFrame
    ZoomInBtn.BackgroundColor3 = Config.BackgroundColor
    ZoomInBtn.BackgroundTransparency = 0
    ZoomInBtn.Position = UDim2.new(1, -btnSize * 4 - 14, 0, 0)
    ZoomInBtn.Size = UDim2.new(0, btnSize, 0, scaledTopBar)
    ZoomInBtn.Text = ""
    ZoomInBtn.BorderSizePixel = 0
    ZoomInBtn.AutoButtonColor = false
    
    ZoomInIcon.Parent = ZoomInBtn
    ZoomInIcon.BackgroundTransparency = 1
    ZoomInIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ZoomInIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    ZoomInIcon.Size = UDim2.new(0, btnIconSize, 0, btnIconSize)
    ZoomInIcon.Image = "http://www.roblox.com/asset/?id=6034407084"
    ZoomInIcon.ImageColor3 = Color3.fromRGB(220, 221, 222)
    
    ResetSizeBtn.Name = "ResetSizeBtn"
    ResetSizeBtn.Parent = TopFrame
    ResetSizeBtn.BackgroundColor3 = Config.BackgroundColor
    ResetSizeBtn.BackgroundTransparency = 0
    ResetSizeBtn.Position = UDim2.new(1, -btnSize * 5 - 17, 0, 0)
    ResetSizeBtn.Size = UDim2.new(0, btnSize, 0, scaledTopBar)
    ResetSizeBtn.Text = ""
    ResetSizeBtn.BorderSizePixel = 0
    ResetSizeBtn.AutoButtonColor = false
    
    ResetSizeIcon.Parent = ResetSizeBtn
    ResetSizeIcon.BackgroundTransparency = 1
    ResetSizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ResetSizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    ResetSizeIcon.Size = UDim2.new(0, btnIconSize, 0, btnIconSize)
    ResetSizeIcon.Image = "http://www.roblox.com/asset/?id=6031280882"
    ResetSizeIcon.ImageColor3 = Color3.fromRGB(220, 221, 222)
    
    -- 按钮悬停效果
    local function setupButtonHover(btn, normalColor, hoverColor)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = hoverColor end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = normalColor end)
    end
    
    setupButtonHover(CloseBtn, Config.BackgroundColor, Color3.fromRGB(240, 71, 71))
    setupButtonHover(MinimizeBtn, Config.BackgroundColor, Color3.fromRGB(40, 43, 46))
    setupButtonHover(ZoomOutBtn, Config.BackgroundColor, Color3.fromRGB(40, 43, 46))
    setupButtonHover(ZoomInBtn, Config.BackgroundColor, Color3.fromRGB(40, 43, 46))
    setupButtonHover(ResetSizeBtn, Config.BackgroundColor, Color3.fromRGB(40, 43, 46))
    
    CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        MainFrame.Size = minimized and UDim2.new(0, scaledW, 0, scaledTopBar) or UDim2.new(0, scaledW, 0, scaledH)
    end)
    ZoomOutBtn.MouseButton1Click:Connect(function() 
        local newScale = setUIScale(currentScale - scaleStep)
        scaledW = math.floor(windowWidth * newScale)
        scaledH = math.floor(windowHeight * newScale)
        MainFrame.Size = UDim2.new(0, scaledW, 0, minimized and scaledTopBar or scaledH)
    end)
    ZoomInBtn.MouseButton1Click:Connect(function()
        local newScale = setUIScale(currentScale + scaleStep)
        scaledW = math.floor(windowWidth * newScale)
        scaledH = math.floor(windowHeight * newScale)
        MainFrame.Size = UDim2.new(0, scaledW, 0, minimized and scaledTopBar or scaledH)
    end)
    ResetSizeBtn.MouseButton1Click:Connect(function()
        local newScale = setUIScale(0.85)
        scaledW = math.floor(windowWidth * newScale)
        scaledH = math.floor(windowHeight * newScale)
        MainFrame.Size = UDim2.new(0, scaledW, 0, minimized and scaledTopBar or scaledH)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    end)

    ServersHolder.Name = "ServersHolder"
    ServersHolder.Parent = TopFrameHolder

    -- 用户面板
    Userpad.Name = "Userpad"
    Userpad.Parent = TopFrameHolder
    Userpad.BackgroundColor3 = Config.SecondaryColor
    Userpad.BorderSizePixel = 0
    Userpad.Position = UDim2.new(0, scaledSidebar + 5, 0, scaledTopBar + 5)
    Userpad.Size = UDim2.new(0, scaledW - scaledSidebar - 10, 0, math.floor(userpadHeight * Config.UIScale))

    UserIcon.Name = "UserIcon"
    UserIcon.Parent = Userpad
    UserIcon.BackgroundColor3 = Color3.fromRGB(31, 33, 36)
    UserIcon.BorderSizePixel = 0
    UserIcon.Position = UDim2.new(0.01, 0, 0.1, 0)
    UserIcon.Size = UDim2.new(0, math.floor(36 * Config.UIScale), 0, math.floor(36 * Config.UIScale))

    UserIconCorner.CornerRadius = UDim.new(1, math.floor(18 * Config.UIScale))
    UserIconCorner.Parent = UserIcon

    UserImage.Name = "UserImage"
    UserImage.Parent = UserIcon
    UserImage.BackgroundTransparency = 1
    UserImage.Size = UDim2.new(1, 0, 1, 0)
    UserImage.Image = pfp
    
    UserCircleImage.Name = "UserCircleImage"
    UserCircleImage.Parent = UserImage
    UserCircleImage.BackgroundTransparency = 1
    UserCircleImage.Size = UDim2.new(1, 0, 1, 0)
    UserCircleImage.Image = "rbxassetid://4031889928"
    UserCircleImage.ImageColor3 = Config.SecondaryColor
    
    UserName.Name = "UserName"
    UserName.Parent = Userpad
    UserName.BackgroundTransparency = 1
    UserName.Position = UDim2.new(0.12, 0, 0.1, 0)
    UserName.Size = UDim2.new(0, math.floor(120 * Config.UIScale), 0, math.floor(18 * Config.UIScale))
    UserName.Font = Enum.Font.GothamSemibold
    UserName.TextColor3 = Config.TextColor
    UserName.TextSize = math.floor(14 * Config.UIScale)
    UserName.TextXAlignment = Enum.TextXAlignment.Left
    UserName.Text = user

    UserTag.Name = "UserTag"
    UserTag.Parent = Userpad
    UserTag.BackgroundTransparency = 1
    UserTag.Position = UDim2.new(0.12, 0, 0.55, 0)
    UserTag.Size = UDim2.new(0, math.floor(120 * Config.UIScale), 0, math.floor(16 * Config.UIScale))
    UserTag.Font = Enum.Font.Gotham
    UserTag.TextColor3 = Config.TextColor
    UserTag.TextTransparency = 0.4
    UserTag.TextSize = math.floor(12 * Config.UIScale)
    UserTag.TextXAlignment = Enum.TextXAlignment.Left
    UserTag.Text = "#" .. tag

    -- 侧边栏
    ServersHoldFrame.Name = "ServersHoldFrame"
    ServersHoldFrame.Parent = MainFrame
    ServersHoldFrame.BackgroundTransparency = 1
    ServersHoldFrame.Size = UDim2.new(0, scaledSidebar, 0, scaledH)

    ServersHold.Name = "ServersHold"
    ServersHold.Parent = ServersHoldFrame
    ServersHold.Active = true
    ServersHold.BackgroundTransparency = 1
    ServersHold.BorderSizePixel = 0
    ServersHold.Position = UDim2.new(0, 0, 0, scaledTopBar)
    ServersHold.Size = UDim2.new(0, scaledSidebar, 0, scaledH - scaledTopBar)
    ServersHold.ScrollBarThickness = 2
    ServersHold.ScrollBarImageTransparency = 0.8
    ServersHold.CanvasSize = UDim2.new(0, 0, 0, 0)

    ServersHoldLayout.Name = "ServersHoldLayout"
    ServersHoldLayout.Parent = ServersHold
    ServersHoldLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ServersHoldLayout.Padding = UDim.new(0, math.floor(8 * Config.UIScale))
    ServersHoldLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    ServersHoldPadding.Name = "ServersHoldPadding"
    ServersHoldPadding.Parent = ServersHold
    ServersHoldPadding.PaddingTop = UDim.new(0, math.floor(10 * Config.UIScale))

    -- 设置按钮
    local SettingsOpenBtn = Instance.new("TextButton")
    local SettingsOpenBtnIco = Instance.new("ImageLabel")
    
    SettingsOpenBtn.Name = "SettingsOpenBtn"
    SettingsOpenBtn.Parent = Userpad
    SettingsOpenBtn.BackgroundTransparency = 1
    SettingsOpenBtn.Position = UDim2.new(1, -math.floor(40 * Config.UIScale), 0.5, -math.floor(12 * Config.UIScale))
    SettingsOpenBtn.Size = UDim2.new(0, math.floor(30 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
    SettingsOpenBtn.Text = ""

    SettingsOpenBtnIco.Name = "SettingsOpenBtnIco"
    SettingsOpenBtnIco.Parent = SettingsOpenBtn
    SettingsOpenBtnIco.BackgroundTransparency = 1
    SettingsOpenBtnIco.Size = UDim2.new(1, 0, 1, 0)
    SettingsOpenBtnIco.Image = "http://www.roblox.com/asset/?id=6031280882"
    SettingsOpenBtnIco.ImageColor3 = Config.TextColor

    -- 设置窗口 (简化版，保持原有结构但修复边框)
    local SettingsFrame = Instance.new("Frame")
    local Settings = Instance.new("Frame")
    local SettingsHolder = Instance.new("Frame")
    
    SettingsFrame.Name = "SettingsFrame"
    SettingsFrame.Parent = MainFrame
    SettingsFrame.BackgroundColor3 = Config.BackgroundColor
    SettingsFrame.BackgroundTransparency = 1
    SettingsFrame.Size = UDim2.new(1, 0, 1, 0)
    SettingsFrame.Visible = false

    Settings.Name = "Settings"
    Settings.Parent = SettingsFrame
    Settings.BackgroundColor3 = Config.SecondaryColor
    Settings.BorderSizePixel = 0
    Settings.Size = UDim2.new(1, 0, 1, 0)

    SettingsHolder.Name = "SettingsHolder"
    SettingsHolder.Parent = Settings
    SettingsHolder.BackgroundTransparency = 1
    SettingsHolder.Size = UDim2.new(1, 0, 1, 0)

    -- 设置窗口关闭按钮
    local CloseSettingsBtn = Instance.new("TextButton")
    local CloseSettingsBtnIcon = Instance.new("ImageLabel")
    
    CloseSettingsBtn.Name = "CloseSettingsBtn"
    CloseSettingsBtn.Parent = SettingsHolder
    CloseSettingsBtn.BackgroundColor3 = Config.AccentColor
    CloseSettingsBtn.Position = UDim2.new(1, -math.floor(45 * Config.UIScale), 0, math.floor(10 * Config.UIScale))
    CloseSettingsBtn.Size = UDim2.new(0, math.floor(35 * Config.UIScale), 0, math.floor(35 * Config.UIScale))
    CloseSettingsBtn.Text = ""
    CloseSettingsBtn.AutoButtonColor = false
    
    CloseSettingsBtnIcon.Parent = CloseSettingsBtn
    CloseSettingsBtnIcon.BackgroundTransparency = 1
    CloseSettingsBtnIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseSettingsBtnIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    CloseSettingsBtnIcon.Size = UDim2.new(0, math.floor(20 * Config.UIScale), 0, math.floor(20 * Config.UIScale))
    CloseSettingsBtnIcon.Image = "http://www.roblox.com/asset/?id=6035047409"
    CloseSettingsBtnIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    
    CloseSettingsBtn.MouseButton1Click:Connect(function()
        settingsopened = false
        TopFrameHolder.Visible = true
        ServersHoldFrame.Visible = true
        SettingsFrame.Visible = false
    end)

    SettingsOpenBtn.MouseButton1Click:Connect(function()
        settingsopened = true
        TopFrameHolder.Visible = false
        ServersHoldFrame.Visible = false
        SettingsFrame.Visible = true
    end)

    MakeDraggable(TopFrame, MainFrame)
    ServersHoldPadding.PaddingLeft = UDim.new(0, math.floor(14 * Config.UIScale))
    
    -- ServerHold 对象
    local ServerHold = {}
    function ServerHold:Server(text, img)
        local fc = false
        local currentchanneltoggled = ""
        local serverSize = math.floor(50 * Config.UIScale)
        
        local Server = Instance.new("TextButton")
        local ServerBtnCorner = Instance.new("UICorner")
        local ServerIco = Instance.new("ImageLabel")
        local ServerWhiteFrame = Instance.new("Frame")
        local ServerWhiteFrameCorner = Instance.new("UICorner")

        Server.Name = text .. "Server"
        Server.Parent = ServersHold
        Server.BackgroundColor3 = Config.SecondaryColor
        Server.Size = UDim2.new(0, serverSize, 0, serverSize)
        Server.AutoButtonColor = false
        Server.Text = ""
        Server.BorderSizePixel = 0

        ServerBtnCorner.CornerRadius = UDim.new(1, math.floor(serverSize / 2))
        ServerBtnCorner.Parent = Server

        ServerIco.Name = "ServerIco"
        ServerIco.Parent = Server
        ServerIco.AnchorPoint = Vector2.new(0.5, 0.5)
        ServerIco.Position = UDim2.new(0.5, 0, 0.5, 0)
        ServerIco.Size = UDim2.new(0, math.floor(28 * Config.UIScale), 0, math.floor(28 * Config.UIScale))
        ServerIco.BackgroundTransparency = 1
        ServerIco.Image = img or ""

        ServerWhiteFrame.Name = "ServerWhiteFrame"
        ServerWhiteFrame.Parent = Server
        ServerWhiteFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        ServerWhiteFrame.BackgroundColor3 = Config.AccentColor
        ServerWhiteFrame.Position = UDim2.new(-0.4, 0, 0.5, 0)
        ServerWhiteFrame.Size = UDim2.new(0, math.floor(10 * Config.UIScale), 0, math.floor(8 * Config.UIScale))

        ServerWhiteFrameCorner.CornerRadius = UDim.new(1, 0)
        ServerWhiteFrameCorner.Parent = ServerWhiteFrame
        
        if img == "" then Server.Text = string.sub(text, 1, 1) end
        
        ServersHold.CanvasSize = UDim2.new(0, 0, 0, ServersHoldLayout.AbsoluteContentSize.Y + math.floor(10 * Config.UIScale))

        -- 服务器内容框架
        local ServerFrame = Instance.new("Frame")
        local ServerTitle = Instance.new("TextLabel")
        local ChannelTitleFrame = Instance.new("Frame")
        local Hashtag = Instance.new("TextLabel")
        local ChannelTitle = Instance.new("TextLabel")
        local ChannelContentFrame = Instance.new("Frame")
        local ServerChannelHolder = Instance.new("ScrollingFrame")
        local ServerChannelHolderLayout = Instance.new("UIListLayout")
        local ServerChannelHolderPadding = Instance.new("UIPadding")

        ServerFrame.Name = "ServerFrame"
        ServerFrame.Parent = ServersHolder
        ServerFrame.BackgroundColor3 = Config.BackgroundColor
        ServerFrame.BorderSizePixel = 0
        ServerFrame.Position = UDim2.new(0, scaledSidebar, 0, scaledTopBar)
        ServerFrame.Size = UDim2.new(0, scaledW - scaledSidebar, 0, scaledH - scaledTopBar)
        ServerFrame.Visible = false

        ServerTitle.Name = "ServerTitle"
        ServerTitle.Parent = ServerFrame
        ServerTitle.BackgroundTransparency = 1
        ServerTitle.Position = UDim2.new(0.02, 0, 0.02, 0)
        ServerTitle.Size = UDim2.new(0, math.floor(200 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
        ServerTitle.Font = Enum.Font.GothamSemibold
        ServerTitle.Text = text
        ServerTitle.TextColor3 = Config.TextColor
        ServerTitle.TextSize = math.floor(16 * Config.UIScale)
        ServerTitle.TextXAlignment = Enum.TextXAlignment.Left

        ChannelTitleFrame.Name = "ChannelTitleFrame"
        ChannelTitleFrame.Parent = ServerFrame
        ChannelTitleFrame.BackgroundColor3 = Config.SecondaryColor
        ChannelTitleFrame.BorderSizePixel = 0
        ChannelTitleFrame.Position = UDim2.new(0.25, 0, 0, 0)
        ChannelTitleFrame.Size = UDim2.new(0.75, 0, 0, math.floor(45 * Config.UIScale))

        Hashtag.Name = "Hashtag"
        Hashtag.Parent = ChannelTitleFrame
        Hashtag.BackgroundTransparency = 1
        Hashtag.Position = UDim2.new(0.02, 0, 0, 0)
        Hashtag.Size = UDim2.new(0, math.floor(25 * Config.UIScale), 0, math.floor(45 * Config.UIScale))
        Hashtag.Font = Enum.Font.Gotham
        Hashtag.Text = "#"
        Hashtag.TextColor3 = Color3.fromRGB(150, 150, 150)
        Hashtag.TextSize = math.floor(24 * Config.UIScale)

        ChannelTitle.Name = "ChannelTitle"
        ChannelTitle.Parent = ChannelTitleFrame
        ChannelTitle.BackgroundTransparency = 1
        ChannelTitle.Position = UDim2.new(0.08, 0, 0, 0)
        ChannelTitle.Size = UDim2.new(0, math.floor(200 * Config.UIScale), 0, math.floor(45 * Config.UIScale))
        ChannelTitle.Font = Enum.Font.GothamSemibold
        ChannelTitle.Text = ""
        ChannelTitle.TextColor3 = Config.TextColor
        ChannelTitle.TextSize = math.floor(15 * Config.UIScale)
        ChannelTitle.TextXAlignment = Enum.TextXAlignment.Left

        ChannelContentFrame.Name = "ChannelContentFrame"
        ChannelContentFrame.Parent = ServerFrame
        ChannelContentFrame.BackgroundColor3 = Config.SecondaryColor
        ChannelContentFrame.BorderSizePixel = 0
        ChannelContentFrame.Position = UDim2.new(0.25, 0, 0, math.floor(45 * Config.UIScale))
        ChannelContentFrame.Size = UDim2.new(0.75, 0, 0, -math.floor(45 * Config.UIScale))

        ServerChannelHolder.Name = "ServerChannelHolder"
        ServerChannelHolder.Parent = ServerFrame
        ServerChannelHolder.Active = true
        ServerChannelHolder.BackgroundTransparency = 1
        ServerChannelHolder.BorderSizePixel = 0
        ServerChannelHolder.Position = UDim2.new(0.01, 0, 0.08, 0)
        ServerChannelHolder.Size = UDim2.new(0.23, 0, 0.92, 0)
        ServerChannelHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
        ServerChannelHolder.ScrollBarThickness = 3
        ServerChannelHolder.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)

        ServerChannelHolderLayout.Name = "ServerChannelHolderLayout"
        ServerChannelHolderLayout.Parent = ServerChannelHolder
        ServerChannelHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ServerChannelHolderLayout.Padding = UDim.new(0, math.floor(4 * Config.UIScale))

        ServerChannelHolderPadding.Name = "ServerChannelHolderPadding"
        ServerChannelHolderPadding.Parent = ServerChannelHolder
        ServerChannelHolderPadding.PaddingLeft = UDim.new(0, math.floor(8 * Config.UIScale))

        -- 服务器悬停效果
        Server.MouseEnter:Connect(function()
            if currentservertoggled ~= Server.Name then
                TweenService:Create(Server, TweenInfo.new(0.15), {BackgroundColor3 = HoverColors.ServerHover}):Play()
                TweenService:Create(ServerBtnCorner, TweenInfo.new(0.15), {CornerRadius = UDim.new(0, math.floor(15 * Config.UIScale))}):Play()
                ServerWhiteFrame:TweenSize(UDim2.new(0, math.floor(10 * Config.UIScale), 0, math.floor(30 * Config.UIScale)), "Out", "Quart", 0.2, true)
            end
        end)

        Server.MouseLeave:Connect(function()
            if currentservertoggled ~= Server.Name then
                TweenService:Create(Server, TweenInfo.new(0.15), {BackgroundColor3 = HoverColors.ServerNormal}):Play()
                TweenService:Create(ServerBtnCorner, TweenInfo.new(0.15), {CornerRadius = UDim.new(1, math.floor(serverSize / 2))}):Play()
                ServerWhiteFrame:TweenSize(UDim2.new(0, math.floor(10 * Config.UIScale), 0, math.floor(8 * Config.UIScale)), "Out", "Quart", 0.2, true)
            end
        end)

        Server.MouseButton1Click:Connect(function()
            currentservertoggled = Server.Name
            for _, v in pairs(ServersHolder:GetChildren()) do
                if v.Name == "ServerFrame" then v.Visible = false end
            end
            ServerFrame.Visible = true
            for _, v in pairs(ServersHold:GetChildren()) do
                if v:IsA("TextButton") then
                    TweenService:Create(v, TweenInfo.new(0.15), {BackgroundColor3 = HoverColors.ServerNormal}):Play()
                    if v.ServerCorner then
                        TweenService:Create(v.ServerCorner, TweenInfo.new(0.15), {CornerRadius = UDim.new(1, math.floor(v.AbsoluteSize.X / 2))}):Play()
                    end
                    if v.ServerWhiteFrame then
                        v.ServerWhiteFrame:TweenSize(UDim2.new(0, math.floor(10 * Config.UIScale), 0, math.floor(8 * Config.UIScale)), "Out", "Quart", 0.2, true)
                    end
                end
            end
            TweenService:Create(Server, TweenInfo.new(0.15), {BackgroundColor3 = HoverColors.ServerHover}):Play()
            TweenService:Create(ServerBtnCorner, TweenInfo.new(0.15), {CornerRadius = UDim.new(0, math.floor(15 * Config.UIScale))}):Play()
            ServerWhiteFrame:TweenSize(UDim2.new(0, math.floor(10 * Config.UIScale), 0, math.floor(46 * Config.UIScale)), "Out", "Quart", 0.2, true)
        end)

        if fs == false then
            fs = true
            Server.MouseButton1Click:Fire()
        end

        local ChannelHold = {}
        function ChannelHold:Channel(channelText)
            local ChannelBtn = Instance.new("TextButton")
            local ChannelBtnCorner = Instance.new("UICorner")
            local ChannelBtnHashtag = Instance.new("TextLabel")
            local ChannelBtnTitle = Instance.new("TextLabel")

            ChannelBtn.Name = channelText .. "ChannelBtn"
            ChannelBtn.Parent = ServerChannelHolder
            ChannelBtn.BackgroundColor3 = Config.SecondaryColor
            ChannelBtn.BorderSizePixel = 0
            ChannelBtn.Size = UDim2.new(0, math.floor(160 * Config.UIScale), 0, math.floor(32 * Config.UIScale))
            ChannelBtn.AutoButtonColor = false
            ChannelBtn.Text = ""

            ChannelBtnCorner.CornerRadius = UDim.new(0, math.floor(6 * Config.UIScale))
            ChannelBtnCorner.Parent = ChannelBtn

            ChannelBtnHashtag.Name = "ChannelBtnHashtag"
            ChannelBtnHashtag.Parent = ChannelBtn
            ChannelBtnHashtag.BackgroundTransparency = 1
            ChannelBtnHashtag.Position = UDim2.new(0.03, 0, 0, 0)
            ChannelBtnHashtag.Size = UDim2.new(0, math.floor(24 * Config.UIScale), 0, math.floor(32 * Config.UIScale))
            ChannelBtnHashtag.Font = Enum.Font.Gotham
            ChannelBtnHashtag.Text = "#"
            ChannelBtnHashtag.TextColor3 = Color3.fromRGB(140, 140, 140)
            ChannelBtnHashtag.TextSize = math.floor(20 * Config.UIScale)

            ChannelBtnTitle.Name = "ChannelBtnTitle"
            ChannelBtnTitle.Parent = ChannelBtn
            ChannelBtnTitle.BackgroundTransparency = 1
            ChannelBtnTitle.Position = UDim2.new(0.15, 0, 0, 0)
            ChannelBtnTitle.Size = UDim2.new(0, math.floor(120 * Config.UIScale), 0, math.floor(32 * Config.UIScale))
            ChannelBtnTitle.Font = Enum.Font.Gotham
            ChannelBtnTitle.Text = channelText
            ChannelBtnTitle.TextColor3 = Color3.fromRGB(140, 140, 140)
            ChannelBtnTitle.TextSize = math.floor(14 * Config.UIScale)
            ChannelBtnTitle.TextXAlignment = Enum.TextXAlignment.Left
            
            ServerChannelHolder.CanvasSize = UDim2.new(0, 0, 0, ServerChannelHolderLayout.AbsoluteContentSize.Y + math.floor(10 * Config.UIScale))

            local ChannelHolder = Instance.new("ScrollingFrame")
            local ChannelHolderLayout = Instance.new("UIListLayout")

            ChannelHolder.Name = "ChannelHolder"
            ChannelHolder.Parent = ChannelContentFrame
            ChannelHolder.Active = true
            ChannelHolder.BackgroundTransparency = 1
            ChannelHolder.BorderSizePixel = 0
            ChannelHolder.Position = UDim2.new(0.02, 0, 0.02, 0)
            ChannelHolder.Size = UDim2.new(0.96, 0, 0.96, 0)
            ChannelHolder.ScrollBarThickness = 4
            ChannelHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
            ChannelHolder.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
            ChannelHolder.Visible = false

            ChannelHolderLayout.Name = "ChannelHolderLayout"
            ChannelHolderLayout.Parent = ChannelHolder
            ChannelHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ChannelHolderLayout.Padding = UDim.new(0, math.floor(8 * Config.UIScale))
            ChannelHolderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

            ChannelBtn.MouseEnter:Connect(function()
                if currentchanneltoggled ~= ChannelBtn.Name then
                    ChannelBtn.BackgroundColor3 = HoverColors.ChannelHover
                    ChannelBtnTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
                end
            end)
            
            ChannelBtn.MouseLeave:Connect(function()
                if currentchanneltoggled ~= ChannelBtn.Name then
                    ChannelBtn.BackgroundColor3 = HoverColors.ChannelNormal
                    ChannelBtnTitle.TextColor3 = Color3.fromRGB(140, 140, 140)
                end
            end)
            
            ChannelBtn.MouseButton1Click:Connect(function()
                for _, v in pairs(ChannelContentFrame:GetChildren()) do
                    if v.Name == "ChannelHolder" then v.Visible = false end
                end
                ChannelHolder.Visible = true
                for _, v in pairs(ServerChannelHolder:GetChildren()) do
                    if v:IsA("TextButton") then
                        v.BackgroundColor3 = Config.SecondaryColor
                        if v.ChannelBtnTitle then v.ChannelBtnTitle.TextColor3 = Color3.fromRGB(140, 140, 140) end
                    end
                end
                ChannelTitle.Text = channelText
                ChannelBtn.BackgroundColor3 = Color3.fromRGB(57, 60, 67)
                ChannelBtnTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                currentchanneltoggled = ChannelBtn.Name
            end)
            
            if fc == false then
                fc = true
                ChannelBtn.MouseButton1Click:Fire()
            end

            -- ChannelContent 对象
            local ChannelContent = {}
            
            function ChannelContent:Button(btnText, callback)
                local Button = Instance.new("TextButton")
                local ButtonCorner = Instance.new("UICorner")

                Button.Name = "Button"
                Button.Parent = ChannelHolder
                Button.BackgroundColor3 = Config.AccentColor
                Button.Size = UDim2.new(0.96, 0, 0, math.floor(38 * Config.UIScale))
                Button.AutoButtonColor = false
                Button.Font = Enum.Font.Gotham
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.TextSize = math.floor(14 * Config.UIScale)
                Button.Text = btnText
                Button.BorderSizePixel = 0

                ButtonCorner.CornerRadius = UDim.new(0, math.floor(6 * Config.UIScale))
                ButtonCorner.Parent = Button
                
                Button.MouseEnter:Connect(function()
                    PlaySound("Hover")
                    TweenService:Create(Button, TweenInfo.new(Config.AnimationSpeed), {BackgroundColor3 = HoverColors.ButtonHover}):Play()
                    CreateGlow(Button, Config.AccentColor)
                end)
                
                Button.MouseButton1Click:Connect(function()
                    PlaySound("Click")
                    pcall(callback)
                end)
                
                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(Config.AnimationSpeed), {BackgroundColor3 = HoverColors.ButtonNormal}):Play()
                    local glow = Button:FindFirstChild("Glow")
                    if glow then glow:Destroy() end
                end)
                
                ChannelHolder.CanvasSize = UDim2.new(0, 0, 0, ChannelHolderLayout.AbsoluteContentSize.Y + math.floor(10 * Config.UIScale))
            end
            
            function ChannelContent:Toggle(toggleText, defaultVal, callback)
                local toggled = defaultVal or false
                local Toggle = Instance.new("TextButton")
                local ToggleTitle = Instance.new("TextLabel")
                local ToggleFrame = Instance.new("Frame")
                local ToggleFrameCorner = Instance.new("UICorner")
                local ToggleFrameCircle = Instance.new("Frame")
                local ToggleFrameCircleCorner = Instance.new("UICorner")
                local Icon = Instance.new("ImageLabel")

                Toggle.Name = "Toggle"
                Toggle.Parent = ChannelHolder
                Toggle.BackgroundColor3 = Config.SecondaryColor
                Toggle.BorderSizePixel = 0
                Toggle.Size = UDim2.new(0.96, 0, 0, math.floor(38 * Config.UIScale))
                Toggle.AutoButtonColor = false
                Toggle.Text = ""

                ToggleTitle.Name = "ToggleTitle"
                ToggleTitle.Parent = Toggle
                ToggleTitle.BackgroundTransparency = 1
                ToggleTitle.Position = UDim2.new(0.02, 0, 0, 0)
                ToggleTitle.Size = UDim2.new(0.7, 0, 0, math.floor(38 * Config.UIScale))
                ToggleTitle.Font = Enum.Font.Gotham
                ToggleTitle.Text = toggleText
                ToggleTitle.TextColor3 = Config.TextColor
                ToggleTitle.TextSize = math.floor(14 * Config.UIScale)
                ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left

                ToggleFrame.Name = "ToggleFrame"
                ToggleFrame.Parent = Toggle
                ToggleFrame.BackgroundColor3 = toggled and Color3.fromRGB(67, 181, 129) or Color3.fromRGB(114, 118, 125)
                ToggleFrame.Position = UDim2.new(0.92, -5, 0.5, -10)
                ToggleFrame.Size = UDim2.new(0, math.floor(44 * Config.UIScale), 0, math.floor(22 * Config.UIScale))

                ToggleFrameCorner.CornerRadius = UDim.new(1, math.floor(11 * Config.UIScale))
                ToggleFrameCorner.Parent = ToggleFrame

                ToggleFrameCircle.Name = "ToggleFrameCircle"
                ToggleFrameCircle.Parent = ToggleFrame
                ToggleFrameCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ToggleFrameCircle.Position = toggled and UDim2.new(0.65, -5, 0.13, 0) or UDim2.new(0.23, -5, 0.13, 0)
                ToggleFrameCircle.Size = UDim2.new(0, math.floor(16 * Config.UIScale), 0, math.floor(16 * Config.UIScale))

                ToggleFrameCircleCorner.CornerRadius = UDim.new(1, math.floor(8 * Config.UIScale))
                ToggleFrameCircleCorner.Parent = ToggleFrameCircle

                Icon.Name = "Icon"
                Icon.Parent = ToggleFrameCircle
                Icon.AnchorPoint = Vector2.new(0.5, 0.5)
                Icon.BackgroundTransparency = 1
                Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
                Icon.Size = UDim2.new(0, math.floor(12 * Config.UIScale), 0, math.floor(12 * Config.UIScale))
                Icon.Image = toggled and "http://www.roblox.com/asset/?id=6023426926" or "http://www.roblox.com/asset/?id=6035047409"
                Icon.ImageColor3 = toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(114, 118, 125)
                
                Toggle.MouseButton1Click:Connect(function()
                    PlaySound("Click")
                    toggled = not toggled
                    local targetColor = toggled and Color3.fromRGB(67, 181, 129) or Color3.fromRGB(114, 118, 125)
                    local targetPos = toggled and UDim2.new(0.65, -5, 0.13, 0) or UDim2.new(0.23, -5, 0.13, 0)
                    local targetIcon = toggled and "http://www.roblox.com/asset/?id=6023426926" or "http://www.roblox.com/asset/?id=6035047409"
                    
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                    TweenService:Create(ToggleFrameCircle, TweenInfo.new(0.2), {Position = targetPos}):Play()
                    Icon.Image = targetIcon
                    pcall(callback, toggled)
                end)
                
                ChannelHolder.CanvasSize = UDim2.new(0, 0, 0, ChannelHolderLayout.AbsoluteContentSize.Y + math.floor(10 * Config.UIScale))
            end
            
            -- 手机端友好的滑块实现
            function ChannelContent:Slider(sliderText, minVal, maxVal, startVal, callback)
                local SliderFunc = {}
                local Slider = Instance.new("Frame")
                local SliderTitle = Instance.new("TextLabel")
                local SliderFrame = Instance.new("Frame")
                local SliderFrameCorner = Instance.new("UICorner")
                local CurrentValueFrame = Instance.new("Frame")
                local CurrentValueFrameCorner = Instance.new("UICorner")
                local Zip = Instance.new("TextButton")
                local ZipCorner = Instance.new("UICorner")
                local ValueLabel = Instance.new("TextLabel")

                Slider.Name = "Slider"
                Slider.Parent = ChannelHolder
                Slider.BackgroundColor3 = Config.SecondaryColor
                Slider.BorderSizePixel = 0
                Slider.Size = UDim2.new(0.96, 0, 0, math.floor(55 * Config.UIScale))

                SliderTitle.Name = "SliderTitle"
                SliderTitle.Parent = Slider
                SliderTitle.BackgroundTransparency = 1
                SliderTitle.Position = UDim2.new(0.02, 0, 0.05, 0)
                SliderTitle.Size = UDim2.new(0.6, 0, 0, math.floor(20 * Config.UIScale))
                SliderTitle.Font = Enum.Font.Gotham
                SliderTitle.Text = sliderText
                SliderTitle.TextColor3 = Config.TextColor
                SliderTitle.TextSize = math.floor(14 * Config.UIScale)
                SliderTitle.TextXAlignment = Enum.TextXAlignment.Left

                SliderFrame.Name = "SliderFrame"
                SliderFrame.Parent = Slider
                SliderFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                SliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
                SliderFrame.Position = UDim2.new(0.5, 0, 0.7, 0)
                SliderFrame.Size = UDim2.new(0.94, 0, 0, math.floor(6 * Config.UIScale))

                SliderFrameCorner.CornerRadius = UDim.new(1, math.floor(3 * Config.UIScale))
                SliderFrameCorner.Parent = SliderFrame

                CurrentValueFrame.Name = "CurrentValueFrame"
                CurrentValueFrame.Parent = SliderFrame
                CurrentValueFrame.BackgroundColor3 = Config.AccentColor
                CurrentValueFrame.Size = UDim2.new((startVal or 0) / maxVal, 0, 0, math.floor(6 * Config.UIScale))

                CurrentValueFrameCorner.CornerRadius = UDim.new(1, math.floor(3 * Config.UIScale))
                CurrentValueFrameCorner.Parent = CurrentValueFrame

                Zip.Name = "Zip"
                Zip.Parent = SliderFrame
                Zip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Zip.Position = UDim2.new((startVal or 0) / maxVal, -7, 0.5, -9)
                Zip.Size = UDim2.new(0, math.floor(14 * Config.UIScale), 0, math.floor(18 * Config.UIScale))
                Zip.Text = ""
                Zip.AutoButtonColor = false

                ZipCorner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
                ZipCorner.Parent = Zip

                ValueLabel.Name = "ValueLabel"
                ValueLabel.Parent = Zip
                ValueLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                ValueLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                ValueLabel.Position = UDim2.new(0.5, 0, -1.2, 0)
                ValueLabel.Size = UDim2.new(0, math.floor(40 * Config.UIScale), 0, math.floor(22 * Config.UIScale))
                ValueLabel.Font = Enum.Font.Gotham
                ValueLabel.Text = tostring(startVal or 0)
                ValueLabel.TextColor3 = Config.TextColor
                ValueLabel.TextSize = math.floor(12 * Config.UIScale)
                ValueLabel.Visible = false
                
                local function updateValue(inputPos)
                    local relativeX = math.clamp((inputPos.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
                    local value = math.floor(relativeX * (maxVal - minVal) + minVal)
                    CurrentValueFrame.Size = UDim2.new(relativeX, 0, 0, math.floor(6 * Config.UIScale))
                    Zip.Position = UDim2.new(relativeX, -7, 0.5, -9)
                    ValueLabel.Text = tostring(value)
                    pcall(callback, value)
                end
                
                Zip.MouseEnter:Connect(function() ValueLabel.Visible = true end)
                Zip.MouseLeave:Connect(function() ValueLabel.Visible = false end)
                
                Zip.MouseButton1Click:Connect(function(input) updateValue(input) end)
                SliderFrame.MouseButton1Click:Connect(function(input) updateValue(input) end)
                
                -- 手机端触摸支持
                Zip.TouchTap:Connect(function(input) updateValue(input) end)
                SliderFrame.TouchTap:Connect(function(input) updateValue(input) end)
                
                function SliderFunc:Change(tochange)
                    local relativeX = math.clamp((tochange - minVal) / (maxVal - minVal), 0, 1)
                    CurrentValueFrame.Size = UDim2.new(relativeX, 0, 0, math.floor(6 * Config.UIScale))
                    Zip.Position = UDim2.new(relativeX, -7, 0.5, -9)
                    ValueLabel.Text = tostring(tochange)
                    pcall(callback, tochange)
                end
                
                ChannelHolder.CanvasSize = UDim2.new(0, 0, 0, ChannelHolderLayout.AbsoluteContentSize.Y + math.floor(10 * Config.UIScale))
                return SliderFunc
            end
            
            function ChannelContent:Seperator()
                local line = Instance.new("Frame")
                line.Name = "Seperator"
                line.Parent = ChannelHolder
                line.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
                line.BorderSizePixel = 0
                line.Size = UDim2.new(0.96, 0, 0, math.floor(1 * Config.UIScale))
                ChannelHolder.CanvasSize = UDim2.new(0, 0, 0, ChannelHolderLayout.AbsoluteContentSize.Y + math.floor(10 * Config.UIScale))
            end
            
            function ChannelContent:Label(labelText)
                local Label = Instance.new("TextLabel")
                Label.Name = "Label"
                Label.Parent = ChannelHolder
                Label.BackgroundColor3 = Config.SecondaryColor
                Label.BorderSizePixel = 0
                Label.Size = UDim2.new(0.96, 0, 0, math.floor(32 * Config.UIScale))
                Label.Font = Enum.Font.Gotham
                Label.Text = labelText
                Label.TextColor3 = Config.TextColor
                Label.TextSize = math.floor(14 * Config.UIScale)
                Label.TextXAlignment = Enum.TextXAlignment.Left
                ChannelHolder.CanvasSize = UDim2.new(0, 0, 0, ChannelHolderLayout.AbsoluteContentSize.Y + math.floor(10 * Config.UIScale))
            end
            
            function ChannelContent:Bind(bindText, defaultKey, callback)
                local currentKey = defaultKey.Name or "None"
                local Bind = Instance.new("TextButton")
                local BindTitle = Instance.new("TextLabel")
                local BindKeyText = Instance.new("TextLabel")

                Bind.Name = "Bind"
                Bind.Parent = ChannelHolder
                Bind.BackgroundColor3 = Config.SecondaryColor
                Bind.BorderSizePixel = 0
                Bind.Size = UDim2.new(0.96, 0, 0, math.floor(38 * Config.UIScale))
                Bind.AutoButtonColor = false
                Bind.Text = ""

                BindTitle.Name = "BindTitle"
                BindTitle.Parent = Bind
                BindTitle.BackgroundTransparency = 1
                BindTitle.Position = UDim2.new(0.02, 0, 0, 0)
                BindTitle.Size = UDim2.new(0.6, 0, 0, math.floor(38 * Config.UIScale))
                BindTitle.Font = Enum.Font.Gotham
                BindTitle.Text = bindText
                BindTitle.TextColor3 = Config.TextColor
                BindTitle.TextSize = math.floor(14 * Config.UIScale)
                BindTitle.TextXAlignment = Enum.TextXAlignment.Left

                BindKeyText.Name = "BindKeyText"
                BindKeyText.Parent = Bind
                BindKeyText.BackgroundTransparency = 1
                BindKeyText.Position = UDim2.new(0.85, 0, 0, 0)
                BindKeyText.Size = UDim2.new(0.13, 0, 0, math.floor(38 * Config.UIScale))
                BindKeyText.Font = Enum.Font.Gotham
                BindKeyText.Text = currentKey
                BindKeyText.TextColor3 = Config.AccentColor
                BindKeyText.TextSize = math.floor(14 * Config.UIScale)
                BindKeyText.TextXAlignment = Enum.TextXAlignment.Right
                
                Bind.MouseButton1Click:Connect(function()
                    BindKeyText.Text = "..."
                    local input = UserInputService.InputBegan:wait()
                    if input.KeyCode.Name ~= "Unknown" then
                        currentKey = input.KeyCode.Name
                        BindKeyText.Text = currentKey
                    end
                end)
                
                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed and input.KeyCode.Name == currentKey then
                        pcall(callback)
                    end
                end)
                
                ChannelHolder.CanvasSize = UDim2.new(0, 0, 0, ChannelHolderLayout.AbsoluteContentSize.Y + math.floor(10 * Config.UIScale))
            end
            
            function ChannelContent:Colorpicker(colorText, defaultColor, callback)
                local ColorpickerFrame = Instance.new("Frame")
                local ColorpickerTitle = Instance.new("TextLabel")
                local ColorDisplay = Instance.new("Frame")
                local ColorDisplayCorner = Instance.new("UICorner")
                local ColorWheel = Instance.new("ImageLabel")
                local HueBar = Instance.new("Frame")
                local HueGradient = Instance.new("UIGradient")
                local ColorSelector = Instance.new("ImageLabel")
                local HueSelector = Instance.new("ImageLabel")

                ColorpickerFrame.Name = "Colorpicker"
                ColorpickerFrame.Parent = ChannelHolder
                ColorpickerFrame.BackgroundColor3 = Config.SecondaryColor
                ColorpickerFrame.Size = UDim2.new(0.96, 0, 0, math.floor(150 * Config.UIScale))

                ColorpickerTitle.Name = "ColorpickerTitle"
                ColorpickerTitle.Parent = ColorpickerFrame
                ColorpickerTitle.BackgroundTransparency = 1
                ColorpickerTitle.Position = UDim2.new(0.02, 0, 0.02, 0)
                ColorpickerTitle.Size = UDim2.new(0.5, 0, 0, math.floor(25 * Config.UIScale))
                ColorpickerTitle.Font = Enum.Font.Gotham
                ColorpickerTitle.Text = colorText
                ColorpickerTitle.TextColor3 = Config.TextColor
                ColorpickerTitle.TextSize = math.floor(14 * Config.UIScale)
                ColorpickerTitle.TextXAlignment = Enum.TextXAlignment.Left

                ColorDisplay.Name = "ColorDisplay"
                ColorDisplay.Parent = ColorpickerFrame
                ColorDisplay.BackgroundColor3 = defaultColor or Config.AccentColor
                ColorDisplay.Position = UDim2.new(0.85, 0, 0.03, 0)
                ColorDisplay.Size = UDim2.new(0, math.floor(30 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
                
                ColorDisplayCorner.CornerRadius = UDim.new(1, math.floor(15 * Config.UIScale))
                ColorDisplayCorner.Parent = ColorDisplay

                ColorWheel.Name = "ColorWheel"
                ColorWheel.Parent = ColorpickerFrame
                ColorWheel.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                ColorWheel.Position = UDim2.new(0.02, 0, 0.3, 0)
                ColorWheel.Size = UDim2.new(0, math.floor(120 * Config.UIScale), 0, math.floor(100 * Config.UIScale))
                ColorWheel.Image = "rbxassetid://4155801252"

                HueBar.Name = "HueBar"
                HueBar.Parent = ColorpickerFrame
                HueBar.Position = UDim2.new(0.4, 0, 0.3, 0)
                HueBar.Size = UDim2.new(0, math.floor(15 * Config.UIScale), 0, math.floor(100 * Config.UIScale))

                HueGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                })
                HueGradient.Rotation = 270
                HueGradient.Parent = HueBar

                ColorSelector.Name = "ColorSelector"
                ColorSelector.Parent = ColorWheel
                ColorSelector.AnchorPoint = Vector2.new(0.5, 0.5)
                ColorSelector.BackgroundTransparency = 1
                ColorSelector.Size = UDim2.new(0, math.floor(18 * Config.UIScale), 0, math.floor(18 * Config.UIScale))
                ColorSelector.Image = "http://www.roblox.com/asset/?id=4805639000"

                HueSelector.Name = "HueSelector"
                HueSelector.Parent = HueBar
                HueSelector.AnchorPoint = Vector2.new(0.5, 0.5)
                HueSelector.BackgroundTransparency = 1
                HueSelector.Size = UDim2.new(0, math.floor(18 * Config.UIScale), 0, math.floor(18 * Config.UIScale))
                HueSelector.Image = "http://www.roblox.com/asset/?id=4805639000"

                local hue = 1
                local sat = 1
                local val = 1
                
                local function updateColor()
                    local color = Color3.fromHSV(hue, sat, val)
                    ColorWheel.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    ColorDisplay.BackgroundColor3 = color
                    pcall(callback, color)
                end
                
                if defaultColor then
                    hue, sat, val = Color3.toHSV(defaultColor)
                    ColorSelector.Position = UDim2.new(sat, -9, 1 - val, -9)
                    HueSelector.Position = UDim2.new(0.5, -9, 1 - hue, -9)
                    updateColor()
                end
                
                ColorWheel.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local connection
                        connection = RunService.RenderStepped:Connect(function()
                            local pos = input.UserInputType == Enum.UserInputType.Touch and input.Position or Mouse
                            local x = math.clamp((pos.X - ColorWheel.AbsolutePosition.X) / ColorWheel.AbsoluteSize.X, 0, 1)
                            local y = math.clamp((pos.Y - ColorWheel.AbsolutePosition.Y) / ColorWheel.AbsoluteSize.Y, 0, 1)
                            ColorSelector.Position = UDim2.new(x, -9, y, -9)
                            sat = x
                            val = 1 - y
                            updateColor()
                        end)
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                connection:Disconnect()
                            end
                        end)
                    end
                end)
                
                HueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local connection
                        connection = RunService.RenderStepped:Connect(function()
                            local pos = input.UserInputType == Enum.UserInputType.Touch and input.Position or Mouse
                            local y = math.clamp((pos.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                            HueSelector.Position = UDim2.new(0.5, -9, y, -9)
                            hue = 1 - y
                            updateColor()
                        end)
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                connection:Disconnect()
                            end
                        end)
                    end
                end)
                
                ChannelHolder.CanvasSize = UDim2.new(0, 0, 0, ChannelHolderLayout.AbsoluteContentSize.Y + math.floor(10 * Config.UIScale))
            end
            
            function ChannelContent:Textbox(boxText, placeholderText, clearOnSubmit, callback)
                local Box = Instance.new("Frame")
                local BoxTitle = Instance.new("TextLabel")
                local BoxFrame = Instance.new("Frame")
                local BoxFrameCorner = Instance.new("UICorner")
                local TextBox = Instance.new("TextBox")

                Box.Name = "Textbox"
                Box.Parent = ChannelHolder
                Box.BackgroundColor3 = Config.SecondaryColor
                Box.Size = UDim2.new(0.96, 0, 0, math.floor(68 * Config.UIScale))

                BoxTitle.Name = "BoxTitle"
                BoxTitle.Parent = Box
                BoxTitle.BackgroundTransparency = 1
                BoxTitle.Position = UDim2.new(0.02, 0, 0.05, 0)
                BoxTitle.Size = UDim2.new(0.6, 0, 0, math.floor(20 * Config.UIScale))
                BoxTitle.Font = Enum.Font.Gotham
                BoxTitle.Text = boxText
                BoxTitle.TextColor3 = Config.TextColor
                BoxTitle.TextSize = math.floor(14 * Config.UIScale)
                BoxTitle.TextXAlignment = Enum.TextXAlignment.Left

                BoxFrame.Name = "BoxFrame"
                BoxFrame.Parent = Box
                BoxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                BoxFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                BoxFrame.Position = UDim2.new(0.5, 0, 0.65, 0)
                BoxFrame.Size = UDim2.new(0.95, 0, 0, math.floor(32 * Config.UIScale))

                BoxFrameCorner.CornerRadius = UDim.new(0, math.floor(6 * Config.UIScale))
                BoxFrameCorner.Parent = BoxFrame

                TextBox.Parent = BoxFrame
                TextBox.BackgroundTransparency = 1
                TextBox.Position = UDim2.new(0.02, 0, 0, 0)
                TextBox.Size = UDim2.new(0.96, 0, 1, 0)
                TextBox.Font = Enum.Font.Gotham
                TextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 105)
                TextBox.PlaceholderText = placeholderText
                TextBox.Text = ""
                TextBox.TextColor3 = Config.TextColor
                TextBox.TextSize = math.floor(14 * Config.UIScale)
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                
                TextBox.Focused:Connect(function()
                    TweenService:Create(BoxFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 55, 60)}):Play()
                end)
                
                TextBox.FocusLost:Connect(function(enterPressed)
                    TweenService:Create(BoxFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
                    if enterPressed and #TextBox.Text > 0 then
                        pcall(callback, TextBox.Text)
                        if clearOnSubmit then TextBox.Text = "" end
                    end
                end)
                
                ChannelHolder.CanvasSize = UDim2.new(0, 0, 0, ChannelHolderLayout.AbsoluteContentSize.Y + math.floor(10 * Config.UIScale))
            end
            
            return ChannelContent
        end
        
        return ChannelHold
    end
    
    -- 通知系统
    function AYXDiscordUILibrary:Notify(titleText, descText, btnText, notifType, duration)
        local notifColors = {
            Success = Color3.fromRGB(67, 181, 129),
            Error = Color3.fromRGB(240, 71, 71),
            Warning = Color3.fromRGB(255, 193, 7),
            Info = Config.AccentColor
        }
        local color = notifColors[notifType] or notifColors.Info
        
        local NotifHolder = Instance.new("TextButton")
        local NotifFrame = Instance.new("Frame")
        local NotifCorner = Instance.new("UICorner")
        local TitleLabel = Instance.new("TextLabel")
        local DescLabel = Instance.new("TextLabel")
        local ActionBtn = Instance.new("TextButton")
        local ActionCorner = Instance.new("UICorner")

        NotifHolder.Name = "NotificationHolder"
        NotifHolder.Parent = MainFrame
        NotifHolder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        NotifHolder.BackgroundTransparency = 0.3
        NotifHolder.Size = UDim2.new(1, 0, 1, 0)
        NotifHolder.AutoButtonColor = false
        NotifHolder.Text = ""
        NotifHolder.Visible = true

        NotifFrame.Name = "Notification"
        NotifFrame.Parent = NotifHolder
        NotifFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        NotifFrame.BackgroundColor3 = Config.SecondaryColor
        NotifFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        NotifFrame.Size = UDim2.new(0, math.floor(300 * Config.UIScale), 0, math.floor(160 * Config.UIScale))

        NotifCorner.CornerRadius = UDim.new(0, math.floor(10 * Config.UIScale))
        NotifCorner.Parent = NotifFrame

        TitleLabel.Name = "Title"
        TitleLabel.Parent = NotifFrame
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Position = UDim2.new(0.05, 0, 0.08, 0)
        TitleLabel.Size = UDim2.new(0.9, 0, 0, math.floor(30 * Config.UIScale))
        TitleLabel.Font = Enum.Font.GothamSemibold
        TitleLabel.Text = titleText or "Notification"
        TitleLabel.TextColor3 = Config.TextColor
        TitleLabel.TextSize = math.floor(18 * Config.UIScale)

        DescLabel.Name = "Description"
        DescLabel.Parent = NotifFrame
        DescLabel.BackgroundTransparency = 1
        DescLabel.Position = UDim2.new(0.05, 0, 0.32, 0)
        DescLabel.Size = UDim2.new(0.9, 0, 0, math.floor(50 * Config.UIScale))
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.Text = descText or ""
        DescLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
        DescLabel.TextSize = math.floor(13 * Config.UIScale)
        DescLabel.TextWrapped = true

        ActionBtn.Name = "ActionBtn"
        ActionBtn.Parent = NotifFrame
        ActionBtn.BackgroundColor3 = color
        ActionBtn.Position = UDim2.new(0.5, -math.floor(60 * Config.UIScale), 0.78, 0)
        ActionBtn.Size = UDim2.new(0, math.floor(120 * Config.UIScale), 0, math.floor(32 * Config.UIScale))
        ActionBtn.Font = Enum.Font.Gotham
        ActionBtn.Text = btnText or "OK"
        ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ActionBtn.TextSize = math.floor(14 * Config.UIScale)
        ActionBtn.AutoButtonColor = false

        ActionCorner.CornerRadius = UDim.new(0, math.floor(6 * Config.UIScale))
        ActionCorner.Parent = ActionBtn
        
        ActionBtn.MouseButton1Click:Connect(function()
            NotifHolder:Destroy()
        end)
        
        if duration and duration > 0 then
            task.wait(duration)
            if NotifHolder and NotifHolder.Parent then
                NotifHolder:Destroy()
            end
        end
        
        PlaySound("Notification")
        return NotifHolder
    end
    
    -- 简化版Notification
    function AYXDiscordUILibrary:Notification(titleText, descText, btnText)
        return AYXDiscordUILibrary:Notify(titleText, descText, btnText, "Info", 3)
    end
    
    ServerHold.Notify = function(titleText, descText, btnText, notifType, duration)
        return AYXDiscordUILibrary:Notify(titleText, descText, btnText, notifType, duration)
    end
    
    return ServerHold
end

-- 主题设置
function AYXDiscordUILibrary:SetTheme(theme)
    if theme == "Dark" then
        Config.BackgroundColor = Color3.fromRGB(30, 32, 35)
        Config.SecondaryColor = Color3.fromRGB(45, 47, 52)
        Config.TextColor = Color3.fromRGB(255, 255, 255)
    elseif theme == "Light" then
        Config.BackgroundColor = Color3.fromRGB(240, 242, 245)
        Config.SecondaryColor = Color3.fromRGB(255, 255, 255)
        Config.TextColor = Color3.fromRGB(0, 0, 0)
    end
    Config.Theme = theme
end

function AYXDiscordUILibrary:SetAccentColor(color)
    Config.AccentColor = color
    UpdateHoverColors()
end

function AYXDiscordUILibrary:SetAnimationSpeed(speed)
    Config.AnimationSpeed = speed
end

function AYXDiscordUILibrary:ToggleSounds(enabled)
    Config.EnableSounds = enabled
end

function AYXDiscordUILibrary:ToggleGlow(enabled)
    Config.EnableGlow = enabled
end

function AYXDiscordUILibrary:GetConfig()
    return Config
end

function AYXDiscordUILibrary:SaveConfig()
    if Config.SaveSettings then
        pcall(function()
            writefile("ayxdiscordlib_config.txt", HttpService:JSONEncode(Config))
        end)
    end
end

function AYXDiscordUILibrary:LoadConfig()
    if Config.SaveSettings then
        pcall(function()
            local data = HttpService:JSONDecode(readfile("ayxdiscordlib_config.txt"))
            if data then
                for k, v in pairs(data) do
                    Config[k] = v
                end
            end
        end)
    end
end

-- 彩虹模式
spawn(function()
    while task.wait(0.1) do
        if Config.EnableRainbowMode then
            Config.AccentColor = Color3.fromHSV(tick() % 1, 1, 1)
            UpdateHoverColors()
        end
    end
end)

-- 自动保存
if Config.AutoSave then
    spawn(function()
        while task.wait(30) do
            AYXDiscordUILibrary:SaveConfig()
        end
    end)
end

UpdateHoverColors()
return AYXDiscordUILibrary