extends BossBase
## Stage 1 boss STAR CORTEX (an homage to Star Soldier's Star Brain): an
## octagonal fortress whose great eye opens and shuts. No invisible armour:
## a shot that misses every part flies on past the hull (the old flank
## armour sat right below the rear pods and swallowed shots at them); four
## pods at the corners fire shell fans; the eye is only vulnerable while
## its shutters are open, and then it answers with light energy patterns.
## The two shutter halves can be shot off: with one gone, shots get in on
## that side even while the eye is shut.
## Phase A: the pods fire shell fans; the eye opens for longer than it is
## shut, and while open fires a needle shotgun, two gaze strikes (a sight
## follows the ship a little slower than it flies, holds still and the spot
## bursts: MarkedStrikes) and a flower of shell rings.
## Phase B, ENRAGED (pods gone or after a while): the fortress sways, the
## eye opens even more, the empty pod sockets spin shell spirals while it
## is shut, and each opening brings three gaze strikes, a longer flower, a wide
## needle shotgun and shells that burst into rings. There is a quiet moment
## in every round to come in with the Spear.

const MarkedStrikes := preload("res://scripts/bosses/marked_strikes.gd")
const INFO := {
	"name": "STAR CORTEX", "role": "boss",
	"desc": "目が開いた時だけ効く（閉じている時間より長く開く）。目を覆うシャッター（左右 2 枚）は壊せて、壊した側からは閉じていても撃ち込める。開くと針弾・照準爆撃（照準が自機を少し遅れて追い、止まるとその場が炸裂）・花びら状の物理弾。ポッドは扇状の物理弾。ポッドを失うか時間で発狂：揺れながら、閉じている間は空いた穴から渦巻き弾、開くと照準爆撃 3 つ・長い花びら・広い散弾・はじけて輪になる弾",
	"demos": [["FULL", ""], ["ENRAGED", "B"]],
}
const EYE_HP := 1400.0
const EYE_SCORE := 50000
const POD_HP := 90.0
const POD_SCORE := 5000
const POD_OFF := [Vector3(-5.6, 0, -2.4), Vector3(5.6, 0, -2.4), Vector3(-4.3, 0, 3.3), Vector3(4.3, 0, 3.3)]
const SHUTTER_HP := 220.0
const SHUTTER_SCORE := 5000
const SHUTTER_R := 1.35
const SHUTTER_X := 1.05  # hit zone centre from the shutter's inner edge
## the eye: seconds shut, then open, per round (phase A, ENRAGED)
const CLOSED_A := 3.0
const OPEN_A := 4.4
const CLOSED_B := 2.0
const OPEN_B := 4.6
const ENRAGE_T := 45.0

var hull: MeshInstance3D
var eye: Enemy
var pods: Array[Enemy] = []
var shutters: Array[Enemy] = []  # left, right: they can be shot off
var center := Vector3.ZERO
var phase := 0  # 0 enter, 1 A, 2 B, 3 dying
var st := 0.0
var fight_t := 0.0
var cycle_t := 0.0
var open := 0.0
var open_want := false
var fired := {}
var spiral_a := 0.0
var spiral_t := 0.0
var gaze: MarkedStrikes
var flower_a := 0.0
var pod_t := 1.0
var pod_k := 0
var destroyed := false
var dying_t := 0.0


func setup(g: Game) -> void:
	game = g
	center = Vector3(0, 0, game.field_top - 9.0)
	# order matters: shots test enemies in list order, so the shutters come
	# before the eye they cover
	for s in [-1, 1]:
		var sh := game.spawn_part(self, "boss_shutter", SHUTTER_R)
		sh.hp = SHUTTER_HP
		sh.max_hp = SHUTTER_HP
		sh.score = SHUTTER_SCORE
		sh.energy_drop = 10.0
		sh.blast = 2.5
		sh.armored = true
		sh.ram = false
		# the mesh is the left half; its inner edge sits SHUTTER_X from the part
		sh.model.position = Vector3(-s * SHUTTER_X, 1.25, 0)
		sh.model.scale = Vector3(-s, 1, 1)
		shutters.append(sh)
	eye = game.spawn_part(self, "boss_eye", 1.9)
	eye.hp = EYE_HP
	eye.max_hp = EYE_HP
	eye.armored = true
	eye.score = EYE_SCORE
	eye.blast = 6.0
	gaze = MarkedStrikes.new(g, self, MarkedStrikes.LANCE, Color(1.0, 0.35, 0.75))
	for k in 4:
		var e := game.spawn_part(self, "boss_pod", 1.45)
		e.hp = POD_HP
		e.max_hp = POD_HP
		e.score = POD_SCORE
		e.energy_drop = 12.0
		e.blast = 2.5
		e.armored = true
		pods.append(e)
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("boss_hull")
	add_child(hull)
	_place()


func on_hit(e: Enemy, dmg: float) -> float:
	return dmg


func on_part_killed(e: Enemy) -> void:
	if e == eye:
		_die()
	elif pods.has(e) or shutters.has(e):
		game.shake(0.8)


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


func _place() -> void:
	hull.position = center
	eye.position = center + Vector3(0, -0.4, 0)
	for k in 4:
		if not pods[k].dead:
			pods[k].position = center + POD_OFF[k]
	var gap := open * 2.2
	for k in 2:
		if not shutters[k].dead:
			var s := -1.0 if k == 0 else 1.0
			shutters[k].position = center + Vector3(s * (gap + SHUTTER_X), 0, 0)


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
	match phase:
		0:
			center.z = move_toward(center.z, game.field_top + 6.5, 4.0 * dt)
			if st > 4.0:
				phase = 1
				st = 0.0
				for q in pods + shutters:
					q.armored = false
				game.boss_fight_started()
		1:
			fight_t += dt
			_eye_cycle(dt, CLOSED_A, OPEN_A)
			_pods(dt)
			if pods_alive() == 0 or fight_t > ENRAGE_T:
				_enrage()
		2:
			fight_t += dt
			center.x = sin(st * 0.6) * 5.0
			_eye_cycle(dt, CLOSED_B, OPEN_B)
			_pods(dt)
			if not open_want and cycle_t > 0.2 and cycle_t < CLOSED_B - 0.1:
				# the pod sockets bleed fire while the eye is shut
				spiral_t -= dt
				if spiral_t <= 0.0:
					spiral_t = 0.16
					spiral_a += 0.33
					for k in 4:
						var at: Vector3 = center + POD_OFF[k]
						if game.boss_can_fire(at):
							game.bullets.fire(at, spiral_a + k * PI / 2.0, 4.4, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if k % 2 == 0 else Bullets.SMALL)
		3:
			dying_t += dt
			if int(dying_t * 8.0) != int((dying_t - dt) * 8.0):
				var off := Vector3(randf_range(-5, 5), 0, randf_range(-3.5, 3.5))
				game.fx.explode(center + off, randf_range(1.5, 3.0), Vector3.ZERO, Models.STEEL_M)
				game.sfx.play("exp_m")
				game.shake(0.4)
			center.z += dt * 1.2
			if dying_t > 3.2:
				game.big_blast(center, 1.0, Models.STEEL_L)
				for k in 5:
					game.fx.explode(center + Vector3(randf_range(-5, 5), 0, randf_range(-3, 3)), 4.0, Vector3.ZERO, Models.GUN)
				game.sfx.play("exp_l")
				game.shake(2.0)
				destroyed = true
				finished = true
				visible = false
				for q in [eye] + pods + shutters:
					game.remove_enemy(q)
					q.visible = false
				game.boss_destroyed(self)
				return
	if phase == 1 or phase == 2:
		gaze.tick(dt)
	open = move_toward(open, 1.0 if open_want else 0.0, dt * 2.5)
	# shut, the eye is armoured while both shutters hold; with one shot off,
	# shots get in on that side
	eye.armored = phase == 0 or phase == 3 or (open < 0.7 and shutters_alive() == 2)
	eye.model.rotation.y += dt * (1.8 if phase == 2 else 0.6)
	_place()


## Pods gone (or time up): the fortress rages. It sways, the eye opens more
## often, the empty sockets spin shell spirals while it is shut, and every
## opening brings three gaze strikes, a longer flower and a wider shotgun.
func _enrage() -> void:
	phase = 2
	st = 0.0
	cycle_t = 0.0
	fired.clear()
	game.show_msg("CORTEX ENRAGED", "", 1.5, true)
	game.shake(0.8)


## One round of the eye: shut for `closed_time`, then open for `open_time`
## with its attacks, each energy shot announced on the eye.
func _eye_cycle(dt: float, closed_time: float, open_time: float) -> void:
	cycle_t += dt
	open_want = cycle_t > closed_time and cycle_t < closed_time + open_time
	var c := closed_time
	var w := Enemy.WINDUP_SHOT
	if open_want:
		if phase == 1:
			_warn_at("shotgun1", c + 0.3 + w, w, Game.Warn.SHOT)
			if _fire_once("shotgun1", c + 0.3 + w):
				game.bullets.fan(eye.position, game.bullets.aim(eye.position), 5, 14.0, 9.0, Bullets.ORB, self, Bullets.NEEDLE)
			_gaze(c + 1.0, 2, 0.5)
			_flower(c + 2.4, 3, 16, 4.0)
			_warn_at("shotgun2", c + 3.6 + w, w, Game.Warn.SHOT)
			if _fire_once("shotgun2", c + 3.6 + w):
				game.bullets.fan(eye.position, game.bullets.aim(eye.position), 5, 16.0, 9.5, Bullets.ORB, self)
		else:
			_gaze(c + 0.2, 3, 0.45)
			_flower(c + 1.4, 4, 20, 4.6)
			_warn_at("shotgun1", c + 2.9 + w, w, Game.Warn.SHOT)
			if _fire_once("shotgun1", c + 2.9 + w):
				game.bullets.fan(eye.position, game.bullets.aim(eye.position), 7, 28.0, 9.5, Bullets.ORB, self, Bullets.NEEDLE)
			if _fire_once("split", c + 3.8):
				# two big shells that burst into rings
				for s in [-1, 1]:
					game.bullets.fire(eye.position, game.bullets.aim(eye.position) + s * deg_to_rad(30.0), 4.2, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, 1.6)
					game.bullets.split(0.8, 10)
	if cycle_t > closed_time + open_time + 0.3:
		cycle_t = 0.0
		fired.clear()


## The eye's gaze strikes: `count` sights dropped on the ship one after
## another, `gap` apart, from `at` (each follows it, holds still and bursts).
func _gaze(at: float, count: int, gap: float) -> void:
	for i in count:
		if _fire_once("gaze%d" % i, at + i * gap):
			gaze.drop(eye, Vector3.ZERO, Vector3.ZERO, 0, i == 0, 1.0 if i % 2 == 0 else -1.0)


func _pods(dt: float) -> void:
	pod_t -= dt
	if pod_t > 0.0 or pods_alive() == 0:
		return
	pod_t = 1.1 if phase == 1 else 1.5
	for i in 4:
		pod_k = (pod_k + 1) % 4
		var q := pods[pod_k]
		if not q.dead:
			var at := q.position + Vector3(0, 0, 1.0)
			game.bullets.fan(at, game.bullets.aim(at), 5, 44.0, 6.0, Bullets.SHELL, self)
			break


## A flower from the eye: `waves` rings of breakable shells, each turned a
## little from the last, big and small by turns (no lock-on: shells can be
## shot down).
func _flower(at: float, waves: int, count: int, speed: float) -> void:
	for k in waves:
		if _fire_once("flower%d" % k, at + k * 0.33):
			flower_a += 0.21
			game.bullets.ring(eye.position, count, speed, Bullets.SHELL, self, flower_a)


func gauge() -> Dictionary:
	if phase < 1 or phase >= 3:
		return {}
	return {"frac": eye.hp / eye.max_hp, "color": Hud.CYAN if not eye.armored else Color(0.55, 0.6, 0.65), "name": INFO["name"], "name_color": Color(0.75, 0.95, 1.0), "x": 0.2, "w": 0.6, "h": 8.0, "name_y": 72.0}


func force_defeat() -> void:
	if phase < 3:
		game.kill(eye)


## "B": straight into the enraged phase, pods still up.
func viewer_skip(to: String) -> void:
	if to == "B":
		center.z = game.field_top + 6.5
		phase = 2
		st = 0.0
		cycle_t = 0.0
		fired.clear()
		for q in pods + shutters:
			q.armored = false
		_place()


func debug_state() -> String:
	var names := ["enter", "A", "B (enraged)", "dying"]
	return "phase %s %.1fs  eye %s %d/%d  pods %d" % [names[phase], st, "open" if not eye.armored else "shut", int(maxf(eye.hp, 0.0)), int(EYE_HP), pods_alive()]


func _die() -> void:
	defeated = true
	phase = 3
	dying_t = 0.0
	open_want = true
	gaze.clear()
	for q in pods + shutters:
		if not q.dead:
			game.kill(q)
	disarm()
	var conv := game.bullets.cancel_all()
	for b in conv:
		game.items.spawn(b, Items.ENERGY, 1.0)
	game.boss_dying()
