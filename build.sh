#!/bin/bash

# docker run --rm -v $(pwd):/webrtc -w /webrtc --name webrtc-build -it ubuntu:latest /bin/bash

# Stop on error
set -e
mkdir -p build && cd build

# Step 1: Download and install depot tools
if [ ! -d depot_tools ]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
else
    cd depot_tools
    git pull origin main
    cd ..
fi
export PATH=$(pwd)/depot_tools:$PATH

# Step 2 - Download and build WebRTC
if [ ! -d webrtc-checkout ]; then
    mkdir -p webrtc-checkout
    cd webrtc-checkout
    fetch --nohooks webrtc
    cd ..
fi

cd webrtc-checkout/src
git fetch --all
git checkout $BRANCH

cd ..
gclient sync --with_branch_heads --with_tags
cd src
