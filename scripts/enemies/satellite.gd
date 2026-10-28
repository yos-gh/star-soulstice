extends Enemy
## Orbital weapon of the planet's defence grid (stage 5, out in space): a
## satellite with no drive of its own, parked in orbit: it comes down the
## screen with the scroll and fires as it passes. Bare machinery in the
## colours of the planet's forces (oxblood and bone on greys), solar
## panels on truss arms. Two arms (params.arm), meant to be set in groups
## that close the ship in:
##   gatling  a rotary gun: announced (lock-on, the barrels spinning up),
##            then a stream of small energy rounds faster than anything
##            before it, its aim swinging after the ship (outrun it across,
##            or hide behind a rock); a gap, and again while above the ship
##   lance    a laser emitter pointing down the screen: its column is
##            marked (a thin flickering sight, then a band as wide as the
##            beam, blinking at the end), then a straight beam burns down
##            it to the bottom edge for a second, moving down with it (a
##            column the ship must leave). A rock in the way stops it.
## Rocks (solid) stop the gun's rounds too. It rams like any small craft.
## params: x, z, arm

const INFO := {
	"name": "SATELLITE", "category": "small",
	"desc": "衛星軌道兵器（ステージ 5 の宇宙）：自分では動けず、スクロールに乗って流れてきて、通りがかりに撃つ。太陽電池の翼をトラスで張った剥き出しの機械。組み合わせで自機を追い込む。gatling：予兆（ロックオン、砲身が回り出す）のあと、これまでにない速さで小さなエネルギー弾を連射し、狙いを自機へ振っていく（横へ振り切るか岩の陰へ）。間をおいて、自機より上にいるうちはもう一度。lance：真下を向いたレーザーの発射器。その列に予兆（細くちらつく照準、ビームの幅の帯、最後に点滅）を出し、まっすぐなビームを下端まで 1 秒焼く（いっしょに下へ流れる。列から出る）。岩があるとそこで止まる。岩は gatling の弾も止める。体当たりあり",
	"demos": [
		["LANCE PAIR", "sats", [0.0, [[-0.5, "lance"], [0.5, "lance"]]]],
		["GATLING", "sats", [0.0, [[0.0, "gatling"]]]],
		["GRID", "sats", [0.0, [[-0.6, "lance"], [0.6, "lance"], [0.0, "gatling", 3.0]]]],
	],
}

const LOCK_GAT := 0.55
const GAT_T := 1.3
const GAT_EVERY := 0.06
const GAT_SPEED := 9.5
const GAT_TURN := 1.1  # rad/s
const GAT_GAP := 1.1
const TRACK_T := 0.45  # the lance: the sight flickers ...
const LOCK_T := 0.5  # ... then holds as the band ...
const BEAM_T := 1.0  # ... then the beam
const BEAM_HW := 0.55
const BEAM_COL := Color(1.0, 0.45, 0.75)
const NOSE := 1.3  # the muzzle, ahead (down-screen) of the centre

static var _beam_mat: ShaderMaterial

var arm := "gatling"
var gun: MeshInstance3D
var barrels: MeshInstance3D
var gun_a := PI / 2.0
var phase := 0  # 0 drifting in, 1 warned, 2 firing, 3 resting
var phase_t := 0.0
var shot_t := 0.0
var shot_k := 0
var beam: MeshInstance3D
var beam_mesh: ImmediateMesh
var beam_warn: Dictionary = {}


func _init_kind() -> void:
	arm = String(p.get("arm", "gatling"))
	hp = 14.0 if arm == "gatling" else 18.0
	radius = 1.15
	score = 700 if arm == "gatling" else 900
	energy_drop = 4.0
	blast = 1.4
	mesh_name = "sat_gatling" if arm == "gatling" else "sat_lance"


func _build() -> void:
	if arm == "gatling":
		gun = add_mesh("sat_gun")
		gun.position = Vector3(0, 0.3, 0.4)
		barrels = MeshInstance3D.new()
		barrels.mesh = Vox.get_mesh("sat_barrels")
		barrels.position = Vector3(0, 0.05, -0.55)
		gun.add_child(barrels)
	else:
		if _beam_mat == null:
			_beam_mat = ShaderMaterial.new()
			_beam_mat.shader = load("res://shaders/lightning.gdshader")
			_beam_mat.render_priority = 2
		beam_mesh = ImmediateMesh.new()
		beam = MeshInstance3D.new()
		beam.mesh = beam_mesh
		beam.material_override = _beam_mat
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam.extra_cull_margin = 16384.0
		add_child(beam)


func _behave(dt: float) -> void:
	# parked in orbit: it comes down with the scroll
	position.z += game.scroll_speed * dt
	model.rotation.y = sin(t * 0.7) * 0.08
	phase_t += dt
	if arm == "gatling":
		_gatling(dt)
	else:
		_lance(dt)


# ------------------------------------------------------------ gatling

func _gatling(dt: float) -> void:
	var aim := game.bullets.aim(_muzzle())
	match phase:
		0, 3:
			gun_a = rotate_toward(gun_a, aim, 2.0 * dt)
			barrels.rotation.z += dt * 3.0
			var ready := phase == 0 or phase_t >= GAT_GAP
			if ready and game.can_fire(position) and position.z > game.field_top + 1.0:
				phase = 1
				phase_t = 0.0
				game.warn(self, LOCK_GAT, Game.Warn.SHOT, radius)
		1:
			# spinning up, turned on the ship
			gun_a = rotate_toward(gun_a, aim, 3.0 * dt)
			barrels.rotation.z += dt * lerpf(3.0, 40.0, phase_t / LOCK_GAT)
			if phase_t >= LOCK_GAT:
				phase = 2
				phase_t = 0.0
				shot_t = 0.0
		2:
			# the stream, its aim swinging after the ship
			gun_a = rotate_toward(gun_a, aim, GAT_TURN * dt)
			barrels.rotation.z += dt * 40.0
			shot_t -= dt
			if shot_t <= 0.0:
				shot_t = GAT_EVERY
				shot_k += 1
				if game.can_fire(position):
					game.bullets.fire(_muzzle(), gun_a + (0.04 if shot_k % 2 == 0 else -0.04), GAT_SPEED, Bullets.ORB, self, Bullets.ROUND, 0.0, 0.0, 0.85)
					if shot_k % 3 == 0:
						game.fx.flash(_muzzle(), 0.25)
			if phase_t >= GAT_T or not game.can_fire(position):
				phase = 3
				phase_t = 0.0
	gun.rotation.y = atan2(-cos(gun_a), -sin(gun_a))


func _muzzle() -> Vector3:
	return position + Vector3(cos(gun_a), 0, sin(gun_a)) * 1.1


# ------------------------------------------------------------ lance

func _lance(dt: float) -> void:
	var from := position + Vector3(0, 0, NOSE)
	var to := Vector3(from.x, 0, _beam_end(from))
	match phase:
		0:
			if game.can_fire(position) and position.z > game.field_top + 0.8:
				phase = 1
				phase_t = 0.0
				game.warn(self, TRACK_T + LOCK_T + BEAM_T, Game.Warn.MOVE, radius, {"laser": PackedVector3Array([from, to])})
				beam_warn = game.warnings[game.warnings.size() - 1]
				game.sfx.play("slam")
		1:
			if phase_t >= TRACK_T + LOCK_T:
				phase = 2
				phase_t = 0.0
				game.sfx.play("exp_s")
				game.shake(0.15)
		2:
			if game.combat_on() and _on_beam(from, to, game.player.position):
				game.touch_player("satellite lance")
			if randf() < 0.4:
				game.fx.spark(from.lerp(to, randf()) + Vector3(0, 0.4, 0), BEAM_COL, 1, 0.3)
			if phase_t >= BEAM_T:
				phase = 3
				phase_t = 0.0
	if phase == 1 or phase == 2:
		(beam_warn.get("to", {}) as Dictionary)["laser"] = PackedVector3Array([from, to])
	_draw_beam(from, to)


## Where the beam down from `from` stops: the bottom edge, or the near side
## of a rock in its way.
func _beam_end(from: Vector3) -> float:
	var end := game.field_bottom + 2.0
	for e in game.enemies:
		if not e.solid or e.dead or not e.visible:
			continue
		var dx := absf(e.hit_pos.x - from.x)
		if dx < e.radius and e.hit_pos.z > from.z:
			end = minf(end, e.hit_pos.z - sqrt(e.radius * e.radius - dx * dx))
	return end


func _on_beam(from: Vector3, to: Vector3, pp: Vector3) -> bool:
	return absf(pp.x - from.x) < BEAM_HW + Player.HIT_R and pp.z > from.z and pp.z < to.z


## The column (in local space, just over the plane): the flickering sight,
## the band with the bright line in it (blinking at the end), the beam.
func _draw_beam(from: Vector3, to: Vector3) -> void:
	beam_mesh.clear_surfaces()
	if phase != 1 and phase != 2:
		return
	beam_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := from - position
	var b := to - position
	if phase == 1:
		if phase_t < TRACK_T:
			_seg(a, b, 0.06, 0.4 + 0.2 * sin(game.time * 70.0))
		else:
			var left := TRACK_T + LOCK_T - phase_t
			_seg(a, b, BEAM_HW, 0.16)
			if left > 0.15 or int(left * 40.0) % 2 == 0:
				_seg(a, b, 0.1, 1.0)
	else:
		var w := BEAM_HW * (1.0 + 0.08 * sin(game.time * 60.0))
		var f := clampf((BEAM_T - phase_t) / 0.2, 0.0, 1.0)
		_seg(a, b, w * 1.6, 0.4 * f)
		_seg(a, b, w, f)
	beam_mesh.surface_end()


func _seg(p0: Vector3, p1: Vector3, w: float, a: float) -> void:
	var col := Color(BEAM_COL.r, BEAM_COL.g, BEAM_COL.b, a)
	var q0 := p0 + Vector3(0, 0.36, 0)
	var q1 := p1 + Vector3(0, 0.36, 0)
	var s := Vector3(w, 0, 0)
	for q: Array in [[q0 - s, 0.0], [q0 + s, 1.0], [q1 + s, 1.0], [q0 - s, 0.0], [q1 + s, 1.0], [q1 - s, 0.0]]:
		beam_mesh.surface_set_color(col)
		beam_mesh.surface_set_uv(Vector2(0, q[1]))
		beam_mesh.surface_add_vertex(q[0])
