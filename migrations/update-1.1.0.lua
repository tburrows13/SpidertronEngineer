-- Move global research level into a table per force
local old_research_level = global.spidertron_research_level
global.spidertron_research_level = {}
global.spidertron_researches = {"military", "military-2", "power-armor", "power-armor-mk2", "spidertron"}


-- Copied from on_init
-- Set each force's research level correctly
for _, force in pairs(game.forces) do
    global.spidertron_research_level[force.name] = 0
    for _, research in pairs(global.spidertron_researches) do
        if force.technologies[research].researched then
            global.spidertron_research_level[force.name] = global.spidertron_research_level[force.name] + 1
        end
    end
end

-- Set each player's spidertron to the correct level for their force
for _, player in pairs(game.players) do
    local spidertron = global.spidertrons[player]
    if spidertron then
        local target_version = global.spidertron_research_level[player.force.name]
        local current_version = string.sub(spidertron.name, -1)
        if target_version ~= current_version then
            create_spidertron(player, spidertron, target_version)
        end
    end
end