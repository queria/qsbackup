#!/bin/bash

if [ -z "$1" ];
then
	echo "No ftpmirror package specified!"
	exit 1
fi

OUT=$(mktemp "/tmp/runftpmirror.XXXXXXX");

ftpmirror "$1" > $OUT 2>&1
if grep "\(: \(failure\|error\)\| not defined\)" $OUT > /dev/null;
then
	echo "===== Errors found in ftpmirror results: ====="
	cat $OUT | sed 's/^\(.*\(: \(failure\|error\)\| not defined\).*\)$/\1 ****************************************/'
	rm $OUT
	exit 2
fi

rm $OUT
exit 0

