extends Enemy
## Strikes from the side, where no shot reaches. A train waits off one edge
## while a lock-on there marks the ship's height, then sweeps in level with
## it and hooks up (or down) the centre line just before it (a ship on the
## centre is passed in front or behind; one nearer that edge has to move
## off the line), and leaves along the centre line, past the guns.
## params: side (-1 = from the left), i (place in the train, 0 = the
## leader, who sets the height and shows the warning), group (shared by the
## train), gap, hook (x of the climb, fraction of the half width), up

const INFO := {
	"name": "FLANKER", "category": "small",
	"desc": "側面強襲機：画面の横に予兆を出し、自機と同じ高さを真横から突っ込む。中央の手前で上（または下）へ折れて抜けていく",
	"demos": [
		["FROM LEFT", "flankers", [0.0, -1, 3]],
		["DOWN", "flankers", [0.0, 1, 3, 0.0, false]],
		["LEFT THEN RIGHT", "flankers", [0.0, -1, 3], "flankers", [1.2, 1, 3]],
		["PINCER 1+1", "pincer", [0.0, 1]],
		["PINCER 2+2", "pincer", [0.0, 2, false]],
	],
}

const WAIT := 0.7
const SPEED := 24.0
const CLIMB := 15.0  # slower once it has turned: easy to shoot
const R := 4.0  # hook radius

var lane := 0.0
var x0 := 0.0  # start, just off the edge
var xh := 0.0  # the climb line
var dir := 1.0  # +1 = moving right
var s := 0.0  # distance along the path
var spd := SPEED
var ud := -1.0  # where it turns: -1 = up the screen, +1 = down


func _init_kind() -> void:
	hp = 1.0
	radius = 0.85
	score = 200
	energy_drop = 2.0


func _behave(dt: float) -> void:
	var i: int = p.get("i", 0)
	if t <= dt * 1.5:
		var side := signf(float(p.get("side", -1)))
		dir = -side
		ud = -1.0 if p.get("up", true) else 1.0
		var grp: Dictionary = p.get("group", {})
		if i == 0 or not grp.has("z"):
			var pz: float = game.player.position.z if game.player.alive else game.field_bottom - 5.0
			grp["z"] = clampf(pz, game.field_top + R + 3.0, game.field_bottom - 1.5)
		lane = grp["z"]
		x0 = side * (game.half_width_at(lane) + 1.5)
		xh = float(p.get("hook", 0.0)) * game.field_hw
		s = -i * float(p.get("gap", 1.8))
		if i == 0:
			game.warn(self, WAIT, Game.Warn.MOVE, radius, Vector3(xh - dir * R, 0, lane))
	var run := dir * (xh - dir * R - x0)  # length of the level run
	var arc := R * PI / 2.0
	if t >= WAIT:
		if s > run + arc:
			spd = move_toward(spd, CLIMB, 30.0 * dt)
		s += spd * dt
	var d: Vector3
	if s < run:
		position = Vector3(x0 + dir * s, 0, lane)
		d = Vector3(dir, 0, 0)
	elif s < run + arc:
		var phi := (s - run) / R
		position = Vector3(xh - dir * R + dir * R * sin(phi), 0, lane + ud * (R - R * cos(phi)))
		d = Vector3(dir * cos(phi), 0, ud * sin(phi))
	else:
		position = Vector3(xh, 0, lane + ud * (R + (s - run - arc)))
		d = Vector3(0, 0, ud)
	vel = d * spd
	face(d)
	# lean into the hook
	var lean := 0.7 * dir * ud if s > run - 1.0 and s < run + arc else 0.0
	model.rotation.z = lerpf(model.rotation.z, lean, 8.0 * dt)
