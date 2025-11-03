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
