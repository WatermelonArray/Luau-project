--!strict

local class: any = {}

-- A type checker to make sure that items being added into memory are in fact data that relate to this type.
type blockToken = {
	ref: Model,
	id: number,
	interact: RemoteEvent,
	originalCFrame: CFrame
}

-- Creation of a noSQL database using a sealed table of all interactable doors that will be loaded into memory.
local blockStorage: {[number]: blockToken} = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local addToken = function(arg_ref: Part)

	-- Remove identification from the door token to make it easier to reference original door model
	local stringSplit: {string} = string.split(arg_ref.Name, "_")
	local identification: number = tonumber(stringSplit[1]) :: number
	table.remove(stringSplit, 1)
	local filteredName: string = table.concat(stringSplit) :: string

	local door_ref: Model = replicatedStorage.Assets.Doors:FindFirstChild(filteredName):Clone()
	door_ref:SetPrimaryPartCFrame(arg_ref.CFrame)
	arg_ref:Destroy()
	door_ref.Parent = workspace.LevelInteractions.Doors

	local token: blockToken = {
		ref = door_ref,
		id = identification,
		interact = replicatedStorage.Hooks.DoorHook,
		originalCFrame = door_ref:GetPrimaryPartCFrame()
	}

	local PP: ProximityPrompt = Instance.new("ProximityPrompt")
	PP.Name = "proxPrompt"
	PP.ObjectText = "Door"
	PP.ActionText = "Open/Close"
	PP.KeyboardKeyCode = Enum.KeyCode.E
	PP.Parent = door_ref.PrimaryPart
	PP.RequiresLineOfSight = false
	PP.MaxActivationDistance = 4
	PP.ClickablePrompt = false
	PP.HoldDuration = 0.2

	PP.Triggered:Connect(function()
		token.interact:FireServer(
			{
				request = "DoorToggle",
				doorID = identification
			}
		)
	end)

	blockStorage[identification] = token

end

-- Initialize the class once on runtime
function class.init()

	local animList: {[string]: any} = require(replicatedStorage.Common.animLoader):Compile()

	local doorRE: RemoteEvent = replicatedStorage.Hooks.DoorHook

	doorRE.OnClientEvent:Connect(function(dataPacket: any)
		
		if dataPacket.response == "doorUpdate" then
			local doorID: number = dataPacket.doorID
			local ref = blockStorage[doorID]

			if dataPacket.token.debounce then
				if dataPacket.token.state then
					animList[dataPacket.token.doorType].trueState(ref, dataPacket.instant)
				else
					animList[dataPacket.token.doorType].falseState(ref, dataPacket.instant)
				end
			end
		elseif dataPacket.response == "allDoorsUpdate" then

			for itteration: number, value: {security: number, state: boolean, debounce: boolean, originalState: boolean, doorType: string} in pairs(dataPacket.tokens) do

				local ref = blockStorage[value.doorID]

				if value.state then
					animList[value.doorType].trueState(ref, 0, true)
				else
					animList[value.doorType].falseState(ref, 0, true)
					
				end
			end
		else
			warn(string.format("Unkown server response from RemoteEvent %s, please report this to the developers!", doorRE.Name))
			-- output unverification to client console for developer debugging
		end
	end)

	doorRE:FireServer({
		request = "allDoorsUpdate"
	})

	for itteration: number, value: Part in pairs(workspace.LevelInteractions.Doors:GetChildren()) do addToken(value) end
end

return class