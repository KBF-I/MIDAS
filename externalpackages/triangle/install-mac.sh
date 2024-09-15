#!/bin/bash
set -eu


# Constants
#
export PREFIX="${ISSM_DIR}/externalpackages/triangle/install" # Set to location where external package should be installed

# Cleanup
rm -rf ${PREFIX} src
mkdir -p ${PREFIX} ${PREFIX}/include ${PREFIX}/lib src

# Download source
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/triangle.zip" "triangle.zip"

# Unpack source
unzip triangle.zip -d src

# Copy customized source files to 'src' directory
cp configs/makefile src
cp configs/triangle.h src
cp configs/mac/configure.make src

# Compile
cd src
make shared

# Install
cd ..
cp src/libtriangle.* ${PREFIX}/lib
cp src/triangle.h ${PREFIX}/include

# Cleanup
rm -rf src
