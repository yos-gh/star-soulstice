class_name Player
extends Node3D
## The player ship on the play plane (y = 0, +z = down-screen).
##
## Main shot: every press fires a volley at once; holding fires 12 volleys/s
## automatically. Pressing fast builds Concentration, which multiplies shot
## damage up to x4 (about 6 presses/s keeps it full); auto fire never builds
## it, and it drains when you stop tapping.
##
## Forms (Star Soldier style): 0 = 2 forward shots; 1 = faster fire, +1 rear
## shot, faster ship; 2 = 3-way forward + 2-way rear and a one-hit shield.
##
## Side arm: the Spear (short, strong forward blade + an aura that erases
## nearby bullets, 4 s cooldown) launches homing lasers from the rear at the
## same time, one per 10 energy (max 8).

const HIT_R := 0.32
const ENERGY_MAX := 80.0
const ENERGY_PER_HOMING := 10.0
const MAX_HOMING := 8
const CONC_MAX_MUL := 4.0
const CONC_FULL_RATE := 6.0  # presses per second for a full gauge
const CONC_MIN_RATE := 1.5
const CONC_RISE := 3.0
const CONC_FALL := 0.9
const TAP_GAP := 0.045
const AUTO_RATE := [9.0, 12.0, 12.0]
const SPEED := [8.5, 11.0, 11.0]
const SPEAR_CD := 4.0
const SPEAR_TIME := 0.42
const SPEAR_LEN := 12.5
const SPEAR_HW := 1.5
const SPEAR_R := 3.6
const SPEAR_DPS := 140.0
const SHOT_SPEED := 44.0

var game: Game
var level := 0
var shield := false
var alive := false
var invuln := 0.0
var entering := 0.0
var energy := 0.0
var conc := 0.0
var taps := PackedFloat32Array()
var fire_cd := 0.0
var spear_cd := 0.0
var spear_t := 0.0
var bank := 0.0
var bounds_x := 12.0
var bounds_z0 := -10.0
var bounds_z1 := 10.0
var clock := 0.0

var model: MeshInstance3D
var flame: MeshInstance3D
var lance: MeshInstance3D
var aura: MeshInstance3D
var shield_fx: MeshInstance3D
var lance_mat: ShaderMaterial
var aura_mat: ShaderMaterial
var shield_mat: ShaderMaterial


func _ready() -> void:
	model = MeshInstance3D.new()
	add_child(model)
	lance_mat = ShaderMaterial.new()
	lance_mat.shader = load("res://shaders/spear.gdshader")
	lance_mat.render_priority = 2
	lance = MeshInstance3D.new()
	var lm := PlaneMesh.new()
	lm.size = Vector2(1, 1)
	lm.material = lance_mat
	lance.mesh = lm
	lance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lance.scale = Vector3(SPEAR_HW * 2.4, 1, SPEAR_LEN)
	lance.position = Vector3(0, 0.6, -SPEAR_LEN * 0.5 - 0.4)
	lance.visible = false
	add_child(lance)
	aura_mat = ShaderMaterial.new()
	aura_mat.shader = load("res://shaders/aura.gdshader")
	aura_mat.render_priority = 2
	aura = MeshInstance3D.new()
	var am := PlaneMesh.new()
	am.size = Vector2(1, 1)
	am.material = aura_mat
	aura.mesh = am
	aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	aura.scale = Vector3.ONE * SPEAR_R * 2.0
	aura.position.y = 0.5
	aura.visible = false
	add_child(aura)
	shield_mat = ShaderMaterial.new()
	shield_mat.shader = aura_mat.shader
	shield_mat.set_shader_parameter("tint", Color(0.4, 0.6, 1.0))
	shield_mat.set_shader_parameter("power", 0.45)
	shield_mat.set_shader_parameter("ripples", 0.0)
	shield_mat.render_priority = 2
	shield_fx = MeshInstance3D.new()
	var sm := PlaneMesh.new()
	sm.size = Vector2(1, 1)
	sm.material = shield_mat
	shield_fx.mesh = sm
	shield_fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shield_fx.scale = Vector3.ONE * 2.8
	shield_fx.position.y = 0.3
	shield_fx.visible = false
	add_child(shield_fx)
	set_level(0)


func set_level(l: int) -> void:
	level = clampi(l, 0, 2)
	shield = level >= 2
	model.mesh = Vox.get_mesh("ship%d" % level)


func reset_at(p: Vector3) -> void:
	position = p
	alive = true
	visible = true
	set_level(0)
	conc = 0.0
	taps.clear()
	fire_cd = 0.0
	spear_cd = 0.0
	spear_t = 0.0
	bank = 0.0


func shot_mul() -> float:
	return 1.0 + (CONC_MAX_MUL - 1.0) * conc


func homing_ready() -> int:
	return mini(MAX_HOMING, int(energy / ENERGY_PER_HOMING))


func tick(dt: float, move: Vector2, tap: bool, hold: bool, side: bool) -> void:
	clock += dt
	invuln = maxf(0.0, invuln - dt)
	spear_cd = maxf(0.0, spear_cd - dt)
	spear_t = maxf(0.0, spear_t - dt)
	fire_cd -= dt
	if entering > 0.0:
		entering -= dt
		position.z -= 9.0 * dt
		move = Vector2.ZERO
		tap = false
		hold = false
		side = false
	else:
		var v: Vector2 = move * SPEED[level]
		position.x = clampf(position.x + v.x * dt, -bounds_x, bounds_x)
		position.z = clampf(position.z + v.y * dt, bounds_z0, bounds_z1)
		var w := game.half_width_at(position.z) - 0.8
		position.x = clampf(position.x, -w, w)
	bank = move_toward(bank, -move.x * 0.5, dt * 4.0)
	model.rotation = Vector3(0, 0, bank)
	# shot
	if tap:
		taps.push_back(clock)
		if fire_cd <= 0.0 or fire_cd < 1.0 / AUTO_RATE[level] - TAP_GAP:
			_volley()
			fire_cd = 1.0 / AUTO_RATE[level]
	elif hold and fire_cd <= 0.0:
		_volley()
		fire_cd = 1.0 / AUTO_RATE[level]
	while not taps.is_empty() and taps[0] < clock - 1.0:
		taps.remove_at(0)
	var target := clampf((taps.size() - CONC_MIN_RATE) / (CONC_FULL_RATE - CONC_MIN_RATE), 0.0, 1.0)
	if target > conc:
		conc = move_toward(conc, target, CONC_RISE * dt)
	else:
		conc = move_toward(conc, target, CONC_FALL * dt)
	# side arm
	if side and spear_cd <= 0.0:
		spear_t = SPEAR_TIME
		spear_cd = SPEAR_CD
		var n := homing_ready()
		energy -= n * ENERGY_PER_HOMING
		game.on_spear(n)
	_visuals()


func _volley() -> void:
	var m := shot_mul()
	var p := position
	var fwd := Vector3(0, 0, -1)
	var back := Vector3(0, 0, 1)
	match level:
		0:
			game.shots.fire(p + Vector3(-0.32, 0, -0.7), fwd, m)
			game.shots.fire(p + Vector3(0.32, 0, -0.7), fwd, m)
		1:
			game.shots.fire(p + Vector3(-0.35, 0, -0.7), fwd, m)
			game.shots.fire(p + Vector3(0.35, 0, -0.7), fwd, m)
			game.shots.fire(p + Vector3(0, 0, 0.8), back, m)
		_:
			game.shots.fire(p + Vector3(0, 0, -0.8), fwd, m)
			game.shots.fire(p + Vector3(-0.4, 0, -0.6), fwd.rotated(Vector3.UP, deg_to_rad(18.0)), m)
			game.shots.fire(p + Vector3(0.4, 0, -0.6), fwd.rotated(Vector3.UP, deg_to_rad(-18.0)), m)
			game.shots.fire(p + Vector3(-0.25, 0, 0.8), back.rotated(Vector3.UP, deg_to_rad(-30.0)), m)
			game.shots.fire(p + Vector3(0.25, 0, 0.8), back.rotated(Vector3.UP, deg_to_rad(30.0)), m)
	game.sfx.play("shot")


func _visuals() -> void:
	var blink := invuln > 0.0 and int(clock * 20.0) % 2 == 0
	model.visible = not blink
	var on := spear_t > 0.0
	lance.visible = on
	aura.visible = on
	if on:
		var f := spear_t / SPEAR_TIME
		var pw := clampf(f * 3.0, 0.0, 1.0) * (0.8 + 0.2 * sin(clock * 60.0))
		lance_mat.set_shader_parameter("power", pw)
		aura_mat.set_shader_parameter("power", pw)
		aura.scale = Vector3.ONE * SPEAR_R * 2.0 * (1.15 - 0.15 * f)
	shield_fx.visible = shield and not blink
	if shield:
		shield_mat.set_shader_parameter("power", 0.35 + 0.1 * sin(clock * 5.0))
