extends Node3D

@export var mesh_instance:MeshInstance3D

func _ready() -> void:
	
	# Example usage
	draw_simple_quad(Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), Color(1, 0, 0))
	
	draw_fragmented_rectangle(Vector3(1, 3, 3), Vector3(3, 3, 0), Vector3(3, 5, 0), 5, 6)
	
	draw_fragmented_rectangle(Vector3(1, 3, 3), Vector3(1, 5, 3), Vector3(1, 3, 5), 3, 2, Color(), Color(1,1,1))
	
	draw_circle(Vector3(5, 0, 5), 3, Vector3(1, 0, 0), 8)
	
	draw_circle(Vector3(5, 0, 5), 2, Vector3(0, -1, 0), 32, Color(0.5, 0.3, 3))
	
	draw_cylindre(Vector3(-5, 2, -5), 2, 2, Vector3(-6, 4, -6), 16)
	
	draw_cylindre(Vector3(-5, 2, 5), 2, 4, Vector3(-6, 4, 6), 16)
	
	draw_hourglass(Vector3(-6, 5, -6), 2, 2, Vector3(-5, 7, -5), 16, Color())
	
	draw_cone(Vector3(5, 3, -5), 4, Vector3(6, 5, -5), 16)
	
# -------------------------------------------------------------------
# Simple Quad (1 rectangle made of 2 triangles)
# -------------------------------------------------------------------
func draw_simple_quad(origin: Vector3, l_o: Vector3, h_o: Vector3, quad_color: Color = Color(1, 0, 0)) -> void:
	var quad_mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = quad_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	st.set_material(mat)
	
	# Directions and corners
	var dir_x = (l_o - origin)
	var dir_z = (h_o - origin)
	
	var l_origin = Vector3.ZERO
	
	var p00 = l_origin
	var p01 = l_origin + dir_x
	var p10 = l_origin + dir_z
	var p11 = l_origin + dir_x + dir_z
	
	# Add vertices (two triangles)
	var verts = [p00, p01, p10, p10, p01, p11]
	var uvs = [
		Vector2(0, 0), Vector2(1, 0), Vector2(0, 1),
		Vector2(0, 1), Vector2(1, 0), Vector2(1, 1)
	]
	
	# Doubling side of triangles
	var reverse = verts.duplicate()
	reverse.reverse()
	verts.append_array(reverse)
	
	var RUVs = uvs.duplicate()
	RUVs.reverse()
	uvs.append_array(RUVs)
	
	for i in range(verts.size()):
		st.set_color(quad_color)
		st.set_uv(uvs[i])
		st.add_vertex(verts[i])
	
	st.commit(quad_mesh)
	
	# Create MeshInstance3D
	var quad_instance = MeshInstance3D.new()
	quad_instance.position = origin
	quad_instance.mesh = quad_mesh
	add_child(quad_instance)

func draw_fragmented_rectangle(origin:Vector3, l_o:Vector3, h_o:Vector3, n_col: int = 4, n_line:int = 4, rect_color: Color =  Color(0.1, 0.9, 0.1), rect_color2: Color =  Color(0.1, 0.1, 0.9) ):
	print("Drawn frag rect")
	
	# Creating Mesh instance & other new thingy
	var mesh_instance_rect = MeshInstance3D.new()
	
	var rect_Mesh = ArrayMesh.new()
	var rect_vertices = PackedVector3Array()
	var rect_UVs = PackedVector2Array()
	var rect_mat = StandardMaterial3D.new()
	
	rect_mat.albedo_color = rect_color
	
	rect_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(rect_mat)
	
	# Extract Local values
	var local_ori:Vector3 = Vector3.ZERO
	var local_l_o:Vector3 = l_o - origin
	var local_h_o:Vector3 = h_o - origin
	
	var length = local_l_o.length()
	var heigth = local_h_o.length()
	
	var dir_x = (l_o - origin).normalized()
	var dir_z = (h_o - origin).normalized()

	
	for col in range(n_col):
		for line in range(n_line):
			# Build vertice position for quad
			var x0 = col * length / n_col
			var x1 = (col + 1) * length / n_col
			var z0 = line * heigth / n_line
			var z1 = (line + 1) * heigth / n_line
			
			# Vertices in local space
			var p00: Vector3 = local_ori + dir_x * x0 + dir_z * z0
			var p01: Vector3 = local_ori + dir_x * x1 + dir_z * z0
			var p10: Vector3 = local_ori + dir_x * x0 + dir_z * z1
			var p11: Vector3 = local_ori + dir_x * x1 + dir_z * z1
			
			# Add vertices
			rect_vertices.append_array([p00, p10, p01, p01, p10, p11])
			
			# --- Add UVs ---
			var u0 = float(col) / n_col
			var v0 = float(line) / n_line
			var u1 = float(col + 1) / n_col
			var v1 = float(line + 1) / n_line

			rect_UVs.append_array([
				Vector2(u0, v0), Vector2(u1, v0), Vector2(u0, v1),
				Vector2(u0, v1), Vector2(u1, v0), Vector2(u1, v1)
			])
			
	
	# Doubling side of triangles
	var reverse = rect_vertices.duplicate()
	reverse.reverse()
	rect_vertices.append_array(reverse)
	
	var RUVs = rect_UVs.duplicate()
	RUVs.reverse()
	rect_UVs.append_array(RUVs)
	
	var color_it: bool = false
	for v in range(rect_vertices.size()):
		if color_it:
			st.set_color(rect_color)
		else:
			st.set_color(rect_color2)
		color_it = !color_it
		st.set_uv(rect_UVs[v])
		st.add_vertex(rect_vertices[v])
	
	st.commit(rect_Mesh)
	
	mesh_instance_rect.mesh = rect_Mesh
	
	mesh_instance_rect.position = origin
	
	add_child(mesh_instance_rect)

# -------------------------------------------------------------------
# Draw a Circle
#
#           (normal ↑)
#                |
#                |
#           ....-o-....
#        . '     |     ' .
#      .         |(r)     .
#     .          O          .
#      ' .               . '
#           '..........'
#                
#             (center)
#
#   O : center (origin)
#   r : radius
#   normal : plane orientation
# -------------------------------------------------------------------
func draw_circle(origin: Vector3, radius: float, normal: Vector3, sides: int = 8, color: Color = Color(1, 0.5, 1)):
	print("Draw Circle")
	normal = normal.normalized()
	
	# Basic setup
	var circle_mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	st.set_material(mat)
	
	var verts = PackedVector3Array()
	var UVs = PackedVector2Array()
	
	# Building mesh
	
	var local_origin: Vector3 = Vector3.ZERO  # center point is always the same
	
	 # Find tangent and bitangent vectors perpendicular to normal
	var tangent = normal.cross(Vector3(0, 0, 1))
	if tangent.length_squared() < 0.01:
		tangent = normal.cross(Vector3(0, 1, 0))
	tangent = tangent.normalized()
	var bitangent = normal.cross(tangent).normalized()
	
	for s in range(sides):
		var theta: float = TAU * (s / float(sides))
		var thetaP1: float = TAU *  ((s+1) / float(sides))
		
		var x0_no_orient = radius * cos(theta)
		var z0_no_orient = radius * sin(theta)
		
		var x1_no_orient = radius * cos(thetaP1)
		var z1_no_orient = radius * sin(thetaP1)
		
		# vertices to local space
		var p10: Vector3 = local_origin + x0_no_orient * tangent + z0_no_orient * bitangent
		var p01: Vector3 = local_origin + x1_no_orient * tangent + z1_no_orient * bitangent
		
		# add vertices
		verts.append_array([local_origin, p10, p01])
		
		# add UVs
		UVs.push_back(Vector2(0,0))
		UVs.push_back(Vector2(1,1))
		UVs.push_back(Vector2(1,1))
		
	# Doubling side of triangles
	var reverse = verts.duplicate()
	reverse.reverse()
	verts.append_array(reverse)
	
	var RUVs = UVs.duplicate()
	RUVs.reverse()
	UVs.append_array(RUVs)
	
	
	# Export
	for i in range(verts.size()):
		st.set_color(color)
		st.set_uv(UVs[i])
		st.add_vertex(verts[i])
	
	st.commit(circle_mesh)
	
	# Create MeshInstance3D
	var circle_instance = MeshInstance3D.new()
	circle_instance.position = origin
	circle_instance.mesh = circle_mesh
	add_child(circle_instance)
	

# -------------------------------------------------------------------
# Draw a Cylinder
#
#               [E] ← end point
#              _____
#             |     |
#             |     |
#             |  r : radius
#             |_____|
#               [O] ← origin
#
#        Cylindrical shape along (O → E)
#        with circular cross-section radius r
#
#   O : origin (base center)
#   E : end point (top center)
#   r : radius
# -------------------------------------------------------------------
func draw_cylindre(origin: Vector3, radius_t: float, radius_b: float, end: Vector3, sides: int = 8, color: Color = Color(1,0,1)):
	print("Draw Cylindre")
	
	# Draw the two opposite circle
	
	var cilinder_dir:Vector3 = origin - end
	var cilinder_dir_norm:Vector3 = cilinder_dir.normalized()
	
	# Basic setup
	var circle_mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	st.set_material(mat)
	
	var verts = PackedVector3Array()
	var UVs = PackedVector2Array()
	
	# Doing ends
	
	for end_num in range(2):
		var local_origin: Vector3
		var normal: Vector3
		var radius: float
		
		if end_num == 0:
			local_origin = Vector3.ZERO	
			normal = cilinder_dir_norm
			radius = radius_b
		else:
			local_origin = Vector3.ZERO + cilinder_dir
			normal = cilinder_dir_norm
			radius = radius_t
			
		 # Find tangent and bitangent vectors perpendicular to normal
		var tangent = normal.cross(Vector3(0, 0, 1))
		if tangent.length_squared() < 0.01:
			tangent = normal.cross(Vector3(0, 1, 0))
		tangent = tangent.normalized()
		var bitangent = normal.cross(tangent).normalized()
		
		for s in range(sides):
			var theta: float = TAU * (s / float(sides))
			var thetaP1: float = TAU *  ((s+1) / float(sides))
			
			var x0_no_orient = radius * cos(theta)
			var z0_no_orient = radius * sin(theta)
			
			var x1_no_orient = radius * cos(thetaP1)
			var z1_no_orient = radius * sin(thetaP1)
			
			# vertices to local space
			var p10: Vector3 = local_origin + x0_no_orient * tangent + z0_no_orient * bitangent
			var p01: Vector3 = local_origin + x1_no_orient * tangent + z1_no_orient * bitangent
			
			# add vertices
			verts.append_array([local_origin, p10, p01])
			
			# add UVs
			UVs.push_back(Vector2(0,0))
			UVs.push_back(Vector2(1,1))
			UVs.push_back(Vector2(1,1))
	
	# Doing Sides
	
	for s in range(sides):
		 # first circle (keep order)
		var i0 = s * 3 + 1
		var i1 = s * 3 + 2
		var p00: Vector3 = verts[i0] # Good
		var p01: Vector3 = verts[i1]
		
		# second circle (reverse order)
		var i2 = sides * 3 + (s * 3 + 1)
		var i3 = sides * 3 + (s * 3 + 2)
		var p10: Vector3 = verts[i2] # problem
		var p11: Vector3 = verts[i3] # Good
		
		verts.append_array([p00, p01, p10, p10, p01, p11])
		
		# Repeat UVs for each new triangle
		for _i in range(6):
			UVs.push_back(Vector2(1,1))
		
	
	# Doubling side of triangles
	var reverse = verts.duplicate()
	reverse.reverse()
	verts.append_array(reverse)
	
	var RUVs = UVs.duplicate()
	RUVs.reverse()
	UVs.append_array(RUVs)
	
	# Export
	for i in range(verts.size()):
		st.set_color(color)
		st.set_uv(UVs[i])
		st.add_vertex(verts[i])
	
	st.commit(circle_mesh)
	
	# Create MeshInstance3D
	var circle_instance = MeshInstance3D.new()
	circle_instance.position = origin
	circle_instance.mesh = circle_mesh
	add_child(circle_instance)
	
	

func draw_hourglass(origin: Vector3, radius_t: float, radius_b: float, end: Vector3, sides: int = 8, color: Color = Color(1,0,1)):
	print("Draw Cylindre")
	
	# Draw the two opposite circle
	
	var cilinder_dir:Vector3 = origin - end
	var cilinder_dir_norm:Vector3 = cilinder_dir.normalized()
	
	# Basic setup
	var circle_mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	st.set_material(mat)
	
	var verts = PackedVector3Array()
	var UVs = PackedVector2Array()
	
	# Doing ends
	
	for end_num in range(2):
		var local_origin: Vector3
		var normal: Vector3
		var radius: float
		
		if end_num == 0:
			local_origin = Vector3.ZERO	
			normal = cilinder_dir_norm
			radius = radius_b
		else:
			local_origin = Vector3.ZERO + cilinder_dir
			normal = -cilinder_dir_norm
			radius = radius_t
			
		 # Find tangent and bitangent vectors perpendicular to normal
		var tangent = normal.cross(Vector3(0, 0, 1))
		if tangent.length_squared() < 0.01:
			tangent = normal.cross(Vector3(0, 1, 0))
		tangent = tangent.normalized()
		var bitangent = normal.cross(tangent).normalized()
		
		for s in range(sides):
			var theta: float = TAU * (s / float(sides))
			var thetaP1: float = TAU *  ((s+1) / float(sides))
			
			var x0_no_orient = radius * cos(theta)
			var z0_no_orient = radius * sin(theta)
			
			var x1_no_orient = radius * cos(thetaP1)
			var z1_no_orient = radius * sin(thetaP1)
			
			# vertices to local space
			var p10: Vector3 = local_origin + x0_no_orient * tangent + z0_no_orient * bitangent
			var p01: Vector3 = local_origin + x1_no_orient * tangent + z1_no_orient * bitangent
			
			# add vertices
			verts.append_array([local_origin, p10, p01])
			
			# add UVs
			UVs.push_back(Vector2(0,0))
			UVs.push_back(Vector2(1,1))
			UVs.push_back(Vector2(1,1))
	
	# Doing Sides
	
	var n_vertexes: int = verts.size()
	
	for s in range(sides):
		 # first circle (keep order)
		var i0 = s * 3 + 1
		var i1 = s * 3 + 2
		var p00: Vector3 = verts[i0] # Good
		var p01: Vector3 = verts[i1]
		
		# second circle (reverse order)
		var i2 = n_vertexes-1 - (s * 3 + 1)
		var i3 = n_vertexes-1 - (s * 3)
		var p10: Vector3 = verts[i2] # problem
		var p11: Vector3 = verts[i3] # Good
		
		verts.append_array([p00, p01, p10, p10, p01, p11])
		
		# Repeat UVs for each new triangle
		for _i in range(6):
			UVs.push_back(Vector2(1,1))
		
	
	# Doubling side of triangles
	var reverse = verts.duplicate()
	reverse.reverse()
	verts.append_array(reverse)
	
	var RUVs = UVs.duplicate()
	RUVs.reverse()
	UVs.append_array(RUVs)
	
	# Export
	for i in range(verts.size()):
		st.set_color(color)
		st.set_uv(UVs[i])
		st.add_vertex(verts[i])
	
	st.commit(circle_mesh)
	
	# Create MeshInstance3D
	var circle_instance = MeshInstance3D.new()
	circle_instance.position = origin
	circle_instance.mesh = circle_mesh
	add_child(circle_instance)


func draw_cone(origin: Vector3, radius: float, end: Vector3, sides: int = 8, color: Color = Color(0,1,1)):
	# Draw the two opposite circle
	
	var cone_dir:Vector3 = origin - end
	var normal:Vector3 = cone_dir.normalized()
	
	# Basic setup
	var cone_mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	st.set_material(mat)
	
	var verts = PackedVector3Array()
	var UVs = PackedVector2Array()
	
	# Doing ends
	
	 # Find tangent and bitangent vectors perpendicular to normal
	var tangent = normal.cross(Vector3(0, 0, 1))
	if tangent.length_squared() < 0.01:
		tangent = normal.cross(Vector3(0, 1, 0))
	tangent = tangent.normalized()
	var bitangent = normal.cross(tangent).normalized()
	
	var local_origin:Vector3 = Vector3.ZERO
	var pointy_end:Vector3 = local_origin + cone_dir
	
	for s in range(sides):
		var theta: float = TAU * (s / float(sides))
		var thetaP1: float = TAU *  ((s+1) / float(sides))
		
		var x0_no_orient = radius * cos(theta)
		var z0_no_orient = radius * sin(theta)
		
		var x1_no_orient = radius * cos(thetaP1)
		var z1_no_orient = radius * sin(thetaP1)
		
		# vertices to local space
		var p10: Vector3 = local_origin + x0_no_orient * tangent + z0_no_orient * bitangent
		var p01: Vector3 = local_origin + x1_no_orient * tangent + z1_no_orient * bitangent
		
		# add vertices for bottom
		verts.append_array([local_origin, p10, p01])
		
		# add vertices for side
		verts.append_array([pointy_end, p10, p01])
		
		# add UVs
		UVs.push_back(Vector2(0,0))
		UVs.push_back(Vector2(0.5,0.5))
		UVs.push_back(Vector2(0.5,0.5))
		
		
		UVs.push_back(Vector2(1,1))
		UVs.push_back(Vector2(0.5,0.5))
		UVs.push_back(Vector2(0.5,0.5))
	
	
	
	# Doubling side of triangles
	var reverse = verts.duplicate()
	reverse.reverse()
	verts.append_array(reverse)
	
	var RUVs = UVs.duplicate()
	RUVs.reverse()
	UVs.append_array(RUVs)
	
	# Export
	for i in range(verts.size()):
		st.set_color(color)
		st.set_uv(UVs[i])
		st.add_vertex(verts[i])
	
	st.commit(cone_mesh)
	
	# Create MeshInstance3D
	var cone_instance = MeshInstance3D.new()
	cone_instance.position = origin
	cone_instance.mesh = cone_mesh
	add_child(cone_instance)
	
	
	
	
