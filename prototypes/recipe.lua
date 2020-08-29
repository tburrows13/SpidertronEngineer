local spidertron_in_rocket = settings.startup["spidertron-engineer-enable-spidertron-space-science"].value

if spidertron_in_rocket then
  -- Remove satellite and add spidertron launch product
  data.raw["item-with-entity-data"]["spidertron"]["rocket_launch_product"] = {"space-science-pack", 1000}
  data.raw.recipe["satellite"]["hidden"] = true;
  add_prerequisites("space-science-pack", {"spidertron"})
end


if settings.startup["spidertron-engineer-space-science-to-fish"].value then
  local fish = {
      type = "recipe",
      name = "spidertron-engineer-raw-fish",
      subgroup = "intermediate-product",
      category = "advanced-crafting",
      order = "y",
      ingredients = {{"space-science-pack", 10}},
      icon = "__base__/graphics/icons/fish.png",
      icon_size = 64, icon_mipmaps = 4,

      results = {{name = "raw-fish", amount = 1, probability = 0.05}},
      enabled = false,
      show_amount_in_title = false,
      energy_required = 30,
      main_product = ""
    }

  data:extend({fish})

  table.insert(data.raw.technology["space-science-pack"].effects, {
    type = "unlock-recipe",
    recipe = "spidertron-engineer-raw-fish"
  })
end

if settings.startup["spidertron-engineer-rocket-returns-fish"].value then
  data.raw["rocket-silo"]["rocket-silo"]["rocket_result_inventory_size"] = 2;
  if spidertron_in_rocket then
    -- Adjust spidertron setting
    data.raw["item-with-entity-data"]["spidertron"]["rocket_launch_product"] = nil
    data.raw["item-with-entity-data"]["spidertron"]["rocket_launch_products"] = {{"space-science-pack", 1000}, {name = "raw-fish", amount = 5, probability = 0.1}, {name = "raw-fish", amount = 10, probability = 0.05}}
  else
    data.raw["item-with-entity-data"]["satellite"]["rocket_launch_product"] = nil
    data.raw["item-with-entity-data"]["satellite"]["rocket_launch_products"] = {{"space-science-pack", 1000}, {name = "raw-fish", amount = 1, probability = 0.5}}
  end
end