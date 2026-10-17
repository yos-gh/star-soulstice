extends Enemy
## Ground gun on an island: announced bursts of three aimed, unbreakable
## needles. It holds fire while the ship is over it or close by (bullet
## sealing): fly in on top of it to shut it up. Spawned with its island
## (params: island, cell); the head turns as a separate mesh.

const INFO := {
	"name": "TURRET", "category": "ground",
	"desc": "砲台：甲板の上から狙いのエネルギー弾を 3 連射（予兆あり）。真上や至近距離では撃てない（弾封じ）",
	"demos": [["ON A DECK", "ground", []]],
}

const SEAL := 6.0  # holds fire while the ship is this close (on the plane)

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
	if fire_t > 0.0:
		return
	if not game.on_field(hp_, -1.0) or not game.combat_on():
		step = 0
		fire_t = 2.6
		return
	if d.length() < SEAL:
		# sealed: the burst stops; it tries again shortly
		step = 0
		fire_t = 0.6
		return
	if step == 0:
		game.warn(self, WINDUP_SHOT, Game.Warn.SHOT, radius)
		step = 1
		fire_t = WINDUP_SHOT
	elif step <= 3:
		game.bullets.fire(hp_, atan2(d.z, d.x), 7.5, Bullets.ORB, self, Bullets.NEEDLE)
		step += 1
		fire_t = 0.14
	else:
		step = 0
		fire_t = 2.6
