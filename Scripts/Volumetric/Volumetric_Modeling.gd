extends Node3D

class_name VolumetricModeling

@export_category("Spheres Parameters")
@export var centers:Array[Vector3]
@export var radiuses:Array[float]
@export var max_subdivision:int = 5
enum Operation { UNION, INTERSECTION, SUBTRACTION }
@export var operations: Array[Operation]

@export_category("Render Parameters")
@export var voxel_scale: float = 1.0

# Octree Vars
var octrees: Array[OctreeNode]

func _ready() -> void:
	# Set default values if arrays are empty
	if centers.is_empty() or radiuses.is_empty() or operations.is_empty() or centers.size() != radiuses.size() or radiuses.size() != operations.size():
		print("Setting default sphere parameters...")
		# Create an interesting structure showcasing all three operations
		centers = [
			Vector3.ZERO,           # Base sphere (UNION - foundation)
			Vector3(2.5, 0, 0),     # Right extension (UNION - add volume)
			Vector3(-2.5, 0, 0),    # Left extension (UNION - add volume)
			Vector3(0, 2.5, 0),     # Top sphere (UNION - add volume)
			Vector3(1.2, 1.2, 0),   # Intersection constraint (INTERSECTION - limit to overlap)
			Vector3(-1.2, 1.2, 0),  # Another intersection constraint (INTERSECTION)
			Vector3(0.8, 0, 0),     # Subtraction hole 1 (SUBTRACTION - remove volume)
			Vector3(-0.8, 0, 0),    # Subtraction hole 2 (SUBTRACTION - remove volume)
			Vector3(0, 1.8, 0),     # Top subtraction (SUBTRACTION - remove from top)
		]
		radiuses = [2.0, 1.5, 1.5, 1.5, 2.5, 2.5, 0.7, 0.7, 0.8]
		operations = [
			Operation.UNION,        # Base: Start with main sphere
			Operation.UNION,        # Add: Right extension
			Operation.UNION,        # Add: Left extension  
			Operation.UNION,        # Add: Top extension
			Operation.INTERSECTION, # Limit: Only keep overlap with this sphere
			Operation.INTERSECTION, # Limit: Further constrain with this sphere
			Operation.SUBTRACTION,  # Remove: Create hole on right
			Operation.SUBTRACTION,  # Remove: Create hole on left
			Operation.SUBTRACTION   # Remove: Create hole at top
		]
	
	print("Starting volumetric modeling with ", centers.size(), " spheres")
	render_spheres_as_one()

# Test function to add a sphere at origin
func add_test_sphere() -> void:
	centers.append(Vector3(0, 0, 3))
	radiuses.append(1.5)
	operations.append(Operation.UNION)
	print("Added test sphere at (0,0,3)")
	
	# Re-render with new sphere
	clear_existing_meshes()
	render_spheres_as_one()

func clear_existing_meshes() -> void:
	# Remove all existing mesh children
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()

func render_spheres_as_one() -> void:
	# Initialize octrees array
	octrees.resize(1)
	
	print("Killing all childrens")
	clear_existing_meshes()
	
	
	print("Building combined octree with ", centers.size(), " spheres")
	print("Centers: ", centers)
	print("Radiuses: ", radiuses)
	octrees[0] = OctreeNode.build_spheres_octree(centers, radiuses, operations, max_subdivision, voxel_scale)
	
	print("Rendering combined octree...")
	octrees[0].render_octree(self)
	print("Finished rendering combined octree")
	


func render_separate_spheres() -> void:
	# Initialize octrees array
	octrees.resize(centers.size())
	
	for idx in range(centers.size()):
		print("Building octree ", idx, " at ", centers[idx], " with radius ", radiuses[idx])
		# Initializing Octree
		octrees[idx] = OctreeNode.build_sphere_octree(centers[idx], radiuses[idx], max_subdivision, voxel_scale)
		# Render Sphere - add to this node instead of current_scene
		print("Rendering octree ", idx)
		octrees[idx].render_octree(self)
	
