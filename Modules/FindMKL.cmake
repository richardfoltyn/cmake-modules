#.rst
# FindMKL
# -------
#
# This module defines
#  MKL_LIBRARIES, the libraries needed to use Intel's implementation of BLAS & LAPACK.
#  MKL_FOUND, If false, do not try to use MKL.

## the link below explains why we're linking only with mkl_rt
## https://software.intel.com/en-us/articles/a-new-linking-model-single-dynamic-library-mkl_rt-since-intel-mkl-103

# Variables controlling FindMKL behavior:
#
#   MKL_RT:BOOL             Controls whether to return the "runtime"-version of MKL
#
#   MKL_INTERFACE:STRING    Either LP64 or IPL64; only applicable for 64-bit
#                           builds if MKL_RT=OFF
#
#   MKL_THREADING:STRING    Threading model used. Valid values are
#                           OpenMP, Sequential and TBB; only applicable if
#                           MKL_RT=OFF
#
#   MKL_STATIC:BOOL         If ON, link against static MKL libraries
#
#   MKL_F95ROOT:STRING      Optional root directory where to look for
#                           Fortran 95 components (not needed on Windows)
#
# COMPONENTS (optional):
#   BLAS95                  Fortran 95 interface to BLAS library
#   LAPACK95                Fortran 95 interface to LAPACK library
# Note that components other than BLAS95 and LAPACK95 on Windows are not
# shipped as pre-compiled libraries with MKL. Thus, they will not be found
# unless MKL_F95ROOT points to the base directory where user-compiled version
# of these libraries are located.


# if none of the MKL_* variables are defined, assume MKL_RT=ON by default
if (NOT DEFINED MKL_RT AND NOT DEFINED MKL_INTERFACE AND NOT DEFINED MKL_THREADING)
  set(MKL_RT TRUE)
endif()

# determine target architecture
include(FindTargetArch)
if (TARGET_ARCH_BITS EQUAL 64)
  set(MKL_ARCH intel64)
else()
  set(MKL_ARCH ia32)
endif()

# Add file extensions for static linking
if (MKL_STATIC)
  if (WIN32)
    set(CMAKE_FIND_LIBRARY_SUFFIXES .lib ${CMAKE_FIND_LIBRARY_SUFFIXES})
  elseif (APPLE)
    set(CMAKE_FIND_LIBRARY_SUFFIXES .lib ${CMAKE_FIND_LIBRARY_SUFFIXES})
  else ()
    set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
  endif ()
endif()

# If MKLROOT environment variable is defined, use it in find_* functions
set(MKL_ROOT_ENV "$ENV{MKLROOT}")
if (MKL_ROOT_ENV)
    set(MKL_ROOT "${MKL_ROOT_ENV}")
else ()
    # set it to some dummy value so we don't get syntax errors in find_* functions
    set(MKL_ROOT_ENV "/opt/intel/mkl")
endif()

# hard-coded directories to be searched
set(_MKL_PATHS
  /usr/local/mkl
  /usr/local/intel/mkl
  /opt/intel/composerxe
  /usr/local/*/mkl
  /usr/local/intel/*/mkl
  /usr/local/*/composerxe
  /opt/intel/*/mkl
)

function(name_interface NAME _stub _arch _interface)
  # Function to conditionally append MKL-interface-specific suffix to _stub
  # Result is store in variable NAME evaluated in parent scope.
  # Arguments _arch and _interface contain the values of the target architecture
  # (ia32, intel64) and MKL interface (LP64, ILP64)
  if (${ARGC} LESS 3)
    set(_interface "")
  endif()

  if (_arch STREQUAL "intel64")
    if (_interface STREQUAL "LP64")
      set(_name ${_stub}_lp64)
    else()
      set(_name ${_stub}_ilp64)
    endif()
  else()
    set(_name ${_stub})
  endif()
  set(${NAME} ${_name} PARENT_SCOPE)
endfunction()

# default interface: LP64 (only relevant for intel64 architecture)
string(TOUPPER "${MKL_INTERFACE}" _INTERFACE)
if (NOT _INTERFACE)
  set(_INTERFACE LP64)
endif()

set(MKL_LIBRARIES)
set(MKL_INCLUDE_DIRS)

if (MKL_RT)
  set(_NAMES mkl_rt)
  find_library(MKL_RT_LIBRARY
    NAMES ${_NAMES}
    HINTS ${MKL_ROOT_ENV} ${MKL_F95ROOT}
    PATHS ${_MKL_PATHS}
    PATH_SUFFIXES lib/${MKL_ARCH} lib .
  )

  if (MKL_RT_LIBRARY)
    list(APPEND MKL_LIBRARIES "${MKL_RT_LIBRARY}")
  endif()
else (MKL_RT)
  # No SDL interface requested, need specify interface/threading/core libraries
  # explicitly

  string(TOUPPER "${MKL_THREADING}" _THREADING)
  if (NOT _THREADING)
    set(_THREADING SEQUENTIAL)
  endif()

  # MKL interface library
  if (TARGET_ARCH_BITS EQUAL 32)
    if (WIN32)
      set(_INTERFACE_NAMES mkl_intel_c)
    else()
      set(_INTERFACE_NAMES mkl_intel)
    endif()
  else()
    name_interface(_INTERFACE_NAMES mkl_intel ${MKL_ARCH} ${_INTERFACE})
  endif()

  # MKL core
  set(_CORE_NAMES mkl_core)

  # MKL threading library
  if (_THREADING STREQUAL "SEQUENTIAL")
    set(_THREADING_NAMES mkl_sequential)
  elseif (_THREADING STREQUAL "OPENMP")
    set(_THREADING_NAMES mkl_intel_thread)
  elseif (_THREADING STREQUAL "TBB")
    set(_THREADING_NAMES mkl_tbb_thread)
  endif()

  # On Windows, add _dll suffix if using static linking
  if (WIN32 AND NOT MKL_STATIC)
    foreach (_type INTERFACE CORE THREADING)
      set(_TMP)
      foreach(_name ${_${_type}_NAMES})
        set(_TMP ${_TMP} ${_name}_dll)
      endforeach()
      set(_${_type}_NAMES ${_TMP})
    endforeach()
  endif()

  foreach(_type INTERFACE CORE THREADING)
    find_library(MKL_${_type}_LIBRARY
      NAMES ${_${_type}_NAMES}
      HINTS ${MKL_ROOT_ENV}  ${MKL_F95ROOT}
      PATHS ${_MKL_PATHS}
      PATH_SUFFIXES lib/${MKL_ARCH} lib .
    )

    list(APPEND MKL_LIBRARIES "${MKL_${_type}_LIBRARY}")
  endforeach()

  # append tbb library if TBB threading model requested
  if (MKL_THREADING STREQUAL "TBB")
    find_library(MKL_TBB_LIBRARY
      NAMES tbb
      HINTS ${MKL_ROOT_ENV}
      PATHS ${_MKL_PATHS}
      PATH_SUFFIXES lib/${MKL_ARCH}
    )

    list(APPEND MKL_LIBRARIES "${MKL_TBB_LIBRARY}")
    list(APPEND MKL_THREADING_LIBRARY "${MKL_TBB_LIBRARY}")
  endif()
endif()

################################################################################
# MKL_ROOT variable
# recover MKL_ROOT from library path found; use path of first library
if (NOT MKL_ROOT AND MKL_LIBRARIES)
    list(GET MKL_LIBRARIES 0 _tmp)
    # make sure the library was found and does not contain -NOTFOUND
    if (_tmp)
        # string the last path components from library, ie something such as
        # /lib/intel64_win/mkl_rt.lib to obtain the MKL root directory
        string(REGEX REPLACE "[/\\]lib[/\\]([^/\\]+[/\\])?mkl_[^/\\]+$" ""
            MKL_ROOT "${_tmp}"
        )
    endif ()
endif ()

# if MKL_ROOT still not found then give up
if (NOT MKL_ROOT OR NOT IS_DIRECTORY "${MKL_ROOT}")
    set(MKL_ROOT NOTFOUND)
endif ()

set(MKL_ROOT "${MKL_ROOT}" CACHE PATH "MKL root directory" FORCE)

################################################################################
# INCLUDE DIRECTORIES

# base include/ directory in MKLROOT; this is not needed for Fortran without
# using Fortran 95 wrappers, as then there are no MOD files to use
get_property(_LANGUAGES_ GLOBAL PROPERTY ENABLED_LANGUAGES)
# CMake does not seem to match regex on word boundary, so process each language
# in turn to avoid matching "RC"
set(_HAS_C FALSE)
foreach(_lang IN LISTS _LANGUAGES_)
  if (NOT _HAS_C)
    STRING(TOUPPER ${_lang} _lang)
    if (_lang STREQUAL "C" OR _lang STREQUAL "CXX")
      set(_HAS_C TRUE)
    endif()
  endif()
endforeach()

if (_HAS_C)
  find_path(_MKL_INCLUDE_DIR
    NAMES mkl.h
    HINTS ${MKL_ROOT}
    PATHS ${_MKL_PATHS}
    PATH_SUFFIXES include
  )

  list(APPEND MKL_INCLUDE_DIRS "${_MKL_INCLUDE_DIR}")
  mark_as_advanced(_MKL_INCLUDE_DIR)
endif()

# Components: MKL_FIND_COMPONENTS contains both required and optional components
# Currently supported components: BLAS95, LAPACK95
# Other optional libraries (wrappers) are not distributed as binaries, not even
# on Windows, and have to be compiled by the users
foreach(_comp ${MKL_FIND_COMPONENTS})
  string(TOLOWER "${_comp}" _name)

  name_interface(_name ${_name} ${MKL_ARCH} ${_INTERFACE})
  # additional library names start with mkl_
  set(_name mkl_${_name})

  find_library(MKL_${_comp}_LIBRARY
    NAMES ${_name}
    HINTS ${MKL_ROOT}  ${MKL_F95ROOT}
    PATHS ${_MKL_PATHS}
    PATH_SUFFIXES lib/${MKL_ARCH} lib .
  )

  # find include path for MOD files
  string(TOLOWER ${_comp} _name)
  string(TOLOWER ${_INTERFACE} _ifname)

  find_path(MKL_${_comp}_INCLUDE_DIR
    NAMES "${_name}.mod"
    HINTS ${MKL_ROOT}  ${MKL_F95ROOT}
    PATHS ${_MKL_PATHS}
    PATH_SUFFIXES include/${MKL_ARCH}/${_ifname} include/${MKL_ARCH} include .
  )

  if (MKL_${_comp}_LIBRARY AND MKL_${_comp}_INCLUDE_DIR)
    # FPHSA function expects the *_FOUND variables to be properly defined for
    # HANDLE_COMPONENTS to work
    set(MKL_${_comp}_FOUND TRUE)
    # optional libs should probably come first in link line
    list(INSERT MKL_LIBRARIES 0 "${MKL_${_comp}_LIBRARY}")
    list(INSERT MKL_INCLUDE_DIRS 0 "${MKL_${_comp}_INCLUDE_DIR}")
  else()
    set(MKL_${_comp}_FOUND FALSE)
  endif()
endforeach()

include(FindPackageHandleStandardArgs)

# include directories not needed for pure Fortran w/o Fortran95 components
if (NOT _HAS_C AND NOT MKL_FIND_COMPONENTS)
  set(_INCLUDE_DIR_VAR "")
else()
  set(_INCLUDE_DIR_VAR MKL_INCLUDE_DIRS)
endif()

find_package_handle_standard_args(MKL
  REQUIRED_VARS MKL_ROOT MKL_LIBRARIES ${_INCLUDE_DIR_VAR}
  HANDLE_COMPONENTS
  FAIL_MESSAGE "Could not find MKL libraries: need to set MKLROOT environment variable?"
)


# mark_as_advanced(MKL_LIBRARY)

# vim: sts=2 sw=2 ts=8 tw=80 et
