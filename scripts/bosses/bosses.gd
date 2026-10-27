class_name Bosses
extends RefCounted
## Every mid-boss and boss by name. To add one: write scripts/bosses/<name>.gd
## (extends BossBase, with an INFO constant), list it here and give it its
## models in BossModels. A stage uses it as a wave spawn (mid-boss) or as
## its `boss`; the viewer lists it by itself.

const KINDS := {
	"lazaro": preload("res://scripts/bosses/lazaro.gd"),
	"star_cortex": preload("res://scripts/bosses/star_cortex.gd"),
	"ouroboros": preload("res://scripts/bosses/ouroboros.gd"),
	"vulcan_press": preload("res://scripts/bosses/vulcan_press.gd"),
	"lodestar": preload("res://scripts/bosses/lodestar.gd"),
	"tempest": preload("res://scripts/bosses/tempest.gd"),
	"behemoth": preload("res://scripts/bosses/behemoth.gd"),
	"titan_dredge": preload("res://scripts/bosses/titan_dredge.gd"),
	"gorgon": preload("res://scripts/bosses/gorgon.gd"),
}


static func has(kind: String) -> bool:
	return KINDS.has(kind)


static func create(kind: String) -> BossBase:
	return KINDS[kind].new()


static func info(kind: String) -> Dictionary:
	return KINDS[kind].INFO


static func title(kind: String) -> String:
	return str(info(kind).get("name", kind.to_upper()))
