local S = technic.getter

local c_vacuum = minetest.get_content_id("vacuum:vacuum")
local c_atmos_thin = minetest.get_content_id("vacuum:atmos_thin")
local c_atmos_thick = minetest.get_content_id("vacuum:atmos_thick")
local c_atmos_asteroid = minetest.get_content_id("asteroid:atmos")
local c_air = minetest.get_content_id("air")

local atmospheres = {}
local atmospheres_ttl_ms = 120 * 1000;

local function get_atmos_vent(vent_pos)
    local pos_str = vent_pos.x .. "," .. vent_pos.y .. "," .. vent_pos.z
    return atmospheres[pos_str]
end

local function has_atmos_vent(vent_pos)
    local pos_str = vent_pos.x .. "," .. vent_pos.y .. "," .. vent_pos.z
    return atmospheres[pos_str] ~= nil
end

local function rem_atmos_vent(vent_pos)
    local pos_str = vent_pos.x .. "," .. vent_pos.y .. "," .. vent_pos.z
    atmospheres[pos_str] = nil
end

local function check_atmos_vent_stale(vent_pos)
    if not has_atmos_vent(vent_pos) then
        -- not tracked, so return as stale
        return true
    end
    local pos_str = vent_pos.x .. "," .. vent_pos.y .. "," .. vent_pos.z
    local atmos = atmospheres[pos_str]
    local t_us = core.get_us_time();
    local elapsed_time_in_ms = (t_us - atmos.time_checked) / 1000.0;
    if elapsed_time_in_ms > atmospheres_ttl_ms / 4 then
        return true
    end
    return false
end

local function check_atmos_vent_expired(vent_pos)
    if not has_atmos_vent(vent_pos) then
        -- not tracked, so return as expired
        return true
    end
    local pos_str = vent_pos.x .. "," .. vent_pos.y .. "," .. vent_pos.z
    local atmos = atmospheres[pos_str]
    local t_us = core.get_us_time();
    local elapsed_time_in_ms = (t_us - atmos.time_created) / 1000.0;
    if elapsed_time_in_ms > atmospheres_ttl_ms then
        return true
    end
    return false
end

local function add_atmos_vent(vent_pos, atmos_nodes, cost)
    if has_atmos_vent(vent_pos) then
        return false
    end
    local pos_str = vent_pos.x .. "," .. vent_pos.y .. "," .. vent_pos.z
    local t_us = core.get_us_time();
    local atmos = {
        time_created = t_us,
        time_checked = t_us,
        nodes = atmos_nodes,
        cost = cost
    }
    atmospheres[pos_str] = atmos
    return true
end

local function update_atmos_vent(vent_pos, atmos_nodes, cost)
    local time_created;
    local t_us = core.get_us_time();
    if has_atmos_vent(vent_pos) then
        time_created = get_atmos_vent(vent_pos).time_created
    else
        time_created = t_us
    end
    local pos_str = vent_pos.x .. "," .. vent_pos.y .. "," .. vent_pos.z
    local atmos = {
        time_created = time_created,
        time_checked = t_us,
        nodes = atmos_nodes,
        cost = cost
    }
    atmospheres[pos_str] = atmos
    return true
end

local function expand_atmos_vent(vent_pos, atmos_nodes)
    if add_atmos_vent(vent_pos, atmos_nodes) then
        return false
    end
    local pos_str = vent_pos.x .. "," .. vent_pos.y .. "," .. vent_pos.z
    local t_us = core.get_us_time();
    local atmos = atmospheres[pos_str]
    -- check if has node already
    local function has_node(n)
        if atmos.nodes[n] then
            return true
        end
        return false
    end
    -- check and add node if not tracked in mapping
    for str_pos, node in pairs(atmos_nodes) do
        if not has_node(str_pos) then
            atmos.nodes[str_pos] = node
        end
    end
    -- update time
    atmos.time_checked = t_us
    -- update mapping entry
    atmospheres[pos_str] = atmos
    return true
end

local function shrink_atmos_vent(vent_pos, distance)
    if not has_atmos_vent(vent_pos) then
        return false
    end
    local pos_str = vent_pos.x .. "," .. vent_pos.y .. "," .. vent_pos.z
    local t_us = core.get_us_time();
    local atmos = atmospheres[pos_str]
    -- get distance from orgin to atmos node
    local function dist_node(n)
        return vector.distance(vent_pos, n)
    end
    local nodes = {}
    -- check distance and remove nodes over limit
    for str_pos, node in pairs(atmos.nodes) do
        if dist_node(node) <= distance then
            nodes[str_pos] = node
        end
    end
    -- update time
    atmos.time_checked = t_us
    -- update nodes
    atmos.nodes = nodes
    -- update mapping entry
    atmospheres[pos_str] = atmos
    return true
end

------------------------------------------------

-- check if enabled
ctg_airs.machine_enabled = function(meta)
    return meta:get_int("enabled") == 1
end

function ctg_airs.get_color_range_text(val, val_max)
    local col = '#FFFFFF'
    if not val or not val_max then
        return col
    end
    local qua = val_max / 8
    if val <= qua then
        col = "#FF0000"
    elseif val <= (qua * 2) then
        col = "#FF3D00"
    elseif val <= (qua * 3) then
        col = "#FF7A00"
    elseif val <= (qua * 4) then
        col = "#FFB500"
    elseif val <= (qua * 5) then
        col = "#FFFF00"
    elseif val <= (qua * 6) then
        col = "#B4FF00"
    elseif val <= (qua * 7) then
        col = "#00FF00"
    elseif val > (qua * 7) then
        col = "#00FF50"
    end
    return col
end

local check_node_tube = function(pos)
    local ducts = {"ctg_airs:air_duct_S", "ctg_airs:air_duct_S2", "ctg_airs:air_duct_A", "ctg_airs:air_duct_A2"}

    local node = minetest.get_node(pos)

    if ducts[node.name] ~= nil then
        return true
    end
    return false
end

local is_duct_vent = function(pos)
    local vent = {"ctg_airs:air_duct_vent", "ctg_airs:air_duct_vent_dirty", "ctg_airs:air_duct_vent_lite",
                  "ctg_airs:air_duct_vent_lite_dirty"}

    local node = minetest.get_node(pos)

    if vent[node.name] ~= nil then
        return true
    end
    return false
end

local function is_vacuum_node(pos)
    local node = minetest.get_node(pos)
    if minetest.get_item_group(node.name, "vacuum") == 1 or minetest.get_item_group(node.name, "atmosphere") == 1 then
        return true
    end
    return false
end

local function is_thin_atmos_node(pos)
    local node = minetest.get_node(pos)
    local atmos = minetest.get_item_group(node.name, "atmosphere")
    if minetest.get_item_group(node.name, "vacuum") == 1 or atmos == 1 or atmos == 3 or atmos == 10 or atmos == 11 then
        return true
    end
    return false
end

local function is_atmos_node(pos)
    local node = minetest.get_node(pos)
    if node.name == "air" then
        return true
    end
    if minetest.get_item_group(node.name, "vacuum") == 1 or minetest.get_item_group(node.name, "atmosphere") > 0 then
        return true
    end
    if node.name == "technic:dummy_light_source" then
        return true
    end
    return false
end

local function get_node_cost(pos)
    local node = minetest.get_node(pos)
    if minetest.get_item_group(node.name, "vacuum") == 1 then
        -- vacuum
        return 0.02
    end
    local atmos = minetest.get_item_group(node.name, "atmosphere")
    if atmos == 1 or atmos == 10 or atmos == 11 then
        -- thin
        return 0.025
    end
    if atmos == 2 or node.name == "air" then
        -- thick/air
        return 1.0
    end
    if atmos == 3 then
        -- atmos
        return 0.25
    end
    if node.name == "technic:dummy_light_source" then
        return 0.5
    end
    return 0.0
end

local is_player_near = function(pos)
    local objs = core.get_objects_inside_radius(pos, 64)
    for _, obj in pairs(objs) do
        if obj:is_player() then
            return true;
        end
    end
    return false;
end

local function str_pos(pos)
    return pos.x .. ":" .. pos.y .. ":" .. pos.z
end

local function has_pos(tab, val)
    return tab[str_pos(val)] ~= nil
end

--[[local function has_pos(tab, val)
    for index, value in ipairs(tab) do
        if value.x == val.x and value.y == val.y and value.z == val.z then
            return true
        end
    end
    return false
end]] --

local function shuffle(t)
    local tbl = {}
    for i = 1, #t do
        tbl[i] = t[i]
    end
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

local function traverse_atmos_local(pos_orig, dir, pos, r, d)
    local positions = {{
        x = pos.x + 1,
        y = pos.y,
        z = pos.z
    }, {
        x = pos.x - 1,
        y = pos.y,
        z = pos.z
    }, {
        x = pos.x,
        y = pos.y + 1,
        z = pos.z
    }, {
        x = pos.x,
        y = pos.y - 1,
        z = pos.z
    }, {
        x = pos.x,
        y = pos.y,
        z = pos.z + 1
    }, {
        x = pos.x,
        y = pos.y,
        z = pos.z - 1
    }}
    if d < 2 then
        table.insert(positions, {
            x = pos.x - dir.x * 2,
            y = pos.y - dir.y * 2,
            z = pos.z - dir.z * 2
        });
    end
    local nodes = {}
    local dist = vector.distance({
        x = pos.x,
        y = pos.y,
        z = pos.z
    }, {
        x = pos_orig.x,
        y = pos_orig.y,
        z = pos_orig.z
    })
    nodes[str_pos(pos)] = pos
    if (dist > r) then
        return nodes;
    end
    for i, cur_pos in pairs(shuffle(positions)) do
        if is_atmos_node(cur_pos) then
            nodes[str_pos(cur_pos)] = cur_pos
        end
    end
    return nodes;
end

local function traverse_atmos(t, pos, dir, pos_next, r, depth, max_cost)
    if pos_next == nil then
        pos_next = pos;
    end
    local nodes = {};
    local costs = get_node_cost(pos_next);
    -- add pos to listing
    nodes[str_pos(pos_next)] = pos_next
    -- depth check
    local max_depth = math.min(r, 8) + 8
    if depth > max_depth then
        return nodes, costs
    end
    depth = depth + 1
    -- elapsed time check
    local elapsed_time_in_ms_max = 3.17;
    local t0_us = core.get_us_time();
    local elapsed_time_in_ms = (t0_us - t) / 1000.0;
    if elapsed_time_in_ms >= elapsed_time_in_ms_max then
        return nodes, costs
    end
    -- traverse nodes in local area
    local trav_nodes = traverse_atmos_local(pos, dir, pos_next, r, depth);
    for _, tpos in pairs(trav_nodes) do
        -- add to listing
        if not has_pos(nodes, tpos) then
            nodes[str_pos(tpos)] = tpos
            if math.random(0, math.max(3, depth)) <= 5 then
                -- traverse atmos for next pos in chain
                local atmoss, cost = traverse_atmos(t, pos, dir, tpos, r, depth, max_cost);
                costs = costs + cost
                for i, n in pairs(atmoss) do
                    nodes[str_pos(n)] = n
                end
            else
                costs = costs + get_node_cost(tpos);
            end
        end
        -- cost overage cehck
        if costs > max_cost then
            break
        end

    end
    -- return nodes and costs
    return nodes, costs;
end

local function traverse_atmos_cache(t_us, origin, dir, pos_next, r, depth, max_cost)

    local function handle_local_atmos_cache(vent_pos)
        if not has_atmos_vent(vent_pos) then
            -- traverse nearby atmos
            local nodes, cost = traverse_atmos(t_us, vent_pos, dir, pos_next, r, depth, max_cost);
            add_atmos_vent(vent_pos, nodes, cost)
            return nodes, cost
        else
            local is_expired = check_atmos_vent_expired(vent_pos)
            if not is_expired then
                local is_stale = check_atmos_vent_stale(vent_pos)
                if not is_stale then
                    local atmos = get_atmos_vent(vent_pos)
                    if atmos then
                        return atmos.nodes, atmos.cost
                    end
                else
                    shrink_atmos_vent(vent_pos, r * 0.67)
                    local nodes, cost = traverse_atmos(t_us, vent_pos, dir, pos_next, r * 0.88, depth + 1, max_cost);
                    expand_atmos_vent(vent_pos, nodes)
                    local atmos = get_atmos_vent(vent_pos)
                    if atmos then
                        return atmos.nodes, atmos.cost + cost
                    end
                end
                return {}, 0
            else
                -- traverse nearby atmos
                local nodes, cost = traverse_atmos(t_us, vent_pos, dir, pos_next, r + 1, depth, max_cost);
                rem_atmos_vent(vent_pos)
                update_atmos_vent(vent_pos, nodes, cost)
                return nodes, cost
            end
        end
    end

    return handle_local_atmos_cache(origin)

end

local fill_atmos_near = function(pos, dir, r)
    local origin = vector.subtract(pos, dir);
    local max_cost = r * math.random(10, 20);
    local t0_us = core.get_us_time();
    -- traverse nearby atmos
    local nodes, cost = traverse_atmos_cache(t0_us, origin, dir, nil, r, 0, max_cost);

    -- minetest.log("found " .. #nodes);
    local count = 0;
    -- iterate over nodes found
    for i, node_pos in pairs(nodes) do
        if (count > 1000) then
            break
        end
        count = count + 1;
        if is_thin_atmos_node(node_pos) then
            core.set_node(node_pos, {
                name = "air"
            })
            if math.random(0, 7) <= 1 then
                ctg_airs.spawn_particle(node_pos, math.random(-0.001, 0.001), math.random(-0.001, 0.001),
                                        math.random(-0.001, 0.001), 0, 0, 0, math.random(1.8, 3), 10, 1)
            end
        end
    end
    return count, cost
end

function ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, time, amount)
    if (not is_player_near(pos)) then
        return;
    end
    local animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = (time or 6) + 1
    }
    local texture = {
        name = "ctg_air_vent_vapor_anim.png",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0.2},
        scale_tween = {{
            x = 0.5,
            y = 0.5
        }, {
            x = 2.1,
            y = 2.0
        }}
    }

    local prt = {
        texture = texture,
        vel = 2,
        time = (time or 6),
        size = 3 + (lvl or 1),
        glow = math.random(1, 3),
        cols = false
    }

    local v = vector.new()
    v.x = 0.0001
    v.y = 0.001
    v.z = 0.0001
    if math.random(0, 10) > 1 then
        local rx = dir_x * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        local ry = dir_y * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        local rz = dir_z * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        minetest.add_particlespawner({
            amount = amount,
            pos = pos,
            minpos = {
                x = 0,
                y = 0,
                z = 0
            },
            maxpos = {
                x = dir_x,
                y = dir_y,
                z = dir_z
            },
            minvel = {
                x = rx * 0.8,
                y = ry * 0.8,
                z = rz * 0.8
            },
            maxvel = {
                x = rx,
                y = ry,
                z = rz
            },
            minacc = {
                x = acl_x * 0.8,
                y = acl_y * 0.8,
                z = acl_z * 0.8
            },
            maxacc = {
                x = acl_x,
                y = acl_y + math.random(-0.008, 0),
                z = acl_z
            },
            time = prt.time + 2,
            minexptime = prt.time - math.random(0, 2),
            maxexptime = prt.time + math.random(0, 1),
            minsize = ((math.random(0.77, 0.93)) * 2 + 1.6) * prt.size,
            maxsize = ((math.random(0.77, 0.93)) * 2 + 1.6) * prt.size,
            collisiondetection = prt.cols,
            vertical = false,
            texture = texture,
            animation = animation,
            glow = prt.glow
        })
    end
end

function ctg_airs.spawn_particle2(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, time, amount)
    if (not is_player_near(pos)) then
        return;
    end
    local animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = (time or 6) + 1
    }
    local texture = {
        name = "ctg_air_vent_vapor_anim.png",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0.2},
        scale_tween = {{
            x = 0.5,
            y = 0.5
        }, {
            x = 2.1,
            y = 2.0
        }}
    }

    local prt = {
        texture = texture,
        vel = 2,
        time = (time or 6),
        size = 3 + (lvl or 1),
        glow = math.random(2, 4),
        cols = true
    }

    local v = vector.new()
    v.x = 0.0001
    v.y = 0.001
    v.z = 0.0001
    if math.random(0, 10) > 1 then
        local rx = dir_x * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        local ry = dir_y * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        local rz = dir_z * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        minetest.add_particlespawner({
            amount = amount,
            pos = pos,
            minpos = {
                x = math.random(-2, -0.25),
                y = math.random(-0.75, -0.01),
                z = math.random(-2, -0.25)
            },
            maxpos = {
                x = math.random(0.25, 2),
                y = math.random(0.0, 0.75),
                z = math.random(0.25, 2)
            },
            minvel = {
                x = rx * 0.8,
                y = ry * 0.8,
                z = rz * 0.8
            },
            maxvel = {
                x = rx,
                y = ry,
                z = rz
            },
            minacc = {
                x = acl_x,
                y = acl_y,
                z = acl_z
            },
            maxacc = {
                x = acl_x,
                y = acl_y + math.random(-0.01, 0),
                z = acl_z
            },
            time = prt.time + 2,
            minexptime = prt.time - math.random(0, 2),
            maxexptime = prt.time + math.random(0, 1),
            minsize = ((math.random(0.77, 0.93)) * 2 + 1.6) * prt.size,
            maxsize = ((math.random(0.77, 0.93)) * 2 + 1.6) * prt.size,
            collisiondetection = prt.cols,
            vertical = false,
            texture = texture,
            animation = animation,
            glow = prt.glow
        })
    end
end

function ctg_airs.process_atmos(pos, max)
    local count = 0
    for i = 1, 2 do
        local range = {
            x = i,
            y = i,
            z = i
        }
        local pos1 = vector.subtract(pos, range)
        local pos2 = vector.add(pos, range)

        local manip = minetest.get_voxel_manip()
        local e1, e2 = manip:read_from_map(pos1, pos2)
        local area = VoxelArea:new({
            MinEdge = e1,
            MaxEdge = e2
        })
        local data = manip:get_data()

        for y = pos1.y, pos2.y do
            for z = pos1.z, pos2.z do
                for x = pos1.x, pos2.x do

                    if (count >= max) then
                        break
                    end

                    if math.random(0, 1) == 0 then
                        local index = area:index(x, y, z)
                        if data[index] == c_atmos_thick then
                            data[index] = c_atmos_thin
                            count = count + 1
                        elseif data[index] == c_air then
                            data[index] = c_atmos_thin
                            count = count + 1
                        elseif data[index] == c_atmos_asteroid then
                            data[index] = c_atmos_thin
                            count = count + 1
                        end
                    end

                end
            end
        end

        manip:set_data(data)
        manip:write_to_map()

        if (count > max) then
            break
        end
    end
    return count
end

function ctg_airs.process_leak(pos, power)
    if not pos then
        return 0, power
    end

    if power <= -10 then
        return 0, power
    end

    if math.random(0, 100) <= 1 then
        return 0, power
    end

    local node = minetest.get_node(pos)
    local param2 = node.param2
    local dir_x = 0.0001
    local dir_z = 0.0001
    local dir_y = 0.0001
    if param2 == 1 then -- west
        dir_x = 1
    elseif param2 == 2 then -- north?
        dir_z = -1
    elseif param2 == 3 then -- east
        dir_x = -1
    elseif param2 == 4 then -- south
        dir_z = 1
        -- elseif param2 == 1 then -- up
        -- dir_y = -0.25
        -- elseif param2 == 5 then -- down
        -- dir_y = 0.25
    else
        dir_x = math.random(-0.5, 0.5)
        dir_y = math.random(-0.75, 0.75)
        dir_z = math.random(-0.5, 0.5)
    end

    local acl_x = 0.28 * (dir_x)
    local acl_y = 0.05 * (dir_y)
    local acl_z = 0.28 * (dir_z)

    ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, 1.5, 7, 2)
    for i = 0, 5 do
        minetest.after(i, function()
            ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, 1, 6, 1)
        end)
    end

    local range = {
        x = 1,
        y = 1,
        z = 1
    }
    local pos1 = vector.subtract(pos, range)
    local pos2 = vector.add(pos, range)

    local manip = minetest.get_voxel_manip()
    local e1, e2 = manip:read_from_map(pos1, pos2)
    local area = VoxelArea:new({
        MinEdge = e1,
        MaxEdge = e2
    })
    local data = manip:get_data()

    local count = 0
    for z = pos1.z, pos2.z do
        for y = pos1.y, pos2.y do
            for x = pos1.x, pos2.x do

                local index = area:index(x, y, z)
                if data[index] == c_atmos_thin then
                    data[index] = c_air
                    count = count + 1
                elseif data[index] == c_vacuum then
                    data[index] = c_atmos_thin
                    count = count + 1
                elseif data[index] == c_atmos_thick then
                    data[index] = c_air
                    count = count + 1
                end

            end
        end
    end

    manip:set_data(data)
    manip:write_to_map()

    power = power - (25 + count)

    if ((count > 0 or math.random(0, 5) == 0)) then
        minetest.sound_play("air_vent_short", {
            pos = pos,
            gain = 0.071,
            pitch = math.random(0.5, 1),
            max_hear_distance = 18
        })
    end

    -- minetest.log("leaking atmos..")
    return count, power
end

local function process_vent2(pos, power, cost, hasPur)
    if power <= 0 then
        return 0, power
    end
    local meta = minetest.get_meta(pos)
    if power - cost <= 0 then
        meta:set_int("active", 0)
        return 0, power
    end

    local t0_us = minetest.get_us_time();
    local t2_us = tonumber(meta:get_string("time_run"))
    local t_lag = tonumber(meta:get_string("time_lag"))
    local elapsed_time_in_seconds = (t0_us - t2_us) / 1000000.0;
    if elapsed_time_in_seconds <= 1 then
        return 0, power + 1
    end
    if t_lag and t_lag > 44 and elapsed_time_in_seconds < 37 then
        return 0, power - 7
    end
    if t_lag and t_lag > 35 and elapsed_time_in_seconds < 34 then
        return 0, power - 6
    end
    if t_lag and t_lag > 26 and elapsed_time_in_seconds < 30 then
        return 0, power - 5
    end
    if t_lag and t_lag > 20 and elapsed_time_in_seconds < 25 then
        return 0, power - 4
    end
    if t_lag and t_lag > 12 and elapsed_time_in_seconds < 20 then
        return 0, power - 3
    end
    if t_lag and t_lag > 5 and elapsed_time_in_seconds < 15 then
        return 0, power - 2
    end
    if t_lag and t_lag > 2.12 and elapsed_time_in_seconds < 10 then
        return 0, power - 1
    end
    if t_lag and t_lag > 0.51 and elapsed_time_in_seconds < 5 then
        return 0, power - 0
    end

    local node = minetest.get_node(pos)
    local param2 = node.param2
    local dir_x = 0.0001
    local dir_z = 0.0001
    local dir_y = 0.0001
    local aclr = 0;

    local dir = math.floor(param2 / 4)
    local rot = param2 % 4

    if dir == 0 or dir == 5 then
        if rot == 0 then
            dir_z = 1
        elseif rot == 1 then
            dir_x = 1
        elseif rot == 2 then
            dir_z = -1
        elseif rot == 3 then
            dir_x = -1
        end
        aclr = math.random(-1, 1)
    elseif dir == 1 or dir == 3 then
        if rot == 0 then
            dir_y = -1
        elseif rot == 1 then
            dir_y = -1
        elseif rot == 2 then
            dir_y = 1
        elseif rot == 3 then
            dir_y = 1
        end
    elseif dir == 2 or dir == 4 then
        if rot == 0 then
            dir_y = 1
        elseif rot == 1 then
            dir_y = 1
        elseif rot == 2 then
            dir_y = 1
        elseif rot == 3 then
            dir_y = 1
        end
    end

    local acl_x = 0.15 * (dir_x)
    local acl_y = 0.10 * (dir_y + aclr)
    local acl_z = 0.15 * (dir_z)

    local lvl = 0
    if (cost > 8) then
        lvl = 2
    end

    minetest.after(0, function()
        ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, 8, cost + 1)
    end)

    if vacuum.is_pos_in_spawn(pos) then
        if ((cost > 0 and math.random(0, 20) == 0) and power > -5) then
            local r = math.random(0, 2)
            minetest.after(r, function()
                minetest.sound_play("air_vent_short", {
                    pos = pos,
                    gain = 0.007,
                    pitch = 0.6 + math.random(-0.001, 0.001),
                    max_hear_distance = 20
                })
            end)
        end
        return cost, power
    end

    if hasPur == false and string.match(node.name, "duct_vent") then
        if not string.match(node.name, "_dirty") and math.random(0, 1000000) == 0 then
            minetest.set_node(pos, {
                name = node.name .. "_dirty",
                param2 = node.param2
            })
            if string.match(node.name, "_lite") then
                minetest.get_meta(pos):set_string("infotext", S("Dirty Lite Vent"))
            else
                minetest.get_meta(pos):set_string("infotext", S("Dirty Vent"))
            end
        end
    end

    local dir = vector.new(dir_x, dir_y, dir_z)
    local dir_pos = vector.subtract(pos, dir);

    -- get dirty group
    local dirty = minetest.get_item_group(node.name, "vent_dirty") or 0
    -- recalc power
    power = math.max(0, power - (cost + dirty))

    local r = 4
    if cost > 9 then
        r = 13
    elseif cost > 6 then
        r = 9
    elseif cost > 3 then
        r = 6
    end

    if (hasPur and dirty == 0) then
        r = r + 1;
    end

    -- fill area with air
    local count, tcost, travs = fill_atmos_near(dir_pos, dir, r - (dirty * 2));
    -- recalc power
    power = power - (tcost * 0.01)

    if ((count > 0 and math.random(0, 25) == 0) and power > -5) then
        local r = math.random(0, 3)
        minetest.after(r, function()
            minetest.sound_play("air_vent_short", {
                pos = pos,
                gain = 0.008 + (count * 0.002),
                pitch = 0.6 + math.random(-0.1, 0.25),
                max_hear_distance = 18
            })
        end)
    end

    -- lag tracking
    local t1_us = minetest.get_us_time();
    local elapsed_time_in_seconds = (t1_us - t0_us) / 1000000.0;
    local elapsed_time_in_milliseconds = elapsed_time_in_seconds * 1000;
    meta:set_string("time_lag", tostring(elapsed_time_in_milliseconds));
    meta:set_string("time_run", tostring(t1_us));
    -- set active
    meta:set_int("active", 1)

    -- lag listing
    local lag_listing = meta:get_string("time_lag_list") or nil
    local lag_list = lag_listing and core.deserialize(lag_listing) or {}
    table.insert(lag_list, elapsed_time_in_milliseconds)
    if #lag_list > 10 then
        table.remove(lag_list, 1)
    end
    meta:set_string("time_lag_list", core.serialize(lag_list))

    -- rounding function
    local function fround(n, prec)
        prec = prec or 3
        local str = string.format("%." .. prec .. "f", n)
        local num = tonumber(str);
        return tostring(num)
    end

    -- lag current
    local lag = fround(elapsed_time_in_milliseconds) .. " ms"
    local n_lag = "\nLag: " .. lag
    -- lag avg
    local count = 0
    local total = 0
    for _, l in pairs(lag_list) do
        total = total + l
        count = count + 1
    end
    local avg = (total / count)
    local lag_avg = fround(avg, 1) .. " ms"
    local n_eff = "\nTick: " .. lag_avg
    -- cost usage
    local cost_max = math.max(512, tcost)
    local n_cost = "\nFilled: " .. fround((tcost / cost_max) * 100, 0) .. " %"

    -- vent node stat info
    local stat = n_lag .. n_eff .. n_cost
    if node.name == "ctg_airs:air_duct_vent" then
        meta:set_string("infotext", S("Vent - Active") .. stat)
    elseif node.name == "ctg_airs:air_duct_vent_dirty" then
        meta:set_string("infotext", S("Dirty Vent - Active") .. stat)
    elseif node.name == "ctg_airs:air_duct_vent_lite" then
        meta:set_string("infotext", S("Lite Vent - Active") .. stat)
    elseif node.name == "ctg_airs:air_duct_vent_lite_dirty" then
        meta:set_string("infotext", S("Dirty Lite Vent - Active") .. stat)
    end

    -- minetest.log("making atmos..")
    return count, power
end

function ctg_airs.process_vent(pos, power, hasPur)
    if not pos then
        return 0, power
    end
    if math.random(0, 15) <= 1 then
        return 0, power
    end
    local node = minetest.get_node(pos)
    local cost = minetest.get_item_group(node.name, "vent") or 10
    return process_vent2(pos, power, cost, hasPur)
end

function ctg_airs.process_junc(junc_pos, dir, power, hasPur)
    local networks = {}
    return ctg_airs.process_junc2(junc_pos, dir, networks, power, hasPur)
end

function ctg_airs.process_junc2(junc_pos, dir, networks, power, hasPur)
    if power <= 0 then
        return 0, power
    end
    local count = 0;
    for i = 0, 6 do
        local cnt = 0;
        local brek = false;
        local tube = ctg_airs.Tube:get_next_tube(junc_pos, i)
        local dest_pos = ctg_airs.Tube:get_connected_node_pos(junc_pos, i)
        -- ctg_airs.Tube:infotext(tube, dest_pos)
        -- local valid, dest_pos, dir = ctg_airs.get_duct_output(junc_pos, i)
        if tube ~= nil or dest_pos ~= nil then
            if dest_pos ~= nil and dest_pos ~= junc_pos and networks[dest_pos] == nil then
                local dest_node = minetest.get_node(dest_pos)
                if dest_node.name == "ctg_airs:air_duct_vent" or dest_node.name == "ctg_airs:air_duct_vent_dirty" or
                    dest_node.name == "ctg_airs:air_duct_vent_lite" or dest_node.name ==
                    "ctg_airs:air_duct_vent_lite_dirty" then
                    networks[dest_pos] = i
                    cnt, power = ctg_airs.process_vent(dest_pos, power, hasPur)
                    -- minetest.log("found connected vent")
                elseif dest_node.name == "ctg_airs:air_duct_junc" then
                    if tube ~= nil then
                        networks[dest_pos] = i
                        cnt, power = ctg_airs.process_junc2(dest_pos, i, networks, power, hasPur)
                        power = power - 3
                        -- minetest.log("found connected junc")
                    end
                    if tube == nil then
                        brek = true;
                    end
                elseif (dest_node and ctg_airs.isAirPurifier(dest_node)) then
                    networks[dest_pos] = i
                    count, power = ctg_airs.process_purifier2(dest_pos, dest_node.param2, networks, power)
                    power = power - 10
                    -- minetest.log("purifier")
                elseif tube ~= nil and (dest_node and dest_node.name == "vacuum:vacuum") then
                    networks[dest_pos] = i
                    cnt, power = ctg_airs.process_leak(dest_pos, power)
                    power = power - 10
                    -- minetest.log("vacuum")
                elseif tube ~= nil and (dest_node and dest_node.name == "vacuum:atmos_thin") then
                    networks[dest_pos] = i
                    cnt, power = ctg_airs.process_leak(dest_pos, power)
                    power = power - 7
                    -- minetest.log("thin atmos")
                elseif tube ~= nil and (dest_node and dest_node.name == "air") then
                    networks[dest_pos] = i
                    cnt, power = ctg_airs.process_leak(dest_pos, power)
                    power = power - 5
                    -- minetest.log("thick atmos")
                end
            end
            if not power or power <= 0 then
                break
            end
        end
        count = count + cnt;
        if brek then
            break
        end
    end
    return count, power
end

-- check if purifier
function ctg_airs.isAirPurifier(node)
    if (node.name == "ctg_airs:lv_air_purifier") then
        return true;
    elseif (node.name == "ctg_airs:lv_air_purifier_active") then
        return true;
    elseif (node.name == "ctg_airs:lv_air_purifier_dirty") then
        return true;
    end
    return false;
end

function ctg_airs.process_purifier(puri_pos, dir, power)
    local networks = {}
    return ctg_airs.process_purifier2(puri_pos, dir, networks, power)
end

function ctg_airs.process_purifier2(puri_pos, dir, networks, power)
    if (not puri_pos) then
        return 0, power
    end
    local count = 0;
    if (dir == nil) then
        minetest.log("process_purifier2: dir " .. 'nil');
        return 0, power
    end
    if power <= 0 then
        return 0, power
    end
    local dir1 = 0;
    local dir2 = 0;
    if (dir ~= nil) then
        -- minetest.log("dir: " .. dir);
        if dir == 0 then
            dir1 = 4 -- ok
            dir2 = 2
        elseif dir == 1 then
            dir1 = 1 -- ok
            dir2 = 3
        elseif dir == 2 then
            dir1 = 2 -- ok
            dir2 = 4
        elseif dir == 3 then
            dir1 = 3 -- ok
            dir2 = 1
        end
    end

    local meta = minetest.get_meta(puri_pos);
    local hasFilter = meta:get_int("has_filter") == 1
    meta:set_int("has_air", power);
    for i = 0, 6 do
        if (i == dir1 or i == dir2) then
            local cnt = 0;
            local brek = false;
            local tube = ctg_airs.Tube:get_next_tube(puri_pos, i)
            local dest_pos = ctg_airs.Tube:get_connected_node_pos(puri_pos, i)
            if tube ~= nil or dest_pos ~= nil then
                if dest_pos ~= nil and dest_pos ~= puri_pos and networks[dest_pos] == nil and networks[dest_pos] ~= i then
                    local dest_node = minetest.get_node(dest_pos)
                    if dest_node.name == "ctg_airs:air_duct_vent" or dest_node.name == "ctg_airs:air_duct_vent_dirty" or
                        dest_node.name == "ctg_airs:air_duct_vent_lite" or dest_node.name ==
                        "ctg_airs:air_duct_vent_lite_dirty" then
                        networks[dest_pos] = i
                        cnt, power = ctg_airs.process_vent(dest_pos, power, hasFilter)
                        power = power - 15
                        -- minetest.log("found connected vent")
                    elseif dest_node.name == "ctg_airs:air_duct_junc" then
                        if tube ~= nil then
                            networks[dest_pos] = i
                            cnt, power = ctg_airs.process_junc2(dest_pos, i, networks, power, hasFilter)
                            power = power - 3
                            -- minetest.log("found connected junc")
                        end
                        if tube == nil then
                            brek = true;
                        end
                    elseif tube ~= nil and (dest_node and dest_node.name == "vacuum:vacuum") then
                        networks[dest_pos] = i
                        cnt, power = ctg_airs.process_leak(dest_pos, power)
                        power = power - 10
                        -- minetest.log("vacuum")
                    elseif tube ~= nil and (dest_node and dest_node.name == "vacuum:atmos_thin") then
                        networks[dest_pos] = i
                        cnt, power = ctg_airs.process_leak(dest_pos, power)
                        power = power - 7
                        -- minetest.log("thin atmos")
                    elseif tube ~= nil and (dest_node and dest_node.name == "air") then
                        networks[dest_pos] = i
                        cnt, power = ctg_airs.process_leak(dest_pos, power)
                        power = power - 5
                        -- minetest.log("thick atmos")
                    end
                end
                if not power or power <= 0 then
                    break
                end
            end
            count = count + cnt;
            if brek then
                break
            end
        end
    end
    return count, power
end

function ctg_airs.get_duct_output_up(pos)
    return ctg_airs.get_duct_output(pos, 6)
end

function ctg_airs.get_duct_output(pos, dir)
    local pos1 = pos
    local pos2 = {
        x = pos.x,
        y = pos.y + 1,
        z = pos.z
    }

    local node1 = minetest.get_node(pos1)
    local node2 = minetest.get_node(pos2)
    if check_node_tube(pos1) then
        pos = pos1;
    elseif dir == 6 and check_node_tube(pos2) then
        pos = pos2;
    end

    local node = minetest.get_node(pos)
    local dir1, dir2, num_con = ctg_airs.Tube:decode_param2(pos, node.param2)

    local dest_pos = ctg_airs.Tube:get_connected_node_pos(pos, dir)

    -- minetest.log(tostring(dir1) .. " " .. tostring(dir2) .. " " .. tostring(num_con))

    -- local loc = minetest.get_meta(pos):get_string("infotext")

    if (dest_pos) then
        -- local dest_pos = minetest.string_to_pos(loc)
        local dest_node = minetest.get_node(dest_pos)
        local dest_dir1, dest_dir2, dest_num_con = ctg_airs.Tube:decode_param2(dest_pos, dest_node.param2)

        if dest_node.name == "air" then
            return 2, dest_pos, dest_dir2
        elseif dest_node.name == "vacuum:atmos_thin" then
            return 3, dest_pos, dest_dir2
        elseif dest_node.name == "vacuum:vacuum" then
            return 5, dest_pos, dest_dir2
        elseif dest_node.name == "ctg_airs:air_duct_vent" or dest_node.name == "ctg_airs:air_duct_vent_dirty" then
            return 1, dest_pos, dest_dir2
        elseif dest_node.name == "ctg_airs:air_duct_vent_lite" or dest_node.name == "ctg_airs:air_duct_vent_lite_dirty" then
            return 1, dest_pos, dest_dir2
        elseif dest_node.name == "ctg_airs:air_duct_junc" then
            return 1, dest_pos, dest_dir2
        elseif dest_node.name == "ctg_airs:lv_air_purifier" or dest_node.name == "ctg_airs:lv_air_purifier_active" or
            dest_node.name == "ctg_airs:lv_air_purifier_dirty" then
            return 4, dest_pos, dest_node.param2
        end
    end
    return 0, nil, nil
end

ctg_airs.find_connected = function(pos)
    local positions = {{
        x = pos.x + 1,
        y = pos.y,
        z = pos.z
    }, {
        x = pos.x - 1,
        y = pos.y,
        z = pos.z
    }, {
        x = pos.x,
        y = pos.y + 1,
        z = pos.z
    }, {
        x = pos.x,
        y = pos.y - 1,
        z = pos.z
    }, {
        x = pos.x,
        y = pos.y,
        z = pos.z + 1
    }, {
        x = pos.x,
        y = pos.y,
        z = pos.z - 1
    }}
    local nodes = {}
    for i, cur_pos in pairs(positions) do
        local n = check_node_tube(cur_pos)
        if n ~= nil then
            table.insert(nodes, cur_pos)
        end
    end
    return nodes
end

-- returns true if the position is near active vent
function ctg_airs.near_active_vent(pos, range)
    local pos1 = vector.subtract(pos, {
        x = range,
        y = range,
        z = range
    })
    local pos2 = vector.add(pos, {
        x = range,
        y = range,
        z = range
    })

    local nodes = minetest.find_nodes_in_area(pos1, pos2, {"ctg_airs:air_duct_vent"})
    for _, node in ipairs(nodes) do
        local meta = minetest.get_meta(node)
        if ctg_airs.vent_active(meta) then
            return true
        end
    end
    local nodes2 = minetest.find_nodes_in_area(pos1, pos2, {"ctg_airs:air_duct_vent_dirty"})
    for _, node in ipairs(nodes2) do
        local meta = minetest.get_meta(node)
        if ctg_airs.vent_active(meta) then
            return true
        end
    end
    local nodes2 = minetest.find_nodes_in_area(pos1, pos2, {"ctg_airs:air_duct_vent_lite"})
    for _, node in ipairs(nodes2) do
        local meta = minetest.get_meta(node)
        if ctg_airs.vent_active(meta) then
            return true
        end
    end
    local nodes2 = minetest.find_nodes_in_area(pos1, pos2, {"ctg_airs:air_duct_vent_lite_dirty"})
    for _, node in ipairs(nodes2) do
        local meta = minetest.get_meta(node)
        if ctg_airs.vent_active(meta) then
            return true
        end
    end

    return false
end
