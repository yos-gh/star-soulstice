class_name Backdrop
extends Node3D
## The scenery far below the ground: a nebula, a ringed planet, star layers
## and a deep layer of colossal structures (blurred by depth of field).
## Perspective gives the parallax for free. Built from a stage's `backdrop`
## dictionary (every entry optional):
##   nebula  {y, size}                              shaders/space.gdshader
##   planet  {x, y, screen_y, radius, rotation, ring}  ring = ring plane size (0 = none)
##   stars   [[height, count, size], ...]
##   deep    {y, meshes: [model names], count}       far-below blocks, cycling
##   tunnel  {styles: {area: style}, first, seed}    a tunnel close below
##           (see Tunnel); its style follows the stage's area (set_area)
## Palette sets the colours of the nebula, planet and ring.

var game: Game
var config := {}
var built := false

var nebula_mat: ShaderMaterial
var planet_mat: ShaderMaterial
var ring_mat: ShaderMaterial
var planet: Node3D
var star_layers: Array = []  # {mm: MultiMesh, pos: PackedVector3Array, rect: Rect2, size}
var deep: Array[MeshInstance3D] = []
var deep_rect := Rect2()
var tunnel: Tunnel
var scroll_total := 0.0


## Builds the scenery for `cfg` (does nothing if it is already showing).
func use(cfg: Dictionary) -> void:
	if built and cfg == config:
		return
	for c in get_children():
		c.queue_free()
	nebula_mat = null
	planet_mat = null
	ring_mat = null
	planet = null
	star_layers.clear()
	deep.clear()
	tunnel = null
	config = cfg
	built = true
	build(cfg)
	if game.env != null:
		Palette.apply(game, Palette.current)


func build(cfg: Dictionary) -> void:
	if cfg.has("nebula"):
		var nb: Dictionary = cfg["nebula"]
		var ny: float = nb.get("y", -240.0)
		var neb := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		var ns: float = nb.get("size", 760.0)
		pm.size = Vector2(ns, ns)
		nebula_mat = ShaderMaterial.new()
		nebula_mat.shader = load("res://shaders/space.gdshader")
		nebula_mat.render_priority = -10
		pm.material = nebula_mat
		neb.mesh = pm
		neb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		neb.position = Vector3(0, ny, game.screen_to_y(Vector2(480, 360), ny).z)
		add_child(neb)
	if cfg.has("planet"):
		var pc: Dictionary = cfg["planet"]
		planet = Node3D.new()
		var body := MeshInstance3D.new()
		var sp := SphereMesh.new()
		var r: float = pc.get("radius", 30.0)
		sp.radius = r
		sp.height = r * 2.0
		sp.radial_segments = 96
		sp.rings = 48
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/planet.gdshader")
		planet_mat = mat
		sp.material = mat
		body.mesh = sp
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		planet.add_child(body)
		var rs: float = pc.get("ring", 0.0)
		if rs > 0.0:
			var ring := MeshInstance3D.new()
			var rp := PlaneMesh.new()
			rp.size = Vector2(rs, rs)
			var rmat := ShaderMaterial.new()
			rmat.shader = load("res://shaders/ring.gdshader")
			ring_mat = rmat
			rp.material = rmat
			ring.mesh = rp
			ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			planet.add_child(ring)
		var py: float = pc.get("y", -150.0)
		planet.position = Vector3(pc.get("x", 0.0), py, game.screen_to_y(Vector2(480, pc.get("screen_y", 220.0)), py).z)
		planet.rotation = pc.get("rotation", Vector3.ZERO)
		add_child(planet)
	if cfg.has("stars"):
		var amat := ShaderMaterial.new()
		amat.shader = load("res://shaders/additive.gdshader")
		amat.render_priority = -5
		for layer: Array in cfg["stars"]:
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
	if cfg.has("deep"):
		var dc: Dictionary = cfg["deep"]
		var dy: float = dc.get("y", -55.0)
		var meshes: Array = dc.get("meshes", [])
		var a2 := game.screen_to_y(Vector2(-100, -160), dy)
		var b2 := game.screen_to_y(Vector2(1060, 880), dy)
		deep_rect = Rect2(a2.x, a2.z, b2.x - a2.x, b2.z - a2.z)
		var count: int = dc.get("count", 4)
		for i in count:
			if meshes.is_empty():
				break
			var m := MeshInstance3D.new()
			m.mesh = Vox.get_mesh(meshes[i % meshes.size()])
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.position = Vector3(deep_rect.position.x + deep_rect.size.x * (0.25 + 0.5 * (i % 2)), dy - (i % 2) * 8.0, deep_rect.position.y + deep_rect.size.y * i / float(count))
			add_child(m)
			deep.append(m)
	if cfg.has("tunnel"):
		tunnel = Tunnel.new()
		tunnel.game = game
		add_child(tunnel)
		tunnel.build(cfg["tunnel"])


## The stage's area changed (a tunnel takes on its style); `now` = at once.
func set_area(a: String, now := false) -> void:
	if tunnel != null:
		tunnel.set_area(a, now)


func tick(dt: float, speed: float) -> void:
	scroll_total += speed * dt
	if tunnel != null:
		tunnel.tick(dt, speed)
	if nebula_mat != null:
		nebula_mat.set_shader_parameter("scroll", scroll_total * 0.0035)
	if planet != null:
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
