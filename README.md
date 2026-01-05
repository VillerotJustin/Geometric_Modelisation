# ModGeo — Geometric Modeling examples (Godot)

=============================================

This Godot project demonstrates procedural 3D geometry generation, mesh import/export functionality for OFF file format, mesh manipulation tools, and a first-person camera controller. It includes both basic geometric primitives (quads, cylinders, spheres) and advanced mesh processing capabilities.

## Screenshots

--------

### Test Scene

![Test Scene](Screenshot/Test_Scene.png)
*Main test scene with procedurally generated geometry*

![Test Scene Wireframe](Screenshot/Test_Scene_WireMode.png)
*Wireframe view of the test scene*

### Subdivision

![Subdivision Initial](Screenshot/Subdivision_0.png)
*Initial randomized icosahedron*

![Subdivision Level 1](Screenshot/Subdivision_1.png)
*After one iteration of Loop subdivision*

![Subdivision Level 2](Screenshot/Subdivision_2.png)
*After two iterations of Loop subdivision*

### Simplification

![Simplification Overview](Screenshot/Simplification.png)
*Grid-based mesh simplification with multiple tolerance levels*

![Simplification Grid](Screenshot/Simplification_Grid.png)
*Spatial grid visualization for mesh analysis*

![Simplification Occupancy](Screenshot/Simplification_Occupancy.png)
*Color-coded vertex density in grid cells*

### Curve Subdivision

![Chaikin Curve](Screenshot/Chaikin_Curve.png)
*Chaikin corner-cutting algorithm for smooth curves*

### Volumetric Modeling

![Volumetric Modeling](Screenshot/Volumetric_Modelisation.png)
*Octree-based volumetric modeling system*

![Volumetric Operations](Screenshot/Volumetric_Modelisation_Addition_n_Substraction.png)
*Union, intersection, and subtraction operations*

## Contents

--------

### Project Files

- `project.godot` — Godot project file (Godot 4.5 with Forward Plus renderer)
- `icon.svg` — Project icon
- `.editorconfig`, `.gitignore`, `.gitattributes` — Project configuration files

### Scenes

- `Scenes/camera_man.tscn` — Camera controller scene
- `Scenes/Test_scene.tscn` — Main test scene demonstrating all geometry features
- `Scenes/Subdivision.tscn` — Loop subdivision demonstration scene
- `Scenes/Simplification.tscn` — Grid-based mesh simplification scene
- `Scenes/volumetric_mesh.tscn` — Volumetric modeling scene

### Scripts

#### MeshBuilder.gd

Procedural mesh generation utilities. Contains functions:

- `draw_simple_quad()` — Create a rectangular quad (two triangles)
- `draw_fragmented_rectangle()` — Create a subdivided rectangular grid with configurable subdivisions
- `draw_circle()` — Create a filled circle on an arbitrary plane with configurable number of sides
- `draw_cylindre()` — Create a capped cylinder between two points (supports different top/top radii)
- `draw_hourglass()` — Create an hourglass shape (cylinder with inverted end normals)
- `draw_cone()` — Create a cone with circular base and apex point
- `draw_sphere()` — Generate a UV sphere from parallels and meridians

#### MeshImporter.gd

OFF (Object File Format) import/export utilities:

- `read_off()` — Import mesh from .off file format, automatically triangulates n-gons, calculates normals using Newell's method, generates spherical UV coordinates, normalizes mesh to [-1, 1] cube
- `export_off()` — Export ArrayMesh to .off file format with vertex deduplication
- `_calculate_spherical_uv()` — Helper for generating spherical UV mapping

#### MeshHelpers.gd

Mesh manipulation and utility functions:

- `_create_standard_material()` — Create a StandardMaterial3D with specified color and disabled backface culling
- `_get_tangent_bitangent()` — Calculate tangent and bitangent vectors from a normal
- `_make_mesh_instance()` — Create a MeshInstance3D from an ArrayMesh at specified position
- `_commit_vertices_to_mesh()` — Commit vertex data to an ArrayMesh using SurfaceTool
- `_commit_vertices_to_mesh_advanced()` — Advanced version with per-vertex color support
- `_find_mesh_gravity_center()` — Calculate the geometric center of a mesh
- `_normalise_mesh()` — Normalize mesh to fit within a [-1, 1] cube centered at origin
- `_remove_random_faces()` — Remove a specified number of random faces from a mesh

#### subdivision.gd

Loop subdivision implementation for mesh refinement:

- `create_start_shape()` — Creates a randomized icosahedron as starting geometry
- `subdivision()` — Performs one iteration of Loop subdivision with midpoint caching
- `apply_loop_smoothing()` — Applies Warren's smoothing formula to subdivided vertices
- `get_or_create_midpoint()` — Efficient edge midpoint creation with caching to avoid duplicates
- Per-face random colors with individual vertex randomization
- Interactive controls: **Enter** to subdivide, **Backspace** to regenerate starting shape

#### simplification.gd

Grid-based mesh simplification system:

- `create_simplified_mesh()` — Simplifies meshes using spatial grid vertex averaging
- `build_grid()` — Creates 3D spatial grid visualization for analyzing mesh structure
- `visualize_grid_occupancy()` — Shows grid cells with color-coded vertex density
- Configurable tolerance epsilon for grid resolution
- Multiple simplification levels demonstration (0.1 to 0.3)
- Interactive keyboard controls:
  - `1` Toggle control grid, `2` Toggle control occupancy
  - `3` Toggle simplified grid, `4` Toggle simplified occupancy
  - `G` Toggle all grids, `O` Toggle all occupancy, `H` Show help

#### chaikin_curve.gd

Chaikin curve subdivision algorithm for smooth curve generation:

- `@tool` script that runs in the Godot editor
- `chaikin_subdivision()` — Applies corner-cutting algorithm to Path3D points
- Configurable iteration count for smoothness control
- Automatic child curve updates
- Works with Path3D nodes for visualization

#### cameraman.gd

Camera3D controller for first-person navigation:

- Mouse look with captured cursor
- WASD movement controls
- E/Q for vertical movement
- Mouse wheel zoom
- Debug viewport mode toggles (P and M keys)

### Meshes

Sample .off format meshes included:

- `buddha.off` — Buddha statue mesh
- `bunny.off` — Stanford bunny mesh
- `cube.off` — Simple cube
- `plan.off` — Planar mesh
- `export.off` — Example exported mesh (generated at runtime)

## Features

--------

### Procedural Geometry Generation

- Multiple geometry builders that create ArrayMesh objects and spawn MeshInstance3D nodes at runtime
- All primitives support custom colors, positions, orientations, and subdivision levels
- Proper UV mapping and normal calculation for all generated geometry
- Example calls in `MeshBuilder.gd` `_ready()` demonstrate all available shapes

### Mesh Subdivision

- **Loop Subdivision**: Implements the Loop subdivision surface algorithm for smooth mesh refinement
- **Edge Midpoint Caching**: Efficient subdivision by reusing shared edge midpoints
- **Warren's Smoothing**: Applies proper smoothing weights based on vertex valence
- **Randomized Starting Shapes**: Creates varied icosahedra with per-vertex randomization
- **Interactive Refinement**: Real-time subdivision with keyboard controls

### Mesh Simplification

- **Grid-Based Simplification**: Spatial grid approach for vertex clustering and averaging
- **Configurable Tolerance**: Adjustable epsilon parameter controls simplification level
- **Visual Grid Analysis**: Interactive visualization of spatial grid and vertex occupancy
- **Multiple Comparison Levels**: Side-by-side comparison of different simplification settings
- **Vertex Density Visualization**: Color-coded cubes show vertex distribution in grid cells

### Curve Subdivision

- **Chaikin Algorithm**: Corner-cutting subdivision for smooth curve generation
- **Editor Integration**: `@tool` script provides real-time curve editing in Godot editor
- **Path3D Support**: Works directly with Godot's Path3D nodes for easy integration
- **Configurable Iterations**: Control smoothness through subdivision iteration count

### Mesh Import/Export

- **OFF Format Support**: Full read/write support for Object File Format (.off)
- **Smart Import**: Automatic triangulation of polygonal faces, Newell's method for normal calculation, spherical UV generation, automatic mesh normalization
- **Smart Export**: Vertex deduplication, proper OFF format compliance
- **Example Pipeline**: Import mesh → modify → export demonstrated in `MeshBuilder.gd`

### Mesh Manipulation

- **Normalization**: Scale meshes to fit [-1, 1] cube while preserving aspect ratio
- **Center Calculation**: Find geometric center of any mesh
- **Face Removal**: Remove random faces for mesh decimation or stylistic effects
- **Material Management**: Easy material creation and application utilities

### Camera Controls

- Mouse look with cursor capture (ESC to release)
- Keyboard navigation:
  - **W/S** (or Arrow Up/Down): Forward/Backward
  - **A/D** (or Arrow Left/Right): Strafe Left/Right
  - **E**: Move up
  - **Q**: Move down
- Mouse wheel: Zoom in/out
- **P**: Cycle viewport debug draw modes
- **M**: Set viewport debug draw to mode 4

### Volumetric Modeling & Brush Tool

- **Overview**: The project includes an interactive volumetric modeling system (`VolumetricModeling`) that builds a voxelized octree from a list of spheres and renders the resulting volume. Spheres can be combined using operations: UNION, INTERSECTION, and SUBTRACTION.
- **Setup**: To use the brush tool, place a `VolumetricModeling` node in your scene and assign it to the `CameraMan` exported property `volumetrick_mesh` (select the camera node in the editor and drag the Volumetric node into the `volumetrick_mesh` slot).
- **Brush preview**: Hold `T` while in-game to display a translucent preview sphere in front of the camera. The preview shows the brush position (in camera local -Z direction) and its radius.
- **Add/Remove spheres**:
  - Press `+` to increase brush radius and add a UNION sphere at the preview position (adds volume).
  - Press `-` to decrease brush radius and add a UNION sphere at the preview position (adds volume).
  - After adding a sphere the volumetric node will re-build and re-render the combined octree (the code calls `render_spheres_as_one()` internally).
- **Brush parameters**: The camera script exposes `brush_radius` and `brush_distance` exported variables to tweak size and distance of the preview brush.

These interactive controls make it easy to paint additions and carve-outs into the procedural volume at runtime for quick experimentation.

### Technical Details

- Targets Godot 4.5 with Forward Plus renderer
- Uses SurfaceTool and ArrayMesh for efficient geometry generation
- All helper functions are static for easy reuse
- Backface culling disabled on generated materials for easier debugging

## How to Run

--------

### Prerequisites

- **Godot 4.4 or 4.5** recommended (project uses 4.5 features)
- Godot 4.2/4.3 may work but with limited feature support

### Steps

1. **Import Project**
   - Launch Godot Engine
   - Click "Import" and navigate to the project folder
   - Select `project.godot`

2. **Run the Demo**
   - Click the "Play" button (F5) to run the main scene
   - Or open `Scenes/Test_scene.tscn` and press "Play Scene" (F6)

3. **Explore the Demo**
   - You'll see multiple procedurally generated shapes
   - An imported bunny mesh from the OFF file
   - Use camera controls to navigate the scene

### Usage Examples

**Generate Custom Geometry:**

```gdscript
# In any Node3D script
draw_sphere(Vector3(0, 5, 0), 2.0, 16, 16, Color.RED)
draw_cylindre(Vector3(0, 0, 0), 1.0, 1.5, Vector3(0, 3, 0), 32)
```

**Import/Export Meshes:**

```gdscript
# Import an OFF file
var mesh_instance = Mesh_Importer.read_off("res://Meshes/bunny.off")
add_child(mesh_instance)

# Export to OFF format
var array_mesh: ArrayMesh = mesh_instance.mesh
Mesh_Importer.export_off(array_mesh, "res://Meshes/output.off", true)
```

**Manipulate Meshes:**

```gdscript
# Remove 10 random faces from a mesh
var modified = Mesh_Helpers._remove_random_faces(original_mesh, 10)

# Normalize mesh to unit cube
var normalized = Mesh_Helpers._normalise_mesh(mesh, center)
```

## Code Architecture

--------

### Design Patterns

- **Static Helper Functions**: `MeshImporter` and `MeshHelpers` use static methods for easy access without instantiation
- **SurfaceTool Pipeline**: Consistent use of SurfaceTool for vertex data management
- **Modular Design**: Each geometry type is self-contained in its own function

### Key Implementation Details

- **Normal Calculation**: Newell's method used for robust normal calculation on arbitrary polygons
- **UV Mapping**: Spherical projection for imported meshes, parametric UVs for generated geometry
- **Mesh Normalization**: Preserves aspect ratio while fitting to standard bounds
- **Vertex Deduplication**: Export function eliminates duplicate vertices for efficient file output

### File Format

The OFF (Object File Format) implementation supports:

- Header: `OFF` magic number
- Counts: vertex count, face count, edge count (always 0)
- Vertices: x y z coordinates (one per line)
- Faces: vertex_count vertex_indices (triangles only on export)

## Troubleshooting

--------

### Project Won't Open

- **Error**: Incompatible `config/features`
- **Solution**: Use Godot 4.4 or 4.5. Download from [godotengine.org](https://godotengine.org)

### Meshes Don't Appear

- **Issue**: MeshInstance3D nodes not visible
- **Checks**:
  - Ensure the script is attached to a Node3D in an active scene
  - Verify `get_tree().current_scene` is valid when creating meshes
  - Check console for errors during mesh generation

### Import/Export Errors

- **File Access Errors**: Ensure file paths use `res://` prefix for project files
- **Invalid OFF Format**: Verify OFF files start with "OFF" header and have correct vertex/face counts
- **Permission Errors**: Check file permissions when exporting

### Performance Issues

- **Too Many Faces**: Reduce subdivision counts (sides, parallels, meridians parameters)
- **Large Imported Meshes**: Consider using lower-resolution models for testing

## Potential Improvements

--------

### New Features

- **Advanced Mesh Operations**: Mesh subdivision, smoothing, edge collapse
- **More File Formats**: PLY, OBJ, STL import/export
- **Interactive Demo**: UI controls to adjust geometry parameters in real-time
- **Mesh Analysis**: Face/edge/vertex counting, bounding box calculation, surface area
- **Advanced Decimation**: Quadric error metrics for better face removal
- **Texture Support**: UV editing, texture coordinate generation options

### Code Quality

- **Parameter Validation**: Add bounds checking and error messages for invalid inputs
- **Unit Tests**: Add automated tests for import/export round-trip accuracy
- **Documentation**: Add inline comments and GDScript documentation strings
- **Performance**: Optimize vertex deduplication with spatial hashing
- **Editor Integration**: Custom inspector plugins for mesh manipulation

### User Experience

- **Exported Variables**: Expose geometry parameters in the editor for tweaking without code changes
- **Gizmos**: Visual handles for manipulating geometry in the viewport
- **Material Presets**: Library of common materials for generated geometry
- **Save/Load**: Save generated geometry configurations

## Project Structure

--------

```text
mod-geo/
├── .editorconfig
├── .gitattributes
├── .gitignore
├── icon.svg
├── project.godot
├── README.md
├── Meshes/
│   ├── buddha.off        # Sample mesh
│   ├── bunny.off          # Sample mesh
│   ├── cube.off           # Sample mesh
│   ├── plan.off           # Sample mesh
│   └── export.off         # Runtime generated
├── Scenes/
│   ├── camera_man.tscn    # Camera controller
│   └── Test_scene.tscn    # Main demo scene
└── Scripts/
    ├── MeshBuilder.gd     # Procedural geometry
    ├── MeshImporter.gd    # OFF import/export
    ├── MeshHelpers.gd     # Mesh utilities
    └── cameraman.gd       # Camera controller
```

## License

--------

This project is provided as educational example code. Feel free to use and modify for your own projects.
