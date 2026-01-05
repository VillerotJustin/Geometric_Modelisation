extends Node3D

class_name Simplification

@onready var bunny_mesh: Mesh = Mesh_Importer.read_off_mesh("res://Meshes/bunny.off")

@export_category("Grid")
@export var tolerance_epsylon: float = 0.1

@export_category("Visualization Toggles")
@export var show_control_grid: bool = true
@export var show_control_occupancy: bool = true
@export var show_simplified_grid: bool = false
@export var show_simplified_occupancy: bool = false

# Runtime toggle tracking
var control_grid_nodes: Array[Node3D] = []
var control_occupancy_nodes: Array[Node3D] = []
var simplified_grid_nodes: Array[Node3D] = []
var simplified_occupancy_nodes: Array[Node3D] = []

# Global toggles
var show_all_grids: bool = true
var show_all_occupancy: bool = true

func _ready() -> void:
	# Validate mesh loaded correctly
	if bunny_mesh == null:
		print("ERROR: Failed to load bunny mesh from 'res://Meshes/bunny.off'")
		print("Please ensure the file exists and Mesh_Importer is working correctly")
		return
	
	if bunny_mesh.get_surface_count() == 0:
		print("ERROR: Loaded bunny mesh has no surfaces")
		print("The .off file may be corrupted or empty")
		return
	
	print("Successfully loaded bunny mesh with ", bunny_mesh.get_surface_count(), " surface(s)")
	
	add_control_mesh()

	add_simplification(0.1, Vector3(2, 0, 0), "Simplified 0.1")
	
	add_simplification(0.15, Vector3(4, 0, 0), "Simplified 0.15")
	
	add_simplification(0.2, Vector3(6, 0, 0), "Simplified 0.2")
	
	add_simplification(0.25, Vector3(8, 0, 0), "Simplified 0.25")
	
	add_simplification(0.3, Vector3(10, 0, 0), "Simplified 0.3")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: # Toggle control grid
				show_control_grid = !show_control_grid
				toggle_visualization_nodes(control_grid_nodes, show_control_grid)
				print("Control Grid: ", "ON" if show_control_grid else "OFF")
			KEY_2: # Toggle control occupancy
				show_control_occupancy = !show_control_occupancy
				toggle_visualization_nodes(control_occupancy_nodes, show_control_occupancy)
				print("Control Occupancy: ", "ON" if show_control_occupancy else "OFF")
			KEY_3: # Toggle simplified grid
				show_simplified_grid = !show_simplified_grid
				toggle_visualization_nodes(simplified_grid_nodes, show_simplified_grid)
				print("Simplified Grid: ", "ON" if show_simplified_grid else "OFF")
			KEY_4: # Toggle simplified occupancy
				show_simplified_occupancy = !show_simplified_occupancy
				toggle_visualization_nodes(simplified_occupancy_nodes, show_simplified_occupancy)
				print("Simplified Occupancy: ", "ON" if show_simplified_occupancy else "OFF")
			KEY_G: # Toggle all grids
				show_all_grids = !show_all_grids
				show_control_grid = show_all_grids
				show_simplified_grid = show_all_grids
				toggle_visualization_nodes(control_grid_nodes, show_all_grids)
				toggle_visualization_nodes(simplified_grid_nodes, show_all_grids)
				print("All Grids: ", "ON" if show_all_grids else "OFF")
			KEY_O: # Toggle all occupancy
				show_all_occupancy = !show_all_occupancy
				show_control_occupancy = show_all_occupancy
				show_simplified_occupancy = show_all_occupancy
				toggle_visualization_nodes(control_occupancy_nodes, show_all_occupancy)
				toggle_visualization_nodes(simplified_occupancy_nodes, show_all_occupancy)
				print("All Occupancy: ", "ON" if show_all_occupancy else "OFF")
			KEY_H: # Show help
				print_keybind_help()
func add_control_mesh() -> void:
	# Default rabit at 0x0x0
	var control_rabbit: MeshInstance3D = MeshInstance3D.new()
	control_rabbit.name = "control_rabbit"
	control_rabbit.position = Vector3.ZERO
	control_rabbit.mesh = bunny_mesh
	
	# Add no-culling material
	var control_material = StandardMaterial3D.new()
	control_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	control_material.albedo_color = Color(0.8, 0.8, 0.8)
	control_rabbit.material_override = control_material
	
	add_child(control_rabbit)
	
	# Add small text above
	var control_text_mesh: TextMesh = TextMesh.new()
	control_text_mesh.text = "Control"
	var control_text: MeshInstance3D = MeshInstance3D.new()
	control_text.mesh = control_text_mesh
	control_text.position = Vector3.UP * 1.5
	add_child(control_text)
	
	# Add pedestral
	var control_plane_mesh: PlaneMesh = PlaneMesh.new()
	var control_pedestral: MeshInstance3D = MeshInstance3D.new()
	control_pedestral.mesh = control_plane_mesh
	control_pedestral.position = Vector3.DOWN * 0.65
	add_child(control_pedestral)
	
	# Validate the original mesh
	validate_mesh(bunny_mesh, "Original Bunny Mesh")
	
	build_grid(control_rabbit, show_control_grid, show_control_occupancy, Color.RED, bunny_mesh)

func build_grid(mesh_instance: MeshInstance3D, show_grid: bool = true, show_occupancy: bool = true, grid_color: Color = Color.RED, base_mesh: Mesh = null) -> void:
	# Use base mesh if provided, otherwise use the mesh instance's mesh
	var reference_mesh = base_mesh if base_mesh != null else mesh_instance.mesh
	
	# Always create the grid but set initial visibility
	gyzmo_grid(mesh_instance, reference_mesh, grid_color, show_grid)
	
	# Make a custom grid 3d matrix with list of the nodes in each cell of the grid
	var grid_data = create_3d_grid_matrix(mesh_instance)
	print("Created 3D grid with ", grid_data.dimensions, " cells")
	print("Total vertices distributed: ", grid_data.total_vertices)
	
	# Always create occupancy visualization but set initial visibility
	visualize_grid_occupancy(grid_data, mesh_instance, show_occupancy)

func gyzmo_grid(mesh_instance: MeshInstance3D, reference_mesh: Mesh, grid_color: Color = Color.RED, initial_visibility: bool = true) -> void:
	# Get the actual bounding box of the reference mesh
	var aabb: AABB = reference_mesh.get_aabb()
	var size: Vector3 = aabb.size
	var min_bounds: Vector3 = aabb.position
	var max_bounds: Vector3 = aabb.position + aabb.size
	
	# Calculate proper step sizes based on tolerance
	var step_x = size.x * tolerance_epsylon
	var step_y = size.y * tolerance_epsylon  
	var step_z = size.z * tolerance_epsylon
	
	# Ensure minimum step size to avoid infinite loops
	step_x = max(step_x, 0.01)
	step_y = max(step_y, 0.01)
	step_z = max(step_z, 0.01)
	
	var edges: Array = []
	
	# X direction lines (parallel to X axis)
	var y = min_bounds.y
	while y <= max_bounds.y + 0.001:
		var z = min_bounds.z
		while z <= max_bounds.z + 0.001:
			edges.append([
				Vector3(min_bounds.x, y, z),
				Vector3(max_bounds.x, y, z)
			])
			z += step_z
		y += step_y
			
	# Y direction lines (parallel to Y axis)
	var x = min_bounds.x
	while x <= max_bounds.x + 0.001:
		var z = min_bounds.z
		while z <= max_bounds.z + 0.001:
			edges.append([
				Vector3(x, min_bounds.y, z),
				Vector3(x, max_bounds.y, z)
			])
			z += step_z
		x += step_x
	
	# Z direction lines (parallel to Z axis)
	x = min_bounds.x
	while x <= max_bounds.x + 0.001:
		y = min_bounds.y
		while y <= max_bounds.y + 0.001:
			edges.append([
				Vector3(x, y, min_bounds.z),
				Vector3(x, y, max_bounds.z)
			])
			y += step_y
		x += step_x
	
	# Create a visual grid using ArrayMesh (works at runtime)
	# Validate that we have edges to draw
	if edges.is_empty():
		print("Warning: No grid edges generated for mesh")
		return
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	var vertex_count = 0
	# Add all grid lines as line segments
	for edge_pair in edges:
		if edge_pair.size() >= 2:  # Ensure we have both start and end points
			var start_point = edge_pair[0] + mesh_instance.position
			var end_point = edge_pair[1] + mesh_instance.position
			
			surface_tool.set_color(grid_color)
			surface_tool.add_vertex(start_point)
			surface_tool.add_vertex(end_point)
			vertex_count += 2
	
	# Only create mesh if we have at least one complete line (2 vertices)
	if vertex_count < 2:
		print("Warning: Not enough vertices for grid lines (", vertex_count, ")")
		return
	
	# Commit to mesh and create instance
	var grid_mesh = surface_tool.commit()
	var grid_instance = MeshInstance3D.new()
	grid_instance.mesh = grid_mesh
	
	# Optional: Create wireframe material
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = grid_color
	line_material.flags_unshaded = true
	line_material.vertex_color_use_as_albedo = true
	grid_instance.material_override = line_material
	
	# Add to scene
	add_child(grid_instance)
	
	# Set initial visibility
	grid_instance.visible = initial_visibility
	
	# Store reference for runtime toggling based on mesh position
	if mesh_instance.position.x < 2.5:  # Control mesh is at x=0
		control_grid_nodes.append(grid_instance)
	else:  # Simplified meshes are at x>=5
		simplified_grid_nodes.append(grid_instance)

func create_3d_grid_matrix(mesh_instance: MeshInstance3D) -> Dictionary:
	# Get mesh data
	var mesh = mesh_instance.mesh
	var aabb = mesh.get_aabb()
	var min_bounds = aabb.position
	var max_bounds = aabb.position + aabb.size
	
	# Calculate grid dimensions
	var step_x = aabb.size.x * tolerance_epsylon
	var step_y = aabb.size.y * tolerance_epsylon
	var step_z = aabb.size.z * tolerance_epsylon
	
	step_x = max(step_x, 0.01)
	step_y = max(step_y, 0.01)
	step_z = max(step_z, 0.01)
	
	var grid_x = int(ceil(aabb.size.x / step_x))
	var grid_y = int(ceil(aabb.size.y / step_y))
	var grid_z = int(ceil(aabb.size.z / step_z))
	
	# Initialize 3D grid as nested arrays
	var grid = []
	for x in range(grid_x):
		grid.append([])
		for y in range(grid_y):
			grid[x].append([])
			for z in range(grid_z):
				grid[x][y].append([]) # Each cell contains array of vertex indices
	
	# Validate mesh has surfaces
	if mesh.get_surface_count() == 0:
		print("Error: Mesh has no surfaces")
		return {
			"grid": [],
			"dimensions": Vector3.ZERO,
			"step_size": Vector3.ZERO,
			"bounds": {"min": Vector3.ZERO, "max": Vector3.ZERO},
			"total_vertices": 0
		}
	
	# Get vertex data from mesh
	var arrays = mesh.surface_get_arrays(0)
	if arrays[Mesh.ARRAY_VERTEX] == null:
		print("Error: Mesh has no vertex data")
		return {
			"grid": [],
			"dimensions": Vector3.ZERO,
			"step_size": Vector3.ZERO,
			"bounds": {"min": Vector3.ZERO, "max": Vector3.ZERO},
			"total_vertices": 0
		}
	
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	
	var total_vertices = 0
	
	# Distribute vertices into grid cells
	for i in range(vertices.size()):
		var vertex = vertices[i]
		
		# Calculate grid coordinates for this vertex
		var grid_coord_x = int((vertex.x - min_bounds.x) / step_x)
		var grid_coord_y = int((vertex.y - min_bounds.y) / step_y)
		var grid_coord_z = int((vertex.z - min_bounds.z) / step_z)
		
		# Clamp coordinates to valid range
		grid_coord_x = clamp(grid_coord_x, 0, grid_x - 1)
		grid_coord_y = clamp(grid_coord_y, 0, grid_y - 1)
		grid_coord_z = clamp(grid_coord_z, 0, grid_z - 1)
		
		# Add vertex index to the corresponding grid cell
		grid[grid_coord_x][grid_coord_y][grid_coord_z].append(i)
		total_vertices += 1
	
	# Return grid data structure
	return {
		"grid": grid,
		"dimensions": Vector3(grid_x, grid_y, grid_z),
		"step_size": Vector3(step_x, step_y, step_z),
		"bounds": {"min": min_bounds, "max": max_bounds},
		"total_vertices": total_vertices
	}

func visualize_grid_occupancy(grid_data: Dictionary, mesh_instance: MeshInstance3D, initial_visibility: bool = true) -> void:
	var grid = grid_data.grid
	var dimensions = grid_data.dimensions
	var min_bounds = grid_data.bounds.min
	var step_size = grid_data.step_size
	
	# Create small cubes to show occupied cells
	for x in range(dimensions.x):
		for y in range(dimensions.y):
			for z in range(dimensions.z):
				var cell_contents = grid[x][y][z]
				
				# Only visualize cells that contain vertices
				if cell_contents.size() > 0:
					var cell_center = min_bounds + Vector3(
						(x + 0.5) * step_size.x,
						(y + 0.5) * step_size.y,
						(z + 0.5) * step_size.z
					) + mesh_instance.position
					
					# Create a small cube to represent this occupied cell
					var cube_mesh = BoxMesh.new()
					cube_mesh.size = step_size * 0.8  # Slightly smaller than full cell
					
					var cube_instance = MeshInstance3D.new()
					cube_instance.mesh = cube_mesh
					cube_instance.position = cell_center
					
					# Color based on vertex density
					var vertex_count = cell_contents.size()
					var intensity = min(vertex_count / 10.0, 1.0)  # Normalize to 0-1
					var material = StandardMaterial3D.new()
					material.albedo_color = Color(0, intensity, 1.0 - intensity, 0.3)  # Blue to red gradient
					material.flags_transparent = true
					cube_instance.material_override = material
					
					add_child(cube_instance)
					
					# Set initial visibility
					cube_instance.visible = initial_visibility
					
					# Store reference for runtime toggling based on mesh position
					if mesh_instance.position.x < 2.5:  # Control mesh is at x=0
						control_occupancy_nodes.append(cube_instance)
					else:  # Simplified meshes are at x>=5
						simplified_occupancy_nodes.append(cube_instance)

func create_simplified_mesh(original_mesh: Mesh) -> ArrayMesh:
	# Validate input mesh
	if original_mesh == null:
		print("Error: Original mesh is null")
		return ArrayMesh.new()
	
	if original_mesh.get_surface_count() == 0:
		print("Error: Original mesh has no surfaces")
		return ArrayMesh.new()
	
	# Get original mesh data
	var arrays = original_mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals = arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var uvs = arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	
	# Validate input data
	if vertices.size() == 0:
		print("Error: No vertices in original mesh")
		return ArrayMesh.new()
	
	# Handle indices properly - for non-indexed meshes, vertices are in triangle order
	var indices: PackedInt32Array
	if arrays[Mesh.ARRAY_INDEX] != null:
		indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	else:
		# For non-indexed meshes, create sequential indices
		indices = PackedInt32Array()
		for i in range(vertices.size()):
			indices.append(i)
	
	print("Input mesh: ", vertices.size(), " vertices, ", indices.size() / 3.0, " triangles")
	
	# Get bounding box for grid calculation
	var aabb = original_mesh.get_aabb()
	var min_bounds = aabb.position
	
	# Calculate grid dimensions
	var step_x = aabb.size.x * tolerance_epsylon
	var step_y = aabb.size.y * tolerance_epsylon
	var step_z = aabb.size.z * tolerance_epsylon
	
	step_x = max(step_x, 0.01)
	step_y = max(step_y, 0.01)
	step_z = max(step_z, 0.01)
	
	var grid_x = int(ceil(aabb.size.x / step_x))
	var grid_y = int(ceil(aabb.size.y / step_y))
	var grid_z = int(ceil(aabb.size.z / step_z))
	
	# Create grid cells to store vertex data
	var grid_cells = {}
	
	# Group vertices by grid cell
	for i in range(vertices.size()):
		var vertex = vertices[i]
		
		# Calculate grid coordinates
		var grid_coord_x = int((vertex.x - min_bounds.x) / step_x)
		var grid_coord_y = int((vertex.y - min_bounds.y) / step_y)
		var grid_coord_z = int((vertex.z - min_bounds.z) / step_z)
		
		# Clamp coordinates to ensure valid range
		grid_coord_x = clamp(grid_coord_x, 0, grid_x - 1)
		grid_coord_y = clamp(grid_coord_y, 0, grid_y - 1)
		grid_coord_z = clamp(grid_coord_z, 0, grid_z - 1)
		
		# Create unique key for this grid cell
		var cell_key = str(grid_coord_x) + "," + str(grid_coord_y) + "," + str(grid_coord_z)
		
		# Initialize cell if doesn't exist
		if not grid_cells.has(cell_key):
			grid_cells[cell_key] = {
				"vertices": [],
				"normals": [],
				"uvs": [],
				"original_indices": []
			}
		
		# Add vertex data to cell
		grid_cells[cell_key].vertices.append(vertex)
		if normals.size() > i:
			grid_cells[cell_key].normals.append(normals[i])
		else:
			grid_cells[cell_key].normals.append(Vector3.UP)  # Default normal if missing
		if uvs.size() > i:
			grid_cells[cell_key].uvs.append(uvs[i])
		else:
			grid_cells[cell_key].uvs.append(Vector2.ZERO)  # Default UV if missing
		grid_cells[cell_key].original_indices.append(i)
	
	# Calculate averaged vertices for each cell
	var vertex_mapping = {}  # Maps original vertex index to new vertex index
	var new_vertices = PackedVector3Array()
	var new_normals = PackedVector3Array()
	var new_uvs = PackedVector2Array()
	var new_vertex_index = 0
	
	for cell_key in grid_cells.keys():
		var cell = grid_cells[cell_key]
		
		# Calculate average position, normal, and UV
		var avg_pos = Vector3.ZERO
		var avg_normal = Vector3.ZERO
		var avg_uv = Vector2.ZERO
		var vertex_count = cell.vertices.size()
		
		for j in range(vertex_count):
			avg_pos += cell.vertices[j]
			if j < cell.normals.size():
				avg_normal += cell.normals[j]
			if j < cell.uvs.size():
				avg_uv += cell.uvs[j]
		
		avg_pos /= vertex_count
		
		# Ensure we have a valid normal
		if avg_normal.length_squared() > 0.001:
			avg_normal = avg_normal.normalized()
		else:
			avg_normal = Vector3.UP  # Fallback normal
		
		if cell.uvs.size() > 0:
			avg_uv /= vertex_count
		
		# Add new averaged vertex
		new_vertices.append(avg_pos)
		new_normals.append(avg_normal)
		if uvs.size() > 0:
			new_uvs.append(avg_uv)
		
		# Map all original vertices in this cell to the new averaged vertex
		for original_idx in cell.original_indices:
			vertex_mapping[original_idx] = new_vertex_index
		
		new_vertex_index += 1
	
	# Rebuild indices using the vertex mapping
	var new_indices = PackedInt32Array()
	for i in range(0, indices.size(), 3):
		# Ensure we have 3 indices for a complete triangle
		if i + 2 >= indices.size():
			break
		
		# Get mapped indices with validation
		var orig_idx0 = indices[i]
		var orig_idx1 = indices[i + 1]
		var orig_idx2 = indices[i + 2]
		
		# Check if all original indices have mappings
		if not vertex_mapping.has(orig_idx0) or not vertex_mapping.has(orig_idx1) or not vertex_mapping.has(orig_idx2):
			print("Warning: Missing vertex mapping for triangle ", i / 3.0)
			continue
		
		var idx0 = vertex_mapping[orig_idx0]
		var idx1 = vertex_mapping[orig_idx1]
		var idx2 = vertex_mapping[orig_idx2]
		
		# Only add triangle if all vertices are different (avoid degenerate triangles)
		if idx0 != idx1 and idx1 != idx2 and idx0 != idx2:
			new_indices.append(idx0)
			new_indices.append(idx1)
			new_indices.append(idx2)
	
	# Validate we have vertices to create a mesh
	if new_vertices.size() == 0:
		print("Error: No vertices after simplification")
		return ArrayMesh.new()
	
	if new_indices.size() == 0:
		print("Error: No valid triangles after simplification")
		return ArrayMesh.new()
	
	# Create new mesh using array approach for better control
	var new_arrays = []
	new_arrays.resize(Mesh.ARRAY_MAX)
	new_arrays[Mesh.ARRAY_VERTEX] = new_vertices
	new_arrays[Mesh.ARRAY_NORMAL] = new_normals
	if new_uvs.size() > 0:
		new_arrays[Mesh.ARRAY_TEX_UV] = new_uvs
	new_arrays[Mesh.ARRAY_INDEX] = new_indices
	
	var simplified_mesh = ArrayMesh.new()
	simplified_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays)
	
	# Calculate reduction ratios
	var vertex_reduction = (1.0 - float(new_vertices.size()) / float(vertices.size())) * 100.0
	var triangle_reduction = (1.0 - float(new_indices.size()) / float(indices.size())) * 100.0
	
	print("Mesh simplified: ")
	print("  Vertices: ", vertices.size(), " -> ", new_vertices.size(), " (", "%.1f" % vertex_reduction, "% reduction)")
	print("  Triangles: ", indices.size() / 3.0, " -> ", new_indices.size() / 3.0, " (", "%.1f" % triangle_reduction, "% reduction)")
	print("  Grid cells occupied: ", grid_cells.size())
	
	return simplified_mesh

func add_simplification(changed_epsilon: float = -1, translation: Vector3 = Vector3(2, 0, 0), message: String = "Simplified") -> void:
	var save_epsilon: float = tolerance_epsylon
	if changed_epsilon != -1:
		tolerance_epsylon = changed_epsilon
	
	# Rabbit at 0x5x0
	var simplified_rabbit: MeshInstance3D = MeshInstance3D.new()
	simplified_rabbit.position = Vector3.ZERO + translation
	simplified_rabbit.mesh = bunny_mesh
	
	# Add no-culling material
	var simplified_material = StandardMaterial3D.new()
	simplified_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	simplified_material.albedo_color = Color(0.6, 0.8, 1.0)
	simplified_rabbit.material_override = simplified_material
	
	add_child(simplified_rabbit)
	
	# Add small text above
	var simplified_text_mesh: TextMesh = TextMesh.new()
	simplified_text_mesh.text = message
	var simplified_text: MeshInstance3D = MeshInstance3D.new()
	simplified_text.mesh = simplified_text_mesh
	simplified_text.position = Vector3.UP * 1.5 + translation
	add_child(simplified_text)
	
	# Add pedestral
	var simplified_plane_mesh: PlaneMesh = PlaneMesh.new()
	var simplified_pedestral: MeshInstance3D = MeshInstance3D.new()
	simplified_pedestral.mesh = simplified_plane_mesh
	simplified_pedestral.position = Vector3.DOWN * 0.65 + translation
	add_child(simplified_pedestral)

	# Simplify the mesh using grid-based vertex averaging
	var simplified_mesh = create_simplified_mesh(bunny_mesh)
	simplified_rabbit.mesh = simplified_mesh
	
	# Build grid visualization for simplified mesh using base mesh bounds
	build_grid(simplified_rabbit, show_simplified_grid, show_simplified_occupancy, Color.GREEN, bunny_mesh)
	
	print("Simplified mesh created with vertex averaging")
	
	# Validate the simplified mesh
	validate_mesh(simplified_mesh, message)
	
	tolerance_epsylon = save_epsilon

func validate_mesh(mesh: Mesh, label: String = "Mesh") -> void:
	if mesh == null:
		print("ERROR: ", label, " is null")
		return
	
	if mesh.get_surface_count() == 0:
		print("ERROR: ", label, " has no surfaces")
		return
	
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array if arrays[Mesh.ARRAY_VERTEX] != null else PackedVector3Array()
	var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	
	print("Validation for ", label, ":")
	print("  Surface count: ", mesh.get_surface_count())
	print("  Vertices: ", vertices.size())
	print("  Indices: ", indices.size())
	print("  Triangles: ", indices.size() / 3.0)
	print("  AABB: ", mesh.get_aabb())
	
	# Check for potential issues
	if vertices.size() == 0:
		print("  WARNING: No vertices!")
	if indices.size() == 0:
		print("  WARNING: No indices!")
	if indices.size() % 3 != 0:
		print("  WARNING: Index count is not divisible by 3!")
	
	# Check index bounds
	var max_vertex_index = vertices.size() - 1
	for i in range(indices.size()):
		if indices[i] > max_vertex_index:
			print("  ERROR: Index ", indices[i], " out of bounds (max: ", max_vertex_index, ")")
			break

func toggle_visualization_nodes(nodes: Array[Node3D], should_show: bool) -> void:
	for node in nodes:
		if is_instance_valid(node):
			node.visible = should_show

func print_keybind_help() -> void:
	print("""
	=== Visualization Toggle Controls ===
	1: Toggle Control Grid (Red)
	2: Toggle Control Occupancy (Cubes)
	3: Toggle Simplified Grid (Green) 
	4: Toggle Simplified Occupancy (Cubes)
	G: Toggle ALL Grids
	O: Toggle ALL Occupancy
	H: Show this help
	""")
	
