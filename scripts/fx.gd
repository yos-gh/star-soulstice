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
## a few big billows that expand fast, cool and tear apart over smoke that
## rolls far out, burning scraps, shards and debris flung wide; big enemies
## go in a chain of small blasts instead of one big glow, and a boss's last
## blast fills the screen (finale).
## Everything an explosion draws is depth-tested as if it lay on a plane
## just under the units (see puff.gdshader, debris.gdshader and the `under`
## glow sprites), so however big it grows it never hides an enemy or a
## bullet; it also draws before the pick-ups and shots.

const MAX_GLOWS := 2400
const MAX_PUFFS := 2400
const MAX_DEBRIS := 900
enum { FIRE, SMOKE, FLASH, RING }  # puff styles
enum { WARM, COOL }  # puff palettes
const BLAST_Y := 0.05  # explosion height (drawn under the units whatever it is)


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
	# drawn smoke, fire, glows, then the pick-ups (0) and shots (1, 2) on top
	glows = Layer.new(MAX_GLOWS)
	sprites = _layer_node(glows, "res://shaders/additive.gdshader", -1)
	smokes = Layer.new(MAX_PUFFS)
	smokes.damp = 1.6
	smokes.grow_pow = 2.0
	smoke_mi = _layer_node(smokes, "res://shaders/puff.gdshader", -3)
	# smoke lies deeper than the fire: under a defeated boss's sunk wreck
	# (which lies under the fire, see Vox.sunk), just above the tunnel walls
	((smoke_mi.multimesh.mesh as QuadMesh).material as ShaderMaterial).set_shader_parameter("under_y", -0.995)
	puffs = Layer.new(MAX_PUFFS)
	puffs.damp = 3.2
	puffs.grow_pow = 3.0
	puff_mi = _layer_node(puffs, "res://shaders/puff.gdshader", -2)

	debris = MultiMeshInstance3D.new()
	var dm := MultiMesh.new()
	dm.transform_format = MultiMesh.TRANSFORM_3D
	dm.use_colors = true
	dm.mesh = Vox.cube(false)
	var dmat := ShaderMaterial.new()
	dmat.shader = load("res://shaders/debris.gdshader")
	dmat.render_priority = -1  # over the fire and smoke, under the pick-ups
	debris.material_override = dmat
	debris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
## `under`: part of an explosion, drawn under the units and bullets (hit
## sparks are not: they show on what they hit).
func sprite(p: Vector3, v: Vector3, s0: float, s1: float, life: float, c: Color, style := 0.0, delay := 0.0, under := false) -> void:
	glows.add(p, v, s0, s1, life, c, style, delay, rng.randf(), 1.0 if under else 0.0)


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
		var spread := minf(scale * 0.6, 5.0)
		for i in count:
			var off := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * spread
			# (less smoke each: together they still roll out wide)
			_blast(at + off, rng.randf_range(0.8, 1.2) * minf(scale * 0.4, 1.6), drift, pal, i * 0.07 + rng.randf() * 0.04, 0.45)
		var last := count * 0.07
		_blast(at, minf(scale * 0.6, 3.6), drift, pal, last, 0.7)
		puff(at, drift, scale * 0.5, scale * 3.6, 0.5, RING, last, pal)
	else:
		_blast(at, scale, drift, pal, 0.0)
	# wreckage flung out wide, with a little hop
	var chunks := int(clampf(scale * 6.0, 6.0, 60.0))
	for i in chunks:
		var a := rng.randf() * TAU
		var dv := Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(5, 15) * sqrt(scale) + Vector3(0, rng.randf_range(1, 4), 0)
		var dc := body if rng.randf() < 0.75 else body.darkened(0.5)
		_debris(at, dv + drift, clampf(scale * 0.12, 0.18, 0.5), dc)
	flash(at, scale)


## One blast: flash, fire billows, burning scraps, smoke rolling far out
## (`smoke` scales how much), shards (and a ring when larger).
func _blast(p: Vector3, s: float, drift: Vector3, pal: int, delay: float, smoke := 1.0) -> void:
	puff(p, drift, s * 2.0, s * 0.6, 0.09, FLASH, delay, pal)
	# a few big turbulent billows rather than many small balls
	var fires := 2 + int(s * 1.2)
	for i in fires:
		var a := rng.randf() * TAU
		var off := Vector3(cos(a), 0, sin(a)) * s * (0.0 if i == 0 else rng.randf_range(0.3, 0.6))
		puff(p + off, off * 2.6 + drift, s * rng.randf_range(0.85, 1.1), s * rng.randf_range(2.0, 2.6), rng.randf_range(0.55, 0.7), FIRE, delay + i * 0.03, pal)
	# burning scraps thrown out of the fireball
	for i in 2 + int(s * 1.5):
		var a := rng.randf() * TAU
		var v := Vector3(cos(a), 0, sin(a)) * rng.randf_range(9, 16) * sqrt(s)
		puff(p, v + drift, s * 0.45, s * 0.12, rng.randf_range(0.35, 0.55), FIRE, delay + 0.02, pal)
	# lit smoke rolls out all round under the fire, far, and lingers,
	# carried by the wreck
	var smokes := int((6 + s * 3.0) * smoke)
	for i in smokes:
		var a := TAU * (i + rng.randf() * 0.8) / maxf(smokes, 1)
		var dir := Vector3(cos(a), 0, sin(a))
		puff(p + dir * s * 0.4, drift * 0.9 + dir * rng.randf_range(1.5, 6.0) * sqrt(s), s * 0.9, s * rng.randf_range(1.6, 2.9), rng.randf_range(1.1, 1.7), SMOKE, delay + 0.05 + i * 0.02, pal)
	# crisp shards, flung far
	var sparks := 6 + int(s * 4.0)
	var sc := Color(1.0, 0.85, 0.5) if pal == WARM else Color(0.6, 0.85, 1.0)
	for i in sparks:
		var v := Vector3(rng.randf_range(-1, 1), 0.0, rng.randf_range(-1, 1)).normalized() * rng.randf_range(14, 28) * sqrt(s)
		sprite(p, v + drift, 0.3, 0.05, rng.randf_range(0.3, 0.5), sc, 0.0, delay, true)
	if s >= 1.3:
		puff(p, drift, s * 0.5, s * 3.0, 0.35, RING, delay + 0.02, pal)


## A boss's last blast, over the whole screen (`k`: 1 = stage boss, less for
## a mid-boss): a white flash, shock rings that run off the screen, rings of
## blasts going off outward to the edges, a blanket of smoke rolling out
## behind them, shards and wreckage flung everywhere. Like every explosion
## it stays under the units and bullets.
func finale(p: Vector3, k := 1.0, body := Color(0.4, 0.4, 0.4)) -> void:
	var at := Vector3(p.x, BLAST_Y, p.z)
	puff(at, Vector3.ZERO, 18.0 * k, 5.0 * k, 0.2, FLASH, 0.0, WARM)
	_blast(at, 4.5 * k, Vector3.ZERO, WARM, 0.0, 0.5)
	# shock rings: quick, so their ends never linger as bars at the edges
	for i in 2:
		puff(at, Vector3.ZERO, 3.0, (64.0 - i * 22.0) * k, 0.55 + i * 0.1, RING, i * 0.1, WARM)
	sprite(at, Vector3.ZERO, 4.0, 84.0 * k, 0.75, Color(0.9, 0.6, 0.35) * 0.6, 2.0, 0.0, true)
	# rings of blasts going off outward (wider than tall, like the screen)
	var rings := [[5.0, 6, 2.6], [10.0, 9, 2.1], [16.0, 12, 1.7], [22.0, 15, 1.4]]
	for ri in rings.size():
		var r: Array = rings[ri]
		var n: int = r[1]
		var a0 := rng.randf() * TAU
		for i in n:
			var a := a0 + TAU * (i + rng.randf_range(-0.3, 0.3)) / n
			var dir := Vector3(cos(a), 0, sin(a))
			var d: float = float(r[0]) * k * rng.randf_range(0.8, 1.15)
			_blast(at + Vector3(dir.x * d * 1.3, 0, dir.z * d), float(r[2]) * k * rng.randf_range(0.8, 1.2), dir * 2.0, WARM, 0.08 + ri * 0.13 + rng.randf() * 0.08, 0.35)
	# a blanket of smoke rolling out to the edges as the blast reaches them
	for i in int(22 * k):
		var a := rng.randf() * TAU
		var dir := Vector3(cos(a), 0, sin(a))
		var d := sqrt(rng.randf()) * 18.0 * k
		puff(at + Vector3(dir.x * d * 1.3, 0, dir.z * d), dir * rng.randf_range(2.0, 5.0), 2.5 * k, rng.randf_range(5.0, 7.5) * k, rng.randf_range(1.5, 2.2), SMOKE, 0.12 + d * 0.025, WARM)
	# shards and wreckage flung across the screen
	for i in int(90 * k):
		var a := rng.randf() * TAU
		sprite(at, Vector3(cos(a), 0, sin(a)) * rng.randf_range(25, 60) * k, 0.4, 0.06, rng.randf_range(0.45, 0.8), Color(1.0, 0.85, 0.5) * 0.8, 0.0, rng.randf() * 0.3, true)
	for i in int(70 * k):
		var a := rng.randf() * TAU
		var dv := Vector3(cos(a), 0, sin(a)) * rng.randf_range(8, 26) * k + Vector3(0, rng.randf_range(1, 5), 0)
		_debris(at, dv, rng.randf_range(0.25, 0.6), body if rng.randf() < 0.7 else body.darkened(0.5))
	flash(at, 12.0 * k)


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
	l.light_energy = minf(0.8 + scale * 0.35, 4.0)


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
