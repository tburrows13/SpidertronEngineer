function get_banned_items(gun_prototypes, armor_prototypes, recipe_prototypes)
    if settings.startup["spidertron-engineer-enable-compatibility-mode"].value then
        return {}
    end

    -- Iterate through all items; find all armor and guns
    local banned_items = {}
    for name, prototype in pairs(gun_prototypes) do
        table.insert(banned_items, prototype.name)
    end
    for name, prototype in pairs(armor_prototypes) do
        table.insert(banned_items, prototype.name)
    end
    log("Found banned items " .. serpent.block(banned_items))

    -- Remove from banned list items that are used in recipes for unbanned items
    for name, prototype in pairs(recipe_prototypes) do
        local ingredients = prototype["ingredients"]
        if not ingredients then ingredients = prototype["normal"]["ingredients"] end
        if not ingredients then ingredients = {} end
        for _, ingredient in pairs(ingredients) do
            local ingredient_name
            if ingredient.name then ingredient_name = ingredient.name
            elseif ingredient[1] then ingredient_name = ingredient[1]
            end
            if ingredient_name then
                if (not contains(banned_items, name)) and contains(banned_items, ingredient_name, true) then
                    log("Banned item " .. ingredient_name .. " used as ingredient for " .. name)
                end
            else
                log("No name found for ingredient " .. serpent.block(ingredient))
            end
        end
    end
    log("Final banned items " .. serpent.block(banned_items))

    return banned_items
end
