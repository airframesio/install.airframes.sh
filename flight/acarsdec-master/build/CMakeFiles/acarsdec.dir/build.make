# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.27

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
CMAKE_COMMAND = /opt/homebrew/Cellar/cmake/3.27.8/bin/cmake

# The command to remove a file.
RM = /opt/homebrew/Cellar/cmake/3.27.8/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build

# Include any dependencies generated for this target.
include CMakeFiles/acarsdec.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/acarsdec.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/acarsdec.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/acarsdec.dir/flags.make

CMakeFiles/acarsdec.dir/acars.c.o: CMakeFiles/acarsdec.dir/flags.make
CMakeFiles/acarsdec.dir/acars.c.o: /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/acars.c
CMakeFiles/acarsdec.dir/acars.c.o: CMakeFiles/acarsdec.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/acarsdec.dir/acars.c.o"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/acarsdec.dir/acars.c.o -MF CMakeFiles/acarsdec.dir/acars.c.o.d -o CMakeFiles/acarsdec.dir/acars.c.o -c /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/acars.c

CMakeFiles/acarsdec.dir/acars.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing C source to CMakeFiles/acarsdec.dir/acars.c.i"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/acars.c > CMakeFiles/acarsdec.dir/acars.c.i

CMakeFiles/acarsdec.dir/acars.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling C source to assembly CMakeFiles/acarsdec.dir/acars.c.s"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/acars.c -o CMakeFiles/acarsdec.dir/acars.c.s

CMakeFiles/acarsdec.dir/acarsdec.c.o: CMakeFiles/acarsdec.dir/flags.make
CMakeFiles/acarsdec.dir/acarsdec.c.o: /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/acarsdec.c
CMakeFiles/acarsdec.dir/acarsdec.c.o: CMakeFiles/acarsdec.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building C object CMakeFiles/acarsdec.dir/acarsdec.c.o"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/acarsdec.dir/acarsdec.c.o -MF CMakeFiles/acarsdec.dir/acarsdec.c.o.d -o CMakeFiles/acarsdec.dir/acarsdec.c.o -c /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/acarsdec.c

CMakeFiles/acarsdec.dir/acarsdec.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing C source to CMakeFiles/acarsdec.dir/acarsdec.c.i"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/acarsdec.c > CMakeFiles/acarsdec.dir/acarsdec.c.i

CMakeFiles/acarsdec.dir/acarsdec.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling C source to assembly CMakeFiles/acarsdec.dir/acarsdec.c.s"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/acarsdec.c -o CMakeFiles/acarsdec.dir/acarsdec.c.s

CMakeFiles/acarsdec.dir/cJSON.c.o: CMakeFiles/acarsdec.dir/flags.make
CMakeFiles/acarsdec.dir/cJSON.c.o: /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/cJSON.c
CMakeFiles/acarsdec.dir/cJSON.c.o: CMakeFiles/acarsdec.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building C object CMakeFiles/acarsdec.dir/cJSON.c.o"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/acarsdec.dir/cJSON.c.o -MF CMakeFiles/acarsdec.dir/cJSON.c.o.d -o CMakeFiles/acarsdec.dir/cJSON.c.o -c /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/cJSON.c

CMakeFiles/acarsdec.dir/cJSON.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing C source to CMakeFiles/acarsdec.dir/cJSON.c.i"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/cJSON.c > CMakeFiles/acarsdec.dir/cJSON.c.i

CMakeFiles/acarsdec.dir/cJSON.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling C source to assembly CMakeFiles/acarsdec.dir/cJSON.c.s"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/cJSON.c -o CMakeFiles/acarsdec.dir/cJSON.c.s

CMakeFiles/acarsdec.dir/label.c.o: CMakeFiles/acarsdec.dir/flags.make
CMakeFiles/acarsdec.dir/label.c.o: /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/label.c
CMakeFiles/acarsdec.dir/label.c.o: CMakeFiles/acarsdec.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building C object CMakeFiles/acarsdec.dir/label.c.o"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/acarsdec.dir/label.c.o -MF CMakeFiles/acarsdec.dir/label.c.o.d -o CMakeFiles/acarsdec.dir/label.c.o -c /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/label.c

CMakeFiles/acarsdec.dir/label.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing C source to CMakeFiles/acarsdec.dir/label.c.i"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/label.c > CMakeFiles/acarsdec.dir/label.c.i

CMakeFiles/acarsdec.dir/label.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling C source to assembly CMakeFiles/acarsdec.dir/label.c.s"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/label.c -o CMakeFiles/acarsdec.dir/label.c.s

CMakeFiles/acarsdec.dir/msk.c.o: CMakeFiles/acarsdec.dir/flags.make
CMakeFiles/acarsdec.dir/msk.c.o: /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/msk.c
CMakeFiles/acarsdec.dir/msk.c.o: CMakeFiles/acarsdec.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building C object CMakeFiles/acarsdec.dir/msk.c.o"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/acarsdec.dir/msk.c.o -MF CMakeFiles/acarsdec.dir/msk.c.o.d -o CMakeFiles/acarsdec.dir/msk.c.o -c /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/msk.c

CMakeFiles/acarsdec.dir/msk.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing C source to CMakeFiles/acarsdec.dir/msk.c.i"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/msk.c > CMakeFiles/acarsdec.dir/msk.c.i

CMakeFiles/acarsdec.dir/msk.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling C source to assembly CMakeFiles/acarsdec.dir/msk.c.s"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/msk.c -o CMakeFiles/acarsdec.dir/msk.c.s

CMakeFiles/acarsdec.dir/output.c.o: CMakeFiles/acarsdec.dir/flags.make
CMakeFiles/acarsdec.dir/output.c.o: /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/output.c
CMakeFiles/acarsdec.dir/output.c.o: CMakeFiles/acarsdec.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building C object CMakeFiles/acarsdec.dir/output.c.o"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/acarsdec.dir/output.c.o -MF CMakeFiles/acarsdec.dir/output.c.o.d -o CMakeFiles/acarsdec.dir/output.c.o -c /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/output.c

CMakeFiles/acarsdec.dir/output.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing C source to CMakeFiles/acarsdec.dir/output.c.i"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/output.c > CMakeFiles/acarsdec.dir/output.c.i

CMakeFiles/acarsdec.dir/output.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling C source to assembly CMakeFiles/acarsdec.dir/output.c.s"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/output.c -o CMakeFiles/acarsdec.dir/output.c.s

CMakeFiles/acarsdec.dir/netout.c.o: CMakeFiles/acarsdec.dir/flags.make
CMakeFiles/acarsdec.dir/netout.c.o: /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/netout.c
CMakeFiles/acarsdec.dir/netout.c.o: CMakeFiles/acarsdec.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Building C object CMakeFiles/acarsdec.dir/netout.c.o"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/acarsdec.dir/netout.c.o -MF CMakeFiles/acarsdec.dir/netout.c.o.d -o CMakeFiles/acarsdec.dir/netout.c.o -c /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/netout.c

CMakeFiles/acarsdec.dir/netout.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing C source to CMakeFiles/acarsdec.dir/netout.c.i"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/netout.c > CMakeFiles/acarsdec.dir/netout.c.i

CMakeFiles/acarsdec.dir/netout.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling C source to assembly CMakeFiles/acarsdec.dir/netout.c.s"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/netout.c -o CMakeFiles/acarsdec.dir/netout.c.s

CMakeFiles/acarsdec.dir/fileout.c.o: CMakeFiles/acarsdec.dir/flags.make
CMakeFiles/acarsdec.dir/fileout.c.o: /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/fileout.c
CMakeFiles/acarsdec.dir/fileout.c.o: CMakeFiles/acarsdec.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_8) "Building C object CMakeFiles/acarsdec.dir/fileout.c.o"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/acarsdec.dir/fileout.c.o -MF CMakeFiles/acarsdec.dir/fileout.c.o.d -o CMakeFiles/acarsdec.dir/fileout.c.o -c /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/fileout.c

CMakeFiles/acarsdec.dir/fileout.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing C source to CMakeFiles/acarsdec.dir/fileout.c.i"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/fileout.c > CMakeFiles/acarsdec.dir/fileout.c.i

CMakeFiles/acarsdec.dir/fileout.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling C source to assembly CMakeFiles/acarsdec.dir/fileout.c.s"
	/Library/Developer/CommandLineTools/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/fileout.c -o CMakeFiles/acarsdec.dir/fileout.c.s

# Object files for target acarsdec
acarsdec_OBJECTS = \
"CMakeFiles/acarsdec.dir/acars.c.o" \
"CMakeFiles/acarsdec.dir/acarsdec.c.o" \
"CMakeFiles/acarsdec.dir/cJSON.c.o" \
"CMakeFiles/acarsdec.dir/label.c.o" \
"CMakeFiles/acarsdec.dir/msk.c.o" \
"CMakeFiles/acarsdec.dir/output.c.o" \
"CMakeFiles/acarsdec.dir/netout.c.o" \
"CMakeFiles/acarsdec.dir/fileout.c.o"

# External object files for target acarsdec
acarsdec_EXTERNAL_OBJECTS =

acarsdec: CMakeFiles/acarsdec.dir/acars.c.o
acarsdec: CMakeFiles/acarsdec.dir/acarsdec.c.o
acarsdec: CMakeFiles/acarsdec.dir/cJSON.c.o
acarsdec: CMakeFiles/acarsdec.dir/label.c.o
acarsdec: CMakeFiles/acarsdec.dir/msk.c.o
acarsdec: CMakeFiles/acarsdec.dir/output.c.o
acarsdec: CMakeFiles/acarsdec.dir/netout.c.o
acarsdec: CMakeFiles/acarsdec.dir/fileout.c.o
acarsdec: CMakeFiles/acarsdec.dir/build.make
acarsdec: CMakeFiles/acarsdec.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --bold --progress-dir=/Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_9) "Linking C executable acarsdec"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/acarsdec.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/acarsdec.dir/build: acarsdec
.PHONY : CMakeFiles/acarsdec.dir/build

CMakeFiles/acarsdec.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/acarsdec.dir/cmake_clean.cmake
.PHONY : CMakeFiles/acarsdec.dir/clean

CMakeFiles/acarsdec.dir/depend:
	cd /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build /Users/kevin/Cloud/Dropbox/work/airframes/install.airframes.sh/flight/acarsdec-master/build/CMakeFiles/acarsdec.dir/DependInfo.cmake "--color=$(COLOR)"
.PHONY : CMakeFiles/acarsdec.dir/depend

