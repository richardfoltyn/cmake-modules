program lapack95_link_test

    use F95_PRECISION, only: DP
    use blas95, only: gemm

    real (DP), dimension(1,1) :: a, b, c

    a = 1
    b = 2

    call gemm (a, b, c)

end program
