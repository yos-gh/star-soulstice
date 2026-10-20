extends Enemy
## A boulder (the drifting big rock): carried in a GRAPPLER's claws and
## flung down a marked line, or fired from TITAN DREDGE's mass driver or
## its rockfall. Rams like any rock; shots break it. One whose carrier is
## gone drifts down slowly (or, still above the screen, is gone with it).
## params: holder (the Enemy carrying it; the carrier moves `grip`), or vx,
## vz (flying from the start), spin, scale (of the model)

const INFO := {
	"name": "BOULDER", "category": "hazard", "stage": 3,
	"desc": "岩塊：GRAPPLER が爪で抱えて盾にし、予兆（線）のあと自機のいた所へ投げつける。TITAN DREDGE も撃ち出す。体当たりあり、撃てば壊れる",
	"demos": [["FLUNG", "one", [0.0, "boulder", 0.1, {"vx": -1.2, "vz": 15.0, "spin": 2.0}]]],
}

var holder: Enemy
var grip := Vector3(0, 0, 2.7)  # from the carrier, while it is carried
var held := false


func _init_kind() -> void:
	hp = 30.0
	radius = 1.5
	score = 300
	energy_drop = 4.0
	blast = 1.8
	counts = false
	marked = true
	mesh_name = "rock_l"


func _behave(dt: float) -> void:
	if t <= dt * 1.5:
		holder = p.get("holder", null)
		held = holder != null
		vel = Vector3(p.get("vx", 0.0), 0, p.get("vz", 0.0))
		model.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
		model.scale = Vector3.ONE * float(p.get("scale", 1.0))
	if held:
		if is_instance_valid(holder) and not holder.dead and game.enemies.has(holder):
			position = holder.position + grip
			model.rotation.y += dt * 0.4
			return
		# its carrier is gone
		held = false
		if position.z < game.field_top - 0.5:
			game.remove_enemy(self)
			return
		vel = Vector3(0, 0, 3.0)
	position += vel * dt
	model.rotation.x += dt * float(p.get("spin", 1.6))
	model.rotation.y += dt * 0.5


## Flung by its carrier: off at velocity `v`.
func hurl(v: Vector3) -> void:
	held = false
	vel = v
	p["spin"] = 3.0
