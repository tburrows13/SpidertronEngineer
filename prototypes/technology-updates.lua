-- If compatibility mode is on then make minimal changes to items/recipes
local compatibility_mode = settings.startup["spidertron-engineer-enable-compatibility-mode"].value

local banned_items = get_banned_items(data.raw.gun, data.raw.armor, data.raw.recipe)

if not compatibility_mode then
    for name, prototype in pairs(data.raw.recipe) do
        if contains(banned_items, name) then
            log("Hiding recipe " .. name)
            prototype.hidden = true
        end
    end
end


-- Change all technologies that require heavy-armor and modular-armor to require military and military-2 and remove all banned item unlocks
log("Data updates")
for tech_name, _ in pairs(data.raw.technology) do
    data.raw.technology[tech_name].prerequisites = data.raw.technology[tech_name].prerequisites or {}
    if contains(data.raw.technology[tech_name].prerequisites, "heavy-armor") then
        add_prerequisites(tech_name, {"military"})
        remove_prerequisites(tech_name, {"heavy-armor"})
        log("Changed prerequisite for " .. tech_name .. " from heavy-armor to military")
    end
    if contains(data.raw.technology[tech_name].prerequisites, "modular-armor") then
        add_prerequisites(tech_name, {"military-2"})
        remove_prerequisites(tech_name, {"modular-armor"})
        log("Changed prerequisite for " .. tech_name .. " from modular-armor to military-2")
    end
    if not compatibility_mode then
        remove_recipe_effects(tech_name, banned_items)
    end
end

if not compatibility_mode then
    data.raw.technology["heavy-armor"]["hidden"] = true
    data.raw.technology["modular-armor"]["hidden"] = true
end