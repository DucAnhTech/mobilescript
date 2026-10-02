--[[
    ╔══════════════════════════════════════════════════════════╗
    ║       DEV MASTER MOBILE ULTIMATE EDITION                 ║
    ║       Engineered specifically for Mobile Touch           ║
    ║       Thumbstick Fly · On-Screen Aim · Tap Teleport      ║
    ╚══════════════════════════════════════════════════════════╝
]]

if _G.DevMasterMobileUnload then
    pcall(_G.DevMasterMobileUnload)
end
_G.stopMobileScript = false

-- ==========================================================
-- 1. COMPATIBILITY & SERVICES
-- ==========================================================
local function missing(typeCheck, func, fallback)
    if type(func) == typeCheck then return func end
    return fallback
end

local _writefile = writefile
local _readfile = readfile

writefile = missing("function", _writefile) and function(f, d, s) if s then return pcall(_writefile, f, d) end _writefile(f, d) end
readfile  = missing("function", _readfile) and function(f, s) if s then return pcall(_readfile, f) end return _readfile(f) end
isfile    = missing("function", isfile, function(f) local ok, r = pcall(function() return readfile(f) end) return ok and r ~= nil and r ~= "" end)
get_hidden_gui = get_hidden_gui or gethui or function() return game:GetService("CoreGui") end

local syn = syn or {}
syn.protect_gui = syn.protect_gui or function(g) return g end

local Svc = {
    UIS        = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Players    = game:GetService("Players"),
    Stats      = game:GetService("Stats"),
    Lighting   = game:GetService("Lighting"),
    Tween      = game:GetService("TweenService"),
    CoreGui    = game:GetService("CoreGui"),
    Workspace  = game:GetService("Workspace"),
}

local LP = Svc.Players.LocalPlayer or Svc.Players.PlayerAdded:Wait()
local Camera = Svc.Workspace.CurrentCamera
local targetParent = (pcall(get_hidden_gui) and get_hidden_gui()) or Svc.CoreGui or LP:WaitForChild("PlayerGui")

local Connections = {}
local function addConn(c) table.insert(Connections, c) return c end

-- ==========================================================
-- 2. STATE & CONFIGURATION
-- ==========================================================
local C = {
    BG          = Color3.fromRGB(13, 13, 20),
    BG2         = Color3.fromRGB(18, 18, 28),
    CARD        = Color3.fromRGB(22, 22, 34),
    ACCENT      = Color3.fromRGB(0, 200, 255),
    ACCENT_DIM  = Color3.fromRGB(0, 80, 110),
    TEXT        = Color3.fromRGB(230, 230, 245),
    TEXT_DIM    = Color3.fromRGB(140, 150, 175),
    BORDER      = Color3.fromRGB(35, 45, 65),
    TOG_ON      = Color3.fromRGB(0, 180, 120),
    TOG_OFF     = Color3.fromRGB(40, 45, 60),
    RED         = Color3.fromRGB(220, 50, 70),
    GREEN       = Color3.fromRGB(0, 200, 120),
    YELLOW      = Color3.fromRGB(230, 180, 0),
}

local State = {
    fly            = false,
    flySpeed       = 50,
    flyUp          = false,
    flyDown        = false,

    walkSpeed      = false,
    walkSpeedVal   = 50,
    jumpPower      = false,
    jumpPowerVal   = 100,
    infJump        = false,
    noclip         = false,
    godmode        = false,

    aimbot         = false,
    aimHolding     = false,
    aimFov         = 120,
    aimSmooth      = 0.25,

    hitboxExpander = false,
    hitboxSize     = 8,

    tapTp          = false,
    esp            = false,
    aggressiveFps  = false,
}

local originalLighting = {
    GlobalShadows = Svc.Lighting.GlobalShadows,
    FogEnd        = Svc.Lighting.FogEnd,
    Brightness    = Svc.Lighting.Brightness,
    ClockTime     = Svc.Lighting.ClockTime,
    Quality       = settings().Rendering.QualityLevel,
}

-- ==========================================================
-- 3. MOBILE TOUCH UTILITIES
-- ==========================================================
local function makeTouchDraggable(handle, target)
    target = target or handle
    local dragging = false
    local dragStart, startPos

    addConn(handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            startPos = target.Position
        end
    end))

    addConn(Svc.UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = inp.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    addConn(Svc.UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
end

-- ==========================================================
-- 4. MOBILE SCREEN GUI ROOT
-- ==========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevMasterMobile"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = targetParent
syn.protect_gui(screenGui)

-- Circular floating toggle button
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 50, 0, 50)
floatBtn.Position = UDim2.new(0, 15, 0.35, 0)
floatBtn.BackgroundColor3 = C.BG2
floatBtn.Text = "⚡"
floatBtn.TextColor3 = C.ACCENT
floatBtn.TextSize = 24
floatBtn.Font = Enum.Font.GothamBold
floatBtn.BorderSizePixel = 0
floatBtn.Parent = screenGui
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
local floatStroke = Instance.new("UIStroke", floatBtn)
floatStroke.Color = C.ACCENT
floatStroke.Thickness = 2
makeTouchDraggable(floatBtn)

-- Main Menu Window (Mobile-Friendly Dimensions: 340 x 300)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 300)
mainFrame.Position = UDim2.new(0.5, -170, 0.5, -150)
mainFrame.BackgroundColor3 = C.BG
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = C.ACCENT_DIM
mainStroke.Thickness = 1.5
makeTouchDraggable(mainFrame)

-- Topbar
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = C.BG2
topBar.BorderSizePixel = 0

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "📱 DEV MASTER MOBILE"
title.TextColor3 = C.TEXT
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -36, 0.5, -15)
closeBtn.BackgroundColor3 = C.RED
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

floatBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- Tab Bar
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, -16, 0, 32)
tabContainer.Position = UDim2.new(0, 8, 0, 48)
tabContainer.BackgroundTransparency = 1

local tabLayout = Instance.new("UIListLayout", tabContainer)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)

local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, -16, 1, -88)
contentFrame.Position = UDim2.new(0, 8, 0, 84)
contentFrame.BackgroundTransparency = 1

local tabs = {}
local function createTab(name, icon)
    local btn = Instance.new("TextButton", tabContainer)
    btn.Size = UDim2.new(0.23, 0, 1, 0)
    btn.BackgroundColor3 = C.BG2
    btn.Text = icon .. " " .. name
    btn.TextColor3 = C.TEXT_DIM
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("ScrollingFrame", contentFrame)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = C.ACCENT_DIM
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 6)
    local pad = Instance.new("UIPadding", page)
    pad.PaddingRight = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 8)

    tabs[name] = { Btn = btn, Page = page }

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.Page.Visible = false
            t.Btn.BackgroundColor3 = C.BG2
            t.Btn.TextColor3 = C.TEXT_DIM
        end
        page.Visible = true
        btn.BackgroundColor3 = C.ACCENT_DIM
        btn.TextColor3 = C.ACCENT
    end)

    return page
end

local pageMove   = createTab("Move", "🏃")
local pageCombat = createTab("Combat", "⚔")
local pageVisual = createTab("Visual", "👁")
local pageLag    = createTab("FixLag", "🚀")

tabs["Move"].Page.Visible = true
tabs["Move"].Btn.BackgroundColor3 = C.ACCENT_DIM
tabs["Move"].Btn.TextColor3 = C.ACCENT

-- ==========================================================
-- 5. UI COMPONENT GENERATORS (Touch-Friendly)
-- ==========================================================
local function createMobileToggle(parent, labelText, defaultState, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = C.CARD
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.68, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = C.TEXT
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local togBtn = Instance.new("TextButton", row)
    togBtn.Size = UDim2.new(0, 48, 0, 24)
    togBtn.Position = UDim2.new(1, -56, 0.5, -12)
    togBtn.BackgroundColor3 = defaultState and C.TOG_ON or C.TOG_OFF
    togBtn.Text = defaultState and "ON" or "OFF"
    togBtn.TextColor3 = Color3.new(1, 1, 1)
    togBtn.Font = Enum.Font.GothamBold
    togBtn.TextSize = 10
    togBtn.BorderSizePixel = 0
    Instance.new("UICorner", togBtn).CornerRadius = UDim.new(0, 6)

    local state = defaultState
    local function setToggle(val)
        state = val
        togBtn.BackgroundColor3 = state and C.TOG_ON or C.TOG_OFF
        togBtn.Text = state and "ON" or "OFF"
        if callback then callback(state) end
    end

    togBtn.MouseButton1Click:Connect(function()
        setToggle(not state)
    end)

    return { Set = setToggle, Get = function() return state end }
end

local function createMobileSlider(parent, labelText, minV, maxV, defV, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundColor3 = C.CARD
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.55, 0, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = C.TEXT_DIM
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valBox = Instance.new("TextBox", row)
    valBox.Size = UDim2.new(0, 52, 0, 18)
    valBox.Position = UDim2.new(1, -62, 0, 5)
    valBox.BackgroundColor3 = C.BG
    valBox.Text = tostring(defV)
    valBox.TextColor3 = C.ACCENT
    valBox.Font = Enum.Font.GothamBold
    valBox.TextSize = 11
    valBox.ClearTextOnFocus = false
    Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 4)

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0, 32)
    track.BackgroundColor3 = C.BORDER
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(math.clamp((defV - minV)/(maxV - minV), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = C.ACCENT
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local currentVal = defV
    local dragging = false

    local function updateSlider(v, skipBox)
        currentVal = math.max(v, minV)
        local pct = math.clamp((currentVal - minV)/(maxV - minV), 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        if not skipBox then valBox.Text = tostring(math.round(currentVal)) end
        if callback then callback(currentVal) end
    end

    local function updateTouch(x)
        local relX = x - track.AbsolutePosition.X
        local pct = math.clamp(relX / track.AbsoluteSize.X, 0, 1)
        updateSlider(minV + (maxV - minV) * pct)
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateTouch(inp.Position.X)
        end
    end)
    addConn(Svc.UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
            updateTouch(inp.Position.X)
        end
    end))
    addConn(Svc.UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    valBox.FocusLost:Connect(function()
        local n = tonumber(valBox.Text)
        if n then updateSlider(n) else valBox.Text = tostring(currentVal) end
    end)
end

-- ==========================================================
-- 6. MOBILE ON-SCREEN FLY / COMBAT OVERLAYS
-- ==========================================================
-- Flight Up/Down touch pads
local flyUpBtn = Instance.new("TextButton", screenGui)
flyUpBtn.Size = UDim2.new(0, 52, 0, 52)
flyUpBtn.Position = UDim2.new(1, -70, 0.45, -30)
flyUpBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
flyUpBtn.Text = "▲\nUP"
flyUpBtn.TextColor3 = Color3.new(1, 1, 1)
flyUpBtn.Font = Enum.Font.GothamBold
flyUpBtn.TextSize = 12
flyUpBtn.BorderSizePixel = 0
flyUpBtn.Visible = false
Instance.new("UICorner", flyUpBtn).CornerRadius = UDim.new(0, 10)
makeTouchDraggable(flyUpBtn)

local flyDownBtn = Instance.new("TextButton", screenGui)
flyDownBtn.Size = UDim2.new(0, 52, 0, 52)
flyDownBtn.Position = UDim2.new(1, -70, 0.45, 30)
flyDownBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 90)
flyDownBtn.Text = "▼\nDOWN"
flyDownBtn.TextColor3 = Color3.new(1, 1, 1)
flyDownBtn.Font = Enum.Font.GothamBold
flyDownBtn.TextSize = 12
flyDownBtn.BorderSizePixel = 0
flyDownBtn.Visible = false
Instance.new("UICorner", flyDownBtn).CornerRadius = UDim.new(0, 10)
makeTouchDraggable(flyDownBtn)

flyUpBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        State.flyUp = true
    end
end)
flyUpBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        State.flyUp = false
    end
end)

flyDownBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        State.flyDown = true
    end
end)
flyDownBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        State.flyDown = false
    end
end)

-- Mobile Aim Button (Replaces MouseButton2 Hold)
local aimTouchBtn = Instance.new("TextButton", screenGui)
aimTouchBtn.Size = UDim2.new(0, 56, 0, 56)
aimTouchBtn.Position = UDim2.new(1, -75, 0.28, 0)
aimTouchBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
aimTouchBtn.Text = "AIM"
aimTouchBtn.TextColor3 = Color3.new(1, 1, 1)
aimTouchBtn.Font = Enum.Font.GothamBold
aimTouchBtn.TextSize = 13
aimTouchBtn.BorderSizePixel = 0
aimTouchBtn.Visible = false
Instance.new("UICorner", aimTouchBtn).CornerRadius = UDim.new(1, 0)
local aimStroke = Instance.new("UIStroke", aimTouchBtn)
aimStroke.Color = Color3.new(1, 1, 1)
aimStroke.Thickness = 1.5
makeTouchDraggable(aimTouchBtn)

aimTouchBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        State.aimHolding = true
        aimTouchBtn.BackgroundColor3 = C.GREEN
    end
end)
aimTouchBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        State.aimHolding = false
        aimTouchBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
    end
end)

-- ==========================================================
-- 7. MOVEMENT ENGINE (Touch Joystick Vector-Driven)
-- ==========================================================
local _flyVel, _flyGyro, _flyConn

local function stopMobileFly()
    if _flyConn then _flyConn:Disconnect(); _flyConn = nil end
    local char = LP.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            if _flyVel then _flyVel:Destroy(); _flyVel = nil end
            if _flyGyro then _flyGyro:Destroy(); _flyGyro = nil end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    flyUpBtn.Visible = false
    flyDownBtn.Visible = false
end

local function startMobileFly()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    _flyVel = Instance.new("BodyVelocity")
    _flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    _flyVel.Velocity = Vector3.zero
    _flyVel.Parent   = root

    _flyGyro = Instance.new("BodyGyro")
    _flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    _flyGyro.CFrame    = root.CFrame
    _flyGyro.Parent    = root

    hum.PlatformStand = true
    flyUpBtn.Visible = true
    flyDownBtn.Visible = true

    _flyConn = Svc.RunService.RenderStepped:Connect(function()
        if not State.fly or not root or not root.Parent then
            stopMobileFly()
            return
        end

        local moveDir = hum.MoveDirection
        local camCF = Camera.CFrame
        local finalVelocity = Vector3.zero

        if moveDir.Magnitude > 0 then
            local forward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
            local right   = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
            local projected = (forward * moveDir.Z * -1) + (right * moveDir.X)
            finalVelocity += projected * State.flySpeed
        end

        if State.flyUp then finalVelocity += Vector3.new(0, State.flySpeed, 0) end
        if State.flyDown then finalVelocity -= Vector3.new(0, State.flySpeed, 0) end

        _flyVel.Velocity = finalVelocity
        _flyGyro.CFrame  = camCF
    end)
end

-- ==========================================================
-- 8. COMBAT SUBSYSTEM
-- ==========================================================
local originalHitboxes = {}

local function resetHitboxes()
    for root, data in pairs(originalHitboxes) do
        if root and root.Parent then
            pcall(function()
                root.Size = data.Size
                root.Transparency = data.Transparency
                root.CanCollide = data.CanCollide
                root.Color = data.Color
            end)
        end
    end
    table.clear(originalHitboxes)
end

local function getClosestPlayerCenterScreen()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, shortestDist = nil, State.aimFov

    for _, p in ipairs(Svc.Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local head = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = head
                    end
                end
            end
        end
    end
    return closest
end

-- ==========================================================
-- 9. POPULATE MOBILE UI PAGES
-- ==========================================================

-- ── MOVE TAB ──
createMobileToggle(pageMove, "Thumbstick Fly", false, function(on)
    State.fly = on
    if on then startMobileFly() else stopMobileFly() end
end)
createMobileSlider(pageMove, "Fly Speed (1-1000)", 10, 1000, 50, function(v) State.flySpeed = v end)

createMobileToggle(pageMove, "Speed Hack (WalkSpeed)", false, function(on)
    State.walkSpeed = on
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not on and hum then hum.WalkSpeed = 16 end
end)
createMobileSlider(pageMove, "Walk Speed (1-1000)", 16, 1000, 50, function(v) State.walkSpeedVal = v end)

createMobileToggle(pageMove, "Jump Power Hack", false, function(on)
    State.jumpPower = on
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not on and hum then hum.UseJumpPower = true; hum.JumpPower = 50 end
end)
createMobileSlider(pageMove, "Jump Power (1-1000)", 50, 1000, 100, function(v) State.jumpPowerVal = v end)

createMobileToggle(pageMove, "Infinite Jump", false, function(on) State.infJump = on end)
createMobileToggle(pageMove, "Noclip", false, function(on) State.noclip = on end)
createMobileToggle(pageMove, "Godmode (Anti-Void)", false, function(on)
    State.godmode = on
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not on and hum then hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end
end)

-- ── COMBAT TAB ──
createMobileToggle(pageCombat, "Mobile Aimbot", false, function(on)
    State.aimbot = on
    aimTouchBtn.Visible = on
end)
createMobileSlider(pageCombat, "FOV Radius", 30, 400, 120, function(v) State.aimFov = v end)
createMobileSlider(pageCombat, "Smoothness", 0.05, 1, 0.25, function(v) State.aimSmooth = v end)

createMobileToggle(pageCombat, "Hitbox Expander", false, function(on)
    State.hitboxExpander = on
    if not on then resetHitboxes() end
end)
createMobileSlider(pageCombat, "Hitbox Size", 2, 50, 8, function(v) State.hitboxSize = v end)

-- ── VISUAL TAB ──
createMobileToggle(pageVisual, "Player ESP", false, function(on) State.esp = on end)
createMobileToggle(pageVisual, "Tap Teleport", false, function(on) State.tapTp = on end)

-- Tap Teleport touch event
addConn(Svc.UIS.InputBegan:Connect(function(inp, gpe)
    if _G.stopMobileScript or gpe then return end
    if State.tapTp and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1) then
        local pos = inp.Position
        local ray = Camera:ViewportPointToRay(pos.X, pos.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { LP.Character }
        params.FilterType = Enum.RaycastFilterType.Exclude

        local res = Svc.Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if res then
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local rot = hrp.CFrame - hrp.CFrame.Position
                hrp.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0)) * rot
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
end))

-- ── FIX LAG TAB ──
local savedEffects = {}
local savedParts   = {}
local fixLagConns  = {}

local function applyMobileOptimization(inst)
    if not inst or not inst.Parent then return end
    if inst:FindFirstAncestorOfClass("Tool") or inst:FindFirstAncestorOfClass("Accessory") then return end
    local mod = inst:FindFirstAncestorOfClass("Model")
    if mod and mod:FindFirstChildOfClass("Humanoid") then return end
    if inst:IsA("GuiBase2d") or inst:IsA("Terrain") then return end

    if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
        if savedEffects[inst] == nil then savedEffects[inst] = { Prop = "Enabled", Val = inst.Enabled } end
        inst.Enabled = false
    elseif inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
        if savedEffects[inst] == nil then savedEffects[inst] = { Prop = "Enabled", Val = inst.Enabled } end
        inst.Enabled = false
    elseif inst:IsA("PostProcessEffect") then
        if savedEffects[inst] == nil then savedEffects[inst] = { Prop = "Enabled", Val = inst.Enabled } end
        inst.Enabled = false
    elseif inst:IsA("BasePart") and not inst:IsA("MeshPart") then
        if not savedParts[inst] then savedParts[inst] = { Mat = inst.Material, Shadow = inst.CastShadow } end
        inst.Material = Enum.Material.SmoothPlastic
        inst.CastShadow = false
    end
end

createMobileToggle(pageLag, "Aggressive Fix Lag", false, function(on)
    State.aggressiveFps = on
    if on then
        Svc.Lighting.GlobalShadows = false
        Svc.Lighting.FogEnd = 9e9
        for _, v in ipairs(Svc.Lighting:GetDescendants()) do applyMobileOptimization(v) end
        for _, v in ipairs(Svc.Workspace:GetDescendants()) do applyMobileOptimization(v) end

        table.insert(fixLagConns, Svc.Workspace.DescendantAdded:Connect(function(v)
            if State.aggressiveFps then applyMobileOptimization(v) end
        end))
    else
        for _, c in ipairs(fixLagConns) do pcall(function() c:Disconnect() end) end
        table.clear(fixLagConns)
        Svc.Lighting.GlobalShadows = originalLighting.GlobalShadows
        Svc.Lighting.FogEnd        = originalLighting.FogEnd

        for inst, data in pairs(savedEffects) do
            if inst and inst.Parent then pcall(function() inst[data.Prop] = data.Val end) end
        end
        table.clear(savedEffects)

        for inst, data in pairs(savedParts) do
            if inst and inst.Parent then
                pcall(function()
                    inst.Material   = data.Mat
                    inst.CastShadow = data.Shadow
                end)
            end
        end
        table.clear(savedParts)
    end
end)

-- ==========================================================
-- 10. RUNTIME BACKGROUND PIPELINES
-- ==========================================================
local lastSafeCF = nil

-- RenderStepped
addConn(Svc.RunService.RenderStepped:Connect(function()
    if _G.stopMobileScript then return end

    -- Mobile Aimbot Tracking (Only locks when holding on-screen AIM button)
    if State.aimbot and State.aimHolding then
        local target = getClosestPlayerCenterScreen()
        if target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, target.Position), State.aimSmooth)
        end
    end

    -- Godmode
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if State.godmode and hum then
        if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        if hrp then
            local d = Svc.Workspace.FallenPartsDestroyHeight
            if hrp.Position.Y > d + 20 and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                lastSafeCF = hrp.CFrame
            end
            if lastSafeCF and hrp.Position.Y <= d + 10 then
                hrp.CFrame = lastSafeCF + Vector3.new(0, 5, 0)
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
end))

-- Stepped
addConn(Svc.RunService.Stepped:Connect(function()
    if _G.stopMobileScript then return end

    -- Noclip
    if State.noclip and LP.Character then
        for _, p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end

    -- Hitbox Expander
    if State.hitboxExpander then
        for _, p in ipairs(Svc.Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local ph = p.Character:FindFirstChildOfClass("Humanoid")
                local pr = p.Character:FindFirstChild("HumanoidRootPart")
                if ph and ph.Health > 0 and pr and pr:IsA("BasePart") then
                    if not originalHitboxes[pr] then
                        originalHitboxes[pr] = {
                            Size         = pr.Size,
                            Transparency = pr.Transparency,
                            CanCollide   = pr.CanCollide,
                            Color        = pr.Color
                        }
                    end
                    pr.Size         = Vector3.new(State.hitboxSize, State.hitboxSize, State.hitboxSize)
                    pr.Transparency = 0.7
                    pr.Color        = Color3.fromRGB(255, 0, 0)
                    pr.CanCollide   = false
                end
            end
        end
    end

    -- Speed & Jump
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if State.walkSpeed then hum.WalkSpeed = State.walkSpeedVal end
        if State.jumpPower then hum.UseJumpPower = true; hum.JumpPower = State.jumpPowerVal end
    end
end))

-- Jump Request for InfJump
addConn(Svc.UIS.JumpRequest:Connect(function()
    if _G.stopMobileScript then return end
    if State.infJump then
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- Mobile ESP Subsystem
local espCache = {}
task.spawn(function()
    while not _G.stopMobileScript and screenGui.Parent do
        if State.esp then
            for _, p in ipairs(Svc.Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local char = p.Character
                    local head = char:FindFirstChild("Head")
                    local hum  = char:FindFirstChildOfClass("Humanoid")
                    if head and hum and hum.Health > 0 then
                        if not espCache[p] then
                            local hl = Instance.new("Highlight", char)
                            hl.FillColor = C.ACCENT
                            hl.OutlineColor = Color3.new(1, 1, 1)
                            espCache[p] = hl
                        end
                    elseif espCache[p] then
                        espCache[p]:Destroy()
                        espCache[p] = nil
                    end
                elseif espCache[p] then
                    espCache[p]:Destroy()
                    espCache[p] = nil
                end
            end
        else
            for p, hl in pairs(espCache) do pcall(function() hl:Destroy() end) end
            table.clear(espCache)
        end
        task.wait(1)
    end
end)

-- ==========================================================
-- 11. UNLOAD CLEANUP
-- ==========================================================
local function unloadMobile()
    _G.stopMobileScript = true
    stopMobileFly()
    resetHitboxes()

    Svc.Lighting.GlobalShadows = originalLighting.GlobalShadows
    Svc.Lighting.FogEnd        = originalLighting.FogEnd

    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed     = 16
        hum.UseJumpPower  = true
        hum.JumpPower     = 50
        hum.PlatformStand = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
    end

    for _, c in ipairs(Connections) do
        if c and typeof(c) == "RBXScriptConnection" then pcall(function() c:Disconnect() end) end
    end
    table.clear(Connections)

    for p, hl in pairs(espCache) do pcall(function() hl:Destroy() end) end
    table.clear(espCache)

    if screenGui and screenGui.Parent then screenGui:Destroy() end
    print("✅ DEV MASTER MOBILE unloaded cleanly.")
end

_G.DevMasterMobileUnload = unloadMobile
closeBtn.MouseButton1Click:Connect(unloadMobile)

print("✅ DEV MASTER MOBILE ULTIMATE LOADED!")