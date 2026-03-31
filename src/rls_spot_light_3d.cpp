#include "rls_spot_light_3d.h"

#include "rls_vertex_light_manager_3d.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/core/object.hpp>

using namespace godot;

namespace {

RLS_VertexLightManager3D *find_manager_ancestor(Node *p_node) {
	Node *current = p_node == nullptr ? nullptr : p_node->get_parent();
	while (current != nullptr) {
		if (RLS_VertexLightManager3D *manager = Object::cast_to<RLS_VertexLightManager3D>(current)) {
			return manager;
		}
		current = current->get_parent();
	}
	return nullptr;
}

} // namespace

RLS_SpotLight3D::RLS_SpotLight3D() {
	set_notify_transform(true);
}

void RLS_SpotLight3D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_enabled", "enabled"), &RLS_SpotLight3D::set_enabled);
	ClassDB::bind_method(D_METHOD("is_enabled"), &RLS_SpotLight3D::is_enabled);
	ClassDB::bind_method(D_METHOD("set_color", "color"), &RLS_SpotLight3D::set_color);
	ClassDB::bind_method(D_METHOD("get_color"), &RLS_SpotLight3D::get_color);
	ClassDB::bind_method(D_METHOD("set_energy", "energy"), &RLS_SpotLight3D::set_energy);
	ClassDB::bind_method(D_METHOD("get_energy"), &RLS_SpotLight3D::get_energy);
	ClassDB::bind_method(D_METHOD("set_range", "range"), &RLS_SpotLight3D::set_range);
	ClassDB::bind_method(D_METHOD("get_range"), &RLS_SpotLight3D::get_range);
	ClassDB::bind_method(D_METHOD("set_attenuation", "attenuation"), &RLS_SpotLight3D::set_attenuation);
	ClassDB::bind_method(D_METHOD("get_attenuation"), &RLS_SpotLight3D::get_attenuation);
	ClassDB::bind_method(D_METHOD("set_distance_fade_enabled", "enabled"), &RLS_SpotLight3D::set_distance_fade_enabled);
	ClassDB::bind_method(D_METHOD("is_distance_fade_enabled"), &RLS_SpotLight3D::is_distance_fade_enabled);
	ClassDB::bind_method(D_METHOD("set_distance_fade_begin", "distance"), &RLS_SpotLight3D::set_distance_fade_begin);
	ClassDB::bind_method(D_METHOD("get_distance_fade_begin"), &RLS_SpotLight3D::get_distance_fade_begin);
	ClassDB::bind_method(D_METHOD("set_distance_fade_length", "distance"), &RLS_SpotLight3D::set_distance_fade_length);
	ClassDB::bind_method(D_METHOD("get_distance_fade_length"), &RLS_SpotLight3D::get_distance_fade_length);
	ClassDB::bind_method(D_METHOD("set_spot_angle", "spot_angle"), &RLS_SpotLight3D::set_spot_angle);
	ClassDB::bind_method(D_METHOD("get_spot_angle"), &RLS_SpotLight3D::get_spot_angle);
	ClassDB::bind_method(D_METHOD("set_spot_blend", "spot_blend"), &RLS_SpotLight3D::set_spot_blend);
	ClassDB::bind_method(D_METHOD("get_spot_blend"), &RLS_SpotLight3D::get_spot_blend);
	ClassDB::bind_method(D_METHOD("set_fake_spot_light", "fake_spot_light"), &RLS_SpotLight3D::set_fake_spot_light);
	ClassDB::bind_method(D_METHOD("is_fake_spot_light"), &RLS_SpotLight3D::is_fake_spot_light);

	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "enabled"), "set_enabled", "is_enabled");
	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "color"), "set_color", "get_color");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "energy", PROPERTY_HINT_RANGE, "0.0,16.0,0.01,or_greater"), "set_energy", "get_energy");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "range", PROPERTY_HINT_RANGE, "0.01,256.0,0.01,or_greater"), "set_range", "get_range");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "attenuation", PROPERTY_HINT_RANGE, "0.01,8.0,0.01,or_greater"), "set_attenuation", "get_attenuation");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "distance_fade_enabled"), "set_distance_fade_enabled", "is_distance_fade_enabled");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "distance_fade_begin", PROPERTY_HINT_RANGE, "0.0,4096.0,0.01,or_greater"), "set_distance_fade_begin", "get_distance_fade_begin");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "distance_fade_length", PROPERTY_HINT_RANGE, "0.01,4096.0,0.01,or_greater"), "set_distance_fade_length", "get_distance_fade_length");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "spot_angle", PROPERTY_HINT_RANGE, "1.0,89.0,0.1"), "set_spot_angle", "get_spot_angle");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "spot_blend", PROPERTY_HINT_RANGE, "0.0,0.99,0.01"), "set_spot_blend", "get_spot_blend");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "fake_spot_light"), "set_fake_spot_light", "is_fake_spot_light");
}

void RLS_SpotLight3D::_notification(int p_what) {
	switch (p_what) {
		case Node::NOTIFICATION_ENTER_TREE:
		case Node::NOTIFICATION_PARENTED:
			_reconnect_manager();
			if (enabled != is_visible()) {
				enabled = is_visible();
				if (manager != nullptr) {
					manager->notify_light_changed();
				}
			}
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
		case Node3D::NOTIFICATION_VISIBILITY_CHANGED:
			if (!syncing_visibility && enabled != is_visible()) {
				enabled = is_visible();
				if (manager != nullptr) {
					manager->notify_light_changed();
				}
			}
			update_gizmos();
			break;
		default:
			break;
	}
}

void RLS_SpotLight3D::set_enabled(bool p_enabled) {
	if (enabled == p_enabled) {
		return;
	}
	enabled = p_enabled;
	if (is_visible() != p_enabled) {
		syncing_visibility = true;
		set_visible(p_enabled);
		syncing_visibility = false;
	}
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

bool RLS_SpotLight3D::is_enabled() const {
	return enabled;
}

void RLS_SpotLight3D::set_color(const Color &p_color) {
	if (color == p_color) {
		return;
	}
	color = p_color;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

Color RLS_SpotLight3D::get_color() const {
	return color;
}

void RLS_SpotLight3D::set_energy(float p_energy) {
	if (Math::is_equal_approx(energy, p_energy)) {
		return;
	}
	energy = p_energy;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

float RLS_SpotLight3D::get_energy() const {
	return energy;
}

void RLS_SpotLight3D::set_range(float p_range) {
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

float RLS_SpotLight3D::get_range() const {
	return range;
}

void RLS_SpotLight3D::set_attenuation(float p_attenuation) {
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

float RLS_SpotLight3D::get_attenuation() const {
	return attenuation;
}

void RLS_SpotLight3D::set_distance_fade_enabled(bool p_enabled) {
	if (distance_fade_enabled == p_enabled) {
		return;
	}
	distance_fade_enabled = p_enabled;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

bool RLS_SpotLight3D::is_distance_fade_enabled() const {
	return distance_fade_enabled;
}

void RLS_SpotLight3D::set_distance_fade_begin(float p_distance) {
	const float clamped = MAX(p_distance, 0.0f);
	if (Math::is_equal_approx(distance_fade_begin, clamped)) {
		return;
	}
	distance_fade_begin = clamped;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

float RLS_SpotLight3D::get_distance_fade_begin() const {
	return distance_fade_begin;
}

void RLS_SpotLight3D::set_distance_fade_length(float p_distance) {
	const float clamped = MAX(p_distance, 0.01f);
	if (Math::is_equal_approx(distance_fade_length, clamped)) {
		return;
	}
	distance_fade_length = clamped;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

float RLS_SpotLight3D::get_distance_fade_length() const {
	return distance_fade_length;
}

void RLS_SpotLight3D::set_spot_angle(float p_spot_angle) {
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

float RLS_SpotLight3D::get_spot_angle() const {
	return spot_angle;
}

void RLS_SpotLight3D::set_spot_blend(float p_spot_blend) {
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

float RLS_SpotLight3D::get_spot_blend() const {
	return spot_blend;
}

void RLS_SpotLight3D::set_fake_spot_light(bool p_fake_spot_light) {
	if (fake_spot_light == p_fake_spot_light) {
		return;
	}
	fake_spot_light = p_fake_spot_light;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

bool RLS_SpotLight3D::is_fake_spot_light() const {
	return fake_spot_light;
}

Vector3 RLS_SpotLight3D::get_light_direction() const {
	return -get_global_transform().basis.get_column(2).normalized();
}

void RLS_SpotLight3D::_reconnect_manager() {
	RLS_VertexLightManager3D *new_manager = find_manager_ancestor(this);
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
