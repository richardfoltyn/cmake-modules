CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

project(test_kinds Fortran)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../Modules")

include(CheckFortranKinds)

check_Fortran_kinds()
message("Default int kind: ${Fortran_DEFAULT_INT_KIND}")
message("Default REAL kind: ${Fortran_DEFAULT_REAL_KIND}")
