#!/bin/bash
set -eu


# Constants
#
VER="1.2.11"

# Download source
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/zlib-${VER}.tar.gz" "zlib-${VER}.tar.gz"

# Unpack source
tar -zxvf zlib-$VER.tar.gz

# Cleanup
rm -rf install src
mkdir install src

# Move source to 'src' directory
mv zlib-$VER/* src/
rm -rf zlib-$VER

# Configure
cd src
./configure \
 	--prefix="${ISSM_DIR}/externalpackages/zlib/install"

# Compile and install
if [ $# -eq 0 ]; then
	make
	make install
else
	make -j $1
	make -j $1 install
fi

# Return to initial directory
cd ..
