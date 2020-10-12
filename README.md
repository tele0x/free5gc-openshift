# Free5GC on OpenShift

Deploy Free5GC on OpenShift Container Platform. free5gc-openshift uses Ansible to create 5G Core NFs images. Ansible is also used with the k8s module to deploy and configure the 5G Core. The playbooks take care of creating the project and resources such as networking and services. The base container image is Red Hat UBI 8 but it should work with a Fedora or CentOS image as well.
UPF requires [GTP5G](https://github.com/PrinzOwO/gtp5g) kernel module that works on specific 5.x kernel versions, as OpenShift 4.x uses RHCOS with kernel 4.x the best way to deploy the UPF is to use a CNV (Container Native Virtualization) 

## Requirements

  - ansible (tested on version 2.10.0)
  - podman
  - buildah
  - A running OpenShift cluster with reachable API
  - Ansible Tower (optional)

### Build Image (optional)

Container images to run the 5G Core are already built and used in the playbooks.

| Name | Image | Description |
| ---- | ----- | ------- |
| free5gc-openshift | quay.io/ferossi/free5gc-openshift | All-in-one image with pre-compiled 5G Core NFs components |
| free5gc-openshift-upf | quay.io/ferossi/free5gc-openshift-upf | UPF Containerized image for CNV |
| uesim | quay.io/ferossi/uesim | UE RAN simulator image |

Optionally you can build and customize the images and push it to your own registry.
Use the build.sh script to create container images for 5G Core. You can build individual images or use "all-in-one" to build an image with all components installed.

```sh
$ ./build.sh
Usage: ./build.sh [ all-in-one | all | nrf | pcf | smf | ausf | udm | udr | amf | n3iwf | upf ]
    
all-in-one: One single image with all the components compiled
all: All components as individual images
uesim: Build UE RAN simulator image to run distributed testing of 5G NFs

$ ./build.sh all-in-one
```
Use podman to list the images and push the image to a registry

```sh
$ podman images
$ podman login quay.io
$ podman push [image_id] quay.io/[user]/[your_repository]:[optional_tag]
``` 

### Installation

Clone this repository

```sh
$ git clone https://github.com/tele0x/free5g-openshift
```

Create 5genv environment, and install dependencies 

```sh
$ python3 -m venv 5genv
$ . 5genv/bin/activate
$ cd free5gc-openshift
$ pip3 install -r requirements.txt
$ ansible-galaxy collection community.kubernetes
```

This should get you up and running with the environment, you can OCP cluster connection is working by running:

```sh
$ ./deploy.sh test
```


