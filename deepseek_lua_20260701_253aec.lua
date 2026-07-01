--[[
    FPS GOD MENU v14 ULTIMATE – MOBILE (DELTA EXECUTOR)
    * Bố cục ngang 2 cột TỰ ĐỘNG CẬP NHẬT KHI KÉO RESIZE.
    * Vòng FOV luôn hiển thị khi bật Show FOV hoặc Aimbot/Silent Aim.
    * Nút to, dễ bấm, menu kéo thả, nút mở di chuyển được.
    * Đầy đủ hack: Aimbot, ESP, Fly, Noclip, Teleport, Fake Lag, Chat Spam...
    * Anti-Ban mạnh mẽ. Tối ưu hiệu suất.
]]

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local NetworkClient = game:GetService("NetworkClient")
local TeleportService = game:GetService("TeleportService")

-- Settings
local Settings = {
    Aimbot = false,
    AimbotSmooth = 10,
    ShowFOV = false,
    FOVSize = 100,
    FOVColor = "Red",
    SilentAim = false,
    TriggerBot = false,
    BoxESP = false,
    NameESP = false,
    DistESP = false,
    HealthESP = false,
    Wallhack = false,
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
    FakeLag = false,
    FakeLagMs = 200,
    ChatSpam = false,
    SpamMessage = "FPS GOD v14",
    SpamInterval = 3,
    AntiKick = true,
    AntiReport = true,
    AntiCheatBypass = true,
    AntiTeleport = true
}

local AimTarget = nil
local savedPitch = nil
local firing = false
local lastTriggerTime = 0
local lastWeaponCheck = 0
local espCache = {}
local highlightCache = {}
local currentTabIndex = 1  -- lưu tab đang mở để cập nhật grid khi resize

-- ===================== ANTI-BAN =====================
local oldKick = hookfunction(LocalPlayer.Kick, function(...)
    if Settings.AntiKick then return nil end
    return oldKick(...)
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
    task.spawn(function()
        local keywords = {"anti", "cheat", "ban", "detect", "hack", "ac_", "anticheat", "sentry", "banana"}
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
    end)
end
if Settings.AntiCheatBypass then removeAntiCheat() end
task.spawn(function() while task.wait(30) do if Settings.AntiCheatBypass then removeAntiCheat() end end end)
local oldTeleport = hookfunction(TeleportService.Teleport, function(...)
    if Settings.AntiTeleport then return nil end
    return oldTeleport(...)
end)

-- ===================== GIAO DIỆN =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPS_GodMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local viewport = Camera.ViewportSize
local scaleFactor = math.min(viewport.X / 450, viewport.Y / 700)
local UIScale = Instance.new("UIScale")
UIScale.Scale = scaleFactor
UIScale.Parent = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 440, 0, 620)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -310)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(0, 200, 100)

local TitleBar = Instance.new("TextButton")
TitleBar.Size = UDim2.new(1, -80, 0, 42)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
TitleBar.Text = "FPS GOD"
TitleBar.Font = Enum.Font.GothamBlack
TitleBar.TextSize = 20
TitleBar.TextColor3 = Color3.fromRGB(0, 255, 120)
TitleBar.Parent = MainFrame

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 42, 0, 42)
MinimizeBtn.Position = UDim2.new(1, -86, 0, 0)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
MinimizeBtn.Text = "━"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 24
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
MinimizeBtn.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 42, 0, 42)
CloseBtn.Position = UDim2.new(1, -44, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 24
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = MainFrame

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 56, 0, 56)
OpenBtn.Position = UDim2.new(0.5, -28, 0.5, -28)
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
OpenBtn.Text = "⚡"
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 30
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)

local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Size = UDim2.new(0, 32, 0, 32)
ResizeHandle.Position = UDim2.new(1, -32, 1, -32)
ResizeHandle.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
ResizeHandle.Text = "◢"
ResizeHandle.Font = Enum.Font.GothamBold
ResizeHandle.TextSize = 22
ResizeHandle.TextColor3 = Color3.fromRGB(255, 255, 255)
ResizeHandle.Parent = MainFrame

-- Kéo menu & resize
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

local resizing, resizeStart, startSize = false
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        startSize = MainFrame.Size
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then resizing = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStart
        local newWidth = math.clamp(startSize.X.Offset + delta.X / UIScale.Scale, 340, 650)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y / UIScale.Scale, 480, 800)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        -- Cập nhật lại bố cục tab hiện tại
        arrangeGrid(TabFrames[currentTabIndex], 5)
        if currentTabIndex == 4 then  -- teleport tab cần cập nhật danh sách
            updatePlayerList()
        end
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
    local mPos = MainFrame.Position
    OpenBtn.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset + MainFrame.Size.X.Offset/2 - 28, mPos.Y.Scale, mPos.Y.Offset + MainFrame.Size.Y.Offset/2 - 28)
end)
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Tabs
local TabButtons = Instance.new("Frame")
TabButtons.Size = UDim2.new(1, 0, 0, 44)
TabButtons.Position = UDim2.new(0, 0, 0, 44)
TabButtons.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
TabButtons.Parent = MainFrame

local tabs = {"Combat", "Visual", "Misc", "Teleport", "Troll"}
local TabFrames = {}
local TabBtns = {}
for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/5, -2, 1, -2)
    btn.Position = UDim2.new((i-1)/5, 1, 0, 1)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Parent = TabButtons
    TabBtns[i] = btn

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -6, 1, -94)
    content.Position = UDim2.new(0, 3, 0, 90)
    content.BackgroundTransparency = 1
    content.Visible = (i == 1)
    content.Parent = MainFrame
    TabFrames[i] = content

    btn.MouseButton1Click:Connect(function()
        for j, b in ipairs(TabBtns) do
            b.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            TabFrames[j].Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        content.Visible = true
        currentTabIndex = i
        arrangeGrid(content, 5)  -- cập nhật bố cục khi chuyển tab
    end)
end

-- UI helpers
local function CreateToggle(parent, name, default, callback)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.75, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btn.Text = "  " .. name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = frame

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 40, 0, 40)
    indicator.Position = UDim2.new(0.85, 0, 0.5, -20)
    indicator.BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(150, 40, 40)
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", indicator).Color = Color3.fromRGB(255, 255, 255)
    indicator.Parent = frame

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        indicator.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(150, 40, 40)
        callback(state)
    end)
    return frame
end

local function CreateSlider(parent, name, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 62)
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.Font = Enum.Font.GothamBold
    label.TextSize = 15
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 24)
    bar.Position = UDim2.new(0, 0, 0, 26)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
    bar.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)
    fill.Parent = bar

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 28, 0, 28)
    knob.Position = UDim2.new((default - min) / (max - min), -14, 0.5, -14)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", knob).Color = Color3.fromRGB(0, 200, 100)
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
            knob.Position = UDim2.new(alpha, -14, 0.5, -14)
            label.Text = name .. ": " .. value
            callback(value)
        end
    end)
    return frame
end

function arrangeGrid(container, gap)
    local children = {}
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextBox") then
            table.insert(children, child)
        end
    end
    if #children == 0 then return end
    local cols = 2
    local width = container.AbsoluteSize.X
    if width <= 0 then width = 400 end  -- phòng trường hợp chưa render
    local colWidth = (width - gap * (cols - 1)) / cols
    for i, child in ipairs(children) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        child.Size = UDim2.new(0, colWidth, 0, child.Size.Y.Offset)
        child.Position = UDim2.new(0, col * (colWidth + gap), 0, row * (child.Size.Y.Offset + gap))
    end
    if container:IsA("ScrollingFrame") then
        local totalHeight = math.ceil(#children / cols) * (children[1].Size.Y.Offset + gap) - gap
        container.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
    end
end

-- ===================== NỘI DUNG TAB =====================
-- Combat
local combatFrame = TabFrames[1]
CreateToggle(combatFrame, "Aimbot", false, function(v) Settings.Aimbot = v end)
CreateSlider(combatFrame, "Smooth", 1, 20, 10, function(v) Settings.AimbotSmooth = v end)
CreateToggle(combatFrame, "Show FOV", false, function(v) Settings.ShowFOV = v end)
CreateSlider(combatFrame, "FOV Size", 10, 800, 100, function(v) Settings.FOVSize = v end)
local fovColorBtn = Instance.new("TextButton")
fovColorBtn.Size = UDim2.new(1, 0, 0, 44)
fovColorBtn.Text = "FOV Color: Red"
fovColorBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
fovColorBtn.Font = Enum.Font.GothamBold
fovColorBtn.TextSize = 16
fovColorBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
fovColorBtn.Parent = combatFrame
fovColorBtn.MouseButton1Click:Connect(function()
    Settings.FOVColor = (Settings.FOVColor == "Red") and "Green" or "Red"
    fovColorBtn.Text = "FOV Color: " .. Settings.FOVColor
end)
CreateToggle(combatFrame, "Silent Aim", false, function(v) Settings.SilentAim = v; SetupSilentAim(v) end)
CreateToggle(combatFrame, "Trigger Bot", false, function(v) Settings.TriggerBot = v end)

-- Visual
local visualFrame = TabFrames[2]
CreateToggle(visualFrame, "Box ESP", false, function(v) Settings.BoxESP = v end)
CreateToggle(visualFrame, "Name ESP", false, function(v) Settings.NameESP = v end)
CreateToggle(visualFrame, "Distance ESP", false, function(v) Settings.DistESP = v end)
CreateToggle(visualFrame, "Health ESP", false, function(v) Settings.HealthESP = v end)
CreateToggle(visualFrame, "Wallhack", false, function(v)
    Settings.Wallhack = v
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then UpdateHighlight(p) end end
end)

-- Misc
local miscFrame = TabFrames[3]
CreateToggle(miscFrame, "Infinite Ammo", false, function(v) Settings.InfAmmo = v end)
CreateToggle(miscFrame, "No Recoil", false, function(v) Settings.NoRecoil = v end)
CreateToggle(miscFrame, "Fast Fire", false, function(v) Settings.FastFire = v end)
CreateToggle(miscFrame, "Speed Hack", false, function(v)
    Settings.SpeedHack = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = v and Settings.SpeedValue or 16 end
end)
CreateSlider(miscFrame, "Speed", 24, 200, 32, function(v)
    Settings.SpeedValue = v
    if Settings.SpeedHack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)
CreateToggle(miscFrame, "High Jump", false, function(v)
    Settings.HighJump = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.JumpPower = v and Settings.JumpPower or 50 end
end)
CreateSlider(miscFrame, "Jump Power", 50, 500, 100, function(v)
    Settings.JumpPower = v
    if Settings.HighJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = v
    end
end)
CreateToggle(miscFrame, "Fly", false, function(v) Settings.Fly = v; ToggleFly(v) end)
CreateSlider(miscFrame, "Fly Speed", 30, 9999, 50, function(v) Settings.FlySpeed = v end)
CreateToggle(miscFrame, "Noclip", false, function(v) Settings.Noclip = v; ToggleNoclip(v) end)

-- Teleport
local teleportFrame = TabFrames[4]
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(1, -10, 1, -10)
playerListFrame.Position = UDim2.new(0, 5, 0, 5)
playerListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
playerListFrame.ScrollBarThickness = 8
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.Parent = teleportFrame

function updatePlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local cols = 2
    local gap = 4
    local width = playerListFrame.AbsoluteSize.X - 10
    if width <= 0 then width = 400 end
    local colWidth = (width - gap * (cols - 1)) / cols
    local btnHeight = 40
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        count = count + 1
        local col = (count - 1) % cols
        local row = math.floor((count - 1) / cols)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, colWidth, 0, btnHeight)
        btn.Position = UDim2.new(0, 5 + col * (colWidth + gap), 0, 5 + row * (btnHeight + gap))
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        btn.Text = player.Name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 15
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    end
    local rows = math.ceil(count / cols)
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 5 + rows * (btnHeight + gap) + 10)
end
updatePlayerList()
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

-- Troll
local trollFrame = TabFrames[5]
CreateToggle(trollFrame, "Fake Lag", false, function(v)
    Settings.FakeLag = v
    if v then NetworkClient:SetFakeLatency(Settings.FakeLagMs / 1000)
    else NetworkClient:SetFakeLatency(0) end
end)
CreateSlider(trollFrame, "Lag (ms)", 50, 1000, 200, function(v)
    Settings.FakeLagMs = v
    if Settings.FakeLag then NetworkClient:SetFakeLatency(v / 1000) end
end)
CreateToggle(trollFrame, "Chat Spammer", false, function(v)
    Settings.ChatSpam = v
    if v then
        task.spawn(function()
            while Settings.ChatSpam do
                pcall(function()
                    local chatService = game:GetService("TextChatService")
                    local channel = chatService.TextChannels:FindFirstChild("RBXGeneral")
                    if channel then channel:SendAsync(Settings.SpamMessage) end
                end)
                pcall(function() Players:Chat(Settings.SpamMessage) end)
                task.wait(Settings.SpamInterval)
            end
        end)
    end
end)
local msgInput = Instance.new("TextBox")
msgInput.Size = UDim2.new(1, -10, 0, 40)
msgInput.PlaceholderText = "Spam message..."
msgInput.Text = Settings.SpamMessage
msgInput.Font = Enum.Font.GothamBold
msgInput.TextSize = 15
msgInput.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
msgInput.TextColor3 = Color3.fromRGB(255, 255, 255)
msgInput.Parent = trollFrame
msgInput.FocusLost:Connect(function() Settings.SpamMessage = msgInput.Text end)
CreateSlider(trollFrame, "Spam Interval", 1, 10, 3, function(v) Settings.SpamInterval = v end)

-- Sắp xếp ban đầu
for i = 1, #TabFrames do
    if i ~= 4 then
        arrangeGrid(TabFrames[i], 5)
    end
end
TabBtns[1].BackgroundColor3 = Color3.fromRGB(0, 200, 100)
TabFrames[1].Visible = true

-- ===================== DRAWING =====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Thickness = 2.5
FOVCircle.Transparency = 0.7
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Radius = 100
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

local function CreateDrawing(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props) do d[k] = v end
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
            cache.box = CreateDrawing("Square", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=2, Transparency=0.5})
        end
        if Settings.NameESP then
            cache.name = CreateDrawing("Text", {Visible=false, Color=Color3.fromRGB(255,255,255), Size=14, Center=true, Outline=true, OutlineColor=Color3.fromRGB(0,0,0)})
        end
        if Settings.DistESP then
            cache.dist = CreateDrawing("Text", {Visible=false, Color=Color3.fromRGB(200,200,200), Size=13, Center=true, Outline=true, OutlineColor=Color3.fromRGB(0,0,0)})
        end
        if Settings.HealthESP then
            cache.healthBar = CreateDrawing("Line", {Visible=false, Color=Color3.fromRGB(0,255,0), Thickness=4, Transparency=0.7})
            cache.healthBg = CreateDrawing("Line", {Visible=false, Color=Color3.fromRGB(40,40,40), Thickness=4, Transparency=0.7})
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
    local direction = (head.Position - origin).Unit * 1000
    local result = workspace:Raycast(origin, direction, RaycastParams.new())
    if result then
        return result.Instance:IsDescendantOf(target)
    end
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
        if part:IsA("BasePart") then
            part.CanCollide = not enable
        end
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
                local max = tool:FindFirstChild("MaxAmmo") or tool:FindFirstChild("MaxAmmoValue")
                v.Value = (max and max:IsA("NumberValue") and max.Value) or 999
            end
        end
    end
end

-- ===================== VÒNG LẶP =====================
RunService.RenderStepped:Connect(function(dt)
    -- FOV visibility
    FOVCircle.Visible = Settings.ShowFOV or Settings.Aimbot or Settings.SilentAim
    FOVCircle.Radius = Settings.FOVSize
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Color = Settings.FOVColor == "Red" and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)

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
end)

RunService.Heartbeat:Connect(function()
    if Settings.Fly then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if hrp and hum then
                local bv = hrp:FindFirstChild("FlyBV")
                local bg = hrp:FindFirstChild("FlyBG")
                if bv and bg then
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
            end
        end
    end

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
    if Settings.Noclip then
        ToggleNoclip(true)
    end
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

print("[FPS GOD MENU v14 Ultimate] FOV hiển thị, bố cục ngang tự động resize, tất cả sẵn sàng!")