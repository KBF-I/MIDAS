cmake_minimum_required(VERSION 2.8.10)

set(CTEST_SOURCE_DIRECTORY "/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/VSProjectInSubdir")
set(CTEST_BINARY_DIRECTORY "/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/CTestBuildCommandProjectInSubdir/Nested")
set(CTEST_CMAKE_GENERATOR "Unix Makefiles")
set(CTEST_BUILD_CONFIGURATION "Release")

ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
ctest_start(Experimental)
ctest_configure(OPTIONS "-DCMAKE_MAKE_PROGRAM:FILEPATH=/usr/bin/make")
ctest_build(TARGET test)
