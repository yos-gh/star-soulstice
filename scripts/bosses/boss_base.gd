class_name BossBase
extends Node3D
## A big enemy made of parts: a mid-boss or a stage boss. Its parts are
## Enemy nodes of kind "part" (Game.spawn_part) whose `controller` is this
## node; hits on a part go through on_hit (which may change the damage) and
## a part's death through on_part_killed. Each boss is a script in
## scripts/bosses/ listed in Bosses, with an INFO constant:
##   name   shown in the CAUTION message, the gauge and the viewer
##   role   "mid" or "boss"
##   desc   one line for the viewer
##   demos  [[label, skip], ...] viewer shortcuts (see viewer_skip)
## A stage boss (`final`) ends the stage with game.boss_destroyed().

var game: Game
var final := false  # the stage boss: its death clears the stage
var finished := false  # gone (destroyed or escaped)
var defeated := false


func setup(g: Game) -> void:
	game = g


func tick(_dt: float) -> void:
	pass


func on_hit(_e: Enemy, dmg: float) -> float:
	return dmg


func on_part_killed(_e: Enemy) -> void:
	pass


## The HUD gauge: {frac, color, name, name_color, x, w, h, name_y} (x and w
## as fractions of the screen width), or {} while it is hidden.
func gauge() -> Dictionary:
	return {}


## Out of health: from now on its wreck is not solid (the ship can't crash
## into it while it blows up) and takes no more hits, and it draws under
## the explosions (Vox.sink_node), so the fire of its death goes over it
## while live enemies and bullets stay on top. Every boss calls this as its
## death sequence starts.
func disarm() -> void:
	defeated = true
	Vox.sink_node(self)
	for e: Enemy in game.enemies:
		if e.controller == self:
			e.intangible = true
			e.ram = false
			e.sunk = true
			Vox.sink_node(e)


## Viewer: destroy it now (its death sequence plays).
func force_defeat() -> void:
	pass


## Viewer: jump to a later part of the fight (INFO.demos).
func viewer_skip(_to: String) -> void:
	pass


## Viewer: one line of live state.
func debug_state() -> String:
	return ""
