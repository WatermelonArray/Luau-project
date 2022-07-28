--!strict

local anim: any = {}

local replicatedStorage = game:GetService("ReplicatedStorage") :: any
local tweenService = game:GetService("TweenService")

local perms = require(replicatedStorage.Common.doorPermissions) :: any -- a list of usable permissions

function anim.playState(ref: any, timer: number, clientSecurity: number, security: number)

	local twDetail: TweenInfo = TweenInfo.new(timer, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true)

	local card = replicatedStorage.Assets.Tools.Keycard.Handle:Clone()
	card.Anchored = true
	card.Parent = workspace
	card.BrickColor = perms.getColor(clientSecurity)

	card.CFrame = ref:GetPrimaryPartCFrame() * CFrame.new(0, 2, 0.1) * CFrame.Angles(0, -math.rad(90), math.rad(90))

	local goalCard = {CFrame = ref:GetPrimaryPartCFrame() * CFrame.new(0, 0.5, 0.1) * CFrame.Angles(0, -math.rad(90), math.rad(90))}

	local cardTween: Tween = tweenService:Create(card, twDetail, goalCard)

	cardTween:Play()

	task.delay(timer, function()
		if clientSecurity >= security then
			ref.PrimaryPart.accept:Play()
			ref.success.Material = Enum.Material.Neon
			ref.success.billboard.Enabled = true

			task.wait(1)
			ref.success.Material = Enum.Material.Glass
			ref.success.billboard.Enabled = false
		else
			ref.PrimaryPart.beep.PlaybackSpeed = 0.8
			ref.PrimaryPart.beep:Play()
			ref.fail.Material = Enum.Material.Neon
			ref.fail.billboard.Enabled = true
			task.wait(0.15)
			ref.PrimaryPart.beep.PlaybackSpeed = 0.6
			ref.PrimaryPart.beep:Play()
			task.wait(0.85)
			ref.fail.Material = Enum.Material.Glass
			ref.fail.billboard.Enabled = false
		end
	end)

	cardTween.Completed:Connect(function()
		card:Destroy()
	end)
end

return anim