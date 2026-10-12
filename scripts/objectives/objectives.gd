extends Node

signal objective_changed(title: String, description: String)
signal objective_completed(objective_id: String)
signal map_updated(area_id: String)

const OBJECTIVES := {
	"find_keycard": {"title": "Find an access card", "description": "Search the entrance area for a staff access card."},
	"restore_power": {"title": "Restore facility power", "description": "Use the generator in the service room."},
	"reach_exit": {"title": "Reach the service exit", "description": "Open the powered service door and escape."}
}

var completed: Array[String] = []
var discovered_areas: Array[String] = ["forest", "entrance"]
var current_id := "find_keycard"

func discover_area(area_id: String) -> void:
	if area_id not in ["forest", "entrance", "administration", "service", "laboratory", "corridor", "exit"] or discovered_areas.has(area_id):
		return
	discovered_areas.append(area_id)
	map_updated.emit(area_id)

func _ready() -> void:
	_publish_current()

func complete(objective_id: String) -> void:
	if not OBJECTIVES.has(objective_id) or completed.has(objective_id):
		return
	completed.append(objective_id)
	objective_completed.emit(objective_id)
	var ids: Array = OBJECTIVES.keys()
	var index: int = ids.find(objective_id)
	current_id = str(ids[index + 1]) if index + 1 < ids.size() else ""
	_publish_current()

func _publish_current() -> void:
	if current_id.is_empty():
		objective_changed.emit("Scenario complete", "You escaped the facility.")
		return
	var data: Dictionary = OBJECTIVES[current_id]
	objective_changed.emit(str(data.title), str(data.description))

func restore(saved_completed: Array, saved_areas: Array = []) -> void:
	completed.clear()
	for objective_id in saved_completed:
		if OBJECTIVES.has(str(objective_id)) and not completed.has(str(objective_id)):
			completed.append(str(objective_id))
	discovered_areas = ["forest", "entrance"]
	for area_id in saved_areas:
		if area_id is String and area_id in ["administration", "service", "laboratory", "corridor", "exit"] and not discovered_areas.has(area_id):
			discovered_areas.append(area_id)
	current_id = "find_keycard"
	var ids: Array = OBJECTIVES.keys()
	for objective_id in completed:
		var index: int = ids.find(objective_id)
		if index >= 0 and index + 1 < ids.size():
			current_id = str(ids[index + 1])
		elif index == ids.size() - 1:
			current_id = ""
	_publish_current()
