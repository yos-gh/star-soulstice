class_name Stage
extends RefCounted
## Runs one StageDef: its areas in turn, then the boss.
## Enemies come in waves (formations), not on a timer: the
## next wave starts as soon as the current one is wiped out (or leaves), or
## when its time runs out — so fast killing shortens the stage ("early
## arrival"). Turrets come with the islands, carriers and area streams on
## their own timers; none of them counts toward clearing a wave. After the
## last wave: a warning, then the boss.

const GAP := 0.3

var game: Game
var def: StageDef
var waves: Array = []  # {spawns: [[delay, kind, params]], timeout, mid, area}
var wi := -1
var wave_t := 0.0
var pending: Array = []
var members: Array = []
var gap_t := 2.0
var carrier_t := 6.0
var phase := "waves"  # waves, warn, boss (done: a stage with no boss yet is over)
var warn_t := 0.0
var mid_index := 0
var area := ""
var stream_t := 1.0


func _init(g: Game, d: StageDef) -> void:
	game = g
	def = d
	if def.waves.is_empty():
		def.build_waves(Formations.new(g))
	waves = def.waves
	mid_index = def.mid_index()
	carrier_t = def.carrier_first


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
			var a: Dictionary = def.areas.get(area, {})
			if a.has("stream"):
				var s: Dictionary = a["stream"]
				stream_t -= dt
				if stream_t <= 0.0:
					stream_t = float(s["every"]) * randf_range(0.6, 1.4)
					(s["spawn"] as Callable).call(game)
			if def.carrier != "" and not w.is_empty() and not w.get("mid", false):
				carrier_t -= dt
				if carrier_t <= 0.0:
					carrier_t = def.carrier_every
					var x := randf_range(-0.6, 0.6) * game.field_hw
					game.spawn_enemy(def.carrier, {"x": x, "z": game.field_top - 1.5})
		"warn":
			warn_t -= dt
			if warn_t <= 0.0:
				phase = "boss"
				game.spawn_boss(def.boss, true)


## Early arrival is generous: in a wave of 5+ the last small fighter may
## still be alive.
func _nearly_clear() -> bool:
	var alive: Array = []
	for m in members:
		if not is_instance_valid(m):
			continue
		if m is Enemy and not (m as Enemy).dead and game.enemies.has(m):
			alive.append(m)
		elif m is BossBase and not (m as BossBase).finished:
			return false
	if alive.is_empty():
		return true
	return alive.size() == 1 and members.size() >= 5 and (alive[0] as Enemy).category != "medium"


func _next_wave() -> void:
	wi += 1
	wave_t = 0.0
	gap_t = GAP
	members.clear()
	if wi >= waves.size():
		if def.boss == "":
			# (a stage built only up to its mid-boss so far ends here)
			phase = "done"
			game.stage_cleared("TO BE CONTINUED")
			return
		_begin_warn()
		return
	_set_area(waves[wi].get("area", def.first_area))
	pending = (waves[wi]["spawns"] as Array).duplicate()
	pending.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	if waves[wi].get("mid", false):
		var who := "MID-BOSS"
		for s: Array in pending:
			if Bosses.has(s[1]):
				who = Bosses.title(s[1])
				break
		game.show_msg("CAUTION", who + " APPROACHING", 2.0, true)


func _begin_warn() -> void:
	phase = "warn"
	warn_t = def.boss_warn_time
	game.terrain.turrets = false
	_set_area(def.boss_area)
	game.show_msg(def.boss_warning[0], def.boss_warning[1], 4.5, true)
	game.sfx.play("warning")


func _set_area(a: String) -> void:
	if a == area:
		return
	area = a
	game.terrain.set_area(a)
	game.backdrop.set_area(a)
	var s: Dictionary = (def.areas.get(a, {}) as Dictionary).get("stream", {})
	if not s.is_empty():
		stream_t = float(s.get("first", s["every"]))
	var n := def.area_label(a)
	if not n.is_empty():
		game.show_msg(n[0], n[1], 2.5)


func _spawn(kind: String, params: Dictionary) -> void:
	if Bosses.has(kind):
		members.append(game.spawn_boss(kind, false))
		return
	var e := game.spawn_enemy(kind, params)
	if e.counts:
		members.append(e)
