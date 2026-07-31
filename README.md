# Reverb J

Reverb J is a separate compact UI option for Reverb scripts. Its internal name is
not shown to players. It is independent from the main `ReverbUI` library and is
designed for low screen usage, touch support, low complexity, and beginner-friendly
Lua.

## Runtime

```lua
local ReverbJ = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/rbxreverb/ReverbJ/refs/heads/main/source.lua"
))()
```

The repository URL is a planned hosting location. Until that repository exists,
load the local `source.lua` through the development workflow.

The floating launcher loads the existing Reverb logo once and caches it locally.
`ReverbJ:SetLogo(assetId)` can override it later if a dedicated Roblox asset is
uploaded.

## Responsive launcher

The Reverb logo is the shared control point for every ReverbJ window:

- Click or tap it to show and hide the script UI.
- Drag it freely anywhere; its exact position is remembered.
- Right-click it on desktop, or hold it on mobile, to open Reverb Controls.
- Press `RightControl` on desktop to show or hide the script UI.

Reverb Controls includes the official website and Discord invite, UI scaling,
and a reset-position action. Link buttons copy their URL to the clipboard when
the executor supports it. Mobile windows use the available viewport instead of
shrinking desktop controls to an unusable size, and their existing pages remain
scrollable.

The floating logo has two permanently available, compact action chips beside it:
`Join Discord` and `Visit Website`. They follow the launcher, automatically move
to whichever side has room, and copy the relevant official link when clicked.

## Basic usage

```lua
local UI = ReverbJ:CreateWindow({
    Game = "My Game",
    Tier = "FREE",
})

local Main = UI:Tab("Main")

Main:Toggle("Auto Farm", false, function(enabled)
    print(enabled)
end, "AutoFarm")
```

The visible title is always formatted as:

```text
My Game by Reverb [FREE]
```

Set `Tier = "PREMIUM"` for premium users. If omitted, the library checks the
current Reverb loader fields, including `Shared_LRM_UserNote`, and otherwise
safely defaults to `FREE`.

## Controls

```lua
local section = Main:Section("Section name", false) -- second value starts collapsed

section:Button("Run", function() end)
section:Toggle("Enabled", false, function(value) end, "EnabledFlag")

local toggle, settings = section:SettingsToggle(
    "Feature",
    false,
    function(value) end,
    "FeatureFlag"
)
settings:Toggle("Option", true, function(value) end, "OptionFlag")
section:Slider("Amount", 0, 100, 50, function(value) end, "AmountFlag")
section:Dropdown("Mode", {"A", "B"}, "A", function(value) end, "ModeFlag")
section:MultiDropdown("ESP Features", {"Boxes", "Names"}, {"Boxes"}, function(values) end, "EspFlag")
section:Input("Name", "Type here", function(value) end, "NameFlag")
section:Keybind("Action", "Q", function() end, "ActionBind")
section:Label("Small supporting text")
section:Paragraph("Heading", "Longer information text.")
section:Divider()
```

Flags are optional. Add them to controls whose values should be eligible for the
opt-in remember feature.

## Built-in Anti-AFK

Every tab named `Settings` automatically receives a compact `Reverb` section
containing an `Anti AFK` toggle. It is enabled by default and uses the same
idle-response behavior as the main Reverb UI.

```lua
local Settings = UI:Tab("Settings")
-- Anti AFK is added automatically. Add script-specific settings normally:
Settings:Toggle("Remember active settings", false, function(enabled)
    UI:SetRememberSettings(enabled)
end)
```

All Reverb J windows share one Anti-AFK connection. Changing the setting in one
window updates the setting across the others.

## Remember settings

Saving is intentionally off by default:

```lua
local UI = ReverbJ:CreateWindow({
    Game = "My Game",
    RememberSettings = false,
    ConfigName = "MyGame",
})

Settings:Toggle("Remember active settings", false, function(enabled)
    UI:SetRememberSettings(enabled)
end)
```

When enabled, supported flagged controls are stored using the executor filesystem.
Nothing is written while remembering is disabled.

## Multiple windows

Call `CreateWindow` again. Every window may have its own tabs and can be dragged
independently. The floating Reverb logo hides or shows all windows together.

```lua
local Tools = ReverbJ:CreateWindow({
    Game = "My Game Tools",
    Tier = "FREE",
})
```

## Design constraints

- One narrow 300 × 380 logical-pixel column per window.
- Automatic scale between 78% and 100% based on viewport size.
- Horizontal scrolling tabs on narrow screens.
- Mouse and touch dragging.
- Subtle short tweens only.
- No themes, external icon pack, blur, gradients, or heavy decoration.
- Reverb black, blue, white, and muted-grey palette only.
