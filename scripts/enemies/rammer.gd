extends Enemy
## Star mine: dives in, stops and winds up facing the player (telegraphed),
## then charges with only a little steering.
## params: x

const INFO := {
	"name": "RAMMER", "category": "small",
	"desc": "突進機雷：降りてきて溜め（予兆あり）、自機へ突進する",
	"demos": [
		["ONE", "rammers", [0.0, [0.0], 0.2]],
		["PAIR", "rammers", [0.0, [-0.5, 0.5], 0.4]],
	],
}


func _init_kind() -> void:
	hp = 3.0
	radius = 0.85
	score = 300
	energy_drop = 3.0


func _behave(dt: float) -> void:
	# dive in, stop and wind up (facing the player), then charge
	if t < 0.8:
		vel = Vector3(0, 0, 9.0)
		face(vel)
	elif t < 0.8 + WINDUP_MOVE:
		if not fired:
			fired = true
			game.warn(self, WINDUP_MOVE, Game.Warn.MOVE, radius, "player")
		vel = vel.move_toward(Vector3.ZERO, 24.0 * dt)
		var look := game.player.position - position
		rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), 8.0 * dt)
		model.rotation.z += dt * 30.0 * (t - 0.8) / WINDUP_MOVE
	elif t < 0.8 + WINDUP_MOVE + 1.4:
		if step == 0:
			step = 1
			var to := game.player.position - position
			vel = (to.normalized() if to.length() > 0.5 else Vector3(0, 0, 1)) * 8.0
		# fast, with only a little steering: dodgeable once it commits
		var spd := minf(21.0, vel.length() + 30.0 * dt)
		var to2 := game.player.position - position
		if game.player.alive and to2.length() > 0.5:
			vel = vel.lerp(to2.normalized() * spd, clampf(0.8 * dt, 0.0, 1.0)).normalized() * spd
		else:
			vel = vel.normalized() * spd
		face(vel)
	else:
		face(vel)
	position += vel * dt
	model.rotation.z += dt * 9.0
