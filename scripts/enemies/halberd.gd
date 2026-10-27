extends Enemy
## Heavy mid-size gunship of the planet's last defences (stage 5), bigger
## and tougher than the others: bare machinery round a long keel that is a
## rail gun (two rails the length of the hull), two engine blocks with a
## gun turret on each, oxblood armour on the nose and the engines. It comes
## down from the top slowly, holds near the top and drifts after the ship
## (slowly: it is heavy), then climbs away when its time is up.
## Its signature is the rail shot: the hull turns to the ship, the line
## from its nose through the ship to the bottom edge is marked while it
## charges (sparks run down the rails), then three iron slugs go down it
## fast (they can't be shot and they stop shots: get off the line). The
## turrets fire needle fans in turn (announced) and the belly a wide shell
## curtain, big then small.
## params: x, hold (z it holds at), stay (seconds)

const INFO := {
	"name": "HALBERD", "category": "medium",
	"desc": "大型の中型機（ステージ 5）：これまでの中型機より大きく硬い。剥き出しの機械の長い竜骨がそのままレールガン（船体の長さの 2 本のレール）、左右のエンジンに砲塔、機首とエンジンに暗赤の装甲。上からゆっくり降りて上のほうにとどまり、自機を追って横へゆっくり動き、時間が来ると上へ去る。大技はレール射撃：船体が自機へ向き、機首から自機を通って下端までの線を予兆（充電中はレールを火花が走る）、そのあと鉄球弾（撃ち落とせず、ショットを遮る）を 3 発、線に沿って速く撃つ（線から外れる）。砲塔から交互に針弾の扇（予兆あり）、腹から物理弾の幕（大、続いて小）",
	"demos": [
		["ONE", "halberd", [0.0, 0.0]],
		["PAIR", "halberd", [0.0, -0.5], "halberd", [1.2, 0.5]],
	],
}

const TURRET := Vector3(2.65, 0, -0.4)  # the engine turrets (and their mirror)
const NOSE := Vector3(0, 0, 3.9)  # the rail gun's muzzle
const DESCENT := 2.2  # seconds down into the hold
const DRIFT := 2.6  # top speed across, after the ship
const CHARGE_T := 1.1  # the rail shot: marked this long, then
const SLUGS := 3
const SLUG_GAP := 0.14
const SLUG_SPEED := 17.0

var turrets: Array[MeshInstance3D] = []
var hold_z := 0.0
var leg := 0  # 0 down, 1 holding, 2 away
var leg_t := 0.0
var aim_a := PI / 2.0  # the hull's heading (PI/2 = down-screen)
var rail_to := Vector3.ZERO
var slug_k := 0
var slug_t := 0.0
var turret_k := 0


func _init_kind() -> void:
	hp = 260.0
	radius = 2.8
	score = 6000
	energy_drop = 20.0
	blast = 3.6
	marked = true  # the autopilot keeps off its marked rail line


func _build() -> void:
	for s: float in [-1.0, 1.0]:
		var m := add_mesh("halberd_turret")
		m.position = Vector3(s * TURRET.x, 0.85, TURRET.z)
		turrets.append(m)
	hold_z = float(p.get("hold", game.field_top + 6.0))
	position = Vector3(float(p.get("x", 0.0)), 0, game.field_top - 4.5)
	fire_t = 0.6


func _behave(dt: float) -> void:
	var stay: float = p.get("stay", 14.0)
	leg_t += dt
	var pl := game.player
	match leg:
		0:
			# down into the hold, slowing
			var f := clampf(leg_t / DESCENT, 0.0, 1.0)
			position.z = lerpf(game.field_top - 4.5, hold_z, 1.0 - (1.0 - f) * (1.0 - f))
			if f >= 1.0:
				leg = 1
				leg_t = 0.0
		1:
			# drift after the ship (not while the rail gun is marked or firing)
			if step % 6 != 1 and slug_k == 0 and pl.alive:
				var want := clampf(pl.position.x, -game.field_hw + 4.0, game.field_hw - 4.0)
				position.x = move_toward(position.x, want, DRIFT * dt)
			position.z = hold_z + sin(t * 0.9) * 0.3
			_attack(dt)
			if t >= stay and step % 6 != 1 and slug_k == 0:
				leg = 2
				leg_t = 0.0
		2:
			position.z -= (2.0 + leg_t * 8.0) * dt
	# the hull turns to the ship (held still while the line is marked)
	if step % 6 != 1 and slug_k == 0 and pl.alive and leg == 1:
		var d := pl.position - position
		aim_a = rotate_toward(aim_a, clampf(atan2(d.z, d.x), PI / 2.0 - 0.7, PI / 2.0 + 0.7), 1.4 * dt)
	rotation.y = atan2(cos(aim_a), sin(aim_a))
	for k in 2:
		var tp := position + _rot(Vector3((-1.0 if k == 0 else 1.0) * TURRET.x, 0, TURRET.z))
		var d := pl.position - tp
		turrets[k].rotation.y = lerp_angle(turrets[k].rotation.y, atan2(-d.x, -d.z) - rotation.y, clampf(6.0 * dt, 0.0, 1.0))
	model.rotation.z = lerpf(model.rotation.z, 0.0, clampf(3.0 * dt, 0.0, 1.0))


func _rot(v: Vector3) -> Vector3:
	return v.rotated(Vector3.UP, rotation.y)


func _attack(dt: float) -> void:
	if slug_k > 0:
		# the slugs, one after another down the marked line
		slug_t -= dt
		if slug_t <= 0.0:
			slug_t = SLUG_GAP
			var muzzle := position + _rot(NOSE)
			if game.combat_on():
				game.bullets.fire(muzzle, atan2(rail_to.z - muzzle.z, rail_to.x - muzzle.x), SLUG_SPEED, Bullets.IRON, self)
				game.fx.flash(muzzle, 0.5)
				game.sfx.play("exp_s")
			slug_k -= 1
			if slug_k == 0:
				fire_t = 0.8
		return
	if step % 6 == 1:
		# charging: sparks run down the rails
		if randf() < 0.5:
			var f := randf()
			game.fx.sprite(position + _rot(Vector3(randf_range(-0.4, 0.4), 0.6, lerpf(-3.0, 3.6, f))), Vector3.ZERO, 0.45, 0.1, 0.12, Color(1.0, 0.6, 0.85), 0.0)
	fire_t -= dt
	if fire_t > 0.0 or not game.can_fire(position):
		return
	match step % 6:
		0:
			# the rail shot: turned to the ship, the line marked
			var muzzle := position + _rot(NOSE)
			rail_to = game.line_to_bottom(muzzle, game.player.position)
			aim_a = atan2(rail_to.z - position.z, rail_to.x - position.x)
			game.warn(self, CHARGE_T, Game.Warn.MOVE, radius, rail_to)
			game.sfx.play("slam")
			fire_t = CHARGE_T
		1:
			slug_k = SLUGS
			slug_t = 0.0
			fire_t = 0.6
		2, 3:
			# a turret's needle fan (left, then right), announced
			var k := turret_k % 2
			turret_k += 1
			var at := position + _rot(Vector3((-1.0 if k == 0 else 1.0) * TURRET.x, 0, TURRET.z))
			game.warn_then(self, WINDUP_SHOT + 0.1, Game.Warn.SHOT, func() -> void:
				var from := position + _rot(Vector3((-1.0 if k == 0 else 1.0) * TURRET.x, 0, TURRET.z))
				if game.can_fire(from):
					game.bullets.fan(from, game.bullets.aim(from), 5, 40.0, 8.5, Bullets.ORB, self, Bullets.NEEDLE))
			fire_t = 0.9 if step % 6 == 2 else 1.0
		4:
			_curtain(Bullets.BIG)
			fire_t = 0.25
		5:
			_curtain(Bullets.SMALL)
			fire_t = 1.6  # a quiet gap
	step += 1


## The belly's shell curtain at the ship: a wide fan (`size` BIG leads,
## SMALL follows offset).
func _curtain(size: float) -> void:
	var at := position + _rot(Vector3(0, 0, 1.6))
	var off := 0.0 if size == Bullets.BIG else deg_to_rad(4.5)
	game.bullets.fan(at, game.bullets.aim(at) + off, 11 if size == Bullets.BIG else 10, 96.0 if size == Bullets.BIG else 88.0, 5.0 if size == Bullets.BIG else 5.6, Bullets.SHELL, self, Bullets.ROUND, size)
