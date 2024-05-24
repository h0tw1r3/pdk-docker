#!/bin/bash

set +x

source pdk-release.env

/usr/lib/apt/apt-helper download-file "${PDK_DEB_URL}" "pdk.deb"
dpkg -i pdk.deb

rm pdk.deb
