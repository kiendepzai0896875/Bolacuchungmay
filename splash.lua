-- splash.lua
-- Loader splash screen cho BF Tool
-- Gọi trước bf_tool.lua

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui", 20)

local BASE = "https://raw.githubusercontent.com/kiendepzai0896875/Bolacuchungmay/main/"
local LOGO = BASE .. "logo.png"
local SPLASH_BG = BASE .. "splash.png"

local splash = Instance.new("ScreenGui")
splash.Name = "BF_Splash"
splash.ResetOnSpawn = false
splash.IgnoreGuiInset = true
splash.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
splash.DisplayOrder = 999
splash.Parent = PG

local splashBg = Instance.new("Frame")
splashBg.Size = UDim2.new(1, 0, 1, 0)
splashBg.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
splashBg.BorderSizePixel = 0
splashBg.Parent = splash

local splashImg = Instance.new("ImageLabel")
splashImg.Size = UDim2.new(1, 0, 1, 0)
splashImg.BackgroundTransparency = 1
splashImg.Image = SPLASH_BG
splashImg.ScaleType = Enum.ScaleType.Crop
splashImg.Parent = splashBg

local splashTint = Instance.new("Frame")
splashTint.Size = UDim2.new(1, 0, 1, 0)
splashTint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
splashTint.BackgroundTransparency = 0.35
splashTint.BorderSizePixel = 0
splashTint.Parent = splashBg

local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 200, 0, 200)
logo.Position = UDim2.new(0.5, -100, 0.5, -140)
logo.BackgroundTransparency = 1
logo.Image = LOGO
logo.Parent = splashBg

local logoSpin = Instance.new("Frame")
logoSpin.Size = UDim2.new(0, 220, 0, 220)
logoSpin.Position = UDim2.new(0.5, -110, 0.5, -150)
logoSpin.BackgroundTransparency = 1
logoSpin.Parent = splashBg

local ring = Instance.new("ImageLabel")
ring.Size = UDim2.new(1, 0, 1, 0)
ring.BackgroundTransparency = 1
ring.Image = "rbxassetid://5028857084"
ring.ImageColor3 = Color3.fromRGB(120, 180, 255)
ring.Parent = logoSpin

TweenService:Create(ring, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()

local splashTitle = Instance.new("TextLabel")
splashTitle.Size = UDim2.new(1, 0, 0, 32)
splashTitle.Position = UDim2.new(0, 0, 0.5, 80)
splashTitle.BackgroundTransparency = 1
splashTitle.Text = "BF TOOL v3"
splashTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
splashTitle.Font = Enum.Font.GothamBold
splashTitle.TextSize = 26
splashTitle.Parent = splashBg

local splashSub = Instance.new("TextLabel")
splashSub.Size = UDim2.new(1, 0, 0, 22)
splashSub.Position = UDim2.new(0, 0, 0.5, 114)
splashSub.BackgroundTransparency = 1
splashSub.Text = "Đang tải..."
splashSub.TextColor3 = Color3.fromRGB(180, 200, 230)
splashSub.Font = Enum.Font.Gotham
splashSub.TextSize = 14
splashSub.Parent = splashBg

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0, 240, 0, 6)
barBg.Position = UDim2.new(0.5, -120, 0.5, 150)
barBg.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
barBg.BorderSizePixel = 0
barBg.Parent = splashBg

local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(1, 0)
barBgCorner.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

function _G.BFSplashFinish()
    if not splash.Parent then return end
    local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(splashBg, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(splashImg, fadeInfo, {ImageTransparency = 1}):Play()
    TweenService:Create(splashTint, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(logo, fadeInfo, {ImageTransparency = 1}):Play()
    TweenService:Create(ring, fadeInfo, {ImageTransparency = 1}):Play()
    TweenService:Create(splashTitle, fadeInfo, {TextTransparency = 1}):Play()
    TweenService:Create(splashSub, fadeInfo, {TextTransparency = 1}):Play()
    TweenService:Create(barBg, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(barFill, fadeInfo, {BackgroundTransparency = 1}):Play()
    task.wait(0.6)
    splash:Destroy()
end

-- auto chạy các bước rồi finish
task.spawn(function()
    local steps = {
        {0.15, 0.10, "Khởi tạo..."},
        {0.40, 0.35, "Nạp tài nguyên..."},
        {0.65, 0.20, "Đăng ký module..."},
        {0.85, 0.40, "Kết nối remote..."},
        {1.00, 0.30, "Hoàn tất."},
    }
    for _, s in ipairs(steps) do
        local target, dur, label = s[1], s[2], s[3]
        splashSub.Text = label
        local startVal = barFill.Size.X.Scale
        local startT = tick()
        while tick() - startT < dur do
            local t = (tick() - startT) / dur
            barFill.Size = UDim2.new(startVal + (target - startVal) * t, 0, 1, 0)
            task.wait()
        end
        barFill.Size = UDim2.new(target, 0, 1, 0)
    end
    task.wait(0.4)
    _G.BFSplashFinish()
end)

return true
