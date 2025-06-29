extends RefCounted
class_name GameData

# Loads and parses JSON question pools
# Validates data structure and provides access to game content

var title: String = ""
var description: String = ""
var questions: Array = []
var board_config: Dictionary = {}
var final_jeopardy: Dictionary = {}

static func load_from_file(file_path: String) -> GameData:
	var game_data = GameData.new()
	
	if not FileAccess.file_exists(file_path):
		print("Game data file not found: ", file_path)
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open game data file: ", file_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse JSON: ", json.error_string)
		return null
	
	var data = json.data
	
	# Validate required fields
	if not data.has("title") or not data.has("questions"):
		print("Invalid game data: missing required fields")
		return null
	
	# Load basic info
	game_data.title = data.get("title", "")
	game_data.description = data.get("description", "")
	
	# Load questions
	game_data.questions = data.get("questions", [])
	if game_data.questions.size() < 30:
		print("Warning: Less than 30 questions available. Need at least 30 for a full board.")
	
	# Validate questions
	for i in range(game_data.questions.size()):
		var question = game_data.questions[i]
		if not _validate_question(question):
			print("Invalid question at index ", i)
			return null
	
	# Load board configuration
	game_data.board_config = data.get("board_config", {
		"categories_count": 6,
		"questions_per_category": 5,
		"point_values": [200, 400, 600, 800, 1000],
		"daily_doubles_count": 2
	})
	
	# Load final jeopardy (optional)
	game_data.final_jeopardy = data.get("final_jeopardy", {})
	
	print("Loaded game data: ", game_data.title, " with ", game_data.questions.size(), " questions")
	return game_data

static func _validate_question(question: Dictionary) -> bool:
	# Check required fields
	var required_fields = ["category", "question", "answer", "point_range"]
	for field in required_fields:
		if not question.has(field):
			print("Question missing required field: ", field)
			return false
	
	# Validate point_range
	var point_range = question.get("point_range")
	if not point_range.has("min") or not point_range.has("max"):
		print("Invalid point_range in question")
		return false
	
	if point_range.min > point_range.max:
		print("Invalid point_range: min > max")
		return false
	
	return true

func get_categories() -> Array:
	var categories = []
	for question in questions:
		var category = question.get("category", "")
		if category != "" and not categories.has(category):
			categories.append(category)
	return categories

func get_questions_by_category(category: String) -> Array:
	var category_questions = []
	for question in questions:
		if question.get("category", "") == category:
			category_questions.append(question)
	return category_questions

func get_questions_in_point_range(min_points: int, max_points: int) -> Array:
	var filtered_questions = []
	for question in questions:
		var point_range = question.get("point_range", {})
		var q_min = point_range.get("min", 0)
		var q_max = point_range.get("max", 0)
		
		# Check if question's range overlaps with target range
		if q_min <= max_points and q_max >= min_points:
			filtered_questions.append(question)
	
	return filtered_questions

func get_question_count() -> int:
	return questions.size()

func get_category_count() -> int:
	return get_categories().size()

func has_final_jeopardy() -> bool:
	return final_jeopardy.has("question") and final_jeopardy.has("answer")

func get_board_categories_count() -> int:
	return board_config.get("categories_count", 6)

func get_questions_per_category() -> int:
	return board_config.get("questions_per_category", 5)

func get_point_values() -> Array:
	return board_config.get("point_values", [200, 400, 600, 800, 1000])

func get_daily_doubles_count() -> int:
	return board_config.get("daily_doubles_count", 2)