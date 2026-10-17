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
## the screen, fast laps around its edges (the last one spiralling in), then
## out snaking across it. Wherever the ship is, they pass somewhere easy to
## shoot; coming from the edges, they rarely surprise it.
##   corner  where they come in: "bl", "br", "tl" or "tr"
##   laps    1 or 2 laps around the edges before the inner one
##   along   false: first along the side edge (up or down); true: first
##           along the bottom or top edge
func racers(at: float, corner: String, laps: int, count: int, along := false, gap := 2.2) -> Array:
	# the path in screen fractions (u right, v down; +-0.9 = the lap's
	# edges), drawn once: in at the bottom left, up the left edge, clockwise
	var lap := [Vector2(-0.9, 0.55), Vector2(-0.9, -0.55), Vector2(-0.72, -0.85), Vector2(-0.35, -0.9), Vector2(0.35, -0.9),
		Vector2(0.72, -0.85), Vector2(0.9, -0.55), Vector2(0.9, 0.55), Vector2(0.72, 0.85), Vector2(0.35, 0.9),
		Vector2(-0.35, 0.9), Vector2(-0.72, 0.85)]
	var inner := [Vector2(-0.62, 0.45), Vector2(-0.62, -0.25), Vector2(-0.5, -0.55), Vector2(-0.15, -0.62), Vector2(0.3, -0.62),
		Vector2(0.55, -0.52)]
	# the snaking exit: rows across, a hairpin at each end
	var snake := [Vector2(0.42, -0.3), Vector2(0.0, -0.28), Vector2(-0.42, -0.26), Vector2(-0.56, -0.1),
		Vector2(-0.42, 0.06), Vector2(0.0, 0.08), Vector2(0.42, 0.1), Vector2(0.56, 0.26),
		Vector2(0.42, 0.42), Vector2(0.0, 0.44), Vector2(-0.42, 0.46), Vector2(-0.56, 0.62),
		Vector2(-0.42, 0.78), Vector2(0.0, 0.8), Vector2(0.5, 0.82), Vector2(0.66, 1.0), Vector2(0.7, 1.4)]
	var uv: Array = [Vector2(-0.9, 1.3)]
	var lap_at: Array = []  # the first point of each lap
	for k in clampi(laps, 1, 3):
		lap_at.append(uv.size())
		uv += lap
	uv += inner + snake
	# mirror and rotate: along = reflect across the corner's diagonal
	var pts := PackedVector2Array()
	for q: Vector2 in uv:
		var a := Vector2(-q.y, -q.x) if along else q
		if corner.contains("r"):
			a.x = -a.x
		if corner.contains("t"):
			a.y = -a.y
		pts.append(_screen(a))
	var c := _spline(pts, pts.size())
	# fire once a lap, from the middle of the lap's highest edge on screen
	var fire := []
	for s0: int in lap_at:
		var j := s0
		for k in range(s0, s0 + lap.size()):
			if pts[k].y < pts[j].y - 0.01:
				j = k
		if pts[j + 1].y > pts[j].y + 0.5:
			j -= 1
		fire.append(_spline(pts, j + 1).get_baked_length() + pts[j].distance_to(pts[j + 1]) * 0.5)
	var out := []
	for i in count:
		out.append([at + i * 0.02, "racer", {"curve": c, "i": i, "gap": gap, "fire": fire, "x": pts[0].x, "z": pts[0].y}])
	return out


## A smooth (Catmull-Rom) curve through the first `n` of `pts`.
func _spline(pts: PackedVector2Array, n: int) -> Curve2D:
	var c := Curve2D.new()
	c.bake_interval = 0.2
	for k in n:
		var tan := (pts[mini(k + 1, pts.size() - 1)] - pts[maxi(k - 1, 0)]) / 6.0
		c.add_point(pts[k], -tan, tan)
	return c


## Screen fraction (u right, v down; the racers' lap runs at +-0.9) to a
## point on the play plane: the lap keeps inside the sides and runs along
## the bottom edge just below the ship's reach.
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
