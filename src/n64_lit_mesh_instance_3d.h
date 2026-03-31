#pragma once

#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_vector4_array.hpp>
#include <godot_cpp/variant/vector4.hpp>

#include <godot_cpp/templates/vector.hpp>

namespace godot {

class N64VertexLightManager3D;

class N64LitMeshInstance3D : public MeshInstance3D {
	GDCLASS(N64LitMeshInstance3D, MeshInstance3D)

	N64VertexLightManager3D *manager = nullptr;
	Ref<ShaderMaterial> runtime_shader_material;
	Vector<Ref<ShaderMaterial>> runtime_surface_shader_materials;
	uint64_t last_material_instance_id = 0;
	Vector<uint64_t> last_surface_material_instance_ids;
	bool cached_ignore_fake_point_lights = false;

	int32_t cached_light_count = -1;
	PackedVector4Array cached_light_vector_type;
	PackedVector4Array cached_light_color_energy;
	PackedVector4Array cached_light_spot_direction_inner;
	PackedFloat32Array cached_light_range;
	PackedFloat32Array cached_light_attenuation;
	PackedFloat32Array cached_light_spot_outer_cos;
	Vector4 cached_global_ambient = Vector4();

	void _reconnect_manager();
	bool _sync_runtime_shader_material();
	bool _sync_surface_shader_materials();
	bool _compute_ignore_fake_point_lights() const;

protected:
	static void _bind_methods();
	void _notification(int p_what);

public:
	N64LitMeshInstance3D();
	~N64LitMeshInstance3D() override = default;

	bool is_ignoring_fake_point_lights() const;

	Ref<ShaderMaterial> get_runtime_shader_material() const;
	const Vector<Ref<ShaderMaterial>> &get_runtime_surface_shader_materials() const;
	bool update_cached_light_state(int32_t p_light_count, const PackedVector4Array &p_light_vector_type, const PackedVector4Array &p_light_color_energy, const PackedVector4Array &p_light_spot_direction_inner, const PackedFloat32Array &p_light_range, const PackedFloat32Array &p_light_attenuation, const PackedFloat32Array &p_light_spot_outer_cos, const Vector4 &p_global_ambient);
	void clear_cached_light_state();
	void notify_runtime_material_changed();
};

} // namespace godot
