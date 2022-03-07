extends EditorInspectorPlugin

const MAX_DEPTH: int = 100

func can_handle(object: Object) -> bool:
	return true


func parse_begin(object: Object) -> void:
	var button = Button.new()
	button.text = "Ref in script"
	button.connect("pressed", self, "reference_node_in_script", [object])

	add_custom_control(button)


func reference_node_in_script(node: Node):
	var viewport = node.get_viewport()

	printt("Start", "Root:", viewport)

	var search_depth = 0
	var parent = node.get_parent()
	while parent != node.get_viewport() and not parent.get_script():
		printt("Node:", parent.name, "Script:", parent.get_script())
		parent = parent.get_parent()

		search_depth+=1
		if search_depth > MAX_DEPTH: break

	var script: Script = parent.get_script()
	var code: String = script.get_source_code()

	var node_path: String = parse_node_path(node, parent)

	code += "\nonready var _" + node.name + ": " + node.get_class() + " = $" + node_path
	script.set_source_code(code)

	script.take_over_path(script.resource_path)
	script.reload()
	script.emit_changed()


func parse_node_path(node: Node, parent: Node) -> String:
	var node_path: String = (str(node.get_path())).split(parent.name)[1]
	node_path.erase(0, 1)
	return node_path
