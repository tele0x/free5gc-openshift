#!/usr/bin/env bash
##
## Container build for UERANSIM (GnodeB and UE RAN simulator)
##

# Exit script on first error
set -o errexit

# Read variables from inventory
UERANSIM_REPO=`yq -r .ueransim.repo group_vars/all.yml`
CMAKE_URL=`yq -r .ueransim.cmake_url group_vars/all.yml`
CMAKE_PKG=`yq -r .ueransim.cmake_pkg group_vars/all.yml`

# Use UBI as base container image
container=$(buildah --name ueransim from registry.access.redhat.com/ubi8/ubi)

buildah config --label maintainer="Federico 'tele' Rossi <ferossi@redhat.com>" $container

# Install packages
buildah run $container dnf install -y --nogpgcheck --disableplugin=subscription-manager iputils gcc make gcc-c++ iproute git lksctp-tools http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/lksctp-tools-devel-1.0.18-3.el8.x86_64.rpm wget
buildah run $container dnf clean all
buildah run $container wget $CMAKE_URL
buildah run $container tar -zxvf $CMAKE_PKG
buildah config --env PATH=$PATH:/`basename $CMAKE_PKG .tar.gz`/bin $container

# Download UERANSIM code
buildah run $container git clone https://github.com/aligungr/UERANSIM.git /UERANSIM

# Compile UERANSIM
buildah config --workingdir /UERANSIM $container
buildah run $container make

buildah config --entrypoint '/bin/sh -c "sleep 200000"' $container

# Commit to local container storage
buildah commit $container ueransim
