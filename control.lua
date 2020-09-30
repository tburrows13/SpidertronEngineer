--control.lua
require "util"  -- Factorio lualib
require("utils.table-utils")
require("utils.get-banned-items")

spidertron_researches = {"military", "military-2", "power-armor", "power-armor-mk2", "spidertron"}
spidertron_names = {"spidertron-engineer-0", "spidertron-engineer-1", "spidertron-engineer-2", "spidertron-engineer-3", "spidertron-engineer-4", "spidertron-engineer-5"}
train_names = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}
drivable_names = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon", "car", "spider-vehicle"}
--[[
/c game.player.force.technologies['military'].researched=true
/c game.player.force.technologies['military-2'].researched=true
/c game.player.force.technologies['power-armor'].researched=true
/c game.player.force.technologies['power-armor-mk2'].researched=true
/c game.player.force.technologies['spidertron'].researched=true
]]

local function recolor_spidertron(player, spidertron)
  if global.spidertron_colors[player.index] then 
    spidertron.color = global.spidertron_colors[player.index]
  else
    spidertron.color = player.color
  end
  global.spidertron_colors[player.index] = spidertron.color
end

local function get_remote(player, not_connected)
  local spidertron = global.spidertrons[player.index]
  local inventory = player.get_main_inventory()
  if spidertron then
    for i = 1, #inventory do
      local item = inventory[i]
      if item.valid_for_read then  -- Check if it isn't an empty inventory slot
        if item.connected_entity == spidertron then
          return item
        end
        if not_connected and item.prototype.type == "spidertron-remote" and not item.connected_entity then
          return item
        end
      end
    end
  end
end

local function copy_inventory(player_index, old_inventory, inventory, surface, position)
  if not inventory then
    inventory = game.create_inventory(#old_inventory)
  end

  local filter_table
  if not inventory.supports_filters() and old_inventory.supports_filters() then
    -- Store the filters in global
    global.spidertron_saved_data_trunk_filters[player_index] = global.spidertron_saved_data_trunk_filters[player_index] or {}
    local filter_tables = global.spidertron_saved_data_trunk_filters[player_index]
    filter_tables[old_inventory.index] = filter_tables[old_inventory.index] or {}
    filter_table = filter_tables[old_inventory.index]
  elseif inventory.supports_filters() and not old_inventory.supports_filters() and global.spidertron_saved_data_trunk_filters[player_index] then
    filter_table = global.spidertron_saved_data_trunk_filters[player_index][inventory.index]
  else
    filter_table = nil
  end

  local newsize = #inventory
  for i = 1, #old_inventory do
    if i <= newsize then
      local transferred = inventory[i].transfer_stack(old_inventory[i])
      if not transferred then
        -- If for some reason only part of the stack was transferred then the whole stack will also be spilled here,
        -- leading to item duplication. I can't see how a partial stack transfer is possible.
        log("Spilling spidertron inventory stack onto ground")
        surface.spill_item_stack(position, old_inventory[i], true, nil, false)
      end
      --[[ Doesn't work - requires https://forums.factorio.com/viewtopic.php?f=28&t=89674
      if old_inventory.supports_filters() and inventory.supports_filters() then
        local filter = old_inventory.get_filter(i)
        if filter then
          inventory.set_filter(i, filter)
        end
      end
      ]]
      if not inventory.supports_filters() and old_inventory.supports_filters() then
        -- Store it in global instead
        filter_table[i] = old_inventory.get_filter(i)
      elseif inventory.supports_filters() and not old_inventory.supports_filters() then
        -- Retrieve filters from global
        if filter_table and filter_table[i] then
          inventory.set_filter(i, filter_table[i])
        end
      end
    else
      -- If the new inventory is smaller than the previous
      log("Spilling spidertron inventory stack onto ground")
      surface.spill_item_stack(position, old_inventory[i], true, nil, false)
    end
  end
  return inventory
end

local function store_spidertron_data(player)
  -- Removes the player's spidertron from the world and saves data about it in global.spidertron_saved_data[player.index]
  -- Remove player before calling

  local spidertron = global.spidertrons[player.index]
  local grid_contents = {}
  if spidertron.grid then
    for _, equipment in pairs(spidertron.grid.equipment) do
      local equipment_data = {name=equipment.name, position=equipment.position, energy=equipment.energy, shield=equipment.shield, burner=equipment.burner}
      if equipment.burner then  -- e.g. BurnerGenerator mod
        equipment_data.burner_inventory = copy_inventory(nil, equipment.burner.inventory)
        equipment_data.burner_burnt_result_inventory = copy_inventory(nil, equipment.burner.burnt_result_inventory)
        equipment_data.burner_burner_heat = equipment.burner.heat
        equipment_data.burner_currently_burning = equipment.burner.currently_burning
        equipment_data.burner_remaining_burning_fuel = equipment.burner.remaining_burning_fuel
      end
      table.insert(grid_contents, equipment_data)
    end
  end

  local trunk = copy_inventory(player.index, spidertron.get_inventory(defines.inventory.car_trunk))
  local ammo = copy_inventory(player.index, spidertron.get_inventory(defines.inventory.car_ammo))
  local auto_target = spidertron.vehicle_automatic_targeting_parameters
  local autopilot_destination = spidertron.autopilot_destination

  global.spidertron_saved_data[player.index] = {index = player.index, equipment = grid_contents, trunk = trunk, ammo = ammo, auto_target = auto_target, autopilot_destination = autopilot_destination}
  return {index = player.index, equipment = grid_contents, ammo = ammo, trunk = trunk}
end

local function place_stored_spidertron_data(player)
  -- Copy across equipment grid
  local saved_data = global.spidertron_saved_data[player.index]
  local spidertron = global.spidertrons[player.index]
  log("Placing saved data back into spidertron:")
  local previous_grid_contents = saved_data.equipment
  if previous_grid_contents then
    local items_to_insert = {}
    for _, equipment in pairs(previous_grid_contents) do
      if spidertron.grid then
        local placed_equipment = spidertron.grid.put( {name=equipment.name, position=equipment.position} )
        if placed_equipment then
          if equipment.energy then placed_equipment.energy = equipment.energy end
          if equipment.shield and equipment.shield > 0 then placed_equipment.shield = equipment.shield end
          if equipment.burner then
            copy_inventory(nil, equipment.burner_inventory, placed_equipment.burner.inventory)
            copy_inventory(nil, equipment.burner_burnt_result_inventory, placed_equipment.burner.burnt_result_inventory)
            if equipment.heat then placed_equipment.burner.heat = equipment.burner_heat end
            placed_equipment.burner.currently_burning = equipment.burner_currently_burning
            placed_equipment.burner.remaining_burning_fuel = equipment.burner_remaining_burning_fuel
          end
        else  -- No space in the grid because we have moved to a smaller grid
          player.surface.spill_item_stack(spidertron.position, {name=equipment.name})
        end
      else  -- No space in the grid because we have 'upgraded' to no grid
        player.surface.spill_item_stack(spidertron.position, {name=equipment.name})
      end
    end
  end

  -- Copy across trunk
  copy_inventory(player.index, saved_data.trunk, spidertron.get_inventory(defines.inventory.car_trunk), spidertron.surface, spidertron.position)
  saved_data.trunk.destroy()
  -- Copy across ammo
  copy_inventory(player.index, saved_data.ammo, spidertron.get_inventory(defines.inventory.car_ammo), spidertron.surface, spidertron.position)
  saved_data.ammo.destroy()

  -- Copy across auto-target settings
  local auto_target = saved_data.auto_target
  if auto_target then
    spidertron.vehicle_automatic_targeting_parameters = auto_target
  end

  -- Copy across autopilot destination (from spidertron remote)
  local autopilot_destination = saved_data.autopilot_destination
  if autopilot_destination then
    spidertron.autopilot_destination = autopilot_destination
  end

  -- Make player's remote point to new spidertron
  local remote = get_remote(player, true)
  if remote then
    remote.connected_entity = spidertron
  end

  global.spidertron_saved_data[player.index] = nil
end

local function replace_spidertron(player, name)
  local previous_spidertron = global.spidertrons[player.index]
  if not name then name = "spidertron-engineer-" .. global.spidertron_research_level[player.force.name] end

  log("Upgrading spidertron to level " .. name .. " for player " .. player.name)

  local last_user = previous_spidertron.last_user

  -- Save data to copy across afterwards
  store_spidertron_data(player)
  global.spidertron_destroyed_by_script[previous_spidertron.unit_number] = true

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
    if previous_spidertron_data and player.driving and
    (global.allowed_into_entities == "all" or (global.allowed_into_entities == "limited" and contains(train_names, player.vehicle.type))) then
      -- Ignore if in train or if allowed to be in an entity by settings - that is allowed (if we are already 'in' a spidertron)
      log("Player in train or allowed vehicle. Left alone")
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
      if spidertron and spidertron.valid then
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

    if not spidertron then
      log("Spidertron could not be created. Moving player 1 tile to the right")
      player.teleport(1)
      ensure_player_is_in_correct_spidertron(player)
      return
    end

    local bonus = 0
    if player.force.technologies["toolbelt"] and player.force.technologies["toolbelt"].researched == true then bonus = 10 end
    player.force.character_inventory_slots_bonus = 10 * spidertron_level + bonus

    global.spidertrons[player.index] = spidertron
    spidertron.set_driver(player)

    recolor_spidertron(player, spidertron)

    local reg_id = script.register_on_entity_destroyed(spidertron)
    global.registered_spidertrons[reg_id] = player

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

    -- Give player spidertron remote
    if global.spawn_with_remote then
      player.insert("spidertron-remote")
      local remote = get_remote(player, true)
      remote.connected_entity = global.spidertrons[player.index]
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
    if player.character then
      local spidertron = global.spidertrons[player.index]
      global.spidertron_destroyed_by_script[spidertron.unit_number] = true
      spidertron.destroy()
      global.spidertrons[player.index] = nil
      log("Entering ensure")
      ensure_player_is_in_correct_spidertron(player)  -- calls place_stored_spidertron_data()
    end
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
      local allowed_into_entities = global.allowed_into_entities
      if (not player.driving) and spidertron and allowed_into_entities ~= "none" then
        -- See if there is a valid entity nearby that we can enter
        log("Searching for nearby entities to enter")
        for radius=1,5 do
          local nearby_entities
          if allowed_into_entities == "limited" then
            nearby_entities = player.surface.find_entities_filtered{position=spidertron.position, radius=radius, type=train_names}
          elseif allowed_into_entities == "all" then
            nearby_entities = player.surface.find_entities_filtered{position=spidertron.position, radius=radius, type=drivable_names}
          end
          if nearby_entities and #nearby_entities >= 1 then
            local entity_to_drive = nearby_entities[1]
            if not contains(spidertron_names, entity_to_drive.name) then
              log("Found entity to drive: " .. entity_to_drive.name)
              entity_to_drive.set_driver(player)
              store_spidertron_data(player)
              global.spidertron_destroyed_by_script[spidertron.unit_number] = true
              spidertron.destroy()
              global.spidertrons[player.index] = nil
              return
            end
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

  global.allowed_into_entities = settings.global["spidertron-engineer-allowed-into-entities"].value


  local previous_setting = global.spawn_with_remote
  global.spawn_with_remote = settings.global["spidertron-engineer-spawn-with-remote"].value
  log("Previous setting = " .. tostring(previous_setting) .. ". Current setting = " .. tostring(global.spawn_with_remote))
  if global.spawn_with_remote and not previous_setting then
    log("Player turned on 'spawn with remote'")
    -- We have just turned the setting on
    for _, player in pairs(game.players) do
      player_start(player)
    end
  end
end
script.on_event(defines.events.on_runtime_mod_setting_changed, settings_changed)

local function setup()
  log("SpidertronEngineer setup() start")
  log(settings.global["spidertron-engineer-spawn-with-remote"].value)
  global.spawn_with_remote = settings.global["spidertron-engineer-spawn-with-remote"].value
  global.spidertron_research_level = {}  -- Indexed by force
  global.player_last_driving_change_tick = {}
  global.spidertron_saved_data_trunk_filters = global.spidertron_saved_data_trunk_filters or {}
  global.registered_spidertrons = global.registered_spidertrons or {}
  global.spidertron_destroyed_by_script = global.spidertron_destroyed_by_script or {}

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

  local function qualifies(name) return game.item_prototypes[name] and --[[(game.item_prototypes[name].type == "gun" or ]] game.item_prototypes[name].type == "armor"--[[)]] end

  for _, force in pairs(game.forces) do
    for name, _ in pairs(force.recipes) do
      if qualifies(name) and force.recipes[name].enabled then
        force.recipes[name].enabled = false

        -- And update assemblers
        for _, surface in pairs(game.surfaces) do
          for _, entity in pairs(surface.find_entities_filtered{type="assembling-machine", force=force}) do
            local recipe = entity.get_recipe()
            if recipe ~= nil and recipe.name == name then
              entity.set_recipe(nil)
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

    --Enable/disable recipes (some mods eg space exploration remove the technology anyway)
    if force.technologies["space-science-pack"] and force.technologies["space-science-pack"].researched == true and settings.startup["spidertron-engineer-space-science-to-fish"].value then
      force.recipes["spidertron-engineer-raw-fish"].enabled = true
    end

  end

  settings_changed()

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
  local this_mod_data = changed_data.mod_changes["SpidertronEngineer"]
  if (not this_mod_data) or (this_mod_data["old_version"]) then
    log("Configuration changed setup running")
    setup()
  else
    log("Configuration changed setup not running: not this_mod_data = " .. tostring(not this_mod_data) .. "; this_mod_data['old_version'] = " .. tostring(this_mod_data["old_version"]))
  end

  if this_mod_data and this_mod_data["old_version"] and changed_data.mod_startup_settings_changed then
    -- Replace spidertron in case its size was changed
    for _, player in pairs(game.players) do
      if contains(spidertron_names, player.vehicle) then
        replace_spidertron(player, "spidertron-engineer-5a")  -- Can't directly fast-replace the same entity so use the 5a dummy
        local spidertron = replace_spidertron(player)
        global.spidertrons[player.index] = spidertron
        spidertron.set_driver(player)
        recolor_spidertron(player, spidertron)
      end
    end
  end

  -- Taken from SpidertronWaypoints
  local old_version
  local mod_changes = changed_data.mod_changes
  if mod_changes and mod_changes["SpidertronEngineer"] and mod_changes["SpidertronEngineer"]["old_version"] then
    old_version = mod_changes["SpidertronEngineer"]["old_version"]
  else
    return
  end

  old_version = util.split(old_version, ".")
  for i=1,#old_version do
    old_version[i] = tonumber(old_version[i])
  end
  if old_version[1] == 1 then
    if old_version[2] <= 6 and old_version[3] < 3 then
      -- Run on 1.6.3 load
      log("Running pre-1.6.3 migration")
      for _, spidertron_data in pairs(global.spidertron_saved_data) do
        local previous_trunk = spidertron_data.trunk
        local trunk_inventory = game.create_inventory(500)
        for name, count in pairs(previous_trunk) do
          trunk_inventory.insert({name=name, count=count})
        end
        spidertron_data.trunk = trunk_inventory
        local previous_ammo = spidertron_data.ammo
        local ammo_inventory = game.create_inventory(500)
        for name, count in pairs(previous_ammo) do
          ammo_inventory.insert({name=name, count=count})
        end
        spidertron_data.ammo = ammo_inventory
      end
    end
  end
end

local function space_exploration_compat()
  if remote.interfaces["space-exploration"] then
    local on_player_respawned = remote.call("space-exploration", "get_on_player_respawned_event")
    script.on_event(on_player_respawned, function(event)
      log("SE: on_player_respawned")
      local player = game.get_player(event.player_index)
      local spidertron = global.spidertrons[player.index]
      if spidertron and spidertron.valid then
        on_spidertron_died(spidertron, player, true)
      end
      player_start(game.get_player(event.player_index))
    end)
  end

end
script.on_load(space_exploration_compat)
script.on_init(
  function()
    global.spidertrons = {}
    global.spidertron_colors = {}
    global.spidertron_saved_data = {}
    global.spidertron_saved_data_trunk_filters = {}
    space_exploration_compat()
    setup()
  end
)
script.on_configuration_changed(config_changed_setup)

-- Kill player upon spidertron death
function on_spidertron_died(spidertron, player, keep_player)
  -- Also called on spidertron destroyed, so spidertron = nil
  if not player then player = spidertron.last_user end

  if spidertron then
    global.spidertron_colors[player.index] = spidertron.color

    if global.spawn_with_remote then
      local remote = get_remote(player)
      log("Removed remote in entity_died")
      if remote then remote.clear() end
    end

    -- Spill all spidertron items onto the ground
    local spidertron_items = store_spidertron_data(player)
    log("Spilling spidertron items onto the ground")
    for i = 1, #spidertron_items.ammo do
      local item_stack = spidertron_items.ammo[i]
      if item_stack and item_stack.valid_for_read then
        spidertron.surface.spill_item_stack(spidertron.position, {name=item_stack.name, count=item_stack.count}, true, nil, false)
      end
    end
    for i = 1, #spidertron_items.trunk do
      local item_stack = spidertron_items.trunk[i]
      if item_stack and item_stack.valid_for_read then
        spidertron.surface.spill_item_stack(spidertron.position, {name=item_stack.name, count=item_stack.count}, true, nil, false)
      end
    end
    for _, equipment in pairs(spidertron_items.equipment) do
      spidertron.surface.spill_item_stack(spidertron.position, {name=equipment.name}, true, nil, false)
    end
  end

  if keep_player then
    spidertron.set_driver(nil)
    global.spidertron_destroyed_by_script[spidertron.unit_number] = true
    spidertron.destroy()
  else
    if player.character then
      log("Killing player " .. player.name)
      player.character.die("neutral")
    end
  end

  global.spidertrons[player.index] = nil
  global.spidertron_saved_data[player.index] = nil
end

script.on_event(defines.events.on_entity_died,
  function(event)
    local spidertron = event.entity
    global.spidertron_destroyed_by_script[spidertron.unit_number] = true
    on_spidertron_died(spidertron)
  end,
  {{filter = "name", name = "spidertron-engineer-0"}, 
   {filter = "name", name = "spidertron-engineer-1"},
   {filter = "name", name = "spidertron-engineer-2"},
   {filter = "name", name = "spidertron-engineer-3"},
   {filter = "name", name = "spidertron-engineer-4"},
   {filter = "name", name = "spidertron-engineer-5"}}
)

script.on_event(defines.events.on_entity_destroyed,
  function(event)
    local reg_id = event.registration_number
    local unit_number = event.unit_number
    if global.spidertron_destroyed_by_script[unit_number] then
      global.spidertron_destroyed_by_script[unit_number] = nil
      return
    end

    if contains_key(global.registered_spidertrons, reg_id, true) then
      local player = global.registered_spidertrons[reg_id]
      on_spidertron_died(nil, player)
      global.registered_spidertrons[reg_id] = nil
    end
    global.spidertrons[unit_number] = nil
  end
)


script.on_event(defines.events.on_pre_player_died,
  function(event)
    local player = game.get_player(event.player_index)
    if global.spawn_with_remote then
      local remote = get_remote(player)
      log("Removed remote in pre_player_died")
      if remote then remote.clear() end
    end
  end
)

-- Handle player dies outside of spidertron
script.on_event(defines.events.on_player_died,
  function(event)
    local player = game.get_player(event.player_index)
    local spidertron = global.spidertrons[player.index]
    if spidertron and spidertron.valid then
      log("Player died outside of spiderton")
      spidertron.die("neutral")
    end
  end
)

script.on_event({defines.events.on_player_left_game, defines.events.on_player_kicked, defines.events.on_player_banned},
  function(event)
    local spidertron = global.spidertrons[event.player_index]
    if spidertron then
      store_spidertron_data({index = event.player_index})
      global.spidertron_destroyed_by_script[spidertron.unit_number] = true
      spidertron.destroy()
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
    local item_name = event.item.name
    -- Could probably be improved to work generically in the future
    if game.active_mods["space-exploration"] then
      if item_name == "se-medpack" then
        global.spidertrons[player.index].damage(-50, player.force, "poison")
      elseif item_name == "se-medpack-2" then
        global.spidertrons[player.index].damage(-100, player.force, "poison")
      elseif item_name == "se-medpack-3" then
        global.spidertrons[player.index].damage(-200, player.force, "poison")
      elseif item_name == "se-medpack-4" then
        global.spidertrons[player.index].damage(-400, player.force, "poison")
      end
    else
      if item_name == "raw-fish" then
        log("Fish eaten by " .. player.name)
        global.spidertrons[player.index].damage(-80, player.force, "poison")
      end
    end
  end
)

commands.add_command("create-spidertron",
  "Usage: `/create-spidertron playername`. Creates a spidertron for the specified player. Use whenever a player loses their spidertron due to mod incompatibilities (such as after respawning in Space Exploration)",
  function(data)
    local player_name = data.parameter
    if player_name then
      local player = game.get_player(player_name)
      if player then
        ensure_player_is_in_correct_spidertron(player)
      else
        game.print(player_name .. " is not a valid player")
      end
    else
      game.print("No player specified. Usage: `/create-spidertron playername`")
    end
  end
)