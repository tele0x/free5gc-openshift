#!/bin/bash

VALID_CNFs="uesim upf mongodb nrf nssf pcf ausf udm udr amf smf"

case "$1" in
	"test")
		echo -e "Test OCP login"
		ansible-playbook -i localhost playbooks/test.yml
		;;		
	"init")
		echo -e "Initialize networking"
		ansible-playbook -i localhost playbooks/init/00_create_namespace.yml
		ansible-playbook -i localhost playbooks/init/01_initialize_cnv_network.yml
		echo -e "Wait for NNCP configuration to be applied"
		retry=0
		until [ "$retry" -ge 5 ]; do
			if oc get nncp bridge-br1 | grep SuccessfullyConfigured; then echo 'NNCP Ready!' && break ; else echo -e "[$retry] NNCP not ready, retry in 15 sec.." ; fi
			retry=$((retry+1))
			sleep 15
		done
		ansible-playbook -i localhost playbooks/init/02_initialize_network.yml
		ansible-playbook -i localhost playbooks/init/03_initialize_sctp_proto.yml
		echo -e "##########################################################\n"
		echo -e "SCTP module is configured on nodes, you can monitor the status with \"watch -n 3 'oc get nodes'\", wait until all nodes have been rebooted"
		echo -e "You can run the following command to ensure SCTP module is loaded: \n"
		echo -e "for n in \$(oc get nodes | awk '{print \$1}' | grep -v NAME) ; do echo -e \"Check SCTP on node \$n\" ; ssh core@\$n lsmod | grep sctp ; done\n"
		;;
	"all")
		echo -e "Start 5G Core Deployment"
		for nf in $VALID_CNFs; do
			echo -e "Deploy 5G Core NFs: $nf"
			ansible-playbook -v -i localhost playbooks/deploy/deploy_$nf.yml
			case "$nf" in
				"upf")
					echo -e "Wait 1 minute for UPF to download image and boot up"
					sleep 60
					;;
				"mongodb" | "nrf" | "udr")
					echo -e "Wait 30 seconds"
					sleep 30
					;;
				"amf" | "smf")
					echo -e "Wait 10 seconds"
					sleep 10
					;;
			esac
		done
		echo -e "5G Core Deployed"
		;;

	"mongodb" | "nrf" | "pcf" | "smf" | "ausf" | "nssf" | "udm" | "udr" | "amf" | "n3iwf" | "upf" | "uesim")
		export CNF=$1
		echo -e "Deploy 5G Core NF: `echo $1 | tr '[a-z]' '[A-Z]'`"
		ansible-playbook -i localhost playbooks/deploy/deploy_$CNF.yml
		;;

	*)
		echo -e "Usage: $0 [all|test|mongodb|nrf|nssf|pcf|smf|ausf|udm|udr|amf|n3iwf|upf|uesim]"
		echo -e "\nall: Deploy all components"
		echo -e "init: Initialize networking"
		echo -e "test: Test OCP login\n"
		;;
esac
