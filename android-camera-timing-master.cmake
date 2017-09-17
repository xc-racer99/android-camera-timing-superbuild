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

set(version        master)
set(qt_version     5.6.2)

superbuild_package(
  NAME           android-camera-timing-pc
  VERSION        ${version}
  DEPENDS
    qtbase-${qt_version}
    qtimageformats-${qt_version}
	qtserialport-${qt_version}
    zlib
    host:qttools-${qt_version}
  
  SOURCE
    DOWNLOAD_NAME  android-camera-timing-pc_${version}.tar.gz
    URL            https://github.com/xc-racer99/android-camera-timing-pc/archive/${version}.tar.gz
  
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
      "-DBUILD_SHARED_LIBS=0"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install -- VERBOSE=1
      $<$<BOOL:${WIN32}>:
        # Windows installation layout is weird
        "DESTDIR=${INSTALL_DIR}/CameraTimingAndroid-PC"
      >$<$<NOT:$<BOOL:${WIN32}>>:
        "DESTDIR=${INSTALL_DIR}"
      >
  ]]
  
  EXECUTABLES src/AndroidTimingPC
  
  PACKAGE [[
    COMMAND "${CMAKE_COMMAND}" --build . --target package/fast
  ]]
)
