CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

project(test C Fortran)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../Modules")

enable_testing()

add_subdirectory(mkl_rt)
add_subdirectory(mkl_sequential_lp64)
add_subdirectory(mkl_static)
add_subdirectory(mkl_dynamic)
add_subdirectory(mkl_f95)
add_subdirectory(mkl_omp)
