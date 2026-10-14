class_name Terrain
extends Node3D
## Everything below the play plane: the sections of the orbital fortress
## the stage flies over (built from a fixed set of layouts at start-up, one
## list per area of the stage), a deep layer of colossal girders and hull
## blocks far below (blurred by depth of field), and the space backdrop:
## nebula, a ringed planet and three star layers. Perspective gives the
## parallax for free.

## kind, w, h (cells of Island.CELL), turrets
const AREAS := {
	"debris": [["fragment", 6, 4, 0], ["asteroid", 6, 5, 1], ["fragment", 8, 5, 1], ["asteroid", 9, 6, 1], ["fragment", 4, 4, 0]],
	"hull": [["hull", 15, 6, 2], ["trench", 16, 7, 2], ["hull", 13, 8, 3], ["solar", 14, 5, 0], ["trench", 14, 9, 3]],
	"open": [["solar", 12, 5, 0], ["fragment", 6, 4, 0], ["solar", 16, 4, 0]],
	"core": [["hull", 16, 7, 3], ["reactor", 10, 10, 3], ["trench", 17, 8, 3], ["hull", 14, 9, 3], ["reactor", 8, 8, 2]],
	"boss": [["solar", 15, 5, 0], ["fragment", 7, 5, 0], ["solar", 12, 4, 0]],
}
## distance (units) between sections per area: [min, max]
const GAPS := {"debris": [3.0, 10.0], "hull": [0.5, 3.0], "open": [8.0, 16.0], "core": [0.0, 2.0], "boss": [10.0, 18.0]}

var game: Game
var layouts := {}  # area -> Array[Dictionary]
var islands: Array[Island] = []
var spawning := false
var turrets := true
var area := "debris"
var next_in := 0.0
var rng := RandomNumberGenerator.new()
var scroll_total := 0.0
var last_layout := -1
var gallery_i := 0

var nebula_mat: ShaderMaterial
var planet: Node3D
var star_layers: Array = []  # {mm: MultiMesh, pos: PackedVector3Array, rect: Rect2}
var deep: Array[MeshInstance3D] = []
var deep_rect := Rect2()
const DEEP_Y := -55.0


func prepare() -> void:
	rng.seed = 7
	var s := 100
	for a: String in AREAS:
		var list: Array[Dictionary] = []
		for l: Array in AREAS[a]:
			list.append(IslandGen.make(s, l[0], l[1], l[2], l[3]))
			s += 17
		layouts[a] = list
	_build_backdrop()


func reset(spawn: bool) -> void:
	for isl in islands:
		isl.queue_free()
	islands.clear()
	spawning = spawn
	turrets = spawn
	area = "debris" if spawn else "hull"
	next_in = 4.0
	rng.seed = 7


func set_area(a: String) -> void:
	if layouts.has(a):
		area = a


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
	# ringed planet
	planet = Node3D.new()
	var body := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 30.0
	sp.height = 60.0
	sp.radial_segments = 96
	sp.rings = 48
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/planet.gdshader")
	sp.material = mat
	body.mesh = sp
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet.add_child(body)
	var ring := MeshInstance3D.new()
	var rp := PlaneMesh.new()
	rp.size = Vector2(150, 150)
	var rmat := ShaderMaterial.new()
	rmat.shader = load("res://shaders/ring.gdshader")
	rp.material = rmat
	ring.mesh = rp
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet.add_child(ring)
	planet.position = Vector3(-70, -150, game.screen_to_y(Vector2(480, 220), -150).z)
	planet.rotation = Vector3(0.45, 0.3, 0.25)
	add_child(planet)
	# stars
	var amat := ShaderMaterial.new()
	amat.shader = load("res://shaders/additive.gdshader")
	amat.render_priority = -5
	for layer in [[-18.0, 70, 0.16], [-45.0, 180, 0.26], [-110.0, 420, 0.42]]:
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
			var tint := Color(0.75, 0.85, 1.0) if randf() < 0.7 else Color(1.0, 0.85, 0.7)
			mm.set_instance_color(i, tint * randf_range(0.4, 1.0))
			mm.set_instance_custom_data(i, Color(0, 0, randf(), 0))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = AABB(Vector3(rect.position.x - 5, y - 5, rect.position.y - 5), Vector3(rect.size.x + 10, 10, rect.size.y + 10))
		add_child(mi)
		star_layers.append({"mm": mm, "pos": pos, "rect": rect, "size": size})
	# colossal structure far below: girders and hull blocks
	var a2 := game.screen_to_y(Vector2(-100, -160), DEEP_Y)
	var b2 := game.screen_to_y(Vector2(1060, 880), DEEP_Y)
	deep_rect = Rect2(a2.x, a2.z, b2.x - a2.x, b2.z - a2.z)
	for i in 4:
		var m := MeshInstance3D.new()
		m.mesh = Vox.get_mesh("deep_girder" if i % 2 == 0 else "deep_block")
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(deep_rect.position.x + deep_rect.size.x * (0.25 + 0.5 * (i % 2)), DEEP_Y - (i % 2) * 8.0, deep_rect.position.y + deep_rect.size.y * i / 4.0)
		add_child(m)
		deep.append(m)


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
	for m in deep:
		m.position.z += speed * dt
		if m.position.z > deep_rect.end.y + 20.0:
			m.position.z -= deep_rect.size.y + 40.0
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
	var list: Array[Dictionary] = layouts[area]
	var li := rng.randi_range(0, list.size() - 1)
	if list.size() > 1 and li == last_layout:
		li = (li + 1) % list.size()
	if game.gallery == 3:
		var all: Array[Dictionary] = []
		for a: String in layouts:
			all.append_array(layouts[a])
		list = all
		li = gallery_i % all.size()
		gallery_i += 1
	last_layout = li
	var lay := list[li]
	var isl := Island.new()
	add_child(isl)
	isl.setup(game, lay)
	var hw := game.ground_hw
	var w: int = lay["w"]
	var h: int = lay["h"]
	var half := w * Island.CELL * 0.5
	var x := 0.0
	if half < hw:
		x = rng.randf_range(-hw + half * 0.6, hw - half * 0.6)
	else:
		x = rng.randf_range(-2.0, 2.0)
	isl.position = Vector3(x, Game.GROUND_Y, game.ground_top - h * Island.CELL * 0.5 - 2.0)
	islands.append(isl)
	if turrets:
		for c: Vector2i in lay["turrets"]:
			game.spawn_enemy("turret", {"island": isl, "cell": c})
	var gap: Array = GAPS[area]
	next_in = h * Island.CELL + rng.randf_range(gap[0], gap[1]) + IslandGen.MARGIN * IslandGen.R * 2.0


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
