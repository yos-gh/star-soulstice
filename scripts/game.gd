class_name Game
extends Node3D
## STAR SOULSTICE — prototype. A modern homage to Star Soldier:
## no air/ground split, everything breakable, tap-fire Concentration, and an
## energy loop (collect energy -> release it as homing lasers with the Spear).
##
## Everything that collides lives on the play plane y = 0 (+z = down-screen).
## Islands float below at GROUND_Y; their tiles and turrets are hit through
## their projection onto the plane along the view ray, so what you see is
## what you hit.
##
## Game owns the world (camera, terrain, units, bullets, effects) and the
## rules (scoring, hits, lives). What a stage contains is data: StageDef
## scripts listed in Stages, enemy kinds in EnemyKinds, bosses in Bosses,
## models in Models (see docs/architecture.md). The viewer (Viewer) runs
## the same world without a stage.
##
## Command-line options (after "--"):
##   --autoplay        a simple bot plays
##   --god             the player cannot die
##   --stage=N         begin at stage N
##   --start=N|mid|boss|boss2  begin at wave N, the mid-boss, the boss or
##                     the second boss (the last stage's)
##   --capture=DIR     save a screenshot every --capture-every seconds (default 3)
##   --quit-after=S    quit after S seconds of play
##   --quit-on-clear   quit when the stage ends (clear or game over)
##   --log             print status every --capture-every seconds
##   --mute            no sound
##   --viewer[=CAT[:N]]  open the viewer (at category CAT, item N)
##   --viewer-tour[=S] show every viewer item for S seconds (default 2.5),
##                     saving one screenshot each into --capture, then quit
##   --press=T:ACTION[:HOLD],...  press input actions at T seconds (tests)

enum State { TITLE, PLAY, CLEAR, GAME_OVER, VIEWER }
enum Warn { SHOT, MOVE }
const WARN_COL := [Color(0.9, 0.85, 0.75), Color(1.0, 1.0, 1.0)]  # body pulse

const DT := 1.0 / 60.0
const GROUND_Y := -3.0
const SCROLL := 12.0
const BOSS_SCROLL := 7.0
const CAM_PITCH := 66.0
const CAM_DIST := 34.0
const CAM_FOV := 40.0
const CAM_TARGET := Vector3(0, 0, 0.0)
const START_LIVES := 3
const RESPAWN_WAIT := 0.9  # after a miss until the next ship flies in (was 1.8)
const EXTENDS := [200000, 600000, 1200000]
## (The time bonus is per stage: StageDef.bonus_t / bonus_rate.)
## Item scoring (see docs/scoring.md)
const ENERGY_GAIN := 0.5  # homing energy per unit of energy picked up
const ENERGY_SCORE := 2  # points per unit of energy
const POWER_UP_SCORE := 1000  # power-up taken in Form I / II
const POWER_SCORE := 5000  # power-up taken in Form III (chained)
const STAR_SCORE := 1000  # hidden star (chained)
const CHAIN_MAX := 8
const PUSH_R := 0.75  # the ship's body, for being shoved by solid rocks

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
## a ground boss holds the scroll (it brings the ground to a stop over
## itself, then lets it go): the speed it wants, or -1 (see _tick_play)
var scroll_hold := -1.0
var respawn_t := 0.0
var deaths := 0
var kills := 0
var tiles_broken := 0
var energy_got := 0.0
var star_mul := 1  # star chain multiplier, reset each stage
var stars_got := 0
var powers_got := 0
var powers_dropped := 0
var powers_taken := 0
var power_mul := 1  # Form III power-up chain, carried over, reset by a miss
var homing_fired := 0
var spears := 0
var clear_t := -1.0
var boss_dmg := {}  # boss name -> {shot, spear, homing}: damage dealt (for tuning, see log_tiles)

var camera: Camera3D
var ground_blur: MeshInstance3D
var cam_pos := Vector3.ZERO
var shake_a := 0.0
var env: Environment
var sun: DirectionalLight3D
var terrain: Terrain
var backdrop: Backdrop
var units: Node3D
var player: Player
var shots: Shots
var bullets: Bullets
var items: Items
var fx: Fx
var sfx: Sfx
var hud: Hud
var stage: Stage
var stage_def: StageDef
var stage_no := 1
var title_def: StageDef  # the first stage: the title screen flies over it
var enemies: Array[Enemy] = []
var bosses: Array[BossBase] = []  # mid-bosses and bosses on the field
var warnings: Array = []  # {node, t, dur, kind, r, to} (see warn)
var delayed: Array = []  # {node, t, fn} (see warn_then)
var bot: Bot
var viewer: Viewer
var title_sel := 0  # title menu: 0 game start, 1 viewer

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
var frames := 0
var hide_layers := PackedStringArray()  # debug: --hide=sprites,debris,lights,bullets,shots,items,units,terrain
var palette_name := "fortress"  # --palette=NAME (see Palette)
var start_stage := 1  # --stage=N
var viewer_at := ""  # --viewer=CAT[:N]
var viewer_tour := 0.0  # --viewer-tour=S
var presses: Array = []  # --press: [time, action, hold], in time order
var held: Array = []  # [release time, action]


func _ready() -> void:
	seed(12345)
	_parse_args()
	Controls.setup()
	Input.joy_connection_changed.connect(Controls.on_joy_changed)
	_setup_world()
	_enter_title()
	if viewer_at != "" or viewer_tour > 0.0:
		_enter_viewer()
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
		elif a.begins_with("--stage="):
			start_stage = clampi(int(a.get_slice("=", 1)), 1, Stages.count())
		elif a.begins_with("--viewer-tour"):
			viewer_tour = float(a.get_slice("=", 1)) if a.contains("=") else 2.5
		elif a.begins_with("--viewer"):
			viewer_at = a.get_slice("=", 1) if a.contains("=") else "-"
		elif a.begins_with("--press="):
			for s in a.get_slice("=", 1).split(","):
				var parts := s.split(":")
				presses.append([float(parts[0]), parts[1], float(parts[2]) if parts.size() > 2 else 0.0])
			presses.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		elif a.begins_with("--capture="):
			capture_dir = a.get_slice("=", 1)
			DirAccess.make_dir_recursive_absolute(capture_dir)
			# keep Godot from importing the screenshots
			var root := capture_dir.get_slice("/", 0)
			if not FileAccess.file_exists(root + "/.gdignore"):
				FileAccess.open(root + "/.gdignore", FileAccess.WRITE)
		elif a.begins_with("--capture-every="):
			capture_every = float(a.get_slice("=", 1))
		elif a.begins_with("--quit-after="):
			quit_after = float(a.get_slice("=", 1))
		elif a == "--log":
			log_status = true
		elif a == "--mute":
			AudioServer.set_bus_mute(0, true)
		elif a.begins_with("--palette="):
			palette_name = a.get_slice("=", 1)
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
	add_child(camera)
	camera.current = true
	var pitch := deg_to_rad(CAM_PITCH)
	cam_pos = CAM_TARGET + Vector3(0, sin(pitch), cos(pitch)) * CAM_DIST
	camera.look_at_from_position(cam_pos, CAM_TARGET, Vector3.UP)
	_measure_field()
	# soft focus for everything below the play plane (see groundblur.gdshader)
	ground_blur = MeshInstance3D.new()
	var quad := QuadMesh.new()
	var bmat := ShaderMaterial.new()
	bmat.shader = load("res://shaders/groundblur.gdshader")
	bmat.render_priority = -128
	quad.material = bmat
	ground_blur.mesh = quad
	ground_blur.extra_cull_margin = 16384.0
	ground_blur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground_blur.position = Vector3(0, 0, -3.0)
	camera.add_child(ground_blur)

	title_def = Stages.create(1)
	terrain = Terrain.new()
	terrain.game = self
	add_child(terrain)
	terrain.use_stage(title_def)
	backdrop = Backdrop.new()
	backdrop.game = self
	add_child(backdrop)
	backdrop.use(title_def.backdrop)
	Palette.apply(self, palette_name)
	bot = Bot.new(self)
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
	viewer = Viewer.new()
	viewer.game = self
	add_child(viewer)
	viewer.panel = ViewerPanel.new()
	viewer.panel.viewer = viewer
	viewer.panel.visible = false
	layer.add_child(viewer.panel)


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
	return combat_on() and player.alive and on_field(p, -0.8) and p.z < player.position.z - 2.0


## Enemies attack only during play (and in the viewer, unless it says no).
func combat_on() -> bool:
	return state == State.PLAY or (state == State.VIEWER and viewer.fire_on)


## Where a charge from `from` through `through` (the ship) meets the bottom
## edge of the screen (straight down if the ship is not below it): the end
## of a marked line for a thrown or slung rock.
func line_to_bottom(from: Vector3, through: Vector3) -> Vector3:
	var d := Vector3(through.x - from.x, 0, through.z - from.z)
	if d.z < 1.0:
		d = Vector3(0, 0, 1)
	d = d.normalized()
	var to := from + d * ((field_bottom + 1.0 - from.z) / d.z)
	return Vector3(clampf(to.x, -hw_bottom - 2.0, hw_bottom + 2.0), 0, to.z)


## The scroll speed the waves want: the current area's own (`scroll` in
## StageDef.areas, stage 5's orbit) or the stage's.
func area_scroll() -> float:
	if stage_def == null:
		return SCROLL
	if stage != null:
		return float((stage_def.areas.get(stage.area, {}) as Dictionary).get("scroll", stage_def.scroll))
	return stage_def.scroll


## The stage's difficulty for small fighters and turrets (StageDef): how
## many times as often they fire, and whether the slow ones start early.
func zako_fire() -> int:
	return stage_def.zako_fire if stage_def != null else 1


func zako_early() -> bool:
	return stage_def != null and stage_def.zako_early


# ------------------------------------------------------------ states

func _enter_title() -> void:
	if quit_after > 0.0 and play_t > 0.0:
		get_tree().quit()
		return
	state = State.TITLE
	state_t = 0.0
	clear_field()
	player.visible = false
	player.alive = false
	scroll_speed = SCROLL
	terrain.use_stage(title_def)
	backdrop.use(title_def.backdrop)
	terrain.reset(false)
	terrain.spawning = true
	terrain.turrets = false


func _start_game() -> void:
	score = 0
	lives = START_LIVES
	next_extend = 0
	power_mul = 1  # per game (carried between stages)
	play_t = 0.0
	_start_stage(start_stage, true)


## Starts stage n. A new game puts the ship in Form I with some energy;
## after a clear the ship keeps its form, shield and energy.
func _start_stage(n: int, new_game: bool) -> void:
	state = State.PLAY
	state_t = 0.0
	stage_t = 0.0
	destroy_score = 0
	item_score = 0
	bonus = 0
	kills = 0
	deaths = 0
	tiles_broken = 0
	energy_got = 0.0
	star_mul = 1  # per stage
	stars_got = 0
	powers_got = 0
	powers_dropped = 0
	powers_taken = 0
	homing_fired = 0
	spears = 0
	clear_t = -1.0
	boss_dmg.clear()
	clear_field()
	stage_no = n
	stage_def = Stages.create(n)
	terrain.use_stage(stage_def)
	backdrop.use(stage_def.backdrop)
	backdrop.set_area(stage_def.first_area, true)
	terrain.reset(true)
	stage = Stage.new(self, stage_def)
	if start_at != "" and new_game:
		stage.start_at(start_at)
	scroll_speed = stage_def.scroll
	var keep := [player.level, player.shield, player.energy]
	player.reset_at(Vector3(0, 0, field_bottom + 2.0))
	player.entering = 0.9
	player.enter_speed = 9.0
	player.invuln = 2.5
	player.energy = 20.0
	if not new_game:
		player.set_level(keep[0])
		player.shield = keep[1]
		player.energy = keep[2]
	sfx.play("start")
	show_msg(stage_def.title, stage_def.subtitle, 2.0)
	print("START at=%s" % start_at if n == 1 else "START stage=%d" % n)


func clear_field() -> void:
	for e: Enemy in enemies.duplicate():
		remove_enemy(e)
	for c in units.get_children():
		c.queue_free()
	for b in bosses:
		b.queue_free()
	bosses.clear()
	bullets.n = 0
	shots.clear()
	items.clear()
	items.vacuum = false
	fx.clear()
	warnings.clear()
	delayed.clear()
	msg_t = 0.0
	scroll_hold = -1.0


func _respawn() -> void:
	var keep := player.energy * 0.5
	player.reset_at(Vector3(0, 0, field_bottom + 2.0))
	# back in half the time it used to take (yos): twice as fast up to the
	# same spot
	player.entering = 0.45
	player.enter_speed = 18.0
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


## Called by a boss when it is gone for good; the stage boss clears the
## stage, unless a second boss follows it (StageDef.boss2).
func boss_destroyed(b: BossBase) -> void:
	if state == State.VIEWER:
		viewer.on_boss_destroyed(b)
		return
	if not b.final:
		return
	if stage != null and stage.next_boss():
		return
	stage_cleared(stage_def.clear_note)


## The stage is over (its boss destroyed; a stage still without its boss
## ends after its last wave, with `sub` under STAGE CLEAR).
func stage_cleared(sub := "") -> void:
	clear_t = stage_t
	bonus = maxi(0, int((stage_def.bonus_t - stage_t) * stage_def.bonus_rate / 100.0) * 100)
	state = State.CLEAR
	state_t = 0.0
	player.invuln = 99.0
	show_msg("STAGE CLEAR", sub, 3.0)
	sfx.play("clear")
	print("CLEAR t=%.1f destroy=%d items=%d bonus=%d deaths=%d kills=%d tiles=%d stars=%d power3=%d power_drop=%d power_taken=%d" % [stage_t, destroy_score, item_score, bonus, deaths, kills, tiles_broken, stars_got, powers_got, powers_dropped, powers_taken])
	if log_status:
		log_tiles()


## Tile density for tuning: the tiles that came in per area and per second
## (Terrain.tally), and for the whole stage.
func log_tiles() -> void:
	var n := 0
	var secs := 0.0
	for a: String in terrain.tally:
		var tl: Array = terrain.tally[a]
		n += int(tl[0])
		secs += float(tl[1])
		print("TILES area=%s in=%d t=%.1f per_s=%.1f" % [a, tl[0], tl[1], float(tl[0]) / maxf(float(tl[1]), 0.01)])
	print("TILES stage=%d in=%d t=%.1f per_s=%.1f" % [stage_no, n, secs, float(n) / maxf(secs, 0.01)])
	for who: String in boss_dmg:
		var t: Dictionary = boss_dmg[who]
		var sum := maxf(float(t["shot"]) + float(t["spear"]) + float(t["homing"]), 0.01)
		print("DMG boss=%s total=%d shot=%d%% spear=%d%% homing=%d%%" % [who, int(sum), int(100.0 * t["shot"] / sum), int(100.0 * t["spear"] / sum), int(100.0 * t["homing"] / sum)])


func show_msg(m: String, sub := "", t := 2.0, warning := false) -> void:
	msg = m
	msg_sub = sub
	msg_t = t
	msg_warning = warning


func shake(a: float) -> void:
	shake_a = maxf(shake_a, a)


## A boss's or mid-boss's last blast over the whole screen (`k`: 1 = the
## stage boss, about 0.7 = a mid-boss), with a white flash of the screen.
## It stays under the units and bullets like every explosion (Fx.finale).
func big_blast(at: Vector3, k: float, body: Color) -> void:
	fx.finale(at, k, body)
	flash_a = maxf(flash_a, 0.3 + 0.3 * k)


# ------------------------------------------------------------ main loop

func _physics_process(_delta: float) -> void:
	var dt := DT
	time += dt
	frames += 1
	if not presses.is_empty() or not held.is_empty():
		_scripted_input()
	if Controls.notice_t > 0.0:
		Controls.notice_t -= dt
	if Input.is_action_just_pressed("palette"):
		var pn := Palette.next(self)
		Controls.notice = "PALETTE : " + pn.to_upper()
		Controls.notice_t = 2.0
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
			backdrop.tick(dt, SCROLL)
			terrain.tick(dt, SCROLL)
			fx.tick(dt, scroll_speed)
			if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("down"):
				title_sel = 1 - title_sel
				sfx.play("cursor")
			# left / right on GAME START picks the stage to begin at
			var ds := int(Input.is_action_just_pressed("right")) - int(Input.is_action_just_pressed("left"))
			if title_sel == 0 and ds != 0 and Stages.count() > 1:
				start_stage = posmod(start_stage - 1 + ds, Stages.count()) + 1
				sfx.play("cursor")
			if Input.is_action_just_pressed("confirm") and state_t > 0.3:
				if title_sel == 1:
					_enter_viewer()
				else:
					_start_game()
		State.VIEWER:
			viewer.tick(dt)
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
					return
				if stage_no < Stages.count():
					_start_stage(stage_no + 1, false)
				else:
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


## --press: presses (and later releases) input actions as if by hand.
func _scripted_input() -> void:
	var i := 0
	while i < held.size():
		if time >= float(held[i][0]):
			Input.action_release(held[i][1])
			held.remove_at(i)
			continue
		i += 1
	while not presses.is_empty() and time >= float(presses[0][0]):
		var p: Array = presses.pop_front()
		Input.action_press(p[1])
		held.append([time + maxf(float(p[2]), DT * 0.5), p[1]])


func _input(event: InputEvent) -> void:
	Controls.note_event(event)
	if state == State.VIEWER:
		viewer.on_input(event)


func _enter_viewer() -> void:
	paused = false
	clear_field()
	state = State.VIEWER
	state_t = 0.0
	viewer.enter(viewer_at, viewer_tour)


## Back from the viewer to the title screen.
func leave_viewer() -> void:
	viewer.leave()
	camera.h_offset = 0.0
	_enter_title()


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
		var b := bot.think()
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
	var want_scroll := stage_def.boss_scroll if (stage != null and stage.phase != "waves") else area_scroll()
	if scroll_hold >= 0.0:
		scroll_speed = scroll_hold
	else:
		scroll_speed = move_toward(scroll_speed, want_scroll, dt * 1.5)
	tick_world(dt)


## Everything but the stage script and the ship: the ground and scenery,
## units, bosses, telegraphs, bullets, shots, items and effects, then hits.
## The viewer runs the world through this too.
func tick_world(dt: float) -> void:
	backdrop.tick(dt, scroll_speed)
	terrain.tick(dt, scroll_speed)
	for e: Enemy in enemies.duplicate():
		if is_instance_valid(e) and not e.dead and e.controller == null:
			e.tick(dt)
	for e: Enemy in enemies.duplicate():
		if is_instance_valid(e) and not e.dead and e.controller != null:
			e.tick(dt)
	for b: BossBase in bosses.duplicate():
		if is_instance_valid(b):
			b.tick(dt)
	_tick_warnings(dt)
	bullets.tick(dt)
	shots.tick(dt)
	items.tick(dt)
	fx.tick(dt, scroll_speed)
	_collide(dt)
	_cull()


# ------------------------------------------------------------ spawning

## Spawns an enemy of an EnemyKinds kind. params: x, z (default just above
## the screen), counts (toward clearing the wave), island + cell (a ground
## unit), and whatever the kind reads.
func spawn_enemy(kind: String, params := {}) -> Enemy:
	var e := EnemyKinds.create(kind)
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


## A part of a boss (`ctrl`), hit as an enemy, moved by its boss.
func spawn_part(ctrl: Object, mesh: String, radius: float) -> Enemy:
	var e := EnemyKinds.create("part")
	e.setup(self, "part", {"mesh": mesh})
	e.controller = ctrl
	e.radius = radius
	e.position = Vector3(0, 0, field_top - 10.0)
	e.hit_pos = e.position
	units.add_child(e)
	enemies.append(e)
	return e


## Spawns a Bosses kind; `final` = the stage boss (its death clears the stage).
func spawn_boss(kind: String, final := false) -> BossBase:
	var b := Bosses.create(kind)
	b.final = final
	add_child(b)
	bosses.append(b)
	b.setup(self)
	return b


func remove_boss(b: BossBase) -> void:
	bosses.erase(b)


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
		var left := terrain.hit(p, dmg)
		if left >= 0.0:
			# a broken soft tile lets a strong shot carry on
			if left > 0.01:
				shots.dmg[i] = left
			else:
				used = true
				fx.spark(p + Vector3(0, 0.3, 0), Color(0.6, 0.8, 1.0), 1, 0.25)
			sfx.play("tile")
		else:
			var sh := bullets.shoot_shell(p, 0.2, dmg)
			if sh.x != INF:
				used = true
				if sh.y > 1.5:
					# glanced off an armoured IRON ball
					fx.spark(Vector3(sh.x, 0.4, sh.z), Color(0.8, 0.7, 1.0), 1, 0.3)
					sfx.play("deflect")
				elif sh.y > 0.5:
					fx.spark(Vector3(sh.x, 0.4, sh.z), Color(0.45, 0.8, 1.0), 3, 0.35)
					add_score(10, true)
			else:
				var e := _enemy_at(p, 0.25)
				if e != null:
					_tally("shot", e, damage(e, dmg, p))
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
		if (te.gap_to(hp) < 0.5) if te.half_ext != Vector2.ZERO else d.length() < te.radius + 0.5:
			_tally("homing", te, damage(te, Shots.HOMING_DMG, hp))
			fx.sprite(hp + Vector3(0, 0.5, 0), Vector3.ZERO, 0.6, 2.2, 0.25, Color(0.5, 0.9, 1.0), 0.0)
			shots.homing_hit(h)
	# spear
	if player.alive and player.spear_t > 0.0:
		_spear(dt)
	_solids()
	# player
	if player.alive and player.entering <= 0.0 and player.invuln <= 0.0 and state == State.PLAY:
		var hit := bullets.hit_test(player.position, Player.HIT_R)
		if hit and log_status:
			print("HIT by bullet t=%.1f" % play_t)
		if not hit:
			for e in enemies:
				if e.dead or not e.ram or e.intangible or not e.visible:
					continue
				var boxed := e.half_ext != Vector2.ZERO and e.gap_to(player.position) < Player.HIT_R
				var d := e.hit_pos - player.position
				d.y = 0.0
				var r := e.radius * 0.8 + Player.HIT_R
				if boxed or (e.half_ext == Vector2.ZERO and d.length_squared() < r * r):
					hit = true
					if log_status:
						print("HIT by %s t=%.1f" % [e.kind, play_t])
					break
		if hit and not god:
			_player_hit()


## Solid things on the plane (giant rocks, `Enemy.solid`): enemy bullets
## that fly into one stop there (any kind: it is cover), and the ship is
## shoved aside instead of crashing (see Player.push_out).
func _solids() -> void:
	for e in enemies:
		if not e.solid or e.dead or e.intangible or not e.visible:
			continue
		for q in bullets.cancel_in(e.hit_pos, e.radius * 0.95):
			fx.spark(q + Vector3(0, 0.4, 0), Color(0.8, 0.74, 0.64), 1, 0.3)
		if player.alive and player.entering <= 0.0 and state != State.CLEAR:
			player.push_out(e.hit_pos, e.radius + PUSH_R)


## Where a beam on the plane from `from` toward `to` stops: at the near side
## of the first solid thing in its way (a giant rock: cover from beams as
## from bullets), else at `to`.
func solid_cut(from: Vector3, to: Vector3) -> Vector3:
	var d := Vector3(to.x - from.x, 0, to.z - from.z)
	var len := d.length()
	if len < 0.01:
		return to
	d /= len
	var best := len
	for e in enemies:
		if not e.solid or e.dead or e.intangible or not e.visible:
			continue
		var oc := Vector3(e.hit_pos.x - from.x, 0, e.hit_pos.z - from.z)
		var along := oc.dot(d)
		var h2 := oc.length_squared() - along * along
		var r2 := e.radius * e.radius
		if h2 >= r2:
			continue
		var t0 := along - sqrt(r2 - h2)
		if t0 < best and along + sqrt(r2 - h2) > 0.0:
			best = maxf(t0, 0.0)
	return Vector3(from.x + d.x * best, 0, from.z + d.z * best)


## A boss's solid part that is not a round hit zone (a hammer's ram) touched
## the ship: the same as being rammed.
func touch_player(src: String) -> void:
	if not player.alive or player.entering > 0.0 or player.invuln > 0.0 or state != State.PLAY:
		return
	if log_status:
		print("HIT by %s t=%.1f" % [src, play_t])
	if not god:
		_player_hit()


func _enemy_at(p: Vector3, r: float) -> Enemy:
	for e in enemies:
		if e.dead or e.intangible or not e.visible or not e.shootable:
			continue
		if not on_field(e.hit_pos, 0.5):
			continue
		if e.half_ext != Vector2.ZERO:
			if e.gap_to(p) < r:
				return e
			continue
		var d := e.hit_pos - p
		var rr := e.radius + r
		if d.x * d.x + d.z * d.z < rr * rr:
			return e
	return null


## Damages `e`; returns the damage that landed (0 on armour), before a
## boss rescales it.
func damage(e: Enemy, dmg: float, at: Vector3) -> float:
	if e.dead:
		return 0.0
	if e.armored:
		fx.spark(at + Vector3(0, 0.5, 0), Color(0.7, 0.8, 1.0), 1, 0.3)
		sfx.play("deflect")
		return 0.0
	var landed := dmg
	if e.controller != null:
		dmg = e.controller.on_hit(e, dmg)
	e.flash = 1.0
	fx.spark(at + Vector3(0, 0.5, 0), Color(1.0, 0.8, 0.5), 1, 0.3)
	sfx.play("hit")
	if dmg <= 0.0:
		return landed
	e.hp -= dmg
	if e.hp <= 0.0:
		kill(e)
	return landed


## Tuning: damage dealt to bosses' parts by weapon (`src`: shot, spear,
## homing), per boss (see log_tiles).
func _tally(src: String, e: Enemy, dmg: float) -> void:
	if dmg <= 0.0 or not (e.controller is BossBase):
		return
	var info: Dictionary = (e.controller as BossBase).get_script().get_script_constant_map().get("INFO", {})
	var who := str(info.get("name", "?"))
	var t: Dictionary = boss_dmg.get_or_add(who, {"shot": 0.0, "spear": 0.0, "homing": 0.0})
	t[src] += dmg


func kill(e: Enemy) -> void:
	if e.dead:
		return
	e.dead = true
	kills += 1
	add_score(e.score, true)
	var at := e.hit_pos
	if e.half_ext != Vector2.ZERO:
		# a wall: it goes up all along
		fx.wall_blast(at, e.half_ext.x - 2.0, e.blast * 0.55, Vector3(0, 0, scroll_speed * 0.4), e.debris_col)
	else:
		fx.explode(at + Vector3(0, 0.4, 0), e.blast, Vector3(0, 0, scroll_speed * 0.4), e.debris_col)
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
		powers_dropped += 1
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
		if e.dead or e.intangible or not e.visible or not e.shootable:
			continue
		var d := e.hit_pos - pp
		var in_ring := Vector2(d.x, d.z).length() < Player.SPEAR_R + e.radius
		var in_lance := absf(d.x) < Player.SPEAR_HW + e.radius and d.z < 0.0 and d.z > -Player.SPEAR_LEN - e.radius
		if e.half_ext != Vector2.ZERO:
			in_ring = e.gap_to(pp) < Player.SPEAR_R
			in_lance = absf(d.x) < Player.SPEAR_HW + e.half_ext.x and d.z - e.half_ext.y < 0.0 and d.z + e.half_ext.y > -Player.SPEAR_LEN
		if in_ring or in_lance:
			_tally("spear", e, damage(e, dmg, e.hit_pos))
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
		if e.dead or e.intangible or e.armored or not e.shootable or not e.lock or not e.visible or not on_field(e.hit_pos, -0.3):
			continue
		list.append(e)
	list.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.hit_pos.distance_squared_to(from) < b.hit_pos.distance_squared_to(from))
	return list


func nearest_target(from: Vector3) -> Object:
	var best: Enemy = null
	var bd := INF
	for e in enemies:
		if e.dead or e.intangible or e.armored or not e.shootable or not e.lock or not e.visible or not on_field(e.hit_pos, -0.3):
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
	power_mul = 1
	lives -= 1
	# the next ship comes in after RESPAWN_WAIT; the game over waits longer
	respawn_t = RESPAWN_WAIT if lives > 0 else 1.8
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
	tile_break_fx(world, t)
	sfx.play("tile_break")
	if star:
		items.spawn(at, Items.STAR, 1.0, Vector3(0, 0, -2.0))
		fx.sprite(world + Vector3(0, 0.6, 0), Vector3.ZERO, 0.5, 3.0, 0.4, Color(1.0, 0.9, 0.4), 2.0)


## Shards, smoke and a flash where tile type t broke (world = its position).
func tile_break_fx(world: Vector3, t: int) -> void:
	var c: Color = GroundModels.TILE_COL[t]
	for k in 4 + t * 2:
		fx._debris(world + Vector3(randf_range(-0.7, 0.7), 0.4, randf_range(-0.7, 0.7)), Vector3(randf_range(-3, 3), randf_range(2, 4), randf_range(-3, 3)), 0.18, c)
	fx.puff(world + Vector3(0, 0.4, 0), Vector3(0, 0, scroll_speed * 0.5), 0.8, 1.8, 0.35, Fx.SMOKE)
	fx.puff(world + Vector3(0, 0.45, 0), Vector3(0, 0, scroll_speed * 0.5), 1.2, 0.3, 0.07, Fx.FLASH)


func collect(kind: int, value: float, at: Vector3) -> void:
	match kind:
		Items.ENERGY:
			player.energy = minf(Player.ENERGY_MAX, player.energy + value * ENERGY_GAIN)
			energy_got += value * ENERGY_GAIN
			_item_score(int(round(ENERGY_SCORE * value)))
			sfx.play("energy")
		Items.POWER:
			powers_taken += 1
			if player.level < 2:
				player.set_level(player.level + 1)
				_item_score(POWER_UP_SCORE)
				show_msg("FORM %s" % ["I", "II", "III"][player.level], "", 1.0)
			else:
				if not player.shield:
					player.shield = true
				# chain: x1, x2, x4, x8 ... kept across stages, reset by a miss
				powers_got += 1
				var v := POWER_SCORE * power_mul
				_item_score(v)
				fx.popup(at, "%d" % v if power_mul == 1 else "%d x%d" % [v, power_mul], Color(0.6, 0.85, 1.0), power_mul >= 4)
				power_mul = mini(power_mul * 2, CHAIN_MAX)
			fx.shockwave(player.position + Vector3(0, 0.4, 0), 2.5, Color(0.4, 0.7, 1.0))
			sfx.play("power")
		Items.STAR:
			# chain within the stage: x1, x2, x4, x8
			stars_got += 1
			var v := STAR_SCORE * star_mul
			_item_score(v)
			fx.popup(at, "%d" % v if star_mul == 1 else "%d x%d" % [v, star_mul], Color(1.0, 0.9, 0.4), star_mul >= 4)
			star_mul = mini(star_mul * 2, CHAIN_MAX)
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
	if state == State.VIEWER:
		# the viewer's free camera; cam_pos stays the play camera, so hits
		# and the drawing of bullets on the plane do not move with it
		var v := viewer.camera_view()
		camera.position = v[0] + off
		camera.look_at(v[1] + off, Vector3.UP)
		camera.h_offset = v[2]
		return
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
		ground_blur.visible = not hide_layers.has("dof")
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

func _automation(dt: float) -> void:
	if capture_dir == "" and not log_status and quit_after < 0.0:
		return
	if state == State.VIEWER and viewer.tour > 0.0:
		return  # the tour saves its own screenshots
	capture_t += dt
	if capture_t >= capture_every:
		capture_t = 0.0
		if log_status and player.alive:
			var sp := camera.unproject_position(player.position)
			print("ship_px=%d,%d" % [int(sp.x), int(sp.y)])
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


# ------------------------------------------------------------ telegraphs

## Every dangerous attack is announced before it happens (unbreakable
## shots, charges, the mid-boss's and boss's big moves):
##   - a white lock-on reticle spins in and closes on the attacker, with a
##     fuse bar counting down and a blink just before the attack (drawn by
##     the HUD); charges and big moves get doubled corners
##   - the attacker pulses white, quickening
##   - a charge also streams chevrons toward its target
##   - a short rising tone
## Breakable shells are never announced: they are the low-threat fodder.
func warn(node: Node3D, dur: float, kind: int, radius := 1.0, to: Variant = null, sound := true, bot := true) -> void:
	warnings.append({"node": node, "t": dur, "dur": dur, "kind": kind, "r": radius, "to": to, "bot": bot})
	if node is Enemy:
		var e := node as Enemy
		e.warn_t = dur
		e.warn_dur = dur
		e.warn_col = WARN_COL[kind]
	if sound:
		sfx.play("warn")


## Announces an attack by `e`, then runs `fn` after `dur` unless `e` died.
func warn_then(e: Enemy, dur: float, kind: int, fn: Callable, to: Variant = null) -> void:
	warn(e, dur, kind, e.radius, to)
	delayed.append({"node": e, "t": dur, "fn": fn})


func _tick_warnings(dt: float) -> void:
	var i := 0
	while i < warnings.size():
		var w: Dictionary = warnings[i]
		w["t"] -= dt
		var nd = w["node"]
		if w["t"] <= 0.0 or not is_instance_valid(nd) or (nd is Enemy and (nd as Enemy).dead):
			warnings.remove_at(i)
			continue
		i += 1
	i = 0
	while i < delayed.size():
		var d: Dictionary = delayed[i]
		d["t"] -= dt
		var nd = d["node"]
		if not is_instance_valid(nd) or (nd is Enemy and (nd as Enemy).dead):
			delayed.remove_at(i)
			continue
		if d["t"] <= 0.0:
			delayed.remove_at(i)
			if combat_on():
				(d["fn"] as Callable).call()
			continue
		i += 1
