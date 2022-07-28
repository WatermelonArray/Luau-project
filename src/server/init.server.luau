--!strict

local doorSystemA = require(script.doorVariantA)
local doorSystemB = require(script.doorVariantB)
local chatSystem = require(script.chatSystem)

doorSystemB.init()
doorSystemA.init()
chatSystem.init()