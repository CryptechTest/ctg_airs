local S = minetest.get_translator(minetest.get_current_modname())

local a = "ctg_world:aluminum_ingot"
local n = "ctg_world:nickel_ingot"
local tt = "ctg_world:titanium_ingot"
local p = "vacuum:airpump"
local t = "default:tin_ingot"
local g = "default:gold_ingot"
local m = "default:mese_crystal"
local d = "ctg_airs:air_duct_S"
local s = "default:steel_ingot"
local c = "ctg_machines:carbon_dust"
local b = "basic_materials:aluminum_bar"
local r = "basic_materials:aluminum_strip"
local i = "technic:machine_casing"
local l = "basic_materials:plastic_sheet"
local o = "basic_materials:motor"
local w = "scifi_nodes:white2"
local ev = "ship_parts:eviromental_sys"

local f = "ctg_airs:lv_air_fan"
local h = "ctg_airs:lv_air_handler"
local u = "pipeworks:tube_1"
local at = "ctg_airs:aluminum_block_embedded_tube"
local nt = "ctg_airs:nickel_block_embedded_tube"
local cl = "technic:control_logic_unit"
local sp = "basic_materials:empty_spool"

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
    recipe = {{a, t, a}, {r, r, r}, {a, t, a}}
})

minetest.register_craft({
    output = "ctg_airs:air_duct_vent 4",
    recipe = {{d, "", d}, {r, r, r}, {d, "", d}}
})

-- vent clean
minetest.register_craft({
    type = "shapeless",
    output = "ctg_airs:air_duct_vent 1",
    recipe = {"ctg_airs:air_duct_vent_dirty", "ctg_world:nickel_dust"}
})

-- vent lite
minetest.register_craft({
    output = "ctg_airs:air_duct_vent_lite 6",
    recipe = {{a, t, a}, {r, "", r}, {a, t, a}}
})

minetest.register_craft({
    output = "ctg_airs:air_duct_vent_lite 4",
    recipe = {{d, "", d}, {r, "", r}, {d, "", d}}
})

-- vent lite clean
minetest.register_craft({
    type = "shapeless",
    output = "ctg_airs:air_duct_vent_lite 1",
    recipe = {"ctg_airs:air_duct_vent_lite_dirty", "ctg_world:nickel_dust"}
})

-- machine
minetest.register_craft({
    output = "ctg_airs:lv_air_handler 1",
    recipe = {{a, a, a}, {o, p, o}, {"", o, ""}}
})

minetest.register_craft({
    output = "ctg_airs:mv_air_handler 1",
    recipe = {{tt, tt, tt}, {a, h, a}, {"", a, ""}}
})

-- fan
minetest.register_craft({
    output = "ctg_airs:lv_air_fan",
    recipe = {{t, o, t}, {r, b, r}, {l, i, l}}
})

minetest.register_craft({
    output = "ctg_airs:mv_air_fan",
    recipe = {{r, o, r}, {"", f, ""}, {"", tt, ""}}
})

-- purifier
minetest.register_craft({
    output = "ctg_airs:lv_air_purifier",
    recipe = {{tt, ev, tt}, {cl, d, cl}, {l, f, l}}
})

-- air filter
minetest.register_craft({
    output = "ctg_airs:air_filter_basic 5",
    recipe = {{c, c, c}, {c, c, c}, {r, nt, r}}
})

-- airtight tube wall

minetest.register_craft({
    output = "ctg_airs:aluminum_block_embedded_tube",
    recipe = {{"", "", ""}, {"", u, ""}, {"", "ctg_world:aluminum_block", ""}}
})

minetest.register_craft({
    output = "ctg_airs:nickel_block_embedded_tube",
    recipe = {{"", "", ""}, {"", u, ""}, {"", "ctg_world:nickel_block", ""}}
})

minetest.register_craft({
    output = "ctg_airs:stainless_steel_block_embedded_tube",
    recipe = {{"", "", ""}, {"", u, ""}, {"", "technic:stainless_steel_block", ""}}
})

minetest.register_craft({
    output = "ctg_airs:plastic_block_embedded_tube",
    recipe = {{"", "", ""}, {"", u, ""}, {"", w, ""}}
})