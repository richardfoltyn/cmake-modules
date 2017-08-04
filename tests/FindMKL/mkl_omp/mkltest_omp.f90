program mkltest

    use, intrinsic :: iso_fortran_env, only: real64
    use omp_lib

    integer, parameter :: PREC = real64
    external :: dgemm

    integer, parameter :: niter = 1000
    integer, parameter :: m = 5, k = 6, n = 1
    real (PREC) :: a(m,k), b(k,niter), c(m,niter)
    character (*), parameter :: transa = 'N', transb = 'N'
    real (PREC) :: alpha, beta, s
    integer :: lda, ldb, ldc

    integer :: i, tid

    call random_number (a)
    call random_number (b)
    call random_number (c)

    alpha = 1.0_PREC
    beta = 0.0_PREC
    lda = m
    ldb = k
    ldc = m

    !$omp parallel default(shared) private(i, tid) reduction(+: s)
    !$omp do
    do i = 1, niter
        tid = omp_get_thread_num ()
        call dgemm (transa, transb, m, n, k, alpha, a, lda, b(:,i), ldb, beta, c(:,i), ldc)
        s = s + sum(c(:,i))
    end do
    !$omp end do
    !$omp end parallel

    print *, s
    print *, "Linking against MKL BLAS routines works"

end program
