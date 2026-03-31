# RetroLightingSystem Manual

This manual describes the full feature set of the retro vertex lighting extension in this repository.

The project itself is developed in `N64v3`, but the packaged addon you install into other Godot projects is named `RetroLightingSystem`.

## What This Extension Is

RetroLightingSystem is a custom Godot lighting workflow built around:

- a native C++ GDExtension runtime
- custom light nodes
- shader-based vertex lighting
- editor gizmos and billboard icons

It is designed for stylized retro lighting, especially scenes that want N64 or low-poly era light behavior without modern real-time shadow complexity.

This system does **not** use Godot's built-in dynamic light pipeline directly. Instead, it:

1. finds the most relevant lights for each `N64LitMeshInstance3D`
2. packs those lights into shader uniforms
3. computes the final lighting in the material shader

## Main Features

- Custom directional, point, and spotlight nodes
- Fake-light modes for cleaner retro per-mesh lighting
- Per-mesh light packing in C++
- Vertex-lit shader workflow
- Interactive editor gizmos for point, spot, and directional lights
- Billboard icons in the 3D viewport
- Custom node icons in the scene tree
- Packaged addon workflow for Linux, Windows, and Web
- Material-side control over fake-light handling

## Included Node Types

### `N64VertexLightManager3D`

This is the central manager node.

It is responsible for:

- collecting lights under it
- collecting lit meshes under it
- choosing which lights affect each mesh
- sending light data to runtime shader materials

Properties:

- `ambient_color`
- `ambient_energy`
- `max_lights`

`max_lights` is capped at `8`, which is the system maximum.

### `N64LitMeshInstance3D`

This is the mesh node that receives packed light data from the manager.

Use it instead of a normal `MeshInstance3D` when you want this extension's lighting behavior.

It supports:

- `material_override`
- `surface_override_material`
- shader materials assigned directly on mesh surfaces

At runtime, shader materials are duplicated per mesh instance so multiple mesh instances can share one mesh resource while still receiving different local light data.

### `N64DirectionalLight3D`

A custom directional light.

Behavior:

- infinite direction-only light
- no range falloff
- uses the node's forward direction

Best for:

- sun/moon style lighting
- broad scene fills
- stable retro character highlights

### `N64PointLight3D`

A custom point light.

Behavior:

- position-based light
- uses `range`
- uses `attenuation`

Best for:

- torches
- lamps
- room accents
- localized colored fills

Extra option:

- `fake_point_light`

### `N64SpotLight3D`

A custom spotlight.

Behavior:

- position-based light
- uses `range`
- uses `attenuation`
- uses cone direction
- uses `spot_angle`
- uses `spot_blend`

Best for:

- flashlights
- stage lights
- focused beams
- directional accents

Extra option:

- `fake_spot_light`

## What "Fake Lighting" Means

"Fake" lights in this extension are not fake in the sense of being broken or decorative. They are intentional approximations made to look better on retro geometry.

### Why Fake Lights Exist

On low-poly or vertex-lit meshes, normal point and spot lights can:

- pop abruptly across large triangles
- shift harshly as a mesh moves
- look muddy on characters
- lose a clear readable light direction

Fake lights trade physical accuracy for cleaner per-mesh readability.

### `fake_point_light`

When enabled on `N64PointLight3D`, the light is still selected using its point-light position, range, and attenuation, but once it affects a mesh it is converted into a **per-mesh directional light** aimed from the mesh toward the point light.

This gives you:

- clearer light direction on characters
- more stable shading on low-poly meshes
- less noisy vertex-light movement

It still fades out by distance and range.

### `fake_spot_light`

When enabled on `N64SpotLight3D`, the spotlight still uses its cone and range to decide whether it affects a mesh, but the final contribution is packed as a **per-mesh directional approximation**.

This gives you:

- cleaner spotlight direction on low-poly meshes
- less noticeable per-vertex popping
- more stable stylized beams

It still respects:

- spotlight cone
- spotlight range
- attenuation

## Material Controls

The shared lighting include is:

`project/shaders/shaderinclude/vertexLightProcess.gdshaderinc`

and the packaged addon version lives under:

`res://addons/RetroLightingSystem/shaders/shaderinclude/vertexLightProcess.gdshaderinc`

Important uniforms exposed there:

### `ignore_fake_lights`

Default: `false`

When enabled on a material, fake local lights are ignored for that mesh.

That means:

- fake point lights behave like normal point lights
- fake spot lights behave like normal spot lights

Use this when:

- characters should use fake lights for readable shading
- scenery should keep true radius/cone behavior
- you want one material set to opt out of the per-mesh fake-light approximation

Important detail:

- light packing is mesh-wide, not per surface
- if any active runtime shader material on the mesh enables `ignore_fake_lights`, the entire mesh ignores fake lights

### `use_material_ambient`

Switches ambient lighting to the material's local ambient value instead of the manager's global ambient.

### `material_ambient`

Per-material ambient color and intensity when `use_material_ambient` is enabled.

### `direct_light_additive_mix`

Controls how direct lighting is blended into the result.

- `0.0` = direct light is multiplied into shade in a more classic retro style
- `1.0` = direct light is added on top

## Shader Variants

Current included shaders:

- `GenericVertexLit.gdshader`
- `GenericVertexLitBlend.gdshader`
- `Metallic.gdshader`
- `post/RDPpost.gdshader`

These shaders share the lighting include and can all use the same packed light data model.

### `N64_MAX_LIGHTS`

The include supports up to `8` lights.

Each main shader can override `N64_MAX_LIGHTS` before including the shared lighting file.

Use lower values when:

- a material does not need many lights
- you want cheaper vertex processing
- you want stricter artistic control

Use `8` when:

- you want the full supported cap

## Light Selection Behavior

The manager packs lights once per `N64LitMeshInstance3D`.

### Order of selection

1. directional lights are packed first
2. local lights are ranked after that
3. only the strongest relevant local lights are kept, up to `max_lights`

### Local lights considered

- point lights
- fake point lights
- spotlights
- fake spotlights

### Selection logic

The system estimates whether a light contributes to the mesh using the mesh bounds, not just the mesh origin. This helps large floors and large simple scenery receive nearby lights correctly.

Lights that contribute nothing are skipped before taking one of the limited light slots.

## Editor Features

The extension includes editor UX, not just runtime code.

### Billboard icons

Viewport billboard icons are shown for:

- point lights
- spotlights
- directional lights

Scene-tree icons are also provided.

### Gizmos

Interactive 3D gizmos are included for:

- point light range
- spotlight range
- spotlight cone angle
- directional light direction arrow

These gizmos support editor undo/redo.

## Installation and Packaging

The reusable packaged addon is generated at:

`packaged/RetroLightingSystem`

To install in another project:

1. copy `RetroLightingSystem` into that project's `addons/` folder
2. open the project in Godot
3. enable `RetroLightingSystem` in `Project Settings > Plugins`
4. use the packaged shaders from `res://addons/RetroLightingSystem/shaders/`

## Platform Support

The packaging workflow currently targets:

- Linux
- Windows
- Web

The build scripts in this repo:

- `build_all.fish`
- `package_extension.fish`

are used to rebuild native binaries and refresh the packaged addon contents.

## What This Extension Does Not Do

- dynamic shadows
- physically accurate lighting
- per-pixel modern PBR lighting
- Godot built-in omni/spot shadow features

This is a stylized retro lighting system, not a replacement for the full modern renderer.

## Recommended Use Cases

Use normal point and spot lights when you want:

- obvious radius/cone behavior
- scenery-focused local lighting
- more literal positional lighting

Use fake point and fake spot lights when you want:

- clearer character shading
- stronger directional readability
- less noisy vertex lighting
- more stable low-poly highlights

Use `ignore_fake_lights` when you want:

- characters to use fake-light behavior
- scenery to use normal local-light behavior

## Current Limitations

- light packing is mesh-wide, not per surface
- fake-light opt-out is also effectively mesh-wide
- spotlight and point behavior are still vertex-lit, so extremely low-poly meshes will always show some stylized stepping
- the packaged addon name is `RetroLightingSystem`, while parts of the source project still use older internal naming such as `N64`

## Related Files

Useful project files:

- [build_all.fish](/home/purpbatboi/Documents/Gamedev/N64v3/build_all.fish)
- [package_extension.fish](/home/purpbatboi/Documents/Gamedev/N64v3/package_extension.fish)
- [lighting-authoring.md](/home/purpbatboi/Documents/Gamedev/N64v3/docs/lighting-authoring.md)
- [vertexLightProcess.gdshaderinc](/home/purpbatboi/Documents/Gamedev/N64v3/project/shaders/shaderinclude/vertexLightProcess.gdshaderinc)
- [README.md](/home/purpbatboi/Documents/Gamedev/N64v3/README.md)

