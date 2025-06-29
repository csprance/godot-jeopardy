extends RefCounted
class_name Question

# Question data structure with metadata

var category: String = ""
var question: String = ""
var answer: String = ""
var points: int = 0
var point_range: Dictionary = {}
var daily_double: bool = false
var completed: bool = false
var tags: Array = []
var media: Dictionary = {}

func _init(data: Dictionary = {}):
	if not data.is_empty():
		from_dict(data)

func from_dict(data: Dictionary):
	category = data.get("category", "")
	question = data.get("question", "")
	answer = data.get("answer", "")
	points = data.get("points", 0)
	point_range = data.get("point_range", {})
	daily_double = data.get("daily_double", false)
	completed = data.get("completed", false)
	tags = data.get("tags", [])
	media = data.get("media", {})

func to_dict() -> Dictionary:
	return {
		"category": category,
		"question": question,
		"answer": answer,
		"points": points,
		"point_range": point_range,
		"daily_double": daily_double,
		"completed": completed,
		"tags": tags,
		"media": media
	}

func is_valid() -> bool:
	return category != "" and question != "" and answer != ""

func has_media() -> bool:
	return media.has("image") or media.has("audio")

func get_media_path(media_type: String) -> String:
	return media.get(media_type, "")

func fits_point_range(target_points: int) -> bool:
	if point_range.is_empty():
		return true
	
	var min_points = point_range.get("min", 0)
	var max_points = point_range.get("max", 1000)
	return target_points >= min_points and target_points <= max_points

func get_difficulty_level() -> String:
	if point_range.is_empty():
		return "medium"
	
	var avg_points = (point_range.get("min", 0) + point_range.get("max", 1000)) / 2
	
	if avg_points <= 300:
		return "easy"
	elif avg_points <= 600:
		return "medium"
	else:
		return "hard"