#!/bin/bash

source "$(dirname $0)/rotate.cfg"

dieError() {
	CODE=-1
	[ "x$2" == "x" ] || echo "$2"
	[ "x$1" == "x" ] || CODE=$1

	exit $CODE
}

[ -z "${LIVEPATH}" -o -z "${ROTATEPATH}" ] && dieError 1 "No rotate configuration found"

FILESLIVE="${LIVEPATH}/files"
DBLIVE="${LIVEPATH}/db"
FILESROT="${ROTATEPATH}/files"
DBROT="${ROTATEPATH}/db"

[ -d "${ROTATEPATH}" ] && ( rm -rf "${ROTATEPATH}" || dieError 2 "Unable to remove old rotdir" )
mkdir -p "${FILESROT}" && mkdir -p "${DBROT}" || dieError 3 "Unable to create rotdirs"

[ -d "${DBLIVE}" -a "$(ls -A "${DBLIVE}")" ] && mv -f "${DBLIVE}/"* -t "${DBROT}" 
[ -d "${FILESLIVE}" -a "$(ls -A "${FILESLIVE}")" ] && mv -f "${FILESLIVE}/"* -t "${FILESROT}" 

# now move back "young" db backups
# and recreate files backup

THISMONTH=$(date "+%Y%m")
LASTMONTH=$(date -d "last month" "+%Y%m")

mv -f "${DBROT}/${THISMONTH}"* -t "${DBLIVE}"
mv -f "${DBROT}/${LASTMONTH}"* -t "${DBLIVE}"

if [ ! "$(ls -A "${ROTATEPATH}")" ] || [ ! "$(ls -A "${DBROT}")" -a ! "$(ls -A "${FILESROT}")" ];
then
	echo "No old backups to rotate ... maybe ok?"
	exit 0
fi

echo "===== Rotated old backups: ====="
find "${ROTATEPATH}" -type f -printf "%P\n"

exit 0

