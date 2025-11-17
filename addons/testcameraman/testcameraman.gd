@tool
extends EditorPlugin

func _enter_tree() -> void:
	# Add the custom camera type to the scene dock
	var script_path = "res://addons/testcameraman/cameraman.gd"
	var script = load(script_path)
	
	if script:
		add_custom_type(
			"CameraMan",
			"Camera3D", 
			script,
			null  # We'll use the default Camera3D icon for now
		)
		print("CameraMan plugin enabled")
		print("Usage: Create Node -> Search 'CameraMan' -> Add to your scene")
		print("Controls: WASD/Arrow keys to move, Mouse to look around, Mouse wheel to zoom, F to toggle light, P for debug views, ESC to release mouse")
	else:
		print("Failed to load CameraMan script")

func _exit_tree() -> void:
	# Remove the custom type when disabling the plugin
	remove_custom_type("CameraMan")
	print("CameraMan plugin disabled")

func _has_main_screen() -> bool:
	return false

func _get_plugin_name() -> String:
	return "CameraMan"
