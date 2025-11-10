extends Node

class_name Mesh_Helpers

# -----------------------------
# Helpers
# -----------------------------
static func _create_standard_material(color: Color) -> StandardMaterial3D:
	var m:StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	# m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func _get_tangent_bitangent(normal: Vector3) -> Array:
	var n:Vector3 = normal.normalized()
	var tangent:Vector3 = n.cross(Vector3(0, 0, 1))
	if tangent.length_squared() < 0.01:
		tangent = n.cross(Vector3(0, 1, 0))
	return [tangent.normalized(), n.cross(tangent).normalized()]

static func _make_mesh_instance(mesh: ArrayMesh, position: Vector3) -> MeshInstance3D:
	var mi:MeshInstance3D = MeshInstance3D.new()
	mi.position = position
	mi.mesh = mesh
	return mi

static func _commit_vertices_to_mesh(mesh: ArrayMesh, color: Color, vertices: PackedVector3Array, uvs: PackedVector2Array, normals: PackedVector3Array = PackedVector3Array()) -> void:
	var st:SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(_create_standard_material(color))
	var use_normals := normals.size() == vertices.size()
	for i in range(vertices.size()):
		st.set_color(color)
		if uvs.size() == vertices.size():
			st.set_uv(uvs[i])
		if use_normals:
			st.set_normal(normals[i])
			st.add_vertex(vertices[i])
			st.commit(mesh)

static func _commit_vertices_to_mesh_advanced(mesh: ArrayMesh, color: PackedColorArray, vertices: PackedVector3Array, uvs: PackedVector2Array, normals: PackedVector3Array = PackedVector3Array()) -> ArrayMesh:
	var st:SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(_create_standard_material(Color()))
	var use_normals := normals.size() == vertices.size()
	for i in range(vertices.size()):
		st.set_color(color[i])
		if uvs.size() == vertices.size():
			st.set_uv(uvs[i])
		if use_normals:
			st.set_normal(normals[i])
			st.add_vertex(vertices[i])
	
	st.commit(mesh)
	
	return mesh

static func _find_mesh_gravity_center(mesh: ArrayMesh) -> Vector3:
	var gravity_center:Vector3 = Vector3.ZERO
	var vertex_count:int = 0
	
	# Iterate through all surfaces in the mesh
	for surface_idx in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface_idx)
		var vertices:PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		
		for vertex in vertices:
			gravity_center += vertex
			vertex_count += 1
	
	if vertex_count > 0:
		gravity_center /= vertex_count
	
	return gravity_center
	
static func _normalise_mesh(mesh: ArrayMesh, center: Vector3 = Vector3.ZERO) -> ArrayMesh:
	# Find the maximum absolute coordinate value to scale mesh to [-1, 1] cube
	var max_coord: float = 0.0
	
	# Iterate through all surfaces to find the furthest coordinate from center
	for surface_idx in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface_idx)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		
		for vertex in vertices:
			# Translate vertex to origin (subtract center)
			var centered_vertex = vertex - center
			# Check each coordinate axis
			max_coord = max(max_coord, abs(centered_vertex.x))
			max_coord = max(max_coord, abs(centered_vertex.y))
			max_coord = max(max_coord, abs(centered_vertex.z))
	
	# If max_coord is 0, return the mesh as-is to avoid division by zero
	if max_coord == 0.0:
		return mesh
	
	# Create a new normalized mesh
	var normalized_mesh = ArrayMesh.new()
	var scale_factor = 1.0 / max_coord
	
	for surface_idx in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface_idx)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		
		# Center and scale all vertices to fit in [-1, 1] cube
		var new_vertices = PackedVector3Array()
		for vertex in vertices:
			# First translate to origin, then scale
			new_vertices.append((vertex - center) * scale_factor)
		
		# Update the arrays with scaled vertices
		arrays[Mesh.ARRAY_VERTEX] = new_vertices
		
		# Add the surface to the new mesh
		normalized_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		# Copy material if it exists
		var material = mesh.surface_get_material(surface_idx)
		if material:
			normalized_mesh.surface_set_material(surface_idx, material)
	
	return normalized_mesh

static func _remove_random_faces(modified_mesh: ArrayMesh, number: int) -> ArrayMesh:
	# Extract all vertices and build face list
	var all_vertices: PackedVector3Array = PackedVector3Array()
	var all_normals: PackedVector3Array = PackedVector3Array()
	var all_colors: PackedColorArray = PackedColorArray()
	var all_uvs: PackedVector2Array = PackedVector2Array()
	
	# Collect all mesh data from all surfaces
	for surface_idx in range(modified_mesh.get_surface_count()):
		var surface_arrays = modified_mesh.surface_get_arrays(surface_idx)
		var vertices: PackedVector3Array = surface_arrays[Mesh.ARRAY_VERTEX]
		all_vertices.append_array(vertices)
		
		if surface_arrays[Mesh.ARRAY_NORMAL] != null:
			var normals: PackedVector3Array = surface_arrays[Mesh.ARRAY_NORMAL]
			all_normals.append_array(normals)
		
		if surface_arrays[Mesh.ARRAY_COLOR] != null:
			var colors: PackedColorArray = surface_arrays[Mesh.ARRAY_COLOR]
			all_colors.append_array(colors)
		
		if surface_arrays[Mesh.ARRAY_TEX_UV] != null:
			var uvs: PackedVector2Array = surface_arrays[Mesh.ARRAY_TEX_UV]
			all_uvs.append_array(uvs)
	
	# Calculate number of faces (each triangle = 3 vertices)
	var total_faces: int = int(all_vertices.size() / 3.0)
	var faces_to_remove: int = min(number, total_faces)
	
	# Generate list of face indices to remove (random selection without replacement)
	var faces_to_remove_set: Array[int] = []
	while faces_to_remove_set.size() < faces_to_remove:
		var random_face: int = randi() % total_faces
		if random_face not in faces_to_remove_set:
			faces_to_remove_set.append(random_face)
	
	# Build new mesh excluding removed faces
	var new_vertices: PackedVector3Array = PackedVector3Array()
	var new_normals: PackedVector3Array = PackedVector3Array()
	var new_colors: PackedColorArray = PackedColorArray()
	var new_uvs: PackedVector2Array = PackedVector2Array()
	
	for face_idx in range(total_faces):
		if face_idx not in faces_to_remove_set:
			var vertex_start: int = face_idx * 3
			# Copy the 3 vertices of this face
			for j in range(3):
				var v_idx: int = vertex_start + j
				new_vertices.append(all_vertices[v_idx])
				
				if all_normals.size() > v_idx:
					new_normals.append(all_normals[v_idx])
				
				if all_colors.size() > v_idx:
					new_colors.append(all_colors[v_idx])
				
				if all_uvs.size() > v_idx:
					new_uvs.append(all_uvs[v_idx])
	
	# Create new mesh with remaining faces
	var result_mesh: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = new_vertices
	
	if new_normals.size() == new_vertices.size():
		arrays[Mesh.ARRAY_NORMAL] = new_normals
	
	if new_colors.size() == new_vertices.size():
		arrays[Mesh.ARRAY_COLOR] = new_colors
	
	if new_uvs.size() == new_vertices.size():
		arrays[Mesh.ARRAY_TEX_UV] = new_uvs
	
	result_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Copy material from original mesh if it exists
	if modified_mesh.get_surface_count() > 0:
		var material = modified_mesh.surface_get_material(0)
		if material:
			result_mesh.surface_set_material(0, material)
	
	return result_mesh
