#!/bin/bash

VALID_CNFs="nrf pcf smf ausf udm udr amf n3iwf upf"
BENDER_CMD="ansible-bender build build_nf.yml"

case "$1" in
	"all")
		for nf in $VALID_CNFs; do
			echo -e "Build all 5G Core NFs: $VALID_CNFs"
			export CNF=$nf
			$BENDER_CMD
		done
		;;

	"all-in-one")
		export CNF=$1
		echo -e "Build 5G Core NFs all-in-one: $VALID_CNFs"
		$BENDER_CMD
		;;

	"nrf" | "pcf" | "smf" | "ausf" | "udm" | "udr" | "amf" | "n3iwf" | "upf")
		export CNF=$1
		echo -e "Build 5G Core NF: `echo $1 | tr '[a-z]' '[A-Z]'`"
		$BENDER_CMD
		;;

	*)
		echo -e "Usage: $0 [all-in-one|all|nrf|pcf|smf|ausf|udm|udr|amf|n3iwf|upf]"
		echo -e "\n\tall-in-one: One single image with all the components compiled"
		echo -e "\tall: All components as individual images\n"
		;;
esac
