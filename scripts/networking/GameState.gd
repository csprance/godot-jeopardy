extends Node

# Centralized game state management
# Handles current game phase, board state, scoring, and turn management

signal state_changed(new_state: State)
signal board_updated(board_data: Dictionary)
signal question_selected(category: String, points: int, question_data: Dictionary)
signal buzz_received(player_id: int, timestamp: float)
signal score_updated(player_id: int, new_score: int)

enum State {
	MENU,
	LOBBY,
	PLAYING,
	QUESTION_ACTIVE,
	GAME_OVER
}

var current_state: State = State.MENU
var game_board: Dictionary = {}
var current_question: Dictionary = {}
var players: Dictionary = {}
var current_player_turn: int = -1

# Buzzer system
var question_start_time: float = 0.0
var buzzer_active: bool = false
var first_buzzer: int = -1
var buzzer_timestamp: float = 0.0

# Game configuration
var board_config: Dictionary = {
	"categories_count": 6,
	"questions_per_category": 5,
	"point_values": [200, 400, 600, 800, 1000],
	"daily_doubles_count": 2
}

func _ready():
	add_to_group("game_state")

func change_state(new_state: State):
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)
		print("Game state changed to: ", State.keys()[new_state])

func set_game_board(board_data: Dictionary):
	game_board = board_data
	board_updated.emit(board_data)

func select_question(category: String, points: int):
	# Find the question in the board
	if game_board.has(category):
		var category_questions = game_board[category]
		for question in category_questions:
			if question.points == points and not question.get("completed", false):
				current_question = question
				question_selected.emit(category, points, question)
				start_question_timer()
				return
	
	print("Question not found or already completed")

func start_question_timer():
	question_start_time = Time.get_time_dict_from_system().second
	buzzer_active = true
	first_buzzer = -1
	change_state(State.QUESTION_ACTIVE)

func handle_buzz(player_id: int, timestamp: float):
	if not buzzer_active:
		return
	
	# First buzz wins
	if first_buzzer == -1:
		first_buzzer = player_id
		buzzer_timestamp = timestamp
		buzzer_active = false
		buzz_received.emit(player_id, timestamp)

func submit_answer(answer: String, is_correct: bool):
	if current_question.is_empty():
		return
	
	var points = current_question.get("points", 0)
	
	if is_correct:
		# Award points
		update_player_score(first_buzzer, points)
		current_player_turn = first_buzzer
	else:
		# Deduct points
		update_player_score(first_buzzer, -points)
		# Resume buzzer for other players
		buzzer_active = true
		first_buzzer = -1
	
	# Mark question as completed if correct or no more players can buzz
	if is_correct or not buzzer_active:
		mark_question_completed()

func update_player_score(player_id: int, points_change: int):
	if players.has(player_id):
		players[player_id].score += points_change
		score_updated.emit(player_id, players[player_id].score)

func mark_question_completed():
	current_question["completed"] = true
	current_question = {}
	change_state(State.PLAYING)
	
	# Check if game is over (all questions completed)
	if is_game_complete():
		change_state(State.GAME_OVER)

func is_game_complete() -> bool:
	for category in game_board.values():
		for question in category:
			if not question.get("completed", false):
				return false
	return true

func get_current_scores() -> Dictionary:
	var scores = {}
	for player_id in players:
		scores[player_id] = {
			"name": players[player_id].name,
			"score": players[player_id].score
		}
	return scores

func get_leaderboard() -> Array:
	var leaderboard = []
	for player_id in players:
		leaderboard.append({
			"id": player_id,
			"name": players[player_id].name,
			"score": players[player_id].score
		})
	
	# Sort by score descending
	leaderboard.sort_custom(func(a, b): return a.score > b.score)
	return leaderboard

func reset_game():
	game_board.clear()
	current_question.clear()
	players.clear()
	current_player_turn = -1
	buzzer_active = false
	first_buzzer = -1
	change_state(State.MENU)