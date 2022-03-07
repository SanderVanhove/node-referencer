extends EditorInspectorPlugin

const MAX_DEPTH: int = 100
const REFERENCE_BLOCK_START: String = "### Automatic References Start ###"
const REFERENCE_BLOCK_STOP: String = "### Automatic References Stop ###"

var _button: Button
var _variable_name: String

func can_handle(object: Object) -> bool:
	if not object is Node: return false

	var parent: Node = find_parent(object)
	return parent.get_script()


func parse_category(object: Object, category: String) -> void:
	if category != "Node":
		return

	_button = Button.new()
	_button.text = "Reference in parent script"
	_button.connect("pressed", self, "reference_node_in_script", [object])

	add_custom_control(_button)


func reference_node_in_script(node: Node):
	# Find a parent with a script or stop
	var parent: Node = find_parent(node)
	if not parent.get_script():
		printerr("Node Referencer: This node does not have a parent with a script attached.")
		return

	var script: Script = parent.get_script()
	var code: String = script.get_source_code()

	var updated_code = alter_code(code, node, parent)
	script.set_source_code(updated_code)

	save_script(script)

	_button.text = "Done, copy variable name"
	_button.disconnect("pressed", self, "reference_node_in_script")
	_button.connect("pressed", self, "copy_variable_name")


func copy_variable_name() -> void:
	OS.set_clipboard(_variable_name)


func find_parent(node: Node) -> Node:
	var search_depth = 0

	var viewport = node.get_viewport()
	var parent = node.get_parent()

	while parent != node.get_viewport() and not parent.get_script():
		parent = parent.get_parent()

		search_depth+=1
		if search_depth > MAX_DEPTH: break

	return parent


func alter_code(code: String, node: Node, parent: Node) -> String:
	var split_code: PoolStringArray = splitup_code(code)
	var references: Array = Array(get_references(split_code))

	# Return if the reference is already in there
	var node_path: String = generate_node_path(node, parent)
	for ref in references:
		if ref.find(node_path) > 0 and len(ref.split(node_path, false, 1)) == 1:
			_variable_name = ref.split("var ")[1].split(":")[0]
			return code

	var reference = generate_reference(node, parent, code)

	# Add the new reference and sort
	references.append(reference)
	references.sort()

	# Add the comments to show what is auto generated
	references.insert(0, REFERENCE_BLOCK_START)
	references.append(REFERENCE_BLOCK_STOP)

	# Join everything back together
	var references_pool = PoolStringArray(references)
	split_code.set(1, references_pool.join("\n"))
	return split_code.join("")


func splitup_code(code: String) -> PoolStringArray:
	var start_split: PoolStringArray = code.split(REFERENCE_BLOCK_START + "\n", true, 1)

	if len(start_split) == 1:
		var split_code: PoolStringArray = code.split("\n", true, 1)
		split_code[0] += "\n\n"
		split_code[1] = "\n" + split_code[1]
		split_code.insert(1, "")
		return split_code

	var block_and_end: PoolStringArray = start_split[1].split(REFERENCE_BLOCK_STOP, true, 1)

	return PoolStringArray([start_split[0], block_and_end[0], block_and_end[1]])


func get_references(split_code: PoolStringArray) -> PoolStringArray:
	return split_code[1].split("\n", false) if len(split_code) == 3 else PoolStringArray()


func generate_reference(node: Node, parent: Node, code: String) -> String:
	var node_path: String = generate_node_path(node, parent)
	var variable_name: String = generate_variable_name(node, code)
	var node_class: String = generate_node_class(node)

	_variable_name = variable_name

	return "onready var " + variable_name + ": " + node_class + " = " + node_path


func generate_variable_name(node: Node, code: String) -> String:
	var name = node.name

	for letter in ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]:
		name = name.replace(letter, "_" + letter.to_lower())

	if not name.begins_with("_"):
		name = "_" + name

	# Check if name already exists
	var index: int = 1
	var indexed_name: String = name
	while code.find(indexed_name) >= 0:
		indexed_name = name + "_" + str(index)
		index += 1

	return indexed_name


func generate_node_path(node: Node, parent: Node) -> String:
	var node_path: String = (str(node.get_path())).split(parent.name)[1]
	node_path[0] = "$"
	return node_path


func generate_node_class(node: Node) -> String:
	var script: Script = node.get_script()

	if not script:
		return node.get_class()
	
	var code: String = script.get_source_code()
	var split_start: PoolStringArray = code.split("class_name ", true, 1)

	if len(split_start) == 1:
		return code.split("extends ", true, 1)[1].split("\n", true, 1)[0]
	
	return split_start[1].split("\n", true, 1)[0]


func save_script(script: Script) -> void:
	script.reload()
	script.emit_changed()

	ResourceSaver.save(script.resource_path, script)
