#pragma once

#include "rls_lit_geometry_instance.h"

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/color.hpp>

#include <godot_cpp/templates/hash_set.hpp>
#include <godot_cpp/templates/vector.hpp>

namespace godot {

class RLS_DirectionalLight3D;
class RLS_PointLight3D;
class RLS_SpotLight3D;

class RLS_VertexLightManager3D : public Node3D {
	GDCLASS(RLS_VertexLightManager3D, Node3D)

	static constexpr int32_t MAX_SUPPORTED_LIGHTS = 8;

	Color ambient_color = Color(0.12, 0.12, 0.16, 1.0);
	float ambient_energy = 1.0f;
	int32_t max_lights = MAX_SUPPORTED_LIGHTS;
	bool lights_dirty = true;

	Vector<RLS_PointLight3D *> point_lights;
	Vector<RLS_SpotLight3D *> spot_lights;
	Vector<RLS_DirectionalLight3D *> directional_lights;
	Vector<RLS_LitGeometryInstance *> lit_geometries;
	HashSet<RLS_LitGeometryInstance *> dirty_geometries;

	static bool _remove_point_light(Vector<RLS_PointLight3D *> &p_lights, RLS_PointLight3D *p_light);
	static bool _remove_spot_light(Vector<RLS_SpotLight3D *> &p_lights, RLS_SpotLight3D *p_light);
	static bool _remove_directional_light(Vector<RLS_DirectionalLight3D *> &p_lights, RLS_DirectionalLight3D *p_light);
	static bool _remove_lit_geometry(Vector<RLS_LitGeometryInstance *> &p_geometries, RLS_LitGeometryInstance *p_geometry);

	void _rebuild_all_geometries();
	void _rebuild_dirty_geometries();
	void _apply_geometry_lighting(RLS_LitGeometryInstance *p_geometry);
	void _mark_all_geometries_dirty();

protected:
	static void _bind_methods();
	void _notification(int p_what);

public:
	RLS_VertexLightManager3D() = default;
	~RLS_VertexLightManager3D() override = default;

	void set_ambient_color(const Color &p_color);
	Color get_ambient_color() const;

	void set_ambient_energy(float p_energy);
	float get_ambient_energy() const;

	void set_max_lights(int32_t p_max_lights);
	int32_t get_max_lights() const;

	void register_point_light(RLS_PointLight3D *p_light);
	void unregister_point_light(RLS_PointLight3D *p_light);
	void register_spot_light(RLS_SpotLight3D *p_light);
	void unregister_spot_light(RLS_SpotLight3D *p_light);
	void register_directional_light(RLS_DirectionalLight3D *p_light);
	void unregister_directional_light(RLS_DirectionalLight3D *p_light);
	void register_lit_geometry(RLS_LitGeometryInstance *p_geometry);
	void unregister_lit_geometry(RLS_LitGeometryInstance *p_geometry);

	void notify_light_changed();
	void notify_geometry_changed(RLS_LitGeometryInstance *p_geometry);
};

} // namespace godot
