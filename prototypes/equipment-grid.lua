-- MK 1 & 2 (indices 0 & 1) do not have equipment grids

local equipment_grid2 = table.deepcopy(data.raw["equipment-grid"]["spidertron-equipment-grid"])
equipment_grid2.name = "spidertron-engineer-equipment-grid-2"
equipment_grid2.width = 5
equipment_grid2.height = 5

local equipment_grid3 = table.deepcopy(data.raw["equipment-grid"]["spidertron-equipment-grid"])
equipment_grid3.name = "spidertron-engineer-equipment-grid-3"
equipment_grid3.width = 7
equipment_grid3.height = 7

local equipment_grid4 = table.deepcopy(data.raw["equipment-grid"]["spidertron-equipment-grid"])
equipment_grid4.name = "spidertron-engineer-equipment-grid-4"
equipment_grid4.width = 10
equipment_grid4.height = 10

local equipment_grid5 = table.deepcopy(data.raw["equipment-grid"]["spidertron-equipment-grid"])
equipment_grid5.name = "spidertron-engineer-equipment-grid-5"
equipment_grid5.width = 12
equipment_grid5.height = 12

if mods["bobvehicleequipment"] then
    equipment_grid2.equipment_categories = {"armor", "spidertron", "vehicle", "armoured-vehicle"}
    equipment_grid3.equipment_categories = {"armor", "spidertron", "vehicle", "armoured-vehicle"}
    equipment_grid4.equipment_categories = {"armor", "spidertron", "vehicle", "armoured-vehicle"}
    equipment_grid5.equipment_categories = {"armor", "spidertron", "vehicle", "armoured-vehicle"}
end

if mods["Krastorio2"] then
    local k2_grid_categories = {
        "universal-equipment", 
        "vehicle-equipment", 
        "vehicle-motor", 
        "robot-interaction-equipment"
    }

    for _, v in ipairs(k2_grid_categories) do
        table.insert(equipment_grid2.equipment_categories, v)
        table.insert(equipment_grid3.equipment_categories, v)
        table.insert(equipment_grid4.equipment_categories, v)
        table.insert(equipment_grid5.equipment_categories, v)
    end
    
end
data:extend{equipment_grid2, equipment_grid3, equipment_grid4, equipment_grid5}