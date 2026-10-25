extends BossBase
## Mid-boss of stage 3, a magnetic ore-catcher of the mining belt: a heavy
## armoured tug (engine pods on its flanks, pincer arms reaching forward)
## round a reactor core in an open bay (the weak point, the gauge), three
## electromagnet pylons (one on its back, one at each pincer tip), and six
## boulders held in orbit round it by their field. The boulders shield it
## (they take the shots as they pass; each can be broken) and they are its ammunition: it slings them
## one at a time down a marked line through where the ship is, right to the
## bottom edge. The pylons spray shell fans (big, then small), the core
## fires telegraphed needle bursts. With two boulders or fewer left it reels
## more in from the belt (they fly in from the top corners, harmless until
## they are in orbit). Armour covers the hull's flanks only: from below,
## the way to the core stays open between the passing boulders.
## OVERLOAD (all three pylons broken): the field runs wild. What boulders
## are left whirl in a tight, fast ring and are slung more often, the core
## spins out a shell spiral and wider needle bursts, and with no boulders
## left it throws rings of shells. A quiet gap ends every round. It leaves
## after a while.

const INFO := {
	"name": "LODESTAR", "role": "mid",
	"desc": "磁力の鉱石捕獲機：核のまわりを 6 個の岩塊が回って盾になり（1 個ずつ壊せる）、岩を 1 個ずつ予兆（線）のあと自機のいた所へ投げつける（下端まで）。3 本の磁石の柱から物理弾の扇、核から狙いの針弾。岩が 2 個以下になると画面の上の隅から岩を引き寄せて補充（回り始めるまで当たらない）。装甲は左右だけで、下からは核まで撃ち込める。柱を全部壊すと暴走（OVERLOAD）：残った岩が小さく速く回り、投げつけが増え、核から渦巻き弾と広い針弾、岩がなければ物理弾の輪",
	"demos": [["FULL", ""], ["OVERLOAD", "B"]],
}
const CORE_HP := 620.0
const SCORE := 25000
const PYLON_HP := 150.0
const PYLON_SCORE := 3000
const ROCK_HP := 24.0
const ROCK_SCORE := 300
const ROCKS := 6
const ROCK_R := 1.4
const RING_R := 3.4  # the pylons, round the core
const ORBIT_R := 5.8
const ORBIT_W := 0.9  # rad/s, clockwise on screen
const WILD_R := 4.6  # OVERLOAD's tight ring
const WILD_W := 2.2
const PYLON_A := [PI * 1.5, PI / 6.0, PI * 5.0 / 6.0]  # top, lower right, lower left (+z is down)
const ARMOUR_OFF := [Vector3(-2.6, 0, -1.2), Vector3(2.6, 0, -1.2)]  # the flanks
const SLING_SPEED := 17.0
const REEL_T := 1.6  # a reeled-in boulder's flight into its slot
const ROUND_A := 7.0
const ROUND_B := 4.5
const LIFE := 48.0

var frame: MeshInstance3D
var core: Enemy
var pylons: Array[Enemy] = []
var armour: Array[Enemy] = []
## the boulders: {e, a (orbit angle), r (orbit radius), state (in, orbit,
## aim, fly), t, from, to, vel, spin}
var rocks: Array[Dictionary] = []
var center := Vector3.ZERO
var rest_z := 0.0
var phase := 0  # 0 enter, 1 A, 2 OVERLOAD, 3 leaving, 4 dying
var st := 0.0
var life_t := 0.0
var cycle_t := 0.0
var sway_t := 0.0
var orbit_a := 0.0
var fired := {}
var spiral_a := 0.0
var spiral_t := 0.0
var boom_t := 0.0


func setup(g: Game) -> void:
	game = g
	rest_z = game.field_top + 10.5
	center = Vector3(0, 0, game.field_top - 8.0)
	# order matters (a shot hits the first part in the list it touches):
	# the boulders, then the pylons and the core, the armour last
	for k in ROCKS:
		_add_rock(TAU * k / ROCKS, "orbit")
	for a: float in PYLON_A:
		var pl := game.spawn_part(self, "lode_pylon", 1.25)
		pl.hp = PYLON_HP
		pl.max_hp = PYLON_HP
		pl.score = PYLON_SCORE
		pl.energy_drop = 10.0
		pl.blast = 2.4
		pylons.append(pl)
	core = game.spawn_part(self, "lode_core", 1.6)
	core.hp = CORE_HP
	core.max_hp = CORE_HP
	core.score = SCORE
	core.energy_drop = 30.0
	core.blast = 4.0
	for o: Vector3 in ARMOUR_OFF:
		var e := game.spawn_part(self, "", 1.5)
		e.armored = true
		e.hp = 1e9
		armour.append(e)
	frame = MeshInstance3D.new()
	frame.mesh = Vox.get_mesh("lode_hull")
	add_child(frame)
	_arm(true)
	_place(0.0)


## A boulder in the field, at orbit angle `a`; "in" = reeled in from `from`
## (harmless and not shootable until it is in orbit).
func _add_rock(a: float, state: String, from := Vector3.ZERO) -> void:
	var e := game.spawn_part(self, "meteor_a" if rocks.size() % 2 == 0 else "meteor_b", ROCK_R)
	e.hp = ROCK_HP
	e.max_hp = ROCK_HP
	e.score = ROCK_SCORE
	e.energy_drop = 3.0
	e.blast = 1.8
	e.model.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
	if state == "in":
		e.intangible = true
		e.ram = false
		e.position = from
	rocks.append({"e": e, "a": a, "r": ORBIT_R, "state": state, "t": 0.0, "from": from, "to": Vector3.ZERO, "vel": Vector3.ZERO, "spin": randf_range(-1.5, 1.5)})


## While it comes in nothing can be hurt.
func _arm(on: bool) -> void:
	core.armored = on
	for pl in pylons:
		if not pl.dead:
			pl.armored = on
	for r in rocks:
		(r["e"] as Enemy).armored = on


func on_hit(_e: Enemy, dmg: float) -> float:
	return 0.0 if defeated else dmg


func on_part_killed(e: Enemy) -> void:
	if e == core:
		_defeat()
		return
	if pylons.has(e):
		game.shake(0.6)
		if pylons_alive() == 0 and phase == 1:
			_overload()
		return
	for r in rocks:
		if r["e"] == e:
			rocks.erase(r)
			e.queue_free()
			return


func pylons_alive() -> int:
	var c := 0
	for pl in pylons:
		if not pl.dead:
			c += 1
	return c


## Boulders in the field (orbiting, or on their way in).
func _held() -> int:
	var c := 0
	for r in rocks:
		if r["state"] == "orbit" or r["state"] == "in":
			c += 1
	return c


func tick(dt: float) -> void:
	if finished:
		return
	st += dt
	life_t += dt
	match phase:
		0:
			center.z = move_toward(center.z, rest_z, 6.0 * dt)
			if center.z >= rest_z - 0.01 and st > 1.0:
				phase = 1
				st = 0.0
				cycle_t = 0.0
				_arm(false)
				game.boss_fight_started()
		1:
			_sway(dt, 0.45, 4.0)
			_round_a(dt)
			if life_t > LIFE:
				_leave()
		2:
			_sway(dt, 0.9, 5.0)
			_round_b(dt)
			if life_t > LIFE:
				_leave()
		3:
			center.z -= (3.0 + st * 9.0) * dt
			if center.z < game.field_top - 13.0:
				_finish()
				return
		4:
			boom_t -= dt
			if boom_t <= 0.0:
				boom_t = 0.12
				if rocks.is_empty():
					for pl in pylons:
						if not pl.dead:
							game.fx.explode(pl.position + Vector3(0, 0.4, 0), 2.2, Vector3.ZERO, BeltModels.COPPER)
					game.big_blast(center, 0.7, BeltModels.COPPER)
					game.items.burst_energy(center, 24.0, 8.0)
					game.sfx.play("exp_l")
					game.shake(1.2)
					_finish()
					return
				var r: Dictionary = rocks.pop_front()
				var e: Enemy = r["e"]
				game.fx.explode(e.position + Vector3(0, 0.4, 0), 1.8, Vector3.ZERO, Models.body_col("meteor_a", Models.GUN))
				game.items.burst_energy(e.position, 3.0)
				game.sfx.play("exp_m")
				game.remove_enemy(e)
				e.queue_free()
	_orbit(dt)
	_place(dt)


## Sways from side to side (eased, so a change of pace never jumps).
func _sway(dt: float, w: float, amp: float) -> void:
	sway_t += dt
	center.x = move_toward(center.x, sin(sway_t * w) * amp, 4.0 * dt)


## True once when the round passes `at` seconds.
func _once(key: String, at: float) -> bool:
	if cycle_t >= at and not fired.has(key):
		fired[key] = true
		return true
	return false


## Phase A: shell fans from the pylons, two boulders slung, a needle burst
## from the core, a refill when the field runs low, a quiet gap at the end.
func _round_a(dt: float) -> void:
	cycle_t += dt
	if _once("reel", 0.3) and _held() <= 2:
		_reel()
	if _once("f1", 0.8):
		_fans(Bullets.BIG)
	if _once("f1s", 1.05):
		_fans(Bullets.SMALL)
	if _once("s1", 1.8):
		_sling()
	if _once("w_core", 3.0):
		game.warn(core, Enemy.WINDUP_SHOT + 0.15, Game.Warn.SHOT, core.radius)
	if _once("core", 3.0 + Enemy.WINDUP_SHOT + 0.15):
		_needles(3, 14.0)
	if _once("s2", 4.2):
		_sling()
	if _once("f2", 5.2):
		_fans(Bullets.BIG)
	if _once("f2s", 5.45):
		_fans(Bullets.SMALL)
	if cycle_t >= ROUND_A:
		cycle_t = 0.0
		fired.clear()


## OVERLOAD: a shell spiral from the core, boulders slung twice a round, a
## wide needle burst, rings of shells once the boulders are gone.
func _round_b(dt: float) -> void:
	cycle_t += dt
	if cycle_t > 0.2 and cycle_t < 3.6 and game.can_fire(center):
		spiral_t -= dt
		if spiral_t <= 0.0:
			spiral_t = 0.14
			spiral_a -= 0.41
			for arm in 2:
				game.bullets.fire(center, spiral_a + arm * PI, 4.4, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if arm == 0 else Bullets.SMALL)
	if _once("s1", 0.4):
		_sling()
	if _once("w_core", 1.4):
		game.warn(core, Enemy.WINDUP_SHOT + 0.15, Game.Warn.SHOT, core.radius)
	if _once("core", 1.4 + Enemy.WINDUP_SHOT + 0.15):
		_needles(5, 26.0)
	if _once("s2", 2.6):
		_sling()
	if _once("ring", 3.0) and _held() == 0 and game.can_fire(center):
		game.bullets.ring(center, 16, 4.8, Bullets.SHELL, self, life_t)
	if cycle_t >= ROUND_B:
		cycle_t = 0.0
		fired.clear()


## All three pylons broken: the field runs wild.
func _overload() -> void:
	phase = 2
	st = 0.0
	cycle_t = 0.0
	fired.clear()
	game.show_msg("LODESTAR OVERLOAD", "", 1.2, true)
	game.shake(0.8)


## The orbiting boulder nearest the ship's side of the ring stops (a
## lock-on and a marked line from it through the ship to the bottom edge)
## and is slung down that line WINDUP_MOVE later.
func _sling() -> void:
	var best := {}
	for r in rocks:
		var e: Enemy = r["e"]
		if r["state"] == "orbit" and game.can_fire(e.position) and (best.is_empty() or e.position.z > (best["e"] as Enemy).position.z):
			best = r
	if best.is_empty():
		return
	var be: Enemy = best["e"]
	best["state"] = "aim"
	best["t"] = 0.0
	best["to"] = game.line_to_bottom(be.position, game.player.position)
	game.warn(be, Enemy.WINDUP_MOVE, Game.Warn.MOVE, ROCK_R, best["to"])
	game.sfx.play("slam")


## Reels boulders in from the belt to fill the field again: they fly in
## from the top corners, harmless, into the gaps in the ring.
func _reel() -> void:
	var n := mini(ROCKS - _held(), 4)
	for k in n:
		var s := -1.0 if k % 2 == 0 else 1.0
		var from := Vector3(s * (game.hw_top + 3.0), 0, game.field_top - 3.0 - k * 1.5)
		_add_rock(orbit_a + TAU * (_held() + 0.5) / ROCKS, "in", from)
	game.fx.shockwave(center + Vector3(0, 0.5, 0), ORBIT_R + 1.5, Color(1.0, 0.85, 0.55))
	game.sfx.play("power")


## Moves the boulders: round the ring (evenly spaced, easing into place
## after a gap), in from the corners, held still while marked, slung.
func _orbit(dt: float) -> void:
	var wild := phase == 2
	var w := WILD_W if wild else ORBIT_W
	var rad := WILD_R if wild else ORBIT_R
	orbit_a += w * dt
	var ring: Array[Dictionary] = []
	for r in rocks:
		if r["state"] == "orbit" or r["state"] == "in":
			ring.append(r)
	for k in ring.size():
		var r := ring[k]
		var want := orbit_a + TAU * k / ring.size()
		r["a"] = float(r["a"]) + w * dt + clampf(wrapf(want - float(r["a"]), -PI, PI), -0.8 * dt, 0.8 * dt)
	for r in rocks.duplicate():
		var e: Enemy = r["e"]
		r["t"] += dt
		var a: float = r["a"]
		match r["state"]:
			"orbit":
				r["r"] = move_toward(r["r"], rad, 3.0 * dt)
				e.position = center + Vector3(cos(a), 0, sin(a)) * float(r["r"])
			"in":
				var f := clampf(float(r["t"]) / REEL_T, 0.0, 1.0)
				f = f * f * (3.0 - 2.0 * f)
				var slot := center + Vector3(cos(a), 0, sin(a)) * rad
				var from: Vector3 = r["from"]
				var bend := Vector3(from.x * 0.55, 0, from.z + 7.0)
				e.position = from.lerp(bend, f).lerp(bend.lerp(slot, f), f)
				if f >= 1.0 and not defeated:
					r["state"] = "orbit"
					r["r"] = rad
					e.intangible = false
					e.ram = true
			"aim":
				r["spin"] = float(r["spin"]) * (1.0 + 2.0 * dt)
				if float(r["t"]) >= Enemy.WINDUP_MOVE:
					var d: Vector3 = r["to"] - e.position
					d.y = 0.0
					r["vel"] = d.normalized() * SLING_SPEED
					r["state"] = "fly"
					r["t"] = 0.0
			"fly":
				e.position += r["vel"] * dt
				if float(r["t"]) > 0.3 and not game.on_field(e.position, 3.0):
					rocks.erase(r)
					game.remove_enemy(e)
					e.queue_free()
					continue
		e.hit_pos = e.position
		e.model.rotation.x += dt * float(r["spin"])
		e.model.rotation.y += dt * 0.4


func _fans(size: float) -> void:
	for pl in pylons:
		if pl.dead or not game.can_fire(pl.position):
			continue
		var off := 0.0 if size == Bullets.BIG else deg_to_rad(5.0)
		game.bullets.fan(pl.position, game.bullets.aim(pl.position) + off, 5 if size == Bullets.BIG else 4, 50.0 if size == Bullets.BIG else 42.0, 5.0 if size == Bullets.BIG else 5.6, Bullets.SHELL, self, Bullets.ROUND, size)


## The core's telegraphed needle burst (fired after its warning).
func _needles(count: int, spread: float) -> void:
	var at := core.position + Vector3(0, 0, 1.4)
	if game.can_fire(at):
		game.bullets.fan(at, game.bullets.aim(at), count, spread, 9.0, Bullets.ORB, self, Bullets.NEEDLE)


func _place(dt: float) -> void:
	frame.position = center
	core.position = center
	core.model.rotation.y += dt * (2.6 if phase == 2 else 0.8)
	for k in pylons.size():
		if not pylons[k].dead:
			var a: float = PYLON_A[k]
			pylons[k].position = center + Vector3(cos(a), 0, sin(a)) * RING_R
	for k in armour.size():
		armour[k].position = center + ARMOUR_OFF[k]


func _leave() -> void:
	phase = 3
	st = 0.0


func _defeat() -> void:
	disarm()
	phase = 4
	st = 0.0
	boom_t = 0.3
	for b in game.bullets.cancel_owner(self):
		game.items.spawn(b, Items.ENERGY, 1.0)


func _finish() -> void:
	finished = true
	for e: Enemy in [core] + pylons + armour:
		game.remove_enemy(e)
		e.queue_free()
	for r in rocks:
		game.remove_enemy(r["e"])
		(r["e"] as Enemy).queue_free()
	rocks.clear()
	game.remove_boss(self)
	queue_free()


func gauge() -> Dictionary:
	if defeated or phase == 0 or phase == 3:
		return {}
	return {"frac": core.hp / CORE_HP, "color": Color(0.95, 0.65, 0.35), "name": INFO["name"], "name_color": Color(1.0, 0.85, 0.65), "x": 0.25, "w": 0.5, "h": 7.0, "name_y": 70.0}


func force_defeat() -> void:
	if not defeated and not finished:
		core.armored = false
		game.kill(core)


## "B": straight into OVERLOAD, the pylons gone.
func viewer_skip(to: String) -> void:
	if to != "B":
		return
	center.z = rest_z
	phase = 1
	_arm(false)
	for pl in pylons:
		pl.dead = true
		game.remove_enemy(pl)
	_overload()
	_place(0.0)


func debug_state() -> String:
	var names := ["enter", "A", "OVERLOAD", "leaving", "dying"]
	return "phase %s %.1fs  core %d/%d  pylons %d  boulders %d  life %.0f" % [names[phase], st, int(maxf(core.hp, 0.0)), int(CORE_HP), pylons_alive(), _held(), life_t]
