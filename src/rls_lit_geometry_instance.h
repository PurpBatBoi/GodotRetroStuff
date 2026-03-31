#pragma once

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/variant/aabb.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_vector4_array.hpp>
#include <godot_cpp/variant/vector4.hpp>

#include <godot_cpp/templates/vector.hpp>

namespace godot {

class RLS_VertexLightManager3D;

class RLS_LitGeometryInstance {
protected:
	RLS_VertexLightManager3D *manager = nullptr;
	bool cached_ignore_fake_lights = false;

	int32_t cached_light_count = -1;
	PackedVector4Array cached_light_vector_type;
	PackedVector4Array cached_light_color_energy;
	PackedVector4Array cached_light_spot_direction_inner;
	PackedFloat32Array cached_light_range;
	PackedFloat32Array cached_light_attenuation;
	PackedFloat32Array cached_light_spot_outer_cos;
	Vector4 cached_global_ambient = Vector4();

public:
	virtual ~RLS_LitGeometryInstance() = default;

	virtual Node3D *get_geometry_node() = 0;
	virtual const Node3D *get_geometry_node() const = 0;
	virtual AABB get_geometry_local_aabb() const = 0;
	virtual Ref<ShaderMaterial> get_runtime_shader_material() const = 0;
	virtual const Vector<Ref<ShaderMaterial>> &get_runtime_surface_shader_materials() const = 0;
	virtual bool sync_runtime_materials() = 0;
	virtual bool compute_ignore_fake_lights() const = 0;

	void handle_enter_tree();
	void handle_exit_tree();
	void handle_parented();
	void handle_unparented();
	void handle_internal_process();
	void handle_transform_changed();

	bool is_ignoring_fake_lights() const;
	bool update_cached_light_state(int32_t p_light_count, const PackedVector4Array &p_light_vector_type, const PackedVector4Array &p_light_color_energy, const PackedVector4Array &p_light_spot_direction_inner, const PackedFloat32Array &p_light_range, const PackedFloat32Array &p_light_attenuation, const PackedFloat32Array &p_light_spot_outer_cos, const Vector4 &p_global_ambient);
	void clear_cached_light_state();
	void notify_runtime_material_changed();

protected:
	void reconnect_manager();
};

} // namespace godot
