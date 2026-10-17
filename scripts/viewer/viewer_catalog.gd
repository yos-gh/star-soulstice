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

const MEDIUM_CATS := ["medium", "carrier", "hazard", "ground"]


static func build(g: Game) -> Array:
	var f := Formations.new(g)
	var stages: Array[StageDef] = []
	for n in Stages.count():
		var d := Stages.create(n + 1)
		d.build_waves(f)
		stages.append(d)
	return [
		{"name": "SHIP", "jp": "自機", "items": _ship(f, stages[0])},
		{"name": "SMALL", "jp": "小型機と編隊", "items": _enemies(f, ["small"], stages[0])},
		{"name": "MEDIUM", "jp": "中型機・コンテナ・小惑星・砲台", "items": _enemies(f, MEDIUM_CATS, stages[0])},
		{"name": "BOSS", "jp": "中ボス・ボス", "items": _bosses(stages[0])},
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


static func _enemies(f: Formations, cats: Array, d: StageDef) -> Array:
	var out := []
	for kind: String in EnemyKinds.KINDS:
		var info := EnemyKinds.info(kind)
		if not cats.has(info.get("category", "")):
			continue
		var demos: Array = info.get("demos", [["ONE", "one", [0.0, kind, 0.0]]])
		for demo: Array in demos:
			var it := {"name": "%s  %s" % [info.get("name", kind), demo[0]], "kind": kind, "stage": d, "desc": info.get("desc", "")}
			if demo[1] == "ground":
				it["type"] = "ground"
				it["scroll"] = 0.0
			else:
				it["type"] = "spawns"
				it["spawns"] = _demo_spawns(f, demo)
			out.append(it)
	return out


static func _bosses(d: StageDef) -> Array:
	var out := []
	for kind: String in Bosses.KINDS:
		var info := Bosses.info(kind)
		for demo: Array in info.get("demos", [["FULL", ""]]):
			out.append({"name": "%s  %s" % [info.get("name", kind), demo[0]], "type": "boss", "kind": kind, "skip": demo[1], "stage": d,
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
		out.append({"name": "S%d SCENERY" % d.number, "type": "backdrop", "stage": d, "desc": "星雲・惑星・星・深層の構造物（地形なし）"})
		out.append({"name": "S%d SCENERY  FAST" % d.number, "type": "backdrop", "stage": d, "scroll": Game.SCROLL * 4.0, "desc": "4 倍速スクロールで奥行きの流れ方を見る"})
	return out


static func _fx(d: StageDef) -> Array:
	var out := []
	var ex := [
		["EXPLOSION S   1.0  fighter", 1.0, Models.CRIMSON],
		["EXPLOSION M   1.6  container", 1.6, Models.STEEL],
		["EXPLOSION M   1.8  big rock", 1.8, Models.CRIMSON],
		["EXPLOSION L   2.5  boss pod", 2.5, Models.CRIMSON],
		["EXPLOSION XL  3.0  bulwark", 3.0, Models.CRIMSON],
		["EXPLOSION XXL 6.0  boss eye", 6.0, Models.CRIMSON],
	]
	for e: Array in ex:
		out.append({"name": e[0], "type": "fx", "fx": "explode", "scale": e[1], "body": e[2], "every": 2.2, "stage": d, "desc": "爆発 大きさ %.1f（大きさ 2.4 以上は小爆発の連鎖になる）" % e[1]})
	for e: Array in [
		["LAZARO DEFEAT", "lazaro_end", 3.0, "ラザロの最期：核と 4 つの殻が爆発"],
		["STAR CORTEX FINALE", "finale", 4.5, "ボスの最後の大爆発"],
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
			["ORB  ROUND", Bullets.ORB, Bullets.ROUND], ["ORB  NEEDLE", Bullets.ORB, Bullets.NEEDLE], ["HEAVY", Bullets.HEAVY, Bullets.ROUND]]:
		out.append({"name": e[0], "type": "bullets", "bkind": e[1], "shape": e[2], "stage": d,
			"desc": ["物理弾：撃ち落とせる。自機のショットを遮る", "エネルギー弾：スピアか撃破でしか消えない", "重エネルギー弾：スピアでも消えない"][e[1]]})
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
	for gr: Array in Models.groups():
		for n: String in gr[1].NAMES:
			out.append({"name": "%s  %s" % [gr[0], n], "type": "model", "stage": d, "scroll": 0.0, "parts": [[n, Vector3.ZERO, 0.0, 1.0]], "auto_cam": true})
	return out
