#!/bin/bash

VALID_CNFs="mongodb nrf pcf smf ausf udm udr amf nssf upf uesim"

case "$1" in
	"init")
		echo -e "Initialize networking"
		ansible-playbook -i localhost playbooks/initialize_network.yml
		;;
	"all")
		for nf in $VALID_CNFs; do
			echo -e "Deploy 5G Core NFs: $VALID_CNFs"
			ansible-playbook -v -i localhost playbooks/deploy/deploy_$nf.yml
		done
		;;

	"mongodb" | "nrf" | "pcf" | "smf" | "ausf" | "nssf" | "udm" | "udr" | "amf" | "n3iwf" | "upf" | "uesim")
		export CNF=$1
		echo -e "Deploy 5G Core NF: `echo $1 | tr '[a-z]' '[A-Z]'`"
		ansible-playbook -i localhost playbooks/deploy/deploy_$CNF.yml
		;;

	*)
		echo -e "Usage: $0 [all|mongodb|nrf|nssf|pcf|smf|ausf|udm|udr|amf|n3iwf|upf|uesim]"
		echo -e "\nall: Deploy all components\n"
		;;
esac
