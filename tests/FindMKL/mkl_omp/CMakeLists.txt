
get_filename_component(_dir "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
message("=== Processing directory ${_dir} ===")

find_package(OpenMP)
find_package(MKL COMPONENTS OpenMP)

message(STATUS "MKL_FOUND: ${MKL_FOUND}")
message(STATUS "MKL_ROOT: ${MKL_ROOT}")
message(STATUS "MKL_OPENMP_FOUND: ${MKL_OPENMP_FOUND}")
message(STATUS "MKL_LIBRARIES: ${MKL_LIBRARIES}")
if (MKL_INCLUDE_DIRS)
  message(STATUS "MKL_INCLUDE_DIRS: ${MKL_INCLUDE_DIRS}")
endif()

set(SOURCE_FILES mkltest_omp.f90)

set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenMP_Fortran_FLAGS}")
include_directories(${MKL_INCLUDE_DIRS})

set(_target ${_dir})
add_executable(${_target} ${SOURCE_FILES})
target_link_libraries(${_target} ${MKL_LIBRARIES})

add_test(NAME ${_target}_test COMMAND ${_target})
