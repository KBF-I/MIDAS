# CMake generated Testfile for 
# Source directory: /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Utilities/cmcurl
# Build directory: /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Utilities/cmcurl
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(curl "curltest" "http://open.cdash.org/user.php")
set_tests_properties(curl PROPERTIES  _BACKTRACE_TRIPLES "/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Utilities/cmcurl/CMakeLists.txt;1461;add_test;/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Utilities/cmcurl/CMakeLists.txt;0;")
subdirs("lib")
