#pragma once

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/color.hpp>

namespace godot {

class N64VertexLightManager3D;

class N64PointLight3D : public Node3D {
	GDCLASS(N64PointLight3D, Node3D)

	bool enabled = true;
	Color color = Color(1.0, 0.95, 0.8, 1.0);
	float energy = 1.0f;
	float range = 5.0f;
	float attenuation = 1.0f;
	N64VertexLightManager3D *manager = nullptr;

	void _reconnect_manager();

protected:
	static void _bind_methods();
	void _notification(int p_what);

public:
	N64PointLight3D();
	~N64PointLight3D() override = default;

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
};

} // namespace godot
