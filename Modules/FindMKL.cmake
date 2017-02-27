# FindMKL
# -------
#
# This module defines
#  MKL_LIBRARIES, the libraries needed to use Intel's implementation of BLAS & LAPACK.
#  MKL_FOUND, If false, do not try to use MKL.

## the link below explains why we're linking only with mkl_rt
## https://software.intel.com/en-us/articles/a-new-linking-model-single-dynamic-library-mkl_rt-since-intel-mkl-103

# Variables controlling FindMKL behavior:
#   MKL_STATIC:BOOL                 If ON, link against static MKL libraries
#
#   MKL_FORTRAN95_ROOT:STRING       Optional root directory where to look for
#                                   Fortran 95 components (not needed on Windows)
#
# COMPONENTS (optional):
#   RT                      Use Single dynamic library (default). Specifying
#                           this option overrides all other interface/threading
#                           components.
#
#   LP64                    Use LP64 interface (default if RT not set)
#   ILP64                   Use ILP64 interface (only available on 64bit builts)
#   SEQUENTIAL              Use non-threaded MKL (default if RT not set)
#   OPENMP                  Use OpenMP threading layer
#   TBB                     Use Intel Thread Building Blocks
#
#   BLAS95                  Fortran 95 interface to BLAS library
#   LAPACK95                Fortran 95 interface to LAPACK library
# Note that components other than BLAS95 and LAPACK95 on Windows are not
# shipped as pre-compiled libraries with MKL. Thus, they will not be found
# unless a prefix is specified where to locate them. This is done either via
#   -DMKL_FORTRAN95_ROOT:STRING=/path/to/mkl95
# or by setting the environment variable MKL_FORTRAN95_ROOT or F95ROOT.

include(FindPackageHandleStandardArgs)

# Determine target architecture
# MKL_ARCH determined in which folders in MKL installation to look; this is
# independent of the compiler used to create executables
include(FindTargetArch)
if (TARGET_ARCH_BITS EQUAL 64)
  set(IS_AMD64 TRUE)
  set(MKL_ARCH intel64)
else()
  set(IS_AMD64 FALSE)
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

# Root directory that contains Fortran 95 wrappers for BLAS, LAPACK, etc.
if (DEFINED MKL_Fortran95_ROOT AND NOT DEFINED MKL_FORTRAN95_ROOT)
    set(MKL_FORTRAN95_ROOT ${MKL_Fortran95_ROOT})
endif ()

if (NOT MKL_FORTRAN95_ROOT)
    unset(_tmp)
    if ($ENV{MKL_FORTRAN95_ROOT})
        set(_tmp "$ENV{MKL_FORTRAN95_ROOT}")
    elseif ($ENV{MKL_Fortran95_ROOT})
        set(_tmp "$ENV{MKL_Fortran95_ROOT}")
    elseif ($ENV{F95ROOT})
        # TRY to use environment variable F95ROOT which is mentioned in Intel's
        # link advisor
        set(MKL_FORTRAN95_ROOT "$ENV{F95ROOT}")
    endif()

    set(MKL_FORTRAN95_ROOT "${_tmp}")
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
    set(IS_GFORTRAN TRUE)
else ()
    message(FATAL_ERROR "Unsupported Fortran compiler")
endif ()

################################################################################
# Default configuration

set(MKL_THREADING_TBB FALSE)
set(MKL_THREADING_OPENMP FALSE)
set(MKL_THREADING_SEQUENTIAL TRUE)

set(MKL_INTERFACE_LP64 TRUE)
set(MKL_INTERFACE_ILP64 FALSE)

set(MKL_RT TRUE)

################################################################################
# Process required COMPONENTS

# Components that are not part of the interface/threading specification will
# be stored in _MKL_FIND_COMPONENTS for later processing
unset(_MKL_FIND_COMPONENTS)
foreach(_comp IN LISTS MKL_FIND_COMPONENTS)
    string(TOUPPER "${_comp}" _name)
    if (_name STREQUAL "TBB")
        set(MLK_THREADING_TBB TRUE)
        set(MKL_THREADING_OPENMP FALSE)
        set(MKL_THREADING_SEQUENTIAL FALSE)
        set(MKL_RT FALSE)
        set(_MKL_FIND_COMPONENT_NAME_TBB ${_comp})
    elseif (_name STREQUAL "OPENMP")
        set(MLK_THREADING_TBB FALSE)
        set(MKL_THREADING_OPENMP TRUE)
        set(MKL_THREADING_SEQUENTIAL FALSE)
        set(MKL_RT FALSE)
        set(_MKL_FIND_COMPONENT_NAME_OPENMP ${_comp})
    elseif (_name STREQUAL "SEQUENTIAL")
        set(MLK_THREADING_TBB FALSE)
        set(MKL_THREADING_OPENMP FALSE)
        set(MKL_THREADING_SEQUENTIAL TRUE)
        set(MKL_RT FALSE)
        set(_MKL_FIND_COMPONENT_NAME_SEQUENTIAL ${_comp})
    elseif (_name STREQUAL "LP64")
        set(MKL_INTERFACE_LP64 TRUE)
        set(MKL_INTERFACE_ILP64 FALSE)
        set(MKL_RT FALSE)
        set(_MKL_FIND_COMPONENT_NAME_LP64 ${_comp})
    elseif (_name STREQUAL "ILP64")
        if (IS_AMD64)
            message(FATAL_ERROR "MKL interface ILP64 not supported for 32-bit builds")
        endif()
        set(MKL_INTERFACE_LP64 FALSE)
        set(MKL_INTERFACE_ILP64 TRUE)
        set(MKL_RT FALSE)
        set(_MKL_FIND_COMPONENT_NAME_ILP64 ${_comp})
    elseif (_name STREQUAL "RT")
        set(MKL_RT TRUE)
        set(_MKL_FIND_COMPONENT_NAME_RT ${_comp})
    else()
        list(APPEND _MKL_FIND_COMPONENTS "${_comp}")
    endif()
endforeach()

# set some names to be used in variable names, depending on what was selected
if (MKL_INTERFACE_ILP64)
    set(MKL_INTERFACE_NAME ILP64)
else ()
    set(MKL_INTERFACE_NAME LP64)
endif ()

if (MKL_THREADING_TBB)
    set(MKL_THREADING_NAME TBB)
elseif (MKL_THREADING_OPENMP)
    set(MKL_THREADING_NAME OPENMP)
else ()
    set(MKL_THREADING_NAME SEQUENTIAL)
endif ()


################################################################################
# Determine library name suffixes which depend on the compiler and MKL
# interface layer used.
if (IS_AMD64)
    if (MKL_INTERFACE_ILP64)
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
unset(MKL_LIBRARY)
unset(MKL_LIBRARIES)
# libraries of MKL dependencies (such as TBB and OpenMP RTLs)
unset(_MKL_DEP_LIBRARIES)

macro(_set_component_vars _comp)
    if (DEFINED MKL_${_comp}_FOUND)
        set(MKL_${_MKL_FIND_COMPONENT_NAME_${_comp}}_FOUND ${MKL_${_comp}_FOUND})
    endif ()
    if (DEFINED MKL_${_comp}_LIBRARY)
        set(MKL_${_MKL_FIND_COMPONENT_NAME_${_comp}}_LIBRARY ${MKL_${_comp}_LIBRARY})
    endif ()
endmacro()

if (MKL_RT)
    set(_NAMES mkl_rt)
    find_library(MKL_RT_LIBRARY
        NAMES ${_NAMES}
        HINTS ${MKL_ROOT_TRY}
        PATHS ${_MKL_PATHS}
        PATH_SUFFIXES ${LIB_PATH_SUFFIXES}
    )

    if (MKL_RT_LIBRARY)
        set(MKL_RT_FOUND TRUE)
    endif ()
    list(APPEND MKL_LIBRARY "${MKL_RT_LIBRARY}")
    _set_component_vars(RT)
else (MKL_RT)
    # No Single dynamic library interface requested, need specify
    # interface/threading/core libraries explicitly

    # On Windows, in dynamic linking is requested the import library names
    # have an _dll suffix;
    unset(_WIN32_DLL_SUFFIX)
    if (WIN32 AND NOT MKL_STATIC)
        set(_WIN32_DLL_SUFFIX "_dll")
    endif()

    # MKL interface library
    set(_INTERFACE_NAMES "mkl${_INTERFACE_SUFFIX}${_WIN32_DLL_SUFFIX}")
    find_library(MKL_${MKL_INTERFACE_NAME}_LIBRARY
        NAMES ${_INTERFACE_NAMES}
        HINTS ${MKL_ROOT_TRY}
        PATHS ${_MKL_PATHS}
        PATH_SUFFIXES ${LIB_PATH_SUFFIXES}
    )
    list(APPEND MKL_LIBRARY "${MKL_${MKL_INTERFACE_NAME}_LIBRARY}")

    if (MKL_${MKL_INTERFACE_NAME}_LIBRARY)
        set(MKL_${MKL_INTERFACE_NAME}_FOUND TRUE)
    else ()
        set(MKL_${MKL_INTERFACE_NAME}_FOUND FALSE)
    endif ()
    _set_component_vars(${MKL_INTERFACE_NAME})

    # MKL core library
    set(_CORE_NAMES "mkl_core${_WIN32_DLL_SUFFIX}")
    find_library(MKL_CORE_LIBRARY
        NAMES ${_CORE_NAMES}
        HINTS ${MKL_ROOT_TRY}
        PATHS ${_MKL_PATHS}
        PATH_SUFFIXES ${LIB_PATH_SUFFIXES}
    )
    list(APPEND MKL_LIBRARY "${MKL_CORE_LIBRARY}")

    # MKL threading library
    if (MKL_THREADING_OPENMP)
        set(_THREADING_NAMES "mkl_intel_thread${_WIN32_DLL_SUFFIX}")
    elseif (MKL_THREADING_TBB)
        set(_THREADING_NAMES "mkl_tbb_thread${_WIN32_DLL_SUFFIX}")
    else ()
        set(_THREADING_NAMES "mkl_sequential${_WIN32_DLL_SUFFIX}")
    endif ()

    find_library(MKL_${MKL_THREADING_NAME}_LIBRARY
        NAMES ${_THREADING_NAMES}
        HINTS ${MKL_ROOT_TRY}
        PATHS ${_MKL_PATHS}
        PATH_SUFFIXES ${LIB_PATH_SUFFIXES}
    )

    list(APPEND MKL_LIBRARY "${MKL_${MKL_THREADING_NAME}_LIBRARY}")

    if (MKL_${MKL_THREADING_NAME}_LIBRARY)
        set(MKL_${MKL_THREADING_NAME}_FOUND TRUE)
    else ()
        set(MKL_${MKL_THREADING_NAME}_FOUND FALSE)
    endif ()
    _set_component_vars(${MKL_THREADING_NAME})

    if (MKL_THREADING_OPENMP)
        if (WIN32)
            set(_OMP_RTL_NAME libiomp5md)
        else ()
            set(_OMP_RTL_NAME liomp5)
        endif()

        # append OpenMP runtime library
        find_library(MKL_FIND_OPENMP_RTL
            NAMES ${_OMP_RTL_NAME}
        )
        list(APPEND _MKL_DEP_LIBRARIES "${MKL_FIND_OPENMP_RTL}")
    elseif (MKL_THREADING_TBB)
        # TODO: on linux, need to add -lstdc++ and other stuff.
        # append tbb library if TBB threading model requested
        find_library(MKL_FIND_TBB_RTL
            NAMES tbb
            HINTS ${MKL_ROOT_TRY}
            PATHS ${_MKL_PATHS}
            PATH_SUFFIXES lib/${MKL_ARCH}
        )
        list(APPEND _MKL_DEP_LIBRARIES "${MKL_FIND_TBB_RTL}")
    endif()
endif()

# Invoke here to set MKL_FOUND which is required for any further processing
if (NOT DEFINED _MKL_DEP_LIBRARIES)
    find_package_handle_standard_args(MKL DEFAULT_MSG MKL_LIBRARY)
else ()
    find_package_handle_standard_args(MKL DEFAULT_MSG MKL_LIBRARY _MKL_DEP_LIBRARIES)
endif ()
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

    list(APPEND _MKL_DEP_LIBRARIES ${CMAKE_THREAD_LIBS_INIT} ${LM})
endif ()

################################################################################
# MKL_ROOT variable
# recover MKL_ROOT from library path found; use path of first library
if (MKL_FOUND)
    if (NOT MKL_ROOT AND MKL_LIBRARY)
        list(GET MKL_LIBRARY 0 _tmp)
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

unset(MKL_INCLUDE_DIRS)

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
  find_path(MKL_INCLUDE_DIR
    NAMES mkl.h
    HINTS ${MKL_ROOT}
    PATHS ${_MKL_PATHS}
    PATH_SUFFIXES include
  )

  list(APPEND MKL_INCLUDE_DIRS "${MKL_INCLUDE_DIR}")
endif()

# macro to test whether compiling against Fortran 95 library works
macro(mkl95_compile _var _file _libs)
    message(STATUS "Checking whether linking to ${_comp} works")
    try_compile(${_var} "${CMAKE_BINARY_DIR}/tmp/FindMKL/"
        "${CMAKE_CURRENT_LIST_DIR}/${_file}"
        LINK_LIBRARIES ${${_libs}}
        OUTPUT_VARIABLE _result
        CMAKE_FLAGS
            "-DINCLUDE_DIRECTORIES=${MKL_${_comp}_INCLUDE_DIR}"
    )
    set(${_var} ${${_var}} CACHE INTERNAL "Whether MKL component works")
endmacro()

# Components: MKL_FIND_COMPONENTS contains both required and optional components
# Currently supported components: BLAS95, LAPACK95
# Other optional libraries (wrappers) are not distributed as binaries, not even
# on Windows, and have to be compiled by the users
if (MKL_FOUND)
    # Determine interface name component; empty for ia32 libraries.
    if (IS_AMD64 AND MKL_INTERFACE_LP64)
        set(_ifname "lp64")
    elseif (IS_AMD64 AND MKL_INTERFACE_ILP64)
        set(_ifname "ilp64")
    endif()

    foreach(_comp IN LISTS _MKL_FIND_COMPONENTS)
        string(TOLOWER "${_comp}" _name_lower)
        string(TOUPPER "${_comp}" _name)
        # store user-given component name for use in _set_component_vars macro
        set(_MKL_FIND_COMPONENT_NAME_${_name} ${_comp})

        # additional library names start with mkl_
        find_library(MKL_${_name}_LIBRARY
            NAMES mkl_${_name_lower}${LP_SUFFIX}
            HINTS ${MKL_FORTRAN95_ROOT} ${MKL_ROOT}
            PATHS ${_MKL_PATHS}
            PATH_SUFFIXES ${LIB_PATH_SUFFIXES95}
        )

        # find include path for MOD files
        find_path(MKL_${_name}_INCLUDE_DIR
            NAMES "${_name_lower}.mod"
            HINTS ${MKL_FORTRAN95_ROOT} ${MKL_ROOT}
            PATHS ${_MKL_PATHS}
            PATH_SUFFIXES
                include/${MKL_ARCH}/${_ifname} include/${MKL_ARCH} include .
        )

        # Check whether linking against Fortran 95 library works, if we have
        # not yet done so
        if (MKL_${_name}_LIBRARY AND MKL_${_name}_INCLUDE_DIR)
            if (NOT MKL_${_name}_WORKS)
                unset(_TRY_LIBRARIES)
                list(APPEND _TRY_LIBRARIES ${MKL_${_name}_LIBRARY})
                list(APPEND _TRY_LIBRARIES ${MKL_LIBRARY})
                list(APPEND _TRY_LIBRARIES ${_MKL_DEP_LIBRARIES})

                if (${_name} STREQUAL "BLAS95")
                    mkl95_compile(MKL_${_name}_WORKS "blas95.f90" _TRY_LIBRARIES)
                elseif (${_name} STREQUAL "LAPACK95")
                    mkl95_compile(MKL_${_name}_WORKS "lapack95.f90" _TRY_LIBRARIES)
                else ()
                    set(MKL_${_name}_WORKS TRUE)
                endif ()
            endif ()

            # FPHSA function expects the *_FOUND variables to be properly defined for
            # HANDLE_COMPONENTS to work
            if (MKL_${_name}_WORKS)
                set(MKL_${_name}_FOUND TRUE)
                # optional libs should probably come first in link line
                list(INSERT MKL_LIBRARY 0 "${MKL_${_name}_LIBRARY}")
                list(INSERT MKL_INCLUDE_DIRS 0 "${MKL_${_name}_INCLUDE_DIR}")
            else()
                set(MKL_${_name}_FOUND FALSE)
            endif ()
        else ()
            set(MKL_${_name}_FOUND FALSE)
        endif()
        _set_component_vars(${_name})
    endforeach()
endif ()

# include directories not needed for pure Fortran w/o Fortran95 components
if (NOT _HAS_C AND NOT MKL_FIND_COMPONENTS)
    set(_INCLUDE_DIR_VAR "")
else()
    set(_INCLUDE_DIR_VAR MKL_INCLUDE_DIRS)
endif()

set(MKL_LIBRARIES ${MKL_LIBRARY} ${_MKL_DEP_LIBRARIES})

find_package_handle_standard_args(MKL
    REQUIRED_VARS MKL_ROOT MKL_LIBRARIES ${_INCLUDE_DIR_VAR}
    HANDLE_COMPONENTS
    FAIL_MESSAGE "Could not find MKL libraries: need to set MKLROOT environment variable?"
)


# vim: sts=4 sw=4 ts=8 tw=80 et
