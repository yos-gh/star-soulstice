class_name EnemyKinds
extends RefCounted
## Every enemy kind by name. To add one: write scripts/enemies/<kind>.gd
## (extends Enemy, with an INFO constant, see enemy.gd), list it here and
## give it a model in EnemyModels (or set mesh_name). Stages spawn it by
## name; the viewer lists it with its demos by itself.

const KINDS := {
	"dart": preload("res://scripts/enemies/dart.gd"),
	"swirl": preload("res://scripts/enemies/swirl.gd"),
	"rammer": preload("res://scripts/enemies/rammer.gd"),
	"chaser": preload("res://scripts/enemies/chaser.gd"),
	"flanker": preload("res://scripts/enemies/flanker.gd"),
	"racer": preload("res://scripts/enemies/racer.gd"),
	"container": preload("res://scripts/enemies/container.gd"),
	"turret": preload("res://scripts/enemies/turret.gd"),
	"rock": preload("res://scripts/enemies/rock.gd"),
	"bulwark": preload("res://scripts/enemies/bulwark.gd"),
	"part": preload("res://scripts/enemies/part.gd"),
}


static func has(kind: String) -> bool:
	return KINDS.has(kind)


static func create(kind: String) -> Enemy:
	if not KINDS.has(kind):
		push_error("unknown enemy kind " + kind)
		return KINDS["part"].new()
	return KINDS[kind].new()


static func info(kind: String) -> Dictionary:
	return KINDS[kind].INFO if KINDS.has(kind) else {}
