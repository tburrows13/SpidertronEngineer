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
        setting_type = "startup",
        default_value = "false",
    }
})
