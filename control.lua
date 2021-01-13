--control.lua
require "util"  -- Factorio lualib
require("utils.table-utils")
require("utils.get-banned-items")
spidertron_lib = require("utils.spidertron_lib")

spidertron_researches = {"military", "military-2", "power-armor", "power-armor-mk2", "spidertron"}
spidertron_names = {"spidertron-engineer-0", "spidertron-engineer-1", "spidertron-engineer-2", "spidertron-engineer-3", "spidertron-engineer-4", "spidertron-engineer-5"}
train_names = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}
drivable_names = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon", "car", "spider-vehicle"}

-- We only search for weapons, armor and spidertron items, so don't need ammo etc inventories
inventory_types = {"cargo-wagon", "container", "car", "character", "logistic-container", "spider-vehicle"}
inventory_defines = {["cargo-wagon"] = {defines.inventory.cargo_wagon},
                   ["container"] = {defines.inventory.chest},
                   ["car"] = {defines.inventory.car_trunk},
                   ["character"] = {defines.inventory.character_main, defines.inventory.character_guns, defines.inventory.character_armor, defines.inventory.character_trash},
                   ["logistic-container"] = {defines.inventory.chest},
                   ["spider-vehicle"] = {defines.inventory.spider_trunk, defines.inventory.spider_trash}}

local spidertron_filters = {
   {filter = "name", name = "spidertron-engineer-0"},
   {filter = "name", name = "spidertron-engineer-1"},
   {filter = "name", name = "spidertron-engineer-2"},
   {filter = "name", name = "spidertron-engineer-3"},
   {filter = "name", name = "spidertron-engineer-4"},
   {filter = "name", name = "spidertron-engineer-5"}
}

--[[
/c game.player.force.technologies['military'].researched=true
/c game.player.force.technologies['military-2'].researched=true
/c game.player.force.technologies['power-armor'].researched=true
/c game.player.force.technologies['power-armor-mk2'].researched=true
/c game.player.force.technologies['spidertron'].researched=true
]]

-- Spidertron heal
heal_amount=1

-- repair function
local function create_spidertron_repair_cloud(event)
  local player = game.players[event.player_index]
  if player then
    --works only with repair-pack. If mod add a new type of repair tool, update this
    if (player.vehicle and player.vehicle.remove_item({name="repair-pack", count=1}) == 1)
      or (player.remove_item({name="repair-pack", count=1}) == 1) then
        local surface = player.surface
        surface.create_entity({name="spidertron-repair-cloud", position=player.position})
    else
      player.print({"message.no-repair-packs"})
    end
  else
    game.print("No player found")
  end
end

-- shortcut to activate repair cloud
script.on_event(defines.events.on_lua_shortcut,
  function(event)
    if event.prototype_name == "spidertron-repair" then
      create_spidertron_repair_cloud(event)
    end
  end
)
script.on_event("spidertron-repair", create_spidertron_repair_cloud)

-- if spidertron is damaged - add it to watch list
script.on_event(defines.events.on_entity_damaged,
  function(event)
    if event.entity.unit_number then
      global.spidertrons_to_heal[event.entity.unit_number]=event.entity
    end
  end,
  spidertron_filters
)

-- each 20 ticks for performance reason
script.on_nth_tick(20, function(event)
  if #global.spidertrons_to_heal then
    for k, v in pairs (global.spidertrons_to_heal) do
      if v.valid then
        -- we don't want to apply resists when healing spidertron
        v.health = v.health + heal_amount
        if v.get_health_ratio() == 1 then
          global.spidertrons_to_heal[v.unit_number] = nil
        end
      else
        global.spidertrons_to_heal[k] = nil
        log("Spidertron is invalid")
      end
    end
  end
end
)

local function get_spidertron_level(force)
  local level = 0
  -- Set each force's research level correctly
  for _, research in pairs(spidertron_researches) do
    if force.technologies[research].researched then
      level = level + 1
    end
  end

  -- Also (re)apply inventory bonus
  local bonus = 0
  if force.technologies["toolbelt"] and force.technologies["toolbelt"].researched == true then bonus = 10 end
  force.character_inventory_slots_bonus = 10 * level + bonus

  return level
end

local function get_remote(player, not_connected)
  local spidertron = global.spidertrons[player.index]
  local inventory = player.get_main_inventory()
  if spidertron or not_connected then
    for i = 1, #inventory do
      local item = inventory[i]
      if item.valid_for_read then  -- Check if it isn't an empty inventory slot
        if not_connected then
          if item.prototype.type == "spidertron-remote" and not item.connected_entity then
            return item
          end
        elseif item.connected_entity == spidertron then
          return item
        end
      end
    end
  end
end


local function store_spidertron_data(player)
  -- Removes the player's spidertron from the world and saves data about it in global.spidertron_saved_data[player.index]
  -- Remove player before calling

  local spidertron = global.spidertrons[player.index]
  global.script_placed_into_vehicle[player.index] = true
  global.spidertron_saved_data[player.index] = spidertron_lib.serialise_spidertron(spidertron)
  global.script_placed_into_vehicle[player.index] = false
  return
end

local function place_stored_spidertron_data(player)
  -- Copy across equipment grid
  local saved_data = global.spidertron_saved_data[player.index]
  local spidertron = global.spidertrons[player.index]
  log("Placing saved data back into spidertron:")
  spidertron_lib.deserialise_spidertron(spidertron, saved_data)
  global.spidertron_saved_data[player.index] = nil

end

local function replace_spidertron(player, name)
  -- Don't assume that player is actually in the spidertron

  local previous_spidertron = global.spidertrons[player.index]
  if not name then name = "spidertron-engineer-" .. get_spidertron_level(player.force) end

  log("Upgrading spidertron to level " .. name .. " for player " .. player.name)

  local last_user = previous_spidertron.last_user

  -- Save data to copy across afterwards
  store_spidertron_data(player)
  global.spidertron_destroyed_by_script[previous_spidertron.unit_number] = true

  local spidertron = player.surface.create_entity{
    name = name,
    position = previous_spidertron.position,
    direction = previous_spidertron.direction,
    force = previous_spidertron.force,
    -- Don't set player here or else the previous spidertron item will be inserted into the player's inventory
    fast_replace = true,
    spill = false,
    create_build_effect_smoke = true
  }
  if not spidertron then
    player.teleport(1)
    replace_spidertron(player)
    return
  end

  if last_user ~= nil then
    spidertron.last_user = last_user
  end

  global.spidertrons[player.index] = spidertron
  spidertron.color = player.color
  place_stored_spidertron_data(player)

  previous_spidertron.destroy()
  return spidertron
end

local function ensure_player_is_in_correct_spidertron(player, entity)
  -- This can be called at anytime (and should be called after a significant event has happened that requires a change)
  -- 1. Creates a spidertron for the player, or sets it the correct level if the player already has on_event
  -- 2. Places the player in the spidertron if it needs to be

  if player and player.character then
    local spidertron = global.spidertrons[player.index]


    -- Some checks to see if the spidertron should exist anyway
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


    -- Step 1
    local spidertron_level = get_spidertron_level(player.force)
    local target_name = "spidertron-engineer-" .. spidertron_level
    if spidertron and spidertron.valid then
      if target_name ~= spidertron.name then
        -- Upgrade the spidertron
        spidertron = replace_spidertron(player)
      end
    else
      log("Creating spidertron for player " .. player.name)
      spidertron = player.surface.create_entity{name=target_name, position=player.position, force=player.force, player=player, create_build_effect_smoke = true}
      if not spidertron then
        player.teleport(1)
        ensure_player_is_in_correct_spidertron(player, entity)
        return
      end
      global.spidertrons[player.index] = spidertron
      spidertron.color = player.color
      if previous_spidertron_data then
        place_stored_spidertron_data(player)
      end
    end

    if not spidertron then
      -- This can happen in multiplayer if a second person spawns before the first person moves. Otherwise, it is probably a result of a bug in the above code
      log("Spidertron could not be created. Moving player 1 tile to the right and trying again")
      player.teleport(1)
      ensure_player_is_in_correct_spidertron(player)
      return
    end

    local reg_id = script.register_on_entity_destroyed(spidertron)
    global.registered_spidertrons[reg_id] = player


    -- Step 2
    if player.driving and contains(spidertron_names, player.vehicle.name) and player.vehicle == spidertron then
      log("Already in a spidertron-engineer with name " .. player.vehicle.name .. " (target_name = " .. target_name .. ")")
      return
    else
      -- The player is not in a valid vehicle so exit it if it is in a vehicle
      if player.driving then
        log("Vehicle ".. player.vehicle.name .." is not a valid vehicle")
        global.script_placed_into_vehicle[player.index] = true
        player.driving = false
        global.script_placed_into_vehicle[player.index] = false
      else
        log("Not in a vehicle")
      end

      -- At this stage, we are not driving
      local allowed_to_leave = contains({"limited-time", "unlimited-time"}, global.allowed_to_leave)
      if (not allowed_to_leave) or (allowed_to_leave and (not entity or (not contains(spidertron_names, entity.name) and previous_spidertron_data))) then
        -- Put the player in a spidertron if (we are not ever allowed to leave) or (we are, we haven't come from a spidertron and there is previously saved data)
        global.script_placed_into_vehicle[player.index] = true
        spidertron.set_driver(player)
        global.script_placed_into_vehicle[player.index] = false

        -- Spidertron heal
        if spidertron.get_health_ratio()<1 then
          global.spidertrons_to_heal[spidertron.unit_number] = spidertron
        end
        -- Spidertron heal END

        if (not player.driving) and not (player.vehicle == spidertron) then
          error("Something has interfered with .set_driver()")
        end
      else
        log("Settings allow player to leave spidertron")
      end
    end

    log("Finished ensure_player_is_in_correct_spidertron()")
  end
  log("Not creating spidertron for player - player or character does not exist")
end

local function upgrade_spidertrons(force)
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
      remove_from_inventory(item_stack, player.character)
    end

    -- Give player spidertron remote
    if global.spawn_with_remote then
      player.insert("spidertron-remote")
      local remote = get_remote(player, true)
      if remote then
        remote.connected_entity = global.spidertrons[player.index]
      end
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
    -- Run our surface code a tick after the player changes surface to allow the mod that changes the surface
    -- time to set character etc correctly.
    -- Not multiplayer safe (will desync if a player joins in the tick that the surface change happens, possibly other times)

    local function on_tick_after_changed_surface(inner_event)
      local player = game.get_player(event.player_index)
      local spidertron = global.spidertrons[player.index]
      if spidertron then
        store_spidertron_data(player)
        global.spidertron_destroyed_by_script[spidertron.unit_number] = true
        spidertron.destroy()
        global.spidertrons[player.index] = nil
      end
      ensure_player_is_in_correct_spidertron(player)  -- calls place_stored_spidertron_data()
      script.on_nth_tick(inner_event.tick, nil)  -- deregister the tick handler
    end

    script.on_nth_tick(event.tick + 1, on_tick_after_changed_surface)

  end
)

script.on_event(defines.events.on_player_driving_changed_state,
  function(event)
    log("on_player_driving_changed_state")
    -- Hack to stop recursive calling of event and to stop calling of event interrupting ensure_player_is_in_correct_spidertron
    if global.player_last_driving_change_tick[event.player_index] ~= event.tick and not global.script_placed_into_vehicle[event.player_index] then
      global.player_last_driving_change_tick[event.player_index] = event.tick
      local player = game.get_player(event.player_index)
      local spidertron = global.spidertrons[player.index]
      local allowed_into_entities = global.allowed_into_entities
      if (not player.driving) and spidertron and allowed_into_entities ~= "none" and event.entity and contains(spidertron_names, event.entity.name) then
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
      ensure_player_is_in_correct_spidertron(player, event.entity)
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

  -- Spidertron heal
  global.spidertrons_to_heal = global.spidertrons_to_heal or {}

  global.spawn_with_remote = settings.global["spidertron-engineer-spawn-with-remote"].value
  global.player_last_driving_change_tick = {}
  global.spidertron_saved_data_trunk_filters = global.spidertron_saved_data_trunk_filters or {}
  global.registered_spidertrons = global.registered_spidertrons or {}
  global.spidertron_destroyed_by_script = global.spidertron_destroyed_by_script or {}
  global.script_placed_into_vehicle = global.script_placed_into_vehicle or {}

  global.banned_items = get_banned_items(
    game.get_filtered_item_prototypes({{filter = "type", type = "gun"}}),  -- Guns
    game.get_filtered_item_prototypes({{filter = "type", type = "armor"}}),  -- Armor
    game.get_filtered_recipe_prototypes({{filter = "has-ingredient-item", elem_filters = {{filter = "type", type = "gun"}, {filter = "type", type = "armor"}}}})  -- Recipes
  )
  for _, name in pairs(spidertron_names) do
    table.insert(global.banned_items, name)
  end

  for _, force in pairs(game.forces) do 
    local resource_reach_distance = game.forces["player"].character_resource_reach_distance_bonus
    force.character_resource_reach_distance_bonus = resource_reach_distance + 3
    local build_distance_bonus = game.forces["player"].character_build_distance_bonus
    force.character_build_distance_bonus = build_distance_bonus + 3
    local reach_distance_bonus = game.forces["player"].character_reach_distance_bonus
    force.character_reach_distance_bonus = reach_distance_bonus + 3
  end

  for _, force in pairs(game.forces) do
    for name, _ in pairs(force.recipes) do
      if contains(global.banned_items, name) and force.recipes[name].enabled then
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
      if contains(global.banned_items, name) then
        for _, surface in pairs(game.surfaces) do
          -- Check train cars, chests, cars, player inventories, and logistics chests.
          for _, entity in pairs(surface.find_entities_filtered{type=inventory_types, force=force}) do
            remove_from_inventory(name, entity)
          end
        end
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


  log("Finished setup()")
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

  -- Regenerate banned item list (in case new mods have been added or compatibility mode has been turned on)
  global.banned_items = get_banned_items(
    game.get_filtered_item_prototypes({{filter = "type", type = "gun"}}),  -- Guns
    game.get_filtered_item_prototypes({{filter = "type", type = "armor"}}),  -- Armor
    game.get_filtered_recipe_prototypes({{filter = "has-ingredient-item", elem_filters = {{filter = "type", type = "gun"}, {filter = "type", type = "armor"}}}})  -- Recipes
  )
  for _, name in pairs(spidertron_names) do
    table.insert(global.banned_items, name)
  end


  if this_mod_data and this_mod_data["old_version"] and changed_data.mod_startup_settings_changed then
    -- Replace spidertron in case its size was changed
    for _, player in pairs(game.players) do
      if contains(spidertron_names, player.vehicle) then
        replace_spidertron(player, "spidertron-engineer-5a")  -- Can't directly fast-replace the same entity so use the 5a dummy
        local spidertron = replace_spidertron(player)
        spidertron.color = player.color
        global.spidertrons[player.index] = spidertron
        spidertron.set_driver(player)
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
    if old_version[2] < 8 then
      log("Running pre-1.8.0 migration")
      for player_index, saved_data in pairs(global.spidertron_saved_data) do
        -- Convert saved data into format compatible with spidertron_lib
        local filter_data = global.spidertron_saved_data_trunk_filters[player_index][defines.inventory.spider_trunk]

        saved_data.trunk = {inventory = saved_data.trunk, filters = filter_data}
        saved_data.ammo = {inventory = saved_data.ammo}
        saved_data.vehicle_automatic_targeting_parameters = saved_data.auto_target

        local player = game.get_player(player_index)
        local remote = get_remote(player, true)
        if remote then
          saved_data.connected_remotes = {remote}
        end
      end
      global.spidertron_saved_data_trunk_filters = nil
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

  if spidertron and global.spawn_with_remote then
    local remote = get_remote(player)
    log("Removed remote in entity_died")
    if remote then remote.clear() end
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
  spidertron_filters
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
      spidertron.color = player.color
    end
  end
)


-- Upgrade all spidertrons
script.on_event(defines.events.on_research_finished,
  function(event)
    local research = event.research
    if contains(spidertron_researches, research.name) then
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
  "Usage: `/create-spidertron [playername]`. Creates a spidertron for user or the specified player. Use whenever a player loses their spidertron due to mod incompatibilities",
  function(data)
    local player_name = data.parameter
    local player
    if player_name then
      player = game.get_player(player_name)
    else
      player = game.get_player(data.player_index)
    end

    if player then
      ensure_player_is_in_correct_spidertron(player)
    else
      game.print("Can't find player")
    end
  end
)