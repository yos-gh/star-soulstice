extends Enemy
## Saucer: comes in level from a side edge to the top of a big loop, goes
## round it (its inner edge runs down the centre line) and leaves straight
## out of the loop; one aimed energy orb on the way down the centre.
## params: x, z (start, off the edge), c (loop centre), r, w (rad/s, + =
## clockwise on screen), loops

const INFO := {
	"name": "SWIRL", "category": "small",
	"desc": "円盤：横の縁から入り、画面半分を使う大きなループ（内側は中央線を通る）を描いて、その側の上へ抜ける。狙いのエネルギー弾を 1 発（予兆あり）",
	"demos": [
		["LOOP LEFT", "swirls", [0.0, -1, 5, 0.25]],
		["LOOP BOTH", "swirls", [0.0, -1, 5, 0.25], "swirls", [1.2, 1, 5, 0.25]],
	],
}

var x0 := 0.0


func _init_kind() -> void:
	hp = 2.0
	radius = 0.9
	score = 200
	energy_drop = 3.0


func _behave(dt: float) -> void:
	var c: Vector3 = p["c"]
	var r: float = p["r"]
	var w: float = p["w"]
	var spd := r * absf(w)
	if t <= dt * 1.5:
		x0 = position.x
	# in level to the top of the loop, then round it from there
	var t_in := absf(c.x - x0) / spd
	var a0 := -PI / 2.0
	var dur: float = float(p.get("loops", 1.75)) * TAU / absf(w)
	if t < t_in:
		vel = Vector3(signf(c.x - x0) * spd, 0, 0)
		position = Vector3(x0 + vel.x * t, 0, c.z - r)
	elif t < t_in + dur:
		var a := a0 + w * (t - t_in)
		position = c + Vector3(cos(a), 0, sin(a)) * r
		vel = Vector3(-sin(a), 0, cos(a)) * r * w
	else:
		position += vel * dt
	model.rotation.y += dt * 5.0
	model.rotation.z = sin(t * 3.0) * 0.2
	# fires going down the centre line (a quarter of the way round)
	if not fired and t >= t_in + PI / 2.0 / absf(w) - WINDUP_SHOT and game.can_fire(position):
		fired = true
		game.warn_then(self, WINDUP_SHOT, Game.Warn.SHOT, func() -> void:
			game.bullets.fire(position, game.bullets.aim(position), 6.5, Bullets.ORB, self))
