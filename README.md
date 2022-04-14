# Uffizzi CLI

A command-line interace (CLI) for the [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app)

## Uffizzi Overview

Uffizzi is the Full-stack Previews Engine that makes it easy for your team to preview code changes before merging — whether frontend, backend or microserivce. Define your full stacks of application and supporting containers with a familiar Docker Compose syntax, and Uffizzi will create on-demand test environments. Preview URLs can be updated when there’s a new commit, so your team can catch issues early, iterate quickly, and accelerate your release cycles.

## Getting started with Uffizzi

Alternatively, you can self-host Uffizzi via the open-source repositories available here on GitHub. 

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
- `UFFIZZI_SERVER`
- `UFFIZZI_PASSWORD`
- `UFFIZZI_PROJECT` (optional)

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
| `--server`   | `-s`   | Adress of your app(optional)        |

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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/UffizziCloud/uffizzi_cli.  See `CONTRIBUTING.md` in this repository.
