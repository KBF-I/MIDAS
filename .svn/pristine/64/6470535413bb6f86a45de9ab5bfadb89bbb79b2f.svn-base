#!/bin/bash
set -eu


## Constants
#
VER="3.5.3"

## Environment
#
export PREFIX="${ISSM_DIR}/externalpackages/gdal/install" # NOTE: Need to export this to properly set destination root for Python libraries on macOS (should not affect Linux build). Set to location where external package should be installed.

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
	--with-libz="${ZLIB_ROOT}" \
	--with-netcdf="${NETCDF_ROOT}" \
	--with-proj="${PROJ_ROOT}"

# Compile and install
if [ $# -eq 0 ]; then
	make
	make install
else
	make -j $1
	make -j $1 install
fi
