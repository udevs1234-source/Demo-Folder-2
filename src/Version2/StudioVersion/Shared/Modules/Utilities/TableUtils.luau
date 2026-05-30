local TableUtils = {}

-------- Path handling ---------
function TableUtils.NormalizePath(Path)
	if type(Path) == "string" then
		return Path:split(".")
	end
	if type(Path) == "table" then
		return Path
	end
	return {}
end

function TableUtils.GetValueAtPath(Table, Path)
	local PathKeys = TableUtils.NormalizePath(Path)
	local CurrentValue = Table
	for _, Key in ipairs(PathKeys) do
		if type(CurrentValue) ~= "table" then
			return nil
		end
		CurrentValue = CurrentValue[Key]
		if CurrentValue == nil then
			return nil
		end
	end
	return CurrentValue
end

function TableUtils.SetValueAtPath(Table, Path, Value)
	local PathKeys = TableUtils.NormalizePath(Path)
	local CurrentValue = Table
	for i, Key in ipairs(PathKeys) do
		if i == #PathKeys then
			CurrentValue[Key] = Value
		else
			if type(CurrentValue[Key]) ~= "table" then
				CurrentValue[Key] = {}
			end
			CurrentValue = CurrentValue[Key]
		end
	end
end

function TableUtils.CheckValueAtPath(Table, Path, Value)
	return TableUtils.GetValueAtPath(Table, Path) == Value
end

function TableUtils.IsPathExists(Table, Path)
	return TableUtils.GetValueAtPath(Table, Path) ~= nil
end

function TableUtils.GetOrSetIfNotAtPath(Table, Path, Value)
	local value = TableUtils.GetValueAtPath(Table, Path)
	if value then
		return value
	end
	if not value then
		TableUtils.SetValueAtPath(Table, Path, Value)
	end
	return Value
end

function TableUtils.Compare(tbl1, tbl2)
	if tbl1 == tbl2 then
		return true
	end
	for k, v in pairs(tbl1) do
		if tbl2[k] ~= v then
			return false
		end
	end
	for k, v in pairs(tbl2) do
		if tbl1[k] == nil then
			return false
		end
	end
	return true
end

function TableUtils.CombineLists(Lists)
	local CombinedList = {}
	for _, list in pairs(Lists) do
		for _, element in pairs(list) do
			table.insert(CombinedList, element)
		end
	end
	return CombinedList
end

function TableUtils.CombineDefaultWithNew(default, new)
	local correctTable = default
	for key, value in pairs(new) do
		correctTable[key] = value
	end
	return correctTable
end

return TableUtils
