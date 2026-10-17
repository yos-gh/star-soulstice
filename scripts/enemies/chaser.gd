extends Enemy
## Strikes from behind. A train waits below the screen while a lock-on on
## the bottom edge marks its lane (the ship's column), then charges straight
## up it, brakes ahead of the ship, turns to face it, fires one aimed shell
## and leaves upward. The rear shot meets it on the way in; after it has
## passed it hangs right in front of the guns.
## params: i (place in the train, 0 = the leader, who sets the lane and
## shows the warning), group (shared by the train), gap

const INFO := {
	"name": "CHASER", "category": "small",
	"desc": "後方強襲機：画面の下に予兆を出し、自機の列を後ろから突き上げる。前に出て止まり、振り向いて狙いの物理弾を 1 発",
	"demos": [
		["TRAIN OF 3", "chasers", [0.0, 3]],
		["TWO TRAINS", "chasers", [0.0, 3], "chasers", [1.8, 3]],
	],
}

const WAIT := 0.7  # telegraph before the charge (from behind: a little longer)
const SPEED := 24.0
const BRAKE := 60.0

var lane := 0.0
var stop_z := 0.0


func _init_kind() -> void:
	hp = 1.0
	radius = 0.8
	score = 200
	energy_drop = 2.0


func _behave(dt: float) -> void:
	var i: int = p.get("i", 0)
	if t <= dt * 1.5:
		var grp: Dictionary = p.get("group", {})
		if i == 0 or not grp.has("x"):
			var px: float = game.player.position.x if game.player.alive else 0.0
			grp["x"] = clampf(px, -game.hw_bottom + 1.5, game.hw_bottom - 1.5)
		lane = grp["x"]
		position = Vector3(lane, 0, game.field_bottom + 2.0 + i * float(p.get("gap", 1.8)))
		stop_z = game.field_top + 9.0 + i * 1.9
		if i == 0:
			game.warn(self, WAIT, Game.Warn.MOVE, radius, Vector3(lane, 0, game.field_bottom - 9.0))
	if t < WAIT:
		return
	var look := game.player.position - position
	match step:
		0:
			# straight up the lane, no steering: step aside and it misses
			vel = Vector3(0, 0, -SPEED)
			if position.z <= stop_z + SPEED * SPEED / (2.0 * BRAKE):
				step = 1
		1:
			# brake ahead of the ship and turn round to face it
			vel = vel.move_toward(Vector3.ZERO, BRAKE * dt)
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), 12.0 * dt)
			if vel.length() < 0.3:
				step = 2
				fire_t = 0.25
		2:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), 12.0 * dt)
			fire_t -= dt
			if fire_t <= 0.0:
				if not fired and game.can_fire(position):
					fired = true
					game.bullets.fire(position, game.bullets.aim(position), 8.0, Bullets.SHELL, self, Bullets.NEEDLE)
				step = 3
				fire_t = 0.3
		_:
			# away upward
			fire_t -= dt
			if fire_t <= 0.0:
				vel = vel.move_toward(Vector3(0, 0, -18.0), 36.0 * dt)
				rotation.y = lerp_angle(rotation.y, 0.0, 8.0 * dt)
	position += vel * dt
	model.rotation.z = sin(t * 9.0) * 0.12 if step == 0 else lerpf(model.rotation.z, 0.0, 6.0 * dt)
