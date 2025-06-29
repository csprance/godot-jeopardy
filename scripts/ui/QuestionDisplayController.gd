extends Control
class_name QuestionDisplay

# Question display popup - shows questions and handles answers

@onready var category_label = $CenterContainer/QuestionPanel/VBoxContainer/Header/Category
@onready var points_label = $CenterContainer/QuestionPanel/VBoxContainer/Header/Points
@onready var daily_double_label = $CenterContainer/QuestionPanel/VBoxContainer/Header/DailyDouble
@onready var question_text = $CenterContainer/QuestionPanel/VBoxContainer/QuestionContainer/QuestionText
@onready var answer_input = $CenterContainer/QuestionPanel/VBoxContainer/AnswerContainer/AnswerInput
@onready var answer_text = $CenterContainer/QuestionPanel/VBoxContainer/AnswerContainer/AnswerText
@onready var submit_button = $CenterContainer/QuestionPanel/VBoxContainer/AnswerContainer/ButtonContainer/SubmitButton
@onready var correct_button = $CenterContainer/QuestionPanel/VBoxContainer/AnswerContainer/ButtonContainer/CorrectButton
@onready var wrong_button = $CenterContainer/QuestionPanel/VBoxContainer/AnswerContainer/ButtonContainer/WrongButton
@onready var status_label = $CenterContainer/QuestionPanel/VBoxContainer/StatusContainer/StatusLabel
@onready var buzz_button = $CenterContainer/QuestionPanel/VBoxContainer/StatusContainer/BuzzButton
@onready var close_button = $CenterContainer/QuestionPanel/VBoxContainer/StatusContainer/CloseButton

# NetworkManager and GameState are now autoloads - access directly
var current_question: Dictionary = {}
var current_category: String = ""
var current_points: int = 0
var buzzer_player_id: int = -1

func _ready():
	# Managers are now autoloads - no need to get references
	
	# Connect button signals
	submit_button.pressed.connect(_on_submit_pressed)
	correct_button.pressed.connect(_on_correct_pressed)
	wrong_button.pressed.connect(_on_wrong_pressed)
	buzz_button.pressed.connect(_on_buzz_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Connect input signal
	answer_input.text_submitted.connect(_on_answer_submitted)
	
	# Connect network signals
	NetworkManager.answer_submitted.connect(_on_answer_received_by_host)
	NetworkManager.answer_judgment.connect(_on_judgment_received)
	NetworkManager.question_completed.connect(_on_question_completed_sync)

func show_question(question_data: Dictionary, category: String = "", points: int = 0):
	current_question = question_data
	current_category = category if not category.is_empty() else question_data.get("category", "CATEGORY")
	current_points = points if points > 0 else question_data.get("points", 0)
	visible = true
	
	# Update display
	category_label.text = current_category
	points_label.text = "$" + str(current_points)
	question_text.text = question_data.get("question", "")
	
	# Show Daily Double indicator
	daily_double_label.visible = question_data.get("daily_double", false)
	
	# Reset answer display
	answer_input.visible = false
	answer_text.visible = false
	submit_button.visible = false
	correct_button.visible = false
	wrong_button.visible = false
	
	# Enable buzz button
	buzz_button.disabled = false
	buzz_button.visible = true
	
	status_label.text = "Waiting for buzz..."

func handle_buzz(player_id: int):
	buzzer_player_id = player_id
	
	# Disable buzz button for everyone
	buzz_button.disabled = true
	
	# Show different UI based on whether local player buzzed
	if player_id == NetworkManager.get_local_player_id():
		# Local player buzzed - show answer input
		_show_answer_input()
	elif NetworkManager.is_host:
		# Host sees correct/wrong buttons for other player
		_show_host_controls()
	else:
		# Other players wait
		var player_name = _get_player_name(player_id)
		status_label.text = player_name + " is answering..."

func _show_answer_input():
	answer_input.visible = true
	submit_button.visible = true
	answer_input.grab_focus()
	status_label.text = "Enter your answer and press Submit!"

func _show_host_controls():
	correct_button.visible = true
	wrong_button.visible = true
	var player_name = _get_player_name(buzzer_player_id)
	status_label.text = "Did " + player_name + " answer correctly?"

func show_answer():
	# Show the correct answer
	answer_text.text = current_question.get("answer", "")
	answer_text.visible = true
	status_label.text = "Correct answer shown"
	
	# Hide other controls
	answer_input.visible = false
	submit_button.visible = false
	correct_button.visible = false
	wrong_button.visible = false

func _on_submit_pressed():
	_submit_answer()

func _on_answer_submitted(text: String):
	_submit_answer()

func _submit_answer():
	var answer = answer_input.text.strip_edges()
	if answer.is_empty():
		return
	
	# Hide input controls
	answer_input.visible = false
	submit_button.visible = false
	
	# Show waiting message
	status_label.text = "Answer submitted! Waiting for host decision..."
	
	# Send answer to host
	NetworkManager.rpc("submit_player_answer", NetworkManager.get_local_player_id(), answer)

func _on_correct_pressed():
	_handle_answer_result(true)

func _on_wrong_pressed():
	_handle_answer_result(false)

func _handle_answer_result(is_correct: bool):
	if not NetworkManager.is_host:
		return
	
	# Calculate points
	var points = current_question.get("points", 0)
	
	# Update score locally
	if is_correct:
		GameState.update_player_score(buzzer_player_id, points)
	else:
		GameState.update_player_score(buzzer_player_id, -points)
	
	# Broadcast judgment to all players
	NetworkManager.rpc("answer_judged", buzzer_player_id, is_correct, points)
	
	# Mark question as completed
	_mark_question_completed()
	
	# Hide host controls
	correct_button.visible = false
	wrong_button.visible = false

func _mark_question_completed():
	# Only host should initiate completion synchronization
	if NetworkManager.is_host:
		# Mark question as completed in game state
		current_question["completed"] = true
		GameState.mark_question_completed()
		
		# Sync to all players
		NetworkManager.rpc("sync_question_completed", current_category, current_points)

func _on_buzz_pressed():
	# Send buzz to network
	var timestamp = Time.get_time_dict_from_system().second
	NetworkManager.rpc("player_buzzed", NetworkManager.get_local_player_id(), timestamp)
	
	buzz_button.disabled = true
	status_label.text = "Buzzed! Waiting for response..."

func _on_close_pressed():
	visible = false
	current_question.clear()
	buzzer_player_id = -1

func _get_player_name(player_id: int) -> String:
	# Try to get player name from network manager
	if NetworkManager.players.has(player_id):
		return NetworkManager.players[player_id].get("name", "Player")
	return "Player " + str(player_id)

func _on_answer_received_by_host(player_id: int, answer_text: String):
	# Only host receives this - show the submitted answer to help with judging
	if NetworkManager.is_host and player_id == buzzer_player_id:
		var player_name = _get_player_name(player_id)
		status_label.text = player_name + " answered: \"" + answer_text + "\""

func _on_judgment_received(player_id: int, is_correct: bool, points: int):
	# All players receive the judgment result
	var player_name = _get_player_name(player_id)
	if is_correct:
		status_label.text = "Correct! " + player_name + " +" + str(points) + " points"
	else:
		status_label.text = "Wrong! " + player_name + " -" + str(points) + " points"
	
	# Show the correct answer
	show_answer()

func _on_question_completed_sync(category: String, points: int):
	# All players receive notification that a question has been completed
	# This will trigger the GameBoardController to update the UI
	pass  # The actual board update happens in GameBoardController