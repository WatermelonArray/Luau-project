--!strict

local class: any = {}

local replicatedStorage = game:GetService("ReplicatedStorage") :: any

local levelInteractions = workspace:FindFirstChild("LevelInteractions") :: any
type computerRecord = {
	ref: any,
	screen: any,
	gui: any,
	terminalOn: boolean,
	debounce: boolean,
}

local ChatHook: RemoteFunction = replicatedStorage.Hooks.ChatHook
local ChatHookSend: RemoteEvent = replicatedStorage.Hooks.ChatHookSend

local colorOn: Color3 = Color3.fromHex("#7fff7f")
local colorOff: Color3 = Color3.fromHex("#ff6464")
local colorChatNotification: Color3 = Color3.fromHex("#49b0ff")
local colorAdmin: Color3 = Color3.fromHex("#ffe146")
local colorP1: Color3 = Color3.fromHex("#66ff66")

local loadSequenceModule: {{text: string, duration: number}} = require(script.loadSequenceModule)
local shutdownSequenceModule: {{text: string, duration: number}} = require(script.shutdownSequenceModule)

local computerStorages: {computerRecord} = {}

local function addRecord(ref: Model, screen: SurfaceGui, gui: ScreenGui)

	local record: computerRecord = {
		ref = ref,
		screen = screen,
		gui = gui,
		terminalOn = false,
		debounce = true,
	}

	table.insert(computerStorages, record)

	for itteration = 1, #computerStorages do
		if computerStorages[itteration] == record then
			return computerStorages[itteration]
		end
	end

	return nil :: any
end

local function clearList(ref: {any})
	for itteration = 1, #ref do
		local v: any = ref[itteration]
		if not v:IsA("UIListLayout") then
			v:Destroy()
		end
	end
end

local function addTerminalLines(ref: {any}, gui, waitVar: boolean?, chat: boolean?, record: computerRecord?)
	local tempMemory: {[number]: TextLabel} = {}
	local deletedTL: number = 0
	local maxLines: number = 13

	clearList(gui:GetChildren())

	for i, v in pairs(ref) do
		local tl: TextLabel = Instance.new("TextLabel")
		tempMemory[i] = tl
		if chat then
			tl.Text = string.format("%s: %s", v.host, v.text)
		else
			tl.Text = v.text
		end
		tl.Name = tostring(i) -- to reference for going above 32 lines
		tl.LayoutOrder = i
		tl.TextSize = 96
		tl.Font = Enum.Font.Arcade
		tl.BackgroundTransparency = 1
		tl.TextColor3 = colorP1
		tl.TextStrokeTransparency = 1
		tl.Size = UDim2.new(1, 0, 0, 96)
		tl.AnchorPoint = Vector2.new(0.5, 0)
		tl.ClipsDescendants = true
	
		tl.TextXAlignment = Enum.TextXAlignment.Left
		if chat and record then
			if v.host == record.ref.Name then
				tl.TextXAlignment = Enum.TextXAlignment.Right
				tl.Text = string.format("%s :%s", v.text, v.host)
			end
		end
		if i > maxLines then
			deletedTL += 1
			tempMemory[deletedTL]:Destroy()
		end
		tl.Parent = gui
		if waitVar then
			task.wait(v.duration or 0.05)
		end
	end
	tempMemory = nil :: any-- Clean up memory for gc
end

local function updateBottomBar(record)

	local messages: number = ChatHook:InvokeServer("messageCount")

	record.screen.render.bottom.messageCount.Text = string.format("Messages: %s", tostring(messages))
	record.screen.render.bottom.hostName.Text = record.ref.Name

end

ChatHookSend.OnClientEvent:Connect(function(data)
	for itteration = 1, #computerStorages do
		local record: computerRecord = computerStorages[itteration]
		if record.terminalOn then
			if data.announcement == false then
				clearList(record.screen.render.main:GetChildren())
				addTerminalLines(data.database, record.screen.render.main, false, true, record)
				updateBottomBar(record)
				if not (data.database[#data.database].host == record.ref.Name) then
					record.ref.PrimaryPart.beep:Play()
				end
			else
				record.ref.PrimaryPart.admin:Play()
			end
		end
	end
end)

-- Initialize the class once on runtime
function class.init()
	local screenStorage: Folder = Instance.new("Folder")
	screenStorage.Parent = game:GetService("Players").LocalPlayer.PlayerGui
	local nodes = levelInteractions.ChatComputers:GetChildren()
	local chatUIOpen: boolean = false

	local chatUI: any = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("chatUI") :: TextLabel

	local currentRecord: computerRecord

	chatUI.render.input.FocusLost:Connect(function(enterPressed: boolean)
		chatUI.render:TweenPosition(UDim2.new(0.5, 0, -1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
		chatUIOpen = false
		if currentRecord.terminalOn then
			currentRecord.ref.chatPP.Enabled = true
			currentRecord.ref.powerPP.Enabled = true
		end
		if enterPressed then
			ChatHookSend:FireServer(chatUI.render.input.Text, currentRecord.ref.Name)
		end
	end)

	chatUI.render.input:GetPropertyChangedSignal("Text"):Connect(function()

		local charCurrent: number = #chatUI.render.input.Text + #currentRecord.ref.Name

		if charCurrent >= 32 then
			chatUI.render.input.Text = string.sub(chatUI.render.input.Text, 1, #chatUI.render.input.Text - 1)
		else
			if chatUI.render.input.Text ~= "" and charCurrent < 31 then
				chatUI.click:Play()
			end
		end
	end)

	chatUI.render.input.ReturnPressedFromOnScreenKeyboard:Connect(function()
		ChatHookSend:FireServer(chatUI.render.input.Text, currentRecord.ref.Name)
	end)

	for itteration = 1, #nodes do

		local value: Part = nodes[itteration]

		local computer: any = replicatedStorage.Assets.ChatTerminals[value.Name]:Clone() :: Model
		computer:SetPrimaryPartCFrame(value.CFrame)
		computer.Parent = levelInteractions.ChatComputers

		computer.Name = value:GetAttribute("hostName")

		value:Destroy()

		local screen: any = replicatedStorage.Assets.GUIs.chatTerminal:Clone() :: SurfaceGui
		screen.Parent = screenStorage
		screen.Adornee = computer.screen

		local chatPP: ProximityPrompt = Instance.new("ProximityPrompt")
		chatPP.Name = "chatPP"
		chatPP.Parent = computer
		chatPP.KeyboardKeyCode = Enum.KeyCode.R
		chatPP.GamepadKeyCode = Enum.KeyCode.ButtonY
		chatPP.HoldDuration = 0.5
		chatPP.UIOffset = Vector2.new(0, -100)
		chatPP.ObjectText = "Chat Terminal"
		chatPP.ActionText = "Enter text"
		chatPP.Enabled = false

		local pp: ProximityPrompt = Instance.new("ProximityPrompt")
		pp.Name = "powerPP"
		pp.Parent = computer
		pp.HoldDuration = 0.5
		pp.ObjectText = "Chat Terminal"
		pp.ActionText = "Turn on"

		local record: computerRecord = addRecord(computer, screen, chatUI)

		if record then
			pp.Triggered:Connect(function()
				if record.debounce then
					if not record.terminalOn then
						pp.Enabled = false
						record.debounce = false
						record.terminalOn = true

						screen.Enabled = true
						computer.PrimaryPart.startup:Play()
						computer.screen.scanLine.Enabled = true
						computer.power.Color = colorOn
						computer.power.billboard.status.ImageColor3 = colorOn
						computer.screen.light.emitLight.Enabled = true

						screen.load.boot.Visible = false

						clearList(screen.load.sequence:GetChildren())
						task.wait(2)

						screen.load.sequence.Visible = true
						addTerminalLines(loadSequenceModule, screen.load.sequence, true)

						--! Very unclean setup for loading chat window animations
						screen.load.sequence.Visible = false
						task.wait(2)
						screen.load.boot.Visible = true
						task.wait(4)
						screen.load.Visible = false
						task.wait(0.5)

						screen.render.Visible = true
						screen.render.top.Visible = true
						task.wait(0.05)

						clearList(screen.render.main:GetChildren())
						screen.render.main.Visible = true
						updateBottomBar(record)
						local chatList: {{text:string, host: string, timestamp: string}} = ChatHook:InvokeServer("messageLoad") -- grab message
						print(chatList)
						addTerminalLines(chatList, screen.render.maini, true, true, record)

						screen.render.bottom.Visible = true
						task.wait(1)
						record.debounce = true
						pp.UIOffset = Vector2.new(0, -180)
						pp.Enabled = true
						pp.ActionText = "Turn off"
						chatPP.Enabled = true

					else
						record.debounce = false
						record.terminalOn = false

						pp.Enabled = false
						chatPP.Enabled = false

						screen.load.Visible = true
						screen.render.Visible = false
						screen.load.boot.Visible = false
						screen.load.sequence.Visible = true

						clearList(screen.load.sequence:GetChildren())

						task.wait(0.5)

						addTerminalLines(shutdownSequenceModule, screen.load.sequence, true)

						screen.Enabled = false
						computer.screen.scanLine.Enabled = false
						computer.screen.light.emitLight.Enabled = false
						task.wait(1)
						computer.power.Color = colorOff
						computer.power.billboard.status.ImageColor3 = colorOff

						task.wait(1)
						pp.UIOffset = Vector2.new(0, 0)
						pp.ActionText = "Turn on"
						pp.Enabled = true
						record.debounce = true
					end
				end
			end)

			chatPP.Triggered:Connect(function()
				if not chatUIOpen then
					pp.Enabled = false
					chatPP.Enabled = false

					chatUIOpen = true
					currentRecord = record
					chatUI.render:TweenPosition(UDim2.new(0.5, 0, 0.1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
					chatUI.render.input.Text = ""
					task.wait(0.5)
					chatUI.render.input.Text = ""
					chatUI.render.input:CaptureFocus()
				end
			end)
		end
	end
end

return class