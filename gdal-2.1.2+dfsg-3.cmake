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

set(version        2.1.2+dfsg)
set(download_hash  SHA256=8c0961400ad64d54cb387d7ebf54411ad91ba4b3955121e56baaaa61785f9b1c)
set(patch_version  ${version}-3)
set(patch_hash     SHA256=2db5d34363b03b18766b94dd5cbd479df30b563f021de4954b6c559fa7de9db7)

if(APPLE)
	set(copy_dir cp -aR)
else()
	set(copy_dir cp -auT)
endif()

option(USE_SYSTEM_GDAL "Use the system GDAL if possible" ON)

set(test_system_gdal [[
	if(USE_SYSTEM_GDAL)
		enable_language(C)
		find_package(GDAL 2 QUIET)
		if(GDAL_FOUND)
			message(STATUS "Found gdal: ${GDAL_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
	
	# Make gdal aware of system libraries
	list(INSERT CMAKE_FIND_ROOT_PATH 0 "${INSTALL_DIR}")
	
	find_program(CURL_CONFIG
	  NAMES curl-config
	  ONLY_CMAKE_FIND_ROOT_PATH
	  QUIET
	)
	if(NOT CURL_CONFIG)
		message(FATAL_ERROR "Could not find curl-config")
	endif()
	
	find_path(EXPAT_INCLUDE_DIR
	  NAMES expat.h
	  ONLY_CMAKE_FIND_ROOT_PATH
	  QUIET
	)
	if(NOT EXPAT_INCLUDE_DIR)
		message(FATAL_ERROR "Could not find expat.h")
	endif()
	get_filename_component(EXPAT_DIR "${EXPAT_INCLUDE_DIR}" DIRECTORY CACHE)
	
	find_path(LIBZ_INCLUDE_DIR
	  NAMES zlib.h
	  ONLY_CMAKE_FIND_ROOT_PATH
	  QUIET
	)
	if(NOT LIBZ_INCLUDE_DIR)
		message(FATAL_ERROR "Could not find zlib.h")
	endif()
	get_filename_component(LIBZ_DIR "${LIBZ_INCLUDE_DIR}" DIRECTORY CACHE)
	
	find_path(SQLITE3_INCLUDE_DIR
	  NAMES sqlite3.h
	  ONLY_CMAKE_FIND_ROOT_PATH
	  QUIET
	)
	if(NOT SQLITE3_INCLUDE_DIR)
		message(FATAL_ERROR "Could not find sqlite3.h")
	endif()
	get_filename_component(SQLITE3_DIR "${SQLITE3_INCLUDE_DIR}" DIRECTORY CACHE)
]])

superbuild_package(
  NAME           gdal-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/g/gdal/gdal_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           gdal
  VERSION        ${patch_version}
  DEPENDS
    source:gdal-patches-${patch_version}
    curl
    expat
    libjpeg
    liblzma
    libpng
    pcre3
    proj
    sqlite3
    tiff
    zlib
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/g/gdal/gdal_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=gdal-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_GDAL copy_dir
  BUILD_CONDITION  ${test_system_gdal}
  BUILD [[
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory "${BINARY_DIR}"
    COMMAND
      ${copy_dir} "${SOURCE_DIR}/" "${BINARY_DIR}"
    COMMAND
      "${BINARY_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:${CMAKE_CROSSCOMPILING}>:
          --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-static
        --enable-shared
        --with-hide-internal-symbols
        --with-rename-internal-libtiff-symbols
        --without-threads
        --with-liblzma
        --with-pcre
        "--with-curl=$${}{CURL_CONFIG}"
        "--with-expat=$${}{EXPAT_DIR}"
        "--with-jpeg=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        "--with-libtiff=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        "--with-libz=$${}{LIBZ_DIR}"
        "--with-png=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        "--with-sqlite3=$${}{SQLITE3_DIR}"
        --without-geos
        --without-grib
        --without-java
        --without-jpeg12
        --without-netcdf
        --without-odbc
        --without-ogdi
        --without-pcraster
        --without-perl
        --without-pg
        --without-php
        --without-python
        --without-xerces
        --without-xml2
        "CPPFLAGS=-I${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}/include"
        "LDFLAGS=-L${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}/lib"
        $<$<BOOL:${ANDROID}>:
          "LIBS=-lgnustl_shared"
        >
        "PKG_CONFIG="
    BUILD_COMMAND
      "$(MAKE)" USER_DEFS=-Wno-format   # no missing-sentinel warnings
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${INSTALL_DIR}"
  ]]
)