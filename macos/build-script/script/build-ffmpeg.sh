#!/bin/sh

# Copyright 2021 Martin Riedl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# handle arguments
echo "arguments: $@"
SCRIPT_DIR=$1
SOURCE_DIR=$2
TOOL_DIR=$3
OUT_DIR=$4
CPUS=$5
FFMPEG_SNAPSHOT=$6
FFMPEG_LIB_FLAGS=$7

# load functions
. $SCRIPT_DIR/functions.sh

# version (Clearwater WP6.5: FFmpeg from git, release/9.0 at the pinned commit
# of the Windows build, instead of the release tarball named by version/ffmpeg)
FFMPEG_REPO="https://github.com/FFmpeg/FFmpeg.git"
FFMPEG_BRANCH="release/9.0"
FFMPEG_COMMIT="b204e94e90fca64045e9ca7dd44c65678c7eb29e"
if [ $FFMPEG_SNAPSHOT != "NO" ]; then
    echo "-FFMPEG_SNAPSHOT is not supported by this recipe"
    exit 1
fi
echo "version: $FFMPEG_BRANCH at $FFMPEG_COMMIT"

# start in working directory
cd "$SOURCE_DIR"
checkStatus $? "change directory failed"
mkdir "ffmpeg"
checkStatus $? "create directory failed"
cd "ffmpeg/"
checkStatus $? "change directory failed"

# clone ffmpeg source and check out the pinned commit (fails if it is absent)
git clone --filter=blob:none --branch="$FFMPEG_BRANCH" "$FFMPEG_REPO" ffmpeg
checkStatus $? "ffmpeg clone failed"
cd "ffmpeg/"
checkStatus $? "change directory failed"
git checkout --detach "$FFMPEG_COMMIT"
checkStatus $? "checkout of the pinned ffmpeg commit failed"

# prepare build (Clearwater WP6.5: the extra version is the UTC build date,
# the form of the Windows build)
EXTRA_VERSION="$(date -u +%Y%m%d)"
export LDFLAGS="-L${TOOL_DIR}/lib"
export CPPFLAGS="-I${TOOL_DIR}/include"
# --pkg-config-flags="--static" is required to respect the Libs.private flags of the *.pc files
./configure --prefix="$OUT_DIR" --pkg-config-flags="--static" --extra-version="$EXTRA_VERSION" \
    --enable-gray --enable-libxml2 $FFMPEG_LIB_FLAGS
checkStatus $? "configuration failed"

# start build
make -j $CPUS
checkStatus $? "build failed"

# install ffmpeg
make install
checkStatus $? "installation failed"
