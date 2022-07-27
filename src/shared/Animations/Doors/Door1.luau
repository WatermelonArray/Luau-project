--!strict

local anim: any = {}

local tweenService = game:GetService("TweenService")

function anim.trueState(token: any, timer: number, instant: boolean?)

	local r: any = token.ref.render
	local a: BasePart = r.animA
	local b: BasePart = r.animB
	local originalCFrame: CFrame = token.originalCFrame

	local rootTime: number = 0.8
	local detailTime: number = 0.2

	if instant then -- support for updating animations
		rootTime = 0
		detailTime = 0
	end

	local twRoot: TweenInfo = TweenInfo.new(rootTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, detailTime + timer)
	local twDetail: TweenInfo = TweenInfo.new(detailTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true, timer)

	local pivotPoint: CFrame = CFrame.new(2, 0, 0)

	local root_CFRAME: CFrameValue = Instance.new("CFrameValue")
	root_CFRAME.Value = originalCFrame * pivotPoint:Inverse()

	local a_OFFSET: CFrame = CFrame.new(0, -0.5, 0.25)
	local b_OFFSET: CFrame = CFrame.new(1.25, 0.25, -0.6)

	local a_CFRAME: CFrameValue = Instance.new("CFrameValue")
	local b_CFRAME: CFrameValue = Instance.new("CFrameValue")

	local goalRoot: {CFrame} = {Value = originalCFrame * pivotPoint:Inverse() * CFrame.Angles(0, 2, 0)}
	local goalA: {CFrame} = {Value = CFrame.new(0, 0, -0.05)}
	local goalB: {CFrame} = {Value =  CFrame.Angles(0, math.rad(-20), 0)}

	root_CFRAME:GetPropertyChangedSignal("Value"):Connect(function() r:SetPrimaryPartCFrame(root_CFRAME.Value * pivotPoint) end)
	a_CFRAME:GetPropertyChangedSignal("Value"):Connect(function() a.CFrame = (r:GetPrimaryPartCFrame() * a_OFFSET) * a_CFRAME.Value end)
	b_CFRAME:GetPropertyChangedSignal("Value"):Connect(function() b.CFrame = (r:GetPrimaryPartCFrame() * b_OFFSET) * b_CFRAME.Value end)

	local animationA: Tween = tweenService:Create(a_CFRAME, twDetail, goalA)
	local animationB: Tween = tweenService:Create(b_CFRAME, twDetail, goalB)
	local animationRoot: Tween = tweenService:Create(root_CFRAME, twRoot, goalRoot)

	animationA:Play()
	animationB:Play()
	animationRoot:Play()

end

function anim.falseState(token: any, timer: number, instant: boolean?)

	local r: any = token.ref.render

	local originalCFrame = token.originalCFrame

	local rootTime: number = 0.6

	if instant then -- support for updating animations
		rootTime = 0
	end

	local twRoot: TweenInfo = TweenInfo.new(rootTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, timer)

	local pivotPoint: CFrame = CFrame.new(2, 0, 0)

	local root_CFRAME: CFrameValue = Instance.new("CFrameValue")
	root_CFRAME.Value = originalCFrame * pivotPoint:Inverse() * CFrame.Angles(0, 2, 0)

	local goalRoot: {CFrame} = {Value = originalCFrame * pivotPoint:Inverse()}
	
	root_CFRAME:GetPropertyChangedSignal("Value"):Connect(function() r:SetPrimaryPartCFrame(root_CFRAME.Value * pivotPoint) end)

	local animationRoot: Tween = tweenService:Create(root_CFRAME, twRoot, goalRoot)

	animationRoot:Play()

end

return anim