-- =========================================================================
-- AREUM HUB LOADER (UAV STRIKE Loader - Mobile & PC Optimized)
-- =========================================================================
local Lversion = "2.000.1"
print(`[ Loader Version: v{Lversion} | Supports UI Library Versions From 2.000.0 ]`)

local env = getfenv(0)

if env.AreumHubExecuted == true then
    warn("[Areum Hub] Hub is already running!")
    return
end
env.AreumHubExecuted = true

local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- =========================================================================
-- CONFIGURATION MANAGER (Crash-Proof Mobile JSON Workspace Saving)
-- =========================================================================
local CONFIG_FILE = "AreumHub_UAV_STRIKE.json"

local ConfigManager = {
    Data = {
        CurrentTheme = "Violet",
        ToggleKey = "LeftControl",
        MobileButton = false,
        FetchVersions = false,
    }
}

function ConfigManager:Load()
    pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" then
            if isfile(CONFIG_FILE) then
                local success, content = pcall(readfile, CONFIG_FILE)
                if success and type(content) == "string" then
                    local successDecode, decoded = pcall(function()
                        return HttpService:JSONDecode(content)
                    end)
                    if successDecode and type(decoded) == "table" then
                        print("[Areum Hub] Configuration loaded successfully from workspace.")
                        for k, v in pairs(decoded) do
                            ConfigManager.Data[k] = v
                        end
                    end
                end
            end
        end
    end)
end

function ConfigManager:Save()
    pcall(function()
        if type(writefile) == "function" then
            local successEncode, encoded = pcall(function()
                return HttpService:JSONEncode(self.Data)
            end)
            if successEncode and type(encoded) == "string" then
                writefile(CONFIG_FILE, encoded)
            end
        end
    end)
end

-- Load config data safely on startup
ConfigManager:Load()

-- Environment Configuration Defaults (Synced with ConfigManager data)
env.SCRIPT_ACTIVE = true
env.UI_TOGGLE_KEY = Enum.KeyCode[ConfigManager.Data.ToggleKey] or Enum.KeyCode.LeftControl
env.STOP_KEY = Enum.KeyCode.F1
env.CURRENT_THEME = ConfigManager.Data.CurrentTheme
env.MOBILE_BUTTON = ConfigManager.Data.MobileButton
env.FETCHVERSIONS = ConfigManager.Data.FetchVersions

local useless_local = false
local update_shown = false

local UIModuleLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/Areum-UI-Library.lua"
local DataLibraryLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/refs/heads/main/Areum-Data-Configs.lua"

-- Mobile Floating Button Management
local mobileButtonGui = nil
local onupdate = nil

local function setupMobileButton(enabled)
    if enabled then
        if mobileButtonGui then return end
        
        local coreGui = nil
        pcall(function() coreGui = game:GetService("CoreGui") end)
        local parentTarget = coreGui or player:WaitForChild("PlayerGui")
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "AreumHub_MobileButton"
        screenGui.ResetOnSpawn = false
        
        pcall(function()
            if syn and syn.protect_gui then
                syn.protect_gui(screenGui)
                screenGui.Parent = coreGui
            elseif protectgui then
                protectgui(screenGui)
                screenGui.Parent = coreGui
            else
                screenGui.Parent = parentTarget
            end
        end)
        if not screenGui.Parent then
            screenGui.Parent = parentTarget
        end
        
        local btn = Instance.new("ImageButton")
        btn.Name = "ToggleBtn"
        btn.Size = UDim2.new(0, 45, 0, 45)
        btn.Position = UDim2.new(0, 30, 0, 200)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.BorderColor3 = Color3.fromRGB(60, 60, 80)
        btn.BorderSizePixel = 1
        btn.Image = "rbxassetid://18397244060" -- Config tab icon
        btn.ImageColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        
        -- Draggable functionality for mobile convenience
        local dragging, dragInput, dragStart, startPos
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = btn.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        btn.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        -- Tap / Click to toggle menu visibility
        btn.MouseButton1Click:Connect(function()
            if env.AreumUI then
                pcall(function()
                    env.AreumUI:Toggle()
                end)
            end
        end)
        
        mobileButtonGui = screenGui
    else
        if mobileButtonGui then
            mobileButtonGui:Destroy()
            mobileButtonGui = nil
        end
    end
end

-- Load Universal UI Module asynchronously
task.spawn(function()
    local success, err = pcall(function()
        local AreumUI = loadstring(game:HttpGet(UIModuleLink))()
        
        local Window = AreumUI:CreateWindow({
            Title = "Areum Hub",
            Theme = env.CURRENT_THEME,
            ToggleKey = env.UI_TOGGLE_KEY
        })
        env.AreumUI = Window

        local MainTab = Window:CreateTab("Main", "rbxassetid://12849292746")
        local WeaponsTab = Window:CreateTab("Weapons", "rbxassetid://7246622296")
        local ConfigTab = Window:CreateTab(" Settings", "rbxassetid://18397244060")

        -- Main Tab Controls
        MainTab:CreateSection("Test Tab1 ://")
       
        -- Weapons Tab Controls
        WeaponsTab:CreateSection("Test Tab2 ://")

        -- Config Tab Controls
        ConfigTab:CreateSection("Themes ://")
        ConfigTab:CreateDropdown({
            Name = "Theme",
            Items = {"Violet", "Xmas", "Ocean", "Crimson", "Light"},
            Default = env.CURRENT_THEME,
            Callback = function(selectedTheme)
                env.CURRENT_THEME = selectedTheme
                ConfigManager.Data.CurrentTheme = selectedTheme
                ConfigManager:Save()
                
                if typeof(env.CloseAreumHub) == "function" then
                    env.CloseAreumHub()
                end
                
                task.spawn(function()
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/UAV-STRIKE-Loader-Source.lua"))()
                    end)
                end)
            end
        })

        ConfigTab:CreateSection("Mobile Options ://")

        ConfigTab:CreateToggle({
            Name = "Mobile Button",
            Default = env.MOBILE_BUTTON,
            Callback = function(state)
                env.MOBILE_BUTTON = state
                ConfigManager.Data.MobileButton = state
                ConfigManager:Save()
                setupMobileButton(state)
            end
        })

        ConfigTab:CreateSection("Debug Library ://")

        ConfigTab:CreateToggle({
            Name = "Fetch Versions with GitHub",
            Default = env.FETCHVERSIONS,
            Callback = function(state)
                env.FETCHVERSIONS = state
                ConfigManager.Data.FetchVersions = state
                ConfigManager:Save()
            end
        })

        ConfigTab:CreateButton({
            Name = "Kill Loader (F1)",
            Callback = function()
                if typeof(env.CloseAreumHub) == "function" then
                    env.CloseAreumHub()
                end
            end
        })

        if env.MOBILE_BUTTON then
            setupMobileButton(true)
        end

        onupdate = function(newver: string)
            if update_shown then return end

            update_shown = true
            local UpdateTab = Window:CreateTab("Update!", "rbxassetid://4869184613")

            UpdateTab:CreateSection("Update News ://")

            UpdateTab:CreateToggle({
                Name = `New Version Detected | v.{newver}`,
                Default = useless_local,
                Callback = function(state)
                    useless_local = state
                end
            })

            UpdateTab:CreateButton({
                Name = "Load into New Version | v."..newver,
                Callback = function()
                    if typeof(env.CloseAreumHub) == "function" then
                        task.delay(1,function()
                            local result, err = pcall(function()
                                local AreumUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/UAV-STRIKE-Loader-Source.lua"))()
                            end)

                            if err then 
                                warn("[Areum Hub]: Error Received While loading |"..err)
                            end
                        end)
                        env.CloseAreumHub()
                    end
                end
            })

        end

    end)
    
    if not success then
        warn("[Areum Hub] Failed to load UI module: " .. tostring(err))
    end
end)

-- Game Automation References

local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local device_supported = UserInputService.KeyboardEnabled

task.spawn(function()

    while task.wait(30) do
        if env.FETCHVERSIONS then
            local GitHub_Version = loadstring(game:HttpGet(DataLibraryLink))()
            if GitHub_Version.Loaders.UAV_StrikeLoader.Lversion ~= Lversion then
                onupdate(GitHub_Version.Loaders.UAV_StrikeLoader.Lversion)
            end
        end
    end
    
end)

-- Main Automation Loop
task.spawn(function()
    while env.SCRIPT_ACTIVE and task.wait(0.01) do

    end
end)

-- Cleanup Routine
local function closeScriptRoutine()
    env.SCRIPT_ACTIVE = false
    env.AreumHubExecuted = false
    env.MOBILE_BUTTON = false
    env.FETCHVERSIONS = false
    
    setupMobileButton(false)
    
    if env.AreumUI then
        pcall(function() env.AreumUI:Destroy() end)
    end

end
env.CloseAreumHub = closeScriptRoutine

-- Termination Keybind Listener (F1)
local stopInputConn
stopInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == env.STOP_KEY then
        closeScriptRoutine()
        if stopInputConn then stopInputConn:Disconnect() end
    end
end)