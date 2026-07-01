```--[[
    FPS GOD MENU v16 LANDSCAPE ULTIMATE – TỐI ƯU MOBILE
    Thiết kế ngang, nút to, chữ rõ, menu mỏng, tab ngang, scale slider.
    Hiệu năng cao: giảm vẽ, cập nhật có giới hạn, dùng task.delay.
    Giữ nguyên mọi chức năng từ v15.
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
    SpamMessage = "FPS GOD v16",
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

-- ===================== GIAO DIỆN (UI) LANDSCAPE =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPS_GodMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

-- UI Scale ban đầu dựa trên viewport, có thể điều chỉnh sau
local viewport = Camera.ViewportSize
local baseScale = math.min(viewport.X / 800, viewport.Y / 600)  -- scale base cho landscape
local UIScale = Instance.new("UIScale")
UIScale.Scale = baseScale
UIScale.Parent = ScreenGui

-- MainFrame – rộng, mỏng, tối ưu landscape
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 600, 0, 360)  -- landscape: rộng 600, cao 360
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

-- Tiêu đề
local TitleBar = Instance.new("TextButton")
TitleBar.Size = UDim2.new(1, -50, 0, 32)  -- chừa chỗ cho nút scale
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
TitleBar.BorderSizePixel = 0
TitleBar.Text = "FPS GOD v16  |  KÉO ĐỂ DI CHUYỂN"
TitleBar.Font = Enum.Font.GothamBold
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.TextSize = 14
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
TitleBar.Parent = MainFrame

-- Nút thu nhỏ
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -30, 0, 2)  -- nằm bên phải titlebar
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "━"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 18
MinimizeBtn.Parent = MainFrame

-- Nút mở lại khi thu nhỏ
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 48, 0, 48)
OpenBtn.Position = UDim2.new(0.5, -24, 0.5, -24)
OpenBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
OpenBtn.BorderSizePixel = 0
OpenBtn.Text = "⚡"
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.TextSize = 24
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)

-- ===================== SCALE SLIDER =====================
local ScaleFrame = Instance.new("Frame")
ScaleFrame.Size = UDim2.new(1, 0, 0, 28)
ScaleFrame.Position = UDim2.new(0, 0, 0, 34)
ScaleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ScaleFrame.BorderSizePixel = 0
ScaleFrame.Parent = MainFrame

local ScaleLabel = Instance.new("TextLabel")
ScaleLabel.Size = UDim2.new(0, 60, 1, 0)
ScaleLabel.Position = UDim2.new(0, 4, 0, 0)
ScaleLabel.BackgroundTransparency = 1
ScaleLabel.Text = "Scale UI"
ScaleLabel.Font = Enum.Font.GothamSemibold
ScaleLabel.TextSize = 13
ScaleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ScaleLabel.TextXAlignment = Enum.TextXAlignment.Left
ScaleLabel.Parent = ScaleFrame

local ScaleBar = Instance.new("Frame")
ScaleBar.Size = UDim2.new(1, -150, 0, 22)
ScaleBar.Position = UDim2.new(0, 70, 0.5, -11)
ScaleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ScaleBar.BorderSizePixel = 0
Instance.new("UICorner", ScaleBar).CornerRadius = UDim.new(0, 6)
ScaleBar.Parent = ScaleFrame

local ScaleFill = Instance.new("Frame")
ScaleFill.Size = UDim2.new(UIScale.Scale / 1.5, 0, 1, 0)  -- giả sử max 1.5
ScaleFill.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
ScaleFill.BorderSizePixel = 0
Instance.new("UICorner", ScaleFill).CornerRadius = UDim.new(0, 6)
ScaleFill.Parent = ScaleBar

local ScaleKnob = Instance.new("TextButton")
ScaleKnob.Size = UDim2.new(0, 24, 0, 24)
ScaleKnob.Position = UDim2.new(UIScale.Scale / 1.5, -12, 0.5, -12)
ScaleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ScaleKnob.BorderSizePixel = 0
ScaleKnob.Text = ""
Instance.new("UICorner", ScaleKnob).CornerRadius = UDim.new(1, 0)
ScaleKnob.Parent = ScaleBar

local scaleDragging = false
ScaleKnob.MouseButton1Down:Connect(function() scaleDragging = true end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        scaleDragging = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if scaleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local mousePos = UIS:GetMouseLocation()
        local barAbsPos = ScaleBar.AbsolutePosition
        local barAbsSize = ScaleBar.AbsoluteSize
        local alpha = math.clamp((mousePos.X - barAbsPos.X) / barAbsSize.X, 0, 1)
        local newScale = 0.5 + alpha * 1.0  -- scale từ 0.5 đến 1.5
        UIScale.Scale = newScale
        ScaleFill.Size = UDim2.new(alpha, 0, 1, 0)
        ScaleKnob.Position = UDim2.new(alpha, -12, 0.5, -12)
        ScaleLabel.Text = "Scale: " .. string.format("%.1f", newScale)
    end
end)

-- Hiển thị giá trị scale hiện tại
ScaleLabel.Text = "Scale: " .. string.format("%.1f", UIScale.Scale)

-- ===================== TAB BAR NGANG =====================
local TabButtons = Instance.new("Frame")
TabButtons.Size = UDim2.new(1, 0, 0, 38)
TabButtons.Position = UDim2.new(0, 0, 0, 64)  -- dưới ScaleFrame
TabButtons.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TabButtons.BorderSizePixel = 0
TabButtons.Parent = MainFrame

local Tabs = {"Combat", "Visual", "Misc", "Teleport", "Troll", "Anti-Ban"}
local TabBtns = {}
local currentTab = 1
local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, -4, 1, -106)
ContentScroll.Position = UDim2.new(0, 2, 0, 104)
ContentScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 6
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.Parent = MainFrame

local function ClearContent()
    for _, child in ipairs(ContentScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextBox") or child:IsA("TextLabel") or child:IsA("ScrollingFrame") then
            child:Destroy()
        end
    end
end

-- ===================== UI HELPERS (TO, NÚT RÕ) =====================
local function CreateToggle(name, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 52)   -- cao 52px, nút to
    frame.BackgroundTransparency = 1
    frame.Parent = ContentScroll

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -60, 1, 0)  -- chừa chỗ cho indicator
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 18                     -- chữ to hơn
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = frame

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 36, 0, 36)
    indicator.Position = UDim2.new(1, -46, 0.5, -18)
    indicator.BackgroundColor3 = default and Color3.fromRGB(0, 230, 0) or Color3.fromRGB(230, 0, 0)
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    indicator.Parent = frame

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        indicator.BackgroundColor3 = state and Color3.fromRGB(0, 230, 0) or Color3.fromRGB(230, 0, 0)
        callback(state)
    end)
    return frame
end

local function CreateSlider(name, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 72)   -- cao 72px
    frame.BackgroundTransparency = 1
    frame.Parent = ContentScroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 28)
    bar.Position = UDim2.new(0, 0, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
    bar.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)
    fill.Parent = bar

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 30, 0, 30)
    knob.Position = UDim2.new((default - min) / (max - min), -15, 0.5, -15)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Text = ""
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    knob.Parent = bar

    local draggingSlider = false
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
            local value = math.floor(min + (max - min) * alpha)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            knob.Position = UDim2.new(alpha, -15, 0.5, -15)
            label.Text = name .. ": " .. value
            callback(value)
        end
    end)
    return frame
end

-- Tạo nội dung tab hiện tại
local function BuildTab(tabIndex)
    ClearContent()
    local yPos = 4
    if tabIndex == 1 then        -- Combat
        CreateToggle("Aimbot", Settings.Aimbot, function(v) Settings.Aimbot = v end)
        CreateSlider("Smooth", 1, 20, Settings.AimbotSmooth, function(v) Settings.AimbotSmooth = v end)
        CreateToggle("Show FOV", Settings.ShowFOV, function(v) Settings.ShowFOV = v end)
        CreateSlider("FOV Size", 20, 800, Settings.FOVSize, function(v) Settings.FOVSize = v end)

        local fovColorBtn = Instance.new("TextButton")
        fovColorBtn.Size = UDim2.new(1, -10, 0, 48)
        fovColorBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        fovColorBtn.BorderSizePixel = 0
        fovColorBtn.Text = "FOV Color: " .. Settings.FOVColor
        fovColorBtn.Font = Enum.Font.GothamSemibold
        fovColorBtn.TextSize = 18
        fovColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        fovColorBtn.Parent = ContentScroll
        fovColorBtn.MouseButton1Click:Connect(function()
            Settings.FOVColor = (Settings.FOVColor == "Red") and "Green" or "Red"
            fovColorBtn.Text = "FOV Color: " .. Settings.FOVColor
        end)

        CreateToggle("Silent Aim", Settings.SilentAim, function(v) Settings.SilentAim = v; SetupSilentAim(v) end)
        CreateToggle("Trigger Bot", Settings.TriggerBot, function(v) Settings.TriggerBot = v end)

    elseif tabIndex == 2 then    -- Visual
        CreateToggle("Box ESP", Settings.BoxESP, function(v) Settings.BoxESP = v end)
        CreateToggle("Name ESP", Settings.NameESP, function(v) Settings.NameESP = v end)
        CreateToggle("Distance ESP", Settings.DistESP, function(v) Settings.DistESP = v end)
        CreateToggle("Health ESP", Settings.HealthESP, function(v) Settings.HealthESP = v end)
        CreateToggle("Wallhack (Chams)", Settings.Wallhack, function(v)
            Settings.Wallhack = v
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then UpdateHighlight(player) end
            end
        end)

    elseif tabIndex == 3 then    -- Misc
        CreateToggle("Infinite Ammo", Settings.InfAmmo, function(v) Settings.InfAmmo = v end)
        CreateToggle("No Recoil", Settings.NoRecoil, function(v) Settings.NoRecoil = v end)
        CreateToggle("Fast Fire", Settings.FastFire, function(v) Settings.FastFire = v end)
        CreateToggle("Speed Hack", Settings.SpeedHack, function(v)
            Settings.SpeedHack = v
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = v and Settings.SpeedValue or 16 end
        end)
        CreateSlider("Speed Value", 24, 200, Settings.SpeedValue, function(v)
            Settings.SpeedValue = v
            if Settings.SpeedHack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = v
            end
        end)
        CreateToggle("Fly", Settings.Fly, function(v)
            Settings.Fly = v
            ToggleFly(v)
        end)
        CreateSlider("Fly Speed", 30, 200, Settings.FlySpeed, function(v) Settings.FlySpeed = v end)
        CreateToggle("High Jump", Settings.HighJump, function(v)
            Settings.HighJump = v
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.JumpPower = v and Settings.JumpPower or 50 end
        end)
        CreateSlider("Jump Height", 50, 500, Settings.JumpPower, function(v)
            Settings.JumpPower = v
            if Settings.HighJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = v
            end
        end)
        CreateToggle("Noclip", Settings.Noclip, function(v)
            Settings.Noclip = v
            ToggleNoclip(v)
        end)

    elseif tabIndex == 4 then    -- Teleport
        local playerList = Instance.new("ScrollingFrame")
        playerList.Size = UDim2.new(1, -10, 1, -10)
        playerList.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        playerList.ScrollBarThickness = 8
        playerList.BorderSizePixel = 0
        playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
        playerList.Parent = ContentScroll

        local function UpdateTeleportList()
            -- Xóa cũ
            for _, child in ipairs(playerList:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            local y = 4
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -10, 0, 44)
                btn.Position = UDim2.new(0, 5, 0, y)
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                btn.BorderSizePixel = 0
                btn.Text = player.Name
                btn.Font = Enum.Font.GothamSemibold
                btn.TextSize = 18
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Parent = playerList
                btn.MouseButton1Click:Connect(function()
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local targetChar = player.Character
                    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    if myRoot and targetRoot then
                        myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 2, 0)
                    end
                end)
                y = y + 48
            end
            playerList.CanvasSize = UDim2.new(0, 0, 0, y + 10)
        end
        UpdateTeleportList()
        Players.PlayerAdded:Connect(function()
            task.delay(0.5, UpdateTeleportList)  -- delay tránh loop nhiều
        end)
        Players.PlayerRemoving:Connect(function()
            task.delay(0.5, UpdateTeleportList)
        end)

    elseif tabIndex == 5 then    -- Troll
        CreateToggle("Fake Lag", Settings.FakeLag, function(v)
            Settings.FakeLag = v
            if v then
                NetworkClient:SetFakeLatency(Settings.FakeLagMs / 1000)
            else
                NetworkClient:SetFakeLatency(0)
            end
        end)
        CreateSlider("Lag (ms)", 50, 1000, Settings.FakeLagMs, function(v)
            Settings.FakeLagMs = v
            if Settings.FakeLag then NetworkClient:SetFakeLatency(v / 1000) end
        end)
        CreateToggle("Chat Spammer", Settings.ChatSpam, function(v)
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
        msgInput.Size = UDim2.new(1, -10, 0, 48)
        msgInput.PlaceholderText = "Spam message..."
        msgInput.Text = Settings.SpamMessage
        msgInput.Font = Enum.Font.GothamSemibold
        msgInput.TextSize = 18
        msgInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        msgInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        msgInput.BorderSizePixel = 0
        msgInput.Parent = ContentScroll
        msgInput.FocusLost:Connect(function() Settings.SpamMessage = msgInput.Text end)
        CreateSlider("Spam Interval", 1, 10, Settings.SpamInterval, function(v) Settings.SpamInterval = v end)

    elseif tabIndex == 6 then    -- Anti-Ban
        CreateToggle("Anti-Kick", Settings.AntiKick, function(v) Settings.AntiKick = v end)
        CreateToggle("Anti-Report", Settings.AntiReport, function(v) Settings.AntiReport = v end)
        CreateToggle("Anti-Cheat Bypass", Settings.AntiCheatBypass, function(v)
            Settings.AntiCheatBypass = v
            if v then removeAntiCheat() end
        end)
    end

    -- Cập nhật CanvasSize sau khi thêm nội dung
    local totalHeight = 0
    for _, child in ipairs(ContentScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextBox") or child:IsA("ScrollingFrame") then
            totalHeight = totalHeight + child.Size.Y.Offset + 6
        end
    end
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
end

-- Tạo tab buttons
for i, name in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#Tabs, -4, 1, -2)  -- nút to, cách đều
    btn.Position = UDim2.new((i-1)/#Tabs, 2, 0, 1)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Parent = TabButtons
    TabBtns[i] = btn

    btn.MouseButton1Click:Connect(function()
        for j, b in ipairs(TabBtns) do
            b.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        end
        btn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
        currentTab = i
        BuildTab(i)
    end)
end

-- Chọn tab đầu tiên
TabBtns[1].BackgroundColor3 = Color3.fromRGB(70, 130, 200)
BuildTab(1)

-- ===================== KÉO & MINIMIZE =====================
local dragging, dragStart, startPos = false
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X / UIScale.Scale, startPos.Y.Scale, startPos.Y.Offset + delta.Y / UIScale.Scale)
    end
end)

local openDragging, openDragStart, openStartPos = false
OpenBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        openDragging = true
        openDragStart = input.Position
        openStartPos = OpenBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then openDragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if openDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - openDragStart
        OpenBtn.Position = UDim2.new(openStartPos.X.Scale, openStartPos.X.Offset + delta.X / UIScale.Scale, openStartPos.Y.Scale, openStartPos.Y.Offset + delta.Y / UIScale.Scale)
    end
end)

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

-- ===================== DRAWING OBJECTS (GIỮ LẠI ÍT NHẤT) =====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.Transparency = 0.8
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Radius = 100
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
FOVCircle.Filled = false

local function createDrawing(type, properties)
    local d = Drawing.new(type)
    for k, v in pairs(properties) do d[k] = v end
    return d
end

local function removePlayerEsp(player)
    local cache = espCache[player]
    if cache then
        for _, d in pairs(cache) do if d then d:Remove() end end
        espCache[player] = nil
    end
end

local function updatePlayerEsp(player, character)
    local cache = espCache[player]
    if not cache then
        cache = {}
        if Settings.BoxESP then
            cache.box = createDrawing("Square", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=2, Transparency=0.5})
        end
        if Settings.NameESP then
            cache.name = createDrawing("Text", {Visible=false, Color=Color3.fromRGB(255,255,255), Size=16, Center=true, Outline=true, OutlineColor=Color3.fromRGB(0,0,0)})
        end
        if Settings.DistESP then
            cache.dist = createDrawing("Text", {Visible=false, Color=Color3.fromRGB(200,200,200), Size=14, Center=true, Outline=true, OutlineColor=Color3.fromRGB(0,0,0)})
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
        for _, d in pairs(cache) do if d then d.Visible = false end end
        return
    end

    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then
        for _, d in pairs(cache) do if d then d.Visible = false end end
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
        if Settings.BoxESP then
            cache.box.Size = Vector2.new(xMax - xMin, yMax - yMin)
            cache.box.Position = Vector2.new(xMin, yMin)
        end
    end
    if cache.name then
        cache.name.Visible = Settings.NameESP
        if Settings.NameESP then
            cache.name.Text = player.Name
            cache.name.Position = Vector2.new(xMin + (xMax-xMin)/2, yMin - 20)
        end
    end
    if cache.dist then
        cache.dist.Visible = Settings.DistESP
        if Settings.DistESP then
            cache.dist.Text = math.floor(distance).."m"
            cache.dist.Position = Vector2.new(xMin + (xMax-xMin)/2, yMax + 4)
        end
    end
    if cache.healthBar and cache.healthBg then
        cache.healthBar.Visible = Settings.HealthESP
        cache.healthBg.Visible = Settings.HealthESP
        if Settings.HealthESP then
            local health = hum.Health / hum.MaxHealth
            local barW = 5
            local barX = xMin - barW - 3
            local barY = yMin
            local barH = yMax - yMin
            cache.healthBar.From = Vector2.new(barX, barY + barH)
            cache.healthBar.To = Vector2.new(barX, barY + barH * (1 - health))
            cache.healthBg.From = Vector2.new(barX, barY)
            cache.healthBg.To = Vector2.new(barX, barY + barH)
        end
    end
end

-- ===================== WALLHACK =====================
local function UpdateHighlight(player)
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

-- ===================== AIMBOT, SILENT AIM, TRIGGER =====================
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

local function HandleFly()
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

-- ===================== VÒNG LẶP CHÍNH (TỐI ƯU) =====================
-- ESP update cách quãng, giảm tải
local lastEspUpdate = 0
local espUpdateInterval = 0.05  -- 20fps cho ESP

RunService.RenderStepped:Connect(function(dt)
    -- FOV Circle
    FOVCircle.Visible = Settings.ShowFOV or Settings.Aimbot or Settings.SilentAim
    if FOVCircle.Visible then
        FOVCircle.Radius = Settings.FOVSize
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Color = Settings.FOVColor == "Red" and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
    end

    -- Aimbot (cần tốc độ cao)
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

    -- Trigger Bot (kiểm tra từng frame, nhưng có cooldown)
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

    -- ESP + Wallhack (cập nhật có khoảng cách)
    if tick() - lastEspUpdate >= espUpdateInterval then
        lastEspUpdate = tick()
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
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then UpdateHighlight(player) end
        end
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

-- ===================== XỬ LÝ SỰ KIỆN NHÂN VẬT =====================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    SetupSilentAim(Settings.SilentAim)
    if Settings.Fly then
        Settings.Fly = false
        task.wait(0.1)
        Settings.Fly = true
        ToggleFly(true)
    end
    if Settings.Noclip then ToggleNoclip(true) end
    local hum = char:WaitForChild("Humanoid", 2)
    if hum then
        if Settings.SpeedHack then hum.WalkSpeed = Settings.SpeedValue end
        if Settings.HighJump then hum.JumpPower = Settings.JumpPower end
    end
end)

-- Khởi động lần đầu nếu đã có nhân vật
if LocalPlayer.Character then
    SetupSilentAim(Settings.SilentAim)
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        if Settings.HighJump then hum.JumpPower = Settings.JumpPower end
        if Settings.SpeedHack then hum.WalkSpeed = Settings.SpeedValue end
    end
end

if Settings.AntiCheatBypass then removeAntiCheat() end

print("[FPS GOD MENU v16 Landscape] Sẵn sàng! Menu ngang, nút to, tối ưu mobile.")
