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

set(version        2.4.13.3)
set(download_hash  SHA256=fb4769d0119c35426c3754b7fb079b407911e863958db53bdec83c7794582e41)

superbuild_package(
  NAME           opencv
  VERSION        ${version}
  
  SOURCE
	DOWNLOAD_NAME  opencv-${version}.tar.gz
	URL            https://github.com/opencv/opencv/archive/${version}.tar.gz
    URL_HASH       ${download_hash}

  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}/${CMAKE_INSTALL_PREFIX}"
    INSTALL_COMMAND
            "${CMAKE_COMMAND}" --build . --target install
      COMMAND
        "${CMAKE_COMMAND}" -E copy_directory "${INSTALL_DIR}/${CMAKE_INSTALL_PREFIX}/x86/mingw/bin" "${INSTALL_DIR}/${CMAKE_INSTALL_PREFIX}/bin"
  ]]
)
