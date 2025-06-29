extends Node

# Multiplayer networking using Godot's built-in system
# Supports both desktop and web builds via WebSocket

signal player_joined(player_name: String, player_id: int)
signal player_left(player_id: int)
signal game_started()
signal connection_failed(error: String)
signal answer_submitted(player_id: int, answer_text: String)
signal answer_judgment(player_id: int, is_correct: bool, points: int)
signal question_completed(category: String, points: int)

var multiplayer_peer: MultiplayerPeer
var is_host: bool = false
var server_port: int = 8080
var max_players: int = 8

# Player data
var players: Dictionary = {}

func _ready():
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func create_server() -> bool:
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_server(server_port, max_players)
	
	if error != OK:
		print("Failed to create server: ", error)
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	is_host = true
	print("Server created on port ", server_port)
	return true

func join_server(ip_address: String) -> bool:
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_client(ip_address, server_port)
	
	if error != OK:
		print("Failed to join server: ", error)
		connection_failed.emit("Failed to connect to " + ip_address)
		return false
	
	multiplayer.multiplayer_peer = multiplayer_peer
	is_host = false
	print("Attempting to connect to ", ip_address, ":", server_port)
	return true

func disconnect_from_game():
	if multiplayer_peer:
		multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	players.clear()
	is_host = false

@rpc("any_peer", "call_local")
func register_player(player_name: String):
	var id = multiplayer.get_remote_sender_id()
	# If called locally (host), use the local peer ID
	if id == 0:
		id = multiplayer.get_unique_id()
	
	players[id] = {
		"name": player_name,
		"score": 0,
		"id": id
	}
	
	player_joined.emit(player_name, id)
	
	# If we're the host, send the current player list to the new player
	if is_host and id != multiplayer.get_unique_id():
		rpc_id(id, "receive_player_list", players)

@rpc("authority", "call_local")
func receive_player_list(player_list: Dictionary):
	players = player_list

@rpc("authority", "call_local")
func start_game():
	# Sync players to GameState before starting
	GameState.players = players.duplicate()
	GameState.change_state(GameState.State.PLAYING)
	game_started.emit()

@rpc("authority", "call_local")
func sync_board_data(board_data: Dictionary):
	# Clients receive the board data from host
	GameState.set_game_board(board_data)

@rpc("authority", "call_local")
func show_question_to_all(category: String, points: int, question_data: Dictionary):
	# Host sends question data to all players
	GameState.question_selected.emit(category, points, question_data)
	
	# Only host activates the buzzer system
	if is_host:
		GameState.start_question_timer()

@rpc("any_peer", "call_local")
func player_buzzed(player_id: int, timestamp: float):
	# Handle buzzer input - host determines winner
	if is_host:
		# Check if this buzz is valid and process it
		if GameState.buzzer_active and GameState.first_buzzer == -1:
			GameState.first_buzzer = player_id
			GameState.buzzer_timestamp = timestamp
			GameState.buzzer_active = false
			
			# Send buzz result to all players
			rpc("buzz_accepted", player_id, timestamp)

@rpc("authority", "call_local")
func buzz_accepted(player_id: int, timestamp: float):
	# All players receive the buzz result
	GameState.buzz_received.emit(player_id, timestamp)

@rpc("any_peer", "call_local", "reliable")
func submit_player_answer(player_id: int, answer_text: String):
	# Player sends their answer to the host
	if is_host:
		# Emit signal to show answer to host's question display
		answer_submitted.emit(player_id, answer_text)

@rpc("authority", "call_local")
func answer_judged(player_id: int, is_correct: bool, points: int):
	# Host broadcasts the judgment to all players
	answer_judgment.emit(player_id, is_correct, points)

@rpc("authority", "call_local")
func sync_question_completed(category: String, points: int):
	# Host tells all players that a specific question has been completed
	question_completed.emit(category, points)

@rpc("authority", "call_local")
func sync_player_score(player_id: int, new_score: int):
	# Sync score updates across all players
	if players.has(player_id):
		players[player_id].score = new_score
	
	# Also update GameState if it has the player
	if GameState.players.has(player_id):
		GameState.players[player_id].score = new_score
	
	# Emit signal to update UI
	GameState.score_updated.emit(player_id, new_score)

func get_local_player_id() -> int:
	return multiplayer.get_unique_id()

func get_local_player_name() -> String:
	var id = get_local_player_id()
	if players.has(id):
		return players[id].name
	return ""

func _on_peer_connected(id: int):
	print("Peer connected: ", id)

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	if players.has(id):
		var player_name = players[id].name
		players.erase(id)
		player_left.emit(id)

func _on_connection_failed():
	print("Connection to server failed")
	connection_failed.emit("Connection failed")

func _on_server_disconnected():
	print("Server disconnected")
	disconnect_from_game()
