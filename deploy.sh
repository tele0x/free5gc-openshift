#!/bin/bash

VALID_CNFs="uesim upf mongodb nrf nssf pcf ausf udm udr amf smf"

case "$1" in
	"test")
		echo -e "Test OCP login"
		ansible-playbook -i localhost playbooks/test.yml
		;;		
	"init")
		echo -e "Initialize networking"
		ansible-playbook -i localhost playbooks/initialize_network.yml
		;;
	"all")
		echo -e "Start 5G Core Deployment"
		for nf in $VALID_CNFs; do
			echo -e "Deploy 5G Core NFs: $nf"
			ansible-playbook -v -i localhost playbooks/deploy/deploy_$nf.yml
			case "$nf" in
				"upf")
					echo -e "Wait 30 seconds for UPF to boot up"
					sleep 30
					;;
				"mongodb" | "nrf" | "udr")
					echo -e "Wait 10 seconds"
					sleep 10
					;;
				"amf" | "smf")
					echo -e "Wait 5 seconds"
					sleep 5
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
