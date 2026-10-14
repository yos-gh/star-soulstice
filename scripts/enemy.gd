class_name Enemy
extends Node3D
## One enemy (or one part of a big enemy run by a `controller`).
## Air units fly on the play plane; ground units (turrets) sit on islands and
## are hit through their projection onto the plane (`hit_pos`).
##
## Kinds:
##   dart       formation fighter: fast fly-in along a curve, one aimed shell
##   swirl      saucer looping in from the side, one aimed energy orb
##   rammer     dives, then homes in to ram the player
##   container  drifts down; breaking it drops a POWER item
##   turret     ground gun on an island: aimed shell bursts
##   bulwark    mid-size: slow, tough; shell walls + an energy shotgun, with
##              quiet gaps so you can close in with the Spear
##   rock       drifting asteroid chunk (debris belt): soaks shots, rams
##   part       a piece of Lazaro / the boss (moved by its controller)

var game: Game
var kind := ""
var hp := 1.0
var max_hp := 1.0
var radius := 0.8
var score := 100
var energy_drop := 2.0
var blast := 1.0
var counts := true
var ground := false
var armored := false
var intangible := false
var ram := true
var drops_power := false
var leaves := true
var entered := false
var dead := false
var controller: Object = null
var hit_pos := Vector3.ZERO
var vel := Vector3.ZERO
var t := 0.0
var p := {}
var flash := 0.0
var fire_t := 0.0
var step := 0
var fired := false
var model: MeshInstance3D
var head: MeshInstance3D
var tint := Color(0, 0, 0)  # extra overlay colour (warnings), added to the hit flash
var warn_t := 0.0  # telegraph: seconds until the warned attack
var warn_dur := 0.0
var warn_col := Color(0, 0, 0)

const WINDUP_SHOT := 0.5  # telegraph time before unbreakable shots
const WINDUP_MOVE := 0.6  # before charges
var overlay_key := -1

static var _overlays := {}


func setup(g: Game, k: String, params: Dictionary) -> void:
	game = g
	kind = k
	p = params
	var mesh_name := k
	match k:
		"dart":
			hp = 1.0
			radius = 0.75
			score = 100
			energy_drop = 2.0
		"swirl":
			hp = 2.0
			radius = 0.9
			score = 200
			energy_drop = 3.0
		"rammer":
			hp = 3.0
			radius = 0.85
			score = 300
			energy_drop = 3.0
		"container":
			hp = 14.0
			radius = 1.1
			score = 1000
			energy_drop = 4.0
			counts = false
			ram = false
			drops_power = true
			blast = 1.6
		"turret":
			hp = 5.0
			radius = 0.8
			score = 400
			energy_drop = 4.0
			counts = false
			ground = true
			ram = false
			mesh_name = "turret_base"
			fire_t = 1.0 + randf() * 1.5
		"rock":
			var big: bool = p.get("big", false)
			hp = 8.0 if big else 3.0
			radius = 1.6 if big else 0.9
			score = 500 if big else 150
			energy_drop = 8.0 if big else 3.0
			blast = 1.8 if big else 1.0
			counts = false
			mesh_name = "rock_l" if big else "rock_s"
		"bulwark":
			hp = 120.0
			radius = 2.1
			score = 3000
			energy_drop = 14.0
			blast = 3.0
		"part":
			mesh_name = p.get("mesh", "")
			leaves = false
			counts = false
	max_hp = hp
	if mesh_name != "":
		model = MeshInstance3D.new()
		model.mesh = Vox.get_mesh(mesh_name)
		add_child(model)
	if k == "turret":
		head = MeshInstance3D.new()
		head.mesh = Vox.get_mesh("turret_head")
		head.position.y = 0.3
		add_child(head)


func face(v: Vector3) -> void:
	if v.length_squared() > 0.0001:
		rotation.y = atan2(-v.x, -v.z)


func tick(dt: float) -> void:
	t += dt
	flash = maxf(0.0, flash - dt * 7.0)
	warn_t = maxf(0.0, warn_t - dt)
	match kind:
		"dart":
			_dart(dt)
		"swirl":
			_swirl(dt)
		"rammer":
			_rammer(dt)
		"container":
			position.z += 2.0 * dt * game.scroll_speed / Game.SCROLL
			position.x = float(p["x"]) + sin(t * 1.1) * 1.4
			model.rotation.y += dt * 0.9
			model.rotation.x = sin(t * 1.7) * 0.25
		"turret":
			_turret(dt)
		"rock":
			if t <= dt * 1.5:
				vel = Vector3(p.get("vx", 0.0), 0, p.get("vz", 3.0))
				model.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
			position += vel * dt
			model.rotation.x += dt * float(p.get("spin", 0.7))
			model.rotation.y += dt * 0.3
		"bulwark":
			_bulwark(dt)
	hit_pos = game.to_plane(global_position + Vector3(0, 0.45, 0)) if ground else position
	if not entered and game.on_field(hit_pos, -0.6):
		entered = true
	_shade()


func _shade() -> void:
	if model == null:
		return
	# quantised so a handful of shared overlay materials cover every case
	var c := Color(1.0, 0.85, 0.7) * (flash * 0.85) + tint
	if warn_t > 0.0:
		# telegraph: a warm pulse that quickens as the attack nears
		var f := 1.0 - warn_t / maxf(warn_dur, 0.01)
		var pulse := 0.5 + 0.5 * sin(warn_t * lerpf(18.0, 40.0, f))
		c += warn_col * (0.25 + 0.5 * f) * pulse
	var q := Vector3i(int(c.r * 8.0 + 0.5), int(c.g * 8.0 + 0.5), int(c.b * 8.0 + 0.5))
	var key := (q.x * 64 + q.y) * 64 + q.z
	if key == overlay_key:
		return
	overlay_key = key
	var mat: Material = null
	if key != 0:
		if not _overlays.has(key):
			var m := ShaderMaterial.new()
			m.shader = preload("res://shaders/flash.gdshader")
			m.set_shader_parameter("col", Color(q.x / 8.0, q.y / 8.0, q.z / 8.0))
			_overlays[key] = m
		mat = _overlays[key]
	model.material_overlay = mat
	if head != null:
		head.material_overlay = mat


# ------------------------------------------------------------ behaviours

## params: x, vx, vz, turn_t, turn (rad/s, + = clockwise on screen),
## turn_dur, fire_at
func _dart(dt: float) -> void:
	if t <= dt * 1.5:
		vel = Vector3(p.get("vx", 0.0), 0, p.get("vz", 13.0))
	var tt: float = p.get("turn_t", 99.0)
	if t > tt and t < tt + float(p.get("turn_dur", 1.0)):
		vel = vel.rotated(Vector3.UP, -float(p.get("turn", 0.0)) * dt)
	position += vel * dt
	face(vel)
	model.rotation.z = lerpf(model.rotation.z, clampf(float(p.get("turn", 0.0)) * 0.25, -0.8, 0.8) if (t > tt and t < tt + float(p.get("turn_dur", 1.0))) else 0.0, 6.0 * dt)
	if not fired and t >= float(p.get("fire_at", 0.7)) and game.can_fire(position):
		fired = true
		game.bullets.fire(position, game.bullets.aim(position), 8.0, Bullets.SHELL, self, Bullets.NEEDLE)


## params: c (Vector3), r, a0, w (rad/s), loops
func _swirl(dt: float) -> void:
	var c: Vector3 = p["c"]
	var r: float = p["r"]
	var w: float = p["w"]
	var dur: float = float(p.get("loops", 1.25)) * TAU / absf(w)
	if t < dur:
		var a: float = float(p["a0"]) + w * t
		position = c + Vector3(cos(a), 0, sin(a)) * r
		vel = Vector3(-sin(a), 0, cos(a)) * r * w
	else:
		position += vel * dt
	model.rotation.y += dt * 5.0
	model.rotation.z = sin(t * 3.0) * 0.2
	if not fired and t >= dur * 0.45 - WINDUP_SHOT and game.can_fire(position):
		fired = true
		game.warn_then(self, WINDUP_SHOT, Game.Warn.SHOT, func() -> void:
			game.bullets.fire(position, game.bullets.aim(position), 6.5, Bullets.ORB, self))


func _rammer(dt: float) -> void:
	# dive in, stop and wind up (facing the player), then charge
	if t < 0.8:
		vel = Vector3(0, 0, 9.0)
		face(vel)
	elif t < 0.8 + WINDUP_MOVE:
		if not fired:
			fired = true
			game.warn(self, WINDUP_MOVE, Game.Warn.MOVE, radius, "player")
		vel = vel.move_toward(Vector3.ZERO, 24.0 * dt)
		var look := game.player.position - position
		rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), 8.0 * dt)
		model.rotation.z += dt * 30.0 * (t - 0.8) / WINDUP_MOVE
	elif t < 0.8 + WINDUP_MOVE + 1.4:
		if step == 0:
			step = 1
			var to := game.player.position - position
			vel = (to.normalized() if to.length() > 0.5 else Vector3(0, 0, 1)) * 8.0
		# fast, with only a little steering: dodgeable once it commits
		var spd := minf(21.0, vel.length() + 30.0 * dt)
		var to2 := game.player.position - position
		if game.player.alive and to2.length() > 0.5:
			vel = vel.lerp(to2.normalized() * spd, clampf(0.8 * dt, 0.0, 1.0)).normalized() * spd
		else:
			vel = vel.normalized() * spd
		face(vel)
	else:
		face(vel)
	position += vel * dt
	model.rotation.z += dt * 9.0


func _turret(dt: float) -> void:
	var hp_ := hit_pos
	if not game.player.alive:
		return
	var d := game.player.position - hp_
	head.rotation.y = lerp_angle(head.rotation.y, atan2(-d.x, -d.z), 6.0 * dt)
	fire_t -= dt
	if fire_t <= 0.0:
		if game.on_field(hp_, -1.0) and d.length() > 4.5 and game.state == Game.State.PLAY:
			if step < 3:
				game.bullets.fire(hp_, atan2(d.z, d.x), 7.5, Bullets.SHELL, self, Bullets.NEEDLE)
				step += 1
				fire_t = 0.14
				return
		step = 0
		fire_t = 2.6


## params: x, stay
func _bulwark(dt: float) -> void:
	var hold_z := game.field_top + 5.0
	var stay: float = p.get("stay", 11.0)
	if position.z < hold_z and t < stay:
		position.z = move_toward(position.z, hold_z, 7.0 * dt)
		fire_t = 0.8
	elif t < stay:
		position.x = float(p["x"]) + sin(t * 0.6) * 1.6
		fire_t -= dt
		if fire_t <= 0.0 and game.can_fire(position):
			var down := PI / 2.0
			match step % 5:
				0:
					game.bullets.fan(position + Vector3(0, 0, 1.2), down, 11, 110.0, 5.0, Bullets.SHELL, self)
					fire_t = 0.4
				1:
					game.bullets.fan(position + Vector3(0, 0, 1.2), down + deg_to_rad(5.5), 10, 99.0, 5.5, Bullets.SHELL, self)
					fire_t = 1.2
				2:
					# announce the energy shotguns
					game.warn(self, WINDUP_SHOT + 0.15, Game.Warn.SHOT, radius)
					fire_t = WINDUP_SHOT + 0.15
				3:
					game.bullets.fan(position + Vector3(0, 0, 1.5), game.bullets.aim(position), 5, 14.0, 9.0, Bullets.ORB, self, Bullets.NEEDLE)
					fire_t = 0.45
				4:
					game.bullets.fan(position + Vector3(0, 0, 1.5), game.bullets.aim(position), 4, 10.0, 10.0, Bullets.ORB, self)
					fire_t = 2.6  # quiet gap: come in with the Spear
			step += 1
	else:
		position.z += 2.6 * dt
	model.rotation.z = sin(t * 0.9) * 0.06
