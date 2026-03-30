#pragma once

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_vector4_array.hpp>
#include <godot_cpp/variant/vector4.hpp>

#include <godot_cpp/templates/hash_set.hpp>
#include <godot_cpp/templates/vector.hpp>

namespace godot {

class N64DirectionalLight3D;
class N64LitMeshInstance3D;
class N64PointLight3D;

class N64VertexLightManager3D : public Node3D {
	GDCLASS(N64VertexLightManager3D, Node3D)

	static constexpr int32_t MAX_SUPPORTED_LIGHTS = 8;

	Color ambient_color = Color(0.12, 0.12, 0.16, 1.0);
	float ambient_energy = 1.0f;
	int32_t max_lights = MAX_SUPPORTED_LIGHTS;
	bool lights_dirty = true;

	Vector<N64PointLight3D *> point_lights;
	Vector<N64DirectionalLight3D *> directional_lights;
	Vector<N64LitMeshInstance3D *> lit_meshes;
	HashSet<N64LitMeshInstance3D *> dirty_meshes;

	static bool _remove_point_light(Vector<N64PointLight3D *> &p_lights, N64PointLight3D *p_light);
	static bool _remove_directional_light(Vector<N64DirectionalLight3D *> &p_lights, N64DirectionalLight3D *p_light);
	static bool _remove_lit_mesh(Vector<N64LitMeshInstance3D *> &p_meshes, N64LitMeshInstance3D *p_mesh);

	void _rebuild_all_meshes();
	void _rebuild_dirty_meshes();
	void _apply_mesh_lighting(N64LitMeshInstance3D *p_mesh);
	void _mark_all_meshes_dirty();

protected:
	static void _bind_methods();
	void _notification(int p_what);

public:
	N64VertexLightManager3D() = default;
	~N64VertexLightManager3D() override = default;

	void set_ambient_color(const Color &p_color);
	Color get_ambient_color() const;

	void set_ambient_energy(float p_energy);
	float get_ambient_energy() const;

	void set_max_lights(int32_t p_max_lights);
	int32_t get_max_lights() const;

	void register_point_light(N64PointLight3D *p_light);
	void unregister_point_light(N64PointLight3D *p_light);
	void register_directional_light(N64DirectionalLight3D *p_light);
	void unregister_directional_light(N64DirectionalLight3D *p_light);
	void register_lit_mesh(N64LitMeshInstance3D *p_mesh);
	void unregister_lit_mesh(N64LitMeshInstance3D *p_mesh);

	void notify_light_changed();
	void notify_mesh_changed(N64LitMeshInstance3D *p_mesh);
};

} // namespace godot
