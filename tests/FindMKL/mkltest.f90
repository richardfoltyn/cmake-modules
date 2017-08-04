program mkltest

    use, intrinsic :: iso_fortran_env, only: real64

    integer, parameter :: PREC = real64
    external :: dgemm

    integer, parameter :: m = 5, k = 6, n = 10
    real (PREC) :: a(m,k), b(k,n), c(m,n)
    character (*), parameter :: transa = 'N', transb = 'N'
    real (PREC) :: alpha, beta
    integer :: lda, ldb, ldc

    call random_number (a)
    call random_number (b)
    call random_number (c)

    alpha = 1.0_PREC
    beta = 0.0_PREC
    lda = m
    ldb = k
    ldc = m

    call dgemm (transa, transb, m, n, k, alpha, a, lda, b, ldb, beta, c, ldc)

    print *, "Linking against MKL BLAS routines works"

end program
