extends Enemy
## Mid-size mining tug of the asteroid belt (stage 3): it comes down
## holding a boulder (a meteor chunk) in its claws in front of it, with a
## spare on its back, and opens with the throw: as soon as it is on the
## screen it winds up (a lock-on on the boulder and a marked line through
## where the ship is) and flings the boulder down that line to the bottom
## edge of the screen, still coming down. Then it holds near the top,
## swaying: telegraphed needle bursts, it loads the spare from its back
## (the rock takes the shots meant for the tug again), shell fans (big, then
## small) from the gun pods on its flanks, and the second throw. A quiet
## gap follows every round: come in with the Spear. When its time is up it
## backs away up the screen.
## params: x, hold (z it holds at), stay (seconds)

const INFO := {
	"name": "GRAPPLER", "category": "medium",
	"desc": "中型機（採掘タグ）：隕石の岩塊を爪で抱えて降りてくる（背中に予備が 1 つ）。画面に入るとすぐ、予兆（線）のあと岩を自機のいた所へ投げつける（下端まで）。止まってからは狙いの針弾を 2 連、予備を積み（岩が盾になる）、両脇の砲から物理弾の扇（大きい弾が先）、2 つ目を投げる。合間に静かな間。時間が来ると後ずさりして去る",
	"demos": [
		["ONE", "grappler", [0.0, 0.0]],
		["PAIR", "grappler", [0.0, -0.5], "grappler", [1.5, 0.5]],
	],
}

const GRIP := Vector3(0, 0, 3.1)  # the boulder in the claws, from the tug
const BED := Vector3(0, 0.6, -0.75)  # the spare on the cargo bed
const CLAW := Vector3(1.15, 0, 1.2)  # the claws' roots
const GUN := Vector3(1.8, 0, 1.6)  # the gun pods' muzzles (and the mirror)
const THROW := 17.0
const LOAD_T := 0.7
const OPEN_AT := 0.5  # below the top of the screen: it winds up for the first throw

var claws: Array[MeshInstance3D] = []
var spare: MeshInstance3D
var rock: Enemy  # the boulder in the claws
var spares := 1
var open := 0.0  # claws: 0 shut, 1 wide
var open_want := 0.0
var hold_t := 0.0
var load_t := -1.0
var throw_to := Vector3.ZERO
var throw_t := -1.0  # counting down to a throw after the wind-up
var opened := false  # the first throw is under way
var arrived := false


func _init_kind() -> void:
	hp = 110.0
	radius = 2.2
	score = 2500
	energy_drop = 12.0
	blast = 3.0


func _build() -> void:
	for s: float in [-1.0, 1.0]:
		var c := add_mesh("grappler_claw")
		c.position = Vector3(s * CLAW.x, 0, CLAW.z)
		if s > 0.0:
			c.scale = Vector3(-1, 1, 1)
		claws.append(c)
	spare = add_mesh("meteor_b")
	spare.scale = Vector3.ONE * 0.62
	spare.position = BED
	spare.rotation = Vector3(0.4, 1.1, 0.2)


func _holding() -> bool:
	return is_instance_valid(rock) and not rock.dead and rock.held


func _grab(at: Vector3, mesh: String) -> void:
	rock = game.spawn_enemy("boulder", {"holder": self, "mesh": mesh, "x": position.x + at.x, "z": position.z + at.z})
	rock.grip = at


## Lock-on on the boulder, the line from it through the ship to the bottom
## edge; the throw follows WINDUP_MOVE later.
func _wind_up() -> void:
	throw_to = game.line_to_bottom(rock.position, game.player.position)
	game.warn(rock, WINDUP_MOVE, Game.Warn.MOVE, rock.radius, throw_to)
	game.sfx.play("slam")
	open_want = 0.15
	throw_t = WINDUP_MOVE


func _throw() -> void:
	throw_t = -1.0
	if not _holding():
		return
	var d := throw_to - rock.position
	d.y = 0.0
	rock.hurl(d.normalized() * THROW)
	rock = null
	open_want = 1.0


func _behave(dt: float) -> void:
	if t <= dt * 1.5:
		_grab(GRIP, "meteor_a")
	var stay: float = p.get("stay", 13.0)
	var hold: float = p.get("hold", game.field_top + 5.0)
	open = move_toward(open, open_want, 4.0 * dt)
	claws[0].rotation.y = -open * 0.6
	claws[1].rotation.y = open * 0.6
	if load_t >= 0.0:
		# the spare slides forward off the bed into the claws
		load_t += dt
		var f := clampf(load_t / LOAD_T, 0.0, 1.0)
		f = f * f * (3.0 - 2.0 * f)
		if _holding():
			rock.grip = Vector3(0, 0, lerpf(BED.z, GRIP.z, f))
		if load_t >= LOAD_T:
			load_t = -1.0
			open_want = 0.0
	if throw_t >= 0.0:
		throw_t -= dt
		if throw_t <= 0.0:
			_throw()
	if t >= stay:
		# back away up the screen
		vel.z = move_toward(vel.z, -8.0, 6.0 * dt)
		position.z += vel.z * dt
		return
	if not arrived:
		# down to the hold line, easing in; the first throw on the way
		if not opened and position.z > game.field_top + OPEN_AT and _holding() and game.can_fire(position):
			opened = true
			_wind_up()
		position.z += clampf((hold - position.z) * 2.2, 1.2, 8.0) * dt
		if position.z >= hold - 0.02:
			arrived = true
			# after the opening throw the round goes on with the needles
			step = 4 if opened else 0
			fire_t = 0.6
		return
	# sway a little (from where it stopped: no jump)
	hold_t += dt
	position.x = float(p.get("x", 0.0)) + sin(hold_t * 0.55) * 1.4
	model.rotation.z = sin(hold_t * 0.9) * 0.05
	fire_t -= dt
	if fire_t > 0.0 or throw_t >= 0.0 or not game.can_fire(position):
		return
	match step % 7:
		0:
			_fans(Bullets.BIG)
			fire_t = 0.3
		1:
			_fans(Bullets.SMALL)
			fire_t = 0.9
		2:
			if _holding() and load_t < 0.0:
				_wind_up()
				fire_t = WINDUP_MOVE + 0.5
			else:
				fire_t = 0.05
		3:
			fire_t = 0.05  # (the throw itself runs on throw_t)
		4:
			game.warn(self, WINDUP_SHOT + 0.15, Game.Warn.SHOT, radius)
			fire_t = WINDUP_SHOT + 0.15
		5:
			_needles()
			fire_t = 0.3
		6:
			_needles()
			fire_t = 2.4  # quiet gap: come in with the Spear
			if not _holding() and spares > 0:
				spares -= 1
				spare.visible = false
				_grab(BED, "meteor_b")
				load_t = 0.0
				open_want = 0.6
	step += 1


## Shell fans from both gun pods, down and a little outward round the
## boulder (`size` BIG leads, SMALL follows).
func _fans(size: float) -> void:
	for s: float in [-1.0, 1.0]:
		var at := position + Vector3(s * GUN.x, 0, GUN.z)
		var a := PI / 2.0 - s * deg_to_rad(22.0 if size == Bullets.BIG else 26.0)
		game.bullets.fan(at, a, 5 if size == Bullets.BIG else 4, 44.0 if size == Bullets.BIG else 36.0, 5.0 if size == Bullets.BIG else 5.6, Bullets.SHELL, self, Bullets.ROUND, size)


## A 3-way burst of unbreakable needles at the ship, from the front.
func _needles() -> void:
	var at := position + Vector3(0, 0, 1.4)
	game.bullets.fan(at, game.bullets.aim(at), 3, 12.0, 9.5, Bullets.ORB, self, Bullets.NEEDLE)
