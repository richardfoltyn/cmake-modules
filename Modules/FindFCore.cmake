# Findfcore.cmake
# Attempts to find local installation of Fortran corelib (fcore) library
# Usage:
#   find_package(FCore)
#
# Upon successful completion defines the following cached variables:
#   FCore_FOUND : TRUE if fcore fcore
#   FCore_INCLUDE_DIRS : include directories for compiled module files
#   FCore_LIBRARIES : fcore library paths

if (WIN32)
    set(HOME $ENV{USERPROFILE})
else ()
    set(HOME $ENV{HOME})
endif ()

include(FindTargetArch)

# Some common suffixes used with ifort
if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
    if (TARGET_ARCH_BITS EQUAL 32)
        set(_INTEL_SUFFIX ia32)
    else()
        set(_INTEL_SUFFIX intel64)
    endif()
endif()

set(FCORE_NAME FCore)
# sufficient to search for one mod file
set(FCORE_MODFILES corelib_string.mod)

string(TOLOWER "${FCORE_NAME}" _name)

find_library(${FCORE_NAME}_LIBRARY
    NAMES ${_name}
    PATHS
    ${FCORE_ROOT}
    ${HOME}
    ${HOME}/local
    ${HOME}/.local/
    /usr/local
    PATH_SUFFIXES
        lib/${_INTEL_SUFFIX}
        ${_INTEL_SUFFIX}
        lib${TARGET_ARCH_BITS}
        lib
        .
)

find_path(${FCORE_NAME}_INCLUDE_DIR NAMES ${FCORE_MODFILES}
    PATHS
    ${FCORE_ROOT}
    ${HOME}
    ${HOME}/local/*/include
    ${HOME}/local/include
    ${HOME}/.local/*/include
    ${HOME}/.local/include
    /usr/local/*/include
    /usr/local/include
    PATH_SUFFIXES
        ${_INTEL_SUFFIX}/${_name}
        ${_name}
        .
)

find_package_handle_standard_args(${FCORE_NAME} DEFAULT_MSG
    ${FCORE_NAME}_LIBRARY
    ${FCORE_NAME}_INCLUDE_DIR
)

set(${FCORE_NAME}_LIBRARIES ${${FCORE_NAME}_LIBRARY})
set(${FCORE_NAME}_INCLUDE_DIRS ${${FCORE_NAME}_INCLUDE_DIR})
