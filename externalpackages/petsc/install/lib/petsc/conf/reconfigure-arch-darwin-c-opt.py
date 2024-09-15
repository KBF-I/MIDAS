#!/opt/homebrew/opt/python@3.10/bin/python3.10
if __name__ == '__main__':
  import sys
  import os
  sys.path.insert(0, os.path.abspath('config'))
  import configure
  configure_options = [
    '--LDFLAGS=-Wl,-no_compact_unwind',
    '--PETSC_DIR=/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/petsc/src',
    '--download-fblaslapack=1',
    '--download-metis=1',
    '--download-mpich=1',
    '--download-mumps=1',
    '--download-parmetis=1',
    '--download-scalapack=1',
    '--download-zlib=1',
    '--prefix=/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/petsc/install',
    '--with-debugging=0',
    '--with-pic=1',
    '--with-ssl=0',
    '--with-valgrind=0',
    '--with-x=0',
    'PETSC_ARCH=arch-darwin-c-opt',
  ]
  configure.petsc_configure(configure_options)
