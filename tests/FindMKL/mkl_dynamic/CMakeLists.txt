# Test FindMKL with sequential threading and LP64 interface
# using static linking.
# This particularly makes a difference on Linux

get_filename_component(_dir "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
message("=== Processing directory ${_dir} ===")

set(MKL_STATIC FALSE)
find_package(MKL REQUIRED COMPONENTS SEQUENTIAL LP64)

message(STATUS "MKL_FOUND: ${MKL_FOUND}")
message(STATUS "MKL_ROOT: ${MKL_ROOT}")
message(STATUS "MKL_SEQUENTIAL_FOUND: ${MKL_SEQUENTIAL_FOUND}")
message(STATUS "MKL_LP64_FOUND: ${MKL_LP64_FOUND}")
message(STATUS "MKL_LIBRARIES: ${MKL_LIBRARIES}")
if (MKL_INCLUDE_DIRS)
  message("MKL_INCLUDE_DIRS: ${MKL_INCLUDE_DIRS}")
endif()

set(SOURCE_FILES ../mkltest.f90)

set(_target ${_dir})
include_directories(${MKL_INCLUDE_DIRS})
add_executable(${_target} ${SOURCE_FILES})
target_link_libraries(${_target} ${MKL_LIBRARIES})

add_test(NAME ${_target}_test COMMAND ${_target})
