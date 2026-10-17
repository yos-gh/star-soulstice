extends Enemy
## Ground gun on an island: one announced, aimed, unbreakable needle at a
## time, launched up from the gun to the flight level (Bullets.launch). It
## holds fire while the ship is over it or close by (bullet sealing): fly
## in on top of it to shut it up. Spawned with its island (params: island,
## cell); the head turns as a separate mesh.

const INFO := {
	"name": "TURRET", "category": "ground",
	"desc": "砲台：甲板から狙いのエネルギー弾を 1 発ずつ打ち上げる（予兆あり）。真上や至近距離では撃てない（弾封じ）",
	"demos": [["ON A DECK", "ground", []]],
}

const SEAL := 6.0  # holds fire while the ship is this close (on the plane)
const MUZZLE_Y := 0.6  # above the base, where the shot leaves the head

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
		# sealed: the shot is called off; it tries again shortly
		step = 0
		fire_t = 0.6
		return
	if step == 0:
		game.warn(self, WINDUP_SHOT, Game.Warn.SHOT, radius)
		step = 1
		fire_t = WINDUP_SHOT
	else:
		# one shot, launched up from the gun to the flight level
		var muzzle := global_position + Vector3(0, MUZZLE_Y, 0)
		game.bullets.launch(muzzle, atan2(d.z, d.x), 7.5, Bullets.ORB, self, Bullets.NEEDLE)
		game.fx.sprite(muzzle, Vector3(0, 4.0, 0), 0.5, 1.6, 0.22, Color(1.0, 0.7, 0.35))
		game.fx.flash(muzzle, 0.3)
		step = 0
		fire_t = 2.6
