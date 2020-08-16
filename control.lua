--control.lua

local function recolor_spidertron(player, spidertron)
  if global.spidertron_colors[player.index] then 
    spidertron.color = global.spidertron_colors[player.index]
  else 
    spidertron.color = player.color 
  end
  global.spidertron_colors[player.index] = spidertron.color
end

local function create_spidertron(player, previous_spidertron)
  -- Creates a Spidertron and puts the player in it
  -- If previous_spidertron is given, it upgrades from that one

  if player.character then
    local spidertron
    if previous_spidertron == nil then
      log("Creating spidertron for player " .. player.name)

      local upgrade_level = global.spidertron_research_level
      spidertron = player.surface.create_entity{name="spidertron-engineer-" .. upgrade_level, position=player.position, force="player", player=player, raise_built=true}
    else
      local name = "spidertron-engineer-" .. string.sub(previous_spidertron.name, -1) + 1
      log("Upgrading spidertron to level " .. name .. " for player " .. player.name)
      local last_user = previous_spidertron.last_user

      -- Save equipment grid to copy across afterwards
      local previous_grid_contents = {}
      if previous_spidertron.grid then
        log("Previous spidertron had a grid")
        for _, equipment in ipairs(previous_spidertron.grid.equipment) do
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
        fast_replace = true,
        spill = false
      }
      if last_user ~= nil then
        spidertron.last_user = last_user
      end

      -- Copy across equipment grid
      if previous_grid_contents then
        local items_to_insert = {}
        for _, equipment in ipairs(previous_grid_contents) do
          spidertron.grid.put( {name=equipment.name, position=equipment.position} )
        end
      end
      -- Copy across ammo
      for name, count in pairs(previous_ammo) do
        spidertron.get_inventory(defines.inventory.car_ammo).insert({name=name, count=count})
      end
      -- Copy across trunk
      for name, count in pairs(previous_trunk) do
        spidertron.get_inventory(defines.inventory.car_trunk).insert({name=name, count=count})
      end
      -- Copy across equipment grid
      --serpent.dumps(spidertron.get_inventory(defines.car_ammo))
      --local inventory = previous_spidertron.get_inventory(defines.inventory.car_ammo)
      --spidertron.get_main_inventory().insert(previous_spidertron.get_main_inventory().get_contents())
      --spidertron.get_inventory(defines.car_ammo).insert(previous_spidertron.get_inventory(defines.car_ammo).get_contents())

      --local ammo_inventory = previous_spidertron.get_inventory(defines.car_ammo)

      previous_spidertron.destroy()
    end

    recolor_spidertron(player, spidertron)
    
    global.spidertrons[player.index] = spidertron
    spidertron.set_driver(player)
  else 
    log("Cannot create Spidertron for player " .. player.name .. " - has no character") 
  end
end

local function place_player_in_spidertron(player)
  if not player.driving and player.character then
    log("Placing " .. player.name .. " in spidertron")
    spidertron = global.spidertrons[player.index]
    spidertron.set_driver(player)
  end
end

local function upgrade_spidertrons()
  global.spidertron_research_level = global.spidertron_research_level + 1
  if global.spidertron_research_level > 5 then
    log("Spidertron already at max level")
    do return end
  end

  for player_index, spidertron in pairs(global.spidertrons) do
    log("Replacing spidertron for player " .. game.get_player(player_index).name)
    
    local player = game.get_player(player_index)
    player.character_inventory_slots_bonus = player.character_inventory_slots_bonus + 10

    create_spidertron(player, spidertron)
    -- Remove 'added' items
    player.remove_item({name="spidertron-engineer-0"})
    player.remove_item({name="spidertron-engineer-1"})
    player.remove_item({name="spidertron-engineer-2"})
    player.remove_item({name="spidertron-engineer-3"})
    player.remove_item({name="spidertron-engineer-4"})
    player.remove_item({name="spidertron-engineer-5"})
  end
end

script.on_init(
  function()
    global.spidertrons = {}
    global.spidertron_colors = {}
    global.spidertron_research_level = 0

    local resource_reach_distance = game.forces["player"].character_resource_reach_distance_bonus 
    game.forces["player"].character_resource_reach_distance_bonus = resource_reach_distance + 3
  
    function qualifies(name) return game.item_prototypes[name] and (game.item_prototypes[name].type == "gun" or game.item_prototypes[name].type == "armor") end

    function remove_from_inventory(item, entity)
      local count = entity.get_item_count(item)
      if count > 0 then
        entity.remove_item({name=item, count=count})
      end
    end

    local banned_items = {}

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
          table.insert(banned_items, {name=name})
          for _, surface in pairs(game.surfaces) do
            -- Check train cars, chests, cars, player inventories, and logistics chests.
            local types = {"cargo-wagon", "container", "car", "character", "logistic-container"}
            for _, entity in pairs(surface.find_entities_filtered{type=types, force=force}) do
              remove_from_inventory(name, entity)
            end
            
          end
        end
      end
    end

    -- Place players in spidertrons
    for _, player in pairs(game.players) do
      -- Check players' gun and armor slots
      for _, item_name in pairs(banned_items) do
        player.character.get_inventory(defines.inventory.character_guns).remove(item_name)
        player.character.get_inventory(defines.inventory.character_armor).remove(item_name)
      end

      create_spidertron(player)
    end

    for _, force in pairs(game.forces) do
      if force.technologies["military"].researched then
        for _, player in pairs(force.players) do
          upgrade_spidertrons(player)
        end
      end
      if force.technologies["military-2"].researched then
        for _, player in pairs(force.players) do
          upgrade_spidertrons(player)
        end
      end
      if force.technologies["power-armor"].researched then
        for _, player in pairs(force.players) do
          upgrade_spidertrons(player)
        end
      end
      if force.technologies["power-armor-mk2"].researched then
        for _, player in pairs(force.players) do
          upgrade_spidertrons(player)
        end
      end
      if force.technologies["spidertron"].researched then
        for _, player in pairs(force.players) do
          upgrade_spidertrons(player)
        end
      end
    end
  end
)

-- Player init
script.on_event(defines.events.on_cutscene_cancelled,
  function(event)
    local player = game.get_player(event.player_index)
    create_spidertron(player)

    -- Remove starting pistol
    player.remove_item({name="pistol"})

  end
)

script.on_event(defines.events.on_player_respawned,
  function(event)
    local player = game.get_player(event.player_index)
    create_spidertron(player)

    -- Remove starting pistol
    player.remove_item({name="pistol"})
  end
)

script.on_event(defines.events.on_player_created,
  function(event)
    local player = game.get_player(event.player_index)
    create_spidertron(player)

    -- Remove starting pistol
    player.remove_item({name="pistol"})
  end
)

-- Keep player in spidertron
script.on_event(defines.events.on_player_driving_changed_state,
  function(event)
    local player = game.get_player(event.player_index)
    place_player_in_spidertron(player)
  end
)

script.on_event(defines.events.on_player_toggled_map_editor,
  function(event)
    local player = game.get_player(event.player_index)
    place_player_in_spidertron(player)
  end
)


-- Kill player upon spidertron death
script.on_event(defines.events.on_entity_died,
  function(event)
    local spidertron = event.entity
    local player = spidertron.last_user

    global.spidertron_colors[player.index] = spidertron.color

    log("Killing player " .. player.name)
    player.character.die("neutral")
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
    if research == "military" or research == "military-2" or research == "power-armor" or research == "power-armor-mk2" or research == "spidertron" then
      upgrade_spidertrons()
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
