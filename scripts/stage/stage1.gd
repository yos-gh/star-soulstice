extends StageDef
## STAGE 1 ORBITAL FORTRESS: three areas of an orbital fortress, then the
## boss.
##   AREA 1 DEBRIS BELT  wreckage and asteroids around the fortress
##   AREA 2 OUTER HULL   armoured decks, trenches and solar arrays
##   (open space)        Lazaro
##   AREA 3 CORE BLOCK   dense machinery and reactors
##   STAR CORTEX         over the reactor field


func _init() -> void:
	title = "STAGE 1"
	subtitle = "ORBITAL FORTRESS"
	boss = "star_cortex"
	boss_warning = ["WARNING", "A HUGE ENERGY SOURCE IS APPROACHING"]
	first_area = "debris"
	title_area = "hull"
	areas = {
		"debris": {
			"label": ["AREA 1", "DEBRIS BELT"],
			"sections": [["fragment", 6, 4, 0], ["asteroid", 6, 5, 1], ["fragment", 8, 5, 1], ["asteroid", 9, 6, 1], ["fragment", 4, 4, 0]],
			"gap": [3.0, 10.0],
			# asteroids drift through on their own timer
			"stream": {"every": 1.3, "first": 1.0, "spawn": _rock},
		},
		"hull": {
			"label": ["AREA 2", "OUTER HULL"],
			"sections": [["hull", 15, 6, 2], ["trench", 16, 7, 2], ["hull", 13, 8, 3], ["solar", 14, 5, 0], ["trench", 14, 9, 3]],
			"gap": [0.5, 3.0],
		},
		"open": {
			"sections": [["solar", 12, 5, 0], ["fragment", 6, 4, 0], ["solar", 16, 4, 0]],
			"gap": [8.0, 16.0],
		},
		"core": {
			"label": ["AREA 3", "CORE BLOCK"],
			"sections": [["hull", 16, 7, 3], ["reactor", 10, 10, 3], ["trench", 17, 8, 3], ["hull", 14, 9, 3], ["reactor", 8, 8, 2]],
			"gap": [0.0, 2.0],
		},
		# islands keep coming during the boss (tiles refill energy), minus turrets
		"boss": {
			"sections": [["solar", 15, 5, 0], ["fragment", 7, 5, 0], ["solar", 12, 4, 0]],
			"gap": [10.0, 18.0],
		},
	}
	backdrop = {
		"nebula": {"y": -240.0, "size": 760.0},
		"planet": {"x": -70.0, "y": -150.0, "screen_y": 220.0, "radius": 30.0, "rotation": Vector3(0.45, 0.3, 0.25), "ring": 150.0},
		# [height, count, size]
		"stars": [[-18.0, 70, 0.16], [-45.0, 180, 0.26], [-110.0, 420, 0.42]],
		# colossal structure far below, blurred by depth of field
		"deep": {"y": -55.0, "meshes": ["deep_girder", "deep_block"], "count": 4},
	}


## A drifting asteroid chunk (a quarter of them big).
func _rock(g: Game) -> void:
	var big := randf() < 0.25
	g.spawn_enemy("rock", {"x": randf_range(-0.9, 0.9) * g.field_hw, "z": g.field_top - 2.5, "vx": randf_range(-1.2, 1.2), "vz": randf_range(2.5, 4.5) + Game.SCROLL * 0.3, "spin": randf_range(-1.2, 1.2), "big": big})


func build_waves(f: Formations) -> void:
	# AREA 1: debris belt
	wave("debris", f.col(0.5, -0.45, 6, 0.2, 1))
	wave("debris", f.col(0.0, 0.45, 6, 0.2, -1) + f.rammers(1.6, [-0.3], 0.2))
	wave("debris", f.swirls(0.0, -1, 5, 0.25) + f.swirls(1.2, 1, 5, 0.25), 8.0)
	wave("debris", f.vform(0.0, 0.0) + f.rammers(1.2, [-0.5, 0.5], 0.4) + f.vform(2.2, -0.4))
	# AREA 2: outer hull
	wave("hull", f.bulwark(0.0, 0.0) + f.col(2.0, -0.8, 4, 0.2, 1) + f.col(4.0, 0.8, 4, 0.2, -1), 12.0)
	wave("hull", f.sweep(0.0, -1, 6, 0.22) + f.sweep(1.0, 1, 6, 0.22))
	wave("hull", f.vform(0.0, -0.5) + f.vform(0.8, 0.5) + f.vform(1.6, 0.0))
	wave("hull", f.bulwark(0.0, -0.5) + f.bulwark(1.5, 0.5), 12.0)
	wave("hull", f.swirls(0.0, -1, 5, 0.22) + f.rammers(1.0, [-0.4, 0.4], 0.3) + f.swirls(1.5, 1, 5, 0.22), 8.0)
	# open space between the hull and the core: Lazaro
	wave("open", [[0.0, "lazaro", {}]], 60.0, true)
	# AREA 3: core block
	wave("core", f.col(0.0, -0.6, 5, 0.18, 1) + f.col(0.6, 0.6, 5, 0.18, -1) + f.col(1.2, -0.2, 5, 0.18, 1) + f.col(1.8, 0.2, 5, 0.18, -1))
	wave("core", f.bulwark(0.0, 0.0) + f.rammers(2.0, [-0.6, 0.6], 0.2) + f.rammers(4.0, [0.0], 0.2), 12.0)
	wave("core", f.vform(0.0, -0.6) + f.vform(0.5, 0.6) + f.vform(1.2, 0.0) + f.vform(2.0, -0.3) + f.vform(2.5, 0.3))
	wave("core", f.bulwark(0.0, -0.55) + f.bulwark(1.0, 0.55) + f.swirls(3.0, -1, 4, 0.25) + f.swirls(3.5, 1, 4, 0.25), 12.0)
	wave("core", f.sweep(0.0, -1, 8, 0.18) + f.sweep(0.4, 1, 8, 0.18) + f.col(1.5, 0.0, 6, 0.2, 1), 8.0)
