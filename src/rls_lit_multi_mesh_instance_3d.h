#pragma once

#include "rls_lit_geometry_instance.h"

#include <godot_cpp/classes/multi_mesh_instance3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>

#include <godot_cpp/templates/vector.hpp>

namespace godot {

class RLS_LitMultiMeshInstance3D : public MultiMeshInstance3D, public RLS_LitGeometryInstance {
	GDCLASS(RLS_LitMultiMeshInstance3D, MultiMeshInstance3D)

	Ref<ShaderMaterial> runtime_shader_material;
	Vector<Ref<ShaderMaterial>> runtime_surface_shader_materials;
	uint64_t last_material_instance_id = 0;
	uint64_t last_multimesh_instance_id = 0;
	uint64_t last_mesh_instance_id = 0;
	Vector<uint64_t> last_surface_material_instance_ids;
	AABB last_local_aabb;
	bool has_last_local_aabb = false;

	bool _sync_multimesh_surface_shader_materials();

protected:
	static void _bind_methods();
	void _notification(int p_what);

public:
	RLS_LitMultiMeshInstance3D();
	~RLS_LitMultiMeshInstance3D() override = default;

	Node3D *get_geometry_node() override;
	const Node3D *get_geometry_node() const override;
	AABB get_geometry_local_aabb() const override;
	Ref<ShaderMaterial> get_runtime_shader_material() const override;
	const Vector<Ref<ShaderMaterial>> &get_runtime_surface_shader_materials() const override;
	bool sync_runtime_materials() override;
	bool compute_ignore_fake_lights() const override;
};

} // namespace godot
