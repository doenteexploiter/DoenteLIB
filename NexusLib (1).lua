-- ╔══════════════════════════════════════════════════════════════╗
-- ║              DoenteLib v3.0 — Roblox UI Library              ║
-- ║         Mobile-First  •  Professional  •  Orion-Style       ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ┌──────────────────────────────────────────────────────────────┐
--   CONFIGURAÇÃO — edite apenas aqui
-- └──────────────────────────────────────────────────────────────┘
local CONFIG = {
	Title    = "DoenteLib",
	Subtitle = "Mobile UI Library v3.0",

	-- Asset ID da logo exibida no canto superior da janela
	LogoAssetId = "6023426952",

	-- Asset ID da imagem de fundo
	BackgroundImageId           = "6023426952",
	BackgroundImageTransparency = 0.40,

	-- Asset ID do botão flutuante
	ToggleButtonImageId = "6023426952",

	-- Tamanho da janela (otimizado para mobile)
	WindowWidth  = 380,
	WindowHeight = 560,

	-- Cores
	PrimaryColor       = Color3.fromRGB(99, 102, 241),
	SecondaryColor     = Color3.fromRGB(139, 142, 255),
	TextColor          = Color3.fromRGB(230, 230, 255),
	TextColorSecondary = Color3.fromRGB(148, 163, 184),
	BackgroundColor    = Color3.fromRGB(10, 10, 20),
	HeaderColor        = Color3.fromRGB(13, 13, 26),
	ElementColor       = Color3.fromRGB(20, 20, 38),

	-- Digitação
	TypingSpeed         = 0.11,
	DeleteSpeed         = 0.06,
	TypingPauseDuration = 2.5,

	-- Comando de chat para reabrir quando a UI estiver escondida
	OpenChatCommand = ":open",
}
-- └──────────────────────────────────────────────────────────────┘

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function New(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function Corner(f, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = f
end

local function Stroke(f, color, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color        = color or CONFIG.PrimaryColor
	s.Thickness    = thick or 1
	s.Transparency = trans or 0.5
	s.Parent = f
end

local function Pad(f, t, r, b, l)
	local p = Instance.new("UIPadding")
	p.PaddingTop    = UDim.new(0, t or 8)
	p.PaddingRight  = UDim.new(0, r or 8)
	p.PaddingBottom = UDim.new(0, b or 8)
	p.PaddingLeft   = UDim.new(0, l or 8)
	p.Parent = f
end

local function List(f, dir, gap, pad)
	local l = Instance.new("UIListLayout")
	l.SortOrder     = Enum.SortOrder.LayoutOrder
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.Padding       = UDim.new(0, gap or 6)
	if pad then
		l.Padding = UDim.new(0, pad)
	end
	l.Parent = f
	return l
end

local function Tween(obj, t, s, d, props)
	local ti = TweenInfo.new(t or 0.3, s or Enum.EasingStyle.Quart, d or Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, ti, props)
	tw:Play()
	return tw
end

-- ══════════════════════════════════════════════════════════════
--  ANIMAÇÃO DE DIGITAÇÃO
-- ══════════════════════════════════════════════════════════════
local _typingThread = nil

local function StartTyping(label, text)
	if _typingThread then
		task.cancel(_typingThread)
		_typingThread = nil
	end
	_typingThread = task.spawn(function()
		local idx, deleting = 0, false
		while label and label.Parent do
			if not deleting then
				idx = idx + 1
				label.Text = string.sub(text, 1, idx) .. (idx < #text and "|" or " ✦")
				if idx >= #text then
					task.wait(CONFIG.TypingPauseDuration)
					deleting = true
				else
					task.wait(CONFIG.TypingSpeed)
				end
			else
				idx = idx - 1
				label.Text = string.sub(text, 1, idx) .. "|"
				if idx <= 0 then
					deleting = false
					task.wait(0.45)
				else
					task.wait(CONFIG.DeleteSpeed)
				end
			end
		end
	end)
end

-- ══════════════════════════════════════════════════════════════
--  ESTADO GLOBAL DE VISIBILIDADE
-- ══════════════════════════════════════════════════════════════
local _uiVisible = true
local _mainFrame = nil
local W          = CONFIG.WindowWidth
local H          = CONFIG.WindowHeight

local function ShowUI()
	if not _mainFrame then return end
	_uiVisible         = true
	_mainFrame.Visible = true
	_mainFrame.Size    = UDim2.new(0, W, 0, 0)
	Tween(_mainFrame, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
		Size = UDim2.new(0, W, 0, H),
		BackgroundTransparency = 0,
	})
end

local function HideUI()
	if not _mainFrame then return end
	_uiVisible = false
	local tw = Tween(_mainFrame, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
		Size = UDim2.new(0, W, 0, 0),
		BackgroundTransparency = 1,
	})
	tw.Completed:Connect(function()
		if not _uiVisible then
			_mainFrame.Visible = false
		end
	end)
end

local function ToggleUI()
	if _uiVisible then HideUI() else ShowUI() end
end

-- ══════════════════════════════════════════════════════════════
--  COMANDO DE CHAT
-- ══════════════════════════════════════════════════════════════
local function SetupChatCommand()
	LocalPlayer.Chatted:Connect(function(msg)
		if string.lower(string.gsub(msg, "%s", "")) == string.lower(CONFIG.OpenChatCommand) then
			if not _uiVisible then ShowUI() end
		end
	end)
end

-- ══════════════════════════════════════════════════════════════
--  DRAG DO BOTÃO FLUTUANTE + 3 CLIQUES
-- ══════════════════════════════════════════════════════════════
local function SetupButtonDrag(btn, onClickCallback)
	local THRESH   = 8
	local pressing = false
	local moved    = false
	local origin   = nil
	local startPos = nil

	local clickCount = 0
	local lastClickTime = 0
	local CLICK_TIMEOUT = 0.8

	local function HideFullUI()
		if _mainFrame then
			_mainFrame.Visible = false
		end
		if btn then
			btn.Visible = false
		end
		_uiVisible = false
	end

	local function ShowFullUI()
		if _mainFrame then
			_mainFrame.Visible = true
			_mainFrame.Size = UDim2.new(0, W, 0, 0)
			Tween(_mainFrame, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
				Size = UDim2.new(0, W, 0, H),
				BackgroundTransparency = 0,
			})
		end
		if btn then
			btn.Visible = true
		end
		_uiVisible = true
	end

	local function onButtonClick()
		local currentTime = tick()

		if currentTime - lastClickTime > CLICK_TIMEOUT then
			clickCount = 0
		end

		clickCount = clickCount + 1
		lastClickTime = currentTime

		local originalSize = btn.Size
		local originalTrans = btn.BackgroundTransparency

		Tween(btn, 0.05, nil, nil, {
			Size = UDim2.new(0, 46, 0, 46),
			BackgroundTransparency = 0
		})
		task.wait(0.05)
		Tween(btn, 0.05, nil, nil, {
			Size = originalSize,
			BackgroundTransparency = originalTrans
		})

		local counter = btn:FindFirstChild("ClickCounter")
		if not counter then
			counter = New("TextLabel", {
				Name = "ClickCounter",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				Font = Enum.Font.GothamBold,
				ZIndex = 11,
			}, btn)
		end

		if clickCount > 0 and clickCount < 3 then
			counter.Text = clickCount .. "/3"
			counter.TextColor3 = Color3.fromRGB(255, 255, 255)
			task.delay(0.5, function()
				if counter then counter.Text = "" end
			end)
		elseif clickCount >= 3 then
			counter.Text = "✓"
			counter.TextColor3 = Color3.fromRGB(34, 197, 94)
			task.delay(0.5, function()
				if counter then counter.Text = "" end
			end)
		end

		if clickCount >= 3 then
			clickCount = 0
			if _uiVisible then
				HideFullUI()
			else
				ShowFullUI()
			end
		else
			onClickCallback()
		end
	end

	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			pressing = true
			moved    = false
			origin   = input.Position
			startPos = btn.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not pressing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - origin
		if not moved and (math.abs(delta.X) > THRESH or math.abs(delta.Y) > THRESH) then
			moved = true
		end
		if moved then
			btn.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			if pressing and not moved then
				onButtonClick()
			end
			pressing = false
			moved    = false
		end
	end)
end

-- ══════════════════════════════════════════════════════════════
--  DRAG DA JANELA
-- ══════════════════════════════════════════════════════════════
local function SetupWindowDrag(header, frame)
	local dragging, dragStart, startPos = false, nil, nil
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = input.Position
			startPos  = frame.Position
		end
	end)
	header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local d = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y
		)
	end)
end

-- ══════════════════════════════════════════════════════════════
--  CLASSE PRINCIPAL
-- ══════════════════════════════════════════════════════════════
local NexusLib   = {}
NexusLib.__index = NexusLib

function NexusLib.new()
	local self = setmetatable({}, NexusLib)

	self.ScreenGui = New("ScreenGui", {
		Name           = "NexusLib",
		ResetOnSpawn   = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder   = 999,
		IgnoreGuiInset = true,
	}, PlayerGui)

	-- Janela principal
	self.MainFrame = New("Frame", {
		Name             = "MainFrame",
		Size             = UDim2.new(0, W, 0, 0),
		Position         = UDim2.new(0.5, -W/2, 0.5, -H/2),
		BackgroundColor3 = CONFIG.BackgroundColor,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
	}, self.ScreenGui)
	Corner(self.MainFrame, 14)
	Stroke(self.MainFrame, CONFIG.PrimaryColor, 1, 0.35)
	_mainFrame = self.MainFrame

	-- Imagem de fundo
	self.BgImage = New("ImageLabel", {
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image                  = "rbxassetid://" .. CONFIG.BackgroundImageId,
		ImageTransparency      = CONFIG.BackgroundImageTransparency,
		ScaleType              = Enum.ScaleType.Crop,
		ZIndex                 = 1,
	}, self.MainFrame)

	-- Overlay
	New("Frame", {
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundColor3       = CONFIG.BackgroundColor,
		BackgroundTransparency = 0.28,
		BorderSizePixel        = 0,
		ZIndex                 = 2,
	}, self.MainFrame)

	-- Header (otimizado para mobile)
	self.Header = New("Frame", {
		Name             = "Header",
		Size             = UDim2.new(1, 0, 0, 130),
		BackgroundColor3 = CONFIG.HeaderColor,
		BorderSizePixel  = 0,
		ZIndex           = 3,
	}, self.MainFrame)

	New("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = CONFIG.PrimaryColor,
		BackgroundTransparency = 0.4,
		BorderSizePixel  = 0,
		ZIndex           = 4,
	}, self.Header)

	-- Logo
	self.LogoImage = New("ImageLabel", {
		Name                   = "LogoImage",
		Size                   = UDim2.new(0, 40, 0, 40),
		Position               = UDim2.new(0, 12, 0, 10),
		BackgroundColor3       = CONFIG.PrimaryColor,
		BackgroundTransparency = 0.55,
		Image                  = "rbxassetid://" .. CONFIG.LogoAssetId,
		ImageTransparency      = 0,
		ScaleType              = Enum.ScaleType.Fit,
		ZIndex                 = 5,
	}, self.Header)
	Corner(self.LogoImage, 10)
	Stroke(self.LogoImage, CONFIG.PrimaryColor, 1, 0.4)

	-- Título
	self.TitleLabel = New("TextLabel", {
		Name                   = "TitleLabel",
		Size                   = UDim2.new(1, -120, 0, 24),
		Position               = UDim2.new(0, 60, 0, 8),
		BackgroundTransparency = 1,
		Text                   = "",
		TextColor3             = CONFIG.TextColor,
		TextSize               = 16,
		Font                   = Enum.Font.GothamBold,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 5,
	}, self.Header)

	-- Subtítulo
	self.SubtitleLabel = New("TextLabel", {
		Name                   = "SubtitleLabel",
		Size                   = UDim2.new(1, -120, 0, 16),
		Position               = UDim2.new(0, 60, 0, 32),
		BackgroundTransparency = 1,
		Text                   = CONFIG.Subtitle,
		TextColor3             = CONFIG.TextColorSecondary,
		TextSize               = 10,
		Font                   = Enum.Font.Gotham,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 5,
	}, self.Header)

	-- Botão fechar (maior para mobile)
	self.CloseButton = New("TextButton", {
		Name                   = "CloseButton",
		Size                   = UDim2.new(0, 34, 0, 34),
		Position               = UDim2.new(1, -44, 0, 8),
		BackgroundColor3       = Color3.fromRGB(239, 68, 68),
		BackgroundTransparency = 0.6,
		Text                   = "✕",
		TextColor3             = Color3.fromRGB(255, 120, 120),
		TextSize               = 14,
		Font                   = Enum.Font.GothamBold,
		BorderSizePixel        = 0,
		ZIndex                 = 6,
	}, self.Header)
	Corner(self.CloseButton, 9)
	Stroke(self.CloseButton, Color3.fromRGB(239, 68, 68), 1, 0.5)
	self.CloseButton.MouseButton1Click:Connect(ToggleUI)
	self.CloseButton.MouseEnter:Connect(function()
		Tween(self.CloseButton, 0.12, nil, nil, {BackgroundTransparency = 0.25})
	end)
	self.CloseButton.MouseLeave:Connect(function()
		Tween(self.CloseButton, 0.15, nil, nil, {BackgroundTransparency = 0.6})
	end)

	-- Player Card (otimizado para mobile)
	self.PlayerCard = New("Frame", {
		Name             = "PlayerCard",
		Size             = UDim2.new(1, -20, 0, 70),
		Position         = UDim2.new(0, 10, 0, 52),
		BackgroundColor3 = Color3.fromRGB(7, 7, 16),
		BackgroundTransparency = 0.08,
		BorderSizePixel  = 0,
		ZIndex           = 4,
	}, self.Header)
	Corner(self.PlayerCard, 12)
	Stroke(self.PlayerCard, CONFIG.PrimaryColor, 1, 0.55)

	-- Viewport 3D (maior para mobile)
	self.PlayerViewport = New("ViewportFrame", {
		Size                   = UDim2.new(0, 64, 0, 64),
		Position               = UDim2.new(0, 4, 0.5, -32),
		BackgroundColor3       = Color3.fromRGB(5, 5, 14),
		BackgroundTransparency = 0.05,
		ZIndex                 = 5,
		Ambient                = Color3.fromRGB(190, 190, 230),
		LightColor             = Color3.fromRGB(255, 255, 255),
		LightDirection         = Vector3.new(-1, -2, -1),
	}, self.PlayerCard)
	Corner(self.PlayerViewport, 10)

	-- Display name
	New("TextLabel", {
		Size                   = UDim2.new(1, -80, 0, 22),
		Position               = UDim2.new(0, 76, 0, 8),
		BackgroundTransparency = 1,
		Text                   = LocalPlayer.DisplayName,
		TextColor3             = CONFIG.TextColor,
		TextSize               = 14,
		Font                   = Enum.Font.GothamBold,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ZIndex                 = 5,
	}, self.PlayerCard)

	-- @username
	New("TextLabel", {
		Size                   = UDim2.new(1, -80, 0, 16),
		Position               = UDim2.new(0, 76, 0, 30),
		BackgroundTransparency = 1,
		Text                   = "@" .. LocalPlayer.Name,
		TextColor3             = CONFIG.TextColorSecondary,
		TextSize               = 11,
		Font                   = Enum.Font.Gotham,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 5,
	}, self.PlayerCard)

	-- Badge ID
	local idBadge = New("TextLabel", {
		Size                   = UDim2.new(0, 0, 0, 18),
		AutomaticSize          = Enum.AutomaticSize.X,
		Position               = UDim2.new(0, 76, 0, 46),
		BackgroundColor3       = CONFIG.PrimaryColor,
		BackgroundTransparency = 0.52,
		Text                   = "  ID: " .. tostring(LocalPlayer.UserId) .. "  ",
		TextColor3             = CONFIG.SecondaryColor,
		TextSize               = 9,
		Font                   = Enum.Font.GothamBold,
		ZIndex                 = 5,
	}, self.PlayerCard)
	Corner(idBadge, 5)

	-- Boneco 3D
	task.spawn(function()
		local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		if not char:FindFirstChild("HumanoidRootPart") then
			char:WaitForChild("HumanoidRootPart", 10)
		end
		task.wait(0.15)
		local clone = char:Clone()
		for _, v in ipairs(clone:GetDescendants()) do
			if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Animator")
				or v:IsA("AnimationController") or v:IsA("BodyMover") or v:IsA("Humanoid") then
				v:Destroy()
			end
		end
		for _, p in ipairs(clone:GetDescendants()) do
			if p:IsA("BasePart") then p.Anchored = true end
		end
		local root = clone:FindFirstChild("HumanoidRootPart")
		if root then root.CFrame = CFrame.new(0, -1.5, 0) end
		clone.Parent = self.PlayerViewport
		local cam = Instance.new("Camera")
		cam.CFrame = CFrame.new(Vector3.new(0, 0.9, 3.6), Vector3.new(0, 0.9, 0))
		cam.Parent = self.PlayerViewport
		self.PlayerViewport.CurrentCamera = cam
	end)

	-- TabBar (rolável horizontalmente para mobile)
	self.TabBar = New("ScrollingFrame", {
		Name                 = "TabBar",
		Size                 = UDim2.new(1, -20, 0, 40),
		Position             = UDim2.new(0, 10, 0, 130),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ScrollBarThickness   = 0,
		ScrollBarImageTransparency = 1,
		CanvasSize           = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize  = Enum.AutomaticSize.X,
		ZIndex               = 3,
	}, self.MainFrame)

	local tabList = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
	}, self.TabBar)
	List(tabList, Enum.FillDirection.Horizontal, 8)

	-- Área de conteúdo com scroll (otimizada para mobile)
	self.ContentArea = New("ScrollingFrame", {
		Name                 = "ContentArea",
		Size                 = UDim2.new(1, -20, 1, -190),
		Position             = UDim2.new(0, 10, 0, 178),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ScrollBarThickness   = 3,
		ScrollBarImageColor3 = CONFIG.PrimaryColor,
		ScrollBarImageTransparency = 0.5,
		CanvasSize           = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize  = Enum.AutomaticSize.Y,
		ZIndex               = 3,
		ClipsDescendants     = true,
	}, self.MainFrame)

	-- Padding interno do content area
	Pad(self.ContentArea, 4, 4, 8, 4)

	self._tabs      = {}
	self._pages     = {}
	self._activeTab = nil
	self._tabList   = tabList

	-- Iniciar digitação
	StartTyping(self.TitleLabel, CONFIG.Title)

	-- Drag da janela
	SetupWindowDrag(self.Header, self.MainFrame)

	-- Botão flutuante (maior para mobile)
	self.ToggleButton = New("ImageButton", {
		Name                   = "ToggleButton",
		Size                   = UDim2.new(0, 56, 0, 56),
		Position               = UDim2.new(0, 16, 1, -80),
		BackgroundColor3       = CONFIG.PrimaryColor,
		BackgroundTransparency = 0.15,
		Image                  = "rbxassetid://" .. CONFIG.ToggleButtonImageId,
		ImageTransparency      = 0.05,
		BorderSizePixel        = 0,
		ZIndex                 = 10,
	}, self.ScreenGui)
	Corner(self.ToggleButton, 15)
	Stroke(self.ToggleButton, CONFIG.PrimaryColor, 1.5, 0.3)

	self.ToggleButton.MouseEnter:Connect(function()
		Tween(self.ToggleButton, 0.15, nil, nil, {
			Size = UDim2.new(0, 60, 0, 60),
			BackgroundTransparency = 0
		})
	end)
	self.ToggleButton.MouseLeave:Connect(function()
		Tween(self.ToggleButton, 0.15, nil, nil, {
			Size = UDim2.new(0, 56, 0, 56),
			BackgroundTransparency = 0.15
		})
	end)

	SetupButtonDrag(self.ToggleButton, ToggleUI)
	SetupChatCommand()

	-- Animação de entrada
	task.wait(0.05)
	Tween(self.MainFrame, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
		Size = UDim2.new(0, W, 0, H)
	})

	-- Mostrar banner
	self:PrintBanner()

	return self
end

-- ══════════════════════════════════════════════════════════════
--  PRINT COM BANNER ASCII
-- ══════════════════════════════════════════════════════════════
function NexusLib:PrintBanner()
	local banner = [[
  _____                   _         _       _           _   
 |  __ \                 | |       (_)     (_)         | |  
 | |  | | ___   ___ _ __ | |_ ___   _ _ __  _  ___  ___| |_ 
 | |  | |/ _ \ / _ \ '_ \| __/ _ \ | | '_ \| |/ _ \/ __| __|
 | |__| | (_) |  __/ | | | ||  __/ | | | | | |  __/ (__| |_ 
 |_____/ \___/ \___|_| |_|\__\___| |_|_| |_| |\___|\___|\__|
                                          _/ |              
                                         |__/               
    ]]

	print(banner)
	print("")
	print("╔════════════════════════════════════════════════════════════════╗")
	print("║                    DoenteLib v3.0 Carregado!                   ║")
	print("╠════════════════════════════════════════════════════════════════╣")
	print("║  • Título: " .. string.sub(CONFIG.Title .. string.rep(" ", 35), 1, 35) .. "║")
	print("║  • Subtítulo: " .. string.sub(CONFIG.Subtitle .. string.rep(" ", 33), 1, 33) .. "║")
	print("║  • 3 cliques no botão para esconder/mostrar a UI               ║")
	print("║  • Mobile-First + Scroll otimizado                             ║")
	print("╚════════════════════════════════════════════════════════════════╝")
	print("")
end

-- ══════════════════════════════════════════════════════════════
--  ABAS
-- ══════════════════════════════════════════════════════════════
function NexusLib:AddTab(name, icon)
	icon = icon or "☰"

	local page = New("Frame", {
		Name              = "Page_" .. name,
		Size              = UDim2.new(1, 0, 0, 0),
		AutomaticSize     = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible           = false,
	}, self.ContentArea)

	local pageList = List(page, Enum.FillDirection.Vertical, 8)
	pageList.Padding = UDim.new(0, 8)

	local btn = New("TextButton", {
		Name                   = "Tab_" .. name,
		Size                   = UDim2.new(0, 0, 1, 0),
		AutomaticSize          = Enum.AutomaticSize.X,
		BackgroundColor3       = CONFIG.ElementColor,
		BackgroundTransparency = 0.4,
		Text                   = icon .. " " .. name,
		TextColor3             = CONFIG.TextColorSecondary,
		TextSize               = 12,
		Font                   = Enum.Font.GothamSemibold,
		BorderSizePixel        = 0,
		ZIndex                 = 4,
	}, self._tabList)
	Corner(btn, 8)
	Pad(btn, 8, 12, 8, 12)
	Stroke(btn, CONFIG.PrimaryColor, 1, 0.75)

	local function Activate()
		for _, d in pairs(self._tabs) do
			Tween(d.btn, 0.15, nil, nil, {
				BackgroundTransparency = 0.5,
				TextColor3 = CONFIG.TextColorSecondary,
			})
			local s = d.btn:FindFirstChildOfClass("UIStroke")
			if s then s.Transparency = 0.75 end
			d.page.Visible = false
		end
		Tween(btn, 0.15, nil, nil, {
			BackgroundTransparency = 0,
			TextColor3 = CONFIG.TextColor,
		})
		local s = btn:FindFirstChildOfClass("UIStroke")
		if s then s.Transparency = 0.25 end
		page.Visible    = true
		self._activeTab = name

		-- Scroll para o topo ao trocar de aba
		self.ContentArea.CanvasPosition = Vector2.new(0, 0)
	end

	btn.MouseButton1Click:Connect(Activate)
	self._tabs[name]  = {btn = btn, page = page}
	self._pages[name] = page
	if self._activeTab == nil then Activate() end

	local Tab = {_page = page, _pageList = pageList}

	-- Toggle
	function Tab:AddToggle(opts)
		opts = opts or {}
		local lbl   = opts.Label    or "Toggle"
		local def   = opts.Default  or false
		local cb    = opts.Callback or function() end
		local state = def

		local cont = New("Frame", {
			Size             = UDim2.new(1, 0, 0, 48),
			BackgroundColor3 = CONFIG.ElementColor,
			BackgroundTransparency = 0.35,
			BorderSizePixel  = 0,
			ZIndex           = 4,
		}, page)
		Corner(cont, 10)
		Stroke(cont, CONFIG.PrimaryColor, 1, 0.65)
		Pad(cont, 0, 14, 0, 14)

		New("TextLabel", {
			Size = UDim2.new(1, -60, 1, 0),
			BackgroundTransparency = 1,
			Text = lbl,
			TextColor3 = CONFIG.TextColor,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
		}, cont)

		local track = New("Frame", {
			Size             = UDim2.new(0, 44, 0, 24),
			Position         = UDim2.new(1, -44, 0.5, -12),
			BackgroundColor3 = state and CONFIG.PrimaryColor or Color3.fromRGB(45, 45, 65),
			BorderSizePixel  = 0,
			ZIndex           = 5,
		}, cont)
		Corner(track, 12)

		local thumb = New("Frame", {
			Size             = UDim2.new(0, 20, 0, 20),
			Position         = state and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel  = 0,
			ZIndex           = 6,
		}, track)
		Corner(thumb, 10)

		New("TextButton", {
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 7,
		}, cont).MouseButton1Click:Connect(function()
			state = not state
			if state then
				Tween(track, 0.18, nil, nil, {BackgroundColor3 = CONFIG.PrimaryColor})
				Tween(thumb, 0.18, nil, nil, {Position = UDim2.new(1,-22,0.5,-10)})
			else
				Tween(track, 0.18, nil, nil, {BackgroundColor3 = Color3.fromRGB(45,45,65)})
				Tween(thumb, 0.18, nil, nil, {Position = UDim2.new(0,2,0.5,-10)})
			end
			cb(state)
		end)

		local ctrl = {}
		function ctrl:Set(v)
			state = v
			track.BackgroundColor3 = v and CONFIG.PrimaryColor or Color3.fromRGB(45,45,65)
			thumb.Position = v and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
			cb(state)
		end
		function ctrl:Get() return state end
		return ctrl
	end

	-- Slider
	function Tab:AddSlider(opts)
		opts = opts or {}
		local lbl    = opts.Label    or "Slider"
		local min    = opts.Min      or 0
		local max    = opts.Max      or 100
		local def    = opts.Default  or min
		local suffix = opts.Suffix   or ""
		local cb     = opts.Callback or function() end
		local value  = def

		local cont = New("Frame", {
			Size             = UDim2.new(1, 0, 0, 70),
			BackgroundColor3 = CONFIG.ElementColor,
			BackgroundTransparency = 0.35,
			BorderSizePixel  = 0,
			ZIndex           = 4,
		}, page)
		Corner(cont, 10)
		Stroke(cont, CONFIG.PrimaryColor, 1, 0.65)
		Pad(cont, 10, 14, 10, 14)

		New("TextLabel", {
			Size = UDim2.new(0.65,0,0,22),
			BackgroundTransparency = 1,
			Text = lbl,
			TextColor3 = CONFIG.TextColor,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
		}, cont)

		local valLbl = New("TextLabel", {
			Size = UDim2.new(0.35,0,0,22),
			Position = UDim2.new(0.65,0,0,0),
			BackgroundTransparency = 1,
			Text = tostring(value)..suffix,
			TextColor3 = CONFIG.SecondaryColor,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
		}, cont)

		local track = New("Frame", {
			Size = UDim2.new(1,0,0,8),
			Position = UDim2.new(0,0,0,34),
			BackgroundColor3 = Color3.fromRGB(35,35,55),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, cont)
		Corner(track, 4)

		local fill = New("Frame", {
			Size = UDim2.new((value-min)/(max-min),0,1,0),
			BackgroundColor3 = CONFIG.PrimaryColor,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, track)
		Corner(fill, 4)

		local thumb = New("Frame", {
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.new((value-min)/(max-min),-9,0.5,-9),
			BackgroundColor3 = Color3.new(1,1,1),
			BorderSizePixel = 0,
			ZIndex = 7,
		}, track)
		Corner(thumb, 9)

		local dragging = false
		local function Update(x)
			local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			value = math.floor(min + rel*(max-min) + 0.5)
			local pct = (value-min)/(max-min)
			fill.Size = UDim2.new(pct,0,1,0)
			thumb.Position = UDim2.new(pct,-9,0.5,-9)
			valLbl.Text = tostring(value)..suffix
			cb(value)
		end
		track.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch
				or i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				Update(i.Position.X)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
				or i.UserInputType == Enum.UserInputType.Touch) then
				Update(i.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch
				or i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)

		local ctrl = {}
		function ctrl:Set(v)
			value = math.clamp(v,min,max)
			local pct = (value-min)/(max-min)
			fill.Size = UDim2.new(pct,0,1,0)
			thumb.Position = UDim2.new(pct,-9,0.5,-9)
			valLbl.Text = tostring(value)..suffix
			cb(value)
		end
		function ctrl:Get() return value end
		return ctrl
	end

	-- Botão
	function Tab:AddButton(opts)
		opts = opts or {}
		local lbl = opts.Label    or "Botão"
		local cb  = opts.Callback or function() end
		local b = New("TextButton", {
			Size             = UDim2.new(1,0,0,48),
			BackgroundColor3 = CONFIG.PrimaryColor,
			BackgroundTransparency = 0.45,
			Text = lbl,
			TextColor3 = CONFIG.TextColor,
			TextSize = 13,
			Font = Enum.Font.GothamSemibold,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, page)
		Corner(b, 10)
		Stroke(b, CONFIG.PrimaryColor, 1, 0.35)
		b.MouseButton1Click:Connect(function()
			Tween(b, 0.08, nil, nil, {BackgroundTransparency = 0.1})
			task.wait(0.12)
			Tween(b, 0.15, nil, nil, {BackgroundTransparency = 0.45})
			cb()
		end)
		b.MouseEnter:Connect(function()
			Tween(b, 0.12, nil, nil, {BackgroundTransparency = 0.25})
		end)
		b.MouseLeave:Connect(function()
			Tween(b, 0.15, nil, nil, {BackgroundTransparency = 0.45})
		end)
		return b
	end

	-- TextBox
	function Tab:AddTextBox(opts)
		opts = opts or {}
		local lbl = opts.Label       or "Input"
		local ph  = opts.Placeholder or "Digite..."
		local cb  = opts.Callback    or function() end

		local cont = New("Frame", {
			Size = UDim2.new(1,0,0,70),
			BackgroundColor3 = CONFIG.ElementColor,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, page)
		Corner(cont, 10)
		Stroke(cont, CONFIG.PrimaryColor, 1, 0.65)
		Pad(cont, 10, 12, 10, 12)

		New("TextLabel", {
			Size = UDim2.new(1,0,0,18),
			BackgroundTransparency = 1,
			Text = lbl,
			TextColor3 = CONFIG.TextColorSecondary,
			TextSize = 11,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
		}, cont)

		local input = New("TextBox", {
			Size = UDim2.new(1,0,0,32),
			Position = UDim2.new(0,0,0,26),
			BackgroundColor3 = Color3.fromRGB(16,16,30),
			BackgroundTransparency = 0.1,
			Text = "",
			PlaceholderText = ph,
			PlaceholderColor3 = CONFIG.TextColorSecondary,
			TextColor3 = CONFIG.TextColor,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			ZIndex = 5,
			ClearTextOnFocus = false,
		}, cont)
		Corner(input, 6)
		Pad(input, 0, 8, 0, 8)
		input.FocusLost:Connect(function(enter)
			cb(input.Text, enter)
		end)
		return input
	end

	-- Dropdown (CORRIGIDO - funcionando)
	function Tab:AddDropdown(opts)
		opts = opts or {}
		local lbl  = opts.Label    or "Dropdown"
		local list = opts.Options  or {"Opção 1"}
		local def  = opts.Default  or list[1]
		local cb   = opts.Callback or function() end
		local sel, open = def, false

		local cont = New("Frame", {
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundColor3 = CONFIG.ElementColor,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 4,
			ClipsDescendants = false,
			AutomaticSize = Enum.AutomaticSize.None,
		}, page)
		Corner(cont, 10)
		Stroke(cont, CONFIG.PrimaryColor, 1, 0.65)
		Pad(cont, 10, 12, 10, 12)

		-- Label
		New("TextLabel", {
			Size = UDim2.new(0.4, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = lbl,
			TextColor3 = CONFIG.TextColor,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
		}, cont)

		-- Botão de seleção
		local selectBtn = New("TextButton", {
			Size = UDim2.new(0.55, -10, 1, -8),
			Position = UDim2.new(0.45, 0, 0, 4),
			BackgroundColor3 = CONFIG.BackgroundColor,
			BackgroundTransparency = 0.3,
			Text = sel,
			TextColor3 = CONFIG.TextColor,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, cont)
		Corner(selectBtn, 8)
		Stroke(selectBtn, CONFIG.PrimaryColor, 1, 0.5)

		-- Seta
		local arrow = New("TextLabel", {
			Name = "Arrow",
			Size = UDim2.new(0, 20, 1, 0),
			Position = UDim2.new(1, -22, 0, 0),
			BackgroundTransparency = 1,
			Text = "▾",
			TextColor3 = CONFIG.TextColorSecondary,
			TextSize = 14,
			ZIndex = 6,
		}, selectBtn)

		-- Painel de opções
		local panel = New("Frame", {
			Name = "DropPanel",
			Size = UDim2.new(0.55, -10, 0, 0),
			Position = UDim2.new(0.45, 0, 0, 44),
			BackgroundColor3 = CONFIG.HeaderColor,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 50,
			ClipsDescendants = true,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, cont)
		Corner(panel, 8)
		Stroke(panel, CONFIG.PrimaryColor, 1, 0.45)

		-- Container rolável para as opções
		local scrollFrame = New("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = CONFIG.PrimaryColor,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 51,
		}, panel)
		Corner(scrollFrame, 8)

		local optionsList = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, scrollFrame)
		List(optionsList, Enum.FillDirection.Vertical, 3)
		Pad(optionsList, 6, 6, 6, 6)

		-- Criar opções
		local optionButtons = {}
		for i, opt in ipairs(list) do
			local ob = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = CONFIG.ElementColor,
				BackgroundTransparency = 0.45,
				Text = opt,
				TextColor3 = CONFIG.TextColor,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				BorderSizePixel = 0,
				ZIndex = 52,
			}, optionsList)
			Corner(ob, 6)

			ob.MouseButton1Click:Connect(function()
				sel = opt
				selectBtn.Text = opt
				open = false
				panel.Visible = false
				arrow.Text = "▾"
				cont.Size = UDim2.new(1, 0, 0, 48)
				cb(opt)
			end)

			ob.MouseEnter:Connect(function()
				Tween(ob, 0.1, nil, nil, {BackgroundTransparency = 0.1})
			end)
			ob.MouseLeave:Connect(function()
				Tween(ob, 0.1, nil, nil, {BackgroundTransparency = 0.45})
			end)

			optionButtons[opt] = ob
		end

		-- Atualizar canvas do scroll
		task.defer(function()
			local totalHeight = #list * 37 + 12
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
		end)

		-- Abrir/fechar dropdown
		selectBtn.MouseButton1Click:Connect(function()
			if open then
				open = false
				panel.Visible = false
				arrow.Text = "▾"
				cont.Size = UDim2.new(1, 0, 0, 48)
			else
				open = true
				panel.Visible = true
				arrow.Text = "▴"
				local panelHeight = math.min(#list * 37 + 12, 200)
				panel.Size = UDim2.new(0.55, -10, 0, panelHeight)
				cont.Size = UDim2.new(1, 0, 0, 48 + panelHeight)
			end
		end)

		-- Fecha dropdown ao clicar fora
		local function closeDropdown()
			if open then
				open = false
				panel.Visible = false
				arrow.Text = "▾"
				cont.Size = UDim2.new(1, 0, 0, 48)
			end
		end

		-- Detecta clique fora
		local screenGui = cont:FindFirstAncestorOfClass("ScreenGui")
		if screenGui then
			local inputConnection
			inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				if not open then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or 
					input.UserInputType == Enum.UserInputType.Touch then
					local mouse = LocalPlayer:GetMouse()
					if mouse and mouse.Target then
						local isInside = mouse.Target:IsDescendantOf(cont)
						if not isInside then
							closeDropdown()
						end
					end
				end
			end)

			cont.AncestryChanged:Connect(function()
				if not cont.Parent and inputConnection then
					inputConnection:Disconnect()
				end
			end)
		end

		local ctrl = {}
		function ctrl:Set(v)
			if optionButtons[v] then
				sel = v
				selectBtn.Text = v
				cb(v)
			end
		end
		function ctrl:Get()
			return sel
		end
		function ctrl:Close()
			closeDropdown()
		end
		function ctrl:AddOption(opt)
			table.insert(list, opt)
			local ob = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = CONFIG.ElementColor,
				BackgroundTransparency = 0.45,
				Text = opt,
				TextColor3 = CONFIG.TextColor,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				BorderSizePixel = 0,
				ZIndex = 52,
			}, optionsList)
			Corner(ob, 6)

			ob.MouseButton1Click:Connect(function()
				sel = opt
				selectBtn.Text = opt
				open = false
				panel.Visible = false
				arrow.Text = "▾"
				cont.Size = UDim2.new(1, 0, 0, 48)
				cb(opt)
			end)

			ob.MouseEnter:Connect(function()
				Tween(ob, 0.1, nil, nil, {BackgroundTransparency = 0.1})
			end)
			ob.MouseLeave:Connect(function()
				Tween(ob, 0.1, nil, nil, {BackgroundTransparency = 0.45})
			end)

			optionButtons[opt] = ob

			local totalHeight = #list * 37 + 12
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
		end

		return ctrl
	end

	-- Label / seção
	function Tab:AddLabel(text, style)
		if style == "section" then
			local f = New("Frame", {
				Size = UDim2.new(1,0,0,28),
				BackgroundTransparency = 1,
				ZIndex = 4,
			}, page)
			New("Frame", {
				Size = UDim2.new(0.3,0,0,1),
				Position = UDim2.new(0,0,0.5,0),
				BackgroundColor3 = CONFIG.PrimaryColor,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, f)
			New("TextLabel", {
				Size = UDim2.new(0.4,0,1,0),
				Position = UDim2.new(0.3,0,0,0),
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = CONFIG.TextColorSecondary,
				TextSize = 11,
				Font = Enum.Font.GothamSemibold,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 5,
			}, f)
			New("Frame", {
				Size = UDim2.new(0.3,0,0,1),
				Position = UDim2.new(0.7,0,0.5,0),
				BackgroundColor3 = CONFIG.PrimaryColor,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, f)
		else
			New("TextLabel", {
				Size = UDim2.new(1,0,0,24),
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = CONFIG.TextColor,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 4,
			}, page)
		end
	end

	-- Retrato
	function Tab:AddPortrait(opts)
		opts = opts or {}
		local lbl      = opts.Label       or "Retrato"
		local assetId  = opts.AssetId     or "6023426952"
		local size     = opts.Size        or 120
		local rounded  = opts.Rounded     or false
		local callback = opts.Callback    or function() end

		local cont = New("Frame", {
			Size = UDim2.new(1, 0, 0, size + (lbl and lbl ~= "" and 40 or 15)),
			BackgroundColor3 = CONFIG.ElementColor,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, page)
		Corner(cont, 12)
		Stroke(cont, CONFIG.PrimaryColor, 1, 0.65)
		Pad(cont, 12, 12, 12, 12)

		if lbl and lbl ~= "" then
			New("TextLabel", {
				Size = UDim2.new(1, 0, 0, 22),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = lbl,
				TextColor3 = CONFIG.TextColor,
				TextSize = 13,
				Font = Enum.Font.GothamSemibold,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 5,
			}, cont)
		end

		local imgY = (lbl and lbl ~= "") and 28 or 0
		local imgContainer = New("Frame", {
			Name = "PortraitContainer",
			Size = UDim2.new(0, size, 0, size),
			Position = UDim2.new(0.5, -size/2, 0, imgY),
			BackgroundColor3 = CONFIG.BackgroundColor,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ZIndex = 5,
			ClipsDescendants = true,
		}, cont)

		if rounded then
			Corner(imgContainer, size/2)
		else
			Corner(imgContainer, 14)
		end

		local image = New("ImageLabel", {
			Name = "PortraitImage",
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://" .. tostring(assetId),
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = 6,
		}, imgContainer)

		if rounded then
			Stroke(image, CONFIG.PrimaryColor, 2, 0.4)
		end

		if callback then
			local clickBtn = New("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				ZIndex = 7,
			}, imgContainer)

			clickBtn.MouseButton1Click:Connect(function()
				Tween(clickBtn, 0.08, nil, nil, {BackgroundTransparency = 0.8})
				task.wait(0.1)
				Tween(clickBtn, 0.15, nil, nil, {BackgroundTransparency = 1})
				callback(assetId)
			end)
		end

		local ctrl = {}

		function ctrl:SetImage(newAssetId)
			assetId = newAssetId
			image.Image = "rbxassetid://" .. tostring(assetId)
		end

		function ctrl:GetImage()
			return assetId
		end

		function ctrl:SetSize(newSize)
			size = newSize
			imgContainer.Size = UDim2.new(0, size, 0, size)
			imgContainer.Position = UDim2.new(0.5, -size/2, 0, imgY)
			if rounded then
				Corner(imgContainer, size/2)
			end
			cont.Size = UDim2.new(1, 0, 0, size + (lbl and lbl ~= "" and 40 or 15))
		end

		return ctrl
	end

	return Tab
end

-- ══════════════════════════════════════════════════════════════
--  NOTIFICAÇÃO
-- ══════════════════════════════════════════════════════════════
function NexusLib:Notify(opts)
	opts = opts or {}
	local title    = opts.Title    or "Aviso"
	local message  = opts.Message  or ""
	local duration = opts.Duration or 3
	local ntype    = opts.Type     or "info"

	local colors = {
		info    = CONFIG.PrimaryColor,
		success = Color3.fromRGB(34, 197, 94),
		warning = Color3.fromRGB(234, 179, 8),
		error   = Color3.fromRGB(239, 68, 68),
	}
	local color = colors[ntype] or CONFIG.PrimaryColor

	local notif = New("Frame", {
		Size = UDim2.new(0, 300, 0, 70),
		Position = UDim2.new(1, 20, 1, -100),
		BackgroundColor3 = CONFIG.HeaderColor,
		BorderSizePixel = 0,
		ZIndex = 100,
	}, self.ScreenGui)
	Corner(notif, 12)
	Stroke(notif, color, 1.5, 0.3)

	New("Frame", {
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 101,
	}, notif)

	New("TextLabel", {
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.new(0, 14, 0, 8),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = CONFIG.TextColor,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 101,
	}, notif)

	New("TextLabel", {
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.new(0, 14, 0, 36),
		BackgroundTransparency = 1,
		Text = message,
		TextColor3 = CONFIG.TextColorSecondary,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 101,
	}, notif)

	Tween(notif, 0.4, nil, nil, {Position = UDim2.new(1, -320, 1, -100)})

	task.delay(duration, function()
		local t = Tween(notif, 0.4, nil, nil, {Position = UDim2.new(1, 20, 1, -100)})
		t.Completed:Connect(function()
			notif:Destroy()
		end)
	end)
end

-- ══════════════════════════════════════════════════════════════
--  FUNÇÕES PÚBLICAS
-- ══════════════════════════════════════════════════════════════

function NexusLib:SetTitle(newTitle)
	CONFIG.Title = newTitle
	StartTyping(self.TitleLabel, newTitle)
end

function NexusLib:SetSubtitle(newSubtitle)
	CONFIG.Subtitle = newSubtitle
	if self.SubtitleLabel then
		self.SubtitleLabel.Text = newSubtitle
	end
end

function NexusLib:SetThemeColor(color)
	CONFIG.PrimaryColor   = color
	CONFIG.SecondaryColor = Color3.new(
		math.min(color.R + 0.14, 1),
		math.min(color.G + 0.14, 1),
		math.min(color.B + 0.14, 1)
	)
	if self.ToggleButton then
		Tween(self.ToggleButton, 0.3, nil, nil, {BackgroundColor3 = color})
	end
end

function NexusLib:SetBackgroundImage(assetId, transparency)
	CONFIG.BackgroundImageId = tostring(assetId)
	if self.BgImage then
		self.BgImage.Image = "rbxassetid://" .. CONFIG.BackgroundImageId
		if transparency ~= nil then
			self.BgImage.ImageTransparency = transparency
		end
	end
end

function NexusLib:SetLogo(assetId)
	CONFIG.LogoAssetId = tostring(assetId)
	if self.LogoImage then
		self.LogoImage.Image = "rbxassetid://" .. CONFIG.LogoAssetId
	end
end

function NexusLib:SetToggleButtonImage(assetId)
	CONFIG.ToggleButtonImageId = tostring(assetId)
	if self.ToggleButton then
		self.ToggleButton.Image = "rbxassetid://" .. CONFIG.ToggleButtonImageId
	end
end

-- ══════════════════════════════════════════════════════════════
return NexusLib
-- ══════════════════════════════════════════════════════════════