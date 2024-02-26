# Script to build BLAS95 and LAPACK95 interfaces for gfortran

CMake script to create the Fortran 95 interfaces to BLAS and LAPACK
routines shipped with 
Intel's [Math Kernel Library (MKL)](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl.html).

Intel ships these only for their own compilers that are part of OneAPI,
but users have to build these interfaces manually for other compilers
such as `gfortran`.

## Required packages

At least the MKL components of Intel oneAPI needs to be installed:

```bash
MKL_VERSION="202x.y.z"
sudo apt install -V intel-oneapi-mkl-${MKL_VERSION}
```

In addition, on Linux (Ubuntu) some of the MKL development packages may need to \
be installed to provide the necessary Fortran source files (this step can be skipped
if the entire set of MKL packages was installed).

```bash
sudo apt install -V intel-oneapi-mkl-common-devel-${MKL_VERSION}
```

## Installation

Installing the Fortran 95 interface definitions is only relevant
on Linux, as on Windows `gfortran` is not supported by MKL.

The following steps are required to build the module files and may need to 
be adapted to your environment:

```bash
GCC_VERSION=12
MKL_VERSION=2024.0

MKL_ROOT=/opt/intel/oneapi/mkl/${MKL_VERSION}
INSTALL_PREFIX="${HOME}/.local/share/mkl/${MKL_VERSION}/gnu/${GCC_VERSION}/"
SRC_DIR="${HOME}/repos/cmake-modules/mkl95"

BUILD_DIR="$HOME/build/gnu/${GCC_VERSION}/mkl95-${MKL_VERSION}"

mkdir -p "${BUILD_DIR}" || exit
cd "${BUILD_DIR}"

CC=gcc-${GCC_VERSION} FC=gfortran-${GCC_VERSION} \
cmake -DMKL_ROOT="${MKL_ROOT}" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    "${SRC_DIR}"
```

To compile and install the modules, run
```bash
cmake --build .
cmake --install .
```
