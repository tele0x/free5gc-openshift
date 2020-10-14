#!/bin/bash

VALID_CNFs="mongodb nrf pcf smf ausf udm udr amf nssf upf"

case "$1" in
	"all")
		for nf in $VALID_CNFs; do
			echo -e "Undeploy 5G Core NFs: $nf"
			ansible-playbook -v -i localhost playbooks/undeploy/undeploy_$nf.yml
		done
		;;

	"mongodb" | "nrf" | "nssf" | "pcf" | "smf" | "ausf" | "udm" | "udr" | "amf" | "n3iwf" | "upf")
		export CNF=$1
		echo -e "Undeploy 5G Core NF: `echo $1 | tr '[a-z]' '[A-Z]'`"
		ansible-playbook -i localhost playbooks/undeploy/undeploy_$nf.yml
		;;

	*)
		echo -e "Usage: $0 [all|mongodb|nrf|pcf|smf|ausf|udm|udr|amf|n3iwf|nssf|upf]"
		echo -e "\nall: Undeploy all components\n"
		;;
esac
