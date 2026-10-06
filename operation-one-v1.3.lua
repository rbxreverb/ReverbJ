--[[
    Reverb J
    The preferred, primary compact UI runtime for Reverb scripts.

    The older ReverbUI runtime is retained only for legacy scripts.

    "Reverb J" is an internal project name and is never displayed in the UI.
]]

local Services = setmetatable({}, {
    __index = function(self, name)
        local service = game:GetService(name)
        rawset(self, name, service)
        return service
    end,
})

local Players = Services.Players
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local HttpService = Services.HttpService
local CoreGui = Services.CoreGui

local Library = {
    Windows = {},
    Open = true,
    Version = "0.6.1-preview",
    AntiAfkEnabled = true,
    _AntiAfkConnection = nil,
    _AntiAfkControls = {},
    HeaderLogos = {},
}

local Theme = {
    Background = Color3.fromRGB(3, 9, 14),
    Surface = Color3.fromRGB(4, 12, 18),
    Raised = Color3.fromRGB(13, 22, 29),
    RaisedBottom = Color3.fromRGB(8, 16, 22),
    Field = Color3.fromRGB(10, 18, 25),
    FieldBottom = Color3.fromRGB(5, 12, 18),
    Hover = Color3.fromRGB(17, 29, 38),
    Selected = Color3.fromRGB(4, 45, 57),
    Accent = Color3.fromRGB(19, 215, 240),
    AccentBright = Color3.fromRGB(31, 226, 248),
    AccentDark = Color3.fromRGB(4, 45, 57),
    AccentDarker = Color3.fromRGB(3, 27, 35),
    Text = Color3.fromRGB(237, 241, 245),
    Muted = Color3.fromRGB(142, 158, 179),
    NavMuted = Color3.fromRGB(176, 190, 210),
    Border = Color3.fromRGB(28, 40, 49),
    BorderSoft = Color3.fromRGB(19, 30, 38),
    BorderBright = Color3.fromRGB(36, 72, 84),
    Highlight = Color3.fromRGB(95, 119, 133),
    Off = Color3.fromRGB(45, 59, 72),
    OffDark = Color3.fromRGB(33, 46, 58),
    SliderOff = Color3.fromRGB(35, 48, 59),
    Danger = Color3.fromRGB(225, 76, 86),
}

local Type = {
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold = Enum.Font.GothamBold,
}

local REVERB_WEBSITE = "https://rbxreverb.com/"
local REVERB_DISCORD = "https://discord.com/invite/xKh6WsgJem"
local UI_PREFS_PATH = "Reverb/ui_preferences.json"
local DESKTOP_WIDTH = 844
local DESKTOP_HEIGHT = 606
local HEADER_HEIGHT = 73
local SIDEBAR_WIDTH = 202
local DESKTOP_RENDER_SCALE = 0.70

local function create(className, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        if property ~= "Parent" then
            if property == "Font" then
                if value == Enum.Font.Gotham then
                    value = Type.Regular
                elseif value == Enum.Font.GothamMedium then
                    value = Type.Medium
                elseif value == Enum.Font.GothamBold then
                    value = Type.Bold
                end
            end
            object[property] = value
        end
    end
    object.Parent = properties and properties.Parent
    return object
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = parent,
    })
end

local function stroke(parent, color, transparency)
    return create("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0,
        Thickness = 1,
        Parent = parent,
    })
end

local function gradient(parent, topColor, bottomColor, rotation)
    if parent and parent:IsA("GuiObject") then
        parent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end
    return create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, topColor),
            ColorSequenceKeypoint.new(1, bottomColor),
        }),
        Rotation = rotation or 90,
        Parent = parent,
    })
end

local function setGradientColors(uiGradient, colorA, colorB)
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colorA),
        ColorSequenceKeypoint.new(1, colorB),
    })
end

local function topHighlight(parent, inset, transparency)
    return create("Frame", {
        BackgroundColor3 = Theme.Highlight,
        BackgroundTransparency = transparency or 0.92,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(inset or 12, 1),
        Size = UDim2.new(1, -((inset or 12) * 2), 0, 1),
        Parent = parent,
    })
end

local function cornerFill(parent, position, size, color)
    return create("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = position,
        Size = size,
        ZIndex = parent.ZIndex,
        Parent = parent,
    })
end

local function chevron(parent, color, zIndex)
    local root = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        ZIndex = zIndex or 1,
        Parent = parent,
    })
    for _, segment in ipairs({
        { Y = -2, Rotation = 45 },
        { Y = 2, Rotation = -45 },
    }) do
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = color or Theme.Muted,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0.5, segment.Y),
            Rotation = segment.Rotation,
            Size = UDim2.fromOffset(7, 2),
            ZIndex = zIndex or 1,
            Parent = root,
        })
    end
    return root
end

local function navigationIcon(parent, kind, color)
    local icons = {
        Combat = "rbxassetid://7733765307",
        Aimbot = "rbxassetid://7733765307",
        ["Aim Assist"] = "rbxassetid://7743872758",
        Triggerbot = "rbxassetid://7734010488",
        ESP = "rbxassetid://7733774602",
        Visuals = "rbxassetid://7733774602",
        Player = "rbxassetid://7743875962",
        Settings = "rbxassetid://7734053495",
        Changelog = "rbxassetid://7733789088",
    }
    local slot = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0.5, 0),
        Size = UDim2.fromOffset(24, 24),
        Parent = parent,
    })
    local icon = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        Image = icons[kind] or icons.Combat,
        ImageColor3 = color,
        ScaleType = Enum.ScaleType.Fit,
        Parent = slot,
    })
    return slot, { icon }
end

local function recolorNavigationIcon(parts, color)
    for _, part in ipairs(parts or {}) do
        if part:IsA("ImageLabel") or part:IsA("ImageButton") then
            part.ImageColor3 = color
        elseif part:IsA("UIStroke") then
            part.Color = color
        else
            part.BackgroundColor3 = color
        end
    end
end

local function padding(parent, top, right, bottom, left)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        PaddingLeft = UDim.new(0, left or right or top or 0),
        Parent = parent,
    })
end

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    )
    animation:Play()
    return animation
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    local ok, message = pcall(callback, ...)
    if not ok then
        warn("[Reverb] UI callback failed: " .. tostring(message))
    end
end

local function environment()
    return (getgenv and getgenv()) or _G
end

function Library:SetAntiAfk(enabled, sourceControl)
    self.AntiAfkEnabled = enabled ~= false

    if self.AntiAfkEnabled and not self._AntiAfkConnection then
        local player = Players.LocalPlayer
        if player then
            self._AntiAfkConnection = player.Idled:Connect(function()
                pcall(function()
                    local virtualUser = Services.VirtualUser
                    local currentCamera = workspace.CurrentCamera
                    if not currentCamera then
                        return
                    end

                    virtualUser:Button2Down(Vector2.zero, currentCamera.CFrame)
                    task.wait(1)
                    virtualUser:Button2Up(Vector2.zero, currentCamera.CFrame)
                end)
            end)
        end
    elseif not self.AntiAfkEnabled and self._AntiAfkConnection then
        self._AntiAfkConnection:Disconnect()
        self._AntiAfkConnection = nil
    end

    for index = #self._AntiAfkControls, 1, -1 do
        local control = self._AntiAfkControls[index]
        if not control.Window or not control.Window.Frame.Parent then
            table.remove(self._AntiAfkControls, index)
        elseif control ~= sourceControl and control.Set then
            control:Set(self.AntiAfkEnabled, true)
        end
    end
end

function Library:GetAntiAfk()
    return self.AntiAfkEnabled
end

local function resolveParent()
    local ok, hidden = pcall(function()
        return gethui and gethui()
    end)
    if ok and hidden then
        return hidden
    end
    return CoreGui
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPosition
    local activeInput

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position
            activeInput = input
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        then
            activeInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == activeInput then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = false
        end
    end)
end

local guiParent = resolveParent()
local previousRoot = guiParent:FindFirstChild("ReverbCompactUI")
if previousRoot then
    previousRoot:Destroy()
end

local root = create("ScreenGui", {
    Name = "ReverbCompactUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = false,
    DisplayOrder = 120,
    Parent = guiParent,
})

-- Compatibility marker for the current production Loader's hub detector.
create("Folder", {
    Name = "ReverbLib",
    Parent = root,
})

local loaderCloseScheduled = false

local function closeReverbLoader()
    if loaderCloseScheduled then
        return
    end

    loaderCloseScheduled = true

    task.delay(0.75, function()
        local containers = {
            guiParent,
            CoreGui,
            Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui"),
        }

        for _, container in ipairs(containers) do
            if container then
                local loader = container:FindFirstChild("ReverbLoader_Final")

                if loader then
                    loader:Destroy()
                    break
                end
            end
        end
    end)
end

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(root)
    end
end)

local windowLayer = create("Frame", {
    Name = "Windows",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Parent = root,
})

local launcher = create("ImageButton", {
    Name = "ReverbControlPanel",
    AutoButtonColor = false,
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    ClipsDescendants = false,
    Position = UDim2.new(0, 14, 0.5, -22),
    Size = UDim2.fromOffset(54, 54),
    Image = "",
    Parent = root,
})
corner(launcher, 27)
local launcherStroke = stroke(launcher, Theme.Accent, 0.12)

-- Keep generous black space around the cyan mark, matching Reverb's profile
-- picture instead of stretching the transparent artwork to the button edges.
local launcherLogo = create("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.78, 0.78),
    Image = "rbxassetid://0",
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 2,
    Parent = launcher,
})

-- Text fallback stays visible until a hosted Reverb icon asset id is supplied.
local launcherMark = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Font = Enum.Font.GothamBold,
    Text = "R",
    TextColor3 = Theme.Accent,
    TextSize = 21,
    ZIndex = 3,
    Parent = launcher,
})

local uiPreferences = {
    LauncherX = 14,
    LauncherYScale = 0.5,
    LauncherYOffset = -27,
}

local function loadUiPreferences()
    if type(readfile) ~= "function" or type(isfile) ~= "function"
        or not isfile(UI_PREFS_PATH)
    then
        return
    end

    local ok, values = pcall(function()
        return HttpService:JSONDecode(readfile(UI_PREFS_PATH))
    end)
    if ok and type(values) == "table" then
        for key, fallback in pairs(uiPreferences) do
            if type(values[key]) == type(fallback) then
                uiPreferences[key] = values[key]
            end
        end
    end
end

local function saveUiPreferences()
    if type(writefile) ~= "function" then
        return
    end
    pcall(function()
        if type(makefolder) == "function"
            and (type(isfolder) ~= "function" or not isfolder("Reverb"))
        then
            makefolder("Reverb")
        end
        writefile(UI_PREFS_PATH, HttpService:JSONEncode(uiPreferences))
    end)
end

loadUiPreferences()
launcher.Position = UDim2.new(
    0,
    uiPreferences.LauncherX,
    uiPreferences.LauncherYScale,
    uiPreferences.LauncherYOffset
)

local function loadDefaultLogo()
    local customAsset = getcustomasset or getsynasset
    if type(customAsset) ~= "function"
        or type(writefile) ~= "function"
        or type(isfile) ~= "function"
    then
        return
    end

    task.spawn(function()
        local path = "ReverbJ/Assets/ReverbIcon.png"
        local ok = pcall(function()
            if type(makefolder) == "function" then
                if type(isfolder) ~= "function" or not isfolder("ReverbJ") then
                    makefolder("ReverbJ")
                end
                if type(isfolder) ~= "function" or not isfolder("ReverbJ/Assets") then
                    makefolder("ReverbJ/Assets")
                end
            end
            if not isfile(path) then
                writefile(
                    path,
                    game:HttpGet(
                        "https://raw.githubusercontent.com/rbxreverb/ReverbUI/refs/heads/main/assets/ReverbIcon.png"
                    )
                )
            end
            launcherLogo.Image = customAsset(path)
            launcherMark.Visible = false
            for _, logo in ipairs(Library.HeaderLogos) do
                if logo.Image and logo.Image.Parent then
                    logo.Image.Image = launcherLogo.Image
                    logo.Fallback.Visible = false
                end
            end
        end)
        if not ok then
            launcherMark.Visible = true
        end
    end)
end

local function copyLink(label, url)
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, url)
        if ok then
            Library:Notify(label .. " link copied", 2.5)
            return true
        end
    end
    Library:Notify(url, 5)
    return false
end

local updateScale

local function clampLauncherToViewport(viewport, mobile)
    local absolute = launcher.AbsolutePosition
    local size = launcher.AbsoluteSize
    local verticalMargin = mobile and 16 or 18
    local clampedX = math.clamp(
        absolute.X,
        8,
        math.max(8, viewport.X - size.X - 8)
    )
    local clampedY = math.clamp(
        absolute.Y,
        verticalMargin,
        math.max(verticalMargin, viewport.Y - size.Y - verticalMargin)
    )
    launcher.Position = UDim2.fromOffset(clampedX, clampedY)
end

local function resetUiPositions()
    uiPreferences.LauncherX = 14
    uiPreferences.LauncherYScale = 0.5
    uiPreferences.LauncherYOffset = -27
    launcher.Position = UDim2.new(0, 14, 0.5, -27)
    for index, window in ipairs(Library.Windows) do
        window.Frame.Position = UDim2.new(
            0.5,
            ((index - 1) * 24),
            0.5,
            ((index - 1) * 20)
        )
    end
    saveUiPreferences()
    updateScale()
end

updateScale = function()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local mobile = UserInputService.TouchEnabled and viewport.X < 900
    local launcherSize = mobile and 48 or 54
    launcher.Size = UDim2.fromOffset(launcherSize, launcherSize)
    launcher:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, launcherSize / 2)
    for _, window in ipairs(Library.Windows) do
        local scale
        local viewportScale = math.min(
            (viewport.X - (mobile and 16 or 24)) / DESKTOP_WIDTH,
            (viewport.Y - (mobile and 16 or 36)) / DESKTOP_HEIGHT
        )
        scale = mobile and viewportScale or math.min(DESKTOP_RENDER_SCALE, viewportScale)
        window.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
        window.Frame.Position = UDim2.fromScale(0.5, 0.5)
        window.Frame.Size = UDim2.fromOffset(DESKTOP_WIDTH, DESKTOP_HEIGHT)
        window.Scale.Scale = scale
        -- Operation One keeps the supplied two-column design on touch devices.
        -- Scaling the complete design grid preserves every proportion and avoids
        -- the previous mobile-only rearrangement that made it feel unrelated.
        window.MobileLayout = false
        if window.ApplyResponsiveLayout then
            window:ApplyResponsiveLayout(false)
        end
        if not mobile then
            local renderedSize = Vector2.new(DESKTOP_WIDTH * scale, DESKTOP_HEIGHT * scale)
            local absolute = window.Frame.AbsolutePosition
            local clampedX = math.clamp(absolute.X, 8, math.max(8, viewport.X - renderedSize.X - 8))
            local clampedY = math.clamp(absolute.Y, 8, math.max(8, viewport.Y - renderedSize.Y - 8))
            window.Frame.Position = UDim2.fromOffset(
                clampedX + (renderedSize.X * 0.5),
                clampedY + (renderedSize.Y * 0.5)
            )
        end
    end
    clampLauncherToViewport(viewport, mobile)
end

function Library:SetOpen(isOpen)
    self.Open = isOpen == true
    windowLayer.Visible = self.Open
    tween(launcherStroke, 0.14, {
        Transparency = self.Open and 0 or 1,
        Thickness = 2,
    })
end

function Library:Toggle()
    self:SetOpen(not self.Open)
end

local launcherDragging = false
local launcherMoved = false
local launcherInput
local launcherStart
local launcherStartPosition
local launcherPressWasTouch = false

launcher.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch
    then
        return
    end
    launcherDragging = true
    launcherMoved = false
    launcherInput = input
    launcherStart = input.Position
    launcherStartPosition = launcher.Position
    launcherPressWasTouch = input.UserInputType == Enum.UserInputType.Touch
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then
        return
    end
    if input.KeyCode == Enum.KeyCode.RightControl then
        Library:Toggle()
    end
end)

launcher.InputChanged:Connect(function(input)
    if launcherDragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        launcherInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not launcherDragging or input ~= launcherInput then
        return
    end
    local delta = input.Position - launcherStart
    if delta.Magnitude >= (launcherPressWasTouch and 10 or 3) then
        launcherMoved = true
    end
    launcher.Position = UDim2.new(
        launcherStartPosition.X.Scale,
        launcherStartPosition.X.Offset + delta.X,
        launcherStartPosition.Y.Scale,
        launcherStartPosition.Y.Offset + delta.Y
    )
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local mobile = UserInputService.TouchEnabled and viewport.X < 900
    clampLauncherToViewport(viewport, mobile)
end)

UserInputService.InputEnded:Connect(function(input)
    if not launcherDragging or (
        input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch
    ) then
        return
    end
    launcherDragging = false
    if launcherMoved then
        -- Preserve the free movement of the original live launcher. Save the
        -- exact release point without snapping it to an edge or grid.
        local releasePosition = launcher.AbsolutePosition
        launcher.Position = UDim2.fromOffset(releasePosition.X, releasePosition.Y)
        uiPreferences.LauncherX = releasePosition.X
        uiPreferences.LauncherYScale = 0
        uiPreferences.LauncherYOffset = releasePosition.Y
        saveUiPreferences()
        updateScale()
    else
        Library:Toggle()
    end
end)

function Library:SetLogo(asset)
    if type(asset) == "number" then
        launcherLogo.Image = "rbxassetid://" .. asset
    elseif type(asset) == "string" then
        launcherLogo.Image = asset
    end
    launcherMark.Visible = launcherLogo.Image == ""
        or launcherLogo.Image == "rbxassetid://0"
    for _, logo in ipairs(self.HeaderLogos) do
        if logo.Image and logo.Image.Parent then
            logo.Image.Image = launcherLogo.Image
            logo.Fallback.Visible = launcherMark.Visible
        end
    end
end

local notificationHost = create("Frame", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -14, 1, -14),
    Size = UDim2.fromOffset(280, 240),
    Parent = root,
})
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 6),
    Parent = notificationHost,
})

function Library:Notify(message, duration)
    if type(message) == "table" then
        duration = message.Duration
        message = message.Content or message.Message or message.Title
    end
    local card = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.03,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Parent = notificationHost,
    })
    corner(card, 7)
    stroke(card, Theme.Border)
    create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        Parent = card,
    })
    local text = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Enum.Font.Gotham,
        Text = tostring(message or "Notification"),
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    tween(card, 0.18, { Size = UDim2.new(1, 0, 0, 46) })
    task.delay(tonumber(duration) or 3, function()
        if card.Parent then
            tween(card, 0.16, { Size = UDim2.new(1, 0, 0, 0) })
            task.delay(0.18, function()
                card:Destroy()
            end)
        end
    end)
    return text
end

local function resolveTier(options)
    local tier = options.Tier or options.Access
    if tier == nil then
        local env = environment()
        local current = env.ReverbCurrentScript
        tier = env.ReverbTier
            or env.ReverbAccess
            or (type(current) == "table" and (current.tier or current.access))
        if tier == nil and env.Shared_LRM_UserNote ~= nil then
            local note = tostring(env.Shared_LRM_UserNote)
            tier = (note ~= "Ad Reward" and note ~= "Not specified" and note ~= "")
                and "PREMIUM"
                or "FREE"
        end
    end
    tier = tostring(tier or "FREE"):upper()
    return tier == "PREMIUM" and "PREMIUM" or "FREE"
end

local function titleFor(options)
    local name = options.Game or options.GameName or options.Title or "Game"
    name = tostring(name)
    name = name:gsub("%s+[Bb][Yy]%s+[Rr][Ee][Vv][Ee][Rr][Bb].*$", "")
    return name
end

local function configApi(window)
    local api = {}

    function api:Save()
        if not window.Remember or not writefile then
            return false
        end
        local values = {}
        for flag, control in pairs(window.Flags) do
            values[flag] = control.Value
        end
        local ok = pcall(function()
            if makefolder and not isfolder("Reverb") then
                makefolder("Reverb")
            end
            writefile(window.ConfigPath, HttpService:JSONEncode(values))
        end)
        return ok
    end

    function api:Load()
        if not window.Remember or not readfile or not isfile or not isfile(window.ConfigPath) then
            return false
        end
        local ok, values = pcall(function()
            return HttpService:JSONDecode(readfile(window.ConfigPath))
        end)
        if not ok or type(values) ~= "table" then
            return false
        end
        for flag, value in pairs(values) do
            local control = window.Flags[flag]
            if control and control.Set then
                -- Restoring the visual state alone leaves the script feature
                -- inactive. Run the normal callback so saved toggles and other
                -- controls actually re-apply their behavior in the new session.
                control:Set(value, false)
            end
        end
        return true
    end

    return api
end

local function readRememberPreference(path)
    if type(readfile) ~= "function" or type(isfile) ~= "function" or not isfile(path) then
        return nil
    end

    local ok, value = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if ok and type(value) == "boolean" then
        return value
    end
    return nil
end

local function writeRememberPreference(path, enabled)
    if type(writefile) ~= "function" then
        return false
    end

    return pcall(function()
        if type(makefolder) == "function"
            and (type(isfolder) ~= "function" or not isfolder("Reverb"))
        then
            makefolder("Reverb")
        end
        writefile(path, HttpService:JSONEncode(enabled == true))
    end)
end

function Library:CreateWindow(options)
    options = options or {}
    local index = #self.Windows + 1
    local configName = tostring(options.ConfigName or options.Game or options.Title or "script")
        :gsub("[^%w_-]", "_")
    local configPath = "Reverb/" .. configName .. "_compact.json"
    local rememberPreferencePath = "Reverb/" .. configName .. "_remember.json"
    local savedRememberPreference = readRememberPreference(rememberPreferencePath)
    local hasLegacyRememberedSettings = savedRememberPreference == nil
        and type(isfile) == "function"
        and isfile(configPath)
    local window = {
        Tabs = {},
        Flags = {},
        SettingsDrawers = {},
        RememberControls = {},
        Remember = savedRememberPreference == nil
            and (options.RememberSettings == true or hasLegacyRememberedSettings)
            or savedRememberPreference == true,
        RememberPreferencePath = rememberPreferencePath,
        ConfigPath = configPath,
        ResponsiveCallbacks = {},
    }

    local frame = create("Frame", {
        Name = "Window" .. index,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        Position = options.Position or UDim2.new(0.5, ((index - 1) * 24), 0.5, ((index - 1) * 20)),
        Size = UDim2.fromOffset(DESKTOP_WIDTH, DESKTOP_HEIGHT),
        ClipsDescendants = true,
        Parent = windowLayer,
    })
    corner(frame, 19)
    stroke(frame, Theme.Accent, 0.3)
    gradient(frame, Color3.fromRGB(6, 15, 21), Color3.fromRGB(2, 8, 12), 112)
    window.Frame = frame
    window.Scale = create("UIScale", { Scale = 1, Parent = frame })

    local header = create("Frame", {
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        Parent = frame,
    })
    corner(header, 18)
    gradient(header, Color3.fromRGB(10, 20, 27), Color3.fromRGB(5, 13, 19), 108)
    create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = header,
    })
    local headerIcon = create("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 25, 0.5, 0),
        Size = UDim2.fromOffset(43, 43),
        Image = launcherLogo.Image,
        ScaleType = Enum.ScaleType.Fit,
        Parent = header,
    })
    local headerFallback = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = headerIcon.Position,
        AnchorPoint = headerIcon.AnchorPoint,
        Size = headerIcon.Size,
        Font = Enum.Font.GothamBold,
        Text = "R",
        TextColor3 = Theme.Accent,
        TextSize = 25,
        Visible = launcherLogo.Image == "" or launcherLogo.Image == "rbxassetid://0",
        Parent = header,
    })
    table.insert(Library.HeaderLogos, {
        Image = headerIcon,
        Fallback = headerFallback,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(83, 0),
        Size = UDim2.fromOffset(190, HEADER_HEIGHT),
        Font = Enum.Font.GothamBold,
        Text = titleFor(options),
        TextColor3 = Theme.Text,
        TextSize = 27,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(270, 1),
        Size = UDim2.fromOffset(100, HEADER_HEIGHT),
        Font = Enum.Font.GothamMedium,
        Text = "By Reverb",
        TextColor3 = Theme.Muted,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(378, 1),
        Size = UDim2.fromOffset(92, HEADER_HEIGHT),
        Font = Enum.Font.GothamBold,
        Text = tostring(options.Version or ""),
        TextColor3 = Theme.Accent,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = options.Version ~= nil and tostring(options.Version) ~= "",
        Parent = header,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -166, 0, 0),
        Size = UDim2.fromOffset(72, HEADER_HEIGHT),
        Font = Enum.Font.GothamMedium,
        Text = resolveTier(options),
        TextColor3 = Theme.Accent,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = header,
    })
    create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -78, 0, 20),
        Size = UDim2.fromOffset(1, 34),
        Parent = header,
    })
    local close = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -62, 0, 16),
        Size = UDim2.fromOffset(48, 40),
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = Theme.Muted,
        TextSize = 34,
        Parent = header,
    })
    for _, rotation in ipairs({ 45, -45 }) do
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.Muted,
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0.5, 0.5),
            Rotation = rotation,
            Size = UDim2.fromOffset(18, 2),
            Parent = close,
        })
    end
    close.MouseButton1Click:Connect(function()
        Library:SetOpen(false)
    end)
    makeDraggable(header, frame)

    local tabBar = create("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        Position = UDim2.fromOffset(0, HEADER_HEIGHT),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -HEADER_HEIGHT),
        Parent = frame,
    })
    corner(tabBar, 18)
    gradient(tabBar, Color3.fromRGB(6, 16, 22), Color3.fromRGB(3, 10, 15), 108)
    local tabPadding = padding(tabBar, 29, 13, 18, 13)
    local tabLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = tabBar,
    })

    local content = create("Frame", {
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0,
        Position = UDim2.fromOffset(SIDEBAR_WIDTH, HEADER_HEIGHT),
        Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -HEADER_HEIGHT),
        Parent = frame,
    })
    corner(content, 18)
    gradient(content, Color3.fromRGB(7, 16, 22), Color3.fromRGB(3, 9, 14), 118)
    window.Content = content
    local sidebarDivider = create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(SIDEBAR_WIDTH - 1, HEADER_HEIGHT),
        Size = UDim2.new(0, 1, 1, -HEADER_HEIGHT),
        Parent = frame,
    })

    function window:ApplyResponsiveLayout(mobile)
        if mobile then
            sidebarDivider.Visible = false
            tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
            tabBar.Position = UDim2.new(0, 0, 1, -54)
            tabBar.ScrollingDirection = Enum.ScrollingDirection.X
            tabBar.Size = UDim2.new(1, 0, 0, 54)
            tabPadding.PaddingTop = UDim.new(0, 7)
            tabPadding.PaddingRight = UDim.new(0, 10)
            tabPadding.PaddingBottom = UDim.new(0, 7)
            tabPadding.PaddingLeft = UDim.new(0, 10)
            tabLayout.FillDirection = Enum.FillDirection.Horizontal
            tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            content.Position = UDim2.fromOffset(0, HEADER_HEIGHT)
            content.Size = UDim2.new(1, 0, 1, -124)
        else
            sidebarDivider.Visible = true
            tabBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
            tabBar.Position = UDim2.fromOffset(0, HEADER_HEIGHT)
            tabBar.ScrollingDirection = Enum.ScrollingDirection.Y
            tabBar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -HEADER_HEIGHT)
            tabPadding.PaddingTop = UDim.new(0, 29)
            tabPadding.PaddingRight = UDim.new(0, 14)
            tabPadding.PaddingBottom = UDim.new(0, 18)
            tabPadding.PaddingLeft = UDim.new(0, 14)
            tabLayout.FillDirection = Enum.FillDirection.Vertical
            tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            tabLayout.VerticalAlignment = Enum.VerticalAlignment.Top
            content.Position = UDim2.fromOffset(SIDEBAR_WIDTH, HEADER_HEIGHT)
            content.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -HEADER_HEIGHT)
        end
        for _, tab in ipairs(self.Tabs) do
            tab:ApplyResponsiveLayout(mobile)
        end
        for _, alias in ipairs(self.AliasTabs or {}) do
            if mobile then
                alias.Button.AutomaticSize = Enum.AutomaticSize.X
                alias.Button.Size = UDim2.fromOffset(0, 40)
                alias.Indicator.AnchorPoint = Vector2.new(0, 1)
                alias.Indicator.Position = UDim2.new(0, 0, 1, 0)
                alias.Indicator.Size = UDim2.new(1, 0, 0, 2)
                alias.Icon.Visible = false
                alias.Label.Position = UDim2.fromOffset(12, 0)
                alias.Label.Size = UDim2.new(1, -24, 1, 0)
                alias.Label.TextXAlignment = Enum.TextXAlignment.Center
                alias.Padding.PaddingLeft = UDim.new(0, 0)
                alias.Button.TextXAlignment = Enum.TextXAlignment.Center
            else
                alias.Button.AutomaticSize = Enum.AutomaticSize.None
                alias.Button.Size = UDim2.new(1, 0, 0, 68)
                alias.Indicator.AnchorPoint = Vector2.new(0, 0.5)
                alias.Indicator.Position = UDim2.new(0, 0, 0.5, 0)
                alias.Indicator.Size = UDim2.fromOffset(3, 66)
                alias.Icon.Visible = true
                alias.Label.Position = UDim2.fromOffset(73, 0)
                alias.Label.Size = UDim2.new(1, -87, 1, 0)
                alias.Label.TextXAlignment = Enum.TextXAlignment.Left
                alias.Padding.PaddingLeft = UDim.new(0, 0)
                alias.Button.TextXAlignment = Enum.TextXAlignment.Left
            end
        end
        for _, callback in ipairs(self.ResponsiveCallbacks) do
            callback(mobile)
        end
    end

    function window:Show()
        self.Frame.Visible = true
        Library:SetOpen(true)
    end

    function window:Hide()
        self.Frame.Visible = false
    end

    function window:Notify(message, duration)
        return Library:Notify(message, duration)
    end

    function window:SetRememberSettings(enabled)
        self.Remember = enabled == true
        writeRememberPreference(self.RememberPreferencePath, self.Remember)
        for _, control in ipairs(self.RememberControls) do
            if control.Value ~= self.Remember then
                control:Set(self.Remember, true)
            end
        end
        if self.Remember then
            self.Config:Load()
        end
    end

    function window:Destroy()
        for i, item in ipairs(Library.Windows) do
            if item == self then
                table.remove(Library.Windows, i)
                break
            end
        end
        self.Frame:Destroy()
    end

    function window:SelectTab(selected)
        for _, tab in ipairs(self.Tabs) do
            local active = tab == selected
            tab.Page.Visible = active
            tween(tab.TabButton, 0.12, {
                BackgroundTransparency = active and 0.08 or 1,
            })
            tween(tab.NavLabel, 0.12, {
                TextColor3 = active and Theme.Text or Theme.Muted,
            })
            setGradientColors(
                tab.Gradient,
                active and Color3.fromRGB(7, 47, 59) or Theme.Surface,
                active and Color3.fromRGB(3, 25, 33) or Theme.Surface
            )
            tab.Indicator.Visible = active
            recolorNavigationIcon(tab.IconParts, active and Theme.Accent or Theme.Muted)
        end
        for _, alias in ipairs(self.AliasTabs or {}) do
            alias.Button.BackgroundTransparency = 1
            alias.Label.TextColor3 = Theme.Muted
            alias.Indicator.Visible = false
            recolorNavigationIcon(alias.IconParts, Theme.Muted)
        end
    end

    local function registerControl(control, flag)
        if flag and flag ~= "" then
            control.Flag = flag
            window.Flags[flag] = control
        end
        return control
    end

    local function controlRow(parent, height)
        local row = create("Frame", {
            BackgroundColor3 = Theme.Raised,
            Size = UDim2.new(1, 0, 0, height or 62),
            Parent = parent,
        })
        corner(row, 12)
        gradient(row, Theme.Raised, Theme.RaisedBottom, 112)
        stroke(row, Theme.Border, 0.38)
        topHighlight(row, 14, 0.93)
        return row
    end

    local function controlDescription(label)
        return nil
    end

    function window:Tab(name)
        local tab = { Name = tostring(name or "Tab") }
        local displayName = tab.Name
        if displayName:lower() == "main"
            and tostring(options.Game or options.GameName or ""):lower() == "operation one"
        then
            displayName = "Main"
        end
        tab.TabButton = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 1,
            LayoutOrder = ({ Main = 1, Visuals = 2, Settings = 3, Changelog = 4 })[tab.Name] or 10,
            Size = UDim2.new(1, 0, 0, 68),
            Font = Enum.Font.GothamMedium,
            Text = "",
            Parent = tabBar,
        })
        tab.Padding = padding(tab.TabButton, 0, 0, 0, 0)
        corner(tab.TabButton, 10)
        tab.Gradient = gradient(
            tab.TabButton,
            Color3.fromRGB(7, 47, 59),
            Color3.fromRGB(3, 25, 33),
            116
        )
        tab.IconRoot, tab.IconParts = navigationIcon(
            tab.TabButton,
            displayName,
            Theme.Muted
        )
        tab.IconRoot.Position = UDim2.new(0, 19, 0.5, 0)
        tab.IconRoot.Size = UDim2.fromOffset(31, 31)
        tab.NavLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(73, 0),
            Size = UDim2.new(1, -87, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = displayName,
            TextColor3 = Theme.Muted,
            TextSize = 17,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tab.TabButton,
        })
        tab.Indicator = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(3, 66),
            Visible = false,
            Parent = tab.TabButton,
        })
        corner(tab.Indicator, 1)

        tab.Page = create("ScrollingFrame", {
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarThickness = 2,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            Parent = content,
        })
        padding(tab.Page, 14, 14, 14, 14)
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tab.Page,
        })
        tab.Container = tab.Page

        function tab:ApplyResponsiveLayout(mobile)
            if mobile then
                self.TabButton.AutomaticSize = Enum.AutomaticSize.X
                self.TabButton.Size = UDim2.fromOffset(0, 40)
                self.Indicator.AnchorPoint = Vector2.new(0, 1)
                self.Indicator.Position = UDim2.new(0, 0, 1, 0)
                self.Indicator.Size = UDim2.new(1, 0, 0, 2)
                self.IconRoot.Visible = false
                self.NavLabel.Position = UDim2.fromOffset(12, 0)
                self.NavLabel.Size = UDim2.new(1, -24, 1, 0)
                self.NavLabel.TextXAlignment = Enum.TextXAlignment.Center
                self.Padding.PaddingLeft = UDim.new(0, 0)
                self.TabButton.TextXAlignment = Enum.TextXAlignment.Center
            else
                self.TabButton.AutomaticSize = Enum.AutomaticSize.None
                self.TabButton.Size = UDim2.new(1, 0, 0, 68)
                self.Indicator.AnchorPoint = Vector2.new(0, 0.5)
                self.Indicator.Position = UDim2.new(0, 0, 0.5, 0)
                self.Indicator.Size = UDim2.fromOffset(3, 66)
                self.IconRoot.Visible = true
                self.NavLabel.Position = UDim2.fromOffset(73, 0)
                self.NavLabel.Size = UDim2.new(1, -87, 1, 0)
                self.NavLabel.TextXAlignment = Enum.TextXAlignment.Left
                self.Padding.PaddingLeft = UDim.new(0, 0)
                self.TabButton.TextXAlignment = Enum.TextXAlignment.Left
            end
        end

        tab.TabButton.MouseButton1Click:Connect(function()
            window:SelectTab(tab)
            if tab._FeatureWorkspace and tab._FeatureWorkspace.SetMode then
                local mode = tab.Name:lower() == "visuals" and "Visuals" or "Combat"
                tab._FeatureWorkspace.SetMode(mode)
                if mode == "Combat"
                    and tab._FeatureWorkspace.ActiveFeature == "Enemy ESP"
                then
                    tab._FeatureWorkspace.SelectFeature("Aimbot")
                end
            end
        end)

        if tab.Name:lower() == "main"
            and tostring(options.Game or options.GameName or ""):lower() == "operation one"
            and options.LegacyOperationOneVisualsAlias == true
        then
            window.AliasTabs = window.AliasTabs or {}
            for aliasIndex, aliasName in ipairs({ "Visuals" }) do
                local aliasButton = create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Theme.Background,
                    BackgroundTransparency = 1,
                    LayoutOrder = aliasIndex + 1,
                    Size = UDim2.new(1, 0, 0, 68),
                    Font = Enum.Font.GothamMedium,
                    Text = "",
                    Parent = tabBar,
                })
                local aliasPadding = padding(aliasButton, 0, 0, 0, 0)
                corner(aliasButton, 10)
                local aliasGradient = gradient(
                    aliasButton,
                    Color3.fromRGB(7, 47, 59),
                    Color3.fromRGB(3, 25, 33),
                    116
                )
                local aliasIcon, aliasIconParts = navigationIcon(aliasButton, aliasName, Theme.Muted)
                aliasIcon.Position = UDim2.new(0, 19, 0.5, 0)
                aliasIcon.Size = UDim2.fromOffset(31, 31)
                local aliasLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(73, 0),
                    Size = UDim2.new(1, -87, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = aliasName,
                    TextColor3 = Theme.Muted,
                    TextSize = 17,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = aliasButton,
                })
                local aliasIndicator = create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.fromOffset(3, 66),
                    Visible = false,
                    Parent = aliasButton,
                })
                corner(aliasIndicator, 2)
                local alias = {
                    Button = aliasButton,
                    Icon = aliasIcon,
                    IconParts = aliasIconParts,
                    Indicator = aliasIndicator,
                    Padding = aliasPadding,
                    Label = aliasLabel,
                    Name = aliasName,
                    Gradient = aliasGradient,
                }
                table.insert(window.AliasTabs, alias)
                local aliasHitbox = create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Text = "",
                    ZIndex = 10,
                    Parent = aliasButton,
                })
                alias.Hitbox = aliasHitbox
                aliasHitbox.Activated:Connect(function()
                    window:SelectTab(tab)
                    tab.TabButton.BackgroundTransparency = 1
                    tab.NavLabel.TextColor3 = Theme.Muted
                    tab.Indicator.Visible = false
                    recolorNavigationIcon(tab.IconParts, Theme.NavMuted)
                    setGradientColors(tab.Gradient, Theme.Surface, Theme.Surface)
                    aliasButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    aliasButton.BackgroundTransparency = 0
                    aliasLabel.TextColor3 = Theme.Text
                    aliasIndicator.Visible = true
                    recolorNavigationIcon(aliasIconParts, Theme.Accent)
                    setGradientColors(
                        aliasGradient,
                        Color3.fromRGB(7, 47, 59),
                        Color3.fromRGB(3, 25, 33)
                    )
                    if tab._FeatureWorkspace and tab._FeatureWorkspace.SelectFeature then
                        tab._FeatureWorkspace.SetMode("Visuals")
                        tab._FeatureWorkspace.SelectFeature("Enemy ESP")
                    end
                end)
            end
        end

        local function addLabel(text, color, size, parent)
            local label = create("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Font = Enum.Font.Gotham,
                Text = tostring(text or ""),
                TextColor3 = color or Theme.Muted,
                TextSize = size or 11,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = parent or tab.Container,
            })
            return label
        end

        function tab:Section(sectionName, collapsed)
            local section = {}
            self.SectionCount = (self.SectionCount or 0) + 1
            local isChangelogSection = self.Name:lower() == "changelog"
            local isPrimarySection = self.Name:lower() == "main"
                and tostring(sectionName or ""):lower() == "main"
            if tostring(options.Game or options.GameName or ""):lower() == "operation one"
                and self.Name:lower() == "visuals"
                and tostring(sectionName or ""):lower() == "visuals"
            then
                isPrimarySection = true
            end
            local shell = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = self.Container,
            })
            local layout = create("UIListLayout", {
                Padding = UDim.new(0, isPrimarySection and 0 or (isChangelogSection and 6 or 7)),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = shell,
            })
            local sectionButton = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Background,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.new(
                    1,
                    0,
                    0,
                    isPrimarySection and 0 or (isChangelogSection and 48 or 36)
                ),
                Font = Enum.Font.GothamMedium,
                Text = (isChangelogSection and "  " or "")
                    .. tostring(sectionName or "Section"),
                TextColor3 = isChangelogSection and Theme.Text or Theme.Muted,
                TextSize = isChangelogSection and 15 or 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not isPrimarySection,
                Parent = shell,
            })
            local sectionChevron
            if isChangelogSection then
                create("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = Theme.Border,
                    BackgroundTransparency = 0.18,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = sectionButton,
                })
                local sectionChevronButton = create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -28, 0, 0),
                    Size = UDim2.new(0, 24, 1, 0),
                    Parent = sectionButton,
                })
                sectionChevron = chevron(sectionChevronButton, Theme.Muted, 2)
            end
            local body = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Background,
                BackgroundTransparency = 1,
                ClipsDescendants = isChangelogSection,
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = shell,
            })
            if isChangelogSection then
                padding(body, 10, 10, 10, 10)
            end
            create("UIListLayout", {
                Padding = UDim.new(0, 7),
                Parent = body,
            })
            local defaultCollapsed = collapsed == nil
                and isChangelogSection
                and self.SectionCount > 1
            section.Open = collapsed ~= true and not defaultCollapsed

            local function updateSectionState()
                body.Visible = section.Open
                if isChangelogSection then
                    sectionChevron.Rotation = section.Open and 90 or 0
                    for _, segment in ipairs(sectionChevron:GetChildren()) do
                        segment.BackgroundColor3 = section.Open and Theme.Accent or Theme.Muted
                    end
                    sectionButton.BackgroundTransparency = 1
                else
                    sectionButton.TextColor3 = section.Open
                        and Theme.Muted
                        or Theme.Text
                end
            end

            updateSectionState()
            if isChangelogSection then
                sectionButton.MouseEnter:Connect(function()
                    tween(sectionButton, 0.1, { BackgroundTransparency = 0.55 })
                end)
                sectionButton.MouseLeave:Connect(function()
                    tween(sectionButton, 0.1, { BackgroundTransparency = 1 })
                end)
            end
            sectionButton.MouseButton1Click:Connect(function()
                section.Open = not section.Open
                updateSectionState()
            end)
            section.Container = body
            setmetatable(section, { __index = tab })
            return section
        end

        function tab:Button(text, callback)
            local button = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Raised,
                Size = UDim2.new(1, 0, 0, 44),
                Font = Enum.Font.GothamMedium,
                Text = tostring(text or "Button"),
                TextColor3 = Theme.Text,
                TextSize = 15,
                Parent = self.Container,
            })
            corner(button, 8)
            button.MouseEnter:Connect(function()
                tween(button, 0.1, { BackgroundColor3 = Theme.Hover })
            end)
            button.MouseLeave:Connect(function()
                tween(button, 0.1, { BackgroundColor3 = Theme.Raised })
            end)
            button.MouseButton1Click:Connect(function()
                tween(button, 0.06, { BackgroundColor3 = Theme.AccentDark })
                task.delay(0.08, function()
                    tween(button, 0.12, { BackgroundColor3 = Theme.Raised })
                end)
                safeCall(callback)
            end)
            return button
        end

        function tab:Toggle(text, default, callback, flag)
            local isRememberControl = tostring(text or ""):lower() == "remember active settings"
            if isRememberControl then
                default = window.Remember
            end
            local description = controlDescription(text)
            local row = controlRow(self.Container, 65)
            local titleLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(28, 0),
                Size = UDim2.new(1, -135, 1, 0),
                Font = description and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                Text = tostring(text or "Toggle"),
                TextColor3 = Theme.Text,
                TextSize = 20,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            local descriptionLabel
            if description then
                descriptionLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(18, 32),
                    Size = UDim2.new(1, -105, 0, 22),
                    Font = Enum.Font.Gotham,
                    Text = description,
                    TextColor3 = Theme.Muted,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })
            end
            local track = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme.Border,
                Position = UDim2.new(1, -25, 0.5, 0),
                Size = UDim2.fromOffset(70, 35),
                Parent = row,
            })
            corner(track, 18)
            local trackStroke = stroke(track, Theme.Border, 0.12)
            local trackGradient = gradient(track, Theme.Off, Theme.OffDark, 105)
            local knob = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme.Muted,
                Position = UDim2.new(0, 5, 0.5, 0),
                Size = UDim2.fromOffset(26, 26),
                Parent = track,
            })
            corner(knob, 13)
            gradient(
                knob,
                Color3.fromRGB(245, 249, 252),
                Color3.fromRGB(210, 222, 233),
                90
            )
            stroke(knob, Color3.fromRGB(255, 255, 255), 0.76)
            local hit = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Parent = row,
            })
            local control = { Value = default == true }
            if description then
                table.insert(window.ResponsiveCallbacks, function(mobile)
                    row.Size = UDim2.new(1, 0, 0, mobile and 68 or 64)
                    descriptionLabel.Visible = not mobile
                    titleLabel.Position = mobile and UDim2.fromOffset(18, 0)
                        or UDim2.fromOffset(18, 7)
                    titleLabel.Size = mobile and UDim2.new(1, -90, 1, 0)
                        or UDim2.new(1, -105, 0, 26)
                    titleLabel.Font = mobile and Type.Medium or Type.Bold
                    titleLabel.TextSize = mobile and 14 or 15
                    track.Position = UDim2.new(1, mobile and -14 or -18, 0.5, 0)
                    track.Size = mobile and UDim2.fromOffset(50, 30)
                        or UDim2.fromOffset(56, 32)
                    track:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, mobile and 15 or 16)
                    knob.Size = mobile and UDim2.fromOffset(24, 24)
                        or UDim2.fromOffset(26, 26)
                    knob:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, mobile and 12 or 13)
                    knob.Position = control.Value
                        and (mobile and UDim2.new(1, -27, 0.5, 0) or UDim2.new(1, -29, 0.5, 0))
                        or UDim2.new(0, 3, 0.5, 0)
                end)
            end
            function control:Set(value, silent)
                self.Value = value == true
                setGradientColors(
                    trackGradient,
                    self.Value and Color3.fromRGB(28, 222, 243) or Theme.Off,
                    self.Value and Color3.fromRGB(10, 188, 216) or Theme.OffDark
                )
                tween(trackStroke, 0.12, {
                    Color = self.Value and Theme.Accent or Theme.Border,
                    Transparency = self.Value and 0.05 or 0.12,
                })
                tween(knob, 0.12, {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Position = self.Value
                        and (window.MobileLayout and UDim2.new(1, -27, 0.5, 0)
                            or UDim2.new(1, -31, 0.5, 0))
                        or (window.MobileLayout and UDim2.new(0, 3, 0.5, 0)
                            or UDim2.new(0, 5, 0.5, 0)),
                })
                if not silent then
                    safeCall(callback, self.Value)
                    window.Config:Save()
                end
            end
            hit.MouseButton1Click:Connect(function()
                control:Set(not control.Value)
            end)
            control:Set(control.Value, true)
            if isRememberControl then
                table.insert(window.RememberControls, control)
            else
                registerControl(control, flag)
            end
            return control
        end

        function tab:SettingsToggle(text, default, callback, flag)
            if not self._FeatureWorkspace then
                local workspaceFrame = create("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Size = UDim2.new(1, 0, 0, 505),
                    Parent = self.Container,
                })
                local selector = create("ScrollingFrame", {
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.new(),
                    ScrollBarThickness = 0,
                    ScrollingDirection = Enum.ScrollingDirection.X,
                    Size = UDim2.new(1, 0, 0, 62),
                    Parent = workspaceFrame,
                })
                local selectorPadding = padding(selector, 4, 0, 4, 0)
                local selectorLayout = create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 7),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = selector,
                })
                local detail = create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 70),
                    Size = UDim2.new(1, 0, 1, -70),
                    Parent = workspaceFrame,
                })
                self._FeatureWorkspace = {
                    Frame = workspaceFrame,
                    Selector = selector,
                    SelectorPadding = selectorPadding,
                    SelectorLayout = selectorLayout,
                    Detail = detail,
                    Items = {},
                }
                local workspace = self._FeatureWorkspace
                local function applyFeatureLayout(mobile)
                    if mobile then
                        workspaceFrame.Size = UDim2.new(1, 0, 0, 440)
                        selector.AutomaticCanvasSize = Enum.AutomaticSize.X
                        selector.Position = UDim2.fromOffset(0, 0)
                        selector.ScrollingDirection = Enum.ScrollingDirection.X
                        selector.Size = UDim2.new(1, 0, 0, 62)
                        selectorPadding.PaddingTop = UDim.new(0, 0)
                        selectorPadding.PaddingRight = UDim.new(0, 0)
                        selectorPadding.PaddingBottom = UDim.new(0, 6)
                        selectorPadding.PaddingLeft = UDim.new(0, 0)
                        selectorLayout.FillDirection = Enum.FillDirection.Horizontal
                        detail.Position = UDim2.fromOffset(0, 70)
                        detail.Size = UDim2.new(1, 0, 1, -70)
                    else
                        workspaceFrame.Size = UDim2.new(1, 0, 0, 505)
                        selector.AutomaticCanvasSize = Enum.AutomaticSize.X
                        selector.Position = UDim2.fromOffset(0, 0)
                        selector.ScrollingDirection = Enum.ScrollingDirection.X
                        selector.Size = UDim2.new(1, 0, 0, 62)
                        selectorPadding.PaddingTop = UDim.new(0, 4)
                        selectorPadding.PaddingRight = UDim.new(0, 0)
                        selectorPadding.PaddingBottom = UDim.new(0, 4)
                        selectorPadding.PaddingLeft = UDim.new(0, 0)
                        selectorLayout.FillDirection = Enum.FillDirection.Horizontal
                        detail.Position = UDim2.fromOffset(0, 70)
                        detail.Size = UDim2.new(1, 0, 1, -70)
                    end
                    local showingVisuals = workspace.Mode == "Visuals"
                    selector.Visible = not showingVisuals
                    detail.Position = showingVisuals
                        and UDim2.fromOffset(0, 0)
                        or UDim2.fromOffset(0, 70)
                    detail.Size = showingVisuals
                        and UDim2.fromScale(1, 1)
                        or UDim2.new(1, 0, 1, -70)
                    local itemCount = 0
                    for _, item in ipairs(workspace.Items) do
                        local isCombatItem = item.Name ~= "Enemy ESP"
                        item.Button.Visible = workspace.Mode ~= "Visuals" and isCombatItem
                        if item.Button.Visible then
                            itemCount += 1
                        end
                    end
                    itemCount = math.max(1, itemCount)
                    for _, item in ipairs(workspace.Items) do
                        if item.Button.Visible and (mobile or itemCount > 4) then
                            item.Button.AutomaticSize = Enum.AutomaticSize.X
                            item.Button.Size = UDim2.fromOffset(0, 54)
                        elseif item.Button.Visible then
                            item.Button.AutomaticSize = Enum.AutomaticSize.None
                            item.Button.Size = UDim2.new(
                                1 / itemCount,
                                -(7 * (itemCount - 1) / itemCount),
                                0,
                                50
                            )
                        end
                    end
                end
                workspace.Mode = self.Name:lower() == "visuals" and "Visuals" or "Combat"
                workspace.SetMode = function(mode)
                    workspace.Mode = mode == "Visuals" and "Visuals" or "Combat"
                    applyFeatureLayout(window.MobileLayout == true)
                    if workspace.Mode == "Visuals" then
                        workspace.ActiveFeature = "Enemy ESP"
                        for _, item in ipairs(workspace.Items) do
                            local selected = item.Name == "Enemy ESP"
                            item.Body.Visible = selected
                            item.Control.SettingsOpen = selected
                        end
                    end
                end
                workspace.ApplyLayout = applyFeatureLayout
                table.insert(window.ResponsiveCallbacks, applyFeatureLayout)
                applyFeatureLayout(window.MobileLayout == true)
            end

            local workspace = self._FeatureWorkspace
            local name = tostring(text or "Feature")
            local selectorName = name == "Enemy ESP" and "ESP" or name
            local featureOrder = {
                ["Aimbot"] = 1,
                ["Aim Assist"] = 2,
                ["Triggerbot"] = 3,
                ["Enemy ESP"] = 4,
            }
            local button = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Surface,
                BackgroundTransparency = 0,
                Size = UDim2.fromOffset(0, 50),
                Font = Enum.Font.GothamMedium,
                LayoutOrder = featureOrder[name] or 50,
                Text = "",
                Parent = workspace.Selector,
            })
            corner(button, 9)
            local buttonGradient = gradient(
                button,
                Color3.fromRGB(11, 20, 27),
                Color3.fromRGB(7, 15, 21),
                108
            )
            local buttonStroke = stroke(button, Theme.Border, 0.48)
            topHighlight(button, 11, 0.91)
            local buttonLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Font = Enum.Font.GothamMedium,
                Text = selectorName,
                TextColor3 = Theme.Muted,
                TextSize = 16,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = button,
            })
            local stateGlow = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.82,
                BorderSizePixel = 0,
                Position = UDim2.new(0.5, 0, 1, 2),
                Size = UDim2.new(1, -10, 0, 7),
                Visible = false,
                Parent = button,
            })
            corner(stateGlow, 4)
            local stateLine = create("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = Theme.Muted,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, -2, 0, 3),
                Visible = false,
                Parent = button,
            })

            local body = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = workspace.Detail,
            })
            local controls = create("ScrollingFrame", {
                Active = true,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                CanvasSize = UDim2.new(),
                Position = UDim2.fromOffset(0, 3),
                ScrollBarImageColor3 = Theme.Accent,
                ScrollBarThickness = 2,
                Size = UDim2.new(1, 0, 1, -3),
                Parent = body,
            })
            padding(controls, 0, 4, 10, 4)
            create("UIListLayout", {
                Padding = UDim.new(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = controls,
            })
            local masterRow = controlRow(controls, 65)
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(28, 0),
                Size = UDim2.new(1, -135, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = name,
                TextColor3 = Theme.Text,
                TextSize = 20,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = masterRow,
            })
            local track = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme.Border,
                Position = UDim2.new(1, -25, 0.5, 0),
                Size = UDim2.fromOffset(70, 35),
                Parent = masterRow,
            })
            corner(track, 18)
            local trackStroke = stroke(track, Theme.Border, 0.12)
            local trackGradient = gradient(track, Theme.Off, Theme.OffDark, 105)
            local knob = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme.Muted,
                Position = UDim2.new(0, 5, 0.5, 0),
                Size = UDim2.fromOffset(26, 26),
                Parent = track,
            })
            corner(knob, 13)
            gradient(
                knob,
                Color3.fromRGB(245, 249, 252),
                Color3.fromRGB(210, 222, 233),
                90
            )
            stroke(knob, Color3.fromRGB(255, 255, 255), 0.76)
            local toggleHit = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Parent = masterRow,
            })

            local control = { Value = default == true, SettingsOpen = false }
            local item = {
                Name = name,
                Button = button,
                ButtonStroke = buttonStroke,
                ButtonGradient = buttonGradient,
                ButtonLabel = buttonLabel,
                StateGlow = stateGlow,
                StateLine = stateLine,
                Body = body,
                Control = control,
            }
            table.insert(workspace.Items, item)
            workspace.ApplyLayout(window.MobileLayout == true)

            local function selectFeature()
                workspace.ActiveFeature = name
                for _, candidate in ipairs(workspace.Items) do
                    local selected = candidate == item
                    candidate.Body.Visible = selected
                    candidate.Control.SettingsOpen = selected
                    tween(candidate.Button, 0.12, {
                        BackgroundTransparency = 0,
                    })
                    tween(candidate.ButtonLabel, 0.12, {
                        TextColor3 = selected and Theme.AccentBright or Theme.NavMuted,
                    })
                    candidate.Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    setGradientColors(
                        candidate.ButtonGradient,
                        selected and Color3.fromRGB(6, 51, 65) or Color3.fromRGB(11, 20, 27),
                        selected and Color3.fromRGB(3, 28, 37) or Color3.fromRGB(7, 15, 21)
                    )
                    tween(candidate.ButtonStroke, 0.12, {
                        Color = selected and Theme.Accent or Theme.Border,
                        Transparency = selected and 0.52 or 0.48,
                    })
                    tween(candidate.StateLine, 0.12, {
                        BackgroundColor3 = selected and Theme.Accent or Theme.Border,
                    })
                    candidate.StateGlow.Visible = selected
                    candidate.StateLine.Visible = selected
                end
            end
            item.Select = selectFeature
            workspace.SelectFeature = function(targetName)
                for _, candidate in ipairs(workspace.Items) do
                    if candidate.Name == targetName and candidate.Select then
                        candidate.Select()
                        return
                    end
                end
            end
            function control:Set(value, silent)
                self.Value = value == true
                setGradientColors(
                    trackGradient,
                    self.Value and Color3.fromRGB(28, 222, 243) or Theme.Off,
                    self.Value and Color3.fromRGB(10, 188, 216) or Theme.OffDark
                )
                tween(trackStroke, 0.12, {
                    Color = self.Value and Theme.Accent or Theme.Border,
                    Transparency = self.Value and 0.04 or 0.12,
                })
                tween(knob, 0.12, {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Position = self.Value and UDim2.new(1, -31, 0.5, 0)
                        or UDim2.new(0, 5, 0.5, 0),
                })
                if not silent then
                    safeCall(callback, self.Value)
                    window.Config:Save()
                end
            end
            function control:SetSettingsOpen(open)
                if open == true then
                    selectFeature()
                end
            end

            button.MouseButton1Click:Connect(selectFeature)
            toggleHit.MouseButton1Click:Connect(function()
                control:Set(not control.Value)
            end)
            control:Set(control.Value, true)
            if name == "Aimbot" or #workspace.Items == 1 then
                selectFeature()
            end
            local settingsTarget = { Container = controls }
            setmetatable(settingsTarget, { __index = self })
            return registerControl(control, flag), settingsTarget
        end

        function tab:Slider(text, minimum, maximum, default, callback, flag)
            minimum, maximum = tonumber(minimum) or 0, tonumber(maximum) or 100
            local description = controlDescription(text)
            local row = controlRow(self.Container, 67)
            local nameLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(28, 0),
                Size = UDim2.new(0.32, 0, 1, 0),
                Font = description and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                Text = tostring(text or "Slider"),
                TextColor3 = Theme.Text,
                TextSize = 20,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            local descriptionLabel
            if description then
                descriptionLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(18, 31),
                    Size = UDim2.new(0.44, 0, 0, 22),
                    Font = Enum.Font.Gotham,
                    Text = description,
                    TextColor3 = Theme.Muted,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })
            end
            local valueLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -64, 0, 0),
                Size = UDim2.fromOffset(55, 67),
                Font = Enum.Font.GothamMedium,
                TextColor3 = Theme.Accent,
                TextSize = 18,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })
            local bar = create("Frame", {
                BackgroundColor3 = Theme.Border,
                Position = UDim2.new(0.41, 0, 0.5, -3),
                Size = UDim2.new(0.43, 0, 0, 7),
                Parent = row,
            })
            corner(bar, 3)
            gradient(bar, Color3.fromRGB(43, 57, 68), Color3.fromRGB(29, 41, 51), 0)
            local fillGlow = create("Frame", {
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.86,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0.5, -5),
                Size = UDim2.new(0, 0, 0, 10),
                Parent = bar,
            })
            corner(fillGlow, 5)
            local fill = create("Frame", {
                BackgroundColor3 = Theme.Accent,
                Size = UDim2.fromScale(0, 1),
                Parent = bar,
            })
            corner(fill, 3)
            gradient(fill, Color3.fromRGB(29, 224, 246), Color3.fromRGB(10, 188, 216), 0)
            local sliderKnob = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Theme.Text,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(20, 20),
                Parent = bar,
            })
            corner(sliderKnob, 10)
            gradient(
                sliderKnob,
                Color3.fromRGB(248, 251, 253),
                Color3.fromRGB(217, 228, 236),
                90
            )
            stroke(sliderKnob, Theme.Accent, 0.14)
            local control = { Value = math.clamp(tonumber(default) or minimum, minimum, maximum) }
            table.insert(window.ResponsiveCallbacks, function(mobile)
                row.Size = UDim2.new(1, 0, 0, mobile and 68 or 67)
                if descriptionLabel then
                    descriptionLabel.Visible = not mobile
                end
                nameLabel.Position = mobile and UDim2.fromOffset(18, 0)
                    or UDim2.fromOffset(28, 0)
                nameLabel.Size = mobile and UDim2.new(0.34, 0, 1, 0)
                    or UDim2.new(0.32, 0, 1, 0)
                nameLabel.Font = mobile and Type.Medium
                    or (description and Type.Bold or Type.Medium)
                nameLabel.TextSize = mobile and 13 or 20
                bar.Position = UDim2.new(mobile and 0.4 or 0.41, 0, 0.5, -3)
                bar.Size = UDim2.new(mobile and 0.38 or 0.43, 0, 0, mobile and 5 or 7)
                valueLabel.Position = UDim2.new(1, mobile and -52 or -64, 0, 0)
                valueLabel.Size = UDim2.fromOffset(mobile and 38 or 55, mobile and 68 or 67)
                valueLabel.TextSize = mobile and 13 or 18
                sliderKnob.Size = mobile and UDim2.fromOffset(16, 16)
                    or UDim2.fromOffset(20, 20)
                sliderKnob:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, mobile and 8 or 10)
            end)
            function control:Set(value, silent)
                self.Value = math.clamp(tonumber(value) or minimum, minimum, maximum)
                local ratio = maximum == minimum and 0 or (self.Value - minimum) / (maximum - minimum)
                fill.Size = UDim2.fromScale(ratio, 1)
                fillGlow.Size = UDim2.new(ratio, 0, 0, 10)
                sliderKnob.Position = UDim2.fromScale(ratio, 0.5)
                valueLabel.Text = tostring(self.Value)
                if not silent then
                    safeCall(callback, self.Value)
                    window.Config:Save()
                end
            end
            local sliding = false
            local function setFromInput(input)
                local ratio = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                control:Set(math.floor((minimum + (maximum - minimum) * ratio) + 0.5))
            end
            row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    sliding = true
                    setFromInput(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch)
                then
                    setFromInput(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    sliding = false
                end
            end)
            control:Set(control.Value, true)
            return registerControl(control, flag)
        end

        function tab:Dropdown(text, options, default, callback, flag)
            options = options or {}
            local description = controlDescription(text)
            local holder = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = self.Container,
            })
            create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = holder,
            })
            local button = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Raised,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 65),
                Font = Enum.Font.Gotham,
                Text = "",
                Parent = holder,
            })
            corner(button, 10)
            stroke(button, Theme.Border, 0.12)
            gradient(button, Theme.Raised, Theme.RaisedBottom, 112)
            topHighlight(button, 14, 0.93)
            local titleLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(28, 0),
                Size = UDim2.new(1, -300, 1, 0),
                Font = description and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                Text = tostring(text or "Dropdown"),
                TextColor3 = Theme.Text,
                TextSize = 20,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = button,
            })
            local descriptionLabel
            if description then
                descriptionLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(18, 31),
                    Size = UDim2.new(1, -275, 0, 22),
                    Font = Enum.Font.Gotham,
                    Text = description,
                    TextColor3 = Theme.Muted,
                    TextSize = 11,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = button,
                })
            end
            local valueBox = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme.Background,
                Position = UDim2.new(1, -20, 0.5, 0),
                Size = UDim2.fromOffset(242, 43),
                Parent = button,
            })
            corner(valueBox, 8)
            stroke(valueBox, Theme.Border, 0.05)
            gradient(valueBox, Theme.Field, Theme.FieldBottom, 112)
            topHighlight(valueBox, 11, 0.92)
            local valueText = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(17, 0),
                Size = UDim2.new(1, -48, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextColor3 = Theme.Text,
                TextSize = 17,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = valueBox,
            })
            local dropdownChevron = chevron(button, Theme.Muted, 2)
            dropdownChevron.AnchorPoint = Vector2.new(1, 0.5)
            dropdownChevron.Position = UDim2.new(1, -33, 0.5, 0)
            local list = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Surface,
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 0),
                Visible = false,
                Parent = holder,
            })
            table.insert(window.ResponsiveCallbacks, function(mobile)
                button.Size = UDim2.new(1, 0, 0, mobile and 68 or 65)
                if descriptionLabel then
                    descriptionLabel.Visible = not mobile
                end
                titleLabel.Position = mobile and UDim2.fromOffset(18, 0)
                    or UDim2.fromOffset(28, 0)
                titleLabel.Size = mobile and UDim2.new(0.43, -18, 1, 0)
                    or UDim2.new(1, -300, 1, 0)
                titleLabel.Font = mobile and Type.Medium
                    or (description and Type.Bold or Type.Medium)
                titleLabel.TextSize = mobile and 13 or 20
                valueBox.Position = UDim2.new(1, mobile and -10 or -20, 0.5, 0)
                valueBox.Size = mobile and UDim2.new(0.54, 0, 0, 44)
                    or UDim2.fromOffset(242, 43)
                valueText.Position = UDim2.fromOffset(mobile and 12 or 17, 0)
                valueText.TextSize = mobile and 12 or 16
                dropdownChevron.Position = UDim2.new(1, mobile and -24 or -33, 0.5, 0)
            end)
            padding(list, 5)
            corner(list, 8)
            gradient(list, Color3.fromRGB(9, 21, 29), Color3.fromRGB(4, 12, 18), 110)
            stroke(list, Theme.BorderBright, 0.42)
            create("UIListLayout", { Padding = UDim.new(0, 2), Parent = list })
            local control = { Value = default or options[1], Open = false }
            local itemButtons = {}
            function control:Set(value, silent)
                self.Value = value
                valueText.Text = tostring(value or "None")
                for option, item in pairs(itemButtons) do
                    local selected = option == value
                    item.TextColor3 = selected and Theme.Accent or Theme.Muted
                    item.BackgroundColor3 = selected and Theme.Hover or Theme.Raised
                end
                if not silent then
                    safeCall(callback, value)
                    window.Config:Save()
                end
            end
            for _, option in ipairs(options) do
                local item = create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Theme.Raised,
                    BackgroundTransparency = 0.35,
                    Size = UDim2.new(1, 0, 0, 44),
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(option),
                    TextColor3 = Theme.Muted,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = list,
                })
                corner(item, 7)
                padding(item, 0, 14, 0, 14)
                itemButtons[option] = item
                item.MouseButton1Click:Connect(function()
                    control:Set(option)
                    control.Open = false
                    list.Visible = false
                end)
            end
            button.MouseButton1Click:Connect(function()
                control.Open = not control.Open
                list.Visible = control.Open
                dropdownChevron.Rotation = control.Open and 90 or 0
            end)
            control:Set(control.Value, true)
            return registerControl(control, flag)
        end

        function tab:MultiDropdown(text, options, default, callback, flag)
            options = options or {}
            local holder = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = self.Container,
            })
            create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = holder,
            })
            local button = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Raised,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 44),
                Font = Enum.Font.Gotham,
                TextColor3 = Theme.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })
            padding(button, 0, 12, 0, 12)
            corner(button, 8)
            local multiDropdownChevron = chevron(button, Theme.Muted, 2)
            multiDropdownChevron.AnchorPoint = Vector2.new(1, 0.5)
            multiDropdownChevron.Position = UDim2.new(1, -10, 0.5, 0)
            local list = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Surface,
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 0),
                Visible = false,
                Parent = holder,
            })
            padding(list, 5)
            corner(list, 8)
            create("UIListLayout", { Padding = UDim.new(0, 2), Parent = list })

            local itemButtons = {}
            local control = { Value = {}, Open = false }

            local function contains(values, wanted)
                for _, value in ipairs(values) do
                    if value == wanted then
                        return true
                    end
                end
                return false
            end

            local function updateDisplay()
                local count = #control.Value
                local summary = count == 0
                    and "None"
                    or count == 1
                        and tostring(control.Value[1])
                        or tostring(count) .. " selected"
                button.Text = tostring(text or "Multi Dropdown")
                    .. "   -   "
                    .. summary

                for option, item in pairs(itemButtons) do
                    local selected = contains(control.Value, option)
                    item.Text = (selected and "[x]  " or "[ ]  ") .. tostring(option)
                    item.TextColor3 = selected and Theme.Accent or Theme.Muted
                    item.BackgroundTransparency = selected and 0.05 or 0.35
                end
            end

            function control:Set(values, silent)
                local selected = {}
                if type(values) == "table" then
                    for _, option in ipairs(options) do
                        if contains(values, option) then
                            table.insert(selected, option)
                        end
                    end
                end

                self.Value = selected
                updateDisplay()
                if not silent then
                    safeCall(callback, table.clone(self.Value))
                    window.Config:Save()
                end
            end

            for _, option in ipairs(options) do
                local item = create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Theme.Raised,
                    BackgroundTransparency = 0.35,
                    Size = UDim2.new(1, 0, 0, 44),
                    Font = Enum.Font.Gotham,
                    Text = tostring(option),
                    TextColor3 = Theme.Muted,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = list,
                })
                padding(item, 0, 10, 0, 10)
                corner(item, 7)
                itemButtons[option] = item

                item.MouseButton1Click:Connect(function()
                    local selected = table.clone(control.Value)
                    if contains(selected, option) then
                        for index, value in ipairs(selected) do
                            if value == option then
                                table.remove(selected, index)
                                break
                            end
                        end
                    else
                        table.insert(selected, option)
                    end
                    control:Set(selected)
                end)
            end

            button.MouseButton1Click:Connect(function()
                control.Open = not control.Open
                list.Visible = control.Open
                multiDropdownChevron.Rotation = control.Open and 90 or 0
            end)

            control:Set(type(default) == "table" and default or {}, true)
            return registerControl(control, flag)
        end

        function tab:Input(text, placeholder, callback, flag)
            local row = controlRow(self.Container, 68)
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 4),
                Size = UDim2.new(1, -20, 0, 19),
                Font = Enum.Font.Gotham,
                Text = tostring(text or "Input"),
                TextColor3 = Theme.Muted,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            local box = create("TextBox", {
                BackgroundColor3 = Theme.Background,
                ClearTextOnFocus = false,
                ClipsDescendants = true,
                Position = UDim2.fromOffset(10, 27),
                Size = UDim2.new(1, -20, 0, 32),
                Font = Enum.Font.Gotham,
                PlaceholderColor3 = Theme.Muted,
                PlaceholderText = tostring(placeholder or "Enter value"),
                Text = "",
                TextColor3 = Theme.Text,
                TextSize = 12,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            padding(box, 0, 9, 0, 9)
            corner(box, 7)
            local control = { Value = "" }
            function control:Set(value, silent)
                self.Value = tostring(value or "")
                box.Text = self.Value
                if not silent then
                    safeCall(callback, self.Value)
                    window.Config:Save()
                end
            end
            box.Focused:Connect(function()
                box.TextTruncate = Enum.TextTruncate.None
            end)
            box.FocusLost:Connect(function(enterPressed)
                control:Set(box.Text)
                box.TextTruncate = Enum.TextTruncate.AtEnd
            end)
            return registerControl(control, flag)
        end

        function tab:Keybind(text, default, callback, flag)
            local row = controlRow(self.Container)
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -84, 1, 0),
                Font = Enum.Font.Gotham,
                Text = tostring(text or "Keybind"),
                TextColor3 = Theme.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            local bind = create("TextButton", {
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme.Background,
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(60, 34),
                Font = Enum.Font.GothamMedium,
                TextColor3 = Theme.Accent,
                TextSize = 11,
                Parent = row,
            })
            corner(bind, 7)
            local control = {
                Value = tostring(default or "None"),
                Listening = false,
            }
            function control:Set(value, silent)
                self.Value = tostring(value or "None")
                bind.Text = self.Value
                if not silent then
                    window.Config:Save()
                end
            end
            bind.MouseButton1Click:Connect(function()
                control.Listening = true
                bind.Text = "..."
            end)
            UserInputService.InputBegan:Connect(function(input, processed)
                if control.Listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    control.Listening = false
                    control:Set(input.KeyCode.Name)
                elseif not processed and input.UserInputType == Enum.UserInputType.Keyboard
                    and input.KeyCode.Name == control.Value
                then
                    safeCall(callback)
                end
            end)
            control:Set(control.Value, true)
            return registerControl(control, flag)
        end

        function tab:Label(text)
            return addLabel(text, Theme.Muted, 11, self.Container)
        end

        function tab:Paragraph(title, text)
            local row = controlRow(self.Container, 0)
            row.AutomaticSize = Enum.AutomaticSize.Y
            padding(row, 12)
            create("UIListLayout", {
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = row,
            })
            create("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Font = Enum.Font.GothamMedium,
                Text = tostring(title or ""),
                TextColor3 = Theme.Text,
                TextSize = 12,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Parent = row,
            })
            return create("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 0),
                Font = Enum.Font.Gotham,
                Text = tostring(text or ""),
                TextColor3 = Theme.Muted,
                TextSize = 11,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Parent = row,
            })
        end

        function tab:Divider()
            return create("Frame", {
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 1),
                Parent = self.Container,
            })
        end

        table.insert(window.Tabs, tab)
        tab:ApplyResponsiveLayout(window.MobileLayout == true)
        if #window.Tabs == 1 then
            window:SelectTab(tab)
        end

        if tab.Name:lower() == "settings" and not window._AntiAfkAdded then
            window._AntiAfkAdded = true
            local reverbSettings = tab:Section("Reverb")
            local antiAfkControl
            antiAfkControl = reverbSettings:Toggle(
                "Anti AFK",
                Library:GetAntiAfk(),
                function(enabled)
                    Library:SetAntiAfk(enabled, antiAfkControl)
                end
            )
            antiAfkControl.Window = window
            table.insert(Library._AntiAfkControls, antiAfkControl)
            reverbSettings:Button("Copy Reverb website", function()
                copyLink("Website", REVERB_WEBSITE)
            end)
            reverbSettings:Button("Copy Discord invite", function()
                copyLink("Discord", REVERB_DISCORD)
            end)
            reverbSettings:Button("Reset interface position", resetUiPositions)
        end

        return tab
    end

    function window:CreateChangelogTab(options)
        options = options or {}
        local changelogTab = self:Tab(options.Name or "Changelog")
        local entries = type(options.Entries) == "table" and options.Entries or {}
        local groups = {
            { Key = "Added", Label = "Added" },
            { Key = "Improved", Label = "Improved" },
            { Key = "Fixed", Label = "Fixed" },
            { Key = "Removed", Label = "Removed" },
        }

        for entryIndex, entry in ipairs(entries) do
            local hasDetails = false
            for _, group in ipairs(groups) do
                local values = entry[group.Key]
                if type(values) == "table" and #values > 0 then
                    hasDetails = true
                    break
                end
            end
            local release = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = changelogTab.Container,
            })
            create("UIListLayout", {
                Padding = UDim.new(0, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = release,
            })

            local headerButton = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Background,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, hasDetails and 54 or 70),
                Text = "",
                Parent = release,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 8),
                Size = UDim2.new(0, 84, 0, 24),
                Font = Enum.Font.GothamBold,
                Text = tostring(entry.Version or "Update"),
                TextColor3 = entryIndex == 1 and Theme.Accent or Theme.Text,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerButton,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 92, 0, 10),
                Size = UDim2.new(1, -132, 0, 20),
                Font = Enum.Font.Gotham,
                Text = tostring(entry.Date or ""),
                TextColor3 = Theme.Muted,
                TextSize = 13,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerButton,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 37),
                Size = UDim2.new(1, -42, 0, 25),
                Font = Enum.Font.GothamMedium,
                Text = tostring(entry.Title or ""),
                TextColor3 = Theme.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not hasDetails and entry.Title ~= nil,
                Parent = headerButton,
            })
            local disclosureHost = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(32, 44),
                Visible = hasDetails,
                Parent = headerButton,
            })
            local disclosure = chevron(disclosureHost, Theme.Muted, 2)
            create("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = Theme.Border,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 1),
                Parent = headerButton,
            })

            local details = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Surface,
                BackgroundTransparency = 0.5,
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = release,
            })
            padding(details, 12, 14, 14, 14)
            create("UIListLayout", {
                Padding = UDim.new(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = details,
            })

            for _, group in ipairs(groups) do
                local values = entry[group.Key]
                if type(values) == "table" and #values > 0 then
                    for _, value in ipairs(values) do
                        local note = create("Frame", {
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 0),
                            Parent = details,
                        })
                        create("Frame", {
                            BackgroundColor3 = Theme.Accent,
                            BorderSizePixel = 0,
                            Position = UDim2.fromOffset(1, 9),
                            Size = UDim2.fromOffset(5, 5),
                            Parent = note,
                        })
                        create("TextLabel", {
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(17, 0),
                            Size = UDim2.new(1, -17, 0, 22),
                            Font = Enum.Font.GothamMedium,
                            Text = tostring(value),
                            TextColor3 = Theme.Text,
                            TextSize = 14,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Top,
                            Parent = note,
                        })
                    end
                end
            end

            local open = entryIndex == 1 and hasDetails
            local function setOpen(nextOpen)
                open = hasDetails and nextOpen == true
                details.Visible = open
                disclosure.Rotation = open and 90 or 0
                for _, segment in ipairs(disclosure:GetChildren()) do
                    segment.BackgroundColor3 = open and Theme.Accent or Theme.Muted
                end
            end
            if hasDetails then
                headerButton.MouseButton1Click:Connect(function()
                    setOpen(not open)
                end)
            end
            setOpen(open)
        end

        return changelogTab
    end

    window.Config = configApi(window)
    table.insert(self.Windows, window)
    updateScale()
    closeReverbLoader()
    if window.Remember then
        task.defer(function()
            window.Config:Load()
        end)
    end
    if environment().ReverbEmergencyAccess == true and not self._EmergencyNoticeShown then
        self._EmergencyNoticeShown = true
        task.defer(function()
            self:Notify("Temporary keyless access is active. Premium features remain locked.", 5)
        end)
    end
    return window
end

function Library:Destroy()
    if self._AntiAfkConnection then
        self._AntiAfkConnection:Disconnect()
        self._AntiAfkConnection = nil
    end
    table.clear(self._AntiAfkControls)
    table.clear(self.Windows)
    root:Destroy()
    local env = environment()
    if env.ReverbCompactLibrary == self then
        env.ReverbCompactLibrary = nil
    end
end

local cameraConnection
local function watchCamera()
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    local camera = workspace.CurrentCamera
    if camera then
        cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end
    updateScale()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
loadDefaultLogo()

local env = environment()
local previousLibrary = env.ReverbCompactLibrary
if previousLibrary ~= Library and type(previousLibrary) == "table"
    and type(previousLibrary.Destroy) == "function"
then
    pcall(function()
        previousLibrary:Destroy()
    end)
end
env.ReverbCompactLibrary = Library
Library:SetAntiAfk(true)

return Library
