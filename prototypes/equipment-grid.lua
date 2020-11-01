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
    table.insert(equipment_grid2.equipment_categories, "vehicle-equipment")
    table.insert(equipment_grid3.equipment_categories, "vehicle-equipment")
    table.insert(equipment_grid4.equipment_categories, "vehicle-equipment")
    table.insert(equipment_grid5.equipment_categories, "vehicle-equipment")
end
if mods["vtk-armor-plating"] then
    table.insert(equipment_grid2.equipment_categories, "vtk-armor-plating")
    table.insert(equipment_grid3.equipment_categories, "vtk-armor-plating")
    table.insert(equipment_grid4.equipment_categories, "vtk-armor-plating")
    table.insert(equipment_grid5.equipment_categories, "vtk-armor-plating")
end
if mods["Krastorio2"] then
    table.insert(equipment_grid2.equipment_categories, "universal-equipment")
    table.insert(equipment_grid2.equipment_categories, "vehicle-equipment")
    table.insert(equipment_grid2.equipment_categories, "vehicle-motor")

    table.insert(equipment_grid3.equipment_categories, "universal-equipment")
    table.insert(equipment_grid3.equipment_categories, "vehicle-equipment")
    table.insert(equipment_grid3.equipment_categories, "vehicle-motor")

    table.insert(equipment_grid4.equipment_categories, "universal-equipment")
    table.insert(equipment_grid4.equipment_categories, "vehicle-equipment")
    table.insert(equipment_grid4.equipment_categories, "vehicle-motor")

    table.insert(equipment_grid5.equipment_categories, "universal-equipment")
    table.insert(equipment_grid5.equipment_categories, "vehicle-equipment")
    table.insert(equipment_grid5.equipment_categories, "vehicle-motor")
end
data:extend{equipment_grid2, equipment_grid3, equipment_grid4, equipment_grid5}