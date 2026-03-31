#!/usr/bin/env fish

set script_dir (cd (dirname (status --current-filename)); and pwd)
cd $script_dir

set package_root "$script_dir/packaged/RetroLightingSystem"
set source_addon "$script_dir/project/addons/rls_visuals_billboards"
set source_shaders "$script_dir/project/shaders"
set source_bin "$script_dir/project/bin"
set source_docs "$script_dir/docs"
set source_manual "$script_dir/RETRO_LIGHTING_SYSTEM_MANUAL.md"
set source_cpp "$script_dir/src"
set source_sconstruct "$script_dir/SConstruct"
set source_cmake "$script_dir/CMakeLists.txt"
set source_license "$script_dir/LICENSE.md"

mkdir -p \
    "$package_root/bin/linux" \
    "$package_root/bin/windows" \
    "$package_root/bin/web" \
    "$package_root/icons" \
    "$package_root/types" \
    "$package_root/shaders/shaderinclude" \
    "$package_root/shaders/post" \
    "$package_root/docs" \
    "$package_root/source/src"

function copy_if_exists
    set source_path $argv[1]
    set target_path $argv[2]
    if test -f "$source_path"
        cp "$source_path" "$target_path"
    end
end

# Copy addon assets.
cp "$source_addon/plugin.cfg" "$package_root/plugin.cfg"
cp "$source_addon/rls_light_gizmo_plugin.gd" "$package_root/rls_light_gizmo_plugin.gd"
cp "$source_addon/types/"*.gd "$package_root/types/"
copy_if_exists "$source_addon/icons/OmniLight3D.png" "$package_root/icons/OmniLight3D.png"
copy_if_exists "$source_addon/icons/DirectionalLight3D.png" "$package_root/icons/DirectionalLight3D.png"
copy_if_exists "$source_addon/icons/SpotLight3D.png" "$package_root/icons/SpotLight3D.png"
copy_if_exists "$source_addon/icons/WorldEnvironment.png" "$package_root/icons/WorldEnvironment.png"
copy_if_exists "$source_addon/icons/OmniLight3D.svg" "$package_root/icons/OmniLight3D.svg"
copy_if_exists "$source_addon/icons/DirectionalLight3D.svg" "$package_root/icons/DirectionalLight3D.svg"
copy_if_exists "$source_addon/icons/SpotLight3D.svg" "$package_root/icons/SpotLight3D.svg"
copy_if_exists "$source_addon/icons/WorldEnvironment.svg" "$package_root/icons/WorldEnvironment.svg"

# Copy the folder-agnostic addon entry script.
cp "$source_addon/plugin.gd" "$package_root/plugin.gd"

sed \
    -e 's#name="RLS Visuals Lights"#name="RetroLightingSystem"#g' \
    -e 's#description="Adds interactive gizmos for custom RLS light nodes."#description="Reusable retro vertex lighting nodes, shaders, and gizmos."#g' \
    "$source_addon/plugin.cfg" > "$package_root/plugin.cfg"

# Copy shaders and retarget includes into the fixed packaged addon path.
for shader_name in GenericVertexLit.gdshader GenericVertexLitBlend.gdshader Metallic.gdshader
    sed \
        's#res://shaders/shaderinclude/#res://addons/RetroLightingSystem/shaders/shaderinclude/#g' \
        "$source_shaders/$shader_name" > "$package_root/shaders/$shader_name"
end

cp "$source_shaders/shaderinclude/RDPcombiner.gdshaderinc" "$package_root/shaders/shaderinclude/RDPcombiner.gdshaderinc"
cp "$source_shaders/shaderinclude/vertexLightProcess.gdshaderinc" "$package_root/shaders/shaderinclude/vertexLightProcess.gdshaderinc"
copy_if_exists "$source_shaders/post/RDPpost.gdshader" "$package_root/shaders/post/RDPpost.gdshader"
copy_if_exists "$source_docs/lighting-authoring.md" "$package_root/docs/lighting-authoring.md"
copy_if_exists "$source_manual" "$package_root/docs/RETRO_LIGHTING_SYSTEM_MANUAL.md"
copy_if_exists "$source_sconstruct" "$package_root/source/SConstruct"
copy_if_exists "$source_cmake" "$package_root/source/CMakeLists.txt"
copy_if_exists "$source_license" "$package_root/source/LICENSE.md"
cp "$source_cpp/"*.cpp "$package_root/source/src/"
cp "$source_cpp/"*.h "$package_root/source/src/"

# Package only the binaries referenced by the packaged .gdextension.
copy_if_exists "$source_bin/linux/librlsvisuals.linux.template_debug.x86_64.so" "$package_root/bin/linux/librlsvisuals.linux.template_debug.x86_64.so"
copy_if_exists "$source_bin/linux/librlsvisuals.linux.template_release.x86_64.so" "$package_root/bin/linux/librlsvisuals.linux.template_release.x86_64.so"

copy_if_exists "$source_bin/windows/librlsvisuals.windows.template_debug.x86_64.dll" "$package_root/bin/windows/librlsvisuals.windows.template_debug.x86_64.dll"
copy_if_exists "$source_bin/windows/librlsvisuals.windows.template_release.x86_64.dll" "$package_root/bin/windows/librlsvisuals.windows.template_release.x86_64.dll"

copy_if_exists "$source_bin/web/librlsvisuals.web.template_debug.wasm32.nothreads.wasm" "$package_root/bin/web/librlsvisuals.web.template_debug.wasm32.nothreads.wasm"
copy_if_exists "$source_bin/web/librlsvisuals.web.template_release.wasm32.nothreads.wasm" "$package_root/bin/web/librlsvisuals.web.template_release.wasm32.nothreads.wasm"

# Generate a packaged .gdextension that points at the bundled binaries.
set gdextension_lines \
    '[configuration]' \
    '' \
    'entry_symbol = "rlsvisuals_library_init"' \
    'compatibility_minimum = "4.1"' \
    'reloadable = false' \
    '' \
    '[libraries]' \
    'linux.debug.x86_64 = "./bin/linux/librlsvisuals.linux.template_debug.x86_64.so"' \
    'linux.release.x86_64 = "./bin/linux/librlsvisuals.linux.template_release.x86_64.so"' \
    'windows.debug.x86_64 = "./bin/windows/librlsvisuals.windows.template_debug.x86_64.dll"' \
    'windows.release.x86_64 = "./bin/windows/librlsvisuals.windows.template_release.x86_64.dll"'

if test -f "$package_root/bin/web/librlsvisuals.web.template_debug.wasm32.nothreads.wasm"
    set gdextension_lines $gdextension_lines 'web.debug.wasm32 = "./bin/web/librlsvisuals.web.template_debug.wasm32.nothreads.wasm"'
end
if test -f "$package_root/bin/web/librlsvisuals.web.template_release.wasm32.nothreads.wasm"
    set gdextension_lines $gdextension_lines 'web.release.wasm32 = "./bin/web/librlsvisuals.web.template_release.wasm32.nothreads.wasm"'
end

printf '%s\n' $gdextension_lines > "$package_root/RetroLightingSystem.gdextension"

set readme_lines \
    '# RetroLightingSystem' \
    '' \
    'Reusable Godot addon package for the retro vertex lighting system.' \
    '' \
    '## Install' \
    '' \
    '1. Copy this `RetroLightingSystem` folder into your target project'"'"'s `addons/` directory.' \
    '2. Open the project in Godot.' \
    '3. Enable `RetroLightingSystem` in `Project Settings > Plugins`.' \
    '4. Use the bundled shaders from `res://addons/RetroLightingSystem/shaders/`.' \
    '' \
    '## Included' \
    '' \
    '- GDExtension runtime binaries for Linux, Windows, and Web' \
    '- Light node editor plugin, gizmos, and icons' \
    '- Reusable vertex lighting shaders and shader includes' \
    '- Original C++ GDExtension source in `source/src/` with build files in `source/`' \
    '- Documentation in `docs/RETRO_LIGHTING_SYSTEM_MANUAL.md` and `docs/lighting-authoring.md`' \
    '' \
    '## Notes' \
    '' \
    '- `ignore_fake_lights` remains a shader material uniform.' \
    '- `RLS_MAX_LIGHTS` can be overridden per shader before including `vertexLightProcess.gdshaderinc`.' \
    '- This package does not include dynamic shadows.' \

printf '%s\n' $readme_lines > "$package_root/README.md"

echo "Packaged addon refreshed at $package_root"
