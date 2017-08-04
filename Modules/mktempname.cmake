function(mktempname fname)
    if (ARGC GREATER 2)
        set(_suffix ${ARGV2})
    else ()
        set(_suffix ".tmp")
    endif ()

    if (ARGC GREATER 1)
        set(_prefix "${ARGV1}")
    else ()
        # Note: do not use file name with leading dot by default, as this
        # will break CMake's try_compile() with some generators
        set(_prefix "cmake")
    endif ()

    set(_counter 0)
    while(EXISTS "${_prefix}-${_counter}${_suffix}")
        math(EXPR _counter "${_counter} + 1")
    endwhile()

    set(${fname} "${_prefix}-${_counter}${_suffix}" PARENT_SCOPE)
endfunction()
