extends StageDef
## STAGE 4 PLANETFALL: down from orbit into the enemy's home world and on
## into its base. The first half dives through the atmosphere (the sky
## backdrop: space gives way to the haze and a sea of cloud tops far below,
## cloud banks rise past, the deck breaks up over the dark surface) over
## floating sky platforms; the mid-boss guards the way in, and with it gone
## the base's face comes up and the stage flies into its hangar shaft, down
## through the deep levels to the boss in the arena at the bottom. Denser
## than stage 3: more fighters at a time, more guns on the ground.
##   AREA 1 UPPER ATMOSPHERE  sky platforms, the haze thickening
##   AREA 2 STORM LAYER       through the cloud deck
##   (the approach)           TEMPEST
##   AREA 3 HANGAR SHAFT      inside the base: gantries and decks
##   AREA 4 CORE ACCESS       the deep levels
##   BEHEMOTH                 in the arena at the bottom


func _init() -> void:
	title = "STAGE 4"
	subtitle = "PLANETFALL"
	boss = "behemoth"
	boss_warning = ["WARNING", "A SIEGE ENGINE IS ROLLING OUT OF THE ARENA"]
	scroll = 16.0
	boss_scroll = 8.0
	zako_fire = 2
	zako_early = true
	first_area = "entry"
	title_area = "entry"
	layout_seed = 700
	areas = {
		"entry": {
			"label": ["AREA 1", "UPPER ATMOSPHERE"],
			"sections": [["aerostat", 9, 6, 2], ["solar", 10, 4, 0], ["aerostat", 10, 6, 2], ["hull", 7, 5, 1], ["aerostat", 8, 5, 1]],
			"gap": [5.5, 11.0],
		},
		"storm": {
			"label": ["AREA 2", "STORM LAYER"],
			"sections": [["aerostat", 11, 7, 3], ["reactor", 8, 8, 2], ["aerostat", 9, 6, 2], ["trench", 10, 6, 2], ["aerostat", 8, 6, 2]],
			"gap": [5.0, 10.0],
		},
		"gate": {
			"sections": [["aerostat", 8, 6, 0], ["solar", 10, 4, 0]],
			"gap": [10.0, 16.0],
		},
		"hangar": {
			"label": ["AREA 3", "HANGAR SHAFT"],
			"sections": [["bridge", 16, 3, 1], ["hull", 6, 6, 2, "wall"], ["bridge", 16, 4, 2], ["reactor", 8, 8, 1], ["hull", 7, 5, 2, "wall"]],
			"gap": [9.0, 15.0],
		},
		"core": {
			"label": ["AREA 4", "CORE ACCESS"],
			"sections": [["trench", 12, 7, 3], ["bridge", 16, 4, 2], ["reactor", 9, 9, 2], ["hull", 7, 7, 3, "wall"], ["bridge", 16, 3, 2]],
			"gap": [10.0, 15.0],
		},
		# the arena: its deck lies where the sections would be
		"boss": {},
	}
	backdrop = {
		"nebula": {"y": -240.0, "size": 760.0},
		"stars": [[-110.0, 420, 0.42], [-170.0, 300, 0.5]],
		"sky": {
			"y": -62.0, "size": 900.0, "rate": 0.018, "rates": {"gate": 0.05},
			"from": {"entry": 0.0, "storm": 0.62, "gate": 1.08},
			"to": {"entry": 0.62, "storm": 1.08, "gate": 1.4},
			"clouds": {"count": 14, "meshes": ["cloud_a", "cloud_b", "cloud_c"], "far": [-50.0, -60.0], "near": [-18.0, -34.0], "seed": 41},
		},
		"tunnel": {"styles": {"entry": "open", "storm": "open", "gate": "open", "hangar": "hangar", "core": "core", "boss": "arena"}, "first": "open", "seed": 61},
	}


func build_waves(f: Formations) -> void:
	# build the stage's big models now, not the moment they first appear
	for n: String in ["cloud_a", "cloud_b", "cloud_c", "kestrel", "tempest_hull", "tempest_core", "tempest_coil", "tempest_rotor", "tunnel_facade", "behemoth_hull", "behemoth_turret", "behemoth_tread", "behemoth_core"]:
		Vox.get_mesh(n)
	# AREA 1: upper atmosphere (more at a time than stage 3 from the start)
	wave("entry", f.col(0.0, -0.75, 6, 0.18, 1) + f.col(0.8, 0.75, 6, 0.18, -1) + f.vform(1.8, 1))
	# the gunship banks in from the left; fighters sweep in behind it
	wave("entry", f.kestrel(0.0, -1, -0.35) + f.sweep(1.6, 1, 6, 0.2) + f.sweep(4.4, -1, 6, 0.2), 13.0)
	wave("entry", f.swirls(0.0, -1, 5, 0.22) + f.swirls(0.6, 1, 5, 0.22) + f.rammers(1.8, [0.0], 0.2), 8.0)
	wave("entry", f.chasers(0.0, 3) + f.flankers(1.6, -1, 3) + f.flankers(3.0, 1, 3), 9.0)
	wave("entry", f.kestrel(0.0, 1, 0.4) + f.bulwark(1.0, -0.45) + f.col(3.5, 0.8, 5, 0.2, -1), 14.0)
	# AREA 2: storm layer: two gunships at once
	wave("storm", f.kestrel(0.0, -1, -0.45) + f.kestrel(1.2, 1, 0.45) + f.vform(4.0, 1) + f.vform(4.6, -1), 15.0)
	wave("storm", f.pincer(0.0, 2) + f.vform(1.0, -1) + f.vform(1.6, 1) + f.rammers(2.6, [0.0], 0.2), 8.0)
	wave("storm", f.racers(0.0, "tl", 1, 8) + f.racers(1.5, "tr", 1, 8), 14.0)
	wave("storm", f.bulwark(0.0, 0.0) + f.col(2.0, -0.8, 5, 0.2, 1) + f.col(3.0, 0.8, 5, 0.2, -1) + f.chasers(5.0, 3), 13.0)
	wave("storm", f.sweep(0.0, -1, 6, 0.2) + f.sweep(0.5, 1, 6, 0.2) + f.rammers(1.6, [-0.4, 0.4], 0.3) + f.swirls(2.6, -1, 5, 0.22), 9.0)
	# the approach to the base: the storm station guards the way in
	wave("gate", [[0.0, "tempest", {}]], 60.0, true)
	# AREA 3: hangar shaft (the rail carriages of the foundry guard it too)
	wave("hangar", f.col(0.0, -0.75, 5, 0.18, 1) + f.col(0.6, 0.75, 5, 0.18, -1) + f.col(1.2, -0.55, 5, 0.18, 1) + f.col(1.8, 0.55, 5, 0.18, -1) + f.vform(2.6, 1))
	wave("hangar", f.railjack(0.0, -1) + f.kestrel(0.8, 1, 0.35) + f.rammers(3.0, [-0.4], 0.2), 14.0)
	wave("hangar", f.chasers(0.0, 3, -1) + f.chasers(1.4, 3, 1) + f.pincer(3.0, 2), 9.0)
	wave("hangar", f.railjack(0.0, 1) + f.railjack(0.6, -1) + f.racers(2.5, "tl", 1, 8), 14.0)
	# AREA 4: core access
	wave("core", f.kestrel(0.0, -1, -0.45) + f.kestrel(0.8, 1, 0.45) + f.rammers(2.5, [0.0], 0.2), 15.0)
	wave("core", f.racers(0.0, "tr", 1, 8) + f.rammers(1.0, [-0.5, 0.5], 0.4) + f.sweep(2.0, -1, 6, 0.2), 12.0)
	wave("core", f.chasers(0.0, 3, -1) + f.chasers(1.4, 3, 1) + f.flankers(3.0, -1, 3) + f.swirls(4.0, 1, 5, 0.22), 10.0)
	wave("core", f.railjack(0.0, -1) + f.railjack(0.6, 1) + f.col(2.0, -0.75, 5, 0.18, 1) + f.col(2.6, 0.75, 5, 0.18, -1), 13.0)
