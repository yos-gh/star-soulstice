extends BossBase
## Stage 2 boss VULCAN PRESS: the foundry's great press, as wide as the
## tunnel, at the end of the furnace row. Its crucible core (the only weak
## point, the gauge) burns in a bay in the front of the hull behind a
## ring of three armour plates that turn round it: shots get through the
## gaps, and the plates can be shot off one by one. Two hammers ride a gantry rail across its front: one slides over
## the ship's lane, locks on (the lane is marked, chevrons down to the
## strike point), drives down the lane on its telescoping ram, throws up a
## spray of shells where it lands, holds the lane shut a moment and draws
## back. The ram runs right to the bottom of the screen: get out of the
## lane. Two vent guns at the corners fire shell fans (big, then small)
## and the core fires telegraphed needle bursts.
## OVERDRIVE (after a while, hammers still up): each round the whole press
## comes down the tunnel (marked first), spins a shell spiral from the core
## while both hammers strike either side of the ship at once.
## MELTDOWN (both hammers destroyed; they are tough, and breaking them is
## the player's choice): the crucible boils over. The press stays forward
## and sways wide; each round it sweeps twin hoses of shells, lobs globs
## of molten metal from the crucible onto the ship's spot and either side of
## it (marked first; MarkedStrikes), fires armoured IRON slugs down the
## ship's lane and one either side from the empty hammer sockets (marked;
## they stop your shots) twice, lobs shells that burst into rings and
## fires a wide needle burst. Every round ends in a quiet gap to come in with the Spear.

const MarkedStrikes := preload("res://scripts/bosses/marked_strikes.gd")

const INFO := {
	"name": "VULCAN PRESS", "role": "boss",
	"desc": "核（坩堝）だけが弱点。核のまわりを回る 3 枚の装甲板の隙間を撃ち抜く（装甲板は 1 枚ずつ壊せる）。2 基のハンマーが自機の列に寄って予兆のあと画面の下端まで打ち下ろし、物理弾が上へ散る。角の砲塔は扇状の物理弾。時間で暴走：本体ごと迫り出して渦巻き弾、ハンマーが自機の両脇を同時に叩く。ハンマー（硬い）を両方失うと発狂（MELTDOWN）：大きく揺れながら 2 本の物理弾の薙ぎ払い、坩堝から溶けた鉄の塊を自機の位置とその左右へ山なりに投げ落とす（落ちる所を予兆、着弾で炸裂）、空いた穴から自機の列と両脇の 3 列へ鉄球弾を 2 回、はじけて輪になる弾、広い針弾",
	"demos": [["FULL", ""], ["OVERDRIVE", "B"], ["MELTDOWN", "C"]],
}
const CORE_HP := 1400.0
const CORE_SCORE := 60000
const HAMMER_HP := 560.0
const HAMMER_SCORE := 8000
const VENT_HP := 70.0
const VENT_SCORE := 3000
const CORE_OFF := Vector3(0, 0, 1.4)
const PLATE_R := 2.6
const RAIL_Z := 3.0  # the hammers' rail, ahead of the centre
const HEAD_REST := 1.6  # hammer head below the rail when drawn back
const VENT_OFF := [Vector3(-10.5, 0, 1.8), Vector3(10.5, 0, 1.8)]
const ARMOUR := [[Vector3(-5.8, 0, -0.6), 3.0], [Vector3(5.8, 0, -0.6), 3.0], [Vector3(-10.5, 0, -1.2), 2.2], [Vector3(10.5, 0, -1.2), 2.2], [Vector3(0, 0, -2.2), 2.4]]
const TUBE_LEN := 6.0
const RODS := 6  # hit zones along a ram (they stop shots and ram; the lane is also checked whole)
const RAM_HW := 0.7  # half width of a ram, for touching the ship
const AIM_T := 1.0
const SLIDE_T := 0.55  # in the wind-up, the hammer slides over to its lane
const DRIVE_T := 0.18
const HOLD_T := 0.55
const BACK_T := 1.1
const CYCLE_A := 9.0
const CYCLE_B := 10.0
const CYCLE_C := 7.0
const MELT_DOWN := 2.5  # how far forward the press stays in MELTDOWN
const SLUG_GAP := 3.4  # between MELTDOWN's slug lanes
const PLATE_HP := 160.0
const PLATE_SCORE := 2500
const ADVANCE := 4.0  # how far the press comes down in OVERDRIVE
const ENRAGE_T := 55.0

var hull: MeshInstance3D
var core: Enemy
var plates: Array[Enemy] = []
var vents: Array[Enemy] = []
var armour: Array[Enemy] = []
## {head, rods: [Enemy], tubes: [MeshInstance3D], x, from_x, lane, lo, hi, park, state, st, ext, to_ext, target, dead}
var hammers: Array[Dictionary] = []
var center := Vector3.ZERO
var rest_z := 0.0
var phase := 0  # 0 enter, 1 A, 2 B (overdrive), 3 C (meltdown), 4 dying
var st := 0.0
var fight_t := 0.0
var cycle_t := 0.0
var cycle := 0
var fired := {}
var plate_a := 0.0
var spiral_a := 0.0
var spiral_t := 0.0
var muzzles: Array[Enemy] = []  # where MELTDOWN's slugs leave (marked by the lock-ons)
var lanes := PackedFloat32Array()
var hose_t := 0.0
var slag: MarkedStrikes  # MELTDOWN's molten globs
var dying_t := 0.0
var destroyed := false


func setup(g: Game) -> void:
	game = g
	rest_z = game.field_top + 5.5
	center = Vector3(0, 0, game.field_top - 9.0)
	# order matters: shots hit the first part in the list they touch, so
	# the plates come before the core they shield, the hull armour last
	for k in 3:
		var pl := game.spawn_part(self, "press_plate", 1.05)
		pl.hp = PLATE_HP
		pl.max_hp = PLATE_HP
		pl.score = PLATE_SCORE
		pl.energy_drop = 6.0
		pl.blast = 1.8
		pl.ram = false
		plates.append(pl)
	core = game.spawn_part(self, "press_core", 1.6)
	core.hp = CORE_HP
	core.max_hp = CORE_HP
	core.score = CORE_SCORE
	core.blast = 6.0
	slag = MarkedStrikes.new(g, self, MarkedStrikes.LOB, Color(1.0, 0.5, 0.15))
	core.ram = false
	for s in [-1, 1]:
		var h := game.spawn_part(self, "press_hammer", 1.5)
		h.hp = HAMMER_HP
		h.max_hp = HAMMER_HP
		h.score = HAMMER_SCORE
		h.energy_drop = 14.0
		h.blast = 3.0
		var rods: Array[Enemy] = []
		for k in RODS:
			var r := game.spawn_part(self, "", 0.55)
			r.armored = true
			r.intangible = true
			r.hp = 1e9
			rods.append(r)
		var tubes: Array[MeshInstance3D] = []
		for k in 3:
			var m := MeshInstance3D.new()
			m.mesh = Vox.get_mesh("press_tube%d" % k)
			add_child(m)
			tubes.append(m)
		hammers.append({"head": h, "rods": rods, "tubes": tubes, "x": s * 6.0, "from_x": s * 6.0, "lane": s * 6.0, "park": s * 7.5,
			"lo": -11.0 if s < 0 else -4.0, "hi": 4.0 if s < 0 else 11.0,
			"state": "idle", "st": 0.0, "ext": 0.0, "to_ext": 0.0, "target": Vector3.ZERO, "dead": false})
	for o: Vector3 in VENT_OFF:
		var v := game.spawn_part(self, "press_vent", 1.2)
		v.hp = VENT_HP
		v.max_hp = VENT_HP
		v.score = VENT_SCORE
		v.energy_drop = 8.0
		v.blast = 2.2
		v.ram = false
		vents.append(v)
	for a: Array in ARMOUR:
		var e := game.spawn_part(self, "", a[1])
		e.armored = true
		e.hp = 1e9
		armour.append(e)
	for k in 3:
		var m := game.spawn_part(self, "", 0.8)
		m.intangible = true
		m.ram = false
		muzzles.append(m)
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("press_hull")
	add_child(hull)
	_arm(true)
	_place(0.0)


## While it comes in nothing can be hurt.
func _arm(on: bool) -> void:
	core.armored = on
	for pl in plates:
		if not pl.dead:
			pl.armored = on
	for h in hammers:
		if not h["dead"]:
			(h["head"] as Enemy).armored = on
	for v in vents:
		if not v.dead:
			v.armored = on


func on_hit(_e: Enemy, dmg: float) -> float:
	return 0.0 if defeated else dmg


func on_part_killed(e: Enemy) -> void:
	if e == core:
		_die()
		return
	for h in hammers:
		if h["head"] == e:
			_drop_hammer(h)
			game.shake(0.8)
	if vents.has(e) or plates.has(e):
		game.shake(0.5)


## A hammer is gone: its ram goes with it.
func _drop_hammer(h: Dictionary) -> void:
	h["dead"] = true
	for r: Enemy in h["rods"]:
		game.remove_enemy(r)
	for m: MeshInstance3D in h["tubes"]:
		m.visible = false


func hammers_alive() -> int:
	var c := 0
	for h in hammers:
		if not h["dead"]:
			c += 1
	return c


func tick(dt: float) -> void:
	if destroyed:
		return
	st += dt
	match phase:
		0:
			center.z = move_toward(center.z, rest_z, 4.0 * dt)
			if st > 4.2:
				phase = 1
				st = 0.0
				_arm(false)
				game.boss_fight_started()
		1:
			fight_t += dt
			cycle_t += dt
			_round_a()
			if cycle_t >= CYCLE_A:
				_next_round()
			if hammers_alive() == 0:
				_meltdown()
			elif fight_t > ENRAGE_T:
				_overdrive()
		2:
			fight_t += dt
			cycle_t += dt
			_round_b(dt)
			if cycle_t >= CYCLE_B:
				_next_round()
			if hammers_alive() == 0:
				_meltdown()
		3:
			fight_t += dt
			cycle_t += dt
			_round_c(dt)
			if cycle_t >= CYCLE_C:
				_next_round()
		4:
			dying_t += dt
			if int(dying_t * 8.0) != int((dying_t - dt) * 8.0):
				var off := Vector3(randf_range(-11, 11), 0, randf_range(-3.5, 3.5))
				game.fx.explode(center + off, randf_range(1.5, 3.0), Vector3.ZERO, Models.ORANGE)
				game.sfx.play("exp_m")
				game.shake(0.4)
			center.z += dt * 1.2
			if dying_t > 3.5:
				game.big_blast(center + CORE_OFF, 1.0, Models.STEEL_L)
				for k in 6:
					game.fx.explode(center + Vector3(randf_range(-11, 11), 0, randf_range(-3, 3)), 4.0, Vector3.ZERO, Models.ORANGE)
				game.sfx.play("exp_l")
				game.shake(2.0)
				destroyed = true
				finished = true
				visible = false
				for q in _parts():
					game.remove_enemy(q)
					q.visible = false
				game.boss_destroyed(self)
				return
	plate_a += dt * ([1.5, 1.5, 2.5, 3.2, 1.5][phase])
	for i in hammers.size():
		_hammer(i, dt)
	if phase >= 1 and phase <= 3:
		slag.tick(dt)
	_place(dt)


func _next_round() -> void:
	cycle_t = 0.0
	cycle += 1
	fired.clear()


## True once when the round passes `at` seconds.
func _once(key: String, at: float) -> bool:
	if cycle_t >= at and not fired.has(key):
		fired[key] = true
		return true
	return false


## Phase A: one hammer, then the other; vent fans after each strike, a
## needle burst between; a quiet gap at the end.
func _round_a() -> void:
	if _once("h1", 1.2):
		_strike(hammers[_pick(cycle % 2)], game.player.position.x)
	if _once("v1", 2.6):
		_vents(Bullets.BIG)
	if _once("v1s", 2.85):
		_vents(Bullets.SMALL)
	if _once("w_core", 3.4):
		game.warn(core, Enemy.WINDUP_SHOT + 0.15, Game.Warn.SHOT, core.radius)
	if _once("core", 3.4 + Enemy.WINDUP_SHOT + 0.15):
		_needles()
	if _once("h2", 4.8):
		_strike(hammers[_pick((cycle + 1) % 2)], game.player.position.x)
	if _once("v2", 6.2):
		_vents(Bullets.BIG)
	if _once("v2s", 6.45):
		_vents(Bullets.SMALL)


## Phase B: the press comes down (marked), spirals and strikes both sides
## of the ship at once, then draws back.
func _round_b(dt: float) -> void:
	if _once("w_adv", 0.0):
		game.warn(core, 1.0, Game.Warn.MOVE, 4.0, center + CORE_OFF + Vector3(0, 0, ADVANCE + 4.0))
		game.sfx.play("slam")
	var down := 0.0
	if cycle_t < 1.0:
		down = 0.0
	elif cycle_t < 2.4:
		down = _smooth((cycle_t - 1.0) / 1.4)
	elif cycle_t < 6.4:
		down = 1.0
	elif cycle_t < 7.8:
		down = 1.0 - _smooth((cycle_t - 6.4) / 1.4)
	center.z = rest_z + ADVANCE * down
	if cycle_t > 2.4 and cycle_t < 6.4 and game.boss_can_fire(center + CORE_OFF):
		spiral_t -= dt
		if spiral_t <= 0.0:
			spiral_t = 0.13
			spiral_a += 0.37
			for arm in 2:
				game.bullets.fire(center + CORE_OFF, spiral_a + arm * PI, 4.6, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if arm == 0 else Bullets.SMALL)
	if _once("h_both", 2.6):
		var px := game.player.position.x
		_strike(hammers[0], px - 4.5, true)
		_strike(hammers[1], px + 4.5, true)
	if _once("w_core", 4.6):
		game.warn(core, Enemy.WINDUP_SHOT + 0.15, Game.Warn.SHOT, core.radius)
	if _once("core", 4.6 + Enemy.WINDUP_SHOT + 0.15):
		_needles()
	if _once("v", 8.0):
		_vents(Bullets.BIG)
	if _once("vs", 8.25):
		_vents(Bullets.SMALL)


func _overdrive() -> void:
	phase = 2
	st = 0.0
	cycle_t = 0.0
	fired.clear()
	game.show_msg("PRESS OVERDRIVE", "", 1.5)


## Both hammers gone: MELTDOWN, the press's last stand.
func _meltdown() -> void:
	phase = 3
	st = 0.0
	cycle_t = 0.0
	fired.clear()
	hose_t = 0.0
	game.show_msg("PRESS MELTDOWN", "", 1.5, true)
	game.shake(1.0)


## Phase C: the press stays forward and sways wide. Twin hoses of shells
## sweep the tunnel from both sides at once while the crucible lobs three
## molten globs onto the ship's spot and either side of it (marked); then IRON slugs fire down three
## lanes (the ship's own and one either side, marked), shells burst into
## rings, the vents fire, a wide needle burst, and a second round of slugs
## before a short rest.
func _round_c(dt: float) -> void:
	center.z = move_toward(center.z, rest_z + MELT_DOWN, 3.0 * dt)
	center.x = sin(st * 0.7) * 4.0
	var cp := center + CORE_OFF + Vector3(0, 0, 1.4)
	# twin hoses: two streams of shells swinging out and back, mirrored
	if cycle_t < 2.4 and game.boss_can_fire(cp):
		hose_t -= dt
		if hose_t <= 0.0:
			hose_t = 0.075
			var sw := sin(cycle_t * 2.6) * 1.0
			for s in [-1, 1]:
				game.bullets.fire(cp, PI / 2.0 + s * sw, 6.4, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if s < 0 else Bullets.SMALL)
	# molten globs from the crucible: the ship's spot first, then either side
	for k in 3:
		if _once("slag%d" % k, 0.6 + k * 0.25):
			var dx := 0.0 if k == 0 else (-4.5 if k == 1 else 4.5)
			slag.drop(core, Vector3(0, 0, 1.4), Vector3(dx, 0, 0), 5, k == 0)
	# slugs down three lanes, twice a round
	_slugs("a", 2.2)
	_slugs("b", 5.4)
	if _once("split", 3.3) and game.boss_can_fire(cp):
		# three big shells that burst into rings
		for s in [-1, 0, 1]:
			game.bullets.fire(cp, game.bullets.aim(cp) + s * deg_to_rad(25.0), 4.5, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, 1.6)
			game.bullets.split(0.9, 12)
	if _once("v", 3.9):
		_vents(Bullets.BIG)
	if _once("vs", 4.15):
		_vents(Bullets.SMALL)
	if _once("w_core", 4.5):
		game.warn(core, Enemy.WINDUP_SHOT + 0.15, Game.Warn.SHOT, core.radius)
	if _once("core", 4.5 + Enemy.WINDUP_SHOT + 0.15):
		var at := core.position + Vector3(0, 0, 1.6)
		if game.boss_can_fire(at):
			game.bullets.fan(at, game.bullets.aim(at), 9, 36.0, 10.0, Bullets.ORB, self, Bullets.NEEDLE)


## IRON slugs from the hammer sockets down the ship's lane and one either
## side of it: marked at `at`, fired 0.8 s later.
func _slugs(key: String, at: float) -> void:
	if _once("w_" + key, at):
		var px := game.player.position.x
		lanes = PackedFloat32Array()
		for k in muzzles.size():
			lanes.append(clampf(px + (k - 1) * SLUG_GAP, -12.0, 12.0))
		_place(0.0)
		for k in muzzles.size():
			game.warn(muzzles[k], 0.8, Game.Warn.MOVE, 0.9, Vector3(lanes[k], 0, game.field_bottom + 1.0))
		game.sfx.play("slam")
	if _once(key, at + 0.8):
		for k in muzzles.size():
			if game.combat_on():
				game.bullets.fire(muzzles[k].position, PI / 2.0, 14.0, Bullets.IRON, self)
		game.shake(0.4)


func _smooth(f: float) -> float:
	f = clampf(f, 0.0, 1.0)
	return f * f * (3.0 - 2.0 * f)


## A strike by hammer `h` at lane x (`exact`: there or nowhere, else the
## nearest lane it can reach).
func _strike(h: Dictionary, x: float, exact := false) -> void:
	if h["dead"] or h["state"] != "idle":
		return
	var lx := clampf(x, h["lo"], h["hi"])
	if exact and absf(lx - x) > 0.5:
		return
	# it slides over to the lane during the wind-up (set at once, it jumped
	# sideways)
	h["from_x"] = h["x"]
	h["lane"] = lx
	var head_rest := center.z + RAIL_Z + HEAD_REST
	# right down to the bottom edge of the screen: the whole lane closes
	var tz := game.field_bottom + 1.2
	h["target"] = Vector3(lx, 0, tz)
	h["to_ext"] = tz - head_rest
	h["state"] = "aim"
	h["st"] = 0.0
	game.warn(h["head"], AIM_T, Game.Warn.MOVE, (h["head"] as Enemy).radius, h["target"])


## One hammer: idle (sliding along the rail), aim (locked, marked), drive
## (down the lane), hold (the lane shut), back.
func _hammer(i: int, dt: float) -> void:
	var h := hammers[i]
	if h["dead"]:
		return
	h["st"] += dt
	var s: float = h["st"]
	match h["state"]:
		"idle":
			var want: float = h["park"]
			if i == _tracker():
				# the one to strike next slides over the ship's lane, clear
				# of the other; the other waits at its side
				want = clampf(game.player.position.x, h["lo"], h["hi"])
				var other: Dictionary = hammers[1 - i]
				if not other["dead"]:
					var ox: float = other["x"]
					if absf(want - ox) < 4.5:
						want = ox + (4.5 if h["park"] > other["park"] else -4.5)
				want = clampf(want, h["lo"], h["hi"])
			h["x"] = move_toward(h["x"], want, 5.0 * dt)
			h["ext"] = move_toward(h["ext"], 0.0, 6.0 * dt)
		"aim":
			h["x"] = lerpf(h["from_x"], h["lane"], _smooth(s / SLIDE_T))
			if s >= AIM_T:
				h["state"] = "drive"
				h["st"] = 0.0
				game.sfx.play("slam")
		"drive":
			var f := clampf(s / DRIVE_T, 0.0, 1.0)
			h["ext"] = h["to_ext"] * f * f
			if f >= 1.0:
				h["state"] = "hold"
				h["st"] = 0.0
				_impact(h)
		"hold":
			if s >= HOLD_T:
				h["state"] = "back"
				h["st"] = 0.0
		"back":
			h["ext"] = h["to_ext"] * (1.0 - _smooth(s / BACK_T))
			if s >= BACK_T:
				h["state"] = "idle"
				h["st"] = 0.0
				h["ext"] = 0.0
	# the ram is solid while it is out
	var out: bool = h["ext"] > 2.0
	for r: Enemy in h["rods"]:
		r.intangible = not out
	if out:
		var pp := game.player.position
		var rail := center.z + RAIL_Z
		if absf(pp.x - float(h["x"])) < RAM_HW + Player.HIT_R and pp.z > rail and pp.z < rail + HEAD_REST + float(h["ext"]):
			game.touch_player("press ram")


## Hammer k strikes, unless the ship is out of its reach (or it is gone)
## and the other one is free: then the other.
func _pick(k: int) -> int:
	var h: Dictionary = hammers[k]
	var o: Dictionary = hammers[1 - k]
	var px := game.player.position.x
	var out_of_reach: bool = h["dead"] or px < float(h["lo"]) - 0.5 or px > float(h["hi"]) + 0.5
	if out_of_reach and not o["dead"] and o["state"] == "idle":
		return 1 - k
	return k


## Which hammer follows the ship (-1 = neither): in phase A the one that
## strikes next this round.
func _tracker() -> int:
	if phase != 1:
		return -1
	if cycle_t < 1.2:
		return _pick(cycle % 2)
	if cycle_t < 4.8:
		return _pick((cycle + 1) % 2)
	return -1


## The hammer lands at the bottom edge: a shake, a ring of dust and a spray
## of shells thrown up the screen from it (not along the bottom, where the
## ship is).
func _impact(h: Dictionary) -> void:
	var at: Vector3 = (h["head"] as Enemy).position
	game.shake(0.6)
	game.fx.shockwave(at + Vector3(0, 0.3, 0), 3.5, Color(1.0, 0.6, 0.3))
	game.fx.spark(at + Vector3(0, 0.5, 0), Color(1.0, 0.8, 0.5), 6, 0.5)
	game.fx.puff(at + Vector3(0, 0.3, 0), Vector3(0, 0, game.scroll_speed * 0.3), 1.2, 3.0, 0.6, Fx.SMOKE)
	game.sfx.play("exp_s")
	if not game.combat_on():
		return
	var n := 7
	for i in n:
		var a := -PI / 2.0 + deg_to_rad(-60.0 + 120.0 * i / (n - 1))
		game.bullets.fire(at - Vector3(0, 0, 1.0), a, 3.4, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if i % 2 == 0 else Bullets.SMALL)


## Both vent guns: a fan of shells toward the ship (`size` BIG leads, SMALL follows).
func _vents(size: float) -> void:
	for v in vents:
		if v.dead or not game.boss_can_fire(v.position):
			continue
		var at := v.position + Vector3(0, 0, 1.0)
		var off := 0.0 if size == Bullets.BIG else deg_to_rad(5.0)
		game.bullets.fan(at, game.bullets.aim(at) + off, 7 if size == Bullets.BIG else 6, 60.0 if size == Bullets.BIG else 54.0, 5.0 if size == Bullets.BIG else 5.6, Bullets.SHELL, self, Bullets.ROUND, size)


## The core's telegraphed needle burst (fired WINDUP after its warning).
func _needles() -> void:
	var at := core.position + Vector3(0, 0, 1.6)
	if game.boss_can_fire(at):
		game.bullets.fan(at, game.bullets.aim(at), 5, 18.0, 9.0, Bullets.ORB, self, Bullets.NEEDLE)


func _place(dt: float) -> void:
	hull.position = center
	var cp := center + CORE_OFF
	core.position = cp
	core.model.rotation.y += dt * 0.8
	for k in 3:
		if plates[k].dead:
			continue
		var a := plate_a + k * TAU / 3.0
		plates[k].position = cp + Vector3(cos(a), 0, sin(a)) * PLATE_R
		plates[k].rotation.y = atan2(-cos(a), -sin(a))
	for i in 2:
		if not vents[i].dead:
			vents[i].position = center + VENT_OFF[i]
	for i in armour.size():
		armour[i].position = center + ARMOUR[i][0]
	for h in hammers:
		if h["dead"]:
			continue
		var rail := center.z + RAIL_Z
		var x: float = h["x"]
		var ext: float = h["ext"]
		var head: Enemy = h["head"]
		head.position = Vector3(x, 0, rail + HEAD_REST + ext)
		var tubes: Array = h["tubes"]
		for k in 3:
			# telescoping: tube 0 (the thinnest) rides behind the head
			var front := rail + ext * (1.0 - k / 3.0)
			(tubes[k] as MeshInstance3D).position = Vector3(x, 0.0, front - TUBE_LEN * 0.5)
		var rods: Array = h["rods"]
		for k in RODS:
			(rods[k] as Enemy).position = Vector3(x, 0, rail + ext * (k + 0.5) / RODS)
	for k in muzzles.size():
		muzzles[k].position = Vector3(lanes[k] if lanes.size() > k else center.x, 0, center.z + RAIL_Z + 0.5)
		muzzles[k].hit_pos = muzzles[k].position


func _parts() -> Array:
	var out: Array = [core] + plates + vents + armour + muzzles
	for h in hammers:
		out.append(h["head"])
		out += h["rods"]
	return out


func gauge() -> Dictionary:
	if phase < 1 or phase >= 4:
		return {}
	return {"frac": core.hp / core.max_hp, "color": Color(1.0, 0.55, 0.2), "name": INFO["name"], "name_color": Color(1.0, 0.8, 0.6), "x": 0.2, "w": 0.6, "h": 8.0, "name_y": 72.0}


func force_defeat() -> void:
	if phase < 4:
		core.armored = false
		game.kill(core)


## "B": straight into OVERDRIVE, hammers still up. "C": into MELTDOWN, the
## hammers gone.
func viewer_skip(to: String) -> void:
	if to == "B":
		center.z = rest_z
		phase = 2
		st = 0.0
		cycle_t = 0.0
		fired.clear()
		_arm(false)
		_place(0.0)
	elif to == "C":
		center.z = rest_z
		_arm(false)
		for h in hammers:
			game.remove_enemy(h["head"])
			_drop_hammer(h)
		_meltdown()
		_place(0.0)

func debug_state() -> String:
	var names := ["enter", "A", "B (overdrive)", "C (meltdown)", "dying"]
	return "phase %s %.1fs  core %d/%d  hammers %d  round %d %.1fs" % [names[phase], st, int(maxf(core.hp, 0.0)), int(CORE_HP), hammers_alive(), cycle, cycle_t]


func _die() -> void:
	defeated = true
	phase = 4
	dying_t = 0.0
	slag.clear()
	for h in hammers:
		if not h["dead"]:
			game.kill(h["head"])
	for v in vents:
		if not v.dead:
			game.kill(v)
	disarm()
	var conv := game.bullets.cancel_all()
	for b in conv:
		game.items.spawn(b, Items.ENERGY, 1.0)
	game.boss_dying()
