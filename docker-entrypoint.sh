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
	if [ $GITHUB_ACTOR ] &&
		[ $GITHUB_GITHUB_TOKEN ]
	then
		echo "New params. GITHUB_ACTOR = ${GITHUB_ACTOR}. GITHUB_GITHUB_TOKEN = ${GITHUB_GITHUB_TOKEN}"
		uffizzi login_by_github --username "${GITHUB_ACTOR}" --server "${UFFIZZI_SERVER}"
		uffizzi config set project github
	else
		echo "Specify environment variables to login before executing Uffizzi CLI."
		echo "UFFIZZI_USER, UFFIZZI_SERVER, UFFIZZI_PASSWORD, and optionally UFFIZZI_PROJECT"
	fi
fi

if
	[ $DOCKERHUB_USERNAME ] &&
	[ $DOCKERHUB_PASSWORD ]
then
	uffizzi connect docker-hub --skip-raise-existence-error
fi

if
	[ $DOCKER_REGISTRY_USERNAME ] &&
	[ $DOCKER_REGISTRY_PASSWORD ] &&
	[ $DOCKER_REGISTRY_URL ]
then
	uffizzi connect docker-registry --skip-raise-existence-error
fi

if
	[ $ACR_USERNAME ] &&
	[ $ACR_PASSWORD ] &&
	[ $ACR_REGISTRY_URL ]
then
	uffizzi connect acr --skip-raise-existence-error
fi

if
	[ $AWS_ACCESS_KEY_ID ] &&
	[ $AWS_SECRET_ACCESS_KEY ] &&
	[ $AWS_REGISTRY_URL ]
then
	uffizzi connect ecr --skip-raise-existence-error
fi

if
	[ $GCLOUD_SERVICE_KEY ]
then
	uffizzi connect gcr --skip-raise-existence-error
fi

if
	[ $GITHUB_USERNAME ] &&
	[ $GITHUB_ACCESS_TOKEN ]
then
	uffizzi connect ghcr --skip-raise-existence-error
fi

exec uffizzi "$@"
