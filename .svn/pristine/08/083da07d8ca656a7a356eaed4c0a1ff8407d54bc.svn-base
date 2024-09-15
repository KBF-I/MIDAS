#!/bin/bash
set -eu


# Constants
#
INSTALL_DIR="install"

# Cleanup
rm -rf ${INSTALL_DIR} src
mkdir ${INSTALL_DIR} ${INSTALL_DIR}/include ${INSTALL_DIR}/lib src

# Download source
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/triangle.zip" "triangle.zip"

# Unpack source
unzip triangle.zip -d src

# Copy customized source files to 'src' directory
cp configs/makefile src
cp configs/triangle.h src
cp configs/linux/configure.make src

# Compile
cd src
make shared

# Install
cd ..
cp src/libtriangle.* ${INSTALL_DIR}/lib
cp src/triangle.h ${INSTALL_DIR}/include

# Cleanup
rm -rf src
