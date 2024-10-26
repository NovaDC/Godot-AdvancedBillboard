@tool
@icon("res://addons/advanced_billboard/advanced_billboard.svg")
class_name AdvancedBillboard
extends Sprite3D

## AdvancedBillboard
##
## [AdvancedBillboard] allows for more advanced Y axis billboarding in 3d space.

enum LOCK_AXIS_MASK{
	X = 0b001, ## The global [code]x[/code] axis.
	Y = 0b010, ## The global [code]y[/code] axis.
	Z = 0b100  ## The global [code]z[/code] axis.
}

## Enables advanced billboard interactions, when [code]false[/code],
## [member Sprite3D.billboard] will be setable again, and act as normal.
@export var advanced_billboard_enable:bool = true:
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
@export var physics_update:bool = false
## A array of textures to map to a specific range of rotations in the y axis.[br]
## Use [member offset_degrees.y] to change where the 0th texture is centered towards.
@export var direction_textures:Array[Texture2D] = []

@export_group("Rotation")
## Offset the rotation of the billboard from it's [member point_target].
@export var offset_degrees:Vector3 = Vector3.ZERO
## The node the billboard should face. When [code]null[/code],
## the rotation of this billboard will not change.
@export var point_target:Node3D = null
## A bitset (with each bit's place value corelating to [enum LOCK_AXIS_MASK])
## that when set will force that axis of rotation of the billboard to snap parallel
## to the global axises.
@export_flags("X:1","Y:2","Z:4") var lock_axis:int = 0
## Instead of looking directly at the targeted node's position, face parallel to it,
## in the oppsite direction. For more convincing orthographic effects.
@export var look_parallel:bool = false

@export_subgroup("Editor")
## When [code]true[/code] the rotation of the billboard in editor
## will differ from the set [member point_target].
@export var editor_direction_override:bool = true:
	get:
		return editor_direction_override
	set(_value):
		editor_direction_override = _value
		notify_property_list_changed()
## When set and [editor_direction_override] is [code]true[/code],
## the billboard will point towards the given editor subviewport index's camera.[br]
## When below 0, no editor viewport will be taken as the point to target and will
## instead point towards the given [member editor_point_target].
@export_range(-1, 3, 1) var editor_point_to_camera_viewport_idx:int = 0:
	get:
		return editor_point_to_camera_viewport_idx
	set(_value):
		editor_point_to_camera_viewport_idx = _value
		notify_property_list_changed()
## When set, and [member editor_direction_override] is [code]true[/code],
## and [member editor_point_to_camera_viewport_idx] is below 0,
## that [Node3D] will be the billboard's target when in editor.
@export var editor_point_target:Node3D = null

## Get the texture that will be shown if the billboard's [member Node3D.global_rotation_degrees]
## is set to [param rotation_degrees].[br]
## Returns [code]null[/code] when not valid texture could be found.
func get_face_texture(rotation_degrees:Vector3) -> Texture2D:
	if direction_textures.size() <= 0:
		return null
	
	var direction_span := 360.0 / direction_textures.size()
	var direction := wrapf(rotation_degrees.y - offset_degrees.y - direction_span/2, 0, 360)
	var index := wrapi(floori(direction / direction_span), 0, direction_textures.size()) 
	
	return direction_textures[index]

func _set(property: StringName, _value:Variant) -> bool:
	if property == "billboard" and advanced_billboard_enable:
		set_billboard_mode(BaseMaterial3D.BillboardMode.BILLBOARD_DISABLED)
		return true
	return false

func _get(property: StringName) -> Variant:
	if property == "billboard" and advanced_billboard_enable:
		return BaseMaterial3D.BillboardMode.BILLBOARD_DISABLED
	return null

func _validate_property(property: Dictionary):
	match(property.name):
		"texture", "billboard" when advanced_billboard_enable:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		"physics_update", "direction_textures", "offset_degrees", "point_target", "lock_axis", "editor_direction_override", "editor_point_to_camera_viewport_idx", "editor_point_target", "look_parallel" when not advanced_billboard_enable:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		"editor_point_to_camera_viewport_idx", "editor_point_target" when not editor_direction_override:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		"editor_point_target" when editor_point_to_camera_viewport_idx >= 0:
			property.usage = PROPERTY_USAGE_NO_EDITOR

func _physics_process(_delta: float) -> void:
	if advanced_billboard_enable and physics_update and not Engine.is_editor_hint():
		__update()

func _process(_delta: float) -> void:
	if advanced_billboard_enable and (not physics_update or (editor_direction_override and Engine.is_editor_hint())):
		__update()

# Update the billboard's rotation and texture, called internally by either
# [member Node._process] or [member Node._physics_process].
func __update():
	var look_point:Vector3 = Vector3.ZERO
	if Engine.is_editor_hint() and editor_direction_override and editor_point_to_camera_viewport_idx >= 0:
		var look_node := EditorInterface.get_editor_viewport_3d(editor_point_to_camera_viewport_idx).get_camera_3d()
		look_point = look_node.global_position if not look_parallel else global_position + (look_node.transform.basis.z)
	elif Engine.is_editor_hint() and editor_direction_override and editor_point_target != null:
		look_point = editor_point_target.global_position
	else:
		look_point = point_target.global_position if not look_parallel else global_position + (point_target.transform.basis.z)
	
	if (lock_axis & LOCK_AXIS_MASK.X > 0):
		look_point.x = global_position.x
	if (lock_axis & LOCK_AXIS_MASK.Y > 0):
		look_point.y = global_position.y
	if (lock_axis & LOCK_AXIS_MASK.Z > 0):
		look_point.z = global_position.z
	
	if look_point != global_position:
		look_at(look_point)
		rotation_degrees += offset_degrees
	
	texture = get_face_texture(global_rotation_degrees)
