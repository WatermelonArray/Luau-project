--!strict

local class: any = {}

local replicatedStorage = game:GetService("ReplicatedStorage") :: any

local levelInteractions = workspace:FindFirstChild("LevelInteractions") :: any
-- A type checker to make sure that items being added into memory are in fact data that relate to this type.
type blockToken = {
	ref: Model,
	id: number,
	interact: RemoteEvent,
	originalCFrame: CFrame,
	keycardHolders: {Model}
}

-- Creation of a noSQL database using a sealed table of all interactable doors that will be loaded into memory.
local blockStorage: {[number]: blockToken} = {}

local addToken = function(arg_ref: Part)

	-- Remove identification from the door token to make it easier to reference original door model
	local stringSplit: {string} = string.split(arg_ref.Name, "_")
	local identification: number = tonumber(stringSplit[1]) :: number
	table.remove(stringSplit, 1)
	local filteredName: string = table.concat(stringSplit) :: string

	local door_ref: any = replicatedStorage.Assets.Doors:FindFirstChild(filteredName):Clone()
	local securityAttribute: number =  arg_ref:GetAttribute("security")

	door_ref:SetPrimaryPartCFrame(arg_ref.CFrame)

	local keycardSet: {Model} = {}
	local children = arg_ref:GetChildren()

	for itteration = 1, #children do
		if children[itteration]:IsA("BasePart") and securityAttribute ~= 0 then
			local cardHolder: any = replicatedStorage.Assets.Doors.cardHolder:Clone()
			local child: BasePart = children[itteration] :: BasePart
		--	cardHolder.PrimaryPart.BrickColor = perms.getColor(securityAttribute)
			cardHolder.display.ui.value.Text = securityAttribute
			cardHolder.Parent = levelInteractions.KeycardHoldersClient
			cardHolder:SetPrimaryPartCFrame(child.CFrame)
			keycardSet[itteration] = cardHolder
			cardHolder.Name = "cardHolder"
		end
	end

	local token: blockToken = {
		ref = door_ref,
		id = identification,
		interact = replicatedStorage.Hooks.DoorHook,
		originalCFrame = door_ref:GetPrimaryPartCFrame(),
		keycardHolders = keycardSet
	}

	local function createProx(parent: any, cardID: number?)
		local PP: ProximityPrompt = Instance.new("ProximityPrompt")
		PP.Name = "proxPrompt"
		PP.ObjectText = "Door"
		PP.ActionText = "Open/Close"
		PP.KeyboardKeyCode = Enum.KeyCode.E
		PP.RequiresLineOfSight = true
		PP.MaxActivationDistance = 4
		PP.ClickablePrompt = false
		PP.HoldDuration = 0.2

		PP.Parent = parent

		PP.Triggered:Connect(function()
			if parent.Name == "cardHolder" then
				token.interact:FireServer(
					{
						request = "DoorToggle",
						doorID = identification,
						readerID = cardID
					}
				)
			else
				token.interact:FireServer(
					{
						request = "DoorToggle",
						doorID = identification,
					}
				)
			end
		end)

		return PP
	end

	arg_ref:Destroy()
	door_ref.Parent = levelInteractions.Doors

	blockStorage[identification] = token

	if #token.keycardHolders == 0 then
		createProx(door_ref.trigger).RequiresLineOfSight = false
	else
		for itteration = 1, #token.keycardHolders do
			createProx(token.keycardHolders[itteration], itteration)
		end
	end

end

-- Initialize the class once on runtime
function class.init()

	local keycardHolder_Folder: Folder = Instance.new("Folder")
	keycardHolder_Folder.Name = "KeycardHoldersClient"
	keycardHolder_Folder.Parent = levelInteractions

	local animList: {[string]: any} = require(replicatedStorage.Common.animLoader):Compile() :: any

	local doorRE: RemoteEvent = replicatedStorage.Hooks.DoorHook

	doorRE.OnClientEvent:Connect(function(dataPacket: any)

		if dataPacket.response == "doorUpdate" then
			local doorID: number = dataPacket.doorID
			local ref = blockStorage[doorID]

			local timer: number = 0

			if dataPacket.token.debounce then
				if dataPacket.token.state then
					if dataPacket.cardID then
						timer = 0.5
						animList["cardReader"].playState(blockStorage[doorID].keycardHolders[dataPacket.cardID], timer)
					end

					animList[dataPacket.token.doorType].trueState(ref, timer, dataPacket.instant)
				else
					animList[dataPacket.token.doorType].falseState(ref, timer, dataPacket.instant)
				end
			end
		elseif dataPacket.response == "allDoorsUpdate" then

			for itteration: number, value: {security: number, state: boolean, debounce: boolean, doorType: string, doorID: number} in pairs(dataPacket.tokens) do

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

	for itteration: number, value: Part in pairs(levelInteractions.Doors:GetChildren()) do addToken(value) end
end

return class