CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

project(test_pdt Fortran)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../Modules")

include(CheckFortranPDT)

check_Fortran_PDT()
