extends Camera3D

@export var speed: float = 5.0          # Panning speed
@export var zoom_speed: float = 2.0     # How fast to zoom
@export var min_zoom: float = 2.0       # Closest zoom (smallest FOV)
@export var max_zoom: float = 50.0      # Farthest zoom (largest FOV)
@export var mouse_sensitivity: float = 0.2  # Mouse look sensitivity

var rotation_x := 0.0
var rotation_y := 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # lock cursor to screen

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouse_sensitivity * 0.01
		rotation_x -= event.relative.y * mouse_sensitivity * 0.01
		rotation_x = clamp(rotation_x, deg_to_rad(-89), deg_to_rad(89))
		rotation = Vector3(rotation_x, rotation_y, 0)

	# Release mouse on ESC
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	var move_dir := Vector3.ZERO

	# --- Panning ---
	if Input.is_action_pressed("camera_left"):
		move_dir.x -= 1.0
	if Input.is_action_pressed("camera_right"):
		move_dir.x += 1.0
	if Input.is_action_pressed("camera_up"):
		move_dir.z -= 1.0
	if Input.is_action_pressed("camera_down"):
		move_dir.z += 1.0
	if Input.is_action_pressed("camera_high"):
		move_dir.y -= 1.0
	if Input.is_action_pressed("camera_low"):
		move_dir.y += 1.0

	if move_dir != Vector3.ZERO:
		move_dir = move_dir.normalized() * speed * delta
		translate_object_local(move_dir)  # local movement relative to rotation

	# --- Zooming ---
	if Input.is_action_just_pressed("zoom_in"):
		fov = clamp(fov - zoom_speed, min_zoom, max_zoom)
	elif Input.is_action_just_pressed("zoom_out"):
		fov = clamp(fov + zoom_speed, min_zoom, max_zoom)


func _init():
	RenderingServer.set_debug_generate_wireframes(true)

func _input(event):
			
	if event is InputEventKey and Input.is_key_pressed(KEY_P):
		var vp = get_viewport()
		vp.debug_draw = (vp.debug_draw + 1 ) % 5
	
	if event is InputEventKey and Input.is_key_pressed(KEY_M):
		var vp = get_viewport()
		vp.debug_draw = 4
	
