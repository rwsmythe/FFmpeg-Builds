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
CPUS=$4

# load functions
. $SCRIPT_DIR/functions.sh

# start in working directory
cd "$SOURCE_DIR"
checkStatus $? "change directory failed"
mkdir "x264"
checkStatus $? "create directory failed"
cd "x264/"
checkStatus $? "change directory failed"

# download source (Clearwater WP6.5: git at a pinned commit instead of the
# floating master archive; the checkout fails if the commit is absent)
git clone https://code.videolan.org/videolan/x264.git "x264-master"
checkStatus $? "download failed"
cd "x264-master/"
checkStatus $? "change directory failed"
git checkout --detach 0480cb05fa188d37ae87e8f4fd8f1aea3711f7ee
checkStatus $? "checkout of the pinned x264 commit failed"

# prepare build
./configure --prefix="$TOOL_DIR" --enable-static --disable-cli
checkStatus $? "configuration failed"

# build
make -j $CPUS
checkStatus $? "build failed"

# install
make install
checkStatus $? "installation failed"
