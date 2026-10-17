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


## A column diving in at x, then a wide U-turn toward `dir` (+1 = right)
## whose bottom lies on the centre line, a little above the middle.
func col(at: float, xn: float, count: int, interval: float, dir: int) -> Array:
	var out := []
	var x := xn * _hw()
	var v := 16.0
	var r := clampf(absf(x), 6.0, 12.0)
	var w := v / r
	var turn_t := maxf(0.05, (_mid() - (_top() - 1.5) - r) / v)
	for i in count:
		out.append([at + i * interval, "dart", {"x": x, "vx": 0.0, "vz": v, "turn_t": turn_t, "turn": -dir * w, "turn_dur": PI / w, "fire_at": 0.45}])
	return out


## Five darts in a V, diving fast and slanting so the V crosses the centre
## line at the middle of the screen.
func vform(at: float, xn: float) -> Array:
	var out := []
	var xc := xn * _hw()
	var vz := 15.0
	var v := Vector3(-xc / ((_mid() - (_top() - 1.5)) / vz), 0, vz)
	var dir := v.normalized()
	var side := Vector3(dir.z, 0, -dir.x)
	for i in range(-2, 3):
		var o := side * (i * 1.7) - dir * (absi(i) * 1.3)
		out.append([at, "dart", {"x": xc + o.x, "z": _top() - 1.5 + o.z, "vx": v.x, "vz": v.z, "fire_at": 0.55 if absi(i) == 2 else 99.0}])
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


## Saucers diving in beside the centre line, then one big loop out toward
## `side` and away to that side across the middle of the screen.
func swirls(at: float, side: int, count: int, interval: float) -> Array:
	var out := []
	for i in count:
		out.append([at + i * interval, "swirl", {"x": side * 1.5, "zl": _top() + 10.5, "r": 7.0, "w": -side * 2.5, "loops": 1.25}])
	return out


## A train of chasers from behind, up the ship's column (see chaser.gd).
## The members come a frame apart so the leader always starts first.
func chasers(at: float, count: int, gap := 1.8) -> Array:
	var out := []
	var grp := {}
	for i in count:
		out.append([at + i * 0.02, "chaser", {"i": i, "group": grp, "gap": gap, "z": game.field_bottom + 4.0}])
	return out


## A train of flankers from `side` (-1 = left), level with the ship, hooking
## up the line at `hook` (fraction of the half width; see flanker.gd).
func flankers(at: float, side: int, count: int, hook := 0.0, gap := 1.8) -> Array:
	var out := []
	var grp := {}
	for i in count:
		out.append([at + i * 0.02, "flanker", {"side": side, "i": i, "group": grp, "gap": gap, "hook": hook, "x": side * (_hw() + 6.0), "z": 0.0}])
	return out


func rammers(at: float, xs: Array, interval: float) -> Array:
	var out := []
	for i in xs.size():
		out.append([at + i * interval, "rammer", {"x": float(xs[i]) * _hw()}])
	return out


func bulwark(at: float, xn: float, stay := 11.0) -> Array:
	return [[at, "bulwark", {"x": xn * _hw(), "z": _top() - 3.0, "stay": stay}]]
