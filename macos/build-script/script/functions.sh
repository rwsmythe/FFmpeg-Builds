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

checkStatus(){
    if [ $1 -ne 0 ]
    then
        echo "check failed: $2"
        exit 1
    fi
}

echoSection(){
    echo ""
    echo "$1"
}

currentTimeInSeconds(){
    TIME_GDATE=$(date +%s)
    if [ $? -eq 0 ]
    then
        echo $TIME_GDATE
    else
        echo 0
    fi
}

echoDurationInSections(){
    END_TIME=$(currentTimeInSeconds)
    echo "took $(($END_TIME - $1))s"
}

download(){
    URL=$1
    NAME=$2
    # Clearwater WP6.5: every download is pinned. The expected sha256 is looked
    # up by the exact URL in macos/sha256-pins.txt; a missing pin or a mismatch
    # ends the component script (a mismatch never falls back to a mirror).
    PIN_FILE="$SCRIPT_DIR/../../sha256-pins.txt"
    EXPECTED_SHA256=$(awk -v url="$URL" '$2 == url { print $1 }' "$PIN_FILE")
    if [ -z "$EXPECTED_SHA256" ]; then
        echo "no pinned sha256 for $URL in $PIN_FILE"
        exit 1
    fi
    curl -o "$NAME" -L -f "$URL"
    CURL_STATUS=$?
    if [ $CURL_STATUS -ne 0 ]; then
        return $CURL_STATUS
    fi
    ACTUAL_SHA256=$(shasum -a 256 "$NAME" | cut -d ' ' -f 1)
    if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
        echo "sha256 mismatch for $URL: expected $EXPECTED_SHA256, got $ACTUAL_SHA256"
        exit 1
    fi
    echo "sha256 verified for $URL: $ACTUAL_SHA256"
}

prepareMeson(){
    # Clearwater WP6.5: no pip install here (it would float). The workflow
    # installs meson by hash and puts it first on PATH.
    MESON_VERSION=$(meson -v 2> /dev/null)
    checkStatus $? "meson not found on PATH (the workflow installs the pinned meson)"
    echo "using meson $MESON_VERSION"
}
