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

set(version        3.05.01)
set(download_hash  SHA256=05898f93c5d057fada49b9a116fc86ad9310ff1726a0f499c3e5211b3af47ec1)
set(patch_hash     SHA256=90471ee22afa6910954985113e94cb06612dce04be0522061c4494772d16abd5)

superbuild_package(
  NAME      tesseract-patches
  VERSION   ${version}

  SOURCE
    DOWNLOAD_NAME  tesseract-patches-${version}.tar.gz
    URL            https://www.dropbox.com/s/szdgrwaji7r88il/tesserat-3.05.01-patches.tar.gz?dl=1
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           tesseract
  VERSION        ${version}
  DEPENDS
    leptonica
    libjpeg
    libpng
    source:tesseract-patches-${version}
    tiff
  
  SOURCE
    DOWNLOAD_NAME  tesseract-${version}.tar.gz
	URL            https://codeload.github.com/tesseract-ocr/tesseract/tar.gz/${version}
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "<SOURCE_DIR>/autogen.sh"
    COMMAND
      "${CMAKE_COMMAND}" -Dpackage=tesseract-patches-${version} -P "${APPLY_PATCHES_SERIES}"

  BUILD [[
    CONFIGURE_COMMAND
      "PKG_CONFIG_PATH=${INSTALL_DIR}/${CMAKE_INSTALL_PREFIX}/lib/pkgconfig"
        "CXXFLAGS=-I${INSTALL_DIR}/${CMAKE_INSTALL_PREFIX}/include/leptonica"
        "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:${CMAKE_CROSSCOMPILING}>:
          --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --with-extra-libraries=${INSTALL_DIR}/${CMAKE_INSTALL_PREFIX}/lib
        "CFLAGS=$${}{CMAKE_C_FLAGS} $${}{CMAKE_C_FLAGS_$<UPPER_CASE:$<CONFIG>>}"
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${INSTALL_DIR}"
      COMMAND
        "${CMAKE_COMMAND}" -E copy "${SOURCE_DIR}/eng.traineddata" "${INSTALL_DIR}/${CMAKE_INSTALL_PREFIX}/share/tessdata"
  ]]
)
