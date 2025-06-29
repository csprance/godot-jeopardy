extends RefCounted
class_name BoardGenerator

# Generates randomized game boards from question pools
# Creates unique boards each game while maintaining balance

static func generate_board(game_data: GameData) -> Dictionary:
	if not game_data:
		print("Cannot generate board: no game data provided")
		return {}
	
	var board = {}
	var categories = game_data.get_categories()
	var point_values = game_data.get_point_values()
	var categories_needed = game_data.get_board_categories_count()
	var questions_per_category = game_data.get_questions_per_category()
	
	# Validate we have enough content
	if categories.size() < categories_needed:
		print("Not enough categories: need ", categories_needed, ", have ", categories.size())
		return {}
	
	# 1. Select random categories
	categories.shuffle()
	var selected_categories = categories.slice(0, categories_needed)
	
	# 2. For each category, select appropriate questions
	for category in selected_categories:
		var category_questions = game_data.get_questions_by_category(category)
		var board_questions = _select_questions_for_category(
			category_questions, point_values, questions_per_category
		)
		
		if board_questions.size() != questions_per_category:
			print("Failed to fill category: ", category)
			continue
		
		board[category] = board_questions
	
	# 3. Add Daily Doubles
	_add_daily_doubles(board, game_data.get_daily_doubles_count())
	
	# 4. Validate board
	if not _validate_board(board, categories_needed, questions_per_category):
		print("Board validation failed")
		return {}
	
	print("Generated board with ", board.size(), " categories")
	return board

static func _select_questions_for_category(questions: Array, point_values: Array, needed_count: int) -> Array:
	if questions.size() < needed_count:
		print("Not enough questions in category: need ", needed_count, ", have ", questions.size())
		return []
	
	var selected_questions = []
	var used_questions = []
	
	# Try to match each point value with appropriate questions
	for i in range(needed_count):
		var target_points = point_values[i] if i < point_values.size() else point_values[-1]
		var best_question = _find_best_question_for_points(questions, target_points, used_questions)
		
		if best_question:
			var question_copy = best_question.duplicate()
			question_copy["points"] = target_points
			question_copy["completed"] = false
			selected_questions.append(question_copy)
			used_questions.append(best_question)
		else:
			print("Could not find suitable question for points: ", target_points)
			return []
	
	return selected_questions

static func _find_best_question_for_points(questions: Array, target_points: int, used_questions: Array) -> Dictionary:
	var best_question = {}
	var best_score = -1
	
	for question in questions:
		# Skip already used questions
		if used_questions.has(question):
			continue
		
		var point_range = question.get("point_range", {})
		var min_points = point_range.get("min", 0)
		var max_points = point_range.get("max", 1000)
		
		# Calculate fitness score (how well this question fits the target)
		var score = _calculate_question_fitness(target_points, min_points, max_points)
		
		if score > best_score:
			best_score = score
			best_question = question
	
	return best_question

static func _calculate_question_fitness(target: int, min_val: int, max_val: int) -> float:
	# Perfect fit: target is within range
	if target >= min_val and target <= max_val:
		# Prefer questions where target is closer to the center of the range
		var center = (min_val + max_val) / 2.0
		var distance_from_center = abs(target - center)
		var range_size = max_val - min_val
		return 100.0 - (distance_from_center / range_size * 50.0)
	
	# Partial fit: target is outside range but close
	var distance = min(abs(target - min_val), abs(target - max_val))
	return max(0.0, 50.0 - distance / 10.0)

static func _add_daily_doubles(board: Dictionary, daily_doubles_count: int):
	if daily_doubles_count <= 0:
		return
	
	var all_positions = []
	
	# Collect all valid positions (exclude first row - lowest point values)
	for category in board.keys():
		var questions = board[category]
		for i in range(1, questions.size()): # Skip index 0 (lowest points)
			all_positions.append({"category": category, "index": i})
	
	# Randomly select positions for Daily Doubles
	all_positions.shuffle()
	var daily_double_count = min(daily_doubles_count, all_positions.size())
	
	for i in range(daily_double_count):
		var pos = all_positions[i]
		board[pos.category][pos.index]["daily_double"] = true
		print("Daily Double placed at: ", pos.category, " - ", board[pos.category][pos.index].points)

static func _validate_board(board: Dictionary, expected_categories: int, expected_questions: int) -> bool:
	# Check category count
	if board.size() != expected_categories:
		print("Board validation failed: wrong category count")
		return false
	
	# Check each category has correct number of questions
	for category in board.keys():
		var questions = board[category]
		if questions.size() != expected_questions:
			print("Board validation failed: wrong question count in ", category)
			return false
		
		# Check each question has required fields
		for question in questions:
			if not question.has("points") or not question.has("question") or not question.has("answer"):
				print("Board validation failed: missing required fields in question")
				return false
	
	return true

static func print_board_summary(board: Dictionary):
	print("=== BOARD SUMMARY ===")
	for category in board.keys():
		print("Category: ", category)
		var questions = board[category]
		for question in questions:
			var points = question.get("points", 0)
			var daily_double = " (DD)" if question.get("daily_double", false) else ""
			print("  ", points, daily_double, ": ", question.get("question", "").substr(0, 50), "...")
	print("====================")