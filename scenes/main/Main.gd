extends Control

# Main game manager - orchestrates all game phases and scene transitions
class_name Main

# UIManager is now an autoload - access directly as UIManager

# Current scene references
var current_scene: Node
var main_menu_scene: PackedScene = preload("res://scenes/ui/MainMenu.tscn")
var lobby_scene: PackedScene = preload("res://scenes/ui/Lobby.tscn")
var game_board_scene: PackedScene = preload("res://scenes/ui/GameBoard.tscn")
var host_reference_scene: PackedScene = preload("res://scenes/ui/HostReference.tscn")

# Shared game data
var game_data: GameData

func _ready():
	add_to_group("main")
	
	# Start with main menu
	switch_to_scene(main_menu_scene)
	
	# Connect network signals (autoloads)
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.player_left.connect(_on_player_left)
	NetworkManager.game_started.connect(_on_game_started)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	
	# Connect game state signals (autoloads)
	GameState.state_changed.connect(_on_game_state_changed)

func switch_to_scene(scene_resource: PackedScene):
	if not scene_resource:
		print("Error: Cannot switch to null scene")
		return
		
	if current_scene:
		current_scene.queue_free()
	
	current_scene = scene_resource.instantiate()
	add_child(current_scene)

func _on_player_joined(player_name: String, player_id: int):
	print("Player joined: ", player_name, " (ID: ", player_id, ")")

func _on_player_left(player_id: int):
	print("Player left: ", player_id)

func _on_game_started():
	switch_to_scene(game_board_scene)

func _on_connection_failed(error: String):
	print("Connection failed: ", error)

func _on_game_state_changed(new_state: GameState.State):
	match new_state:
		GameState.State.LOBBY:
			switch_to_scene(lobby_scene)
		GameState.State.PLAYING:
			switch_to_scene(game_board_scene)
		GameState.State.GAME_OVER:
			# Could switch to results scene
			pass
