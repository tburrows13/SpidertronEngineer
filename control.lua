--control.lua

local function create_spidertron(player)
  if player.character then
    log("Creating spidertron for player " .. player.name)
    local spidertron = player.surface.create_entity{name="spidertron-engineer", position=player.position, force="player", player=player, raise_built=true}
    global.spidertrons[player.index] = spidertron
    spidertron.set_driver(player)
  else 
    log("Player " .. player.name .. " has no character") 
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
        create_spidertron(player)
      end
    end
  end
)

-- Player init
script.on_event(defines.events.on_cutscene_cancelled,
  function(event)
    local player = game.get_player(event.player_index)
    create_spidertron(player)
  end
)

script.on_event(defines.events.on_player_respawned,
  function(event)
    local player = game.get_player(event.player_index)
    create_spidertron(player)
  end
)

script.on_event(defines.events.on_player_created,
  function(event)
    local player = game.get_player(event.player_index)
    create_spidertron(player)
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
  {{filter = "name", name = "spidertron-engineer"}}
)