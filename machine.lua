local S = minetest.get_translator(minetest.get_current_modname())

local has_pipeworks = minetest.get_modpath("pipeworks")
local fs_helpers = pipeworks.fs_helpers

local tube_entry_wood = ""
local tube_entry_stone = ""
local tube_entry_metal = ""

if has_pipeworks then
    tube_entry_wood = "^pipeworks_tube_connection_wooden.png"
    tube_entry_stone = "^pipeworks_tube_connection_stony.png"
    tube_entry_metal = "^pipeworks_tube_connection_metallic.png"
end

local connect_default = {"bottom", "back"}

local function round(v)
    return math.floor(v + 0.5)
end
-- rounding function
local function fround(n, prec)
    prec = prec or 3
    local str = string.format("%."..prec.."f", n)
    local num = tonumber(str);
    return tostring(num)
end

local function update_formspec2(data, meta, running, enabled, size, percent)
    local input_size = size
    local machine_desc = data.machine_desc
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil
    if typename == 'air_handler' or typename == 'air_handler_admin' then
        local btnName = "State: "
        if enabled then
            btnName = btnName .. "<Enabled>"
        else
            btnName = btnName .. "<Disabled>"
        end

        local lag_stat = ""
        if meta ~= nil then
            -- lag last
            local lag = meta:get_string("time_lag")
            local clag = lag .. " ms"
            if lag and tonumber(lag, 10) ~= nil then
                if tonumber(lag, 10) >= 25 then
                    clag = minetest.colorize('#ff3b21', lag .. " ms")
                elseif tonumber(lag, 10) >= 10 then
                    clag = minetest.colorize('#ffcb21', lag .. " ms")
                elseif tonumber(lag, 10) < 1 then
                    clag = minetest.colorize('#25ff21', lag .. " ms")
                else
                    clag = minetest.colorize('#21ffb5', lag .. " ms")
                end
            end
            local lag = "label[4,0.175;Lag:]" .. "label[4.6,0.175;" .. clag .. "]"
            -- lag avg
            local lag_listing = meta:get_string("time_lag_list") or nil
            local lag_list = lag_listing and core.deserialize(lag_listing) or {}
            local count = 0 
            local total = 0
            for _, l in pairs(lag_list) do
                total = total + l
                count = count + 1
            end
            local avg = (total / count)
            local acol = ctg_airs.get_color_range_text(38 - avg, 38)
            local alag = minetest.colorize(acol, fround(avg, 1) .. " ms")
            local avg = "label[4,0.5;Avg:]" .. "label[4.6,0.5;" .. alag .. "]"
            -- lag stat
            lag_stat = avg .. lag
        end

        local image = "ctg_gauge_0.png"
        if running then
            local lag = meta:get_string("time_lag")
            if lag and tonumber(lag, 10) ~= nil then
                local lagg = tonumber(lag, 10);
                if lagg > 30 then
                    image = "ctg_gauge_1.png"
                elseif lagg > 20 then
                    image = "ctg_gauge_2.png"
                elseif lagg > 10 then
                    image = "ctg_gauge_3.png"
                elseif lagg > 3 then
                    image = "ctg_gauge_4.png"
                else
                    image = "ctg_gauge_5.png"
                end
            end
        end

        local p = 0
        if meta then
            if data.power ~= nil and tonumber(meta:get_string("air_power")) ~= nil then
                p = data.power - tonumber(meta:get_string("air_power"));
            end
        end
        local power = "label[0.5,1.1;" .. minetest.colorize('#429dff', "Air Power") .. "]" .. "label[0.5,1.5;" ..
                          "Max: " .. data.power .. "]" .. "label[0.5,1.86;" .. "Now: " .. p .. "]"

        formspec = "size[8,9;]" .. "list[current_name;src;" .. (4 - input_size) .. ",1.5;" .. input_size .. ",1;]" ..
                       "list[current_name;dst;5,1;2,2;]" .. "list[current_player;main;0,5;8,4;]" .. "label[0,0;" ..
                       machine_desc:format(tier) .. "]" .. -- "image[4,1;1,1;".. image .."]"..
        "image[4,1;1,1;" .. image .. "]" .. lag_stat .. power .. -- "animated_image[4,1;1,1;an_img;recycler_front_active.png;4;800;1]"..
        "image[4,2.0;1,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent) ..
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "listring[current_name;dst]" ..
                       "listring[current_player;main]" .. "listring[current_name;src]" ..
                       "listring[current_player;main]" .. "button[3,3;4,1;toggle;" .. btnName .. "]"
    elseif typename == 'air_fan' then
        local btnName = "State: "
        if enabled then
            btnName = btnName .. "<Enabled>"
        else
            btnName = btnName .. "<Disabled>"
        end

        local lag_stat = ""
        if meta ~= nil then
            local lag = meta:get_string("time_lag")
            local clag = lag .. " ms"
            if lag and tonumber(lag, 10) ~= nil then
                if tonumber(lag, 10) >= 25 then
                    clag = minetest.colorize('#ff3b21', lag .. " ms")
                elseif tonumber(lag, 10) >= 10 then
                    clag = minetest.colorize('#ffcb21', lag .. " ms")
                elseif tonumber(lag, 10) < 1 then
                    clag = minetest.colorize('#25ff21', lag .. " ms")
                else
                    clag = minetest.colorize('#21ffb5', lag .. " ms")
                end
            end
            lag_stat = "label[3.5,0.5;Lag:]" .. "label[4,0.5;" .. clag .. "]"
        end

        local image = "ctg_fan_icon.png"
        if (running) then
            image = "ctg_fan_on_icon.png"
        end
        formspec = "size[8,9;]" .. "list[current_player;main;0,5;8,4;]" .. "label[0,0;" .. machine_desc:format(tier) ..
                       "]" .. "image[4,1;1,1;" .. image .. "]" .. lag_stat .. "listring[current_player;main]" ..
                       "listring[current_player;main]" .. "button[3,3;4,1;toggle;" .. btnName .. "]"
    end

    if data.upgrade then
        formspec = formspec .. "list[current_name;upgrade1;1,3;1,1;]" .. "list[current_name;upgrade2;2,3;1,1;]" ..
                       "label[1,4;" .. S("Upgrade Slots") .. "]" .. "listring[current_name;upgrade1]" ..
                       "listring[current_player;main]" .. "listring[current_name;upgrade2]" ..
                       "listring[current_player;main]"
    end
    return formspec
end

local  function update_formspec(data, meta, running, enabled, size)
    return update_formspec2(data, meta, running, enabled, size, 0)
end

function ctg_airs.update_formspec(data, meta, running, enabled, size)
    return update_formspec(data, meta, running, enabled, size)
end

local function get_bottle(typename, items, has_air_near)
    local new_input = {}
    local new_output = nil
    local run_length = 0;
    if typename == "bottle" then
        local c = 1;
        for i, stack in ipairs(items) do
            if stack:get_name() == 'vacuum:air_bottle' then
                -- skip over full bottle..
            elseif stack:get_name() == 'vessels:steel_bottle' then
                new_input[i] = ItemStack(stack)
                new_input[i]:take_item(1)
                new_output = ItemStack({
                    name = "vacuum:air_bottle",
                    count = c
                })
                run_length = 6 + c
                c = c + 1
                break
            end
        end
    end
    if typename == "air_handler" then
        local c = 1;
        for i, stack in ipairs(items) do
            if stack:get_name() == 'vacuum:air_bottle' then
                new_input[i] = ItemStack(stack)
                new_input[i]:take_item(1)
                new_output = ItemStack({
                    name = "vessels:steel_bottle",
                    count = c
                })
                if has_air_near then
                    run_length = 15 + c
                else
                    run_length = 5 + c
                end
                c = c + 1
                break
            elseif stack:get_name() == 'vessels:steel_bottle' then
                -- skip over empty bottle..
            end
        end
    end
    if typename == "air_handler_admin" then
        run_length = 10
    end
    if (run_length > 0) then
        return {
            time = run_length,
            new_input = new_input,
            output = new_output
        }
    else
        return nil
    end
end

function ctg_airs.register_machine(data)
    local typename = data.typename
    local input_size = 1
    if typename == 'bottle' then
        input_size = 2
    end
    local tier = data.tier
    local ltier = string.lower(tier)
    local machine_name = data.machine_name
    local machine_desc = tier .. " " .. data.machine_desc
    local air_power = data.power

    data.modname = data.modname or minetest.get_current_modname()

    local groups = {
        cracky = 2,
        technic_machine = 1,
        ["technic_" .. ltier] = 1,
        ctg_machine = 1,
        metal = 1
    }
    if data.tube then
        groups.tubedevice = 1
        groups.tubedevice_receiver = 1
    end
    local active_groups = {
        not_in_creative_inventory = 1
    }
    for k, v in pairs(groups) do
        active_groups[k] = v
    end

    local formspec = update_formspec(data, nil, false, false, input_size)
    local tube = technic.new_default_tube()
    if data.can_insert then
        tube.can_insert = data.can_insert
    end
    if data.insert_object then
        tube.insert_object = data.insert_object
    end

    local run = function(pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local eu_input = meta:get_int(tier .. "_EU_input")

        local machine_desc_tier = machine_desc
        local machine_node = data.modname .. ":" .. ltier .. "_" .. machine_name
        local machine_demand = data.demand

        -- Setup meta data if it does not exist.
        if not eu_input then
            meta:set_int(tier .. "_EU_demand", machine_demand[1])
            meta:set_int(tier .. "_EU_input", 0)
            return
        end

        if not meta:get_string("time_lag") then
            meta:set_string("time_lag", "0")
        end

        if not meta:get_int("enabled") then
            meta:set_int("enabled", 1)
            return
        end

        local EU_upgrade, tube_upgrade = 0, 0
        if data.upgrade then
            EU_upgrade, tube_upgrade = technic.handle_machine_upgrades(meta)
        end
        if data.tube then
            technic.handle_machine_pipeworks(pos, tube_upgrade)
        end

        if not meta:get_int("vent_tick") then
            meta:set_int("vent_tick", 1);
        end

        local powered = eu_input >= machine_demand[EU_upgrade + 1]
        if powered then
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 100 * 1.0))
        end
        local form_buttons = ""
        if not string.find(node.name, ":lv_") then
            form_buttons = fs_helpers.cycling_button(meta, pipeworks.button_base, "splitstacks",
                {pipeworks.button_off, pipeworks.button_on}) .. pipeworks.button_label
        end
        while true do
            local enabled = meta:get_int("enabled") == 1
            if typename == 'vacuum' then
                for i = 1, 2 do
                    local node_above = minetest.get_node({
                        x = pos.x,
                        y = pos.y + i,
                        z = pos.z
                    })
                    if node_above.name == 'air' then
                        ctg_airs.process_air(pos)
                        break
                    end
                end
            end

            if (not enabled) then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", machine_desc_tier .. S(" Disabled"))
                meta:set_int(tier .. "_EU_demand", 0)
                -- meta:set_int("src_time", 0)
                local formspec = update_formspec(data, meta, false, enabled, input_size)
                meta:set_string("formspec", formspec .. form_buttons)
                return
            end

            --[[if vacuum.has_in_range(pos, "air", 1, 1) == false and
                vacuum.has_in_range(pos, "technic:dummy_light_source", 1, 1) == false and typename ~=
                "air_handler_admin" then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", machine_desc_tier .. S(" Idle - No air nearby"))
                meta:set_int(tier .. "_EU_demand", 0)
                -- meta:set_int("src_time", 0)
                local formspec = update_formspec(data, meta, false, enabled, input_size)
                meta:set_string("formspec", formspec .. form_buttons)
                return
            end]]--

            local has_air_near = vacuum.has_in_range(pos, "air", 1, 3);
            local result = get_bottle(typename, inv:get_list("src"), has_air_near)
            if not result then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", machine_desc_tier .. S(" Idle - No air bottles"))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                local formspec = update_formspec(data, meta, false, enabled, input_size)
                meta:set_string("formspec", formspec .. form_buttons)
                return
            end

            local item_percent = (math.floor(meta:get_int("src_time") / round(result.time * 250) * 100))
            local formspec = update_formspec2(data, meta, true, enabled, input_size, item_percent)
            meta:set_string("formspec", formspec .. form_buttons)
            meta:set_int(tier .. "_EU_demand", machine_demand[EU_upgrade + 1])
            if (item_percent > 20) then
                technic.swap_node(pos, machine_node .. "_active")
            elseif (math.random(1, 3) > 1) then
                technic.swap_node(pos, machine_node .. "_wait")
            end
            meta:set_string("infotext", machine_desc_tier .. S(" Active"))
            if meta:get_int("src_time") < round(result.time * 250) then
                if powered == false and typename ~= "air_handler_admin" then
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", machine_desc_tier .. S(" Unpowered"))
                    return;
                end
            end

            meta:set_int("vent_tick", meta:get_int("vent_tick") - 1);
            if meta:get_int("vent_tick") <= 0 and (typename == "air_handler" or typename == "air_handler_admin") and
                not vacuum.is_pos_in_spawn(pos) then

                local t0_us = minetest.get_us_time();

                local hasPur = typename == "air_handler_admin";
                local count = 0;
                local power = air_power or 0
                local valid, dest_pos, dir = ctg_airs.get_duct_output_up(pos)
                --ctg_airs.Tube:infotext(pos, dest_pos)
                -- minetest.log(tostring(valid))
                local disable = false
                if (valid > 0 and not disable) then
                    -- minetest.log("processing air handler... " .. tostring(pos))
                    local dest_node = minetest.get_node(dest_pos)
                    if (dest_node and dest_node.name == "ctg_airs:air_duct_vent") then
                        count, power = ctg_airs.process_vent(dest_pos, air_power, hasPur)
                        -- minetest.log("vent")
                    elseif (dest_node and dest_node.name == "ctg_airs:air_duct_junc") then
                        count, power = ctg_airs.process_junc(dest_pos, dir, air_power, hasPur)
                        -- minetest.log("junc")
                    elseif (dest_node and ctg_airs.isAirPurifier(dest_node)) then
                        count, power = ctg_airs.process_purifier(dest_pos, dir, air_power)
                        -- minetest.log("purifier")
                    elseif (dest_node and dest_node.name == "vacuum:vacuum") then
                        count, power = ctg_airs.process_leak(dest_pos, air_power)
                        -- minetest.log("vacuum")
                    elseif (dest_node and dest_node.name == "vacuum:atmos_thin") then
                        count, power = ctg_airs.process_leak(dest_pos, air_power)
                        -- minetest.log("thin atmos")
                    elseif (dest_node and dest_node.name == "air") then
                        count, power = ctg_airs.process_leak(dest_pos, air_power)
                        -- minetest.log("thick atmos")
                    end
                    -- minetest.log("power rem: " .. power)

                    if count <= 1 then
                        meta:set_int("vent_tick", math.random(1, 5));
                    elseif count <= 27 then
                        meta:set_int("vent_tick", math.random(1, 4));
                    elseif count <= 125 then
                        meta:set_int("vent_tick", math.random(1, 3));
                    else
                        meta:set_int("vent_tick", 2);
                    end

                    meta:set_int("src_time", meta:get_int("src_time") + round(count))
                    meta:set_int("air_power", power);

                    if math.random(0, 2) > 0 then
                        ctg_airs.spawn_particle(pos, 0, 0, 0, math.random(-0.1, 0.1), math.random(-0.1, 0.1),
                            math.random(-0.1, 0.2), 3)
                    end

                    if (power ~= air_power and math.random(0, 5) == 0) then
                        minetest.sound_play("air_vent_short", {
                            pos = pos,
                            gain = 0.02 + (count * 0.001),
                            pitch = math.random(0.57, 0.72)
                        })
                    end
                end

                local t1_us = minetest.get_us_time();
                local elapsed_time_in_seconds = (t1_us - t0_us) / 1000000.0;
                local elapsed_time_in_milliseconds = elapsed_time_in_seconds * 1000;
                meta:set_string("time_lag", tostring(elapsed_time_in_milliseconds));

                -- lag listing
                local lag_listing = meta:get_string("time_lag_list") or nil
                local lag_list = lag_listing and core.deserialize(lag_listing) or {}
                table.insert(lag_list, elapsed_time_in_milliseconds)
                if #lag_list > 20 then
                    table.remove(lag_list, 1)
                end
                meta:set_string("time_lag_list", core.serialize(lag_list))

                if elapsed_time_in_milliseconds >= 60 then
                    meta:set_int("vent_tick", meta:get_int("vent_tick") + 11);
                elseif elapsed_time_in_milliseconds >= 50 then
                    meta:set_int("vent_tick", meta:get_int("vent_tick") + 9);
                elseif elapsed_time_in_milliseconds >= 40 then
                    meta:set_int("vent_tick", meta:get_int("vent_tick") + 7);
                elseif elapsed_time_in_milliseconds >= 30 then
                    meta:set_int("vent_tick", meta:get_int("vent_tick") + 5);
                elseif elapsed_time_in_milliseconds >= 20 then
                    meta:set_int("vent_tick", meta:get_int("vent_tick") + 3);
                elseif elapsed_time_in_milliseconds >= 10 then
                    meta:set_int("vent_tick", meta:get_int("vent_tick") + 2);
                elseif elapsed_time_in_milliseconds >= 5 then
                    meta:set_int("vent_tick", meta:get_int("vent_tick") + 1);
                end
            end

            if meta:get_int("src_time") < round(result.time * 250) then
                return
            end

            -- technic.swap_node(pos, machine_node.."_wait")
            local output = result.output
            if output ~= nil then
                if type(output) ~= "table" then
                    output = {output}
                end
                local output_stacks = {}
                for _, o in ipairs(output) do
                    table.insert(output_stacks, ItemStack(o))
                end
                local room_for_output = true
                inv:set_size("dst_tmp", inv:get_size("dst"))
                inv:set_list("dst_tmp", inv:get_list("dst"))
                for _, o in ipairs(output_stacks) do
                    if not inv:room_for_item("dst_tmp", o) then
                        room_for_output = false
                        break
                    end
                    inv:add_item("dst_tmp", o)
                end
                if not room_for_output then
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", machine_desc_tier .. S(" Idle - Output full"))
                    meta:set_int(tier .. "_EU_demand", 0)
                    meta:set_int("src_time", round(result.time * 250))
                    return
                end
            end
            meta:set_int("src_time", 0)
            inv:set_list("src", result.new_input)
            inv:set_list("dst", inv:get_list("dst_tmp"))

            return
        end
    end

    local node_name = data.modname .. ":" .. ltier .. "_" .. machine_name
    minetest.register_node(node_name, {
        description = machine_desc:format(tier),
        -- up, down, right, left, back, frondrt
        tiles = {ltier .. "_" .. machine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_bottom.png" .. tube_entry_metal,
                 ltier .. "_" .. machine_name .. "_top.png", ltier .. "_" .. machine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_side.png" .. tube_entry_metal,
                 ltier .. "_" .. machine_name .. "_front.png"},
        paramtype2 = "facedir",
        groups = groups,
        tube = data.tube and tube or nil,
        connect_sides = data.connect_sides or connect_default,
        legacy_facedir_simple = true,
        sounds = default.node_sound_wood_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local tube_dir = ((minetest.dir_to_facedir(placer:get_look_dir()) + 2) % 4) + 1
            minetest.get_meta(pos):set_int("tube_dir", tube_dir)
            ctg_airs.Tube:after_place_node(pos, {tube_dir})
            if data.tube then
                pipeworks.after_place(pos)
            end
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            ctg_airs.Tube:after_dig_node(pos)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        on_construct = function(pos)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)

            local form_buttons = ""
            if not string.find(node.name, ":lv_") and not string.find(node.name, ":mv_") then
                form_buttons = fs_helpers.cycling_button(meta, pipeworks.button_base, "splitstacks",
                    {pipeworks.button_off, pipeworks.button_on}) .. pipeworks.button_label
            end

            meta:set_string("infotext", machine_desc:format(tier))
            meta:set_int("tube_time", 0)
            meta:set_string("formspec", formspec .. form_buttons)
            local inv = meta:get_inventory()
            inv:set_size("src", input_size)
            inv:set_size("dst", 4)
            inv:set_size("upgrade1", 1)
            inv:set_size("upgrade2", 1)
            meta:set_int("enabled", 1)
        end,
        can_dig = technic.machine_can_dig,
        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        technic_run = run,
        on_receive_fields = function(pos, formname, fields, sender)
            if fields.quit then
                return
            end
            if not pipeworks.may_configure(pos, sender) then
                return
            end
            fs_helpers.on_receive_fields(pos, fields)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            local form_buttons = ""
            if not string.find(node.name, ":lv_") and not string.find(node.name, ":mv_") then
                form_buttons = fs_helpers.cycling_button(meta, pipeworks.button_base, "splitstacks",
                    {pipeworks.button_off, pipeworks.button_on}) .. pipeworks.button_label
            end
            local enabled = false
            if fields.toggle then
                if meta:get_int("enabled") == 1 then
                    meta:set_int("enabled", 0)
                else
                    meta:set_int("enabled", 1)
                    enabled = true
                end
            end
            local formspec = update_formspec(data, meta, false, enabled, input_size)
            meta:set_string("formspec", formspec .. form_buttons)
        end,
        mesecons = {
            effector = {
                action_on = function(pos, node)
                    local meta = minetest.get_meta(pos)
                    meta:set_int("enabled", 1)
                end,
                action_off = function(pos, node)
                    local meta = minetest.get_meta(pos)
                    meta:set_int("enabled", 0)
                end
            }
        },
        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = ctg_airs.digiline_effector
            }
        }
    })

    local animation = {
        type = "vertical_frames",
        aspect_w = 64,
        aspect_h = 64,
        length = 1.75
    }

    minetest.register_node(data.modname .. ":" .. ltier .. "_" .. machine_name .. "_active", {
        description = machine_desc:format(tier),
        tiles = {ltier .. "_" .. machine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_bottom.png" .. tube_entry_metal,
                 ltier .. "_" .. machine_name .. "_top.png", ltier .. "_" .. machine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_side.png" .. tube_entry_metal, {
            image = ltier .. "_" .. machine_name .. "_active.png",
            backface_culling = false,
            animation = animation
        }},
        paramtype2 = "facedir",
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = active_groups,
        connect_sides = data.connect_sides or connect_default,
        legacy_facedir_simple = true,
        sounds = default.node_sound_wood_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            ctg_airs.Tube:after_place_node(pos)
            if data.tube then
                pipeworks.after_place(pos)
            end
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            ctg_airs.Tube:after_dig_node(pos)
            return technic.machine_after_dig_node
        end,
        on_push_item = function(pos, dir, item)
            local tube_dir = minetest.get_meta(pos):get_int("tube_dir")
            if dir == tubelib2.Turn180Deg[tube_dir] then
                local s = minetest.get_meta(pos):get_string("peer_pos")
                if s and s ~= "" then
                    push_item(minetest.string_to_pos(s))
                    return true
                end
            end
        end,
        on_rotate = screwdriver.disallow,
        tube = data.tube and tube or nil,
        can_dig = technic.machine_can_dig,
        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        technic_run = run,
        technic_disabled_machine_name = data.modname .. ":" .. ltier .. "_" .. machine_name,
        on_receive_fields = function(pos, formname, fields, sender)
            if fields.quit then
                return
            end
            if not pipeworks.may_configure(pos, sender) then
                return
            end
            fs_helpers.on_receive_fields(pos, fields)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            local form_buttons = ""
            if not string.find(node.name, ":lv_") and not string.find(node.name, ":mv_") then
                form_buttons = fs_helpers.cycling_button(meta, pipeworks.button_base, "splitstacks",
                    {pipeworks.button_off, pipeworks.button_on}) .. pipeworks.button_label
            end
            if fields.toggle then
                if meta:get_int("enabled") == 1 then
                    meta:set_int("enabled", 0)
                else
                    meta:set_int("enabled", 1)
                end
            end
            meta:set_string("formspec", formspec .. form_buttons)
        end,
        mesecons = {
            effector = {
                action_on = function(pos, node)
                    local meta = minetest.get_meta(pos)
                    meta:set_int("enabled", 1)
                end,
                action_off = function(pos, node)
                    local meta = minetest.get_meta(pos)
                    meta:set_int("enabled", 0)
                end
            }
        },
        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = ctg_airs.digiline_effector
            }
        }
    })

    minetest.register_node(data.modname .. ":" .. ltier .. "_" .. machine_name .. "_wait", {
        description = machine_desc:format(tier),
        tiles = {ltier .. "_" .. machine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_bottom.png" .. tube_entry_metal,
                 ltier .. "_" .. machine_name .. "_top.png", ltier .. "_" .. machine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_side.png" .. tube_entry_metal,
                 ltier .. "_" .. machine_name .. "_front_wait.png"},
        sunlight_propagates = (typename == 'compost'),
        paramtype2 = "facedir",
        drop = data.modname .. ":" .. ltier .. "_" .. machine_name,
        groups = active_groups,
        connect_sides = data.connect_sides or connect_default,
        legacy_facedir_simple = true,
        sounds = default.node_sound_wood_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            ctg_airs.Tube:after_place_node(pos)
            if data.tube then
                pipeworks.after_place(pos)
            end
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            ctg_airs.Tube:after_dig_node(pos)
            return technic.machine_after_dig_node
        end,
        on_rotate = screwdriver.disallow,
        tube = data.tube and tube or nil,
        can_dig = technic.machine_can_dig,
        allow_metadata_inventory_put = technic.machine_inventory_put,
        allow_metadata_inventory_take = technic.machine_inventory_take,
        allow_metadata_inventory_move = technic.machine_inventory_move,
        technic_run = run,
        technic_disabled_machine_name = data.modname .. ":" .. ltier .. "_" .. machine_name,
        on_receive_fields = function(pos, formname, fields, sender)
            if fields.quit then
                return
            end
            if not pipeworks.may_configure(pos, sender) then
                return
            end
            fs_helpers.on_receive_fields(pos, fields)
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            local form_buttons = ""
            if not string.find(node.name, ":lv_") and not string.find(node.name, ":mv_") then
                form_buttons = fs_helpers.cycling_button(meta, pipeworks.button_base, "splitstacks",
                    {pipeworks.button_off, pipeworks.button_on}) .. pipeworks.button_label
            end
            if fields.toggle then
                if meta:get_int("enabled") == 1 then
                    meta:set_int("enabled", 0)
                else
                    meta:set_int("enabled", 1)
                end
            end
            meta:set_string("formspec", formspec .. form_buttons)
        end,
        mesecons = {
            effector = {
                action_on = function(pos, node)
                    local meta = minetest.get_meta(pos)
                    meta:set_int("enabled", 1)
                end,
                action_off = function(pos, node)
                    local meta = minetest.get_meta(pos)
                    meta:set_int("enabled", 0)
                end
            }
        },
        digiline = {
            receptor = {
                action = function()
                end
            },
            effector = {
                action = ctg_airs.digiline_effector
            }
        }
    })

    technic.register_machine(tier, node_name, technic.receiver)
    technic.register_machine(tier, node_name .. "_wait", technic.receiver)
    technic.register_machine(tier, node_name .. "_active", technic.receiver)

end -- End registration
