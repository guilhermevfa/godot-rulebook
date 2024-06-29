@tool
class_name RulebookMainPanel
extends PanelContainer

signal add_hint(rulebook_name: String)
signal edit_hint(old_name: String, new_name: String)
signal remove_hint(rulebook_name: String)
signal make_floating
var suffix: int = 1


func get_rulebooks() -> Array[EditorRulebook]:
	var result: Array[EditorRulebook]
	for child in %TabContainer.get_children():
		if child is EditorRulebook:
			result.append(child)
	return result


func add_rulebook(rulebook: EditorRulebook, custom_position: int = 0) -> void:
	%TabContainer.add_child(rulebook)
	%TabContainer.move_child(rulebook, custom_position)
	add_hint.emit(rulebook.name)
	rulebook.name_changed.connect(on_rulebook_name_changed)
	rulebook.delete_rulebook.connect(on_delete_rulebook)


func on_rulebook_name_changed(old_name: String, new_name: String):
	edit_hint.emit(old_name, new_name)


func on_delete_rulebook(rulebook: EditorRulebook):
	remove_hint.emit(rulebook.name)


func create_rulebook() -> void:
	var new_rulebook: EditorRulebook = RulebookEditorIO.EDITOR_RULEBOOK.instantiate()
	new_rulebook.name = "Rulebook " + str(suffix)
	suffix += 1
	add_rulebook(new_rulebook, %"+ Rulebook".get_index())


func _on_tab_container_tab_clicked(tab: int):
	if tab == %TabContainer.get_tab_idx_from_control(%"+ Rulebook"):
		create_rulebook()


func _on_make_floating_pressed():
	%MakeFloating.visible = false
	make_floating.emit()


func undo_floating_panel():
	%MakeFloating.visible = true
