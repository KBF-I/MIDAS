#!/bin/bash
set -eu


## Constants
#
VER="6.0.0"

# Find libgfortran and libgcc so we do not have to hardcode them
#
# TODO:
# - Move this to etc/environment.sh
# - Test if -static-libgfortran flag will avoid all of this.
# - Otherwise, refactor this to work with other gfortran installations.
#
echo "Finding libgfortran..."
LIBGFORTRAN=$(find /usr -name libgfortran* 2>/dev/null | egrep -n libgfortran.a | sed "s/[0-9]*://g" | head -1)
LIBGFORTRAN_ROOT=${LIBGFORTRAN%/*}
LIBGCC=$(find ${LIBGFORTRAN_ROOT} -name libgcc* 2>/dev/null | egrep -n libgcc.a | sed "s/[0-9]*://g" | head -1)

GDAL_EXTRA_LIBS="-lstdc++" # Determined by running `$GDAL_ROOT/bin/gdal-config --dep-libs` then removing duplicate libs
NETCDF_EXTRA_LIBS="-lm -ldl -lz" # `$NETCDF_ROOT/bin/nc-config --libs` does not report certain dependencies of certain static libraries (see also customized configuration file ./configs/6.0/static/cmake/modules/FindNETCDF.cmake)

# Environment
#
export CC=mpicc
export CURL_INCLUDE_DIRS="${CURL_ROOT}/include"
export CURL_LIBRARIES="${CURL_ROOT}/lib/libcurl.a;/usr/lib/x86_64-linux-gnu/libssl.a;/usr/lib/x86_64-linux-gnu/libcrypto.a"
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
cp ./configs/6.0/static/linux/cmake/ConfigUser.static.cmake ./src/cmake/ConfigUser.cmake
cp ./configs/6.0/static/cmake/modules/FindGDAL.cmake ./src/cmake/modules
cp ./configs/6.0/static/cmake/modules/FindGSHHG.cmake ./src/cmake/modules
cp ./configs/6.0/static/cmake/modules/FindNETCDF.cmake ./src/cmake/modules
cp ./configs/6.0/static/src/CMakeLists.txt ./src/src

# Configure
cd src
mkdir build
cd build

# NOTE:
# - The CMake modules used to find and probe the BLAS and LAPACK libraries do
#	not seem to handle the situation where BLAS_LIBRARY and LAPACK_LIBRARY are
#	set but we are working with static libraries
#	(see customized ConfigUser.static.cmake). Using BLAS_LIBRARIES and
#	LAPACK_LIBRARIES is a workaround.
#
cmake \
	-DBLAS_LIBRARIES="${BLAS_ROOT}/lib/libfblas.a;${LIBGFORTRAN_ROOT}/libgfortran.a;${LIBGFORTRAN_ROOT}/libquadmath.a;${LIBGCC}" \
	-DCURL_INCLUDE_DIR="${CURL_ROOT}/include" \
	-DCURL_LIBRARY="${CURL_ROOT}/lib/libcurl.a" \
	-DGDAL_EXTRA_LIBS="${GDAL_EXTRA_LIBS}" \
	-DLAPACK_LIBRARIES="${LAPACK_ROOT}/lib/libflapack.a;${LIBGFORTRAN_ROOT}/libgfortran.a;${LIBGFORTRAN_ROOT}/libquadmath.a;${LIBGCC}" \
	-DNETCDF_EXTRA_LIBS="${NETCDF_EXTRA_LIBS}" \
	..

# Compile and install
if [ $# -eq 0 ]; then
	make
	make install
else
	make -j $1
	make -j $1 install
fi

# Make necessary link on RHEL
if [[ -d ${PREFIX}/lib64 && ! -d ${PREFIX}/lib ]]; then
	cd ${PREFIX}
	ln -s ./lib64 ./lib
fi
