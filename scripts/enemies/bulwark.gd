extends Enemy
## Mid-size cruiser: slow, tough; shell walls + an energy shotgun, with
## quiet gaps so you can close in with the Spear.
## params: x, z, stay (seconds before it leaves)

const INFO := {
	"name": "BULWARK", "category": "medium",
	"desc": "中型機：物理弾の壁と予兆つきのエネルギー散弾。合間の静かな間にスピアで近づける",
	"demos": [
		["HOLD", "bulwark", [0.0, 0.0]],
		["PAIR", "bulwark", [0.0, -0.5], "bulwark", [1.5, 0.5]],
	],
}


func _init_kind() -> void:
	hp = 120.0
	radius = 2.1
	score = 3000
	energy_drop = 14.0
	blast = 3.0


func _behave(dt: float) -> void:
	var hold_z := game.field_top + 5.0
	var stay: float = p.get("stay", 11.0)
	if position.z < hold_z and t < stay:
		position.z = move_toward(position.z, hold_z, 7.0 * dt)
		fire_t = 0.8
	elif t < stay:
		position.x = float(p["x"]) + sin(t * 0.6) * 1.6
		fire_t -= dt
		if fire_t <= 0.0 and game.can_fire(position):
			var down := PI / 2.0
			match step % 5:
				0:
					game.bullets.fan(position + Vector3(0, 0, 1.2), down, 11, 110.0, 5.0, Bullets.SHELL, self, Bullets.ROUND, Bullets.BIG)
					fire_t = 0.4
				1:
					# the second volley small, between the big ones that lead
					game.bullets.fan(position + Vector3(0, 0, 1.2), down + deg_to_rad(5.5), 10, 99.0, 5.5, Bullets.SHELL, self, Bullets.ROUND, Bullets.SMALL)
					fire_t = 1.2
				2:
					# announce the energy shotguns
					game.warn(self, WINDUP_SHOT + 0.15, Game.Warn.SHOT, radius)
					fire_t = WINDUP_SHOT + 0.15
				3:
					game.bullets.fan(position + Vector3(0, 0, 1.5), game.bullets.aim(position), 5, 14.0, 9.0, Bullets.ORB, self, Bullets.NEEDLE)
					fire_t = 0.45
				4:
					game.bullets.fan(position + Vector3(0, 0, 1.5), game.bullets.aim(position), 4, 10.0, 10.0, Bullets.ORB, self)
					fire_t = 2.6  # quiet gap: come in with the Spear
			step += 1
	else:
		position.z += 2.6 * dt
	model.rotation.z = sin(t * 0.9) * 0.06
