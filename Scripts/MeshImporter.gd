extends Node

class_name Mesh_Importer

# Helper function to calculate spherical UVs for a vertex
static func _calculate_spherical_uv(vertex: Vector3, center: Vector3) -> Vector2:
	var dir = (vertex - center).normalized()
	var u = 0.5 + atan2(dir.z, dir.x) / TAU
	var v = 0.5 - asin(clamp(dir.y, -1.0, 1.0)) / PI
	return Vector2(u, v)

static func read_off(file_path: String) -> MeshInstance3D:
	print("Importing mesh from .off at : "+ file_path)
	var mesh_file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	
	if mesh_file == null:
		push_error("Failed to open file: %s" % file_path)
		return
	
	var line:String = mesh_file.get_line()
	if line != "OFF":
		push_error("File %s isn't and OFF file" % file_path)
		return
	
	# Get Mesh info (the number of vertices, number of faces, and number of edges (potentialy 0))
	line = mesh_file.get_line()
	var header_info:PackedStringArray = line.split(" ", true)
	if header_info.size() != 3:
		push_error("File %s header are invalid" % file_path)
		return
	var n_verts: int = header_info[0].to_int()
	var n_faces: int = header_info[1].to_int()
	var _n_edges: int = header_info[2].to_int()
	
	# Extracting vertices
	var vertices: PackedVector3Array
	
	for i in range(n_verts):
		var split_line: PackedStringArray = mesh_file.get_line().split(" ")
		if split_line.size() != 3 :
			push_error("File %s vertices wrongly fformated" % file_path)
			return
		vertices.append(Vector3(
			split_line[0].to_float(),
			split_line[1].to_float(),
			split_line[2].to_float()
		))
	
	# Extracting faces
	var faces: Array[Dictionary]
	
	for i in range(n_faces):
		var r_line: String = mesh_file.get_line().strip_edges()
		var split_line: PackedStringArray = r_line.split(" ", true)
		var number_vertix: int = split_line[0].to_int()
		
		if split_line.size() != number_vertix + 1 and split_line.size() != number_vertix+4:
			push_error("File %s vertices wrongly formated" % file_path)
			return
		var vertixes: Array[int]
		for v in range(number_vertix):
			vertixes.append(split_line[1+v].to_int())
		
		# Get color if exist
		var color: Color = Color.BLACK
		if split_line.size() == 3 + number_vertix + 1:
			color = Color(split_line[1 + number_vertix + 1].to_float(), split_line[1 + number_vertix + 2].to_float(), split_line[1 + number_vertix + 3].to_float())
		
		faces.append({
			"vertex_numbers": number_vertix,
			"vertexes": vertixes,
			"color": color
		})
	
	# Extracting edges
	# TODO might be useless
	
	mesh_file.close()

	# Calculating center of the mesh
	var center: Vector3 = Vector3.ZERO
	for v in vertices:
		center += v
	center /= vertices.size()
	
	var mesh: ArrayMesh = ArrayMesh.new()
	
	# Making final lists
	var processed_vertices: PackedVector3Array = PackedVector3Array()
	var processed_normals: PackedVector3Array = PackedVector3Array()
	var processed_color: PackedColorArray = PackedColorArray()
	var processed_uvs: PackedVector2Array = PackedVector2Array()
	
	for face in faces:
		#print(face)
		var nx:float = 0
		var ny:float = 0
		var nz:float = 0
		
		# Calculating normal With Newell's method
		for vi_index in range(face["vertex_numbers"]):
			var vi = face["vertexes"][vi_index]
			var vi_next = face["vertexes"][(vi_index + 1) % face["vertex_numbers"]]

			nx += (vertices[vi].y - vertices[vi_next].y) * (vertices[vi].z + vertices[vi_next].z)
			ny += (vertices[vi].z - vertices[vi_next].z) * (vertices[vi].x + vertices[vi_next].x)
			nz += (vertices[vi].x - vertices[vi_next].x) * (vertices[vi].y + vertices[vi_next].y)
			
		# Calculate normal of face
		var normal:Vector3 = -Vector3(nx, ny, nz).normalized()

		# Triangulate face using fan method
		# All triangles share the first vertex
		var v0_index: int = face["vertexes"][0]
		for tri_index in range(1, face["vertex_numbers"] - 1):
			var v1_index: int = face["vertexes"][tri_index]
			var v2_index: int = face["vertexes"][tri_index + 1]
			
			# Add triangle vertices
			processed_vertices.append(vertices[v0_index])
			processed_vertices.append(vertices[v1_index])
			processed_vertices.append(vertices[v2_index])

			# Add colors (same for all three vertices of this triangle)
			processed_color.append(face["color"])
			processed_color.append(face["color"])
			processed_color.append(face["color"])

			# Add normals
			processed_normals.append(normal)
			processed_normals.append(normal)
			processed_normals.append(normal)

			# Add UVs using spherical projection
			processed_uvs.append(_calculate_spherical_uv(vertices[v0_index], center))
			processed_uvs.append(_calculate_spherical_uv(vertices[v1_index], center))
			processed_uvs.append(_calculate_spherical_uv(vertices[v2_index], center))

	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0, 0.8, 0.8, 1)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	#mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	st.set_material(mat)
	
	for i in range(processed_vertices.size()):
		st.set_normal(processed_normals[i])
		st.set_color(processed_color[i])
		st.set_uv(processed_uvs[i])
		st.add_vertex(processed_vertices[i])
	
	mesh = st.commit()
	
	var gravity_center: Vector3 = Mesh_Helpers._find_mesh_gravity_center(mesh)
	
	var normalised_mesh:ArrayMesh = Mesh_Helpers._normalise_mesh(mesh, gravity_center)
	
	var mi:MeshInstance3D = MeshInstance3D.new()
	mi.mesh = normalised_mesh
	
	print("Mesh Imported vertices %s  faces %s" % [n_verts, n_faces])
	
	print(mi)
	
	return mi

static func export_off(mesh: ArrayMesh, file_path: String, overwrite: bool = false) -> void:
	print("Exporting ", mesh, " to ", file_path)
	
	# Check if file exists and overwrite is disabled
	if FileAccess.file_exists(file_path) and !overwrite:
		push_error("File already exists, enable overwrite: %s" % file_path)
		return
	
	var mesh_file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	
	if mesh_file == null:
		push_error("Failed to open file for writing: %s" % file_path)
		return
	
	# Extract vertices and faces from ArrayMesh
	var vertices_dict: Dictionary = {}  # Maps vertex position to index
	var vertices_list: PackedVector3Array = PackedVector3Array()
	var faces_list: Array[PackedInt32Array] = []
	var vertex_counter: int = 0
	
	# Iterate through all surfaces in the mesh
	for surface_idx in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface_idx)
		var surface_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		
		# Process vertices in groups of 3 (triangles)
		for i in range(0, surface_vertices.size(), 3):
			var face_indices: PackedInt32Array = PackedInt32Array()
			
			# Process each vertex of the triangle
			for j in range(3):
				if i + j < surface_vertices.size():
					var vertex: Vector3 = surface_vertices[i + j]
					var vertex_key: String = "%f,%f,%f" % [vertex.x, vertex.y, vertex.z]
					
					# Check if vertex already exists
					if not vertices_dict.has(vertex_key):
						vertices_dict[vertex_key] = vertex_counter
						vertices_list.append(vertex)
						face_indices.append(vertex_counter)
						vertex_counter += 1
					else:
						face_indices.append(vertices_dict[vertex_key])
			
			if face_indices.size() == 3:
				faces_list.append(face_indices)
	
	# Write OFF header
	mesh_file.store_line("OFF")
	
	# Write counts: vertices, faces, edges (0 for edges as we don't track them)
	mesh_file.store_line("%d %d 0" % [vertices_list.size(), faces_list.size()])
	
	# Write vertices
	for vertex in vertices_list:
		mesh_file.store_line("%f %f %f" % [vertex.x, vertex.y, vertex.z])
	
	# Write faces
	for face in faces_list:
		mesh_file.store_line("3 %d %d %d" % [face[0], face[1], face[2]])
	
	mesh_file.close()
	print("Mesh exported successfully: %d vertices, %d faces" % [vertices_list.size(), faces_list.size()])
