extends BossBase
## Stage 4 boss BEHEMOTH: the enemy base's siege tank, in the arena at the
## bottom of the base. It rolls in on its tracks (they run on the arena's
## deck, which is raised for it) and keeps station facing the ship, creeping
## forward and back; the tracks turn with every move.
## The main turret (twin barrels, the main weapon) stands at the front of
## the hull, right over the reactor behind it (the weak point): the reactor
## is sealed under the turret's ring until the turret is destroyed, so the
## guns go first. The turret turns after the ship: a lock-on and the line
## marked to the bottom edge, then two armour-piercing slugs (IRON: they
## can't be shot or erased) down it, and the barrels recoil. The howitzers
## at the back lob shells high over the screen onto marked circles, one on
## the ship and the rest scattered; each lands with a blast (deadly inside
## its circle) and a ring of shells. The sponsons fire shell fans (big,
## then small), the hull gun telegraphed needles. Once a round it charges:
## the corridor its dozer blade will sweep is marked down to the bottom edge
## (edged, filling as the charge nears, chevrons streaming down it), then
## it drives the blade down to the bottom of the screen (get out to the
## side) and backs off.
## OVERRUN (the main turret destroyed, or after a while): the reactor is
## laid open and the tank goes wild. It pivots on its tracks to face the
## ship and charges along that heading to the edge of the screen (the
## corridor marked first), and it spins round on the spot (neutral steer,
## a full turn: the circle it sweeps is marked): the blade and the hull
## swing round, the sponsons and the open reactor spray shells outward as
## they turn (the reactor out of both flanks), a spiral wound by the turning
## hull. The howitzers fire four barrages a round (one down the ship's
## column), the reactor spits shell fans while the tank charges, the hull
## gun fires wide needles.

const INFO := {
	"name": "BEHEMOTH", "role": "boss",
	"desc": "敵基地の最深部、闘技場の床（ボス用に高くなっている）を履帯で走る攻城戦車。主砲塔（連装、主兵装）は車体の前にあり、その奥の反応炉（弱点）は砲塔が残っているあいだ砲塔の台座に封じられている：先に砲を落とす。主砲は自機を追って旋回し、予兆（線）のあと下端まで徹甲弾（鉄球弾：撃ち落とせず、スピアでも消えない）を 2 発。後ろの榴弾砲は砲弾を高く放り、予兆（円）のところへ落とす（1 発は自機、残りは散らばる。円の中は爆風、物理弾の輪が広がる）。副砲から物理弾の扇、車体の機銃から針弾。1 周に 1 回、ドーザーブレードが通る帯（下端まで、突進が近づくと満ちていく）の予兆のあと画面の下まで突進して戻る（横へ逃げる）。主砲塔を壊すか時間で OVERRUN：反応炉がむき出しになり、履帯で向きを変えて自機の方へ画面の端まで突進（通り道を予兆）、その場で一回転（超信地旋回：届く円を予兆）しながら副砲と反応炉から物理弾を外へ撒く（回る車体が渦を描く）。着弾が自機の列を上から追い、反応炉から広い針弾",
	"demos": [["FULL", ""], ["CHARGE", "A"], ["OVERRUN", "C"]],
}
const CORE_HP := 540.0
const CORE_SCORE := 60000
const TURRET_HP := 520.0
const TURRET_SCORE := 10000
const SPONSON_HP := 180.0
const SPONSON_SCORE := 4000
const TURRET_OFF := Vector3(0, 0, 2.3)
const CORE_OFF := Vector3(0, 0, -1.9)
const SPONSON_OFF := [Vector3(-5.3, 0, 4.0), Vector3(5.3, 0, 4.0)]
const HOWITZER_OFF := [Vector3(-4.2, 0, -3.6), Vector3(4.2, 0, -3.6)]  # the muzzles
const MG_OFF := Vector3(0, 0, 5.3)
const TRACK_X := 7.6
## armoured hit zones: the tracks, the engine deck
const ARMOUR := [[Vector3(-7.6, 0, -4.0), 1.5], [Vector3(7.6, 0, -4.0), 1.5], [Vector3(-7.6, 0, 0.0), 1.5], [Vector3(7.6, 0, 0.0), 1.5],
	[Vector3(-7.6, 0, 4.0), 1.5], [Vector3(7.6, 0, 4.0), 1.5], [Vector3(0, 0, -5.3), 1.6]]
const BLADE_X := [-7.2, -3.6, 0.0, 3.6, 7.2]  # the dozer blade's ram zones
const BLADE_HW := 8.9  # the blade: deadly to touch (it lets shots by: no hit zone)
const BLADE_Z := 6.8
const BARREL_LEN := 4.2  # turret centre to the muzzles
const BARREL_SEP := 0.55
const SLUG_SPEED := 15.0
const TURN_W := 0.9  # the turret's slew (rad/s)
const TURN_MAX := 1.1  # either side of the hull's heading
const FLIGHT_T := 1.3
const IMPACT_R := 1.9
const LOB_PEAK := 8.0
const LUNGE_WARN := 1.0  # the charge: marked (and the hull pivoting) ...
const LUNGE_GO := 0.8  # ... down there ...
const LUNGE_HOLD := 0.3
const LUNGE_BACK := 1.6  # ... and back
const AIM_MAX := 0.75  # OVERRUN's charge: how far it pivots toward the ship
const SPIN_R := 11.8  # the circle a turn on the spot sweeps (the blade's corners)
const CRUSH_R := 9.6  # what it rolls over (a circle round the hull)
const SPIN_WARN := 1.0
const SPIN_T := 2.6
const ROUND_A := 10.0
const ROUND_C := 10.0
const ENRAGE_T := 60.0
const TREAD_PITCH := 0.54
const TREAD_Y := -1.15

var hull: MeshInstance3D
var shutters: Array[MeshInstance3D] = []  # over the reactor while it is sealed
var seal_f := 1.0  # 1 shut, 0 slid aside
var treads: Array[MeshInstance3D] = []
var tread_z := [0.0, 0.0]
var turret: Enemy
var barrels: MeshInstance3D
var recoil := 0.0
var turret_a := PI / 2.0  # where the main gun points (PI/2 = down-screen)
var turret_want := PI / 2.0
var lock_a := PI / 2.0
var locking := false
var core: Enemy
var sponsons: Array[Enemy] = []
var armour: Array[Enemy] = []
var blade: Array[Enemy] = []
var marks: Array[Enemy] = []  # where the howitzer shells land
var mg: Enemy
var hub: Enemy  # the tank's centre (the spin's marked circle)
## shells in flight: {m, from, to, t, mark}
var shells: Array[Dictionary] = []
var blasts: Array[Dictionary] = []  # {at, t}: deadly for a moment
var plans := {}  # each barrage's impact points (by its key)
var center := Vector3.ZERO
var yaw := 0.0  # the hull's heading (0 = facing down-screen)
var rest_z := 0.0
var last_c := Vector3.ZERO
var last_yaw := 0.0
var creep_t := 0.0
var phase := 0  # 0 enter, 1 A, 3 OVERRUN, 4 dying
var st := 0.0
var fight_t := 0.0
var cycle_t := 0.0
var cycle := 0
var fired := {}
## the charge: "", warn, go, hold, back, turn (back to facing down)
var lunge := ""
var lunge_t := 0.0
var lunge_yaw := 0.0
var lunge_from := Vector3.ZERO
var lunge_to := Vector3.ZERO
var spin := ""  # "", warn, go
var spin_t := 0.0
var spin_dir := 1.0
var spray_t := 0.0
var spray_k := 0
var how_k := 0
var dying_t := 0.0
var destroyed := false


func setup(g: Game) -> void:
	game = g
	rest_z = game.field_top + 7.0
	center = Vector3(0, 0, game.field_top - 14.0)
	last_c = center
	# order matters (a shot hits the first part in the list it touches): the
	# guns, the reactor, the armour last
	for o: Vector3 in SPONSON_OFF:
		var s := game.spawn_part(self, "behemoth_sponson", 1.2)
		s.hp = SPONSON_HP
		s.max_hp = SPONSON_HP
		s.score = SPONSON_SCORE
		s.energy_drop = 10.0
		s.blast = 2.4
		sponsons.append(s)
	turret = game.spawn_part(self, "behemoth_turret", 2.4)
	turret.hp = TURRET_HP
	turret.max_hp = TURRET_HP
	turret.score = TURRET_SCORE
	turret.energy_drop = 16.0
	turret.blast = 3.6
	barrels = MeshInstance3D.new()
	barrels.mesh = Vox.get_mesh("behemoth_barrels")
	turret.add_child(barrels)
	turret.extra.append(barrels)
	core = game.spawn_part(self, "behemoth_core", 1.4)
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
	for x: float in BLADE_X:
		var e := game.spawn_part(self, "", 1.2)
		e.armored = true
		e.hp = 1e9
		e.shootable = false
		blade.append(e)
	for k in 14:
		var m := game.spawn_part(self, "", IMPACT_R)
		m.intangible = true
		m.ram = false
		marks.append(m)
	mg = game.spawn_part(self, "", 0.9)
	mg.intangible = true
	mg.ram = false
	hub = game.spawn_part(self, "", 3.0)
	hub.intangible = true
	hub.ram = false
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("behemoth_hull")
	add_child(hull)
	for s: float in [-1.0, 1.0]:
		var t := MeshInstance3D.new()
		t.mesh = Vox.get_mesh("behemoth_tread")
		hull.add_child(t)
		t.position = Vector3(s * TRACK_X, TREAD_Y, 0)
		treads.append(t)
	for k in 2:
		var sh := MeshInstance3D.new()
		sh.mesh = Vox.get_mesh("behemoth_louvre")
		if k == 1:
			sh.scale = Vector3(-1, 1, 1)
		hull.add_child(sh)
		shutters.append(sh)
	_arm(true)
	_place(0.0)


## While it rolls in nothing can be hurt.
func _arm(on: bool) -> void:
	for e: Enemy in [turret] + sponsons:
		if not e.dead:
			e.armored = on
	_seal()
	if on:
		core.armored = true


## The reactor is sealed under the turret's ring while the turret stands
## (in OVERRUN it is laid open whatever is left).
func _seal() -> void:
	core.armored = not turret.dead and phase != 3


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
			_overrun()
		_seal()


## A point on the hull (offset from its centre, turned with it).
func _at(off: Vector3) -> Vector3:
	return center + off.rotated(Vector3.UP, yaw)


## The hull's heading as a plane angle (0 = +x, PI/2 = down-screen).
func _heading_a() -> float:
	return PI / 2.0 - yaw


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
			_moves(dt)
			_round_a()
			if cycle_t >= ROUND_A:
				_next_round()
			if fight_t > ENRAGE_T and lunge == "":
				_overrun()
		3:
			fight_t += dt
			cycle_t += dt
			_moves(dt)
			_round_c()
			if cycle_t >= ROUND_C:
				_next_round()
		4:
			_dying(dt)
			if destroyed:
				return
	_aim(dt)
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


## Phase A: sponson fans, the main gun, the barrage, the hull gun, the
## charge to the bottom edge, the main gun again.
func _round_a() -> void:
	if _once("f1", 0.4):
		_sponson_fans(Bullets.BIG)
	if _once("f1s", 0.65):
		_sponson_fans(Bullets.SMALL)
	_main_gun("g1", 1.0)
	_barrage("b1", 2.6, 4, false)
	_hull_gun("mg", 3.6, 3, 14.0)
	if _once("c", 4.8):
		_lunge_warn(0.0)
	_main_gun("g2", 8.6)


## OVERRUN: the aimed charge (the reactor spitting shells as it goes and
## comes back), sponson fans, the spin with the spray, four barrages (one
## as it charges, one down the ship's column, one while it spins, one to
## end the round), wide needles; the main gun if it is still there
## (OVERRUN on time).
func _round_c() -> void:
	if _once("c", 0.3):
		var d := game.player.position - center
		_lunge_warn(clampf(atan2(d.x, d.z), -AIM_MAX, AIM_MAX))
	# shells raining all round: while it charges, down the ship's column as
	# it backs off, while it spins, and to end the round
	_barrage("sc1", 0.5, 5, false)
	_barrage("col", 2.8, 4, true)
	_barrage("sp", 6.2, 4, false)
	_barrage("sc2", 8.6, 4, false)
	if _once("f", 1.0):
		_sponson_fans(Bullets.BIG)
	if _once("fs", 1.25):
		_sponson_fans(Bullets.SMALL)
	_main_gun("g", 8.9)
	if _once("s", 4.8):
		_spin_warn()
	_hull_gun("mg", 9.4, 7, 34.0)


func _overrun() -> void:
	phase = 3
	st = 0.0
	_next_round()
	_seal()
	game.show_msg("BEHEMOTH OVERRUN", "", 1.5, true)
	game.shake(1.0)


# ------------------------------------------------------------ moving

## Creeping at its station, charging, or spinning.
func _moves(dt: float) -> void:
	if lunge != "":
		_lunge(dt)
	elif spin != "":
		_spin(dt)
	else:
		creep_t += dt
		center.z = move_toward(center.z, rest_z + sin(creep_t * 0.4) * 1.0, 2.0 * dt)
		center.x = move_toward(center.x, 0.0, 2.0 * dt)
		yaw = move_toward(yaw, 0.0, 1.2 * dt)
	# the cargo along the arena's sides is crushed where it rolls (or its
	# blade swings) over it
	game.terrain.crush(center, SPIN_R if spin == "go" else CRUSH_R)


## The charge: the hull pivots to heading `a` (0 = straight down) while
## the corridor the blade will sweep is marked along it to the edge of the
## screen; then it drives the blade down there, holds, and backs off.
func _lunge_warn(a: float) -> void:
	lunge = "warn"
	lunge_t = 0.0
	lunge_yaw = a
	var h := Vector3(sin(a), 0, cos(a))
	var home := Vector3(0, 0, rest_z)
	lunge_from = home
	# how far until the blade's middle reaches the bottom edge (or a side)
	var b0 := home + Vector3(0, 0, BLADE_Z + 0.4).rotated(Vector3.UP, a)
	var l := (game.field_bottom + 0.6 - b0.z) / maxf(cos(a), 0.05)
	if absf(sin(a)) > 0.05:
		l = minf(l, (game.hw_bottom + 1.5 - absf(b0.x)) / absf(sin(a)))
	lunge_to = home + h * maxf(l, 2.0)
	var lane := PackedVector3Array([b0, b0 + h * maxf(l, 2.0)])
	# the corridor the blade will sweep, shown (HUD._charge_lane) ...
	game.warn(hub, LUNGE_WARN, Game.Warn.MOVE, 1.6, {"lane": lane, "hw": BLADE_HW, "show": true}, true, false)
	# ... and for the autopilot one band it leaves sideways, until the
	# blade is back
	game.warn(hub, LUNGE_WARN + LUNGE_GO + LUNGE_HOLD, Game.Warn.MOVE, 3.0, {"lane": lane, "hw": BLADE_HW + 0.6}, false)
	game.sfx.play("slam")


func _lunge(dt: float) -> void:
	lunge_t += dt
	match lunge:
		"warn":
			# back to its station, turning to the heading
			center = center.move_toward(lunge_from, 4.0 * dt)
			yaw = move_toward(yaw, lunge_yaw, 1.6 * dt)
			if lunge_t >= LUNGE_WARN:
				lunge = "go"
				lunge_t = 0.0
				yaw = lunge_yaw
				game.shake(0.8)
		"go":
			var f := clampf(lunge_t / LUNGE_GO, 0.0, 1.0)
			_flak(dt)
			center = lunge_from.lerp(lunge_to, f * f * (3.0 - 2.0 * f))
			if int(lunge_t * 12.0) != int((lunge_t - dt) * 12.0):
				game.fx.puff(_at(Vector3(randf_range(-8.0, 8.0), 0.2, BLADE_Z)), Vector3(0, 0, 3.0), 0.8, 2.2, 0.6, Fx.SMOKE)
			if f >= 1.0:
				lunge = "hold"
				lunge_t = 0.0
		"hold":
			if lunge_t >= LUNGE_HOLD:
				lunge = "back"
				lunge_t = 0.0
		"back":
			var f := clampf(lunge_t / LUNGE_BACK, 0.0, 1.0)
			_flak(dt)
			center = lunge_to.lerp(lunge_from, f * f * (3.0 - 2.0 * f))
			if f >= 1.0:
				lunge = "turn" if absf(yaw) > 0.01 else ""
				lunge_t = 0.0
		"turn":
			yaw = move_toward(yaw, 0.0, 1.6 * dt)
			if absf(yaw) < 0.001:
				lunge = ""


## OVERRUN: the open reactor spits fans of shells at the ship while the
## tank charges and backs off.
func _flak(dt: float) -> void:
	if phase != 3:
		return
	spray_t -= dt
	if spray_t > 0.0 or not game.can_fire(core.position):
		return
	spray_t = 0.3
	spray_k += 1
	game.bullets.fan(core.position, game.bullets.aim(core.position), 3, 30.0, 5.2, Bullets.SHELL, self, Bullets.ROUND, Bullets.BIG if spray_k % 2 == 0 else Bullets.SMALL)


## OVERRUN's spin: the circle it will sweep marked round it, then one full
## turn on the spot (each time the other way).
func _spin_warn() -> void:
	if lunge != "":
		return
	spin = "warn"
	spin_t = 0.0
	spin_dir = -spin_dir
	game.warn(hub, SPIN_WARN, Game.Warn.MOVE, 3.0, {"r": SPIN_R})
	game.sfx.play("slam")


func _spin(dt: float) -> void:
	spin_t += dt
	match spin:
		"warn":
			center = center.move_toward(Vector3(0, 0, rest_z), 4.0 * dt)
			yaw = move_toward(yaw, 0.0, 1.6 * dt)
			if spin_t >= SPIN_WARN:
				spin = "go"
				spin_t = 0.0
				yaw = 0.0
				game.warn(hub, SPIN_T, Game.Warn.MOVE, 3.0, {"r": SPIN_R}, false)
				game.shake(0.6)
		"go":
			var f := clampf(spin_t / SPIN_T, 0.0, 1.0)
			yaw = spin_dir * TAU * f * f * (3.0 - 2.0 * f)
			_spray(dt)
			if f >= 1.0:
				spin = ""
				yaw = 0.0


## While it spins: the sponsons fire along the hull's heading (a little
## outward each) and the open reactor out both ends: the turning hull winds
## them into a spiral (big and small by turns).
func _spray(dt: float) -> void:
	spray_t -= dt
	if spray_t > 0.0 or not game.combat_on():
		return
	spray_t = 0.07
	spray_k += 1
	var sz := Bullets.BIG if spray_k % 2 == 0 else Bullets.SMALL
	var ha := _heading_a()
	for k in sponsons.size():
		var s := sponsons[k]
		if not s.dead:
			game.bullets.fire(s.position, ha + (-0.35 if k == 1 else 0.35), 5.0, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, sz)
	if spray_k % 2 == 0:
		for a: float in [ha + PI * 0.5, ha - PI * 0.5]:
			game.bullets.fire(core.position, a, 4.4, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if sz == Bullets.SMALL else Bullets.SMALL)


# ------------------------------------------------------------ the main gun

## The turret turns after the ship (within its arc of the hull's heading);
## while a shot is locked it turns fast onto the locked line.
func _aim(dt: float) -> void:
	recoil = maxf(0.0, recoil - dt * 1.6)
	if turret.dead or phase == 4:
		return
	var ha := _heading_a()
	if spin == "go":
		# carried round by the hull
		turret_a = ha
		return
	if not locking:
		var d := game.player.position - _at(TURRET_OFF)
		turret_want = ha + clampf(wrapf(atan2(d.z, d.x) - ha, -PI, PI), -TURN_MAX, TURN_MAX)
	var w := 3.2 if locking else TURN_W
	turret_a = turret_a + clampf(wrapf(turret_want - turret_a, -PI, PI), -w * dt, w * dt)


## Locks on at `at` (the line marked to the bottom edge), fires two slugs
## down it 0.9 s later.
func _main_gun(key: String, at: float) -> void:
	if turret.dead or lunge != "" or spin == "go":
		if cycle_t >= at:
			fired[key] = true
			fired["w_" + key] = true
		return
	if _once("w_" + key, at):
		if not game.can_fire(turret.position):
			fired[key] = true
			return
		var ha := _heading_a()
		var d := game.player.position - _at(TURRET_OFF)
		lock_a = ha + clampf(wrapf(atan2(d.z, d.x) - ha, -PI, PI), -TURN_MAX, TURN_MAX)
		turret_want = lock_a
		locking = true
		var dir := Vector3(cos(lock_a), 0, sin(lock_a))
		var mz := _at(TURRET_OFF) + dir * BARREL_LEN
		game.warn(turret, 0.9, Game.Warn.MOVE, turret.radius, game.line_to_bottom(mz, mz + dir * 10.0))
		game.sfx.play("slam")
	if _once(key, at + 0.9):
		locking = false
		if turret.dead or not game.combat_on():
			return
		turret_a = lock_a
		var dir := Vector3(cos(lock_a), 0, sin(lock_a))
		var side := Vector3(-dir.z, 0, dir.x) * BARREL_SEP
		for s: float in [-1.0, 1.0]:
			var mz := _at(TURRET_OFF) + dir * BARREL_LEN + side * s
			game.bullets.fire(mz, lock_a, SLUG_SPEED, Bullets.IRON, self)
			game.fx.sprite(mz + Vector3(0, 0.6, 0), dir * 3.0, 1.6, 0.4, 0.14, Color(1.0, 0.85, 0.6), 0.0)
		game.fx.flash(_at(TURRET_OFF) + dir * BARREL_LEN, 2.0)
		game.sfx.play("exp_m")
		game.shake(0.6)
		recoil = 1.0


# ------------------------------------------------------------ the barrage

## The howitzers lob `n` shells, one after another from the back corners:
## onto the ship and scattered round the screen, or (`column`) down the
## ship's column from the top toward the bottom edge. Each lands FLIGHT_T
## after it is fired, its circle marked till then.
func _barrage(key: String, at: float, n: int, column: bool) -> void:
	if _once("p_" + key, at):
		var plan: Array = []
		plans[key] = plan
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
	var volley: Array = plans.get(key, [])
	var stagger := 0.26 if column else 0.2
	for k in volley.size():
		if _once("%s%d" % [key, k], at + 0.1 + k * stagger):
			_lob(volley[k])


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
	var from: Vector3 = _at(HOWITZER_OFF[how_k % 2])
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


## The dozer blade across the front: touching it is a crash (it has no
## hit zone, so shots go by it on to the guns).
func _blade_touch() -> void:
	var d := (game.player.position - center).rotated(Vector3.UP, -yaw)
	if absf(d.x) < BLADE_HW + Player.HIT_R and absf(d.z - BLADE_Z) < 0.5 + Player.HIT_R:
		game.touch_player("dozer")


# ------------------------------------------------------------ placing

func _place(dt: float) -> void:
	# the tracks: the top runs move with the tank over the deck (which
	# scrolls by under it), the two of them opposite ways in a turn
	if dt > 0.0:
		var v := (center - last_c) / dt - Vector3(0, 0, game.scroll_speed * (1.0 if phase != 4 else maxf(0.0, 1.0 - dying_t / 2.5)))
		var fwd := v.dot(Vector3(sin(yaw), 0, cos(yaw)))
		var w := wrapf(yaw - last_yaw, -PI, PI) / dt
		for k in 2:
			tread_z[k] += (fwd + (-1.0 if k == 0 else 1.0) * w * TRACK_X) * dt
	last_c = center
	last_yaw = yaw
	for k in 2:
		treads[k].position.z = fposmod(tread_z[k], TREAD_PITCH) - TREAD_PITCH * 0.5
	hull.position = center
	hull.rotation.y = yaw
	# the shutters over the reactor slide aside once it is laid open
	seal_f = move_toward(seal_f, 1.0 if core.armored else 0.0, dt * 1.5)
	for k in 2:
		var s := -1.0 if k == 0 else 1.0
		shutters[k].position = CORE_OFF + Vector3(s * lerpf(2.1, 0.7, seal_f), 0.25, 0)
	core.position = _at(CORE_OFF)
	core.model.rotation.y += dt * (2.8 if phase == 3 else 1.0)
	for k in 2:
		if not sponsons[k].dead:
			var s := sponsons[k]
			s.position = _at(SPONSON_OFF[k])
			var d := game.player.position - s.position
			var want := atan2(d.x, d.z) if spin != "go" else yaw + (0.35 if k == 1 else -0.35)
			s.rotation.y = lerp_angle(s.rotation.y, want, clampf(6.0 * dt, 0.0, 1.0))
	if not turret.dead:
		turret.position = _at(TURRET_OFF)
		turret.rotation.y = atan2(cos(turret_a), sin(turret_a))
		barrels.position.z = -0.6 * recoil
	for k in armour.size():
		armour[k].position = _at(ARMOUR[k][0])
	for k in blade.size():
		blade[k].position = _at(Vector3(BLADE_X[k], 0, BLADE_Z))
		blade[k].hit_pos = blade[k].position
	mg.position = _at(MG_OFF)
	mg.hit_pos = mg.position
	hub.position = center
	hub.hit_pos = center


func _parts() -> Array:
	return [core, turret] + sponsons + armour + blade + marks + [mg, hub]


## The gauge: the main turret and the reactor together (the turret goes
## first, then the reactor).
func gauge() -> Dictionary:
	if phase < 1 or phase >= 4:
		return {}
	var left := maxf(core.hp, 0.0) + (0.0 if turret.dead else maxf(turret.hp, 0.0))
	return {"frac": left / (CORE_HP + TURRET_HP), "color": Color(1.0, 0.86, 0.5), "name": INFO["name"], "name_color": Color(1.0, 0.92, 0.7), "x": 0.2, "w": 0.6, "h": 8.0, "name_y": 72.0}


func force_defeat() -> void:
	if phase < 4:
		core.armored = false
		game.kill(core)


## "A": straight into the fight, the charge about to come. "C": into
## OVERRUN, the main turret gone.
func viewer_skip(to: String) -> void:
	center.z = rest_z
	phase = 1
	st = 0.0
	_arm(false)
	if to == "A":
		cycle_t = 4.6
	elif to == "C":
		turret.dead = true
		game.remove_enemy(turret)
		on_part_killed(turret)
	_place(0.0)


func debug_state() -> String:
	var names := ["enter", "A", "-", "OVERRUN", "dying"]
	return "phase %s %.1fs  core %d/%d%s  turret %s  sponsons %d  charge %s  spin %s  shells %d  round %d %.1fs" % [names[phase], st, int(maxf(core.hp, 0.0)), int(CORE_HP), " sealed" if core.armored else "", "dead" if turret.dead else "%d" % int(turret.hp), sponsons.filter(func(s: Enemy) -> bool: return not s.dead).size(), lunge, spin, shells.size(), cycle, cycle_t]


func _die() -> void:
	defeated = true
	phase = 4
	dying_t = 0.0
	lunge = ""
	spin = ""
	for e: Enemy in [turret] + sponsons:
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
		game.fx.explode(center + off.rotated(Vector3.UP, yaw), randf_range(1.5, 3.0), Vector3.ZERO, Models.GUN)
		game.sfx.play("exp_m")
		game.shake(0.4)
	if dying_t > 3.5:
		game.big_blast(_at(CORE_OFF), 1.0, Models.GUN)
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
