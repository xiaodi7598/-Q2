--by小迪
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
    AnimationSpeed = 0.3,
    EnableSounds = true,
    EnableAnimations = true,
    EnableGlow = true,
    EnableBlur = false,
    SaveSettings = true,
    AutoSave = true,
    Notifications = true,
    EnableRainbowMode = false,
    EnableParticles = false,
    EnableSmoothScrolling = true,
    EnableTooltips = true,
    EnableKeyboardShortcuts = true,
    EnableMouseEffects = true,
    EnablePerformanceMode = false,
    MaxNotifications = 5,
    NotificationDuration = 5,
    EnableAutoClose = true,
    SoundErrorCount = 0,
    MaxSoundErrors = 5,
    UIScale = 0.75
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

-- 更新悬停颜色
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

-- 播放音效
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

-- 创建发光效果
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

-- 模糊效果
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

function AYXDiscordUILibrary:SetColor(which, color)
    if Config[which] ~= nil and typeof(color) == "Color3" then
        Config[which] = color
    end
end

function AYXDiscordUILibrary:SetThemeColors(tbl)
    for k, v in pairs(tbl) do
        if Config[k] ~= nil and typeof(v) == "Color3" then
            Config[k] = v
        end
    end
end

function AYXDiscordUILibrary:SaveTheme(name)
    if typeof(name) ~= "string" then return end
    local theme = {
        AccentColor = Config.AccentColor,
        BackgroundColor = Config.BackgroundColor,
        TextColor = Config.TextColor,
        SecondaryColor = Config.SecondaryColor
    }
    writefile("ayxdiscordlib_theme_"..name..".txt", HttpService:JSONEncode(theme))
end

function AYXDiscordUILibrary:LoadTheme(name)
    if typeof(name) ~= "string" then return end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile("ayxdiscordlib_theme_"..name..".txt"))
    end)
    if success and typeof(data) == "table" then
        self:SetThemeColors(data)
    end
end

-- 用户信息
local pfp
local user
local tag
local userinfo = {}

pcall(function()
    userinfo = HttpService:JSONDecode(readfile("discordlibinfo.txt"))
end)

local function GetSafeProfilePicture()
    local success, result = pcall(function()
        return "https://www.roblox.com/headshot-thumbnail/image?userId=".. game.Players.LocalPlayer.UserId .."&width=420&height=420&format=png"
    end)
    return success and result or "rbxassetid://0"
end

local function GetSafeUserInfo()
    local success, result = pcall(function()
        return game.Players.LocalPlayer.Name
    end)
    return success and result or "User"
end

pfp = userinfo["pfp"] or GetSafeProfilePicture()
user = userinfo["user"] or GetSafeUserInfo()
tag = userinfo["tag"] or tostring(math.random(1000,9999))

local function SaveInfo()
    userinfo["pfp"] = pfp
    userinfo["user"] = user
    userinfo["tag"] = tag
    writefile("discordlibinfo.txt", HttpService:JSONEncode(userinfo))
end

-- 拖动功能
local function MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
        object.Position = pos
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

-- 安全初始化
local function SafeInit()
    local success, result = pcall(function()
        local Discord = Instance.new("ScreenGui")
        Discord.Name = "Discord"
        Discord.Parent = game.CoreGui
        Discord.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        return Discord
    end)
    return success and result or Instance.new("ScreenGui")
end

local Discord = SafeInit()

-- 添加UIScale支持缩放
local uiScaleObj = Instance.new("UIScale")
uiScaleObj.Name = "UIScale"
uiScaleObj.Scale = Config.UIScale
uiScaleObj.Parent = Discord

function AYXDiscordUILibrary:Window(text)
    local currentservertoggled = ""
    local minimized = false
    local fs = false
    local settingsopened = false
    
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
    MainFrame.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(0, math.floor(681 * Config.UIScale), 0, math.floor(396 * Config.UIScale))

    TopFrame.Name = "TopFrame"
    TopFrame.Parent = MainFrame
    TopFrame.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    TopFrame.BackgroundTransparency = 1.000
    TopFrame.BorderSizePixel = 0
    TopFrame.Position = UDim2.new(-0.000658480625, 0, 0, 0)
    TopFrame.Size = UDim2.new(0, math.floor(681 * Config.UIScale), 0, math.floor(22 * Config.UIScale))
    
    TopFrameHolder.Name = "TopFrameHolder"
    TopFrameHolder.Parent = TopFrame
    TopFrameHolder.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    TopFrameHolder.BackgroundTransparency = 1.000
    TopFrameHolder.BorderSizePixel = 0
    TopFrameHolder.Position = UDim2.new(-0.000658480625, 0, 0, 0)
    TopFrameHolder.Size = UDim2.new(0, math.floor(681 * Config.UIScale), 0, math.floor(22 * Config.UIScale))

    Title.Name = "Title"
    Title.Parent = TopFrame
    Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1.000
    Title.Position = UDim2.new(0.0102790017, 0, 0, 0)
    Title.Size = UDim2.new(0, math.floor(192 * Config.UIScale), 0, math.floor(23 * Config.UIScale))
    Title.Font = Enum.Font.Gotham
    Title.Text = text
    Title.TextColor3 = Color3.fromRGB(99, 102, 109)
    Title.TextSize = math.floor(13 * Config.UIScale)
    Title.TextXAlignment = Enum.TextXAlignment.Left

    CloseBtn.Name = "CloseBtn"
    CloseBtn.Parent = TopFrame
    CloseBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    CloseBtn.BackgroundTransparency = 0
    CloseBtn.Position = UDim2.new(0.959063113, 0, -0.0169996787, 0)
    CloseBtn.Size = UDim2.new(0, math.floor(28 * Config.UIScale), 0, math.floor(22 * Config.UIScale))
    CloseBtn.Font = Enum.Font.Gotham
    CloseBtn.Text = ""
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = math.floor(14 * Config.UIScale)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.AutoButtonColor = false

    CloseIcon.Name = "CloseIcon"
    CloseIcon.Parent = CloseBtn
    CloseIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CloseIcon.BackgroundTransparency = 1.000
    CloseIcon.Position = UDim2.new(0.189182192, 0, 0.128935531, 0)
    CloseIcon.Size = UDim2.new(0, math.floor(17 * Config.UIScale), 0, math.floor(17 * Config.UIScale))
    CloseIcon.Image = "http://www.roblox.com/asset/?id=6035047409"
    CloseIcon.ImageColor3 = Color3.fromRGB(220, 221, 222)

    MinimizeBtn.Name = "MinimizeButton"
    MinimizeBtn.Parent = TopFrame
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    MinimizeBtn.BackgroundTransparency = 0
    MinimizeBtn.Position = UDim2.new(0.917947114, 0, -0.0169996787, 0)
    MinimizeBtn.Size = UDim2.new(0, math.floor(28 * Config.UIScale), 0, math.floor(22 * Config.UIScale))
    MinimizeBtn.Font = Enum.Font.Gotham
    MinimizeBtn.Text = ""
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = math.floor(14 * Config.UIScale)
    MinimizeBtn.BorderSizePixel = 0
    MinimizeBtn.AutoButtonColor = false

    MinimizeIcon.Name = "MinimizeLabel"
    MinimizeIcon.Parent = MinimizeBtn
    MinimizeIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeIcon.BackgroundTransparency = 1.000
    MinimizeIcon.Position = UDim2.new(0.189182192, 0, 0.128935531, 0)
    MinimizeIcon.Size = UDim2.new(0, math.floor(17 * Config.UIScale), 0, math.floor(17 * Config.UIScale))
    MinimizeIcon.Image = "http://www.roblox.com/asset/?id=6035067836"
    MinimizeIcon.ImageColor3 = Color3.fromRGB(220, 221, 222)

    ServersHolder.Name = "ServersHolder"
    ServersHolder.Parent = TopFrameHolder

    Userpad.Name = "Userpad"
    Userpad.Parent = TopFrameHolder
    Userpad.BackgroundColor3 = Color3.fromRGB(41, 43, 47)
    Userpad.BorderSizePixel = 0
    Userpad.Position = UDim2.new(0.106243297, 0, math.floor(15.98 * Config.UIScale), 0)
    Userpad.Size = UDim2.new(0, math.floor(179 * Config.UIScale), 0, math.floor(43 * Config.UIScale))

    UserIcon.Name = "UserIcon"
    UserIcon.Parent = Userpad
    UserIcon.BackgroundColor3 = Color3.fromRGB(31, 33, 36)
    UserIcon.BorderSizePixel = 0
    UserIcon.Position = UDim2.new(0.0340000018, 0, 0.123999998, 0)
    UserIcon.Size = UDim2.new(0, math.floor(32 * Config.UIScale), 0, math.floor(32 * Config.UIScale))

    UserIconCorner.CornerRadius = UDim.new(1, math.floor(8 * Config.UIScale))
    UserIconCorner.Name = "UserIconCorner"
    UserIconCorner.Parent = UserIcon

    UserImage.Name = "UserImage"
    UserImage.Parent = UserIcon
    UserImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserImage.BackgroundTransparency = 1.000
    UserImage.Size = UDim2.new(0, math.floor(32 * Config.UIScale), 0, math.floor(32 * Config.UIScale))
    UserImage.Image = pfp 
    
    UserCircleImage.Name = "UserCircleImage"
    UserCircleImage.Parent = UserImage
    UserCircleImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserCircleImage.BackgroundTransparency = 1.000
    UserCircleImage.Size = UDim2.new(0, math.floor(32 * Config.UIScale), 0, math.floor(32 * Config.UIScale))
    UserCircleImage.Image = "rbxassetid://4031889928"
    UserCircleImage.ImageColor3 = Color3.fromRGB(41, 43, 47)
    
    UserName.Name = "UserName"
    UserName.Parent = Userpad
    UserName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserName.BackgroundTransparency = 1.000
    UserName.BorderSizePixel = 0
    UserName.Position = UDim2.new(0.230000004, 0, 0.115999997, 0)
    UserName.Size = UDim2.new(0, math.floor(98 * Config.UIScale), 0, math.floor(17 * Config.UIScale))
    UserName.Font = Enum.Font.GothamSemibold
    UserName.TextColor3 = Color3.fromRGB(255, 255, 255)
    UserName.TextSize = math.floor(13 * Config.UIScale)
    UserName.TextXAlignment = Enum.TextXAlignment.Left
    UserName.ClipsDescendants = true
    UserName.Text = user

    UserTag.Name = "UserTag"
    UserTag.Parent = Userpad
    UserTag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserTag.BackgroundTransparency = 1.000
    UserTag.BorderSizePixel = 0
    UserTag.Position = UDim2.new(0.230000004, 0, 0.455000013, 0)
    UserTag.Size = UDim2.new(0, math.floor(95 * Config.UIScale), 0, math.floor(17 * Config.UIScale))
    UserTag.Font = Enum.Font.Gotham
    UserTag.TextColor3 = Color3.fromRGB(255, 255, 255)
    UserTag.TextSize = math.floor(13 * Config.UIScale)
    UserTag.TextTransparency = 0.300
    UserTag.TextXAlignment = Enum.TextXAlignment.Left
    UserTag.Text = "#" .. tag

    ServersHoldFrame.Name = "ServersHoldFrame"
    ServersHoldFrame.Parent = MainFrame
    ServersHoldFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ServersHoldFrame.BackgroundTransparency = 1.000
    ServersHoldFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
    ServersHoldFrame.Size = UDim2.new(0, math.floor(71 * Config.UIScale), 0, math.floor(396 * Config.UIScale))

    ServersHold.Name = "ServersHold"
    ServersHold.Parent = ServersHoldFrame
    ServersHold.Active = true
    ServersHold.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ServersHold.BackgroundTransparency = 1.000
    ServersHold.BorderSizePixel = 0
    ServersHold.Position = UDim2.new(-0.000359333731, 0, 0.0580808073, 0)
    ServersHold.Size = UDim2.new(0, math.floor(71 * Config.UIScale), 0, math.floor(373 * Config.UIScale))
    ServersHold.ScrollBarThickness = 1
    ServersHold.ScrollBarImageTransparency = 1
    ServersHold.CanvasSize = UDim2.new(0, 0, 0, 0)

    ServersHoldLayout.Name = "ServersHoldLayout"
    ServersHoldLayout.Parent = ServersHold
    ServersHoldLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ServersHoldLayout.Padding = UDim.new(0, math.floor(7 * Config.UIScale))

    ServersHoldPadding.Name = "ServersHoldPadding"
    ServersHoldPadding.Parent = ServersHold

    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .3, true)
    end)

    CloseBtn.MouseEnter:Connect(function()
        CloseBtn.BackgroundColor3 = Color3.fromRGB(240, 71, 71)
    end)

    CloseBtn.MouseLeave:Connect(function()
        CloseBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    end)

    MinimizeBtn.MouseEnter:Connect(function()
        MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 46)
    end)

    MinimizeBtn.MouseLeave:Connect(function()
        MinimizeBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    end)

    MinimizeBtn.MouseButton1Click:Connect(function()
        if minimized == false then
            MainFrame:TweenSize(
                UDim2.new(0, math.floor(681 * Config.UIScale), 0, math.floor(22 * Config.UIScale)),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quart,
                .3,
                true
            )
        else
            MainFrame:TweenSize(
                UDim2.new(0, math.floor(681 * Config.UIScale), 0, math.floor(396 * Config.UIScale)),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quart,
                .3,
                true
            )
        end
        minimized = not minimized
    end)
    
    -- 缩放按钮
    local ZoomOutBtn = Instance.new("TextButton")
    local ZoomOutIcon = Instance.new("ImageLabel")
    local ZoomInBtn = Instance.new("TextButton")
    local ZoomInIcon = Instance.new("ImageLabel")
    
    ZoomOutBtn.Name = "ZoomOutBtn"
    ZoomOutBtn.Parent = TopFrame
    ZoomOutBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    ZoomOutBtn.BackgroundTransparency = 0
    ZoomOutBtn.Position = UDim2.new(0.876, 0, -0.0169996787, 0)
    ZoomOutBtn.Size = UDim2.new(0, math.floor(28 * Config.UIScale), 0, math.floor(22 * Config.UIScale))
    ZoomOutBtn.Font = Enum.Font.Gotham
    ZoomOutBtn.Text = ""
    ZoomOutBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ZoomOutBtn.TextSize = math.floor(14 * Config.UIScale)
    ZoomOutBtn.BorderSizePixel = 0
    ZoomOutBtn.AutoButtonColor = false
    
    ZoomOutIcon.Name = "ZoomOutIcon"
    ZoomOutIcon.Parent = ZoomOutBtn
    ZoomOutIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ZoomOutIcon.BackgroundTransparency = 1.000
    ZoomOutIcon.Position = UDim2.new(0.189182192, 0, 0.128935531, 0)
    ZoomOutIcon.Size = UDim2.new(0, math.floor(17 * Config.UIScale), 0, math.floor(17 * Config.UIScale))
    ZoomOutIcon.Image = "http://www.roblox.com/asset/?id=6035067836"
    ZoomOutIcon.ImageColor3 = Color3.fromRGB(220, 221, 222)
    
    ZoomInBtn.Name = "ZoomInBtn"
    ZoomInBtn.Parent = TopFrame
    ZoomInBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    ZoomInBtn.BackgroundTransparency = 0
    ZoomInBtn.Position = UDim2.new(0.835, 0, -0.0169996787, 0)
    ZoomInBtn.Size = UDim2.new(0, math.floor(28 * Config.UIScale), 0, math.floor(22 * Config.UIScale))
    ZoomInBtn.Font = Enum.Font.Gotham
    ZoomInBtn.Text = ""
    ZoomInBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ZoomInBtn.TextSize = math.floor(14 * Config.UIScale)
    ZoomInBtn.BorderSizePixel = 0
    ZoomInBtn.AutoButtonColor = false
    
    ZoomInIcon.Name = "ZoomInIcon"
    ZoomInIcon.Parent = ZoomInBtn
    ZoomInIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ZoomInIcon.BackgroundTransparency = 1.000
    ZoomInIcon.Position = UDim2.new(0.189182192, 0, 0.128935531, 0)
    ZoomInIcon.Size = UDim2.new(0, math.floor(17 * Config.UIScale), 0, math.floor(17 * Config.UIScale))
    ZoomInIcon.Image = "http://www.roblox.com/asset/?id=6034407084"
    ZoomInIcon.ImageColor3 = Color3.fromRGB(220, 221, 222)
    
    ZoomOutBtn.MouseEnter:Connect(function()
        ZoomOutBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 46)
    end)
    ZoomOutBtn.MouseLeave:Connect(function()
        ZoomOutBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    end)
    ZoomOutBtn.MouseButton1Click:Connect(function()
        local newScale = math.max(0.5, Config.UIScale - 0.05)
        Config.UIScale = newScale
        uiScaleObj.Scale = newScale
        MainFrame.Size = UDim2.new(0, math.floor(681 * newScale), 0, math.floor(396 * newScale))
    end)
    
    ZoomInBtn.MouseEnter:Connect(function()
        ZoomInBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 46)
    end)
    ZoomInBtn.MouseLeave:Connect(function()
        ZoomInBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    end)
    ZoomInBtn.MouseButton1Click:Connect(function()
        local newScale = math.min(1.2, Config.UIScale + 0.05)
        Config.UIScale = newScale
        uiScaleObj.Scale = newScale
        MainFrame.Size = UDim2.new(0, math.floor(681 * newScale), 0, math.floor(396 * newScale))
    end)
    
    local SettingsOpenBtn = Instance.new("TextButton")
    local SettingsOpenBtnIco = Instance.new("ImageLabel")
    
    SettingsOpenBtn.Name = "SettingsOpenBtn"
    SettingsOpenBtn.Parent = Userpad
    SettingsOpenBtn.BackgroundColor3 = Color3.fromRGB(53, 56, 62)
    SettingsOpenBtn.BackgroundTransparency = 1.000
    SettingsOpenBtn.Position = UDim2.new(0.849161983, 0, 0.279069781, 0)
    SettingsOpenBtn.Size = UDim2.new(0, math.floor(18 * Config.UIScale), 0, math.floor(18 * Config.UIScale))
    SettingsOpenBtn.Font = Enum.Font.SourceSans
    SettingsOpenBtn.Text = ""
    SettingsOpenBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    SettingsOpenBtn.TextSize = math.floor(14 * Config.UIScale)

    SettingsOpenBtnIco.Name = "SettingsOpenBtnIco"
    SettingsOpenBtnIco.Parent = SettingsOpenBtn
    SettingsOpenBtnIco.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    SettingsOpenBtnIco.BackgroundTransparency = 1.000
    SettingsOpenBtnIco.Size = UDim2.new(0, math.floor(18 * Config.UIScale), 0, math.floor(18 * Config.UIScale))
    SettingsOpenBtnIco.Image = "http://www.roblox.com/asset/?id=6031280882"
    SettingsOpenBtnIco.ImageColor3 = Color3.fromRGB(220, 220, 220)
    
    local SettingsFrame = Instance.new("Frame")
    local Settings = Instance.new("Frame")
    local SettingsHolder = Instance.new("Frame")
    local CloseSettingsBtn = Instance.new("TextButton")
    local CloseSettingsBtnCorner = Instance.new("UICorner")
    local CloseSettingsBtnCircle = Instance.new("Frame")
    local CloseSettingsBtnCircleCorner = Instance.new("UICorner")
    local CloseSettingsBtnIcon = Instance.new("ImageLabel")
    local TextLabel = Instance.new("TextLabel")
    local UserPanel = Instance.new("Frame")
    local UserSettingsPad = Instance.new("Frame")
    local UserSettingsPadCorner = Instance.new("UICorner")
    local UsernameText = Instance.new("TextLabel")
    local UserSettingsPadUserTag = Instance.new("Frame")
    local UserSettingsPadUser = Instance.new("TextLabel")
    local UserSettingsPadUserTagLayout = Instance.new("UIListLayout")
    local UserSettingsPadTag = Instance.new("TextLabel")
    local EditBtn = Instance.new("TextButton")
    local EditBtnCorner = Instance.new("UICorner")
    local UserPanelUserIcon = Instance.new("TextButton")
    local UserPanelUserImage = Instance.new("ImageLabel")
    local UserPanelUserCircle = Instance.new("ImageLabel")
    local BlackFrame = Instance.new("Frame")
    local BlackFrameCorner = Instance.new("UICorner")
    local ChangeAvatarText = Instance.new("TextLabel")
    local SearchIcoFrame = Instance.new("Frame")
    local SearchIcoFrameCorner = Instance.new("UICorner")
    local SearchIco = Instance.new("ImageLabel")
    local UserPanelUserTag = Instance.new("Frame")
    local UserPanelUser = Instance.new("TextLabel")
    local UserPanelUserTagLayout = Instance.new("UIListLayout")
    local UserPanelTag = Instance.new("TextLabel")
    local UserPanelCorner = Instance.new("UICorner")
    local LeftFrame = Instance.new("Frame")
    local MyAccountBtn = Instance.new("TextButton")
    local MyAccountBtnCorner = Instance.new("UICorner")
    local MyAccountBtnTitle = Instance.new("TextLabel")
    local SettingsTitle = Instance.new("TextLabel")
    local DiscordInfo = Instance.new("TextLabel")
    local CurrentSettingOpen = Instance.new("TextLabel")

    SettingsFrame.Name = "SettingsFrame"
    SettingsFrame.Parent = MainFrame
    SettingsFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
    SettingsFrame.BackgroundTransparency = 1.000
    SettingsFrame.Size = UDim2.new(0, math.floor(681 * Config.UIScale), 0, math.floor(396 * Config.UIScale))
    SettingsFrame.Visible = false

    Settings.Name = "Settings"
    Settings.Parent = SettingsFrame
    Settings.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
    Settings.BorderSizePixel = 0
    Settings.Position = UDim2.new(0, 0, 0.0530303046, 0)
    Settings.Size = UDim2.new(0, math.floor(681 * Config.UIScale), 0, math.floor(375 * Config.UIScale))

    SettingsHolder.Name = "SettingsHolder"
    SettingsHolder.Parent = Settings
    SettingsHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    SettingsHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SettingsHolder.BackgroundTransparency = 1.000
    SettingsHolder.ClipsDescendants = true
    SettingsHolder.Position = UDim2.new(0.49926579, 0, 0.498666674, 0)
    SettingsHolder.Size = UDim2.new(0, 0, 0, 0)

    CloseSettingsBtn.Name = "CloseSettingsBtn"
    CloseSettingsBtn.Parent = SettingsHolder
    CloseSettingsBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseSettingsBtn.BackgroundColor3 = Color3.fromRGB(113, 117, 123)
    CloseSettingsBtn.Position = UDim2.new(0.952967286, 0, 0.0853333324, 0)
    CloseSettingsBtn.Selectable = false
    CloseSettingsBtn.Size = UDim2.new(0, math.floor(30 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
    CloseSettingsBtn.AutoButtonColor = false
    CloseSettingsBtn.Font = Enum.Font.SourceSans
    CloseSettingsBtn.Text = ""
    CloseSettingsBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    CloseSettingsBtn.TextSize = math.floor(14 * Config.UIScale)

    CloseSettingsBtnCorner.CornerRadius = UDim.new(1, 0)
    CloseSettingsBtnCorner.Name = "CloseSettingsBtnCorner"
    CloseSettingsBtnCorner.Parent = CloseSettingsBtn

    CloseSettingsBtnCircle.Name = "CloseSettingsBtnCircle"
    CloseSettingsBtnCircle.Parent = CloseSettingsBtn
    CloseSettingsBtnCircle.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
    CloseSettingsBtnCircle.Position = UDim2.new(0.0879999995, 0, 0.118000001, 0)
    CloseSettingsBtnCircle.Size = UDim2.new(0, math.floor(24 * Config.UIScale), 0, math.floor(24 * Config.UIScale))

    CloseSettingsBtnCircleCorner.CornerRadius = UDim.new(1, 0)
    CloseSettingsBtnCircleCorner.Name = "CloseSettingsBtnCircleCorner"
    CloseSettingsBtnCircleCorner.Parent = CloseSettingsBtnCircle

    CloseSettingsBtnIcon.Name = "CloseSettingsBtnIcon"
    CloseSettingsBtnIcon.Parent = CloseSettingsBtnCircle
    CloseSettingsBtnIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CloseSettingsBtnIcon.BackgroundTransparency = 1.000
    CloseSettingsBtnIcon.Position = UDim2.new(0, math.floor(2 * Config.UIScale), 0, math.floor(2 * Config.UIScale))
    CloseSettingsBtnIcon.Size = UDim2.new(0, math.floor(19 * Config.UIScale), 0, math.floor(19 * Config.UIScale))
    CloseSettingsBtnIcon.Image = "http://www.roblox.com/asset/?id=6035047409"
    CloseSettingsBtnIcon.ImageColor3 = Color3.fromRGB(222, 222, 222)
    
    CloseSettingsBtn.MouseButton1Click:Connect(function()
        settingsopened = false
        TopFrameHolder.Visible = true
        ServersHoldFrame.Visible = true
        SettingsHolder:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .3, true)
        TweenService:Create(
            Settings,
            TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        ):Play()
        for i,v in next, SettingsHolder:GetChildren() do
            TweenService:Create(
                v,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
        end
        wait(.3)
        SettingsFrame.Visible = false
    end)
    
    CloseSettingsBtn.MouseEnter:Connect(function()
        CloseSettingsBtnCircle.BackgroundColor3 = Color3.fromRGB(72,76,82)
    end)

    CloseSettingsBtn.MouseLeave:Connect(function()
        CloseSettingsBtnCircle.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
    end)
    
    UserInputService.InputBegan:Connect(
        function(io, p)
            if io.KeyCode == Enum.KeyCode.RightControl then
                if settingsopened == true then
                    settingsopened = false
                    TopFrameHolder.Visible = true
                    ServersHoldFrame.Visible = true
                    SettingsHolder:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .3, true)
                    TweenService:Create(
                        Settings,
                        TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {BackgroundTransparency = 1}
                    ):Play()
                    for i,v in next, SettingsHolder:GetChildren() do
                        TweenService:Create(
                            v,
                            TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {BackgroundTransparency = 1}
                        ):Play()
                    end
                    wait(.3)
                    SettingsFrame.Visible = false
                end
            end
        end
    )

    TextLabel.Parent = CloseSettingsBtn
    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.BackgroundTransparency = 1.000
    TextLabel.Position = UDim2.new(-0.0666666701, 0, 1.06666672, 0)
    TextLabel.Size = UDim2.new(0, math.floor(34 * Config.UIScale), 0, math.floor(22 * Config.UIScale))
    TextLabel.Font = Enum.Font.GothamSemibold
    TextLabel.Text = "RightCtrl"
    TextLabel.TextColor3 = Color3.fromRGB(113, 117, 123)
    TextLabel.TextSize = math.floor(11 * Config.UIScale)

    UserPanel.Name = "UserPanel"
    UserPanel.Parent = SettingsHolder
    UserPanel.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
    UserPanel.Position = UDim2.new(0.365638763, 0, 0.130666673, 0)
    UserPanel.Size = UDim2.new(0, math.floor(362 * Config.UIScale), 0, math.floor(164 * Config.UIScale))

    UserSettingsPad.Name = "UserSettingsPad"
    UserSettingsPad.Parent = UserPanel
    UserSettingsPad.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
    UserSettingsPad.Position = UDim2.new(0.0331491716, 0, 0.568140388, 0)
    UserSettingsPad.Size = UDim2.new(0, math.floor(337 * Config.UIScale), 0, math.floor(56 * Config.UIScale))

    UserSettingsPadCorner.Name = "UserSettingsPadCorner"
    UserSettingsPadCorner.Parent = UserSettingsPad

    UsernameText.Name = "UsernameText"
    UsernameText.Parent = UserSettingsPad
    UsernameText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UsernameText.BackgroundTransparency = 1.000
    UsernameText.Position = UDim2.new(0.0419999994, 0, 0.154714286, 0)
    UsernameText.Size = UDim2.new(0, math.floor(65 * Config.UIScale), 0, math.floor(19 * Config.UIScale))
    UsernameText.Font = Enum.Font.GothamBold
    UsernameText.Text = "USERNAME"
    UsernameText.TextColor3 = Color3.fromRGB(126, 130, 136)
    UsernameText.TextSize = math.floor(11 * Config.UIScale)
    UsernameText.TextXAlignment = Enum.TextXAlignment.Left

    UserSettingsPadUserTag.Name = "UserSettingsPadUserTag"
    UserSettingsPadUserTag.Parent = UserSettingsPad
    UserSettingsPadUserTag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserSettingsPadUserTag.BackgroundTransparency = 1.000
    UserSettingsPadUserTag.Position = UDim2.new(0.0419999994, 0, 0.493999988, 0)
    UserSettingsPadUserTag.Size = UDim2.new(0, math.floor(65 * Config.UIScale), 0, math.floor(19 * Config.UIScale))

    UserSettingsPadUser.Name = "UserSettingsPadUser"
    UserSettingsPadUser.Parent = UserSettingsPadUserTag
    UserSettingsPadUser.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserSettingsPadUser.BackgroundTransparency = 1.000
    UserSettingsPadUser.Font = Enum.Font.Gotham
    UserSettingsPadUser.TextColor3 = Color3.fromRGB(255, 255, 255)
    UserSettingsPadUser.TextSize = math.floor(13 * Config.UIScale)
    UserSettingsPadUser.TextXAlignment = Enum.TextXAlignment.Left
    UserSettingsPadUser.Text = user
    UserSettingsPadUser.Size = UDim2.new(0, UserSettingsPadUser.TextBounds.X + math.floor(2 * Config.UIScale), 0, math.floor(19 * Config.UIScale))

    UserSettingsPadUserTagLayout.Name = "UserSettingsPadUserTagLayout"
    UserSettingsPadUserTagLayout.Parent = UserSettingsPadUserTag
    UserSettingsPadUserTagLayout.FillDirection = Enum.FillDirection.Horizontal
    UserSettingsPadUserTagLayout.SortOrder = Enum.SortOrder.LayoutOrder

    UserSettingsPadTag.Name = "UserSettingsPadTag"
    UserSettingsPadTag.Parent = UserSettingsPadUserTag
    UserSettingsPadTag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserSettingsPadTag.BackgroundTransparency = 1.000
    UserSettingsPadTag.Position = UDim2.new(0.0419999994, 0, 0.493999988, 0)
    UserSettingsPadTag.Size = UDim2.new(0, math.floor(65 * Config.UIScale), 0, math.floor(19 * Config.UIScale))
    UserSettingsPadTag.Font = Enum.Font.Gotham
    UserSettingsPadTag.Text = "#" .. tag
    UserSettingsPadTag.TextColor3 = Color3.fromRGB(184, 186, 189)
    UserSettingsPadTag.TextSize = math.floor(13 * Config.UIScale)
    UserSettingsPadTag.TextXAlignment = Enum.TextXAlignment.Left

    EditBtn.Name = "EditBtn"
    EditBtn.Parent = UserSettingsPad
    EditBtn.BackgroundColor3 = Color3.fromRGB(116, 127, 141)
    EditBtn.Position = UDim2.new(0.797671914, 0, 0.232142866, 0)
    EditBtn.Size = UDim2.new(0, math.floor(55 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
    EditBtn.Font = Enum.Font.Gotham
    EditBtn.Text = "Edit"
    EditBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    EditBtn.TextSize = math.floor(14 * Config.UIScale)
    EditBtn.AutoButtonColor = false
    
    EditBtn.MouseEnter:Connect(function()
        TweenService:Create(
            EditBtn,
            TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.fromRGB(104,114,127)}
        ):Play()
    end)
    
    EditBtn.MouseLeave:Connect(function()
        TweenService:Create(
            EditBtn,
            TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.fromRGB(116, 127, 141)}
        ):Play()
    end)

    EditBtnCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
    EditBtnCorner.Name = "EditBtnCorner"
    EditBtnCorner.Parent = EditBtn

    UserPanelUserIcon.Name = "UserPanelUserIcon"
    UserPanelUserIcon.Parent = UserPanel
    UserPanelUserIcon.BackgroundColor3 = Color3.fromRGB(31, 33, 36)
    UserPanelUserIcon.BorderSizePixel = 0
    UserPanelUserIcon.Position = UDim2.new(0.0340000018, 0, 0.074000001, 0)
    UserPanelUserIcon.Size = UDim2.new(0, math.floor(71 * Config.UIScale), 0, math.floor(71 * Config.UIScale))
    UserPanelUserIcon.AutoButtonColor = false
    UserPanelUserIcon.Text = ""

    UserPanelUserImage.Name = "UserPanelUserImage"
    UserPanelUserImage.Parent = UserPanelUserIcon
    UserPanelUserImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserPanelUserImage.BackgroundTransparency = 1.000
    UserPanelUserImage.Size = UDim2.new(0, math.floor(71 * Config.UIScale), 0, math.floor(71 * Config.UIScale))
    UserPanelUserImage.Image = pfp

    UserPanelUserCircle.Name = "UserPanelUserCircle"
    UserPanelUserCircle.Parent = UserPanelUserImage
    UserPanelUserCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserPanelUserCircle.BackgroundTransparency = 1.000
    UserPanelUserCircle.Size = UDim2.new(0, math.floor(71 * Config.UIScale), 0, math.floor(71 * Config.UIScale))
    UserPanelUserCircle.Image = "rbxassetid://4031889928"
    UserPanelUserCircle.ImageColor3 = Color3.fromRGB(47, 49, 54)

    BlackFrame.Name = "BlackFrame"
    BlackFrame.Parent = UserPanelUserIcon
    BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BlackFrame.BackgroundTransparency = 0.400
    BlackFrame.BorderSizePixel = 0
    BlackFrame.Size = UDim2.new(0, math.floor(71 * Config.UIScale), 0, math.floor(71 * Config.UIScale))
    BlackFrame.Visible = false

    BlackFrameCorner.CornerRadius = UDim.new(1, math.floor(8 * Config.UIScale))
    BlackFrameCorner.Name = "BlackFrameCorner"
    BlackFrameCorner.Parent = BlackFrame

    ChangeAvatarText.Name = "ChangeAvatarText"
    ChangeAvatarText.Parent = BlackFrame
    ChangeAvatarText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ChangeAvatarText.BackgroundTransparency = 1.000
    ChangeAvatarText.Size = UDim2.new(0, math.floor(71 * Config.UIScale), 0, math.floor(71 * Config.UIScale))
    ChangeAvatarText.Font = Enum.Font.GothamBold
    ChangeAvatarText.Text = "CHANGE AVATAR"
    ChangeAvatarText.TextColor3 = Color3.fromRGB(255, 255, 255)
    ChangeAvatarText.TextSize = math.floor(11 * Config.UIScale)
    ChangeAvatarText.TextWrapped = true

    SearchIcoFrame.Name = "SearchIcoFrame"
    SearchIcoFrame.Parent = UserPanelUserIcon
    SearchIcoFrame.BackgroundColor3 = Color3.fromRGB(222, 222, 222)
    SearchIcoFrame.Position = UDim2.new(0.657999992, 0, 0, 0)
    SearchIcoFrame.Size = UDim2.new(0, math.floor(20 * Config.UIScale), 0, math.floor(20 * Config.UIScale))

    SearchIcoFrameCorner.CornerRadius = UDim.new(1, math.floor(8 * Config.UIScale))
    SearchIcoFrameCorner.Name = "SearchIcoFrameCorner"
    SearchIcoFrameCorner.Parent = SearchIcoFrame

    SearchIco.Name = "SearchIco"
    SearchIco.Parent = SearchIcoFrame
    SearchIco.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SearchIco.BackgroundTransparency = 1.000
    SearchIco.Position = UDim2.new(0.150000006, 0, 0.100000001, 0)
    SearchIco.Size = UDim2.new(0, math.floor(15 * Config.UIScale), 0, math.floor(15 * Config.UIScale))
    SearchIco.Image = "http://www.roblox.com/asset/?id=6034407084"
    SearchIco.ImageColor3 = Color3.fromRGB(114, 118, 125)
    
    UserPanelUserIcon.MouseEnter:Connect(function()
        BlackFrame.Visible = true
    end)
    
    UserPanelUserIcon.MouseLeave:Connect(function()
        BlackFrame.Visible = false
    end)
    
    UserPanelUserIcon.MouseButton1Click:Connect(function()
        local NotificationHolder = Instance.new("TextButton")
        NotificationHolder.Name = "NotificationHolder"
        NotificationHolder.Parent = SettingsHolder
        NotificationHolder.BackgroundColor3 = Color3.fromRGB(22,22,22)
        NotificationHolder.Position = UDim2.new(-0.00881057233, 0, -0.00266666664, 0)
        NotificationHolder.Size = UDim2.new(0, math.floor(687 * Config.UIScale), 0, math.floor(375 * Config.UIScale))
        NotificationHolder.AutoButtonColor = false
        NotificationHolder.Font = Enum.Font.SourceSans
        NotificationHolder.Text = ""
        NotificationHolder.TextColor3 = Color3.fromRGB(0, 0, 0)
        NotificationHolder.TextSize = math.floor(14 * Config.UIScale)
        NotificationHolder.BackgroundTransparency = 1
        NotificationHolder.Visible = true
        TweenService:Create(
            NotificationHolder,
            TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.2}
        ):Play()

        local AvatarChange = Instance.new("Frame")
        local UserChangeCorner = Instance.new("UICorner")
        local UnderBar = Instance.new("Frame")
        local UnderBarCorner = Instance.new("UICorner")
        local UnderBarFrame = Instance.new("Frame")
        local Text1 = Instance.new("TextLabel")
        local Text2 = Instance.new("TextLabel")
        local TextBoxFrame = Instance.new("Frame")
        local TextBoxFrameCorner = Instance.new("UICorner")
        local TextBoxFrame1 = Instance.new("Frame")
        local TextBoxFrame1Corner = Instance.new("UICorner")
        local AvatarTextbox = Instance.new("TextBox")
        local ChangeBtn = Instance.new("TextButton")
        local ChangeCorner = Instance.new("UICorner")
        local CloseBtn2 = Instance.new("TextButton")
        local Close2Icon = Instance.new("ImageLabel")
        local CloseBtn1 = Instance.new("TextButton")
        local CloseBtn1Corner = Instance.new("UICorner")
        local ResetBtn = Instance.new("TextButton")
        local ResetCorner = Instance.new("UICorner")

        AvatarChange.Name = "AvatarChange"
        AvatarChange.Parent = NotificationHolder
        AvatarChange.AnchorPoint = Vector2.new(0.5, 0.5)
        AvatarChange.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
        AvatarChange.ClipsDescendants = true
        AvatarChange.Position = UDim2.new(0.513071597, 0, 0.4746176, 0)
        AvatarChange.Size = UDim2.new(0, 0, 0, 0)
        AvatarChange.BackgroundTransparency = 1
        
        AvatarChange:TweenSize(UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(198 * Config.UIScale)), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .2, true)
        TweenService:Create(
            AvatarChange,
            TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0}
        ):Play()

        UserChangeCorner.CornerRadius = UDim.new(0, math.floor(5 * Config.UIScale))
        UserChangeCorner.Name = "UserChangeCorner"
        UserChangeCorner.Parent = AvatarChange

        UnderBar.Name = "UnderBar"
        UnderBar.Parent = AvatarChange
        UnderBar.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        UnderBar.Position = UDim2.new(-0.000297061284, 0, 0.945048928, 0)
        UnderBar.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(13 * Config.UIScale))

        UnderBarCorner.CornerRadius = UDim.new(0, math.floor(5 * Config.UIScale))
        UnderBarCorner.Name = "UnderBarCorner"
        UnderBarCorner.Parent = UnderBar

        UnderBarFrame.Name = "UnderBarFrame"
        UnderBarFrame.Parent = UnderBar
        UnderBarFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        UnderBarFrame.BorderSizePixel = 0
        UnderBarFrame.Position = UDim2.new(-0.000297061284, 0, -2.53846145, 0)
        UnderBarFrame.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(39 * Config.UIScale))

        Text1.Name = "Text1"
        Text1.Parent = AvatarChange
        Text1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Text1.BackgroundTransparency = 1.000
        Text1.Position = UDim2.new(-0.000594122568, 0, 0.0202020202, 0)
        Text1.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(68 * Config.UIScale))
        Text1.Font = Enum.Font.GothamSemibold
        Text1.Text = "Change Avatar"
        Text1.TextColor3 = Color3.fromRGB(255, 255, 255)
        Text1.TextSize = math.floor(20 * Config.UIScale)

        Text2.Name = "Text2"
        Text2.Parent = AvatarChange
        Text2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Text2.BackgroundTransparency = 1.000
        Text2.Position = UDim2.new(-0.000594122568, 0, 0.141587839, 0)
        Text2.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(63 * Config.UIScale))
        Text2.Font = Enum.Font.Gotham
        Text2.Text = "Enter your new profile picture URL"
        Text2.TextColor3 = Color3.fromRGB(171, 172, 176)
        Text2.TextSize = math.floor(14 * Config.UIScale)

        TextBoxFrame.Name = "TextBoxFrame"
        TextBoxFrame.Parent = AvatarChange
        TextBoxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        TextBoxFrame.BackgroundColor3 = Color3.fromRGB(37, 40, 43)
        TextBoxFrame.Position = UDim2.new(0.49710983, 0, 0.560606062, 0)
        TextBoxFrame.Size = UDim2.new(0, math.floor(319 * Config.UIScale), 0, math.floor(38 * Config.UIScale))

        TextBoxFrameCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
        TextBoxFrameCorner.Name = "TextBoxFrameCorner"
        TextBoxFrameCorner.Parent = TextBoxFrame

        TextBoxFrame1.Name = "TextBoxFrame1"
        TextBoxFrame1.Parent = TextBoxFrame
        TextBoxFrame1.AnchorPoint = Vector2.new(0.5, 0.5)
        TextBoxFrame1.BackgroundColor3 = Color3.fromRGB(48, 51, 57)
        TextBoxFrame1.ClipsDescendants = true
        TextBoxFrame1.Position = UDim2.new(0.5, 0, 0.5, 0)
        TextBoxFrame1.Size = UDim2.new(0, math.floor(317 * Config.UIScale), 0, math.floor(36 * Config.UIScale))

        TextBoxFrame1Corner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
        TextBoxFrame1Corner.Name = "TextBoxFrame1Corner"
        TextBoxFrame1Corner.Parent = TextBoxFrame1

        AvatarTextbox.Name = "AvatarTextbox"
        AvatarTextbox.Parent = TextBoxFrame1
        AvatarTextbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        AvatarTextbox.BackgroundTransparency = 1.000
        AvatarTextbox.Position = UDim2.new(0.0378548913, 0, 0, 0)
        AvatarTextbox.Size = UDim2.new(0, math.floor(293 * Config.UIScale), 0, math.floor(37 * Config.UIScale))
        AvatarTextbox.Font = Enum.Font.Gotham
        AvatarTextbox.Text = ""
        AvatarTextbox.TextColor3 = Color3.fromRGB(193, 195, 197)
        AvatarTextbox.TextSize = math.floor(14 * Config.UIScale)
        AvatarTextbox.TextXAlignment = Enum.TextXAlignment.Left

        ChangeBtn.Name = "ChangeBtn"
        ChangeBtn.Parent = AvatarChange
        ChangeBtn.BackgroundColor3 = Color3.fromRGB(114, 137, 228)
        ChangeBtn.Position = UDim2.new(0.749670506, 0, 0.823232353, 0)
        ChangeBtn.Size = UDim2.new(0, math.floor(76 * Config.UIScale), 0, math.floor(27 * Config.UIScale))
        ChangeBtn.Font = Enum.Font.Gotham
        ChangeBtn.Text = "Change"
        ChangeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ChangeBtn.TextSize = math.floor(13 * Config.UIScale)
        ChangeBtn.AutoButtonColor = false

        ChangeBtn.MouseEnter:Connect(function()
            TweenService:Create(
                ChangeBtn,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(103,123,196)}
            ):Play()
        end)

        ChangeBtn.MouseLeave:Connect(function()
            TweenService:Create(
                ChangeBtn,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(114, 137, 228)}
            ):Play()
        end)

        ChangeBtn.MouseButton1Click:Connect(function()
            pfp = tostring(AvatarTextbox.Text)
            UserImage.Image = pfp 
            UserPanelUserImage.Image = pfp
            SaveInfo()

            AvatarChange:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .2, true)
            TweenService:Create(
                AvatarChange,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            TweenService:Create(
                NotificationHolder,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            wait(.2)
            NotificationHolder:Destroy()
        end)

        ChangeCorner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
        ChangeCorner.Name = "ChangeCorner"
        ChangeCorner.Parent = ChangeBtn

        CloseBtn2.Name = "CloseBtn2"
        CloseBtn2.Parent = AvatarChange
        CloseBtn2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn2.BackgroundTransparency = 1.000
        CloseBtn2.Position = UDim2.new(0.898000002, 0, 0, 0)
        CloseBtn2.Size = UDim2.new(0, math.floor(26 * Config.UIScale), 0, math.floor(26 * Config.UIScale))
        CloseBtn2.Font = Enum.Font.Gotham
        CloseBtn2.Text = ""
        CloseBtn2.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn2.TextSize = math.floor(14 * Config.UIScale)

        Close2Icon.Name = "Close2Icon"
        Close2Icon.Parent = CloseBtn2
        Close2Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Close2Icon.BackgroundTransparency = 1.000
        Close2Icon.Position = UDim2.new(-0.0384615399, 0, 0.312910825, 0)
        Close2Icon.Size = UDim2.new(0, math.floor(25 * Config.UIScale), 0, math.floor(25 * Config.UIScale))
        Close2Icon.Image = "http://www.roblox.com/asset/?id=6035047409"
        Close2Icon.ImageColor3 = Color3.fromRGB(119, 122, 127)

        CloseBtn1.Name = "CloseBtn1"
        CloseBtn1.Parent = AvatarChange
        CloseBtn1.BackgroundColor3 = Color3.fromRGB(114, 137, 228)
        CloseBtn1.BackgroundTransparency = 1.000
        CloseBtn1.Position = UDim2.new(0.495000005, 0, 0.823000014, 0)
        CloseBtn1.Size = UDim2.new(0, math.floor(76 * Config.UIScale), 0, math.floor(27 * Config.UIScale))
        CloseBtn1.Font = Enum.Font.Gotham
        CloseBtn1.Text = "Close"
        CloseBtn1.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn1.TextSize = math.floor(13 * Config.UIScale)

        CloseBtn1Corner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
        CloseBtn1Corner.Name = "CloseBtn1Corner"
        CloseBtn1Corner.Parent = CloseBtn1

        ResetBtn.Name = "ResetBtn"
        ResetBtn.Parent = AvatarChange
        ResetBtn.BackgroundColor3 = Color3.fromRGB(114, 137, 228)
        ResetBtn.BackgroundTransparency = 1.000
        ResetBtn.Position = UDim2.new(0.260895967, 0, 0.823000014, 0)
        ResetBtn.Size = UDim2.new(0, math.floor(76 * Config.UIScale), 0, math.floor(27 * Config.UIScale))
        ResetBtn.Font = Enum.Font.Gotham
        ResetBtn.Text = "Reset"
        ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ResetBtn.TextSize = math.floor(13 * Config.UIScale)
        
        ResetBtn.MouseButton1Click:Connect(function()
            pfp = "https://www.roblox.com/headshot-thumbnail/image?userId=".. game.Players.LocalPlayer.UserId .."&width=420&height=420&format=png"
            UserImage.Image = pfp 
            UserPanelUserImage.Image = pfp
            SaveInfo()

            AvatarChange:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .2, true)
            TweenService:Create(
                AvatarChange,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            TweenService:Create(
                NotificationHolder,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            wait(.2)
            NotificationHolder:Destroy()
        end)

        ResetCorner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
        ResetCorner.Name = "ResetCorner"
        ResetCorner.Parent = ResetBtn
        
        CloseBtn1.MouseButton1Click:Connect(function()
            AvatarChange:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .2, true)
            TweenService:Create(
                AvatarChange,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            TweenService:Create(
                NotificationHolder,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            wait(.2)
            NotificationHolder:Destroy()
        end)

        CloseBtn2.MouseButton1Click:Connect(function()
            AvatarChange:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .2, true)
            TweenService:Create(
                AvatarChange,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            TweenService:Create(
                NotificationHolder,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            wait(.2)
            NotificationHolder:Destroy()
        end)
        
        CloseBtn2.MouseEnter:Connect(function()
            TweenService:Create(
                Close2Icon,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {ImageColor3 = Color3.fromRGB(210,210,210)}
            ):Play()
        end)

        CloseBtn2.MouseLeave:Connect(function()
            TweenService:Create(
                Close2Icon,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {ImageColor3 = Color3.fromRGB(119, 122, 127)}
            ):Play()
        end)

        AvatarTextbox.Focused:Connect(function()
            TweenService:Create(
                TextBoxFrame,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(114, 137, 228)}
            ):Play()
        end)

        AvatarTextbox.FocusLost:Connect(function()
            TweenService:Create(
                TextBoxFrame,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(37, 40, 43)}
            ):Play()
        end)
    end)

    UserPanelUserTag.Name = "UserPanelUserTag"
    UserPanelUserTag.Parent = UserPanel
    UserPanelUserTag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserPanelUserTag.BackgroundTransparency = 1.000
    UserPanelUserTag.Position = UDim2.new(0.271143615, 0, 0.231804818, 0)
    UserPanelUserTag.Size = UDim2.new(0, math.floor(113 * Config.UIScale), 0, math.floor(19 * Config.UIScale))

    UserPanelUser.Name = "UserPanelUser"
    UserPanelUser.Parent = UserPanelUserTag
    UserPanelUser.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserPanelUser.BackgroundTransparency = 1.000
    UserPanelUser.Font = Enum.Font.GothamSemibold
    UserPanelUser.TextColor3 = Color3.fromRGB(255, 255, 255)
    UserPanelUser.TextSize = math.floor(17 * Config.UIScale)
    UserPanelUser.TextXAlignment = Enum.TextXAlignment.Left
    UserPanelUser.Text = user
    UserPanelUser.Size = UDim2.new(0, UserPanelUser.TextBounds.X + math.floor(2 * Config.UIScale), 0, math.floor(19 * Config.UIScale))

    UserPanelUserTagLayout.Name = "UserPanelUserTagLayout"
    UserPanelUserTagLayout.Parent = UserPanelUserTag
    UserPanelUserTagLayout.FillDirection = Enum.FillDirection.Horizontal
    UserPanelUserTagLayout.SortOrder = Enum.SortOrder.LayoutOrder

    UserPanelTag.Name = "UserPanelTag"
    UserPanelTag.Parent = UserPanelUserTag
    UserPanelTag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserPanelTag.BackgroundTransparency = 1.000
    UserPanelTag.Position = UDim2.new(0.0419999994, 0, 0.493999988, 0)
    UserPanelTag.Size = UDim2.new(0, math.floor(65 * Config.UIScale), 0, math.floor(19 * Config.UIScale))
    UserPanelTag.Font = Enum.Font.Gotham
    UserPanelTag.Text = "#" .. tag
    UserPanelTag.TextColor3 = Color3.fromRGB(184, 186, 189)
    UserPanelTag.TextSize = math.floor(17 * Config.UIScale)
    UserPanelTag.TextXAlignment = Enum.TextXAlignment.Left

    UserPanelCorner.Name = "UserPanelCorner"
    UserPanelCorner.Parent = UserPanel

    LeftFrame.Name = "LeftFrame"
    LeftFrame.Parent = SettingsHolder
    LeftFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
    LeftFrame.BorderSizePixel = 0
    LeftFrame.Position = UDim2.new(0, 0, -0.000303059904, 0)
    LeftFrame.Size = UDim2.new(0, math.floor(233 * Config.UIScale), 0, math.floor(375 * Config.UIScale))

    MyAccountBtn.Name = "MyAccountBtn"
    MyAccountBtn.Parent = LeftFrame
    MyAccountBtn.BackgroundColor3 = Color3.fromRGB(57, 60, 67)
    MyAccountBtn.BorderSizePixel = 0
    MyAccountBtn.Position = UDim2.new(0.271232396, 0, 0.101614028, 0)
    MyAccountBtn.Size = UDim2.new(0, math.floor(160 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
    MyAccountBtn.AutoButtonColor = false
    MyAccountBtn.Font = Enum.Font.SourceSans
    MyAccountBtn.Text = ""
    MyAccountBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    MyAccountBtn.TextSize = math.floor(14 * Config.UIScale)

    MyAccountBtnCorner.CornerRadius = UDim.new(0, math.floor(6 * Config.UIScale))
    MyAccountBtnCorner.Name = "MyAccountBtnCorner"
    MyAccountBtnCorner.Parent = MyAccountBtn

    MyAccountBtnTitle.Name = "MyAccountBtnTitle"
    MyAccountBtnTitle.Parent = MyAccountBtn
    MyAccountBtnTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MyAccountBtnTitle.BackgroundTransparency = 1.000
    MyAccountBtnTitle.BorderSizePixel = 0
    MyAccountBtnTitle.Position = UDim2.new(0.0759999976, 0, -0.166999996, 0)
    MyAccountBtnTitle.Size = UDim2.new(0, math.floor(95 * Config.UIScale), 0, math.floor(39 * Config.UIScale))
    MyAccountBtnTitle.Font = Enum.Font.GothamSemibold
    MyAccountBtnTitle.Text = "My Account"
    MyAccountBtnTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    MyAccountBtnTitle.TextSize = math.floor(14 * Config.UIScale)
    MyAccountBtnTitle.TextXAlignment = Enum.TextXAlignment.Left

    SettingsTitle.Name = "SettingsTitle"
    SettingsTitle.Parent = LeftFrame
    SettingsTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SettingsTitle.BackgroundTransparency = 1.000
    SettingsTitle.Position = UDim2.new(0.308999985, 0, 0.0450000018, 0)
    SettingsTitle.Size = UDim2.new(0, math.floor(65 * Config.UIScale), 0, math.floor(19 * Config.UIScale))
    SettingsTitle.Font = Enum.Font.GothamBlack
    SettingsTitle.Text = "SETTINGS"
    SettingsTitle.TextColor3 = Color3.fromRGB(142, 146, 152)
    SettingsTitle.TextSize = math.floor(11 * Config.UIScale)
    SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left

    DiscordInfo.Name = "DiscordInfo"
    DiscordInfo.Parent = LeftFrame
    DiscordInfo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DiscordInfo.BackgroundTransparency = 1.000
    DiscordInfo.Position = UDim2.new(0.304721028, 0, 0.821333349, 0)
    DiscordInfo.Size = UDim2.new(0, math.floor(133 * Config.UIScale), 0, math.floor(44 * Config.UIScale))
    DiscordInfo.Font = Enum.Font.Gotham
    DiscordInfo.Text = "AYX Discord UI Library v1.0.0                Roblox Lua Engine    "
    DiscordInfo.TextColor3 = Color3.fromRGB(101, 108, 116)
    DiscordInfo.TextSize = math.floor(13 * Config.UIScale)
    DiscordInfo.TextWrapped = true
    DiscordInfo.TextXAlignment = Enum.TextXAlignment.Left
    DiscordInfo.TextYAlignment = Enum.TextYAlignment.Top

    CurrentSettingOpen.Name = "CurrentSettingOpen"
    CurrentSettingOpen.Parent = LeftFrame
    CurrentSettingOpen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CurrentSettingOpen.BackgroundTransparency = 1.000
    CurrentSettingOpen.Position = UDim2.new(1.07294846, 0, 0.0450000018, 0)
    CurrentSettingOpen.Size = UDim2.new(0, math.floor(65 * Config.UIScale), 0, math.floor(19 * Config.UIScale))
    CurrentSettingOpen.Font = Enum.Font.GothamBlack
    CurrentSettingOpen.Text = "MY ACCOUNT"
    CurrentSettingOpen.TextColor3 = Color3.fromRGB(255, 255, 255)
    CurrentSettingOpen.TextSize = math.floor(14 * Config.UIScale)
    CurrentSettingOpen.TextXAlignment = Enum.TextXAlignment.Left

    SettingsOpenBtn.MouseButton1Click:Connect(function ()
        settingsopened = true
        TopFrameHolder.Visible = false
        ServersHoldFrame.Visible = false
        SettingsFrame.Visible = true
        SettingsHolder:TweenSize(UDim2.new(0, math.floor(681 * Config.UIScale), 0, math.floor(375 * Config.UIScale)), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .3, true)
        Settings.BackgroundTransparency = 1
        TweenService:Create(
            Settings,
            TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0}
        ):Play()
        for i,v in next, SettingsHolder:GetChildren() do
            v.BackgroundTransparency = 1
            TweenService:Create(
                v,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 0}
            ):Play()
        end
    end)
    
    EditBtn.MouseButton1Click:Connect(function()
        local NotificationHolder = Instance.new("TextButton")
        NotificationHolder.Name = "NotificationHolder"
        NotificationHolder.Parent = SettingsHolder
        NotificationHolder.BackgroundColor3 = Color3.fromRGB(22,22,22)
        NotificationHolder.Position = UDim2.new(-0.00881057233, 0, -0.00266666664, 0)
        NotificationHolder.Size = UDim2.new(0, math.floor(687 * Config.UIScale), 0, math.floor(375 * Config.UIScale))
        NotificationHolder.AutoButtonColor = false
        NotificationHolder.Font = Enum.Font.SourceSans
        NotificationHolder.Text = ""
        NotificationHolder.TextColor3 = Color3.fromRGB(0, 0, 0)
        NotificationHolder.TextSize = math.floor(14 * Config.UIScale)
        NotificationHolder.BackgroundTransparency = 1
        NotificationHolder.Visible = true
        TweenService:Create(
            NotificationHolder,
            TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.2}
        ):Play()

        local UserChange = Instance.new("Frame")
        local UserChangeCorner = Instance.new("UICorner")
        local UnderBar = Instance.new("Frame")
        local UnderBarCorner = Instance.new("UICorner")
        local UnderBarFrame = Instance.new("Frame")
        local Text1 = Instance.new("TextLabel")
        local Text2 = Instance.new("TextLabel")
        local TextBoxFrame = Instance.new("Frame")
        local TextBoxFrameCorner = Instance.new("UICorner")
        local TextBoxFrame1 = Instance.new("Frame")
        local TextBoxFrame1Corner = Instance.new("UICorner")
        local UsernameTextbox = Instance.new("TextBox")
        local Seperator = Instance.new("Frame")
        local HashtagLabel = Instance.new("TextLabel")
        local TagTextbox = Instance.new("TextBox")
        local ChangeBtn = Instance.new("TextButton")
        local ChangeCorner = Instance.new("UICorner")
        local CloseBtn2 = Instance.new("TextButton")
        local Close2Icon = Instance.new("ImageLabel")
        local CloseBtn1 = Instance.new("TextButton")
        local CloseBtn1Corner = Instance.new("UICorner")

        UserChange.Name = "UserChange"
        UserChange.Parent = NotificationHolder
        UserChange.AnchorPoint = Vector2.new(0.5, 0.5)
        UserChange.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
        UserChange.ClipsDescendants = true
        UserChange.Position = UDim2.new(0.513071597, 0, 0.4746176, 0)
        UserChange.Size = UDim2.new(0, 0, 0, 0)
        UserChange.BackgroundTransparency = 1
        
        UserChange:TweenSize(UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(198 * Config.UIScale)), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .2, true)
        TweenService:Create(
            UserChange,
            TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0}
        ):Play()
        
        UserChangeCorner.CornerRadius = UDim.new(0, math.floor(5 * Config.UIScale))
        UserChangeCorner.Name = "UserChangeCorner"
        UserChangeCorner.Parent = UserChange

        UnderBar.Name = "UnderBar"
        UnderBar.Parent = UserChange
        UnderBar.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        UnderBar.Position = UDim2.new(-0.000297061284, 0, 0.945048928, 0)
        UnderBar.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(13 * Config.UIScale))

        UnderBarCorner.CornerRadius = UDim.new(0, math.floor(5 * Config.UIScale))
        UnderBarCorner.Name = "UnderBarCorner"
        UnderBarCorner.Parent = UnderBar

        UnderBarFrame.Name = "UnderBarFrame"
        UnderBarFrame.Parent = UnderBar
        UnderBarFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        UnderBarFrame.BorderSizePixel = 0
        UnderBarFrame.Position = UDim2.new(-0.000297061284, 0, -2.53846145, 0)
        UnderBarFrame.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(39 * Config.UIScale))

        Text1.Name = "Text1"
        Text1.Parent = UserChange
        Text1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Text1.BackgroundTransparency = 1.000
        Text1.Position = UDim2.new(-0.000594122568, 0, 0.0202020202, 0)
        Text1.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(68 * Config.UIScale))
        Text1.Font = Enum.Font.GothamSemibold
        Text1.Text = "Change Username"
        Text1.TextColor3 = Color3.fromRGB(255, 255, 255)
        Text1.TextSize = math.floor(20 * Config.UIScale)

        Text2.Name = "Text2"
        Text2.Parent = UserChange
        Text2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Text2.BackgroundTransparency = 1.000
        Text2.Position = UDim2.new(-0.000594122568, 0, 0.141587839, 0)
        Text2.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(63 * Config.UIScale))
        Text2.Font = Enum.Font.Gotham
        Text2.Text = "Enter your new username"
        Text2.TextColor3 = Color3.fromRGB(171, 172, 176)
        Text2.TextSize = math.floor(14 * Config.UIScale)

        TextBoxFrame.Name = "TextBoxFrame"
        TextBoxFrame.Parent = UserChange
        TextBoxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        TextBoxFrame.BackgroundColor3 = Color3.fromRGB(37, 40, 43)
        TextBoxFrame.Position = UDim2.new(0.49710983, 0, 0.560606062, 0)
        TextBoxFrame.Size = UDim2.new(0, math.floor(319 * Config.UIScale), 0, math.floor(38 * Config.UIScale))

        TextBoxFrameCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
        TextBoxFrameCorner.Name = "TextBoxFrameCorner"
        TextBoxFrameCorner.Parent = TextBoxFrame

        TextBoxFrame1.Name = "TextBoxFrame1"
        TextBoxFrame1.Parent = TextBoxFrame
        TextBoxFrame1.AnchorPoint = Vector2.new(0.5, 0.5)
        TextBoxFrame1.BackgroundColor3 = Color3.fromRGB(48, 51, 57)
        TextBoxFrame1.ClipsDescendants = true
        TextBoxFrame1.Position = UDim2.new(0.5, 0, 0.5, 0)
        TextBoxFrame1.Size = UDim2.new(0, math.floor(317 * Config.UIScale), 0, math.floor(36 * Config.UIScale))

        TextBoxFrame1Corner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
        TextBoxFrame1Corner.Name = "TextBoxFrame1Corner"
        TextBoxFrame1Corner.Parent = TextBoxFrame1

        UsernameTextbox.Name = "UsernameTextbox"
        UsernameTextbox.Parent = TextBoxFrame1
        UsernameTextbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        UsernameTextbox.BackgroundTransparency = 1.000
        UsernameTextbox.Position = UDim2.new(0.0378548913, 0, 0, 0)
        UsernameTextbox.Size = UDim2.new(0, math.floor(221 * Config.UIScale), 0, math.floor(37 * Config.UIScale))
        UsernameTextbox.Font = Enum.Font.Gotham
        UsernameTextbox.Text = user
        UsernameTextbox.TextColor3 = Color3.fromRGB(193, 195, 197)
        UsernameTextbox.TextSize = math.floor(14 * Config.UIScale)
        UsernameTextbox.TextXAlignment = Enum.TextXAlignment.Left

        Seperator.Name = "Seperator"
        Seperator.Parent = TextBoxFrame1
        Seperator.AnchorPoint = Vector2.new(0.5, 0.5)
        Seperator.BackgroundColor3 = Color3.fromRGB(64, 68, 73)
        Seperator.BorderSizePixel = 0
        Seperator.Position = UDim2.new(0.753000021, 0, 0.500999987, 0)
        Seperator.Size = UDim2.new(0, math.floor(1 * Config.UIScale), 0, math.floor(25 * Config.UIScale))

        HashtagLabel.Name = "HashtagLabel"
        HashtagLabel.Parent = TextBoxFrame1
        HashtagLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        HashtagLabel.BackgroundTransparency = 1.000
        HashtagLabel.Position = UDim2.new(0.765877604, 0, -0.0546001866, 0)
        HashtagLabel.Size = UDim2.new(0, math.floor(23 * Config.UIScale), 0, math.floor(37 * Config.UIScale))
        HashtagLabel.Font = Enum.Font.Gotham
        HashtagLabel.Text = "#"
        HashtagLabel.TextColor3 = Color3.fromRGB(79, 82, 88)
        HashtagLabel.TextSize = math.floor(16 * Config.UIScale)

        TagTextbox.Name = "TagTextbox"
        TagTextbox.Parent = TextBoxFrame1
        TagTextbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TagTextbox.BackgroundTransparency = 1.000
        TagTextbox.Position = UDim2.new(0.824999988, 0, -0.0280000009, 0)
        TagTextbox.Size = UDim2.new(0, math.floor(59 * Config.UIScale), 0, math.floor(38 * Config.UIScale))
        TagTextbox.Font = Enum.Font.Gotham
        TagTextbox.PlaceholderColor3 = Color3.fromRGB(210, 211, 212)
        TagTextbox.Text = tag
        TagTextbox.TextColor3 = Color3.fromRGB(193, 195, 197)
        TagTextbox.TextSize = math.floor(14 * Config.UIScale)
        TagTextbox.TextXAlignment = Enum.TextXAlignment.Left

        ChangeBtn.Name = "ChangeBtn"
        ChangeBtn.Parent = UserChange
        ChangeBtn.BackgroundColor3 = Color3.fromRGB(114, 137, 228)
        ChangeBtn.Position = UDim2.new(0.749670506, 0, 0.823232353, 0)
        ChangeBtn.Size = UDim2.new(0, math.floor(76 * Config.UIScale), 0, math.floor(27 * Config.UIScale))
        ChangeBtn.Font = Enum.Font.Gotham
        ChangeBtn.Text = "Change"
        ChangeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ChangeBtn.TextSize = math.floor(13 * Config.UIScale)
        ChangeBtn.AutoButtonColor = false
        
        ChangeBtn.MouseEnter:Connect(function()
            TweenService:Create(
                ChangeBtn,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(103,123,196)}
            ):Play()
        end)
        
        ChangeBtn.MouseLeave:Connect(function()
            TweenService:Create(
                ChangeBtn,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(114, 137, 228)}
            ):Play()
        end)
        
        ChangeBtn.MouseButton1Click:Connect(function()
            user = UsernameTextbox.Text
            tag = TagTextbox.Text
            UserSettingsPadUser.Text = user
            UserSettingsPadUser.Size = UDim2.new(0, UserSettingsPadUser.TextBounds.X + math.floor(2 * Config.UIScale), 0, math.floor(19 * Config.UIScale))
            UserSettingsPadTag.Text = "#" .. tag
            UserPanelTag.Text = "#" .. tag
            UserPanelUser.Text = user
            UserPanelUser.Size = UDim2.new(0, UserPanelUser.TextBounds.X + math.floor(2 * Config.UIScale), 0, math.floor(19 * Config.UIScale))
            UserName.Text = user
            UserTag.Text = "#" .. tag
            SaveInfo()

            UserChange:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .2, true)
            TweenService:Create(
                UserChange,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            TweenService:Create(
                NotificationHolder,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            wait(.2)
            NotificationHolder:Destroy()
        end)

        ChangeCorner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
        ChangeCorner.Name = "ChangeCorner"
        ChangeCorner.Parent = ChangeBtn

        CloseBtn2.Name = "CloseBtn2"
        CloseBtn2.Parent = UserChange
        CloseBtn2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn2.BackgroundTransparency = 1.000
        CloseBtn2.Position = UDim2.new(0.898000002, 0, 0, 0)
        CloseBtn2.Size = UDim2.new(0, math.floor(26 * Config.UIScale), 0, math.floor(26 * Config.UIScale))
        CloseBtn2.Font = Enum.Font.Gotham
        CloseBtn2.Text = ""
        CloseBtn2.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn2.TextSize = math.floor(14 * Config.UIScale)

        Close2Icon.Name = "Close2Icon"
        Close2Icon.Parent = CloseBtn2
        Close2Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Close2Icon.BackgroundTransparency = 1.000
        Close2Icon.Position = UDim2.new(-0.0384615399, 0, 0.312910825, 0)
        Close2Icon.Size = UDim2.new(0, math.floor(25 * Config.UIScale), 0, math.floor(25 * Config.UIScale))
        Close2Icon.Image = "http://www.roblox.com/asset/?id=6035047409"
        Close2Icon.ImageColor3 = Color3.fromRGB(119, 122, 127)

        CloseBtn1.Name = "CloseBtn1"
        CloseBtn1.Parent = UserChange
        CloseBtn1.BackgroundColor3 = Color3.fromRGB(114, 137, 228)
        CloseBtn1.BackgroundTransparency = 1.000
        CloseBtn1.Position = UDim2.new(0.495000005, 0, 0.823000014, 0)
        CloseBtn1.Size = UDim2.new(0, math.floor(76 * Config.UIScale), 0, math.floor(27 * Config.UIScale))
        CloseBtn1.Font = Enum.Font.Gotham
        CloseBtn1.Text = "Close"
        CloseBtn1.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn1.TextSize = math.floor(13 * Config.UIScale)

        CloseBtn1Corner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
        CloseBtn1Corner.Name = "CloseBtn1Corner"
        CloseBtn1Corner.Parent = CloseBtn1
        
        CloseBtn1.MouseButton1Click:Connect(function()
            UserChange:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .2, true)
            TweenService:Create(
                UserChange,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            TweenService:Create(
                NotificationHolder,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            wait(.2)
            NotificationHolder:Destroy()
        end)
        
        CloseBtn2.MouseButton1Click:Connect(function()
            UserChange:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .2, true)
            TweenService:Create(
                UserChange,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            TweenService:Create(
                NotificationHolder,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            wait(.2)
            NotificationHolder:Destroy()
        end)
        
        CloseBtn2.MouseEnter:Connect(function()
            TweenService:Create(
                Close2Icon,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {ImageColor3 = Color3.fromRGB(210,210,210)}
            ):Play()
        end)
        
        CloseBtn2.MouseLeave:Connect(function()
            TweenService:Create(
                Close2Icon,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {ImageColor3 = Color3.fromRGB(119, 122, 127)}
            ):Play()
        end)
        
        TagTextbox.Changed:Connect(function()
            TagTextbox.Text = TagTextbox.Text:sub(1,4)    
        end)
        
        TagTextbox:GetPropertyChangedSignal("Text"):Connect(function()
            TagTextbox.Text = TagTextbox.Text:gsub('%D+', '');
        end)
        
        UsernameTextbox.Changed:Connect(function()
            UsernameTextbox.Text = UsernameTextbox.Text:sub(1,13)    
        end)
        
        TagTextbox.Focused:Connect(function()
            TweenService:Create(
                TextBoxFrame,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(114, 137, 228)}
            ):Play()
        end)
        
        TagTextbox.FocusLost:Connect(function()
            TweenService:Create(
                TextBoxFrame,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(37, 40, 43)}
            ):Play()
        end)
        
        UsernameTextbox.Focused:Connect(function()
            TweenService:Create(
                TextBoxFrame,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(114, 137, 228)}
            ):Play()
        end)

        UsernameTextbox.FocusLost:Connect(function()
            TweenService:Create(
                TextBoxFrame,
                TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(37, 40, 43)}
            ):Play()
        end)
    end)
    
    function AYXDiscordUILibrary:Notification(titletext, desctext, btntext)
        local NotificationHolderMain = Instance.new("TextButton")
        local Notification = Instance.new("Frame")
        local NotificationCorner = Instance.new("UICorner")
        local UnderBar = Instance.new("Frame")
        local UnderBarCorner = Instance.new("UICorner")
        local UnderBarFrame = Instance.new("Frame")
        local Text1 = Instance.new("TextLabel")
        local Text2 = Instance.new("TextLabel")
        local AlrightBtn = Instance.new("TextButton")
        local AlrightCorner = Instance.new("UICorner")

        NotificationHolderMain.Name = "NotificationHolderMain"
        NotificationHolderMain.Parent = MainFrame
        NotificationHolderMain.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        NotificationHolderMain.BackgroundTransparency = 1
        NotificationHolderMain.BorderSizePixel = 0
        NotificationHolderMain.Position = UDim2.new(0, 0, 0.0560000017, 0)
        NotificationHolderMain.Size = UDim2.new(0, math.floor(681 * Config.UIScale), 0, math.floor(374 * Config.UIScale))
        NotificationHolderMain.AutoButtonColor = false
        NotificationHolderMain.Font = Enum.Font.SourceSans
        NotificationHolderMain.Text = ""
        NotificationHolderMain.TextColor3 = Color3.fromRGB(0, 0, 0)
        NotificationHolderMain.TextSize = math.floor(14 * Config.UIScale)
        TweenService:Create(
            NotificationHolderMain,
            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.2}
        ):Play()
        
        PlaySound("Notification")

        Notification.Name = "Notification"
        Notification.Parent = NotificationHolderMain
        Notification.AnchorPoint = Vector2.new(0.5, 0.5)
        Notification.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
        Notification.ClipsDescendants = true
        Notification.Position = UDim2.new(0.524819076, 0, 0.469270051, 0)
        Notification.Size = UDim2.new(0, 0, 0, 0)
        Notification.BackgroundTransparency = 1
        
        Notification:TweenSize(UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(176 * Config.UIScale)), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, Config.AnimationSpeed, true)
        
        TweenService:Create(
            Notification,
            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0}
        ):Play()
        
        if Config.EnableGlow then
            CreateGlow(Notification, Config.AccentColor)
        end

        NotificationCorner.CornerRadius = UDim.new(0, math.floor(5 * Config.UIScale))
        NotificationCorner.Name = "NotificationCorner"
        NotificationCorner.Parent = Notification

        UnderBar.Name = "UnderBar"
        UnderBar.Parent = Notification
        UnderBar.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        UnderBar.Position = UDim2.new(-0.000297061284, 0, 0.945048928, 0)
        UnderBar.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(10 * Config.UIScale))

        UnderBarCorner.CornerRadius = UDim.new(0, math.floor(5 * Config.UIScale))
        UnderBarCorner.Name = "UnderBarCorner"
        UnderBarCorner.Parent = UnderBar

        UnderBarFrame.Name = "UnderBarFrame"
        UnderBarFrame.Parent = UnderBar
        UnderBarFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        UnderBarFrame.BorderSizePixel = 0
        UnderBarFrame.Position = UDim2.new(-0.000297061284, 0, -3.76068449, 0)
        UnderBarFrame.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(40 * Config.UIScale))

        Text1.Name = "Text1"
        Text1.Parent = Notification
        Text1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Text1.BackgroundTransparency = 1.000
        Text1.Position = UDim2.new(-0.000594122568, 0, 0.0202020202, 0)
        Text1.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(68 * Config.UIScale))
        Text1.Font = Enum.Font.GothamSemibold
        Text1.Text = titletext
        Text1.TextColor3 = Color3.fromRGB(255, 255, 255)
        Text1.TextSize = math.floor(20 * Config.UIScale)

        Text2.Name = "Text2"
        Text2.Parent = Notification
        Text2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Text2.BackgroundTransparency = 1.000
        Text2.Position = UDim2.new(0.106342293, 0, 0.317724228, 0)
        Text2.Size = UDim2.new(0, math.floor(272 * Config.UIScale), 0, math.floor(63 * Config.UIScale))
        Text2.Font = Enum.Font.Gotham
        Text2.Text = desctext
        Text2.TextColor3 = Color3.fromRGB(171, 172, 176)
        Text2.TextSize = math.floor(14 * Config.UIScale)
        Text2.TextWrapped = true

        AlrightBtn.Name = "AlrightBtn"
        AlrightBtn.Parent = Notification
        AlrightBtn.BackgroundColor3 = Color3.fromRGB(114, 137, 228)
        AlrightBtn.Position = UDim2.new(0.0332369953, 0, 0.789141417, 0)
        AlrightBtn.Size = UDim2.new(0, math.floor(322 * Config.UIScale), 0, math.floor(27 * Config.UIScale))
        AlrightBtn.Font = Enum.Font.Gotham
        AlrightBtn.Text = btntext
        AlrightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        AlrightBtn.TextSize = math.floor(13 * Config.UIScale)
        AlrightBtn.AutoButtonColor = false
        
        AlrightCorner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
        AlrightCorner.Name = "AlrightCorner"
        AlrightCorner.Parent = AlrightBtn
        
        AlrightBtn.MouseButton1Click:Connect(function()
            PlaySound("Click")
            TweenService:Create(
                NotificationHolderMain,
                TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            Notification:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, Config.AnimationSpeed, true)
            TweenService:Create(
                Notification,
                TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            wait(Config.AnimationSpeed)
            NotificationHolderMain:Destroy()
        end)
        
        AlrightBtn.MouseEnter:Connect(function()
            PlaySound("Hover")
            TweenService:Create(
                AlrightBtn,
                TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(103,123,196)}
            ):Play()
        end)

        AlrightBtn.MouseLeave:Connect(function()
            TweenService:Create(
                AlrightBtn,
                TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(114, 137, 228)}
            ):Play()
        end)
    end
    
    local ActiveNotifications = {}
    
    function AYXDiscordUILibrary:Notify(titletext, desctext, btntext, notifType, duration)
        notifType = notifType or "Info"
        local colors = {
            Success = Color3.fromRGB(67, 181, 129),
            Error = Color3.fromRGB(240, 71, 71),
            Warning = Color3.fromRGB(255, 193, 7),
            Info = Color3.fromRGB(114, 137, 228)
        }
        
        local NotificationHolderMain = Instance.new("TextButton")
        local Notification = Instance.new("Frame")
        local NotificationCorner = Instance.new("UICorner")
        local UnderBar = Instance.new("Frame")
        local UnderBarCorner = Instance.new("UICorner")
        local UnderBarFrame = Instance.new("Frame")
        local Text1 = Instance.new("TextLabel")
        local Text2 = Instance.new("TextLabel")
        local AlrightBtn = Instance.new("TextButton")
        local AlrightCorner = Instance.new("UICorner")
        local Icon = Instance.new("ImageLabel")

        NotificationHolderMain.Name = "NotificationHolderMain"
        NotificationHolderMain.Parent = MainFrame
        NotificationHolderMain.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        NotificationHolderMain.BackgroundTransparency = 1
        NotificationHolderMain.BorderSizePixel = 0
        NotificationHolderMain.Position = UDim2.new(0, 0, 0.0560000017, 0)
        NotificationHolderMain.Size = UDim2.new(0, math.floor(681 * Config.UIScale), 0, math.floor(374 * Config.UIScale))
        NotificationHolderMain.AutoButtonColor = false
        NotificationHolderMain.Font = Enum.Font.SourceSans
        NotificationHolderMain.Text = ""
        NotificationHolderMain.TextColor3 = Color3.fromRGB(0, 0, 0)
        NotificationHolderMain.TextSize = math.floor(14 * Config.UIScale)
        
        TweenService:Create(
            NotificationHolderMain,
            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.2}
        ):Play()
        
        PlaySound("Notification")

        Notification.Name = "Notification"
        Notification.Parent = NotificationHolderMain
        Notification.AnchorPoint = Vector2.new(0.5, 0.5)
        Notification.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
        Notification.ClipsDescendants = true
        Notification.Position = UDim2.new(0.524819076, 0, 0.469270051, 0)
        Notification.Size = UDim2.new(0, 0, 0, 0)
        Notification.BackgroundTransparency = 1
        
        Notification:TweenSize(UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(176 * Config.UIScale)), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, Config.AnimationSpeed, true)
        
        TweenService:Create(
            Notification,
            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0}
        ):Play()
        
        if Config.EnableGlow then
            CreateGlow(Notification, colors[notifType])
        end

        NotificationCorner.CornerRadius = UDim.new(0, math.floor(5 * Config.UIScale))
        NotificationCorner.Name = "NotificationCorner"
        NotificationCorner.Parent = Notification

        Icon.Name = "Icon"
        Icon.Parent = Notification
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Icon.BackgroundTransparency = 1.000
        Icon.Position = UDim2.new(0.02, 0, 0.1, 0)
        Icon.Size = UDim2.new(0, math.floor(30 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
        Icon.Image = "rbxassetid://6035047409"
        Icon.ImageColor3 = colors[notifType]

        UnderBar.Name = "UnderBar"
        UnderBar.Parent = Notification
        UnderBar.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        UnderBar.Position = UDim2.new(-0.000297061284, 0, 0.945048928, 0)
        UnderBar.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(10 * Config.UIScale))

        UnderBarCorner.CornerRadius = UDim.new(0, math.floor(5 * Config.UIScale))
        UnderBarCorner.Name = "UnderBarCorner"
        UnderBarCorner.Parent = UnderBar

        UnderBarFrame.Name = "UnderBarFrame"
        UnderBarFrame.Parent = UnderBar
        UnderBarFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        UnderBarFrame.BorderSizePixel = 0
        UnderBarFrame.Position = UDim2.new(-0.000297061284, 0, -3.76068449, 0)
        UnderBarFrame.Size = UDim2.new(0, math.floor(346 * Config.UIScale), 0, math.floor(40 * Config.UIScale))

        Text1.Name = "Text1"
        Text1.Parent = Notification
        Text1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Text1.BackgroundTransparency = 1.000
        Text1.Position = UDim2.new(0.1, 0, 0.0202020202, 0)
        Text1.Size = UDim2.new(0, math.floor(300 * Config.UIScale), 0, math.floor(68 * Config.UIScale))
        Text1.Font = Enum.Font.GothamSemibold
        Text1.Text = titletext
        Text1.TextColor3 = Color3.fromRGB(255, 255, 255)
        Text1.TextSize = math.floor(20 * Config.UIScale)

        Text2.Name = "Text2"
        Text2.Parent = Notification
        Text2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Text2.BackgroundTransparency = 1.000
        Text2.Position = UDim2.new(0.106342293, 0, 0.317724228, 0)
        Text2.Size = UDim2.new(0, math.floor(272 * Config.UIScale), 0, math.floor(63 * Config.UIScale))
        Text2.Font = Enum.Font.Gotham
        Text2.Text = desctext
        Text2.TextColor3 = Color3.fromRGB(171, 172, 176)
        Text2.TextSize = math.floor(14 * Config.UIScale)
        Text2.TextWrapped = true

        AlrightBtn.Name = "AlrightBtn"
        AlrightBtn.Parent = Notification
        AlrightBtn.BackgroundColor3 = colors[notifType]
        AlrightBtn.Position = UDim2.new(0.0332369953, 0, 0.789141417, 0)
        AlrightBtn.Size = UDim2.new(0, math.floor(322 * Config.UIScale), 0, math.floor(27 * Config.UIScale))
        AlrightBtn.Font = Enum.Font.Gotham
        AlrightBtn.Text = btntext
        AlrightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        AlrightBtn.TextSize = math.floor(13 * Config.UIScale)
        AlrightBtn.AutoButtonColor = false
        
        AlrightCorner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
        AlrightCorner.Name = "AlrightCorner"
        AlrightCorner.Parent = AlrightBtn
        
        AlrightBtn.MouseButton1Click:Connect(function()
            PlaySound("Click")
            TweenService:Create(
                NotificationHolderMain,
                TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            Notification:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, Config.AnimationSpeed, true)
            TweenService:Create(
                Notification,
                TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()
            wait(Config.AnimationSpeed)
            NotificationHolderMain:Destroy()
        end)
        
        AlrightBtn.MouseEnter:Connect(function()
            PlaySound("Hover")
            TweenService:Create(
                AlrightBtn,
                TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(103,123,196)}
            ):Play()
        end)

        AlrightBtn.MouseLeave:Connect(function()
            TweenService:Create(
                AlrightBtn,
                TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = colors[notifType]}
            ):Play()
        end)
    end

    MakeDraggable(TopFrame, MainFrame)
    ServersHoldPadding.PaddingLeft = UDim.new(0, math.floor(14 * Config.UIScale))
    
    local ServerHold = {}
    function ServerHold:Server(text, img)
        local fc = false
        local currentchanneltoggled = ""
        local Server = Instance.new("TextButton")
        local ServerBtnCorner = Instance.new("UICorner")
        local ServerIco = Instance.new("ImageLabel")
        local ServerWhiteFrame = Instance.new("Frame")
        local ServerWhiteFrameCorner = Instance.new("UICorner")

        Server.Name = text .. "Server"
        Server.Parent = ServersHold
        Server.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        Server.Position = UDim2.new(0.125, 0, 0, 0)
        Server.Size = UDim2.new(0, math.floor(47 * Config.UIScale), 0, math.floor(47 * Config.UIScale))
        Server.AutoButtonColor = false
        Server.Font = Enum.Font.Gotham
        Server.Text = ""
        Server.TextColor3 = Color3.fromRGB(255, 255, 255)
        Server.TextSize = math.floor(18 * Config.UIScale)

        ServerBtnCorner.CornerRadius = UDim.new(1, 0)
        ServerBtnCorner.Name = "ServerCorner"
        ServerBtnCorner.Parent = Server

        ServerIco.Name = "ServerIco"
        ServerIco.Parent = Server
        ServerIco.AnchorPoint = Vector2.new(0.5, 0.5)
        ServerIco.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ServerIco.BackgroundTransparency = 1.000
        ServerIco.Position = UDim2.new(0.489361703, 0, 0.489361703, 0)
        ServerIco.Size = UDim2.new(0, math.floor(26 * Config.UIScale), 0, math.floor(26 * Config.UIScale))
        ServerIco.Image = ""

        ServerWhiteFrame.Name = "ServerWhiteFrame"
        ServerWhiteFrame.Parent = Server
        ServerWhiteFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        ServerWhiteFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ServerWhiteFrame.Position = UDim2.new(-0.347378343, 0, 0.502659559, 0)
        ServerWhiteFrame.Size = UDim2.new(0, math.floor(11 * Config.UIScale), 0, math.floor(10 * Config.UIScale))

        ServerWhiteFrameCorner.CornerRadius = UDim.new(1, 0)
        ServerWhiteFrameCorner.Name = "ServerWhiteFrameCorner"
        ServerWhiteFrameCorner.Parent = ServerWhiteFrame
        ServersHold.CanvasSize = UDim2.new(0, 0, 0, ServersHoldLayout.AbsoluteContentSize.Y)

        local ServerFrame = Instance.new("Frame")
        local ServerFrame1 = Instance.new("Frame")
        local ServerFrame2 = Instance.new("Frame")
        local ServerTitleFrame = Instance.new("Frame")
        local ServerTitle = Instance.new("TextLabel")
        local GlowFrame = Instance.new("Frame")
        local Glow = Instance.new("ImageLabel")
        local ServerContentFrame = Instance.new("Frame")
        local ServerCorner = Instance.new("UICorner")
        local ChannelTitleFrame = Instance.new("Frame")
        local Hashtag = Instance.new("TextLabel")
        local ChannelTitle = Instance.new("TextLabel")
        local ChannelContentFrame = Instance.new("Frame")
        local GlowChannel = Instance.new("ImageLabel")
        local ServerChannelHolder = Instance.new("ScrollingFrame")
        local ServerChannelHolderLayout = Instance.new("UIListLayout")
        local ServerChannelHolderPadding = Instance.new("UIPadding")

        ServerFrame.Name = "ServerFrame"
        ServerFrame.Parent = ServersHolder
        ServerFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        ServerFrame.BorderSizePixel = 0
        ServerFrame.ClipsDescendants = true
        ServerFrame.Position = UDim2.new(0.105726875, 0, 1.01262593, 0)
        ServerFrame.Size = UDim2.new(0, math.floor(609 * Config.UIScale), 0, math.floor(373 * Config.UIScale))
        ServerFrame.Visible = false

        ServerFrame1.Name = "ServerFrame1"
        ServerFrame1.Parent = ServerFrame
        ServerFrame1.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        ServerFrame1.BorderSizePixel = 0
        ServerFrame1.Position = UDim2.new(0, 0, 0.972290039, 0)
        ServerFrame1.Size = UDim2.new(0, math.floor(12 * Config.UIScale), 0, math.floor(10 * Config.UIScale))

        ServerFrame2.Name = "ServerFrame2"
        ServerFrame2.Parent = ServerFrame
        ServerFrame2.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        ServerFrame2.BorderSizePixel = 0
        ServerFrame2.Position = UDim2.new(0.980295539, 0, 0.972290039, 0)
        ServerFrame2.Size = UDim2.new(0, math.floor(12 * Config.UIScale), 0, math.floor(9 * Config.UIScale))

        ServerTitleFrame.Name = "ServerTitleFrame"
        ServerTitleFrame.Parent = ServerFrame
        ServerTitleFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        ServerTitleFrame.BackgroundTransparency = 1.000
        ServerTitleFrame.BorderSizePixel = 0
        ServerTitleFrame.Position = UDim2.new(-0.0010054264, 0, -0.000900391256, 0)
        ServerTitleFrame.Size = UDim2.new(0, math.floor(180 * Config.UIScale), 0, math.floor(40 * Config.UIScale))

        ServerTitle.Name = "ServerTitle"
        ServerTitle.Parent = ServerTitleFrame
        ServerTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ServerTitle.BackgroundTransparency = 1.000
        ServerTitle.BorderSizePixel = 0
        ServerTitle.Position = UDim2.new(0.0751359761, 0, 0, 0)
        ServerTitle.Size = UDim2.new(0, math.floor(97 * Config.UIScale), 0, math.floor(39 * Config.UIScale))
        ServerTitle.Font = Enum.Font.GothamSemibold
        ServerTitle.Text = text
        ServerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        ServerTitle.TextSize = math.floor(15 * Config.UIScale)
        ServerTitle.TextXAlignment = Enum.TextXAlignment.Left

        GlowFrame.Name = "GlowFrame"
        GlowFrame.Parent = ServerFrame
        GlowFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        GlowFrame.BackgroundTransparency = 1.000
        GlowFrame.BorderSizePixel = 0
        GlowFrame.Position = UDim2.new(-0.0010054264, 0, -0.000900391256, 0)
        GlowFrame.Size = UDim2.new(0, math.floor(609 * Config.UIScale), 0, math.floor(40 * Config.UIScale))

        Glow.Name = "Glow"
        Glow.Parent = GlowFrame
        Glow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Glow.BackgroundTransparency = 1.000
        Glow.BorderSizePixel = 0
        Glow.Position = UDim2.new(0, -math.floor(15 * Config.UIScale), 0, -math.floor(15 * Config.UIScale))
        Glow.Size = UDim2.new(1, math.floor(30 * Config.UIScale), 1, math.floor(30 * Config.UIScale))
        Glow.ZIndex = 0
        Glow.Image = "rbxassetid://4996891970"
        Glow.ImageColor3 = Color3.fromRGB(15, 15, 15)
        Glow.ScaleType = Enum.ScaleType.Slice
        Glow.SliceCenter = Rect.new(20, 20, 280, 280)

        ServerContentFrame.Name = "ServerContentFrame"
        ServerContentFrame.Parent = ServerFrame
        ServerContentFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
        ServerContentFrame.BackgroundTransparency = 1.000
        ServerContentFrame.BorderSizePixel = 0
        ServerContentFrame.Position = UDim2.new(-0.0010054264, 0, 0.106338218, 0)
        ServerContentFrame.Size = UDim2.new(0, math.floor(180 * Config.UIScale), 0, math.floor(333 * Config.UIScale))

        ServerCorner.CornerRadius = UDim.new(0, math.floor(9 * Config.UIScale))
        ServerCorner.Name = "ServerCorner"
        ServerCorner.Parent = ServerFrame

        ChannelTitleFrame.Name = "ChannelTitleFrame"
        ChannelTitleFrame.Parent = ServerFrame
        ChannelTitleFrame.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
        ChannelTitleFrame.BorderSizePixel = 0
        ChannelTitleFrame.Position = UDim2.new(0.294561088, 0, -0.000900391256, 0)
        ChannelTitleFrame.Size = UDim2.new(0, math.floor(429 * Config.UIScale), 0, math.floor(40 * Config.UIScale))

        Hashtag.Name = "Hashtag"
        Hashtag.Parent = ChannelTitleFrame
        Hashtag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Hashtag.BackgroundTransparency = 1.000
        Hashtag.BorderSizePixel = 0
        Hashtag.Position = UDim2.new(0.0279720277, 0, 0, 0)
        Hashtag.Size = UDim2.new(0, math.floor(19 * Config.UIScale), 0, math.floor(39 * Config.UIScale))
        Hashtag.Font = Enum.Font.Gotham
        Hashtag.Text = "#"
        Hashtag.TextColor3 = Color3.fromRGB(114, 118, 125)
        Hashtag.TextSize = math.floor(25 * Config.UIScale)

        ChannelTitle.Name = "ChannelTitle"
        ChannelTitle.Parent = ChannelTitleFrame
        ChannelTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ChannelTitle.BackgroundTransparency = 1.000
        ChannelTitle.BorderSizePixel = 0
        ChannelTitle.Position = UDim2.new(0.0862470865, 0, 0, 0)
        ChannelTitle.Size = UDim2.new(0, math.floor(95 * Config.UIScale), 0, math.floor(39 * Config.UIScale))
        ChannelTitle.Font = Enum.Font.GothamSemibold
        ChannelTitle.Text = ""
        ChannelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        ChannelTitle.TextSize = math.floor(15 * Config.UIScale)
        ChannelTitle.TextXAlignment = Enum.TextXAlignment.Left

        ChannelContentFrame.Name = "ChannelContentFrame"
        ChannelContentFrame.Parent = ServerFrame
        ChannelContentFrame.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
        ChannelContentFrame.BorderSizePixel = 0
        ChannelContentFrame.ClipsDescendants = true
        ChannelContentFrame.Position = UDim2.new(0.294561088, 0, 0.106338218, 0)
        ChannelContentFrame.Size = UDim2.new(0, math.floor(429 * Config.UIScale), 0, math.floor(333 * Config.UIScale))

        GlowChannel.Name = "GlowChannel"
        GlowChannel.Parent = ChannelContentFrame
        GlowChannel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        GlowChannel.BackgroundTransparency = 1.000
        GlowChannel.BorderSizePixel = 0
        GlowChannel.Position = UDim2.new(0, -math.floor(33 * Config.UIScale), 0, -math.floor(91 * Config.UIScale))
        GlowChannel.Size = UDim2.new(1.06396091, math.floor(30 * Config.UIScale), 0.228228226, math.floor(30 * Config.UIScale))
        GlowChannel.ZIndex = 0
        GlowChannel.Image = "rbxassetid://4996891970"
        GlowChannel.ImageColor3 = Color3.fromRGB(15, 15, 15)
        GlowChannel.ScaleType = Enum.ScaleType.Slice
        GlowChannel.SliceCenter = Rect.new(20, 20, 280, 280)

        ServerChannelHolder.Name = "ServerChannelHolder"
        ServerChannelHolder.Parent = ServerContentFrame
        ServerChannelHolder.Active = true
        ServerChannelHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ServerChannelHolder.BackgroundTransparency = 1.000
        ServerChannelHolder.BorderSizePixel = 0
        ServerChannelHolder.Position = UDim2.new(0.00535549596, 0, 0.0241984241, 0)
        ServerChannelHolder.Selectable = false
        ServerChannelHolder.Size = UDim2.new(0, math.floor(179 * Config.UIScale), 0, math.floor(278 * Config.UIScale))
        ServerChannelHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
        ServerChannelHolder.ScrollBarThickness = math.floor(4 * Config.UIScale)
        ServerChannelHolder.ScrollBarImageColor3 = Color3.fromRGB(18, 19, 21)
        ServerChannelHolder.ScrollBarImageTransparency = 1

        ServerChannelHolderLayout.Name = "ServerChannelHolderLayout"
        ServerChannelHolderLayout.Parent = ServerChannelHolder
        ServerChannelHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ServerChannelHolderLayout.Padding = UDim.new(0, math.floor(4 * Config.UIScale))

        ServerChannelHolderPadding.Name = "ServerChannelHolderPadding"
        ServerChannelHolderPadding.Parent = ServerChannelHolder
        ServerChannelHolderPadding.PaddingLeft = UDim.new(0, math.floor(9 * Config.UIScale))
        
        ServerChannelHolder.MouseEnter:Connect(function()
            ServerChannelHolder.ScrollBarImageTransparency = 0
        end)
        
        ServerChannelHolder.MouseLeave:Connect(function()
            ServerChannelHolder.ScrollBarImageTransparency = 1
        end)

        Server.MouseEnter:Connect(function()
            if currentservertoggled ~= Server.Name then
                TweenService:Create(
                    Server,
                    TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundColor3 = HoverColors.ServerHover}
                ):Play()
                TweenService:Create(
                    ServerBtnCorner,
                    TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {CornerRadius = UDim.new(0, math.floor(15 * Config.UIScale))}
                ):Play()
                ServerWhiteFrame:TweenSize(
                    UDim2.new(0, math.floor(11 * Config.UIScale), 0, math.floor(27 * Config.UIScale)),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Quart,
                    .3,
                    true
                )
            end
        end)

        Server.MouseLeave:Connect(function()
            if currentservertoggled ~= Server.Name then
                TweenService:Create(
                    Server,
                    TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundColor3 = HoverColors.ServerNormal}
                ):Play()
                TweenService:Create(
                    ServerBtnCorner,
                    TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {CornerRadius = UDim.new(1, 0)}
                ):Play()
                ServerWhiteFrame:TweenSize(
                    UDim2.new(0, math.floor(11 * Config.UIScale), 0, math.floor(10 * Config.UIScale)),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Quart,
                    .3,
                    true
                )
            end
        end)

        Server.MouseButton1Click:Connect(function()
            currentservertoggled = Server.Name
            for i, v in next, ServersHolder:GetChildren() do
                if v.Name == "ServerFrame" then
                    v.Visible = false
                end
                ServerFrame.Visible = true
            end
            for i, v in next, ServersHold:GetChildren() do
                if v.ClassName == "TextButton" then
                    TweenService:Create(
                        v,
                        TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {BackgroundColor3 = HoverColors.ServerNormal}
                    ):Play()
                    TweenService:Create(
                        Server,
                        TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {BackgroundColor3 = HoverColors.ServerHover}
                    ):Play()
                    TweenService:Create(
                        v.ServerCorner,
                        TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {CornerRadius = UDim.new(1, 0)}
                    ):Play()
                    TweenService:Create(
                        ServerBtnCorner,
                        TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {CornerRadius = UDim.new(0, math.floor(15 * Config.UIScale))}
                    ):Play()
                    v.ServerWhiteFrame:TweenSize(
                        UDim2.new(0, math.floor(11 * Config.UIScale), 0, math.floor(10 * Config.UIScale)),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        .3,
                        true
                    )
                    ServerWhiteFrame:TweenSize(
                        UDim2.new(0, math.floor(11 * Config.UIScale), 0, math.floor(46 * Config.UIScale)),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        .3,
                        true
                    )
                end
            end
        end)

        if img == "" then
            Server.Text = string.sub(text, 1, 1)
        else
            ServerIco.Image = img
        end

        if fs == false then
            TweenService:Create(
                Server,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = HoverColors.ServerHover}
            ):Play()
            TweenService:Create(
                ServerBtnCorner,
                TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {CornerRadius = UDim.new(0, math.floor(15 * Config.UIScale))}
            ):Play()
            ServerWhiteFrame:TweenSize(
                UDim2.new(0, math.floor(11 * Config.UIScale), 0, math.floor(46 * Config.UIScale)),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quart,
                .3,
                true
            )
            ServerFrame.Visible = true
            Server.Name = text .. "Server"
            currentservertoggled = Server.Name
            fs = true
        end
        
        local ChannelHold = {}
        function ChannelHold:Channel(text)
            local ChannelBtn = Instance.new("TextButton")
            local ChannelBtnCorner = Instance.new("UICorner")
            local ChannelBtnHashtag = Instance.new("TextLabel")
            local ChannelBtnTitle = Instance.new("TextLabel")

            ChannelBtn.Name = text .. "ChannelBtn"
            ChannelBtn.Parent = ServerChannelHolder
            ChannelBtn.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
            ChannelBtn.BorderSizePixel = 0
            ChannelBtn.Position = UDim2.new(0.24118948, 0, 0.578947365, 0)
            ChannelBtn.Size = UDim2.new(0, math.floor(160 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
            ChannelBtn.AutoButtonColor = false
            ChannelBtn.Font = Enum.Font.SourceSans
            ChannelBtn.Text = ""
            ChannelBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            ChannelBtn.TextSize = math.floor(14 * Config.UIScale)

            ChannelBtnCorner.CornerRadius = UDim.new(0, math.floor(6 * Config.UIScale))
            ChannelBtnCorner.Name = "ChannelBtnCorner"
            ChannelBtnCorner.Parent = ChannelBtn

            ChannelBtnHashtag.Name = "ChannelBtnHashtag"
            ChannelBtnHashtag.Parent = ChannelBtn
            ChannelBtnHashtag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ChannelBtnHashtag.BackgroundTransparency = 1.000
            ChannelBtnHashtag.BorderSizePixel = 0
            ChannelBtnHashtag.Position = UDim2.new(0.0279720314, 0, 0, 0)
            ChannelBtnHashtag.Size = UDim2.new(0, math.floor(24 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
            ChannelBtnHashtag.Font = Enum.Font.Gotham
            ChannelBtnHashtag.Text = "#"
            ChannelBtnHashtag.TextColor3 = Color3.fromRGB(114, 118, 125)
            ChannelBtnHashtag.TextSize = math.floor(21 * Config.UIScale)

            ChannelBtnTitle.Name = "ChannelBtnTitle"
            ChannelBtnTitle.Parent = ChannelBtn
            ChannelBtnTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ChannelBtnTitle.BackgroundTransparency = 1.000
            ChannelBtnTitle.BorderSizePixel = 0
            ChannelBtnTitle.Position = UDim2.new(0.173747092, 0, -0.166666672, 0)
            ChannelBtnTitle.Size = UDim2.new(0, math.floor(95 * Config.UIScale), 0, math.floor(39 * Config.UIScale))
            ChannelBtnTitle.Font = Enum.Font.Gotham
            ChannelBtnTitle.Text = text
            ChannelBtnTitle.TextColor3 = Color3.fromRGB(114, 118, 125)
            ChannelBtnTitle.TextSize = math.floor(14 * Config.UIScale)
            ChannelBtnTitle.TextXAlignment = Enum.TextXAlignment.Left
            ServerChannelHolder.CanvasSize = UDim2.new(0, 0, 0, ServerChannelHolderLayout.AbsoluteContentSize.Y)

            local ChannelHolder = Instance.new("ScrollingFrame")
            local ChannelHolderLayout = Instance.new("UIListLayout")

            ChannelHolder.Name = "ChannelHolder"
            ChannelHolder.Parent = ChannelContentFrame
            ChannelHolder.Active = true
            ChannelHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ChannelHolder.BackgroundTransparency = 1.000
            ChannelHolder.BorderSizePixel = 0
            ChannelHolder.Position = UDim2.new(0.0360843192, 0, 0.0241984241, 0)
            ChannelHolder.Size = UDim2.new(0, math.floor(412 * Config.UIScale), 0, math.floor(314 * Config.UIScale))
            ChannelHolder.ScrollBarThickness = math.floor(6 * Config.UIScale)
            ChannelHolder.CanvasSize = UDim2.new(0,0,0,0)
            ChannelHolder.ScrollBarImageTransparency = 0
            ChannelHolder.ScrollBarImageColor3 = Color3.fromRGB(18, 19, 21)
            ChannelHolder.Visible = false
            ChannelHolder.ClipsDescendants = false

            ChannelHolderLayout.Name = "ChannelHolderLayout"
            ChannelHolderLayout.Parent = ChannelHolder
            ChannelHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ChannelHolderLayout.Padding = UDim.new(0, math.floor(6 * Config.UIScale))
            
            ChannelBtn.MouseEnter:Connect(function()
                if currentchanneltoggled ~= ChannelBtn.Name then
                    ChannelBtn.BackgroundColor3 = HoverColors.ChannelHover
                    ChannelBtnTitle.TextColor3 = Color3.fromRGB(220,221,222)
                end
            end)
            
            ChannelBtn.MouseLeave:Connect(function()
                if currentchanneltoggled ~= ChannelBtn.Name then
                    ChannelBtn.BackgroundColor3 = HoverColors.ChannelNormal
                    ChannelBtnTitle.TextColor3 = Color3.fromRGB(114, 118, 125)
                end
            end)
            
            ChannelBtn.MouseButton1Click:Connect(function()
                for i, v in next, ChannelContentFrame:GetChildren() do
                    if v.Name == "ChannelHolder" then
                        v.Visible = false
                    end
                    ChannelHolder.Visible = true
                end
                for i, v in next, ServerChannelHolder:GetChildren() do
                    if v.ClassName == "TextButton" then
                        v.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
                        v.ChannelBtnTitle.TextColor3 = Color3.fromRGB(114, 118, 125)
                    end
                    ServerFrame.Visible = true
                end
                ChannelTitle.Text = text
                ChannelBtn.BackgroundColor3 = Color3.fromRGB(57,60,67)
                ChannelBtnTitle.TextColor3 = Color3.fromRGB(255,255,255)
                currentchanneltoggled = ChannelBtn.Name
            end)
            
            if fc == false then
                fc = true
                ChannelTitle.Text = text
                ChannelBtn.BackgroundColor3 = Color3.fromRGB(57,60,67)
                ChannelBtnTitle.TextColor3 = Color3.fromRGB(255,255,255)
                currentchanneltoggled = ChannelBtn.Name
                ChannelHolder.Visible = true
            end
            
            local ChannelContent = {}
            function ChannelContent:Button(text,callback)
                local Button = Instance.new("TextButton")
                local ButtonCorner = Instance.new("UICorner")

                Button.Name = "Button"
                Button.Parent = ChannelHolder
                Button.BackgroundColor3 = Config.AccentColor
                Button.Size = UDim2.new(0, math.floor(401 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
                Button.AutoButtonColor = false
                Button.Font = Enum.Font.Gotham
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.TextSize = math.floor(14 * Config.UIScale)
                Button.Text = text

                ButtonCorner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
                ButtonCorner.Name = "ButtonCorner"
                ButtonCorner.Parent = Button
                
                Button.MouseEnter:Connect(function()
                    PlaySound("Hover")
                    TweenService:Create(
                        Button,
                        TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {BackgroundColor3 = HoverColors.ButtonHover}
                    ):Play()
                    if Config.EnableGlow then
                        CreateGlow(Button, Config.AccentColor)
                    end
                end)
                
                Button.MouseButton1Click:Connect(function()
                    PlaySound("Click")
                    pcall(callback)
                    Button.TextSize = 0
                    TweenService:Create(
                        Button,
                        TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {TextSize = math.floor(14 * Config.UIScale)}
                    ):Play()
                end)
                
                Button.MouseLeave:Connect(function()
                    TweenService:Create(
                        Button,
                        TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {BackgroundColor3 = HoverColors.ButtonNormal}
                    ):Play()
                    local glow = Button:FindFirstChild("Glow")
                    if glow then
                        glow:Destroy()
                    end
                end)
                ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
            end
            
            function ChannelContent:Toggle(text,default,callback)
                local toggled = false
                local Toggle = Instance.new("TextButton")
                local ToggleTitle = Instance.new("TextLabel")
                local ToggleFrame = Instance.new("Frame")
                local ToggleFrameCorner = Instance.new("UICorner")
                local ToggleFrameCircle = Instance.new("Frame")
                local ToggleFrameCircleCorner = Instance.new("UICorner")
                local Icon = Instance.new("ImageLabel")

                Toggle.Name = "Toggle"
                Toggle.Parent = ChannelHolder
                Toggle.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
                Toggle.BorderSizePixel = 0
                Toggle.Position = UDim2.new(0.261979163, 0, 0.190789461, 0)
                Toggle.Size = UDim2.new(0, math.floor(401 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
                Toggle.AutoButtonColor = false
                Toggle.Font = Enum.Font.Gotham
                Toggle.Text = ""
                Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
                Toggle.TextSize = math.floor(14 * Config.UIScale)

                ToggleTitle.Name = "ToggleTitle"
                ToggleTitle.Parent = Toggle
                ToggleTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ToggleTitle.BackgroundTransparency = 1.000
                ToggleTitle.Position = UDim2.new(0, math.floor(5 * Config.UIScale), 0, 0)
                ToggleTitle.Size = UDim2.new(0, math.floor(200 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
                ToggleTitle.Font = Enum.Font.Gotham
                ToggleTitle.Text = text
                ToggleTitle.TextColor3 = Color3.fromRGB(127, 131, 137)
                ToggleTitle.TextSize = math.floor(14 * Config.UIScale)
                ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left

                ToggleFrame.Name = "ToggleFrame"
                ToggleFrame.Parent = Toggle
                ToggleFrame.BackgroundColor3 = Color3.fromRGB(114, 118, 125)
                ToggleFrame.Position = UDim2.new(0.900481343, -math.floor(5 * Config.UIScale), 0.13300018, 0)
                ToggleFrame.Size = UDim2.new(0, math.floor(40 * Config.UIScale), 0, math.floor(21 * Config.UIScale))

                ToggleFrameCorner.CornerRadius = UDim.new(1, math.floor(8 * Config.UIScale))
                ToggleFrameCorner.Name = "ToggleFrameCorner"
                ToggleFrameCorner.Parent = ToggleFrame

                ToggleFrameCircle.Name = "ToggleFrameCircle"
                ToggleFrameCircle.Parent = ToggleFrame
                ToggleFrameCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ToggleFrameCircle.Position = UDim2.new(0.234999999, -math.floor(5 * Config.UIScale), 0.133000001, 0)
                ToggleFrameCircle.Size = UDim2.new(0, math.floor(15 * Config.UIScale), 0, math.floor(15 * Config.UIScale))

                ToggleFrameCircleCorner.CornerRadius = UDim.new(1, 0)
                ToggleFrameCircleCorner.Name = "ToggleFrameCircleCorner"
                ToggleFrameCircleCorner.Parent = ToggleFrameCircle

                Icon.Name = "Icon"
                Icon.Parent = ToggleFrameCircle
                Icon.AnchorPoint = Vector2.new(0.5, 0.5)
                Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Icon.BackgroundTransparency = 1.000
                Icon.BorderColor3 = Color3.fromRGB(27, 42, 53)
                Icon.Position = UDim2.new(0, math.floor(8 * Config.UIScale), 0, math.floor(8 * Config.UIScale))
                Icon.Size = UDim2.new(0, math.floor(13 * Config.UIScale), 0, math.floor(13 * Config.UIScale))
                Icon.Image = "http://www.roblox.com/asset/?id=6035047409"
                Icon.ImageColor3 = Color3.fromRGB(114, 118, 125)
                
                Toggle.MouseButton1Click:Connect(function()
                    PlaySound("Click")
                    if toggled == false then
                        TweenService:Create(
                            Icon,
                            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {ImageColor3 = Color3.fromRGB(67,181,129)}
                        ):Play()
                        TweenService:Create(
                            ToggleFrame,
                            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {BackgroundColor3 = Color3.fromRGB(67,181,129)}
                        ):Play()
                        ToggleFrameCircle:TweenPosition(UDim2.new(0.655, -math.floor(5 * Config.UIScale), 0.133000001, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, Config.AnimationSpeed, true)
                        TweenService:Create(
                            Icon,
                            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {ImageTransparency = 1}
                        ):Play()
                        Icon.Image = "http://www.roblox.com/asset/?id=6023426926"
                        wait(.1)
                        TweenService:Create(
                            Icon,
                            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {ImageTransparency = 0}
                        ):Play()
                    else
                        TweenService:Create(
                            Icon,
                            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {ImageColor3 = Color3.fromRGB(114, 118, 125)}
                        ):Play()
                        TweenService:Create(
                            ToggleFrame,
                            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {BackgroundColor3 = Color3.fromRGB(114, 118, 125)}
                        ):Play()
                        ToggleFrameCircle:TweenPosition(UDim2.new(0.234999999, -math.floor(5 * Config.UIScale), 0.133000001, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, Config.AnimationSpeed, true)
                        TweenService:Create(
                            Icon,
                            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {ImageTransparency = 1}
                        ):Play()
                        Icon.Image = "http://www.roblox.com/asset/?id=6035047409"
                        wait(.1)
                        TweenService:Create(
                            Icon,
                            TweenInfo.new(Config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {ImageTransparency = 0}
                        ):Play()
                    end
                    toggled = not toggled
                    pcall(callback, toggled)
                end)
                
                ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
            end
            
            function ChannelContent:Slider(text, min, max, start, callback)
                local SliderFunc = {}
                local dragging = false
                local Slider = Instance.new("TextButton")
                local SliderTitle = Instance.new("TextLabel")
                local SliderFrame = Instance.new("Frame")
                local SliderFrameCorner = Instance.new("UICorner")
                local CurrentValueFrame = Instance.new("Frame")
                local CurrentValueFrameCorner = Instance.new("UICorner")
                local Zip = Instance.new("Frame")
                local ZipCorner = Instance.new("UICorner")
                local ValueBubble = Instance.new("Frame")
                local ValueBubbleCorner = Instance.new("UICorner")
                local SquareBubble = Instance.new("Frame")
                local GlowBubble = Instance.new("ImageLabel")
                local ValueLabel = Instance.new("TextLabel")

                Slider.Name = "Slider"
                Slider.Parent = ChannelHolder
                Slider.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
                Slider.BorderSizePixel = 0
                Slider.Position = UDim2.new(0, 0, 0.216560602, 0)
                Slider.Size = UDim2.new(0, math.floor(401 * Config.UIScale), 0, math.floor(38 * Config.UIScale))
                Slider.AutoButtonColor = false
                Slider.Font = Enum.Font.Gotham
                Slider.Text = ""
                Slider.TextColor3 = Color3.fromRGB(255, 255, 255)
                Slider.TextSize = math.floor(14 * Config.UIScale)

                SliderTitle.Name = "SliderTitle"
                SliderTitle.Parent = Slider
                SliderTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SliderTitle.BackgroundTransparency = 1.000
                SliderTitle.Position = UDim2.new(0, math.floor(5 * Config.UIScale), 0, -math.floor(4 * Config.UIScale))
                SliderTitle.Size = UDim2.new(0, math.floor(200 * Config.UIScale), 0, math.floor(27 * Config.UIScale))
                SliderTitle.Font = Enum.Font.Gotham
                SliderTitle.Text = text
                SliderTitle.TextColor3 = Color3.fromRGB(127, 131, 137)
                SliderTitle.TextSize = math.floor(14 * Config.UIScale)
                SliderTitle.TextXAlignment = Enum.TextXAlignment.Left

                SliderFrame.Name = "SliderFrame"
                SliderFrame.Parent = Slider
                SliderFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                SliderFrame.BackgroundColor3 = Color3.fromRGB(79, 84, 92)
                SliderFrame.Position = UDim2.new(0.497999996, 0, 0.757000029, 0)
                SliderFrame.Size = UDim2.new(0, math.floor(385 * Config.UIScale), 0, math.floor(8 * Config.UIScale))

                SliderFrameCorner.Name = "SliderFrameCorner"
                SliderFrameCorner.Parent = SliderFrame

                CurrentValueFrame.Name = "CurrentValueFrame"
                CurrentValueFrame.Parent = SliderFrame
                CurrentValueFrame.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
                CurrentValueFrame.Size = UDim2.new((start or 0) / max, 0, 0, math.floor(8 * Config.UIScale))

                CurrentValueFrameCorner.Name = "CurrentValueFrameCorner"
                CurrentValueFrameCorner.Parent = CurrentValueFrame

                Zip.Name = "Zip"
                Zip.Parent = SliderFrame
                Zip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Zip.Position = UDim2.new((start or 0)/max, -math.floor(6 * Config.UIScale), -0.644999981, 0)
                Zip.Size = UDim2.new(0, math.floor(10 * Config.UIScale), 0, math.floor(18 * Config.UIScale))
                ZipCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                ZipCorner.Name = "ZipCorner"
                ZipCorner.Parent = Zip

                ValueBubble.Name = "ValueBubble"
                ValueBubble.Parent = Zip
                ValueBubble.AnchorPoint = Vector2.new(0.5, 0.5)
                ValueBubble.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
                ValueBubble.Position = UDim2.new(0.5, 0, -1.00800002, 0)
                ValueBubble.Size = UDim2.new(0, math.floor(36 * Config.UIScale), 0, math.floor(21 * Config.UIScale))
                ValueBubble.Visible = false

                Zip.MouseEnter:Connect(function()
                    if dragging == false then
                        ValueBubble.Visible = true
                    end
                end)
                
                Zip.MouseLeave:Connect(function()
                    if dragging == false then
                        ValueBubble.Visible = false
                    end
                end)

                ValueBubbleCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                ValueBubbleCorner.Name = "ValueBubbleCorner"
                ValueBubbleCorner.Parent = ValueBubble

                SquareBubble.Name = "SquareBubble"
                SquareBubble.Parent = ValueBubble
                SquareBubble.AnchorPoint = Vector2.new(0.5, 0.5)
                SquareBubble.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
                SquareBubble.BorderSizePixel = 0
                SquareBubble.Position = UDim2.new(0.493000001, 0, 0.637999971, 0)
                SquareBubble.Rotation = 45.000
                SquareBubble.Size = UDim2.new(0, math.floor(19 * Config.UIScale), 0, math.floor(19 * Config.UIScale))

                GlowBubble.Name = "GlowBubble"
                GlowBubble.Parent = ValueBubble
                GlowBubble.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                GlowBubble.BackgroundTransparency = 1.000
                GlowBubble.BorderSizePixel = 0
                GlowBubble.Position = UDim2.new(0, -math.floor(15 * Config.UIScale), 0, -math.floor(15 * Config.UIScale))
                GlowBubble.Size = UDim2.new(1, math.floor(30 * Config.UIScale), 1, math.floor(30 * Config.UIScale))
                GlowBubble.ZIndex = 0
                GlowBubble.Image = "rbxassetid://4996891970"
                GlowBubble.ImageColor3 = Color3.fromRGB(15, 15, 15)
                GlowBubble.ScaleType = Enum.ScaleType.Slice
                GlowBubble.SliceCenter = Rect.new(20, 20, 280, 280)

                ValueLabel.Name = "ValueLabel"
                ValueLabel.Parent = ValueBubble
                ValueLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ValueLabel.BackgroundTransparency = 1.000
                ValueLabel.Size = UDim2.new(0, math.floor(36 * Config.UIScale), 0, math.floor(21 * Config.UIScale))
                ValueLabel.Font = Enum.Font.Gotham
                ValueLabel.Text = tostring(start and math.floor((start / max) * (max - min) + min) or 0)
                ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                ValueLabel.TextSize = math.floor(10 * Config.UIScale)
                
                local function move(input)
                    local relativeX = math.clamp((input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
                    local value = math.floor(relativeX * (max - min) + min)
                    
                    CurrentValueFrame.Size = UDim2.new(relativeX, 0, 0, math.floor(8 * Config.UIScale))
                    Zip.Position = UDim2.new(relativeX, -math.floor(6 * Config.UIScale), -0.644999981, 0)
                    ValueLabel.Text = tostring(value)
                    pcall(callback, value)
                end
                
                Zip.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        ValueBubble.Visible = true
                        move(input)
                    end
                end)
                
                Zip.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                        ValueBubble.Visible = false
                    end
                end)
                
                SliderFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        move(input)
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        move(input)
                    end
                end)
                
                function SliderFunc:Change(tochange)
                    local relativeX = math.clamp((tochange - min) / (max - min), 0, 1)
                    CurrentValueFrame.Size = UDim2.new(relativeX, 0, 0, math.floor(8 * Config.UIScale))
                    Zip.Position = UDim2.new(relativeX, -math.floor(6 * Config.UIScale), -0.644999981, 0)
                    ValueLabel.Text = tostring(tochange)
                    pcall(callback, tochange)
                end
                
                ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
                return SliderFunc
            end
            
            function ChannelContent:Seperator()
                local Seperator1 = Instance.new("Frame")
                local Seperator2 = Instance.new("Frame")

                Seperator1.Name = "Seperator1"
                Seperator1.Parent = ChannelHolder
                Seperator1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Seperator1.BackgroundTransparency = 1.000
                Seperator1.Position = UDim2.new(0, 0, 0.350318581, 0)
                Seperator1.Size = UDim2.new(0, math.floor(100 * Config.UIScale), 0, math.floor(8 * Config.UIScale))

                Seperator2.Name = "Seperator2"
                Seperator2.Parent = Seperator1
                Seperator2.BackgroundColor3 = Color3.fromRGB(66, 69, 74)
                Seperator2.BorderSizePixel = 0
                Seperator2.Position = UDim2.new(0, 0, 0, math.floor(4 * Config.UIScale))
                Seperator2.Size = UDim2.new(0, math.floor(401 * Config.UIScale), 0, math.floor(1 * Config.UIScale))
                ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
            end
            
            function ChannelContent:Dropdown(text, list, callback)
                local DropFunc = {}
                local itemcount = 0
                local framesize = 0
                local DropTog = false
                local Dropdown = Instance.new("Frame")
                local DropdownTitle = Instance.new("TextLabel")
                local DropdownFrameOutline = Instance.new("Frame")
                local DropdownFrameOutlineCorner = Instance.new("UICorner")
                local DropdownFrame = Instance.new("Frame")
                local DropdownFrameCorner = Instance.new("UICorner")
                local CurrentSelectedText = Instance.new("TextLabel")
                local ArrowImg = Instance.new("ImageLabel")
                local DropdownFrameBtn = Instance.new("TextButton")

                Dropdown.Name = "Dropdown"
                Dropdown.Parent = ChannelHolder
                Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Dropdown.BackgroundTransparency = 1.000
                Dropdown.Position = UDim2.new(0.0796874985, 0, 0.445175439, 0)
                Dropdown.Size = UDim2.new(0, math.floor(403 * Config.UIScale), 0, math.floor(73 * Config.UIScale))

                DropdownTitle.Name = "DropdownTitle"
                DropdownTitle.Parent = Dropdown
                DropdownTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                DropdownTitle.BackgroundTransparency = 1.000
                DropdownTitle.Position = UDim2.new(0, math.floor(5 * Config.UIScale), 0, 0)
                DropdownTitle.Size = UDim2.new(0, math.floor(200 * Config.UIScale), 0, math.floor(29 * Config.UIScale))
                DropdownTitle.Font = Enum.Font.Gotham
                DropdownTitle.Text = text
                DropdownTitle.TextColor3 = Color3.fromRGB(127, 131, 137)
                DropdownTitle.TextSize = math.floor(14 * Config.UIScale)
                DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left

                DropdownFrameOutline.Name = "DropdownFrameOutline"
                DropdownFrameOutline.Parent = DropdownTitle
                DropdownFrameOutline.AnchorPoint = Vector2.new(0.5, 0.5)
                DropdownFrameOutline.BackgroundColor3 = Color3.fromRGB(37, 40, 43)
                DropdownFrameOutline.Position = UDim2.new(0.988442957, 0, 1.6197437, 0)
                DropdownFrameOutline.Size = UDim2.new(0, math.floor(396 * Config.UIScale), 0, math.floor(36 * Config.UIScale))

                DropdownFrameOutlineCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                DropdownFrameOutlineCorner.Name = "DropdownFrameOutlineCorner"
                DropdownFrameOutlineCorner.Parent = DropdownFrameOutline

                DropdownFrame.Name = "DropdownFrame"
                DropdownFrame.Parent = DropdownTitle
                DropdownFrame.BackgroundColor3 = Color3.fromRGB(48, 51, 57)
                DropdownFrame.ClipsDescendants = true
                DropdownFrame.Position = UDim2.new(0.00999999978, 0, 1.06638527, 0)
                DropdownFrame.Selectable = true
                DropdownFrame.Size = UDim2.new(0, math.floor(392 * Config.UIScale), 0, math.floor(32 * Config.UIScale))

                DropdownFrameCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                DropdownFrameCorner.Name = "DropdownFrameCorner"
                DropdownFrameCorner.Parent = DropdownFrame

                CurrentSelectedText.Name = "CurrentSelectedText"
                CurrentSelectedText.Parent = DropdownFrame
                CurrentSelectedText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                CurrentSelectedText.BackgroundTransparency = 1.000
                CurrentSelectedText.Position = UDim2.new(0.0178571437, 0, 0, 0)
                CurrentSelectedText.Size = UDim2.new(0, math.floor(193 * Config.UIScale), 0, math.floor(32 * Config.UIScale))
                CurrentSelectedText.Font = Enum.Font.Gotham
                CurrentSelectedText.Text = "..."
                CurrentSelectedText.TextColor3 = Color3.fromRGB(212, 212, 212)
                CurrentSelectedText.TextSize = math.floor(14 * Config.UIScale)
                CurrentSelectedText.TextXAlignment = Enum.TextXAlignment.Left

                ArrowImg.Name = "ArrowImg"
                ArrowImg.Parent = CurrentSelectedText
                ArrowImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ArrowImg.BackgroundTransparency = 1.000
                ArrowImg.Position = UDim2.new(1.84974098, 0, 0.167428851, 0)
                ArrowImg.Size = UDim2.new(0, math.floor(22 * Config.UIScale), 0, math.floor(22 * Config.UIScale))
                ArrowImg.Image = "http://www.roblox.com/asset/?id=6034818372"
                ArrowImg.ImageColor3 = Color3.fromRGB(212, 212, 212)

                DropdownFrameBtn.Name = "DropdownFrameBtn"
                DropdownFrameBtn.Parent = DropdownFrame
                DropdownFrameBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                DropdownFrameBtn.BackgroundTransparency = 1.000
                DropdownFrameBtn.Size = UDim2.new(0, math.floor(392 * Config.UIScale), 0, math.floor(32 * Config.UIScale))
                DropdownFrameBtn.Font = Enum.Font.SourceSans
                DropdownFrameBtn.Text = ""
                DropdownFrameBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                DropdownFrameBtn.TextSize = math.floor(14 * Config.UIScale)

                local DropdownFrameMainOutline = Instance.new("Frame")
                local DropdownFrameMainOutlineCorner = Instance.new("UICorner")
                local DropdownFrameMain = Instance.new("Frame")
                local DropdownFrameMainCorner = Instance.new("UICorner")
                local DropItemHolderLabel = Instance.new("TextLabel")
                local DropItemHolder = Instance.new("ScrollingFrame")
                local DropItemHolderLayout = Instance.new("UIListLayout")

                DropdownFrameMainOutline.Name = "DropdownFrameMainOutline"
                DropdownFrameMainOutline.Parent = DropdownTitle
                DropdownFrameMainOutline.BackgroundColor3 = Color3.fromRGB(37, 40, 43)
                DropdownFrameMainOutline.Position = UDim2.new(-0.00155700743, 0, 2.16983342, 0)
                DropdownFrameMainOutline.Size = UDim2.new(0, math.floor(396 * Config.UIScale), 0, math.floor(81 * Config.UIScale))
                DropdownFrameMainOutline.Visible = false

                DropdownFrameMainOutlineCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                DropdownFrameMainOutlineCorner.Name = "DropdownFrameMainOutlineCorner"
                DropdownFrameMainOutlineCorner.Parent = DropdownFrameMainOutline

                DropdownFrameMain.Name = "DropdownFrameMain"
                DropdownFrameMain.Parent = DropdownTitle
                DropdownFrameMain.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
                DropdownFrameMain.ClipsDescendants = true
                DropdownFrameMain.Position = UDim2.new(0.00999999978, 0, 2.2568965, 0)
                DropdownFrameMain.Selectable = true
                DropdownFrameMain.Size = UDim2.new(0, math.floor(392 * Config.UIScale), 0, math.floor(77 * Config.UIScale))
                DropdownFrameMain.Visible = false

                DropdownFrameMainCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                DropdownFrameMainCorner.Name = "DropdownFrameMainCorner"
                DropdownFrameMainCorner.Parent = DropdownFrameMain

                DropItemHolderLabel.Name = "ItemHolderLabel"
                DropItemHolderLabel.Parent = DropdownFrameMain
                DropItemHolderLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                DropItemHolderLabel.BackgroundTransparency = 1.000
                DropItemHolderLabel.Position = UDim2.new(0.0178571437, 0, 0, 0)
                DropItemHolderLabel.Size = UDim2.new(0, math.floor(193 * Config.UIScale), 0, math.floor(13 * Config.UIScale))
                DropItemHolderLabel.Font = Enum.Font.Gotham
                DropItemHolderLabel.Text = ""
                DropItemHolderLabel.TextColor3 = Color3.fromRGB(212, 212, 212)
                DropItemHolderLabel.TextSize = math.floor(14 * Config.UIScale)
                DropItemHolderLabel.TextXAlignment = Enum.TextXAlignment.Left

                DropItemHolder.Name = "ItemHolder"
                DropItemHolder.Parent = DropItemHolderLabel
                DropItemHolder.Active = true
                DropItemHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                DropItemHolder.BackgroundTransparency = 1.000
                DropItemHolder.Position = UDim2.new(0, 0, 0.215384638, 0)
                DropItemHolder.Size = UDim2.new(0, math.floor(385 * Config.UIScale), 0, 0)
                DropItemHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
                DropItemHolder.ScrollBarThickness = math.floor(6 * Config.UIScale)
                DropItemHolder.BorderSizePixel = 0
                DropItemHolder.ScrollBarImageColor3 = Color3.fromRGB(28, 29, 32)

                DropItemHolderLayout.Name = "ItemHolderLayout"
                DropItemHolderLayout.Parent = DropItemHolder
                DropItemHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
                DropItemHolderLayout.Padding = UDim.new(0, 0)
                
                DropdownFrameBtn.MouseButton1Click:Connect(function()
                    if DropTog == false then
                        DropdownFrameMain.Visible = true
                        DropdownFrameMainOutline.Visible = true
                        Dropdown.Size = UDim2.new(0, math.floor(403 * Config.UIScale), 0, math.floor(73 * Config.UIScale) + DropdownFrameMainOutline.AbsoluteSize.Y)
                        ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
                        
                    else
                        Dropdown.Size = UDim2.new(0, math.floor(403 * Config.UIScale), 0, math.floor(73 * Config.UIScale))
                        DropdownFrameMain.Visible = false
                        DropdownFrameMainOutline.Visible = false
                        ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
                    end
                    DropTog = not DropTog
                end)
                
                for i,v in next, list do
                    itemcount = itemcount + 1
                    
                    if itemcount == 1 then
                        framesize = math.floor(29 * Config.UIScale)
                    elseif itemcount == 2 then
                        framesize = math.floor(58 * Config.UIScale)
                    elseif itemcount >= 3 then
                        framesize = math.floor(87 * Config.UIScale)
                    end
                    
                    local Item = Instance.new("TextButton")
                    local ItemCorner = Instance.new("UICorner")
                    local ItemText = Instance.new("TextLabel")

                    Item.Name = "Item"
                    Item.Parent = DropItemHolder
                    Item.BackgroundColor3 = Color3.fromRGB(42, 44, 48)
                    Item.Size = UDim2.new(0, math.floor(379 * Config.UIScale), 0, math.floor(29 * Config.UIScale))
                    Item.AutoButtonColor = false
                    Item.Font = Enum.Font.SourceSans
                    Item.Text = ""
                    Item.TextColor3 = Color3.fromRGB(0, 0, 0)
                    Item.TextSize = math.floor(14 * Config.UIScale)
                    Item.BackgroundTransparency = 1

                    ItemCorner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
                    ItemCorner.Name = "ItemCorner"
                    ItemCorner.Parent = Item

                    ItemText.Name = "ItemText"
                    ItemText.Parent = Item
                    ItemText.BackgroundColor3 = Color3.fromRGB(42, 44, 48)
                    ItemText.BackgroundTransparency = 1.000
                    ItemText.Position = UDim2.new(0.0211081803, 0, 0, 0)
                    ItemText.Size = UDim2.new(0, math.floor(192 * Config.UIScale), 0, math.floor(29 * Config.UIScale))
                    ItemText.Font = Enum.Font.Gotham
                    ItemText.TextColor3 = Color3.fromRGB(212, 212, 212)
                    ItemText.TextSize = math.floor(14 * Config.UIScale)
                    ItemText.TextXAlignment = Enum.TextXAlignment.Left
                    ItemText.Text = v
                    
                    Item.MouseEnter:Connect(function()
                        ItemText.TextColor3 = Color3.fromRGB(255,255,255)
                        Item.BackgroundTransparency = 0
                    end)
                    
                    Item.MouseLeave:Connect(function()
                        ItemText.TextColor3 = Color3.fromRGB(212, 212, 212)
                        Item.BackgroundTransparency = 1
                    end)
                    
                    Item.MouseButton1Click:Connect(function()
                        CurrentSelectedText.Text = v
                        pcall(callback, v)
                        Dropdown.Size = UDim2.new(0, math.floor(403 * Config.UIScale), 0, math.floor(73 * Config.UIScale))
                        DropdownFrameMain.Visible = false
                        DropdownFrameMainOutline.Visible = false
                        ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
                        DropTog = not DropTog
                    end)
                    
                    DropItemHolder.CanvasSize = UDim2.new(0,0,0,DropItemHolderLayout.AbsoluteContentSize.Y)
                    
                    DropItemHolder.Size = UDim2.new(0, math.floor(385 * Config.UIScale), 0, framesize)
                    DropdownFrameMain.Size = UDim2.new(0, math.floor(392 * Config.UIScale), 0, framesize + math.floor(6 * Config.UIScale))
                    DropdownFrameMainOutline.Size = UDim2.new(0, math.floor(396 * Config.UIScale), 0, framesize + math.floor(10 * Config.UIScale))
                end
                
                ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
                
                function DropFunc:Clear()
                    for i,v in next, DropItemHolder:GetChildren() do
                        if v.Name == "Item" then
                            v:Destroy()
                        end
                    end						
                    
                    CurrentSelectedText.Text = "..."
                    
                    itemcount = 0
                    framesize = 0
                    DropItemHolder.Size = UDim2.new(0, math.floor(385 * Config.UIScale), 0, 0)
                    DropdownFrameMain.Size = UDim2.new(0, math.floor(392 * Config.UIScale), 0, 0)
                    DropdownFrameMainOutline.Size = UDim2.new(0, math.floor(396 * Config.UIScale), 0, 0)
                    Dropdown.Size = UDim2.new(0, math.floor(403 * Config.UIScale), 0, math.floor(73 * Config.UIScale))
                    DropdownFrameMain.Visible = false
                    DropdownFrameMainOutline.Visible = false
                    ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
                end
                
                function DropFunc:Add(textadd)
                    itemcount = itemcount + 1

                    if itemcount == 1 then
                        framesize = math.floor(29 * Config.UIScale)
                    elseif itemcount == 2 then
                        framesize = math.floor(58 * Config.UIScale)
                    elseif itemcount >= 3 then
                        framesize = math.floor(87 * Config.UIScale)
                    end

                    local Item = Instance.new("TextButton")
                    local ItemCorner = Instance.new("UICorner")
                    local ItemText = Instance.new("TextLabel")

                    Item.Name = "Item"
                    Item.Parent = DropItemHolder
                    Item.BackgroundColor3 = Color3.fromRGB(42, 44, 48)
                    Item.Size = UDim2.new(0, math.floor(379 * Config.UIScale), 0, math.floor(29 * Config.UIScale))
                    Item.AutoButtonColor = false
                    Item.Font = Enum.Font.SourceSans
                    Item.Text = ""
                    Item.TextColor3 = Color3.fromRGB(0, 0, 0)
                    Item.TextSize = math.floor(14 * Config.UIScale)
                    Item.BackgroundTransparency = 1

                    ItemCorner.CornerRadius = UDim.new(0, math.floor(4 * Config.UIScale))
                    ItemCorner.Name = "ItemCorner"
                    ItemCorner.Parent = Item

                    ItemText.Name = "ItemText"
                    ItemText.Parent = Item
                    ItemText.BackgroundColor3 = Color3.fromRGB(42, 44, 48)
                    ItemText.BackgroundTransparency = 1.000
                    ItemText.Position = UDim2.new(0.0211081803, 0, 0, 0)
                    ItemText.Size = UDim2.new(0, math.floor(192 * Config.UIScale), 0, math.floor(29 * Config.UIScale))
                    ItemText.Font = Enum.Font.Gotham
                    ItemText.TextColor3 = Color3.fromRGB(212, 212, 212)
                    ItemText.TextSize = math.floor(14 * Config.UIScale)
                    ItemText.TextXAlignment = Enum.TextXAlignment.Left
                    ItemText.Text = textadd

                    Item.MouseEnter:Connect(function()
                        ItemText.TextColor3 = Color3.fromRGB(255,255,255)
                        Item.BackgroundTransparency = 0
                    end)

                    Item.MouseLeave:Connect(function()
                        ItemText.TextColor3 = Color3.fromRGB(212, 212, 212)
                        Item.BackgroundTransparency = 1
                    end)

                    Item.MouseButton1Click:Connect(function()
                        CurrentSelectedText.Text = textadd
                        pcall(callback, textadd)
                        Dropdown.Size = UDim2.new(0, math.floor(403 * Config.UIScale), 0, math.floor(73 * Config.UIScale))
                        DropdownFrameMain.Visible = false
                        DropdownFrameMainOutline.Visible = false
                        ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
                        DropTog = not DropTog
                    end)

                    DropItemHolder.CanvasSize = UDim2.new(0,0,0,DropItemHolderLayout.AbsoluteContentSize.Y)

                    DropItemHolder.Size = UDim2.new(0, math.floor(385 * Config.UIScale), 0, framesize)
                    DropdownFrameMain.Size = UDim2.new(0, math.floor(392 * Config.UIScale), 0, framesize + math.floor(6 * Config.UIScale))
                    DropdownFrameMainOutline.Size = UDim2.new(0, math.floor(396 * Config.UIScale), 0, framesize + math.floor(10 * Config.UIScale))
                end
                return DropFunc
            end
            
            function ChannelContent:Colorpicker(text, preset, callback)
                local Colorpicker = Instance.new("Frame")
                local ColorpickerTitle = Instance.new("TextLabel")
                local ColorpickerFrameOutline = Instance.new("Frame")
                local ColorpickerFrameOutlineCorner = Instance.new("UICorner")
                local ColorpickerFrame = Instance.new("Frame")
                local ColorpickerFrameCorner = Instance.new("UICorner")
                local Color = Instance.new("ImageLabel")
                local ColorCorner = Instance.new("UICorner")
                local ColorSelection = Instance.new("ImageLabel")
                local Hue = Instance.new("ImageLabel")
                local HueCorner = Instance.new("UICorner")
                local HueGradient = Instance.new("UIGradient")
                local HueSelection = Instance.new("ImageLabel")
                local PresetClr = Instance.new("Frame")
                local PresetClrCorner = Instance.new("UICorner")
                
                local ColorH, ColorS, ColorV = 1, 1, 1
                local ColorInput = nil
                local HueInput = nil

                Colorpicker.Name = "Colorpicker"
                Colorpicker.Parent = ChannelHolder
                Colorpicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Colorpicker.BackgroundTransparency = 1.000
                Colorpicker.Position = UDim2.new(0.0895741582, 0, 0.474232763, 0)
                Colorpicker.Size = UDim2.new(0, math.floor(403 * Config.UIScale), 0, math.floor(175 * Config.UIScale))

                ColorpickerTitle.Name = "ColorpickerTitle"
                ColorpickerTitle.Parent = Colorpicker
                ColorpickerTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ColorpickerTitle.BackgroundTransparency = 1.000
                ColorpickerTitle.Position = UDim2.new(0, math.floor(5 * Config.UIScale), 0, 0)
                ColorpickerTitle.Size = UDim2.new(0, math.floor(200 * Config.UIScale), 0, math.floor(29 * Config.UIScale))
                ColorpickerTitle.Font = Enum.Font.Gotham
                ColorpickerTitle.Text = text
                ColorpickerTitle.TextColor3 = Color3.fromRGB(127, 131, 137)
                ColorpickerTitle.TextSize = math.floor(14 * Config.UIScale)
                ColorpickerTitle.TextXAlignment = Enum.TextXAlignment.Left

                ColorpickerFrameOutline.Name = "ColorpickerFrameOutline"
                ColorpickerFrameOutline.Parent = ColorpickerTitle
                ColorpickerFrameOutline.BackgroundColor3 = Color3.fromRGB(37, 40, 43)
                ColorpickerFrameOutline.Position = UDim2.new(-0.00100000005, 0, 0.991999984, 0)
                ColorpickerFrameOutline.Size = UDim2.new(0, math.floor(238 * Config.UIScale), 0, math.floor(139 * Config.UIScale))

                ColorpickerFrameOutlineCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                ColorpickerFrameOutlineCorner.Name = "ColorpickerFrameOutlineCorner"
                ColorpickerFrameOutlineCorner.Parent = ColorpickerFrameOutline

                ColorpickerFrame.Name = "ColorpickerFrame"
                ColorpickerFrame.Parent = ColorpickerTitle
                ColorpickerFrame.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
                ColorpickerFrame.ClipsDescendants = true
                ColorpickerFrame.Position = UDim2.new(0.00999999978, 0, 1.06638515, 0)
                ColorpickerFrame.Selectable = true
                ColorpickerFrame.Size = UDim2.new(0, math.floor(234 * Config.UIScale), 0, math.floor(135 * Config.UIScale))

                ColorpickerFrameCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                ColorpickerFrameCorner.Name = "ColorpickerFrameCorner"
                ColorpickerFrameCorner.Parent = ColorpickerFrame

                Color.Name = "Color"
                Color.Parent = ColorpickerFrame
                Color.BackgroundColor3 = Color3.fromRGB(255, 0, 4)
                Color.Position = UDim2.new(0, math.floor(10 * Config.UIScale), 0, math.floor(10 * Config.UIScale))
                Color.Size = UDim2.new(0, math.floor(154 * Config.UIScale), 0, math.floor(118 * Config.UIScale))
                Color.ZIndex = 10
                Color.Image = "rbxassetid://4155801252"

                ColorCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                ColorCorner.Name = "ColorCorner"
                ColorCorner.Parent = Color

                ColorSelection.Name = "ColorSelection"
                ColorSelection.Parent = Color
                ColorSelection.AnchorPoint = Vector2.new(0.5, 0.5)
                ColorSelection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ColorSelection.BackgroundTransparency = 1.000
                ColorSelection.Position = UDim2.new(preset and select(3, Color3.toHSV(preset)) or 0, 0, preset and select(3, Color3.toHSV(preset)) or 0, 0)
                ColorSelection.Size = UDim2.new(0, math.floor(18 * Config.UIScale), 0, math.floor(18 * Config.UIScale))
                ColorSelection.Image = "http://www.roblox.com/asset/?id=4805639000"
                ColorSelection.ScaleType = Enum.ScaleType.Fit

                Hue.Name = "Hue"
                Hue.Parent = ColorpickerFrame
                Hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Hue.Position = UDim2.new(0, math.floor(171 * Config.UIScale), 0, math.floor(10 * Config.UIScale))
                Hue.Size = UDim2.new(0, math.floor(18 * Config.UIScale), 0, math.floor(118 * Config.UIScale))

                HueCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                HueCorner.Name = "HueCorner"
                HueCorner.Parent = Hue

                HueGradient.Color = ColorSequence.new {
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)),
                    ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)),
                    ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)),
                    ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)),
                    ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
                }				
                HueGradient.Rotation = 270
                HueGradient.Name = "HueGradient"
                HueGradient.Parent = Hue

                HueSelection.Name = "HueSelection"
                HueSelection.Parent = Hue
                HueSelection.AnchorPoint = Vector2.new(0.5, 0.5)
                HueSelection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HueSelection.BackgroundTransparency = 1.000
                HueSelection.Position = UDim2.new(0.48, 0, 1 - (preset and select(1, Color3.toHSV(preset)) or 1), 0)
                HueSelection.Size = UDim2.new(0, math.floor(18 * Config.UIScale), 0, math.floor(18 * Config.UIScale))
                HueSelection.Image = "http://www.roblox.com/asset/?id=4805639000"

                PresetClr.Name = "PresetClr"
                PresetClr.Parent = ColorpickerFrame
                PresetClr.BackgroundColor3 = preset or Config.AccentColor
                PresetClr.Position = UDim2.new(0.846153855, 0, 0.0740740746, 0)
                PresetClr.Size = UDim2.new(0, math.floor(25 * Config.UIScale), 0, math.floor(25 * Config.UIScale))

                PresetClrCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                PresetClrCorner.Name = "PresetClrCorner"
                PresetClrCorner.Parent = PresetClr
                
                local function UpdateColorPicker()
                    PresetClr.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                    Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
                    pcall(callback, PresetClr.BackgroundColor3)
                end

                if preset then
                    ColorH, ColorS, ColorV = Color3.toHSV(preset)
                end
                
                Color.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if ColorInput then ColorInput:Disconnect() end
                        ColorInput = RunService.RenderStepped:Connect(function()
                            local ColorX = math.clamp((Mouse.X - Color.AbsolutePosition.X) / Color.AbsoluteSize.X, 0, 1)
                            local ColorY = math.clamp((Mouse.Y - Color.AbsolutePosition.Y) / Color.AbsoluteSize.Y, 0, 1)
                            ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
                            ColorS = ColorX
                            ColorV = 1 - ColorY
                            UpdateColorPicker()
                        end)
                    end
                end)

                Color.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if ColorInput then ColorInput:Disconnect() end
                    end
                end)

                Hue.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if HueInput then HueInput:Disconnect() end
                        HueInput = RunService.RenderStepped:Connect(function()
                            local HueY = math.clamp((Mouse.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y, 0, 1)
                            HueSelection.Position = UDim2.new(0.48, 0, HueY, 0)
                            ColorH = 1 - HueY
                            UpdateColorPicker()
                        end)
                    end
                end)

                Hue.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if HueInput then HueInput:Disconnect() end
                    end
                end)
                
                ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
            end
            
            function ChannelContent:Textbox(text, placetext, disapper, callback)
                local Textbox = Instance.new("Frame")
                local TextboxTitle = Instance.new("TextLabel")
                local TextboxFrameOutline = Instance.new("Frame")
                local TextboxFrameOutlineCorner = Instance.new("UICorner")
                local TextboxFrame = Instance.new("Frame")
                local TextboxFrameCorner = Instance.new("UICorner")
                local TextBox = Instance.new("TextBox")

                Textbox.Name = "Textbox"
                Textbox.Parent = ChannelHolder
                Textbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Textbox.BackgroundTransparency = 1.000
                Textbox.Position = UDim2.new(0.0796874985, 0, 0.445175439, 0)
                Textbox.Size = UDim2.new(0, math.floor(403 * Config.UIScale), 0, math.floor(73 * Config.UIScale))

                TextboxTitle.Name = "TextboxTitle"
                TextboxTitle.Parent = Textbox
                TextboxTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextboxTitle.BackgroundTransparency = 1.000
                TextboxTitle.Position = UDim2.new(0, math.floor(5 * Config.UIScale), 0, 0)
                TextboxTitle.Size = UDim2.new(0, math.floor(200 * Config.UIScale), 0, math.floor(29 * Config.UIScale))
                TextboxTitle.Font = Enum.Font.Gotham
                TextboxTitle.Text = text
                TextboxTitle.TextColor3 = Color3.fromRGB(127, 131, 137)
                TextboxTitle.TextSize = math.floor(14 * Config.UIScale)
                TextboxTitle.TextXAlignment = Enum.TextXAlignment.Left

                TextboxFrameOutline.Name = "TextboxFrameOutline"
                TextboxFrameOutline.Parent = TextboxTitle
                TextboxFrameOutline.AnchorPoint = Vector2.new(0.5, 0.5)
                TextboxFrameOutline.BackgroundColor3 = Color3.fromRGB(37, 40, 43)
                TextboxFrameOutline.Position = UDim2.new(0.988442957, 0, 1.6197437, 0)
                TextboxFrameOutline.Size = UDim2.new(0, math.floor(396 * Config.UIScale), 0, math.floor(36 * Config.UIScale))

                TextboxFrameOutlineCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                TextboxFrameOutlineCorner.Name = "TextboxFrameOutlineCorner"
                TextboxFrameOutlineCorner.Parent = TextboxFrameOutline

                TextboxFrame.Name = "TextboxFrame"
                TextboxFrame.Parent = TextboxTitle
                TextboxFrame.BackgroundColor3 = Color3.fromRGB(48, 51, 57)
                TextboxFrame.ClipsDescendants = true
                TextboxFrame.Position = UDim2.new(0.00999999978, 0, 1.06638527, 0)
                TextboxFrame.Selectable = true
                TextboxFrame.Size = UDim2.new(0, math.floor(392 * Config.UIScale), 0, math.floor(32 * Config.UIScale))

                TextboxFrameCorner.CornerRadius = UDim.new(0, math.floor(3 * Config.UIScale))
                TextboxFrameCorner.Name = "TextboxFrameCorner"
                TextboxFrameCorner.Parent = TextboxFrame

                TextBox.Parent = TextboxFrame
                TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextBox.BackgroundTransparency = 1.000
                TextBox.Position = UDim2.new(0.0178571437, 0, 0, 0)
                TextBox.Size = UDim2.new(0, math.floor(377 * Config.UIScale), 0, math.floor(32 * Config.UIScale))
                TextBox.Font = Enum.Font.Gotham
                TextBox.PlaceholderColor3 = Color3.fromRGB(91, 95, 101)
                TextBox.PlaceholderText = placetext
                TextBox.Text = ""
                TextBox.TextColor3 = Color3.fromRGB(193, 195, 197)
                TextBox.TextSize = math.floor(14 * Config.UIScale)
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                
                TextBox.Focused:Connect(function()
                    TweenService:Create(
                        TextboxFrameOutline,
                        TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {BackgroundColor3 = Color3.fromRGB(114, 137, 228)}
                    ):Play()
                end)
                
                TextBox.FocusLost:Connect(function(ep)
                    TweenService:Create(
                        TextboxFrameOutline,
                        TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {BackgroundColor3 = Color3.fromRGB(37, 40, 43)}
                    ):Play()
                    if ep then
                        if #TextBox.Text > 0 then
                            pcall(callback, TextBox.Text)
                            if disapper then
                                TextBox.Text = ""
                            end
                        end
                    end
                end)
                
                ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
            end
            
            function ChannelContent:Label(text)
                local Label = Instance.new("TextButton")
                local LabelTitle = Instance.new("TextLabel")

                Label.Name = "Label"
                Label.Parent = ChannelHolder
                Label.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
                Label.BorderSizePixel = 0
                Label.Position = UDim2.new(0.261979163, 0, 0.190789461, 0)
                Label.Size = UDim2.new(0, math.floor(401 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
                Label.AutoButtonColor = false
                Label.Font = Enum.Font.Gotham
                Label.Text = ""
                Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                Label.TextSize = math.floor(14 * Config.UIScale)

                LabelTitle.Name = "LabelTitle"
                LabelTitle.Parent = Label
                LabelTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                LabelTitle.BackgroundTransparency = 1.000
                LabelTitle.Position = UDim2.new(0, math.floor(5 * Config.UIScale), 0, 0)
                LabelTitle.Size = UDim2.new(0, math.floor(200 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
                LabelTitle.Font = Enum.Font.Gotham
                LabelTitle.Text = text
                LabelTitle.TextColor3 = Color3.fromRGB(127, 131, 137)
                LabelTitle.TextSize = math.floor(14 * Config.UIScale)
                LabelTitle.TextXAlignment = Enum.TextXAlignment.Left
                
                ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
            end
            
            function ChannelContent:Bind(text, presetbind, callback)
                local Key = presetbind.Name
                local Keybind = Instance.new("TextButton")
                local KeybindTitle = Instance.new("TextLabel")
                local KeybindText = Instance.new("TextLabel")

                Keybind.Name = "Keybind"
                Keybind.Parent = ChannelHolder
                Keybind.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
                Keybind.BorderSizePixel = 0
                Keybind.Position = UDim2.new(0.261979163, 0, 0.190789461, 0)
                Keybind.Size = UDim2.new(0, math.floor(401 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
                Keybind.AutoButtonColor = false
                Keybind.Font = Enum.Font.Gotham
                Keybind.Text = ""
                Keybind.TextColor3 = Color3.fromRGB(255, 255, 255)
                Keybind.TextSize = math.floor(14 * Config.UIScale)

                KeybindTitle.Name = "KeybindTitle"
                KeybindTitle.Parent = Keybind
                KeybindTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindTitle.BackgroundTransparency = 1.000
                KeybindTitle.Position = UDim2.new(0, math.floor(5 * Config.UIScale), 0, 0)
                KeybindTitle.Size = UDim2.new(0, math.floor(200 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
                KeybindTitle.Font = Enum.Font.Gotham
                KeybindTitle.Text = text
                KeybindTitle.TextColor3 = Color3.fromRGB(127, 131, 137)
                KeybindTitle.TextSize = math.floor(14 * Config.UIScale)
                KeybindTitle.TextXAlignment = Enum.TextXAlignment.Left

                KeybindText.Name = "KeybindText"
                KeybindText.Parent = Keybind
                KeybindText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindText.BackgroundTransparency = 1.000
                KeybindText.Position = UDim2.new(0, math.floor(316 * Config.UIScale), 0, 0)
                KeybindText.Size = UDim2.new(0, math.floor(85 * Config.UIScale), 0, math.floor(30 * Config.UIScale))
                KeybindText.Font = Enum.Font.Gotham
                KeybindText.Text = presetbind.Name
                KeybindText.TextColor3 = Color3.fromRGB(127, 131, 137)
                KeybindText.TextSize = math.floor(14 * Config.UIScale)
                KeybindText.TextXAlignment = Enum.TextXAlignment.Right
                
                Keybind.MouseButton1Click:Connect(function()
                    KeybindText.Text = "..."
                    local inputwait = game:GetService("UserInputService").InputBegan:wait()
                    if inputwait.KeyCode.Name ~= "Unknown" then
                        KeybindText.Text = inputwait.KeyCode.Name
                        Key = inputwait.KeyCode.Name
                    end
                end)
                
                game:GetService("UserInputService").InputBegan:connect(
                    function(current, pressed)
                        if not pressed then
                            if current.KeyCode.Name == Key then
                                pcall(callback)
                            end
                        end
                    end
                )
                ChannelHolder.CanvasSize = UDim2.new(0,0,0,ChannelHolderLayout.AbsoluteContentSize.Y)
            end
            
            return ChannelContent
        end
        
        return ChannelHold
    end
    
    ServerHold.Notify = function(titletext, desctext, btntext, notifType, duration)
        return AYXDiscordUILibrary:Notify(titletext, desctext, btntext, notifType, duration)
    end
    
    return ServerHold
end

-- 主题系统
function AYXDiscordUILibrary:SetTheme(theme)
    if theme == "Dark" then
        Config.BackgroundColor = Color3.fromRGB(32, 34, 37)
        Config.SecondaryColor = Color3.fromRGB(47, 49, 54)
        Config.TextColor = Color3.fromRGB(255, 255, 255)
    elseif theme == "Light" then
        Config.BackgroundColor = Color3.fromRGB(255, 255, 255)
        Config.SecondaryColor = Color3.fromRGB(240, 240, 240)
        Config.TextColor = Color3.fromRGB(0, 0, 0)
    elseif theme == "Custom" then
    end
    Config.Theme = theme
end

function AYXDiscordUILibrary:SetAccentColor(color)
    Config.AccentColor = color
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

function AYXDiscordUILibrary:ToggleBlur(enabled)
    Config.EnableBlur = enabled
    SetBlur(enabled)
end

function AYXDiscordUILibrary:GetConfig()
    return Config
end

function AYXDiscordUILibrary:SaveConfig()
    if Config.SaveSettings then
        writefile("ayxdiscordlib_config.txt", HttpService:JSONEncode(Config))
    end
end

function AYXDiscordUILibrary:LoadConfig()
    if Config.SaveSettings then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile("ayxdiscordlib_config.txt"))
        end)
        if success then
            Config = result
        end
    end
end

function AYXDiscordUILibrary:SetColor(which, color)
    if Config[which] ~= nil then
        if typeof(color) == "Color3" then
            Config[which] = color
        elseif typeof(color) == "boolean" then
            Config[which] = color
        elseif typeof(color) == "number" then
            Config[which] = color
        end
    end
end

function AYXDiscordUILibrary:SetThemeColors(tbl)
    for k, v in pairs(tbl) do
        if Config[k] ~= nil and typeof(v) == "Color3" then
            Config[k] = v
        end
    end
end

function AYXDiscordUILibrary:SaveTheme(name)
    if typeof(name) ~= "string" then return end
    local theme = {
        AccentColor = Config.AccentColor,
        BackgroundColor = Config.BackgroundColor,
        TextColor = Config.TextColor,
        SecondaryColor = Config.SecondaryColor,
        EnableRainbowMode = Config.EnableRainbowMode,
        EnableParticles = Config.EnableParticles,
        EnableTooltips = Config.EnableTooltips,
        EnableMouseEffects = Config.EnableMouseEffects,
        EnablePerformanceMode = Config.EnablePerformanceMode,
        EnableSmoothScrolling = Config.EnableSmoothScrolling
    }
    writefile("ayxdiscordlib_theme_"..name..".txt", HttpService:JSONEncode(theme))
end

function AYXDiscordUILibrary:LoadTheme(name)
    if typeof(name) ~= "string" then return end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile("ayxdiscordlib_theme_"..name..".txt"))
    end)
    if success and typeof(data) == "table" then
        for k, v in pairs(data) do
            if Config[k] ~= nil then
                Config[k] = v
            end
        end
    end
end

-- 彩虹模式
spawn(function()
    while wait(0.1) do
        if Config.EnableRainbowMode then
            local hue = tick() % 1
            Config.AccentColor = Color3.fromHSV(hue, 1, 1)
        end
    end
end)

-- 自动保存
if Config.AutoSave then
    spawn(function()
        while wait(30) do
            AYXDiscordUILibrary:SaveConfig()
        end
    end)
end

UpdateHoverColors()

return AYXDiscordUILibrary