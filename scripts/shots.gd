class_name Shots
extends Node3D
## Player main shots (packed arrays, one MultiMesh of flat glow bolts whose
## size and colour follow the Concentration multiplier) and homing lasers
## (steered missiles drawn as additive ribbons).

const MAX := 400
const BASE_DMG := 1.0
## Afterimages drawn behind each shot: (distance back, scale, alpha).
const GHOSTS := [Vector3(0.0, 1.0, 1.0), Vector3(1.1, 0.8, 0.45), Vector3(2.0, 0.62, 0.22)]
const HOMING_DMG := 16.0
const HOMING_SPEED := 30.0
## Time scale: the first implementation's path, flown K times faster
## (speeds x K, turn rates x K, schedules compressed by K).
const K := 2.0
const TRAIL := 9
const BLOOM := 0.0  # seconds the lasers float outward before homing (0 = off)

var game: Game
var pos := PackedVector3Array()
var vel := PackedVector3Array()
var dmg := PackedFloat32Array()
var mul := PackedFloat32Array()
var n := 0
var bolts: MultiMeshInstance3D

## {pos, vel, target (Object), life, trail (PackedVector3Array), done, fade}
var homing: Array = []
var ribbons: MeshInstance3D
var ribbon_mesh: ImmediateMesh


func _ready() -> void:
	pos.resize(MAX)
	vel.resize(MAX)
	dmg.resize(MAX)
	mul.resize(MAX)
	bolts = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var q := PlaneMesh.new()
	q.size = Vector2(1, 1)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/bolt.gdshader")
	mat.render_priority = 1
	q.material = mat
	mm.mesh = q
	mm.instance_count = MAX * 3
	mm.visible_instance_count = 0
	bolts.multimesh = mm
	bolts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bolts.custom_aabb = AABB(Vector3(-60, -10, -60), Vector3(120, 20, 120))
	add_child(bolts)
	ribbon_mesh = ImmediateMesh.new()
	ribbons = MeshInstance3D.new()
	ribbons.mesh = ribbon_mesh
	var rm := ShaderMaterial.new()
	rm.shader = load("res://shaders/beam.gdshader")
	rm.render_priority = 2
	ribbons.material_override = rm
	ribbons.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ribbons.custom_aabb = bolts.custom_aabb
	add_child(ribbons)


func fire(p: Vector3, dir: Vector3, m: float) -> void:
	if n >= MAX:
		return
	pos[n] = Vector3(p.x, 0.0, p.z)
	vel[n] = dir * Player.SHOT_SPEED
	dmg[n] = BASE_DMG * m
	mul[n] = m
	n += 1


func remove(i: int) -> void:
	n -= 1
	pos[i] = pos[n]
	vel[i] = vel[n]
	dmg[i] = dmg[n]
	mul[i] = mul[n]


func clear() -> void:
	n = 0
	homing.clear()


## Launches `count` homing lasers from the ship's rear, fanned out, each
## with its own target (nearest first, cycling when there are fewer).
func launch_homing(p: Vector3, count: int) -> void:
	var targets := game.homing_targets(p)
	for i in count:
		var spread := 0.0 if count == 1 else lerpf(-1.0, 1.0, float(i) / (count - 1))
		# fan out behind and to the sides; they float for a moment before
		# turning on their targets
		var ang := PI / 2.0 + spread * deg_to_rad(75.0)
		var v := Vector3(cos(ang), 0, sin(ang)) * 12.0 * K
		var tgt: Object = null
		if not targets.is_empty():
			tgt = targets[i % targets.size()]
		var trail := PackedVector3Array()
		trail.push_back(p)
		homing.append({"pos": p + Vector3(0, 0, 0.6), "vel": v, "target": tgt, "life": 2.6 / K, "trail": trail, "done": false, "fade": 0.25, "t": 0.0})


func tick(dt: float) -> void:
	var i := 0
	while i < n:
		var p := pos[i] + vel[i] * dt
		pos[i] = p
		if not game.on_field(p, 1.0):
			remove(i)
			continue
		i += 1
	var k := 0
	while k < homing.size():
		var h: Dictionary = homing[k]
		var trail: PackedVector3Array = h["trail"]
		if h["done"]:
			h["fade"] -= dt
			if trail.size() > 1:
				trail.remove_at(0)
			h["trail"] = trail
			if h["fade"] <= 0.0:
				homing.remove_at(k)
				continue
			k += 1
			continue
		h["t"] += dt
		h["life"] -= dt
		var tgt = h["target"]
		if not is_instance_valid(tgt) or (tgt as Enemy).dead or not game.enemies.has(tgt):
			tgt = game.nearest_target(h["pos"])
			h["target"] = tgt
		var v: Vector3 = h["vel"]
		var hp: Vector3 = h["pos"]
		var ht: float = h["t"]
		if ht < BLOOM:
			# bloom: drift outward and slow down, no steering yet
			v *= 1.0 - 2.0 * dt
			hp += v * dt
			h["vel"] = v
			h["pos"] = hp
			trail.push_back(hp)
			if trail.size() > TRAIL:
				trail.remove_at(0)
			h["trail"] = trail
			k += 1
			continue
		var ta := ht - BLOOM
		var spd := minf(HOMING_SPEED * K, (12.0 + ta * K * 40.0) * K)
		if is_instance_valid(tgt):
			var to: Vector3 = (tgt as Enemy).hit_pos - hp
			to.y = 0.0
			var turn := clampf(4.0 + ta * K * 10.0, 0.0, 22.0) * K
			var want := to.normalized() * spd
			v = v.lerp(want, clampf(turn * dt, 0.0, 1.0))
			if v.length() > 0.001:
				v = v.normalized() * spd
		else:
			v = v.lerp(Vector3(0, 0, -spd), 3.0 * K * dt)
		hp += v * dt
		h["vel"] = v
		h["pos"] = hp
		trail.push_back(hp)
		if trail.size() > TRAIL:
			trail.remove_at(0)
		h["trail"] = trail
		if h["life"] <= 0.0 or not game.on_field(hp, 3.0):
			h["done"] = true
		k += 1


## Called by Game when a homing laser reaches its target.
func homing_hit(h: Dictionary) -> void:
	h["done"] = true


func draw() -> void:
	var mm := bolts.multimesh
	var k := 0
	for i in n:
		var m := mul[i]
		var f := (m - 1.0) / (Player.CONC_MAX_MUL - 1.0)
		# size follows the multiplier: x1 = 1.0, x4 = 1.5
		var s := 1.0 + 0.5 * f
		var dir := vel[i].normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		var c := Color(0.4, 0.85, 1.0).lerp(Color(1.0, 0.78, 0.3), f)
		# the shot, then two fading afterimages behind it (visual only)
		for g in GHOSTS.size():
			var gh: Vector3 = GHOSTS[g]  # (back offset, scale, alpha)
			var w := 0.22 * s * gh.y
			var l := 1.7 * s * gh.y
			# local -z (UV.y = 0) is the head
			var b := Basis(side * w, Vector3.UP, -dir * l)
			mm.set_instance_transform(k, Transform3D(b, pos[i] - dir * gh.x * s + Vector3(0, 0.4, 0)))
			mm.set_instance_color(k, Color(c.r, c.g, c.b, gh.z))
			k += 1
	mm.visible_instance_count = k
	ribbon_mesh.clear_surfaces()
	var any := false
	for h: Dictionary in homing:
		var tr: PackedVector3Array = h["trail"]
		if tr.size() >= 2:
			any = true
			break
	if not any:
		return
	ribbon_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for h: Dictionary in homing:
		var tr: PackedVector3Array = h["trail"]
		var cnt := tr.size()
		if cnt < 2:
			continue
		var fa: float = clampf(h["fade"] / 0.25, 0.0, 1.0) if h["done"] else 1.0
		for j in cnt - 1:
			var a := tr[j]
			var b := tr[j + 1]
			var d := b - a
			d.y = 0.0
			if d.length_squared() < 0.000001:
				continue
			var side := Vector3(-d.z, 0, d.x).normalized()
			var ta := float(j) / (cnt - 1)
			var tb := float(j + 1) / (cnt - 1)
			var wa := 0.24 * ta
			var wb := 0.24 * tb
			var ca := Color(0.3, 0.8, 1.0, ta * fa)
			var cb := Color(0.6, 0.95, 1.0, tb * fa)
			var y := Vector3(0, 0.5, 0)
			var p0 := a - side * wa + y
			var p1 := a + side * wa + y
			var p2 := b - side * wb + y
			var p3 := b + side * wb + y
			_v(ca, Vector2(ta, 0), p0)
			_v(ca, Vector2(ta, 1), p1)
			_v(cb, Vector2(tb, 0), p2)
			_v(ca, Vector2(ta, 1), p1)
			_v(cb, Vector2(tb, 1), p3)
			_v(cb, Vector2(tb, 0), p2)
		if not h["done"]:
			# sharp diamond head pointing along the flight
			var hp: Vector3 = h["pos"]
			var hv: Vector3 = h["vel"]
			var dir := hv.normalized() if hv.length_squared() > 0.0001 else Vector3(0, 0, -1)
			var sd := Vector3(-dir.z, 0, dir.x) * 0.19
			var y := Vector3(0, 0.55, 0)
			var c := Color(0.9, 1.0, 1.0, 1.0)
			var tip := hp + dir * 0.84 + y
			var tail := hp - dir * 0.54 + y
			_v(c, Vector2(1, 0.5), tip)
			_v(c, Vector2(0.5, 0), hp - sd + y)
			_v(c, Vector2(0.5, 1), hp + sd + y)
			_v(c, Vector2(0, 0.5), tail)
			_v(c, Vector2(0.5, 1), hp + sd + y)
			_v(c, Vector2(0.5, 0), hp - sd + y)
	ribbon_mesh.surface_end()


func _v(c: Color, uv: Vector2, p: Vector3) -> void:
	ribbon_mesh.surface_set_color(c)
	ribbon_mesh.surface_set_uv(uv)
	ribbon_mesh.surface_add_vertex(p)
