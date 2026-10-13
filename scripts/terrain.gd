class_name Terrain
extends Node3D
## Everything below the play plane: floating islands with tiles and turrets
## (built from a fixed set of layouts made at start-up), plus the deep-space
## backdrop: a dim nebula, a planet, three star layers and big blurred
## asteroids. Perspective gives the parallax for free.

const LAYOUTS := [
	# w, h, style (0 rock, 1 station), pattern, turrets
	[16, 10, 0, 0, 1],
	[22, 12, 0, 1, 2],
	[18, 10, 1, 2, 2],
	[12, 8, 0, 0, 0],
	[26, 14, 1, 0, 3],
	[20, 16, 0, 3, 2],
	[14, 8, 1, 1, 1],
	[24, 10, 0, 2, 2],
	[10, 10, 0, 0, 1],
	[20, 12, 1, 3, 2],
]

var game: Game
var layouts: Array[Dictionary] = []
var islands: Array[Island] = []
var spawning := false
var turrets := true
var next_in := 0.0
var rng := RandomNumberGenerator.new()
var scroll_total := 0.0
var last_layout := -1

var nebula_mat: ShaderMaterial
var planet: MeshInstance3D
var star_layers: Array = []  # {mm: MultiMesh, pos: PackedVector3Array, rect: Rect2}
var decor: Array[MeshInstance3D] = []
var decor_rect := Rect2()


func prepare() -> void:
	rng.seed = 7
	for i in LAYOUTS.size():
		var l: Array = LAYOUTS[i]
		layouts.append(_make_layout(100 + i * 17, l[0], l[1], l[2], l[3], l[4]))
	_build_backdrop()


func reset(spawn: bool) -> void:
	for isl in islands:
		isl.queue_free()
	islands.clear()
	spawning = spawn
	turrets = spawn
	next_in = 4.0
	rng.seed = 7


# ------------------------------------------------------------ layouts

func _make_layout(seed: int, w: int, h: int, style: int, pattern: int, turret_count: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var maxd := 6
	var mask := PackedFloat32Array()  # normalized "edge distance" e (<1 inside), or 9 outside
	mask.resize(w * h)
	var phase := r.randf() * TAU
	for j in h:
		for i in w:
			var dx := (i + 0.5 - w * 0.5) / (w * 0.5)
			var dz := (j + 0.5 - h * 0.5) / (h * 0.5)
			var e := 9.0
			if style == 0:
				var a := atan2(dz, dx)
				var wob := 0.12 * sin(a * 3.0 + phase) + 0.08 * sin(a * 5.0 + phase * 2.0) + r.randf_range(-0.04, 0.04)
				var d := sqrt(dx * dx + dz * dz)
				if d < 0.95 + wob:
					e = d / (0.95 + wob)
			else:
				var cut := absf(dx) + absf(dz)
				if cut < 1.55 and absf(dx) < 0.98 and absf(dz) < 0.98:
					e = maxf(maxf(absf(dx), absf(dz)), cut / 1.55)
					# notches along the long sides
					if absf(dz) > 0.75 and int(i / 3) % 3 == 1:
						e = 9.0
			mask[j * w + i] = e
	var v := Vox.new(w, maxd, h)
	var top_c := Color(0.25, 0.24, 0.29) if style == 0 else Color(0.27, 0.3, 0.36)
	var side_c := Color(0.19, 0.18, 0.23) if style == 0 else Color(0.2, 0.22, 0.27)
	var deep_c := Color(0.12, 0.11, 0.15) if style == 0 else Color(0.13, 0.14, 0.18)
	for j in h:
		for i in w:
			var e := mask[j * w + i]
			if e >= 1.0:
				continue
			var d := 1 + int((1.0 - e) * 4.0) + r.randi_range(0, 1)
			if style == 1:
				d = 2 if e > 0.8 else 3 + (1 if (i % 4 == 0 or j % 4 == 0) else 0)
			d = clampi(d, 1, maxd)
			for y in range(maxd - d, maxd):
				var c := deep_c
				if y == maxd - 1:
					c = top_c
				elif y >= maxd - 2:
					c = side_c
				var glow := false
				if style == 0 and y < maxd - 1 and r.randf() < 0.02:
					c = Color(0.5, 0.3, 0.8)
					glow = true
				if style == 1 and y == maxd - 2 and e > 0.85 and (i + j) % 3 == 0:
					c = Color(0.3, 0.75, 0.9)
					glow = true
				v.put(i - w / 2, y, j - h / 2, c, glow)
	var mesh := v.mesh(1.0, Vector3(0, maxd, 0))
	# tiles
	var types := PackedInt32Array()
	types.resize(w * h)
	var hidden := PackedByteArray()
	hidden.resize(w * h)
	for j in h:
		for i in w:
			var idx := j * w + i
			var e := mask[idx]
			types[idx] = -1
			if e >= 0.97:
				continue
			var t := 0
			match pattern:
				0:
					t = 2 if e < 0.35 else (1 if e < 0.65 else 0)
				1:
					t = 1 if j % 3 == 0 else 0
					if absi(i - w / 2) <= 1 and e < 0.7:
						t = 2
				2:
					t = 0 if (i / 2 + j / 2) % 2 == 0 else 1
					if r.randf() < 0.1:
						t = 2
				_:
					t = 1 if r.randf() < 0.25 else 0
					if r.randf() < 0.05:
						t = 2
			if r.randf() < (0.06 if pattern != 3 else 0.14):
				continue
			types[idx] = t
			var star_p := 0.08 if t == 2 else 0.025
			hidden[idx] = 1 if r.randf() < star_p else 0
	# turret cells: spread along x through the inner area
	var tcells: Array[Vector2i] = []
	for k in turret_count:
		for attempt in 30:
			var i := int(w * (k + 0.5) / turret_count) + r.randi_range(-2, 2)
			var j := r.randi_range(2, h - 3)
			i = clampi(i, 1, w - 2)
			if mask[j * w + i] < 0.75:
				var ok := true
				for c in tcells:
					if absi(c.x - i) + absi(c.y - j) < 4:
						ok = false
				if ok:
					tcells.append(Vector2i(i, j))
					types[j * w + i] = -1
					break
	return {"w": w, "h": h, "style": style, "types": types, "hidden": hidden, "mesh": mesh, "turrets": tcells}


# ------------------------------------------------------------ backdrop

func _build_backdrop() -> void:
	# nebula
	var ny := -170.0
	var neb := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(520, 520)
	nebula_mat = ShaderMaterial.new()
	nebula_mat.shader = load("res://shaders/space.gdshader")
	nebula_mat.render_priority = -10
	pm.material = nebula_mat
	neb.mesh = pm
	neb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	neb.position = Vector3(0, ny, game.screen_to_y(Vector2(480, 360), ny).z)
	add_child(neb)
	# planet
	planet = MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 26.0
	sp.height = 52.0
	sp.radial_segments = 48
	sp.rings = 24
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.11, 0.22)
	mat.roughness = 1.0
	mat.rim_enabled = true
	mat.rim = 0.35
	mat.rim_tint = 0.2
	mat.emission_enabled = true
	mat.emission = Color(0.03, 0.02, 0.06)
	mat.disable_fog = true
	sp.material = mat
	planet.mesh = sp
	planet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet.position = Vector3(-45, -125, game.screen_to_y(Vector2(480, 200), -125).z)
	add_child(planet)
	# stars
	var amat := ShaderMaterial.new()
	amat.shader = load("res://shaders/additive.gdshader")
	amat.render_priority = -5
	for layer in [[-14.0, 90, 0.22], [-40.0, 160, 0.34], [-95.0, 260, 0.6]]:
		var y: float = layer[0]
		var count: int = layer[1]
		var size: float = layer[2]
		var a := game.screen_to_y(Vector2(-40, -40), y)
		var b := game.screen_to_y(Vector2(1000, 760), y)
		var rect := Rect2(a.x, a.z, b.x - a.x, b.z - a.z)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		var q := QuadMesh.new()
		q.material = amat
		mm.mesh = q
		mm.instance_count = count
		var pos := PackedVector3Array()
		for i in count:
			var p := Vector3(rect.position.x + randf() * rect.size.x, y, rect.position.y + randf() * rect.size.y)
			pos.push_back(p)
			var s := size * randf_range(0.6, 1.4)
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(s, s, s)), p))
			var tint := Color(0.75, 0.82, 1.0) if randf() < 0.7 else Color(1.0, 0.8, 0.7)
			mm.set_instance_color(i, tint * randf_range(0.35, 0.8))
			mm.set_instance_custom_data(i, Color(0, 0, randf(), 0))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = AABB(Vector3(rect.position.x - 5, y - 5, rect.position.y - 5), Vector3(rect.size.x + 10, 10, rect.size.y + 10))
		add_child(mi)
		star_layers.append({"mm": mm, "pos": pos, "rect": rect, "size": size})
	# big blurred asteroids
	var dy := -22.0
	var a2 := game.screen_to_y(Vector2(-200, -200), dy)
	var b2 := game.screen_to_y(Vector2(1160, 920), dy)
	decor_rect = Rect2(a2.x, a2.z, b2.x - a2.x, b2.z - a2.z)
	for i in 5:
		var m := MeshInstance3D.new()
		m.mesh = Vox.get_mesh("rock_a" if i % 2 == 0 else "rock_b")
		m.set_instance_shader_parameter("tint", Color(0.5, 0.5, 0.62, 1))
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(decor_rect.position.x + randf() * decor_rect.size.x, dy - randf() * 14.0, decor_rect.position.y + decor_rect.size.y * i / 5.0)
		m.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
		add_child(m)
		decor.append(m)


# ------------------------------------------------------------ tick

func tick(dt: float, speed: float) -> void:
	scroll_total += speed * dt
	nebula_mat.set_shader_parameter("scroll", scroll_total * 0.0035)
	planet.position.z += speed * dt * 0.02
	planet.rotation.y += dt * 0.01
	for L: Dictionary in star_layers:
		var mm: MultiMesh = L["mm"]
		var pos: PackedVector3Array = L["pos"]
		var rect: Rect2 = L["rect"]
		var size: float = L["size"]
		for i in pos.size():
			var p := pos[i]
			p.z += speed * dt
			if p.z > rect.end.y:
				p.z -= rect.size.y
				p.x = rect.position.x + randf() * rect.size.x
			pos[i] = p
			var s := size * (0.8 + 0.4 * fmod(i * 0.618, 1.0))
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(s, s, s)), p))
		L["pos"] = pos
	for m in decor:
		m.position.z += speed * dt * 0.8
		m.rotation.y += dt * 0.05
		if m.position.z > decor_rect.end.y:
			m.position.z = decor_rect.position.y
			m.position.x = decor_rect.position.x + randf() * decor_rect.size.x
	# islands
	var i := 0
	while i < islands.size():
		var isl := islands[i]
		isl.position.z += speed * dt
		if isl.position.z - isl.h * 0.5 > game.ground_bottom + 1.0:
			for c in isl.get_children():
				if c is Enemy:
					game.remove_enemy(c as Enemy)
			isl.queue_free()
			islands.remove_at(i)
			continue
		i += 1
	if spawning:
		next_in -= speed * dt
		if next_in <= 0.0:
			_spawn_island()


func _spawn_island() -> void:
	var li := rng.randi_range(0, layouts.size() - 1)
	if li == last_layout:
		li = (li + 3) % layouts.size()
	last_layout = li
	var lay := layouts[li]
	var isl := Island.new()
	add_child(isl)
	isl.setup(game, lay)
	var hw := game.ground_hw
	var w: int = lay["w"]
	var h: int = lay["h"]
	var x := rng.randf_range(-hw + w * 0.3, hw - w * 0.3)
	isl.position = Vector3(x, Game.GROUND_Y, game.ground_top - h * 0.5 - 1.0)
	islands.append(isl)
	if turrets:
		for c: Vector2i in lay["turrets"]:
			game.spawn_enemy("turret", {"island": isl, "cell": c})
	next_in = h + rng.randf_range(2.0, 9.0)


# ------------------------------------------------------------ hits

## A main shot at plane point p: damages the tile under it. True if blocked.
func hit(p: Vector3, dmg: float) -> bool:
	if islands.is_empty():
		return false
	var g := game.from_plane(p, Game.GROUND_Y + 0.25)
	for isl in islands:
		var idx := isl.tile_at(g)
		if idx >= 0:
			isl.damage(idx, dmg)
			return true
	return false


## Spear: damages tiles inside the aura circle and the lance rectangle.
func spear(pp: Vector3, r: float, hw: float, length: float, dmg: float) -> void:
	for isl in islands:
		if absf(isl.position.z - pp.z) > isl.h * 0.5 + length + 4.0:
			continue
		for idx in isl.w * isl.h:
			if isl.types[idx] < 0:
				continue
			var q := isl.tile_plane_pos(idx)
			var d := q - pp
			if d.x * d.x + d.z * d.z < r * r or (absf(d.x) < hw and d.z < 0.0 and d.z > -length):
				isl.damage(idx, dmg)


func tiles_alive() -> int:
	var c := 0
	for isl in islands:
		c += isl.alive_tiles
	return c
