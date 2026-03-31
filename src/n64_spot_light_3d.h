#pragma once

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class N64VertexLightManager3D;

class N64SpotLight3D : public Node3D {
	GDCLASS(N64SpotLight3D, Node3D)

	bool enabled = true;
	Color color = Color(1.0, 0.95, 0.8, 1.0);
	float energy = 1.0f;
	float range = 6.0f;
	float attenuation = 1.0f;
	float spot_angle = 45.0f;
	float spot_blend = 0.15f;
	N64VertexLightManager3D *manager = nullptr;

	void _reconnect_manager();

protected:
	static void _bind_methods();
	void _notification(int p_what);

public:
	N64SpotLight3D();
	~N64SpotLight3D() override = default;

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

	void set_spot_angle(float p_spot_angle);
	float get_spot_angle() const;

	void set_spot_blend(float p_spot_blend);
	float get_spot_blend() const;

	Vector3 get_light_direction() const;
};

} // namespace godot
