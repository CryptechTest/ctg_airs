local S = technic.getter

local c_vacuum = minetest.get_content_id("vacuum:vacuum")
local c_atmos_thin = minetest.get_content_id("vacuum:atmos_thin")
local c_atmos_thick = minetest.get_content_id("vacuum:atmos_thick")
local c_atmos_asteroid = minetest.get_content_id("asteroid:atmos")
local c_air = minetest.get_content_id("air")

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
    if minetest.get_item_group(node.name, "vacuum") == 1 or minetest.get_item_group(node.name, "atmosphere") == 1 or
        minetest.get_item_group(node.name, "atmosphere") == 3 then
        return true
    end
    return false
end

local function is_atmos_node(pos)
    local node = minetest.get_node(pos)
    if minetest.get_item_group(node.name, "vacuum") == 1 or minetest.get_item_group(node.name, "atmosphere") > 0 then
        return true
    end
    if node.name == "air" then
        return true
    end
    return false
end

local function get_node_cost(pos)
    local node = minetest.get_node(pos)
    if minetest.get_item_group(node.name, "vacuum") == 1 then
        -- vacuum
        return 0.2
    end
    local atmos = minetest.get_item_group(node.name, "atmosphere")
    if atmos == 1 then
        -- thin
        return 0.1
    end
    if atmos == 2 or node.name == "air" then
        -- thick/air
        return 1
    end
    if atmos == 3 then
        -- atmos
        return 0.25
    end
    return 0
end

local function has_pos(tab, val)
    for index, value in ipairs(tab) do
        if value.x == val.x and value.y == val.y and value.z == val.z then
            return true
        end
    end
    return false
end

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

local function traverse_atmos_local(pos_orig, pos, r)
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
    local dist = vector.distance({
        x = pos.x,
        y = pos.y,
        z = pos.z
    }, {
        x = pos_orig.x,
        y = pos_orig.y,
        z = pos_orig.z
    })
    if (dist > r + 1) then
        return nodes, 0;
    end
    table.insert(nodes, pos);
    local costs = 0
    for i, cur_pos in pairs(shuffle(positions)) do
        local dist = vector.distance({
            x = pos_orig.x,
            y = pos_orig.y,
            z = pos_orig.z
        }, {
            x = cur_pos.x,
            y = cur_pos.y,
            z = cur_pos.z
        })
        -- if (dist <= math.random(math.max(1, r - 1), r + 2)) then
        if is_atmos_node(cur_pos) then
            table.insert(nodes, cur_pos);
            costs = costs + get_node_cost(cur_pos)
        end
        -- end
    end
    return nodes, costs;
end

local function traverse_atmos(trv, pos, pos_next, r, depth)
    if depth > 14 then
        return {}, 0
    end
    if #trv > 2500 then
        return {}, 0
    end
    if pos_next == nil then
        pos_next = pos;
    end
    local nodes = {};
    if has_pos(trv, pos_next) then
        return nodes, 0;
    end

    table.insert(nodes, pos_next)
    table.insert(trv, pos_next);
    local trav_nodes, costs = traverse_atmos_local(pos, pos_next, r);
    for i, pos2 in pairs(trav_nodes) do

        if costs > 250 then
            break
        end

        if has_pos(trv, pos2) == false then
            if math.random(0, 7) > 0 then
                local atmoss, cost = traverse_atmos(trv, pos, pos2, r, depth + 1);
                for i, n in pairs(atmoss) do
                    table.insert(nodes, n)
                end
                costs = costs + cost
            end
        end

    end
    return nodes, costs;
end

local fill_atmos_near = function(pos, r)
    local traversed = {}
    local nodes, cost = traverse_atmos(traversed, pos, nil, r, 0);
    -- minetest.log("found " .. #nodes);
    local count = 0;
    for i, node_pos in pairs(nodes) do
        if (count > 1500) then
            break
        end
        local node = minetest.get_node(node_pos)
        local chng = false;
        local vacc = false;
        if (minetest.get_item_group(node.name, "vacuum") == 1) then
            chng = true;
            vacc = true;
        elseif (minetest.get_item_group(node.name, "atmosphere") == 1) or
            (minetest.get_item_group(node.name, "atmosphere") == 3) then
            chng = true;
        elseif (minetest.get_item_group(node.name, "atmosphere") == 2) then
            chng = true
        end
        if chng then
            count = count + 1;
            if vacc and math.random(0, 2) == 0 then
                minetest.set_node(node_pos, {
                    name = "vacuum:atmos_thin"
                })
            else
                minetest.set_node(node_pos, {
                    name = "air"
                })
            end
            if math.random(0, 4) <= 1 then
                ctg_airs.spawn_particle(node_pos, math.random(-0.001, 0.001), math.random(-0.001, 0.001),
                    math.random(-0.001, 0.001), 0, 0, 0, math.random(1.8, 3), 10, 1)
            end
        end
    end
    return count
end

function ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, time, amount)
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
                x = 0,
                y = 0,
                z = 0
            },
            maxpos = {
                x = 0,
                y = 0,
                z = 0
            },
            minvel = {
                x = rx,
                y = ry,
                z = rz
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
                y = acl_y + math.random(-0.008, 0),
                z = acl_z
            },
            time = 2,
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

    power = power - (20 + count)

    if ((count > 0 or math.random(0, 5) == 0)) then
        minetest.sound_play("air_vent_short", {
            pos = pos,
            gain = 0.071,
            pitch = math.random(0.5, 1)
        })
    end

    -- minetest.log("leaking atmos..")
    return count, power
end

local function process_vent2(pos, power, cost)
    if power <= 0 then
        minetest.get_meta(pos):set_int("active", 0)
        return 0, power
    end

    minetest.get_meta(pos):set_int("active", 1)

    local node = minetest.get_node(pos)
    local param2 = node.param2
    local dir_x = 0.0001
    local dir_z = 0.0001
    local dir_y = 0.0001
    local aclr = 0;
    if param2 == 1 then -- west
        dir_x = 1
        aclr = math.random(-1, 1)
    elseif param2 == 2 then -- north?
        dir_z = -1
        aclr = math.random(-1, 1)
    elseif param2 == 3 then -- east
        dir_x = -1
        aclr = math.random(-1, 1)
    elseif param2 == 0 then -- south
        dir_z = 1
        aclr = math.random(-1, 1)
    elseif param2 == 8 or param2 == 15 or param2 == 6 then
        -- down
        dir_y = 1
    elseif param2 == 10 or param2 == 13 or param2 == 4 then
        -- up
        dir_y = -1
    end

    local acl_x = 0.15 * (dir_x)
    local acl_y = 0.10 * (dir_y + aclr)
    local acl_z = 0.15 * (dir_z)

    local lvl = 0
    if (cost > 8) then
        lvl = 2
    end

    if cost > 8 or math.random(0, 1) == 0 then
        ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, 7, 2)
    end

    for i = 1, 5 + lvl + math.random(0, 3) do
        if cost > 8 or math.random(0, 1) <= 1 then
            minetest.after(i, function()
                ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, 6, 1)
            end)
        end
    end

    if vacuum.is_pos_in_spawn(pos) then
        if ((cost > 0 and math.random(0, 16) == 0) and power > -5) then
            local r = math.random(0, 2)
            minetest.after(r, function()
                minetest.sound_play("air_vent_short", {
                    pos = pos,
                    gain = 0.007,
                    pitch = 0.6 + math.random(-0.001, 0.001)
                })
            end)
        end
        return cost
    end

    if string.match(node.name, "duct_vent") then
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

    local dir_pos = vector.subtract(pos, {
        x = dir_x,
        y = dir_y,
        z = dir_z
    });

    local count = 1;
    local dirty = minetest.get_item_group(node.name, "vent_dirty") or 0

    power = power - (cost + dirty)

    local r = 3
    if cost > 9 then
        r = 10
    elseif cost > 6 then
        r = 7
    elseif cost > 3 then
        r = 4
    end

    count = fill_atmos_near(dir_pos, r - (dirty * 2));

    if ((count > 0 and math.random(0, 10) == 0) and power > -5) then
        local r = math.random(0, 3)
        minetest.after(r, function()
            minetest.sound_play("air_vent_short", {
                pos = pos,
                gain = 0.007 + (count * 0.001),
                pitch = 0.6 + math.random(-0.1, 0.25)
            })
        end)
    end

    -- minetest.log("making atmos..")
    return count, power
end

function ctg_airs.process_vent(pos, power)
    if not pos then
        return 0, power
    end
    if math.random(0, 15) <= 1 then
        return 0, power
    end
    local node = minetest.get_node(pos)
    local cost = minetest.get_item_group(node.name, "vent") or 10
    return process_vent2(pos, power, cost)
end

function ctg_airs.process_junc(junc_pos, dir, power)
    local networks = {}
    return ctg_airs.process_junc2(junc_pos, dir, networks, power)
end

function ctg_airs.process_junc2(junc_pos, dir, networks, power)
    local count = 0;
    for i = 0, 6 do
        local cnt = 0;
        local brek = false;
        local tube = ctg_airs.Tube:get_next_tube(junc_pos, i)
        local dest_pos = ctg_airs.Tube:get_connected_node_pos(junc_pos, i)
        if tube ~= nil or dest_pos ~= nil then
            if dest_pos ~= nil and dest_pos ~= junc_pos and networks[dest_pos] == nil then
                local dest_node = minetest.get_node(dest_pos)
                if dest_node.name == "ctg_airs:air_duct_vent" or dest_node.name == "ctg_airs:air_duct_vent_dirty" or
                    dest_node.name == "ctg_airs:air_duct_vent_lite" or dest_node.name ==
                    "ctg_airs:air_duct_vent_lite_dirty" then
                    networks[dest_pos] = i
                    cnt, power = ctg_airs.process_vent(dest_pos, power)
                    -- minetest.log("found connected vent")
                elseif dest_node.name == "ctg_airs:air_duct_junc" then
                    if tube ~= nil then
                        networks[dest_pos] = i
                        cnt, power = ctg_airs.process_junc2(dest_pos, i, networks, power)
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
    return count, power
end

function ctg_airs.get_duct_output(pos)
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
    elseif check_node_tube(pos2) then
        pos = pos2;
    end

    local node = minetest.get_node(pos)
    local dir1, dir2, num_con = ctg_airs.Tube:decode_param2(pos, node.param2)

    local dest_pos = ctg_airs.Tube:get_connected_node_pos(pos, 6)

    -- minetest.log(tostring(dir1) .. " " .. tostring(dir2) .. " " .. tostring(num_con))

    local loc = minetest.get_meta(pos):get_string("infotext")

    if (dest_pos) then
        -- local dest_pos = minetest.string_to_pos(loc)
        local dest_node = minetest.get_node(dest_pos)
        local dett_dir1, dest_dir2, dest_num_con = ctg_airs.Tube:decode_param2(dest_pos, dest_node.param2)

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
        end
        return 0, nil, nil
    end
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

