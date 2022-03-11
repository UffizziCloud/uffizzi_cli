#!/bin/sh

set -e # Exit immediately if anything below exits with non-zero status.

if
	[ $UFFIZZI_USER ] &&
	[ $UFFIZZI_HOSTNAME ] &&
	[ $UFFIZZI_PASSWORD ]
then
	uffizzi login --user "${UFFIZZI_USER}" --hostname "${UFFIZZI_HOSTNAME}"
else
	echo "Specify environment variables to login before executing Uffizzi CLI."
	echo "UFFIZZI_USER, UFFIZZI_HOSTNAME, and UFFIZZI_PASSWORD"
fi

exec uffizzi "$@"
