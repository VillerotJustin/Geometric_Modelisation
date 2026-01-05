extends Node3D

# Random shape subdivision

@export var show_shape: bool = true

var mesh_instance: MeshInstance3D
var base_vertices
var edges
var face_indices


func _ready():
	if show_shape:
		create_start_shape()

func initialise_mat():
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.set_surface_override_material(0, material)
	

func create_start_shape() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create an icosahedron - good starting shape for subdivision
	var phi = (1.0 + sqrt(5.0)) / 2.0
	var scale_factor = 1.0 / sqrt(1.0 + phi * phi)
	
	base_vertices = [
		Vector3(-1.5, phi, 0) * scale_factor * randf_range(0.8, 10.2),
		Vector3(1.3, phi, 0) * scale_factor * randf_range(0.8, 10.2),
		Vector3(-1.4, -phi, 0) * scale_factor * randf_range(0.8, 10.2),
		Vector3(0.5, -phi, 0) * scale_factor * randf_range(0.8, 10.2),
		Vector3(0.2, -1, phi) * scale_factor * randf_range(0.8, 10.2),
		Vector3(0.4, 1, phi) * scale_factor * randf_range(0.8, 10.2),
		Vector3(0.3, -1.1, -phi) * scale_factor * randf_range(0.8, 10.2),
		Vector3(0.2, 1.3, -phi) * scale_factor * randf_range(0.8, 10.2),
		Vector3(phi, 0, -1) * scale_factor * randf_range(0.8, 10.2),
		Vector3(phi, 0, 1) * scale_factor * randf_range(0.8, 10.2),
		Vector3(-phi, 0, -1) * scale_factor * randf_range(0.8, 10.2),
		Vector3(-phi, 0, 1) * scale_factor * randf_range(0.8, 10.2)
	]
	
	edges = [
		[0, 5], [0, 11], [0, 1], [0, 7], [0, 10],
		[1, 5], [1, 9], [1, 8], [1, 7],
		[2, 10], [2, 11], [2, 4], [2, 6], [2, 3],
		[3, 4], [3, 9], [3, 8], [3, 6],
		[4, 5], [4, 9], [4, 11],
		[5, 9], [5, 11],
		[6, 7], [6, 8], [6, 10],
		[7, 8], [7, 10],
		[8, 9],
		[10, 11]
	]
	
	face_indices = [
		[0, 5, 11], [0, 1, 5], [0, 7, 1], [0, 10, 7], [0, 11, 10],
		[1, 9, 5], [5, 4, 11], [11, 2, 10], [10, 6, 7], [7, 8, 1],
		[3, 4, 9], [3, 2, 4], [3, 6, 2], [3, 8, 6], [3, 9, 8],
		[4, 5, 9], [2, 11, 4], [6, 10, 2], [8, 7, 6], [9, 1, 8]
	]
	
	create_mesh()
	
func create_mesh() -> void:
	var array_mesh = ArrayMesh.new()
	
	# Create mesh with per-face colors
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	var vertex_index = 0
	for face in face_indices:
		var face_color = Color(randf(), randf(), randf())
		
		vertices.append(base_vertices[face[0]])
		vertices.append(base_vertices[face[1]])
		vertices.append(base_vertices[face[2]])
		
		colors.append(face_color)
		colors.append(face_color)
		colors.append(face_color)
		
		indices.append(vertex_index)
		indices.append(vertex_index + 1)
		indices.append(vertex_index + 2)
		
		vertex_index += 3
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh
	
	initialise_mat()

func clear_old_objects() -> void:
	if mesh_instance:
		mesh_instance.queue_free()
	

func _physics_process(_delta: float) -> void:
	# Take input for loop subdivision
	if Input.is_action_just_pressed("ui_text_submit"):
		subdivision()
	if Input.is_action_just_pressed("ui_text_backspace"):
		clear_old_objects()
		create_start_shape()

func get_or_create_midpoint(v1_idx: int, v2_idx: int, vertices: Array, cache: Dictionary) -> int:
	# Create a sorted key to ensure edge (0,1) and (1,0) are treated the same
	var key = [min(v1_idx, v2_idx), max(v1_idx, v2_idx)]
	var key_str = str(key)
	
	if cache.has(key_str):
		return cache[key_str]
	
	# Create new midpoint vertex
	var midpoint = find_middle(vertices[v1_idx], vertices[v2_idx])
	var new_index = vertices.size()
	vertices.append(midpoint)
	cache[key_str] = new_index
	
	return new_index

func find_middle(vert1:Vector3, vert2:Vector3) -> Vector3:
	return vert1 + (vert2 - vert1)*0.5

func subdivision() -> void:
	clear_old_objects()
	
	var new_vertices = base_vertices.duplicate()
	var new_edges = []
	var new_faces = []

	# Dictionary to store midpoint vertices: key is sorted edge (min,max), value is new vertex index
	var midpoint_cache = {}
	
	for face in face_indices:
		var v0 = face[0]
		var v1 = face[1]
		var v2 = face[2]
		
		# Get or create midpoint indices for each edge
		var m01 = get_or_create_midpoint(v0, v1, new_vertices, midpoint_cache)
		var m12 = get_or_create_midpoint(v1, v2, new_vertices, midpoint_cache)
		var m20 = get_or_create_midpoint(v2, v0, new_vertices, midpoint_cache)
		
		# Create 4 new faces
		new_faces.append([v0, m01, m20])
		new_faces.append([v1, m12, m01])
		new_faces.append([v2, m20, m12])
		new_faces.append([m01, m12, m20])

		# Create new edges
		new_edges.append_array([
			[v0, m01], [m01, m20], [m20, v0],
			[v1, m12], [m12, m01], [m01, v1],
			[v2, m20], [m20, m12], [m12, v2],
			[m01, m12], [m12, m20], [m20, m01]
		])

	new_vertices = apply_loop_smoothing(new_vertices, new_faces)
	
	base_vertices = new_vertices
	edges = new_edges
	face_indices = new_faces
	
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	create_mesh()

func apply_loop_smoothing(vertices:Array, faces:Array) -> Array:
	var smoothed_vertices = []
	smoothed_vertices.resize(vertices.size())

	# Adjacency info
	var vertex_neighbors = {}

	for face in faces:
		for i in range(3):
			var v_current = face[i]
			var v_next = face[(i + 1) % 3]
			
			if not vertex_neighbors.has(v_current):
				vertex_neighbors[v_current] = []
			if not vertex_neighbors.has(v_next):
				vertex_neighbors[v_next] = []
			
			if v_current not in vertex_neighbors[v_next]:
				vertex_neighbors[v_next].append(v_current)
			if v_next not in vertex_neighbors[v_current]:
				vertex_neighbors[v_current].append(v_next)
	
	# Smoothing
	for i in range(vertices.size()):
		# Pass non found vertices
		if not vertex_neighbors.has(i):
			smoothed_vertices[i] = vertices[i]
			continue
		
		var neighbors = vertex_neighbors[i]
		var n = neighbors.size()
		
		# Pass alone vertices
		if n == 0:
			smoothed_vertices[i] = vertices[i]
			continue
		
		# Caculate Beta (Waren's Formula)
		var beta: float
		
		if n == 3:
			beta = 3.0 / 16.0
		else:
			beta = (1.0 / n) * (5.0 / 8.0 - pow((3.0 / 8.0 + 0.25 * cos(2.0 * PI / n)), 2))
		
		# Apply Smoothing
		var neighbors_sum: Vector3 = Vector3.ZERO
		for neighbors_idx in neighbors:
			neighbors_sum += vertices[neighbors_idx]
		
		smoothed_vertices[i] = (1.0 - n * beta) * vertices[i] + beta * neighbors_sum
		
	return smoothed_vertices
