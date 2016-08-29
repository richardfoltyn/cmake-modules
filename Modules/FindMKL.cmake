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
# unless a prefix is specified where to locate them. This is done either via
#   -DMKL_F95ROOT:STRING=/path/to/mkl95
# or by setting the environment ariable F95ROOT.


# if none of the MKL_* variables are defined, assume MKL_RT=ON by default
if (NOT DEFINED MKL_RT AND NOT DEFINED MKL_INTERFACE AND NOT DEFINED MKL_THREADING)
  set(MKL_RT TRUE)
endif()

include(FindPackageHandleStandardArgs)

# determine target architecture
include(FindTargetArch)
if (TARGET_ARCH_BITS EQUAL 64)
  set(IS_AMD64 TRUE)
else()
  set(IS_AMD64 FALSE)
endif()

# MKL_ARCH determined in which folders in MKL installation to look; this is
# independent of the compiler used to create executables
if (IS_AMD64)
    set(MKL_ARCH intel64)
else ()
    set(MKL_ARCH ia32)
endif ()

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

# If -DMKL_ROOT=/path/to/mkl was passed to cmake, use this as the MKL root
# directory. Otherwise, try to use the MKLROOT environment variable if defined.
if (NOT MKL_ROOT)
    set(MKL_ROOT_TRY "$ENV{MKLROOT}")
    if (MKL_ROOT_TRY)
        set(MKL_ROOT "${MKL_ROOT_TRY}")
    else ()
        # set it to some dummy value so we don't get syntax errors in find_*
        # functions
        set(MKL_ROOT_TRY "/opt/intel/mkl")
    endif ()
else()
    set(MKL_ROOT_TRY "${MKL_ROOT}")
endif()

if (NOT MKL_F95ROOT)
    # TRY to use environment variable F95ROOT which is mentioned in Intel's
    # link advisor
    set(MKL_F95ROOT_ENV "$ENV{F95ROOT}")
endif ()

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

# suffixes for find_library; use platform-specific lib*/ directory if available
include(GNUInstallDirs)
if(CMAKE_INSTALL_LIBDIR)
    set(_GNU_LIBDIR "${CMAKE_INSTALL_LIBDIR}/${MKL_ARCH} ${CMAKE_INSTALL_LIBDIR}")
endif ()
set(LIB_PATH_SUFFIXES lib/${MKL_ARCH} lib .)
set(LIB_PATH_SUFFIXES95 ${_GNU_LIBDIR} ${LIB_PATH_SUFFIXES})

# identify supported compiler
if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
    set(IS_INTEL TRUE)
elseif (CMAKE_Fortran_COMPILER_ID STREQUAL "PGI")
    set(IS_PGI TRUE)
elseif (CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    set(IS_GFORTRAN TRUR)
else ()
    message(FATAL_ERROR "Unsupported Fortran compiler")
endif ()

################################################################################
# MKL Interface
# default interface: LP64 (only relevant for intel64 architecture)
string(TOUPPER "${MKL_INTERFACE}" _INTERFACE)
if (IS_AMD64 AND NOT _INTERFACE)
    set(_INTERFACE LP64)
else ()
    # unset for 32-bit arch, we have no options here
    unset(_INTERFACE)
endif()

# find suffix for interface library
if (IS_AMD64)
    if (MKL_ILP64)
        set(LP_SUFFIX "_ilp64")
    else ()
        set(LP_SUFFIX "_lp64")
    endif()

    # gfortran not supported on Windows
    if (IS_GFORTRAN AND NOT WIN32)
        set(COMP_SUFFIX "_gf")
    else ()
        set(COMP_SUFFIX "_intel")
    endif ()
else ()
    if (WIN32)
        if (IS_PGI)
            set(COMP_SUFFIX "_intel_s")
        else (IS_PGI)
            set(COMP_SUFFIX "_intel_c")
        endif ()
    else()
        if(IS_INTEL OR IS_PGI)
            set(COMP_SUFFIX "_intel")
        elseif (IS_GFORTRAN)
            set(COMP_SUFFIX "_gf")
        endif ()
    endif ()
endif ()
set(_INTERFACE_SUFFIX "${COMP_SUFFIX}${LP_SUFFIX}")

################################################################################
# Locate MKL libraries
set(MKL_LIBRARIES)

if (MKL_RT)
  set(_NAMES mkl_rt)
  find_library(MKL_RT_LIBRARY
    NAMES ${_NAMES}
    HINTS ${MKL_ROOT_TRY}
    PATHS ${_MKL_PATHS}
    PATH_SUFFIXES ${LIB_PATH_SUFFIXES}
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
    set(_INTERFACE_NAMES "mkl${_INTERFACE_SUFFIX}")

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
      HINTS ${MKL_ROOT_TRY}
      PATHS ${_MKL_PATHS}
      PATH_SUFFIXES ${LIB_PATH_SUFFIXES}
    )

    list(APPEND MKL_LIBRARIES "${MKL_${_type}_LIBRARY}")
  endforeach()

  # append tbb library if TBB threading model requested
  if (MKL_THREADING STREQUAL "TBB")
    find_library(MKL_TBB_LIBRARY
      NAMES tbb
      HINTS ${MKL_ROOT_TRY}
      PATHS ${_MKL_PATHS}
      PATH_SUFFIXES lib/${MKL_ARCH}
    )

    list(APPEND MKL_LIBRARIES "${MKL_TBB_LIBRARY}")
    list(APPEND MKL_THREADING_LIBRARY "${MKL_TBB_LIBRARY}")
  endif()
endif()

find_package_handle_standard_args(MKL DEFAULT_MSG MKL_LIBRARIES)

################################################################################
# Additional libraries

if (MKL_FOUND)
    if (Find_MKL_QUIETLY OR NOT FIND_MKL_REQUIRED)
        find_package(Threads)
    else ()
        find_package(Threads REQUIRED)
    endif ()

    # append -lm on non-Windows systems
    if (NOT WIN32)
        set(LM "-lm")
    endif ()

    list(APPEND MKL_LIBRARIES ${CMAKE_THREAD_LIBS_INIT} ${LM})
endif ()

################################################################################
# MKL_ROOT variable
# recover MKL_ROOT from library path found; use path of first library
if (MKL_FOUND)
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
endif ()

################################################################################
# INCLUDE DIRECTORIES

set(MKL_INCLUDE_DIRS)

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
  mark_as_advanced(_MKL_INCLUDE_DIR)

  list(APPEND MKL_INCLUDE_DIRS "${_MKL_INCLUDE_DIR}")
endif()

# macro to test whether compiling against Fortran 95 library works
macro(mkl95_compile _var _file)
    message(STATUS "Checking whether linking to ${_comp} works")
    try_compile(${_var} "${CMAKE_BINARY_DIR}/tmp/FindMKL/"
        "${CMAKE_CURRENT_LIST_DIR}/${_file}"
        LINK_LIBRARIES ${_TRY_LIBRARIES}
        OUTPUT_VARIABLE _result
        CMAKE_FLAGS
            "-DINCLUDE_DIRECTORIES=${MKL_${_comp}_INCLUDE_DIR}"
    )
    set(${_var} ${${_var}} CACHE INTERNAL "Whether MKL component works")
    # message("*** try_compile result: ${_result}")
endmacro()

# Components: MKL_FIND_COMPONENTS contains both required and optional components
# Currently supported components: BLAS95, LAPACK95
# Other optional libraries (wrappers) are not distributed as binaries, not even
# on Windows, and have to be compiled by the users
if (MKL_FOUND)
    foreach(_comp ${MKL_FIND_COMPONENTS})
        string(TOLOWER "${_comp}" _name)

        # additional library names start with mkl_
        set(_name mkl_${_name}${LP_SUFFIX})

        find_library(MKL_${_comp}_LIBRARY
            NAMES ${_name}
            HINTS ${MKL_F95ROOT} ${MKL_ROOT}
            PATHS ${_MKL_PATHS}
            PATH_SUFFIXES ${LIB_PATH_SUFFIXES95}
        )

        # find include path for MOD files
        string(TOLOWER ${_comp} _name)
        string(TOLOWER ${_INTERFACE} _ifname)

        find_path(MKL_${_comp}_INCLUDE_DIR
            NAMES "${_name}.mod"
            HINTS ${MKL_F95ROOT} ${MKL_ROOT}
            PATHS ${_MKL_PATHS}
            PATH_SUFFIXES
                include/${MKL_ARCH}/${_ifname} include/${MKL_ARCH} include .
        )

        # Check whether linking against Fortran 95 library works, if we have
        # not yet done so
        if (MKL_${_comp}_LIBRARY AND MKL_${_comp}_INCLUDE_DIR)
            if (NOT MKL_${_comp}_WORKS)
                unset(_TRY_LIBRARIES)
                list(APPEND _TRY_LIBRARIES ${MKL_${_comp}_LIBRARY})
                list(APPEND _TRY_LIBRARIES ${MKL_LIBRARIES})

                if (${_name} STREQUAL "blas95")
                    mkl95_compile(MKL_${_comp}_WORKS "blas95.f90")
                elseif (${_name} STREQUAL "lapack95")
                    mkl95_compile(MKL_${_comp}_WORKS "lapack95.f90")
                else ()
                    set(MKL_${_comp}_WORKS TRUE)
                endif ()
            endif ()

            # FPHSA function expects the *_FOUND variables to be properly defined for
            # HANDLE_COMPONENTS to work
            if (MKL_${_comp}_WORKS)
                set(MKL_${_comp}_FOUND TRUE)
                # optional libs should probably come first in link line
                list(INSERT MKL_LIBRARIES 0 "${MKL_${_comp}_LIBRARY}")
                list(INSERT MKL_INCLUDE_DIRS 0 "${MKL_${_comp}_INCLUDE_DIR}")
            else()
                set(MKL_${_comp}_FOUND FALSE)
            endif ()
        else ()
            set(MKL_${_comp}_FOUND FALSE)
        endif()
    endforeach()
endif ()

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


# vim: sts=4 sw=4 ts=8 tw=80 et
