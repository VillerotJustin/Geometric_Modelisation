extends Camera3D
class_name CameraMan

## A versatile 3D camera controller with mouse look, movement controls, and debugging features
##
## This camera provides:
## - Mouse look (captured mouse mode)
## - WASD + QE movement (or arrow keys)
## - Mouse wheel zooming
## - Torch light toggle (F key)
## - Debug view cycling (P key)
## - Wireframe view (M key)
## - ESC to release mouse cursor

@export_group("Movement")
@export var speed: float = 5.0                    ## Movement speed in units per second
@export var sprint_multiplier: float = 2.0        ## Speed multiplier when holding shift
@export var mouse_sensitivity: float = 0.2        ## Mouse look sensitivity

@export_group("Zoom")
@export var zoom_speed: float = 2.0               ## How fast to zoom in/out
@export var min_zoom: float = 2.0                 ## Closest zoom (smallest FOV)
@export var max_zoom: float = 120.0               ## Farthest zoom (largest FOV)

@export_group("Light")
@export var torch_enabled: bool = true            ## Whether to include a torch light
@export var torch_intensity: float = 1.0          ## Torch light intensity
@export var torch_range: float = 10.0             ## Torch light range

@export_group("Tools")
@export var volumetrick_mesh: VolumetricModeling

# Brush settings (for simple brush/preview in front of the camera)
@export var brush_radius: float = 0.5
@export var brush_distance: float = 2.0

var brush_sphere: MeshInstance3D = null
var brush_visible := false

var lamp_torch: SpotLight3D
var rotation_x := 0.0
var rotation_y := 0.0
var mouse_captured := false

func _ready() -> void:
	# Find existing torch or create one if enabled
	lamp_torch = get_node_or_null("SpotLight3D")
	if torch_enabled and not lamp_torch:
		_setup_torch()
	elif lamp_torch:
		# Configure existing torch
		lamp_torch.light_energy = torch_intensity
		lamp_torch.spot_range = torch_range
		lamp_torch.light_color = Color(1.0, 0.9, 0.7)
	
	# Setup wireframe rendering
	RenderingServer.set_debug_generate_wireframes(true)
	
	# Capture mouse if in game mode
	if not Engine.is_editor_hint():
		_capture_mouse()
	
	print("CameraMan ready!")
	print_controls()

func _setup_torch() -> void:
	if not lamp_torch:
		lamp_torch = SpotLight3D.new()
		add_child(lamp_torch)
		lamp_torch.name = "SpotLight3D"
	
	lamp_torch.light_energy = torch_intensity
	lamp_torch.spot_range = torch_range
	lamp_torch.spot_angle = 45.0
	lamp_torch.light_color = Color(1.0, 0.9, 0.7)  # Warm white color

func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	mouse_captured = false

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look (only when captured)
	if event is InputEventMouseMotion and mouse_captured:
		rotation_y -= event.relative.x * mouse_sensitivity * 0.01
		rotation_x -= event.relative.y * mouse_sensitivity * 0.01
		rotation_x = clamp(rotation_x, deg_to_rad(-89), deg_to_rad(89))
		rotation = Vector3(rotation_x, rotation_y, 0)

	# Toggle mouse capture on ESC
	if event.is_action_pressed("ui_cancel"):
		if mouse_captured:
			_release_mouse()
		else:
			_capture_mouse()

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_zoom()
	_handle_light()

func _process(delta: float) -> void:
	# Keep the preview brush positioned in front of the camera while visible
	if brush_sphere and brush_visible:
		brush_sphere.position = Vector3(0, 0, -brush_distance)
		brush_sphere.scale = Vector3.ONE * brush_radius

func _handle_movement(delta: float) -> void:
	var move_dir := Vector3.ZERO
	var current_speed := speed

	# Check for sprint
	if Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SHIFT):
		current_speed *= sprint_multiplier

	# --- Movement ---
	if Input.is_action_pressed("camera_left"):
		move_dir.x -= 1.0
	if Input.is_action_pressed("camera_right"):
		move_dir.x += 1.0
	if Input.is_action_pressed("camera_up"):
		move_dir.z -= 1.0
	if Input.is_action_pressed("camera_down"):
		move_dir.z += 1.0
	if Input.is_action_pressed("camera_high"):
		move_dir.y += 1.0  # Positive Y is up in Godot
	if Input.is_action_pressed("camera_low"):
		move_dir.y -= 1.0

	if move_dir != Vector3.ZERO:
		move_dir = move_dir.normalized() * current_speed * delta
		translate_object_local(move_dir)  # Local movement relative to rotation

func _handle_zoom() -> void:
	# --- Zooming ---
	if Input.is_action_just_pressed("zoom_in"):
		fov = clamp(fov - zoom_speed, min_zoom, max_zoom)
	elif Input.is_action_just_pressed("zoom_out"):
		fov = clamp(fov + zoom_speed, min_zoom, max_zoom)

func _handle_light() -> void:
	# --- Torch ---
	if Input.is_action_just_pressed("toggle_light") and lamp_torch:
		lamp_torch.visible = !lamp_torch.visible
		print("Torch: ", "ON" if lamp_torch.visible else "OFF")


func _input(event: InputEvent) -> void:
	# Debug view cycling with P key
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		var vp = get_viewport()
		vp.debug_draw = (vp.debug_draw + 1) % 5
		var debug_names = ["Normal", "Unshaded", "Lighting", "Overdraw", "Wireframe"]
		print("Debug draw mode: ", debug_names[vp.debug_draw])
	
	# Wireframe mode with M key
	elif event is InputEventKey and event.pressed and event.keycode == KEY_M:
		var vp = get_viewport()
		vp.debug_draw = 4  # Wireframe mode
		print("Debug draw mode: Wireframe")

	# Toggle transient translucent brush preview while T is held
	elif event is InputEventKey and event.keycode == KEY_T:
		if event.pressed:
			_show_brush(true)
		else:
			_show_brush(false)

	# Add SUBTRACTION sphere to volumetric model at brush location
	elif event is InputEventKey and event.pressed and event.keycode == KEY_L:
		# Reduce brush radius slightly
		if volumetrick_mesh:
			var world_pos = global_transform.origin + -transform.basis.z * brush_distance
			var local_pos = volumetrick_mesh.to_local(world_pos)
			volumetrick_mesh.centers.append(local_pos)
			volumetrick_mesh.radiuses.append(brush_radius)
			volumetrick_mesh.operations.append(VolumetricModeling.Operation.SUBTRACTION)
			if volumetrick_mesh.has_method("render_spheres_as_one"):
				volumetrick_mesh.render_spheres_as_one()
			print("Added union sphere at", local_pos)
		else:
			print("No VolumetricModeling node assigned to `volumetrick_mesh`")

	# Add union sphere to volumetric model at brush location
	elif event is InputEventKey and event.pressed and event.keycode == KEY_O:
		# Increase brush radius slightly
		if volumetrick_mesh:
			var world_pos2 = global_transform.origin + -transform.basis.z * brush_distance
			var local_pos2 = volumetrick_mesh.to_local(world_pos2)
			volumetrick_mesh.centers.append(local_pos2)
			volumetrick_mesh.radiuses.append(brush_radius)
			volumetrick_mesh.operations.append(VolumetricModeling.Operation.UNION)
			if volumetrick_mesh.has_method("render_spheres_as_one"):
				volumetrick_mesh.render_spheres_as_one()
			print("Added union sphere at", local_pos2)
		else:
			print("No VolumetricModeling node assigned to `volumetrick_mesh`")


func _create_brush_sphere() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	# Simple translucent material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.6, 1.0, 0.35)
	mat.flags_transparent = true
	mi.material_override = mat
	return mi


func _show_brush(show: bool) -> void:
	brush_visible = show
	if show:
		if not brush_sphere:
			brush_sphere = _create_brush_sphere()
			add_child(brush_sphere)
		# Position in front of camera in local coordinates
		brush_sphere.position = Vector3(0, 0, -brush_distance)
		brush_sphere.scale = Vector3.ONE * brush_radius
		brush_sphere.visible = true
	else:
		if brush_sphere:
			brush_sphere.visible = false

func get_controls_help() -> String:
	var help_text = """
	=== CameraMan Controls ===
	WASD / Arrow Keys: Move camera
	Q / E: Move up/down
	Mouse: Look around (when captured)
	Mouse Wheel: Zoom in/out
	Shift: Sprint (faster movement)
	F: Toggle torch light
	P: Cycle debug views
	M: Wireframe view
	ESC: Toggle mouse capture
	"""
	return help_text

func print_controls() -> void:
	print(get_controls_help())
	
