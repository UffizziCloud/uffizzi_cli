#!/bin/sh

set -e # Exit immediately if anything below exits with non-zero status.

if
	[ $UFFIZZI_USER ] &&
	[ $UFFIZZI_SERVER ] &&
	[ $UFFIZZI_PASSWORD ]
then
	uffizzi login --username "${UFFIZZI_USER}" --server "${UFFIZZI_SERVER}"
	if [ $UFFIZZI_PROJECT ]
	then
		uffizzi config set project "${UFFIZZI_PROJECT}"
	fi
else
	echo "Specify environment variables to login before executing Uffizzi CLI."
	echo "UFFIZZI_USER, UFFIZZI_SERVER, UFFIZZI_PASSWORD, and optionally UFFIZZI_PROJECT"
fi

exec uffizzi "$@"
