extends Enemy
## Mid-size VTOL gunship of the enemy planet (stage 4): two ducted lift
## fans on stub wings, a chin turret with a rotary cannon. It flies in from
## a side edge on a curve, nose first, banking, and comes to a hover near
## the top (the fans keep it up; it turns to face the ship). Its signature
## is the hose: the rotary cannon spins up and sweeps a stream of shells
## across the screen in one long arc, through where the ship is and on past
## it, left to right or back (the shells break: shoot a way through, or go
## round the end of the arc). Then telegraphed needle bursts from the fan
## pods, twice, and a quiet gap: come in with the Spear. When its time is
## up it banks away up the screen to the other side.
## params: side (-1 = in from the left edge), hx (where it hovers), hold
## (z it hovers at), stay (seconds)

const INFO := {
	"name": "KESTREL", "category": "medium",
	"desc": "中型機（VTOL ガンシップ）：画面の横から弧を描いて飛び込み、上のほうでホバリング（2 基のファンで浮く）。機首の回転砲が回り始めると、物理弾の流れを自機のいる所を通って反対側まで大きく弧を描いて撒く（壊せるので撃ち抜くか、弧の端を回る）。予兆のあとファンの砲から狙いの針弾を 2 連。合間に静かな間。時間が来ると反対側の上へ去る",
	"demos": [
		["FROM LEFT", "kestrel", [0.0, -1, -0.3]],
		["PAIR", "kestrel", [0.0, -1, -0.45], "kestrel", [1.4, 1, 0.45]],
	],
}

const T_IN := 2.0  # the curve in
const T_OUT := 2.4  # and away
const FAN := Vector3(1.45, 0, 0.0)  # the fans (and the mirror)
const POD := Vector3(1.45, 0, 0.75)  # the fan pods' muzzles
const GUN := Vector3(0, -0.1, 1.8)  # the chin turret, under and ahead of the nose
const HOSE_T := 1.3
const HOSE_ARC := 55.0  # degrees either side of the ship
const HOSE_EVERY := 0.065
const HOSE_SPEED := 6.2

var side := -1.0
var fans: Array[MeshInstance3D] = []
var gun: MeshInstance3D
var barrels: MeshInstance3D
var gun_a := PI / 2.0  # where the gun points (0 = +x, PI/2 = down-screen)
var from := Vector3.ZERO
var bend := Vector3.ZERO
var to := Vector3.ZERO
var leg := 0  # 0 in, 1 hovering, 2 away
var leg_t := 0.0
var hover_t := 0.0
var hose_t := -1.0
var hose_a0 := 0.0
var hose_a1 := 0.0
var hose_dir := 1.0
var spray_t := 0.0
var shot_k := 0


func _init_kind() -> void:
	hp = 120.0
	radius = 2.0
	score = 2500
	energy_drop = 12.0
	blast = 3.0


func _build() -> void:
	side = -1.0 if float(p.get("side", -1)) < 0.0 else 1.0
	for s: float in [-1.0, 1.0]:
		var f := add_mesh("kestrel_fan")
		f.position = Vector3(s * FAN.x, 0.0, FAN.z)
		fans.append(f)
	gun = add_mesh("kestrel_gun")
	gun.position = GUN
	barrels = MeshInstance3D.new()
	barrels.mesh = Vox.get_mesh("kestrel_barrels")
	barrels.position = Vector3(0, 0.12, 0.35)
	gun.add_child(barrels)
	hose_dir = side
	# in from the side edge, level, then curving down into the hover
	from = Vector3(side * (game.hw_top + 4.0), 0, game.field_top + 2.0)
	to = Vector3(float(p.get("hx", 0.0)), 0, float(p.get("hold", game.field_top + 5.5)))
	bend = Vector3(to.x + side * 7.0, 0, from.z)
	position = from


func _bezier(f: float) -> Vector3:
	return from.lerp(bend, f).lerp(bend.lerp(to, f), f)


func _behave(dt: float) -> void:
	var stay: float = p.get("stay", 12.0)
	for f in fans:
		f.rotation.y += dt * 22.0
	leg_t += dt
	match leg:
		0:
			# the curve in, slowing into the hover, nose along the way
			var f := clampf(leg_t / T_IN, 0.0, 1.0)
			var e := 1.0 - (1.0 - f) * (1.0 - f)
			var prev := position
			position = _bezier(e)
			var v := (position - prev) / maxf(dt, 0.001)
			if v.length_squared() > 1.0:
				rotation.y = lerp_angle(rotation.y, atan2(v.x, v.z), clampf(8.0 * dt, 0.0, 1.0))
			rotation.z = -side * 0.35 * (1.0 - f)
			if f >= 1.0:
				leg = 1
				leg_t = 0.0
				fire_t = 0.7
		1:
			# hover: turn to the ship, a slow bob from where it stopped
			hover_t += dt
			position = to + Vector3(sin(hover_t * 0.6) * 0.9, 0, sin(hover_t * 1.1) * 0.35)
			var d := game.player.position - position
			rotation.y = lerp_angle(rotation.y, clampf(atan2(d.x, d.z), -0.5, 0.5), clampf(2.5 * dt, 0.0, 1.0))
			rotation.z = lerpf(rotation.z, 0.0, clampf(3.0 * dt, 0.0, 1.0))
			_attack(dt)
			if t >= stay and hose_t < 0.0:
				leg = 2
				leg_t = 0.0
				from = position
				to = Vector3(-side * (game.hw_top + 6.0), 0, game.field_top - 5.0)
				bend = Vector3(position.x, 0, game.field_top - 1.0)
		2:
			# away up the screen to the other side, picking up speed
			var f := clampf(leg_t / T_OUT, 0.0, 1.0)
			var prev := position
			position = _bezier(f * f)
			var v := (position - prev) / maxf(dt, 0.001)
			if v.length_squared() > 1.0:
				rotation.y = lerp_angle(rotation.y, atan2(v.x, v.z), clampf(4.0 * dt, 0.0, 1.0))
			rotation.z = lerpf(rotation.z, side * 0.35, clampf(2.0 * dt, 0.0, 1.0))
	gun.rotation.y = lerp_angle(gun.rotation.y, _local(gun_a), clampf(10.0 * dt, 0.0, 1.0))
	# the rotary cannon's barrels spin up for the hose
	barrels.rotation.z += dt * (30.0 if hose_t >= 0.0 or (leg == 1 and step % 5 == 1) else 4.0)


## The gun's turn (relative to the hull) to point along angle `a`.
func _local(a: float) -> float:
	return atan2(cos(a), sin(a)) - rotation.y


func _muzzle() -> Vector3:
	return position + GUN.rotated(Vector3.UP, rotation.y) + Vector3(cos(gun_a), 0, sin(gun_a)) * 1.0


func _attack(dt: float) -> void:
	if hose_t >= 0.0:
		# the hose: one long arc of shells, big and small by turns
		hose_t += dt
		var f := clampf(hose_t / HOSE_T, 0.0, 1.0)
		gun_a = lerpf(hose_a0, hose_a1, f)
		spray_t -= dt
		if spray_t <= 0.0 and game.can_fire(position):
			spray_t = HOSE_EVERY
			shot_k += 1
			game.bullets.fire(_muzzle(), gun_a, HOSE_SPEED, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if shot_k % 2 == 0 else Bullets.SMALL)
		if f >= 1.0:
			hose_t = -1.0
			fire_t = 0.7
		return
	fire_t -= dt
	if fire_t > 0.0 or not game.can_fire(position):
		return
	var aim := game.bullets.aim(position + GUN)
	match step % 5:
		0:
			# spin up, turned to where the arc starts
			hose_a0 = aim - hose_dir * deg_to_rad(HOSE_ARC)
			hose_a1 = aim + hose_dir * deg_to_rad(HOSE_ARC)
			gun_a = hose_a0
			fire_t = 0.5
		1:
			hose_t = 0.0
			spray_t = 0.0
			hose_dir = -hose_dir
		2:
			gun_a = aim
			game.warn(self, WINDUP_SHOT + 0.15, Game.Warn.SHOT, radius)
			fire_t = WINDUP_SHOT + 0.15
		3:
			_needles()
			fire_t = 0.3
		4:
			_needles()
			fire_t = 2.2  # quiet gap: come in with the Spear
	step += 1


## A 3-way burst of unbreakable needles at the ship from each fan pod.
func _needles() -> void:
	for s: float in [-1.0, 1.0]:
		var at := position + Vector3(s * POD.x, 0, POD.z).rotated(Vector3.UP, rotation.y)
		game.bullets.fan(at, game.bullets.aim(at), 3, 12.0, 9.5, Bullets.ORB, self, Bullets.NEEDLE)
