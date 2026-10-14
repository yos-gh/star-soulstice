class_name Fx
extends Node3D
## Effects: camera-facing sprites in three layers, tumbling voxel debris, pooled
## flash lights and floating labels.
##   glows  additive sprites (sparks, small flashes, shockwaves) - additive.gdshader
##   puffs  explosion sprites (puff.gdshader): turbulent fire billows with
##          dot-work colour steps, a four-point flash and thin rings
##   smokes lit translucent smoke, its own layer under the fire
## Explosions after DoDonPachi DaiFukkatsu (fire dot work), Under Defeat and
## Ikaruga (lit translucent smoke, crisp flash and shards): a brief glint,
## a few big billows that expand fast, cool and tear apart over rolling
## smoke, shards and debris; big enemies go in a chain of small blasts instead of one big
## glow. They sit just below the bullets so the bullets stay readable.

const MAX_GLOWS := 1600
const MAX_PUFFS := 1400
const MAX_DEBRIS := 500
enum { FIRE, SMOKE, FLASH, RING }  # puff styles
enum { WARM, COOL }  # puff palettes
const BLAST_Y := 0.05  # explosion height: under the bullets (drawn at 0.32)


## One sprite layer: packed arrays + a MultiMesh of camera-facing quads.
## custom data = (age 0..1, style, seed, palette)
class Layer:
	var mm: MultiMesh
	var pos := PackedVector3Array()
	var vel := PackedVector3Array()
	var size := PackedVector2Array()  # start, end
	var life := PackedFloat32Array()
	var age := PackedFloat32Array()  # negative = delayed start
	var col := PackedColorArray()
	var style := PackedFloat32Array()
	var seed := PackedFloat32Array()
	var pal := PackedFloat32Array()
	var damp := 2.5
	var grow_pow := 2.0
	var n := 0
	var cap := 0

	func _init(max_count: int) -> void:
		cap = max_count
		pos.resize(cap)
		vel.resize(cap)
		size.resize(cap)
		life.resize(cap)
		age.resize(cap)
		col.resize(cap)
		style.resize(cap)
		seed.resize(cap)
		pal.resize(cap)

	func add(p: Vector3, v: Vector3, s0: float, s1: float, l: float, c: Color, st: float, delay: float, sd: float, pl: float) -> void:
		if n >= cap:
			return
		pos[n] = p
		vel[n] = v
		size[n] = Vector2(s0, s1)
		life[n] = l
		age[n] = -delay
		col[n] = c
		style[n] = st
		seed[n] = sd
		pal[n] = pl
		n += 1

	func tick(dt: float) -> void:
		var i := 0
		while i < n:
			var a := age[i] + dt
			age[i] = a
			if a < 0.0:
				i += 1
				continue
			if a >= life[i]:
				n -= 1
				pos[i] = pos[n]
				vel[i] = vel[n]
				size[i] = size[n]
				life[i] = life[n]
				age[i] = age[n]
				col[i] = col[n]
				style[i] = style[n]
				seed[i] = seed[n]
				pal[i] = pal[n]
				continue
			vel[i] *= 1.0 - damp * dt
			pos[i] += vel[i] * dt
			i += 1

	func draw() -> void:
		var vis := 0
		for i in n:
			var a := age[i]
			if a < 0.0:
				continue
			var f := a / life[i]
			# expand fast, then slow down
			var sz := lerpf(size[i].x, size[i].y, 1.0 - pow(1.0 - f, grow_pow))
			mm.set_instance_transform(vis, Transform3D(Basis.from_scale(Vector3(sz, sz, sz)), pos[i]))
			mm.set_instance_color(vis, col[i])
			mm.set_instance_custom_data(vis, Color(f, style[i], seed[i], pal[i]))
			vis += 1
		mm.visible_instance_count = vis


var glows: Layer
var puffs: Layer
var smokes: Layer  # smoke has its own layer, drawn under the fire
var smoke_mi: MultiMeshInstance3D
var sprites: MultiMeshInstance3D  # the glow layer (kept for --hide)
var puff_mi: MultiMeshInstance3D
var debris: MultiMeshInstance3D

var d_pos := PackedVector3Array()
var d_vel := PackedVector3Array()
var d_rot := PackedVector3Array()
var d_spin := PackedVector3Array()
var d_life := PackedFloat32Array()
var d_scale := PackedFloat32Array()
var d_col := PackedColorArray()
var dn := 0

var lights: Array[OmniLight3D] = []
var light_t: Array[float] = []
var labels: Array = []  # [Label3D, age]
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 99
	d_pos.resize(MAX_DEBRIS)
	d_vel.resize(MAX_DEBRIS)
	d_rot.resize(MAX_DEBRIS)
	d_spin.resize(MAX_DEBRIS)
	d_life.resize(MAX_DEBRIS)
	d_scale.resize(MAX_DEBRIS)
	d_col.resize(MAX_DEBRIS)
	glows = Layer.new(MAX_GLOWS)
	sprites = _layer_node(glows, "res://shaders/additive.gdshader", 1)
	smokes = Layer.new(MAX_PUFFS)
	smokes.damp = 1.6
	smokes.grow_pow = 2.0
	smoke_mi = _layer_node(smokes, "res://shaders/puff.gdshader", -1)
	puffs = Layer.new(MAX_PUFFS)
	puffs.damp = 3.2
	puffs.grow_pow = 3.0
	puff_mi = _layer_node(puffs, "res://shaders/puff.gdshader", 0)

	debris = MultiMeshInstance3D.new()
	var dm := MultiMesh.new()
	dm.transform_format = MultiMesh.TRANSFORM_3D
	dm.use_colors = true
	dm.mesh = Vox.cube(false)
	dm.instance_count = MAX_DEBRIS
	dm.visible_instance_count = 0
	debris.multimesh = dm
	debris.custom_aabb = sprites.custom_aabb
	add_child(debris)

	for i in 6:
		var l := OmniLight3D.new()
		l.omni_range = 10.0
		l.light_energy = 0.0
		l.shadow_enabled = false
		l.visible = false
		add_child(l)
		lights.append(l)
		light_t.append(0.0)


func _layer_node(layer: Layer, shader: String, priority: int) -> MultiMeshInstance3D:
	var mi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new()
	var mat := ShaderMaterial.new()
	mat.shader = load(shader)
	mat.render_priority = priority
	q.material = mat
	mm.mesh = q
	mm.instance_count = layer.cap
	mm.visible_instance_count = 0
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(Vector3(-80, -40, -120), Vector3(160, 80, 180))
	add_child(mi)
	layer.mm = mm
	return mi


## Additive glow sprite. style: 0 soft glow, 1 fireball, 2 ring, 3 square ring.
func sprite(p: Vector3, v: Vector3, s0: float, s1: float, life: float, c: Color, style := 0.0, delay := 0.0) -> void:
	glows.add(p, v, s0, s1, life, c, style, delay, rng.randf(), 0.0)


## Pixel explosion sprite (see the styles and palettes above).
func puff(p: Vector3, v: Vector3, s0: float, s1: float, life: float, style: int, delay := 0.0, pal := WARM) -> void:
	(smokes if style == SMOKE else puffs).add(p, v, s0, s1, life, Color(1, 1, 1), style, delay, rng.randf(), pal)


func spark(p: Vector3, c: Color, count := 3, size := 0.45) -> void:
	sprite(p, Vector3.ZERO, size * 1.2, size * 0.3, 0.1, c * 0.8, 0.0)
	for i in count:
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.1, 0.25), rng.randf_range(-1, 1)).normalized() * rng.randf_range(4, 10)
		sprite(p, v, size * 0.4, 0.05, rng.randf_range(0.12, 0.22), c, 0.0)


func smoke(p: Vector3, drift: Vector3, size := 1.0) -> void:
	puff(p, drift, size * 0.6, size * 1.3, 0.7, SMOKE)


## Explosion of the given scale (1 = small fighter, 3 = cruiser, 6+ = boss
## part). `body` colours the voxel debris; a bluish `c` picks the cool
## palette (the player's ship).
func explode(p: Vector3, scale := 1.0, drift := Vector3.ZERO, body := Color(0.4, 0.4, 0.4), c := Color(1.0, 0.55, 0.2)) -> void:
	var pal := COOL if c.b > c.r else WARM
	var at := Vector3(p.x, BLAST_Y, p.z)
	if scale >= 2.4:
		# a chain of small blasts across the body, then the core goes
		var count := int(clampf(scale * 1.6, 3.0, 12.0))
		var spread := minf(scale * 0.5, 4.0)
		for i in count:
			var off := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * spread
			_blast(at + off, rng.randf_range(0.8, 1.2) * minf(scale * 0.4, 1.4), drift, pal, i * 0.07 + rng.randf() * 0.04)
		var last := count * 0.07
		_blast(at, minf(scale * 0.55, 3.0), drift, pal, last)
		puff(at, drift, scale * 0.5, scale * 2.6, 0.45, RING, last, pal)
	else:
		_blast(at, scale, drift, pal, 0.0)
	var chunks := int(clampf(scale * 4.0, 4.0, 40.0))
	for i in chunks:
		var dv := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.1, 0.6), rng.randf_range(-1, 1)) * rng.randf_range(4, 10) * sqrt(scale)
		var dc := body if rng.randf() < 0.75 else body.darkened(0.5)
		_debris(at, dv + drift, clampf(scale * 0.1, 0.12, 0.4), dc)
	flash(at, scale)


## One blast: flash, fire puffs, smoke, sparks (and a ring when larger).
func _blast(p: Vector3, s: float, drift: Vector3, pal: int, delay: float) -> void:
	puff(p, drift, s * 1.6, s * 0.5, 0.08, FLASH, delay, pal)
	# a few big turbulent billows rather than many small balls
	var fires := 2 + int(s * 1.2)
	for i in fires:
		var a := rng.randf() * TAU
		var off := Vector3(cos(a), 0, sin(a)) * s * (0.0 if i == 0 else rng.randf_range(0.25, 0.5))
		puff(p + off, off * 2.2 + drift, s * rng.randf_range(0.6, 0.8), s * rng.randf_range(1.3, 1.7), rng.randf_range(0.5, 0.62), FIRE, delay + i * 0.03, pal)
	# lit smoke rolls out under the fire and lingers, carried by the wreck
	for i in 2 + int(s):
		var a := rng.randf() * TAU
		var off := Vector3(cos(a), 0, sin(a)) * s * rng.randf_range(0.2, 0.5)
		puff(p + off, drift * 0.9 + off * 1.2, s * 0.8, s * rng.randf_range(1.5, 1.9), rng.randf_range(0.8, 1.1), SMOKE, delay + 0.05 + i * 0.04, pal)
	# crisp shards
	var sparks := 4 + int(s * 3.0)
	var sc := Color(1.0, 0.85, 0.5) if pal == WARM else Color(0.6, 0.85, 1.0)
	for i in sparks:
		var v := Vector3(rng.randf_range(-1, 1), 0.05, rng.randf_range(-1, 1)).normalized() * rng.randf_range(8, 16) * sqrt(s)
		sprite(p, v + drift, 0.14, 0.03, rng.randf_range(0.18, 0.3), sc * 0.7, 0.0, delay)
	if s >= 1.3:
		puff(p, drift, s * 0.5, s * 2.3, 0.3, RING, delay + 0.02, pal)


func shockwave(p: Vector3, radius: float, c: Color, square := false) -> void:
	sprite(p, Vector3.ZERO, radius * 0.2, radius * 2.0, 0.6, c, 3.0 if square else 2.0)


func flash(p: Vector3, scale: float) -> void:
	var best := 0
	for i in lights.size():
		if light_t[i] < light_t[best]:
			best = i
	var l := lights[best]
	l.position = p + Vector3(0, 2, 0)
	l.light_color = Color(1.0, 0.65, 0.35)
	l.omni_range = 5.0 + scale * 2.5
	l.visible = true
	light_t[best] = 0.2 + scale * 0.04
	l.light_energy = 0.8 + scale * 0.35


func _debris(p: Vector3, v: Vector3, sc: float, c: Color) -> void:
	if dn >= MAX_DEBRIS:
		return
	d_pos[dn] = p
	d_vel[dn] = v
	d_rot[dn] = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
	d_spin[dn] = Vector3(rng.randf_range(-10, 10), rng.randf_range(-10, 10), rng.randf_range(-10, 10))
	d_life[dn] = rng.randf_range(0.7, 1.4)
	d_scale[dn] = sc * rng.randf_range(0.7, 1.4)
	d_col[dn] = c
	dn += 1


## Floating text.
func popup(p: Vector3, text: String, c := Color(1, 1, 1), big := false) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0008 if big else 0.0006
	l.font_size = 40
	l.outline_size = 8
	l.modulate = c
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.position = p + Vector3(0, 1.0, 0)
	l.render_priority = 6
	l.outline_render_priority = 5
	add_child(l)
	labels.append([l, 0.0])


func clear() -> void:
	glows.n = 0
	puffs.n = 0
	smokes.n = 0
	dn = 0
	for e: Array in labels:
		(e[0] as Label3D).queue_free()
	labels.clear()


func tick(dt: float, scroll_speed: float) -> void:
	glows.tick(dt)
	puffs.tick(dt)
	smokes.tick(dt)
	var i := 0
	while i < dn:
		d_life[i] -= dt
		if d_life[i] <= 0.0:
			dn -= 1
			d_pos[i] = d_pos[dn]
			d_vel[i] = d_vel[dn]
			d_rot[i] = d_rot[dn]
			d_spin[i] = d_spin[dn]
			d_life[i] = d_life[dn]
			d_scale[i] = d_scale[dn]
			d_col[i] = d_col[dn]
			continue
		d_vel[i] *= 1.0 - 1.2 * dt
		d_vel[i].y -= 9.0 * dt
		d_pos[i] += d_vel[i] * dt
		d_rot[i] += d_spin[i] * dt
		if rng.randf() < 0.1:
			# smoke trail behind flying chunks
			puff(d_pos[i], Vector3(0, 0, scroll_speed * 0.3), 0.18, 0.4, 0.35, SMOKE)
		i += 1
	for k in lights.size():
		if light_t[k] > 0.0:
			light_t[k] -= dt
			lights[k].light_energy = maxf(0.0, lights[k].light_energy - dt * 10.0)
			if light_t[k] <= 0.0:
				lights[k].visible = false
	var j := 0
	while j < labels.size():
		var e: Array = labels[j]
		var l: Label3D = e[0]
		e[1] += dt
		l.position.y += dt * 2.0
		l.modulate.a = clampf(2.0 - e[1] * 2.0, 0.0, 1.0)
		l.outline_modulate.a = l.modulate.a * 0.85
		if e[1] > 1.0:
			l.queue_free()
			labels.remove_at(j)
			continue
		j += 1


func draw() -> void:
	glows.draw()
	puffs.draw()
	smokes.draw()
	var dm := debris.multimesh
	dm.visible_instance_count = dn
	for i in dn:
		var b := Basis.from_euler(d_rot[i]).scaled(Vector3.ONE * d_scale[i])
		dm.set_instance_transform(i, Transform3D(b, d_pos[i]))
		dm.set_instance_color(i, d_col[i])
