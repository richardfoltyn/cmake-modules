program lapack95_link_test

    use F95_PRECISION, only: DP
    use lapack95, only: gesvd

    real (DP) :: a(2,2), s(2)
    integer :: info

    a = reshape([real (DP) :: 1,2,3,4], shape=[2,2])

    call gesvd (a, s, info=info)

end program
