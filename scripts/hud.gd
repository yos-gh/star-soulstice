class_name Hud
extends Control
## Screen overlay: score, lives, energy (homing stock), Concentration, Spear
## readiness, form, boss gauge, messages, title, pause and results.

const CYAN := Color(0.45, 0.9, 1.0)
const GOLD := Color(1.0, 0.82, 0.3)
const GREEN := Color(0.45, 1.0, 0.55)
const PINK := Color(1.0, 0.4, 0.7)
const DIM := Color(1, 1, 1, 0.55)

var game: Game
var font: Font


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font


func _text(p: Vector2, s: String, size: int, c: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string_outline(font, p, s, align, width, size, 6, Color(0, 0, 0, 0.8 * c.a))
	draw_string(font, p, s, align, width, size, c)


func _center(y: float, s: String, size: int, c: Color) -> void:
	_text(Vector2(0, y), s, size, c, HORIZONTAL_ALIGNMENT_CENTER, size_v().x)


func size_v() -> Vector2:
	return get_viewport_rect().size


func _draw() -> void:
	var g := game
	var sz := size_v()
	if g.state == Game.State.TITLE:
		_title(sz)
		_notice(sz)
		return
	_warnings()
	# top bar
	draw_rect(Rect2(0, 0, sz.x, 40), Color(0, 0, 0, 0.35))
	_text(Vector2(16, 28), "SCORE", 14, DIM)
	_text(Vector2(74, 29), "%08d" % g.score, 22, Color(1, 1, 1))
	_text(Vector2(0, 28), "HI %08d" % maxi(g.hi_score, g.score), 16, Color(1, 0.85, 0.6), HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	for i in maxi(0, g.lives - (1 if g.player.alive else 0)):
		_ship_icon(Vector2(sz.x - 24 - i * 22, 20))
	# bottom bar
	var by := sz.y - 46.0
	draw_rect(Rect2(0, by - 6, sz.x, 52), Color(0, 0, 0, 0.35))
	_energy(Vector2(16, by), g.player)
	_conc(Vector2(sz.x * 0.5 - 130, by), g.player)
	_spear(Vector2(sz.x - 250, by), g.player)
	if g.stage != null:
		var label := "WAVE %d/%d" % [clampi(g.stage.wi + 1, 0, g.stage.wave_count()), g.stage.wave_count()]
		if g.stage.phase != "waves":
			label = "BOSS"
		_text(Vector2(0, 58), label, 13, DIM, HORIZONTAL_ALIGNMENT_RIGHT, sz.x - 14)
		_text(Vector2(0, 74), "%d:%04.1f" % [int(g.stage_t / 60.0), fmod(g.stage_t, 60.0)], 13, DIM, HORIZONTAL_ALIGNMENT_RIGHT, sz.x - 14)
	# boss / mid-boss gauges
	if g.boss != null and g.boss.phase >= 1 and g.boss.phase < 3:
		var e := g.boss.eye
		_gauge(Rect2(sz.x * 0.2, 48, sz.x * 0.6, 8), e.hp / e.max_hp, PINK if not e.armored else Color(0.6, 0.55, 0.65))
		_text(Vector2(sz.x * 0.2, 72), "STAR CORTEX", 13, Color(1, 0.75, 0.85))
	elif g.lazaro != null and not g.lazaro.defeated:
		_gauge(Rect2(sz.x * 0.25, 48, sz.x * 0.5, 7), g.lazaro.hp / Lazaro.HP, GOLD)
		_text(Vector2(sz.x * 0.25, 70), "LAZARO", 13, Color(1, 0.9, 0.6))
	_messages(sz)
	if g.state == Game.State.CLEAR and g.state_t > 3.0:
		_results(sz)
	if g.paused:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.5))
		_center(sz.y * 0.45, "PAUSE", 40, Color(1, 1, 1))
		_center(sz.y * 0.45 + 40, "%s : RESUME    %s : TITLE" % [Controls.label("pause"), Controls.label("back")], 16, DIM)
	if g.flash_a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, g.flash_a * 0.5))
	_notice(sz)


func _gauge(r: Rect2, f: float, c: Color) -> void:
	draw_rect(r.grow(2), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(f, 0.0, 1.0), r.size.y)), c)


func _ship_icon(p: Vector2) -> void:
	var pts := PackedVector2Array([p + Vector2(0, -9), p + Vector2(8, 7), p + Vector2(0, 3), p + Vector2(-8, 7)])
	draw_colored_polygon(pts, Color(0.75, 0.85, 1.0))
	draw_circle(p + Vector2(0, -2), 2.0, CYAN)


## Energy: 8 cells, one homing laser each.
func _energy(p: Vector2, pl: Player) -> void:
	_text(p + Vector2(0, 12), "ENERGY", 13, GREEN)
	var cells := Player.MAX_HOMING
	for i in cells:
		var r := Rect2(p.x + i * 22, p.y + 18, 18, 14)
		draw_rect(r, Color(0.05, 0.15, 0.08, 0.9))
		var f := clampf((pl.energy - i * Player.ENERGY_PER_HOMING) / Player.ENERGY_PER_HOMING, 0.0, 1.0)
		if f > 0.0:
			var full := f >= 1.0
			draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), GREEN if full else Color(0.25, 0.55, 0.3))
		draw_rect(r, Color(0.5, 1.0, 0.6, 0.6), false, 1.0)
	_text(p + Vector2(84, 12), "HOMING x%d" % pl.homing_ready(), 13, Color(0.8, 1, 0.85))


func _conc(p: Vector2, pl: Player) -> void:
	var m := pl.shot_mul()
	var f := pl.conc
	var c := CYAN.lerp(GOLD, f)
	_text(p + Vector2(0, 12), "CONCENTRATION", 13, c)
	var r := Rect2(p.x, p.y + 18, 200, 14)
	draw_rect(r, Color(0.05, 0.08, 0.15, 0.9))
	draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), c)
	for k in range(1, 3):
		var x := r.position.x + r.size.x * k / 3.0
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(0, 0, 0, 0.6), 2.0)
	draw_rect(r, Color(c.r, c.g, c.b, 0.6), false, 1.0)
	_text(Vector2(r.end.x + 8, r.end.y), "x%.1f" % m, 18 if f < 0.99 else 20, c)


func _spear(p: Vector2, pl: Player) -> void:
	var ready := pl.spear_cd <= 0.0
	var c := CYAN if ready else Color(0.4, 0.55, 0.7)
	_text(p + Vector2(0, 12), "SPEAR", 13, c)
	var r := Rect2(p.x, p.y + 18, 90, 14)
	draw_rect(r, Color(0.05, 0.08, 0.15, 0.9))
	var f := 1.0 - pl.spear_cd / Player.SPEAR_CD
	draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), c)
	draw_rect(r, Color(c.r, c.g, c.b, 0.6), false, 1.0)
	if ready and int(game.time * 4.0) % 2 == 0:
		_text(Vector2(r.position.x + 6, r.end.y - 1), "READY", 12, Color(1, 1, 1))
	var form := "FORM %s" % ["I", "II", "III"][pl.level]
	_text(Vector2(p.x + 104, p.y + 12), form, 13, Color(0.8, 0.85, 1.0))
	if pl.shield:
		_text(Vector2(p.x + 104, p.y + 31), "SHIELD", 13, Color(0.5, 0.7, 1.0))


func _messages(sz: Vector2) -> void:
	var g := game
	if g.msg_t <= 0.0:
		return
	var a := clampf(g.msg_t * 2.0, 0.0, 1.0)
	if g.msg_warning:
		var blink := 0.5 + 0.5 * sin(g.time * 10.0)
		draw_rect(Rect2(0, sz.y * 0.36, sz.x, 96), Color(0.6, 0.0, 0.08, 0.35 * a))
		_center(sz.y * 0.36 + 60, g.msg, 52, Color(1.0, 0.3 + 0.3 * blink, 0.35, a))
		_center(sz.y * 0.36 + 120, g.msg_sub, 16, Color(1, 0.8, 0.85, a))
	else:
		_center(sz.y * 0.4, g.msg, 40, Color(1, 1, 1, a))
		if g.msg_sub != "":
			_center(sz.y * 0.4 + 32, g.msg_sub, 18, Color(0.8, 0.9, 1.0, a))


func _results(sz: Vector2) -> void:
	var g := game
	var y := sz.y * 0.5
	draw_rect(Rect2(sz.x * 0.25, y - 30, sz.x * 0.5, 170), Color(0, 0, 0, 0.55))
	var rows := [
		["DESTRUCTION", "%d" % g.destroy_score],
		["ITEMS", "%d" % g.item_score],
		["TIME", "%d:%04.1f" % [int(g.clear_t / 60.0), fmod(g.clear_t, 60.0)]],
		["TIME BONUS", "%d" % g.bonus],
	]
	for i in rows.size():
		var r: Array = rows[i]
		_text(Vector2(sz.x * 0.29, y + i * 28), r[0], 18, Color(0.8, 0.9, 1.0))
		_text(Vector2(0, y + i * 28), r[1], 18, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_RIGHT, sz.x * 0.71)
	_text(Vector2(sz.x * 0.29, y + 4 * 28 + 8), "TILES %d   KILLS %d   MISS %d" % [g.tiles_broken, g.kills, g.deaths], 14, DIM)
	if g.state_t > 9.0:
		_center(y + 175, "PRESS %s" % Controls.label("confirm"), 16, Color(1, 1, 1, 0.5 + 0.5 * sin(g.time * 5.0)))


func _title(sz: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0.02, 0.35))
	_center(sz.y * 0.3, "STAR SOULSTICE", 64, Color(0.75, 0.9, 1.0))
	_center(sz.y * 0.3 + 34, "STAGE 1 PROTOTYPE", 18, Color(1.0, 0.75, 0.85))
	var y := sz.y * 0.52
	var lines := [
		["MOVE", Controls.label("move")],
		["SHOT", Controls.label("shot") + "   tap fast = power x4 / hold = auto"],
		["SPEAR + HOMING", Controls.label("side") + "   erases nearby bullets, 4 s cooldown"],
		["PAUSE", Controls.label("pause")],
	]
	for i in lines.size():
		var l: Array = lines[i]
		_text(Vector2(sz.x * 0.2, y + i * 26), l[0], 16, CYAN)
		_text(Vector2(sz.x * 0.42, y + i * 26), l[1], 16, Color(1, 1, 1, 0.85))
	_center(sz.y * 0.85, "PRESS %s TO START" % Controls.label("confirm"), 22, Color(1, 1, 1, 0.5 + 0.5 * sin(game.time * 4.0)))
	if game.hi_score > 0:
		_center(sz.y * 0.92, "HI %08d" % game.hi_score, 16, Color(1, 0.85, 0.6))


func _notice(sz: Vector2) -> void:
	if Controls.notice_t > 0.0:
		_text(Vector2(0, sz.y - 60), Controls.notice, 14, Color(1, 1, 1, clampf(Controls.notice_t, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, sz.x)


## Telegraphs (see Game.warn): 「 」 brackets that close in on the attacker
## and blink just before the attack, plus a dashed line for charges.
func _warnings() -> void:
	var g := game
	for w: Dictionary in g.warnings:
		var nd = w["node"]
		if not is_instance_valid(nd):
			continue
		var at: Vector3 = (nd as Enemy).hit_pos if nd is Enemy else (nd as Node3D).global_position
		var sp := g.camera.unproject_position(at)
		var rpx := g.camera.unproject_position(at + Vector3(float(w["r"]), 0, 0)).x - sp.x
		var t: float = w["t"]
		var f := 1.0 - t / maxf(float(w["dur"]), 0.01)
		var c: Color = Game.WARN_COL[w["kind"]]
		if t < 0.16 and int(t * 30.0) % 2 == 0:
			c = Color(1, 1, 1)
		var s := rpx * lerpf(2.3, 1.2, f) + 8.0
		var l := maxf(8.0, s * 0.55)
		var tl := sp + Vector2(-s, -s)
		var br := sp + Vector2(s, s)
		var bracket_tl := PackedVector2Array([tl + Vector2(0, l), tl, tl + Vector2(l, 0)])
		var bracket_br := PackedVector2Array([br - Vector2(0, l), br, br - Vector2(l, 0)])
		for pts in [bracket_tl, bracket_br]:
			draw_polyline(pts, Color(0, 0, 0, 0.6), 5.0)
			draw_polyline(pts, c, 2.5)
		# charge path
		var to = w["to"]
		var target := Vector2.INF
		if to is String and to == "player" and g.player.alive:
			target = g.camera.unproject_position(g.player.position)
		elif to is Vector3:
			target = g.camera.unproject_position(to)
		if target != Vector2.INF:
			var d := target - sp
			var len := minf(d.length(), 420.0)
			if len > s:
				var dir := d / d.length()
				var k := s
				var phase := fmod(g.time * 60.0, 18.0)
				while k + 10.0 < len:
					var a := sp + dir * (k + phase)
					var b := sp + dir * minf(k + phase + 10.0, len)
					draw_line(a, b, Color(c.r, c.g, c.b, 0.75), 2.0)
					k += 18.0
