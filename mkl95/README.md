

# Installation

Installing the Fortran 95 interface definitions is only relevant
on Linux, as on Windows `gfortran` is not supported by MKL.

The following steps are required to build the module files:

    mkdir /path/to/build/directory
    cd /path/to/build/directory
    cmake -DMKL_ROOT=/opt/intel/compilers_and_libraries_20XX/linux/mkl \
        -DCMAKE_INSTALL_PREFIX=$HOME/.local/share/mkl/gnu/x/20XX \
        $HOME/repos/cmake-modules/mkl95
    make -j8
    make install
    
