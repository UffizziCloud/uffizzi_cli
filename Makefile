.PHONY: release release_patch release_minor release_major

NEXT_PATCH=$(shell docker-compose run --rm gem bash -c "bundle exec bump show-next patch")
NEXT_MINOR=$(shell docker-compose run --rm gem bash -c "bundle exec bump show-next minor")
NEXT_MAJOR=$(shell docker-compose run --rm gem bash -c "bundle exec bump show-next major")

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
	@echo 'Update remote origin'
	git push origin develop
	git checkout main
	git pull origin --rebase main
	git merge --no-ff --no-edit develop
	git push origin main
	@echo 'Create a new tag'
	git tag v${VERSION}
	git push origin v${VERSION}

shell:
	docker-compose run --rm gem bash

test:
	docker-compose run --rm gem bash -c "bundle exec rake test"

.PHONY: test
