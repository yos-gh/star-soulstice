extends BossBase
## Mid-boss of stage 4, over the approach to the enemy base: a storm
## control station held up by four ducted lift rotors on an X frame round
## the storm generator in the middle (the weak point, the gauge), with
## three lightning masts (glazed insulator stacks under steel toroids: one
## aft on the spine, one on each front boom).
## Lightning, its signature: a mast charges (a lock-on and the bolt's whole
## jagged path marked, from the mast through where the ship is on to the
## bottom edge), then the bolt strikes down that path for a moment: be off
## the line by then. The rotor nacelles shed hail in their downwash,
## columns of shells falling straight down under a pair of rotors at a time
## (break through them, or keep between). The generator fires telegraphed
## needle bursts and a squall of shells (big, then small). A quiet gap ends
## every round. Armour covers the rotors and the back of the hull; from
## below the generator is open.
## SUPERCELL (all three masts broken): the generator takes the lightning
## itself and forks it, three bolts at once (one through the ship, one
## either side of it), the hail falls from all four rotors, rings of shells
## gust out of the generator, a gap in each, and it sways harder. It leaves
## after a while; shot down, its rotors die and it goes down burning.

const INFO := {
	"name": "TEMPEST", "role": "mid",
	"desc": "嵐を操る浮遊ステーション：4 基の揚力ローターが X 字の骨組みで真ん中の嵐の発生機（弱点）を支え、3 本の避雷塔（碍子の柱）を持つ。塔が充電すると予兆（稲妻の道筋全体を表示：塔から自機のいた所を通って下端まで）のあと一瞬だけ雷が落ちる。ローターの下から雹（物理弾）の柱が 2 基ずつ真下へ降る（撃ち抜けるし、柱の間にいてもよい）。発生機から狙いの針弾と物理弾の扇。合間に静かな間。装甲はローターと船体の後ろだけで、下から発生機を撃てる。塔を全部壊すと SUPERCELL：発生機が雷を 3 本に分けて落とし（1 本は自機、2 本はその両脇）、雹は 4 基とも、隙間のある物理弾の輪を吹き出し、揺れが大きくなる。時間が来ると去る",
	"demos": [["FULL", ""], ["SUPERCELL", "B"]],
}
const CORE_HP := 640.0
const SCORE := 25000
const COIL_HP := 150.0
const COIL_SCORE := 3000
const CORE_OFF := Vector3(0, 0, 0.8)
const ROTOR_OFF := [Vector3(-9.5, 0, -3.0), Vector3(9.5, 0, -3.0), Vector3(-7.0, 0, 3.0), Vector3(7.0, 0, 3.0)]
const COIL_OFF := [Vector3(0, 0, -4.4), Vector3(-3.9, 0, 1.6), Vector3(3.9, 0, 1.6)]
const HULL_ARMOUR := [Vector3(0, 0, -2.4), 2.0]
const CHARGE_T := 1.0  # a mast's charge, marked: then the bolt
const STRIKE_T := 0.3  # the bolt
const FADE_T := 0.25  # its afterglow (harmless)
const BOLT_R := 0.55  # the bolt's deadly half width
const BOLT_COL := Color(0.86, 0.8, 1.0)
const HAIL_EVERY := 0.17
const HAIL_SPEED := 6.0
const ROUND_A := 7.6
const ROUND_B := 6.2
const LIFE := 50.0

var hull: MeshInstance3D
var core: Enemy
var coils: Array[Enemy] = []
var armour: Array[Enemy] = []
var rotors: Array[MeshInstance3D] = []
var rotor_spin := 1.0
## bolts: {node, pts, state (charge, strike, fade), t}
var bolts: Array[Dictionary] = []
var bolt_mesh: ImmediateMesh
var bolt_mi: MeshInstance3D
var center := Vector3.ZERO
var rest_z := 0.0
var phase := 0  # 0 enter, 1 A, 2 SUPERCELL, 3 leaving, 4 dying
var st := 0.0
var life_t := 0.0
var cycle_t := 0.0
var sway_t := 0.0
var fired := {}
var coil_k := 0  # the mast to strike next
var hail := [false, false, false, false]
var hail_t := 0.0
var hail_k := 0
var dying_t := 0.0
var boom_t := 0.0


func setup(g: Game) -> void:
	game = g
	rest_z = game.field_top + 9.0
	center = Vector3(0, 0, game.field_top - 10.0)
	# order matters (a shot hits the first part in the list it touches):
	# the masts, then the generator, the armour last
	for k in COIL_OFF.size():
		var c := game.spawn_part(self, "tempest_coil", 1.25)
		c.hp = COIL_HP
		c.max_hp = COIL_HP
		c.score = COIL_SCORE
		c.energy_drop = 10.0
		c.blast = 2.4
		coils.append(c)
	core = game.spawn_part(self, "tempest_core", 1.8)
	core.hp = CORE_HP
	core.max_hp = CORE_HP
	core.score = SCORE
	core.energy_drop = 30.0
	core.blast = 4.0
	for o: Vector3 in ROTOR_OFF:
		var e := game.spawn_part(self, "", 2.3)
		e.armored = true
		e.hp = 1e9
		armour.append(e)
	var hb := game.spawn_part(self, "", HULL_ARMOUR[1])
	hb.armored = true
	hb.hp = 1e9
	armour.append(hb)
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("tempest_hull")
	add_child(hull)
	for o: Vector3 in ROTOR_OFF:
		var r := MeshInstance3D.new()
		r.mesh = Vox.get_mesh("tempest_rotor")
		hull.add_child(r)
		r.position = o + Vector3(0, -0.15, 0)
		rotors.append(r)
	bolt_mesh = ImmediateMesh.new()
	bolt_mi = MeshInstance3D.new()
	bolt_mi.mesh = bolt_mesh
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/lightning.gdshader")
	mat.render_priority = 2
	bolt_mi.material_override = mat
	bolt_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bolt_mi.extra_cull_margin = 16384.0
	game.add_child(bolt_mi)
	_arm(true)
	_place(0.0)


## While it comes in nothing can be hurt.
func _arm(on: bool) -> void:
	core.armored = on
	for c in coils:
		if not c.dead:
			c.armored = on


func on_hit(_e: Enemy, dmg: float) -> float:
	return 0.0 if defeated else dmg


func on_part_killed(e: Enemy) -> void:
	if e == core:
		_defeat()
		return
	if coils.has(e):
		game.shake(0.6)
		# a mast gone mid-charge: no bolt from it
		for b in bolts.duplicate():
			if b["node"] == e and b["state"] == "charge":
				bolts.erase(b)
		if coils_alive() == 0 and phase == 1:
			_supercell()


func coils_alive() -> int:
	var c := 0
	for k in coils:
		if not k.dead:
			c += 1
	return c


func tick(dt: float) -> void:
	if finished:
		return
	st += dt
	life_t += dt
	match phase:
		0:
			center.z = move_toward(center.z, rest_z, 6.0 * dt)
			if center.z >= rest_z - 0.01 and st > 1.0:
				phase = 1
				st = 0.0
				cycle_t = 0.0
				_arm(false)
				game.boss_fight_started()
		1:
			_sway(dt, 0.45, 3.0)
			_round_a(dt)
			if life_t > LIFE:
				_leave()
		2:
			_sway(dt, 0.8, 4.5)
			_round_b(dt)
			if life_t > LIFE:
				_leave()
		3:
			center.z -= (3.0 + st * 9.0) * dt
			if center.z < game.field_top - 14.0:
				_finish()
				return
		4:
			_dying(dt)
			if finished:
				return
	_hail(dt)
	_bolts(dt)
	_place(dt)


## Sways from side to side (eased, so a change of pace never jumps).
func _sway(dt: float, w: float, amp: float) -> void:
	sway_t += dt
	center.x = move_toward(center.x, sin(sway_t * w) * amp, 4.0 * dt)


## True once when the round passes `at` seconds.
func _once(key: String, at: float) -> bool:
	if cycle_t >= at and not fired.has(key):
		fired[key] = true
		return true
	return false


## Phase A: hail under the back rotors, a bolt, a needle burst, hail under
## the front rotors, another bolt from the next mast, a squall; quiet.
func _round_a(dt: float) -> void:
	cycle_t += dt
	_hail_on([0, 1], cycle_t > 0.4 and cycle_t < 2.4)
	_hail_on([2, 3], cycle_t > 3.6 and cycle_t < 5.6)
	if _once("b1", 1.0):
		_mast_bolt()
	if _once("w_core", 2.6):
		game.warn(core, Enemy.WINDUP_SHOT + 0.15, Game.Warn.SHOT, core.radius)
	if _once("core", 2.6 + Enemy.WINDUP_SHOT + 0.15):
		_needles(5, 22.0)
	if _once("b2", 4.2):
		_mast_bolt()
	if _once("sq", 5.8):
		_squall(Bullets.BIG)
	if _once("sqs", 6.05):
		_squall(Bullets.SMALL)
	if cycle_t >= ROUND_A:
		cycle_t = 0.0
		fired.clear()


## SUPERCELL: forked bolts from the generator twice a round, hail from all
## four rotors in two bursts, rings of shells with a gap, a wide needle
## burst; a short quiet gap.
func _round_b(dt: float) -> void:
	cycle_t += dt
	var on := (cycle_t > 0.2 and cycle_t < 1.6) or (cycle_t > 2.6 and cycle_t < 4.0)
	_hail_on([0, 1, 2, 3], on)
	if _once("f1", 0.3):
		_fork()
	var cp := core.position + Vector3(0, 0, 1.4)
	for k in 2:
		if _once("ring%d" % k, 1.9 + k * 0.45) and game.can_fire(cp):
			game.bullets.ring(cp, 18, 4.6, Bullets.SHELL, self, life_t * 0.9 + k * 0.17, 3, life_t * 2.3 + k)
	if _once("w_core", 2.9):
		game.warn(core, Enemy.WINDUP_SHOT + 0.15, Game.Warn.SHOT, core.radius)
	if _once("core", 2.9 + Enemy.WINDUP_SHOT + 0.15):
		_needles(7, 34.0)
	if _once("f2", 3.8):
		_fork()
	if cycle_t >= ROUND_B:
		cycle_t = 0.0
		fired.clear()


## All three masts broken: the generator runs the storm itself.
func _supercell() -> void:
	phase = 2
	st = 0.0
	cycle_t = 0.0
	fired.clear()
	game.show_msg("TEMPEST SUPERCELL", "", 1.2, true)
	game.shake(0.8)


# ------------------------------------------------------------ lightning

## The next mast still standing charges a bolt at the ship.
func _mast_bolt() -> void:
	for n in COIL_OFF.size():
		var c := coils[(coil_k + n) % coils.size()]
		if c.dead or not game.can_fire(c.position):
			continue
		coil_k = (coils.find(c) + 1) % coils.size()
		_charge(c, game.player.position)
		game.sfx.play("slam")
		return


## SUPERCELL: three bolts from the generator, through the ship and either
## side of it.
func _fork() -> void:
	if not game.can_fire(core.position):
		return
	var d := game.player.position - core.position
	for a: float in [0.0, -0.42, 0.42]:
		_charge(core, core.position + d.rotated(Vector3.UP, a), a == 0.0)
	game.sfx.play("slam")


## A bolt from `node` charging: its jagged path from the node through
## `through` to the bottom edge is marked now and struck CHARGE_T later.
func _charge(node: Enemy, through: Vector3, sound := true) -> void:
	var from := node.position
	var to := game.line_to_bottom(from, through)
	var d := to - from
	var side := Vector3(-d.z, 0, d.x).normalized()
	var pts := PackedVector3Array([from])
	var n := 10
	for k in range(1, n):
		pts.append(from + d * (float(k) / n) + side * randf_range(-0.5, 0.5))
	pts.append(to)
	bolts.append({"node": node, "pts": pts, "state": "charge", "t": CHARGE_T})
	game.warn(node, CHARGE_T, Game.Warn.MOVE, node.radius, pts, sound)


func _bolts(dt: float) -> void:
	for b in bolts.duplicate():
		b["t"] -= dt
		var node: Enemy = b["node"]
		match b["state"]:
			"charge":
				if defeated or not is_instance_valid(node) or node.dead:
					bolts.erase(b)
					continue
				# sparks crawl over the mast as it charges
				if randf() < 0.35:
					game.fx.sprite(node.position + Vector3(randf_range(-0.6, 0.6), 0.8, randf_range(-0.6, 0.6)), Vector3.ZERO, 0.5, 0.1, 0.12, BOLT_COL, 0.0)
				if b["t"] <= 0.0:
					b["state"] = "strike"
					b["t"] = STRIKE_T
					game.sfx.play("exp_m")
					game.shake(0.35)
					game.flash_a = maxf(game.flash_a, 0.12)
					# the bot keeps off the line while it burns
					game.warn(node, STRIKE_T, Game.Warn.MOVE, node.radius, b["pts"], false)
					var pts: PackedVector3Array = b["pts"]
					for k in range(1, pts.size(), 2):
						game.fx.spark(pts[k] + Vector3(0, 0.4, 0), BOLT_COL, 2, 0.4)
			"strike":
				if game.combat_on() and _on_bolt(b["pts"], game.player.position):
					game.touch_player("lightning")
				if b["t"] <= 0.0:
					b["state"] = "fade"
					b["t"] = FADE_T
			"fade":
				if b["t"] <= 0.0:
					bolts.erase(b)
	_draw_bolts()


func _on_bolt(pts: PackedVector3Array, p: Vector3) -> bool:
	for k in pts.size() - 1:
		var c := Geometry3D.get_closest_point_to_segment(p, pts[k], pts[k + 1])
		if Vector2(p.x - c.x, p.z - c.z).length() < BOLT_R + Player.HIT_R:
			return true
	return false


## The bolts that are striking (or fading) as ribbons just over the plane.
func _draw_bolts() -> void:
	bolt_mesh.clear_surfaces()
	var any := false
	for b in bolts:
		if b["state"] != "charge":
			any = true
	if not any:
		return
	bolt_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in bolts:
		if b["state"] == "charge":
			continue
		var a := 1.0 if b["state"] == "strike" else float(b["t"]) / FADE_T
		var w := 0.75 if b["state"] == "strike" else 0.5
		var pts: PackedVector3Array = b["pts"]
		for k in pts.size() - 1:
			var p0 := pts[k] + Vector3(0, 0.36, 0)
			var p1 := pts[k + 1] + Vector3(0, 0.36, 0)
			var d := p1 - p0
			var s := Vector3(-d.z, 0, d.x).normalized() * w
			var col := Color(BOLT_COL.r, BOLT_COL.g, BOLT_COL.b, a)
			for q: Array in [[p0 - s, 0.0], [p0 + s, 1.0], [p1 + s, 1.0], [p0 - s, 0.0], [p1 + s, 1.0], [p1 - s, 0.0]]:
				bolt_mesh.surface_set_color(col)
				bolt_mesh.surface_set_uv(Vector2(0, q[1]))
				bolt_mesh.surface_add_vertex(q[0])
	bolt_mesh.surface_end()


# ------------------------------------------------------------ guns

## Hail: rotor k sheds shells while `on` (a column straight down under it).
func _hail_on(ks: Array, on: bool) -> void:
	for k: int in ks:
		hail[k] = on


func _hail(dt: float) -> void:
	hail_t -= dt
	if hail_t > 0.0 or phase == 0 or defeated:
		return
	hail_t = HAIL_EVERY
	hail_k += 1
	for k in ROTOR_OFF.size():
		if not hail[k]:
			continue
		var at: Vector3 = center + ROTOR_OFF[k] + Vector3(randf_range(-0.35, 0.35), 0, 2.0)
		if game.can_fire(at):
			game.bullets.fire(at, PI / 2.0, HAIL_SPEED, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if (hail_k + k) % 2 == 0 else Bullets.SMALL)


## A squall from the generator: a wide fan of shells toward the ship
## (`size` BIG leads, SMALL follows offset).
func _squall(size: float) -> void:
	var at := core.position + Vector3(0, 0, 1.6)
	if not game.can_fire(at):
		return
	var off := 0.0 if size == Bullets.BIG else deg_to_rad(5.0)
	game.bullets.fan(at, game.bullets.aim(at) + off, 9 if size == Bullets.BIG else 8, 80.0 if size == Bullets.BIG else 72.0, 4.8 if size == Bullets.BIG else 5.4, Bullets.SHELL, self, Bullets.ROUND, size)


## The generator's telegraphed needle burst (fired after its warning).
func _needles(count: int, spread: float) -> void:
	var at := core.position + Vector3(0, 0, 1.6)
	if game.can_fire(at):
		game.bullets.fan(at, game.bullets.aim(at), count, spread, 9.0, Bullets.ORB, self, Bullets.NEEDLE)


# ------------------------------------------------------------ placing

func _place(dt: float) -> void:
	hull.position = center
	core.position = center + CORE_OFF
	core.model.rotation.y += dt * (2.4 if phase == 2 else 0.9)
	for k in coils.size():
		if not coils[k].dead:
			coils[k].position = center + COIL_OFF[k]
	for k in ROTOR_OFF.size():
		armour[k].position = center + ROTOR_OFF[k]
		rotors[k].rotation.y += dt * 14.0 * rotor_spin * (1.0 if k % 2 == 0 else -1.0)
	armour[4].position = center + HULL_ARMOUR[0]


func _leave() -> void:
	phase = 3
	st = 0.0
	for k in 4:
		hail[k] = false


func _defeat() -> void:
	disarm()
	phase = 4
	st = 0.0
	dying_t = 0.0
	boom_t = 0.2
	for k in 4:
		hail[k] = false
	bolts.clear()
	for b in game.bullets.cancel_owner(self):
		game.items.spawn(b, Items.ENERGY, 1.0)


## Shot down: the rotors wind down one by one with a blast each, the hull
## heels over and drops, then the last blast.
func _dying(dt: float) -> void:
	dying_t += dt
	rotor_spin = maxf(0.0, rotor_spin - dt * 0.6)
	hull.rotation.z = lerpf(hull.rotation.z, 0.12, dt * 0.8)
	center.z += dt * 1.0
	boom_t -= dt
	if boom_t <= 0.0:
		boom_t = 0.3
		var k := int(dying_t / 0.3) % 4
		game.fx.explode(center + ROTOR_OFF[k] + Vector3(0, 0.4, 0), 2.2, Vector3.ZERO, Models.STEEL_M)
		game.sfx.play("exp_m")
		game.shake(0.4)
	if dying_t > 2.2:
		game.big_blast(center + CORE_OFF, 0.7, Models.STEEL_M)
		game.items.burst_energy(center, 24.0, 8.0)
		game.sfx.play("exp_l")
		game.shake(1.2)
		_finish()


func _finish() -> void:
	finished = true
	for e: Enemy in [core] + coils + armour:
		game.remove_enemy(e)
		e.queue_free()
	bolt_mi.queue_free()
	game.remove_boss(self)
	queue_free()


func gauge() -> Dictionary:
	if defeated or phase == 0 or phase == 3:
		return {}
	return {"frac": core.hp / CORE_HP, "color": Color(0.7, 0.66, 1.0), "name": INFO["name"], "name_color": Color(0.85, 0.82, 1.0), "x": 0.25, "w": 0.5, "h": 7.0, "name_y": 70.0}


func force_defeat() -> void:
	if not defeated and not finished:
		core.armored = false
		game.kill(core)


## "B": straight into SUPERCELL, the masts gone.
func viewer_skip(to: String) -> void:
	if to != "B":
		return
	center.z = rest_z
	phase = 1
	_arm(false)
	for c in coils:
		c.dead = true
		game.remove_enemy(c)
	_supercell()
	_place(0.0)


func debug_state() -> String:
	var names := ["enter", "A", "SUPERCELL", "leaving", "dying"]
	return "phase %s %.1fs  core %d/%d  masts %d  bolts %d  life %.0f" % [names[phase], st, int(maxf(core.hp, 0.0)), int(CORE_HP), coils_alive(), bolts.size(), life_t]
