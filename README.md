# Free5GC on OpenShift

## Table of Contents

<!-- TOC -->

- [Free5GC on OpenShift](#free5gc-on-openshift)
  - [Introduction](#introduction)
  - [Prerequisities](#prerequisities)
  - [Architecture](#architecture)
  - [(Optional) Build container images](#build-container-images)
    - [5G Core](#5g-core-container-images)
    - [UE RAN Simulator](#ue-ran-simulator)
    - [Push images to a registry](#push-images-to-a-registry)
  - [Installation](#installation)
  - [Validation](#validation)
<!-- TOC -->

## Introduction

Free5GC-OpenShift is an open-source project to deploy a working 5G Core network using [Free5GC](https://github.com/free5gc/free5gc) on Red Hat OpenShift Container Platform. This project can be used for testing and learning 5G protocols. A containerized gNB and UE ([UERANSIM](https://github.com/aligungr/UERANSIM) is deployed for E2E data connection testing.
The base container image for the components is Red Hat UBI 8. The UPF in Free5GC requires [GTP5G](https://github.com/PrinzOwO/gtp5g) a kernel module that implements kernel-side GTP-U plane, the module is backported on kernel 4.18.x in order to work with Red Hat CoreOS. 
Optionally you can build and customize your own container images.

## Prerequisities

  - Ansible (tested on version 2.10.0)
  - A running OpenShift cluster with reachable API URL

(Optional) To build the container images:

  - podman
  - buildah
  - yq - used to parse yaml files 

## Architecture

![OpenShift Free5GC Architecture](img/free5gc_openshift_architecture.png?raw=true "OpenShift Free5GC Architecture")

Both core and RAN are deployed in the same cluster and namespace, using the ansible script is easy to deploy specific components on another cluster, for example to have a Core and Edge cluster. 
Network segmentation is implemented and configurable. The SBI (Service Based Interface) using HTTP2 uses `Services` while N1,N2,N3,N4 are on additional networks.

| Network Name | Link | Interface | Network | Netmask
| ------------ | ----------- | --------- | ------- | -------
| net-ran | UE<->gNB | N1 | 192.168.8.0 | 255.255.255.0
| net-ngap | gNB<->AMF (NGAP) | N2 | 192.168.5.0 | 255.255.255.0
| net-gtp | gNB<->UPF (GTP) | N3 | 192.168.6.0 | 255.255.255.0
| net-pfcp | UPF<->SMF (PFCP) | N4 | 192.168.7.0 | 255.255.255.0


## (Optional) Build container images

Container images to run the 5G Core are already built and used in the playbooks:

| Name | Image | Description | Version |
| ---- | ----- | ----------- | ------- |
| free5gc-openshift | quay.io/ferossi/free5gc-openshift | All-in-one image with pre-compiled 5G Core NFs components | 0.1
| free5gc-openshift-upf | quay.io/ferossi/free5gc-openshift-upf | UPF Containerized image for CNV | 0.1
| ueransim | quay.io/ferossi/ueransim | UE RAN simulator image | 0.1

Optionally you can build and customize the images and push it to your own registry.

### 5G Core

Use the build.sh script to create container images for 5G Core. You can build individual images or use "all-in-one" to build an image with all components compiled.

```
$ ./build.sh
Usage: ./build.sh [ all-in-one | all | nrf | pcf | smf | ausf | udm | udr | amf | n3iwf | upf ]
    
all-in-one: One single image with all the components compiled
all: All components as individual images
uesim: Build UE RAN simulator image to run distributed testing of 5G NFs

$ ./build.sh all-in-one
```

### UE RAN Simulator

```
$ ./build_ueransim.sh
```

### Push images to a registry

Use podman to list the images and push to a registry.

```
$ podman images
REPOSITORY                           TAG     IMAGE ID      CREATED      SIZE
localhost/free5gc-aio                latest  1334f9e8ee88  6 hours ago  2.38 GB
localhost/ueransim                   latest  c400257d64e2  7 hours ago  736 MB
localhost/free5gc-upf                latest  0cd09d2ada4f  7 hours ago  3.69 GB
registry.access.redhat.com/ubi8/ubi  latest  9992f11c61c5  2 weeks ago  213 MB

$ podman login quay.io
$ podman push [image_id] quay.io/[user]/[your_repository]:[optional_tag]
``` 


## Installation

Clone this repository.

```
$ git clone https://github.com/tele0x/free5gc-openshift
```

Create 5genv environment, and install dependencies.

```
$ python3 -m venv 5genv
$ . 5genv/bin/activate
$ cd free5gc-openshift
$ pip3 install -r requirements.txt
$ ansible-galaxy install -r collections/requirements.yaml
```

This should get you up and running with the environment.
Create or use an existing user in the cluster and assign cluster-admin role. Creating a user in OpenShift is out of scope of this document.

```
$ oc create clusterrolebinding registry-controller --clusterrole=cluster-admin --user=[username]
```

Edit *group_vars/all.yml* and change openshift *api_url*, *username* and *password*
You can test OCP cluster login is working by running:

```
$ ./deploy.sh test
```

Edit *group_vars/all.yml* and change openshift *host_ifname*. This is the interface you wish to use for macvlan driver.
NOTE: If your cluster is running on VMware ESXi hypervisor, you would have to update the vCenter distributed port group security settings to Allow Promiscious mode, Mac address changes and Forged Transmits for macvlan traffic to flow between OCP nodes.

Initialize networking deployment, this will configure networking in the cluster
NOTE: This will reboot all your worker nodes one at the time to apply the changes to enable SCTP.

```
$ ./deploy.sh init
```

Network initialization workflow:

  - playbooks/init/00_create_namespace.yml 
     - Create *5gcore* namespace
  - playbooks/init/01-load-gtp5g.yaml 
     - Load GTP5G kernel module
  - playbooks/init/02_initialize_network.yml 
     - Add additional macvlan network called *5g-net* to the cluster
  - playbooks/init/03_initialize_sctp_proto.yml 
     - Create *MachineConfig* to load SCTP kernel module on worker nodes

Check resources are correctly created
GTP5G Kernel module:

```
$ oc get pods -n gtp5g-driver
NAME                                READY   STATUS    RESTARTS   AGE
gtp5g-kmod-driver-container-7psd9   1/1     Running   0          20h
gtp5g-kmod-driver-container-ffxll   1/1     Running   0          20h
gtp5g-kmod-driver-container-tbv92   1/1     Running   0          20h

$ oc logs -f gtp5g-kmod-driver-container-7psd9 -n gtp5g-driver
gtp5g                 118784  0
udp_tunnel             20480  2 gtp5g,vxlan
Unloading module
Loading gtp5g module..
Module loaded: 
gtp5g                 118784  0
udp_tunnel             20480  2 gtp5g,vxlan
filename:       /lib/modules/4.18.0-305.19.1.el8_4.x86_64/kernel/drivers/net/gtp5g.ko
alias:          net-pf-16-proto-16-family-gtp5g
alias:          rtnl-link-gtp5g
version:        1.0.3b
description:    Interface for 5G GTP encapsulated traffic
author:         Muthuraman <muthuramane.cs03g@g2.nctu.edu.tw>
author:         Yao-Wen Chang <yaowenowo@gmail.com>
license:        GPL
rhelversion:    8.4
srcversion:     D93DAC9B9735453E689040C
depends:        udp_tunnel
name:           gtp5g
vermagic:       4.18.0-305.19.1.el8_4.x86_64 SMP mod_unload modversions 
```

Additional networks:

```
$ oc get net-attach-def -n 5gcore
NAME          AGE
net-gtp       3d14h
net-ngap      3d14h
net-pfcp      3d14h
net-ran       3d14h
```

Deploy all components:

```
$ ./deploy.sh all
```

Wait until the playbooks finishes to run and *5G Core and RAN simulator deployed* is displayed.


## Validation

Use *5gcore* project:

```
$ oc project 5gcore
```

Check all pods are running successfully:

```
$ oc get pods
NAME                         READY   STATUS    RESTARTS   AGE
amf                          1/1     Running   0          4m34s
ausf                         1/1     Running   0          5m23s
mongodb                      1/1     Running   0          6m47s
nrf                          1/1     Running   0          6m11s
nssf                         1/1     Running   0          5m34s
pcf                          1/1     Running   0          5m28s
ransim                       1/1     Running   0          3m52s
smf                          1/1     Running   0          4m16s
udm                          1/1     Running   0          5m17s
udr                          1/1     Running   0          5m10s
uesim                        1/1     Running   0          3m15s
upf                          1/1     Running   0          7m51s
webui                        1/1     Running   0          3m59s
```

Check the UE is registered, the PDU session is established successfully and the TUN interface uesimtun0 is up.
==[2021-05-28 20:32:06.126] [app] [info] Connection setup for PDU session[1] is successful, TUN interface[uesimtun0, 60.60.0.1] is up==

```
$ oc logs -f uesim -n 5gcore
UERANSIM v3.1.6
[2021-05-28 20:32:05.815] [nas] [debug] NAS layer started
[2021-05-28 20:32:05.815] [rrc] [debug] RRC layer started
[2021-05-28 20:32:05.815] [nas] [info] UE switches to state [MM-DEREGISTERED/PLMN-SEARCH]
[2021-05-28 20:32:05.815] [nas] [info] UE connected to gNB
[2021-05-28 20:32:05.815] [nas] [info] UE switches to state [MM-DEREGISTERED/NORMAL-SERVICE]
[2021-05-28 20:32:05.815] [nas] [debug] Sending Initial Registration
[2021-05-28 20:32:05.815] [nas] [info] UE switches to state [MM-REGISTER-INITIATED/NA]
[2021-05-28 20:32:05.815] [rrc] [debug] Sending RRC Setup Request
[2021-05-28 20:32:05.816] [rrc] [info] RRC connection established
[2021-05-28 20:32:05.816] [nas] [info] UE switches to state [CM-CONNECTED]
[2021-05-28 20:32:05.846] [nas] [debug] Security Mode Command received
[2021-05-28 20:32:05.846] [nas] [debug] Derived NAS keys integrity[009D03BF992EE1A1263BA39A864B9A48] ciphering[22BEC84F478430C5DEEB39DEF71C3169]
[2021-05-28 20:32:05.846] [nas] [debug] Selected integrity[2] ciphering[0]
[2021-05-28 20:32:05.886] [nas] [debug] Registration accept received
[2021-05-28 20:32:05.886] [nas] [info] UE switches to state [MM-REGISTERED/NORMAL-SERVICE]
[2021-05-28 20:32:05.886] [nas] [info] Initial Registration is successful
[2021-05-28 20:32:05.886] [nas] [info] Initial PDU sessions are establishing [1#]
[2021-05-28 20:32:05.886] [nas] [debug] Sending PDU Session Establishment Request
[2021-05-28 20:32:06.112] [nas] [debug] PDU Session Establishment Accept received
[2021-05-28 20:32:06.112] [nas] [warning] SM cause received in PduSessionEstablishmentAccept [PDU_SESSION_TYPE_IPV4_ONLY_ALLOWED]
[2021-05-28 20:32:06.112] [nas] [info] PDU Session establishment is successful PSI[1]
[2021-05-28 20:32:06.126] [app] [info] Connection setup for PDU session[1] is successful, TUN interface[uesimtun0, 60.60.0.1] is up.
```

Ping an IP to make sure the connection is working.

```
$ oc exec -ti uesim -n 5gcore -- ping -I uesimtun0 8.8.8.8
PING 8.8.8.8 (8.8.8.8) from 60.60.0.1 uesimtun0: 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=114 time=9.34 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=114 time=7.93 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=114 time=6.89 ms
^C
--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 5ms
rtt min/avg/max/mdev = 6.889/8.053/9.338/1.008 ms```
```

Login on the UPF

```
$ oc exec -ti upf -- /bin/bash
[free5gc@upf ~]#
```

On another terminal run the ping command from uesim pod while running tcpdump on UPF GTP interface *upfgtp*

```
[root@upf free5gc]# tcpdump -i upfgtp
dropped privs to tcpdump
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on upfgtp, link-type RAW (Raw IP), capture size 262144 bytes
21:09:40.665525 IP 60-60-0-1.rev.home.ne.jp > dns.google: ICMP echo request, id 8, seq 1, length 64
21:09:40.674294 IP dns.google > 60-60-0-1.rev.home.ne.jp: ICMP echo reply, id 8, seq 1, length 64
21:09:41.666948 IP 60-60-0-1.rev.home.ne.jp > dns.google: ICMP echo request, id 8, seq 2, length 64
21:09:41.674869 IP dns.google > 60-60-0-1.rev.home.ne.jp: ICMP echo reply, id 8, seq 2, length 64
21:09:42.668357 IP 60-60-0-1.rev.home.ne.jp > dns.google: ICMP echo request, id 8, seq 3, length 64
21:09:42.675066 IP dns.google > 60-60-0-1.rev.home.ne.jp: ICMP echo reply, id 8, seq 3, length 64
^C
6 packets captured
6 packets received by filter
0 packets dropped by kernel
```

Run tcpdump on the pod interface filtering on icmp traffic (DN interface).

```
[root@upf free5gc]# tcpdump -i eth0 icmp
dropped privs to tcpdump
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
21:10:44.219396 IP upf-vm > dns.google: ICMP echo request, id 9, seq 1, length 64
21:10:44.227764 IP dns.google > upf-vm: ICMP echo reply, id 9, seq 1, length 64
21:10:45.220815 IP upf-vm > dns.google: ICMP echo request, id 9, seq 2, length 64
21:10:45.227181 IP dns.google > upf-vm: ICMP echo reply, id 9, seq 2, length 64
```
