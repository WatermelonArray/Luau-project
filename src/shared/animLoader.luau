--!strict

local class = {}

local compiled: boolean = false

-- Create anim type restrictions with generic functions
export type animType = {
	trueStart: (Model) -> (),
	falseStart: (Model) -> ()
}

function class:Compile()

	if compiled then warn("ANIMAION LIST WAS ALREADY COMPILED!") end

	local animList: {[string]: animType} = {} -- create type restrictions on module data

	for itteration: number, module: ModuleScript in pairs(game:GetService("ReplicatedStorage").Common.Animations.Doors:GetChildren()) do

		local data: animType = require(module) :: animType
		animList[module.Name] = data

	end

	compiled = false

	return animList
end

return class