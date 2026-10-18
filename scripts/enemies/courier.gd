extends Enemy
## Energy courier, launched in pairs by the bosses just before their weak
## point opens: a drone with a glowing energy canister that swings down
## round the middle of the screen and away up the other side. It never
## attacks; shot down, it spills enough energy for two homing lasers, so
## catching both feeds a full Spear + homing salvo into the open core.
## params: p0, p1, p2 (a curve on the plane: from the hatch, round the
## middle, away off the top)

const INFO := {
	"name": "COURIER", "category": "small",
	"desc": "エネルギー運び屋（ボスが弱点の開く前に 2 機ずつ出す）：画面の真ん中あたりを回って反対側の上へ抜ける。攻撃しない。撃ち落とすとホーミング 2 発ぶんのエネルギーがこぼれる",
	"demos": [["PAIR", "couriers", [0.0]]],
}

const SPEED := 9.0

var u := 0.0


func _init_kind() -> void:
	hp = 4.0
	radius = 0.9
	score = 500
	energy_drop = 40.0
	blast = 1.2
	ram = false
	debris_col = Models.GOLD


func _behave(dt: float) -> void:
	var a: Vector3 = p["p0"]
	var b: Vector3 = p["p1"]
	var c: Vector3 = p["p2"]
	var was := position
	if u < 1.0:
		# along the curve at about SPEED
		var d := ((b - a) * (1.0 - u) + (c - b) * u) * 2.0
		u = minf(1.0, u + SPEED * dt / maxf(d.length(), 0.1))
		position = a.lerp(b, u).lerp(b.lerp(c, u), u)
	else:
		# then straight on
		position += (c - b).normalized() * SPEED * dt
	vel = (position - was) / maxf(dt, 0.001)
	face(vel)
	model.rotation.z = sin(t * 4.0) * 0.15
