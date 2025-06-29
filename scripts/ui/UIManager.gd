extends Node

# Coordinates UI transitions and updates across all game scenes

signal scene_transition_requested(scene_name: String)

func _ready():
	add_to_group("ui_manager")

# Helper functions for common UI operations
func show_loading_screen():
	# Could implement loading overlay
	pass

func hide_loading_screen():
	# Could hide loading overlay
	pass

func show_error_dialog(message: String):
	print("Error: ", message)
	# Could implement error dialog

func show_confirmation_dialog(message: String, callback: Callable):
	print("Confirm: ", message)
	# Could implement confirmation dialog
	callback.call(true) # For now, auto-confirm

func update_player_list(players: Dictionary):
	# Broadcast to current scene if it needs player updates
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("update_player_list"):
		current_scene.update_player_list(players)

func update_scores(scores: Dictionary):
	# Broadcast score updates to current scene
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("update_scores"):
		current_scene.update_scores(scores)
