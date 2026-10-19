extends BossBase
## Mid-boss (after Star Soldier's Lazaro): a sphere that splits into four
## shell pieces, surrounds the player, then slams shut on where the player
## was. While closed after a slam its core is exposed for a while.
## The pieces take reduced damage; all damage goes to one shared pool.

const INFO := {
	"name": "LAZARO", "role": "mid",
	"desc": "4 つに割れて自機を囲み、閉じて挟む。閉じた直後は核がむき出し",
	"demos": [["FULL", ""]],
}
const HP := 240.0
const SCORE := 20000
const PIECE_MUL := 0.55
const ORBIT_R := 7.5
const PINCH_TIME := 1.5  # slow enough to slip out, or to shoot a piece down
const SPLIT_WARN := 0.6  # telegraph before the pieces fly out
const PINCH_WARN := 0.9  # before they slam shut
const LIFE := 50.0

var pieces: Array[Enemy] = []
var core: Enemy
var hp := HP
var state := "enter"
var st := 0.0
var life_t := 0.0
var center := Vector3.ZERO
var orbit_c := Vector3.ZERO
var orbit_a := 0.0
var pinch_from: Array[Vector3] = []
var fire_k := 0
var open := 0.0  # 0 closed .. 1 pieces pushed apart to show the core
var warn := 0.0
var cycle := 0
var warned := {}


func setup(g: Game) -> void:
	game = g
	center = Vector3(0, 0, game.field_top - 4.0)
	core = game.spawn_part(self, "lazaro_core", 1.5)
	core.intangible = true
	core.score = 0
	for k in 4:
		var e := game.spawn_part(self, "lazaro_piece", 1.35)
		e.score = 0
		e.rotation.y = -k * PI / 2.0
		pieces.append(e)
		pinch_from.append(Vector3.ZERO)
	_place_merged()


func _quad(k: int) -> Vector3:
	# centroid of piece k when the sphere is closed
	return Vector3(0.95, 0, 0.95).rotated(Vector3.UP, -k * PI / 2.0)


func _place_merged() -> void:
	for k in 4:
		pieces[k].position = center + _quad(k) * (1.0 + open * 0.55)
	core.position = center


func on_hit(e: Enemy, dmg: float) -> float:
	if defeated:
		return 0.0
	hp -= dmg if e == core else dmg * PIECE_MUL
	for q in pieces:
		q.flash = maxf(q.flash, 0.3 if e == core else 0.2)
	core.flash = 1.0 if e == core else core.flash
	if hp <= 0.0:
		_defeat()
	return 0.0


func on_part_killed(_e: Enemy) -> void:
	pass


func _defeat() -> void:
	disarm()
	state = "dying"
	st = 0.0
	game.add_score(SCORE, true)
	game.fx.popup(center + Vector3(0, 2, 0), str(SCORE), Color(1, 0.85, 0.4), true)


func gauge() -> Dictionary:
	if defeated:
		return {}
	return {"frac": hp / HP, "color": Hud.GOLD, "name": INFO["name"], "name_color": Color(1, 0.9, 0.6), "x": 0.25, "w": 0.5, "h": 7.0, "name_y": 70.0}


func force_defeat() -> void:
	if not defeated and not finished:
		hp = 0.0
		_defeat()


func debug_state() -> String:
	return "%s %.1fs  HP %d/%d  cycle %d" % [state, st, int(maxf(hp, 0.0)), int(HP), cycle]


func tick(dt: float) -> void:
	if finished:
		return
	st += dt
	life_t += dt
	warn = maxf(0.0, warn - dt)
	if life_t > LIFE and not defeated and state != "escape":
		state = "escape"
		st = 0.0
	match state:
		"enter":
			center.z = move_toward(center.z, game.field_top + 6.0, 5.0 * dt)
			open = 0.0
			if st > 2.6 - SPLIT_WARN:
				_warn_once("split", SPLIT_WARN, Game.Warn.MOVE, [core], 2.6)
			_place_merged()
			if st > 2.6:
				_begin_split()
		"split":
			var f := clampf(st / 1.3, 0.0, 1.0)
			f = 1.0 - (1.0 - f) * (1.0 - f)
			orbit_c = orbit_c.lerp(game.player.position, clampf(2.0 * dt, 0.0, 1.0))
			orbit_a += dt * 0.5
			for k in 4:
				var target := _orbit_pos(k, ORBIT_R)
				pieces[k].position = pinch_from[k].lerp(target, f)
			core.visible = false
			if st > 1.3:
				state = "orbit"
				st = 0.0
				fire_k = 0
		"orbit":
			orbit_c = orbit_c.lerp(game.player.position, clampf(0.8 * dt, 0.0, 1.0))
			orbit_a += dt * 0.6
			var r := lerpf(ORBIT_R, 6.3, clampf(st / 3.2, 0.0, 1.0))
			for k in 4:
				pieces[k].position = _orbit_pos(k, r)
				pieces[k].rotation.y += dt * 2.0
			if st > 0.6 + fire_k * 0.6 and fire_k < 4:
				var q := pieces[fire_k]
				if game.player.alive:
					game.bullets.fan(q.position, game.bullets.aim(q.position), 3, 18.0, 6.5, Bullets.SHELL, self)
				fire_k += 1
			if st > 3.2 - PINCH_WARN:
				_warn_once("pinch", PINCH_WARN, Game.Warn.MOVE, pieces)
			if st > 3.2:
				state = "pinch"
				st = 0.0
				center = orbit_c
				for k in 4:
					pinch_from[k] = pieces[k].position
				game.sfx.play("slam")
				# a closing ring shows where the jaws will meet
				game.fx.sprite(center + Vector3(0, 0.3, 0), Vector3.ZERO, 14.0, 2.5, PINCH_TIME, Color(1.0, 0.35, 0.3), 2.0)
		"pinch":
			var f := clampf(st / PINCH_TIME, 0.0, 1.0)
			f = f * f * (3.0 - 2.0 * f)
			for k in 4:
				pieces[k].position = pinch_from[k].lerp(center + _quad(k), f)
				pieces[k].rotation.y = lerp_angle(pieces[k].rotation.y, -k * PI / 2.0, clampf(10.0 * dt, 0.0, 1.0))
			if st > PINCH_TIME:
				for k in 4:
					pieces[k].rotation.y = -k * PI / 2.0
				state = "merged"
				st = 0.0
				open = 0.0
				game.shake(0.6)
				game.fx.shockwave(center, 6.0, Color(1.0, 0.5, 0.3))
				game.sfx.play("exp_m")
		"merged":
			open = clampf(st / 0.4, 0.0, 1.0) if st < 2.4 else clampf((2.8 - st) / 0.4, 0.0, 1.0)
			core.visible = true
			core.intangible = open < 0.5
			core.model.rotation.y += dt * 3.0
			_warn_once("ring", 0.45, Game.Warn.SHOT, [core])
			if st > 1.4 - Enemy.WINDUP_SHOT:
				_warn_once("fan", Enemy.WINDUP_SHOT, Game.Warn.SHOT, [core])
			if st > 0.45 and fire_k < 10:
				fire_k = 10
				game.bullets.ring(center, 10, 5.0, Bullets.ORB, self, randf() * TAU)
			if st > 1.4 and fire_k < 11:
				fire_k = 11
				game.bullets.fan(center, game.bullets.aim(center), 3, 12.0, 8.5, Bullets.ORB, self, Bullets.NEEDLE)
			_place_merged()
			if st > 2.8:
				state = "rise"
				st = 0.0
				core.intangible = true
		"rise":
			center = center.lerp(Vector3(clampf(game.player.position.x * 0.4, -6.0, 6.0), 0, game.field_top + 6.0), clampf(2.5 * dt, 0.0, 1.0))
			if st > 1.0 - SPLIT_WARN:
				_warn_once("split", SPLIT_WARN, Game.Warn.MOVE, [core], 2.6)
			_place_merged()
			if st > 1.0:
				_begin_split()
		"escape":
			core.intangible = true
			for q in pieces:
				q.position.z -= 14.0 * dt
			core.visible = false
			if st > 2.5:
				_finish()
		"dying":
			core.intangible = true
			if int(st * 10.0) != int((st - dt) * 10.0) and st < 1.6:
				var q := pieces[randi() % 4]
				game.fx.explode(q.position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)), 1.6, Vector3.ZERO, Models.VIOLET)
				game.sfx.play("exp_s")
			if st > 1.6:
				var conv := game.bullets.cancel_owner(self)
				for b in conv:
					game.items.spawn(b, Items.ENERGY, 1.0)
				game.big_blast(center, 0.7, Models.VIOLET)
				for q in pieces:
					game.fx.explode(q.position, 2.5, Vector3.ZERO, Models.GOLD)
				game.items.burst_energy(center, 40.0, 9.0)
				game.sfx.play("exp_l")
				game.shake(1.2)
				_finish()


## Telegraphs each big move or energy volley once per cycle.
func _warn_once(key: String, dur: float, kind: int, nodes: Array, radius := 0.0) -> void:
	var k := "%s%d" % [key, cycle]
	if warned.has(k):
		return
	warned[k] = true
	for q: Enemy in nodes:
		game.warn(q, dur, kind, radius if radius > 0.0 else q.radius, "player" if kind == Game.Warn.MOVE else null)
	if key == "split":
		# one reticle around the whole sphere, but every shell piece pulses
		for q in pieces:
			q.warn_t = dur
			q.warn_dur = dur
			q.warn_col = Game.WARN_COL[kind]


func _begin_split() -> void:
	cycle += 1
	state = "split"
	st = 0.0
	orbit_c = game.player.position
	orbit_a = randf() * TAU
	for k in 4:
		pinch_from[k] = pieces[k].position
	core.intangible = true


func _orbit_pos(k: int, r: float) -> Vector3:
	var a := orbit_a + k * PI / 2.0 + PI / 4.0
	return orbit_c + Vector3(cos(a), 0, sin(a)) * r


func _finish() -> void:
	finished = true
	for q in pieces:
		game.remove_enemy(q)
		q.queue_free()
	game.remove_enemy(core)
	core.queue_free()
	pieces.clear()
	game.remove_boss(self)
	queue_free()
