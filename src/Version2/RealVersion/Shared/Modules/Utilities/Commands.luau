local Commands = {}

local folder = game.ReplicatedStorage.Test -- change folder if needed

for _, module in ipairs(folder:GetChildren()) do
	if module:IsA("ModuleScript") then
		local source = module.Source

		-- Detect table name
		local tableName = source:match("local%s+([%w_]+)%s*=%s*{%s*}")

		if tableName then
			-- Match constructor (works with () or (Config))
			local constructorPattern = "function%s+" .. tableName .. "%.new%([^%)]*%)%s*(.-)%s*return%s+self%s*end"

			local body = source:match(constructorPattern)

			-- Skip if Update already exists
			if body and not source:find("function%s+" .. tableName .. ":Update") then
				local constructorLines = {}
				local updateLines = {}

				for line in body:gmatch("[^\r\n]+") do
					local clean = line:match("^%s*(.-)%s*$")

					if clean ~= "" and not clean:find("setmetatable") then
						-- Detect submodule creation
						if clean:find("%.new%(") then
							table.insert(constructorLines, "\t" .. clean)

							local varName = clean:match("self%.([%w_]+)%s*=")

							if varName then
								table.insert(updateLines, "\tself." .. varName .. ":Update(Config)")
							end
						else
							-- Regular property assignment
							table.insert(updateLines, "\t" .. clean)
						end
					end
				end

				-- Build new constructor
				local newConstructor = string.format(
					"function %s.new(Config)\n\tlocal self = setmetatable({}, %s)\n%s\treturn self\nend",
					tableName,
					tableName,
					#constructorLines > 0 and table.concat(constructorLines, "\n") .. "\n" or ""
				)

				-- Build Update function
				local newUpdate =
					string.format("function %s:Update(Config)\n\t\n%s\nend", tableName, table.concat(updateLines, "\n"))

				local replacement = newConstructor .. "\n\n" .. newUpdate

				module.Source = source:gsub(constructorPattern, replacement)
			end
		end
	end
end

return Commands
