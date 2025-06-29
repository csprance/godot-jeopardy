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
@onready var close_button = $CenterContainer/QuestionPanel/VBoxContainer/StatusContainer/CloseButton

# NetworkManager and GameState are now autoloads - access directly
var current_question: Dictionary = {}
var buzzer_player_id: int = -1

func _ready():
	# Managers are now autoloads - no need to get references
	
	# Connect button signals
	submit_button.pressed.connect(_on_submit_pressed)
	correct_button.pressed.connect(_on_correct_pressed)
	wrong_button.pressed.connect(_on_wrong_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Connect input signal
	answer_input.text_submitted.connect(_on_answer_submitted)

func show_question(question_data: Dictionary):
	current_question = question_data
	visible = true
	
	# Update display
	category_label.text = question_data.get("category", "CATEGORY")
	points_label.text = "$" + str(question_data.get("points", 0))
	question_text.text = question_data.get("question", "")
	
	# Show Daily Double indicator
	daily_double_label.visible = question_data.get("daily_double", false)
	
	# Reset answer display
	answer_input.visible = false
	answer_text.visible = false
	submit_button.visible = false
	correct_button.visible = false
	wrong_button.visible = false
	
	status_label.text = "Waiting for buzz..."

func handle_buzz(player_id: int):
	buzzer_player_id = player_id
	
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
	
	# In a real implementation, this would be sent to host for validation
	# For now, we'll auto-validate or let host decide

func _on_correct_pressed():
	_handle_answer_result(true)

func _on_wrong_pressed():
	_handle_answer_result(false)

func _handle_answer_result(is_correct: bool):
	if not NetworkManager.is_host:
		return
	
	# Update score
	var points = current_question.get("points", 0)
	if is_correct:
		GameState.update_player_score(buzzer_player_id, points)
		status_label.text = "Correct! +" + str(points) + " points"
	else:
		GameState.update_player_score(buzzer_player_id, -points)
		status_label.text = "Wrong! -" + str(points) + " points"
	
	# Show answer
	show_answer()
	
	# Mark question as completed
	_mark_question_completed()
	
	# Hide host controls
	correct_button.visible = false
	wrong_button.visible = false

func _mark_question_completed():
	# Mark question as completed in game state
	current_question["completed"] = true
	GameState.mark_question_completed()

func _on_close_pressed():
	visible = false
	current_question.clear()
	buzzer_player_id = -1

func _get_player_name(player_id: int) -> String:
	# Try to get player name from network manager
	if NetworkManager.players.has(player_id):
		return NetworkManager.players[player_id].get("name", "Player")
	return "Player " + str(player_id)