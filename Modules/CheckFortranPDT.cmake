# CheckFortranPDT
# Check whether Fortran compiler suppors Parametrized Derived Types (PDT)
# After calling the function check_Fortran_PDT_support(), the following
# cached variables will be set:
#
#   Fortran_SUPPORTS_PDT_KIND       True if compiler supports KIND parameters.
#   Fortran_SUPPORTS_PDT_LEN        True if compiler supports LEN parameters.
#
# Note that both KIND and LEN parameters are part of the Fortran 2003 standard,
# but some compilers implement none, one or both paratemer variants.

include(mktempname)

function(check_Fortran_PDT_support)
    set(SOURCE_CODE_KIND
        "
        program pdt_test
            use iso_fortran_env, only: int32
            type :: pdt (x)
                integer, kind :: x
                integer (x) :: xx
            end type

            type (pdt(int32)) :: obj
        end program
        "
    )

    set(SOURCE_CODE_LEN
        "
        program pdt_test
            type :: pdt (x)
                integer, len :: x
                integer, dimension(x) :: xx
            end type

            type (pdt(x=10)) :: obj
        end program
        "
    )

    set(MSG_TRUE yes)
    set(MSG_FALSE no)

    if (NOT DEFINED Fortran_SUPPORTS_PDT_KIND)
        mktempname(_TEMPFILE "${CMAKE_BINARY_DIR}/test-pdt" ".f90")
        file (WRITE "${_TEMPFILE}" "${SOURCE_CODE_KIND}")
        try_compile(_SUPPORTS_PDT ${CMAKE_BINARY_DIR} "${_TEMPFILE}")
        file (REMOVE "${_TEMPFILE}")

        set(Fortran_SUPPORTS_PDT_KIND ${_SUPPORTS_PDT} CACHE BOOL "")
        mark_as_advanced(Fortran_SUPPORTS_PDT_KIND)

        message(STATUS
            "Checking whether compiler supports PDT kind parameters -- ${MSG_${_SUPPORTS_PDT}}"
        )
    endif()

    if (NOT DEFINED Fortran_SUPPORTS_PDT_LEN)
        mktempname(_TEMPFILE "${CMAKE_BINARY_DIR}/test-pdt" ".f90")
        file (WRITE "${_TEMPFILE}" "${SOURCE_CODE_LEN}")
        try_compile(_SUPPORTS_PDT ${CMAKE_BINARY_DIR} "${_TEMPFILE}")
        file (REMOVE "${_TEMPFILE}")

        set(Fortran_SUPPORTS_PDT_LEN ${_SUPPORTS_PDT} CACHE BOOL "")
        mark_as_advanced(Fortran_SUPPORTS_PDT_LEN)

        message(STATUS
            "Checking whether compiler supports PDT len parameters -- ${MSG_${_SUPPORTS_PDT}}"
        )
    endif()

endfunction()
