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

set(version        1.74.4-cc)
set(download_hash  SHA256=b05c7efd2ad05e2a77a052c70a6adcaa8b5c41df74d92d718fad7fd2c37074c6)

superbuild_package(
  NAME           leptonica
  VERSION        ${version}
  DEPENDS
    libpng
    libjpeg-turbo
    tiff
    zlib
  
  SOURCE
    DOWNLOAD_NAME  leptonica-${version}.tar.gz
	URL            https://github.com/xc-racer99/leptonica/archive/${version}.tar.gz
    URL_HASH       ${download_hash}

  PATCH_COMMAND
    

  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip -- VERBOSE=1 "DESTDIR=${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "${SOURCE_DIR}/leptonica-license.txt"
        "${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}/share/doc/copyright/leptonica.txt"
  ]]
)
