# CMake generated Testfile for 
# Source directory: /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src
# Build directory: /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
include("/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/EnforceConfig.cmake")
add_test(SystemInformationNew "/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/bin/cmake" "--system-information" "-G" "Unix Makefiles")
set_tests_properties(SystemInformationNew PROPERTIES  _BACKTRACE_TRIPLES "/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/CMakeLists.txt;853;add_test;/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/CMakeLists.txt;0;")
subdirs("Source/kwsys")
subdirs("Utilities/std")
subdirs("Utilities/KWIML")
subdirs("Utilities/cmlibrhash")
subdirs("Utilities/cmzlib")
subdirs("Utilities/cmcurl")
subdirs("Utilities/cmnghttp2")
subdirs("Utilities/cmexpat")
subdirs("Utilities/cmbzip2")
subdirs("Utilities/cmzstd")
subdirs("Utilities/cmliblzma")
subdirs("Utilities/cmlibarchive")
subdirs("Utilities/cmjsoncpp")
subdirs("Utilities/cmlibuv")
subdirs("Source/CursesDialog/form")
subdirs("Source")
subdirs("Utilities")
subdirs("Tests")
subdirs("Auxiliary")
