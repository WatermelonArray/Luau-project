--!strict

local anim: any = {}

local tweenService = game:GetService("TweenService")

function anim.playState(ref: Model, timer: number)

	local twDetail: TweenInfo = TweenInfo.new(timer, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true)

	local card = game:GetService("ReplicatedStorage").Assets.Tools.Keycard.Handle:Clone()
	card.Anchored = true
	card.Parent = workspace

	card.CFrame = ref:GetPrimaryPartCFrame() * CFrame.new(0, 2, 0.1) * CFrame.Angles(0, -math.rad(90), math.rad(90))

	local goalCard = {CFrame = ref:GetPrimaryPartCFrame() * CFrame.new(0, 0.5, 0.1) * CFrame.Angles(0, -math.rad(90), math.rad(90))}

	local cardTween: Tween = tweenService:Create(card, twDetail, goalCard)

	cardTween:Play()

	cardTween.Completed:Connect(function()
		card:Destroy()
	end)
end

return anim