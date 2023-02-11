-- NoFreefall Rewrite
-- MisterPhilo
-- Created January 23, 2022
-- Rewritten January 15, 2023

local NoFreefall = {}

local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local BezierTweens = require(script.BezierTweens)
local Waypoints = BezierTweens.Waypoints
local SGEffects = require(script.SGEffects)
local Effects = Instance.new("Folder")
Effects.Parent = workspace
Effects.Name = "EffectsFolder"

PhysicsService:RegisterCollisionGroup("FreefallPlayers")

local PointsFolder = workspace:WaitForChild("Points")

local startSound = "rbxassetid://9065060568"
local endSound = "rbxassetid://9065062241"

local collisions = {}
local Parts = {}

local function nearestToChar(position, group)
	local closestPart, closestPartMagnitude

	local tmpMagnitude
	for i, v in pairs(group:GetChildren()) do
		if closestPart then
			tmpMagnitude = (position - v.Position).magnitude

			if tmpMagnitude < closestPartMagnitude then
				closestPart = v
				closestPartMagnitude = tmpMagnitude
			end
		else
			closestPart = v
			closestPartMagnitude = (position - v.Position).magnitude
		end
	end
	return closestPart
end

local function roundVector(vector, unit)
	return vector - Vector3.new(vector.X % unit, vector.Y % unit, vector.Z % unit)
end

local function clearParts()
	for i = 1, #Parts do
		Parts[i]:Destroy()
	end
	Parts = {}
end

local function poof(char)
	local poofTemplate = Instance.new("Part")
	poofTemplate.Position = char:WaitForChild("HumanoidRootPart").Position
	poofTemplate.Anchored = true
	poofTemplate.CanCollide = false
	poofTemplate.Transparency = 1
	poofTemplate.CastShadow = false

	for i = 1, 50 do
		local Clone = poofTemplate:Clone()
		Clone.Parent = workspace:WaitForChild("Effects")
		Clone.Material = Enum.Material.SmoothPlastic
		Clone.BrickColor = BrickColor.random()
		Clone.Transparency = 0
		Clone.Name = "Effect"
		local SO = SGEffects:ScatterOut(Clone)
		local SF = SGEffects:SizeFactor(Clone)
		SO:Play()
		SF:Play()
	end
	poofTemplate:Destroy()
end

local function visChar(char, value)
	for _, p in pairs(char:GetDescendants()) do
		if (p:IsA("BasePart") or p:IsA("Decal")) and p.Name ~= "HumanoidRootPart" then
			p.Transparency = value
		end
	end
end

local function effects(char, bool)
	local HRP = char:WaitForChild("HumanoidRootPart")
	if bool == "create" then
		local Trail = Instance.new("Trail")
		Trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
		Trail.FaceCamera = true
		Trail.LightEmission = 1
		Trail.LightInfluence = 1
		Trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.0149, 0),
			NumberSequenceKeypoint.new(1, 0),
		})
		Trail.Enabled = true
		Trail.Lifetime = 0.5
		Trail.MaxLength = 0
		Trail.MinLength = 0.05
		Trail.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.0379, 0.594),
			NumberSequenceKeypoint.new(0.2, 0.856),
			NumberSequenceKeypoint.new(0.8, 0.85),
			NumberSequenceKeypoint.new(0.916, 0.65),
			NumberSequenceKeypoint.new(1, 0),
		})

		local attachment0 = Instance.new("Attachment", HRP)
		attachment0.Position = Vector3.new(1, 0, 0)
		attachment0.Name = "A0"

		local attachment1 = Instance.new("Attachment", HRP)
		attachment1.Position = Vector3.new(-1, 0, 0)
		attachment1.Name = "A1"

		Trail.Parent = HRP
		Trail.Attachment0 = attachment0
		Trail.Attachment1 = attachment1
	elseif bool == "destroy" then
		HRP:WaitForChild("Trail"):Destroy()
		HRP:WaitForChild("A0"):Destroy()
		HRP:WaitForChild("A1"):Destroy()
	end
end

local function bezierInfo(part, waypoints, style, direction, t)
	local newTween = BezierTweens.Create(part, {
		Waypoints = waypoints,
		EasingStyle = style or Enum.EasingStyle.Sine,
		EasingDirection = direction or Enum.EasingDirection.In,
		Time = t or 5,
	})

	return newTween
end

local function collisions(char, bool)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("Part") or part:IsA("MeshPart") then
			if bool == true then
				part.CollisionGroup = "FreefallPlayers"
			end
			if bool == false then
				part.CollisionGroup = "Default"
			end
		end
	end
end

function NoFreefall:Fire(char)
	if char then
		if char:GetAttribute("IsFreefall") == true then
			warn("Freefall is already active.")
			return
		end
		char:SetAttribute("IsFreefall", true)
		local HRP = char:WaitForChild("HumanoidRootPart")

		local Sound = Instance.new("Sound", HRP)

		local endPos = nearestToChar(HRP.Position, PointsFolder).Position
		local startPos = HRP.Position + Vector3.new(0, 0, -3)
		local Control = (HRP.Position + Vector3.new(startPos.X - endPos.X, 200, startPos.Z - endPos.Z))

		local waypoints = Waypoints.new(startPos, Control, endPos)

		local BP = Instance.new("BodyPosition", HRP)
		BP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		BP.D = 1800
		BP.P = 20000
		BP.Position = HRP.Position

		local tween = bezierInfo(BP, waypoints)

		collisions(char, true)
		poof(char)
		effects(char, "create")
		visChar(char, 1)

		Sound.SoundId = startSound
		Sound:Play()
		tween:Play()

		tween.Completed:Wait()

		Sound.SoundId = endSound
		Sound.PlayOnRemove = true

		repeat
			BP.P += 100
			task.wait(0.01)
		until roundVector(HRP.Position, 1) == roundVector(endPos, 1)

		BP:Destroy()
		Sound:Destroy()
		poof(char)
		effects(char, "destroy")
		visChar(char, 0)

		char:SetAttribute("IsFreefall", false)
		collisions(char, false)
		task.wait(3)
		clearParts()
	else
		warn("You didn't input a valid character instance.")
	end
end

return NoFreefall
