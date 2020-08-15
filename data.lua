--data.lua
local spiderneer = table.deepcopy(data.raw["spider-vehicle"]["spidertron"])

spiderneer.name = "spidertron-engineer"
spiderneer.max_health = 250
spiderneer.equipment_grid = nil
spiderneer.inventory_size = 0
spiderneer.guns = {"pistol"}

spiderneer.minimap_representation = nil
spiderneer.selected_minimap_representation = nil
spiderneer.alert_when_damaged = false

data:extend{spiderneer}