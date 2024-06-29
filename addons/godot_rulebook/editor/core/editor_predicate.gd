@tool
class_name EditorPredicate
extends VBoxContainer

var monitorable_type: String
var monitorable_script: Script


func _ready():
	update_monitorable_type_options()


func update_monitorable_type_options():
	var selected_idx: int = %MonitorableTypeOptions.selected
	var selected_text: String = %MonitorableTypeOptions.get_item_text(selected_idx) if selected_idx != -1 else ""
	
	%MonitorableTypeOptions.clear()
	for class_dict in ProjectSettings.get_global_class_list():
		if inherits_monitorable(class_dict):
			var option: String = class_dict["class"].trim_prefix("Monitorable")
			%MonitorableTypeOptions.add_item(option)
	
	if selected_text != "":
		for index in range(%MonitorableTypeOptions.item_count):
			if %MonitorableTypeOptions.get_item_text(index) == selected_text:
				%MonitorableTypeOptions.select(index)
				break


func inherits_monitorable(class_dict: Dictionary) -> bool:
	var base_class: String = class_dict["base"]
	if base_class == "Monitorable":
		return true
	else:
		for dict in ProjectSettings.get_global_class_list():
			if dict["class"] == base_class:
				return inherits_monitorable(dict)
	return false


func _on_add_premise_pressed():
	add_premise(RulebookEditorIO.EDITOR_PREMISE.instantiate())


func add_premise(premise: EditorPremise):
	%Premises.add_child(premise)
	premise.set_monitorable_hints(monitorable_script)
	%Premises.move_child(premise, %AddPremise.get_index())


func _on_monitorable_type_item_selected(index: int):
	set_monitorable(%MonitorableTypeOptions.get_item_text(index))


func set_monitorable(_monitorable_type: String):
	monitorable_type = _monitorable_type
	for class_dict in ProjectSettings.get_global_class_list():
		if class_dict["class"] == monitorable_type \
		or class_dict["class"] == "Monitorable" + monitorable_type:
			monitorable_script = load(class_dict["path"])
	
	for child in %Premises.get_children():
		if child is EditorPremise:
			child.set_monitorable_hints(monitorable_script)


func get_premises() -> Array[EditorPremise]:
	var result: Array[EditorPremise]
	for child in %Premises.get_children():
		if child is EditorPremise:
			result.append(child)
	return result


func _on_delete_monitorable_pressed():
	queue_free()


func save_info(predicate: Predicate):
	predicate.monitorable_type = monitorable_type
	predicate.monitorable_id = %MonitorableIdentifier.text


func load_info(predicate: Predicate):
	update_monitorable_type_options()
	for index in range(%MonitorableTypeOptions.item_count):
		var type: String = "Monitorable" + %MonitorableTypeOptions.get_item_text(index)
		if type == predicate.monitorable_type:
			# item_selected signal is not emitted when select() is called. Godot bug?
			%MonitorableTypeOptions.select(index)
			%MonitorableTypeOptions.item_selected.emit(index)
			break
	%MonitorableIdentifier.set_text(predicate.monitorable_id)
