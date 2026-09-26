-- bf_tool.lua
-- Target: Roblox 2.738.1397 / Delta executor
-- GUI hiển thị ngay, không phụ thuộc splash

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local LP = Players.LocalPlayer

-- Lấy PlayerGui an toàn, fallback CoreGui nếu không có
local function getGuiParent()
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then return pg end
    if gethui then
        local h = gethui()
        if h then return h end
    end
    local cg = game:GetService("CoreGui")
    if cg then return cg end
    return LP:WaitForChild("PlayerGui", 30)
end

local cfg = {
    autoFarm   = false,
    autoStat   = false,
    autoMelee  = false,
    autoAttack = false,
    autoQuest  = false,
    fly        = false,
    vacuum     = false,
    statTarget = "Melee",
    farmMode   = "Level",
    toggleKey  = Enum.KeyCode.RightShift,
    flySpeed   = 120,
    vacuumRadius = 120,
}

local islands = {
    {lv=1,   pos=Vector3.new(0, 10, 0)},
    {lv=15,  pos=Vector3.new(-600, 10, 400)},
    {lv=30,  pos=Vector3.new(1200, 10, 200)},
    {lv=60,  pos=Vector3.new(-1300, 10, -200)},
    {lv=90,  pos=Vector3.new(1300, 10, -900)},
    {lv=120, pos=Vector3.new(-1500, 10, 1500)},
    {lv=150, pos=Vector3.new(0, 800, 0)},
    {lv=200, pos=Vector3.new(-5000, 10, 3000)},
    {lv=250, pos=Vector3.new(5000, 10, -3000)},
    {lv=300, pos=Vector3.new(-2000, 10, -4000)},
    {lv=375, pos=Vector3.new(6000, 10, 6000)},
    {lv=450, pos=Vector3.new(-6000, 10, -6000)},
    {lv=600, pos=Vector3.new(3000, 10, 8000)},
    {lv=700, pos=Vector3.new(0, 10, 20000)},
}

-- ===== HELPERS =====
local function getChar()
    local c = LP.Character
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return nil end
    return c, h, r
end

local function getLevel()
    local d = LP:FindFirstChild("Data")
    if d and d:FindFirstChild("Level") then return d.Level.Value end
    local ls = LP:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Level") then return ls.Level.Value end
    return 0
end

local function getStatPoints()
    local d = LP:FindFirstChild("Data")
    if d and d:FindFirstChild("StatPoints") then return d.StatPoints.Value end
    return 0
end

local CommF
local function getCommF()
    if CommF and CommF.Parent then return CommF end
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if r then CommF = r:FindFirstChild("CommF_") end
    return CommF
end

local function invoke(...)
    local rem = getCommF()
    if rem then pcall(function() rem:InvokeServer(...) end) end
end

-- ===== FEATURE TICKS =====
local function farmTick()
    if not cfg.autoFarm or cfg.farmMode ~= "Level" then return end
    local _, _, hrp = getChar()
    if not hrp then return end
    local lv = getLevel()
    local target = islands[1]
    for _, isl in ipairs(islands) do
        if lv >= isl.lv then target = isl end
    end
    if (hrp.Position - target.pos).Magnitude < 50 then return end
    hrp.CFrame = CFrame.new(target.pos)
end

local function statTick()
    if not cfg.autoStat then return end
    if getStatPoints() <= 0 then return end
    invoke("AddPoint", cfg.statTarget)
end

local function meleeTick()
    if not cfg.autoMelee then return end
    local char, hum = getChar()
    if not char or not hum then return end
    if char:FindFirstChildOfClass("Tool") then return end
    local bp = LP:FindFirstChild("Backpack")
    if not bp then return end
    local tool = bp:FindFirstChild("Combat") or bp:FindFirstChildOfClass("Tool")
    if tool then pcall(function() hum:EquipTool(tool) end) end
end

local function questTick()
    if not cfg.autoQuest then return end
    local gui = LP.PlayerGui and LP.PlayerGui:FindFirstChild("Main")
    local quest = gui and gui:FindFirstChild("Quest")
    if not quest or not quest.Visible then invoke("StartQuest") end
end

local attackConn
local function startAttack()
    if attackConn then attackConn:Disconnect() end
    attackConn = RunService.Heartbeat:Connect(function()
        if not cfg.autoAttack then return end
        local char = LP.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
        end)
    end)
end

local flyBV, flyBG, flyConn
local function startFly()
    local _, hum, hrp = getChar()
    if not hrp or not hum then return end
    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1e4
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        if not cfg.fly then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
        if move.Magnitude > 0 then flyBV.Velocity = move.Unit * cfg.flySpeed else flyBV.Velocity = Vector3.zero end
        flyBG.CFrame = cam.CFrame
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local _, hum = getChar()
    if hum then hum.PlatformStand = false end
end

local vacuumConn
local function startVacuum()
    if vacuumConn then vacuumConn:Disconnect() end
    vacuumConn = RunService.Heartbeat:Connect(function()
        if not cfg.vacuum then return end
        local char, _, hrp = getChar()
        if not hrp then return end
        for _, m in ipairs(Workspace:GetChildren()) do
            if m ~= char then
                local hum = m:FindFirstChildOfClass("Humanoid")
                local root = m:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 and not Players:GetPlayerFromCharacter(m) then
                    if (root.Position - hrp.Position).Magnitude <= cfg.vacuumRadius then
                        pcall(function() root.CFrame = hrp.CFrame * CFrame.new(0, 0, -3) end)
                    end
                end
            end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    pcall(farmTick)
    pcall(statTick)
    pcall(meleeTick)
    pcall(questTick)
end)

-- ===== BUILD GUI =====
local function buildGui()
    local parent = getGuiParent()
    if not parent then
        warn("[BF Tool] no gui parent")
        return
    end

    -- xóa GUI cũ nếu tồn tại
    for _, name in ipairs({"BF_Tool_v3", "BF_Splash"}) do
        local old = parent:FindFirstChild(name)
        if old then old:Destroy() end
        local oldCore = game:GetService("CoreGui"):FindFirstChild(name)
        if oldCore then oldCore:Destroy() end
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "BF_Tool_v3"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = 10
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 260, 0, 470)
    frame.Position = UDim2.new(0, 20, 0.5, -235)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Visible = true
    frame.Parent = screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    title.BorderSizePixel = 0
    title.Text = "  BF Tool v3"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = frame

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 8)
    tc.Parent = title

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 24, 0, 24)
    close.Position = UDim2.new(1, -30, 0, 4)
    close.BackgroundTransparency = 1
    close.Text = "×"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextSize = 20
    close.Font = Enum.Font.GothamBold
    close.Parent = title
    close.MouseButton1Click:Connect(function()
        frame.Visible = false
    end)

    local function makeToggle(y, label, key, onEnable, onDisable)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 220, 0, 32)
        btn.Position = UDim2.new(0, 20, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = frame

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = btn

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.Parent = btn

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 40, 0, 18)
        dot.Position = UDim2.new(1, -52, 0.5, -9)
        dot.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        dot.BorderSizePixel = 0
        dot.Parent = btn

        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = dot

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new(0, 2, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        knob.BorderSizePixel = 0
        knob.Parent = dot

        local kc = Instance.new("UICorner")
        kc.CornerRadius = UDim.new(1, 0)
        kc.Parent = knob

        local state = false
        btn.MouseButton1Click:Connect(function()
            state = not state
            cfg[key] = state
            if state then
                dot.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
                TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(1, -16, 0.5, -7)}):Play()
                if onEnable then pcall(onEnable) end
            else
                dot.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -7)}):Play()
                if onDisable then pcall(onDisable) end
            end
        end)
    end

    makeToggle(38,  "Auto Farm Level",  "autoFarm")
    makeToggle(74,  "Auto Add Stat",    "autoStat")
    makeToggle(110, "Auto Equip Melee", "autoMelee")
    makeToggle(146, "Auto Attack",      "autoAttack", startAttack)
    makeToggle(182, "Auto Quest",       "autoQuest")
    makeToggle(218, "Fly (WASD/Space)", "fly", startFly, stopFly)
    makeToggle(254, "Mob Vacuum",       "vacuum", startVacuum)

    local statLabel = Instance.new("TextLabel")
    statLabel.Size = UDim2.new(0, 220, 0, 18)
    statLabel.Position = UDim2.new(0, 20, 0, 292)
    statLabel.BackgroundTransparency = 1
    statLabel.Text = "Stat target:"
    statLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    statLabel.TextXAlignment = Enum.TextXAlignment.Left
    statLabel.Font = Enum.Font.Gotham
    statLabel.TextSize = 12
    statLabel.Parent = frame

    local stats = {"Melee", "Defense", "Sword", "Gun", "Fruit"}
    local sb = Instance.new("TextButton")
    sb.Size = UDim2.new(0, 220, 0, 30)
    sb.Position = UDim2.new(0, 20, 0, 312)
    sb.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    sb.BorderSizePixel = 0
    sb.Text = cfg.statTarget
    sb.TextColor3 = Color3.fromRGB(255, 255, 255)
    sb.Font = Enum.Font.Gotham
    sb.TextSize = 13
    sb.Parent = frame

    local sbc = Instance.new("UICorner")
    sbc.CornerRadius = UDim.new(0, 6)
    sbc.Parent = sb

    local idx = 1
    sb.MouseButton1Click:Connect(function()
        idx = idx % #stats + 1
        cfg.statTarget = stats[idx]
        sb.Text = cfg.statTarget
    end)

    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(0, 220, 0, 18)
    modeLabel.Position = UDim2.new(0, 20, 0, 348)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = "Farm mode:"
    modeLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.TextSize = 12
    modeLabel.Parent = frame

    local modes = {"Level", "Money", "Mastery"}
    local mb = Instance.new("TextButton")
    mb.Size = UDim2.new(0, 220, 0, 30)
    mb.Position = UDim2.new(0, 20, 0, 368)
    mb.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    mb.BorderSizePixel = 0
    mb.Text = cfg.farmMode
    mb.TextColor3 = Color3.fromRGB(255, 255, 255)
    mb.Font = Enum.Font.Gotham
    mb.TextSize = 13
    mb.Parent = frame

    local mbc = Instance.new("UICorner")
    mbc.CornerRadius = UDim.new(0, 6)
    mbc.Parent = mb

    local midx = 1
    mb.MouseButton1Click:Connect(function()
        midx = midx % #modes + 1
        cfg.farmMode = modes[midx]
        mb.Text = cfg.farmMode
    end)

    local spdLabel = Instance.new("TextLabel")
    spdLabel.Size = UDim2.new(0, 220, 0, 18)
    spdLabel.Position = UDim2.new(0, 20, 0, 404)
    spdLabel.BackgroundTransparency = 1
    spdLabel.Text = "Fly speed: " .. cfg.flySpeed
    spdLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    spdLabel.TextXAlignment = Enum.TextXAlignment.Left
    spdLabel.Font = Enum.Font.Gotham
    spdLabel.TextSize = 12
    spdLabel.Parent = frame

    local function spdBtn(x, txt, delta)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 60, 0, 26)
        b.Position = UDim2.new(0, x, 0, 424)
        b.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        b.BorderSizePixel = 0
        b.Text = txt
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.Gotham
        b.TextSize = 13
        b.Parent = frame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = b
        b.MouseButton1Click:Connect(function()
            cfg.flySpeed = math.clamp(cfg.flySpeed + delta, 20, 500)
            spdLabel.Text = "Fly speed: " .. cfg.flySpeed
        end)
    end
    spdBtn(20, "-20", -20)
    spdBtn(90, "+20", 20)

    -- nút mở lại khi ẩn
    local reopen = Instance.new("TextButton")
    reopen.Name = "Reopen"
    reopen.Size = UDim2.new(0, 44, 0, 44)
    reopen.Position = UDim2.new(0, 20, 0.5, -22)
    reopen.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    reopen.BorderSizePixel = 0
    reopen.Text = "BF"
    reopen.TextColor3 = Color3.fromRGB(255, 255, 255)
    reopen.Font = Enum.Font.GothamBold
    reopen.TextSize = 14
    reopen.Visible = false
    reopen.Parent = screen

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(1, 0)
    rc.Parent = reopen

    reopen.MouseButton1Click:Connect(function()
        frame.Visible = true
        reopen.Visible = false
    end)

    local function setVisible(v)
        frame.Visible = v
        reopen.Visible = not v
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == cfg.toggleKey then
            setVisible(not frame.Visible)
        end
    end)

    print("[BF Tool] gui built in", parent:GetFullName())
    return screen
end

local ok, err = pcall(buildGui)
if not ok then
    warn("[BF Tool] gui error:", err)
end

LP.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

print("[BF Tool v3] loaded. Toggle: RightShift.")
