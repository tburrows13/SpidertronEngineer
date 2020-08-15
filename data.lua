--data.lua
require("prototypes.technology.technology")

local spiderneer = table.deepcopy(data.raw["spider-vehicle"]["spidertron"])

spiderneer.fast_replaceable_group = "spidertron"
spiderneer.minimap_representation = nil
spiderneer.selected_minimap_representation = nil
spiderneer.alert_when_damaged = false

spiderneer.name = "spidertron-engineer"

local spiderneer1 = table.deepcopy(spiderneer)

spiderneer1.name = "spidertron-engineer-1"
spiderneer1.max_health = 250
spiderneer1.equipment_grid = nil
spiderneer1.inventory_size = 0
spiderneer1.guns = {"pistol"}

local spiderneer2 = table.deepcopy(spiderneer)
spiderneer2.name = "spidertron-engineer-2"
spiderneer2.max_health = 500
spiderneer2.equipment_grid = nil
spiderneer2.inventory_size = 0
spiderneer2.guns = {"pistol"}

data:extend{spiderneer1, spiderneer2}