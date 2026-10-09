extends RefCounted
## EP1 "Community Service" — the whole episode, scene by scene (docs/ep1-script.md).
## Each scene is its own script with `run(d)`, built in its own patch of world.

const SCENES := [
	"res://episodes/ep1_cold_open.gd",      # cold open + theme
	"res://episodes/ep1_s1_handoff.gd",
]

func run(d: Director) -> void:
	for path in SCENES:
		await load(path).new().run(d)
