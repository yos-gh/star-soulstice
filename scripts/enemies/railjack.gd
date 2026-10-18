extends Enemy
## Mid-size rail carriage (stage 2's tunnel): rolls down the rail along the
## top of one tunnel wall, holds beside the top of the screen and rakes the
## tunnel with broadside shell fans, across and down (a big volley, then a
## small one just under it; the second rake steeper), then a telegraphed
## aimed burst of unbreakable needles, twice. A quiet gap follows every
## round: come in under it with the Spear. When its time is up it backs
## away up the rail.
## params: side (-1 = the left wall), hold (z it holds at), stay (seconds)

const INFO := {
	"name": "RAILJACK", "category": "medium",
	"desc": "中型機：トンネルの壁の上のレールを下りてきて画面上の脇に留まり、物理弾の扇で横から斜め下を掃く（大きい弾の扇が先、2 回目は角度を下げる）。予兆のあと狙いの針弾を 2 連。合間に静かな間。時間が来るとレールを後ずさりして去る",
	"demos": [
		["RIGHT WALL", "railjack", [0.0, 1]],
		["BOTH WALLS", "railjack", [0.0, -1], "railjack", [1.2, 1]],
	],
}

const GUN_Y := 0.45

var side := -1.0
var arrived := false
var sway_t := 0.0
var gun: MeshInstance3D
var gun_want := 0.0  # where the gun turns to (0 = +x, PI/2 = down-screen)


func _init_kind() -> void:
	hp = 100.0
	radius = 2.0
	score = 2500
	energy_drop = 12.0
	blast = 3.0


func _build() -> void:
	side = -1.0 if float(p.get("side", -1)) < 0.0 else 1.0
	face(Vector3(-side, 0, 0))
	gun = add_mesh("railjack_gun")
	gun.position.y = GUN_Y
	gun_want = _inward(30.0)
	gun.rotation.y = _local(gun_want)


## The angle `deg` below straight across the tunnel, from this wall.
func _inward(deg: float) -> float:
	var a := deg_to_rad(deg)
	return a if side < 0.0 else PI - a


## The gun's turn (relative to the carriage) to point along angle `a`.
func _local(a: float) -> float:
	return atan2(-cos(a), -sin(a)) - rotation.y


func _behave(dt: float) -> void:
	var stay: float = p.get("stay", 12.0)
	var hold: float = p.get("hold", game.field_top + 5.5)
	position.x = side * (game.field_hw - 2.4)
	gun.rotation.y = lerp_angle(gun.rotation.y, _local(gun_want), clampf(6.0 * dt, 0.0, 1.0))
	if t >= stay:
		# back away up the rail
		vel.z = move_toward(vel.z, -9.0, 6.0 * dt)
		position.z += vel.z * dt
		return
	if not arrived:
		# roll down, easing in to the hold line
		position.z += clampf((hold - position.z) * 2.2, 1.2, 8.0) * dt
		fire_t = 0.8
		if position.z >= hold - 0.05:
			arrived = true
		return
	# sway a little along the rail
	sway_t += dt
	position.z = hold + sin(sway_t * 0.5) * 0.8
	fire_t -= dt
	if fire_t > 0.0 or not game.can_fire(position):
		return
	var muzzle := position + Vector3(-side * 1.2, 0, 0.1)
	var aim := game.bullets.aim(muzzle)
	match step % 7:
		0:
			gun_want = _inward(30.0)
			game.bullets.fan(muzzle, _inward(30.0), 7, 56.0, 5.0, Bullets.SHELL, self, Bullets.ROUND, Bullets.BIG)
			fire_t = 0.3
		1:
			game.bullets.fan(muzzle, _inward(36.0), 6, 50.0, 5.6, Bullets.SHELL, self, Bullets.ROUND, Bullets.SMALL)
			fire_t = 0.9
		2:
			gun_want = _inward(52.0)
			game.bullets.fan(muzzle, _inward(52.0), 7, 56.0, 5.0, Bullets.SHELL, self, Bullets.ROUND, Bullets.BIG)
			fire_t = 0.3
		3:
			game.bullets.fan(muzzle, _inward(58.0), 6, 50.0, 5.6, Bullets.SHELL, self, Bullets.ROUND, Bullets.SMALL)
			fire_t = 1.0
		4:
			# announce the needles
			gun_want = aim
			game.warn(self, WINDUP_SHOT + 0.15, Game.Warn.SHOT, radius)
			fire_t = WINDUP_SHOT + 0.15
		5:
			gun_want = aim
			game.bullets.fan(muzzle, aim, 3, 12.0, 9.5, Bullets.ORB, self, Bullets.NEEDLE)
			fire_t = 0.3
		6:
			gun_want = aim
			game.bullets.fan(muzzle, aim, 3, 12.0, 9.5, Bullets.ORB, self, Bullets.NEEDLE)
			fire_t = 2.6  # quiet gap: come in with the Spear
	step += 1
