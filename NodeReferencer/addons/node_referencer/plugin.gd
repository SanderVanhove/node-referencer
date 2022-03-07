tool
extends EditorPlugin


var plugin = load("res://addons/node_referencer/NodeReferencer.gd")
var plug_instance


func _enter_tree() -> void:
	plug_instance = plugin.new()
	add_inspector_plugin(plug_instance)


func _exit_tree():
	remove_inspector_plugin(plug_instance)
