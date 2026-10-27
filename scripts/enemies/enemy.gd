class_name Enemy
extends Node3D
## One enemy, or one part of a big enemy run by a `controller` (a BossBase).
## Air units fly on the play plane; ground units (turrets) sit on islands and
## are hit through their projection onto the plane (`hit_pos`).
##
## Each kind is a script in scripts/enemies/ that extends this one and is
## listed in EnemyKinds. It sets its stats in _init_kind(), adds any extra
## meshes in _build() and flies in _behave(dt); `p` holds the spawn params
## (see Formations). Its INFO constant tells the stage, the bot and the
## viewer what it is:
##   name      shown in the viewer
##   category  small (formation fighters), medium (mid-size), ground,
##             carrier (drops a power-up), hazard (drifting debris), part
##   desc      one line for the viewer
##   demos     [[label, formation, args], ...] for the viewer: a Formations
##             method and its arguments ("ground" = on a deck section)
##   stage     (optional) the stage whose scenery the viewer shows it over,
##             for a kind no wave lists (the stage 3 rocks)

var game: Game
var kind := ""
var category := "small"
var mesh_name := ""
var hp := 1.0
var max_hp := 1.0
var radius := 0.8
var score := 100
var energy_drop := 2.0
var blast := 1.0
var debris_col := Models.CRIMSON  # colour of the voxel debris when it blows up
var counts := true
var ground := false
var armored := false
var intangible := false
var ram := true
var drops_power := false
var leaves := true
var solid := false  # a wall on the plane (giant rock): stops enemy bullets, shoves the ship aside
var lock := true  # homing lasers may pick it
var shootable := true  # false: shots, the Spear and homing pass by it (a ram-only zone: BEHEMOTH's dozer blade)
var half_ext := Vector2.ZERO  # a wall hit as a box (half width x, half depth z) instead of a circle (the stage 4 barriers)
var brake := 0.0  # while it stands on the screen (or about to), the scroll slows to this (0 = never): barriers to break
var marked := false  # its charges' MOVE warnings mark a line the autopilot keeps out of
var entered := false
var dead := false
var controller: Object = null
var sunk := false  # part of a defeated boss's wreck, drawn under the explosions (no more flashes)
var hit_pos := Vector3.ZERO
var vel := Vector3.ZERO
var t := 0.0
var p := {}
var flash := 0.0
var fire_t := 0.0
var step := 0
var fired := false
var model: MeshInstance3D
var extra: Array[MeshInstance3D] = []  # more meshes that flash with the model
var tint := Color(0, 0, 0)  # extra overlay colour (warnings), added to the hit flash
var warn_t := 0.0  # telegraph: seconds until the warned attack
var warn_dur := 0.0
var warn_col := Color(0, 0, 0)

const WINDUP_SHOT := 0.5  # telegraph time before unbreakable shots
const WINDUP_MOVE := 0.6  # before charges
var overlay_key := -1

static var _overlays := {}


func setup(g: Game, k: String, params: Dictionary) -> void:
	game = g
	kind = k
	p = params
	mesh_name = k
	category = EnemyKinds.info(k).get("category", "small")
	_init_kind()
	if debris_col == Models.CRIMSON:
		debris_col = Models.body_col(mesh_name, debris_col)
	max_hp = hp
	if mesh_name != "":
		model = MeshInstance3D.new()
		model.mesh = Vox.get_mesh(mesh_name)
		add_child(model)
	_build()


## Stats: hp, radius, score, energy_drop, blast, flags, mesh_name.
func _init_kind() -> void:
	pass


## Extra meshes (after the model is in place); see add_mesh.
func _build() -> void:
	pass


## Movement and attacks, every tick.
func _behave(_dt: float) -> void:
	pass


## How far plane point p lies outside the hit shape (below 0: inside):
## the circle, or the box of a wall.
func gap_to(p: Vector3) -> float:
	var d := Vector2(p.x - hit_pos.x, p.z - hit_pos.z)
	if half_ext == Vector2.ZERO:
		return d.length() - radius
	var q := Vector2(absf(d.x) - half_ext.x, absf(d.y) - half_ext.y)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)


## Adds a mesh that takes the hit flash and telegraph pulse with the model.
func add_mesh(name: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = Vox.get_mesh(name)
	add_child(m)
	extra.append(m)
	return m


func face(v: Vector3) -> void:
	if v.length_squared() > 0.0001:
		rotation.y = atan2(-v.x, -v.z)


func tick(dt: float) -> void:
	t += dt
	flash = maxf(0.0, flash - dt * 7.0)
	warn_t = maxf(0.0, warn_t - dt)
	_behave(dt)
	hit_pos = game.to_plane(global_position + Vector3(0, 0.45, 0)) if ground else position
	if not entered and game.on_field(hit_pos, -0.6):
		entered = true
	_shade()


func _shade() -> void:
	if model == null or sunk:
		return
	# quantised so a handful of shared overlay materials cover every case
	var c := Color(1.0, 0.85, 0.7) * (flash * 0.85) + tint
	if warn_t > 0.0:
		# telegraph: a warm pulse that quickens as the attack nears
		var f := 1.0 - warn_t / maxf(warn_dur, 0.01)
		var pulse := 0.5 + 0.5 * sin(warn_t * lerpf(18.0, 40.0, f))
		c += warn_col * (0.25 + 0.5 * f) * pulse
	var q := Vector3i(int(c.r * 8.0 + 0.5), int(c.g * 8.0 + 0.5), int(c.b * 8.0 + 0.5))
	var key := (q.x * 64 + q.y) * 64 + q.z
	if key == overlay_key:
		return
	overlay_key = key
	var mat: Material = null
	if key != 0:
		if not _overlays.has(key):
			var m := ShaderMaterial.new()
			m.shader = preload("res://shaders/flash.gdshader")
			m.set_shader_parameter("col", Color(q.x / 8.0, q.y / 8.0, q.z / 8.0))
			_overlays[key] = m
		mat = _overlays[key]
	model.material_overlay = mat
	for m in extra:
		m.material_overlay = mat
