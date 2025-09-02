@tool
@icon("./advanced_billboard_2d.svg")
class_name AdvancedBillboard2D
extends Sprite2D

## AdvancedBillboard2D
##
## AKA Turnaround Sprites.
## [AdvancedBillboard2D] allows for a pseudo-3D approach to rotation in 2D space.
## NOTE: The given facing textures must not be pre-rotated
## (make them all face the same direction visually,
## even though they appear form a diffrent angle).
## Godot already renders these from the appropriate angle.
## If you prefer your sprites remain rotated,
## please implement custom shader logic to handle this.
## You can hook into the [method _billboard_update] method if you wish.

## Enables advanced billboard interactions, when [code]false[/code],
## [member Sprite2D] will not change its state based on this sprite.
@export var advanced_billboard_enable := true:
	get:
		return advanced_billboard_enable
	set(_value):
		if _value != advanced_billboard_enable:
			if not _value:
				texture = direction_textures[0] if direction_textures.size() > 0 else null
			elif _value and Engine.is_editor_hint() and direction_textures == [] and texture != null:
				direction_textures = [texture]
		advanced_billboard_enable = _value
		notify_property_list_changed()

## Update billboard rotation during the physics update instead of the frame update.
## This will have no effect in editor, and will always update on frame.
@export var physics_update := false
## A array of textures to map to a specific range of rotations in the y axis.[br]
## Use [member offset_rotation_degrees] to change where the 0th texture is centered towards.
@export var direction_textures:Array[Texture2D] = []

@export_group("Rotation")
## Offset the rotation of the billboard from it's [method get_relevant_rotation] in radians.
@export_range(-360, 360, 0.1, "radians_as_degrees")
var offset_rotation:float = 0.0
## Offset the rotation of the billboard from it's [method get_relevant_rotation] in degrees.
var offset_rotation_degrees:float:
	get:
		return rad_to_deg(offset_rotation)
	set(_value):
		offset_rotation = deg_to_rad(_value)
## Use the rotation of the sprite node as the rotation to use when selecting textures.
## Mostly usefull from a top down viewpoint.
@export var automatic_rotation := true:
	get:
		return automatic_rotation
	set(_value):
		automatic_rotation = _value
		notify_property_list_changed()
## The manual rotation in radians to use when selecting textures.
## Only applies when [member automatic_rotation] is [code]false[/code].
## Mostly usefull from a side or orthagonal perspective.
@export_range(-360, 360, 0.1, "radians_as_degrees")
var manual_rotation_z:float = 0.0
## The manual rotation in degrees to use when selecting textures.
## Only applies when [member automatic_rotation] is [code]false[/code].
## Mostly usefull from a side or orthagonal perspective.
var manual_rotation_z_degrees:float = 0.0:
	get:
		return rad_to_deg(manual_rotation_z)
	set(_value):
		manual_rotation_z = deg_to_rad(_value)

## Returns the rotation to use when selecting a texture to display.
func get_relevant_rotation() -> float:
	if automatic_rotation:
		return global_rotation
	return manual_rotation_z

## Load a [Texture2DArray] as the [member direction_textures].
func load_texture_2d_array(array:Texture2DArray) -> void:
	direction_textures = Array()
	if array == null:
		return
	var s:int = array.get_size()
	direction_textures.resize(s)
	for i in range(s):
		direction_textures[i] = array.get_texture(i)

## Get the texture that will be shown if the billboard's [member Node3D.global_rotation_degrees]
## is set to [param rotation_degrees].[br]
## Returns [code]null[/code] when not valid texture could be found.
func get_face_texture(rot:float) -> Texture2D:
	if direction_textures.size() <= 0:
		return null

	var direction_span := TAU / direction_textures.size()
	var direction := wrapf(rot - offset_rotation - direction_span/2, 0, TAU)
	var index := wrapi(floori(direction / direction_span), 0, direction_textures.size())

	return direction_textures[index]

func _validate_property(property: Dictionary) -> void:
	match(property.name):
		"texture" when advanced_billboard_enable:
			property.usage &= ~PROPERTY_USAGE_EDITOR
		"physics_update", "direction_textures", "offset_rotation", "automatic_rotation" when not advanced_billboard_enable:
			property.usage &= ~PROPERTY_USAGE_EDITOR
		"manual_rotation_z" when automatic_rotation or not advanced_billboard_enable:
			property.usage &= ~PROPERTY_USAGE_EDITOR

func _physics_process(_delta: float) -> void:
	if advanced_billboard_enable and physics_update:
		_billboard_update()

func _process(_delta: float) -> void:
	if advanced_billboard_enable and not physics_update:
		_billboard_update()

# Update the billboard's rotation and texture, called internally by either
# [member Node._process] or [member Node._physics_process].
func _billboard_update() -> void:
	texture = get_face_texture(get_relevant_rotation())

func _notification(what:int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE when advanced_billboard_enable:
			# Just like in [AdvancedBillboard3D], there is no need to
			# save this if we always automatically change it every save.
			texture = get_face_texture(0.0)
