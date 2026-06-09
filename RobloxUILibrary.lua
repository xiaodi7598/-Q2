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
    -- 新增缩放配置
    UIScale = 0.8  -- 默认缩小到80%，适合手机电脑通用
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

-- 全局缩放变量
local 当前UI缩放 = Config.UIScale
local 缩放步长 = 0.05
local 最小缩放 = 0.5
local 最大缩放 = 1.2

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