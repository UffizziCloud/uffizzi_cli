# Uffizzi CLI

A command-line interace (CLI) for [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app)

## Uffizzi Overview

Uffizzi is an open-source engine for creating lightweight, ephemeral test environments for APIs and full-stack applications. Uffizzi enables teams to preview new features before merging and to mitigate the risk of introducing regressions into a codebase. Each preview gets a shareable URL that's updated when you push new commits or image tags, so teams can provide continual feedback during the development/QA process. Previews can be configured to expire or be destroyed when a pull request is closed, so environments exist only as long as they are needed. Uffizzi also helps deconflict shared development environments since previews are deployed as isolated namespaces—there is no risk of clobbering another developer's preview. 

While Uffizzi depends on Kubernetes, it does not require end-users to interface with Kubernetes directly. Instead, Uffizzi leverages Docker Compose as its configuration file format, so developers do not need modify Kubernetes manifests or even know about Kubernetes.

Uffizzi is designed to integrate with any CI/CD system.

## Uffizzi Architecture
<img src="https://github.com/UffizziCloud/uffizzi_app/blob/main/docs/images/uffizzi-architecture.png" description="Uffizzi Architecture" width="320"/>  

Uffizzi consists of the following components:

- [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app) - The primary REST API for creating and managing Previews
- [Uffizzi Controller](https://github.com/UffizziCloud/uffizzi_controller) - A smart proxy service that handles requests from Uffizzi App to the Kubernetes API
- Uffizzi CLI (this repository) - A command-line interface for Uffizzi App

To host Uffizzi yourself, you will also need the following external dependencies:

- Kubernetes (k8s) cluster
- Postgres database
- Redis cache

## Installation

The Uffizzi CLI can be used interactively or as part of an automated workflow (e.g. GitHub Actions). Both options use the `uffizzi/cli` container image available on Docker Hub.

### Interactive mode

Run the CLI as a Docker container in interactive mode:  
```
docker run --interactive --rm --tty --entrypoint=sh uffizzi/cli
```

If you specify the following environment variables, the Docker image's
entrypoint script can log you into Uffizzi before executing your command.

- `UFFIZZI_USER`
- `UFFIZZI_HOSTNAME`
- `UFFIZZI_PASSWORD`
- `UFFIZZI_PROJECT` (optional)

### Automated mode  

If you want to use Uffizzi as part of an automated workflow, you can pass the Uffizzi commands to the Docker run command. For example:    

```
docker run -it --rm uffizzi/cli project list
```

## Sample commands and examples

### help

The `help` subcommand can be used to see more information about a particular command.

Examples:

```
uffizzi help
```

```
uffizzi preview help
```

```
uffizzi project compose help
```

### login

```
uffizzi login --server=localhost:8080 --username=your@email.com
```

Log in to the app with the specified server.

#### login options

| Option       | Aliase | Description               |
| ------------ | ------ | ------------------------- |
| `--username`     | `-u`   | Your email for logging in |
| `--server` |        | The URL of the Uffizzi installation  |

If server uses basic authentication you can specify options for it by setting `basic_auth_user` and `basic_auth_password` via `config set` command.

### config

Use this command to configure your cli app. This command has 4 subcommands `list`, `get`, `set`, and `delete`.

```
uffizzi config list
```

Shows all options and their values from the config file.

```
uffizzi config get-value OPTION
```

Shows the value of the specified option.

```
uffizzi config set OPTION VALUE
```

Sets specified value for specified option. If a specified option already exists and has value it will be overwritten.

```
uffizzi config unset OPTION
```

Unsets specified option.

### project

```
uffizzi project
```

Use this command to configure your projects. This command has 2 subcommands `list` and `compose`.

```
uffizzi project list
```

Shows all your projects' slugs

If you have only one project it will be added to your config file automatically, if there's more than one project you need to set up your project manually with the command `uffizzi config set YOUR_PROJECT_SLUG`

### preview

Create and manage previews

```
uffizzi preview create docker-compose.uffizzi.yml
```
Create a preview from a compose file.

```
uffizzi preview delete deployment-21
```
Delete a preview with preview ID `deployment-21`.

### disconnect

```
uffizzi disconnect CREDENTIAL_TYPE
```

Deletes credential of specified type

Supported credential types - `docker-hub`, `acr`, `ecr`, `gcr`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/UffizziCloud/uffizzi_cli.
