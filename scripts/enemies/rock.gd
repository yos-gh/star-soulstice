extends Enemy
## Drifting asteroid chunk (debris belt): soaks shots, rams.
## params: x, z, vx, vz, spin, big

const INFO := {
	"name": "ROCK", "category": "hazard",
	"desc": "小惑星：漂ってきてショットを吸う。体当たりあり",
	"demos": [
		["SMALL", "one", [0.0, "rock", -0.2, {"vx": 0.6, "vz": 6.0, "spin": 0.8}]],
		["BIG", "one", [0.0, "rock", 0.2, {"vx": -0.6, "vz": 6.0, "spin": -0.8, "big": true}]],
	],
}


func _init_kind() -> void:
	var big: bool = p.get("big", false)
	hp = 8.0 if big else 3.0
	radius = 1.6 if big else 0.9
	score = 500 if big else 150
	energy_drop = 8.0 if big else 3.0
	blast = 1.8 if big else 1.0
	counts = false
	mesh_name = "rock_l" if big else "rock_s"


func _behave(dt: float) -> void:
	if t <= dt * 1.5:
		vel = Vector3(p.get("vx", 0.0), 0, p.get("vz", 3.0))
		model.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
	position += vel * dt
	model.rotation.x += dt * float(p.get("spin", 0.7))
	model.rotation.y += dt * 0.3
