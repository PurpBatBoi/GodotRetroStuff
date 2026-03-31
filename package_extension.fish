#!/usr/bin/env fish

set script_dir (cd (dirname (status --current-filename)); and pwd)
cd $script_dir

set package_root "$script_dir/packaged/n64_vertex_lighting"
set source_addon "$script_dir/project/addons/n64_visuals_billboards"
set source_shaders "$script_dir/project/shaders"
set source_bin "$script_dir/project/bin"
set source_docs "$script_dir/docs"

mkdir -p \
    "$package_root/bin/linux" \
    "$package_root/bin/windows" \
    "$package_root/bin/web" \
    "$package_root/icons" \
    "$package_root/types" \
    "$package_root/shaders/shaderinclude" \
    "$package_root/shaders/post" \
    "$package_root/docs"

function copy_if_exists
    set source_path $argv[1]
    set target_path $argv[2]
    if test -f "$source_path"
        cp "$source_path" "$target_path"
    end
end

# Copy addon assets.
cp "$source_addon/plugin.cfg" "$package_root/plugin.cfg"
cp "$source_addon/n64_light_gizmo_plugin.gd" "$package_root/n64_light_gizmo_plugin.gd"
cp "$source_addon/types/"*.gd "$package_root/types/"
copy_if_exists "$source_addon/icons/OmniLight3D.png" "$package_root/icons/OmniLight3D.png"
copy_if_exists "$source_addon/icons/DirectionalLight3D.png" "$package_root/icons/DirectionalLight3D.png"
copy_if_exists "$source_addon/icons/SpotLight3D.png" "$package_root/icons/SpotLight3D.png"
copy_if_exists "$source_addon/icons/WorldEnvironment.png" "$package_root/icons/WorldEnvironment.png"
copy_if_exists "$source_addon/icons/OmniLight3D.svg" "$package_root/icons/OmniLight3D.svg"
copy_if_exists "$source_addon/icons/DirectionalLight3D.svg" "$package_root/icons/DirectionalLight3D.svg"
copy_if_exists "$source_addon/icons/SpotLight3D.svg" "$package_root/icons/SpotLight3D.svg"
copy_if_exists "$source_addon/icons/WorldEnvironment.svg" "$package_root/icons/WorldEnvironment.svg"

# Rewrite plugin paths so the packaged addon can be dropped directly into addons/.
sed \
    's#res://addons/n64_visuals_billboards/#res://addons/n64_vertex_lighting/#g' \
    "$source_addon/plugin.gd" > "$package_root/plugin.gd"

sed \
    -e 's#name="N64 Visuals Lights"#name="N64 Vertex Lighting"#g' \
    -e 's#description="Adds interactive gizmos for custom N64 light nodes."#description="Reusable N64-style vertex lighting nodes, shaders, and gizmos."#g' \
    "$source_addon/plugin.cfg" > "$package_root/plugin.cfg"

# Copy shaders and retarget their include paths into the packaged addon.
for shader_name in GenericVertexLit.gdshader GenericVertexLitBlend.gdshader Metallic.gdshader
    sed \
        's#res://shaders/shaderinclude/#res://addons/n64_vertex_lighting/shaders/shaderinclude/#g' \
        "$source_shaders/$shader_name" > "$package_root/shaders/$shader_name"
end

cp "$source_shaders/shaderinclude/RDPcombiner.gdshaderinc" "$package_root/shaders/shaderinclude/RDPcombiner.gdshaderinc"
cp "$source_shaders/shaderinclude/vertexLightProcess.gdshaderinc" "$package_root/shaders/shaderinclude/vertexLightProcess.gdshaderinc"
copy_if_exists "$source_shaders/post/RDPpost.gdshader" "$package_root/shaders/post/RDPpost.gdshader"
copy_if_exists "$source_docs/lighting-authoring.md" "$package_root/docs/lighting-authoring.md"

# Package the binaries that are currently available.
for binary in "$source_bin/linux/"*.so
    if test -f "$binary"
        cp "$binary" "$package_root/bin/linux/"
    end
end

for binary in "$source_bin/windows/"*.dll
    if test -f "$binary"
        cp "$binary" "$package_root/bin/windows/"
    end
end

for binary in "$source_bin/web/"*.wasm
    if test -f "$binary"
        cp "$binary" "$package_root/bin/web/"
    end
end

# Generate a packaged .gdextension that points at the bundled binaries.
set gdextension_lines \
    '[configuration]' \
    '' \
    'entry_symbol = "n64visuals_library_init"' \
    'compatibility_minimum = "4.1"' \
    'reloadable = false' \
    '' \
    '[libraries]' \
    'linux.x86_64.single.debug = "./bin/linux/libn64visuals.linux.template_debug.x86_64.so"' \
    'linux.x86_64.single.release = "./bin/linux/libn64visuals.linux.template_release.x86_64.so"' \
    'windows.x86_64.single.debug = "./bin/windows/libn64visuals.windows.template_debug.x86_64.dll"' \
    'windows.x86_64.single.release = "./bin/windows/libn64visuals.windows.template_release.x86_64.dll"' \
    'web.wasm32.single.debug = "./bin/web/libn64visuals.web.template_debug.wasm32.wasm"' \
    'web.wasm32.single.release = "./bin/web/libn64visuals.web.template_release.wasm32.wasm"'

if test -f "$package_root/bin/web/libn64visuals.web.template_release.wasm32.nothreads.wasm"
    set gdextension_lines $gdextension_lines 'web.wasm32.nothreads.single.release = "./bin/web/libn64visuals.web.template_release.wasm32.nothreads.wasm"'
end

printf '%s\n' $gdextension_lines > "$package_root/n64visuals.gdextension"

set readme_lines \
    '# N64 Vertex Lighting' \
    '' \
    'Reusable Godot addon package for the custom N64-style vertex lighting system.' \
    '' \
    '## Install' \
    '' \
    '1. Copy this `n64_vertex_lighting` folder into your target project'"'"'s `addons/` directory.' \
    '2. Open the project in Godot.' \
    '3. Enable `N64 Vertex Lighting` in `Project Settings > Plugins`.' \
    '4. Use the bundled shaders from `res://addons/n64_vertex_lighting/shaders/`.' \
    '' \
    '## Included' \
    '' \
    '- GDExtension runtime binaries for Linux, Windows, and Web' \
    '- Light node editor plugin, gizmos, and icons' \
    '- Reusable vertex lighting shaders and shader includes' \
    '- Lighting authoring notes in `docs/lighting-authoring.md`' \
    '' \
    '## Notes' \
    '' \
    '- `ignore_fake_point_lights` remains a shader material uniform.' \
    '- `N64_MAX_LIGHTS` can be overridden per shader before including `vertexLightProcess.gdshaderinc`.' \
    '- This package does not include dynamic shadows.' \

printf '%s\n' $readme_lines > "$package_root/README.md"

echo "Packaged addon refreshed at $package_root"
