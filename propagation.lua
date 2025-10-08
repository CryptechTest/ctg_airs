-- seed propagations from vents
minetest.register_abm({
    label = "thin atmos + vacuum -> atmos replacement",
    nodenames = {"vacuum:atmos_thin", "vacuum:vacuum"},
    neighbors = {"ctg_airs:air_duct_vent", "ctg_airs:air_duct_vent_lite"},
    interval = 5,
    chance = 3,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(2000, function(pos)
        if ctg_airs.near_active_vent(pos, 1) then
            minetest.set_node(pos, {
                name = "vacuum:atmos_thin"
            })
        end
    end)
})
