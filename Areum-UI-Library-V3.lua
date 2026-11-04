-- =========================================================================
-- AREUM UI LIBRARY (Debug Tool - Private Version v3.007.0)
-- =========================================================================
print("[ UI Library Version: 3.007.1 | Supports Loader Versions From 3.000.0 ]")

local AreumUI = {}
AreumUI.__index = AreumUI

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- Global Themes Palette
local Themes = {
    Violet = {
        BackgroundGradient = {Color3.fromRGB(18, 10, 26), Color3.fromRGB(8, 6, 12)},
        Sidebar = Color3.fromRGB(7, 7, 7),
        Row = Color3.fromRGB(18, 18, 18),
        Stroke = Color3.fromRGB(24, 0, 34),
        Accent = Color3.fromRGB(118, 0, 214),
        TextMuted = Color3.fromRGB(150, 150, 150),
        BackgroundImage = "rbxassetid://14731252126"
    },
    Xmas = {
        BackgroundGradient = {Color3.fromRGB(2, 35, 2), Color3.fromRGB(1, 15, 1)},
        Sidebar = Color3.fromRGB(45, 0, 0),
        Row = Color3.fromRGB(45, 0, 0),
        Stroke = Color3.fromRGB(64, 87, 0),
        Accent = Color3.fromRGB(27, 216, 2),
        TextMuted = Color3.fromRGB(2, 114, 11),
        BackgroundImage = "rbxassetid://15769220526"
    },
    Ocean = {
        BackgroundGradient = {Color3.fromRGB(12, 22, 36), Color3.fromRGB(5, 9, 14)},
        Sidebar = Color3.fromRGB(6, 9, 14),
        Row = Color3.fromRGB(16, 22, 32),
        Stroke = Color3.fromRGB(28, 42, 64),
        Accent = Color3.fromRGB(60, 160, 255),
        TextMuted = Color3.fromRGB(140, 165, 200),
        BackgroundImage = "rbxassetid://9544622638"
    },
    Crimson = {
        BackgroundGradient = {Color3.fromRGB(28, 12, 12), Color3.fromRGB(10, 5, 5)},
        Sidebar = Color3.fromRGB(10, 6, 6),
        Row = Color3.fromRGB(26, 16, 16),
        Stroke = Color3.fromRGB(52, 28, 28),
        Accent = Color3.fromRGB(255, 85, 85),
        TextMuted = Color3.fromRGB(200, 150, 150),
        BackgroundImage = "rbxassetid://92523071261344"
    },
    Noise = {
        BackgroundGradient = {Color3.fromRGB(250, 250, 250), Color3.fromRGB(168, 168, 168)},
        Sidebar = Color3.fromRGB(199, 199, 199),
        Row = Color3.fromRGB(146, 146, 146),
        Stroke = Color3.fromRGB(5, 5, 5),
        Accent = Color3.fromRGB(102, 102, 102),
        TextMuted = Color3.fromRGB(68, 68, 68),
        BackgroundImage = "rbxassetid://79071105946443"
    },
    Sakura = {
        BackgroundGradient = {Color3.fromRGB(255, 114, 255), Color3.fromRGB(253, 202, 255)},
        Sidebar = Color3.fromRGB(182, 101, 182),
        Row = Color3.fromRGB(143, 38, 38),
        Stroke = Color3.fromRGB(197, 70, 70),
        Accent = Color3.fromRGB(255, 197, 236),
        TextMuted = Color3.fromRGB(158, 120, 153),
        BackgroundImage = "rbxassetid://17070917034"
    },
    Void = {
        BackgroundGradient = {Color3.fromRGB(17, 17, 17), Color3.fromRGB(0, 0, 0)},
        Sidebar = Color3.fromRGB(8, 8, 8),
        Row = Color3.fromRGB(12, 12, 12),
        Stroke = Color3.fromRGB(8, 8, 8),
        Accent = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(168, 168, 168),
        BackgroundImage = "rbxassetid://14731252126"
    },
}

-- Helper function to format input IDs cleanly into valid rbxassetids
local function formatAssetId(input)
    if not input or input == "" then return "" end
    input = tostring(input):gsub("%s+", "")
    if tonumber(input) then
        return "rbxassetid://" .. input
    elseif not input:find("rbxassetid://") then
        return "rbxassetid://" .. input:match("%d+")
    end
    return input
end

-- 1. Library Initialization (CreateWindow)
function AreumUI:CreateWindow(config)
    config = config or {}
    local window = setmetatable({}, AreumUI)
    
    window.TitleText = config.Title or "Areum Hub"
    window.CurrentThemeName = config.Theme or "Violet"
    window.ToggleKey = config.ToggleKey or Enum.KeyCode.LeftControl
    window.ThemeData = Themes[window.CurrentThemeName] or Themes.Violet
    
    local initialBg = window.ThemeData.BackgroundImage
    if config.CustomBackground and config.CustomBackground ~= "" then
        initialBg = formatAssetId(config.CustomBackground)
    end

    window.Pages = {}
    window.TabButtons = {}
    window.ActiveTab = nil
    window.Connections = {}

    local targetParent = CoreGui
    pcall(function()
        if typeof(gethui) == "function" then
            targetParent = gethui()
        end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AreumHub_Universal"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ClipToDeviceSafeArea = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 9999999
    ScreenGui.Parent = targetParent
    window.ScreenGui = ScreenGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 580, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -290, 0.5, -200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = ScreenGui
    window.MainFrame = MainFrame

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1.5
    MainStroke.Color = window.ThemeData.Stroke
    MainStroke.Parent = MainFrame

    -- Background 2-Color Gradient Support
    local BgGradient = Instance.new("UIGradient")
    BgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, window.ThemeData.BackgroundGradient[1]),
        ColorSequenceKeypoint.new(1, window.ThemeData.BackgroundGradient[2])
    })
    BgGradient.Rotation = 45
    BgGradient.Parent = MainFrame

    -- Background Image Layer with Slight Dark Tint (Color3.fromRGB(120, 120, 120))
    local BgImage = Instance.new("ImageLabel")
    BgImage.Name = "BackgroundImage"
    BgImage.Size = UDim2.new(1, 0, 1, 0)
    BgImage.BackgroundTransparency = 1
    BgImage.ScaleType = Enum.ScaleType.Stretch
    BgImage.ImageTransparency = 0.15
    BgImage.ImageColor3 = Color3.fromRGB(200,200,200)
    BgImage.Parent = MainFrame
    window.BgImage = BgImage

    local ImageCorner = Instance.new("UICorner")
    ImageCorner.CornerRadius = UDim.new(0, 12)
    ImageCorner.Parent = BgImage

    -- Function to safely load and instantly update background anywhere
    function window:UpdateBackground(assetInput)
        local formatted = formatAssetId(assetInput)
        if formatted == "" then
            formatted = window.ThemeData.BackgroundImage
        end
        
        BgImage.Image = formatted
    end

    window:UpdateBackground(initialBg)

    -- Custom Smooth Dragging (Supports Touch & Mouse)
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    table.insert(window.Connections, RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    -- Sidebar Setup 
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundColor3 = window.ThemeData.Sidebar
    Sidebar.BackgroundTransparency = 0.75
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 12)
    SidebarCorner.Parent = Sidebar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, -16, 0, 60)
    TitleLabel.Position = UDim2.new(0, 16, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.RichText = true
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 22
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Sidebar

    local r, g, b = math.floor(window.ThemeData.Accent.R * 255), math.floor(window.ThemeData.Accent.G * 255), math.floor(window.ThemeData.Accent.B * 255)
    TitleLabel.Text = string.format([[<font color="rgb(%d,%d,%d)"><b>Areum</b></font> <font color="rgb(255,255,255)" size="16">Hub</font>]], r, g, b)

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -16, 1, -85)
    TabContainer.Position = UDim2.new(0, 8, 0, 75)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = Sidebar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.Parent = TabContainer
    window.TabContainer = TabContainer

    -- Content Frame
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -170, 1, -24)
    ContentFrame.Position = UDim2.new(0, 165, 0, 12)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    window.ContentFrame = ContentFrame

    table.insert(window.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == window.ToggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end))

    return window
end

function AreumUI:Toggle()
    if self.MainFrame then
        self.MainFrame.Visible = not self.MainFrame.Visible
    end
end

-- 2. Tab Creation (CreateTab)
function AreumUI:CreateTab(name, iconAssetId)
    local tab = {}
    tab.Window = self
    tab.Name = name

    local Page = Instance.new("ScrollingFrame")
    Page.Name = name .. "Page"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
    Page.Visible = false
    Page.Parent = self.ContentFrame
    tab.Page = Page

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    PageLayout.Padding = UDim.new(0, 8)
    PageLayout.Parent = Page

    local Btn = Instance.new("TextButton")
    Btn.Name = name .. "TabBtn"
    Btn.Size = UDim2.new(1, -12, 0, 40)
    Btn.Position = UDim2.new(0, 6, 0, 0)
    Btn.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    Btn.BackgroundTransparency = 0.45
    Btn.Text = "          " .. name
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 14
    Btn.TextColor3 = self.ThemeData.TextMuted
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = self.TabContainer

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Btn

    if iconAssetId then
        local Icon = Instance.new("ImageLabel")
        Icon.Name = "Icon"
        Icon.Size = UDim2.new(0, 18, 0, 18)
        Icon.Position = UDim2.new(0, 12, 0.5, -9)
        Icon.BackgroundTransparency = 1
        Icon.Image = iconAssetId
        Icon.ImageColor3 = self.ThemeData.TextMuted
        Icon.Parent = Btn
    end

    Btn.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    self.Pages[name] = Page
    self.TabButtons[name] = Btn

    if not self.ActiveTab then
        self:SelectTab(name)
    end

    setmetatable(tab, {__index = AreumUI})
    return tab
end

function AreumUI:SelectTab(name)
    self.ActiveTab = name
    for pageName, pageFrame in pairs(self.Pages) do
        pageFrame.Visible = (pageName == name)
    end
    for btnName, btn in pairs(self.TabButtons) do
        local icon = btn:FindFirstChild("Icon")
        if btnName == name then
            btn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
            btn.BackgroundTransparency = 0.45
            btn.TextColor3 = self.ThemeData.Accent
            if icon then icon.ImageColor3 = self.ThemeData.Accent end
        else
            btn.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
            btn.BackgroundTransparency = 0.45
            btn.TextColor3 = self.ThemeData.TextMuted
            if icon then icon.ImageColor3 = self.ThemeData.TextMuted end
        end
    end
end

-- 3. Section Creation
function AreumUI:CreateSection(titleText)
    local SectionLabel = Instance.new("TextLabel")
    SectionLabel.Size = UDim2.new(1, -24, 0, 24)
    SectionLabel.Position = UDim2.new(0, 6, 0, 0)
    SectionLabel.BackgroundTransparency = 1
    SectionLabel.Text = titleText:upper()
    SectionLabel.Font = Enum.Font.GothamMedium
    SectionLabel.TextSize = 13
    SectionLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    SectionLabel.Parent = self.Page
end

-- 4. Components Implementation
function AreumUI:CreateToggle(options)
    options = options or {}
    local name = options.Name or "Toggle"
    local state = options.Default or false
    local callback = options.Callback or function() end

    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 46)
    Row.BackgroundColor3 = self.Window.ThemeData.Row
    Row.BackgroundTransparency = 0.45
    Row.Parent = self.Page

    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = Row

    local RowStroke = Instance.new("UIStroke")
    RowStroke.Thickness = 1
    RowStroke.Color = self.Window.ThemeData.Stroke
    RowStroke.Parent = Row

    local RowText = Instance.new("TextLabel")
    RowText.Size = UDim2.new(0.6, 0, 1, 0)
    RowText.Position = UDim2.new(0, 14, 0, 0)
    RowText.BackgroundTransparency = 1
    RowText.Text = name
    RowText.Font = Enum.Font.GothamMedium
    RowText.TextSize = 14
    RowText.TextColor3 = Color3.fromRGB(220, 220, 220)
    RowText.TextXAlignment = Enum.TextXAlignment.Left
    RowText.Parent = Row

    local SwitchBG = Instance.new("TextButton")
    SwitchBG.Size = UDim2.new(0, 44, 0, 24)
    SwitchBG.Position = UDim2.new(1, -14, 0.5, -12)
    SwitchBG.AnchorPoint = Vector2.new(1, 0)
    SwitchBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SwitchBG.BackgroundTransparency = 0.45
    SwitchBG.Text = ""
    SwitchBG.Parent = Row

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBG

    local SwitchBall = Instance.new("Frame")
    SwitchBall.Size = UDim2.new(0, 18, 0, 18)
    SwitchBall.Position = UDim2.new(0, 3, 0.5, -9)
    SwitchBall.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    SwitchBall.BackgroundTransparency = 0.45
    SwitchBall.Parent = SwitchBG

    local BallCorner = Instance.new("UICorner")
    BallCorner.CornerRadius = UDim.new(1, 0)
    BallCorner.Parent = SwitchBall

    local function updateVisuals()
        if state then
            TweenService:Create(SwitchBall, TweenInfo.new(0.18), {Position = UDim2.new(1, -21, 0.5, -9), BackgroundColor3 = Color3.fromRGB(12, 12, 12)}):Play()
            TweenService:Create(SwitchBG, TweenInfo.new(0.18), {BackgroundColor3 = self.Window.ThemeData.Accent}):Play()
        else
            TweenService:Create(SwitchBall, TweenInfo.new(0.18), {Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.fromRGB(180, 180, 180)}):Play()
            TweenService:Create(SwitchBG, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
        end
    end

    SwitchBG.MouseButton1Click:Connect(function()
        state = not state
        updateVisuals()
        pcall(callback, state)
    end)

    updateVisuals()
end

function AreumUI:CreateButton(options)
    options = options or {}
    local name = options.Name or "Button"
    local callback = options.Callback or function() end

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -24, 0, 40)
    Btn.BackgroundColor3 = self.Window.ThemeData.Row
    Btn.BackgroundTransparency = 0.45
    Btn.Text = name
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 13
    Btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    Btn.Parent = self.Page

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Btn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Thickness = 1
    BtnStroke.Color = self.Window.ThemeData.Stroke
    BtnStroke.Parent = Btn

    Btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
end

function AreumUI:CreateSystemButton(options)
    options = options or {}
    local name = options.Name or "System Action"
    local callback = options.Callback or function() end

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -24, 0, 40)
    Btn.BackgroundColor3 = Color3.fromRGB(24, 12, 12)
    Btn.BackgroundTransparency = 0.45
    Btn.Text = name
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 13
    Btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    Btn.Parent = self.Page

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Btn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Thickness = 1
    BtnStroke.Color = Color3.fromRGB(60, 25, 25)
    BtnStroke.Parent = Btn

    Btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
end

function AreumUI:CreateTextBox(options)
    options = options or {}
    local name = options.Name or "TextBox"
    local placeholder = options.Placeholder or "Enter text..."
    local defaultText = options.Default or ""
    local callback = options.Callback or function() end

    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 50)
    Row.BackgroundColor3 = self.Window.ThemeData.Row
    Row.BackgroundTransparency = 0.45
    Row.Parent = self.Page

    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = Row

    local RowStroke = Instance.new("UIStroke")
    RowStroke.Thickness = 1
    RowStroke.Color = self.Window.ThemeData.Stroke
    RowStroke.Parent = Row

    local RowText = Instance.new("TextLabel")
    RowText.Size = UDim2.new(0.45, 0, 1, 0)
    RowText.Position = UDim2.new(0, 14, 0, 0)
    RowText.BackgroundTransparency = 1
    RowText.Text = name
    RowText.Font = Enum.Font.GothamMedium
    RowText.TextSize = 13
    RowText.TextColor3 = Color3.fromRGB(220, 220, 220)
    RowText.TextXAlignment = Enum.TextXAlignment.Left
    RowText.Parent = Row

    local BoxInput = Instance.new("TextBox")
    BoxInput.Size = UDim2.new(0, 150, 0, 30)
    BoxInput.Position = UDim2.new(1, -14, 0.5, -15)
    BoxInput.AnchorPoint = Vector2.new(1, 0)
    BoxInput.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    BoxInput.BackgroundTransparency = 0.45
    BoxInput.Text = defaultText
    BoxInput.PlaceholderText = placeholder
    BoxInput.Font = Enum.Font.GothamMedium
    BoxInput.TextSize = 12
    BoxInput.TextColor3 = Color3.fromRGB(240, 240, 240)
    BoxInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    BoxInput.ClearTextOnFocus = false
    BoxInput.Parent = Row

    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 6)
    BoxCorner.Parent = BoxInput

    BoxInput.FocusLost:Connect(function(enterPressed)
        pcall(callback, BoxInput.Text)
        if name:lower().match("background") or name:lower().match("url") or name:lower().match("asset") then
            self:UpdateBackground(BoxInput.Text)
        end
    end)
end

function AreumUI:CreateSlider(options)
    options = options or {}
    local name = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local callback = options.Callback or function() end

    local currentValue = math.clamp(default, min, max)

    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 56)
    Row.BackgroundColor3 = self.Window.ThemeData.Row
    Row.BackgroundTransparency = 0.45
    Row.Parent = self.Page

    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = Row

    local RowStroke = Instance.new("UIStroke")
    RowStroke.Thickness = 1
    RowStroke.Color = self.Window.ThemeData.Stroke
    RowStroke.Parent = Row

    local RowText = Instance.new("TextLabel")
    RowText.Size = UDim2.new(0.6, 0, 0, 26)
    RowText.Position = UDim2.new(0, 14, 0, 4)
    RowText.BackgroundTransparency = 1
    RowText.Text = name
    RowText.Font = Enum.Font.GothamMedium
    RowText.TextSize = 13
    RowText.TextColor3 = Color3.fromRGB(220, 220, 220)
    RowText.TextXAlignment = Enum.TextXAlignment.Left
    RowText.Parent = Row

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0.4, -28, 0, 26)
    ValueLabel.Position = UDim2.new(1, -14, 0, 4)
    ValueLabel.AnchorPoint = Vector2.new(1, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(currentValue)
    ValueLabel.Font = Enum.Font.GothamMedium
    ValueLabel.TextSize = 13
    ValueLabel.TextColor3 = self.Window.ThemeData.Accent
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Row

    local SliderBar = Instance.new("TextButton")
    SliderBar.Size = UDim2.new(1, -28, 0, 8)
    SliderBar.Position = UDim2.new(0, 14, 0, 36)
    SliderBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SliderBar.BackgroundTransparency = 0.45
    SliderBar.AutoButtonColor = false
    SliderBar.Text = ""
    SliderBar.Parent = Row

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = SliderBar

    local FillBar = Instance.new("Frame")
    FillBar.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
    FillBar.BackgroundColor3 = self.Window.ThemeData.Accent
    FillBar.BackgroundTransparency = 0.45
    FillBar.BorderSizePixel = 0
    FillBar.Parent = SliderBar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = FillBar

    local dragging = false
    local function updateValue(input)
        local sizeX = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        currentValue = math.floor(min + ((max - min) * sizeX))
        FillBar.Size = UDim2.new(sizeX, 0, 1, 0)
        ValueLabel.Text = tostring(currentValue)
        pcall(callback, currentValue)
    end

    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateValue(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)
end

function AreumUI:CreateInfoBox(options)
    options = options or {}
    local name = options.Name or "Info"
    local infoText = options.Text or "Information"

    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 42)
    Row.BackgroundColor3 = self.Window.ThemeData.Row
    Row.BackgroundTransparency = 0.45
    Row.Parent = self.Page

    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = Row

    local RowStroke = Instance.new("UIStroke")
    RowStroke.Thickness = 1
    RowStroke.Color = self.Window.ThemeData.Stroke
    RowStroke.Parent = Row

    local RowText = Instance.new("TextLabel")
    RowText.Size = UDim2.new(0.5, 0, 1, 0)
    RowText.Position = UDim2.new(0, 14, 0, 0)
    RowText.BackgroundTransparency = 1
    RowText.Text = name
    RowText.Font = Enum.Font.GothamMedium
    RowText.TextSize = 13
    RowText.TextColor3 = Color3.fromRGB(200, 200, 200)
    RowText.TextXAlignment = Enum.TextXAlignment.Left
    RowText.Parent = Row

    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(0.5, -14, 1, 0)
    InfoLabel.Position = UDim2.new(1, -14, 0, 0)
    InfoLabel.AnchorPoint = Vector2.new(1, 0)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = infoText
    InfoLabel.Font = Enum.Font.GothamMedium
    InfoLabel.TextSize = 12
    InfoLabel.TextColor3 = self.Window.ThemeData.TextMuted
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Right
    InfoLabel.Parent = Row
end

function AreumUI:CreateDropdown(options)
    options = options or {}
    local name = options.Name or "Dropdown"
    local items = options.Items or {}
    local defaultItem = options.Default or items[1] or ""
    local callback = options.Callback or function() end

    local ThemeRow = Instance.new("Frame")
    ThemeRow.Size = UDim2.new(1, -24, 0, 46)
    ThemeRow.BackgroundColor3 = self.Window.ThemeData.Row
    ThemeRow.BackgroundTransparency = 0.45
    ThemeRow.ClipsDescendants = false
    ThemeRow.ZIndex = 2
    ThemeRow.Parent = self.Page

    local ThemeRowCorner = Instance.new("UICorner")
    ThemeRowCorner.CornerRadius = UDim.new(0, 8)
    ThemeRowCorner.Parent = ThemeRow

    local ThemeRowStroke = Instance.new("UIStroke")
    ThemeRowStroke.Thickness = 1
    ThemeRowStroke.Color = self.Window.ThemeData.Stroke
    ThemeRowStroke.Parent = ThemeRow

    local ThemeRowText = Instance.new("TextLabel")
    ThemeRowText.Size = UDim2.new(0.6, 0, 1, 0)
    ThemeRowText.Position = UDim2.new(0, 14, 0, 0)
    ThemeRowText.BackgroundTransparency = 1
    ThemeRowText.Text = name
    ThemeRowText.Font = Enum.Font.GothamMedium
    ThemeRowText.TextSize = 13
    ThemeRowText.TextColor3 = Color3.fromRGB(220, 220, 220)
    ThemeRowText.TextXAlignment = Enum.TextXAlignment.Left
    ThemeRowText.Parent = ThemeRow

    local Badge = Instance.new("TextButton")
    Badge.Size = UDim2.new(0, 110, 0, 28)
    Badge.Position = UDim2.new(1, -14, 0.5, -14)
    Badge.AnchorPoint = Vector2.new(1, 0)
    Badge.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    Badge.BackgroundTransparency = 0.45
    Badge.Text = defaultItem .. " ▼"
    Badge.Font = Enum.Font.GothamMedium
    Badge.TextSize = 11
    Badge.TextColor3 = Color3.fromRGB(210, 210, 210)
    Badge.ZIndex = 3
    Badge.Parent = ThemeRow

    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 6)
    BadgeCorner.Parent = Badge

    local DropdownList = Instance.new("ScrollingFrame")
    DropdownList.Size = UDim2.new(0, 110, 0, 0)
    DropdownList.Position = UDim2.new(1, -14, 0.5, 16)
    DropdownList.AnchorPoint = Vector2.new(1, 0)
    DropdownList.BackgroundColor3 = self.Window.ThemeData.Row
    DropdownList.BackgroundTransparency = 0.45
    DropdownList.BorderSizePixel = 0
    DropdownList.ScrollBarThickness = 0
    DropdownList.ClipsDescendants = true
    DropdownList.Visible = false
    DropdownList.ZIndex = 50
    DropdownList.Parent = ThemeRow

    local DropdownCorner = Instance.new("UICorner")
    DropdownCorner.CornerRadius = UDim.new(0, 8)
    DropdownCorner.Parent = DropdownList

    local DropdownLayout = Instance.new("UIListLayout")
    DropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
    DropdownLayout.Padding = UDim.new(0, 2)
    DropdownLayout.Parent = DropdownList

    local open = false
    for idx, itemName in ipairs(items) do
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Size = UDim2.new(1, -4, 0, 30)
        ItemBtn.BackgroundTransparency = 1
        ItemBtn.Text = "  " .. itemName
        ItemBtn.Font = Enum.Font.GothamMedium
        ItemBtn.TextSize = 12
        ItemBtn.TextColor3 = (defaultItem == itemName) and self.Window.ThemeData.Accent or Color3.fromRGB(160, 160, 160)
        ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
        ItemBtn.LayoutOrder = idx
        ItemBtn.ZIndex = 51
        ItemBtn.Parent = DropdownList

        ItemBtn.MouseButton1Click:Connect(function()
            Badge.Text = itemName .. " ▼"
            open = false
            TweenService:Create(DropdownList, TweenInfo.new(0.15), {Size = UDim2.new(0, 110, 0, 0)}):Play()
            task.wait(0.15)
            DropdownList.Visible = false
            pcall(callback, itemName)
        end)
    end

    Badge.MouseButton1Click:Connect(function()
        open = not open
        if open then
            DropdownList.Visible = true
            Badge.Text = defaultItem .. " ▲"
            TweenService:Create(DropdownList, TweenInfo.new(0.2), {Size = UDim2.new(0, 110, 0, #items * 32)}):Play()
        else
            Badge.Text = defaultItem .. " ▼"
            local tw = TweenService:Create(DropdownList, TweenInfo.new(0.15), {Size = UDim2.new(0, 110, 0, 0)})
            tw:Play()
            tw.Completed:Connect(function()
                if not open then DropdownList.Visible = false end
            end)
        end
    end)
end

function AreumUI:Destroy()
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

return AreumUI