#!/bin/bash

VALID_CNFs="upf mongodb nrf nssf pcf ausf udm udr amf smf webui ransim uesim"

case "$1" in
	"test")
		echo -e "Test OCP login"
		ansible-playbook -i localhost playbooks/test.yml
		;;		
	"init")
		echo -e "Initialize networking"
		ansible-playbook -i localhost playbooks/init/00-create-namespace.yaml
		ansible-playbook -i localhost playbooks/init/01-load-gtp5g.yaml
		ansible-playbook -i localhost playbooks/init/02-initialize-network.yaml
		ansible-playbook -i localhost playbooks/init/03-initialize-sctp-proto.yaml
		echo -e "##########################################################\n"
		echo -e "SCTP module is configured on nodes, you can monitor the status with \"watch -n 3 'oc get nodes'\", wait until all nodes have been rebooted"
		echo -e "You can run the following command to ensure SCTP module is loaded: \n"
		echo -e "for n in \$(oc get nodes | awk '{print \$1}' | grep -v NAME) ; do echo -e \"Check SCTP on node \$n\" ; ssh core@\$n lsmod | grep sctp ; done\n"
		;;
	"all")
		echo -e "Start 5G Core Deployment"
		for nf in $VALID_CNFs; do
			echo -e "Deploy 5G Core NFs: $nf"
			ansible-playbook -i localhost playbooks/deploy/$nf.yaml
			case "$nf" in
				"mongodb" | "nrf" | "udr")
					echo -e "Wait 30 seconds"
					sleep 30
					;;
				"amf" | "smf")
					echo -e "Wait 10 seconds"
					sleep 10
					;;
			        "ransim")
					echo -e "Wait 30 seconds for GnodeB to be up"
					sleep 30
					;;
			esac
		done
		echo -e "5G Core and RAN simulator deployed"
		;;

	"mongodb" | "nrf" | "pcf" | "smf" | "ausf" | "nssf" | "udm" | "udr" | "amf" | "n3iwf" | "upf" | "webui" | "ransim" | "uesim")
		export CNF=$1
		echo -e "Deploy 5G Core NF: `echo $1 | tr '[a-z]' '[A-Z]'`"
		ansible-playbook -i localhost playbooks/deploy/$CNF.yaml
		;;

	*)
		echo -e "Usage: $0 [all|test|mongodb|nrf|nssf|pcf|smf|ausf|udm|udr|amf|n3iwf|upf|webui|ransim|uesim]"
		echo -e "\nall: Deploy all components"
		echo -e "init: Initialize networking"
		echo -e "test: Test OCP login\n"
		;;
esac
