program mkltest95

    use, intrinsic :: iso_fortran_env, only: real64
    use blas95, only: gemm
    use lapack95, only: gels

    integer, parameter :: PREC = real64

    integer, parameter :: m = 10, k = 6, n = 4
    real (PREC) :: a(m,k), b(k,n), c(m,n), d(m,1)
    integer :: info

    call random_number (a)
    call random_number (b)
    call random_number (d)

    call gemm (a, b, c)
    call gels (a, d, info=info)

    print *, "Linking against BLAS95 and LAPACK95 routines works"


end program
