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
	if g.state == Game.State.VIEWER:
		# the viewer draws its own panel; keep what the subject shows
		_boss_gauge(sz, ViewerPanel.W if g.viewer.panel.visible else 0.0)
		_messages(sz)
		if g.flash_a > 0.0:
			draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, g.flash_a * 0.5))
		_notice(sz)
		return
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
	_boss_gauge(sz)
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


## The gauge of the last boss on the field that shows one (the stage boss
## comes after the mid-boss).
func _boss_gauge(sz: Vector2, left := 0.0) -> void:
	for i in range(game.bosses.size() - 1, -1, -1):
		var b := game.bosses[i]
		if not is_instance_valid(b):
			continue
		var gd := b.gauge()
		if gd.is_empty():
			continue
		var x: float = gd["x"]
		var span := sz.x - left
		_gauge(Rect2(left + span * x, 48, span * float(gd["w"]), gd["h"]), gd["frac"], gd["color"])
		_text(Vector2(left + span * x, gd["name_y"]), gd["name"], 13, gd["name_color"])
		return


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
	# a mark at each whole multiplier (x2 ... x7)
	var steps := int(Player.CONC_MAX_MUL - 1.0)
	for k in range(1, steps):
		var x := r.position.x + r.size.x * k / float(steps)
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
	_center(sz.y * 0.3 + 34, "PROTOTYPE  %d STAGES" % Stages.count(), 18, Color(1.0, 0.75, 0.85))
	var y := sz.y * 0.52
	var lines := [
		["MOVE", Controls.label("move")],
		["SHOT", Controls.label("shot") + "   tap fast = power x%d / hold = auto" % int(Player.CONC_MAX_MUL)],
		["SPEAR + HOMING", Controls.label("side") + "   erases nearby bullets, 4 s cooldown"],
		["PAUSE", Controls.label("pause")],
	]
	for i in lines.size():
		var l: Array = lines[i]
		_text(Vector2(sz.x * 0.2, y + i * 26), l[0], 16, CYAN)
		_text(Vector2(sz.x * 0.42, y + i * 26), l[1], 16, Color(1, 1, 1, 0.85))
	var menu := ["GAME START", "VIEWER"]
	var many := Stages.count() > 1
	if many:
		menu[0] = "GAME START   <  STAGE %d  >" % game.start_stage
	for i in menu.size():
		var sel := game.title_sel == i
		var c := Color(1, 1, 1, 0.8 + 0.2 * sin(game.time * 4.0)) if sel else Color(0.75, 0.85, 1.0, 0.45)
		_center(sz.y * 0.79 + i * 34, ("-  %s  -" % menu[i]) if sel else menu[i], 22 if sel else 18, c)
	var keys := "UP / DOWN : SELECT     " + ("LEFT / RIGHT : STAGE     " if many else "") + "%s : DECIDE" % Controls.label("confirm")
	_center(sz.y * 0.79 + 64, keys, 13, DIM)
	if game.hi_score > 0:
		_center(sz.y * 0.94, "HI %08d" % game.hi_score, 16, Color(1, 0.85, 0.6))


func _notice(sz: Vector2) -> void:
	if Controls.notice_t > 0.0:
		_text(Vector2(0, sz.y - 60), Controls.notice, 14, Color(1, 1, 1, clampf(Controls.notice_t, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, sz.x)


## Telegraphs (see Game.warn), all in white: a lock-on reticle of four
## corner brackets that spins in from 45 degrees and closes on the attacker,
## inner ticks in the second half, a fuse bar of four cells counting down,
## and a blink just before the attack. Charges and big moves get doubled
## corners and chevrons streaming along the path.
func _warnings() -> void:
	var g := game
	for w: Dictionary in g.warnings:
		var nd = w["node"]
		if not is_instance_valid(nd):
			continue
		# (a "lane" is for the autopilot only, unless it is to be shown)
		if w["to"] is Dictionary and (w["to"] as Dictionary).has("lane") and not w["to"].get("show", false):
			continue
		var at: Vector3 = (nd as Enemy).hit_pos if nd is Enemy else (nd as Node3D).global_position
		var sp := g.camera.unproject_position(at)
		var rpx := g.camera.unproject_position(at + Vector3(float(w["r"]), 0, 0)).x - sp.x
		# an attacker still off screen (from behind or a side): the lock-on
		# waits on that edge, fuse bar included
		var vs := size_v()
		if not Rect2(Vector2.ZERO, vs).has_point(sp):
			sp = Vector2(clampf(sp.x, 56.0, vs.x - 56.0), clampf(sp.y, 56.0, vs.y - 76.0))
		var t: float = w["t"]
		var f := 1.0 - t / maxf(float(w["dur"]), 0.01)
		var e := 1.0 - pow(1.0 - f, 3.0)
		var heavy: bool = w["kind"] == Game.Warn.MOVE
		var last := t < 0.16
		if last and int(t * 40.0) % 2 == 1:
			continue
		var c := Color(1, 1, 1)
		var s := rpx * lerpf(2.4, 1.25, e) + 9.0
		var ang := lerpf(PI / 4.0, 0.0, e)
		var l := maxf(7.0, s * 0.45)
		var wdt := 3.0 if last else 2.0
		for k in 4:
			var sx := 1.0 if k % 2 == 0 else -1.0
			var sy := 1.0 if k < 2 else -1.0
			for inset: float in ([0.0, 5.0] if heavy else [0.0]):
				var corner := Vector2(sx, sy) * (s - inset)
				var pts := PackedVector2Array([
					sp + (corner - Vector2(sx * l, 0)).rotated(ang),
					sp + corner.rotated(ang),
					sp + (corner - Vector2(0, sy * l)).rotated(ang),
				])
				draw_polyline(pts, Color(0, 0, 0, 0.55), wdt + 2.5)
				draw_polyline(pts, c, wdt)
		if f > 0.5:
			var tick := 6.0 * (f - 0.5) * 2.0
			for dir: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				var a := sp + (dir * s).rotated(ang)
				var b := sp + (dir * (s - tick)).rotated(ang)
				draw_line(a, b, c, 2.0)
		# fuse: four cells under the reticle
		var cells := ceili((1.0 - f) * 4.0)
		var cw := maxf(4.0, s * 0.32)
		var y := sp.y + s + 7.0
		for k in 4:
			var r := Rect2(sp.x - cw * 2.0 - 3.0 + k * (cw + 2.0), y, cw, 3.0)
			draw_rect(r.grow(1.0), Color(0, 0, 0, 0.5))
			if k < cells:
				draw_rect(r, c)
		# charge path: chevrons streaming toward the target
		var to = w["to"]
		var target := Vector2.INF
		if to is String and to == "player" and g.player.alive:
			target = g.camera.unproject_position(g.player.position)
		elif to is Vector3:
			target = g.camera.unproject_position(to)
		elif to is PackedVector3Array:
			_path_chevrons(to as PackedVector3Array)
		elif to is Dictionary and (to as Dictionary).has("r"):
			_impact_ring(at, float(to["r"]), f)
		elif to is Dictionary and (to as Dictionary).has("lane"):
			_charge_lane(to["lane"], float(to["hw"]), f)
		# (a "laser" path: its attacker draws the sight itself, TEMPEST)
		if target != Vector2.INF:
			var d := target - sp
			var len := minf(d.length(), 420.0)
			if len > s + 10.0:
				var dir := d / d.length()
				var side := Vector2(-dir.y, dir.x)
				var k := s + 6.0 + fmod(g.time * 90.0, 22.0)
				while k < len:
					var tip := sp + dir * k
					var a := clampf(1.0 - k / len, 0.25, 0.9)
					var col := Color(1, 1, 1, a)
					var pts := PackedVector2Array([tip - dir * 6.0 + side * 5.0, tip, tip - dir * 6.0 - side * 5.0])
					draw_polyline(pts, Color(0, 0, 0, a * 0.5), 4.0)
					draw_polyline(pts, col, 2.0)
					k += 22.0


## Where something lands (a lobbed shell): the circle it will blast,
## dashed and turning, and a second ring closing in on it as the fuse runs
## down (`f` 0 to 1).
func _impact_ring(at: Vector3, r: float, f: float) -> void:
	var g := game
	var pts := PackedVector2Array()
	var inner := PackedVector2Array()
	var n := 28
	var spin := g.time * 1.5
	var ri := r * lerpf(2.2, 1.0, 1.0 - pow(1.0 - f, 2.0))
	for k in n + 1:
		var a := TAU * k / n + spin
		pts.append(g.camera.unproject_position(at + Vector3(cos(a), 0, sin(a)) * r))
		inner.append(g.camera.unproject_position(at + Vector3(cos(a), 0, sin(a)) * ri))
	for k in n:
		if k % 2 == 0:
			var seg := PackedVector2Array([pts[k], pts[k + 1]])
			draw_polyline(seg, Color(0, 0, 0, 0.55), 4.5)
			draw_polyline(seg, Color(1, 1, 1, 0.9), 2.0)
	draw_polyline(inner, Color(1, 1, 1, 0.35 + 0.4 * f), 1.5)


## Something wide about to charge down a corridor (BEHEMOTH's dozer
## blade): the corridor on the plane from `lane[0]` to `lane[1]`, `hw`
## either side, edged, filling from where it starts toward its end as the
## fuse runs (`f`), with rows of wide chevrons streaming down it and a
## heavy line across where the charge stops.
func _charge_lane(lane: PackedVector3Array, hw: float, f: float) -> void:
	var g := game
	var a := lane[0]
	var b := lane[1]
	var h := b - a
	h.y = 0.0
	var l := h.length()
	if l < 0.1:
		return
	h /= l
	var n := Vector3(-h.z, 0, h.x)
	var pulse := 0.5 + 0.5 * sin(g.time * 14.0)
	var quad := func(z0: float, z1: float) -> PackedVector2Array:
		return PackedVector2Array([
			g.camera.unproject_position(a + h * z0 - n * hw), g.camera.unproject_position(a + h * z0 + n * hw),
			g.camera.unproject_position(a + h * z1 + n * hw), g.camera.unproject_position(a + h * z1 - n * hw)])
	draw_colored_polygon(quad.call(0.0, l), Color(1, 1, 1, 0.07 + 0.05 * pulse))
	if f > 0.03:
		draw_colored_polygon(quad.call(0.0, l * (1.0 - pow(1.0 - f, 2.0))), Color(1, 1, 1, 0.12))
	# the edges, and the stop line with ticks back up the edges
	for s: float in [-1.0, 1.0]:
		var e0 := g.camera.unproject_position(a + n * hw * s)
		var e1 := g.camera.unproject_position(b + n * hw * s)
		draw_line(e0, e1, Color(0, 0, 0, 0.55), 5.5)
		draw_line(e0, e1, Color(1, 1, 1, 0.9), 3.0)
	var stop := PackedVector2Array([
		g.camera.unproject_position(b - n * hw - h * 1.2), g.camera.unproject_position(b - n * hw),
		g.camera.unproject_position(b + n * hw), g.camera.unproject_position(b + n * hw - h * 1.2)])
	draw_polyline(stop, Color(0, 0, 0, 0.55), 6.0)
	draw_polyline(stop, Color(1, 1, 1, 0.95), 3.5)
	# wide chevrons streaming down it
	var gap := 3.2
	var k := fmod(g.time * 9.0, gap)
	while k < l - 0.6:
		var p := a + h * k
		var fade := clampf(minf(k, l - k) / 2.0, 0.0, 1.0) * 0.8
		var v := PackedVector2Array([
			g.camera.unproject_position(p - n * hw * 0.82),
			g.camera.unproject_position(p + h * 1.6),
			g.camera.unproject_position(p + n * hw * 0.82)])
		draw_polyline(v, Color(0, 0, 0, fade * 0.5), 6.0)
		draw_polyline(v, Color(1, 1, 1, fade), 3.0)
		k += gap


## A big move along a path of points on the plane (a boom's sweep):
## chevrons streaming along the whole path.
func _path_chevrons(path: PackedVector3Array) -> void:
	var g := game
	var pts := PackedVector2Array()
	for q in path:
		pts.append(g.camera.unproject_position(q))
	var total := 0.0
	for k in pts.size() - 1:
		total += pts[k].distance_to(pts[k + 1])
	var k := fmod(g.time * 90.0, 22.0)
	var seg := 0
	var seg_start := 0.0
	while k < total and seg < pts.size() - 1:
		var sl := pts[seg].distance_to(pts[seg + 1])
		if k > seg_start + sl:
			seg_start += sl
			seg += 1
			continue
		var dir := (pts[seg + 1] - pts[seg]) / maxf(sl, 0.001)
		var side := Vector2(-dir.y, dir.x)
		var tip := pts[seg] + dir * (k - seg_start)
		var a := clampf(1.0 - k / total, 0.3, 0.9)
		var tri := PackedVector2Array([tip - dir * 6.0 + side * 5.0, tip, tip - dir * 6.0 - side * 5.0])
		draw_polyline(tri, Color(0, 0, 0, a * 0.5), 4.0)
		draw_polyline(tri, Color(1, 1, 1, a), 2.0)
		k += 22.0
