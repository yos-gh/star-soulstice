class_name Game
extends Node3D
## STAR SOULSTICE — stage 1 prototype. A modern homage to Star Soldier:
## no air/ground split, everything breakable, tap-fire Concentration, and an
## energy loop (collect energy -> release it as homing lasers with the Spear).
##
## Everything that collides lives on the play plane y = 0 (+z = down-screen).
## Islands float below at GROUND_Y; their tiles and turrets are hit through
## their projection onto the plane along the view ray, so what you see is
## what you hit.
##
## Command-line options (after "--"):
##   --autoplay        a simple bot plays
##   --god             the player cannot die
##   --start=N|mid|boss  begin at wave N, the mid-boss or the boss
##   --capture=DIR     save a screenshot every --capture-every seconds (default 3)
##   --quit-after=S    quit after S seconds of play
##   --quit-on-clear   quit when the stage ends (clear or game over)
##   --log             print status every --capture-every seconds
##   --mute            no sound

enum State { TITLE, PLAY, CLEAR, GAME_OVER }

const DT := 1.0 / 60.0
const GROUND_Y := -3.0
const SCROLL := 7.0
const BOSS_SCROLL := 4.5
const CAM_PITCH := 66.0
const CAM_DIST := 34.0
const CAM_FOV := 40.0
const CAM_TARGET := Vector3(0, 0, 0.0)
const START_LIVES := 3
const EXTENDS := [200000, 600000, 1200000]
## Time bonus: BONUS_RATE points for every second the stage took under
## BONUS_T. Tuned so a quick clear earns about as much as the destruction.
const BONUS_T := 260.0
const BONUS_RATE := 1300

var state := State.TITLE
var state_t := 0.0
var time := 0.0
var play_t := 0.0
var stage_t := 0.0
var paused := false
var score := 0
var hi_score := 0
var destroy_score := 0
var item_score := 0
var bonus := 0
var lives := START_LIVES
var next_extend := 0
var scroll_speed := SCROLL
var respawn_t := 0.0
var deaths := 0
var kills := 0
var tiles_broken := 0
var energy_got := 0.0
var homing_fired := 0
var spears := 0
var clear_t := -1.0

var camera: Camera3D
var cam_pos := Vector3.ZERO
var shake_a := 0.0
var env: Environment
var sun: DirectionalLight3D
var terrain: Terrain
var units: Node3D
var player: Player
var shots: Shots
var bullets: Bullets
var items: Items
var fx: Fx
var sfx: Sfx
var hud: Hud
var stage: Stage
var enemies: Array[Enemy] = []
var lazaro: Lazaro
var boss: Boss

# play field on the plane (measured from the camera)
var field_top := -14.0
var field_bottom := 12.0
var field_hw := 15.0
var hw_top := 16.0
var hw_bottom := 14.0
var ground_top := -16.0
var ground_bottom := 14.0
var ground_hw := 16.0

var msg := ""
var msg_sub := ""
var msg_t := 0.0
var msg_warning := false
var flash_a := 0.0

# automation
var autoplay := false
var god := false
var start_at := ""
var capture_dir := ""
var capture_every := 3.0
var capture_t := 0.0
var quit_after := -1.0
var quit_on_clear := false
var log_status := false
var bot_frame := 0
var bot_goal := Vector3.ZERO
var frames := 0
var hide_layers := PackedStringArray()  # debug: --hide=sprites,debris,lights,bullets,shots,items,units,terrain
var gallery := 0  # debug: --gallery=1|2 lays models out for inspection


func _ready() -> void:
	seed(12345)
	_parse_args()
	Controls.setup()
	Input.joy_connection_changed.connect(Controls.on_joy_changed)
	_setup_world()
	_enter_title()
	if gallery > 0:
		_build_gallery()
	elif autoplay:
		_start_game()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--autoplay":
			autoplay = true
		elif a == "--god":
			god = true
		elif a == "--quit-on-clear":
			quit_on_clear = true
		elif a.begins_with("--start="):
			start_at = a.get_slice("=", 1)
		elif a.begins_with("--capture="):
			capture_dir = a.get_slice("=", 1)
			DirAccess.make_dir_recursive_absolute(capture_dir)
		elif a.begins_with("--capture-every="):
			capture_every = float(a.get_slice("=", 1))
		elif a.begins_with("--quit-after="):
			quit_after = float(a.get_slice("=", 1))
		elif a == "--log":
			log_status = true
		elif a == "--mute":
			AudioServer.set_bus_mute(0, true)
		elif a.begins_with("--gallery"):
			gallery = int(a.get_slice("=", 1)) if a.contains("=") else 1
		elif a.begins_with("--hide="):
			hide_layers = a.get_slice("=", 1).split(",")


func _setup_world() -> void:
	Vox.materials()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.008, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.8)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 0.8)
	env.set_glow_level(3, 0.5)
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.03, 0.03, 0.07)
	env.fog_depth_begin = 44.0
	env.fog_depth_end = 120.0
	env.fog_depth_curve = 1.4
	env.fog_density = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.94, 0.86)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, Vector3(-0.45, -0.8, -0.2), Vector3.UP)

	camera = Camera3D.new()
	camera.fov = CAM_FOV
	camera.near = 1.0
	camera.far = 400.0
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = CAM_DIST + 22.0  # islands and units stay sharp
	attrs.dof_blur_far_transition = 18.0
	attrs.dof_blur_amount = 0.09
	camera.attributes = attrs
	add_child(camera)
	camera.current = true
	var pitch := deg_to_rad(CAM_PITCH)
	cam_pos = CAM_TARGET + Vector3(0, sin(pitch), cos(pitch)) * CAM_DIST
	camera.look_at_from_position(cam_pos, CAM_TARGET, Vector3.UP)
	_measure_field()

	terrain = Terrain.new()
	terrain.game = self
	add_child(terrain)
	terrain.prepare()
	units = Node3D.new()
	add_child(units)
	items = Items.new()
	items.game = self
	add_child(items)
	shots = Shots.new()
	shots.game = self
	add_child(shots)
	bullets = Bullets.new()
	bullets.game = self
	bullets.bounds = Rect2(-hw_top - 3.0, field_top - 4.0, (hw_top + 3.0) * 2.0, field_bottom - field_top + 8.0)
	add_child(bullets)
	fx = Fx.new()
	add_child(fx)
	player = Player.new()
	player.game = self
	add_child(player)
	player.bounds_x = hw_bottom - 0.8
	player.bounds_z0 = field_top + 2.0
	player.bounds_z1 = field_bottom - 1.2
	sfx = Sfx.new()
	add_child(sfx)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.game = self
	layer.add_child(hud)


func _measure_field() -> void:
	var s := Vector2(960, 720)
	field_top = screen_to_y(Vector2(s.x * 0.5, 0.0), 0.0).z
	field_bottom = screen_to_y(Vector2(s.x * 0.5, s.y), 0.0).z
	hw_top = absf(screen_to_y(Vector2(0.0, 0.0), 0.0).x)
	hw_bottom = absf(screen_to_y(Vector2(0.0, s.y), 0.0).x)
	field_hw = absf(screen_to_y(Vector2(0.0, s.y * 0.5), 0.0).x)
	ground_top = screen_to_y(Vector2(s.x * 0.5, 0.0), GROUND_Y).z
	ground_bottom = screen_to_y(Vector2(s.x * 0.5, s.y), GROUND_Y).z
	ground_hw = absf(screen_to_y(Vector2(0.0, s.y * 0.5), GROUND_Y).x)
	print("field top=%.1f bottom=%.1f hw=%.1f..%.1f..%.1f ground %.1f..%.1f hw=%.1f" % [field_top, field_bottom, hw_top, field_hw, hw_bottom, ground_top, ground_bottom, ground_hw])


func screen_to_y(sp: Vector2, y: float) -> Vector3:
	var o := camera.project_ray_origin(sp)
	var d := camera.project_ray_normal(sp)
	return o + d * ((y - o.y) / d.y)


## Projects a world point onto the play plane along the (unshaken) view ray.
func to_plane(p: Vector3) -> Vector3:
	if absf(p.y) < 0.001:
		return Vector3(p.x, 0.0, p.z)
	var d := p - cam_pos
	return cam_pos + d * (-cam_pos.y / d.y)


## The inverse: the point at height y that appears at plane point p.
func from_plane(p: Vector3, y: float) -> Vector3:
	var d := Vector3(p.x, 0.0, p.z) - cam_pos
	return cam_pos + d * ((y - cam_pos.y) / d.y)


func half_width_at(z: float) -> float:
	return lerpf(hw_top, hw_bottom, clampf((z - field_top) / (field_bottom - field_top), 0.0, 1.0))


func on_field(p: Vector3, margin := 0.0) -> bool:
	return p.z > field_top - margin and p.z < field_bottom + margin and absf(p.x) < half_width_at(p.z) + margin


## Enemies only fire while on screen and not right on top of the player.
func can_fire(p: Vector3) -> bool:
	return state == State.PLAY and player.alive and on_field(p, -0.8) and p.z < player.position.z - 2.0


# ------------------------------------------------------------ states

func _enter_title() -> void:
	if quit_after > 0.0 and play_t > 0.0:
		get_tree().quit()
		return
	state = State.TITLE
	state_t = 0.0
	_clear_field()
	player.visible = false
	player.alive = false
	scroll_speed = SCROLL
	terrain.reset(false)
	terrain.spawning = true
	terrain.turrets = false


func _start_game() -> void:
	state = State.PLAY
	state_t = 0.0
	play_t = 0.0
	stage_t = 0.0
	score = 0
	destroy_score = 0
	item_score = 0
	bonus = 0
	lives = START_LIVES
	next_extend = 0
	kills = 0
	deaths = 0
	tiles_broken = 0
	energy_got = 0.0
	homing_fired = 0
	spears = 0
	clear_t = -1.0
	_clear_field()
	terrain.reset(true)
	stage = Stage.new(self)
	if start_at != "":
		stage.start_at(start_at)
	scroll_speed = SCROLL
	player.reset_at(Vector3(0, 0, field_bottom + 2.0))
	player.entering = 0.9
	player.invuln = 2.5
	player.energy = 20.0
	sfx.play("start")
	show_msg("STAGE 1", "ORBITAL FORTRESS", 2.0)
	print("START at=%s" % start_at)


func _clear_field() -> void:
	for e: Enemy in enemies.duplicate():
		remove_enemy(e)
	for c in units.get_children():
		c.queue_free()
	if lazaro != null:
		lazaro.queue_free()
		lazaro = null
	if boss != null:
		boss.queue_free()
		boss = null
	bullets.n = 0
	shots.clear()
	items.clear()
	items.vacuum = false
	fx.clear()
	msg_t = 0.0


func _respawn() -> void:
	var keep := player.energy * 0.5
	player.reset_at(Vector3(0, 0, field_bottom + 2.0))
	player.entering = 0.9
	player.invuln = 3.0
	player.energy = keep


func _game_over() -> void:
	state = State.GAME_OVER
	state_t = 0.0
	hi_score = maxi(hi_score, score)
	show_msg("GAME OVER", "", 5.0)
	print("GAME OVER score=%d t=%.1f wave=%d" % [score, stage_t, stage.wi + 1])


func boss_fight_started() -> void:
	pass


func boss_dying() -> void:
	items.vacuum = true


func boss_destroyed() -> void:
	clear_t = stage_t
	bonus = maxi(0, int((BONUS_T - stage_t) * BONUS_RATE / 100.0) * 100)
	state = State.CLEAR
	state_t = 0.0
	player.invuln = 99.0
	show_msg("STAGE CLEAR", "", 3.0)
	sfx.play("clear")
	print("CLEAR t=%.1f destroy=%d items=%d bonus=%d deaths=%d kills=%d tiles=%d" % [stage_t, destroy_score, item_score, bonus, deaths, kills, tiles_broken])


func show_msg(m: String, sub := "", t := 2.0, warning := false) -> void:
	msg = m
	msg_sub = sub
	msg_t = t
	msg_warning = warning


func shake(a: float) -> void:
	shake_a = maxf(shake_a, a)


# ------------------------------------------------------------ main loop

func _physics_process(_delta: float) -> void:
	var dt := DT
	time += dt
	frames += 1
	if Controls.notice_t > 0.0:
		Controls.notice_t -= dt
	if Input.is_action_just_pressed("fullscreen"):
		var w := get_window()
		w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	if state == State.PLAY or state == State.CLEAR:
		if Input.is_action_just_pressed("pause") and not autoplay:
			paused = not paused
			sfx.play("cursor")
		if paused:
			if Input.is_action_just_pressed("back"):
				paused = false
				_enter_title()
			hud.queue_redraw()
			return
	state_t += dt
	match state:
		State.TITLE:
			terrain.tick(dt, SCROLL if gallery != 1 and gallery != 2 else 0.0)
			if gallery > 0:
				_gallery_tick(dt)
				play_t += dt
			fx.tick(dt, scroll_speed)
			if Input.is_action_just_pressed("confirm") and state_t > 0.3:
				_start_game()
		State.PLAY:
			_tick_play(dt)
		State.CLEAR:
			_tick_play(dt)
			if bonus > 0 and state_t > 3.5:
				var step := mini(bonus, maxi(1000, bonus / 40) / 100 * 100)
				bonus -= step
				score += step
				hi_score = maxi(hi_score, score)
				if int(state_t * 20.0) % 2 == 0:
					sfx.play("item")
			if state_t > 9.0 and (Input.is_action_just_pressed("confirm") or autoplay):
				score += bonus
				bonus = 0
				hi_score = maxi(hi_score, score)
				if quit_on_clear:
					get_tree().quit()
				_enter_title()
		State.GAME_OVER:
			_tick_play(dt)
			if state_t > 2.0 and (Input.is_action_just_pressed("confirm") or state_t > 6.0):
				if quit_on_clear:
					get_tree().quit()
				_enter_title()
	flash_a = maxf(0.0, flash_a - dt * 2.5)
	msg_t = maxf(0.0, msg_t - dt)
	_update_camera(dt)
	_draw_all()
	hud.queue_redraw()
	_automation(dt)


func _input(event: InputEvent) -> void:
	Controls.note_event(event)


func _tick_play(dt: float) -> void:
	play_t += dt
	if state == State.PLAY:
		stage_t += dt
		stage.tick(dt)
	var move := Vector2.ZERO
	var tap := false
	var hold := false
	var side := false
	if autoplay:
		var b := _bot()
		move = b[0]
		tap = b[1]
		hold = b[2]
		side = b[3]
	else:
		move = Input.get_vector("left", "right", "up", "down")
		tap = Input.is_action_just_pressed("shot")
		hold = Input.is_action_pressed("shot")
		side = Input.is_action_just_pressed("side")
	if state != State.PLAY:
		tap = false
		hold = false
		side = false
	if state == State.CLEAR:
		move = Vector2(-player.position.x * 0.2, -0.6 if state_t > 4.0 else 0.0)
	if player.alive:
		player.tick(dt, move, tap, hold, side)
	elif state == State.PLAY and respawn_t > 0.0:
		respawn_t -= dt
		if respawn_t <= 0.0:
			if lives > 0:
				_respawn()
			else:
				_game_over()
	var want_scroll := BOSS_SCROLL if (stage != null and stage.phase != "waves") else SCROLL
	scroll_speed = move_toward(scroll_speed, want_scroll, dt * 0.8)
	terrain.tick(dt, scroll_speed)
	for e: Enemy in enemies.duplicate():
		if is_instance_valid(e) and not e.dead and e.controller == null:
			e.tick(dt)
	for e: Enemy in enemies.duplicate():
		if is_instance_valid(e) and not e.dead and e.controller != null:
			e.tick(dt)
	if lazaro != null:
		lazaro.tick(dt)
	if boss != null:
		boss.tick(dt)
	bullets.tick(dt)
	shots.tick(dt)
	items.tick(dt)
	fx.tick(dt, scroll_speed)
	_collide(dt)
	_cull()


# ------------------------------------------------------------ spawning

func spawn_enemy(kind: String, params := {}) -> Enemy:
	var e := Enemy.new()
	e.setup(self, kind, params)
	if params.has("island"):
		var isl: Island = params["island"]
		var c: Vector2i = params["cell"]
		isl.add_child(e)
		e.position = isl.cell_center(c.x, c.y) + Vector3(0, IslandGen.R, 0)
		e.hit_pos = to_plane(e.global_position)
	else:
		units.add_child(e)
		e.position = Vector3(float(params.get("x", 0.0)), 0, float(params.get("z", field_top - 1.5)))
		e.hit_pos = e.position
	if params.has("counts"):
		e.counts = params["counts"]
	enemies.append(e)
	return e


func spawn_part(ctrl: Object, mesh: String, radius: float) -> Enemy:
	var e := Enemy.new()
	e.setup(self, "part", {"mesh": mesh})
	e.controller = ctrl
	e.radius = radius
	e.position = Vector3(0, 0, field_top - 10.0)
	e.hit_pos = e.position
	units.add_child(e)
	enemies.append(e)
	return e


func spawn_lazaro() -> Lazaro:
	lazaro = Lazaro.new()
	add_child(lazaro)
	lazaro.setup(self)
	return lazaro


func spawn_boss() -> void:
	boss = Boss.new()
	add_child(boss)
	boss.setup(self)


func remove_enemy(e: Enemy) -> void:
	enemies.erase(e)
	if not is_instance_valid(e):
		return
	if e.controller == null:
		e.queue_free()
	else:
		e.visible = false


func _cull() -> void:
	for e: Enemy in enemies.duplicate():
		if e.dead or not e.leaves or e.ground:
			continue
		if e.entered and not on_field(e.hit_pos, 3.5):
			remove_enemy(e)
		elif not e.entered and e.t > 10.0:
			remove_enemy(e)
	# ground units leave with their island; drop them once off screen
	for e: Enemy in enemies.duplicate():
		if e.ground and e.entered and e.hit_pos.z > field_bottom + 2.0:
			remove_enemy(e)


# ------------------------------------------------------------ combat

func _collide(dt: float) -> void:
	# main shots: tiles, then shells, then enemies
	var i := 0
	while i < shots.n:
		var p := shots.pos[i]
		var dmg := shots.dmg[i]
		var used := false
		if terrain.hit(p, dmg):
			used = true
			fx.spark(p + Vector3(0, 0.3, 0), Color(0.6, 0.8, 1.0), 1, 0.25)
			sfx.play("tile")
		else:
			var sh := bullets.shoot_shell(p, 0.2, dmg)
			if sh.x != INF:
				used = true
				if sh.y > 0.5:
					fx.spark(Vector3(sh.x, 0.4, sh.z), Color(0.45, 0.8, 1.0), 3, 0.35)
					add_score(10, true)
			else:
				var e := _enemy_at(p, 0.25)
				if e != null:
					damage(e, dmg, p)
					used = true
		if used:
			shots.remove(i)
			continue
		i += 1
	# homing lasers
	for h: Dictionary in shots.homing:
		if h["done"]:
			continue
		var tgt = h["target"]
		if not is_instance_valid(tgt):
			continue
		var te := tgt as Enemy
		if te.dead or te.intangible:
			continue
		var hp: Vector3 = h["pos"]
		var d := te.hit_pos - hp
		d.y = 0.0
		if d.length() < te.radius + 0.5:
			damage(te, Shots.HOMING_DMG, hp)
			fx.sprite(hp + Vector3(0, 0.5, 0), Vector3.ZERO, 0.6, 2.2, 0.25, Color(0.5, 0.9, 1.0), 0.0)
			shots.homing_hit(h)
	# spear
	if player.alive and player.spear_t > 0.0:
		_spear(dt)
	# player
	if player.alive and player.entering <= 0.0 and player.invuln <= 0.0 and state == State.PLAY:
		var hit := bullets.hit_test(player.position, Player.HIT_R)
		if not hit:
			for e in enemies:
				if e.dead or not e.ram or e.intangible or not e.visible:
					continue
				var d := e.hit_pos - player.position
				d.y = 0.0
				var r := e.radius * 0.8 + Player.HIT_R
				if d.length_squared() < r * r:
					hit = true
					break
		if hit and not god:
			_player_hit()


func _enemy_at(p: Vector3, r: float) -> Enemy:
	for e in enemies:
		if e.dead or e.intangible or not e.visible:
			continue
		if not on_field(e.hit_pos, 0.5):
			continue
		var d := e.hit_pos - p
		var rr := e.radius + r
		if d.x * d.x + d.z * d.z < rr * rr:
			return e
	return null


func damage(e: Enemy, dmg: float, at: Vector3) -> void:
	if e.dead:
		return
	if e.armored:
		fx.spark(at + Vector3(0, 0.5, 0), Color(0.7, 0.8, 1.0), 1, 0.3)
		sfx.play("deflect")
		return
	if e.controller != null:
		dmg = e.controller.on_hit(e, dmg)
	e.flash = 1.0
	fx.spark(at + Vector3(0, 0.5, 0), Color(1.0, 0.8, 0.5), 1, 0.3)
	sfx.play("hit")
	if dmg <= 0.0:
		return
	e.hp -= dmg
	if e.hp <= 0.0:
		kill(e)


func kill(e: Enemy) -> void:
	if e.dead:
		return
	e.dead = true
	kills += 1
	add_score(e.score, true)
	var at := e.hit_pos
	var body := Models.CRIMSON
	if e.kind == "container":
		body = Models.STEEL
	fx.explode(at + Vector3(0, 0.4, 0), e.blast, Vector3(0, 0, scroll_speed * 0.4), body)
	sfx.play("exp_l" if e.blast >= 2.5 else ("exp_m" if e.blast >= 1.5 else "exp_s"))
	if e.blast >= 2.5:
		shake(0.5 + e.blast * 0.1)
	items.burst_energy(at, e.energy_drop)
	# bullets the enemy fired turn into energy
	if e.controller == null:
		for q in bullets.cancel_owner(e):
			items.spawn(q, Items.ENERGY, 1.0)
			fx.sprite(q + Vector3(0, 0.4, 0), Vector3.ZERO, 0.8, 0.2, 0.2, Color(0.5, 1.0, 0.6), 0.0)
	if e.drops_power:
		items.spawn(at, Items.POWER, 1.0, Vector3(0, 0, -3.0))
	if e.score >= 1000:
		fx.popup(at, str(e.score), Color(1, 0.9, 0.5), e.score >= 5000)
	if e.controller != null:
		e.controller.on_part_killed(e)
	remove_enemy(e)


func _spear(dt: float) -> void:
	var pp := player.position
	var conv := bullets.cancel_spear(pp, Player.SPEAR_R, Player.SPEAR_HW, Player.SPEAR_LEN)
	for q in conv:
		items.spawn(q, Items.ENERGY, 1.0)
		fx.sprite(q + Vector3(0, 0.4, 0), Vector3.ZERO, 0.9, 0.2, 0.2, Color(0.5, 0.9, 1.0), 0.0)
	var dmg := Player.SPEAR_DPS * dt
	for e: Enemy in enemies.duplicate():
		if e.dead or e.intangible or not e.visible:
			continue
		var d := e.hit_pos - pp
		var in_ring := Vector2(d.x, d.z).length() < Player.SPEAR_R + e.radius
		var in_lance := absf(d.x) < Player.SPEAR_HW + e.radius and d.z < 0.0 and d.z > -Player.SPEAR_LEN - e.radius
		if in_ring or in_lance:
			damage(e, dmg, e.hit_pos)
	terrain.spear(pp, Player.SPEAR_R, Player.SPEAR_HW, Player.SPEAR_LEN, dmg)


func on_spear(n: int) -> void:
	spears += 1
	if log_status:
		print("SPEAR t=%.1f homing=%d" % [play_t, n])
	sfx.play("spear")
	fx.shockwave(player.position + Vector3(0, 0.5, 0), Player.SPEAR_R, Color(0.4, 0.85, 1.0))
	if n > 0:
		homing_fired += n
		shots.launch_homing(player.position, n)
		sfx.play("homing")
	Controls.rumble(0.3, 0.0, 0.15)


func homing_targets(from: Vector3) -> Array:
	var list: Array = []
	for e in enemies:
		if e.dead or e.intangible or e.armored or not e.visible or not on_field(e.hit_pos, -0.3):
			continue
		list.append(e)
	list.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.hit_pos.distance_squared_to(from) < b.hit_pos.distance_squared_to(from))
	return list


func nearest_target(from: Vector3) -> Object:
	var best: Enemy = null
	var bd := INF
	for e in enemies:
		if e.dead or e.intangible or e.armored or not e.visible or not on_field(e.hit_pos, -0.3):
			continue
		var d := e.hit_pos.distance_squared_to(from)
		if d < bd:
			bd = d
			best = e
	return best


func _player_hit() -> void:
	if player.shield:
		player.set_level(1)
		player.shield = false
		player.invuln = 1.6
		fx.shockwave(player.position + Vector3(0, 0.4, 0), 3.0, Color(0.5, 0.7, 1.0))
		bullets.cancel_spear(player.position, 3.0, 0.0, 0.0)
		sfx.play("shield")
		show_msg("SHIELD BROKEN", "", 1.2)
		Controls.rumble(0.5, 0.3, 0.25)
		return
	player.alive = false
	player.visible = false
	deaths += 1
	lives -= 1
	respawn_t = 1.8
	fx.explode(player.position + Vector3(0, 0.4, 0), 2.6, Vector3.ZERO, Models.WHITE, Color(0.5, 0.75, 1.0))
	sfx.play("die")
	shake(1.0)
	flash_a = 0.5
	Controls.rumble(0.7, 0.9, 0.5)
	bullets.n = 0
	shots.homing.clear()


func on_tile_broken(at: Vector3, world: Vector3, t: int, star: bool) -> void:
	tiles_broken += 1
	add_score(Island.TILE_SCORE[t], true)
	items.burst_energy(at, Island.TILE_ENERGY[t], 3.0)
	var c: Color = [Color(0.35, 0.6, 0.62), Color(0.45, 0.5, 0.65), Color(0.5, 0.52, 0.58)][t]
	for k in 4 + t * 2:
		fx._debris(world + Vector3(randf_range(-0.7, 0.7), 0.4, randf_range(-0.7, 0.7)), Vector3(randf_range(-3, 3), randf_range(2, 4), randf_range(-3, 3)), 0.18, c)
	fx.sprite(world + Vector3(0, 0.5, 0), Vector3.ZERO, 1.0, 2.6, 0.25, c.lightened(0.3), 0.0)
	sfx.play("tile_break")
	if star:
		items.spawn(at, Items.STAR, 1.0, Vector3(0, 0, -2.0))
		fx.sprite(world + Vector3(0, 0.6, 0), Vector3.ZERO, 0.5, 3.0, 0.4, Color(1.0, 0.9, 0.4), 2.0)


func collect(kind: int, value: float, at: Vector3) -> void:
	match kind:
		Items.ENERGY:
			player.energy = minf(Player.ENERGY_MAX, player.energy + value)
			energy_got += value
			_item_score(int(round(2 * value)))
			sfx.play("energy")
		Items.POWER:
			if player.level < 2:
				player.set_level(player.level + 1)
				_item_score(1000)
				show_msg("FORM %s" % ["I", "II", "III"][player.level], "", 1.0)
			else:
				if not player.shield:
					player.shield = true
				_item_score(5000)
				fx.popup(at, "5000", Color(0.6, 0.85, 1.0))
			fx.shockwave(player.position + Vector3(0, 0.4, 0), 2.5, Color(0.4, 0.7, 1.0))
			sfx.play("power")
		Items.STAR:
			_item_score(5000)
			fx.popup(at, "5000", Color(1.0, 0.9, 0.4))
			sfx.play("star")


func _item_score(v: int) -> void:
	item_score += v
	add_score(v, false)


func add_score(v: int, destroy: bool) -> void:
	score += v
	if destroy:
		destroy_score += v
	if next_extend < EXTENDS.size() and score >= EXTENDS[next_extend]:
		next_extend += 1
		lives += 1
		show_msg("1UP", "", 1.5)
		sfx.play("extend")


# ------------------------------------------------------------ view

func _update_camera(dt: float) -> void:
	shake_a = maxf(0.0, shake_a - dt * 2.2)
	var s := shake_a * shake_a * 0.6
	var off := Vector3(randf_range(-s, s), 0, randf_range(-s, s))
	camera.position = cam_pos + off
	camera.look_at(CAM_TARGET + off, Vector3.UP)


func _draw_all() -> void:
	if not hide_layers.is_empty():
		fx.sprites.visible = not hide_layers.has("sprites")
		fx.debris.visible = not hide_layers.has("debris")
		for l in fx.lights:
			if hide_layers.has("lights"):
				l.visible = false
		bullets.visible = not hide_layers.has("bullets")
		shots.visible = not hide_layers.has("shots")
		items.visible = not hide_layers.has("items")
		units.visible = not hide_layers.has("units")
		for e: Array in fx.labels:
			(e[0] as Label3D).visible = not hide_layers.has("labels")
		(camera.attributes as CameraAttributesPractical).dof_blur_far_enabled = not hide_layers.has("dof")
		env.glow_enabled = not hide_layers.has("glow")
		sun.shadow_enabled = not hide_layers.has("shadow")
		player.visible = player.alive and not hide_layers.has("player")
		for isl in terrain.islands:
			isl.visible = not hide_layers.has("islands")
			for c in isl.get_children():
				if c is MultiMeshInstance3D:
					(c as Node3D).visible = not hide_layers.has("tiles")
				elif c is MeshInstance3D:
					(c as Node3D).visible = not hide_layers.has("rock")
			for c in isl.get_children():
				if c is Enemy:
					(c as Enemy).visible = not hide_layers.has("turrets")
	shots.draw()
	bullets.draw()
	items.draw()
	fx.draw()


# ------------------------------------------------------------ automation

## A simple bot: lines up under the nearest enemy, dodges bullets, picks up
## items, taps fast for Concentration and uses the Spear when bullets crowd
## in or a big target is close.
func _bot() -> Array:
	bot_frame += 1
	var pp := player.position
	var goal := Vector3(pp.x, 0, field_bottom - 5.5)
	var best: Enemy = null
	var bd := INF
	for e in enemies:
		if e.dead or e.intangible or e.armored or not e.visible or not on_field(e.hit_pos, -1.0):
			continue
		var d := absf(e.hit_pos.x - pp.x) + maxf(0.0, e.hit_pos.z - pp.z) * 2.0
		if e.kind == "container":
			d -= 6.0
		if d < bd:
			bd = d
			best = e
	if best != null:
		goal.x = best.hit_pos.x
		if best.kind == "bulwark" or best.controller != null:
			goal.z = clampf(best.hit_pos.z + 7.0, field_top + 6.0, field_bottom - 3.0)
	# items
	for k in items.n:
		if items.kind[k] != Items.ENERGY or items.pos[k].distance_to(pp) < 5.0:
			if items.pos[k].z < pp.z + 1.0 and items.pos[k].z > field_top + 3.0:
				goal = items.pos[k]
				break
	var steer := goal - pp
	steer.y = 0.0
	if steer.length() > 1.0:
		steer = steer.normalized()
	# dodge
	var push := Vector3.ZERO
	for b in bullets.n:
		var d := pp - bullets.pos[b]
		d.y = 0.0
		var dist := d.length()
		if dist < 3.2 and dist > 0.01:
			var v := bullets.vel[b]
			var closing := -d.normalized().dot(v.normalized())
			if closing > 0.2:
				var side := Vector3(-v.z, 0, v.x).normalized()
				if side.dot(d) < 0.0:
					side = -side
				push += side * (3.2 - dist) * 1.4 + d.normalized() * (3.2 - dist) * 0.4
	for e in enemies:
		if e.dead or not e.ram or e.intangible:
			continue
		var d := pp - e.hit_pos
		d.y = 0.0
		var dist := d.length()
		var safe := e.radius + 2.2
		if dist < safe and dist > 0.01:
			push += d.normalized() * (safe - dist) * 1.5
	var mv := steer + push * 1.2
	var m2 := Vector2(mv.x, mv.z)
	if m2.length() > 1.0:
		m2 = m2.normalized()
	var tap := bot_frame % 8 == 0
	var hold := true
	var near := bullets.count_near(pp, 3.0)
	var side := false
	if player.spear_cd <= 0.0:
		if near >= 4 or (best != null and best.radius >= 1.4 and absf(best.hit_pos.x - pp.x) < 2.5 and best.hit_pos.z > pp.z - Player.SPEAR_LEN) or player.energy >= 60.0:
			side = true
	return [m2, tap, hold, side]


func _automation(dt: float) -> void:
	if capture_dir == "" and not log_status and quit_after < 0.0:
		return
	capture_t += dt
	if capture_t >= capture_every:
		capture_t = 0.0
		if log_status:
			print("t=%.1f state=%d wave=%d/%d phase=%s score=%d lives=%d lvl=%d energy=%.0f conc=%.2f enemies=%d bullets=%d items=%d islands=%d tiles=%d fps=%d" % [
				play_t, state, (stage.wi + 1) if stage else 0, stage.wave_count() if stage else 0, stage.phase if stage else "-",
				score, lives, player.level, player.energy, player.conc, enemies.size(), bullets.n, items.n,
				terrain.islands.size(), terrain.tiles_alive(), Engine.get_frames_per_second()])
		if capture_dir != "":
			var img := get_viewport().get_texture().get_image()
			img.save_png("%s/shot_%04d.png" % [capture_dir, int(play_t * 10.0)])
	if quit_after > 0.0 and play_t >= quit_after:
		print("QUIT score=%d t=%.1f" % [score, stage_t])
		get_tree().quit()


## Debug view (--gallery=1: units and items, 2: the boss, 3: islands only):
## models laid out on the play plane, turning slowly.
func _build_gallery() -> void:
	hud.visible = false
	terrain.spawning = gallery == 3
	var row := func(names: Array, z: float, gap: float) -> void:
		for i in names.size():
			var m := MeshInstance3D.new()
			m.mesh = Vox.get_mesh(names[i])
			m.position = Vector3((i - (names.size() - 1) * 0.5) * gap, 0, z)
			m.set_meta("spin", true)
			units.add_child(m)
	if gallery == 1:
		row.call(["ship0", "ship1", "ship2", "power", "star", "energy"], -9.0, 4.5)
		row.call(["dart", "swirl", "rammer", "container", "turret_base", "turret_head"], -3.0, 4.5)
		row.call(["bulwark", "boss_pod", "rock_l", "rock_s", "tile0", "tile1", "tile2"], 4.0, 4.6)
		for k in 4:
			var m := MeshInstance3D.new()
			m.mesh = Vox.get_mesh("lazaro_piece")
			m.rotation.y = -k * PI / 2.0
			m.position = Vector3(-11, 0, 10.5) + Vector3(0.95, 0, 0.95).rotated(Vector3.UP, -k * PI / 2.0) * 1.15
			units.add_child(m)
	elif gallery == 2:
		for n in ["boss_hull", "boss_eye"]:
			var m := MeshInstance3D.new()
			m.mesh = Vox.get_mesh(n)
			m.position = Vector3(0, 0 if n == "boss_hull" else -0.4, -2)
			units.add_child(m)
		for k in 4:
			var m := MeshInstance3D.new()
			m.mesh = Vox.get_mesh("boss_pod")
			m.position = Vector3(0, 0, -2) + Boss.POD_OFF[k]
			units.add_child(m)


func _gallery_tick(dt: float) -> void:
	for c in units.get_children():
		if c.has_meta("spin"):
			(c as Node3D).rotation.y += dt * 0.4
