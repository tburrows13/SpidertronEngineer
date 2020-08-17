--control.lua
function contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function contains_key(table, element)
  for value, _ in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

local function recolor_spidertron(player, spidertron)
  if global.spidertron_colors[player.index] then 
    spidertron.color = global.spidertron_colors[player.index]
  else 
    spidertron.color = player.color 
  end
  global.spidertron_colors[player.index] = spidertron.color
end

local function replace_spidertron(player)
  local previous_spidertron = global.spidertrons[player.index]
  local name = "spidertron-engineer-" .. global.spidertron_research_level[player.force.name]

  log("Upgrading spidertron to level " .. name .. " for player " .. player.name)

  local last_user = previous_spidertron.last_user

  -- Save equipment grid to copy across afterwards
  local previous_grid_contents = {}
  if previous_spidertron.grid then
    log("Previous spidertron had a grid")
    for _, equipment in pairs(previous_spidertron.grid.equipment) do
      table.insert(previous_grid_contents, {name=equipment.name, position=equipment.position})
    end
  end
  local previous_ammo = previous_spidertron.get_inventory(defines.inventory.car_ammo).get_contents()
  local previous_trunk = previous_spidertron.get_inventory(defines.inventory.car_trunk).get_contents()

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

  -- Copy across equipment grid
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
  local ammo_inventory = spidertron.get_inventory(defines.inventory.car_ammo)
  for name, count in pairs(previous_ammo) do
    if ammo_inventory then ammo_inventory.insert({name=name, count=count})
    else
      player.surface.spill_item_stack(spidertron.position, {name=name, count=count})
    end
  end
  -- Copy across trunk
  local trunk_inventory = spidertron.get_inventory(defines.inventory.car_trunk)
  for name, count in pairs(previous_trunk) do
    if trunk_inventory then trunk_inventory.insert({name=name, count=count})
    else
      player.surface.spill_item_stack(spidertron.position, {name=name, count=count})
    end
  end

  previous_spidertron.destroy()
  return spidertron
end

local function ensure_player_is_in_correct_spidertron(player)
  -- If player is in train, do nothing
  -- If player is in a spidertron-engineer upgrade it if necessary
  -- Otherwise, remove player from any vehicles and put it in its spidertron if it has on, create a spidertron if not


  if player and player.character then
    if player.driving and contains({"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}, player.vehicle.type) then
      -- Ignore if in train - that is allowed
      -- Some global settings may not be set at this point
      log("Player in train. Left alone")
      return
    end

    local spidertron
    local spidertron_level = global.spidertron_research_level[player.force.name]
    local target_name = "spidertron-engineer-" .. spidertron_level
    if spidertron_level > 5 then error("Spidertron is being upgraded to level " .. spidertron_level) end

    if player.driving and contains(global.spidertron_names, player.vehicle.name) then
      log("Already in a spidertron-engineer with name " .. player.vehicle.name .. " (target_name = " .. target_name .. ")")
      -- We are already in a Spidertron Engineer, check if it needs upgrading
      if target_name ~= player.vehicle.name then
        -- Upgrade the spidertron
        spidertron = replace_spidertron(player)
      else
        -- We are in the correct spidertron. Do nothing
        log("Returning")
        return
      end
    else
      -- The player is not in a valid vehicle so exit it if it is in a vehicle
      player.driving = false
      log("Not in a valid vehicle")
      -- Check if a spidertron needs to be created
      spidertron = global.spidertrons[player.index]
      if spidertron then
        log("Player " .. player.name .. " attempted to leave spidertron")
        spidertron.set_driver(player)
        log("Player set to driver")
      else
        log("Creating spidertron for player " .. player.name)
        spidertron = player.surface.create_entity{name=target_name, position=player.position, force=player.force, player=player}
      end
    end

    if not spidertron then error("Spidertron could not be created. Please report this error along with factorio-current.log") end

    player.character_inventory_slots_bonus = 10 * spidertron_level

    global.spidertrons[player.index] = spidertron
    spidertron.set_driver(player)

    recolor_spidertron(player, spidertron)
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
        player.remove_item({name="spidertron-engineer-0"})
        player.remove_item({name="spidertron-engineer-1"})
        player.remove_item({name="spidertron-engineer-2"})
        player.remove_item({name="spidertron-engineer-3"})
        player.remove_item({name="spidertron-engineer-4"})
        player.remove_item({name="spidertron-engineer-5"})
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
      player.character.get_main_inventory().remove(item_stack)
      player.character.get_inventory(defines.inventory.character_guns).remove(item_stack)
      player.character.get_inventory(defines.inventory.character_armor).remove(item_stack)
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

script.on_event(defines.events.on_player_driving_changed_state,
  function(event) 
    log("on_player_driving_changed_state")
    -- Hack to stop recursive calling of event
    if global.player_last_driving_change_tick[event.player_index] ~= event.tick then
      global.player_last_driving_change_tick[event.player_index] = event.tick
      ensure_player_is_in_correct_spidertron(game.get_player(event.player_index)) 
    end
  end
)
script.on_event(defines.events.on_player_toggled_map_editor, function(event) log("on_player_toggled_map_editor") ensure_player_is_in_correct_spidertron(game.get_player(event.player_index)) end)


local function setup()
  log("SpidertronEngineer setup() start")
  global.spidertrons = {}
  global.spidertron_colors = {}
  global.spidertron_research_level = {}  -- Indexed by force
  global.player_last_driving_change_tick = {}
  global.spidertron_researches = {"military", "military-2", "power-armor", "power-armor-mk2", "spidertron"}
  global.spidertron_names = {"spidertron-engineer-0", "spidertron-engineer-1", "spidertron-engineer-2", "spidertron-engineer-3", "spidertron-engineer-4", "spidertron-engineer-5"}
  global.banned_items = {}
  for _, name in pairs(global.spidertron_names) do
    table.insert(global.banned_items, {name=name, count=10000})
  end

  local resource_reach_distance = game.forces["player"].character_resource_reach_distance_bonus 
  game.forces["player"].character_resource_reach_distance_bonus = resource_reach_distance + 3
  local build_distance_bonus = game.forces["player"].character_build_distance_bonus 
  game.forces["player"].character_build_distance_bonus = build_distance_bonus + 3
  local reach_distance_bonus = game.forces["player"].character_reach_distance_bonus
  game.forces["player"].character_reach_distance_bonus = reach_distance_bonus + 3


  function qualifies(name) return game.item_prototypes[name] and (game.item_prototypes[name].type == "gun" or game.item_prototypes[name].type == "armor") end

  function remove_from_inventory(item, entity)
    local count = entity.get_item_count(item)
    if count > 0 then
      entity.remove_item({name=item, count=count})
    end
  end


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
    for _, research in pairs(global.spidertron_researches) do
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
end
--script.on_init(setup)
script.on_configuration_changed(setup)


-- Kill player upon spidertron death
script.on_event(defines.events.on_entity_died,
  function(event)
    local spidertron = event.entity
    local player = spidertron.last_user

    global.spidertron_colors[player.index] = spidertron.color

    log("Killing player " .. player.name)
    player.character.die("neutral")

    global.spidertrons[player.index] = nil
  end,
  {{filter = "name", name = "spidertron-engineer-0"}, 
   {filter = "name", name = "spidertron-engineer-1"},
   {filter = "name", name = "spidertron-engineer-2"},
   {filter = "name", name = "spidertron-engineer-3"},
   {filter = "name", name = "spidertron-engineer-4"},
   {filter = "name", name = "spidertron-engineer-5"}}
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
    if contains(global.spidertron_researches, research) then
      upgrade_spidertrons(research.force)
    end
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