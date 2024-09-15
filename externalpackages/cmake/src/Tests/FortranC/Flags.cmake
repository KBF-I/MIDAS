set(src "/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/FortranC")
set(bld "/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/FortranC/Flags")

# Create wrapper scripts for the compilers that check for expected
# flags, remove them, and invoke the real compiler.
set(ID "CC")
set(COMMAND "/Library/Developer/CommandLineTools/usr/bin/clang")
configure_file("${src}/test_opt.sh.in" "${bld}/cc.sh" @ONLY)
set(ID "FC")
set(COMMAND "/opt/homebrew/bin/gfortran")
configure_file("${src}/test_opt.sh.in" "${bld}/fc.sh" @ONLY)
set(ID)
set(COMMAND)

set(make_program "/usr/bin/make")
if(make_program)
  set(maybe_make_program "-DCMAKE_MAKE_PROGRAM=${make_program}")
endif()

execute_process(
  WORKING_DIRECTORY "${bld}"
  COMMAND ${CMAKE_COMMAND} "${src}" -G "Unix Makefiles"
                           -A ""
                           -T ""
                           ${maybe_make_program}
                           "-DFortranC_TEST_FLAGS=1"
                           "-DCMAKE_C_COMPILER=${bld}/cc.sh"
                           "-DCMAKE_C_FLAGS:STRING="
                           "-DCMAKE_Fortran_COMPILER=${bld}/fc.sh"
                           "-DCMAKE_Fortran_FLAGS:STRING="
  RESULT_VARIABLE result
  )

if(NOT "${result}" STREQUAL "0")
  message(FATAL_ERROR "Configuration failed: ${result}")
endif()
