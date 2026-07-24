--[[
    Reverb J
    A separate, compact UI runtime for Reverb scripts.

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
    Version = "0.1.0",
}

local Theme = {
    Background = Color3.fromRGB(10, 12, 16),
    Surface = Color3.fromRGB(17, 20, 27),
    Raised = Color3.fromRGB(24, 28, 37),
    Hover = Color3.fromRGB(30, 36, 48),
    Accent = Color3.fromRGB(0, 174, 255),
    AccentDark = Color3.fromRGB(0, 105, 170),
    Text = Color3.fromRGB(238, 244, 250),
    Muted = Color3.fromRGB(142, 153, 168),
    Border = Color3.fromRGB(41, 48, 61),
    Danger = Color3.fromRGB(225, 76, 86),
}

local function create(className, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        if property ~= "Parent" then
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
    Name = "ReverbLauncher",
    AutoButtonColor = false,
    BackgroundColor3 = Theme.Background,
    Position = UDim2.new(0, 14, 0.5, -22),
    Size = UDim2.fromOffset(44, 44),
    Image = "rbxassetid://0",
    Parent = root,
})
corner(launcher, 12)
stroke(launcher, Theme.Accent, 0.15)

-- Text fallback stays visible until a hosted Reverb icon asset id is supplied.
local launcherMark = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Font = Enum.Font.GothamBold,
    Text = "R",
    TextColor3 = Theme.Accent,
    TextSize = 21,
    Parent = launcher,
})
makeDraggable(launcher, launcher)

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
            launcher.Image = customAsset(path)
            launcherMark.Visible = false
        end)
        if not ok then
            launcherMark.Visible = true
        end
    end)
end

local function updateScale()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local scale = math.clamp(math.min(viewport.X / 900, viewport.Y / 650), 0.78, 1)
    for _, window in ipairs(Library.Windows) do
        window.Scale.Scale = scale
    end
end

function Library:SetOpen(isOpen)
    self.Open = isOpen == true
    windowLayer.Visible = self.Open
    tween(launcher, 0.14, {
        BackgroundColor3 = self.Open and Theme.AccentDark or Theme.Background,
    })
end

function Library:Toggle()
    self:SetOpen(not self.Open)
end

launcher.MouseButton1Click:Connect(function()
    Library:Toggle()
end)

function Library:SetLogo(asset)
    if type(asset) == "number" then
        launcher.Image = "rbxassetid://" .. asset
    elseif type(asset) == "string" then
        launcher.Image = asset
    end
    launcherMark.Visible = launcher.Image == "" or launcher.Image == "rbxassetid://0"
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
    return string.format("%s by Reverb [%s]", name, resolveTier(options))
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
                control:Set(value, true)
            end
        end
        return true
    end

    return api
end

function Library:CreateWindow(options)
    options = options or {}
    local index = #self.Windows + 1
    local window = {
        Tabs = {},
        Flags = {},
        Remember = options.RememberSettings == true,
        ConfigPath = "Reverb/" .. tostring(options.ConfigName or options.Game or options.Title or "script")
            :gsub("[^%w_-]", "_") .. "_compact.json",
    }

    local frame = create("Frame", {
        Name = "Window" .. index,
        BackgroundColor3 = Theme.Background,
        Position = options.Position or UDim2.new(0.5, -150 + ((index - 1) * 24), 0.5, -190 + ((index - 1) * 20)),
        Size = UDim2.fromOffset(300, 380),
        ClipsDescendants = true,
        Parent = windowLayer,
    })
    corner(frame, 8)
    stroke(frame, Theme.Border)
    window.Frame = frame
    window.Scale = create("UIScale", { Scale = 1, Parent = frame })

    local header = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        Parent = frame,
    })
    create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Parent = header,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 2),
        Size = UDim2.new(1, -44, 1, -2),
        Font = Enum.Font.GothamMedium,
        Text = titleFor(options),
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    local hide = create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -34, 0, 2),
        Size = UDim2.fromOffset(32, 32),
        Font = Enum.Font.GothamBold,
        Text = "–",
        TextColor3 = Theme.Muted,
        TextSize = 16,
        Parent = header,
    })
    hide.MouseButton1Click:Connect(function()
        Library:SetOpen(false)
    end)
    makeDraggable(header, frame)

    local tabBar = create("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        Position = UDim2.fromOffset(0, 36),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        Size = UDim2.new(1, 0, 0, 31),
        Parent = frame,
    })
    padding(tabBar, 0, 6, 0, 6)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 2),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = tabBar,
    })

    local content = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 67),
        Size = UDim2.new(1, 0, 1, -67),
        Parent = frame,
    })
    window.Content = content

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
            tween(tab.Button, 0.12, {
                TextColor3 = active and Theme.Text or Theme.Muted,
                BackgroundTransparency = active and 0 or 1,
            })
            tab.Indicator.Visible = active
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
            BackgroundTransparency = 0.18,
            Size = UDim2.new(1, 0, 0, height or 34),
            Parent = parent,
        })
        corner(row, 5)
        return row
    end

    function window:Tab(name)
        local tab = { Name = tostring(name or "Tab") }
        tab.Button = create("TextButton", {
            AutomaticSize = Enum.AutomaticSize.X,
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Raised,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 25),
            Font = Enum.Font.GothamMedium,
            Text = tab.Name,
            TextColor3 = Theme.Muted,
            TextSize = 11,
            Parent = tabBar,
        })
        padding(tab.Button, 0, 9, 0, 9)
        corner(tab.Button, 4)
        tab.Indicator = create("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 5, 1, 0),
            Size = UDim2.new(1, -10, 0, 2),
            Visible = false,
            Parent = tab.Button,
        })
        corner(tab.Indicator, 2)

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
        padding(tab.Page, 8, 8, 8, 8)
        create("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tab.Page,
        })
        tab.Container = tab.Page

        tab.Button.MouseButton1Click:Connect(function()
            window:SelectTab(tab)
        end)

        local function addLabel(text, color, size)
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
                Parent = tab.Container,
            })
            return label
        end

        function tab:Section(sectionName, collapsed)
            local section = {}
            local shell = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = self.Container,
            })
            local layout = create("UIListLayout", {
                Padding = UDim.new(0, 5),
                Parent = shell,
            })
            local sectionButton = create("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                Font = Enum.Font.GothamMedium,
                Text = "⌄  " .. tostring(sectionName or "Section"),
                TextColor3 = Theme.Muted,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = shell,
            })
            local body = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = shell,
            })
            create("UIListLayout", {
                Padding = UDim.new(0, 5),
                Parent = body,
            })
            section.Open = collapsed ~= true
            body.Visible = section.Open
            sectionButton.Text = (section.Open and "⌄  " or "›  ") .. tostring(sectionName or "Section")
            sectionButton.MouseButton1Click:Connect(function()
                section.Open = not section.Open
                body.Visible = section.Open
                sectionButton.Text = (section.Open and "⌄  " or "›  ") .. tostring(sectionName or "Section")
            end)
            section.Container = body
            setmetatable(section, { __index = tab })
            return section
        end

        function tab:Button(text, callback)
            local button = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Raised,
                Size = UDim2.new(1, 0, 0, 34),
                Font = Enum.Font.GothamMedium,
                Text = tostring(text or "Button"),
                TextColor3 = Theme.Text,
                TextSize = 11,
                Parent = self.Container,
            })
            corner(button, 5)
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
            local row = controlRow(self.Container)
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -52, 1, 0),
                Font = Enum.Font.Gotham,
                Text = tostring(text or "Toggle"),
                TextColor3 = Theme.Text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            local track = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme.Border,
                Position = UDim2.new(1, -9, 0.5, 0),
                Size = UDim2.fromOffset(30, 16),
                Parent = row,
            })
            corner(track, 8)
            local knob = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme.Muted,
                Position = UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.fromOffset(10, 10),
                Parent = track,
            })
            corner(knob, 5)
            local hit = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Parent = row,
            })
            local control = { Value = default == true }
            function control:Set(value, silent)
                self.Value = value == true
                tween(track, 0.12, {
                    BackgroundColor3 = self.Value and Theme.Accent or Theme.Border,
                })
                tween(knob, 0.12, {
                    BackgroundColor3 = self.Value and Theme.Text or Theme.Muted,
                    Position = self.Value and UDim2.new(1, -13, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
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
            return registerControl(control, flag)
        end

        function tab:Slider(text, minimum, maximum, default, callback, flag)
            minimum, maximum = tonumber(minimum) or 0, tonumber(maximum) or 100
            local row = controlRow(self.Container, 48)
            local nameLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 2),
                Size = UDim2.new(1, -62, 0, 24),
                Font = Enum.Font.Gotham,
                Text = tostring(text or "Slider"),
                TextColor3 = Theme.Text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            local valueLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -52, 0, 2),
                Size = UDim2.fromOffset(42, 24),
                Font = Enum.Font.GothamMedium,
                TextColor3 = Theme.Accent,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })
            local bar = create("Frame", {
                BackgroundColor3 = Theme.Border,
                Position = UDim2.new(0, 10, 1, -13),
                Size = UDim2.new(1, -20, 0, 4),
                Parent = row,
            })
            corner(bar, 2)
            local fill = create("Frame", {
                BackgroundColor3 = Theme.Accent,
                Size = UDim2.fromScale(0, 1),
                Parent = bar,
            })
            corner(fill, 2)
            local control = { Value = math.clamp(tonumber(default) or minimum, minimum, maximum) }
            function control:Set(value, silent)
                self.Value = math.clamp(tonumber(value) or minimum, minimum, maximum)
                local ratio = maximum == minimum and 0 or (self.Value - minimum) / (maximum - minimum)
                fill.Size = UDim2.fromScale(ratio, 1)
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
            local holder = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = self.Container,
            })
            create("UIListLayout", { Padding = UDim.new(0, 2), Parent = holder })
            local button = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Raised,
                Size = UDim2.new(1, 0, 0, 34),
                Font = Enum.Font.Gotham,
                TextColor3 = Theme.Text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })
            padding(button, 0, 10, 0, 10)
            corner(button, 5)
            local list = create("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Surface,
                Size = UDim2.new(1, 0, 0, 0),
                Visible = false,
                Parent = holder,
            })
            padding(list, 3)
            corner(list, 5)
            create("UIListLayout", { Padding = UDim.new(0, 2), Parent = list })
            local control = { Value = default or options[1], Open = false }
            function control:Set(value, silent)
                self.Value = value
                button.Text = tostring(text or "Dropdown") .. "   ·   " .. tostring(value or "None") .. "   ⌄"
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
                    Size = UDim2.new(1, 0, 0, 28),
                    Font = Enum.Font.Gotham,
                    Text = tostring(option),
                    TextColor3 = Theme.Muted,
                    TextSize = 10,
                    Parent = list,
                })
                corner(item, 4)
                item.MouseButton1Click:Connect(function()
                    control:Set(option)
                    control.Open = false
                    list.Visible = false
                end)
            end
            button.MouseButton1Click:Connect(function()
                control.Open = not control.Open
                list.Visible = control.Open
            end)
            control:Set(control.Value, true)
            return registerControl(control, flag)
        end

        function tab:Input(text, placeholder, callback, flag)
            local row = controlRow(self.Container, 52)
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 2),
                Size = UDim2.new(1, -20, 0, 19),
                Font = Enum.Font.Gotham,
                Text = tostring(text or "Input"),
                TextColor3 = Theme.Muted,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            local box = create("TextBox", {
                BackgroundColor3 = Theme.Background,
                ClearTextOnFocus = false,
                Position = UDim2.fromOffset(8, 23),
                Size = UDim2.new(1, -16, 0, 23),
                Font = Enum.Font.Gotham,
                PlaceholderColor3 = Theme.Muted,
                PlaceholderText = tostring(placeholder or "Enter value"),
                Text = "",
                TextColor3 = Theme.Text,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            padding(box, 0, 7, 0, 7)
            corner(box, 4)
            local control = { Value = "" }
            function control:Set(value, silent)
                self.Value = tostring(value or "")
                box.Text = self.Value
                if not silent then
                    safeCall(callback, self.Value)
                    window.Config:Save()
                end
            end
            box.FocusLost:Connect(function(enterPressed)
                control:Set(box.Text)
            end)
            return registerControl(control, flag)
        end

        function tab:Keybind(text, default, callback, flag)
            local row = controlRow(self.Container)
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -70, 1, 0),
                Font = Enum.Font.Gotham,
                Text = tostring(text or "Keybind"),
                TextColor3 = Theme.Text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            local bind = create("TextButton", {
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme.Background,
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(50, 22),
                Font = Enum.Font.GothamMedium,
                TextColor3 = Theme.Accent,
                TextSize = 9,
                Parent = row,
            })
            corner(bind, 4)
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
            return addLabel(text, Theme.Muted, 10)
        end

        function tab:Paragraph(title, text)
            local row = controlRow(self.Container, 0)
            row.AutomaticSize = Enum.AutomaticSize.Y
            padding(row, 9)
            local body = create("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Font = Enum.Font.Gotham,
                Text = string.format("%s\n%s", tostring(title or ""), tostring(text or "")),
                TextColor3 = Theme.Muted,
                TextSize = 10,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Parent = row,
            })
            return body
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
        if #window.Tabs == 1 then
            window:SelectTab(tab)
        end
        return tab
    end

    window.Config = configApi(window)
    table.insert(self.Windows, window)
    updateScale()
    if window.Remember then
        task.defer(function()
            window.Config:Load()
        end)
    end
    return window
end

function Library:Destroy()
    table.clear(self.Windows)
    root:Destroy()
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

return Library
