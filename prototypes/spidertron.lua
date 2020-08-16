local enormous_equipment_grid = table.deepcopy(data.raw["equipment-grid"]["large-equipment-grid"])
enormous_equipment_grid.name = "enormous-equipment-grid"
enormous_equipment_grid.width = 12
enormous_equipment_grid.height = 12


local spiderneer = table.deepcopy(data.raw["spider-vehicle"]["spidertron"])

spiderneer.fast_replaceable_group = "spidertron"
spiderneer.minimap_representation = nil
spiderneer.selected_minimap_representation = nil
spiderneer.alert_when_damaged = false

spiderneer.name = "spidertron-engineer"

local spiderneer0 = table.deepcopy(spiderneer)
spiderneer0.name = "spidertron-engineer-0"
spiderneer0.max_health = 250
spiderneer0.equipment_grid = nil
spiderneer0.inventory_size = 0
spiderneer0.guns = {"pistol"}
spiderneer0.automatic_weapon_cycling = false
spiderneer0.chain_shooting_cooldown_modifier = 1

spiderneer0.resistances = {
  {
      type = "physical",
      decrease = 3,
      percent = 20
  },
  {
      type = "acid",
      decrease = 0,
      percent = 20
  },
  {
      type = "explosion",
      decrease = 2,
      percent = 20
  },
  {
      type = "fire",
      decrease = 0,
      percent = 10
  }
}


local spiderneer1 = table.deepcopy(spiderneer)
spiderneer1.name = "spidertron-engineer-1"
spiderneer1.max_health = 250
spiderneer1.equipment_grid = nil
spiderneer1.inventory_size = 10
spiderneer1.guns = {"submachine-gun", "shotgun"}
spiderneer1.automatic_weapon_cycling = false
spiderneer1.chain_shooting_cooldown_modifier = 1

spiderneer1.resistances = {
  {
    type = "physical",
    decrease = 6,
    percent = 30
  },
  {
    type = "explosion",
    decrease = 20,
    percent = 30
  },
  {
    type = "acid",
    decrease = 0,
    percent = 40
  },
  {
    type = "fire",
    decrease = 0,
    percent = 30
  }
}


local spiderneer2 = table.deepcopy(spiderneer)
spiderneer2.name = "spidertron-engineer-2"
spiderneer2.max_health = 350
spiderneer2.equipment_grid = "small-equipment-grid"
spiderneer2.inventory_size = 20
spiderneer2.guns = {"submachine-gun", "shotgun", "tank-flamethrower", "rocket-launcher"}
spiderneer2.automatic_weapon_cycling = false
spiderneer2.chain_shooting_cooldown_modifier = 1

spiderneer2.resistances = {
  {
    type = "physical",
    decrease = 6,
    percent = 30
  },
  {
    type = "acid",
    decrease = 0,
    percent = 50
  },
  {
    type = "explosion",
    decrease = 30,
    percent = 35
  },
  {
    type = "fire",
    decrease = 0,
    percent = 40
  }
}

local spiderneer3 = table.deepcopy(spiderneer)
spiderneer3.name = "spidertron-engineer-3"
spiderneer3.max_health = 500
spiderneer3.equipment_grid = "medium-equipment-grid"
spiderneer3.inventory_size = 30
spiderneer3.guns = {"submachine-gun", "combat-shotgun", "tank-flamethrower", "rocket-launcher", "rocket-launcher"}
spiderneer3.automatic_weapon_cycling = true
spiderneer3.chain_shooting_cooldown_modifier = 1


spiderneer3.resistances = {
  {
    type = "physical",
    decrease = 8,
    percent = 30
  },
  {
    type = "acid",
    decrease = 0,
    percent = 60
  },
  {
    type = "explosion",
    decrease = 40,
    percent = 40
  },
  {
    type = "fire",
    decrease = 0,
    percent = 60
  }
}

local spiderneer4 = table.deepcopy(spiderneer)
spiderneer4.name = "spidertron-engineer-4"
spiderneer4.max_health = 1000
spiderneer4.equipment_grid = "large-equipment-grid"
spiderneer4.inventory_size = 40
spiderneer4.guns = {"submachine-gun", "combat-shotgun", "tank-flamethrower", "spidertron-rocket-launcher-1", "spidertron-rocket-launcher-2", "spidertron-rocket-launcher-3"}
spiderneer4.automatic_weapon_cycling = false
spiderneer4.chain_shooting_cooldown_modifier = 0.5

spiderneer4.resistances =  {
  {
    type = "physical",
    decrease = 10,
    percent = 40
  },
  {
    type = "acid",
    decrease = 0,
    percent = 70
  },
  {
    type = "explosion",
    decrease = 60,
    percent = 50
  },
  {
    type = "fire",
    decrease = 0,
    percent = 70
  }
}

local spiderneer5 = table.deepcopy(spiderneer4)
spiderneer5.name = "spidertron-engineer-5"
spiderneer5.max_health = 3000
spiderneer5.equipment_grid = "enormous-equipment-grid"
spiderneer4.inventory_size = 50
table.insert(spiderneer5.guns, "spidertron-rocket-launcher-4")
spiderneer4.automatic_weapon_cycling = false
spiderneer4.chain_shooting_cooldown_modifier = 0.5


data:extend{enormous_equipment_grid, spiderneer0, spiderneer1, spiderneer2, spiderneer3, spiderneer4, spiderneer5}

-- Create lots of items to allow displaying them in the technology tree
local spiderneer_item = table.deepcopy(data.raw["item-with-entity-data"]["spidertron"])
spiderneer_item0 = table.deepcopy(spiderneer_item)
spiderneer_item1 = table.deepcopy(spiderneer_item)
spiderneer_item2 = table.deepcopy(spiderneer_item)
spiderneer_item3 = table.deepcopy(spiderneer_item)
spiderneer_item4 = table.deepcopy(spiderneer_item)
spiderneer_item5 = table.deepcopy(spiderneer_item)
spiderneer_item0.name = "spidertron-engineer-0"
spiderneer_item1.name = "spidertron-engineer-1"
spiderneer_item2.name = "spidertron-engineer-2"
spiderneer_item3.name = "spidertron-engineer-3"
spiderneer_item4.name = "spidertron-engineer-4"
spiderneer_item5.name = "spidertron-engineer-5"
spiderneer_item0.place_result = "spidertron-engineer-0"
spiderneer_item1.place_result = "spidertron-engineer-1"
spiderneer_item2.place_result = "spidertron-engineer-2"
spiderneer_item3.place_result = "spidertron-engineer-3"
spiderneer_item4.place_result = "spidertron-engineer-4"
spiderneer_item5.place_result = "spidertron-engineer-5"

data:extend{spiderneer_item0, spiderneer_item1, spiderneer_item2, spiderneer_item3, spiderneer_item4, spiderneer_item5}
