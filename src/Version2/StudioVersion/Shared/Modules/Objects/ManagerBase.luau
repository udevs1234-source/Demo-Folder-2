local ManagerBase = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local TableUtils = require(Registry.Shared.Modules.TableUtils)

ManagerBase.__index = ManagerBase

function ManagerBase.new()
	local self = setmetatable({}, ManagerBase)
	self.Storage = {}
	return self
end

function ManagerBase:StoreObject(Path, Object)
	TableUtils.SetValueAtPath(self.Storage, Path, Object or {})
end

function ManagerBase:StoreObjects(Paths, Objects)
	if not Paths then
		return
	end
	if #Paths == 0 then
		return
	end
	if not Objects then
		for i = 1, #Paths do
			self:StoreObject(Paths[i], {})
		end
	elseif #Paths == #Objects then
		for i = 1, #Paths do
			self:StoreObject(Paths[i], Objects[i])
		end
	else
		return
	end
end

function ManagerBase:GetObject(Path)
	return TableUtils.GetValueAtPath(self.Storage, Path)
end

function ManagerBase:GetAllObjects()
	return self.Storage
end

function ManagerBase:DestroyObject(Path)
	local Object = self:GetObject(Path)
	if not Object then
		return
	end
	if Object:IsA("Table") then
		table.clear(Object)
	elseif Object:IsA("BasePart") then
		Object:Destroy()
	end
	TableUtils.StoreObject(self.Storage, Path, nil)
end

function ManagerBase:DestroyAllObjects()
	self:DestroyObject(self.Storage)
end

function ManagerBase:RunFunctionForObject(Key, fn)
	fn(Key, self.Storage[Key])
end

function ManagerBase:RunFunctionForEach(fn)
	for Key, _ in pairs(self.Storage) do
		self:RunFunctionForObject(Key, fn)
	end
end

function ManagerBase:Cleanup()
	self.Storage = nil
end

return ManagerBase
