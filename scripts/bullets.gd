class_name Bullets
extends Node3D
## Enemy bullets on the play plane (y = 0), in packed arrays.
## Angles: 0 = +x (right), PI/2 = +z (down-screen).
##
## Kinds (every kind comes as a round ball or a needle, a rounded bar a
## little brighter at the head):
##   SHELL  physical: shootable (blocks your shots, breaks after `hp`),
##          low threat: the curtains of mid-size enemies and bosses. Cool
##          blue, dark centre, bright outline.
##   ORB    energy: cannot be shot; only the Spear aura or killing its
##          shooter removes it. The small fighters' and turrets' aimed shots,
##          always announced (Game.warn). Warm orange, white-hot centre.
##   HEAVY  big energy ball (boss): not even the Spear erases it. Warm red.
## Every bullet remembers its shooter so a kill can turn them into energy.
## Ground guns `launch` theirs: for LIFT seconds the bullet climbs from the
## gun up to the flight level (drawn small and dim, rising along the view
## ray) and cannot hit the ship yet.

enum { SHELL, ORB, HEAVY }
enum { ROUND, NEEDLE }

const MAX := 1200
const RADIUS := [0.27, 0.23, 0.5]  # round hit radius per kind
const NEEDLE_RADIUS := 0.2
const SIZE := [0.68, 0.62, 1.5]  # round sprite diameter per kind
const NEEDLE_W := 0.36
const NEEDLE_L := 1.1
const BIG := 1.22  # curtains mix big and small bullets side by side
const SMALL := 0.82
const COLOR := [Color(0.35, 0.78, 1.0), Color(1.0, 0.5, 0.22), Color(1.0, 0.28, 0.36)]
const LIFT := 0.4  # seconds a launched bullet takes to climb to the flight level

var game: Game
var pos := PackedVector3Array()
var vel := PackedVector3Array()
var acc := PackedFloat32Array()
var tspd := PackedFloat32Array()
var kind := PackedInt32Array()
var shape := PackedInt32Array()
var hp := PackedFloat32Array()
var owner_id := PackedInt64Array()
var lift := PackedFloat32Array()  # seconds left climbing (launched bullets)
var lift_y := PackedFloat32Array()  # height it was launched from
var size := PackedFloat32Array()  # x the kind's size (curtains vary it a little)
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
	lift.resize(MAX)
	lift_y.resize(MAX)
	size.resize(MAX)
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


func fire(p: Vector3, ang: float, speed: float, k: int, owner: Object, shp := ROUND, accel := 0.0, to_speed := 0.0, sz := 1.0) -> void:
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
	lift[n] = 0.0
	size[n] = sz
	n += 1


## Fires from a ground gun at `muzzle` (a point below the play plane): the
## bullet starts on the plane where the muzzle is seen and climbs for LIFT.
func launch(muzzle: Vector3, ang: float, speed: float, k: int, owner: Object, shp := ROUND) -> void:
	if n >= MAX:
		return
	fire(game.to_plane(muzzle), ang, speed, k, owner, shp)
	lift[n - 1] = LIFT
	lift_y[n - 1] = muzzle.y


func aim(from: Vector3) -> float:
	var d := game.player.position - from
	return atan2(d.z, d.x)


## `count` bullets spread over `spread` degrees around `ang`. Big and small
## bullets take turns across it (the middle one big), so the curtain is
## never uniform; `sz` > 0 makes the whole volley that size instead (to
## pair a volley of BIG with one of SMALL fired just after it).
func fan(p: Vector3, ang: float, count: int, spread: float, speed: float, k: int, owner: Object, shp := ROUND, sz := 0.0) -> void:
	if count == 1:
		fire(p, ang, speed, k, owner, shp, 0.0, 0.0, sz if sz > 0.0 else 1.0)
		return
	var s := deg_to_rad(spread)
	var mid := (count - 1) / 2
	for i in count:
		var f := float(i) / (count - 1)
		var big := (i - mid) % 2 == 0
		fire(p, ang - s * 0.5 + s * f, speed, k, owner, shp, 0.0, 0.0, sz if sz > 0.0 else (BIG if big else SMALL))


## A ring with a gap of `gap` bullets centred on `gap_ang` (gap 0 = full);
## big and small bullets take turns round it.
func ring(p: Vector3, count: int, speed: float, k: int, owner: Object, offset := 0.0, gap := 0, gap_ang := 0.0, shp := ROUND) -> void:
	for i in count:
		var a := offset + TAU * i / count
		if gap > 0:
			var d := absf(wrapf(a - gap_ang, -PI, PI))
			if d < TAU / count * (gap * 0.5):
				continue
		fire(p, a, speed, k, owner, shp, 0.0, 0.0, BIG if i % 2 == 0 else SMALL)


func radius(i: int) -> float:
	return (NEEDLE_RADIUS if shape[i] == NEEDLE else RADIUS[kind[i]]) * size[i]


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
	lift[i] = lift[n]
	lift_y[i] = lift_y[n]
	size[i] = size[n]


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
		if lift[i] > 0.0:
			lift[i] = maxf(0.0, lift[i] - dt)
		var p := pos[i] + vel[i] * dt
		pos[i] = p
		if p.x < bounds.position.x or p.x > bounds.end.x or p.z < bounds.position.y or p.z > bounds.end.y:
			_remove(i)
			continue
		i += 1


## True if a bullet touches the circle (p, r); that bullet is removed.
## Launched bullets still climbing pass under it.
func hit_test(p: Vector3, r: float) -> bool:
	for i in n:
		if lift[i] > 0.0:
			continue
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
		var sc := size[i]
		# drawn just above the ships, on the view ray through its plane point so
		# what you see lines up with what hits
		var y := 0.32
		var c: Color = COLOR[k]
		if lift[i] > 0.0:
			# climbing from the gun: lower on the ray (so smaller), shrunk and
			# dim, easing up to full size at the flight level
			var f := 1.0 - lift[i] / LIFT
			f = f * f * (3.0 - 2.0 * f)
			y = lerpf(lift_y[i], 0.32, f)
			sc *= lerpf(0.25, 1.0, f)
			c = Color(c.r, c.g, c.b).darkened(0.55 * (1.0 - f))
		if sc != 1.0:
			b = b.scaled(Vector3(sc, 1.0, sc))
		mm.set_instance_transform(i, Transform3D(b, game.from_plane(pos[i], y)))
		mm.set_instance_color(i, c)
		mm.set_instance_custom_data(i, Color(1.0 if k == SHELL else 0.0, aspect, 0.0, 0.0))
