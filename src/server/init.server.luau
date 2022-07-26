--!strict

local doorSystemA = require(script.doorVarientA)
local doorSystemB = require(script.doorVarientB)
local chatSystem = require(script.chatSystem)

doorSystemB.init()
doorSystemA.init()
chatSystem.init()