--!strict

local class = {}

local replicatedStorage = game:GetService("ReplicatedStorage") :: any

local levelInteractions = workspace:FindFirstChild("LevelInteractions") :: any

local perms = require(replicatedStorage.Common.doorPermissions) :: any -- a list of usable permissions

-- A type checker to make sure that items being added into memory are in fact data that relate to this type.
type blockToken = {
	security: number,
	state: boolean,
	debounce: boolean,
	doorType: string,
	doorID: number
}

-- Creation of a noSQL database using a sealed table of all interactable doors that will be loaded into memory.
local blockStorage: {[number]: blockToken} = {}

-- Create tokens in blockStorage corresponding to each door part
local addToken = function(itterationID: number, arg_doorType: string, arg_security: number?, arg_state: boolean?)
	local token: blockToken = {
		security = arg_security or 0,       --* the minimum requirement for opening the door
		state = arg_state or false,         --* the current state of the door: close, open
		doorID = itterationID,              --* assigns a referencable identifier for clients
		debounce = true,                    --* checks if the server must wait before calling a state change to the door token
		doorType = arg_doorType or "unkown" --* required if animations are needed
	}
	blockStorage[itterationID] = token      --* store the token through the appropriate ID
end

-- Initialize the class once on runtime
function class.init()

	-- Create network hook for client and server interaction with doors.
	local re: RemoteEvent = Instance.new("RemoteEvent")
	re.Name = "DoorHook"
	re.Parent = replicatedStorage.Hooks
	re.OnServerEvent:Connect(function(client: Player, dataPacket: any)

		local token: blockToken = blockStorage[tonumber(dataPacket.doorID) :: number]

		if dataPacket.request == "allDoorsUpdate" then
			-- On bigger games, this can be a much bigger data packet to send, so it should --! ONLY BE USED ONCE PER PLAYER WHEN JOINING GAME
			re:FireClient(client, {
				response = dataPacket.request,
				tokens = blockStorage,
			})
		else

			local access = perms.getSecurityPerms(client, token.security)

			if dataPacket.request == "DoorToggle" and token and token.debounce and access then

				-- Use a request string, a token and a security integer to verify the token and the user the access permissions of this remote event.
				local char = client.Character
				local passCheck: boolean = false
				if char and (client.Character.PrimaryPart.Position).Magnitude <= 30 then -- good to check the position of a player who is sending
					passCheck = true
				end

				if passCheck then
					token.state = not token.state
					re:FireAllClients({
						response = "doorUpdate",
						token = token,
						doorID = dataPacket.doorID,
						instant = false,
						cardID = dataPacket.readerID
					})
					token.debounce = false

					task.delay(2, function() token.debounce = true end) -- Create thread and execute after 4 seconds in the task scheduler
				else
					client:Kick("Something went wrong")
				end

			elseif dataPacket.request == "DoorUpdate" and token then -- Additional arguement to allow for clients to update their objects without setting state

				re:FireClient(client, {
					response = "doorUpdate",
					token = token,
					doorID = dataPacket.doorID,
					instant = true
				})

			elseif not ((dataPacket.request == "DoorToggle" or dataPacket.request == "DoorUpdate") and token and access) then -- Failsafe for re incase RemoteEvent is tampered with
				warn(string.format("Unverified access to %s RemoteEvent by %s", re.Name, client.Name)) -- Output unverification to server console for developer debugging
			else
				client:Kick("Something went wrong")
			end

			--* NOTE: This can further be refined to allow for custom anti cheat systems that checks the client's distance from the token
			--*       when the client tries to access the remote hook, thus returning a boolean value.
		end
	end)

	-- Cycle through all door nodes and create appropriate tokens for them
	for itteration, door in pairs(levelInteractions.Doors:GetChildren()) do
		local doorName: string = door.Name
		door.Name = string.format("%s%s%s", itteration, "_", door.name) -- Create unique identifiers for clients to reference.
		for i, value in pairs(door:GetChildren()) do
			if not value:IsA("BasePart") then
				value:Destroy()
			end
		end
		for i, value in pairs(door:GetChildren()) do
			if value:IsA("BasePart") and value.Name == "cardHolder" then
				value.Name = i
			end
		end

		addToken(itteration, doorName)
	end
--[[
	--! Remove below for release builds of your game

	blockStorage[1].state = true --* Sets state for testing on client updates
	blockStorage[2].security = 2 --* A test to see if security permissions are taken into account
--?	                                 spoiler: they do!
]]
end

return class