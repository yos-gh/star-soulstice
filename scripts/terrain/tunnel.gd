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
## The style "open" is no tunnel at all (the open sky of stage 4 before it
## dives into the base): empty segments keep the beat. Going from open into
## a style, the gate comes with the facade of the base round it (the
## "mouth", TunnelModels._facade); it comes in further off than a segment
## would, so its face, which reaches far down, is off the screen until it
## scrolls in.
## A surface style (SurfaceModels: stage 5 out on the enemy planet) is open
## ground instead: its segments are drawn at random from the style's
## variants and every other one is turned round; its gate is the way from
## the area before into it (out of the base, into a canyon, into a crater).
## A canyon keeps the sections between its walls (SurfaceModels.SPAN).

const OPEN := "open"
## how far up the screen (z) the mouth comes in: its deep facade must be
## past the top edge
const MOUTH_Z := -60.0

var game: Game
var styles := {}  # area -> TunnelModels style (or OPEN)
var style := ""
var segs: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var seed_ := 1
var z_far := 0.0  # a new segment comes in once the farthest one is past this
var z_near := 0.0  # a segment goes once it is past this
var count := 0
var gate := false
var mouth := false  # the next gate is the base's mouth (out of the open)
var mouth_seg: MeshInstance3D  # the last mouth to come in (stage 4's blast door rides on it)
var edge := ""  # out of a surface style into the open: the ground breaks off there (stage 5)


func build(cfg: Dictionary) -> void:
	styles = cfg.get("styles", {})
	seed_ = int(cfg.get("seed", 1))
	style = String(cfg.get("first", styles.values()[0] if not styles.is_empty() else TunnelModels.STYLES[0]))
	# (open ground lies deeper than a tunnel's floor: it shows further up)
	var deep := TunnelModels.FLOOR
	for s: String in styles.values():
		if SurfaceModels.STYLES.has(s):
			deep = -11.5
	z_far = game.screen_to_y(Vector2(480, -40), deep).z - TunnelModels.LEN * 0.5
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
	edge = ""
	gate = false
	mouth = false
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
		mouth = style == OPEN and s != OPEN
		if SurfaceModels.STYLES.has(style) and s == OPEN:
			edge = style
		style = s
		gate = true


## Whether the tunnel's walls are there (not the open sky or ground).
func walled() -> bool:
	return style != OPEN and not SurfaceModels.STYLES.has(style)


## How far either side of the middle the ground sections may lie in style
## `st` (0 = anywhere): between a tunnel's walls or a canyon's.
static func span_of(st: String) -> float:
	if st == OPEN:
		return 0.0
	if SurfaceModels.STYLES.has(st):
		return float(SurfaceModels.SPAN.get(st, 0.0))
	return TunnelModels.HW


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
	if mouth and gate:
		# open sky on out to where the mouth comes in, then the mouth
		while far - TunnelModels.LEN > MOUTH_Z:
			far -= TunnelModels.LEN
			_add(far, OPEN)
		far -= TunnelModels.LEN
		_add(far)
	while far - TunnelModels.LEN * 0.5 > z_far:
		far -= TunnelModels.LEN
		_add(far)


func _add(z: float, as_style := "") -> void:
	var st := style if as_style == "" else as_style
	var m := MeshInstance3D.new()
	m.position = Vector3(0, 0, z)
	add_child(m)
	segs.append(m)
	if st == OPEN:
		# (where a surface ends: the ground breaking off at a cliff)
		if edge != "" and as_style == "":
			var n := "surface_%s_edge" % edge
			edge = ""
			gate = false
			if SurfaceModels.NAMES.has(n):
				m.mesh = Vox.get_mesh(n)
		return
	if SurfaceModels.STYLES.has(st):
		var vs: Array = SurfaceModels.VARIANTS[st]
		var sv: String = "gate" if gate else vs[rng.randi() % vs.size()]
		gate = false
		mouth = false
		m.mesh = Vox.get_mesh("surface_%s_%s" % [st, sv])
		if sv != "gate" and rng.randf() < 0.5:
			m.rotation.y = PI
		count += 1
		return
	var variant := "plain"
	var props_of := ""
	if gate:
		variant = "gate"
		props_of = "mouth" if mouth else "gate"
		if mouth:
			mouth_seg = m
		gate = false
		mouth = false
	elif count % 2 == 0:
		variant = "rib"
	elif rng.randf() < 0.4:
		variant = "feature"
	count += 1
	m.mesh = Vox.get_mesh("tunnel_%s_%s" % [st, variant])
	for p: Array in TunnelModels.props(st, props_of if props_of != "" else variant):
		var n := MeshInstance3D.new()
		n.mesh = Vox.get_mesh(p[0])
		n.position = p[1]
		n.set_meta("spin", p[2])
		m.add_child(n)
