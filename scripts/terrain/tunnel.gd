class_name Tunnel
extends Node3D
## A tunnel the stage flies down, inside a factory or a base: a floor not
## far below the ground sections and a wall up each side, close enough that
## the scroll rushes past (TunnelModels segments, end to end, moving with
## the scroll). Built by Backdrop from a stage's `backdrop.tunnel`:
##   {styles: {area: style}, first: style, seed}
## Each area has its style. When the area changes, a blast-door gate comes
## down the tunnel and the segments behind it take the new style. Every
## other segment is a bulkhead rib and some carry the style's set piece
## (in a fixed order per seed: the stage plays the same every time). The
## walls also bound the ground sections (Terrain.span_hw).

var game: Game
var styles := {}  # area -> TunnelModels style
var style := ""
var segs: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var seed_ := 1
var z_far := 0.0  # a new segment comes in once the farthest one is past this
var z_near := 0.0  # a segment goes once it is past this
var count := 0
var gate := false


func build(cfg: Dictionary) -> void:
	styles = cfg.get("styles", {})
	seed_ = int(cfg.get("seed", 1))
	style = String(cfg.get("first", styles.values()[0] if not styles.is_empty() else TunnelModels.STYLES[0]))
	z_far = game.screen_to_y(Vector2(480, -40), TunnelModels.FLOOR).z - TunnelModels.LEN * 0.5
	z_near = game.screen_to_y(Vector2(480, 760), 0.0).z + TunnelModels.LEN * 0.5
	_fill()


## The tunnel from the bottom of the screen to beyond the top, in the
## current style.
func _fill() -> void:
	for s in segs:
		s.queue_free()
	segs.clear()
	rng.seed = seed_
	count = 0
	gate = false
	var z := z_near
	while z > z_far - TunnelModels.LEN:
		_add(z)
		z -= TunnelModels.LEN


## The tunnel after the next gate takes the style of area `a`; `now`
## restyles all of it at once (a stage start, the viewer).
func set_area(a: String, now := false) -> void:
	var s: String = styles.get(a, style)
	if now:
		style = s
		_fill()
	elif s != style:
		style = s
		gate = true


func tick(dt: float, speed: float) -> void:
	var far := INF
	var i := 0
	while i < segs.size():
		var m := segs[i]
		m.position.z += speed * dt
		if m.position.z - TunnelModels.LEN * 0.5 > z_near:
			m.queue_free()
			segs.remove_at(i)
			continue
		far = minf(far, m.position.z)
		for c in m.get_children():
			if c.has_meta("spin"):
				(c as Node3D).rotation.y += float(c.get_meta("spin")) * dt
		i += 1
	while far - TunnelModels.LEN * 0.5 > z_far:
		far -= TunnelModels.LEN
		_add(far)


func _add(z: float) -> void:
	var variant := "plain"
	if gate:
		variant = "gate"
		gate = false
	elif count % 2 == 0:
		variant = "rib"
	elif rng.randf() < 0.4:
		variant = "feature"
	count += 1
	var m := MeshInstance3D.new()
	m.mesh = Vox.get_mesh("tunnel_%s_%s" % [style, variant])
	m.position = Vector3(0, 0, z)
	add_child(m)
	for p: Array in TunnelModels.props(style, variant):
		var n := MeshInstance3D.new()
		n.mesh = Vox.get_mesh(p[0])
		n.position = p[1]
		n.set_meta("spin", p[2])
		m.add_child(n)
	segs.append(m)
