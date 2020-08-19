--control.lua
require("utils.table-utils")
require("utils.get-banned-items")

spidertron_researches = {"military", "military-2", "power-armor", "power-armor-mk2", "spidertron"}
spidertron_names = {"spidertron-engineer-0", "spidertron-engineer-1", "spidertron-engineer-2", "spidertron-engineer-3", "spidertron-engineer-4", "spidertron-engineer-5"}


local function recolor_spidertron(player, spidertron)
  if global.spidertron_colors[player.index] then 
    spidertron.color = global.spidertron_colors[player.index]
  else 
    spidertron.color = player.color 
  end
  global.spidertron_colors[player.index] = spidertron.color
end

local function store_spidertron_data(player)
  -- Removes the player's spidertron from the world and saves data about it in global.spidertron_saved_data[player.index]
  -- Probably redo with teleport when v1.1 comes
  -- Remove player before calling

  local spidertron = global.spidertrons[player.index]
  local grid_contents = {}
  if spidertron.grid then
    for _, equipment in pairs(spidertron.grid.equipment) do
      table.insert(grid_contents, {name=equipment.name, position=equipment.position})
    end
  end
  local ammo = spidertron.get_inventory(defines.inventory.car_ammo).get_contents()
  local trunk = spidertron.get_inventory(defines.inventory.car_trunk).get_contents()
  global.spidertron_saved_data[player.index] = {index = player.index, equipment = grid_contents, ammo = ammo, trunk = trunk}
  return {index = player.index, equipment = grid_contents, ammo = ammo, trunk = trunk}
end

local function place_stored_spidertron_data(player)
  -- Copy across equipment grid
  local saved_data = global.spidertron_saved_data[player.index]
  local spidertron = global.spidertrons[player.index]
  log("Placing saved data back into spidertron: \n" .. serpent.block(saved_data))
  local previous_grid_contents = saved_data.equipment
  if previous_grid_contents then
    local items_to_insert = {}
    for _, equipment in pairs(previous_grid_contents) do
      if spidertron.grid then
        spidertron.grid.put( {name=equipment.name, position=equipment.position} )
      else 
        player.surface.spill_item_stack(spidertron.position, {name=equipment.name})
      end
    end
  end

  -- Copy across ammo
  local previous_ammo = saved_data.ammo
  local ammo_inventory = spidertron.get_inventory(defines.inventory.car_ammo)
  for name, count in pairs(previous_ammo) do
    if ammo_inventory then ammo_inventory.insert({name=name, count=count})
    else
      player.surface.spill_item_stack(spidertron.position, {name=name, count=count})
    end
  end

  -- Copy across trunk
  local previous_trunk = saved_data.trunk
  local trunk_inventory = spidertron.get_inventory(defines.inventory.car_trunk)
  for name, count in pairs(previous_trunk) do
    if trunk_inventory then trunk_inventory.insert({name=name, count=count})
    else
      player.surface.spill_item_stack(spidertron.position, {name=name, count=count})
    end
  end

  global.spidertron_saved_data[player.index] = nil
end

local function replace_spidertron(player)
  local previous_spidertron = global.spidertrons[player.index]
  local name = "spidertron-engineer-" .. global.spidertron_research_level[player.force.name]

  log("Upgrading spidertron to level " .. name .. " for player " .. player.name)

  local last_user = previous_spidertron.last_user

  -- Save data to copy across afterwards
  store_spidertron_data(player)

  spidertron = player.surface.create_entity{
    name = name,
    position = previous_spidertron.position,
    direction = previous_spidertron.direction,
    force = previous_spidertron.force,
    -- Don't set player here or else the previous spidertron item will be inserted into the player's inventory
    fast_replace = true,
    spill = false
  }
  if last_user ~= nil then
    spidertron.last_user = last_user
  end

  global.spidertrons[player.index] = spidertron
  place_stored_spidertron_data(player)

  previous_spidertron.destroy()
  return spidertron
end

local function ensure_player_is_in_correct_spidertron(player)
  -- If player is in train, do nothing
  -- If player is in a spidertron-engineer upgrade it if necessary
  -- Otherwise, remove player from any vehicles and put it in its spidertron if it has on, create a spidertron if not


  if player and player.character then
    local previous_spidertron_data = global.spidertron_saved_data[player.index]
    if previous_spidertron_data and player.driving and contains({"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}, player.vehicle.type) then
      -- Ignore if in train - that is allowed (if we are already 'in' a spidertron)
      log("Player in train. Left alone")
      return
    end
    if game.active_mods["TheFatController"] and player.driving and player.vehicle.type == "locomotive" then
      return
    end

    local spidertron
    local spidertron_level = global.spidertron_research_level[player.force.name]
    local target_name = "spidertron-engineer-" .. spidertron_level
    if spidertron_level > 5 then error("Spidertron is being upgraded to level " .. spidertron_level) end

    if player.driving and contains(spidertron_names, player.vehicle.name) then
      log("Already in a spidertron-engineer with name " .. player.vehicle.name .. " (target_name = " .. target_name .. ")")
      -- We are already in a Spidertron Engineer, check if it needs upgrading
      if target_name ~= player.vehicle.name then
        -- Upgrade the spidertron
        spidertron = replace_spidertron(player)
      else
        -- We are in the correct spidertron.
        global.spidertrons[player.index] = player.vehicle
        log("Returning early from ensure_player_is_in_correct_spidertron() - in correct spidertron already")
        return
      end
    else
      -- The player is not in a valid vehicle so exit it if it is in a vehicle
      if player.driving then
        log("Vehicle ".. player.vehicle.name .." is not a valid vehicle")
        player.driving = false
      else
        log("Not in a vehicle")
      end
      -- Check if a spidertron needs to be created
      spidertron = global.spidertrons[player.index]
      if spidertron then
        log("Player " .. player.name .. " attempted to leave spidertron, and allowed to leave = " .. global.allowed_to_leave)
        -- Check if mod settings allow player to leave
        if contains({"limited-time", "unlimited-time"}, global.allowed_to_leave) then
          log("Settings allow player to leave spidertron")
          return
        end
        spidertron.set_driver(player)
        log("Player set to driver")
      else
        log("Creating spidertron for player " .. player.name)
        spidertron = player.surface.create_entity{name=target_name, position=player.position, force=player.force, player=player}
        if previous_spidertron_data then
          global.spidertrons[player.index] = spidertron
          place_stored_spidertron_data(player)
        end
      end
    end

    if not spidertron then error("Spidertron could not be created. Please report this error along with factorio-current.log") end

    player.character_inventory_slots_bonus = 10 * spidertron_level

    global.spidertrons[player.index] = spidertron
    spidertron.set_driver(player)

    recolor_spidertron(player, spidertron)
    log("Finished ensure_player_is_in_correct_spidertron()")
    return spidertron
  end
  log("Cannot create Spidertron for player - has no player or character")
end

local function upgrade_spidertrons(force, create)
  if not force then force = game.forces["player"] end
  if not create then create = false end

  if global.spidertron_research_level[force.name] >= 5 then
    log("Spidertron already at max level for force " .. force.name)
    return
  else
    global.spidertron_research_level[force.name] = global.spidertron_research_level[force.name] + 1
    log("Increased spidertron research level to " .. global.spidertron_research_level[force.name] .. " for force " .. force.name)
  end

  for _, player in pairs(force.players) do
    -- For each player in <force>, find that player's spidertron
    for player_index, spidertron in pairs(global.spidertrons) do
      if player.index == player_index then
        ensure_player_is_in_correct_spidertron(player)

        -- Remove 'added' items for if this was upgraded because of research completion
        local removed_items = 0
        removed_items = removed_items + player.remove_item({name="spidertron-engineer-0"})
        removed_items = removed_items + player.remove_item({name="spidertron-engineer-1"})
        removed_items = removed_items + player.remove_item({name="spidertron-engineer-2"})
        removed_items = removed_items + player.remove_item({name="spidertron-engineer-3"})
        removed_items = removed_items + player.remove_item({name="spidertron-engineer-4"})
        removed_items = removed_items + player.remove_item({name="spidertron-engineer-5"})
        log("Removed spidertron items: " .. removed_items)
      end
    end
  end
end


-- Player init
local function player_start(player)
  if player and player.character then
    log("Setting up player " .. player.name)

    ensure_player_is_in_correct_spidertron(player)

    -- Check players' main inventory and gun and armor slots
    for _, item_stack in pairs(global.banned_items) do
      local removed = 0
      removed = removed + player.character.get_main_inventory().remove(item_stack)
      removed = removed + player.character.get_inventory(defines.inventory.character_guns).remove(item_stack)
      removed = removed + player.character.get_inventory(defines.inventory.character_armor).remove(item_stack)
      if removed > 0 then log(removed .. " items of type " .. serpent.block(item_stack) .. " removed from player " .. player.name) end
    end

  else
    if not player then log("Can't set up player - no character")
    elseif not player.character then log("Can't set up player " .. player.name .. " - no player")
    end
  end
end
script.on_event(defines.events.on_cutscene_cancelled, function(event) log("on_cutscene_cancelled") player_start(game.get_player(event.player_index)) end)
script.on_event(defines.events.on_player_respawned, function(event) log("on_player_respawned") player_start(game.get_player(event.player_index)) end)
script.on_event(defines.events.on_player_created, function(event) log("on_player_created") player_start(game.get_player(event.player_index)) end)
script.on_event(defines.events.on_player_joined_game, function(event) log("on_player_joined_game") player_start(game.get_player(event.player_index)) end)

script.on_event(defines.events.on_player_changed_surface,
  function(event)
    log("on_player_changed_surface - player " .. event.player_index)
    local player = game.get_player(event.player_index)
    store_spidertron_data(player)
    global.spidertrons[player.index].destroy()
    global.spidertrons[player.index] = nil
    log("Entering ensure")
    ensure_player_is_in_correct_spidertron(player)
    --place_stored_spidertron_data(player)
  end
)

script.on_event(defines.events.on_player_driving_changed_state,
  function(event) 
    log("on_player_driving_changed_state")
    -- Hack to stop recursive calling of event
    if global.player_last_driving_change_tick[event.player_index] ~= event.tick then
      global.player_last_driving_change_tick[event.player_index] = event.tick
      local player = game.get_player(event.player_index)
      local spidertron = global.spidertrons[player.index]
      if (not player.driving) and spidertron then
        -- See if there is a valid entity nearby that we can enter
        log("Searching for nearby trains")
        for radius=1,5 do
          local nearby_entities = player.surface.find_entities_filtered{position=spidertron.position, radius=radius, type={"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}}
          if #nearby_entities >= 1 then
            local entity_to_drive = nearby_entities[1]
            entity_to_drive.set_driver(player)
            store_spidertron_data(player)
            spidertron.destroy()
            global.spidertrons[player.index] = nil
            return
          end
        end
      end
      ensure_player_is_in_correct_spidertron(player) 
    else 
      log("Driving state already changed this tick")
    end
  end
)
script.on_event(defines.events.on_player_toggled_map_editor, function(event) log("on_player_toggled_map_editor") ensure_player_is_in_correct_spidertron(game.get_player(event.player_index)) end)

local function deal_damage()
  for _, player in pairs(game.players) do
    if player.character and player.character.is_entity_with_health and (not player.driving) --[[and (contains({"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}, player.vehicle.type) or contains(spidertron_names, player.vehicle.name))]] then
      player.character.damage(10, "neutral")
    end
  end
end

local function settings_changed()
  global.allowed_to_leave = settings.global["spidertron-engineer-allowed-out-of-spidertron"].value
  log("Settings changed. Allowed to leave = " .. global.allowed_to_leave)
  if global.allowed_to_leave == "limited-time" then
    log("Turning on deal_damage()")
    script.on_nth_tick(31, deal_damage)
  else
    script.on_nth_tick(31, nil)
    if global.allowed_to_leave == "never" then
      for _, player in pairs(game.players) do
        ensure_player_is_in_correct_spidertron(player)
      end
    end
  end
end

script.on_event(defines.events.on_runtime_mod_setting_changed, settings_changed)
local function setup()
  log("SpidertronEngineer setup() start")
  settings_changed()

  global.spidertrons = {}
  global.spidertron_colors = {}
  global.spidertron_saved_data = {}
  global.spidertron_research_level = {}  -- Indexed by force
  global.player_last_driving_change_tick = {}
  global.banned_items = get_banned_items(
    game.get_filtered_item_prototypes({{filter = "type", type = "gun"}}),  -- Guns
    game.get_filtered_item_prototypes({{filter = "type", type = "armor"}}),  -- Armor
    game.get_filtered_recipe_prototypes({{filter = "has-ingredient-item", elem_filters = {{filter = "type", type = "gun"}, {filter = "type", type = "armor"}}}})  -- Recipes
  )

  for _, name in pairs(spidertron_names) do
    table.insert(global.banned_items, {name=name, count=10000})
  end

  for _, force in pairs(game.forces) do 
    local resource_reach_distance = game.forces["player"].character_resource_reach_distance_bonus 
    force.character_resource_reach_distance_bonus = resource_reach_distance + 3
    local build_distance_bonus = game.forces["player"].character_build_distance_bonus 
    force.character_build_distance_bonus = build_distance_bonus + 3
    local reach_distance_bonus = game.forces["player"].character_reach_distance_bonus
    force.character_reach_distance_bonus = reach_distance_bonus + 3
  end

  function qualifies(name) return game.item_prototypes[name] and --[[(game.item_prototypes[name].type == "gun" or ]] game.item_prototypes[name].type == "armor"--[[)]] end

  for _, force in pairs(game.forces) do 
    for name, _ in pairs(force.recipes) do
      if qualifies(name) and force.recipes[name].enabled then
        force.recipes[name].enabled = false
        
        -- And update assemblers
        for _, surface in pairs(game.surfaces) do
          for _, entity in pairs(surface.find_entities_filtered{type="assembling-machine", force=force}) do
            local recipe = entity.get_recipe()
            if recipe ~= nil and recipe.name == name then
              entity.set_recipe(changed(name))
            end
          end
        end    
      end
    end

    -- Replace items
    for name, _ in pairs(game.item_prototypes) do
      if qualifies(name) then
        table.insert(global.banned_items, {name=name, count=10000})
        for _, surface in pairs(game.surfaces) do
          -- Check train cars, chests, cars, player inventories, and logistics chests.
          local types = {"cargo-wagon", "container", "car", "character", "logistic-container"}
          for _, entity in pairs(surface.find_entities_filtered{type=types, force=force}) do
            remove_from_inventory(name, entity)
          end
        end
      end
    end

    -- Set each force's research level correctly
    global.spidertron_research_level[force.name] = 0
    for _, research in pairs(spidertron_researches) do
      if force.technologies[research].researched then
        global.spidertron_research_level[force.name] = global.spidertron_research_level[force.name] + 1
      end
    end
  end

  -- Place players in spidertrons
  for _, player in pairs(game.players) do
    player_start(player)
  end

  log("Finished setup(). Research levels set to:\n" .. serpent.block(global.spidertron_research_level))
  log("Spidertrons assigned:\n" .. serpent.block(global.spidertrons))
end
local function config_changed_setup(changed_data)
  -- Only run when this mod was present in the previous save as well. Otherwise, on_init will run.
  -- Case 1: SpidertronEngineer has an entry in mod_changes.
  --   Either because update (old_version ~= nil -> run setup) or addition (old_version == nil -> don't run setup because on_init will).
  -- Case 2: SpidertronEngineer does not have an entry in mod_changes. Therefore run setup.
  log("Configuration changed data: " .. serpent.block(changed_data))
  this_mod_data = changed_data.mod_changes["SpidertronEngineer"]
  if (not this_mod_data) or (this_mod_data["old_version"]) then
    log("Configuration changed setup running")
    setup()
  else
    log("Configuration changed setup not running: not this_mod_data = " .. tostring(not this_mod_data) .. "; this_mod_data['old_version'] = " .. tostring(this_mod_data["old_version"]))
  end
end

script.on_init(setup)
script.on_configuration_changed(config_changed_setup)

-- Kill player upon spidertron death
script.on_event(defines.events.on_entity_died,
  function(event)
    local spidertron = event.entity
    local player = spidertron.last_user

    global.spidertron_colors[player.index] = spidertron.color

    log("Killing player " .. player.name)
    player.character.die("neutral")

    -- Spill all spidertron items onto the ground
    local spidertron_items = store_spidertron_data(player)
    log("Spilling spidertron items onto the ground: " .. serpent.block(spidertron_items))
    for name, count in pairs(merge(spidertron_items.ammo, spidertron_items.trunk)) do
      spidertron.surface.spill_item_stack(spidertron.position, {name=name, count=count}, true, nil, false)
    end
    for _, equipment in pairs(spidertron_items.equipment) do
      spidertron.surface.spill_item_stack(spidertron.position, {name=equipment.name}, true, nil, false)
    end


    global.spidertrons[player.index] = nil
  end,
  {{filter = "name", name = "spidertron-engineer-0"}, 
   {filter = "name", name = "spidertron-engineer-1"},
   {filter = "name", name = "spidertron-engineer-2"},
   {filter = "name", name = "spidertron-engineer-3"},
   {filter = "name", name = "spidertron-engineer-4"},
   {filter = "name", name = "spidertron-engineer-5"}}
)

-- Handle player dies outside of spidertron
script.on_event(defines.events.on_player_died,
  function(event)
    local player = game.get_player(event.player_index)
    local spidertron = global.spidertrons[player.index]
    if spidertron then
      log("Player died outside of spiderton")
      spidertron.die("neutral")
    end
  end
)


-- Keep track of colors
script.on_event(defines.events.on_gui_closed,
  function(event)
    local player = game.get_player(event.player_index)
    local spidertron = global.spidertrons[player.index]
    if spidertron then
      global.spidertron_colors[player.index] = spidertron.color
      log("Setting color for player " .. player.name)
      recolor_spidertron(player, spidertron)
    end
  end
)


-- Upgrade all spidertrons
script.on_event(defines.events.on_research_finished,
  function(event)
    local research = event.research.name
    if contains(spidertron_researches, research) then
      upgrade_spidertrons(research.force)
    end
  end
)

script.on_event(defines.events.on_technology_effects_reset,
  function(event)
    for _, player in pairs(event.force.players) do
      for _, name in pairs(spidertron_names) do
        remove_from_inventory(name, player)
      end
    end
    log("on_technology_effects_reset")
  end
)


-- Intercept fish usage to heal spidertron
script.on_event(defines.events.on_player_used_capsule,
  function(event)
    local player = game.get_player(event.player_index)
    if event.item.name == "raw-fish" then
      log("Fish eaten by " .. player.name)
      global.spidertrons[player.index].damage(-80, player.force, "physical")
    end
  end
)