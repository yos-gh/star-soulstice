extends Enemy
## Saucer: dives in beside the centre line, makes one big loop out to its
## side and leaves that way across the middle; one aimed energy orb.
## params: x (dive line), zl (where the loop starts), r, w (rad/s, + =
## clockwise on screen: loops to the left), loops

const INFO := {
	"name": "SWIRL", "category": "small",
	"desc": "円盤：中央寄りに降りてきて大きく 1 回ループし、横へ抜ける。狙いのエネルギー弾を 1 発（予兆あり）",
	"demos": [
		["LOOP LEFT", "swirls", [0.0, -1, 5, 0.25]],
		["LOOP BOTH", "swirls", [0.0, -1, 5, 0.25], "swirls", [1.2, 1, 5, 0.25]],
	],
}

var z0 := 0.0
var c := Vector3.ZERO


func _init_kind() -> void:
	hp = 2.0
	radius = 0.9
	score = 200
	energy_drop = 3.0


func _behave(dt: float) -> void:
	var r: float = p["r"]
	var w: float = p["w"]
	var spd := r * absf(w)
	var zl: float = p["zl"]
	if t <= dt * 1.5:
		z0 = position.z
		# the loop starts on its inner side, heading down
		c = Vector3(position.x - signf(w) * r, 0, zl)
	var t_dive := maxf(0.0, (zl - z0) / spd)
	var a0 := 0.0 if w > 0.0 else PI
	var dur: float = float(p.get("loops", 1.25)) * TAU / absf(w)
	if t < t_dive:
		vel = Vector3(0, 0, spd)
		position.z = z0 + spd * t
	elif t < t_dive + dur:
		var a := a0 + w * (t - t_dive)
		position = c + Vector3(cos(a), 0, sin(a)) * r
		vel = Vector3(-sin(a), 0, cos(a)) * r * w
	else:
		position += vel * dt
	model.rotation.y += dt * 5.0
	model.rotation.z = sin(t * 3.0) * 0.2
	# fires at the bottom of the loop's first half, near the middle
	if not fired and t >= t_dive + PI / 2.0 / absf(w) - WINDUP_SHOT and game.can_fire(position):
		fired = true
		game.warn_then(self, WINDUP_SHOT, Game.Warn.SHOT, func() -> void:
			game.bullets.fire(position, game.bullets.aim(position), 6.5, Bullets.ORB, self))
