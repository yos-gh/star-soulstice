class_name Bullets
extends Node3D
## Enemy bullets on the play plane (y = 0), in packed arrays.
## Angles: 0 = +x (right), PI/2 = +z (down-screen).
##
## Kinds:
##   SHELL  physical: shootable (blocks your shots, breaks after `hp`),
##          low threat, can be plentiful. Drawn as small spinning voxels.
##   ORB    energy: cannot be shot; only the Spear aura or killing its
##          shooter removes it. Keep these few.
##   HEAVY  big energy orb (boss): not even the Spear erases it.
## Every bullet remembers its shooter so a kill can turn them into energy.

enum { SHELL, ORB, HEAVY }

const MAX := 1200
const RADIUS := [0.26, 0.22, 0.5]

var game: Game
var pos := PackedVector3Array()
var vel := PackedVector3Array()
var acc := PackedFloat32Array()
var tspd := PackedFloat32Array()
var kind := PackedInt32Array()
var hp := PackedFloat32Array()
var owner_id := PackedInt64Array()
var spin := PackedFloat32Array()
var n := 0
var bounds := Rect2(-30, -30, 60, 60)  # x, z

var shells: MultiMeshInstance3D
var orbs: MultiMeshInstance3D


func _ready() -> void:
	pos.resize(MAX)
	vel.resize(MAX)
	acc.resize(MAX)
	tspd.resize(MAX)
	kind.resize(MAX)
	hp.resize(MAX)
	owner_id.resize(MAX)
	spin.resize(MAX)
	shells = MultiMeshInstance3D.new()
	var sm := MultiMesh.new()
	sm.transform_format = MultiMesh.TRANSFORM_3D
	sm.mesh = Vox.get_mesh("shell")
	sm.instance_count = MAX
	sm.visible_instance_count = 0
	shells.multimesh = sm
	shells.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shells.custom_aabb = AABB(Vector3(-60, -10, -60), Vector3(120, 20, 120))
	add_child(shells)
	orbs = MultiMeshInstance3D.new()
	var om := MultiMesh.new()
	om.transform_format = MultiMesh.TRANSFORM_3D
	om.use_colors = true
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/bullet.gdshader")
	mat.render_priority = 3
	q.material = mat
	om.mesh = q
	om.instance_count = MAX
	om.visible_instance_count = 0
	orbs.multimesh = om
	orbs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orbs.custom_aabb = shells.custom_aabb
	add_child(orbs)


func fire(p: Vector3, ang: float, speed: float, k: int, owner: Object, accel := 0.0, to_speed := 0.0) -> void:
	if n >= MAX:
		return
	pos[n] = Vector3(p.x, 0.0, p.z)
	vel[n] = Vector3(cos(ang), 0.0, sin(ang)) * speed
	acc[n] = accel
	tspd[n] = to_speed
	kind[n] = k
	hp[n] = 1.0
	owner_id[n] = owner.get_instance_id() if owner != null else 0
	spin[n] = randf() * TAU
	n += 1


func aim(from: Vector3) -> float:
	var d := game.player.position - from
	return atan2(d.z, d.x)


## `count` bullets spread over `spread` degrees around `ang`.
func fan(p: Vector3, ang: float, count: int, spread: float, speed: float, k: int, owner: Object, accel := 0.0, to_speed := 0.0) -> void:
	if count == 1:
		fire(p, ang, speed, k, owner, accel, to_speed)
		return
	var s := deg_to_rad(spread)
	for i in count:
		fire(p, ang - s * 0.5 + s * i / (count - 1), speed, k, owner, accel, to_speed)


## A ring with a gap of `gap` bullets centred on `gap_ang` (gap 0 = full).
func ring(p: Vector3, count: int, speed: float, k: int, owner: Object, offset := 0.0, gap := 0, gap_ang := 0.0) -> void:
	for i in count:
		var a := offset + TAU * i / count
		if gap > 0:
			var d := absf(wrapf(a - gap_ang, -PI, PI))
			if d < TAU / count * (gap * 0.5):
				continue
		fire(p, a, speed, k, owner)


func _remove(i: int) -> void:
	n -= 1
	pos[i] = pos[n]
	vel[i] = vel[n]
	acc[i] = acc[n]
	tspd[i] = tspd[n]
	kind[i] = kind[n]
	hp[i] = hp[n]
	owner_id[i] = owner_id[n]
	spin[i] = spin[n]


## Removes the bullets fired by `owner`; returns where they were.
func cancel_owner(owner: Object) -> PackedVector3Array:
	var out := PackedVector3Array()
	var id := owner.get_instance_id()
	var i := 0
	while i < n:
		if owner_id[i] == id:
			out.push_back(pos[i])
			_remove(i)
			continue
		i += 1
	return out


func cancel_all() -> PackedVector3Array:
	var out := pos.slice(0, n)
	n = 0
	return out


## Spear: erases shells and orbs (not HEAVY) within r of p, and inside the
## lance rectangle; returns where they were.
func cancel_spear(p: Vector3, r: float, hw: float, length: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var i := 0
	while i < n:
		if kind[i] != HEAVY:
			var d := pos[i] - p
			var in_ring := d.x * d.x + d.z * d.z < r * r
			var in_lance := absf(d.x) < hw and d.z < 0.0 and d.z > -length
			if in_ring or in_lance:
				out.push_back(pos[i])
				_remove(i)
				continue
		i += 1
	return out


## A player shot at p hits a shell? The shell takes the damage; returns true
## if the shot was blocked. `broke` receives the position of a broken shell.
func shoot_shell(p: Vector3, r: float, dmg: float) -> Vector3:
	for i in n:
		if kind[i] != SHELL:
			continue
		var d := pos[i] - p
		var rr := r + RADIUS[SHELL] + 0.12
		if d.x * d.x + d.z * d.z < rr * rr:
			hp[i] -= dmg
			var at := pos[i]
			if hp[i] <= 0.0:
				_remove(i)
				return Vector3(at.x, 1.0, at.z)
			return Vector3(at.x, 0.0, at.z)
	return Vector3(INF, 0, 0)


func tick(dt: float) -> void:
	var i := 0
	while i < n:
		var a := acc[i]
		if a != 0.0:
			var v := vel[i]
			var s := v.length()
			var ns := move_toward(s, tspd[i], absf(a) * dt)
			if s > 0.0001:
				vel[i] = v * (ns / s)
			if ns == tspd[i]:
				acc[i] = 0.0
		var p := pos[i] + vel[i] * dt
		pos[i] = p
		spin[i] += dt * 7.0
		if p.x < bounds.position.x or p.x > bounds.end.x or p.z < bounds.position.y or p.z > bounds.end.y:
			_remove(i)
			continue
		i += 1


## True if a bullet touches the circle (p, r); that bullet is removed.
func hit_test(p: Vector3, r: float) -> bool:
	for i in n:
		var d := pos[i] - p
		var rr: float = r + RADIUS[kind[i]]
		if d.x * d.x + d.z * d.z < rr * rr:
			_remove(i)
			return true
	return false


func count_near(p: Vector3, r: float) -> int:
	var c := 0
	for i in n:
		var d := pos[i] - p
		if d.x * d.x + d.z * d.z < r * r:
			c += 1
	return c


func draw() -> void:
	var sm := shells.multimesh
	var om := orbs.multimesh
	var si := 0
	var oi := 0
	var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.025)
	for i in n:
		match kind[i]:
			SHELL:
				var b := Basis(Vector3(0.6, 1.0, 0.3).normalized(), spin[i])
				sm.set_instance_transform(si, Transform3D(b, pos[i] + Vector3(0, 0.35, 0)))
				si += 1
			ORB:
				var s := 0.78 * pulse
				om.set_instance_transform(oi, Transform3D(Basis.from_scale(Vector3(s, s, s)), pos[i] + Vector3(0, 0.4, 0)))
				om.set_instance_color(oi, Color(1.0, 0.25, 0.7))
				oi += 1
			HEAVY:
				var s := 1.5 * pulse
				om.set_instance_transform(oi, Transform3D(Basis.from_scale(Vector3(s, s, s)), pos[i] + Vector3(0, 0.4, 0)))
				om.set_instance_color(oi, Color(0.7, 0.3, 1.0))
				oi += 1
	sm.visible_instance_count = si
	om.visible_instance_count = oi
