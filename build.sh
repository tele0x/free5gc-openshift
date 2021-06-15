#!/usr/bin/env bash
##
## Container build for free5gc components
##

# Exit script on first error
set -o errexit

case "$1" in
	"all-in-one")
		NF="all-in-one"
		;;
	"nrf" | "pcf" | "smf" | "ausf" | "udm" | "udr" | "amf" | "n3iwf" | "upf" | "nssf" | "upf")
		NF=$1
		;;
	*)
		echo -e "Usage: $0 [all-in-one|all|nrf|pcf|smf|ausf|nssf|udm|udr|amf|n3iwf|upf]"
		echo -e "\nall-in-one: Build a container image with all the 5G Core NFs compiled"
		exit 0
		;;
esac

NF=$1

# Read variables from inventory
GO_URL=`yq -r .go.url group_vars/all.yml`
GO_PACKAGE=`yq -r .go.package group_vars/all.yml`
FREE5GC_VERSION=`yq -r .free5gc.version group_vars/all.yml`
FREE5GC_REPO=`yq -r .free5gc.repo group_vars/all.yml`

# Use UBI as base container image
container=$(buildah --name free5gc-aio from registry.access.redhat.com/ubi8/ubi)

buildah config --label maintainer="Federico 'tele' Rossi <ferossi@redhat.com>" $container

# Install packages
buildah run $container dnf install -y --nogpgcheck --disableplugin=subscription-manager iproute git iputils make cmake pkgconfig autoconf automake gcc gcc-c++ libyaml libyaml-devel libmnl libtool http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/libmnl-devel-1.0.4-6.el8.x86_64.rpm
buildah run $container dnf clean all

# Download free5gc source code
buildah run $container git clone $FREE5GC_REPO -b $FREE5GC_VERSION --recursive /free5gc

# Install golang
buildah run $container curl -o /tmp/$GO_PACKAGE $GO_URL
buildah run $container tar -zxvf /tmp/$GO_PACKAGE -C /usr/local
buildah config --env GOPATH=/go --env GOROOT=/usr/local/go --env GO111MODULE=auto --env PATH=$PATH:/usr/local/go/bin $container
buildah run $container mkdir /go /go/bin /go/pkg /go/src
	
# Install packages for WebUI
buildah run $container curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo
buildah run $container rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
buildah run $container dnf -y install nodejs yarn
buildah run $container dnf clean all
buildah config --workingdir /free5gc/webconsole $container
buildah run $container git checkout v1.0.1

# Compile NFs
buildah config --workingdir /free5gc $container

if [ "$NF" != "all-in-one" ]; then

	buildah run $container make $NF
else
	buildah run $container make
	buildah run $container make webconsole
fi
buildah config --entrypoint '/bin/sh -c "sleep 200000"' $container

# Commit to local container storage
buildah commit $container free5gc-aio
