#!/usr/bin/env fish

set script_dir (cd (dirname (status --current-filename)); and pwd)
cd $script_dir

if not test -f .venv/bin/activate.fish
    echo "Missing .venv/bin/activate.fish"
    exit 1
end

source .venv/bin/activate.fish

if not type -q scons
    echo "scons not found after activating .venv"
    exit 1
end

set jobs (nproc)
set web_jobs $jobs

if test $web_jobs -gt 4
    set web_jobs 4
end

function run_web_build --argument-names target web_jobs
    echo "Building Web $target..."
    scons platform=web target=$target threads=false -j$web_jobs
    or begin
        echo "Web $target failed on the first attempt; retrying once with -j1..."
        scons platform=web target=$target threads=false -j1
    end
end

# Linux builds
for target in template_debug template_release
    echo "Building Linux $target..."
    scons platform=linux target=$target -j$jobs
    or exit $status
end

echo "Linux builds completed."

# Windows builds
if not type -q x86_64-w64-mingw32-g++
    echo "Missing x86_64-w64-mingw32-g++ for Windows builds"
    exit 1
end

for target in template_debug template_release
    echo "Building Windows $target..."
    scons platform=windows target=$target arch=x86_64 -j$jobs
    or exit $status
end

echo "Windows builds completed."

# Web builds (must keep Emscripten stdlib symbols available for side modules)
set -x EMCC_FORCE_STDLIBS 1
set -x EMCC_FORCE_STDLIBS_ALWAYS 1

for target in template_debug template_release
    run_web_build $target $web_jobs
    or exit $status
end

echo "Web builds completed."

echo "Refreshing packaged addon..."
fish ./package_extension.fish
or exit $status

echo "Packaged addon ready."
