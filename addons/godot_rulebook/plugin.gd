@tool
extends EditorPlugin

const MAIN_PANEL := preload("res://addons/godot_rulebook/editor/main_panel.tscn")
const ICON := preload("res://addons/godot_rulebook/editor/assets/icons/icon.svg")
const MANAGER_PATH := "res://addons/godot_rulebook/manager.gd"
const AUTOLOAD_NAME := "RulebooksManager"


var window : Window
var main_panel_instance: RulebookMainPanel
var floating_window_mode: bool = false


# Initialization of the plugin.
func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, MANAGER_PATH)
	main_panel_instance = MAIN_PANEL.instantiate()
	main_panel_instance.make_floating.connect(make_floating_window)
	main_screen_changed.connect(check_window_focus)
	# Add the main panel to the editor's main viewport.
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	for rulebook in RulebookEditorIO.load_all_saved():
		main_panel_instance.add_rulebook(rulebook)
	main_panel_instance.add_hint.connect(RulebooksManager.add_hint)
	main_panel_instance.edit_hint.connect(RulebooksManager.edit_hint)
	main_panel_instance.remove_hint.connect(RulebooksManager.remove_hint)
	# Hide the main panel. Very much required.
	_make_visible(false)


# Clean-up of the plugin.
func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	if main_panel_instance:
		main_panel_instance.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if main_panel_instance:
		main_panel_instance.visible = visible


func _save_external_data() -> void:
	for rulebook in main_panel_instance.get_rulebooks():
		RulebookEditorIO.save_on_disk(rulebook)


func _get_plugin_name() -> String:
	return "Rulebook"


func _get_plugin_icon() -> Texture2D:
	return ICON


func make_floating_window():
	window = Window.new()
	window.close_requested.connect(undo_floating_window)
	EditorInterface.get_editor_main_screen().remove_child(main_panel_instance)
	window.add_child(main_panel_instance)
	window.set_size(main_panel_instance.get_size())
	window.set_title("Rulebook Editor")
	get_viewport().add_child(window)
	window.set_initial_position(Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN)
	floating_window_mode = true


func undo_floating_window():
	window.remove_child(main_panel_instance)
	window.queue_free()
	main_panel_instance.undo_floating_panel()
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	floating_window_mode = false


func check_window_focus(screen_name: String):
	if floating_window_mode and screen_name == _get_plugin_name():
		window.grab_focus()
