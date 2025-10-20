
ModGeo — Geometric Modeling examples (Godot)
=============================================

This small Godot project contains example scripts to procedurally build basic 3D geometry (quads, fragmented rectangles, circles, cylinders, cones, spheres, etc.) and a simple camera controller for navigation.

Contents
--------

- `project.godot` — Godot project file (engine config: Godot 4.5 features flagged). The project main scene is configured in this file.
- `Scenes/` — Godot scenes shipped with the project (camera and a test scene).
- `Scripts/MeshBuilder.gd` — Procedural mesh generation utilities. Contains functions:
	- `draw_simple_quad` — create one rectangular quad (two triangles).
	- `draw_fragmented_rectangle` — create a subdivided rectangular grid of quads with alternating colors.
	- `draw_circle` — create a filled circle on an arbitrary plane.
	- `draw_cylindre` — create a capped cylinder between two points (different radii allowed).
	- `draw_hourglass` — variation of cylinder with inverted normals for the second end.
	- `draw_cone` — create a cone with base and sides.
	- `draw_sphere` — generate a sphere from parallels/meridians.
- `Scripts/cameraman.gd` — Camera3D controller for first-person style view with keyboard panning, mouse look, and zoom controls.

What is implemented
--------------------

- Multiple procedural geometry builders that create ArrayMesh objects and spawn `MeshInstance3D` nodes at runtime. These are currently called from `_ready()` in `MeshBuilder.gd` as example usages.
- A camera controller that supports:
	- Mouse look (cursor captured by default).
	- WASD-like panning via configured input actions (`camera_left`, `camera_right`, `camera_up`, `camera_down`, `camera_high`, `camera_low`).
	- Zooming in/out via mouse buttons mapped to `zoom_in` / `zoom_out` actions.
	- Toggle viewport debug drawing with `P` and `M` keys.
- The project file lists `config/features` containing `"4.5"` and `"Forward Plus"`, and `config_version=5`, meaning it targets Godot 4.x with 4.5 features enabled.

How to open and run the project
--------------------------------

Prerequisites

- Godot 4.2+ is recommended. The project `project.godot` references features flagged as `4.5`, so using Godot 4.4/4.5 will provide the best experience. If you only have 4.2/4.3, the project may still run but some optional features might be unavailable.

1. Open the project in Godot

	- Start Godot and choose "Import" or "Open an existing project". Point it to the repository folder (the folder that contains `project.godot`).

2. Run the main scene

	- The main scene is set in `project.godot`. You can press the Play button in the editor to run the configured main scene.
	- Alternatively open `Scenes/Test_scene.tscn` (or `camera_man.tscn`) in the editor and press Play Scene to test individual scenes.

Controls (default)

- Mouse movement: look around (mouse captured on start).
- ESC (or action `ui_cancel`): release mouse cursor.
- Movement keys (as configured in `project.godot` input map):
	- camera_left: typically 'Q' or 'A' depending on mapping
	- camera_right: typically 'D'
	- camera_up: typically 'W'
	- camera_down: typically 'S'
	- camera_high: 'E'
	- camera_low: 'Q' (see project input map for exact keys)
- Zoom: mouse buttons mapped as `zoom_in` / `zoom_out` (scroll or mouse buttons depending on input map entries)
- P: cycle viewport debug draw mode
- M: set viewport debug draw to mode 4

Notes about the code
--------------------

- `MeshBuilder.gd` builds mesh data using `SurfaceTool` and `ArrayMesh`. Example calls are present in `_ready()` to show how to use the functions; remove or adapt those calls when integrating into other scenes.
- UVs, normals, and colors are assigned in a basic way for demonstration purposes. Materials are `StandardMaterial3D` with backface culling disabled so single-sided primitives are visible from both sides during testing.
- The geometry builders assume simple, non-degenerate inputs; no extensive validation is done. You can improve by adding parameter checks and error messages.

Troubleshooting
---------------

- If the project does not open or errors appear about incompatible `config/features`, try using a newer Godot 4.x editor (download Godot 4.5 or 4.4 nightly if needed).
- If meshes don't appear, confirm the `MeshInstance3D` nodes created by the scripts were added to an active scene tree (scripts run from a node that is instanced in the active scene). You can also attach `MeshBuilder.gd` to a Node3D in your scene.

Suggested next steps / improvements
----------------------------------

- Turn the example calls in `_ready()` into a demo scene that exposes parameters via exported variables so you can tweak radii, sides, and positions in the editor.
- Add input validation and clearer errors for bad parameters.
- Add normals calculation for all shapes (some already set for sphere) and better UV mapping for texturing.
- Add unit tests (if you export utilities into a library or helper script) or a small demonstration scene that toggles different generated meshes interactively.

Files changed
-------------

- Updated: `README.md` — added project description and run instructions.

Completion
----------

I updated `README.md` with run instructions, feature list, and suggestions for next steps.
