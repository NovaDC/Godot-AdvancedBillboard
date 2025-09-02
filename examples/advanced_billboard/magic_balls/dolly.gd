@tool
extends PathFollow3D

@export var loop_per_sec:float = 0.01
@export var focus:Node3D = null

func _process(delta: float) -> void:
	progress_ratio += loop_per_sec * delta
	if focus != null:
		look_at(focus.global_position, Vector3.UP)

func _notification(what:int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			progress_ratio = 0
			global_rotation = Vector3.ZERO
