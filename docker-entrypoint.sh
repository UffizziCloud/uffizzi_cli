#!/bin/sh

set -e # Exit immediately if anything below exits with non-zero status.

if
	[ "$UFFIZZI_USER" ] &&
	[ "$UFFIZZI_SERVER" ] &&
	[ "$UFFIZZI_PASSWORD" ]
then
	uffizzi login --username "${UFFIZZI_USER}" --server "${UFFIZZI_SERVER}"
	if [ "$UFFIZZI_PROJECT" ]
	then
		uffizzi config set project "${UFFIZZI_PROJECT}"
	fi
else
	if
    [ "$REQUEST_TOKEN" ] &&
    [ "$REQUEST_TOKEN_URL" ]
	then
    OIDC_TOKEN=$(curl -sLS "${REQUEST_TOKEN_URL}&audience=uffizzi" -H "User-Agent: actions/oidc-client" -H "Authorization: Bearer $REQUEST_TOKEN")
		uffizzi login_by_identity_token --token "${OIDC_TOKEN}" --access-token "${ACCESS_TOKEN}" --server "${UFFIZZI_SERVER}"
	else
		echo "Specify environment variables to login before executing Uffizzi CLI."
		echo "UFFIZZI_USER, UFFIZZI_SERVER, UFFIZZI_PASSWORD, and optionally UFFIZZI_PROJECT"
    echo "or"
    echo "REQUEST_TOKEN, REQUEST_TOKEN_URL and UFFFIZZI SERVER"
	fi
fi

if
	[ "$DOCKERHUB_USERNAME" ] &&
	[ "$DOCKERHUB_PASSWORD" ]
then
	uffizzi connect docker-hub --update-credential-if-exists
fi

if
	[ "$DOCKER_REGISTRY_USERNAME" ] &&
	[ "$DOCKER_REGISTRY_PASSWORD" ] &&
	[ "$DOCKER_REGISTRY_URL" ]
then
	uffizzi connect docker-registry --update-credential-if-exists
fi

if
	[ "$ACR_USERNAME" ] &&
	[ "$ACR_PASSWORD" ] &&
	[ "$ACR_REGISTRY_URL" ]
then
	uffizzi connect acr --update-credential-if-exists
fi

if
	[ "$AWS_ACCESS_KEY_ID" ] &&
	[ "$AWS_SECRET_ACCESS_KEY" ] &&
	[ "$AWS_REGISTRY_URL" ]
then
	uffizzi connect ecr --update-credential-if-exists
fi

if
	[ "$GCLOUD_SERVICE_KEY" ]
then
	uffizzi connect gcr --update-credential-if-exists
fi

if
	[ "$GITHUB_USERNAME" ] &&
	[ "$GITHUB_ACCESS_TOKEN" ]
then
	uffizzi connect ghcr --update-credential-if-exists
fi

exec uffizzi "$@"
