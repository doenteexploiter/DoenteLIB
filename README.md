# 📦 Doente UI Library – Documentation

A clean, customizable, and mobile-friendly UI library for Roblox.

---

## 🚀 Getting Started

Load the library:

```lua
local NexusLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/doenteexploiter/DoenteLIB/refs/heads/main/DoenteLib.lua"))()
local Window   = NexusLib.new()
```

Display the intro banner:

```lua
Window:PrintBanner()
```

---

## 🎨 Window Customization

You can fully customize the UI appearance:

```lua
Window:SetTitle("Doente UILib")
Window:SetSubtitle("by Mlk_doente70 • BETA")
Window:SetThemeColor(Color3.fromRGB(0, 0, 0))
Window:SetBackgroundImage("135051969494454", 0.4)
Window:SetLogo("124817743118691")
Window:SetToggleButtonImage("75336481759342")
```

### Options Explained

| Function                 | Description                                        |
| ------------------------ | -------------------------------------------------- |
| `SetTitle()`             | Changes the main title (restarts typing animation) |
| `SetSubtitle()`          | Sets a subtitle below the title                    |
| `SetThemeColor()`        | Main UI color                                      |
| `SetBackgroundImage()`   | Background image + transparency                    |
| `SetLogo()`              | Logo at the top                                    |
| `SetToggleButtonImage()` | Floating button icon                               |

---

## 📑 Tabs

Create tabs to organize your UI:

```lua
local Home   = Window:AddTab("Home", "")
local Config = Window:AddTab("Config", "⚙")
```

---

## 🧾 UI Components

### 🔤 TextBox

```lua
local textBox = Config:AddTextBox({
	Label = "Player Name",
	Placeholder = "Enter name...",
	Callback = function(text, pressedEnter)
		if pressedEnter then
			print("Submitted:", text)
		end
	end
})
```

✔ Triggers when user presses Enter
✔ Returns text input

---

### 📋 Dropdown

```lua
local drop = Config:AddDropdown({
	Label = "Select Weapon",
	Options = {"AK-47", "M4A1", "Shotgun", "Sniper"},
	Default = "AK-47",
	Callback = function(selected)
		print("Selected:", selected)
	end
})
```

✔ Predefined options
✔ Default selection support

---

### 🔘 Toggle

```lua
Home:AddToggle({
	Label = "Speed Hack",
	Default = false,
	Callback = function(on)
		local hum = game.Players.LocalPlayer.Character
			and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = on and 100 or 16
		end
	end
})
```

✔ Boolean switch
✔ Ideal for enabling/disabling features

---

### 🎚 Slider

```lua
Home:AddSlider({
	Label = "Walk Speed",
	Min = 1,
	Max = 250,
	Default = 16,
	Suffix = " sp",
	Callback = function(value)
		local hum = game.Players.LocalPlayer.Character
			and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = value
		end
	end
})
```

✔ Adjustable numeric values
✔ Supports suffix display

---

### 🔘 Button

```lua
Home:AddButton({
	Label = "Teleport Spawn",
	Callback = function()
		local char = game.Players.LocalPlayer.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)
		end
	end
})
```

✔ Executes actions on click

---

## 🔔 Notifications

Display messages to the user:

```lua
Window:Notify({
	Title = "Title",
	Message = "Message here",
	Type = "info", -- info / success / error
	Duration = 4
})
```

### Example

```lua
Window:Notify({
	Title = "DoenteLib",
	Message = "Script loaded successfully!",
	Type = "info",
	Duration = 4
})
```

---

## ✅ Features Summary

* 📱 Mobile-friendly UI
* 🎨 Fully customizable
* 📑 Tab system
* 🔧 Multiple UI components
* 🔔 Built-in notifications
* ⚡ Lightweight and easy to use

---

## 📌 Notes

* Make sure the script runs on the **client side** (LocalScript).
* Asset IDs must be valid Roblox assets.
* Always check if the character exists before modifying it.

---

## 💡 Tips

* Use tabs to separate features (Combat, Visuals, Config, etc.)
* Keep UI simple for better mobile performance
* Avoid excessive callbacks for smoother execution

---

## 📜 License

Free to use. Modify as needed.

---

Enjoy building your UI 🚀
