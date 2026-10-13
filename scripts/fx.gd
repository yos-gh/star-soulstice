class_name Fx
extends Node3D
## Explosions: additive camera-facing sprites (one MultiMesh, blocky
## fireballs), tumbling voxel debris in the unit's colours (one MultiMesh),
## pooled flash lights and floating labels.

const MAX_SPRITES := 1600
const MAX_DEBRIS := 500

var sprites: MultiMeshInstance3D
var debris: MultiMeshInstance3D

var s_pos := PackedVector3Array()
var s_vel := PackedVector3Array()
var s_size := PackedVector2Array()  # start, end
var s_life := PackedFloat32Array()
var s_age := PackedFloat32Array()  # negative = delayed start
var s_col := PackedColorArray()
var s_style := PackedFloat32Array()
var s_seed := PackedFloat32Array()
var sn := 0

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
	s_pos.resize(MAX_SPRITES)
	s_vel.resize(MAX_SPRITES)
	s_size.resize(MAX_SPRITES)
	s_life.resize(MAX_SPRITES)
	s_age.resize(MAX_SPRITES)
	s_col.resize(MAX_SPRITES)
	s_style.resize(MAX_SPRITES)
	s_seed.resize(MAX_SPRITES)
	d_pos.resize(MAX_DEBRIS)
	d_vel.resize(MAX_DEBRIS)
	d_rot.resize(MAX_DEBRIS)
	d_spin.resize(MAX_DEBRIS)
	d_life.resize(MAX_DEBRIS)
	d_scale.resize(MAX_DEBRIS)
	d_col.resize(MAX_DEBRIS)
	sprites = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/additive.gdshader")
	mat.render_priority = 1
	q.material = mat
	mm.mesh = q
	mm.instance_count = MAX_SPRITES
	mm.visible_instance_count = 0
	sprites.multimesh = mm
	sprites.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprites.custom_aabb = AABB(Vector3(-80, -40, -120), Vector3(160, 80, 180))
	add_child(sprites)

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
		l.omni_range = 14.0
		l.light_energy = 0.0
		l.shadow_enabled = false
		l.visible = false
		add_child(l)
		lights.append(l)
		light_t.append(0.0)


func sprite(p: Vector3, v: Vector3, s0: float, s1: float, life: float, c: Color, style := 0.0, delay := 0.0) -> void:
	if sn >= MAX_SPRITES:
		return
	s_pos[sn] = p
	s_vel[sn] = v
	s_size[sn] = Vector2(s0, s1)
	s_life[sn] = life
	s_age[sn] = -delay
	s_col[sn] = c
	s_style[sn] = style
	s_seed[sn] = rng.randf()
	sn += 1


func spark(p: Vector3, c: Color, count := 3, size := 0.45) -> void:
	sprite(p, Vector3.ZERO, size * 1.6, size * 0.4, 0.12, c, 0.0)
	for i in count:
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.1, 0.25), rng.randf_range(-1, 1)).normalized() * rng.randf_range(4, 10)
		sprite(p, v, size * 0.5, 0.05, rng.randf_range(0.12, 0.25), c, 0.0)


func smoke(p: Vector3, drift: Vector3, size := 1.0) -> void:
	sprite(p, drift + Vector3(rng.randf_range(-0.5, 0.5), 1.5, rng.randf_range(-0.5, 0.5)), size * 0.6, size * 1.6, 0.9, Color(0.35, 0.3, 0.28), 1.0)


## Explosion of the given scale (1 = small heli, 3 = gunship, 6+ = boss part).
## `body` colours the voxel debris.
func explode(p: Vector3, scale := 1.0, drift := Vector3.ZERO, body := Color(0.4, 0.4, 0.4), c := Color(1.0, 0.55, 0.2)) -> void:
	var balls := int(clampf(3.0 + scale * 3.0, 3.0, 40.0))
	sprite(p, drift, scale * 1.3, scale * 2.6, 0.16, Color(1.0, 0.7, 0.4), 0.0)
	for i in balls:
		var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.8), rng.randf_range(-1, 1)) * scale * 0.7
		var v := off * rng.randf_range(1.0, 3.0) + drift
		var delay := rng.randf_range(0.0, 0.08 * scale) if i > 2 else 0.0
		sprite(p + off * 0.3, v, scale * rng.randf_range(0.8, 1.3), scale * rng.randf_range(2.0, 3.0), rng.randf_range(0.5, 0.85) + scale * 0.05, c, 1.0, delay)
	var sparks := int(clampf(scale * 6.0, 4.0, 40.0))
	for i in sparks:
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.1, 0.25), rng.randf_range(-1, 1)).normalized() * rng.randf_range(6, 16) * sqrt(scale)
		sprite(p, v + drift, 0.35, 0.05, rng.randf_range(0.3, 0.6), Color(1.0, 0.75, 0.4), 0.0)
	if scale >= 2.0:
		sprite(p, drift, scale * 0.5, scale * 5.5, 0.45, Color(1.0, 0.7, 0.4), 2.0)
	var chunks := int(clampf(scale * 6.0, 5.0, 60.0))
	for i in chunks:
		var dv := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.1, 0.6), rng.randf_range(-1, 1)) * rng.randf_range(4, 10) * sqrt(scale)
		var dc := body if rng.randf() < 0.75 else body.darkened(0.5)
		_debris(p, dv + drift, clampf(scale * 0.12, 0.14, 0.5), dc)
	flash(p, scale)


func shockwave(p: Vector3, radius: float, c: Color, square := false) -> void:
	sprite(p, Vector3.ZERO, radius * 0.2, radius * 2.0, 0.6, c, 3.0 if square else 2.0)


func flash(p: Vector3, scale: float) -> void:
	var best := 0
	for i in lights.size():
		if light_t[i] < light_t[best]:
			best = i
	var l := lights[best]
	l.position = p + Vector3(0, 2, 0)
	l.light_color = Color(1.0, 0.6, 0.3)
	l.omni_range = 8.0 + scale * 4.0
	l.visible = true
	light_t[best] = 0.35 + scale * 0.06
	l.light_energy = 2.0 + scale


func _debris(p: Vector3, v: Vector3, sc: float, c: Color) -> void:
	if dn >= MAX_DEBRIS:
		return
	d_pos[dn] = p
	d_vel[dn] = v
	d_rot[dn] = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
	d_spin[dn] = Vector3(rng.randf_range(-10, 10), rng.randf_range(-10, 10), rng.randf_range(-10, 10))
	d_life[dn] = rng.randf_range(0.9, 1.8)
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
	l.pixel_size = 0.0013 if big else 0.0009
	l.font_size = 40
	l.outline_size = 10
	l.modulate = c
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.position = p + Vector3(0, 1.0, 0)
	l.render_priority = 6
	l.outline_render_priority = 5
	add_child(l)
	labels.append([l, 0.0])


func clear() -> void:
	sn = 0
	dn = 0
	for e: Array in labels:
		(e[0] as Label3D).queue_free()
	labels.clear()


func tick(dt: float, scroll_speed: float) -> void:
	var i := 0
	while i < sn:
		var a := s_age[i] + dt
		s_age[i] = a
		if a < 0.0:
			i += 1
			continue
		if a >= s_life[i]:
			sn -= 1
			s_pos[i] = s_pos[sn]
			s_vel[i] = s_vel[sn]
			s_size[i] = s_size[sn]
			s_life[i] = s_life[sn]
			s_age[i] = s_age[sn]
			s_col[i] = s_col[sn]
			s_style[i] = s_style[sn]
			s_seed[i] = s_seed[sn]
			continue
		s_vel[i] *= 1.0 - 2.5 * dt
		s_pos[i] += s_vel[i] * dt
		i += 1
	i = 0
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
		if rng.randf() < 0.12:
			sprite(d_pos[i], Vector3(0, 0, scroll_speed * 0.3), 0.3, 0.8, 0.35, Color(0.6, 0.35, 0.2), 1.0)
		i += 1
	for k in lights.size():
		if light_t[k] > 0.0:
			light_t[k] -= dt
			lights[k].light_energy = maxf(0.0, lights[k].light_energy - dt * 12.0)
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
	var mm := sprites.multimesh
	var vis := 0
	for i in sn:
		var a := s_age[i]
		if a < 0.0:
			continue
		var f := a / s_life[i]
		var sz := lerpf(s_size[i].x, s_size[i].y, 1.0 - (1.0 - f) * (1.0 - f))
		mm.set_instance_transform(vis, Transform3D(Basis.from_scale(Vector3(sz, sz, sz)), s_pos[i]))
		mm.set_instance_color(vis, s_col[i])
		mm.set_instance_custom_data(vis, Color(f, s_style[i], s_seed[i], 0.0))
		vis += 1
	mm.visible_instance_count = vis
	var dm := debris.multimesh
	dm.visible_instance_count = dn
	for i in dn:
		var b := Basis.from_euler(d_rot[i]).scaled(Vector3.ONE * d_scale[i])
		dm.set_instance_transform(i, Transform3D(b, d_pos[i]))
		dm.set_instance_color(i, d_col[i])
