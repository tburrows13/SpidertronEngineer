-- Repair input and shortcut
data:extend{
  {
    type = "custom-input",
    name = "spidertron-repair",
    key_sequence = "",
    action = "lua",
    consuming = "none"
  },
  {
    type = "shortcut",
    name = "spidertron-repair",
    order = "s[spidertron]",
    action = "lua",
    associated_control_input = "spidertron-repair",
    localised_name = {"shortcut.spidertron-repair"},
    icon = {
      filename = "__base__/graphics/icons/repair-pack.png",
      size = 64,
    }
  }
}

-- Repair smoke
data:extend{
  {
    name = "spidertron-repair-cloud",
    type = "smoke-with-trigger",
    flags = {"not-on-map"},
    show_when_smoke_off = true,
    particle_count = 6,
    particle_spread = { 5, 5 * 0.7 },
    particle_distance_scale_factor = 0.5,
    particle_scale_factor = { 1, 0.707 },
    spread_duration_variation = 20,
    particle_duration_variation = 10 * 3,
    render_layer = "object",

    affected_by_wind = false,
    cyclic = true,
    duration = 20*60,
    fade_away_duration = 60,
    spread_duration = 20,
    color = {r = 0.2, g = 0.2, b = 1, a = 0.1},

    animation =
    {
      width = 152,
      height = 120,
      line_length = 5,
      frame_count = 60,
      shift = {-0.53125, -0.4375},
      priority = "high",
      animation_speed = 0.25,
      filename = "__base__/graphics/entity/smoke/smoke.png",
      flags = { "smoke" }
    },

    created_effect =
    {
      {
        type = "cluster",
        cluster_count = 8,
        distance = 10 * 1.1,
        distance_deviation = 4,
        action_delivery =
        {
          type = "instant",
          target_effects =
          {
            {
              type = "create-smoke",
              show_in_tooltip = false,
              entity_name = "spidertron-repair-visual",
              initial_height = 0
            }
          }
        }
      }
    },
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          type = "nested-result",
          action =
          {
            type = "area",
            radius = 11,
            entity_flags = {"player-creation"},
            ignore_collision_condition = true,
            action_delivery =
            {
              type = "instant",
              target_effects =
              {
                type = "damage",
                damage = { amount = -5, type = "poison"}
              }
            }
          }
        }
      }
    },
    action_cooldown = 20,
  },
  {
    type = "smoke-with-trigger",
    name = "spidertron-repair-visual",
    flags = {"not-on-map"},
    show_when_smoke_off = true,
    particle_count = 24,
    particle_spread = { 3.6 * 1.05, 3.6 * 0.6 * 1.05 },
    particle_distance_scale_factor = 0.5,
    particle_scale_factor = { 1, 0.707 },
    particle_duration_variation = 60 * 3,
    wave_speed = { 0.5 / 80, 0.5 / 60 },
    wave_distance = { 1, 0.5 },
    spread_duration_variation = 300 - 20,

    render_layer = "object",

    affected_by_wind = false,
    cyclic = true,
    duration = 60 * 2,
    fade_away_duration = 60,
    spread_duration = 20 ,
    color = {r = 0.2, g = 0.2, b = 1, a = 0.01},

    animation =
    {
      width = 152,
      height = 120,
      line_length = 5,
      frame_count = 60,
      shift = {-0.53125, -0.4375},
      priority = "high",
      animation_speed = 0.25,
      filename = "__base__/graphics/entity/smoke/smoke.png",
      flags = { "smoke" }
    },
  },
}