extends Node

var _graph := AStar3D.new()
var _points: Dictionary = {}

func _ready() -> void:
	var positions := {
		1: Vector3(0, 0, -8), 2: Vector3(0, 0, -11), 3: Vector3(0, 0, -14),
		4: Vector3(0, 0, -18), 5: Vector3(0, 0, -22), 6: Vector3(0, 0, -25),
		7: Vector3(0, 0, -29), 8: Vector3(-3, 0, -14), 9: Vector3(-5.5, 0, -15),
		10: Vector3(-6, 0, -19), 11: Vector3(3, 0, -14), 12: Vector3(5.5, 0, -15),
		13: Vector3(9, 0, -18), 14: Vector3(4.5, 0, -4), 15: Vector3(7, 0, -5),
		16: Vector3(10, 0, -8), 17: Vector3(0, 0, 2)
	}
	for point_id in positions:
		_points[point_id] = positions[point_id]
		_graph.add_point(point_id, positions[point_id])
	var edges := [[1,2],[2,3],[3,4],[4,5],[5,6],[6,7],[3,8],[8,9],[9,10],[3,11],[11,12],[12,13],[1,14],[14,15],[15,16],[1,17]]
	for edge in edges:
		_graph.connect_points(edge[0], edge[1])

func get_waypoint(from_position: Vector3, to_position: Vector3) -> Vector3:
	var start_id := _nearest_point(from_position)
	var end_id := _nearest_point(to_position)
	if start_id == end_id:
		return to_position
	var path := _graph.get_id_path(start_id, end_id)
	if path.size() > 1:
		return _points[path[1]]
	return to_position

func _nearest_point(position: Vector3) -> int:
	var nearest_id := 1
	var nearest_distance := INF
	for point_id in _points:
		var distance: float = position.distance_squared_to(_points[point_id])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_id = point_id
	return nearest_id
