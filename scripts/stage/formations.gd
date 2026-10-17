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


## Five darts in a V from the upper corner on `side` (-1 = left), slanting
## down across the screen so the V crosses the centre line at the middle.
func vform(at: float, side: int) -> Array:
	var out := []
	var x0 := side * 0.8 * game.hw_top
	var z0 := _top() - 1.5
	var vz := 13.0
	var v := Vector3(-x0 / ((_mid() - z0) / vz), 0, vz)
	var dir := v.normalized()
	var across := Vector3(dir.z, 0, -dir.x)
	for i in range(-2, 3):
		var o := across * (i * 1.7) - dir * (absi(i) * 1.3)
		out.append([at, "dart", {"x": x0 + o.x, "z": z0 + o.z, "vx": v.x, "vz": v.z, "fire_at": 0.55 if absi(i) == 2 else 99.0}])
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


## A train of racers, after the GG Aleste 2 squadrons: in from a corner of
## the screen on a curve, fast laps round an ellipse in the middle of it,
## then off its top edge on a curve into a sine wave out across the screen.
## Wherever the ship is, they pass somewhere easy to shoot; coming in from
## a corner, they rarely surprise it.
##   corner  where they come in: "bl", "br", "tl" or "tr"
##   laps    laps round the ellipse (1 or 2)
##   along   false: in up (or down) the side first; true: in along the
##           bottom (or top) first, and out to the side
func racers(at: float, corner: String, laps: int, count: int, along := false, gap := 2.2) -> Array:
	var lap_at: Array = []
	var path := _racer_path(clampi(laps, 1, 3), lap_at)
	# mirror and turn (the ellipse is the unit circle here, so it stays put)
	var pts := PackedVector2Array()
	for q: Vector2 in path:
		var a := Vector2(-q.y, -q.x) if along else q
		if corner.contains("r"):
			a.x = -a.x
		if corner.contains("t"):
			a.y = -a.y
		pts.append(_screen(Vector2(a.x * RACE_A, RACE_V + a.y * RACE_B)))
	var c := Curve2D.new()
	c.bake_interval = 0.2
	var dist := PackedFloat32Array([0.0])
	for k in pts.size():
		c.add_point(pts[k])
		if k > 0:
			dist.append(dist[k - 1] + pts[k].distance_to(pts[k - 1]))
	# fire once a lap, from the highest point of the ellipse on screen
	var fire := []
	for r: Array in lap_at:
		var j: int = r[0]
		for k in range(r[0], r[1]):
			if pts[k].y < pts[j].y:
				j = k
		fire.append(dist[j])
	var out := []
	for i in count:
		out.append([at + i * 0.02, "racer", {"curve": c, "i": i, "gap": gap, "fire": fire, "x": pts[0].x, "z": pts[0].y}])
	return out


## The racers' ellipse in screen fractions (see _screen): half axes and the
## height of its centre (above the middle: the bottom of the ellipse passes
## in front of a ship low on the screen).
const RACE_A := 0.66
const RACE_B := 0.55
const RACE_V := -0.2


## The racers' path drawn once with the ellipse as the unit circle: in from
## the bottom left corner, up onto the left of the circle, clockwise round
## it, off the top on a quarter curve into a cosine wave down the screen.
## `lap_at` gets [first, end) sample indices of each lap.
func _racer_path(laps: int, lap_at: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var e := Vector2(-1.74, 2.37)
	var l := Vector2(-1.0, 0.0)
	out.append_array(_bezier(e, e + Vector2(0.25, -1.0).normalized() * 0.9, l + Vector2(0, 0.9), l, 40, true))
	var n := 120  # samples a lap
	for k in laps:
		lap_at.append([out.size(), out.size() + n])
		for j in range(1, n + 1):
			var th := PI + TAU * (k * n + j) / n
			out.append(Vector2(cos(th), sin(th)))
	for j in range(1, int(n * 0.25) + 1):
		var th := PI + TAU * (laps * n + j) / n
		out.append(Vector2(cos(th), sin(th)))
	# off the top (heading right) and round into the wave, heading down
	var w := 0.6
	var s := Vector2(w, -0.42)
	out.append_array(_bezier(Vector2(0, -1), Vector2(0.4, -1), s + Vector2(0, -0.35), s, 16, false))
	var kw := 3.4
	var v := s.y
	while v < 2.9:
		v += 0.04
		out.append(Vector2(w * cos(kw * (v - s.y)), v))
	return out


## Points along a cubic Bezier from p0 (only if `first`) to p3.
func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, steps: int, first: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	for j in range(0 if first else 1, steps + 1):
		var t := float(j) / steps
		var u := 1.0 - t
		out.append(p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t)
	return out


## Screen fraction (u right, v down; +-0.9 is a little inside the edges)
## to a point on the play plane.
func _screen(q: Vector2) -> Vector2:
	var z := lerpf(_top() + 2.0, game.field_bottom - 0.4, (q.y + 0.9) / 1.8)
	return Vector2(q.x / 0.9 * (game.half_width_at(z) - 1.4), z)


func rammers(at: float, xs: Array, interval: float) -> Array:
	var out := []
	for i in xs.size():
		out.append([at + i * interval, "rammer", {"x": float(xs[i]) * _hw()}])
	return out


func bulwark(at: float, xn: float, stay := 11.0) -> Array:
	return [[at, "bulwark", {"x": xn * _hw(), "z": _top() - 3.0, "stay": stay}]]
