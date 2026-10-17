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
## or two laps), then away snaking: rows back and forth across the middle,
## each crossing the centre line in front of the ship. Wherever the ship
## is, they pass somewhere easy to shoot; coming in from a corner, they
## rarely surprise it.
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
		pts.append(_screen(Vector2(a.x * RACE_A, RACE_V + a.y * RACE_B)))
	var c := Curve2D.new()
	c.bake_interval = 0.2
	var dist := PackedFloat32Array([0.0])
	for k in pts.size():
		c.add_point(pts[k])
		if k > 0:
			dist.append(dist[k - 1] + pts[k].distance_to(pts[k - 1]))
	# fire once a lap, from the top of the loop
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


## The racers' loop in screen fractions (see _screen): half axes and the
## height of its centre. It fills the screen; its bottom runs along the
## bottom edge just out of the ship's reach.
const RACE_A := 0.85
const RACE_B := 0.85
const RACE_V := 0.05


## The racers' path drawn once with the loop as the unit circle: straight
## up from below the bottom left onto the left of the circle, clockwise
## round it, then off the left of it into a snake: four rows across the
## middle (each one crossing the centre line, in front of the ship when
## mirrored to come in from the top), joined by round hairpins, and out.
## `lap_at` gets [first, end) sample indices of each lap.
func _racer_path(laps: int, lap_at: Array) -> PackedVector2Array:
	var out := PackedVector2Array([Vector2(-1.0, 2.6)])
	var v := 2.6
	while v > 0.05:
		v -= 0.1
		out.append(Vector2(-1.0, v))
	var n := 120  # samples a lap
	for k in laps:
		lap_at.append([out.size(), out.size() + n])
		for j in range(1, n + 1):
			var th := PI + TAU * (k * n + j) / n
			out.append(Vector2(cos(th), sin(th)))
	# the snake: rows at v0, v0 + 2r, ... from -w to w
	var w := 0.6
	var r := 0.205
	var v0 := -0.29
	out.append_array(_arc(Vector2(-1.0 - v0, 0.0), -v0, PI, PI * 1.5))
	for row in 4:
		var y := v0 + row * 2.0 * r
		var dir := 1.0 if row % 2 == 0 else -1.0
		out.append_array(_line(Vector2(out[out.size() - 1].x, y), Vector2(dir * w, y)))
		if row < 3:
			# hairpin round the end, onto the next row
			out.append_array(_arc(Vector2(dir * w, y + r), r, -PI / 2.0, PI / 2.0 if dir > 0.0 else -PI * 1.5))
	# a quarter turn at the end of the last row, and straight out
	var last := out[out.size() - 1]
	out.append_array(_arc(last + Vector2(0, 0.2), 0.2, -PI / 2.0, -PI))
	out.append_array(_line(out[out.size() - 1], Vector2(out[out.size() - 1].x, 3.0)))
	return out


## Points along a circular arc (centre c, radius rad) from angle a0 to a1,
## leaving out the first one.
func _arc(c: Vector2, rad: float, a0: float, a1: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var steps := maxi(4, int(absf(a1 - a0) * rad / 0.03))
	for j in range(1, steps + 1):
		var a := lerpf(a0, a1, float(j) / steps)
		out.append(c + Vector2(cos(a), sin(a)) * rad)
	return out


## Points along a straight line from a to b, leaving out the first one.
func _line(a: Vector2, b: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var steps := maxi(1, int(a.distance_to(b) / 0.05))
	for j in range(1, steps + 1):
		out.append(a.lerp(b, float(j) / steps))
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
