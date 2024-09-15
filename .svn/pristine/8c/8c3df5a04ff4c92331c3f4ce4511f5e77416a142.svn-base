#!/bin/bash
set -eu


## Constants
#
VER="6.0.0"

# Find libgfortran so that we do not have to hardcode it.
#
# TODO:
# - Move this to etc/environment.sh
#
echo "Finding libgfortran..."
LIBGFORTRAN=$(find /usr /opt -name libgfortran* 2>/dev/null | egrep -n libgfortran.a | egrep -v i386 | sed "s/[0-9]*://g" | head -1)
LIBGFORTRAN_ROOT=${LIBGFORTRAN%/*}

# Environment
#
export CC=mpicc
export PREFIX="${ISSM_DIR}/externalpackages/gmt/install" # NOTE: Need to export this to be picked up by customized ConfigUser.cmake (see below). Set to location where external package should be installed.

# Download source
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/gmt-${VER}.tar.gz" "gmt-${VER}.tar.gz"

# Unpack source
tar -zxvf gmt-${VER}.tar.gz

# Cleanup
rm -rf ${PREFIX} src
mkdir -p ${PREFIX} src

# Move source to 'src' directory
mv gmt-${VER}/* src
rm -rf gmt-${VER}

# Copy custom configuration files
cp ./configs/6.0/mac/cmake/ConfigUser.cmake ./src/cmake

# Configure
cd src
mkdir build
cd build

# NOTE:
# - There is a CMake variable named CURL_ROOT in src/cmake/ConfigUser.cmake
#	that, ostensibly, allows for supplying the path to curl when it is in a
#	non-standard location. That said, newer versions of CMake will ignore said
#	variable and instead try to find curl itself. Passing in the two options
#	below overrides this behavior.
#
cmake \
	-DBLAS_LIBRARIES="-L${BLAS_ROOT}/lib;-lfblas;-L${LIBGFORTRAN_ROOT};-lgfortran" \
	-DCURL_INCLUDE_DIR="${CURL_ROOT}/include" \
	-DCURL_LIBRARY="-L${CURL_ROOT}/lib;-lcurl" \
	-DLAPACK_LIBRARIES="-L${LAPACK_ROOT}/lib;-lflapack;-L${LIBGFORTRAN_ROOT};-lgfortran" \
	..

# Compile and install
if [ $# -eq 0 ]; then
	make
	make install
else
	make -j $1
	make -j $1 install
fi
