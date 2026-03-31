# RetroLightingSystem Manual

RetroLightingSystem is a stylized retro lighting addon for Godot 4.x. It is built for low-poly, vertex-lit scenes

## What It Includes

- custom directional, point, and spot light nodes
- a light manager that chooses and packs lights per mesh
- shader-based vertex lighting
- editor gizmos and icons
- reusable shaders and shader includes
- original C++ GDExtension source under `source/src/`

## What It Is Best At

Use RetroLightingSystem when you want:

- retro-era or PS1-era style lighting
- stable, readable character shading
- low-cost stylized scene lighting
- more artistic control than physical accuracy

## Installation

1. Copy `RetroLightingSystem` into your project's `addons/` folder.
2. Open the project in Godot.
3. Enable `RetroLightingSystem` in `Project Settings > Plugins`.
4. Use the included shaders from `res://addons/RetroLightingSystem/shaders/`.

Documentation is included in:

- `res://addons/RetroLightingSystem/docs/RETRO_LIGHTING_SYSTEM_MANUAL.md`
- `res://addons/RetroLightingSystem/docs/lighting-authoring.md`

Bundled source files are included in:

- `res://addons/RetroLightingSystem/source/src/`
- `res://addons/RetroLightingSystem/source/SConstruct`
- `res://addons/RetroLightingSystem/source/CMakeLists.txt`

## Main Nodes

### `RLS_VertexLightManager3D`

This is the central manager node. It collects custom lights, finds lit meshes under it, and sends packed light data to their materials.

Important properties:

- `ambient_color`
- `ambient_energy`
- `max_lights`

`max_lights` is capped at `8`.

### `RLS_LitMeshInstance3D`

Use this instead of a normal `MeshInstance3D` when you want the addon to light that mesh.

It works with:

- `material_override`
- `surface_override_material`
- shader materials assigned directly on mesh surfaces

### `RLS_LitMultiMeshInstance3D`

Use this instead of a normal `MultiMeshInstance3D` when you want the addon to light that geometry.

It works with:

- `material_override`
- shader materials assigned on the `MultiMesh`'s source mesh surfaces

### `RLS_DirectionalLight3D`

Use for broad scene lighting such as sunlight, moonlight, or large fill light.

### `RLS_PointLight3D`

Use for torches, lamps, and local colored fills.

Extra option:

- `fake_point_light`

### `RLS_SpotLight3D`

Use for flashlights, stage lights, and focused beams.

Extra option:

- `fake_spot_light`

## Fake Lighting

Fake lights are intentional stylized approximations for low-poly geometry.

On very simple meshes, normal point and spot lights can:

- pop harshly across large triangles
- shift too much as a mesh moves
- produce muddy lighting on characters

Fake lights keep the light's selection rules, but change the final shading to a cleaner per-mesh directional approximation.

Use fake lights when you want:

- cleaner character shading
- clearer light direction
- less noisy lighting on low-poly meshes

## Material Controls

The shared lighting include is available in the packaged addon at:

`res://addons/RetroLightingSystem/shaders/shaderinclude/vertexLightProcess.gdshaderinc`

Important controls:

### `ignore_fake_lights`

Default: `false`

When enabled, fake local lights are treated like normal point or spot lights for that mesh.

Use this when:

- characters should use fake lights
- scenery should keep radius or cone behavior

### `use_material_ambient`

Uses the material's local ambient instead of the manager's ambient.

### `material_ambient`

Sets the material's own ambient when `use_material_ambient` is enabled.

### `direct_light_additive_mix`

Controls whether direct light behaves more like classic multiplied shading or more additive lighting.

## Included Shaders

- `GenericVertexLit.gdshader`
- `GenericVertexLitBlend.gdshader`
- `Metallic.gdshader`
- `post/RDPpost.gdshader`

## Editor Features

The addon includes:

- billboard icons for the custom light nodes
- scene-tree icons
- gizmos for point light range
- gizmos for spotlight range and cone angle
- a gizmo arrow for directional light direction

## Current Limits

- lighting is packed per mesh, not per surface
- fake-light opt-out is effectively mesh-wide
- point and spot behavior is still vertex-lit, so very low-poly meshes will show stylized stepping
- the maximum supported light count is `8`

## What It Does Not Do

- dynamic shadows
- physically accurate lighting
- full modern per-pixel PBR lighting
- built-in Godot omni or spot shadow workflows

RetroLightingSystem is a stylized retro lighting workflow, not a replacement for Godot's full modern renderer.
