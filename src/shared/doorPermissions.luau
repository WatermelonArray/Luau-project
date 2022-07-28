--!strict

local class = {}

local perms: {[string]: number} = {

	--*["TeamName"] = 0  -- the id of rank

	["Visitor"] = 0,
	["Employees"] = 1,
	["Maintenance"] = 1,
	["Security"] = 2,
	["Raider"] = 2,
	["Administrator"] = 3,
	["Developer"] = 3

}

local colors: {[number]: BrickColor} = {

	--*[securityLevel] = BrickColor  -- the color of the security for cosmetic purposes

	[0] = BrickColor.new("White"),
	[1] = BrickColor.new("Bright orange"),
	[2] = BrickColor.new("Sand violet metallic"),
	[3] = BrickColor.new("Dark grey metallic"),

}

class.getColor = function(security: number) return colors[security] or BrickColor.new("Flame reddish orange") end

class.getSecurityPerms = function(client: Player, security: number)

	local team: Team? = client.Team :: Team

	if team then
		local teamString: string = team.Name

		local result = perms[teamString] or 0

		print(perms[teamString])
		print(security)
		print(result)
		print(perms[teamString] >= 1)

		print()

		if teamString then
			return result >= security
		end
	end

	return false
end

--! Backup of older work to revist later on storing BrickColor classes AND strings into memory. (Was not working as intended - therfor scrapped)
--[[
local perms: {[string|BrickColor]: number} = {

	--[BrickColor or "TeamName"] = 0  -- the id of rank

	[BrickColor.new("White")] = 0, -- Visitor
	[BrickColor.new("White")] = 2, -- Visitor              --## memory stores different intger of the same BrickColor value?
	["Security"] = 2,
	["Raider"] = 2,
	["Administrator"] = 3

}

-- This will return a boolean 
class.getSecurityPerms = function(client: Player, security: number)

	local team: Team? = client.Team :: Team
	local teamBrickColor: BrickColor = client.TeamColor :: BrickColor

	print(perms)
	
	print(teamBrickColor)

	if team then
		local teamString: string? = team.Name :: string
		if teamString and perms[teamString] then
			print(perms[teamString])
			return perms[teamString] >= security or perms[teamBrickColor] >= security
		end
	elseif perms[teamBrickColor] then
		return perms[teamBrickColor] >= security           --## result is that looking for BrickColor values would be assigned a new
--		                                                        value integer rather than looking up the Enum/Class value...?
	end

	return false
end
]]

return class