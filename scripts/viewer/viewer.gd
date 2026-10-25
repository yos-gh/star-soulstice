class_name Viewer
extends Node
## The viewer (title menu > VIEWER): every asset of the game one at a time,
## live in the real game world, so it moves and looks exactly as in play.
## The lists come from the registries (ViewerCatalog), so new enemies,
## bosses, stages, sections and models appear here by themselves.
##   SHIP     the three forms, side by side, and their weapons
##   SMALL    small fighters flying their formations (EnemyKinds INFO.demos)
##   MEDIUM   mid-size, carriers, drifting hazards and ground units
##   BOSS     mid-bosses and bosses, with shortcuts into later phases
##   WAVES    every wave of every stage, over its area, as the stage runs it
##   TERRAIN  each area streaming by, every section still, every IslandGen kind
##   SCENERY  each stage's backdrop without the ground
##   FX       explosions, hits, shockwaves, telegraphs
##   BULLETS  every bullet kind and shape
##   ITEMS    energy, power-up, star
##   MODELS   every voxel model on a turntable, and assembled sets
## Subjects loop: a formation flies in again once it is gone, a boss
## returns after it is destroyed or escapes. A still ship stands in as
## the target (it cannot be hit).
##
## Keys: LEFT/RIGHT category, UP/DOWN item, Z replay, ESC freeze (the whole
## world stops; the camera still moves), F one frame, 1-5 or -/= speed,
## mouse drag orbit / right drag pan / wheel zoom (or SHIFT+arrows,
## PAGE UP/DOWN), C camera reset, K destroy, B autopilot, TAB fly the ship
## yourself, E enemy fire on/off, G ground, V scenery, T turntable,
## H hide this panel, Q back to the title. Pad: LB/RB category, D-pad item,
## A replay, START freeze, X frame, Y fly, right stick orbit, triggers zoom.

const SPEEDS := [0.1, 0.25, 0.5, 1.0, 2.0]
const RESTART_GAP := 1.2
const MIN_PITCH := 8.0
const MAX_PITCH := 88.0

var game: Game
var panel: ViewerPanel
var cats: Array = []  # [{name, items: [Dictionary]}]
var ci := 0
var sel: Array[int] = []  # selected item per category
var entry: Dictionary = {}

var frozen := false
var step_req := false
var speed_i := 3
var fire_on := true
var bot_on := false
var fly := false
var spin := true
var ground_on := false
var scenery_on := true
var t := 0.0  # seconds since the subject started
var loops := 0

# the subject
var pending: Array = []
var wave_t := 0.0
var members: Array = []
var idle_t := -1.0  # counting down to a replay once the subject is gone
var boss: BossBase
var pivot: Node3D  # turntable for models
var models: Array[MeshInstance3D] = []
var emit_t := 0.0
var break_t := -1.0  # TILE BREAK: seconds until the tiles go
var dummy: Enemy  # what telegraphs point at
var stream_t := 0.0
var kind_layouts := {}  # IslandGen kind -> layout (KIND entries)
var then_done := false  # the entry's "then" (a later area) has come

# camera
var cam_yaw := 0.0
var cam_pitch := Game.CAM_PITCH
var cam_dist := Game.CAM_DIST
var cam_target := Game.CAM_TARGET
var drag := 0  # 1 orbit, 2 pan

# --viewer-tour
var tour := 0.0
var tour_t := 0.0
var tour_i := 0
var tour_list: Array = []  # [category, item]


# ------------------------------------------------------------ enter / leave

func enter(at: String, tour_s: float) -> void:
	if cats.is_empty():
		cats = ViewerCatalog.build(game)
		sel.clear()
		for c in cats:
			sel.append(0)
	if at != "" and at != "-":
		_jump(at)
	tour = tour_s
	if tour > 0.0:
		tour_list.clear()
		for c in cats.size():
			for i in (cats[c]["items"] as Array).size():
				tour_list.append([c, i])
		tour_i = 0
		tour_t = 0.0
		ci = tour_list[0][0]
		sel[ci] = tour_list[0][1]
	frozen = false
	fly = false
	bot_on = false
	panel.visible = true
	_begin()


## --viewer=CAT[:N]: a category by name (or its first letters) or number.
func _jump(at: String) -> void:
	var c := at.get_slice(":", 0).to_upper()
	for k in cats.size():
		if c.is_valid_int() and int(c) == k or not c.is_valid_int() and String(cats[k]["name"]).begins_with(c):
			ci = k
			break
	if at.contains(":"):
		var n := at.get_slice(":", 1)
		var items: Array = cats[ci]["items"]
		if n.is_valid_int():
			sel[ci] = clampi(int(n), 0, items.size() - 1)
		else:
			for i in items.size():
				if String(items[i]["name"]).to_upper().contains(n.to_upper()):
					sel[ci] = i
					break


func leave() -> void:
	_clear()
	panel.visible = false
	frozen = false
	fly = false
	bot_on = false
	game.backdrop.visible = true
	game.terrain.visible = true
	game.player.rotation = Vector3.ZERO


func items() -> Array:
	return cats[ci]["items"]


# ------------------------------------------------------------ subject

func _clear() -> void:
	game.clear_field()
	game.terrain.reset(false)
	game.terrain.spawning = false
	if pivot != null:
		pivot.queue_free()
		pivot = null
	models.clear()
	pending.clear()
	members.clear()
	boss = null
	dummy = null
	idle_t = -1.0
	break_t = -1.0
	then_done = false
	game.flash_a = 0.0
	game.shake_a = 0.0


## (Re)starts the selected item.
func _begin() -> void:
	entry = items()[sel[ci]]
	_clear()
	t = 0.0
	wave_t = 0.0
	loops = 0
	emit_t = 0.0
	var e := entry
	var speed := Game.SCROLL
	if e.has("stage"):
		var d: StageDef = e["stage"]
		game.terrain.use_stage(d)
		game.backdrop.use(d.backdrop)
		game.backdrop.set_area(e.get("area", d.first_area), true)
		game.stage_def = d
		speed = d.scroll
	game.scroll_speed = e.get("scroll", speed)
	_reset_camera()
	var tp: String = e["type"]
	var want_player: bool = e.get("player", tp in ["spawns", "boss", "ground", "ship"])
	_player(want_player)
	match tp:
		"spawns":
			pending = (e["spawns"] as Array).duplicate()
			pending.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
			if e.has("area"):
				var a: Dictionary = (e["stage"] as StageDef).areas.get(e["area"], {})
				stream_t = float((a.get("stream", {}) as Dictionary).get("first", 1.0))
		"boss":
			_spawn_boss()
		"ship":
			var p := game.player
			p.position = Vector3(0, 0, 2.0)
			p.set_level(e["form"])
			p._visuals()
		"ground":
			var lays: Array = game.terrain.layouts.get(game.terrain.title_area, [])
			for lay: Dictionary in lays:
				if not (lay["turrets"] as Array).is_empty():
					game.terrain.place(lay, _ground_mid(), true)
					break
		"section":
			var lay: Dictionary = game.terrain.layouts[e["area"]][e["index"]]
			game.terrain.place(lay, _ground_mid(), false)
		"kind_section":
			var k: String = e["kind"]
			if not kind_layouts.has(k):
				kind_layouts[k] = IslandGen.make(e["seed"], k, 12, 6, 2)
			game.terrain.place(kind_layouts[k], _ground_mid(), false)
		"area":
			game.terrain.reset(true)
			game.terrain.set_area(e["area"])
			game.terrain.next_in = 0.0
		"items":
			_line_up_items()
		"model":
			_show_model()
	if e.get("terrain", false) and e.has("area"):
		game.terrain.reset(true)
		game.terrain.set_area(e["area"])
		game.terrain.next_in = 0.0
	elif ground_on and tp in ["spawns", "boss", "ship", "fx", "bullets"]:
		game.terrain.reset(false)
		game.terrain.spawning = true
		game.terrain.next_in = 0.0
	game.backdrop.visible = scenery_on
	if tour <= 0.0:
		print("VIEW %s / %s" % [cats[ci]["name"], e["name"]])


func _ground_mid() -> Vector3:
	return Vector3(0, Game.GROUND_Y, (game.ground_top + game.ground_bottom) * 0.5 - 1.0)


## The still stand-in ship (also what enemies aim at), or none.
func _player(on: bool) -> void:
	var p := game.player
	p.reset_at(Vector3(0, 0, game.field_bottom - 5.5))
	p.rotation = Vector3.ZERO
	p.entering = 0.0
	p.invuln = 0.0
	p.energy = Player.ENERGY_MAX
	p.alive = on
	p.visible = on
	if on and entry.has("form"):
		p.set_level(entry["form"])
	p._visuals()


func _spawn_boss() -> void:
	boss = game.spawn_boss(entry["kind"], false)
	if entry.get("skip", "") != "":
		boss.viewer_skip(entry["skip"])


func on_boss_destroyed(b: BossBase) -> void:
	if b == boss and idle_t < 0.0:
		idle_t = 2.5


func _show_model() -> void:
	pivot = Node3D.new()
	game.units.add_child(pivot)
	var aabb := AABB()
	var first := true
	for part: Array in entry["parts"]:
		var m := MeshInstance3D.new()
		m.mesh = Vox.get_mesh(part[0])
		m.position = part[1]
		m.rotation.y = part[2]
		m.scale = Vector3.ONE * float(part[3])
		pivot.add_child(m)
		models.append(m)
		var bb: AABB = m.transform * m.mesh.get_aabb()
		aabb = bb if first else aabb.merge(bb)
		first = false
	entry["aabb"] = aabb
	if entry.get("auto_cam", false):
		cam_target = aabb.get_center()
		cam_dist = clampf(aabb.size.length() * 2.4, 4.0, 90.0)
		cam_pitch = 50.0


func _line_up_items() -> void:
	var z := -4.0
	var vals := [1.0, 2.0, 4.0, 8.0]
	for i in vals.size():
		game.items.spawn(Vector3(-6.0 + i * 2.2, 0, z), Items.ENERGY, vals[i])
	game.items.spawn(Vector3(4.0, 0, z), Items.POWER, 1.0)
	game.items.spawn(Vector3(7.5, 0, z), Items.STAR, 1.0)


# ------------------------------------------------------------ tick

func tick(dt: float) -> void:
	_keys(dt)
	if game.state != Game.State.VIEWER:
		return
	if tour > 0.0:
		_tour(dt)
	if frozen and not step_req:
		return
	if step_req:
		_step(Game.DT)
		step_req = false
		return
	var sp: float = SPEEDS[speed_i]
	if sp > 1.0:
		for k in int(sp):
			_step(dt)
	else:
		_step(dt * sp)


func _step(dt: float) -> void:
	t += dt
	game.play_t += dt
	# scenery that moves on to a later area (the way into a base), and
	# replays after a while
	if entry.has("then") and not then_done and t >= float(entry["then"][0]):
		then_done = true
		game.backdrop.set_area(entry["then"][1])
	if entry.has("loop") and t >= float(entry["loop"]):
		_restart_keep_camera()
		return
	match entry["type"]:
		"spawns":
			_drive_spawns(dt)
		"boss":
			if idle_t >= 0.0 or boss == null or not is_instance_valid(boss) or boss.finished:
				if idle_t < 0.0:
					idle_t = 2.5
				idle_t -= dt
				if idle_t <= 0.0:
					_restart_keep_camera()
					return
		"fx":
			emit_t -= dt
			if emit_t <= 0.0:
				emit_t = float(entry.get("every", 2.0))
				_emit_fx(entry["fx"])
				loops += 1
			if break_t > 0.0:
				break_t -= dt
				if break_t <= 0.0:
					_break_tiles()
		"bullets":
			emit_t -= dt
			if emit_t <= 0.0:
				emit_t = 1.4
				_emit_bullets()
		"items":
			if game.items.n == 0:
				_line_up_items()
	_drive_player(dt)
	game.tick_world(dt)
	if spin and entry.get("spin", true):
		if pivot != null:
			pivot.rotation.y += dt * 0.5
		elif entry["type"] == "ship" and not fly and not bot_on:
			game.player.rotation.y += dt * 0.5


func _drive_spawns(dt: float) -> void:
	wave_t += dt
	while not pending.is_empty() and float(pending[0][0]) <= wave_t:
		var s: Array = pending.pop_front()
		if Bosses.has(s[1]):
			members.append(game.spawn_boss(s[1], false))
		else:
			members.append(game.spawn_enemy(s[1], (s[2] as Dictionary).duplicate()))
	# the area's drifting hazards (asteroids in the debris belt)
	if entry.get("terrain", false):
		var a: Dictionary = (entry["stage"] as StageDef).areas.get(entry["area"], {})
		if a.has("stream"):
			stream_t -= dt
			if stream_t <= 0.0:
				var s: Dictionary = a["stream"]
				stream_t = float(s["every"]) * randf_range(0.6, 1.4)
				(s["spawn"] as Callable).call(game)
	if pending.is_empty() and idle_t < 0.0 and not _any_alive():
		idle_t = RESTART_GAP
	if idle_t >= 0.0:
		idle_t -= dt
		if idle_t <= 0.0:
			idle_t = -1.0
			loops += 1
			wave_t = 0.0
			members.clear()
			pending = (entry["spawns"] as Array).duplicate()
			pending.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


func _any_alive() -> bool:
	for m in members:
		if not is_instance_valid(m):
			continue
		if m is Enemy and not (m as Enemy).dead and game.enemies.has(m):
			return true
		if m is BossBase and not (m as BossBase).finished:
			return true
	return false


func _restart_keep_camera() -> void:
	var cam := [cam_yaw, cam_pitch, cam_dist, cam_target]
	_begin()
	cam_yaw = cam[0]
	cam_pitch = cam[1]
	cam_dist = cam[2]
	cam_target = cam[3]


func _drive_player(dt: float) -> void:
	var p := game.player
	if not p.alive:
		return
	if fly:
		var move := Input.get_vector("left", "right", "up", "down")
		p.tick(dt, move, Input.is_action_just_pressed("shot"), Input.is_action_pressed("shot"), Input.is_action_just_pressed("side"))
	elif bot_on:
		var b := game.bot.think()
		p.tick(dt, b[0], b[1], b[2], b[3])
	elif entry.get("pilot", "") == "weapons":
		# tap fast (Concentration), Spear + a full load of homing every 4.2 s
		var side := fmod(t + 3.0, 4.2) < dt
		if side:
			p.energy = Player.ENERGY_MAX
		p.tick(dt, Vector2.ZERO, int(t * 60.0) % 6 == 0, true, side)


# ------------------------------------------------------------ effects

func _emit_fx(what: String) -> void:
	var at := Vector3(0, 0, -3.0)
	var drift := Vector3(0, 0, game.scroll_speed * 0.4)
	var fx := game.fx
	match what:
		"explode":
			var s: float = entry["scale"]
			fx.explode(at + Vector3(0, 0.4, 0), s, drift, entry["body"])
			game.sfx.play("exp_l" if s >= 2.5 else ("exp_m" if s >= 1.5 else "exp_s"))
			if s >= 2.5:
				game.shake(0.5 + s * 0.1)
		"lazaro_end":
			game.big_blast(at, 0.7, Models.GOLD)
			for k in 4:
				fx.explode(at + Vector3(0.95, 0, 0.95).rotated(Vector3.UP, -k * PI / 2.0) * 2.5, 2.5, Vector3.ZERO, Models.BRONZE)
			game.sfx.play("exp_l")
			game.shake(1.2)
		"finale":
			game.big_blast(at, 1.0, Models.STEEL_L)
			for k in 5:
				fx.explode(at + Vector3(randf_range(-5, 5), 0, randf_range(-3, 3)), 4.0, Vector3.ZERO, Models.GUN)
			game.sfx.play("exp_l")
			game.shake(2.0)
		"player_die":
			fx.explode(at + Vector3(0, 0.4, 0), 2.6, Vector3.ZERO, Models.WHITE, Color(0.5, 0.75, 1.0))
			game.sfx.play("die")
			game.shake(1.0)
			game.flash_a = 0.5
		"shield":
			fx.shockwave(at + Vector3(0, 0.4, 0), 3.0, Color(0.5, 0.7, 1.0))
			game.sfx.play("shield")
		"tiles":
			# a small section, then every tile on it breaks
			game.terrain.clear()
			var lays: Array = game.terrain.layouts.get(game.terrain.first_area, [])
			if not lays.is_empty():
				game.terrain.place(lays[0], _ground_mid(), false)
			break_t = 0.8
		"spark":
			fx.spark(at + Vector3(-4, 0.5, 0), Color(1.0, 0.8, 0.5), 1, 0.3)
			fx.spark(at + Vector3(-1.5, 0.5, 0), Color(0.45, 0.8, 1.0), 3, 0.35)
			fx.spark(at + Vector3(1.5, 0.5, 0), Color(0.7, 0.8, 1.0), 1, 0.3)
			fx.sprite(at + Vector3(4, 0.5, 0), Vector3.ZERO, 0.6, 2.2, 0.25, Color(0.5, 0.9, 1.0), 0.0)
			game.sfx.play("hit")
		"shockwave":
			fx.shockwave(at + Vector3(0, 0.5, 0), Player.SPEAR_R, Color(0.4, 0.85, 1.0))
			game.sfx.play("spear")
		"popup":
			fx.popup(at + Vector3(-3, 0, 0), "1000", Color(1, 0.9, 0.5), false)
			fx.popup(at + Vector3(3, 0, 0), "8000 x8", Color(1.0, 0.9, 0.4), true)
		"cancel":
			game.bullets.ring(at, 18, 3.0, Bullets.SHELL, self, 0.0)
			game.get_tree().create_timer(1.0).timeout.connect(func() -> void:
				if game.state != Game.State.VIEWER or entry.get("fx", "") != "cancel":
					return
				fx.explode(at + Vector3(0, 0.4, 0), 1.0, Vector3.ZERO, Models.CRIMSON)
				for q in game.bullets.cancel_owner(self):
					game.items.spawn(q, Items.ENERGY, 1.0)
					fx.sprite(q + Vector3(0, 0.4, 0), Vector3.ZERO, 0.8, 0.2, 0.2, Color(0.5, 1.0, 0.6), 0.0))
		"energy":
			game.items.burst_energy(at, 14.0)
		"warn_shot", "warn_move":
			if dummy == null or not is_instance_valid(dummy):
				dummy = game.spawn_part(null, "swirl" if what == "warn_shot" else "rammer", 0.9)
				dummy.position = at
				dummy.hit_pos = at
			var mv := what == "warn_move"
			game.warn(dummy, float(entry["every"]) * 0.8, Game.Warn.MOVE if mv else Game.Warn.SHOT, dummy.radius, Vector3(0, 0, game.field_bottom - 5.5) if mv else null)


func _emit_bullets() -> void:
	var k: int = entry["bkind"]
	var shp: int = entry["shape"]
	var at := Vector3(0, 0, -6.0)
	loops += 1
	if k == Bullets.IRON:
		# three armoured balls weaving down
		for i in 3:
			game.bullets.fire(at, PI / 2.0 + deg_to_rad(18.0) * (i - 1), 4.6, k, self)
			game.bullets.snake(2.2, 3.0)
		emit_t = 2.6
		return
	if shp < 0:
		# big shells that burst into rings
		for s in [-1, 1]:
			game.bullets.fire(at, PI / 2.0 + s * 0.5, 4.2, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, 1.6)
			game.bullets.split(0.9, 10)
		emit_t = 2.4
		return
	var n := 8 if k == Bullets.HEAVY else 16
	game.bullets.ring(at, n, 3.2, k, self, loops * 0.2, 0, 0.0, shp)


# ------------------------------------------------------------ input

func _keys(dt: float) -> void:
	var orbit := Input.is_action_pressed("v_orbit")
	# camera: keyboard, pad
	if orbit and not fly:
		var v := Input.get_vector("left", "right", "up", "down")
		cam_yaw -= v.x * dt * 1.6
		cam_pitch = clampf(cam_pitch - v.y * dt * 60.0, MIN_PITCH, MAX_PITCH)
	var rs := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if rs.length() > 0.25:
		cam_yaw -= rs.x * dt * 1.8
		cam_pitch = clampf(cam_pitch - rs.y * dt * 70.0, MIN_PITCH, MAX_PITCH)
	if Input.is_action_pressed("v_zoom_in"):
		cam_dist = maxf(2.5, cam_dist * (1.0 - dt * 1.2))
	if Input.is_action_pressed("v_zoom_out"):
		cam_dist = minf(160.0, cam_dist * (1.0 + dt * 1.2))
	if Input.is_action_just_pressed("v_cam"):
		_reset_camera()
	# always available
	if Input.is_action_just_pressed("back"):
		game.leave_viewer()
		return
	if Input.is_action_just_pressed("pause"):
		frozen = not frozen
		game.sfx.play("cursor")
	if Input.is_action_just_pressed("v_step"):
		frozen = true
		step_req = true
	if Input.is_action_just_pressed("v_fly"):
		fly = not fly
		if fly:
			bot_on = false
			var p := game.player
			if not p.alive:
				p.reset_at(Vector3(0, 0, game.field_bottom - 5.5))
				p.energy = Player.ENERGY_MAX
			p.rotation = Vector3.ZERO
		game.sfx.play("cursor")
	if Input.is_action_just_pressed("v_panel"):
		panel.visible = not panel.visible
	if fly:
		return
	# lists and toggles (the arrows and Z fly the ship in TAB mode)
	if not orbit:
		var dc := 0
		if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("v_next"):
			dc = 1
		if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("v_prev"):
			dc = -1
		if dc != 0:
			ci = posmod(ci + dc, cats.size())
			game.sfx.play("cursor")
			_begin()
			return
		var di := 0
		if Input.is_action_just_pressed("down"):
			di = 1
		if Input.is_action_just_pressed("up"):
			di = -1
		if di != 0:
			sel[ci] = posmod(sel[ci] + di, items().size())
			game.sfx.play("cursor")
			_begin()
			return
	if Input.is_action_just_pressed("confirm") and not Input.is_action_just_pressed("pause"):
		_restart_keep_camera()
		return
	if Input.is_action_just_pressed("v_kill"):
		_destroy()
	if Input.is_action_just_pressed("v_bot"):
		bot_on = not bot_on
		if bot_on and not game.player.alive:
			_player(true)
		game.player.rotation = Vector3.ZERO
	if Input.is_action_just_pressed("v_fire"):
		fire_on = not fire_on
	if Input.is_action_just_pressed("v_spin"):
		spin = not spin
	if Input.is_action_just_pressed("v_ground"):
		ground_on = not ground_on
		_restart_keep_camera()
	if Input.is_action_just_pressed("v_scenery"):
		scenery_on = not scenery_on
		game.backdrop.visible = scenery_on
	if Input.is_action_just_pressed("v_slower"):
		speed_i = maxi(0, speed_i - 1)
	if Input.is_action_just_pressed("v_faster"):
		speed_i = mini(SPEEDS.size() - 1, speed_i + 1)


func on_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: Key = (ev as InputEventKey).physical_keycode
		if k >= KEY_1 and k <= KEY_5:
			speed_i = k - KEY_1
	elif ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			cam_dist = maxf(2.5, cam_dist * 0.9)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			cam_dist = minf(160.0, cam_dist * 1.1)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			drag = 1 if mb.pressed else 0
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			drag = 2 if mb.pressed else 0
	elif ev is InputEventMouseMotion and drag != 0:
		var r := (ev as InputEventMouseMotion).relative
		if drag == 1:
			cam_yaw -= r.x * 0.006
			cam_pitch = clampf(cam_pitch + r.y * 0.3, MIN_PITCH, MAX_PITCH)
		else:
			var k := cam_dist * 0.0016
			var right := Vector3(cos(cam_yaw), 0, -sin(cam_yaw))
			var fwd := Vector3(sin(cam_yaw), 0, cos(cam_yaw))
			cam_target -= right * r.x * k + fwd * r.y * k


## K: blows up whatever is being shown (formations, bosses, turrets, tiles).
func _destroy() -> void:
	for m in members:
		if not is_instance_valid(m):
			continue
		if m is Enemy and not (m as Enemy).dead and game.enemies.has(m):
			game.kill(m)
		elif m is BossBase:
			(m as BossBase).force_defeat()
	if boss != null and is_instance_valid(boss):
		boss.force_defeat()
	for e: Enemy in game.enemies.duplicate():
		if e.ground and not e.dead:
			game.kill(e)
	if entry["type"] in ["section", "kind_section", "ground", "area"]:
		_break_tiles()


func _break_tiles() -> void:
	for isl in game.terrain.islands:
		for idx in isl.w * isl.h:
			if isl.types[idx] >= 0:
				isl.damage(idx, 99.0)


# ------------------------------------------------------------ camera

func _reset_camera() -> void:
	var c: Dictionary = entry.get("cam", {})
	cam_yaw = 0.0
	cam_pitch = c.get("pitch", Game.CAM_PITCH)
	cam_dist = c.get("dist", Game.CAM_DIST)
	cam_target = c.get("target", Game.CAM_TARGET)
	if entry.has("aabb") and entry.get("auto_cam", false):
		var bb: AABB = entry["aabb"]
		cam_target = bb.get_center()
		cam_dist = clampf(bb.size.length() * 2.4, 4.0, 90.0)
		cam_pitch = 50.0


## [eye, look-at point, horizontal offset] for Game._update_camera. Close-up
## subjects are shifted to the middle of the screen right of the panel.
func camera_view() -> Array:
	var p := deg_to_rad(cam_pitch)
	var eye := cam_target + Vector3(sin(cam_yaw) * cos(p), sin(p), cos(cam_yaw) * cos(p)) * cam_dist
	var shift := 0.0
	if panel.visible and entry.get("type", "") in ["model", "ship", "section", "kind_section", "items"]:
		var px := ViewerPanel.W * 0.5
		shift = -px * 2.0 * cam_dist * tan(deg_to_rad(Game.CAM_FOV * 0.5)) / game.get_viewport().get_visible_rect().size.y
	return [eye, cam_target, shift]


# ------------------------------------------------------------ tour

## --viewer-tour: every item for `tour` seconds, one screenshot each.
func _tour(dt: float) -> void:
	tour_t += dt
	if tour_t < tour:
		return
	var e := entry
	var line := "TOUR %02d %s / %s  enemies=%d bosses=%d bullets=%d items=%d islands=%d" % [tour_i, cats[ci]["name"], e["name"], game.enemies.size(), game.bosses.size(), game.bullets.n, game.items.n, game.terrain.islands.size()]
	print(line)
	if game.capture_dir != "":
		var img := game.get_viewport().get_texture().get_image()
		var slug := ("%s_%s" % [cats[ci]["name"], e["name"]]).to_lower().replace(" ", "_").replace("/", "_")
		while slug.contains("__"):
			slug = slug.replace("__", "_")
		img.save_png("%s/%03d_%s.png" % [game.capture_dir, tour_i, slug])
	tour_i += 1
	tour_t = 0.0
	if tour_i >= tour_list.size():
		print("TOUR done")
		game.get_tree().quit()
		return
	ci = tour_list[tour_i][0]
	sel[ci] = tour_list[tour_i][1]
	_begin()
