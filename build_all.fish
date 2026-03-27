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

echo "Building Linux template_debug..."
scons platform=linux target=template_debug -j$jobs
or exit $status

echo "Building Linux template_release..."
scons platform=linux target=template_release -j$jobs
or exit $status

echo "All Linux builds completed."
