CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

project(test_kinds Fortran)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../Modules")

include(CheckFortranSupportedKinds)

check_Fortran_supported_kinds()
