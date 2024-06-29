@tool
class_name EditorRulebook
extends PanelContainer

signal delete_rulebook(rulebook: EditorRulebook)
signal name_changed(old: String, new: String)


func _on_rulebook_name_text_changed(new_text: String) -> void:
	name_changed.emit(name, new_text)
	name = new_text


func _on_add_rule_pressed() -> void:
	add_rule(RulebookEditorIO.EDITOR_RULE.instantiate())


func add_rule(rule: EditorRule) -> void:
	%Rules.add_child(rule)
	%Rules.move_child(rule, %AddRule.get_index())


func get_rules() -> Array[EditorRule]:
	var result: Array[EditorRule]
	for child in %Rules.get_children():
		if child is EditorRule:
			result.append(child)
	return result


func _on_delete_rulebook_pressed() -> void:
	delete_rulebook.emit(self)
	queue_free()


func save_info(rulebook: Rulebook) -> void:
	rulebook.name = name


func load_info(rulebook: Rulebook) -> void:
	%RulebookName.rename(rulebook.name)
