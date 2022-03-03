# Uffizzi CLI  

A command-line interace (CLI) for [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app) 

## Uffizzi Overview

Uffizzi is the Full-stack Previews Engine that makes it easy for your team to preview code changes before merging—whether frontend, backend or microserivce. Define your full-stack apps with a familiar syntax based on Docker Compose, and Uffizzi will create on-demand test environments when you open pull requests or build new images. Preview URLs are updated when there’s a new commit, so your team can catch issues early, iterate quickly, and accelerate your release cycles.  

## Getting started with Uffizzi  

The fastest and easiest way to get started with Uffizzi is via the fully hosted version available at https://uffizzi.com, which includes free plans for small teams and qualifying open-source projects.   

Alternatively, you can self-host Uffizzi via the open-source repositories available here on GitHub. The remainder of this README is intended for users interested in self-hosting Uffizzi or for those who are just curious about how Uffizzi works.

## Uffizzi Architecture  

Uffizzi consists of the following components:  

* [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app) - The primary REST API for creating and managing Previews  
* [Uffizzi Controller](https://github.com/UffizziCloud/uffizzi_controller) - A smart proxy service that handles requests from Uffizzi App to the Kubernetes API  
* Uffizzi CLI (this repository) - A command-line interface for Uffizzi App    
* [Uffizzi Dashboard](https://app.uffizzi.com) - A graphical user interface for Uffizzi App, available as a paid service at https://uffizzi.com  

To host Uffizzi yourself, you will also need the following external dependencies:  

 * Kubernetes (k8s) cluster  
 * Postgres database  
 * Redis cache 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'uffizzi'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install uffizzi

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Run rubocop:
`bundle exec rubocop -A`

## Commands

### login ###

```
$ uffizzi login -u your@email.com -h localhost:8080
```
Logging you into the app which you set in the hostname option.


### login options ###

Option      | Aliase          | Description
-------     | -------         | -----------
`--user`    | `-u`            | Your email for logging in
`--hostname`| `-h`            | Adress of your app

If hostname uses basic authentication you can specify options for it by setting `basic_auth_user` and `basic_auth_password` via `config set` command.

### projects ###

```
$ uffizzi projects
```

Shows all your projects' slugs

If you have only one project it will be added to your config file automatically, if there's more than one project you need to set up your project manually with the command `uffizzi config set YOUR_PROJECT_SLUG`

### config ###

Use this command to configure your cli app. This command has 4 subcommands `list`, `get`, `set`, and `delete`.

```
$ uffizzi config list
```
Shows all options and their values from the config file.

```
$ uffizzi config get OPTION
```

Shows the value of the specified option.

```
$ uffizzi config set OPTION VALUE
```

Sets specified value for specified option. If a specified option already exists and has value it will be overwritten.

```
$ uffizzi config delete OPTION
```

Deletes specified option.

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
git push origin FEATURE_NAME
```

4. You already can create PR with develop branch as a target. Once the feature is ready let us know in the channel - we will review

5. Merge your feature to `qa` branch and push. Ensure your pipeline is successful
```
git checkout qa
git pull --rebase qa
git merge --no-ff FEATURE_NAME
git push origin qa
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/UffizziCloud/uffizzi_cli.
