extends RefCounted
class_name Player

# Player data structure for multiplayer game

var id: int = -1
var name: String = ""
var score: int = 0
var is_host: bool = false
var is_connected: bool = true

func _init(player_id: int = -1, player_name: String = ""):
	id = player_id
	name = player_name

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"score": score,
		"is_host": is_host,
		"is_connected": is_connected
	}

static func from_dict(data: Dictionary) -> Player:
	var player = Player.new()
	player.id = data.get("id", -1)
	player.name = data.get("name", "")
	player.score = data.get("score", 0)
	player.is_host = data.get("is_host", false)
	player.is_connected = data.get("is_connected", true)
	return player

func add_score(points: int):
	score += points

func subtract_score(points: int):
	score -= points

func reset_score():
	score = 0

func get_display_name() -> String:
	var display = name
	if is_host:
		display += " (Host)"
	if not is_connected:
		display += " (Disconnected)"
	return display