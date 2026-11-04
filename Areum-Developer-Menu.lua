-- =========================================================================
-- AREUM HUB LOADER (Universal Debug Tool - Developer Edition)
-- =========================================================================
local Lversion = "DEV-NLY"
print(`[ Loader Version: v{Lversion} | Debug Menu ]`)

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
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

if player.DisplayName ~= "Areum" and player.DisplayName ~= "AreumTheBest" then
    warn("[Areum Hub] Only people with display name 'AreumTheBest' can use this loader!")
    env.AreumHubExecuted = false
    return
end

-- =========================================================================
-- CONFIGURATION MANAGER (Crash-Proof Mobile JSON Workspace Saving)
-- =========================================================================
local CONFIG_FILE = "AreumHub_Debug.json"

local ConfigManager = {
    Data = {
        CurrentTheme = "Violet",
        ToggleKey = "LeftControl",
        MobileButton = false,
        FetchVersions = false,
        CustomAssetURL = "",
        DebugSliderVal = 50,
        DebugInputText = "",
        InfoDisplay = "Debug"
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

ConfigManager:Load()

-- Environment Configuration Defaults
env.SCRIPT_ACTIVE = true
env.UI_TOGGLE_KEY = Enum.KeyCode[ConfigManager.Data.ToggleKey] or Enum.KeyCode.LeftControl
env.STOP_KEY = Enum.KeyCode.F1

env.CURRENT_THEME = ConfigManager.Data.CurrentTheme
env.MOBILE_BUTTON = ConfigManager.Data.MobileButton
env.FETCHVERSIONS = ConfigManager.Data.FetchVersions

local useless_local = false
local update_shown = false

local UIModuleLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/Areum-UI-Library-V3.lua"
local DataLibraryLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/refs/heads/main/Areum-Data-Configs.lua"
local LoaderLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/Areum-Developer-Menu.lua"

local mobileButtonGui = nil

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
        btn.Image = "rbxassetid://18397244060"
        btn.ImageColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        
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

-- Load Universal UI Module asynchronously with all new UI components
task.spawn(function()
    local success, err = pcall(function()
        local AreumUI = loadstring(game:HttpGet(UIModuleLink))()
        
        local Window = AreumUI:CreateWindow({
            Title = "Debug Menu",
            Theme = env.CURRENT_THEME,
            ToggleKey = env.UI_TOGGLE_KEY,
            CustomBackground = ConfigManager.Data.CustomAssetURL
        })
        env.AreumUI = Window

        local ToolsTab = Window:CreateTab("Tools", "rbxassetid://8772194322")
        local ConfigTab = Window:CreateTab("Settings", "rbxassetid://18397244060")
        
        -- Tools Tab Components
        ToolsTab:CreateSection("Debug Operations ://")

        ToolsTab:CreateButton({
            Name = "Test Button A1",
            Callback = function()
                print("[Debug Tool]: Button A1 Pressed")
            end
        })

        ToolsTab:CreateSlider({
            Name = "Test Value Slider A2",
            Min = 1,
            Max = 1234,
            Default = ConfigManager.Data.DebugSliderVal,
            Callback = function(val)
                ConfigManager.Data.DebugSliderVal = val
                ConfigManager:Save()
            end
        })

        ToolsTab:CreateTextBox({
            Name = "Test Input A3",
            Placeholder = "Type code or arguments...",
            Default = ConfigManager.Data.DebugInputText,
            Callback = function(txt)
                ConfigManager.Data.DebugInputText = txt
                ConfigManager:Save()
                print("[Debug Tool Input]: " .. txt)
            end
        })

        ToolsTab:CreateInfoBox({
            Name = "Test Info Display A4",
            Text = ConfigManager.Data.InfoDisplay
        })

        -- Settings Tab Components
        ConfigTab:CreateSection("Theme Customization ://")
        
        ConfigTab:CreateDropdown({
            Name = "Theme Selector",
            Items = {"Violet", "Xmas", "Ocean", "Crimson", "Noise","Sakura","Void"},
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
                        loadstring(game:HttpGet(LoaderLink))()
                    end)
                end)
            end
        })

        ConfigTab:CreateTextBox({
            Name = "Custom Background URL",
            Placeholder = "rbxassetid://...",
            Default = ConfigManager.Data.CustomAssetURL,
            Callback = function(assetId)
                ConfigManager.Data.CustomAssetURL = assetId
                ConfigManager:Save()

                Window:UpdateBackground(assetId)
            end
        })

        ConfigTab:CreateSection("Mobile Toggles ://")

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

        ConfigTab:CreateSection("System Controls ://")

        -- Separate System Button (Red Warning Accent)
        ConfigTab:CreateSystemButton({
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
                            pcall(function()
                                loadstring(game:HttpGet(LoaderLink))()
                            end)
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

-- Version Sync Loop
task.spawn(function()
    while task.wait(15) do
        if env.FETCHVERSIONS then
            local success, GitHub_Version = pcall(function()
                return loadstring(game:HttpGet(DataLibraryLink))()
            end)
            if success and GitHub_Version and GitHub_Version.Loaders.UAV_StrikeLoader.Lversion ~= Lversion then
                onupdate(GitHub_Version.Loaders.UAV_StrikeLoader.Lversion)
            end
        end
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