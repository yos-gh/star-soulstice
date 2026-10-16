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


## A column diving in at x, then hair-pinning toward `dir` (+1 = right).
func col(at: float, xn: float, count: int, interval: float, dir: int) -> Array:
	var out := []
	for i in count:
		out.append([at + i * interval, "dart", {"x": xn * _hw(), "vx": 0.0, "vz": 16.0, "turn_t": 0.6, "turn": -dir * 3.3, "turn_dur": 0.95, "fire_at": 0.45}])
	return out


## Five darts in a V, straight down fast.
func vform(at: float, xn: float) -> Array:
	var out := []
	for i in range(-2, 3):
		out.append([at, "dart", {"x": xn * _hw() + i * 1.7, "z": _top() - 1.5 - absi(i) * 1.3, "vx": 0.0, "vz": 15.0, "fire_at": 0.55 if absi(i) == 2 else 99.0}])
	return out


## A stream from the upper side `side`, curving down across the screen.
func sweep(at: float, side: int, count: int, interval: float) -> Array:
	var out := []
	for i in count:
		out.append([at + i * interval, "dart", {"x": side * (_hw() + 1.0), "z": _top() + 2.5, "vx": -side * 12.0, "vz": 4.0, "turn_t": 0.3, "turn": -side * 1.0, "turn_dur": 1.3, "fire_at": 0.6 if i % 2 == 0 else 99.0}])
	return out


## Saucers looping in from `side`.
func swirls(at: float, side: int, count: int, interval: float) -> Array:
	var out := []
	var c := Vector3(side * (_hw() - 4.0), 0, _top() + 6.5)
	for i in count:
		out.append([at + i * interval, "swirl", {"c": c, "r": 5.5, "a0": 0.0 if side > 0 else PI, "w": -side * 2.6, "loops": 1.25}])
	return out


func rammers(at: float, xs: Array, interval: float) -> Array:
	var out := []
	for i in xs.size():
		out.append([at + i * interval, "rammer", {"x": float(xs[i]) * _hw()}])
	return out


func bulwark(at: float, xn: float, stay := 11.0) -> Array:
	return [[at, "bulwark", {"x": xn * _hw(), "z": _top() - 3.0, "stay": stay}]]
