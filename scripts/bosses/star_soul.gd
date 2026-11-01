extends BossBase
## Stage 5's last boss STAR SOUL: the core that sat inside every Cortex,
## out on its own in warp space, cut like a gem (CoreModels: an octagonal
## brilliant of eight wedges round a small heart, emerald, lit from
## inside, glints running over its facets as it turns). Only the gem (its
## heart) can be hurt. Round it turns a barrier of hexagonal panels of
## light (twelve slots, two left open): blue like every breakable cover, a
## panel breaks after a few hits and builds itself back a few seconds
## later, so the barrier takes some of the fire, never all of it.
## Three forms, one after another as its light runs down (or after a while):
##   BRILLIANT  the whole gem, turning: shell spokes from its eight points,
##              aimed needle volleys, a flower of shells, iron balls weaving
##              at the ship; its signature, the REFRACTION: a beam into a
##              prism of light hung over the ship, three beams fanning out
##              of it down the screen (all the lines marked first: the ship
##              goes between them)
##   SCATTER    the eight wedges break away and circle the heart, firing in
##              turn; two at a time they turn on the ship and dash straight
##              through (the lane is marked), shedding shells, and come
##              back in from the top; the heart shines into the three lowest
##              and they bend its beam down at the ship
##   SOULSTICE  (its rage) the wedges lock back on point out, a star
##              spinning fast: spirals of shells from the points, heavy
##              balls that burst into rings, and the PRISM CROSS: four beams
##              from the points, swinging round with the star (run with
##              them, or slip into the gap they never reach)
## The wedges can't be shot (shots pass by them), but they ram. A quiet
## moment while it changes form: the heart can be hit then too.

const INFO := {
	"name": "STAR SOUL", "role": "boss",
	"desc": "最終面のボス 2 体目（最終ボス）。これまでの CORTEX の奥にあったコアだけが独立し、宝石のようにカットされて輝く（8 つのくさびが組み合った八角のブリリアントと、中の小さな心臓。エメラルド色で内から光り、回るとファセットにきらめきが走る）。当たるのは宝石（心臓）だけ。まわりを六角形の光のバリアが回る（12 枠のうち 2 枠は空き）：壊せる覆いなので青、数発で割れて数秒後に張り直す。光が減るにつれて（または時間で）姿を変える。BRILLIANT：宝石のまま回り、8 つの角から物理弾の放射、狙いの針弾、花びら、蛇行する鉄球弾。大技 REFRACTION：自機の上に光のプリズムを吊り、そこへビームを撃ち込むと 3 本に分かれて下へ広がる（線は先に予兆、あいだに入る）。SCATTER：8 つのくさびが分かれて心臓のまわりを回り、交代で撃つ。2 つずつ自機を向いて画面を突き抜け（通り道を予兆）、物理弾をこぼし、上から戻ってくる。心臓が下側の 3 つへビームを当て、くさびがそれを自機へ曲げる。SOULSTICE（発狂）：くさびが先を外へ向けて戻り、星形で速く回る。先から渦巻きの物理弾、輪にはじける大型弾、大技 PRISM CROSS（4 つの先から 4 本のビームが星といっしょに回る。ついて回るか、届かない隙間へ）。くさびは撃てない（ショットは素通り）が、体当たりあり。姿を変える間は静かで、そのあいだも宝石は撃てる",
	"demos": [["FULL", ""], ["SCATTER", "B"], ["SOULSTICE", "C"]],
}

const HEART_HP := 4500.0
const HEART_SCORE := 150000
## the form changes at these shares of its light left (or after FORM_T)
const FORM_AT := [0.66, 0.33]
const FORM_T := [42.0, 40.0]
const MORPH := 2.2  # changing form: quiet this long
## per form (brilliant, scatter, soulstice): the gem's hit radius, the
## barrier's radius and turn (rad/s), the time a broken panel stays down
const HIT_R := [2.7, 1.8, 2.3]
const WARD_R := [5.4, 4.6, 6.3]
const WARD_W := [0.3, -0.36, 0.48]
const WARD_BACK := [6.5, 6.0, 4.5]
const WARD_SLOTS := 12
const WARD_OPEN := [0, 6]  # slots left without a panel
const WARD_HP := 40.0
const WARD_SCORE := 300
const WARD_ENERGY := 8.0
const WARD_BUILD := 0.8
const SPIN := [0.35, 0.0, 0.9]
## the wedges: their orbit round the heart (half width, half height, turn),
## how far out they stand as a star, and their dash
const ORBIT := Vector3(10.5, 6.0, 0.45)
const STAR_D := 3.4
const STAR_S := 0.82
const DASH_AIM := 0.9
const DASH_SPEED := 30.0
const DASH_HW := 1.1
const BACK_T := 1.3
## beams: the sight flickers, then the band holds, then it burns
const SIGHT := 0.45
const BEAM_HW := 0.5
const BEAM_COL := Color(0.6, 1.0, 0.78)
const CROSS_W := 0.34
const CYCLE := [9.5, 10.0, 10.5]

var heart: Enemy
var heart_mesh: MeshInstance3D
var shards: Array[Enemy] = []
var shard_mesh: Array[MeshInstance3D] = []
var shard_mat: Array[ShaderMaterial] = []
## per wedge: {mode: "form" | "aim" | "dash" | "back", t, ang (dash heading), from}
var shard_st: Array[Dictionary] = []
var wards: Array[Enemy] = []
var ward_mat: Array[ShaderMaterial] = []
var ward_slot: Array[int] = []
var ward_down: Array[float] = []  # seconds until a broken panel builds back (0 = up)
var ward_build: Array[float] = []  # 0..1 while it builds
var ward_a := 0.0
var ward_r := 5.4
## beams: {pts (a polyline on the plane), t, lock, burn, warn (its warning's
## `to`), tip: the wedge it shines from, turning with it (-1 = fixed)}
var beams: Array[Dictionary] = []
var beam_mi: MeshInstance3D
var beam_mesh: ImmediateMesh
var prism := Vector3.INF  # where REFRACTION's prism hangs (INF = none)
var center := Vector3.ZERO
var phase := 0  # 0 enter, 1 BRILLIANT, 2 SCATTER, 3 SOULSTICE, 4 dying
var st := 0.0
var form_t := 0.0
var morph_t := 0.0
var cycle_t := 0.0
var fired := {}
var spin_a := 0.0
var spin_w := 0.35
var orbit_a := 0.0
var orbit_w := 0.0
var spoke_t := 0.0
var spoke_k := 0
var volley_t := 0.0
var volley_k := 0
var flower_a := 0.0
var cross_dir := 1.0
var aim_at := Vector3.ZERO
var destroyed := false
var dying_t := 0.0
var heat := 0.0


static var _beam_mat: ShaderMaterial


func setup(g: Game) -> void:
	game = g
	center = Vector3(0, 0, game.field_top - 7.0)
	# the barrier's panels first (shots meet them on the way in), then the
	# gem; the wedges can't be hit, so their place in the list is no matter
	for s in WARD_SLOTS:
		if WARD_OPEN.has(s):
			continue
		var w := game.spawn_part(self, "", 1.3)
		w.hp = WARD_HP
		w.max_hp = WARD_HP
		w.score = WARD_SCORE
		w.energy_drop = WARD_ENERGY
		w.blast = 0.6
		w.debris_col = Color(0.4, 0.7, 1.0)
		w.ram = false
		w.lock = false  # the homing lasers go for the gem
		var m := MeshInstance3D.new()
		m.mesh = Vox.get_mesh("soul_ward")
		var mat := (m.mesh.surface_get_material(0) as ShaderMaterial).duplicate() as ShaderMaterial
		mat.set_shader_parameter("seed", float(s))
		mat.set_shader_parameter("build", 0.0)
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.add_child(m)
		wards.append(w)
		ward_mat.append(mat)
		ward_slot.append(s)
		ward_down.append(0.0)
		ward_build.append(0.0)
	heart = game.spawn_part(self, "", HIT_R[0])
	heart.hp = HEART_HP
	heart.max_hp = HEART_HP
	heart.score = HEART_SCORE
	heart.armored = true
	heart.blast = 3.0
	heart.debris_col = CoreModels.EMERALD
	heart_mesh = MeshInstance3D.new()
	heart_mesh.mesh = Vox.get_mesh("soul_heart")
	heart_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	heart_mesh.material_override = CoreModels.gem_material("heart").duplicate()
	heart.add_child(heart_mesh)
	for k in 8:
		var s := game.spawn_part(self, "", 1.6)
		s.shootable = false  # shots pass the wedges: only the gem's heart is a target
		s.armored = true
		s.hp = 1e9
		s.ram = false
		var m := MeshInstance3D.new()
		m.mesh = Vox.get_mesh("soul_shard")
		var mat := CoreModels.gem_material("shard").duplicate() as ShaderMaterial
		m.material_override = mat
		s.add_child(m)
		shards.append(s)
		shard_mesh.append(m)
		shard_mat.append(mat)
		shard_st.append({"mode": "form", "t": 0.0, "ang": 0.0})
	if _beam_mat == null:
		_beam_mat = ShaderMaterial.new()
		_beam_mat.shader = load("res://shaders/lightning.gdshader")
		_beam_mat.render_priority = 2
	beam_mesh = ImmediateMesh.new()
	beam_mi = MeshInstance3D.new()
	beam_mi.mesh = beam_mesh
	beam_mi.material_override = _beam_mat
	beam_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam_mi.extra_cull_margin = 16384.0
	add_child(beam_mi)
	_place_shards(0.0, true)
	_place_wards(0.0)


## A panel's last hit breaks it here, not as a kill: no fire, it shatters.
func on_hit(e: Enemy, dmg: float) -> float:
	var k := wards.find(e)
	if k >= 0 and dmg >= e.hp:
		_break_ward(k, true)
		return 0.0
	return dmg


func on_part_killed(e: Enemy) -> void:
	if e == heart:
		_die()


## Panel k shatters into blue sparks (its points and energy if `scored`)
## and builds itself back later.
func _break_ward(k: int, scored: bool) -> void:
	var e := wards[k]
	e.dead = true
	game.remove_enemy(e)
	ward_down[k] = WARD_BACK[clampi(phase - 1, 0, 2)] if scored else 0.0
	ward_build[k] = 0.0
	if scored:
		game.add_score(e.score, true)
		game.items.burst_energy(e.position, e.energy_drop)
	for i in 6:
		var a := TAU * i / 6.0 + randf() * 0.5
		game.fx.sprite(e.position + Vector3(0, 0.4, 0), Vector3(cos(a), 0, sin(a)) * randf_range(3.0, 6.0), 0.5, 0.1, 0.35, Color(0.5, 0.8, 1.0), 0.0)
	game.fx.shockwave(e.position + Vector3(0, 0.3, 0), 1.6 * e.radius, Color(0.4, 0.75, 1.0))
	game.sfx.play("tile_break")


func tick(dt: float) -> void:
	if destroyed:
		return
	st += dt
	match phase:
		0:
			center.z = move_toward(center.z, game.field_top + 8.0, 4.2 * dt)
			for k in wards.size():
				ward_build[k] = minf(1.0, st / 3.6)
			if st > 3.8:
				phase = 1
				st = 0.0
				heart.armored = false
				game.boss_fight_started()
		1, 2, 3:
			form_t += dt
			if morph_t > 0.0:
				morph_t -= dt
				if morph_t <= 0.0:
					cycle_t = 0.0
					fired.clear()
			else:
				_attacks(dt)
			_next_form()
			if phase >= 2:
				center.x = move_toward(center.x, sin(form_t * 0.42) * 3.2, 3.0 * dt)
		4:
			_dying(dt)
			if destroyed:
				return
	heat = move_toward(heat, 1.0 if phase >= 3 else 0.0, dt * 0.8)
	var spin_to: float = SPIN[clampi(phase - 1, 0, 2)]
	if _crossing():
		spin_to = CROSS_W * cross_dir
	spin_w = move_toward(spin_w, spin_to, dt * 1.2)
	spin_a += spin_w * dt
	orbit_a += orbit_w * dt
	_place_shards(dt, false)
	_place_wards(dt)
	_wards(dt)
	_beams(dt)
	_draw_beams()
	heart.radius = HIT_R[clampi(phase - 1, 0, 2)]
	heart_mesh.rotation.y = -spin_a * 1.3
	var hs := 0.9 if phase <= 1 else (1.3 if phase == 2 else 1.1)
	heart_mesh.scale = heart_mesh.scale.lerp(Vector3.ONE * hs, clampf(dt * 3.0, 0.0, 1.0))
	# hits and warnings light the gem up from inside (no overlay: a white
	# wash would take its colour away under steady fire)
	var glow := 1.0 + heat * 0.4 + heart.flash * 0.6 + _pulse(heart)
	var hm := heart_mesh.material_override as ShaderMaterial
	hm.set_shader_parameter("heat", heat)
	hm.set_shader_parameter("light", 1.3 * glow)
	for k in 8:
		var m := shard_mat[k]
		m.set_shader_parameter("heat", heat)
		var aiming := String(shard_st[k]["mode"]) == "aim" and fmod(game.time * 10.0, 1.0) < 0.5
		# docked, a wedge is the gem's body: it lights up with the heart
		var own := 1.0 + heat * 0.4 + _pulse(shards[k])
		m.set_shader_parameter("light", 2.2 if aiming else (glow if phase != 2 else own))


## An attacker's warning pulse (as Enemy._shade gives a model): quickening
## as the attack nears.
func _pulse(e: Enemy) -> float:
	if e.warn_t <= 0.0:
		return 0.0
	var f := 1.0 - e.warn_t / maxf(e.warn_dur, 0.01)
	return (0.3 + 0.7 * f) * (0.5 + 0.5 * sin(e.warn_t * lerpf(18.0, 40.0, f)))


## Health down to the next form's share, or the form has gone on long
## enough: change.
func _next_form() -> void:
	if phase == 1 and (heart.hp < heart.max_hp * FORM_AT[0] or form_t > FORM_T[0]):
		_morph(2)
	elif phase == 2 and morph_t <= 0.0 and (heart.hp < heart.max_hp * FORM_AT[1] or form_t > FORM_T[1]):
		_morph(3)


func _morph(to: int) -> void:
	if game.log_status:
		print("SOUL form=%d after %.1fs light=%d" % [to, form_t, int(heart.hp)])
	phase = to
	form_t = 0.0
	morph_t = MORPH
	cycle_t = 0.0
	fired.clear()
	_cancel_beams()
	game.shake(1.0)
	game.flash_a = maxf(game.flash_a, 0.2)
	game.sfx.play("slam")
	if to == 2:
		# the wedges blow apart, then take their places round the heart
		orbit_a = spin_a
		orbit_w = 0.0
		for k in 8:
			shard_st[k] = {"mode": "burst", "t": 0.0, "ang": 0.0}
	else:
		orbit_w = 0.0
		for k in 8:
			shard_st[k] = {"mode": "form", "t": 0.0, "ang": 0.0}
		game.show_msg("SOULSTICE", "", 1.5, true)
	for k in 8:
		var a := TAU * k / 8.0 + spin_a
		game.fx.sprite(center + Vector3(cos(a), 0.6, sin(a)) * 2.0, Vector3(cos(a), 0, sin(a)) * 9.0, 0.6, 0.1, 0.5, BEAM_COL, 0.0)


func _crossing() -> bool:
	for b in beams:
		if int(b["tip"]) >= 0:
			return true
	return phase == 3 and morph_t <= 0.0 and fired.has("w_cross") and not fired.has("cross_done")


# ------------------------------------------------------------ the wedges

## Where wedge k belongs in the current form: [position, heading, scale].
func _shard_goal(k: int) -> Array:
	var a := TAU * k / 8.0 + spin_a
	match phase:
		2:
			var o := TAU * k / 8.0 + orbit_a
			var p := center + Vector3(cos(o) * ORBIT.x, 0, sin(o) * ORBIT.y)
			p.z = maxf(p.z, game.field_top + 1.5)
			return [p, -o, 1.0]
		3:
			var d := STAR_D + 0.35 * sin(form_t * 2.2)
			return [center + Vector3(cos(a), 0, sin(a)) * d, -a + PI, STAR_S]
		4:
			return [shards[k].position, shard_mesh[k].rotation.y, shard_mesh[k].scale.x]
	return [center + Vector3(cos(a), 0, sin(a)) * CoreModels.MID, -a, 1.0]


func _place_shards(dt: float, now: bool) -> void:
	for k in 8:
		var s := shards[k]
		var m := shard_mesh[k]
		var ss: Dictionary = shard_st[k]
		var goal := _shard_goal(k)
		var to: Vector3 = goal[0]
		var head: float = goal[1]
		var ease := 7.0
		ss["t"] = float(ss["t"]) + dt
		match String(ss["mode"]):
			"burst":
				# flung out from the gem, then off to its place
				var a := TAU * k / 8.0 + spin_a
				to = center + Vector3(cos(a), 0, sin(a)) * 7.0
				head = -a + float(ss["t"]) * 6.0
				ease = 9.0
				if float(ss["t"]) > 0.45:
					ss["mode"] = "form"
			"aim":
				to = s.position
				head = -float(ss["ang"]) - PI
				ease = 0.0
			"dash":
				s.position += Vector3(cos(float(ss["ang"])), 0, sin(float(ss["ang"]))) * DASH_SPEED * dt
				to = s.position
				head = -float(ss["ang"]) - PI
				_shed(k, dt)
				if not game.on_field(s.position, 3.5):
					# off the screen: back in from the top, over its place
					ss["mode"] = "back"
					ss["t"] = 0.0
					s.position = Vector3(clampf(to.x, -game.hw_top, game.hw_top), 0, game.field_top - 4.0)
					to = s.position
			"back":
				ease = 4.0
				head = lerp_angle(m.rotation.y, head, clampf(dt * 4.0, 0.0, 1.0))
				if float(ss["t"]) > BACK_T:
					ss["mode"] = "form"
					s.ram = phase != 1
		if now:
			s.position = to
			m.rotation.y = head
			m.scale = Vector3.ONE * float(goal[2])
		elif ease > 0.0:
			s.position = s.position.lerp(to, 1.0 - exp(-dt * ease))
			m.rotation.y = lerp_angle(m.rotation.y, head, 1.0 - exp(-dt * ease * 1.4))
			m.scale = m.scale.lerp(Vector3.ONE * float(goal[2]), clampf(dt * 3.0, 0.0, 1.0))
		else:
			m.rotation.y = lerp_angle(m.rotation.y, head, 1.0 - exp(-dt * 10.0))
		# docked in the gem the heart takes the rams; out on their own they ram
		s.ram = phase == 2 or phase == 3
		s.radius = 1.5 if phase == 2 else 1.2
	heart.position = center


## A wedge's point (its inner edge, out at the star's points).
func _tip(k: int) -> Vector3:
	var a := TAU * k / 8.0 + spin_a
	return shards[k].position + Vector3(cos(a), 0, sin(a)) * CoreModels.MID * STAR_S


## A dashing wedge sheds shells either side of its track.
func _shed(k: int, dt: float) -> void:
	var ss: Dictionary = shard_st[k]
	ss["shed"] = float(ss.get("shed", 0.0)) - dt
	if float(ss["shed"]) > 0.0:
		return
	ss["shed"] = 0.09
	var p := shards[k].position
	if not game.can_fire(p):
		return
	var a := float(ss["ang"])
	for s in [-1.0, 1.0]:
		game.bullets.fire(p, a + s * PI * 0.5, 2.4, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.SMALL)


## Two wedges turn on the ship (their lanes marked), then dash through.
func _dash(pick: Array) -> void:
	var first := true
	for k: int in pick:
		var ss: Dictionary = shard_st[k]
		if String(ss["mode"]) != "form":
			continue
		var p := shards[k].position
		var d := game.player.position - p
		var a := atan2(d.z, d.x)
		var end := p + Vector3(cos(a), 0, sin(a)) * 60.0
		shard_st[k] = {"mode": "aim", "t": 0.0, "ang": a}
		game.warn(shards[k], DASH_AIM, Game.Warn.MOVE, 1.5, {"lane": PackedVector3Array([p, end]), "hw": DASH_HW, "show": true}, first)
		first = false
		var kk := k
		get_tree().create_timer(DASH_AIM, false, true).timeout.connect(func() -> void: _go(kk))


func _go(k: int) -> void:
	if destroyed or defeated or String(shard_st[k]["mode"]) != "aim":
		return
	shard_st[k]["mode"] = "dash"
	shard_st[k]["t"] = 0.0
	game.sfx.play("exp_s")


# ------------------------------------------------------------ the barrier

func _place_wards(dt: float) -> void:
	var want: float = WARD_R[clampi(phase - 1, 0, 2)]
	if phase == 0:
		want = WARD_R[0]
	ward_r = move_toward(ward_r, want, dt * 2.5)
	ward_a += WARD_W[clampi(phase - 1, 0, 2)] * dt
	# a slot's arc: the panels fit it with no gap between their hit circles
	var slot := TAU * ward_r / WARD_SLOTS
	var r := minf(1.35, slot * 0.5 - 0.05)
	for k in wards.size():
		var w := wards[k]
		var a := ward_a + TAU * ward_slot[k] / WARD_SLOTS
		w.position = center + Vector3(cos(a), 0, sin(a)) * ward_r
		w.radius = r
		w.rotation.y = -a
		w.scale = Vector3.ONE * (r * 1.08)


func _wards(dt: float) -> void:
	for k in wards.size():
		var w := wards[k]
		var mat := ward_mat[k]
		if ward_down[k] > 0.0 and phase >= 1 and phase <= 3:
			ward_down[k] -= dt
			if ward_down[k] <= 0.0:
				ward_down[k] = 0.0
				ward_build[k] = 0.0
				w.visible = true
			elif ward_down[k] < WARD_BUILD:
				# building back (not solid yet)
				w.visible = true
				ward_build[k] = 1.0 - ward_down[k] / WARD_BUILD
		if w.dead and ward_down[k] <= 0.0 and phase >= 1 and phase <= 3:
			# up again
			w.dead = false
			w.flash = 0.0
			w.hp = WARD_HP
			w.visible = true
			ward_build[k] = 1.0
			game.enemies.append(w)
			game.sfx.play("shield")
		mat.set_shader_parameter("build", ward_build[k])
		mat.set_shader_parameter("hit", w.flash if not w.dead else 0.0)
		mat.set_shader_parameter("wear", 1.0 - w.hp / WARD_HP if not w.dead else 0.0)


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
			_brilliant(dt)
		2:
			_scatter(dt)
		3:
			_soulstice(dt)
	if cycle_t > CYCLE[phase - 1]:
		cycle_t = 0.0
		fired.clear()


func _brilliant(dt: float) -> void:
	# spokes: shells out of the eight points, turning with the gem
	if cycle_t > 0.3 and cycle_t < 2.7:
		spoke_t -= dt
		if spoke_t <= 0.0:
			spoke_t = 0.2
			spoke_k += 1
			for k in range(spoke_k % 2, 8, 2):
				var a := TAU * k / 8.0 + spin_a
				var at := center + Vector3(cos(a), 0, sin(a)) * CoreModels.R
				if game.can_fire(at):
					game.bullets.fire(at, a, 4.6, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if k % 4 == 0 else Bullets.SMALL)
	_needles("n1", 2.9, 7, 30.0, 9.0)
	_needles("n2", 3.7, 9, 46.0, 9.5)
	_refraction(4.6)
	for i in 3:
		if _once("flower%d" % i, 7.1 + i * 0.3):
			flower_a += 0.2
			game.bullets.ring(center, 18, 4.2, Bullets.SHELL, self, flower_a)
	# iron balls from the two points nearest the ship, weaving at it
	if cycle_t >= 8.0 - 0.8 and not fired.has("w_iron"):
		fired["w_iron"] = true
		aim_at = game.player.position
		game.warn(heart, 0.8, Game.Warn.MOVE, heart.radius, aim_at)
	if _once("iron", 8.0):
		var d := aim_at - center
		var base := atan2(d.z, d.x)
		for s in [-1.0, 1.0]:
			var a: float = base + s * 0.5
			var at := center + Vector3(cos(a), 0, sin(a)) * CoreModels.R
			game.bullets.fire(at, atan2(aim_at.z - at.z, aim_at.x - at.x), 5.0, Bullets.IRON, self)
			game.bullets.snake(1.8, 3.2)


func _scatter(dt: float) -> void:
	orbit_w = move_toward(orbit_w, 0.0 if _refracting() else ORBIT.z, dt * 1.5)
	# the wedges fire in turn: small aimed shell fans
	volley_t -= dt
	if volley_t <= 0.0:
		volley_t = 0.5
		for i in 8:
			volley_k = (volley_k + 1) % 8
			if String(shard_st[volley_k]["mode"]) != "form":
				continue
			var p := shards[volley_k].position
			if game.can_fire(p):
				game.bullets.fan(p, game.bullets.aim(p), 3, 28.0, 5.4, Bullets.SHELL, self)
			break
	if _once("dash1", 1.0):
		_dash(_pair(0))
	if _once("dash2", 4.0):
		_dash(_pair(1))
	_needles("n1", 5.5, 11, 60.0, 9.5)
	_refraction2(6.6)
	for i in 2:
		if _once("flower%d" % i, 9.1 + i * 0.3):
			flower_a += 0.25
			game.bullets.ring(center, 16, 4.4, Bullets.SHELL, self, flower_a)


func _soulstice(dt: float) -> void:
	# spirals out of the star's points
	if cycle_t > 0.2 and cycle_t < 3.0:
		spoke_t -= dt
		if spoke_t <= 0.0:
			spoke_t = 0.14
			spoke_k += 1
			for k in range(spoke_k % 2, 8, 2):
				var a := TAU * k / 8.0 + spin_a
				var at := _tip(k)
				if game.can_fire(at):
					game.bullets.fire(at, a, 4.8, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if k % 4 == spoke_k % 4 else Bullets.SMALL)
	# heavy balls that burst into rings
	if cycle_t >= 3.4 - 0.8 and not fired.has("w_heavy"):
		fired["w_heavy"] = true
		aim_at = game.player.position
		game.warn(heart, 0.8, Game.Warn.MOVE, heart.radius, aim_at)
	if _once("heavy", 3.4):
		var d := aim_at - center
		var base := atan2(d.z, d.x)
		for i in 3:
			game.bullets.fire(center, base + (i - 1) * 0.42, 5.0, Bullets.HEAVY, self)
			game.bullets.split(1.5, 10)
		game.sfx.play("exp_m")
	_cross(5.0)
	_needles("n1", 9.4, 9, 40.0, 9.5)


## An aimed volley of energy needles from the gem (announced).
func _needles(key: String, at: float, count: int, spread: float, speed: float) -> void:
	var w := Enemy.WINDUP_SHOT
	if cycle_t >= at - w and not fired.has("w_" + key):
		fired["w_" + key] = true
		game.warn(heart, w, Game.Warn.SHOT, heart.radius)
	if _once(key, at) and game.can_fire(center):
		game.bullets.fan(center, game.bullets.aim(center), count, spread, speed, Bullets.ORB, self, Bullets.NEEDLE)


## Two wedges across from each other for a dash (`n` picks which pair:
## the ones lowest on the screen first).
func _pair(n: int) -> Array:
	var order: Array = range(8)
	order.sort_custom(func(a: int, b: int) -> bool: return shards[a].position.z > shards[b].position.z)
	var first: int = order[n % 8]
	var out := [first]
	# its partner: the next-lowest on the other side of the heart
	for k: int in order:
		if k != first and signf(shards[k].position.x - center.x) != signf(shards[first].position.x - center.x):
			out.append(k)
			break
	return out


# ------------------------------------------------------------ beams

## REFRACTION (BRILLIANT): a prism of light hung over the ship, a beam
## into it from the gem and three fanning out of it down the screen.
func _refraction(at: float) -> void:
	var lock := 1.1
	if cycle_t >= at and not fired.has("refraction"):
		fired["refraction"] = true
		var pp := game.player.position
		prism = Vector3(clampf(pp.x, -9.0, 9.0), 0, lerpf(center.z, pp.z, 0.45))
		var d := pp - prism
		var base := atan2(d.z, d.x)
		_beam(PackedVector3Array([center, prism]), lock, 1.0, heart, true)
		for s in [-1.0, 0.0, 1.0]:
			_beam(PackedVector3Array([prism, _edge(prism, base + s * 0.5)]), lock, 1.0, heart, false)
		game.sfx.play("slam")


## The heart shines into the three lowest wedges and they bend the beam
## down at the ship (SCATTER; they stop turning round it meanwhile).
func _refraction2(at: float) -> void:
	if cycle_t >= at and not fired.has("refraction"):
		fired["refraction"] = true
		var order: Array = []
		for k in 8:
			if String(shard_st[k]["mode"]) == "form":
				order.append(k)
		order.sort_custom(func(a: int, b: int) -> bool: return shards[a].position.z > shards[b].position.z)
		var pp := game.player.position
		var first := true
		for i in mini(3, order.size()):
			var p := shards[order[i]].position
			var off: float = [-4.5, 0.0, 4.5][i] if order.size() >= 3 else 0.0
			var to := game.line_to_bottom(p, pp + Vector3(off, 0, 0))
			_beam(PackedVector3Array([center, p, to]), 1.1, 1.1, shards[order[i]], first)
			first = false
		game.sfx.play("slam")


func _refracting() -> bool:
	for b in beams:
		if int(b["tip"]) < 0:
			return true
	return false


## The PRISM CROSS (SOULSTICE): four beams from every other point of the
## star, swinging round with it.
func _cross(at: float) -> void:
	var lock := 1.2
	var burn := 3.2
	if cycle_t >= at - 0.6 and not fired.has("w_cross"):
		fired["w_cross"] = true
		cross_dir = -cross_dir
	if cycle_t >= at and not fired.has("cross"):
		fired["cross"] = true
		var first := true
		for k in [0, 2, 4, 6]:
			_beam(PackedVector3Array([_tip(k), _tip(k)]), lock, burn, shards[k], first, k)
			first = false
		game.sfx.play("slam")
	if fired.has("cross") and beams.is_empty() and not fired.has("cross_done"):
		fired["cross_done"] = true


## Starts a beam along `pts` (the path is marked for `lock`, then burns for
## `burn`), announced on `node`; `tip` >= 0: it shines out of that wedge's
## point and turns with the star.
func _beam(pts: PackedVector3Array, lock: float, burn: float, node: Enemy, sound: bool, tip := -1) -> void:
	var b := {"pts": pts, "t": 0.0, "lock": lock, "burn": burn, "tip": tip}
	if tip >= 0:
		b["pts"] = _tip_pts(tip)
	game.warn(node, lock + burn, Game.Warn.MOVE, node.radius, _bot_mark(b), sound)
	b["warn"] = game.warnings[game.warnings.size() - 1]["to"]
	beams.append(b)


## What the autopilot keeps out of: the path, or for a turning beam the
## sector it has still to sweep.
func _bot_mark(b: Dictionary) -> Dictionary:
	var tip := int(b["tip"])
	if tip < 0:
		return {"laser": b["pts"]}
	var pts: PackedVector3Array = b["pts"]
	var a := atan2(pts[1].z - pts[0].z, pts[1].x - pts[0].x)
	var left := float(b["lock"]) + float(b["burn"]) - float(b["t"])
	return {"sector": [center, a, a + spin_w * maxf(left, 0.0)], "hw": BEAM_HW}


## From a wedge's point straight out to the edge of the screen.
func _tip_pts(k: int) -> PackedVector3Array:
	var a := TAU * k / 8.0 + spin_a
	var from := _tip(k)
	return PackedVector3Array([from, _edge(from, a)])


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
	for b in beams.duplicate():
		b["t"] = float(b["t"]) + dt
		var tip := int(b["tip"])
		if tip >= 0:
			b["pts"] = _tip_pts(tip)
		(b["warn"] as Dictionary).merge(_bot_mark(b), true)
		var lock := float(b["lock"])
		if b["t"] >= lock + float(b["burn"]):
			beams.erase(b)
			continue
		if b["t"] >= lock and game.combat_on():
			var pts: PackedVector3Array = b["pts"]
			for i in pts.size() - 1:
				if _on_beam(pts[i], pts[i + 1], game.player.position):
					game.touch_player("star soul beam")
			if randf() < 0.5:
				var i := randi() % maxi(pts.size() - 1, 1)
				game.fx.spark(pts[i].lerp(pts[i + 1], randf()) + Vector3(0, 0.4, 0), BEAM_COL, 1, 0.3)
	if not _refracting() and prism != Vector3.INF and not fired.has("refraction_keep"):
		prism = Vector3.INF


func _cancel_beams() -> void:
	beams.clear()
	prism = Vector3.INF
	var i := 0
	while i < game.warnings.size():
		var w: Dictionary = game.warnings[i]
		var nd = w["node"]
		if is_instance_valid(nd) and nd is Enemy and (nd as Enemy).controller == self and w["kind"] == Game.Warn.MOVE:
			game.warnings.remove_at(i)
			continue
		i += 1


func _on_beam(from: Vector3, to: Vector3, pp: Vector3) -> bool:
	var c := Geometry3D.get_closest_point_to_segment(Vector3(pp.x, 0, pp.z), from, to)
	return Vector2(pp.x - c.x, pp.z - c.z).length() < BEAM_HW + Player.HIT_R


## Every beam (in world space, just over the plane): the flickering sight,
## then the band with the bright line in it (blinking at the end), then the
## beam; and REFRACTION's prism, a turning star of light.
func _draw_beams() -> void:
	beam_mesh.clear_surfaces()
	if beams.is_empty() and prism == Vector3.INF:
		return
	beam_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in beams:
		var pts: PackedVector3Array = b["pts"]
		var t := float(b["t"])
		var lock := float(b["lock"])
		for i in pts.size() - 1:
			var p0 := pts[i]
			var p1 := pts[i + 1]
			if t < SIGHT:
				_seg(p0, p1, 0.06, 0.4 + 0.2 * sin(game.time * 70.0))
			elif t < lock:
				var left := lock - t
				_seg(p0, p1, BEAM_HW, 0.16)
				if left > 0.15 or int(left * 40.0) % 2 == 0:
					_seg(p0, p1, 0.1, 1.0)
			else:
				var w := BEAM_HW * (1.0 + 0.08 * sin(game.time * 60.0))
				var f := clampf((lock + float(b["burn"]) - t) / 0.2, 0.0, 1.0)
				_seg(p0, p1, w * 1.7, 0.4 * f)
				_seg(p0, p1, w, f)
	if prism != Vector3.INF:
		var r := 1.1 + 0.15 * sin(game.time * 9.0)
		for i in 2:
			var a := game.time * 2.0 + i * PI * 0.5
			var d := Vector3(cos(a), 0, sin(a)) * r
			_seg(prism - d, prism + d, 0.22, 0.9)
	beam_mesh.surface_end()


func _seg(p0: Vector3, p1: Vector3, w: float, a: float) -> void:
	var col := Color(BEAM_COL.r, BEAM_COL.g, BEAM_COL.b, a)
	var q0 := p0 + Vector3(0, 0.36, 0)
	var q1 := p1 + Vector3(0, 0.36, 0)
	var dd := q1 - q0
	if dd.length_squared() < 0.0001:
		return
	var s := Vector3(-dd.z, 0, dd.x).normalized() * w
	for q: Array in [[q0 - s, 0.0], [q0 + s, 1.0], [q1 + s, 1.0], [q0 - s, 0.0], [q1 + s, 1.0], [q1 - s, 0.0]]:
		beam_mesh.surface_set_color(col)
		beam_mesh.surface_set_uv(Vector2(0, q[1]))
		beam_mesh.surface_add_vertex(q[0])


# ------------------------------------------------------------ the end

func gauge() -> Dictionary:
	if phase < 1 or phase >= 4:
		return {}
	return {"frac": heart.hp / heart.max_hp, "color": Color(0.4, 1.0, 0.66) if not heart.armored else Color(0.55, 0.6, 0.65), "name": INFO["name"], "name_color": Color(0.75, 1.0, 0.85), "x": 0.2, "w": 0.6, "h": 8.0, "name_y": 72.0}


func force_defeat() -> void:
	if phase < 4:
		game.kill(heart)


## "B": straight into SCATTER, "C": into SOULSTICE (its light down to there).
func viewer_skip(to: String) -> void:
	if to != "B" and to != "C":
		return
	center.z = game.field_top + 8.0
	st = 0.0
	heart.armored = false
	for k in wards.size():
		ward_build[k] = 1.0
	if to == "B":
		heart.hp = heart.max_hp * (FORM_AT[0] - 0.01)
		phase = 1
		_morph(2)
	else:
		heart.hp = heart.max_hp * (FORM_AT[1] - 0.01)
		phase = 2
		_morph(3)
	_place_shards(0.0, true)
	_place_wards(0.0)


func debug_state() -> String:
	var names := ["enter", "BRILLIANT", "SCATTER", "SOULSTICE", "dying"]
	var up := 0
	for w in wards:
		if not w.dead:
			up += 1
	return "form %s %.1fs%s  heart %d/%d  wards %d/%d  beams %d" % [names[phase], form_t, " (morph)" if morph_t > 0.0 else "", int(maxf(heart.hp, 0.0)), int(HEART_HP), up, wards.size(), beams.size()]


func _die() -> void:
	defeated = true
	phase = 4
	dying_t = 0.0
	_cancel_beams()
	for k in wards.size():
		if not wards[k].dead:
			_break_ward(k, false)
		wards[k].visible = false
		ward_down[k] = 0.0
	disarm()
	var conv := game.bullets.cancel_all()
	for b in conv:
		game.items.spawn(b, Items.ENERGY, 1.0)
	game.boss_dying()


## Its death: the gem shakes and cracks, light bursting out of it, the
## wedges fly apart, then the heart goes up in the last blast and space
## drops out of warp.
func _dying(dt: float) -> void:
	dying_t += dt
	heat = 1.0
	center.z += dt * 0.6
	if int(dying_t * 9.0) != int((dying_t - dt) * 9.0):
		var off := Vector3(randf_range(-4.0, 4.0), 0, randf_range(-3.0, 3.0))
		game.fx.explode(center + off, randf_range(1.2, 2.4), Vector3.ZERO, CoreModels.EMERALD, Color(0.55, 1.0, 0.75))
		game.sfx.play("exp_m")
		game.shake(0.4)
		for i in 3:
			var a := randf() * TAU
			game.fx.sprite(center + Vector3(0, 0.6, 0), Vector3(cos(a), 0, sin(a)) * randf_range(8.0, 16.0), 0.7, 0.1, 0.5, BEAM_COL, 0.0)
	var jit := Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15)) * minf(dying_t, 2.0)
	if dying_t < 2.4:
		# the wedges close in on the heart, shaking
		for k in 8:
			var a := TAU * k / 8.0 + spin_a
			var to := center + jit + Vector3(cos(a), 0, sin(a)) * (CoreModels.MID + dying_t * 0.25)
			shards[k].position = shards[k].position.lerp(to, 1.0 - exp(-dt * 5.0))
	else:
		# then fly apart, tumbling
		for k in 8:
			var out := shards[k].position - center
			out.y = 0.0
			shards[k].position += out.normalized() * dt * 22.0
			shard_mesh[k].rotation.y += dt * (5.0 + k)
	spin_a += dt * (0.4 + dying_t * 1.5)
	heart.position = center
	heart_mesh.scale = Vector3.ONE * (1.0 + dying_t * 0.35)
	for m in shard_mat:
		m.set_shader_parameter("light", 1.0 + dying_t * 1.2)
		m.set_shader_parameter("heat", 1.0)
	if dying_t > 3.6:
		game.big_blast(center, 1.0, CoreModels.EMERALD)
		for k in 6:
			var a := TAU * k / 6.0
			game.fx.explode(center + Vector3(cos(a) * 8.0, 0, sin(a) * 5.0), 4.0, Vector3.ZERO, CoreModels.EMERALD, Color(0.55, 1.0, 0.75))
		for i in 40:
			var a := randf() * TAU
			game.fx.sprite(center + Vector3(0, 0.6, 0), Vector3(cos(a), 0, sin(a)) * randf_range(14.0, 40.0), 0.9, 0.12, randf_range(0.6, 1.0), BEAM_COL, 0.0)
		game.sfx.play("exp_l")
		game.shake(2.2)
		game.backdrop.warp_out(0.3)
		destroyed = true
		finished = true
		visible = false
		beam_mesh.clear_surfaces()
		for q in [heart] + wards + shards:
			game.remove_enemy(q)
			q.visible = false
		game.boss_destroyed(self)
