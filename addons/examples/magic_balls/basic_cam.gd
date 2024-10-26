extends Camera3D

@export var sensitivity:float = 0.01

var init_rotation := Vector3.ZERO
var init_mouse_position := Vector2.ZERO

func _ready() -> void:
	init_rotation = rotation
	init_mouse_position = get_window().get_mouse_position()
	get_window().warp_mouse(Vector2.ZERO)

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_up", "ui_down", "ui_right", "ui_left")
	if dir:
		position += Vector3(dir.x, 0, dir.y)
	
	var window_size := get_window().size
	var mouse_position := get_window().get_mouse_position() - init_mouse_position
	
	var tilt := (mouse_position) * sensitivity
	rotation.x = -tilt.y + init_rotation.x
	rotation.y = tilt.x + init_rotation.y
