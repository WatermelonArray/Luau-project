--!strict

--local perms = require(script.doorPermissions) :: any -- a list of usable permissions

local class = {}

local replicatedStorage = game:GetService("ReplicatedStorage") :: any

local levelInteractions = workspace:FindFirstChild("LevelInteractions") :: any

local animList: {[string]: any} = require(replicatedStorage.Common.animLoader):Compile() :: any
local perms = require(replicatedStorage.Common.doorPermissions) :: any -- a list of usable permissions

-- A type checker to make sure that items being added into memory are in fact data that relate to this type.
type blockToken = {
	doorID: number,
	ref: Model,
	state: boolean,
	debounce: boolean,
	security: number,
	doorType: string,
	originalCFrame: CFrame,
	keycardHolders: {Model}
}

-- Creation of a noSQL database using a sealed table of all interactable doors that will be loaded into memory.
local blockStorage: {[number]: blockToken} = {}

-- Create tokens in blockStorage corresponding to each door part
local addToken = function(itterationID: number, arg_ref: Part, arg_security: number?, arg_state: boolean?)

	local door_ref: any = replicatedStorage.Assets.Doors:FindFirstChild(arg_ref.Name):Clone()
	local securityAttribute: number =  arg_ref:GetAttribute("security")

	door_ref:SetPrimaryPartCFrame(arg_ref.CFrame)

	local keycardSet: {Model} = {}
	local children = arg_ref:GetChildren()

	for itteration = 1, #children do
		if children[itteration].Name == "cardHolder" and children[itteration]:IsA("BasePart") and securityAttribute ~= 0 then
			local cardHolder: any = replicatedStorage.Assets.Doors.cardHolder:Clone()
			local child: BasePart = children[itteration] :: BasePart
			cardHolder.PrimaryPart.BrickColor = perms.getColor(securityAttribute)
			cardHolder.display.ui.value.Text = securityAttribute
			cardHolder.Parent = levelInteractions.KeycardHolders
			cardHolder:SetPrimaryPartCFrame(child.CFrame)
			table.insert(keycardSet, cardHolder)
		end
	end

	local token: blockToken = {
		doorID = itterationID,                            --* assigns a referencable identifier for clients
		ref = door_ref,                                   --* assigns a model reference for the token
		state = arg_state or false,                       --* the current state of the door: close, open
		debounce = true,                                  --* checks if the server must wait before calling a state change to the door token
		security = securityAttribute or 0,                     --* the minimum requirement for opening the door
		doorType = arg_ref.Name or "unkown",              --* required if animations are needed
		originalCFrame = door_ref:GetPrimaryPartCFrame(), --* in case something happens, this will reset the door state back to their original state when the server compiled the information
		keycardHolders = keycardSet                       --* A list of keycard models for animation purposes
	}

	local function createProx(parent: any)
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

		PP.Triggered:Connect(function(client: Player)
			if token.debounce  then
				
				local timer: number = 0
				
				local access: boolean = perms.getSecurityPerms(client, token.security)
				
				if token.debounce then
					
					token.debounce = false
					
					if parent.Name == "cardHolder" and parent:IsA("Model") then
						timer = 0.5
						animList["cardReader"].playState(parent, timer, perms.getSecurityCode(client), token.security)
					end
					if access then
						token.state = not token.state
						if token.state then
							animList[token.doorType].trueState(token, timer, false)
						else
							animList[token.doorType].falseState(token, timer, false)
						end
					end

					task.delay(2 + timer, function() token.debounce = true end) -- Create thread and execute after 4 seconds in the task scheduler
				end
			end
		end)

		return PP
	end
	door_ref.Name =	 string.format("%s%s%s", tostring(itterationID), "_", arg_ref.Name) -- Create unique identifiers for clients to reference.
	arg_ref:Destroy()
	door_ref.Parent = levelInteractions.ServerDoors

	blockStorage[itterationID] = token

	if #token.keycardHolders == 0 then
		createProx(door_ref.trigger).RequiresLineOfSight = false
	else
		for itteration = 1, #token.keycardHolders do
			createProx(token.keycardHolders[itteration])
		end
	end
end

function class.init()

	local keycardHolder_Folder: Folder = Instance.new("Folder")
	keycardHolder_Folder.Name = "KeycardHolders"
	keycardHolder_Folder.Parent = levelInteractions

	for itteration, value in pairs(levelInteractions.ServerDoors:GetChildren()) do
		addToken(itteration, value)
	end

end

return class