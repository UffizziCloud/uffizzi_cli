# Contributing to the Uffizzi Command-line Interface

First, thank you for considering contributing to Uffizzi! You are what drive the open source community.

Uffizzi welcomes all contributions from everyone, not just Pull Requests. You can also help by filing detailed bug reports, proposing new features, and sharing Continuous Previews and Uffizzi with your local community.

**Working on your first Pull Request?** You can learn how from this *free* series [How to Contribute to an Open Source Project on GitHub](https://kcd.im/pull-request)

If you find a security vulnerability, DO NOT open an issue. Email <info@uffizzi.com> instead.

## Community

Please join us on the [Uffizzi Slack](https://join.slack.com/t/uffizzi/shared_invite/zt-ffr4o3x0-J~0yVT6qgFV~wmGm19Ux9A) where we look forward to discussing any feature requests, bugs, and other proposed changes.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Run rubocop:
`bundle exec rubocop -A`

## Generate manual

In order to generate a manual, create a `.ronn` file having a name pattern like `uffizzi-{command-name}` (for example `uffizzi-project-compose`) in the `man` directory and run `bundle exec ronn man/{filename}.ronn` 

## Testing

Run tests:
`bundle exec rake test`

Run tests from a file:
`bundle exec rake test TEST=test/uffizzi/cli/preview_test.rb`

Run single test
`bundle exec rake test TEST=test/uffizzi/cli/preview_test.rb TESTOPTS="--name=test_name"`

## Git workflow for the app:

1. Clone the repository and checkout to `develop` branch

2. Pull repository to ensure you have the latest changes
```
git pull --rebase develop
```

3. Start new branch from `develop`
```
git checkout -b feature/ISSUE_NUMBER_short_issue_description (e.g. feature/99_add_domain_settings)
```

4. Make changes you need for the feature, commit them to the repo
```
git add .
git commit -m '[#ISSUE_NUMBER] short commit description' (e.g. git commit -m '[#99] added domain settings')
git push origin BRANCH_NAME
```

4. You already can create PR with develop branch as a target. Once the feature is ready let us know in the channel - we will review

5. Merge your feature to `qa` branch and push. Ensure your pipeline is successful
```
git checkout qa
git pull --rebase qa
git merge --no-ff BRANCH_NAME
git push origin qa
```

## Release

1. Merge the branch to develop.
2. Checkout to the develop branch.
3. Run one of the following command depending on the new release version:

```
make release_patch
make release_minor
make release_major
```

These commands will merge and push the develop branch into main and create a new tag.
Once the tag is pushed, the GHA workflows will release a gem and create new binaries for Linux and MacOs that can be found in the github release artefacts.

## Homebrew tap

Uffizzi supports a [Homebrew tap package] (https://github.com/UffizziCloud/homebrew-tap) and it needs to be updated after each release.
1. Go to the [latest release] (https://github.com/UffizziCloud/uffizzi_cli/releases/latest).
2. Copy the link to the source code archive (tar.gz).
3. Run `brew create [link copied in the previous step]` - this will create a new Formula file with the sha and the source code url.
4. Copy over the contents of the existing [Formula](https://github.com/UffizziCloud/homebrew-tap/blob/main/Formula/uffizzi.rb) from the master, replacing the sha and the url for the ones from the newly created Formula.
5. Update the `resource "uffizzi-cli"` to the latest gem and add new dependencies if needed.
6. Run `HOMEBREW_NO_INSTALL_FROM_API=1 brew install --build-from-source --verbose --debug uffizzi` and manually test the new uffizzi version (make sure that all other homebrew uffizzi versions are uninstalled).
7. Run `brew audit --strict --online` to check if the Formula adheres to the Homebrew style.
8. If tests and audit pass, create a PR into master in the UffizziCloud/homebrew-tap [repository] (https://github.com/UffizziCloud/homebrew-tap) with the new Formula.
