# Free5GC on OpenShift

Deploy Free5GC on OpenShift Container Platform. free5gc-openshift uses Ansible to create 5G Core NFs images. Ansible is also used with the k8s module to deploy and configure the 5G Core. The playbooks take care of creating the project and resources such as networking and services. The base container image is Red Hat UBI 8 but it should work with a Fedora or CentOS image as well.
UPF requires [GTP5G](https://github.com/PrinzOwO/gtp5g) kernel module that works on specific 5.x kernel versions, OpenShift 4.x uses RHCOS with kernel 4.x the best way to deploy the UPF is to use a CNV (Container Native Virtualization) Check how I built the UPF image 

## Requirements

  - ansible (tested on version 2.10.0)
  - A running OpenShift cluster with reachable API URL
  - [OpenShift Virtualization](https://docs.openshift.com/container-platform/4.5/virt/install/installing-virt-web.html) installed (Note: you don't need baremetal it works on nested-virtualization too)
  - (optional) podman
  - (optional) buildah

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
$ git clone https://github.com/tele0x/free5gc-openshift
```

Create 5genv environment, and install dependencies 

```sh
$ python3 -m venv 5genv
$ . 5genv/bin/activate
$ cd free5gc-openshift
$ pip3 install -r requirements.txt
$ ansible-galaxy collection install community.kubernetes
```

This should get you up and running with the environment.
Create or use an existing user in the cluster and assign cluster-admin role.

```sh
$ oc create clusterrolebinding registry-controller --clusterrole=cluster-admin --user=[username]
```

Edit *group_vars/all.yml* and change openshift *api_url*, *username* and *password*

You can test OCP cluster connection is working by running:

```sh
$ ./deploy.sh test
```

At this point we must initialize the networking on OpenShift

```sh
$ ./deploy.sh init
```

Network initialization will execute the following:

  - Create *5gcore* namespace. 
  - Add additional network called *5g-net* to the cluster.
  - Create *MachineConfig* to load SCTP kernel module on worker nodes.
  - Create *NodeNetworkConfigurationPolicy*
     - Add a new bridge interface to the worker node, this is used by the VM to attach the secondary network.
  - Create *NetworkAttachmentDefinition* used in VM manifest to attach the VM to secondary network.
