-- Change all technologies that require heavy-armor and modular-armor to require military and military-2

require("utils.technology-utils")
require("utils.table-utils")

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
end

data.raw.technology["heavy-armor"]["hidden"] = true
data.raw.technology["modular-armor"]["hidden"] = true
