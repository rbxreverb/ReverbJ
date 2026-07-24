local ReverbJ = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/rbxreverb/ReverbJ/refs/heads/main/source.lua"
))()

local UI = ReverbJ:CreateWindow({
    Game = "Example Game",
    Tier = "FREE", -- The loader can pass "PREMIUM" here.
    RememberSettings = false,
    ConfigName = "ExampleGame",
})

local Main = UI:Tab("Main")
local Player = UI:Tab("Player")
local Settings = UI:Tab("Settings")

local Farming = Main:Section("Farming")

Farming:Toggle("Auto Farm", false, function(enabled)
    print("Auto Farm:", enabled)
end, "AutoFarm")

Farming:Slider("Farm Speed", 1, 10, 5, function(value)
    print("Farm Speed:", value)
end, "FarmSpeed")

Farming:Dropdown("Target", {
    "Nearest",
    "Lowest Health",
    "Highest Value",
}, "Nearest", function(value)
    print("Target:", value)
end, "Target")

Main:Section("Actions"):Button("Collect Everything", function()
    UI:Notify("Collected everything.", 2.5)
end)

Player:Input("Walk Speed", "16", function(value)
    local speed = tonumber(value)
    local character = game.Players.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if speed and humanoid then
        humanoid.WalkSpeed = speed
    end
end, "WalkSpeed")

Player:Keybind("Quick Action", "Q", function()
    print("Quick action")
end, "QuickAction")

Settings:Toggle("Remember active settings", false, function(enabled)
    UI:SetRememberSettings(enabled)
    UI:Notify(enabled and "Settings will now be remembered." or "Settings will no longer be saved.")
end)

Settings:Paragraph(
    "Compact by design",
    "Drag the header to move this window. Use the floating Reverb logo to hide or show all windows."
)
