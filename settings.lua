data:extend({
    {
        type = "string-setting",
        name = "spidertron-engineer-allowed-out-of-spidertron",
        setting_type = "runtime-global",
        default_value = "never",
        allowed_values = {"never", "limited-time", "unlimited-time"}
    },
    {
        type = "string-setting",
        name = "spidertron-engineer-allowed-into-entities",
        setting_type = "runtime-global",
        default_value = "limited",
        allowed_values = {"none", "limited", "all"}
    },
    {
        type = "bool-setting",
        name = "spidertron-engineer-spawn-with-remote",
        setting_type = "runtime-global",
        default_value = "false",
    },
})

data:extend({
    {
        type = "bool-setting",
        name = "spidertron-engineer-enable-compatibility-mode",
        setting_type = "startup",
        default_value = "false",
        order = "a"
    },
    {
        type = "bool-setting",
        name = "spidertron-engineer-enable-spidertron-space-science",
        setting_type = "startup",
        default_value = "true",
        order = "ba"
    },
    {
        type = "bool-setting",
        name = "spidertron-engineer-space-science-to-fish",
        setting_type = "startup",
        default_value = "true",
        order = "bb"
    },
    {
        type = "bool-setting",
        name = "spidertron-engineer-rocket-returns-fish",
        setting_type = "startup",
        default_value = "false",
        order = "bc"
    },
    {
        type = "bool-setting",
        name = "spidertron-engineer-enable-upgrade-size",
        setting_type = "startup",
        default_value = "true",
        order = "ca"
    },
    {
        type = "double-setting",
        name = "spidertron-engineer-constant-size-scale",
        setting_type = "startup",
        default_value = 1,
        minimum_value = 0.2,
        maximum_value = 8,
        order = "cb"
    }
})

-- Disable Spidertron Enhancement features that aren't compatible
data.raw["bool-setting"]["spidertron-enhancements-enter-entity-base-game"].hidden = true
data.raw["bool-setting"]["spidertron-enhancements-enter-entity-custom"].hidden = true
data.raw["bool-setting"]["spidertron-enhancements-show-spider-on-vehicle"].hidden = true
data.raw["bool-setting"]["spidertron-enhancements-enter-player"].hidden = true
