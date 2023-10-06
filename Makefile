.PHONY: release release_patch release_minor release_major

NEXT_PATCH=$(shell docker-compose run --rm gem bash -c "bundle exec bump show-next patch")
NEXT_MINOR=$(shell docker-compose run --rm gem bash -c "bundle exec bump show-next minor")
NEXT_MAJOR=$(shell docker-compose run --rm gem bash -c "bundle exec bump show-next major")
TAG_FULL_VERSION=v${VERSION}
CURRENT_LOCAL_GEM_NAME := $(shell ls | sort -r | grep 'uffizzi-cli-.*\.gem' | head -1)

release_gem:
	mkdir -p ${HOME}/.gem
	touch ${HOME}/.gem/credentials
	chmod 0600 ${HOME}/.gem/credentials
	printf -- "---\n:rubygems_api_key: ${RUBYGEMS_API_KEY}\n" > ${HOME}/.gem/credentials
	gem build *.gemspec
	gem push *.gem

release_patch: export VERSION=${NEXT_PATCH}
release_patch:
	make release

release_minor: export VERSION=${NEXT_MINOR}
release_minor:
	make release

release_major: export VERSION=${NEXT_MAJOR}
release_major:
	make release

release:
	git checkout develop
	@echo 'Set a new version'
	docker-compose run --rm gem bash -c "bundle exec bump set ${VERSION}"
	docker-compose run --rm gem bash -c "bundle install"
	git commit -am "Change version to ${VERSION}"
	@echo 'Update remote origin'
	git push origin develop
	git checkout main
	git pull origin --rebase main
	git merge --no-ff --no-edit develop
	git push origin main
	@echo 'Create a new tag'
	git tag ${TAG_FULL_VERSION}
	git push origin ${TAG_FULL_VERSION}

shell:
	docker-compose run --rm gem bash

test:
	docker-compose run --rm gem bash -c "bundle exec rake test"

lint:
	docker-compose run --rm gem bash -c "bundle exec rubocop -A"

run_single_test:
	docker-compose run --rm gem bash -c 'bundle exec rake test TEST=$(TEST_PATH) TESTOPTS="--name=${TEST_NAME}"'

gem_build:
	gem build uffizzi.gemspec

gem_install:
	gem install $(CURRENT_LOCAL_GEM_NAME)

gem_build_install:
	make gem_build
	make gem_install

gem_uninstall:
	gem uninstall uffizzi-cli

brew_add_tap:
	brew tap UffizziCloud/tap

brew_tap_install:
	brew install uffizzicloud/tap/uffizzi

.PHONY: test
