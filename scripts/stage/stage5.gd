extends StageDef
## STAGE 5 DEAD WORLD, the last stage: out of the enemy base and on across
## its planet's surface, a dead rock like the Moon or Mars, then up off it
## into orbit. It opens in the base's exit shaft; the tunnel ends at a
## portal and the ship comes out over a plain of craters and boulders, the
## enemy's works on the mesas standing out of it, then down a rust-red
## canyon between stepped cliffs (bridges across it, outposts on its
## ledges) into the great crater where the mid-boss lies: GORGON, a fortress
## with two eyes. Past it the crater floor breaks off and the ship climbs
## away: the planet falls away under it (Backdrop globe), its limb comes in
## at the top and passes down and out at the bottom, space beyond. Up there
## the defence grid waits: orbital weapons parked across the way (satellite:
## rotary guns, laser lances) set to close the ship in, rocks drifting
## among them to hide behind; then fast waves with the satellites mixed in.
## More fighters at a time than ever, and they fire three times as often
## (zako_fire 3). Two bosses: as the first one's last blast goes off, space
## bends into warp (Backdrop warp) and the core itself comes for the ship.
##   (the exit shaft)      the base's last tunnel
##   AREA 1 CRATER PLAINS  craters, boulders, mesas with storehouses
##   AREA 2 RED RIFT       a canyon: bridges, outposts on the walls
##   (the crater)          GORGON
##   AREA 3 HIGH ORBIT     the climb: satellites in groups, rocks for cover
##   AREA 4 DEFENSE GRID   fast waves with satellites, no rocks
##   OMEGA CORTEX          the first of the last stage's two bosses
##   (warp space)          STAR SOUL, the core grown into a crystal: the last boss

## the meteor stream's count (every other one a giant rock)
var drift_n := 0


func _init() -> void:
	title = "STAGE 5"
	subtitle = "DEAD WORLD"
	boss = "omega_cortex"
	boss_warning = ["WARNING", "THE STAR CORTEX REBUILT AND ARMED: OMEGA"]
	boss2 = "star_soul"
	boss2_area = "core"
	boss2_warning = ["WARNING", "THE CORE, CRYSTALLIZED: STAR SOUL"]
	clear_note = "ALL STAGES CLEAR"
	# the whole stage with both bosses: a good run still earns some
	bonus_t = 330.0
	scroll = 16.0
	boss_scroll = 8.0
	zako_fire = 3
	zako_early = true
	first_area = "exit"
	title_area = "plains"
	layout_seed = 900
	areas = {
		"exit": {
			"sections": [["bridge", 16, 3, 2]],
			"gap": [6.0, 9.0],
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
		# up off the planet: slow (the satellites drift with the scroll and
		# need the time on screen to turn their beams), wreckage and solar arrays in orbit, rocks
		# drifting through (cover from the satellites); its first section
		# once the ground has broken off
		"ascent": {
			"label": ["AREA 3", "HIGH ORBIT"],
			"scroll": 7.5,
			"sections": [["fragment", 7, 5, 0], ["solar", 10, 4, 1], ["fragment", 8, 6, 1], ["hull", 7, 5, 1]],
			"gap": [3.0, 7.0], "lead": 22.0,
			"stream": {"every": 3.0, "first": 5.0, "spawn": _meteor},
		},
		"orbit": {
			"label": ["AREA 4", "DEFENSE GRID"],
			"scroll": 17.0,
			"sections": [["hull", 8, 6, 2], ["reactor", 8, 8, 2], ["trench", 10, 6, 2], ["solar", 12, 4, 1], ["hull", 7, 5, 2]],
			"gap": [6.0, 11.0],
		},
		# the boss in orbit: wreckage drifting by (tiles refill the homing
		# lasers), no guns on it
		"boss": {
			"sections": [["fragment", 7, 5, 0], ["hull", 6, 5, 0], ["solar", 9, 4, 0]],
			"gap": [5.0, 10.0],
		},
		# the last boss in warp space: nothing drifts there (the wreckage
		# left from the first fight rushes off); the crystal sheds energy as it
		# is hurt, which feeds the homing lasers
		"core": {},
	}
	backdrop = {
		# space, under the ground and the planet until the climb
		"nebula": {"y": -240.0, "size": 760.0},
		"stars": [[-120.0, 420, 0.42], [-175.0, 300, 0.5]],
		"globe": {"radius": 120.0, "top": [16.0, 34.0], "shift": 150.0, "rate": 0.06,
			"from": {"ascent": 0.0, "orbit": 1.0, "boss": 1.0, "core": 1.0}, "to": {"ascent": 1.0, "orbit": 1.0, "boss": 1.0, "core": 1.0}},
		# warp space, from OMEGA CORTEX's last blast on
		"warp": {"y": -200.0, "rate": 0.45, "speed": 260.0, "from": {"core": 1.0}, "to": {"core": 1.0},
			"streaks": [[-70.0, 70, 0.32], [-110.0, 110, 0.42], [-160.0, 150, 0.55]]},
		"tunnel": {"styles": {"exit": "hangar", "plains": "regolith", "rift": "rift", "basin": "basin", "ascent": "open", "orbit": "open", "boss": "open", "core": "open"}, "first": "hangar", "seed": 83},
	}


## AREA 3's rocks: every other one a giant rock (two at most), drifting
## slowly down the middle (cover), else a small rock from above.
func _meteor(g: Game) -> void:
	drift_n += 1
	if drift_n % 2 == 1 and _giants(g) < 2:
		var xn := randf_range(-0.55, 0.55)
		g.spawn_enemy("giant_rock", {"x": xn * g.field_hw, "vx": -xn * randf_range(0.3, 0.8), "vz": randf_range(3.2, 4.2), "spin": randf_range(-0.15, 0.15), "turn": randf() * TAU, "big": randf() < 0.3})
	else:
		g.spawn_enemy("rock", {"x": randf_range(-0.85, 0.85) * g.field_hw, "z": g.field_top - 2.5, "vx": randf_range(-1.0, 1.0), "vz": randf_range(4.0, 6.0), "spin": randf_range(-1.2, 1.2), "big": randf() < 0.3})


func _giants(g: Game) -> int:
	var c := 0
	for e in g.enemies:
		if e.kind == "giant_rock" and not e.dead:
			c += 1
	return c


func build_waves(f: Formations) -> void:
	# build the stage's big models now, not the moment they first appear
	# (the surface's segments, GORGON's parts, the heavies, the satellites)
	for n: String in SurfaceModels.NAMES:
		Vox.get_mesh(n)
	for n: String in ["giant_rock_a", "giant_rock_b"]:
		Vox.get_mesh(n)
	# the exit shaft: a few fighters, and out (the tunnel ends at a portal
	# a few seconds on)
	wave("exit", f.col(0.0, -0.75, 5, 0.16, 1) + f.col(0.4, 0.75, 5, 0.16, -1), 4.0)
	# AREA 1: crater plains
	wave("plains", f.kestrel(0.0, -1, -0.45) + f.kestrel(0.6, 1, 0.45) + f.vform(2.4, 1) + f.vform(2.9, -1), 14.0)
	wave("plains", f.racers(0.0, "tl", 1, 8) + f.racers(1.2, "tr", 1, 8) + f.rammers(2.6, [0.0], 0.2), 14.0)
	wave("plains", f.grappler(0.0, -0.5) + f.grappler(0.8, 0.5) + f.sweep(2.0, 1, 7, 0.18) + f.sweep(2.4, -1, 7, 0.18), 14.0)
	wave("plains", f.chasers(0.0, 4, -1) + f.chasers(1.2, 4, 1) + f.pincer(2.6, 3) + f.swirls(3.6, -1, 5, 0.22), 11.0)
	# the heavy gunship
	wave("plains", f.halberd(0.0, 0.0) + f.sweep(3.0, -1, 7, 0.18) + f.sweep(3.4, 1, 7, 0.18), 16.0)
	wave("plains", f.swirls(0.0, -1, 6, 0.2) + f.swirls(0.5, 1, 6, 0.2) + f.vform(1.6, 1) + f.vform(2.1, -1) + f.rammers(3.0, [-0.4, 0.4], 0.3), 10.0)
	wave("plains", f.kestrel(0.0, -1, -0.4) + f.kestrel(1.0, 1, 0.4) + f.flankers(2.4, -1, 4) + f.flankers(3.6, 1, 4), 15.0)
	# AREA 2: the red rift
	wave("rift", f.col(0.0, -0.75, 6, 0.16, 1) + f.col(0.5, 0.75, 6, 0.16, -1) + f.vform(1.2, 1) + f.vform(1.7, -1) + f.vform(2.4, 1))
	wave("rift", f.grappler(0.0, -0.35) + f.kestrel(0.8, 1, 0.45) + f.racers(2.6, "tl", 1, 8), 15.0)
	wave("rift", f.chasers(0.0, 4, -1) + f.chasers(1.0, 4, 1) + f.pincer(2.2, 3) + f.rammers(3.4, [0.0], 0.2), 10.0)
	wave("rift", f.racers(0.0, "tr", 1, 8) + f.racers(1.0, "tl", 1, 8) + f.sweep(2.4, -1, 7, 0.18), 14.0)
	wave("rift", f.halberd(0.0, -0.45) + f.halberd(1.4, 0.45, 8.5) + f.swirls(3.6, -1, 5, 0.2) + f.swirls(4.0, 1, 5, 0.2), 18.0)
	wave("rift", f.bulwark(0.0, 0.0) + f.kestrel(1.0, -1, -0.5) + f.kestrel(1.6, 1, 0.5) + f.swirls(3.2, -1, 5, 0.2) + f.swirls(3.6, 1, 5, 0.2), 16.0)
	wave("rift", f.sweep(0.0, -1, 7, 0.18) + f.sweep(0.4, 1, 7, 0.18) + f.chasers(1.6, 4) + f.vform(2.6, -1) + f.vform(3.0, 1), 10.0)
	# out of the canyon into the crater (its walls gone before the fortress
	# comes), then the buried fortress
	wave("basin", f.vform(0.0, -1) + f.vform(0.6, 1) + f.rammers(1.4, [-0.3, 0.3], 0.3), 7.0)
	wave("basin", [[0.0, "gorgon", {}]], 95.0, true)
	# AREA 3: the climb into orbit. A few fighters while the ground breaks
	# off and the planet falls away, then the satellites. The lances are
	# doors: hinged high on one side, the beam comes in near level across
	# the top and swings down, herding the ship below it; the guns wait where
	# it is herded. Rocks drift through for cover (they stop the beams).
	wave("ascent", f.vform(0.0, 1) + f.vform(0.7, -1) + f.col(2.0, -0.75, 4, 0.18, 1) + f.col(2.4, 0.75, 4, 0.18, -1), 8.0)
	# a door from the left drives the ship down to the left, under it; a gun
	# comes in there after it
	wave("ascent", f.sats(0.0, [[-0.65, "lance", 0.0, 8.0, 16.0], [-0.35, "gatling", 7.0]]), 11.0)
	# and from the right onto a gun on the right; saucers through the gap
	wave("ascent", f.sats(0.0, [[0.65, "lance", 0.0, 172.0, -16.0], [0.35, "gatling", 7.0]]) + f.swirls(1.6, -1, 5, 0.22), 11.0)
	# doors from both sides closing over a pocket at the bottom middle
	# (darts cross it), a gun behind them over the pocket
	wave("ascent", f.sats(0.0, [[-0.65, "lance", 0.0, -15.0, 17.0], [0.65, "lance", 0.0, 195.0, -17.0], [0.0, "gatling", 9.0]]) + f.vform(1.0, 1), 12.0)
	# doors in turn: the left one herds the ship to the left, then the right
	# one comes over and drives it back across to the right, onto a gun
	wave("ascent", f.sats(0.0, [[-0.65, "lance", 0.0, 8.0, 16.0], [0.65, "lance", 13.0, 172.0, -16.0], [0.45, "gatling", 19.0]]) + f.sweep(1.0, -1, 6, 0.2), 14.0)
	# and the other way round, the guns crossing it from both sides
	wave("ascent", f.sats(0.0, [[0.65, "lance", 0.0, 172.0, -16.0], [-0.65, "lance", 13.0, 8.0, 16.0], [-0.45, "gatling", 19.0], [0.8, "gatling", 4.0]]) + f.rammers(2.4, [0.0], 0.2), 14.0)
	# AREA 4: the defence grid: fast waves, satellites among them (their
	# beams are out only while they cross the top half here)
	wave("orbit", f.col(0.0, -0.75, 6, 0.16, 1) + f.col(0.4, 0.75, 6, 0.16, -1) + f.col(0.8, -0.55, 5, 0.16, 1) + f.col(1.2, 0.55, 5, 0.16, -1))
	wave("orbit", f.racers(0.0, "tl", 1, 8) + f.racers(1.2, "tr", 1, 8) + f.sats(1.0, [[-0.6, "lance", 0.0, 10.0, 26.0], [0.6, "lance", 16.0, 170.0, -26.0]]), 14.0)
	wave("orbit", f.chasers(0.0, 4, -1) + f.chasers(1.2, 4, 1) + f.pincer(2.4, 3) + f.sats(2.0, [[-0.7, "gatling"], [0.7, "gatling"]]), 11.0)
	wave("orbit", f.kestrel(0.0, -1, -0.45) + f.kestrel(0.6, 1, 0.45) + f.sweep(2.0, 1, 7, 0.18) + f.sats(3.0, [[0.65, "lance", 0.0, 172.0, -26.0], [0.3, "gatling", 5.0]]), 15.0)
	wave("orbit", f.swirls(0.0, -1, 6, 0.2) + f.swirls(0.5, 1, 6, 0.2) + f.vform(1.6, 1) + f.vform(2.1, -1) + f.sats(1.0, [[-0.65, "lance", 0.0, 8.0, 26.0], [-0.35, "gatling", 5.0]]), 12.0)
	# (the HALBERD with lances either side. As doors swinging down from both
	# sides at once they shut the whole screen within 2 s at this scroll, and
	# each one's beam swept the other's side: no way out but to shoot one
	# down, with the HALBERD firing too: yos found it too much. Now they
	# come late and as scissors: beams straight down the two sides, swinging
	# in toward the middle as the satellites pass. They never quite meet: a
	# lane stays open down the middle, about 4 either side of centre at the
	# ship's usual height, 2.5 at the very bottom, and the strips outside the
	# satellites stay clear as well. Same drift as every other satellite.)
	wave("orbit", f.halberd(0.0, 0.0) + f.flankers(2.0, -1, 4) + f.flankers(3.2, 1, 4) + f.sats(5.5, [[-0.65, "lance", 0.0, 90.0, -24.0], [0.65, "lance", 0.0, 90.0, 24.0]]), 18.0)
	wave("orbit", f.col(0.0, -0.75, 6, 0.16, 1) + f.col(0.4, 0.75, 6, 0.16, -1) + f.sats(0.8, [[-0.65, "lance", 0.0, 8.0, 26.0], [0.65, "lance", 16.0, 172.0, -26.0], [0.0, "gatling", 3.0], [-0.3, "gatling", 9.0], [0.3, "gatling", 9.0]]) + f.rammers(2.8, [-0.4, 0.4], 0.3), 12.0)
