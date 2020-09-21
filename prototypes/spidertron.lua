local function generate_legs(spidertron, number)
  local spider_legs = {}
  for _, leg in pairs(spidertron.spider_engine.legs) do
    local spider_leg = table.deepcopy(data.raw['spider-leg'][leg.leg])
    spider_leg.name = spider_leg.name .. "-copy-" .. number
    leg.leg = spider_leg.name
    table.insert(spider_legs, spider_leg)
  end
  return spider_legs
end

local spiderneer = table.deepcopy(data.raw["spider-vehicle"]["spidertron"])
-- Generic prototype
spiderneer.fast_replaceable_group = "spidertron"
spiderneer.minimap_representation = nil
spiderneer.selected_minimap_representation = nil
spiderneer.alert_when_damaged = false
spiderneer.minable = nil
spiderneer.automatic_weapon_cycling = false

spiderneer.name = "spidertron-engineer"

local spiderneer0 = table.deepcopy(spiderneer)
spiderneer0.name = "spidertron-engineer-0"
spiderneer0.max_health = 250
spiderneer0.equipment_grid = nil  -- Redone in data-final-fixes
spiderneer0.inventory_size = 0
spiderneer0.guns = {"pistol"}

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
spiderneer1.equipment_grid = nil  -- Redone in data-final-fixes
spiderneer1.inventory_size = 0
spiderneer1.guns = {"submachine-gun", "shotgun"}

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
spiderneer2.equipment_grid = "spidertron-engineer-equipment-grid-2"
spiderneer2.inventory_size = 20
spiderneer2.guns = {"submachine-gun", "shotgun", "tank-flamethrower", "rocket-launcher"}

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
spiderneer3.equipment_grid = "spidertron-engineer-equipment-grid-3"
spiderneer3.inventory_size = 30
spiderneer3.guns = {"submachine-gun", "combat-shotgun", "tank-flamethrower", "rocket-launcher", "rocket-launcher"}

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
spiderneer4.equipment_grid = "spidertron-engineer-equipment-grid-4"
spiderneer4.inventory_size = 40
spiderneer4.guns = {"submachine-gun", "combat-shotgun", "tank-flamethrower", "spidertron-rocket-launcher-1", "spidertron-rocket-launcher-2", "spidertron-rocket-launcher-3"}

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
spiderneer5.equipment_grid = "spidertron-engineer-equipment-grid-5"
spiderneer5.inventory_size = 50
table.insert(spiderneer5.guns, "spidertron-rocket-launcher-4")

local spiderneer5a = table.deepcopy(spiderneer5)
spiderneer5a.name = "spidertron-engineer-5a"

if mods["Nanobots"] then
  table.insert(spiderneer1.guns, "gun-nano-emitter")
  table.insert(spiderneer2.guns, "gun-nano-emitter")
  table.insert(spiderneer3.guns, "gun-nano-emitter")
  table.insert(spiderneer4.guns, "gun-nano-emitter")
  table.insert(spiderneer5.guns, "gun-nano-emitter")
  table.insert(spiderneer5a.guns, "gun-nano-emitter")
end

-- Created so that there is always a spidertron that can be switched to

data:extend{spiderneer0, spiderneer1, spiderneer2, spiderneer3, spiderneer4, spiderneer5, spiderneer5a}

legs = {generate_legs(spiderneer0, "0"),
        generate_legs(spiderneer1, "1"),
        generate_legs(spiderneer2, "2"),
        generate_legs(spiderneer3, "3"),
        generate_legs(spiderneer4, "4"),
        generate_legs(spiderneer5, "5"),
        generate_legs(spiderneer5a, "5a")
      }
for i, leg in pairs(legs) do
  data:extend(legs[i])
end

if settings.startup["spidertron-engineer-enable-upgrade-size"].value then
  spidertron_scale{spidertron = spiderneer0, scale = 0.6}
  spidertron_scale{spidertron = spiderneer1, scale = 0.7}
  spidertron_scale{spidertron = spiderneer2, scale = 0.8}
  spidertron_scale{spidertron = spiderneer3, scale = 0.9}
  spidertron_scale{spidertron = spiderneer5, scale = 1.2}
  spidertron_scale{spidertron = spiderneer5a, scale = 1.2}
else
  scale = settings.startup["spidertron-engineer-constant-size-scale"].value
  spidertron_scale{spidertron = spiderneer0, scale = scale}
  spidertron_scale{spidertron = spiderneer1, scale = scale}
  spidertron_scale{spidertron = spiderneer2, scale = scale}
  spidertron_scale{spidertron = spiderneer3, scale = scale}
  spidertron_scale{spidertron = spiderneer5, scale = scale}
  spidertron_scale{spidertron = spiderneer5a, scale = scale}
end
-- Create lots of items to allow displaying them in the technology tree
local spiderneer_item = table.deepcopy(data.raw["item-with-entity-data"]["spidertron"])
spiderneer_item0 = table.deepcopy(spiderneer_item)
spiderneer_item1 = table.deepcopy(spiderneer_item)
spiderneer_item2 = table.deepcopy(spiderneer_item)
spiderneer_item3 = table.deepcopy(spiderneer_item)
spiderneer_item4 = table.deepcopy(spiderneer_item)
spiderneer_item5 = table.deepcopy(spiderneer_item)
spiderneer_item5a = table.deepcopy(spiderneer_item)
spiderneer_item0.name = "spidertron-engineer-0"
spiderneer_item1.name = "spidertron-engineer-1"
spiderneer_item2.name = "spidertron-engineer-2"
spiderneer_item3.name = "spidertron-engineer-3"
spiderneer_item4.name = "spidertron-engineer-4"
spiderneer_item5.name = "spidertron-engineer-5"
spiderneer_item5a.name = "spidertron-engineer-5a"
spiderneer_item0.place_result = "spidertron-engineer-0"
spiderneer_item1.place_result = "spidertron-engineer-1"
spiderneer_item2.place_result = "spidertron-engineer-2"
spiderneer_item3.place_result = "spidertron-engineer-3"
spiderneer_item4.place_result = "spidertron-engineer-4"
spiderneer_item5.place_result = "spidertron-engineer-5"
spiderneer_item5a.place_result = "spidertron-engineer-5a"

data:extend{spiderneer_item0, spiderneer_item1, spiderneer_item2, spiderneer_item3, spiderneer_item4, spiderneer_item5, spiderneer_item5a}
