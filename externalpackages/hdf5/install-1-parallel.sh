#!/bin/bash
set -eu


# Constants
#
VER="1.14.0"

PREFIX="${ISSM_DIR}/externalpackages/hdf5/install" # Set to location where external package should be installed

## Environnment
#
export CC=mpicc

# Download source
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/hdf5-${VER}.tar.gz" "hdf5-${VER}.tar.gz"

# Untar source
tar -zxvf hdf5-${VER}.tar.gz

# Cleanup
rm -rf install src
mkdir install src

# Move source to 'src' directory
mv hdf5-${VER}/* src/
rm -rf hdf5-${VER}

# Configure
cd src
./configure \
	--prefix="${PREFIX}" \
	--disable-dependency-tracking \
	--disable-static \
	--enable-parallel \
	--with-zlib="${ZLIB_ROOT}" \
	--enable-hl

# Compile and install
#
if [ $# -eq 0 ]; then
	make
	make install
else
	make -j $1
	make -j $1 install
fi
