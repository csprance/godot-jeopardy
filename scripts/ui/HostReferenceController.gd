extends Control
class_name HostReferenceController

# Host Reference - shows all questions, answers, and Daily Doubles for host
# This is meant to run on a separate instance for host reference

@onready var title_label = $MainContainer/Header/Title
@onready var connection_status = $MainContainer/Header/ConnectionStatus
@onready var players_list = $MainContainer/GameStatus/PlayersPanel/PlayersList
@onready var game_status_label = $MainContainer/GameStatus/StatusPanel/GameStatusLabel
@onready var reference_container = $MainContainer/ScrollContainer/ReferenceContainer
@onready var connect_button = $MainContainer/Controls/ConnectButton
@onready var close_button = $MainContainer/Controls/CloseButton

var game_data: GameData
var current_board: Dictionary = {}
var is_connected: bool = false
var current_question_category: String = ""
var current_question_points: int = 0
var question_panels: Dictionary = {}  # Store references to question panels for highlighting
var current_players: Dictionary = {}
var current_buzzer_player: String = ""

func _ready():
	# Connect button signals
	connect_button.pressed.connect(_on_connect_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Connect to network signals for real-time updates
	_connect_network_signals()
	
	# Try to load game data
	_load_game_data()

func _connect_network_signals():
	# Connect to game state signals
	GameState.question_selected.connect(_on_question_selected_update)
	GameState.buzz_received.connect(_on_buzz_received_update)
	GameState.score_updated.connect(_on_score_updated_update)
	
	# Connect to network signals
	NetworkManager.answer_judgment.connect(_on_answer_judgment_update)
	NetworkManager.question_completed.connect(_on_question_completed_update)
	NetworkManager.player_joined.connect(_on_player_joined_update)
	NetworkManager.player_left.connect(_on_player_left_update)

func _load_game_data():
	# Load the same game data file used by the main game
	var file_path = "res://sample_game.json"
	game_data = GameData.load_from_file(file_path)
	if game_data:
		print("Host Reference: Loaded game data with ", game_data.get_categories().size(), " categories")
		_display_all_questions()
	else:
		print("Host Reference: Failed to load game data file")

func _display_all_questions():
	if not game_data:
		return
	
	# Clear existing content
	for child in reference_container.get_children():
		child.queue_free()
	
	var categories = game_data.get_categories()
	var point_values = game_data.get_point_values()
	
	# Create reference display for each category
	for category in categories:
		_create_category_section(category, point_values)

func _create_category_section(category: String, point_values: Array):
	# Category header
	var category_header = Label.new()
	category_header.text = "=== " + category + " ==="
	category_header.add_theme_font_size_override("font_size", 20)
	category_header.modulate = Color.YELLOW
	reference_container.add_child(category_header)
	
	# Get all questions for this category
	var questions = game_data.get_questions_by_category(category)
	
	# Create a reference entry for each point value
	for i in range(point_values.size()):
		var target_points = point_values[i]
		var best_question = _find_question_for_points(questions, target_points)
		
		if best_question:
			_create_question_reference(best_question, target_points)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	reference_container.add_child(spacer)

func _find_question_for_points(questions: Array, target_points: int) -> Dictionary:
	# Find the best matching question for the target points
	# This uses the same logic as BoardGenerator
	var best_question = {}
	var best_score = -1
	
	for question in questions:
		var point_range = question.get("point_range", {})
		var min_points = point_range.get("min", 0)
		var max_points = point_range.get("max", 1000)
		
		var score = _calculate_question_fitness(target_points, min_points, max_points)
		if score > best_score:
			best_score = score
			best_question = question
	
	return best_question

func _calculate_question_fitness(target: int, min_val: int, max_val: int) -> float:
	# Same fitness calculation as BoardGenerator
	if target >= min_val and target <= max_val:
		var center = (min_val + max_val) / 2.0
		var distance_from_center = abs(target - center)
		var range_size = max_val - min_val
		return 100.0 - (distance_from_center / range_size * 50.0)
	
	var distance = min(abs(target - min_val), abs(target - max_val))
	return max(0.0, 50.0 - distance / 10.0)

func _create_question_reference(question_data: Dictionary, points: int):
	# Create a panel for this question
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _create_question_style())
	reference_container.add_child(panel)
	
	# Store panel reference for highlighting
	var category = question_data.get("category", "")
	var key = category + "_" + str(points)
	question_panels[key] = panel
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Points and Daily Double indicator
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var points_label = Label.new()
	points_label.text = "$" + str(points)
	points_label.add_theme_font_size_override("font_size", 16)
	points_label.modulate = Color.GREEN
	header.add_child(points_label)
	
	# Check if this might be a Daily Double (randomly placed, so we simulate)
	var is_daily_double = _check_if_daily_double(points)
	if is_daily_double:
		var dd_label = Label.new()
		dd_label.text = " *** DAILY DOUBLE ***"
		dd_label.add_theme_font_size_override("font_size", 16)
		dd_label.modulate = Color.ORANGE
		header.add_child(dd_label)
	
	# Question text
	var question_label = Label.new()
	question_label.text = "Q: " + question_data.get("question", "")
	question_label.add_theme_font_size_override("font_size", 14)
	question_label.modulate = Color.WHITE
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(question_label)
	
	# Answer text
	var answer_label = Label.new()
	answer_label.text = "A: " + question_data.get("answer", "")
	answer_label.add_theme_font_size_override("font_size", 14)
	answer_label.modulate = Color.CYAN
	answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(answer_label)

func _create_question_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style.set_border_width_all(1)
	style.border_color = Color(0.4, 0.4, 0.5, 1.0)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.content_margin_left = 15
	style.content_margin_right = 15
	return style

func _check_if_daily_double(points: int) -> bool:
	# Since Daily Doubles are placed randomly, we can't know exactly where they'll be
	# But we can note that they're typically not on the lowest point values
	# This is just for reference - actual Daily Doubles are determined by BoardGenerator
	return points >= 600  # Just a placeholder indicator

func _on_connect_pressed():
	if is_connected:
		_disconnect_from_game()
	else:
		_connect_to_game()

func _connect_to_game():
	# Connect to the same host as a silent observer
	var host_ip = "127.0.0.1"  # Localhost for testing
	
	print("Host Reference: Attempting to connect to game at ", host_ip)
	
	# Connect as a client to observe the game
	if NetworkManager.join_server(host_ip):
		# Wait a moment then register as a silent observer
		await get_tree().create_timer(0.5).timeout
		NetworkManager.rpc("register_player", "[HOST REF]")
		is_connected = true
		connection_status.text = "Connected (Observer)"
		connect_button.text = "Disconnect"
	else:
		connection_status.text = "Failed to connect"
		connection_status.modulate = Color.RED

func _disconnect_from_game():
	NetworkManager.disconnect_from_game()
	is_connected = false
	connection_status.text = "Not Connected"
	connection_status.modulate = Color.WHITE
	connect_button.text = "Connect as Host Ref"
	
	# Clear current highlights
	_clear_current_highlight()
	current_question_category = ""
	current_question_points = 0

func _on_close_pressed():
	# Return to main menu or close the window
	get_tree().quit()

func update_board_state(board_data: Dictionary):
	# Called when board state changes to show which questions have been used
	current_board = board_data
	# Could add visual indicators for completed questions
	print("Host Reference: Board state updated")

# Real-time game update handlers
func _on_question_selected_update(category: String, points: int, question_data: Dictionary):
	# Highlight the currently selected question
	_clear_current_highlight()
	current_question_category = category
	current_question_points = points
	_highlight_current_question()
	
	# Update connection status with current question info
	var dd_text = " (DAILY DOUBLE!)" if question_data.get("daily_double", false) else ""
	connection_status.text = "CURRENT: " + category + " $" + str(points) + dd_text
	connection_status.modulate = Color.YELLOW

func _on_buzz_received_update(player_id: int, timestamp: float):
	# Show who buzzed
	var player_name = _get_player_name(player_id)
	current_buzzer_player = player_name
	connection_status.text = player_name + " BUZZED! - " + current_question_category + " $" + str(current_question_points)
	connection_status.modulate = Color.ORANGE

func _on_score_updated_update(player_id: int, new_score: int):
	# Update player scores
	if current_players.has(player_id):
		current_players[player_id]["score"] = new_score
	_update_players_display()

func _on_answer_judgment_update(player_id: int, is_correct: bool, points: int):
	# Show judgment result
	var player_name = _get_player_name(player_id)
	var result_text = "CORRECT" if is_correct else "WRONG"
	var points_text = "+" + str(points) if is_correct else "-" + str(points)
	connection_status.text = player_name + " " + result_text + " (" + points_text + " pts)"
	connection_status.modulate = Color.GREEN if is_correct else Color.RED

func _on_question_completed_update(category: String, points: int):
	# Mark question as completed
	_mark_question_completed(category, points)
	connection_status.text = "Question completed - Ready for next"
	connection_status.modulate = Color.CYAN

func _on_player_joined_update(player_name: String, player_id: int):
	# Add player to tracking
	current_players[player_id] = {"name": player_name, "score": 0}
	_update_players_display()

func _on_player_left_update(player_id: int):
	# Remove player from tracking
	current_players.erase(player_id)
	_update_players_display()

# Visual update methods
func _highlight_current_question():
	var key = current_question_category + "_" + str(current_question_points)
	if question_panels.has(key):
		var panel = question_panels[key]
		panel.add_theme_stylebox_override("panel", _create_highlighted_style())

func _clear_current_highlight():
	if current_question_category != "" and current_question_points > 0:
		var key = current_question_category + "_" + str(current_question_points)
		if question_panels.has(key):
			var panel = question_panels[key]
			panel.add_theme_stylebox_override("panel", _create_question_style())

func _mark_question_completed(category: String, points: int):
	var key = category + "_" + str(points)
	if question_panels.has(key):
		var panel = question_panels[key]
		panel.add_theme_stylebox_override("panel", _create_completed_style())

func _get_player_name(player_id: int) -> String:
	if current_players.has(player_id):
		return current_players[player_id]["name"]
	elif NetworkManager.players.has(player_id):
		return NetworkManager.players[player_id].get("name", "Player")
	return "Player " + str(player_id)

func _create_highlighted_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.6, 0.2, 0.9)  # Orange highlight for current question
	style.set_border_width_all(3)
	style.border_color = Color.YELLOW
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.content_margin_left = 15
	style.content_margin_right = 15
	return style

func _create_completed_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.3, 0.6)  # Grayed out for completed questions
	style.set_border_width_all(1)
	style.border_color = Color(0.2, 0.2, 0.2, 1.0)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.content_margin_left = 15
	style.content_margin_right = 15
	return style

func _update_players_display():
	# Clear existing player displays
	for child in players_list.get_children():
		child.queue_free()
	
	# Add current players with scores
	for player_id in current_players:
		var player_data = current_players[player_id]
		var player_label = Label.new()
		var score_text = "$" + str(player_data.get("score", 0))
		var highlight = " [BUZZED]" if player_data.get("name", "") == current_buzzer_player else ""
		player_label.text = player_data.get("name", "Unknown") + ": " + score_text + highlight
		player_label.add_theme_font_size_override("font_size", 14)
		
		# Highlight the player who buzzed
		if highlight != "":
			player_label.modulate = Color.ORANGE
		else:
			player_label.modulate = Color.WHITE
		
		players_list.add_child(player_label)