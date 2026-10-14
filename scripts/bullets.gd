class_name Bullets
extends Node3D
## Enemy bullets on the play plane (y = 0), in packed arrays.
## Angles: 0 = +x (right), PI/2 = +z (down-screen).
##
## Kinds (every kind comes as a round ball or a needle):
##   SHELL  physical: shootable (blocks your shots, breaks after `hp`),
##          low threat, can be plentiful. Cool blue, dark centre, bright outline.
##   ORB    energy: cannot be shot; only the Spear aura or killing its
##          shooter removes it. Keep these few. Warm orange, white-hot centre.
##   HEAVY  big energy ball (boss): not even the Spear erases it. Warm red.
## Every bullet remembers its shooter so a kill can turn them into energy.

enum { SHELL, ORB, HEAVY }
enum { ROUND, NEEDLE }

const MAX := 1200
const RADIUS := [0.27, 0.23, 0.5]  # round hit radius per kind
const NEEDLE_RADIUS := 0.2
const SIZE := [0.68, 0.62, 1.5]  # round sprite diameter per kind
const NEEDLE_W := 0.36
const NEEDLE_L := 1.1
const COLOR := [Color(0.35, 0.78, 1.0), Color(1.0, 0.5, 0.22), Color(1.0, 0.28, 0.36)]

var game: Game
var pos := PackedVector3Array()
var vel := PackedVector3Array()
var acc := PackedFloat32Array()
var tspd := PackedFloat32Array()
var kind := PackedInt32Array()
var shape := PackedInt32Array()
var hp := PackedFloat32Array()
var owner_id := PackedInt64Array()
var n := 0
var bounds := Rect2(-30, -30, 60, 60)  # x, z

var sprites: MultiMeshInstance3D


func _ready() -> void:
	pos.resize(MAX)
	vel.resize(MAX)
	acc.resize(MAX)
	tspd.resize(MAX)
	kind.resize(MAX)
	shape.resize(MAX)
	hp.resize(MAX)
	owner_id.resize(MAX)
	sprites = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := PlaneMesh.new()
	q.size = Vector2(1, 1)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ebullet.gdshader")
	mat.render_priority = 3
	q.material = mat
	mm.mesh = q
	mm.instance_count = MAX
	mm.visible_instance_count = 0
	sprites.multimesh = mm
	sprites.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprites.custom_aabb = AABB(Vector3(-60, -10, -60), Vector3(120, 20, 120))
	add_child(sprites)


func fire(p: Vector3, ang: float, speed: float, k: int, owner: Object, shp := ROUND, accel := 0.0, to_speed := 0.0) -> void:
	if n >= MAX:
		return
	pos[n] = Vector3(p.x, 0.0, p.z)
	vel[n] = Vector3(cos(ang), 0.0, sin(ang)) * speed
	acc[n] = accel
	tspd[n] = to_speed
	kind[n] = k
	shape[n] = NEEDLE if (shp == NEEDLE and k != HEAVY) else ROUND
	hp[n] = 1.0
	owner_id[n] = owner.get_instance_id() if owner != null else 0
	n += 1


func aim(from: Vector3) -> float:
	var d := game.player.position - from
	return atan2(d.z, d.x)


## `count` bullets spread over `spread` degrees around `ang`.
func fan(p: Vector3, ang: float, count: int, spread: float, speed: float, k: int, owner: Object, shp := ROUND) -> void:
	if count == 1:
		fire(p, ang, speed, k, owner, shp)
		return
	var s := deg_to_rad(spread)
	for i in count:
		fire(p, ang - s * 0.5 + s * i / (count - 1), speed, k, owner, shp)


## A ring with a gap of `gap` bullets centred on `gap_ang` (gap 0 = full).
func ring(p: Vector3, count: int, speed: float, k: int, owner: Object, offset := 0.0, gap := 0, gap_ang := 0.0, shp := ROUND) -> void:
	for i in count:
		var a := offset + TAU * i / count
		if gap > 0:
			var d := absf(wrapf(a - gap_ang, -PI, PI))
			if d < TAU / count * (gap * 0.5):
				continue
		fire(p, a, speed, k, owner, shp)


func radius(i: int) -> float:
	return NEEDLE_RADIUS if shape[i] == NEEDLE else RADIUS[kind[i]]


func _remove(i: int) -> void:
	n -= 1
	pos[i] = pos[n]
	vel[i] = vel[n]
	acc[i] = acc[n]
	tspd[i] = tspd[n]
	kind[i] = kind[n]
	shape[i] = shape[n]
	hp[i] = hp[n]
	owner_id[i] = owner_id[n]


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


## A player shot at p hits a shell: the shell takes the damage. Returns
## Vector3(INF, ...) for no hit, else the shell's position with y = 1 if it
## broke and y = 0 if it held.
func shoot_shell(p: Vector3, r: float, dmg: float) -> Vector3:
	for i in n:
		if kind[i] != SHELL:
			continue
		var d := pos[i] - p
		var rr := r + radius(i) + 0.12
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
		if p.x < bounds.position.x or p.x > bounds.end.x or p.z < bounds.position.y or p.z > bounds.end.y:
			_remove(i)
			continue
		i += 1


## True if a bullet touches the circle (p, r); that bullet is removed.
func hit_test(p: Vector3, r: float) -> bool:
	for i in n:
		var d := pos[i] - p
		var rr := r + radius(i)
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
	var mm := sprites.multimesh
	mm.visible_instance_count = n
	var pulse := 1.0 + 0.06 * sin(Time.get_ticks_msec() * 0.025)
	for i in n:
		var k := kind[i]
		var b: Basis
		var aspect := 1.0
		if shape[i] == NEEDLE:
			var dir := vel[i].normalized()
			if dir.length_squared() < 0.5:
				dir = Vector3(0, 0, 1)
			b = Basis(Vector3(-dir.z, 0, dir.x) * NEEDLE_W, Vector3.UP, dir * NEEDLE_L)
			aspect = NEEDLE_L / NEEDLE_W
		else:
			var s: float = SIZE[k] * (pulse if k != SHELL else 1.0)
			b = Basis.from_scale(Vector3(s, 1.0, s))
		# drawn just above the ships, on the view ray through its plane point so
		# what you see lines up with what hits
		mm.set_instance_transform(i, Transform3D(b, game.from_plane(pos[i], 0.32)))
		mm.set_instance_color(i, COLOR[k])
		mm.set_instance_custom_data(i, Color(1.0 if k == SHELL else 0.0, aspect, 0.0, 0.0))
