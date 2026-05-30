local ProjectilePath = {}

local function GetPositionAtTime(Origin, Velocity, Direction: Vector3, Time, Gravity)
	local YVector = Vector3.new(0, Direction.Y, 0)
	local AxisVector = Direction:Cross(YVector):Cross(YVector)
	local Angle = AxisVector:Angle(Direction)
	local AxisPosition = AxisVector.Unit * Velocity * math.cos(Angle) * Time
	local YPosition = Velocity * math.sin(Angle) * Time - 1 / 2 * Gravity * (Time ^ 2)
	local Position = Origin + AxisPosition + YPosition
	return Position
end

local function GetPath(Origin, Direction, Velocity) end

return ProjectilePath
