
minetest.register_craftitem("ctg_airs:air_filter_basic", {
	description = S("Basic Air Filter"),
	inventory_image = "ctg_air_filter.png",
    wield_scale = {x = 0.9, y = 0.9, z = 0.9},
	stack_max = 10,
})

minetest.register_craftitem("ctg_airs:air_filter_basic_dirty", {
	description = S("Dirty Basic Air Filter"),
	inventory_image = "ctg_air_filter_dirty.png",
    wield_scale = {x = 0.9, y = 0.9, z = 0.9},
	stack_max = 10,
	groups = {not_in_creative_inventory = 1},
})