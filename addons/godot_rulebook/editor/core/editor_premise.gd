@tool
class_name EditorPremise
extends HBoxContainer

var monitorable_script: Script


func _ready():
	update_operator_options()
	update_operand_type_list()


func update_operator_options():
	var selected_idx: int = %OperatorOption.selected
	var selected_text: String = %OperatorOption.get_item_text(selected_idx) if selected_idx != -1 else ""
	
	%OperatorOption.clear()
	for operator in Premise.OPERATOR_HINTS:
		%OperatorOption.add_item(operator)
	
	if selected_text != "":
		for index in range(%OperatorOption.item_count):
			if %OperatorOption.get_item_text(index) == selected_text:
				%OperatorOption.select(index)
				break


func update_operand_type_list():
	var selected_text: String = ""
	if not %OperandTypeList.get_selected_items().is_empty():
		var selected_idx: int = %OperandTypeList.get_selected_items()[0]
		selected_text = %OperandTypeList.get_item_text(selected_idx)
	
	%OperandTypeList.clear()
	for type: String in Premise.OperandType.keys():
		%OperandTypeList.add_item(type)
	
	if selected_text != "":
		for index in range(%OperandTypeList.item_count):
			if %OperandTypeList.get_item_text(index) == selected_text:
				%OperandTypeList.select(index)
				break


func set_monitorable_hints(script: Script) -> void:
	if monitorable_script != script:
		monitorable_script = script
		
		%AttributeOption.clear()
		%AttributeField.get_node("AttributeOption").clear()
		if script:
			for attribute in get_attribute_hints():
				%AttributeOption.add_item(attribute)
				%AttributeField.get_node("AttributeOption").add_item(attribute)


func get_attribute_hints() -> Array[String]:
	var result: Array[String]
	for property in monitorable_script.get_script_property_list():
		if is_valid_attribute(property["name"]):
			result.append(property["name"])
	return result


func is_valid_attribute(attr: String) -> bool:
	var result: bool = (
		attr != "holder"
		and attr != "rulebook"
		and attr != "rulebook_name"
		and attr != "auto_monitoring"
		and not attr.ends_with(".gd")
	)
	return result


func _on_operand_type_selected(index: int) -> void:
	var new_type: String = %OperandTypeList.get_item_text(index)
	change_active_field(new_type)


func change_active_field(new_field: String):
	for field: Control in [%ConstantField, %AttributeField, %VariableField]:
		field.visible = false
	get_node("%" + new_field.capitalize() + "Field").visible = true


func _on_delete_premise_pressed():
	queue_free()


func save_info(premise: Premise):
	premise.monitorable_type = monitorable_script.get_global_name()
	premise.attribute = %AttributeOption.get_item_text(%AttributeOption.selected)
	premise.operator = %OperatorOption.get_item_text(%OperatorOption.selected)
	premise.operand_type = %OperandTypeList.get_selected_items()[0]
	match premise.operand_type:
		Premise.OperandType.CONSTANT:
			premise.operand = %ConstantField.text
		Premise.OperandType.ATTRIBUTE:
			var option_button: OptionButton = %AttributeField.get_node("AttributeOption")
			premise.operand = option_button.get_item_text(option_button.selected)
		Premise.OperandType.VARIABLE:
			premise.operand = %VariableField.text


func load_info(premise: Premise):
	%AttributeOption.select(get_idx_by_text(%AttributeOption, premise.attribute))
	
	update_operator_options()
	var operator_idx: int = get_idx_by_text(%OperatorOption, premise.operator)
	%OperatorOption.select(operator_idx)
	%OperatorOption.item_selected.emit(operator_idx)
	
	update_operand_type_list()
	%OperandTypeList.select(premise.operand_type)
	%OperandTypeList.item_selected.emit(premise.operand_type)
	
	match premise.operand_type:
		Premise.OperandType.CONSTANT:
			%ConstantField.text = premise.operand
		Premise.OperandType.ATTRIBUTE:
			var option_button: OptionButton = %AttributeField.get_node("AttributeOption")
			option_button.select(get_idx_by_text(option_button, premise.operand))
		Premise.OperandType.VARIABLE:
			%VariableField.text = premise.operand


func get_idx_by_text(option_button: OptionButton, text: String) -> int:
	for index in range(option_button.item_count):
		if option_button.get_item_text(index) == text:
			return index
	return -1
