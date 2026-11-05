-- =========================================================================
-- AREUM HUB LOADER (Universal Debug Tool - Developer Edition)
-- =========================================================================
local Lversion = "1.012.2"
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
local Camera = workspace.CurrentCamera

if player.DisplayName ~= "Areum" and player.DisplayName ~= "AreumTheBest" then
    warn("[Areum Hub] Only people with display name 'AreumTheBest' can use this loader!")
    env.AreumHubExecuted = false
    return
end

local HasDrawing = (typeof(Drawing) == "table" and rawget(Drawing, "new") ~= nil) or (typeof(Drawing) == "userdata" or typeof(Drawing) == "function")

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

    }
}

local GameLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    GlobalShadows = Lighting.GlobalShadows,
    ClockTime = Lighting.ClockTime,
    Atmopshere = {
        Density = Lighting.Atmosphere.Density,
        Offset = Lighting.Atmosphere.Offset,
    };
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

env.SPEEDMODIFIFICATIONS = false
env.JUMPMODIFICATIONS = false
env.INFJUMP = false
env.PLAYERESP = false
env.TRACES = false
env.DISABLE3DRENDERING = false
env.FULLBRIGHT = false

env.SPEEDVALUE = 0
env.JUMPVALUE = 0

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
        ToolsTab:CreateSection("External Tools ://")

        ToolsTab:CreateButton({
            Name = "Execute Dex Explorer++",
            Callback = function()
                local success, err = pcall(function()
                    loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))() 
                end)

                if err then
                    warn("[Areum Hub] Failed to load Dex Explorer++: " .. tostring(err))
                end
            end
        })

        ToolsTab:CreateButton({
            Name = "Execute Cobalt UI",
            Callback = function()
                local success, err = pcall(function()
                    loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))()
                end)

                if err then
                    warn("[Areum Hub] Failed to load Cobalt UI: " .. tostring(err))
                end
            end
        })

        ToolsTab:CreateSection("Universal Scripts ://")

        ToolsTab:CreateButton({
            Name = "Execute Infinite Yield",
            Callback = function()
                local success, err = pcall(function()
                    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
                end)

                if err then
                    warn("[Areum Hub] Failed to load Infinite Yield: " .. tostring(err))
                end
            end
        })

        ToolsTab:CreateButton({
            Name = "Execute Void UI (WASOR)",
            Callback = function()
                local success, err = pcall(function()
                    if identifyexecutor or printidentity then
                        game:GetService("GuiService"):SetGameplayPausedNotificationEnabled(false)
                        loadstring(game:HttpGet(('https://raw.githubusercontent.com/MizunoSync/WASOR/refs/heads/main/github_loader.lua'),true))()
                    end
                end)

                if err then
                    warn("[Areum Hub] Failed to load Void UI (WASOR): " .. tostring(err))
                end
            end
        })

        ToolsTab:CreateButton({
            Name = "Execute Dropkick Script",
            Callback = function()
                local success, err = pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/gsm231/Fe-DropKick/refs/heads/main/V0.1"))()
                end)

                if err then
                    warn("[Areum Hub] Failed to load Dropkick Script: " .. tostring(err))
                end
            end
        })

        ToolsTab:CreateSection("Management ://")

        ToolsTab:CreateSystemButton({
            Name = "Load Developer Pack [ Dex++ | Cobalt | Inf Yield ]",
            Callback = function()
                local success, err = pcall(function()
                    loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))() 
                end)

                if err then
                    warn("[Areum Hub] Failed to load Dex Explorer++: " .. tostring(err))
                end

                local success, err = pcall(function()
                    loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))()
                end)

                if err then
                    warn("[Areum Hub] Failed to load Cobalt UI: " .. tostring(err))
                end

                local success, err = pcall(function()
                    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
                end)

                if err then
                    warn("[Areum Hub] Failed to load Infinite Yield: " .. tostring(err))
                end
            end
        })

         ToolsTab:CreateSystemButton({
            Name = "Install Universal Module [Areum-Hub]",
            Callback = function()
                
                local PlayerTab = Window:CreateTab("Player", "rbxassetid://17769995325")
                local VisualsTab = Window:CreateTab("Visuals", "rbxassetid://136474990712998")

                PlayerTab:CreateSection("Character Settings ://")

                PlayerTab:CreateToggle({
                    Name = "Walkspeed Modifications",
                    Default = false,
                    Callback = function(state)
                        env.SPEEDMODIFIFICATIONS = state
                    end
                })

                PlayerTab:CreateSlider({
                    Name = "Set Walkspeed to",
                    Min = 0,
                    Max = 200,
                    Default = 16,
                    Callback = function(value)
                        env.SPEEDVALUE = value
                    end
                })

                PlayerTab:CreateToggle({
                    Name = "Jump Power Modifications",
                    Default = false,
                    Callback = function(state)
                        env.JUMPMODIFICATIONS = state
                    end
                })

                PlayerTab:CreateSlider({
                    Name = "Set JumpPower to",
                    Min = 0,
                    Max = 300,
                    Default = 50,
                    Callback = function(value)
                        env.JUMPVALUE = value
                    end
                })

                 PlayerTab:CreateToggle({
                    Name = "Infinite Jump",
                    Default = false,
                    Callback = function(state)
                        env.INFJUMP = state
                    end
                })

                PlayerTab:CreateButton({
                    Name = "Reset Character",
                    Callback = function()
                        local character = player.Character
                        if character then
                            character:BreakJoints()
                        end
                    end
                })

                VisualsTab:CreateSection("Visual Settings ://")

                VisualsTab:CreateToggle({
                    Name = "Player ESP",
                    Default = env.PLAYERESP,
                    Callback = function(state)
                        env.PLAYERESP = state
                    end
                })

                VisualsTab:CreateToggle({
                    Name = "Traces",
                    Default = env.TRACES,
                    Callback = function(state)
                        env.TRACES = state
                    end
                })

                VisualsTab:CreateSection("Rendering ://")

                VisualsTab:CreateToggle({
                    Name = "Disable 3D Rendering",
                    Default = env.DISABLE3DRENDERING,
                    Callback = function(state)
                        env.DISABLE3DRENDERING = state
                    end
                })

                VisualsTab:CreateToggle({
                    Name = "Fullbright",
                    Default = env.FULLBRIGHT,
                    Callback = function(state)
                        env.FULLBRIGHT = state
                    end
                })

            end
        })

        -- Settings Tab Components
        ConfigTab:CreateSection("Theme Customization ://")
        
        ConfigTab:CreateDropdown({
            Name = "Theme Selector",
            Items = {"Violet", "AreumCoolTheme", "Xmas", "Ocean", "Crimson", "Noise","Sakura","Void"},
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

local ActivePlayerEsps = {}
local ActivePlayerTracers = {}

local lastSpeedValue = 0
local lastJumpValue = 0

local function InitESP(targetPlayer: Player)
    if targetPlayer == player then return end

    local function setupCharacter(character)
        if ActivePlayerEsps[targetPlayer.Name] then
            pcall(function() ActivePlayerEsps[targetPlayer.Name]:Destroy() end)
        end

        local highlight = Instance.new("Highlight")
        highlight.Parent = character
        highlight.FillColor = Color3.fromRGB(22, 137, 172)
        highlight.FillTransparency = 0.75
        highlight.OutlineColor = Color3.fromRGB(28, 184, 231)
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = false

        ActivePlayerEsps[targetPlayer.Name] = highlight
    end

    if targetPlayer.Character then
        setupCharacter(targetPlayer.Character)
    end

    targetPlayer.CharacterAdded:Connect(function(character)
        setupCharacter(character)
    end)

    if HasDrawing and not ActivePlayerTracers[targetPlayer.Name] then
        pcall(function()
            local tracer = Drawing.new("Line")
            tracer.Visible = false
            tracer.Color = Color3.fromRGB(28, 184, 231)
            tracer.Thickness = 1.5
            tracer.Transparency = 0.8
            ActivePlayerTracers[targetPlayer.Name] = tracer
        end)
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    InitESP(p)
end

Players.PlayerAdded:Connect(function(p)
    InitESP(p)
end)

Players.PlayerRemoving:Connect(function(p)
    if ActivePlayerEsps[p.Name] then
        pcall(function() ActivePlayerEsps[p.Name]:Destroy() end)
        ActivePlayerEsps[p.Name] = nil
    end
    if ActivePlayerTracers[p.Name] then
        pcall(function() ActivePlayerTracers[p.Name]:Remove() end)
        ActivePlayerTracers[p.Name] = nil
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

task.spawn(function()
    while task.wait() and env.SCRIPT_ACTIVE do

        if env.FULLBRIGHT then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 5
            Lighting.GlobalShadows = false
            Lighting.ClockTime = 12

            if Lighting:FindFirstChildWhichIsA("Atmosphere") then
                Lighting.Atmosphere.Density = 0
                Lighting.Atmosphere.Offset = 0
            end

        else
            Lighting.Ambient = GameLighting.Ambient
            Lighting.Brightness = GameLighting.Brightness
            Lighting.GlobalShadows = GameLighting.GlobalShadows
            Lighting.ClockTime = GameLighting.ClockTime

            if Lighting:FindFirstChildWhichIsA("Atmosphere") then
                Lighting.Atmosphere.Density = GameLighting.Atmopshere.Density
                Lighting.Atmosphere.Offset = GameLighting.Atmopshere.Offset
            end
        end
        
        if env.SPEEDMODIFIFICATIONS and env.SCRIPT_ACTIVE then
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") then
                if lastSpeedValue ~= env.SPEEDVALUE then
                    character.Humanoid.WalkSpeed = env.SPEEDVALUE
                    lastSpeedValue = env.SPEEDVALUE
                end
            end
        end

        if env.JUMPMODIFIFICATIONS and env.SCRIPT_ACTIVE then
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") then
                if lastJumpValue ~= env.JUMPVALUE then
                    character.Humanoid.JumpPower = env.JUMPVALUE
                    lastJumpValue = env.JUMPVALUE
                end
            end
        end

        if env.INFJUMP and env.SCRIPT_ACTIVE then
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") then
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end

        for name, esp in pairs(ActivePlayerEsps) do
            local p = Players:FindFirstChild(name)
            local shouldShow = env.PLAYERESP and p and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0
            if esp then
                esp.Enabled = shouldShow
            end
        end

        if HasDrawing and env.SCRIPT_ACTIVE then
            for name, tracer in pairs(ActivePlayerTracers) do
                local p = Players:FindFirstChild(name)
                local shouldShow = false

                if env.TRACES and p and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChild("Humanoid")

                    if hrp and hum and hum.Health > 0 then
                        local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            tracer.To = Vector2.new(vector.X, vector.Y)
                            tracer.Visible = true
                            shouldShow = true
                        end
                    end
                end

            if not shouldShow and tracer then
                tracer.Visible = false
            end
        end

        RunService:Set3dRenderingEnabled(not env.DISABLE3DRENDERING)
        end
    end
end)

-- Cleanup Routine
local function closeScriptRoutine()
    env.SCRIPT_ACTIVE = false
    env.AreumHubExecuted = false
    env.MOBILE_BUTTON = false
    env.FETCHVERSIONS = false

    env.SPEEDMODIFIFICATIONS = false
    env.JUMPMODIFICATIONS = false

    env.INFJUMP = false
    env.PLAYERESP = false
    env.TRACES = false
    env.DISABLE3DRENDERING = false

    Lighting.Ambient = GameLighting.Ambient
    Lighting.Brightness = GameLighting.Brightness
    Lighting.GlobalShadows = GameLighting.GlobalShadows
    Lighting.ClockTime = GameLighting.ClockTime

    if Lighting:FindFirstChildWhichIsA("Atmosphere") then
         Lighting.Atmosphere.Density = GameLighting.Atmopshere.Density
         Lighting.Atmosphere.Offset = GameLighting.Atmopshere.Offset
    end

    for _, esp in pairs(ActivePlayerEsps) do
        pcall(function() esp:Destroy() end)
    end
    ActivePlayerEsps = {}

    for _, tracer in pairs(ActivePlayerTracers) do
        pcall(function() tracer:Remove() end)
    end
    ActivePlayerTracers = {}

    RunService:Set3dRenderingEnabled(true)

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