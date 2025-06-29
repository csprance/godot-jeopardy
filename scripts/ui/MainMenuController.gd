extends Control
class_name MainMenuController

# Main menu controller - handles hosting, joining, and game data loading

@onready var host_button = $VBoxContainer/HostButton
@onready var join_button = $VBoxContainer/JoinButton
@onready var load_data_button = $VBoxContainer/LoadDataButton
@onready var host_reference_button = $VBoxContainer/HostReferenceButton
@onready var ip_input = $VBoxContainer/IPContainer/IPInput
@onready var status_label = $VBoxContainer/StatusLabel
@onready var file_dialog = $FileDialog

# NetworkManager is now an autoload - access directly as NetworkManager
var game_data: GameData

func _ready():
	# Connect button signals
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	load_data_button.pressed.connect(_on_load_data_pressed)
	host_reference_button.pressed.connect(_on_host_reference_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	
	# Get references to managers - use call_deferred to ensure Main is ready
	call_deferred("_initialize_managers")
	
	# Load default game data
	_load_default_game_data()
	
	# Set default IP to localhost
	ip_input.text = "127.0.0.1"

func _initialize_managers():
	# Connect network signals (using autoload)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.player_joined.connect(_on_player_joined)

func _load_default_game_data():
	var file_path = "res://sample_game.json"
	game_data = GameData.load_from_file(file_path)
	if game_data:
		status_label.text = "Loaded: " + game_data.title
		status_label.modulate = Color.GREEN
	else:
		status_label.text = "Failed to load default game data"
		status_label.modulate = Color.RED

func _on_host_pressed():
	if not game_data:
		_show_error("Please load game data first")
		return
	
	status_label.text = "Starting server..."
	host_button.disabled = true
	
	if NetworkManager.create_server():
		status_label.text = "Server started! Players can join at: " + _get_local_ip()
		status_label.modulate = Color.GREEN
		
		# Register host as first player
		await get_tree().create_timer(0.1).timeout
		NetworkManager.rpc("register_player", "Host")
		
		# Transition to lobby after a moment
		await get_tree().create_timer(1.0).timeout
		_transition_to_lobby()
	else:
		status_label.text = "Failed to start server"
		status_label.modulate = Color.RED
		host_button.disabled = false

func _on_join_pressed():
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		_show_error("Please enter server IP address")
		return
	
	status_label.text = "Connecting to " + ip + "..."
	join_button.disabled = true
	
	if NetworkManager.join_server(ip):
		# Register as client once connected
		await get_tree().create_timer(0.5).timeout  # Wait for connection
		NetworkManager.rpc("register_player", "Player")
	else:
		join_button.disabled = false

func _on_load_data_pressed():
	file_dialog.popup_centered_ratio(0.8)

func _on_file_selected(path: String):
	game_data = GameData.load_from_file(path)
	if game_data:
		status_label.text = "Loaded: " + game_data.title
		status_label.modulate = Color.GREEN
	else:
		status_label.text = "Failed to load: " + path
		status_label.modulate = Color.RED

func _on_connection_failed(error: String):
	status_label.text = "Connection failed: " + error
	status_label.modulate = Color.RED
	join_button.disabled = false

func _on_player_joined(player_name: String, player_id: int):
	if not NetworkManager.is_host:
		# We successfully joined as a client
		status_label.text = "Connected! Joining lobby..."
		status_label.modulate = Color.GREEN
		
		# Transition to lobby
		await get_tree().create_timer(1.0).timeout
		_transition_to_lobby()

func _transition_to_lobby():
	# Store game data in a global location
	if game_data:
		var main = get_node("/root/Main")
		if main:
			main.game_data = game_data
			main.switch_to_scene(main.lobby_scene)

func _show_error(message: String):
	status_label.text = message
	status_label.modulate = Color.RED

func _on_host_reference_pressed():
	# Open the host reference view in a new window or replace current scene
	var host_ref_scene = load("res://scenes/ui/HostReference.tscn")
	if host_ref_scene:
		get_tree().change_scene_to_packed(host_ref_scene)
	else:
		_show_error("Failed to load Host Reference scene")

func _get_local_ip() -> String:
	# For local testing, always use localhost
	# In production, this could show the actual network IP
	return "127.0.0.1"