#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/classes/editor_plugin_registration.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "rls_editor_plugin.h"
#include "rls_directional_light_3d.h"
#include "rls_light_gizmo_plugin.h"
#include "rls_lit_mesh_instance_3d.h"
#include "rls_point_light_3d.h"
#include "rls_spot_light_3d.h"
#include "rls_vertex_light_manager_3d.h"

using namespace godot;

void initialize_gdextension_types(ModuleInitializationLevel p_level)
{
	if (p_level == MODULE_INITIALIZATION_LEVEL_SCENE) {
		GDREGISTER_CLASS(RLS_VertexLightManager3D);
		GDREGISTER_CLASS(RLS_PointLight3D);
		GDREGISTER_CLASS(RLS_DirectionalLight3D);
		GDREGISTER_CLASS(RLS_SpotLight3D);
		GDREGISTER_CLASS(RLS_LitMeshInstance3D);
		return;
	}

	if (p_level == MODULE_INITIALIZATION_LEVEL_EDITOR) {
		GDREGISTER_CLASS(RLSLightGizmoPlugin);
		GDREGISTER_CLASS(RLSEditorPlugin);
	}
}

void uninitialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level == MODULE_INITIALIZATION_LEVEL_EDITOR) {
	}
}

extern "C"
{
	static GDExtensionBool initialize_rlsvisuals_library(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization)
	{
		GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
		init_obj.register_initializer(initialize_gdextension_types);
		init_obj.register_terminator(uninitialize_gdextension_types);
		// init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

		return init_obj.init();
	}

	GDExtensionBool GDE_EXPORT rlsvisuals_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization)
	{
		return initialize_rlsvisuals_library(p_get_proc_address, p_library, r_initialization);
	}
}
