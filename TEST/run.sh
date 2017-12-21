#!/bin/sh
set -x
../inclean --use_file_content --or_upper_case_file_name --include "*.hpp" --include "INCLUDE_FOLDER/!/*.hpp" --comment "// -- IMPORTS" --partial --missing --unused --sort --verbose --print --preview "*.hpp" "*.cpp"
../inclean --sort --verbose --print --preview ".//*.hpp" ".//*.cpp"

