local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local ClipboardService = game:GetService("ClipboardService")

local OrionLib = {
	Elements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	Themes = {
		Default = {
			Main = Color3.fromRGB(25, 25, 25),
			Second = Color3.fromRGB(32, 32, 32),
			Stroke = Color3.fromRGB(60, 60, 60),
			Divider = Color3.fromRGB(60, 60, 60),
			Text = Color3.fromRGB(240, 240, 240),
			TextDark = Color3.fromRGB(150, 150, 150)
		}
	},
	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false,
	Transparency = 0.9,
	BackgroundImage = nil,
	CustomColors = { Text = nil, Stroke = nil },
	RemotesLog = {},
	RemoteSpyActive = false
}

-- Função segura para GUI
local function ProtectGui(gui)
    local success, result = pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        elseif setclipboard then
            -- Fallback para outros executors
        end
    end)
    return success
end

-- Criar GUI principal
local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
Orion.ResetOnSpawn = false

ProtectGui(Orion)

local function GetGuiParent()
    local success, result = pcall(function()
        if gethui then
            return gethui()
        end
        return game:GetService("CoreGui")
    end)
    return success and result or game.CoreGui
end

Orion.Parent = GetGuiParent()

-- Limpar interfaces antigas
for _, Interface in ipairs(GetGuiParent():GetChildren()) do
    if Interface.Name == Orion.Name and Interface ~= Orion then
        Interface:Destroy()
    end
end

-- Função para garantir que os elementos sejam clicáveis
local function MakeClickable(element)
    pcall(function()
        element.Active = true
        element.Selectable = true
        element.AutoButtonColor = false
        element.Modal = true
        
        if element:IsA("ImageButton") or element:IsA("TextButton") then
            element.AutoButtonColor = false
        end
    end)
end

-- Conexão segura
local function AddConnection(Signal, Function)
    if not Orion.Parent then return end
    local SignalConnect = Signal:Connect(Function)
    table.insert(OrionLib.Connections, SignalConnect)
    return SignalConnect
end

-- Feather Icons
local Icons = {}
local Success, Response = pcall(function()
    Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")).icons
end)

if not Success then
    warn("Orion Library - Failed to load Feather Icons")
end

local function GetIcon(IconName)
    return Icons[IconName]
end

-- Criar elementos básicos
local function Create(Name, Properties, Children)
    local Object = Instance.new(Name)
    for i, v in next, Properties or {} do
        Object[i] = v
    end
    for i, v in next, Children or {} do
        v.Parent = Object
    end
    return Object
end

local function CreateElement(ElementName, ElementFunction)
    OrionLib.Elements[ElementName] = function(...)
        return ElementFunction(...)
    end
end

local function MakeElement(ElementName, ...)
    return OrionLib.Elements[ElementName](...)
end

-- Elementos básicos
CreateElement("Corner", function(Scale, Offset)
    return Create("UICorner", { CornerRadius = UDim.new(Scale or 0, Offset or 8) })
end)

CreateElement("Stroke", function(Color, Thickness)
    return Create("UIStroke", { Color = Color or Color3.fromRGB(255, 255, 255), Thickness = Thickness or 1 })
end)

CreateElement("List", function(Scale, Offset)
    return Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(Scale or 0, Offset or 8) })
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
    return Create("UIPadding", {
        PaddingBottom = UDim.new(0, Bottom or 8),
        PaddingLeft = UDim.new(0, Left or 8),
        PaddingRight = UDim.new(0, Right or 8),
        PaddingTop = UDim.new(0, Top or 8)
    })
end)

CreateElement("TFrame", function()
    return Create("Frame", { BackgroundTransparency = 1 })
end)

CreateElement("Frame", function(Color)
    return Create("Frame", { BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 })
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
    return Create("Frame", { BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }, {
        Create("UICorner", { CornerRadius = UDim.new(Scale, Offset) })
    })
end)

CreateElement("Button", function()
    local btn = Create("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0 })
    MakeClickable(btn)
    return btn
end)

CreateElement("ScrollFrame", function(Color, Width)
    return Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        ScrollBarImageColor3 = Color,
        BorderSizePixel = 0,
        ScrollBarThickness = Width or 4,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
end)

CreateElement("Image", function(ImageID)
    local img = Create("ImageLabel", { Image = ImageID, BackgroundTransparency = 1 })
    if GetIcon(ImageID) then
        img.Image = GetIcon(ImageID)
    end
    return img
end)

CreateElement("ImageButton", function(ImageID)
    local btn = Create("ImageButton", { Image = ImageID, BackgroundTransparency = 1 })
    MakeClickable(btn)
    if GetIcon(ImageID) then
        btn.Image = GetIcon(ImageID)
    end
    return btn
end)

CreateElement("Label", function(Text, TextSize, Transparency)
    return Create("TextLabel", {
        Text = Text or "",
        TextColor3 = Color3.fromRGB(240, 240, 240),
        TextTransparency = Transparency or 0,
        TextSize = TextSize or 14,
        Font = Enum.Font.Gotham,
        RichText = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end)

-- Arrasto melhorado
local function AddDraggingFunctionality(DragPoint, Main)
    pcall(function()
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        DragPoint.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
            end
        end)
        
        DragPoint.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end)
end

local function SetTheme()
    for Name, Type in pairs(OrionLib.ThemeObjects) do
        for _, Object in pairs(Type) do
            local prop = nil
            if Object:IsA("Frame") or Object:IsA("TextButton") then
                prop = "BackgroundColor3"
            elseif Object:IsA("ScrollingFrame") then
                prop = "ScrollBarImageColor3"
            elseif Object:IsA("UIStroke") then
                prop = "Color"
            elseif Object:IsA("TextLabel") or Object:IsA("TextBox") then
                prop = "TextColor3"
            elseif Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
                prop = "ImageColor3"
            end
            
            if prop then
                if prop == "BackgroundColor3" and Name == "Main" then
                    Object.BackgroundTransparency = 1 - OrionLib.Transparency
                end
                
                local color = OrionLib.Themes[OrionLib.SelectedTheme][Name]
                if Name == "Text" and OrionLib.CustomColors.Text then
                    color = OrionLib.CustomColors.Text
                elseif Name == "Stroke" and OrionLib.CustomColors.Stroke then
                    color = OrionLib.CustomColors.Stroke
                end
                Object[prop] = color
            end
        end
    end
end

local function AddThemeObject(Object, Type)
    if not OrionLib.ThemeObjects[Type] then
        OrionLib.ThemeObjects[Type] = {}
    end
    table.insert(OrionLib.ThemeObjects[Type], Object)
    
    local prop = nil
    if Object:IsA("Frame") or Object:IsA("TextButton") then
        prop = "BackgroundColor3"
    elseif Object:IsA("ScrollingFrame") then
        prop = "ScrollBarImageColor3"
    elseif Object:IsA("UIStroke") then
        prop = "Color"
    elseif Object:IsA("TextLabel") or Object:IsA("TextBox") then
        prop = "TextColor3"
    elseif Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
        prop = "ImageColor3"
    end
    
    if prop and prop == "BackgroundColor3" and Type == "Main" then
        Object.BackgroundTransparency = 1 - OrionLib.Transparency
    end
    
    if prop then
        Object[prop] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
    end
    
    return Object
end

-- Sistema de executor de scripts
local function ExecuteScript(code)
    local success, result = pcall(function()
        if loadstring then
            local func = loadstring(code)
            if func then
                func()
            end
        end
    end)
    return success, result
end

-- Sistema de Remote Spy
local RemoteSpyConnections = {}

local function StartRemoteSpy()
    if OrionLib.RemoteSpyActive then return end
    OrionLib.RemoteSpyActive = true
    
    local function LogRemote(remote, type, ...)
        local args = {...}
        local argsString = {}
        for i, arg in ipairs(args) do
            if typeof(arg) == "Instance" then
                argsString[i] = arg.ClassName .. ": " .. arg.Name
            elseif typeof(arg) == "function" then
                argsString[i] = "function()"
            elseif typeof(arg) == "table" then
                argsString[i] = "{...}"
            else
                argsString[i] = tostring(arg)
            end
        end
        
        local logEntry = {
            Remote = remote.Name,
            Type = type,
            Args = table.concat(argsString, ", "),
            Time = os.date("%H:%M:%S")
        }
        
        table.insert(OrionLib.RemotesLog, 1, logEntry)
        
        if #OrionLib.RemotesLog > 50 then
            table.remove(OrionLib.RemotesLog)
        end
        
        OrionLib:MakeNotification({
            Name = "Remote " .. type,
            Content = remote.Name .. " | Args: " .. table.concat(argsString, ", "),
            Time = 3
        })
    end
    
    -- Hook Remotes
    local function HookRemote(remote)
        if remote:IsA("RemoteEvent") then
            local oldFire = remote.FireServer
            remote.FireServer = function(self, ...)
                LogRemote(remote, "FireServer", ...)
                return oldFire(self, ...)
            end
        elseif remote:IsA("RemoteFunction") then
            local oldInvoke = remote.InvokeServer
            remote.InvokeServer = function(self, ...)
                LogRemote(remote, "InvokeServer", ...)
                return oldInvoke(self, ...)
            end
        end
    end
    
    -- Procurar remotes existentes
    local function ScanRemotes(container)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                HookRemote(child)
            end
            ScanRemotes(child)
        end
    end
    
    ScanRemotes(game)
    
    -- Hook novos remotes
    local descendentAdded = game.DescendantAdded:Connect(function(desc)
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            HookRemote(desc)
        end
    end)
    
    table.insert(RemoteSpyConnections, descendentAdded)
end

local function StopRemoteSpy()
    OrionLib.RemoteSpyActive = false
    for _, conn in ipairs(RemoteSpyConnections) do
        conn:Disconnect()
    end
    RemoteSpyConnections = {}
end

-- Notification system
local NotificationHolder = MakeElement("TFrame")
NotificationHolder.Position = UDim2.new(1, -20, 1, -20)
NotificationHolder.Size = UDim2.new(0, 320, 1, -20)
NotificationHolder.AnchorPoint = Vector2.new(1, 1)
NotificationHolder.Parent = Orion

local NotificationList = Create("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 5) })
NotificationList.Parent = NotificationHolder

function OrionLib:MakeNotification(NotificationConfig)
    task.spawn(function()
        NotificationConfig.Name = NotificationConfig.Name or "Notification"
        NotificationConfig.Content = NotificationConfig.Content or "Test"
        NotificationConfig.Image = NotificationConfig.Image or "rbxassetid://4384403532"
        NotificationConfig.Time = NotificationConfig.Time or 5
        
        local NotificationParent = MakeElement("TFrame")
        NotificationParent.Size = UDim2.new(1, 0, 0, 0)
        NotificationParent.AutomaticSize = Enum.AutomaticSize.Y
        NotificationParent.Parent = NotificationHolder
        
        local NotificationFrame = MakeElement("RoundFrame", Color3.fromRGB(25, 25, 25), 0, 8)
        NotificationFrame.Parent = NotificationParent
        NotificationFrame.Size = UDim2.new(1, 0, 0, 0)
        NotificationFrame.Position = UDim2.new(1, 0, 0, 0)
        NotificationFrame.AutomaticSize = Enum.AutomaticSize.Y
        
        local NotifStroke = MakeElement("Stroke", Color3.fromRGB(93, 93, 93), 1)
        NotifStroke.Parent = NotificationFrame
        
        local NotifPadding = MakeElement("Padding", 12, 12, 12, 12)
        NotifPadding.Parent = NotificationFrame
        
        local Icon = MakeElement("Image", NotificationConfig.Image)
        Icon.Size = UDim2.new(0, 20, 0, 20)
        Icon.ImageColor3 = Color3.fromRGB(240, 240, 240)
        Icon.Name = "Icon"
        Icon.Parent = NotificationFrame
        
        local Title = MakeElement("Label", NotificationConfig.Name, 15)
        Title.Size = UDim2.new(1, -30, 0, 20)
        Title.Position = UDim2.new(0, 30, 0, 0)
        Title.Font = Enum.Font.GothamBold
        Title.Name = "Title"
        Title.Parent = NotificationFrame
        
        local Content = MakeElement("Label", NotificationConfig.Content, 13)
        Content.Size = UDim2.new(1, -30, 0, 0)
        Content.Position = UDim2.new(0, 30, 0, 25)
        Content.Font = Enum.Font.GothamSemibold
        Content.Name = "Content"
        Content.AutomaticSize = Enum.AutomaticSize.Y
        Content.TextColor3 = Color3.fromRGB(200, 200, 200)
        Content.TextWrapped = true
        Content.Parent = NotificationFrame
        
        TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        
        task.wait(NotificationConfig.Time - 0.5)
        
        TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(1, 20, 0, 0) }):Play()
        task.wait(0.5)
        NotificationFrame:Destroy()
        NotificationParent:Destroy()
    end)
end

-- Janela principal
function OrionLib:MakeWindow(WindowConfig)
    WindowConfig = WindowConfig or {}
    WindowConfig.Name = WindowConfig.Name or "Orion Library"
    WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
    WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
    WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
    
    local Minimized = false
    local UIHidden = false
    local FirstTab = true
    
    -- Top bar
    local TopBar = MakeElement("TFrame")
    TopBar.Size = UDim2.new(1, 0, 0, 50)
    TopBar.Name = "TopBar"
    
    -- Window name
    local WindowName = AddThemeObject(MakeElement("Label", WindowConfig.Name, 18), "Text")
    WindowName.Size = UDim2.new(1, -100, 2, 0)
    WindowName.Position = UDim2.new(0, 20, 0, -24)
    WindowName.Font = Enum.Font.GothamBlack
    WindowName.Parent = TopBar
    
    -- Top bar line
    local WindowTopBarLine = AddThemeObject(MakeElement("Frame"), "Stroke")
    WindowTopBarLine.Size = UDim2.new(1, 0, 0, 1)
    WindowTopBarLine.Position = UDim2.new(0, 0, 1, -1)
    WindowTopBarLine.Parent = TopBar
    
    -- Close and Minimize buttons
    local ButtonFrame = AddThemeObject(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), "Second")
    ButtonFrame.Size = UDim2.new(0, 80, 0, 30)
    ButtonFrame.Position = UDim2.new(1, -90, 0, 10)
    ButtonFrame.Parent = TopBar
    
    local ButtonStroke = MakeElement("Stroke")
    ButtonStroke.Parent = ButtonFrame
    
    local Divider = AddThemeObject(MakeElement("Frame"), "Stroke")
    Divider.Size = UDim2.new(0, 1, 1, 0)
    Divider.Position = UDim2.new(0.5, 0, 0, 0)
    Divider.Parent = ButtonFrame
    
    local CloseBtn = MakeElement("Button")
    CloseBtn.Size = UDim2.new(0.5, 0, 1, 0)
    CloseBtn.Position = UDim2.new(0.5, 0, 0, 0)
    CloseBtn.Parent = ButtonFrame
    
    local CloseIcon = AddThemeObject(MakeElement("Image", "rbxassetid://7072725342"), "Text")
    CloseIcon.Position = UDim2.new(0, 11, 0, 6)
    CloseIcon.Size = UDim2.new(0, 18, 0, 18)
    CloseIcon.Parent = CloseBtn
    
    local MinimizeBtn = MakeElement("Button")
    MinimizeBtn.Size = UDim2.new(0.5, 0, 1, 0)
    MinimizeBtn.Parent = ButtonFrame
    
    local MinIcon = AddThemeObject(MakeElement("Image", "rbxassetid://7072719338"), "Text")
    MinIcon.Position = UDim2.new(0, 11, 0, 6)
    MinIcon.Size = UDim2.new(0, 18, 0, 18)
    MinIcon.Name = "Ico"
    MinIcon.Parent = MinimizeBtn
    
    -- Drag point
    local DragPoint = MakeElement("TFrame")
    DragPoint.Size = UDim2.new(1, 0, 0, 50)
    
    -- Tab holder
    local TabHolder = AddThemeObject(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 4), "Divider")
    TabHolder.Size = UDim2.new(1, 0, 1, -50)
    
    local TabList = MakeElement("List")
    TabList.Parent = TabHolder
    
    local TabPadding = MakeElement("Padding", 8, 0, 0, 8)
    TabPadding.Parent = TabHolder
    
    AddConnection(TabList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabList.AbsoluteContentSize.Y + 16)
    end)
    
    -- Window stuff
    local WindowStuff = AddThemeObject(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), "Second")
    WindowStuff.Size = UDim2.new(0, 180, 1, -50)
    WindowStuff.Position = UDim2.new(0, 0, 0, 50)
    
    local StuffCorner = MakeElement("Corner", 0, 10)
    StuffCorner.Parent = WindowStuff
    
    local StuffTop = AddThemeObject(MakeElement("Frame"), "Second")
    StuffTop.Size = UDim2.new(1, 0, 0, 10)
    StuffTop.Parent = WindowStuff
    
    TabHolder.Parent = WindowStuff
    
    -- Main window
    local MainWindow = AddThemeObject(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), "Main")
    MainWindow.Parent = Orion
    MainWindow.Position = UDim2.new(0.5, -300, 0.5, -250)
    MainWindow.Size = UDim2.new(0, 600, 0, 500)
    MainWindow.ClipsDescendants = true
    MainWindow.Name = "MainWindow"
    
    TopBar.Parent = MainWindow
    DragPoint.Parent = MainWindow
    WindowStuff.Parent = MainWindow
    
    AddDraggingFunctionality(DragPoint, MainWindow)
    
    -- Close button function
    AddConnection(CloseBtn.MouseButton1Click, function()
        UIHidden = true
        MainWindow.Visible = false
        WindowConfig.CloseCallback()
        OrionLib:MakeNotification({ Name = "Interface", Content = "Use 'Open' no chat para reabrir", Time = 5 })
    end)
    
    -- Minimize button function
    AddConnection(MinimizeBtn.MouseButton1Click, function()
        if Minimized then
            TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(0, 600, 0, 500) }):Play()
            MinIcon.Image = "rbxassetid://7072719338"
            task.wait(0.1)
            WindowStuff.Visible = true
        else
            MinIcon.Image = "rbxassetid://7072720870"
            TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50) }):Play()
            task.wait(0.1)
            WindowStuff.Visible = false
        end
        Minimized = not Minimized
    end)
    
    -- Chat command to reopen
    AddConnection(LocalPlayer.Chatted, function(msg)
        if msg:lower() == "open" then
            MainWindow.Visible = true
            UIHidden = false
        end
    end)
    
    -- Tabs function
    local TabFunction = {}
    
    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "Tab"
        TabConfig.Icon = TabConfig.Icon or ""
        
        local TabFrame = MakeElement("Button")
        TabFrame.Size = UDim2.new(1, 0, 0, 35)
        TabFrame.Parent = TabHolder
        
        local TabIcon = AddThemeObject(MakeElement("Image", TabConfig.Icon), "Text")
        TabIcon.AnchorPoint = Vector2.new(0, 0.5)
        TabIcon.Size = UDim2.new(0, 20, 0, 20)
        TabIcon.Position = UDim2.new(0, 12, 0.5, 0)
        TabIcon.ImageTransparency = 0.4
        TabIcon.Name = "Ico"
        TabIcon.Parent = TabFrame
        
        local TabTitle = AddThemeObject(MakeElement("Label", TabConfig.Name, 14), "Text")
        TabTitle.Size = UDim2.new(1, -40, 1, 0)
        TabTitle.Position = UDim2.new(0, 40, 0, 0)
        TabTitle.Font = Enum.Font.GothamSemibold
        TabTitle.TextTransparency = 0.4
        TabTitle.Name = "Title"
        TabTitle.Parent = TabFrame
        
        -- Container for tab content
        local Container = AddThemeObject(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), "Divider")
        Container.Size = UDim2.new(1, -190, 1, -50)
        Container.Position = UDim2.new(0, 190, 0, 50)
        Container.Parent = MainWindow
        Container.Visible = false
        Container.Name = "ItemContainer"
        
        local ContainerList = MakeElement("List", 0, 8)
        ContainerList.Parent = Container
        
        local ContainerPadding = MakeElement("Padding", 15, 15, 15, 15)
        ContainerPadding.Parent = Container
        
        AddConnection(ContainerList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0, 0, 0, ContainerList.AbsoluteContentSize.Y + 30)
        end)
        
        if FirstTab then
            FirstTab = false
            TabIcon.ImageTransparency = 0
            TabTitle.TextTransparency = 0
            TabTitle.Font = Enum.Font.GothamBlack
            Container.Visible = true
        end
        
        AddConnection(TabFrame.MouseButton1Click, function()
            for _, Tab in ipairs(TabHolder:GetChildren()) do
                if Tab:IsA("TextButton") then
                    local icon = Tab:FindFirstChild("Ico")
                    local title = Tab:FindFirstChild("Title")
                    if icon and title then
                        title.Font = Enum.Font.GothamSemibold
                        TweenService:Create(icon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { ImageTransparency = 0.4 }):Play()
                        TweenService:Create(title, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { TextTransparency = 0.4 }):Play()
                    end
                end
            end
            
            for _, ItemContainer in ipairs(MainWindow:GetChildren()) do
                if ItemContainer.Name == "ItemContainer" then
                    ItemContainer.Visible = false
                end
            end
            
            TweenService:Create(TabIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { ImageTransparency = 0 }):Play()
            TweenService:Create(TabTitle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { TextTransparency = 0 }):Play()
            TabTitle.Font = Enum.Font.GothamBlack
            Container.Visible = true
        end)
        
        -- Element functions
        local function GetElements(Parent)
            local Elements = {}
            
            function Elements:AddLabel(Text)
                local Frame = AddThemeObject(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), "Second")
                Frame.Size = UDim2.new(1, 0, 0, 35)
                Frame.BackgroundTransparency = 0.7
                Frame.Parent = Parent
                
                local Label = AddThemeObject(MakeElement("Label", Text, 14), "Text")
                Label.Size = UDim2.new(1, -16, 1, 0)
                Label.Position = UDim2.new(0, 16, 0, 0)
                Label.Font = Enum.Font.GothamBold
                Label.Name = "Content"
                Label.Parent = Frame
                
                local Stroke = MakeElement("Stroke")
                Stroke.Parent = Frame
                
                local LabelFunc = {}
                function LabelFunc:Set(ToChange)
                    Label.Text = ToChange
                end
                return LabelFunc
            end
            
            function Elements:AddButton(ButtonConfig)
                ButtonConfig.Name = ButtonConfig.Name or "Button"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end
                
                local ButtonFrame = AddThemeObject(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), "Second")
                ButtonFrame.Size = UDim2.new(1, 0, 0, 38)
                ButtonFrame.Parent = Parent
                
                local ButtonText = AddThemeObject(MakeElement("Label", ButtonConfig.Name, 14), "Text")
                ButtonText.Size = UDim2.new(1, -16, 1, 0)
                ButtonText.Position = UDim2.new(0, 16, 0, 0)
                ButtonText.Font = Enum.Font.GothamBold
                ButtonText.Parent = ButtonFrame
                
                local Stroke = MakeElement("Stroke")
                Stroke.Parent = ButtonFrame
                
                local ClickBtn = MakeElement("Button")
                ClickBtn.Size = UDim2.new(1, 0, 1, 0)
                ClickBtn.Parent = ButtonFrame
                
                AddConnection(ClickBtn.MouseButton1Click, function()
                    ButtonConfig.Callback()
                    OrionLib:MakeNotification({ Name = ButtonConfig.Name, Content = "Executado!", Time = 2 })
                end)
                
                local Button = {}
                function Button:Set(Text)
                    ButtonText.Text = Text
                end
                return Button
            end
            
            function Elements:AddToggle(ToggleConfig)
                ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Callback = ToggleConfig.Callback or function() end
                
                local Toggle = { Value = ToggleConfig.Default }
                
                local ToggleFrame = AddThemeObject(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), "Second")
                ToggleFrame.Size = UDim2.new(1, 0, 0, 38)
                ToggleFrame.Parent = Parent
                
                local ToggleText = AddThemeObject(MakeElement("Label", ToggleConfig.Name, 14), "Text")
                ToggleText.Size = UDim2.new(1, -50, 1, 0)
                ToggleText.Position = UDim2.new(0, 16, 0, 0)
                ToggleText.Font = Enum.Font.GothamBold
                ToggleText.Parent = ToggleFrame
                
                local ToggleBox = AddThemeObject(MakeElement("RoundFrame", Color3.fromRGB(9, 99, 195), 0, 4), "Main")
                ToggleBox.Size = UDim2.new(0, 24, 0, 24)
                ToggleBox.Position = UDim2.new(1, -16, 0.5, 0)
                ToggleBox.AnchorPoint = Vector2.new(0.5, 0.5)
                ToggleBox.Parent = ToggleFrame
                
                local BoxStroke = MakeElement("Stroke", Color3.fromRGB(9, 99, 195))
                BoxStroke.Transparency = 0.5
                BoxStroke.Parent = ToggleBox
                
                local CheckIcon = MakeElement("Image", "rbxassetid://3944680095")
                CheckIcon.Size = UDim2.new(0, 20, 0, 20)
                CheckIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                CheckIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
                CheckIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
                CheckIcon.Name = "Ico"
                CheckIcon.Parent = ToggleBox
                
                local Stroke = MakeElement("Stroke")
                Stroke.Parent = ToggleFrame
                
                local ClickBtn = MakeElement("Button")
                ClickBtn.Size = UDim2.new(1, 0, 1, 0)
                ClickBtn.Parent = ToggleFrame
                
                function Toggle:Set(Value)
                    Toggle.Value = Value
                    TweenService:Create(ToggleBox, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { BackgroundColor3 = Toggle.Value and Color3.fromRGB(9, 99, 195) or Color3.fromRGB(60, 60, 60) }):Play()
                    TweenService:Create(BoxStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { Color = Toggle.Value and Color3.fromRGB(9, 99, 195) or Color3.fromRGB(60, 60, 60) }):Play()
                    TweenService:Create(CheckIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { ImageTransparency = Toggle.Value and 0 or 1 }):Play()
                    ToggleConfig.Callback(Toggle.Value)
                end
                
                Toggle:Set(Toggle.Value)
                
                AddConnection(ClickBtn.MouseButton1Click, function()
                    Toggle:Set(not Toggle.Value)
                end)
                
                return Toggle
            end
            
            function Elements:AddTextbox(TextboxConfig)
                TextboxConfig.Name = TextboxConfig.Name or "Textbox"
                TextboxConfig.Default = TextboxConfig.Default or ""
                TextboxConfig.Callback = TextboxConfig.Callback or function() end
                
                local TextboxFrame = AddThemeObject(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), "Second")
                TextboxFrame.Size = UDim2.new(1, 0, 0, 38)
                TextboxFrame.Parent = Parent
                
                local TextboxLabel = AddThemeObject(MakeElement("Label", TextboxConfig.Name, 14), "Text")
                TextboxLabel.Size = UDim2.new(1, -100, 1, 0)
                TextboxLabel.Position = UDim2.new(0, 16, 0, 0)
                TextboxLabel.Font = Enum.Font.GothamBold
                TextboxLabel.Parent = TextboxFrame
                
                local TextboxInput = AddThemeObject(Create("TextBox", {
                    Size = UDim2.new(0, 80, 0, 24),
                    Position = UDim2.new(1, -16, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    TextColor3 = Color3.fromRGB(240, 240, 240),
                    PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
                    PlaceholderText = "Input",
                    Font = Enum.Font.GothamSemibold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextSize = 12,
                    ClearTextOnFocus = false
                }), "Main")
                
                local InputCorner = Create("UICorner", { CornerRadius = UDim.new(0, 4) })
                InputCorner.Parent = TextboxInput
                TextboxInput.Parent = TextboxFrame
                
                local Stroke = MakeElement("Stroke")
                Stroke.Parent = TextboxFrame
                
                TextboxInput.Text = TextboxConfig.Default
                
                AddConnection(TextboxInput.FocusLost, function()
                    TextboxConfig.Callback(TextboxInput.Text)
                end)
            end
            
            return Elements
        end
        
        local TabElements = GetElements(Container)
        
        function TabElements:AddSection(SectionConfig)
            SectionConfig.Name = SectionConfig.Name or "Section"
            
            local SectionFrame = MakeElement("TFrame")
            SectionFrame.Size = UDim2.new(1, 0, 0, 30)
            SectionFrame.Parent = Container
            
            local SectionTitle = AddThemeObject(MakeElement("Label", SectionConfig.Name, 12), "TextDark")
            SectionTitle.Size = UDim2.new(1, -16, 0, 16)
            SectionTitle.Position = UDim2.new(0, 0, 0, 3)
            SectionTitle.Font = Enum.Font.GothamSemibold
            SectionTitle.Parent = SectionFrame
            
            local SectionHolder = MakeElement("TFrame")
            SectionHolder.Size = UDim2.new(1, 0, 1, -24)
            SectionHolder.Position = UDim2.new(0, 0, 0, 23)
            SectionHolder.Name = "Holder"
            SectionHolder.Parent = SectionFrame
            
            local HolderList = MakeElement("List", 0, 8)
            HolderList.Parent = SectionHolder
            
            AddConnection(HolderList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                SectionFrame.Size = UDim2.new(1, 0, 0, HolderList.AbsoluteContentSize.Y + 31)
                SectionHolder.Size = UDim2.new(1, 0, 0, HolderList.AbsoluteContentSize.Y)
            end)
            
            local SectionFunctions = GetElements(SectionHolder)
            return SectionFunctions
        end
        
        -- Tab Executor
        function TabElements:AddExecutorTab()
            local ExecSection = TabElements:AddSection({ Name = "Script Executor" })
            
            local ScriptBox = Create("TextBox", {
                Size = UDim2.new(1, 0, 0, 100),
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                TextColor3 = Color3.fromRGB(240, 240, 240),
                PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
                PlaceholderText = "Cole seu script aqui...",
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                ClearTextOnFocus = false
            })
            
            local BoxCorner = Create("UICorner", { CornerRadius = UDim.new(0, 8) })
            BoxCorner.Parent = ScriptBox
            
            local ExecButton = ExecSection:AddButton({ 
                Name = "▶ Executar Script", 
                Callback = function()
                    if ScriptBox.Text and ScriptBox.Text ~= "" then
                        local success, result = ExecuteScript(ScriptBox.Text)
                        if success then
                            OrionLib:MakeNotification({ Name = "Executor", Content = "Script executado com sucesso!", Time = 3 })
                        else
                            OrionLib:MakeNotification({ Name = "Erro", Content = "Erro ao executar: " .. tostring(result), Time = 5 })
                        end
                    end
                end
            })
            
            local ClearButton = ExecSection:AddButton({ 
                Name = "🗑 Limpar", 
                Callback = function()
                    ScriptBox.Text = ""
                end
            })
            
            ScriptBox.Parent = Container
            ScriptBox.Position = UDim2.new(0, 15, 0, 120)
            
            return ScriptBox
        end
        
        -- Tab Remote Spy
        function TabElements:AddRemoteSpyTab()
            local RemoteSection = TabElements:AddSection({ Name = "Remote Spy" })
            
            local SpyToggle = RemoteSection:AddToggle({
                Name = "Ativar Remote Spy",
                Default = false,
                Callback = function(state)
                    if state then
                        StartRemoteSpy()
                        OrionLib:MakeNotification({ Name = "Remote Spy", Content = "Spy ativado!", Time = 2 })
                    else
                        StopRemoteSpy()
                        OrionLib:MakeNotification({ Name = "Remote Spy", Content = "Spy desativado!", Time = 2 })
                    end
                end
            })
            
            local ClearButton = RemoteSection:AddButton({
                Name = "🗑 Limpar Logs",
                Callback = function()
                    OrionLib.RemotesLog = {}
                    OrionLib:MakeNotification({ Name = "Remote Spy", Content = "Logs limpos!", Time = 2 })
                end
            })
            
            -- Log display
            local LogFrame = MakeElement("RoundFrame", Color3.fromRGB(32, 32, 32), 0, 8)
            LogFrame.Size = UDim2.new(1, 0, 0, 200)
            LogFrame.Parent = Container
            
            local LogScroll = MakeElement("ScrollFrame", Color3.fromRGB(100, 100, 100), 4)
            LogScroll.Size = UDim2.new(1, 0, 1, 0)
            LogScroll.Parent = LogFrame
            
            local LogList = MakeElement("List", 0, 4)
            LogList.Parent = LogScroll
            
            local LogPadding = MakeElement("Padding", 8, 8, 8, 8)
            LogPadding.Parent = LogScroll
            
            -- Update log display
            local function UpdateLogDisplay()
                for _, child in ipairs(LogList:GetChildren()) do
                    if child:IsA("TextLabel") then
                        child:Destroy()
                    end
                end
                
                for i, log in ipairs(OrionLib.RemotesLog) do
                    local logText = string.format("[%s] %s: %s", log.Time, log.Remote, log.Args)
                    local logLabel = MakeElement("Label", logText, 11)
                    logLabel.Size = UDim2.new(1, 0, 0, 20)
                    logLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                    logLabel.TextWrapped = true
                    logLabel.Parent = LogList
                end
                
                LogScroll.CanvasSize = UDim2.new(0, 0, 0, LogList.AbsoluteContentSize.Y + 16)
            end
            
            -- Update every second
            task.spawn(function()
                while true do
                    task.wait(1)
                    UpdateLogDisplay()
                end
            end)
            
            return SpyToggle
        end
        
        return TabElements
    end
    
    OrionLib:MakeNotification({ Name = "Orion Library", Content = "Carregada com sucesso!", Time = 3 })
    
    return TabFunction
end

function OrionLib:Destroy()
    Orion:Destroy()
end

return OrionLib