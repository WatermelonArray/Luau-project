--!strict

local class: any = {}

local replicatedStorage = game:GetService("ReplicatedStorage") :: any
local textService: TextService = game:GetService("TextService")

local levelInteractions = workspace:FindFirstChild("LevelInteractions") :: any

type recordType = {
	text: string,
	host: string,
	timestamp: string
}

local maxLimit: number = 12
local maxWidth: number = 22

local messageCount: number = 0

local recordDatabase: {recordType} = {}

local function addRecord(hostRef: string, textRef: string)

	local record: recordType = {
		text = textRef,
		host = hostRef,
		timestamp = "00:00"
	}

	messageCount += 1

	if #recordDatabase >= maxLimit then table.remove(recordDatabase, 1) end
	table.insert(recordDatabase, record)

end

function class.init()

	local rf: RemoteFunction = Instance.new("RemoteFunction")
	rf.Name = "ChatHook"
	rf.Parent = replicatedStorage.Hooks
	rf.OnServerInvoke = function(client: Player, state: string)
		if state == "messageLoad" then
			return recordDatabase
		elseif state == "messageCount" then
			return messageCount
		end
		return nil
	end

	local re: RemoteEvent = Instance.new("RemoteEvent")
	re.Name = "ChatHookSend"
	re.Parent = replicatedStorage.Hooks
	re.OnServerEvent:Connect(function(client: Player, text: string, hostComputer: string)

		local filtereredText: TextFilterResult
		local stringCapTotal: number = #text + #hostComputer

		local passCheck: boolean = false

		-- Check if hostName variable is what the server recognizes
		local computerList = levelInteractions.ChatComputers:GetChildren()
		for i = 1, #computerList do
			if computerList[i]:GetAttribute("hostName") == hostComputer then
				local char = client.Character
				if char and (computerList[i].Position - client.Character.PrimaryPart.Position).Magnitude <= 30 then -- good to check the position of a player who is sending
					passCheck = true
				end
				break -- if a comptuer is found, no need to continue the loop
			end
		end

		if passCheck then

			local stringCap: string = text
			if stringCapTotal >= maxWidth then
				stringCap = string.sub(stringCap, 1, maxWidth)
			end

			local success, error = pcall(function()
				filtereredText = textService:FilterStringAsync(stringCap, client.UserId) :: TextFilterResult
			end)

			if not success then
				warn(string.format("ERROR: Text Filtering - %s: %s", stringCap, error))
			else
				addRecord(hostComputer, filtereredText:GetNonChatStringForBroadcastAsync())
				re:FireAllClients({database = recordDatabase, announcement = false})
			end
		else
			client:Kick("Something went wrong")
		end
	end)
end

return class