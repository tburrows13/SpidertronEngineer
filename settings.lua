data:extend({
    {
        type = "string-setting",
        name = "spidertron-engineer-allowed-out-of-spidertron",
        setting_type = "runtime-global",
        default_value = "never",
        allowed_values = {"never", "limited-time", "unlimited-time"}
    }
})

data:extend({
    {
        type = "bool-setting",
        name = "spidertron-engineer-spawn-with-remote",
        setting_type = "runtime-global",
        default_value = "false",
    }
})

data:extend({
    {
        type = "bool-setting",
        name = "spidertron-engineer-enable-spidertron-space-science",
        setting_type = "startup",
        default_value = "true",
        order = "a"
    },
    {
        type = "bool-setting",
        name = "spidertron-engineer-space-science-to-fish",
        setting_type = "startup",
        default_value = "true",
        order = "b"
    },
    {
        type = "bool-setting",
        name = "spidertron-engineer-rocket-returns-fish",
        setting_type = "startup",
        default_value = "false",
        order = "c"
    }
})

