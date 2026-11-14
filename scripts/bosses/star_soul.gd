extends BossBase
## Stage 5's last boss STAR SOUL: what sat at the heart of every boss so
## far, out on its own in warp space and grown into a crystal. Nothing
## mechanical is left of it: a long octahedron of dark glass, lines of light
## along its edges, two rings of light round its waist and six motes (small
## octahedra) circling there (CoreModels). It is made of eight plates round
## a bright seed, and it attacks by changing its shape. All of it can be
## shot, in every shape (no armour, no shutter: every hit counts on the one
## gauge), and as its light runs down it sheds energy for the homing lasers.
## Three forms, one after another as its light runs down (or after a while):
##   OBELISK    the closed crystal, turning about its long axis: shell fans
##              from the tip nearer the ship, an aimed needle volley, two
##              homing lances (MarkedStrikes), rings of shells; a SPIRE RUN
##              (shards grow out of the field one after another along a
##              marked line through the ship); and its shape change, the
##              LANCE: it draws itself out long and thin, swings its point
##              onto the ship (the lane is marked), thrusts down the lane,
##              hangs there a moment and draws back
##   PRISM      it comes apart: the two pyramids stand off from the seed and
##              turn against each other, the plates loose. Twin spirals of
##              shells from the seed, needle volleys, three spire runs
##              fanned out, lances; and the LATTICE: the motes fly out to
##              the edges of the screen and string beams between them, two
##              columns either side of the ship, a row through it, then a
##              beam from each of two motes through the ship itself (every
##              line a thin sight first, then a band, then it burns)
##   SOULSTICE  (its rage) it turns its point to the camera and opens like
##              a flower: an eight-pointed star round the bare seed,
##              spinning. Spirals of shells from its points, heavy balls
##              that burst into rings, shards erupting under the ship (each
##              spot ringed first); the STAR MANDALA: the motes take the
##              corners of a hexagon round the whole screen and draw a
##              six-pointed star across it stroke by stroke, a beam through
##              the ship between the strokes (a faint trace of each stroke
##              stays a while: the finished figure hangs over the field);
##              and the SOLSTICE: the star gathers light (its lane straight
##              down the screen marked and filling), then a wide beam burns
##              down it while rings of shells roll off the star
## A quiet moment while it changes form: it can be hit then too.

const MarkedStrikes := preload("res://scripts/bosses/marked_strikes.gd")

const INFO := {
	"name": "STAR SOUL", "role": "boss",
	"desc": "最終面のボス 2 体目（最終ボス）。これまでのボスの奥にあったコアが結晶になったもの。機械らしさはなく、暗いガラスのような縦に長い八面体で、稜線が光り、腰のまわりに光の輪が 2 本と小さな八面体（モート）が 6 つ回る。8 枚の板と中の明るい種でできていて、形を変えて攻撃する。どの姿でも全体に弾が当たる（装甲なし、ゲージは 1 本）。光が減るたびにエネルギーをこぼす。光が減るにつれて（または時間で）姿を変える。OBELISK：閉じた結晶のまま軸で回り、自機に近い先端から物理弾の扇、狙いの針弾、追尾する光の槍 2 本、物理弾の輪。SPIRE RUN（自機を通る線を予兆してから、結晶の棘が手前から順に生える）。変形 LANCE：細長く伸びて先端を自機に向け（通り道を予兆）、突き出して少し止まり、引き戻る。PRISM：上下 2 つのピラミッドに分かれて種がむき出しになり、互い違いに回る。種から二重の渦巻き、針弾、3 本に広がる SPIRE RUN、光の槍。大技 LATTICE：モートが画面の縁へ飛び、そのあいだにビームを張る（自機の左右に縦 2 本、自機を通る横 1 本、続いてモート 2 つから自機を通る 1 本ずつ。どれも細い照準線、帯、照射の順）。SOULSTICE（発狂）：先端をこちらへ向けて花のように開き、種を囲む八芒星になって回る。星の先から渦巻きの物理弾、輪にはじける大型弾、自機の足もとに生える棘（落ちる所を円で予兆）。大技 STAR MANDALA：モートが画面いっぱいの六角形の角につき、ビームで六芒星を 1 画ずつ描く。画のあいだに自機を通る 1 本（描いた線は薄く残って図形になる）。大技 SOLSTICE：星が光を集め（真下への通り道を予兆）、太いビームを撃ち下ろす。そのあいだ星から物理弾の輪。姿を変える間は静かで、そのあいだも撃てる",
	"demos": [["FULL", ""], ["PRISM", "B"], ["SOULSTICE", "C"]],
}

const HP := 4000.0
const SCORE := 150000
## the form changes at these shares of its light left (or after FORM_T)
const FORM_AT := [0.66, 0.33]
const FORM_T := [36.0, 34.0]
const MORPH := 2.0  # changing form: quiet this long
## every CHIP of its light lost, it sheds this much energy
const CHIP := 0.04
const CHIP_ENERGY := 6.0
const CYCLE := [9.6, 9.8, 13.0]
const HOME_Z := 8.0  # where it hangs, below the top edge
const L := CoreModels.L
const R := CoreModels.R
## its long axis lying on the field (pointing up the screen) / at the camera
const FLAT := -PI / 2.0
const FACE := (90.0 - Game.CAM_PITCH) * PI / 180.0
## its shape: how far the plates swing open about their waist edges (rad),
## stand off along their faces, how far the two pyramids stand apart, the
## lower one's twist against the upper, the stretch along the axis and the
## squeeze across it, the axis's pitch and yaw, the size of the rings
enum { OPEN, GAP, SPLIT, TWIST, STRETCH, SQUEEZE, PITCH, YAW, RING }
const EASE := [3.2, 4.0, 4.0, 3.0, 6.0, 6.0, 2.4, 7.0, 3.0]
const OBELISK := [0.0, 0.0, 0.0, 0.0, 1.0, 1.0, FLAT, 0.0, 1.0]
const LANCE := [0.0, 0.0, 0.0, 0.0, 1.45, 0.6, FLAT, 0.0, 0.72]
const PRISM := [0.1, 0.2, 1.5, 0.0, 1.0, 1.0, FLAT, 0.0, 1.3]
const BLOOM := [1.36, 0.0, 0.0, PI / 4.0, 1.0, 1.0, FACE, 0.0, 1.75]
const SPIN := [0.5, 0.7, 1.4]
const MOTE_R := 3.9  # the motes' orbit (x the ring size)
## the LANCE: drawn out, then the lane follows the ship, holds, and it goes
const LANCE_FORM := 0.45
const LANCE_TRACK := 0.7
const LANCE_LOCK := 0.35
const LANCE_SPEED := 40.0
const LANCE_HANG := 0.3
const LANCE_BACK := 13.0
const LANCE_TURN := 2.6  # how fast the point swings after the ship (rad/s)
## spires: a run's line marked, then one after another; a single one's spot
const RUN_MARK := 0.8
const RUN_STEP := 0.06
const RUN_GAP := 2.2
const RUN_FROM := 4.0
const ERUPT_MARK := 0.75
const ERUPT_R := 1.4
const SPIRE_UP := 0.1  # growing
const SPIRE_LIVE := 0.3  # deadly
const SPIRE_STAND := 0.55  # then it shatters
## beams: the sight flickers, then the band holds, then it burns
const SIGHT := 0.4
const BEAM_HW := 0.5
const BEAM_COL := Color(0.62, 1.0, 0.84)
const TRACE := 3.2  # a mandala stroke's trace fades this long
## the SOLSTICE: gathering light, then the beam
const SOL_CHARGE := 1.4
const SOL_BURN := 1.5
const SOL_HW := 2.0

static var _beam_mat: ShaderMaterial

var core: Enemy  # the middle: it holds the light (hp); homing lasers lock it
var lobes: Array[Enemy] = []  # the rest of its body: hits go to the core
var motes: Array[Enemy] = []
var mote_mesh: Array[MeshInstance3D] = []
var mote_to: Array[Vector3] = []  # their posts while they are out
var motes_out := false
var mote_a := 0.0
var rig: Node3D  # yaw
var tilt: Node3D  # pitch
var form: Node3D  # stretch and squeeze
var turn: Node3D  # the spin about the long axis
var plates: Array[MeshInstance3D] = []
var seed_mi: MeshInstance3D
var plate_mat: ShaderMaterial
var seed_mat: ShaderMaterial
var mote_mat: ShaderMaterial
var halos: Array[MeshInstance3D] = []
var halo_mat: Array[ShaderMaterial] = []
var halo_a := 0.0
var shape: Array[float] = []
var want: Array[float] = []
var hinge := Vector3.RIGHT  # a plate's waist edge (model space) ...
var edge_mid := Vector3.ZERO  # ... its middle ...
var face_n := Vector3.UP  # ... the plate's face normal ...
var flip := Basis.IDENTITY  # ... and an upper plate turned into a lower one
var spin_a := 0.0
var spin_w := 0.5
var counter_a := 0.0
var center := Vector3.ZERO  # where it hangs
var pos := Vector3.ZERO  # where it is (a thrust takes it off its place)
var lunge := 0.0
var lunge_to := 0.0
var thrust := ""  # "" | form | aim | go | hang | back | ease
var thrust_t := 0.0
var thrust_lane := {}  # the lane's warning (its `to`)
var lane_len := 0.0
var hold_t := 0.0  # it stays where it is this long (the SOLSTICE)
## beams: {pts (a polyline on the plane), t, lock, burn, hw, trace}
var beams: Array[Dictionary] = []
var traces: Array[Dictionary] = []  # {pts, t}: what a mandala stroke leaves
## spires: {at, t, delay, r, shells, a (anchor or null), mi, lean, turn}
var spires: Array[Dictionary] = []
var fx_mi: MeshInstance3D
var fx_mesh: ImmediateMesh
var lances: MarkedStrikes
var phase := 0  # 0 enter, 1 OBELISK, 2 PRISM, 3 SOULSTICE, 4 dying
var st := 0.0
var form_t := 0.0
var morph_t := 0.0
var cycle_t := 0.0
var fired := {}
var fan_t := 0.0
var spiral_t := 0.0
var spiral_a := 0.0
var spiral_k := 0
var flower_a := 0.0
var web_a := 0.5
var aim_at := Vector3.ZERO
var heat := 0.0
var glow := 0.0
var chips := 0
var spear_frame := -1
var destroyed := false
var dying_t := 0.0


func setup(g: Game) -> void:
	game = g
	hinge = Vector3(1, 0, -1).normalized()
	edge_mid = Vector3(R * 0.5, 0, R * 0.5)
	face_n = Vector3(1.0 / R, 1.0 / L, 1.0 / R).normalized()
	flip = Basis(Vector3(1, 0, 1).normalized(), PI)
	center = Vector3(0, 0, game.field_top - 7.5)
	pos = center
	for v: float in OBELISK:
		shape.append(v)
		want.append(v)
	core = game.spawn_part(self, "", R)
	core.hp = HP
	core.max_hp = HP
	core.score = SCORE
	core.armored = true
	core.blast = 3.0
	core.debris_col = CoreModels.GLASS
	for k in 8:
		var q := game.spawn_part(self, "", 1.0)
		q.hp = 1e9
		q.max_hp = 1e9
		q.score = 0
		q.armored = true
		q.lock = false  # the homing lasers go for the middle
		lobes.append(q)
	lances = MarkedStrikes.new(g, self, MarkedStrikes.LANCE, Color(0.3, 1.0, 0.6))
	rig = Node3D.new()
	add_child(rig)
	tilt = Node3D.new()
	rig.add_child(tilt)
	form = Node3D.new()
	tilt.add_child(form)
	turn = Node3D.new()
	form.add_child(turn)
	plate_mat = CoreModels.crystal_material("plate").duplicate() as ShaderMaterial
	for i in 8:
		var m := MeshInstance3D.new()
		m.mesh = Vox.get_mesh("soul_plate")
		m.material_override = plate_mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		turn.add_child(m)
		plates.append(m)
	seed_mat = CoreModels.crystal_material("seed").duplicate() as ShaderMaterial
	seed_mi = MeshInstance3D.new()
	seed_mi.mesh = Vox.get_mesh("soul_seed")
	seed_mi.material_override = seed_mat
	seed_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	turn.add_child(seed_mi)
	for k in 2:
		var h := MeshInstance3D.new()
		h.mesh = Vox.get_mesh("soul_halo")
		var hm := CoreModels.halo_material().duplicate() as ShaderMaterial
		hm.set_shader_parameter("dashes", 24.0 if k == 0 else 36.0)
		hm.set_shader_parameter("ticks", 12.0 if k == 0 else 18.0)
		h.material_override = hm
		h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tilt.add_child(h)
		halos.append(h)
		halo_mat.append(hm)
	mote_mat = CoreModels.crystal_material("mote").duplicate() as ShaderMaterial
	for i in 6:
		var e := game.spawn_part(self, "", 0.5)
		e.intangible = true
		e.shootable = false
		e.lock = false
		e.ram = false
		var m := MeshInstance3D.new()
		m.mesh = Vox.get_mesh("soul_mote")
		m.material_override = mote_mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		e.add_child(m)
		motes.append(e)
		mote_mesh.append(m)
		mote_to.append(Vector3.ZERO)
	if _beam_mat == null:
		_beam_mat = ShaderMaterial.new()
		_beam_mat.shader = load("res://shaders/lightning.gdshader")
		_beam_mat.render_priority = 2
	fx_mesh = ImmediateMesh.new()
	fx_mi = MeshInstance3D.new()
	fx_mi.mesh = fx_mesh
	fx_mi.material_override = _beam_mat
	fx_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx_mi.extra_cull_margin = 16384.0
	add_child(fx_mi)
	_pose()
	_zones()
	_motes(0.0, true)
	_light(0.0)


## A hit anywhere on it is a hit on its light. The Spear reaches several of
## its hit zones at once: only one of them counts each frame.
func on_hit(e: Enemy, dmg: float) -> float:
	if absf(dmg - Player.SPEAR_DPS * Game.DT) < 0.001 and game.player.spear_t > 0.0:
		if spear_frame == game.frames:
			return 0.0
		spear_frame = game.frames
	if e == core:
		return dmg
	if lobes.has(e) and not core.dead:
		core.flash = 1.0
		core.hp -= dmg
		if core.hp <= 0.0:
			game.kill(core)
	return 0.0


func on_part_killed(e: Enemy) -> void:
	if e == core:
		_die()


func tick(dt: float) -> void:
	if destroyed:
		return
	st += dt
	match phase:
		0:
			center.z = move_toward(center.z, game.field_top + HOME_Z, 4.2 * dt)
			glow = clampf(st / 3.4, 0.0, 1.0)
			if st > 3.8:
				phase = 1
				st = 0.0
				core.armored = false
				for q in lobes:
					q.armored = false
				game.boss_fight_started()
		1, 2, 3:
			form_t += dt
			glow = 1.0
			if morph_t > 0.0:
				morph_t -= dt
				if morph_t <= 0.0:
					cycle_t = 0.0
					fired.clear()
			else:
				_attacks(dt)
			_next_form()
			hold_t = maxf(0.0, hold_t - dt)
			if thrust == "" and hold_t <= 0.0:
				var reach := 2.0 if phase == 1 else 3.2
				center.x = move_toward(center.x, sin(form_t * 0.42) * reach, (1.5 if phase == 1 else 3.0) * dt)
			_shed_energy()
		4:
			_dying(dt)
			if destroyed:
				return
	_thrust(dt)
	for i in shape.size():
		var k := 1.0 - exp(-dt * float(EASE[i]))
		shape[i] = lerp_angle(shape[i], want[i], k) if i == YAW else lerpf(shape[i], want[i], k)
	var w: float = SPIN[clampi(phase - 1, 0, 2)]
	if thrust == "aim" or thrust == "go":
		w = 5.0  # a drill
	elif phase == 3 and _charging():
		w = 3.2
	elif phase == 4:
		w = 0.6 + dying_t * 2.0
	spin_w = move_toward(spin_w, w, dt * 3.0)
	spin_a += spin_w * dt
	if phase == 2:
		# the lower pyramid turns against the upper one
		counter_a -= 2.0 * spin_w * dt
	else:
		counter_a = move_toward(counter_a, roundf(counter_a / (PI * 0.5)) * PI * 0.5, dt * 3.0)
	pos = center + _point() * lunge
	_pose()
	_zones()
	_motes(dt, false)
	_spires(dt)
	_beams(dt)
	_draw()
	if phase >= 1 and phase <= 3:
		lances.tick(dt)
	_light(dt)


# ------------------------------------------------------------ shape

func _set_shape(to: Array, keep_yaw := false) -> void:
	for i in want.size():
		if i == YAW and keep_yaw:
			continue
		want[i] = float(to[i])


## Puts the plates, the seed and the rings where the shape says.
func _pose() -> void:
	rig.position = pos
	rig.rotation.y = shape[YAW]
	tilt.rotation.x = shape[PITCH]
	form.scale = Vector3(shape[SQUEEZE], shape[STRETCH], shape[SQUEEZE])
	turn.rotation.y = spin_a
	var open := Basis(hinge, shape[OPEN])
	var t := Transform3D(open, edge_mid - open * edge_mid + face_n * shape[GAP] + Vector3.UP * shape[SPLIT])
	for i in 8:
		var up := i < 4
		var b := Basis(Vector3.UP, PI * 0.5 * (i % 4) + (0.0 if up else shape[TWIST] + counter_a))
		if not up:
			b = b * flip
		plates[i].transform = Transform3D(b, Vector3.ZERO) * t
	for k in 2:
		var h := halos[k]
		var s: float = MOTE_R * shape[RING] / 0.94 * (1.0 if k == 0 else 1.3)
		h.scale = Vector3.ONE * s
		if k == 1:
			h.rotation = Vector3(0.42, halo_a, 0.0)


## Its long axis, toward the upper tip (a unit vector in the world).
func _axis() -> Vector3:
	return tilt.global_transform.basis.y


## Where its lower tip points, on the plane.
func _point() -> Vector3:
	return Vector3(sin(shape[YAW]), 0, cos(shape[YAW]))


## Half its length on the plane (while it lies flat).
func _reach() -> float:
	return L * shape[STRETCH] + shape[SPLIT]


## A tip on the plane: +1 the lower one (toward the ship at rest), -1 the upper.
func _tip(s: float) -> Vector3:
	return game.to_plane(pos - _axis() * (s * _reach()))


## The tip nearer the ship.
func _near_tip() -> float:
	return 1.0 if (game.player.position - pos).dot(_point()) >= 0.0 else -1.0


func _bloomed() -> bool:
	return shape[PITCH] > -0.6


## A point of a plate (model space) on the plane.
func _plate_at(i: int, p: Vector3) -> Vector3:
	return game.to_plane(plates[i].global_transform * p)


## The hit zones follow the shape: a chain of circles along the axis while
## it lies flat, one on each petal once it has opened toward the camera.
func _zones() -> void:
	var sq := shape[SQUEEZE]
	core.position = pos
	if _bloomed():
		core.radius = 2.5
		var mid := Vector3(R / 3.0, L / 3.0, R / 3.0)
		for i in 8:
			lobes[i].position = _plate_at(i, mid)
			lobes[i].radius = 1.3
			lobes[i].intangible = defeated
		return
	core.radius = R * sq * 0.9 + 0.1
	var ax := _axis()
	var h := L * shape[STRETCH]
	var k := 0
	for s: float in [-1.0, 1.0]:
		for q: Array in [[0.22, 0.7], [0.62, 0.34]]:
			lobes[k].position = game.to_plane(pos - ax * (s * (shape[SPLIT] + float(q[0]) * h)))
			lobes[k].radius = R * sq * float(q[1]) + 0.25
			lobes[k].intangible = defeated
			k += 1
	for i in range(4, 8):
		lobes[i].position = pos
		lobes[i].intangible = true


## The motes: round the waist, or gliding out to their posts and back.
func _motes(dt: float, now: bool) -> void:
	mote_a += dt * (0.9 + heat * 0.7)
	halo_a += dt * 0.35
	var b := tilt.global_transform.basis
	for i in 6:
		var to: Vector3 = mote_to[i]
		if not motes_out:
			var a := mote_a + TAU * i / 6.0
			to = pos + b * (Vector3(cos(a), 0, sin(a)) * MOTE_R * shape[RING])
		var m := motes[i]
		m.position = to if now else m.position.lerp(to, 1.0 - exp(-dt * (5.0 if motes_out else 6.0)))
		mote_mesh[i].rotation += Vector3(1.3, 2.1, 0.7) * dt


## The crystal's light: dim as it comes in, hot in its rage; hits and
## warnings wash over it.
func _light(dt: float) -> void:
	heat = move_toward(heat, 1.0 if phase >= 3 else 0.0, dt * 0.8)
	var pulse := _pulse(core)
	var hit := core.flash if not core.dead else 0.0
	var boost := 1.0 + 0.4 * heat + (dying_t * 0.8 if phase == 4 else 0.0)
	plate_mat.set_shader_parameter("light", glow * boost * (1.0 + 0.5 * pulse))
	plate_mat.set_shader_parameter("heat", heat)
	plate_mat.set_shader_parameter("wash", hit * 0.045 + pulse * 0.12)
	seed_mat.set_shader_parameter("light", glow * boost * (1.1 + 0.25 * sin(game.time * 6.0)))
	seed_mat.set_shader_parameter("heat", heat)
	seed_mat.set_shader_parameter("wash", hit * 0.15 + pulse * 0.3 + (maxf(dying_t - 2.2, 0.0) * 1.2 if phase == 4 else 0.0))
	mote_mat.set_shader_parameter("light", glow * boost)
	mote_mat.set_shader_parameter("heat", heat)
	for k in 2:
		var hm := halo_mat[k]
		hm.set_shader_parameter("alpha", glow * (0.75 if k == 0 else 0.5) * (1.0 + 0.6 * pulse) * (maxf(0.0, 1.0 - dying_t / 2.4) if phase == 4 else 1.0))
		hm.set_shader_parameter("heat", heat)
		hm.set_shader_parameter("turn", game.time * (0.5 if k == 0 else -0.3) * (1.0 + heat))


## An attacker's warning pulse (as Enemy._shade gives a model): quickening
## as the attack nears.
func _pulse(e: Enemy) -> float:
	if e.warn_t <= 0.0:
		return 0.0
	var f := 1.0 - e.warn_t / maxf(e.warn_dur, 0.01)
	return (0.3 + 0.7 * f) * (0.5 + 0.5 * sin(e.warn_t * lerpf(18.0, 40.0, f)))


## Its light bleeding out as it is hurt: energy for the homing lasers.
func _shed_energy() -> void:
	var lost := 1.0 - core.hp / core.max_hp
	while chips < int(lost / CHIP) and not core.dead:
		chips += 1
		game.items.burst_energy(pos, CHIP_ENERGY)
		for i in 5:
			var a := randf() * TAU
			game.fx.sprite(pos + Vector3(0, 0.6, 0), Vector3(cos(a), 0, sin(a)) * randf_range(5.0, 11.0), 0.45, 0.08, 0.4, BEAM_COL, 0.0)


# ------------------------------------------------------------ forms

## Light down to the next form's share, or the form has gone on long enough.
func _next_form() -> void:
	if morph_t > 0.0:
		return
	if phase == 1 and (core.hp < core.max_hp * FORM_AT[0] or form_t > FORM_T[0]):
		_morph(2)
	elif phase == 2 and (core.hp < core.max_hp * FORM_AT[1] or form_t > FORM_T[1]):
		_morph(3)


func _morph(to: int) -> void:
	if game.log_status:
		print("SOUL form=%d after %.1fs light=%d" % [to, form_t, int(core.hp)])
	phase = to
	form_t = 0.0
	morph_t = MORPH
	cycle_t = 0.0
	fired.clear()
	_call_off()
	game.shake(1.0)
	game.flash_a = maxf(game.flash_a, 0.2)
	game.sfx.play("slam")
	if to == 2:
		_set_shape(PRISM)
	else:
		_set_shape(BLOOM)
		game.show_msg("SOULSTICE", "", 1.5, true)
	game.fx.shockwave(pos + Vector3(0, 0.5, 0), 9.0, BEAM_COL)
	for k in 12:
		var a := TAU * k / 12.0
		game.fx.sprite(pos + Vector3(cos(a), 0.6, sin(a)) * 2.0, Vector3(cos(a), 0, sin(a)) * 11.0, 0.6, 0.1, 0.5, BEAM_COL, 0.0)


## Whatever it was at is off: beams, a thrust, spires not yet up, the motes
## home again (the lances already on their way fly on).
func _call_off() -> void:
	beams.clear()
	thrust = ""
	thrust_lane = {}
	hold_t = 0.0
	motes_out = false
	for s: Dictionary in spires.duplicate():
		if float(s["t"]) < float(s["delay"]):
			_drop_spire(s)
	var i := 0
	while i < game.warnings.size():
		var w: Dictionary = game.warnings[i]
		var nd = w["node"]
		if is_instance_valid(nd) and (nd == core or motes.has(nd)):
			game.warnings.remove_at(i)
			continue
		i += 1
	core.warn_t = 0.0


# ------------------------------------------------------------ attacks

func _once(key: String, at: float) -> bool:
	if cycle_t >= at and not fired.has(key):
		fired[key] = true
		return true
	return false


func _attacks(dt: float) -> void:
	cycle_t += dt
	match phase:
		1:
			_obelisk(dt)
		2:
			_prism(dt)
		3:
			_soulstice(dt)
	if cycle_t > CYCLE[phase - 1] and thrust == "":
		cycle_t = 0.0
		fired.clear()


func _obelisk(dt: float) -> void:
	# shell fans off the tip nearer the ship
	if cycle_t > 0.4 and cycle_t < 2.3:
		fan_t -= dt
		if fan_t <= 0.0:
			fan_t = 0.5
			var p := _tip(_near_tip())
			if game.boss_can_fire(p):
				game.bullets.fan(p, game.bullets.aim(p), 3, 28.0, 5.2, Bullets.SHELL, self)
	if _once("run", 0.8):
		_run(0.0, true)
	_needles("n1", 7.0, 7, 26.0, 9.0)
	if _once("thrust", 2.4):
		_start_thrust()
	_lances(7.6)
	for i in 2:
		if _once("flower%d" % i, 8.4 + i * 0.35):
			flower_a += 0.2
			game.bullets.ring(pos, 16, 4.2, Bullets.SHELL, self, flower_a)


func _prism(dt: float) -> void:
	# twin spirals out of the bare seed, one each way
	if cycle_t > 0.3 and cycle_t < 2.6:
		spiral_t -= dt
		if spiral_t <= 0.0 and game.boss_can_fire(pos):
			spiral_t = 0.16
			spiral_a += 0.31
			for s: float in [0.0, PI]:
				game.bullets.fire(pos, spiral_a + s, 4.6, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG)
				game.bullets.fire(pos, -spiral_a * 0.8 + s + 0.5, 4.2, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.SMALL)
	if _once("run", 5.2):
		for i in 3:
			_run((i - 1) * 0.42, i == 0)
	_needles("n1", 6.9, 9, 40.0, 9.5)
	_lattice(0.8)
	_lances(7.7)
	_needles("n2", 8.9, 9, 46.0, 9.5)


func _soulstice(dt: float) -> void:
	# spirals out of the star's points
	if (cycle_t > 0.3 and cycle_t < 2.4) or (cycle_t > 11.0 and cycle_t < 12.6):
		spiral_t -= dt
		if spiral_t <= 0.0:
			spiral_t = 0.14
			spiral_k += 1
			for i in range(spiral_k % 2, 8, 2):
				var at := _plate_at(i, Vector3(0, L, 0))
				var d := at - pos
				if game.boss_can_fire(at):
					game.bullets.fire(at, atan2(d.z, d.x), 4.8, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if i % 4 == spiral_k % 4 else Bullets.SMALL)
	_mandala(0.6)
	# heavy balls that burst into rings
	if cycle_t >= 7.2 - 0.8 and not fired.has("w_heavy"):
		fired["w_heavy"] = true
		aim_at = game.player.position
		game.warn(core, 0.8, Game.Warn.MOVE, core.radius, aim_at)
	if _once("heavy", 7.2) and game.boss_can_fire(pos):
		var d := aim_at - pos
		var base := atan2(d.z, d.x)
		for i in 3:
			game.bullets.fire(pos, base + (i - 1) * 0.42, 5.0, Bullets.HEAVY, self)
			game.bullets.split(1.5, 10)
		game.sfx.play("exp_m")
	_solstice(8.0)
	# shards erupting under the ship
	for i in 3:
		if _once("erupt%d" % i, 11.2 + i * 0.5):
			_erupt(i == 0)


## An aimed volley of energy needles from its middle (announced).
func _needles(key: String, at: float, count: int, spread: float, speed: float) -> void:
	var w := Enemy.WINDUP_SHOT
	if cycle_t >= at - w and not fired.has("w_" + key):
		fired["w_" + key] = true
		game.warn(core, w, Game.Warn.SHOT, core.radius)
	if _once(key, at) and game.boss_can_fire(pos):
		game.bullets.fan(pos, game.bullets.aim(pos), count, spread, speed, Bullets.ORB, self, Bullets.NEEDLE)


## Two homing lances of light, one from each tip, onto sights that follow
## the ship.
func _lances(at: float) -> void:
	for i in 2:
		if _once("lance%d" % i, at + i * 0.4):
			var s := 1.0 if i == 0 else -1.0
			var off := _tip(s) - pos
			var side := signf(off.x) if absf(off.x) > 0.5 else s
			lances.drop(core, off, Vector3.ZERO, 0, i == 0, side)


# ------------------------------------------------------------ the LANCE

## Its shape change in OBELISK: drawn out long and thin, its point swung
## onto the ship (the lane marked and following, then held), a thrust down
## the lane, a moment's hang, and back.
func _start_thrust() -> void:
	thrust = "form"
	thrust_t = 0.0
	_set_shape(LANCE, true)
	game.sfx.play("slam")


func _thrust(dt: float) -> void:
	if thrust == "":
		lunge = move_toward(lunge, 0.0, 20.0 * dt)
		return
	thrust_t += dt
	match thrust:
		"form":
			_swing(dt)
			if thrust_t >= LANCE_FORM:
				thrust = "aim"
				thrust_t = 0.0
				game.warn(core, LANCE_TRACK + LANCE_LOCK, Game.Warn.MOVE, core.radius, {"lane": _lane(), "hw": _lane_hw(), "show": true})
				thrust_lane = game.warnings[game.warnings.size() - 1]["to"]
		"aim":
			if thrust_t < LANCE_TRACK:
				_swing(dt)
			thrust_lane["lane"] = _lane()
			if thrust_t >= LANCE_TRACK + LANCE_LOCK:
				thrust = "go"
				thrust_t = 0.0
				lunge_to = maxf(lane_len - _reach(), 0.0)
				game.sfx.play("exp_s")
				game.shake(0.4)
		"go":
			lunge = move_toward(lunge, lunge_to, LANCE_SPEED * dt)
			_shed(dt)
			if lunge >= lunge_to:
				thrust = "hang"
				thrust_t = 0.0
		"hang":
			if thrust_t >= LANCE_HANG:
				thrust = "back"
		"back":
			lunge = move_toward(lunge, 0.0, LANCE_BACK * dt)
			if lunge <= 0.0:
				thrust = "ease"
				thrust_t = 0.0
				_set_shape(OBELISK)
		"ease":
			if thrust_t >= 0.5:
				thrust = ""


## The point swings after the ship, and the lane reaches past where the
## ship is (not much further than the screen).
func _swing(dt: float) -> void:
	var d := game.player.position - center
	var far := Vector2(d.x, d.z).length()
	if far > 1.0:
		want[YAW] = rotate_toward(want[YAW], atan2(d.x, d.z), LANCE_TURN * dt)
	shape[YAW] = want[YAW]
	var dir := _point()
	var least := L * float(LANCE[STRETCH]) + 3.0
	var edge := center.distance_to(_edge(center, atan2(dir.z, dir.x)))
	lane_len = clampf(far + 3.0, least, maxf(edge + 1.0, least))


func _lane() -> PackedVector3Array:
	return PackedVector3Array([center, center + _point() * lane_len])


func _lane_hw() -> float:
	return R * float(LANCE[SQUEEZE]) + 0.4


## Thrusting, it sheds shells either side of its track.
func _shed(dt: float) -> void:
	fan_t -= dt
	if fan_t > 0.0:
		return
	fan_t = 0.06
	if not game.boss_can_fire(pos):
		return
	var dir := _point()
	var a := atan2(dir.z, dir.x)
	for s: float in [-1.0, 1.0]:
		game.bullets.fire(pos, a + s * PI * 0.5, 2.3, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.SMALL)


# ------------------------------------------------------------ spires

## A shard will grow out of the field at `at` after `delay` (deadly within
## `r` as it comes up), then shatter into `shells` slow shells.
func _spire(at: Vector3, delay: float, r: float, shells: int, anchor: Enemy = null) -> void:
	spires.append({"at": at, "t": 0.0, "delay": delay, "r": r, "shells": shells, "a": anchor, "lean": randf_range(-0.28, 0.28), "turn": randf() * TAU})


## A SPIRE RUN: a line from the crystal through the ship (turned `off`
## radians from it) to the edge of the screen, marked, then the shards come
## up along it one after another.
func _run(off: float, sound: bool) -> void:
	var d := game.player.position - pos
	var a := atan2(d.z, d.x) + off
	var dir := Vector3(cos(a), 0, sin(a))
	var p := pos + dir * RUN_FROM
	var path := PackedVector3Array([p])
	var k := 0
	while k < 16 and game.on_field(p, 0.5):
		_spire(p, RUN_MARK + k * RUN_STEP, 1.0, 4 if k % 3 == 2 else 0)
		p += dir * RUN_GAP
		k += 1
	path.append(p)
	if k > 0:
		game.warn(core, RUN_MARK + k * RUN_STEP, Game.Warn.MOVE, core.radius, {"laser": path}, sound)


## One shard under the ship: its spot ringed, then it comes up.
func _erupt(sound: bool) -> void:
	var a := game.spawn_part(self, "", 0.6)
	a.intangible = true
	a.shootable = false
	a.lock = false
	a.ram = false
	var p := game.player.position
	var z := clampf(p.z, game.field_top + 2.0, game.field_bottom - 0.5)
	var w := game.half_width_at(z) - 0.5
	a.position = Vector3(clampf(p.x, -w, w), 0, z)
	a.hit_pos = a.position
	game.warn(a, ERUPT_MARK, Game.Warn.MOVE, 1.2, {"r": ERUPT_R}, sound)
	_spire(a.position, ERUPT_MARK, ERUPT_R, 4, a)


func _spires(dt: float) -> void:
	for s: Dictionary in spires.duplicate():
		var was: float = float(s["t"]) - float(s["delay"])
		s["t"] = float(s["t"]) + dt
		var t := was + dt
		if t < 0.0:
			continue
		var at: Vector3 = s["at"]
		var r: float = s["r"]
		if was < 0.0:
			# up it comes: leaning up the screen, so its length shows
			var mi := MeshInstance3D.new()
			mi.mesh = Vox.get_mesh("soul_spire")
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var y := Vector3(float(s["lean"]), 0.75, -0.66).normalized()
			var x := y.cross(Vector3(0, 0, 1)).normalized()
			mi.transform = Transform3D(Basis(x, y, x.cross(y)) * Basis(Vector3.UP, float(s["turn"])), at)
			add_child(mi)
			s["mi"] = mi
			game.fx.sprite(at + Vector3(0, 0.4, 0), Vector3.ZERO, r * 2.4, r * 0.6, 0.14, Color(1, 1, 1), 0.0)
			game.sfx.play("tile_break")
		var f := clampf(t / SPIRE_UP, 0.0, 1.0)
		var up := 1.0 - pow(1.0 - f, 3.0)
		var k := r * randf_range(0.98, 1.02)
		(s["mi"] as MeshInstance3D).scale = Vector3(k * (0.5 + 0.5 * up), k * maxf(up, 0.02), k * (0.5 + 0.5 * up))
		if t < SPIRE_LIVE and game.combat_on():
			var d := game.player.position - at
			if Vector2(d.x, d.z).length() < r + Player.HIT_R:
				game.touch_player("soul spire")
		if t >= SPIRE_STAND:
			_shatter(s)


## A spire's time is up: it breaks into sparks (and a few slow shells).
func _shatter(s: Dictionary) -> void:
	var at: Vector3 = s["at"]
	var r: float = s["r"]
	var top := at + Vector3(0, 1.2, -1.0) * r
	for i in 5:
		var a := randf() * TAU
		game.fx.sprite(at.lerp(top, randf()), Vector3(cos(a), 0, sin(a)) * randf_range(3.0, 8.0), 0.5, 0.08, 0.35, BEAM_COL, 0.0)
	game.fx.shockwave(at + Vector3(0, 0.3, 0), r * 1.3, BEAM_COL)
	var n := int(s["shells"])
	if n > 0 and game.boss_can_fire(at):
		var a0 := randf() * TAU
		for k in n:
			game.bullets.fire(at, a0 + TAU * k / n, 3.2, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.SMALL)
	_drop_spire(s)


func _drop_spire(s: Dictionary) -> void:
	if s.has("mi"):
		(s["mi"] as MeshInstance3D).queue_free()
	var a = s["a"]
	if a != null and is_instance_valid(a):
		game.remove_enemy(a)
		(a as Enemy).queue_free()
	spires.erase(s)


# ------------------------------------------------------------ beams

## Starts a beam along `pts` (the path is marked for `lock`, then burns for
## `burn`), announced on `node`; with `trace` it leaves a faint line behind.
func _beam(pts: PackedVector3Array, lock: float, burn: float, node: Enemy, sound: bool, trace := false) -> void:
	beams.append({"pts": pts, "t": 0.0, "lock": lock, "burn": burn, "hw": BEAM_HW, "trace": trace})
	game.warn(node, lock + burn, Game.Warn.MOVE, 0.8, {"laser": pts}, sound)


## A beam strung between motes i and j (out at their posts), on past both.
func _chord(i: int, j: int, lock: float, burn: float, sound: bool) -> void:
	var a := mote_to[i]
	var b := mote_to[j]
	var d := (b - a).normalized()
	_beam(PackedVector3Array([a - d * 8.0, b + d * 8.0]), lock, burn, motes[i], sound, true)
	game.sfx.play("slam")


## A beam from mote i (out at its post) through the ship and on.
func _ray(i: int, lock: float, burn: float, sound: bool) -> void:
	var a := mote_to[i]
	var d := game.player.position - a
	d.y = 0.0
	d = d.normalized() if d.length() > 1.0 else Vector3(0, 0, 1)
	_beam(PackedVector3Array([a - d * 8.0, a + d * 60.0]), lock, burn, motes[i], sound)


## The LATTICE (PRISM): the motes out to the edges of the screen, beams
## strung between them round the ship, then two through it.
func _lattice(at: float) -> void:
	if _once("lat_out", at):
		var p := game.player.position
		var zt := game.field_top + 1.3
		var zb := game.field_bottom - 2.4
		var x := clampf(p.x, -9.0, 9.0)
		var z := clampf(p.z, game.field_top + 5.0, game.field_bottom - 3.0)
		var w := game.half_width_at(z) - 1.0
		var posts := [Vector3(x - 3.0, 0, zt), Vector3(x - 3.0, 0, zb), Vector3(x + 3.0, 0, zt), Vector3(x + 3.0, 0, zb), Vector3(-w, 0, z), Vector3(w, 0, z)]
		for i in 6:
			mote_to[i] = posts[i]
		motes_out = true
		game.sfx.play("deflect")
	if _once("lat_cols", at + 0.75):
		_chord(0, 1, 1.0, 0.6, true)
		_chord(2, 3, 1.0, 0.6, false)
	if _once("lat_row", at + 1.35):
		_chord(4, 5, 1.0, 0.6, true)
	if _once("lat_ray0", at + 2.0):
		_ray(0, 0.9, 0.5, true)
	if _once("lat_ray1", at + 2.5):
		_ray(2, 0.9, 0.5, true)
	if _once("lat_in", at + 4.0):
		motes_out = false


## The STAR MANDALA (SOULSTICE): the motes at the corners of a hexagon round
## the whole screen draw a six-pointed star across it stroke by stroke, a
## beam through the ship between the strokes.
func _mandala(at: float) -> void:
	if _once("man_out", at):
		web_a += 0.4
		for i in 6:
			mote_to[i] = _border(web_a + TAU * i / 6.0)
		motes_out = true
		game.sfx.play("deflect")
	var seq := [[0, 2], [4, -1], [2, 4], [0, -1], [4, 0], [2, -1], [1, 3], [3, 5], [5, 1]]
	for k in seq.size():
		if _once("man%d" % k, at + 0.8 + k * 0.5):
			var q: Array = seq[k]
			if int(q[1]) < 0:
				_ray(q[0], 0.85, 0.35, true)
			else:
				_chord(q[0], q[1], 0.85, 0.35, true)
	if _once("man_in", at + 0.8 + seq.size() * 0.5 + 1.0):
		motes_out = false


## A point on the edge of the screen (a little inside it), `theta` round
## from the middle of the field.
func _border(theta: float) -> Vector3:
	var z0 := game.field_top + 1.3
	var z1 := game.field_bottom - 2.4
	var d := Vector3(cos(theta), 0, sin(theta))
	var t := 1e9
	if absf(d.x) > 0.001:
		t = minf(t, 15.5 / absf(d.x))
	if absf(d.z) > 0.001:
		t = minf(t, (z1 - z0) * 0.5 / absf(d.z))
	var p := Vector3(0, 0, (z0 + z1) * 0.5) + d * t
	var w := game.half_width_at(p.z) - 1.0
	p.x = clampf(p.x, -w, w)
	return p


## The SOLSTICE (SOULSTICE): the star gathers light, its lane straight down
## the screen marked and filling; then a wide beam burns down the lane
## while rings of shells roll off the star.
func _solstice(at: float) -> void:
	var end := Vector3(pos.x, 0, game.field_bottom + 3.0)
	if _once("sol_w", at):
		hold_t = SOL_CHARGE + SOL_BURN + 0.3
		game.warn(core, SOL_CHARGE, Game.Warn.MOVE, core.radius, {"lane": PackedVector3Array([pos, end]), "hw": SOL_HW + 0.3, "show": true})
		game.sfx.play("slam")
	if _charging():
		# light pouring in
		for i in 2:
			var a := randf() * TAU
			var off := Vector3(cos(a), 0, sin(a)) * randf_range(7.0, 13.0)
			game.fx.sprite(pos + off + Vector3(0, 0.6, 0), -off / 0.5, 0.4, 0.08, 0.5, BEAM_COL.lerp(CoreModels.FIRE, 0.6), 0.0)
	if _once("sol", at + SOL_CHARGE):
		beams.append({"pts": PackedVector3Array([pos, end]), "t": 0.0, "lock": 0.0, "burn": SOL_BURN, "hw": SOL_HW, "trace": false})
		game.warn(core, SOL_BURN, Game.Warn.MOVE, core.radius, {"lane": PackedVector3Array([pos, end]), "hw": SOL_HW + 0.3}, false)
		game.flash_a = maxf(game.flash_a, 0.3)
		game.shake(1.2)
		game.sfx.play("exp_l")
		game.fx.shockwave(pos + Vector3(0, 0.5, 0), 8.0, CoreModels.FIRE)
	for i in 3:
		if _once("sol_ring%d" % i, at + SOL_CHARGE + 0.2 + i * 0.5) and game.boss_can_fire(pos):
			flower_a += 0.2
			game.bullets.ring(pos, 16, 4.4, Bullets.SHELL, self, flower_a)


func _charging() -> bool:
	return phase == 3 and morph_t <= 0.0 and fired.has("sol_w") and not fired.has("sol")


## Where a ray on the plane from `from` at angle `a` leaves the screen.
func _edge(from: Vector3, a: float) -> Vector3:
	var d := Vector3(cos(a), 0, sin(a))
	var reach := 80.0
	if d.z > 0.01:
		reach = (game.field_bottom + 2.0 - from.z) / d.z
	elif d.z < -0.01:
		reach = (game.field_top - 2.0 - from.z) / d.z
	if absf(d.x) > 0.01:
		reach = minf(reach, (signf(d.x) * (game.hw_top + 3.0) - from.x) / d.x)
	return from + d * maxf(reach, 0.0)


func _beams(dt: float) -> void:
	for b: Dictionary in beams.duplicate():
		b["t"] = float(b["t"]) + dt
		var lock := float(b["lock"])
		var pts: PackedVector3Array = b["pts"]
		if float(b["t"]) >= lock + float(b["burn"]):
			if b["trace"]:
				traces.append({"pts": pts, "t": 0.0})
			beams.erase(b)
			continue
		if float(b["t"]) >= lock and game.combat_on():
			var hw := float(b["hw"])
			for i in pts.size() - 1:
				if _on_beam(pts[i], pts[i + 1], game.player.position, hw):
					game.touch_player("star soul beam")
			if randf() < 0.5:
				var i := randi() % maxi(pts.size() - 1, 1)
				var q := pts[i].lerp(pts[i + 1], randf())
				if game.on_field(q, 0.0):
					game.fx.spark(q + Vector3(randf_range(-hw, hw), 0.4, 0), BEAM_COL, 1, 0.3)
	for tr: Dictionary in traces.duplicate():
		tr["t"] = float(tr["t"]) + dt
		if float(tr["t"]) >= TRACE:
			traces.erase(tr)


func _on_beam(from: Vector3, to: Vector3, pp: Vector3, hw: float) -> bool:
	var c := Geometry3D.get_closest_point_to_segment(Vector3(pp.x, 0, pp.z), from, to)
	return Vector2(pp.x - c.x, pp.z - c.z).length() < hw + Player.HIT_R


## Everything it draws flat on the field (just over the plane): the marks
## where spires will come up (white, closing in), the traces a mandala
## leaves, and every beam: the flickering sight, then the band with the
## bright line in it (blinking at the end), then the beam.
func _draw() -> void:
	fx_mesh.clear_surfaces()
	if beams.is_empty() and traces.is_empty() and spires.is_empty():
		return
	var any := false
	fx_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var white := Color(1, 1, 1)
	for s: Dictionary in spires:
		var t := float(s["t"])
		var delay := float(s["delay"])
		if t >= delay:
			continue
		any = true
		var f := t / delay
		var at: Vector3 = s["at"]
		var r: float = s["r"]
		_diamond(at, r, 0.07, 0.75, white)
		_diamond(at, r * lerpf(2.0, 1.0, f * f), 0.05, 0.3 + 0.5 * f, white)
	for tr: Dictionary in traces:
		any = true
		var pts: PackedVector3Array = tr["pts"]
		_seg(pts[0], pts[1], 0.08, 0.5 * (1.0 - float(tr["t"]) / TRACE), BEAM_COL)
	for b: Dictionary in beams:
		any = true
		var pts: PackedVector3Array = b["pts"]
		var t := float(b["t"])
		var lock := float(b["lock"])
		var hw := float(b["hw"])
		for i in pts.size() - 1:
			var p0 := pts[i]
			var p1 := pts[i + 1]
			if t < minf(SIGHT, lock):
				_seg(p0, p1, 0.06, 0.45 + 0.25 * sin(game.time * 70.0), white)
			elif t < lock:
				var left := lock - t
				_seg(p0, p1, hw, 0.16, BEAM_COL)
				if left > 0.15 or int(left * 40.0) % 2 == 0:
					_seg(p0, p1, 0.1, 1.0, white)
			else:
				var w := hw * (1.0 + 0.08 * sin(game.time * 60.0))
				var f := clampf((lock + float(b["burn"]) - t) / 0.2, 0.0, 1.0) * clampf((t - lock) / 0.06 + 0.3, 0.0, 1.0)
				var col := BEAM_COL if hw < 1.0 else BEAM_COL.lerp(CoreModels.FIRE, 0.7)
				_seg(p0, p1, w * 1.6, 0.35 * f, col)
				_seg(p0, p1, w * 1.05, f, col)
				if hw >= 1.0:
					# a wide beam: its edges drawn, so its reach is plain
					var side := Vector3(-(p1 - p0).z, 0, (p1 - p0).x).normalized() * hw
					_seg(p0 + side, p1 + side, 0.12, f, white)
					_seg(p0 - side, p1 - side, 0.12, f, white)
	if not any:
		# (a surface must hold something)
		_seg(Vector3.ZERO, Vector3(0.01, 0, 0), 0.0, 0.0, white)
	fx_mesh.surface_end()


func _diamond(at: Vector3, r: float, w: float, a: float, col: Color) -> void:
	var c := [Vector3(r, 0, 0), Vector3(0, 0, r), Vector3(-r, 0, 0), Vector3(0, 0, -r)]
	for i in 4:
		_seg(at + c[i], at + c[(i + 1) % 4], w, a, col)


func _seg(p0: Vector3, p1: Vector3, w: float, a: float, c: Color) -> void:
	var col := Color(c.r, c.g, c.b, a)
	var q0 := p0 + Vector3(0, 0.36, 0)
	var q1 := p1 + Vector3(0, 0.36, 0)
	var dd := q1 - q0
	var s := Vector3(-dd.z, 0, dd.x).normalized() * w
	for q: Array in [[q0 - s, 0.0], [q0 + s, 1.0], [q1 + s, 1.0], [q0 - s, 0.0], [q1 + s, 1.0], [q1 - s, 0.0]]:
		fx_mesh.surface_set_color(col)
		fx_mesh.surface_set_uv(Vector2(0, q[1]))
		fx_mesh.surface_add_vertex(q[0])


# ------------------------------------------------------------ the end

func gauge() -> Dictionary:
	if phase < 1 or phase >= 4:
		return {}
	return {"frac": core.hp / core.max_hp, "color": Color(0.5, 1.0, 0.76).lerp(Color(1.0, 0.9, 0.7), heat), "name": INFO["name"], "name_color": Color(0.8, 1.0, 0.9), "x": 0.2, "w": 0.6, "h": 8.0, "name_y": 72.0}


func force_defeat() -> void:
	if phase < 4:
		game.kill(core)


## "B": straight into PRISM, "C": into SOULSTICE (its light down to there).
func viewer_skip(to: String) -> void:
	if to != "B" and to != "C":
		return
	center.z = game.field_top + HOME_Z
	pos = center
	st = 0.0
	glow = 1.0
	core.armored = false
	for q in lobes:
		q.armored = false
	if to == "B":
		core.hp = core.max_hp * (FORM_AT[0] - 0.01)
		phase = 1
		_morph(2)
	else:
		core.hp = core.max_hp * (FORM_AT[1] - 0.01)
		phase = 2
		_morph(3)
	chips = int((1.0 - core.hp / core.max_hp) / CHIP)
	for i in shape.size():
		shape[i] = want[i]
	_pose()
	_zones()
	_motes(0.0, true)


func debug_state() -> String:
	var names := ["enter", "OBELISK", "PRISM", "SOULSTICE", "dying"]
	return "form %s %.1fs%s  light %d/%d  cycle %.1f%s  beams %d  spires %d" % [names[phase], form_t, " (morph)" if morph_t > 0.0 else "", int(maxf(core.hp, 0.0)), int(HP), cycle_t, ("  thrust " + thrust) if thrust != "" else "", beams.size(), spires.size()]


func _die() -> void:
	defeated = true
	phase = 4
	dying_t = 0.0
	_call_off()
	traces.clear()
	for s: Dictionary in spires.duplicate():
		_drop_spire(s)
	lances.clear()
	disarm()
	var conv := game.bullets.cancel_all()
	for b in conv:
		game.items.spawn(b, Items.ENERGY, 1.0)
	game.boss_dying()


## Its death: whatever shape it was in, it draws itself shut, shaking,
## cracks of light opening between its plates; then the plates fly apart,
## the seed swells white and goes up in the last blast, and space drops out
## of warp.
func _dying(dt: float) -> void:
	dying_t += dt
	heat = 1.0
	center.z += dt * 0.5
	var jit := minf(dying_t, 2.0) * 0.12
	center.x += randf_range(-jit, jit)
	if int(dying_t * 9.0) != int((dying_t - dt) * 9.0):
		var off := Vector3(randf_range(-4.5, 4.5), 0, randf_range(-4.0, 4.0))
		game.fx.explode(pos + off, randf_range(1.2, 2.4), Vector3.ZERO, CoreModels.GLASS, Color(0.55, 1.0, 0.8))
		game.sfx.play("exp_m")
		game.shake(0.4)
		for i in 3:
			var a := randf() * TAU
			game.fx.sprite(pos + Vector3(0, 0.6, 0), Vector3(cos(a), 0, sin(a)) * randf_range(8.0, 16.0), 0.7, 0.1, 0.5, BEAM_COL, 0.0)
	if dying_t < 2.4:
		want[OPEN] = 0.0
		want[SPLIT] = 0.0
		want[STRETCH] = 1.0
		want[SQUEEZE] = 1.0
		want[GAP] = 0.15 + dying_t * 0.2
	else:
		# apart: no easing now, the plates just go
		shape[GAP] += dt * 16.0 * (dying_t - 2.3)
		want[GAP] = shape[GAP]
		shape[OPEN] += dt * 1.5
		want[OPEN] = shape[OPEN]
		seed_mi.scale = Vector3.ONE * (1.0 + (dying_t - 2.4) * 1.6)
	if dying_t > 3.6:
		game.big_blast(pos, 1.0, CoreModels.GLASS)
		for k in 6:
			var a := TAU * k / 6.0
			game.fx.explode(pos + Vector3(cos(a) * 8.0, 0, sin(a) * 5.0), 4.0, Vector3.ZERO, CoreModels.GLASS, Color(0.55, 1.0, 0.8))
		for i in 40:
			var a := randf() * TAU
			game.fx.sprite(pos + Vector3(0, 0.6, 0), Vector3(cos(a), 0, sin(a)) * randf_range(14.0, 40.0), 0.9, 0.12, randf_range(0.6, 1.0), BEAM_COL, 0.0)
		game.sfx.play("exp_l")
		game.shake(2.2)
		game.backdrop.warp_out(0.3)
		destroyed = true
		finished = true
		visible = false
		fx_mesh.clear_surfaces()
		for q in [core] + lobes + motes:
			game.remove_enemy(q)
			q.visible = false
		game.boss_destroyed(self)
