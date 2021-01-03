--data.lua
require("utils.table-utils")
require("utils.technology-utils")
require("utils.get-banned-items")

require "spidertron_scale"

require("prototypes.custom-input")
require("prototypes.equipment-grid")
require("prototypes.spidertron")
require("prototypes.technology")
require("prototypes.recipe")
require("prototypes.spidertron-repair")

local character = data.raw["character"]["character"]
character["healing_per_tick"] = 1  -- Default value is 0.15 but it needs to be faster to recover quickly from damage dealt when out of spidertron
character.icon = data.raw.capsule["raw-fish"].icon