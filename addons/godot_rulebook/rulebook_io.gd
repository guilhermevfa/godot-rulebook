class_name RulebookIO


const SAVED_RULEBOOKS_PATH := "res://addons/godot_rulebook/editor/saved_rulebooks/"
#static var COMPILED_RULEBOOKS_PATH := "res://addons/godot_rulebook/compiled_rulebooks/"


static func load_all() -> Array[Rulebook]:
	var rulebooks: Array[Rulebook]
	var dir := DirAccess.open(SAVED_RULEBOOKS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var scene: PackedScene = ResourceLoader.load(SAVED_RULEBOOKS_PATH + file_name)
			var saved_rulebook: Rulebook = scene.instantiate()
			if saved_rulebook:
				rulebooks.append(saved_rulebook)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return rulebooks


static func save(rulebook: Rulebook) -> void:
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(rulebook)
	if result == OK:
		if not DirAccess.dir_exists_absolute(SAVED_RULEBOOKS_PATH):
			DirAccess.make_dir_absolute(SAVED_RULEBOOKS_PATH)
		var error = ResourceSaver.save(packed_scene, SAVED_RULEBOOKS_PATH + rulebook.name + ".tscn")
		if error != OK:
			push_error("An error occurred while saving the Rulebook to disk.")
