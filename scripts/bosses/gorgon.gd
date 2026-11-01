extends BossBase
## Mid-boss of stage 5 (after Star Soldier's Delilah): GORGON, a fortress
## on a stepped platform in a crater of the enemy planet, bare machinery
## like the stage 1 boss: a lattice frame (a spine down the middle, a
## crossbar, girders round it), and in a square armoured housing at either
## end of the crossbar an eye: the cores, each with its own durability.
## The central gun at the foot of the spine and eight gun bunkers round
## the platform can be destroyed too. No invisible armour anywhere (shots
## pass over what they don't hit), and a gun down in its bunker lets them
## pass too.
## It lies in the ground, so it comes in with the scroll, which it brings to
## a stop over itself (Game.scroll_hold); asleep, its shutters closed over
## the eyes. Then the shutters slide back and the eyes follow the ship.
## Its signature is the gaze: an eye charges, a thin sight from it through
## the ship (leading it a little) to the edge of the screen follows the
## ship, then holds still as a band as wide as the beam and blinks, and a
## thick beam burns down it. The eyes fire them in pairs (one through the
## ship, one to the side it is heading for), and every other round they
## sweep their beams together across the screen: the sector each sweeps is
## marked first, faint, with chevrons along its far edge. The central gun
## lobs iron balls (they can't be shot and they stop shots) that burst into
## rings of shells; the eyes fire needle fans; the bunkers' guns rise in
## turn, four at a time, and fire spreads of needles (they hold fire with
## the ship close, like any ground gun); a bunker whose gun is destroyed
## raises a new one GUN_REARM later. The guns are the fight's energy: each
## drops GUN_ENERGY and its rounds in the air turn to energy too.
## Hit both eyes together (the front side shots of Form III's five, the eyes
## set wide for them, or homing lasers) and break them within TWIN_WINDOW
## of each other: a TWIN BREAK bonus, and the fortress dies at once. Break
## one alone and the other goes mad: DEATH STARE, a beam that stays on and
## follows the ship for seconds while the dead housing sprays shells and
## every gun comes up. WRATH, with both eyes alive, once as many guns as
## there are bunkers have been destroyed, or after a while: the sweeps come every round, wider,
## with bigger iron volleys, double gazes and all the guns up. It shuts its
## eyes and lets the ground move on after LIFE seconds.

const INFO := {
	"name": "GORGON", "role": "mid",
	"desc": "クレーターの段々の台の上に組まれた剥き出しの機械の要塞（スターソルジャーのデライラ風）：真ん中の背骨と横桁と周りの桁の格子、横桁の両端の四角い装甲の筐体に目が 1 つずつ（核：それぞれ別の耐久）。背骨の根元の中央砲台と、台のまわりの 8 つのトーチカの砲台も壊せる。目と中央砲台の手前には何も置かない（下からショットが届く）。地上にあるのでスクロールといっしょに来て、真上でスクロールを止める（来る間は目の上のシャッターが閉じている）。目は自機を追う。目玉の極太レーザー（大技）：細い照準が自機を少し先読みして画面の端まで追い、止まるとビームの幅の帯になって点滅し、ビームが焼く。2 つの目で 1 本は自機、1 本は自機の向かう側。1 周おきに 2 本のビームが扇形に薙ぐ（薙ぐ範囲を薄く、奥の縁に矢印）。中央砲台から鉄球弾（撃ち落とせず、ショットを遮る）がはじけて物理弾の輪に。目から針弾の扇。トーチカから砲台が 4 基ずつ交代でせり上がって針弾の 3 方向（近いと撃てない）。壊された砲台のトーチカはしばらくして新しい砲台を上げる（砲台はエネルギーを多めに落とし、撃っていた弾もエネルギーに変わる：この戦いのホーミングの補給）。2 つの目を TWIN_WINDOW 秒以内に壊すと TWIN BREAK のボーナスでそのまま撃破（第 3 形態の 5 方向の前の斜めのショット：目はそのために左右に広く離してある。またはホーミング）。片目だけ壊すと残りの目が DEATH STARE：ビームが出たまま数秒自機を追い、壊れた筐体から物理弾が渦を巻き、残った砲台が全部上がる。両目が残ったまま砲台をトーチカの数だけ壊すか時間で WRATH：毎周の薙ぎ払いが広く、鉄球が増え、2 本の照準と全砲台。時間が来ると目を閉じて地面ごと流れ去る",
	"demos": [["FULL", ""], ["WRATH", "W"], ["DEATH STARE", "L"]],
}
const EYE_HP := 620.0
const EYE_SCORE := 10000
const SCORE := 20000  # both eyes gone: the fortress falls
const TWIN_BONUS := 50000
const TWIN_WINDOW := 1.5  # seconds between the two eyes for the TWIN BREAK
const GUN_HP := 36.0
const GUN_SCORE := 2000
const GUN_ENERGY := 10.0
const GUN_REARM := 6.0  # a bunker raises a new gun this long after its gun is destroyed
const EYE_OFF := [Vector3(-8.5, 0, 0), Vector3(8.5, 0, 0)]  # wide apart: Form III's front side shots meet both
const EYE_Y := -2.2  # the eyeballs' centres
const CANNON_OFF := Vector3(0, 0, 2.6)
const CANNON_Y := -3.0
const CANNON_HP := 420.0
const CANNON_SCORE := 8000
## the gun bunkers round the platform; two groups take turns (A, B)
const SILO_OFF := [Vector3(-14.0, 0, -6.5), Vector3(14.0, 0, -6.5), Vector3(-14.3, 0, 1.0), Vector3(14.3, 0, 1.0),
	Vector3(-12.6, 0, 7.4), Vector3(12.6, 0, 7.4), Vector3(-4.6, 0, 8.0), Vector3(4.6, 0, 8.0)]
const GROUPS := [[0, 3, 4, 7], [1, 2, 5, 6]]
const GUN_DOWN := -4.8  # the gun's height down in its bunker, and up
const GUN_UP := -2.3
const RISE_T := 0.7
const SILO_SHIFT := 5.0  # each group's turn
const BURST := 2.0  # between a gun's bursts (rages: BURST_RAGE)
const BURST_RAGE := 1.3
const SEAL := 6.0
## armoured hit zones: none. It lies under the plane like the ground (shots
## pass over what they don't hit), and invisible armour there swallowed
## shots meant for the guns beyond it (yos)
const ARMOUR := []
const LID_SLIDE := 2.6  # how far the shutters part ...
const LID_SINK := 0.75  # ... and drop onto the housing
const DECEL := 4.2  # the scroll's braking as it comes in (units/s/s)
const RELEASE := 5.0  # and its pick-up as it lets the ground go
## the beams
const BEAM_HW := 1.05  # deadly half width
const BEAM_COL := Color(1.0, 0.45, 0.75)
const AIM_TRACK := 1.1  # the sight creeps after the ship ...
const AIM_LOCK := 0.55  # ... holds still ...
const AIM_FIRE := 0.9  # ... and the beam burns
const SWEEP_LOCK := 1.15  # a sweep: marked, then
const SWEEP_T := 1.5  # swept
const STARE_LOCK := 0.85
const STARE_FIRE := 3.2  # DEATH STARE: on this long, turning after the ship
const STARE_TURN := 0.35  # rad/s
const EYE_TURN := 0.6  # how fast an eye turns after the ship (rad/s): slowly
const GAZE_TURN := 0.55  # and a gaze's sight while it follows
const FADE_T := 0.3
const LEAD := 0.3
const BRACKET := 2.8
const ROUND_A := 9.6
const ROUND_W := 8.6
const ROUND_L := 8.2
const WRATH_T := 38.0
const LIFE := 64.0

var hull: MeshInstance3D
var eyes: Array[Enemy] = []
var eye_q: Array[Quaternion] = [Quaternion.IDENTITY, Quaternion.IDENTITY]
var look: Array[float] = [PI / 2.0, PI / 2.0]  # where each eye looks (plane angle, PI/2 = down)
var lids: Array = []  # per eye [upper, lower]
var lid_f := 1.0  # 1 shut, 0 open
var sockets: Array = [null, null]  # a burnt-out eye's wreck (MeshInstance3D)
var cannon: Enemy
var armour: Array[Enemy] = []
## the silos: {gun, state (down, rise, up, sink), t, burst, dead}
var silos: Array[Dictionary] = []
## beams: {eye, kind (aim, sweep, stare), state (track, lock, fire, fade),
## t, ang, a0, a1, side, warn}
var beams: Array[Dictionary] = []
var beam_mesh: ImmediateMesh
var beam_mi: MeshInstance3D
var center := Vector3.ZERO
var rest_z := 0.0
var phase := 0  # 0 coming in, 1 waking, 2 A, 3 WRATH, 4 DEATH STARE, 5 leaving, 6 dying
var st := 0.0
var fight_t := 0.0
var cycle_t := 0.0
var round_k := 0
var fired := {}
var group_t := 0.0
var guns_down := 0  # guns destroyed in all (as many as there are bunkers: WRATH)
var twin_t := 0.0  # after the first eye falls: the window for the second
var spray_t := 0.0
var spray_a := 0.0
var spraying := false
var smoke_t := 0.0
var dying_t := 0.0
var boom_t := 0.0
var gone_t := 0.0
var ship_v := Vector3.ZERO
var ship_last := Vector3.ZERO


func setup(g: Game) -> void:
	game = g
	rest_z = game.field_top + 7.0
	center = Vector3(0, 0, game.field_top - 22.0)
	ship_last = game.player.position
	# order matters (a shot hits the first part in the list it touches): the
	# eyes, the guns, the central gun, the armour last
	for k in 2:
		var e := game.spawn_part(self, "gorgon_eye", 1.75)
		e.hp = EYE_HP
		e.max_hp = EYE_HP
		e.score = EYE_SCORE
		e.energy_drop = 20.0
		e.blast = 3.4
		e.ground = true
		e.ram = false
		eyes.append(e)
		var pair := []
		for s in 2:
			var m := MeshInstance3D.new()
			m.mesh = Vox.get_mesh("gorgon_lid")
			m.rotation.y = 0.0 if s == 0 else PI
			add_child(m)
			pair.append(m)
		lids.append(pair)
	for o: Vector3 in SILO_OFF:
		silos.append({"gun": _new_gun(), "state": "down", "t": 0.0, "burst": 0.0, "dead": false, "y": GUN_DOWN, "rearm": 0.0})
	cannon = game.spawn_part(self, "gorgon_cannon", 1.6)
	cannon.hp = CANNON_HP
	cannon.max_hp = CANNON_HP
	cannon.score = CANNON_SCORE
	cannon.energy_drop = 14.0
	cannon.blast = 2.8
	cannon.ground = true
	cannon.ram = false
	for a: Array in ARMOUR:
		var e := game.spawn_part(self, "", a[1])
		e.armored = true
		e.hp = 1e9
		e.ground = true
		e.ram = false
		armour.append(e)
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("gorgon_hull")
	add_child(hull)
	beam_mesh = ImmediateMesh.new()
	beam_mi = MeshInstance3D.new()
	beam_mi.mesh = beam_mesh
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/lightning.gdshader")
	mat.render_priority = 2
	beam_mi.material_override = mat
	beam_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam_mi.extra_cull_margin = 16384.0
	game.add_child(beam_mi)
	_arm(true)
	_place(0.0)


## A bunker's gun, down in it (shots pass over it until it is up).
func _new_gun() -> Enemy:
	var gun := game.spawn_part(self, "gorgon_gun", 1.0)
	gun.hp = GUN_HP
	gun.max_hp = GUN_HP
	gun.score = GUN_SCORE
	gun.energy_drop = GUN_ENERGY
	gun.blast = 1.6
	gun.ground = true
	gun.ram = false
	gun.intangible = true
	return gun


func _exit_tree() -> void:
	# (also when the field is cleared under it)
	if is_instance_valid(beam_mi):
		beam_mi.queue_free()


## Asleep (coming in, leaving) nothing can be hurt.
func _arm(on: bool) -> void:
	for e in eyes:
		if not e.dead:
			e.armored = on


## Out of health: like BossBase.disarm, but the wreck is not sunk under the
## explosions (Vox.sink_node): it lies deep in the ground already, under
## them, and sinking a thing that deep scrambled the picture.
func disarm() -> void:
	defeated = true
	for e: Enemy in game.enemies:
		if e.controller == self:
			e.intangible = true
			e.ram = false
			e.sunk = true


func on_hit(_e: Enemy, dmg: float) -> float:
	return 0.0 if defeated else dmg


func on_part_killed(e: Enemy) -> void:
	var k := eyes.find(e)
	if k >= 0:
		_eye_down(k)
		return
	if e == cannon:
		# its iron stops; it smoulders
		game.shake(0.7)
		return
	for s in silos:
		if s["gun"] == e:
			s["dead"] = true
			s["rearm"] = GUN_REARM
			guns_down += 1
			game.shake(0.4)
			game.fx.puff(e.global_position + Vector3(0, 0.6, 0), Vector3(0, 1.5, 0), 1.6, 1.4, 0.5, Fx.SMOKE)
			# its rounds still in the air turn to energy (the homing lasers'
			# supply in this fight, with the guns' own drop)
			for b in game.bullets.cancel_owner(e):
				game.items.spawn(b, Items.ENERGY, 1.0)
			if guns_down >= SILO_OFF.size() and phase == 2:
				_wrath()
			return


func eyes_alive() -> int:
	return int(not eyes[0].dead) + int(not eyes[1].dead)


func silos_alive() -> int:
	var c := 0
	for s in silos:
		if not s["dead"]:
			c += 1
	return c


func _stage_scroll() -> float:
	return game.area_scroll()


## Holds the ground at speed v (it is part of it).
func _hold(v: float) -> void:
	game.scroll_hold = v
	game.scroll_speed = v


## Lets the ground go: the scroll picks up to the stage's speed.
func _release(dt: float) -> void:
	if game.scroll_hold < 0.0:
		return
	var to := _stage_scroll()
	var v := move_toward(game.scroll_hold, to, RELEASE * dt)
	game.scroll_speed = v
	game.scroll_hold = -1.0 if v >= to else v


func tick(dt: float) -> void:
	if finished:
		return
	st += dt
	if dt > 0.0:
		var p := game.player.position
		ship_v = ship_v.lerp((p - ship_last) / dt, clampf(dt * 8.0, 0.0, 1.0))
		ship_last = p
	match phase:
		0:
			# with the ground, braking it to a stop with itself on the mark
			center.z += game.scroll_speed * dt
			var d := rest_z - center.z
			if d <= 0.02:
				center.z = rest_z
				_hold(0.0)
				phase = 1
				st = 0.0
				game.sfx.play("slam")
				game.shake(0.5)
			else:
				_hold(minf(_stage_scroll(), sqrt(2.0 * DECEL * d)))
		1:
			lid_f = move_toward(lid_f, 0.0, dt / 0.9)
			if st > 1.1:
				phase = 2
				st = 0.0
				cycle_t = 0.0
				_arm(false)
				game.boss_fight_started()
		2:
			_round_a(dt)
			if fight_t > WRATH_T and eyes_alive() == 2:
				_wrath()
		3:
			_round_wrath(dt)
		4:
			_round_stare(dt)
		5:
			_leaving(dt)
		6:
			_dying(dt)
	if phase >= 2 and phase <= 4:
		fight_t += dt
		if twin_t > 0.0:
			twin_t -= dt
			if twin_t <= 0.0 and eyes_alive() == 1:
				_stare()
		if fight_t > LIFE:
			_leave()
	if phase >= 1 and phase <= 5:
		_silos(dt)
	_spray(dt)
	_beams(dt)
	_place(dt)


## True once when the round passes `at` seconds.
func _once(key: String, at: float) -> bool:
	if cycle_t >= at and not fired.has(key):
		fired[key] = true
		return true
	return false


func _next_round(len: float) -> void:
	if cycle_t >= len:
		cycle_t = 0.0
		fired.clear()
		round_k += 1


## Phase A: a pair of gazes, the central gun's iron, the eyes' needle fans, then
## (every other round) a sweep of both beams inward from the sides, or two
## gazes one after the other; the central gun again.
func _round_a(dt: float) -> void:
	cycle_t += dt
	if _once("gaze", 0.3):
		_gaze_pair()
	if _once("maw", 2.8):
		_maw(3, 26.0)
	if _once("fan0", 3.7):
		_eye_fan(0, 5, 34.0)
	if _once("fan1", 4.1):
		_eye_fan(1, 5, 34.0)
	if round_k % 2 == 1:
		if _once("cross", 5.2):
			_cross(false)
	else:
		if _once("g0", 5.0):
			_gaze(0, 0.0)
		if _once("g1", 5.7):
			_gaze(1, 0.0)
	if _once("maw2", 8.0):
		_maw(3, 40.0)
	_next_round(ROUND_A)


## WRATH: a scissor sweep (the beams cross, then open out to the sides),
## a bigger iron volley, both eyes gazing with fans, the inward sweep, the
## central gun again; all the guns up.
func _round_wrath(dt: float) -> void:
	cycle_t += dt
	if _once("open", 0.3):
		_cross(true)
	if _once("maw", 2.6):
		_maw(5, 60.0)
	if _once("gaze", 3.3):
		_gaze_pair()
	if _once("fans", 4.4):
		_eye_fan(0, 7, 50.0)
		_eye_fan(1, 7, 50.0)
	if _once("close", 5.5):
		_cross(false)
	if _once("maw2", 7.6):
		_maw(4, 48.0)
	_next_round(ROUND_W)


## DEATH STARE (one eye left): its beam stays on and follows the ship while
## the dead housing sprays shells; the central gun's iron, a wide needle fan, a
## quick gaze.
func _round_stare(dt: float) -> void:
	cycle_t += dt
	var k := 0 if not eyes[0].dead else 1
	if _once("stare", 0.3):
		_stare_beam(k)
	spraying = cycle_t > 1.0 and cycle_t < 4.6
	if _once("maw", 4.6):
		_maw(4, 44.0)
	if _once("fan", 5.3):
		_eye_fan(k, 9, 70.0)
	if _once("gaze", 6.2):
		_gaze(k, 0.0)
	_next_round(ROUND_L)


func _wrath() -> void:
	phase = 3
	cycle_t = 0.0
	fired.clear()
	game.show_msg("GORGON WRATH", "", 1.2, true)
	game.shake(0.8)
	game.sfx.play("slam")


func _stare() -> void:
	phase = 4
	cycle_t = 0.0
	fired.clear()
	game.show_msg("GORGON DEATH STARE", "", 1.2, true)
	game.shake(0.8)
	game.sfx.play("slam")


## An eye is destroyed: its beams go out, its socket burns. The other one
## gone too within the window: the TWIN BREAK.
func _eye_down(k: int) -> void:
	for b in beams.duplicate():
		if b["eye"] == eyes[k]:
			if b["state"] == "fire":
				b["state"] = "fade"
				b["t"] = FADE_T
			elif b["state"] != "fade":
				beams.erase(b)
	var s := MeshInstance3D.new()
	s.mesh = Vox.get_mesh("gorgon_socket")
	add_child(s)
	sockets[k] = s
	game.shake(1.0)
	if eyes[1 - k].dead:
		if twin_t > 0.0:
			_twin_break()
		_defeat()
	else:
		twin_t = TWIN_WINDOW


func _twin_break() -> void:
	game.add_score(TWIN_BONUS, true)
	var at := game.to_plane(center + Vector3(0, -1.0, 1.0))
	game.fx.popup(at + Vector3(0, 0, -1.6), "TWIN BREAK  %d" % TWIN_BONUS, Color(1.0, 0.6, 0.85), true)
	game.show_msg("TWIN BREAK", "", 1.6)
	game.sfx.play("clear")


# ------------------------------------------------------------ the gaze

## -1 or 1: the way the ship is moving across (toward the middle if still).
func _heading_side() -> float:
	if absf(ship_v.x) > 1.0:
		return signf(ship_v.x)
	return -signf(game.player.position.x) if absf(game.player.position.x) > 0.5 else 1.0


## Both eyes (whichever are left): one through the ship, one to the side it
## heads for.
func _gaze_pair() -> void:
	var side := _heading_side() * BRACKET
	var first := true
	for k in 2:
		if not eyes[k].dead:
			_gaze(k, 0.0 if first else side, first)
			first = false


## Eye k's gaze: the sight follows the ship (`side`: that far to its side).
func _gaze(k: int, side: float, sound := true) -> void:
	var e := eyes[k]
	if e.dead or not game.can_fire(e.hit_pos):
		return
	var b := {"eye": e, "kind": "aim", "state": "track", "t": AIM_TRACK, "side": side}
	b["ang"] = look[k]
	game.warn(e, AIM_TRACK + AIM_LOCK, Game.Warn.MOVE, e.radius, {"laser": _beam_pts(e.hit_pos, b["ang"])}, sound)
	b["warn"] = game.warnings[game.warnings.size() - 1]
	beams.append(b)
	if sound:
		game.sfx.play("slam")


## Both eyes sweep their beams: `open` = from crossed in the middle out to
## the sides (WRATH), else from the sides inward, short of the middle.
## Each sweep's sector is marked first.
func _cross(open: bool) -> void:
	var first := true
	for k in 2:
		var e := eyes[k]
		if e.dead or not game.can_fire(e.hit_pos):
			continue
		var s := -1.0 if k == 0 else 1.0
		var x0 := s * (-3.0 if open else 14.0)
		var x1 := s * (11.0 if open else 3.5)
		var a0 := _ang_to_bottom(e.hit_pos, x0)
		var a1 := _ang_to_bottom(e.hit_pos, x1)
		var b := {"eye": e, "kind": "sweep", "state": "lock", "t": SWEEP_LOCK, "ang": a0, "a0": a0, "a1": a1, "side": 0.0}
		game.warn(e, SWEEP_LOCK, Game.Warn.MOVE, e.radius, {"sector": [e.hit_pos, a0, a1], "hw": BEAM_HW}, first)
		b["warn"] = game.warnings[game.warnings.size() - 1]
		beams.append(b)
		first = false
	if not first:
		game.sfx.play("slam")


## DEATH STARE: locked on the ship, then on for STARE_FIRE, turning after it.
func _stare_beam(k: int) -> void:
	var e := eyes[k]
	if e.dead or not game.can_fire(e.hit_pos):
		return
	var b := {"eye": e, "kind": "stare", "state": "lock", "t": STARE_LOCK, "side": 0.0}
	b["ang"] = look[k]
	game.warn(e, STARE_LOCK, Game.Warn.MOVE, e.radius, {"laser": _beam_pts(e.hit_pos, b["ang"])})
	b["warn"] = game.warnings[game.warnings.size() - 1]
	beams.append(b)
	game.sfx.play("slam")


## Heading from `o` through the ship (led a little, shifted `side`), kept
## pointing down the screen.
func _aim_ang(e: Enemy, side: float) -> float:
	var lead := ship_v * LEAD
	if lead.length() > 3.0:
		lead = lead.normalized() * 3.0
	var t := game.player.position + lead + Vector3(side, 0, 0)
	var d := t - e.hit_pos
	return atan2(d.z, d.x)


func _ang_to_bottom(o: Vector3, x: float) -> float:
	return atan2(game.field_bottom + 1.0 - o.z, x - o.x)


## A beam from `o` heading `ang`: to past the bottom edge.
func _beam_end(o: Vector3, ang: float) -> Vector3:
	var d := Vector3(cos(ang), 0, sin(ang))
	var reach := 80.0
	if d.z > 0.01:
		reach = (game.field_bottom + 2.0 - o.z) / d.z
	elif d.z < -0.01:
		reach = (game.field_top - 2.0 - o.z) / d.z
	if absf(d.x) > 0.01:
		reach = minf(reach, (signf(d.x) * (game.hw_top + 3.0) - o.x) / d.x)
	# (a giant rock in the way stops it)
	return game.solid_cut(o, o + d * reach)


func _beam_pts(o: Vector3, ang: float) -> PackedVector3Array:
	return PackedVector3Array([o, _beam_end(o, ang)])


func _on_beam(o: Vector3, ang: float, p: Vector3) -> bool:
	var d := Vector3(cos(ang), 0, sin(ang))
	var r := Vector3(p.x - o.x, 0, p.z - o.z)
	var along := r.dot(d)
	if along < 0.0 or along > o.distance_to(_beam_end(o, ang)):
		return false
	return (r - d * along).length() < BEAM_HW + Player.HIT_R


func _beams(dt: float) -> void:
	for b in beams.duplicate():
		b["t"] -= dt
		var e: Enemy = b["eye"]
		var o := e.hit_pos
		match b["state"]:
			"track":
				if defeated or e.dead:
					beams.erase(b)
					continue
				# (it creeps after the ship, as fast as the eye can turn)
				b["ang"] = rotate_toward(float(b["ang"]), _aim_ang(e, float(b["side"])), GAZE_TURN * dt)
				(b["warn"]["to"] as Dictionary)["laser"] = _beam_pts(o, b["ang"])
				_charge_fx(e)
				if b["t"] <= 0.0:
					b["state"] = "lock"
					b["t"] = AIM_LOCK
			"lock":
				if defeated or e.dead:
					beams.erase(b)
					continue
				_charge_fx(e)
				if b["t"] <= 0.0:
					b["state"] = "fire"
					var dur: float = {"aim": AIM_FIRE, "sweep": SWEEP_T, "stare": STARE_FIRE}[b["kind"]]
					b["t"] = dur
					b["dur"] = dur
					game.sfx.play("exp_m")
					game.shake(0.3)
					game.flash_a = maxf(game.flash_a, 0.1)
					# the autopilot keeps off it while it burns (no sound)
					var to: Dictionary = {"sector": [o, b["ang"], b["a1"]], "hw": BEAM_HW} if b["kind"] == "sweep" else {"laser": _beam_pts(o, b["ang"])}
					game.warn(e, dur, Game.Warn.MOVE, e.radius, to, false)
					b["warn"] = game.warnings[game.warnings.size() - 1]
			"fire":
				if defeated:
					b["state"] = "fade"
					b["t"] = FADE_T
					continue
				match b["kind"]:
					"sweep":
						var f: float = 1.0 - float(b["t"]) / float(b["dur"])
						b["ang"] = lerp_angle(b["a0"], b["a1"], smoothstep(0.0, 1.0, f))
						(b["warn"]["to"] as Dictionary)["sector"] = [o, b["ang"], b["a1"]]
					"stare":
						var want := _aim_ang(e, 0.0)
						b["ang"] = rotate_toward(float(b["ang"]), want, STARE_TURN * dt)
						(b["warn"]["to"] as Dictionary)["laser"] = _beam_pts(o, b["ang"])
				if game.combat_on() and _on_beam(o, b["ang"], game.player.position):
					game.touch_player("gorgon gaze")
				if randf() < 0.5:
					var q := o.lerp(_beam_end(o, b["ang"]), randf())
					game.fx.spark(q + Vector3(0, 0.4, 0), BEAM_COL, 1, 0.35)
				if b["t"] <= 0.0:
					b["state"] = "fade"
					b["t"] = FADE_T
			"fade":
				if b["t"] <= 0.0:
					beams.erase(b)
	_draw_beams()


## Sparks drawn into a charging eye.
func _charge_fx(e: Enemy) -> void:
	if randf() < 0.4:
		var off := Vector3(randf_range(-1.6, 1.6), 0.6, randf_range(-1.6, 1.6))
		game.fx.sprite(e.hit_pos + off, -off * 2.0, 0.45, 0.12, 0.15, BEAM_COL, 0.0)


## The beams just over the plane: a thin flickering sight while one follows
## the ship, a faint band as wide as the beam with a bright line in it once
## it holds still (blinking just before), the beam itself (a white core in
## a pink glow, flickering) and its fading. A sweep is marked by its sector
## (faint), its first line (the band) and its last (dim), with chevrons
## streaming along the far edge the way it will go.
func _draw_beams() -> void:
	beam_mesh.clear_surfaces()
	if beams.is_empty():
		return
	beam_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in beams:
		var e: Enemy = b["eye"]
		var o := e.hit_pos
		var t: float = b["t"]
		match b["state"]:
			"track":
				_line(o, b["ang"], 0.07, 0.42 + 0.18 * sin(game.time * 70.0 + float(b["side"])))
			"lock":
				var blink := t > 0.15 or int(t * 40.0) % 2 == 0
				if b["kind"] == "sweep":
					_fan(o, b["a0"], b["a1"], 0.4)
					_line(o, b["a1"], 0.06, 0.45)
					_chevrons(o, b["a0"], b["a1"])
				_line(o, b["ang"], BEAM_HW, 0.16)
				if blink:
					_line(o, b["ang"], 0.13, 1.0)
			"fire":
				var w := BEAM_HW * (1.0 + 0.07 * sin(game.time * 55.0))
				if b["kind"] == "sweep":
					_fan(o, b["ang"], b["a1"], 0.22)
				_line(o, b["ang"], w * 1.6, 0.4)
				_line(o, b["ang"], w, 1.0)
			"fade":
				var f := clampf(t / FADE_T, 0.0, 1.0)
				_line(o, b["ang"], BEAM_HW * (0.4 + 0.6 * f), f)
	beam_mesh.surface_end()


## One ribbon from o heading `ang` to past the bottom, `w` either side.
func _line(o: Vector3, ang: float, w: float, a: float) -> void:
	_seg(o, _beam_end(o, ang), w, a)


func _seg(p0: Vector3, p1: Vector3, w: float, a: float) -> void:
	var col := Color(BEAM_COL.r, BEAM_COL.g, BEAM_COL.b, a)
	var q0 := p0 + Vector3(0, 0.36, 0)
	var q1 := p1 + Vector3(0, 0.36, 0)
	var d := q1 - q0
	var s := Vector3(-d.z, 0, d.x).normalized() * w
	for q: Array in [[q0 - s, 0.0], [q0 + s, 1.0], [q1 + s, 1.0], [q0 - s, 0.0], [q1 + s, 1.0], [q1 - s, 0.0]]:
		beam_mesh.surface_set_color(col)
		beam_mesh.surface_set_uv(Vector2(0, q[1]))
		beam_mesh.surface_add_vertex(q[0])


## The sector between two headings, faint (its glow only: UV.y off the
## middle of the ribbon profile).
func _fan(o: Vector3, a0: float, a1: float, a: float) -> void:
	var col := Color(BEAM_COL.r, BEAM_COL.g, BEAM_COL.b, a)
	var n := 10
	var q0 := o + Vector3(0, 0.36, 0)
	for k in n:
		var p1 := _beam_end(o, lerp_angle(a0, a1, float(k) / n)) + Vector3(0, 0.36, 0)
		var p2 := _beam_end(o, lerp_angle(a0, a1, float(k + 1) / n)) + Vector3(0, 0.36, 0)
		for q: Vector3 in [q0, p1, p2]:
			beam_mesh.surface_set_color(col)
			beam_mesh.surface_set_uv(Vector2(0, 0.14))
			beam_mesh.surface_add_vertex(q)


## Chevrons streaming along a sweep's far edge, from a0 toward a1.
func _chevrons(o: Vector3, a0: float, a1: float) -> void:
	var span := wrapf(a1 - a0, -PI, PI)
	var reach := (game.field_bottom - 1.5 - o.z)
	var steps := 5
	var ph := fmod(game.time * 1.6, 1.0)
	for k in steps:
		var f := (k + ph) / steps
		var ang := a0 + span * f
		var dir := Vector3(cos(ang), 0, sin(ang))
		var tip := o + dir * (reach / maxf(dir.z, 0.3))
		var along := Vector3(-dir.z, 0, dir.x) * signf(span)  # the way it sweeps
		var a := 0.9 * sin(f * PI)
		_seg(tip - along * 0.9 + dir * 0.9, tip, 0.11, a)
		_seg(tip - along * 0.9 - dir * 0.9, tip, 0.11, a)


# ------------------------------------------------------------ guns

## The central gun lobs `n` iron balls over `spread` degrees at the ship
## (they burst into rings of shells; they no longer weave: yos found weaving
## iron balls more stress than fun). Not once
## it is destroyed.
func _maw(n: int, spread: float) -> void:
	if cannon.dead or not game.can_fire(cannon.hit_pos):
		return
	game.warn_then(cannon, 0.7, Game.Warn.SHOT, func() -> void:
		var muzzle := cannon.global_position + Vector3(0, 0.7, 0) - cannon.model.global_basis.z * 1.6
		var from := game.to_plane(muzzle)
		var aim := game.bullets.aim(from)
		for i in n:
			var a := aim + deg_to_rad(spread) * ((float(i) / maxf(n - 1, 1)) - 0.5) if n > 1 else aim
			game.bullets.launch(muzzle, a, 5.2, Bullets.IRON, self)
			game.bullets.split(1.15 + 0.08 * absf(i - (n - 1) * 0.5), 12)
		game.fx.flash(muzzle, 0.6)
		game.shake(0.3)
		game.sfx.play("exp_s"))


## Eye k's needle fan at the ship (announced).
func _eye_fan(k: int, count: int, spread: float) -> void:
	var e := eyes[k]
	if e.dead or not game.can_fire(e.hit_pos):
		return
	game.warn_then(e, Enemy.WINDUP_SHOT + 0.1, Game.Warn.SHOT, func() -> void:
		var muzzle := e.global_position + Vector3(0, 1.6, 0)
		var from := game.to_plane(muzzle)
		var aim := game.bullets.aim(from)
		for i in count:
			game.bullets.launch(muzzle, aim + deg_to_rad(spread) * (float(i) / maxf(count - 1, 1) - 0.5), 8.5, Bullets.ORB, self, Bullets.NEEDLE))


## The silos: in phase A the two groups take turns, in a rage every gun is
## up; up, a gun fires spreads of three needles at the ship (each burst
## announced), unless the ship is close.
func _silos(dt: float) -> void:
	group_t += dt
	var turn := int(group_t / SILO_SHIFT) % 2
	for k in silos.size():
		var s := silos[k]
		if s["dead"]:
			# a new gun comes up from the bunker after a while
			if phase >= 2 and phase <= 4:
				s["rearm"] -= dt
				if s["rearm"] <= 0.0:
					var old: Enemy = s["gun"]
					old.queue_free()
					s["gun"] = _new_gun()
					s["dead"] = false
					s["state"] = "down"
					s["y"] = GUN_DOWN
					s["t"] = 0.0
			continue
		var gun: Enemy = s["gun"]
		var want := false
		match phase:
			2:
				want = GROUPS[turn].has(k)
			3, 4:
				want = true
		s["t"] += dt
		match s["state"]:
			"down":
				if want:
					s["state"] = "rise"
					s["t"] = 0.0
			"rise":
				s["y"] = lerpf(GUN_DOWN, GUN_UP, smoothstep(0.0, 1.0, s["t"] / RISE_T))
				if s["t"] >= RISE_T:
					s["state"] = "up"
					gun.intangible = false
					s["burst"] = 0.35 + k * 0.09
			"up":
				s["burst"] -= dt
				if not want:
					s["state"] = "sink"
					s["t"] = 0.0
					gun.intangible = true
				elif s["burst"] <= 0.0:
					var d := game.player.position - gun.hit_pos
					if not game.can_fire(gun.hit_pos) or d.length() < SEAL:
						s["burst"] = 0.6
					else:
						s["burst"] = (BURST if phase == 2 else BURST_RAGE) + Enemy.WINDUP_SHOT
						game.warn_then(gun, Enemy.WINDUP_SHOT, Game.Warn.SHOT, func() -> void:
							var muzzle := gun.global_position + Vector3(0, 0.7, 0)
							var a := game.bullets.aim(game.to_plane(muzzle))
							for i in 3:
								game.bullets.launch(muzzle, a + deg_to_rad(16.0) * (i - 1), 7.5, Bullets.ORB, gun, Bullets.NEEDLE)
							game.fx.flash(muzzle, 0.3))
			"sink":
				s["y"] = lerpf(GUN_UP, GUN_DOWN, smoothstep(0.0, 1.0, s["t"] / RISE_T))
				if s["t"] >= RISE_T:
					s["state"] = "down"


## DEATH STARE: the dead socket sprays shells, a two-armed whirl.
func _spray(dt: float) -> void:
	if not spraying or phase != 4 or defeated:
		return
	spray_t -= dt
	spray_a += dt * 2.2
	if spray_t > 0.0:
		return
	spray_t = 0.09
	var k := 0 if eyes[0].dead else 1
	var at := game.to_plane(center + EYE_OFF[k] + Vector3(0, EYE_Y + 1.2, 0))
	if not game.can_fire(at):
		return
	for arm in 2:
		game.bullets.fire(at, spray_a + PI * arm, 5.0, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if arm == 0 else Bullets.SMALL)


# ------------------------------------------------------------ placing

func _place(dt: float) -> void:
	hull.position = center
	for k in 2:
		var e := eyes[k]
		var p: Vector3 = center + EYE_OFF[k] + Vector3(0, EYE_Y, 0)
		e.position = p
		if not e.dead:
			# the eye turns slowly after the ship, or looks down its beam
			var beamed := false
			for b in beams:
				if b["eye"] == e and b["state"] != "fade":
					look[k] = float(b["ang"])
					beamed = true
			if not beamed:
				var d := game.player.position - e.hit_pos
				look[k] = rotate_toward(look[k], atan2(d.z, d.x), EYE_TURN * dt)
			# the iris (+y) tilted toward where it looks
			var want := Quaternion.IDENTITY
			if lid_f < 0.99:
				var dir := Vector3(cos(look[k]), 0, sin(look[k]))
				want = Quaternion(Vector3.UP.cross(dir).normalized(), 0.55)
			eye_q[k] = eye_q[k].slerp(want, clampf(dt * 6.0, 0.0, 1.0))
			e.model.quaternion = eye_q[k]
		# the lids part along the eye and sink away (shut: they meet over it)
		var open := 1.0 - lid_f
		(lids[k][0] as MeshInstance3D).position = p + Vector3(0, -open * LID_SINK, -open * LID_SLIDE)
		(lids[k][1] as MeshInstance3D).position = p + Vector3(0, -open * LID_SINK, open * LID_SLIDE)
		if sockets[k] != null:
			(sockets[k] as MeshInstance3D).position = p
	cannon.position = center + CANNON_OFF + Vector3(0, CANNON_Y, 0)
	if not cannon.dead:
		var dc := game.player.position - cannon.hit_pos
		cannon.model.rotation.y = lerp_angle(cannon.model.rotation.y, atan2(-dc.x, -dc.z), clampf(3.0 * dt, 0.0, 1.0))
	for k in armour.size():
		armour[k].position = center + (ARMOUR[k][0] as Vector3) + Vector3(0, -2.0, 0)
	for k in silos.size():
		var s := silos[k]
		var gun: Enemy = s["gun"]
		gun.position = center + SILO_OFF[k] + Vector3(0, float(s["y"]), 0)
		if not s["dead"]:
			var d := game.player.position - gun.hit_pos
			gun.model.rotation.y = lerp_angle(gun.model.rotation.y, atan2(-d.x, -d.z), clampf(6.0 * dt, 0.0, 1.0))
	# the dead sockets smoulder
	smoke_t -= dt
	if smoke_t <= 0.0 and phase != 0:
		smoke_t = 0.12
		for k in 2:
			if sockets[k] != null and not defeated:
				var at: Vector3 = center + EYE_OFF[k] + Vector3(randf_range(-0.6, 0.6), EYE_Y + 1.0, randf_range(-0.6, 0.6))
				game.fx.puff(at, Vector3(0, 2.0, 0), 0.9, 1.1, 0.4, Fx.SMOKE)
		if cannon.dead and not defeated:
			game.fx.puff(cannon.global_position + Vector3(randf_range(-0.8, 0.8), 1.0, randf_range(-0.8, 0.8)), Vector3(0, 2.0, 0), 0.9, 1.1, 0.4, Fx.SMOKE)


# ------------------------------------------------------------ the end

## Time up: the lids close, the guns go down, the ground moves on with it.
func _leave() -> void:
	phase = 5
	st = 0.0
	spraying = false
	_arm(true)
	for b in beams.duplicate():
		if b["state"] != "fire" and b["state"] != "fade":
			beams.erase(b)


func _leaving(dt: float) -> void:
	lid_f = move_toward(lid_f, 1.0, dt / 0.8)
	if st > 1.0:
		_release(dt)
	center.z += game.scroll_speed * dt
	if center.z - 10.0 > game.field_bottom:
		_finish()


func _defeat() -> void:
	disarm()
	phase = 6
	st = 0.0
	dying_t = 0.0
	boom_t = 0.1
	spraying = false
	for b in beams:
		if b["state"] != "fade":
			b["state"] = "fade"
			b["t"] = FADE_T
	for b in game.bullets.cancel_owner(self):
		game.items.spawn(b, Items.ENERGY, 1.0)
	for s in silos:
		for b in game.bullets.cancel_owner(s["gun"]):
			game.items.spawn(b, Items.ENERGY, 1.0)


## Destroyed: blasts all over the face and round the rim, the last blast,
## then the ground moves on with the wreck.
func _dying(dt: float) -> void:
	dying_t += dt
	if dying_t < 2.6:
		boom_t -= dt
		if boom_t <= 0.0:
			boom_t = 0.22
			var k := int(dying_t / 0.22)
			var at: Vector3
			if k % 3 == 2:
				at = center + SILO_OFF[k % SILO_OFF.size()]
			else:
				at = center + Vector3(randf_range(-11.0, 11.0), 0, randf_range(-6.0, 5.0))
			game.fx.explode(game.to_plane(at + Vector3(0, -2.0, 0)) + Vector3(0, 0.4, 0), 2.4, Vector3.ZERO, Color(0.46, 0.14, 0.15))
			game.sfx.play("exp_m")
			game.shake(0.4)
		return
	if not fired.has("finale"):
		fired["finale"] = true
		var at := game.to_plane(center + Vector3(0, -2.0, 0))
		game.big_blast(at, 0.75, Color(0.46, 0.14, 0.15))
		game.add_score(SCORE, true)
		game.fx.popup(at + Vector3(0, 0, 1.4), str(SCORE), Color(1, 0.9, 0.5), true)
		game.items.burst_energy(at, 30.0, 9.0)
		game.sfx.play("exp_l")
		game.shake(1.3)
	if dying_t > 3.4:
		_release(dt)
	center.z += game.scroll_speed * dt
	if center.z - 10.0 > game.field_bottom or dying_t > 12.0:
		_finish()


func _finish() -> void:
	finished = true
	if game.scroll_hold >= 0.0:
		game.scroll_hold = -1.0
	var parts: Array[Enemy] = []
	parts.append_array(eyes)
	parts.append(cannon)
	parts.append_array(armour)
	for s in silos:
		parts.append(s["gun"])
	for e in parts:
		game.remove_enemy(e)
		e.queue_free()
	game.remove_boss(self)
	queue_free()


func gauge() -> Dictionary:
	if defeated or phase <= 1 or phase == 5:
		return {}
	var f := [maxf(eyes[0].hp, 0.0) / EYE_HP, maxf(eyes[1].hp, 0.0) / EYE_HP]
	return {"frac": (f[0] + f[1]) * 0.5, "fracs": f, "color": Color(1.0, 0.5, 0.75), "name": INFO["name"], "name_color": Color(1.0, 0.75, 0.88), "x": 0.25, "w": 0.5, "h": 7.0, "name_y": 70.0}


func force_defeat() -> void:
	if defeated or finished:
		return
	# both together: the twin break
	for e in eyes:
		e.armored = false
		game.kill(e)


## Viewer: "W" into WRATH, "L" one eye gone (DEATH STARE).
func viewer_skip(to: String) -> void:
	if to == "":
		return
	center.z = rest_z
	_hold(0.0)
	phase = 2
	lid_f = 0.0
	_arm(false)
	if to == "W":
		for s in silos:
			s["dead"] = true
			s["rearm"] = GUN_REARM
			(s["gun"] as Enemy).dead = true
			game.remove_enemy(s["gun"])
		guns_down = SILO_OFF.size()
		_wrath()
	elif to == "L":
		var e := eyes[0]
		e.hp = 0.0
		e.dead = true
		game.remove_enemy(e)
		_eye_down(0)
		twin_t = 0.0
		_stare()
	_place(0.0)


func debug_state() -> String:
	var names := ["coming in", "waking", "A", "WRATH", "DEATH STARE", "leaving", "dying"]
	return "phase %s %.1fs  eyes %d/%d  silos %d  beams %d  fight %.0f" % [names[phase], st, int(maxf(eyes[0].hp, 0.0)), int(maxf(eyes[1].hp, 0.0)), silos_alive(), beams.size(), fight_t]
