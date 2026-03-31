#include "n64_spot_light_3d.h"

#include "n64_vertex_light_manager_3d.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/core/object.hpp>

using namespace godot;

namespace {

N64VertexLightManager3D *find_manager_ancestor(Node *p_node) {
	Node *current = p_node == nullptr ? nullptr : p_node->get_parent();
	while (current != nullptr) {
		if (N64VertexLightManager3D *manager = Object::cast_to<N64VertexLightManager3D>(current)) {
			return manager;
		}
		current = current->get_parent();
	}
	return nullptr;
}

} // namespace

N64SpotLight3D::N64SpotLight3D() {
	set_notify_transform(true);
}

void N64SpotLight3D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_enabled", "enabled"), &N64SpotLight3D::set_enabled);
	ClassDB::bind_method(D_METHOD("is_enabled"), &N64SpotLight3D::is_enabled);
	ClassDB::bind_method(D_METHOD("set_color", "color"), &N64SpotLight3D::set_color);
	ClassDB::bind_method(D_METHOD("get_color"), &N64SpotLight3D::get_color);
	ClassDB::bind_method(D_METHOD("set_energy", "energy"), &N64SpotLight3D::set_energy);
	ClassDB::bind_method(D_METHOD("get_energy"), &N64SpotLight3D::get_energy);
	ClassDB::bind_method(D_METHOD("set_range", "range"), &N64SpotLight3D::set_range);
	ClassDB::bind_method(D_METHOD("get_range"), &N64SpotLight3D::get_range);
	ClassDB::bind_method(D_METHOD("set_attenuation", "attenuation"), &N64SpotLight3D::set_attenuation);
	ClassDB::bind_method(D_METHOD("get_attenuation"), &N64SpotLight3D::get_attenuation);
	ClassDB::bind_method(D_METHOD("set_spot_angle", "spot_angle"), &N64SpotLight3D::set_spot_angle);
	ClassDB::bind_method(D_METHOD("get_spot_angle"), &N64SpotLight3D::get_spot_angle);
	ClassDB::bind_method(D_METHOD("set_spot_blend", "spot_blend"), &N64SpotLight3D::set_spot_blend);
	ClassDB::bind_method(D_METHOD("get_spot_blend"), &N64SpotLight3D::get_spot_blend);
	ClassDB::bind_method(D_METHOD("set_fake_spot_light", "fake_spot_light"), &N64SpotLight3D::set_fake_spot_light);
	ClassDB::bind_method(D_METHOD("is_fake_spot_light"), &N64SpotLight3D::is_fake_spot_light);

	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "enabled"), "set_enabled", "is_enabled");
	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "color"), "set_color", "get_color");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "energy", PROPERTY_HINT_RANGE, "0.0,16.0,0.01,or_greater"), "set_energy", "get_energy");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "range", PROPERTY_HINT_RANGE, "0.01,256.0,0.01,or_greater"), "set_range", "get_range");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "attenuation", PROPERTY_HINT_RANGE, "0.01,8.0,0.01,or_greater"), "set_attenuation", "get_attenuation");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "spot_angle", PROPERTY_HINT_RANGE, "1.0,89.0,0.1"), "set_spot_angle", "get_spot_angle");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "spot_blend", PROPERTY_HINT_RANGE, "0.0,0.99,0.01"), "set_spot_blend", "get_spot_blend");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "fake_spot_light"), "set_fake_spot_light", "is_fake_spot_light");
}

void N64SpotLight3D::_notification(int p_what) {
	switch (p_what) {
		case Node::NOTIFICATION_ENTER_TREE:
		case Node::NOTIFICATION_PARENTED:
			_reconnect_manager();
			break;
		case Node::NOTIFICATION_EXIT_TREE:
		case Node::NOTIFICATION_UNPARENTED:
			if (manager != nullptr) {
				manager->unregister_spot_light(this);
				manager = nullptr;
			}
			break;
		case Node3D::NOTIFICATION_TRANSFORM_CHANGED:
			if (manager != nullptr) {
				manager->notify_light_changed();
			}
			update_gizmos();
			break;
		default:
			break;
	}
}

void N64SpotLight3D::set_enabled(bool p_enabled) {
	if (enabled == p_enabled) {
		return;
	}
	enabled = p_enabled;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

bool N64SpotLight3D::is_enabled() const {
	return enabled;
}

void N64SpotLight3D::set_color(const Color &p_color) {
	if (color == p_color) {
		return;
	}
	color = p_color;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

Color N64SpotLight3D::get_color() const {
	return color;
}

void N64SpotLight3D::set_energy(float p_energy) {
	if (Math::is_equal_approx(energy, p_energy)) {
		return;
	}
	energy = p_energy;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

float N64SpotLight3D::get_energy() const {
	return energy;
}

void N64SpotLight3D::set_range(float p_range) {
	const float clamped = MAX(p_range, 0.01f);
	if (Math::is_equal_approx(range, clamped)) {
		return;
	}
	range = clamped;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

float N64SpotLight3D::get_range() const {
	return range;
}

void N64SpotLight3D::set_attenuation(float p_attenuation) {
	const float clamped = MAX(p_attenuation, 0.01f);
	if (Math::is_equal_approx(attenuation, clamped)) {
		return;
	}
	attenuation = clamped;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

float N64SpotLight3D::get_attenuation() const {
	return attenuation;
}

void N64SpotLight3D::set_spot_angle(float p_spot_angle) {
	const float clamped = CLAMP(p_spot_angle, 1.0f, 89.0f);
	if (Math::is_equal_approx(spot_angle, clamped)) {
		return;
	}
	spot_angle = clamped;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

float N64SpotLight3D::get_spot_angle() const {
	return spot_angle;
}

void N64SpotLight3D::set_spot_blend(float p_spot_blend) {
	const float clamped = CLAMP(p_spot_blend, 0.0f, 0.99f);
	if (Math::is_equal_approx(spot_blend, clamped)) {
		return;
	}
	spot_blend = clamped;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

float N64SpotLight3D::get_spot_blend() const {
	return spot_blend;
}

void N64SpotLight3D::set_fake_spot_light(bool p_fake_spot_light) {
	if (fake_spot_light == p_fake_spot_light) {
		return;
	}
	fake_spot_light = p_fake_spot_light;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

bool N64SpotLight3D::is_fake_spot_light() const {
	return fake_spot_light;
}

Vector3 N64SpotLight3D::get_light_direction() const {
	return -get_global_transform().basis.get_column(2).normalized();
}

void N64SpotLight3D::_reconnect_manager() {
	N64VertexLightManager3D *new_manager = find_manager_ancestor(this);
	if (new_manager == manager) {
		return;
	}
	if (manager != nullptr) {
		manager->unregister_spot_light(this);
	}
	manager = new_manager;
	if (manager != nullptr) {
		manager->register_spot_light(this);
	}
}
