@tool
extends EditorPlugin

const PLUGIN_NAME := "AdvancedBillboard"

const PLUGIN_ICON := preload("./advanced_billboard_3d.svg")

func _get_plugin_name() -> String:
	return PLUGIN_NAME

func _get_plugin_icon() -> Texture2D:
	return PLUGIN_ICON
