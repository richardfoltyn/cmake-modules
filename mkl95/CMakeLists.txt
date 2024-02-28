# mkl95/CMakeLists.txt
# Configuration file to build Fortran 95 interfaces to MKL
# (currently tested components: blas95 lapack95)
#
# The resulting libraries and MOD files are installed in CMAKE_INSTALL_PREFIX
# in the usual subdirectories (lib/ and include/)
#
# Options:
#   ARCH_INSTALL_DIRS       Mimick the directory hierarchy used by Intel's make
#                           file, ie. create architecture and interface-specific
#                           subdirectories for libraries and MOD files beneath
#                           lib/ and include/
#   MKL_ILP64               Build using ILP64 interface (for 64-bit targets)

cmake_minimum_required(VERSION 3.12)

project(build_mkl95 C Fortran)

################################################################################
# User-definable options
option(ARCH_INSTALL_DIRS "Create architecture/interface-specific subdirectories" ON)
option(MKL_ILP64 "Use ILP64 interface (only on 64-bit platforms)" OFF)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../Modules")
find_package(MKL REQUIRED)
include(FindTargetArch)

if (NOT MKL_ROOT)
    message(FATAL_ERROR "MKL root directory not found")
endif ()

# disable IPL64 for 32-bit targets, not applicable
if (NOT TARGET_ARCH_BITS EQUAL 64)
    set(MKL_IPL64 OFF)
endif ()

################################################################################
# Arch-specific install directory structure

if (TARGET_ARCH_BITS STREQUAL "64")
  set(MKL95_ARCH libintel64)
  set(MKL95_LIBRARY_PREFIX intel64)
  set(MKL95_INCLUDE_PREFIX intel64/lp64)

  # MKL interface
  set(MKL95_SUFFIX _lp64)

  # use IPL64 interface if requested
    if (MKL_ILP64)
        set(MKL95_INCLUDE_PREFIX intel64/ilp64)
        set(MKL95_SUFFIX _ilp64)
    endif()
else ()
    # no idea whether this is the correct directory, not tested with 32 bit
    set(MKL95_LIBRARY_PREFIX ia32)
    set(MKL95_INCLUDE_PREFIX ia32)
endif()

set(CMAKE_Fortran_MODULE_PATH "${CMAKE_BINARY_DIR}/include")

# installation tree structure
if (UNIX)
    include(GNUInstallDirs)
endif ()

if (NOT CMAKE_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR lib)
endif ()
if (NOT CMAKE_INSTALL_INCLUDEDIR)
    set(CMAKE_INSTALL_INCLUDEDIR include)
endif ()

if (ARCH_INSTALL_DIRS)
    set(CMAKE_INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}/${MKL95_LIBRARY_PREFIX}")
    set(CMAKE_INSTALL_INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}/${MKL95_INCLUDE_PREFIX}" )
endif ()

################################################################################
# Compiler flags

set(_FFLAGS)
if (MKL_ILP64)
    if (CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
        if (WIN32)
            set(_FFLAGS "/4I8 /4Ya")
        else ()
            set(_FFLAGS "-i8 -auto")
        endif ()
    elseif (CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
        set(_FFLAGS "-fdefault-integer-8")
    endif ()

    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${_FFLAGS}")
endif ()

################################################################################
# Components for which to build Fortran95 interfaces

if (MKL95_COMPONENTS)
    string(TOLOWER "${MKL95_COMPONENTS}" MKL95_COMPONENTS)
else ()
    set(MKL95_COMPONENTS blas95 lapack95)
endif ()

foreach (_comp IN LISTS MKL95_COMPONENTS)
    if (IS_DIRECTORY "${MKL_ROOT}/interfaces/${_comp}/source")
        file(GLOB SOURCE_FILES LIST_DIRECTORIES false
            "${MKL_ROOT}/interfaces/${_comp}/source/*.f90"
        )
    else ()
        # oneAPI MKL 2024 and later
        file(GLOB SOURCE_FILES LIST_DIRECTORIES false
            "${MKL_ROOT}/share/mkl/interfaces/${_comp}/source/*.f90"
        )
    endif ()

    if (NOT SOURCE_FILES) 
        message(FATAL_ERROR "MKL interface source directory not found")
    endif ()

    unset(_files)
    unset(_modules)

    # add additional source files for each component, and component-specifc
    # module files
    if (${_comp} STREQUAL "blas95")
        list(APPEND _files mkl_blas.f90)
        list(APPEND _modules blas95 f95_precision)
    elseif (${_comp} STREQUAL "lapack95")
        list(APPEND _files mkl_lapack.f90)
        list(APPEND _modules lapack95 f95_precision)
    endif ()

    # additional interface source files from include directory
    foreach (_file IN LISTS _files)
        set(SOURCE_FILES ${SOURCE_FILES} ${MKL_ROOT}/include/${_file})
    endforeach()

    set(CMAKE_Fortran_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/include/${_comp}")

    set(_target mkl_${_comp}${MKL95_SUFFIX})
    add_library(${_target} ${SOURCE_FILES})
    target_link_libraries(${_target} ${MKL_LIBRARIES})

    install(TARGETS ${_target}
        RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    )

    foreach (_mod IN LISTS _modules)
        install(FILES "${CMAKE_Fortran_MODULE_DIRECTORY}/${_mod}.mod"
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
        )
    endforeach()

endforeach()

################################################################################
# Diagnostic messages
message(STATUS "Using MKL found in ${MKL_ROOT}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Building for ${TARGET_ARCH_BITS}-bit target architecture")
if (MKL_ILP64)
    message(STATUS "Using ILP64 interface")
elseif (TARGET_ARCH_BITS EQUAL 64)
    message(STATUS "Using LP64 interface")
endif ()
message(STATUS "Building components ${MKL95_COMPONENTS}")

message(STATUS "Default compiler flags: ${CMAKE_Fortran_FLAGS}")
# Make sure build type is upper case, otherwise the wrong flags will be shown
string(TOUPPER "${CMAKE_BUILD_TYPE}" _CONFIG)
if (CMAKE_Fortran_FLAGS_${_CONFIG})
    message(STATUS "Default compiler flags for ${CMAKE_BUILD_TYPE}: ${CMAKE_Fortran_FLAGS_${_CONFIG}}")
endif ()
