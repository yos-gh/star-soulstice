extends StageDef
## STAGE 2 ARMS FOUNDRY: down the supply tunnels of the fortress's arms
## foundry at full speed (a close, fast-scrolling tunnel), to the press at
## the end of the line.
##   AREA 1 INTAKE DUCT    cold steel duct: gantries across, decks on the walls
##   AREA 2 ASSEMBLY LINE  conveyor floor, assembly arms on the walls
##   (transfer hall)       OUROBOROS
##   AREA 3 FURNACE ROW    molten channels, crucible platforms
##   VULCAN PRESS          at the end of the furnace row


func _init() -> void:
	title = "STAGE 2"
	subtitle = "ARMS FOUNDRY"
	boss = "vulcan_press"
	boss_warning = ["WARNING", "THE FOUNDRY PRESS IS COMING DOWN THE LINE"]
	scroll = 18.0
	boss_scroll = 10.0
	first_area = "duct"
	title_area = "duct"
	layout_seed = 300
	areas = {
		"duct": {
			"label": ["AREA 1", "INTAKE DUCT"],
			"sections": [["bridge", 16, 3, 1], ["hull", 6, 5, 2, "wall"], ["bridge", 16, 4, 0], ["solar", 10, 5, 0], ["hull", 7, 4, 1, "wall"]],
			"gap": [14.0, 22.0],
		},
		"line": {
			"label": ["AREA 2", "ASSEMBLY LINE"],
			"sections": [["trench", 12, 6, 2], ["bridge", 16, 3, 2], ["hull", 6, 7, 2, "wall"], ["solar", 12, 4, 0], ["bridge", 16, 5, 1]],
			"gap": [10.0, 16.0],
		},
		"hall": {
			"sections": [["bridge", 16, 3, 0], ["solar", 10, 4, 0]],
			"gap": [18.0, 26.0],
		},
		"furnace": {
			"label": ["AREA 3", "FURNACE ROW"],
			"sections": [["reactor", 9, 9, 2], ["bridge", 16, 4, 2], ["hull", 7, 6, 2, "wall"], ["reactor", 8, 8, 2], ["trench", 13, 7, 3]],
			"gap": [9.0, 14.0],
		},
		"boss": {
			"sections": [["bridge", 16, 3, 0], ["solar", 12, 4, 0]],
			"gap": [26.0, 36.0],
		},
	}
	backdrop = {
		"tunnel": {"styles": {"duct": "duct", "line": "line", "hall": "line", "furnace": "furnace", "boss": "furnace"}, "first": "duct", "seed": 21},
	}


func build_waves(f: Formations) -> void:
	# AREA 1: intake duct
	wave("duct", f.col(0.0, -0.75, 6, 0.18, 1) + f.col(0.8, 0.75, 6, 0.18, -1))
	wave("duct", f.vform(0.0, 1) + f.vform(0.6, -1) + f.rammers(1.4, [0.0], 0.2))
	# the rail carriage comes down one wall; fighters sweep in from the other
	wave("duct", f.railjack(0.0, -1) + f.sweep(1.5, 1, 6, 0.2) + f.sweep(4.5, 1, 6, 0.2), 12.0)
	wave("duct", f.racers(0.0, "tr", 1, 8), 12.0)
	wave("duct", f.swirls(0.0, -1, 5, 0.22) + f.swirls(0.6, 1, 5, 0.22), 8.0)
	wave("duct", f.chasers(0.0, 3) + f.flankers(1.6, 1, 3), 8.0)
	# AREA 2: assembly line
	# a carriage on each wall: their rakes cross
	wave("line", f.railjack(0.0, -1) + f.railjack(1.0, 1) + f.vform(3.5, 1) + f.vform(4.2, -1), 13.0)
	wave("line", f.pincer(0.0, 2) + f.vform(1.0, -1) + f.vform(1.6, 1), 8.0)
	wave("line", f.bulwark(0.0, 0.0) + f.col(2.0, -0.8, 4, 0.2, 1) + f.col(4.0, 0.8, 4, 0.2, -1), 12.0)
	wave("line", f.racers(0.0, "tl", 1, 8) + f.racers(1.5, "tr", 1, 8), 14.0)
	wave("line", f.sweep(0.0, -1, 6, 0.2) + f.sweep(0.5, 1, 6, 0.2) + f.rammers(1.6, [-0.4, 0.4], 0.3), 8.0)
	wave("line", f.railjack(0.0, 1) + f.swirls(1.0, -1, 5, 0.22) + f.chasers(3.5, 3, -1), 12.0)
	# the transfer hall: the freight train
	wave("hall", [[0.0, "ouroboros", {}]], 60.0, true)
	# AREA 3: furnace row
	wave("furnace", f.col(0.0, -0.75, 5, 0.18, 1) + f.col(0.6, 0.75, 5, 0.18, -1) + f.col(1.2, -0.55, 5, 0.18, 1) + f.col(1.8, 0.55, 5, 0.18, -1))
	wave("furnace", f.railjack(0.0, 1) + f.bulwark(0.8, -0.35) + f.rammers(3.0, [0.4], 0.2), 13.0)
	wave("furnace", f.chasers(0.0, 3, -1) + f.chasers(1.4, 3, 1) + f.pincer(3.0, 2), 9.0)
	wave("furnace", f.vform(0.0, -1) + f.vform(0.5, 1) + f.vform(1.2, -1) + f.vform(2.0, 1) + f.vform(2.5, -1))
	wave("furnace", f.railjack(0.0, -1) + f.railjack(0.6, 1) + f.racers(2.5, "tl", 1, 8), 14.0)
	wave("furnace", f.racers(0.0, "tr", 1, 8) + f.rammers(1.0, [-0.5, 0.5], 0.4) + f.sweep(2.0, -1, 6, 0.2), 12.0)
