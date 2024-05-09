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

function update_formspec3(data, meta, running, enabled)
    return update_formspec2(data, meta, running, enabled, 0, 0)
end

function ctg_airs.register_machine_fan(data)
    local typename = data.typename
    local machine_name = data.machine_name
    local machine_desc = data.machine_desc
    local tier = data.tier
    local ltier = string.lower(tier)
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

    local formspec = update_formspec3(data, nil, false, false)
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

        local machine_desc_tier = S("%s " .. machine_desc):format(tier)
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
            meta:set_int("enabled", 0)
            return
        end

        local EU_upgrade, tube_upgrade = 0, 0
        if data.upgrade then
            EU_upgrade, tube_upgrade = technic.handle_machine_upgrades(meta)
        end
        if data.tube then
            technic.handle_machine_pipeworks(pos, tube_upgrade)
        end

        local powered = eu_input >= machine_demand[EU_upgrade + 1]
        if powered then
            meta:set_int("src_time", meta:get_int("src_time") + round(data.speed * 100 * 1.0))
        end
        while true do
            local enabled = meta:get_int("enabled") == 1

            if (not enabled) then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", machine_desc_tier .. S(" Disabled"))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                local formspec = update_formspec3(data, meta, false, enabled)
                meta:set_string("formspec", formspec)
                return
            end

            if not vacuum.has_in_range(pos, "air", 1, 2) and not vacuum.has_in_range(pos, "vacuum:atmos_thick", 1, 2) then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", machine_desc_tier .. S(" Idle - No air nearby"))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                local formspec = update_formspec3(data, meta, false, enabled)
                meta:set_string("formspec", formspec)
                return
            end

            local formspec = update_formspec3(data, meta, true, enabled)
            meta:set_string("formspec", formspec)
            meta:set_int(tier .. "_EU_demand", machine_demand[EU_upgrade + 1])
            technic.swap_node(pos, machine_node .. "_active")

            if powered and typename == "air_fan" and not vacuum.is_pos_in_spawn(pos) then
                local t0_us = minetest.get_us_time();
                local count = 0;
                local power = 0
                local valid, dest_pos, dir = ctg_airs.get_duct_output_up(pos)
                -- minetest.log(tostring(valid))
                local disable = math.random(0, 2) == 0
                if (valid > 0 and not disable) then
                    local dest_node = minetest.get_node(dest_pos)
                    if (dest_node and dest_node.name == "ctg_airs:air_duct_vent") then
                        count, power = ctg_airs.process_vent(dest_pos, air_power, false)
                        -- minetest.log("vent")
                    elseif (dest_node and dest_node.name == "ctg_airs:air_duct_junc") then
                        count, power = ctg_airs.process_junc(dest_pos, dir, air_power, false)
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
                    elseif (dest_node and dest_node.name == "vacuum:atmos_thick") then
                        count, power = ctg_airs.process_leak(dest_pos, air_power)
                        -- minetest.log("thick atmos")
                    end
                    -- minetest.log("power rem: " .. power)

                    if (power ~= air_power and math.random(0, 2) > 0) or math.random(0, 1) == 0 then
                        ctg_airs.process_atmos(pos, math.random(1, 3))
                    end

                    if (power ~= air_power and math.random(0, 7) == 0) then
                        minetest.sound_play("air_vent_short", {
                            pos = pos,
                            gain = 0.015,
                            pitch = 0.67
                        })
                    end
                end

                local t1_us = minetest.get_us_time();
                local elapsed_time_in_seconds = (t1_us - t0_us) / 1000000.0;
                local elapsed_time_in_milliseconds = elapsed_time_in_seconds * 1000;
                meta:set_string("time_lag", tostring(elapsed_time_in_milliseconds));
            end

            meta:set_string("infotext", machine_desc_tier .. S(" Active"))
            if meta:get_int("src_time") < round(10 * 100) then
                if not powered then
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", machine_desc_tier .. S(" Unpowered"))
                end
                return
            end

            meta:set_int("src_time", meta:get_int("src_time") - round(10 * 100))
            return
        end
    end

    local mv = ""
    if ltier == "mv" then
        mv = "^[colorize:#0fd16612"
    end

    local node_name = data.modname .. ":" .. ltier .. "_" .. machine_name
    minetest.register_node(node_name, {
        description = S("%s " .. machine_desc):format(tier),
        -- up, down, right, left, back, frondrt
        tiles = {ltier .. "_" .. machine_name .. "_top.png", ltier .. "_" .. machine_name .. "_bottom.png" .. mv,
                 ltier .. "_" .. machine_name .. "_side.png" .. mv, ltier .. "_" .. machine_name .. "_side.png" .. mv,
                 ltier .. "_" .. machine_name .. "_side.png" .. mv, ltier .. "_" .. machine_name .. "_front.png" .. mv},
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
            meta:set_string("infotext", S("%s " .. machine_desc):format(tier))
            -- meta:set_int("tube_time", 0)
            local inv = meta:get_inventory()
            -- inv:set_size("src", input_size)
            -- inv:set_size("dst", 4)
            inv:set_size("upgrade1", 1)
            inv:set_size("upgrade2", 1)
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
            local formspec = update_formspec3(data, meta, false, enabled)
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
                action = ctg_airs.fan_digiline_effector
            }
        }
    })

    local len = 1.0
    if (ltier == "mv") then
        len = 0.8
    elseif (ltier == "hv") then
        len = 0.6
    end

    minetest.register_node(data.modname .. ":" .. ltier .. "_" .. machine_name .. "_active", {
        description = S("%s " .. machine_desc):format(tier),
        tiles = {ltier .. "_" .. machine_name .. "_top.png", ltier .. "_" .. machine_name .. "_bottom.png" .. mv,
                 ltier .. "_" .. machine_name .. "_side.png" .. mv, ltier .. "_" .. machine_name .. "_side.png" .. mv,
                 ltier .. "_" .. machine_name .. "_side.png" .. mv, {
            image = ltier .. "_" .. machine_name .. "_active.png" .. mv,
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 32,
                aspect_h = 32,
                length = len
            }
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
            local enabled = false
            if fields.toggle then
                if meta:get_int("enabled") == 1 then
                    meta:set_int("enabled", 0)
                else
                    meta:set_int("enabled", 1)
                    enabled = true
                end
            end
            local formspec = update_formspec3(data, meta, false, enabled)
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
                action = ctg_airs.fan_digiline_effector
            }
        }
    })

    technic.register_machine(tier, node_name, technic.receiver)
    technic.register_machine(tier, node_name .. "_active", technic.receiver)

end -- End registration
