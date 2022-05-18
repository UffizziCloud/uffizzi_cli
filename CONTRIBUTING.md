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
