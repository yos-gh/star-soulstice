extends StageDef
## STAGE 3 ASTEROID BELT: out through the belt beyond the fortress, where
## the mining machines work the rocks. Rocks drift through all the way:
## from above and in from the sides, and from AREA 2 on giant ones, walls
## that stop enemy bullets and shove the ship aside (giant_rock.gd). From
## this stage on the small fighters and turrets fire twice as often, and
## the slow ones start sooner (zako_fire / zako_early).
##   AREA 1 DRIFT FIELD   scattered asteroids, rocks drifting in
##   AREA 2 QUARRY ROCKS  strip-mined asteroids; giant rocks drift through
##   (the cleft)          LODESTAR
##   AREA 3 CRUSH ZONE    crowded quarries, rocks, two giant rocks at a time
##   TITAN DREDGE         dug into a giant asteroid

## the stream's count (every few rocks a giant one)
var drift_n := 0


func _init() -> void:
	title = "STAGE 3"
	subtitle = "ASTEROID BELT"
	boss = "titan_dredge"
	boss_warning = ["WARNING", "A COLOSSAL DREDGE IS MINING THE BELT AHEAD"]
	scroll = 15.0
	boss_scroll = 8.0
	zako_fire = 2
	zako_early = true
	first_area = "drift"
	title_area = "drift"
	layout_seed = 500
	areas = {
		"drift": {
			"label": ["AREA 1", "DRIFT FIELD"],
			"sections": [["asteroid", 8, 6, 1], ["fragment", 7, 5, 0], ["asteroid", 10, 7, 1], ["quarry", 11, 8, 2], ["asteroid", 7, 6, 0]],
			"gap": [1.5, 5.0],
			"stream": {"every": 1.2, "first": 1.0, "spawn": _drift},
		},
		"quarry": {
			"label": ["AREA 2", "QUARRY ROCKS"],
			"sections": [["quarry", 12, 9, 2], ["asteroid", 7, 6, 1], ["quarry", 10, 8, 2], ["solar", 12, 4, 0], ["asteroid", 9, 7, 2]],
			"gap": [2.0, 6.0],
			"stream": {"every": 1.4, "first": 0.5, "spawn": _quarry},
		},
		"cleft": {
			"sections": [["asteroid", 8, 6, 0], ["fragment", 7, 5, 0], ["quarry", 10, 7, 0]],
			"gap": [4.0, 9.0],
			"stream": {"every": 2.6, "first": 2.0, "spawn": _cleft},
		},
		"crush": {
			"label": ["AREA 3", "CRUSH ZONE"],
			"sections": [["quarry", 13, 10, 3], ["asteroid", 10, 8, 2], ["quarry", 11, 9, 3], ["asteroid", 8, 6, 2], ["fragment", 7, 5, 1]],
			"gap": [1.0, 4.0],
			"stream": {"every": 1.1, "first": 0.5, "spawn": _crush},
		},
		# rocks keep coming during the boss (tiles refill energy), minus turrets
		"boss": {
			"sections": [["asteroid", 8, 6, 0], ["fragment", 7, 5, 0], ["quarry", 10, 7, 0]],
			"gap": [6.0, 11.0],
		},
	}
	backdrop = {
		"nebula": {"y": -240.0, "size": 760.0},
		# the gas giant the belt goes round
		"planet": {"x": 95.0, "y": -180.0, "screen_y": 150.0, "radius": 46.0, "rotation": Vector3(0.35, 0.2, -0.4), "ring": 0.0},
		"stars": [[-45.0, 160, 0.26], [-110.0, 400, 0.42]],
		# the belt's rocks tumbling below the ground, and huge ones far down
		"rocks": {"y": [-16.0, -40.0], "count": 14, "meshes": ["belt_rock_a", "belt_rock_b", "belt_rock_c"], "size": [0.5, 1.0], "seed": 31},
		"deep": {"y": -64.0, "meshes": ["deep_rock_a", "deep_rock_b"], "count": 4},
	}


## AREA 1: rocks from above, some in from the sides.
func _drift(g: Game) -> void:
	_rock(g, 0.35)


## AREA 2: every fifth a giant rock, one at a time.
func _quarry(g: Game) -> void:
	drift_n += 1
	if drift_n % 5 == 0 and _giants(g) < 1:
		_giant(g)
	else:
		_rock(g, 0.3)


## The cleft (the mid-boss): a few.
func _cleft(g: Game) -> void:
	_rock(g, 0.2)


## AREA 3: every fourth a giant rock, two at a time.
func _crush(g: Game) -> void:
	drift_n += 1
	if drift_n % 4 == 0 and _giants(g) < 2:
		_giant(g)
	else:
		_rock(g, 0.4)


## A drifting rock (a quarter of them big): from above, or (`side` of the
## time) in from a side edge in the upper half, slowly across and down.
func _rock(g: Game, side: float) -> void:
	var big := randf() < 0.25
	var spin := randf_range(-1.2, 1.2)
	if randf() < side:
		var s := -1.0 if randf() < 0.5 else 1.0
		var z := randf_range(g.field_top + 1.0, g.field_top + 9.0)
		g.spawn_enemy("rock", {"x": s * (g.half_width_at(z) + 2.0), "z": z, "vx": -s * randf_range(3.5, 5.5), "vz": randf_range(3.5, 5.5), "spin": spin, "big": big})
	else:
		g.spawn_enemy("rock", {"x": randf_range(-0.9, 0.9) * g.field_hw, "z": g.field_top - 2.5, "vx": randf_range(-1.2, 1.2), "vz": randf_range(2.5, 4.5) + Game.SCROLL * 0.3, "spin": spin, "big": big})


## A giant rock from above, drifting slowly down toward the middle.
func _giant(g: Game) -> void:
	var xn := randf_range(-0.6, 0.6)
	g.spawn_enemy("giant_rock", {"x": xn * g.field_hw, "vx": -xn * randf_range(0.3, 0.9), "vz": randf_range(3.6, 4.8), "spin": randf_range(-0.15, 0.15), "turn": randf() * TAU, "big": randf() < 0.35})


func _giants(g: Game) -> int:
	var c := 0
	for e in g.enemies:
		if e.kind == "giant_rock" and not e.dead:
			c += 1
	return c


func build_waves(f: Formations) -> void:
	# build the stage's big models now, not the moment they first appear
	for n: String in ["giant_rock_a", "giant_rock_b", "grappler", "grappler_claw", "lode_hull", "lode_core", "lode_pylon", "dredge_hull", "dredge_core", "dredge_wheel", "dredge_boom", "dredge_jib", "dredge_driver"]:
		Vox.get_mesh(n)
	# AREA 1: drift field
	wave("drift", f.col(0.0, -0.75, 6, 0.18, 1) + f.col(0.8, 0.75, 6, 0.18, -1))
	wave("drift", f.vform(0.0, 1) + f.vform(0.6, -1) + f.rammers(1.4, [0.0], 0.2))
	# the mining tug, its boulder held up as a shield; fighters sweep in
	wave("drift", f.grappler(0.0, -0.4) + f.sweep(1.8, 1, 6, 0.2) + f.sweep(4.8, -1, 6, 0.2), 13.0)
	wave("drift", f.racers(0.0, "tr", 1, 8), 12.0)
	wave("drift", f.swirls(0.0, -1, 5, 0.22) + f.swirls(0.6, 1, 5, 0.22), 8.0)
	wave("drift", f.chasers(0.0, 3) + f.flankers(1.6, -1, 3), 8.0)
	# AREA 2: quarry rocks (giant rocks drift through)
	wave("quarry", f.grappler(0.0, -0.55) + f.grappler(1.2, 0.55) + f.vform(4.0, 1) + f.vform(4.7, -1), 14.0)
	wave("quarry", f.pincer(0.0, 2) + f.vform(1.0, -1) + f.vform(1.6, 1), 8.0)
	wave("quarry", f.bulwark(0.0, 0.0) + f.col(2.0, -0.8, 4, 0.2, 1) + f.col(4.0, 0.8, 4, 0.2, -1), 12.0)
	wave("quarry", f.racers(0.0, "tl", 1, 8) + f.racers(1.5, "tr", 1, 8), 14.0)
	wave("quarry", f.sweep(0.0, -1, 6, 0.2) + f.sweep(0.5, 1, 6, 0.2) + f.rammers(1.6, [-0.4, 0.4], 0.3), 8.0)
	wave("quarry", f.grappler(0.0, 0.35) + f.swirls(1.0, -1, 5, 0.22) + f.chasers(3.5, 3, -1), 13.0)
	# the cleft between the rocks: the ore-catcher
	wave("cleft", [[0.0, "lodestar", {}]], 60.0, true)
	# AREA 3: crush zone
	wave("crush", f.col(0.0, -0.75, 5, 0.18, 1) + f.col(0.6, 0.75, 5, 0.18, -1) + f.col(1.2, -0.55, 5, 0.18, 1) + f.col(1.8, 0.55, 5, 0.18, -1))
	wave("crush", f.grappler(0.0, -0.3) + f.bulwark(1.0, 0.45) + f.rammers(3.0, [-0.4], 0.2), 13.0)
	wave("crush", f.chasers(0.0, 3, -1) + f.chasers(1.4, 3, 1) + f.pincer(3.0, 2), 9.0)
	wave("crush", f.vform(0.0, -1) + f.vform(0.5, 1) + f.vform(1.2, -1) + f.vform(2.0, 1) + f.vform(2.5, -1))
	wave("crush", f.grappler(0.0, -0.55) + f.grappler(0.6, 0.55) + f.racers(2.5, "tl", 1, 8), 15.0)
	wave("crush", f.racers(0.0, "tr", 1, 8) + f.rammers(1.0, [-0.5, 0.5], 0.4) + f.sweep(2.0, -1, 6, 0.2), 12.0)
