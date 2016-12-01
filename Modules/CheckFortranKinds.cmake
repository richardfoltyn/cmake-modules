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


    list(APPEND BITSIZE 8 16 32 64 128)

    # arguments to selected_int_kind
    set(SELECTED_INT_SIZE8 2)
    set(SELECTED_INT_SIZE16 4)
    set(SELECTED_INT_SIZE32 9)
    set(SELECTED_INT_SIZE64 12)
    set(SELECTED_INT_SIZE128 20)

    if (NOT DEFINED Fortran_SUPPORTED_INTS)
        unset(_SUPPORTED)
        foreach(_size IN LISTS BITSIZE)
            set(SOURCE_CODE
                "
                program kind_test
                    integer, parameter :: k = &
                        selected_int_kind(${SELECTED_INT_SIZE${_size}})
                    integer (k) :: val
                    integer :: i
                    print '(i0,a1,i0,a1,i0)', k, ';', bit_size(val), ';', bit_size(i)
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
                list(GET _tmp 2 _default_size)

                if (_size STREQUAL ${_size})
                    set(${_var} TRUE CACHE BOOL "" FORCE)
                    list(APPEND _SUPPORTED ${_size})
                    set(Fortran_INT${_size}_KIND ${_kind} CACHE INTERNAL "" FORCE)
                endif()

                if (_size STREQUAL _default_size)
                    set(Fortran_DEFAULT_INT_KIND ${_kind} CACHE INTERNAL "" FORCE)
                    set(Fortran_DEFAULT_INT_SIZE ${_size} CACHE INTERNAL "" FORCE)
                endif()
            endif()

            mark_as_advanced(${_var})
        endforeach()

        set(Fortran_SUPPORTED_INTS ${_SUPPORTED} CACHE INTERNAL "" FORCE)
        unset(_msg)
        foreach (_size IN LISTS _SUPPORTED)
            if (_msg)
                set(_msg "${_msg}, ${_size}")
            else()
                set(_msg "${_size}")
            endif()
            if (_size STREQUAL Fortran_DEFAULT_INT_SIZE)
                set(_msg "${_msg} (default)")
            endif()
        endforeach()
        message(STATUS "Checking supported Fortran integer bit sizes -- ${_msg}")
    endif()

    # process REAL kinds
    unset(BITSIZE)
    list(APPEND BITSIZE 32 64 128)
    # first argument to selected_real_kind()
    set(SELECTED_REAL_PREC32 6)
    set(SELECTED_REAL_PREC64 15)
    set(SELECTED_REAL_PREC128 33)

    if (NOT DEFINED Fortran_SUPPORTED_REALS)
        unset(_SUPPORTED)
        foreach(_size IN LISTS BITSIZE)
            set(SOURCE_CODE
                "
                program kind_test
                    integer, parameter :: k = &
                        selected_real_kind(${SELECTED_REAL_PREC${_size}})
                    real (k) :: val
                    real :: r
                    print '(i0,a1,i0,a1,i0)', k, ';', precision(val), ';', precision(r)
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
                list(GET _tmp 2 _default_prec)

                if (_prec STREQUAL ${SELECTED_REAL_PREC${_size}})
                    set(${_var} TRUE CACHE BOOL "" FORCE)
                    list(APPEND _SUPPORTED ${_size})
                    set(Fortran_REAL${_size}_KIND ${_kind} CACHE INTERNAL "" FORCE)
                endif()

                if (_prec STREQUAL _default_prec)
                    set(Fortran_DEFAULT_REAL_KIND ${_kind} CACHE INTERNAL "" FORCE)
                    set(Fortran_DEFAULT_REAL_SIZE ${_size} CACHE INTERNAL "" FORCE)
                endif()
            endif()

            mark_as_advanced(${_var})

        endforeach()

        set(Fortran_SUPPORTED_REALS ${_SUPPORTED} CACHE INTERNAL "" FORCE)

        unset(_msg)
        foreach (_size IN LISTS _SUPPORTED)
            if (_msg)
                set(_msg "${_msg}, ${_size}")
            else()
                set(_msg "${_size}")
            endif()
            if (_size STREQUAL Fortran_DEFAULT_REAL_SIZE)
                set(_msg "${_msg} (default)")
            endif()
        endforeach()

        message(STATUS "Checking supported Fortran real bit sizes -- ${_msg}")

    endif()


endfunction()
