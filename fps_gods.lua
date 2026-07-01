--[[
    FPS GOD MENU v7 – MOBILE (DELTA EXECUTOR)
    * Vòng FOV chỉ còn viền (không tô trong)
    * Thêm Wallhack (Chams) – sáng địch xuyên tường
    * ESP hoạt động ổn định (cache Drawing)
    * Aimbot, Fly, High Jump, Silent Aim, Trigger Bot...
]]

-- Dịch vụ
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

-- Cấu hình
local Settings = {
    -- Combat
    Aimbot = false,
    AimbotSmooth = 10,
    FOVSize = 100,
    FOVColor = "Red",
    SilentAim = false,
    TriggerBot = false,

    -- Visual
    BoxESP = false,
    NameESP = false,
    DistESP = false,
    HealthESP = false,
    Wallhack = false,       -- Chams / Glow

    -- Misc
    InfAmmo = false,
    NoRecoil = false,
    FastFire = false,
    SpeedHack = false,
    SpeedValue = 32,
    Fly = false,
    FlySpeed = 50,
    HighJump = false,
    JumpPower = 100
}

local AimTarget = nil
local savedPitch = nil
local firing = false

-- Cache cho ESP (giữ Drawing tồn tại, chỉ cập nhật)
local espCache = {}          -- [player] = { box, name, dist, healthBar1, healthBar2, ... }

-- Highlight cache cho Wallhack
local highlightCache = {}    -- [player] = Highlight

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
MainFrame.Size = UDim2.new(0, 350, 0, 520)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

-- Title bar
local TitleBar = Instance.new("TextButton")
TitleBar.Size = UDim2.new(1, -30, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
TitleBar.BorderSizePixel = 0
TitleBar.Text = "FPS GOD  |  KÉO ĐỂ DI CHUYỂN"
TitleBar.Font = Enum.Font.GothamBold
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.TextSize = 14
TitleBar.Parent = MainFrame

-- Nút thu nhỏ
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -30, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "━"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 18
MinimizeBtn.Parent = MainFrame

-- Nút resize
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Size = UDim2.new(0, 28, 0, 28)
ResizeHandle.Position = UDim2.new(1, -28, 1, -28)
ResizeHandle.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
ResizeHandle.BorderSizePixel = 0
ResizeHandle.Text = "◢"
ResizeHandle.Font = Enum.Font.GothamBold
ResizeHandle.TextColor3 = Color3.fromRGB(255, 255, 255)
ResizeHandle.TextSize = 18
ResizeHandle.Parent = MainFrame

-- Nút mở menu (ẩn ban đầu)
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

-- ===================== KÉO & RESIZE =====================
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
        local newWidth = math.clamp(startSize.X.Offset + delta.X / UIScale.Scale, 280, 600)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y / UIScale.Scale, 400, 800)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

-- Ẩn/hiện
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

-- ===================== TABS =====================
local TabButtons = Instance.new("Frame")
TabButtons.Size = UDim2.new(1, 0, 0, 38)
TabButtons.Position = UDim2.new(0, 0, 0, 34)
TabButtons.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TabButtons.BorderSizePixel = 0
TabButtons.Parent = MainFrame

local Tabs = {"Combat", "Visual", "Misc"}
local TabFrames = {}
local TabBtns = {}
for i, name in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/3, -2, 1, -2)
    btn.Position = UDim2.new((i-1)/3, 1, 0, 1)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Parent = TabButtons
    TabBtns[i] = btn

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -6, 1, -82)
    content.Position = UDim2.new(0, 3, 0, 74)
    content.BackgroundTransparency = 1
    content.Visible = (i == 1)
    content.Parent = MainFrame
    TabFrames[i] = content

    btn.MouseButton1Click:Connect(function()
        for j, b in ipairs(TabBtns) do
            b.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
            TabFrames[j].Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
        content.Visible = true
    end)
end

-- ===================== TIỆN ÍCH GIAO DIỆN =====================
local function CreateToggle(parent, name, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 48)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = frame

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 32, 0, 32)
    indicator.Position = UDim2.new(0.85, 0, 0.5, -16)
    indicator.BackgroundColor3 = default and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    indicator.Parent = frame

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        indicator.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        callback(state)
    end)
    return frame
end

local function CreateSlider(parent, name, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 64)
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
    bar.Size = UDim2.new(1, 0, 0, 24)
    bar.Position = UDim2.new(0, 0, 0, 26)
    bar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)
    bar.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 6)
    fill.Parent = bar

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 28, 0, 28)
    knob.Position = UDim2.new((default - min) / (max - min), -14, 0.5, -14)
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
            knob.Position = UDim2.new(alpha, -14, 0.5, -14)
            label.Text = name .. ": " .. value
            callback(value)
        end
    end)
    return frame
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

-- ===================== TAB COMBAT =====================
local combatFrame = TabFrames[1]
CreateToggle(combatFrame, "Aimbot", false, function(val) Settings.Aimbot = val end)
CreateSlider(combatFrame, "Smooth", 1, 20, 10, function(val) Settings.AimbotSmooth = val end)
CreateSlider(combatFrame, "FOV Size", 10, 800, 100, function(val) Settings.FOVSize = val end)

local fovColorBtn = Instance.new("TextButton")
fovColorBtn.Size = UDim2.new(1, -10, 0, 44)
fovColorBtn.Text = "FOV Color: Red"
fovColorBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
fovColorBtn.Font = Enum.Font.GothamBold
fovColorBtn.TextSize = 16
fovColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
fovColorBtn.Parent = combatFrame
fovColorBtn.MouseButton1Click:Connect(function()
    if Settings.FOVColor == "Red" then
        Settings.FOVColor = "Green"
        fovColorBtn.Text = "FOV Color: Green"
    else
        Settings.FOVColor = "Red"
        fovColorBtn.Text = "FOV Color: Red"
    end
end)

CreateToggle(combatFrame, "Silent Aim", false, function(val) Settings.SilentAim = val; SetupSilentAim(val) end)
CreateToggle(combatFrame, "Trigger Bot", false, function(val) Settings.TriggerBot = val end)

-- ===================== TAB VISUAL =====================
local visualFrame = TabFrames[2]
CreateToggle(visualFrame, "Box ESP", false, function(val) Settings.BoxESP = val end)
CreateToggle(visualFrame, "Name ESP", false, function(val) Settings.NameESP = val end)
CreateToggle(visualFrame, "Distance ESP", false, function(val) Settings.DistESP = val end)
CreateToggle(visualFrame, "Health ESP", false, function(val) Settings.HealthESP = val end)
CreateToggle(visualFrame, "Wallhack (Chams)", false, function(val)
    Settings.Wallhack = val
    -- Cập nhật highlight cho tất cả người chơi hiện tại
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            UpdateHighlight(player)
        end
    end
end)

-- ===================== TAB MISC =====================
local miscFrame = TabFrames[3]
CreateToggle(miscFrame, "Infinite Ammo", false, function(val) Settings.InfAmmo = val end)
CreateToggle(miscFrame, "No Recoil", false, function(val) Settings.NoRecoil = val end)
CreateToggle(miscFrame, "Fast Fire", false, function(val) Settings.FastFire = val end)
CreateToggle(miscFrame, "Speed Hack", false, function(val)
    Settings.SpeedHack = val
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = val and Settings.SpeedValue or 16 end
end)
CreateSlider(miscFrame, "Speed Value", 24, 100, 32, function(val)
    Settings.SpeedValue = val
    if Settings.SpeedHack and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
end)

CreateToggle(miscFrame, "Fly", false, function(val)
    Settings.Fly = val
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if val then
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
end)
CreateSlider(miscFrame, "Fly Speed", 30, 200, 50, function(val) Settings.FlySpeed = val end)

CreateToggle(miscFrame, "High Jump", false, function(val)
    Settings.HighJump = val
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        hum.JumpPower = val and Settings.JumpPower or 50
    end
end)
CreateSlider(miscFrame, "Jump Height", 50, 500, 100, function(val)
    Settings.JumpPower = val
    if Settings.HighJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = val
    end
end)

-- Sắp xếp các tab
for _, f in ipairs(TabFrames) do arrange(f) end
TabBtns[1].BackgroundColor3 = Color3.fromRGB(70, 130, 200)
TabFrames[1].Visible = true

-- ===================== DRAWING =====================
-- Vòng FOV (chỉ viền, không tô)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.Transparency = 0.8
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Radius = 100
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
FOVCircle.Filled = false  -- Chỉ đường viền

-- Hàm tạo Drawing (cho ESP cache)
local function createDrawing(type, properties)
    local drawing = Drawing.new(type)
    for k, v in pairs(properties) do
        drawing[k] = v
    end
    return drawing
end

-- Hàm xóa cache ESP của một người chơi
local function removePlayerEsp(player)
    local cache = espCache[player]
    if cache then
        for _, drawing in pairs(cache) do
            if drawing then drawing:Remove() end
        end
        espCache[player] = nil
    end
end

-- Hàm tạo/cập nhật ESP cho một người chơi
local function updatePlayerEsp(player, character)
    local cache = espCache[player]
    -- Nếu chưa có cache, tạo mới
    if not cache then
        cache = {}
        if Settings.BoxESP then
            cache.box = createDrawing("Square", {
                Visible = false, Color = Color3.fromRGB(255,255,255), Thickness = 2, Transparency = 0.5
            })
        end
        if Settings.NameESP then
            cache.name = createDrawing("Text", {
                Visible = false, Color = Color3.fromRGB(255,255,255), Size = 14, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0,0,0)
            })
        end
        if Settings.DistESP then
            cache.dist = createDrawing("Text", {
                Visible = false, Color = Color3.fromRGB(200,200,200), Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0,0,0)
            })
        end
        if Settings.HealthESP then
            cache.healthBar = createDrawing("Line", {
                Visible = false, Color = Color3.fromRGB(0,255,0), Thickness = 4, Transparency = 0.7
            })
            cache.healthBg = createDrawing("Line", {
                Visible = false, Color = Color3.fromRGB(40,40,40), Thickness = 4, Transparency = 0.7
            })
        end
        espCache[player] = cache
    end

    -- Cập nhật vị trí / hiển thị
    local head = character and character:FindFirstChild("Head")
    local humanoid = character and character:FindFirstChild("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not head or not humanoid or humanoid.Health <= 0 then
        -- Ẩn tất cả
        for _, drawing in pairs(cache) do
            if drawing then drawing.Visible = false end
        end
        return
    end

    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then
        for _, drawing in pairs(cache) do
            if drawing then drawing.Visible = false end
        end
        return
    end

    local rootPos = root and root.Position or head.Position
    local rootScreen = Camera:WorldToViewportPoint(rootPos)
    local distance = (Camera.CFrame.Position - rootPos).Magnitude
    local yMin = headPos.Y
    local yMax = rootScreen.Y
    local xMin = headPos.X - (yMax - yMin)/4
    local xMax = headPos.X + (yMax - yMin)/4

    -- Box
    if cache.box then
        cache.box.Visible = Settings.BoxESP
        cache.box.Size = Vector2.new(xMax - xMin, yMax - yMin)
        cache.box.Position = Vector2.new(xMin, yMin)
    end
    -- Name
    if cache.name then
        cache.name.Visible = Settings.NameESP
        cache.name.Text = player.Name
        cache.name.Position = Vector2.new(xMin + (xMax-xMin)/2, yMin - 18)
    end
    -- Distance
    if cache.dist then
        cache.dist.Visible = Settings.DistESP
        cache.dist.Text = math.floor(distance).."m"
        cache.dist.Position = Vector2.new(xMin + (xMax-xMin)/2, yMax + 2)
    end
    -- Health bar
    if cache.healthBar and cache.healthBg then
        cache.healthBar.Visible = Settings.HealthESP
        cache.healthBg.Visible = Settings.HealthESP
        local health = humanoid.Health / humanoid.MaxHealth
        local barWidth = 4
        local barX = xMin - barWidth - 2
        local barY = yMin
        local barH = yMax - yMin
        cache.healthBar.From = Vector2.new(barX, barY + barH)
        cache.healthBar.To = Vector2.new(barX, barY + barH * (1 - health))
        cache.healthBg.From = Vector2.new(barX, barY)
        cache.healthBg.To = Vector2.new(barX, barY + barH)
    end
end

-- ===================== WALLHACK (CHAMS) =====================
local function UpdateHighlight(player)
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if Settings.Wallhack and hum and hum.Health > 0 then
        -- Nếu chưa có Highlight thì tạo
        if not highlightCache[player] then
            local highlight = Instance.new("Highlight")
            highlight.Name = "Chams"
            highlight.FillColor = Color3.fromRGB(255, 100, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.3
            highlight.OutlineTransparency = 0
            highlight.Enabled = true
            highlight.Adornee = char
            highlight.Parent = char
            highlightCache[player] = highlight
        end
    else
        -- Xóa highlight nếu có
        local hl = highlightCache[player]
        if hl then
            hl:Destroy()
            highlightCache[player] = nil
        end
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
    local oldFireServer = remote.FireServer
    SilentAimHook = hookfunction(remote.FireServer, function(self, ...)
        local args = {...}
        if Settings.SilentAim and AimTarget and AimTarget:FindFirstChild("Head") then
            args[1] = AimTarget.Head.Position
        end
        return oldFireServer(self, unpack(args))
    end)
end

local function IsTargetVisible(target)
    local head = target and target:FindFirstChild("Head")
    if not head then return false end
    local camPos = Camera.CFrame.Position
    local rayOrigin = camPos
    local rayDir = (head.Position - camPos).Unit * 1000
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(rayOrigin, rayDir, rayParams)
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
            local direction = (headPos - camPos).Unit
            local angle = math.acos(math.clamp(camLook:Dot(direction), -1, 1))
            if angle < minAngle then
                if IsTargetVisible(char) then
                    minAngle = angle
                    nearest = char
                end
            end
        end
    end
    return nearest
end

local function HandleAimbot(dt)
    if not Settings.Aimbot then
        AimTarget = nil
        return
    end
    local target = GetClosestVisibleEnemy()
    AimTarget = target
    if target and target:FindFirstChild("Head") then
        local aimPos = target.Head.Position
        local vel = target.Head.Velocity
        if vel and vel.Magnitude > 1 then
            local distance = (Camera.CFrame.Position - aimPos).Magnitude
            local bulletSpeed = 500
            aimPos = aimPos + vel * (distance / bulletSpeed)
        end
        local targetCF = CFrame.lookAt(Camera.CFrame.Position, aimPos)
        local smoothFactor = 1 - (Settings.AimbotSmooth - 1) / 19
        local alpha = 1 - math.exp(-dt * (smoothFactor * 25))
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, math.clamp(alpha, 0.01, 1))
    end
end

local lastTriggerTime = 0
local function HandleTriggerBot()
    if not Settings.TriggerBot then return end
    if tick() - lastTriggerTime < 0.2 then return end
    local char = LocalPlayer.Character
    if not char then return end
    local rayOrigin = Camera.CFrame.Position
    local rayDir = Camera.CFrame.LookVector * 1000
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {char}
    local result = workspace:Raycast(rayOrigin, rayDir, rayParams)
    if result then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model and Players:GetPlayerFromCharacter(model) then
            lastTriggerTime = tick()
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.05)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end

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

local lastWeaponCheck = 0
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
        local forwardInput = -localMove.Z
        local rightInput = localMove.X
        bv.Velocity = (camCF.LookVector * forwardInput + camCF.RightVector * rightInput) * Settings.FlySpeed
    else
        bv.Velocity = Vector3.zero
    end
    bg.CFrame = Camera.CFrame
end

-- ===================== VÒNG LẶP CHÍNH =====================
RunService.RenderStepped:Connect(function(dt)
    -- Cập nhật FOV Circle
    FOVCircle.Visible = Settings.Aimbot or Settings.SilentAim
    FOVCircle.Radius = Settings.FOVSize
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Color = Settings.FOVColor == "Red" and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)

    -- Aimbot
    HandleAimbot(dt)
    -- Trigger Bot
    HandleTriggerBot()
    -- No Recoil
    if Settings.NoRecoil and firing and savedPitch then
        local currentYaw = Camera.CFrame:toEulerAnglesYXZ()
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.Angles(savedPitch, currentYaw, 0)
    end
    -- Weapon mods
    if tick() - lastWeaponCheck > 0.5 then
        lastWeaponCheck = tick()
        HandleWeaponMods()
    end
    -- Fly
    HandleFly()

    -- Cập nhật ESP cho tất cả người chơi
    local activePlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            activePlayers[player] = true
            local char = player.Character
            updatePlayerEsp(player, char)
        end
    end
    -- Xóa ESP cache của người chơi đã thoát
    for player, _ in pairs(espCache) do
        if not activePlayers[player] then
            removePlayerEsp(player)
        end
    end

    -- Cập nhật Wallhack (gọi trong loop để xử lý khi nhân vật mới xuất hiện, nhưng có thể tối ưu hơn bằng sự kiện)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            UpdateHighlight(player)
        end
    end
end)

-- ===================== SỰ KIỆN NHÂN VẬT =====================
-- Khi người chơi khác thay đổi nhân vật, cập nhật highlight và ESP
Players.PlayerRemoving:Connect(function(player)
    removePlayerEsp(player)
    if highlightCache[player] then
        highlightCache[player]:Destroy()
        highlightCache[player] = nil
    end
end)

-- Theo dõi nhân vật mới của bất kỳ người chơi nào
local function onCharacterAdded(character, player)
    if player == LocalPlayer then
        -- Xử lý cho LocalPlayer
        task.wait(0.5)
        SetupSilentAim(Settings.SilentAim)
        if Settings.Fly then
            Settings.Fly = false
            Settings.Fly = true
        end
        local hum = character:WaitForChild("Humanoid", 2)
        if hum then
            if Settings.SpeedHack then hum.WalkSpeed = Settings.SpeedValue end
            if Settings.HighJump then hum.JumpPower = Settings.JumpPower end
        end
    else
        -- Người chơi khác
        -- Xóa cache cũ nếu có
        removePlayerEsp(player)
        -- Cập nhật highlight
        UpdateHighlight(player)
    end
end

-- Kết nối sự kiện CharacterAdded cho tất cả người chơi
for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(char, player)
    end)
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(char, player)
    end)
end)

-- Khởi tạo cho LocalPlayer
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character, LocalPlayer)
end
SetupSilentAim(Settings.SilentAim)

print("[FPS GOD MENU v7] Sẵn sàng! FOV viền, Wallhack sáng địch, ESP hoạt động mượt.")