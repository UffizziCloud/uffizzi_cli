# Uffizzi CLI

A command-line interace (CLI) for [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app)

## Uffizzi Overview

Uffizzi is the Full-stack Previews Engine that makes it easy for your team to preview code changes before merging—whether frontend, backend or microserivce. Define your full-stack apps with a familiar syntax based on Docker Compose, and Uffizzi will create on-demand test environments when you open pull requests or build new images. Preview URLs are updated when there’s a new commit, so your team can catch issues early, iterate quickly, and accelerate your release cycles.

## Getting started with Uffizzi

The fastest and easiest way to get started with Uffizzi is via the fully hosted version available at https://uffizzi.com, which includes free plans for small teams and qualifying open-source projects.

Alternatively, you can self-host Uffizzi via the open-source repositories available here on GitHub. The remainder of this README is intended for users interested in self-hosting Uffizzi or for those who are just curious about how Uffizzi works.

## Uffizzi Architecture

Uffizzi consists of the following components:

- [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app) - The primary REST API for creating and managing Previews
- [Uffizzi Controller](https://github.com/UffizziCloud/uffizzi_controller) - A smart proxy service that handles requests from Uffizzi App to the Kubernetes API
- Uffizzi CLI (this repository) - A command-line interface for Uffizzi App
- [Uffizzi Dashboard](https://app.uffizzi.com) - A graphical user interface for Uffizzi App, available as a paid service at https://uffizzi.com

To host Uffizzi yourself, you will also need the following external dependencies:

- Kubernetes (k8s) cluster
- Postgres database
- Redis cache

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'uffizzi-cli'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install uffizzi-cli

### Docker image

We also provide an image on Docker Hub:

```bash
docker run -it --rm uffizzi/cli project list
```

If you specify the following environment variables, the Docker image's
entrypoint script can log you into Uffizzi before executing your command.

- `UFFIZZI_USER`
- `UFFIZZI_HOSTNAME`
- `UFFIZZI_PASSWORD`
- `UFFIZZI_PROJECT` (optional)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Run rubocop:
`bundle exec rubocop -A`

## Testing

Run tests:
`bundle exec rake test`

Run tests from a file:
`bundle exec rake test TEST=test/uffizzi/cli/preview_test.rb`

Run single test
`bundle exec rake test TEST=test/uffizzi/cli/preview_test.rb TESTOPTS="--name=test_name"`

## Commands

### login

```
$ uffizzi login --user your@email.com --server localhost:8080
```

Logging you into the app which you set in the server option or config file

### login options

| Option       | Aliase | Description                         |
| ------------ | ------ | ----------------------------------- |
| `--username` | `-u`   | Your email for logging in(optional) |
| `--server`   |        | Adress of your app(optional)        |

If server uses basic authentication you can specify options for it by setting `basic_auth_user` and `basic_auth_password` via `config set` command.

### project

```
$ uffizzi project
```

Use this command to configure your projects. This command has 2 subcommands `list` and `compose`.

```
$ uffizzi project list
```

Shows all your projects' slugs

If you have only one project it will be added to your config file automatically, if there's more than one project you need to set up your project manually with the command `uffizzi config set YOUR_PROJECT_SLUG`

### compose

```
$ uffizzi project compose
```

That's the subcommand for project command. Use it to configure your compose file. This command has 3 subcommands `set`, `describe` and `unset`.

```
$ uffizzi project compose set -f path_to_your_compose_file.yml
```

Creates a new or updates existed compose file in uffizzi app for project specified in config file

```
$ uffizzi project compose describe
```

Shows the content of compose file related to project specified in config file if it's valid or validation errors if it's not

```
$ uffizzi project compose unset
```

Removes compose file related to project specified in config file

You need to set project before use any of these commands via `uffizzi config set project YOUR_PROJECT_SLUG` command

### compose options

| Option   | Aliase | Description               |
| -------- | ------ | ------------------------- |
| `--file` | `-f`   | Path to your compose file |

### config

Use this command to configure your cli app.

```
$ uffizzi config
```

Launching interactive setup guide that sets the values for `server`, `username` and `project`

### config subcommands

This command has 4 subcommands `list`, `get`, `set`, and `delete`.

```
$ uffizzi config list
```

Shows all options and their values from the config file.

```
$ uffizzi config get-value OPTION
```

Shows the value of the specified option.

```
$ uffizzi config set OPTION VALUE
```

Sets specified value for specified option. If a specified option already exists and has value it will be overwritten.

```
$ uffizzi config unset OPTION
```

Deletes value of specified option.

### disconnect ###

```
$ uffizzi disconnect CREDENTIAL_TYPE
```

Deletes credential of specified type

Supported credential types - `docker-hub`, `acr`, `ecr`, `gcr`

## Generate manual

In order to generate a manual, create a `.ronn` file having a name pattern like `uffizzi-{command-name}` (for example `uffizzi-project-compose`) in the `man` directory and run `bundle exec ronn man/{filename}.ronn` 

## Git workflow for the app:

1. Clone the repository and checkout to `develop` branch

2. Pull repository to ensure you have the latest changes
```
git pull --rebase develop
```

3. Start new branch from `develop`
```
git checkout -b feature/short_issue_description (e.g. feature/add_domain_settings)
```

4. Make changes you need for the feature, commit them to the repo
```
git add .
git commit -m 'short commit description' (e.g. git commit -m 'added domain settings')
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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/UffizziCloud/uffizzi_cli.
