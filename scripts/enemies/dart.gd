extends Enemy
## Formation fighter: fast fly-in along a curve, one aimed unbreakable
## needle (announced).
## params: x, z, vx, vz, turn_t, turn (rad/s, + = clockwise on screen),
## turn_dur, fire_at

const INFO := {
	"name": "DART", "category": "small",
	"desc": "編隊機：画面の外寄りから高速で入り、軌道の途中で画面の中央線を横切る。狙いのエネルギー弾を 1 発（予兆あり）",
	"demos": [
		["COLUMN", "col", [0.0, -0.75, 6, 0.2, 1]],
		["V", "vform", [0.0, -1]],
		["V CROSS", "vform", [0.0, -1], "vform", [0.8, 1]],
		["SWEEP", "sweep", [0.0, -1, 6, 0.22]],
	],
}

const REFIRE := 0.6  # between needles where the stage doubles the fire


func _init_kind() -> void:
	hp = 1.0
	radius = 0.75
	score = 100
	energy_drop = 2.0


func _behave(dt: float) -> void:
	if t <= dt * 1.5:
		vel = Vector3(p.get("vx", 0.0), 0, p.get("vz", 13.0))
	var tt: float = p.get("turn_t", 99.0)
	if t > tt and t < tt + float(p.get("turn_dur", 1.0)):
		vel = vel.rotated(Vector3.UP, -float(p.get("turn", 0.0)) * dt)
	position += vel * dt
	face(vel)
	model.rotation.z = lerpf(model.rotation.z, clampf(float(p.get("turn", 0.0)) * 0.25, -0.8, 0.8) if (t > tt and t < tt + float(p.get("turn_dur", 1.0))) else 0.0, 6.0 * dt)
	# an unbreakable needle, announced: the lock-on starts WINDUP_SHOT early
	# (where the stage doubles the fire, a second one follows REFIRE later)
	if step < game.zako_fire() and t >= maxf(float(p.get("fire_at", 0.7)) - WINDUP_SHOT, fire_t) and game.can_fire(position):
		step += 1
		fire_t = t + REFIRE
		game.warn_then(self, WINDUP_SHOT, Game.Warn.SHOT, func() -> void:
			if game.can_fire(position):
				game.bullets.fire(position, game.bullets.aim(position), 8.0, Bullets.ORB, self, Bullets.NEEDLE))
