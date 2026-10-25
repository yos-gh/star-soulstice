extends BossBase
## Stage 3 boss TITAN DREDGE: a strip-mining machine dug into a giant
## asteroid at the top of the screen. Its two cutter wheels dig at the
## asteroid's face between attacks, and what they cut is loaded into ore
## skips that come out of a mine adit on the left: armoured cars on the
## belt, down the left side and across the front of the core (the only
## weak point, the gauge) to the loader on the right. They can't be broken:
## shots glance off them as they pass, so the core is shut off now and
## then and open in the gaps between them (it is softer for it). Every
## skip that reaches the loader tips its rock into the mass driver beside
## it (a loaded boulder shows on the driver), which turns on the ship and
## fires it down a marked line to the bottom edge.
## The cutter wheels (tough; breaking them is the player's choice) take
## turns to sweep. The boom reaches out to the ship's distance from its
## pivot (at least MIN_R): a lock-on and the whole path marked (out to the
## edge of the screen, then the arc through where the ship is and on past
## it), the wheel sweeps the arc throwing gravel shells out of it, holds,
## comes back along the same arc and stows. Dodge by changing your distance
## from the pivot (in or out of the arc's band), by slipping inside the
## minimum reach close under the pivot, or out past the arc's end. Gravel
## vents fire shell fans, the core telegraphed needle bursts, and every
## round ends in a quiet gap.
## RAMPAGE (both wheels broken, or after a while): it pushes forward and
## sways, the belt runs fast, the core spins a shell spiral, the asteroid
## sheds boulders down marked lanes scattered across the screen (one near
## the ship) twice a round, the driver fires three-way, a wide needle
## burst; wheels still up sweep both at once.

const INFO := {
	"name": "TITAN DREDGE", "role": "boss",
	"desc": "巨大な小惑星に食い込んだ採掘機。弱点は前の真ん中で回る核だけ。カッターホイールが小惑星を掘り、削った岩を積んだ装甲トロッコが左の坑道から出てきて、ベルトで左側を下り、核の前を横切る。トロッコは壊せず弾を弾くので、核は通る間だけふさがり、隙間から撃ち込む（そのぶん核は柔らかい）。右端の積み込み口に着いたトロッコの岩は隣の質量投射機に装填され、予兆（線）のあと自機のいた所へ下端まで撃ち出される。2 つのカッターホイール（硬い）が交互に、自機までの距離にブームを伸ばし（最小半径あり）、予兆（道筋全体）のあと画面の端から自機の向こうまで弧を描いて薙ぎ払い、物理弾の砂利を外へまいて同じ弧を戻る：弧の帯から外れるか、最小半径の内側（支点の下）に潜るか、弧の終わりの先へ。端の噴出口は扇状の物理弾、核は針弾。ホイールを両方失うか時間で発狂（RAMPAGE）：迫り出して揺れ、ベルトが速まり、核から渦巻き弾、小惑星から岩塊がばらけた列に予兆つきで落ちてくる（1 つは自機の近く）、投射機は 3 方向、広い針弾、残ったホイールは 2 つ同時に薙ぎ払う",
	"demos": [["FULL", ""], ["SWEEP", "A"], ["RAMPAGE", "C"]],
}
const CORE_HP := 1200.0
const CORE_SCORE := 60000
const WHEEL_HP := 520.0
const WHEEL_SCORE := 8000
const SKIP_R := 1.3
const CORE_OFF := Vector3(0, 0, 1.4)
const PIVOT_OFF := [Vector3(-8.5, 0, -1.0), Vector3(8.5, 0, -1.0)]
## the ore belt: out of the adit in the asteroid, down the left side and
## across the front of the core to the loader
const BELT := [Vector3(-12.4, 0, -5.2), Vector3(-12.4, 0, 4.3), Vector3(11.4, 0, 4.3)]
const EMERGE := 1.4  # along the belt: coming out of the adit
const HOPPER := Vector3(12.7, 0, 4.0)
const DROP_T := 0.45  # going into the loader
const DRIVER_OFF := Vector3(11.8, 0, 6.2)
const VENT_OFF := [Vector3(-8.5, 0, 2.3), Vector3(8.5, 0, 2.3)]
const ARMOUR := [[Vector3(-4.6, 0, 0.2), 2.6], [Vector3(4.6, 0, 0.2), 2.6], [Vector3(-10.0, 0, -0.4), 2.3], [Vector3(10.0, 0, -0.4), 2.3], [Vector3(0, 0, -2.4), 2.4]]
const JIB_LEN := 10.5
## a boom's angle (0 = +x, PI/2 = down-screen) for the left one; the right
## one mirrors it
const REST_A := 3.95  # stowed: up and out, the wheel digging at the asteroid
const REST_L := 6.5  # boom length stowed
const MIN_R := 11.0  # the shortest a sweep reaches: inside it is safe
const REACH_TO := 0.5  # the longest: to this far above the bottom edge
const PAST := 0.6  # the arc runs on past the ship by this (radians)
const SWEEP_W := 1.1  # rad/s on average
const WIND_T := 1.0
const HOLD_T := 0.35
const BACK_T := 1.4
const STOW_T := 1.2
const ROUND_A := 10.0
const ROUND_C := 8.0
const ENRAGE_T := 50.0
const RAGE_DOWN := 2.0
const BOULDER_SPEED := 15.0
const FALL_SPEED := 14.0

var hull: MeshInstance3D
var core: Enemy
var driver: Enemy
var loaded: MeshInstance3D  # a boulder in the driver's breech
var armour: Array[Enemy] = []
var skips: Array[Dictionary] = []  # ore skips on the belt: {e, s (along it), drop (s going into the loader, -1)}
var lanes: Array[Enemy] = []  # where the rockfall comes down (marked)
var fan_marks: Array[Enemy] = []  # the driver's three-way lines (marked)
## {wheel, boom, jib, side, a, l, state, st, from_a, from_l, reach, start, end, sweep_t, spray_t, dead}
var booms: Array[Dictionary] = []
var center := Vector3.ZERO
var rest_z := 0.0
var phase := 0  # 0 enter, 1 A, 3 RAMPAGE, 4 dying
var st := 0.0
var fight_t := 0.0
var cycle_t := 0.0
var cycle := 0
var fired := {}
var ammo := 1
var skip_t := 0.0
var aim_to := Vector3.ZERO
var fan_to: Array[Vector3] = []
var falls: Array = []  # this round's rockfall: [x, ...]
var spiral_a := 0.0
var spiral_t := 0.0
var sway_t := 0.0
var dying_t := 0.0
var destroyed := false


func setup(g: Game) -> void:
	game = g
	rest_z = game.field_top + 7.5
	center = Vector3(0, 0, game.field_top - 14.0)
	# order matters (a shot hits the first part in the list it touches): the
	# wheels and the driver, the core, the hull armour last; the belt's
	# boulders lie in front of the core
	for s: float in [-1.0, 1.0]:
		var w := game.spawn_part(self, "dredge_wheel", 1.9)
		w.hp = WHEEL_HP
		w.max_hp = WHEEL_HP
		w.score = WHEEL_SCORE
		w.energy_drop = 14.0
		w.blast = 3.0
		var boom := MeshInstance3D.new()
		boom.mesh = Vox.get_mesh("dredge_boom")
		add_child(boom)
		var jib := MeshInstance3D.new()
		jib.mesh = Vox.get_mesh("dredge_jib")
		add_child(jib)
		booms.append({"wheel": w, "boom": boom, "jib": jib, "side": s, "a": REST_A, "l": REST_L, "state": "rest", "st": 0.0,
			"from_a": REST_A, "from_l": REST_L, "reach": MIN_R, "start": 2.0, "end": 1.0, "sweep_t": 1.0, "spray_t": 0.0, "dead": false})
	driver = game.spawn_part(self, "dredge_driver", 1.4)
	driver.armored = true
	driver.hp = 1e9
	loaded = MeshInstance3D.new()
	loaded.mesh = Vox.get_mesh("meteor_b")
	loaded.scale = Vector3.ONE * 0.5
	loaded.position = Vector3(0, 0.55, 0.25)
	driver.add_child(loaded)
	core = game.spawn_part(self, "dredge_core", 1.7)
	core.hp = CORE_HP
	core.max_hp = CORE_HP
	core.score = CORE_SCORE
	core.blast = 6.0
	core.ram = false
	for a: Array in ARMOUR:
		var e := game.spawn_part(self, "", a[1])
		e.armored = true
		e.hp = 1e9
		armour.append(e)
	for k in 4:
		var m := game.spawn_part(self, "", 0.9)
		m.intangible = true
		m.ram = false
		lanes.append(m)
	for k in 3:
		var m := game.spawn_part(self, "", 0.9)
		m.intangible = true
		m.ram = false
		fan_marks.append(m)
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("dredge_hull")
	add_child(hull)
	# the belt already running as it comes in
	for s: float in [6.0, 13.0, 20.0, 27.0]:
		_add_skip(s)
	_arm(true)
	_place(0.0)


## An ore skip on the belt, `s` along it (0 = deep in the adit): armoured,
## solid, never broken.
func _add_skip(s: float) -> void:
	var e := game.spawn_part(self, "dredge_skip", SKIP_R)
	e.armored = true
	e.hp = 1e9
	e.score = 0
	skips.append({"e": e, "s": s, "drop": -1.0})
	_place_skip(skips[-1], 0.0)


## While it comes in nothing can be hurt.
func _arm(on: bool) -> void:
	core.armored = on
	for b in booms:
		if not b["dead"]:
			(b["wheel"] as Enemy).armored = on


func on_hit(_e: Enemy, dmg: float) -> float:
	return 0.0 if defeated else dmg


func on_part_killed(e: Enemy) -> void:
	if e == core:
		_die()
		return
	for b in booms:
		if b["wheel"] == e:
			b["dead"] = true
			b["state"] = "dead"
			b["st"] = 0.0
			b["from_a"] = b["a"]
			b["from_l"] = b["l"]
			(b["jib"] as MeshInstance3D).visible = false
			game.shake(0.8)


func wheels_alive() -> int:
	var c := 0
	for b in booms:
		if not b["dead"]:
			c += 1
	return c


func tick(dt: float) -> void:
	if destroyed:
		return
	st += dt
	match phase:
		0:
			center.z = move_toward(center.z, rest_z, 5.0 * dt)
			if st > 4.2:
				phase = 1
				st = 0.0
				_arm(false)
				game.boss_fight_started()
		1:
			fight_t += dt
			cycle_t += dt
			_round_a()
			if cycle_t >= ROUND_A:
				_next_round()
			if wheels_alive() == 0 or fight_t > ENRAGE_T:
				_rampage()
		3:
			fight_t += dt
			cycle_t += dt
			_round_c(dt)
			if cycle_t >= ROUND_C:
				_next_round()
		4:
			dying_t += dt
			if int(dying_t * 8.0) != int((dying_t - dt) * 8.0):
				var off := Vector3(randf_range(-12, 12), 0, randf_range(-4.0, 4.5))
				game.fx.explode(center + off, randf_range(1.5, 3.0), Vector3.ZERO, BeltModels.MINE)
				game.sfx.play("exp_m")
				game.shake(0.4)
			center.z += dt * 1.2
			if dying_t > 3.5:
				game.big_blast(center + CORE_OFF, 1.0, Models.STEEL_L)
				for k in 6:
					game.fx.explode(center + Vector3(randf_range(-12, 12), 0, randf_range(-3, 4)), 4.0, Vector3.ZERO, BeltModels.MINE)
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
	_belt(dt)
	for b in booms:
		_boom(b, dt)
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


## Phase A: a sweep by one wheel, vent fans, a needle burst, a boulder from
## the driver, the other wheel's sweep, vent fans, a second boulder, a
## quiet gap.
func _round_a() -> void:
	if _once("b1", 0.8):
		_sweep(_pick(cycle % 2))
	if _once("v1", 3.0):
		_vents(Bullets.BIG)
	if _once("v1s", 3.25):
		_vents(Bullets.SMALL)
	_core_needles("c", 3.9, 5, 18.0)
	_driver_shot("d1", 4.8)
	if _once("b2", 5.4):
		_sweep(_pick((cycle + 1) % 2))
	if _once("v2", 7.8):
		_vents(Bullets.BIG)
	if _once("v2s", 8.05):
		_vents(Bullets.SMALL)
	_driver_shot("d2", 8.4)


## RAMPAGE: forward and swaying; a shell spiral from the core, the rockfall
## twice, a three-way from the driver, a wide needle burst, both wheels
## sweeping at once if any are left (vent fans if not), a last boulder, a
## short quiet gap.
func _round_c(dt: float) -> void:
	center.z = move_toward(center.z, rest_z + RAGE_DOWN, 3.0 * dt)
	sway_t += dt
	center.x = move_toward(center.x, sin(sway_t * 0.7) * 3.5, 4.0 * dt)
	var cp := center + CORE_OFF
	if ((cycle_t > 0.4 and cycle_t < 2.8) or (cycle_t > 4.8 and cycle_t < 6.6)) and game.can_fire(cp):
		spiral_t -= dt
		if spiral_t <= 0.0:
			spiral_t = 0.15
			spiral_a += 0.39
			for arm in 2:
				game.bullets.fire(cp, spiral_a + arm * PI, 4.4, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if arm == 0 else Bullets.SMALL)
	_rockfall("f1", 1.0, 3)
	_driver_fan("t", 2.6)
	_core_needles("c", 3.4, 7, 34.0)
	_rockfall("f2", 4.4, 4)
	if _once("both", 5.4):
		if wheels_alive() > 0:
			for b in booms:
				_sweep(b)
		else:
			_vents(Bullets.BIG)
	if _once("both_s", 5.65) and wheels_alive() == 0:
		_vents(Bullets.SMALL)
	_driver_shot("d", 6.6, true)


func _rampage() -> void:
	phase = 3
	st = 0.0
	sway_t = 0.0
	_next_round()
	game.show_msg("DREDGE RAMPAGE", "", 1.5, true)
	game.shake(1.0)


## Which wheel sweeps: wheel k, or the other if k is gone.
func _pick(k: int) -> Dictionary:
	return booms[k] if not booms[k]["dead"] else booms[1 - k]


# ------------------------------------------------------------ the booms

## Direction of a boom at angle a (in the left boom's terms; the right one
## mirrors it).
func _dir(b: Dictionary, a: float) -> Vector3:
	var m := a if float(b["side"]) < 0.0 else PI - a
	return Vector3(cos(m), 0, sin(m))


func _pivot(b: Dictionary) -> Vector3:
	return center + PIVOT_OFF[0 if float(b["side"]) < 0.0 else 1]


## Where the wheel is with the boom at angle a, length l.
func _wheel_at(b: Dictionary, a: float, l: float) -> Vector3:
	return _pivot(b) + _dir(b, a) * l


func _smooth(f: float) -> float:
	f = clampf(f, 0.0, 1.0)
	return f * f * (3.0 - 2.0 * f)


## A sweep: the boom will reach out to the ship's distance from the pivot
## (at least MIN_R, at most the bottom of the screen), the arc runs from
## the edge of the screen through the ship's direction and PAST on. The
## lock-on and the whole path are marked (out to the start, then the arc),
## then the wind-up starts.
func _sweep(b: Dictionary) -> void:
	if b["dead"] or b["state"] != "rest":
		return
	var pv := _pivot(b)
	var sp := game.player.position
	var d := Vector2(sp.x - pv.x, sp.z - pv.z)
	var reach := clampf(d.length(), MIN_R, game.field_bottom - REACH_TO - pv.z)
	# the ship's direction in the left boom's terms
	var ship_a := atan2(d.y, d.x * float(b["side"]) * -1.0)
	# start just off the outer edge of the screen (or level, if it can't reach it)
	var edge := game.field_hw + 1.0
	var px := pv.x * -float(b["side"])  # the pivot's x, mirrored for the right boom
	var c := (-edge - px) / reach
	var start := acos(clampf(c, -1.0, 1.0)) if c >= -1.0 else PI
	start = clampf(maxf(start, ship_a + PAST), 1.2, PI)
	var end := clampf(ship_a - PAST, 0.25, start - 0.5)
	b["reach"] = reach
	b["start"] = start
	b["end"] = end
	b["sweep_t"] = clampf((start - end) / SWEEP_W, 0.7, 1.5)
	b["state"] = "wind"
	b["st"] = 0.0
	b["from_a"] = b["a"]
	b["from_l"] = b["l"]
	var path := PackedVector3Array()
	for k in 5:
		var f := _smooth(k / 4.0)
		path.append(_wheel_at(b, lerpf(b["a"], start, f), lerpf(b["l"], reach, f)))
	for k in range(1, 9):
		path.append(_wheel_at(b, lerpf(start, end, k / 8.0), reach))
	game.warn(b["wheel"], WIND_T, Game.Warn.MOVE, 1.9, path)
	game.sfx.play("slam")


func _boom(b: Dictionary, dt: float) -> void:
	b["st"] += dt
	var s: float = b["st"]
	var w: Enemy = b["wheel"]
	var moving := false
	match b["state"]:
		"rest":
			b["a"] = move_toward(b["a"], REST_A, 0.8 * dt)
			b["l"] = move_toward(b["l"], REST_L, 4.0 * dt)
		"wind":
			var f := _smooth(s / WIND_T)
			b["a"] = lerpf(b["from_a"], b["start"], f)
			b["l"] = lerpf(b["from_l"], b["reach"], f)
			moving = true
			if s >= WIND_T:
				_go(b, "sweep")
		"sweep":
			b["a"] = lerpf(b["start"], b["end"], _smooth(s / float(b["sweep_t"])))
			moving = true
			_spray(b, dt)
			if s >= float(b["sweep_t"]):
				_go(b, "hold")
				# it comes back along the same arc
				var path := PackedVector3Array()
				for k in 9:
					path.append(_wheel_at(b, lerpf(b["end"], b["start"], k / 8.0), b["reach"]))
				game.warn(w, HOLD_T, Game.Warn.MOVE, 1.9, path)
		"hold":
			if s >= HOLD_T:
				_go(b, "back")
		"back":
			b["a"] = lerpf(b["end"], b["start"], _smooth(s / BACK_T))
			moving = true
			if s >= BACK_T:
				_go(b, "stow")
		"stow":
			var f := _smooth(s / STOW_T)
			b["a"] = lerpf(b["start"], REST_A, f)
			b["l"] = lerpf(b["reach"], REST_L, f)
			moving = true
			if s >= STOW_T:
				_go(b, "rest")
		"dead":
			# a broken boom folds back
			var f := _smooth(s / 1.5)
			b["a"] = lerpf(b["from_a"], REST_A, f)
			b["l"] = lerpf(b["from_l"], REST_L * 0.8, f)
	if not b["dead"]:
		w.model.rotation.y += dt * (10.0 if moving else 4.0) * -float(b["side"])


func _go(b: Dictionary, s: String) -> void:
	b["state"] = s
	b["st"] = 0.0


## Gravel thrown out of the cutting wheel as it sweeps: slow shells out of
## the arc, away from the dredge (big and small by turns).
func _spray(b: Dictionary, dt: float) -> void:
	var w: Enemy = b["wheel"]
	b["spray_t"] -= dt
	if b["spray_t"] > 0.0 or not game.combat_on() or not game.on_field(w.position, -0.5):
		return
	b["spray_t"] = 0.09
	var out := w.position - _pivot(b)
	var k := int(b["st"] / 0.09)
	var a := atan2(out.z, out.x) + (0.45 if k % 2 == 0 else -0.45)
	game.bullets.fire(w.position, a, 2.8, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if k % 2 == 0 else Bullets.SMALL)


# ------------------------------------------------------------ belt and driver

## The belt brings the ore skips out of the adit, down the left side and
## across the front of the core; at the far end each runs into the loader
## and its rock loads the driver.
func _belt(dt: float) -> void:
	var v := 4.5 if phase == 3 else 3.0
	if phase != 4:
		skip_t -= dt
		if skip_t <= 0.0:
			skip_t = 1.6 if phase == 3 else 3.2
			_add_skip(0.0)
	var length := _belt_len()
	for o in skips.duplicate():
		var e: Enemy = o["e"]
		if o["drop"] >= 0.0:
			o["drop"] += dt
			if o["drop"] >= DROP_T:
				skips.erase(o)
				game.remove_enemy(e)
				e.queue_free()
				ammo = mini(ammo + 1, 3)
				continue
		else:
			o["s"] += v * dt
			if o["s"] >= length and phase != 4:
				# into the loader: out of the way
				o["drop"] = 0.0
				e.intangible = true
				e.ram = false
		_place_skip(o, dt)


func _belt_len() -> float:
	var l := 0.0
	for k in BELT.size() - 1:
		l += (BELT[k + 1] - BELT[k]).length()
	return l


## A skip's place: along the belt, facing the way it goes (turning round
## the corner), coming up out of the adit, or sinking into the loader.
func _place_skip(o: Dictionary, dt: float) -> void:
	var e: Enemy = o["e"]
	var s: float = o["s"]
	var p: Vector3 = BELT[BELT.size() - 1]
	var dir := Vector3(1, 0, 0)
	var acc := 0.0
	for k in BELT.size() - 1:
		var seg: float = (BELT[k + 1] - BELT[k]).length()
		if s <= acc + seg:
			p = (BELT[k] as Vector3).lerp(BELT[k + 1], (s - acc) / seg)
			dir = ((BELT[k + 1] as Vector3) - BELT[k]).normalized()
			break
		acc += seg
	var sc := lerpf(0.6, 1.0, _smooth(s / EMERGE))
	var y := 0.0
	if o["drop"] >= 0.0:
		var f := _smooth(o["drop"] / DROP_T)
		p = p.lerp(HOPPER, f)
		sc *= 1.0 - 0.4 * f
		y = -0.8 * f
	e.position = center + p
	e.hit_pos = e.position
	e.model.scale = Vector3.ONE * sc
	e.model.position.y = y
	var want := atan2(-dir.x, -dir.z)
	e.rotation.y = want if dt <= 0.0 else lerp_angle(e.rotation.y, want, clampf(5.0 * dt, 0.0, 1.0))


func _muzzle(dir: Vector3) -> Vector3:
	return driver.position + dir * 3.2


## A boulder from the driver, down a line marked at `at` and fired
## WINDUP_MOVE later (only if the belt brought one, unless `free`).
func _driver_shot(key: String, at: float, free := false) -> void:
	if _once("w_" + key, at):
		if (ammo <= 0 and not free) or not game.can_fire(driver.position):
			fired[key] = true
			return
		if not free:
			ammo -= 1
		aim_to = game.line_to_bottom(driver.position, game.player.position)
		game.warn(driver, Enemy.WINDUP_MOVE, Game.Warn.MOVE, driver.radius, aim_to)
		game.sfx.play("slam")
	if _once(key, at + Enemy.WINDUP_MOVE):
		var d := aim_to - driver.position
		d.y = 0.0
		_fire_boulder(_muzzle(d.normalized()), d.normalized() * BOULDER_SPEED)


## RAMPAGE: three boulders fanned out from the driver, each line marked.
func _driver_fan(key: String, at: float) -> void:
	if _once("w_" + key, at):
		if not game.can_fire(driver.position):
			fired[key] = true
			return
		var d := game.player.position - driver.position
		d.y = 0.0
		var base := atan2(d.z, d.x)
		fan_to.clear()
		for k in 3:
			var a := base + deg_to_rad(18.0) * (k - 1)
			var dir := Vector3(cos(a), 0, sin(a))
			var to := game.line_to_bottom(driver.position, driver.position + dir * 10.0)
			fan_to.append(to)
			fan_marks[k].position = _muzzle(dir) + dir * 1.5
			fan_marks[k].hit_pos = fan_marks[k].position
			game.warn(fan_marks[k], Enemy.WINDUP_MOVE, Game.Warn.MOVE, 0.9, to)
		game.sfx.play("slam")
	if _once(key, at + Enemy.WINDUP_MOVE) and fan_to.size() == 3:
		for k in 3:
			var d := fan_to[k] - driver.position
			d.y = 0.0
			_fire_boulder(_muzzle(d.normalized()), d.normalized() * BOULDER_SPEED)


func _fire_boulder(at: Vector3, v: Vector3, mesh := "meteor_a") -> void:
	if not game.combat_on():
		return
	game.spawn_enemy("boulder", {"x": at.x, "z": at.z, "vx": v.x, "vz": v.z, "spin": 2.5, "mesh": mesh})
	game.fx.flash(at + Vector3(0, 0.4, 0), 0.6)
	game.shake(0.3)


## RAMPAGE: the asteroid sheds `n` boulders down lanes scattered across the
## screen, one of them near the ship's; each lane is marked from the top
## edge to the bottom, one after another, and its boulder falls 0.8 s
## after its mark.
func _rockfall(key: String, at: float, n: int) -> void:
	if _once("p_" + key, at):
		falls.clear()
		var lim := game.hw_top - 1.5
		falls.append(clampf(game.player.position.x + randf_range(-1.2, 1.2), -lim, lim))
		var tries := 0
		while falls.size() < n and tries < 40:
			tries += 1
			var x := randf_range(-lim, lim)
			var ok := true
			for q: float in falls:
				if absf(q - x) < 3.4:
					ok = false
			if ok:
				falls.append(x)
		# in a scattered order, not left to right
		falls.shuffle()
	for k in falls.size():
		var t0 := at + k * 0.22
		if _once("w_%s%d" % [key, k], t0):
			var x: float = falls[k]
			lanes[k].position = Vector3(x, 0, game.field_top + 1.2)
			lanes[k].hit_pos = lanes[k].position
			game.warn(lanes[k], 0.8, Game.Warn.MOVE, 0.9, Vector3(x, 0, game.field_bottom + 1.0))
			if k == 0:
				game.sfx.play("slam")
		if _once("%s%d" % [key, k], t0 + 0.8):
			_fire_boulder(Vector3(falls[k], 0, game.field_top - 2.0), Vector3(0, 0, FALL_SPEED), "meteor_b" if k % 2 == 0 else "meteor_a")


# ------------------------------------------------------------ guns

## Both gravel vents: a fan of shells toward the ship (`size` BIG leads,
## SMALL follows).
func _vents(size: float) -> void:
	for o: Vector3 in VENT_OFF:
		var at := center + o + Vector3(0, 0, 0.8)
		if not game.can_fire(at):
			continue
		var off := 0.0 if size == Bullets.BIG else deg_to_rad(5.0)
		game.bullets.fan(at, game.bullets.aim(at) + off, 7 if size == Bullets.BIG else 6, 60.0 if size == Bullets.BIG else 54.0, 5.0 if size == Bullets.BIG else 5.6, Bullets.SHELL, self, Bullets.ROUND, size)


## The core's needle burst: announced at `at`, fired after the lock-on.
func _core_needles(key: String, at: float, count: int, spread: float) -> void:
	if _once("w_" + key, at):
		game.warn(core, Enemy.WINDUP_SHOT + 0.15, Game.Warn.SHOT, core.radius)
	if _once(key, at + Enemy.WINDUP_SHOT + 0.15):
		var p := core.position + Vector3(0, 0, 1.8)
		if game.can_fire(p):
			game.bullets.fan(p, game.bullets.aim(p), count, spread, 9.0, Bullets.ORB, self, Bullets.NEEDLE)


# ------------------------------------------------------------ placing

func _place(dt: float) -> void:
	hull.position = center
	core.position = center + CORE_OFF
	core.model.rotation.y += dt * (3.0 if phase == 3 else 1.2)
	for i in armour.size():
		armour[i].position = center + ARMOUR[i][0]
	driver.position = center + DRIVER_OFF
	loaded.visible = ammo > 0 and phase != 4
	var d := game.player.position - driver.position
	if d.length_squared() > 0.01 and phase != 4:
		driver.rotation.y = lerp_angle(driver.rotation.y, atan2(-d.x, -d.z), clampf(4.0 * dt, 0.0, 1.0))
	for b in booms:
		var p := _pivot(b)
		var dir := _dir(b, b["a"])
		var rot := atan2(dir.x, dir.z)
		var boom: MeshInstance3D = b["boom"]
		boom.position = p
		boom.rotation.y = rot
		var jib: MeshInstance3D = b["jib"]
		jib.position = p + dir * (float(b["l"]) - JIB_LEN)
		jib.rotation.y = rot
		if not b["dead"]:
			var w: Enemy = b["wheel"]
			w.position = p + dir * float(b["l"])
			w.hit_pos = w.position


func _parts() -> Array:
	var out: Array = [core, driver] + armour + lanes + fan_marks
	for o in skips:
		out.append(o["e"])
	for b in booms:
		out.append(b["wheel"])
	return out


func gauge() -> Dictionary:
	if phase < 1 or phase >= 4:
		return {}
	return {"frac": core.hp / core.max_hp, "color": Color(1.0, 0.82, 0.35), "name": INFO["name"], "name_color": Color(1.0, 0.9, 0.6), "x": 0.2, "w": 0.6, "h": 8.0, "name_y": 72.0}


func force_defeat() -> void:
	if phase < 4:
		core.armored = false
		game.kill(core)


## "A": straight into the fight, a wheel about to sweep. "C": into
## RAMPAGE, the wheels gone.
func viewer_skip(to: String) -> void:
	center.z = rest_z
	phase = 1
	st = 0.0
	_arm(false)
	if to == "A":
		cycle_t = 0.6
	elif to == "C":
		for b in booms:
			var w: Enemy = b["wheel"]
			w.dead = true
			game.remove_enemy(w)
			on_part_killed(w)
		_rampage()
	_place(0.0)


func debug_state() -> String:
	var names := ["enter", "A", "-", "RAMPAGE", "dying"]
	var bs := []
	for b in booms:
		bs.append("%s r%.0f" % [b["state"], b["reach"]])
	return "phase %s %.1fs  core %d/%d  wheels %s  belt %d  ammo %d  round %d %.1fs" % [names[phase], st, int(maxf(core.hp, 0.0)), int(CORE_HP), " / ".join(bs), skips.size(), ammo, cycle, cycle_t]


func _die() -> void:
	defeated = true
	phase = 4
	dying_t = 0.0
	for b in booms:
		if not b["dead"]:
			game.kill(b["wheel"])
	disarm()
	var conv := game.bullets.cancel_all()
	for q in conv:
		game.items.spawn(q, Items.ENERGY, 1.0)
	game.boss_dying()
