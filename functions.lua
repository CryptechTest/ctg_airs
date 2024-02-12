local S = technic.getter

local c_vacuum = minetest.get_content_id("vacuum:vacuum")
local c_atmos_thin = minetest.get_content_id("vacuum:atmos_thin")
local c_atmos_thick = minetest.get_content_id("vacuum:atmos_thick")
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
    local vent = {"ctg_airs:air_duct_vent"}

    local node = minetest.get_node(pos)

    if vent[node.name] ~= nil then
        return true
    end
    return false
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
    if (dist > r) then
        return nodes;
    end
    table.insert(nodes, pos);
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
        if (dist < math.random(math.max(2, r - 3), r + 1)) then
            local n = minetest.get_node(cur_pos);
            if n then
                if minetest.get_item_group(n.name, "vacuum") == 1 or minetest.get_item_group(n.name, "atmosphere") > 0 then
                    table.insert(nodes, cur_pos);
                end
            end
        end
    end
    return nodes;
end

local function traverse_atmos(trv, pos, pos_next, r, depth)
    if depth > 12 then
        return {}
    end
    if pos_next == nil then
        pos_next = pos;
    end
    local nodes = {};
    if has_pos(trv, pos_next) then
        return nodes;
    end
    table.insert(nodes, pos_next)
    table.insert(trv, pos_next);
    local trav_nodes = traverse_atmos_local(pos, pos_next, r);
    for i, pos2 in pairs(trav_nodes) do
        if has_pos(trv, pos2) == false then
            local atmoss = traverse_atmos(trv, pos, pos2, r, depth + 1);
            for i, n in pairs(atmoss) do
                table.insert(nodes, n)
            end
        end

    end
    return nodes;
end

local fill_atmos_near = function(pos, r)
    local traversed = {}
    local nodes = traverse_atmos(traversed, pos, nil, r, 0);
    -- minetest.log("found " .. #nodes);
    local count = 0;
    for i, node_pos in pairs(nodes) do
        if (count > 50) then -- 125=5x5
            break
        end
        local node = minetest.get_node(node_pos)
        local chng = false;
        local vacc = false;
        if (minetest.get_item_group(node.name, "vacuum") == 1) then
            chng = true;
            vacc = true;
        elseif (minetest.get_item_group(node.name, "atmosphere") == 1) then
            chng = true;
        end
        if chng then
            count = count + 1;
            if vacc then
                minetest.set_node(node_pos, {
                    name = "vacuum:atmos_thin"
                })
            else
                minetest.set_node(node_pos, {
                    name = "vacuum:atmos_thick"
                })
            end
            if math.random(0, 5) == 0 then
                ctg_airs.spawn_particle(node_pos, math.random(-0.001, 0.001), math.random(-0.001, 0.001),
                    math.random(-0.001, 0.001), 0, 0, 0, math.random(2, 4), 10)
            end
        end
    end
end

function ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, time)
    local texture = "ctg_air_vent_vapor.png"
    if (math.random() > 0.5) then
        texture = "ctg_air_vent_vapor.png^[transformR90]"
    end
    local prt = {
        texture = texture,
        vel = 2,
        time = time or 6,
        size = 3 + (lvl or 1),
        glow = 3,
        cols = true
    }

    local v = vector.new()
    v.x = 0.0001
    v.y = 0.001
    v.z = 0.0001
    if math.random(1, 10) > 1 then
        local rx = dir_x * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        local ry = dir_y * prt.vel * -math.random(0.3 * 100, 0.6 * 100) / 100
        local rz = dir_z * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        minetest.add_particle({
            pos = pos,
            velocity = vector.add(v, {
                x = rx,
                y = ry,
                z = rz
            }),
            acceleration = {
                x = acl_x,
                y = acl_y + math.random(-0.08, 0),
                z = acl_z
            },
            expirationtime = ((math.random() / 5) + 0.3) * prt.time,
            size = ((math.random(0.75, 0.95)) * 2 + 0.1) * prt.size,
            collisiondetection = prt.cols,
            vertical = false,
            texture = prt.texture,
            glow = prt.glow
        })
    end
end

function ctg_airs.process_atmos(pos)
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

        local max = 1
        local count = 0
        for z = pos1.z, pos2.z do
            for y = pos1.y, pos2.y do
                for x = pos1.x, pos2.x do

                    if (count >= max) then
                        break
                    end

                    local index = area:index(x, y, z)
                    if data[index] == c_atmos_thick then
                        data[index] = c_atmos_thin
                        count = count + 1
                    end

                end
            end
        end

        manip:set_data(data)
        manip:write_to_map()

        if (count > 0) then
            break
        end
    end
end

function ctg_airs.process_leak(pos, power)
    if not pos then
        return power
    end

    if power <= -10 then
        return power
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
        dir_y = math.random(-0.5, 0.5)
        dir_z = math.random(-0.5, 0.5)
    end

    local acl_x = 0.28 * (dir_x)
    local acl_y = 0.05 * (dir_y)
    local acl_z = 0.28 * (dir_z)

    ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, 1.5, 7)
    for i = 0, 5 do
        minetest.after(i, function()
            ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, 1, 6)
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
                    data[index] = c_atmos_thick
                    count = count + 1
                elseif data[index] == c_vacuum then
                    data[index] = c_atmos_thin
                    count = count + 1
                elseif data[index] == c_air then
                    data[index] = c_atmos_thin
                    count = count + 1
                end

            end
        end
    end

    manip:set_data(data)
    manip:write_to_map()

    power = power - (20 + count)

    if ((count > 0 or math.random(0, 2) == 0)) then
        minetest.sound_play("air_vent_short", {
            pos = pos,
            gain = 0.01,
            pitch = 1.0
        })
    end

    -- minetest.log("leaking atmos..")
    return power
end

local function process_vent2(pos, power, cost)
    if power <= 0 then
        minetest.get_meta(pos):set_int("active", 0)
        return power
    end

    minetest.get_meta(pos):set_int("active", 1)

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
    elseif param2 == 0 then -- south
        dir_z = 1
    elseif param2 == 8 or param2 == 15 or param2 == 6 then
        -- down
        dir_y = 1
    elseif param2 == 10 or param2 == 13 or param2 == 4 then
        -- up
        dir_y = -1
    end

    local acl_x = 0.2 * (dir_x)
    local acl_y = 0.2 * (dir_y)
    local acl_z = 0.2 * (dir_z)

    local lvl = 0
    if (cost > 8) then
        lvl = 1
    end

    if cost > 8 or math.random(0, 1) == 0 then
        ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, 7)
    end

    for i = 1, 5 + lvl + math.random(0, 1) do
        if cost > 8 or math.random(0, 2) == 0 then
            minetest.after(i, function()
                ctg_airs.spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, 6)
            end)
        end
    end

    if vacuum.is_pos_in_spawn(pos) then
        if ((cost > 0 and math.random(0, 2) == 0) and power > -5) then
            local r = math.random(0.2, 1)
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

    local r = 4
    local m = 0
    if cost > 9 then
        r = 8
        m = 5
    elseif cost > 6 then
        r = 7
        m = 3
    elseif cost > 3 then
        r = 5
        m = 1
    end

    fill_atmos_near(dir_pos, r - dirty);

    if ((count > 0 and math.random(0, 2) == 0) and power > -5) then
        local r = math.random(0.2, 1)
        minetest.after(r, function()
            minetest.sound_play("air_vent_short", {
                pos = pos,
                gain = 0.007,
                pitch = 0.6 + math.random(-0.001, 0.001)
            })
        end)
    end

    -- minetest.log("making atmos..")
    return power
end

function ctg_airs.process_vent(pos, power)
    if not pos then
        return power
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
    for i = 0, 6 do
        local tube = ctg_airs.Tube:get_next_tube(junc_pos, i)
        if tube ~= nil then
            local dest_pos = ctg_airs.Tube:get_connected_node_pos(junc_pos, i)
            if dest_pos ~= nil and dest_pos ~= junc_pos and networks[dest_pos] == nil then
                local dest_node = minetest.get_node(dest_pos)
                if dest_node.name == "ctg_airs:air_duct_vent" or dest_node.name == "ctg_airs:air_duct_vent_dirty" or
                    dest_node.name == "ctg_airs:air_duct_vent_lite" or dest_node.name ==
                    "ctg_airs:air_duct_vent_lite_dirty" then
                    networks[dest_pos] = i
                    power = ctg_airs.process_vent(dest_pos, power)
                    -- minetest.log("found connected vent")
                elseif dest_node.name == "ctg_airs:air_duct_junc" then
                    networks[dest_pos] = i
                    power = ctg_airs.process_junc2(dest_pos, i, networks, power) - 2
                    -- minetest.log("found connected junc")
                elseif (dest_node and dest_node.name == "vacuum:vacuum") then
                    networks[dest_pos] = i
                    power = ctg_airs.process_leak(dest_pos, power)
                    -- minetest.log("vacuum")
                elseif (dest_node and dest_node.name == "vacuum:atmos_thin") then
                    networks[dest_pos] = i
                    power = ctg_airs.process_leak(dest_pos, power)
                    -- minetest.log("thin atmos")
                elseif (dest_node and dest_node.name == "vacuum:atmos_thick") then
                    networks[dest_pos] = i
                    power = ctg_airs.process_leak(dest_pos, power)
                    -- minetest.log("thick atmos")
                end
            end
            if power <= 0 then
                break
            end
        end
    end
    return power
end

function ctg_airs.get_duct_output(pos)
    pos = {
        x = pos.x,
        y = pos.y + 1,
        z = pos.z
    }

    local node = minetest.get_node(pos)
    local dir1, dir2, num_con = ctg_airs.Tube:decode_param2(pos, node.param2)

    local dest_pos = ctg_airs.Tube:get_connected_node_pos(pos, 6)

    -- minetest.log(tostring(dir1) .. " " .. tostring(dir2) .. " " .. tostring(num_con))

    local loc = minetest.get_meta(pos):get_string("infotext")

    if (dest_pos) then
        -- local dest_pos = minetest.string_to_pos(loc)
        local dest_node = minetest.get_node(dest_pos)
        local dett_dir1, dest_dir2, dest_num_con = ctg_airs.Tube:decode_param2(dest_pos, dest_node.param2)

        if dest_node.name == "vacuum:atmos_thick" then
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

