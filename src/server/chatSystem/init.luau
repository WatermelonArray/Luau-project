--!strict

local class: any = {}

local replicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local textService: TextService = game:GetService("TextService")

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
	end

	local re: RemoteEvent = Instance.new("RemoteEvent")
	re.Name = "ChatHookSend"
	re.Parent = replicatedStorage.Hooks
	re.OnServerEvent:Connect(function(client: Player, text: string, hostComputer: string)

		local filtereredText: TextFilterResult
		local stringCapTotal: number = #text + #hostComputer

		local passCheck: boolean = false

		-- Check if hostName variable is what the server recognizes
		local computerList = workspace.LevelInteractions.ChatComputers:GetChildren()
		for i = 1, #computerList do
			if computerList[i]:GetAttribute("hostName") == hostComputer then
				if (computerList[i].Position - client.Character.PrimaryPart.Position).Magnitude <= 30 then -- good to check the position of a player who is sending
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
				filtereredText = textService:FilterStringAsync(stringCap, client.UserId)
			end)

			if not success then
				warn(string.concat("ERROR: Text Filtering - %s: %s", stringCap, error))
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