class_name StyleTracker
extends RefCounted
var score: int = 0
var combo: int = 0
var events: Array[String] = []
var last_event: String = "FIND YOUR FLOW"
const POINTS: Dictionary = {"BANK": 25, "SMASH": 40, "GAP JUMP": 75, "SPRING": 20, "AIR": 10, "BOING": 25, "GRIND": 15, "SO CLOSE": 30, "NICE": 40, "FULL SEND": 20, "SAVED": 50, "BULLSEYE": 100, "GRAZE": -50, "TILT": -100}

func add(event: String) -> int:
	var points: int = int(POINTS.get(event, 0))
	if points > 0:
		combo += 1
	else:
		combo = 0
	if event == "BOING":
		points = roundi(points * pow(1.1, mini(combo - 1, 8)))
	score = maxi(0, score + points)
	last_event = event
	events.append(event)
	return points

func stars(clear: bool, accuracy: float, par: int, purist: bool) -> int:
	if not clear:
		return 0
	if purist:
		return 3
	return 1 + int(score >= par) + int(accuracy >= 0.72)
