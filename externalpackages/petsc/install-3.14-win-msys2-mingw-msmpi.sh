#!/bin/bash
set -u # NOTE: Do not set -e as it will cause this script to fail when there are errors in underlying Python scripts

# NOTE:
# - You must install various needed packages with,
#
#		pacman -S mingw-w64-x86_64-toolchain python
#
# - You must use MSYS2 MinGW 64-bit version of cmake to be able to install 
#	external packages correctly,
#
#		pacman -R mingw-w64-x86_64-cmake
#
# Sources:
# - https://gitlab.com/petsc/petsc/-/issues/820#note_487483240
#

## Constants
#
VER="3.14.6"

MAKEFILE_GENERATOR='-G "MSYS Makefiles"'
PETSC_DIR="${ISSM_DIR}/externalpackages/petsc/src" # DO NOT CHANGE THIS
PREFIX="${ISSM_DIR}/externalpackages/petsc/install" # Set to location where external package should be installed

# Download source
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/petsc-lite-${VER}.tar.gz" "petsc-${VER}.tar.gz"

# Unpack source
tar -zxvf petsc-${VER}.tar.gz

# Cleanup
rm -rf ${PREFIX} ${PETSC_DIR}
mkdir -p ${PETSC_DIR}

# Move source to $PETSC_DIR
mv petsc-${VER}/* ${PETSC_DIR}
rm -rf petsc-${VER}

# Copy customized source files to $PETSC_DIR
cp configs/3.14/win/msys2/mingw64/config/configure.py ${PETSC_DIR}/config

# Configure
# - Cannot use --with-fpic option when compiling static libs,
#
#		Cannot determine compiler PIC flags if shared libraries is turned off
#		Either run using --with-shared-libraries or --with-pic=0 and supply the
#		compiler PIC flag via CFLAGS, CXXXFLAGS, and FCFLAGS
#
# - Added -fallow-argument-mismatch option to FFLAGS in order to clear "Error: 
#	Rank mismatch between actual argument at [...]"
# - Added -fallow-invalid-boz option to FFLAGS in order to clear "Error: BOZ 
#	literal constant at [...]"
# - Argument to --with-mpi-include must be a list or it gets expanded 
#	incorrectly
#
cd ${PETSC_DIR}
./config/configure.py \
	--prefix="${PREFIX}" \
	--PETSC_DIR="${PETSC_DIR}" \
	--CFLAGS="-fPIC -Wno-error=implicit-function-declaration" \
	--CXXFLAGS="-fPIC" \
	--FFLAGS="-fPIC -fallow-argument-mismatch -fallow-invalid-boz" \
	--with-shared-libraries=0 \
	--with-debugging=0 \
	--with-valgrind=0 \
	--with-x=0 \
	--with-ssl=0 \
	--with-proc-filesystem=0 \
	--with-mpiexec="${MPIEXEC_DIR}/mpiexec.exe" \
	--with-mpi-lib="-L${MSMPI_ROOT}/lib -lmsmpi" \
	--with-mpi-include="${MSMPI_ROOT}/include" \
	--download-fblaslapack=1 \
	--download-metis=1 \
	--download-metis-cmake-arguments="${MAKEFILE_GENERATOR}" \
	--download-parmetis=1 \
	--download-parmetis-cmake-arguments="${MAKEFILE_GENERATOR}" \
	--download-scalapack=1 \
	--download-scalapack-cmake-arguments="${MAKEFILE_GENERATOR}" \
	--download-mumps=1

# Compile and install
make
make install
