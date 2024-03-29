local S = minetest.get_translator(minetest.get_current_modname())

ctg_airs = {}

-- load files
local default_path = minetest.get_modpath("ctg_airs")

dofile(default_path .. DIR_DELIM .. "tubes.lua")
dofile(default_path .. DIR_DELIM .. "ducts.lua")
dofile(default_path .. DIR_DELIM .. "vents.lua")
dofile(default_path .. DIR_DELIM .. "nodes.lua")
dofile(default_path .. DIR_DELIM .. "functions.lua")
dofile(default_path .. DIR_DELIM .. "digilines.lua")
dofile(default_path .. DIR_DELIM .. "machine.lua")
dofile(default_path .. DIR_DELIM .. "fan.lua")
dofile(default_path .. DIR_DELIM .. "nature.lua")
dofile(default_path .. DIR_DELIM .. "crafts.lua")
dofile(default_path .. DIR_DELIM .. "propagation.lua")
dofile(default_path .. DIR_DELIM .. "plants.lua")

function ctg_airs.register_air_handler_machine(data)
    data.tube = 1
    data.connect_sides = {
        left = 1,
        right = 1,
        back = 1
    }
    data.machine_name = "air_handler"
    -- data.can_insert = true
    data.typename = "air_handler"
    data.machine_desc = "Air Handler Machine"
    ctg_airs.register_machine(data)
end

function ctg_airs.register_air_fan_machine(data)
    data.machine_name = "air_fan"
    -- data.can_insert = true
    data.typename = "air_fan"
    data.machine_desc = data.tier .. " Air Fan"
    ctg_airs.register_machine_fan(data)
end

function ctg_airs.register_air_handler_machine_admin(data)
    data.tube = 1
    data.connect_sides = {
        left = 1,
        right = 1,
        back = 1
    }
    data.machine_name = "air_handler_gen"
    -- data.can_insert = true
    data.typename = "air_handler_admin"
    data.machine_desc = "Air Admin Machine"
    ctg_airs.register_machine(data)
end

ctg_airs.register_air_handler_machine_admin({
    tier = "LV",
    demand = {0},
    speed = 1,
    power = 1000
})

ctg_airs.register_air_handler_machine({
    tier = "LV",
    demand = {1250},
    speed = 0.5,
    power = 128
})

ctg_airs.register_air_handler_machine({
    tier = "MV",
    demand = {2500},
    speed = 0.4,
    power = 280
})

ctg_airs.register_air_fan_machine({
    tier = "LV",
    demand = {500},
    speed = 1,
    power = 32
})

ctg_airs.register_air_fan_machine({
    tier = "MV",
    demand = {1200},
    speed = 0.8,
    power = 76
})
