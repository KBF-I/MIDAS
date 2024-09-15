#!/bin/bash
set -eu


# Dependencies
# - MPI implementation (for parallel I/O support)
# - hdf5 (1.8.9 / 1.10.1 or later, for netCDF-4 support)
# - zlib (1.2.5 or later, for netCDF-4 compression)
# - curl (7.18.0 or later, for DAP remote access client support)
#
# Sources:
# - https://www.unidata.ucar.edu/software/netcdf/documentation/NUG/getting_and_building_netcdf.html#building
#
# NOTE:
# - Certain configuration tests fail if libraries are not supplied explicitly
#
# TODO:
# - Compile and link curl statically (issue with DAP and system libs on macOS 
#	with more restirctive Gatekeeper; see also --disable-dap option in 
#	configuration)
#

# Constants
#
VER="4.7.2"

PREFIX="${ISSM_DIR}/externalpackages/netcdf/install" # Set to location where external package should be installed

# Environment
#
export CC=mpicc
export CPPFLAGS="-I${ZLIB_ROOT}/include"

export ZLIB="${ZLIB_ROOT}/lib/libz.a"

# Download source
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/netcdf-c-${VER}.tar.gz" "netcdf-c-${VER}.tar.gz"

# Unpack source
tar -zxvf netcdf-c-${VER}.tar.gz

# Cleanup
rm -rf ${PREFIX} src
mkdir -p ${PREFIX} src

# Move source to 'src' directory
mv netcdf-c-${VER}/* src
rm -rf netcdf-c-${VER}

# Configure
cd src
./configure \
	--prefix="${PREFIX}" \
	--disable-shared \
	--disable-dependency-tracking \
	--enable-fast-install \
	--disable-doxygen \
	--enable-netcdf4 \
	--disable-dap \
	--disable-testsets \
	--disable-examples \
	--disable-filter-testing

# Compile and install
if [ $# -eq 0 ]; then
	make
	make install
else
	make -j $1
	make -j $1 install
fi
