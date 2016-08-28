CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

project(test Fortran)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../Modules")

# set(MKL_THREADING Sequential)
# set(MKL_INTERFACE LP64)
set(MKL_RT FALSE)

find_package(MKL)

message("MKL_FOUND: ${MKL_FOUND}")
message("MKL_ROOT: ${MKL_ROOT}")
message("MKL_LIBRARIES: ${MKL_LIBRARIES}")
if (MKL_INCLUDE_DIRS)
  message("MKL_INCLUDE_DIRS: ${MKL_INCLUDE_DIRS}")
endif()

set(SOURCE_FILES mkltest.f90)

include_directories(${MKL_INCLUDE_DIRS})
add_executable(test1 ${SOURCE_FILES})
target_link_libraries(test1 ${MKL_LIBRARIES})

find_package(MKL COMPONENTS BLAS95)

set(SOURCE_FILES mkltest95.f90)

include_directories(${MKL_INCLUDE_DIRS})
add_executable(test95 ${SOURCE_FILES})
target_link_libraries(test95 ${MKL_LIBRARIES})
