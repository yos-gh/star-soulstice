extends BossBase
## Stage 4 boss BEHEMOTH: the enemy base's siege tank, in the arena at the
## bottom of the base. It rolls in on its tracks (they run on the arena's
## deck, which is raised for it) and keeps station facing the ship, creeping
## forward and back; the tracks turn with every move.
## The main turret (twin barrels, the main weapon) turns after the ship: a
## lock-on and the line marked to the bottom edge, then two armour-piercing
## slugs (IRON: they can't be shot or erased) down it, and the barrels
## recoil. Every shot vents the reactor: the cooling louvres over it (in the
## front of the hull, the only weak point, the gauge) slide aside for a
## while and the reactor can be hit; the louvres can also be broken. Its
## signature is the barrage: the two howitzers at the back lob shells high
## over the screen onto marked circles, one on the ship and the rest
## scattered; each lands with a blast (deadly inside its circle) and a ring
## of shells. The sponsons on the front fire shell fans (big, then small),
## the hull gun telegraphed needles. A quiet gap ends every round.
## BREAKTHROUGH (the main turret destroyed, or after a while): the reactor
## overheats and the louvres jam open; the tank charges, the dozer blade
## pushed down the screen to a marked line (five lines show the ground it
## covers) and backs off again, the barrage creeps down the ship's column
## toward the bottom edge, the reactor boils over in rings of shells, wide
## needles, a scattered barrage.

const INFO := {
	"name": "BEHEMOTH", "role": "boss",
	"desc": "敵基地の最深部、闘技場の床（ボス用に高くなっている）を履帯で走る攻城戦車。自機の方を向いて前後に這い、履帯が動く。主砲（連装、主兵装）は自機を追って旋回し、予兆（線）のあと下端まで徹甲弾（鉄球弾：撃ち落とせず、スピアでも消えない）を 2 発撃ち、砲身が後退する。撃つたびに車体前の反応炉（唯一の弱点）の冷却ルーバーが横へ開き、しばらく撃ち込める（ルーバーは壊すこともできる）。後ろの 2 門の榴弾砲は砲弾を画面の上へ高く放り、予兆（円）のところへ落とす：1 発は自機、残りは散らばる。着弾は円の中が爆風（当たると死ぬ）で、物理弾の輪が広がる。前の両脇の副砲から物理弾の扇（大きい弾が先）、車体の機銃から予兆つきの針弾。合間に静かな間。主砲を壊すか時間で BREAKTHROUGH：反応炉が過熱してルーバーが開きっぱなしになり、予兆（5 本の線）のあとドーザーブレードを押し立てて画面の下まで突進して戻る、着弾が自機の列を上から下へ追ってくる、反応炉から物理弾の輪、広い針弾、散らばった着弾",
	"demos": [["FULL", ""], ["BARRAGE", "A"], ["BREAKTHROUGH", "C"]],
}
const CORE_HP := 1000.0
const CORE_SCORE := 60000
const TURRET_HP := 520.0
const TURRET_SCORE := 10000
const SPONSON_HP := 200.0
const SPONSON_SCORE := 4000
const LOUVRE_HP := 160.0
const LOUVRE_SCORE := 5000
const TURRET_OFF := Vector3(0, 0, -1.8)
const CORE_OFF := Vector3(0, 0, 3.7)
const LOUVRE_SHUT := [Vector3(-0.68, 0, 3.7), Vector3(0.68, 0, 3.7)]
const LOUVRE_OPEN := [Vector3(-2.05, 0, 3.7), Vector3(2.05, 0, 3.7)]
const SPONSON_OFF := [Vector3(-4.7, 0, 2.6), Vector3(4.7, 0, 2.6)]
const HOWITZER_OFF := [Vector3(-4.2, 0, -3.6), Vector3(4.2, 0, -3.6)]  # the muzzles
const MG_OFF := Vector3(0, 0, 5.6)
const TRACK_X := 7.6
## armoured hit zones: the glacis either side of the reactor, the tracks,
## the engine deck
const ARMOUR := [[Vector3(-2.7, 0, 4.7), 1.0], [Vector3(2.7, 0, 4.7), 1.0],
	[Vector3(-7.6, 0, -4.0), 1.5], [Vector3(7.6, 0, -4.0), 1.5], [Vector3(-7.6, 0, 0.0), 1.5], [Vector3(7.6, 0, 0.0), 1.5],
	[Vector3(-7.6, 0, 4.0), 1.5], [Vector3(7.6, 0, 4.0), 1.5], [Vector3(0, 0, -5.0), 2.0]]
const BLADE_X := [-7.2, -3.6, 0.0, 3.6, 7.2]  # the charge's marked lines (from the blade)
const BLADE_HW := 8.9  # the blade: deadly to touch (it lets shots by: no hit zone)
const BLADE_Z := 6.8
const BARREL_LEN := 4.3  # turret centre to the muzzles
const BARREL_SEP := 0.55
const SLUG_SPEED := 15.0
const TURN_W := 0.9  # the turret's slew (rad/s)
const TURN_MAX := 1.05  # either side of straight down
const VENT_T := 3.4
const FLIGHT_T := 1.3
const IMPACT_R := 1.9
const LOB_PEAK := 8.0
const CHARGE := 7.0  # how far the BREAKTHROUGH charge comes down
const ROUND_A := 9.0
const ROUND_C := 8.0
const ENRAGE_T := 55.0
const TREAD_PITCH := 0.54
const TREAD_Y := -1.15

var hull: MeshInstance3D
var treads: Array[MeshInstance3D] = []
var tread_z := 0.0
var turret: Enemy
var barrels: MeshInstance3D
var recoil := 0.0
var turret_a := PI / 2.0  # where the main gun points (PI/2 = down-screen)
var turret_want := PI / 2.0
var lock_a := PI / 2.0
var lock_to := Vector3.ZERO
var locking := false
var core: Enemy
var louvres: Array[Enemy] = []
var open_f := 0.0  # the louvres: 0 shut, 1 aside
var vent_t := 0.0
var sponsons: Array[Enemy] = []
var armour: Array[Enemy] = []
var blade: Array[Enemy] = []
var marks: Array[Enemy] = []  # where the howitzer shells land (and the hull gun)
var mg: Enemy
## shells in flight: {m, from, to, t, mark}
var shells: Array[Dictionary] = []
var blasts: Array[Dictionary] = []  # {at, t}: deadly for a moment
var plan: Array = []  # this barrage's impact points
var center := Vector3.ZERO
var rest_z := 0.0
var last_z := 0.0
var creep_t := 0.0
var phase := 0  # 0 enter, 1 A, 3 BREAKTHROUGH, 4 dying
var st := 0.0
var fight_t := 0.0
var cycle_t := 0.0
var cycle := 0
var fired := {}
var charge := ""  # "", warn, go, hold, back
var charge_t := 0.0
var how_k := 0
var dying_t := 0.0
var destroyed := false


func setup(g: Game) -> void:
	game = g
	rest_z = game.field_top + 7.0
	center = Vector3(0, 0, game.field_top - 14.0)
	last_z = center.z
	# order matters (a shot hits the first part in the list it touches): the
	# louvres over the reactor, the reactor, the guns, the armour last
	for k in 2:
		var l := game.spawn_part(self, "behemoth_louvre", 0.9)
		l.hp = LOUVRE_HP
		l.max_hp = LOUVRE_HP
		l.score = LOUVRE_SCORE
		l.energy_drop = 10.0
		l.blast = 2.0
		if k == 1:
			l.model.scale = Vector3(-1, 1, 1)
		louvres.append(l)
	core = game.spawn_part(self, "behemoth_core", 1.3)
	core.hp = CORE_HP
	core.max_hp = CORE_HP
	core.score = CORE_SCORE
	core.blast = 6.0
	core.ram = false
	for o: Vector3 in SPONSON_OFF:
		var s := game.spawn_part(self, "behemoth_sponson", 1.2)
		s.hp = SPONSON_HP
		s.max_hp = SPONSON_HP
		s.score = SPONSON_SCORE
		s.energy_drop = 10.0
		s.blast = 2.4
		sponsons.append(s)
	turret = game.spawn_part(self, "behemoth_turret", 2.5)
	turret.hp = TURRET_HP
	turret.max_hp = TURRET_HP
	turret.score = TURRET_SCORE
	turret.energy_drop = 16.0
	turret.blast = 3.6
	barrels = MeshInstance3D.new()
	barrels.mesh = Vox.get_mesh("behemoth_barrels")
	turret.add_child(barrels)
	turret.extra.append(barrels)
	for a: Array in ARMOUR:
		var e := game.spawn_part(self, "", a[1])
		e.armored = true
		e.hp = 1e9
		armour.append(e)
	for x: float in BLADE_X:
		var e := game.spawn_part(self, "", 1.2)
		e.armored = true
		e.hp = 1e9
		e.shootable = false
		blade.append(e)
	for k in 8:
		var m := game.spawn_part(self, "", IMPACT_R)
		m.intangible = true
		m.ram = false
		marks.append(m)
	mg = game.spawn_part(self, "", 0.9)
	mg.intangible = true
	mg.ram = false
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("behemoth_hull")
	add_child(hull)
	for s: float in [-1.0, 1.0]:
		var t := MeshInstance3D.new()
		t.mesh = Vox.get_mesh("behemoth_tread")
		hull.add_child(t)
		t.position = Vector3(s * TRACK_X, TREAD_Y, 0)
		treads.append(t)
	_arm(true)
	_place(0.0)


## While it rolls in nothing can be hurt.
func _arm(on: bool) -> void:
	for e: Enemy in [core, turret] + sponsons + louvres:
		if not e.dead:
			e.armored = on


func on_hit(_e: Enemy, dmg: float) -> float:
	return 0.0 if defeated else dmg


func on_part_killed(e: Enemy) -> void:
	if e == core:
		_die()
		return
	game.shake(0.7)
	if e == turret:
		locking = false
		if phase == 1:
			_breakthrough()


func _louvres_alive() -> int:
	var c := 0
	for l in louvres:
		if not l.dead:
			c += 1
	return c


func tick(dt: float) -> void:
	if destroyed:
		return
	st += dt
	match phase:
		0:
			center.z = move_toward(center.z, rest_z, 5.0 * dt)
			if st > 4.6:
				phase = 1
				st = 0.0
				_arm(false)
				game.boss_fight_started()
		1:
			fight_t += dt
			cycle_t += dt
			_creep(dt)
			_round_a()
			if cycle_t >= ROUND_A:
				_next_round()
			if fight_t > ENRAGE_T:
				_breakthrough()
		3:
			fight_t += dt
			cycle_t += dt
			_charge(dt)
			_round_c()
			if cycle_t >= ROUND_C:
				_next_round()
		4:
			_dying(dt)
			if destroyed:
				return
	_aim(dt)
	_vent(dt)
	_shells(dt)
	_place(dt)
	if phase == 1 or phase == 3:
		_blade_touch()


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


## Creeps forward and back a little round its station (eased).
func _creep(dt: float) -> void:
	creep_t += dt
	center.z = move_toward(center.z, rest_z + sin(creep_t * 0.4) * 1.0, 2.0 * dt)


## Phase A: sponson fans, the main gun, the barrage, the hull gun, fans
## again, the main gun again; quiet.
func _round_a() -> void:
	if _once("f1", 0.5):
		_sponson_fans(Bullets.BIG)
	if _once("f1s", 0.75):
		_sponson_fans(Bullets.SMALL)
	_main_gun("g1", 1.2)
	_barrage("b1", 2.8, 4, false)
	_hull_gun("mg", 5.0, 3, 14.0)
	if _once("f2", 5.6):
		_sponson_fans(Bullets.BIG)
	if _once("f2s", 5.85):
		_sponson_fans(Bullets.SMALL)
	_main_gun("g2", 6.4)


## BREAKTHROUGH: the charge, the barrage creeping down the ship's column,
## rings of shells boiling out of the reactor, wide needles, a scattered
## barrage; sponson fans while they last.
func _round_c() -> void:
	if _once("c", 0.3):
		_charge_warn()
	if _once("f", 1.2):
		_sponson_fans(Bullets.BIG)
	if _once("fs", 1.45):
		_sponson_fans(Bullets.SMALL)
	# (the main gun, if it is still there: BREAKTHROUGH on time)
	_main_gun("g", 2.6)
	var cp := core.position + Vector3(0, 0, 1.2)
	for k in 3:
		if _once("ring%d" % k, 3.0 + k * 0.4) and game.can_fire(cp):
			game.bullets.ring(cp, 16, 4.6, Bullets.SHELL, self, fight_t * 0.8 + k * 0.2, 2, fight_t * 1.9 + k * 1.3)
	_barrage("col", 4.4, 5, true)
	_hull_gun("mg", 5.6, 7, 34.0)
	_barrage("sc", 6.4, 4, false)


func _breakthrough() -> void:
	phase = 3
	st = 0.0
	_next_round()
	vent_t = 0.0
	game.show_msg("BEHEMOTH BREAKTHROUGH", "", 1.5, true)
	game.shake(1.0)


# ------------------------------------------------------------ the main gun

## The turret turns after the ship (within its arc); while a shot is
## locked it turns fast onto the locked line.
func _aim(dt: float) -> void:
	if turret.dead or phase == 4:
		return
	if not locking:
		var d := game.player.position - (center + TURRET_OFF)
		turret_want = clampf(atan2(d.z, d.x), PI / 2.0 - TURN_MAX, PI / 2.0 + TURN_MAX)
	var w := 3.2 if locking else TURN_W
	turret_a = turret_a + clampf(wrapf(turret_want - turret_a, -PI, PI), -w * dt, w * dt)
	recoil = maxf(0.0, recoil - dt * 1.6)


func _muzzle_dir() -> Vector3:
	return Vector3(cos(turret_a), 0, sin(turret_a))


## Locks on at `at` (the line marked to the bottom edge), fires two slugs
## down it 0.9 s later.
func _main_gun(key: String, at: float) -> void:
	if turret.dead:
		return
	if _once("w_" + key, at):
		if not game.can_fire(turret.position):
			fired[key] = true
			return
		var d := game.player.position - (center + TURRET_OFF)
		lock_a = clampf(atan2(d.z, d.x), PI / 2.0 - TURN_MAX, PI / 2.0 + TURN_MAX)
		turret_want = lock_a
		locking = true
		var dir := Vector3(cos(lock_a), 0, sin(lock_a))
		var mz := center + TURRET_OFF + dir * BARREL_LEN
		lock_to = game.line_to_bottom(mz, mz + dir * 10.0)
		game.warn(turret, 0.9, Game.Warn.MOVE, turret.radius, lock_to)
		game.sfx.play("slam")
	if _once(key, at + 0.9):
		locking = false
		if turret.dead or not game.combat_on():
			return
		turret_a = lock_a
		var dir := _muzzle_dir()
		var side := Vector3(-dir.z, 0, dir.x) * BARREL_SEP
		for s: float in [-1.0, 1.0]:
			var mz := center + TURRET_OFF + dir * BARREL_LEN + side * s
			game.bullets.fire(mz, lock_a, SLUG_SPEED, Bullets.IRON, self)
			game.fx.sprite(mz + Vector3(0, 0.6, 0), dir * 3.0, 1.6, 0.4, 0.14, Color(1.0, 0.85, 0.6), 0.0)
		game.fx.flash(center + TURRET_OFF + dir * BARREL_LEN, 2.0)
		game.sfx.play("exp_m")
		game.shake(0.6)
		recoil = 1.0
		# the shot vents the reactor
		vent_t = VENT_T


## The louvres slide aside while the reactor vents (and stay aside in
## BREAKTHROUGH); with both in place and shut the reactor can't be hurt.
func _vent(dt: float) -> void:
	vent_t = maxf(0.0, vent_t - dt)
	var want := 1.0 if (vent_t > 0.0 or phase == 3 or phase == 4) else 0.0
	open_f = move_toward(open_f, want, dt * 2.5)
	if phase == 1 or phase == 3:
		core.armored = open_f < 0.5 and _louvres_alive() == 2
	if open_f > 0.5 and phase != 4 and randf() < 0.12:
		# heat haze out of the vent
		game.fx.puff(core.position + Vector3(randf_range(-0.8, 0.8), 0.5, 0.3), Vector3(0, 0, 2.0), 0.4, 1.2, 0.5, Fx.SMOKE)


# ------------------------------------------------------------ the barrage

## The howitzers lob `n` shells, one after another from the back corners:
## onto the ship and scattered round the screen, or (`column`) down the
## ship's column from the top toward the bottom edge. Each lands FLIGHT_T
## after it is fired, its circle marked till then.
func _barrage(key: String, at: float, n: int, column: bool) -> void:
	if _once("p_" + key, at):
		plan.clear()
		var sp := game.player.position
		var lim := game.hw_bottom - 2.0
		if column:
			var z := game.field_top + 14.5
			while plan.size() < n and z < game.field_bottom - 1.0:
				plan.append(Vector3(clampf(sp.x + randf_range(-0.6, 0.6), -lim, lim), 0, z))
				z += 2.9
		else:
			plan.append(Vector3(clampf(sp.x, -lim, lim), 0, clampf(sp.z, game.field_top + 15.0, game.field_bottom - 1.5)))
			var tries := 0
			while plan.size() < n and tries < 60:
				tries += 1
				var q := Vector3(randf_range(-lim, lim), 0, randf_range(game.field_top + 15.0, game.field_bottom - 1.5))
				var ok := true
				for o: Vector3 in plan:
					if o.distance_to(q) < 4.2:
						ok = false
				if ok:
					plan.append(q)
	var stagger := 0.26 if column else 0.2
	for k in plan.size():
		if _once("%s%d" % [key, k], at + 0.1 + k * stagger):
			_lob(plan[k])


func _lob(to: Vector3) -> void:
	if not game.combat_on():
		return
	var mark: Enemy = null
	for m in marks:
		if not m.has_meta("busy"):
			mark = m
			break
	if mark == null:
		return
	mark.set_meta("busy", true)
	mark.position = to
	mark.hit_pos = to
	game.warn(mark, FLIGHT_T, Game.Warn.MOVE, IMPACT_R, {"r": IMPACT_R}, how_k % 2 == 0)
	var from: Vector3 = center + HOWITZER_OFF[how_k % 2]
	how_k += 1
	var m := MeshInstance3D.new()
	m.mesh = Vox.get_mesh("behemoth_shell")
	game.units.add_child(m)
	m.position = from
	shells.append({"m": m, "from": from, "to": to, "t": 0.0, "mark": mark})
	game.fx.sprite(from + Vector3(0, 1.0, 0), Vector3(0, 0, -2.0), 1.3, 0.3, 0.12, Color(1.0, 0.85, 0.6), 0.0)
	game.fx.smoke(from + Vector3(0, 0.6, 0), Vector3(0, 0, -1.5), 0.8)
	game.sfx.play("hit")


func _shells(dt: float) -> void:
	for s in shells.duplicate():
		s["t"] += dt
		var f := clampf(float(s["t"]) / FLIGHT_T, 0.0, 1.0)
		var m: MeshInstance3D = s["m"]
		var from: Vector3 = s["from"]
		var to: Vector3 = s["to"]
		var p := from.lerp(to, f)
		p.y = LOB_PEAK * 4.0 * f * (1.0 - f)
		m.position = p
		m.rotation.x = lerpf(-0.9, 0.9, f)
		if f >= 1.0:
			shells.erase(s)
			m.queue_free()
			(s["mark"] as Enemy).remove_meta("busy")
			_impact(to)
	for b in blasts.duplicate():
		b["t"] -= dt
		var d: Vector3 = game.player.position - (b["at"] as Vector3)
		if Vector2(d.x, d.z).length() < IMPACT_R + Player.HIT_R and game.combat_on():
			game.touch_player("barrage")
		if b["t"] <= 0.0:
			blasts.erase(b)


## A shell lands: a blast deadly inside its circle for a moment, a ring of
## shells out of it.
func _impact(at: Vector3) -> void:
	blasts.append({"at": at, "t": 0.12})
	game.fx.explode(at + Vector3(0, 0.4, 0), 1.2, Vector3.ZERO, Models.GUN)
	game.fx.shockwave(at + Vector3(0, 0.3, 0), IMPACT_R, Color(1.0, 0.8, 0.55))
	game.sfx.play("exp_m")
	game.shake(0.35)
	if game.combat_on():
		game.bullets.ring(at, 6, 3.8, Bullets.SHELL, self, randf() * TAU)


# ------------------------------------------------------------ other guns

## Both sponsons: a fan of shells at the ship (`size` BIG leads, SMALL
## follows).
func _sponson_fans(size: float) -> void:
	for s in sponsons:
		if s.dead:
			continue
		var at := s.position + Vector3(0, 0, 1.0)
		if not game.can_fire(at):
			continue
		var off := 0.0 if size == Bullets.BIG else deg_to_rad(5.0)
		game.bullets.fan(at, game.bullets.aim(at) + off, 5 if size == Bullets.BIG else 4, 46.0 if size == Bullets.BIG else 40.0, 5.0 if size == Bullets.BIG else 5.6, Bullets.SHELL, self, Bullets.ROUND, size)


## The hull gun under the glacis: announced at `at`, a needle burst after
## the lock-on.
func _hull_gun(key: String, at: float, count: int, spread: float) -> void:
	if _once("w_" + key, at):
		game.warn(mg, Enemy.WINDUP_SHOT + 0.15, Game.Warn.SHOT, 0.9)
	if _once(key, at + Enemy.WINDUP_SHOT + 0.15):
		var p := mg.position
		if game.can_fire(p):
			game.bullets.fan(p, game.bullets.aim(p), count, spread, 9.0, Bullets.ORB, self, Bullets.NEEDLE)


# ------------------------------------------------------------ the charge

## BREAKTHROUGH's charge: five lines marked from the blade down to where
## its edge will stop, then it drives down there, holds, and backs off.
func _charge_warn() -> void:
	charge = "warn"
	charge_t = 0.0
	for k in blade.size():
		var e := blade[k]
		game.warn(e, 0.9, Game.Warn.MOVE, 1.2, Vector3(e.position.x, 0, rest_z + CHARGE + BLADE_Z + 0.6), k == 2)
	game.sfx.play("slam")


func _charge(dt: float) -> void:
	charge_t += dt
	match charge:
		"warn":
			center.z = move_toward(center.z, rest_z, 3.0 * dt)
			if charge_t >= 0.9:
				charge = "go"
				charge_t = 0.0
				game.shake(0.8)
		"go":
			var f := clampf(charge_t / 0.9, 0.0, 1.0)
			if charge_t <= dt * 1.5:
				# (the autopilot keeps off the ground it covers while it goes)
				for e in blade:
					game.warn(e, 1.3, Game.Warn.MOVE, 1.2, Vector3(e.position.x, 0, rest_z + CHARGE + BLADE_Z + 0.6), false)
			center.z = rest_z + CHARGE * f * f * (3.0 - 2.0 * f)
			if int(charge_t * 12.0) != int((charge_t - dt) * 12.0):
				game.fx.puff(center + Vector3(randf_range(-8.0, 8.0), 0.2, BLADE_Z), Vector3(0, 0, 3.0), 0.8, 2.2, 0.6, Fx.SMOKE)
			if f >= 1.0:
				charge = "hold"
				charge_t = 0.0
		"hold":
			if charge_t >= 0.4:
				charge = "back"
				charge_t = 0.0
		"back":
			var f := clampf(charge_t / 1.8, 0.0, 1.0)
			center.z = rest_z + CHARGE * (1.0 - f * f * (3.0 - 2.0 * f))
			if f >= 1.0:
				charge = ""
		_:
			_creep(dt)


## The dozer blade across the front: touching it is a crash (it has no
## hit zone, so shots go by it on to the reactor).
func _blade_touch() -> void:
	var p := game.player.position
	var b := center + Vector3(0, 0, BLADE_Z)
	if absf(p.x - b.x) < BLADE_HW + Player.HIT_R and absf(p.z - b.z) < 0.5 + Player.HIT_R:
		game.touch_player("dozer")


# ------------------------------------------------------------ placing

func _place(dt: float) -> void:
	# the tracks: the top run moves with the tank over the deck (the deck
	# scrolls by under it)
	var vz := (center.z - last_z) / maxf(dt, 0.0001) if dt > 0.0 else 0.0
	last_z = center.z
	if phase != 4 or dying_t < 2.5:
		tread_z += (vz - game.scroll_speed * (1.0 if phase != 4 else maxf(0.0, 1.0 - dying_t / 2.5))) * dt
	for t in treads:
		t.position.z = fposmod(tread_z, TREAD_PITCH) - TREAD_PITCH * 0.5
	hull.position = center
	core.position = center + CORE_OFF
	core.model.rotation.y += dt * (2.8 if phase == 3 else 1.0)
	for k in 2:
		if not louvres[k].dead:
			louvres[k].position = center + (LOUVRE_SHUT[k] as Vector3).lerp(LOUVRE_OPEN[k], open_f)
	for k in 2:
		if not sponsons[k].dead:
			var s := sponsons[k]
			s.position = center + SPONSON_OFF[k]
			var d := game.player.position - s.position
			s.rotation.y = lerp_angle(s.rotation.y, atan2(d.x, d.z), clampf(3.0 * dt, 0.0, 1.0))
	if not turret.dead:
		turret.position = center + TURRET_OFF
		turret.rotation.y = atan2(cos(turret_a), sin(turret_a))
		barrels.position.z = -0.6 * recoil
	for k in armour.size():
		armour[k].position = center + ARMOUR[k][0]
	for k in blade.size():
		blade[k].position = center + Vector3(BLADE_X[k], 0, BLADE_Z)
		blade[k].hit_pos = blade[k].position
	mg.position = center + MG_OFF
	mg.hit_pos = mg.position


func _parts() -> Array:
	return [core, turret] + louvres + sponsons + armour + blade + marks + [mg]


func gauge() -> Dictionary:
	if phase < 1 or phase >= 4:
		return {}
	return {"frac": core.hp / core.max_hp, "color": Color(1.0, 0.86, 0.5), "name": INFO["name"], "name_color": Color(1.0, 0.92, 0.7), "x": 0.2, "w": 0.6, "h": 8.0, "name_y": 72.0}


func force_defeat() -> void:
	if phase < 4:
		core.armored = false
		game.kill(core)


## "A": straight into the fight, the barrage about to fly. "C": into
## BREAKTHROUGH, the main turret gone.
func viewer_skip(to: String) -> void:
	center.z = rest_z
	phase = 1
	st = 0.0
	_arm(false)
	if to == "A":
		cycle_t = 2.6
	elif to == "C":
		turret.dead = true
		game.remove_enemy(turret)
		on_part_killed(turret)
	_place(0.0)


func debug_state() -> String:
	var names := ["enter", "A", "-", "BREAKTHROUGH", "dying"]
	return "phase %s %.1fs  core %d/%d  turret %s  louvres %d (open %.1f)  sponsons %d  shells %d  round %d %.1fs" % [names[phase], st, int(maxf(core.hp, 0.0)), int(CORE_HP), "dead" if turret.dead else "%d" % int(turret.hp), _louvres_alive(), open_f, sponsons.filter(func(s: Enemy) -> bool: return not s.dead).size(), shells.size(), cycle, cycle_t]


func _die() -> void:
	defeated = true
	phase = 4
	dying_t = 0.0
	charge = ""
	for e: Enemy in [turret] + sponsons + louvres:
		if not e.dead:
			game.kill(e)
	for s in shells:
		(s["m"] as MeshInstance3D).queue_free()
	shells.clear()
	blasts.clear()
	disarm()
	var conv := game.bullets.cancel_all()
	for q in conv:
		game.items.spawn(q, Items.ENERGY, 1.0)
	game.boss_dying()


## Done for: the drive dies and the deck carries the wreck slowly down
## the screen while it blows up piece by piece, then the last blast.
func _dying(dt: float) -> void:
	dying_t += dt
	center.z += game.scroll_speed * clampf(dying_t / 2.5, 0.0, 1.0) * 0.45 * dt
	if int(dying_t * 8.0) != int((dying_t - dt) * 8.0):
		var off := Vector3(randf_range(-8.5, 8.5), 0, randf_range(-6.0, 6.0))
		game.fx.explode(center + off, randf_range(1.5, 3.0), Vector3.ZERO, Models.GUN)
		game.sfx.play("exp_m")
		game.shake(0.4)
	if dying_t > 3.5:
		game.big_blast(center + CORE_OFF, 1.0, Models.GUN)
		for k in 6:
			game.fx.explode(center + Vector3(randf_range(-8, 8), 0, randf_range(-5, 5)), 4.0, Vector3.ZERO, PlanetModels.SAND)
		game.sfx.play("exp_l")
		game.shake(2.0)
		destroyed = true
		finished = true
		visible = false
		for q in _parts():
			game.remove_enemy(q)
			q.visible = false
		game.boss_destroyed(self)
