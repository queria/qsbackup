#!/bin/bash

source "$(dirname $0)/rotate.cfg"

dieError() {
	CODE=-1
	[ "x$2" == "x" ] || echo "$2"
	[ "x$1" == "x" ] || CODE=$1

	exit $CODE
}

[ -z "${ROTATEPATH}" ] && dieError 1 "No rotate configuration found"

if [ -d "${ROTATEPATH}" ];
then
	if rm -rf "${ROTATEPATH}";
	then
		echo "Removed old-rotate dir"
		exit 0
	else
		echo "Unable to remove old-rotate dir !"
		exit 2
	fi
else
	echo "No old-rotated backups dir found ... maybe ok?"
	exit 0
fi

