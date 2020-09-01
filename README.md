# Free5GC on OpenShift

Deploy Free5GC on OpenShift Container Platform. free5gc-openshift uses Ansible to create 5G Core NFs images. Ansible is also used with the k8s module to deploy and configure the 5G Core. The playbooks take care of creating the project and resources such as networking and services. The base container image is Red Hat UBI 8  but it should work with a Fedora or CentOS image as well.
-
# Requirements

  - ansible (tested on version 2.9.12)
  - podman
  - buildah
  - A running OpenShift cluster

# Installation

Use the build.sh script to create container images for 5G Core. You can build individual images or use "all-in-one" to build an image with all components installed.

```sh
$ ./build.sh
Usage: ./build.sh [ all-in-one | all | nrf | pcf | smf | ausf | udm | udr | amf | n3iwf | upf ]
$ ./build.sh all-in-one
```

Work in progress...

# TODO

  - Reduce image size by using UBI-minimal
