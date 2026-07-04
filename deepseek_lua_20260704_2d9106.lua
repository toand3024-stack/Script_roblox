--[[
    FPS GOD MENU v16 ULTIMATE – TOANDINH STYLE UI (FIXED UI LAYOUT)
    - Sửa lỗi danh sách người chơi (Teleport, Sit on Head) bị đè, giờ có thể cuộn
    - Sửa giao diện Fake Lag trong Troll tab không bị đè
    - Giữ nguyên bố cục như v15
]]

-- ==================== DỊCH VỤ ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local NetworkClient = game:GetService("NetworkClient")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- ==================== CẤU HÌNH ====================
local Settings = {
    -- Combat
    Aimbot = false,
    AimbotSmooth = 10,
    ShowFOV = false,
    FOVSize = 100,
    FOVColor = "Red",
    SilentAim = false,
    TriggerBot = false,
    KillAura = false,
    KillAuraRadius = 20,
    AutoHeadshot = false,

    -- Visual
    BoxESP = false,
    NameESP = false,
    DistESP = false,
    HealthESP = false,
    Wallhack = false,
    RainbowESP = false,

    -- Misc
    InfAmmo = false,
    NoRecoil = false,
    FastFire = false,
    SpeedHack = false,
    SpeedValue = 32,
    Fly = false,
    FlySpeed = 50,
    HighJump = false,
    JumpPower = 100,
    Noclip = false,
    RemoveFallDamage = false,
    Godmode = false,

    -- Rage
    HitboxExpander = false,
    HitboxSize = 2,
    RapidFire = false,
    BulletTracer = false,
    CamLock = false,
    SpinBot = false,
    SpinSpeed = 10,
    FakeDeath = false,
    AutoFarmKill = false,

    -- Troll
    FakeLag = false,
    FakeLagIntensity = 100,
    ChatSpam = false,
    SpamMessage = "FPS GOD v16",
    SpamInterval = 3,
    SitOnHead = false,
    SitTarget = "",

    -- Stats
    StatKills = 999,
    StatDeaths = 1,
    StatLevel = 100,
    StatWins = 999,

    -- Anti-Ban
    AntiKick = false,
    AntiReport = false,
    AntiCheatBypass = false,
    AntiMod = false
}

local AimTarget = nil
local savedPitch = nil
local firing = false
local lastTriggerTime = 0
local lastWeaponCheck = 0
local espCache = {}
local highlightCache = {}
local chatSpamRunning = false
local tracerTable = {}
local rainbowHue = 0
local sitTargetChar = nil
local sitConnection = nil
local spinVel = nil
local lastESPUpdate = 0
local lastKillAuraUpdate = 0
local godmodeConnection = nil

-- Kiểm tra Drawing API
local DrawingSupported = pcall(function() local test = Drawing.new("Circle"); test:Remove() end)
if not DrawingSupported then
    Settings.ShowFOV = false
    Settings.BoxESP = false
    Settings.NameESP = false
    Settings.DistESP = false
    Settings.HealthESP = false
    Settings.Wallhack = false
    Settings.BulletTracer = false
end

-- ===================== ANTI-BAN =====================
local function hookPlayer(player)
    pcall(function()
        if player ~= LocalPlayer and not player.AntiBanHooked then
            local oldReport = hookfunction(player.ReportAbuse, function(...)
                if Settings.AntiReport then return nil end
                return oldReport(...)
            end)
            local oldKick = hookfunction(player.Kick, function(...)
                if Settings.AntiKick then return nil end
                return oldKick(...)
            end)
            player.AntiBanHooked = true
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(function(p) task.wait(0.5); hookPlayer(p) end)

local function removeAntiCheat()
    local keywords = {"anti", "cheat", "ban", "detect", "hack", "ac_", "anticheat", "sentry", "banned", "blacklist"}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("ModuleScript") or obj:IsA("LocalScript") or obj:IsA("Script") then
            local name = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if name:find(kw) then
                    pcall(function() obj:Destroy() end)
                    break
                end
            end
        elseif obj:IsA("RemoteEvent") or obj:IsA("BindableEvent") then
            if obj.Name:lower():find("ban") or obj.Name:lower():find("kick") then
                pcall(function() obj:Destroy() end)
            end
        end
    end
end

task.spawn(function()
    while task.wait(15) do
        if Settings.AntiCheatBypass then removeAntiCheat() end
    end
end)

pcall(function()
    local oldKickLocal = hookfunction(LocalPlayer.Kick, function(...)
        if Settings.AntiKick then return nil end
        return oldKickLocal(...)
    end)
end)

-- ===================== UI HELPERS =====================
local function CreateSwitch(parent, labelText, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 50, 0, 28)
    switchBg.Position = UDim2.new(1, -55, 0.5, -14)
    switchBg.BackgroundColor3 = default and Color3.fromRGB(0, 176, 255) or Color3.fromRGB(60, 60, 70)
    switchBg.BorderSizePixel = 0
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    switchBg.Parent = frame

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = default and UDim2.new(0, 26, 0, 3) or UDim2.new(0, 3, 0, 3)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    knob.Parent = switchBg

    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = switchBg

    local function updateSwitch(newState)
        state = newState
        local goal = {}
        if state then
            switchBg.BackgroundColor3 = Color3.fromRGB(0, 176, 255)
            goal.Position = UDim2.new(0, 26, 0, 3)
        else
            switchBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            goal.Position = UDim2.new(0, 3, 0, 3)
        end
        TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
        callback(state)
    end

    btn.MouseButton1Click:Connect(function()
        updateSwitch(not state)
    end)

    return frame
end

local function CreateSlider(parent, name, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 60)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 15
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 20)
    bar.Position = UDim2.new(0, 0, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
    bar.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 176, 255)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)
    fill.Parent = bar

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 24, 0, 24)
    knob.Position = UDim2.new((default - min) / (max - min), -12, 0.5, -12)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Text = ""
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    knob.Parent = bar

    local draggingSlider = false
    local value = default
    knob.MouseButton1Down:Connect(function() draggingSlider = true end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = UIS:GetMouseLocation()
            local barAbsPos = bar.AbsolutePosition
            local barAbsSize = bar.AbsoluteSize
            local alpha = math.clamp((mousePos.X - barAbsPos.X) / barAbsSize.X, 0, 1)
            value = math.floor(min + (max - min) * alpha)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            knob.Position = UDim2.new(alpha, -12, 0.5, -12)
            label.Text = name .. ": " .. value
            callback(value)
        end
    end)
    return frame
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 42)
    btn.Position = UDim2.new(0, 10, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.Parent = parent
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function arrange(container)
    local yPos = 5
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child.Position = UDim2.new(0, 0, 0, yPos)
            yPos = yPos + child.Size.Y.Offset + 4
        end
    end
    return yPos + 5
end

-- ===================== TẠO UI CHÍNH =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPS_God_Toandinh_Ultimate"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local viewport = Camera.ViewportSize
local scaleFactor = math.min(viewport.X / 600, viewport.Y / 800)
local UIScale = Instance.new("UIScale")
UIScale.Scale = scaleFactor
UIScale.Parent = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 720, 0, 600)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0.8, 0, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "FPS GOD ULTIMATE | toandinh"
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 16
TitleText.TextColor3 = Color3.fromRGB(255,255,255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -32, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,70)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "━"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinimizeBtn.Parent = TitleBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(1,0)

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 52, 0, 52)
OpenBtn.Position = UDim2.new(0.5, -26, 0.5, -26)
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 176, 255)
OpenBtn.BorderSizePixel = 0
OpenBtn.Text = "⚡"
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 28
OpenBtn.TextColor3 = Color3.fromRGB(255,255,255)
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1,0)

-- Kéo mainframe
local draggingMain, dragStartMain, startPosMain = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        dragStartMain = input.Position
        startPosMain = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then draggingMain = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if draggingMain and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X / UIScale.Scale, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y / UIScale.Scale)
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
    local mPos = MainFrame.Position
    OpenBtn.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset + MainFrame.Size.X.Offset/2 - 26, mPos.Y.Scale, mPos.Y.Offset + MainFrame.Size.Y.Offset/2 - 26)
end)
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)

-- Kéo nút mở
local draggingOpen, dragStartOpen, startPosOpen = false, nil, nil
OpenBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingOpen = true
        dragStartOpen = input.Position
        startPosOpen = OpenBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then draggingOpen = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if draggingOpen and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartOpen
        OpenBtn.Position = UDim2.new(startPosOpen.X.Scale, startPosOpen.X.Offset + delta.X / UIScale.Scale, startPosOpen.Y.Scale, startPosOpen.Y.Offset + delta.Y / UIScale.Scale)
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, -32)
Sidebar.Position = UDim2.new(0, 0, 0, 32)
Sidebar.BackgroundColor3 = Color3.fromRGB(15,15,25)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1,0,1,0)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.ScrollBarThickness = 4
SidebarScroll.CanvasSize = UDim2.new(0,0,0,0)
SidebarScroll.Parent = Sidebar

local TabList = {
    {name="Combat", icon="🎯"},
    {name="Visual", icon="👁️"},
    {name="Misc", icon="⚡"},
    {name="Rage", icon="💢"},
    {name="Troll", icon="🎭"},
    {name="Teleport", icon="📍"},
    {name="Stats", icon="📊"},
    {name="Anti-Ban", icon="🛡️"}
}

local TabButtons = {}
local TabFrames = {}
local yPos = 5
for i, tab in ipairs(TabList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 44)
    btn.Position = UDim2.new(0,5,0,yPos)
    btn.BackgroundColor3 = (i==1) and Color3.fromRGB(0,80,160) or Color3.fromRGB(30,30,40)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = SidebarScroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0,26,1,0)
    icon.BackgroundTransparency = 1
    icon.Text = tab.icon
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 16
    icon.TextColor3 = Color3.fromRGB(255,255,255)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Parent = btn

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-28,1,0)
    label.Position = UDim2.new(0,28,0,0)
    label.BackgroundTransparency = 1
    label.Text = tab.name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    TabButtons[i] = btn
    yPos = yPos + 48
end
SidebarScroll.CanvasSize = UDim2.new(0,0,0,yPos+10)

-- Content Panel
local ContentPanel = Instance.new("Frame")
ContentPanel.Size = UDim2.new(1, -160, 1, -32)
ContentPanel.Position = UDim2.new(0,160,0,32)
ContentPanel.BackgroundColor3 = Color3.fromRGB(17,17,24)
ContentPanel.BorderSizePixel = 0
ContentPanel.Parent = MainFrame

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1,0,1,0)
ContentScroll.BackgroundTransparency = 1
ContentScroll.ScrollBarThickness = 6
ContentScroll.CanvasSize = UDim2.new(0,0,0,0)
ContentScroll.Parent = ContentPanel

-- Tạo các tab frame
for i, tab in ipairs(TabList) do
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,0)
    f.BackgroundTransparency = 1
    f.Visible = (i==1)
    f.Parent = ContentScroll
    TabFrames[i] = f
end

local function switchTab(index)
    for j, b in ipairs(TabButtons) do
        b.BackgroundColor3 = Color3.fromRGB(30,30,40)
        TabFrames[j].Visible = false
    end
    TabButtons[index].BackgroundColor3 = Color3.fromRGB(0,80,160)
    local frame = TabFrames[index]
    frame.Visible = true
    ContentScroll.CanvasSize = UDim2.new(0,0,0,frame.Size.Y.Offset + 10)
    ContentScroll.CanvasPosition = Vector2.new(0,0)
end

for i, btn in ipairs(TabButtons) do
    btn.MouseButton1Click:Connect(function()
        switchTab(i)
    end)
end

-- ===================== NỘI DUNG CÁC TAB =====================
-- Combat
local combatFrame = TabFrames[1]
CreateSwitch(combatFrame, "Aimbot", false, function(v) Settings.Aimbot = v end)
CreateSlider(combatFrame, "Smooth", 1,20,10, function(v) Settings.AimbotSmooth = v end)
CreateSwitch(combatFrame, "Show FOV", false, function(v) Settings.ShowFOV = v and DrawingSupported end)
CreateSlider(combatFrame, "FOV Size", 10,800,100, function(v) Settings.FOVSize = v end)
local fovColorBtn = CreateButton(combatFrame, "FOV Color: Red", function()
    if Settings.FOVColor == "Red" then Settings.FOVColor = "Green"; fovColorBtn.Text = "FOV Color: Green"
    else Settings.FOVColor = "Red"; fovColorBtn.Text = "FOV Color: Red" end
end)
fovColorBtn.Size = UDim2.new(1,-20,0,38)
CreateSwitch(combatFrame, "Silent Aim", false, function(v) Settings.SilentAim = v; SetupSilentAim(v) end)
CreateSwitch(combatFrame, "Trigger Bot", false, function(v) Settings.TriggerBot = v end)
CreateSwitch(combatFrame, "Auto Headshot", false, function(v) Settings.AutoHeadshot = v end)
CreateSwitch(combatFrame, "Kill Aura", false, function(v) Settings.KillAura = v end)
CreateSlider(combatFrame, "Kill Aura Range", 5,100,20, function(v) Settings.KillAuraRadius = v end)
local combatHeight = arrange(combatFrame)
combatFrame.Size = UDim2.new(1,0,0,combatHeight)

-- Visual
local visualFrame = TabFrames[2]
CreateSwitch(visualFrame, "Box ESP", false, function(v) Settings.BoxESP = v end)
CreateSwitch(visualFrame, "Name ESP", false, function(v) Settings.NameESP = v end)
CreateSwitch(visualFrame, "Distance ESP", false, function(v) Settings.DistESP = v end)
CreateSwitch(visualFrame, "Health ESP", false, function(v) Settings.HealthESP = v end)
CreateSwitch(visualFrame, "Wallhack (Chams)", false, function(v)
    Settings.Wallhack = v
    for _, p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then UpdateHighlight(p) end end
end)
CreateSwitch(visualFrame, "Rainbow ESP", false, function(v) Settings.RainbowESP = v end)
CreateSwitch(visualFrame, "Bullet Tracer", false, function(v) Settings.BulletTracer = v and DrawingSupported end)
local visualHeight = arrange(visualFrame)
visualFrame.Size = UDim2.new(1,0,0,visualHeight)

-- Misc
local miscFrame = TabFrames[3]
CreateSwitch(miscFrame, "Infinite Ammo", false, function(v) Settings.InfAmmo = v end)
CreateSwitch(miscFrame, "No Recoil", false, function(v) Settings.NoRecoil = v end)
CreateSwitch(miscFrame, "Fast Fire", false, function(v) Settings.FastFire = v end)
CreateSwitch(miscFrame, "Speed Hack", false, function(v)
    Settings.SpeedHack = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = v and Settings.SpeedValue or 16 end
end)
CreateSlider(miscFrame, "Speed Value", 24,200,32, function(v)
    Settings.SpeedValue = v
    if Settings.SpeedHack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)
CreateSwitch(miscFrame, "Fly", false, function(v) Settings.Fly = v; ToggleFly(v) end)
CreateSlider(miscFrame, "Fly Speed", 30,200,50, function(v) Settings.FlySpeed = v end)
CreateSwitch(miscFrame, "High Jump", false, function(v)
    Settings.HighJump = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.JumpPower = v and Settings.JumpPower or 50 end
end)
CreateSlider(miscFrame, "Jump Height", 50,500,100, function(v)
    Settings.JumpPower = v
    if Settings.HighJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = v
    end
end)
CreateSwitch(miscFrame, "Noclip", false, function(v) Settings.Noclip = v; ToggleNoclip(v) end)
CreateSwitch(miscFrame, "Remove Fall Damage", false, function(v) Settings.RemoveFallDamage = v; HookFallDamage() end)
CreateSwitch(miscFrame, "Godmode", false, function(v)
    Settings.Godmode = v
    if v then EnableGodmode() else DisableGodmode() end
end)
local miscHeight = arrange(miscFrame)
miscFrame.Size = UDim2.new(1,0,0,miscHeight)

-- Rage
local rageFrame = TabFrames[4]
CreateSwitch(rageFrame, "Hitbox Expander", false, function(v)
    Settings.HitboxExpander = v
    if v then ScaleHitboxes(Settings.HitboxSize) else ScaleHitboxes(1) end
end)
CreateSlider(rageFrame, "Hitbox Size", 1.1, 5, 2, function(v)
    Settings.HitboxSize = v
    if Settings.HitboxExpander then ScaleHitboxes(v) end
end)
CreateSwitch(rageFrame, "Rapid Fire", false, function(v) Settings.RapidFire = v end)
CreateSwitch(rageFrame, "Cam Lock", false, function(v) Settings.CamLock = v end)
CreateSwitch(rageFrame, "Spin Bot", false, function(v) Settings.SpinBot = v; ToggleSpinBot(v) end)
CreateSlider(rageFrame, "Spin Speed", 5, 30, 10, function(v) Settings.SpinSpeed = v; if spinVel then spinVel.AngularVelocity = Vector3.new(0, v, 0) end end)
CreateSwitch(rageFrame, "Fake Death", false, function(v) Settings.FakeDeath = v; ToggleFakeDeath(v) end)
CreateSwitch(rageFrame, "Auto Farm Kill", false, function(v) Settings.AutoFarmKill = v end)
local rageHeight = arrange(rageFrame)
rageFrame.Size = UDim2.new(1,0,0,rageHeight)

-- ===================== TROLL TAB (SỬA LẠI BỐ CỤC) =====================
local trollFrame = TabFrames[5]

-- Fake Lag (đặt riêng để không bị đè)
CreateSwitch(trollFrame, "Fake Lag", false, function(v)
    Settings.FakeLag = v
    NetworkClient:SetFakeLatency(v and Settings.FakeLagIntensity/1000 or 0)
end)
CreateSlider(trollFrame, "Lag Intensity", 50,1000,200, function(v)
    Settings.FakeLagIntensity = v
    if Settings.FakeLag then NetworkClient:SetFakeLatency(v/1000) end
end)

-- Chat Spammer
CreateSwitch(trollFrame, "Chat Spammer", false, function(v)
    Settings.ChatSpam = v
    if v then
        chatSpamRunning = true
        task.spawn(function()
            while chatSpamRunning and Settings.ChatSpam do
                pcall(function()
                    local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                    if channel then channel:SendAsync(Settings.SpamMessage) end
                end)
                pcall(function() Players:Chat(Settings.SpamMessage) end)
                task.wait(Settings.SpamInterval)
            end
        end)
    else
        chatSpamRunning = false
    end
end)
local msgInput = Instance.new("TextBox")
msgInput.Size = UDim2.new(1,-20,0,35)
msgInput.PlaceholderText = "Spam message..."
msgInput.Text = Settings.SpamMessage
msgInput.Font = Enum.Font.GothamBold
msgInput.TextSize = 14
msgInput.BackgroundColor3 = Color3.fromRGB(30,30,40)
msgInput.TextColor3 = Color3.fromRGB(255,255,255)
msgInput.BorderSizePixel = 0
Instance.new("UICorner", msgInput).CornerRadius = UDim.new(0,6)
msgInput.Parent = trollFrame
msgInput.FocusLost:Connect(function() Settings.SpamMessage = msgInput.Text end)
CreateSlider(trollFrame, "Spam Interval", 1,10,3, function(v) Settings.SpamInterval = v end)

-- Sit on Head (dùng ScrollingFrame)
CreateSwitch(trollFrame, "Sit on Head", false, function(v)
    Settings.SitOnHead = v
    if not v then UnSitOnHead() end
end)

local sitPlayerListFrame = Instance.new("ScrollingFrame")
sitPlayerListFrame.Size = UDim2.new(1, -20, 0, 120)
sitPlayerListFrame.Position = UDim2.new(0, 10, 0, 0)
sitPlayerListFrame.BackgroundColor3 = Color3.fromRGB(25,25,35)
sitPlayerListFrame.ScrollBarThickness = 6
sitPlayerListFrame.CanvasSize = UDim2.new(0,0,0,0)
sitPlayerListFrame.Parent = trollFrame

local function refreshSitList()
    for _, child in ipairs(sitPlayerListFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local y = 5
    local hasPlayer = false
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            hasPlayer = true
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.Position = UDim2.new(0, 5, 0, y)
            btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
            btn.Text = plr.Name
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 13
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
            btn.Parent = sitPlayerListFrame
            btn.MouseButton1Click:Connect(function()
                Settings.SitTarget = plr.Name
                if Settings.SitOnHead then
                    SitOnHead(plr)
                end
            end)
            y = y + 34
        end
    end
    if not hasPlayer then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 1, 0)
        lbl.Position = UDim2.new(0, 5, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "No other players"
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.fromRGB(150,150,150)
        lbl.Parent = sitPlayerListFrame
        y = 40
    end
    sitPlayerListFrame.CanvasSize = UDim2.new(0,0,0,y+5)
end
refreshSitList()
Players.PlayerAdded:Connect(refreshSitList)
Players.PlayerRemoving:Connect(refreshSitList)

-- Sắp xếp troll frame
local trollHeight = arrange(trollFrame)
trollFrame.Size = UDim2.new(1,0,0,trollHeight)

-- ===================== TELEPORT TAB (GIỮ NGUYÊN NHƯNG CHỈNH KÍCH THƯỚC) =====================
local teleportFrame = TabFrames[6]
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(1, -10, 0, 200)  -- Tăng chiều cao để cuộn tốt hơn
playerListFrame.Position = UDim2.new(0, 5, 0, 5)
playerListFrame.BackgroundColor3 = Color3.fromRGB(25,25,35)
playerListFrame.ScrollBarThickness = 8
playerListFrame.CanvasSize = UDim2.new(0,0,0,0)
playerListFrame.Parent = teleportFrame

local function refreshTeleportList()
    for _, child in ipairs(playerListFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local y = 5
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,-10,0,38)
            btn.Position = UDim2.new(0,5,0,y)
            btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
            btn.Text = plr.Name
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
            btn.Parent = playerListFrame
            btn.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,2,0)
                end
            end)
            y = y + 42
        end
    end
    playerListFrame.CanvasSize = UDim2.new(0,0,0,y+10)
end
refreshTeleportList()
Players.PlayerAdded:Connect(refreshTeleportList)
Players.PlayerRemoving:Connect(refreshTeleportList)

CreateButton(teleportFrame, "Server Hop (Fast)", function()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end)
local teleportHeight = arrange(teleportFrame)
teleportFrame.Size = UDim2.new(1,0,0,teleportHeight)

-- Stats
local statsFrame = TabFrames[7]
CreateSlider(statsFrame, "Kills", 0, 50000, 999, function(v) Settings.StatKills = v; UpdateStats() end)
CreateSlider(statsFrame, "Deaths", 0, 50000, 1, function(v) Settings.StatDeaths = v; UpdateStats() end)
CreateSlider(statsFrame, "Level", 1, 500, 100, function(v) Settings.StatLevel = v; UpdateStats() end)
CreateSlider(statsFrame, "Wins", 0, 50000, 999, function(v) Settings.StatWins = v; UpdateStats() end)
local statsHeight = arrange(statsFrame)
statsFrame.Size = UDim2.new(1,0,0,statsHeight)

-- Anti-Ban
local antiBanFrame = TabFrames[8]
CreateSwitch(antiBanFrame, "Anti-Kick", false, function(v) Settings.AntiKick = v end)
CreateSwitch(antiBanFrame, "Anti-Report", false, function(v) Settings.AntiReport = v end)
CreateSwitch(antiBanFrame, "Anti-Cheat Bypass", false, function(v)
    Settings.AntiCheatBypass = v
    if v then removeAntiCheat() end
end)
CreateSwitch(antiBanFrame, "Anti-Mod (Detect Hackers)", false, function(v) Settings.AntiMod = v end)
local warningLabel = Instance.new("TextLabel")
warningLabel.Size = UDim2.new(1,-20,0,40)
warningLabel.BackgroundTransparency = 1
warningLabel.Text = "No hackers detected"
warningLabel.Font = Enum.Font.GothamBold
warningLabel.TextSize = 14
warningLabel.TextColor3 = Color3.fromRGB(255,255,100)
warningLabel.Parent = antiBanFrame
CreateButton(antiBanFrame, "Refresh Anti-Mod", function() warningLabel.Text = DetectHackers() end)
local antiHeight = arrange(antiBanFrame)
antiBanFrame.Size = UDim2.new(1,0,0,antiHeight)

-- Khởi tạo tab đầu tiên
switchTab(1)

-- ===================== CHỨC NĂNG CHI TIẾT =====================
local cachedRemote = nil
local remoteCacheTime = 0
function FindRemote()
    if tick() - remoteCacheTime < 1 then return cachedRemote end
    cachedRemote = nil
    for _, tool in ipairs(LocalPlayer.Character and LocalPlayer.Character:GetChildren() or {}) do
        if tool:IsA("Tool") then
            for _, v in tool:GetDescendants() do
                if v:IsA("RemoteEvent") then cachedRemote = v; break end
            end
        end
    end
    if not cachedRemote then
        for _, tool in ipairs(LocalPlayer.Backpack and LocalPlayer.Backpack:GetChildren() or {}) do
            if tool:IsA("Tool") then
                for _, v in tool:GetDescendants() do
                    if v:IsA("RemoteEvent") then cachedRemote = v; break end
                end
            end
        end
    end
    remoteCacheTime = tick()
    return cachedRemote
end

local SilentAimHook
function SetupSilentAim(enable)
    if SilentAimHook then SilentAimHook:Disable(); SilentAimHook = nil end
    if not enable then return end
    local remote = FindRemote()
    if not remote then return end
    local oldFire = remote.FireServer
    SilentAimHook = hookfunction(remote.FireServer, function(self, ...)
        local args = {...}
        if Settings.SilentAim and AimTarget and AimTarget:FindFirstChild("Head") then
            args[1] = AimTarget.Head.Position
        end
        return oldFire(self, unpack(args))
    end)
end

function IsTargetVisible(target)
    if not target or not target:FindFirstChild("Head") then return false end
    local headPos = target.Head.Position
    local origin = Camera.CFrame.Position
    local dir = (headPos - origin).Unit * 1000
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    if LocalPlayer.Character then params.FilterDescendantsInstances = {LocalPlayer.Character} end
    local result = workspace:Raycast(origin, dir, params)
    return result and result.Instance:IsDescendantOf(target)
end

function GetClosestVisibleEnemy()
    local nearest = nil
    local minAngle = math.rad(Settings.FOVSize/2)
    local camPos = Camera.CFrame.Position
    local camLook = Camera.CFrame.LookVector
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if char and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local headPos = char.Head.Position
            local dir = (headPos - camPos).Unit
            local angle = math.acos(math.clamp(camLook:Dot(dir), -1, 1))
            if angle < minAngle and IsTargetVisible(char) then
                minAngle = angle
                nearest = char
            end
        end
    end
    return nearest
end

function ToggleFly(enable)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if enable then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyBV"
        bv.Velocity = Vector3.zero
        bv.MaxForce = Vector3.new(400000, 400000, 400000)
        bv.Parent = hrp
        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyBG"
        bg.CFrame = hrp.CFrame
        bg.MaxTorque = Vector3.new(400000, 400000, 400000)
        bg.Parent = hrp
        if char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = true end
    else
        if hrp:FindFirstChild("FlyBV") then hrp.FlyBV:Destroy() end
        if hrp:FindFirstChild("FlyBG") then hrp.FlyBG:Destroy() end
        if char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
    end
end

function ToggleNoclip(enable)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not enable end
    end
end

function HandleFly()
    if not Settings.Fly then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    local bv = hrp:FindFirstChild("FlyBV")
    local bg = hrp:FindFirstChild("FlyBG")
    if not bv or not bg then return end
    local moveDir = hum.MoveDirection
    if moveDir.Magnitude > 0.1 then
        local camCF = Camera.CFrame
        local localMove = camCF:VectorToObjectSpace(moveDir)
        bv.Velocity = (camCF.LookVector * (-localMove.Z) + camCF.RightVector * localMove.X) * Settings.FlySpeed
    else
        bv.Velocity = Vector3.zero
    end
    bg.CFrame = Camera.CFrame
end

function ScaleHitboxes(size)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head and head:IsA("BasePart") then head.Size = Vector3.new(2*size,1.2*size,1*size) end
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then root.Size = Vector3.new(4*size,2*size,2*size) end
        end
    end
end

function HookFallDamage()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        pcall(function()
            hum.FallDamageEnabled = false
            local oldTakeDamage = hum.TakeDamage
            hum.TakeDamage = function(self, amount)
                if Settings.RemoveFallDamage and amount > 0 and amount < 50 then return end
                return oldTakeDamage(self, amount)
            end
        end)
    end
end

function EnableGodmode()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            if godmodeConnection then godmodeConnection:Disconnect() end
            godmodeConnection = hum.HealthChanged:Connect(function()
                if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
            end)
            hum.Health = hum.MaxHealth
        end
    end
end
function DisableGodmode()
    if godmodeConnection then godmodeConnection:Disconnect(); godmodeConnection = nil end
end

function ToggleSpinBot(enable)
    if enable then
        if not spinVel then
            spinVel = Instance.new("BodyAngularVelocity")
            spinVel.Name = "SpinBotAV"
            spinVel.MaxTorque = Vector3.new(0, 400000, 0)
            spinVel.AngularVelocity = Vector3.new(0, Settings.SpinSpeed, 0)
        end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and not spinVel.Parent then spinVel.Parent = hrp end
    else
        if spinVel then spinVel:Destroy(); spinVel = nil end
    end
end

function ToggleFakeDeath(enable)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    if enable then
        hum.PlatformStand = true
        hum.Health = 0
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p ~= char:FindFirstChild("Head") then
                p.CanCollide = false
                p.Transparency = 0.5
            end
        end
    else
        hum.PlatformStand = false
        hum.Health = hum.MaxHealth
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
                p.Transparency = 0
            end
        end
    end
end

function DetectHackers()
    local hackers = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            local hum = plr.Character.Humanoid
            if hum.WalkSpeed > 100 or hum.JumpPower > 200 then
                table.insert(hackers, plr.Name)
            end
            if plr.Character:FindFirstChild("Head") and plr.Character.Head.Transparency < 0 then
                table.insert(hackers, plr.Name)
            end
        end
    end
    if #hackers > 0 then return "Hackers: "..table.concat(hackers,", ") else return "No hackers detected" end
end

function UpdateStats()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                local name = stat.Name:lower()
                if name:find("kill") then stat.Value = Settings.StatKills
                elseif name:find("death") then stat.Value = Settings.StatDeaths
                elseif name:find("level") then stat.Value = Settings.StatLevel
                elseif name:find("win") then stat.Value = Settings.StatWins end
            end
        end
    end
end

function SitOnHead(targetPlayer)
    if targetPlayer and targetPlayer.Character then
        sitTargetChar = targetPlayer.Character
        if sitConnection then sitConnection:Disconnect() end
        sitConnection = RunService.Heartbeat:Connect(function()
            if sitTargetChar and LocalPlayer.Character then
                local head = sitTargetChar:FindFirstChild("Head")
                local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if head and myRoot then
                    myRoot.CFrame = CFrame.new(head.Position + Vector3.new(0, 2, 0))
                end
            end
        end)
    end
end
function UnSitOnHead()
    if sitConnection then sitConnection:Disconnect(); sitConnection = nil end
    sitTargetChar = nil
end

function DrawTracer(origin, direction)
    if not DrawingSupported or not Settings.BulletTracer then return end
    local ray = Ray.new(origin, direction * 500)
    local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character}, false, true)
    local endpoint = pos or origin + direction * 500
    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(255, 100, 0)
    line.From = Camera:WorldToViewportPoint(origin)
    line.To = Camera:WorldToViewportPoint(endpoint)
    line.Visible = true
    table.insert(tracerTable, {line = line, start = tick()})
    task.delay(0.1, function() line:Remove() end)
end

-- ===================== HÀM VẼ ESP =====================
local function createDrawing(type, properties)
    if not DrawingSupported then return {Visible=false,Remove=function()end} end
    local d = Drawing.new(type)
    for k,v in pairs(properties) do d[k] = v end
    return d
end
function removePlayerEsp(player)
    local cache = espCache[player]
    if cache then
        for _, d in pairs(cache) do if d and d.Remove then d:Remove() end end
        espCache[player] = nil
    end
end
function updatePlayerEsp(player, character)
    if not DrawingSupported then return end
    local cache = espCache[player]
    if not cache then
        cache = {}
        cache.box = createDrawing("Square", {Visible=false,Color=Color3.fromRGB(255,255,255),Thickness=2,Transparency=0.5})
        cache.name = createDrawing("Text", {Visible=false,Color=Color3.fromRGB(255,255,255),Size=14,Center=true,Outline=true,OutlineColor=Color3.fromRGB(0,0,0)})
        cache.dist = createDrawing("Text", {Visible=false,Color=Color3.fromRGB(200,200,200),Size=13,Center=true,Outline=true,OutlineColor=Color3.fromRGB(0,0,0)})
        cache.healthBg = createDrawing("Line", {Visible=false,Color=Color3.fromRGB(40,40,40),Thickness=4})
        cache.healthBar = createDrawing("Line", {Visible=false,Color=Color3.fromRGB(0,255,0),Thickness=4})
        espCache[player] = cache
    end
    local head = character and character:FindFirstChild("Head")
    local hum = character and character:FindFirstChild("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not head or not hum or hum.Health <= 0 then
        for _, d in pairs(cache) do if d.Visible ~= nil then d.Visible = false end end
        return
    end
    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    local rootPos = root and root.Position or head.Position
    local rootScreen = Camera:WorldToViewportPoint(rootPos)
    if not onScreen then
        for _, d in pairs(cache) do if d.Visible ~= nil then d.Visible = false end end
        return
    end
    local distance = (Camera.CFrame.Position - rootPos).Magnitude
    local yMin = headPos.Y
    local yMax = rootScreen.Y
    local xMin = headPos.X - (yMax - yMin)/4
    local xMax = headPos.X + (yMax - yMin)/4

    local color = Color3.fromHSV(rainbowHue % 1, 1, 1)
    if Settings.RainbowESP then
        if cache.box then cache.box.Color = color end
        if cache.name then cache.name.Color = color end
        if cache.dist then cache.dist.Color = color end
        if cache.healthBar then cache.healthBar.Color = color end
    else
        if cache.box then cache.box.Color = Color3.fromRGB(255,255,255) end
        if cache.name then cache.name.Color = Color3.fromRGB(255,255,255) end
        if cache.dist then cache.dist.Color = Color3.fromRGB(200,200,200) end
        if cache.healthBar then cache.healthBar.Color = Color3.fromRGB(0,255,0) end
    end
    if cache.box then
        cache.box.Visible = Settings.BoxESP
        cache.box.Size = Vector2.new(xMax - xMin, yMax - yMin)
        cache.box.Position = Vector2.new(xMin, yMin)
    end
    if cache.name then
        cache.name.Visible = Settings.NameESP
        cache.name.Text = player.Name
        cache.name.Position = Vector2.new(xMin + (xMax-xMin)/2, yMin - 18)
    end
    if cache.dist then
        cache.dist.Visible = Settings.DistESP
        cache.dist.Text = math.floor(distance).."m"
        cache.dist.Position = Vector2.new(xMin + (xMax-xMin)/2, yMax + 2)
    end
    if cache.healthBar and cache.healthBg then
        cache.healthBar.Visible = Settings.HealthESP
        cache.healthBg.Visible = Settings.HealthESP
        local health = hum.Health / hum.MaxHealth
        local barW = 4
        local barX = xMin - barW - 2
        local barY = yMin
        local barH = yMax - yMin
        cache.healthBar.From = Vector2.new(barX, barY + barH)
        cache.healthBar.To = Vector2.new(barX, barY + barH * (1 - health))
        cache.healthBg.From = Vector2.new(barX, barY)
        cache.healthBg.To = Vector2.new(barX, barY + barH)
    end
end

local function UpdateHighlight(player)
    if not DrawingSupported then return end
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if Settings.Wallhack and hum and hum.Health > 0 then
        if not highlightCache[player] then
            local hl = Instance.new("Highlight")
            hl.Name = "Chams"
            hl.FillColor = Color3.fromRGB(255, 100, 0)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.3
            hl.OutlineTransparency = 0
            hl.Enabled = true
            hl.Adornee = char
            hl.Parent = char
            highlightCache[player] = hl
        end
    else
        local hl = highlightCache[player]
        if hl then hl:Destroy(); highlightCache[player] = nil end
    end
end

-- ===================== VÒNG LẶP CHÍNH =====================
local FOVCircle
if DrawingSupported then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 2
    FOVCircle.Transparency = 0.8
    FOVCircle.Radius = 100
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Filled = false
end

RunService.RenderStepped:Connect(function(dt)
    rainbowHue = (tick() * 0.3) % 1

    if DrawingSupported and FOVCircle then
        FOVCircle.Visible = Settings.ShowFOV or Settings.Aimbot or Settings.SilentAim
        FOVCircle.Radius = Settings.FOVSize
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Color = Settings.FOVColor == "Red" and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
    end

    if Settings.Aimbot then
        local target = GetClosestVisibleEnemy()
        AimTarget = target
        if target and target:FindFirstChild("Head") then
            local aimPos = target.Head.Position
            if Settings.AutoHeadshot then aimPos = target.Head.Position end
            local smoothFactor = 1 - (Settings.AimbotSmooth-1)/19
            local alpha = 1 - math.exp(-dt * (smoothFactor * 25))
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, aimPos), math.clamp(alpha, 0.01, 1))
        end
    else
        AimTarget = nil
    end

    if Settings.CamLock then
        local target = GetClosestVisibleEnemy() or AimTarget
        if target and target:FindFirstChild("Head") then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Head.Position)
        end
    end

    if Settings.TriggerBot and tick() - lastTriggerTime >= 0.2 then
        lastTriggerTime = tick()
        local char = LocalPlayer.Character
        if char then
            local ray = Ray.new(Camera.CFrame.Position, Camera.CFrame.LookVector * 1000)
            local hit = workspace:FindPartOnRayWithIgnoreList(ray, {char}, false, true)
            if hit then
                local model = hit:FindFirstAncestorOfClass("Model")
                if model and Players:GetPlayerFromCharacter(model) then
                    VIM:SendMouseButtonEvent(0,0,0,true,game,1)
                    task.wait(0.05)
                    VIM:SendMouseButtonEvent(0,0,0,false,game,1)
                end
            end
        end
    end

    if Settings.KillAura and tick() - lastKillAuraUpdate >= 0.15 then
        lastKillAuraUpdate = tick()
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or not player.Character then continue end
            local char = player.Character
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local enemyRoot = char:FindFirstChild("HumanoidRootPart")
                if myRoot and enemyRoot then
                    local dist = (myRoot.Position - enemyRoot.Position).Magnitude
                    if dist <= Settings.KillAuraRadius and IsTargetVisible(char) then
                        local remote = FindRemote()
                        if remote then
                            remote:FireServer(char.Head.Position)
                        end
                    end
                end
            end
        end
    end

    if Settings.AutoFarmKill and tick() - lastKillAuraUpdate >= 0.15 then
        local target = GetClosestVisibleEnemy()
        if target and target:FindFirstChild("Head") then
            local remote = FindRemote()
            if remote then
                remote:FireServer(target.Head.Position)
            end
        end
    end

    if tick() - lastESPUpdate >= 0.2 then
        lastESPUpdate = tick()
        local activePlayers = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                activePlayers[p] = true
                updatePlayerEsp(p, p.Character)
                UpdateHighlight(p)
            end
        end
        for plr, _ in pairs(espCache) do
            if not activePlayers[plr] then removePlayerEsp(plr) end
        end
    end

    if Settings.AntiMod then
        warningLabel.Text = DetectHackers()
    end
end)

RunService.Heartbeat:Connect(function()
    HandleFly()
    if Settings.NoRecoil and firing and savedPitch then
        local currentYaw = Camera.CFrame:toEulerAnglesYXZ()
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.Angles(savedPitch, currentYaw, 0)
    end
    if tick() - lastWeaponCheck >= 0.5 then
        lastWeaponCheck = tick()
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            if Settings.RapidFire then
                for _, v in ipairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") and (v.Name:lower():find("firerate") or v.Name:lower():find("cool")) then
                        v.Value = 0.01
                    end
                end
            end
            if Settings.InfAmmo then
                for _, v in ipairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") and v.Name:lower():find("ammo") then
                        v.Value = 999
                    end
                end
            end
        end
    end
    if Settings.Godmode and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        firing = true
        if Settings.NoRecoil then savedPitch = Camera.CFrame:toEulerAnglesYXZ() end
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then firing = false end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    SetupSilentAim(Settings.SilentAim)
    if Settings.Fly then ToggleFly(true) end
    if Settings.Noclip then ToggleNoclip(true) end
    if Settings.SpeedHack then char:WaitForChild("Humanoid",2).WalkSpeed = Settings.SpeedValue end
    if Settings.HighJump then char:WaitForChild("Humanoid",2).JumpPower = Settings.JumpPower end
    if Settings.HitboxExpander then ScaleHitboxes(Settings.HitboxSize) end
    if Settings.RemoveFallDamage then HookFallDamage() end
    if Settings.Godmode then EnableGodmode() end
    if Settings.SpinBot then ToggleSpinBot(true) end
    if Settings.FakeDeath then ToggleFakeDeath(true) end
end)

if LocalPlayer.Character then
    SetupSilentAim(Settings.SilentAim)
    if Settings.Godmode then EnableGodmode() end
    if Settings.HitboxExpander then ScaleHitboxes(Settings.HitboxSize) end
    if Settings.RemoveFallDamage then HookFallDamage() end
end

if Settings.AntiCheatBypass then removeAntiCheat() end

print("[FPS GOD ULTIMATE v16 – UI FIXED] Đã tải thành công!")