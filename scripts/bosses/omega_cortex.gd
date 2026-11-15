extends BossBase
## Stage 5's first boss OMEGA CORTEX: STAR CORTEX (stage 1) finished and
## armed. The same octagonal core round the great eye (its shutters, its
## four pods), now built out: truss girders carry a gun deck either side with
## a rail cannon on a ring mount (fed by glowing capacitor banks), and two
## mine batteries stand on a frame at its back. Bare machinery in the
## Cortex's greys, cyan lamps. No invisible armour: a shot that misses every
## part flies on past the hull (the old flank armour hid the rear pods).
## Its own weapons, more than bullet patterns:
##   rail shot       a rail cannon turns to the ship, the line through it to
##                   the bottom edge is marked, then four iron slugs go down
##                   it fast (they can't be shot and they stop shots)
##   arc mines       the batteries lob mines that slow to a stop round the
##                   ship and link up with electric arcs (marked, then live):
##                   a tripwire through the ship's row; in OVERDRIVE a cage
##                   of four round it that shrinks. A mine shot down takes
##                   its arcs with it
##   shutter blades  the eye's two shutter halves fly off as spinning blades
##                   round a loop down either side of the screen (the loop
##                   marked first) and back to the eye, which is bare while
##                   they are out; they can be shot down in flight
##   discharge       (OVERDRIVE) a broken rail deck's capacitors arc to the
##                   ship: a forked bolt, marked, then struck
##   vortex          (OVERDRIVE) the open eye drags the ship toward it, then
##                   the NOVA: a ring of iron balls and a ring of shells burst
##                   out to about where the ship is and halt there; then the
##                   eye draws them back in (they are tethered: hollow rings
##                   on lines of light to the eye, so they read as coming
##                   back; only they are drawn back)
## Phase A: the pods fire shell fans in turn, rail shots, arc tripwires. The
## eye (only vulnerable while open, open longer than shut; with a shutter
## shot off, shots get in on that side while it is shut) opens with a needle
## shotgun, then by turns the shutter blades, or three gaze strikes (a sight
## follows the ship, holds still and the spot bursts with a few slow shells:
## MarkedStrikes) and a second shotgun.
## OVERDRIVE (both rail cannons gone, all four pods gone, or after a while):
## the fortress sways; a living rail cannon marks two lines at a time (one
## through the ship, one where it is heading), broken decks discharge, mines
## come as cages; the eye opens longer: four gaze strikes (every other one
## ahead of where the ship is heading), a wide needle fan and the vortex.

const MarkedStrikes := preload("res://scripts/bosses/marked_strikes.gd")
const INFO := {
	"name": "OMEGA CORTEX", "role": "boss",
	"desc": "ステージ 1 の STAR CORTEX を完成させて武装した最終面のボス 1 体目。八角形の本体と目（シャッター 2 枚、4 つのポッド）はそのまま、トラスの桁で左右に砲甲板を張り出してレールキャノン（コンデンサーで光る）を載せ、後ろの架台に機雷の発射機が 2 基。見えない装甲はなし（外れた弾は本体の上を抜ける）。目は開いている時だけ効く（閉じている時間より長く開く。シャッターを片方壊せばその側からは閉じていても撃ち込める）。通常：ポッドが交代で物理弾の扇。レール射撃（砲塔が自機を向き、自機を通って下端までの線を予兆、そのあと鉄球弾 4 発を速く）。電磁機雷（自機の左右に止まって、予兆のあと電撃の線でつながる。撃ち落とせばその線が消える）。目が開くと針弾の散弾、そして交互に、シャッター刃（シャッターが外れて回転しながら画面の左右を大きく回って戻る。軌道を予兆、飛んでいる間は目がむき出しで、刃も撃ち落とせる）か、照準爆撃 3 つ（照準が自機を少し遅れて追い、止まるとその場が炸裂して遅い物理弾を少し撒く）ともう一度散弾。レールキャノンを両方壊すか、ポッドを全部壊すか、時間で OVERDRIVE：揺れながら、レールキャノンは 2 本同時、壊れた砲甲板からは放電（自機へ枝分かれする稲妻、予兆つき）、機雷は 4 つで自機を囲む檻になって縮む（1 つ撃てば抜けられる）。目は長く開き、照準爆撃 4 つ（1 つおきに自機の向かう先）、広い針弾、そして大技の重力渦：自機を目に引き寄せ、NOVA（鉄球弾と物理弾の輪が自機のあたりまで広がって止まる）、そのあと自分の遅い弾を全部吸い戻す（自機を通り過ぎた弾が下から戻ってくる）",
	"demos": [["FULL", ""], ["OVERDRIVE", "B"], ["RAILS DOWN", "C"]],
}
const EYE_HP := 1450.0
const EYE_SCORE := 80000
const POD_HP := 110.0
const POD_SCORE := 5000
const RAIL_HP := 320.0
const RAIL_SCORE := 12000
const SHUTTER_HP := 240.0
const SHUTTER_SCORE := 6000
const MINE_HP := 8.0
const MINE_SCORE := 500
const POD_OFF := [Vector3(-5.6, 0, -2.4), Vector3(5.6, 0, -2.4), Vector3(-4.3, 0, 3.3), Vector3(4.3, 0, 3.3)]
const RAIL_OFF := [Vector3(-11.5, 0, -1.0), Vector3(11.5, 0, -1.0)]
const BATTERY_OFF := [Vector3(-5.6, 0, -6.3), Vector3(5.6, 0, -6.3)]
const SHUTTER_R := 1.35
const SHUTTER_X := 1.05
const SHUTTER_OPEN := 2.2  # how far each half slides out, open
const RAIL_LEN := 3.2  # turret centre to the muzzle
const RAIL_LOCK := 1.0  # the rail shot: marked this long, then
const SLUGS := 4
const SLUG_GAP := 0.12
const SLUG_SPEED := 16.0
const RAIL_TURN := 1.6  # the turret's slew (rad/s)
## the eye: seconds shut, then open, per round (phase A, OVERDRIVE)
const CLOSED_A := 2.6
const OPEN_A := 4.6
const CLOSED_B := 1.6
const OPEN_B := 6.5
const ENRAGE_T := 50.0
## arc mines: the flight to their spot, the arcs marked, then live
const MINE_FLY := 1.1
const ARC_WARN := 0.8
const ARC_LIVE := 1.6  # phase A's tripwire
const ARC_REACH := 7.0  # ... each mine this far either side of the ship
const CAGE_LIVE := 1.8  # OVERDRIVE's cage (one a round, before the vortex) shrinks all the while ...
const CAGE_HALF := 5.0
const CAGE_SHRINK := 0.25  # ... to this
const ARC_HW := 0.2
const ARC_COL := Color(0.55, 0.92, 1.0)
## shutter blades: the loop marked, then flown (the right one a little later)
const BLADE_WARN := 0.9
const BLADE_FLY := 3.0
const BLADE_LAG := 0.35
const BLADE_R := 1.6
## the left blade's loop from its open place (offsets from the centre; the
## right one flies its mirror)
const BLADE_LOOP := [Vector3(-3.25, 0, 0.0), Vector3(-8.5, 0, 3.0), Vector3(-12.5, 0, 10.0), Vector3(-9.5, 0, 17.5), Vector3(-2.0, 0, 16.5), Vector3(-2.8, 0, 7.0)]
## discharge: marked, then struck
const BOLT_LOCK := 0.7
const BOLT_LIVE := 0.25
## the vortex (seconds into the open eye): the drag and the NOVA's lock-on,
## the NOVA flying out and halting, then the eye draws its bullets back
const VORTEX_AT := 2.2
const NOVA_LOCK := 1.3
const NOVA_FLY := 1.3
const WELL_T := 1.8  # (on past the eye's shutting: till the NOVA is all back)
const PULL := 5.0  # the drag on the ship (it flies 17) ...
const DRAG_STOP := 9.0  # ... never closer than this below the core (clear of its body)
const WELL := 14.0

static var _arc_mat: ShaderMaterial

var hull: MeshInstance3D
var wings: MeshInstance3D
var eye: Enemy
var pods: Array[Enemy] = []
var shutters: Array[Enemy] = []
var rails: Array[Enemy] = []
var decks: Array[Enemy] = []  # where a broken deck's discharge is announced (no hit zone)
var rail_a := [PI / 2.0, PI / 2.0]  # where each rail cannon points (PI/2 = down)
## rail shots: {k, to: [Vector3, ...], t, slugs, gap}
var rail_shots: Array[Dictionary] = []
var rail_t := 1.2
var rail_k := 0
var mine_t := 2.0
## arc mines in flight or linked: {m: [Enemy], from, to, links: [[i, j]],
## t, state (0 flying, 1 marked, 2 live), cage, c, w: [warning per link]}
var nets: Array[Dictionary] = []
## discharges: {k, from, to, f: [fork ends], t}
var bolts: Array[Dictionary] = []
var bolt_t := 0.8
var bolt_k := 0
var blade_t := [-1.0, -1.0]  # seconds into each shutter's flight (< 0: at the eye)
var blade_pts: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
var blade_len: Array[PackedFloat32Array] = [PackedFloat32Array(), PackedFloat32Array()]
var eye_round := 0
var pulling := false
var pull_vis := 0.0  # how strongly the drag is shown (fades in and out)
var pull_ring := 0.0
var arcs: MeshInstance3D
var arc_mesh: ImmediateMesh
var arc_tris: Array = []  # [p, color, uv] collected for this frame's arcs
var center := Vector3.ZERO
var phase := 0  # 0 enter, 1 A, 2 OVERDRIVE, 3 dying
var st := 0.0
var fight_t := 0.0
var cycle_t := 0.0
var open := 0.0
var open_want := false
var fired := {}
var gaze: MarkedStrikes
var pod_t := 1.0
var pod_k := 0
var destroyed := false
var dying_t := 0.0
var ship_v := Vector3.ZERO
var ship_last := Vector3.ZERO


func setup(g: Game) -> void:
	game = g
	center = Vector3(0, 0, game.field_top - 10.0)
	ship_last = game.player.position
	# order matters: shots test enemies in list order, so the shutters come
	# before the eye they cover
	for s in [-1, 1]:
		var sh := game.spawn_part(self, "boss_shutter", SHUTTER_R)
		sh.hp = SHUTTER_HP
		sh.max_hp = SHUTTER_HP
		sh.score = SHUTTER_SCORE
		sh.energy_drop = 10.0
		sh.blast = 2.5
		sh.armored = true
		sh.ram = false
		sh.model.position = Vector3(-s * SHUTTER_X, 1.25, 0)
		sh.model.scale = Vector3(-s, 1, 1)
		shutters.append(sh)
	eye = game.spawn_part(self, "boss_eye", 1.9)
	eye.hp = EYE_HP
	eye.max_hp = EYE_HP
	eye.armored = true
	eye.score = EYE_SCORE
	eye.blast = 6.0
	gaze = MarkedStrikes.new(g, self, MarkedStrikes.LANCE, Color(1.0, 0.35, 0.75))
	for k in 4:
		var e := game.spawn_part(self, "boss_pod", 1.45)
		e.hp = POD_HP
		e.max_hp = POD_HP
		e.score = POD_SCORE
		e.energy_drop = 12.0
		e.blast = 2.5
		e.armored = true
		pods.append(e)
	for k in 2:
		var r := game.spawn_part(self, "omega_rail", 1.7)
		r.hp = RAIL_HP
		r.max_hp = RAIL_HP
		r.score = RAIL_SCORE
		r.energy_drop = 16.0
		r.blast = 3.2
		r.armored = true
		r.ram = false
		rails.append(r)
	for k in 2:
		var d := game.spawn_part(self, "", 1.4)
		d.intangible = true
		d.shootable = false
		d.lock = false
		d.ram = false
		decks.append(d)
	hull = MeshInstance3D.new()
	hull.mesh = Vox.get_mesh("boss_hull")
	add_child(hull)
	wings = MeshInstance3D.new()
	wings.mesh = Vox.get_mesh("omega_wings")
	add_child(wings)
	if _arc_mat == null:
		_arc_mat = ShaderMaterial.new()
		_arc_mat.shader = load("res://shaders/lightning.gdshader")
		_arc_mat.render_priority = 2
	arc_mesh = ImmediateMesh.new()
	arcs = MeshInstance3D.new()
	arcs.mesh = arc_mesh
	arcs.material_override = _arc_mat
	arcs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arcs.extra_cull_margin = 16384.0
	add_child(arcs)
	for k in 2:
		_bake_loop(k)
	_place(0.0)


func on_hit(_e: Enemy, dmg: float) -> float:
	return dmg


func on_part_killed(e: Enemy) -> void:
	if e == eye:
		_die()
		return
	if e.mesh_name == "omega_mine":
		return  # its arcs go with it (_nets)
	game.shake(0.8)
	var k := rails.find(e)
	if k >= 0:
		for r in rail_shots.duplicate():
			if r["k"] == k and r["slugs"] == SLUGS:
				rail_shots.erase(r)  # marked but not fired: called off
	if phase == 1 and (rails_alive() == 0 or pods_alive() == 0):
		_overdrive()


func shutters_alive() -> int:
	var c := 0
	for q in shutters:
		if not q.dead:
			c += 1
	return c


func pods_alive() -> int:
	var c := 0
	for q in pods:
		if not q.dead:
			c += 1
	return c


func rails_alive() -> int:
	var c := 0
	for q in rails:
		if not q.dead:
			c += 1
	return c


func _place(dt: float) -> void:
	hull.position = center
	wings.position = center
	eye.position = center + Vector3(0, -0.4, 0)
	for k in 4:
		if not pods[k].dead:
			pods[k].position = center + POD_OFF[k]
	var gap := open * SHUTTER_OPEN
	for k in 2:
		var sh := shutters[k]
		if sh.dead:
			continue
		var s := -1.0 if k == 0 else 1.0
		var spin := 0.0
		if float(blade_t[k]) >= 0.0:
			# flying: eased out of the eye and back in again, spinning
			var u := float(blade_t[k]) / BLADE_FLY
			var f := u - sin(TAU * u) / TAU
			var total: float = blade_len[k][blade_len[k].size() - 1]
			sh.position = center + _along(k, total * f)
			spin = -s * TAU * 6.0 * f
		else:
			sh.position = center + Vector3(s * (gap + SHUTTER_X), 0, 0)
		sh.model.rotation.y = spin
		sh.model.position = Vector3(-s * SHUTTER_X, 1.25, 0).rotated(Vector3.UP, spin)
	for k in 2:
		decks[k].position = center + RAIL_OFF[k]
		var r := rails[k]
		r.position = center + RAIL_OFF[k]
		if not r.dead:
			# the turret turns after the ship, unless a shot is marked
			var held := false
			for q in rail_shots:
				if q["k"] == k:
					held = true
			if not held and phase >= 1 and phase <= 2:
				var d := game.player.position - r.position
				rail_a[k] = rotate_toward(float(rail_a[k]), atan2(d.z, d.x), RAIL_TURN * dt)
			r.model.rotation.y = atan2(cos(float(rail_a[k])), sin(float(rail_a[k])))


func _warn_at(key: String, at: float, dur: float, kind: int) -> void:
	if cycle_t >= at - dur and not fired.has("w_" + key):
		fired["w_" + key] = true
		game.warn(eye, dur, kind, eye.radius)


func _fire_once(key: String, at: float) -> bool:
	if cycle_t >= at and not fired.has(key):
		fired[key] = true
		return true
	return false


func tick(dt: float) -> void:
	if destroyed:
		return
	st += dt
	if dt > 0.0:
		var p := game.player.position
		ship_v = ship_v.lerp((p - ship_last) / dt, clampf(dt * 8.0, 0.0, 1.0))
		ship_last = p
	pulling = false
	game.bullets.well_pull = 0.0
	game.bullets.tether_owner = get_instance_id()
	game.bullets.tether_at = eye.position
	match phase:
		0:
			center.z = move_toward(center.z, game.field_top + 7.0, 4.0 * dt)
			if st > 4.2:
				phase = 1
				st = 0.0
				for q in pods + shutters + rails:
					q.armored = false
				game.boss_fight_started()
		1:
			fight_t += dt
			_eye_cycle(dt, CLOSED_A, OPEN_A)
			_pods(dt)
			_rails(dt)
			_mines(dt)
			if fight_t > ENRAGE_T:
				_overdrive()
		2:
			fight_t += dt
			center.x = move_toward(center.x, sin(st * 0.55) * 3.5, 4.0 * dt)
			_eye_cycle(dt, CLOSED_B, OPEN_B)
			_pods(dt)
			_rails(dt)
			if _fire_once("cage", 0.0):
				_launch_mines()
			_bolts(dt)
			if pulling:
				_drag(dt)
		3:
			dying_t += dt
			if int(dying_t * 8.0) != int((dying_t - dt) * 8.0):
				var off := Vector3(randf_range(-13, 13), 0, randf_range(-5.5, 4.0))
				game.fx.explode(center + off, randf_range(1.5, 3.0), Vector3.ZERO, Models.STEEL_M)
				game.sfx.play("exp_m")
				game.shake(0.4)
			center.z += dt * 1.2
			if dying_t > 3.6:
				game.big_blast(center, 1.0, Models.STEEL_L)
				for k in 6:
					game.fx.explode(center + Vector3(randf_range(-12, 12), 0, randf_range(-4, 3)), 4.0, Vector3.ZERO, Models.GUN)
				game.sfx.play("exp_l")
				game.shake(2.0)
				destroyed = true
				finished = true
				visible = false
				for q in [eye] + pods + shutters + rails + decks:
					game.remove_enemy(q)
					q.visible = false
				game.boss_destroyed(self)
				return
	_rail_shots(dt)
	if phase == 1 or phase == 2:
		gaze.tick(dt)
	_fly_blades(dt)
	_nets(dt)
	_tick_bolts(dt)
	open = move_toward(open, 1.0 if open_want else 0.0, dt * 2.5)
	# shut, the eye is armoured while both shutters hold; with one shot off,
	# shots get in on that side
	eye.armored = phase == 0 or phase == 3 or (open < 0.7 and shutters_alive() == 2)
	eye.model.rotation.y += dt * (2.2 if phase == 2 else 0.6)
	_place(dt)
	pull_vis = move_toward(pull_vis, 1.0 if pulling else 0.0, dt * 4.0)
	_draw_arcs()


## Both rail cannons gone, all the pods gone, or time up: OVERDRIVE.
func _overdrive() -> void:
	phase = 2
	st = 0.0
	cycle_t = 0.0
	fired.clear()
	game.show_msg("CORTEX OVERDRIVE", "", 1.5, true)
	game.shake(1.0)
	game.sfx.play("slam")


## One round of the eye: shut, then open with its attacks (each energy shot
## announced on the eye). It stays open until its blades are back.
func _eye_cycle(dt: float, closed_time: float, open_time: float) -> void:
	cycle_t += dt
	var c := closed_time
	var w := Enemy.WINDUP_SHOT
	var is_open := cycle_t > c and cycle_t < c + open_time
	open_want = is_open or _blades_out()
	if is_open:
		if phase == 1:
			_warn_at("shotgun1", c + 0.3 + w, w, Game.Warn.SHOT)
			if _fire_once("shotgun1", c + 0.3 + w):
				game.bullets.fan(eye.position, game.bullets.aim(eye.position), 7, 24.0, 9.0, Bullets.ORB, self, Bullets.NEEDLE)
			if eye_round % 2 == 0 and shutters_alive() > 0:
				_blades(c + 0.7)
			else:
				_gaze(c + 1.2, 3, 0.5, 4, false)
				_warn_at("shotgun2", c + 3.3 + w, w, Game.Warn.SHOT)
				if _fire_once("shotgun2", c + 3.3 + w):
					game.bullets.fan(eye.position, game.bullets.aim(eye.position), 9, 40.0, 9.5, Bullets.ORB, self)
		else:
			_gaze(c + 0.2, 4, 0.4, 6, true)
			_warn_at("shotgun1", c + 0.9 + w, w, Game.Warn.SHOT)
			if _fire_once("shotgun1", c + 0.9 + w):
				game.bullets.fan(eye.position, game.bullets.aim(eye.position), 11, 60.0, 9.5, Bullets.ORB, self, Bullets.NEEDLE)
	if phase == 2:
		_vortex(c + VORTEX_AT)
	if cycle_t > closed_time + open_time + 0.4 and not _blades_out():
		cycle_t = 0.0
		fired.clear()
		eye_round += 1


## The eye's gaze strikes: `count` sights dropped one after another, `gap`
## apart, from `at`, each bursting with `shells` slow shells; with `lead`,
## every other one goes ahead of where the ship is heading.
func _gaze(at: float, count: int, gap: float, shells: int, lead: bool) -> void:
	for i in count:
		if _fire_once("gaze%d" % i, at + i * gap):
			var off := Vector3.ZERO
			if lead and i % 2 == 1:
				off = Vector3(ship_v.x, 0, ship_v.z).limit_length(10.0) * 0.4
			gaze.drop(eye, Vector3.ZERO, off, shells, i == 0, 1.0 if i % 2 == 0 else -1.0)


# ------------------------------------------------------------ shutter blades

## The shutter halves (those still on) fly off round their loops: each loop
## is marked with chevrons first, then flown.
func _blades(at: float) -> void:
	if cycle_t >= at and not fired.has("w_blades"):
		fired["w_blades"] = true
		var first := true
		for k in 2:
			if shutters[k].dead:
				continue
			var path := PackedVector3Array()
			var pts := blade_pts[k]
			for j in range(0, pts.size(), 3):
				path.append(center + pts[j])
			path.append(center + pts[pts.size() - 1])
			game.warn(shutters[k], BLADE_WARN + k * BLADE_LAG, Game.Warn.MOVE, SHUTTER_R, path, first)
			first = false
	for k in 2:
		if _fire_once("blade%d" % k, at + BLADE_WARN + k * BLADE_LAG) and not shutters[k].dead:
			blade_t[k] = 0.0
			shutters[k].ram = true
			shutters[k].radius = BLADE_R
			game.sfx.play("slam")
			game.fx.flash(shutters[k].position, 0.4)


func _blades_out() -> bool:
	return float(blade_t[0]) >= 0.0 or float(blade_t[1]) >= 0.0


func _fly_blades(dt: float) -> void:
	for k in 2:
		if float(blade_t[k]) < 0.0:
			continue
		var sh := shutters[k]
		if sh.dead or defeated:
			blade_t[k] = -1.0
			continue
		blade_t[k] = float(blade_t[k]) + dt
		if randf() < 0.5:
			game.fx.spark(sh.position + Vector3(0, 0.6, 0), ARC_COL, 1, 0.3)
		if float(blade_t[k]) >= BLADE_FLY:
			# home: back in its slot by the eye
			blade_t[k] = -1.0
			sh.ram = false
			sh.radius = SHUTTER_R
			game.sfx.play("deflect")


## A blade's loop as a closed Catmull-Rom curve through BLADE_LOOP (offsets
## from the centre), sampled with the distance along it.
func _bake_loop(k: int) -> void:
	var m := 1.0 if k == 0 else -1.0
	var ctrl: Array[Vector3] = []
	for q: Vector3 in BLADE_LOOP:
		ctrl.append(Vector3(q.x * m, 0, q.z))
	var n := ctrl.size()
	var pts := PackedVector3Array()
	var cum := PackedFloat32Array()
	var total := 0.0
	for i in n:
		var p0 := ctrl[(i - 1 + n) % n]
		var p1 := ctrl[i]
		var p2 := ctrl[(i + 1) % n]
		var p3 := ctrl[(i + 2) % n]
		for j in 12:
			var t := j / 12.0
			var q := 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)
			if not pts.is_empty():
				total += q.distance_to(pts[pts.size() - 1])
			pts.append(q)
			cum.append(total)
	total += ctrl[0].distance_to(pts[pts.size() - 1])
	pts.append(ctrl[0])
	cum.append(total)
	blade_pts[k] = pts
	blade_len[k] = cum


func _along(k: int, d: float) -> Vector3:
	var pts := blade_pts[k]
	var cum := blade_len[k]
	var i := cum.bsearch(d)
	if i <= 0:
		return pts[0]
	if i >= pts.size():
		return pts[pts.size() - 1]
	var f := (d - cum[i - 1]) / maxf(cum[i] - cum[i - 1], 0.0001)
	return pts[i - 1].lerp(pts[i], f)


# ------------------------------------------------------------ vortex

## OVERDRIVE's big move, from `at` into the open eye: the eye drags the ship
## toward it through a long lock-on, the NOVA bursts out to about where the
## ship is and halts, then the eye draws its slow bullets back in.
func _vortex(at: float) -> void:
	var nova_at := at + NOVA_LOCK
	var halt_at := nova_at + NOVA_FLY
	var well_at := halt_at + 0.3
	if cycle_t >= at and not fired.has("w_nova"):
		fired["w_nova"] = true
		game.warn(eye, NOVA_LOCK, Game.Warn.MOVE, eye.radius * 1.6)
		game.sfx.play("slam")
		game.show_msg("GRAVITY WELL", "", 1.4, true)
	pulling = cycle_t >= at and cycle_t < halt_at
	if cycle_t >= well_at and cycle_t < well_at + WELL_T:
		game.bullets.well = eye.position
		game.bullets.well_owner = get_instance_id()
		game.bullets.well_pull = WELL
		if randf() < 0.6:
			_inflow(10.0, 22.0)
	if _fire_once("nova", nova_at):
		var d := game.player.position - eye.position
		var reach := clampf(Vector2(d.x, d.z).length(), 9.0, 18.0)
		var aim := atan2(d.z, d.x)
		# iron balls halting just past the ship (it sits between two) and
		# shells a little further, with a gap toward where it is heading
		var v0 := 2.0 * (reach + 0.5) / NOVA_FLY
		for k in 8:
			game.bullets.fire(eye.position, aim + PI / 8.0 + TAU * k / 8.0, v0, Bullets.IRON, self, Bullets.ROUND, v0 / NOVA_FLY, 0.0)
			game.bullets.tether()
		var head := aim + (0.35 if ship_v.x > 0.0 else -0.35)
		v0 = 2.0 * (reach + 2.0) / NOVA_FLY
		for i in 28:
			var a := TAU * i / 28.0
			if absf(wrapf(a - head, -PI, PI)) < TAU / 28.0 * 2.0:
				continue
			game.bullets.fire(eye.position, a, v0, Bullets.SHELL, self, Bullets.ROUND, v0 / NOVA_FLY, 0.0, Bullets.BIG if i % 2 == 0 else Bullets.SMALL)
			game.bullets.tether()
		game.flash_a = maxf(game.flash_a, 0.15)
		game.shake(0.7)
		game.sfx.play("exp_m")


## The ship drawn toward the eye (it can fly against it), streaks pouring in;
## the drag gives out short of the fortress, so it never pulls the ship into
## the hull. Shown on the ship itself (yos: the pull was not plain to see):
## a tractor beam from the eye down to the ship with chevrons running up it
## (_draw_arcs), rings closing in on the ship, sparks torn off it toward
## the eye, and GRAVITY WELL on the screen as it starts.
func _drag(dt: float) -> void:
	var d := eye.position - game.player.position
	d.y = 0.0
	if d.length() > 3.0 and game.state != Game.State.VIEWER:
		var v := d.normalized() * PULL
		if game.player.position.z + v.z * dt < center.z + DRAG_STOP:
			v.z = 0.0
		game.player.drift(v, dt)
	_inflow(8.0, 20.0)
	var pp := game.player.position + Vector3(0, 0.6, 0)
	var up := (eye.position - game.player.position).normalized()
	pull_ring -= dt
	if pull_ring <= 0.0:
		pull_ring = 0.22
		game.fx.sprite(pp, Vector3.ZERO, 3.4, 0.6, 0.3, ARC_COL, 2.0)
	for k in 2:
		var off := Vector3(randf_range(-0.9, 0.9), 0, randf_range(-0.6, 0.9))
		game.fx.sprite(pp + off, up * randf_range(9.0, 14.0), 0.35, 0.1, 0.45, ARC_COL, 0.0)


func _inflow(r0: float, r1: float) -> void:
	var a := randf() * TAU
	var off := Vector3(cos(a), 0, sin(a)) * randf_range(r0, r1)
	game.fx.sprite(eye.position + off + Vector3(0, 0.6, 0), -off / 0.9, 0.32, 0.08, 0.9, ARC_COL, 0.0)


# ------------------------------------------------------------ pods, rails

func _pods(dt: float) -> void:
	pod_t -= dt
	if pod_t > 0.0 or pods_alive() == 0:
		return
	pod_t = 1.0 if phase == 1 else 1.3
	for i in 4:
		pod_k = (pod_k + 1) % 4
		var q := pods[pod_k]
		if not q.dead:
			var at := q.position + Vector3(0, 0, 1.0)
			game.bullets.fan(at, game.bullets.aim(at), 5, 44.0, 6.0, Bullets.SHELL, self)
			break


## The rail cannons take turns: one marked shot at a time in phase A, two
## lines at once from one cannon in OVERDRIVE (through the ship, and where
## it is heading).
func _rails(dt: float) -> void:
	rail_t -= dt
	if rail_t > 0.0 or rails_alive() == 0:
		return
	rail_t = 3.2 if phase == 1 else 2.6
	for i in 2:
		rail_k = (rail_k + 1) % 2
		var r := rails[rail_k]
		if r.dead or not game.boss_can_fire(r.position):
			continue
		var muzzle := r.position + Vector3(cos(float(rail_a[rail_k])), 0, sin(float(rail_a[rail_k]))) * RAIL_LEN
		var tos: Array = [game.line_to_bottom(muzzle, game.player.position)]
		if phase == 2:
			var side := signf(ship_v.x) if absf(ship_v.x) > 1.0 else (-signf(game.player.position.x) if absf(game.player.position.x) > 0.5 else 1.0)
			tos.append(game.line_to_bottom(muzzle, game.player.position + Vector3(side * 3.2, 0, 0)))
		for to: Vector3 in tos:
			game.warn(r, RAIL_LOCK, Game.Warn.MOVE, r.radius, to, to == tos[0])
		rail_a[rail_k] = atan2(tos[0].z - r.position.z, tos[0].x - r.position.x)
		rail_shots.append({"k": rail_k, "to": tos, "t": RAIL_LOCK, "slugs": SLUGS, "gap": 0.0})
		game.sfx.play("slam")
		return


## Marked rail shots: once the lock runs out, the slugs go down the lines
## one after another (the turret swings between two lines).
func _rail_shots(dt: float) -> void:
	for q in rail_shots.duplicate():
		var r := rails[int(q["k"])]
		if r.dead or defeated:
			rail_shots.erase(q)
			continue
		q["t"] -= dt
		# sparks run up the rails while it charges
		if q["t"] > 0.0 and randf() < 0.4:
			var d := Vector3(cos(float(rail_a[int(q["k"])])), 0, sin(float(rail_a[int(q["k"])])))
			game.fx.sprite(r.position + d * randf_range(0.5, RAIL_LEN) + Vector3(0, 0.5, 0), Vector3.ZERO, 0.45, 0.1, 0.12, Color(0.6, 0.95, 1.0), 0.0)
		if q["t"] > 0.0:
			continue
		q["gap"] -= dt
		if q["gap"] > 0.0:
			continue
		q["gap"] = SLUG_GAP
		var tos: Array = q["to"]
		var to: Vector3 = tos[(SLUGS - int(q["slugs"])) % tos.size()]
		var a := atan2(to.z - r.position.z, to.x - r.position.x)
		rail_a[int(q["k"])] = a
		var muzzle := r.position + Vector3(cos(a), 0, sin(a)) * RAIL_LEN
		if game.combat_on():
			game.bullets.fire(muzzle, atan2(to.z - muzzle.z, to.x - muzzle.x), SLUG_SPEED, Bullets.IRON, self)
			game.fx.flash(muzzle, 0.4)
			game.sfx.play("exp_s")
		q["slugs"] = int(q["slugs"]) - 1
		if int(q["slugs"]) <= 0:
			rail_shots.erase(q)


# ------------------------------------------------------------ arc mines

## The batteries at the back lob arc mines that slow to a stop round the
## ship: a pair either side of it (phase A, every few seconds), four boxing
## it in (OVERDRIVE, as the eye shuts).
func _mines(dt: float) -> void:
	mine_t -= dt
	if mine_t > 0.0:
		return
	mine_t = 4.6
	_launch_mines()


func _launch_mines() -> void:
	if not game.boss_can_fire(center):
		return
	var p := game.player.position
	var hw := game.field_hw - 1.5
	var tos: Array[Vector3] = []
	var links := []
	var c := p
	if phase == 1:
		var tilt := randf_range(-0.35, 0.35)
		var dir := Vector3(cos(tilt), 0, sin(tilt)) * ARC_REACH
		var a := p - dir
		var b := p + dir
		var shift := 0.0
		if a.x < -hw:
			shift = -hw - a.x
		elif b.x > hw:
			shift = hw - b.x
		for q: Vector3 in [a, b]:
			tos.append(Vector3(q.x + shift, 0, clampf(q.z, game.field_top + 9.0, game.field_bottom - 1.0)))
		links = [[0, 1]]
	else:
		c = Vector3(clampf(p.x, -hw + CAGE_HALF, hw - CAGE_HALF), 0, clampf(p.z, game.field_top + 14.0, game.field_bottom - 1.0 - CAGE_HALF))
		var turn := randf_range(-0.3, 0.3)
		for q: Vector3 in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(1, 0, 1), Vector3(-1, 0, 1)]:
			tos.append(c + (q * CAGE_HALF).rotated(Vector3.UP, turn))
		links = [[0, 1], [1, 2], [2, 3], [3, 0]]
	var ms: Array[Enemy] = []
	var froms: Array[Vector3] = []
	for to in tos:
		var at: Vector3 = center + BATTERY_OFF[0 if to.x < center.x else 1] + Vector3(0, 0, 1.0)
		var m := game.spawn_part(self, "omega_mine", 0.8)
		m.hp = MINE_HP
		m.max_hp = MINE_HP
		m.score = MINE_SCORE
		m.energy_drop = 4.0
		m.blast = 1.2
		m.debris_col = Models.STEEL_M
		m.ram = false  # only its arcs hurt, like a ground gun's body
		m.position = at
		m.hit_pos = at
		ms.append(m)
		froms.append(at)
		game.fx.flash(at, 0.4)
	nets.append({"m": ms, "from": froms, "to": tos, "links": links, "t": 0.0, "state": 0, "cage": phase == 2, "c": c, "w": []})
	game.sfx.play("exp_s")


func _nets(dt: float) -> void:
	for nt: Dictionary in nets.duplicate():
		var ms: Array = nt["m"]
		nt["t"] = float(nt["t"]) + dt
		var t: float = nt["t"]
		var alive := 0
		for m: Enemy in ms:
			if not m.dead:
				alive += 1
				m.model.rotation.y += dt * 2.5
		if alive == 0 or defeated:
			_end_net(nt)
			continue
		var live := CAGE_LIVE if nt["cage"] else ARC_LIVE
		match int(nt["state"]):
			0:
				# flying out, slowing to a stop on the spot
				var u := clampf(t / MINE_FLY, 0.0, 1.0)
				var f := 1.0 - (1.0 - u) * (1.0 - u)
				for i in ms.size():
					if not (ms[i] as Enemy).dead:
						(ms[i] as Enemy).position = (nt["from"][i] as Vector3).lerp(nt["to"][i], f)
				if u >= 1.0:
					nt["state"] = 1
					nt["t"] = 0.0
					_mark_net(nt)
			1:
				if t >= ARC_WARN:
					nt["state"] = 2
					nt["t"] = 0.0
					game.sfx.play("exp_s")
			2:
				if nt["cage"]:
					var k := lerpf(1.0, CAGE_SHRINK, clampf(t / live, 0.0, 1.0))
					var c: Vector3 = nt["c"]
					for i in ms.size():
						if not (ms[i] as Enemy).dead:
							(ms[i] as Enemy).position = c + ((nt["to"][i] as Vector3) - c) * k
				for l: Array in nt["links"]:
					var a: Enemy = ms[l[0]]
					var b: Enemy = ms[l[1]]
					if not a.dead and not b.dead and game.combat_on() and _on_line(a.position, b.position, ARC_HW):
						game.touch_player("omega arc")
				if t >= live:
					_end_net(nt)
					continue
		# the marks (for the autopilot) follow the mines; a broken link's goes
		var ws: Array = nt["w"]
		for j in ws.size():
			var w: Dictionary = ws[j]
			if w.is_empty():
				continue
			var l: Array = nt["links"][j]
			var a: Enemy = ms[l[0]]
			var b: Enemy = ms[l[1]]
			if a.dead or b.dead:
				w["t"] = 0.0
			else:
				(w["to"] as Dictionary)["laser"] = PackedVector3Array([a.position, b.position])


## The mines have stopped: each link is marked (a reticle on its mine) for
## as long as it will be live.
func _mark_net(nt: Dictionary) -> void:
	var ms: Array = nt["m"]
	var dur := ARC_WARN + (CAGE_LIVE if nt["cage"] else ARC_LIVE)
	var ws := []
	var first := true
	for l: Array in nt["links"]:
		var a: Enemy = ms[l[0]]
		var b: Enemy = ms[l[1]]
		if a.dead or b.dead:
			ws.append({})
			continue
		game.warn(a, dur, Game.Warn.MOVE, a.radius, {"laser": PackedVector3Array([a.position, b.position])}, first)
		ws.append(game.warnings[game.warnings.size() - 1])
		first = false
	if not nt["cage"] and not (ms[1] as Enemy).dead:
		game.warn(ms[1], dur, Game.Warn.MOVE, (ms[1] as Enemy).radius, null, false, false)
	nt["w"] = ws


## The mines' time is up (or all shot down): those left fizzle out.
func _end_net(nt: Dictionary) -> void:
	for w: Dictionary in nt["w"]:
		if not w.is_empty():
			w["t"] = 0.0
	for m: Enemy in nt["m"]:
		if not m.dead:
			m.dead = true
			game.fx.sprite(m.position + Vector3(0, 0.6, 0), Vector3.ZERO, 1.8, 0.3, 0.25, ARC_COL, 0.0)
			game.fx.spark(m.position + Vector3(0, 0.6, 0), ARC_COL, 5, 0.45)
			game.remove_enemy(m)
		m.queue_free()
	nets.erase(nt)


func _on_line(a: Vector3, b: Vector3, hw: float) -> bool:
	var pp := game.player.position
	var c := Geometry3D.get_closest_point_to_segment(Vector3(pp.x, 0, pp.z), Vector3(a.x, 0, a.z), Vector3(b.x, 0, b.z))
	return Vector2(pp.x - c.x, pp.z - c.z).length() < hw + Player.HIT_R


# ------------------------------------------------------------ discharge

## OVERDRIVE: a broken rail deck's capacitors arc to the ship, by turns: a
## bolt from the deck to where the ship is, forking on past it, marked first.
func _bolts(dt: float) -> void:
	if rails_alive() == 2:
		return
	bolt_t -= dt
	if bolt_t > 0.0:
		return
	bolt_t = 1.5 if rails_alive() == 1 else 1.1
	for i in 2:
		bolt_k = (bolt_k + 1) % 2
		if rails[bolt_k].dead:
			break
	var from: Vector3 = center + RAIL_OFF[bolt_k]
	if not game.boss_can_fire(from):
		return
	var to := game.player.position
	var dir := to - from
	dir.y = 0.0
	dir = dir.normalized()
	var forks: Array[Vector3] = [to + dir.rotated(Vector3.UP, 0.75) * 3.4, to + dir * 3.8, to + dir.rotated(Vector3.UP, -0.75) * 3.4]
	bolts.append({"k": bolt_k, "from": from, "to": to, "f": forks, "t": 0.0})
	game.warn(decks[bolt_k], BOLT_LOCK, Game.Warn.MOVE, 1.4, {"laser": PackedVector3Array([from, to, forks[1]])})
	for k in 3:
		game.fx.spark(from + Vector3(randf_range(-1.5, 1.5), 0.8, randf_range(-1.5, 1.5)), ARC_COL, 2, 0.4)


func _tick_bolts(dt: float) -> void:
	for b: Dictionary in bolts.duplicate():
		var was: float = b["t"]
		b["t"] = was + dt
		b["from"] = center + RAIL_OFF[int(b["k"])]  # the deck sways with the fortress
		if defeated:
			bolts.erase(b)
			continue
		if was < BOLT_LOCK and float(b["t"]) >= BOLT_LOCK:
			game.fx.flash(b["to"], 0.6)
			game.sfx.play("exp_m")
			game.shake(0.3)
		if float(b["t"]) >= BOLT_LOCK and game.combat_on():
			var hit := _on_line(b["from"], b["to"], 0.3)
			for f: Vector3 in b["f"]:
				hit = hit or _on_line(b["to"], f, 0.25)
			if hit:
				game.touch_player("omega discharge")
		if float(b["t"]) >= BOLT_LOCK + BOLT_LIVE:
			bolts.erase(b)


# ------------------------------------------------------------ drawing

## The arcs between mines and the discharges: a thin flickering line while
## marked, a jagged bolt with a glow round it while live.
func _draw_arcs() -> void:
	arc_mesh.clear_surfaces()
	arc_tris.clear()
	var tm := game.time
	if pull_vis > 0.0 and game.player.alive:
		_tractor(pull_vis)
	for nt: Dictionary in nets:
		var st_n := int(nt["state"])
		if st_n == 0:
			continue
		var ms: Array = nt["m"]
		var j := 0
		for l: Array in nt["links"]:
			j += 1
			var a: Enemy = ms[l[0]]
			var b: Enemy = ms[l[1]]
			if a.dead or b.dead:
				continue
			if st_n == 1:
				_zap(a.position, b.position, 0.07, 0.45 + 0.25 * sin(tm * 70.0 + j), j, 0.1)
			else:
				_zap(a.position, b.position, 0.55, 0.35, j, 0.25)
				_zap(a.position, b.position, ARC_HW, 1.0, j, 0.25)
	for b: Dictionary in bolts:
		var t: float = b["t"]
		var lines := [[b["from"], b["to"]]]
		for f: Vector3 in b["f"]:
			lines.append([b["to"], f])
		var j := 0
		for ln: Array in lines:
			j += 1
			if t < BOLT_LOCK:
				_zap(ln[0], ln[1], 0.06, 0.4 + 0.3 * sin(tm * 80.0 + j), j + 7, 0.12)
			else:
				var fade := clampf((BOLT_LOCK + BOLT_LIVE - t) / BOLT_LIVE, 0.0, 1.0)
				_zap(ln[0], ln[1], 0.7, 0.4 * fade, j + 7, 0.35)
				_zap(ln[0], ln[1], 0.26, fade, j + 7, 0.35)
	if arc_tris.is_empty():
		return
	arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for v: Array in arc_tris:
		arc_mesh.surface_set_color(v[1])
		arc_mesh.surface_set_uv(v[2])
		arc_mesh.surface_add_vertex(v[0])
	arc_mesh.surface_end()


## A jagged ribbon from a to b just over the plane: kinks every ~1.1 units
## jumping about (`jag` at most) as the game clock runs.
## The vortex's tractor beam: a faint funnel from the eye widening down to
## the ship, chevrons streaming up it toward the eye (the way it pulls).
func _tractor(k: float) -> void:
	var top := eye.position
	var bot := game.player.position
	var d := top - bot
	d.y = 0.0
	var len := d.length()
	if len < 2.0:
		return
	var up := d / len
	var side := Vector3(-up.z, 0, up.x)
	var col := Color(ARC_COL.r, ARC_COL.g, ARC_COL.b, 0.07 * k)
	for e: float in [-1.0, 1.0]:
		_zap(top + side * e * 0.6, bot + side * e * 2.6, 0.08, 0.35 * k, 0, 0.0)
	var q0 := Vector3(top.x, 0.36, top.z)
	var q1 := Vector3(bot.x, 0.36, bot.z)
	for v: Array in [[q0 - side * 0.6, 0.0], [q0 + side * 0.6, 1.0], [q1 + side * 2.6, 1.0], [q0 - side * 0.6, 0.0], [q1 + side * 2.6, 1.0], [q1 - side * 2.6, 0.0]]:
		arc_tris.append([v[0], col, Vector2(0, v[1])])
	var s := fmod(game.time * 9.0, 2.2)
	while s < len - 1.5:
		var f := s / len
		var w := lerpf(2.0, 0.5, f)
		var tip := bot + up * (s + 0.7)
		var a := clampf(minf(s / 2.0, (len - 1.5 - s) / 3.0), 0.0, 1.0) * k
		_zap(tip - up * 0.7 + side * w, tip, 0.12, a, 0, 0.0)
		_zap(tip - up * 0.7 - side * w, tip, 0.12, a, 0, 0.0)
		s += 2.2


func _zap(a: Vector3, b: Vector3, w: float, alpha: float, seed: int, jag: float) -> void:
	var d := b - a
	d.y = 0.0
	var n := maxi(2, int(d.length() / 1.1))
	var side := Vector3(-d.z, 0, d.x).normalized()
	var col := Color(ARC_COL.r, ARC_COL.g, ARC_COL.b, alpha)
	var prev := Vector3(a.x, 0.36, a.z)
	for i in range(1, n + 1):
		var q := a.lerp(b, float(i) / n)
		q.y = 0.36
		if i < n:
			q += side * sin(seed * 3.1 + i * 2.39 + game.time * 37.0) * jag
		var s := Vector3(-(q - prev).z, 0, (q - prev).x).normalized() * w
		for v: Array in [[prev - s, 0.0], [prev + s, 1.0], [q + s, 1.0], [prev - s, 0.0], [q + s, 1.0], [q - s, 0.0]]:
			arc_tris.append([v[0], col, Vector2(0, v[1])])
		prev = q


func gauge() -> Dictionary:
	if phase < 1 or phase >= 3:
		return {}
	return {"frac": eye.hp / eye.max_hp, "color": Hud.CYAN if not eye.armored else Color(0.55, 0.6, 0.65), "name": INFO["name"], "name_color": Color(0.75, 0.95, 1.0), "x": 0.2, "w": 0.6, "h": 8.0, "name_y": 72.0}


func force_defeat() -> void:
	if phase < 3:
		game.kill(eye)


## "B": straight into OVERDRIVE, everything still up; "C": the same with
## the rail cannons shot off (their decks discharge).
func viewer_skip(to: String) -> void:
	if to == "B" or to == "C":
		center.z = game.field_top + 7.0
		phase = 1
		for q in pods + shutters + rails:
			q.armored = false
		_overdrive()
		if to == "C":
			for r in rails:
				game.kill(r)
		_place(0.0)


func debug_state() -> String:
	var names := ["enter", "A", "OVERDRIVE", "dying"]
	return "phase %s %.1fs  eye %s %d/%d  pods %d  rails %d  mines %d" % [names[phase], st, "open" if not eye.armored else "shut", int(maxf(eye.hp, 0.0)), int(EYE_HP), pods_alive(), rails_alive(), nets.size()]


func _die() -> void:
	defeated = true
	phase = 3
	dying_t = 0.0
	open_want = true
	pulling = false
	gaze.clear()
	game.bullets.well_pull = 0.0
	rail_shots.clear()
	bolts.clear()
	for q in pods + shutters + rails:
		if not q.dead:
			game.kill(q)
	for nt in nets:
		for m: Enemy in nt["m"]:
			if not m.dead:
				game.kill(m)
	for nt in nets.duplicate():
		_end_net(nt)
	disarm()
	var conv := game.bullets.cancel_all()
	for b in conv:
		game.items.spawn(b, Items.ENERGY, 1.0)
	game.boss_dying()
