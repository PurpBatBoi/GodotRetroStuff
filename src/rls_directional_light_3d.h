#pragma once

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class RLS_VertexLightManager3D;

class RLS_DirectionalLight3D : public Node3D {
	GDCLASS(RLS_DirectionalLight3D, Node3D)

	bool enabled = true;
	Color color = Color(0.8, 0.9, 1.0, 1.0);
	float energy = 1.0f;
	bool syncing_visibility = false;
	RLS_VertexLightManager3D *manager = nullptr;

	void _reconnect_manager();

protected:
	static void _bind_methods();
	void _notification(int p_what);

public:
	RLS_DirectionalLight3D();
	~RLS_DirectionalLight3D() override = default;

	void set_enabled(bool p_enabled);
	bool is_enabled() const;

	void set_color(const Color &p_color);
	Color get_color() const;

	void set_energy(float p_energy);
	float get_energy() const;

	Vector3 get_light_direction() const;
};

} // namespace godot
