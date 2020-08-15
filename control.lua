--control.lua

local function create_spidertron(player, upgrade_level, previous_spidertron)
  -- Creates a Spidertron level <upgrade_level> and puts the player in it
  -- If previous_spidertron is given, it upgrades from that one

  if player.character then
    log("Creating spidertron for player " .. player.name)
    local spidertron
    if previous_spidertron == nil then
      spidertron = player.surface.create_entity{name="spidertron-engineer-" .. upgrade_level, position=player.position, force="player", player=player, raise_built=true}
    else
      local name = "spidertron-engineer-" .. string.sub(previous_spidertron.name, -1) + 1
      spidertron = player.surface.create_entity{
        name = name,
        position = previous_spidertron.position,
        direction = previous_spidertron.direction,
        force = previous_spidertron.force,
        fast_replace = true,
        player = previous_spidertron.last_user,
      }
      previous_spidertron.destroy()
    end

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

script.on_init(
  function()
    global.spidertrons = {}
    local resource_reach_distance = game.forces["player"].character_resource_reach_distance_bonus 
    game.forces["player"].character_resource_reach_distance_bonus = resource_reach_distance + 3

    -- Place players in spidertrons
    for _, player in pairs(game.players) do
      if not player.driving and player.character then
        create_spidertron(player, 1)
      end
    end
  end
)

-- Player init
script.on_event(defines.events.on_cutscene_cancelled,
  function(event)
    local player = game.get_player(event.player_index)
    create_spidertron(player, 1)
  end
)

script.on_event(defines.events.on_player_respawned,
  function(event)
    local player = game.get_player(event.player_index)
    create_spidertron(player, 1)
  end
)

script.on_event(defines.events.on_player_created,
  function(event)
    local player = game.get_player(event.player_index)
    create_spidertron(player, 1)
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
    log("Killing player " .. player.name)
    player.character.die("neutral")
  end,
  {{filter = "name", name = "spidertron-engineer-1"}}
)


script.on_event(defines.events.on_player_toggled_alt_mode,
  function(event)
    log("alt mode")

    for player_index, spidertron in pairs(global.spidertrons) do
      log("Replacing spidertron")
      local player = game.get_player(player_index)
      create_spidertron(player, nil, spidertron)
    end
  end
)