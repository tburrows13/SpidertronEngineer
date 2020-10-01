function contains(array, element, remove)
  for i, value in pairs(array) do
    if value == element then
      if remove then table.remove(array, i) end
      return true
    end
  end
  return false
end

function contains_key(table, element)
  for value, _ in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function merge(first_table, second_table)
  for k,v in pairs(second_table) do first_table[k] = v end
  return first_table
end

function remove_from_inventory(item, entity)
  local count = entity.get_item_count(item)
  if count > 0 then
    local removed = entity.remove_item({name=item, count=count})
    if removed > 0 then log("Removed " .. removed .. " instances of item " .. item) end
  end
end
