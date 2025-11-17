# CameraMan Plugin

A versatile 3D camera controller for Godot 4 that provides smooth mouse look, keyboard movement controls, zooming, and debugging features. Perfect for exploring 3D scenes, prototyping, and debugging geometry.

## Features

- **Mouse Look**: Smooth camera rotation with captured mouse mode
- **Movement Controls**: WASD + QE movement (or arrow keys)
- **Zoom**: Mouse wheel zooming with configurable limits
- **Sprint**: Hold Shift for faster movement
- **Torch Light**: Built-in spotlight with toggle (F key)
- **Debug Views**: Cycle through different rendering modes (P key)
- **Wireframe Mode**: Quick wireframe toggle (M key)
- **Mouse Capture**: ESC to toggle mouse capture/release

## Installation

1. Copy the `testcameraman` folder to your project's `addons/` directory
2. Enable the plugin in Project Settings > Plugins
3. The "CameraMan" node type will be available in the Create Node dialog

## Usage

### Adding to Scene

1. In the Scene dock, click "Create Node" (+ icon)
2. Search for "CameraMan"
3. Add it to your scene
4. Position the camera where you want to start

### Controls

| Input | Action |
|-------|--------|
| **Mouse Movement** | Look around (when mouse captured) |
| **WASD / Arrow Keys** | Move forward/back/left/right |
| **Q / E** | Move down/up |
| **Shift** | Sprint (faster movement) |
| **Mouse Wheel** | Zoom in/out |
| **F** | Toggle torch light |
| **P** | Cycle debug rendering modes |
| **M** | Toggle wireframe mode |
| **ESC** | Toggle mouse capture |

### Configuration

The CameraMan node exposes several properties in the inspector:

#### Movement Group

- **Speed**: Base movement speed (default: 5.0)
- **Sprint Multiplier**: Speed boost when sprinting (default: 2.0)
- **Mouse Sensitivity**: Mouse look sensitivity (default: 0.2)

#### Zoom Group

- **Zoom Speed**: How fast zoom changes (default: 2.0)
- **Min Zoom**: Closest zoom level (default: 2.0)
- **Max Zoom**: Farthest zoom level (default: 120.0)

#### Light Group

- **Torch Enabled**: Whether to include torch light (default: true)
- **Torch Intensity**: Light intensity (default: 1.0)
- **Torch Range**: Light range (default: 10.0)

## Debug Features

The CameraMan includes several debugging features useful for 3D development:

- **Debug View Cycling (P)**: Cycles through Normal, Unshaded, Lighting, Overdraw, and Wireframe modes
- **Quick Wireframe (M)**: Instantly switches to wireframe mode
- **Console Output**: Prints current mode and control help to console

## Input Map Requirements

The plugin requires these input actions to be defined in your project's Input Map:

- `camera_left` (A, Left Arrow)
- `camera_right` (D, Right Arrow)  
- `camera_up` (W, Up Arrow)
- `camera_down` (S, Down Arrow)
- `camera_high` (E)
- `camera_low` (Q)
- `zoom_in` (Mouse Wheel Up)
- `zoom_out` (Mouse Wheel Down)
- `toggle_light` (F)

## Tips

- **In Editor**: Mouse capture is disabled by default when running in the editor
- **Performance**: Use wireframe mode to check geometry complexity
- **Debugging**: Use different debug views to identify rendering issues
- **Navigation**: Start with mouse captured for immediate control, use ESC to release for UI interaction

## Author

Created by VillerotJustin for the ModGeo project.
