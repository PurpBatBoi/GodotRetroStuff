#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/classes/editor_plugin_registration.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "example_class.h"
#include "n64_editor_plugin.h"
#include "n64_directional_light_3d.h"
#include "n64_light_gizmo_plugin.h"
#include "n64_lit_mesh_instance_3d.h"
#include "n64_point_light_3d.h"
#include "n64_vertex_light_manager_3d.h"

using namespace godot;

void initialize_gdextension_types(ModuleInitializationLevel p_level)
{
	if (p_level == MODULE_INITIALIZATION_LEVEL_SCENE) {
		GDREGISTER_CLASS(ExampleClass);
		GDREGISTER_CLASS(N64VertexLightManager3D);
		GDREGISTER_CLASS(N64PointLight3D);
		GDREGISTER_CLASS(N64DirectionalLight3D);
		GDREGISTER_CLASS(N64LitMeshInstance3D);
		return;
	}

	if (p_level == MODULE_INITIALIZATION_LEVEL_EDITOR) {
		GDREGISTER_CLASS(N64LightGizmoPlugin);
		GDREGISTER_CLASS(N64EditorPlugin);
		EditorPlugins::add_by_type<N64EditorPlugin>();
	}
}

void uninitialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level == MODULE_INITIALIZATION_LEVEL_EDITOR) {
		EditorPlugins::remove_by_type<N64EditorPlugin>();
	}
}

extern "C"
{
	// Initialization
	GDExtensionBool GDE_EXPORT n64visuals_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization)
	{
		GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
		init_obj.register_initializer(initialize_gdextension_types);
		init_obj.register_terminator(uninitialize_gdextension_types);
		init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

		return init_obj.init();
	}
}
