function add_prerequisites(tech_name, require_names)
    if not data.raw.technology[tech_name] then return end
    if type(require_names) == "string" then require_names = {require_names} end
    for _, require_name in pairs(require_names) do
      if data.raw.technology[require_name] then
        data.raw.technology[tech_name].prerequisites = data.raw.technology[tech_name].prerequisites or {}
        local already = false
        for _, prerequisite in pairs(data.raw.technology[tech_name].prerequisites) do
          if prerequisite == require_name then
            already = true
            break
          end
        end
        if not already then
          table.insert(data.raw.technology[tech_name].prerequisites, require_name)
        end
      end
    end
  end
  
  
  function remove_prerequisites (prototype_name, prerequisites)
    local prototype = data.raw.technology[prototype_name]
    if not prototype then return end
    for _, new_prerequisite in pairs(prerequisites) do
      for i = #prototype.prerequisites, 1, -1 do
        if prototype.prerequisites[i] == new_prerequisite then
          table.remove(prototype.prerequisites, i)
        end
      end
    end
  end