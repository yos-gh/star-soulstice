class_name Formations
extends RefCounted
## Formation helpers for stage scripts and the viewer. Each returns a spawn
## list [[delay, kind, params], ...] (delays in seconds from the start of
## the wave); join lists with +. x positions are fractions of the field's
## half width (-1 = left edge, 1 = right edge). The params are read by the
## enemy kind's script (see scripts/enemies/).

var game: Game


func _init(g: Game) -> void:
	game = g


func _hw() -> float:
	return game.field_hw


func _top() -> float:
	return game.field_top


## One enemy of any kind at x (`params` may override x, z and the rest).
func one(at: float, kind: String, xn: float, params := {}) -> Array:
	var p := {"x": xn * _hw()}
	p.merge(params, true)
	return [[at, kind, p]]


## The middle of the screen (z), where the small fighters should cross the
## centre line soon after they come in: easy to shoot from the middle.
func _mid() -> float:
	return _top() + 14.0


## A column diving in at x (use the outer part of the screen), then a wide
## U-turn toward `dir` (+1 = right) whose bottom lies on the centre line, a
## little above the middle.
func col(at: float, xn: float, count: int, interval: float, dir: int) -> Array:
	var out := []
	var x := xn * _hw()
	var v := 16.0
	var r := clampf(absf(x), 6.0, 14.0)
	var w := v / r
	var turn_t := maxf(0.05, (_mid() - (_top() - 1.5) - r) / v)
	for i in count:
		out.append([at + i * interval, "dart", {"x": x, "vx": 0.0, "vz": v, "turn_t": turn_t, "turn": -dir * w, "turn_dur": PI / w, "fire_at": 0.45}])
	return out


## Five darts in a V from the upper corner on `side` (-1 = left), down
## across the screen on a gentle arc: steeper at first, then easing out
## toward the far side, crossing the centre line at the middle. The V
## turns as one piece (each dart circles the same centre at the same rate).
func vform(at: float, side: int) -> Array:
	var out := []
	var dir := -float(side)  # +1 = heading right
	var p0 := Vector2(side * 0.8 * game.hw_top, _top() - 1.5)
	# headings from straight down toward the far side: the arc to the centre
	# crossing starts 18 degrees steeper than the straight line to it and
	# arrives 18 degrees flatter, then turns on to 48 degrees in all
	var chord := atan2(absf(p0.x), _mid() - p0.y)
	var phi0 := chord - deg_to_rad(18.0)
	var r := absf(p0.x) / (cos(phi0) - cos(chord + deg_to_rad(18.0)))
	var w := 18.0 / r
	var c := p0 + Vector2(dir * cos(phi0), -sin(phi0)) * r  # centre of the turn
	var h := Vector2(dir * sin(phi0), cos(phi0))
	var across := Vector2(h.y, -h.x)
	for i in range(-2, 3):
		var q := p0 + across * (i * 1.7) - h * (absi(i) * 1.3)
		var v := Vector2(dir * (q - c).y, -dir * (q - c).x) * w
		out.append([at, "dart", {"x": q.x, "z": q.y, "vx": v.x, "vz": v.y, "turn_t": 0.0, "turn": -dir * w, "turn_dur": deg_to_rad(48.0) / w, "fire_at": 0.55 if absi(i) == 2 else 99.0}])
	return out


## A stream from the upper side `side`, curving down to the centre line
## (the arc covers about 8.6 across; it ends just short of the centre).
func sweep(at: float, side: int, count: int, interval: float) -> Array:
	var out := []
	var x0 := _hw() + 1.0
	var turn_t := maxf(0.1, (x0 - 8.6 - 1.0) / 12.0)
	for i in count:
		out.append([at + i * interval, "dart", {"x": side * x0, "z": _top() + 2.5, "vx": -side * 12.0, "vz": 4.0, "turn_t": turn_t, "turn": -side * 1.0, "turn_dur": 1.3, "fire_at": 0.6 if i % 2 == 0 else 99.0}])
	return out


## Saucers from the edge on `side` (-1 = left) in the upper third, into
## one big loop on that half whose inner edge runs down the centre line,
## then away up that side of the screen (see swirl.gd).
func swirls(at: float, side: int, count: int, interval: float) -> Array:
	var out := []
	var r := 7.0
	var c := Vector3(side * (r + 0.5), 0, _mid() - 1.0)
	for i in count:
		out.append([at + i * interval, "swirl", {"x": side * (game.half_width_at(c.z - r) + 2.0), "z": c.z - r, "c": c, "r": r, "w": -side * 2.8, "loops": 1.75}])
	return out


## A train of chasers from behind (see chaser.gd), rising beside the
## ship's column: `side` +1 / -1 = to its right / left, 0 = toward the
## centre. The members come a frame apart so the leader always starts first.
func chasers(at: float, count: int, side := 0, gap := 1.8) -> Array:
	var out := []
	var grp := {}
	for i in count:
		out.append([at + i * 0.02, "chaser", {"i": i, "group": grp, "gap": gap, "side": side, "z": game.field_bottom + 4.0}])
	return out


## A train of flankers from `side` (-1 = left), level with the ship, hooking
## up (or down) the line at `hook` (fraction of the half width; see
## flanker.gd).
func flankers(at: float, side: int, count: int, hook := 0.0, up := true, gap := 1.8) -> Array:
	var out := []
	var grp := {}
	for i in count:
		out.append([at + i * 0.02, "flanker", {"side": side, "i": i, "group": grp, "gap": gap, "hook": hook, "up": up, "x": side * (_hw() + 6.0), "z": 0.0}])
	return out


## Flankers from both sides at once, `count` each, level with the ship:
## one side hooks up, the other down, just either side of the centre.
func pincer(at: float, count: int, left_up := true) -> Array:
	return flankers(at, -1, count, -0.12, left_up) + flankers(at, 1, count, 0.12, not left_up)


## A train of racers, after the GG Aleste 2 squadrons: in from a corner
## straight along a side, a big loop filling the screen round the ship (one
## or two laps), then away on a wide sine wave from the far side. Wherever
## the ship is, they pass somewhere easy to shoot; coming in from a corner,
## they rarely surprise it.
##   corner  where they come in: "bl", "br", "tl" or "tr" (from a top
##           corner they leave upward, away from the ship)
##   laps    laps round the loop (1 or 2)
##   along   false: in along the left or right side; true: along the top
##           or bottom
func racers(at: float, corner: String, laps: int, count: int, along := false, gap := 2.2) -> Array:
	var lap_at: Array = []
	var path := _racer_path(clampi(laps, 1, 3), lap_at)
	# mirror and turn (the loop is the unit circle here, so it stays put)
	var pts := PackedVector2Array()
	for q: Vector2 in path:
		var a := Vector2(-q.y, -q.x) if along else q
		if corner.contains("r"):
			a.x = -a.x
		if corner.contains("t"):
			a.y = -a.y
		pts.append(_on_plane(RACE_C + a * RACE_R))
	var c := Curve2D.new()
	c.bake_interval = 0.2
	var dist := PackedFloat32Array([0.0])
	for k in pts.size():
		c.add_point(pts[k])
		if k > 0:
			dist.append(dist[k - 1] + pts[k].distance_to(pts[k - 1]))
	# fire once a lap, from the top of the loop (and where a stage doubles
	# the fire, also as they come onto each lap: `early`)
	var fire := []
	var early := []
	for r: Array in lap_at:
		early.append(dist[r[0]])
		var j: int = r[0]
		for k in range(r[0], r[1]):
			if pts[k].y < pts[j].y:
				j = k
		fire.append(dist[j])
	var out := []
	for i in count:
		out.append([at + i * 0.02, "racer", {"curve": c, "i": i, "gap": gap, "fire": fire, "early": early, "x": pts[0].x, "z": pts[0].y}])
	return out


## The racers' loop on the 960 x 720 screen, in pixels: centre and half
## axes. It fills the screen with the same margin above and below.
const RACE_C := Vector2(480, 360)
const RACE_R := Vector2(416, 312)


## The racers' path drawn once with the loop as the unit circle: straight
## up from below the bottom left onto the left of the circle, clockwise
## round it, on to its right side and away down a cosine wave as wide as
## the loop (three quarters of a wave before it is off the screen). The
## ends stop just off the screen; the racer carries on straight from them.
## `lap_at` gets [first, end) sample indices of each lap.
func _racer_path(laps: int, lap_at: Array) -> PackedVector2Array:
	var out := PackedVector2Array([Vector2(-1.0, 1.4)])
	var v := 1.4
	while v > 0.05:
		v -= 0.05
		out.append(Vector2(-1.0, v))
	var n := 120  # samples a lap
	for k in laps:
		lap_at.append([out.size(), out.size() + n])
		for j in range(1, n + 1):
			var th := PI + TAU * (k * n + j) / n
			out.append(Vector2(cos(th), sin(th)))
	for j in range(1, int(n * 0.5) + 1):
		var th := PI + TAU * (laps * n + j) / n
		out.append(Vector2(cos(th), sin(th)))
	# from the right of the circle (heading down) on its crest
	var kw := 4.1
	v = 0.0
	while v < 1.4:
		v += 0.02
		out.append(Vector2(cos(kw * v), v))
	return out


## A screen point (960 x 720 pixels) to the play plane (x, z), seen from
## the play camera at rest (the live camera may be shaking, or be the
## viewer's free camera, when formations are built).
func _on_plane(px: Vector2) -> Vector2:
	var o := game.cam_pos
	var f := (Game.CAM_TARGET - o).normalized()
	var right := Vector3(1, 0, 0)
	var up := right.cross(f)
	var th := tan(deg_to_rad(Game.CAM_FOV) * 0.5)  # vertical field of view
	var d := f + right * ((px.x - 480.0) / 360.0 * th) - up * ((px.y - 360.0) / 360.0 * th)
	var p := o + d * (-o.y / d.y)
	return Vector2(p.x, p.z)


func rammers(at: float, xs: Array, interval: float) -> Array:
	var out := []
	for i in xs.size():
		out.append([at + i * interval, "rammer", {"x": float(xs[i]) * _hw()}])
	return out


func bulwark(at: float, xn: float, stay := 11.0) -> Array:
	return [[at, "bulwark", {"x": xn * _hw(), "z": _top() - 3.0, "stay": stay}]]


## A mining tug at x (fraction of the half width) down to hold `hold` below
## the top of the screen, with a boulder in its claws (see grappler.gd).
func grappler(at: float, xn: float, hold := 5.0, stay := 13.0) -> Array:
	return [[at, "grappler", {"x": xn * _hw(), "z": _top() - 3.0, "hold": _top() + hold, "stay": stay}]]


## A rail carriage down the wall on `side` (-1 = left) to hold `hold`
## below the top of the screen (see railjack.gd).
func railjack(at: float, side: int, hold := 5.5, stay := 12.0) -> Array:
	return [[at, "railjack", {"side": side, "x": side * (_hw() - 2.4), "z": _top() - 3.0, "hold": _top() + hold, "stay": stay}]]


## Orbital weapons parked across the way (see satellite.gd): `list` =
## [[xn, arm, dz, spin], ...], each just above the top edge at x (fraction
## of the half width), `dz` further up (optional); a lance turns its beam
## `spin` (+1 its far end moves right, -1 left; optional). They come down
## with the scroll.
func sats(at: float, list: Array) -> Array:
	var out := []
	for s: Array in list:
		var dz := float(s[2]) if s.size() > 2 else 0.0
		out.append([at, "satellite", {"x": float(s[0]) * _hw(), "z": _top() - 2.0 - dz, "arm": s[1], "spin": float(s[3]) if s.size() > 3 else 0.0}])
	return out


## A heavy gunship down from the top at x (fraction of the half width) to
## hold `hold` below the top of the screen (see halberd.gd).
func halberd(at: float, xn: float, hold := 6.0, stay := 14.0) -> Array:
	return [[at, "halberd", {"x": xn * _hw(), "hold": _top() + hold, "stay": stay}]]


## A VTOL gunship in from the side edge `side` (-1 = left) on a curve, to
## hover at x (fraction of the half width) `hold` below the top of the
## screen (see kestrel.gd).
func kestrel(at: float, side: int, xn: float, hold := 5.5, stay := 12.0) -> Array:
	return [[at, "kestrel", {"side": side, "hx": xn * _hw(), "x": side * (game.hw_top + 4.0), "z": _top() + 2.0, "hold": _top() + hold, "stay": stay}]]
