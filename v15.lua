--[[
    FPS GOD MENU v15 ULTIMATE – TOANDINH STYLE UI (FIXED + DRAGGABLE MINIMIZE BUTTON)
    Fix lỗi crash do thiếu Drawing API và thiếu hàm ESP.
    Menu vẫn lên bình thường, ESP/FOV tự tắt nếu không khả dụng.
    Nút minimize có thể kéo di chuyển.
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

    -- Visual
    BoxESP = false,
    NameESP = false,
    DistESP = false,
    HealthESP = false,
    Wallhack = false,

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

    -- Troll
    FakeLag = false,
    FakeLagMs = 200,
    ChatSpam = false,
    SpamMessage = "FPS GOD v15",
    SpamInterval = 3,

    -- Anti-Ban
    AntiKick = false,
    AntiReport = false,
    AntiCheatBypass = false
}

local AimTarget = nil
local savedPitch = nil
local firing = false
local lastTriggerTime = 0
local lastWeaponCheck = 0
local espCache = {}
local highlightCache = {}
local chatSpamRunning = false
local DrawingSupported = pcall(function() local test = Drawing.new("Circle"); test:Remove() end)

-- Nếu không hỗ trợ Drawing, vô hiệu hoá toàn bộ tính năng vẽ
if not DrawingSupported then
    Settings.ShowFOV = false
    Settings.BoxESP = false
    Settings.NameESP = false
    Settings.DistESP = false
    Settings.HealthESP = false
    Settings.Wallhack = false
end

-- ===================== ANTI-BAN HOOKS =====================
local oldKick = hookfunction(LocalPlayer.Kick, function(self, ...)
    if Settings.AntiKick then return nil end
    return oldKick(self, ...)
end)

local function hookReport(player)
    pcall(function()
        if player ~= LocalPlayer and not player.ReportHooked then
            local oldReport = hookfunction(player.ReportAbuse, function(...)
                if Settings.AntiReport then return nil end
                return oldReport(...)
            end)
            player.ReportHooked = true
        end
    end)
end
for _, p in ipairs(Players:GetPlayers()) do hookReport(p) end
Players.PlayerAdded:Connect(hookReport)

local function removeAntiCheat()
    local keywords = {"anti", "cheat", "ban", "detect", "hack", "ac_", "anticheat", "sentry"}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("ModuleScript") or obj:IsA("LocalScript") or obj:IsA("Script") then
            local name = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if name:find(kw) then
                    pcall(function() obj:Destroy() end)
                    break
                end
            end
        end
    end
end
if Settings.AntiCheatBypass then removeAntiCheat() end
task.spawn(function()
    while task.wait(30) do
        if Settings.AntiCheatBypass then removeAntiCheat() end
    end
end)

local oldTeleport = hookfunction(TeleportService.Teleport, function(...)
    if Settings.AntiTeleport then return nil end
    return oldTeleport(...)
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
end

-- ===================== TẠO UI CHÍNH =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPS_God_Toandinh"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local viewport = Camera.ViewportSize
local scaleFactor = math.min(viewport.X / 450, viewport.Y / 700)
local UIScale = Instance.new("UIScale")
UIScale.Scale = scaleFactor
UIScale.Parent = ScreenGui

-- Main container (có thể kéo)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 720, 0, 540)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -270)
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
TitleText.Text = "FPS GOD  |  toandinh"
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 16
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -32, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "━"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Parent = TitleBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(1, 0)

-- Nút mở lại (có thể kéo)
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 48, 0, 48)
OpenBtn.Position = UDim2.new(0.5, -24, 0.5, -24)
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 176, 255)
OpenBtn.BorderSizePixel = 0
OpenBtn.Text = "⚡"
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 24
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)

-- ===================== KÉO MAINFRAME =====================
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

-- ===================== MINIMIZE / RESTORE =====================
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
    local mPos = MainFrame.Position
    OpenBtn.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset + MainFrame.Size.X.Offset/2 - 24, mPos.Y.Scale, mPos.Y.Offset + MainFrame.Size.Y.Offset/2 - 24)
end)
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)

-- ===================== KÉO NÚT MỞ (OPENBTN) =====================
local draggingOpen, dragStartOpen, startPosOpen = false, nil, nil
OpenBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingOpen = true
        dragStartOpen = input.Position
        startPosOpen = OpenBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingOpen = false
            end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if draggingOpen and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartOpen
        OpenBtn.Position = UDim2.new(startPosOpen.X.Scale, startPosOpen.X.Offset + delta.X / UIScale.Scale, startPosOpen.Y.Scale, startPosOpen.Y.Offset + delta.Y / UIScale.Scale)
    end
end)

-- ===================== SIDEBAR =====================
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 180, 1, -32)
Sidebar.Position = UDim2.new(0, 0, 0, 32)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, 0)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.ScrollBarThickness = 4
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.Parent = Sidebar

local TabList = {
    {name = "Combat", icon = "⚔️"},
    {name = "Visual", icon = "👁️"},
    {name = "Misc", icon = "🛠️"},
    {name = "Teleport", icon = "🌐"},
    {name = "Troll", icon = "🎭"},
    {name = "Anti-Ban", icon = "🛡️"}
}

local TabButtons = {}
local TabFrames = {}
local TabContent = {}

local yPos = 5
for i, tab in ipairs(TabList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 48)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(0, 80, 160) or Color3.fromRGB(30, 30, 40)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = SidebarScroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = tab.icon
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 18
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Parent = btn

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -35, 1, 0)
    label.Position = UDim2.new(0, 32, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tab.name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    TabButtons[i] = btn
    yPos = yPos + 52
end
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)

-- ===================== MAIN CONTENT =====================
local ContentPanel = Instance.new("Frame")
ContentPanel.Size = UDim2.new(1, -180, 1, -32)
ContentPanel.Position = UDim2.new(0, 180, 0, 32)
ContentPanel.BackgroundColor3 = Color3.fromRGB(17, 17, 24)
ContentPanel.BorderSizePixel = 0
ContentPanel.Parent = MainFrame

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, 0, 1, 0)
ContentScroll.BackgroundTransparency = 1
ContentScroll.ScrollBarThickness = 6
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.Parent = ContentPanel

for i, tab in ipairs(TabList) do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (i == 1)
    frame.Parent = ContentScroll
    TabFrames[i] = frame
end

for i, btn in ipairs(TabButtons) do
    btn.MouseButton1Click:Connect(function()
        for j, b in ipairs(TabButtons) do
            b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            TabFrames[j].Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(0, 80, 160)
        TabFrames[i].Visible = true
        ContentScroll.CanvasPosition = Vector2.new(0, 0)
    end)
end

-- ===================== TẠO NỘI DUNG TABS =====================
-- Combat Tab
local combatFrame = TabFrames[1]
CreateSwitch(combatFrame, "Aimbot", false, function(v) Settings.Aimbot = v end)
CreateSlider(combatFrame, "Smooth", 1, 20, 10, function(v) Settings.AimbotSmooth = v end)
CreateSwitch(combatFrame, "Show FOV", false, function(v) Settings.ShowFOV = v and DrawingSupported end)
CreateSlider(combatFrame, "FOV Size", 10, 800, 100, function(v) Settings.FOVSize = v end)

local fovColorBtn = Instance.new("TextButton")
fovColorBtn.Size = UDim2.new(1, -20, 0, 42)
fovColorBtn.Position = UDim2.new(0, 10, 0, 0)
fovColorBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
fovColorBtn.BorderSizePixel = 1
fovColorBtn.BorderColor3 = Color3.fromRGB(50, 50, 60)
fovColorBtn.Text = "FOV Color: Red"
fovColorBtn.Font = Enum.Font.GothamBold
fovColorBtn.TextSize = 16
fovColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", fovColorBtn).CornerRadius = UDim.new(0, 6)
fovColorBtn.Parent = combatFrame
fovColorBtn.MouseButton1Click:Connect(function()
    if not DrawingSupported then return end
    if Settings.FOVColor == "Red" then
        Settings.FOVColor = "Green"
        fovColorBtn.Text = "FOV Color: Green"
    else
        Settings.FOVColor = "Red"
        fovColorBtn.Text = "FOV Color: Red"
    end
end)

CreateSwitch(combatFrame, "Silent Aim", false, function(v) Settings.SilentAim = v; SetupSilentAim(v) end)
CreateSwitch(combatFrame, "Trigger Bot", false, function(v) Settings.TriggerBot = v end)

-- Visual Tab
local visualFrame = TabFrames[2]
CreateSwitch(visualFrame, "Box ESP", false, function(v) if DrawingSupported then Settings.BoxESP = v else Settings.BoxESP = false end end)
CreateSwitch(visualFrame, "Name ESP", false, function(v) if DrawingSupported then Settings.NameESP = v else Settings.NameESP = false end end)
CreateSwitch(visualFrame, "Distance ESP", false, function(v) if DrawingSupported then Settings.DistESP = v else Settings.DistESP = false end end)
CreateSwitch(visualFrame, "Health ESP", false, function(v) if DrawingSupported then Settings.HealthESP = v else Settings.HealthESP = false end end)
CreateSwitch(visualFrame, "Wallhack (Chams)", false, function(v)
    Settings.Wallhack = v and DrawingSupported
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then UpdateHighlight(player) end
    end
end)

-- Misc Tab
local miscFrame = TabFrames[3]
CreateSwitch(miscFrame, "Infinite Ammo", false, function(v) Settings.InfAmmo = v end)
CreateSwitch(miscFrame, "No Recoil", false, function(v) Settings.NoRecoil = v end)
CreateSwitch(miscFrame, "Fast Fire", false, function(v) Settings.FastFire = v end)
CreateSwitch(miscFrame, "Speed Hack", false, function(v)
    Settings.SpeedHack = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = v and Settings.SpeedValue or 16 end
end)
CreateSlider(miscFrame, "Speed Value", 24, 200, 32, function(v)
    Settings.SpeedValue = v
    if Settings.SpeedHack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)
CreateSwitch(miscFrame, "Fly", false, function(v)
    Settings.Fly = v
    ToggleFly(v)
end)
CreateSlider(miscFrame, "Fly Speed", 30, 200, 50, function(v) Settings.FlySpeed = v end)
CreateSwitch(miscFrame, "High Jump", false, function(v)
    Settings.HighJump = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.JumpPower = v and Settings.JumpPower or 50 end
end)
CreateSlider(miscFrame, "Jump Height", 50, 500, 100, function(v)
    Settings.JumpPower = v
    if Settings.HighJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = v
    end
end)
CreateSwitch(miscFrame, "Noclip", false, function(v)
    Settings.Noclip = v
    ToggleNoclip(v)
end)

-- Teleport Tab
local teleportFrame = TabFrames[4]
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(1, -10, 1, -10)
playerListFrame.Position = UDim2.new(0, 5, 0, 5)
playerListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
playerListFrame.ScrollBarThickness = 8
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.Parent = teleportFrame

local function updatePlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local yPos = 5
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 40)
        btn.Position = UDim2.new(0, 5, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btn.Text = player.Name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.Parent = playerListFrame
        btn.MouseButton1Click:Connect(function()
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetChar = player.Character
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            if myRoot and targetRoot then
                myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 2, 0)
            end
        end)
        yPos = yPos + 44
    end
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
end
updatePlayerList()
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

-- Troll Tab
local trollFrame = TabFrames[5]
CreateSwitch(trollFrame, "Fake Lag", false, function(v)
    Settings.FakeLag = v
    if v then
        NetworkClient:SetFakeLatency(Settings.FakeLagMs / 1000)
    else
        NetworkClient:SetFakeLatency(0)
    end
end)
CreateSlider(trollFrame, "Lag (ms)", 50, 1000, 200, function(v)
    Settings.FakeLagMs = v
    if Settings.FakeLag then NetworkClient:SetFakeLatency(v / 1000) end
end)

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
msgInput.Size = UDim2.new(1, -20, 0, 40)
msgInput.Position = UDim2.new(0, 10, 0, 0)
msgInput.PlaceholderText = "Spam message..."
msgInput.Text = Settings.SpamMessage
msgInput.Font = Enum.Font.GothamBold
msgInput.TextSize = 16
msgInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
msgInput.TextColor3 = Color3.fromRGB(255, 255, 255)
msgInput.BorderSizePixel = 0
Instance.new("UICorner", msgInput).CornerRadius = UDim.new(0, 6)
msgInput.Parent = trollFrame
msgInput.FocusLost:Connect(function() Settings.SpamMessage = msgInput.Text end)
CreateSlider(trollFrame, "Spam Interval", 1, 10, 3, function(v) Settings.SpamInterval = v end)

-- Anti-Ban Tab
local antiBanFrame = TabFrames[6]
CreateSwitch(antiBanFrame, "Anti-Kick", false, function(v) Settings.AntiKick = v end)
CreateSwitch(antiBanFrame, "Anti-Report", false, function(v) Settings.AntiReport = v end)
CreateSwitch(antiBanFrame, "Anti-Cheat Bypass", false, function(v)
    Settings.AntiCheatBypass = v
    if v then removeAntiCheat() end
end)

-- Sắp xếp nội dung các tab
for _, f in ipairs(TabFrames) do arrange(f) end

-- ===================== CHỨC NĂNG =====================
local function FindRemote()
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                for _, v in ipairs(tool:GetDescendants()) do
                    if v:IsA("RemoteEvent") then return v end
                end
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                for _, v in ipairs(tool:GetDescendants()) do
                    if v:IsA("RemoteEvent") then return v end
                end
            end
        end
    end
    return nil
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

local function IsTargetVisible(target)
    local head = target and target:FindFirstChild("Head")
    if not head then return false end
    local origin = Camera.CFrame.Position
    local dir = (head.Position - origin).Unit * 1000
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    if LocalPlayer.Character then params.FilterDescendantsInstances = {LocalPlayer.Character} end
    local result = workspace:Raycast(origin, dir, params)
    if result then return result.Instance:IsDescendantOf(target) end
    return false
end

local function GetClosestVisibleEnemy()
    local nearest = nil
    local minAngle = math.rad(Settings.FOVSize / 2)
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
    if enable then
        char.DescendantAdded:Connect(function(child)
            if child:IsA("BasePart") then child.CanCollide = false end
        end)
    end
end

local function HandleWeaponMods()
    if not Settings.FastFire and not Settings.InfAmmo then return end
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("NumberValue") then
            local name = v.Name:lower()
            if Settings.FastFire and (name:find("fire") or name:find("rate") or name:find("cooldown") or name:find("delay")) then
                v.Value = 0.01
            end
            if Settings.InfAmmo and (name:find("ammo") or name:find("clip") or name:find("bullets")) then
                local maxAmmo = tool:FindFirstChild("MaxAmmo") or tool:FindFirstChild("MaxAmmoValue")
                v.Value = (maxAmmo and maxAmmo:IsA("NumberValue") and maxAmmo.Value) or 999
            end
        end
    end
end

local function HandleFly(dt)
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

-- ===================== HÀM VẼ ESP (thêm vào) =====================
local function createDrawing(type, properties)
    if not DrawingSupported then return { Visible = false, Remove = function() end } end
    local d = Drawing.new(type)
    for k, v in pairs(properties) do d[k] = v end
    return d
end

local function removePlayerEsp(player)
    local cache = espCache[player]
    if cache then
        for _, d in pairs(cache) do if d and d.Remove then d:Remove() end end
        espCache[player] = nil
    end
end

local function updatePlayerEsp(player, character)
    if not DrawingSupported then return end
    local cache = espCache[player]
    if not cache then
        cache = {}
        if Settings.BoxESP then
            cache.box = createDrawing("Square", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=2, Transparency=0.5})
        end
        if Settings.NameESP then
            cache.name = createDrawing("Text", {Visible=false, Color=Color3.fromRGB(255,255,255), Size=14, Center=true, Outline=true, OutlineColor=Color3.fromRGB(0,0,0)})
        end
        if Settings.DistESP then
            cache.dist = createDrawing("Text", {Visible=false, Color=Color3.fromRGB(200,200,200), Size=13, Center=true, Outline=true, OutlineColor=Color3.fromRGB(0,0,0)})
        end
        if Settings.HealthESP then
            cache.healthBar = createDrawing("Line", {Visible=false, Color=Color3.fromRGB(0,255,0), Thickness=4, Transparency=0.7})
            cache.healthBg = createDrawing("Line", {Visible=false, Color=Color3.fromRGB(40,40,40), Thickness=4, Transparency=0.7})
        end
        espCache[player] = cache
    end

    local head = character and character:FindFirstChild("Head")
    local hum = character and character:FindFirstChild("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not head or not hum or hum.Health <= 0 then
        for _, d in pairs(cache) do if d and d.Visible ~= nil then d.Visible = false end end
        return
    end

    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then
        for _, d in pairs(cache) do if d and d.Visible ~= nil then d.Visible = false end end
        return
    end

    local rootPos = root and root.Position or head.Position
    local rootScreen = Camera:WorldToViewportPoint(rootPos)
    local distance = (Camera.CFrame.Position - rootPos).Magnitude
    local yMin = headPos.Y
    local yMax = rootScreen.Y
    local xMin = headPos.X - (yMax - yMin)/4
    local xMax = headPos.X + (yMax - yMin)/4

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
-- ===================== KẾT THÚC THÊM VÀO =====================

-- Fake FOV Circle
local FOVCircle
if DrawingSupported then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Thickness = 2
    FOVCircle.Transparency = 0.8
    FOVCircle.Color = Color3.fromRGB(255,0,0)
    FOVCircle.Radius = 100
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Filled = false
else
    FOVCircle = { Visible = false, Radius = 100, Position = Vector2.new(0,0), Color = Color3.fromRGB(255,0,0) }
end

-- ===================== VÒNG LẶP CHÍNH =====================
RunService.RenderStepped:Connect(function(dt)
    -- FOV Circle
    if DrawingSupported then
        FOVCircle.Visible = Settings.ShowFOV or Settings.Aimbot or Settings.SilentAim
        FOVCircle.Radius = Settings.FOVSize
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Color = Settings.FOVColor == "Red" and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
    end

    -- Aimbot
    if Settings.Aimbot then
        local target = GetClosestVisibleEnemy()
        AimTarget = target
        if target and target:FindFirstChild("Head") then
            local aimPos = target.Head.Position
            local vel = target.Head.Velocity
            if vel and vel.Magnitude > 1 then
                aimPos = aimPos + vel * ((Camera.CFrame.Position - aimPos).Magnitude / 500)
            end
            local smoothFactor = 1 - (Settings.AimbotSmooth - 1) / 19
            local alpha = 1 - math.exp(-dt * (smoothFactor * 25))
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, aimPos), math.clamp(alpha, 0.01, 1))
        end
    else
        AimTarget = nil
    end

    -- Trigger Bot
    if Settings.TriggerBot and tick() - lastTriggerTime >= 0.2 then
        lastTriggerTime = tick()
        local char = LocalPlayer.Character
        if char then
            local ray = Ray.new(Camera.CFrame.Position, Camera.CFrame.LookVector * 1000)
            local hit = workspace:FindPartOnRayWithIgnoreList(ray, {char}, false, true)
            if hit then
                local model = hit:FindFirstAncestorOfClass("Model")
                if model and Players:GetPlayerFromCharacter(model) then
                    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.05)
                    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end
            end
        end
    end

    -- ESP + Wallhack
    if DrawingSupported then
        local activePlayers = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                activePlayers[player] = true
                updatePlayerEsp(player, player.Character)
            end
        end
        for player, _ in pairs(espCache) do
            if not activePlayers[player] then removePlayerEsp(player) end
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then UpdateHighlight(player) end
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
        HandleWeaponMods()
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
    if Settings.Fly then
        Settings.Fly = false
        Settings.Fly = true
    end
    if Settings.Noclip then ToggleNoclip(true) end
    local hum = char:WaitForChild("Humanoid", 2)
    if hum then
        if Settings.SpeedHack then hum.WalkSpeed = Settings.SpeedValue end
        if Settings.HighJump then hum.JumpPower = Settings.JumpPower end
    end
end)

if LocalPlayer.Character then
    SetupSilentAim(Settings.SilentAim)
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        if Settings.HighJump then hum.JumpPower = Settings.JumpPower end
        if Settings.SpeedHack then hum.WalkSpeed = Settings.SpeedValue end
    end
end

if Settings.AntiCheatBypass then removeAntiCheat() end

print("[FPS GOD MENU v15] toandinh UI loaded successfully! (ESP fixed)")
