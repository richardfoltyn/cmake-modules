# Script to build BLAS95 and LAPACK95 interfaces for gfortran

CMake script to create the Fortran 95 interfaces to BLAS and LAPACK
routines shipped with 
Intel's [Math Kernel Library (MKL)](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl.html).

Intel ships these only for their own compilers that are part of OneAPI,
but users have to build these interfaces manually for other compilers
such as `gfortran`.

## Required packages

At least the MKL runtime and development components of Intel oneAPI need to be installed.

### Ubuntu

#### Bash
```bash
MKL_VERSION="202x.y.z"
sudo apt install -V intel-oneapi-mkl-$MKL_VERSION \
    intel-oneapi-mkl-devel-$MKL_VERSION
```

#### Fish
```fish
set MKL_VERSION "202x.y.z"
sudo apt install -V intel-oneapi-mkl-$MKL_VERSION \
    intel-oneapi-mkl-devel-$MKL_VERSION
```

### Fedora

#### Bash
```bash
MKL_VERSION="202x.y.z"
sudo dnf install intel-oneapi-mkl-$MKL_VERSION \
    intel-oneapi-mkl-devel-$MKL_VERSION
```

#### Fish
```fish
set MKL_VERSION "202x.y.z"
sudo dnf install intel-oneapi-mkl-$MKL_VERSION \
    intel-oneapi-mkl-devel-$MKL_VERSION
```

## Installation

Installing the Fortran 95 interface definitions is only relevant
on Linux, as on Windows `gfortran` is not supported by MKL.

The following steps are required to build the module files and may need to 
be adapted to your environment:

### Environment Setup

#### Bash
```bash
GCC_VERSION=16
MKL_VERSION=2026.0

MKL_ROOT=/opt/intel/oneapi/mkl/${MKL_VERSION}
INSTALL_PREFIX="${HOME}/.local/share/mkl/${MKL_VERSION}/gnu/${GCC_VERSION}/"
SRC_DIR="${HOME}/repos/cmake-modules/mkl95"

BUILD_DIR="$HOME/build/gnu/${GCC_VERSION}/mkl95-${MKL_VERSION}"

mkdir -p "${BUILD_DIR}" || exit
cd "${BUILD_DIR}"
```

#### Fish
```fish
set GCC_VERSION 16
set MKL_VERSION 2026.0

set MKL_ROOT /opt/intel/oneapi/mkl/$MKL_VERSION
set INSTALL_PREFIX $HOME/.local/share/mkl/$MKL_VERSION/gnu/$GCC_VERSION/
set SRC_DIR $HOME/repos/cmake-modules/mkl95

set BUILD_DIR $HOME/build/gnu/$GCC_VERSION/mkl95-$MKL_VERSION

mkdir -p $BUILD_DIR; or exit
cd $BUILD_DIR
```

### Ubuntu

Specify the compilers explicitly:

#### Bash
```bash
CC=gcc-${GCC_VERSION} FC=gfortran-${GCC_VERSION} \
cmake -DMKL_ROOT="${MKL_ROOT}" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    "${SRC_DIR}"
```

#### Fish
```fish
env CC=gcc-$GCC_VERSION FC=gfortran-$GCC_VERSION \
cmake -DMKL_ROOT="$MKL_ROOT" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    "$SRC_DIR"
```

### Fedora

Fedora does not provide multiple versions of GCC in its repositories, so there 
the default compilers should be used.

#### Bash
```bash
cmake -DMKL_ROOT="${MKL_ROOT}" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    "${SRC_DIR}"
```

#### Fish
```fish
cmake -DMKL_ROOT="$MKL_ROOT" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    "$SRC_DIR"
```

### Build & Install

To compile and install the modules, run
```bash
cmake --build . -j 32
cmake --install .
```
