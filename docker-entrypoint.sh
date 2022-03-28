#!/bin/sh

set -e # Exit immediately if anything below exits with non-zero status.

if
	[ $UFFIZZI_USER ] &&
	[ $UFFIZZI_HOSTNAME ] &&
	[ $UFFIZZI_PASSWORD ]
then
	uffizzi login --username "${UFFIZZI_USER}" --hostname "${UFFIZZI_HOSTNAME}"
	if [ $UFFIZZI_PROJECT ]
	then
		uffizzi config set project "${UFFIZZI_PROJECT}"
	fi
else
	echo "Specify environment variables to login before executing Uffizzi CLI."
	echo "UFFIZZI_USER, UFFIZZI_HOSTNAME, UFFIZZI_PASSWORD, and optionally UFFIZZI_PROJECT"
fi

exec uffizzi "$@"
