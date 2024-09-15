#!/bin/bash
set -eu

## Constants
#
VER=3.3

PREFIX="${ISSM_DIR}/externalpackages/m1qn3/install" # Set to location where external package should be installed

# Cleanup
rm -rf ${PREFIX} src
mkdir -p ${PREFIX} src

# Download source
$ISSM_DIR/scripts/DownloadExternalPackage.sh "https://issm.ess.uci.edu/files/externalpackages/m1qn3-${VER}-distrib.tgz" "m1qn3-${VER}-distrib.tgz"

# Unpack source
tar -xzf m1qn3-${VER}-distrib.tgz

# Move source to 'src' directory
mv m1qn3-${VER}-distrib/* src
rm -rf m1qn3-${VER}-distrib

#patch
#patch -u -b src/src/m1qn3.f -i patch/m1qn3.f.patch
patch src/src/m1qn3.f patch/m1qn3.f.patch

if [ -z "${FC-}" ]; then
	if which ifort >/dev/null; then
		FC="ifort"
	else
		FC="gfortran"
		if [ `uname` == "Darwin" ]; then
			FC="gfortran -arch x86_64"
		fi
	fi
fi
echo "Using fortran compiler: $FC"

# Compile and install
cd src/src/
(
cat << EOF
LIB_EXT=a
FC=$FC
install: libm1qn3.\$(LIB_EXT)
	cp libm1qn3.\$(LIB_EXT) ${PREFIX}
OBJECTS= m1qn3.o
libm1qn3.\$(LIB_EXT): \$(OBJECTS)
	ar -r libm1qn3.\$(LIB_EXT) \$(OBJECTS) 
	ranlib libm1qn3.\$(LIB_EXT) 
%.o: %.f
	\$(FC) \$(FFLAGS) -fPIC -c $< -o \$@
clean: 
	rm -rf *.o *.\$(LIB_EXT)
EOF
) > Makefile
make

cd ../blas
(
cat << EOF
LIB_EXT=a
FC=$FC
install: libddot.\$(LIB_EXT)
	cp libddot.\$(LIB_EXT) ${PREFIX}
OBJECTS= ddot.o
libddot.\$(LIB_EXT): \$(OBJECTS)
	ar -r libddot.\$(LIB_EXT) \$(OBJECTS) 
	ranlib libddot.\$(LIB_EXT) 
%.o: %.f
	\$(FC) \$(FFLAGS) -fPIC -c $< -o \$@
clean: 
	rm -rf *.o *.\$(LIB_EXT)
EOF
) > Makefile
make
