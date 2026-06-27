#!/bin/bash
set -e

UBUNTU_VERSION=22.04

# $HOME/.local/bin にインストール
mkdir -p /tmp/Amatsukaze \
&& curl -s https://api.github.com/repos/rigaya/Amatsukaze/releases/latest \
    | grep "browser_download_url.*tar.xz" | grep "Ubuntu${UBUNTU_VERSION}" | cut -d : -f 2,3 | tr -d \" \
    | wget -i - -O - | tar -xJ -C /tmp/Amatsukaze \
&& install /tmp/Amatsukaze/exe_files/AmatsukazeAddTask $HOME/.local/bin/ \
&& rm -rf /tmp/Amatsukaze