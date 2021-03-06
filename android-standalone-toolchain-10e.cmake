# This file is part of OpenOrienteering.

# Copyright 2016, 2017 Kai Pastor
#
# Redistribution and use is allowed according to the terms of the BSD license:
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
# 1. Redistributions of source code must retain the copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products 
#    derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set(supported_abis
  armeabi-v7a  
  x86
)

set(system_name_armeabi-v7a arm-linux-androideabi)
set(system_name_x86         i686-linux-android)

set(enabled_abis )
foreach(abi ${supported_abis})
	option(ENABLE_${system_name_${abi}} "Enable the ${system_name_${abi}} toolchain" 0)
	if(ENABLE_${system_name_${abi}})
		list(APPEND enabled_abis ${abi})
	endif()
endforeach()
if(NOT enabled_abis)
	return() # *** Early exit ***
endif()

set(KEYSTORE_URL "KEYSTORE_URL-NOTFOUND" CACHE STRING
  "URL of the keystore to be used when signing APK packages."
)
set(KEYSTORE_ALIAS "KEYSTORE_ALIAS-NOTFOUND" CACHE STRING
  "Alias in the keystore to be used when signing APK packages."
)
if(CMAKE_BUILD_TYPE MATCHES Rel)
	if(NOT KEYSTORE_URL OR NOT KEYSTORE_ALIAS)
		# Warn here, fail on build - don't block other toolchains
		message(WARNING "You must configure KEYSTORE_URL and KEYSTORE_ALIAS for signing Android release packages.")
	endif()
endif()

if(NOT DEFINED ANDROID_SDK_ROOT AND NOT "$ENV{ANDROID_SDK_ROOT}" STREQUAL "")
	set(ANDROID_SDK_ROOT "$ENV{ANDROID_SDK_ROOT}")
endif()
if(NOT DEFINED ANDROID_NDK_ROOT AND NOT "$ENV{ANDROID_NDK_ROOT}" STREQUAL "")
	set(ANDROID_NDK_ROOT "$ENV{ANDROID_NDK_ROOT}")
endif()
if(NOT DEFINED ANDROID_API AND NOT "$ENV{ANDROID_API}" STREQUAL "")
	set(ANDROID_API "$ENV{ANDROID_API}")
elseif(NOT DEFINED ANDROID_API)
	set(ANDROID_API 9)
endif()
set(version "${ANDROID_API}")

set(android_toolchain_dependencies)
if(CMAKE_VERSION VERSION_LESS 3.7.0)
	list(APPEND android_toolchain_dependencies cmake)
endif()
if(UNIX AND NOT APPLE
   AND CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
	
	# cf. http://code.qt.io/cgit/qt/qt5.git/tree/coin/provisioning/qtci-linux-RHEL-6.6-x86_64/android_sdk_linux.sh?h=5.6
	set(sdk_version 24.4.1)
	set(sdk_components
	  android-10
	  android-11
	  android-16
	  tools
	  platform-tools
	  build-tools-23.0.3
	)
	string(REPLACE ";" "," sdk_components "${sdk_components}")
	superbuild_package(
	  NAME         android-sdk
	  VERSION      ${sdk_version}
	  
	  SOURCE
	    URL           https://dl.google.com/android/android-sdk_r${sdk_version}-linux.tgz
	    URL_HASH      SHA1=725bb360f0f7d04eaccff5a2d57abdd49061326d
	    UPDATE_COMMAND
	      echo "y" > "<TMP_DIR>/y"
	    COMMAND
	      <SOURCE_DIR>/tools/android update sdk --no-ui --all
	        --filter ${sdk_components}
	        < "<TMP_DIR>/y"
	)
	if(NOT ANDROID_SDK_ROOT)
		set(ANDROID_SDK_ROOT "${PROJECT_BINARY_DIR}/source/android-sdk-${sdk_version}")
		list(APPEND android_toolchain_dependencies source:android-sdk-${sdk_version})
	endif()
	
	set(ndk_version 10e)
	superbuild_package(
	  NAME         android-ndk
	  VERSION      ${ndk_version}
	  
	  SOURCE
	    URL           https://dl.google.com/android/repository/android-ndk-r${ndk_version}-linux-x86_64.zip
	    URL_HASH      SHA1=f692681b007071103277f6edc6f91cb5c5494a32
	)
	if(NOT ANDROID_NDK_ROOT)
		set(version "${ndk_version}-${version}")
		set(ANDROID_NDK_ROOT "${PROJECT_BINARY_DIR}/source/android-ndk-${ndk_version}")
		list(APPEND android_toolchain_dependencies android-gnustl-4.9-${ndk_version})
	endif()
	
	set(android_gnustl_4.9_source_script [[
#!/bin/bash -e

ANDROID_NDK_ROOT="$1"
if [ -z "$ANDROID_NDK_ROOT" -o ! -d "$ANDROID_NDK_ROOT" ]
then
	echo "$0: Error: missing parameter" >&2
	echo "Usage:" >&2
	echo "   $0 /PATH/TO/NDK-DIR" >&2
	exit 1
fi

PATCHES_DIR="${ANDROID_NDK_ROOT}/build/tools/toolchain-patches/gcc"
if [ ! -d "$PATCHES_DIR" ]
then
	echo "Error: No build/tools/toolchain-patches/gcc in $ANDROID_NDK_ROOT"
	exit 2
fi
mkdir -p build && touch build/configure
export GIT_DIR="$(pwd)/gcc/.git"
if [ ! -d "$GIT_DIR" ]
then
	echo "Creating local git repository..."
	git clone --no-checkout https://android.googlesource.com/toolchain/gcc.git
else
	echo "Updating local git repository..."
	( cd gcc; git fetch )
fi

REVISION=$(sed -e '/gcc.git/!d\\;s/^[^ ]* *\|([^ ]* *\| .*//g' "$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/SOURCES")
echo $REVISION > REVISION
echo "Checking out revision $REVISION..."
(
	cd gcc &&
	git checkout -f $REVISION -- \
	  gcc-4.9/libstdc++-v3 \
	  \
	  gcc-4.9/ChangeLog* \
	  gcc-4.9/config\* \
	  gcc-4.9/COPYING* \
	  gcc-4.9/gcc/DATESTAMP \
	  gcc-4.9/include \
	  gcc-4.9/install-sh \
	  gcc-4.9/libgcc \
	  gcc-4.9/libiberty \
	  gcc-4.9/libtool* \
	  gcc-4.9/lt* \
	  gcc-4.9/MAINTAINERS* \
	  gcc-4.9/mkinstalldirs \
	  gcc-4.9/README* \
	  \
	  gcc-4.8/gcc/config/linux-android.h \
	  gcc-4.9/gcc/config/linux-android.h \
	  \
	  gcc-4.8/libgcc/gthr-posix.h \
	  gcc-4.9/libgcc/gthr-posix.h \
	  \
	  gcc-4.8/libstdc++-v3/src/Makefile.in \
	  gcc-4.9/libstdc++-v3/src/Makefile.in \
	  \
	  gcc-4.9/gcc/BASE-VER \
	  \
	  gcc-4.9/gcc/ChangeLog \
	  gcc-4.9/gcc/config/arm/arm.md \
	  gcc-4.9/gcc/testsuite/ChangeLog \
	  \
	  gcc-4.8/gcc/config/i386/arm_neon.h \
	  gcc-4.9/gcc/config/i386/arm_neon.h \
	  \
	  # End. Covers libstdc++ sources, build dependencies, and extra files touched by patches.
)

echo "Copying build scripts and patches..."

NDK_SCRIPTS=" \
  build/tools/build-gnu-libstdc++.sh \
  build/tools/dev-defaults.sh \
  build/tools/ndk-common.sh \
  build/tools/prebuilt-common.sh "

mkdir -p build/tools
for I in $NDK_SCRIPTS
do
	cp "$ANDROID_NDK_ROOT/$I" build/tools/
done

PATCHES=$(find "$PATCHES_DIR" -name '*.patch' | sort)
if [ -n "$PATCHES" ]
then
	mkdir -p build/tools/toolchain-patches/gcc
	for PATCH in $PATCHES
	do
		grep -q gcc-4.9 "$PATCH" &&
		  cp "$PATCH" build/tools/toolchain-patches/gcc/
	done
fi

echo "Applying patches..."

CHANGE_FILE=CHANGES.txt
cat > $CHANGE_FILE << END_CHANGES
*** CHANGE NOTICE: ***

$(date +%F) OpenOrienteering (http://www.openorienteering.org)
           Patches from build/tools/toolchain-patches/gcc applied to src/:

END_CHANGES
PATCHES=$(find "$(pwd)/build/tools/toolchain-patches/gcc" -name '*.patch' | sort)
if [ -n "$PATCHES" ]
then
	for PATCH in $PATCHES
	do
		echo "*** $(basename $PATCH)"
		( cd gcc && patch -p1 < $PATCH ) || exit 1
	done  | tee -a $CHANGE_FILE
fi

echo "Cleanup..."
for I in gcc/gcc-4.8 gcc/gcc-4.9/lto-plugin gcc/gcc-4.9/libgcc/config/*
do
	case $(basename "$I") in
	aarch64|arm|mips|i386)
		\\;\\; 
	*)
		if [ -d "$I" ]
		then
			rm -R "$I"
		fi
		\\;\\;
	esac
done
]]
	)
	set(android_gnustl_4.9_copyright [[
COPYRIGHT STATEMENTS AND LICENSING TERMS


GCC is Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007,
2008, 2009, 2010, 2011, 2012, 2013, 2014 Free Software Foundation, Inc.

GCC is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

GCC is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

Files that have exception clauses are licensed under the terms of the
GNU General Public License; either version 3, or (at your option) any
later version.

On Debian GNU/Linux systems, the complete text of the GNU General
Public License is in `/usr/share/common-licenses/GPL', version 3 of this
license in `/usr/share/common-licenses/GPL-3'.

The following runtime libraries are licensed under the terms of the
GNU General Public License (v3 or later) with version 3.1 of the GCC
Runtime Library Exception (included in this file):

 - libgcc (libgcc/, gcc/libgcc2.[ch], gcc/unwind*, gcc/gthr*,
   gcc/coretypes.h, gcc/crtstuff.c, gcc/defaults.h, gcc/dwarf2.h,
   gcc/emults.c, gcc/gbl-ctors.h, gcc/gcov-io.h, gcc/libgcov.c,
   gcc/tsystem.h, gcc/typeclass.h).
 - libstdc++-v3


GCC RUNTIME LIBRARY EXCEPTION

Version 3.1, 31 March 2009

Copyright (C) 2009 Free Software Foundation, Inc. <http://fsf.org/>

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.

This GCC Runtime Library Exception ("Exception") is an additional
permission under section 7 of the GNU General Public License, version
3 ("GPLv3"). It applies to a given file (the "Runtime Library") that
bears a notice placed by the copyright holder of the file stating that
the file is governed by GPLv3 along with this Exception.

When you use GCC to compile a program, GCC may combine portions of
certain GCC header files and runtime libraries with the compiled
program. The purpose of this Exception is to allow compilation of
non-GPL (including proprietary) programs to use, in this way, the
header files and runtime libraries covered by this Exception.

0. Definitions.

A file is an "Independent Module" if it either requires the Runtime
Library for execution after a Compilation Process, or makes use of an
interface provided by the Runtime Library, but is not otherwise based
on the Runtime Library.

"GCC" means a version of the GNU Compiler Collection, with or without
modifications, governed by version 3 (or a specified later version) of
the GNU General Public License (GPL) with the option of using any
subsequent versions published by the FSF.

"GPL-compatible Software" is software whose conditions of propagation,
modification and use would permit combination with GCC in accord with
the license of GCC.

"Target Code" refers to output from any compiler for a real or virtual
target processor architecture, in executable form or suitable for
input to an assembler, loader, linker and/or execution
phase. Notwithstanding that, Target Code does not include data in any
format that is used as a compiler intermediate representation, or used
for producing a compiler intermediate representation.

The "Compilation Process" transforms code entirely represented in
non-intermediate languages designed for human-written code, and/or in
Java Virtual Machine byte code, into Target Code. Thus, for example,
use of source code generators and preprocessors need not be considered
part of the Compilation Process, since the Compilation Process can be
understood as starting with the output of the generators or
preprocessors.

A Compilation Process is "Eligible" if it is done using GCC, alone or
with other GPL-compatible software, or if it is done without using any
work based on GCC. For example, using non-GPL-compatible Software to
optimize any GCC intermediate representations would not qualify as an
Eligible Compilation Process.

1. Grant of Additional Permission.

You have permission to propagate a work of Target Code formed by
combining the Runtime Library with Independent Modules, even if such
propagation would otherwise violate the terms of GPLv3, provided that
all Target Code was generated by Eligible Compilation Processes. You
may then convey such a combination under terms of your choice,
consistent with the licensing of the Independent Modules.

2. No Weakening of GCC Copyleft.

The availability of this Exception does not imply any general
presumption that third-party software is unaffected by the copyleft
requirements of the license of GCC.

]]
	)
	set(archive_name android-gnustl-4.9-${ndk_version})
	string(REPLACE ";" "," android_ndk_abis "${enabled_abis}")
	superbuild_package(
	  NAME         android-gnustl-4.9
	  VERSION      ${ndk_version}
	  DEPENDS      source:android-ndk-${ndk_version}
	  SOURCE_WRITE
	    copyright         android_gnustl_4.9_copyright
	    source_script.sh  android_gnustl_4.9_source_script
	  SOURCE
	    # source_script.sh is created between download and update step.
	    DOWNLOAD_COMMAND "${CMAKE_COMMAND}" -E make_directory "<SOURCE_DIR>"
	    UPDATE_COMMAND "${CMAKE_COMMAND}" -E chdir "<SOURCE_DIR>"
	      bash -e -- "<SOURCE_DIR>/source_script.sh" "${ANDROID_NDK_ROOT}"
	    COMMAND "${CMAKE_COMMAND}" -E chdir "<SOURCE_DIR>/.."
	      tar czf "${PROJECT_SOURCE_DIR}/${archive_name}.tar.gz"
	        "--exclude=${archive_name}/gcc/.git"
	        "--exclude=*~"
	        "${archive_name}"
	  USING ANDROID_NDK_ROOT android_ndk_abis
	  BUILD [[
	    CONFIGURE_COMMAND ""
	    BUILD_COMMAND "${CMAKE_COMMAND}" -E env "ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}"
	      bash -- "${SOURCE_DIR}/build/tools/build-gnu-libstdc++.sh"
		    --gcc-version-list=4.9
		    --abis=${android_ndk_abis}
	        "${SOURCE_DIR}"
	    INSTALL_COMMAND ""
	  ]]
	)
endif()


if(NOT ANDROID_SDK_ROOT)
	message(FATAL_ERROR "ANDROID_SDK_ROOT must be set")
elseif(NOT ANDROID_NDK_ROOT)
	message(FATAL_ERROR "ANDROID_NDK_ROOT must be set")
endif()

foreach(abi ${enabled_abis})
	set(system_name "${system_name_${abi}}")
	
	if(CMAKE_VERSION VERSION_LESS 3.7.0
	   AND NOT ${system_name}_CMAKE_COMMAND)
		# Superbuild will set the path to include the superbuilt new CMake.
		set(${system_name}_CMAKE_COMMAND "cmake" PARENT_SCOPE)
	endif()
	
	sb_toolchain_dir(toolchain_dir ${system_name})
	sb_install_dir(install_dir ${system_name})
	
	if(NOT DEFINED ${system_name}_INSTALL_PREFIX)
		set(${system_name}_INSTALL_PREFIX "/usr")
	endif()
	
	if(NOT DEFINED ${system_name}_FIND_ROOT_PATH)
		set(${system_name}_FIND_ROOT_PATH "${install_dir}")
	endif()
	
	set(toolchain [[
# Generated by ]] "${CMAKE_CURRENT_LIST_FILE}\n" [[

if(CMAKE_VERSION VERSION_LESS 3.7)
	message(FATAL_ERROR "CMake >= 3.7.0 is required for Android")
endif()

# Cf. https://cmake.org/cmake/help/v3.7/manual/cmake-toolchains.7.html
# We use the standalone toolchain configuration.
set(CMAKE_SYSTEM_NAME      "Android")
set(CMAKE_SYSROOT          "]] "${toolchain_dir}/sysroot" [[")
set(CMAKE_ANDROID_ARCH_ABI "]] ${abi} [[")
set(CMAKE_ANDROID_STL_TYPE "gnustl_shared")

set(SYSTEM_NAME            "]] ${system_name} [[")
set(SUPERBUILD_TOOLCHAIN_TRIPLET ]] ${system_name} [[)

set(TOOLCHAIN_DIR          "]] "${toolchain_dir}" [[")
set(INSTALL_DIR            "]] "${install_dir}" [[")
set(CMAKE_INSTALL_PREFIX   "]] "${${system_name}_INSTALL_PREFIX}" [["
    CACHE PATH             "Install path prefix, prepended onto install directories")

set(CMAKE_FIND_ROOT_PATH   "]] "${${system_name}_FIND_ROOT_PATH}" [[")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(ANDROID_SDK_ROOT       "]] "${ANDROID_SDK_ROOT}" [[")
set(ANDROID_NDK_ROOT       "]] "${ANDROID_NDK_ROOT}" [[")
set(KEYSTORE_URL           "]] "${KEYSTORE_URL}" [[")
set(KEYSTORE_ALIAS         "]] "${KEYSTORE_ALIAS}" [[")
set(EXPRESSION_BOOL_SIGN   "$<AND:$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>,$<BOOL:${KEYSTORE_URL}>,$<BOOL:${KEYSTORE_ALIAS}>>")

set(USE_SYSTEM_ZLIB        ON)
set(ZLIB_ROOT              "${CMAKE_SYSROOT}")

set(CMAKE_RULE_MESSAGES    OFF CACHE BOOL "Whether to report a message for each make rule")
set(CMAKE_TARGET_MESSAGES  OFF CACHE BOOL "Whether to report a message for each target")
set(CMAKE_VERBOSE_MAKEFILE ON  CACHE BOOL "Enable verbose output from Makefile builds")
]]
)
	string(MD5 md5 "${toolchain}")
	
	if(android_toolchain_dependencies MATCHES "gnustl-4.9")
		set(install_copyright
"	    COMMAND
	      \"\${CMAKE_COMMAND}\" -E copy_if_different
	        \"<SOURCE_DIR>/../android-gnustl-4.9-${ndk_version}/copyright\"
	        \"${install_dir}${${system_name}_INSTALL_PREFIX}/share/doc/copyright/gnustl-4.9.txt\"
"
		)
	else()
		set(install_copyright )
	endif()
	
	string(REPLACE "i686-linux-android" "x86" toolchain_name "${system_name}")
	
	superbuild_package(
	  NAME         ${system_name}-toolchain
	  VERSION      ${version}
	  SYSTEM_NAME  ${system_name}
	  
	  DEPENDS      ${android_toolchain_dependencies}
	  
	  SOURCE_WRITE
	    toolchain.cmake toolchain
	  
	  USING
	    md5
	    toolchain_name
	    install_copyright
	    ANDROID_SDK_ROOT
	    ANDROID_NDK_ROOT
	    ANDROID_API
	    KEYSTORE_URL
	    KEYSTORE_ALIAS
	  
	  BUILD [[
	    CONFIGURE_COMMAND
	      "${CMAKE_COMMAND}" -E touch_nocreate ${md5}
	    $<$<NOT:$<AND:$<BOOL:${KEYSTORE_URL}>,$<BOOL:${KEYSTORE_ALIAS}>>>:
	      $<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:
	        COMMAND "${CMAKE_COMMAND}" -E echo
	          "You must configure KEYSTORE_URL and KEYSTORE_ALIAS for signing Android release packages."
	      >
	      $<$<CONFIG:Release>:
	        COMMAND false
	      >
	    >
	    BUILD_COMMAND
	      bash "${ANDROID_NDK_ROOT}/build/tools/make-standalone-toolchain.sh"
	        "--toolchain=${toolchain_name}-4.9"
	        "--platform=android-${ANDROID_API}"
	        "--install-dir=${INSTALL_DIR}"
	    INSTALL_COMMAND
	      "${CMAKE_COMMAND}" -E copy_if_different
	        "${SOURCE_DIR}/toolchain.cmake" "${INSTALL_DIR}/toolchain.cmake"
	    ${install_copyright}
	  ]]
	)
endforeach()
