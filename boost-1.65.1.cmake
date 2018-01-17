# Copyright 2016, 2017 Kai Pastor
# Copyright 2017 Jonathan Bakker
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

set(version        1.65.1)
set(download_hash  SHA256=a13de2c8fbad635e6ba9c8f8714a0e6b4264b60a29b964b940a22554705b6b60)
set(patch_hash     SHA256=d5f3fa7b276b4ef9ef457adb9415dbc03f77a6bf3fbdc9cc5683a0a9da0246a1)

set(crosscompiling [[$<BOOL:${CMAKE_CROSSCOMPILING}>]])
set(windows        [[$<STREQUAL:${CMAKE_SYSTEM_NAME},Windows>]])

superbuild_package(
  NAME      boost-patches
  VERSION   ${version}

  SOURCE
    DOWNLOAD_NAME  boost-patches-${version}.tar.gz
    URL       https://www.dropbox.com/s/qj9takp66o14lju/boost-patches.tar.gz?dl=1
    URL_HASH  ${patch_hash}
)

superbuild_package(
  NAME           boost
  VERSION        ${version}
  DEPENDS
    source:boost-patches-${version}
  
  SOURCE
	URL            https://dl.bintray.com/boostorg/release/${version}/source/boost_1_65_1.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -Dpackage=boost-patches-${version} -P "${APPLY_PATCHES_SERIES}"

  BUILD [[
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E copy_directory ${SOURCE_DIR} ${BINARY_DIR}
    BUILD_COMMAND
      "${BINARY_DIR}/bootstrap.sh"
        --with-toolset=gcc
        "CFLAGS=$${}{CMAKE_C_FLAGS} $${}{CMAKE_C_FLAGS_$<UPPER_CASE:$<CONFIG>>}"
    INSTALL_COMMAND
      "${BINARY_DIR}/b2"
        --with-filesystem --with-system
        release
        install "--prefix=${INSTALL_DIR}/${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:${CMAKE_CROSSCOMPILING}>:
          toolset=gcc-mingw target-os=windows
          --user-config=user-config.jam
        >
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "${SOURCE_DIR}/LICENSE_1_0.txt"
        "${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}/share/doc/copyright/boost.txt"
  ]]
)
