extends BossBase
## Stage 5's first boss OMEGA CORTEX: STAR CORTEX (stage 1) finished and
## armed. The same octagonal core round the great eye (its shutters, its
## four pods, the armour blocks on its flanks), now built out: truss girders
## carry a gun deck either side with a rail cannon on a ring mount (fed by
## glowing capacitor banks), and two mine batteries stand on a frame at its
## back. Bare machinery in the Cortex's greys, cyan lamps.
## The eye is only vulnerable while open (open longer than shut; with a
## shutter half shot off, shots get in on that side while it is shut).
## Phase A: the pods fire shell fans in turn; the rail cannons take turns
## at the rail shot (the turret turns to the ship, the line through it to
## the bottom edge is marked, then four iron slugs go down it fast: they
## can't be shot and they stop shots); the batteries lob mines (big shells
## that slow to a stop over the screen and burst into rings: shoot them
## first). Open, the eye fires a needle shotgun, three serpents (iron balls
## weaving at the ship, announced), a flower of shell rings and a second
## shotgun.
## OVERDRIVE (both rail cannons gone, all four pods gone, or after a
## while): the fortress sways, the eye opens longer; the pod sockets spin
## shell spirals while it is shut; a living rail cannon marks two lines at a
## time (one through the ship, one where it is heading), a dead one's deck
## sprays a turning pair of shell streams; mines come in fours. Open, the
## eye fires five serpents that burst into rings, a longer flower, a wide
## needle fan, and once a round its signature, the NOVA: the eye glows (a
## long lock-on), then a ring of eight iron balls and a ring of shells with
## a gap toward the ship's side. There is a quiet moment in every round to
## come in with the Spear.

const INFO := {
	"name": "OMEGA CORTEX", "role": "boss",
	"desc": "ステージ 1 の STAR CORTEX を完成させて武装した最終面のボス 1 体目。八角形の本体と目（シャッター 2 枚、4 つのポッド、側面の装甲）はそのまま、トラスの桁で左右に砲甲板を張り出してレールキャノン（コンデンサーで光る）を載せ、後ろの架台に機雷の発射機が 2 基。目は開いている時だけ効く（閉じている時間より長く開く。シャッターを片方壊せばその側からは閉じていても撃ち込める）。通常：ポッドが交代で物理弾の扇。レールキャノンが交代でレール射撃（砲塔が自機を向き、自機を通って下端までの線を予兆、そのあと鉄球弾 4 発を速く：撃ち落とせず、ショットを遮る）。発射機が機雷（止まってから輪にはじける大きな物理弾：先に撃ち落とす）。開くと針弾の散弾、大型弾（蛇行する鉄球弾）3 つ、花びら状の物理弾、もう一度散弾。レールキャノンを両方壊すか、ポッドを全部壊すか、時間で OVERDRIVE：揺れながら、目は長く開き、閉じている間はポッドの穴から渦巻き弾、生きているレールキャノンは 2 本同時（自機と自機の向かう側）、壊れた甲板は回る 2 本の物理弾の流れ、機雷は 4 つずつ。開くと 5 つの大型弾（はじけて輪に）、長い花びら、広い針弾、そして 1 周に 1 回の大技 NOVA（目が光る長い予兆のあと、鉄球弾 8 つの輪と、自機の側に隙間のある物理弾の輪）。毎周、スピアで寄れる静かな間がある",
	"demos": [["FULL", ""], ["OVERDRIVE", "B"]],
}
const EYE_HP := 1150.0
const EYE_SCORE := 80000
const POD_HP := 110.0
const POD_SCORE := 5000
const RAIL_HP := 320.0
const RAIL_SCORE := 12000
const SHUTTER_HP := 240.0
const SHUTTER_SCORE := 6000
const POD_OFF := [Vector3(-5.6, 0, -2.4), Vector3(5.6, 0, -2.4), Vector3(-4.3, 0, 3.3), Vector3(4.3, 0, 3.3)]
const RAIL_OFF := [Vector3(-11.5, 0, -1.0), Vector3(11.5, 0, -1.0)]
const BATTERY_OFF := [Vector3(-5.6, 0, -6.3), Vector3(5.6, 0, -6.3)]
const ARMOUR_OFF := [Vector3(-4.0, 0, 0.0), Vector3(4.0, 0, 0.0)]
const ARMOUR_R := 2.7
const SHUTTER_R := 1.35
const SHUTTER_X := 1.05
const RAIL_LEN := 3.2  # turret centre to the muzzle
const RAIL_LOCK := 1.0  # the rail shot: marked this long, then
const SLUGS := 4
const SLUG_GAP := 0.12
const SLUG_SPEED := 16.0
const RAIL_TURN := 1.6  # the turret's slew (rad/s)
## the eye: seconds shut, then open, per round (phase A, OVERDRIVE)
const CLOSED_A := 2.6
const OPEN_A := 4.6
const CLOSED_B := 1.6
const OPEN_B := 5.2
const NOVA_LOCK := 1.3
const ENRAGE_T := 50.0

var hull: MeshInstance3D
var wings: MeshInstance3D
var armour: Array[Enemy] = []
var eye: Enemy
var pods: Array[Enemy] = []
var shutters: Array[Enemy] = []
var rails: Array[Enemy] = []
var rail_a := [PI / 2.0, PI / 2.0]  # where each rail cannon points (PI/2 = down)
## rail shots: {k, to: [Vector3, ...], t, slugs, gap}
var rail_shots: Array[Dictionary] = []
var rail_t := 1.2
var rail_k := 0
var mine_t := 2.0
var center := Vector3.ZERO
var phase := 0  # 0 enter, 1 A, 2 OVERDRIVE, 3 dying
var st := 0.0
var fight_t := 0.0
var cycle_t := 0.0
var open := 0.0
var open_want := false
var fired := {}
var spiral_a := 0.0
var spiral_t := 0.0
var spray_a := 0.0
var spray_t := 0.0
var serpent_to := Vector3.ZERO
var flower_a := 0.0
var pod_t := 1.0
var pod_k := 0
var destroyed := false
var dying_t := 0.0
var ship_v := Vector3.ZERO
var ship_last := Vector3.ZERO


func setup(g: Game) -> void:
	game = g
	center = Vector3(0, 0, game.field_top - 10.0)
	ship_last = game.player.position
	# order matters: shots test enemies in list order, so the shutters come
	# before the eye they cover, the eye, pods and rails before the armour
	for s in [-1, 1]:
		var sh := game.spawn_part(self, "boss_shutter", SHUTTER_R)
		sh.hp = SHUTTER_HP
		sh.max_hp = SHUTTER_HP
		sh.score = SHUTTER_SCORE
		sh.energy_drop = 10.0
		sh.blast = 2.5
		sh.armored = true
		sh.ram = false
		sh.model.position = Vector3(-s * SHUTTER_X, 1.25, 0)
		sh.model.scale = Vector3(-s, 1, 1)
		shutters.append(sh)
	eye = game.spawn_part(self, "boss_eye", 1.9)
	eye.hp = EYE_HP
	eye.max_hp = EYE_HP
	eye.armored = true
	eye.score = EYE_SCORE
	eye.blast = 6.0
	for k in 4:
		var e := game.spawn_part(self, "boss_pod", 1.45)
		e.hp = POD_HP
		e.max_hp = POD_HP
		e.score = POD_SCORE
		e.energy_drop = 12.0
		e.blast = 2.5
		e.armored = true
		pods.append(e)
	for k in 2:
		var r := game.spawn_part(self, "omega_rail", 1.7)
		r.hp = RAIL_HP
		r.max_hp = RAIL_HP
		r.score = RAIL_SCORE
		r.energy_drop = 16.0
		r.blast = 3.2
		r.armored = true
		r.ram = false
		rails.append(r)
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("boss_hull")
	add_child(hull)
	wings = MeshInstance3D.new()
	wings.mesh = Vox.get_mesh("omega_wings")
	add_child(wings)
	for k in 2:
		var a := game.spawn_part(self, "", ARMOUR_R)
		a.armored = true
		a.hp = 1e9
		armour.append(a)
	_place(0.0)


func on_hit(_e: Enemy, dmg: float) -> float:
	return dmg


func on_part_killed(e: Enemy) -> void:
	if e == eye:
		_die()
		return
	game.shake(0.8)
	var k := rails.find(e)
	if k >= 0:
		for r in rail_shots.duplicate():
			if r["k"] == k and r["slugs"] == SLUGS:
				rail_shots.erase(r)  # marked but not fired: called off
	if phase == 1 and (rails_alive() == 0 or pods_alive() == 0):
		_overdrive()


func shutters_alive() -> int:
	var c := 0
	for q in shutters:
		if not q.dead:
			c += 1
	return c


func pods_alive() -> int:
	var c := 0
	for q in pods:
		if not q.dead:
			c += 1
	return c


func rails_alive() -> int:
	var c := 0
	for q in rails:
		if not q.dead:
			c += 1
	return c


func _place(dt: float) -> void:
	hull.position = center
	wings.position = center
	for k in 2:
		armour[k].position = center + ARMOUR_OFF[k]
	eye.position = center + Vector3(0, -0.4, 0)
	for k in 4:
		if not pods[k].dead:
			pods[k].position = center + POD_OFF[k]
	var gap := open * 2.2
	for k in 2:
		if not shutters[k].dead:
			var s := -1.0 if k == 0 else 1.0
			shutters[k].position = center + Vector3(s * (gap + SHUTTER_X), 0, 0)
	for k in 2:
		var r := rails[k]
		r.position = center + RAIL_OFF[k]
		if not r.dead:
			# the turret turns after the ship, unless a shot is marked
			var held := false
			for q in rail_shots:
				if q["k"] == k:
					held = true
			if not held and phase >= 1 and phase <= 2:
				var d := game.player.position - r.position
				rail_a[k] = rotate_toward(float(rail_a[k]), atan2(d.z, d.x), RAIL_TURN * dt)
			r.model.rotation.y = atan2(cos(float(rail_a[k])), sin(float(rail_a[k])))


func _warn_at(key: String, at: float, dur: float, kind: int) -> void:
	if cycle_t >= at - dur and not fired.has("w_" + key):
		fired["w_" + key] = true
		game.warn(eye, dur, kind, eye.radius)


func _fire_once(key: String, at: float) -> bool:
	if cycle_t >= at and not fired.has(key):
		fired[key] = true
		return true
	return false


func tick(dt: float) -> void:
	if destroyed:
		return
	st += dt
	if dt > 0.0:
		var p := game.player.position
		ship_v = ship_v.lerp((p - ship_last) / dt, clampf(dt * 8.0, 0.0, 1.0))
		ship_last = p
	match phase:
		0:
			center.z = move_toward(center.z, game.field_top + 7.0, 4.0 * dt)
			if st > 4.2:
				phase = 1
				st = 0.0
				for q in pods + shutters + rails:
					q.armored = false
				game.boss_fight_started()
		1:
			fight_t += dt
			_eye_cycle(dt, CLOSED_A, OPEN_A)
			_pods(dt)
			_rails(dt)
			_mines(dt)
			if fight_t > ENRAGE_T:
				_overdrive()
		2:
			fight_t += dt
			center.x = move_toward(center.x, sin(st * 0.55) * 3.5, 4.0 * dt)
			_eye_cycle(dt, CLOSED_B, OPEN_B)
			_pods(dt)
			_rails(dt)
			_mines(dt)
			_sprays(dt)
			if not open_want and cycle_t > 0.2 and cycle_t < CLOSED_B - 0.1:
				# the pod sockets bleed fire while the eye is shut
				spiral_t -= dt
				if spiral_t <= 0.0:
					spiral_t = 0.15
					spiral_a += 0.33
					for k in 4:
						var at: Vector3 = center + POD_OFF[k]
						if game.can_fire(at):
							game.bullets.fire(at, spiral_a + k * PI / 2.0, 4.6, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if k % 2 == 0 else Bullets.SMALL)
		3:
			dying_t += dt
			if int(dying_t * 8.0) != int((dying_t - dt) * 8.0):
				var off := Vector3(randf_range(-13, 13), 0, randf_range(-5.5, 4.0))
				game.fx.explode(center + off, randf_range(1.5, 3.0), Vector3.ZERO, Models.STEEL_M)
				game.sfx.play("exp_m")
				game.shake(0.4)
			center.z += dt * 1.2
			if dying_t > 3.6:
				game.big_blast(center, 1.0, Models.STEEL_L)
				for k in 6:
					game.fx.explode(center + Vector3(randf_range(-12, 12), 0, randf_range(-4, 3)), 4.0, Vector3.ZERO, Models.GUN)
				game.sfx.play("exp_l")
				game.shake(2.0)
				destroyed = true
				finished = true
				visible = false
				for q in [eye] + armour + pods + shutters + rails:
					game.remove_enemy(q)
					q.visible = false
				game.boss_destroyed(self)
				return
	_rail_shots(dt)
	open = move_toward(open, 1.0 if open_want else 0.0, dt * 2.5)
	# shut, the eye is armoured while both shutters hold; with one shot off,
	# shots get in on that side
	eye.armored = phase == 0 or phase == 3 or (open < 0.7 and shutters_alive() == 2)
	eye.model.rotation.y += dt * (2.2 if phase == 2 else 0.6)
	_place(dt)


## Both rail cannons gone, all the pods gone, or time up: OVERDRIVE.
func _overdrive() -> void:
	phase = 2
	st = 0.0
	cycle_t = 0.0
	fired.clear()
	game.show_msg("CORTEX OVERDRIVE", "", 1.5, true)
	game.shake(1.0)
	game.sfx.play("slam")


## One round of the eye: shut, then open with its attacks (each energy shot
## announced on the eye).
func _eye_cycle(dt: float, closed_time: float, open_time: float) -> void:
	cycle_t += dt
	open_want = cycle_t > closed_time and cycle_t < closed_time + open_time
	var c := closed_time
	var w := Enemy.WINDUP_SHOT
	if open_want:
		if phase == 1:
			_warn_at("shotgun1", c + 0.3 + w, w, Game.Warn.SHOT)
			if _fire_once("shotgun1", c + 0.3 + w):
				game.bullets.fan(eye.position, game.bullets.aim(eye.position), 7, 24.0, 9.0, Bullets.ORB, self, Bullets.NEEDLE)
			_serpents(c + 1.2, 3, 20.0, false)
			_flower(c + 2.3, 4, 18, 4.2)
			_warn_at("shotgun2", c + 3.7 + w, w, Game.Warn.SHOT)
			if _fire_once("shotgun2", c + 3.7 + w):
				game.bullets.fan(eye.position, game.bullets.aim(eye.position), 9, 40.0, 9.5, Bullets.ORB, self)
		else:
			_serpents(c + 0.2, 5, 18.0, true)
			_flower(c + 1.3, 5, 22, 4.6)
			_warn_at("shotgun1", c + 2.8 + w, w, Game.Warn.SHOT)
			if _fire_once("shotgun1", c + 2.8 + w):
				game.bullets.fan(eye.position, game.bullets.aim(eye.position), 11, 60.0, 9.5, Bullets.ORB, self, Bullets.NEEDLE)
			_nova(c + 3.6 + NOVA_LOCK)
	if cycle_t > closed_time + open_time + 0.4:
		cycle_t = 0.0
		fired.clear()


## `count` armoured IRON serpents weaving down toward where the ship was (a
## lock-on marks the line first); in OVERDRIVE they burst into rings.
func _serpents(at: float, count: int, spread: float, bursting: bool) -> void:
	var dur := 0.8
	if cycle_t >= at - dur and not fired.has("w_serpent"):
		fired["w_serpent"] = true
		serpent_to = game.player.position
		game.warn(eye, dur, Game.Warn.MOVE, eye.radius, serpent_to)
	if _fire_once("serpent", at):
		var d := serpent_to - eye.position
		var base := atan2(d.z, d.x)
		for i in count:
			var a := base + deg_to_rad(spread) * (i - (count - 1) * 0.5)
			game.bullets.fire(eye.position + Vector3(0, 0, 1.2), a, 4.8 if phase == 1 else 5.2, Bullets.IRON, self)
			game.bullets.snake(2.3 if phase == 1 else 2.7, 3.1 if phase == 1 else 3.5)
			if bursting:
				game.bullets.split(1.9 + 0.12 * absf(i - (count - 1) * 0.5), 8)


## A flower from the eye: rings of breakable shells, each turned a little.
func _flower(at: float, waves: int, count: int, speed: float) -> void:
	for k in waves:
		if _fire_once("flower%d" % k, at + k * 0.32):
			flower_a += 0.21
			game.bullets.ring(eye.position, count, speed, Bullets.SHELL, self, flower_a)


## The NOVA (OVERDRIVE, once a round): a long lock-on as the eye glows,
## then a ring of eight iron balls and a ring of shells with a gap toward
## where the ship is heading.
func _nova(at: float) -> void:
	if cycle_t >= at - NOVA_LOCK and not fired.has("w_nova"):
		fired["w_nova"] = true
		game.warn(eye, NOVA_LOCK, Game.Warn.MOVE, eye.radius * 1.6)
		game.sfx.play("slam")
	if cycle_t >= at - NOVA_LOCK and cycle_t < at and randf() < 0.5:
		var off := Vector3(randf_range(-2.4, 2.4), 0.5, randf_range(-2.4, 2.4))
		game.fx.sprite(eye.position + off, -off * 2.2, 0.5, 0.12, 0.18, Color(0.6, 0.95, 1.0), 0.0)
	if _fire_once("nova", at):
		var aim := game.bullets.aim(eye.position)
		for k in 8:
			game.bullets.fire(eye.position, aim + PI / 8.0 + TAU * k / 8.0, 4.4, Bullets.IRON, self)
		var head := aim + (0.35 if ship_v.x > 0.0 else -0.35)
		game.bullets.ring(eye.position, 28, 5.2, Bullets.SHELL, self, 0.0, 4, head)
		game.flash_a = maxf(game.flash_a, 0.15)
		game.shake(0.7)
		game.sfx.play("exp_m")


func _pods(dt: float) -> void:
	pod_t -= dt
	if pod_t > 0.0 or pods_alive() == 0:
		return
	pod_t = 1.0 if phase == 1 else 1.3
	for i in 4:
		pod_k = (pod_k + 1) % 4
		var q := pods[pod_k]
		if not q.dead:
			var at := q.position + Vector3(0, 0, 1.0)
			game.bullets.fan(at, game.bullets.aim(at), 5, 44.0, 6.0, Bullets.SHELL, self)
			break


## The rail cannons take turns: one marked shot at a time in phase A, two
## lines at once from one cannon in OVERDRIVE (through the ship, and where
## it is heading).
func _rails(dt: float) -> void:
	rail_t -= dt
	if rail_t > 0.0 or rails_alive() == 0:
		return
	rail_t = 3.2 if phase == 1 else 2.6
	for i in 2:
		rail_k = (rail_k + 1) % 2
		var r := rails[rail_k]
		if r.dead or not game.can_fire(r.position):
			continue
		var muzzle := r.position + Vector3(cos(float(rail_a[rail_k])), 0, sin(float(rail_a[rail_k]))) * RAIL_LEN
		var tos: Array = [game.line_to_bottom(muzzle, game.player.position)]
		if phase == 2:
			var side := signf(ship_v.x) if absf(ship_v.x) > 1.0 else (-signf(game.player.position.x) if absf(game.player.position.x) > 0.5 else 1.0)
			tos.append(game.line_to_bottom(muzzle, game.player.position + Vector3(side * 3.2, 0, 0)))
		for to: Vector3 in tos:
			game.warn(r, RAIL_LOCK, Game.Warn.MOVE, r.radius, to, to == tos[0])
		rail_a[rail_k] = atan2(tos[0].z - r.position.z, tos[0].x - r.position.x)
		rail_shots.append({"k": rail_k, "to": tos, "t": RAIL_LOCK, "slugs": SLUGS, "gap": 0.0})
		game.sfx.play("slam")
		return


## Marked rail shots: once the lock runs out, the slugs go down the lines
## one after another (the turret swings between two lines).
func _rail_shots(dt: float) -> void:
	for q in rail_shots.duplicate():
		var r := rails[int(q["k"])]
		if r.dead or defeated:
			rail_shots.erase(q)
			continue
		q["t"] -= dt
		# sparks run up the rails while it charges
		if q["t"] > 0.0 and randf() < 0.4:
			var d := Vector3(cos(float(rail_a[int(q["k"])])), 0, sin(float(rail_a[int(q["k"])])))
			game.fx.sprite(r.position + d * randf_range(0.5, RAIL_LEN) + Vector3(0, 0.5, 0), Vector3.ZERO, 0.45, 0.1, 0.12, Color(0.6, 0.95, 1.0), 0.0)
		if q["t"] > 0.0:
			continue
		q["gap"] -= dt
		if q["gap"] > 0.0:
			continue
		q["gap"] = SLUG_GAP
		var tos: Array = q["to"]
		var to: Vector3 = tos[(SLUGS - int(q["slugs"])) % tos.size()]
		var a := atan2(to.z - r.position.z, to.x - r.position.x)
		rail_a[int(q["k"])] = a
		var muzzle := r.position + Vector3(cos(a), 0, sin(a)) * RAIL_LEN
		if game.combat_on():
			game.bullets.fire(muzzle, atan2(to.z - muzzle.z, to.x - muzzle.x), SLUG_SPEED, Bullets.IRON, self)
			game.fx.flash(muzzle, 0.5)
			game.sfx.play("exp_s")
		q["slugs"] = int(q["slugs"]) - 1
		if int(q["slugs"]) <= 0:
			rail_shots.erase(q)


## The batteries at the back lob mines: big shells that slow to a stop over
## the screen and burst into rings (they can be shot down first).
func _mines(dt: float) -> void:
	mine_t -= dt
	if mine_t > 0.0:
		return
	mine_t = 4.2 if phase == 1 else 3.4
	var n := 1 if phase == 1 else 2
	for k in 2:
		var at: Vector3 = center + BATTERY_OFF[k]
		if not game.can_fire(at):
			continue
		for i in n:
			var target := Vector3(randf_range(-0.8, 0.8) * game.field_hw, 0, randf_range(game.field_top + 10.0, game.field_bottom - 7.0))
			var d := target - at
			var dist := d.length()
			# it decelerates to a stop at the target (v^2 = 2 a s)
			var v0 := 9.0
			game.bullets.fire(at, atan2(d.z, d.x), v0, Bullets.SHELL, self, Bullets.ROUND, -v0 * v0 / (2.0 * maxf(dist, 1.0)), 0.0, 1.7)
			game.bullets.split(2.0 * maxf(dist, 1.0) / v0 + 0.5, 12)
		game.fx.flash(at, 0.4)


## OVERDRIVE: a dead rail cannon's deck sprays a turning pair of shell
## streams from the stump.
func _sprays(dt: float) -> void:
	spray_t -= dt
	spray_a += dt * 1.6
	if spray_t > 0.0:
		return
	spray_t = 0.11
	for k in 2:
		if not rails[k].dead:
			continue
		var at: Vector3 = center + RAIL_OFF[k]
		if not game.can_fire(at):
			continue
		var s := -1.0 if k == 0 else 1.0
		for arm in 2:
			game.bullets.fire(at, s * spray_a + PI * arm, 4.8, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if arm == 0 else Bullets.SMALL)


func gauge() -> Dictionary:
	if phase < 1 or phase >= 3:
		return {}
	return {"frac": eye.hp / eye.max_hp, "color": Hud.CYAN if not eye.armored else Color(0.55, 0.6, 0.65), "name": INFO["name"], "name_color": Color(0.75, 0.95, 1.0), "x": 0.2, "w": 0.6, "h": 8.0, "name_y": 72.0}


func force_defeat() -> void:
	if phase < 3:
		game.kill(eye)


## "B": straight into OVERDRIVE, everything still up.
func viewer_skip(to: String) -> void:
	if to == "B":
		center.z = game.field_top + 7.0
		phase = 1
		for q in pods + shutters + rails:
			q.armored = false
		_overdrive()
		_place(0.0)


func debug_state() -> String:
	var names := ["enter", "A", "OVERDRIVE", "dying"]
	return "phase %s %.1fs  eye %s %d/%d  pods %d  rails %d" % [names[phase], st, "open" if not eye.armored else "shut", int(maxf(eye.hp, 0.0)), int(EYE_HP), pods_alive(), rails_alive()]


func _die() -> void:
	defeated = true
	phase = 3
	dying_t = 0.0
	open_want = true
	rail_shots.clear()
	for q in pods + shutters + rails:
		if not q.dead:
			game.kill(q)
	disarm()
	var conv := game.bullets.cancel_all()
	for b in conv:
		game.items.spawn(b, Items.ENERGY, 1.0)
	game.boss_dying()
