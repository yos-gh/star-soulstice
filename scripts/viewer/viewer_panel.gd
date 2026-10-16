class_name ViewerPanel
extends Control
## The viewer's side panel: categories, the item list, what is showing
## (live stats of the subject), the play state and the keys.

const W := 286.0
const ROWS := 15
const CYAN := Color(0.45, 0.9, 1.0)
const GOLD := Color(1.0, 0.82, 0.3)
const DIM := Color(1, 1, 1, 0.55)

var viewer: Viewer
var font: Font


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _text(p: Vector2, s: String, size: int, c: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string_outline(font, p, s, align, width, size, 5, Color(0, 0, 0, 0.8 * c.a))
	draw_string(font, p, s, align, width, size, c)


func _draw() -> void:
	var v := viewer
	if v.cats.is_empty():
		return
	var sz := get_viewport_rect().size
	draw_rect(Rect2(0, 0, W, sz.y), Color(0, 0, 0.02, 0.62))
	draw_line(Vector2(W, 0), Vector2(W, sz.y), Color(0.45, 0.9, 1.0, 0.25), 1.0)
	var x := 14.0
	var y := 26.0
	_text(Vector2(x, y), "VIEWER  閲覧モード", 18, Color(0.75, 0.9, 1.0))
	_text(Vector2(0, y), "%d / %d" % [v.ci + 1, v.cats.size()], 12, DIM, HORIZONTAL_ALIGNMENT_RIGHT, W - 14)
	# categories: the current one with its neighbours
	y += 26.0
	var n := v.cats.size()
	var prev: String = v.cats[posmod(v.ci - 1, n)]["name"]
	var next: String = v.cats[posmod(v.ci + 1, n)]["name"]
	_text(Vector2(x, y), "<  " + prev.to_lower(), 12, DIM)
	_text(Vector2(0, y), next.to_lower() + "  >", 12, DIM, HORIZONTAL_ALIGNMENT_RIGHT, W - 14)
	y += 24.0
	_text(Vector2(0, y), v.cats[v.ci]["name"], 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER, W)
	y += 18.0
	_text(Vector2(0, y), v.cats[v.ci].get("jp", ""), 12, Color(1.0, 0.9, 0.7, 0.8), HORIZONTAL_ALIGNMENT_CENTER, W)
	# items, scrolled around the selection
	y += 6.0
	var items := v.items()
	var cur: int = v.sel[v.ci]
	var first := clampi(cur - ROWS / 2, 0, maxi(0, items.size() - ROWS))
	for r in mini(ROWS, items.size()):
		var i := first + r
		var on := i == cur
		y += 19.0
		if on:
			draw_rect(Rect2(6, y - 14, W - 12, 18), Color(0.45, 0.9, 1.0, 0.18))
		var name: String = items[i]["name"]
		_text(Vector2(x, y), ("> " if on else "  ") + name, 13, Color(1, 1, 1) if on else Color(0.8, 0.85, 0.95, 0.75))
	if items.size() > ROWS:
		_text(Vector2(0, y + 16), "%d / %d" % [cur + 1, items.size()], 11, DIM, HORIZONTAL_ALIGNMENT_RIGHT, W - 14)
	# what is showing
	y = maxf(y + 32.0, 404.0)
	var e := v.entry
	for line in _wrap(String(e.get("desc", "")), 12, W - 26):
		_text(Vector2(x, y), line, 12, Color(0.8, 0.9, 1.0, 0.85))
		y += 16.0
	for line in _live():
		_text(Vector2(x, y), line, 12, Color(0.9, 1.0, 0.8, 0.9))
		y += 16.0
	# state
	y += 6.0
	var st := "停止中" if v.frozen else ("x%s" % str(Viewer.SPEEDS[v.speed_i]))
	_text(Vector2(x, y), st, 16, Color(1.0, 0.45, 0.45) if v.frozen else CYAN)
	_text(Vector2(x + 64, y), "%.2f s" % v.t, 13, DIM)
	var flags := []
	if v.fly:
		flags.append("操縦中")
	if v.bot_on:
		flags.append("自動操縦")
	if not v.fire_on:
		flags.append("敵の攻撃なし")
	if v.ground_on:
		flags.append("地形あり")
	if not v.scenery_on:
		flags.append("背景なし")
	_text(Vector2(0, y), " ".join(flags), 11, GOLD, HORIZONTAL_ALIGNMENT_RIGHT, W - 14)
	# keys
	var keys := [
		"←→ 分類　↑↓ 項目　Z 最初から",
		"ESC 停止　F 1コマ送り　1〜5 速さ",
		"ドラッグ 回り込み　ホイール 寄る",
		"右ドラッグ 平行移動　C カメラを戻す",
		"K 撃破　B 自動操縦　TAB 自分で操縦",
		"E 敵の攻撃　G 地形　V 背景　T 回転",
		"H パネルを隠す　Q タイトルへ",
	]
	if Controls.using_pad:
		keys = [
			"LB/RB 分類　十字キー 項目　A 最初から",
			"START 停止　X 1コマ送り　Y 自分で操縦",
			"右スティック 回り込み　LT/RT 寄る",
			"R3 カメラを戻す　BACK タイトルへ",
		]
	if v.fly:
		keys = ["操縦中：矢印 移動　Z ショット　X スピア", "TAB 一覧に戻る　ESC 停止　F 1コマ送り"]
	var ky := sz.y - 12.0 - (keys.size() - 1) * 15.0
	for k in keys:
		_text(Vector2(x, ky), k, 12, DIM)
		ky += 15.0
	if v.frozen and int(v.game.time * 2.0) % 2 == 0:
		_text(Vector2(W, 34), "停止中", 22, Color(1.0, 0.45, 0.45), HORIZONTAL_ALIGNMENT_CENTER, sz.x - W)


## Live readout of the subject.
func _live() -> Array:
	var v := viewer
	var g := v.game
	var e := v.entry
	var out := []
	match e.get("type", ""):
		"spawns", "ground":
			var alive := 0
			var first: Enemy = null
			for m in g.enemies:
				if m.dead or m.category == "part":
					continue
				if e["type"] == "spawns" and not v.members.has(m):
					continue
				alive += 1
				if first == null:
					first = m
			out.append("画面内 %d 機　%d 周目" % [alive, v.loops + 1])
			if first != null:
				out.append("%s  耐久 %s/%s  得点 %d" % [first.kind.to_upper(), _num(first.hp), _num(first.max_hp), first.score])
				out.append("エネルギー %s  半径 %.2f  経過 %.1f 秒" % [_num(first.energy_drop), first.radius, first.t])
			for m in v.members:
				if is_instance_valid(m) and m is BossBase:
					out.append((m as BossBase).debug_state())
		"boss":
			if v.boss != null and is_instance_valid(v.boss):
				out.append(v.boss.debug_state())
		"model":
			if e.has("aabb"):
				var s: Vector3 = (e["aabb"] as AABB).size
				out.append("大きさ %.2f x %.2f x %.2f" % [s.x, s.y, s.z])
		"section", "kind_section":
			if not g.terrain.islands.is_empty():
				var isl := g.terrain.islands[0]
				out.append("%d x %d マス　タイル %d" % [isl.w, isl.h, isl.alive_tiles])
		"area":
			out.append("区画 %d　タイル %d" % [g.terrain.islands.size(), g.terrain.tiles_alive()])
		"bullets", "fx":
			out.append("敵弾 %d　アイテム %d" % [g.bullets.n, g.items.n])
	return out


func _num(f: float) -> String:
	return str(int(f)) if is_equal_approx(f, round(f)) else "%.1f" % f


## Breaks s into lines no wider than max_w pixels (character by character,
## so Japanese without spaces wraps too).
func _wrap(s: String, size: int, max_w: float) -> Array:
	var out := []
	var line := ""
	for i in s.length():
		var c := s[i]
		if font.get_string_size(line + c, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w and line != "":
			out.append(line)
			line = "" if c == " " else c
		else:
			line += c
	if line != "":
		out.append(line)
	return out
