-- local S = minetest.get_translator(minetest.get_current_modname())
local S = technic.getter

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

function update_formspec(data, running, enabled, size)
    return update_formspec2(data, running, enabled, size, 0)
end

function update_formspec2(data, running, enabled, size, percent)
    local input_size = size
    local machine_desc = data.machine_desc
    local typename = data.typename
    local tier = data.tier
    local ltier = string.lower(tier)
    local formspec = nil
    if typename == 'air_handler' then
        local btnName = "State: "
        if enabled then
            btnName = btnName .. "<Enabled>"
        else
            btnName = btnName .. "<Disabled>"
        end

        local image = "bottler_gauge.png"
        if (running) then
            image = "bottler_gauge.png"
        end
        formspec = "size[8,9;]" .. "list[current_name;src;" .. (4 - input_size) .. ",1.5;" .. input_size .. ",1;]" ..
                       "list[current_name;dst;5,1;2,2;]" .. "list[current_player;main;0,5;8,4;]" .. "label[0,0;" ..
                       machine_desc:format(tier) .. "]" .. -- "image[4,1;1,1;".. image .."]"..
        "image[4,1;1,1;" .. image .. "]" .. -- "animated_image[4,1;1,1;an_img;recycler_front_active.png;4;800;1]"..
        "image[4,2.0;1,1;gui_furnace_arrow_bg.png^[lowpart:" .. tostring(percent) ..
                       ":gui_furnace_arrow_fg.png^[transformR270]" .. "listring[current_name;dst]" ..
                       "listring[current_player;main]" .. "listring[current_name;src]" ..
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

function get_bottle(typename, items)
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
                run_length = 6 + c
                c = c + 1
            elseif stack:get_name() == 'vessels:steel_bottle' then
                -- skip over empty bottle..
            end
        end
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

-- check if enabled
ctg_airs.machine_enabled = function(meta)
    return meta:get_int("enabled") == 1
end

function ctg_airs.register_machine(data)
    local typename = data.typename
    local input_size = 1
    if typename == 'bottle' then
        input_size = 2
    end
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
        ctg_machine = 1
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

    local formspec = update_formspec(data, false, false, input_size)
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

        local machine_desc_tier = machine_desc:format(tier)
        local machine_node = data.modname .. ":" .. ltier .. "_" .. machine_name
        local machine_demand = data.demand

        -- Setup meta data if it does not exist.
        if not eu_input then
            meta:set_int(tier .. "_EU_demand", machine_demand[1])
            meta:set_int(tier .. "_EU_input", 0)
            return
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
                    if node_above.name == 'vacuum:atmos_thick' then
                        ctg_airs.play_hiss(pos)
                        ctg_airs.process_air(pos)
                        break
                    end
                end
            end

            if (not enabled) then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", S("%s Disabled"):format(machine_desc_tier))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                local formspec = update_formspec(data, false, enabled, input_size)
                meta:set_string("formspec", formspec .. form_buttons)
                return
            end

            if not vacuum.has_in_range(pos, "vacuum:atmos_thick", 1, 3) then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", S("%s Idle - No air nearby"):format(machine_desc_tier))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                local formspec = update_formspec(data, false, enabled, input_size)
                meta:set_string("formspec", formspec .. form_buttons)
                return
            end

            local result = get_bottle(typename, inv:get_list("src"))
            if not result then
                technic.swap_node(pos, machine_node)
                meta:set_string("infotext", S("%s Idle - No air bottles"):format(machine_desc_tier))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", 0)
                local formspec = update_formspec(data, false, enabled, input_size)
                meta:set_string("formspec", formspec .. form_buttons)
                return
            end

            if typename == "air_handler" then
                local power = air_power
                local valid, dest_pos, dir = ctg_airs.get_duct_output(pos)
                -- minetest.log(tostring(valid))
                if (valid > 0) then
                    local dest_node = minetest.get_node(dest_pos)
                    if (dest_node and dest_node.name == "ctg_airs:air_duct_vent") then
                        power = ctg_airs.process_vent(dest_pos, power)
                        -- minetest.log("vent")
                    elseif (dest_node and dest_node.name == "ctg_airs:air_duct_junc") then
                        power = ctg_airs.process_junc(dest_pos, dir, power)
                        -- minetest.log("junc")
                    elseif (dest_node and dest_node.name == "vacuum:vacuum") then
                        power = ctg_airs.process_leak(dest_pos, power)
                        -- minetest.log("vacuum")
                    elseif (dest_node and dest_node.name == "vacuum:atmos_thin") then
                        power = ctg_airs.process_leak(dest_pos, power)
                        -- minetest.log("thin atmos")
                    elseif (dest_node and dest_node.name == "vacuum:atmos_thick") then
                        power = ctg_airs.process_leak(dest_pos, power)
                        -- minetest.log("thick atmos")
                    end
                    -- minetest.log("power rem: " .. power)

                    if (power ~= air_power and math.random(0, 1) == 0) then
                        minetest.sound_play("air_vent_short", {
                            pos = pos,
                            gain = 0.15,
                            pitch = 0.7
                        })
                    end
                end
            end

            local item_percent = (math.floor(meta:get_int("src_time") / round(result.time * 100) * 100))
            local formspec = update_formspec2(data, true, enabled, input_size, item_percent)
            meta:set_string("formspec", formspec .. form_buttons)
            meta:set_int(tier .. "_EU_demand", machine_demand[EU_upgrade + 1])
            if (item_percent > 20) then
                technic.swap_node(pos, machine_node .. "_active")
            elseif (math.random(1, 3) > 1) then
                technic.swap_node(pos, machine_node .. "_wait")
            end
            meta:set_string("infotext", S("%s Active"):format(machine_desc_tier))
            if meta:get_int("src_time") < round(result.time * 100) then
                if not powered then
                    technic.swap_node(pos, machine_node)
                    meta:set_string("infotext", S("%s Unpowered"):format(machine_desc_tier))
                end
                return
            end
            -- technic.swap_node(pos, machine_node.."_wait")
            local output = result.output
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
                meta:set_string("infotext", S("%s Idle - Output full"):format(machine_desc_tier))
                meta:set_int(tier .. "_EU_demand", 0)
                meta:set_int("src_time", round(result.time * 100))
                return
            end
            meta:set_int("src_time", meta:get_int("src_time") - round(result.time * 100))
            inv:set_list("src", result.new_input)
            inv:set_list("dst", inv:get_list("dst_tmp"))

            if typename == 'bottle' and math.random(1, 5) > 3 then
                ctg_airs.play_hiss(pos)
            end
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
            local formspec = update_formspec(data, false, enabled, input_size)
            meta:set_string("formspec", formspec .. form_buttons)
        end
    })

    minetest.register_node(data.modname .. ":" .. ltier .. "_" .. machine_name .. "_active", {
        description = machine_desc:format(tier),
        tiles = {ltier .. "_" .. machine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_bottom.png" .. tube_entry_metal,
                 ltier .. "_" .. machine_name .. "_top.png", ltier .. "_" .. machine_name .. "_top.png",
                 ltier .. "_" .. machine_name .. "_side.png" .. tube_entry_metal, {
            image = ltier .. "_" .. machine_name .. "_active.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 32,
                aspect_h = 32,
                length = 1.25
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
            if fields.toggle then
                if meta:get_int("enabled") == 1 then
                    meta:set_int("enabled", 0)
                else
                    meta:set_int("enabled", 1)
                end
            end
            meta:set_string("formspec", formspec .. form_buttons)
        end
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
        end
    })

    technic.register_machine(tier, node_name, technic.receiver)
    technic.register_machine(tier, node_name .. "_wait", technic.receiver)
    technic.register_machine(tier, node_name .. "_active", technic.receiver)

end -- End registration
