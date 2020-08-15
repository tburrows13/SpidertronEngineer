function add_prerequisites(tech_name, require_names)
  if not data.raw.technology[tech_name] then return end
  if type(require_names) == "string" then require_names = {require_names} end
  for _, require_name in pairs(require_names) do
    if data.raw.technology[require_name] then
      data.raw.technology[tech_name].prerequisites = data.raw.technology[tech_name].prerequisites or {}
      local already = false
      for _, prerequisite in pairs(data.raw.technology[tech_name].prerequisites) do
        if prerequisite == require_name then
          already = true
          break
        end
      end
      if not already then
        table.insert(data.raw.technology[tech_name].prerequisites, require_name)
      end
    end
  end
end


function remove_prerequisites (prototype_name, prerequisites)
  local prototype = data.raw.technology[prototype_name]
  if not prototype then return end
  for _, new_prerequisite in pairs(prerequisites) do
    for i = #prototype.prerequisites, 1, -1 do
      if prototype.prerequisites[i] == new_prerequisite then
        table.remove(prototype.prerequisites, i)
      end
    end
  end
end

-- Remove heavy-armor, modular-armor
data.raw.recipe["light-armor"] = nil
data.raw.technology["heavy-armor"] = nil
data.raw.technology["modular-armor"] = nil


-- Mil 1 gives heavy-armor, MG, Shotgun
table.insert(data.raw.technology["military"].effects, { type = "give-item", item = "heavy-armor" } )

-- Mil 2 gives modular-armor, rocket launcher, flamethrower
table.insert(data.raw.technology["military-2"].effects, { type = "give-item", item = "modular-armor" } )

add_prerequisites("military-2", {"advanced-electronics"})
remove_prerequisites("solar-panel-equipment", {"modular-armor"})
remove_prerequisites("power-armor", {"modular-armor"})
add_prerequisites("rocketry", {"military-2"})
add_prerequisites("flamethrower", {"military-2"})



-- Power Armor gives power-armor, second rocket slot
data.raw.technology["power-armor"].effects = {
  {
    type = "give-item",
    item = "power-armor"
  },
  {
    type = "nothing",
    effect_description = "Second rocket launcher slot"
  }
}

-- Power Armor 2 gives power-armor-mk2, 3rd+4th rocket slots
data.raw.technology["power-armor-mk2"].effects = {
  {
    type = "give-item",
    item = "power-armor-mk2"
  },
  {
    type = "nothing",
    effect_description = "Third rocket launcher slot"
  }
}

table.insert(data.raw.technology["atomic-bomb"].effects, { type = "nothing", effect_description = "Fourth rocket launcher slot" } )
