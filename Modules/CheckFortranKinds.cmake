# CheckFortranKinds
#
# Check which integer and real kinds are supported by Fortran compiler.
# After calling the function check_Fortran_kinds(), the following
# cached variables will be set:
#
#   Fortran_SUPPORTS_INTxxx         True if compiler supports integers with
#                                   bit size xxx (6, 16, 32, 64, 128)
#   Fortran_SUPPORTS_REAlxxx        True if compiler supports floating point
#                                   numbers of {32,64,128} bits.
#
#   Fortran_INTxxx_KIND             Integer kind parameter that corresponds
#                                   to bit size xxx.
#   Fortran_REALxxx_KIND            Integer kind parameter that corresponds
#                                   to real of xxx bits.
#
#   Fortran_DEFAULT_INT_KIND        Default integer kind
#   Fortran_DEFAULT_INT_SIZE        Bit size of default integer.
#
#   Fortran_DEFAULT_REAL_KIND        Default real kind
#   Fortran_DEFAULT_REAL_SIZE        Bit size of default real
#
#   Fortran_SUPPORTED_INTS          List of bit sizes of supported integers
#   Fortran_SUPPORTED_REALS         List of bit sizes of supported reals

include(mktempname)

function(check_Fortran_kinds)

    # Store default integer kind and size
    if (NOT DEFINED Fortran_DEFAULT_INT_KIND)
        find_Fortran_default_int()
    endif()

    if (NOT DEFINED Fortran_DEFAULT_REAL_KIND)
        find_Fortran_default_real()
    endif()

    if (NOT DEFINED Fortran_SUPPORTED_INTS)
        find_Fortran_supported_ints()
        print_report("integers" Fortran_SUPPORTED_INTS Fortran_DEFAULT_INT_SIZE)
    endif()

    if (NOT DEFINED Fortran_SUPPORTED_REALS)
        find_Fortran_supported_reals()
        print_report("reals" Fortran_SUPPORTED_REALS Fortran_DEFAULT_REAL_SIZE)
    endif()

endfunction()

################################################################################
# Function to detect the KIND parameter and bit size of default integer kind.
# Results are stored in the cache variables
#   Fortran_DEFAULT_INT_KIND
#   Fortran_DEFAULT_INT_SIZE
function(find_Fortran_default_int)
    set(SOURCE_CODE
        "
        program kind_test
            integer :: i
            print '(i0,a1,i0)', kind(i), ';', bit_size(i)
        end
        "
    )

    mktempname(_TEMPFILE "${CMAKE_BINARY_DIR}/test-kind" ".f90")
    file (WRITE "${_TEMPFILE}" "${SOURCE_CODE}")
    try_run(_run_result _compile_result
        ${CMAKE_BINARY_DIR} "${_TEMPFILE}"
        RUN_OUTPUT_VARIABLE _output_result
    )
    file (REMOVE "${_TEMPFILE}")

    string(STRIP "${_output_result}" _tmp)
    list(GET _tmp 0 _kind)
    list(GET _tmp 1 _size)

    set(Fortran_DEFAULT_INT_KIND ${_kind} CACHE INTERNAL "" FORCE)
    set(Fortran_DEFAULT_INT_SIZE ${_size} CACHE INTERNAL "" FORCE)
endfunction()

################################################################################
# Function to detect the default real KIND parameter. KIND value is stored
# in the cached variable
#   Fortran_DEFAULT_REAL_KIND
function(find_Fortran_default_real)
    set(SOURCE_CODE
        "
        program kind_test
            real :: r
            print '(i0)', kind(r)
        end
        "
    )

    mktempname(_TEMPFILE "${CMAKE_BINARY_DIR}/test-kind" ".f90")
    file (WRITE "${_TEMPFILE}" "${SOURCE_CODE}")
    try_run(_run_result _compile_result
        ${CMAKE_BINARY_DIR} "${_TEMPFILE}"
        RUN_OUTPUT_VARIABLE _output_result
    )
    file (REMOVE "${_TEMPFILE}")

    string(STRIP "${_output_result}" _kind)
    set(Fortran_DEFAULT_REAL_KIND ${_kind} CACHE INTERNAL "" FORCE)
endfunction()

################################################################################
# Detect supported integer kinds and bit sizes. For each each bit size, the
# cached variables
#   Fortran_SUPPORTED_INTxxx
#   Fortran_INTxxx_KIND
# are created to indicate whether integers of size xxx are supported, and
# if so, their associated KIND parameter.
function(find_Fortran_supported_ints)
    list(APPEND BITSIZE 8 16 32 64 128)

    # arguments to selected_int_kind
    set(SELECTED_INT_SIZE8 2)
    set(SELECTED_INT_SIZE16 4)
    set(SELECTED_INT_SIZE32 9)
    set(SELECTED_INT_SIZE64 12)
    set(SELECTED_INT_SIZE128 20)

    unset(_SUPPORTED)
    foreach(_size IN LISTS BITSIZE)
        set(SOURCE_CODE
            "
            program kind_test
                integer, parameter :: k = &
                    selected_int_kind(${SELECTED_INT_SIZE${_size}})
                integer (k) :: val
                print '(i0,a1,i0)', k, ';', bit_size(val)
            end program
            "
        )

        mktempname(_TEMPFILE "${CMAKE_BINARY_DIR}/test-kind" ".f90")
        file (WRITE "${_TEMPFILE}" "${SOURCE_CODE}")
        try_run(_run_result _compile_result
            ${CMAKE_BINARY_DIR} "${_TEMPFILE}"
            RUN_OUTPUT_VARIABLE _output_result
        )
        file (REMOVE "${_TEMPFILE}")

        set(_var Fortran_SUPPORTS_INT${_size})
        set(${_var} FALSE CACHE INTERNAL "" FORCE)

        if (_compile_result)
            # parse output for real kind and precision
            string(STRIP "${_output_result}" _tmp)
            list(GET _tmp 0 _kind)
            list(GET _tmp 1 _size)

            if (_size STREQUAL ${_size})
                set(${_var} TRUE CACHE BOOL "" FORCE)
                list(APPEND _SUPPORTED ${_size})
                set(Fortran_INT${_size}_KIND ${_kind} CACHE INTERNAL "" FORCE)
            endif()
        endif()

        mark_as_advanced(${_var})
    endforeach()

    set(Fortran_SUPPORTED_INTS ${_SUPPORTED} CACHE INTERNAL "" FORCE)
endfunction()

################################################################################
# Detected supported real KINDs. 
function(find_Fortran_supported_reals)
    list(APPEND BITSIZE 32 64 128)
    # first argument to selected_real_kind()
    set(SELECTED_REAL_PREC32 6)
    set(SELECTED_REAL_PREC64 15)
    set(SELECTED_REAL_PREC128 33)

    unset(_SUPPORTED)
    foreach(_size IN LISTS BITSIZE)
        set(SOURCE_CODE
            "
            program kind_test
                integer, parameter :: k = &
                    selected_real_kind(${SELECTED_REAL_PREC${_size}})
                real (k) :: val
                print '(i0,a1,i0)', k, ';', precision(val)
            end program
            "
        )

        mktempname(_TEMPFILE "${CMAKE_BINARY_DIR}/test-kind" ".f90")
        file (WRITE "${_TEMPFILE}" "${SOURCE_CODE}")
        try_run(_run_result _compile_result
            ${CMAKE_BINARY_DIR} "${_TEMPFILE}"
            RUN_OUTPUT_VARIABLE _output_result
        )
        file (REMOVE "${_TEMPFILE}")

        set(_var Fortran_SUPPORTS_REAL${_size})
        set(${_var} FALSE CACHE INTERNAL "" FORCE)

        if (_compile_result)
            # parse output for real kind and precision
            string(STRIP "${_output_result}" _tmp)
            list(GET _tmp 0 _kind)
            list(GET _tmp 1 _prec)

            if (_prec STREQUAL ${SELECTED_REAL_PREC${_size}})
                set(${_var} TRUE CACHE BOOL "" FORCE)
                list(APPEND _SUPPORTED ${_size})
                set(Fortran_REAL${_size}_KIND ${_kind} CACHE INTERNAL "" FORCE)
            endif()

            # identify default real size by comparing against previously found
            # default KIND
            if (_kind STREQUAL Fortran_DEFAULT_REAL_KIND)
                set(Fortran_DEFAULT_REAL_SIZE ${_size} CACHE INTERNAL "" FORCE)
            endif()
        endif()

        mark_as_advanced(${_var})

    endforeach()

    set(Fortran_SUPPORTED_REALS ${_SUPPORTED} CACHE INTERNAL "" FORCE)
endfunction()

function(print_report label supported default)
    foreach (_size IN LISTS ${supported})
        if (_msg)
            set(_msg "${_msg}, ${_size}")
        else()
            set(_msg "${_size}")
        endif()
        if (_size STREQUAL ${default})
            set(_msg "${_msg} (default)")
        endif()
    endforeach()

    message(STATUS "Checking supported Fortran ${label} -- ${_msg}")
endfunction()
