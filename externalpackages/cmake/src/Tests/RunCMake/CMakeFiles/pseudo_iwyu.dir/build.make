# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.19

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Disable VCS-based implicit rules.
% : %,v


# Disable VCS-based implicit rules.
% : RCS/%


# Disable VCS-based implicit rules.
% : RCS/%,v


# Disable VCS-based implicit rules.
% : SCCS/s.%


# Disable VCS-based implicit rules.
% : s.%


.SUFFIXES: .hpux_make_needs_suffix_list


# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Bootstrap.cmk/cmake

# The command to remove a file.
RM = /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Bootstrap.cmk/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src

# Include any dependencies generated for this target.
include Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/depend.make

# Include the progress variables for this target.
include Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/progress.make

# Include the compile flags for this target's objects.
include Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/flags.make

Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.o: Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/flags.make
Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.o: Tests/RunCMake/pseudo_iwyu.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.o"
	cd /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake && /Library/Developer/CommandLineTools/usr/bin/clang $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.o -c /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake/pseudo_iwyu.c

Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.i"
	cd /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake && /Library/Developer/CommandLineTools/usr/bin/clang $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake/pseudo_iwyu.c > CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.i

Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.s"
	cd /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake && /Library/Developer/CommandLineTools/usr/bin/clang $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake/pseudo_iwyu.c -o CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.s

# Object files for target pseudo_iwyu
pseudo_iwyu_OBJECTS = \
"CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.o"

# External object files for target pseudo_iwyu
pseudo_iwyu_EXTERNAL_OBJECTS =

Tests/RunCMake/pseudo_iwyu: Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/pseudo_iwyu.c.o
Tests/RunCMake/pseudo_iwyu: Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/build.make
Tests/RunCMake/pseudo_iwyu: Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking C executable pseudo_iwyu"
	cd /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/pseudo_iwyu.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/build: Tests/RunCMake/pseudo_iwyu

.PHONY : Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/build

Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/clean:
	cd /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake && $(CMAKE_COMMAND) -P CMakeFiles/pseudo_iwyu.dir/cmake_clean.cmake
.PHONY : Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/clean

Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/depend:
	cd /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/cmake/src/Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : Tests/RunCMake/CMakeFiles/pseudo_iwyu.dir/depend

