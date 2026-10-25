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
##   rocks   {y: [near, far], count, meshes, size: [min, max], seed}  rocks of
##           an asteroid belt tumbling between the ground and the deep
##           layer, at depths spread from near to far (stage 3)
##   tunnel  {styles: {area: style}, first, seed}    a tunnel close below
##           (see Tunnel); its style follows the stage's area (set_area)
##   sky     {y, size, from: {area: level}, to: {area: level}, rate, rates,
##           clouds: {count, meshes, far: [y, y], near: [y, y], seed}}
##           a planet's atmosphere below (stage 4 diving into it): a plane at
##           y (shaders/sky.gdshader) and cloud banks above it. `level` says
##           how far down the stage is: 0 in space (the plane is clear and
##           the stars show), the haze and a cloud sea far below, from 0.7
##           the deck breaking up over the surface, 1.4 low over it. Each
##           area eases the level toward its `to` at `rate` a second (or its
##           own in `rates`; starting an area at once, as a stage start or
##           the viewer does, puts it at its `from`); the plane's features
##           grow and quicken and the cloud banks rise from `far` to `near`
##           as it comes down (out from level 0.22 to 1.02, not in an area
##           that goes lower than that, nor in a base)
## Palette sets the colours of the nebula, planet, ring and sky.

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
var belt: Array = []  # {m, a, b, spin}: the rocks layer
var belt_rng := RandomNumberGenerator.new()
var tunnel: Tunnel
var scroll_total := 0.0
var sky_mat: ShaderMaterial
var sky := {}  # the sky config (see above)
var level := 0.0
var level_to := 0.0
var level_rate := 0.02  # the area's (sky.rates, else sky.rate)
var sky_off := Vector2.ZERO
var clouds: Array = []  # {m, far, near}
var cloud_rng := RandomNumberGenerator.new()


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
	belt.clear()
	tunnel = null
	sky_mat = null
	sky = {}
	clouds.clear()
	level = 0.0
	level_to = 0.0
	sky_off = Vector2.ZERO
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
	if cfg.has("rocks"):
		var rc: Dictionary = cfg["rocks"]
		belt_rng.seed = int(rc.get("seed", 3))
		var ys: Array = rc.get("y", [-12.0, -36.0])
		var meshes: Array = rc.get("meshes", [])
		var sz: Array = rc.get("size", [0.7, 1.4])
		var count: int = rc.get("count", 16)
		for i in count:
			if meshes.is_empty():
				break
			var y := lerpf(float(ys[0]), float(ys[1]), float(i) / maxf(count - 1.0, 1.0))
			var a := game.screen_to_y(Vector2(-160, -220), y)
			var b := game.screen_to_y(Vector2(1120, 940), y)
			var m := MeshInstance3D.new()
			m.mesh = Vox.get_mesh(meshes[i % meshes.size()])
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.scale = Vector3.ONE * belt_rng.randf_range(float(sz[0]), float(sz[1]))
			m.position = Vector3(belt_rng.randf_range(a.x, b.x), y, belt_rng.randf_range(a.z, b.z))
			m.rotation = Vector3(belt_rng.randf() * TAU, belt_rng.randf() * TAU, 0)
			add_child(m)
			belt.append({"m": m, "a": a, "b": b, "spin": Vector3(belt_rng.randf_range(-0.25, 0.25), belt_rng.randf_range(-0.3, 0.3), 0)})
	if cfg.has("sky"):
		_build_sky(cfg["sky"])
	if cfg.has("tunnel"):
		tunnel = Tunnel.new()
		tunnel.game = game
		add_child(tunnel)
		tunnel.build(cfg["tunnel"])


func _build_sky(sc: Dictionary) -> void:
	sky = sc
	var y: float = sc.get("y", -60.0)
	var sz: float = sc.get("size", 900.0)
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(sz, sz)
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	sky_mat.render_priority = -4  # over the stars (-5)
	sky_mat.set_shader_parameter("size", sz)
	pm.material = sky_mat
	plane.mesh = pm
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plane.position = Vector3(0, y, game.screen_to_y(Vector2(480, 360), y).z)
	add_child(plane)
	var cc: Dictionary = sc.get("clouds", {})
	cloud_rng.seed = int(cc.get("seed", 5))
	var meshes: Array = cc.get("meshes", [])
	var count: int = cc.get("count", 0)
	var far: Array = cc.get("far", [-48.0, -62.0])
	var near: Array = cc.get("near", [-8.0, -30.0])
	for i in count:
		if meshes.is_empty():
			break
		var f := float(i) / maxf(count - 1.0, 1.0)
		var c := {"far": lerpf(float(far[0]), float(far[1]), f), "near": lerpf(float(near[0]), float(near[1]), f)}
		var m := MeshInstance3D.new()
		m.mesh = Vox.get_mesh(meshes[i % meshes.size()])
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.rotation.y = cloud_rng.randf() * TAU
		m.scale = Vector3.ONE * cloud_rng.randf_range(0.8, 1.25)
		m.visible = false
		add_child(m)
		c["m"] = m
		c["on"] = false
		clouds.append(c)
	_place_clouds()
	_sky_view(0.0, 0.0)


## The stage's area changed (a tunnel takes on its style, the sky comes
## down toward the area's level); `now` = at once.
func set_area(a: String, now := false) -> void:
	if tunnel != null:
		tunnel.set_area(a, now)
	if not sky.is_empty():
		var to: Dictionary = sky.get("to", {})
		var from: Dictionary = sky.get("from", {})
		level_to = float(to.get(a, level_to))
		level_rate = float((sky.get("rates", {}) as Dictionary).get(a, sky.get("rate", 0.02)))
		if now:
			level = float(from.get(a, level_to))
			_place_clouds()
			_sky_view(0.0, 0.0)


## The cloud banks are out between these levels, and not inside a base.
const CLOUDS_FROM := 0.22
const CLOUDS_TO := 1.02


func _clouds_out() -> bool:
	return level >= CLOUDS_FROM and level < CLOUDS_TO and level_to <= CLOUDS_TO + 0.1 and (tunnel == null or not tunnel.walled())


## The depth band of the screen at height y, as seen from the resting
## camera: where a cloud bank comes in (top) and goes (bottom), and the
## half width it may come in across.
func _band(y: float) -> Vector3:
	var top := game.from_plane(Vector3(0, 0, game.field_top - 4.0), y).z - 16.0
	var bottom := game.from_plane(Vector3(0, 0, game.field_bottom + 4.0), y).z + 16.0
	var hw := absf(game.from_plane(Vector3(game.hw_top, 0, game.field_top), y).x) + 6.0
	return Vector3(top, bottom, hw)


## Cloud banks spread over the view (at a level where they are out), or
## waiting off the top in a queue.
func _place_clouds() -> void:
	var out := _clouds_out()
	var rise := smoothstep(0.25, 1.15, level)
	for i in clouds.size():
		var c: Dictionary = clouds[i]
		var m: MeshInstance3D = c["m"]
		var y := lerpf(c["far"], c["near"], rise)
		var b := _band(y)
		c["on"] = out
		m.visible = out
		m.position = Vector3(cloud_rng.randf_range(-b.z, b.z), y, lerpf(b.x, b.y, (i + cloud_rng.randf()) / clouds.size()) if out else b.x)


## The sky after `dt` of the scroll at `speed`: the level eases toward the
## area's, the plane's features grow (zoom) and run past faster the lower
## it is (the offset moves the same in noise cells whatever the zoom: a
## cell is bigger, so it crosses the screen sooner). The cloud banks come
## in once the level reaches CLOUDS_FROM, a queue of them from the top,
## rise as it comes down, and stop coming at CLOUDS_TO (below the deck) or
## inside a base: the ones out scroll away off the bottom.
func _sky_view(dt: float, speed: float) -> void:
	if sky_mat == null:
		return
	level = move_toward(level, level_to, level_rate * dt)
	sky_off.y -= speed * dt / float(sky.get("cell", 26.0))
	sky_mat.set_shader_parameter("level", level)
	sky_mat.set_shader_parameter("zoom", 0.38 * exp(level))
	sky_mat.set_shader_parameter("off", sky_off)
	var rise := smoothstep(0.25, 1.15, level)
	var out := _clouds_out()
	for i in clouds.size():
		var c: Dictionary = clouds[i]
		var m: MeshInstance3D = c["m"]
		var y := lerpf(c["far"], c["near"], rise)
		var b := _band(y)
		m.position.y = y
		if not c["on"]:
			if not out:
				continue
			# out of the haze: the queue comes in from the top
			c["on"] = true
			m.visible = true
			m.position = Vector3(cloud_rng.randf_range(-b.z, b.z), y, b.x - (b.y - b.x) * i / clouds.size())
		m.position.z += speed * dt
		if m.position.z > b.y:
			if out:
				m.position.z -= b.y - b.x
				m.position.x = cloud_rng.randf_range(-b.z, b.z)
			else:
				c["on"] = false
				m.visible = false


func tick(dt: float, speed: float) -> void:
	scroll_total += speed * dt
	_sky_view(dt, speed)
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
	for r: Dictionary in belt:
		var m: MeshInstance3D = r["m"]
		var a: Vector3 = r["a"]
		var b: Vector3 = r["b"]
		m.position.z += speed * dt
		m.rotation += (r["spin"] as Vector3) * dt
		if m.position.z > b.z:
			m.position.z -= b.z - a.z
			m.position.x = belt_rng.randf_range(a.x, b.x)
	for m in deep:
		m.position.z += speed * dt
		if m.position.z > deep_rect.end.y + 20.0:
			m.position.z -= deep_rect.size.y + 40.0
