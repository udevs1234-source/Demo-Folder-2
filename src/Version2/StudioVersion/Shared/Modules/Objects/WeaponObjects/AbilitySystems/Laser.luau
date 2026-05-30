local LaserAbilitySystem = {}
LaserAbilitySystem.__index = LaserAbilitySystem

local function GetAmmoContainer()
	return game.Workspace.Ammos
end

function LaserAbilitySystem.new(Config)
	local self = setmetatable({}, LaserAbilitySystem)
	self:Init(Config)
	return self
end

function LaserAbilitySystem:Init(Config)
	self.Beam = nil
	self.Cooldown = 0
end

function LaserAbilitySystem:Update(Config)
	self.Beam = Config.Beam
	self.Cooldown = Config.Cooldown
end

function LaserAbilitySystem:SetUpLaserSystem(Data)
	local Origin = Data.Origin
	local Beam = self.Beam
	local Cooldown = self.Cooldown

	local AmmoContainer = GetAmmoContainer()

	local function MakeAmmoFolder()
		local AmmoFolder = Instance.new("Folder")
		AmmoFolder.Name = "AmmoFolder"
		AmmoFolder.Parent = AmmoContainer

		local Attachment0 = Instance.new("Attachment")
		Attachment0.Name = "Attachment0"
		Attachment0.Parent = AmmoFolder

		local Attachment1 = Instance.new("Attachment")
		Attachment1.Name = "Attachment1"
		Attachment1.Parent = AmmoFolder

		local NewBeam = Instance.new("Beam")
		NewBeam.Name = "Beam"
		NewBeam.Enabled = false
		NewBeam.Parent = AmmoFolder
		NewBeam.Attachment0 = Attachment0
		NewBeam.Attachment1 = Attachment1

		-- Copy appearance properties from the template beam if provided
		if Beam then
			NewBeam.Color = Beam.Color
			NewBeam.Width0 = Beam.Width0
			NewBeam.Width1 = Beam.Width1
			NewBeam.Texture = Beam.Texture
			NewBeam.TextureSpeed = Beam.TextureSpeed
			NewBeam.FaceCamera = Beam.FaceCamera
		end

		return AmmoFolder
	end

	local function GetPoolCount()
		local Count = 0
		for _, Child in ipairs(AmmoContainer:GetChildren()) do
			if Child.Name == "AmmoFolder" then
				Count += 1
			end
		end
		return Count
	end

	local function GetAvailableAmmoFolder()
		for _, Child in ipairs(AmmoContainer:GetChildren()) do
			if Child.Name == "AmmoFolder" then
				local BeamInstance = Child:FindFirstChild("Beam") :: Beam
				if BeamInstance and not BeamInstance.Enabled then
					return Child
				end
			end
		end
		return nil
	end

	-- Initialize pool on first use
	local POOL_SIZE = 10
	if GetPoolCount() < POOL_SIZE then
		for i = GetPoolCount() + 1, POOL_SIZE do
			MakeAmmoFolder()
		end
	end

	-- Expand pool if all are in use
	local RequiredAmmoFolder = GetAvailableAmmoFolder()
	if not RequiredAmmoFolder then
		RequiredAmmoFolder = MakeAmmoFolder()
	end

	-- Position and fire the beam
	local BeamInstance = RequiredAmmoFolder.Beam :: Beam
	local Att0 = RequiredAmmoFolder.Attachment0 :: Attachment
	local Att1 = RequiredAmmoFolder.Attachment1 :: Attachment

	local HitPosition = Data.HitPosition
	local Direction = Data.Direction
	Att0.CFrame = CFrame.new(Origin)
	if HitPosition then
		Att1.CFrame = CFrame.new(HitPosition)
	end
	if Direction then
		Att1.CFrame = CFrame.new(Origin + Direction * 4)
	end
	BeamInstance.Enabled = true

	task.spawn(function()
		task.wait(Cooldown)
		BeamInstance.Enabled = false
	end)
end
function LaserAbilitySystem:OnHit(Data)
	if not Data.HitPosition then
		return
	end
	self:SetUpLaserSystem(Data)
end

function LaserAbilitySystem:OnShoot(Data)
	if not Data.Direction then
		return
	end
	self:SetUpLaserSystem(Data)
end

return LaserAbilitySystem
