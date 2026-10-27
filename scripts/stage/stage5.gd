extends StageDef
## STAGE 5 DEAD WORLD, the last stage: out of the enemy base and on across
## its planet's surface, a dead rock like the Moon or Mars. It opens in the
## base's exit shaft; the tunnel ends at a portal and the ship comes out over
## a plain of craters and boulders, the enemy's works on the mesas standing
## out of it, then down a rust-red canyon between stepped cliffs (bridges
## across it, outposts on its ledges) into the great crater where the
## mid-boss lies buried: GORGON, a fortress with two eyes. More fighters at
## a time than ever, and they fire three times as often (zako_fire 3).
## (Built up to the mid-boss so far: the stage ends there.)
##   (the exit shaft)      the base's last tunnel
##   AREA 1 CRATER PLAINS  craters, boulders, mesas with storehouses
##   AREA 2 RED RIFT       a canyon: bridges, outposts on the walls
##   (the crater)          GORGON


func _init() -> void:
	title = "STAGE 5"
	subtitle = "DEAD WORLD"
	boss = ""
	scroll = 16.0
	boss_scroll = 8.0
	zako_fire = 3
	zako_early = true
	first_area = "exit"
	title_area = "plains"
	layout_seed = 900
	areas = {
		"exit": {
			"sections": [["bridge", 16, 3, 2], ["hull", 6, 6, 2, "wall"], ["bridge", 16, 4, 2]],
			"gap": [9.0, 14.0],
		},
		"plains": {
			"label": ["AREA 1", "CRATER PLAINS"],
			"sections": [["mesa", 10, 7, 3], ["mesa", 7, 6, 2], ["mesa", 12, 8, 3], ["mesa", 8, 6, 2], ["mesa", 9, 6, 2]],
			"gap": [3.0, 7.0],
		},
		"rift": {
			"label": ["AREA 2", "RED RIFT"],
			"sections": [["bridge", 16, 3, 2], ["mesa", 8, 7, 2, "wall"], ["bridge", 16, 4, 3], ["mesa", 8, 7, 2], ["mesa", 9, 6, 3, "wall"]],
			"gap": [4.5, 9.0],
		},
		# the crater: bare (the fortress stops the scroll over itself, so
		# anything there would stay in front of it); its guns and shells
		# refill the homing lasers
		"basin": {},
	}
	backdrop = {
		"tunnel": {"styles": {"exit": "hangar", "plains": "regolith", "rift": "rift", "basin": "basin"}, "first": "hangar", "seed": 83},
	}


func build_waves(f: Formations) -> void:
	# build the stage's big models now, not the moment they first appear
	# (the surface's segments and GORGON's parts)
	for n: String in SurfaceModels.NAMES:
		Vox.get_mesh(n)
	# the exit shaft: fighters coming down it, guns on the gantries
	wave("exit", f.col(0.0, -0.75, 6, 0.16, 1) + f.col(0.5, 0.75, 6, 0.16, -1) + f.col(1.0, -0.55, 5, 0.16, 1) + f.col(1.5, 0.55, 5, 0.16, -1))
	wave("exit", f.kestrel(0.0, -1, -0.45) + f.kestrel(0.6, 1, 0.45) + f.vform(2.4, 1) + f.vform(2.9, -1), 14.0)
	# AREA 1: crater plains
	wave("plains", f.racers(0.0, "tl", 1, 8) + f.racers(1.2, "tr", 1, 8) + f.rammers(2.6, [0.0], 0.2), 14.0)
	wave("plains", f.grappler(0.0, -0.5) + f.grappler(0.8, 0.5) + f.sweep(2.0, 1, 7, 0.18) + f.sweep(2.4, -1, 7, 0.18), 14.0)
	wave("plains", f.chasers(0.0, 4, -1) + f.chasers(1.2, 4, 1) + f.pincer(2.6, 3) + f.swirls(3.6, -1, 5, 0.22), 11.0)
	wave("plains", f.bulwark(0.0, -0.45) + f.bulwark(0.8, 0.45) + f.col(2.0, -0.8, 6, 0.18, 1) + f.col(2.6, 0.8, 6, 0.18, -1), 15.0)
	wave("plains", f.swirls(0.0, -1, 6, 0.2) + f.swirls(0.5, 1, 6, 0.2) + f.vform(1.6, 1) + f.vform(2.1, -1) + f.rammers(3.0, [-0.4, 0.4], 0.3), 10.0)
	wave("plains", f.kestrel(0.0, -1, -0.4) + f.kestrel(1.0, 1, 0.4) + f.flankers(2.4, -1, 4) + f.flankers(3.6, 1, 4), 15.0)
	# AREA 2: the red rift
	wave("rift", f.col(0.0, -0.75, 6, 0.16, 1) + f.col(0.5, 0.75, 6, 0.16, -1) + f.vform(1.2, 1) + f.vform(1.7, -1) + f.vform(2.4, 1))
	wave("rift", f.grappler(0.0, -0.35) + f.kestrel(0.8, 1, 0.45) + f.racers(2.6, "tl", 1, 8), 15.0)
	wave("rift", f.chasers(0.0, 4, -1) + f.chasers(1.0, 4, 1) + f.pincer(2.2, 3) + f.rammers(3.4, [0.0], 0.2), 10.0)
	wave("rift", f.racers(0.0, "tr", 1, 8) + f.racers(1.0, "tl", 1, 8) + f.sweep(2.4, -1, 7, 0.18), 14.0)
	wave("rift", f.bulwark(0.0, 0.0) + f.kestrel(1.0, -1, -0.5) + f.kestrel(1.6, 1, 0.5) + f.swirls(3.2, -1, 5, 0.2) + f.swirls(3.6, 1, 5, 0.2), 16.0)
	wave("rift", f.sweep(0.0, -1, 7, 0.18) + f.sweep(0.4, 1, 7, 0.18) + f.chasers(1.6, 4) + f.vform(2.6, -1) + f.vform(3.0, 1), 10.0)
	# out of the canyon into the crater (its walls gone before the fortress
	# comes), then the buried fortress
	wave("basin", f.vform(0.0, -1) + f.vform(0.6, 1) + f.rammers(1.4, [-0.3, 0.3], 0.3), 7.0)
	wave("basin", [[0.0, "gorgon", {}]], 95.0, true)
