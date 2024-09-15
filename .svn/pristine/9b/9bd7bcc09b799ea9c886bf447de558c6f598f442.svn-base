#!/bin/bash
set -eu


## TODO
#	- May want to supply path to Python instead of, effectively, using result of `which python`
#

## Constants
#
VER="3.5.3"

## Environment
#
export CC=mpicc
export CXXFLAGS="-std=c++11"
export CXX=mpicxx
export LIBS="-lsqlite3 -lhdf5_hl -lhdf5"
export PREFIX="${ISSM_DIR}/externalpackages/gdal/install" # Need this to properly set destination root for Python libraries on macOS (should not affect Linux build; do not need for this configuration, but including it for consistency)

# Cleanup
rm -rf ${PREFIX} src
mkdir -p ${PREFIX} src

# Download source
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/gdal-${VER}.tar.gz" "gdal-${VER}.tar.gz"

# Unpack source
tar -zxvf gdal-${VER}.tar.gz

# Move source into 'src' directory
mv gdal-${VER}/* src
rm -rf gdal-${VER}

# Configure
cd src
./configure \
	--prefix="${PREFIX}" \
	--enable-fast-install \
	--disable-shared \
	--without-ld-shared \
	--enable-static \
	--with-pic \
	--with-python="python3" \
	--with-curl="${CURL_ROOT}/bin/curl-config" \
	--with-jpeg=internal \
	--with-libz="${ZLIB_ROOT}" \
	--with-netcdf="${NETCDF_ROOT}" \
	--with-pcre=no \
	--with-pg=no \
	--with-png=internal \
	--with-proj="${PROJ_ROOT}" \
	--with-zstd=no

# Compile and install
if [ $# -eq 0 ]; then
	make
	make install
else
	make -j $1
	make -j $1 install
fi
