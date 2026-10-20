extends BossBase
## Stage 3 boss TITAN DREDGE: a strip-mining machine dug into a giant
## asteroid at the top of the screen. Its core (the only weak point, the
## gauge) turns in a bay in the middle of its front, and across the front
## runs the ore belt: boulders dug out of the asteroid ride it from the
## left, past the core (they take the shots: break them, or wait for a
## gap) to the hopper on the right, which feeds the mass driver. The driver
## turns on the ship and fires the boulders down a marked line to the
## bottom edge: every boulder broken on the belt is one it can't fire. Two
## cutter wheels on telescoping booms (tough; breaking them is the player's
## choice) take turns to sweep: a lock-on, the whole path marked (down the
## side and the arc), the boom reaches out to the bottom of the screen and
## the wheel sweeps an arc along the bottom from the edge to past the
## middle, throwing gravel shells out of it, holds, comes back along the
## same arc and stows: get above the arc (inside its reach) or out past its
## end. Gravel vents fire shell fans, the core telegraphed needle bursts,
## and every round ends in a quiet gap.
## RAMPAGE (both wheels broken, or after a while): it pushes forward and
## sways, the belt runs fast, the core spins a shell spiral, the asteroid
## sheds boulders down three marked lanes (the ship's and either side)
## twice a round, the driver fires three-way, a wide needle burst; wheels
## still up sweep both at once.

const INFO := {
	"name": "TITAN DREDGE", "role": "boss",
	"desc": "巨大な小惑星に食い込んだ採掘機。弱点は前の真ん中で回る核だけ。核の前をベルトコンベアが横切り、掘り出した岩塊が左から流れて弾を受け止める（壊せる）。右の端でホッパーに入った岩は質量投射機の弾になり、予兆（線）のあと自機のいた所へ下端まで撃ち出される（ベルトで壊した分だけ減る）。伸び縮みするブームの先の 2 つのカッターホイール（硬い）が交互に、予兆（道筋全体を示す）のあと画面の下端まで伸びて弧を描いて薙ぎ払い、物理弾の砂利を外へまき、同じ弧を戻る：弧の内側（上）か、弧の終わりの先へ逃げる。端の噴出口は扇状の物理弾、核は針弾。ホイールを両方失うか時間で発狂（RAMPAGE）：迫り出して揺れ、ベルトが速まり、核から渦巻き弾、小惑星から岩塊が 3 列（自機の列と両脇）に予兆つきで落ちてくる、投射機は 3 方向、広い針弾、残ったホイールは 2 つ同時に薙ぎ払う",
	"demos": [["FULL", ""], ["SWEEP", "A"], ["RAMPAGE", "C"]],
}
const CORE_HP := 2800.0
const CORE_SCORE := 60000
const WHEEL_HP := 520.0
const WHEEL_SCORE := 8000
const ORE_HP := 36.0
const ORE_SCORE := 400
const ORE_R := 1.25
const CORE_OFF := Vector3(0, 0, 1.4)
const PIVOT_OFF := [Vector3(-8.5, 0, -1.0), Vector3(8.5, 0, -1.0)]
const BELT_Z := 4.3
const BELT_X := 11.4  # the belt runs from -BELT_X to BELT_X
const DRIVER_OFF := Vector3(11.8, 0, 6.2)
const VENT_OFF := [Vector3(-12.9, 0, 1.8), Vector3(12.9, 0, 1.8)]
const ARMOUR := [[Vector3(-4.6, 0, 0.2), 2.6], [Vector3(4.6, 0, 0.2), 2.6], [Vector3(-10.4, 0, 0.0), 2.4], [Vector3(10.4, 0, 0.0), 2.4], [Vector3(0, 0, -2.4), 2.4]]
const JIB_LEN := 10.5
## a boom's angle (0 = +x, PI/2 = down-screen) for the left one; the right
## one mirrors it
const REST_A := 2.51  # stowed: up and out to the side
const START_A := 1.95  # a sweep starts with the wheel at the edge, low
const END_A := 0.97  # and ends past the middle
const REST_L := 6.5  # boom length stowed
const REACH_TO := 0.5  # a sweep reaches out to this far above the bottom edge
const WIND_T := 1.0
const SWEEP_T := 1.0
const HOLD_T := 0.35
const BACK_T := 1.5
const STOW_T := 1.2
const ROUND_A := 10.0
const ROUND_C := 8.0
const ENRAGE_T := 50.0
const RAGE_DOWN := 2.0
const LANE_GAP := 3.6
const BOULDER_SPEED := 15.0
const FALL_SPEED := 14.0

var hull: MeshInstance3D
var core: Enemy
var driver: Enemy
var armour: Array[Enemy] = []
var ores: Array[Enemy] = []  # boulders on the belt
var lanes: Array[Enemy] = []  # where the rockfall comes down (marked)
var fan_marks: Array[Enemy] = []  # the driver's three-way lines (marked)
## {wheel, boom, jib, side, a, l, state, st, from_a, from_l, spray_t, dead}
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
var ore_t := 0.0
var aim_to := Vector3.ZERO
var fan_to: Array[Vector3] = []
var fall_x := PackedFloat32Array()
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
			"from_a": REST_A, "from_l": REST_L, "reach": 19.0, "spray_t": 0.0, "dead": false})
	driver = game.spawn_part(self, "dredge_driver", 1.4)
	driver.armored = true
	driver.hp = 1e9
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
	for k in 3:
		for list: Array in [lanes, fan_marks]:
			var m := game.spawn_part(self, "", 0.9)
			m.intangible = true
			m.ram = false
			list.append(m)
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("dredge_hull")
	add_child(hull)
	# the belt already loaded as it comes in
	for x: float in [-8.0, -2.5, 3.0, 8.5]:
		_add_ore(x)
	_arm(true)
	_place(0.0)


func _add_ore(x: float) -> void:
	var e := game.spawn_part(self, "rock_l", ORE_R)
	e.hp = ORE_HP
	e.max_hp = ORE_HP
	e.score = ORE_SCORE
	e.energy_drop = 5.0
	e.blast = 1.8
	e.model.scale = Vector3.ONE * 0.82
	e.model.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
	e.position = center + Vector3(x, 0, BELT_Z)
	e.armored = phase == 0
	ores.append(e)


## While it comes in nothing can be hurt.
func _arm(on: bool) -> void:
	core.armored = on
	for b in booms:
		if not b["dead"]:
			(b["wheel"] as Enemy).armored = on
	for e in ores:
		e.armored = on


func on_hit(_e: Enemy, dmg: float) -> float:
	return 0.0 if defeated else dmg


func on_part_killed(e: Enemy) -> void:
	if e == core:
		_die()
		return
	if ores.has(e):
		ores.erase(e)
		e.queue_free()
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
## down three marked lanes twice, a three-way from the driver, a wide needle
## burst, both wheels sweeping at once if any are left (vent fans if not),
## a last boulder, a short quiet gap.
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
	_rockfall("f1", 1.0)
	_driver_fan("t", 2.4)
	_core_needles("c", 3.4, 7, 34.0)
	_rockfall("f2", 4.4)
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


## A sweep: the lock-on and the whole path marked (the reach down the side,
## then the arc), then the wind-up starts.
func _sweep(b: Dictionary) -> void:
	if b["dead"] or b["state"] != "rest":
		return
	b["state"] = "wind"
	b["st"] = 0.0
	b["from_a"] = b["a"]
	b["from_l"] = b["l"]
	# right down to the bottom of the screen, wherever the dredge is
	b["reach"] = game.field_bottom - REACH_TO - _pivot(b).z
	var path := PackedVector3Array()
	for k in 5:
		var f := _smooth(k / 4.0)
		path.append(_wheel_at(b, lerpf(b["a"], START_A, f), lerpf(b["l"], b["reach"], f)))
	for k in range(1, 9):
		path.append(_wheel_at(b, lerpf(START_A, END_A, k / 8.0), b["reach"]))
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
			b["a"] = lerpf(b["from_a"], START_A, f)
			b["l"] = lerpf(b["from_l"], b["reach"], f)
			moving = true
			if s >= WIND_T:
				_go(b, "sweep")
		"sweep":
			b["a"] = lerpf(START_A, END_A, _smooth(s / SWEEP_T))
			moving = true
			_spray(b, dt)
			if s >= SWEEP_T:
				_go(b, "hold")
				# it comes back along the same arc
				var path := PackedVector3Array()
				for k in 9:
					path.append(_wheel_at(b, lerpf(END_A, START_A, k / 8.0), b["reach"]))
				game.warn(w, HOLD_T, Game.Warn.MOVE, 1.9, path)
		"hold":
			if s >= HOLD_T:
				_go(b, "back")
		"back":
			b["a"] = lerpf(END_A, START_A, _smooth(s / BACK_T))
			moving = true
			if s >= BACK_T:
				_go(b, "stow")
		"stow":
			var f := _smooth(s / STOW_T)
			b["a"] = lerpf(START_A, REST_A, f)
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
		w.model.rotation.y += dt * (10.0 if moving else 2.5) * -float(b["side"])


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

## The belt carries boulders from the chute on the left to the hopper on
## the right; each that gets there is one more for the driver.
func _belt(dt: float) -> void:
	var v := 5.0 if phase == 3 else 3.0
	if phase != 4:
		ore_t -= dt
		if ore_t <= 0.0:
			ore_t = 1.0 if phase == 3 else 1.5
			_add_ore(-BELT_X)
	for e in ores.duplicate():
		e.position = Vector3(e.position.x + v * dt, 0, center.z + BELT_Z)
		e.position.x = maxf(e.position.x, center.x - BELT_X)
		e.hit_pos = e.position
		e.model.rotation.y += dt * 0.6
		if e.position.x > center.x + BELT_X:
			ores.erase(e)
			game.remove_enemy(e)
			e.queue_free()
			ammo = mini(ammo + 1, 3)


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


func _fire_boulder(at: Vector3, v: Vector3) -> void:
	if not game.combat_on():
		return
	game.spawn_enemy("boulder", {"x": at.x, "z": at.z, "vx": v.x, "vz": v.z, "spin": 2.5})
	game.fx.flash(at + Vector3(0, 0.4, 0), 0.6)
	game.shake(0.3)


## RAMPAGE: the asteroid sheds boulders down three lanes, the ship's and
## one either side, marked at `at` from the top edge to the bottom, falling
## 0.8 s later.
func _rockfall(key: String, at: float) -> void:
	if _once("w_" + key, at):
		var px := game.player.position.x
		fall_x = PackedFloat32Array()
		for k in 3:
			var x := clampf(px + (k - 1) * LANE_GAP, -game.hw_top + 1.5, game.hw_top - 1.5)
			fall_x.append(x)
			lanes[k].position = Vector3(x, 0, game.field_top + 1.2)
			lanes[k].hit_pos = lanes[k].position
			game.warn(lanes[k], 0.8, Game.Warn.MOVE, 0.9, Vector3(x, 0, game.field_bottom + 1.0))
		game.sfx.play("slam")
	if _once(key, at + 0.8) and fall_x.size() == 3:
		for k in 3:
			_fire_boulder(Vector3(fall_x[k], 0, game.field_top - 2.0 - k * 0.6), Vector3(0, 0, FALL_SPEED))


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
	var out: Array = [core, driver] + armour + lanes + fan_marks + ores
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
		bs.append(b["state"])
	return "phase %s %.1fs  core %d/%d  wheels %s  belt %d  ammo %d  round %d %.1fs" % [names[phase], st, int(maxf(core.hp, 0.0)), int(CORE_HP), "/".join(bs), ores.size(), ammo, cycle, cycle_t]


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
