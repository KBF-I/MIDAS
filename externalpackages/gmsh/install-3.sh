#!/bin/bash
set -eu


## Constants
#
VER="3.0.5"

# Cleanup
rm -rf install src
mkdir install src

# Download source
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/gmsh-${VER}-source.tgz" "gmsh-${VER}-source.tgz"

# Untar source
tar -xvzf gmsh-${VER}-source.tgz

# Move source to 'src' directory
mv gmsh-${VER}-source/* src
rm -rf gmsh-${VER}-source

# Configure
cd install
cmake ../src \
	-DCMAKE_INSTALL_PREFIX="${ISSM_DIR}/externalpackages/gmsh/install" \
	-DENABLE_MPI=1 \
	-DENABLE_BUILD_DYNAMIC=1 \
	-DENABLE_BUILD_SHARED=1

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
