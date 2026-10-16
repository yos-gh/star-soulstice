extends Enemy
## Formation fighter: fast fly-in along a curve, one aimed shell.
## params: x, z, vx, vz, turn_t, turn (rad/s, + = clockwise on screen),
## turn_dur, fire_at

const INFO := {
	"name": "DART", "category": "small",
	"desc": "編隊機：曲線を描いて高速で入ってきて、狙いの物理弾を 1 発",
	"demos": [
		["COLUMN", "col", [0.0, -0.45, 6, 0.2, 1]],
		["V", "vform", [0.0, 0.0]],
		["SWEEP", "sweep", [0.0, -1, 6, 0.22]],
	],
}


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
	if not fired and t >= float(p.get("fire_at", 0.7)) and game.can_fire(position):
		fired = true
		game.bullets.fire(position, game.bullets.aim(position), 8.0, Bullets.SHELL, self, Bullets.NEEDLE)
