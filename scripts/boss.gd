class_name Boss
extends Node3D
## Stage 1 boss STAR CORTEX (an homage to Star Soldier's Star Brain): an
## octagonal fortress whose great eye opens and shuts. The hull is armour
## (two blocks on the flanks; a channel in front of the eye lets shots in);
## four pods at the corners fire shell fans; the eye is only vulnerable while
## its shutters are open, and then it answers with light energy patterns.
## Phase A: pods + eye cycle, hatches release darts.
## Phase B (pods gone or after a while): the fortress sways, spins shell
## spirals while shut and adds heavy orbs (not erasable by the Spear) when
## open. There are quiet gaps in every cycle to come in with the Spear.

const EYE_HP := 800.0
const POD_HP := 90.0
const POD_OFF := [Vector3(-5.6, 0, -2.4), Vector3(5.6, 0, -2.4), Vector3(-4.3, 0, 3.3), Vector3(4.3, 0, 3.3)]
const ARMOUR_OFF := [Vector3(-4.0, 0, 0.0), Vector3(4.0, 0, 0.0)]
const ARMOUR_R := 2.7

var game: Game
var hull: MeshInstance3D
var armour: Array[Enemy] = []
var eye: Enemy
var pods: Array[Enemy] = []
var shutter_l: MeshInstance3D
var shutter_r: MeshInstance3D
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
var hatch_t := 5.0
var pod_t := 1.0
var pod_k := 0
var destroyed := false
var dying_t := 0.0


func setup(g: Game) -> void:
	game = g
	center = Vector3(0, 0, game.field_top - 9.0)
	# order matters: shots test enemies in list order, so the eye and pods
	# come before the hull armour that would otherwise swallow them.
	eye = game.spawn_part(self, "boss_eye", 1.9)
	eye.hp = EYE_HP
	eye.max_hp = EYE_HP
	eye.armored = true
	eye.score = 50000
	eye.blast = 6.0
	for k in 4:
		var e := game.spawn_part(self, "boss_pod", 1.45)
		e.hp = POD_HP
		e.max_hp = POD_HP
		e.score = 5000
		e.energy_drop = 12.0
		e.blast = 2.5
		e.armored = true
		pods.append(e)
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("boss_hull")
	add_child(hull)
	for k in 2:
		var a := game.spawn_part(self, "", ARMOUR_R)
		a.armored = true
		a.hp = 1e9
		armour.append(a)
	shutter_l = MeshInstance3D.new()
	shutter_l.mesh = Vox.get_mesh("boss_shutter")
	add_child(shutter_l)
	shutter_r = MeshInstance3D.new()
	shutter_r.mesh = shutter_l.mesh
	shutter_r.scale = Vector3(-1, 1, 1)
	add_child(shutter_r)
	_place()


func on_hit(e: Enemy, dmg: float) -> float:
	return dmg


func on_part_killed(e: Enemy) -> void:
	if e == eye:
		_die()
	elif pods.has(e):
		game.shake(0.8)


func pods_alive() -> int:
	var c := 0
	for q in pods:
		if not q.dead:
			c += 1
	return c


func _place() -> void:
	hull.position = center
	for k in 2:
		armour[k].position = center + ARMOUR_OFF[k]
	eye.position = center + Vector3(0, -0.4, 0)
	for k in 4:
		if not pods[k].dead:
			pods[k].position = center + POD_OFF[k]
	var gap := open * 2.2
	shutter_l.position = center + Vector3(-gap, 1.25, 0)
	shutter_r.position = center + Vector3(gap, 1.25, 0)


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
				for q in pods:
					q.armored = false
				game.boss_fight_started()
		1:
			fight_t += dt
			_eye_cycle(dt, 4.6, 3.2)
			_pods(dt)
			hatch_t -= dt
			if hatch_t <= 0.0:
				hatch_t = 8.0
				for s in [-1, 1]:
					game.spawn_enemy("dart", {"x": center.x + s * 6.0, "z": center.z + 1.0, "vx": s * 4.0, "vz": 9.0, "turn_t": 0.5, "turn": -s * 1.6, "turn_dur": 1.0, "fire_at": 0.9, "counts": false})
			if pods_alive() == 0 or fight_t > 45.0:
				phase = 2
				st = 0.0
				cycle_t = 0.0
				fired.clear()
				game.show_msg("CORTEX ENRAGED", "", 1.5)
		2:
			fight_t += dt
			center.x = sin(st * 0.45) * 4.0
			_eye_cycle(dt, 3.2, 3.4)
			_pods(dt)
			if not open_want and cycle_t > 0.6 and cycle_t < 2.8:
				spiral_t -= dt
				if spiral_t <= 0.0:
					spiral_t = 0.16
					spiral_a += 0.42
					for arm in 3:
						game.bullets.fire(center + Vector3(0, 0, 0.5), spiral_a + arm * TAU / 3.0, 5.5, Bullets.SHELL, self)
		3:
			dying_t += dt
			if int(dying_t * 8.0) != int((dying_t - dt) * 8.0):
				var off := Vector3(randf_range(-5, 5), 0, randf_range(-3.5, 3.5))
				game.fx.explode(center + off, randf_range(1.5, 3.0), Vector3.ZERO, Models.PLUM)
				game.sfx.play("exp_m")
				game.shake(0.4)
			center.z += dt * 1.2
			if dying_t > 3.2:
				game.fx.explode(center, 9.0, Vector3.ZERO, Models.PLUM)
				for k in 5:
					game.fx.explode(center + Vector3(randf_range(-5, 5), 0, randf_range(-3, 3)), 4.0, Vector3.ZERO, Models.CRIMSON)
				game.sfx.play("exp_l")
				game.shake(2.0)
				destroyed = true
				visible = false
				for q in [eye] + armour + pods:
					game.remove_enemy(q)
					q.visible = false
				game.boss_destroyed()
				return
	open = move_toward(open, 1.0 if open_want else 0.0, dt * 2.5)
	eye.armored = open < 0.7 or phase == 3
	eye.model.rotation.y += dt * 0.6
	_place()


func _eye_cycle(dt: float, closed_time: float, open_time: float) -> void:
	cycle_t += dt
	open_want = cycle_t > closed_time and cycle_t < closed_time + open_time
	var o := closed_time + 0.4
	if open_want:
		if _fire_once("shotgun1", o + 0.2):
			game.bullets.fan(eye.position, game.bullets.aim(eye.position), 5, 14.0, 9.0, Bullets.ORB, self, Bullets.NEEDLE)
		if _fire_once("ring", o + 1.2):
			game.bullets.ring(eye.position, 14, 4.8, Bullets.ORB, self, 0.0, 3, game.bullets.aim(eye.position))
		if phase == 2 and _fire_once("heavy", o + 0.8):
			game.bullets.fan(eye.position, game.bullets.aim(eye.position), 3, 30.0, 4.6, Bullets.HEAVY, self)
		if _fire_once("shotgun2", o + 2.1):
			game.bullets.fan(eye.position, game.bullets.aim(eye.position), 5, 16.0, 9.5, Bullets.ORB, self)
	if cycle_t > closed_time + open_time + 0.3:
		cycle_t = 0.0
		fired.clear()


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


func _die() -> void:
	phase = 3
	dying_t = 0.0
	open_want = true
	for q in pods:
		if not q.dead:
			game.kill(q)
	var conv := game.bullets.cancel_all()
	for b in conv:
		game.items.spawn(b, Items.ENERGY, 1.0)
	game.boss_dying()
