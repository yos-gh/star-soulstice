class_name ViewerCatalog
extends RefCounted
## Builds the viewer's categories from the registries, so whatever is added
## to Stages, EnemyKinds, Bosses, IslandGen.KINDS or Models shows up here
## without touching the viewer. Each item is a Dictionary:
##   name    the line in the list
##   type    what Viewer does with it (see Viewer._begin)
##   desc    one line under the list (optional)
##   stage   the StageDef whose ground and scenery it uses (optional)
##   scroll  scroll speed (default Game.SCROLL)
##   player  a still ship stands in as the target (default per type)
##   cam     {target, dist, pitch} starting camera (default: the play camera)
## and the fields of its type.

const MEDIUM_CATS := ["medium", "carrier", "hazard", "ground", "barrier"]


static func build(g: Game) -> Array:
	var f := Formations.new(g)
	var stages: Array[StageDef] = []
	for n in Stages.count():
		var d := Stages.create(n + 1)
		d.build_waves(f)
		stages.append(d)
	return [
		{"name": "SHIP", "jp": "自機", "items": _ship(f, stages[0])},
		{"name": "SMALL", "jp": "小型機と編隊", "items": _enemies(f, ["small"], stages)},
		{"name": "MEDIUM", "jp": "中型機・コンテナ・小惑星・砲台・隔壁", "items": _enemies(f, MEDIUM_CATS, stages)},
		{"name": "BOSS", "jp": "中ボス・ボス", "items": _bosses(stages)},
		{"name": "WAVES", "jp": "ステージのウェーブ（地形・砲台つき）", "items": _waves(stages)},
		{"name": "TERRAIN", "jp": "地形・区画", "items": _terrain(stages)},
		{"name": "SCENERY", "jp": "背景", "items": _scenery(stages)},
		{"name": "FX", "jp": "エフェクト", "items": _fx(stages[0])},
		{"name": "BULLETS", "jp": "敵弾", "items": _bullets(stages[0])},
		{"name": "ITEMS", "jp": "アイテム", "items": _items(stages[0])},
		{"name": "MODELS", "jp": "全モデル（回転台）", "items": _models(stages[0])},
	]


## Spawn list from a demo [label, method, args, method, args, ...].
static func _demo_spawns(f: Formations, demo: Array) -> Array:
	var out := []
	var k := 1
	while k + 1 < demo.size():
		out += f.callv(demo[k], demo[k + 1])
		k += 2
	return out


static func _ship(f: Formations, d: StageDef) -> Array:
	var out := []
	var forms := ["I", "II", "III"]
	for k in 3:
		out.append({"name": "FORM %s" % forms[k], "type": "ship", "form": k, "stage": d, "scroll": Game.SCROLL, "spin": true,
			"desc": "ship%d：形態 %s（同じ部品の組み替え）" % [k, forms[k]],
			"cam": {"target": Vector3(0, 0.3, 2.0), "dist": 7.0, "pitch": 55.0}})
	out.append({"name": "FORMS SIDE BY SIDE", "type": "model", "stage": d, "scroll": 0.0, "spin": false,
		"parts": [["ship0", Vector3(-9, 0, 0), 0.0, 3.0], ["ship1", Vector3(0, 0, 0), 0.0, 3.0], ["ship2", Vector3(9, 0, 0), 0.0, 3.0]],
		"desc": "3 形態を 3 倍に拡大して並べたもの", "cam": {"target": Vector3.ZERO, "dist": 40.0, "pitch": 66.0}})
	var targets: Array = f.swirls(0.0, -1, 5, 0.3) + f.swirls(0.8, 1, 5, 0.3) + f.vform(2.4, 1)
	for k in 3:
		out.append({"name": "WEAPONS FORM %s" % forms[k], "type": "spawns", "spawns": targets, "pilot": "weapons", "form": k, "stage": d,
			"desc": "連打で集中ゲージを溜め、4.2 秒ごとにスピアとホーミング 8 発"})
	return out


## The first stage that uses `kind` (an enemy kind or a boss): its subject
## is shown over that stage's ground and scenery. Stage 1 if none does.
static func _home(kind: String, stages: Array[StageDef]) -> StageDef:
	# a kind no wave lists (the drifting giant rocks) may name its stage
	var home := int(EnemyKinds.info(kind).get("stage", 0))
	if home > 0 and home <= stages.size():
		return stages[home - 1]
	for d in stages:
		if d.boss == kind:
			return d
		for w: Dictionary in d.waves:
			for s: Array in w["spawns"]:
				if s[1] == kind:
					return d
	return stages[0]


static func _enemies(f: Formations, cats: Array, stages: Array[StageDef]) -> Array:
	var out := []
	for kind: String in EnemyKinds.KINDS:
		var info := EnemyKinds.info(kind)
		if not cats.has(info.get("category", "")):
			continue
		var d := _home(kind, stages)
		var demos: Array = info.get("demos", [["ONE", "one", [0.0, kind, 0.0]]])
		for demo: Array in demos:
			var it := {"name": "%s  %s" % [info.get("name", kind), demo[0]], "kind": kind, "stage": d, "desc": info.get("desc", "")}
			# (the scenery it is met in, if it says)
			if info.has("area"):
				it["area"] = info["area"]
			if demo[1] == "ground":
				it["type"] = "ground"
				it["scroll"] = 0.0
			else:
				it["type"] = "spawns"
				it["spawns"] = _demo_spawns(f, demo)
			out.append(it)
	return out


static func _bosses(stages: Array[StageDef]) -> Array:
	var out := []
	for kind: String in Bosses.KINDS:
		var info := Bosses.info(kind)
		var d := _home(kind, stages)
		# the area it is fought over sets the scenery (a tunnel's style)
		var area := d.boss_area if d.boss == kind else d.first_area
		for w: Dictionary in d.waves:
			for s: Array in w["spawns"]:
				if s[1] == kind:
					area = w["area"]
		for demo: Array in info.get("demos", [["FULL", ""]]):
			out.append({"name": "%s  %s" % [info.get("name", kind), demo[0]], "type": "boss", "kind": kind, "skip": demo[1], "stage": d, "area": area,
				"scroll": d.boss_scroll if d.boss == kind else d.scroll,
				"desc": "%s：%s" % [{"mid": "中ボス", "boss": "ボス"}.get(info.get("role", ""), ""), info.get("desc", "")]})
	return out


## Every wave of every stage over its own area, then the stage's boss.
static func _waves(stages: Array[StageDef]) -> Array:
	var out := []
	for d in stages:
		for i in d.waves.size():
			var w: Dictionary = d.waves[i]
			var kinds := {}
			for s: Array in w["spawns"]:
				kinds[s[1]] = true
			out.append({"name": "S%d W%02d  %s" % [d.number, i + 1, String(w["area"]).to_upper()], "type": "spawns", "spawns": w["spawns"],
				"stage": d, "area": w["area"], "terrain": true, "desc": "%s（制限 %.0f 秒）" % [", ".join(kinds.keys()), w["timeout"]]})
		if d.boss != "":
			out.append({"name": "S%d BOSS  %s" % [d.number, Bosses.title(d.boss)], "type": "boss", "kind": d.boss, "skip": "", "stage": d,
				"area": d.boss_area, "terrain": true, "scroll": d.boss_scroll, "desc": "ステージのボス（ボス戦の地形つき）"})
	return out


static func _terrain(stages: Array[StageDef]) -> Array:
	var out := []
	for d in stages:
		for a: String in d.areas:
			var lab := d.area_label(a)
			out.append({"name": "S%d AREA  %s" % [d.number, a.to_upper()], "type": "area", "stage": d, "area": a,
				"desc": ("%s %s: " % [lab[0], lab[1]] if not lab.is_empty() else "") + "本編どおりに流れる区画（砲台つき）"})
	for d in stages:
		for a: String in d.areas:
			var secs: Array = d.areas[a].get("sections", [])
			for i in secs.size():
				var s: Array = secs[i]
				out.append({"name": "S%d %s #%d  %s %dx%d" % [d.number, a.to_upper(), i + 1, String(s[0]).to_upper(), s[1], s[2]], "type": "section",
					"stage": d, "area": a, "index": i, "scroll": 0.0, "desc": "区画 1 つを静止で。K でタイルを全部壊す"})
	for i in IslandGen.KINDS.size():
		var k: String = IslandGen.KINDS[i]
		out.append({"name": "KIND  %s 12x6" % k.to_upper(), "type": "kind_section", "kind": k, "seed": 500 + i * 17, "stage": stages[0], "scroll": 0.0,
			"desc": "IslandGen の種類を標準の大きさで（砲台の場所 2 つ）。K でタイルを全部壊す"})
	return out


static func _scenery(stages: Array[StageDef]) -> Array:
	var out := []
	for d in stages:
		var tunnel: Dictionary = d.backdrop.get("tunnel", {})
		var sky: Dictionary = d.backdrop.get("sky", {})
		if not sky.is_empty():
			# diving into a planet: each area's stretch of the descent (it
			# goes on coming down as in play), then the way into the base
			var from: Dictionary = sky.get("from", {})
			for a: String in from:
				out.append({"name": "S%d SKY  %s" % [d.number, a.to_upper()], "type": "backdrop", "stage": d, "area": a, "scroll": d.scroll, "loop": 30.0,
					"desc": "大気圏の降下（高さ %.2f から %.2f へ）：空・雲海・雲の峰（地形なし）" % [float(from[a]), float((sky.get("to", {}) as Dictionary).get(a, from[a]))]})
			for a: String in d.areas:
				var st: String = (tunnel.get("styles", {}) as Dictionary).get(a, "")
				var prev := d.areas.keys().find(a) - 1
				if st != Tunnel.OPEN and prev >= 0 and (tunnel.get("styles", {}) as Dictionary).get(d.areas.keys()[prev], "") == Tunnel.OPEN:
					out.append({"name": "S%d BASE MOUTH" % d.number, "type": "backdrop", "stage": d, "area": d.areas.keys()[prev], "then": [1.0, a], "loop": 9.0, "scroll": d.scroll,
						"desc": "空から基地の入口（外壁の正面とゲート）へ入るところ"})
		if tunnel.is_empty():
			out.append({"name": "S%d SCENERY" % d.number, "type": "backdrop", "stage": d, "desc": "星雲・惑星・星・深層の構造物（地形なし）"})
			out.append({"name": "S%d SCENERY  FAST" % d.number, "type": "backdrop", "stage": d, "scroll": Game.SCROLL * 4.0, "desc": "4 倍速スクロールで奥行きの流れ方を見る"})
			continue
		# a tunnel: each of its styles, at the stage's speed and slowed down
		# (a planet's surface likewise)
		var seen := {}
		var styles: Dictionary = tunnel["styles"]
		var keys := d.areas.keys()
		for i in keys.size():
			var a: String = keys[i]
			var style: String = styles.get(a, "")
			# off a planet's surface into space: the ground breaks off, the
			# planet falls away
			if style == Tunnel.OPEN and i > 0 and SurfaceModels.STYLES.has(String(styles.get(keys[i - 1], ""))) and not seen.has("liftoff"):
				seen["liftoff"] = true
				out.append({"name": "S%d LIFT-OFF" % d.number, "type": "backdrop", "stage": d, "area": keys[i - 1], "then": [1.0, a], "loop": 18.0,
					"scroll": float((d.areas.get(a, {}) as Dictionary).get("scroll", d.scroll)),
					"desc": "地表が崖で途切れ、惑星が遠ざかって、そのへりが画面の下へ流れ去る（宇宙へ）"})
			if style == "" or style == Tunnel.OPEN or seen.has(style):
				continue
			seen[style] = true
			var ground := SurfaceModels.STYLES.has(style)
			# out of a base onto the surface: the portal
			if ground and i > 0 and not SurfaceModels.STYLES.has(String(styles.get(keys[i - 1], Tunnel.OPEN))) and styles.get(keys[i - 1], Tunnel.OPEN) != Tunnel.OPEN:
				out.append({"name": "S%d BASE EXIT" % d.number, "type": "backdrop", "stage": d, "area": keys[i - 1], "then": [1.0, a], "loop": 9.0, "scroll": d.scroll,
					"desc": "基地の最後のトンネルが出口で終わり、惑星の地表へ出るところ"})
			if ground:
				out.append({"name": "S%d SURFACE  %s" % [d.number, style.to_upper()], "type": "backdrop", "stage": d, "area": a, "scroll": d.scroll,
					"desc": "惑星の地表（%s）を本編の速さで。区間をばらばらの順に、半分は向きを変えて並べる。エリアの境のゲート（地形なし）" % style})
				out.append({"name": "S%d SURFACE  %s  SLOW" % [d.number, style.to_upper()], "type": "backdrop", "stage": d, "area": a, "scroll": d.scroll * 0.25,
					"desc": "同じ地表を 1/4 の速さで"})
				continue
			out.append({"name": "S%d TUNNEL  %s" % [d.number, style.to_upper()], "type": "backdrop", "stage": d, "area": a, "scroll": d.scroll,
				"desc": "トンネル（%s）を本編の速さで。仕切りのリブ・目玉の区画・エリアの境のゲート（地形なし）" % style})
			out.append({"name": "S%d TUNNEL  %s  SLOW" % [d.number, style.to_upper()], "type": "backdrop", "stage": d, "area": a, "scroll": d.scroll * 0.25,
				"desc": "同じトンネルを 1/4 の速さで"})
	return out


static func _fx(d: StageDef) -> Array:
	var out := []
	var ex := [
		["EXPLOSION S   1.0  fighter", 1.0, Models.CRIM],
		["EXPLOSION M   1.6  container", 1.6, Models.COBALT],
		["EXPLOSION M   1.8  big rock", 1.8, Models.body_col("rock_l", Models.GUN)],
		["EXPLOSION L   2.5  boss pod", 2.5, Models.STEEL_M],
		["EXPLOSION XL  3.0  bulwark", 3.0, Models.GUN],
		["EXPLOSION XXL 6.0  boss eye", 6.0, Models.body_col("boss_eye", Models.GUN)],
	]
	for e: Array in ex:
		out.append({"name": e[0], "type": "fx", "fx": "explode", "scale": e[1], "body": e[2], "every": 2.2, "stage": d, "desc": "爆発 大きさ %.1f（大きさ 2.4 以上は小爆発の連鎖になる）。火・煙・破片はすべて敵と敵弾の下に描く" % e[1]})
	for e: Array in [
		["LAZARO DEFEAT", "lazaro_end", 3.0, "ラザロの最期：画面の大半に広がる大爆発と、4 つの殻の爆発"],
		["STAR CORTEX FINALE", "finale", 4.5, "ボスの最後の大爆発：画面全体に広がる"],
		["SHIP LOST", "player_die", 2.5, "自機の爆発（寒色）と画面の閃光"],
		["SHIELD BREAK", "shield", 2.0, "第 3 形態のシールドが割れるところ"],
		["TILE BREAK", "tiles", 3.0, "区画のタイルが割れるところ（3 種、スターとエネルギーも）"],
		["HITS AND SPARKS", "spark", 1.0, "命中・弾の撃ち落とし・装甲で弾かれた火花・ホーミング命中"],
		["SPEAR SHOCKWAVE", "shockwave", 1.5, "スピアを出した時の輪"],
		["SCORE POPUPS", "popup", 1.5, "得点表示（通常と大）"],
		["BULLETS TO ENERGY", "cancel", 2.5, "撃破で、その敵の弾がエネルギーに変わる"],
		["TELEGRAPH  SHOT", "warn_shot", 2.0, "予兆：消せない弾の前"],
		["TELEGRAPH  MOVE", "warn_move", 2.0, "予兆：突進や大技の前（二重の括弧と矢印）"],
	]:
		out.append({"name": e[0], "type": "fx", "fx": e[1], "every": e[2], "desc": e[3], "stage": d, "scroll": 0.0 if e[1] == "tiles" else Game.SCROLL})
	return out


static func _bullets(d: StageDef) -> Array:
	var out := []
	for e: Array in [["SHELL  ROUND", Bullets.SHELL, Bullets.ROUND], ["SHELL  NEEDLE", Bullets.SHELL, Bullets.NEEDLE],
			["ORB  ROUND", Bullets.ORB, Bullets.ROUND], ["ORB  NEEDLE", Bullets.ORB, Bullets.NEEDLE], ["HEAVY", Bullets.HEAVY, Bullets.ROUND], ["IRON  SNAKING", Bullets.IRON, Bullets.ROUND], ["SHELL  SPLITTING", Bullets.SHELL, -1]]:
		out.append({"name": e[0], "type": "bullets", "bkind": e[1], "shape": e[2], "stage": d,
			"desc": "大きな物理弾がはじけて物理弾の輪になる（ボス）" if e[2] == -1 else ["物理弾：撃ち落とせる。自機のショットを遮る", "エネルギー弾：スピアか撃破でしか消えない", "重エネルギー弾：スピアでも消えない", "鉄球弾（ボス）：蛇行して飛ぶ。撃ち落とせず、スピアでも消えず、自機のショットを遮る"][e[1]]})
	return out


static func _items(d: StageDef) -> Array:
	return [
		{"name": "ITEMS  LINE-UP", "type": "items", "scroll": 0.0, "stage": d, "desc": "エネルギー 1 / 2 / 4 / 8、パワーアップ、スター（静止）"},
		{"name": "ENERGY BURST", "type": "fx", "fx": "energy", "every": 2.0, "stage": d, "desc": "撃破で出るエネルギー（スクロールに流れる）"},
	]


static func _models(d: StageDef) -> Array:
	var out := []
	var shell := [["lazaro_core", Vector3.ZERO, 0.0, 1.0]]
	for k in 4:
		shell.append(["lazaro_piece", Vector3(0.95, 0, 0.95).rotated(Vector3.UP, -k * PI / 2.0), -k * PI / 2.0, 1.0])
	out.append({"name": "SET  LAZARO SHELL", "type": "model", "stage": d, "scroll": 0.0, "parts": shell,
		"desc": "核を 4 つの殻で閉じた状態", "cam": {"target": Vector3.ZERO, "dist": 14.0, "pitch": 60.0}})
	var cortex := [["boss_hull", Vector3.ZERO, 0.0, 1.0], ["boss_eye", Vector3(0, -0.4, 0), 0.0, 1.0]]
	for o: Vector3 in Bosses.KINDS["star_cortex"].POD_OFF:
		cortex.append(["boss_pod", o, 0.0, 1.0])
	out.append({"name": "SET  STAR CORTEX", "type": "model", "stage": d, "scroll": 0.0, "spin": false, "parts": cortex,
		"desc": "船体・目・ポッドを組んだ状態（シャッターなし）", "cam": {"target": Vector3.ZERO, "dist": 26.0, "pitch": 66.0}})
	var train := [["ouro_head", Vector3(0, 0, -6.9), 0.0, 1.0]]
	for k in 6:
		train.append(["ouro_car", Vector3(0, 0, -4.6 + k * 2.3), 0.0, 1.0])
	out.append({"name": "SET  OUROBOROS", "type": "model", "stage": d, "scroll": 0.0, "spin": false, "parts": train,
		"desc": "機関車と車両を一列に連結した状態", "cam": {"target": Vector3.ZERO, "dist": 24.0, "pitch": 60.0}})
	var vp = Bosses.KINDS["vulcan_press"]
	var press := [["press_hull", Vector3.ZERO, 0.0, 1.0], ["press_core", vp.CORE_OFF, 0.0, 1.0]]
	for k in 3:
		var a := -PI / 2.0 + k * TAU / 3.0
		press.append(["press_plate", vp.CORE_OFF + Vector3(cos(a), 0, sin(a)) * vp.PLATE_R, atan2(-cos(a), -sin(a)), 1.0])
	for s in [-1, 1]:
		press.append(["press_hammer", Vector3(s * 6.0, 0, vp.RAIL_Z + vp.HEAD_REST + 3.0), 0.0, 1.0])
		for k in 3:
			press.append(["press_tube%d" % k, Vector3(s * 6.0, 0, vp.RAIL_Z + 3.0 * (1.0 - k / 3.0) - vp.TUBE_LEN * 0.5), 0.0, 1.0])
	for o: Vector3 in vp.VENT_OFF:
		press.append(["press_vent", o, 0.0, 1.0])
	out.append({"name": "SET  VULCAN PRESS", "type": "model", "stage": d, "scroll": 0.0, "spin": false, "parts": press,
		"desc": "船体・核・装甲板・ハンマー（少し伸ばした状態）・砲塔を組んだ状態", "cam": {"target": Vector3(0, 0, 2.0), "dist": 34.0, "pitch": 62.0}})
	for gr: Array in Models.groups():
		for n: String in gr[1].NAMES:
			out.append({"name": "%s  %s" % [gr[0], n], "type": "model", "stage": d, "scroll": 0.0, "parts": [[n, Vector3.ZERO, 0.0, 1.0]], "auto_cam": true})
	return out
