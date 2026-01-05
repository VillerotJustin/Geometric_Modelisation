@tool
extends Path3D

@export var subdivisions: int = 2:
	set(value):
		subdivisions = value
		update_curve()

@export var update: bool = false:
	set(value):
		if value:
			update_curve()
		update = false

var child_path: Path3D
var child_curve: Curve3D

func _ready():
	child_path = get_node_or_null("Child_Curve")
	if child_path:
		child_curve = child_path.curve
	update_curve()

func update_curve():
	if Engine.is_editor_hint():
		child_path = get_node_or_null("Child_Curve")
		if child_path:
			child_curve = child_path.curve
	
	if child_curve == null:
		return
	
	if curve == null:
		return
	
	# Get the original curve points from THIS path
	var original_points: Array[Vector3]= []
	for i in range(curve.point_count):
		original_points.append(curve.get_point_position(i))
	
	if original_points.size() < 2:
		return
	
	# Apply Chaikin subdivision
	var new_points = chaikin_subdivision(original_points, subdivisions)
	
	# Update the CHILD path's curve with the result
	child_curve.clear_points()
	for point in new_points:
		child_curve.add_point(point)
	
	# Notify the editor that the property changed
	if Engine.is_editor_hint():
		notify_property_list_changed()

func chaikin_subdivision(points: Array[Vector3], iterations: int) -> Array:
	var result = points.duplicate()
	
	for _iter in range(iterations):
		if result.size() < 2:
			break
			
		var new_result = []
		
		for i in range(result.size()):
			var working_point: Vector3 = result[i]
			var next_point: Vector3 = result[(i + 1) % result.size()]
			
			var direction: Vector3 = next_point - working_point
			
			# Skip if points are identical or too close
			if direction.length_squared() < 0.0001:
				new_result.append(working_point)
				continue
			
			var new_point_1: Vector3 = working_point + (1.0/3.0) * direction
			var new_point_2: Vector3 = working_point + (2.0/3.0) * direction
			
			new_result.append(new_point_1)
			new_result.append(new_point_2)
			
		result = new_result
	
	return result
