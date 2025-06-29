extends Node

# Multiplayer networking using Godot's built-in system
# Supports both desktop and web builds via WebSocket

signal player_joined(player_name: String, player_id: int)
signal player_left(player_id: int)
signal game_started()
signal connection_failed(error: String)

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
	game_started.emit()

@rpc("any_peer", "call_local")
func player_buzzed(player_id: int, timestamp: float):
	# Handle buzzer input - host determines winner
	if is_host:
		GameState.handle_buzz(player_id, timestamp)

@rpc("authority", "call_local")
func update_score(player_id: int, new_score: int):
	if players.has(player_id):
		players[player_id].score = new_score

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
