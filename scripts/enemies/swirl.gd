extends Enemy
## Saucer looping in from the side, one aimed energy orb.
## params: c (Vector3), r, a0, w (rad/s), loops

const INFO := {
	"name": "SWIRL", "category": "small",
	"desc": "円盤：横から回り込み、狙いのエネルギー弾を 1 発（予兆あり）",
	"demos": [
		["LOOP LEFT", "swirls", [0.0, -1, 5, 0.25]],
		["LOOP BOTH", "swirls", [0.0, -1, 5, 0.25], "swirls", [1.2, 1, 5, 0.25]],
	],
}


func _init_kind() -> void:
	hp = 2.0
	radius = 0.9
	score = 200
	energy_drop = 3.0


func _behave(dt: float) -> void:
	var c: Vector3 = p["c"]
	var r: float = p["r"]
	var w: float = p["w"]
	var dur: float = float(p.get("loops", 1.25)) * TAU / absf(w)
	if t < dur:
		var a: float = float(p["a0"]) + w * t
		position = c + Vector3(cos(a), 0, sin(a)) * r
		vel = Vector3(-sin(a), 0, cos(a)) * r * w
	else:
		position += vel * dt
	model.rotation.y += dt * 5.0
	model.rotation.z = sin(t * 3.0) * 0.2
	if not fired and t >= dur * 0.45 - WINDUP_SHOT and game.can_fire(position):
		fired = true
		game.warn_then(self, WINDUP_SHOT, Game.Warn.SHOT, func() -> void:
			game.bullets.fire(position, game.bullets.aim(position), 6.5, Bullets.ORB, self))
