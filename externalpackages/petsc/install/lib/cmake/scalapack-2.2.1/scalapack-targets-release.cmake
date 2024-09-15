#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "scalapack" for configuration "Release"
set_property(TARGET scalapack APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(scalapack PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libscalapack.2.2.1.dylib"
  IMPORTED_SONAME_RELEASE "/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/petsc/install/lib/libscalapack.2.2.dylib"
  )

list(APPEND _IMPORT_CHECK_TARGETS scalapack )
list(APPEND _IMPORT_CHECK_FILES_FOR_scalapack "${_IMPORT_PREFIX}/lib/libscalapack.2.2.1.dylib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
