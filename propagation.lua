-- thick atmos propagation base
-- seed propagations from vents
minetest.register_abm({
    label = "thin atmos + vacuum -> atmos replacement",
    nodenames = {"vacuum:atmos_thin", "vacuum:vacuum"},
    neighbors = {"ctg_airs:air_duct_vent"},
    interval = 5,
    chance = 2,
    min_y = vacuum.space_height,
    action = vacuum.throttle(100, function(pos)
        if vacuum.has_in_range(pos, "vacuum:atmos_thin", 1, 5) and ctg_airs.near_active_vent(pos, 3) then
            minetest.set_node(pos, {
                name = "vacuum:atmos_thick"
            })
        elseif ctg_airs.near_active_vent(pos, 1) then
            minetest.set_node(pos, {
                name = "vacuum:atmos_thin"
            })
        end
    end)
})
