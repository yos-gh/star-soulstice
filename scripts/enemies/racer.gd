extends Enemy
## Lap racer, after the GG Aleste 2 squadrons: a fast train of small
## saucers in from a corner straight along a side, round a loop that fills
## the screen (closing round the ship), then away on a wide sine wave;
## every other one fires an aimed shell from the top of the loop each lap.
## The path is a Curve2D on the play plane built by Formations.racers and
## shared by the train; each member flies it `i * gap` behind the leader.
## params: curve, i, gap, fire (path distances where it fires)

const INFO := {
	"name": "RACER", "category": "small",
	"desc": "周回円盤（GG アレスタ 2 の編隊から）：画面の隅から縁沿いにまっすぐ入り、画面いっぱいのループで自機を囲んで 1〜2 周、振幅の大きいサインカーブで抜ける。周回ごとにループの上から狙いの物理弾",
	"demos": [
		["1 LAP FROM TOP LEFT", "racers", [0.0, "tl", 1, 8]],
		["2 LAPS FROM TOP RIGHT", "racers", [0.0, "tr", 2, 8]],
		["FROM BOTTOM LEFT", "racers", [0.0, "bl", 1, 8]],
		["ALONG THE TOP FROM TOP LEFT", "racers", [0.0, "tl", 1, 8, true]],
	],
}

const SPEED := 26.0

var s := 0.0
var last := 0.0


func _init_kind() -> void:
	hp = 1.0
	radius = 0.75
	score = 150
	energy_drop = 2.0


func _behave(dt: float) -> void:
	var c: Curve2D = p["curve"]
	if t <= dt * 1.5:
		s = -int(p.get("i", 0)) * float(p.get("gap", 2.2))
	last = s
	s += SPEED * dt
	var was := position
	position = _at(c, s)
	vel = (position - was) / maxf(dt, 0.001)
	model.rotation.y += dt * 6.0
	model.rotation.z = sin(t * 3.0) * 0.2
	if int(p.get("i", 0)) % 2 == 0:
		for f: float in p.get("fire", []):
			if last < f and s >= f and game.can_fire(position):
				game.bullets.fire(position, game.bullets.aim(position), 7.0, Bullets.SHELL, self, Bullets.NEEDLE)


## The point `s` along the path, carried on straight before it and after it.
func _at(c: Curve2D, at: float) -> Vector3:
	var n := c.point_count
	var q: Vector2
	if at < 0.0:
		var d := (c.get_point_position(1) - c.get_point_position(0)).normalized()
		q = c.get_point_position(0) + d * at
	else:
		var l := c.get_baked_length()
		if at > l:
			var d := (c.get_point_position(n - 1) - c.get_point_position(n - 2)).normalized()
			q = c.get_point_position(n - 1) + d * (at - l)
		else:
			q = c.sample_baked(at, true)
	return Vector3(q.x, 0, q.y)
