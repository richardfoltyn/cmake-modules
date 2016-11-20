# Findfcore.cmake
# Attempts to find local installation of Fortran corelib (fcorelib) library
# Usage:
#   find_package(FCorelib)
#
# Upon successful completion defines the following cached variables:
#   FCorelib_FOUND : TRUE if fcore fcore
#   FCorelib_INCLUDE_DIRS : include directories for compiled module files
#   FCorelib_LIBRARIES : fcore library paths

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

set(FCORELIB_NAME FCorelib)
# sufficient to search for one mod file
set(FCORELIB_MODFILES corelib_version_mod.mod)

string(TOLOWER "${FCORELIB_NAME}" _name)

find_library(${FCORELIB_NAME}_LIBRARY
    NAMES ${_name}
    PATHS
    ${FCORELIB_ROOT}
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

find_path(${FCORELIB_NAME}_INCLUDE_DIR NAMES ${FCORELIB_MODFILES}
    PATHS
    ${FCORELIB_ROOT}
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

find_package_handle_standard_args(${FCORELIB_NAME} DEFAULT_MSG
    ${FCORELIB_NAME}_LIBRARY
    ${FCORELIB_NAME}_INCLUDE_DIR
)

set(${FCORELIB_NAME}_LIBRARIES ${${FCORELIB_NAME}_LIBRARY})
set(${FCORELIB_NAME}_INCLUDE_DIRS ${${FCORELIB_NAME}_INCLUDE_DIR})
