-- Mil 1 gives heavy-armor, MG, Shotgun
table.insert(data.raw.technology["military"].effects, 1, {
  type = "give-item",
  item = "spidertron-engineer-1"
})


-- Mil 2 gives modular-armor, rocket launcher, flamethrower
table.insert(data.raw.technology["military-2"].effects, 1, {
  type = "give-item",
  item = "spidertron-engineer-2"
})

add_prerequisites("military-2", {"advanced-electronics"})
add_prerequisites("rocketry", {"military-2"})
add_prerequisites("flamethrower", {"military-2"})


-- Power Armor gives power-armor, combat-shotgun, second rocket slot
table.insert(data.raw.technology["power-armor"].effects, 1, {
  type = "give-item",
  item = "spidertron-engineer-3"
})
--add_prerequisites("power-armor", {"military-2"})


-- Power Armor 2 gives power-armor-mk2, 3rd rocket slot
table.insert(data.raw.technology["power-armor-mk2"].effects, 1, {
  type = "give-item",
  item = "spidertron-engineer-4"
})

-- Spidertron gives MK6
table.insert(data.raw.technology["spidertron"].effects, 1,{
  type = "give-item",
  item = "spidertron-engineer-5"
})
add_prerequisites("spidertron", {"power-armor-mk2"})