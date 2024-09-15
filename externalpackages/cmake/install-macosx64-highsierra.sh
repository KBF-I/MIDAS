#!/bin/bash
set -eu
VER="3.14.5"

#Some cleanup
rm -rf install cmake-$VER.tar.gz
mkdir install

#Download from ISSM server
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/cmake-$VER.tar.gz" "cmake-$VER.tar.gz"

#Untar
tar -zxvf cmake-$VER.tar.gz

#Move cmake into install directory
mv cmake-$VER/* install
rm -rf cmake-$VER

#Compile cmake
cd install
./bootstrap --prefix=$ISSM_DIR/externalpackages/cmake/install

if [ $# -eq 0 ]; then
	make
else
	make -j $1;
fi
make install
