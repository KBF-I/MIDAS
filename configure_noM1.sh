export FFLAGS=" -arch arm64"
export CFLAGS=" -arch arm64"
export LDFLAGS=" -arch arm64"
export CXXFLAGS=" -arch arm64"

./configure \
   --without-Love --without-kml --without-Sealevelchange \
   --prefix=$ISSM_DIR \
   --without-wrappers \
   --enable-debugging \
   --enable-development \
   --with-triangle-dir="$ISSM_DIR/externalpackages/triangle/install" \
   --with-mpi-include="$ISSM_DIR/externalpackages/petsc/install/" \
   --with-mpi-libflags="-L$ISSM_DIR/externalpackages/petsc/install/ -lmpich" \
   --with-petsc-dir="$ISSM_DIR/externalpackages/petsc/install" \
   --with-metis-dir="$ISSM_DIR/externalpackages/petsc/install" \
   --with-blas-lapack-dir="$ISSM_DIR/externalpackages/petsc/install" \
   --with-scalapack-dir="$ISSM_DIR/externalpackages/petsc/install/" \
   --with-mumps-dir="$ISSM_DIR/externalpackages/petsc/install/" \
   --with-m1qn3-dir="$ISSM_DIR/externalpackages/m1qn3/install" \
   --with-fortran-lib="-L/opt/homebrew/Cellar/gcc/12.2.0/lib/gcc/current/ -lgfortran" \
   --with-numthreads=4
