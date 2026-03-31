#include "n64_directional_light_3d.h"

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

N64DirectionalLight3D::N64DirectionalLight3D() {
	set_notify_transform(true);
}

void N64DirectionalLight3D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_enabled", "enabled"), &N64DirectionalLight3D::set_enabled);
	ClassDB::bind_method(D_METHOD("is_enabled"), &N64DirectionalLight3D::is_enabled);
	ClassDB::bind_method(D_METHOD("set_color", "color"), &N64DirectionalLight3D::set_color);
	ClassDB::bind_method(D_METHOD("get_color"), &N64DirectionalLight3D::get_color);
	ClassDB::bind_method(D_METHOD("set_energy", "energy"), &N64DirectionalLight3D::set_energy);
	ClassDB::bind_method(D_METHOD("get_energy"), &N64DirectionalLight3D::get_energy);

	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "enabled"), "set_enabled", "is_enabled");
	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "color"), "set_color", "get_color");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "energy", PROPERTY_HINT_RANGE, "0.0,16.0,0.01,or_greater"), "set_energy", "get_energy");
}

void N64DirectionalLight3D::_notification(int p_what) {
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
				manager->unregister_directional_light(this);
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

void N64DirectionalLight3D::set_enabled(bool p_enabled) {
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

bool N64DirectionalLight3D::is_enabled() const {
	return enabled;
}

void N64DirectionalLight3D::set_color(const Color &p_color) {
	if (color == p_color) {
		return;
	}
	color = p_color;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

Color N64DirectionalLight3D::get_color() const {
	return color;
}

void N64DirectionalLight3D::set_energy(float p_energy) {
	if (Math::is_equal_approx(energy, p_energy)) {
		return;
	}
	energy = p_energy;
	if (manager != nullptr) {
		manager->notify_light_changed();
	}
	update_gizmos();
}

float N64DirectionalLight3D::get_energy() const {
	return energy;
}

Vector3 N64DirectionalLight3D::get_light_direction() const {
	return -get_global_transform().basis.get_column(2).normalized();
}

void N64DirectionalLight3D::_reconnect_manager() {
	N64VertexLightManager3D *new_manager = find_manager_ancestor(this);
	if (new_manager == manager) {
		return;
	}
	if (manager != nullptr) {
		manager->unregister_directional_light(this);
	}
	manager = new_manager;
	if (manager != nullptr) {
		manager->register_directional_light(this);
	}
}
