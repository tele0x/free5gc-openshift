#!/bin/bash

VALID_CNFs="mongodb nrf pcf smf ausf udm udr amf nssf upf"

case "$1" in
	"all")
		ansible-playbook -i localhost playbooks/initialize_network.yml
		for nf in $VALID_CNFs; do
			echo -e "Deploy 5G Core NFs: $VALID_CNFs"
			ansible-playbook -v -i localhost playbooks/deploy/deploy_$nf.yml
		done
		;;

	"mongodb" | "nrf" | "pcf" | "smf" | "ausf" | "udm" | "udr" | "amf" | "n3iwf" | "upf")
		export CNF=$1
		ansible-playbook -i localhost playbooks/initialize_network.yml
		echo -e "Deploy 5G Core NF: `echo $1 | tr '[a-z]' '[A-Z]'`"
		ansible-playbook -i localhost playbooks/deploy/deploy_$CNF.yml
		;;

	*)
		echo -e "Usage: $0 [all|mongodb|nrf|pcf|smf|ausf|udm|udr|amf|n3iwf|upf]"
		echo -e "\nall: Deploy all components\n"
		;;
esac
