class_name OctreeNode

# Octree var
var is_empty: bool = false
var center: Vector3
var radius: float
var max_subdivision: int = 5

var voxel_scale: float = 1.0

# Child nodes
var childrens:Array[OctreeNode]

# Builder
func _init(vec_center:Vector3, side:float, empty: bool = false, max_div:int = 5, voxel_sc: float = 1.0) -> void:
	center = vec_center
	radius = side
	is_empty = empty
	max_subdivision = max_div
	voxel_scale = voxel_sc

func build_childrens_sphere(sphere_center: Vector3, sphere_radius: float, current_subdivision: int = 5) -> void:
	# Check if we've reached maximum subdivision depth
	if current_subdivision <= 0:
		return
	
	# Check if this octree node (cube) intersects with the sphere
	is_empty = (center - sphere_center).length_squared() >= sphere_radius * sphere_radius
	
	# Initialize children array with 8 elements
	childrens.resize(8)
	
	var idx_counter: int = 0
	var half_radius = radius / 2.0
	
	for UP_DOWN in range(2):
		for LEFT_RIGHT in range(2):
			for FORWARD_BACK in range(2):
				# Calculate child center by offsetting from current center
				var offset_x = (LEFT_RIGHT - 0.5) * half_radius
				var offset_y = (UP_DOWN - 0.5) * half_radius  
				var offset_z = (FORWARD_BACK - 0.5) * half_radius
				
				var child_center: Vector3 = center + Vector3(offset_x, offset_y, offset_z)
				var child_empty: bool = (child_center - sphere_center).length_squared() >= sphere_radius * sphere_radius
				
				childrens[idx_counter] = OctreeNode.new(child_center, half_radius, child_empty, max_subdivision, voxel_scale)
				childrens[idx_counter].build_childrens_sphere(sphere_center, sphere_radius, current_subdivision - 1)
				idx_counter += 1
	
	# Only recurse if we haven't reached the subdivision limit
	# If all children are full (not empty), clear children array for optimization
	var all_children_full: bool = true
	for children in childrens:
		if children.is_empty or center == sphere_center: # Exception for first node or edge node
			all_children_full = false
		# Only recurse if the child intersects with the sphere and we have subdivisions left
		#if not children.is_empty and current_subdivision > 1:
			#children.build_childrens_sphere(sphere_center, sphere_radius, current_subdivision - 1)
	
	# If all children are full (solid), we can remove them for optimization
	if all_children_full:
		childrens.clear()

# Helper function to check if a cube intersects with a sphere
func _cube_intersects_sphere(cube_center: Vector3, cube_half_size: float, sphere_center: Vector3, sphere_radius: float) -> bool:
	# Find the closest point on the cube to the sphere center
	var closest_point = Vector3()
	# cube_half_size is already the radius/half-size, don't divide again
	var half_size = cube_half_size
	
	# Clamp sphere center to cube bounds for each axis
	closest_point.x = clamp(sphere_center.x, cube_center.x - half_size, cube_center.x + half_size)
	closest_point.y = clamp(sphere_center.y, cube_center.y - half_size, cube_center.y + half_size)
	closest_point.z = clamp(sphere_center.z, cube_center.z - half_size, cube_center.z + half_size)
	
	# Check if the closest point is within the sphere
	var distance_squared = (closest_point - sphere_center).length_squared()
	return distance_squared <= sphere_radius * sphere_radius

static func build_sphere_octree(sphere_center: Vector3, sphere_radius: float, max_div:int = 5, voxel_sc: float = 1.0) -> OctreeNode:
	var root_octree: OctreeNode = OctreeNode.new(sphere_center, sphere_radius * 2, false, max_div, voxel_sc)
	root_octree.build_childrens_sphere(sphere_center, sphere_radius, max_div)
	return root_octree
	
static func is_voxel_in_a_sphere(voxel_center: Vector3, sphere_centers: Array[Vector3], sphere_radiuses: Array[float], operations: Array[VolumetricModeling.Operation]) -> bool:
	if sphere_centers.is_empty():
		return false
	
	var intersections: Array[bool]
	intersections.resize(sphere_centers.size())
	
	# Calculate which spheres the voxel is inside
	for idx in range(sphere_centers.size()):
		intersections[idx] = (voxel_center - sphere_centers[idx]).length_squared() <= pow(sphere_radiuses[idx], 2)
	
	# Start with first sphere (should always be UNION for base)
	var result: bool = intersections[0]
	
	# Apply subsequent operations
	for idx in range(1, sphere_centers.size()):
		match operations[idx]:
			VolumetricModeling.Operation.UNION:
				result = result or intersections[idx]
			VolumetricModeling.Operation.INTERSECTION:
				result = result and intersections[idx]
			VolumetricModeling.Operation.SUBTRACTION:
				result = result and not intersections[idx]
			
	return result
	
func build_childrens_spheres(sphere_centers: Array[Vector3], sphere_radiuses: Array[float], operations: Array[VolumetricModeling.Operation], current_subdivision: int = 5) -> void:
	# Check if we've reached maximum subdivision depth
	if current_subdivision <= 0:
		return
	
	# Check if this octree node (cube) intersects with the sphere
	is_empty = not is_voxel_in_a_sphere(center, sphere_centers, sphere_radiuses, operations)
	
	# Initialize children array with 8 elements
	childrens.resize(8)
	
	var idx_counter: int = 0
	var half_radius = radius / 2.0
	
	for UP_DOWN in range(2):
		for LEFT_RIGHT in range(2):
			for FORWARD_BACK in range(2):
				# Calculate child center by offsetting from current center
				var offset_x = (LEFT_RIGHT - 0.5) * half_radius
				var offset_y = (UP_DOWN - 0.5) * half_radius  
				var offset_z = (FORWARD_BACK - 0.5) * half_radius
				
				var child_center: Vector3 = center + Vector3(offset_x, offset_y, offset_z)
				var child_empty: bool = not is_voxel_in_a_sphere(child_center, sphere_centers, sphere_radiuses, operations)
				
				childrens[idx_counter] = OctreeNode.new(child_center, half_radius, child_empty, max_subdivision, voxel_scale)
				childrens[idx_counter].build_childrens_spheres(sphere_centers, sphere_radiuses, operations, current_subdivision - 1)
				idx_counter += 1
	
	# Only recurse if we haven't reached the subdivision limit
	# If all children are full (not empty), clear children array for optimization
	var all_children_full: bool = true
	for children in childrens:
		if children.is_empty or center in sphere_centers: # Exception for first node or edge node
			all_children_full = false
		# Only recurse if the child intersects with the sphere and we have subdivisions left
		#if not children.is_empty and current_subdivision > 1:
			#children.build_childrens_sphere(sphere_center, sphere_radius, current_subdivision - 1)
	
	# If all children are full (solid), we can remove them for optimization
	if all_children_full:
		childrens.clear()
	
static func build_spheres_octree(sphere_centers: Array[Vector3], sphere_radiuses: Array[float], operations: Array[VolumetricModeling.Operation], max_div:int = 5, voxel_sc: float = 1.0) -> OctreeNode:
	# Get max x,y,z
	var max_x: float = 0
	var max_y: float = 0
	var max_z: float = 0
	
	var min_x: float = 0
	var min_y: float = 0
	var min_z: float = 0
	
	var acc_center: Vector3 = Vector3.ZERO
	
	for idx in range(sphere_centers.size()):
		var sphere_pos = sphere_centers[idx]
		var sphere_radius = sphere_radiuses[idx]
		
		max_x = max(max_x, sphere_pos.x + sphere_radius)
		max_y = max(max_y, sphere_pos.y + sphere_radius)
		max_z = max(max_z, sphere_pos.z + sphere_radius)
		
		min_x = min(min_x, sphere_pos.x - sphere_radius)
		min_y = min(min_y, sphere_pos.y - sphere_radius)
		min_z = min(min_z, sphere_pos.z - sphere_radius)
		
		acc_center += sphere_centers[idx]
		
	var sphere_center: Vector3 = acc_center / sphere_centers.size()
	var maxC: Vector3 = Vector3(max_x, max_y, max_z)
	var minC: Vector3 = Vector3(min_x, min_y, min_z)
	
	var root_octree: OctreeNode = OctreeNode.new(sphere_center, (maxC-minC).length(), false, max_div, voxel_sc)
	root_octree.build_childrens_spheres(sphere_centers, sphere_radiuses, operations, max_div)
	return root_octree

func render_octree(root: Node) -> void:
	# If has children render them
	if not childrens.is_empty():
		for children in childrens:
			children.render_octree(root)
	else:
		if !is_empty:
			var box: BoxMesh = BoxMesh.new()
			box.size = Vector3.ONE * radius * voxel_scale
			var meshInstance: MeshInstance3D = Mesh_Helpers._make_mesh_instance(box, center)
			
			# Add a material to make it visible
			var material = StandardMaterial3D.new()
			material.albedo_color = Color.RED
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			meshInstance.material_override = material
			
			root.add_child(meshInstance)
			# print("Added voxel at ", center, " with size ", radius)
			
