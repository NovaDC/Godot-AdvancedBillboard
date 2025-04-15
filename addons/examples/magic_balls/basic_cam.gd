extends Camera3D

@export var sensitivity:float = 0.01
@export var rail_cam:Camera3D = null

var init_rotation := Vector3.ZERO
var init_mouse_position := Vector2.ZERO

func _ready() -> void:
	init_rotation = rotation
	init_mouse_position = get_window().get_mouse_position()
	get_window().warp_mouse(Vector2.ZERO)

func _input(event: InputEvent) -> void:
	if rail_cam == null:
		return
	if event.is_action_pressed("ui_accept"):
		if get_viewport().get_camera_3d() != rail_cam:
			rail_cam.current = true
		else:
			current = true

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir:
		position += ((basis * Vector3(dir.x, 0, dir.y)) * Vector3(1,0,1)).normalized()
	
	var window_size := get_window().size
	var mouse_position := get_window().get_mouse_position() - init_mouse_position
	
	var tilt := (mouse_position) * sensitivity
	rotation.x = -tilt.y + init_rotation.x
	rotation.y = tilt.x + init_rotation.y
