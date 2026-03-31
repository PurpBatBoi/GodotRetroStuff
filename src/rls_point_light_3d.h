#pragma once

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/color.hpp>

namespace godot {

class RLS_VertexLightManager3D;

class RLS_PointLight3D : public Node3D {
	GDCLASS(RLS_PointLight3D, Node3D)

	bool enabled = true;
	Color color = Color(1.0, 0.95, 0.8, 1.0);
	float energy = 1.0f;
	float range = 5.0f;
	float attenuation = 1.0f;
	bool distance_fade_enabled = false;
	float distance_fade_begin = 40.0f;
	float distance_fade_length = 10.0f;
	bool fake_point_light = false;
	bool syncing_visibility = false;
	RLS_VertexLightManager3D *manager = nullptr;

	void _reconnect_manager();

protected:
	static void _bind_methods();
	void _notification(int p_what);

public:
	RLS_PointLight3D();
	~RLS_PointLight3D() override = default;

	void set_enabled(bool p_enabled);
	bool is_enabled() const;

	void set_color(const Color &p_color);
	Color get_color() const;

	void set_energy(float p_energy);
	float get_energy() const;

	void set_range(float p_range);
	float get_range() const;

	void set_attenuation(float p_attenuation);
	float get_attenuation() const;

	void set_distance_fade_enabled(bool p_enabled);
	bool is_distance_fade_enabled() const;

	void set_distance_fade_begin(float p_distance);
	float get_distance_fade_begin() const;

	void set_distance_fade_length(float p_distance);
	float get_distance_fade_length() const;

	void set_fake_point_light(bool p_fake_point_light);
	bool is_fake_point_light() const;
};

} // namespace godot
