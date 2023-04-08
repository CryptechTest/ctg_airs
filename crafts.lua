local S = minetest.get_translator(minetest.get_current_modname())

local a = "ctg_world:aluminum_ingot"
local n = "ctg_world:nickel_ingot"
local p = "vacuum:airpump"
local t = "default:tin_ingot"
local m = "default:mese_crystal"
local d = "ctg_airs:air_duct_S"
local s = "default:steel_ingot"
local c = "ctg_machines:carbon_dust"
local b = "basic_materials:aluminum_bar"
local r = "basic_materials:aluminum_strip"
local i = "technic:machine_casing"
local l = "basic_materials:plastic_sheet"

local h = "ctg_airs:lv_air_handler"
local u = "pipeworks:tube_1"
local at = "ctg_airs:aluminum_block_embedded_tube"
local nt = "ctg_airs:nickel_block_embedded_tube"

-- ducts
minetest.register_craft({
    output = "ctg_airs:air_duct_S 8",
    recipe = {{a, t, a}, {t, "", t}, {a, t, a}}
})

-- junction
minetest.register_craft({
    output = "ctg_airs:air_duct_junc 4",
    recipe = {{a, t, a}, {t, m, t}, {a, t, a}}
})

minetest.register_craft({
    output = "ctg_airs:air_duct_junc 4",
    recipe = {{d, "", d}, {"", m, ""}, {d, "", d}}
})

-- vent
minetest.register_craft({
    output = "ctg_airs:air_duct_vent 6",
    recipe = {{a, t, a}, {t, s, t}, {a, t, a}}
})

minetest.register_craft({
    output = "ctg_airs:air_duct_vent 4",
    recipe = {{d, "", d}, {"", s, ""}, {d, "", d}}
})

-- machine
minetest.register_craft({
    output = "ctg_airs:lv_air_handler 1",
    recipe = {{"", a, ""}, {"", p, ""}, {"", t, ""}}
})

minetest.register_craft({
    output = "ctg_airs:mv_air_handler 1",
    recipe = {{"", a, ""}, {c, h, c}, {"", a, ""}}
})

-- air tight tubes
minetest.register_craft({
    output = "ctg_airs:aluminum_block_embedded_tube 1",
    recipe = {{a, a, a}, {a, u, a}, {a, a, a}}
})

-- minetest.register_craft({
--    output = "ctg_airs:nickel_block_embedded_tube 1",
--    recipe = {{n, n, n}, {n, u, n}, {n, n, n}}
-- })

-- fan
minetest.register_craft({
    output = "ctg_airs:lv_air_fan",
    recipe = {{t, r, t}, {r, b, r}, {l, i, l}}
})
