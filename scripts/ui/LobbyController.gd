extends Control
class_name LobbyController

# Lobby controller - manages pre-game player list and game start

@onready var game_title_label = $HBoxContainer/LeftPanel/GameInfo/GameTitle
@onready var player_count_label = $HBoxContainer/LeftPanel/GameInfo/PlayerCount
@onready var server_ip_label = $HBoxContainer/LeftPanel/GameInfo/ServerIP
@onready var start_button = $HBoxContainer/LeftPanel/Controls/StartButton
@onready var back_button = $HBoxContainer/LeftPanel/Controls/BackButton
@onready var players_list = $HBoxContainer/RightPanel/PlayersList
@onready var status_label = $StatusLabel

# NetworkManager and GameState are now autoloads - access directly
var game_data: GameData
var players: Dictionary = {}

func _ready():
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Initialize managers after scene tree is ready
	call_deferred("_initialize_managers")

func _initialize_managers():
	# Get game data from main
	var main_node = get_node_or_null("/root/Main")
	if main_node:
		game_data = main_node.game_data
	
	# Connect network signals (using autoloads)
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.player_left.connect(_on_player_left)
	NetworkManager.game_started.connect(_on_game_started)
	
	# Initialize display
	_update_display()
	
	# Only host can start game
	start_button.visible = NetworkManager.is_host

func _update_display():
	# Update game info
	if game_data:
		game_title_label.text = "Game: " + game_data.title
	else:
		game_title_label.text = "Game: No data loaded"
	
	# Update player count
	player_count_label.text = "Players: " + str(players.size()) + "/8 (min: 1)"
	
	# Update server IP
	if NetworkManager.is_host:
		server_ip_label.text = "Server: " + _get_local_ip() + ":8080"
	else:
		server_ip_label.text = "Connected to server"
	
	# Update start button
	if NetworkManager.is_host:
		start_button.disabled = players.size() < 1
		status_label.text = "Need at least 1 player to start" if players.size() < 1 else "Ready to start!"
	else:
		status_label.text = "Waiting for host to start game..."
	
	# Update players list
	_update_players_list()

func _update_players_list():
	# Clear existing player cards
	for child in players_list.get_children():
		child.queue_free()
	
	# Add player cards
	for player_id in players:
		var player_data = players[player_id]
		var player_card = _create_player_card(player_data)
		players_list.add_child(player_card)

func _create_player_card(player_data: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.set_custom_minimum_size(Vector2(0, 60))
	
	var hbox = HBoxContainer.new()
	card.add_child(hbox)
	
	var name_label = Label.new()
	name_label.text = player_data.get("name", "Unknown")
	if player_data.get("id", -1) == NetworkManager.get_local_player_id():
		name_label.text += " (You)"
	hbox.add_child(name_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	var score_label = Label.new()
	score_label.text = "Score: " + str(player_data.get("score", 0))
	hbox.add_child(score_label)
	
	return card

func _on_start_pressed():
	if not NetworkManager.is_host:
		return
	
	if players.size() < 1:
		status_label.text = "Need at least 1 player to start"
		status_label.modulate = Color.RED
		return
	
	status_label.text = "Starting game..."
	start_button.disabled = true
	
	# Generate game board
	_generate_game_board()
	
	# Start the game
	NetworkManager.rpc("start_game")

func _generate_game_board():
	if not game_data:
		print("No game data available for board generation")
		return
	
	var board = BoardGenerator.generate_board(game_data)
	if board.is_empty():
		print("Failed to generate board")
		return
	
	# Set board in game state
	GameState.set_game_board(board)
	
	# Send board data to all clients
	NetworkManager.rpc("sync_board_data", board)
	
	# Debug print
	BoardGenerator.print_board_summary(board)

func _on_back_pressed():
	# Disconnect from game
	NetworkManager.disconnect_from_game()
	
	# Return to main menu
	var main = get_node("/root/Main")
	if main and main.has_method("switch_to_scene"):
		main.switch_to_scene(main.main_menu_scene)

func _on_player_joined(player_name: String, player_id: int):
	players[player_id] = {
		"name": player_name,
		"id": player_id,
		"score": 0
	}
	_update_display()

func _on_player_left(player_id: int):
	players.erase(player_id)
	_update_display()

func _on_game_started():
	# Transition to game board
	var main = get_node("/root/Main")
	if main and main.has_method("switch_to_scene"):
		main.switch_to_scene(main.game_board_scene)

func update_player_list(new_players: Dictionary):
	players = new_players
	_update_display()

func _get_local_ip() -> String:
	# For local testing, always use localhost
	return "127.0.0.1"