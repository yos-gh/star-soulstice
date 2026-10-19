extends Enemy
## Cargo capsule: drifts down; breaking it drops a POWER item.
## params: x

const INFO := {
	"name": "CONTAINER", "category": "carrier",
	"desc": "コンテナ：ゆっくり流れてくる。壊すとパワーアップが出る",
	"demos": [["DRIFT", "one", [0.0, "container", 0.0]]],
}


func _init_kind() -> void:
	hp = 14.0
	radius = 1.1
	score = 1000
	energy_drop = 4.0
	counts = false
	ram = false
	drops_power = true
	blast = 1.6
	debris_col = Models.PEARL


func _behave(dt: float) -> void:
	position.z += 2.0 * dt * game.scroll_speed / Game.SCROLL
	position.x = float(p["x"]) + sin(t * 1.1) * 1.4
	model.rotation.y += dt * 0.9
	model.rotation.x = sin(t * 1.7) * 0.25
