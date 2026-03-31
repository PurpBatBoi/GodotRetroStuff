# RLS Lighting Authoring

This project packs custom light data per `RLS_LitMeshInstance3D` and applies it in the vertex-light shader path.

## Light Types

- `RLS_DirectionalLight3D`
  - Infinite directional contribution.
  - Always uses the light node's forward direction.
- `RLS_PointLight3D`
  - Normal point light with position, range, and attenuation.
- `RLS_PointLight3D` with `fake_point_light = true`
  - Per-mesh directional light aimed from the mesh origin toward the point light.
  - Still fades by range and attenuation based on mesh-origin distance to the light.
- `RLS_SpotLight3D`
  - Point light with cone direction, `spot_angle`, and `spot_blend`.

## Material Controls

The shared lighting include, `vertexLightProcess.gdshaderinc`, exposes:

- `ignore_fake_lights`
  - Default: `false`
  - When enabled, fake point lights are treated as normal point lights for that mesh.
  - Useful for scenery that should respect point-light radius instead of receiving a directional-style fake point light.

## `RLS_MAX_LIGHTS`

- The lighting include has a fallback `RLS_MAX_LIGHTS` value of `8`.
- Individual shaders can override it before including `vertexLightProcess.gdshaderinc`.
- Use lower values on cheaper materials if you want to reduce per-vertex light work.

## Material Authoring Paths

Lighting supports the common Godot authoring paths for `RLS_LitMeshInstance3D`:

- `material_override`
- `surface_override_material`
- shader materials authored directly on the mesh resource's surfaces

When a shader material is authored directly on a mesh surface, the runtime duplicates it into a per-instance surface override. From that point on, the mesh instance owns the lit copy.

This means:

- two mesh instances can share the same mesh resource and still receive different packed local lights
- changes to the original shared mesh-surface material do not automatically propagate after the runtime override has been created

## Mesh-Wide Light Packing

Light selection is packed once per `RLS_LitMeshInstance3D`, not separately per surface.

As a result:

- if any runtime shader material on the mesh enables `ignore_fake_lights`, the whole mesh uses normal point-light and fake spotlight behavior instead of the per-mesh fake-light approximation
- local-light slot selection is based on estimated contribution at the mesh origin

## Local Light Selection

- Directional lights are packed first.
- Point, fake point, and spot lights are ranked by estimated contribution at the mesh origin.
- Lights with zero contribution at the mesh origin are skipped before slot selection.

This helps avoid cases where a nearby but fully out-of-range or out-of-cone light steals one of the local-light slots.
