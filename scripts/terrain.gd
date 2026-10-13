class_name Terrain
extends Node3D
## Everything below the play plane: floating islands with tiles and turrets
## (built from a fixed set of layouts made at start-up), plus the deep-space
## backdrop: a dim nebula, a distant gas giant and three star layers.
## Perspective gives the parallax for free.

const LAYOUTS := [
	# w, h (cells of Island.CELL), style (0 rock, 1 station), pattern, turrets
	[8, 5, 0, 0, 1],
	[11, 6, 0, 1, 2],
	[9, 5, 1, 2, 2],
	[6, 4, 0, 0, 0],
	[13, 7, 1, 0, 3],
	[10, 8, 0, 3, 2],
	[7, 4, 1, 1, 1],
	[12, 5, 0, 2, 2],
	[5, 5, 0, 0, 1],
	[10, 6, 1, 3, 2],
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


func prepare() -> void:
	rng.seed = 7
	for i in LAYOUTS.size():
		var l: Array = LAYOUTS[i]
		layouts.append(IslandGen.make(100 + i * 17, l[0], l[1], l[2], l[3], l[4]))
	_build_backdrop()


func reset(spawn: bool) -> void:
	for isl in islands:
		isl.queue_free()
	islands.clear()
	spawning = spawn
	turrets = spawn
	next_in = 4.0
	rng.seed = 7


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
	sp.radius = 30.0
	sp.height = 60.0
	sp.radial_segments = 96
	sp.rings = 48
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/planet.gdshader")
	sp.material = mat
	planet.mesh = sp
	planet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet.position = Vector3(-62, -150, game.screen_to_y(Vector2(480, 260), -150).z)
	planet.rotation = Vector3(0.35, 0.0, 0.2)
	add_child(planet)
	# stars
	var amat := ShaderMaterial.new()
	amat.shader = load("res://shaders/additive.gdshader")
	amat.render_priority = -5
	for layer in [[-18.0, 70, 0.14], [-45.0, 180, 0.22], [-110.0, 420, 0.38]]:
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
			var s := size * (randf_range(0.6, 1.2) if randf() < 0.92 else 2.2)
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(s, s, s)), p))
			var tint := Color(0.75, 0.82, 1.0) if randf() < 0.7 else Color(1.0, 0.8, 0.7)
			mm.set_instance_color(i, tint * randf_range(0.4, 1.0))
			mm.set_instance_custom_data(i, Color(0, 0, randf(), 0))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = AABB(Vector3(rect.position.x - 5, y - 5, rect.position.y - 5), Vector3(rect.size.x + 10, 10, rect.size.y + 10))
		add_child(mi)
		star_layers.append({"mm": mm, "pos": pos, "rect": rect, "size": size})


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
	# islands
	var i := 0
	while i < islands.size():
		var isl := islands[i]
		isl.position.z += speed * dt
		if isl.position.z - isl.h * Island.CELL * 0.5 > game.ground_bottom + 1.0:
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
	if game.gallery == 3:
		li = (last_layout + 1) % layouts.size()
	last_layout = li
	var lay := layouts[li]
	var isl := Island.new()
	add_child(isl)
	isl.setup(game, lay)
	var hw := game.ground_hw
	var w: int = lay["w"]
	var h: int = lay["h"]
	var x := rng.randf_range(-hw + w * Island.CELL * 0.3, hw - w * Island.CELL * 0.3)
	isl.position = Vector3(x, Game.GROUND_Y, game.ground_top - h * Island.CELL * 0.5 - 1.0)
	islands.append(isl)
	if turrets:
		for c: Vector2i in lay["turrets"]:
			game.spawn_enemy("turret", {"island": isl, "cell": c})
	next_in = h * Island.CELL + rng.randf_range(2.0, 9.0)


# ------------------------------------------------------------ hits

## A main shot at plane point p: damages the tile under it. True if blocked.
func hit(p: Vector3, dmg: float) -> bool:
	if islands.is_empty():
		return false
	var g := game.from_plane(p, Game.GROUND_Y + 0.4)
	for isl in islands:
		var idx := isl.tile_at(g)
		if idx >= 0:
			isl.damage(idx, dmg)
			return true
	return false


## Spear: damages tiles inside the aura circle and the lance rectangle.
func spear(pp: Vector3, r: float, hw: float, length: float, dmg: float) -> void:
	for isl in islands:
		if absf(isl.position.z - pp.z) > isl.h * Island.CELL * 0.5 + length + 4.0:
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
