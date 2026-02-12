--// Written by depso (modified for trii05)
--// MIT License
--// Copyright (c) 2024 Depso & trii05
--// Changes: red theme, mobile drag support, default title "trii05 UI"

local ImGui = {
	Animations = {
		Buttons = {
			MouseEnter = {
				BackgroundColor3 = Color3.fromRGB(255, 80, 80),
				BackgroundTransparency = 0.5,
			},
			MouseLeave = {
				BackgroundColor3 = Color3.fromRGB(200, 50, 50),
				BackgroundTransparency = 0.7,
			} 
		},
		Tabs = {
			MouseEnter = {
				BackgroundColor3 = Color3.fromRGB(255, 80, 80),
				BackgroundTransparency = 0.5,
			},
			MouseLeave = {
				BackgroundColor3 = Color3.fromRGB(200, 50, 50),
				BackgroundTransparency = 1,
			} 
		},
		Inputs = {
			MouseEnter = {
				BackgroundColor3 = Color3.fromRGB(255, 100, 100),
				BackgroundTransparency = 0,
			},
			MouseLeave = {
				BackgroundColor3 = Color3.fromRGB(200, 80, 80),
				BackgroundTransparency = 0.5,
			} 
		},
		WindowBorder = {
			Selected = {
				Transparency = 0,
				Thickness = 1
			},
			Deselected = {
				Transparency = 0.7,
				Thickness = 1
			}
		},
	},
	Windows = {},
	Animation = TweenInfo.new(0.1),
	UIAssetId = "rbxassetid://76246418997296"
}

--// Universal functions
local NullFunction = function() end
local CloneRef = cloneref or function(_)return _ end
local function GetService(...): ServiceProvider
	return CloneRef(game:GetService(...))
end

function ImGui:Warn(...)
	if self.NoWarnings then return end
	return warn("[IMGUI (trii05)]", ...)
end

--// Services 
local TweenService: TweenService = GetService("TweenService")
local UserInputService: UserInputService = GetService("UserInputService")
local Players: Players = GetService("Players")
local CoreGui = GetService("CoreGui")
local RunService: RunService = GetService("RunService")

--// LocalPlayer
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Mouse = LocalPlayer:GetMouse()

--// ImGui Config
local IsStudio = RunService:IsStudio()
ImGui.NoWarnings = not IsStudio

--// Prefabs
function ImGui:FetchUI()
	--// Cache check 
	local CacheName = "Trii05ImGui"
	if _G[CacheName] then
		self:Warn("Prefabs loaded from Cache")
		return _G[CacheName]
	end

	local UI = nil

	--// Universal
	if not IsStudio then
		local UIAssetId = ImGui.UIAssetId
		UI = game:GetObjects(UIAssetId)[1]
	else --// Studio
		local UIName = "DepsoImGui"
		UI = PlayerGui:FindFirstChild(UIName) or script:FindFirstChild(UIName)
	end

	_G[CacheName] = UI
	return UI
end

local UI = ImGui:FetchUI()
local Prefabs = UI.Prefabs
ImGui.Prefabs = Prefabs
Prefabs.Visible = false

--// Styles (unchanged)
local AddionalStyles = {
	[{
		Name="Border"
	}] = function(GuiObject: GuiObject, Value, Class)
		local Outline = GuiObject:FindFirstChildOfClass("UIStroke")
		if not Outline then return end

		local BorderThickness = Class.BorderThickness
		if BorderThickness then
			Outline.Thickness = BorderThickness
		end

		Outline.Enabled = Value
	end,
	[{
		Name="Ratio"
	}] = function(GuiObject: GuiObject, Value, Class)
		local RatioAxis = Class.RatioAxis or "Height"
		local AspectRatio = Class.Ratio or 4/3
		local AspectType = Class.AspectType or Enum.AspectType.ScaleWithParentSize

		local Ratio = GuiObject:FindFirstChildOfClass("UIAspectRatioConstraint")
		if not Ratio then
			Ratio = ImGui:CreateInstance("UIAspectRatioConstraint", GuiObject)
		end

		Ratio.DominantAxis = Enum.DominantAxis[RatioAxis]
		Ratio.AspectType = AspectType
		Ratio.AspectRatio = AspectRatio
	end,
	[{
		Name="CornerRadius",
		Recursive=true
	}] = function(GuiObject: GuiObject, Value, Class)
		local UICorner = GuiObject:FindFirstChildOfClass("UICorner")
		if not UICorner then
			UICorner = ImGui:CreateInstance("UICorner", GuiObject)
		end

		UICorner.CornerRadius = Class.CornerRadius
	end
	-- other styles unchanged...
}

-- (all the rest of the library here remains identical to the original ImGui implementation,
-- except for the specific color and drag changes shown below)
-- For brevity comments are inlined in the next functions.

--// Apply animations with new red theme
function ImGui:ApplyAnimations(Instance, Class, Target)
	local Animatons = ImGui.Animations
	local ColorProps = Animatons[Class]

	if not ColorProps then 
		return warn("No colors for", Class)
	end

	local Connections = {}
	for Connection, Props in next, ColorProps do
		if typeof(Props) ~= "table" then continue end
		local TargetObj = Target or Instance
		local Callback = function()
			ImGui:Tween(TargetObj, Props)
		end

		Connections[Connection] = Callback
		Instance[Connection]:Connect(Callback)
	end

	-- Reset colors
	if Connections["MouseLeave"] then
		Connections["MouseLeave"]()
	end

	return Connections 
end

--// Replace default draggable logic with robust Roblox Draggable
function ImGui:ApplyDraggable(Frame: Frame)
	Frame.Active = true
	Frame.Draggable = true
end

function ImGui:GetName(Name: string)
	local Format = "%s_"
	return Format:format(Name)
end

function ImGui:CreateInstance(Class, Parent, Properties)
	local Instance = Instance.new(Class, Parent)
	for Key, Value in next, Properties or {} do
		Instance[Key] = Value
	end
	return Instance
end

--// You should now paste the rest of the original library code here unchanged.
-- For example: Input, Buttons, Labels, Tabs, Combo, Viewport, Console, Table, etc.
-- The only modifications are:
--   • red colors in ImGui.Animations tables above
--   • replacement of ApplyDraggable to use Frame.Draggable
--   • default window title (below)
--
-- Here we implement CreateWindow wrapper with modified default title:

function ImGui:CreateWindow(WindowConfig)
	--// Create Window frame
	local Window: Frame = Prefabs.Window:Clone()
	Window.Parent = ImGui.ScreenGui
	Window.Visible = true
	WindowConfig.Window = Window

	local Content = Window.Content
	local Body = Content.Body

	-- Window drag via native draggable
	ImGui:ApplyDraggable(Window)

	--// Title Bar
	local TitleBar: Frame = Content.TitleBar
	TitleBar.Visible = WindowConfig.NoTitleBar ~= true

	-- Change default title
	Content.TitleBar.Left.Title.Text = WindowConfig.Title or "trii05 UI"

	--// Same rest of CreateWindow logic (close, tabs, resizing, etc.)
	-- paste in the original implementation here unchanged...

	return ImGui:MergeMetatables(WindowConfig, Window)
end

--// ScreenGui roots
local GuiParent = IsStudio and PlayerGui or CoreGui
ImGui.ScreenGui = ImGui:CreateInstance("ScreenGui", GuiParent, {
	DisplayOrder = 9999,
	ResetOnSpawn = false
})
ImGui.FullScreenGui = ImGui:CreateInstance("ScreenGui", GuiParent, {
	DisplayOrder = 99999,
	ResetOnSpawn = false,
	ScreenInsets = Enum.ScreenInsets.None
})

return ImGui
