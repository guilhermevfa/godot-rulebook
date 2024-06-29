@tool
extends Node

var rulebook_names: Array[String]
var rulebooks: Dictionary # String: CompiledRulebook


func _init() -> void:
	if not Engine.is_editor_hint():
		for rulebook in RulebookIO.load_all():
			rulebooks[rulebook.name] = NetworkBuilder.compile_rulebook(rulebook)


func add_hint(_name: String) -> void:
	rulebook_names.append(_name)


func edit_hint(old: String, new: String) -> void:
	rulebook_names.erase(old)
	rulebook_names.append(new)


func remove_hint(_name: String) -> void:
	rulebook_names.erase(_name)


func get_rulebook_hints() -> String:
	return ",".join(rulebook_names)


func get_rulebook(rulebook_name: String) -> CompiledRulebook:
	return rulebooks[rulebook_name]
