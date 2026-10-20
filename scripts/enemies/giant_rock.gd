extends Enemy
## Giant asteroid drifting through the belt (stage 3): a wall on the play
## plane. It stops every enemy bullet that flies into it (cover to hide
## behind), shoves the ship aside instead of wrecking it (Game._solids,
## Player.push_out: never crushed against an edge) and soaks the ship's
## shots: it takes a while, but it can be broken for a big reward. Homing
## lasers leave it alone.
## params: x, z (default: just above the screen), vx, vz, spin, big

const INFO := {
	"name": "GIANT ROCK", "category": "hazard", "stage": 3,
	"desc": "巨大な岩：ゆっくり流れてくる壁。敵弾をすべて止める（盾になる）。自機はぶつかっても壊れず押しのけられる（画面の端に挟まれても潰されない）。ショットを吸い、硬いが壊せる（ホーミングは狙わない）",
	"demos": [
		["DRIFT", "one", [0.0, "giant_rock", -0.25, {"vx": 0.4, "vz": 4.5, "spin": 0.15}]],
		["BIG", "one", [0.0, "giant_rock", 0.2, {"vx": -0.3, "vz": 4.0, "spin": -0.12, "big": true}]],
	],
}


func _init_kind() -> void:
	var big: bool = p.get("big", false)
	hp = 450.0 if big else 300.0
	radius = 3.8 if big else 3.0
	score = 5000 if big else 3000
	energy_drop = 24.0 if big else 16.0
	blast = 4.2 if big else 3.4
	counts = false
	ram = false
	solid = true
	lock = false
	leaves = false
	mesh_name = "giant_rock_b" if big else "giant_rock_a"


func _behave(dt: float) -> void:
	if t <= dt * 1.5:
		vel = Vector3(p.get("vx", 0.0), 0, p.get("vz", 4.0))
		if not p.has("z"):
			position.z = game.field_top - radius - 1.0
		model.rotation.y = float(p.get("turn", 0.0))
	position += vel * dt
	model.rotation.y += dt * float(p.get("spin", 0.1))
	# a soft flicker under fire, not a full flash: it soaks shots for a
	# long while, and kept white it no longer looked like rock
	flash = minf(flash, 0.3)
	# gone once wholly off the screen (it is too big for the usual margin)
	if position.z > game.field_bottom + radius + 1.0 or absf(position.x) > game.hw_bottom + radius + 2.0 or (not entered and t > 14.0):
		game.remove_enemy(self)
