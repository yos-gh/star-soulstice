class_name Stages
extends RefCounted
## The stages in play order. To add a stage: write scripts/stage/stageN.gd
## (extends StageDef) and list it here. Clearing a stage moves on to the
## next one; after the last comes the title screen.

const LIST := [
	preload("res://scripts/stage/stage1.gd"),
	preload("res://scripts/stage/stage2.gd"),
	preload("res://scripts/stage/stage3.gd"),
	preload("res://scripts/stage/stage4.gd"),
]


static func count() -> int:
	return LIST.size()


## A fresh definition of stage n (1-based), its waves not built yet.
static func create(n: int) -> StageDef:
	var d: StageDef = LIST[clampi(n, 1, LIST.size()) - 1].new()
	d.number = clampi(n, 1, LIST.size())
	return d
