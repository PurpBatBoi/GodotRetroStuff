# Godot Retro Stuff — N64 Visuals for Godot 4

An N64-style rendering pipeline for Godot 4.6+, built as a GDExtension (C++) with accompanying shaders. Aims to faithfully recreate the look and feel of the Nintendo 64's graphics hardware — vertex lighting, RDP color combiner, color quantization, dithering, and VI post-processing — all running in real-time.

![N64-style rendering demo](media/photo1.png)

## Features

- **N64 RSP Vertex Lighting** — Up to 7 directional lights + 1 ambient, calculated per-vertex just like the real hardware. Includes point light support for dynamic effects.
- **RDP Color Combiner** — A full implementation of the N64's multi-cycle color combiner as a Godot shader include, supporting all the blending modes the original hardware offered.
- **Post-Processing (RDP VI)** — Screen-space color quantization, ordered dithering, horizontal VI interpolation, and gamma correction to nail that distinctive N64 framebuffer look.
- **Custom Light Nodes** — `N64DirectionalLight3D` and `N64PointLight3D` nodes that act as RSP-style light proxies, managed by a `N64VertexLightManager3D`.
- **Editor Integration** — Custom gizmos for light visualization in the Godot editor.
- **Metallic / Matcap Support** — Includes a metallic reflection shader using matcap textures.

## Project Structure

```
src/                          # C++ GDExtension source
├── n64_directional_light_3d  # RSP-style directional light node
├── n64_point_light_3d        # Point light node
├── n64_vertex_light_manager  # Manages light state and pushes uniforms
├── n64_lit_mesh_instance_3d  # Mesh instance with per-vertex lighting
├── n64_editor_plugin         # Editor plugin registration
├── n64_light_gizmo_plugin    # Custom gizmos for light nodes
└── register_types            # GDExtension entry point

project/                      # Godot demo project
├── shaders/
│   ├── GenericVertexLit.gdshader       # Standard vertex-lit material
│   ├── GenericVertexLitBlend.gdshader  # Vertex-lit with blending
│   ├── Metallic.gdshader               # Matcap metallic shader
│   ├── post/RDPpost.gdshader           # N64 VI post-processing
│   └── shaderinclude/RDPcombiner.gdshaderinc  # RDP color combiner
└── addons/
    └── n64_visuals_billboards/         # Billboard addon
```

## Requirements

- [Godot 4.6+](https://godotengine.org/) (GL Compatibility renderer)
- [SCons](https://scons.org/) build system
- C++ compiler (GCC, Clang, or MSVC)

## Building

1. Clone the repository with submodules:
   ```bash
   git clone --recurse-submodules https://github.com/PurpBatBoi/GodotRetroStuff.git
   cd GodotRetroStuff
   ```

2. If you already cloned without submodules:
   ```bash
   git submodule update --init --recursive
   ```

3. Build the GDExtension:
   ```bash
   scons          # debug build
   scons target=template_release  # release build
   ```

4. Open the `project/` folder in Godot.

## Usage

### Shaders Only (No C++ Required)

If you just want the N64 visual style without the custom lighting nodes, copy the following into your Godot project:

- `project/shaders/` — All shader files
- `project/shaders/post/RDPpost.gdshader` — Apply to a full-screen quad for the N64 post-processing look

### Full Pipeline (With GDExtension)

For the complete experience including RSP-style vertex lighting:

1. Build the extension (see above)
2. Copy `project/bin/` into your Godot project
3. Copy the shader files from `project/shaders/`
4. Add `N64VertexLightManager3D` to your scene
5. Add `N64DirectionalLight3D` or `N64PointLight3D` nodes for lighting
6. Use `N64LitMeshInstance3D` for meshes that should receive vertex lighting

## License

[MIT](LICENSE.md)
