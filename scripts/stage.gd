class_name Stage
extends RefCounted
## Stage 1 script: three areas of an orbital fortress, then the boss.
##   AREA 1 DEBRIS BELT  wreckage and asteroids around the fortress
##   AREA 2 OUTER HULL   armoured decks, trenches and solar arrays
##   (open space)        Lazaro
##   AREA 3 CORE BLOCK   dense machinery and reactors
##   STAR CORTEX         over the reactor field
## Enemies come in waves (formations), not on a timer: the
## next wave starts as soon as the current one is wiped out (or leaves), or
## when its time runs out — so fast killing shortens the stage ("early
## arrival"). Turrets come with the islands and containers on their own
## timer; neither counts toward clearing a wave. After the last wave: boss.

const GAP := 0.3
const CONTAINER_EVERY := 12.0
const ROCK_EVERY := 1.3
const AREA_NAMES := {"debris": ["AREA 1", "DEBRIS BELT"], "hull": ["AREA 2", "OUTER HULL"], "core": ["AREA 3", "CORE BLOCK"]}

var game: Game
var waves: Array = []  # {spawns: [[delay, kind, params]], timeout, mid}
var wi := -1
var wave_t := 0.0
var pending: Array = []
var members: Array = []
var gap_t := 2.0
var container_t := 6.0
var phase := "waves"  # waves, warn, boss
var warn_t := 0.0
var mid_index := 0
var area := ""
var rock_t := 1.0


func _init(g: Game) -> void:
	game = g
	_build()


func wave_count() -> int:
	return waves.size()


func start_at(what: String) -> void:
	if what == "mid":
		wi = mid_index - 1
		gap_t = 1.0
	elif what == "boss":
		wi = waves.size()
		_begin_warn()
	elif what.is_valid_int():
		wi = clampi(int(what), 1, waves.size()) - 2
		gap_t = 1.0


func tick(dt: float) -> void:
	match phase:
		"waves":
			if wi >= 0 and wi < waves.size():
				wave_t += dt
				while not pending.is_empty() and float(pending[0][0]) <= wave_t:
					var s: Array = pending.pop_front()
					_spawn(s[1], s[2])
			var w: Dictionary = waves[wi] if wi >= 0 and wi < waves.size() else {}
			var cleared := pending.is_empty() and _nearly_clear()
			var timeout := not w.is_empty() and wave_t >= float(w["timeout"])
			if wi < 0 or cleared or timeout:
				gap_t -= dt
				if gap_t <= 0.0:
					_next_wave()
			if area == "debris":
				rock_t -= dt
				if rock_t <= 0.0:
					rock_t = ROCK_EVERY * randf_range(0.6, 1.4)
					var big := randf() < 0.25
					game.spawn_enemy("rock", {"x": randf_range(-0.9, 0.9) * game.field_hw, "z": game.field_top - 2.5, "vx": randf_range(-1.2, 1.2), "vz": randf_range(2.5, 4.5) + Game.SCROLL * 0.3, "spin": randf_range(-1.2, 1.2), "big": big})
			if not w.is_empty() and not w.get("mid", false):
				container_t -= dt
				if container_t <= 0.0:
					container_t = CONTAINER_EVERY
					var x := randf_range(-0.6, 0.6) * game.field_hw
					game.spawn_enemy("container", {"x": x, "z": game.field_top - 1.5})
		"warn":
			warn_t -= dt
			if warn_t <= 0.0:
				phase = "boss"
				game.spawn_boss()


## Early arrival is generous: in a wave of 5+ the last small fighter may
## still be alive.
func _nearly_clear() -> bool:
	var alive: Array = []
	for m in members:
		if not is_instance_valid(m):
			continue
		if m is Enemy and not (m as Enemy).dead and game.enemies.has(m):
			alive.append(m)
		elif m is Lazaro and not (m as Lazaro).finished:
			return false
	if alive.is_empty():
		return true
	return alive.size() == 1 and members.size() >= 5 and (alive[0] as Enemy).kind != "bulwark"


func _alive() -> int:
	var c := 0
	for m in members:
		if not is_instance_valid(m):
			continue
		if m is Enemy:
			var e := m as Enemy
			if not e.dead and game.enemies.has(e):
				c += 1
		elif m is Lazaro:
			if not (m as Lazaro).finished:
				c += 1
	return c


func _next_wave() -> void:
	wi += 1
	wave_t = 0.0
	gap_t = GAP
	members.clear()
	if wi >= waves.size():
		_begin_warn()
		return
	_set_area(waves[wi].get("area", "hull"))
	pending = (waves[wi]["spawns"] as Array).duplicate()
	pending.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	if waves[wi].get("mid", false):
		game.show_msg("CAUTION", "LAZARO APPROACHING", 2.0, true)


func _begin_warn() -> void:
	phase = "warn"
	warn_t = 5.5
	# islands keep coming during the boss (tiles refill energy), minus turrets
	game.terrain.turrets = false
	_set_area("boss")
	game.show_msg("WARNING", "A HUGE ENERGY SOURCE IS APPROACHING", 4.5, true)
	game.sfx.play("warning")


func _set_area(a: String) -> void:
	if a == area:
		return
	area = a
	game.terrain.set_area(a)
	if AREA_NAMES.has(a):
		var n: Array = AREA_NAMES[a]
		game.show_msg(n[0], n[1], 2.5)


func _spawn(kind: String, params: Dictionary) -> void:
	if kind == "lazaro":
		members.append(game.spawn_lazaro())
		return
	var e := game.spawn_enemy(kind, params)
	if e.counts:
		members.append(e)


# ------------------------------------------------------------ formations

func _hw() -> float:
	return game.field_hw


func _top() -> float:
	return game.field_top


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


func _w(area_name: String, spawns: Array, timeout := 7.0, mid := false) -> void:
	waves.append({"spawns": spawns, "timeout": timeout, "mid": mid, "area": area_name})


func _build() -> void:
	# AREA 1: debris belt (asteroids drift through on their own timer)
	_w("debris", col(0.5, -0.45, 6, 0.2, 1))
	_w("debris", col(0.0, 0.45, 6, 0.2, -1) + rammers(1.6, [-0.3], 0.2))
	_w("debris", swirls(0.0, -1, 5, 0.25) + swirls(1.2, 1, 5, 0.25), 8.0)
	_w("debris", vform(0.0, 0.0) + rammers(1.2, [-0.5, 0.5], 0.4) + vform(2.2, -0.4))
	# AREA 2: outer hull
	_w("hull", bulwark(0.0, 0.0) + col(2.0, -0.8, 4, 0.2, 1) + col(4.0, 0.8, 4, 0.2, -1), 12.0)
	_w("hull", sweep(0.0, -1, 6, 0.22) + sweep(1.0, 1, 6, 0.22))
	_w("hull", vform(0.0, -0.5) + vform(0.8, 0.5) + vform(1.6, 0.0))
	_w("hull", bulwark(0.0, -0.5) + bulwark(1.5, 0.5), 12.0)
	_w("hull", swirls(0.0, -1, 5, 0.22) + rammers(1.0, [-0.4, 0.4], 0.3) + swirls(1.5, 1, 5, 0.22), 8.0)
	# open space between the hull and the core: Lazaro
	mid_index = waves.size()
	_w("open", [[0.0, "lazaro", {}]], 60.0, true)
	# AREA 3: core block
	_w("core", col(0.0, -0.6, 5, 0.18, 1) + col(0.6, 0.6, 5, 0.18, -1) + col(1.2, -0.2, 5, 0.18, 1) + col(1.8, 0.2, 5, 0.18, -1))
	_w("core", bulwark(0.0, 0.0) + rammers(2.0, [-0.6, 0.6], 0.2) + rammers(4.0, [0.0], 0.2), 12.0)
	_w("core", vform(0.0, -0.6) + vform(0.5, 0.6) + vform(1.2, 0.0) + vform(2.0, -0.3) + vform(2.5, 0.3))
	_w("core", bulwark(0.0, -0.55) + bulwark(1.0, 0.55) + swirls(3.0, -1, 4, 0.25) + swirls(3.5, 1, 4, 0.25), 12.0)
	_w("core", sweep(0.0, -1, 8, 0.18) + sweep(0.4, 1, 8, 0.18) + col(1.5, 0.0, 6, 0.2, 1), 8.0)
