extends Enemy
## Ground gun on an island: aimed shell bursts. Spawned with its island
## (params: island, cell); the head turns as a separate mesh.

const INFO := {
	"name": "TURRET", "category": "ground",
	"desc": "砲台：甲板の上から狙いの物理弾を 3 連射",
	"demos": [["ON A DECK", "ground", []]],
}

var head: MeshInstance3D


func _init_kind() -> void:
	hp = 5.0
	radius = 0.8
	score = 400
	energy_drop = 4.0
	counts = false
	ground = true
	ram = false
	mesh_name = "turret_base"
	fire_t = 1.0 + randf() * 1.5


func _build() -> void:
	head = add_mesh("turret_head")
	head.position.y = 0.3


func _behave(dt: float) -> void:
	var hp_ := hit_pos
	if not game.player.alive:
		return
	var d := game.player.position - hp_
	head.rotation.y = lerp_angle(head.rotation.y, atan2(-d.x, -d.z), 6.0 * dt)
	fire_t -= dt
	if fire_t <= 0.0:
		if game.on_field(hp_, -1.0) and d.length() > 4.5 and game.combat_on():
			if step < 3:
				game.bullets.fire(hp_, atan2(d.z, d.x), 7.5, Bullets.SHELL, self, Bullets.NEEDLE)
				step += 1
				fire_t = 0.14
				return
		step = 0
		fire_t = 2.6
