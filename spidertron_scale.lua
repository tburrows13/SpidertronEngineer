local mul = require('math3d').vector2.mul -- __core__/lualib/math3d.lua

--[[
    Author: Qon
    Contact: https://forums.factorio.com/memberlist.php?mode=viewprofile&u=16047
    `spidertron` is the spidertron prototype you want to scale. Example data.raw['spider-vehicle'].spidertron
    `scale` is the numeric scaling value to multiply all relevant values by.
    `spider_legs` (optional) are the spider-legs prototypes you want to scale. Example
            local spider_legs = {}
            for _, leg in ipairs(data.raw['spider-vehicle'].spidertron.spider_engine.legs) do table.insert(spider_legs, data.raw['spider-leg'][leg.leg]) end
        gives you the vanilla spidertron legs prototypes in spider_legs
        If you are updating a complete existing spidertron prototype and spidertron legs already in data.raw then this can be left as nil
        because the above lookups are done for you then.
    `corpse` (optional) like spider_legs. Optional when the corpse is in data.raw.corpse
    `leg_graphics_scale` (optional) is used as an alternative scale for the graphics of the legs. Doesn't affect actual leg length.
--]]

local function mult_area(v, s) return {mul(v[1], s), mul(v[2], s)} end
local function rescale_graphics(o, scale)
    o.scale = (o.scale or 1) * scale
    o.shift = mul(o.shift or {0, 0}, scale)
end
local function recursive_modify_graphics(o, scaler)
    if type(o) ~= 'table' then return end
    scaler(o)
    for k, v in pairs(o) do
        recursive_modify_graphics(v, scaler)
    end
end

function spidertron_scale(args)
    local spidertron = assert(args.spidertron)
    local scale = assert(args.scale)

    local spider_legs = args.spider_legs
    local corpse = args.corpse or data.raw.corpse[spidertron.corpse]

    local leg_graphics_scale = args.leg_graphics_scale
    if leg_graphics_scale == nil then leg_graphics_scale = scale end

    spidertron.collision_box = mult_area(spidertron.collision_box, scale)
    spidertron.selection_box = mult_area(spidertron.selection_box, scale)
    spidertron.height = spidertron.height * scale

    recursive_modify_graphics(spidertron.graphics_set, function(o) if o.filename or o.filenames then rescale_graphics(o, scale) end end)
    recursive_modify_graphics(corpse.animation, function(o) if o.filename or o.filenames then rescale_graphics(o, scale) end end)
    corpse.selection_box = mult_area(corpse.selection_box, scale)

    local add_legs = false
    if spider_legs == nil then
        spider_legs = {}
        add_legs = true
    end
    for _, leg in ipairs(spidertron.spider_engine.legs) do
        if add_legs then table.insert(spider_legs, data.raw['spider-leg'][leg.leg]) end
        -- leg is a structure in the spidertron prototype which tells which leg prototype to attach and how, it is not the spider-leg prototype
        leg.ground_position = mul(leg.ground_position, scale)
        leg.mount_position  = mul(leg.mount_position,  scale)
    end
    for _, spider_leg in ipairs(spider_legs) do -- the actual spider-leg prototypes
        -- longer legs means they will fold (go up then down) instead of being stretched out to reach the ground positions and the spidertron connection points
        -- This is used to dynamically set the position of the knee. Longer legs will also allow you to cross larger bodies of water.
        -- The stretchy spiral part of graphics will be scaled length-wise dynamically according to this value and mount and ground positions.
        spider_leg.part_length = spider_leg.part_length * scale

        -- This part actually scales the graphics for all parts and the attachment points.
        recursive_modify_graphics(spider_leg.graphics_set, function(o)
            if o.filename or o.filenames then
                rescale_graphics(o, leg_graphics_scale)
            else
                for k, v in pairs(o) do
                    if type(v) == 'number' and (string.match(k, 'length') or (string.match(k, 'offset') and not string.match(k, 'turn'))) then
                        o[k] = o[k] * leg_graphics_scale
                    end
                end
            end
        end)
    end

end

return spidertron_scale