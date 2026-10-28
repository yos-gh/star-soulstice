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
##   lance    a laser emitter: its beam's line down the screen is marked
##            (a thin flickering sight, then a band as wide as the beam,
##            blinking at the end), then the straight beam burns out to the
##            edge of the screen for as long as the satellite has left on
##            the screen, turning very slowly (no warning: it is slow) the
##            way it was set: params.tilt its first heading off straight
##            down (+ its far end to the right), params.spin which way it
##            turns (+1 its far end moves right, -1 left). Set in pairs
##            that close in on the ship (scissors) or sweep it onto the
##            guns (a push): break one quickly, or get behind a rock (a
##            rock in the way stops the beam: Game.solid_cut).
## Rocks (solid) stop the gun's rounds too. It rams like any small craft.
## Both lock on as they come over the top edge and open fire the moment
## they are on the screen.
## params: x, z, arm, spin, tilt

const INFO := {
	"name": "SATELLITE", "category": "small",
	"desc": "衛星軌道兵器（ステージ 5 の宇宙）：自分では動けず、スクロールに乗って流れてきて、通りがかりに撃つ。太陽電池の翼をトラスで張った剥き出しの機械。組み合わせで自機を追い込む。gatling：予兆（ロックオン、砲身が回り出す）のあと、これまでにない速さで小さなエネルギー弾を連射し、狙いを自機へ振っていく（横へ振り切るか岩の陰へ）。間をおいて、自機より上にいるうちはもう一度。lance：レーザーの発射器。ビームの線に予兆（細くちらつく照準、ビームの幅の帯、最後に点滅）を出し、まっすぐなビームを画面の端まで、画面にいられるあいだ焼き続け、決められた向きへごくゆっくり回る（ゆっくりなので回る向きの予兆はなし）。初めの向きと回る向きは並べ方しだい：両側から閉じてくるハサミ、片側から掃いて砲台の側へ押し込む押し込み（急いで 1 機壊すか、岩の陰へ）。どちらも画面の上の端にかかるところでロックオンし、画面に入るとすぐ撃つ。岩があるとそこで止まる。岩は gatling の弾も止める。体当たりあり",
	"demos": [
				["SCISSORS", "sats", [0.0, [[-0.6, "lance", 0.0, 1.0, -0.15], [0.6, "lance", 0.0, -1.0, 0.15], [0.0, "gatling", 3.0]]]],
		["PUSH", "sats", [0.0, [[-0.8, "lance", 0.0, 1.0, -0.3], [-0.35, "lance", 4.0, 1.0, -0.3], [0.75, "gatling", 1.0], [0.45, "gatling", 5.0]]]],
		["GATLING", "sats", [0.0, [[0.0, "gatling"]]]],
		["GRID", "sats", [0.0, [[-0.6, "lance"], [0.6, "lance"], [0.0, "gatling", 3.0]]]],
	],
}

const LOCK_GAT := 0.4
const GAT_T := 1.3
const GAT_EVERY := 0.06
const GAT_SPEED := 9.5
const GAT_TURN := 1.1  # rad/s
const GAT_GAP := 1.1
const TRACK_T := 0.3  # the lance: the sight flickers ...
const LOCK_T := 0.45  # ... then holds as the band ...
const BEAM_MIN := 1.0  # ... then the beam, this long at least ...
const BEAM_MAX := 3.2  # ... at most
const SPIN_W := 0.23  # how fast the beam turns (rad/s)
const ENTER := 2.5  # it locks on this far above the top edge (coming in): it opens fire the moment it is on
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
var ang := PI / 2.0  # where the lance points (PI/2 = down the screen)
var spin := 0.0
var beam_t := BEAM_MIN


func _init_kind() -> void:
	arm = String(p.get("arm", "gatling"))
	hp = 14.0 if arm == "gatling" else 32.0
	radius = 1.15
	score = 700 if arm == "gatling" else 1200
	spin = float(p.get("spin", 0.0))
	ang = PI / 2.0 - float(p.get("tilt", 0.0))
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
	phase_t += dt
	if arm == "gatling":
		model.rotation.y = sin(t * 0.7) * 0.08
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
			if phase == 0 and t <= dt * 1.5:
				gun_a = aim  # (turned on the ship from the start)
			var ready := phase == 0 or phase_t >= GAT_GAP
			if ready and _coming_in():
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


## On (or just coming onto) the screen, above the ship: time to lock on.
func _coming_in() -> bool:
	var pl := game.player
	return game.combat_on() and pl.alive and position.z > game.field_top - ENTER and position.z < pl.position.z - 2.0 and absf(position.x) < game.half_width_at(position.z) + 1.0


func _muzzle() -> Vector3:
	return position + Vector3(cos(gun_a), 0, sin(gun_a)) * 1.1


# ------------------------------------------------------------ lance

func _lance(dt: float) -> void:
	match phase:
		0:
			if _coming_in():
				phase = 1
				phase_t = 0.0
				# as long as it has left on the screen, up to BEAM_MAX
				beam_t = clampf((game.field_bottom - 2.0 - position.z) / maxf(game.scroll_speed, 1.0) - TRACK_T - LOCK_T, BEAM_MIN, BEAM_MAX)
				var pts := _beam_pts()
				game.warn(self, TRACK_T + LOCK_T + beam_t, Game.Warn.MOVE, radius, {"laser": pts})
				beam_warn = game.warnings[game.warnings.size() - 1]
				game.sfx.play("slam")
		1:
			if phase_t >= TRACK_T + LOCK_T:
				phase = 2
				phase_t = 0.0
				game.sfx.play("exp_s")
				game.shake(0.15)
		2:
			# the beam turns, very slowly, the way it was set to
			ang -= spin * SPIN_W * dt
			var pts := _beam_pts()
			if game.combat_on() and _on_beam(pts[0], pts[1], game.player.position):
				game.touch_player("satellite lance")
			if randf() < 0.4:
				game.fx.spark(pts[0].lerp(pts[1], randf()) + Vector3(0, 0.4, 0), BEAM_COL, 1, 0.3)
			if phase_t >= beam_t:
				phase = 3
				phase_t = 0.0
	if phase == 1 or phase == 2:
		(beam_warn.get("to", {}) as Dictionary)["laser"] = _beam_pts()
	# the emitter points along the beam
	model.rotation.y = atan2(cos(ang), sin(ang)) + sin(t * 0.7) * (0.08 if phase == 0 else 0.0)
	_draw_beam()


## The muzzle and where the beam from it stops: the edge of the screen the
## way it points, or the near side of a rock in its way.
func _beam_pts(a := INF) -> PackedVector3Array:
	if a == INF:
		a = ang
	var d := Vector3(cos(a), 0, sin(a))
	var from := position + d * NOSE
	var reach := 80.0
	if d.z > 0.01:
		reach = (game.field_bottom + 2.0 - from.z) / d.z
	if absf(d.x) > 0.01:
		reach = minf(reach, (signf(d.x) * (game.hw_top + 3.0) - from.x) / d.x)
	return PackedVector3Array([from, game.solid_cut(from, from + d * reach)])


func _on_beam(from: Vector3, to: Vector3, pp: Vector3) -> bool:
	var c := Geometry3D.get_closest_point_to_segment(Vector3(pp.x, 0, pp.z), from, to)
	return Vector2(pp.x - c.x, pp.z - c.z).length() < BEAM_HW + Player.HIT_R


## The beam (in local space, just over the plane): the flickering sight,
## then the band with the bright line in it (blinking at the end); then the
## beam itself (it turns slowly: the turn needs no warning).
func _draw_beam() -> void:
	beam_mesh.clear_surfaces()
	if phase != 1 and phase != 2:
		return
	beam_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := _beam_pts()
	var a := pts[0] - position
	var b := pts[1] - position
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
		var f := clampf((beam_t - phase_t) / 0.2, 0.0, 1.0)
		_seg(a, b, w * 1.6, 0.4 * f)
		_seg(a, b, w, f)
	beam_mesh.surface_end()


func _seg(p0: Vector3, p1: Vector3, w: float, a: float) -> void:
	var col := Color(BEAM_COL.r, BEAM_COL.g, BEAM_COL.b, a)
	var q0 := p0 + Vector3(0, 0.36, 0)
	var q1 := p1 + Vector3(0, 0.36, 0)
	var dd := q1 - q0
	var s := Vector3(-dd.z, 0, dd.x).normalized() * w
	for q: Array in [[q0 - s, 0.0], [q0 + s, 1.0], [q1 + s, 1.0], [q0 - s, 0.0], [q1 + s, 1.0], [q1 - s, 0.0]]:
		beam_mesh.surface_set_color(col)
		beam_mesh.surface_set_uv(Vector2(0, q[1]))
		beam_mesh.surface_add_vertex(q[0])
