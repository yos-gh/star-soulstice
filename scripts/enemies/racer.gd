extends Enemy
## Lap racer, after the GG Aleste 2 squadrons: a fast train in from a
## corner, round the edges of the screen once or twice (the last lap
## spiralling in), then out snaking across it; every other one fires an
## aimed shell from the top edge each lap. The path is a Curve2D on the
## play plane built by Formations.racers and shared by the train; each
## member flies it `i * gap` behind the leader.
## params: curve, i, gap, fire (path distances where it fires)

const INFO := {
	"name": "RACER", "category": "small",
	"desc": "周回機（GG アレスタ 2 の編隊から）：画面の隅から高速で入り、縁を 1〜2 周して内側へ回り込み、蛇行しながら抜ける。周回ごとに上の縁から狙いの物理弾",
	"demos": [
		["1 LAP FROM TOP LEFT", "racers", [0.0, "tl", 1, 8]],
		["2 LAPS FROM BOTTOM RIGHT", "racers", [0.0, "br", 2, 8]],
		["ALONG THE TOP FROM TOP RIGHT", "racers", [0.0, "tr", 1, 8, true]],
	],
}

const SPEED := 27.0

var s := 0.0
var last := 0.0
var head := 0.0


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
	position = _at(c, s)
	var d := _at(c, s + 0.5) - position
	if d.length_squared() > 0.0001:
		var h := atan2(-d.x, -d.z)
		if t <= dt * 1.5:
			head = h
		# bank with the turn
		var turn := wrapf(h - head, -PI, PI) / maxf(dt, 0.001)
		head = h
		rotation.y = h
		model.rotation.z = lerpf(model.rotation.z, clampf(-turn * 0.08, -0.9, 0.9), 8.0 * dt)
	vel = d.normalized() * SPEED
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
