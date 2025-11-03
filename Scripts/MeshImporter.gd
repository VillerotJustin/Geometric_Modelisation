extends Node

class_name Mesh_Importer

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
		vertices.append_array([
			split_line[0].to_float(),
			split_line[1].to_float(),
			split_line[2].to_float()
		])
	
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
		
		# Add vertices & color & calculating normal
		for vi_index in range(face["vertex_numbers"]):
			var vi = face["vertexes"][vi_index]
			var vi_next = face["vertexes"][(vi_index + 1) % face["vertex_numbers"]]
			
			processed_vertices.append(vertices[vi])
			processed_color.append(face["color"])
			
			# Newell’s stuff
			nx += (vertices[vi][1] - vertices[vi_next][1]) * (vertices[vi][2] - vertices[vi_next][2])
			ny += (vertices[vi][2] - vertices[vi_next][2]) * (vertices[vi][0] - vertices[vi_next][0])
			nz += (vertices[vi][0] - vertices[vi_next][0]) * (vertices[vi][1] - vertices[vi_next][1])
			
		# Calculate normal of face
		var normal:Vector3 = Vector3(nx, ny, nz).normalized()
		for vert in range(face["vertex_numbers"]):
			processed_normals.append(normal)
			processed_uvs.append(Vector2.ZERO)
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 0.8)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)
	
	## Triangulate faces
	#for face in faces:
		#var normal = Vector3.ZERO
		## Newell method
		#for i in range(face["vertex_numbers"]):
			#var current = vertices[face["vertexes"][i]]
			#var next = vertices[face["vertexes"][(i + 1) % face["vertex_numbers"]]]
			#normal.x += (current.y - next.y) * (current.z + next.z)
			#normal.y += (current.z - next.z) * (current.x + next.x)
			#normal.z += (current.x - next.x) * (current.y + next.y)
		#normal = normal.normalized()
		#
		## Fan triangulation
		#for i in range(1, face["vertex_numbers"] - 1):
			#st.set_normal(normal)
			#st.add_vertex(vertices[face["vertexes"][0]])
			#st.set_normal(normal)
			#st.add_vertex(vertices[face["vertexes"][i]])
			#st.set_normal(normal)
			#st.add_vertex(vertices[face["vertexes"][i + 1]])
	
	st.commit(mesh)
	var mi:MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	
	print("Mesh Imported vertices %s  faces %s" % [n_verts, n_faces])
	
	return mi
