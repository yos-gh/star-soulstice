extends Enemy
## Strikes from behind. A lock-on on the bottom edge marks where a train
## will come up; it rises slowly beside the ship's column (the rear shot
## meets it there), stops, turns and fires one aimed unbreakable needle
## (announced) up at the ship,
## then breaks away fast, easing round onto a diagonal away from the ship.
## params: i (place in the train, 0 = the leader, who sets the lane and
## shows the warning), group (shared by the train), gap, side (+1 / -1 =
## the ship's right / left, 0 = toward the centre)

const INFO := {
	"name": "CHASER", "category": "small",
	"desc": "後方強襲機：画面の下に予兆を出し、自機の列の横を後ろからゆっくり上がってくる。止まって狙いのエネルギー弾を 1 発（予兆あり）、ゆるく曲がって斜め上へ高速で抜ける",
	"demos": [
		["TRAIN OF 3", "chasers", [0.0, 3]],
		["BOTH SIDES", "chasers", [0.0, 3, -1], "chasers", [1.4, 3, 1]],
	],
}

const WAIT := 0.5  # telegraph before it shows
const OFFSET := 3.2  # from the ship's column
const RISE := 6.0
const ESCAPE := 26.0

var lane := 0.0
var stop_z := 0.0
var away := 1.0  # escape side
var heading := Vector3(0, 0, -1)


func _init_kind() -> void:
	hp = 1.0
	radius = 0.8
	score = 200
	energy_drop = 2.0


func _behave(dt: float) -> void:
	var i: int = p.get("i", 0)
	var pl := game.player
	if t <= dt * 1.5:
		var grp: Dictionary = p.get("group", {})
		if i == 0 or not grp.has("x"):
			var px: float = pl.position.x if pl.alive else 0.0
			var side := float(p.get("side", 0))
			if side == 0.0:
				side = -signf(px) if absf(px) > 1.0 else 1.0
			var lim := game.hw_bottom - 1.5
			var x := px + side * OFFSET
			if absf(x) > lim:
				x = px - side * OFFSET  # no room on that side: the other one
			grp["x"] = clampf(x, -lim, lim)
		lane = grp["x"]
		position = Vector3(lane, 0, game.field_bottom + 1.6 + i * float(p.get("gap", 1.8)))
		stop_z = game.field_bottom - 5.0 + i * float(p.get("gap", 1.8))
		if i == 0:
			game.warn(self, WAIT, Game.Warn.MOVE, radius, Vector3(lane, 0, stop_z))
	if t < WAIT:
		return
	var look := pl.position - position
	match step:
		0:
			# up slowly, easing to a stop beside the ship
			var d := position.z - stop_z
			vel = Vector3(0, 0, -minf(RISE, sqrt(maxf(0.0, 2.0 * 10.0 * d)) + 0.3))
			if d <= 0.05:
				vel = Vector3.ZERO
				step = 1
				# one unbreakable needle, announced (the train one after another)
				fire_t = WINDUP_SHOT + i * 0.15
				if game.combat_on() and pl.alive and game.on_field(position, -0.8):
					game.warn_then(self, fire_t, Game.Warn.SHOT, func() -> void:
						if game.combat_on() and pl.alive and game.on_field(position, -0.8) and (pl.position - position).length() > 3.0:
							game.bullets.fire(position, game.bullets.aim(position), 7.0, Bullets.ORB, self, Bullets.NEEDLE))
		1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), 10.0 * dt)
			fire_t -= dt
			if fire_t <= -0.05:
				step = 2
				away = signf(lane - pl.position.x) if absf(lane - pl.position.x) > 0.1 else signf(lane + 0.001)
				heading = Vector3(0, 0, -1)
				vel = heading * 6.0
		_:
			# break away: speed up while the heading eases round to a
			# diagonal, up and away from the ship
			var want := Vector3(away * 0.8, 0, -1.0).normalized()
			heading = heading.slerp(want, clampf(1.4 * dt, 0.0, 1.0)).normalized()
			vel = heading * minf(ESCAPE, vel.length() + 60.0 * dt)
			face(heading)
	position += vel * dt
	if step == 0:
		rotation.y = lerp_angle(rotation.y, 0.0, 8.0 * dt)
	model.rotation.z = lerpf(model.rotation.z, away * 0.6 if step >= 2 else 0.0, 6.0 * dt)
