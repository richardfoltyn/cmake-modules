

# Installation

Installing the Fortran 95 interface definitions is only relevant
on Linux, as on Windows `gfortran` is not supported by MKL.

The following steps are required to build the module files:

```bash
mkdir /path/to/build/directory
cd /path/to/build/directory

MKL_ROOT=/opt/intel/oneapi/mkl/latest
GCC_VERSION=11
MKL_VERSION=2023
INSTALL_PREFIX="${HOME}/.local/share/mkl/${MKL_VERSION}/gnu/${GCC_VERSION}/"
SRCDIR="${HOME}/repos/cmake-modules/mkl95"

cmake -DMKL_ROOT="${MKL_ROOT}" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    "${SRCDIR}"
    
make -j8
make install
```
