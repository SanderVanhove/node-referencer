tool
extends EditorPlugin


const MAX_DEPTH: int = 100
const REFERENCE_BLOCK_START: String = "### Automatic References Start ###"
const REFERENCE_BLOCK_STOP: String = "### Automatic References Stop ###"
const CAPITAL_LETTERS: Array = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]


var _ref_3d_button: MenuButton
var _ref_2d_button: MenuButton
var _popup_menu_2d: PopupMenu
var _popup_menu_3d: PopupMenu

var _last_variable_name: String
var _valid_parents: Array


func _enter_tree() -> void:
	_ref_2d_button = MenuButton.new()
	_ref_2d_button.flat = true
	_ref_2d_button.text = "Reference"
	_ref_2d_button.hint_tooltip = "Reference node(s) in a parent's script."
	_ref_2d_button.hide()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _ref_2d_button)

	_ref_3d_button = _ref_2d_button.duplicate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _ref_3d_button)

	_popup_menu_2d = _ref_2d_button.get_popup()
	_popup_menu_2d.connect("id_pressed", self, "_reference_nodes")

	_popup_menu_3d = _ref_3d_button.get_popup()
	_popup_menu_3d.connect("id_pressed", self, "_reference_nodes")

	get_editor_interface().get_selection().connect("selection_changed", self, "_update_button_visibility")


func _update_button_visibility() -> void:
	var selection: Array = get_editor_interface().get_selection().get_selected_nodes()

	if not len(selection):
		_ref_2d_button.visible = false
		_ref_3d_button.visible = false
		return

	var selected_paths: Array = []
	var found_parents: Array = []
	var is_visible: bool = true

	_valid_parents.clear()
	_popup_menu_2d.clear()
	_popup_menu_3d.clear()

	for object in selection:
		if object as Node:
			var object_path: String = str(object.get_path())
			# If one of it's parents was processed, don't do this one
			if _parent_was_processed(object_path, selected_paths):
				continue
			selected_paths.append(object_path)

			# Get all valid parents
			var parents: Array = _find_valid_parents(object)

			for parent in parents:
				if not parent in found_parents:
					found_parents.append(parent)

	# Make sure only common parents are shown
	for parent in found_parents:
		if _is_common_parent(parent.get_path(), selected_paths):
			_valid_parents.append(parent)

	# Walk reversed through the valid parents
	for i in range(len(_valid_parents) - 1, -1, -1):
		var parent: Node = _valid_parents[i]
		var parent_path: String = _generate_node_path(parent, parent.get_viewport())

		_popup_menu_2d.add_item(parent_path, i)
		_popup_menu_3d.add_item(parent_path, i)

	_popup_menu_2d.add_separator()
	_popup_menu_3d.add_separator()

	_popup_menu_2d.add_item("Copy last reference")
	_popup_menu_3d.add_item("Copy last reference")

	_ref_2d_button.visible = len(_valid_parents)
	_ref_3d_button.visible = _ref_2d_button.visible



func _is_common_parent(object_path: String, selected_paths: Array) -> bool:
	for path in selected_paths:
		if path.find(object_path) < 0: return false
	return true


func _parent_was_processed(object_path: String, selected_paths: Array) -> bool:
	for path in selected_paths:
		if object_path.find(path) >= 0: return true
	return false


func _exit_tree():
	_ref_2d_button.queue_free()
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _ref_2d_button)


func _reference_nodes(selection_id: int):
	if selection_id >= len(_valid_parents):
		_copy_variable_name()
		return

	var nodes: Array = get_editor_interface().get_selection().get_selected_nodes()
	var parent: Node = _valid_parents[selection_id]

	for node in nodes:
		_reference_node_in_script(node, parent)


func _reference_node_in_script(node: Node, parent: Node):
	var script: Script = parent.get_script()
	var code: String = script.get_source_code()

	var updated_code = _alter_code(code, node, parent)
	script.set_source_code(updated_code)

	_save_script(script)


func _copy_variable_name() -> void:
	OS.set_clipboard(_last_variable_name)


func _find_valid_parents(node: Node) -> Array:
	var valid_parents: Array = []
	var search_depth = 0

	var viewport = node.get_viewport()
	var parent = node.get_parent()

	while parent != viewport:
		if parent.get_script():
			valid_parents.append(parent)

		search_depth += 1
		if search_depth > MAX_DEPTH: break

		parent = parent.get_parent()

	return valid_parents


func _alter_code(code: String, node: Node, parent: Node) -> String:
	var split_code: PoolStringArray = _splitup_code(code)
	var references: Array = Array(_get_references(split_code))

	# Return if the reference is already in there
	var node_path: String = _generate_node_path(node, parent)
	for ref in references:
		if ref.find(node_path) > 0 and len(ref.split(node_path, false, 1)) == 1:
			_last_variable_name = ref.split("var ")[1].split(":")[0]
			return code

	var reference = _generate_reference(node, parent, code)

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


func _splitup_code(code: String) -> PoolStringArray:
	var start_split: PoolStringArray = code.split(REFERENCE_BLOCK_START + "\n", true, 1)

	if len(start_split) == 1:
		var regex = RegEx.new()
		if code.find("class_name") != -1:
			regex.compile("class_name .+\n")
		else:
			regex.compile("extends .+\n")

		var split_index: int = regex.search(code).get_end()
		var split_code: PoolStringArray = [
			code.left(split_index) + "\n\n",
			"\n" + code.right(split_index)
		]

		# Insert an empty string where the ref block will come
		split_code.insert(1, "")

		return split_code

	var block_and_end: PoolStringArray = start_split[1].split(REFERENCE_BLOCK_STOP, true, 1)

	return PoolStringArray([start_split[0], block_and_end[0], block_and_end[1]])


func _get_references(split_code: PoolStringArray) -> PoolStringArray:
	return split_code[1].split("\n", false) if len(split_code) == 3 else PoolStringArray()


func _generate_reference(node: Node, parent: Node, code: String) -> String:
	var node_path: String = _generate_node_path(node, parent)
	var variable_name: String = _generate_variable_name(node, code)
	var node_class: String = _generate_node_class(node)

	_last_variable_name = variable_name

	return "onready var " + variable_name + ": " + node_class + " = " + node_path


func _generate_variable_name(node: Node, code: String) -> String:
	var name = node.name

	name = name.replace("2D", "_2d").replace(" ", "")

	for letter in CAPITAL_LETTERS:
		name = name.replace(letter, "_" + letter.to_lower())

	if not name.begins_with("_"):
		name = "_" + name

	# Check if name already exists
	var index: int = 1
	var indexed_name: String = name
	while code.find("onready var " + indexed_name + ": ") >= 0:
		indexed_name = name + "_" + str(index)
		index += 1

	return indexed_name


func _generate_node_path(node: Node, parent: Node) -> String:
	var node_path: String = (str(node.get_path())).split(parent.name, true, 1)[1]

	node_path.erase(0, 1)

	if node_path.find(" ") >= 0:
		node_path = "\"" + node_path + "\""

	node_path = "$" + node_path

	return node_path


func _generate_node_class(node: Node) -> String:
	var script: Script = node.get_script()

	if not script:
		return node.get_class()

	var code: String = script.get_source_code()
	var split_start: PoolStringArray = code.split("class_name ", true, 1)

	if len(split_start) == 1:
		return code.split("extends ", true, 1)[1].split("\n", true, 1)[0]

	return split_start[1].split("\n", true, 1)[0]


func _save_script(script: Script) -> void:
	ResourceSaver.save(script.resource_path, script.duplicate())
	# For version 3.5
	var script_editor := get_editor_interface().get_script_editor()
	if script_editor.has_method("reload_scripts"):
		script_editor.call("reload_scripts")
