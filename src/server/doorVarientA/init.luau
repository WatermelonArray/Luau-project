--!strict

--local perms = require(script.doorPermissions) :: any -- a list of usable permissions

local class = {}

local animList: {[string]: any} = require(script.animLoader):Compile()
local perms = require(script.doorPermissions) :: any -- a list of usable permissions

-- A type checker to make sure that items being added into memory are in fact data that relate to this type.
type blockToken = {
	doorID: number,
	doorRef: Model,
	state: boolean,
	debounce: boolean,
	security: number,
	doorType: string,
	originalCFrame: CFrame
}

local replicatedStorage = game:GetService("ReplicatedStorage")

-- Creation of a noSQL database using a sealed table of all interactable doors that will be loaded into memory.
local blockStorage: {[number]: blockToken} = {}

-- Create tokens in blockStorage corresponding to each door part
local addToken = function(itterationID: number, arg_ref: Part, arg_security: number?, arg_state: boolean?)

	local door_ref: Model = replicatedStorage.Assets.Doors:FindFirstChild(arg_ref.Name):Clone()
	door_ref:SetPrimaryPartCFrame(arg_ref.CFrame)
	
	local token: blockToken = {
		doorID = itterationID,                           --* assigns a referencable identifier for clients
		ref = door_ref,                                  --* assigns a model reference for the token
		state = arg_state or false,                      --* the current state of the door: close, open
		debounce = true,                                 --* checks if the server must wait before calling a state change to the door token
		security = arg_security or 0,                    --* the minimum requirement for opening the door
		doorType = arg_ref.Name or "unkown",             --* required if animations are needed
		originalCFrame = door_ref:GetPrimaryPartCFrame() --* in case something happens, this will reset the door state back to their original state when the server compiled the information
	}
	
	door_ref.Name =	 string.format("%s%s%s", itterationID, "_", arg_ref.Name) -- Create unique identifiers for clients to reference.
	arg_ref:Destroy()
	door_ref.Parent = workspace.LevelInteractions.ServerDoors

	blockStorage[itterationID] = token

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

	PP.Triggered:Connect(function(client)
		if token.debounce and perms.getSecurityPerms(client, token.security) then
			token.state = not token.state
			if token.state then
				animList[token.doorType].trueState(token, false)
			else
				animList[token.doorType].falseState(token, false)
			end
		end
	end)

end

function class.init()

	for itteration, value in pairs(workspace.LevelInteractions.ServerDoors:GetChildren()) do
		addToken(itteration, value)
	end

	--! Remove below for release builds of your game

	blockStorage[1].security = 1 --* A test to see if security permissions are taken into account
--?	                                 spoiler: they do!

end

return class