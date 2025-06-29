extends Control
class_name GameBoardController

# Game board controller - manages the main game interface

@onready var game_title = $MainContainer/TopBar/GameTitle
@onready var timer_label = $MainContainer/TopBar/Timer
@onready var categories_container = $MainContainer/GameArea/BoardContainer/CategoriesContainer
@onready var questions_grid = $MainContainer/GameArea/BoardContainer/QuestionsGrid
@onready var players_list = $MainContainer/GameArea/SidePanel/PlayersList
@onready var buzzer_button = $MainContainer/GameArea/SidePanel/BuzzerButton
@onready var status_label = $MainContainer/StatusBar/StatusLabel
@onready var current_player_label = $MainContainer/StatusBar/CurrentPlayer

# NetworkManager and GameState are now autoloads - access directly
var game_board: Dictionary = {}
var players: Dictionary = {}

# Question display popup
var question_popup: QuestionDisplay

# Timer
var timer_duration: float = 30.0
var timer_remaining: float = 0.0
var timer_active: bool = false

func _ready():
	# Connect button signals
	buzzer_button.pressed.connect(_on_buzzer_pressed)
	
	# Initialize managers after scene tree is ready
	call_deferred("_initialize_managers")

func _initialize_managers():
	# Connect game state signals (using autoloads)
	GameState.board_updated.connect(_on_board_updated)
	GameState.question_selected.connect(_on_question_selected)
	GameState.buzz_received.connect(_on_buzz_received)
	GameState.score_updated.connect(_on_score_updated)
	
	# Connect network signals (using autoloads)
	NetworkManager.player_left.connect(_on_player_left)
	NetworkManager.question_completed.connect(_on_question_completed_received)
	
	# Check if board data already exists (in case signal was emitted before we connected)
	if not GameState.game_board.is_empty():
		print("GameBoardController: Found existing board data with ", GameState.game_board.size(), " categories")
		_on_board_updated(GameState.game_board)
	
	# Initialize players from NetworkManager
	players = NetworkManager.players.duplicate()
	
	# Initialize display
	_update_display()
	
	# Load question popup scene
	var question_scene = load("res://scenes/ui/QuestionDisplay.tscn")
	if question_scene:
		question_popup = question_scene.instantiate()
		add_child(question_popup)
		question_popup.visible = false
	else:
		print("Warning: Failed to load QuestionDisplay scene")

func _process(delta):
	if timer_active and timer_remaining > 0:
		timer_remaining -= delta
		timer_label.text = str(int(timer_remaining))
		
		if timer_remaining <= 0:
			_on_timer_expired()

func _update_display():
	# Update player list
	_update_players_list()
	
	# Update status
	status_label.text = "Game in progress"
	current_player_label.text = "Current Player: None"

func _update_players_list():
	# Clear existing player displays
	for child in players_list.get_children():
		child.queue_free()
	
	# Create player score displays
	for player_id in players:
		var player_data = players[player_id]
		var player_display = _create_player_display(player_data)
		players_list.add_child(player_display)

func _create_player_display(player_data: Dictionary) -> Control:
	var container = PanelContainer.new()
	container.set_custom_minimum_size(Vector2(0, 50))
	
	var vbox = VBoxContainer.new()
	container.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = player_data.get("name", "Unknown")
	if player_data.get("id", -1) == NetworkManager.get_local_player_id():
		name_label.text += " (You)"
	vbox.add_child(name_label)
	
	var score_label = Label.new()
	score_label.text = "$" + str(player_data.get("score", 0))
	vbox.add_child(score_label)
	
	return container

func _create_game_board():
	if game_board.is_empty():
		return
	
	# Clear existing board
	for child in categories_container.get_children():
		child.queue_free()
	for child in questions_grid.get_children():
		child.queue_free()
	
	var categories = game_board.keys()
	questions_grid.columns = categories.size()
	
	# Create category headers
	for category in categories:
		var header = _create_category_header(category)
		categories_container.add_child(header)
	
	# Get point values (assume 5 rows)
	var point_values = [200, 400, 600, 800, 1000]
	
	# Create question buttons in grid
	for row in range(5):
		for col in range(categories.size()):
			var category = categories[col]
			var questions = game_board[category]
			
			if row < questions.size():
				var question_data = questions[row]
				var button = _create_question_button(question_data, category)
				questions_grid.add_child(button)
			else:
				# Empty slot
				var empty = Control.new()
				empty.custom_minimum_size = Vector2(120, 80)
				questions_grid.add_child(empty)

func _create_category_header(category: String) -> Control:
	var header = Button.new()
	header.text = category
	header.custom_minimum_size = Vector2(120, 60)
	header.disabled = true
	return header

func _create_question_button(question_data: Dictionary, category: String) -> Control:
	var button = Button.new()
	button.custom_minimum_size = Vector2(120, 80)
	
	var points = question_data.get("points", 0)
	button.text = "$" + str(points)
	
	# Don't show Daily Double indicator on the board - keep it hidden until selected
	
	if question_data.get("completed", false):
		button.disabled = true
		button.text = ""
	else:
		button.pressed.connect(_on_question_button_clicked.bind(category, points))
	
	return button

func _on_board_updated(board_data: Dictionary):
	print("GameBoardController: Received board data with ", board_data.size(), " categories")
	game_board = board_data
	_create_game_board()
	status_label.text = "Board loaded - Select a question!"

func _on_question_button_clicked(category: String, points: int):
	# Only allow question selection when it's the right time and player is host
	if GameState.current_state != GameState.State.PLAYING:
		return
	
	if not NetworkManager.is_host:
		status_label.text = "Only the host can select questions!"
		return
	
	# Find and send question to all players
	var question_data = _find_question(category, points)
	if question_data:
		NetworkManager.rpc("show_question_to_all", category, points, question_data)

func _on_question_selected(category: String, points: int, question_data: Dictionary):
	# This is called via RPC for all players
	if question_data and question_popup:
		question_popup.show_question(question_data, category, points)
		
		# Timer is started by host via NetworkManager
		# Keep the main buzzer disabled since popup has its own buzz button
		buzzer_button.disabled = true
		status_label.text = "Question active - BUZZ to answer!"

func _find_question(category: String, points: int) -> Dictionary:
	if not game_board.has(category):
		return {}
	
	var questions = game_board[category]
	for question in questions:
		if question.get("points", 0) == points and not question.get("completed", false):
			return question
	
	return {}

func _start_question_timer():
	timer_remaining = timer_duration
	timer_active = true
	timer_label.modulate = Color.WHITE

func _stop_timer():
	timer_active = false
	timer_label.modulate = Color.GRAY

func _on_timer_expired():
	_stop_timer()
	buzzer_button.disabled = true
	status_label.text = "Time's up! No one answered."
	
	if question_popup:
		question_popup.show_answer()

func _on_buzzer_pressed():
	if not timer_active:
		return
	
	# Send buzz to network
	var timestamp = Time.get_time_dict_from_system().second
	NetworkManager.rpc("player_buzzed", NetworkManager.get_local_player_id(), timestamp)
	
	buzzer_button.disabled = true
	status_label.text = "Buzzed! Waiting for response..."

func _on_buzz_received(player_id: int, timestamp: float):
	_stop_timer()
	buzzer_button.disabled = true
	
	var player_name = players.get(player_id, {}).get("name", "Unknown")
	status_label.text = player_name + " buzzed first!"
	
	# Show answer input or handle answer
	if question_popup:
		question_popup.handle_buzz(player_id)

func _on_score_updated(player_id: int, new_score: int):
	if players.has(player_id):
		players[player_id]["score"] = new_score
		_update_players_list()

func _on_player_left(player_id: int):
	players.erase(player_id)
	_update_players_list()

func update_player_list(new_players: Dictionary):
	players = new_players
	_update_players_list()

func update_scores(scores: Dictionary):
	players = scores
	_update_players_list()

func _on_question_completed_received(category: String, points: int):
	# Mark the question as completed in our local board data
	if game_board.has(category):
		var questions = game_board[category]
		for question in questions:
			if question.get("points", 0) == points:
				question["completed"] = true
				break
	
	# Refresh the board UI to show the completed state
	_create_game_board()