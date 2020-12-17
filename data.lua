--data.lua
require("utils.table-utils")
require("utils.technology-utils")
require("utils.get-banned-items")

require "spidertron_scale"

require("prototypes.equipment-grid")
require("prototypes.spidertron")
require("prototypes.technology")
require("prototypes.recipe")
require("prototypes.spidertron-repair")

data.raw["character"]["character"]["healing_per_tick"] = 1